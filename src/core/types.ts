export type RuntimeMode = "phone" | "rpg";

export type ChapterId = "chapter_one" | "chapter_two" | "chapter_three" | "chapter_four";

export interface FeatureAccess {
  chapter: ChapterId;
  checkin: boolean;
  cc98: boolean;
  photos: boolean;
  departmentDirectory: boolean;
  weather: boolean;
  fullCampusMap: boolean;
  library: boolean;
  libraryReservation: boolean;
  libraryCatalog: boolean;
  cc98OwnerUpload: boolean;
  cc98Bd: boolean;
  libraryRecovery: boolean;
  timelineRecovery: boolean;
  voiceMemos: boolean;
  clockCalibration: boolean;
}

export type QuestStepStatus = "completed" | "active" | "locked";

export interface QuestStep {
  id: string;
  label: string;
  status: QuestStepStatus;
  itemId?: ItemId;
}

export interface QuestParallelBranch {
  id: string;
  label: string;
  detail?: string;
  status: "pending" | "completed";
  targetSurface?: "phone" | "rpg";
  recommendedScene?: SceneId;
}

/**
 * 第四章任务栏的只读展示上下文。字段全部由现有 ChapterFourState 派生，
 * 不参与存档，也不拥有章节推进规则。
 */
export interface ChapterFourQuestPresentationContext {
  stageLabel: string;
  timeStateLabel: string;
  phoneTime: string;
  timeSource: string;
  trustState: string;
  floor: string;
  currentDifference: string;
  localProgress: string;
  confirmedFacts: readonly string[];
}

export interface QuestViewModel {
  id: string;
  chapter: ChapterId;
  title: string;
  objective: string;
  completed: number;
  total: number;
  steps: QuestStep[];
  hints: readonly string[];
  targetSurface: "phone" | "rpg";
  recommendedScene?: SceneId;
  parallelBranches?: readonly QuestParallelBranch[];
  parallelProgress?: { completed: number; total: number };
  chapterFourPresentation?: ChapterFourQuestPresentationContext;
}

export interface StoryLine {
  kind: "dialogue" | "taunt" | "task";
  speaker?: "narrator" | "system" | "player" | "seat022" | "cleaner" | "guard";
  voiceRole?: "male_narrator" | "female_system" | "male_player" | "female_cleaner" | "male_guard";
  voiceTextEn?: string;
  voiceAsset?: string;
  subtitleZh: string;
}

export interface DocumentContent {
  heading: string;
  fields: Array<{ label: string; value: string }>;
  body: string[];
  footer?: string;
}

export interface ItemCatalogEntry {
  inspectKind: "object" | "paper";
  document?: DocumentContent;
  uses: Array<{ target: string; result: "retain" | "consume" | "transform" }>;
}

export type RpgSceneId =
  | "campus_bootstrap"
  | "campus_qizhen_loop"
  | "dorm_hub"
  | "library_interior"
  | "canteen_interior"
  | "theater_interior"
  | "qizhen_lake"
  | "duan_yongping_temporal_maze";

export type RpgCheckpointId =
  | "campus_spawn"
  | "campus_library_gate"
  | "campus_canteen_gate"
  | "campus_theater_junction"
  | "campus_qizhen_transition_stop"
  | "campus_qizhen_gate"
  | "dorm_spawn"
  | "canteen_entrance"
  | "theater_lobby"
  | "theater_auditorium"
  | "theater_stage"
  | "qizhen_reflection"
  | "qizhen_signs"
  | "qizhen_decoy"
  | "qizhen_mist"
  | "qizhen_dock"
  | "qizhen_open_water"
  | "qizhen_channel"
  | "qizhen_swan_cove"
  | "qizhen_chase"
  | "qizhen_complete"
  | "library_entrance"
  | "library_seat_022"
  | "library_front_desk"
  | "library_shelf_755"
  | "c4_a1_lobby"
  | "c4_a1_main_elevator"
  | "c4_a2_corridor"
  | "c4_a2_room202"
  | "c4_a3_wayfinding"
  | "c4_a3_skybridge"
  | "c4_b3_landing"
  | "c4_b2_activity"
  | "c4_b2_final_room";

export type ActOneBootstrapPhase =
  | "prologue"
  | "friend_message_required"
  | "system_required"
  | "inventory_required"
  | "system_return_required"
  | "reservation_briefing_required"
  | "reservation_required"
  | "movement_ready"
  // Legacy save values. SaveStore migrates these to movement_required.
  | "identity_required"
  | "phone_link_required"
  | "controls_required"
  | "movement_required"
  | "item_required"
  | "map_required"
  | "chapter_two_ready"
  | "complete";

