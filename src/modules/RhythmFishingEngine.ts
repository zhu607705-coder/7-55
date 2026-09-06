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
  protocol: "lake-rhythm-v3";
  assist: boolean;
  finishedAtSec: number;
  inputs: readonly RhythmFishingInputEvent[];
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

export interface RhythmFishingInputEvent { type: "press" | "release" | "neutral"; action: RhythmFishingAction; timeSec: number }
export const LAKE_FISHING_TIMING = Object.freeze({
  beatSec: 0.6, leadSec: 1.6, assistLeadSec: 1.6,
  perfectMs: 100, greatMs: 190, goodMs: 280, assistGoodMs: 350, holdReleaseSlackSec: 0.08
});
export const LAKE_FISHING_TENSION = Object.freeze({
  initial: 40, min: 15, max: 100, perfectRecover: 9, greatShift: 6, goodShift: 6,
  missPenalty: 22, wrongActionPenalty: 22, holdBreakPenalty: 22,
  warnLow: 0, warnHigh: 80, passMin: 0, passMax: 99, failSustainMs: 0, assistFailSustainMs: 0
});
export const LAKE_FISHING_HOLD_MIN_SEC = 0.24;
export const LAKE_FISHING_PULLS = 8;
export const LAKE_FISHING_INPUT_LIMIT = 4096;
export function createLakeFishingChart(beatSec = LAKE_FISHING_TIMING.beatSec): RhythmFishingChartData {
  return { durationSeconds: 33 * beatSec, notes: Array.from({ length: LAKE_FISHING_PULLS }, (_, i) => ({ beat: 3 + i * 4, action: "hook", hold: LAKE_FISHING_HOLD_MIN_SEC / beatSec })) };
}

export type LakeFishingStage = "casting" | "count_in" | "fighting";
const PHYSICS_HZ = 120;
const LINE_SPEED = 1.3;
const clamp = (value: number, min: number, max: number) => Math.max(min, Math.min(max, value));

/** Aim the cast, track the fish, ease off its rushes and lift on the gold flash. */
export class RhythmFishingEngine<ChartId extends string> {
  readonly notes: readonly RhythmFishingNote[];
  readonly totalNotes: number;
  readonly beatSec: number;
  readonly leadSec = LAKE_FISHING_TIMING.leadSec;
  readonly assist: boolean;
  private readonly events: RhythmFishingEngineEvents<ChartId>;
  private readonly chartId: ChartId;
  private readonly now: () => number;
  private phaseValue: RhythmFishingSessionPhase = "idle";
  private stageValue: LakeFishingStage = "casting";
  private armed = false;
  private t0Sec: number | null = null;
  private castAt: number | null = null;
  private heldAt: number | null = null;
  private controls = new Set<RhythmFishingAction>();
  private tensionValue: number;
  private linePosition = -0.5;
  private trackingSeconds = 0;
  private castAttemptsValue = 0;
  private comboValue = 0;
  private maxComboValue = 0;
  private judged = 0;
  private trace: RhythmFishingInputEvent[] = [];
  private lastElapsed = 0;
  private physicsTick = 0;
  private lastCueValue = "左右移动浮漂，对准鱼影；按住蓄力，松手抛竿";

