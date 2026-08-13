import type { EventBus } from "../core/EventBus";
import type {
  ClockArchiveClueId,
  ClockCalibrationStep,
  ClockCoarseLockId,
  ClockDriftChannelId,
  GameStore
} from "../core/types";
import content from "../data/chapter4-clock.content.json";

const SECONDS_PER_HOUR = 3600;
const SECONDS_PER_MINUTE = 60;
const REQUIRED_PHASE_LOCK_HITS = 3;
const REQUIRED_ARCHIVE_CLUES = 3;
const REQUIRED_COARSE_LOCKS = 2;
const REQUIRED_DRIFT_CHANNELS = 3;

export type ClockCalibrationResult =
  | "accepted"
  | "wrong_target"
  | "wrong_time"
  | "missed_lock"
  | "locked"
  | "already_complete";

/**
 * 第四章校时控制器。四关分别验证档案证据、双机芯、三路漂移和三种节奏，
 * 每关内部事实都进入正式存档，DEV 仅负责从这些事实构造测试入口。
 */
export class ClockCalibrationController {
  constructor(
    private readonly store: GameStore,
    private readonly events: EventBus
  ) {}

  toggleArchiveClue(clueId: ClockArchiveClueId): ClockCalibrationResult {
    const state = this.store.getState();
    const gate = this.checkStep(state.clockCalibration.step, "target_selection");
    if (gate) return gate;
    const current = state.clockCalibration.archiveClueIds;
    const archiveClueIds = current.includes(clueId)
      ? current.filter((id) => id !== clueId)
      : [...current, clueId];
    this.store.setState((value) => ({
      ...value,
      clockCalibration: { ...value.clockCalibration, archiveClueIds }
    }));
    this.events.emit("clock_archive_clue_changed", { clueId, selected: archiveClueIds.includes(clueId) });
    return "accepted";
  }

  selectTarget(seconds: number): ClockCalibrationResult {
    const state = this.store.getState();
    const gate = this.checkStep(state.clockCalibration.step, "target_selection");
    if (gate) return gate;
    const selectedTargetSeconds = wrapDaySeconds(seconds);
    if (
      selectedTargetSeconds !== state.clockCalibration.targetSeconds
      || state.clockCalibration.archiveClueIds.length !== REQUIRED_ARCHIVE_CLUES
    ) {
      this.store.setState((current) => ({
        ...current,
        clockCalibration: { ...current.clockCalibration, selectedTargetSeconds }
      }));
      this.events.emit("clock_target_rejected", { selectedTargetSeconds });
      return "wrong_target";
    }
    this.store.setState((current) => ({
      ...current,
      clockCalibration: {
        ...current.clockCalibration,
        phase: "calibrating",
        step: "coarse_time",
        selectedTargetSeconds,
        coarseLockIds: []
      }
    }));
    this.events.emit("clock_step_changed", { step: "coarse_time" });
    return "accepted";
  }

  adjustCoarseBy(unit: ClockCoarseLockId, delta: number): ClockCalibrationResult {
    const state = this.store.getState();
    const gate = this.checkStep(state.clockCalibration.step, "coarse_time");
    if (gate) return gate;
    if (!Number.isFinite(delta) || delta === 0 || state.clockCalibration.coarseLockIds.includes(unit)) return "locked";
    const current = splitClock(state.clockCalibration.displayedSeconds);
    const amount = Math.trunc(delta);
    const hours = unit === "hour" ? wrapUnit(current.hours + amount, 24) : current.hours;
    const minutes = unit === "minute" ? wrapUnit(current.minutes + amount, 60) : current.minutes;
    this.applyDisplayedSeconds(hours * SECONDS_PER_HOUR + minutes * SECONDS_PER_MINUTE + current.seconds);
    return "accepted";
  }

  lockCoarseUnit(unit: ClockCoarseLockId): ClockCalibrationResult {
    const state = this.store.getState();
    const gate = this.checkStep(state.clockCalibration.step, "coarse_time");
    if (gate) return gate;
    const displayed = splitClock(state.clockCalibration.displayedSeconds);
    const target = splitClock(state.clockCalibration.targetSeconds);
    const matches = unit === "hour" ? displayed.hours === target.hours : displayed.minutes === target.minutes;
    if (!matches) return "wrong_time";
    if (state.clockCalibration.coarseLockIds.includes(unit)) return "accepted";
    const coarseLockIds = [...state.clockCalibration.coarseLockIds, unit];
    this.store.setState((current) => ({
      ...current,
      clockCalibration: { ...current.clockCalibration, coarseLockIds }
    }));
    this.events.emit("clock_coarse_unit_locked", { unit, coarseLockIds });
    return "accepted";
  }

