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
    { id: "digits", label: "找回签到码", done: digitCount === 4 },
    { id: "checkin", label: "去签到", done: state.flags.checkinDone }
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
      objective: "去签到",
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
  const sources: StepSource[] = [
    { id: "respond", label: "让地图人物回应你", done: state.actOne.characterNamed },
    { id: "move", label: "让地图人物动起来", done: state.actOne.exerciseStarted },
    { id: "direction", label: "找到控制方向的方法", done: state.actOne.gamepadPurchased },
    { id: "library", label: "去图书馆", done: state.actOne.phase === "complete" }
  ];
  const nextById: Record<string, NextAction> = {
    respond: {
      objective: "让地图人物回应你",
      hints: ["他现在听不见你。", "手机里有能联系校内人员的地方。", "用校园卡上的身份信息，在部门黄页里找到他。"],
      targetSurface: "phone",
      recommendedScene: "zjuding"
    },
    move: {
      objective: "让地图人物动起来",
      hints: ["他知道自己是谁了，但还没有运动权限。", "有一个 App 专门负责把普通走路变成记录。", "打开浙大体艺，开始课外锻炼。"],
      targetSurface: "phone",
      recommendedScene: "tiyi"
    },
    direction: {
      objective: "找到控制方向的方法",
      hints: ["他会走，但不知道听谁指挥。", "论坛里可能有人卖很便宜的控制设备。", "去 CC98 二手交易，用处理过的校园卡余额买手柄。"],
      targetSurface: "phone",
      recommendedScene: "cc98"
    },
    library: {
      objective: "去图书馆",
      hints: ["你已经能控制小人了。", "系统朋友在图书馆，不在寝室门口。", "操控小人离开寝室，在校园地图上前往图书馆。"],
      targetSurface: "rpg"
    }
  };
  const nextId = sources.find((step) => !step.done)?.id ?? "library";
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
  const proofCount = [puzzle.nonPersonProofStamped, puzzle.seatReceiptCollected, puzzle.presenceProofCollected].filter(Boolean).length;
  const sources: StepSource[] = [
    { id: "reserve", label: "预约 022", done: state.ui.librarySeatReserved && state.ui.librarySelectedSeat === "022" },
    { id: "confirm", label: "确认座位状态", done: puzzle.occupancyNoteCollected },
    { id: "rules", label: "查清占座规则", done: puzzle.archivedRuleCollected },
    { id: "materials", label: "凑齐恢复材料", done: proofCount === 3 },
    { id: "visibility", label: "让帖子被看见", done: puzzle.bdCount >= 3 },
    { id: "application", label: "提交恢复申请", done: puzzle.evictionPassGenerated },
    { id: "return", label: "回到 022", done: puzzle.nextQuestId === "chapter_three_book_hunt" }
  ];
  const nextId = sources.find((step) => !step.done)?.id ?? "return";
  const phone = (objective: string, scene: SceneId, hints = DEFAULT_HINTS): NextAction => ({ objective, recommendedScene: scene, targetSurface: "phone", hints });
  const rpg = (objective: string, hints = DEFAULT_HINTS): NextAction => ({ objective, targetSurface: "rpg", hints });
  const next: Record<string, NextAction> = {
    reserve: phone("预约 022", "zjuding", ["系统朋友绑定在一个座位上。", "没有预约，图书馆不会承认你和它有关系。", "去浙大钉图书馆预约二楼南区 022。"]),
    confirm: rpg("确认座位状态", ["手机里预约成功，不代表现场没问题。", "去 RPG 图书馆地图找 022。", "检查 022 上的东西和旁边的纸条。"]),
    rules: phone("查清占座规则", "cc98", ["纸条提到了一个更吵的地方。", "CC98 里有人讨论过 022。", "用占座纸条搜索 CC98，再顺着帖子找旧规则。"]),
    materials: phone(`凑齐恢复材料（${proofCount}/3）`, "photos", ["旧规则说恢复座位需要三种证明。", "分别证明“你来过”“座位是 022”“书包不是本人”。", "照片、座位夹缝和体艺都能帮上忙。"]),
    visibility: phone("让帖子被看见", "cc98", ["上传证据只是让它存在。", "管理员只会处理足够显眼的问题。", "选择能和证据对应上的回复 bd。"]),
    application: phone("提交恢复申请", "zjuding", ["帖子热度已经触发图书馆 App。", "恢复申请不需要所有材料，只需要三份证明。", "把三份证明拖进图书馆恢复申请槽。"]),
    return: rpg("回到 022", ["申请通过不等于书包会自己走。", "PASS 要在现场使用。", "回 RPG 图书馆，把 PASS 用在 022 的书包上。"])
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
