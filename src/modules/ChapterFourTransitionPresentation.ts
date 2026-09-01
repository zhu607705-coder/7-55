import type {
  ChapterFourPhase,
  ChapterFourTimeState
} from "../core/types";
import chapterFour755Content from "../data/chapter4-755.content.json";
import type {
  ChapterFour755Intent,
  ChapterFour755IntentResult
} from "./ChapterFourTemporalMazeController";

export type ChapterFourTransitionPresentationOwner =
  | "scene_interaction"
  | "transition_overlay"
  | "external_overlay"
  | "controller_feedback";

export type ChapterFourTransitionPresentationKind = "time_shift" | "world_handoff";

export interface ChapterFourTransitionChange {
  kind: "time";
  eyebrow: string;
  title: string;
  detail: string;
  fromTimeState: ChapterFourTimeState;
  toTimeState: ChapterFourTimeState;
}

export interface ChapterFourTransitionPresentationPlan {
  id: string;
  presentationKind: "time_shift";
  owner: "transition_overlay";
  intentTypes: readonly ChapterFour755Intent["type"][];
  fromPhase: ChapterFourPhase;
  toPhase: ChapterFourPhase;
  change: Readonly<ChapterFourTransitionChange>;
}

interface RawTransitionContract {
  id: string;
  presentationKind: ChapterFourTransitionPresentationKind;
  owner: "transition_overlay" | "scene_interaction";
  intentTypes: ChapterFour755Intent["type"][];
  fromPhase: ChapterFourPhase;
  toPhase: ChapterFourPhase;
  change?: ChapterFourTransitionChange;
}

interface PhaseContract {
  id: ChapterFourPhase;
  timeState: ChapterFourTimeState;
}

const EXPECTED_TRANSITIONS = Object.freeze([
  {
    id: "hour_hand_to_room204",
    presentationKind: "time_shift",
    owner: "transition_overlay",
    intentTypes: ["install_hour_hand"],
    fromPhase: "bakery_hour_hand",
    toPhase: "room204_restore"
  },
  {
    id: "room204_to_maintenance",
    presentationKind: "time_shift",
    owner: "transition_overlay",
    intentTypes: ["install_positioning_plate"],
    fromPhase: "room204_restore",
    toPhase: "maintenance_repair"
  },
  {
    id: "maintenance_to_blackout",
    presentationKind: "time_shift",
    owner: "transition_overlay",
    intentTypes: ["complete_minute_theft"],
    fromPhase: "maintenance_repair",
    toPhase: "blackout_light_grid"
  },
  {
    id: "blackout_to_chase",
    presentationKind: "world_handoff",
    owner: "scene_interaction",
    intentTypes: ["lock_light_grid"],
    fromPhase: "blackout_light_grid",
    toPhase: "final_chase"
  },
  {
    id: "chase_to_room202",
    presentationKind: "world_handoff",
    owner: "scene_interaction",
    intentTypes: ["reach_202_threshold"],
    fromPhase: "final_chase",
    toPhase: "final_minute_recovery"
  },
  {
    id: "room202_to_clock_return",
    presentationKind: "world_handoff",
    owner: "scene_interaction",
    intentTypes: ["collect_final_minute"],
    fromPhase: "final_minute_recovery",
    toPhase: "return_to_clock"
  },
  {
    id: "clock_return_to_morning",
    presentationKind: "time_shift",
    owner: "transition_overlay",
    intentTypes: ["install_final_minute"],
    fromPhase: "return_to_clock",
    toPhase: "morning_checkin"
  },
  {
    id: "checkin_to_exterior",
    presentationKind: "world_handoff",
    owner: "scene_interaction",
    intentTypes: ["read_campus_card", "submit_attendance_paper"],
    fromPhase: "morning_checkin",
    toPhase: "exterior_closure"
  }
] as const satisfies readonly {
  id: string;
  presentationKind: ChapterFourTransitionPresentationKind;
  owner: "transition_overlay" | "scene_interaction";
  intentTypes: readonly ChapterFour755Intent["type"][];
  fromPhase: ChapterFourPhase;
  toPhase: ChapterFourPhase;
}[]);

const RAW_TRANSITIONS = chapterFour755Content.transitionContracts as RawTransitionContract[];
const PHASE_CONTRACTS = chapterFour755Content.phaseContracts as PhaseContract[];
const PHASE_IDS = new Set<ChapterFourPhase>(
  chapterFour755Content.orderedPhases as ChapterFourPhase[]
);
const TIME_STATE_IDS = new Set<ChapterFourTimeState>(
  chapterFour755Content.time.stateOrder as ChapterFourTimeState[]
);

function nonEmpty(value: unknown): value is string {
  return typeof value === "string" && value.trim().length > 0;
}

function sameStrings(actual: readonly string[], expected: readonly string[]): boolean {
  return actual.length === expected.length
    && actual.every((value, index) => value === expected[index]);
}

function requirePhaseTimeState(phase: ChapterFourPhase): ChapterFourTimeState {
  const contract = PHASE_CONTRACTS.find((candidate) => candidate.id === phase);
  if (!contract) {
    throw new Error(`chapter4_transition_missing_phase_contract:${phase}`);
  }
  return contract.timeState;
}

