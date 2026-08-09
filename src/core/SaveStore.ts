import type {
  ActOneBootstrapPhase,
  ActOneBootstrapState,
  BikeArcadeChapterState,
  CanteenDrinkIngredientId,
  CanteenMenuOptionId,
  GameState,
  LibraryEvidenceId,
  LibraryFinalsBdPostId,
  LibraryFinalsBdReplyId,
  LibraryFinalsPhase,
  LibraryFinalsPuzzleState,
  LibraryLocationId,
  LostFoundStage,
  LibraryRecoveryEvidenceId,
  QizhenDecoyTargetId,
  QizhenFishingSpotId,
  QizhenLakePhase,
  QizhenMapClueId,
  WalletState
} from "./types";
import { BIKE_SAVE_KEY, GAME_SAVE_BACKUP_KEY, GAME_SAVE_KEY } from "./StorageKeys";
import { canEnterScene, sanitizeZjudingPage } from "./FeatureAccess";

const SAVE_VERSION = 16;
const WALLET_SAVE_VERSION = 12;
const SUPPORTED_ENVELOPE_VERSIONS = new Set([2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, SAVE_VERSION]);

const VALID_RUNTIME_MODES = new Set<GameState["runtimeMode"]>(["phone", "rpg"]);
const VALID_RPG_SCENES = new Set<GameState["rpgScene"]>([
  "campus_bootstrap", "campus_qizhen_loop", "dorm_hub", "library_interior", "canteen_interior", "theater_interior", "qizhen_lake"
]);
const VALID_RPG_CHECKPOINTS = new Set<GameState["rpgCheckpoint"]>([
  "campus_spawn",
  "campus_library_gate",
  "campus_canteen_gate",
  "campus_theater_junction",
  "campus_qizhen_transition_stop",
  "campus_qizhen_gate",
  "dorm_spawn",
  "canteen_entrance",
  "theater_lobby",
  "theater_auditorium",
  "theater_stage",
  "qizhen_reflection",
  "qizhen_signs",
  "qizhen_decoy",
  "qizhen_mist",
  "qizhen_dock",
  "qizhen_open_water",
  "qizhen_channel",
  "qizhen_swan_cove",
  "qizhen_chase",
  "qizhen_complete",
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
const VALID_CANTEEN_HUNT_PHASES = new Set<GameState["canteenHunt"]["phase"]>([
  "tracking", "canteen_reached", "entered", "tray_search", "drink_mix", "menu_order", "pickup_search",
  "exit_blocking", "chase_ready", "chasing", "theater_reached"
]);
const VALID_CANTEEN_MODES = new Set<GameState["canteenHunt"]["mode"]>(["light", "dark"]);
const VALID_CANTEEN_TRAY_IDS = new Set([
  "tray_blue_01", "tray_blue_02", "tray_blue_03",
  "tray_plain_01", "tray_plain_02", "tray_plain_03",
  "tray_plain_04", "tray_plain_05", "tray_plain_06",
  "tray_plain_07", "tray_plain_08", "tray_plain_09"
]);
const VALID_CANTEEN_EXIT_IDS = new Set(["west", "southeast", "steam"]);
const VALID_CANTEEN_DRINK_IDS = new Set<CanteenDrinkIngredientId>([
  "sparklingWater", "lemonTea", "blackCoffee"
]);
const VALID_CANTEEN_MENU_OPTIONS = new Set<CanteenMenuOptionId>(["A", "B", "C", "D", "E"]);
const VALID_THEATER_HUNT_PHASES = new Set<GameState["theaterHunt"]["phase"]>([
  "entry_ticket", "program_search", "prop_setup", "spotlight_ready", "spotlight_hunt", "reversal", "complete"
]);
const VALID_THEATER_MODES = new Set<GameState["theaterHunt"]["mode"]>(["light", "dark"]);
const VALID_THEATER_PROGRAM_IDS = new Set<GameState["theaterHunt"]["collectedProgramIds"][number]>([
  "opening", "spotlight", "finale"
]);
const VALID_QIZHEN_PHASES = new Set<QizhenLakePhase>([
  "inactive", "location_search", "lake_unlocked", "dock_outfitting", "boarding_tutorial",
  "lake_exploration", "tool_chain", "swan_exchange", "paper_capture", "swan_chase", "complete"
]);
const LEGACY_QIZHEN_INTERIOR_PHASES = new Set([
  "reflection_hunt", "sign_alignment", "decoy_setup", "mist_timing", "chase_ready"
]);
const VALID_QIZHEN_MODES = new Set<GameState["qizhenLake"]["mode"]>(["light", "dark"]);
const VALID_QIZHEN_ZONES = new Set<GameState["qizhenLake"]["zone"]>(["dock", "open_water", "channel", "swan_cove"]);
const VALID_QIZHEN_VEHICLES = new Set<GameState["qizhenLake"]["vehicle"]>(["on_foot", "kayak"]);
const VALID_QIZHEN_SAFE_SPAWNS = new Set<GameState["qizhenLake"]["safeSpawnId"]>([
  "dock_entry", "dock_kayak", "open_water_entry", "channel_entry", "swan_cove_entry", "channel_chase"
]);
const VALID_QIZHEN_PADDLE_SIDES = new Set<NonNullable<GameState["qizhenLake"]["boardingLastSide"]>>(["left", "right"]);
const VALID_QIZHEN_FISHING_SPOTS = new Set<QizhenFishingSpotId>(["locker_key", "net_frame", "paper", "fish"]);
const VALID_QIZHEN_MAP_CLUES = new Set<QizhenMapClueId>(["bridge", "reflection", "lake"]);
const VALID_QIZHEN_DECOY_TARGETS = new Set<QizhenDecoyTargetId>(["notice", "bridge", "lamp"]);
const VALID_DIGIT_VALUES = new Set<NonNullable<GameState["digits"]["d1"]>>(["0", "7", "9", "8"]);
const VALID_ITEM_IDS = new Set<NonNullable<GameState["ui"]["selectedItem"]>>([
  "waterDrop", "headphone", "wateredHeadphone", "reverseGear", "slashLine", "towerKey",
  "fertilizer", "campusCard", "pushTriangle", "weatherWater", "mentorLine", "rightArrow",
  "gamepad", "occupancyNote", "callNumber755", "archivedLeaveRule", "itemRecognitionReport",
  "bagNonPersonProof", "seat022Receipt", "libraryPresenceProof", "seatReleasePass",
  "cafeteriaWages", "greaseTissue", "pickupTicket0755", "canteenRealBun",
  "canteenCluelessSoyMilk", "canteenEdgeEgg", "canteenUselessCongee", "theaterTicketHalfA",
  "sparklingWater", "lemonTea", "blackCoffee", "badDrink", "dailySpecialSparklingWater",
  "theaterTicketHalfB", "temporaryTheaterTicket", "theaterProgramOpening",
  "theaterProgramSpotlight", "theaterProgramFinale", "spotlightRemote",
  "fluorescentBrush", "decoyPaper", "wetProgram", "bridgeKeyword", "reflectionKeyword",
  "lakeKeyword", "reflectionCoordinate", "fishingRod", "rustedLockerKey", "nylonCord",
  "brokenNetFrame", "improvisedDipNet", "sealedFeedTin", "fishFeedPellets", "smallCarp",
  "swanMagnet", "magneticFishingRod"
]);
const VALID_ZJUDING_PAGES = new Set<GameState["ui"]["zjudingPage"]>([
  "hub", "login", "directory", "learn", "campus_map", "library", "library_spaces", "library_seat",
  "library_catalog", "library_recovery"
]);
const VALID_LIBRARY_FINALS_PHASES = new Set<LibraryFinalsPhase>([
  "idle", "library_route_unlocked", "library_entered", "occupied_seat_found", "evidence_gathering",
  "bd_briefing", "top_ten_rising", "top_ten_reached", "recovery_application", "pass_ready", "backpack_removed",
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
const VALID_BD_POST_IDS = new Set<LibraryFinalsBdPostId>([
  "bd-notice-tens", "bd-rule-count", "bd-rank-first", "bd-identity-zero",
  "bd-call-number-tail", "bd-seat-tail", "bd-reply-count", "bd-arrival-minutes"
]);
const COMPLETED_BD_POST_IDS: LibraryFinalsBdPostId[] = [
  "bd-rule-count", "bd-identity-zero", "bd-seat-tail", "bd-arrival-minutes"
];
const VALID_LOST_FOUND_STAGES = new Set<LostFoundStage>(["missing_report", "ready", "scanning", "stamped"]);
const VALID_CHAPTER_IDS = new Set<GameState["ui"]["seenChapterIntros"][number]>([
  "chapter_one", "chapter_two", "chapter_three"
]);

interface SaveEnvelope {
  version: typeof SAVE_VERSION;
  state: GameState;
  savedAt: number;
}

export class SaveStore {
  constructor(private readonly storage: Storage = window.localStorage) {}

  save(state: GameState): boolean {
    try {
      const existing = this.storage.getItem(GAME_SAVE_KEY);
      if (existing && isPotentiallyLoadableSave(existing)) {
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
      const hasEnvelopeShape = Object.prototype.hasOwnProperty.call(parsed, "version")
        || Object.prototype.hasOwnProperty.call(parsed, "state");
      if (hasEnvelopeShape && !isVersionedEnvelope) return null;
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
      const savedCanteenHunt = isRecord(saved.canteenHunt) ? saved.canteenHunt : {};
      const savedCanteenPhase = enumOr(savedCanteenHunt.phase, VALID_CANTEEN_HUNT_PHASES, initial.canteenHunt.phase);
      const legacyChaseCompleted = savedCanteenPhase === "theater_reached";
      const chaseCompleted = booleanOr(savedCanteenHunt.chaseCompleted, legacyChaseCompleted);
      const savedBlockHits = rangedIntegerOr(savedCanteenHunt.blockHits, 0, 3, initial.canteenHunt.blockHits);
      const drinkPreviouslyCompleted = ["menu_order", "pickup_search", "exit_blocking", "chase_ready", "chasing", "theater_reached"].includes(savedCanteenPhase);
      const menuPreviouslyCompleted = ["pickup_search", "exit_blocking", "chase_ready", "chasing", "theater_reached"].includes(savedCanteenPhase);
      const pickupPreviouslyCompleted = ["exit_blocking", "chase_ready", "chasing", "theater_reached"].includes(savedCanteenPhase);
      let canteenHunt: GameState["canteenHunt"] = {
        active: typeof savedCanteenHunt.active === "boolean" ? savedCanteenHunt.active : initial.canteenHunt.active,
        phase: savedCanteenPhase === "entered" ? "tray_search" : savedCanteenPhase,
        mode: enumOr(savedCanteenHunt.mode, VALID_CANTEEN_MODES, initial.canteenHunt.mode),
        entryPaperEscaped: booleanOr(
          savedCanteenHunt.entryPaperEscaped,
          savedCanteenPhase !== "tray_search"
          || booleanOr(savedCanteenHunt.trayTaskStarted, false)
          || (Array.isArray(savedCanteenHunt.returnedTrayIds) && savedCanteenHunt.returnedTrayIds.length > 0)
        ),
        trayTaskStarted: booleanOr(
          savedCanteenHunt.trayTaskStarted,
          savedCanteenPhase !== "tray_search"
          || (Array.isArray(savedCanteenHunt.identifiedTrayIds) && savedCanteenHunt.identifiedTrayIds.length > 0)
          || (Array.isArray(savedCanteenHunt.returnedTrayIds) && savedCanteenHunt.returnedTrayIds.length > 0)
        ),
        carriedTrayIds: filteredStringArrayFromSet(
          savedCanteenHunt.carriedTrayIds,
          VALID_CANTEEN_TRAY_IDS,
          initial.canteenHunt.carriedTrayIds
        ).slice(0, 1),
        identifiedTrayIds: filteredStringArrayFromSet(
          savedCanteenHunt.identifiedTrayIds,
          VALID_CANTEEN_TRAY_IDS,
          initial.canteenHunt.identifiedTrayIds
        ),
        returnedTrayIds: filteredStringArrayFromSet(
          savedCanteenHunt.returnedTrayIds,
          VALID_CANTEEN_TRAY_IDS,
          initial.canteenHunt.returnedTrayIds
        ),
        drinkShelfRead: booleanOr(savedCanteenHunt.drinkShelfRead, drinkPreviouslyCompleted),
        drinkMixSequence: filteredStringArrayFromSet(
          savedCanteenHunt.drinkMixSequence,
          VALID_CANTEEN_DRINK_IDS,
          initial.canteenHunt.drinkMixSequence
        ).slice(0, 3) as CanteenDrinkIngredientId[],
        drinkMixAttemptCount: nonNegativeIntegerOr(
          savedCanteenHunt.drinkMixAttemptCount,
          drinkPreviouslyCompleted ? 1 : initial.canteenHunt.drinkMixAttemptCount
        ),
        queueChallengeSeen: booleanOr(savedCanteenHunt.queueChallengeSeen, drinkPreviouslyCompleted),
        promoDrinkPlaced: booleanOr(savedCanteenHunt.promoDrinkPlaced, drinkPreviouslyCompleted),
        queueGapOpened: booleanOr(savedCanteenHunt.queueGapOpened, drinkPreviouslyCompleted),
        menuDarkClueRead: booleanOr(savedCanteenHunt.menuDarkClueRead, menuPreviouslyCompleted),
        pickupTimeErrorSeen: booleanOr(savedCanteenHunt.pickupTimeErrorSeen, pickupPreviouslyCompleted),
        pickupDarkClueRead: booleanOr(savedCanteenHunt.pickupDarkClueRead, pickupPreviouslyCompleted),
        defenseDrinkUsed: booleanOr(
          savedCanteenHunt.defenseDrinkUsed,
          ["chase_ready", "chasing", "theater_reached"].includes(savedCanteenPhase)
        ),
        orderedMenuOption: typeof savedCanteenHunt.orderedMenuOption === "string"
          && VALID_CANTEEN_MENU_OPTIONS.has(savedCanteenHunt.orderedMenuOption as CanteenMenuOptionId)
            ? savedCanteenHunt.orderedMenuOption as CanteenMenuOptionId
            : savedCanteenPhase === "pickup_search" && booleanOr((saved.items as Record<string, unknown> | undefined)?.pickupTicket0755, false)
              ? "D"
              : initial.canteenHunt.orderedMenuOption,
        identifiedExitIds: filteredStringArrayFromSet(
          savedCanteenHunt.identifiedExitIds,
          VALID_CANTEEN_EXIT_IDS,
          ["southeast", "steam", "west"].slice(0, savedBlockHits)
        ) as GameState["canteenHunt"]["identifiedExitIds"],
        orderAttemptCount: nonNegativeIntegerOr(savedCanteenHunt.orderAttemptCount, initial.canteenHunt.orderAttemptCount),
        pickupAttemptCount: nonNegativeIntegerOr(savedCanteenHunt.pickupAttemptCount, initial.canteenHunt.pickupAttemptCount),
        blockHits: savedBlockHits,
        bikeCodeRead: booleanOr(savedCanteenHunt.bikeCodeRead, initial.canteenHunt.bikeCodeRead),
        bikeLockCleaned: booleanOr(savedCanteenHunt.bikeLockCleaned, initial.canteenHunt.bikeLockCleaned),
        bikePaid: booleanOr(savedCanteenHunt.bikePaid, initial.canteenHunt.bikePaid),
        chaseCompleted,
        chaseAttemptCount: nonNegativeIntegerOr(savedCanteenHunt.chaseAttemptCount, legacyChaseCompleted ? 1 : initial.canteenHunt.chaseAttemptCount),
        chaseBestDistance: Math.max(
          chaseCompleted ? 755 : 0,
          nonNegativeIntegerOr(savedCanteenHunt.chaseBestDistance, initial.canteenHunt.chaseBestDistance)
        ),
        chaseBestLives: rangedIntegerOr(
          savedCanteenHunt.chaseBestLives,
          0,
          3,
          legacyChaseCompleted ? 3 : initial.canteenHunt.chaseBestLives
        ),
        chaseCollisions: nonNegativeIntegerOr(savedCanteenHunt.chaseCollisions, initial.canteenHunt.chaseCollisions)
      };
      const savedTheaterHunt = isRecord(saved.theaterHunt) ? saved.theaterHunt : {};
      const theaterHunt: GameState["theaterHunt"] = {
        active: booleanOr(savedTheaterHunt.active, initial.theaterHunt.active),
        phase: enumOr(savedTheaterHunt.phase, VALID_THEATER_HUNT_PHASES, initial.theaterHunt.phase),
        mode: enumOr(savedTheaterHunt.mode, VALID_THEATER_MODES, initial.theaterHunt.mode),
        posterCleaned: booleanOr(savedTheaterHunt.posterCleaned, initial.theaterHunt.posterCleaned),
        ticketCodeRead: booleanOr(savedTheaterHunt.ticketCodeRead, initial.theaterHunt.ticketCodeRead),
        ticketCodeAttempts: nonNegativeIntegerOr(savedTheaterHunt.ticketCodeAttempts, initial.theaterHunt.ticketCodeAttempts),
        admitted: booleanOr(savedTheaterHunt.admitted, initial.theaterHunt.admitted),
        collectedProgramIds: filteredStringArrayFromSet(
          savedTheaterHunt.collectedProgramIds,
          VALID_THEATER_PROGRAM_IDS,
          initial.theaterHunt.collectedProgramIds
        ),
        programOrder: filteredStringArrayFromSet(
          savedTheaterHunt.programOrder,
          VALID_THEATER_PROGRAM_IDS,
          initial.theaterHunt.programOrder
        ).slice(0, 3),
        programWrongAttempts: nonNegativeIntegerOr(savedTheaterHunt.programWrongAttempts, initial.theaterHunt.programWrongAttempts),
        propGhostRead: booleanOr(savedTheaterHunt.propGhostRead, initial.theaterHunt.propGhostRead),
        managerHintRead: booleanOr(savedTheaterHunt.managerHintRead, initial.theaterHunt.managerHintRead),
        propBoxOpened: booleanOr(savedTheaterHunt.propBoxOpened, initial.theaterHunt.propBoxOpened),
        paperDusted: booleanOr(savedTheaterHunt.paperDusted, initial.theaterHunt.paperDusted),
        spotlightRound: rangedIntegerOr(savedTheaterHunt.spotlightRound, 0, 3, initial.theaterHunt.spotlightRound),
        spotlightMistakes: nonNegativeIntegerOr(savedTheaterHunt.spotlightMistakes, initial.theaterHunt.spotlightMistakes),
        decoyRevealed: booleanOr(savedTheaterHunt.decoyRevealed, initial.theaterHunt.decoyRevealed)
      };
      const qizhenNormalization = normalizeQizhenLake(
        saved.qizhenLake,
        initial.qizhenLake,
        envelopeVersion < SAVE_VERSION
      );
      const qizhenLake = qizhenNormalization.state;
      if ((theaterHunt.phase === "complete" || items.wetProgram) && qizhenLake.phase === "inactive") {
        qizhenLake.active = true;
        qizhenLake.phase = "location_search";
      }
      const requiresCanteenMigration = isLegacyChapterThreeState(saved, ui);
      const chapterThreeAlreadyProgressed = hasChapterThreeProgress(canteenHunt, theaterHunt, qizhenLake);
      if (requiresCanteenMigration) {
        ui.libraryFinalsPhase = "friend_contacted";
        ui.libraryFinalsPuzzle = {
          ...ui.libraryFinalsPuzzle,
          nextQuestId: "chapter_three_canteen_hunt"
        };
        if (!chapterThreeAlreadyProgressed) {
          canteenHunt = createCanteenTrackingState(initial.canteenHunt);
        }
      }

      normalizeConsumedItems(items, ui, flags, theaterHunt, qizhenLake);
      normalizeQizhenItems(items, qizhenLake, qizhenNormalization);
      const wallet = normalizeWallet(
        saved.wallet,
        initial.wallet,
        actOne,
        items,
        canteenHunt,
        envelopeVersion >= WALLET_SAVE_VERSION
      );
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
        wallet,
        bikeArcade,
        canteenHunt,
        theaterHunt,
        qizhenLake,
        ui
      };
      if (
        hydrated.rpgScene === "campus_bootstrap"
        && ["campus_qizhen_transition_stop", "campus_qizhen_gate"].includes(hydrated.rpgCheckpoint)
      ) {
        hydrated.rpgScene = "campus_qizhen_loop";
      }
      if (qizhenNormalization.migratedLegacyInterior && saved.rpgScene === "qizhen_lake") {
        hydrated.rpgScene = "qizhen_lake";
        hydrated.rpgCheckpoint = qizhenNormalization.migratedLegacyChase
          ? "qizhen_chase"
          : "qizhen_dock";
      }
      if (requiresCanteenMigration && !chapterThreeAlreadyProgressed) {
        hydrated.runtimeMode = "rpg";
        hydrated.rpgScene = "campus_bootstrap";
        hydrated.rpgCheckpoint = "campus_spawn";
        hydrated.currentScene = "phone_home";
      }
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

interface QizhenNormalizationResult {
  state: GameState["qizhenLake"];
  migratedLegacyInterior: boolean;
  migratedLegacyChase: boolean;
}

function normalizeQizhenLake(
  value: unknown,
  initial: GameState["qizhenLake"],
  migrateLegacyPaperRelease: boolean
): QizhenNormalizationResult {
  const saved = asRecord(value);
  const signRotations = Array.isArray(saved.signRotations)
    && saved.signRotations.length === 3
    && saved.signRotations.every((entry) => Number.isInteger(entry) && entry >= 0 && entry <= 3)
    ? saved.signRotations as [number, number, number]
    : [...initial.signRotations] as [number, number, number];
  const savedPhase = typeof saved.phase === "string" ? saved.phase : initial.phase;
  const migratedLegacyChase = savedPhase === "chase_ready"
    || (migrateLegacyPaperRelease && booleanOr(saved.paperReleased, false));
  const migratedLegacyInterior = migratedLegacyChase || LEGACY_QIZHEN_INTERIOR_PHASES.has(savedPhase);
  const phase: QizhenLakePhase = migratedLegacyChase
    ? "swan_chase"
    : migratedLegacyInterior
      ? "dock_outfitting"
      : enumOr(saved.phase, VALID_QIZHEN_PHASES, initial.phase);
  const decoyPlacedAt = nullableEnumOr(saved.decoyPlacedAt, VALID_QIZHEN_DECOY_TARGETS, initial.decoyPlacedAt);
  const reachedBoarding = [
    "boarding_tutorial", "lake_exploration", "tool_chain", "swan_exchange",
    "paper_capture", "swan_chase", "complete"
  ].includes(phase);
  const reachedExploration = [
    "lake_exploration", "tool_chain", "swan_exchange", "paper_capture", "swan_chase", "complete"
  ].includes(phase);
  const reachedToolChain = ["tool_chain", "swan_exchange", "paper_capture", "swan_chase", "complete"].includes(phase);
  const reachedSwanExchange = ["swan_exchange", "paper_capture", "swan_chase", "complete"].includes(phase);
  const reachedPaperCapture = ["paper_capture", "swan_chase", "complete"].includes(phase);
  const reachedChase = ["swan_chase", "complete"].includes(phase);
  const completed = phase === "complete";

  const magneticRodCombined = reachedChase
    || migratedLegacyChase
    || booleanOr(saved.magneticRodCombined, initial.magneticRodCombined);
  const swanFed = reachedPaperCapture
    || magneticRodCombined
    || migratedLegacyChase
    || booleanOr(saved.swanFed, initial.swanFed);
  const fishCaught = reachedSwanExchange
    || swanFed
    || migratedLegacyChase
    || booleanOr(saved.fishCaught, initial.fishCaught);
  const feedTinOpened = fishCaught
    || migratedLegacyChase
    || booleanOr(saved.feedTinOpened, initial.feedTinOpened);
  const feedTinRetrieved = feedTinOpened
    || migratedLegacyChase
    || booleanOr(saved.feedTinRetrieved, initial.feedTinRetrieved);
  const netCombined = feedTinRetrieved
    || migratedLegacyChase
    || booleanOr(saved.netCombined, initial.netCombined);
  const lockerOpened = netCombined
    || migratedLegacyChase
    || booleanOr(saved.lockerOpened, initial.lockerOpened);
  const paperCaptured = reachedChase
    || migratedLegacyChase
    || booleanOr(saved.paperCaptured, initial.paperCaptured);
  const swanReleased = paperCaptured
    || migratedLegacyChase
    || booleanOr(saved.swanReleased, initial.swanReleased);
  const observedFishingSpotIds = new Set(filteredStringArrayFromSet(
    saved.observedFishingSpotIds,
    VALID_QIZHEN_FISHING_SPOTS,
    initial.observedFishingSpotIds
  ));
  if (lockerOpened) observedFishingSpotIds.add("locker_key");
  if (netCombined) observedFishingSpotIds.add("net_frame");
  if (fishCaught) observedFishingSpotIds.add("fish");
  if (paperCaptured) observedFishingSpotIds.add("paper");

  let zone = enumOr(saved.zone, VALID_QIZHEN_ZONES, initial.zone);
  let vehicle = enumOr(saved.vehicle, VALID_QIZHEN_VEHICLES, initial.vehicle);
  let safeSpawnId = enumOr(saved.safeSpawnId, VALID_QIZHEN_SAFE_SPAWNS, initial.safeSpawnId);
  if (migratedLegacyChase || phase === "swan_chase") {
    zone = "channel";
    vehicle = "kayak";
    safeSpawnId = "channel_chase";
  } else if (migratedLegacyInterior) {
    zone = "dock";
    vehicle = "on_foot";
    safeSpawnId = "dock_entry";
  } else if (phase === "complete") {
    zone = "dock";
    vehicle = "on_foot";
    safeSpawnId = "dock_entry";
  } else {
    if (zone !== "dock" && vehicle === "on_foot") vehicle = "kayak";
    if (!safeSpawnMatchesZone(safeSpawnId, zone)) {
      safeSpawnId = defaultSafeSpawnFor(zone, vehicle);
    }
  }

  const chaseDistance = completed
    ? 1000
    : rangedIntegerOr(saved.chaseDistance, 0, 1000, initial.chaseDistance);
  const chaseBestDistance = Math.max(
    chaseDistance,
    rangedIntegerOr(saved.chaseBestDistance, 0, 1000, initial.chaseBestDistance)
  );
  const state: GameState["qizhenLake"] = {
    active: phase !== "inactive" || booleanOr(saved.active, initial.active),
    phase,
    mode: enumOr(saved.mode, VALID_QIZHEN_MODES, initial.mode),
    zone,
    vehicle,
    safeSpawnId,
    locationBriefingSeen: booleanOr(saved.locationBriefingSeen, initial.locationBriefingSeen),
    bridgeClueFound: booleanOr(saved.bridgeClueFound, initial.bridgeClueFound),
    reflectionClueFound: booleanOr(saved.reflectionClueFound, initial.reflectionClueFound),
    lakeClueFound: booleanOr(saved.lakeClueFound, initial.lakeClueFound),
    mapClueIds: filteredStringArrayFromSet(saved.mapClueIds, VALID_QIZHEN_MAP_CLUES, initial.mapClueIds),
    introSeen: booleanOr(saved.introSeen, initial.introSeen),
    kayakEquipped: reachedBoarding || migratedLegacyChase || booleanOr(saved.kayakEquipped, initial.kayakEquipped),
    leftPaddleEquipped: reachedBoarding || migratedLegacyChase || booleanOr(saved.leftPaddleEquipped, initial.leftPaddleEquipped),
    rightPaddleEquipped: reachedBoarding || migratedLegacyChase || booleanOr(saved.rightPaddleEquipped, initial.rightPaddleEquipped),
    boardingStrokeCount: Math.max(
      migratedLegacyChase ? 4 : 0,
      nonNegativeIntegerOr(saved.boardingStrokeCount, initial.boardingStrokeCount)
    ),
    boardingLastSide: nullableEnumOr(saved.boardingLastSide, VALID_QIZHEN_PADDLE_SIDES, initial.boardingLastSide),
    boardingTutorialCompleted: reachedExploration
      || migratedLegacyChase
      || booleanOr(saved.boardingTutorialCompleted, initial.boardingTutorialCompleted),
    capsizeCount: nonNegativeIntegerOr(saved.capsizeCount, initial.capsizeCount),
    rodFound: reachedToolChain
      || magneticRodCombined
      || migratedLegacyChase
      || booleanOr(saved.rodFound, initial.rodFound),
    decoyBaitAttached: reachedSwanExchange
      || migratedLegacyChase
      || booleanOr(saved.decoyBaitAttached, initial.decoyBaitAttached),
    reflectionLocationObserved: reachedToolChain
      || migratedLegacyChase
      || booleanOr(saved.reflectionLocationObserved, initial.reflectionLocationObserved),
    observedFishingSpotIds: [...observedFishingSpotIds],
    directPaperCastFailures: nonNegativeIntegerOr(saved.directPaperCastFailures, initial.directPaperCastFailures),
    lockerOpened,
    netCombined,
    feedTinRetrieved,
    feedTinOpened,
    fishCaught,
    swanFed,
    magneticRodCombined,
    paperCaptured,
    swanReleased,
    chaseDistance,
    chaseBestDistance,
    chaseAttempts: Math.max(
      reachedChase ? 1 : 0,
      nonNegativeIntegerOr(saved.chaseAttempts, initial.chaseAttempts)
    ),
    magneticAttachmentBroken: completed || booleanOr(saved.magneticAttachmentBroken, initial.magneticAttachmentBroken),
    transitionReady: completed || booleanOr(saved.transitionReady, initial.transitionReady),
    reflectionRound: rangedIntegerOr(saved.reflectionRound, 0, 3, initial.reflectionRound),
    reflectionMistakes: nonNegativeIntegerOr(saved.reflectionMistakes, initial.reflectionMistakes),
    signRotations,
    signsSolved: booleanOr(saved.signsSolved, initial.signsSolved),
    decoyPlacedAt,
    decoyAttempts: nonNegativeIntegerOr(saved.decoyAttempts, initial.decoyAttempts),
    mistRhythmRead: booleanOr(saved.mistRhythmRead, initial.mistRhythmRead),
    mistAttempts: nonNegativeIntegerOr(saved.mistAttempts, initial.mistAttempts),
    paperReleased: booleanOr(saved.paperReleased, initial.paperReleased)
  };
  return { state, migratedLegacyInterior, migratedLegacyChase };
}

function safeSpawnMatchesZone(
  safeSpawnId: GameState["qizhenLake"]["safeSpawnId"],
  zone: GameState["qizhenLake"]["zone"]
): boolean {
  if (zone === "dock") return safeSpawnId === "dock_entry" || safeSpawnId === "dock_kayak";
  if (zone === "open_water") return safeSpawnId === "open_water_entry";
  if (zone === "channel") return safeSpawnId === "channel_entry" || safeSpawnId === "channel_chase";
  return safeSpawnId === "swan_cove_entry";
}

function defaultSafeSpawnFor(
  zone: GameState["qizhenLake"]["zone"],
  vehicle: GameState["qizhenLake"]["vehicle"]
): GameState["qizhenLake"]["safeSpawnId"] {
  if (zone === "dock") return vehicle === "kayak" ? "dock_kayak" : "dock_entry";
  if (zone === "open_water") return "open_water_entry";
  if (zone === "channel") return "channel_entry";
  return "swan_cove_entry";
}

function isLegacyChapterThreeState(saved: Record<string, unknown>, ui: GameState["ui"]): boolean {
  const savedUi = asRecord(saved.ui);
  const savedPuzzle = asRecord(savedUi.libraryFinalsPuzzle);
  return ui.libraryFinalsPhase === "friend_contacted"
    || ui.libraryFinalsPuzzle.nextQuestId === "chapter_three_canteen_hunt"
    || savedPuzzle.nextQuestId === "chapter_three_book_hunt"
    || saved.currentScene === "bike_arcade"
    || saved.currentScene === "chapter_transition";
}

function hasChapterThreeProgress(
  canteenHunt: GameState["canteenHunt"],
  theaterHunt: GameState["theaterHunt"],
  qizhenLake: GameState["qizhenLake"]
): boolean {
  const canteenProgressed = canteenHunt.active
    || canteenHunt.phase !== "tracking"
    || canteenHunt.mode !== "light"
    || canteenHunt.identifiedTrayIds.length > 0
    || canteenHunt.returnedTrayIds.length > 0
    || canteenHunt.menuDarkClueRead
    || canteenHunt.pickupTimeErrorSeen
    || canteenHunt.pickupDarkClueRead
    || canteenHunt.defenseDrinkUsed
    || canteenHunt.identifiedExitIds.length > 0
    || canteenHunt.orderAttemptCount > 0
    || canteenHunt.pickupAttemptCount > 0
    || canteenHunt.blockHits > 0
    || canteenHunt.bikeCodeRead
    || canteenHunt.bikeLockCleaned
    || canteenHunt.bikePaid
    || canteenHunt.chaseCollisions > 0;
  const theaterProgressed = theaterHunt.active
    || theaterHunt.phase !== "entry_ticket"
    || theaterHunt.posterCleaned
    || theaterHunt.ticketCodeRead
    || theaterHunt.admitted
    || theaterHunt.collectedProgramIds.length > 0
    || theaterHunt.propBoxOpened
    || theaterHunt.spotlightRound > 0;
  const qizhenProgressed = qizhenLake.active
    || qizhenLake.phase !== "inactive"
    || qizhenLake.mapClueIds.length > 0
    || qizhenLake.introSeen
    || qizhenLake.zone !== "dock"
    || qizhenLake.vehicle !== "on_foot"
    || qizhenLake.boardingTutorialCompleted
    || qizhenLake.capsizeCount > 0
    || qizhenLake.observedFishingSpotIds.length > 0
    || qizhenLake.lockerOpened
    || qizhenLake.netCombined
    || qizhenLake.feedTinOpened
    || qizhenLake.fishCaught
    || qizhenLake.swanFed
    || qizhenLake.paperCaptured
    || qizhenLake.chaseAttempts > 0
    || qizhenLake.transitionReady
    || qizhenLake.reflectionRound > 0
    || qizhenLake.signsSolved
    || qizhenLake.paperReleased;
  return canteenProgressed || theaterProgressed || qizhenProgressed;
}

function createCanteenTrackingState(
  initial: GameState["canteenHunt"]
): GameState["canteenHunt"] {
  return {
    ...initial,
    active: true,
    phase: "tracking",
    mode: "light",
    trayTaskStarted: false,
    carriedTrayIds: [],
    identifiedTrayIds: [],
    returnedTrayIds: [],
    drinkShelfRead: false,
    drinkMixSequence: [],
    drinkMixAttemptCount: 0,
    queueChallengeSeen: false,
    promoDrinkPlaced: false,
    queueGapOpened: false,
    orderAttemptCount: 0,
    pickupAttemptCount: 0,
    blockHits: 0,
    bikeCodeRead: false,
    bikeLockCleaned: false,
    bikePaid: false,
    chaseCompleted: false,
    chaseAttemptCount: 0,
    chaseBestDistance: 0,
    chaseBestLives: 0,
    chaseCollisions: 0
  };
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

function isPotentiallyLoadableSave(value: string): boolean {
  try {
    const parsed = JSON.parse(value) as unknown;
    if (!isRecord(parsed)) return false;
    const hasEnvelopeShape = Object.prototype.hasOwnProperty.call(parsed, "version")
      || Object.prototype.hasOwnProperty.call(parsed, "state");
    return !hasEnvelopeShape
      || (SUPPORTED_ENVELOPE_VERSIONS.has(Number(parsed.version)) && isRecord(parsed.state));
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

function normalizeWallet(
  value: unknown,
  initial: WalletState,
  actOne: ActOneBootstrapState,
  items: GameState["items"],
  canteenHunt: GameState["canteenHunt"],
  saveHasWallet: boolean
): WalletState {
  const saved = asRecord(value);
  const inferred: WalletState = {
    // The 6.00 balance is spent by the gamepad purchase, so that fact wins
    // when old saves contain a contradictory combination of flags.
    campusCardCents: actOne.gamepadPurchased ? 0 : actOne.balanceShifted ? 600 : 6,
    // The tray receipt represents the two yuan cash payment. Once the bike
    // has been paid for, the receipt has already been consumed.
    cashCents: canteenHunt.bikePaid ? 0 : items.cafeteriaWages ? 200 : 0
  };
  if (!saveHasWallet) return inferred;
  return {
    campusCardCents: nonNegativeSafeIntegerOr(saved.campusCardCents, inferred.campusCardCents),
    cashCents: nonNegativeSafeIntegerOr(saved.cashCents, inferred.cashCents)
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
    musicMuted: booleanOr(saved.musicMuted, initial.musicMuted),
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

function normalizeConsumedItems(
  items: GameState["items"],
  ui: GameState["ui"],
  flags: GameState["flags"],
  theaterHunt: GameState["theaterHunt"],
  qizhenLake: GameState["qizhenLake"]
): void {
  // A successful check-in proves the first-chapter water recipe was completed.
  // Remove stale inputs/intermediates from older saves while preserving the
  // separate chapter-two weatherWater item.
  if (flags.checkinDone) {
    items.waterDrop = false;
    items.headphone = false;
    items.wateredHeadphone = false;
  }

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

  // The right arrow is retained after adjusting the campus-card balance, then
  // consumed when it pushes the 022 receipt out of the library desk gap.
  if (puzzle.seatReceiptCollected) items.rightArrow = false;

  const programSolved = ["prop_setup", "spotlight_ready", "spotlight_hunt", "reversal", "complete"].includes(theaterHunt.phase);
  const ticketScanned = theaterHunt.propBoxOpened
    || ["spotlight_ready", "spotlight_hunt", "reversal", "complete"].includes(theaterHunt.phase);
  const brushUsed = theaterHunt.paperDusted
    || ["spotlight_ready", "spotlight_hunt", "reversal", "complete"].includes(theaterHunt.phase);
  const spotlightStarted = ["spotlight_hunt", "reversal", "complete"].includes(theaterHunt.phase);
  if (theaterHunt.posterCleaned || theaterHunt.phase !== "entry_ticket") items.greaseTissue = false;
  if (theaterHunt.admitted || theaterHunt.phase !== "entry_ticket") {
    items.theaterTicketHalfA = false;
    items.theaterTicketHalfB = false;
  }
  if (ticketScanned) items.temporaryTheaterTicket = false;
  if (programSolved) {
    items.theaterProgramOpening = false;
    items.theaterProgramSpotlight = false;
    items.theaterProgramFinale = false;
  }
  if (brushUsed) items.fluorescentBrush = false;
  if (spotlightStarted) items.spotlightRemote = false;

  const allLocationSourcesRead = qizhenLake.bridgeClueFound
    && qizhenLake.reflectionClueFound
    && qizhenLake.lakeClueFound;
  const locationSolved = !["inactive", "location_search"].includes(qizhenLake.phase);
  if (allLocationSourcesRead || locationSolved) items.wetProgram = false;
  if (qizhenLake.mapClueIds.includes("bridge") || locationSolved) items.bridgeKeyword = false;
  if (qizhenLake.mapClueIds.includes("reflection") || locationSolved) items.reflectionKeyword = false;
  if (qizhenLake.mapClueIds.includes("lake") || locationSolved) items.lakeKeyword = false;

  if (!["inactive", "location_search", "lake_unlocked"].includes(qizhenLake.phase)) {
    items.reflectionCoordinate = false;
  }
}

function normalizeQizhenItems(
  items: GameState["items"],
  qizhenLake: GameState["qizhenLake"],
  normalization: QizhenNormalizationResult
): void {
  const kayakItemIds: Array<keyof GameState["items"]> = [
    "fishingRod",
    "rustedLockerKey",
    "nylonCord",
    "brokenNetFrame",
    "improvisedDipNet",
    "sealedFeedTin",
    "fishFeedPellets",
    "smallCarp",
    "swanMagnet",
    "magneticFishingRod"
  ];

  if (normalization.migratedLegacyInterior) {
    for (const itemId of kayakItemIds) items[itemId] = false;
    items.reflectionCoordinate = false;
    items.decoyPaper = !normalization.migratedLegacyChase;
    if (normalization.migratedLegacyChase) items.magneticFishingRod = true;
  }

  if (qizhenLake.rodFound && !qizhenLake.magneticRodCombined) items.fishingRod = true;
  if (qizhenLake.decoyBaitAttached) items.decoyPaper = false;

  if (qizhenLake.lockerOpened) {
    items.rustedLockerKey = false;
    if (!qizhenLake.netCombined) items.nylonCord = true;
  }
  if (qizhenLake.netCombined) {
    items.nylonCord = false;
    items.brokenNetFrame = false;
    items.improvisedDipNet = !qizhenLake.feedTinRetrieved;
  }
  if (qizhenLake.feedTinRetrieved) {
    items.improvisedDipNet = false;
    items.sealedFeedTin = !qizhenLake.feedTinOpened;
  }
  if (qizhenLake.feedTinOpened) {
    items.sealedFeedTin = false;
    items.fishFeedPellets = !qizhenLake.fishCaught;
  }
  if (qizhenLake.fishCaught) {
    items.fishFeedPellets = false;
    items.smallCarp = !qizhenLake.swanFed;
  }
  if (qizhenLake.swanFed) {
    items.smallCarp = false;
    items.swanMagnet = !qizhenLake.magneticRodCombined;
  }
  if (qizhenLake.magneticRodCombined) {
    items.fishingRod = false;
    items.swanMagnet = false;
    items.magneticFishingRod = !qizhenLake.magneticAttachmentBroken;
  }
  if (qizhenLake.magneticAttachmentBroken) items.magneticFishingRod = false;
}

function normalizeLibraryFinalsPuzzle(value: unknown, initial: LibraryFinalsPuzzleState): LibraryFinalsPuzzleState {
  const saved = asRecord(value);
  const bdCount = bdCountOr(saved.bdCount, initial.bdCount);
  const bdSelectedPostIds = stringArrayFromSet(saved.bdSelectedPostIds, VALID_BD_POST_IDS, initial.bdSelectedPostIds).slice(0, 4);
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
    archivedRuleBriefingSeen: typeof saved.archivedRuleBriefingSeen === "boolean"
      ? saved.archivedRuleBriefingSeen
      : booleanOr(saved.archivedRuleRead, initial.archivedRuleRead),
    frontDeskProofRequestSeen: booleanOr(
      saved.frontDeskProofRequestSeen,
      booleanOr(saved.itemReportGenerated, initial.itemReportGenerated)
        || booleanOr(saved.nonPersonProofStamped, initial.nonPersonProofStamped)
    ),
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
    bdCount,
    appliedBdReplyIds: stringArrayFromSet(saved.appliedBdReplyIds, VALID_BD_REPLY_IDS, initial.appliedBdReplyIds),
    bdSelectedPostIds: bdCount >= 3 && bdSelectedPostIds.length === 0 ? [...COMPLETED_BD_POST_IDS] : bdSelectedPostIds,
    bdPasswordAttemptCount: nonNegativeIntegerOr(saved.bdPasswordAttemptCount, initial.bdPasswordAttemptCount),
    recoverySubmittedEvidenceIds: stringArrayFromSet(saved.recoverySubmittedEvidenceIds, VALID_LIBRARY_RECOVERY_EVIDENCE_IDS, initial.recoverySubmittedEvidenceIds),
    evictionPassGenerated: booleanOr(saved.evictionPassGenerated, initial.evictionPassGenerated),
    passBriefingSeen: typeof saved.passBriefingSeen === "boolean"
      ? saved.passBriefingSeen
      : booleanOr(saved.evictionPassGenerated, initial.evictionPassGenerated),
    backpackEvicted: booleanOr(saved.backpackEvicted, initial.backpackEvicted),
    playerSeated: booleanOr(saved.playerSeated, initial.playerSeated),
    nextQuestId: saved.nextQuestId === "chapter_three_canteen_hunt" || saved.nextQuestId === "chapter_three_book_hunt"
      ? "chapter_three_canteen_hunt"
      : initial.nextQuestId,
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
    archivedRuleBriefingSeen: true,
    frontDeskProofRequestSeen: true,
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
    bdSelectedPostIds: [...COMPLETED_BD_POST_IDS],
    bdPasswordAttemptCount: 1,
    recoverySubmittedEvidenceIds: ["bag_non_person_proof", "seat_022_receipt", "library_presence_proof"],
    evictionPassGenerated: true,
    passBriefingSeen: true,
    backpackEvicted: true,
    playerSeated: true,
    nextQuestId: "chapter_three_canteen_hunt",
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
function nullableStringOr(value: unknown, fallback: string | null): string | null {
  if (value === null) return null;
  return typeof value === "string" ? value : fallback;
}
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
