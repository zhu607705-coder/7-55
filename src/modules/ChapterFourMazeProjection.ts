import type {
  ChapterFourFactId,
  ChapterFourGuardMode,
  ChapterFourPhase,
  ChapterFourState,
  ChapterFourTimeState,
  GameState,
  RpgCheckpointId
} from "../core/types";
import content from "../data/chapter4-755.content.json";
import layout from "../data/chapter4-three-floor-maze.layout.json";
import {
  CHAPTER_FOUR_755_INTERACTION_TARGETS,
  isChapterFour755TargetProjectable,
  isChapterFour755TargetStateActive
} from "../scenes/rpg/RpgInteractionContract";

export type ChapterFour755DoorState = "open" | "closed" | "locked";

export interface ChapterFourMazeProjection {
  phase: ChapterFourPhase | null;
  timeState: ChapterFourTimeState | null;
  activePlateIds: string[];
  plateId: string | null;
  availableTargetIds: string[];
  dynamicCollisionIds: string[];
  occlusionIds: string[];
  npcIds: string[];
  guardMode: ChapterFourGuardMode;
  doorStates: Record<string, ChapterFour755DoorState>;
  safeCheckpoint: RpgCheckpointId;

  /** @deprecated Task 6 scene compatibility; it is not a progression authority. */
  routeState: ChapterFourMazeRouteState;
  /** @deprecated Task 6 scene compatibility. */
  visibleNpcIds: string[];
  /** @deprecated Task 6 scene compatibility. */
  residualNpcIds: string[];
  /** @deprecated Task 6 scene compatibility. */
  activeDoorIds: string[];
  /** @deprecated Task 6 scene compatibility. */
  activePartitionIds: string[];
  /** @deprecated Use dynamicCollisionIds. */
  activeCollisionIds: string[];
  /** @deprecated Use availableTargetIds. */
  activeTargetIds: string[];
}

/**
 * @deprecated Old three-floor route states are retained only so the Task 6
 * scene compiles. New projection results always return baseline.
 */
export type ChapterFourMazeRouteState =
  | "baseline"
  | "schedule_observed"
  | "corridor_reconfigured"
  | "wayfinding_aligned"
  | "return_window";

/** @deprecated Old Task 6 scene IDs. */
export const CHAPTER_FOUR_MAZE_IDS = Object.freeze({
  partitions: ["a2_partition_west", "a2_partition_east"] as const,
  returnDoor: "a2_room_203_return_door",
  scheduleTarget: "a2_schedule_observation",
  fragments: ["a2_fragment_west", "a2_fragment_east"] as const,
  oldSignageTarget: "a3_old_signage",
  wayfindingBoardTarget: "a3_wayfinding_board",
  bridgeHistoryTarget: "a3_bridge_history",
  returnWindowTarget: "a2_return_window"
});

/** @deprecated Old Task 6 scene facts. */
export const CHAPTER_FOUR_MAZE_CLUES = Object.freeze({
  scheduleObserved: "a2_npc_schedule_observed",
  partitionWestReconfigured: "a2_partition_west_reconfigured",
  partitionEastReconfigured: "a2_partition_east_reconfigured",
  fragmentWestCollected: "a2_fragment_west_collected",
  fragmentEastCollected: "a2_fragment_east_collected",
  oldSignageObserved: "a3_old_signage_observed",
  bridgeHistoryObserved: "a3_bridge_history_observed",
  wayfindingAligned: "a3_wayfinding_aligned",
  secondFloorReturnWindowOpen: "a2_return_window_open"
});

/** @deprecated Old DEV/Task 6 scene times. */
export const CHAPTER_FOUR_MAZE_TIMES = Object.freeze({
  thirdFloorHistorySeconds: 81900,
  secondFloorReturnSeconds: 81960
});

/** @deprecated Old Task 6 wayfinding game order. */
export const CHAPTER_FOUR_WAYFINDING_ORDER = Object.freeze([
  "a2_fragment_west",
  "empty",
  "a2_fragment_east"
] as const);

const ACTIVE_PHASES = new Set<ChapterFourPhase>(
  content.orderedPhases as readonly ChapterFourPhase[]
);

