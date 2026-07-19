import type {
  ActOneBootstrapPhase,
  ActOneBootstrapState,
  BikeArcadeChapterState,
  GameState,
  LibraryEvidenceId,
  LibraryFinalsBdReplyId,
  LibraryFinalsPhase,
  LibraryFinalsPuzzleState,
  LibraryLocationId,
  LostFoundStage,
  LibraryRecoveryEvidenceId
} from "./types";
import { BIKE_SAVE_KEY, GAME_SAVE_BACKUP_KEY, GAME_SAVE_KEY } from "./StorageKeys";
import { canEnterScene, sanitizeZjudingPage } from "./FeatureAccess";

const SAVE_VERSION = 7;
const SUPPORTED_ENVELOPE_VERSIONS = new Set([2, 3, 4, 5, 6, SAVE_VERSION]);

const VALID_RUNTIME_MODES = new Set<GameState["runtimeMode"]>(["phone", "rpg"]);
const VALID_RPG_SCENES = new Set<GameState["rpgScene"]>(["campus_bootstrap", "dorm_hub", "library_interior"]);
const VALID_RPG_CHECKPOINTS = new Set<GameState["rpgCheckpoint"]>([
  "campus_library_gate",
  "library_entrance",
  "library_seat_022",
  "library_front_desk",
  "library_shelf_755"
]);
const VALID_ACT_ONE_PHASES = new Set<ActOneBootstrapPhase>([
  "prologue", "friend_message_required", "system_required", "inventory_required",
  "system_return_required", "reservation_briefing_required", "reservation_required",
  "movement_ready", "identity_required", "phone_link_required",
  "controls_required", "movement_required", "item_required", "map_required",
  "chapter_two_ready", "complete"
]);
const VALID_ACT_ONE_AREA_IDS = new Set(["north_gate", "bridge", "library", "game_kiosk"]);
const VALID_SCENES = new Set<GameState["currentScene"]>([
  "alarm", "desktop", "phone_home", "wechat", "cc98", "zjuding", "tiyi", "weather",
  "photos", "campus_card", "bike_arcade", "chapter_transition", "checkin", "bonsai", "ending"
]);
const VALID_NETWORK_MODES = new Set<GameState["networkMode"]>(["campus_wifi", "cellular", "offline"]);
const VALID_THEME_MODES = new Set<GameState["themeMode"]>(["normal", "dark", "backside"]);
const VALID_DIGIT_VALUES = new Set<NonNullable<GameState["digits"]["d1"]>>(["0", "7", "9", "8"]);
const VALID_ITEM_IDS = new Set<NonNullable<GameState["ui"]["selectedItem"]>>([
  "waterDrop", "headphone", "wateredHeadphone", "reverseGear", "slashLine", "towerKey",
  "fertilizer", "campusCard", "pushTriangle", "weatherWater", "mentorLine", "rightArrow",
  "gamepad", "occupancyNote", "callNumber755", "archivedLeaveRule", "itemRecognitionReport",
  "bagNonPersonProof", "seat022Receipt", "libraryPresenceProof", "seatReleasePass"
]);
const VALID_ZJUDING_PAGES = new Set<GameState["ui"]["zjudingPage"]>([
  "hub", "login", "directory", "learn", "library", "library_spaces", "library_seat",
  "library_catalog", "library_recovery"
]);
const VALID_LIBRARY_FINALS_PHASES = new Set<LibraryFinalsPhase>([
  "idle", "library_route_unlocked", "library_entered", "occupied_seat_found", "evidence_gathering",
  "top_ten_rising", "top_ten_reached", "recovery_application", "pass_ready", "backpack_removed",
  "seat_recovered", "friend_contacted"
]);
const LEGACY_LIBRARY_PHASES = new Set([
  "seat_reserved", "seat_lost", "cc98_filtering", "floor_47_found", "route_order_found",
  "route_active", "route_evidence_ready", "top_ten_rising", "top_ten_reached",
  "recovery_code_found", "route_audit_pending", "route_audit_passed", "seat_recovered"
]);
const VALID_LIBRARY_LOCATION_IDS = new Set<LibraryLocationId>([
  "entrance", "seat_022", "front_desk", "lost_found", "catalog_terminal", "printer", "shelf_755"
]);
const VALID_LIBRARY_EVIDENCE_IDS = new Set<LibraryEvidenceId>([
  "archived_leave_rule", "bag_non_person_proof", "seat_022_receipt", "library_presence_proof"
]);
const VALID_LIBRARY_RECOVERY_EVIDENCE_IDS = new Set<LibraryRecoveryEvidenceId>([
  "bag_non_person_proof", "seat_022_receipt", "library_presence_proof"
]);
const VALID_BD_REPLY_IDS = new Set<LibraryFinalsBdReplyId>([
  "reply-seat-ticket", "reply-visit-proof", "reply-bag-nonperson"
]);
const VALID_LOST_FOUND_STAGES = new Set<LostFoundStage>(["missing_report", "ready", "scanning", "stamped"]);
const VALID_CHAPTER_IDS = new Set<GameState["ui"]["seenChapterIntros"][number]>([
  "chapter_one", "chapter_two", "chapter_three"
]);