  constructor(options: RhythmFishingEngineOptions<ChartId>) {
    this.beatSec = options.timing.beatSec;
    this.events = options.events; this.chartId = options.chartId; this.now = options.now; this.assist = options.assist === true;
    this.tensionValue = clamp(Number.isFinite(options.initialTension) ? options.initialTension! : 40, 20, 75);
    this.comboValue = Number.isSafeInteger(options.initialCombo) ? clamp(options.initialCombo!, 0, 1_000_000) : 0;
    this.maxComboValue = this.comboValue;
    this.notes = options.chart.notes.slice(0, 64).map((raw, index) => ({
      index, beat: raw.beat, timeSec: raw.beat * options.timing.beatSec,
      spawnSec: raw.beat * options.timing.beatSec - this.leadSec, action: "hook",
      holdBeats: LAKE_FISHING_HOLD_MIN_SEC / options.timing.beatSec,
      holdSec: LAKE_FISHING_HOLD_MIN_SEC, cue: null, judgment: null, holding: false
    }));
    if (!this.notes.length || this.notes.some((note, i) => !Number.isFinite(note.timeSec) || note.timeSec <= 0 || (i > 0 && note.timeSec <= this.notes[i - 1].timeSec))) throw new Error("Invalid lake fishing chart");
    this.totalNotes = this.notes.length;
  }
  get phase(): RhythmFishingSessionPhase { return this.phaseValue; }
  get stage(): LakeFishingStage { return this.stageValue; }
  get tension(): number { return Math.round(this.tensionValue * 1000) / 1000; }
  get combo(): number { return this.comboValue; }
  get maxCombo(): number { return this.maxComboValue; }
  get judgedCount(): number { return this.judged; }
  get isHolding(): boolean { return this.controls.has("hook"); }
  get startedAtSec(): number | null { return this.t0Sec; }
  get musicStartedAtSec(): number | null { return this.castAt === null || this.t0Sec === null ? null : this.t0Sec + this.castAt; }
  get fightStartedAtSec(): number | null { return this.musicStartedAtSec === null ? null : this.musicStartedAtSec + 4 * this.beatSec; }
  get rhythmBeat(): number { return this.castAt===null ? 0 : Math.floor(Math.max(0,this.elapsedSec-this.castAt)/this.beatSec)%4; }
  get beatProgress(): number { return this.castAt===null ? 0 : (Math.max(0,this.elapsedSec-this.castAt)/this.beatSec)%1; }
  get countIn(): number { return this.stageValue!=="count_in"||this.castAt===null ? 0 : Math.max(1,4-Math.floor((this.elapsedSec-this.castAt)/this.beatSec)); }
  get lastCue(): string { return this.lastCueValue; }
  get currentNote(): RhythmFishingNote | null { return this.notes.find(note => note.judgment === null) ?? null; }
  get lineX(): number { return this.linePosition; }
  get fishX(): number { return this.fishAt(this.physicsTick / PHYSICS_HZ); }
  get castAttempts(): number { return this.castAttemptsValue; }
  get castPower(): number { return this.heldAt === null ? 0 : clamp((this.elapsedSec - this.heldAt) / 1.2, 0, 1); }
  get tracking(): number { return clamp(this.trackingSeconds / 0.42, 0, 1); }
  get aligned(): boolean { return Math.abs(this.lineX - this.fishX) <= (this.assist ? 0.34 : 0.25); }
  get fishRushing(): boolean { return this.rushingAt(this.physicsTick / PHYSICS_HZ); }
  get liftReady(): boolean { return this.stageValue === "fighting" && Math.abs((this.currentNote?.timeSec ?? -100) - this.elapsedSec) <= this.goodWindow; }
  get elapsedSec(): number {
    if (this.t0Sec === null) return 0;
    const value = this.now() - this.t0Sec;
    if (Number.isFinite(value)) this.lastElapsed = Math.max(this.lastElapsed, value);
    return this.lastElapsed;
  }
  private get goodWindow(): number { return (this.assist ? LAKE_FISHING_TIMING.assistGoodMs : LAKE_FISHING_TIMING.goodMs) / 1000; }
  start(): void { if (this.phaseValue === "idle") this.armed = true; }

  handlePress(action: RhythmFishingAction): void {
    if (!this.armed || this.controls.has(action) || !["idle", "running"].includes(this.phaseValue)) return;
    if (this.t0Sec === null) { this.t0Sec = this.now(); this.phaseValue = "running"; }
    const elapsed = this.elapsedSec;
    this.updateAt(elapsed);
    if (this.phaseValue !== "running" || !this.record("press", action, elapsed)) return;
    this.controls.add(action);
    if (action === "hook") {
      this.heldAt = elapsed;
      if (this.currentNote) this.currentNote.holding = true;
      this.lastCueValue = this.stageValue === "casting" ? "蓄到绿色范围，松手抛竿" : this.fishRushing ? "它在猛拽，松手放线！" : "左右跟住鱼影，按住收线";
    }
  }
  handleRelease(action: RhythmFishingAction): void {
    if (!this.controls.has(action) || this.phaseValue !== "running") return;
    const elapsed = this.elapsedSec;
    this.updateAt(elapsed);
    if (this.phaseValue !== "running" || !this.record("release", action, elapsed)) return;
    this.controls.delete(action);
    if (action !== "hook") return;
    const heldFor = elapsed - (this.heldAt ?? elapsed);
    this.heldAt = null;
    this.notes.forEach(note => { note.holding = false; });
    if (this.stageValue === "casting") {
      this.castAttemptsValue++;
      const power = heldFor / 1.2;
      if (Math.abs(this.lineX - this.fishX) > (this.assist ? 0.4 : 0.3)) { this.lastCueValue = "抛偏了：左右移动浮漂，先对准鱼影"; return; }
      if (power < 0.3 || power > 0.9) { this.lastCueValue = power < 0.3 ? "太轻了：按住蓄到绿色范围再松手" : "太重了：这次早一点松手"; return; }
      this.stageValue = "count_in"; this.castAt = elapsed; this.trackingSeconds = 0;
      this.notes.forEach(note => { note.timeSec += elapsed + 4 * this.beatSec; note.spawnSec += elapsed + 4 * this.beatSec; });
      this.lastCueValue = "跟着预备拍：稳、放、收、提";
      return;
    }
    if (this.stageValue !== "fighting") return;
    const note = this.currentNote;
    if (!note) return;
    const errorMs = (elapsed - note.timeSec) * 1000;
    // Releasing outside the gold window is a deliberate tension-management action.
    if (Math.abs(errorMs) > this.goodWindow * 1000 + 1e-6) { this.lastCueValue = "放线缓一缓，等鱼影闪金再收竿"; return; }
    const stable = this.trackingSeconds >= (this.assist ? 0.25 : 0.42) - 1e-6 && this.aligned;
    const heldEnough = heldFor >= LAKE_FISHING_HOLD_MIN_SEC - 1e-6;
    const safeLine = this.tensionValue < 88;
    const magnitude = Math.abs(errorMs);
    const judgment: RhythmFishingJudgment = !stable || !heldEnough || !safeLine ? "miss"
      : magnitude <= LAKE_FISHING_TIMING.perfectMs + 1e-6 ? "perfect" : magnitude <= LAKE_FISHING_TIMING.greatMs + 1e-6 ? "great" : "good";
    if (!heldEnough) this.events.onHoldBroken(note, this.tension);
    this.judge(note, judgment, errorMs, elapsed);
    if (judgment === "miss") this.lastCueValue = !stable ? "鱼影没跟住：左右控线，再择机收竿" : !safeLine ? "线太紧了：猛拽时松手放线" : "收线太短：先按住稳住，再松手";
  }

