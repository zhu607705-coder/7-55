import { useCallback, useEffect, useMemo, useRef, useState } from "react";
import campusPlateUrl from "../../assets/rpg/campus/zijingang_campus_plate.png";
import type { EventBus } from "../../core/EventBus";
import canteenContent from "../../data/chapter3-canteen.content.json";
import { setCanteenChaseSnapshot } from "./CanteenChaseRuntime";

interface CanteenChaseOverlayProps {
  events: EventBus;
  onComplete: (collisions: number) => void;
}

interface ChaseObstacle {
  id: string;
  at: number;
  lane: number;
  kind: "delivery" | "runner" | "bike";
}

const CHASE_DURATION_MS = 34000;
const LANE_Y = [220, 320, 420] as const;
const PLAYER_X = 220;
const OBSTACLE_APPROACH_SCALE = 1480;
const OBSTACLES: readonly ChaseObstacle[] = [
  { id: "delivery-1", at: 0.16, lane: 1, kind: "delivery" },
  { id: "runner-1", at: 0.28, lane: 0, kind: "runner" },
  { id: "bike-1", at: 0.39, lane: 2, kind: "bike" },
  { id: "runner-2", at: 0.51, lane: 1, kind: "runner" },
  { id: "delivery-2", at: 0.64, lane: 2, kind: "delivery" },
  { id: "bike-2", at: 0.76, lane: 0, kind: "bike" },
  { id: "delivery-3", at: 0.88, lane: 1, kind: "delivery" }
];

