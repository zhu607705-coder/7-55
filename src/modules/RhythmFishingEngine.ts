export type RhythmFishingAction = "left" | "right" | "hook";
export type RhythmFishingJudgment = "perfect" | "great" | "good" | "miss";
export type RhythmFishingGrade = "S" | "A" | "B" | "C";
export type RhythmFishingFailReason = "line_snapped" | "hook_escaped";
export type RhythmFishingSessionPhase = "idle" | "running" | "completed" | "failed" | "cancelled";
export type RhythmFishingWarningKind = "tension_low" | "tension_high";

export interface RhythmFishingNote {
  index: number;
  beat: number;
  timeSec: number;
  spawnSec: number;
  action: RhythmFishingAction;
  holdBeats: number;
  holdSec: number;
  cue: "left_intro" | "right_intro" | null;
  judgment: RhythmFishingJudgment | null;
  holding: boolean;
}

export interface RhythmFishingChartNoteData {
  beat: number;
  action: RhythmFishingAction;
  hold?: number;
  cue?: "left_intro" | "right_intro";
}

export interface RhythmFishingChartData {
  durationSeconds: number;
  notes: readonly RhythmFishingChartNoteData[];
}

export interface RhythmFishingTiming {
  beatSec: number;
  leadSec: number;
  assistLeadSec: number;
  perfectMs: number;
  greatMs: number;
  goodMs: number;
  assistGoodMs: number;
  holdReleaseSlackSec: number;
}

export interface RhythmFishingTension {
  initial: number;
  min: number;
  max: number;
  perfectRecover: number;
  greatShift: number;
  goodShift: number;
  missPenalty: number;
  wrongActionPenalty: number;
  holdBreakPenalty: number;
  warnLow: number;
  warnHigh: number;
  passMin: number;
  passMax: number;
  failSustainMs: number;
  assistFailSustainMs: number;
}

export interface RhythmFishingResult<ChartId extends string> {
  chartId: ChartId;
  grade: RhythmFishingGrade;
  passed: boolean;
  accuracy: number;
  perfect: number;
  great: number;
  good: number;
  miss: number;
  maxCombo: number;
  finalTension: number;
}

export interface RhythmFishingEngineEvents<ChartId extends string> {
  onNoteJudged(
    note: RhythmFishingNote,
    judgment: RhythmFishingJudgment,
    errorMs: number,
    tension: number,
  ): void;
  onHoldBroken(note: RhythmFishingNote, tension: number): void;
  onWarning(kind: RhythmFishingWarningKind, tension: number): void;
  onCompleted(result: RhythmFishingResult<ChartId>): void;
  onFailed(reason: RhythmFishingFailReason, tension: number): void;
}

export interface RhythmFishingEngineOptions<ChartId extends string> {
  chartId: ChartId;
  chart: RhythmFishingChartData;
  now: () => number;
  assist?: boolean;
  initialTension?: number;
  initialCombo?: number;
  timing: RhythmFishingTiming;
  tension: RhythmFishingTension;
  events: RhythmFishingEngineEvents<ChartId>;
}

const WARNING_REARM_LOW = 30;
const WARNING_REARM_HIGH = 70;
const ACCURACY_EPSILON = 1e-9;

/**
 * Shared monotonic-clock rhythm judgment engine. It stores no scene, audio or
 * persistent state, so story charts and generated challenge segments use the
 * identical hit, hold, tension and completion rules.
 */
export class RhythmFishingEngine<ChartId extends string> {
  readonly notes: readonly RhythmFishingNote[];
  readonly totalNotes: number;
  readonly leadSec: number;
  readonly assist: boolean;

  private readonly events: RhythmFishingEngineEvents<ChartId>;
  private readonly chartId: ChartId;
  private readonly durationSeconds: number;
  private readonly noteList: RhythmFishingNote[];
  private readonly now: () => number;
  private readonly timing: RhythmFishingTiming;
  private readonly tensionRules: RhythmFishingTension;

  private sessionPhase: RhythmFishingSessionPhase = "idle";
  private t0Sec: number | null = null;
  private tensionValue: number;
  private comboCounter = 0;
  private maxComboCounter = 0;
  private judgedCounter = 0;
  private outOfBoundsSinceSec: number | null = null;
  private lowWarningFired = false;
  private highWarningFired = false;

