import { useCallback, useEffect, useRef, useState } from "react";
import { useMediaQuery } from "../../components/useMediaQuery";
import type { EventBus } from "../../core/EventBus";
import type { CanteenChaseAttempt } from "../../modules/ChapterThreeCanteenController";
import { setCanteenChaseSnapshot } from "./CanteenChaseRuntime";
import { obstaclesBetween, visibleObstacles } from "./canteen-chase/ChaseGeometry";
import { ChaseRenderer } from "./canteen-chase/ChaseRenderer";

interface CanteenChaseOverlayProps {
  events: EventBus;
  completed: boolean;
  attemptCount: number;
  bestDistance: number;
  bestLives: number;
  onAttempt: (attempt: CanteenChaseAttempt) => void;
  onContinue: () => void;
}

type ChaseMode = "story" | "endless";
type ChaseRunState = "ready" | "countdown" | "running" | "won" | "lost";

interface ChaseRuntime {
  mode: ChaseMode;
  runState: ChaseRunState;
  distance: number;
  lives: number;
  lane: number;
  collisions: number;
  countdownMs: number;
  invulnerableMs: number;
  milestone: number | null;
  milestoneMs: number;
  paused: boolean;
  hitObstacleIds: Set<string>;
  reachedMilestones: Set<number>;
  lastPublishedDistance: number;
}

interface ChaseView {
  mode: ChaseMode;
  runState: ChaseRunState;
  distance: number;
  lives: number;
  lane: number;
  collisions: number;
  countdown: number | null;
  milestone: number | null;
  paused: boolean;
}

const GOAL_DISTANCE = 755;
const MAX_LIVES = 3;
const MILESTONES = [188, 377, 566] as const;

function createInitialRuntime(completed: boolean): ChaseRuntime {
  return {
    mode: "story",
    runState: completed ? "won" : "ready",
    distance: completed ? GOAL_DISTANCE : 0,
    lives: completed ? MAX_LIVES : MAX_LIVES,
    lane: 1,
    collisions: 0,
    countdownMs: 0,
    invulnerableMs: 0,
    milestone: null,
    milestoneMs: 0,
    paused: typeof document !== "undefined" && document.visibilityState === "hidden",
    hitObstacleIds: new Set<string>(),
    reachedMilestones: new Set<number>(),
    lastPublishedDistance: -1
  };
}

function paceAt(distance: number, mode: ChaseMode): number {
  const capped = mode === "story" ? Math.min(distance, GOAL_DISTANCE) : Math.min(distance, 3200);
  return 0.031 + capped * 0.000021;
}

