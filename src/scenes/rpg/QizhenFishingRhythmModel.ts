/**
 * Qizhen Lake authored-chart adapter for the shared monotonic rhythm engine.
 * The chapter API and its four chart IDs stay stable for the RPG scene.
 */

import chartsData from "../../data/chapter3-qizhen-fishing.charts.json";
import {
  RhythmFishingEngine,
  type RhythmFishingAction,
  type RhythmFishingChartData,
  type RhythmFishingEngineEvents,
  type RhythmFishingFailReason,
  type RhythmFishingGrade,
  type RhythmFishingJudgment,
  type RhythmFishingNote,
  type RhythmFishingResult,
  type RhythmFishingSessionPhase,
  type RhythmFishingWarningKind,
} from "../../modules/RhythmFishingEngine";

export type QizhenFishingAction = RhythmFishingAction;
export type QizhenFishingChartId = "locker_key" | "net_frame" | "fish" | "paper";
export type QizhenFishingJudgment = RhythmFishingJudgment;
export type QizhenFishingGrade = RhythmFishingGrade;
export type QizhenFishingFailReason = RhythmFishingFailReason;
export type QizhenFishingSessionPhase = RhythmFishingSessionPhase;
export type QizhenFishingWarningKind = RhythmFishingWarningKind;
export type QizhenFishingNote = RhythmFishingNote;
export type QizhenFishingResult = RhythmFishingResult<QizhenFishingChartId>;

export interface QizhenFishingModelEvents extends RhythmFishingEngineEvents<QizhenFishingChartId> {}

export interface QizhenFishingRhythmModelOptions {
  chartId: QizhenFishingChartId;
  /** Monotonic clock in seconds (Web Audio `AudioContext.currentTime`). */
  now: () => number;
  assist?: boolean;
  events: QizhenFishingModelEvents;
}

export const QIZHEN_FISHING_TIMING = {
  beatSec: 0.625,
  leadSec: 1.25,
  assistLeadSec: 1.5625,
  perfectMs: 70,
  greatMs: 130,
  goodMs: 190,
  assistGoodMs: 230,
  holdReleaseSlackSec: 0.08,
} as const;

export const QIZHEN_FISHING_TENSION = {
  initial: 50,
  min: 0,
  max: 100,
  perfectRecover: 4,
  greatShift: 3,
  goodShift: 7,
  missPenalty: 14,
  wrongActionPenalty: 16,
  holdBreakPenalty: 12,
  warnLow: 20,
  warnHigh: 80,
  passMin: 15,
  passMax: 85,
  failSustainMs: 350,
  assistFailSustainMs: 700,
} as const;

interface QizhenFishingChartData extends RhythmFishingChartData {
  spotId: string;
  label: string;
  bars: number;
}

const chartCatalog = chartsData.charts as unknown as Record<QizhenFishingChartId, QizhenFishingChartData>;

/** Preserves the Chapter 3 constructor and public model surface. */
export class QizhenFishingRhythmModel extends RhythmFishingEngine<QizhenFishingChartId> {
  constructor(options: QizhenFishingRhythmModelOptions) {
    super({
      chartId: options.chartId,
      chart: chartCatalog[options.chartId],
      now: options.now,
      assist: options.assist,
      timing: QIZHEN_FISHING_TIMING,
      tension: QIZHEN_FISHING_TENSION,
      events: options.events,
    });
  }
}
