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
  | "c1-alarm" | "c1-home" | "c1-code-hunt" | "c1-dorm-card" | "c1-checkin" | "c1-narrator-block"
  | "c2-friend" | "c2-system" | "c2-inventory" | "c2-system-return"
  | "c2-name" | "c2-exercise" | "c2-triangle" | "c2-weather-water"
  | "c2-mentor-line" | "c2-arrow-assembly" | "c2-balance-shift"
  | "c2-gamepad-market" | "c2-manual-movement" | "c2-reservation-briefing"
  | "c2-seat-reservation" | "c2-dorm-exit"
  | "c2-library-gate" | "c2-entrance-record" | "c2-seat-arrival"
  | "c2-occupancy-note" | "c2-catalog" | "c2-archived-rule"
  | "c2-photo-report" | "c2-nonperson-stamp" | "c2-seat-receipt"
  | "c2-tiyi-proof" | "c2-cc98-upload" | "c2-bd-rise"
  | "c2-recovery-form" | "c2-pass-generate" | "c2-pass-apply"
  | "c2-seat-sit" | "c2-seat-dialogue" | "c2-chapter-exit"
  | "campus-canteen-entry"
  | "canteen-hunt" | "c3-canteen-entry" | "c3-canteen-menu" | "c3-canteen-pickup"
  | "c3-canteen-block" | "c3-canteen-block-2" | "c3-canteen-block-3"
  | "c3-canteen-bike" | "c3-canteen-chase" | "c3-canteen-theater"
  | "c3-theater-entry" | "c3-theater-code" | "c3-theater-program"
  | "c3-theater-prop" | "c3-theater-spotlight" | "c3-theater-spotlight-round" | "c3-theater-complete"
  | "c3-qizhen-location" | "c3-qizhen-map" | "c3-qizhen-gate"
  | "c3-qizhen-reflection" | "c3-qizhen-signs" | "c3-qizhen-decoy"
  | "c3-qizhen-mist" | "c3-qizhen-release";

type LegacyDeveloperCheckpointId =
  | "c2-movement" | "c2-seat-022" | "c2-evidence"
  | "c2-top-ten" | "c2-recovery" | "c2-pass"
  | "c3-intro" | "c3-congestion" | "c3-sprint" | "c3-result";

type DeveloperCheckpointRequestId = DeveloperCheckpointId | LegacyDeveloperCheckpointId;
type LibraryDeveloperCheckpointId = Extract<DeveloperCheckpointId, `c2-${string}`>;
type CanteenDeveloperCheckpointId = Extract<DeveloperCheckpointId, "canteen-hunt" | `c3-canteen-${string}`>;
type TheaterDeveloperCheckpointId = Extract<DeveloperCheckpointId, `c3-theater-${string}`>;
type QizhenDeveloperCheckpointId = Extract<DeveloperCheckpointId, `c3-qizhen-${string}`>;

export interface DeveloperCheckpoint {
  id: DeveloperCheckpointId;
  chapter: "第一章" | "第二章" | "第三章" | "寻人篇";
  label: string;
  detail: string;
}

