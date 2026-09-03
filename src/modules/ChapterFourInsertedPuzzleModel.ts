import type { ChapterFourFactId } from "../core/types";

export const CHAPTER_FOUR_INSERTED_PUZZLE_IDS = Object.freeze([
  "duty_board",
  "archive_index",
  "media_alignment",
  "positioning_calibration",
  "power_topology",
  "evacuation_route"
] as const);

export type ChapterFourInsertedPuzzleId =
  typeof CHAPTER_FOUR_INSERTED_PUZZLE_IDS[number];

export const CHAPTER_FOUR_INSERTED_PUZZLE_TARGETS = Object.freeze({
  a1_front_desk_duty_board_context: "duty_board",
  a3_archive_exhibition_301_context: "archive_index",
  a3_media_studio_302_context: "media_alignment",
  a2_maker_workshop_201_context: "positioning_calibration",
  a2_computer_room_203_context: "power_topology",
  a2_open_study_evacuation_context: "evacuation_route"
} as const satisfies Readonly<Record<string, ChapterFourInsertedPuzzleId>>);

export type ChapterFourInsertedPuzzleTargetId =
  keyof typeof CHAPTER_FOUR_INSERTED_PUZZLE_TARGETS;

export type ChapterFourDutyBoardCardId = "classroom_104" | "classroom_105" | "main_elevator";
export type ChapterFourArchiveYearBandId = "1977_1984" | "1985_1990" | "1991_1998";
export type ChapterFourArchiveFloorId = "A1" | "A2" | "A3";
export type ChapterFourArchivePurposeId = "attendance" | "wayfinding" | "maintenance";
export type ChapterFourPowerEdgeId =
  | "hall__west_corridor"
  | "hall__east_corridor"
  | "west_corridor__bakery_back_area"
  | "east_corridor__classroom_zone"
  | "bakery_back_area__classroom_zone"
  | "west_corridor__east_corridor"
  | "hall__classroom_zone";
export type ChapterFourEvacuationSegmentId =
  | "lecture_202_door"
  | "east_corridor"
  | "transport_core"
  | "main_stair_down";

export type ChapterFourInsertedPuzzleAnswer =
  | {
      puzzleId: "duty_board";
      order: ChapterFourDutyBoardCardId[];
    }
  | {
      puzzleId: "archive_index";
      yearBand: ChapterFourArchiveYearBandId;
      floor: ChapterFourArchiveFloorId;
      purpose: ChapterFourArchivePurposeId;
    }
  | {
      puzzleId: "media_alignment";
      xOffset: number;
      yOffset: number;
      rotationQuarterTurns: number;
    }
  | {
      puzzleId: "positioning_calibration";
      horizontal: number;
      vertical: number;
      pressure: number;
    }
  | {
      puzzleId: "power_topology";
      edgeIds: ChapterFourPowerEdgeId[];
    }
  | {
      puzzleId: "evacuation_route";
      order: ChapterFourEvacuationSegmentId[];
    };

export interface ChapterFourInsertedPuzzleDefinition {
  id: ChapterFourInsertedPuzzleId;
  factId: ChapterFourFactId;
  targetId: ChapterFourInsertedPuzzleTargetId;
  title: string;
  locationLabel: string;
  darkPrompt: string;
  lightPrompt: string;
  successText: string;
}

export const CHAPTER_FOUR_INSERTED_PUZZLES = Object.freeze({
  duty_board: {
    id: "duty_board",
    factId: "a1_duty_board_reconstructed",
    targetId: "a1_front_desk_duty_board_context",
    title: "值班牌重建",
    locationLabel: "A1 前台",
    darkPrompt: "三段痕迹分别停在 104、105 与主电梯；夹痕由左向右逐渐变新。",
    lightPrompt: "把三张值班牌按痕迹先后放回签到板。",
    successText: "A1 的三处调查已汇成一条值班记录。"
  },
  archive_index: {
    id: "archive_index",
    factId: "a3_archive_film_retrieved",
    targetId: "a3_archive_exhibition_301_context",
    title: "胶片索引",
    locationLabel: "A3 · 301 校史档案展",
    darkPrompt: "残留索引指向九十年代末、A3 层，并标记为入口导视用途。",
    lightPrompt: "用年份、楼层和用途缩小抽屉范围，取出唯一胶片。",
    successText: "旧导视胶片已从索引抽屉取出。"
  },
  media_alignment: {
    id: "media_alignment",
    factId: "a3_media_alignment_completed",
    targetId: "a3_media_studio_302_context",
    title: "新旧影像对齐",
    locationLabel: "A3 · 302 媒体工作室",
    darkPrompt: "旧影像的入口轮廓向右偏两格、向上一格，并顺时针转过四分之一圈。",
    lightPrompt: "平移并旋转胶片，让入口、楼梯与荣誉墙三个轮廓同时重合。",
    successText: "旧导视影像已与当前楼层坐标重合。"
  },
  positioning_calibration: {
    id: "positioning_calibration",
    factId: "a2_positioning_plate_calibrated",
    targetId: "a2_maker_workshop_201_context",
    title: "定位板校准",
    locationLabel: "A2 · 201 创客工坊",
    darkPrompt: "压力痕迹显示横向回退两格、纵向前推一格，第三档压力留下完整压印。",
    lightPrompt: "调整横向、纵向与压力，让三处触点同时落入旧痕。",
    successText: "定位板已完成三轴校准。"
  },
  power_topology: {
    id: "power_topology",
    factId: "a2_power_topology_recovered",
    targetId: "a2_computer_room_203_context",
    title: "五区拓扑恢复",
    locationLabel: "A2 · 203 计算机教室",
    darkPrompt: "五区形成一个闭合环：大厅连两侧走廊，两侧分别接后区与教室区，末端再相连。",
    lightPrompt: "只保留停电前存在的五条相邻连线。",
    successText: "五区供电拓扑已恢复到停电前状态。"
  },
  evacuation_route: {
    id: "evacuation_route",
    factId: "a2_evacuation_route_confirmed",
    targetId: "a2_open_study_evacuation_context",
    title: "202 夜间疏散图",
    locationLabel: "A2 · 开放自习区路线板",
    darkPrompt: "图面没有完整箭头。比较四处鞋印的朝向、连续纹路和收束位置。",
    lightPrompt: "从 202 门口开始，把四块磁贴排成连续通路；终点必须落在主楼梯下行口。",
    successText: "202 到主楼梯的夜间疏散路线已记录。"
  }
} as const satisfies Readonly<Record<ChapterFourInsertedPuzzleId, ChapterFourInsertedPuzzleDefinition>>);

