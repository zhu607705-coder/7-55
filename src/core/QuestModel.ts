import type { GameState, ItemId, QuestStep, QuestViewModel, SceneId } from "./types";
import { selectFeatureAccess } from "./FeatureAccess";

interface StepSource {
  id: string;
  label: string;
  done: boolean;
  itemId?: ItemId;
}

interface NextAction {
  objective: string;
  hints: [string, string, string];
  targetSurface: "phone" | "rpg";
  recommendedScene?: SceneId;
}

const DEFAULT_HINTS: [string, string, string] = [
  "先检查当前任务提到的应用或现场。",
  "对照物品来源与界面里仍缺少的证据类型。",
  "留意当前界面中可展开、可拖入或可继续对话的区域。"
];

function buildSteps(sources: StepSource[]): QuestStep[] {
  const firstPending = sources.findIndex((step) => !step.done);
  return sources.map((step, index) => ({
    id: step.id,
    label: step.label,
    status: step.done ? "completed" : index === firstPending ? "active" : "locked",
    ...(step.itemId ? { itemId: step.itemId } : {})
  }));
}

function countDone(sources: StepSource[]): number {
  return sources.filter((step) => step.done).length;
}

function chapterOneQuest(state: GameState): QuestViewModel {
  const digitCount = Object.values(state.digits).filter(Boolean).length;
  const sources: StepSource[] = [
    { id: "friend_message", label: "查看朋友消息", done: state.flags.codeScattered },
    { id: "campus_card", label: "取得寝室校园卡", done: state.items.campusCard },
    { id: "digit_1", label: "找回第 1 位签到码", done: digitCount >= 1 },
    { id: "digit_2", label: "找回第 2 位签到码", done: digitCount >= 2 },
    { id: "digit_3", label: "找回第 3 位签到码", done: digitCount >= 3 },
    { id: "digit_4", label: "找回第 4 位签到码", done: digitCount >= 4 },
    { id: "checkin", label: "完成签到", done: state.flags.checkinDone }
  ];
  let next: NextAction;
  if (!state.flags.codeScattered) {
    next = {
      objective: "查看朋友发来的新消息",
      hints: ["从手机里的聊天应用开始。", "朋友消息会说明签到遇到的异常。", "查看微信会话列表里带新提示的联系人。"],
      targetSurface: "phone",
      recommendedScene: "wechat"
    };
  } else if (!state.items.campusCard) {
    next = {
      objective: "在寝室找到校园卡",
      hints: ["浙大钉里保留了寝室地图入口。", "校园卡属于个人物品，位置靠近个人桌面。", "从浙大钉的校园地图进入寝室，检查右侧书桌。"],
      targetSurface: "phone",
      recommendedScene: "zjuding"
    };
  } else if (digitCount < 4) {
    next = {
      objective: `找回四位签到码（${digitCount}/4）`,
      hints: ["数字分散在校园卡、体艺、主屏设置和植物相关界面。", "每个数字都需要一次观察、翻转或组合。", "依次检查校园卡余额、体艺记录、设置齿轮背面和盆栽。"],
      targetSurface: "phone",
      recommendedScene: "phone_home"
    };
  } else {
    next = {
      objective: "回到学在浙大完成签到",
      hints: ["四位数字已经齐全。", "签到入口位于浙大钉的学习服务中。", "打开浙大钉，再进入学在浙大。"],
      targetSurface: "phone",
      recommendedScene: "zjuding"
    };
  }
  return {
    id: "chapter_one_checkin",
    chapter: "chapter_one",
    title: "找回签到码",
    completed: countDone(sources),
    total: sources.length,
    steps: buildSteps(sources),
    ...next
  };
}

