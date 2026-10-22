import { cloneSerializable } from "../../../core/ClientCompatibility";
import type { FailureReason, InterceptionPhase, WordBody } from "./InterceptionModel";

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
  maxMisses: number | null;
  attempt: number;
  paddle: { xPercent: number; widthPercent: number };
  narratorOrb: { xPercent: number; yPercent: number } | null;
  lockProgress: number;
  lockRequiredMs: 1400;
  paused: boolean;
  feedback: "blocked" | "missed" | "round_failed" | null;
  interception: {
    stage: number; phase: InterceptionPhase; collected: string[]; missing: string[];
    clueIndex: number; failures: number; failureReason: FailureReason | null;
    boardX: number; boardY: number; boardAngle: number; words: WordBody[];
  };
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
