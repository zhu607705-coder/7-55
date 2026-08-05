import { useCallback, useEffect, useRef, useState } from "react";
import { useMediaQuery } from "../../components/useMediaQuery";
import type { EventBus } from "../../core/EventBus";
import type { CanteenChaseAttempt } from "../../modules/ChapterThreeCanteenController";
import { setCanteenChaseSnapshot } from "./CanteenChaseRuntime";
import { obstaclesBetween, visibleObstacles } from "./canteen-chase/ChaseGeometry";
import { ChaseRenderer } from "./canteen-chase/ChaseRenderer";

interface CanteenChaseOverlayProps {
  events: EventBus;
  onAttempt: (attempt: CanteenChaseAttempt) => void;
  onContinue: () => void;
}

type ChaseRunState = "running" | "won" | "lost";

interface ChaseRuntime {
  runState: ChaseRunState;
  distance: number;
  lives: number;
  lane: number;
  collisions: number;
  invulnerableMs: number;
  milestone: number | null;
  milestoneMs: number;
  paused: boolean;
  hitObstacleIds: Set<string>;
  reachedMilestones: Set<number>;
  lastPublishedDistance: number;
}

interface ChaseView {
  runState: ChaseRunState;
  distance: number;
  lives: number;
  lane: number;
  collisions: number;
  milestone: number | null;
  paused: boolean;
}

const GOAL_DISTANCE = 755;
const MAX_LIVES = 3;
const MILESTONES = [188, 377, 566] as const;

function createInitialRuntime(): ChaseRuntime {
  return {
    runState: "running",
    distance: 0,
    lives: MAX_LIVES,
    lane: 1,
    collisions: 0,
    invulnerableMs: 0,
    milestone: null,
    milestoneMs: 0,
    paused: typeof document !== "undefined" && document.visibilityState === "hidden",
    hitObstacleIds: new Set<string>(),
    reachedMilestones: new Set<number>(),
    lastPublishedDistance: -1
  };
}

function paceAt(distance: number): number {
  const capped = Math.min(distance, GOAL_DISTANCE);
  return 0.031 + capped * 0.000021;
}