export interface ActOneBootstrapState {
  phase: ActOneBootstrapPhase;
  identityVerified: boolean;
  phoneLinked: boolean;
  controlsInstalled: boolean;
  movementEnabled: boolean;
  inventoryRecovered: boolean;
  characterPromptSeen: boolean;
  characterNamed: boolean;
  exerciseStarted: boolean;
  pushTriangleTapCount: number;
  pushTriangleTaken: boolean;
  weatherWaterTaken: boolean;
  mentorLineReleased: boolean;
  rightArrowAssembled: boolean;
  balanceShifted: boolean;
  gamepadPurchased: boolean;
  manualControlTested: boolean;
  canLeaveDorm: boolean;
  requiredItemCollected: boolean;
  visitedAreaIds: string[];
  gameMenuUnlocked: boolean;
  dormHubUnlocked: boolean;
  cc98Login: Cc98UnifiedLoginState;
}

export interface Cc98UnifiedLoginState {
  studentIdDiscovered: boolean;
  revealedHintCount: number;
  failureCount: number;
  lockUntilMs: number | null;
  authenticated: boolean;
}

/**
 * Persistent player money. All amounts are stored as integer cents so story
 * transactions do not depend on formatted decimal strings.
 */
export interface WalletState {
  campusCardCents: number;
  cashCents: number;
}

export type CanteenHuntPhase =
  | "tracking"
  | "canteen_reached"
  // Legacy prototype value. SaveStore migrates it to tray_search.
  | "entered"
  | "tray_search"
  | "drink_mix"
  | "menu_order"
  | "pickup_search"
  | "exit_blocking"
  | "chase_ready"
  | "chasing"
  | "theater_reached";

export type CanteenMode = "light" | "dark";

export type CanteenExitId = "west" | "southeast" | "steam";

export type CanteenDrinkIngredientId = "sparklingWater" | "lemonTea" | "blackCoffee";

export type CanteenMenuOptionId = "A" | "B" | "C" | "D" | "E";

export interface CanteenHuntState {
  active: boolean;
  phase: CanteenHuntPhase;
  mode: CanteenMode;
  entryPaperEscaped: boolean;
  trayTaskStarted: boolean;
  carriedTrayIds: string[];
  identifiedTrayIds: string[];
  returnedTrayIds: string[];
  drinkShelfRead: boolean;
  drinkMixSequence: CanteenDrinkIngredientId[];
  drinkMixAttemptCount: number;
  queueChallengeSeen: boolean;
  promoDrinkPlaced: boolean;
  queueGapOpened: boolean;
  menuDarkClueRead: boolean;
  pickupTimeErrorSeen: boolean;
  pickupDarkClueRead: boolean;
  defenseDrinkUsed: boolean;
  orderedMenuOption: CanteenMenuOptionId | null;
  identifiedExitIds: CanteenExitId[];
  orderAttemptCount: number;
  pickupAttemptCount: number;
  blockHits: number;
  bikeCodeRead: boolean;
  bikeLockCleaned: boolean;
  bikePaid: boolean;
  chaseCompleted: boolean;
  chaseAttemptCount: number;
  chaseBestDistance: number;
  chaseBestLives: number;
  chaseCollisions: number;
}

export type TheaterHuntPhase =
  | "entry_ticket"
  | "program_search"
  | "prop_setup"
  | "spotlight_ready"
  | "spotlight_hunt"
  | "reversal"
  | "complete";

export type TheaterMode = "light" | "dark";

export type TheaterProgramId = "opening" | "spotlight" | "finale";

export type TheaterTicketCommissionPhase = "locked" | "posted" | "accepted" | "first_wave_failed" | "delivered";

export interface TheaterHuntState {
  active: boolean;
  phase: TheaterHuntPhase;
  mode: TheaterMode;
  cc98TicketCommissionPhase: TheaterTicketCommissionPhase;
  cc98TicketClaimedWave: 1 | 2 | null;
  posterCleaned: boolean;
  ticketCodeRead: boolean;
  ticketCodeAttempts: number;
  admitted: boolean;
  collectedProgramIds: TheaterProgramId[];
  programOrder: TheaterProgramId[];
  programWrongAttempts: number;
  propGhostRead: boolean;
  managerHintRead: boolean;
  propBoxOpened: boolean;
  paperDusted: boolean;
  spotlightRound: number;
  spotlightMistakes: number;
  decoyRevealed: boolean;
}

export type QizhenLakeMode = "light" | "dark";

export type QizhenLakePhase =
  | "inactive"
  | "location_search"
  | "lake_unlocked"
  | "dock_outfitting"
  | "boarding_tutorial"
  | "rain_recovery"
  | "lake_exploration"
  | "tool_chain"
  | "swan_exchange"
  | "paper_capture"
  | "swan_chase"
  | "complete";

export type QizhenLakeZone = "dock" | "open_water" | "channel" | "swan_cove";

export type QizhenLakeVehicle = "on_foot" | "kayak";

export type QizhenLakeSafeSpawnId =
  | "dock_entry"
  | "dock_kayak"
  | "open_water_entry"
  | "channel_entry"
  | "swan_cove_entry"
  | "channel_chase";

export type QizhenPaddleSide = "left" | "right";

