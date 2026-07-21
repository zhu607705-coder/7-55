import type { ChapterId, GameState, QuestStep, QuestViewModel, SceneId } from "./types";
import { selectFeatureAccess } from "./FeatureAccess";

interface TaskDefinition {
  id: string;
  label: string;
  hints: readonly string[];
  targetSurface: "phone" | "rpg";
  recommendedScene?: SceneId;
}

function buildQuest(
  chapter: ChapterId,
  title: string,
  tasks: readonly TaskDefinition[],
  currentIndex: number
): QuestViewModel {
  const activeIndex = Math.max(0, Math.min(currentIndex, tasks.length - 1));
  const active = tasks[activeIndex];
  const steps: QuestStep[] = tasks.map((task, index) => ({
    id: task.id,
    label: task.label,
    status: index < activeIndex ? "completed" : index === activeIndex ? "active" : "locked"
  }));
  return {
    id: active.id,
    chapter,
    title,
    objective: active.label,
    completed: activeIndex,
    total: tasks.length,
    steps,
    hints: active.hints,
    targetSurface: active.targetSurface,
    ...(active.recommendedScene ? { recommendedScene: active.recommendedScene } : {})
  };
}

function chapterOneQuest(state: GameState): QuestViewModel {
  const digitCount = Object.values(state.digits).filter(Boolean).length;
  const tasks: readonly TaskDefinition[] = [
    {
      id: "chapter_one_view_info",
      label: "查看信息",
      hints: [],
      targetSurface: "phone",
      recommendedScene: "wechat"
    },
    {
      id: "chapter_one_find_code",
      label: `找签到码（${digitCount}/4）`,
      hints: [
        "先检查浙大体艺、设置齿轮和盆栽相关界面。",
        "道具可以拖拽合并。",
        "浙大体艺打不开时，试试换一种网络。",
        "微信界面也用“自动旋转”",
        "光照在控制中心拖动调节",
        "还有一个在签到页面"
      ],
      targetSurface: "phone",
      recommendedScene: "phone_home"
    },
    {
      id: "chapter_one_check_in",
      label: "去签到",
      hints: [],
      targetSurface: "phone",
      recommendedScene: "checkin"
    }
  ];
  const currentIndex = !state.flags.codeScattered ? 0 : digitCount < 4 ? 1 : 2;
  return buildQuest("chapter_one", "五分钟", tasks, currentIndex);
}

function movementQuest(state: GameState): QuestViewModel {
  const inventoryTaskActive = ["inventory_required", "system_return_required"].includes(state.actOne.phase);
  const tasks: readonly TaskDefinition[] = [
    {
      id: "chapter_two_character_response",
      label: inventoryTaskActive ? "找到道具栏" : "让地图人物回应你",
      hints: inventoryTaskActive ? [] : [
        "手机里有能联系校内人员的地方。",
        "用校园卡上的身份信息，在部门黄页里找到他。"
      ],
      targetSurface: inventoryTaskActive ? "rpg" : "phone",
      ...(inventoryTaskActive ? {} : { recommendedScene: "zjuding" })
    },
    {
      id: "chapter_two_character_move",
      label: "让地图人物动起来",
      hints: [
        "有一个 App 专门负责把普通走路变成记录。",
        "打开浙大体艺，开始课外锻炼。"
      ],
      targetSurface: "phone",
      recommendedScene: "tiyi"
    },
    {
      id: "chapter_two_direction_control",
      label: "找到控制方向的方法",
      hints: [
        "论坛里可能有人卖很便宜的控制设备。",
        "去 CC98 二手交易，用处理过的校园卡余额买手柄。",
        "组合成箭头放在校园卡余额上，小数点右移两位。"
      ],
      targetSurface: "phone",
      recommendedScene: "cc98"
    },
    {
      id: "chapter_two_reserve_022",
      label: "预约 022",
      hints: ["二层南区022"],
      targetSurface: "phone",
      recommendedScene: "zjuding"
    }
  ];

  // 系统说明属于上一关的过渡；完成说明、正式开放预约后才切换到“预约 022”。
  const currentIndex = !state.actOne.characterNamed
    ? 0
    : !state.actOne.exerciseStarted
      ? 1
      : state.actOne.phase === "reservation_required"
        ? 3
        : 2;
  return buildQuest("chapter_two", "找到移动的办法", tasks, currentIndex);
}

