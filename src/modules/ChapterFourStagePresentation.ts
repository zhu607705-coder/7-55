import type {
  ChapterFourFactId,
  ChapterFourPhase,
  ChapterFourQuestPresentationContext,
  ChapterFourTimeAuthority,
  ChapterFourTimeState,
  GameState
} from "../core/types";
import chapterFour755Content from "../data/chapter4-755.content.json";
import chapterFourTemporalMazeContent from "../data/chapter4-temporal-maze.content.json";
import { CHAPTER_FOUR_LIGHT_GRID } from "./ChapterFourLightGridModel";
import { normalizeRoom204Placements } from "../scenes/rpg/ChapterFourRoom204Model";

interface PhasePresentationCopy {
  stageLabel: string;
  currentDifference: string;
}

interface TimeStatePresentationCopy {
  timeStateLabel: string;
}

interface PhaseContract {
  id: ChapterFourPhase;
  timeAuthority: ChapterFourTimeAuthority;
  timeState: ChapterFourTimeState;
}

interface TimeContract {
  id: ChapterFourTimeState;
  phoneStatusTimeTrusted: boolean;
}

interface PresentationContextCopy {
  timeSources: Readonly<Record<ChapterFourTimeAuthority, string>>;
  trustStates: {
    trusted: string;
    untrusted: string;
  };
}

export type ChapterFourStagePresentation = ChapterFourQuestPresentationContext;

const PHASE_IDS = chapterFour755Content.orderedPhases as readonly ChapterFourPhase[];
const TIME_STATE_IDS = chapterFour755Content.time.stateOrder as readonly ChapterFourTimeState[];
const PHASE_CONTRACTS = chapterFour755Content.phaseContracts as readonly PhaseContract[];
const TIME_CONTRACTS = chapterFour755Content.time.states as readonly TimeContract[];
const PHASE_COPY = chapterFour755Content.presentation.phaseCopy as Readonly<
  Record<ChapterFourPhase, PhasePresentationCopy>
>;
const TIME_STATE_COPY = chapterFour755Content.presentation.timeStateCopy as Readonly<
  Record<ChapterFourTimeState, TimeStatePresentationCopy>
>;
const FACT_LABELS = chapterFour755Content.presentation.factLabels as Readonly<
  Record<ChapterFourFactId, string>
>;
const CONTEXT_COPY = chapterFourTemporalMazeContent.presentationContext as PresentationContextCopy;
const PHASE_ID_SET = new Set<ChapterFourPhase>(PHASE_IDS);

export interface ChapterFourStagePresentationValidation {
  phaseCount: 13;
  timeStateCount: 6;
  opening2245Label: string;
  maintenance2245Label: string;
}

/**
 * Validates presentation coverage against the existing controller contracts.
 * This checks labels and coverage only; the controller remains the sole phase graph.
 */
export function validateChapterFourStagePresentationContract(): ChapterFourStagePresentationValidation {
  assertExactUniqueIds(PHASE_IDS, Object.keys(PHASE_COPY), 13, "phase");
  assertExactUniqueIds(TIME_STATE_IDS, Object.keys(TIME_STATE_COPY), 6, "time_state");
  assertUniqueText(PHASE_IDS.map((phase) => PHASE_COPY[phase].stageLabel), "stage_label");
  assertUniqueText(TIME_STATE_IDS.map((timeState) => TIME_STATE_COPY[timeState].timeStateLabel), "time_state_label");

  const openingPhase = requirePhaseContract("opening_handoff");
  const maintenancePhase = requirePhaseContract("maintenance_repair");
  const openingTime = requireTimeContract(openingPhase.timeState);
  const maintenanceTime = requireTimeContract(maintenancePhase.timeState);
  const openingLabel = TIME_STATE_COPY[openingPhase.timeState].timeStateLabel;
  const maintenanceLabel = TIME_STATE_COPY[maintenancePhase.timeState].timeStateLabel;
  if (openingLabel !== "现场 22:45 · 手机 07:55:23 未同步"
    || maintenanceLabel !== "旧钟 22:45 · 维修时段 · 手机已同步"
    || openingPhase.timeAuthority === maintenancePhase.timeAuthority
    || openingTime.phoneStatusTimeTrusted === maintenanceTime.phoneStatusTimeTrusted
    || CONTEXT_COPY.timeSources.external_evidence === CONTEXT_COPY.timeSources.hall_clock
    || CONTEXT_COPY.trustStates.trusted === CONTEXT_COPY.trustStates.untrusted
    || PHASE_COPY.opening_handoff.stageLabel === PHASE_COPY.maintenance_repair.stageLabel) {
    throw new Error("chapter4_stage_presentation_2245_states_not_distinct");
  }

  return Object.freeze({
    phaseCount: 13,
    timeStateCount: 6,
    opening2245Label: openingLabel,
    maintenance2245Label: maintenanceLabel
  });
}