export type QizhenPaddleDirection = "forward" | "reverse";

export type QizhenFishingSpotId = "locker_key" | "net_frame" | "paper" | "fish";

export type QizhenMapClueId = "bridge" | "reflection" | "lake";

export type QizhenDecoyTargetId = "notice" | "bridge" | "lamp";

export interface QizhenLakeState {
  active: boolean;
  phase: QizhenLakePhase;
  mode: QizhenLakeMode;
  zone: QizhenLakeZone;
  vehicle: QizhenLakeVehicle;
  safeSpawnId: QizhenLakeSafeSpawnId;
  locationBriefingSeen: boolean;
  bridgeClueFound: boolean;
  reflectionClueFound: boolean;
  lakeClueFound: boolean;
  mapClueIds: QizhenMapClueId[];
  introSeen: boolean;
  kayakEquipped: boolean;
  leftPaddleEquipped: boolean;
  rightPaddleEquipped: boolean;
  /** 值班老师已经明确劝阻雨天登船。 */
  rainWarningSeen: boolean;
  /** 玩家强行下水后已经落水获救并被送回寝室。 */
  rainRescueCompleted: boolean;
  /** 落水救援完成后，天气应用收到待处理的湖区记录。 */
  weatherAdjustmentRequested: boolean;
  /** 云层校准小游戏的累计开始次数。 */
  weatherControlAttempts: number;
  /** 云层校准的最少移动数，0 表示尚未完成。 */
  weatherControlBestMoves: number;
  /** 天气应用完成调控后才允许登船。 */
  rainSafetyCleared: boolean;
  boardingStrokeCount: number;
  boardingLastSide: QizhenPaddleSide | null;
  boardingTutorialCompleted: boolean;
  capsizeCount: number;
  rodFound: boolean;
  decoyBaitAttached: boolean;
  reflectionLocationObserved: boolean;
  observedFishingSpotIds: QizhenFishingSpotId[];
  directPaperCastFailures: number;
  lockerOpened: boolean;
  netCombined: boolean;
  feedTinRetrieved: boolean;
  feedTinOpened: boolean;
  fishCaught: boolean;
  swanFed: boolean;
  magneticRodCombined: boolean;
  paperCaptured: boolean;
  swanReleased: boolean;
  chaseDistance: number;
  chaseBestDistance: number;
  chaseAttempts: number;
  magneticAttachmentBroken: boolean;
  transitionReady: boolean;
  // Photo-journal record for the CC98 rowing thread. Kayak speed, roll, and
  // camera-open state stay runtime-only; only the journal facts below persist.
  journal: QizhenJournalState;
  dockCollisionCount: number;
  swanAlertLevel: number;
  // v13 compatibility fields. SaveStore reads them once when upgrading old
  // lake saves; the kayak runtime does not use them as progression authority.
  reflectionRound: number;
  reflectionMistakes: number;
  signRotations: [number, number, number];
  signsSolved: boolean;
  decoyPlacedAt: QizhenDecoyTargetId | null;
  decoyAttempts: number;
  mistRhythmRead: boolean;
  mistAttempts: number;
  paperReleased: boolean;
}

export type QizhenJournalStatus = "locked" | "capture_ready" | "main_draft" | "open" | "summary_ready" | "archived";
export type QizhenPhotoSpotId = "lake_center" | "dock" | "reflection" | "swan_cove";
// Photo tags recorded at capture time. "swan_aftermath" is the empty-enclosure
// shot after the swan has left; "composition_ok" only applies when both speed
// and roll are inside the thresholds in QizhenJournalModel.
export type QizhenPhotoTag =
  | "composition_ok"
  | "tilted"
  | "high_speed"
  | "ripple_clear"
  | "ripple_broken"
  | "swan_near"
  | "swan_far"
  | "swan_aftermath";
export interface QizhenPhotoRecipe {
  zone: QizhenLakeZone;
  cropCenterX: number; cropCenterY: number;
  zoomStep: 0 | 1 | 2;
  kayakX: number; kayakY: number;
  headingBucket: 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7;
  swanDistanceBucket?: "near" | "mid" | "far" | "gone";
  rippleClarityBucket?: "clear" | "partial" | "lost";
}
export interface QizhenPhotoRecord {
  id: string;
  spotId: QizhenPhotoSpotId;
  capturedAtSeconds: number;
  tags: QizhenPhotoTag[];
  recipe: QizhenPhotoRecipe;
}
export interface QizhenJournalDraft {
  id: string;
  kind: "main" | "spot";
  photo: QizhenPhotoRecord;
  titleId: string | null;   // main 用
  statusId: string | null;  // main 用
  captionId: string | null; // spot 用
}
export interface QizhenJournalState {
  status: QizhenJournalStatus;
  threadId: string;
  threadSeed: number;
  mainPhoto: QizhenPhotoRecord | null;
  optionalPhotos: Partial<Record<"dock" | "reflection" | "swan_cove", QizhenPhotoRecord>>;
  mainTitleId: string | null;
  mainStatusId: string | null;
  publishedSpotIds: QizhenPhotoSpotId[];
  pendingDraft: QizhenJournalDraft | null;
  summaryChoice: "safe_return" | "details_withheld" | null;
  summaryPublished: boolean;
  fishingAssistUnlocked: boolean;
  fishingAssistConsumed: boolean;
  memoryCardUnlocked: boolean;
}

