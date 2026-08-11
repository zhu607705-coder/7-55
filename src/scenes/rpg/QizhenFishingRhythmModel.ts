/**
 * Qizhen Lake rhythm-fishing judgment engine (pure TypeScript, no Phaser).
 *
 * Contract: docs/chapter-3-qizhen-fishing-rhythm.md §9.1.
 * Chart data: src/data/chapter3-qizhen-fishing.charts.json (§3).
 * Judgment, tension, and completion rules: §4; assist mode: §5.
 * All timing reads the injected monotonic `now()` clock; no timers, no Date.
 */

import chartsData from "../../data/chapter3-qizhen-fishing.charts.json";

export type QizhenFishingAction = "left" | "right" | "hook";
export type QizhenFishingChartId = "locker_key" | "net_frame" | "fish" | "paper";
export type QizhenFishingJudgment = "perfect" | "great" | "good" | "miss";
export type QizhenFishingGrade = "S" | "A" | "B" | "C";
export type QizhenFishingFailReason = "line_snapped" | "hook_escaped";
export type QizhenFishingSessionPhase = "idle" | "running" | "completed" | "failed" | "cancelled";
export type QizhenFishingWarningKind = "tension_low" | "tension_high";

export interface QizhenFishingNote {
  index: number;
  beat: number;
  timeSec: number;
  spawnSec: number;
  action: QizhenFishingAction;
  holdBeats: number;
  holdSec: number;
  cue: "left_intro" | "right_intro" | null;
  judgment: QizhenFishingJudgment | null;
  holding: boolean;
}

export interface QizhenFishingResult {
  chartId: QizhenFishingChartId;
  grade: QizhenFishingGrade;
  passed: boolean;
  accuracy: number;
  perfect: number;
  great: number;
  good: number;
  miss: number;
  maxCombo: number;
  finalTension: number;
}

export interface QizhenFishingModelEvents {
  onNoteJudged(
    note: QizhenFishingNote,
    judgment: QizhenFishingJudgment,
    errorMs: number,
    tension: number,
  ): void;
  onHoldBroken(note: QizhenFishingNote, tension: number): void;
  onWarning(kind: QizhenFishingWarningKind, tension: number): void;
  onCompleted(result: QizhenFishingResult): void;
  onFailed(reason: QizhenFishingFailReason, tension: number): void;
}

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

/** §4.2: tension warnings re-arm only after tension returns to [30, 70]. */
const WARNING_REARM_LOW = 30;
const WARNING_REARM_HIGH = 70;
/** §4.2: perfect pulls tension toward the 0–100 midpoint. */
const TENSION_MIDPOINT =
  (QIZHEN_FISHING_TENSION.min + QIZHEN_FISHING_TENSION.max) / 2;
/** Guards §4.3 accuracy thresholds against binary floating-point drift. */
const ACCURACY_EPSILON = 1e-9;

interface QizhenFishingChartNoteData {
  beat: number;
  action: QizhenFishingAction;
  hold?: number;
  cue?: "left_intro" | "right_intro";
}

interface QizhenFishingChartData {
  spotId: string;
  label: string;
  bars: number;
  durationSeconds: number;
  notes: QizhenFishingChartNoteData[];
}

const chartCatalog = chartsData.charts as unknown as Record<
  QizhenFishingChartId,
  QizhenFishingChartData
>;

function clampTensionValue(value: number): number {
  return Math.min(QIZHEN_FISHING_TENSION.max, Math.max(QIZHEN_FISHING_TENSION.min, value));
}

export class QizhenFishingRhythmModel {
  readonly notes: readonly QizhenFishingNote[];
  readonly totalNotes: number;
  readonly leadSec: number;
  readonly assist: boolean;

  private readonly options: QizhenFishingRhythmModelOptions;
  private readonly events: QizhenFishingModelEvents;
  private readonly chartId: QizhenFishingChartId;
  private readonly durationSeconds: number;
  private readonly noteList: QizhenFishingNote[];

