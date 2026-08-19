import type { ItemId, QizhenPhotoRecipe, QizhenPhotoSpotId } from "../../core/types";
import {
  distanceFromPlayerToRpgTarget,
  isPlayerWithinRpgTarget,
  type RpgSpatialInteractionTarget
} from "./RpgInteractionContract";

export const QIZHEN_LAKE_WORLD = { width: 1672, height: 941 } as const;

export type QizhenLakeZoneId = "dock" | "open_water" | "channel" | "swan_cove";
export type QizhenLakeVehicle = "on_foot" | "kayak";

export interface QizhenLakeCollisionRect {
  id: string;
  left: number;
  top: number;
  right: number;
  bottom: number;
}

export interface QizhenLakeOcclusionRect extends QizhenLakeCollisionRect {
  sortY: number;
}

export interface QizhenLakeWaterArea {
  id: string;
  left: number;
  top: number;
  right: number;
  bottom: number;
}

export type QizhenLakeTargetKind =
  | "exit"
  | "outfit"
  | "board"
  | "zone_portal"
  | "reflection"
  | "fishing_spot"
  | "item_use"
  | "swan"
  | "paper"
  | "escape";

export interface QizhenLakeInteractionTarget extends RpgSpatialInteractionTarget {
  kind: QizhenLakeTargetKind;
  zone: QizhenLakeZoneId;
  value?: string;
  targetZone?: QizhenLakeZoneId;
  vehicle?: QizhenLakeVehicle;
  /** Assembly targets accept either of their two parts. */
  acceptedItems?: readonly ItemId[];
}

export interface QizhenLakeZoneDefinition {
  id: QizhenLakeZoneId;
  onFootSpawn: { x: number; y: number };
  kayakSpawn: { x: number; y: number; heading: number };
  kayakEntrySpawns: Partial<Record<QizhenLakeZoneId, { x: number; y: number; heading: number }>>;
  onFootCollisions: readonly QizhenLakeCollisionRect[];
  kayakCollisions: readonly QizhenLakeCollisionRect[];
  waterAreas: readonly QizhenLakeWaterArea[];
  occlusions: readonly QizhenLakeOcclusionRect[];
}

const EDGE = 28;
const FULL_LEFT: QizhenLakeCollisionRect = {
  id: "world_left",
  left: 0,
  top: 0,
  right: EDGE,
  bottom: QIZHEN_LAKE_WORLD.height
};
const FULL_RIGHT: QizhenLakeCollisionRect = {
  id: "world_right",
  left: QIZHEN_LAKE_WORLD.width - EDGE,
  top: 0,
  right: QIZHEN_LAKE_WORLD.width,
  bottom: QIZHEN_LAKE_WORLD.height
};
const FULL_TOP: QizhenLakeCollisionRect = {
  id: "world_top",
  left: 0,
  top: 0,
  right: QIZHEN_LAKE_WORLD.width,
  bottom: EDGE
};
const FULL_BOTTOM: QizhenLakeCollisionRect = {
  id: "world_bottom",
  left: 0,
  top: QIZHEN_LAKE_WORLD.height - EDGE,
  right: QIZHEN_LAKE_WORLD.width,
  bottom: QIZHEN_LAKE_WORLD.height
};

