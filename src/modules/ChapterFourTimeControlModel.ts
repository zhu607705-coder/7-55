import type {
  ChapterFourFactId,
  ChapterFourPhase,
  ChapterFourState,
  ChapterFourTimeState,
  GameState
} from "../core/types";
import chapterFour755Content from "../data/chapter4-755.content.json";

interface PhaseTimeContract {
  id: ChapterFourPhase;
  timeState: ChapterFourTimeState;
}

interface TimeContract {
  id: ChapterFourTimeState;
  worldTimeSeconds: number;
  phoneStatusTimeSeconds: number;
  phoneStatusTimeTrusted: boolean;
}

export interface ChapterFourClockTimeOption extends TimeContract {
  label: string;
}

const PHASE_TIME_CONTRACTS = chapterFour755Content.phaseContracts as readonly PhaseTimeContract[];
const TIME_CONTRACTS = chapterFour755Content.time.states as readonly TimeContract[];
const TIME_LABELS: Readonly<Record<ChapterFourTimeState, string>> = Object.freeze({
  "2245_opening": "22:45",
  "1225_bakery": "12:25",
  "1850_evening": "18:50",
  "2245_maintenance": "22:45",
  "0754_blackout": "07:54",
  "0755_morning": "07:55"
});

const CLOCK_CONTROL_TIME_ORDER = Object.freeze([
  "1225_bakery",
  "1850_evening",
  "2245_maintenance"
] as const satisfies readonly ChapterFourTimeState[]);

const ACTIVE_PHASES = new Set<ChapterFourPhase>(
  PHASE_TIME_CONTRACTS.map((contract) => contract.id)
);

type ChapterFourRuntimeTimeState = Pick<
  GameState["chapter4"],
  "phase" | "timeState"
>;

type ChapterFourRuntimeClockState = Pick<
  GameState["chapter4"],
  "phase" | "timeState" | "factIds"
>;

function isActiveChapterFourPhase(
  phase: GameState["chapter4"]["phase"]
): phase is ChapterFourPhase {
  return ACTIVE_PHASES.has(phase as ChapterFourPhase);
}

function hasFact(
  state: Pick<ChapterFourState, "factIds">,
  factId: ChapterFourFactId
): boolean {
  return state.factIds.includes(factId);
}

export function chapterFourExpectedTimeState(
  phase: ChapterFourPhase
): ChapterFourTimeState {
  const contract = PHASE_TIME_CONTRACTS.find((candidate) => candidate.id === phase);
  if (!contract) throw new Error(`chapter4_time_control_missing_phase:${phase}`);
  return contract.timeState;
}

export function chapterFourTimeContract(
  timeState: ChapterFourTimeState
): Readonly<TimeContract> {
  const contract = TIME_CONTRACTS.find((candidate) => candidate.id === timeState);
  if (!contract) throw new Error(`chapter4_time_control_missing_time:${timeState}`);
  return contract;
}

export function isChapterFourPhaseTimeAligned(
  state: ChapterFourRuntimeTimeState
): boolean {
  return isActiveChapterFourPhase(state.phase)
    && state.timeState === chapterFourExpectedTimeState(state.phase);
}

/**
 * Returns the next clock setting whose physical prerequisite has already been
 * produced. The target is deliberately inferred from controller-owned facts;
 * the clock panel cannot unlock a future period on its own.
 */
export function selectChapterFourRequiredClockTime(
  state: ChapterFourRuntimeClockState
): ChapterFourTimeState | null {
  if (!isActiveChapterFourPhase(state.phase)) return null;
  if (state.phase === "hall_clock_inspection"
    && hasFact(state, "hall_clock_inspected")
    && state.timeState === "2245_opening") {
    return "1225_bakery";
  }
  if (state.phase === "room204_restore"
    && hasFact(state, "hour_hand_installed")
    && state.timeState !== "1850_evening") {
    return "1850_evening";
  }
  if (state.phase === "maintenance_repair"
    && hasFact(state, "positioning_plate_installed")
    && state.timeState !== "2245_maintenance") {
    return "2245_maintenance";
  }
  return null;
}

export function isChapterFourClockControlAvailable(
  state: ChapterFourRuntimeClockState
): boolean {
  return selectChapterFourRequiredClockTime(state) !== null;
}

export function selectChapterFourClockTimeOptions(
  gameState: Pick<GameState, "chapter4">
): readonly ChapterFourClockTimeOption[] {
  const chapter = gameState.chapter4;
  const required = selectChapterFourRequiredClockTime(chapter);
  const ids = new Set<ChapterFourTimeState>([chapter.timeState]);
  if (required) ids.add(required);

  const ordered = [
    "2245_opening" as const,
    ...CLOCK_CONTROL_TIME_ORDER
  ].filter((timeState) => ids.has(timeState));

  return Object.freeze(ordered.map((timeState) => Object.freeze({
    ...chapterFourTimeContract(timeState),
    label: TIME_LABELS[timeState]
  })));
}

/** SaveStore accepts only these two deliberate, pre-adjustment mismatches. */
export function isChapterFourPendingClockTimeState(
  phase: ChapterFourPhase,
  timeState: ChapterFourTimeState,
  factIds: readonly ChapterFourFactId[]
): boolean {
  if (phase === "room204_restore") {
    return timeState === "1225_bakery" && factIds.includes("hour_hand_installed");
  }
  if (phase === "maintenance_repair") {
    return timeState === "1850_evening" && factIds.includes("positioning_plate_installed");
  }
  return false;
}