export type ChapterThreeInterludePhase =
  | "inactive"
  | "reboot"
  | "journal_closeout"
  | "evidence_collection"
  | "timeline_assembly"
  | "destination_verified"
  | "replay_ready"
  | "complete";

export type ChapterThreeInterludeEvidenceId =
  | "journal_start"
  | "photo_direction"
  | "network_destination"
  | "broadcast_end";

export type ChapterThreeInterludeDecoyId =
  | "canteen_0755"
  | "theater_0832"
  | "status_clock_075523";

export type ChapterThreeInterludePhotoFrameId =
  | "paper_left"
  | "paper_middle"
  | "paper_right";

export type ChapterThreeInterludeVoiceClipId =
  | "lake"
  | "stone"
  | "lobby"
  | "broadcast";

export type ChapterThreeInterludeDestinationId = "duan_yongping_a1";

/**
 * 第三章半「未同步的七分五十五秒」。它不占用 ChapterId，只保存启真湖
 * 与第四章之间的手机取证事实；页面选中态、拖动位置和播放进度保持运行时状态。
 */
export interface ChapterThreeInterludeState {
  phase: ChapterThreeInterludePhase;
  rebootSeen: boolean;
  recoveryOpened: boolean;
  photoFrameIds: ChapterThreeInterludePhotoFrameId[];
  photoSequenceSolved: boolean;
  voiceClipOrder: ChapterThreeInterludeVoiceClipId[];
  voiceSequenceSolved: boolean;
  officialNoticeSaved: boolean;
  routeScreenshotSaved: boolean;
  networkRecordRead: boolean;
  networkRecordId:
    | "record_qizhen_dock"
    | "record_theater_hall"
    | "record_library_south"
    | "record_0755"
    | null;
  evidenceIds: ChapterThreeInterludeEvidenceId[];
  timelineOrder: ChapterThreeInterludeEvidenceId[];
  rejectedDecoyIds: ChapterThreeInterludeDecoyId[];
  statusClockMarkedUntrusted: boolean;
  destinationId: ChapterThreeInterludeDestinationId | null;
  windowStartSeconds: number;
  windowEndSeconds: number;
  replayUnlocked: boolean;
  completed: boolean;
}

export type ClockCalibrationPhase = "tampered" | "calibrating" | "release_ready" | "aligned";

/**
 * 校时页的四段可玩流程。`complete` 仅用于完成后的只读回执，不计入四个
 * DEV 试玩节点。
 */
export type ClockCalibrationStep =
  | "target_selection"
  | "coarse_time"
  | "seconds_trim"
  | "phase_lock"
  | "complete";

export type ClockArchiveClueId = "room_b2_04" | "schedule_0800" | "attendance_open";
export type ClockCoarseLockId = "hour" | "minute";
export type ClockDriftChannelId = "gate" | "elevator" | "room";

/**
 * 第四章「校时」：手机状态栏时间被系统篡改并冻结在 07:55:23。
 * 秒数按一天 86400 环绕计量；displayedSeconds 为当前显示，targetSeconds
 * 为校时目标 08:00:00，adjustCount 记录玩家调整次数。
 */
/** @deprecated Task 5 removes the legacy 08:00/B2-04 calibration controller state. */
export interface ClockCalibrationState {
  phase: ClockCalibrationPhase;
  step: ClockCalibrationStep;
  displayedSeconds: number;
  targetSeconds: number;
  selectedTargetSeconds: number | null;
  archiveClueIds: ClockArchiveClueId[];
  coarseLockIds: ClockCoarseLockId[];
  driftCorrectedChannelIds: ClockDriftChannelId[];
  driftAttempts: number;
  phaseLockHits: number;
  phaseLockAttempts: number;
  adjustCount: number;
}

/**
 * 第四章「时间迷宫」章节级事实。prologueSeen 记录「纸条进入段永平教学楼」
 * 序幕过场是否已看完（含跳过）；过场本身不改写任何第三章事实。
 */
export type ChapterFourRealityMode = "light" | "dark";

export type ChapterFourTimeAuthority = "external_evidence" | "hall_clock";
export type ChapterFourTimeState =
  | "2245_opening"
  | "1225_bakery"
  | "1850_evening"
  | "2245_maintenance"
  | "0754_blackout"
  | "0755_morning";
export type ChapterFourGuardMode = "absent" | "patrol" | "chase";
export type ChapterFour755BuildingId = "A";
export type ChapterFour755FloorId = "A1" | "A2" | "A3";
export type ChapterFourLightZoneId =
  | "hall"
  | "west_corridor"
  | "east_corridor"
  | "classroom_zone"
  | "bakery_back_area";
