import type { ChapterId, GameState, QuestStep, QuestViewModel, SceneId } from "./types";
import { selectFeatureAccess } from "./FeatureAccess";
import canteenContent from "../data/chapter3-canteen.content.json";
import theaterContent from "../data/chapter3-theater.content.json";
import qizhenContent from "../data/chapter3-qizhen-lake.content.json";
import clockContent from "../data/chapter4-clock.content.json";
import chapterFourContent from "../data/chapter4-temporal-maze.content.json";
import { selectChapterFourWechatObjective } from "../modules/ChapterFourWechatModel";

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
    return task("boarding", qizhenContent.quest.boarding, [
      qizhenContent.boarding.instruction,
      qizhenContent.boarding.sameSide
    ]);
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
    if (!lake.lockerOpened) {
      return state.items.rustedLockerKey
        ? task("open_locker", steps.openLocker.label, steps.openLocker.hints)
        : task("catch_key", steps.catchKey.label, steps.catchKey.hints);
    }
    if (!lake.netCombined) {
      return state.items.brokenNetFrame
        ? task("combine_net", steps.combineNet.label, steps.combineNet.hints)
        : task("catch_net_frame", steps.catchNetFrame.label, steps.catchNetFrame.hints);
    }
    if (!lake.feedTinRetrieved) {
      return task("retrieve_tin", steps.retrieveTin.label, steps.retrieveTin.hints);
    }
    if (!lake.feedTinOpened) {
      return task("open_tin", steps.openTin.label, steps.openTin.hints);
    }
    return task("catch_fish", steps.catchFish.label, steps.catchFish.hints);
  }
  if (lake.phase === "swan_exchange") {
    return task("feed_swan", qizhenContent.quest.swan, [
      qizhenContent.swan.feedPrompt,
      stripPrefix(qizhenContent.swan.combineHint)
    ]);
  }
  if (lake.phase === "paper_capture") {
    return lake.magneticRodCombined
      ? task("capture_paper", qizhenContent.quest.paper, steps.capturePaper.hints)
      : task("combine_magnetic_rod", steps.combineMagneticRod.label, steps.combineMagneticRod.hints);
  }
  if (lake.phase === "swan_chase") {
    return task("swan_chase", qizhenContent.quest.chase, [qizhenContent.chase.instruction]);
  }
  if (lake.phase === "complete") {
    return task("complete", qizhenContent.quest.complete);
  }
  return task(lake.phase, qizhenContent.quest.lake, qizhenContent.quest.lakeHints);
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
    return buildQuest("chapter_three", "启真湖追纸", [task], 0);
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
                    "靠近闸机右侧读票器并面向它。",
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
                        "靠近大厅左侧海报栏并面向玻璃。",
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
            label: theaterContent.program.task,
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
        ? {
            id: "chapter_three_canteen_intercept",
            label: canteenContent.task.replace(/^任务：/, ""),
            hints: canteenContent.hints,
            targetSurface: "rpg"
          }
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
  const interlude = state.chapterThreeInterlude;
  let task: TaskDefinition;

  if (!interlude.recoveryOpened || interlude.phase === "reboot") {
    task = {
      id: "chapter_three_interlude_reboot",
      label: "打开未同步记录",
      hints: ["手机刚收到一条 7 分 55 秒记录恢复通知。"],
      targetSurface: "phone",
      recommendedScene: "timeline_recovery"
    };
  } else if (!interlude.evidenceIds.includes("journal_start")) {
    task = {
      id: "chapter_three_interlude_journal",
      label: "在 CC98 确认离湖时间",
      hints: ["打开划船记录帖，保存最后一条离湖回复。"],
      targetSurface: "phone",
      recommendedScene: "cc98"
    };
  } else if (!interlude.photoSequenceSolved) {
    task = {
      id: "chapter_three_interlude_photos",
      label: "按方向整理三张恢复照片",
      hints: ["在照片中依次选择纸条位于左侧、中间、右侧的画面。"],
      targetSurface: "phone",
      recommendedScene: "photos"
    };
  } else if (!interlude.voiceSequenceSolved) {
    task = {
      id: "chapter_three_interlude_voice",
      label: "整理四段夜间录音",
      hints: ["按湖面、石岸、大厅、闭楼广播的顺序排列。"],
      targetSurface: "phone",
      recommendedScene: "voice_memos"
    };
  } else if (!interlude.officialNoticeSaved || !interlude.routeScreenshotSaved) {
    task = {
      id: "chapter_three_interlude_wechat",
      label: "保存闭楼通知和入口截图",
      hints: ["微信中有一条楼宇公众号通知和一张群聊路线截图。"],
      targetSurface: "phone",
      recommendedScene: "wechat"
    };
  } else if (!interlude.networkRecordRead) {
    task = {
      id: "chapter_three_interlude_network",
      label: "核对教学楼接入点记录",
      hints: ["在浙大钉中筛出缺口末段、未知设备和三秒短会话。"],
      targetSurface: "phone",
      recommendedScene: "zjuding"
    };
  } else if (interlude.destinationId !== "duan_yongping_a1") {
    task = {
      id: "chapter_three_interlude_timeline",
      label: "排除旧时间并恢复完整路线",
      hints: ["回到记录恢复，先排除三条旧时间，再按发生顺序放入四项证据。"],
      targetSurface: "phone",
      recommendedScene: "timeline_recovery"
    };
  } else {
    task = {
      id: "chapter_three_interlude_replay",
      label: "播放恢复回放",
      hints: ["已确认目的地为段永平教学楼 A 楼一层。"],
      targetSurface: "phone",
      recommendedScene: "timeline_recovery"
    };
  }

  return buildQuest("chapter_three", "未同步的七分五十五秒", [task], 0);
}

