export interface CanteenChaseSnapshot {
  active: boolean;
  progress: number;
  lane: number;
  collisions: number;
  slowed: boolean;
  paused: boolean;
  countdown: number | null;
}

let snapshot: CanteenChaseSnapshot | null = null;

export function setCanteenChaseSnapshot(next: CanteenChaseSnapshot | null): void {
  snapshot = next;
}

export function getCanteenChaseSnapshot(): CanteenChaseSnapshot | null {
  return snapshot ? { ...snapshot } : null;
}
