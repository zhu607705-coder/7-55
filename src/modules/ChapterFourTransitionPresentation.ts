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

interface ExpectedTransitionContract {
  id: string;
  presentationKind: ChapterFourTransitionPresentationKind;
  owner: "transition_overlay" | "scene_interaction";
  intentTypes: readonly ChapterFour755Intent["type"][];
  fromPhase: ChapterFourPhase;
  toPhase: ChapterFourPhase;
  fromTimeState?: ChapterFourTimeState;
  toTimeState?: ChapterFourTimeState;
}

const EXPECTED_TRANSITIONS: readonly ExpectedTransitionContract[] = Object.freeze([
  {
    id: "opening_to_bakery",
    presentationKind: "time_shift",
    owner: "transition_overlay",
    intentTypes: ["adjust_hall_clock_time"],
    fromPhase: "hall_clock_inspection",
    toPhase: "bakery_hour_hand",
    fromTimeState: "2245_opening",
    toTimeState: "1225_bakery"
  },
  {
    id: "clock_tune_to_evening",
    presentationKind: "time_shift",
    owner: "transition_overlay",
    intentTypes: ["adjust_hall_clock_time"],
    fromPhase: "room204_restore",
    toPhase: "room204_restore",
    fromTimeState: "1225_bakery",
    toTimeState: "1850_evening"
  },
  {
    id: "clock_tune_to_maintenance",
    presentationKind: "time_shift",
    owner: "transition_overlay",
    intentTypes: ["adjust_hall_clock_time"],
    fromPhase: "maintenance_repair",
    toPhase: "maintenance_repair",
    fromTimeState: "1850_evening",
    toTimeState: "2245_maintenance"
  },
  {
    id: "maintenance_to_blackout",
    presentationKind: "time_shift",
    owner: "transition_overlay",
    intentTypes: ["complete_minute_theft"],
    fromPhase: "maintenance_repair",
    toPhase: "blackout_light_grid",
    fromTimeState: "2245_maintenance",
    toTimeState: "0754_blackout"
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
    toPhase: "morning_checkin",
    fromTimeState: "0754_blackout",
    toTimeState: "0755_morning"
  },
  {
    id: "checkin_to_exterior",
    presentationKind: "world_handoff",
    owner: "scene_interaction",
    intentTypes: ["read_campus_card", "submit_attendance_paper"],
    fromPhase: "morning_checkin",
    toPhase: "exterior_closure"
  }
]);

const RAW_TRANSITIONS = chapterFour755Content.transitionContracts as RawTransitionContract[];
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

export function validateChapterFourTransitionPresentationContracts(): {
  transitionCount: 9;
  overlayCount: 5;
  worldHandoffCount: 4;
  intentMatchCount: 10;
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
        || change.fromTimeState !== expected.fromTimeState
        || change.toTimeState !== expected.toTimeState) {
        throw new Error(`chapter4_transition_time_change:${contract.id}`);
      }
      return;
    }

    worldHandoffCount += 1;
    if (contract.owner !== "scene_interaction" || contract.change !== undefined) {
      throw new Error(`chapter4_transition_world_handoff:${contract.id}`);
    }
  });

  if (matchKeys.size !== 10) {
    throw new Error("chapter4_transition_match_count");
  }
  if (overlayCount !== 5 || worldHandoffCount !== 4) {
    throw new Error("chapter4_transition_ownership_count");
  }
  return Object.freeze({
    transitionCount: 9,
    overlayCount: 5,
    worldHandoffCount: 4,
    intentMatchCount: 10
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
      | "previousTimeState" | "timeState"
  >
): RawTransitionContract | null {
  if (!result.accepted
    || !result.changed
    || result.previousPhase === null
    || result.phase === null
    || result.previousTimeState === null
    || result.timeState === null) {
    return null;
  }
  return RAW_TRANSITIONS.find((contract) =>
    contract.fromPhase === result.previousPhase
      && contract.toPhase === result.phase
      && contract.intentTypes.includes(result.intentType)
      && (contract.presentationKind !== "time_shift"
        || (contract.change?.fromTimeState === result.previousTimeState
          && contract.change.toTimeState === result.timeState))
  ) ?? null;
}

export function selectChapterFourTransitionPresentationOwner(
  result: Pick<
    ChapterFour755IntentResult,
    "accepted" | "changed" | "intentType" | "previousPhase" | "phase"
      | "previousTimeState" | "timeState"
  >
): "transition_overlay" | "scene_interaction" | null {
  return matchTransition(result)?.owner ?? null;
}

export function selectChapterFourTransitionPresentation(
  result: Pick<
    ChapterFour755IntentResult,
    "accepted" | "changed" | "intentType" | "previousPhase" | "phase"
      | "previousTimeState" | "timeState"
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
