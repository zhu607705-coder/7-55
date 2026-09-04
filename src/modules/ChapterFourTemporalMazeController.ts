import type { EventBus } from "../core/EventBus";
import type {
  ChapterFour755FloorId,
  ChapterFourFactId,
  ChapterFourGuardMode,
  ChapterFourLightZoneId,
  ChapterFourPhase,
  ChapterFourRealityMode,
  ChapterFourRoom204GroupId,
  ChapterFourRoom204Orientation,
  ChapterFourRoom204PieceId,
  ChapterFourRoom204SlotId,
  ChapterFourState,
  ChapterFourTimeAuthority,
  ChapterFourTimeState,
  ChapterFourZhuPersonAnswerId,
  ChapterFourZhuPurposeAnswerId,
  GameState,
  GameStore,
  InventoryItemId,
  RpgCheckpointId
} from "../core/types";
import content from "../data/chapter4-755.content.json";
import {
  isChapterFourContextInteractionTargetId,
  type ChapterFourContextInteractionTargetId
} from "../data/ChapterFourInteractionContent";
import {
  ROOM204_GROUP_ORDER,
  countCompletedRoom204Groups,
  isRoom204GroupComplete,
  isRoom204PlacementSetComplete,
  resolveRoom204GroupPlacement,
  resolveRoom204Placement,
  room204GroupTargetId,
  room204SlotTargetId
} from "../scenes/rpg/ChapterFourRoom204Model";
import {
  CHAPTER_FOUR_LIGHT_GRID,
  isChapterFourLightGridSolved,
  toggleChapterFourLightZone
} from "./ChapterFourLightGridModel";
import {
  BLOCKED_CHAPTER_FOUR_CLOSURE_SESSION_VERIFIER,
  closureProofMatchesReference,
  isChapterFourClosureSessionProof,
  type ChapterFourClosureSessionProof,
  type ChapterFourClosureSessionVerifier
} from "./ChapterFourClosureContract";
import {
  isChapterFourElevatorStartSelectable,
  isChapterFourElevatorTrackAligned
} from "./ChapterFourElevatorModel";
import {
  CHAPTER_FOUR_ELEVATOR_FLOOR_RECORDS,
  chapterFourElevatorRecordsComplete,
  isChapterFourElevatorDeductionFloor,
  isChapterFourElevatorRecordFloor,
  isChapterFourElevatorStopChainCorrect,
  type ChapterFourElevatorDeductionFloor,
  type ChapterFourElevatorRecordFloor
} from "./ChapterFourElevatorFloorInvestigation";
import {
  CHAPTER_FOUR_INSERTED_PUZZLES,
  chapterFourInsertedPuzzleForTarget,
  isChapterFourInsertedPuzzleAnswer,
  isChapterFourInsertedPuzzleAnswerCorrect,
  type ChapterFourInsertedPuzzleAnswer,
  type ChapterFourInsertedPuzzleId
} from "./ChapterFourInsertedPuzzleModel";
import {
  chapterFourTimeContract,
  isChapterFourPhaseTimeAligned,
  selectChapterFourRequiredClockTime
} from "./ChapterFourTimeControlModel";
import {
  getChapterFour755TargetContract,
  resolveChapterFour755RuntimeEntityTarget,
  validateChapterFour755TargetIntentContract,
  type ChapterFour755RuntimeTargetContext,
  type RpgHalfOpenWorldRect
} from "../scenes/rpg/RpgInteractionContract";

/**
 * Compatibility result used by the retired Chapter 4 phone and Three.js
 * consumers. Task 6 removes those consumers. The deprecated methods below do
 * not mutate state.
 */
export type ChapterFourActionResult =
  | "accepted"
  | "already_complete"
  | "incorrect"
  | "misaligned"
  | "wrong_mode"
  | "locked"
  | "inactive";

/** @deprecated Task 6 removes the old free-form maze movement requests. */
export type ChapterFourMazeRoute = "walk" | "elevator" | "stair";

/** @deprecated Task 6 removes the old free-form maze movement requests. */
export interface ChapterFourMazeMoveIntent {
  floor: GameState["chapter4"]["floor"];
  roomId: string;
  checkpoint: RpgCheckpointId;
  route: ChapterFourMazeRoute;
}

/** @deprecated Task 6 removes the old A2 partition puzzle. */
export type ChapterFourCorridorPartitionId = "a2_partition_west" | "a2_partition_east";
/** @deprecated Task 6 removes the old wayfinding-fragment puzzle. */
export type ChapterFourWayfindingFragmentId = "a2_fragment_west" | "a2_fragment_east";

export type ChapterFourMaintenanceSymptomId = "wheel_sound" | "clock_jam" | "oil_trace";
export type ChapterFourMaintenanceCauseId = "latch" | "oil_shortage" | "gear_offset" | "power_loss" | "foreign_object";
export type ChapterFourMaintenanceDiagnosisAnswers = Record<
  ChapterFourMaintenanceSymptomId,
  ChapterFourMaintenanceCauseId
>;

export const CHAPTER_FOUR_755_TARGET_IDS = Object.freeze({
  attendancePaper: "a1_noticeboard_paper",
  hallClock: "a1_hall_clock",
  bakeryInspectionLamp: "a1_bakery_inspection_lamp",
  bakeryConveyorEdge: "a1_bakery_conveyor_edge",
  bakeryHourHandPickup: "a1_bakery_hour_hand_pickup",
  hourHandSocket: "a1_hall_clock_hour_hand_socket",
  frontDeskAttendant: "a1_front_desk_attendant",
  a2ElevatorAttendant: "a2_elevator_attendant",
  a3ReferenceTeacher: "a3_reference_teacher",
  alumniSuBuqing: "a3_alumni_su_buqing",
  alumniZhuKezhen: "a3_alumni_zhu_kezhen",
  alumniLuYongxiang: "a3_alumni_lu_yongxiang",
  alumniChenJiangong: "a3_alumni_chen_jiangong",
  alumniTanJiazhen: "a3_alumni_tan_jiazhen",
  alumniChengKaijia: "a3_alumni_cheng_kaijia",
  classroom104BlackboardResidual: "a1_classroom_104_blackboard_residual",
  classroom105LecternTerminal: "a1_classroom_105_lectern_terminal",
  a3Reference: "a3_reference_classroom_layout",
  room204Residual: "a2_room204_residual_group",
  positioningPlatePickup: "a2_room204_podium_drawer",
  positioningPlateSocket: "a1_hall_clock_positioning_plate_slot",
  cartWheelInspection: "a1_cleaning_cart_wheel_inspection",
  pryBarPickup: "a1_bakery_back_pry_bar",
  cartWheelCover: "a1_cleaning_cart_wheel_cover",
  oilPickup: "a1_cleaning_cart_oil_bottle",
  cartWheel: "a1_cleaning_cart_wheel",
  clockGear: "a1_hall_clock_gear",
  minuteEndpoint: "a1_hall_clock_minute_endpoint",
  powerPanel: "a1_power_panel",
  lecture202Threshold: "a2_202_threshold",
  finalMinuteProjection: "a2_202_projection",
  campusCardReader: "a1_campus_card_reader",
  attendancePaperSlot: "a1_attendance_paper_slot"
});

export interface ChapterFour755SpatialResult {
  distance: "within_range" | "too_far";
}

export const CHAPTER_FOUR_755_ACCEPTED_SPATIAL_RESULT = Object.freeze({
  distance: "within_range"
} as const satisfies ChapterFour755SpatialResult);

type ChapterFour755TargetIntent<T extends { targetId: string }> = T & {
  spatial: ChapterFour755SpatialResult;
};

export type ChapterFour755Intent =
  | { type: "complete_prologue_handoff" }
  | { type: "complete_opening_paper_flight" }
  | { type: "resolve_external_time_rejection" }
  | { type: "resolve_hall_clock_inspection" }
  | { type: "set_mode"; mode: ChapterFourRealityMode }
  | {
      type: "move_to_location" | "record_checkpoint";
      floor: ChapterFour755FloorId;
      roomId: string;
      checkpoint: RpgCheckpointId;
    }
  | {
      type: "traverse_main_stair";
      fromFloor: "A1" | "A2";
      toFloor: "A1" | "A2";
      expectedAttempt: number;
    }
  | { type: "observe_elevator_history" }
  | { type: "calibrate_elevator_history"; startSeconds: number }
  | { type: "observe_elevator_floor_record"; floor: ChapterFourElevatorRecordFloor }
  | {
      type: "reconstruct_elevator_stop_chain";
      actualArrivalFloor: ChapterFourElevatorDeductionFloor;
      unservedCallFloor: ChapterFourElevatorDeductionFloor;
    }
  | { type: "complete_misaligned_stair" }
  | { type: "complete_inserted_puzzle"; answer: ChapterFourInsertedPuzzleAnswer }
  | ChapterFour755TargetIntent<{ type: "catch_attendance_paper"; targetId: typeof CHAPTER_FOUR_755_TARGET_IDS.attendancePaper }>
  | ChapterFour755TargetIntent<{ type: "inspect_hall_clock"; targetId: typeof CHAPTER_FOUR_755_TARGET_IDS.hallClock }>
  | ChapterFour755TargetIntent<{ type: "pull_hall_clock"; targetId: typeof CHAPTER_FOUR_755_TARGET_IDS.hallClock }>
  | ChapterFour755TargetIntent<{
      type: "adjust_hall_clock_time";
      targetId: typeof CHAPTER_FOUR_755_TARGET_IDS.hallClock;
      targetTimeState: ChapterFourTimeState;
    }>
  | ChapterFour755TargetIntent<{
      type: "inspect_bakery_conveyor_lamp";
      targetId: typeof CHAPTER_FOUR_755_TARGET_IDS.bakeryInspectionLamp;
    }>
  | ChapterFour755TargetIntent<{
      type: "inspect_bakery_conveyor_edge";
      targetId: typeof CHAPTER_FOUR_755_TARGET_IDS.bakeryConveyorEdge;
    }>
  | { type: "complete_bakery_conveyor_stop" }
  | ChapterFour755TargetIntent<{
      type: "collect_hour_hand";
      targetId: typeof CHAPTER_FOUR_755_TARGET_IDS.bakeryHourHandPickup;
    }>
  | ChapterFour755TargetIntent<{
      type: "install_hour_hand";
      itemId: InventoryItemId;
      targetId: typeof CHAPTER_FOUR_755_TARGET_IDS.hourHandSocket;
    }>
  | ChapterFour755TargetIntent<{
      type: "talk_to_a1_front_desk_attendant";
      targetId: typeof CHAPTER_FOUR_755_TARGET_IDS.frontDeskAttendant;
    }>
  | ChapterFour755TargetIntent<{
      type: "talk_to_chapter_four_support_npc";
      targetId:
        | typeof CHAPTER_FOUR_755_TARGET_IDS.a2ElevatorAttendant
        | typeof CHAPTER_FOUR_755_TARGET_IDS.a3ReferenceTeacher;
    }>
  | ChapterFour755TargetIntent<{
      type: "inspect_chapter_four_context";
      targetId: ChapterFourContextInteractionTargetId;
    }>
  | ChapterFour755TargetIntent<{
      type: "inspect_alumni_figure";
      targetId:
        | typeof CHAPTER_FOUR_755_TARGET_IDS.alumniSuBuqing
        | typeof CHAPTER_FOUR_755_TARGET_IDS.alumniZhuKezhen
        | typeof CHAPTER_FOUR_755_TARGET_IDS.alumniLuYongxiang
        | typeof CHAPTER_FOUR_755_TARGET_IDS.alumniChenJiangong
        | typeof CHAPTER_FOUR_755_TARGET_IDS.alumniTanJiazhen
        | typeof CHAPTER_FOUR_755_TARGET_IDS.alumniChengKaijia;
    }>
  | {
      type: "complete_zhu_two_questions";
      purposeAnswer: ChapterFourZhuPurposeAnswerId;
      personAnswer: ChapterFourZhuPersonAnswerId;
    }
  | ChapterFour755TargetIntent<{
      type: "observe_classroom_104_chalk_residual";
      targetId: typeof CHAPTER_FOUR_755_TARGET_IDS.classroom104BlackboardResidual;
    }>
  | ChapterFour755TargetIntent<{
      type: "check_classroom_105_terminal_replay";
      targetId: typeof CHAPTER_FOUR_755_TARGET_IDS.classroom105LecternTerminal;
    }>
  | ChapterFour755TargetIntent<{ type: "observe_a3_reference"; targetId: typeof CHAPTER_FOUR_755_TARGET_IDS.a3Reference }>
  | ChapterFour755TargetIntent<{ type: "observe_room204_residual"; targetId: typeof CHAPTER_FOUR_755_TARGET_IDS.room204Residual }>
  | ChapterFour755TargetIntent<{
      type: "place_room204_piece";
      pieceId: ChapterFourRoom204PieceId;
      slotId: ChapterFourRoom204SlotId;
      orientation: ChapterFourRoom204Orientation;
      targetId: string;
    }>
  | ChapterFour755TargetIntent<{
      type: "place_room204_group";
      groupId: ChapterFourRoom204GroupId;
      targetId: string;
    }>
  | { type: "complete_room204_projection" }
  | ChapterFour755TargetIntent<{
      type: "collect_positioning_plate";
      targetId: typeof CHAPTER_FOUR_755_TARGET_IDS.positioningPlatePickup;
    }>
  | ChapterFour755TargetIntent<{
      type: "install_positioning_plate";
      itemId: InventoryItemId;
      targetId: typeof CHAPTER_FOUR_755_TARGET_IDS.positioningPlateSocket;
    }>
  | ChapterFour755TargetIntent<{
      type: "inspect_cart_wheel";
      targetId: typeof CHAPTER_FOUR_755_TARGET_IDS.cartWheelInspection;
    }>
  | { type: "complete_maintenance_diagnosis"; answers: ChapterFourMaintenanceDiagnosisAnswers }
  | ChapterFour755TargetIntent<{ type: "collect_short_pry_bar"; targetId: typeof CHAPTER_FOUR_755_TARGET_IDS.pryBarPickup }>
  | ChapterFour755TargetIntent<{
      type: "open_cart_wheel_cover";
      itemId: InventoryItemId;
      targetId: typeof CHAPTER_FOUR_755_TARGET_IDS.cartWheelCover;
    }>
  | ChapterFour755TargetIntent<{ type: "collect_lubricating_oil"; targetId: typeof CHAPTER_FOUR_755_TARGET_IDS.oilPickup }>
  | ChapterFour755TargetIntent<{
      type: "lubricate_cart_wheel";
      itemId: InventoryItemId;
      targetId: typeof CHAPTER_FOUR_755_TARGET_IDS.cartWheel;
    }>
  | ChapterFour755TargetIntent<{
      type: "lubricate_clock_gear";
      itemId: InventoryItemId;
      targetId: typeof CHAPTER_FOUR_755_TARGET_IDS.clockGear;
    }>
  | { type: "recover_from_maintenance_patrol" }
  | ChapterFour755TargetIntent<{
      type: "begin_final_clock_drag";
      targetId: typeof CHAPTER_FOUR_755_TARGET_IDS.minuteEndpoint;
    }>
  | { type: "complete_minute_theft" }
  | ChapterFour755TargetIntent<{ type: "trigger_minute_theft"; targetId: typeof CHAPTER_FOUR_755_TARGET_IDS.minuteEndpoint }>
  | ChapterFour755TargetIntent<{ type: "open_power_panel"; targetId: typeof CHAPTER_FOUR_755_TARGET_IDS.powerPanel }>
  | ChapterFour755TargetIntent<{
      type: "toggle_light_zone";
      zoneId: ChapterFourLightZoneId;
      targetId: typeof CHAPTER_FOUR_755_TARGET_IDS.powerPanel;
    }>
  | ChapterFour755TargetIntent<{ type: "lock_light_grid"; targetId: typeof CHAPTER_FOUR_755_TARGET_IDS.powerPanel }>
  | ChapterFour755TargetIntent<{
      type: "reach_202_threshold";
      targetId: typeof CHAPTER_FOUR_755_TARGET_IDS.lecture202Threshold;
      expectedAttempt: number;
    }>
  | {
      type: "fail_chase";
      expectedAttempt: number;
      failureFloor: "A1" | "A2";
    }
  | ChapterFour755TargetIntent<{
      type: "collect_final_minute";
      targetId: typeof CHAPTER_FOUR_755_TARGET_IDS.finalMinuteProjection;
    }>
  | ChapterFour755TargetIntent<{
      type: "install_final_minute";
      itemId: InventoryItemId;
      targetId: typeof CHAPTER_FOUR_755_TARGET_IDS.minuteEndpoint;
    }>
  | ChapterFour755TargetIntent<{
      type: "read_campus_card";
      itemId: InventoryItemId;
      targetId: typeof CHAPTER_FOUR_755_TARGET_IDS.campusCardReader;
    }>
  | ChapterFour755TargetIntent<{
      type: "submit_attendance_paper";
      itemId: InventoryItemId;
      targetId: typeof CHAPTER_FOUR_755_TARGET_IDS.attendancePaperSlot;
    }>
  | {
      type: "acknowledge_exterior_closure";
      proof: ChapterFourClosureSessionProof;
    };

