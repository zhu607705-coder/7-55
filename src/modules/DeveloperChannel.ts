import { createInitialGameState } from "../core/GameState";
import type {
  GameState,
  GameStore,
  LibraryFinalsPhase,
  SceneId,
  ZjudingPage
} from "../core/types";
import {
  DEVELOPER_ACTIVE_KEY,
  DEVELOPER_BACKUP_KEY,
  DEVELOPER_BIKE_START_KEY
} from "../core/StorageKeys";

export type DeveloperCheckpointId =
  | "c1-alarm" | "c1-home" | "c1-code-hunt" | "c1-dorm-card" | "c1-checkin"
  | "c2-friend" | "c2-system"
  | "c2-name" | "c2-exercise" | "c2-triangle" | "c2-weather-water"
  | "c2-mentor-line" | "c2-arrow-assembly" | "c2-balance-shift"
  | "c2-gamepad-market" | "c2-manual-movement" | "c2-dorm-exit"
  | "c2-library-gate" | "c2-entrance-record" | "c2-seat-arrival"
  | "c2-occupancy-note" | "c2-catalog" | "c2-archived-rule"
  | "c2-photo-report" | "c2-nonperson-stamp" | "c2-seat-receipt"
  | "c2-tiyi-proof" | "c2-cc98-upload" | "c2-bd-rise"
  | "c2-recovery-form" | "c2-pass-generate" | "c2-pass-apply"
  | "c2-seat-sit" | "c2-seat-dialogue" | "c2-chapter-exit"
  | "c3-intro" | "c3-congestion" | "c3-sprint" | "c3-result";

type LegacyDeveloperCheckpointId =
  | "c2-inventory" | "c2-system-return" | "c2-movement" | "c2-seat-022" | "c2-evidence"
  | "c2-top-ten" | "c2-recovery" | "c2-pass";

type DeveloperCheckpointRequestId = DeveloperCheckpointId | LegacyDeveloperCheckpointId;
type LibraryDeveloperCheckpointId = Extract<DeveloperCheckpointId, `c2-${string}`>;

export interface DeveloperCheckpoint {
  id: DeveloperCheckpointId;
  chapter: "第一章" | "第二章" | "第三章";
  label: string;
  detail: string;
}