export const DEVELOPER_CHECKPOINTS: DeveloperCheckpoint[] = [
  { id: "c1-alarm", chapter: "第一章", label: "闹钟开始", detail: "07:55 闹钟振动" },
  { id: "c1-home", chapter: "第一章", label: "手机主页", detail: "散码前" },
  { id: "c1-code-hunt", chapter: "第一章", label: "签到码散落", detail: "四条线索可探索" },
  { id: "c1-dorm-card", chapter: "第一章", label: "签到页数字", detail: "本周缺勤次数中的 0" },
  { id: "c1-checkin", chapter: "第一章", label: "签到输入", detail: "0798 已集齐" },
  { id: "c1-narrator-block", chapter: "第一章", label: "错误框拦截", detail: "挡住三次后按住旁白" },
  { id: "c2-friend", chapter: "第二章", label: "朋友追问", detail: "回复签到失败" },
  { id: "c2-system", chapter: "第二章", label: "系统红圈", detail: "浙大钉名字旁" },
  { id: "c2-inventory", chapter: "第二章", label: "取得校园卡", detail: "寝室右侧个人书桌" },
  { id: "c2-system-return", chapter: "第二章", label: "校园卡首显", detail: "取得后自动放大" },
  { id: "c2-name", chapter: "第二章", label: "人物命名", detail: "黄页填写身份" },
  { id: "c2-exercise", chapter: "第二章", label: "启动锻炼", detail: "体艺开始课外锻炼" },
  { id: "c2-triangle", chapter: "第二章", label: "取得三角形", detail: "主页任务推送" },
  { id: "c2-weather-water", chapter: "第二章", label: "取得天气水滴", detail: "天气页面" },
  { id: "c2-mentor-line", chapter: "第二章", label: "释放导师竖线", detail: "水滴拖到导师头像" },
  { id: "c2-arrow-assembly", chapter: "第二章", label: "合成右移箭头", detail: "三角形加竖线" },
  { id: "c2-balance-shift", chapter: "第二章", label: "移动余额小数点", detail: "0.06 变为 6.00" },
  { id: "c2-gamepad-market", chapter: "第二章", label: "购买游戏手柄", detail: "CC98 二手交易" },
  { id: "c2-manual-movement", chapter: "第二章", label: "首次手动移动", detail: "寝室方向控制" },
  { id: "c2-reservation-briefing", chapter: "第二章", label: "系统预约说明", detail: "首次移动后的三句说明" },
  { id: "c2-seat-reservation", chapter: "第二章", label: "预约 022", detail: "基础馆二层南区" },
  { id: "c2-dorm-exit", chapter: "第二章", label: "离开寝室", detail: "出口已开放" },
  { id: "c2-library-gate", chapter: "第二章", label: "图书馆门口", detail: "校园地图入口" },
  { id: "c2-entrance-record", chapter: "第二章", label: "入馆记录", detail: "点击小屏核对两条时间" },
  { id: "c2-seat-arrival", chapter: "第二章", label: "到达 022", detail: "检查占座书包" },
  { id: "c2-occupancy-note", chapter: "第二章", label: "占座纸条", detail: "从书包取得线索" },
  { id: "c2-catalog", chapter: "第二章", label: "馆藏检索", detail: "搜索正确书籍" },
  { id: "c2-archived-rule", chapter: "第二章", label: "旧版规则", detail: "索书号拖到书架" },
  { id: "c2-photo-report", chapter: "第二章", label: "照片识别报告", detail: "调暗照片并生成报告" },
  { id: "c2-nonperson-stamp", chapter: "第二章", label: "非本人证明", detail: "报告拖到登记机" },
  { id: "c2-seat-receipt", chapter: "第二章", label: "022 座位小票", detail: "箭头拖到座位缝隙" },
  { id: "c2-tiyi-proof", chapter: "第二章", label: "本人来过证明", detail: "填写 7 / 47 / 3" },
  { id: "c2-cc98-upload", chapter: "第二章", label: "上传四项证据", detail: "CC98 调查帖" },
  { id: "c2-bd-rise", chapter: "第二章", label: "BD 四位口令", detail: "数字回复推到排名 01" },
  { id: "c2-recovery-form", chapter: "第二章", label: "打开恢复申请", detail: "浙大钉材料页" },
  { id: "c2-pass-generate", chapter: "第二章", label: "生成 PASS", detail: "三项材料已提交" },
  { id: "c2-pass-apply", chapter: "第二章", label: "使用 PASS", detail: "拖到 022 书包" },
  { id: "c2-seat-sit", chapter: "第二章", label: "坐到 022", detail: "书包已清退" },
  { id: "c2-seat-dialogue", chapter: "第二章", label: "022 对话", detail: "联系异常意识" },
  { id: "c2-chapter-exit", chapter: "第二章", label: "追往东区大食堂", detail: "022 对话后沿校园脚印继续追踪" },
  { id: "campus-canteen-entry", chapter: "第二章", label: "食堂门口", detail: "普通校园探索入口" },
  { id: "canteen-hunt", chapter: "第三章", label: "东区大食堂追踪", detail: "从校园出生点沿脚印前往东区大食堂" },
  { id: "c3-canteen-entry", chapter: "第三章", label: "进入食堂", detail: "寻找三只残影餐盘" },
  { id: "c3-canteen-menu", chapter: "第三章", label: "点餐机", detail: "浅色与深色菜单" },
  { id: "c3-canteen-pickup", chapter: "第三章", label: "0755 取餐", detail: "按暗号选择窗口" },
  { id: "c3-canteen-block", chapter: "第三章", label: "截住纸条", detail: "餐盘车封住第一个出口" },
  { id: "c3-canteen-block-2", chapter: "第三章", label: "第二次拦截", detail: "纸条转向蒸汽出口" },
  { id: "c3-canteen-block-3", chapter: "第三章", label: "第三次拦截", detail: "纸条转向西侧出口" },
  { id: "c3-canteen-bike", chapter: "第三章", label: "解锁自行车", detail: "使用餐盘回收费" },
  { id: "c3-canteen-chase", chapter: "第三章", label: "755 米 3D 追逐", detail: "A / D 三车道骑行" },
  { id: "c3-canteen-theater", chapter: "第三章", label: "抵达剧院", detail: "纸条钻进剧院" },
  { id: "c3-theater-entry", chapter: "第三章", label: "剧院检票", detail: "海报栏与取票机" },
  { id: "c3-theater-code", chapter: "第三章", label: "取票码 0832", detail: "两张半票根待合成" },
  { id: "c3-theater-program", chapter: "第三章", label: "节目顺序", detail: "追光、开场、谢幕" },
  { id: "c3-theater-prop", chapter: "第三章", label: "后台道具箱", detail: "票根验证与荧光粉刷" },
  { id: "c3-theater-spotlight", chapter: "第三章", label: "追光围捕", detail: "三轮路径预判" },
  { id: "c3-theater-spotlight-round", chapter: "第三章", label: "追光第一轮", detail: "观察路径终点并选择光圈" },
  { id: "c3-theater-complete", chapter: "第三章", label: "替身揭晓", detail: "假纸条与湿节目单" },
  { id: "c3-qizhen-location", chapter: "第三章", label: "寻找启真湖", detail: "CC98、馆藏与微信三条线索" },
  { id: "c3-qizhen-map", chapter: "第三章", label: "地图猜谜", detail: "桥边、倒影与湖自由组合" },
  { id: "c3-qizhen-gate", chapter: "第三章", label: "启真湖入口", detail: "从校园大地图步行进入" },
  { id: "c3-qizhen-reflection", chapter: "第三章", label: "倒影追踪", detail: "深浅模式辨认三次残影" },
  { id: "c3-qizhen-signs", chapter: "第三章", label: "指示牌校准", detail: "旋转三块湖边指示牌" },
  { id: "c3-qizhen-decoy", chapter: "第三章", label: "悬挂假纸条", detail: "按倒影坐标选择目标" },
  { id: "c3-qizhen-mist", chapter: "第三章", label: "喷雾显形", detail: "观察节奏后切换浅色模式" },
  { id: "c3-qizhen-release", chapter: "第三章", label: "纸条脱离倒影", detail: "准备追往东教学楼" }
];