  confirmCoarseTime(): ClockCalibrationResult {
    const state = this.store.getState();
    const gate = this.checkStep(state.clockCalibration.step, "coarse_time");
    if (gate) return gate;
    if (state.clockCalibration.coarseLockIds.length !== REQUIRED_COARSE_LOCKS) return "wrong_time";
    this.store.setState((current) => ({
      ...current,
      clockCalibration: {
        ...current.clockCalibration,
        step: "seconds_trim",
        driftCorrectedChannelIds: [],
        driftAttempts: 0
      }
    }));
    this.events.emit("clock_step_changed", { step: "seconds_trim" });
    return "accepted";
  }

  correctDriftChannel(channelId: ClockDriftChannelId, correction: number): ClockCalibrationResult {
    const state = this.store.getState();
    const gate = this.checkStep(state.clockCalibration.step, "seconds_trim");
    if (gate) return gate;
    if (state.clockCalibration.driftCorrectedChannelIds.includes(channelId)) return "accepted";
    const expected = content.secondsTrim.channels.find((channel) => channel.id === channelId)?.expectedCorrection;
    if (expected === undefined || correction !== expected) {
      this.store.setState((current) => ({
        ...current,
        clockCalibration: { ...current.clockCalibration, driftAttempts: current.clockCalibration.driftAttempts + 1 }
      }));
      this.events.emit("clock_drift_channel_rejected", { channelId, correction });
      return "wrong_time";
    }
    const driftCorrectedChannelIds = [...state.clockCalibration.driftCorrectedChannelIds, channelId];
    const nextSeconds = driftCorrectedChannelIds.length === REQUIRED_DRIFT_CHANNELS
      ? state.clockCalibration.targetSeconds
      : state.clockCalibration.displayedSeconds;
    this.store.setState((current) => ({
      ...current,
      clockCalibration: {
        ...current.clockCalibration,
        displayedSeconds: nextSeconds,
        driftCorrectedChannelIds,
        driftAttempts: current.clockCalibration.driftAttempts + 1,
        adjustCount: current.clockCalibration.adjustCount + 1
      }
    }));
    this.events.emit("clock_drift_channel_corrected", { channelId, driftCorrectedChannelIds });
    return "accepted";
  }

  /** 兼容旧表冠入口：只在第三关开放，归零时作为三路漂移全部修正。 */
  adjustBySeconds(deltaSeconds: number): boolean {
    const state = this.store.getState();
    if (!this.canUseClock() || state.clockCalibration.step !== "seconds_trim") return false;
    if (!Number.isFinite(deltaSeconds) || deltaSeconds === 0) return false;
    const target = splitClock(state.clockCalibration.targetSeconds);
    const displayed = splitClock(state.clockCalibration.displayedSeconds);
    const seconds = clamp(displayed.seconds + Math.trunc(deltaSeconds), 0, 59);
    const changed = this.applyDisplayedSeconds(target.hours * SECONDS_PER_HOUR + target.minutes * SECONDS_PER_MINUTE + seconds);
    if (changed && seconds === 0) this.markAllDriftChannelsCorrected();
    return changed;
  }

  setDisplayedSeconds(seconds: number): boolean {
    const state = this.store.getState();
    if (!this.canUseClock() || state.clockCalibration.step !== "seconds_trim") return false;
    if (!Number.isFinite(seconds)) return false;
    const target = splitClock(state.clockCalibration.targetSeconds);
    const requested = splitClock(wrapDaySeconds(seconds));
    const changed = this.applyDisplayedSeconds(target.hours * SECONDS_PER_HOUR + target.minutes * SECONDS_PER_MINUTE + requested.seconds);
    if (changed && requested.seconds === 0) this.markAllDriftChannelsCorrected();
    return changed;
  }

  confirmPrecision(): ClockCalibrationResult {
    const state = this.store.getState();
    const gate = this.checkStep(state.clockCalibration.step, "seconds_trim");
    if (gate) return gate;
    if (
      state.clockCalibration.displayedSeconds !== state.clockCalibration.targetSeconds
      || state.clockCalibration.driftCorrectedChannelIds.length !== REQUIRED_DRIFT_CHANNELS
    ) return "wrong_time";
    this.store.setState((current) => ({
      ...current,
      clockCalibration: {
        ...current.clockCalibration,
        phase: "release_ready",
        step: "phase_lock",
        phaseLockHits: 0
      }
    }));
    this.events.emit("clock_release_ready", { text: content.toastReleaseReady });
    this.events.emit("clock_step_changed", { step: "phase_lock" });
    this.events.emit("toast", { text: content.toastReleaseReady, tone: "system" });
    return "accepted";
  }

