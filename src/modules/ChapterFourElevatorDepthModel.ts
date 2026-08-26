export const CHAPTER_FOUR_PLAYER_DEPTH_BASE = 4000;

/**
 * The elevator is background architecture. Every dynamic player depth starts at
 * CHAPTER_FOUR_PLAYER_DEPTH_BASE, so keeping all elevator presentation layers
 * below that boundary guarantees the player remains visible during boarding,
 * travel handoff and arrival on A1/A2/A3.
 */
export const CHAPTER_FOUR_ELEVATOR_VISUAL_DEPTH = Object.freeze({
  door: CHAPTER_FOUR_PLAYER_DEPTH_BASE - 20,
  indicator: CHAPTER_FOUR_PLAYER_DEPTH_BASE - 19,
  lamp: CHAPTER_FOUR_PLAYER_DEPTH_BASE - 19
});

export function chapterFourPlayerDepth(worldY: number): number {
  return CHAPTER_FOUR_PLAYER_DEPTH_BASE + worldY;
}

export function isChapterFourPlayerInFrontOfElevator(
  playerDepth: number,
  elevatorDepth: number
): boolean {
  return Number.isFinite(playerDepth)
    && Number.isFinite(elevatorDepth)
    && playerDepth > elevatorDepth;
}
