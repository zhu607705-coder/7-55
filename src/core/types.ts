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
  bikeArcade: boolean;
  clockCalibration: boolean;
}

export type QuestStepStatus = "completed" | "active" | "locked";

export interface QuestStep {
  id: string;
  label: string;
  status: QuestStepStatus;
  itemId?: ItemId;
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
}

export interface BikeArcadeChapterState {
  unlocked: boolean;
  completed: boolean;
  attemptCount: number;
  bestDistance: number;
  bestLives: number;
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

export type ChapterFourBuildingId = "A" | "B";
export type ChapterFourFloorId = "A1" | "A2" | "A3" | "A4" | "B2" | "B3";
export type ChapterFourCycle = 1 | 2;
export type ChapterFourStairRotation = 0 | 1 | 2 | 3;

export type ChapterFourPuzzleId =
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

export type ChapterFourPhase =
  | "inactive"
  | "arrival"
  | ChapterFourPuzzleId
  | "first_cycle_reset"
  | "complete";

export interface ChapterFourTemporalAnchor {
  floor: ChapterFourFloorId;
  roomId: string;
  timeSeconds: number;
}

/**
 * 第四章「段永平教学楼时间迷宫」的控制器事实。场景运行时只读取这些事实并
 * 提交领域意图；移动速度、动画帧、局部特效和临时输入不进入存档。
 */
export interface ChapterFourState {
  prologueSeen: boolean;
  phase: ChapterFourPhase;
  cycle: ChapterFourCycle;
  mode: ChapterFourRealityMode;
  building: ChapterFourBuildingId;
  floor: ChapterFourFloorId;
  roomId: string;
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
  solvedPuzzleIds: ChapterFourPuzzleId[];
  clueIds: string[];
  anchor: ChapterFourTemporalAnchor | null;
  echoRecorded: boolean;
  resetCount: number;
  finalCode: string | null;
  completed: boolean;
}

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
  | "fishingRod"
  | "rustedLockerKey"
  | "nylonCord"
  | "brokenNetFrame"
  | "improvisedDipNet"
  | "sealedFeedTin"
  | "fishFeedPellets"
  | "smallCarp"
  | "swanMagnet"
  | "magneticFishingRod";

export type SceneId =
  | "alarm"
  | "desktop"
  | "phone_home"
  | "wechat"
  | "cc98"
  | "zjuding"
  | "tiyi"
  | "weather"
  | "photos"
  | "campus_card"
  | "bike_arcade"
  | "chapter_transition"
  | "checkin"
  | "bonsai"
  | "clock"
  | "ending";

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
  items: Record<ItemId, boolean>;
  flags: GameFlags;
  actOne: ActOneBootstrapState;
  wallet: WalletState;
  bikeArcade: BikeArcadeChapterState;
  canteenHunt: CanteenHuntState;
  theaterHunt: TheaterHuntState;
  qizhenLake: QizhenLakeState;
  clockCalibration: ClockCalibrationState;
  chapter4: ChapterFourState;
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
