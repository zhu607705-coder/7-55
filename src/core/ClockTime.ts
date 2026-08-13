import type { ClockCalibrationPhase } from "./types";

const SECONDS_PER_DAY = 86400;
/** 校时目标：08:00:00。 */
const TARGET_SECONDS = 8 * 3600;
/** 近段窗口：距目标 5 分钟内染色从 0 升到冷蓝微光。 */
const NEAR_WINDOW_SECONDS = 5 * 60;
/** 远段窗口：距目标 2 小时后染色达到深夜封顶。 */
const FAR_WINDOW_SECONDS = 2 * 3600;
/** 近段端点透明度：07:55 附近的冷蓝微光约 0.3。 */
const NEAR_ALPHA = 0.3;
/** 深夜封底透明度。 */
const FAR_ALPHA = 0.55;
/** 黎明冷蓝（贴近 08:00 时）。 */
const DAWN_RGB: readonly [number, number, number] = [143, 183, 255];
/** 深夜靛蓝（远离目标时）。 */
const NIGHT_RGB: readonly [number, number, number] = [16, 28, 60];

export interface ClockDigits {
  hh: string;
  mm: string;
  ss: string;
}

export interface ClockTint {
  color: string;
  alpha: number;
}

/** 把一天内的秒数格式化为 hh/mm/ss 两位字符串；输入先按 86400 环绕并取整。 */
export function formatClockSeconds(seconds: number): ClockDigits {
  const wrapped = wrapDaySeconds(seconds);
  const hh = Math.floor(wrapped / 3600);
  const mm = Math.floor((wrapped % 3600) / 60);
  const ss = wrapped % 60;
  return { hh: padTwo(hh), mm: padTwo(mm), ss: padTwo(ss) };
}

/**
 * 时间染色层色标（第四章「校时」：被冻结的 07:55 → 08:00 黎明）：
 * - 距 08:00 五分钟以内：黎明冷蓝 #8fb7ff，alpha 由 0 线性升至 0.30
 *   （07:55:23 附近即约 0.28 的冷蓝微光）；
 * - 五分钟到两小时：颜色由黎明冷蓝平滑沉入深夜靛蓝 #101c3c，
 *   alpha 由 0.30 升至 0.55；
 * - 偏离超过两小时：保持深夜靛蓝 0.55 封顶；
 * - phase 为 "aligned"（校时完成）后染色层解除，完全透明。
 * alpha 保留三位小数，供 RPG 氛围层与校时页共用同一刻度。
 */
export function selectClockTint(displayedSeconds: number, phase: ClockCalibrationPhase): ClockTint {
  if (phase === "aligned") {
    return { color: toRgbString(DAWN_RGB), alpha: 0 };
  }
  const distance = Math.abs(wrapDaySeconds(displayedSeconds) - TARGET_SECONDS);
  if (distance <= NEAR_WINDOW_SECONDS) {
    const t = distance / NEAR_WINDOW_SECONDS;
    return { color: toRgbString(DAWN_RGB), alpha: roundAlpha(NEAR_ALPHA * t) };
  }
  const t = Math.min((distance - NEAR_WINDOW_SECONDS) / (FAR_WINDOW_SECONDS - NEAR_WINDOW_SECONDS), 1);
  return {
    color: toRgbString(mixRgb(DAWN_RGB, NIGHT_RGB, t)),
    alpha: roundAlpha(NEAR_ALPHA + (FAR_ALPHA - NEAR_ALPHA) * t)
  };
}

function wrapDaySeconds(seconds: number): number {
  const rounded = Math.round(seconds);
  return ((rounded % SECONDS_PER_DAY) + SECONDS_PER_DAY) % SECONDS_PER_DAY;
}

function padTwo(value: number): string {
  return String(value).padStart(2, "0");
}

function mixRgb(
  from: readonly [number, number, number],
  to: readonly [number, number, number],
  t: number
): [number, number, number] {
  return [
    Math.round(from[0] + (to[0] - from[0]) * t),
    Math.round(from[1] + (to[1] - from[1]) * t),
    Math.round(from[2] + (to[2] - from[2]) * t)
  ];
}

function toRgbString(rgb: readonly [number, number, number]): string {
  return `rgb(${rgb[0]}, ${rgb[1]}, ${rgb[2]})`;
}

function roundAlpha(alpha: number): number {
  return Math.round(alpha * 1000) / 1000;
}