  constructor(options: RhythmFishingEngineOptions<ChartId>) {
    this.events = options.events;
    this.chartId = options.chartId;
    this.now = options.now;
    this.timing = options.timing;
    this.tensionRules = options.tension;
    this.assist = options.assist === true;
    this.leadSec = this.assist ? options.timing.assistLeadSec : options.timing.leadSec;
    this.durationSeconds = options.chart.durationSeconds;
    this.tensionValue = typeof options.initialTension === "number" && Number.isFinite(options.initialTension)
      ? this.clampTension(options.initialTension)
      : options.tension.initial;
    this.comboCounter = typeof options.initialCombo === "number" && Number.isSafeInteger(options.initialCombo)
      ? Math.max(0, options.initialCombo)
      : 0;
    this.maxComboCounter = this.comboCounter;

    const notes: RhythmFishingNote[] = [];
    for (const rawNote of options.chart.notes) {
      if (this.assist && !Number.isInteger(rawNote.beat)) continue;
      const timeSec = rawNote.beat * options.timing.beatSec;
      const holdBeats = rawNote.hold ?? 0;
      notes.push({
        index: notes.length,
        beat: rawNote.beat,
        timeSec,
        spawnSec: timeSec - this.leadSec,
        action: rawNote.action,
        holdBeats,
        holdSec: holdBeats * options.timing.beatSec,
        cue: rawNote.cue ?? null,
        judgment: null,
        holding: false,
      });
    }
    this.noteList = notes;
    this.notes = notes;
    this.totalNotes = notes.length;
  }

  get phase(): RhythmFishingSessionPhase {
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
    return this.t0Sec === null ? 0 : this.now() - this.t0Sec;
  }

  start(): void {
    if (this.sessionPhase !== "idle") return;
    this.t0Sec = this.now();
    this.sessionPhase = "running";
  }

  handlePress(action: RhythmFishingAction): void {
    if (this.sessionPhase !== "running" || this.t0Sec === null) return;
    const elapsedSec = this.now() - this.t0Sec;
    const windowMs = this.goodWindowMs();
    let target: RhythmFishingNote | null = null;
    let targetAbsErrorMs = Number.POSITIVE_INFINITY;
    for (const note of this.noteList) {
      if (note.judgment !== null) continue;
      const absErrorMs = Math.abs((elapsedSec - note.timeSec) * 1000);
      if (absErrorMs <= windowMs && absErrorMs < targetAbsErrorMs) {
        target = note;
        targetAbsErrorMs = absErrorMs;
      }
    }
    if (target === null) return;

    const errorMs = (elapsedSec - target.timeSec) * 1000;
    if (target.action !== action) {
      this.judgeMiss(target, errorMs, this.tensionRules.wrongActionPenalty);
      return;
    }
    const judgment: Exclude<RhythmFishingJudgment, "miss"> =
      targetAbsErrorMs <= this.timing.perfectMs
        ? "perfect"
        : targetAbsErrorMs <= this.timing.greatMs
          ? "great"
          : "good";
    this.judgeHit(target, judgment, errorMs);
  }

  handleRelease(action: RhythmFishingAction): void {
    if (this.sessionPhase !== "running" || this.t0Sec === null) return;
    const elapsedSec = this.now() - this.t0Sec;
    for (const note of this.noteList) {
      if (!note.holding || note.action !== action) continue;
      if (elapsedSec < note.timeSec + note.holdSec - this.timing.holdReleaseSlackSec) {
        note.judgment = "miss";
        note.holding = false;
        this.comboCounter = 0;
        this.tensionValue = this.clampTension(this.tensionValue - this.tensionRules.holdBreakPenalty);
        this.events.onHoldBroken(note, this.tensionValue);
        this.checkWarningEdge();
      } else {
        note.holding = false;
      }
    }
  }

  /**
   * Clears held notes without applying a gameplay judgment. This is reserved
   * for host lifecycle boundaries such as blur, visibility pause and teardown,
   * where the matching keyup or pointerup may never reach the scene.
   */
  releaseHeldInputs(): void {
    for (const note of this.noteList) {
      if (note.holding) note.holding = false;
    }
  }