export const DEVELOPER_CHECKPOINTS: DeveloperCheckpoint[] = [
  { id: "c1-alarm", chapter: "第一章", label: "闹钟开始", detail: "07:55 闹钟振动" },
  { id: "c1-home", chapter: "第一章", label: "手机主页", detail: "散码前" },
  { id: "c1-code-hunt", chapter: "第一章", label: "签到码散落", detail: "四条线索可探索" },
  { id: "c1-dorm-card", chapter: "第一章", label: "寝室校园卡", detail: "拾取右侧书桌校园卡后查看 ¥0.06 黄零" },
  { id: "c1-checkin", chapter: "第一章", label: "签到输入", detail: "0798 已集齐" },
  { id: "c2-friend", chapter: "第二章", label: "朋友追问", detail: "回复签到失败" },
  { id: "c2-system", chapter: "第二章", label: "系统红圈", detail: "浙大钉名字旁" },
  { id: "c2-name", chapter: "第二章", label: "人物命名", detail: "黄页填写身份" },
  { id: "c2-exercise", chapter: "第二章", label: "启动锻炼", detail: "体艺开始课外锻炼" },
  { id: "c2-triangle", chapter: "第二章", label: "取得三角形", detail: "主页任务推送" },
  { id: "c2-weather-water", chapter: "第二章", label: "取得天气水滴", detail: "天气页面" },
  { id: "c2-mentor-line", chapter: "第二章", label: "释放导师竖线", detail: "水滴拖到导师头像" },
  { id: "c2-arrow-assembly", chapter: "第二章", label: "合成右移箭头", detail: "三角形加竖线" },
  { id: "c2-balance-shift", chapter: "第二章", label: "移动余额小数点", detail: "0.06 变为 6.00" },
  { id: "c2-gamepad-market", chapter: "第二章", label: "购买游戏手柄", detail: "CC98 二手交易" },
  { id: "c2-manual-movement", chapter: "第二章", label: "首次手动移动", detail: "寝室方向控制" },
  { id: "c2-dorm-exit", chapter: "第二章", label: "离开寝室", detail: "出口已开放" },
  { id: "c2-library-gate", chapter: "第二章", label: "图书馆门口", detail: "校园地图入口" },
  { id: "c2-entrance-record", chapter: "第二章", label: "入馆记录", detail: "读取 07:55 记录" },
  { id: "c2-seat-arrival", chapter: "第二章", label: "到达 022", detail: "检查占座书包" },
  { id: "c2-occupancy-note", chapter: "第二章", label: "占座纸条", detail: "从书包取得线索" },
  { id: "c2-catalog", chapter: "第二章", label: "馆藏检索", detail: "搜索正确书籍" },
  { id: "c2-archived-rule", chapter: "第二章", label: "旧版规则", detail: "索书号拖到书架" },
  { id: "c2-photo-report", chapter: "第二章", label: "照片识别报告", detail: "调暗照片并生成报告" },
  { id: "c2-nonperson-stamp", chapter: "第二章", label: "非本人证明", detail: "报告拖到登记机" },
  { id: "c2-seat-receipt", chapter: "第二章", label: "022 座位小票", detail: "箭头拖到座位缝隙" },
  { id: "c2-tiyi-proof", chapter: "第二章", label: "本人来过证明", detail: "填写 7 / 47 / 3" },
  { id: "c2-cc98-upload", chapter: "第二章", label: "上传四项证据", detail: "CC98 调查帖" },
  { id: "c2-bd-rise", chapter: "第二章", label: "有效 bd", detail: "排名 04 升至 01" },
  { id: "c2-recovery-form", chapter: "第二章", label: "打开恢复申请", detail: "浙大钉材料页" },
  { id: "c2-pass-generate", chapter: "第二章", label: "生成 PASS", detail: "三项材料已提交" },
  { id: "c2-pass-apply", chapter: "第二章", label: "使用 PASS", detail: "拖到 022 书包" },
  { id: "c2-seat-sit", chapter: "第二章", label: "坐到 022", detail: "书包已清退" },
  { id: "c2-seat-dialogue", chapter: "第二章", label: "022 对话", detail: "联系异常意识" },
  { id: "c2-chapter-exit", chapter: "第二章", label: "第三章入口", detail: "求是潮应用已开放" },
  { id: "c3-intro", chapter: "第三章", label: "求是潮起点", detail: "0 米" },
  { id: "c3-congestion", chapter: "第三章", label: "拥堵阶段", detail: "377 米起跑" },
  { id: "c3-sprint", chapter: "第三章", label: "冲刺阶段", detail: "566 米起跑" },
  { id: "c3-result", chapter: "第三章", label: "755 结算", detail: "章节完成" }
];

const CHECKPOINT_IDS = new Set(DEVELOPER_CHECKPOINTS.map((checkpoint) => checkpoint.id));
const LEGACY_CHECKPOINT_ALIASES: Record<LegacyDeveloperCheckpointId, DeveloperCheckpointId> = {
  "c2-inventory": "c1-dorm-card",
  "c2-system-return": "c2-system",
  "c2-movement": "c2-name",
  "c2-seat-022": "c2-seat-arrival",
  "c2-evidence": "c2-catalog",
  "c2-top-ten": "c2-cc98-upload",
  "c2-recovery": "c2-recovery-form",
  "c2-pass": "c2-pass-apply"
};

