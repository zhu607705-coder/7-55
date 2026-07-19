export type RuntimeMode = "phone" | "rpg";

export type ChapterId = "chapter_one" | "chapter_two" | "chapter_three";

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
  hints: [string, string, string];
  targetSurface: "phone" | "rpg";
  recommendedScene?: SceneId;
}

export interface StoryLine {
  kind: "dialogue" | "taunt" | "task";
  speaker?: "narrator" | "system" | "player" | "seat022";
  voiceRole?: "male_narrator" | "female_system";
  voiceTextEn?: string;
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

export type RpgSceneId = "campus_bootstrap" | "dorm_hub" | "library_interior";

export type RpgCheckpointId =
  | "campus_library_gate"
  | "library_entrance"
  | "library_seat_022"
  | "library_front_desk"
  | "library_shelf_755";

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

export type NetworkMode = "campus_wifi" | "cellular" | "offline";

export type ThemeMode = "normal" | "dark" | "backside";

export type ZjudingPage =
  | "hub"
  | "login"
  | "directory"
  | "learn"
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
  recoverySubmittedEvidenceIds: LibraryRecoveryEvidenceId[];
  evictionPassGenerated: boolean;
  backpackEvicted: boolean;
  playerSeated: boolean;
  nextQuestId: "chapter_three_book_hunt" | null;
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
  | "seatReleasePass";

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
  bikeArcade: BikeArcadeChapterState;
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