export const QIZHEN_LAKE_ZONES: Readonly<Record<QizhenLakeZoneId, QizhenLakeZoneDefinition>> = {
  dock: {
    id: "dock",
    onFootSpawn: { x: 330, y: 830 },
    kayakSpawn: { x: 714, y: 390, heading: -Math.PI / 2 },
    kayakEntrySpawns: {
      open_water: { x: 1425, y: 390, heading: Math.PI }
    },
    onFootCollisions: [
      FULL_LEFT,
      FULL_RIGHT,
      FULL_TOP,
      FULL_BOTTOM,
      { id: "north_water", left: 0, top: 0, right: 1672, bottom: 430 },
      { id: "shore_water", left: 0, top: 430, right: 630, bottom: 555 },
      { id: "pier_east_water", left: 790, top: 430, right: 1672, bottom: 650 },
      { id: "southeast_water", left: 1080, top: 650, right: 1672, bottom: 941 },
      { id: "kayak_house", left: 80, top: 642, right: 425, bottom: 825 },
      { id: "kayak_rack_base", left: 448, top: 814, right: 542, bottom: 842 },
      { id: "south_planter", left: 690, top: 795, right: 1080, bottom: 941 }
    ],
    kayakCollisions: [
      FULL_LEFT,
      FULL_RIGHT,
      FULL_TOP,
      FULL_BOTTOM,
      { id: "west_land", left: 0, top: 370, right: 610, bottom: 941 },
      { id: "dock_walkway", left: 618, top: 430, right: 790, bottom: 670 },
      { id: "south_land", left: 790, top: 650, right: 1100, bottom: 941 },
      { id: "south_willow", left: 860, top: 610, right: 1090, bottom: 890 }
    ],
    waterAreas: [
      { id: "dock_basin", left: 520, top: 28, right: 1644, bottom: 913 }
    ],
    occlusions: [
      { id: "dock_walkway_front", left: 620, top: 450, right: 790, bottom: 688, sortY: 610 },
      { id: "kayak_rack_front", left: 438, top: 714, right: 542, bottom: 844, sortY: 814 },
      { id: "south_willow", left: 830, top: 600, right: 1100, bottom: 910, sortY: 910 }
    ]
  },
  open_water: {
    id: "open_water",
    onFootSpawn: { x: 836, y: 820 },
    kayakSpawn: { x: 560, y: 790, heading: -Math.PI / 2 },
    kayakEntrySpawns: {
      dock: { x: 560, y: 790, heading: -Math.PI / 2 },
      swan_cove: { x: 1450, y: 500, heading: Math.PI },
      channel: { x: 620, y: 160, heading: Math.PI / 2 }
    },
    onFootCollisions: [FULL_LEFT, FULL_RIGHT, FULL_TOP, FULL_BOTTOM],
    kayakCollisions: [
      FULL_LEFT,
      FULL_RIGHT,
      FULL_TOP,
      FULL_BOTTOM,
      { id: "northwest_island", left: 90, top: 45, right: 575, bottom: 400 },
      { id: "north_channel_bank", left: 780, top: 28, right: 980, bottom: 180 },
      { id: "lily_piles", left: 1020, top: 520, right: 1260, bottom: 765 },
      { id: "south_central_bank", left: 650, top: 810, right: 1040, bottom: 941 }
    ],
    waterAreas: [
      { id: "open_basin", left: 30, top: 30, right: 1642, bottom: 911 }
    ],
    occlusions: [
      { id: "northwest_willow", left: 120, top: 40, right: 530, bottom: 420, sortY: 420 },
      { id: "lily_piles", left: 1030, top: 500, right: 1260, bottom: 760, sortY: 760 }
    ]
  },
  channel: {
    id: "channel",
    onFootSpawn: { x: 1540, y: 505 },
    kayakSpawn: { x: 1280, y: 680, heading: Math.PI },
    kayakEntrySpawns: {
      swan_cove: { x: 1280, y: 680, heading: Math.PI },
      open_water: { x: 840, y: 755, heading: -Math.PI / 2 },
      dock: { x: 120, y: 510, heading: 0 }
    },
    onFootCollisions: [FULL_LEFT, FULL_RIGHT, FULL_TOP, FULL_BOTTOM],
    kayakCollisions: [
      FULL_LEFT,
      FULL_RIGHT,
      FULL_TOP,
      FULL_BOTTOM,
      { id: "north_bank_west", left: 0, top: 0, right: 650, bottom: 174 },
      { id: "north_bank_willow_1", left: 650, top: 0, right: 755, bottom: 198 },
      { id: "north_bank_center", left: 755, top: 0, right: 1185, bottom: 174 },
      { id: "north_bank_willow_2", left: 1185, top: 0, right: 1300, bottom: 202 },
      { id: "north_bank_east", left: 1300, top: 0, right: 1605, bottom: 178 },
      { id: "right_upper_bank", left: 1605, top: 0, right: 1672, bottom: 438 },
      { id: "south_bank_west", left: 0, top: 770, right: 1400, bottom: 941 },
      { id: "south_bank_step_1", left: 1400, top: 730, right: 1500, bottom: 941 },
      { id: "south_bank_step_2", left: 1500, top: 650, right: 1560, bottom: 941 },
      { id: "south_bank_step_3", left: 1560, top: 570, right: 1672, bottom: 941 },
      { id: "floating_raft", left: 555, top: 374, right: 712, bottom: 525 },
      { id: "west_net", left: 448, top: 432, right: 555, bottom: 532 },
      { id: "raft_mooring_nw", left: 505, top: 388, right: 528, bottom: 435 },
      { id: "raft_mooring_se", left: 685, top: 525, right: 708, bottom: 572 },
      { id: "right_dock", left: 1548, top: 450, right: 1672, bottom: 580 },
      { id: "rock_west", left: 285, top: 548, right: 350, bottom: 608 },
      { id: "rock_mid_east", left: 1215, top: 525, right: 1322, bottom: 607 },
      { id: "rock_east", left: 1350, top: 492, right: 1424, bottom: 557 },
      { id: "buoy_1", left: 78, top: 485, right: 102, bottom: 523 },
      { id: "buoy_2", left: 360, top: 440, right: 385, bottom: 479 },
      { id: "buoy_3", left: 932, top: 440, right: 957, bottom: 479 },
      { id: "buoy_4", left: 1228, top: 440, right: 1253, bottom: 479 },
      { id: "buoy_5", left: 1478, top: 439, right: 1503, bottom: 478 }
    ],
    waterAreas: [
      { id: "straight_channel", left: 28, top: 174, right: 1644, bottom: 770 }
    ],
    occlusions: [
      { id: "floating_raft", left: 535, top: 340, right: 745, bottom: 570, sortY: 570 },
      { id: "north_willows", left: 0, top: 0, right: 1420, bottom: 220, sortY: 220 },
      { id: "south_willows", left: 0, top: 700, right: 1430, bottom: 941, sortY: 941 }
    ]
  },
  swan_cove: {
    id: "swan_cove",
    onFootSpawn: { x: 180, y: 515 },
    kayakSpawn: { x: 220, y: 515, heading: 0 },
    kayakEntrySpawns: {
      open_water: { x: 190, y: 510, heading: 0 },
      channel: { x: 410, y: 835, heading: -Math.PI / 2 }
    },
    onFootCollisions: [FULL_LEFT, FULL_RIGHT, FULL_TOP, FULL_BOTTOM],
    kayakCollisions: [
      FULL_LEFT,
      FULL_RIGHT,
      FULL_TOP,
      FULL_BOTTOM,
      { id: "north_bank", left: 0, top: 0, right: 1672, bottom: 160 },
      { id: "east_walkway", left: 1450, top: 0, right: 1672, bottom: 941 },
      { id: "swan_fence_north", left: 924, top: 158, right: 1155, bottom: 190 },
      { id: "swan_fence_west_upper", left: 924, top: 158, right: 951, bottom: 383 },
      { id: "swan_fence_west_curve_1", left: 938, top: 362, right: 984, bottom: 404 },
      { id: "swan_fence_west_curve_2", left: 970, top: 391, right: 1026, bottom: 430 },
      { id: "swan_fence_west_curve_3", left: 1012, top: 416, right: 1077, bottom: 451 },
      { id: "swan_fence_southwest_curve", left: 1060, top: 438, right: 1137, bottom: 474 },
      { id: "swan_fence_south_west", left: 1120, top: 460, right: 1252, bottom: 493 },
      { id: "swan_fence_south_center", left: 1232, top: 475, right: 1372, bottom: 514 },
      { id: "swan_fence_southeast_curve", left: 1350, top: 487, right: 1428, bottom: 535 },
      { id: "swan_fence_east", left: 1402, top: 220, right: 1438, bottom: 535 },
      { id: "south_bank", left: 500, top: 760, right: 1450, bottom: 941 }
    ],
    waterAreas: [
      { id: "swan_basin", left: 28, top: 150, right: 1450, bottom: 913 }
    ],
    occlusions: [
      { id: "swan_enclosure", left: 920, top: 130, right: 1445, bottom: 590, sortY: 590 },
      { id: "east_willows", left: 1430, top: 180, right: 1672, bottom: 820, sortY: 820 }
    ]
  }
} as const;

