export interface CanteenChaseSnapshot {
  active: boolean;
  coordinateSystem: "3D road projection, horizon at top center, distance increases forward";
  mode: "story";
  runState: "running" | "won" | "lost";
  distance: number;
  goal: number;
  lives: number;
  lane: number;
  collisions: number;
  paused: boolean;
  countdown: number | null;
  visibleObstacles: Array<{
    id: string;
    kind: string;
    lane: number;
    distanceAhead: number;
  }>;
  visiblePedestrians: Array<{
    id: string;
    kind: string;
    side: -1 | 1;
    distanceAhead: number;
  }>;
  narration: { id: string; text: string } | null;
}

let snapshot: CanteenChaseSnapshot | null = null;

export function setCanteenChaseSnapshot(next: CanteenChaseSnapshot | null): void {
  snapshot = next;
}

export function getCanteenChaseSnapshot(): CanteenChaseSnapshot | null {
  return snapshot ? { ...snapshot } : null;
}