  releaseHeldInputs(): void {
    if (this.controls.size && this.phaseValue === "running") {
      const elapsed = this.elapsedSec; this.updateAt(elapsed);
      if (this.phaseValue === "running") this.record("neutral", "hook", elapsed);
    }
    this.controls.clear(); this.heldAt = null;
    this.notes.forEach(note => { note.holding = false; });
  }
  update(): void { this.updateAt(this.elapsedSec); }
  private fishAt(time: number): number {
    if (this.castAt === null) return 0.42 + Math.sin(time * 0.6) * 0.07;
    const t = Math.max(0, time - this.castAt - 4 * this.beatSec);
    return clamp(0.59 * Math.sin(t * 1.05 + 0.8) + 0.12 * Math.sin(t * 2.1 + 0.2), -0.8, 0.8);
  }
  private rushingAt(time: number): boolean {
    if (this.stageValue !== "fighting") return false;
    const remaining = (this.currentNote?.timeSec ?? -100) - time;
    return remaining > this.beatSec && remaining <= 2 * this.beatSec;
  }
  private updateAt(elapsed: number): void {
    if (this.phaseValue !== "running") return;
    if (elapsed > 180) { this.fail("hook_escaped"); return; }
    const targetTick = Math.floor(elapsed * PHYSICS_HZ + 1e-7);
    while (this.physicsTick < targetTick && this.phaseValue === "running") {
      this.physicsTick++;
      const time = this.physicsTick / PHYSICS_HZ, dt = 1 / PHYSICS_HZ;
      const axis = Number(this.controls.has("right")) - Number(this.controls.has("left"));
      this.linePosition = clamp(this.linePosition + axis * LINE_SPEED * dt, -1, 1);
      if (this.stageValue === "count_in" && this.castAt!==null && time >= this.castAt + 4*this.beatSec) this.stageValue="fighting";
      if (this.stageValue !== "fighting") continue;
      const aligned = Math.abs(this.linePosition - this.fishAt(time)) <= (this.assist ? 0.34 : 0.25);
      const reeling = this.controls.has("hook");
      if (aligned && reeling && !this.rushingAt(time)) this.trackingSeconds += dt;
      else this.trackingSeconds = Math.max(0, this.trackingSeconds - dt * (aligned ? 0.15 : 0.8));
      const pull = reeling ? this.rushingAt(time) ? 45 : aligned ? 6 : 17 : -22;
      this.tensionValue = clamp(this.tensionValue + pull * dt, 15, 100);
      if (this.tensionValue >= 100) { this.fail("line_snapped"); break; }
      const note = this.currentNote;
      if (note && time > note.timeSec + this.goodWindow + 1e-7) this.judge(note, "miss", (time - note.timeSec) * 1000, time);
    }
  }
  cancel(): void {
    if (["idle", "running"].includes(this.phaseValue)) this.phaseValue = "cancelled";
    this.controls.clear(); this.heldAt = null; this.notes.forEach(note => { note.holding = false; });
  }
  private record(type: RhythmFishingInputEvent["type"], action: RhythmFishingAction, timeSec: number): boolean {
    if (this.trace.length >= LAKE_FISHING_INPUT_LIMIT) { this.fail("hook_escaped"); return false; }
    this.trace.push({ type, action, timeSec }); return true;
  }
  private judge(note: RhythmFishingNote, judgment: RhythmFishingJudgment, errorMs: number, atSec: number): void {
    if (note.judgment !== null || this.phaseValue !== "running") return;
    note.judgment = judgment; note.holding = false; this.judged++;
    this.trackingSeconds = 0;
    if (judgment === "miss") { this.comboValue = 0; this.tensionValue = Math.min(100, this.tensionValue + 22); this.lastCueValue = "脱了一钩，先跟住鱼影再提竿"; }
    else { this.comboValue = Math.min(1_000_000, this.comboValue + 1); this.maxComboValue = Math.max(this.maxComboValue, this.comboValue); this.tensionValue = Math.max(15, this.tensionValue - (judgment === "perfect" ? 9 : 6)); this.lastCueValue = "收近了！留意下一次猛拽"; }
    this.events.onNoteJudged(note, judgment, errorMs, this.tension);
    if (this.tensionValue >= 100) { this.fail("line_snapped"); return; }
    if (this.tensionValue >= 80) this.events.onWarning("tension_high", this.tension);
    if (this.judged === this.totalNotes) this.complete(atSec);
  }
  private complete(atSec: number): void {
    if (this.phaseValue !== "running") return;
    this.phaseValue = "completed"; this.controls.clear(); this.heldAt = null;
    const count = (j: RhythmFishingJudgment) => this.notes.filter(note => note.judgment === j).length;
    const perfect = count("perfect"), great = count("great"), good = count("good"), miss = count("miss");
    const accuracy = (perfect + great * 0.85 + good * 0.6) / this.totalNotes;
    const passed = perfect + great + good >= Math.ceil(this.totalNotes * 0.75);
    const grade: RhythmFishingGrade = passed ? accuracy >= 0.9 ? "S" : accuracy >= 0.75 ? "A" : "B" : "C";
    this.events.onCompleted({ chartId: this.chartId, grade, passed, accuracy, perfect, great, good, miss, maxCombo: this.maxComboValue,
      finalTension: this.tension, protocol: "lake-rhythm-v3", assist: this.assist, finishedAtSec: atSec, inputs: this.trace.map(event => ({ ...event })) });
  }
  private fail(reason: RhythmFishingFailReason): void {
    if (!["idle", "running"].includes(this.phaseValue)) return;
    this.phaseValue = "failed"; this.controls.clear(); this.heldAt = null;
    this.events.onFailed(reason, this.tension);
  }
}

