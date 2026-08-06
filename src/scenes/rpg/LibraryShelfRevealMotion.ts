export interface LibraryShelfRevealFrame {
  offsetPx: number;
  durationMs: number;
  phase: "shaking" | "sliding";
}

export const LIBRARY_SHELF_REVEAL_SHIFT_PX = 16;

export const LIBRARY_SHELF_REVEAL_FRAMES: readonly LibraryShelfRevealFrame[] = [
  { offsetPx: 0, durationMs: 120, phase: "shaking" },
  { offsetPx: -2, durationMs: 135, phase: "shaking" },
  { offsetPx: 1, durationMs: 135, phase: "shaking" },
  { offsetPx: -1, durationMs: 135, phase: "shaking" },
  { offsetPx: 0, durationMs: 165, phase: "shaking" },
  { offsetPx: 2, durationMs: 175, phase: "sliding" },
  { offsetPx: 4, durationMs: 175, phase: "sliding" },
  { offsetPx: 6, durationMs: 175, phase: "sliding" },
  { offsetPx: 8, durationMs: 175, phase: "sliding" },
  { offsetPx: 10, durationMs: 175, phase: "sliding" },
  { offsetPx: 12, durationMs: 175, phase: "sliding" },
  { offsetPx: 14, durationMs: 175, phase: "sliding" },
  { offsetPx: LIBRARY_SHELF_REVEAL_SHIFT_PX, durationMs: 190, phase: "sliding" }
] as const;

export const LIBRARY_SHELF_REVEAL_TOTAL_MS = LIBRARY_SHELF_REVEAL_FRAMES
  .reduce((total, frame) => total + frame.durationMs, 0);

export function scaleLibraryShelfRevealOffset(offsetPx: number, finalOffsetPx: number): number {
  return Math.round(offsetPx * finalOffsetPx / LIBRARY_SHELF_REVEAL_SHIFT_PX);
}