function movementQuest(state: GameState): QuestViewModel {
  const phaseOrder = ["friend_message_required", "system_required", "inventory_required", "system_return_required"];
  const dialogueDone = !phaseOrder.includes(state.actOne.phase);
  const sources: StepSource[] = [
    { id: "system_dialogue", label: "完成系统对话", done: dialogueDone },
    { id: "identity", label: "登记人物身份", done: state.actOne.characterNamed },
    { id: "exercise", label: "启动课外锻炼", done: state.actOne.exerciseStarted },
    { id: "arrow", label: "取得右移箭头", done: state.actOne.rightArrowAssembled },
    { id: "balance", label: "调整校园卡余额", done: state.actOne.balanceShifted },
    { id: "gamepad", label: "取得游戏手柄", done: state.actOne.gamepadPurchased },
    { id: "manual_move", label: "完成首次手动移动", done: state.actOne.manualControlTested },
    { id: "leave_dorm", label: "离开寝室", done: state.actOne.phase === "complete" }
  ];
  const nextById: Record<string, NextAction> = {
    system_dialogue: { objective: "跟进朋友消息并找到系统", hints: ["新消息仍在微信。", "朋友会把你引向浙大钉里的异常。", "先完成微信对话，再检查浙大钉标题附近的系统标记。"], targetSurface: "phone", recommendedScene: state.actOne.phase === "friend_message_required" ? "wechat" : "zjuding" },
    identity: { objective: "为地图人物补齐身份", hints: ["第二章开放了新的校园服务。", "电子校园卡包含姓名和学号，部门黄页可以读取它。", "进入浙大钉部门黄页，使用校园卡读卡区。"], targetSurface: "phone", recommendedScene: "zjuding" },
    exercise: { objective: "让人物先自动走起来", hints: ["体艺记录与运动能力有关。", "完成身份登记后，体艺页面会识别参与者。", "进入浙大体艺，使用页面中的开始锻炼按钮。"], targetSurface: "phone", recommendedScene: "tiyi" },
    arrow: { objective: "拼出一个能移动对象的方向", hints: ["主页推送与导师头像各缺少一部分图形。", "天气里的水滴能处理头像边缘的连接处。", "取得三角形和竖线后，在物品栏中将两者组合。"], targetSurface: "phone", recommendedScene: "phone_home" },
    balance: { objective: "让校园卡余额发生位移", hints: ["新道具只描述移动方向。", "校园卡上有一串位置值得改变的数字。", "打开校园卡余额，把右移箭头拖到余额区域。"], targetSurface: "phone", recommendedScene: "campus_card" },
    gamepad: { objective: "找到可以控制方向的设备", hints: ["第二章已经开放 CC98。", "余额变化后可以处理一笔低价交易。", "进入 CC98 今日热门，查看二手交易帖。"], targetSurface: "phone", recommendedScene: "cc98" },
    manual_move: { objective: "在寝室完成一次手动移动", hints: ["手柄需要在地图人物旁使用。", "姓名和锻炼状态共同决定手柄是否生效。", "聚焦寝室地图，使用方向键或 WASD 移动一次。"], targetSurface: "rpg" },
    leave_dorm: { objective: "从寝室出口离开", hints: ["第一次手动移动已经解除出口限制。", "出口位于寝室下方。", "走到南侧门口并继续向外移动。"], targetSurface: "rpg" }
  };
  const nextId = sources.find((step) => !step.done)?.id ?? "leave_dorm";
  return {
    id: "chapter_two_movement",
    chapter: "chapter_two",
    title: "找到移动的办法",
    completed: countDone(sources),
    total: sources.length,
    steps: buildSteps(sources),
    ...nextById[nextId]
  };
}