  private sessionPhase: QizhenFishingSessionPhase = "idle";
  private t0Sec: number | null = null;
  private tensionValue: number = QIZHEN_FISHING_TENSION.initial;
  private comboCounter = 0;
  private maxComboCounter = 0;
  private judgedCounter = 0;
  private outOfBoundsSinceSec: number | null = null;
  private lowWarningFired = false;
  private highWarningFired = false;

  constructor(options: QizhenFishingRhythmModelOptions) {
    this.options = options;
    this.events = options.events;
    this.chartId = options.chartId;
    this.assist = options.assist === true;
    this.leadSec = this.assist
      ? QIZHEN_FISHING_TIMING.assistLeadSec
      : QIZHEN_FISHING_TIMING.leadSec;

    const chart = chartCatalog[options.chartId];
    this.durationSeconds = chart.durationSeconds;

    const beatSec = QIZHEN_FISHING_TIMING.beatSec;
    const notes: QizhenFishingNote[] = [];
    for (const rawNote of chart.notes) {
      // §5: assist mode removes fractional-beat (eighth-note) notes outright.
      if (this.assist && !Number.isInteger(rawNote.beat)) {
        continue;
      }
      const timeSec = rawNote.beat * beatSec;
      const holdBeats = rawNote.hold ?? 0;
      notes.push({
        index: notes.length,
        beat: rawNote.beat,
        timeSec,
        spawnSec: timeSec - this.leadSec,
        action: rawNote.action,
        holdBeats,
        holdSec: holdBeats * beatSec,
        cue: rawNote.cue ?? null,
        judgment: null,
        holding: false,
      });
    }
    this.noteList = notes;
    this.notes = notes;
    this.totalNotes = notes.length;
  }

  get phase(): QizhenFishingSessionPhase {
    return this.sessionPhase;
  }

  get tension(): number {
    return this.tensionValue;
  }

  get combo(): number {
    return this.comboCounter;
  }

  get maxCombo(): number {
    return this.maxComboCounter;
  }

  get judgedCount(): number {
    return this.judgedCounter;
  }

  get elapsedSec(): number {
    return this.t0Sec === null ? 0 : this.options.now() - this.t0Sec;
  }

  start(): void {
    if (this.sessionPhase !== "idle") {
      return;
    }
    this.t0Sec = this.options.now();
    this.sessionPhase = "running";
  }

  handlePress(action: QizhenFishingAction): void {
    if (this.sessionPhase !== "running" || this.t0Sec === null) {
      return;
    }
    // §2: note times are chart-relative (t_n = t0 + 0.625 × b_n), so inputs
    // are matched against elapsed time, not the raw absolute clock.
    const elapsedSec = this.options.now() - this.t0Sec;
    const windowMs = this.goodWindowMs();

    // §4.1: one input matches at most one unjudged note, the nearest in time.
    let target: QizhenFishingNote | null = null;
    let targetAbsErrorMs = Number.POSITIVE_INFINITY;
    for (const note of this.noteList) {
      if (note.judgment !== null) {
        continue;
      }
      const absErrorMs = Math.abs((elapsedSec - note.timeSec) * 1000);
      if (absErrorMs <= windowMs && absErrorMs < targetAbsErrorMs) {
        target = note;
        targetAbsErrorMs = absErrorMs;
      }
    }
    if (target === null) {
      return; // no note inside the window: the input is ignored.
    }

    // §4.1: errorMs is signed; negative means the input was early.
    const errorMs = (elapsedSec - target.timeSec) * 1000;
    if (target.action !== action) {
      // §4.1: wrong direction in-window judges that note miss with +16 tension
      // instead of the normal miss penalty.
      this.judgeMiss(target, errorMs, QIZHEN_FISHING_TENSION.wrongActionPenalty);
      return;
    }

    const judgment: QizhenFishingJudgment =
      targetAbsErrorMs <= QIZHEN_FISHING_TIMING.perfectMs
        ? "perfect"
        : targetAbsErrorMs <= QIZHEN_FISHING_TIMING.greatMs
          ? "great"
          : "good";
    this.judgeHit(target, judgment, errorMs);
  }