export function CanteenChaseOverlay({
  events,
  onAttempt,
  onContinue
}: CanteenChaseOverlayProps) {
  const hasCoarsePointer = useMediaQuery("(any-pointer: coarse)");
  const prefersReducedMotion = useMediaQuery("(prefers-reduced-motion: reduce)");
  const runtimeRef = useRef<ChaseRuntime>(createInitialRuntime());
  const eventsRef = useRef(events);
  const onAttemptRef = useRef(onAttempt);
  const onContinueRef = useRef(onContinue);
  const theaterTransitionedRef = useRef(false);
  const theaterTransitionTimerRef = useRef<number | null>(null);
  const retryTimerRef = useRef<number | null>(null);
  const startedRef = useRef(false);
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
    theaterTransitionTimerRef.current = window.setTimeout(enterTheater, 900);
  }, [enterTheater]);

  const restartStoryRun = useCallback(() => {
    const runtime = runtimeRef.current;
    runtime.runState = "running";
    runtime.distance = 0;
    runtime.lives = MAX_LIVES;
    runtime.lane = 1;
    runtime.collisions = 0;
    runtime.invulnerableMs = 0;
    runtime.milestone = null;
    runtime.milestoneMs = 0;
    runtime.hitObstacleIds.clear();
    runtime.reachedMilestones.clear();
    runtime.lastPublishedDistance = -1;
    theaterTransitionedRef.current = false;
    if (retryTimerRef.current !== null) {
      window.clearTimeout(retryTimerRef.current);
      retryTimerRef.current = null;
    }
    eventsRef.current.emit("canteen_chase_run_started", { mode: "story" });
    publish(true);
  }, [publish]);

  const finishRun = useCallback((result: "won" | "lost") => {
    const runtime = runtimeRef.current;
    if (runtime.runState !== "running") return;
    runtime.runState = result;
    runtime.distance = result === "won" ? GOAL_DISTANCE : Math.floor(runtime.distance);
    runtime.milestone = null;
    eventsRef.current.emit("canteen_chase_finish", {
      result,
      mode: "story",
      distance: Math.floor(runtime.distance),
      lives: runtime.lives,
      collisions: runtime.collisions
    });
    onAttemptRef.current({
      mode: "story",
      distance: Math.floor(runtime.distance),
      lives: runtime.lives,
      collisions: runtime.collisions
    });
    publish(true);
    if (result === "won") {
      scheduleTheaterEntry();
      return;
    }
    retryTimerRef.current = window.setTimeout(restartStoryRun, 900);
  }, [publish, restartStoryRun, scheduleTheaterEntry]);

  const advanceSimulation = useCallback((milliseconds: number) => {
    const runtime = runtimeRef.current;
    if (runtime.paused || milliseconds <= 0) return;
    const remaining = Math.min(5000, milliseconds);
    if (runtime.runState !== "running" || remaining <= 0) return;
    const previousDistance = runtime.distance;
    const nextDistance = Math.min(GOAL_DISTANCE, previousDistance + remaining * paceAt(previousDistance));
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

    if (runtime.distance >= GOAL_DISTANCE) {
      finishRun("won");
      return;
    }
    publish();
  }, [finishRun, publish]);

  const changeLane = useCallback((delta: number) => {
    const runtime = runtimeRef.current;
    if (runtime.runState !== "running" || runtime.paused) return;
    const nextLane = Math.max(0, Math.min(2, runtime.lane + delta));
    if (nextLane === runtime.lane) return;
    runtime.lane = nextLane;
    eventsRef.current.emit("canteen_chase_lane_changed", { lane: nextLane });
    publish(true);
  }, [publish]);

  useEffect(() => () => {
    if (theaterTransitionTimerRef.current !== null) {
      window.clearTimeout(theaterTransitionTimerRef.current);
    }
    if (retryTimerRef.current !== null) {
      window.clearTimeout(retryTimerRef.current);
    }
  }, []);

  useEffect(() => {
    if (startedRef.current) return;
    startedRef.current = true;
    eventsRef.current.emit("canteen_chase_run_started", { mode: "story" });
    publish(true);
  }, [publish]);

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
      }
    };
    window.addEventListener("keydown", handleKeyDown);
    return () => window.removeEventListener("keydown", handleKeyDown);
  }, [changeLane]);

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
      mode: "story",
      runState: view.runState,
      distance: Math.floor(view.distance),
      goal: GOAL_DISTANCE,
      lives: view.lives,
      lane: view.lane,
      collisions: view.collisions,
      paused: view.paused,
      countdown: null,
      visibleObstacles: near
    });
    return () => setCanteenChaseSnapshot(null);
  }, [view]);

  return (
    <section
      className={`canteen-chase-overlay canteen-bike-rush-3d is-${view.runState} ${view.paused ? "is-paused" : ""}`}
      aria-label="食堂到剧院：755 米 3D 自行车追逐"
      data-run-state={view.runState}
      data-mode="story"
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
          <strong>{String(Math.floor(view.distance)).padStart(3, "0")}<small> / 755m</small></strong>
        </div>
        <div className="canteen-bike-hud-card is-lives">
          <span>机会 LIVES</span>
          <strong>{"■".repeat(view.lives)}{"□".repeat(MAX_LIVES - view.lives)}</strong>
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

      {view.paused ? <div className="canteen-chase-paused" role="status">已暂停<br /><small>返回页面后继续</small></div> : null}
    </section>
  );
}

function toView(runtime: ChaseRuntime): ChaseView {
  return {
    runState: runtime.runState,
    distance: runtime.distance,
    lives: runtime.lives,
    lane: runtime.lane,
    collisions: runtime.collisions,
    milestone: runtime.milestone,
    paused: runtime.paused
  };
}