function libraryQuest(state: GameState): QuestViewModel {
  const puzzle = state.ui.libraryFinalsPuzzle;
  const sources: StepSource[] = [
    { id: "entrance_record", label: "读取入馆记录", done: puzzle.entranceRecordRead },
    { id: "seat_022", label: "找到 022", done: puzzle.backpackInspected },
    { id: "note", label: "取得占座纸条", done: puzzle.occupancyNoteCollected, itemId: "occupancyNote" },
    { id: "catalog", label: "完成馆藏检索", done: puzzle.callNumberCollected, itemId: "callNumber755" },
    { id: "rule", label: "取得旧版规则", done: puzzle.archivedRuleCollected, itemId: "archivedLeaveRule" },
    { id: "proof_nonperson", label: "取得非本人证明", done: puzzle.nonPersonProofStamped, itemId: "bagNonPersonProof" },
    { id: "proof_receipt", label: "取得 022 小票", done: puzzle.seatReceiptCollected, itemId: "seat022Receipt" },
    { id: "proof_presence", label: "取得本人来过证明", done: puzzle.presenceProofCollected, itemId: "libraryPresenceProof" },
    { id: "cc98_upload", label: "提交四项公示材料", done: puzzle.cc98UploadedEvidenceIds.length === 4 },
    { id: "bd_one", label: "完成第 1 次有效 bd", done: puzzle.bdCount >= 1 },
    { id: "bd_two", label: "完成第 2 次有效 bd", done: puzzle.bdCount >= 2 },
    { id: "bd_three", label: "排名推进至 01", done: puzzle.bdCount >= 3 },
    { id: "recovery", label: "提交恢复申请", done: puzzle.evictionPassGenerated },
    { id: "apply_pass", label: "使用清退 PASS", done: puzzle.backpackEvicted, itemId: "seatReleasePass" },
    { id: "sit", label: "坐到 022", done: puzzle.playerSeated },
    { id: "dialogue", label: "完成 022 对话", done: puzzle.nextQuestId === "chapter_three_book_hunt" }
  ];
  const nextId = sources.find((step) => !step.done)?.id ?? "dialogue";
  const phone = (objective: string, scene: SceneId, hints = DEFAULT_HINTS): NextAction => ({ objective, recommendedScene: scene, targetSurface: "phone", hints });
  const rpg = (objective: string, hints = DEFAULT_HINTS): NextAction => ({ objective, targetSurface: "rpg", hints });
  const next: Record<string, NextAction> = {
    entrance_record: rpg("读取基础图书馆入馆记录", ["入口闸机保存了访问记录。", "记录能确认目标座位仍有未闭合会话。", "聚焦图书馆地图，在入口前台附近交互。"]),
    seat_022: rpg("前往二层南区寻找 022", ["入馆记录已经给出座位区域。", "目标会话与一个具体座位相连。", "在阅览区找到 022 并检查占座书包。"]),
    note: rpg("检查书包旁留下的信息"),
    catalog: phone("用纸条查找公开记录，再核对馆藏", "cc98", ["占座纸条可以作为论坛搜索材料。", "公开记录会提到一条旧版离座规则。", "先将纸条拖到 CC98 搜索，再到浙大钉馆藏检索核对书名。"]),
    rule: rpg("按索书号找到旧版规则"),
    proof_nonperson: phone("生成并盖章物品识别报告", "photos"),
    proof_receipt: rpg("检查 022 桌面夹缝"),
    proof_presence: phone("核对本人到馆记录", "tiyi"),
    cc98_upload: phone(`上传四项公示材料（${puzzle.cc98UploadedEvidenceIds.length}/4）`, "cc98", ["旧规则和三份证明都属于公示材料。", "每个上传槽只接受对应类型的纸质道具。", "进入 CC98 调查帖，将兼容道具拖到四个上传槽。"]),
    bd_one: phone("选择与证据一致的回复推进排名", "cc98"),
    bd_two: phone("继续筛选有效回复推进排名", "cc98"),
    bd_three: phone("完成最后一次有效回复", "cc98"),
    recovery: phone(`提交恢复材料（${puzzle.recoverySubmittedEvidenceIds.length}/3）`, "zjuding", ["进入十大后，图书馆会开放恢复申请。", "恢复申请只需要三份个人与座位证明。", "在浙大钉图书馆打开 022 恢复申请并提交材料。"]),
    apply_pass: rpg("把离座清退 PASS 用于 022 书包"),
    sit: rpg("坐到已经空出的 022"),
    dialogue: rpg("与 022 完成对话")
  };
  return {
    id: "chapter_two_library",
    chapter: "chapter_two",
    title: "恢复 022 座位",
    completed: countDone(sources),
    total: sources.length,
    steps: buildSteps(sources),
    ...next[nextId]
  };
}

function chapterThreeQuest(state: GameState): QuestViewModel {
  const sources: StepSource[] = [
    { id: "book_hunt", label: "找到借走签到记录的书", done: state.bikeArcade.completed }
  ];
  return {
    id: "chapter_three_book_hunt",
    chapter: "chapter_three",
    title: "寻找借走记录的书",
    objective: state.bikeArcade.completed ? "第三章任务完成" : "打开求是潮，追上那本书",
    completed: countDone(sources),
    total: 1,
    steps: buildSteps(sources),
    hints: ["新的游戏入口已出现在手机。", "目标距离与书上的编号有关。", "打开求是潮，完成骑行关卡。"],
    targetSurface: "phone",
    recommendedScene: "bike_arcade"
  };
}

export function selectQuestViewModel(state: GameState): QuestViewModel {
  const access = selectFeatureAccess(state);
  if (access.chapter === "chapter_one") return chapterOneQuest(state);
  if (access.chapter === "chapter_three") return chapterThreeQuest(state);
  if (state.actOne.phase !== "complete" && state.ui.libraryFinalsPhase === "idle") return movementQuest(state);
  return libraryQuest(state);
}