  update(): void {
    if (this.sessionPhase !== "running" || this.t0Sec === null) return;
    const nowSec = this.now();
    const elapsedSec = nowSec - this.t0Sec;
    const goodWindowMs = this.goodWindowMs();
    const goodWindowSec = goodWindowMs / 1000;
    for (const note of this.noteList) {
      if (note.judgment === null && elapsedSec > note.timeSec + goodWindowSec) {
        this.judgeMiss(note, goodWindowMs, -this.tensionRules.missPenalty);
      }
    }
    for (const note of this.noteList) {
      if (note.holding && elapsedSec >= note.timeSec + note.holdSec - this.timing.holdReleaseSlackSec) {
        note.holding = false;
      }
    }

    const escaped = this.tensionValue <= this.tensionRules.min;
    const snapped = this.tensionValue >= this.tensionRules.max;
    if (escaped || snapped) {
      if (this.outOfBoundsSinceSec === null) this.outOfBoundsSinceSec = nowSec;
      const sustainSec = (this.assist
        ? this.tensionRules.assistFailSustainMs
        : this.tensionRules.failSustainMs) / 1000;
      if (nowSec - this.outOfBoundsSinceSec >= sustainSec) {
        this.sessionPhase = "failed";
        this.events.onFailed(escaped ? "hook_escaped" : "line_snapped", this.tensionValue);
        return;
      }
    } else {
      this.outOfBoundsSinceSec = null;
    }

    if (this.judgedCounter >= this.totalNotes && nowSec - this.t0Sec >= this.durationSeconds) {
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
    return this.assist ? this.timing.assistGoodMs : this.timing.goodMs;
  }

  private judgeHit(
    note: RhythmFishingNote,
    judgment: Exclude<RhythmFishingJudgment, "miss">,
    errorMs: number,
  ): void {
    note.judgment = judgment;
    this.judgedCounter += 1;
    this.comboCounter += 1;
    if (this.comboCounter > this.maxComboCounter) this.maxComboCounter = this.comboCounter;
    const midpoint = (this.tensionRules.min + this.tensionRules.max) / 2;
    if (judgment === "perfect") {
      if (this.tensionValue > midpoint) {
        this.tensionValue = Math.max(midpoint, this.tensionValue - this.tensionRules.perfectRecover);
      } else if (this.tensionValue < midpoint) {
        this.tensionValue = Math.min(midpoint, this.tensionValue + this.tensionRules.perfectRecover);
      }
    } else {
      const shift = judgment === "great" ? this.tensionRules.greatShift : this.tensionRules.goodShift;
      this.tensionValue += errorMs < 0 ? shift : -shift;
    }
    this.tensionValue = this.clampTension(this.tensionValue);
    if (note.holdBeats > 0) note.holding = true;
    this.events.onNoteJudged(note, judgment, errorMs, this.tensionValue);
    this.checkWarningEdge();
  }

  private judgeMiss(note: RhythmFishingNote, errorMs: number, tensionDelta: number): void {
    note.judgment = "miss";
    this.judgedCounter += 1;
    this.comboCounter = 0;
    this.tensionValue = this.clampTension(this.tensionValue + tensionDelta);
    this.events.onNoteJudged(note, "miss", errorMs, this.tensionValue);
    this.checkWarningEdge();
  }

  private checkWarningEdge(): void {
    const tension = this.tensionValue;
    if (tension < this.tensionRules.warnLow) {
      if (!this.lowWarningFired) {
        this.lowWarningFired = true;
        this.events.onWarning("tension_low", tension);
      }
    } else if (tension > this.tensionRules.warnHigh) {
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

  private clampTension(value: number): number {
    return Math.min(this.tensionRules.max, Math.max(this.tensionRules.min, value));
  }

  private buildResult(): RhythmFishingResult<ChartId> {
    let perfect = 0;
    let great = 0;
    let good = 0;
    let miss = 0;
    let weightSum = 0;
    for (const note of this.noteList) {
      switch (note.judgment) {
        case "perfect": perfect += 1; weightSum += 1; break;
        case "great": great += 1; weightSum += 0.8; break;
        case "good": good += 1; weightSum += 0.55; break;
        default: miss += 1; break;
      }
    }
    const accuracy = this.totalNotes > 0 ? weightSum / this.totalNotes : 0;
    const first = this.noteList[0];
    const last = this.noteList[this.noteList.length - 1];
    const hooksLanded = first != null && first.judgment !== null && first.judgment !== "miss"
      && last != null && last.judgment !== null && last.judgment !== "miss";
    const passed = hooksLanded
      && accuracy >= 0.7 - ACCURACY_EPSILON
      && this.tensionValue >= this.tensionRules.passMin
      && this.tensionValue <= this.tensionRules.passMax;
    const grade: RhythmFishingGrade = accuracy >= 0.95 - ACCURACY_EPSILON && miss === 0
      ? "S"
      : accuracy >= 0.85 - ACCURACY_EPSILON
        ? "A"
        : accuracy >= 0.7 - ACCURACY_EPSILON ? "B" : "C";
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
