import type { GameState } from "../core/types";
import { isLegacyChapterFourPhoneGatePhase } from "../core/FeatureAccess";

export const CHAPTER_FOUR_CC98_CLUES = Object.freeze({
  studyIndexImported: "cc98_study_index_imported"
});

export const CHAPTER_FOUR_CC98_FACT_IDS = Object.freeze({
  courseYearIndex: "course_year_index",
  archivedDiscussion: "archived_discussion",
  fieldCheckRequired: "field_check_required"
});

export const REQUIRED_CHAPTER_FOUR_CC98_FACT_IDS = Object.freeze(
  Object.values(CHAPTER_FOUR_CC98_FACT_IDS)
);

export function selectChapterFourCc98Projection(state: GameState) {
  const clueIds = new Set(state.chapter4.clueIds);
  const legacyActive = state.chapter4.prologueSeen
    && isLegacyChapterFourPhoneGatePhase(state.chapter4.phase);
  return {
    visible: legacyActive,
    importAvailable: legacyActive
      && state.chapter4.floor === "A2"
      && state.chapter4.phase === "npc_schedule_route",
    imported: clueIds.has(CHAPTER_FOUR_CC98_CLUES.studyIndexImported)
  };
}