const LIBRARY_CHECKPOINT_ORDER: readonly LibraryDeveloperCheckpointId[] = [
  "c2-library-gate",
  "c2-entrance-record",
  "c2-seat-arrival",
  "c2-occupancy-note",
  "c2-catalog",
  "c2-archived-rule",
  "c2-photo-report",
  "c2-nonperson-stamp",
  "c2-seat-receipt",
  "c2-tiyi-proof",
  "c2-cc98-upload",
  "c2-bd-rise",
  "c2-recovery-form",
  "c2-pass-generate",
  "c2-pass-apply",
  "c2-seat-sit",
  "c2-seat-dialogue",
  "c2-chapter-exit"
];

function resolveCheckpointId(value: string | null): DeveloperCheckpointId | null {
  if (!value) return null;
  if (CHECKPOINT_IDS.has(value as DeveloperCheckpointId)) return value as DeveloperCheckpointId;
  return LEGACY_CHECKPOINT_ALIASES[value as LegacyDeveloperCheckpointId] ?? null;
}

function createActTwoBase(phase: GameState["actOne"]["phase"]): GameState {
  const state = createInitialGameState();
  return {
    ...state,
    currentScene: "phone_home",
    digits: { d1: "0", d2: "7", d3: "9", d4: "8" },
    items: { ...state.items, campusCard: true },
    flags: {
      ...state.flags,
      codeScattered: true,
      cardZeroTaken: true,
      tiyiCountTaken: true,
      gearNineTaken: true,
      flowerEightTaken: true,
      checkinDone: true
    },
    actOne: {
      ...state.actOne,
      phase,
      inventoryRecovered: true,
      dormHubUnlocked: true
    },
    ui: { ...state.ui, zjudingPage: "hub" }
  };
}

function withMovementFacts(
  state: GameState,
  patch: Partial<GameState["actOne"]>,
  items: Partial<GameState["items"]> = {}
): GameState {
  const actOne = { ...state.actOne, ...patch };
  actOne.identityVerified = actOne.characterNamed;
  actOne.controlsInstalled = actOne.gamepadPurchased;
  actOne.movementEnabled = actOne.characterNamed && actOne.exerciseStarted && actOne.gamepadPurchased;
  return { ...state, actOne, items: { ...state.items, ...items } };
}

function createMovementCheckpointState(id: DeveloperCheckpointId): GameState {
  let state = withMovementFacts(createActTwoBase("movement_required"), {
    inventoryRecovered: true,
    characterPromptSeen: true
  }, { campusCard: true });

  if (id === "c2-name") {
    return { ...state, currentScene: "zjuding", ui: { ...state.ui, zjudingPage: "directory" } };
  }
  state = withMovementFacts(state, { characterNamed: true });
  if (id === "c2-exercise") return { ...state, currentScene: "tiyi" };
  state = withMovementFacts(state, { exerciseStarted: true });
  if (id === "c2-triangle") return state;
  state = withMovementFacts(state, { pushTriangleTaken: true }, { pushTriangle: true });
  if (id === "c2-weather-water") return { ...state, currentScene: "weather" };
  state = withMovementFacts(state, { weatherWaterTaken: true }, { weatherWater: true });
  if (id === "c2-mentor-line") {
    return {
      ...state,
      currentScene: "wechat",
      ui: { ...state.ui, inventoryOpen: true, selectedItem: "weatherWater" }
    };
  }
  state = withMovementFacts(state, { mentorLineReleased: true }, { weatherWater: false, mentorLine: true });
  if (id === "c2-arrow-assembly") {
    return { ...state, ui: { ...state.ui, inventoryOpen: true } };
  }
  state = withMovementFacts(state, { rightArrowAssembled: true }, {
    pushTriangle: false,
    mentorLine: false,
    rightArrow: true
  });
  if (id === "c2-balance-shift") {
    return {
      ...state,
      currentScene: "campus_card",
      ui: { ...state.ui, inventoryOpen: true, selectedItem: "rightArrow" }
    };
  }
  state = withMovementFacts(state, { balanceShifted: true });
  if (id === "c2-gamepad-market") return { ...state, currentScene: "cc98" };
  state = withMovementFacts(state, { gamepadPurchased: true }, { gamepad: true });
  if (id === "c2-manual-movement") {
    return { ...state, runtimeMode: "rpg", rpgScene: "dorm_hub" };
  }
  return {
    ...withMovementFacts(state, {
      phase: "movement_ready",
      manualControlTested: true,
      canLeaveDorm: true
    }),
    runtimeMode: "rpg",
    rpgScene: "dorm_hub"
  };
}

