export const CHAPTER_FOUR_VISUAL_HINT_MAX_FAILURES = 4 as const;

export type ChapterFourVisualHintLevel = 0 | 1 | 2 | 3;

export type ChapterFourVisualHintPuzzleId =
  | "bakery_trace_comparison"
  | "elevator_timing_comparison"
  | "room204_window_group"
  | "room204_central_group"
  | "room204_podium_group"
  | "room204_door_group"
  | "maintenance_geometry_comparison"
  | "power_route_comparison"
  | "room202_record_comparison";

export interface ChapterFourVisualHintContract {
  id: ChapterFourVisualHintPuzzleId;
  detailIds: readonly string[];
  pairedDetailIds: readonly [string, string];
}

export interface ChapterFourVisualHintSession {
  puzzleId: ChapterFourVisualHintPuzzleId;
  failureCount: number;
  level: ChapterFourVisualHintLevel;
  emphasizedDetailIds: readonly string[];
  pairedDetailIds: readonly string[];
  visualEmphasis: boolean;
  positionalAudio: boolean;
  pairedEmphasis: boolean;
}

export interface ChapterFourVisualHintModel {
  sessions: Readonly<Partial<Record<ChapterFourVisualHintPuzzleId, ChapterFourVisualHintSession>>>;
}

const CONTRACTS = Object.freeze([
  {
    id: "bakery_trace_comparison",
    detailIds: [
      "bakery_wet_drag_east",
      "bakery_conveyor_reverse_wear",
      "bakery_pry_bar_outline"
    ],
    pairedDetailIds: ["bakery_wet_drag_east", "bakery_conveyor_reverse_wear"]
  },
  {
    id: "elevator_timing_comparison",
    detailIds: ["elevator_passenger_trace_6s", "elevator_door_interval_8s"],
    pairedDetailIds: ["elevator_passenger_trace_6s", "elevator_door_interval_8s"]
  },
  {
    id: "room204_window_group",
    detailIds: ["room204_window_time_marks", "classroom104_chalk_1844"],
    pairedDetailIds: ["room204_window_time_marks", "classroom104_chalk_1844"]
  },
  {
    id: "room204_central_group",
    detailIds: ["room204_central_drag_marks", "bakery_wet_drag_east"],
    pairedDetailIds: ["room204_central_drag_marks", "bakery_wet_drag_east"]
  },
  {
    id: "room204_podium_group",
    detailIds: ["room204_projection_edge", "a3_reference_desk_shadow"],
    pairedDetailIds: ["room204_projection_edge", "a3_reference_desk_shadow"]
  },
  {
    id: "room204_door_group",
    detailIds: ["room204_door_paper_trace", "elevator_passenger_trace_6s"],
    pairedDetailIds: ["room204_door_paper_trace", "elevator_passenger_trace_6s"]
  },
  {
    id: "maintenance_geometry_comparison",
    detailIds: [
      "bakery_pry_bar_outline",
      "cart_wheel_impact_scratch",
      "cart_cover_matching_notch",
      "hall_clock_oil_stain"
    ],
    pairedDetailIds: ["bakery_pry_bar_outline", "cart_cover_matching_notch"]
  },
  {
    id: "power_route_comparison",
    detailIds: [
      "room204_door_paper_trace",
      "power_hall_node",
      "power_east_corridor_node",
      "power_classroom_node"
    ],
    pairedDetailIds: ["room204_door_paper_trace", "power_classroom_node"]
  },
  {
    id: "room202_record_comparison",
    detailIds: ["room202_paper_torn_edge", "room202_minute_projection"],
    pairedDetailIds: ["room202_paper_torn_edge", "room202_minute_projection"]
  }
] as const satisfies readonly ChapterFourVisualHintContract[]);

export const CHAPTER_FOUR_VISUAL_HINT_CONTRACTS: readonly ChapterFourVisualHintContract[] =
  CONTRACTS;

const CONTRACT_BY_ID = new Map<ChapterFourVisualHintPuzzleId, ChapterFourVisualHintContract>(
  CONTRACTS.map((contract) => [contract.id, contract])
);

const ROOM204_TARGET_PUZZLES = Object.freeze({
  window_time_marks: "room204_window_group",
  central_drag_marks: "room204_central_group",
  podium_projection_edge: "room204_podium_group",
  door_paper_trace: "room204_door_group"
} as const satisfies Readonly<Record<string, ChapterFourVisualHintPuzzleId>>);

export function createChapterFourVisualHintModel(): ChapterFourVisualHintModel {
  return Object.freeze({ sessions: Object.freeze({}) });
}

export function chapterFourVisualHintLevelForFailureCount(
  failureCount: number
): ChapterFourVisualHintLevel {
  if (!Number.isFinite(failureCount) || failureCount <= 1) return 0;
  if (failureCount === 2) return 1;
  if (failureCount === 3) return 2;
  return 3;
}