const DUTY_ORDER: readonly ChapterFourDutyBoardCardId[] = [
  "classroom_104",
  "classroom_105",
  "main_elevator"
];
const EVACUATION_ORDER: readonly ChapterFourEvacuationSegmentId[] = [
  "lecture_202_door",
  "east_corridor",
  "transport_core",
  "main_stair_down"
];
const POWER_EDGES: readonly ChapterFourPowerEdgeId[] = [
  "hall__west_corridor",
  "hall__east_corridor",
  "west_corridor__bakery_back_area",
  "east_corridor__classroom_zone",
  "bakery_back_area__classroom_zone"
];

export function chapterFourInsertedPuzzleForTarget(
  targetId: string
): ChapterFourInsertedPuzzleId | null {
  return Object.prototype.hasOwnProperty.call(CHAPTER_FOUR_INSERTED_PUZZLE_TARGETS, targetId)
    ? CHAPTER_FOUR_INSERTED_PUZZLE_TARGETS[targetId as ChapterFourInsertedPuzzleTargetId]
    : null;
}

export function isChapterFourInsertedPuzzleId(
  value: unknown
): value is ChapterFourInsertedPuzzleId {
  return typeof value === "string"
    && (CHAPTER_FOUR_INSERTED_PUZZLE_IDS as readonly string[]).includes(value);
}

export function isChapterFourInsertedPuzzleAnswer(
  value: unknown
): value is ChapterFourInsertedPuzzleAnswer {
  if (typeof value !== "object" || value === null || Array.isArray(value)) return false;
  const answer = value as Record<string, unknown>;
  if (!isChapterFourInsertedPuzzleId(answer.puzzleId)) return false;
  switch (answer.puzzleId) {
    case "duty_board":
      return stringArray(answer.order, ["classroom_104", "classroom_105", "main_elevator"]);
    case "archive_index":
      return ["1977_1984", "1985_1990", "1991_1998"].includes(String(answer.yearBand))
        && ["A1", "A2", "A3"].includes(String(answer.floor))
        && ["attendance", "wayfinding", "maintenance"].includes(String(answer.purpose));
    case "media_alignment":
      return integerBetween(answer.xOffset, -3, 3)
        && integerBetween(answer.yOffset, -3, 3)
        && integerBetween(answer.rotationQuarterTurns, 0, 3);
    case "positioning_calibration":
      return integerBetween(answer.horizontal, -3, 3)
        && integerBetween(answer.vertical, -3, 3)
        && integerBetween(answer.pressure, 0, 4);
    case "power_topology":
      return stringArray(answer.edgeIds, [
        "hall__west_corridor",
        "hall__east_corridor",
        "west_corridor__bakery_back_area",
        "east_corridor__classroom_zone",
        "bakery_back_area__classroom_zone",
        "west_corridor__east_corridor",
        "hall__classroom_zone"
      ]);
    case "evacuation_route":
      return stringArray(answer.order, [
        "lecture_202_door",
        "east_corridor",
        "transport_core",
        "main_stair_down"
      ]);
  }
}

export function isChapterFourInsertedPuzzleAnswerCorrect(
  answer: ChapterFourInsertedPuzzleAnswer
): boolean {
  switch (answer.puzzleId) {
    case "duty_board":
      return sameOrder(answer.order, DUTY_ORDER);
    case "archive_index":
      return answer.yearBand === "1991_1998"
        && answer.floor === "A3"
        && answer.purpose === "wayfinding";
    case "media_alignment":
      return answer.xOffset === 2
        && answer.yOffset === -1
        && answer.rotationQuarterTurns === 1;
    case "positioning_calibration":
      return answer.horizontal === -2
        && answer.vertical === 1
        && answer.pressure === 3;
    case "power_topology":
      return sameSet(answer.edgeIds, POWER_EDGES);
    case "evacuation_route":
      return sameOrder(answer.order, EVACUATION_ORDER);
  }
}

function stringArray(value: unknown, allowed: readonly string[]): boolean {
  return Array.isArray(value)
    && value.length > 0
    && value.every((entry) => typeof entry === "string" && allowed.includes(entry));
}

function integerBetween(value: unknown, min: number, max: number): boolean {
  return typeof value === "number" && Number.isInteger(value) && value >= min && value <= max;
}

function sameOrder<T extends string>(actual: readonly T[], expected: readonly T[]): boolean {
  return actual.length === expected.length
    && actual.every((entry, index) => entry === expected[index]);
}

function sameSet<T extends string>(actual: readonly T[], expected: readonly T[]): boolean {
  return actual.length === expected.length
    && new Set(actual).size === expected.length
    && expected.every((entry) => actual.includes(entry));
}