export type ChapterFourRoom204Orientation = "up" | "right" | "down" | "left";
export type ChapterFourRoom204PieceId =
  | "desk_pair_01"
  | "desk_pair_02"
  | "desk_pair_03"
  | "desk_pair_04"
  | "desk_pair_05"
  | "desk_pair_06"
  | "desk_pair_07"
  | "desk_pair_08"
  | "desk_pair_09"
  | "desk_pair_10"
  | "desk_pair_11"
  | "desk_pair_12";
export type ChapterFourRoom204SlotId =
  | "morning_slot_01"
  | "morning_slot_02"
  | "morning_slot_03"
  | "morning_slot_04"
  | "morning_slot_05"
  | "morning_slot_06"
  | "morning_slot_07"
  | "morning_slot_08"
  | "morning_slot_09"
  | "morning_slot_10"
  | "morning_slot_11"
  | "morning_slot_12";
export type ChapterFourRoom204GroupId =
  | "window_time_marks"
  | "central_drag_marks"
  | "podium_projection_edge"
  | "door_paper_trace";

export interface ChapterFourLightGridState {
  mask: number;
  locked: boolean;
}

export interface ChapterFourRoom204Placement {
  pieceId: ChapterFourRoom204PieceId;
  slotId: ChapterFourRoom204SlotId;
  orientation: ChapterFourRoom204Orientation;
}

export type ChapterFourFactId =
  | "opening_paper_at_noticeboard"
  | "opening_paper_caught"
  | "external_time_rejected"
  | "hall_clock_inspected"
  | "bakery_conveyor_lamp_inspected"
  | "bakery_conveyor_direction_observed"
  | "bakery_tool_location_observed"
  | "bakery_hour_hand_exposed"
  | "bakery_hour_hand_collected"
  | "hour_hand_installed"
  | "classroom_104_chalk_residual_observed"
  | "classroom_105_terminal_replay_checked"
  | "elevator_history_observed"
  | "elevator_history_calibrated"
  | "a1_time_route_compared"
  | "elevator_a2_call_record_observed"
  | "elevator_a3_arrival_record_observed"
  | "elevator_stop_chain_reconstructed"
  | "a1_duty_board_reconstructed"
  | "a3_archive_film_retrieved"
  | "a3_media_alignment_completed"
  | "a3_reference_observed"
  | "a3_identity_context_observed"
  | "zhu_two_questions_answered"
  | "misaligned_stair_solved"
  | "room204_residual_observed"
  | "room204_restored"
  | "room204_projection_completed"
  | "room204_projection_composite_completed"
  | "room202_endpoint_inferred"
  | "maintenance_incident_linked"
  | "positioning_plate_collected"
  | "a2_positioning_plate_calibrated"
  | "positioning_plate_installed"
  | "a2_power_topology_recovered"
  | "a2_evacuation_route_confirmed"
  | "cart_wheel_inspected"
  | "cart_wheel_cover_opened"
  | "cart_wheel_repaired"
  | "clock_gear_repaired"
  | "paper_temporarily_out_of_inventory"
  | "light_grid_locked"
  | "powered_route_confirmed"
  | "canruo_star_lamp_primed"
  | "room202_route_reached"
  | "final_minute_recovered"
  | "attendance_record_recovered"
  | "final_minute_installed"
  | "checkin_card_accepted"
  | "checkin_paper_accepted"
  | "checkin_identity_verified"
  | "exterior_closure_acknowledged";

export type ChapterFourZhuPurposeAnswerId =
  | "seek_truth"
  | "solve_real_problems"
  | "serve_public";

export type ChapterFourZhuPersonAnswerId =
  | "responsible"
  | "clear_minded"
  | "public_service";

export interface ChapterFourZhuQuestionAnswers {
  purpose: ChapterFourZhuPurposeAnswerId | null;
  person: ChapterFourZhuPersonAnswerId | null;
}

export type ChapterFourPhase =
  | "opening_handoff"
  | "opening_paper_caught"
  | "hall_clock_inspection"
  | "bakery_hour_hand"
  | "room204_restore"
  | "maintenance_repair"
  | "blackout_light_grid"
  | "final_chase"
  | "final_minute_recovery"
  | "return_to_clock"
  | "morning_checkin"
  | "exterior_closure"
  | "complete";

export interface ChapterFourState {
  prologueSeen: boolean;
  phase: ChapterFourPhase;
  mode: ChapterFourRealityMode;
  building: ChapterFour755BuildingId;
  floor: ChapterFour755FloorId;
  roomId: string;
  timeAuthority: ChapterFourTimeAuthority;
  timeState: ChapterFourTimeState;
  worldTimeSeconds: number;
  phoneStatusTimeSeconds: number;
  phoneStatusTimeTrusted: boolean;
  factIds: ChapterFourFactId[];
  zhuQuestionAnswers: ChapterFourZhuQuestionAnswers;
  room204Placements: ChapterFourRoom204Placement[];
  lightGrid: ChapterFourLightGridState;
  guardMode: ChapterFourGuardMode;
  chaseAttempt: number;
  chaseRestartCheckpoint: RpgCheckpointId | null;
  checkinCardAccepted: boolean;
  checkinPaperAccepted: boolean;
  exteriorClosureAcknowledged: boolean;
  completed: boolean;
}

