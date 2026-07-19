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
  const chapter = puzzle.nextQuestId === "chapter_three_book_hunt" || state.ui.libraryFinalsPhase === "friend_contacted"
    ? "chapter_three"
    : state.actOne.phase === "prologue"
      ? "chapter_one"
      : "chapter_two";
  const chapterTwoOpen = chapter !== "chapter_one";
  const library = state.actOne.phase === "complete" || LIBRARY_VISIBLE_PHASES.has(state.ui.libraryFinalsPhase);
  const recoveryProofsReady = puzzle.nonPersonProofStamped
    && puzzle.seatReceiptCollected
    && puzzle.presenceProofCollected;
  const cc98OwnerUpload = library && puzzle.archivedRuleCollected && recoveryProofsReady;
  const cc98Bd = puzzle.cc98UploadedEvidenceIds.length === 4
    && ["top_ten_rising", "top_ten_reached", "recovery_application", "pass_ready", "backpack_removed", "seat_recovered", "friend_contacted"]
      .includes(state.ui.libraryFinalsPhase);
  const libraryRecovery = RECOVERY_VISIBLE_PHASES.has(state.ui.libraryFinalsPhase);
  const bikeArcade = chapter === "chapter_three" || state.bikeArcade.unlocked;

  return {
    chapter,
    cc98: chapterTwoOpen,
    photos: library && puzzle.backpackInspected,
    departmentDirectory: chapterTwoOpen,
    weather: chapterTwoOpen,
    fullCampusMap: chapterTwoOpen,
    library,
    cc98OwnerUpload,
    cc98Bd,
    libraryRecovery,
    bikeArcade
  };
}

export function canEnterScene(state: GameState, scene: SceneId): boolean {
  const access = selectFeatureAccess(state);
  if (scene === "cc98") return access.cc98;
  if (scene === "photos") return access.photos;
  if (scene === "weather") return access.weather;
  if (scene === "bike_arcade") return access.bikeArcade;
  if (scene === "chapter_transition") return access.chapter !== "chapter_one";
  return true;
}

export function sanitizeZjudingPage(state: GameState, requested = state.ui.zjudingPage): ZjudingPage {
  const access = selectFeatureAccess(state);
  if (requested === "directory" && !access.departmentDirectory) return "hub";
  if (requested === "library_recovery" && !access.libraryRecovery) return access.library ? "library" : "hub";
  if (requested === "library_catalog" && !access.library) return "hub";
  if (requested === "library_spaces" || requested === "library_seat") return access.library ? "library" : "hub";
  if (requested === "library" && !access.library) return "hub";
  return requested;
}