const CHECKPOINT_IDS = new Set(DEVELOPER_CHECKPOINTS.map((checkpoint) => checkpoint.id));
const LEGACY_CHECKPOINT_ALIASES: Record<LegacyDeveloperCheckpointId, DeveloperCheckpointId> = {
  "c2-movement": "c2-name",
  "c2-seat-022": "c2-seat-arrival",
  "c2-evidence": "c2-catalog",
  "c2-top-ten": "c2-cc98-upload",
  "c2-recovery": "c2-recovery-form",
  "c2-pass": "c2-pass-apply",
  "c3-intro": "canteen-hunt",
  "c3-congestion": "canteen-hunt",
  "c3-sprint": "canteen-hunt",
  "c3-result": "canteen-hunt"
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
  const cardRecovered = !["friend_message_required", "system_required", "inventory_required"].includes(phase);
  return {
    ...state,
    currentScene: "phone_home",
    digits: { d1: "0", d2: "7", d3: "9", d4: "8" },
    items: { ...state.items, campusCard: cardRecovered },
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
      inventoryRecovered: cardRecovered,
      dormHubUnlocked: !["friend_message_required", "system_required"].includes(phase)
    },
    ui: {
      ...state.ui,
      zjudingPage: "hub",
      seenChapterIntros: ["chapter_one", "chapter_two"]
    }
  };
}