function chapterFourQuest(state: GameState): QuestViewModel {
  const chapter = state.chapter4;
  const wechatObjective = selectChapterFourWechatObjective(chapter);
  const phaseObjectives = chapterFourContent.phaseObjectives as Record<GameState["chapter4"]["phase"], string>;
  const clockPhase = chapter.phase === "clock_phase_lock";
  const completed = chapter.completed || chapter.phase === "complete";
  const label = wechatObjective?.label
    ?? phaseObjectives[chapter.phase]
    ?? chapterFourContent.arrival.objective;
  return {
    id: "chapter_four_temporal_maze",
    chapter: "chapter_four",
    title: chapterFourContent.title,
    objective: label,
    completed: completed ? 13 : chapter.solvedPuzzleIds.length,
    total: 13,
    steps: [{
      id: `chapter_four_${chapter.phase}`,
      label,
      status: completed ? "completed" : "active"
    }],
    hints: wechatObjective ? [wechatObjective.hint] : selectChapterFourHints(state),
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

function selectChapterFourHints(state: GameState): string[] {
  const chapter = state.chapter4;
  if (chapter.completed || chapter.phase === "complete") return [];
  if (chapter.phase === "clock_phase_lock") {
    const clock = state.clockCalibration;
    return [clockContent.quest.hints[clock.step]];
  }
  if (chapter.phase === "elevator_track_sync") {
    return [
      !chapter.elevatorHistoryObserved
        ? chapterFourContent.elevator.observePrompt
        : chapter.elevatorTrackAligned
          ? chapterFourContent.elevator.aligned
          : chapterFourContent.elevator.operatePrompt
    ];
  }
  if (chapter.airflowObserved && chapter.phase === "airflow_overlay") {
    return [chapterFourContent.airflow.lightPrompt];
  }
  if (chapter.phase === "arrival" || chapter.phase === "airflow_overlay") {
    return [chapterFourContent.arrival.hint];
  }
  if (chapter.phase === "npc_schedule_route") {
    return [chapterFourContent.threeFloorMaze.schedule.observePrompt];
  }
  if (chapter.phase === "corridor_bay_reconstruction") {
    return [chapterFourContent.threeFloorMaze.corridor.operatePrompt];
  }
  if (chapter.phase === "wayfinding_fragment_board") {
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
  if (chapter.phase === "bridge_floor_discrimination") {
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