export interface ChapterFour755IntentRequest {
  requestId: string;
  intent: ChapterFour755Intent;
  runtimeTarget?: ChapterFour755RuntimeTargetContext;
}

export type ChapterFour755IntentRequestValidation =
  | { valid: true; request: ChapterFour755IntentRequest }
  | { valid: false; reason: "invalid_request" | "invalid_intent"; requestId: string };

export type ChapterFour755SessionRequestResolution<T> =
  | { status: "duplicate" }
  | { status: "failed"; error: unknown }
  | { status: "resolved"; result: T };

/** Adds an id only after the resolver returns a terminal result. */
export function resolveChapterFour755SessionRequest<T>(
  resolvedRequestIds: Set<string>,
  requestId: string,
  resolve: () => T
): ChapterFour755SessionRequestResolution<T> {
  if (resolvedRequestIds.has(requestId)) return { status: "duplicate" };
  try {
    const result = resolve();
    resolvedRequestIds.add(requestId);
    return { status: "resolved", result };
  } catch (error) {
    return { status: "failed", error };
  }
}

export type ChapterFour755IntentResultReason =
  | "accepted"
  | "already_complete"
  | "incorrect"
  | "wrong_mode"
  | "wrong_item"
  | "too_far"
  | "locked"
  | "inactive";

export const CHAPTER_FOUR_755_INTENT_DETAIL_CODES = Object.freeze([
  "prologue_requirements_unmet",
  "current_phase_mismatch",
  "clock_adjustment_required",
  "target_unavailable",
  "route_not_available",
  "stair_route_not_available",
  "bakery_lamp_required",
  "bakery_stop_pending",
  "hour_hand_required",
  "classroom_checks_required",
  "elevator_history_required",
  "elevator_calibration_required",
  "elevator_floor_records_required",
  "elevator_stop_chain_required",
  "duty_board_required",
  "archive_film_required",
  "media_alignment_required",
  "positioning_calibration_required",
  "power_topology_required",
  "evacuation_route_required",
  "zhu_two_questions_required",
  "misaligned_stair_required",
  "room204_observations_required",
  "room204_layout_incomplete",
  "room204_unknown_piece",
  "room204_unknown_slot",
  "room204_invalid_orientation",
  "room204_duplicate_piece",
  "room204_slot_occupied",
  "room204_piece_already_placed",
  "room204_unknown_group",
  "room204_wrong_group",
  "room204_group_conflict",
  "room204_group_already_placed",
  "room204_projection_required",
  "a1_comparison_required",
  "projection_composite_required",
  "maintenance_incident_required",
  "powered_route_required",
  "identity_context_required",
  "positioning_plate_required",
  "cart_wheel_inspection_required",
  "cart_wheel_cover_required",
  "cart_wheel_repair_required",
  "clock_gear_repair_required",
  "final_clock_drag_not_armed",
  "blackout_not_started",
  "chase_attempt_stale",
  "final_minute_not_recovered",
  "return_route_incomplete",
  "interlude_completion_required",
  "checkin_requirements_incomplete",
  "checkin_card_already_accepted",
  "checkin_paper_already_accepted",
  "closure_prerequisites_incomplete",
  "closure_session_unverified"
] as const);

export type ChapterFour755IntentDetailCode =
  (typeof CHAPTER_FOUR_755_INTENT_DETAIL_CODES)[number];

export interface ChapterFour755IntentResult {
  accepted: boolean;
  changed: boolean;
  reason: ChapterFour755IntentResultReason;
  detailCode?: ChapterFour755IntentDetailCode;
  intentType: ChapterFour755Intent["type"];
  previousPhase: ChapterFourPhase | null;
  phase: ChapterFourPhase | null;
  previousTimeState: ChapterFourTimeState | null;
  timeState: ChapterFourTimeState | null;
}

interface PhaseContract {
  id: ChapterFourPhase;
  timeAuthority: ChapterFourTimeAuthority;
  timeState: ChapterFourTimeState;
  guardMode: ChapterFourGuardMode;
}

interface TimeContract {
  id: ChapterFourTimeState;
  worldTimeSeconds: number;
  phoneStatusTimeSeconds: number;
  phoneStatusTimeTrusted: boolean;
}

type PhaseTransitionOverrides = Partial<Omit<
  ChapterFourState,
  | "phase"
  | "building"
  | "floor"
  | "roomId"
  | "timeAuthority"
  | "timeState"
  | "worldTimeSeconds"
  | "phoneStatusTimeSeconds"
  | "phoneStatusTimeTrusted"
  | "guardMode"
>> & {
  items?: GameState["items"];
  floor?: ChapterFour755FloorId;
  roomId?: string;
  checkpoint?: RpgCheckpointId;
};

type ChapterPatch = Partial<Omit<
  ChapterFourState,
  | "phase"
  | "building"
  | "floor"
  | "roomId"
  | "timeAuthority"
  | "timeState"
  | "worldTimeSeconds"
  | "phoneStatusTimeSeconds"
  | "phoneStatusTimeTrusted"
  | "guardMode"
>>;

const PHASE_CONTRACTS = content.phaseContracts as readonly PhaseContract[];
const TIME_CONTRACTS = content.time.states as readonly TimeContract[];
const LIGHT_GRID_ZONES = content.lightGrid.zones as readonly {
  id: ChapterFourLightZoneId;
  toggleMask: number;
}[];

const ACTIVE_PHASES = new Set<ChapterFourPhase>(
  content.orderedPhases as readonly ChapterFourPhase[]
);
const ROOM204_PIECES = new Set<ChapterFourRoom204PieceId>(
  content.room204.pieceIds as readonly ChapterFourRoom204PieceId[]
);
const ROOM204_SLOTS = new Set<ChapterFourRoom204SlotId>(
  content.room204.slotIds as readonly ChapterFourRoom204SlotId[]
);
const ROOM204_GROUPS = new Set<ChapterFourRoom204GroupId>(ROOM204_GROUP_ORDER);
const ROOM204_ORIENTATIONS = new Set<ChapterFourRoom204Orientation>(["up"]);
const LIGHT_ZONE_IDS = new Set<ChapterFourLightZoneId>(LIGHT_GRID_ZONES.map((zone) => zone.id));
const ZHU_PURPOSE_ANSWER_IDS = new Set<ChapterFourZhuPurposeAnswerId>([
  "seek_truth",
  "solve_real_problems",
  "serve_public"
]);
const ZHU_PERSON_ANSWER_IDS = new Set<ChapterFourZhuPersonAnswerId>([
  "responsible",
  "clear_minded",
  "public_service"
]);

type AllowedLocation = {
  floor: ChapterFour755FloorId;
  roomId: string;
  checkpoint: RpgCheckpointId;
};

const ALLOWED_LOCATIONS_BY_PHASE: Readonly<Record<ChapterFourPhase, readonly AllowedLocation[]>> = {
  opening_handoff: [
    { floor: "A1", roomId: "a1_lobby", checkpoint: "c4_a1_lobby" }
  ],
  opening_paper_caught: [
    { floor: "A1", roomId: "a1_lobby", checkpoint: "c4_a1_lobby" },
    { floor: "A1", roomId: "a1_hall_clock", checkpoint: "c4_a1_lobby" }
  ],
  hall_clock_inspection: [
    { floor: "A1", roomId: "a1_lobby", checkpoint: "c4_a1_lobby" },
    { floor: "A1", roomId: "a1_hall_clock", checkpoint: "c4_a1_lobby" }
  ],
  bakery_hour_hand: [
    { floor: "A1", roomId: "a1_bakery", checkpoint: "c4_a1_lobby" },
    { floor: "A1", roomId: "a1_hall_clock", checkpoint: "c4_a1_lobby" },
    { floor: "A1", roomId: "a1_lobby", checkpoint: "c4_a1_lobby" }
  ],
  room204_restore: [
    { floor: "A1", roomId: "a1_hall_clock", checkpoint: "c4_a1_lobby" },
    { floor: "A2", roomId: "a2_corridor", checkpoint: "c4_a2_corridor" },
    { floor: "A2", roomId: "a2_room204", checkpoint: "c4_a2_corridor" },
    { floor: "A2", roomId: "a2_room_204", checkpoint: "c4_a2_corridor" },
    { floor: "A3", roomId: "a3_wayfinding", checkpoint: "c4_a3_wayfinding" },
    { floor: "A3", roomId: "a3_reference_classroom", checkpoint: "c4_a3_wayfinding" }
  ],
  maintenance_repair: [
    { floor: "A1", roomId: "a1_lobby", checkpoint: "c4_a1_lobby" },
    { floor: "A1", roomId: "a1_hall_clock", checkpoint: "c4_a1_lobby" },
    { floor: "A1", roomId: "a1_bakery", checkpoint: "c4_a1_lobby" },
    { floor: "A1", roomId: "a1_cleaning_cart", checkpoint: "c4_a1_lobby" }
  ],
  blackout_light_grid: [
    { floor: "A1", roomId: "a1_lobby", checkpoint: "c4_a1_lobby" },
    { floor: "A1", roomId: "a1_hall_clock", checkpoint: "c4_a1_lobby" },
    { floor: "A1", roomId: "a1_power_panel", checkpoint: "c4_a1_lobby" }
  ],
  final_chase: [
    { floor: "A1", roomId: "a1_lobby", checkpoint: "c4_a1_lobby" },
    { floor: "A2", roomId: "a2_corridor", checkpoint: "c4_a2_corridor" }
  ],
  final_minute_recovery: [
    { floor: "A2", roomId: "a2_room_202", checkpoint: "c4_a2_room202" }
  ],
  return_to_clock: [
    { floor: "A2", roomId: "a2_room_202", checkpoint: "c4_a2_room202" },
    { floor: "A2", roomId: "a2_corridor", checkpoint: "c4_a2_corridor" },
    { floor: "A1", roomId: "a1_lobby", checkpoint: "c4_a1_lobby" },
    { floor: "A1", roomId: "a1_hall_clock", checkpoint: "c4_a1_lobby" }
  ],
  morning_checkin: [
    { floor: "A1", roomId: "a1_checkin", checkpoint: "c4_a1_lobby" }
  ],
  exterior_closure: [
    { floor: "A1", roomId: "a1_exterior", checkpoint: "c4_a1_lobby" }
  ],
  complete: []
};

