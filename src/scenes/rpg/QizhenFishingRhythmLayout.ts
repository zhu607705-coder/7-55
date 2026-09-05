import type { QizhenFishingNote } from "./QizhenFishingRhythmModel";

// Logical 960 x 540 coordinates. Clip geometry before drawing: a Phaser
// GeometryMask cannot inherit the adaptive screen-space wrapper transform.
export const FISHING_BOARD = Object.freeze({
  left: 270, right: 690, top: 84, bottom: 490,
  noteTop: 178, judgmentY: 406, noteBottom: 423,
  keyTop: 434, keyBottom: 482, noteWidth: 98, noteHeight: 28,
});
export const FISHING_LANES = Object.freeze([
  { action: "left", key: "A", label: "左收线", x: 342, color: 0x94dfa4 },
  { action: "hook", key: "S", label: "提竿", x: 480, color: 0x9edaff },
  { action: "right", key: "D", label: "右收线", x: 618, color: 0xffd27e },
] as const);

export function fishingTileGeometry(note: QizhenFishingNote, elapsed: number, firstVisible: number) {
  const b = FISHING_BOARD;
  const start = Math.min(note.spawnSec, Math.max(0, firstVisible));
  const speed = (b.judgmentY - b.noteTop) / Math.max(0.001, note.timeSec - start);
  const headY = b.noteTop + Math.max(0, elapsed - start) * speed;
  const rawTop = note.holdSec > 0 ? headY - note.holdSec * speed : headY - b.noteHeight / 2;
  const top = Math.max(b.noteTop, rawTop);
  const bottom = Math.min(b.noteBottom, (note.holding ? b.judgmentY : headY) + b.noteHeight / 2);
  const lane = FISHING_LANES.find((entry) => entry.action === note.action)!;
  return {
    x: lane.x - b.noteWidth / 2, y: top, width: b.noteWidth,
    height: Math.max(0, bottom - top), headY: note.holding ? b.judgmentY : headY,
    tailY: rawTop, action: note.action,
  };
}