export const CHAPTER_FOUR_STAGE_PRESENTATION_VALIDATION =
  validateChapterFourStagePresentationContract();

export function selectChapterFourStagePresentation(
  state: GameState
): ChapterFourStagePresentation | null {
  const chapter = state.chapter4;
  const phase = chapter.phase;
  const timeState = chapter.timeState;
  if (!PHASE_ID_SET.has(phase as ChapterFourPhase)
    || !Object.prototype.hasOwnProperty.call(TIME_STATE_COPY, timeState)) {
    return null;
  }

  const activePhase = phase as ChapterFourPhase;
  const activeTimeState = timeState as ChapterFourTimeState;
  const facts = new Set<ChapterFourFactId>(chapter.factIds);
  const confirmedFacts = chapter.factIds
    .map((factId) => FACT_LABELS[factId])
    .filter((label): label is string => Boolean(label));

  return Object.freeze({
    stageLabel: PHASE_COPY[activePhase].stageLabel,
    timeStateLabel: TIME_STATE_COPY[activeTimeState].timeStateLabel,
    phoneTime: formatClockTime(chapter.phoneStatusTimeSeconds),
    timeSource: CONTEXT_COPY.timeSources[chapter.timeAuthority],
    trustState: chapter.phoneStatusTimeTrusted
      ? CONTEXT_COPY.trustStates.trusted
      : CONTEXT_COPY.trustStates.untrusted,
    floor: chapter.floor,
    currentDifference: PHASE_COPY[activePhase].currentDifference,
    localProgress: selectLocalProgress(state, activePhase, facts),
    confirmedFacts: Object.freeze(confirmedFacts)
  });
}

function selectLocalProgress(
  state: GameState,
  phase: ChapterFourPhase,
  facts: ReadonlySet<ChapterFourFactId>
): string {
  switch (phase) {
    case "opening_handoff":
      return `纸条抓取 ${facts.has("opening_paper_caught") ? 1 : 0}/1`;
    case "opening_paper_caught":
      return `时间核对 ${facts.has("external_time_rejected") ? 1 : 0}/1`;
    case "hall_clock_inspection":
      return `旧钟检查 ${facts.has("hall_clock_inspected") ? 1 : 0}/1`;
    case "bakery_hour_hand":
      return `旧时针流程 ${countFacts(facts, [
        "bakery_conveyor_lamp_inspected",
        "bakery_hour_hand_exposed",
        "bakery_hour_hand_collected",
        "hour_hand_installed"
      ])}/4`;
    case "room204_restore":
      return `复原 204：${normalizeRoom204Placements(state.chapter4.room204Placements).length}/12`;
    case "maintenance_repair":
      return `维修流程 ${countMaintenanceMilestones(state, facts)}/6`;
    case "blackout_light_grid": {
      const progress = countRequiredLightConditions(state.chapter4.lightGrid.mask);
      return `必要灯区 ${progress.satisfied}/${progress.total}`;
    }
    case "final_chase":
      return "抵达 202 0/1";
    case "final_minute_recovery":
      return `最后一分钟 ${facts.has("final_minute_recovered") ? 1 : 0}/1`;
    case "return_to_clock":
      return state.chapter4.floor === "A1" ? "返回旧钟 1/1" : "返回旧钟 0/1";
    case "morning_checkin":
      return `签到确认 ${countFacts(facts, ["checkin_card_accepted", "checkin_paper_accepted"])}/2`;
    case "exterior_closure":
      return `收束确认 ${facts.has("exterior_closure_acknowledged") ? 1 : 0}/1`;
    case "complete":
      return "章节完成 1/1";
  }
}