  handleRelease(action: QizhenFishingAction): void {
    if (this.sessionPhase !== "running" || this.t0Sec === null) {
      return;
    }
    const elapsedSec = this.options.now() - this.t0Sec;
    for (const note of this.noteList) {
      if (!note.holding || note.action !== action) {
        continue;
      }
      // §4.1: the hold must survive until timeSec + holdSec - slack.
      if (elapsedSec < note.timeSec + note.holdSec - QIZHEN_FISHING_TIMING.holdReleaseSlackSec) {
        note.judgment = "miss";
        note.holding = false;
        this.comboCounter = 0;
        this.tensionValue = clampTensionValue(
          this.tensionValue - QIZHEN_FISHING_TENSION.holdBreakPenalty,
        );
        this.events.onHoldBroken(note, this.tensionValue);
        this.checkWarningEdge();
      } else {
        note.holding = false;
      }
    }
  }

  update(): void {
    if (this.sessionPhase !== "running" || this.t0Sec === null) {
      return;
    }
    const nowSec = this.options.now();
    // §2: chart-relative elapsed time drives note timing; the raw clock only
    // measures the out-of-bounds sustain duration below.
    const elapsedSec = nowSec - this.t0Sec;

    // §4.1: unjudged notes past the good window time out as miss.
    const goodWindowMs = this.goodWindowMs();
    const goodWindowSec = goodWindowMs / 1000;
    for (const note of this.noteList) {
      if (note.judgment === null && elapsedSec > note.timeSec + goodWindowSec) {
        this.judgeMiss(note, goodWindowMs, -QIZHEN_FISHING_TENSION.missPenalty);
      }
    }

    // §4.1: a hold still pressed at its release threshold completes quietly.
    for (const note of this.noteList) {
      if (
        note.holding &&
        elapsedSec >= note.timeSec + note.holdSec - QIZHEN_FISHING_TIMING.holdReleaseSlackSec
      ) {
        note.holding = false;
      }
    }

    // §4.2: out-of-bounds tension must persist for the sustain window before
    // the run fails; this check has priority over completion below.
    const escaped = this.tensionValue <= QIZHEN_FISHING_TENSION.min;
    const snapped = this.tensionValue >= QIZHEN_FISHING_TENSION.max;
    if (escaped || snapped) {
      if (this.outOfBoundsSinceSec === null) {
        this.outOfBoundsSinceSec = nowSec;
      }
      const sustainSec =
        (this.assist
          ? QIZHEN_FISHING_TENSION.assistFailSustainMs
          : QIZHEN_FISHING_TENSION.failSustainMs) / 1000;
      if (nowSec - this.outOfBoundsSinceSec >= sustainSec) {
        this.sessionPhase = "failed";
        this.events.onFailed(escaped ? "hook_escaped" : "line_snapped", this.tensionValue);
        return;
      }
    } else {
      this.outOfBoundsSinceSec = null;
    }

    // §4.3: resolve once every note is judged and the chart has fully played.
    if (
      this.judgedCounter >= this.totalNotes &&
      nowSec - this.t0Sec >= this.durationSeconds
    ) {
      this.sessionPhase = "completed";
      this.events.onCompleted(this.buildResult());
    }
  }

  cancel(): void {
    if (this.sessionPhase === "running" || this.sessionPhase === "idle") {
      this.sessionPhase = "cancelled";
    }
  }

  private goodWindowMs(): number {
    return this.assist ? QIZHEN_FISHING_TIMING.assistGoodMs : QIZHEN_FISHING_TIMING.goodMs;
  }