/**
 * v24 及更早存档、旧控制器和旧 DEV 节点使用的阶段。它们不属于当前
 * ChapterFourPhase，也不能由 v25 SaveStore 恢复为活动剧情。
 */
export type LegacyChapterFourPuzzleId =
  | "airflow_overlay"
  | "elevator_track_sync"
  | "npc_schedule_route"
  | "corridor_bay_reconstruction"
  | "wayfinding_fragment_board"
  | "bridge_floor_discrimination"
  | "stair_echo_direction"
  | "multicam_video_edit"
  | "echo_action_record"
  | "dual_lift_logistics"
  | "warm_air_balance"
  | "route_schedule"
  | "clock_phase_lock";

export type LegacyChapterFourPhase =
  | "inactive"
  | "arrival"
  | LegacyChapterFourPuzzleId
  | "first_cycle_reset"
  | "complete";

export type LegacyChapterFourFloorId = "A4" | "B2" | "B3";

/** @deprecated Task 5 removes imports of this compatibility floor alias. */
export type ChapterFourFloorId = ChapterFour755FloorId | LegacyChapterFourFloorId;
/** @deprecated Task 5 removes the B-building controller path. */
export type ChapterFourBuildingId = ChapterFour755BuildingId | "B";
/** @deprecated Task 5 removes the old two-cycle route. */
export type ChapterFourCycle = 1 | 2;
/** @deprecated Task 5 removes the required stair-alignment route. */
export type ChapterFourStairRotation = 0 | 1 | 2 | 3;

export interface ChapterFourTemporalAnchor {
  floor: ChapterFourFloorId;
  roomId: string;
  timeSeconds: number;
}

/**
 * 仅为 Task 5 尚未改写的控制器保留。SaveStore v25 会把这些字段清空，
 * 新鲜状态和迁移状态都只使用 ChapterFourState 的 7:55 主线字段。
 */
export interface LegacyChapterFourControllerFields {
  cycle: ChapterFourCycle;
  buildingTimeSeconds: number;
  airflowObserved: boolean;
  paperGuidedToElevator: boolean;
  elevatorHistoryObserved: boolean;
  elevatorSelectedStartSeconds: number | null;
  elevatorTrackAligned: boolean;
  elevatorReplayAttempts: number;
  elevatorPlayerBoarded: boolean;
  stairEchoObserved: boolean;
  stairRotationQuarterTurns: ChapterFourStairRotation;
  stairAlignmentSolved: boolean;
  solvedPuzzleIds: LegacyChapterFourPuzzleId[];
  clueIds: string[];
  anchor: ChapterFourTemporalAnchor | null;
  echoRecorded: boolean;
  resetCount: number;
  finalCode: string | null;
}

/**
 * 临时编译边界：Task 5 改写旧控制器后，GameState.chapter4 应直接恢复为
 * ChapterFourState，并删除这个类型。运行时初始化和 v25 水合均不会产生
 * LegacyChapterFourPhase、B 楼或旧谜题事实。
 */
export type ChapterFourRuntimeCompatibilityState =
  & Omit<ChapterFourState, "phase" | "building" | "floor">
  & {
    phase: ChapterFourPhase | LegacyChapterFourPhase;
    building: ChapterFourBuildingId;
    floor: ChapterFourFloorId;
  }
  & LegacyChapterFourControllerFields;

export type NetworkMode = "campus_wifi" | "cellular" | "offline";

export type ThemeMode = "normal" | "dark" | "backside";

export type ZjudingPage =
  | "hub"
  | "login"
  | "directory"
  | "learn"
  | "campus_map"
  | "library"
  | "library_spaces"
  | "library_seat"
  | "library_catalog"
  | "library_recovery";

export type LibraryLocationId =
  | "entrance"
  | "seat_022"
  | "front_desk"
  | "lost_found"
  | "catalog_terminal"
  | "printer"
  | "shelf_755";

export type LibraryEvidenceId =
  | "archived_leave_rule"
  | "bag_non_person_proof"
  | "seat_022_receipt"
  | "library_presence_proof";

export type LibraryRecoveryEvidenceId = Exclude<LibraryEvidenceId, "archived_leave_rule">;

export type LibraryFinalsBdReplyId =
  | "reply-seat-ticket"
  | "reply-visit-proof"
  | "reply-bag-nonperson";

export type LibraryFinalsBdPostId =
  | "bd-notice-tens"
  | "bd-rule-count"
  | "bd-rank-first"
  | "bd-identity-zero"
  | "bd-call-number-tail"
  | "bd-seat-tail"
  | "bd-reply-count"
  | "bd-arrival-minutes";