/** Replay every directional input, cast and lift before any story item can be awarded. */
export function validateLakeFishingResult(value: unknown, expectedChartId: string): boolean {
  if (!value || typeof value !== "object") return false;
  const result = value as Partial<RhythmFishingResult<string>>;
  if (result.protocol !== "lake-rhythm-v3" || result.chartId !== expectedChartId || result.passed !== true || typeof result.assist !== "boolean"
    || !Array.isArray(result.inputs) || result.inputs.length < 8 || result.inputs.length > LAKE_FISHING_INPUT_LIMIT
    || typeof result.finishedAtSec !== "number" || !Number.isFinite(result.finishedAtSec) || result.finishedAtSec < 0 || result.finishedAtSec > 180) return false;
  let now = 0, last = -1, replay: RhythmFishingResult<string> | null = null;
  const engine = new RhythmFishingEngine({ chartId: expectedChartId, chart: createLakeFishingChart(), now: () => now, assist: result.assist,
    timing: LAKE_FISHING_TIMING, tension: LAKE_FISHING_TENSION, events: { onNoteJudged() {}, onHoldBroken() {}, onWarning() {}, onFailed() {}, onCompleted(r) { replay = r; } } });
  engine.start();
  for (const event of result.inputs) {
    if (!event || !["press", "release", "neutral"].includes(event.type) || !["left", "right", "hook"].includes(event.action)
      || !Number.isFinite(event.timeSec) || event.timeSec < last || event.timeSec < 0 || event.timeSec > result.finishedAtSec + 1e-6) return false;
    if (last === -1 && (event.type !== "press" || Math.abs(event.timeSec) > 1e-6)) return false;
    if (engine.phase === "completed" || engine.phase === "failed") return false;
    now = event.timeSec; last = now;
    if (event.type === "press") engine.handlePress(event.action);
    else if (event.type === "release") engine.handleRelease(event.action);
    else engine.releaseHeldInputs();
  }
  now = result.finishedAtSec; engine.update();
  const verified = replay as RhythmFishingResult<string> | null;
  return Boolean(verified?.passed && ["grade", "perfect", "great", "good", "miss", "maxCombo", "finalTension"].every(key => verified[key as keyof typeof verified] === result[key as keyof typeof result])
    && typeof result.accuracy === "number" && Math.abs(verified.accuracy - result.accuracy) < 1e-6);
}