function createCompletedMovementState(): GameState {
  return withMovementFacts(createActTwoBase("complete"), {
    inventoryRecovered: true,
    characterPromptSeen: true,
    characterNamed: true,
    exerciseStarted: true,
    pushTriangleTaken: true,
    weatherWaterTaken: true,
    mentorLineReleased: true,
    rightArrowAssembled: true,
    balanceShifted: true,
    gamepadPurchased: true,
    manualControlTested: true,
    canLeaveDorm: true
  }, {
    campusCard: true,
    rightArrow: true,
    gamepad: true
  });
}

function libraryPhaseFor(id: LibraryDeveloperCheckpointId): LibraryFinalsPhase {
  if (id === "c2-library-gate") return "library_route_unlocked";
  if (id === "c2-entrance-record" || id === "c2-seat-arrival") return "library_entered";
  if (id === "c2-occupancy-note") return "occupied_seat_found";
  if (["c2-catalog", "c2-archived-rule", "c2-photo-report", "c2-nonperson-stamp", "c2-seat-receipt", "c2-tiyi-proof"].includes(id)) return "evidence_gathering";
  if (id === "c2-cc98-upload") return "bd_briefing";
  if (id === "c2-bd-rise") return "top_ten_rising";
  if (id === "c2-recovery-form") return "top_ten_reached";
  if (id === "c2-pass-generate") return "recovery_application";
  if (id === "c2-pass-apply") return "pass_ready";
  if (id === "c2-seat-sit") return "backpack_removed";
  if (id === "c2-seat-dialogue") return "seat_recovered";
  return "friend_contacted";
}