interface SaveEnvelope {
  version: 7;
  state: GameState;
  savedAt: number;
}

export class SaveStore {
  constructor(private readonly storage: Storage = window.localStorage) {}

  save(state: GameState): boolean {
    try {
      const existing = this.storage.getItem(GAME_SAVE_KEY);
      if (existing && isValidJsonRecord(existing)) {
        this.storage.setItem(GAME_SAVE_BACKUP_KEY, existing);
      }
      const envelope: SaveEnvelope = {
        version: SAVE_VERSION,
        state: createPersistentSnapshot(state),
        savedAt: Date.now()
      };
      this.storage.setItem(GAME_SAVE_KEY, JSON.stringify(envelope));
      return true;
    } catch {
      return false;
    }
  }

  load(initial: GameState): GameState | null {
    const primary = this.loadKey(GAME_SAVE_KEY, initial);
    if (primary) {
      return primary;
    }
    const backup = this.loadKey(GAME_SAVE_BACKUP_KEY, initial);
    if (backup) {
      const rawBackup = this.storage.getItem(GAME_SAVE_BACKUP_KEY);
      if (rawBackup) {
        this.storage.setItem(GAME_SAVE_KEY, rawBackup);
      }
    }
    return backup;
  }

  private loadKey(key: string, initial: GameState): GameState | null {
    try {
      const value = this.storage.getItem(key);
      if (!value) return null;
      const parsed = JSON.parse(value) as unknown;
      if (!isRecord(parsed)) return null;

      const isVersionedEnvelope = SUPPORTED_ENVELOPE_VERSIONS.has(Number(parsed.version)) && isRecord(parsed.state);
      const envelopeVersion = isVersionedEnvelope ? Number(parsed.version) : 0;
      const saved = isVersionedEnvelope ? parsed.state as Record<string, unknown> : parsed;
      const legacySave = !isVersionedEnvelope || envelopeVersion <= 6;
      let actOne = normalizeActOne(saved.actOne, initial.actOne, legacySave);
      const items = normalizeItems(saved.items, initial.items);
      const digits = normalizeDigits(saved.digits, initial.digits);
      const flags = normalizeFlags(saved.flags, initial.flags);
      const legacyIdentityOrMovementCompleted = actOne.characterNamed
        || actOne.manualControlTested
        || actOne.movementEnabled
        || actOne.canLeaveDorm
        || actOne.phase === "movement_ready"
        || actOne.phase === "complete";
      const campusCardMustBeAbsent = [
        "prologue",
        "friend_message_required",
        "system_required",
        "inventory_required"
      ].includes(actOne.phase) && !(legacySave && legacyIdentityOrMovementCompleted);
      const campusCardRecovered = !campusCardMustBeAbsent && (
        items.campusCard
        || actOne.inventoryRecovered
        || (legacySave && legacyIdentityOrMovementCompleted)
      );
      if (campusCardMustBeAbsent) {
        items.campusCard = false;
        actOne = { ...actOne, inventoryRecovered: false };
      } else if (campusCardRecovered) {
        items.campusCard = true;
        actOne = {
          ...actOne,
          inventoryRecovered: true,
          phase: actOne.phase === "inventory_required" ? "system_return_required" : actOne.phase
        };
      }
      actOne = {
        ...actOne,
        dormHubUnlocked: !["prologue", "friend_message_required", "system_required"].includes(actOne.phase)
      };
      const ui = normalizeUi(saved.ui, initial.ui, !isVersionedEnvelope, actOne);
      if (legacySave) {
        const puzzle = ui.libraryFinalsPuzzle;
        const catalogWasAlreadyPassed = puzzle.catalogSearchCompleted
          || puzzle.callNumberCollected
          || puzzle.archivedRuleCollected
          || puzzle.archivedRuleRead
          || puzzle.photoDimmed
          || puzzle.itemReportGenerated
          || puzzle.nonPersonProofStamped;
        const archivedRuleWasAlreadyRead = puzzle.photoDimmed
          || puzzle.itemReportGenerated
          || puzzle.nonPersonProofStamped;
        ui.libraryFinalsPuzzle = {
          ...puzzle,
          catalogUnlocked: puzzle.catalogUnlocked || catalogWasAlreadyPassed,
          archivedRuleRead: puzzle.archivedRuleRead || archivedRuleWasAlreadyRead,
          photoCaptured: puzzle.photoCaptured || puzzle.photoDimmed || puzzle.itemReportGenerated,
          preBdBriefingSeen: puzzle.preBdBriefingSeen || puzzle.bdCount > 0
        };
      }
      if (actOne.pushTriangleTaken && actOne.pushTriangleTapCount < 3) {
        actOne = { ...actOne, pushTriangleTapCount: 3 };
      }
      if (
        legacySave
        && actOne.phase === "movement_ready"
        && actOne.manualControlTested
        && !ui.librarySeatReserved
      ) {
        actOne = { ...actOne, phase: "reservation_briefing_required", canLeaveDorm: false };
      }
      if (actOne.phase === "reservation_required" && ui.librarySeatReserved) {
        actOne = { ...actOne, phase: "movement_ready", canLeaveDorm: true };
      }
      if (actOne.phase === "movement_ready" || actOne.phase === "complete") {
        ui.librarySelectedSeat = "022";
        ui.librarySeatReserved = true;
        actOne = { ...actOne, canLeaveDorm: true };
      }
      if (envelopeVersion <= 5 && actOne.phase === "system_return_required") {
        ui.inventoryOpen = false;
        ui.selectedItem = null;
      }
      if (items.rightArrow && !actOne.rightArrowAssembled) {
        actOne = { ...actOne, rightArrowAssembled: true };
      }
      if (actOne.rightArrowAssembled) {
        items.rightArrow = true;
      }
      if (items.gamepad && !actOne.gamepadPurchased) {
        actOne = { ...actOne, gamepadPurchased: true };
      }
      if (actOne.gamepadPurchased && !actOne.controlsInstalled) {
        items.gamepad = true;
      }
      if (actOne.controlsInstalled) {
        items.gamepad = false;
        actOne = {
          ...actOne,
          movementEnabled: actOne.characterNamed && actOne.exerciseStarted
        };
      }

      const bikeArcade = normalizeBikeArcade(saved.bikeArcade, initial.bikeArcade);
      if (ui.libraryFinalsPhase === "friend_contacted" || ui.libraryFinalsPuzzle.nextQuestId === "chapter_three_book_hunt") {
        bikeArcade.unlocked = true;
      }

      normalizeConsumedItems(items, ui);
      if (ui.selectedItem && !items[ui.selectedItem]) {
        ui.selectedItem = null;
      }
      const hydrated: GameState = {
        runtimeMode: enumOr(saved.runtimeMode, VALID_RUNTIME_MODES, initial.runtimeMode),
        rpgScene: enumOr(saved.rpgScene, VALID_RPG_SCENES, initial.rpgScene),
        rpgCheckpoint: enumOr(saved.rpgCheckpoint, VALID_RPG_CHECKPOINTS, initial.rpgCheckpoint),
        currentScene: enumOr(saved.currentScene, VALID_SCENES, initial.currentScene),
        networkMode: enumOr(saved.networkMode, VALID_NETWORK_MODES, initial.networkMode),
        themeMode: enumOr(saved.themeMode, VALID_THEME_MODES, initial.themeMode),
        digits,
        items,
        flags,
        actOne,
        bikeArcade,
        ui
      };
      hydrated.currentScene = canEnterScene(hydrated, hydrated.currentScene) ? hydrated.currentScene : "phone_home";
      hydrated.ui.zjudingPage = sanitizeZjudingPage(hydrated);
      return hydrated;
    } catch {
      return null;
    }
  }

