/**
 * 第四章序幕「纸条进入段永平教学楼」的共享时间线。
 * Overlay 按 BEATS 触发领域事件（音频 cue 与字幕），Renderer 按 PHASES
 * 绘制画面；两端只读常量，不互相调用。
 */

export interface PrologueBeat {
  /** 相对过场开始的毫秒数 */
  at: number;
  /** 同名领域事件；PresentationDirector 按 chapter4-prologue.audio.json 转发为音频 cue */
  cueEvent: string;
}

export interface PrologueSubtitle {
  id: "player" | "narrator" | "cleaner" | "guard";
  at: number;
  durationMs: number;
  text: string;
  speaker: string;
  tone: "player" | "narrator" | "broadcast";
}

export const PROLOGUE_PHASES = [
  { id: "snap", from: 0, to: 4200 },
  { id: "lake_exit", from: 4200, to: 12400 },
  { id: "arcade", from: 12400, to: 24400 },
  { id: "entrance", from: 24400, to: 32400 },
  { id: "lobby", from: 32400, to: 44200 },
  { id: "closing", from: 44200, to: 51600 }
] as const;

export type ProloguePhaseId = (typeof PROLOGUE_PHASES)[number]["id"];

/** 任务卡弹出时间；确认前过场停在卡片状态。 */
export const PROLOGUE_TASK_CARD_AT = 51600;
/** 卡片之后画面静止收尾的总时长（无交互兜底）。 */
export const PROLOGUE_TOTAL_MS = 55600;

export const PROLOGUE_BEATS: readonly PrologueBeat[] = [
  { at: 0, cueEvent: "chapter4_prologue_started" },
  { at: 200, cueEvent: "chapter4_prologue_magnet_tension" },
  { at: 2100, cueEvent: "chapter4_prologue_magnet_snap" },
  { at: 2600, cueEvent: "chapter4_prologue_line_recoil" },
  { at: 3200, cueEvent: "chapter4_prologue_water_ripple" },
  { at: 4200, cueEvent: "chapter4_prologue_lake_exit" },
  { at: 6900, cueEvent: "chapter4_prologue_railing_hit" },
  { at: 7600, cueEvent: "chapter4_prologue_paper_flip" },
  { at: 8600, cueEvent: "chapter4_prologue_stone_land" },
  { at: 9800, cueEvent: "chapter4_prologue_gust_skim" },
  { at: 12400, cueEvent: "chapter4_prologue_arcade" },
  { at: 19200, cueEvent: "chapter4_prologue_step_fold" },
  { at: 21800, cueEvent: "chapter4_prologue_arcade_push" },
  { at: 26200, cueEvent: "chapter4_prologue_glass_door" },
  { at: 27600, cueEvent: "chapter4_prologue_pressure_suction" },
  { at: 30500, cueEvent: "chapter4_prologue_clock_chime" },
  { at: 32400, cueEvent: "chapter4_prologue_wet_floor" },
  { at: 35800, cueEvent: "chapter4_prologue_cleaner_line" },
  { at: 44200, cueEvent: "chapter4_prologue_broadcast_static" },
  { at: 45200, cueEvent: "chapter4_prologue_guard_line" },
  { at: 50000, cueEvent: "chapter4_prologue_lights_out" },
  { at: PROLOGUE_TASK_CARD_AT, cueEvent: "chapter4_prologue_task_card" }
];

export const PROLOGUE_SUBTITLES: readonly PrologueSubtitle[] = [
  {
    id: "player",
    at: 2950,
    durationMs: 1800,
    text: "又断了。",
    speaker: "我",
    tone: "player"
  },
  {
    id: "narrator",
    at: 12600,
    durationMs: 6400,
    text: "湖面没有留下它。夜风把它送进了仍然亮着灯的教学楼。",
    speaker: "旁白",
    tone: "narrator"
  },
  {
    id: "cleaner",
    at: 35800,
    durationMs: 6600,
    text: "小心，刚拖过。刚才有张纸贴着地往里卷了。",
    speaker: "保洁员",
    tone: "broadcast"
  },
  {
    id: "guard",
    at: 45200,
    durationMs: 5200,
    text: "同学，北教准备清楼了，手上的东西收一下。",
    speaker: "保安",
    tone: "broadcast"
  }
];

export function prologuePhaseAt(elapsedMs: number): { id: ProloguePhaseId; localMs: number; durationMs: number } {
  for (const phase of PROLOGUE_PHASES) {
    if (elapsedMs < phase.to) {
      return { id: phase.id, localMs: elapsedMs - phase.from, durationMs: phase.to - phase.from };
    }
  }
  const last = PROLOGUE_PHASES[PROLOGUE_PHASES.length - 1];
  return { id: last.id, localMs: elapsedMs - last.from, durationMs: last.to - last.from };
}

export function prologueSubtitleAt(elapsedMs: number): PrologueSubtitle | null {
  return PROLOGUE_SUBTITLES.find((subtitle) => elapsedMs >= subtitle.at && elapsedMs < subtitle.at + subtitle.durationMs) ?? null;
}
