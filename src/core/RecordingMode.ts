/**
 * Presentation-only switch for clean gameplay capture.
 *
 * The flag deliberately lives in the URL instead of GameState/SaveStore so a
 * recording setup can never affect story progress or a player's formal save.
 */
export function isRecordingMode(search: string): boolean {
  return new URLSearchParams(search).get("recording") === "1";
}
