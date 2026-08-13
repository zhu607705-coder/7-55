import type { GameState, RpgCheckpointId } from "../core/types";
import content from "../data/chapter4-temporal-maze.content.json";

export type ChapterFourMazeRouteState =
  | "baseline"
  | "schedule_observed"
  | "corridor_reconfigured"
  | "wayfinding_aligned"
  | "return_window";

export interface ChapterFourMazeProjection {
  routeState: ChapterFourMazeRouteState;
  visibleNpcIds: string[];
  residualNpcIds: string[];
  activeDoorIds: string[];
  activePartitionIds: string[];
  activeCollisionIds: string[];
  activeTargetIds: string[];
  safeCheckpoint: RpgCheckpointId;
}

export const CHAPTER_FOUR_MAZE_IDS = {
  partitions: ["a2_partition_west", "a2_partition_east"],
  returnDoor: "a2_room_203_return_door",
  scheduleTarget: "a2_schedule_observation",
  fragments: ["a2_fragment_west", "a2_fragment_east"],
  oldSignageTarget: "a3_old_signage",
  wayfindingBoardTarget: "a3_wayfinding_board",
  bridgeHistoryTarget: "a3_bridge_history",
  returnWindowTarget: "a2_return_window"
} as const;

export const CHAPTER_FOUR_MAZE_CLUES = {
  scheduleObserved: "a2_npc_schedule_observed",
  partitionWestReconfigured: "a2_partition_west_reconfigured",
  partitionEastReconfigured: "a2_partition_east_reconfigured",
  fragmentWestCollected: "a2_fragment_west_collected",
  fragmentEastCollected: "a2_fragment_east_collected",
  oldSignageObserved: "a3_old_signage_observed",
  bridgeHistoryObserved: "a3_bridge_history_observed",
  wayfindingAligned: "a3_wayfinding_aligned",
  secondFloorReturnWindowOpen: "a2_return_window_open"
} as const;

export const CHAPTER_FOUR_MAZE_TIMES = Object.freeze({
  thirdFloorHistorySeconds: content.threeFloorMaze.wayfinding.historyStartsAtSeconds,
  secondFloorReturnSeconds: content.threeFloorMaze.returnWindow.opensAtSeconds
});

export const CHAPTER_FOUR_WAYFINDING_ORDER = Object.freeze([
  ...content.threeFloorMaze.wayfinding.correctOrder
]);

const A2_VISIBLE_NPCS = [
  "a2_discussion_group",
  "a2_headphone_student",
  "a2_clearance_staff",
  "a2_security_patrol",
  "a2_upper_corridor_student",
  "a2_returning_student",
  "a2_study_student_201_west",
  "a2_study_student_201_east",
  "a2_study_student_204_west",
  "a2_study_student_204_east"
] as const;

const A2_RESIDUAL_NPCS = [
  "a2_discussion_group_residual",
  "a2_headphone_student_residual",
  "a2_clearance_staff_residual",
  "a2_security_patrol_residual",
  "a2_upper_corridor_student_residual",
  "a2_returning_student_residual",
  "a2_study_student_201_west_residual",
  "a2_study_student_201_east_residual",
  "a2_study_student_204_west_residual",
  "a2_study_student_204_east_residual"
] as const;

const PHASE_RANK: Readonly<Partial<Record<GameState["chapter4"]["phase"], number>>> = {
  npc_schedule_route: 1,
  corridor_bay_reconstruction: 2,
  wayfinding_fragment_board: 3,
  bridge_floor_discrimination: 4,
  stair_echo_direction: 5,
  multicam_video_edit: 6,
  echo_action_record: 7,
  dual_lift_logistics: 8,
  warm_air_balance: 9,
  first_cycle_reset: 10,
  route_schedule: 11,
  clock_phase_lock: 12,
  complete: 13
};

/**
 * Derives the complete three-floor route presentation from persisted Chapter 4
 * facts. The returned arrays are new values, so renderers cannot mutate save
 * state through a projection reference.
 */