export function recordChapterFourVisualHintFailure(
  model: ChapterFourVisualHintModel,
  puzzleId: ChapterFourVisualHintPuzzleId
): ChapterFourVisualHintModel {
  const contract = requireContract(puzzleId);
  const previous = model.sessions[puzzleId];
  const failureCount = Math.min(
    CHAPTER_FOUR_VISUAL_HINT_MAX_FAILURES,
    (previous?.failureCount ?? 0) + 1
  );
  const level = chapterFourVisualHintLevelForFailureCount(failureCount);
  const session: ChapterFourVisualHintSession = Object.freeze({
    puzzleId,
    failureCount,
    level,
    emphasizedDetailIds: level >= 1
      ? Object.freeze([...contract.detailIds])
      : Object.freeze([]),
    pairedDetailIds: level >= 3
      ? Object.freeze([...contract.pairedDetailIds])
      : Object.freeze([]),
    visualEmphasis: level >= 1,
    positionalAudio: level >= 2,
    pairedEmphasis: level >= 3
  });
  return Object.freeze({
    sessions: Object.freeze({ ...model.sessions, [puzzleId]: session })
  });
}

export function clearChapterFourVisualHintPuzzle(
  model: ChapterFourVisualHintModel,
  puzzleId: ChapterFourVisualHintPuzzleId
): ChapterFourVisualHintModel {
  if (!model.sessions[puzzleId]) return model;
  const sessions = { ...model.sessions };
  delete sessions[puzzleId];
  return Object.freeze({ sessions: Object.freeze(sessions) });
}

export function clearAllChapterFourVisualHints(): ChapterFourVisualHintModel {
  return createChapterFourVisualHintModel();
}

export function selectChapterFourVisualHintSession(
  model: ChapterFourVisualHintModel,
  puzzleId: ChapterFourVisualHintPuzzleId
): ChapterFourVisualHintSession | null {
  return model.sessions[puzzleId] ?? null;
}

export function selectChapterFourVisualHintForDetail(
  model: ChapterFourVisualHintModel,
  detailId: string
): {
  level: ChapterFourVisualHintLevel;
  emphasized: boolean;
  paired: boolean;
} {
  let level: ChapterFourVisualHintLevel = 0;
  let emphasized = false;
  let paired = false;
  for (const session of Object.values(model.sessions)) {
    if (!session) continue;
    if (session.emphasizedDetailIds.includes(detailId)) {
      emphasized = true;
      level = Math.max(level, session.level) as ChapterFourVisualHintLevel;
    }
    if (session.pairedDetailIds.includes(detailId)) paired = true;
  }
  return Object.freeze({ level, emphasized, paired });
}

export function selectChapterFourVisualHintPuzzleForIntent(
  intentType: string,
  targetId?: string
): ChapterFourVisualHintPuzzleId | null {
  if (intentType === "inspect_bakery_conveyor_edge"
    || intentType === "complete_bakery_conveyor_stop") {
    return "bakery_trace_comparison";
  }
  if (intentType === "calibrate_elevator_history") return "elevator_timing_comparison";
  if (intentType === "place_room204_group") {
    const groupId = targetId?.replace(/^a2_room204_group_/, "") ?? "";
    return ROOM204_TARGET_PUZZLES[groupId as keyof typeof ROOM204_TARGET_PUZZLES] ?? null;
  }
  if (intentType === "open_cart_wheel_cover"
    || intentType === "lubricate_cart_wheel"
    || intentType === "lubricate_clock_gear") {
    return "maintenance_geometry_comparison";
  }
  if (intentType === "lock_light_grid") return "power_route_comparison";
  if (intentType === "collect_final_minute") return "room202_record_comparison";
  return null;
}

export function validateChapterFourVisualHintContracts(
  knownDetailIds?: ReadonlySet<string>
): { puzzleCount: 9; maximumFailureCount: 4 } {
  if (CONTRACTS.length !== 9 || new Set(CONTRACTS.map((contract) => contract.id)).size !== 9) {
    throw new Error("chapter4_visual_hint_contract_coverage");
  }
  for (const contract of CONTRACTS) {
    const detailIds: readonly string[] = contract.detailIds;
    const pairedDetailIds: readonly string[] = contract.pairedDetailIds;
    if (detailIds.length < 2
      || new Set(detailIds).size !== detailIds.length
      || contract.pairedDetailIds.length !== 2
      || pairedDetailIds.some((detailId) => !detailIds.includes(detailId))) {
      throw new Error(`chapter4_visual_hint_contract_details:${contract.id}`);
    }
    if (knownDetailIds
      && detailIds.some((detailId) => !knownDetailIds.has(detailId))) {
      throw new Error(`chapter4_visual_hint_unknown_detail:${contract.id}`);
    }
  }
  const levels = [1, 2, 3, 4, 5].map(chapterFourVisualHintLevelForFailureCount);
  if (levels.join(",") !== "0,1,2,3,3") {
    throw new Error("chapter4_visual_hint_level_progression");
  }
  return Object.freeze({ puzzleCount: 9, maximumFailureCount: 4 });
}

export const CHAPTER_FOUR_VISUAL_HINT_VALIDATION = validateChapterFourVisualHintContracts();

function requireContract(puzzleId: ChapterFourVisualHintPuzzleId): ChapterFourVisualHintContract {
  const contract = CONTRACT_BY_ID.get(puzzleId);
  if (!contract) throw new Error(`chapter4_visual_hint_unknown_puzzle:${puzzleId}`);
  return contract;
}