  saveBikeArcade(state: GameState): boolean {
    try {
      this.storage.setItem(BIKE_SAVE_KEY, JSON.stringify({ version: SAVE_VERSION, bikeArcade: state.bikeArcade }));
      return true;
    } catch {
      return false;
    }
  }

  loadBikeArcade(initial: GameState): BikeArcadePersistence | null {
    try {
      const value = this.storage.getItem(BIKE_SAVE_KEY);
      if (value) {
        const saved = JSON.parse(value) as unknown;
        if (isRecord(saved)) {
          const legacyUnlocked = saved.version === 1 && saved.libraryFinalsPhase === "seat_recovered";
          return { bikeArcade: normalizeBikeArcade(saved.bikeArcade, initial.bikeArcade, legacyUnlocked) };
        }
      }
    } catch {
      // Fall through to the validated full save.
    }

    const full = this.load(initial);
    return full ? { bikeArcade: full.bikeArcade } : null;
  }

  clear(): void {
    this.storage.removeItem(GAME_SAVE_KEY);
    this.storage.removeItem(GAME_SAVE_BACKUP_KEY);
    this.storage.removeItem(BIKE_SAVE_KEY);
  }
}

function createPersistentSnapshot(state: GameState): GameState {
  return {
    ...state,
    ui: {
      ...state.ui,
      controlCenterOpen: false,
      inventoryOpen: false,
      selectedItem: null
    }
  };
}