const PHASE_PLATES = new Map<ChapterFourPhase, readonly string[]>(
  content.phaseContracts.map((contract) => [
    contract.id as ChapterFourPhase,
    [...contract.floorPlateIds]
  ])
);

interface ChapterFour755LayoutFloor {
  storyFloor: ChapterFourState["floor"];
  foregroundOcclusions: Array<{ id: string }>;
}

const LAYOUT_FLOORS = layout.floors as ChapterFour755LayoutFloor[];

/**
 * Stable structural plates used when a time-state contract intentionally has
 * no opaque full-frame plate for the player's current floor. The Task 3 asset
 * manifest must keep these IDs so cross-floor travel never selects another
 * floor's time-state plate or leaves an active A1/A2/A3 projection blank.
 */
export const CHAPTER_FOUR_755_BASE_PLATE_IDS = Object.freeze({
  A1: "a1_base",
  A2: "a2_base",
  A3: "a3_base"
} satisfies Readonly<Record<ChapterFourState["floor"], string>>);

/**
 * Pure read model for the 07:55 Chapter 4 path. It derives every visible plate,
 * interaction, collision, occlusion, NPC, guard and door state from active
 * ChapterFourState fields. Pending targets without defensible world-space
 * bounds are intentionally withheld until Tasks 8/10/13 calibrate their
 * visible sprites.
 */
export function selectChapterFourMazeProjection(gameState: GameState): ChapterFourMazeProjection {
  const state = activeChapter(gameState.chapter4);
  if (!state) return inactiveProjection();

  const activePlateIds = [...(PHASE_PLATES.get(state.phase) ?? [])];
  const plateId = selectCurrentPlate(activePlateIds, state.floor);
  const factIds = new Set(state.factIds);
  const availableTargetIds = Object.values(CHAPTER_FOUR_755_INTERACTION_TARGETS)
    .filter((target) => isChapterFour755TargetStateActive(gameState, target))
    .filter((target) => isChapterFour755TargetProjectable(target, state.phase))
    .map((target) => target.id);
  const dynamicCollisionIds = selectDynamicCollisions(state);
  const occlusionIds = selectOcclusions(state, plateId);
  const npcIds = selectNpcs(state);
  const doorStates = selectDoorStates(state, factIds);
  const activeDoorIds = Object.entries(doorStates)
    .filter(([, doorState]) => doorState !== "open")
    .map(([doorId]) => doorId);
  const safeCheckpoint = selectSafeCheckpoint(state, gameState.rpgCheckpoint);

  return {
    phase: state.phase,
    timeState: state.timeState,
    activePlateIds,
    plateId,
    availableTargetIds,
    dynamicCollisionIds,
    occlusionIds,
    npcIds,
    guardMode: state.guardMode,
    doorStates,
    safeCheckpoint,
    routeState: "baseline",
    visibleNpcIds: [...npcIds],
    residualNpcIds: state.mode === "dark"
      ? npcIds.map((npcId) => `${npcId}_residual`)
      : [],
    activeDoorIds,
    activePartitionIds: [],
    activeCollisionIds: [...dynamicCollisionIds],
    activeTargetIds: [...availableTargetIds]
  };
}

function inactiveProjection(): ChapterFourMazeProjection {
  return {
    phase: null,
    timeState: null,
    activePlateIds: [],
    plateId: null,
    availableTargetIds: [],
    dynamicCollisionIds: [],
    occlusionIds: [],
    npcIds: [],
    guardMode: "absent",
    doorStates: {},
    safeCheckpoint: "c4_a1_lobby",
    routeState: "baseline",
    visibleNpcIds: [],
    residualNpcIds: [],
    activeDoorIds: [],
    activePartitionIds: [],
    activeCollisionIds: [],
    activeTargetIds: []
  };
}

function activeChapter(value: GameState["chapter4"]): ChapterFourState | null {
  if (typeof value.phase !== "string" || !ACTIVE_PHASES.has(value.phase as ChapterFourPhase)) {
    return null;
  }
  if (value.building !== "A" || !["A1", "A2", "A3"].includes(value.floor)) return null;
  return value as ChapterFourState;
}