export function selectChapterFourMazeProjection(
  state: GameState["chapter4"]
): ChapterFourMazeProjection {
  const clues = new Set(state.clueIds);
  const solved = new Set(state.solvedPuzzleIds);
  const phaseRank = PHASE_RANK[state.phase] ?? 0;

  const scheduleObserved = clues.has(CHAPTER_FOUR_MAZE_CLUES.scheduleObserved)
    || solved.has("npc_schedule_route")
    || phaseRank >= PHASE_RANK.corridor_bay_reconstruction!;
  const westPartitionReconfigured = clues.has(CHAPTER_FOUR_MAZE_CLUES.partitionWestReconfigured)
    || solved.has("corridor_bay_reconstruction")
    || phaseRank >= PHASE_RANK.wayfinding_fragment_board!;
  const eastPartitionReconfigured = clues.has(CHAPTER_FOUR_MAZE_CLUES.partitionEastReconfigured)
    || solved.has("corridor_bay_reconstruction")
    || phaseRank >= PHASE_RANK.wayfinding_fragment_board!;
  const corridorReconfigured = westPartitionReconfigured && eastPartitionReconfigured;
  const wayfindingAligned = clues.has(CHAPTER_FOUR_MAZE_CLUES.wayfindingAligned)
    || solved.has("wayfinding_fragment_board")
    || phaseRank >= PHASE_RANK.bridge_floor_discrimination!;
  const returnDoorOpen = clues.has(CHAPTER_FOUR_MAZE_CLUES.secondFloorReturnWindowOpen)
    || solved.has("bridge_floor_discrimination")
    || phaseRank >= PHASE_RANK.stair_echo_direction!;
  const returnWindowAvailable = returnDoorOpen
    || (
      wayfindingAligned
      && state.buildingTimeSeconds >= CHAPTER_FOUR_MAZE_TIMES.secondFloorReturnSeconds
      && (state.floor === "A2" || state.cycle === 2)
    );

  const routeState: ChapterFourMazeRouteState = returnWindowAvailable
    ? "return_window"
    : wayfindingAligned
      ? "wayfinding_aligned"
      : corridorReconfigured
        ? "corridor_reconfigured"
        : scheduleObserved
          ? "schedule_observed"
          : "baseline";

  const onSecondFloor = state.floor === "A2";
  const onThirdFloor = state.floor === "A3";
  const activeDoorIds = onSecondFloor ? [CHAPTER_FOUR_MAZE_IDS.returnDoor] : [];
  const activePartitionIds = onSecondFloor ? [...CHAPTER_FOUR_MAZE_IDS.partitions] : [];
  const activeCollisionIds = onSecondFloor
    ? [
        ...(!westPartitionReconfigured ? [CHAPTER_FOUR_MAZE_IDS.partitions[0]] : []),
        ...(!eastPartitionReconfigured ? [CHAPTER_FOUR_MAZE_IDS.partitions[1]] : []),
        ...(!returnDoorOpen ? [CHAPTER_FOUR_MAZE_IDS.returnDoor] : [])
      ]
    : [];

  const visibleNpcIds = onSecondFloor && !returnWindowAvailable
    ? [...A2_VISIBLE_NPCS]
    : [];
  const residualNpcIds = onSecondFloor && state.mode === "dark"
    ? [...A2_RESIDUAL_NPCS]
    : [];

  return {
    routeState,
    visibleNpcIds,
    residualNpcIds,
    activeDoorIds,
    activePartitionIds,
    activeCollisionIds,
    activeTargetIds: selectActiveTargets({
      state,
      clues,
      solved,
      routeState,
      onSecondFloor,
      onThirdFloor
    }),
    safeCheckpoint: selectSafeCheckpoint(state)
  };
}

interface ActiveTargetContext {
  state: GameState["chapter4"];
  clues: ReadonlySet<string>;
  solved: ReadonlySet<GameState["chapter4"]["solvedPuzzleIds"][number]>;
  routeState: ChapterFourMazeRouteState;
  onSecondFloor: boolean;
  onThirdFloor: boolean;
}

function selectActiveTargets({
  state,
  clues,
  solved,
  routeState,
  onSecondFloor,
  onThirdFloor
}: ActiveTargetContext): string[] {
  if (onSecondFloor) {
    if (routeState === "return_window") {
      return [CHAPTER_FOUR_MAZE_IDS.returnWindowTarget];
    }
    if (routeState === "wayfinding_aligned") {
      return [CHAPTER_FOUR_MAZE_IDS.returnWindowTarget];
    }
    if (routeState === "baseline" && state.phase === "npc_schedule_route") {
      return [CHAPTER_FOUR_MAZE_IDS.scheduleTarget];
    }
    if (routeState === "corridor_reconfigured" && !solved.has("wayfinding_fragment_board")) {
      return CHAPTER_FOUR_MAZE_IDS.fragments.filter((fragmentId) => (
        fragmentId === "a2_fragment_west"
          ? !clues.has(CHAPTER_FOUR_MAZE_CLUES.fragmentWestCollected)
          : !clues.has(CHAPTER_FOUR_MAZE_CLUES.fragmentEastCollected)
      ));
    }
    return [];
  }

  if (!onThirdFloor) return [];
  if (
    state.phase === "wayfinding_fragment_board"
    && !clues.has(CHAPTER_FOUR_MAZE_CLUES.oldSignageObserved)
  ) {
    return [CHAPTER_FOUR_MAZE_IDS.oldSignageTarget];
  }
  if (state.phase === "wayfinding_fragment_board" && !solved.has("wayfinding_fragment_board")) {
    return [CHAPTER_FOUR_MAZE_IDS.wayfindingBoardTarget];
  }
  if (
    state.phase === "bridge_floor_discrimination"
    && solved.has("wayfinding_fragment_board")
    && !clues.has(CHAPTER_FOUR_MAZE_CLUES.bridgeHistoryObserved)
  ) {
    return [CHAPTER_FOUR_MAZE_IDS.bridgeHistoryTarget];
  }
  return [];
}

function selectSafeCheckpoint(state: GameState["chapter4"]): RpgCheckpointId {
  if (state.floor === "A1") {
    return state.roomId === "a1_main_elevator" ? "c4_a1_main_elevator" : "c4_a1_lobby";
  }
  if (state.floor === "A2") return "c4_a2_corridor";
  if (state.floor === "A3" || state.floor === "A4") return "c4_a3_wayfinding";
  if (state.floor === "B3") return "c4_b3_landing";
  return state.roomId === "b2_04" ? "c4_b2_final_room" : "c4_b2_activity";
}
