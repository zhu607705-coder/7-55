import type {
  ChapterFourPhase,
  ChapterFourRealityMode,
  ChapterFourTimeState
} from "../../core/types";
import {
  isChapterFourContextInteractionTargetId,
  selectChapterFourContextInteractionText,
  type ChapterFourContextInteractionTargetId
} from "../../data/ChapterFourInteractionContent";
import type {
  ChapterFour755Intent,
  ChapterFour755IntentResult,
  ChapterFour755SpatialResult
} from "../../modules/ChapterFourTemporalMazeController";
import { chapterFourInsertedPuzzleForTarget } from "../../modules/ChapterFourInsertedPuzzleModel";

export type ChapterFourContextInteractionIntent = Extract<
  ChapterFour755Intent,
  { type: "inspect_chapter_four_context" }
>;

export interface ChapterFourContextInteractionSubtitle {
  text: string;
  tone: "system";
  durationMs: 4400;
}

/**
 * Pure entry point shared by the Phaser scene and the executable validator.
 * It accepts either reality mode because the mode changes only the resulting
 * read-only subtitle; it does not introduce an observation/operation order.
 */
export function createChapterFourContextInteractionIntent(options: {
  targetId: string;
  spatial: ChapterFour755SpatialResult;
}): ChapterFourContextInteractionIntent | null {
  if (!isChapterFourContextInteractionTargetId(options.targetId)) return null;
  return {
    type: "inspect_chapter_four_context",
    targetId: options.targetId,
    spatial: { ...options.spatial }
  };
}

function isAcceptedReadOnlyContextResult(
  result: unknown
): result is ChapterFour755IntentResult & {
  accepted: true;
  changed: false;
  intentType: "inspect_chapter_four_context";
} {
  if (typeof result !== "object" || result === null) return false;
  const candidate = result as Partial<ChapterFour755IntentResult>;
  return candidate.accepted === true
    && candidate.changed === false
    && candidate.intentType === "inspect_chapter_four_context";
}

/**
 * Pure completion point for the accepted controller response. A subtitle is
 * produced only for the same read-only intent shape that the controller has
 * accepted; rejected, mutating, or mismatched responses cannot leak content.
 */
export function resolveChapterFourContextInteractionSubtitle(options: {
  targetId: string | undefined;
  phase: ChapterFourPhase | null;
  timeState: ChapterFourTimeState;
  mode: ChapterFourRealityMode;
  result: unknown;
}): ChapterFourContextInteractionSubtitle | null {
  if (!options.targetId
    || !isChapterFourContextInteractionTargetId(options.targetId)
    || chapterFourInsertedPuzzleForTarget(options.targetId) !== null
    || !isAcceptedReadOnlyContextResult(options.result)) return null;
  const text = selectChapterFourContextInteractionText({
    targetId: options.targetId as ChapterFourContextInteractionTargetId,
    phase: options.phase,
    timeState: options.timeState,
    mode: options.mode
  });
  return text === null
    ? null
    : { text, tone: "system", durationMs: 4400 };
}
