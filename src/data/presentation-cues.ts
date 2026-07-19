export type PresentationCueKind =
  | "ticket"
  | "alert"
  | "scan"
  | "route"
  | "photo"
  | "rank"
  | "code"
  | "stamp"
  | "success"
  | "chapter"
  | "countdown"
  | "milestone"
  | "impact"
  | "result";

export interface PresentationCueDefinition {
  kind: PresentationCueKind;
  title: string;
  detail: string;
  mark: string;
  durationMs: number;
  priority: 1 | 2 | 3;
  visual?: boolean;
}

export interface ResolvedPresentationCue extends PresentationCueDefinition {
  id: string;
}

export const PRESENTATION_CUES: Record<string, PresentationCueDefinition> = {
  act2_system_inventory_requested: {
    kind: "ticket",
    title: "找到道具栏",
    detail: "校园地图内出现了可调查的寝室据点",
    mark: "箱",
    durationMs: 1700,
    priority: 2
  },
  act2_movement_quest_started: {
    kind: "chapter",
    title: "找到移动的办法",
    detail: "让寝室里的人离开房间",
    mark: "MOVE",
    durationMs: 1900,
    priority: 3
  },
  act2_right_arrow_assembled: {
    kind: "success",
    title: "右移箭头已合成",
    detail: "它能把一个目标向右移动两格",
    mark: "→",
    durationMs: 1450,
    priority: 2
  },
  act2_gamepad_purchased: {
    kind: "stamp",
    title: "交易完成",
    detail: "游戏手柄已放入道具栏",
    mark: "¥6",
    durationMs: 1550,
    priority: 2
  },
  act2_exit_ready: {
    kind: "success",
    title: "可以出门了",
    detail: "寝室出口已开放",
    mark: "门",
    durationMs: 1800,
    priority: 3
  },
  library_route_unlocked: {
    kind: "chapter",
    title: "进入图书馆，找到 022",
    detail: "基础图书馆入口已开放",
    mark: "022",
    durationMs: 1900,
    priority: 3
  },
  library_entered: {
    kind: "scan",
    title: "入馆记录待核对",
    detail: "点击闸机旁的小屏查看两条时间",
    mark: "LOG",
    durationMs: 1600,
    priority: 2,
    visual: false
  },
  library_occupied_seat_found: {
    kind: "alert",
    title: "022 被书包占用",
    detail: "调查纸条与离座规则",
    mark: "!",
    durationMs: 1900,
    priority: 3,
    visual: false
  },
  library_occupancy_note_collected: {
    kind: "ticket",
    title: "获得占座纸条",
    detail: "可拖入 CC98 搜索",
    mark: "NOTE",
    durationMs: 1400,
    priority: 2,
    visual: false
  },
  cc98_occupation_post_opened: {
    kind: "scan",
    title: "调查帖已找到",
    detail: "23 楼内容，5 条 ac01 可选",
    mark: "23F",
    durationMs: 1600,
    priority: 2
  },
  library_catalog_match_found: {
    kind: "ticket",
    title: "正确馆藏已确认",
    detail: "索书号 I247.55 / 755",
    mark: "755",
    durationMs: 1800,
    priority: 3
  },
  library_archived_rule_recovered: {
    kind: "scan",
    title: "旧版离座规则",
    detail: "恢复 022 需要三项证明",
    mark: "3",
    durationMs: 1800,
    priority: 2,
    visual: false
  },
  photo_bag_report_generated: {
    kind: "photo",
    title: "物品识别报告已生成",
    detail: "对象类型：书包",
    mark: "IMG",
    durationMs: 1600,
    priority: 2
  },
  library_bag_nonperson_proof_issued: {
    kind: "stamp",
    title: "书包非本人证明",
    detail: "失物招领登记已盖章",
    mark: "章",
    durationMs: 1700,
    priority: 3,
    visual: false
  },
  library_seat_receipt_recovered: {
    kind: "ticket",
    title: "022 座位小票",
    detail: "右移箭头仍保留在道具栏",
    mark: "022",
    durationMs: 1600,
    priority: 2,
    visual: false
  },
  tiyi_presence_proof_issued: {
    kind: "stamp",
    title: "本人来过证明",
    detail: "7 / 47 / 3 补录通过",
    mark: "PASS",
    durationMs: 1900,
    priority: 3
  },
  cc98_evidence_set_completed: {
    kind: "scan",
    title: "四项证据已公示",
    detail: "系统将说明帮顶与四位口令规则",
    mark: "4/4",
    durationMs: 1700,
    priority: 2
  },
  cc98_top_ten_reached: {
    kind: "rank",
    title: "进入十大",
    detail: "剧情帖排名 01",
    mark: "04→01",
    durationMs: 2000,
    priority: 3
  },
  library_recovery_application_opened: {
    kind: "ticket",
    title: "022 恢复申请已开放",
    detail: "提交三项恢复证明",
    mark: "FORM",
    durationMs: 1700,
    priority: 2
  },
  library_seat_release_pass_issued: {
    kind: "stamp",
    title: "解除占座 PASS",
    detail: "仅可用于 RPG 中的 022 书包",
    mark: "PASS",
    durationMs: 1900,
    priority: 3
  },
  library_backpack_evicted: {
    kind: "impact",
    title: "占座对象已转移",
    detail: "书包已送往失物招领",
    mark: "→",
    durationMs: 1800,
    priority: 3,
    visual: false
  },
  library_seat_recovered: {
    kind: "success",
    title: "022 已恢复",
    detail: "点击座位并联系异常意识",
    mark: "022",
    durationMs: 2100,
    priority: 3,
    visual: false
  },
  chapter_three_book_hunt_unlocked: {
    kind: "chapter",
    title: "找到那本借走签到记录的书",
    detail: "第三章任务已更新",
    mark: "BOOK",
    durationMs: 2400,
    priority: 3
  },
  bike_arcade_unlocked: {
    kind: "chapter",
    title: "新任务已开放",
    detail: "求是潮 755",
    mark: "755",
    durationMs: 1700,
    priority: 2
  },
  bike_arcade_opened: {
    kind: "chapter",
    title: "求是潮 755",
    detail: "三车道 · 三次机会",
    mark: "07:55",
    durationMs: 1500,
    priority: 2
  },
  bike_arcade_run_started: {
    kind: "countdown",
    title: "开始骑行",
    detail: "保持车道",
    mark: "3·2·1",
    durationMs: 950,
    priority: 2
  },
  bike_arcade_milestone: {
    kind: "milestone",
    title: "里程节点",
    detail: "继续前进",
    mark: "188m",
    durationMs: 1050,
    priority: 2
  },
  bike_arcade_collision: {
    kind: "impact",
    title: "发生碰撞",
    detail: "短暂无敌已启动",
    mark: "×",
    durationMs: 520,
    priority: 3
  },
  bike_arcade_last_life: {
    kind: "alert",
    title: "剩余一次机会",
    detail: "下一次碰撞将结束本轮",
    mark: "1",
    durationMs: 1500,
    priority: 3
  },
  bike_arcade_won: {
    kind: "success",
    title: "已抵达 755 米",
    detail: "第三章完成记录已保存",
    mark: "CLEAR",
    durationMs: 2300,
    priority: 3
  },
  bike_arcade_lost: {
    kind: "result",
    title: "本轮结束",
    detail: "最高距离已保存",
    mark: "STOP",
    durationMs: 1800,
    priority: 3
  },
  chapter_transition_opened: {
    kind: "result",
    title: "CHAPTER 03 CLEAR",
    detail: "下一任务已开放",
    mark: "755",
    durationMs: 1800,
    priority: 3,
    visual: false
  }
};

export const PRESENTATION_VISUAL_CUE_IDS = new Set(
  Object.entries(PRESENTATION_CUES)
    .filter(([, cue]) => cue.visual !== false)
    .map(([id]) => id)
);

export function resolvePresentationCue(
  cueId: string,
  payload: Record<string, unknown> = {}
): ResolvedPresentationCue | null {
  const definition = PRESENTATION_CUES[cueId];
  if (!definition || definition.visual === false) {
    return null;
  }

  if (cueId === "bike_arcade_milestone") {
    const distance = Number(payload.distance);
    const milestone = distance === 188 || distance === 377 || distance === 566 || distance === 755
      ? distance
      : 188;
    return {
      ...definition,
      id: cueId,
      mark: `${milestone}m`,
      detail: milestone === 188
        ? "节奏提升"
        : milestone === 377
          ? "拥堵升级"
          : milestone === 566
            ? "最后冲刺"
            : "目标抵达"
    };
  }

  if (cueId === "bike_arcade_collision") {
    const lives = Number(payload.lives);
    return {
      ...definition,
      id: cueId,
      detail: Number.isFinite(lives) ? `剩余机会 ${Math.max(0, lives)}` : definition.detail
    };
  }

  return { ...definition, id: cueId };
}