function lockedDetailForIntent(
  state: GameState,
  chapter: ChapterFourState,
  intent: ChapterFour755Intent
): ChapterFour755IntentDetailCode {
  switch (intent.type) {
    case "complete_prologue_handoff":
      return "prologue_requirements_unmet";
    case "adjust_hall_clock_time":
      return "clock_adjustment_required";
    case "move_to_location":
    case "record_checkpoint":
      return "route_not_available";
    case "traverse_main_stair":
      return "stair_route_not_available";
    case "observe_elevator_history":
      return "elevator_history_required";
    case "calibrate_elevator_history":
      return "elevator_calibration_required";
    case "observe_elevator_floor_record":
      return "elevator_floor_records_required";
    case "reconstruct_elevator_stop_chain":
      return chapterFourElevatorRecordsComplete(chapter.factIds)
        ? "elevator_stop_chain_required"
        : "elevator_floor_records_required";
    case "complete_misaligned_stair":
      return hasFact(chapter, "a3_reference_observed")
        ? "misaligned_stair_required"
        : "room204_observations_required";
    case "complete_inserted_puzzle":
      return insertedPuzzleLockedDetail(chapter, intent.answer.puzzleId);
    case "complete_zhu_two_questions":
      return "zhu_two_questions_required";
    case "inspect_bakery_conveyor_edge":
      return hasFact(chapter, "bakery_conveyor_lamp_inspected")
        ? "bakery_stop_pending"
        : "bakery_lamp_required";
    case "complete_bakery_conveyor_stop":
      return hasFact(chapter, "bakery_conveyor_lamp_inspected")
        ? "bakery_stop_pending"
        : "bakery_lamp_required";
    case "collect_hour_hand":
    case "install_hour_hand":
      return "hour_hand_required";
    case "place_room204_piece": {
      if (chapter.room204Placements.some((placement) => placement.pieceId === intent.pieceId)) {
        return "room204_piece_already_placed";
      }
      if (chapter.room204Placements.some((placement) => placement.slotId === intent.slotId)) {
        return "room204_slot_occupied";
      }
      return "target_unavailable";
    }
    case "place_room204_group": {
      if (isRoom204GroupComplete(chapter.room204Placements, intent.groupId)
        || countCompletedRoom204Groups(chapter.room204Placements) >= ROOM204_GROUP_ORDER.length) {
        return "room204_group_already_placed";
      }
      if (!hasFact(chapter, "a3_reference_observed")
        || !hasFact(chapter, "room204_residual_observed")) {
        return "room204_observations_required";
      }
      return "target_unavailable";
    }
    case "complete_room204_projection":
      if (!hasFact(chapter, "a1_time_route_compared")) {
        return "a1_comparison_required";
      }
      if (!hasFact(chapter, "a1_duty_board_reconstructed")) {
        return "duty_board_required";
      }
      if (!hasFact(chapter, "a3_reference_observed")
        || !hasFact(chapter, "room204_residual_observed")) {
        return "room204_observations_required";
      }
      return "room204_layout_incomplete";
    case "collect_positioning_plate":
      return "room204_projection_required";
    case "install_positioning_plate":
      if (!hasFact(chapter, "room204_projection_composite_completed")) {
        return "projection_composite_required";
      }
      if (!hasFact(chapter, "elevator_stop_chain_reconstructed")) {
        return chapterFourElevatorRecordsComplete(chapter.factIds)
          ? "elevator_stop_chain_required"
          : "elevator_floor_records_required";
      }
      if (!hasFact(chapter, "a2_positioning_plate_calibrated")) {
        return "positioning_calibration_required";
      }
      if (!hasFact(chapter, "a2_power_topology_recovered")) {
        return "power_topology_required";
      }
      if (!hasFact(chapter, "a2_evacuation_route_confirmed")) {
        return "evacuation_route_required";
      }
      return "positioning_plate_required";
    case "inspect_cart_wheel":
    case "collect_short_pry_bar":
      if (!hasFact(chapter, "maintenance_incident_linked")) {
        return "maintenance_incident_required";
      }
      return "cart_wheel_inspection_required";
    case "open_cart_wheel_cover":
      return "cart_wheel_inspection_required";
    case "collect_lubricating_oil":
    case "lubricate_cart_wheel":
      return "cart_wheel_cover_required";
    case "lubricate_clock_gear":
      return "cart_wheel_repair_required";
    case "begin_final_clock_drag":
      return hasFact(chapter, "clock_gear_repaired")
        ? "final_clock_drag_not_armed"
        : "clock_gear_repair_required";
    case "complete_minute_theft":
    case "trigger_minute_theft":
      return "final_clock_drag_not_armed";
    case "open_power_panel":
    case "toggle_light_zone":
    case "lock_light_grid":
      return "blackout_not_started";
    case "reach_202_threshold":
      return hasFact(chapter, "powered_route_confirmed")
        ? "chase_attempt_stale"
        : "powered_route_required";
    case "fail_chase":
      return "chase_attempt_stale";
    case "collect_final_minute":
      return "final_minute_not_recovered";
    case "install_final_minute":
      if (!state.chapterThreeInterlude.completed
        || state.chapterThreeInterlude.phase !== "complete") {
        return "interlude_completion_required";
      }
      if (!hasFact(chapter, "final_minute_recovered") || !state.items.finalMinute) {
        return "final_minute_not_recovered";
      }
      return "return_route_incomplete";
    case "read_campus_card":
      if (chapter.checkinCardAccepted || hasFact(chapter, "checkin_card_accepted")) {
        return "checkin_card_already_accepted";
      }
      return hasFact(chapter, "a3_identity_context_observed")
        ? "checkin_requirements_incomplete"
        : "identity_context_required";
    case "submit_attendance_paper":
      if (chapter.checkinPaperAccepted || hasFact(chapter, "checkin_paper_accepted")) {
        return "checkin_paper_already_accepted";
      }
      return "checkin_requirements_incomplete";
    case "acknowledge_exterior_closure":
      return "closure_prerequisites_incomplete";
    default:
      return "current_phase_mismatch";
  }
}

function room204IssueDetailCode(
  issue: "unknown_piece" | "unknown_slot" | "invalid_orientation" | "duplicate_piece" | "occupied_slot" | "already_placed"
): ChapterFour755IntentDetailCode {
  const byIssue: Record<typeof issue, ChapterFour755IntentDetailCode> = {
    unknown_piece: "room204_unknown_piece",
    unknown_slot: "room204_unknown_slot",
    invalid_orientation: "room204_invalid_orientation",
    duplicate_piece: "room204_duplicate_piece",
    occupied_slot: "room204_slot_occupied",
    already_placed: "room204_piece_already_placed"
  };
  return byIssue[issue];
}

function room204GroupIssueDetailCode(
  issue: "unknown_group" | "wrong_group" | "group_conflict" | "already_placed"
): ChapterFour755IntentDetailCode {
  const byIssue: Record<typeof issue, ChapterFour755IntentDetailCode> = {
    unknown_group: "room204_unknown_group",
    wrong_group: "room204_wrong_group",
    group_conflict: "room204_group_conflict",
    already_placed: "room204_group_already_placed"
  };
  return byIssue[issue];
}

export class ChapterFourTemporalMazeController {
  private finalClockDragArmed = false;

  constructor(
    private readonly store: GameStore,
    private readonly events: EventBus,
    private readonly closureSessionVerifier: ChapterFourClosureSessionVerifier =
      BLOCKED_CHAPTER_FOUR_CLOSURE_SESSION_VERIFIER
  ) {}

