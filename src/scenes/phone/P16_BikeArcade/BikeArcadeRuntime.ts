import type { BikeArcadeLane, BikeArcadeMilestone } from "./BikeArcadeRules";

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

export interface BikeArcadeRunSummary {
  distance: number;
  lives: number;
  lastMilestone: BikeArcadeMilestone | null;
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
  distance: number;
  goal: 755;
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