function isValidJsonRecord(value: string): boolean {
  try {
    return isRecord(JSON.parse(value));
  } catch {
    return false;
  }
}

export interface BikeArcadePersistence {
  bikeArcade: BikeArcadeChapterState;
}

function normalizeBikeArcade(
  value: unknown,
  initial: BikeArcadeChapterState,
  legacyUnlocked = false
): BikeArcadeChapterState {
  const saved = asRecord(value);
  return {
    unlocked: booleanOr(saved.unlocked, legacyUnlocked || initial.unlocked),
    completed: booleanOr(saved.completed, initial.completed),
    attemptCount: nonNegativeSafeIntegerOr(saved.attemptCount, initial.attemptCount),
    bestDistance: rangedNumberOr(saved.bestDistance, 0, 755, initial.bestDistance),
    bestLives: rangedIntegerOr(saved.bestLives, 0, 3, initial.bestLives)
  };
}

function normalizeActOne(value: unknown, initial: ActOneBootstrapState, legacyControlsCoupled: boolean): ActOneBootstrapState {
  const saved = asRecord(value);
  const savedPhase = enumOr(saved.phase, VALID_ACT_ONE_PHASES, initial.phase);
  const phase = (["identity_required", "phone_link_required", "controls_required", "item_required", "map_required", "chapter_two_ready"] as ActOneBootstrapPhase[]).includes(savedPhase)
    ? "movement_required"
    : savedPhase;
  const characterNamed = booleanOr(saved.characterNamed, booleanOr(saved.identityVerified, initial.characterNamed));
  const gamepadPurchased = booleanOr(saved.gamepadPurchased, false);
  const exerciseStarted = booleanOr(saved.exerciseStarted, false);
  const controlsInstalled = booleanOr(saved.controlsInstalled, legacyControlsCoupled && gamepadPurchased);
  return {
    phase,
    identityVerified: characterNamed,
    phoneLinked: booleanOr(saved.phoneLinked, initial.phoneLinked),
    controlsInstalled,
    movementEnabled: characterNamed && exerciseStarted && controlsInstalled,
    inventoryRecovered: booleanOr(saved.inventoryRecovered, initial.inventoryRecovered),
    characterPromptSeen: booleanOr(saved.characterPromptSeen, initial.characterPromptSeen),
    characterNamed,
    exerciseStarted,
    pushTriangleTapCount: rangedIntegerOr(saved.pushTriangleTapCount, 0, 3, initial.pushTriangleTapCount),
    pushTriangleTaken: booleanOr(saved.pushTriangleTaken, initial.pushTriangleTaken),
    weatherWaterTaken: booleanOr(saved.weatherWaterTaken, initial.weatherWaterTaken),
    mentorLineReleased: booleanOr(saved.mentorLineReleased, initial.mentorLineReleased),
    rightArrowAssembled: booleanOr(saved.rightArrowAssembled, initial.rightArrowAssembled),
    balanceShifted: booleanOr(saved.balanceShifted, initial.balanceShifted),
    gamepadPurchased,
    manualControlTested: booleanOr(saved.manualControlTested, initial.manualControlTested),
    canLeaveDorm: booleanOr(saved.canLeaveDorm, initial.canLeaveDorm),
    requiredItemCollected: booleanOr(saved.requiredItemCollected, initial.requiredItemCollected),
    visitedAreaIds: isStringArrayInSet(saved.visitedAreaIds, VALID_ACT_ONE_AREA_IDS)
      ? [...new Set(saved.visitedAreaIds)] : [...initial.visitedAreaIds],
    gameMenuUnlocked: booleanOr(saved.gameMenuUnlocked, initial.gameMenuUnlocked),
    dormHubUnlocked: booleanOr(saved.dormHubUnlocked, initial.dormHubUnlocked)
  };
}