const QIZHEN_ANY_FACING = ["up", "down", "left", "right"] as const;

const target = (
  definition: Omit<QizhenLakeInteractionTarget, "proximity"> & { proximity?: number }
): QizhenLakeInteractionTarget => ({
  proximity: 128,
  requiredFacing: QIZHEN_ANY_FACING,
  ...definition
});

export const QIZHEN_LAKE_TARGETS: readonly QizhenLakeInteractionTarget[] = [
  target({ id: "qizhen_dock_exit", label: "离开启真湖", x: 225, y: 845, kind: "exit", zone: "dock", vehicle: "on_foot", proximity: 72 }),
  target({ id: "qizhen_dock_kayak", label: "器材架上的皮划艇", x: 500, y: 780, width: 110, height: 80, stand: { x: 590, y: 790 }, kind: "outfit", value: "kayak", zone: "dock", vehicle: "on_foot", proximity: 56 }),
  target({ id: "qizhen_dock_left_paddle", label: "花坛边的柳树枝", x: 245, y: 570, width: 70, height: 30, stand: { x: 260, y: 635 }, kind: "outfit", value: "left_paddle", zone: "dock", vehicle: "on_foot", proximity: 52 }),
  target({ id: "qizhen_dock_right_paddle", label: "可拆的旧三角牌", x: 585, y: 780, width: 70, height: 70, stand: { x: 645, y: 805 }, kind: "outfit", value: "right_paddle", zone: "dock", vehicle: "on_foot", proximity: 52 }),
  target({ id: "qizhen_dock_board", label: "小码头登船边", x: 710, y: 650, width: 80, height: 120, stand: { x: 610, y: 650 }, kind: "board", zone: "dock", vehicle: "on_foot", proximity: 64 }),
  target({ id: "qizhen_use_item_1", label: "码头储物柜", x: 390, y: 750, width: 92, height: 100, stand: { x: 430, y: 835 }, kind: "item_use", zone: "dock", vehicle: "on_foot", proximity: 56, value: "item_1_to_2", dropWidth: 92, dropHeight: 100, requiredMode: "light", acceptedItem: "rustedLockerKey" }),
  target({ id: "qizhen_dock_to_open", label: "划向大湖", x: 1430, y: 390, kind: "zone_portal", zone: "dock", targetZone: "open_water", vehicle: "kayak", proximity: 155 }),

  target({ id: "qizhen_open_to_dock", label: "返回小码头", x: 560, y: 820, kind: "zone_portal", zone: "open_water", targetZone: "dock", vehicle: "kayak", proximity: 138 }),
  target({ id: "qizhen_open_to_swan", label: "前往黑天鹅围栏", x: 1510, y: 500, kind: "zone_portal", zone: "open_water", targetZone: "swan_cove", vehicle: "kayak", proximity: 150 }),
  target({ id: "qizhen_open_to_channel", label: "进入浮排河道", x: 620, y: 110, kind: "zone_portal", zone: "open_water", targetZone: "channel", vehicle: "kayak", proximity: 135 }),
  target({ id: "qizhen_reflection_paper", label: "纸条倒影位置", x: 1320, y: 330, kind: "reflection", zone: "open_water", vehicle: "kayak", proximity: 170, value: "paper" }),
  target({ id: "qizhen_reflection_item_1", label: "钥匙倒影位置", x: 1040, y: 620, kind: "reflection", zone: "open_water", vehicle: "kayak", proximity: 165, value: "locker_key" }),
  target({ id: "qizhen_reflection_item_3", label: "网框倒影位置", x: 910, y: 360, kind: "reflection", zone: "open_water", vehicle: "kayak", proximity: 165, value: "net_frame" }),
  target({ id: "qizhen_reflection_fish", label: "鱼群倒影位置", x: 705, y: 585, kind: "reflection", zone: "open_water", vehicle: "kayak", proximity: 170, value: "fish" }),
  target({ id: "qizhen_fishing_rod", label: "漂浮的钓鱼竿", x: 620, y: 520, kind: "fishing_spot", zone: "open_water", vehicle: "kayak", proximity: 160, value: "fishing_rod" }),
  target({ id: "qizhen_paper_reflection", label: "纸条倒影", x: 1320, y: 330, kind: "paper", zone: "open_water", vehicle: "kayak", proximity: 160, value: "paper_reflection", acceptedItem: "decoyPaper" }),
  target({ id: "qizhen_fishing_item_1", label: "倒影对应点一", x: 1040, y: 620, kind: "fishing_spot", zone: "open_water", vehicle: "kayak", proximity: 155, value: "item_1", acceptedItem: "fishingRod" }),
  target({ id: "qizhen_fishing_item_3", label: "旧木桩倒影", x: 910, y: 360, kind: "fishing_spot", zone: "open_water", vehicle: "kayak", proximity: 165, value: "item_3", acceptedItem: "fishingRod" }),
  target({ id: "qizhen_open_workbench", label: "浮标组合位", x: 840, y: 430, stand: { x: 840, y: 580 }, kind: "item_use", zone: "open_water", vehicle: "kayak", proximity: 165, value: "combine_net", dropWidth: 150, dropHeight: 110, requiredMode: "light", acceptedItems: ["nylonCord", "brokenNetFrame"] }),
  target({ id: "qizhen_fishing_fish", label: "鱼群水纹", x: 705, y: 585, kind: "fishing_spot", zone: "open_water", vehicle: "kayak", proximity: 170, value: "fish", acceptedItem: "fishFeedPellets" }),

  target({ id: "qizhen_swan_to_open", label: "返回大湖", x: 165, y: 510, kind: "zone_portal", zone: "swan_cove", targetZone: "open_water", vehicle: "kayak", proximity: 145 }),
  target({ id: "qizhen_swan_to_channel", label: "进入返航河道", x: 405, y: 840, kind: "zone_portal", zone: "swan_cove", targetZone: "channel", vehicle: "kayak", proximity: 150 }),
  target({ id: "qizhen_black_swan", label: "围栏里的黑天鹅", x: 1165, y: 470, width: 470, height: 220, stand: { x: 890, y: 505 }, kind: "swan", zone: "swan_cove", vehicle: "kayak", proximity: 180, value: "black_swan", dropWidth: 150, dropHeight: 110, requiredMode: "light", acceptedItem: "smallCarp" }),
  target({ id: "qizhen_swan_workbench", label: "船头磁吸组合位", x: 760, y: 520, stand: { x: 760, y: 660 }, kind: "item_use", zone: "swan_cove", vehicle: "kayak", proximity: 165, value: "combine_magnetic_rod", dropWidth: 96, dropHeight: 64, requiredMode: "light", acceptedItems: ["swanMagnet", "fishingRod"] }),
  target({ id: "qizhen_final_paper_cast", label: "纸条本体水纹", x: 760, y: 450, kind: "paper", zone: "swan_cove", vehicle: "kayak", proximity: 175, value: "paper_body", acceptedItem: "magneticFishingRod" }),

  target({ id: "qizhen_channel_from_swan", label: "黑天鹅追逐起点", x: 1515, y: 510, kind: "zone_portal", zone: "channel", targetZone: "swan_cove", vehicle: "kayak", proximity: 150 }),
  target({ id: "qizhen_channel_to_open", label: "返回大湖", x: 840, y: 735, kind: "zone_portal", zone: "channel", targetZone: "open_water", vehicle: "kayak", proximity: 145 }),
  target({ id: "qizhen_use_item_4", label: "浮排下的密封饲料盒", x: 640, y: 575, stand: { x: 790, y: 575 }, kind: "item_use", zone: "channel", vehicle: "kayak", proximity: 175, value: "item_4_to_5", dropWidth: 156, dropHeight: 112, requiredMode: "light", acceptedItem: "improvisedDipNet" }),
  target({ id: "qizhen_use_item_5", label: "浮排硬边开罐位", x: 640, y: 330, stand: { x: 790, y: 330 }, kind: "item_use", zone: "channel", vehicle: "kayak", proximity: 175, value: "item_5_to_6", dropWidth: 156, dropHeight: 104, requiredMode: "light", acceptedItem: "sealedFeedTin" }),
  target({ id: "qizhen_channel_escape", label: "小码头方向", x: 105, y: 510, kind: "escape", zone: "channel", targetZone: "dock", vehicle: "kayak", proximity: 145 })
] as const;