function createLibraryCheckpointState(id: LibraryDeveloperCheckpointId): GameState {
  let state = createCompletedMovementState();
  const stage = LIBRARY_CHECKPOINT_ORDER.indexOf(id);
  const reached = (checkpoint: LibraryDeveloperCheckpointId) => stage >= LIBRARY_CHECKPOINT_ORDER.indexOf(checkpoint);
  const puzzle = { ...state.ui.libraryFinalsPuzzle };
  const items = { ...state.items };

  if (reached("c2-entrance-record")) puzzle.libraryVisitedPoints = ["entrance"];
  if (reached("c2-seat-arrival")) {
    puzzle.entranceRecordRead = true;
    puzzle.libraryVisitedPoints = ["entrance", "seat_022"];
    puzzle.clueIds = ["arrival_7_minutes"];
  }
  if (reached("c2-occupancy-note")) puzzle.backpackInspected = true;
  if (reached("c2-catalog")) {
    puzzle.occupancyNoteCollected = true;
    puzzle.investigationOpened = true;
    puzzle.clueIds = [...puzzle.clueIds, "occupancy_note", "public_notice_floor_47"];
    items.occupancyNote = false;
  }
  if (reached("c2-archived-rule")) {
    puzzle.catalogSearchCompleted = true;
    puzzle.callNumberCollected = true;
    puzzle.clueIds = [...puzzle.clueIds, "call_number_755"];
    items.callNumber755 = true;
  }
  if (reached("c2-photo-report")) {
    puzzle.archivedRuleCollected = true;
    puzzle.libraryVisitedPoints = [...new Set([...puzzle.libraryVisitedPoints, "catalog_terminal", "shelf_755"])] as GameState["ui"]["libraryFinalsPuzzle"]["libraryVisitedPoints"];
    puzzle.clueIds = [...puzzle.clueIds, "archived_leave_rule"];
    items.callNumber755 = false;
    items.archivedLeaveRule = true;
  }
  if (reached("c2-nonperson-stamp")) {
    puzzle.photoDimmed = true;
    puzzle.itemReportGenerated = true;
    items.itemRecognitionReport = true;
  }
  if (reached("c2-seat-receipt")) {
    puzzle.nonPersonProofStamped = true;
    items.itemRecognitionReport = false;
    items.bagNonPersonProof = true;
  }
  if (reached("c2-tiyi-proof")) {
    puzzle.seatReceiptCollected = true;
    items.rightArrow = false;
    items.seat022Receipt = true;
  }
  if (reached("c2-cc98-upload")) {
    puzzle.auditAttemptCount = 1;
    puzzle.auditArrivalMinutes = 7;
    puzzle.auditPublicNoticeFloor = 47;
    puzzle.auditProofCount = 3;
    puzzle.presenceProofCollected = true;
    puzzle.cc98UploadedEvidenceIds = [
      "archived_leave_rule",
      "bag_non_person_proof",
      "seat_022_receipt",
      "library_presence_proof"
    ];
    items.archivedLeaveRule = false;
    items.libraryPresenceProof = true;
  }
  if (reached("c2-bd-rise")) {
    puzzle.bdCount = 0;
  }
  if (reached("c2-recovery-form")) {
    puzzle.bdCount = 3;
    puzzle.appliedBdReplyIds = ["reply-seat-ticket", "reply-visit-proof", "reply-bag-nonperson"];
  }
  if (reached("c2-pass-generate")) {
    puzzle.recoverySubmittedEvidenceIds = ["bag_non_person_proof", "seat_022_receipt", "library_presence_proof"];
    items.bagNonPersonProof = false;
    items.seat022Receipt = false;
    items.libraryPresenceProof = false;
  }
  if (reached("c2-pass-apply")) {
    puzzle.evictionPassGenerated = true;
    items.seatReleasePass = true;
  }
  if (reached("c2-seat-sit")) {
    puzzle.backpackEvicted = true;
    items.seatReleasePass = false;
  }
  if (reached("c2-seat-dialogue")) puzzle.playerSeated = true;
  if (reached("c2-chapter-exit")) {
    puzzle.nextQuestId = "chapter_three_book_hunt";
    puzzle.clueIds = [...puzzle.clueIds, "borrowed_attendance_record"];
  }

  const rpgCheckpoints: Partial<Record<LibraryDeveloperCheckpointId, GameState["rpgCheckpoint"]>> = {
    "c2-library-gate": "campus_library_gate",
    "c2-entrance-record": "library_entrance",
    "c2-seat-arrival": "library_seat_022",
    "c2-occupancy-note": "library_seat_022",
    "c2-archived-rule": "library_shelf_755",
    "c2-nonperson-stamp": "library_front_desk",
    "c2-seat-receipt": "library_seat_022",
    "c2-pass-apply": "library_seat_022",
    "c2-seat-sit": "library_seat_022",
    "c2-seat-dialogue": "library_seat_022"
  };
  const rpgCheckpoint = rpgCheckpoints[id];
  const runtimeMode = rpgCheckpoint ? "rpg" : "phone";
  const currentSceneByCheckpoint: Partial<Record<LibraryDeveloperCheckpointId, SceneId>> = {
    "c2-catalog": "zjuding",
    "c2-photo-report": "photos",
    "c2-tiyi-proof": "tiyi",
    "c2-cc98-upload": "cc98",
    "c2-bd-rise": "cc98",
    "c2-recovery-form": "zjuding",
    "c2-pass-generate": "zjuding",
    "c2-chapter-exit": "phone_home"
  };
  const zjudingPage: ZjudingPage = id === "c2-catalog"
    ? "library_catalog"
    : id === "c2-recovery-form" || id === "c2-pass-generate"
      ? "library_recovery"
      : "hub";

  state = {
    ...state,
    runtimeMode,
    rpgScene: id === "c2-library-gate" ? "campus_bootstrap" : rpgCheckpoint ? "library_interior" : state.rpgScene,
    rpgCheckpoint: rpgCheckpoint ?? state.rpgCheckpoint,
    currentScene: currentSceneByCheckpoint[id] ?? state.currentScene,
    items,
    bikeArcade: { ...state.bikeArcade, unlocked: reached("c2-chapter-exit") },
    ui: {
      ...state.ui,
      brightness: id === "c2-photo-report" ? 33 : state.ui.brightness,
      inventoryOpen: false,
      selectedItem: null,
      zjudingPage,
      librarySelectedSeat: reached("c2-library-gate") ? "022" : null,
      librarySeatReserved: reached("c2-library-gate"),
      libraryFinalsPhase: libraryPhaseFor(id),
      libraryFinalsPuzzle: puzzle
    }
  };
  return state;
}