function normalizeUi(
  value: unknown,
  initial: GameState["ui"],
  legacy: boolean,
  actOne: ActOneBootstrapState
): GameState["ui"] {
  const saved = asRecord(value);
  const savedPhase = typeof saved.libraryFinalsPhase === "string" ? saved.libraryFinalsPhase : "idle";
  let phase = enumOr(savedPhase, VALID_LIBRARY_FINALS_PHASES, initial.libraryFinalsPhase);
  let puzzle = normalizeLibraryFinalsPuzzle(saved.libraryFinalsPuzzle, initial.libraryFinalsPuzzle);

  if (legacy && LEGACY_LIBRARY_PHASES.has(savedPhase)) {
    if (savedPhase === "seat_recovered") {
      phase = "friend_contacted";
      puzzle = completedLegacyPuzzle(initial.libraryFinalsPuzzle);
    } else {
      phase = actOne.canLeaveDorm ? "library_route_unlocked" : "idle";
      puzzle = { ...initial.libraryFinalsPuzzle };
    }
  }

  return {
    controlCenterOpen: booleanOr(saved.controlCenterOpen, initial.controlCenterOpen),
    autoRotate: booleanOr(saved.autoRotate, initial.autoRotate),
    musicPlaying: booleanOr(saved.musicPlaying, initial.musicPlaying),
    brightness: rangedNumberOr(saved.brightness, 0, 100, initial.brightness),
    inventoryOpen: booleanOr(saved.inventoryOpen, initial.inventoryOpen),
    selectedItem: nullableEnumOr(saved.selectedItem, VALID_ITEM_IDS, initial.selectedItem),
    zjudingPage: enumOr(saved.zjudingPage, VALID_ZJUDING_PAGES, initial.zjudingPage),
    librarySelectedSeat: nullableStringOr(saved.librarySelectedSeat, initial.librarySelectedSeat),
    librarySeatReserved: phase === "seat_recovered" || phase === "friend_contacted"
      ? true : booleanOr(saved.librarySeatReserved, initial.librarySeatReserved),
    libraryFinalsPhase: phase,
    libraryFinalsPuzzle: puzzle,
    seenChapterIntros: filteredStringArrayFromSet(saved.seenChapterIntros, VALID_CHAPTER_IDS, initial.seenChapterIntros)
  };
}

