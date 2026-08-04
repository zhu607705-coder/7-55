import { cloneSerializable } from "../core/ClientCompatibility";

export type ChapterThreeOpeningPhase =
  | "conversation"
  | "record_scan"
  | "record_escape"
  | "mode_unlock"
  | "mode_explanation"
  | "paper_burst"
  | "paper_dialogue"
  | "exit_observation"
  | "cart_clear"
  | "route_confirm"
  | "route"
  | "arrival";

export interface ChapterThreeOpeningRuntimeSnapshot {
  coordinateSystem: "960x540 cutscene coordinates, origin at top-left, x right, y down";
  phase: ChapterThreeOpeningPhase;
  beatIndex: number;
  beatCount: number;
  beatProgress: number;
  overallProgress: number;
  lineIndex: number | null;
  paused: boolean;
  skipped: boolean;
  completionRequested: boolean;
}

let currentSnapshot: ChapterThreeOpeningRuntimeSnapshot | null = null;

export function setChapterThreeOpeningRuntimeSnapshot(
  snapshot: ChapterThreeOpeningRuntimeSnapshot
): void {
  currentSnapshot = cloneSerializable(snapshot);
}

export function getChapterThreeOpeningRuntimeSnapshot(): ChapterThreeOpeningRuntimeSnapshot | null {
  return currentSnapshot ? cloneSerializable(currentSnapshot) : null;
}

export function clearChapterThreeOpeningRuntimeSnapshot(): void {
  currentSnapshot = null;
}