function selectCurrentPlate(plateIds: readonly string[], floor: ChapterFourState["floor"]): string | null {
  const prefix = `${floor.toLowerCase()}_`;
  return plateIds.find((plateId) => plateId.startsWith(prefix))
    ?? CHAPTER_FOUR_755_BASE_PLATE_IDS[floor];
}

function selectDynamicCollisions(
  state: ChapterFourState
): string[] {
  const collisionIds: string[] = [];
  if (state.phase === "room204_restore" && state.floor === "A2") {
    collisionIds.push("a2_room204_disordered_furniture");
  }
  if (state.guardMode === "chase") {
    collisionIds.push(state.floor === "A2" ? "a2_guard_chase_body" : "a1_guard_chase_body");
  }
  if (state.floor === "A2" && state.phase === "final_minute_recovery") {
    collisionIds.push("a2_room202_recovery_barrier");
  }
  return collisionIds;
}

function selectOcclusions(
  state: ChapterFourState,
  plateId: string | null
): string[] {
  if (!plateId) return [];
  const floor = LAYOUT_FLOORS.find((candidate) => candidate.storyFloor === state.floor);
  return floor?.foregroundOcclusions.map((entry) => entry.id) ?? [];
}

function selectNpcs(state: ChapterFourState): string[] {
  switch (state.phase) {
    case "bakery_hour_hand":
      return state.floor === "A1" ? ["a1_bakery_clerk", "a1_bakery_lunch_crowd"] : [];
    case "room204_restore":
      return state.floor === "A3"
        ? ["a3_reference_students"]
        : state.floor === "A2" && state.mode === "dark"
          ? ["a2_evening_residual_group"]
          : [];
    case "maintenance_repair":
      return state.floor === "A1" ? ["a1_cleaner", "a1_security_guard"] : [];
    case "final_chase":
      return [state.floor === "A2" ? "a2_security_guard" : "a1_security_guard"];
    case "morning_checkin":
      return state.floor === "A1" ? ["a1_morning_students"] : [];
    default:
      return [];
  }
}

function selectDoorStates(
  state: ChapterFourState,
  facts: ReadonlySet<ChapterFourFactId>
): Record<string, ChapterFour755DoorState> {
  return {
    a1_bakery_back_door: state.phase === "bakery_hour_hand" || state.phase === "maintenance_repair"
      ? "open"
      : "closed",
    a2_room204_door: state.phase === "room204_restore" ? "open" : "closed",
    a2_room202_door: state.phase === "final_chase" || state.phase === "return_to_clock"
      ? "open"
      : facts.has("light_grid_locked")
        ? "closed"
        : "locked",
    a1_exterior_door: state.phase === "exterior_closure" || state.phase === "complete"
      ? "open"
      : "closed"
  };
}

function selectSafeCheckpoint(
  state: ChapterFourState,
  currentCheckpoint: RpgCheckpointId
): RpgCheckpointId {
  if (state.phase === "final_chase") return state.chaseRestartCheckpoint ?? "c4_a1_lobby";
  if (state.phase === "final_minute_recovery") return "c4_a2_room202";
  if (state.phase === "return_to_clock" && state.floor === "A2") {
    return state.roomId === "a2_room_202" ? "c4_a2_room202" : "c4_a2_corridor";
  }
  if (isCheckpointForFloor(currentCheckpoint, state.floor)) return currentCheckpoint;
  if (state.floor === "A3") return "c4_a3_wayfinding";
  if (state.floor === "A2") return "c4_a2_corridor";
  return "c4_a1_lobby";
}

function isCheckpointForFloor(
  checkpoint: RpgCheckpointId,
  floor: ChapterFourState["floor"]
): boolean {
  if (floor === "A3") return checkpoint === "c4_a3_wayfinding";
  if (floor === "A2") return checkpoint === "c4_a2_corridor" || checkpoint === "c4_a2_room202";
  return checkpoint === "c4_a1_lobby" || checkpoint === "c4_a1_main_elevator";
}