function normalizeConsumedItems(items: GameState["items"], ui: GameState["ui"]): void {
  const puzzle = ui.libraryFinalsPuzzle;
  if (puzzle.occupancyNoteCollected && !puzzle.investigationOpened) items.occupancyNote = true;
  if (puzzle.callNumberCollected && !puzzle.archivedRuleCollected) items.callNumber755 = true;
  if (puzzle.archivedRuleCollected && !puzzle.cc98UploadedEvidenceIds.includes("archived_leave_rule")) items.archivedLeaveRule = true;
  if (puzzle.itemReportGenerated && !puzzle.nonPersonProofStamped) items.itemRecognitionReport = true;
  if (puzzle.nonPersonProofStamped && !puzzle.recoverySubmittedEvidenceIds.includes("bag_non_person_proof")) items.bagNonPersonProof = true;
  if (puzzle.seatReceiptCollected && !puzzle.recoverySubmittedEvidenceIds.includes("seat_022_receipt")) items.seat022Receipt = true;
  if (puzzle.presenceProofCollected && !puzzle.recoverySubmittedEvidenceIds.includes("library_presence_proof")) items.libraryPresenceProof = true;
  if (puzzle.evictionPassGenerated && !puzzle.backpackEvicted) items.seatReleasePass = true;
  if (puzzle.investigationOpened) items.occupancyNote = false;
  if (puzzle.archivedRuleCollected) items.callNumber755 = false;
  if (puzzle.cc98UploadedEvidenceIds.includes("archived_leave_rule")) items.archivedLeaveRule = false;
  if (puzzle.nonPersonProofStamped) items.itemRecognitionReport = false;
  if (puzzle.recoverySubmittedEvidenceIds.includes("bag_non_person_proof")) items.bagNonPersonProof = false;
  if (puzzle.recoverySubmittedEvidenceIds.includes("seat_022_receipt")) items.seat022Receipt = false;
  if (puzzle.recoverySubmittedEvidenceIds.includes("library_presence_proof")) items.libraryPresenceProof = false;
  if (puzzle.backpackEvicted) items.seatReleasePass = false;
}

function normalizeLibraryFinalsPuzzle(value: unknown, initial: LibraryFinalsPuzzleState): LibraryFinalsPuzzleState {
  const saved = asRecord(value);
  return {
    libraryVisitedPoints: stringArrayFromSet(saved.libraryVisitedPoints, VALID_LIBRARY_LOCATION_IDS, initial.libraryVisitedPoints),
    entranceRecordRead: booleanOr(saved.entranceRecordRead, initial.entranceRecordRead),
    backpackInspected: booleanOr(saved.backpackInspected, initial.backpackInspected),
    occupancyNoteCollected: booleanOr(saved.occupancyNoteCollected, initial.occupancyNoteCollected),
    investigationOpened: booleanOr(saved.investigationOpened, initial.investigationOpened),
    optionalAc01Floors: rangedIntegerArray(saved.optionalAc01Floors, 1, 23, initial.optionalAc01Floors, 5),
    catalogSearchCompleted: booleanOr(saved.catalogSearchCompleted, initial.catalogSearchCompleted),
    catalogUnlocked: booleanOr(saved.catalogUnlocked, initial.catalogUnlocked),
    callNumberCollected: booleanOr(saved.callNumberCollected, initial.callNumberCollected),
    archivedRuleCollected: booleanOr(saved.archivedRuleCollected, initial.archivedRuleCollected),
    archivedRuleRead: booleanOr(saved.archivedRuleRead, initial.archivedRuleRead),
    photoCaptured: booleanOr(saved.photoCaptured, initial.photoCaptured),
    photoDimmed: booleanOr(saved.photoDimmed, initial.photoDimmed),
    itemReportGenerated: booleanOr(saved.itemReportGenerated, initial.itemReportGenerated),
    lostFoundStage: enumOr(saved.lostFoundStage, VALID_LOST_FOUND_STAGES,
      booleanOr(saved.nonPersonProofStamped, initial.nonPersonProofStamped)
        ? "stamped"
        : booleanOr(saved.itemReportGenerated, initial.itemReportGenerated)
          ? "ready"
          : initial.lostFoundStage),
    nonPersonProofStamped: booleanOr(saved.nonPersonProofStamped, initial.nonPersonProofStamped),
    seatReceiptCollected: booleanOr(saved.seatReceiptCollected, initial.seatReceiptCollected),
    auditAttemptCount: nonNegativeIntegerOr(saved.auditAttemptCount, initial.auditAttemptCount),
    auditArrivalMinutes: rangedIntegerOr(saved.auditArrivalMinutes, 0, 12, initial.auditArrivalMinutes),
    auditPublicNoticeFloor: rangedIntegerOr(saved.auditPublicNoticeFloor, 0, 63, initial.auditPublicNoticeFloor),
    auditProofCount: rangedIntegerOr(saved.auditProofCount, 0, 5, initial.auditProofCount),
    presenceProofCollected: booleanOr(saved.presenceProofCollected, initial.presenceProofCollected),
    cc98UploadedEvidenceIds: stringArrayFromSet(saved.cc98UploadedEvidenceIds, VALID_LIBRARY_EVIDENCE_IDS, initial.cc98UploadedEvidenceIds),
    preBdBriefingSeen: booleanOr(saved.preBdBriefingSeen, initial.preBdBriefingSeen),
    bdCount: bdCountOr(saved.bdCount, initial.bdCount),
    appliedBdReplyIds: stringArrayFromSet(saved.appliedBdReplyIds, VALID_BD_REPLY_IDS, initial.appliedBdReplyIds),
    recoverySubmittedEvidenceIds: stringArrayFromSet(saved.recoverySubmittedEvidenceIds, VALID_LIBRARY_RECOVERY_EVIDENCE_IDS, initial.recoverySubmittedEvidenceIds),
    evictionPassGenerated: booleanOr(saved.evictionPassGenerated, initial.evictionPassGenerated),
    backpackEvicted: booleanOr(saved.backpackEvicted, initial.backpackEvicted),
    playerSeated: booleanOr(saved.playerSeated, initial.playerSeated),
    nextQuestId: saved.nextQuestId === "chapter_three_book_hunt" ? saved.nextQuestId : initial.nextQuestId,
    clueIds: isStringArray(saved.clueIds) ? [...new Set(saved.clueIds)] : [...initial.clueIds]
  };
}