  resolve755Intent(
    intent: ChapterFour755Intent,
    runtimeTarget?: ChapterFour755RuntimeTargetContext
  ): ChapterFour755IntentResult {
    const state = this.store.getState();
    const chapter = activeChapterFour(state);
    const previousPhase = chapter?.phase ?? null;
    const previousTimeState = chapter?.timeState ?? null;
    const reject = (
      reason: Exclude<ChapterFour755IntentResultReason, "accepted">,
      detailCode?: ChapterFour755IntentDetailCode
    ): ChapterFour755IntentResult => ({
      accepted: false,
      changed: false,
      reason,
      ...(reason === "locked"
        ? {
            detailCode: detailCode ?? (chapter
              ? lockedDetailForIntent(state, chapter, intent)
              : "current_phase_mismatch")
          }
        : detailCode
          ? { detailCode }
          : {}),
      intentType: intent.type,
      previousPhase,
      phase: previousPhase,
      previousTimeState,
      timeState: previousTimeState
    });
    const accept = (nextState: GameState): ChapterFour755IntentResult => {
      const nextChapter = activeChapterFour(nextState);
      this.store.setState(() => nextState);
      try {
        this.events.emit("chapter4_755_intent_committed", {
          intentType: intent.type,
          previousPhase,
          phase: nextChapter?.phase ?? previousPhase
        });
      } catch {
        // Presentation listeners cannot reverse an already committed domain
        // transaction or make the host retry the same intent.
      }
      return {
        accepted: true,
        changed: true,
        reason: "accepted",
        intentType: intent.type,
        previousPhase,
        phase: nextChapter?.phase ?? previousPhase,
        previousTimeState,
        timeState: nextChapter?.timeState ?? previousTimeState
      };
    };
    const acceptReadOnly = (): ChapterFour755IntentResult => ({
      accepted: true,
      changed: false,
      reason: "accepted",
      intentType: intent.type,
      previousPhase,
      phase: previousPhase,
      previousTimeState,
      timeState: previousTimeState
    });

    if (!chapter) return reject("inactive");
    if (intent.type === "complete_prologue_handoff") {
      if (chapter.prologueSeen) return reject("already_complete");
      if (chapter.phase !== "opening_handoff"
        || state.qizhenLake.phase !== "complete"
        || state.chapterThreeInterlude.phase !== "replay_ready"
        || !state.chapterThreeInterlude.replayUnlocked) {
        return reject("locked");
      }
      const next = this.transition(state, "opening_handoff", {
        prologueSeen: true,
        floor: "A1",
        roomId: "a1_lobby",
        checkpoint: "c4_a1_lobby"
      });
      return accept({
        ...next,
        ui: { ...next.ui, inventoryOpen: false, selectedItem: null },
        chapterThreeInterlude: {
          ...next.chapterThreeInterlude,
          phase: "complete",
          completed: true
        }
      });
    }
    if (!chapter.prologueSeen) return reject("inactive");
    if (chapter.completed || chapter.phase === "complete") return reject("already_complete");
    if (!isChapterFourPhaseTimeAligned(chapter)
      && intent.type !== "adjust_hall_clock_time"
      && intent.type !== "set_mode") {
      return reject("locked", "clock_adjustment_required");
    }
    if (isChapterFour755TargetIntent(intent)) {
      const resolvedTarget = runtimeTarget === undefined
        ? undefined
        : runtimeTarget.targetId === intent.targetId
          ? resolveChapterFour755RuntimeEntityTarget(
              runtimeTarget.targetId,
              runtimeTarget.entityId,
              runtimeTarget.bounds
            ) ?? undefined
          : undefined;
      if (runtimeTarget !== undefined && resolvedTarget === undefined) return reject("locked");
      const contractRejection = validateChapterFour755TargetIntentContract(state, {
        targetId: intent.targetId,
        spatial: intent.spatial,
        ...("itemId" in intent ? { itemId: intent.itemId } : {}),
        ...("pieceId" in intent ? { pieceId: intent.pieceId } : {})
      }, resolvedTarget);
      if (contractRejection) return reject(contractRejection);
    } else if (runtimeTarget !== undefined) {
      return reject("locked");
    }

    switch (intent.type) {
      case "complete_opening_paper_flight": {
        if (chapter.phase !== "opening_handoff") return reject("locked");
        if (hasFact(chapter, "opening_paper_at_noticeboard")) return reject("already_complete");
        return accept(this.patchChapter(state, {
          factIds: appendFact(chapter, "opening_paper_at_noticeboard")
        }));
      }

      case "resolve_external_time_rejection": {
        if (chapter.phase !== "opening_paper_caught"
          || !hasFact(chapter, "opening_paper_at_noticeboard")
          || !hasFact(chapter, "opening_paper_caught")) {
          return reject("locked");
        }
        if (hasFact(chapter, "external_time_rejected")) return reject("already_complete");
        return accept(this.patchChapter(state, {
          factIds: appendFact(chapter, "external_time_rejected")
        }));
      }

      case "resolve_hall_clock_inspection": {
        if (chapter.phase !== "hall_clock_inspection"
          || !hasFact(chapter, "external_time_rejected")) {
          return reject("locked");
        }
        if (hasFact(chapter, "hall_clock_inspected")) return reject("already_complete");
        return accept(this.patchChapter(state, {
          factIds: appendFact(chapter, "hall_clock_inspected")
        }));
      }

      case "set_mode": {
        if (chapter.mode === intent.mode) return reject("already_complete");
        return accept(this.patchChapter(state, { mode: intent.mode }));
      }

      case "observe_elevator_history": {
        if (chapter.phase !== "room204_restore"
          || chapter.floor !== "A1") {
          return reject("locked", "elevator_history_required");
        }
        if (chapter.mode !== "dark") return reject("wrong_mode");
        if (hasFact(chapter, "elevator_history_observed")) return reject("already_complete");
        return accept(this.patchChapter(state, {
          factIds: finalizeChapterFourCausalFacts(
            appendFact(chapter, "elevator_history_observed")
          )
        }));
      }

      case "calibrate_elevator_history": {
        if (chapter.phase !== "room204_restore"
          || chapter.floor !== "A1") {
          return reject("locked", "elevator_calibration_required");
        }
        if (chapter.mode !== "light") return reject("wrong_mode");
        if (hasFact(chapter, "elevator_history_calibrated")) return reject("already_complete");
        if (!isChapterFourElevatorStartSelectable(intent.startSeconds)
          || !isChapterFourElevatorTrackAligned(intent.startSeconds)) {
          return reject("incorrect");
        }
        return accept(this.patchChapter(state, {
          factIds: finalizeChapterFourCausalFacts(
            appendFact(chapter, "elevator_history_calibrated")
          )
        }));
      }

      case "observe_elevator_floor_record": {
        if (chapter.phase !== "room204_restore"
          || chapter.floor !== intent.floor) {
          return reject("locked", "elevator_floor_records_required");
        }
        if (chapter.mode !== "dark") return reject("wrong_mode");
        const record = CHAPTER_FOUR_ELEVATOR_FLOOR_RECORDS[intent.floor];
        if (hasFact(chapter, record.factId)) return reject("already_complete");
        if (intent.floor === "A1") {
          return reject("locked", "elevator_history_required");
        }
        if (intent.floor === "A2" && !hasFact(chapter, "misaligned_stair_solved")) {
          return reject("locked", "misaligned_stair_required");
        }
        if (intent.floor === "A3" && !hasFact(chapter, "elevator_history_calibrated")) {
          return reject("locked", "elevator_calibration_required");
        }
        return accept(this.patchChapter(state, {
          factIds: appendFact(chapter, record.factId)
        }));
      }

      case "reconstruct_elevator_stop_chain": {
        if (chapter.phase !== "room204_restore") {
          return reject("locked", "elevator_stop_chain_required");
        }
        if (chapter.mode !== "light") return reject("wrong_mode");
        if (hasFact(chapter, "elevator_stop_chain_reconstructed")) {
          return reject("already_complete");
        }
        if (!chapterFourElevatorRecordsComplete(chapter.factIds)) {
          return reject("locked", "elevator_floor_records_required");
        }
        if (!isChapterFourElevatorStopChainCorrect(intent)) return reject("incorrect");
        return accept(this.patchChapter(state, {
          factIds: appendFact(chapter, "elevator_stop_chain_reconstructed")
        }));
      }

      case "complete_misaligned_stair": {
        if (chapter.phase !== "room204_restore"
          || chapter.floor !== "A3") {
          return reject("locked", "misaligned_stair_required");
        }
        if (!hasFact(chapter, "a3_reference_observed")) {
          return reject("locked", "room204_observations_required");
        }
        if (hasFact(chapter, "misaligned_stair_solved")) return reject("already_complete");
        const withSolvedStair = this.patchChapter(state, {
          factIds: appendFact(chapter, "misaligned_stair_solved")
        });
        return accept(this.relocate(withSolvedStair, {
          floor: "A2",
          roomId: "a2_corridor",
          checkpoint: "c4_a2_corridor"
        }));
      }

      case "move_to_location":
      case "record_checkpoint": {
        if ((chapter.phase === "final_chase" || chapter.phase === "return_to_clock")
          && chapter.floor !== intent.floor) return reject("locked");
        if (chapter.phase === "room204_restore"
          && intent.floor !== "A1"
          && (!hasFact(chapter, "classroom_104_chalk_residual_observed")
            || !hasFact(chapter, "classroom_105_terminal_replay_checked"))) {
          return reject("locked", "classroom_checks_required");
        }
        if (chapter.phase === "room204_restore"
          && intent.floor === "A3"
          && !hasFact(chapter, "elevator_history_calibrated")) {
          return reject("locked", "elevator_calibration_required");
        }
        if (chapter.phase === "room204_restore"
          && intent.floor === "A2"
          && !hasFact(chapter, "misaligned_stair_solved")) {
          return reject("locked", "misaligned_stair_required");
        }
        if (chapter.phase === "room204_restore"
          && chapter.floor === "A3"
          && intent.floor === "A1"
          && !hasFact(chapter, "misaligned_stair_solved")) {
          return reject("locked", "misaligned_stair_required");
        }
        if (!isAllowedLocation(chapter.phase, intent)) return reject("locked");
        if (chapter.floor === intent.floor
          && chapter.roomId === intent.roomId
          && state.rpgCheckpoint === intent.checkpoint) {
          return reject("already_complete");
        }
        return accept(this.relocate(state, intent));
      }

      case "traverse_main_stair": {
        if (intent.expectedAttempt !== chapter.chaseAttempt
          || chapter.floor !== intent.fromFloor) return reject("locked");
        if (chapter.phase === "final_chase"
          && intent.fromFloor === "A1"
          && intent.toFloor === "A2") {
          return accept(this.relocate(state, {
            floor: "A2",
            roomId: "a2_corridor",
            checkpoint: "c4_a2_corridor"
          }));
        }
        if (chapter.phase === "return_to_clock"
          && intent.fromFloor === "A2"
          && intent.toFloor === "A1") {
          return accept(this.relocate(state, {
            floor: "A1",
            roomId: "a1_lobby",
            checkpoint: "c4_a1_lobby"
          }));
        }
        return reject("locked");
      }

      case "catch_attendance_paper": {
        return accept(this.transition(state, "opening_paper_caught", {
          factIds: appendFact(chapter, "opening_paper_caught"),
          items: withItem(state, "attendanceRecordPaper", true)
        }));
      }

      case "inspect_hall_clock": {
        return accept(this.transition(state, "hall_clock_inspection"));
      }

      case "pull_hall_clock": {
        return reject("locked", "clock_adjustment_required");
      }

      case "adjust_hall_clock_time": {
        const requiredTimeState = selectChapterFourRequiredClockTime(chapter);
        if (!requiredTimeState) return reject("locked", "clock_adjustment_required");
        if (intent.targetTimeState === chapter.timeState) return reject("already_complete");
        if (intent.targetTimeState !== requiredTimeState) return reject("incorrect");
        const next = chapter.phase === "hall_clock_inspection"
          ? this.transition(state, "bakery_hour_hand")
          : this.applyTimeState(state, chapter.phase, intent.targetTimeState);
        const result = accept(next);
        this.emitChapterFourCue("chapter4_time_swap_committed", {
          previousPhase,
          phase: next.chapter4.phase,
          previousTimeState,
          timeState: intent.targetTimeState
        });
        return result;
      }

      case "inspect_bakery_conveyor_lamp": {
        if (chapter.phase !== "bakery_hour_hand"
          || hasFact(chapter, "bakery_hour_hand_exposed")
          || hasFact(chapter, "bakery_hour_hand_collected")
          || hasFact(chapter, "hour_hand_installed")) return reject("locked");
        if (hasFact(chapter, "bakery_conveyor_lamp_inspected")) return reject("already_complete");
        return accept(this.patchChapter(state, {
          factIds: appendFact(chapter, "bakery_conveyor_lamp_inspected")
        }));
      }

      case "inspect_bakery_conveyor_edge": {
        if (chapter.phase !== "bakery_hour_hand"
          || hasFact(chapter, "bakery_hour_hand_exposed")
          || hasFact(chapter, "bakery_hour_hand_collected")
          || hasFact(chapter, "hour_hand_installed")) return reject("locked");
        if (!hasFact(chapter, "bakery_conveyor_lamp_inspected")) return reject("locked");
        return reject("locked");
      }

      case "complete_bakery_conveyor_stop": {
        if (chapter.phase !== "bakery_hour_hand"
          || !hasFact(chapter, "bakery_conveyor_lamp_inspected")
          || hasFact(chapter, "bakery_hour_hand_collected")
          || hasFact(chapter, "hour_hand_installed")) return reject("locked");
        if (hasFact(chapter, "bakery_hour_hand_exposed")) return reject("already_complete");
        return accept(this.patchChapter(state, {
          factIds: appendFacts(chapter, [
            "bakery_conveyor_direction_observed",
            "bakery_tool_location_observed",
            "bakery_hour_hand_exposed"
          ])
        }));
      }

      case "collect_hour_hand": {
        if (chapter.phase !== "bakery_hour_hand"
          || !hasFact(chapter, "bakery_conveyor_lamp_inspected")
          || !hasFact(chapter, "bakery_hour_hand_exposed")
          || hasFact(chapter, "hour_hand_installed")) return reject("locked");
        if (hasFact(chapter, "bakery_hour_hand_collected") || state.items.oldClockHourHand) {
          return reject("already_complete");
        }
        return accept(this.patchChapter(state, {
          factIds: appendFact(chapter, "bakery_hour_hand_collected")
        }, withItem(state, "oldClockHourHand", true)));
      }

      case "install_hour_hand": {
        if (chapter.phase !== "bakery_hour_hand"
          || !hasFact(chapter, "bakery_conveyor_lamp_inspected")
          || !hasFact(chapter, "bakery_hour_hand_exposed")
          || !hasFact(chapter, "bakery_hour_hand_collected")
          || !state.items.oldClockHourHand
          || hasFact(chapter, "hour_hand_installed")) return reject("locked");
        const result = accept(this.advancePhaseKeepingTime(state, "room204_restore", {
          factIds: appendFact(chapter, "hour_hand_installed"),
          items: withItem(state, "oldClockHourHand", false),
          floor: "A1",
          roomId: "a1_hall_clock",
          checkpoint: "c4_a1_lobby"
        }));
        return result;
      }

      case "talk_to_a1_front_desk_attendant":
      case "talk_to_chapter_four_support_npc":
      case "inspect_alumni_figure":
        return acceptReadOnly();

      case "inspect_chapter_four_context": {
        const puzzleId = chapterFourInsertedPuzzleForTarget(intent.targetId);
        if (puzzleId) {
          const definition = CHAPTER_FOUR_INSERTED_PUZZLES[puzzleId];
          this.emitChapterFourCue("chapter4_inserted_puzzle_requested", {
            puzzleId,
            targetId: intent.targetId,
            mode: chapter.mode,
            completed: hasFact(chapter, definition.factId),
            prerequisiteReady: insertedPuzzlePrerequisiteReady(chapter, puzzleId)
          });
        }
        return acceptReadOnly();
      }

      case "complete_inserted_puzzle": {
        const { answer } = intent;
        const definition = CHAPTER_FOUR_INSERTED_PUZZLES[answer.puzzleId];
        if (chapter.phase !== "room204_restore"
          || chapter.floor !== insertedPuzzleFloor(answer.puzzleId)) {
          return reject("locked", insertedPuzzleLockedDetail(chapter, answer.puzzleId));
        }
        if (!insertedPuzzlePrerequisiteReady(chapter, answer.puzzleId)) {
          return reject("locked", insertedPuzzleLockedDetail(chapter, answer.puzzleId));
        }
        if (hasFact(chapter, definition.factId)) return reject("already_complete");
        if (!isChapterFourInsertedPuzzleAnswerCorrect(answer)) return reject("incorrect");
        const result = accept(this.patchChapter(state, {
          factIds: appendFact(chapter, definition.factId)
        }));
        this.emitChapterFourCue("chapter4_inserted_puzzle_completed", {
          puzzleId: answer.puzzleId,
          factId: definition.factId,
          successText: definition.successText
        });
        return result;
      }

      case "complete_zhu_two_questions": {
        if (chapter.phase !== "exterior_closure"
          || chapter.floor !== "A1"
          || chapter.roomId !== "a1_exterior") {
          return reject("locked", "zhu_two_questions_required");
        }
        if (!hasFact(chapter, "a3_identity_context_observed")
          || !hasFact(chapter, "attendance_record_recovered")
          || !hasFact(chapter, "checkin_identity_verified")) {
          return reject("locked", "identity_context_required");
        }
        if (hasFact(chapter, "zhu_two_questions_answered")) return reject("already_complete");
        if (!ZHU_PURPOSE_ANSWER_IDS.has(intent.purposeAnswer)
          || !ZHU_PERSON_ANSWER_IDS.has(intent.personAnswer)) return reject("incorrect");
        const result = accept(this.patchChapter(state, {
          factIds: appendFact(chapter, "zhu_two_questions_answered"),
          zhuQuestionAnswers: {
            purpose: intent.purposeAnswer,
            person: intent.personAnswer
          }
        }));
        this.emitChapterFourCue("zhu_two_questions_answered", {
          purposeAnswer: intent.purposeAnswer,
          personAnswer: intent.personAnswer,
          nextConsumer: "canruo_star_lamp"
        });
        return result;
      }

      case "observe_classroom_104_chalk_residual": {
        if (hasFact(chapter, "classroom_104_chalk_residual_observed")) {
          return acceptReadOnly();
        }
        return accept(this.patchChapter(state, {
          factIds: finalizeChapterFourCausalFacts(
            appendFact(chapter, "classroom_104_chalk_residual_observed")
          )
        }));
      }

      case "check_classroom_105_terminal_replay": {
        if (hasFact(chapter, "classroom_105_terminal_replay_checked")) {
          return acceptReadOnly();
        }
        return accept(this.patchChapter(state, {
          factIds: finalizeChapterFourCausalFacts(
            appendFact(chapter, "classroom_105_terminal_replay_checked")
          )
        }));
      }

      case "observe_a3_reference": {
        const factIds = appendFacts(chapter, [
          "a3_reference_observed",
          "a3_identity_context_observed"
        ]);
        return accept(this.patchChapter(state, {
          factIds: finalizeChapterFourCausalFacts(
            finalizeRoom204Facts(factIds, chapter.room204Placements)
          )
        }));
      }

      case "observe_room204_residual": {
        const factIds = appendFact(chapter, "room204_residual_observed");
        return accept(this.patchChapter(state, {
          factIds: finalizeChapterFourCausalFacts(
            finalizeRoom204Facts(factIds, chapter.room204Placements)
          )
        }));
      }

      case "place_room204_piece": {
        if (intent.targetId !== room204SlotTargetId(intent.slotId)) return reject("locked");
        const resolution = resolveRoom204Placement(chapter.room204Placements, {
          pieceId: intent.pieceId,
          slotId: intent.slotId,
          orientation: intent.orientation
        });
        if (!resolution.accepted) {
          return reject(
            resolution.issue === "already_placed" ? "already_complete" : "incorrect",
            room204IssueDetailCode(resolution.issue)
          );
        }
        return accept(this.patchChapter(state, {
          room204Placements: resolution.placements,
          factIds: finalizeChapterFourCausalFacts(
            finalizeRoom204Facts(chapter.factIds, resolution.placements)
          )
        }));
      }

      case "place_room204_group": {
        if (intent.targetId !== room204GroupTargetId(intent.groupId)) return reject("locked");
        const resolution = resolveRoom204GroupPlacement(chapter.room204Placements, {
          groupId: intent.groupId,
          targetGroupId: intent.groupId
        });
        if (!resolution.accepted) {
          return reject(
            resolution.issue === "already_placed" ? "already_complete" : "incorrect",
            room204GroupIssueDetailCode(resolution.issue)
          );
        }
        return accept(this.patchChapter(state, {
          room204Placements: resolution.placements,
          factIds: finalizeChapterFourCausalFacts(
            finalizeRoom204Facts(chapter.factIds, resolution.placements)
          )
        }));
      }

      case "complete_room204_projection": {
        if (chapter.phase !== "room204_restore"
          || !hasFact(chapter, "a1_time_route_compared")
          || !hasFact(chapter, "a1_duty_board_reconstructed")
          || !hasFact(chapter, "a3_reference_observed")
          || !hasFact(chapter, "a3_identity_context_observed")
          || !hasFact(chapter, "room204_residual_observed")
          || !hasFact(chapter, "room204_restored")
          || !isRoom204PlacementSetComplete(chapter.room204Placements)) return reject("locked");
        if (hasFact(chapter, "room204_projection_completed")) return reject("already_complete");
        return accept(this.patchChapter(state, {
          factIds: finalizeChapterFourCausalFacts(
            appendFact(chapter, "room204_projection_completed")
          )
        }));
      }

      case "collect_positioning_plate": {
        if (!hasFact(chapter, "room204_projection_completed")
          || hasFact(chapter, "positioning_plate_collected")
          || state.items.clockPositioningPlate) return reject("locked");
        const result = accept(this.patchChapter(state, {
          factIds: appendFact(chapter, "positioning_plate_collected")
        }, withItem(state, "clockPositioningPlate", true)));
        this.emitChapterFourCue("room204_drawer_opened", {
          phase: chapter.phase,
          targetId: intent.targetId
        });
        return result;
      }

      case "install_positioning_plate": {
        if (!hasFact(chapter, "room204_projection_composite_completed")
          || !hasFact(chapter, "positioning_plate_collected")
          || !hasFact(chapter, "a2_positioning_plate_calibrated")
          || !hasFact(chapter, "a2_power_topology_recovered")
          || !hasFact(chapter, "a2_evacuation_route_confirmed")
          || !hasFact(chapter, "elevator_stop_chain_reconstructed")
          || !state.items.clockPositioningPlate
          || hasFact(chapter, "positioning_plate_installed")) return reject("locked");
        const result = accept(this.advancePhaseKeepingTime(state, "maintenance_repair", {
          factIds: appendFact(chapter, "positioning_plate_installed"),
          items: withItem(state, "clockPositioningPlate", false),
          floor: "A1",
          roomId: "a1_hall_clock",
          checkpoint: "c4_a1_lobby"
        }));
        return result;
      }

      case "inspect_cart_wheel": {
        if (chapter.phase !== "maintenance_repair"
          || chapter.guardMode !== "patrol"
          || !hasFact(chapter, "maintenance_incident_linked")
          || hasFact(chapter, "cart_wheel_cover_opened")
          || hasFact(chapter, "cart_wheel_repaired")
          || hasFact(chapter, "clock_gear_repaired")) return reject("locked");
        if (hasFact(chapter, "cart_wheel_inspected")) return reject("already_complete");
        this.emitChapterFourCue("chapter4_maintenance_diagnosis_requested", {
          phase: chapter.phase,
          targetId: intent.targetId
        });
        return acceptReadOnly();
      }

      case "complete_maintenance_diagnosis": {
        if (chapter.phase !== "maintenance_repair"
          || chapter.guardMode !== "patrol"
          || hasFact(chapter, "cart_wheel_inspected")) return reject("locked");
        const correct = intent.answers.wheel_sound === "latch"
          && intent.answers.clock_jam === "gear_offset"
          && intent.answers.oil_trace === "oil_shortage";
        if (!correct) {
          this.emitChapterFourCue("chapter4_maintenance_diagnosis_rejected", { phase: chapter.phase });
          return reject("incorrect");
        }
        const result = accept(this.patchChapter(state, {
          factIds: appendFact(chapter, "cart_wheel_inspected")
        }, {
          ...state.items,
          shortPryBar: true,
          universalLubricatingOil: true
        }));
        this.emitChapterFourCue("chapter4_maintenance_diagnosis_completed", {
          phase: chapter.phase,
          actions: ["open_cart_wheel_cover", "lubricate_maintenance_linkage"]
        });
        return result;
      }

      case "collect_short_pry_bar": {
        return reject("locked");
      }

      case "open_cart_wheel_cover": {
        if (chapter.phase !== "maintenance_repair"
          || !hasFact(chapter, "cart_wheel_inspected")
          || !state.items.shortPryBar
          || hasFact(chapter, "cart_wheel_cover_opened")) return reject("locked");
        return accept(this.patchChapter(state, {
          factIds: appendFact(chapter, "cart_wheel_cover_opened")
        }, withItem(state, "shortPryBar", false)));
      }

      case "collect_lubricating_oil": {
        return reject("locked");
      }

      case "lubricate_cart_wheel": {
        if (chapter.phase !== "maintenance_repair"
          || !hasFact(chapter, "cart_wheel_cover_opened")
          || !state.items.universalLubricatingOil
          || hasFact(chapter, "cart_wheel_repaired")) return reject("locked");
        const repairedFacts = appendFact(chapter, "cart_wheel_repaired");
        if (!repairedFacts.includes("clock_gear_repaired")) repairedFacts.push("clock_gear_repaired");
        const result = accept(this.patchChapter(state, {
          factIds: repairedFacts
        }, withItem(state, "universalLubricatingOil", false)));
        this.emitChapterFourCue("maintenance_cart_wheel_repaired", {
          phase: chapter.phase,
          targetId: intent.targetId,
          clockGearAligned: true
        });
        this.emitChapterFourCue("clock_gear_repaired", {
          phase: chapter.phase,
          targetId: intent.targetId,
          linkedAction: true
        });
        return result;
      }

      case "lubricate_clock_gear": {
        return hasFact(chapter, "clock_gear_repaired")
          ? reject("already_complete")
          : reject("locked");
      }

      case "recover_from_maintenance_patrol": {
        if (chapter.phase !== "maintenance_repair" || chapter.guardMode !== "patrol") {
          return reject("locked");
        }
        return accept({
          ...state,
          rpgCheckpoint: "c4_a1_lobby",
          chapter4: {
            ...state.chapter4,
            building: "A",
            floor: "A1",
            roomId: "a1_lobby"
          },
          ui: {
            ...state.ui,
            inventoryOpen: false,
            selectedItem: null
          }
        });
      }

      case "trigger_minute_theft": {
        // Retained only for old queued requests. Task 11 uses a read-only
        // begin handshake followed by the authored completion transaction.
        return reject("locked");
      }

      case "begin_final_clock_drag": {
        if (chapter.phase !== "maintenance_repair"
          || !hasFact(chapter, "clock_gear_repaired")
          || !state.items.attendanceRecordPaper
          || hasFact(chapter, "paper_temporarily_out_of_inventory")) return reject("locked");
        this.finalClockDragArmed = true;
        return acceptReadOnly();
      }

      case "complete_minute_theft": {
        if (!this.finalClockDragArmed
          || chapter.phase !== "maintenance_repair"
          || !hasFact(chapter, "clock_gear_repaired")
          || !state.items.attendanceRecordPaper
          || hasFact(chapter, "paper_temporarily_out_of_inventory")) {
          this.finalClockDragArmed = false;
          return reject("locked");
        }
        if (chapter.mode !== "light") {
          this.finalClockDragArmed = false;
          return reject("wrong_mode");
        }
        this.finalClockDragArmed = false;
        const next = this.transition(state, "blackout_light_grid", {
          factIds: appendFact(chapter, "paper_temporarily_out_of_inventory"),
          items: withItem(state, "attendanceRecordPaper", false),
          lightGrid: {
            mask: CHAPTER_FOUR_LIGHT_GRID.initialMask,
            locked: false
          },
          floor: "A1",
          roomId: "a1_lobby",
          checkpoint: "c4_a1_lobby"
        });
        const result = accept(next);
        this.emitChapterFourCue("blackout_committed", {
          previousPhase,
          phase: "blackout_light_grid",
          timeState: "0754_blackout",
          mask: CHAPTER_FOUR_LIGHT_GRID.initialMask
        });
        return result;
      }

      case "open_power_panel": {
        if (chapter.phase !== "blackout_light_grid"
          || !hasFact(chapter, "paper_temporarily_out_of_inventory")
          || hasFact(chapter, "light_grid_locked")
          || chapter.lightGrid.locked) return reject("locked");
        return acceptReadOnly();
      }

      case "toggle_light_zone": {
        if (chapter.phase !== "blackout_light_grid"
          || !hasFact(chapter, "paper_temporarily_out_of_inventory")
          || hasFact(chapter, "light_grid_locked")
          || chapter.lightGrid.locked) return reject("locked");
        if (!LIGHT_ZONE_IDS.has(intent.zoneId)) return reject("incorrect");
        const previousMask = chapter.lightGrid.mask;
        const nextMask = toggleChapterFourLightZone(previousMask, intent.zoneId);
        const result = accept(this.patchChapter(state, {
          lightGrid: {
            mask: nextMask,
            locked: false
          }
        }));
        this.emitChapterFourCue("power_zone_toggled", {
          zoneId: intent.zoneId,
          previousMask,
          mask: nextMask
        });
        return result;
      }

      case "lock_light_grid": {
        if (chapter.phase !== "blackout_light_grid"
          || !hasFact(chapter, "paper_temporarily_out_of_inventory")
          || hasFact(chapter, "light_grid_locked")
          || chapter.lightGrid.locked) return reject("locked");
        if (!isChapterFourLightGridSolved(chapter.lightGrid.mask)
          || chapter.lightGrid.mask !== CHAPTER_FOUR_LIGHT_GRID.targetMask) return reject("incorrect");
        if (!hasFact(chapter, "room204_projection_composite_completed")
          || !hasFact(chapter, "room202_endpoint_inferred")) {
          return reject("locked", "projection_composite_required");
        }
        if (!hasFact(chapter, "a2_power_topology_recovered")) {
          return reject("locked", "power_topology_required");
        }
        if (!hasFact(chapter, "a2_evacuation_route_confirmed")) {
          return reject("locked", "evacuation_route_required");
        }
        const lightGridFacts = finalizeChapterFourCausalFacts(
          appendFact(chapter, "light_grid_locked")
        );
        const primedFacts = appendFact(
          { ...chapter, factIds: lightGridFacts },
          "canruo_star_lamp_primed"
        );
        const result = accept(this.transition(state, "final_chase", {
          factIds: primedFacts,
          lightGrid: { mask: CHAPTER_FOUR_LIGHT_GRID.targetMask, locked: true },
          chaseRestartCheckpoint: "c4_a1_lobby",
          floor: "A1",
          roomId: "a1_lobby",
          checkpoint: "c4_a1_lobby"
        }));
        this.emitChapterFourCue("power_grid_locked", {
          mask: CHAPTER_FOUR_LIGHT_GRID.targetMask,
          phase: "final_chase",
          canruoStarLampPrimed: true,
          zhuQuestionAnswers: { purpose: null, person: null }
        });
        return result;
      }

      case "reach_202_threshold": {
        if (chapter.phase !== "final_chase"
          || intent.expectedAttempt !== chapter.chaseAttempt
          || chapter.floor !== "A2"
          || !hasFact(chapter, "light_grid_locked")
          || !hasFact(chapter, "powered_route_confirmed")
          || !hasFact(chapter, "room202_endpoint_inferred")) return reject("locked");
        return accept(this.transition(state, "final_minute_recovery", {
          factIds: appendFact(chapter, "room202_route_reached"),
          floor: "A2",
          roomId: "a2_room_202",
          checkpoint: "c4_a2_room202"
        }));
      }

      case "fail_chase": {
        if (chapter.phase !== "final_chase"
          || intent.expectedAttempt !== chapter.chaseAttempt
          || intent.failureFloor !== chapter.floor) return reject("locked");
        const failedUpstairs = intent.failureFloor === "A2";
        return accept(this.transition(state, "final_chase", {
          chaseAttempt: chapter.chaseAttempt + 1,
          chaseRestartCheckpoint: failedUpstairs ? "c4_a2_corridor" : "c4_a1_lobby",
          floor: failedUpstairs ? "A2" : "A1",
          roomId: failedUpstairs ? "a2_corridor" : "a1_lobby",
          checkpoint: failedUpstairs ? "c4_a2_corridor" : "c4_a1_lobby"
        }));
      }

      case "collect_final_minute": {
        if (chapter.phase !== "final_minute_recovery"
          || chapter.floor !== "A2"
          || chapter.roomId !== "a2_room_202"
          || !hasFact(chapter, "paper_temporarily_out_of_inventory")
          || !hasFact(chapter, "powered_route_confirmed")
          || !hasFact(chapter, "room202_endpoint_inferred")
          || !hasFact(chapter, "room202_route_reached")
          || hasFact(chapter, "final_minute_recovered")
          || state.items.finalMinute) return reject("locked");
        const items = withItem(withItemState(state, "finalMinute", true), "attendanceRecordPaper", true);
        return accept(this.transition(state, "return_to_clock", {
          factIds: appendFacts(chapter, [
            "final_minute_recovered",
            "attendance_record_recovered"
          ]),
          items,
          floor: "A2",
          roomId: "a2_room_202",
          checkpoint: "c4_a2_room202"
        }));
      }

      case "install_final_minute": {
        if (chapter.phase !== "return_to_clock"
          || chapter.floor !== "A1"
          || !["a1_lobby", "a1_hall_clock"].includes(chapter.roomId)
          || !hasFact(chapter, "final_minute_recovered")
          || hasFact(chapter, "final_minute_installed")
          || !state.items.finalMinute
          || !state.items.attendanceRecordPaper
          || !state.items.campusCard
          || chapter.mode !== "light"
          || chapter.guardMode !== "absent"
          || !state.chapterThreeInterlude.completed
          || state.chapterThreeInterlude.phase !== "complete") return reject("locked");
        const result = accept(this.transition(state, "morning_checkin", {
          factIds: appendFact(chapter, "final_minute_installed"),
          items: withItem(state, "finalMinute", false),
          floor: "A1",
          roomId: "a1_checkin",
          checkpoint: "c4_a1_lobby",
          checkinCardAccepted: false,
          checkinPaperAccepted: false,
          exteriorClosureAcknowledged: false,
          completed: false,
          chaseRestartCheckpoint: null
        }));
        this.emitChapterFourCue("final_minute_installed", {
          previousPhase,
          phase: "morning_checkin",
          timeState: "0755_morning",
          worldTimeSeconds: 28500,
          phoneStatusTimeSeconds: 28500,
          phoneStatusTimeTrusted: true
        });
        return result;
      }

      case "read_campus_card": {
        if (chapter.phase !== "morning_checkin"
          || chapter.floor !== "A1"
          || chapter.roomId !== "a1_checkin"
          || chapter.guardMode !== "absent"
          || !state.chapterThreeInterlude.completed
          || state.chapterThreeInterlude.phase !== "complete"
          || !hasFact(chapter, "final_minute_installed")
          || !hasFact(chapter, "a3_identity_context_observed")
          || !hasFact(chapter, "attendance_record_recovered")
          || !state.items.campusCard
          || chapter.checkinCardAccepted
          || hasFact(chapter, "checkin_card_accepted")) return reject("locked");
        const next = this.acceptCheckinTarget(state, "card");
        const result = accept(next);
        this.emitChapterFourCue("morning_checkin_card_accepted", {
          complete: next.chapter4.phase === "exterior_closure"
        });
        if (next.chapter4.phase === "exterior_closure") {
          this.emitChapterFourCue("morning_checkin_completed", {
            timeState: "0755_morning",
            worldTimeSeconds: 28500,
            phoneStatusTimeSeconds: 28500,
            phoneStatusTimeTrusted: true,
            message: "外面亮了一下。"
          });
        }
        return result;
      }

      case "submit_attendance_paper": {
        if (chapter.phase !== "morning_checkin"
          || chapter.floor !== "A1"
          || chapter.roomId !== "a1_checkin"
          || chapter.guardMode !== "absent"
          || !state.chapterThreeInterlude.completed
          || state.chapterThreeInterlude.phase !== "complete"
          || !hasFact(chapter, "final_minute_installed")
          || !hasFact(chapter, "a3_identity_context_observed")
          || !hasFact(chapter, "attendance_record_recovered")
          || !state.items.attendanceRecordPaper
          || chapter.checkinPaperAccepted
          || hasFact(chapter, "checkin_paper_accepted")) return reject("locked");
        const next = this.acceptCheckinTarget(state, "paper");
        const result = accept(next);
        this.emitChapterFourCue("morning_checkin_paper_accepted", {
          complete: next.chapter4.phase === "exterior_closure"
        });
        if (next.chapter4.phase === "exterior_closure") {
          this.emitChapterFourCue("morning_checkin_completed", {
            timeState: "0755_morning",
            worldTimeSeconds: 28500,
            phoneStatusTimeSeconds: 28500,
            phoneStatusTimeTrusted: true,
            message: "外面亮了一下。"
          });
        }
        return result;
      }

      case "acknowledge_exterior_closure": {
        if (chapter.exteriorClosureAcknowledged || hasFact(chapter, "exterior_closure_acknowledged")) {
          return reject("already_complete");
        }
        if (chapter.phase !== "exterior_closure"
          || chapter.floor !== "A1"
          || chapter.roomId !== "a1_exterior"
          || chapter.guardMode !== "absent"
          || !chapter.checkinCardAccepted
          || !chapter.checkinPaperAccepted
          || !hasFact(chapter, "checkin_card_accepted")
          || !hasFact(chapter, "checkin_paper_accepted")
          || !hasFact(chapter, "checkin_identity_verified")
          || !hasFact(chapter, "zhu_two_questions_answered")
          || !hasFact(chapter, "final_minute_installed")
          || !chapter.lightGrid.locked
          || chapter.timeState !== "0755_morning"
          || chapter.worldTimeSeconds !== 28500
          || chapter.phoneStatusTimeSeconds !== 28500
          || !chapter.phoneStatusTimeTrusted) {
          return reject("locked");
        }
        const reference = this.closureSessionVerifier.reference;
        if (!reference
          || !closureProofMatchesReference(intent.proof, reference)
          || !this.closureSessionVerifier.verifyCompletedSession(intent.proof)) {
          return reject("locked", "closure_session_unverified");
        }
        const completedState = this.transition(state, "complete", {
          factIds: appendFact(chapter, "exterior_closure_acknowledged"),
          exteriorClosureAcknowledged: true,
          completed: true,
          chaseRestartCheckpoint: null
        });
        return accept({
          ...completedState,
          runtimeMode: "phone",
          currentScene: "phone_home",
          ui: {
            ...completedState.ui,
            controlCenterOpen: false,
            inventoryOpen: false,
            selectedItem: null
          }
        });
      }
    }
  }