  private judgeHit(
    note: QizhenFishingNote,
    judgment: Exclude<QizhenFishingJudgment, "miss">,
    errorMs: number,
  ): void {
    note.judgment = judgment;
    this.judgedCounter += 1;
    this.comboCounter += 1;
    if (this.comboCounter > this.maxComboCounter) {
      this.maxComboCounter = this.comboCounter;
    }
    if (judgment === "perfect") {
      // §4.2: perfect recovers 4 toward the midpoint without crossing it.
      if (this.tensionValue > TENSION_MIDPOINT) {
        this.tensionValue = Math.max(
          TENSION_MIDPOINT,
          this.tensionValue - QIZHEN_FISHING_TENSION.perfectRecover,
        );
      } else if (this.tensionValue < TENSION_MIDPOINT) {
        this.tensionValue = Math.min(
          TENSION_MIDPOINT,
          this.tensionValue + QIZHEN_FISHING_TENSION.perfectRecover,
        );
      }
    } else {
      // §4.2: early inputs raise tension, late inputs lower it.
      const shift =
        judgment === "great"
          ? QIZHEN_FISHING_TENSION.greatShift
          : QIZHEN_FISHING_TENSION.goodShift;
      this.tensionValue += errorMs < 0 ? shift : -shift;
    }
    this.tensionValue = clampTensionValue(this.tensionValue);
    if (note.holdBeats > 0) {
      note.holding = true;
    }
    this.events.onNoteJudged(note, judgment, errorMs, this.tensionValue);
    this.checkWarningEdge();
  }

  private judgeMiss(note: QizhenFishingNote, errorMs: number, tensionDelta: number): void {
    note.judgment = "miss";
    this.judgedCounter += 1;
    this.comboCounter = 0;
    this.tensionValue = clampTensionValue(this.tensionValue + tensionDelta);
    this.events.onNoteJudged(note, "miss", errorMs, this.tensionValue);
    this.checkWarningEdge();
  }

  private checkWarningEdge(): void {
    const tension = this.tensionValue;
    if (tension < QIZHEN_FISHING_TENSION.warnLow) {
      if (!this.lowWarningFired) {
        this.lowWarningFired = true;
        this.events.onWarning("tension_low", tension);
      }
    } else if (tension > QIZHEN_FISHING_TENSION.warnHigh) {
      if (!this.highWarningFired) {
        this.highWarningFired = true;
        this.events.onWarning("tension_high", tension);
      }
    }
    if (tension >= WARNING_REARM_LOW && tension <= WARNING_REARM_HIGH) {
      this.lowWarningFired = false;
      this.highWarningFired = false;
    }
  }

  private buildResult(): QizhenFishingResult {
    let perfect = 0;
    let great = 0;
    let good = 0;
    let miss = 0;
    let weightSum = 0;
    for (const note of this.noteList) {
      switch (note.judgment) {
        case "perfect":
          perfect += 1;
          weightSum += 1;
          break;
        case "great":
          great += 1;
          weightSum += 0.8;
          break;
        case "good":
          good += 1;
          weightSum += 0.55;
          break;
        default:
          miss += 1;
          break;
      }
    }
    const accuracy = this.totalNotes > 0 ? weightSum / this.totalNotes : 0;
    const first = this.noteList[0];
    const last = this.noteList[this.noteList.length - 1];
    // §4.3: both terminal hook notes must be non-miss, accuracy >= 0.70, and
    // final tension inside [15, 85].
    const hooksLanded =
      first != null &&
      first.judgment !== null &&
      first.judgment !== "miss" &&
      last != null &&
      last.judgment !== null &&
      last.judgment !== "miss";
    const passed =
      hooksLanded &&
      accuracy >= 0.7 - ACCURACY_EPSILON &&
      this.tensionValue >= QIZHEN_FISHING_TENSION.passMin &&
      this.tensionValue <= QIZHEN_FISHING_TENSION.passMax;
    const grade: QizhenFishingGrade =
      accuracy >= 0.95 - ACCURACY_EPSILON && miss === 0
        ? "S"
        : accuracy >= 0.85 - ACCURACY_EPSILON
          ? "A"
          : accuracy >= 0.7 - ACCURACY_EPSILON
            ? "B"
            : "C";
    return {
      chartId: this.chartId,
      grade,
      passed,
      accuracy,
      perfect,
      great,
      good,
      miss,
      maxCombo: this.maxComboCounter,
      finalTension: this.tensionValue,
    };
  }
}
