import { useCallback, useEffect, useMemo, useRef, useState } from "react";
import { useMediaQuery } from "../../components/useMediaQuery";
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
  crossingSide: -1 | 1;
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
    kind: OBSTACLE_KINDS[(hash >>> 16) % OBSTACLE_KINDS.length],
    crossingSide: (hash & 1) === 0 ? -1 : 1
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

function projectObstaclePoint(obstacle: ChaseObstacle, distanceAhead: number) {
  if (obstacle.kind !== "runner") {
    return {
      ...projectRoadPoint(distanceAhead, obstacle.lane),
      crossingSide: obstacle.crossingSide
    };
  }
  const depth = Math.max(0, Math.min(1, 1 - distanceAhead / VISIBLE_DISTANCE));
  const crossingProgress = Math.max(0, Math.min(1, (depth - 0.32) / 0.62));
  const easedProgress = crossingProgress * crossingProgress * (3 - 2 * crossingProgress);
  const roadsideLane = obstacle.crossingSide < 0 ? -1.25 : 3.25;
  const movingLane = roadsideLane + (obstacle.lane - roadsideLane) * easedProgress;
  return {
    ...projectRoadPoint(distanceAhead, movingLane),
    crossingSide: obstacle.crossingSide
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
  const hasCoarsePointer = useMediaQuery("(any-pointer: coarse)");
  const runtimeRef = useRef<ChaseRuntime>(createInitialRuntime(completed));
  const eventsRef = useRef(events);
  const onAttemptRef = useRef(onAttempt);
  const onContinueRef = useRef(onContinue);
  const theaterTransitionedRef = useRef(false);
  const theaterTransitionTimerRef = useRef<number | null>(null);
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
      projection: projectObstaclePoint(obstacle, obstacle.distance - view.distance)
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
            <stop offset="0" stopColor="#747e82" />
            <stop offset="0.5" stopColor="#4e575c" />
            <stop offset="1" stopColor="#2d3439" />
          </linearGradient>
          <linearGradient id="bike-rush-sidewalk" x1="0" y1="0" x2="0" y2="1">
            <stop offset="0" stopColor="#c9c7bc" />
            <stop offset="1" stopColor="#807f78" />
          </linearGradient>
          <linearGradient id="bike-rush-car" x1="0" y1="0" x2="1" y2="1">
            <stop offset="0" stopColor="#f07867" />
            <stop offset="0.55" stopColor="#c9443f" />
            <stop offset="1" stopColor="#8e2d35" />
          </linearGradient>
          <linearGradient id="bike-rush-glass" x1="0" y1="0" x2="1" y2="1">
            <stop offset="0" stopColor="#d8f5ff" />
            <stop offset="0.45" stopColor="#7caec4" />
            <stop offset="1" stopColor="#345a70" />
          </linearGradient>
          <radialGradient id="bike-rush-foliage" cx="38%" cy="30%" r="72%">
            <stop offset="0" stopColor="#78b95c" />
            <stop offset="0.55" stopColor="#3f8147" />
            <stop offset="1" stopColor="#22583a" />
          </radialGradient>
          <pattern id="bike-rush-asphalt" width="22" height="18" patternUnits="userSpaceOnUse">
            <circle cx="3" cy="4" r="1.2" fill="#c8d0d2" opacity="0.12" />
            <circle cx="16" cy="13" r="1" fill="#10171b" opacity="0.2" />
            <path d="M7 16 L12 14" stroke="#d8dfe0" strokeWidth="0.8" opacity="0.09" />
          </pattern>
          <pattern id="bike-rush-pavers" width="22" height="13" patternUnits="userSpaceOnUse">
            <path d="M0 0 H22 M0 13 H22 M11 0 V13" stroke="#5b605f" strokeWidth="1" opacity="0.32" />
          </pattern>
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
        <g className="canteen-bike-clouds" fill="#f5fbff" opacity="0.78">
          <path d="M84 84 C99 58 126 64 133 82 C153 65 185 77 184 99 H71 C70 92 75 86 84 84 Z" />
          <path d="M643 99 C658 78 682 80 691 98 C710 81 740 91 742 111 H628 C629 104 634 100 643 99 Z" opacity="0.7" />
        </g>
        <g className="canteen-bike-skyline" fill="#718b94" opacity="0.48">
          <path d="M0 145 V116 H40 V98 H73 V124 H112 V90 H157 V118 H201 V82 H252 V124 H301 V102 H347 V145 Z" />
          <path d="M612 145 V108 H658 V84 H708 V120 H746 V96 H790 V118 H838 V76 H884 V109 H927 V92 H960 V145 Z" />
          <g fill="#d8eef4" opacity="0.7">
            <rect x="126" y="101" width="7" height="7" /><rect x="146" y="101" width="7" height="7" />
            <rect x="218" y="94" width="8" height="8" /><rect x="240" y="94" width="8" height="8" />
            <rect x="679" y="96" width="8" height="8" /><rect x="703" y="96" width="8" height="8" />
            <rect x="855" y="89" width="8" height="8" /><rect x="878" y="89" width="8" height="8" />
          </g>
        </g>
        <path d="M0 145 L0 540 L960 540 L960 145 L540 128 L420 128 Z" fill="#658a55" />
        <path d="M0 150 L30 540 L0 540 Z M960 150 L930 540 L960 540 Z" fill="#3b7142" opacity="0.82" />
        <path d="M410 145 L12 540 L30 540 L420 145 Z" fill="url(#bike-rush-sidewalk)" />
        <path d="M550 145 L948 540 L930 540 L540 145 Z" fill="url(#bike-rush-sidewalk)" />
        <path d="M410 145 L12 540 L30 540 L420 145 Z M550 145 L948 540 L930 540 L540 145 Z" fill="url(#bike-rush-pavers)" opacity="0.75" />
        <path d="M420 145 L540 145 L930 540 L30 540 Z" fill="url(#bike-rush-road)" />
        <path d="M420 145 L540 145 L930 540 L30 540 Z" fill="url(#bike-rush-asphalt)" />
        <path d="M420 145 L30 540" stroke="#f0d54e" strokeWidth="7" />
        <path d="M540 145 L930 540" stroke="#f0d54e" strokeWidth="7" />
        <path d="M414 145 L18 540 M546 145 L942 540" stroke="#f8edb0" strokeWidth="2" opacity="0.65" />
        <path d="M480 145 L480 540" stroke="#f4f0de" strokeWidth="3" opacity="0.55" />
        <g className="canteen-bike-road-markings" fill="#f3f0df" opacity="0.48">
          <path d="M178 470 L213 422 L248 470 H228 V510 H198 V470 Z" />
          <path d="M712 470 L747 422 L782 470 H762 V510 H732 V470 Z" />
        </g>

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
              crossingSide={obstacle.projection.crossingSide}
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
            <button type="button" className="canteen-bike-primary" onClick={enterTheater}>立即进入剧院</button>
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
  const firstWorldIndex = Math.floor(distance / spacing) + 1;
  for (let index = 0; index < 10; index += 1) {
    const worldIndex = firstWorldIndex + index;
    const ahead = worldIndex * spacing - distance;
    const depth = Math.max(0, Math.min(1, 1 - ahead / VISIBLE_DISTANCE));
    const perspective = depth * depth;
    for (const side of [-1, 1] as const) {
      const variant = worldIndex * 2 + (side > 0 ? 1 : 0);
      result.push({
        id: `roadside-${worldIndex}-${side}`,
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
  const travel = distance * 0.72;
  const spacing = 42;
  const firstWorldIndex = Math.floor(travel / spacing) + 1;
  return Array.from({ length: 10 }, (_, index) => {
    const worldIndex = firstWorldIndex + index;
    const ahead = worldIndex * spacing - travel;
    const depthNear = Math.max(0, Math.min(1, 1 - ahead / 420));
    const depthFar = Math.max(0, Math.min(1, 1 - (ahead + 18) / 420));
    const top = 145 + depthFar * depthFar * 395;
    const bottom = 145 + depthNear * depthNear * 395;
    const halfTop = 4 + depthFar * 5;
    const halfBottom = 5 + depthNear * 7;
    return {
      id: `dash-${worldIndex}`,
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
      <g className="canteen-bike-roadside-tree" transform={transform} opacity={opacity}>
        <ellipse cx="0" cy="4" rx="42" ry="9" fill="#18251d" opacity="0.32" />
        <rect x="-20" y="-3" width="40" height="8" rx="2" fill="#59645b" />
        <path d="M-7 0 C-8 -27 -4 -58 0 -82 C7 -63 8 -35 7 0 Z" fill="#6d4b32" stroke="#3f3025" strokeWidth="4" />
        <path d="M0 -54 L-24 -82 M3 -66 L29 -91 M-1 -43 L18 -66" stroke="#68462f" strokeWidth="7" strokeLinecap="round" />
        <g fill="url(#bike-rush-foliage)" stroke="#285d3a" strokeWidth="3">
          <circle cx="-28" cy="-82" r="29" />
          <circle cx="4" cy="-102" r="36" />
          <circle cx="36" cy="-78" r="27" />
          <circle cx="-2" cy="-69" r="34" />
        </g>
        <g fill="#a3cf70" opacity="0.66">
          <circle cx="-22" cy="-95" r="6" />
          <circle cx="6" cy="-118" r="7" />
          <circle cx="31" cy="-91" r="5" />
          <circle cx="-3" cy="-81" r="5" />
        </g>
      </g>
    );
  }
  if (kind === "lamp") {
    return (
      <g className="canteen-bike-roadside-lamp" transform={transform} opacity={opacity}>
        <ellipse cx="0" cy="4" rx="22" ry="6" fill="#122027" opacity="0.34" />
        <path d="M-13 3 H13 L9 -8 H-9 Z" fill="#263039" stroke="#11181d" strokeWidth="3" />
        <rect x="-5" y="-112" width="10" height="108" rx="3" fill="#39464d" stroke="#1b252b" strokeWidth="3" />
        <rect x="-3" y="-108" width="3" height="99" fill="#718087" opacity="0.62" />
        <path
          d={side < 0 ? "M0 -108 H36 Q48 -108 48 -96" : "M0 -108 H-36 Q-48 -108 -48 -96"}
          fill="none"
          stroke="#303b42"
          strokeWidth="8"
          strokeLinecap="round"
        />
        <g transform={`translate(${side < 0 ? 48 : -48} -91)`}>
          <path d="M-17 -5 H17 L12 16 H-12 Z" fill="#28343c" stroke="#172127" strokeWidth="4" />
          <path d="M-10 -1 H10 L7 10 H-7 Z" fill="#fff1bd" opacity="0.92" />
          <circle cy="14" r="4" fill="#f0d54e" opacity="0.65" />
        </g>
        <g transform="translate(0 -69)">
          <rect x={side < 0 ? -4 : -40} y="-14" width="44" height="28" rx="3" fill="#214e65" stroke="#d9c260" strokeWidth="2" />
          <path d={side < 0 ? "M5 -6 H30 M5 1 H25 M5 8 H18" : "M-31 -6 H-6 M-26 1 H-6 M-19 8 H-6"} stroke="#d9eef4" strokeWidth="3" />
        </g>
      </g>
    );
  }
  const height = 86 + (variant % 4) * 18;
  const width = 76 + (variant % 3) * 16;
  const wall = ["#cfc6b4", "#bbc4ca", "#d8cdb8", "#b94b39"][variant % 4];
  const rows = Math.max(2, Math.floor((height - 28) / 28));
  const columns = width > 90 ? [-30, 0, 30] : [-22, 0, 22];
  return (
    <g className="canteen-bike-roadside-building" transform={transform} opacity={opacity}>
      <ellipse cx="0" cy="4" rx={width * 0.58} ry="9" fill="#172127" opacity="0.3" />
      <path
        d={`M${-width / 2} ${-height} H${width / 2} L${width / 2 + side * 12} ${-height + 12} V0 H${-width / 2} Z`}
        fill={wall}
        stroke="#4b5961"
        strokeWidth="5"
      />
      <rect x={-width / 2 - 6} y={-height - 13} width={width + 12} height="15" fill="#646f76" stroke="#3c474d" strokeWidth="3" />
      <rect x={-width / 2 + 7} y={-height - 22} width="22" height="10" fill="#71838b" />
      {Array.from({ length: rows }, (_, row) => columns.map((column) => (
        <g key={`${row}-${column}`} transform={`translate(${column} ${-height + 19 + row * 26})`}>
          <rect x="-9" y="-8" width="18" height="18" fill="#385b6d" stroke="#e5ded0" strokeWidth="3" />
          <path d="M0 -7 V9 M-8 1 H8" stroke="#92c9d6" strokeWidth="1.5" opacity="0.8" />
          {(row + column + variant) % 3 === 0 ? <rect x="-7" y="-6" width="6" height="5" fill="#f2da7f" opacity="0.85" /> : null}
        </g>
      )))}
      <path d="M-20 0 V-30 H20 V0" fill="#3d4e58" stroke="#24333b" strokeWidth="4" />
      <path d="M0 -28 V0" stroke="#9cc4cc" strokeWidth="2" />
      <path d="M-27 -34 H27 L20 -25 H-20 Z" fill="#2d6d79" stroke="#244852" strokeWidth="3" />
      <rect x="-31" y="-49" width="62" height="13" rx="2" fill="#23414d" stroke="#d5bd61" strokeWidth="2" />
      <path d="M-22 -43 H22" stroke="#f3efdc" strokeWidth="3" strokeDasharray="7 4" />
    </g>
  );
}

function Rider3D() {
  return (
    <g className="canteen-bike-rider-model">
      <ellipse cx="0" cy="31" rx="49" ry="13" fill="#071019" opacity="0.38" />
      <g className="canteen-bike-wheel is-front" transform="translate(0 -19)">
        <ellipse rx="9" ry="27" fill="none" stroke="#121c22" strokeWidth="7" />
        <ellipse rx="5" ry="22" fill="none" stroke="#819097" strokeWidth="2" />
      </g>
      <g className="canteen-bike-wheel is-rear" transform="translate(0 11)">
        <ellipse rx="18" ry="43" fill="none" stroke="#111b22" strokeWidth="9" />
        <ellipse rx="12" ry="36" fill="none" stroke="#87969d" strokeWidth="2" />
        <path d="M0 -34 V34 M-10 -24 L10 24 M10 -24 L-10 24" stroke="#aab5b9" strokeWidth="1.6" opacity="0.86" />
        <circle r="5" fill="#d8deda" stroke="#1b2429" strokeWidth="2" />
      </g>
      <path d="M-17 9 L-12 -31 L14 -31 L17 9 L0 21 Z M-12 -31 L0 8 L14 -31" fill="none" stroke="#f0d54e" strokeWidth="7" strokeLinejoin="round" />
      <path d="M0 -31 V-51 M-17 -51 H17" fill="none" stroke="#26333b" strokeWidth="6" strokeLinecap="round" />
      <path d="M-29 -57 Q0 -65 29 -57" fill="none" stroke="#26333b" strokeWidth="6" strokeLinecap="round" />
      <circle className="canteen-bike-crank" cx="0" cy="7" r="8" fill="#27343c" stroke="#e8d36b" strokeWidth="3" />
      <path className="canteen-bike-crank" d="M0 7 L11 16 M11 16 H20" stroke="#28343b" strokeWidth="4" strokeLinecap="round" />
      <path d="M-25 -43 H25 L20 -35 H-20 Z" fill="#202b32" stroke="#10181d" strokeWidth="3" />
      <rect x="-14" y="-3" width="28" height="11" rx="4" fill="#26343a" stroke="#111b20" strokeWidth="3" />
      <rect x="-7" y="-1" width="14" height="5" rx="2" fill="#e35d52" />

      <g className="canteen-bike-rider-bob">
        <g className="canteen-bike-leg is-left">
          <path d="M-10 -48 L-17 -18 L-9 6" fill="none" stroke="#1d2d42" strokeWidth="13" strokeLinecap="round" strokeLinejoin="round" />
          <path d="M-14 7 H-1" stroke="#edf1ed" strokeWidth="7" strokeLinecap="round" />
        </g>
        <g className="canteen-bike-leg is-right">
          <path d="M10 -48 L17 -15 L8 13" fill="none" stroke="#263b56" strokeWidth="13" strokeLinecap="round" strokeLinejoin="round" />
          <path d="M4 14 H18" stroke="#edf1ed" strokeWidth="7" strokeLinecap="round" />
        </g>
        <path d="M-18 -93 Q0 -103 18 -93 L21 -49 Q0 -40 -21 -49 Z" fill="#315f9f" stroke="#17283d" strokeWidth="5" />
        <path d="M-15 -84 H15 M-16 -57 H16" stroke="#75d5dc" strokeWidth="3" opacity="0.82" />
        <rect x="-14" y="-88" width="28" height="30" rx="6" fill="#294b73" stroke="#13253c" strokeWidth="3" />
        <path d="M-7 -82 H7 M-7 -75 H7" stroke="#9ee6e7" strokeWidth="2" />
        <path d="M-15 -88 L-28 -61 M15 -88 L28 -61" fill="none" stroke="#315f9f" strokeWidth="11" strokeLinecap="round" />
        <circle cx="-28" cy="-60" r="5" fill="#d8aa70" /><circle cx="28" cy="-60" r="5" fill="#d8aa70" />
        <circle cx="0" cy="-121" r="19" fill="#d8aa70" stroke="#17212a" strokeWidth="5" />
        <path d="M-18 -126 Q-9 -147 12 -143 Q25 -139 20 -119 L12 -111 H-15 Z" fill="#1d252b" stroke="#11181d" strokeWidth="4" />
        <path d="M-12 -130 Q0 -141 14 -133" fill="none" stroke="#4a555b" strokeWidth="3" />
        <path d="M-14 -112 Q0 -106 14 -112" fill="none" stroke="#2e3940" strokeWidth="3" />
      </g>
    </g>
  );
}

function Obstacle3D({
  kind,
  x,
  y,
  scale,
  opacity,
  crossingSide
}: {
  kind: ChaseObstacleKind;
  x: number;
  y: number;
  scale: number;
  opacity: number;
  crossingSide: -1 | 1;
}) {
  const transform = `translate(${x} ${y}) scale(${scale})`;
  if (kind === "barrier") {
    return (
      <g className="canteen-bike-obstacle is-barrier" transform={transform} opacity={opacity} filter="url(#bike-rush-shadow)">
        <ellipse cy="36" rx="70" ry="11" fill="#11191e" opacity="0.38" />
        <rect x="-64" y="-51" width="128" height="48" rx="6" fill="#f0d54e" stroke="#283139" strokeWidth="7" />
        <path d="M-56 -48 L-26 -6 M-16 -48 L14 -6 M24 -48 L54 -6" stroke="#29343b" strokeWidth="13" />
        <path d="M-51 -3 L-58 31 M51 -3 L58 31" stroke="#3c474e" strokeWidth="10" />
        <path d="M-68 31 H-43 M43 31 H68" stroke="#242e34" strokeWidth="9" strokeLinecap="round" />
        <rect x="-14" y="-68" width="28" height="12" rx="4" fill="#39444a" />
        <circle className="canteen-bike-warning-light" cx="0" cy="-69" r="10" fill="#ef5e51" stroke="#6f2322" strokeWidth="3" />
        <circle cx="0" cy="-72" r="4" fill="#ffd6af" opacity="0.85" />
        <rect x="-45" y="-39" width="21" height="8" fill="#fff2c4" opacity="0.92" />
        <rect x="24" y="-20" width="21" height="8" fill="#fff2c4" opacity="0.92" />
      </g>
    );
  }
  if (kind === "cone") {
    return (
      <g className="canteen-bike-obstacle is-cone" transform={transform} opacity={opacity} filter="url(#bike-rush-shadow)">
        <ellipse cy="16" rx="42" ry="10" fill="#11191e" opacity="0.34" />
        <rect x="-38" y="1" width="76" height="14" rx="3" fill="#bf5828" stroke="#71321d" strokeWidth="4" />
        <path d="M-26 2 L0 -82 L26 2 Z" fill="#ff8740" stroke="#71351e" strokeWidth="6" />
        <path d="M-18 -26 H18 L13 -44 H-13 Z" fill="#f7f2e8" stroke="#c9c7bf" strokeWidth="2" />
        <path d="M-8 -68 H8 L5 -78 H-5 Z" fill="#f7c16c" opacity="0.78" />
        <rect x="-28" y="6" width="56" height="4" fill="#f6c36f" opacity="0.78" />
      </g>
    );
  }
  if (kind === "car") {
    return (
      <g className="canteen-bike-obstacle is-car" transform={transform} opacity={opacity} filter="url(#bike-rush-shadow)">
        <ellipse cy="33" rx="69" ry="14" fill="#10181d" opacity="0.38" />
        <path d="M-62 -10 L-45 -69 Q-41 -79 -29 -81 H28 Q41 -78 45 -68 L62 -10 L54 30 H-54 Z" fill="url(#bike-rush-car)" stroke="#26313a" strokeWidth="7" />
        <path d="M-34 -67 Q-30 -72 -22 -73 H22 Q30 -71 34 -64 L43 -29 H-43 Z" fill="url(#bike-rush-glass)" stroke="#263b48" strokeWidth="4" />
        <path d="M0 -72 V-29" stroke="#263b48" strokeWidth="4" />
        <path d="M-49 -16 Q0 -30 49 -16 L44 6 H-44 Z" fill="#b83738" opacity="0.72" />
        <rect x="-23" y="-9" width="46" height="8" rx="3" fill="#7d2730" />
        <path d="M-25 9 H25 M-22 16 H22" stroke="#242d32" strokeWidth="4" />
        <rect x="-47" y="-8" width="18" height="13" rx="4" fill="#ffe79a" stroke="#7a5632" strokeWidth="3" />
        <rect x="29" y="-8" width="18" height="13" rx="4" fill="#ffe79a" stroke="#7a5632" strokeWidth="3" />
        <rect x="-13" y="20" width="26" height="9" rx="2" fill="#dce8e8" stroke="#40515a" strokeWidth="2" />
        <path d="M-62 -31 L-75 -37 V-24 H-60 M62 -31 L75 -37 V-24 H60" fill="#b83c3b" stroke="#26313a" strokeWidth="4" />
        {[-42, 42].map((wheelX) => (
          <g key={wheelX}>
            <circle cx={wheelX} cy="30" r="15" fill="#151e24" />
            <circle cx={wheelX} cy="30" r="7" fill="#89969b" />
            <path d={`M${wheelX - 6} 30 H${wheelX + 6} M${wheelX} 24 V36`} stroke="#d1d8d7" strokeWidth="2" />
          </g>
        ))}
      </g>
    );
  }
  if (kind === "crowd") {
    return (
      <g className="canteen-bike-obstacle is-crowd" transform={transform} opacity={opacity} filter="url(#bike-rush-shadow)">
        <ellipse cy="34" rx="65" ry="12" fill="#11191e" opacity="0.35" />
        {[-32, 0, 32].map((personX, index) => (
          <g key={personX} transform={`translate(${personX} ${index % 2 ? 4 : 0})`}>
            <circle cy="-62" r="15" fill="#d9aa70" stroke="#26313a" strokeWidth="4" />
            <path d={index === 1 ? "M-14 -66 Q0 -83 14 -64 V-57 H-14 Z" : "M-15 -68 Q0 -79 15 -66 L12 -55 H-13 Z"} fill={index === 2 ? "#5a3429" : "#26313a"} />
            <path d="M-16 -47 Q0 -54 16 -47 L14 0 H-14 Z" fill={["#315f9f", "#756aa9", "#e97b70"][index]} stroke="#29333a" strokeWidth="3" />
            <path d="M-9 0 L-15 31 M9 0 L15 31" stroke="#27323b" strokeWidth="10" strokeLinecap="round" />
            <path d="M-15 31 H-3 M8 31 H21" stroke="#e8ece8" strokeWidth="6" strokeLinecap="round" />
            <path d="M-14 -39 L-31 -12 M14 -39 L28 -9" stroke={["#315f9f", "#756aa9", "#e97b70"][index]} strokeWidth="9" strokeLinecap="round" />
            {index !== 1 ? <path d="M15 -42 Q30 -38 27 -17 H15 Z" fill="#293c50" stroke="#172534" strokeWidth="3" /> : null}
            <circle cx="-5" cy="-61" r="2" fill="#2b211e" /><circle cx="5" cy="-61" r="2" fill="#2b211e" />
          </g>
        ))}
      </g>
    );
  }
  if (kind === "runner") {
    const runnerTransform = `translate(${x} ${y}) scale(${scale * crossingSide} ${scale})`;
    return (
      <g className="canteen-bike-obstacle is-runner" transform={runnerTransform} opacity={opacity} filter="url(#bike-rush-shadow)">
        <ellipse cy="29" rx="49" ry="10" fill="#11191e" opacity="0.34" />
        <path d="M-63 -22 H-35 M-58 -10 H-39 M-69 2 H-49" stroke="#dce8ea" strokeWidth="4" opacity="0.62" />
        <g className="canteen-bike-runner-body">
          <circle cy="-75" r="17" fill="#d9aa70" stroke="#26313a" strokeWidth="4" />
          <path d="M-16 -80 Q-5 -96 13 -87 L18 -72 L7 -64 H-15 Z" fill="#2d2727" />
          <path d="M-2 -73 H10" stroke="#382a25" strokeWidth="2" />
          <circle cx="11" cy="-74" r="2" fill="#29201e" />
          <path d="M-14 -57 Q0 -64 17 -53 L10 -13 H-14 Z" fill="#756aa9" stroke="#34314b" strokeWidth="4" />
          <path d="M-8 -50 H11" stroke="#a89dd6" strokeWidth="3" />
          <rect x="-4" y="-45" width="14" height="16" rx="2" fill="#f2e8d5" />
          <path d="M3 -42 V-32 M-1 -37 H7" stroke="#6b5a8f" strokeWidth="2" />
          <path d="M15 -51 Q31 -50 30 -28 H15 Z" fill="#293c50" stroke="#172534" strokeWidth="3" />
        </g>
        <g className="canteen-bike-runner-leg is-leading">
          <path d="M-5 -14 L-39 22" fill="none" stroke="#263442" strokeWidth="13" strokeLinecap="round" />
          <path d="M-43 24 H-25" stroke="#edf1eb" strokeWidth="7" strokeLinecap="round" />
        </g>
        <g className="canteen-bike-runner-leg is-trailing">
          <path d="M3 -13 L36 14" fill="none" stroke="#33465a" strokeWidth="13" strokeLinecap="round" />
          <path d="M32 17 H49" stroke="#edf1eb" strokeWidth="7" strokeLinecap="round" />
        </g>
        <g className="canteen-bike-runner-arm is-leading">
          <path d="M-10 -50 L-41 -27" fill="none" stroke="#756aa9" strokeWidth="11" strokeLinecap="round" />
          <circle cx="-41" cy="-27" r="5" fill="#d9aa70" />
        </g>
        <g className="canteen-bike-runner-arm is-trailing">
          <path d="M12 -47 L40 -65" fill="none" stroke="#756aa9" strokeWidth="11" strokeLinecap="round" />
          <circle cx="40" cy="-65" r="5" fill="#d9aa70" />
        </g>
      </g>
    );
  }
  return (
    <g className="canteen-bike-obstacle is-bicycle" transform={transform} opacity={opacity} filter="url(#bike-rush-shadow)">
      <ellipse cy="32" rx="43" ry="10" fill="#11191e" opacity="0.34" />
      <g className="canteen-bike-wheel" transform="translate(0 12)">
        <ellipse rx="16" ry="39" fill="none" stroke="#17212a" strokeWidth="8" />
        <ellipse rx="10" ry="33" fill="none" stroke="#87969c" strokeWidth="2" />
        <path d="M0 -31 V31 M-8 -22 L8 22 M8 -22 L-8 22" stroke="#9eaaae" strokeWidth="1.6" />
      </g>
      <path d="M-15 10 L-10 -26 L12 -26 L16 10 L0 20 Z M-10 -26 L0 8 L12 -26" fill="none" stroke="#d0b34d" strokeWidth="7" strokeLinejoin="round" />
      <path d="M0 -27 V-43 M-24 -47 H24" stroke="#26333a" strokeWidth="5" strokeLinecap="round" />
      <rect x="-19" y="-37" width="38" height="8" rx="3" fill="#26333a" />
      <circle cy="-86" r="16" fill="#d9aa70" stroke="#26313a" strokeWidth="4" />
      <path d="M-15 -91 Q0 -106 16 -89 L13 -78 H-13 Z" fill="#234a66" />
      <path d="M-16 -72 Q0 -79 16 -70 L18 -35 H-18 Z" fill="#e97b70" stroke="#793d3b" strokeWidth="4" />
      <path d="M-13 -65 L-25 -46 M13 -65 L25 -46" stroke="#e97b70" strokeWidth="10" strokeLinecap="round" />
      <path d="M-8 -35 L-15 -8 M8 -35 L15 -5" stroke="#283743" strokeWidth="10" strokeLinecap="round" />
      <rect x="-20" y="-30" width="40" height="18" rx="3" fill="#687b82" stroke="#26333a" strokeWidth="4" />
      <path d="M-15 -25 H15 M-15 -19 H15" stroke="#d8e0dd" strokeWidth="2" />
    </g>
  );
}