function withMovementFacts(
  state: GameState,
  patch: Partial<GameState["actOne"]>,
  items: Partial<GameState["items"]> = {}
): GameState {
  const actOne = { ...state.actOne, ...patch };
  actOne.identityVerified = actOne.characterNamed;
  actOne.movementEnabled = actOne.characterNamed && actOne.exerciseStarted && actOne.controlsInstalled;
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
  if (id === "c2-exercise") return { ...state, currentScene: "tiyi", networkMode: "cellular" };
  state = withMovementFacts(state, { exerciseStarted: true });
  if (id === "c2-triangle") return state;
  state = withMovementFacts(state, { pushTriangleTapCount: 3, pushTriangleTaken: true }, { pushTriangle: true });
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
  state = {
    ...withMovementFacts(state, { balanceShifted: true }),
    wallet: { ...state.wallet, campusCardCents: 600 }
  };
  if (id === "c2-gamepad-market") return { ...state, currentScene: "cc98" };
  state = {
    ...withMovementFacts(state, { gamepadPurchased: true }, { gamepad: true }),
    wallet: { ...state.wallet, campusCardCents: 0 }
  };
  if (id === "c2-manual-movement") {
    return { ...state, runtimeMode: "rpg", rpgScene: "dorm_hub", rpgCheckpoint: "dorm_spawn" };
  }
  state = withMovementFacts(state, {
    phase: "reservation_briefing_required",
    controlsInstalled: true,
    manualControlTested: true,
    canLeaveDorm: false
  }, { gamepad: false });
  if (id === "c2-reservation-briefing") {
    return { ...state, runtimeMode: "phone", currentScene: "zjuding", ui: { ...state.ui, zjudingPage: "hub" } };
  }
  state = withMovementFacts(state, { phase: "reservation_required" });
  if (id === "c2-seat-reservation") {
    return { ...state, runtimeMode: "phone", currentScene: "zjuding", ui: { ...state.ui, zjudingPage: "hub" } };
  }
  const reservedState = withMovementFacts(state, {
      phase: "movement_ready",
      canLeaveDorm: true
    });
  return {
    ...reservedState,
    runtimeMode: "rpg",
    rpgScene: "dorm_hub",
    rpgCheckpoint: "dorm_spawn",
    ui: {
      ...reservedState.ui,
      librarySelectedSeat: "022",
      librarySeatReserved: true
    }
  };
}

function createCompletedMovementState(): GameState {
  const state = withMovementFacts(createActTwoBase("complete"), {
    inventoryRecovered: true,
    characterPromptSeen: true,
    characterNamed: true,
    exerciseStarted: true,
    pushTriangleTapCount: 3,
    pushTriangleTaken: true,
    weatherWaterTaken: true,
    mentorLineReleased: true,
    rightArrowAssembled: true,
    balanceShifted: true,
    gamepadPurchased: true,
    controlsInstalled: true,
    manualControlTested: true,
    canLeaveDorm: true
  }, {
    campusCard: true,
    rightArrow: true,
    gamepad: false
  });
  return {
    ...state,
    wallet: { ...state.wallet, campusCardCents: 0 },
    ui: {
      ...state.ui,
      librarySelectedSeat: "022",
      librarySeatReserved: true
    }
  };
}