export type LostFoundStage = "missing_report" | "ready" | "scanning" | "stamped";

export interface LibraryFinalsAuditValues {
  arrivalMinutes: number;
  publicNoticeFloor: number;
  proofCount: number;
}

export type LibraryFinalsPhase =
  | "idle"
  | "library_route_unlocked"
  | "library_entered"
  | "occupied_seat_found"
  | "evidence_gathering"
  | "bd_briefing"
  | "top_ten_rising"
  | "top_ten_reached"
  | "recovery_application"
  | "pass_ready"
  | "backpack_removed"
  | "seat_recovered"
  | "friend_contacted";

export interface LibraryFinalsPuzzleState {
  libraryVisitedPoints: LibraryLocationId[];
  entranceRecordRead: boolean;
  backpackInspected: boolean;
  occupancyNoteCollected: boolean;
  investigationOpened: boolean;
  optionalAc01Floors: number[];
  catalogSearchCompleted: boolean;
  catalogUnlocked: boolean;
  callNumberCollected: boolean;
  archivedRuleCollected: boolean;
  archivedRuleRead: boolean;
  archivedRuleBriefingSeen: boolean;
  frontDeskProofRequestSeen: boolean;
  photoCaptured: boolean;
  photoDimmed: boolean;
  itemReportGenerated: boolean;
  lostFoundStage: LostFoundStage;
  nonPersonProofStamped: boolean;
  seatReceiptCollected: boolean;
  auditAttemptCount: number;
  auditArrivalMinutes: number;
  auditPublicNoticeFloor: number;
  auditProofCount: number;
  presenceProofCollected: boolean;
  cc98UploadedEvidenceIds: LibraryEvidenceId[];
  preBdBriefingSeen: boolean;
  bdCount: 0 | 1 | 2 | 3;
  appliedBdReplyIds: LibraryFinalsBdReplyId[];
  bdSelectedPostIds: LibraryFinalsBdPostId[];
  bdPasswordAttemptCount: number;
  recoverySubmittedEvidenceIds: LibraryRecoveryEvidenceId[];
  evictionPassGenerated: boolean;
  passBriefingSeen: boolean;
  backpackEvicted: boolean;
  playerSeated: boolean;
  nextQuestId: "chapter_three_canteen_hunt" | null;
  clueIds: string[];
}

export type DigitIndex = "d1" | "d2" | "d3" | "d4";

export type DigitValue = "0" | "7" | "9" | "8";

export type ItemId =
  | "waterDrop"
  | "headphone"
  | "wateredHeadphone"
  | "reverseGear"
  | "slashLine"
  | "towerKey"
  | "fertilizer"
  | "campusCard"
  | "pushTriangle"
  | "weatherWater"
  | "mentorLine"
  | "rightArrow"
  | "gamepad"
  | "occupancyNote"
  | "callNumber755"
  | "archivedLeaveRule"
  | "itemRecognitionReport"
  | "bagNonPersonProof"
  | "seat022Receipt"
  | "libraryPresenceProof"
  | "seatReleasePass"
  | "cafeteriaWages"
  | "greaseTissue"
  | "sparklingWater"
  | "lemonTea"
  | "blackCoffee"
  | "badDrink"
  | "dailySpecialSparklingWater"
  | "pickupTicket0755"
  | "canteenRealBun"
  | "canteenCluelessSoyMilk"
  | "canteenEdgeEgg"
  | "canteenUselessCongee"
  | "theaterTicketHalfA"
  | "theaterTicketHalfB"
  | "temporaryTheaterTicket"
  | "theaterProgramOpening"
  | "theaterProgramSpotlight"
  | "theaterProgramFinale"
  | "spotlightRemote"
  | "fluorescentBrush"
  | "decoyPaper"
  | "wetProgram"
  | "bridgeKeyword"
  | "reflectionKeyword"
  | "lakeKeyword"
  | "reflectionCoordinate"
  | "hairDryer"
  | "fishingRod"
  | "rustedLockerKey"
  | "nylonCord"
  | "brokenNetFrame"
  | "improvisedDipNet"
  | "sealedFeedTin"
  | "fishFeedPellets"
  | "smallCarp"
  | "swanMagnet"
  | "magneticFishingRod"
  | "attendanceRecordPaper"
  | "oldClockHourHand"
  | "clockPositioningPlate"
  | "shortPryBar"
  | "universalLubricatingOil"
  | "finalMinute";

export type ChapterFourItemId =
  | "attendanceRecordPaper"
  | "oldClockHourHand"
  | "clockPositioningPlate"
  | "shortPryBar"
  | "universalLubricatingOil"
  | "finalMinute";

export type InventoryItemId = ItemId | ChapterFourItemId;

