import type { ChapterFourFactId } from "../core/types";

export type ChapterFourElevatorRecordFloor = "A1" | "A2" | "A3";
export type ChapterFourElevatorDeductionFloor = "A2" | "A3";

export interface ChapterFourElevatorFloorRecord {
  floor: ChapterFourElevatorRecordFloor;
  displayFloor: 1 | 2 | 3;
  shortLabel: string;
  destinationLabel: string;
  recordTitle: string;
  timestamp: string;
  evidence: readonly [string, string];
  factId: ChapterFourFactId;
}

export const CHAPTER_FOUR_ELEVATOR_FLOOR_RECORDS = Object.freeze({
  A1: {
    floor: "A1",
    displayFloor: 1,
    shortLabel: "门厅 · 教室层",
    destinationLabel: "104 / 105 / 旧钟门厅",
    recordTitle: "起行与门体轨",
    timestamp: "18:49:58—18:50:06",
    evidence: [
      "一楼门体持续开放八秒，完整覆盖六秒进入窗口。",
      "门体闭合后，轿厢指示立即由 1F 转为上行。"
    ],
    factId: "elevator_history_observed"
  },
  A2: {
    floor: "A2",
    displayFloor: 2,
    shortLabel: "204 · 创客层",
    destinationLabel: "201 / 203 / 204 / 开放自习区",
    recordTitle: "外呼与门机对照",
    timestamp: "18:50:04—18:50:12",
    evidence: [
      "二楼下行外呼在 18:50:04 被按下，按钮持续亮到 18:50:12。",
      "同一时间段没有二楼门机开启记录，层显由 1F 直接跳到 3F。"
    ],
    factId: "elevator_a2_call_record_observed"
  },
  A3: {
    floor: "A3",
    displayFloor: 3,
    shortLabel: "荣誉墙 · 档案层",
    destinationLabel: "301 / 302 / 303 / 304 / 荣誉墙",
    recordTitle: "到站铃与开门轨",
    timestamp: "18:50:12—18:50:20",
    evidence: [
      "三楼到站铃在 18:50:12 响起，随后门机完整开启。",
      "轿厢内没有第二次起步记录，这里是离开一楼后的实际到站层。"
    ],
    factId: "elevator_a3_arrival_record_observed"
  }
} as const satisfies Readonly<Record<ChapterFourElevatorRecordFloor, ChapterFourElevatorFloorRecord>>);

export const CHAPTER_FOUR_ELEVATOR_RECORD_ORDER = Object.freeze([
  "A1",
  "A2",
  "A3"
] as const satisfies readonly ChapterFourElevatorRecordFloor[]);

export const CHAPTER_FOUR_ELEVATOR_STOP_CHAIN = Object.freeze({
  actualArrivalFloor: "A3" as const,
  unservedCallFloor: "A2" as const,
  factId: "elevator_stop_chain_reconstructed" as const satisfies ChapterFourFactId
});

export function chapterFourElevatorRecordForDisplayFloor(
  floor: 1 | 2 | 3
): ChapterFourElevatorFloorRecord {
  return CHAPTER_FOUR_ELEVATOR_FLOOR_RECORDS[`A${floor}` as ChapterFourElevatorRecordFloor];
}

export function chapterFourElevatorCollectedRecordCount(
  factIds: readonly ChapterFourFactId[]
): number {
  const facts = new Set(factIds);
  return CHAPTER_FOUR_ELEVATOR_RECORD_ORDER.filter(
    (floor) => facts.has(CHAPTER_FOUR_ELEVATOR_FLOOR_RECORDS[floor].factId)
  ).length;
}

export function chapterFourElevatorRecordsComplete(
  factIds: readonly ChapterFourFactId[]
): boolean {
  return chapterFourElevatorCollectedRecordCount(factIds)
    === CHAPTER_FOUR_ELEVATOR_RECORD_ORDER.length;
}

export function isChapterFourElevatorRecordFloor(
  value: unknown
): value is ChapterFourElevatorRecordFloor {
  return value === "A1" || value === "A2" || value === "A3";
}

export function isChapterFourElevatorDeductionFloor(
  value: unknown
): value is ChapterFourElevatorDeductionFloor {
  return value === "A2" || value === "A3";
}

export function isChapterFourElevatorStopChainCorrect(answer: {
  actualArrivalFloor: ChapterFourElevatorDeductionFloor;
  unservedCallFloor: ChapterFourElevatorDeductionFloor;
}): boolean {
  return answer.actualArrivalFloor === CHAPTER_FOUR_ELEVATOR_STOP_CHAIN.actualArrivalFloor
    && answer.unservedCallFloor === CHAPTER_FOUR_ELEVATOR_STOP_CHAIN.unservedCallFloor;
}