export function targetsForQizhenZone(
  zone: QizhenLakeZoneId,
  vehicle: QizhenLakeVehicle
): QizhenLakeInteractionTarget[] {
  return QIZHEN_LAKE_TARGETS.filter((candidate) => (
    candidate.zone === zone && (!candidate.vehicle || candidate.vehicle === vehicle)
  ));
}

export function qizhenTargetAcceptsItem(target: QizhenLakeInteractionTarget, itemId: ItemId): boolean {
  return target.acceptedItem === itemId || target.acceptedItems?.includes(itemId) === true;
}

export function findNearestQizhenTarget(
  x: number,
  y: number,
  targets: readonly QizhenLakeInteractionTarget[]
): QizhenLakeInteractionTarget | null {
  let nearest: QizhenLakeInteractionTarget | null = null;
  let bestDistance = Number.POSITIVE_INFINITY;
  targets.forEach((candidate) => {
    const distance = distanceFromPlayerToRpgTarget(candidate, x, y);
    if (isPlayerWithinRpgTarget(candidate, x, y) && distance < bestDistance) {
      nearest = candidate;
      bestDistance = distance;
    }
  });
  return nearest;
}

export function clampKayakToWater(
  zone: QizhenLakeZoneId,
  x: number,
  y: number
): { x: number; y: number; contained: boolean } {
  const areas = QIZHEN_LAKE_ZONES[zone].waterAreas;
  const containedArea = areas.find((area) => x >= area.left && x <= area.right && y >= area.top && y <= area.bottom);
  if (containedArea) return { x, y, contained: true };
  let closest = { x, y, distance: Number.POSITIVE_INFINITY };
  areas.forEach((area) => {
    const clampedX = Math.max(area.left, Math.min(area.right, x));
    const clampedY = Math.max(area.top, Math.min(area.bottom, y));
    const distance = Math.hypot(x - clampedX, y - clampedY);
    if (distance < closest.distance) closest = { x: clampedX, y: clampedY, distance };
  });
  return { x: closest.x, y: closest.y, contained: false };
}

