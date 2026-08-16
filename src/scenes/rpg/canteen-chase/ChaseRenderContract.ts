export interface ChaseRenderState {
  runState: "running" | "won" | "lost";
  distance: number;
  lane: number;
  invulnerableMs: number;
  collisions: number;
  paused: boolean;
}

export interface ChaseRendererBackend {
  destroy(): void;
  setReducedMotion(reduced: boolean): void;
  render(state: ChaseRenderState): void;
}