function libraryPhaseFor(id: LibraryDeveloperCheckpointId): LibraryFinalsPhase {
  if (id === "c2-library-gate") return "library_route_unlocked";
  if (id === "c2-entrance-record" || id === "c2-seat-arrival") return "library_entered";
  if (id === "c2-occupancy-note") return "occupied_seat_found";
  if (["c2-catalog", "c2-archived-rule", "c2-photo-report", "c2-nonperson-stamp", "c2-seat-receipt", "c2-tiyi-proof", "c2-cc98-upload"].includes(id)) return "evidence_gathering";
  if (id === "c2-bd-rise") return "bd_briefing";
  if (id === "c2-recovery-form" || id === "c2-pass-generate") return "recovery_application";
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
    puzzle.catalogUnlocked = true;
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
    puzzle.archivedRuleRead = true;
    puzzle.archivedRuleBriefingSeen = true;
    puzzle.frontDeskProofRequestSeen = true;
    puzzle.libraryVisitedPoints = [...new Set([...puzzle.libraryVisitedPoints, "catalog_terminal", "shelf_755"])] as GameState["ui"]["libraryFinalsPuzzle"]["libraryVisitedPoints"];
    puzzle.clueIds = [...puzzle.clueIds, "archived_leave_rule"];
    items.callNumber755 = false;
    items.archivedLeaveRule = true;
  }
  if (reached("c2-nonperson-stamp")) {
    puzzle.photoCaptured = true;
    puzzle.photoDimmed = true;
    puzzle.itemReportGenerated = true;
    puzzle.lostFoundStage = "ready";
    items.itemRecognitionReport = true;
  }
  if (reached("c2-seat-receipt")) {
    puzzle.lostFoundStage = "stamped";
    puzzle.nonPersonProofStamped = true;
    items.itemRecognitionReport = false;
    items.bagNonPersonProof = true;
  }
  if (reached("c2-tiyi-proof")) {
    puzzle.seatReceiptCollected = true;
    items.seat022Receipt = true;
  }
  if (reached("c2-cc98-upload")) {
    puzzle.auditAttemptCount = 1;
    puzzle.auditArrivalMinutes = 7;
    puzzle.auditPublicNoticeFloor = 47;
    puzzle.auditProofCount = 3;
    puzzle.presenceProofCollected = true;
    items.libraryPresenceProof = true;
  }
  if (reached("c2-bd-rise")) {
    puzzle.cc98UploadedEvidenceIds = [
      "archived_leave_rule",
      "bag_non_person_proof",
      "seat_022_receipt",
      "library_presence_proof"
    ];
    items.archivedLeaveRule = false;
  }
  if (reached("c2-recovery-form")) {
    puzzle.preBdBriefingSeen = true;
    puzzle.bdCount = 3;
    puzzle.appliedBdReplyIds = ["reply-seat-ticket", "reply-visit-proof", "reply-bag-nonperson"];
    puzzle.bdSelectedPostIds = ["bd-rule-count", "bd-identity-zero", "bd-seat-tail", "bd-arrival-minutes"];
    puzzle.bdPasswordAttemptCount = 1;
  }
  if (reached("c2-pass-generate")) {
    puzzle.recoverySubmittedEvidenceIds = ["bag_non_person_proof", "seat_022_receipt", "library_presence_proof"];
    items.bagNonPersonProof = false;
    items.seat022Receipt = false;
    items.libraryPresenceProof = false;
  }
  if (reached("c2-pass-apply")) {
    puzzle.evictionPassGenerated = true;
    puzzle.passBriefingSeen = true;
    items.seatReleasePass = true;
  }
  if (reached("c2-seat-sit")) {
    puzzle.backpackEvicted = true;
    items.seatReleasePass = false;
  }
  if (reached("c2-seat-dialogue")) puzzle.playerSeated = true;
  if (reached("c2-chapter-exit")) {
    puzzle.nextQuestId = "chapter_three_canteen_hunt";
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
    "c2-seat-dialogue": "library_seat_022",
    "c2-chapter-exit": "campus_spawn"
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
    networkMode: id === "c2-tiyi-proof" ? "cellular" : state.networkMode,
    runtimeMode,
    rpgScene: id === "c2-library-gate" || id === "c2-chapter-exit" ? "campus_bootstrap" : rpgCheckpoint ? "library_interior" : state.rpgScene,
    rpgCheckpoint: rpgCheckpoint ?? state.rpgCheckpoint,
    currentScene: currentSceneByCheckpoint[id] ?? state.currentScene,
    items,
    canteenHunt: reached("c2-chapter-exit")
      ? {
          ...state.canteenHunt,
          active: true,
          phase: "tracking",
          mode: "light",
          identifiedTrayIds: [],
          returnedTrayIds: [],
          menuDarkClueRead: false,
          pickupDarkClueRead: false,
          identifiedExitIds: [],
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
        }
      : state.canteenHunt,
    ui: {
      ...state.ui,
      brightness: id === "c2-photo-report" ? 33 : state.ui.brightness,
      inventoryOpen: false,
      selectedItem: null,
      zjudingPage,
      librarySelectedSeat: "022",
      librarySeatReserved: true,
      libraryFinalsPhase: libraryPhaseFor(id),
      libraryFinalsPuzzle: puzzle
    }
  };
  return state;
}

