import type { ChapterId, GameState, QuestStep, QuestViewModel, SceneId } from "./types";
import { selectFeatureAccess } from "./FeatureAccess";
import canteenContent from "../data/chapter3-canteen.content.json";
import theaterContent from "../data/chapter3-theater.content.json";
import qizhenContent from "../data/chapter3-qizhen-lake.content.json";
import clockContent from "../data/chapter4-clock.content.json";
import chapterFour755Content from "../data/chapter4-755.content.json";
import chapterFourContent from "../data/chapter4-temporal-maze.content.json";
import { selectChapterFourWechatObjective } from "../modules/ChapterFourWechatModel";
import { selectChapterThreeInterludeViewModel } from "../modules/ChapterThreeInterludeModel";
import { selectChapterFourStagePresentation } from "../modules/ChapterFourStagePresentation";
import {
  ROOM204_GROUP_ORDER,
  countCompletedRoom204Groups
} from "../scenes/rpg/ChapterFourRoom204Model";

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
  const quest = buildQuest("chapter_one", "五分钟", tasks, currentIndex);
  if (currentIndex !== 1) return quest;
  const branches = [
    { id: "checkin_digit", label: "签到校园卡", detail: state.digits.d1 ? `数字 ${state.digits.d1}` : "签到页", complete: Boolean(state.digits.d1), recommendedScene: "checkin" },
    { id: "tiyi_digit", label: "浙大体艺", detail: state.digits.d2 ? `数字 ${state.digits.d2}` : "应用异常", complete: Boolean(state.digits.d2), recommendedScene: "tiyi" },
    { id: "settings_digit", label: "设置齿轮", detail: state.digits.d3 ? `数字 ${state.digits.d3}` : "设置页", complete: Boolean(state.digits.d3), recommendedScene: "settings" },
    { id: "bonsai_digit", label: "盆栽机关", detail: state.digits.d4 ? `数字 ${state.digits.d4}` : "主页盆栽", complete: Boolean(state.digits.d4), recommendedScene: "bonsai" }
  ] as const;
  return {
    ...quest,
    parallelProgress: { completed: digitCount, total: branches.length },
    parallelBranches: branches.map((branch) => ({
      id: branch.id,
      label: branch.label,
      detail: branch.detail,
      status: branch.complete ? "completed" : "pending",
      targetSurface: "phone",
      recommendedScene: branch.recommendedScene
    }))
  };
}