export function CanteenChaseOverlay({
  events,
  completed,
  attemptCount,
  bestDistance,
  bestLives,
  onAttempt,
  onContinue
}: CanteenChaseOverlayProps) {
  const hasCoarsePointer = useMediaQuery("(any-pointer: coarse)");
  const prefersReducedMotion = useMediaQuery("(prefers-reduced-motion: reduce)");
  const runtimeRef = useRef<ChaseRuntime>(createInitialRuntime(completed));
  const eventsRef = useRef(events);
  const onAttemptRef = useRef(onAttempt);
  const onContinueRef = useRef(onContinue);
  const theaterTransitionedRef = useRef(false);
  const theaterTransitionTimerRef = useRef<number | null>(null);
  const canvasRef = useRef<HTMLCanvasElement | null>(null);
  const rendererRef = useRef<ChaseRenderer | null>(null);
  const [view, setView] = useState<ChaseView>(() => toView(runtimeRef.current));
  eventsRef.current = events;
  onAttemptRef.current = onAttempt;
  onContinueRef.current = onContinue;

  const publish = useCallback((force = false) => {
    const runtime = runtimeRef.current;
    if (
      !force
      && runtime.runState === "running"
      && runtime.distance - runtime.lastPublishedDistance < 0.42
    ) return;
    runtime.lastPublishedDistance = runtime.distance;
    setView(toView(runtime));
  }, []);

  const enterTheater = useCallback(() => {
    if (theaterTransitionedRef.current) return;
    theaterTransitionedRef.current = true;
    if (theaterTransitionTimerRef.current !== null) {
      window.clearTimeout(theaterTransitionTimerRef.current);
      theaterTransitionTimerRef.current = null;
    }
    onContinueRef.current();
  }, []);

  const scheduleTheaterEntry = useCallback(() => {
    if (theaterTransitionTimerRef.current !== null) {
      window.clearTimeout(theaterTransitionTimerRef.current);
    }
    theaterTransitionTimerRef.current = window.setTimeout(enterTheater, 1650);
  }, [enterTheater]);

  const finishRun = useCallback((result: "won" | "lost") => {
    const runtime = runtimeRef.current;
    if (runtime.runState !== "running") return;
    runtime.runState = result;
    runtime.distance = result === "won" ? GOAL_DISTANCE : Math.floor(runtime.distance);
    runtime.countdownMs = 0;
    runtime.milestone = null;
    eventsRef.current.emit("canteen_chase_finish", {
      result,
      mode: runtime.mode,
      distance: Math.floor(runtime.distance),
      lives: runtime.lives,
      collisions: runtime.collisions
    });
    onAttemptRef.current({
      mode: runtime.mode,
      distance: Math.floor(runtime.distance),
      lives: runtime.lives,
      collisions: runtime.collisions
    });
    publish(true);
    if (result === "won" && runtime.mode === "story") scheduleTheaterEntry();
  }, [publish, scheduleTheaterEntry]);

  const advanceSimulation = useCallback((milliseconds: number) => {
    const runtime = runtimeRef.current;
    if (runtime.paused || milliseconds <= 0) return;
    let remaining = Math.min(5000, milliseconds);

    if (runtime.runState === "countdown") {
      const previousValue = Math.max(1, Math.ceil(runtime.countdownMs / 1000));
      const consumed = Math.min(remaining, runtime.countdownMs);
      runtime.countdownMs -= consumed;
      remaining -= consumed;
      const nextValue = runtime.countdownMs > 0 ? Math.max(1, Math.ceil(runtime.countdownMs / 1000)) : null;
      if (nextValue !== null && nextValue !== previousValue) {
        eventsRef.current.emit("canteen_chase_countdown", { value: nextValue });
      }
      if (runtime.countdownMs <= 0) {
        runtime.runState = "running";
        eventsRef.current.emit("canteen_chase_run_started", { mode: runtime.mode });
      }
      publish(true);
    }

    if (runtime.runState !== "running" || remaining <= 0) return;
    const previousDistance = runtime.distance;
    const nextDistance = runtime.mode === "story"
      ? Math.min(GOAL_DISTANCE, previousDistance + remaining * paceAt(previousDistance, runtime.mode))
      : previousDistance + remaining * paceAt(previousDistance, runtime.mode);
    runtime.invulnerableMs = Math.max(0, runtime.invulnerableMs - remaining);
    runtime.milestoneMs = Math.max(0, runtime.milestoneMs - remaining);
    if (runtime.milestoneMs === 0) runtime.milestone = null;

    for (const obstacle of obstaclesBetween(previousDistance, nextDistance)) {
      if (runtime.hitObstacleIds.has(obstacle.id)) continue;
      runtime.hitObstacleIds.add(obstacle.id);
      if (obstacle.lane === runtime.lane && runtime.invulnerableMs <= 0) {
        runtime.collisions += 1;
        runtime.lives = Math.max(0, runtime.lives - 1);
        runtime.invulnerableMs = 900;
        eventsRef.current.emit("canteen_chase_collision", {
          obstacleId: obstacle.id,
          kind: obstacle.kind,
          collisions: runtime.collisions,
          lives: runtime.lives
        });
        if (runtime.lives === 0) {
          runtime.distance = Math.floor(obstacle.distance);
          finishRun("lost");
          return;
        }
      } else {
        eventsRef.current.emit("canteen_chase_near_miss", {
          obstacleId: obstacle.id,
          kind: obstacle.kind
        });
      }
    }

    runtime.distance = nextDistance;
    for (const milestone of MILESTONES) {
      if (
        previousDistance < milestone
        && nextDistance >= milestone
        && !runtime.reachedMilestones.has(milestone)
      ) {
        runtime.reachedMilestones.add(milestone);
        runtime.milestone = milestone;
        runtime.milestoneMs = 1100;
        eventsRef.current.emit("canteen_chase_paper_nearer", { milestone });
      }
    }

    if (runtime.mode === "story" && runtime.distance >= GOAL_DISTANCE) {
      finishRun("won");
      return;
    }
    publish();
  }, [finishRun, publish]);

  const beginRun = useCallback((mode: ChaseMode) => {
    const runtime = runtimeRef.current;
    runtime.mode = mode;
    runtime.runState = "countdown";
    runtime.distance = 0;
    runtime.lives = MAX_LIVES;
    runtime.lane = 1;
    runtime.collisions = 0;
    runtime.countdownMs = 3000;
    runtime.invulnerableMs = 0;
    runtime.milestone = null;
    runtime.milestoneMs = 0;
    runtime.hitObstacleIds.clear();
    runtime.reachedMilestones.clear();
    runtime.lastPublishedDistance = -1;
    theaterTransitionedRef.current = false;
    if (theaterTransitionTimerRef.current !== null) {
      window.clearTimeout(theaterTransitionTimerRef.current);
      theaterTransitionTimerRef.current = null;
    }
    eventsRef.current.emit("canteen_chase_countdown", { value: 3, mode });
    publish(true);
  }, [publish]);

  const changeLane = useCallback((delta: number) => {
    const runtime = runtimeRef.current;
    if (runtime.runState !== "running" || runtime.paused) return;
    const nextLane = Math.max(0, Math.min(2, runtime.lane + delta));
    if (nextLane === runtime.lane) return;
    runtime.lane = nextLane;
    eventsRef.current.emit("canteen_chase_lane_changed", { lane: nextLane });
    publish(true);
  }, [publish]);

  const showTitle = useCallback(() => {
    const runtime = runtimeRef.current;
    runtime.runState = "ready";
    runtime.mode = "story";
    runtime.distance = 0;
    runtime.lives = MAX_LIVES;
    runtime.lane = 1;
    runtime.collisions = 0;
    runtime.milestone = null;
    if (theaterTransitionTimerRef.current !== null) {
      window.clearTimeout(theaterTransitionTimerRef.current);
      theaterTransitionTimerRef.current = null;
    }
    publish(true);
  }, [publish]);

  useEffect(() => () => {
    if (theaterTransitionTimerRef.current !== null) {
      window.clearTimeout(theaterTransitionTimerRef.current);
    }
  }, []);

  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    const renderer = new ChaseRenderer(canvas);
    rendererRef.current = renderer;
    renderer.setReducedMotion(prefersReducedMotion);
    renderer.render(runtimeRef.current);
    return () => {
      renderer.destroy();
      rendererRef.current = null;
    };
  }, [prefersReducedMotion]);

  useEffect(() => {
    const handleKeyDown = (event: KeyboardEvent) => {
      if (event.metaKey || event.ctrlKey || event.altKey) return;
      if (event.key === "ArrowLeft" || event.key.toLowerCase() === "a") {
        event.preventDefault();
        changeLane(-1);
      } else if (event.key === "ArrowRight" || event.key.toLowerCase() === "d") {
        event.preventDefault();
        changeLane(1);
      } else if (
        (event.key === "Enter" || event.key === " ")
        && runtimeRef.current.runState === "ready"
      ) {
        event.preventDefault();
        beginRun("story");
      }
    };
    window.addEventListener("keydown", handleKeyDown);
    return () => window.removeEventListener("keydown", handleKeyDown);
  }, [beginRun, changeLane]);

  useEffect(() => {
    const handleVisibility = () => {
      const runtime = runtimeRef.current;
      runtime.paused = document.visibilityState === "hidden";
      eventsRef.current.emit(runtime.paused ? "canteen_chase_paused" : "canteen_chase_resumed");
      publish(true);
    };
    document.addEventListener("visibilitychange", handleVisibility);
    return () => document.removeEventListener("visibilitychange", handleVisibility);
  }, [publish]);

  useEffect(() => {
    let frame = 0;
    let previous = performance.now();
    const tick = (now: number) => {
      const delta = Math.min(48, Math.max(0, now - previous));
      previous = now;
      advanceSimulation(delta);
      rendererRef.current?.render(runtimeRef.current);
      frame = window.requestAnimationFrame(tick);
    };
    frame = window.requestAnimationFrame(tick);
    return () => window.cancelAnimationFrame(frame);
  }, [advanceSimulation]);

  useEffect(() => {
    const previousAdvance = window.advanceTime;
    const advanceTime = (milliseconds: number) => {
      const duration = Math.max(0, Number(milliseconds) || 0);
      let remaining = duration;
      while (remaining > 0) {
        const step = Math.min(1000 / 60, remaining);
        advanceSimulation(step);
        remaining -= step;
      }
      rendererRef.current?.render(runtimeRef.current);
    };
    window.advanceTime = advanceTime;
    return () => {
      if (window.advanceTime !== advanceTime) return;
      if (previousAdvance) window.advanceTime = previousAdvance;
      else delete window.advanceTime;
    };
  }, [advanceSimulation]);

  useEffect(() => {
    const near = visibleObstacles(view.distance).slice(-5).map((obstacle) => ({
      id: obstacle.id,
      kind: obstacle.kind,
      lane: obstacle.lane,
      distanceAhead: Math.round(obstacle.distance - view.distance)
    }));
    setCanteenChaseSnapshot({
      active: true,
      coordinateSystem: "3D road projection, horizon at top center, distance increases forward",
      mode: view.mode,
      runState: view.runState,
      distance: Math.floor(view.distance),
      goal: view.mode === "story" ? GOAL_DISTANCE : null,
      lives: view.lives,
      lane: view.lane,
      collisions: view.collisions,
      paused: view.paused,
      countdown: view.countdown,
      visibleObstacles: near
    });
    return () => setCanteenChaseSnapshot(null);
  }, [view]);

  const currentBest = Math.max(bestDistance, Math.floor(view.distance));
  const storyCleared = completed || view.runState === "won";
  const resultDistance = Math.floor(view.distance);
  const resultBestLives = view.runState === "won" ? view.lives : bestLives;

  return (
    <section
      className={`canteen-chase-overlay canteen-bike-rush-3d is-${view.runState} ${view.paused ? "is-paused" : ""}`}
      aria-label="食堂到剧院：755 米 3D 自行车追逐"
      data-run-state={view.runState}
      data-mode={view.mode}
    >
      <canvas
        ref={canvasRef}
        className="canteen-bike-canvas"
        role="img"
        aria-label="三车道校园道路、骑车人物和前方障碍"
      />

      <header className="canteen-bike-hud" aria-label="骑行状态">
        <div className="canteen-bike-hud-card">
          <span>距离 DIST</span>
          <strong>{String(Math.floor(view.distance)).padStart(3, "0")}<small>{view.mode === "story" ? " / 755m" : "m"}</small></strong>
        </div>
        <div className="canteen-bike-hud-stack">
          <em>{view.mode === "story" ? "剧情模式" : "无尽模式"}</em>
          <div className="canteen-bike-hud-card is-lives">
            <span>机会 LIVES</span>
            <strong>{"■".repeat(view.lives)}{"□".repeat(MAX_LIVES - view.lives)}</strong>
          </div>
          <div className="canteen-bike-hud-card is-best">
            <span>最佳 BEST</span>
            <strong>{currentBest}m</strong>
          </div>
        </div>
      </header>

      {view.milestone !== null ? (
        <div className="canteen-bike-milestone" role="status">
          <strong>{view.milestone}m</strong>
          <span>{view.milestone === 188 ? "节奏提升" : view.milestone === 377 ? "拥堵升级" : "最后冲刺"}</span>
        </div>
      ) : null}

      {view.runState === "running" ? (
        <>
          {!hasCoarsePointer ? <div className="canteen-bike-key-hint"><kbd>A</kbd> / <kbd>←</kbd> 左移　·　右移 <kbd>→</kbd> / <kbd>D</kbd></div> : null}
          {hasCoarsePointer ? (
            <nav className="canteen-chase-controls" aria-label="追逐方向">
              <button type="button" aria-label="向左换道" disabled={view.lane === 0} onPointerDown={() => changeLane(-1)}>←</button>
              <button type="button" aria-label="向右换道" disabled={view.lane === 2} onPointerDown={() => changeLane(1)}>→</button>
            </nav>
          ) : null}
        </>
      ) : null}

      {view.runState === "ready" ? (
        <div className="canteen-bike-overlay-card">
          <span className="canteen-bike-kicker">EAST CANTEEN · 3D CHASE</span>
          <h2>755 米骑行追逐</h2>
          <p>餐盘回收费已经完成解锁。使用 A / D 或方向键换道，保留至少一次机会追到剧院。</p>
          <div className="canteen-bike-stats">
            <span>最佳<strong>{bestDistance}m</strong></span>
            <span>尝试<strong>{attemptCount}</strong></span>
          </div>
          <button type="button" className="canteen-bike-primary" onClick={() => beginRun("story")}>开始追逐 755m</button>
          {completed ? <button type="button" className="canteen-bike-secondary" onClick={() => beginRun("endless")}>无尽模式</button> : null}
          {!completed ? <small>完成 755 米剧情后开放无尽模式</small> : null}
        </div>
      ) : null}

      {view.runState === "won" || view.runState === "lost" ? (
        <div className="canteen-bike-overlay-card is-result">
          <b className={view.runState === "won" ? "is-win" : "is-loss"}>{view.runState === "won" ? "CLEAR" : "STOP"}</b>
          <h2>{view.runState === "won" ? "已追到剧院路口" : view.mode === "endless" ? "无尽骑行结束" : "追逐中断"}</h2>
          <p>{view.runState === "won" ? "纸条钻进剧院。正在跟进。" : `本次抵达 ${resultDistance} 米，重新规划换道时机后继续。`}</p>
          <div className="canteen-bike-stats">
            <span>本次<strong>{resultDistance}m</strong></span>
            <span>剩余<strong>{view.lives}</strong></span>
            <span>最佳机会<strong>{resultBestLives}</strong></span>
          </div>
          {view.runState === "won" || completed ? (
            <button type="button" className="canteen-bike-primary" onClick={enterTheater}>回到校园继续追踪</button>
          ) : null}
          {(view.runState === "won" || completed) ? (
            <button type="button" className="canteen-bike-secondary" onClick={() => beginRun("endless")}>无尽模式</button>
          ) : null}
          <button type="button" className="canteen-bike-secondary" onClick={() => beginRun(view.mode)}>再来一次</button>
          <button type="button" className="canteen-bike-text-button" onClick={showTitle}>返回骑行标题</button>
        </div>
      ) : null}

      {view.countdown !== null ? <div className="canteen-chase-countdown" role="status">{view.countdown}</div> : null}
      {view.paused ? <div className="canteen-chase-paused" role="status">已暂停<br /><small>返回页面后继续</small></div> : null}
    </section>
  );
}

function toView(runtime: ChaseRuntime): ChaseView {
  return {
    mode: runtime.mode,
    runState: runtime.runState,
    distance: runtime.distance,
    lives: runtime.lives,
    lane: runtime.lane,
    collisions: runtime.collisions,
    countdown: runtime.runState === "countdown" ? Math.max(1, Math.ceil(runtime.countdownMs / 1000)) : null,
    milestone: runtime.milestone,
    paused: runtime.paused
  };
}
