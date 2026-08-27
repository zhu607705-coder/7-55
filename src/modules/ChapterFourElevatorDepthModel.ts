export const CHAPTER_FOUR_PLAYER_DEPTH_BASE = 4000;
export const CHAPTER_FOUR_PLAYER_TOP_DEPTH = 9900;

/**
 * The elevator is background architecture. Keeping all elevator presentation
 * layers below CHAPTER_FOUR_PLAYER_DEPTH_BASE guarantees the player remains
 * visible during boarding, travel handoff and arrival on A1/A2/A3.
 */
export const CHAPTER_FOUR_ELEVATOR_VISUAL_DEPTH = Object.freeze({
  door: CHAPTER_FOUR_PLAYER_DEPTH_BASE - 20,
  indicator: CHAPTER_FOUR_PLAYER_DEPTH_BASE - 19,
  lamp: CHAPTER_FOUR_PLAYER_DEPTH_BASE - 19
});

export function chapterFourPlayerDepth(_worldY: number): number {
  return CHAPTER_FOUR_PLAYER_TOP_DEPTH;
}

export function isChapterFourPlayerInFrontOfElevator(
  playerDepth: number,
  elevatorDepth: number
): boolean {
  return Number.isFinite(playerDepth)
    && Number.isFinite(elevatorDepth)
    && playerDepth > elevatorDepth;
}