export function createDeveloperCheckpointState(requestedId: DeveloperCheckpointRequestId): GameState {
  const id = resolveCheckpointId(requestedId) ?? "c1-alarm";
  const initial = createInitialGameState();
  if (id === "c1-alarm") return initial;
  if (id === "c1-home") return { ...initial, currentScene: "phone_home" };
  if (id === "c1-code-hunt") return { ...initial, currentScene: "phone_home", flags: { ...initial.flags, codeScattered: true } };
  if (id === "c1-dorm-card") {
    return {
      ...initial,
      runtimeMode: "rpg",
      rpgScene: "dorm_hub",
      flags: { ...initial.flags, codeScattered: true },
      actOne: { ...initial.actOne, dormHubUnlocked: true }
    };
  }
  if (id === "c1-checkin") {
    return {
      ...initial,
      currentScene: "checkin",
      digits: { d1: "0", d2: "7", d3: "9", d4: "8" },
      items: { ...initial.items, campusCard: true },
      flags: {
        ...initial.flags,
        codeScattered: true,
        cardZeroTaken: true,
        tiyiCountTaken: true,
        gearNineTaken: true,
        flowerEightTaken: true
      },
      actOne: { ...initial.actOne, inventoryRecovered: true }
    };
  }
  if (id === "c2-friend") return createActTwoBase("friend_message_required");
  if (id === "c2-system") return { ...createActTwoBase("system_required"), currentScene: "zjuding" };
  if ([
    "c2-name", "c2-exercise", "c2-triangle", "c2-weather-water", "c2-mentor-line",
    "c2-arrow-assembly", "c2-balance-shift", "c2-gamepad-market", "c2-manual-movement",
    "c2-dorm-exit"
  ].includes(id)) return createMovementCheckpointState(id);
  if (LIBRARY_CHECKPOINT_ORDER.includes(id as LibraryDeveloperCheckpointId)) {
    return createLibraryCheckpointState(id as LibraryDeveloperCheckpointId);
  }

  const state = createLibraryCheckpointState("c2-chapter-exit");
  return {
    ...state,
    runtimeMode: "phone",
    currentScene: id === "c3-result" ? "chapter_transition" : "bike_arcade",
    bikeArcade: {
      unlocked: true,
      completed: id === "c3-result",
      attemptCount: id === "c3-result" ? 1 : 0,
      bestDistance: id === "c3-result" ? 755 : 0,
      bestLives: id === "c3-result" ? 2 : 0
    }
  };
}

export function applyDeveloperCheckpoint(
  store: GameStore,
  requestedId: DeveloperCheckpointRequestId,
  storage: Storage = window.sessionStorage
): void {
  const id = resolveCheckpointId(requestedId);
  if (!id) return;
  if (!storage.getItem(DEVELOPER_BACKUP_KEY)) {
    storage.setItem(DEVELOPER_BACKUP_KEY, JSON.stringify(store.getState()));
  }
  storage.setItem(DEVELOPER_ACTIVE_KEY, id);
  storage.setItem(DEVELOPER_BIKE_START_KEY, id === "c3-congestion" ? "377" : id === "c3-sprint" ? "566" : "0");
  store.setState(() => createDeveloperCheckpointState(id));
}

