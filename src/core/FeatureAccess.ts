import type { FeatureAccess, GameState, SceneId, ZjudingPage } from "./types";

const LIBRARY_VISIBLE_PHASES = new Set<GameState["ui"]["libraryFinalsPhase"]>([
  "library_route_unlocked",
  "library_entered",
  "occupied_seat_found",
  "evidence_gathering",
  "bd_briefing",
  "top_ten_rising",
  "top_ten_reached",
  "recovery_application",
  "pass_ready",
  "backpack_removed",
  "seat_recovered",
  "friend_contacted"
]);

const RECOVERY_VISIBLE_PHASES = new Set<GameState["ui"]["libraryFinalsPhase"]>([
  "top_ten_reached",
  "recovery_application",
  "pass_ready",
  "backpack_removed",
  "seat_recovered",
  "friend_contacted"
]);

const LEGACY_CHAPTER_FOUR_PHONE_GATE_PHASES = new Set<string>([
  "arrival",
  "airflow_overlay",
  "elevator_track_sync",
  "npc_schedule_route",
  "corridor_bay_reconstruction",
  "wayfinding_fragment_board",
  "bridge_floor_discrimination",
  "stair_echo_direction",
  "multicam_video_edit",
  "echo_action_record",
  "dual_lift_logistics",
  "warm_air_balance",
  "route_schedule",
  "clock_phase_lock",
  "first_cycle_reset"
]);

/**
 * Read-only migration compatibility for the retired phone-gated Chapter 4
 * path. The current 13-phase 7:55 path never returns true here, so Settings,
 * CC98 and WeChat cannot become a second progression surface.
 */
export function isLegacyChapterFourPhoneGatePhase(phase: unknown): boolean {
  return typeof phase === "string" && LEGACY_CHAPTER_FOUR_PHONE_GATE_PHASES.has(phase);
}

export function selectFeatureAccess(state: GameState): FeatureAccess {
  const puzzle = state.ui.libraryFinalsPuzzle;
  const interludeActive = state.qizhenLake.phase === "complete"
    && !state.chapterThreeInterlude.completed;
  const chapterThreeActive = puzzle.nextQuestId === "chapter_three_canteen_hunt"
    || state.ui.libraryFinalsPhase === "friend_contacted"
    || state.canteenHunt.active
    || state.theaterHunt.active
    || state.qizhenLake.active;
  // 第四章只影响章节标识；Settings、微信和 CC98 保持普通入口规则。
  // 旧校时页已退出 07:55 主线，不再由 chapter_four 自动开放。
  const chapterFourActive = state.chapterThreeInterlude.completed
    && state.chapterThreeInterlude.replayUnlocked;
  const chapter = chapterFourActive
    ? "chapter_four"
    : chapterThreeActive
      ? "chapter_three"
      : state.actOne.phase === "prologue"
        ? "chapter_one"
        : "chapter_two";
  const chapterTwoOpen = chapter !== "chapter_one";
  const librarySceneAccess = state.actOne.phase === "complete" || LIBRARY_VISIBLE_PHASES.has(state.ui.libraryFinalsPhase);
  const libraryReservation = ["reservation_required", "movement_ready", "complete"].includes(state.actOne.phase)
    || state.ui.librarySeatReserved;
  const library = librarySceneAccess || libraryReservation;
  const libraryCatalog = librarySceneAccess && puzzle.catalogUnlocked;
  const cc98OwnerUpload = librarySceneAccess && puzzle.investigationOpened;
  const cc98Bd = puzzle.cc98UploadedEvidenceIds.length === 4
    && ["top_ten_rising", "top_ten_reached", "recovery_application", "pass_ready", "backpack_removed", "seat_recovered", "friend_contacted"]
      .includes(state.ui.libraryFinalsPhase);
  const libraryRecovery = RECOVERY_VISIBLE_PHASES.has(state.ui.libraryFinalsPhase);
  // The portrait runner remains a retained mini-game implementation, but it
  // no longer participates in the formal chapter-three unlock path.
  const bikeArcade = false;

  return {
    chapter,
    checkin: chapter === "chapter_one",
    cc98: chapterTwoOpen || interludeActive,
    photos: interludeActive || (librarySceneAccess && puzzle.backpackInspected && puzzle.investigationOpened),
    departmentDirectory: chapterTwoOpen,
    weather: chapterTwoOpen,
    fullCampusMap: chapterTwoOpen && state.actOne.dormHubUnlocked,
    library,
    libraryReservation,
    libraryCatalog,
    cc98OwnerUpload,
    cc98Bd,
    libraryRecovery,
    bikeArcade,
    timelineRecovery: interludeActive,
    voiceMemos: interludeActive,
    clockCalibration: false
  };
}

export function canEnterScene(state: GameState, scene: SceneId): boolean {
  const access = selectFeatureAccess(state);
  if (scene === "checkin") return access.checkin;
  if (scene === "cc98") return access.cc98;
  if (scene === "photos") return access.photos;
  if (scene === "timeline_recovery") return access.timelineRecovery;
  if (scene === "voice_memos") return access.voiceMemos;
  if (scene === "weather") return access.weather;
  if (scene === "bike_arcade") return access.bikeArcade;
  if (scene === "chapter_transition") return access.chapter !== "chapter_one";
  if (scene === "clock") return access.clockCalibration;
  return true;
}

export function sanitizeZjudingPage(state: GameState, requested = state.ui.zjudingPage): ZjudingPage {
  const access = selectFeatureAccess(state);
  if (requested === "campus_map" && !access.fullCampusMap) return "hub";
  if (requested === "directory" && !access.departmentDirectory) return "hub";
  if (requested === "library_recovery" && !access.libraryRecovery) return access.library ? "library" : "hub";
  if (requested === "library_catalog" && !access.libraryCatalog) return access.library ? "library" : "hub";
  if ((requested === "library_spaces" || requested === "library_seat") && !access.libraryReservation) return access.library ? "library" : "hub";
  if (requested === "library" && !access.library) return "hub";
  return requested;
}
