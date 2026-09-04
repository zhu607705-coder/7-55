export const DORM_HUB_SOURCE_WORLD = {
  width: 941,
  height: 1672
} as const;

// The shared indoor actor already renders at twice the dorm's former character
// treatment. Shrinking the authored room once more by one half yields the requested
// four-times relative character presence without introducing a dorm-only actor scale.
export const DORM_HUB_ENVIRONMENT_SCALE = 0.5;
export const DORM_HUB_MAP_OFFSET_X = Math.round(
  (960 - DORM_HUB_SOURCE_WORLD.width * DORM_HUB_ENVIRONMENT_SCALE) / 2
);
export const DORM_HUB_WORLD = {
  width: 960,
  height: DORM_HUB_SOURCE_WORLD.height * DORM_HUB_ENVIRONMENT_SCALE
} as const;

export const DORM_RAIN_SOAKED_VISUAL_PROFILE = Object.freeze({
  dropletCount: 8,
  reducedMotionDropletCount: 3,
  maxFootprints: 6,
  footprintSpacing: 18,
  footprintLifetimeMs: 980
});

export interface DormRainSoakedState {
  qizhenLake: {
    phase: string;
    rainRescueCompleted: boolean;
    rainSafetyCleared: boolean;
  };
}

/**
 * The player stays visibly soaked for the complete dorm recovery detour.
 * Picking up the dryer alone does not dry them; the weather calibration is the
 * controller-owned terminal fact for this presentation state.
 */
export function isDormPlayerRainSoaked(state: DormRainSoakedState): boolean {
  return state.qizhenLake.phase === "rain_recovery"
    && state.qizhenLake.rainRescueCompleted
    && !state.qizhenLake.rainSafetyCleared;
}

export function dormSourceToWorldX(sourceX: number): number {
  return DORM_HUB_MAP_OFFSET_X + sourceX * DORM_HUB_ENVIRONMENT_SCALE;
}

export function dormSourceToWorldY(sourceY: number): number {
  return sourceY * DORM_HUB_ENVIRONMENT_SCALE;
}

export function dormSourceToWorldSize(sourceSize: number): number {
  return sourceSize * DORM_HUB_ENVIRONMENT_SCALE;
}

export function dormWorldToSourceX(worldX: number): number {
  return (worldX - DORM_HUB_MAP_OFFSET_X) / DORM_HUB_ENVIRONMENT_SCALE;
}

export function dormWorldToSourceY(worldY: number): number {
  return worldY / DORM_HUB_ENVIRONMENT_SCALE;
}

export function dormWorldToSourceSize(worldSize: number): number {
  return worldSize / DORM_HUB_ENVIRONMENT_SCALE;
}

export interface DormCollisionRect {
  id: string;
  left: number;
  top: number;
  right: number;
  bottom: number;
}

// Bounds are authored directly against dorm_hub.png (941 x 1672).
// Furniture keeps its visible source-pixel silhouette while the blue aisle stays open.
export const DORM_SOURCE_STATIC_COLLISION_RECTS: readonly DormCollisionRect[] = [
  { id: "north_wall", left: 20, top: 10, right: 920, bottom: 403 },
  { id: "west_wall", left: 18, top: 42, right: 66, bottom: 1518 },
  { id: "east_wall", left: 878, top: 42, right: 923, bottom: 1518 },
  { id: "south_wall_west", left: 20, top: 1484, right: 399, bottom: 1595 },
  { id: "south_wall_east", left: 542, top: 1484, right: 920, bottom: 1595 },
  { id: "bunk_bed_row", left: 70, top: 96, right: 260, bottom: 965 },
  { id: "upper_personal_shelf", left: 272, top: 181, right: 359, bottom: 402 },
  { id: "window_cabinet", left: 410, top: 226, right: 566, bottom: 403 },
  { id: "laundry_bin", left: 589, top: 246, right: 672, bottom: 389 },
  { id: "desk_01", left: 732, top: 181, right: 881, bottom: 450 },
  { id: "chair_01", left: 680, top: 221, right: 734, bottom: 428 },
  { id: "desk_02", left: 732, top: 456, right: 881, bottom: 716 },
  { id: "chair_02", left: 680, top: 495, right: 734, bottom: 681 },
  { id: "desk_03", left: 732, top: 723, right: 881, bottom: 991 },
  { id: "chair_03", left: 680, top: 760, right: 734, bottom: 960 },
  { id: "desk_04", left: 732, top: 998, right: 881, bottom: 1288 },
  { id: "chair_04", left: 680, top: 1042, right: 734, bottom: 1246 },
  { id: "wash_basin", left: 72, top: 957, right: 256, bottom: 1122 },
  { id: "balcony_partition", left: 34, top: 1115, right: 226, bottom: 1494 },
  { id: "lower_personal_shelf", left: 271, top: 1048, right: 361, bottom: 1266 },
  { id: "floor_backpack", left: 680, top: 1324, right: 753, bottom: 1438 },
  { id: "lower_right_storage", left: 745, top: 1268, right: 879, bottom: 1477 }
] as const;

export const DORM_STATIC_COLLISION_RECTS: readonly DormCollisionRect[] = Object.freeze(
  DORM_SOURCE_STATIC_COLLISION_RECTS.map((rect) => ({
    id: rect.id,
    left: dormSourceToWorldX(rect.left),
    top: dormSourceToWorldY(rect.top),
    right: dormSourceToWorldX(rect.right),
    bottom: dormSourceToWorldY(rect.bottom)
  }))
);

