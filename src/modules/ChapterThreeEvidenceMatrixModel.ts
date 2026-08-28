import type { GameState } from "../core/types";
import type {
  ChapterThreeInterludeDestinationCandidateId,
  ChapterThreeInterludeNetworkRecordId
} from "../data/chapter3InterludeContent";

export type ChapterThreeEvidenceMatrixConflict =
  | "network_record_conflict"
  | "destination_conflict";

export interface ChapterThreeEvidenceMatrixEvaluation {
  accepted: boolean;
  conflict: ChapterThreeEvidenceMatrixConflict | null;
}

/**
 * 把网络页保存的候选记录放回四源证据矩阵中核对。筛选页只负责查询，
 * 不在保存动作发生时替玩家判定答案。
 */
export function evaluateChapterThreeEvidenceMatrix(
  interlude: GameState["chapterThreeInterlude"],
  destinationId: ChapterThreeInterludeDestinationCandidateId
): ChapterThreeEvidenceMatrixEvaluation {
  const recordId = interlude.networkRecordId as ChapterThreeInterludeNetworkRecordId | null;
  if (recordId !== "record_0755") {
    return { accepted: false, conflict: "network_record_conflict" };
  }
  if (destinationId !== "duan_yongping_a1") {
    return { accepted: false, conflict: "destination_conflict" };
  }
  return { accepted: true, conflict: null };
}