function completedLegacyPuzzle(initial: LibraryFinalsPuzzleState): LibraryFinalsPuzzleState {
  return {
    ...initial,
    libraryVisitedPoints: ["entrance", "seat_022", "front_desk", "lost_found", "catalog_terminal", "shelf_755"],
    entranceRecordRead: true,
    backpackInspected: true,
    occupancyNoteCollected: true,
    investigationOpened: true,
    catalogSearchCompleted: true,
    catalogUnlocked: true,
    callNumberCollected: true,
    archivedRuleCollected: true,
    archivedRuleRead: true,
    photoCaptured: true,
    photoDimmed: true,
    itemReportGenerated: true,
    lostFoundStage: "stamped",
    nonPersonProofStamped: true,
    seatReceiptCollected: true,
    auditArrivalMinutes: 7,
    auditPublicNoticeFloor: 47,
    auditProofCount: 3,
    presenceProofCollected: true,
    cc98UploadedEvidenceIds: ["archived_leave_rule", "bag_non_person_proof", "seat_022_receipt", "library_presence_proof"],
    preBdBriefingSeen: true,
    bdCount: 3,
    appliedBdReplyIds: ["reply-seat-ticket", "reply-visit-proof", "reply-bag-nonperson"],
    recoverySubmittedEvidenceIds: ["bag_non_person_proof", "seat_022_receipt", "library_presence_proof"],
    evictionPassGenerated: true,
    backpackEvicted: true,
    playerSeated: true,
    nextQuestId: "chapter_three_book_hunt",
    clueIds: ["borrowed_attendance_record"]
  };
}

function normalizeItems(value: unknown, initial: GameState["items"]): GameState["items"] {
  const saved = asRecord(value);
  return Object.fromEntries(
    Object.keys(initial).map((key) => [key, booleanOr(saved[key], initial[key as keyof GameState["items"]])])
  ) as GameState["items"];
}

function normalizeDigits(value: unknown, initial: GameState["digits"]): GameState["digits"] {
  const saved = asRecord(value);
  return { d1: digitOr(saved.d1, initial.d1), d2: digitOr(saved.d2, initial.d2), d3: digitOr(saved.d3, initial.d3), d4: digitOr(saved.d4, initial.d4) };
}