export function restoreDeveloperBackup(store: GameStore, storage: Storage = window.sessionStorage): boolean {
  const raw = storage.getItem(DEVELOPER_BACKUP_KEY);
  if (!raw) return false;
  try {
    store.setState(() => JSON.parse(raw) as GameState);
  } catch {
    return false;
  }
  storage.removeItem(DEVELOPER_BACKUP_KEY);
  storage.removeItem(DEVELOPER_ACTIVE_KEY);
  storage.removeItem(DEVELOPER_BIKE_START_KEY);
  return true;
}

export function getDeveloperBikeStart(storage: Storage = window.sessionStorage): number {
  return Number(storage.getItem(DEVELOPER_BIKE_START_KEY) ?? 0) || 0;
}

export function getActiveDeveloperCheckpoint(storage: Storage = window.sessionStorage): DeveloperCheckpointId | null {
  return resolveCheckpointId(storage.getItem(DEVELOPER_ACTIVE_KEY));
}

export function getDeveloperCc98Mode(storage: Storage = window.sessionStorage): "exchange" | "investigation" | null {
  const checkpoint = getActiveDeveloperCheckpoint(storage);
  if (checkpoint === "c2-gamepad-market") return "exchange";
  if (checkpoint === "c2-cc98-upload" || checkpoint === "c2-bd-rise") return "investigation";
  return null;
}

function checkpointFromLegacyParams(params: URLSearchParams): DeveloperCheckpointId | null {
  const scene = params.get("scene") as SceneId | null;
  const page = params.get("zjudingPage") as ZjudingPage | null;
  const phase = params.get("libraryFinalsPhase") as LibraryFinalsPhase | null;
  if (phase === "library_route_unlocked") return "c2-library-gate";
  if (phase === "library_entered") return scene === "zjuding" ? "c2-catalog" : "c2-entrance-record";
  if (phase === "occupied_seat_found") return "c2-occupancy-note";
  if (phase === "evidence_gathering") {
    if (scene === "photos") return "c2-photo-report";
    if (scene === "tiyi") return "c2-tiyi-proof";
    if (scene === "cc98") return "c2-cc98-upload";
    if (page === "library_catalog") return "c2-catalog";
    return "c2-catalog";
  }
  if (phase === "bd_briefing") return "c2-cc98-upload";
  if (phase === "top_ten_rising") return "c2-bd-rise";
  if (phase === "top_ten_reached") return "c2-recovery-form";
  if (phase === "recovery_application") return "c2-pass-generate";
  if (phase === "pass_ready") return "c2-pass-apply";
  if (phase === "backpack_removed") return "c2-seat-sit";
  if (phase === "seat_recovered") return "c2-seat-dialogue";
  if (phase === "friend_contacted") return "c2-chapter-exit";
  if (scene === "bike_arcade") return "c3-intro";
  if (scene === "chapter_transition") return "c3-result";
  if (scene === "photos") return "c2-photo-report";
  if (scene === "tiyi") return "c2-exercise";
  if (scene === "cc98") return "c2-gamepad-market";
  if (scene === "zjuding") return page === "library_recovery" ? "c2-recovery-form" : page === "library_catalog" ? "c2-catalog" : "c2-system";
  if (scene === "phone_home") return "c1-code-hunt";
  return null;
}

export function applyDeveloperCheckpointFromUrl(
  store: GameStore,
  location: Location,
  storage: Storage = window.sessionStorage
): DeveloperCheckpointId | null {
  const params = new URLSearchParams(location.search);
  const requested = resolveCheckpointId(params.get("devCheckpoint")) ?? checkpointFromLegacyParams(params);
  if (requested) applyDeveloperCheckpoint(store, requested, storage);
  return requested;
}