export function CanteenChaseOverlay({ events, onComplete }: CanteenChaseOverlayProps) {
  const [progress, setProgress] = useState(0);
  const [lane, setLane] = useState(1);
  const [collisions, setCollisions] = useState(0);
  const [slowed, setSlowed] = useState(false);
  const [paused, setPaused] = useState(document.visibilityState === "hidden");
  const [finishing, setFinishing] = useState(false);
  const [countdown, setCountdown] = useState<number | null>(3);
  const progressRef = useRef(0);
  const laneRef = useRef(1);
  const collisionsRef = useRef(0);
  const lastFrameRef = useRef<number | null>(null);
  const slowedUntilRef = useRef(0);
  const hitObstacleIdsRef = useRef(new Set<string>());
  const milestoneRef = useRef(new Set<number>());
  const completionScheduledRef = useRef(false);
  const lastLaneChangeAtRef = useRef(0);
  const chaseRunStartedRef = useRef(false);
  const countdownCueRef = useRef(new Set<number>());

  const changeLane = useCallback((delta: number) => {
    if (finishing || paused || countdown !== null) return;
    const now = Date.now();
    if (now - lastLaneChangeAtRef.current < 120) return;
    const next = Math.max(0, Math.min(2, laneRef.current + delta));
    if (next === laneRef.current) return;
    lastLaneChangeAtRef.current = now;
    laneRef.current = next;
    setLane(next);
    events.emit("canteen_chase_lane_changed", { lane: next });
  }, [countdown, events, finishing, paused]);

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
      const nextPaused = document.visibilityState === "hidden";
      setPaused(nextPaused);
      lastFrameRef.current = null;
      events.emit(nextPaused ? "canteen_chase_paused" : "canteen_chase_resumed");
    };
    document.addEventListener("visibilitychange", handleVisibility);
    return () => document.removeEventListener("visibilitychange", handleVisibility);
  }, [events]);

  useEffect(() => {
    if (paused || countdown === null) {
      if (countdown === null && !chaseRunStartedRef.current) {
        chaseRunStartedRef.current = true;
        events.emit("canteen_chase_run_started");
      }
      return undefined;
    }
    if (!countdownCueRef.current.has(countdown)) {
      countdownCueRef.current.add(countdown);
      events.emit("canteen_chase_countdown", { value: countdown });
    }
    const timer = window.setTimeout(() => {
      setCountdown((current) => current === null || current <= 1 ? null : current - 1);
    }, 1000);
    return () => window.clearTimeout(timer);
  }, [countdown, events, paused]);

  useEffect(() => {
    let frame = 0;
    const tick = (now: number) => {
      if (paused || finishing || countdown !== null) {
        lastFrameRef.current = now;
        frame = window.requestAnimationFrame(tick);
        return;
      }
      const lastFrame = lastFrameRef.current ?? now;
      const delta = Math.min(48, Math.max(0, now - lastFrame));
      lastFrameRef.current = now;
      const isSlowed = now < slowedUntilRef.current;
      setSlowed(isSlowed);
      const speedFactor = isSlowed ? 0.8 : 1;
      const nextProgress = Math.min(1, progressRef.current + delta * speedFactor / CHASE_DURATION_MS);
      progressRef.current = nextProgress;
      setProgress(nextProgress);

      OBSTACLES.forEach((obstacle) => {
        if (hitObstacleIdsRef.current.has(obstacle.id)) return;
        const obstacleX = PLAYER_X + (obstacle.at - nextProgress) * OBSTACLE_APPROACH_SCALE;
        if (obstacleX >= PLAYER_X - 22 && obstacleX <= PLAYER_X + 26) {
          hitObstacleIdsRef.current.add(obstacle.id);
          if (obstacle.lane === laneRef.current) {
            collisionsRef.current += 1;
            setCollisions(collisionsRef.current);
            slowedUntilRef.current = now + 800;
            setSlowed(true);
            events.emit("canteen_chase_collision", {
              obstacleId: obstacle.id,
              kind: obstacle.kind,
              collisions: collisionsRef.current
            });
          } else {
            events.emit("canteen_chase_near_miss", { obstacleId: obstacle.id, kind: obstacle.kind });
          }
        }
      });

      [0.34, 0.67].forEach((milestone) => {
        if (nextProgress >= milestone && !milestoneRef.current.has(milestone)) {
          milestoneRef.current.add(milestone);
          events.emit("canteen_chase_paper_nearer", { milestone });
        }
      });

      if (nextProgress >= 1 && !completionScheduledRef.current) {
        completionScheduledRef.current = true;
        setFinishing(true);
        events.emit("canteen_chase_finish", { collisions: collisionsRef.current });
        window.setTimeout(() => onComplete(collisionsRef.current), 900);
        return;
      }
      frame = window.requestAnimationFrame(tick);
    };
    frame = window.requestAnimationFrame(tick);
    return () => window.cancelAnimationFrame(frame);
  }, [countdown, events, finishing, onComplete, paused]);

  useEffect(() => {
    setCanteenChaseSnapshot({
      active: true,
      progress: Number(progress.toFixed(3)),
      lane,
      collisions,
      slowed,
      paused,
      countdown
    });
    return () => setCanteenChaseSnapshot(null);
  }, [collisions, countdown, lane, paused, progress, slowed]);

  const visibleObstacles = useMemo(() => OBSTACLES.map((obstacle) => ({
    ...obstacle,
    x: PLAYER_X + (obstacle.at - progress) * OBSTACLE_APPROACH_SCALE,
    y: LANE_Y[obstacle.lane]
  })).filter((obstacle) => obstacle.x > -120 && obstacle.x < 1080), [progress]);

  const imageX = -260 - progress * 2780;
  const paperX = finishing ? 1015 : 590 + Math.sin(progress * 28) * 22;
  const paperY = finishing ? 135 : 150 + Math.sin(progress * 18) * 18;

  return (
    <section className={`canteen-chase-overlay ${slowed ? "is-slowed" : ""} ${finishing ? "is-finishing" : ""} ${countdown !== null ? "is-counting-down" : ""}`} aria-label="食堂到剧院：扫码自行车与第一次追逐">
      <svg viewBox="0 0 960 540" role="img" aria-label="玩家骑车沿主路追纸条">
        <defs>
          <linearGradient id="canteen-chase-vignette" x1="0" y1="0" x2="1" y2="0">
            <stop offset="0" stopColor="#071019" stopOpacity="0.74" />
            <stop offset="0.18" stopColor="#071019" stopOpacity="0.06" />
            <stop offset="0.82" stopColor="#071019" stopOpacity="0.08" />
            <stop offset="1" stopColor="#071019" stopOpacity="0.76" />
          </linearGradient>
          <filter id="canteen-chase-paper-glow" x="-100%" y="-100%" width="300%" height="300%">
            <feDropShadow dx="0" dy="0" stdDeviation="7" floodColor="#65d7ff" floodOpacity="0.95" />
          </filter>
        </defs>
        <image href={campusPlateUrl} x={imageX} y="0" width="5849.45" height="540" preserveAspectRatio="xMinYMid meet" />
        <path d="M -60 460 C 200 420, 395 410, 1030 165" fill="none" stroke="#18222a" strokeOpacity="0.58" strokeWidth="250" />
        <path d="M -60 460 C 200 420, 395 410, 1030 165" fill="none" stroke="#ccd2c7" strokeOpacity="0.58" strokeWidth="8" strokeDasharray="28 28" />
        <rect x="0" y="0" width="960" height="540" fill="url(#canteen-chase-vignette)" />

        {visibleObstacles.map((obstacle) => (
          <Obstacle key={obstacle.id} x={obstacle.x} y={obstacle.y} kind={obstacle.kind} />
        ))}

        <g className="canteen-chase-paper" transform={`translate(${paperX} ${paperY})`} filter="url(#canteen-chase-paper-glow)">
          <path d={`M ${-72 + progress * 34} 1 L -22 1`} fill="none" stroke="#8ee6ff" strokeWidth="6" strokeLinecap="square" opacity="0.54" />
          <path d="M -18 -14 L 17 -10 L 14 16 L -14 13 Z" fill="#f2f4ed" stroke="#68d8ff" strokeWidth="3" />
          <path d="M -9 -5 L 9 -2 M -10 2 L 7 5" stroke="#71808a" strokeWidth="2" />
        </g>

        {progress >= 0.67 ? (
          <g className="canteen-chase-edge-fibers" fill="none" stroke="#7fdcf7" strokeWidth="3" opacity="0.58">
            <path d="M 6 110 Q 34 126 8 144 M 6 174 Q 38 190 9 210 M 954 96 Q 927 116 953 134 M 953 170 Q 922 188 952 207" />
          </g>
        ) : null}

        <g className="canteen-chase-player" transform={`translate(${PLAYER_X} ${LANE_Y[lane]})`}>
          <ellipse cx="0" cy="20" rx="34" ry="9" fill="#071019" opacity="0.38" />
          <circle cx="-20" cy="12" r="13" fill="none" stroke="#1d2630" strokeWidth="5" />
          <circle cx="22" cy="12" r="13" fill="none" stroke="#1d2630" strokeWidth="5" />
          <path d="M -20 12 L 0 -10 L 22 12 L -4 12 Z M 0 -10 L 13 -11" fill="none" stroke="#e35b4d" strokeWidth="5" />
          <rect x="-7" y="-39" width="17" height="26" fill="#315f9f" stroke="#17212a" strokeWidth="3" />
          <circle cx="2" cy="-49" r="10" fill="#e0b36f" stroke="#17212a" strokeWidth="3" />
        </g>

        <g className="canteen-chase-progress" transform="translate(180 72)">
          <rect x="0" y="0" width="310" height="18" rx="4" fill="#071019" opacity="0.82" />
          <rect x="3" y="3" width={304 * progress} height="12" rx="2" fill="#62c8e8" />
          <text x="0" y="42" fill="#fff7df" fontFamily="monospace" fontSize="16">{canteenContent.bike.setupDialogue[0]}</text>
        </g>
        <text x="760" y="90" fill="#fff7df" textAnchor="end" fontFamily="monospace" fontSize="18">{Math.round(progress * 70)}%</text>
      </svg>

      <nav className="canteen-chase-controls" aria-label="追逐方向">
        <button type="button" aria-label="向左换道" disabled={lane === 0 || finishing || countdown !== null} onPointerDown={() => changeLane(-1)}>←</button>
        <button type="button" aria-label="向右换道" disabled={lane === 2 || finishing || countdown !== null} onPointerDown={() => changeLane(1)}>→</button>
      </nav>
      {countdown !== null ? <div className="canteen-chase-countdown" role="status" aria-live="polite">{countdown}</div> : null}
      {paused ? <div className="canteen-chase-paused" role="status">暂停</div> : null}
    </section>
  );
}