/**
 * 拍照取景站位区域(源像素)。每块区域都对着本区已有碰撞/水域数据
 * 校过:kayak 区域落在水域内且不压任何船体碰撞;on_foot 区域落在
 * 码头可步行陆地上。
 */
export interface QizhenLakePhotoSpotRect {
  left: number;
  top: number;
  right: number;
  bottom: number;
}

export interface QizhenLakePhotoSpot {
  id: QizhenPhotoSpotId;
  zone: QizhenLakeZoneId;
  /** 拍摄点名称,用于场景内提示文案。 */
  label: string;
  /** 建议站位区域;dock 点含 kayak 与 on_foot 两块,两类站位不会互相到达。 */
  standAreas: readonly QizhenLakePhotoSpotRect[];
  /** 取景裁切中心建议(源像素)。 */
  cropCenter: { x: number; y: number };
  /** 默认缩放档位;dock 视野更宽,取 0。 */
  defaultZoomStep: 0 | 1 | 2;
  /** 主体可见范围说明。 */
  subjectFramingNote: string;
}

export const QIZHEN_LAKE_PHOTO_SPOTS: Readonly<Record<QizhenPhotoSpotId, QizhenLakePhotoSpot>> = {
  lake_center: {
    id: "lake_center",
    zone: "open_water",
    label: "湖心",
    // 大湖面中部开阔水带:西北柳岛(右界 575)、北河道岸(底界 180)、
    // 东南浮筒桩(左界 1020)、南岸(顶界 810)都不压;在 open_basin 水域内。
    standAreas: [{ left: 700, top: 380, right: 980, bottom: 560 }],
    cropCenter: { x: 836, y: 430 },
    defaultZoomStep: 1,
    subjectFramingNote: "湖心全景:朝北取景时西北柳岛与整片开阔水面入镜,船体落在画面下缘。"
  },
  dock: {
    id: "dock",
    zone: "dock",
    label: "小码头",
    standAreas: [
      // kayak:码头北侧水面,dock_walkway(顶界 430)与 west_land(右界 610)之外,
      // 在 dock_basin 水域内。
      { left: 660, top: 150, right: 1080, bottom: 380 },
      // on_foot:栈道步行段,shore_water(底界 555)、pier_east_water(左界 790)、
      // south_planter(顶界 795)之间,与登船边站位相邻。
      { left: 632, top: 560, right: 788, bottom: 700 }
    ],
    cropCenter: { x: 704, y: 540 },
    defaultZoomStep: 0,
    subjectFramingNote: "小码头:木栈道、器材架与登船边入镜;徒步或乘艇都可取景。"
  },
  reflection: {
    id: "reflection",
    zone: "open_water",
    label: "倒影水面",
    // 大湖面东侧倒影水带,与 lake_center 站位不重叠:北河道岸(右界 980)以东、
    // 浮筒桩(顶界 520)以北;靠近纸条倒影目标 (1320, 330)。
    standAreas: [{ left: 1150, top: 250, right: 1420, bottom: 460 }],
    cropCenter: { x: 1290, y: 350 },
    defaultZoomStep: 1,
    subjectFramingNote: "倒影水面:东侧倒影区入镜;水面平静时倒影完整,船速与侧倾大时水纹断开。"
  },
  swan_cove: {
    id: "swan_cove",
    zone: "swan_cove",
    label: "黑天鹅围栏",
    // 围栏外侧水域(西侧):swan_fence_west_upper(底界 383)以南、
    // swan_fence_west_curve_2(左界 970)以西、south_bank(顶界 760)以北,
    // 与喂鹅站位 (890, 505) 相邻;在 swan_basin 水域内。
    standAreas: [{ left: 700, top: 420, right: 900, bottom: 560 }],
    cropCenter: { x: 1165, y: 430 },
    defaultZoomStep: 1,
    subjectFramingNote: "黑天鹅围栏:从围栏外水域取景,黑天鹅在围栏内游动;鹅离开后只剩空围栏与水痕。"
  }
} as const;

