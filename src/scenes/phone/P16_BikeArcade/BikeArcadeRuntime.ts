import type {
  BikeArcadeLane,
  BikeArcadeMilestone,
  BikeArcadeMode
} from "./BikeArcadeRules";

export type BikeArcadePhase = "intro" | "playing" | "won" | "lost";
export type BikeArcadeObstacleType = "bicycle" | "barrier" | "crowd";
export type BikeArcadePauseReason = "document-hidden" | "window-blur";
export type BikeArcadePauseTransition = "unchanged" | "paused" | "resume-pending";

export interface BikeArcadeFrame {
  deltaMs: number;
  paused: boolean;
  resumed: boolean;
}

export interface BikeArcadeCollisionEvent {
  obstacleType: BikeArcadeObstacleType;
  lives: number;
  invulnerableMs: 900;
}

export interface BikeArcadeLaneChangeEvent {
  from: BikeArcadeLane;
  to: BikeArcadeLane;
}

export interface BikeArcadeNearMissEvent {
  obstacleType: BikeArcadeObstacleType;
  lane: BikeArcadeLane;
}

export interface BikeArcadeBridge {
  onDistance: (distance: number) => void;
  onLives: (lives: number) => void;
  onFinish: (result: "won" | "lost", summary: BikeArcadeRunSummary) => void;
  onCollision: (event: BikeArcadeCollisionEvent) => void;
  onMilestone?: (milestone: BikeArcadeMilestone) => void;
  onLaneChanged?: (event: BikeArcadeLaneChangeEvent) => void;
  onNearMiss?: (event: BikeArcadeNearMissEvent) => void;
  onPauseChange?: (paused: boolean) => void;
  reducedMotion?: boolean;
}

export interface BikeArcadeRunSummary {
  distance: number;
  lives: number;
  lastMilestone: BikeArcadeMilestone | null;
  score?: number;
  combo?: number;
  lap?: number;
  tier?: number;
}

export type BikeArcadeStoryBridgeEvent =
  | { type: "distance"; distance: number }
  | { type: "lives"; lives: number }
  | { type: "collision"; event: BikeArcadeCollisionEvent }
  | { type: "milestone"; milestone: BikeArcadeMilestone }
  | { type: "lane_changed"; event: BikeArcadeLaneChangeEvent }
  | { type: "near_miss"; event: BikeArcadeNearMissEvent }
  | { type: "pause_changed"; paused: boolean }
  | { type: "finish"; result: "won" | "lost"; summary: BikeArcadeRunSummary };

export class BikeArcadeStoryBridgeDispatcher {
  private finished = false;

  constructor(private readonly bridge: BikeArcadeBridge) {}

  dispatch(event: BikeArcadeStoryBridgeEvent): boolean {
    if (this.finished) {
      return false;
    }
    switch (event.type) {
      case "distance":
        this.bridge.onDistance(event.distance);
        break;
      case "lives":
        this.bridge.onLives(event.lives);
        break;
      case "collision":
        this.bridge.onCollision(event.event);
        break;
      case "milestone":
        this.bridge.onMilestone?.(event.milestone);
        break;
      case "lane_changed":
        this.bridge.onLaneChanged?.(event.event);
        break;
      case "near_miss":
        this.bridge.onNearMiss?.(event.event);
        break;
      case "pause_changed":
        this.bridge.onPauseChange?.(event.paused);
        break;
      case "finish":
        this.finished = true;
        this.bridge.onFinish(event.result, event.summary);
        break;
    }
    return true;
  }
}

export class BikeArcadeLifecycle {
  private readonly pauseReasons = new Set<BikeArcadePauseReason>();
  private discardNextFrame = false;
  private readonly maxFrameDeltaMs: number;

  constructor(maxFrameDeltaMs = 100) {
    this.maxFrameDeltaMs = Math.max(0, maxFrameDeltaMs);
  }

  setPauseReason(reason: BikeArcadePauseReason, paused: boolean): BikeArcadePauseTransition {
    const wasPaused = this.pauseReasons.size > 0;
    if (paused) {
      this.pauseReasons.add(reason);
    } else {
      this.pauseReasons.delete(reason);
    }
    const isPaused = this.pauseReasons.size > 0;

    if (!wasPaused && isPaused) {
      this.discardNextFrame = false;
      return "paused";
    }
    if (wasPaused && !isPaused) {
      this.discardNextFrame = true;
      return "resume-pending";
    }
    return "unchanged";
  }

  consumeFrame(deltaMs: number): BikeArcadeFrame {
    if (this.pauseReasons.size > 0) {
      return { deltaMs: 0, paused: true, resumed: false };
    }
    if (this.discardNextFrame) {
      this.discardNextFrame = false;
      return { deltaMs: 0, paused: false, resumed: true };
    }
    const safeDelta = Number.isFinite(deltaMs) ? Math.max(0, deltaMs) : 0;
    return {
      deltaMs: Math.min(this.maxFrameDeltaMs, safeDelta),
      paused: false,
      resumed: false
    };
  }

  get activePauseReasons(): readonly BikeArcadePauseReason[] {
    return Array.from(this.pauseReasons);
  }

  reset(): void {
    this.pauseReasons.clear();
    this.discardNextFrame = false;
  }
}

export function resolveBikeArcadeReducedMotion(
  explicitFlag: boolean | undefined,
  mediaPreference: boolean
): boolean {
  return explicitFlag ?? mediaPreference;
}

export interface BikeArcadeObstacleSnapshot {
  lane: number;
  type: BikeArcadeObstacleType;
  y: number;
}

export interface BikeArcadeSnapshot {
  coordinateSystem: "390x650 canvas, origin at top-left, x right, y down";
  phase: BikeArcadePhase;
  mode?: BikeArcadeMode;
  distance: number;
  goal: 755;
  score?: number;
  combo?: number;
  lap?: number;
  tier?: number;
  lives: number;
  lane: number;
  invulnerable: boolean;
  obstacles: BikeArcadeObstacleSnapshot[];
  paused?: boolean;
  reducedMotion?: boolean;
  lastMilestone?: BikeArcadeMilestone | null;
  safeLane?: BikeArcadeLane;
  nextSpawnInMs?: number;
}

let currentSnapshot: BikeArcadeSnapshot | null = null;

export function setBikeArcadeSnapshot(snapshot: BikeArcadeSnapshot): void {
  currentSnapshot = {
    ...snapshot,
    obstacles: snapshot.obstacles.map((obstacle) => ({ ...obstacle }))
  };
}

export function getBikeArcadeSnapshot(): BikeArcadeSnapshot | null {
  if (!currentSnapshot) {
    return null;
  }
  return {
    ...currentSnapshot,
    obstacles: currentSnapshot.obstacles.map((obstacle) => ({ ...obstacle }))
  };
}

export function clearBikeArcadeSnapshot(): void {
  currentSnapshot = null;
}
