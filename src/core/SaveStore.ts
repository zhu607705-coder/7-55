import type {
  ActOneBootstrapPhase,
  ActOneBootstrapState,
  BikeArcadeChapterState,
  CanteenDrinkIngredientId,
  CanteenMenuOptionId,
  ChapterFour755FloorId,
  ChapterFourFactId,
  ChapterFourPhase,
  ChapterFourRoom204Placement,
  ChapterFourTimeState,
  ClockArchiveClueId,
  ClockCalibrationPhase,
  ClockCoarseLockId,
  ClockDriftChannelId,
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
  QizhenJournalDraft,
  QizhenJournalStatus,
  QizhenLakePhase,
  QizhenMapClueId,
  QizhenPhotoRecipe,
  QizhenPhotoRecord,
  QizhenPhotoSpotId,
  QizhenPhotoTag,
  WalletState
} from "./types";
import {
  normalizeHiddenPhoneHomeAppIds,
  normalizePhoneHomeAppOrder
} from "./PhoneHomeApps";
import { draftIdFor } from "../modules/QizhenJournalModel";
import {
  createCanonicalCompleteRoom204Placements,
  isRoom204PlacementSetComplete,
  normalizeRoom204Placements
} from "../scenes/rpg/ChapterFourRoom204Model";
import { BIKE_SAVE_KEY, GAME_SAVE_BACKUP_KEY, GAME_SAVE_KEY } from "./StorageKeys";
import { canEnterScene, sanitizeZjudingPage } from "./FeatureAccess";

const SAVE_VERSION = 25;
const WALLET_SAVE_VERSION = 12;
const QIZHEN_KAYAK_SAVE_VERSION = 18;
const SUPPORTED_ENVELOPE_VERSIONS = new Set([2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, SAVE_VERSION]);

