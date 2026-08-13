import content from "../data/chapter4-temporal-maze.content.json";

export const CHAPTER_FOUR_ELEVATOR = Object.freeze({ ...content.elevator.timeline });

export function isChapterFourElevatorStartSelectable(startSeconds: number): boolean {
  return Number.isInteger(startSeconds)
    && startSeconds >= CHAPTER_FOUR_ELEVATOR.selectableStartMinSeconds
    && startSeconds <= CHAPTER_FOUR_ELEVATOR.selectableStartMaxSeconds;
}

export function isChapterFourElevatorTrackAligned(startSeconds: number): boolean {
  return startSeconds === CHAPTER_FOUR_ELEVATOR.correctReplayStartSeconds;
}
