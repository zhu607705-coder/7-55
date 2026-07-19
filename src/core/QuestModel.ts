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
  const phaseOrder = ["friend_message_required", "system_required"];
  const dialogueDone = !phaseOrder.includes(state.actOne.phase);
  const cardRecovered = state.actOne.inventoryRecovered && state.items.campusCard;
  const reservationBriefed = ["reservation_required", "movement_ready", "complete"].includes(state.actOne.phase);
  const sources: StepSource[] = [
    { id: "system_dialogue", label: "完成系统对话", done: dialogueDone },
    { id: "inventory", label: "找到道具栏", done: cardRecovered },
    { id: "identity", label: "登记人物身份", done: state.actOne.characterNamed },
    { id: "exercise", label: "启动课外锻炼", done: state.actOne.exerciseStarted },
    { id: "arrow", label: "取得右移箭头", done: state.actOne.rightArrowAssembled },
    { id: "balance", label: "调整校园卡余额", done: state.actOne.balanceShifted },
    { id: "gamepad", label: "取得游戏手柄", done: state.actOne.gamepadPurchased },
    { id: "controls", label: "把手柄安装给人物", done: state.actOne.controlsInstalled },
    { id: "manual_move", label: "完成首次手动移动", done: state.actOne.manualControlTested },
    { id: "reservation_briefing", label: "听取系统的图书馆说明", done: reservationBriefed },
    { id: "seat_reservation", label: "预约基础馆二层南区 022", done: state.ui.librarySeatReserved },
    { id: "leave_dorm", label: "离开寝室", done: state.actOne.phase === "complete" }
  ];
  const arrowNextAction: NextAction = !state.actOne.pushTriangleTaken
    ? {
        objective: "查看主页的「方向校准」推送",
        hints: ["锻炼记录已经同步到手机。", "主页通知列表出现了新的「方向校准」。", "回到手机主页，多观察几次推送头像边缘的变化。"],
        targetSurface: "phone",
        recommendedScene: "phone_home"
      }
    : !state.actOne.weatherWaterTaken
      ? {
          objective: "从天气页面取得一滴水",
          hints: ["三角形已经进入道具栏。", "主页的天气通知现在可以打开。", "进入天气页面，接住界面下方的水滴。"],
          targetSurface: "phone",
          recommendedScene: "weather"
        }
      : !state.actOne.mentorLineReleased
        ? {
            objective: "用天气水滴处理导师头像",
            hints: ["水滴可以用于处理黏着物。", "微信导师头像边缘有一条被黏住的竖线。", "打开微信，将天气水滴拖到导师头像。"],
            targetSurface: "phone",
            recommendedScene: "wechat"
          }
        : {
            objective: "组合三角形与竖线",
            hints: ["两个图形素材已经齐全。", "道具栏支持把互补形状拖到一起。", "将三角形与竖线组合。"],
            targetSurface: "phone",
            recommendedScene: "phone_home"
          };
  const nextById: Record<string, NextAction> = {
    system_dialogue: { objective: state.actOne.phase === "friend_message_required" ? "回复朋友的新消息" : "找到系统", hints: ["新消息仍在微信。", "朋友会把你引向浙大钉里的异常。", "完成微信对话后，检查浙大钉身份区域“求”字旁的红圈。"], targetSurface: "phone", recommendedScene: state.actOne.phase === "friend_message_required" ? "wechat" : "zjuding" },
    inventory: { objective: "找到道具栏", hints: ["系统已经开放寝室地图。", "个人物品留在右侧书桌。", "进入浙大钉校园地图，打开右侧个人书桌上的宝箱。"], targetSurface: "rpg" },
    identity: { objective: "为地图人物补齐身份", hints: ["第二章开放了新的校园服务。", "电子校园卡包含姓名和学号，部门黄页可以读取它。", "进入浙大钉部门黄页，使用校园卡读卡区。"], targetSurface: "phone", recommendedScene: "zjuding" },
    exercise: { objective: "让人物先自动走起来", hints: ["体艺记录与运动能力有关。", "完成身份登记后，体艺页面会识别参与者。", "进入浙大体艺，使用页面中的开始锻炼按钮。"], targetSurface: "phone", recommendedScene: "tiyi" },
    arrow: arrowNextAction,
    balance: { objective: "让校园卡余额发生位移", hints: ["新道具只描述移动方向。", "校园卡上有一串位置值得改变的数字。", "打开校园卡余额，把右移箭头拖到余额区域。"], targetSurface: "phone", recommendedScene: "campus_card" },
    gamepad: { objective: "找到可以控制方向的设备", hints: ["第二章已经开放 CC98。", "余额变化后可以处理一笔低价交易。", "进入 CC98 今日热门，查看二手交易帖。"], targetSurface: "phone", recommendedScene: "cc98" },
    controls: { objective: "把手柄拖到寝室小人身上", hints: ["购买只会把手柄放入道具栏。", "返回寝室后展开 RPG 道具栏。", "将手柄拖到小人身上完成安装。"], targetSurface: "rpg" },
    manual_move: { objective: "在寝室完成一次手动移动", hints: ["手柄已安装，自动走动已停止。", "桌面端使用 WASD 或方向键。", "真实输入任意一次方向。"], targetSurface: "rpg" },
    reservation_briefing: { objective: "听系统说明图书馆方案", hints: ["系统已回到浙大钉。", "它会说明权限限制和可协助的对象。", "继续当前系统对话。"], targetSurface: "phone", recommendedScene: "zjuding" },
    seat_reservation: { objective: ["library_spaces", "library_seat"].includes(state.ui.zjudingPage) ? "预约基础馆二层南区 022" : "在浙大钉预约图书馆座位", hints: ["打开浙大钉的图书馆服务。", "进入座位预约，选择基础馆二层南区。", "选中 022 并确认预约。"], targetSurface: "phone", recommendedScene: "zjuding" },
    leave_dorm: { objective: "前往基础图书馆 022", hints: ["座位预约已经完成。", "回到寝室，出口现在可以通行。", "离开寝室后沿校园道路前往基础图书馆。"], targetSurface: "rpg" }
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
    { id: "rule", label: "阅读旧版临时离座恢复规定", done: puzzle.archivedRuleRead, itemId: "archivedLeaveRule" },
    { id: "proof_presence", label: "本人确实到馆", done: puzzle.presenceProofCollected, itemId: "libraryPresenceProof" },
    { id: "proof_receipt", label: "目标座位与凭据一致", done: puzzle.seatReceiptCollected, itemId: "seat022Receipt" },
    { id: "proof_nonperson", label: "当前占用物不具备本人身份", done: puzzle.nonPersonProofStamped, itemId: "bagNonPersonProof" },
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
    catalog: puzzle.investigationOpened
      ? puzzle.catalogUnlocked
        ? phone("在浙大钉馆藏检索核对书名", "zjuding", ["调查帖已经给出题名线索。", "图书馆终端已开放手机馆藏检索。", "进入浙大钉图书馆，打开馆藏检索。"])
        : rpg("在图书馆终端解锁馆藏检索", ["调查帖提到了馆藏题名。", "馆内终端负责开放检索权限。", "回到图书馆的馆藏检索终端并互动。"])
      : phone("用纸条查找公开记录", "cc98", ["占座纸条可以作为论坛搜索材料。", "公开记录会提到一条旧版离座规则。", "进入 CC98，将占座纸条拖到搜索框。"]),
    rule: rpg("按索书号找到旧版规则"),
    proof_nonperson: puzzle.itemReportGenerated
      ? rpg("把识别报告交给失物身份登记机")
      : phone("生成物品识别报告", "photos"),
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