export function validateChapterFourTransitionPresentationContracts(): {
  transitionCount: 8;
  overlayCount: 4;
  worldHandoffCount: 4;
  intentMatchCount: 9;
} {
  if (RAW_TRANSITIONS.length !== EXPECTED_TRANSITIONS.length) {
    throw new Error("chapter4_transition_contract_count");
  }
  const ids = RAW_TRANSITIONS.map((contract) => contract.id);
  if (new Set(ids).size !== ids.length) {
    throw new Error("chapter4_transition_duplicate_id");
  }

  const matchKeys = new Set<string>();
  let overlayCount = 0;
  let worldHandoffCount = 0;
  RAW_TRANSITIONS.forEach((contract, index) => {
    const expected = EXPECTED_TRANSITIONS[index];
    if (!expected
      || contract.id !== expected.id
      || contract.presentationKind !== expected.presentationKind
      || contract.owner !== expected.owner
      || contract.fromPhase !== expected.fromPhase
      || contract.toPhase !== expected.toPhase
      || !sameStrings(contract.intentTypes, expected.intentTypes)) {
      throw new Error(`chapter4_transition_order_or_match:${contract.id || index}`);
    }
    if (!PHASE_IDS.has(contract.fromPhase) || !PHASE_IDS.has(contract.toPhase)) {
      throw new Error(`chapter4_transition_phase:${contract.id}`);
    }
    if (!Array.isArray(contract.intentTypes) || contract.intentTypes.length === 0) {
      throw new Error(`chapter4_transition_intents:${contract.id}`);
    }
    contract.intentTypes.forEach((intentType) => {
      const key = `${intentType}:${contract.fromPhase}:${contract.toPhase}`;
      if (matchKeys.has(key)) {
        throw new Error(`chapter4_transition_duplicate_match:${key}`);
      }
      matchKeys.add(key);
    });

    if (contract.presentationKind === "time_shift") {
      overlayCount += 1;
      if (contract.owner !== "transition_overlay") {
        throw new Error(`chapter4_transition_time_owner:${contract.id}`);
      }
      const change = contract.change;
      if (!change
        || change.kind !== "time"
        || !nonEmpty(change.eyebrow)
        || !nonEmpty(change.title)
        || !nonEmpty(change.detail)
        || !TIME_STATE_IDS.has(change.fromTimeState)
        || !TIME_STATE_IDS.has(change.toTimeState)
        || change.fromTimeState === change.toTimeState
        || change.fromTimeState !== requirePhaseTimeState(contract.fromPhase)
        || change.toTimeState !== requirePhaseTimeState(contract.toPhase)) {
        throw new Error(`chapter4_transition_time_change:${contract.id}`);
      }
      return;
    }

    worldHandoffCount += 1;
    if (contract.owner !== "scene_interaction" || contract.change !== undefined) {
      throw new Error(`chapter4_transition_world_handoff:${contract.id}`);
    }
  });

  if (matchKeys.size !== 9) {
    throw new Error("chapter4_transition_match_count");
  }
  if (overlayCount !== 4 || worldHandoffCount !== 4) {
    throw new Error("chapter4_transition_ownership_count");
  }
  return Object.freeze({
    transitionCount: 8,
    overlayCount: 4,
    worldHandoffCount: 4,
    intentMatchCount: 9
  });
}

export const CHAPTER_FOUR_TRANSITION_PRESENTATION_VALIDATION =
  validateChapterFourTransitionPresentationContracts();

const TRANSITION_PLANS = Object.freeze(RAW_TRANSITIONS
  .filter((contract): contract is RawTransitionContract & {
    presentationKind: "time_shift";
    owner: "transition_overlay";
    change: ChapterFourTransitionChange;
  } => contract.presentationKind === "time_shift"
    && contract.owner === "transition_overlay"
    && contract.change !== undefined)
  .map((contract) => Object.freeze({
    id: contract.id,
    presentationKind: contract.presentationKind,
    owner: contract.owner,
    intentTypes: Object.freeze([...contract.intentTypes]),
    fromPhase: contract.fromPhase,
    toPhase: contract.toPhase,
    change: Object.freeze({ ...contract.change })
  } satisfies ChapterFourTransitionPresentationPlan)));

function matchTransition(
  result: Pick<
    ChapterFour755IntentResult,
    "accepted" | "changed" | "intentType" | "previousPhase" | "phase"
  >
): RawTransitionContract | null {
  if (!result.accepted
    || !result.changed
    || result.previousPhase === null
    || result.phase === null
    || result.previousPhase === result.phase) {
    return null;
  }
  return RAW_TRANSITIONS.find((contract) =>
    contract.fromPhase === result.previousPhase
      && contract.toPhase === result.phase
      && contract.intentTypes.includes(result.intentType)
  ) ?? null;
}

export function selectChapterFourTransitionPresentationOwner(
  result: Pick<
    ChapterFour755IntentResult,
    "accepted" | "changed" | "intentType" | "previousPhase" | "phase"
  >
): "transition_overlay" | "scene_interaction" | null {
  return matchTransition(result)?.owner ?? null;
}

export function selectChapterFourTransitionPresentation(
  result: Pick<
    ChapterFour755IntentResult,
    "accepted" | "changed" | "intentType" | "previousPhase" | "phase"
  >
): ChapterFourTransitionPresentationPlan | null {
  const contract = matchTransition(result);
  if (!contract || contract.presentationKind !== "time_shift") return null;
  return TRANSITION_PLANS.find((plan) => plan.id === contract.id) ?? null;
}

export function getChapterFourTransitionPresentationById(
  transitionId: string
): ChapterFourTransitionPresentationPlan | null {
  return TRANSITION_PLANS.find((plan) => plan.id === transitionId) ?? null;
}