function movementQuest(state: GameState): QuestViewModel {
  const inventoryTaskActive = ["inventory_required", "system_return_required"].includes(state.actOne.phase);
  const directionTask: TaskDefinition = !state.actOne.pushTriangleTaken && !state.actOne.weatherWaterTaken
    ? {
        id: "chapter_two_direction_collect_materials",
        label: "收集三角形与天气水滴",
        hints: [
          "主页的「方向校准」与天气页面各有一项变化，两边可以分别检查。",
          "取得顺序不影响后续组合。"
        ],
        targetSurface: "phone",
        recommendedScene: "phone_home"
      }
    : !state.actOne.pushTriangleTaken
      ? {
          id: "chapter_two_direction_collect_triangle",
          label: "查看主页的「方向校准」推送",
          hints: ["连续检查推送头像边缘，取下松动的三角形。"],
          targetSurface: "phone",
          recommendedScene: "phone_home"
        }
      : !state.actOne.weatherWaterTaken
        ? {
            id: "chapter_two_direction_collect_weather_water",
            label: "从天气页面取得天气水滴",
            hints: ["打开天气页面，收集已经出现的水滴。"],
            targetSurface: "phone",
            recommendedScene: "weather"
          }
        : !state.actOne.mentorLineReleased
          ? {
              id: "chapter_two_direction_release_mentor_line",
              label: "用天气水滴处理导师头像",
              hints: ["打开微信，把天气水滴拖到导师头像边缘的黏着竖线。"],
              targetSurface: "phone",
              recommendedScene: "wechat"
            }
          : !state.actOne.rightArrowAssembled
            ? {
                id: "chapter_two_direction_assemble_arrow",
                label: "组合三角形与竖线",
                hints: ["在道具栏中将主页三角形与导师头像掉落的竖线组合。"],
                targetSurface: "phone",
                recommendedScene: "phone_home"
              }
            : !state.actOne.balanceShifted
              ? {
                  id: "chapter_two_direction_shift_balance",
                  label: "用右移箭头调整校园卡余额",
                  hints: ["把右移箭头拖到电子校园卡的余额数字上。"],
                  targetSurface: "phone",
                  recommendedScene: "campus_card"
                }
              : !state.actOne.cc98Login.authenticated
                ? {
                    id: "chapter_two_cc98_unified_login",
                    label: "完成 CC98 首次身份认证",
                    hints: [
                      "先从随身校园卡读取 10 位学号。",
                      "密码按校名缩写、建校年份、结尾标点三段拼接。"
                    ],
                    targetSurface: "phone",
                    recommendedScene: "cc98"
                  }
                : !state.actOne.gamepadPurchased
                ? {
                    id: "chapter_two_direction_purchase_gamepad",
                    label: "去 CC98 购买游戏手柄",
                    hints: ["打开 CC98 二手交易，用调整后的校园卡余额付款。"],
                    targetSurface: "phone",
                    recommendedScene: "cc98"
                  }
                : !state.actOne.controlsInstalled
                  ? {
                      id: "chapter_two_direction_install_gamepad",
                      label: "把游戏手柄安装到寝室角色",
                      hints: ["返回寝室，把道具栏里的游戏手柄拖到角色身上。"],
                      targetSurface: "rpg"
                    }
                  : !state.actOne.manualControlTested
                    ? {
                        id: "chapter_two_direction_test_controls",
                        label: "完成第一次手动移动",
                        hints: ["使用方向键移动一次，确认手柄已经生效。"],
                        targetSurface: "rpg"
                      }
                    : {
                        id: "chapter_two_direction_confirmed",
                        label: "确认方向控制已经生效",
                        hints: [],
                        targetSurface: "rpg"
                      };
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
    directionTask,
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
  const quest = buildQuest("chapter_two", "找到移动的办法", tasks, currentIndex);
  if (!["chapter_two_direction_collect_materials", "chapter_two_direction_collect_triangle", "chapter_two_direction_collect_weather_water"]
    .includes(directionTask.id)) return quest;
  const branches = [
    {
      id: "direction_triangle",
      label: "主页方向校准",
      detail: "松动三角形",
      complete: state.actOne.pushTriangleTaken,
      recommendedScene: "phone_home"
    },
    {
      id: "weather_water",
      label: "天气页面",
      detail: "天气水滴",
      complete: state.actOne.weatherWaterTaken,
      recommendedScene: "weather"
    }
  ] as const;
  return {
    ...quest,
    parallelProgress: {
      completed: branches.filter((branch) => branch.complete).length,
      total: branches.length
    },
    parallelBranches: branches.map((branch) => ({
      id: branch.id,
      label: branch.label,
      detail: branch.detail,
      status: branch.complete ? "completed" : "pending",
      targetSurface: "phone",
      recommendedScene: branch.recommendedScene
    }))
  };
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
  if (["top_ten_reached", "recovery_application"].includes(state.ui.libraryFinalsPhase)) {
    currentIndex = 5;
  } else if (["backpack_removed", "seat_recovered"].includes(state.ui.libraryFinalsPhase)
    || (state.ui.libraryFinalsPhase === "pass_ready" && puzzle.passBriefingSeen)) {
    currentIndex = 6;
  } else if (puzzle.preBdBriefingSeen) {
    // BD 说明完成后仍停留在帖子任务；进入十大后立即转到恢复材料页。
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

function qizhenTaskForLakePhase(state: GameState): TaskDefinition {
  const lake = state.qizhenLake;
  const task = (suffix: string, label: string, hints: readonly string[] = []): TaskDefinition => ({
    id: `chapter_three_qizhen_${suffix}`,
    label,
    hints,
    targetSurface: "rpg"
  });
  const stripPrefix = (text: string): string => text.replace(/^任务：/, "");
  const steps = qizhenContent.quest.steps;

  if (lake.phase === "dock_outfitting") {
    const hint = !lake.kayakEquipped
      ? qizhenContent.dock.kayakHint
      : !lake.leftPaddleEquipped
        ? qizhenContent.dock.leftPaddleHint
        : qizhenContent.dock.rightPaddleHint;
    return task("dock_outfitting", qizhenContent.quest.dock, [hint, stripPrefix(qizhenContent.dock.outfitPrompt)]);
  }
  if (lake.phase === "boarding_tutorial") {
    if (!lake.rainSafetyCleared && !lake.rainWarningSeen) {
      return task("weather_request", "确认能否下水", [
        "器材收齐后，去小码头找值班老师确认。"
      ]);
    }
    if (!lake.rainSafetyCleared && !lake.rainRescueCompleted) {
      return task("rain_launch", "再次尝试登船", [
        "回到皮划艇旁。"
      ]);
    }
    return task("boarding", qizhenContent.quest.boarding, [
      qizhenContent.boarding.instruction,
      qizhenContent.boarding.sameSide
    ]);
  }
  if (lake.phase === "rain_recovery") {
    if (!state.items.hairDryer) {
      return task("hair_dryer", "在寝室找一件能用的设备", [
        "检查自己的书桌。"
      ]);
    }
    return {
      ...task("weather_adjustment", "处理启真湖的天气记录", [
        "打开手机天气页面。"
      ]),
      targetSurface: "phone"
    };
  }
  if (lake.phase === "lake_exploration") {
    if (!lake.reflectionLocationObserved) {
      return task("observe_reflection", qizhenContent.quest.observe, [
        qizhenContent.lake.darkPrompt,
        qizhenContent.reflection.lightWater
      ]);
    }
    if (!lake.rodFound) {
      return task("find_rod", steps.findRod.label, steps.findRod.hints);
    }
    return task("attach_decoy", steps.attachDecoy.label, steps.attachDecoy.hints);
  }
  if (lake.phase === "tool_chain") {
    const branchCount = [
      lake.lockerOpened,
      state.items.brokenNetFrame || lake.netCombined,
      lake.swanFed
    ]
      .filter(Boolean).length;
    if (branchCount < 3) {
      return task("parallel_tool_branches", `完成湖区三处分支 ${branchCount}/3`, [
        lake.lockerOpened ? "码头柜门：已取得尼龙绳。" : "码头柜门：钓起钥匙并打开柜门。",
        state.items.brokenNetFrame || lake.netCombined ? "浮排分支：已取得破损网框。" : "浮排分支：在直河道钓起破损网框。",
        lake.swanFed ? "天鹅分支：已取得磁性扣。" : "天鹅分支：前往围栏处理旧饲料盒。",
        "三个分支可以任意顺序完成。"
      ]);
    }
    return task("combine_final_rig", "合并三处分支材料", [
      "返回大湖面的最终钓具装配位。",
      "将尼龙绳、破损网框、磁性扣和钓鱼竿放入装配位。"
    ]);
  }
  if (lake.phase === "swan_exchange") {
    return task("feed_swan", qizhenContent.quest.swan, [
      qizhenContent.swan.feedPrompt,
      stripPrefix(qizhenContent.swan.combineHint)
    ]);
  }
  if (lake.phase === "paper_capture") {
    return task("capture_paper", qizhenContent.quest.paper, steps.capturePaper.hints);
  }
  if (lake.phase === "swan_chase") {
    return task("swan_chase", qizhenContent.quest.chase, [qizhenContent.chase.instruction]);
  }
  if (lake.phase === "complete") {
    return task("complete", qizhenContent.quest.complete);
  }
  return task(lake.phase, qizhenContent.quest.lake, qizhenContent.quest.lakeHints);
}

function canteenInteriorTask(state: GameState): TaskDefinition {
  const hunt = state.canteenHunt;
  const task = (id: string, label: string, hints: readonly string[] = []): TaskDefinition => ({
    id: `chapter_three_canteen_${id}`,
    label,
    hints,
    targetSurface: "rpg"
  });
  const returnedTargetTrays = hunt.returnedTrayIds.filter((id) => id.startsWith("tray_blue_")).length;

  if (!hunt.entryPaperEscaped) {
    return task("paper_entry", "靠近食堂里的异常纸条", ["纸条停在入口附近，靠近后会继续移动。"]);
  }
  if (!hunt.trayTaskStarted) {
    return task("tray_start", "与收餐口阿姨交谈", ["先完成餐盘回收，取得后续行动需要的零钱和纸巾。"]);
  }
  if (returnedTargetTrays < 3) {
    return task(
      "tray_return",
      `找出并交回带污渍的餐盘（${returnedTargetTrays}/3）`,
      ["深色观察可辨认蓝光和油渍；浅色操作可直接拿起餐盘并交给收餐口阿姨。", "一次只能搬一个餐盘。"]
    );
  }
  if (!hunt.queueGapOpened) {
    if (!hunt.queueChallengeSeen) {
      return task("queue", "查看第三列队伍和新品宣传板", ["与排队学生交谈，确认怎样让第三列队伍移动。"]);
    }
    if (!hunt.drinkShelfRead) {
      return task("drink_shelf", "查看饮料货架的颜色顺序", ["货架从左到右的颜色决定调配顺序。"]);
    }
    if (!state.items.dailySpecialSparklingWater && !hunt.promoDrinkPlaced) {
      return task(
        "drink_mix",
        `按货架顺序调配今日新品（${hunt.drinkMixSequence.length}/3）`,
        ["从饮料机取得三种饮料，再到调配台按黑色、蓝色、白色依次倒入。"]
      );
    }
    if (!hunt.promoDrinkPlaced) {
      return task("promo_drop", "把今日新品气泡水放入宣传板空杯位", ["目标位在第三窗口宣传板下方。"]);
    }
    return task("queue_shift", "等待第三列队伍让出位置");
  }
  if (hunt.phase === "menu_order") {
    return task(
      "menu_order",
      "在点餐机选择纸包鸡",
      ["浅色操作可直接点餐；深色观察可补充读取异常菜单文字。", "点餐后会取得 0755 取餐号。"]
    );
  }
  if (hunt.phase === "pickup_search") {
    return task(
      "pickup",
      "把 0755 取餐号交给 3 号窗口",
      ["浅色操作可直接交票；深色观察可补充查看 3 号窗口残影。"]
    );
  }
  if (hunt.phase === "exit_blocking") {
    return task(
      "exit_blocking",
      `守住纸条可能逃离的出口（${hunt.blockHits}/3）`,
      ["浅色操作可推动当前路线上的餐盘车；深色观察可补充确认蓝色轨迹。", "空格键可以冲刺；纸条回头时路线会再次出现。"]
    );
  }
  return task("unlock_bike", canteenContent.bike.task.replace(/^任务：/, ""), canteenContent.bike.hints);
}

function chapterThreeQuest(state: GameState): QuestViewModel {
  if (state.qizhenLake.active) {
    const mapCluesReady = (["bridge", "reflection", "lake"] as const)
      .every((clueId) => state.qizhenLake.mapClueIds.includes(clueId));
    const task: TaskDefinition = state.qizhenLake.phase === "location_search"
      ? mapCluesReady
        ? {
            id: "chapter_three_qizhen_location_confirm",
            label: "在校园地图核对地点交点",
            hints: [
              "三条地点记录已接入。",
              "打开浙大钉的校园地图，完成最后核对。"
            ],
            targetSurface: "phone",
            recommendedScene: "zjuding"
          }
        : {
          id: "chapter_three_qizhen_location",
          label: theaterContent.completionTask.label,
          hints: theaterContent.completionTask.hints,
          targetSurface: "phone",
          recommendedScene: "phone_home"
        }
      : state.qizhenLake.phase === "lake_unlocked"
        ? {
            id: "chapter_three_qizhen_gate",
            label: "从校园地图前往启真湖",
            hints: ["手机地图已确认地点。", "进入大地图后走到启真湖入口。"],
            targetSurface: "phone",
            recommendedScene: "zjuding"
          }
        : qizhenTaskForLakePhase(state);
    const quest = buildQuest("chapter_three", "启真湖追纸", [task], 0);
    if (state.qizhenLake.phase !== "tool_chain" || !task.id.endsWith("parallel_tool_branches")) {
      return quest;
    }
    const branches = [
      {
        id: "dock_locker",
        label: "码头柜门",
        detail: "钥匙与尼龙绳",
        complete: state.qizhenLake.lockerOpened
      },
      {
        id: "channel_raft",
        label: "直河浮排",
        detail: "破损网框",
        complete: state.items.brokenNetFrame || state.qizhenLake.netCombined
      },
      {
        id: "swan_cove",
        label: "天鹅围栏",
        detail: "饲料与磁性扣",
        complete: state.qizhenLake.swanFed
      }
    ] as const;
    return {
      ...quest,
      parallelProgress: {
        completed: branches.filter((branch) => branch.complete).length,
        total: branches.length
      },
      parallelBranches: branches.map((branch) => ({
        id: branch.id,
        label: branch.label,
        detail: branch.detail,
        status: branch.complete ? "completed" : "pending",
        targetSurface: "rpg"
      }))
    };
  }
  if (state.theaterHunt.active) {
    const task: TaskDefinition = state.theaterHunt.phase === "entry_ticket"
      ? state.theaterHunt.cc98TicketCommissionPhase === "posted"
        ? {
            id: "chapter_three_theater_ticket_commission",
            label: "去 CC98 接下学生剧现场帮抢委托",
            hints: [
              "手机 CC98 出现了一条学生剧临时退票求助帖。",
              "接单后再到剧院大厅确认取票时间。"
            ],
            targetSurface: "phone",
            recommendedScene: "cc98"
          }
        : state.theaterHunt.cc98TicketCommissionPhase === "accepted"
          ? !state.theaterHunt.ticketCodeRead
            ? {
                id: "chapter_three_theater_ticket_read_time",
                label: "在剧院大厅确认 08:32 放票时间",
                hints: [
                  "在深色观察中靠近取票机，读取屏幕残影。",
                  "确认时间后回到手机 CC98 帖子参加第一波。"
                ],
                targetSurface: "rpg"
              }
            : {
                id: "chapter_three_theater_ticket_first_wave",
                label: "在手机 CC98 票务页参加第一波放票",
                hints: [
                  "打开学生剧现场帮抢帖，在票务卡中操作。",
                  "可以直接抢第一波，也可以先打开控制中心切换到移动数据。"
                ],
                targetSurface: "phone",
                recommendedScene: "cc98"
              }
          : state.theaterHunt.cc98TicketCommissionPhase === "first_wave_failed"
            ? state.networkMode === "cellular"
              ? {
                  id: "chapter_three_theater_ticket_second_wave",
                  label: "在手机票务页参加第二波放票",
                  hints: [
                    "移动数据已经开启。",
                    "回到 CC98 帮抢帖，等待倒计时结束后点击第二波。"
                  ],
                  targetSurface: "phone",
                  recommendedScene: "cc98"
                }
              : {
                  id: "chapter_three_theater_ticket_enable_cellular",
                  label: "开启手机移动数据，等待第二波放票",
                  hints: [
                    "第一波已结束，系统提示响应速度过慢。",
                    "在 CC98 票务卡中打开控制中心，切换为移动数据。"
                  ],
                  targetSurface: "phone",
                  recommendedScene: "cc98"
                }
          : state.theaterHunt.cc98TicketCommissionPhase === "delivered"
            ? state.items.temporaryTheaterTicket
              ? {
                  id: "chapter_three_theater_admission",
                  label: "把临时观演票交给检票闸机",
                  hints: [
                    "靠近闸机右侧的读票器。",
                    "把道具栏里的临时观演票拖到读票器的发光框内。"
                  ],
                  targetSurface: "rpg"
                }
              : state.items.theaterTicketHalfA && state.items.theaterTicketHalfB
                ? {
                    id: "chapter_three_theater_combine_ticket",
                    label: "合成两张半票根",
                    hints: ["在道具栏中将半张票根 A 与半张票根 B 组合。"],
                    targetSurface: "rpg"
                  }
                : !state.items.theaterTicketHalfB
                  ? {
                      id: "chapter_three_theater_print_ticket",
                      label: "去剧院取票机打印半张票根 B",
                      hints: [
                        "手机抢票已经成功，订单取票码是 0832。",
                        "在浅色操作中靠近取票机，输入取票码打印实体票根。"
                      ],
                      targetSurface: "rpg"
                    }
                  : !state.items.theaterTicketHalfA
                  ? {
                      id: "chapter_three_theater_find_half_a",
                      label: "从入口海报栏取得半张票根 A",
                      hints: [
                        "靠近大厅左侧的海报玻璃。",
                        "把去油纸巾拖到海报玻璃的发光区域。"
                      ],
                      targetSurface: "rpg"
                    }
                  : {
                      id: "chapter_three_theater_recover_ticket",
                      label: "确认两张半票根",
                      hints: ["打开道具栏确认票根 A 与票根 B，再完成组合。"],
                      targetSurface: "rpg"
                    }
          : {
              id: "chapter_three_theater_ticket",
              label: theaterContent.entryTask.label,
              hints: theaterContent.entryTask.hints,
              targetSurface: "rpg"
            }
      : state.theaterHunt.phase === "program_search"
        ? {
            id: "chapter_three_theater_program",
            label: theaterContent.program.task.replace(/[。！？]$/, ""),
            hints: [theaterContent.program.consolePrompt, theaterContent.program.consoleState],
            targetSurface: "rpg"
          }
        : state.theaterHunt.phase === "prop_setup"
          ? {
              id: "chapter_three_theater_prop",
              label: theaterContent.prop.task,
              hints: [theaterContent.prop.ghost, theaterContent.prop.managerHint],
              targetSurface: "rpg"
            }
          : state.theaterHunt.phase === "spotlight_ready"
            ? {
                id: "chapter_three_theater_spotlight_ready",
                label: theaterContent.spotlight.readyHint,
                hints: [theaterContent.spotlight.task],
                targetSurface: "rpg"
              }
            : state.theaterHunt.phase === "spotlight_hunt"
              ? {
                  id: "chapter_three_theater_spotlight",
                  label: `追光第 ${Math.min(state.theaterHunt.spotlightRound + 1, 3)} / 3 轮：观察轨迹，预置灯位并持续照射`,
                  hints: [
                    `已完成 ${state.theaterHunt.spotlightRound} / 3 轮，失败只重试当前轮。`,
                    theaterContent.spotlight.preview,
                    theaterContent.spotlight.choose,
                    theaterContent.spotlight.controlHint
                  ],
                  targetSurface: "rpg"
                }
              : state.theaterHunt.phase === "reversal"
                ? {
                    id: "chapter_three_theater_reversal",
                    label: "查看追光灯下的纸条",
                    hints: [theaterContent.spotlight.reversal],
                    targetSurface: "rpg"
                  }
            : {
                id: "chapter_three_theater_next_stop",
                label: theaterContent.completionTask.label,
                hints: theaterContent.completionTask.hints,
                targetSurface: "phone"
              };
    return buildQuest("chapter_three", "剧院追纸", [task], 0);
  }
  if (state.canteenHunt.active) {
    const task: TaskDefinition = state.canteenHunt.phase === "tracking"
      ? {
          id: "chapter_three_reach_east_canteen",
          label: "追到东区大食堂",
          hints: ["沿校园地图中留下的脚印前往东区大食堂。"],
          targetSurface: "rpg"
        }
      : ["canteen_reached", "tray_search", "drink_mix", "menu_order", "pickup_search", "exit_blocking", "entered"].includes(state.canteenHunt.phase)
        ? canteenInteriorTask(state)
        : state.canteenHunt.phase === "theater_reached"
          ? {
              id: "chapter_three_theater_reached",
              label: canteenContent.theaterTask.label,
              hints: canteenContent.theaterTask.hints,
              targetSurface: "rpg"
            }
          : state.canteenHunt.phase === "chasing"
            ? {
                id: "chapter_three_canteen_chase",
                label: canteenContent.trackingTask.label,
                hints: canteenContent.trackingTask.hints,
                targetSurface: "rpg"
              }
          : {
              id: "chapter_three_unlock_bike",
              label: canteenContent.bike.task.replace(/^任务：/, ""),
              hints: canteenContent.bike.hints,
              targetSurface: "rpg"
            };
    return buildQuest("chapter_three", "追到东区大食堂", [task], 0);
  }
  return buildQuest("chapter_three", "追到东区大食堂", [{
    id: "chapter_three_reach_east_canteen",
    label: "追到东区大食堂",
    hints: ["沿校园地图中留下的脚印前往东区大食堂。"],
    targetSurface: "rpg"
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

function chapterThreeInterludeQuest(state: GameState): QuestViewModel {
  const viewModel = selectChapterThreeInterludeViewModel(state);
  const quest = buildQuest("chapter_three", viewModel.title, [viewModel.currentObjective], 0);
  if (viewModel.currentObjective.id !== "chapter_three_interlude_evidence") return quest;
  return {
    ...quest,
    parallelProgress: viewModel.branchProgress,
    parallelBranches: viewModel.parallelBranches.map((branch) => ({
      id: branch.id,
      label: branch.label,
      status: branch.completed ? "completed" : "pending",
      recommendedScene: branch.recommendedScene
    }))
  };
}

interface ChapterFour755PhaseTaskContract {
  id: string;
  taskKeys: readonly string[];
}

interface ChapterFour755TaskCopy {
  label: string;
  hints: readonly string[];
}

const CHAPTER_FOUR_755_PHASE_TASK_CONTRACTS =
  chapterFour755Content.phaseContracts as readonly ChapterFour755PhaseTaskContract[];
const CHAPTER_FOUR_755_TASKS =
  chapterFour755Content.tasks as Readonly<Record<string, ChapterFour755TaskCopy>>;

function selectChapterFour755TaskKey(
  state: GameState,
  contract: ChapterFour755PhaseTaskContract
): string {
  const facts = new Set(state.chapter4.factIds);
  let preferredTaskKey = contract.taskKeys[0];
  if (contract.id === "bakery_hour_hand") {
    preferredTaskKey = state.items.oldClockHourHand
      || facts.has("bakery_hour_hand_collected")
      || facts.has("hour_hand_installed")
      ? "install_hour_hand"
      : facts.has("bakery_hour_hand_exposed")
        ? "collect_hour_hand"
        : "explore_bakery";
  } else if (contract.id === "room204_restore") {
    preferredTaskKey = !facts.has("classroom_104_chalk_residual_observed")
      || !facts.has("classroom_105_terminal_replay_checked")
      || !facts.has("elevator_history_observed")
        || !facts.has("elevator_history_calibrated")
        || !facts.has("a1_duty_board_reconstructed")
      ? "resolve_a1_investigation"
      : !facts.has("a3_reference_observed")
        ? "resolve_a3_archive_chain"
      : !facts.has("misaligned_stair_solved")
        ? "solve_misaligned_stair"
      : !facts.has("a2_positioning_plate_calibrated")
        || !facts.has("a2_power_topology_recovered")
        || !facts.has("a2_evacuation_route_confirmed")
        ? "resolve_a2_inserted_puzzles"
      : !facts.has("elevator_stop_chain_reconstructed")
        ? "resolve_elevator_stop_chain"
      : !facts.has("room204_residual_observed")
        || !facts.has("room204_restored")
          ? "restore_room204"
          : !facts.has("room204_projection_completed")
            ? "watch_room204_projection"
            : !facts.has("positioning_plate_collected")
              ? "collect_positioning_plate"
              : "install_positioning_plate";
  } else if (contract.id === "maintenance_repair") {
    preferredTaskKey = !facts.has("cart_wheel_inspected")
      ? "inspect_cart_wheel"
      : !facts.has("cart_wheel_cover_opened")
        ? "open_cart_wheel_cover"
        : !facts.has("cart_wheel_repaired") || !facts.has("clock_gear_repaired")
          ? "lubricate_cart_wheel"
          : "turn_clock_to_0755";
  } else if (contract.id === "return_to_clock") {
    preferredTaskKey = state.chapter4.floor === "A1"
      ? "install_final_minute"
      : "return_via_main_stair";
  } else if (contract.id === "exterior_closure") {
    preferredTaskKey = facts.has("zhu_two_questions_answered")
      ? "acknowledge_exterior_closure"
      : "answer_zhu_two_questions";
  } else if (contract.id === "morning_checkin") {
    const cardAccepted = state.chapter4.checkinCardAccepted
      && facts.has("checkin_card_accepted");
    const paperAccepted = state.chapter4.checkinPaperAccepted
      && facts.has("checkin_paper_accepted");
    preferredTaskKey = cardAccepted && !paperAccepted
      ? "submit_attendance_paper"
      : paperAccepted && !cardAccepted
        ? "read_campus_card"
        : "complete_checkin";
  }
  return contract.taskKeys.includes(preferredTaskKey)
    ? preferredTaskKey
    : contract.taskKeys[0];
}

function chapterFour755Quest(
  state: GameState,
  contract: ChapterFour755PhaseTaskContract
): QuestViewModel {
  const phase = String(state.chapter4.phase);
  const facts = new Set(state.chapter4.factIds);
  const taskKey = selectChapterFour755TaskKey(state, contract);
  const task = CHAPTER_FOUR_755_TASKS[taskKey];
  const completed = state.chapter4.completed || phase === "complete";
  const label = task?.label ?? taskKey;
  const presentation = selectChapterFourStagePresentation(state);
  const quest: QuestViewModel = {
    id: "chapter_four_temporal_maze",
    chapter: "chapter_four",
    title: chapterFour755Content.title,
    objective: label,
    // Chapter 4 deliberately exposes one current action only. The internal
    // phase table remains controller data and must never leak its length into
    // the player-facing drawer.
    completed: completed ? 1 : 0,
    total: 1,
    // The drawer exposes only the current next objective. Future taskKeys stay
    // in the content contract and are selected only after facts/items advance.
    steps: [{
      id: `chapter_four_${taskKey}`,
      label,
      status: completed ? "completed" : "active"
    }],
    hints: task?.hints ?? [],
    targetSurface: "rpg",
    ...(presentation ? { chapterFourPresentation: presentation } : {})
  };
  if (taskKey === "resolve_a1_investigation"
    && (!facts.has("classroom_104_chalk_residual_observed")
      || !facts.has("classroom_105_terminal_replay_checked"))) {
    const branches = [
      {
        id: "a1_classroom_104",
        label: "104 黑板",
        detail: "擦痕残留",
        factId: "classroom_104_chalk_residual_observed"
      },
      {
        id: "a1_classroom_105",
        label: "105 讲台",
        detail: "本地回放",
        factId: "classroom_105_terminal_replay_checked"
      }
    ] as const;
    return {
      ...quest,
      parallelProgress: {
        completed: branches.filter((branch) => facts.has(branch.factId)).length,
        total: branches.length
      },
      parallelBranches: branches.map((branch) => ({
        id: branch.id,
        label: branch.label,
        detail: branch.detail,
        status: facts.has(branch.factId) ? "completed" : "pending",
        targetSurface: "rpg"
      }))
    };
  }
  if (taskKey === "resolve_a2_inserted_puzzles") {
    const branches = [
      {
        id: "a2_positioning",
        label: "201 定位板",
        detail: "三轴校准",
        factId: "a2_positioning_plate_calibrated"
      },
      {
        id: "a2_power",
        label: "203 配电箱",
        detail: "五区拓扑",
        factId: "a2_power_topology_recovered"
      },
      {
        id: "a2_evacuation",
        label: "开放自习区",
        detail: "疏散路线",
        factId: "a2_evacuation_route_confirmed"
      }
    ] as const;
    return {
      ...quest,
      parallelProgress: {
        completed: branches.filter((branch) => facts.has(branch.factId)).length,
        total: branches.length
      },
      parallelBranches: branches.map((branch) => ({
        id: branch.id,
        label: branch.label,
        detail: branch.detail,
        status: facts.has(branch.factId) ? "completed" : "pending",
        targetSurface: "rpg"
      }))
    };
  }
  if (taskKey === "resolve_elevator_stop_chain") {
    const branches = [
      {
        id: "elevator_record_a1",
        label: "1F 起行轨",
        detail: "门体与起行",
        factId: "elevator_history_observed"
      },
      {
        id: "elevator_record_a2",
        label: "2F 外呼日志",
        detail: "呼梯与门机",
        factId: "elevator_a2_call_record_observed"
      },
      {
        id: "elevator_record_a3",
        label: "3F 到站记录",
        detail: "铃声与开门",
        factId: "elevator_a3_arrival_record_observed"
      }
    ] as const;
    return {
      ...quest,
      parallelProgress: {
        completed: branches.filter((branch) => facts.has(branch.factId)).length,
        total: branches.length
      },
      parallelBranches: branches.map((branch) => ({
        id: branch.id,
        label: branch.label,
        detail: branch.detail,
        status: facts.has(branch.factId) ? "completed" : "pending",
        targetSurface: "rpg"
      }))
    };
  }
  if (taskKey === "restore_room204") {
    const completedGroupCount = countCompletedRoom204Groups(state.chapter4.room204Placements);
    const branches = [
      {
        id: "room204_reference",
        label: "303 晨间参照",
        detail: "浅色现场记录",
        complete: facts.has("a3_reference_observed")
      },
      {
        id: "room204_residual",
        label: "204 夜间残影",
        detail: "深色轮廓记录",
        complete: facts.has("room204_residual_observed")
      },
      {
        id: "room204_layout",
        label: "204 家具复原",
        detail: `${completedGroupCount}/${ROOM204_GROUP_ORDER.length} 组就位`,
        complete: completedGroupCount === ROOM204_GROUP_ORDER.length
      }
    ] as const;
    return {
      ...quest,
      parallelProgress: {
        completed: branches.filter((branch) => branch.complete).length,
        total: branches.length
      },
      parallelBranches: branches.map((branch) => ({
        id: branch.id,
        label: branch.label,
        detail: branch.detail,
        status: branch.complete ? "completed" : "pending",
        targetSurface: "rpg"
      }))
    };
  }
  if (["complete_checkin", "submit_attendance_paper", "read_campus_card"].includes(taskKey)) {
    const branches = [
      {
        id: "checkin_card",
        label: "校园卡读卡器",
        detail: "刷卡确认",
        complete: state.chapter4.checkinCardAccepted
          && facts.has("checkin_card_accepted")
      },
      {
        id: "checkin_paper",
        label: "签到纸插槽",
        detail: "纸条确认",
        complete: state.chapter4.checkinPaperAccepted
          && facts.has("checkin_paper_accepted")
      }
    ] as const;
    return {
      ...quest,
      parallelProgress: {
        completed: branches.filter((branch) => branch.complete).length,
        total: branches.length
      },
      parallelBranches: branches.map((branch) => ({
        id: branch.id,
        label: branch.label,
        detail: branch.detail,
        status: branch.complete ? "completed" : "pending",
        targetSurface: "rpg"
      }))
    };
  }
  return quest;
}

function chapterFourLegacyQuest(state: GameState): QuestViewModel {
  const chapter = state.chapter4;
  const wechatObjective = selectChapterFourWechatObjective(chapter);
  const phase = String(chapter.phase);
  const phaseObjectives = chapterFourContent.phaseObjectives as Record<string, string>;
  const clockPhase = phase === "clock_phase_lock";
  const completed = chapter.completed || phase === "complete";
  const label = wechatObjective?.label
    ?? phaseObjectives[phase]
    ?? chapterFourContent.arrival.objective;
  return {
    id: "chapter_four_temporal_maze",
    chapter: "chapter_four",
    title: chapterFourContent.title,
    objective: label,
    completed: completed ? 13 : chapter.solvedPuzzleIds.length,
    total: 13,
    steps: [{
      id: `chapter_four_${phase}`,
      label,
      status: completed ? "completed" : "active"
    }],
    hints: wechatObjective ? [wechatObjective.hint] : selectLegacyChapterFourHints(state),
    targetSurface: clockPhase || wechatObjective ? "phone" : "rpg",
    recommendedScene: clockPhase
      ? "clock"
      : wechatObjective?.id === "study_index"
        ? "cc98"
        : wechatObjective
          ? "wechat"
          : undefined
  };
}

function chapterFourQuest(state: GameState): QuestViewModel {
  const phase = String(state.chapter4.phase);
  const contract = CHAPTER_FOUR_755_PHASE_TASK_CONTRACTS.find((candidate) => candidate.id === phase);
  return contract ? chapterFour755Quest(state, contract) : chapterFourLegacyQuest(state);
}

function selectLegacyChapterFourHints(state: GameState): string[] {
  const chapter = state.chapter4;
  const phase = String(chapter.phase);
  if (chapter.completed || phase === "complete") return [];
  if (phase === "clock_phase_lock") {
    const clock = state.clockCalibration;
    return [clockContent.quest.hints[clock.step]];
  }
  if (phase === "elevator_track_sync") {
    return [
      !chapter.elevatorHistoryObserved
        ? chapterFourContent.elevator.observePrompt
        : chapter.elevatorTrackAligned
          ? chapterFourContent.elevator.aligned
          : chapterFourContent.elevator.operatePrompt
    ];
  }
  if (chapter.airflowObserved && phase === "airflow_overlay") {
    return [chapterFourContent.airflow.lightPrompt];
  }
  if (phase === "arrival" || phase === "airflow_overlay") {
    return [chapterFourContent.arrival.hint];
  }
  if (phase === "npc_schedule_route") {
    return [chapterFourContent.threeFloorMaze.schedule.observePrompt];
  }
  if (phase === "corridor_bay_reconstruction") {
    return [chapterFourContent.threeFloorMaze.corridor.operatePrompt];
  }
  if (phase === "wayfinding_fragment_board") {
    const fragmentsCollected = ["a2_fragment_west_collected", "a2_fragment_east_collected"]
      .every((clueId) => chapter.clueIds.includes(clueId));
    if (!fragmentsCollected) {
      return [chapterFourContent.threeFloorMaze.wayfinding.collectPrompt];
    }
    if (chapter.floor === "A2") {
      return ["回到交通核心，在仍有历史残影的楼层核对旧导视。"];
    }
    if (!chapter.clueIds.includes("a3_old_signage_observed")) {
      return [chapterFourContent.threeFloorMaze.wayfinding.observePrompt];
    }
    return [chapterFourContent.threeFloorMaze.wayfinding.alignPrompt];
  }
  if (phase === "bridge_floor_discrimination") {
    if (chapter.floor === "A2") {
      return [chapter.clueIds.includes("a2_return_window_open")
        ? chapterFourContent.threeFloorMaze.returnWindow.opened
        : chapterFourContent.threeFloorMaze.returnWindow.objective];
    }
    if (!chapter.clueIds.includes("a3_bridge_history_observed")) {
      return [chapterFourContent.threeFloorMaze.bridge.observePrompt];
    }
    return [chapterFourContent.threeFloorMaze.wayfinding.aligned];
  }
  return [];
}

export function selectQuestViewModel(state: GameState): QuestViewModel {
  const access = selectFeatureAccess(state);
  if (access.chapter === "chapter_one") return chapterOneQuest(state);
  if (state.qizhenLake.phase === "complete" && !state.chapterThreeInterlude.completed) {
    return chapterThreeInterludeQuest(state);
  }
  if (access.chapter === "chapter_four") return chapterFourQuest(state);
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