  /**
   * Applies the phase, time authority, time state, both displayed clocks,
   * trust bit and guard mode as one GameStore transaction. Spatial location and
   * checkpoint remain unchanged unless the caller explicitly supplies a
   * transport, recovery or authored-cutscene override.
   */
  private transition(
    state: GameState,
    phase: ChapterFourPhase,
    overrides: PhaseTransitionOverrides = {}
  ): GameState {
    const phaseContract = requirePhaseContract(phase);
    const time = requireTimeContract(phaseContract.timeState);
    const {
      items = state.items,
      floor = state.chapter4.floor,
      roomId = state.chapter4.roomId,
      checkpoint = state.rpgCheckpoint,
      ...chapterOverrides
    } = overrides;
    return {
      ...state,
      runtimeMode: "rpg",
      rpgScene: "duan_yongping_temporal_maze",
      rpgCheckpoint: checkpoint,
      items,
      chapter4: {
        ...state.chapter4,
        phase,
        building: "A",
        floor,
        roomId,
        timeAuthority: phaseContract.timeAuthority,
        timeState: phaseContract.timeState,
        worldTimeSeconds: time.worldTimeSeconds,
        phoneStatusTimeSeconds: time.phoneStatusTimeSeconds,
        phoneStatusTimeTrusted: time.phoneStatusTimeTrusted,
        guardMode: phaseContract.guardMode,
        ...chapterOverrides
      }
    };
  }