function libraryQuest(state: GameState): QuestViewModel {
  const puzzle = state.ui.libraryFinalsPuzzle;
  const proofCount = [
    puzzle.nonPersonProofStamped,
    puzzle.seatReceiptCollected,
    puzzle.presenceProofCollected
  ].filter(Boolean).length;
  const tasks: readonly TaskDefinition[] = [
    {
      id: "chapter_two_go_library",
      label: "去图书馆",
      hints: ["地图缩放仔细找"],
      targetSurface: "rpg"
    },
    {
      id: "chapter_two_confirm_seat",
      label: "确认座位状态",
      hints: [
        "去 RPG 图书馆地图找 022。",
        "检查 022 上的东西和旁边的纸条。"
      ],
      targetSurface: "rpg"
    },
    {
      id: "chapter_two_check_rules",
      label: "查清占座规则",
      hints: [
        "纸条提到了一个更吵的地方。",
        "CC98 里有人讨论过 022。",
        "用占座纸条搜索 CC98，再顺着帖子找旧规则。"
      ],
      targetSurface: "phone",
      recommendedScene: "cc98"
    },
    {
      id: "chapter_two_collect_materials",
      label: `凑齐恢复材料（${proofCount}/3）`,
      hints: [
        "照片、座位夹缝和体艺都能帮上忙。",
        "照片曝光了就把光调小（控制中心光条）",
        "体艺 7,47,3"
      ],
      targetSurface: "phone",
      recommendedScene: "phone_home"
    },
    {
      id: "chapter_two_make_post_visible",
      label: "让帖子被看见",
      hints: ["3027，为什么自己想"],
      targetSurface: "phone",
      recommendedScene: "cc98"
    },
    {
      id: "chapter_two_submit_recovery",
      label: "提交恢复申请",
      hints: ["在浙大钉->图书馆->pass申请"],
      targetSurface: "phone",
      recommendedScene: "zjuding"
    },
    {
      id: "chapter_two_return_022",
      label: "回到 022",
      hints: ["字面意思。"],
      targetSurface: "rpg"
    }
  ];

  let currentIndex = 0;
  if (state.ui.libraryFinalsPhase === "recovery_application") {
    currentIndex = 5;
  } else if (["backpack_removed", "seat_recovered"].includes(state.ui.libraryFinalsPhase)
    || (state.ui.libraryFinalsPhase === "pass_ready" && puzzle.passBriefingSeen)) {
    currentIndex = 6;
  } else if (puzzle.preBdBriefingSeen) {
    // 十大成功后的管理员剧情仍属于“让帖子被看见”，直到恢复申请真的打开。
    currentIndex = 4;
  } else if (puzzle.archivedRuleBriefingSeen) {
    // 四项证据上传后的系统说明仍属于“凑齐恢复材料”，说明结束才进入下一关。
    currentIndex = 3;
  } else if (puzzle.occupancyNoteCollected) {
    currentIndex = 2;
  } else if (puzzle.entranceRecordRead) {
    // 入馆演出是“去图书馆”的收尾；读取现场记录后才正式开始确认座位。
    currentIndex = 1;
  }
  return buildQuest("chapter_two", "恢复 022 座位", tasks, currentIndex);
}

function chapterThreeQuest(state: GameState): QuestViewModel {
  return buildQuest("chapter_three", "寻找借走记录的书", [{
    id: "chapter_three_book_hunt",
    label: state.bikeArcade.completed ? "第三章任务完成" : "打开求是潮，追上那本书",
    hints: ["新的游戏入口已出现在手机。", "目标距离与书上的编号有关。", "打开求是潮，完成骑行关卡。"],
    targetSurface: "phone",
    recommendedScene: "bike_arcade"
  }], 0);
}

export function isQuestTaskBarVisible(state: GameState): boolean {
  const chapter = selectFeatureAccess(state).chapter;
  if (chapter !== "chapter_two") return true;
  return ![
    "friend_message_required",
    "system_required"
  ].includes(state.actOne.phase);
}

export function selectQuestViewModel(state: GameState): QuestViewModel {
  const access = selectFeatureAccess(state);
  if (access.chapter === "chapter_one") return chapterOneQuest(state);
  if (access.chapter === "chapter_three") return chapterThreeQuest(state);
  if ([
    "friend_message_required",
    "system_required",
    "inventory_required",
    "system_return_required",
    "movement_required",
    "reservation_briefing_required",
    "reservation_required"
  ].includes(state.actOne.phase)) {
    return movementQuest(state);
  }
  return libraryQuest(state);
}