export function qizhenPhotoSpotsForZone(zone: QizhenLakeZoneId): QizhenLakePhotoSpot[] {
  return Object.values(QIZHEN_LAKE_PHOTO_SPOTS).filter((spot) => spot.zone === zone);
}

/**
 * 站位解析:位置落在某拍摄点任一站位区域内即返回该点;open_water 内
 * lake_center 与 reflection 用两块不相交子区域区分。
 */
export function resolveQizhenPhotoSpot(
  zone: QizhenLakeZoneId,
  kayakX: number,
  kayakY: number
): QizhenPhotoSpotId | null {
  const spots = qizhenPhotoSpotsForZone(zone);
  for (const spot of spots) {
    const hit = spot.standAreas.some((area) => (
      kayakX >= area.left && kayakX <= area.right && kayakY >= area.top && kayakY <= area.bottom
    ));
    if (hit) return spot.id;
  }
  return null;
}

/** 距当前位置最近的拍摄点(按站位区域中心),用于"去最近拍摄点"提示。 */
export function nearestQizhenPhotoSpot(
  zone: QizhenLakeZoneId,
  x: number,
  y: number
): QizhenLakePhotoSpot | null {
  let nearest: QizhenLakePhotoSpot | null = null;
  let bestDistance = Number.POSITIVE_INFINITY;
  qizhenPhotoSpotsForZone(zone).forEach((spot) => {
    spot.standAreas.forEach((area) => {
      const centerX = (area.left + area.right) / 2;
      const centerY = (area.top + area.bottom) / 2;
      const distance = Math.hypot(x - centerX, y - centerY);
      if (distance < bestDistance) {
        bestDistance = distance;
        nearest = spot;
      }
    });
  });
  return nearest;
}

