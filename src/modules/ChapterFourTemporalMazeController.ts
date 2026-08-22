import type { EventBus } from "../core/EventBus";
import type {
  ChapterFour755FloorId,
  ChapterFourFactId,
  ChapterFourGuardMode,
  ChapterFourLightZoneId,
  ChapterFourPhase,
  ChapterFourRealityMode,
  ChapterFourRoom204Orientation,
  ChapterFourRoom204PieceId,
  ChapterFourRoom204SlotId,
  ChapterFourState,
  ChapterFourTimeAuthority,
  ChapterFourTimeState,
  GameState,
  GameStore,
  InventoryItemId,
  RpgCheckpointId
} from "../core/types";
import content from "../data/chapter4-755.content.json";
import {
  isRoom204PlacementSetComplete,
  resolveRoom204Placement,
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

export const CHAPTER_FOUR_755_TARGET_IDS = Object.freeze({
  attendancePaper: "a1_noticeboard_paper",
  hallClock: "a1_hall_clock",
  bakeryInspectionLamp: "a1_bakery_inspection_lamp",
  bakeryConveyorEdge: "a1_bakery_conveyor_edge",
  bakeryHourHandPickup: "a1_bakery_hour_hand_pickup",
  hourHandSocket: "a1_hall_clock_hour_hand_socket",
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
  | ChapterFour755TargetIntent<{ type: "catch_attendance_paper"; targetId: typeof CHAPTER_FOUR_755_TARGET_IDS.attendancePaper }>
  | ChapterFour755TargetIntent<{ type: "inspect_hall_clock"; targetId: typeof CHAPTER_FOUR_755_TARGET_IDS.hallClock }>
  | ChapterFour755TargetIntent<{ type: "pull_hall_clock"; targetId: typeof CHAPTER_FOUR_755_TARGET_IDS.hallClock }>
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
  | ChapterFour755TargetIntent<{ type: "observe_a3_reference"; targetId: typeof CHAPTER_FOUR_755_TARGET_IDS.a3Reference }>
  | ChapterFour755TargetIntent<{ type: "observe_room204_residual"; targetId: typeof CHAPTER_FOUR_755_TARGET_IDS.room204Residual }>
  | ChapterFour755TargetIntent<{
      type: "place_room204_piece";
      pieceId: ChapterFourRoom204PieceId;
      slotId: ChapterFourRoom204SlotId;
      orientation: ChapterFourRoom204Orientation;
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
  | { type: "fail_chase"; expectedAttempt: number }
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

export interface ChapterFour755IntentResult {
  accepted: boolean;
  changed: boolean;
  reason: ChapterFour755IntentResultReason;
  intentType: ChapterFour755Intent["type"];
  previousPhase: ChapterFourPhase | null;
  phase: ChapterFourPhase | null;
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
const ROOM204_ORIENTATIONS = new Set<ChapterFourRoom204Orientation>(["up"]);
const LIGHT_ZONE_IDS = new Set<ChapterFourLightZoneId>(LIGHT_GRID_ZONES.map((zone) => zone.id));

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
    const reject = (reason: Exclude<ChapterFour755IntentResultReason, "accepted">): ChapterFour755IntentResult => ({
      accepted: false,
      changed: false,
      reason,
      intentType: intent.type,
      previousPhase,
      phase: previousPhase
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
        phase: nextChapter?.phase ?? previousPhase
      };
    };
    const acceptReadOnly = (): ChapterFour755IntentResult => ({
      accepted: true,
      changed: false,
      reason: "accepted",
      intentType: intent.type,
      previousPhase,
      phase: previousPhase
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

      case "move_to_location":
      case "record_checkpoint": {
        if ((chapter.phase === "final_chase" || chapter.phase === "return_to_clock")
          && chapter.floor !== intent.floor) return reject("locked");
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
        const result = accept(this.transition(state, "bakery_hour_hand"));
        this.emitChapterFourCue("chapter4_time_swap_committed", {
          previousPhase,
          phase: "bakery_hour_hand",
          timeState: "1225_bakery"
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
          factIds: appendFact(chapter, "bakery_hour_hand_exposed")
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
        const result = accept(this.transition(state, "room204_restore", {
          factIds: appendFact(chapter, "hour_hand_installed"),
          items: withItem(state, "oldClockHourHand", false)
        }));
        this.emitChapterFourCue("chapter4_time_swap_committed", {
          previousPhase,
          phase: "room204_restore",
          timeState: "1850_room204"
        });
        return result;
      }

      case "observe_a3_reference": {
        return accept(this.patchChapter(state, {
          factIds: appendFact(chapter, "a3_reference_observed")
        }));
      }

      case "observe_room204_residual": {
        return accept(this.patchChapter(state, {
          factIds: appendFact(chapter, "room204_residual_observed")
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
          return reject(resolution.issue === "already_placed" ? "already_complete" : "incorrect");
        }
        const restored = resolution.complete
          && hasFact(chapter, "a3_reference_observed")
          && hasFact(chapter, "room204_residual_observed");
        return accept(this.patchChapter(state, {
          room204Placements: resolution.placements,
          factIds: restored ? appendFact(chapter, "room204_restored") : chapter.factIds
        }));
      }

      case "complete_room204_projection": {
        if (chapter.phase !== "room204_restore"
          || !hasFact(chapter, "a3_reference_observed")
          || !hasFact(chapter, "room204_residual_observed")
          || !hasFact(chapter, "room204_restored")
          || !isRoom204PlacementSetComplete(chapter.room204Placements)) return reject("locked");
        if (hasFact(chapter, "room204_projection_completed")) return reject("already_complete");
        return accept(this.patchChapter(state, {
          factIds: appendFact(chapter, "room204_projection_completed")
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
        if (!hasFact(chapter, "room204_projection_completed")
          || !hasFact(chapter, "positioning_plate_collected")
          || !state.items.clockPositioningPlate
          || hasFact(chapter, "positioning_plate_installed")) return reject("locked");
        const result = accept(this.transition(state, "maintenance_repair", {
          factIds: appendFact(chapter, "positioning_plate_installed"),
          items: withItem(state, "clockPositioningPlate", false),
          floor: "A1",
          roomId: "a1_hall_clock",
          checkpoint: "c4_a1_lobby"
        }));
        this.emitChapterFourCue("chapter4_time_swap_committed", {
          previousPhase,
          phase: "maintenance_repair",
          timeState: "2245_maintenance"
        });
        return result;
      }

      case "inspect_cart_wheel": {
        if (chapter.phase !== "maintenance_repair"
          || chapter.guardMode !== "patrol"
          || hasFact(chapter, "cart_wheel_cover_opened")
          || hasFact(chapter, "cart_wheel_repaired")
          || hasFact(chapter, "clock_gear_repaired")) return reject("locked");
        if (hasFact(chapter, "cart_wheel_inspected")) return reject("already_complete");
        return accept(this.patchChapter(state, {
          factIds: appendFact(chapter, "cart_wheel_inspected")
        }));
      }

      case "collect_short_pry_bar": {
        if (chapter.phase !== "maintenance_repair"
          || hasFact(chapter, "cart_wheel_cover_opened")
          || state.items.shortPryBar) return reject("locked");
        return accept(this.patchChapter(state, {}, withItem(state, "shortPryBar", true)));
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
        if (chapter.phase !== "maintenance_repair"
          || !hasFact(chapter, "cart_wheel_cover_opened")
          || state.items.universalLubricatingOil
          || hasFact(chapter, "clock_gear_repaired")) return reject("locked");
        return accept(this.patchChapter(state, {}, withItem(state, "universalLubricatingOil", true)));
      }

      case "lubricate_cart_wheel": {
        if (chapter.phase !== "maintenance_repair"
          || !hasFact(chapter, "cart_wheel_cover_opened")
          || !state.items.universalLubricatingOil
          || hasFact(chapter, "cart_wheel_repaired")) return reject("locked");
        return accept(this.patchChapter(state, {
          factIds: appendFact(chapter, "cart_wheel_repaired")
        }));
      }

      case "lubricate_clock_gear": {
        if (chapter.phase !== "maintenance_repair"
          || !hasFact(chapter, "cart_wheel_repaired")
          || !state.items.universalLubricatingOil
          || hasFact(chapter, "clock_gear_repaired")) return reject("locked");
        const result = accept(this.patchChapter(state, {
          factIds: appendFact(chapter, "clock_gear_repaired"),
        }, withItem(state, "universalLubricatingOil", false)));
        this.emitChapterFourCue("clock_gear_repaired", {
          phase: chapter.phase,
          targetId: intent.targetId
        });
        return result;
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
        const result = accept(this.transition(state, "final_chase", {
          factIds: appendFact(chapter, "light_grid_locked"),
          lightGrid: { mask: CHAPTER_FOUR_LIGHT_GRID.targetMask, locked: true },
          chaseRestartCheckpoint: "c4_a1_lobby",
          floor: "A1",
          roomId: "a1_lobby",
          checkpoint: "c4_a1_lobby"
        }));
        this.emitChapterFourCue("power_grid_locked", {
          mask: CHAPTER_FOUR_LIGHT_GRID.targetMask,
          phase: "final_chase"
        });
        return result;
      }

      case "reach_202_threshold": {
        if (chapter.phase !== "final_chase"
          || intent.expectedAttempt !== chapter.chaseAttempt
          || chapter.floor !== "A2"
          || !hasFact(chapter, "light_grid_locked")) return reject("locked");
        return accept(this.transition(state, "final_minute_recovery", {
          floor: "A2",
          roomId: "a2_room_202",
          checkpoint: "c4_a2_room202"
        }));
      }

      case "fail_chase": {
        if (chapter.phase !== "final_chase"
          || intent.expectedAttempt !== chapter.chaseAttempt) return reject("locked");
        return accept(this.transition(state, "final_chase", {
          chaseAttempt: chapter.chaseAttempt + 1,
          chaseRestartCheckpoint: "c4_a1_lobby",
          floor: "A1",
          roomId: "a1_lobby",
          checkpoint: "c4_a1_lobby"
        }));
      }

      case "collect_final_minute": {
        if (chapter.phase !== "final_minute_recovery"
          || chapter.floor !== "A2"
          || chapter.roomId !== "a2_room_202"
          || !hasFact(chapter, "paper_temporarily_out_of_inventory")
          || hasFact(chapter, "final_minute_recovered")
          || state.items.finalMinute) return reject("locked");
        const items = withItem(withItemState(state, "finalMinute", true), "attendanceRecordPaper", true);
        return accept(this.transition(state, "return_to_clock", {
          factIds: appendFact(chapter, "final_minute_recovered"),
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
          return reject("locked");
        }
        return accept(this.transition(state, "complete", {
          factIds: appendFact(chapter, "exterior_closure_acknowledged"),
          exteriorClosureAcknowledged: true,
          completed: true,
          chaseRestartCheckpoint: null
        }));
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
    const factIds = target === "card"
      ? appendFact(chapter, "checkin_card_accepted")
      : appendFact(chapter, "checkin_paper_accepted");
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
      return hasExactKeys(value, ["type"]);
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
    case "collect_hour_hand":
      return targetIntentIs(CHAPTER_FOUR_755_TARGET_IDS.bakeryHourHandPickup);
    case "inspect_bakery_conveyor_lamp":
      return targetIntentIs(CHAPTER_FOUR_755_TARGET_IDS.bakeryInspectionLamp);
    case "inspect_bakery_conveyor_edge":
      return targetIntentIs(CHAPTER_FOUR_755_TARGET_IDS.bakeryConveyorEdge);
    case "install_hour_hand":
      return value.itemId === "oldClockHourHand"
        && targetIntentIs(CHAPTER_FOUR_755_TARGET_IDS.hourHandSocket, ["itemId"]);
    case "observe_a3_reference":
      return targetIntentIs(CHAPTER_FOUR_755_TARGET_IDS.a3Reference);
    case "observe_room204_residual":
      return targetIntentIs(CHAPTER_FOUR_755_TARGET_IDS.room204Residual);
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
      return hasExactKeys(value, ["type", "expectedAttempt"])
        && isNonNegativeSafeInteger(value.expectedAttempt);
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