export type DormInteractionTargetId =
  | "upper_bunk"
  | "lower_bunk"
  | "window"
  | "window_cabinet"
  | "shoe_shelf"
  | "laundry_bin"
  | "desk_01"
  | "desk_02"
  | "desk_03"
  | "desk_04"
  | "hair_dryer"
  | "wash_basin"
  | "lower_shelf"
  | "floor_backpack"
  | "exit_door";

export interface DormInteractionTarget {
  id: DormInteractionTargetId;
  x: number;
  y: number;
  width: number;
  height: number;
  proximity: number;
  label: string;
}

export const DORM_SOURCE_INTERACTION_TARGETS: readonly DormInteractionTarget[] = [
  { id: "upper_bunk", x: 166, y: 350, width: 190, height: 500, proximity: 128, label: "检查上铺床组" },
  { id: "lower_bunk", x: 166, y: 790, width: 190, height: 340, proximity: 128, label: "检查下铺床组" },
  { id: "window", x: 375, y: 260, width: 90, height: 286, proximity: 100, label: "拉动窗帘" },
  { id: "window_cabinet", x: 488, y: 315, width: 156, height: 174, proximity: 118, label: "打开窗下柜" },
  { id: "shoe_shelf", x: 316, y: 302, width: 90, height: 208, proximity: 112, label: "查看鞋架" },
  { id: "laundry_bin", x: 630, y: 315, width: 84, height: 142, proximity: 105, label: "查看洗衣篮" },
  { id: "desk_01", x: 805, y: 316, width: 150, height: 268, proximity: 142, label: "拨动蓝色台灯" },
  { id: "desk_02", x: 805, y: 586, width: 150, height: 260, proximity: 142, label: "翻看摊开的书" },
  { id: "desk_03", x: 805, y: 855, width: 150, height: 268, proximity: 142, label: "检查个人书桌" },
  { id: "desk_04", x: 805, y: 1140, width: 150, height: 290, proximity: 142, label: "拉开书桌抽屉" },
  { id: "wash_basin", x: 164, y: 1030, width: 184, height: 166, proximity: 130, label: "拧开水龙头" },
  { id: "lower_shelf", x: 316, y: 1155, width: 92, height: 218, proximity: 112, label: "查看床边书架" },
  { id: "floor_backpack", x: 714, y: 1382, width: 74, height: 116, proximity: 108, label: "检查地上的背包" },
  { id: "exit_door", x: 470, y: 1530, width: 148, height: 118, proximity: 116, label: "打开寝室门" }
] as const;

function dormSourceTargetToWorld(target: DormInteractionTarget): DormInteractionTarget {
  return {
    ...target,
    x: dormSourceToWorldX(target.x),
    y: dormSourceToWorldY(target.y),
    width: dormSourceToWorldSize(target.width),
    height: dormSourceToWorldSize(target.height),
    proximity: dormSourceToWorldSize(target.proximity)
  };
}

export const DORM_INTERACTION_TARGETS: readonly DormInteractionTarget[] = Object.freeze(
  DORM_SOURCE_INTERACTION_TARGETS.map(dormSourceTargetToWorld)
);

export const DORM_SOURCE_CAMPUS_CARD = {
  x: 792,
  y: 928,
  proximity: 148
} as const;

export const DORM_CAMPUS_CARD = {
  x: dormSourceToWorldX(DORM_SOURCE_CAMPUS_CARD.x),
  y: dormSourceToWorldY(DORM_SOURCE_CAMPUS_CARD.y),
  proximity: dormSourceToWorldSize(DORM_SOURCE_CAMPUS_CARD.proximity)
} as const;

export const DORM_SOURCE_QIZHEN_HAIR_DRYER: DormInteractionTarget = {
  id: "hair_dryer",
  x: 805,
  y: 914,
  width: 104,
  height: 104,
  proximity: 122,
  label: "拿起书桌上的吹风机"
};

export const DORM_QIZHEN_HAIR_DRYER = dormSourceTargetToWorld(DORM_SOURCE_QIZHEN_HAIR_DRYER);

export const DORM_SOURCE_SPAWN = {
  x: 470,
  y: 1440
} as const;

export const DORM_SPAWN = {
  x: dormSourceToWorldX(DORM_SOURCE_SPAWN.x),
  y: dormSourceToWorldY(DORM_SOURCE_SPAWN.y)
} as const;

export function findNearestDormTarget(
  x: number,
  y: number,
  targets: readonly DormInteractionTarget[] = DORM_INTERACTION_TARGETS
): DormInteractionTarget | null {
  let nearest: DormInteractionTarget | null = null;
  let nearestDistance = Number.POSITIVE_INFINITY;
  for (const target of targets) {
    const distance = distanceToDormTarget(x, y, target);
    if (distance <= target.proximity && distance < nearestDistance) {
      nearest = target;
      nearestDistance = distance;
    }
  }
  return nearest;
}

export function distanceToDormTarget(x: number, y: number, target: DormInteractionTarget): number {
  const outsideX = Math.max(Math.abs(x - target.x) - target.width / 2, 0);
  const outsideY = Math.max(Math.abs(y - target.y) - target.height / 2, 0);
  return Math.hypot(outsideX, outsideY);
}