  private patchChapter(
    state: GameState,
    patch: ChapterPatch,
    items: GameState["items"] = state.items
  ): GameState {
    return {
      ...state,
      items,
      chapter4: { ...state.chapter4, ...patch }
    };
  }

  private advancePhaseKeepingTime(
    state: GameState,
    phase: ChapterFourPhase,
    overrides: PhaseTransitionOverrides = {}
  ): GameState {
    const next = this.transition(state, phase, overrides);
    return {
      ...next,
      chapter4: {
        ...next.chapter4,
        timeAuthority: state.chapter4.timeAuthority,
        timeState: state.chapter4.timeState,
        worldTimeSeconds: state.chapter4.worldTimeSeconds,
        phoneStatusTimeSeconds: state.chapter4.phoneStatusTimeSeconds,
        phoneStatusTimeTrusted: state.chapter4.phoneStatusTimeTrusted,
        guardMode: state.chapter4.guardMode
      }
    };
  }

  private applyTimeState(
    state: GameState,
    phase: ChapterFourPhase,
    timeState: ChapterFourTimeState
  ): GameState {
    const time = chapterFourTimeContract(timeState);
    return {
      ...state,
      chapter4: {
        ...state.chapter4,
        timeAuthority: "hall_clock",
        timeState,
        worldTimeSeconds: time.worldTimeSeconds,
        phoneStatusTimeSeconds: time.phoneStatusTimeSeconds,
        phoneStatusTimeTrusted: time.phoneStatusTimeTrusted,
        guardMode: requirePhaseContract(phase).guardMode
      }
    };
  }