function createCanteenCheckpointState(id: CanteenDeveloperCheckpointId): GameState {
  const state = createLibraryCheckpointState("c2-chapter-exit");
  const identifiedTrayIds = ["tray_blue_01", "tray_blue_02", "tray_blue_03"];
  const afterTrayStage = id !== "canteen-hunt" && id !== "c3-canteen-entry";
  const afterMenuStage = ["c3-canteen-pickup", "c3-canteen-block", "c3-canteen-block-2", "c3-canteen-block-3", "c3-canteen-bike", "c3-canteen-chase", "c3-canteen-theater"].includes(id);
  const afterPickupStage = ["c3-canteen-block", "c3-canteen-block-2", "c3-canteen-block-3", "c3-canteen-bike", "c3-canteen-chase", "c3-canteen-theater"].includes(id);
  const afterBlockingStage = ["c3-canteen-bike", "c3-canteen-chase", "c3-canteen-theater"].includes(id);
  const phase: GameState["canteenHunt"]["phase"] = id === "canteen-hunt"
    ? "tracking"
    : id === "c3-canteen-entry"
      ? "tray_search"
      : id === "c3-canteen-menu"
        ? "menu_order"
        : id === "c3-canteen-pickup"
          ? "pickup_search"
          : ["c3-canteen-block", "c3-canteen-block-2", "c3-canteen-block-3"].includes(id)
            ? "exit_blocking"
            : id === "c3-canteen-bike"
              ? "chase_ready"
              : id === "c3-canteen-chase"
                ? "chasing"
                : "theater_reached";
  const inCanteen = ["c3-canteen-entry", "c3-canteen-menu", "c3-canteen-pickup", "c3-canteen-block", "c3-canteen-block-2", "c3-canteen-block-3"].includes(id);

  return {
    ...state,
    runtimeMode: "rpg",
    rpgScene: inCanteen ? "canteen_interior" : "campus_bootstrap",
    rpgCheckpoint: inCanteen
      ? "canteen_entrance"
      : afterBlockingStage
        ? id === "c3-canteen-theater" ? "campus_theater_junction" : "campus_canteen_gate"
        : "campus_spawn",
    themeMode: "normal",
    wallet: {
      ...state.wallet,
      cashCents: id === "c3-canteen-chase" || id === "c3-canteen-theater"
        ? 0
        : afterTrayStage
          ? 200
          : 0
    },
    items: {
      ...state.items,
      cafeteriaWages: afterTrayStage && !["c3-canteen-chase", "c3-canteen-theater"].includes(id),
      greaseTissue: afterTrayStage,
      pickupTicket0755: afterMenuStage && !afterPickupStage
    },
    canteenHunt: {
      ...state.canteenHunt,
      active: true,
      phase,
      mode: "light",
      identifiedTrayIds: afterTrayStage ? identifiedTrayIds : [],
      returnedTrayIds: afterTrayStage ? identifiedTrayIds : [],
      menuDarkClueRead: afterMenuStage,
      pickupDarkClueRead: afterPickupStage,
      identifiedExitIds: afterBlockingStage
        ? ["southeast", "steam", "west"]
        : id === "c3-canteen-block-3"
          ? ["southeast", "steam"]
          : id === "c3-canteen-block-2"
            ? ["southeast"]
            : [],
      orderAttemptCount: afterMenuStage ? 1 : 0,
      pickupAttemptCount: afterPickupStage ? 1 : 0,
      blockHits: afterBlockingStage ? 3 : id === "c3-canteen-block-3" ? 2 : id === "c3-canteen-block-2" ? 1 : 0,
      bikeCodeRead: ["c3-canteen-chase", "c3-canteen-theater"].includes(id),
      bikeLockCleaned: ["c3-canteen-chase", "c3-canteen-theater"].includes(id),
      bikePaid: ["c3-canteen-chase", "c3-canteen-theater"].includes(id),
      chaseCompleted: id === "c3-canteen-theater",
      chaseAttemptCount: id === "c3-canteen-theater" ? 1 : 0,
      chaseBestDistance: id === "c3-canteen-theater" ? 755 : 0,
      chaseBestLives: id === "c3-canteen-theater" ? 2 : 0,
      chaseCollisions: id === "c3-canteen-theater" ? 1 : 0
    },
    ui: {
      ...state.ui,
      inventoryOpen: false,
      selectedItem: null,
      seenChapterIntros: ["chapter_one", "chapter_two", "chapter_three"]
    }
  };
}

function createTheaterCheckpointState(id: TheaterDeveloperCheckpointId): GameState {
  const base = createCanteenCheckpointState("c3-canteen-theater");
  const reachedCode = ["c3-theater-code", "c3-theater-program", "c3-theater-prop", "c3-theater-spotlight", "c3-theater-spotlight-round", "c3-theater-complete"].includes(id);
  const admitted = ["c3-theater-program", "c3-theater-prop", "c3-theater-spotlight", "c3-theater-spotlight-round", "c3-theater-complete"].includes(id);
  const programSolved = ["c3-theater-prop", "c3-theater-spotlight", "c3-theater-spotlight-round", "c3-theater-complete"].includes(id);
  const propSolved = ["c3-theater-spotlight", "c3-theater-spotlight-round", "c3-theater-complete"].includes(id);
  const complete = id === "c3-theater-complete";
  const phase: GameState["theaterHunt"]["phase"] = complete
    ? "complete"
    : id === "c3-theater-spotlight-round"
      ? "spotlight_hunt"
    : id === "c3-theater-spotlight"
      ? "spotlight_ready"
      : id === "c3-theater-prop"
        ? "prop_setup"
        : id === "c3-theater-program"
          ? "program_search"
          : "entry_ticket";
  return {
    ...base,
    rpgScene: "theater_interior",
    rpgCheckpoint: programSolved ? "theater_stage" : admitted ? "theater_auditorium" : "theater_lobby",
    items: {
      ...base.items,
      greaseTissue: true,
      theaterTicketHalfA: reachedCode && !admitted,
      theaterTicketHalfB: false,
      temporaryTheaterTicket: admitted,
      theaterProgramOpening: admitted && !programSolved,
      theaterProgramSpotlight: admitted && !programSolved,
      theaterProgramFinale: admitted && !programSolved,
      spotlightRemote: programSolved,
      fluorescentBrush: propSolved,
      decoyPaper: complete,
      wetProgram: complete
    },
    theaterHunt: {
      ...base.theaterHunt,
      active: true,
      phase,
      mode: id === "c3-theater-spotlight-round" ? "dark" : "light",
      posterCleaned: reachedCode,
      ticketCodeRead: reachedCode,
      ticketCodeAttempts: admitted ? 1 : 0,
      admitted,
      collectedProgramIds: admitted ? ["opening", "spotlight", "finale"] : [],
      programOrder: programSolved ? ["spotlight", "opening", "finale"] : [],
      propGhostRead: programSolved,
      managerHintRead: programSolved,
      propBoxOpened: propSolved,
      paperDusted: propSolved,
      spotlightRound: complete ? 3 : 0,
      decoyRevealed: complete
    }
  };
}

