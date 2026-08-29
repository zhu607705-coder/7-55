export type QizhenRainRescueStrokeSide = "left" | "right";

export interface QizhenRainRescueRoutePoint {
  readonly x: number;
  readonly y: number;
  readonly heading: number;
  readonly roll: number;
  readonly side: QizhenRainRescueStrokeSide;
  readonly intensity: number;
}

export interface QizhenRainRescueTiming {
  readonly approachMs: number;
  readonly launchMs: number;
  readonly strokeMs: number;
  readonly strokeGapMs: number;
  readonly gustMs: number;
  readonly capsizeMs: number;
  readonly rescueHoldMs: number;
}

/**
 * 雨天强行下水只负责演出。控制器仍在最后一次救援事件后统一结算落水、
 * 回寝室和后续天气任务，路线坐标不会写入存档。
 */
export const QIZHEN_RAIN_RESCUE_START = Object.freeze({
  x: 714,
  y: 424,
  heading: -Math.PI / 2,
  roll: 0
});

export const QIZHEN_RAIN_RESCUE_ROUTE: readonly QizhenRainRescueRoutePoint[] = Object.freeze([
  { x: 700, y: 386, heading: -1.7, roll: 0.11, side: "left", intensity: 0.82 },
  { x: 718, y: 348, heading: -1.48, roll: -0.08, side: "right", intensity: 0.9 },
  { x: 702, y: 307, heading: -1.72, roll: 0.16, side: "left", intensity: 0.96 },
  { x: 721, y: 267, heading: -1.43, roll: -0.2, side: "right", intensity: 1.02 },
  { x: 699, y: 228, heading: -1.82, roll: 0.34, side: "left", intensity: 1.08 },
  { x: 724, y: 192, heading: -1.37, roll: -0.48, side: "right", intensity: 1.14 }
]);

export const QIZHEN_RAIN_RESCUE_TIMING = Object.freeze({
  normal: Object.freeze({
    approachMs: 460,
    launchMs: 520,
    strokeMs: 420,
    strokeGapMs: 90,
    gustMs: 620,
    capsizeMs: 1080,
    rescueHoldMs: 1600
  }),
  reduced: Object.freeze({
    approachMs: 160,
    launchMs: 180,
    strokeMs: 150,
    strokeGapMs: 35,
    gustMs: 200,
    capsizeMs: 400,
    rescueHoldMs: 800
  })
} satisfies Readonly<Record<"normal" | "reduced", QizhenRainRescueTiming>>);

export const QIZHEN_RAIN_RESCUE_REDUCED_ROUTE_INDICES = Object.freeze([0, 3, 4] as const);

export function getQizhenRainRescueDurationMs(reducedMotion: boolean): number {
  const timing = reducedMotion ? QIZHEN_RAIN_RESCUE_TIMING.reduced : QIZHEN_RAIN_RESCUE_TIMING.normal;
  const strokeCount = reducedMotion
    ? QIZHEN_RAIN_RESCUE_REDUCED_ROUTE_INDICES.length
    : QIZHEN_RAIN_RESCUE_ROUTE.length;
  return timing.approachMs
    + timing.launchMs
    + timing.strokeMs * strokeCount
    + timing.strokeGapMs * Math.max(0, strokeCount - 1)
    + timing.gustMs
    + timing.capsizeMs
    + timing.rescueHoldMs;
}
