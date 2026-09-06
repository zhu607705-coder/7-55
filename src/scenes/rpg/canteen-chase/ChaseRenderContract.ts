export interface ChaseRenderState {
  runState: "running" | "won" | "lost";
  distance: number;
  lane: number;
  invulnerableMs: number;
  collisions: number;
  paused: boolean;
  airHeight?: number; charge?: number; bellPulse?: number; boostSeconds?: number; shield?: boolean;
  paperLane?: number; paperGap?: number;
  clearedObstacleIds?: ReadonlySet<string>; collectedPickupIds?: ReadonlySet<string>;
}

export interface ChaseRendererBackend {
  destroy(): void;
  setReducedMotion(reduced: boolean): void;
  render(state: ChaseRenderState): void;
}