function normalizeFlags(value: unknown, initial: GameState["flags"]): GameState["flags"] {
  const saved = asRecord(value);
  return {
    codeScattered: booleanOr(saved.codeScattered, initial.codeScattered),
    cardZeroTaken: booleanOr(saved.cardZeroTaken, initial.cardZeroTaken),
    tiyiCrashCount: nonNegativeIntegerOr(saved.tiyiCrashCount, initial.tiyiCrashCount),
    tiyiCountTaken: booleanOr(saved.tiyiCountTaken, initial.tiyiCountTaken),
    gearFallen: booleanOr(saved.gearFallen, initial.gearFallen),
    gearNineTaken: booleanOr(saved.gearNineTaken, initial.gearNineTaken),
    headphoneFallen: booleanOr(saved.headphoneFallen, initial.headphoneFallen),
    waterDropTaken: booleanOr(saved.waterDropTaken, initial.waterDropTaken),
    slashHalfDropped: booleanOr(saved.slashHalfDropped, initial.slashHalfDropped),
    slashTapCount: nonNegativeIntegerOr(saved.slashTapCount, initial.slashTapCount),
    slashTaken: booleanOr(saved.slashTaken, initial.slashTaken),
    bonsaiHintShown: booleanOr(saved.bonsaiHintShown, initial.bonsaiHintShown),
    towerOpened: booleanOr(saved.towerOpened, initial.towerOpened),
    plantWatered: booleanOr(saved.plantWatered, initial.plantWatered),
    plantLit: booleanOr(saved.plantLit, initial.plantLit),
    plantFertilized: booleanOr(saved.plantFertilized, initial.plantFertilized),
    flowerBloomed: booleanOr(saved.flowerBloomed, initial.flowerBloomed),
    flowerEightTaken: booleanOr(saved.flowerEightTaken, initial.flowerEightTaken),
    checkinDone: booleanOr(saved.checkinDone, initial.checkinDone)
  };
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}
function asRecord(value: unknown): Record<string, unknown> { return isRecord(value) ? value : {}; }
function enumOr<T extends string>(value: unknown, valid: ReadonlySet<T>, fallback: T): T {
  return typeof value === "string" && valid.has(value as T) ? value as T : fallback;
}
function nullableEnumOr<T extends string>(value: unknown, valid: ReadonlySet<T>, fallback: T | null): T | null {
  if (value === null) return null;
  return typeof value === "string" && valid.has(value as T) ? value as T : fallback;
}
function digitOr(value: unknown, fallback: GameState["digits"]["d1"]): GameState["digits"]["d1"] {
  if (value === null) return null;
  return typeof value === "string" && VALID_DIGIT_VALUES.has(value as NonNullable<typeof fallback>) ? value as NonNullable<typeof fallback> : fallback;
}
function nullableStringOr(value: unknown, fallback: string | null): string | null { return value === null || typeof value === "string" ? value : fallback; }
function booleanOr(value: unknown, fallback: boolean): boolean { return typeof value === "boolean" ? value : fallback; }
function rangedNumberOr(value: unknown, min: number, max: number, fallback: number): number {
  return typeof value === "number" && Number.isFinite(value) && value >= min && value <= max ? value : fallback;
}
function rangedIntegerOr(value: unknown, min: number, max: number, fallback: number): number {
  return typeof value === "number" && Number.isInteger(value) && value >= min && value <= max ? value : fallback;
}
function nonNegativeIntegerOr(value: unknown, fallback: number): number { return typeof value === "number" && Number.isInteger(value) && value >= 0 ? value : fallback; }
function nonNegativeSafeIntegerOr(value: unknown, fallback: number): number { return typeof value === "number" && Number.isSafeInteger(value) && value >= 0 ? value : fallback; }
function bdCountOr(value: unknown, fallback: LibraryFinalsPuzzleState["bdCount"]): LibraryFinalsPuzzleState["bdCount"] {
  return value === 0 || value === 1 || value === 2 || value === 3 ? value : fallback;
}
function isStringArray(value: unknown): value is string[] { return Array.isArray(value) && value.every((item) => typeof item === "string"); }
function isStringArrayInSet<T extends string>(value: unknown, valid: ReadonlySet<T>): value is T[] {
  return Array.isArray(value) && value.every((item) => typeof item === "string" && valid.has(item as T));
}
function stringArrayFromSet<T extends string>(value: unknown, valid: ReadonlySet<T>, fallback: readonly T[]): T[] {
  return isStringArrayInSet(value, valid) ? [...new Set(value)] : [...fallback];
}
function filteredStringArrayFromSet<T extends string>(value: unknown, valid: ReadonlySet<T>, fallback: readonly T[]): T[] {
  if (!Array.isArray(value)) return [...fallback];
  return [...new Set(value.filter((item): item is T => typeof item === "string" && valid.has(item as T)))];
}
function rangedIntegerArray(value: unknown, min: number, max: number, fallback: readonly number[], maxLength: number): number[] {
  if (!Array.isArray(value) || value.length > maxLength || !value.every((item) => Number.isInteger(item) && item >= min && item <= max)) return [...fallback];
  return [...new Set(value as number[])];
}