const VALID_RUNTIME_MODES = new Set<GameState["runtimeMode"]>(["phone", "rpg"]);
const VALID_RPG_SCENES = new Set<GameState["rpgScene"]>([
  "campus_bootstrap", "campus_qizhen_loop", "dorm_hub", "library_interior", "canteen_interior", "theater_interior", "qizhen_lake",
  "duan_yongping_temporal_maze"
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
  "library_shelf_755",
  "c4_a1_lobby",
  "c4_a1_main_elevator",
  "c4_a2_corridor",
  "c4_a2_room202",
  "c4_a3_wayfinding",
  "c4_a3_skybridge",
  "c4_b3_landing",
  "c4_b2_activity",
  "c4_b2_final_room"
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
  "alarm", "desktop", "phone_home", "settings", "wechat", "cc98", "zjuding", "tiyi", "weather",
  "photos", "timeline_recovery", "voice_memos", "campus_card", "bike_arcade", "chapter_transition",
  "checkin", "bonsai", "clock", "ending"
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
const VALID_THEATER_TICKET_COMMISSION_PHASES = new Set<GameState["theaterHunt"]["cc98TicketCommissionPhase"]>([
  "locked", "posted", "accepted", "first_wave_failed", "delivered"
]);
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
const VALID_CHAPTER_THREE_INTERLUDE_PHASES = new Set<GameState["chapterThreeInterlude"]["phase"]>([
  "inactive", "reboot", "journal_closeout", "evidence_collection", "timeline_assembly",
  "destination_verified", "replay_ready", "complete"
]);
const VALID_CHAPTER_THREE_INTERLUDE_PHOTOS = new Set<GameState["chapterThreeInterlude"]["photoFrameIds"][number]>([
  "paper_left", "paper_middle", "paper_right"
]);
const VALID_CHAPTER_THREE_INTERLUDE_VOICES = new Set<GameState["chapterThreeInterlude"]["voiceClipOrder"][number]>([
  "lake", "stone", "lobby", "broadcast"
]);
const VALID_CHAPTER_THREE_INTERLUDE_EVIDENCE = new Set<GameState["chapterThreeInterlude"]["evidenceIds"][number]>([
  "journal_start", "photo_direction", "network_destination", "broadcast_end"
]);
const VALID_CHAPTER_THREE_INTERLUDE_DECOYS = new Set<GameState["chapterThreeInterlude"]["rejectedDecoyIds"][number]>([
  "canteen_0755", "theater_0832", "status_clock_075523"
]);
const VALID_QIZHEN_SAFE_SPAWNS = new Set<GameState["qizhenLake"]["safeSpawnId"]>([
  "dock_entry", "dock_kayak", "open_water_entry", "channel_entry", "swan_cove_entry", "channel_chase"
]);
const VALID_QIZHEN_PADDLE_SIDES = new Set<NonNullable<GameState["qizhenLake"]["boardingLastSide"]>>(["left", "right"]);
const VALID_QIZHEN_FISHING_SPOTS = new Set<QizhenFishingSpotId>(["locker_key", "net_frame", "paper", "fish"]);
const VALID_QIZHEN_MAP_CLUES = new Set<QizhenMapClueId>(["bridge", "reflection", "lake"]);
const VALID_QIZHEN_DECOY_TARGETS = new Set<QizhenDecoyTargetId>(["notice", "bridge", "lamp"]);
const VALID_QIZHEN_JOURNAL_STATUSES = new Set<QizhenJournalStatus>([
  "locked", "capture_ready", "main_draft", "open", "summary_ready", "archived"
]);
const VALID_QIZHEN_PHOTO_SPOTS = new Set<QizhenPhotoSpotId>(["lake_center", "dock", "reflection", "swan_cove"]);
const VALID_QIZHEN_PHOTO_TAGS = new Set<QizhenPhotoTag>([
  "composition_ok", "tilted", "high_speed", "ripple_clear",
  "ripple_broken", "swan_near", "swan_far", "swan_aftermath"
]);
const VALID_QIZHEN_SWAN_BUCKETS = new Set(["near", "mid", "far", "gone"]);
const VALID_QIZHEN_RIPPLE_BUCKETS = new Set(["clear", "partial", "lost"]);
const VALID_QIZHEN_SUMMARY_CHOICES = new Set<NonNullable<GameState["qizhenLake"]["journal"]["summaryChoice"]>>(["safe_return", "details_withheld"]);
const VALID_CHAPTER_FOUR_PHASES = new Set<ChapterFourPhase>([
  "opening_handoff", "opening_paper_caught", "hall_clock_inspection", "bakery_hour_hand",
  "room204_restore", "maintenance_repair", "blackout_light_grid", "final_chase",
  "final_minute_recovery", "return_to_clock", "morning_checkin", "exterior_closure", "complete"
]);
const LEGACY_CHAPTER_FOUR_PHASES = new Set([
  "inactive", "arrival", "airflow_overlay", "elevator_track_sync", "npc_schedule_route",
  "corridor_bay_reconstruction", "wayfinding_fragment_board", "bridge_floor_discrimination",
  "stair_echo_direction", "multicam_video_edit", "echo_action_record", "dual_lift_logistics",
  "warm_air_balance", "first_cycle_reset", "route_schedule", "clock_phase_lock", "complete"
]);
const LEGACY_CHAPTER_FOUR_PUZZLE_IDS = new Set<GameState["chapter4"]["solvedPuzzleIds"][number]>([
  "airflow_overlay", "elevator_track_sync", "npc_schedule_route", "corridor_bay_reconstruction",
  "wayfinding_fragment_board", "bridge_floor_discrimination", "stair_echo_direction",
  "multicam_video_edit", "echo_action_record", "dual_lift_logistics", "warm_air_balance",
  "route_schedule", "clock_phase_lock"
]);
const VALID_CHAPTER_FOUR_FACT_IDS = new Set<ChapterFourFactId>([
  "opening_paper_at_noticeboard", "opening_paper_caught", "external_time_rejected",
  "hall_clock_inspected", "bakery_conveyor_lamp_inspected", "bakery_hour_hand_exposed",
  "bakery_hour_hand_collected", "hour_hand_installed", "a3_reference_observed",
  "room204_residual_observed", "room204_restored", "room204_projection_completed",
  "positioning_plate_collected", "positioning_plate_installed",
  "cart_wheel_inspected", "cart_wheel_cover_opened", "cart_wheel_repaired", "clock_gear_repaired",
  "paper_temporarily_out_of_inventory", "light_grid_locked", "final_minute_recovered",
  "final_minute_installed", "checkin_card_accepted", "checkin_paper_accepted",
  "exterior_closure_acknowledged"
]);
const VALID_CHAPTER_FOUR_MODES = new Set<GameState["chapter4"]["mode"]>(["light", "dark"]);
const VALID_CHAPTER_FOUR_FLOORS = new Set<ChapterFour755FloorId>(["A1", "A2", "A3"]);
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
  "chapter_one", "chapter_two", "chapter_three", "chapter_four"
]);
const VALID_CLOCK_CALIBRATION_PHASES = new Set<ClockCalibrationPhase>(["tampered", "calibrating", "release_ready", "aligned"]);
const VALID_CLOCK_CALIBRATION_STEPS = new Set<GameState["clockCalibration"]["step"]>([
  "target_selection", "coarse_time", "seconds_trim", "phase_lock", "complete"
]);
const VALID_CLOCK_ARCHIVE_CLUE_IDS = new Set<ClockArchiveClueId>([
  "room_b2_04", "schedule_0800", "attendance_open"
]);
const VALID_CLOCK_COARSE_LOCK_IDS = new Set<ClockCoarseLockId>(["hour", "minute"]);
const VALID_CLOCK_DRIFT_CHANNEL_IDS = new Set<ClockDriftChannelId>(["gate", "elevator", "room"]);

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
      const trayPreviouslyCompleted = ["drink_mix", "menu_order", "pickup_search", "exit_blocking", "chase_ready", "chasing", "theater_reached"].includes(savedCanteenPhase);
      const drinkPreviouslyCompleted = ["menu_order", "pickup_search", "exit_blocking", "chase_ready", "chasing", "theater_reached"].includes(savedCanteenPhase);
      const menuPreviouslyCompleted = ["pickup_search", "exit_blocking", "chase_ready", "chasing", "theater_reached"].includes(savedCanteenPhase);
      const pickupPreviouslyCompleted = ["exit_blocking", "chase_ready", "chasing", "theater_reached"].includes(savedCanteenPhase);
      let canteenHunt: GameState["canteenHunt"] = {
        active: typeof savedCanteenHunt.active === "boolean" ? savedCanteenHunt.active : initial.canteenHunt.active,
        phase: savedCanteenPhase === "entered" ? "tray_search" : savedCanteenPhase,
        mode: enumOr(savedCanteenHunt.mode, VALID_CANTEEN_MODES, initial.canteenHunt.mode),
        entryPaperEscaped: booleanOr(
          savedCanteenHunt.entryPaperEscaped,
          savedCanteenPhase === "entered"
          || trayPreviouslyCompleted
          || booleanOr(savedCanteenHunt.trayTaskStarted, false)
          || (Array.isArray(savedCanteenHunt.returnedTrayIds) && savedCanteenHunt.returnedTrayIds.length > 0)
        ),
        trayTaskStarted: booleanOr(
          savedCanteenHunt.trayTaskStarted,
          savedCanteenPhase === "entered"
          || trayPreviouslyCompleted
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
      const savedTheaterPhase = enumOr(savedTheaterHunt.phase, VALID_THEATER_HUNT_PHASES, initial.theaterHunt.phase);
      const savedTheaterActive = booleanOr(savedTheaterHunt.active, initial.theaterHunt.active);
      const savedTheaterAdmitted = booleanOr(savedTheaterHunt.admitted, initial.theaterHunt.admitted);
      const savedTicketCodeRead = booleanOr(savedTheaterHunt.ticketCodeRead, initial.theaterHunt.ticketCodeRead);
      const savedTicketCodeAttempts = nonNegativeIntegerOr(savedTheaterHunt.ticketCodeAttempts, initial.theaterHunt.ticketCodeAttempts);
      const migratedTicketCommissionPhase: GameState["theaterHunt"]["cc98TicketCommissionPhase"] =
        savedTheaterPhase !== "entry_ticket"
        || savedTheaterAdmitted
        || items.theaterTicketHalfB
        || items.temporaryTheaterTicket
          ? "delivered"
          : savedTheaterActive && (savedTicketCodeRead || savedTicketCodeAttempts > 0)
            ? "accepted"
            : savedTheaterActive
              ? "posted"
              : "locked";
      const savedTicketCommissionPhase = enumOr(
        savedTheaterHunt.cc98TicketCommissionPhase,
        VALID_THEATER_TICKET_COMMISSION_PHASES,
        migratedTicketCommissionPhase
      );
      const theaterHunt: GameState["theaterHunt"] = {
        active: savedTheaterActive,
        phase: savedTheaterPhase,
        mode: enumOr(savedTheaterHunt.mode, VALID_THEATER_MODES, initial.theaterHunt.mode),
        cc98TicketCommissionPhase: savedTicketCommissionPhase,
        cc98TicketClaimedWave: savedTicketCommissionPhase === "delivered"
          ? savedTheaterHunt.cc98TicketClaimedWave === 1 || savedTheaterHunt.cc98TicketClaimedWave === 2
            ? savedTheaterHunt.cc98TicketClaimedWave
            : 2
          : null,
        posterCleaned: booleanOr(savedTheaterHunt.posterCleaned, initial.theaterHunt.posterCleaned),
        ticketCodeRead: savedTicketCodeRead,
        ticketCodeAttempts: savedTicketCodeAttempts,
        admitted: savedTheaterAdmitted,
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
        envelopeVersion < QIZHEN_KAYAK_SAVE_VERSION
      );
      const qizhenLake = qizhenNormalization.state;
      const clockCalibration = normalizeClockCalibration(saved.clockCalibration, initial.clockCalibration);
      const chapter4Normalization = normalizeChapterFour(
        saved.chapter4,
        initial.chapter4,
        envelopeVersion
      );
      const chapter4 = chapter4Normalization.state;
      const chapterThreeInterlude = normalizeChapterThreeInterlude(
        saved.chapterThreeInterlude,
        initial.chapterThreeInterlude,
        qizhenLake,
        chapter4
      );
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
      normalizeChapterFourItems(items, chapter4, chapter4Normalization.migrationKind);
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
        chapterThreeInterlude,
        clockCalibration,
        chapter4,
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
      if (chapter4Normalization.migrationKind === "legacy_in_progress") {
        hydrated.runtimeMode = "rpg";
        hydrated.rpgScene = "duan_yongping_temporal_maze";
        hydrated.rpgCheckpoint = "c4_a1_lobby";
        hydrated.currentScene = "phone_home";
      }
      if (chapter4Normalization.migrationKind === "legacy_complete") {
        hydrated.clockCalibration = {
          ...hydrated.clockCalibration,
          phase: "aligned",
          step: "complete",
          displayedSeconds: 28500,
          targetSeconds: 28500,
          selectedTargetSeconds: 28500
        };
      }
      if (hydrated.rpgScene === "duan_yongping_temporal_maze") {
        hydrated.rpgCheckpoint = normalizeChapterFourCheckpoint(
          hydrated.rpgCheckpoint,
          hydrated.chapter4
        );
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
  const legacyCompletionRecorded = savedPhase === "complete"
    || booleanOr(saved.transitionReady, false)
    || Number(saved.chaseDistance) >= 1000;
  const migratedLegacyChase = !legacyCompletionRecorded && (
    savedPhase === "chase_ready"
    || (migrateLegacyPaperRelease && booleanOr(saved.paperReleased, false))
  );
  const migratedLegacyInterior = migratedLegacyChase || LEGACY_QIZHEN_INTERIOR_PHASES.has(savedPhase);
  const phase: QizhenLakePhase = legacyCompletionRecorded
    ? "complete"
    : migratedLegacyChase
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
    // v22:拍照记录。旧档缺 journal 字段;已完成启真湖的旧档直接迁为兼容归档。
    journal: normalizeQizhenJournal(saved.journal, initial.journal, completed),
    dockCollisionCount: nonNegativeIntegerOr(saved.dockCollisionCount, initial.dockCollisionCount),
    swanAlertLevel: nonNegativeIntegerOr(saved.swanAlertLevel, initial.swanAlertLevel),
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

/**
 * v22 拍照记录的水合。旧档(v21 及更早)没有 journal 字段:未完成启真湖的档
 * 补默认值;已完成启真湖的旧档(legacyCompleted)直接迁为兼容归档——status
 * "archived"、照片与楼层保持空的只读占位,不能回退到拍照任务。
 * 已有 journal 的存档逐字段 sanitize:照片记录显式重建,只保留合同字段,
 * 任何 Base64/canvas/截图数据都在重建时被丢弃(照片只存 recipe)。
 */
function normalizeQizhenJournal(
  value: unknown,
  initial: GameState["qizhenLake"]["journal"],
  legacyCompleted: boolean
): GameState["qizhenLake"]["journal"] {
  if (!isRecord(value)) {
    return legacyCompleted
      ? { ...initial, status: "archived", summaryPublished: true }
      : { ...initial };
  }
  const savedMain = normalizeQizhenPhotoRecord(value.mainPhoto);
  const mainPhoto = savedMain?.spotId === "lake_center" ? savedMain : null;
  const optionalPhotos: GameState["qizhenLake"]["journal"]["optionalPhotos"] = {};
  const savedOptional = asRecord(value.optionalPhotos);
  (["dock", "reflection", "swan_cove"] as const).forEach((spotId) => {
    const photo = normalizeQizhenPhotoRecord(savedOptional[spotId]);
    if (photo && photo.spotId === spotId) optionalPhotos[spotId] = photo;
  });
  const pendingDraft = normalizeQizhenJournalDraft(value.pendingDraft, mainPhoto, optionalPhotos);
  return {
    status: enumOr(value.status, VALID_QIZHEN_JOURNAL_STATUSES, initial.status),
    threadId: typeof value.threadId === "string" ? value.threadId : initial.threadId,
    threadSeed: nonNegativeSafeIntegerOr(value.threadSeed, initial.threadSeed),
    mainPhoto,
    optionalPhotos,
    mainTitleId: nullableStringOr(value.mainTitleId, initial.mainTitleId),
    mainStatusId: nullableStringOr(value.mainStatusId, initial.mainStatusId),
    publishedSpotIds: filteredStringArrayFromSet(value.publishedSpotIds, VALID_QIZHEN_PHOTO_SPOTS, initial.publishedSpotIds),
    pendingDraft,
    summaryChoice: nullableEnumOr(value.summaryChoice, VALID_QIZHEN_SUMMARY_CHOICES, initial.summaryChoice),
    summaryPublished: booleanOr(value.summaryPublished, initial.summaryPublished),
    fishingAssistUnlocked: booleanOr(value.fishingAssistUnlocked, initial.fishingAssistUnlocked),
    fishingAssistConsumed: booleanOr(value.fishingAssistConsumed, initial.fishingAssistConsumed),
    memoryCardUnlocked: booleanOr(value.memoryCardUnlocked, initial.memoryCardUnlocked)
  };
}

function normalizeQizhenPhotoRecord(value: unknown): QizhenPhotoRecord | null {
  if (!isRecord(value)) return null;
  if (typeof value.id !== "string" || value.id.length === 0) return null;
  if (typeof value.spotId !== "string" || !VALID_QIZHEN_PHOTO_SPOTS.has(value.spotId as QizhenPhotoSpotId)) {
    return null;
  }
  const capturedAtSeconds = nonNegativeIntegerOr(value.capturedAtSeconds, -1);
  if (capturedAtSeconds < 0) return null;
  const recipe = normalizeQizhenPhotoRecipe(value.recipe);
  if (!recipe) return null;
  return {
    id: value.id,
    spotId: value.spotId as QizhenPhotoSpotId,
    capturedAtSeconds,
    tags: filteredStringArrayFromSet(value.tags, VALID_QIZHEN_PHOTO_TAGS, []),
    recipe
  };
}

function normalizeQizhenPhotoRecipe(value: unknown): QizhenPhotoRecipe | null {
  if (!isRecord(value)) return null;
  if (typeof value.zone !== "string" || !VALID_QIZHEN_ZONES.has(value.zone as GameState["qizhenLake"]["zone"])) {
    return null;
  }
  const cropCenterX = rangedNumberOr(value.cropCenterX, 0, 1672, Number.NaN);
  const cropCenterY = rangedNumberOr(value.cropCenterY, 0, 941, Number.NaN);
  const kayakX = rangedNumberOr(value.kayakX, 0, 1672, Number.NaN);
  const kayakY = rangedNumberOr(value.kayakY, 0, 941, Number.NaN);
  const zoomStep = rangedIntegerOr(value.zoomStep, 0, 2, Number.NaN);
  const headingBucket = rangedIntegerOr(value.headingBucket, 0, 7, Number.NaN);
  if ([cropCenterX, cropCenterY, kayakX, kayakY, zoomStep, headingBucket].some((entry) => Number.isNaN(entry))) {
    return null;
  }
  const recipe: QizhenPhotoRecipe = {
    zone: value.zone as QizhenPhotoRecipe["zone"],
    cropCenterX,
    cropCenterY,
    zoomStep: zoomStep as QizhenPhotoRecipe["zoomStep"],
    kayakX,
    kayakY,
    headingBucket: headingBucket as QizhenPhotoRecipe["headingBucket"]
  };
  if (typeof value.swanDistanceBucket === "string" && VALID_QIZHEN_SWAN_BUCKETS.has(value.swanDistanceBucket)) {
    recipe.swanDistanceBucket = value.swanDistanceBucket as QizhenPhotoRecipe["swanDistanceBucket"];
  }
  if (typeof value.rippleClarityBucket === "string" && VALID_QIZHEN_RIPPLE_BUCKETS.has(value.rippleClarityBucket)) {
    recipe.rippleClarityBucket = value.rippleClarityBucket as QizhenPhotoRecipe["rippleClarityBucket"];
  }
  return recipe;
}

/** 草稿必须挂在 sanitize 后仍存在的照片上,且 id 与幂等键格式一致,否则丢弃。 */
function normalizeQizhenJournalDraft(
  value: unknown,
  mainPhoto: QizhenPhotoRecord | null,
  optionalPhotos: GameState["qizhenLake"]["journal"]["optionalPhotos"]
): QizhenJournalDraft | null {
  if (!isRecord(value)) return null;
  const kind = value.kind === "main" ? "main" : value.kind === "spot" ? "spot" : null;
  if (!kind) return null;
  const savedPhoto = asRecord(value.photo);
  const photoId = typeof savedPhoto.id === "string" ? savedPhoto.id : "";
  const stored = mainPhoto?.id === photoId
    ? mainPhoto
    : Object.values(optionalPhotos).find((photo) => photo.id === photoId) ?? null;
  if (!stored) return null;
  if (kind === "main" && stored.spotId !== "lake_center") return null;
  if (kind === "spot" && stored.spotId === "lake_center") return null;
  if (value.id !== draftIdFor(photoId)) return null;
  return {
    id: value.id,
    kind,
    photo: stored,
    titleId: nullableStringOr(value.titleId, null),
    statusId: nullableStringOr(value.statusId, null),
    captionId: nullableStringOr(value.captionId, null)
  };
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

function normalizeClockCalibration(
  value: unknown,
  initial: GameState["clockCalibration"]
): GameState["clockCalibration"] {
  const saved = asRecord(value);
  const phase = enumOr(saved.phase, VALID_CLOCK_CALIBRATION_PHASES, initial.phase);
  const displayedSeconds = rangedIntegerOr(saved.displayedSeconds, 0, 86399, initial.displayedSeconds);
  const targetSeconds = rangedIntegerOr(saved.targetSeconds, 0, 86399, initial.targetSeconds);
  const directDistance = Math.abs(displayedSeconds - targetSeconds);
  const targetDistance = Math.min(directDistance, 86400 - directDistance);
  const inferredStep: GameState["clockCalibration"]["step"] = phase === "aligned"
    ? "complete"
    : phase === "release_ready"
      ? "phase_lock"
      : phase === "calibrating"
        ? targetDistance <= 60 ? "seconds_trim" : "coarse_time"
        : "target_selection";
  const savedStep = enumOr(saved.step, VALID_CLOCK_CALIBRATION_STEPS, inferredStep);
  const step: GameState["clockCalibration"]["step"] = phase === "aligned"
    ? "complete"
    : phase === "release_ready"
      ? "phase_lock"
      : phase === "tampered"
        ? "target_selection"
        : savedStep === "coarse_time" || savedStep === "seconds_trim"
          ? savedStep
          : inferredStep;
  const savedSelectedTarget = typeof saved.selectedTargetSeconds === "number"
    && Number.isInteger(saved.selectedTargetSeconds)
    && saved.selectedTargetSeconds >= 0
    && saved.selectedTargetSeconds <= 86399
    ? saved.selectedTargetSeconds
    : null;
  const selectedTargetSeconds = step === "target_selection"
    ? savedSelectedTarget
    : savedSelectedTarget ?? targetSeconds;
  const archiveClueIds = filteredStringArrayFromSet(
    saved.archiveClueIds,
    VALID_CLOCK_ARCHIVE_CLUE_IDS,
    step === "target_selection" ? initial.archiveClueIds : ["room_b2_04", "schedule_0800", "attendance_open"]
  );
  const coarseLockIds = filteredStringArrayFromSet(
    saved.coarseLockIds,
    VALID_CLOCK_COARSE_LOCK_IDS,
    step === "target_selection" || step === "coarse_time" ? initial.coarseLockIds : ["hour", "minute"]
  );
  const driftCorrectedChannelIds = filteredStringArrayFromSet(
    saved.driftCorrectedChannelIds,
    VALID_CLOCK_DRIFT_CHANNEL_IDS,
    step === "phase_lock" || step === "complete" ? ["gate", "elevator", "room"] : initial.driftCorrectedChannelIds
  );
  return {
    phase,
    step,
    displayedSeconds,
    targetSeconds,
    selectedTargetSeconds,
    archiveClueIds,
    coarseLockIds,
    driftCorrectedChannelIds,
    driftAttempts: nonNegativeIntegerOr(saved.driftAttempts, initial.driftAttempts),
    phaseLockHits: rangedIntegerOr(
      saved.phaseLockHits,
      0,
      3,
      step === "complete" ? 3 : initial.phaseLockHits
    ),
    phaseLockAttempts: nonNegativeIntegerOr(saved.phaseLockAttempts, initial.phaseLockAttempts),
    adjustCount: nonNegativeIntegerOr(saved.adjustCount, initial.adjustCount)
  };
}

type ChapterFourMigrationKind =
  | "none"
  | "legacy_not_started"
  | "legacy_in_progress"
  | "legacy_complete";

interface ChapterFourNormalizationResult {
  state: GameState["chapter4"];
  migrationKind: ChapterFourMigrationKind;
}

interface ChapterFourTimeContract {
  timeState: ChapterFourTimeState;
  worldTimeSeconds: number;
  phoneStatusTimeSeconds: number;
  phoneStatusTimeTrusted: boolean;
}

const CHAPTER_FOUR_TIME_BY_PHASE: Record<ChapterFourPhase, ChapterFourTimeContract> = {
  opening_handoff: {
    timeState: "2245_opening",
    worldTimeSeconds: 81900,
    phoneStatusTimeSeconds: 28523,
    phoneStatusTimeTrusted: false
  },
  opening_paper_caught: {
    timeState: "2245_opening",
    worldTimeSeconds: 81900,
    phoneStatusTimeSeconds: 28523,
    phoneStatusTimeTrusted: false
  },
  hall_clock_inspection: {
    timeState: "2245_opening",
    worldTimeSeconds: 81900,
    phoneStatusTimeSeconds: 28523,
    phoneStatusTimeTrusted: false
  },
  bakery_hour_hand: {
    timeState: "1225_bakery",
    worldTimeSeconds: 44700,
    phoneStatusTimeSeconds: 44700,
    phoneStatusTimeTrusted: true
  },
  room204_restore: {
    timeState: "1850_evening",
    worldTimeSeconds: 67800,
    phoneStatusTimeSeconds: 67800,
    phoneStatusTimeTrusted: true
  },
  maintenance_repair: {
    timeState: "2245_maintenance",
    worldTimeSeconds: 81900,
    phoneStatusTimeSeconds: 81900,
    phoneStatusTimeTrusted: true
  },
  blackout_light_grid: {
    timeState: "0754_blackout",
    worldTimeSeconds: 28440,
    phoneStatusTimeSeconds: 28440,
    phoneStatusTimeTrusted: true
  },
  final_chase: {
    timeState: "0754_blackout",
    worldTimeSeconds: 28440,
    phoneStatusTimeSeconds: 28440,
    phoneStatusTimeTrusted: true
  },
  final_minute_recovery: {
    timeState: "0754_blackout",
    worldTimeSeconds: 28440,
    phoneStatusTimeSeconds: 28440,
    phoneStatusTimeTrusted: true
  },
  return_to_clock: {
    timeState: "0754_blackout",
    worldTimeSeconds: 28440,
    phoneStatusTimeSeconds: 28440,
    phoneStatusTimeTrusted: true
  },
  morning_checkin: {
    timeState: "0755_morning",
    worldTimeSeconds: 28500,
    phoneStatusTimeSeconds: 28500,
    phoneStatusTimeTrusted: true
  },
  exterior_closure: {
    timeState: "0755_morning",
    worldTimeSeconds: 28500,
    phoneStatusTimeSeconds: 28500,
    phoneStatusTimeTrusted: true
  },
  complete: {
    timeState: "0755_morning",
    worldTimeSeconds: 28500,
    phoneStatusTimeSeconds: 28500,
    phoneStatusTimeTrusted: true
  }
};

const CHAPTER_FOUR_EXTERIOR_WAITING_FACT_IDS: ChapterFourFactId[] = [
  "opening_paper_at_noticeboard",
  "opening_paper_caught",
  "external_time_rejected",
  "hall_clock_inspected",
  "bakery_conveyor_lamp_inspected",
  "bakery_hour_hand_exposed",
  "bakery_hour_hand_collected",
  "hour_hand_installed",
  "a3_reference_observed",
  "room204_residual_observed",
  "room204_restored",
  "room204_projection_completed",
  "positioning_plate_collected",
  "positioning_plate_installed",
  "cart_wheel_inspected",
  "cart_wheel_cover_opened",
  "cart_wheel_repaired",
  "clock_gear_repaired",
  "paper_temporarily_out_of_inventory",
  "light_grid_locked",
  "final_minute_recovered",
  "final_minute_installed",
  "checkin_card_accepted",
  "checkin_paper_accepted"
];

const CHAPTER_FOUR_OPENING_FACT_ORDER = [
  "opening_paper_at_noticeboard",
  "opening_paper_caught",
  "external_time_rejected",
  "hall_clock_inspected"
] as const satisfies readonly ChapterFourFactId[];
const CHAPTER_FOUR_BAKERY_FACT_ORDER = [
  "bakery_conveyor_lamp_inspected",
  "bakery_hour_hand_exposed",
  "bakery_hour_hand_collected",
  "hour_hand_installed"
] as const satisfies readonly ChapterFourFactId[];
const CHAPTER_FOUR_POST_BAKERY_PHASES: ReadonlySet<ChapterFourPhase> = new Set([
  "room204_restore",
  "maintenance_repair",
  "blackout_light_grid",
  "final_chase",
  "final_minute_recovery",
  "return_to_clock",
  "morning_checkin",
  "exterior_closure",
  "complete"
]);
const CHAPTER_FOUR_ROOM204_FACT_ORDER = [
  "a3_reference_observed",
  "room204_residual_observed",
  "room204_restored",
  "room204_projection_completed",
  "positioning_plate_collected",
  "positioning_plate_installed"
] as const satisfies readonly ChapterFourFactId[];
const CHAPTER_FOUR_POST_ROOM204_PHASES: ReadonlySet<ChapterFourPhase> = new Set([
  "maintenance_repair",
  "blackout_light_grid",
  "final_chase",
  "final_minute_recovery",
  "return_to_clock",
  "morning_checkin",
  "exterior_closure",
  "complete"
]);
const CHAPTER_FOUR_MAINTENANCE_FACT_ORDER = [
  "cart_wheel_inspected",
  "cart_wheel_cover_opened",
  "cart_wheel_repaired",
  "clock_gear_repaired"
] as const satisfies readonly ChapterFourFactId[];
const CHAPTER_FOUR_POST_MAINTENANCE_PHASES: ReadonlySet<ChapterFourPhase> = new Set([
  "blackout_light_grid",
  "final_chase",
  "final_minute_recovery",
  "return_to_clock",
  "morning_checkin",
  "exterior_closure",
  "complete"
]);
const CHAPTER_FOUR_POST_MINUTE_THEFT_PHASES: ReadonlySet<ChapterFourPhase> = new Set([
  "blackout_light_grid",
  "final_chase",
  "final_minute_recovery",
  "return_to_clock",
  "morning_checkin",
  "exterior_closure",
  "complete"
]);
const CHAPTER_FOUR_POST_LIGHT_GRID_PHASES: ReadonlySet<ChapterFourPhase> = new Set([
  "final_chase",
  "final_minute_recovery",
  "return_to_clock",
  "morning_checkin",
  "exterior_closure",
  "complete"
]);

/**
 * Restores the authored opening handshakes without inventing a second phase.
 * A later phase implies its completed prerequisites, while the two resumable
 * presentation phases deliberately keep their final fact optional.
 */
function normalizeChapterFourFactClosure(
  phase: ChapterFourPhase,
  savedFactIds: readonly ChapterFourFactId[]
): ChapterFourFactId[] {
  const facts = new Set(savedFactIds);
  if (facts.has("hall_clock_inspected")) facts.add("external_time_rejected");
  if (facts.has("external_time_rejected")) facts.add("opening_paper_caught");
  if (facts.has("opening_paper_caught")) facts.add("opening_paper_at_noticeboard");
  if (facts.has("hour_hand_installed")) facts.add("bakery_hour_hand_collected");
  if (facts.has("bakery_hour_hand_collected")) facts.add("bakery_hour_hand_exposed");
  if (facts.has("bakery_hour_hand_exposed")) facts.add("bakery_conveyor_lamp_inspected");

  if (phase === "opening_handoff") {
    facts.delete("opening_paper_caught");
    facts.delete("external_time_rejected");
    facts.delete("hall_clock_inspected");
  } else if (phase === "opening_paper_caught") {
    facts.add("opening_paper_at_noticeboard");
    facts.add("opening_paper_caught");
    facts.delete("hall_clock_inspected");
  } else if (phase === "hall_clock_inspection") {
    facts.add("opening_paper_at_noticeboard");
    facts.add("opening_paper_caught");
    facts.add("external_time_rejected");
  } else {
    for (const factId of CHAPTER_FOUR_OPENING_FACT_ORDER) facts.add(factId);
  }

  if (["opening_handoff", "opening_paper_caught", "hall_clock_inspection"].includes(phase)) {
    for (const factId of CHAPTER_FOUR_BAKERY_FACT_ORDER) facts.delete(factId);
  } else if (CHAPTER_FOUR_POST_BAKERY_PHASES.has(phase)) {
    for (const factId of CHAPTER_FOUR_BAKERY_FACT_ORDER) facts.add(factId);
  } else if (phase === "bakery_hour_hand") {
    // A partially completed stop beat is a valid resumable save. Only causal
    // prerequisites are synthesized; the next handshake result remains open.
    facts.delete("hour_hand_installed");
    if (!facts.has("bakery_conveyor_lamp_inspected")) {
      facts.delete("bakery_hour_hand_exposed");
      facts.delete("bakery_hour_hand_collected");
      facts.delete("hour_hand_installed");
    }
  }

  return [
    ...CHAPTER_FOUR_OPENING_FACT_ORDER.filter((factId) => facts.delete(factId)),
    ...CHAPTER_FOUR_BAKERY_FACT_ORDER.filter((factId) => facts.delete(factId)),
    ...savedFactIds.filter((factId) => facts.delete(factId)),
    ...facts
  ];
}

function normalizeChapterFour(
  value: unknown,
  initial: GameState["chapter4"],
  envelopeVersion: number
): ChapterFourNormalizationResult {
  const saved = asRecord(value);
  if (envelopeVersion < SAVE_VERSION) {
    const savedPhase = typeof saved.phase === "string" ? saved.phase : "inactive";
    const completed = saved.completed === true || savedPhase === "complete";
    const started = completed
      || saved.prologueSeen === true
      || (LEGACY_CHAPTER_FOUR_PHASES.has(savedPhase) && savedPhase !== "inactive")
      || (Array.isArray(saved.solvedPuzzleIds)
        && saved.solvedPuzzleIds.some((puzzleId) => LEGACY_CHAPTER_FOUR_PUZZLE_IDS.has(
          puzzleId as GameState["chapter4"]["solvedPuzzleIds"][number]
        )))
      || (Array.isArray(saved.clueIds) && saved.clueIds.length > 0);
    if (completed) {
      return {
        state: createExteriorClosureWaitingChapterFourState(initial),
        migrationKind: "legacy_complete"
      };
    }
    return {
      state: createOpeningChapterFourState(initial, started),
      migrationKind: started ? "legacy_in_progress" : "legacy_not_started"
    };
  }

  const savedFactIds = filteredStringArrayFromSet(
    saved.factIds,
    VALID_CHAPTER_FOUR_FACT_IDS,
    []
  );
  const savedCardAccepted = saved.checkinCardAccepted === true
    && savedFactIds.includes("checkin_card_accepted");
  const savedPaperAccepted = saved.checkinPaperAccepted === true
    && savedFactIds.includes("checkin_paper_accepted");
  const savedCompleted = saved.completed === true || saved.phase === "complete";
  const savedPhase = enumOr(saved.phase, VALID_CHAPTER_FOUR_PHASES, "opening_handoff");
  let phase: ChapterFourPhase = savedCompleted
    || savedPhase === "complete"
    || (savedPhase === "exterior_closure" && saved.exteriorClosureAcknowledged === true)
      ? "exterior_closure"
      : savedPhase;
  if (phase === "morning_checkin" && savedCardAccepted && savedPaperAccepted) {
    phase = "exterior_closure";
  }
  // A formal exterior consumer reference and completed runtime session are not
  // persisted yet. Bare phase/boolean/fact fields therefore cannot hydrate a
  // completed Chapter 4 state.
  const completed = false;
  const time = CHAPTER_FOUR_TIME_BY_PHASE[phase];
  const timeAuthority = [
    "opening_handoff",
    "opening_paper_caught",
    "hall_clock_inspection"
  ].includes(phase) ? "external_evidence" : "hall_clock";
  const location = normalizeChapterFour755Location(
    phase,
    nullableEnumOr(saved.floor, VALID_CHAPTER_FOUR_FLOORS, null),
    typeof saved.roomId === "string"
      ? migrateChapterFourRoomId(saved.roomId.trim())
      : ""
  );
  let factIds = normalizeChapterFourFactClosure(phase, savedFactIds);
  let room204Placements = normalizeChapterFourRoom204Placements(saved.room204Placements);
  const room204Closure = normalizeChapterFourRoom204Closure(
    phase,
    factIds,
    room204Placements
  );
  factIds = room204Closure.factIds;
  room204Placements = room204Closure.placements;
  factIds = normalizeChapterFourMaintenanceClosure(phase, factIds);
  factIds = normalizeChapterFourMinuteTheftClosure(phase, factIds);
  factIds = normalizeChapterFourFinalMinuteClosure(phase, factIds);
  const checkinClosure = normalizeChapterFourCheckinClosure(
    phase,
    factIds,
    savedCardAccepted,
    savedPaperAccepted
  );
  factIds = checkinClosure.factIds;
  const lightGridSaved = asRecord(saved.lightGrid);
  const lightGridMustBeLocked = [
    "final_chase",
    "final_minute_recovery",
    "return_to_clock",
    "morning_checkin",
    "exterior_closure",
    "complete"
  ].includes(phase);
  const lightGridMask = lightGridMustBeLocked
    ? 13
    : phase === "blackout_light_grid"
      ? rangedIntegerOr(lightGridSaved.mask, 0, 31, 6)
      : 6;
  const checkinCardAccepted = checkinClosure.checkinCardAccepted;
  const checkinPaperAccepted = checkinClosure.checkinPaperAccepted;
  const prologueSeen = phase === "opening_handoff"
    ? booleanOr(saved.prologueSeen, initial.prologueSeen)
    : true;

  return {
    state: {
      prologueSeen,
      phase,
      mode: enumOr(saved.mode, VALID_CHAPTER_FOUR_MODES, initial.mode),
      building: "A",
      floor: location.floor,
      roomId: location.roomId,
      timeAuthority,
      timeState: time.timeState,
      worldTimeSeconds: time.worldTimeSeconds,
      phoneStatusTimeSeconds: time.phoneStatusTimeSeconds,
      phoneStatusTimeTrusted: time.phoneStatusTimeTrusted,
      factIds,
      room204Placements,
      lightGrid: {
        mask: lightGridMask,
        locked: lightGridMustBeLocked
      },
      guardMode: phase === "maintenance_repair" ? "patrol" : phase === "final_chase" ? "chase" : "absent",
      chaseAttempt: nonNegativeSafeIntegerOr(saved.chaseAttempt, initial.chaseAttempt),
      chaseRestartCheckpoint: phase === "final_chase" ? "c4_a1_lobby" : null,
      checkinCardAccepted,
      checkinPaperAccepted,
      exteriorClosureAcknowledged: false,
      completed,
      ...createEmptyLegacyChapterFourControllerFields(time.worldTimeSeconds)
    },
    migrationKind: "none"
  };
}

function createOpeningChapterFourState(
  initial: GameState["chapter4"],
  prologueSeen: boolean
): GameState["chapter4"] {
  return {
    ...initial,
    prologueSeen,
    phase: "opening_handoff",
    mode: "light",
    building: "A",
    floor: "A1",
    roomId: "a1_lobby",
    timeAuthority: "external_evidence",
    timeState: "2245_opening",
    worldTimeSeconds: 81900,
    phoneStatusTimeSeconds: 28523,
    phoneStatusTimeTrusted: false,
    factIds: [],
    room204Placements: [],
    lightGrid: { mask: 6, locked: false },
    guardMode: "absent",
    chaseAttempt: 0,
    chaseRestartCheckpoint: null,
    checkinCardAccepted: false,
    checkinPaperAccepted: false,
    exteriorClosureAcknowledged: false,
    completed: false,
    ...createEmptyLegacyChapterFourControllerFields(81900)
  };
}

function createExteriorClosureWaitingChapterFourState(
  initial: GameState["chapter4"]
): GameState["chapter4"] {
  return {
    ...initial,
    prologueSeen: true,
    phase: "exterior_closure",
    mode: "light",
    building: "A",
    floor: "A1",
    roomId: "a1_exterior",
    timeAuthority: "hall_clock",
    timeState: "0755_morning",
    worldTimeSeconds: 28500,
    phoneStatusTimeSeconds: 28500,
    phoneStatusTimeTrusted: true,
    factIds: [...CHAPTER_FOUR_EXTERIOR_WAITING_FACT_IDS],
    room204Placements: createCanonicalCompleteRoom204Placements(),
    lightGrid: { mask: 13, locked: true },
    guardMode: "absent",
    chaseAttempt: 0,
    chaseRestartCheckpoint: null,
    checkinCardAccepted: true,
    checkinPaperAccepted: true,
    exteriorClosureAcknowledged: false,
    completed: false,
    ...createEmptyLegacyChapterFourControllerFields(28500)
  };
}

function createEmptyLegacyChapterFourControllerFields(
  buildingTimeSeconds: number
): Pick<
  GameState["chapter4"],
  | "cycle"
  | "buildingTimeSeconds"
  | "airflowObserved"
  | "paperGuidedToElevator"
  | "elevatorHistoryObserved"
  | "elevatorSelectedStartSeconds"
  | "elevatorTrackAligned"
  | "elevatorReplayAttempts"
  | "elevatorPlayerBoarded"
  | "stairEchoObserved"
  | "stairRotationQuarterTurns"
  | "stairAlignmentSolved"
  | "solvedPuzzleIds"
  | "clueIds"
  | "anchor"
  | "echoRecorded"
  | "resetCount"
  | "finalCode"
> {
  return {
    cycle: 1,
    buildingTimeSeconds,
    airflowObserved: false,
    paperGuidedToElevator: false,
    elevatorHistoryObserved: false,
    elevatorSelectedStartSeconds: null,
    elevatorTrackAligned: false,
    elevatorReplayAttempts: 0,
    elevatorPlayerBoarded: false,
    stairEchoObserved: false,
    stairRotationQuarterTurns: 0,
    stairAlignmentSolved: false,
    solvedPuzzleIds: [],
    clueIds: [],
    anchor: null,
    echoRecorded: false,
    resetCount: 0,
    finalCode: null
  };
}

function normalizeChapterFour755Location(
  phase: ChapterFourPhase,
  savedFloor: ChapterFour755FloorId | null,
  savedRoomId: string
): { floor: ChapterFour755FloorId; roomId: string } {
  if (phase === "opening_handoff") {
    return { floor: "A1", roomId: "a1_lobby" };
  }
  if (phase === "room204_restore") {
    const floor = savedFloor === "A3" ? "A3" : "A2";
    const roomIds = floor === "A3"
      ? new Set(["a3_reference_classroom", "a3_wayfinding"])
      : new Set(["a2_corridor", "a2_room204", "a2_room_204"]);
    return {
      floor,
      roomId: roomIds.has(savedRoomId)
        ? savedRoomId
        : floor === "A3" ? "a3_wayfinding" : "a2_corridor"
    };
  }
  if (phase === "maintenance_repair") {
    const roomIds = new Set([
      "a1_lobby",
      "a1_hall_clock",
      "a1_bakery",
      "a1_cleaning_cart"
    ]);
    return {
      floor: "A1",
      roomId: roomIds.has(savedRoomId) ? savedRoomId : "a1_lobby"
    };
  }
  if (phase === "final_chase") {
    // A save never resumes inside a half-applied inter-floor chase. Runtime
    // guard/portal state is intentionally discarded and the chase restarts at
    // its authored A1 safe point with the same persistent attempt counter.
    return { floor: "A1", roomId: "a1_lobby" };
  }
  if (phase === "final_minute_recovery") {
    return { floor: "A2", roomId: "a2_room_202" };
  }
  if (phase === "return_to_clock") {
    if (savedFloor === "A2") {
      return {
        floor: "A2",
        roomId: savedRoomId === "a2_corridor" ? "a2_corridor" : "a2_room_202"
      };
    }
    return {
      floor: "A1",
      roomId: savedRoomId === "a1_hall_clock" ? "a1_hall_clock" : "a1_lobby"
    };
  }
  if (phase === "morning_checkin") {
    return { floor: "A1", roomId: "a1_checkin" };
  }
  if (phase === "exterior_closure" || phase === "complete") {
    return { floor: "A1", roomId: "a1_exterior" };
  }
  return { floor: "A1", roomId: savedRoomId || "a1_lobby" };
}

function migrateChapterFourRoomId(roomId: string): string {
  return roomId === "a2_lecture_202" ? "a2_room_202" : roomId;
}

function normalizeChapterFourRoom204Placements(value: unknown): ChapterFourRoom204Placement[] {
  return normalizeRoom204Placements(value);
}

function normalizeChapterFourRoom204Closure(
  phase: ChapterFourPhase,
  savedFactIds: readonly ChapterFourFactId[],
  savedPlacements: readonly ChapterFourRoom204Placement[]
): { factIds: ChapterFourFactId[]; placements: ChapterFourRoom204Placement[] } {
  const facts = new Set(savedFactIds);
  let placements = normalizeRoom204Placements(savedPlacements);
  const room204Started = phase === "room204_restore";
  const postRoom204 = CHAPTER_FOUR_POST_ROOM204_PHASES.has(phase);

  if (!room204Started && !postRoom204) {
    for (const factId of CHAPTER_FOUR_ROOM204_FACT_ORDER) facts.delete(factId);
    placements = [];
  } else if (postRoom204) {
    if (!isRoom204PlacementSetComplete(placements)) {
      placements = createCanonicalCompleteRoom204Placements();
    }
    for (const factId of CHAPTER_FOUR_ROOM204_FACT_ORDER) facts.add(factId);
  } else {
    const hasBothObservations = facts.has("a3_reference_observed")
      && facts.has("room204_residual_observed");
    const complete = isRoom204PlacementSetComplete(placements);
    if (complete && hasBothObservations) facts.add("room204_restored");
    else facts.delete("room204_restored");

    if (!facts.has("room204_restored")) facts.delete("room204_projection_completed");
    if (!facts.has("room204_projection_completed")) facts.delete("positioning_plate_collected");
    // Installing the positioning plate always performs the atomic transition
    // to maintenance_repair, so this fact cannot remain inside room204_restore.
    facts.delete("positioning_plate_installed");
  }

  return {
    factIds: [
      ...savedFactIds.filter((factId) => !CHAPTER_FOUR_ROOM204_FACT_ORDER.includes(
        factId as (typeof CHAPTER_FOUR_ROOM204_FACT_ORDER)[number]
      ) && facts.delete(factId)),
      ...CHAPTER_FOUR_ROOM204_FACT_ORDER.filter((factId) => facts.delete(factId)),
      ...facts
    ],
    placements
  };
}

function normalizeChapterFourMaintenanceClosure(
  phase: ChapterFourPhase,
  savedFactIds: readonly ChapterFourFactId[]
): ChapterFourFactId[] {
  const facts = new Set(savedFactIds);
  if (phase === "maintenance_repair") {
    if (facts.has("clock_gear_repaired")) facts.add("cart_wheel_repaired");
    if (facts.has("cart_wheel_repaired")) facts.add("cart_wheel_cover_opened");
    if (facts.has("cart_wheel_cover_opened")) facts.add("cart_wheel_inspected");
  } else if (CHAPTER_FOUR_POST_MAINTENANCE_PHASES.has(phase)) {
    for (const factId of CHAPTER_FOUR_MAINTENANCE_FACT_ORDER) facts.add(factId);
  } else {
    for (const factId of CHAPTER_FOUR_MAINTENANCE_FACT_ORDER) facts.delete(factId);
  }
  return [
    ...savedFactIds.filter((factId) => !CHAPTER_FOUR_MAINTENANCE_FACT_ORDER.includes(
      factId as (typeof CHAPTER_FOUR_MAINTENANCE_FACT_ORDER)[number]
    ) && facts.delete(factId)),
    ...CHAPTER_FOUR_MAINTENANCE_FACT_ORDER.filter((factId) => facts.delete(factId)),
    ...facts
  ];
}

function normalizeChapterFourMinuteTheftClosure(
  phase: ChapterFourPhase,
  savedFactIds: readonly ChapterFourFactId[]
): ChapterFourFactId[] {
  const facts = new Set(savedFactIds);
  if (CHAPTER_FOUR_POST_MINUTE_THEFT_PHASES.has(phase)) {
    facts.add("paper_temporarily_out_of_inventory");
  } else {
    facts.delete("paper_temporarily_out_of_inventory");
  }
  if (CHAPTER_FOUR_POST_LIGHT_GRID_PHASES.has(phase)) {
    facts.add("light_grid_locked");
  } else {
    facts.delete("light_grid_locked");
  }
  const normalizedFactOrder = [
    "paper_temporarily_out_of_inventory",
    "light_grid_locked"
  ] as const satisfies readonly ChapterFourFactId[];
  return [
    ...savedFactIds.filter((factId) => !normalizedFactOrder.includes(
      factId as (typeof normalizedFactOrder)[number]
    ) && facts.delete(factId)),
    ...normalizedFactOrder.filter((factId) => facts.delete(factId)),
    ...facts
  ];
}

function normalizeChapterFourFinalMinuteClosure(
  phase: ChapterFourPhase,
  savedFactIds: readonly ChapterFourFactId[]
): ChapterFourFactId[] {
  const facts = new Set(savedFactIds);
  if (phase === "return_to_clock") {
    facts.add("final_minute_recovered");
    facts.delete("final_minute_installed");
  } else if (["morning_checkin", "exterior_closure", "complete"].includes(phase)) {
    facts.add("final_minute_recovered");
    facts.add("final_minute_installed");
  } else {
    facts.delete("final_minute_recovered");
    facts.delete("final_minute_installed");
  }
  const normalizedFactOrder = [
    "final_minute_recovered",
    "final_minute_installed"
  ] as const satisfies readonly ChapterFourFactId[];
  return [
    ...savedFactIds.filter((factId) => !normalizedFactOrder.includes(
      factId as (typeof normalizedFactOrder)[number]
    ) && facts.delete(factId)),
    ...normalizedFactOrder.filter((factId) => facts.delete(factId)),
    ...facts
  ];
}

function normalizeChapterFourCheckinClosure(
  phase: ChapterFourPhase,
  savedFactIds: readonly ChapterFourFactId[],
  savedCardAccepted: boolean,
  savedPaperAccepted: boolean
): {
  factIds: ChapterFourFactId[];
  checkinCardAccepted: boolean;
  checkinPaperAccepted: boolean;
} {
  const facts = new Set(savedFactIds);
  const checkinFinished = phase === "exterior_closure" || phase === "complete";
  const checkinAvailable = phase === "morning_checkin";
  const checkinCardAccepted = checkinFinished || (checkinAvailable && savedCardAccepted);
  const checkinPaperAccepted = checkinFinished || (checkinAvailable && savedPaperAccepted);
  facts.delete("checkin_card_accepted");
  facts.delete("checkin_paper_accepted");
  facts.delete("exterior_closure_acknowledged");
  if (checkinCardAccepted) facts.add("checkin_card_accepted");
  if (checkinPaperAccepted) facts.add("checkin_paper_accepted");
  const normalizedFactOrder = [
    "checkin_card_accepted",
    "checkin_paper_accepted"
  ] as const satisfies readonly ChapterFourFactId[];
  return {
    factIds: [
      ...savedFactIds.filter((factId) => !normalizedFactOrder.includes(
        factId as (typeof normalizedFactOrder)[number]
      ) && factId !== "exterior_closure_acknowledged" && facts.delete(factId)),
      ...normalizedFactOrder.filter((factId) => facts.delete(factId)),
      ...facts
    ],
    checkinCardAccepted,
    checkinPaperAccepted
  };
}

function normalizeChapterThreeInterlude(
  value: unknown,
  initial: GameState["chapterThreeInterlude"],
  qizhenLake: GameState["qizhenLake"],
  chapter4: GameState["chapter4"]
): GameState["chapterThreeInterlude"] {
  const saved = asRecord(value);
  const chapterFourStarted = chapter4.prologueSeen || chapter4.completed;
  const migratedPhase: GameState["chapterThreeInterlude"]["phase"] = chapterFourStarted
    ? "complete"
    : qizhenLake.phase === "complete"
      ? "reboot"
      : "inactive";
  const phase = enumOr(saved.phase, VALID_CHAPTER_THREE_INTERLUDE_PHASES, migratedPhase);
  const completed = chapterFourStarted || booleanOr(saved.completed, phase === "complete");
  const replayUnlocked = chapterFourStarted || completed || booleanOr(saved.replayUnlocked, initial.replayUnlocked);
  const destinationId = saved.destinationId === "duan_yongping_a1"
    ? "duan_yongping_a1"
    : chapterFourStarted
      ? "duan_yongping_a1"
      : null;
  return {
    phase: completed ? "complete" : phase,
    rebootSeen: booleanOr(saved.rebootSeen, chapterFourStarted),
    recoveryOpened: booleanOr(saved.recoveryOpened, chapterFourStarted),
    photoFrameIds: filteredStringArrayFromSet(
      saved.photoFrameIds,
      VALID_CHAPTER_THREE_INTERLUDE_PHOTOS,
      chapterFourStarted ? ["paper_left", "paper_middle", "paper_right"] : initial.photoFrameIds
    ),
    photoSequenceSolved: booleanOr(saved.photoSequenceSolved, chapterFourStarted),
    voiceClipOrder: filteredStringArrayFromSet(
      saved.voiceClipOrder,
      VALID_CHAPTER_THREE_INTERLUDE_VOICES,
      chapterFourStarted ? ["lake", "stone", "lobby", "broadcast"] : initial.voiceClipOrder
    ),
    voiceSequenceSolved: booleanOr(saved.voiceSequenceSolved, chapterFourStarted),
    officialNoticeSaved: booleanOr(saved.officialNoticeSaved, chapterFourStarted),
    routeScreenshotSaved: booleanOr(saved.routeScreenshotSaved, chapterFourStarted),
    networkRecordRead: booleanOr(saved.networkRecordRead, chapterFourStarted),
    evidenceIds: filteredStringArrayFromSet(
      saved.evidenceIds,
      VALID_CHAPTER_THREE_INTERLUDE_EVIDENCE,
      chapterFourStarted
        ? ["journal_start", "photo_direction", "network_destination", "broadcast_end"]
        : initial.evidenceIds
    ),
    timelineOrder: filteredStringArrayFromSet(
      saved.timelineOrder,
      VALID_CHAPTER_THREE_INTERLUDE_EVIDENCE,
      chapterFourStarted
        ? ["journal_start", "photo_direction", "network_destination", "broadcast_end"]
        : initial.timelineOrder
    ),
    rejectedDecoyIds: filteredStringArrayFromSet(
      saved.rejectedDecoyIds,
      VALID_CHAPTER_THREE_INTERLUDE_DECOYS,
      chapterFourStarted ? ["canteen_0755", "theater_0832", "status_clock_075523"] : initial.rejectedDecoyIds
    ),
    statusClockMarkedUntrusted: booleanOr(saved.statusClockMarkedUntrusted, chapterFourStarted),
    destinationId,
    windowStartSeconds: rangedIntegerOr(saved.windowStartSeconds, 0, 86399, initial.windowStartSeconds),
    windowEndSeconds: rangedIntegerOr(saved.windowEndSeconds, 0, 86399, initial.windowEndSeconds),
    replayUnlocked,
    completed
  };
}

function normalizeChapterFourCheckpoint(
  checkpoint: GameState["rpgCheckpoint"],
  chapter: GameState["chapter4"]
): GameState["rpgCheckpoint"] {
  if (chapter.phase === "final_chase") return "c4_a1_lobby";
  if (chapter.phase === "final_minute_recovery") return "c4_a2_room202";
  if (chapter.phase === "return_to_clock" && chapter.floor === "A2") {
    const expected = chapter.roomId === "a2_room_202" ? "c4_a2_room202" : "c4_a2_corridor";
    return checkpoint === expected ? checkpoint : expected;
  }
  const expected = chapter.floor === "A1"
    ? "c4_a1_lobby"
    : chapter.floor === "A2"
      ? "c4_a2_corridor"
      : "c4_a3_wayfinding";
  return checkpoint === expected ? checkpoint : expected;
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

  const normalizedStateForRemoval = { actOne, ui: { libraryFinalsPuzzle: puzzle } };

  return {
    controlCenterOpen: booleanOr(saved.controlCenterOpen, initial.controlCenterOpen),
    autoRotate: booleanOr(saved.autoRotate, initial.autoRotate),
    musicPlaying: booleanOr(saved.musicPlaying, initial.musicPlaying),
    musicMuted: booleanOr(saved.musicMuted, initial.musicMuted),
    brightness: rangedNumberOr(saved.brightness, 0, 100, initial.brightness),
    homeAppOrder: normalizePhoneHomeAppOrder(saved.homeAppOrder),
    hiddenHomeAppIds: normalizeHiddenPhoneHomeAppIds(saved.hiddenHomeAppIds, normalizedStateForRemoval),
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

function normalizeChapterFourItems(
  items: GameState["items"],
  chapter4: GameState["chapter4"],
  migrationKind: ChapterFourMigrationKind
): void {
  const chapterFourItemIds = [
    "attendanceRecordPaper",
    "oldClockHourHand",
    "clockPositioningPlate",
    "shortPryBar",
    "universalLubricatingOil",
    "finalMinute"
  ] as const;
  const savedItems = Object.fromEntries(
    chapterFourItemIds.map((itemId) => [itemId, items[itemId]])
  ) as Record<(typeof chapterFourItemIds)[number], boolean>;
  for (const itemId of chapterFourItemIds) items[itemId] = false;

  if (migrationKind === "legacy_complete") {
    items.attendanceRecordPaper = true;
    items.campusCard = true;
    return;
  }
  if (migrationKind !== "none") return;

  const phase = chapter4.phase as ChapterFourPhase;
  if (!VALID_CHAPTER_FOUR_PHASES.has(phase)) return;
  const factIds = new Set(chapter4.factIds);
  const hasFact = (factId: ChapterFourFactId) => factIds.has(factId);
  const finalMinuteRecovered = hasFact("final_minute_recovered")
    || hasFact("final_minute_installed");

  if ([
    "opening_paper_caught",
    "hall_clock_inspection",
    "bakery_hour_hand",
    "room204_restore",
    "maintenance_repair"
  ].includes(phase)) {
    items.attendanceRecordPaper = true;
  } else if (phase === "opening_handoff") {
    items.attendanceRecordPaper = hasFact("opening_paper_caught");
  } else if (phase === "blackout_light_grid") {
    items.attendanceRecordPaper = false;
  } else if (phase === "final_chase") {
    items.attendanceRecordPaper = false;
  } else if (phase === "final_minute_recovery") {
    items.attendanceRecordPaper = finalMinuteRecovered;
  } else if (["return_to_clock", "morning_checkin", "exterior_closure", "complete"].includes(phase)) {
    items.attendanceRecordPaper = true;
  }
  if (["return_to_clock", "morning_checkin", "exterior_closure", "complete"].includes(phase)) {
    items.campusCard = true;
  }

  if (phase === "bakery_hour_hand" && !hasFact("hour_hand_installed")) {
    // The item and its controller-owned collection fact are one persisted
    // transaction. A stale item bit without the fact is discarded; a valid
    // collected fact restores the held item after reload.
    items.oldClockHourHand = hasFact("bakery_hour_hand_collected");
  }
  if (phase === "room204_restore" && !hasFact("positioning_plate_installed")) {
    // The grant fact and held item are one controller transaction. Restore a
    // missing item bit from the fact and discard a stale item without it.
    items.clockPositioningPlate = hasFact("positioning_plate_collected");
  }
  if (phase === "maintenance_repair") {
    const cartWheelCoverOpened = hasFact("cart_wheel_cover_opened")
      || hasFact("cart_wheel_repaired")
      || hasFact("clock_gear_repaired");
    const cartWheelRepaired = hasFact("cart_wheel_repaired")
      || hasFact("clock_gear_repaired");
    items.shortPryBar = savedItems.shortPryBar
      && !cartWheelCoverOpened;
    items.universalLubricatingOil = cartWheelCoverOpened
      && !hasFact("clock_gear_repaired")
      && (savedItems.universalLubricatingOil || cartWheelRepaired);
  }
  if (phase === "final_minute_recovery" && !hasFact("final_minute_installed")) {
    items.finalMinute = finalMinuteRecovered;
  }
  if (phase === "return_to_clock" && !hasFact("final_minute_installed")) {
    items.finalMinute = true;
  }
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
