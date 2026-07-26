import { useCallback, useEffect, useMemo, useRef, useState } from "react";
import type { EventBus } from "../../core/EventBus";
import type { CanteenChaseAttempt } from "../../modules/ChapterThreeCanteenController";
import { setCanteenChaseSnapshot } from "./CanteenChaseRuntime";

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
type ChaseObstacleKind = "barrier" | "bicycle" | "crowd" | "cone" | "car" | "runner";

interface ChaseObstacle {
  id: string;
  distance: number;
  lane: number;
  kind: ChaseObstacleKind;
}

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
const OBSTACLE_START_DISTANCE = 78;
const OBSTACLE_INTERVAL = 66;
const VISIBLE_DISTANCE = 220;
const MILESTONES = [188, 377, 566] as const;
const OBSTACLE_KINDS: readonly ChaseObstacleKind[] = [
  "barrier",
  "bicycle",
  "crowd",
  "cone",
  "car",
  "runner"
];

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

function obstacleAt(index: number): ChaseObstacle {
  const hash = Math.imul(index + 11, 1103515245) >>> 0;
  return {
    id: `rush-${index}`,
    distance: OBSTACLE_START_DISTANCE + index * OBSTACLE_INTERVAL,
    lane: (hash >>> 8) % 3,
    kind: OBSTACLE_KINDS[(hash >>> 16) % OBSTACLE_KINDS.length]
  };
}

function obstaclesBetween(start: number, end: number): ChaseObstacle[] {
  const first = Math.max(0, Math.ceil((start - OBSTACLE_START_DISTANCE) / OBSTACLE_INTERVAL));
  const last = Math.max(first - 1, Math.floor((end - OBSTACLE_START_DISTANCE) / OBSTACLE_INTERVAL));
  const result: ChaseObstacle[] = [];
  for (let index = first; index <= last; index += 1) result.push(obstacleAt(index));
  return result;
}

function visibleObstacles(distance: number): ChaseObstacle[] {
  return obstaclesBetween(distance + 0.01, distance + VISIBLE_DISTANCE)
    .sort((left, right) => right.distance - left.distance);
}

function paceAt(distance: number, mode: ChaseMode): number {
  const capped = mode === "story" ? Math.min(distance, GOAL_DISTANCE) : Math.min(distance, 3200);
  return 0.031 + capped * 0.000021;
}

