import { cloneSerializable } from "../../../core/ClientCompatibility";

export type EndingRuntimePhase =
  | "blackout"
  | "deploy"
  | "intercept"
  | "impact"
  | "miss"
  | "failed"
  | "lock"
  | "caught"
  | "burst"
  | "whiteout";

export interface EndingRuntimeSnapshot {
  coordinateSystem: "430x820 scene coordinates, origin at top-left, x right, y down";
  phase: EndingRuntimePhase;
  blockedCount: number;
  requiredBlocks: 3;
  misses: number;
  maxMisses: 3;
  attempt: number;
  paddle: { xPercent: number; widthPercent: number };
  narratorOrb: { xPercent: number; yPercent: number } | null;
  lockProgress: number;
  lockRequiredMs: 1400;
  paused: boolean;
  feedback: "blocked" | "missed" | "round_failed" | null;
}

let currentSnapshot: EndingRuntimeSnapshot | null = null;

export function setEndingRuntimeSnapshot(snapshot: EndingRuntimeSnapshot): void {
  currentSnapshot = cloneSerializable(snapshot);
}

export function getEndingRuntimeSnapshot(): EndingRuntimeSnapshot | null {
  return currentSnapshot ? cloneSerializable(currentSnapshot) : null;
}

export function clearEndingRuntimeSnapshot(): void {
  currentSnapshot = null;
}
