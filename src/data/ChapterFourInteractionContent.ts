import type {
  ChapterFour755FloorId,
  ChapterFourPhase,
  ChapterFourRealityMode,
  ChapterFourTimeState
} from "../core/types";

export const CHAPTER_FOUR_CONTEXT_INTERACTION_TARGET_IDS = Object.freeze([
  "a1_front_desk_duty_board_context",
  "a2_maker_workshop_201_context",
  "a2_lecture_room_202_context",
  "a2_computer_room_203_context",
  "a2_open_study_evacuation_context",
  "a3_archive_exhibition_301_context",
  "a3_media_studio_302_context",
  "a3_report_hall_304_context"
] as const);

export type ChapterFourContextInteractionTargetId =
  typeof CHAPTER_FOUR_CONTEXT_INTERACTION_TARGET_IDS[number];

export type ChapterFourContextInteractionPurpose =
  | "environment"
  | "state_feedback"
  | "side_info"
  | "theme";

export interface ChapterFourContextInteractionContent {
  targetId: ChapterFourContextInteractionTargetId;
  label: string;
  floor: ChapterFour755FloorId;
  roomId: string;
  anchorId: string;
  activePhases: readonly ChapterFourPhase[];
  roomAliases: readonly string[];
  proximity?: number;
  purpose: ChapterFourContextInteractionPurpose;
  repeatPolicy: "repeatable";
  textByTimeState: Readonly<Record<
    ChapterFourTimeState,
    Readonly<Record<ChapterFourRealityMode, string>>
  >>;
}

const TIME_STATES = Object.freeze([
  "2245_opening",
  "1225_bakery",
  "1850_evening",
  "2245_maintenance",
  "0754_blackout",
  "0755_morning"
] as const satisfies readonly ChapterFourTimeState[]);

const MODE_KEYS = Object.freeze([
  "light",
  "dark"
] as const satisfies readonly ChapterFourRealityMode[]);

function defineContextInteraction(
  content: ChapterFourContextInteractionContent
): ChapterFourContextInteractionContent {
  for (const timeState of TIME_STATES) {
    for (const mode of MODE_KEYS) {
      if (content.textByTimeState[timeState][mode].trim().length === 0) {
        throw new Error(`Missing Chapter 4 context text: ${content.targetId}/${timeState}/${mode}`);
      }
    }
  }
  return Object.freeze(content);
}

function repeatedPuzzleText(
  light: string,
  dark: string
): Readonly<Record<ChapterFourTimeState, Readonly<Record<ChapterFourRealityMode, string>>>> {
  return Object.freeze(Object.fromEntries(TIME_STATES.map((timeState) => [
    timeState,
    Object.freeze({ light, dark })
  ])) as Record<ChapterFourTimeState, Readonly<Record<ChapterFourRealityMode, string>>>);
}

/**
 * Layout-backed contextual targets. Ordinary room targets remain read-only;
 * the six inserted puzzle targets launch their controller-owned overlay and
 * persist only after an explicit, validated solution. Reopening any target is
 * safe and never consumes an item. The current active phase reaches the 18:50
 * variant while the other authored time states stay available for later use.
 */