function Obstacle({ x, y, kind }: { x: number; y: number; kind: ChaseObstacle["kind"] }) {
  if (kind === "runner") {
    return (
      <g transform={`translate(${x} ${y})`}>
        <ellipse cx="0" cy="18" rx="16" ry="6" fill="#071019" opacity="0.35" />
        <circle cx="0" cy="-17" r="8" fill="#d6aa70" stroke="#17212a" strokeWidth="3" />
        <path d="M 0 -9 L -4 8 L -17 20 M -3 5 L 13 18 M -2 -2 L 14 -8" fill="none" stroke="#7c4a9b" strokeWidth="6" strokeLinecap="square" />
      </g>
    );
  }
  if (kind === "bike") {
    return (
      <g transform={`translate(${x} ${y})`}>
        <circle cx="-22" cy="12" r="13" fill="none" stroke="#202a32" strokeWidth="5" />
        <circle cx="22" cy="12" r="13" fill="none" stroke="#202a32" strokeWidth="5" />
        <path d="M -22 12 L 0 -10 L 22 12 L -2 12 Z" fill="none" stroke="#d0b34d" strokeWidth="5" />
      </g>
    );
  }
  return (
    <g transform={`translate(${x} ${y})`}>
      <ellipse cx="0" cy="25" rx="39" ry="9" fill="#071019" opacity="0.36" />
      <rect x="-36" y="-25" width="72" height="47" rx="5" fill="#355b72" stroke="#17212a" strokeWidth="5" />
      <rect x="-30" y="-18" width="29" height="16" fill="#9bd2dd" />
      <rect x="8" y="-18" width="21" height="27" fill="#d4ad5d" />
      <circle cx="-22" cy="24" r="8" fill="#1a232a" />
      <circle cx="22" cy="24" r="8" fill="#1a232a" />
    </g>
  );
}
