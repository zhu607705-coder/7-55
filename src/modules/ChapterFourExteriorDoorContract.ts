export type ChapterFourExteriorDoorState = "idle" | "opening" | "open";

interface ChapterFourExteriorDoorLeafContract {
  frameName: "a1-exterior-door-left" | "a1-exterior-door-right";
  hinge: "left" | "right";
  bounds: { x: number; y: number; width: number; height: number };
}

/**
 * A1 主入口动画直接从 1672 x 941 的晨间状态图裁取门扇。
 * 坐标与状态图一一对应，宿主和 Phaser 场景共用同一时序。
 */
export const CHAPTER_FOUR_EXTERIOR_DOOR = Object.freeze({
  storyFloor: "A1" as const,
  plateId: "a1_0755_morning" as const,
  doorwayBounds: Object.freeze({ x: 767, y: 779, width: 141, height: 94 }),
  leaves: Object.freeze([
    Object.freeze({
      frameName: "a1-exterior-door-left",
      hinge: "left",
      bounds: Object.freeze({ x: 767, y: 779, width: 72, height: 94 })
    }),
    Object.freeze({
      frameName: "a1-exterior-door-right",
      hinge: "right",
      bounds: Object.freeze({ x: 839, y: 779, width: 69, height: 94 })
    })
  ] as const satisfies readonly ChapterFourExteriorDoorLeafContract[]),
  startDelayMs: 240,
  openingDurationMs: 880,
  openHoldMs: 380,
  finalLeafScaleX: 0.12,
  openedEventName: "rpg_chapter4_exterior_door_opened" as const
});

export const CHAPTER_FOUR_EXTERIOR_DOOR_PRESENTATION_MS =
  CHAPTER_FOUR_EXTERIOR_DOOR.startDelayMs
  + CHAPTER_FOUR_EXTERIOR_DOOR.openingDurationMs
  + CHAPTER_FOUR_EXTERIOR_DOOR.openHoldMs;

export const CHAPTER_FOUR_EXTERIOR_DOOR_FALLBACK_MS =
  CHAPTER_FOUR_EXTERIOR_DOOR_PRESENTATION_MS + 1200;
