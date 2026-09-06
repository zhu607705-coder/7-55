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

export { LAKE_FISHING_TIMING as QIZHEN_FISHING_TIMING, LAKE_FISHING_TENSION as QIZHEN_FISHING_TENSION } from "../../modules/RhythmFishingEngine";
import { LAKE_FISHING_TIMING, LAKE_FISHING_TENSION } from "../../modules/RhythmFishingEngine";

interface QizhenFishingChartData extends RhythmFishingChartData {
  spotId: string;
  label: string;
  bars: number;
}

const chartCatalog = chartsData.charts as unknown as Record<QizhenFishingChartId, QizhenFishingChartData>;

export function qizhenFishingChartHasHold(chartId: QizhenFishingChartId): boolean {
  return chartCatalog[chartId].notes.some((note) => (note.hold ?? 0) > 0);
}

export function qizhenFishingFirstHoldAction(chartId: QizhenFishingChartId): QizhenFishingAction | null {
  const holdNote = chartCatalog[chartId].notes.find((note) => (note.hold ?? 0) > 0);
  return holdNote?.action ?? null;
}

/** Preserves the Chapter 3 constructor and public model surface. */
export class QizhenFishingRhythmModel extends RhythmFishingEngine<QizhenFishingChartId> {
  constructor(options: QizhenFishingRhythmModelOptions) {
    super({
      chartId: options.chartId,
      chart: chartCatalog[options.chartId],
      now: options.now,
      assist: options.assist,
      timing: LAKE_FISHING_TIMING,
      tension: LAKE_FISHING_TENSION,
      events: options.events,
    });
  }
}