function projectRoadPoint(distanceAhead: number, lane: number) {
  const depth = Math.max(0, Math.min(1, 1 - distanceAhead / VISIBLE_DISTANCE));
  const perspective = depth * depth;
  return {
    x: 480 + (lane - 1) * (44 + perspective * 260),
    y: 148 + perspective * 350,
    scale: 0.18 + perspective * 1.28,
    opacity: 0.32 + perspective * 0.68
  };
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
  const runtimeRef = useRef<ChaseRuntime>(createInitialRuntime(completed));
  const eventsRef = useRef(events);
  const onAttemptRef = useRef(onAttempt);
  const [view, setView] = useState<ChaseView>(() => toView(runtimeRef.current));
  eventsRef.current = events;
  onAttemptRef.current = onAttempt;

  const publish = useCallback((force = false) => {
    const runtime = runtimeRef.current;
    const roundedDistance = Math.floor(runtime.distance);
    if (!force && roundedDistance === runtime.lastPublishedDistance && runtime.runState === "running") return;
    runtime.lastPublishedDistance = roundedDistance;
    setView(toView(runtime));
  }, []);

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
  }, [publish]);

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
    publish(true);
  }, [publish]);

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
    };
    window.advanceTime = advanceTime;
    return () => {
      if (window.advanceTime !== advanceTime) return;
      if (previousAdvance) window.advanceTime = previousAdvance;
      else delete window.advanceTime;
    };
  }, [advanceSimulation]);

  const visible = useMemo(
    () => visibleObstacles(view.distance).map((obstacle) => ({
      ...obstacle,
      projection: projectRoadPoint(obstacle.distance - view.distance, obstacle.lane)
    })),
    [view.distance]
  );

  useEffect(() => {
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
      visibleObstacles: visible.slice(-5).map((obstacle) => ({
        id: obstacle.id,
        kind: obstacle.kind,
        lane: obstacle.lane,
        distanceAhead: Math.round(obstacle.distance - view.distance)
      }))
    });
    return () => setCanteenChaseSnapshot(null);
  }, [view, visible]);

  const roadside = useMemo(() => createRoadside(view.distance), [view.distance]);
  const roadDashes = useMemo(() => createRoadDashes(view.distance), [view.distance]);
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
      <svg className="canteen-bike-3d-scene" viewBox="0 0 960 540" role="img" aria-label="三车道校园道路、骑车人物和前方障碍">
        <defs>
          <linearGradient id="bike-rush-sky" x1="0" y1="0" x2="0" y2="1">
            <stop offset="0" stopColor="#77b8ed" />
            <stop offset="1" stopColor="#d6e7ef" />
          </linearGradient>
          <linearGradient id="bike-rush-road" x1="0" y1="0" x2="0" y2="1">
            <stop offset="0" stopColor="#667074" />
            <stop offset="1" stopColor="#343b40" />
          </linearGradient>
          <linearGradient id="bike-rush-vignette" x1="0" y1="0" x2="1" y2="0">
            <stop offset="0" stopColor="#071019" stopOpacity="0.55" />
            <stop offset="0.22" stopColor="#071019" stopOpacity="0" />
            <stop offset="0.78" stopColor="#071019" stopOpacity="0" />
            <stop offset="1" stopColor="#071019" stopOpacity="0.55" />
          </linearGradient>
          <filter id="bike-rush-shadow" x="-100%" y="-100%" width="300%" height="300%">
            <feDropShadow dx="0" dy="5" stdDeviation="4" floodColor="#071019" floodOpacity="0.42" />
          </filter>
        </defs>

        <rect width="960" height="540" fill="url(#bike-rush-sky)" />
        <circle cx="790" cy="76" r="36" fill="#fff4c2" opacity="0.9" />
        <path d="M0 145 L0 540 L960 540 L960 145 L540 128 L420 128 Z" fill="#658a55" />
        <path d="M420 145 L540 145 L930 540 L30 540 Z" fill="url(#bike-rush-road)" />
        <path d="M420 145 L30 540" stroke="#f0d54e" strokeWidth="8" />
        <path d="M540 145 L930 540" stroke="#f0d54e" strokeWidth="8" />
        <path d="M480 145 L480 540" stroke="#f4f0de" strokeWidth="3" opacity="0.55" />

        {roadDashes.map((dash) => (
          <path
            key={dash.id}
            d={`M ${dash.leftTop} ${dash.top} L ${dash.rightTop} ${dash.top} L ${dash.rightBottom} ${dash.bottom} L ${dash.leftBottom} ${dash.bottom} Z`}
            fill="#f4f0de"
            opacity={dash.opacity}
          />
        ))}

        <g className="canteen-bike-roadside">
          {roadside.map((prop) => (
            <RoadsideProp key={prop.id} {...prop} />
          ))}
        </g>

        <g className="canteen-bike-target-paper" transform="translate(480 122)">
          <path d="M-17 -11 L17 -8 L14 15 L-14 12 Z" fill="#f5f3e8" stroke="#68d8ff" strokeWidth="2" />
          <path d="M-9 -3 L8 -1 M-8 4 L6 6" stroke="#71808a" strokeWidth="1.5" />
        </g>

        <g className="canteen-bike-obstacles">
          {visible.map((obstacle) => (
            <Obstacle3D
              key={obstacle.id}
              kind={obstacle.kind}
              x={obstacle.projection.x}
              y={obstacle.projection.y}
              scale={obstacle.projection.scale}
              opacity={obstacle.projection.opacity}
            />
          ))}
        </g>

        <g
          className={`canteen-bike-player ${runtimeRef.current.invulnerableMs > 0 ? "is-invulnerable" : ""}`}
          transform={`translate(${480 + (view.lane - 1) * 258} 452)`}
          filter="url(#bike-rush-shadow)"
        >
          <Rider3D />
        </g>

        <rect width="960" height="540" fill="url(#bike-rush-vignette)" pointerEvents="none" />
      </svg>

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
          <div className="canteen-bike-key-hint"><kbd>A</kbd> / <kbd>←</kbd> 左移　·　右移 <kbd>→</kbd> / <kbd>D</kbd></div>
          <nav className="canteen-chase-controls" aria-label="追逐方向">
            <button type="button" aria-label="向左换道" disabled={view.lane === 0} onPointerDown={() => changeLane(-1)}>←</button>
            <button type="button" aria-label="向右换道" disabled={view.lane === 2} onPointerDown={() => changeLane(1)}>→</button>
          </nav>
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
          <p>{view.runState === "won" ? "755 米剧情骑行完成，纸条已经钻进剧院。" : `本次抵达 ${resultDistance} 米，重新规划换道时机后继续。`}</p>
          <div className="canteen-bike-stats">
            <span>本次<strong>{resultDistance}m</strong></span>
            <span>剩余<strong>{view.lives}</strong></span>
            <span>最佳机会<strong>{resultBestLives}</strong></span>
          </div>
          {view.runState === "won" || completed ? (
            <button type="button" className="canteen-bike-primary" onClick={onContinue}>继续追踪纸条</button>
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

interface RoadsideProjection {
  id: string;
  side: -1 | 1;
  kind: "building" | "tree" | "lamp";
  x: number;
  y: number;
  scale: number;
  opacity: number;
  variant: number;
}

function createRoadside(distance: number): RoadsideProjection[] {
  const result: RoadsideProjection[] = [];
  const spacing = 24;
  const offset = distance % spacing;
  for (let index = 0; index < 10; index += 1) {
    const ahead = index * spacing + (spacing - offset);
    const depth = Math.max(0, Math.min(1, 1 - ahead / VISIBLE_DISTANCE));
    const perspective = depth * depth;
    for (const side of [-1, 1] as const) {
      const variant = index * 2 + (side > 0 ? 1 : 0);
      result.push({
        id: `roadside-${index}-${side}`,
        side,
        kind: variant % 5 === 0 ? "lamp" : variant % 3 === 0 ? "tree" : "building",
        x: 480 + side * (78 + perspective * 430),
        y: 145 + perspective * 350,
        scale: 0.15 + perspective * 1.18,
        opacity: 0.28 + perspective * 0.72,
        variant
      });
    }
  }
  return result.sort((left, right) => left.y - right.y);
}

function createRoadDashes(distance: number) {
  const offset = (distance * 0.72) % 42;
  return Array.from({ length: 10 }, (_, index) => {
    const ahead = index * 42 + (42 - offset);
    const depthNear = Math.max(0, Math.min(1, 1 - ahead / 420));
    const depthFar = Math.max(0, Math.min(1, 1 - (ahead + 18) / 420));
    const top = 145 + depthFar * depthFar * 395;
    const bottom = 145 + depthNear * depthNear * 395;
    const halfTop = 4 + depthFar * 5;
    const halfBottom = 5 + depthNear * 7;
    return {
      id: `dash-${index}`,
      top,
      bottom,
      leftTop: 480 - halfTop,
      rightTop: 480 + halfTop,
      leftBottom: 480 - halfBottom,
      rightBottom: 480 + halfBottom,
      opacity: 0.18 + depthNear * 0.72
    };
  });
}

function RoadsideProp({ side, kind, x, y, scale, opacity, variant }: RoadsideProjection) {
  const transform = `translate(${x} ${y}) scale(${scale})`;
  if (kind === "tree") {
    return (
      <g transform={transform} opacity={opacity}>
        <rect x="-6" y="-54" width="12" height="58" fill="#725037" />
        <polygon points="-42,-42 0,-104 42,-42" fill={variant % 2 ? "#397343" : "#4b8548"} />
        <polygon points="-34,-70 0,-126 34,-70" fill="#2f6b3f" />
      </g>
    );
  }
  if (kind === "lamp") {
    return (
      <g transform={transform} opacity={opacity}>
        <rect x="-4" y="-104" width="8" height="108" fill="#30363b" />
        <rect x={side < 0 ? -4 : -38} y="-105" width="42" height="7" fill="#30363b" />
        <circle cx={side < 0 ? 34 : -34} cy="-100" r="11" fill="#fff1bd" stroke="#52616a" strokeWidth="4" />
      </g>
    );
  }
  const height = 86 + (variant % 4) * 18;
  const width = 76 + (variant % 3) * 16;
  const wall = ["#cfc6b4", "#bbc4ca", "#d8cdb8", "#b94b39"][variant % 4];
  return (
    <g transform={transform} opacity={opacity}>
      <rect x={-width / 2} y={-height} width={width} height={height} fill={wall} stroke="#5d6770" strokeWidth="5" />
      <rect x={-width / 2 - 5} y={-height - 12} width={width + 10} height="14" fill="#69737b" />
      {[-1, 0, 1].map((column) => (
        <rect key={column} x={column * 22 - 7} y={-height + 22} width="14" height="20" fill="#759db5" />
      ))}
      <rect x="-12" y="-30" width="24" height="30" fill="#4c5962" />
    </g>
  );
}

function Rider3D() {
  return (
    <g>
      <ellipse cx="0" cy="18" rx="54" ry="12" fill="#071019" opacity="0.35" />
      <ellipse cx="-35" cy="2" rx="18" ry="34" fill="none" stroke="#17222a" strokeWidth="8" />
      <ellipse cx="35" cy="2" rx="18" ry="34" fill="none" stroke="#17222a" strokeWidth="8" />
      <path d="M-35 2 L0 -22 L35 2 L-6 2 Z M0 -22 L22 -25" fill="none" stroke="#f0d54e" strokeWidth="8" />
      <path d="M-5 -20 L-10 -54 L14 -72" fill="none" stroke="#2f5f9c" strokeWidth="15" strokeLinecap="round" />
      <circle cx="16" cy="-91" r="17" fill="#e0b36f" stroke="#17212a" strokeWidth="5" />
      <path d="M0 -100 Q16 -119 32 -98 L30 -87 L6 -88 Z" fill="#f0d54e" stroke="#17212a" strokeWidth="5" />
      <path d="M-7 -53 L-31 -28 M2 -54 L25 -34" fill="none" stroke="#315f9f" strokeWidth="10" strokeLinecap="round" />
    </g>
  );
}

function Obstacle3D({
  kind,
  x,
  y,
  scale,
  opacity
}: {
  kind: ChaseObstacleKind;
  x: number;
  y: number;
  scale: number;
  opacity: number;
}) {
  const transform = `translate(${x} ${y}) scale(${scale})`;
  if (kind === "barrier") {
    return (
      <g transform={transform} opacity={opacity} filter="url(#bike-rush-shadow)">
        <rect x="-58" y="-46" width="116" height="43" fill="#f0d54e" stroke="#283139" strokeWidth="7" />
        <path d="M-48 -43 L-20 -5 M-8 -43 L20 -5 M32 -43 L55 -12" stroke="#283139" strokeWidth="12" />
        <path d="M-43 -3 L-53 35 M43 -3 L53 35" stroke="#4e565c" strokeWidth="9" />
        <circle cx="0" cy="-58" r="10" fill="#ef5e51" />
      </g>
    );
  }
  if (kind === "cone") {
    return (
      <g transform={transform} opacity={opacity} filter="url(#bike-rush-shadow)">
        <rect x="-32" y="0" width="64" height="12" fill="#d9702e" />
        <path d="M-23 0 L0 -72 L23 0 Z" fill="#ff8c42" stroke="#773b1e" strokeWidth="5" />
        <path d="M-15 -25 L15 -25 L11 -39 L-11 -39 Z" fill="#f2eee2" />
      </g>
    );
  }
  if (kind === "car") {
    return (
      <g transform={transform} opacity={opacity} filter="url(#bike-rush-shadow)">
        <path d="M-56 -12 L-42 -65 L36 -65 L56 -12 L48 27 L-48 27 Z" fill="#d75649" stroke="#26313a" strokeWidth="7" />
        <path d="M-31 -57 L27 -57 L38 -24 L-41 -24 Z" fill="#98c3d5" />
        <circle cx="-37" cy="27" r="13" fill="#17212a" />
        <circle cx="37" cy="27" r="13" fill="#17212a" />
      </g>
    );
  }
  if (kind === "crowd") {
    return (
      <g transform={transform} opacity={opacity} filter="url(#bike-rush-shadow)">
        {[-32, 0, 32].map((personX, index) => (
          <g key={personX} transform={`translate(${personX} ${index % 2 ? 4 : 0})`}>
            <circle cy="-59" r="13" fill="#d9aa70" stroke="#26313a" strokeWidth="4" />
            <rect x="-14" y="-46" width="28" height="44" fill={["#315f9f", "#756aa9", "#e97b70"][index]} />
            <path d="M-8 -2 L-13 30 M8 -2 L13 30" stroke="#27323b" strokeWidth="9" />
          </g>
        ))}
      </g>
    );
  }
  if (kind === "runner") {
    return (
      <g transform={transform} opacity={opacity} filter="url(#bike-rush-shadow)">
        <circle cy="-67" r="15" fill="#d9aa70" stroke="#26313a" strokeWidth="4" />
        <path d="M0 -52 L-7 -10 L-38 20 M-4 -22 L30 -6 M-2 -38 L28 -55" fill="none" stroke="#756aa9" strokeWidth="13" strokeLinecap="round" />
      </g>
    );
  }
  return (
    <g transform={transform} opacity={opacity} filter="url(#bike-rush-shadow)">
      <ellipse cx="-29" cy="14" rx="14" ry="27" fill="none" stroke="#17212a" strokeWidth="7" />
      <ellipse cx="29" cy="14" rx="14" ry="27" fill="none" stroke="#17212a" strokeWidth="7" />
      <path d="M-29 14 L0 -13 L29 14 L-5 14 Z" fill="none" stroke="#d0b34d" strokeWidth="8" />
      <circle cx="2" cy="-58" r="14" fill="#d9aa70" stroke="#26313a" strokeWidth="4" />
      <path d="M0 -45 L-6 -10" stroke="#e97b70" strokeWidth="16" />
    </g>
  );
}
