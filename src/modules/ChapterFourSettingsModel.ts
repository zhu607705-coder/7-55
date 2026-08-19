import type { GameState } from "../core/types";

export const CHAPTER_FOUR_SETTINGS_CLUES = Object.freeze({
  backgroundActivityVerified: "settings_background_activity_verified",
  desktopLayoutRestored: "settings_desktop_layout_restored"
});

export const CHAPTER_FOUR_BACKGROUND_RECORD_IDS = Object.freeze({
  photoIndex: "photo_index_0755",
  clockWake: "clock_wake_0755",
  mapResume: "map_resume_0755"
});

export const REQUIRED_BACKGROUND_RECORD_IDS = Object.freeze(
  Object.values(CHAPTER_FOUR_BACKGROUND_RECORD_IDS)
);

export function selectChapterFourSettingsProjection(state: GameState) {
  const active = state.chapter4.prologueSeen && state.chapter4.phase !== "inactive";
  const clueIds = new Set(state.chapter4.clueIds);
  return {
    active,
    backgroundAuditAvailable: active,
    backgroundActivityVerified: clueIds.has(CHAPTER_FOUR_SETTINGS_CLUES.backgroundActivityVerified),
    desktopLayoutRestored: clueIds.has(CHAPTER_FOUR_SETTINGS_CLUES.desktopLayoutRestored)
  };
}