  private relocate(state: GameState, location: AllowedLocation): GameState {
    return {
      ...state,
      runtimeMode: "rpg",
      rpgScene: "duan_yongping_temporal_maze",
      rpgCheckpoint: location.checkpoint,
      chapter4: {
        ...state.chapter4,
        building: "A",
        floor: location.floor,
        roomId: location.roomId
      }
    };
  }

  private acceptCheckinTarget(state: GameState, target: "card" | "paper"): GameState {
    const chapter = activeChapterFour(state)!;
    const cardAccepted = target === "card" || chapter.checkinCardAccepted;
    const paperAccepted = target === "paper" || chapter.checkinPaperAccepted;
    const acceptedFactIds = target === "card"
      ? appendFact(chapter, "checkin_card_accepted")
      : appendFact(chapter, "checkin_paper_accepted");
    const factIds = cardAccepted
      && paperAccepted
      && acceptedFactIds.includes("a3_identity_context_observed")
      && acceptedFactIds.includes("attendance_record_recovered")
      ? appendFact({ ...chapter, factIds: acceptedFactIds }, "checkin_identity_verified")
      : acceptedFactIds;
    const patch = {
      factIds,
      checkinCardAccepted: cardAccepted,
      checkinPaperAccepted: paperAccepted
    };
    return cardAccepted && paperAccepted
      ? this.transition(state, "exterior_closure", {
          ...patch,
          floor: "A1",
          roomId: "a1_exterior",
          checkpoint: "c4_a1_lobby",
          exteriorClosureAcknowledged: false,
          completed: false
        })
      : this.patchChapter(state, patch);
  }

  private emitChapterFourCue(cue: string, payload: Record<string, unknown>): void {
    try {
      this.events.emit(cue, payload);
    } catch {
      // Presentation/audio consumers cannot block or roll back domain state.
    }
  }

  // The following signatures are a compile-only boundary for Task 6. They no
  // longer read or write legacy clueIds, solvedPuzzleIds, building time, phase,
  // calibration or B-building data.

  /** @deprecated Use resolve755Intent(). */
  verifyBackgroundActivity(_recordIds: readonly string[]): ChapterFourActionResult { return "locked"; }
  /** @deprecated Use resolve755Intent(). */
  restoreDesktopLayout(_appOrder: readonly string[]): ChapterFourActionResult { return "locked"; }
  /** @deprecated Use resolve755Intent(). */
  importCc98StudyIndex(_factIds: readonly string[]): ChapterFourActionResult { return "locked"; }
  /** @deprecated Use resolve755Intent(). */
  readWechatOfficialNotice(): ChapterFourActionResult { return "locked"; }
  /** @deprecated Use resolve755Intent(). */
  archiveWechatElevatorAudio(): ChapterFourActionResult { return "locked"; }
  /** @deprecated Use resolve755Intent(). */
  saveWechatStudentRoute(): ChapterFourActionResult { return "locked"; }
  /** @deprecated Use resolve755Intent(). */
  archiveWechatWayfindingPhotos(): ChapterFourActionResult { return "locked"; }
  /** @deprecated Use resolve755Intent(). */
  compareWechatWayfindingPhotos(): ChapterFourActionResult { return "locked"; }
  /** @deprecated Use resolve755Intent({ type: "set_mode", mode }). */
  setMode(_mode: ChapterFourRealityMode): ChapterFourActionResult { return "locked"; }
  /** @deprecated */ observeAirflow(): ChapterFourActionResult { return "locked"; }
  /** @deprecated */ guidePaperToElevator(): ChapterFourActionResult { return "locked"; }
  /** @deprecated */ observeElevatorHistory(): ChapterFourActionResult { return "locked"; }
  /** @deprecated */ startElevatorReplay(_startSeconds: number): ChapterFourActionResult { return "locked"; }
  /** @deprecated */ boardHistoricalElevator(): ChapterFourActionResult { return "locked"; }
  /** @deprecated */ markElevatorReplayMissed(): ChapterFourActionResult { return "locked"; }
  /** @deprecated */ completeElevatorRide(): ChapterFourActionResult { return "locked"; }
  /** @deprecated */ moveWithinMaze(_intent: ChapterFourMazeMoveIntent): ChapterFourActionResult { return "locked"; }
  /** @deprecated */ observeNpcSchedule(): ChapterFourActionResult { return "locked"; }
  /** @deprecated */ reconfigureCorridorBay(_id: ChapterFourCorridorPartitionId): ChapterFourActionResult { return "locked"; }
  /** @deprecated */ collectWayfindingFragment(_id: ChapterFourWayfindingFragmentId): ChapterFourActionResult { return "locked"; }
  /** @deprecated */ observeOldSignage(): ChapterFourActionResult { return "locked"; }
  /** @deprecated */ observeBridgeHistory(): ChapterFourActionResult { return "locked"; }
  /** @deprecated */ alignWayfindingBoard(_order: readonly string[]): ChapterFourActionResult { return "locked"; }
  /** @deprecated */ openSecondFloorReturnWindow(): ChapterFourActionResult { return "locked"; }
  /** @deprecated */ observeStairEcho(): ChapterFourActionResult { return "locked"; }
  /** @deprecated */ rotateStair(_direction: "left" | "right"): ChapterFourActionResult { return "locked"; }
  /** @deprecated */ traverseAlignedStair(): ChapterFourActionResult { return "locked"; }
}

export function isChapterFour755Intent(value: unknown): value is ChapterFour755Intent {
  if (!isRecord(value) || typeof value.type !== "string") return false;
  const targetIs = (targetId: string) => value.targetId === targetId;
  const targetIntentIs = (targetId: string, extraKeys: readonly string[] = []) => (
    targetIs(targetId)
    && isChapterFour755SpatialResult(value.spatial)
    && hasExactKeys(value, ["type", "targetId", "spatial", ...extraKeys])
  );
  switch (value.type) {
    case "complete_prologue_handoff":
    case "complete_opening_paper_flight":
    case "resolve_external_time_rejection":
    case "resolve_hall_clock_inspection":
    case "complete_bakery_conveyor_stop":
    case "complete_room204_projection":
    case "complete_minute_theft":
    case "observe_elevator_history":
    case "complete_misaligned_stair":
      return hasExactKeys(value, ["type"]);
    case "complete_inserted_puzzle":
      return hasExactKeys(value, ["type", "answer"])
        && isChapterFourInsertedPuzzleAnswer(value.answer);
    case "calibrate_elevator_history":
      return hasExactKeys(value, ["type", "startSeconds"])
        && isChapterFourElevatorStartSelectable(value.startSeconds as number);
    case "observe_elevator_floor_record":
      return hasExactKeys(value, ["type", "floor"])
        && isChapterFourElevatorRecordFloor(value.floor);
    case "reconstruct_elevator_stop_chain":
      return hasExactKeys(value, ["type", "actualArrivalFloor", "unservedCallFloor"])
        && isChapterFourElevatorDeductionFloor(value.actualArrivalFloor)
        && isChapterFourElevatorDeductionFloor(value.unservedCallFloor)
        && value.actualArrivalFloor !== value.unservedCallFloor;
    case "set_mode":
      return hasExactKeys(value, ["type", "mode"])
        && (value.mode === "light" || value.mode === "dark");
    case "move_to_location":
    case "record_checkpoint":
      return hasExactKeys(value, ["type", "floor", "roomId", "checkpoint"])
        && is755Floor(value.floor)
        && typeof value.roomId === "string"
        && value.roomId.length > 0
        && value.roomId.trim() === value.roomId
        && is755Checkpoint(value.checkpoint);
    case "traverse_main_stair":
      return hasExactKeys(value, ["type", "fromFloor", "toFloor", "expectedAttempt"])
        && (value.fromFloor === "A1" || value.fromFloor === "A2")
        && (value.toFloor === "A1" || value.toFloor === "A2")
        && value.fromFloor !== value.toFloor
        && isNonNegativeSafeInteger(value.expectedAttempt);
    case "catch_attendance_paper":
      return targetIntentIs(CHAPTER_FOUR_755_TARGET_IDS.attendancePaper);
    case "inspect_hall_clock":
    case "pull_hall_clock":
      return targetIntentIs(CHAPTER_FOUR_755_TARGET_IDS.hallClock);
    case "adjust_hall_clock_time":
      return typeof value.targetTimeState === "string"
        && TIME_CONTRACTS.some((contract) => contract.id === value.targetTimeState)
        && targetIntentIs(CHAPTER_FOUR_755_TARGET_IDS.hallClock, ["targetTimeState"]);
    case "collect_hour_hand":
      return targetIntentIs(CHAPTER_FOUR_755_TARGET_IDS.bakeryHourHandPickup);
    case "inspect_bakery_conveyor_lamp":
      return targetIntentIs(CHAPTER_FOUR_755_TARGET_IDS.bakeryInspectionLamp);
    case "inspect_bakery_conveyor_edge":
      return targetIntentIs(CHAPTER_FOUR_755_TARGET_IDS.bakeryConveyorEdge);
    case "install_hour_hand":
      return value.itemId === "oldClockHourHand"
        && targetIntentIs(CHAPTER_FOUR_755_TARGET_IDS.hourHandSocket, ["itemId"]);
    case "talk_to_a1_front_desk_attendant":
      return targetIntentIs(CHAPTER_FOUR_755_TARGET_IDS.frontDeskAttendant);
    case "talk_to_chapter_four_support_npc":
      return targetIntentIs(CHAPTER_FOUR_755_TARGET_IDS.a2ElevatorAttendant)
        || targetIntentIs(CHAPTER_FOUR_755_TARGET_IDS.a3ReferenceTeacher);
    case "inspect_chapter_four_context":
      return typeof value.targetId === "string"
        && isChapterFourContextInteractionTargetId(value.targetId)
        && targetIntentIs(value.targetId);
    case "inspect_alumni_figure":
      return targetIntentIs(CHAPTER_FOUR_755_TARGET_IDS.alumniSuBuqing)
        || targetIntentIs(CHAPTER_FOUR_755_TARGET_IDS.alumniZhuKezhen)
        || targetIntentIs(CHAPTER_FOUR_755_TARGET_IDS.alumniLuYongxiang)
        || targetIntentIs(CHAPTER_FOUR_755_TARGET_IDS.alumniChenJiangong)
        || targetIntentIs(CHAPTER_FOUR_755_TARGET_IDS.alumniTanJiazhen)
        || targetIntentIs(CHAPTER_FOUR_755_TARGET_IDS.alumniChengKaijia);
    case "complete_zhu_two_questions":
      return hasExactKeys(value, ["type", "purposeAnswer", "personAnswer"])
        && typeof value.purposeAnswer === "string"
        && ZHU_PURPOSE_ANSWER_IDS.has(value.purposeAnswer as ChapterFourZhuPurposeAnswerId)
        && typeof value.personAnswer === "string"
        && ZHU_PERSON_ANSWER_IDS.has(value.personAnswer as ChapterFourZhuPersonAnswerId);
    case "observe_classroom_104_chalk_residual":
      return targetIntentIs(CHAPTER_FOUR_755_TARGET_IDS.classroom104BlackboardResidual);
    case "check_classroom_105_terminal_replay":
      return targetIntentIs(CHAPTER_FOUR_755_TARGET_IDS.classroom105LecternTerminal);
    case "observe_a3_reference":
      return targetIntentIs(CHAPTER_FOUR_755_TARGET_IDS.a3Reference);
    case "observe_room204_residual":
      return targetIntentIs(CHAPTER_FOUR_755_TARGET_IDS.room204Residual);
    case "place_room204_group":
      return hasExactKeys(value, ["type", "groupId", "targetId", "spatial"])
        && isChapterFour755SpatialResult(value.spatial)
        && typeof value.groupId === "string"
        && ROOM204_GROUPS.has(value.groupId as ChapterFourRoom204GroupId)
        && value.targetId === room204GroupTargetId(value.groupId as ChapterFourRoom204GroupId);
    case "place_room204_piece":
      return hasExactKeys(value, ["type", "pieceId", "slotId", "orientation", "targetId", "spatial"])
        && isChapterFour755SpatialResult(value.spatial)
        && typeof value.pieceId === "string"
        && ROOM204_PIECES.has(value.pieceId as ChapterFourRoom204PieceId)
        && typeof value.slotId === "string"
        && ROOM204_SLOTS.has(value.slotId as ChapterFourRoom204SlotId)
        && typeof value.orientation === "string"
        && ROOM204_ORIENTATIONS.has(value.orientation as ChapterFourRoom204Orientation)
        && value.targetId === room204SlotTargetId(value.slotId as ChapterFourRoom204SlotId);
    case "collect_positioning_plate":
      return targetIntentIs(CHAPTER_FOUR_755_TARGET_IDS.positioningPlatePickup);
    case "install_positioning_plate":
      return value.itemId === "clockPositioningPlate"
        && targetIntentIs(CHAPTER_FOUR_755_TARGET_IDS.positioningPlateSocket, ["itemId"]);
    case "inspect_cart_wheel":
      return targetIntentIs(CHAPTER_FOUR_755_TARGET_IDS.cartWheelInspection);
    case "complete_maintenance_diagnosis": {
      if (!hasExactKeys(value, ["type", "answers"]) || !isRecord(value.answers)) return false;
      if (!hasExactKeys(value.answers, ["wheel_sound", "clock_jam", "oil_trace"])) return false;
      const validCauses = new Set<ChapterFourMaintenanceCauseId>([
        "latch", "oil_shortage", "gear_offset", "power_loss", "foreign_object"
      ]);
      return Object.values(value.answers).every((cause) => (
        typeof cause === "string" && validCauses.has(cause as ChapterFourMaintenanceCauseId)
      ));
    }
    case "collect_short_pry_bar":
      return targetIntentIs(CHAPTER_FOUR_755_TARGET_IDS.pryBarPickup);
    case "open_cart_wheel_cover":
      return value.itemId === "shortPryBar"
        && targetIntentIs(CHAPTER_FOUR_755_TARGET_IDS.cartWheelCover, ["itemId"]);
    case "collect_lubricating_oil":
      return targetIntentIs(CHAPTER_FOUR_755_TARGET_IDS.oilPickup);
    case "lubricate_cart_wheel":
      return value.itemId === "universalLubricatingOil"
        && targetIntentIs(CHAPTER_FOUR_755_TARGET_IDS.cartWheel, ["itemId"]);
    case "lubricate_clock_gear":
      return value.itemId === "universalLubricatingOil"
        && targetIntentIs(CHAPTER_FOUR_755_TARGET_IDS.clockGear, ["itemId"]);
    case "trigger_minute_theft":
    case "begin_final_clock_drag":
      return targetIntentIs(CHAPTER_FOUR_755_TARGET_IDS.minuteEndpoint);
    case "install_final_minute":
      return value.itemId === "finalMinute"
        && targetIntentIs(CHAPTER_FOUR_755_TARGET_IDS.minuteEndpoint, ["itemId"]);
    case "toggle_light_zone":
      return typeof value.zoneId === "string"
        && LIGHT_ZONE_IDS.has(value.zoneId as ChapterFourLightZoneId)
        && targetIntentIs(CHAPTER_FOUR_755_TARGET_IDS.powerPanel, ["zoneId"]);
    case "lock_light_grid":
    case "open_power_panel":
      return targetIntentIs(CHAPTER_FOUR_755_TARGET_IDS.powerPanel);
    case "reach_202_threshold":
      return isNonNegativeSafeInteger(value.expectedAttempt)
        && targetIntentIs(CHAPTER_FOUR_755_TARGET_IDS.lecture202Threshold, ["expectedAttempt"]);
    case "fail_chase":
      return hasExactKeys(value, ["type", "expectedAttempt", "failureFloor"])
        && isNonNegativeSafeInteger(value.expectedAttempt)
        && (value.failureFloor === "A1" || value.failureFloor === "A2");
    case "recover_from_maintenance_patrol":
      return hasExactKeys(value, ["type"]);
    case "acknowledge_exterior_closure":
      return hasExactKeys(value, ["type", "proof"])
        && isChapterFourClosureSessionProof(value.proof);
    case "collect_final_minute":
      return targetIntentIs(CHAPTER_FOUR_755_TARGET_IDS.finalMinuteProjection);
    case "read_campus_card":
      return value.itemId === "campusCard"
        && targetIntentIs(CHAPTER_FOUR_755_TARGET_IDS.campusCardReader, ["itemId"]);
    case "submit_attendance_paper":
      return value.itemId === "attendanceRecordPaper"
        && targetIntentIs(CHAPTER_FOUR_755_TARGET_IDS.attendancePaperSlot, ["itemId"]);
    default:
      return false;
  }
}