export type SceneId =
  | "alarm"
  | "desktop"
  | "phone_home"
  | "settings"
  | "wechat"
  | "cc98"
  | "zjuding"
  | "tiyi"
  | "weather"
  | "photos"
  | "timeline_recovery"
  | "voice_memos"
  | "campus_card"
  | "checkin"
  | "bonsai"
  | "clock"
  | "ending";

export type PhoneHomeAppId =
  | "wechat"
  | "tiyi"
  | "zjuding"
  | "settings"
  | "photos"
  | "timeline_recovery"
  | "voice_memos"
  | "cc98"
  | "control_center"
  | "clock";

export interface GameFlags {
  /** 小影已散码，任务"找回四位签到码"开始，物品栏解锁 */
  codeScattered: boolean;
  /** 校园卡余额页黄色 0 已被点击 */
  cardZeroTaken: boolean;
  /** 浙大体艺在校园网下的闪退次数 */
  tiyiCrashCount: number;
  /** 体艺 47 已点击 */
  tiyiCountTaken: boolean;
  /** 主屏设置齿轮已转 180° 掉落，背面朝外 */
  gearFallen: boolean;
  /** 齿轮背面 9 已收集 */
  gearNineTaken: boolean;
  /** 控制中心耳机图标已掉落并收入物品栏 */
  headphoneFallen: boolean;
  /** 天气组件水滴已收集 */
  waterDropTaken: boolean;
  /** 朋友头像斜线一端已掉落挂在框上 */
  slashHalfDropped: boolean;
  /** 剩余一端已点击次数（3 次后掉落） */
  slashTapCount: number;
  /** 斜线已完整掉落收入物品栏 */
  slashTaken: boolean;
  /** 盆栽提示"它绝对不会开花"已展示过 */
  bonsaiHintShown: boolean;
  /** 钥匙已插入塔楼旋转 90°，获得肥料 */
  towerOpened: boolean;
  /** 盆栽三个平行步骤 */
  plantWatered: boolean;
  plantLit: boolean;
  plantFertilized: boolean;
  /** 花已开，数字 8 已吐出被点击 */
  flowerBloomed: boolean;
  flowerEightTaken: boolean;
  /** 签到已提交成功（进入红闪结局） */
  checkinDone: boolean;
}

/** 手机系统层 UI 状态（控制中心开关等） */
export interface UiState {
  controlCenterOpen: boolean;
  autoRotate: boolean;
  musicPlaying: boolean;
  /** 全局背景音乐静音；不影响语音和操作音效。 */
  musicMuted: boolean;
  /** 0-100 */
  brightness: number;
  /** 手机桌面图标顺序。读取旧存档时会补齐新应用并过滤未知 id。 */
  homeAppOrder: PhoneHomeAppId[];
  /** 仅记录玩家从桌面删除的可选应用。剧情应用不会进入此列表。 */
  hiddenHomeAppIds: PhoneHomeAppId[];
  /** 物品栏是否展开 */
  inventoryOpen: boolean;
  /** 物品栏中当前选中的道具（用于对场景目标使用） */
  selectedItem: ItemId | null;
  /** 浙大钉内部页面，供返回链与自动化验收读取 */
  zjudingPage: ZjudingPage;
  /** 图书馆选座当前选中的座位号 */
  librarySelectedSeat: string | null;
  /** 当前选座是否已确认预约 */
  librarySeatReserved: boolean;
  /** 图书馆期末周关卡阶段，跨图书馆、校园卡、体艺和 CC98 共用 */
  libraryFinalsPhase: LibraryFinalsPhase;
  /** 图书馆期末周关卡的细粒度解谜状态 */
  libraryFinalsPuzzle: LibraryFinalsPuzzleState;
  /** 章节卡是否已由玩家确认；只影响提示显示，不参与功能解锁。 */
  seenChapterIntros: ChapterId[];
}

export interface GameState {
  runtimeMode: RuntimeMode;
  rpgScene: RpgSceneId;
  rpgCheckpoint: RpgCheckpointId;
  currentScene: SceneId;
  networkMode: NetworkMode;
  themeMode: ThemeMode;
  digits: Record<DigitIndex, DigitValue | null>;
  items: Record<InventoryItemId, boolean>;
  flags: GameFlags;
  actOne: ActOneBootstrapState;
  wallet: WalletState;
  canteenHunt: CanteenHuntState;
  theaterHunt: TheaterHuntState;
  qizhenLake: QizhenLakeState;
  chapterThreeInterlude: ChapterThreeInterludeState;
  /** Legacy controller compatibility only; the active Chapter 4 contract lives in chapter4. */
  clockCalibration: ClockCalibrationState;
  /** Temporary Task 5 compatibility boundary; persisted v25 data is ChapterFourState-shaped. */
  chapter4: ChapterFourRuntimeCompatibilityState;
  ui: UiState;
}

export type GameStore = {
  getState: () => GameState;
  subscribe: (listener: () => void) => () => void;
  setState: (updater: (state: GameState) => GameState) => void;
};

export interface GameEvent {
  name: string;
  payload?: Record<string, unknown>;
}