function createQizhenCheckpointState(id: QizhenDeveloperCheckpointId): GameState {
  const base = createTheaterCheckpointState("c3-theater-complete");
  const inLake = [
    "c3-qizhen-reflection",
    "c3-qizhen-signs",
    "c3-qizhen-decoy",
    "c3-qizhen-mist",
    "c3-qizhen-release"
  ].includes(id);
  const phase: GameState["qizhenLake"]["phase"] = id === "c3-qizhen-location" || id === "c3-qizhen-map"
    ? "location_search"
    : id === "c3-qizhen-gate"
      ? "lake_unlocked"
      : id === "c3-qizhen-reflection"
        ? "reflection_hunt"
        : id === "c3-qizhen-signs"
          ? "sign_alignment"
          : id === "c3-qizhen-decoy"
            ? "decoy_setup"
            : id === "c3-qizhen-mist"
              ? "mist_timing"
              : "chase_ready";
  const signsSolved = ["c3-qizhen-decoy", "c3-qizhen-mist", "c3-qizhen-release"].includes(id);
  const mistReached = ["c3-qizhen-mist", "c3-qizhen-release"].includes(id);
  const releaseReady = id === "c3-qizhen-release";

  return {
    ...base,
    runtimeMode: id === "c3-qizhen-location" || id === "c3-qizhen-map" ? "phone" : "rpg",
    currentScene: id === "c3-qizhen-location" ? "cc98" : id === "c3-qizhen-map" ? "zjuding" : base.currentScene,
    rpgScene: inLake ? "qizhen_lake" : "campus_bootstrap",
    rpgCheckpoint: id === "c3-qizhen-gate"
      ? "campus_qizhen_gate"
      : id === "c3-qizhen-signs"
        ? "qizhen_signs"
        : id === "c3-qizhen-decoy"
          ? "qizhen_decoy"
          : mistReached
            ? "qizhen_mist"
            : inLake
              ? "qizhen_reflection"
              : base.rpgCheckpoint,
    items: {
      ...base.items,
      wetProgram: true,
      decoyPaper: true,
      bridgeKeyword: id !== "c3-qizhen-location",
      reflectionKeyword: id !== "c3-qizhen-location",
      lakeKeyword: id !== "c3-qizhen-location",
      reflectionCoordinate: signsSolved
    },
    qizhenLake: {
      ...base.qizhenLake,
      active: true,
      phase,
      mode: id === "c3-qizhen-signs" || id === "c3-qizhen-mist" ? "dark" : "light",
      locationBriefingSeen: id !== "c3-qizhen-location",
      bridgeClueFound: id !== "c3-qizhen-location",
      reflectionClueFound: id !== "c3-qizhen-location",
      lakeClueFound: id !== "c3-qizhen-location",
      mapClueIds: id === "c3-qizhen-location"
        ? []
        : id === "c3-qizhen-map"
          ? ["bridge", "reflection"]
          : ["bridge", "reflection", "lake"],
      introSeen: ["c3-qizhen-signs", "c3-qizhen-decoy", "c3-qizhen-mist", "c3-qizhen-release"].includes(id),
      reflectionRound: ["sign_alignment", "decoy_setup", "mist_timing", "chase_ready"].includes(phase) ? 3 : 0,
      signRotations: signsSolved ? [1, 2, 3] : [0, 0, 0],
      signsSolved,
      decoyPlacedAt: mistReached ? "lamp" : null,
      mistRhythmRead: releaseReady,
      mistAttempts: releaseReady ? 1 : 0,
      paperReleased: releaseReady
    },
    ui: {
      ...base.ui,
      zjudingPage: id === "c3-qizhen-map" ? "campus_map" : "hub",
      inventoryOpen: false,
      selectedItem: null
    }
  };
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
      currentScene: "checkin",
      flags: { ...initial.flags, codeScattered: true },
      actOne: { ...initial.actOne, dormHubUnlocked: false }
    };
  }
  if (id === "c1-checkin") {
    return {
      ...initial,
      currentScene: "checkin",
      digits: { d1: "0", d2: "7", d3: "9", d4: "8" },
      flags: {
        ...initial.flags,
        codeScattered: true,
        cardZeroTaken: true,
        tiyiCountTaken: true,
        gearNineTaken: true,
        flowerEightTaken: true
      }
    };
  }
  if (id === "c1-narrator-block") {
    return {
      ...initial,
      currentScene: "ending",
      digits: { d1: "0", d2: "7", d3: "9", d4: "8" },
      flags: {
        ...initial.flags,
        codeScattered: true,
        cardZeroTaken: true,
        tiyiCountTaken: true,
        gearNineTaken: true,
        flowerEightTaken: true,
        checkinDone: true
      },
      actOne: { ...initial.actOne, inventoryRecovered: false, dormHubUnlocked: false }
    };
  }
  if (id === "c2-friend") return createActTwoBase("friend_message_required");
  if (id === "c2-system") return { ...createActTwoBase("system_required"), currentScene: "zjuding" };
  if (id === "c2-inventory") {
    return {
      ...createActTwoBase("inventory_required"),
      runtimeMode: "rpg",
      rpgScene: "dorm_hub"
    };
  }
  if (id === "c2-system-return") {
    const state = createActTwoBase("system_return_required");
    return {
      ...state,
      currentScene: "zjuding",
      runtimeMode: "rpg",
      rpgScene: "dorm_hub",
      actOne: { ...state.actOne, inventoryRecovered: true }
    };
  }
  if ([
    "c2-name", "c2-exercise", "c2-triangle", "c2-weather-water", "c2-mentor-line",
    "c2-arrow-assembly", "c2-balance-shift", "c2-gamepad-market", "c2-manual-movement",
    "c2-reservation-briefing", "c2-seat-reservation", "c2-dorm-exit"
  ].includes(id)) return createMovementCheckpointState(id);
  if (LIBRARY_CHECKPOINT_ORDER.includes(id as LibraryDeveloperCheckpointId)) {
    return createLibraryCheckpointState(id as LibraryDeveloperCheckpointId);
  }
  if (id === "campus-canteen-entry") {
    const state = createCompletedMovementState();
    return {
      ...state,
      runtimeMode: "rpg",
      rpgScene: "campus_bootstrap",
      rpgCheckpoint: "campus_canteen_gate",
      canteenHunt: {
        ...state.canteenHunt,
        active: false,
        phase: "tracking"
      },
      ui: {
        ...state.ui,
        inventoryOpen: false,
        selectedItem: null,
        seenChapterIntros: ["chapter_one", "chapter_two"]
      }
    };
  }
  if (id === "canteen-hunt" || id.startsWith("c3-canteen-")) {
    return createCanteenCheckpointState(id as CanteenDeveloperCheckpointId);
  }
  if (id.startsWith("c3-theater-")) {
    return createTheaterCheckpointState(id as TheaterDeveloperCheckpointId);
  }
  if (id.startsWith("c3-qizhen-")) {
    return createQizhenCheckpointState(id as QizhenDeveloperCheckpointId);
  }

  return createCanteenCheckpointState("canteen-hunt");
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
  storage.setItem(DEVELOPER_BIKE_START_KEY, "0");
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
  if (phase === "bd_briefing" || phase === "top_ten_rising") return "c2-bd-rise";
  if (phase === "top_ten_reached") return "c2-recovery-form";
  if (phase === "recovery_application") return "c2-pass-generate";
  if (phase === "pass_ready") return "c2-pass-apply";
  if (phase === "backpack_removed") return "c2-seat-sit";
  if (phase === "seat_recovered") return "c2-seat-dialogue";
  if (phase === "friend_contacted") return "c2-chapter-exit";
  if (scene === "bike_arcade" || scene === "chapter_transition") return "canteen-hunt";
  if (scene === "photos") return "c2-photo-report";
  if (scene === "tiyi") return "c2-exercise";
  if (scene === "cc98") return "c2-gamepad-market";
  if (scene === "zjuding") return page === "library_recovery" ? "c2-recovery-form" : page === "library_catalog" ? "c2-catalog" : "c2-system";
  if (scene === "phone_home") return "c1-code-hunt";
  if (scene === "ending") return "c1-narrator-block";
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