export function validateChapterFour755IntentRequest(
  value: unknown
): ChapterFour755IntentRequestValidation {
  if (!isRecord(value)) {
    return { valid: false, reason: "invalid_request", requestId: "" };
  }
  const requestId = typeof value.requestId === "string" ? value.requestId : "";
  const hasRuntimeTarget = Object.prototype.hasOwnProperty.call(value, "runtimeTarget");
  if (!hasExactKeys(value, hasRuntimeTarget
    ? ["requestId", "intent", "runtimeTarget"]
    : ["requestId", "intent"])) {
    return { valid: false, reason: "invalid_request", requestId };
  }
  if (!requestId || requestId !== requestId.trim()) {
    return { valid: false, reason: "invalid_request", requestId };
  }
  if (!isChapterFour755Intent(value.intent)) {
    return { valid: false, reason: "invalid_intent", requestId };
  }
  if (hasRuntimeTarget
    && !isChapterFour755RuntimeTargetContext(value.runtimeTarget, value.intent)) {
    return { valid: false, reason: "invalid_intent", requestId };
  }
  return {
    valid: true,
    request: {
      requestId,
      intent: value.intent,
      ...(hasRuntimeTarget
        ? { runtimeTarget: value.runtimeTarget as ChapterFour755RuntimeTargetContext }
        : {})
    }
  };
}

function isChapterFour755RuntimeTargetContext(
  value: unknown,
  intent: ChapterFour755Intent
): value is ChapterFour755RuntimeTargetContext {
  if (!isChapterFour755TargetIntent(intent)
    || !isRecord(value)
    || !hasExactKeys(value, ["targetId", "entityId", "bounds"])
    || typeof value.targetId !== "string"
    || value.targetId !== intent.targetId
    || typeof value.entityId !== "string"
    || !isRecord(value.bounds)
    || !hasExactKeys(value.bounds, ["x", "y", "width", "height"])
    || typeof value.bounds.x !== "number"
    || typeof value.bounds.y !== "number"
    || typeof value.bounds.width !== "number"
    || typeof value.bounds.height !== "number") {
    return false;
  }
  const target = getChapterFour755TargetContract(value.targetId);
  if (!target || target.boundsSource.kind !== "runtime_entity") return false;
  return resolveChapterFour755RuntimeEntityTarget(
    target.id,
    value.entityId,
    value.bounds as unknown as RpgHalfOpenWorldRect
  ) !== null;
}

function activeChapterFour(state: GameState): ChapterFourState | null {
  const chapter = state.chapter4;
  if (typeof chapter.phase !== "string" || !ACTIVE_PHASES.has(chapter.phase as ChapterFourPhase)) {
    return null;
  }
  if (chapter.building !== "A" || !["A1", "A2", "A3"].includes(chapter.floor)) return null;
  return chapter as ChapterFourState;
}

function requirePhaseContract(phase: ChapterFourPhase): PhaseContract {
  const contract = PHASE_CONTRACTS.find((candidate) => candidate.id === phase);
  if (!contract) throw new Error(`Missing Chapter 4 phase contract: ${phase}`);
  return contract;
}

function requireTimeContract(timeState: ChapterFourTimeState): TimeContract {
  const contract = TIME_CONTRACTS.find((candidate) => candidate.id === timeState);
  if (!contract) throw new Error(`Missing Chapter 4 time contract: ${timeState}`);
  return contract;
}

function hasFact(chapter: ChapterFourState, factId: ChapterFourFactId): boolean {
  return chapter.factIds.includes(factId);
}

function appendFact(chapter: ChapterFourState, factId: ChapterFourFactId): ChapterFourFactId[] {
  return hasFact(chapter, factId) ? [...chapter.factIds] : [...chapter.factIds, factId];
}

function appendFacts(
  chapter: Pick<ChapterFourState, "factIds">,
  factIds: readonly ChapterFourFactId[]
): ChapterFourFactId[] {
  const next = [...chapter.factIds];
  for (const factId of factIds) {
    if (!next.includes(factId)) next.push(factId);
  }
  return next;
}

function finalizeChapterFourCausalFacts(
  factIds: readonly ChapterFourFactId[]
): ChapterFourFactId[] {
  const next = new Set(factIds);
  if ([
    "classroom_104_chalk_residual_observed",
    "classroom_105_terminal_replay_checked",
    "elevator_history_observed",
    "elevator_history_calibrated"
  ].every((factId) => next.has(factId as ChapterFourFactId))) {
    next.add("a1_time_route_compared");
  }
  if ([
    "room204_restored",
    "room204_projection_completed",
    "a1_time_route_compared",
    "a3_reference_observed",
    "a3_identity_context_observed",
    "room204_residual_observed"
  ].every((factId) => next.has(factId as ChapterFourFactId))) {
    next.add("room204_projection_composite_completed");
    next.add("room202_endpoint_inferred");
    next.add("maintenance_incident_linked");
  }
  if ([
    "light_grid_locked",
    "room204_projection_composite_completed",
    "room202_endpoint_inferred"
  ].every((factId) => next.has(factId as ChapterFourFactId))) {
    next.add("powered_route_confirmed");
  }
  return [...next];
}

function insertedPuzzleFloor(
  puzzleId: ChapterFourInsertedPuzzleId
): ChapterFour755FloorId {
  if (puzzleId === "duty_board") return "A1";
  if (puzzleId === "archive_index" || puzzleId === "media_alignment") return "A3";
  return "A2";
}

function insertedPuzzlePrerequisiteReady(
  chapter: ChapterFourState,
  puzzleId: ChapterFourInsertedPuzzleId
): boolean {
  return puzzleId !== "media_alignment" || hasFact(chapter, "a3_archive_film_retrieved");
}

function insertedPuzzleLockedDetail(
  chapter: ChapterFourState,
  puzzleId: ChapterFourInsertedPuzzleId
): ChapterFour755IntentDetailCode {
  if (puzzleId === "duty_board") return "duty_board_required";
  if (puzzleId === "archive_index") return "archive_film_required";
  if (puzzleId === "media_alignment") {
    return hasFact(chapter, "a3_archive_film_retrieved")
      ? "media_alignment_required"
      : "archive_film_required";
  }
  if (puzzleId === "positioning_calibration") return "positioning_calibration_required";
  if (puzzleId === "power_topology") return "power_topology_required";
  return "evacuation_route_required";
}

function finalizeRoom204Facts(
  factIds: readonly ChapterFourFactId[],
  placements: ChapterFourState["room204Placements"]
): ChapterFourFactId[] {
  const next = [...factIds];
  if (isRoom204PlacementSetComplete(placements)
    && next.includes("a3_reference_observed")
    && next.includes("room204_residual_observed")
    && !next.includes("room204_restored")) {
    next.push("room204_restored");
  }
  return next;
}

function withItem(state: GameState, itemId: InventoryItemId, owned: boolean): GameState["items"] {
  return { ...state.items, [itemId]: owned };
}

function withItemState(
  state: GameState,
  itemId: InventoryItemId,
  owned: boolean
): GameState {
  return { ...state, items: withItem(state, itemId, owned) };
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

function hasExactKeys(value: Record<string, unknown>, expectedKeys: readonly string[]): boolean {
  const actualKeys = Object.keys(value);
  return actualKeys.length === expectedKeys.length
    && expectedKeys.every((key) => Object.prototype.hasOwnProperty.call(value, key));
}

function isChapterFour755SpatialResult(value: unknown): value is ChapterFour755SpatialResult {
  return isRecord(value)
    && hasExactKeys(value, ["distance"])
    && (value.distance === "within_range" || value.distance === "too_far");
}

function isChapterFour755TargetIntent(
  intent: ChapterFour755Intent
): intent is Extract<ChapterFour755Intent, { targetId: string }> {
  return "targetId" in intent;
}

function isAllowedLocation(phase: ChapterFourPhase, location: AllowedLocation): boolean {
  return ALLOWED_LOCATIONS_BY_PHASE[phase].some((allowed) => (
    allowed.floor === location.floor
    && allowed.roomId === location.roomId
    && allowed.checkpoint === location.checkpoint
  ));
}

function is755Floor(value: unknown): value is ChapterFour755FloorId {
  return value === "A1" || value === "A2" || value === "A3";
}

function is755Checkpoint(value: unknown): value is RpgCheckpointId {
  return value === "c4_a1_lobby"
    || value === "c4_a1_main_elevator"
    || value === "c4_a2_corridor"
    || value === "c4_a2_room202"
    || value === "c4_a3_wayfinding";
}

function isNonNegativeSafeInteger(value: unknown): value is number {
  return typeof value === "number" && Number.isSafeInteger(value) && value >= 0;
}