export const CHAPTER_FOUR_CONTEXT_INTERACTIONS = Object.freeze([
  defineContextInteraction({
    targetId: "a1_front_desk_duty_board_context",
    label: "打开前台值班签到板",
    floor: "A1",
    roomId: "a1_front_desk",
    anchorId: "a1_front_desk_duty_board",
    activePhases: ["room204_restore"],
    roomAliases: ["a1_hall_clock", "a1_lobby"],
    purpose: "state_feedback",
    repeatPolicy: "repeatable",
    textByTimeState: repeatedPuzzleText(
      "前台签到板留有三个空位，可以把已确认的值班牌放回去。",
      "三个夹痕的磨损不同，分别对应 104、105 与主电梯。"
    )
  }),
  defineContextInteraction({
    targetId: "a2_maker_workshop_201_context",
    label: "查看 201 创客工坊",
    floor: "A2",
    roomId: "a2_room_201",
    anchorId: "a2_201_calibration_bench",
    activePhases: ["room204_restore"],
    roomAliases: ["a2_corridor", "a2_room204", "a2_room_204"],
    purpose: "environment",
    repeatPolicy: "repeatable",
    textByTimeState: {
      "2245_opening": {
        light: "201 的工具已经归位，门边登记板停在晚间封闭状态。",
        dark: "操作台边缘保留着较早的手部动作残影，当前房间没有新增活动轨迹。"
      },
      "1225_bakery": {
        light: "午间工坊暂停开放，切割垫上压着尚未装配的校园模型。",
        dark: "模型零件周围有连续取放残影，时间间隔与午休人流一致。"
      },
      "1850_evening": {
        light: "晚课前的工坊已经清台，只有一台焊台仍显示余温警示。",
        dark: "焊台上方的动作残影在 18:50 前停止，随后没有人继续使用设备。"
      },
      "2245_maintenance": {
        light: "维修时段的总电源已经断开，工具柜保持封签状态。",
        dark: "工具柜没有被开启的残影，走廊异常并非来自这间工坊。"
      },
      "0754_blackout": {
        light: "应急照明只覆盖出口，工坊设备仍保持断电。",
        dark: "门口出现一段短暂停留残影，没有进入操作区。"
      },
      "0755_morning": {
        light: "晨间开放检查已完成，工具数量与登记表一致。",
        dark: "昨夜残影已经淡去，设备状态回到正常的早班记录。"
      }
    }
  }),
  defineContextInteraction({
    targetId: "a2_lecture_room_202_context",
    label: "查看 202 阶梯教室",
    floor: "A2",
    roomId: "a2_room_202",
    anchorId: "lecture_room_202",
    activePhases: ["room204_restore"],
    roomAliases: ["a2_corridor", "a2_room204", "a2_room_204"],
    purpose: "state_feedback",
    repeatPolicy: "repeatable",
    textByTimeState: {
      "2245_opening": {
        light: "202 的投影幕已经收起，阶梯座位按离场状态折叠。",
        dark: "最后一排到门口有一段连贯离场残影，讲台附近没有停留。"
      },
      "1225_bakery": {
        light: "午间讲座尚未开始，前排桌面摆着未发放的空白资料。",
        dark: "座位间只有短暂经过的残影，没有形成完整听课轨迹。"
      },
      "1850_evening": {
        light: "晚间教室已清空，投影机风扇刚停止，门槛处仍有散场脚印。",
        dark: "座位残影从前排向出口逐段消失，散场时间集中在 18:50 前后。"
      },
      "2245_maintenance": {
        light: "维修许可牌挂在门外，室内设备保持关机。",
        dark: "讲台投影区保留一段独立画面残留，与普通授课记录不连续。"
      },
      "0754_blackout": {
        light: "停电后安全出口灯正常，阶梯通道没有障碍物。",
        dark: "投影区残影仍在，亮度不随停电状态变化。"
      },
      "0755_morning": {
        light: "202 已完成晨检，投影和座椅等待第一节课。",
        dark: "夜间残留停止更新，教室回到正常的晨间时间轨。"
      }
    }
  }),
  defineContextInteraction({
    targetId: "a2_computer_room_203_context",
    label: "查看 203 计算机教室",
    floor: "A2",
    roomId: "a2_room_203",
    anchorId: "a2_203_circuit_terminal",
    activePhases: ["room204_restore"],
    roomAliases: ["a2_corridor", "a2_room204", "a2_room_204"],
    purpose: "side_info",
    repeatPolicy: "repeatable",
    textByTimeState: {
      "2245_opening": {
        light: "203 的终端已批量关机，教师机保留着当日维护清单。",
        dark: "屏幕前的残影按座位顺序消失，没有人在关机后返回。"
      },
      "1225_bakery": {
        light: "午间机房处于节能待机，靠门终端正在安装课程环境。",
        dark: "键盘上方的输入残影很短，属于自动部署前的检查动作。"
      },
      "1850_evening": {
        light: "晚课结束后终端已退出账号，第三排有一把椅子尚未推回。",
        dark: "第三排的离座残影比其他位置晚六秒，但随后直接离开机房。"
      },
      "2245_maintenance": {
        light: "机房交换机仍在线，学生终端全部断开。",
        dark: "网络指示残影连续，设备没有出现异常重启。"
      },
      "0754_blackout": {
        light: "后备电源只维持交换机，显示器和主机均已关闭。",
        dark: "设备断电时间一致，没有单独延迟的终端。"
      },
      "0755_morning": {
        light: "机房已按早课配置启动，座位状态与预约名单一致。",
        dark: "夜间设备残影已经结束，当前只有晨检人员的短时轨迹。"
      }
    }
  }),
  defineContextInteraction({
    targetId: "a2_open_study_evacuation_context",
    label: "检查 202 疏散路线板",
    floor: "A2",
    roomId: "a2_open_study",
    anchorId: "a2_open_study_evacuation",
    activePhases: ["room204_restore"],
    roomAliases: ["a2_corridor", "a2_room204", "a2_room_204"],
    proximity: 96,
    purpose: "state_feedback",
    repeatPolicy: "repeatable",
    textByTimeState: repeatedPuzzleText(
      "路线板缺少从 202 到主楼梯的连续箭头，四块磁贴仍可调整。",
      "202 门外与楼梯黄线内留有同一种鞋底纹，中间两段需要根据朝向接续。"
    )
  }),
  defineContextInteraction({
    targetId: "a3_archive_exhibition_301_context",
    label: "查看 301 校史档案展",
    floor: "A3",
    roomId: "a3_room_301",
    anchorId: "a3_301_archive_index",
    activePhases: ["room204_restore"],
    roomAliases: ["a3_wayfinding", "a3_reference_classroom"],
    purpose: "theme",
    repeatPolicy: "repeatable",
    textByTimeState: {
      "2245_opening": {
        light: "301 的档案柜按年代编号，展签强调记录需要保留原始时间。",
        dark: "翻阅残影停在同一页：校史记录同时注明事件、地点与记录人。"
      },
      "1225_bakery": {
        light: "午间展厅开放，玻璃柜中的教学日志按日期排放。",
        dark: "访客残影在日志柜前停留最久，随后依次查看人物档案。"
      },
      "1850_evening": {
        light: "晚间展厅已停止接待，档案扫描台仍显示当日校验结果。",
        dark: "扫描动作在 18:50 前完成，每页都保留来源编号。"
      },
      "2245_maintenance": {
        light: "恒温柜运行正常，维修记录没有涉及档案展区。",
        dark: "展柜周围没有异常移动残影，档案位置保持不变。"
      },
      "0754_blackout": {
        light: "停电时档案柜自动上锁，应急照明覆盖疏散通道。",
        dark: "锁定动作同时发生，没有单独开启的柜门。"
      },
      "0755_morning": {
        light: "晨检完成后，档案展恢复开放状态。",
        dark: "早班记录从 07:55 开始，昨夜时间轨已经封存。"
      }
    }
  }),
  defineContextInteraction({
    targetId: "a3_media_studio_302_context",
    label: "查看 302 媒体工作室",
    floor: "A3",
    roomId: "a3_room_302",
    anchorId: "a3_302_alignment_scanner",
    activePhases: ["room204_restore"],
    roomAliases: ["a3_wayfinding", "a3_reference_classroom"],
    purpose: "side_info",
    repeatPolicy: "repeatable",
    textByTimeState: {
      "2245_opening": {
        light: "302 的录音设备已关闭，时间码发生器保留最后一次同步结果。",
        dark: "剪辑台残影显示素材被逐段核对，没有一次性覆盖原始文件。"
      },
      "1225_bakery": {
        light: "午间工作室正在导出校园活动素材，监听音量保持在低档。",
        dark: "录音棚里的说话残影与波形段落对应，停顿位置清晰。"
      },
      "1850_evening": {
        light: "晚间录制已经结束，场记板停在 18:50 的收尾镜次。",
        dark: "最后一段人声结束后仍有六秒环境声，随后才停止录制。"
      },
      "2245_maintenance": {
        light: "工作室断开外部输入，存储阵列继续执行校验。",
        dark: "设备残影只显示自动校验，没有新的录制动作。"
      },
      "0754_blackout": {
        light: "后备电源保留时间码和存储阵列，其他设备已经关闭。",
        dark: "时间码在停电期间连续，没有发生跳秒。"
      },
      "0755_morning": {
        light: "工作室完成晨间同步，所有设备采用同一时间源。",
        dark: "当前残影只有开机检查，时间轨从 07:55 重新开始。"
      }
    }
  }),
  defineContextInteraction({
    targetId: "a3_report_hall_304_context",
    label: "查看 304 报告厅",
    floor: "A3",
    roomId: "a3_room_304",
    anchorId: "report_hall_304",
    activePhases: ["room204_restore"],
    roomAliases: ["a3_wayfinding", "a3_reference_classroom"],
    purpose: "theme",
    repeatPolicy: "repeatable",
    textByTimeState: {
      "2245_opening": {
        light: "304 的报告题目仍留在侧屏：判断需要来源、时间和可复核记录。",
        dark: "观众残影在提问环节集中出现，讲台记录保留了每次修改。"
      },
      "1225_bakery": {
        light: "午间报告尚未开始，讲台水杯和翻页器已经摆好。",
        dark: "前排只有布场人员的短时残影，座位区尚未形成观众轨迹。"
      },
      "1850_evening": {
        light: "晚间报告结束后，侧屏保留最后一页：记录结果，也记录判断过程。",
        dark: "散场残影从后排开始，讲台人员最后离开。"
      },
      "2245_maintenance": {
        light: "报告厅完成设备巡检，扩声与投影均处于关机状态。",
        dark: "设备周围没有异常操作残影，巡检记录连续。"
      },
      "0754_blackout": {
        light: "应急广播接管报告厅，所有出口指示正常。",
        dark: "广播启用与停电同时发生，没有额外控制动作。"
      },
      "0755_morning": {
        light: "报告厅开始晨间准备，侧屏切换为当日安排。",
        dark: "当前只有布场人员的残影，昨夜报告已经归档。"
      }
    }
  })
] as const satisfies readonly ChapterFourContextInteractionContent[]);

const CONTEXT_INTERACTIONS_BY_TARGET = new Map(
  CHAPTER_FOUR_CONTEXT_INTERACTIONS.map((entry) => [entry.targetId, entry] as const)
);

export function isChapterFourContextInteractionTargetId(
  value: string
): value is ChapterFourContextInteractionTargetId {
  return CONTEXT_INTERACTIONS_BY_TARGET.has(value as ChapterFourContextInteractionTargetId);
}

export function getChapterFourContextInteraction(
  targetId: string
): ChapterFourContextInteractionContent | null {
  return CONTEXT_INTERACTIONS_BY_TARGET.get(targetId as ChapterFourContextInteractionTargetId) ?? null;
}

export function selectChapterFourContextInteractionText(options: {
  targetId: string;
  phase: ChapterFourPhase | null;
  timeState: ChapterFourTimeState;
  mode: ChapterFourRealityMode;
}): string | null {
  const content = getChapterFourContextInteraction(options.targetId);
  if (!content || options.phase === null || !content.activePhases.includes(options.phase)) return null;
  return content.textByTimeState[options.timeState][options.mode];
}