  submitPhaseLock(hit: boolean): ClockCalibrationResult {
    const state = this.store.getState();
    const gate = this.checkStep(state.clockCalibration.step, "phase_lock");
    if (gate) return gate;
    const phaseLockAttempts = state.clockCalibration.phaseLockAttempts + 1;
    const phaseLockHits = hit ? state.clockCalibration.phaseLockHits + 1 : 0;
    if (!hit) {
      this.store.setState((current) => ({
        ...current,
        clockCalibration: { ...current.clockCalibration, phaseLockAttempts, phaseLockHits }
      }));
      this.events.emit("clock_phase_lock_attempted", { hit: false, phaseLockHits, phaseLockAttempts });
      return "missed_lock";
    }
    if (phaseLockHits < REQUIRED_PHASE_LOCK_HITS) {
      this.store.setState((current) => ({
        ...current,
        clockCalibration: { ...current.clockCalibration, phaseLockAttempts, phaseLockHits }
      }));
      this.events.emit("clock_phase_lock_attempted", { hit: true, phaseLockHits, phaseLockAttempts });
      return "accepted";
    }
    this.store.setState((current) => ({
      ...current,
      clockCalibration: {
        ...current.clockCalibration,
        phase: "aligned",
        step: "complete",
        displayedSeconds: current.clockCalibration.targetSeconds,
        phaseLockHits: REQUIRED_PHASE_LOCK_HITS,
        phaseLockAttempts
      },
      chapter4: {
        ...current.chapter4,
        phase: "complete",
        buildingTimeSeconds: current.clockCalibration.targetSeconds,
        solvedPuzzleIds: appendUnique(current.chapter4.solvedPuzzleIds, "clock_phase_lock"),
        completed: true
      }
    }));
    this.events.emit("clock_phase_lock_attempted", { hit: true, phaseLockHits: REQUIRED_PHASE_LOCK_HITS, phaseLockAttempts });
    this.events.emit("clock_calibration_aligned", { text: content.toastAligned });
    this.events.emit("chapter4_clock_phase_lock_completed");
    this.events.emit("toast", { text: content.toastAligned, tone: "system" });
    return "accepted";
  }

  confirmAlignment(): boolean {
    return this.submitPhaseLock(true) === "accepted";
  }

  resetCurrentStep(): boolean {
    const state = this.store.getState();
    if (!this.canUseClock() || state.clockCalibration.step === "complete") return false;
    const step = state.clockCalibration.step;
    const displayedSeconds = step === "seconds_trim" ? state.clockCalibration.targetSeconds + 23 : step === "phase_lock" ? state.clockCalibration.targetSeconds : 28523;
    this.store.setState((current) => ({
      ...current,
      clockCalibration: {
        ...current.clockCalibration,
        displayedSeconds,
        selectedTargetSeconds: step === "target_selection" ? null : current.clockCalibration.targetSeconds,
        archiveClueIds: step === "target_selection" ? [] : current.clockCalibration.archiveClueIds,
        coarseLockIds: step === "coarse_time" ? [] : current.clockCalibration.coarseLockIds,
        driftCorrectedChannelIds: step === "seconds_trim" ? [] : current.clockCalibration.driftCorrectedChannelIds,
        phaseLockHits: step === "phase_lock" ? 0 : current.clockCalibration.phaseLockHits
      }
    }));
    this.events.emit("clock_step_reset", { step });
    return true;
  }

  private markAllDriftChannelsCorrected(): void {
    this.store.setState((state) => ({
      ...state,
      clockCalibration: {
        ...state.clockCalibration,
        driftCorrectedChannelIds: ["gate", "elevator", "room"]
      }
    }));
  }

  private canUseClock(): boolean {
    const state = this.store.getState();
    return state.chapter4.phase === "clock_phase_lock" && state.clockCalibration.step !== "complete" && state.clockCalibration.phase !== "aligned";
  }

  private checkStep(actual: ClockCalibrationStep, expected: ClockCalibrationStep): Exclude<ClockCalibrationResult, "accepted" | "wrong_target" | "wrong_time" | "missed_lock"> | null {
    if (actual === "complete" || this.store.getState().clockCalibration.phase === "aligned") return "already_complete";
    if (!this.canUseClock() || actual !== expected) return "locked";
    return null;
  }

  private applyDisplayedSeconds(displayedSeconds: number): boolean {
    const state = this.store.getState();
    const normalized = wrapDaySeconds(displayedSeconds);
    if (normalized === state.clockCalibration.displayedSeconds) return false;
    this.store.setState((current) => ({
      ...current,
      clockCalibration: {
        ...current.clockCalibration,
        displayedSeconds: normalized,
        adjustCount: current.clockCalibration.adjustCount + 1
      }
    }));
    this.events.emit("clock_time_adjusted", { displayedSeconds: normalized });
    return true;
  }
}

function splitClock(seconds: number) {
  const normalized = wrapDaySeconds(seconds);
  return {
    hours: Math.floor(normalized / SECONDS_PER_HOUR),
    minutes: Math.floor((normalized % SECONDS_PER_HOUR) / SECONDS_PER_MINUTE),
    seconds: normalized % SECONDS_PER_MINUTE
  };
}

function wrapUnit(value: number, size: number) {
  return ((value % size) + size) % size;
}

function wrapDaySeconds(seconds: number) {
  return wrapUnit(Math.trunc(seconds), 86400);
}

function clamp(value: number, min: number, max: number) {
  return Math.max(min, Math.min(max, value));
}

function appendUnique<T>(values: T[], value: T): T[] {
  return values.includes(value) ? values : [...values, value];
}