export interface QizhenPhotoRecipeInput {
  kayakX: number;
  kayakY: number;
  /** 船头朝向(弧度,y 向下)。 */
  heading: number;
  /** 船到黑天鹅的真实距离(源像素);"gone" 表示黑天鹅已离开。 */
  swanDistance?: number | "gone";
  /** 水面可读性:boolean 或 0–1 的清晰度(1 平静清晰,0 完全打散)。 */
  rippleVisible?: boolean | number;
}

/** 朝向量化到八方位:0 = 东(+x),2 = 南(+y),4 = 西,6 = 北。 */
export function quantizeQizhenPhotoHeading(heading: number): QizhenPhotoRecipe["headingBucket"] {
  const bucket = ((Math.round(heading / (Math.PI / 4)) % 8) + 8) % 8;
  return bucket as QizhenPhotoRecipe["headingBucket"];
}

export function bucketQizhenSwanDistance(
  swanDistance: QizhenPhotoRecipeInput["swanDistance"]
): QizhenPhotoRecipe["swanDistanceBucket"] | undefined {
  if (swanDistance === undefined) return undefined;
  if (swanDistance === "gone" || !Number.isFinite(swanDistance)) return "gone";
  // swan_cove 站位区 (700,420)–(900,560) 到天鹅锚点 (1160,400) 的可达距离带约
  // 261–487 源像素:阈值必须落在带内,near/far 标签才真实可达。
  if (swanDistance < 330) return "near";
  if (swanDistance < 430) return "mid";
  return "far";
}

