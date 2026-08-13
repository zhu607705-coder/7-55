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

export function selectFeatureAccess(state: GameState): FeatureAccess {
  const puzzle = state.ui.libraryFinalsPuzzle;
  const chapterThreeActive = puzzle.nextQuestId === "chapter_three_canteen_hunt"
    || state.ui.libraryFinalsPhase === "friend_contacted"
    || state.canteenHunt.active
    || state.theaterHunt.active
    || state.qizhenLake.active;
  // 第四章「校时」：启真湖流程完成后开放，优先级高于第三章。
  const chapterFourActive = state.qizhenLake.phase === "complete";
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
    cc98: chapterTwoOpen,
    photos: librarySceneAccess && puzzle.backpackInspected && puzzle.investigationOpened,
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
    clockCalibration: chapter === "chapter_four"
  };
}

export function canEnterScene(state: GameState, scene: SceneId): boolean {
  const access = selectFeatureAccess(state);
  if (scene === "checkin") return access.checkin;
  if (scene === "cc98") return access.cc98;
  if (scene === "photos") return access.photos;
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