function countMaintenanceMilestones(
  state: GameState,
  facts: ReadonlySet<ChapterFourFactId>
): number {
  const coverOpened = facts.has("cart_wheel_cover_opened");
  const wheelRepaired = facts.has("cart_wheel_repaired");
  const gearRepaired = facts.has("clock_gear_repaired");
  return [
    facts.has("cart_wheel_inspected"),
    state.items.shortPryBar || coverOpened || wheelRepaired || gearRepaired,
    coverOpened,
    state.items.universalLubricatingOil || wheelRepaired || gearRepaired,
    wheelRepaired,
    gearRepaired
  ].filter(Boolean).length;
}

function countRequiredLightConditions(maskValue: number): { satisfied: number; total: number } {
  const mask = Number.isInteger(maskValue)
    ? maskValue & CHAPTER_FOUR_LIGHT_GRID.allOnMask
    : 0;
  const isOn = (zoneId: (typeof CHAPTER_FOUR_LIGHT_GRID.requiredOnZoneIds)[number]): boolean => {
    const zone = CHAPTER_FOUR_LIGHT_GRID.zones.find((candidate) => candidate.id === zoneId);
    return zone ? (mask & (1 << zone.bit)) !== 0 : false;
  };
  const satisfiedOn = CHAPTER_FOUR_LIGHT_GRID.requiredOnZoneIds.filter(isOn).length;
  const satisfiedOff = CHAPTER_FOUR_LIGHT_GRID.requiredOffZoneIds.filter((zoneId) => !isOn(zoneId)).length;
  return {
    satisfied: satisfiedOn + satisfiedOff,
    total: CHAPTER_FOUR_LIGHT_GRID.requiredOnZoneIds.length
      + CHAPTER_FOUR_LIGHT_GRID.requiredOffZoneIds.length
  };
}

function countFacts(
  facts: ReadonlySet<ChapterFourFactId>,
  required: readonly ChapterFourFactId[]
): number {
  return required.filter((factId) => facts.has(factId)).length;
}

function formatClockTime(secondsValue: number): string {
  const wholeSeconds = Number.isFinite(secondsValue) ? Math.floor(secondsValue) : 0;
  const normalized = ((wholeSeconds % 86400) + 86400) % 86400;
  const hours = Math.floor(normalized / 3600);
  const minutes = Math.floor((normalized % 3600) / 60);
  const seconds = normalized % 60;
  const base = `${String(hours).padStart(2, "0")}:${String(minutes).padStart(2, "0")}`;
  return seconds === 0 ? base : `${base}:${String(seconds).padStart(2, "0")}`;
}

function requirePhaseContract(phase: ChapterFourPhase): PhaseContract {
  const contract = PHASE_CONTRACTS.find((candidate) => candidate.id === phase);
  if (!contract) throw new Error(`chapter4_stage_presentation_missing_phase_contract:${phase}`);
  return contract;
}

function requireTimeContract(timeState: ChapterFourTimeState): TimeContract {
  const contract = TIME_CONTRACTS.find((candidate) => candidate.id === timeState);
  if (!contract) throw new Error(`chapter4_stage_presentation_missing_time_contract:${timeState}`);
  return contract;
}

function assertExactUniqueIds(
  expected: readonly string[],
  actual: readonly string[],
  count: number,
  label: string
): void {
  if (expected.length !== count
    || actual.length !== count
    || new Set(expected).size !== count
    || new Set(actual).size !== count
    || expected.some((id) => !actual.includes(id))) {
    throw new Error(`chapter4_stage_presentation_${label}_coverage`);
  }
}

function assertUniqueText(values: readonly string[], label: string): void {
  if (values.some((value) => value.trim().length === 0)
    || new Set(values).size !== values.length) {
    throw new Error(`chapter4_stage_presentation_${label}_not_unique`);
  }
}