export function bucketQizhenRippleClarity(
  rippleVisible: QizhenPhotoRecipeInput["rippleVisible"]
): QizhenPhotoRecipe["rippleClarityBucket"] | undefined {
  if (rippleVisible === undefined) return undefined;
  const clarity = typeof rippleVisible === "boolean" ? (rippleVisible ? 1 : 0) : rippleVisible;
  if (clarity >= 0.66) return "clear";
  if (clarity >= 0.33) return "partial";
  return "lost";
}

export function buildQizhenPhotoRecipe(
  spotId: QizhenPhotoSpotId,
  input: QizhenPhotoRecipeInput
): QizhenPhotoRecipe {
  const spot = QIZHEN_LAKE_PHOTO_SPOTS[spotId];
  const recipe: QizhenPhotoRecipe = {
    zone: spot.zone,
    cropCenterX: spot.cropCenter.x,
    cropCenterY: spot.cropCenter.y,
    zoomStep: spot.defaultZoomStep,
    kayakX: Math.round(input.kayakX),
    kayakY: Math.round(input.kayakY),
    headingBucket: quantizeQizhenPhotoHeading(input.heading)
  };
  const swanDistanceBucket = bucketQizhenSwanDistance(input.swanDistance);
  if (swanDistanceBucket) recipe.swanDistanceBucket = swanDistanceBucket;
  const rippleClarityBucket = bucketQizhenRippleClarity(input.rippleVisible);
  if (rippleClarityBucket) recipe.rippleClarityBucket = rippleClarityBucket;
  return recipe;
}
