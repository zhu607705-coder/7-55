import {
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
      { id: "dock_walkway_front", left: 620, top: 450, right: 790, bottom: 688, sortY: 688 },
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
    kayakSpawn: { x: 1390, y: 505, heading: Math.PI },
    kayakEntrySpawns: {
      swan_cove: { x: 1390, y: 510, heading: Math.PI },
      open_water: { x: 840, y: 755, heading: -Math.PI / 2 },
      dock: { x: 120, y: 510, heading: 0 }
    },
    onFootCollisions: [FULL_LEFT, FULL_RIGHT, FULL_TOP, FULL_BOTTOM],
    kayakCollisions: [
      FULL_LEFT,
      FULL_RIGHT,
      FULL_TOP,
      FULL_BOTTOM,
      { id: "north_bank", left: 0, top: 0, right: 1672, bottom: 180 },
      { id: "south_bank", left: 0, top: 780, right: 1672, bottom: 941 },
      { id: "floating_raft", left: 545, top: 360, right: 735, bottom: 555 },
      { id: "west_net", left: 430, top: 420, right: 535, bottom: 560 },
      { id: "right_dock", left: 1530, top: 438, right: 1672, bottom: 570 }
    ],
    waterAreas: [
      { id: "straight_channel", left: 28, top: 180, right: 1644, bottom: 780 }
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
      { id: "swan_enclosure", left: 930, top: 155, right: 1435, bottom: 565 },
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

const target = (
  definition: Omit<QizhenLakeInteractionTarget, "proximity"> & { proximity?: number }
): QizhenLakeInteractionTarget => ({ proximity: 128, ...definition });

export const QIZHEN_LAKE_TARGETS: readonly QizhenLakeInteractionTarget[] = [
  target({ id: "qizhen_dock_exit", label: "离开启真湖", x: 225, y: 845, kind: "exit", zone: "dock", vehicle: "on_foot" }),
  target({ id: "qizhen_dock_kayak", label: "器材架上的皮划艇", x: 500, y: 780, stand: { x: 590, y: 790 }, kind: "outfit", value: "kayak", zone: "dock", vehicle: "on_foot", proximity: 108 }),
  target({ id: "qizhen_dock_left_paddle", label: "花坛边的柳树枝", x: 245, y: 570, stand: { x: 260, y: 635 }, kind: "outfit", value: "left_paddle", zone: "dock", vehicle: "on_foot", proximity: 96 }),
  target({ id: "qizhen_dock_right_paddle", label: "可拆的旧三角牌", x: 585, y: 780, stand: { x: 645, y: 805 }, kind: "outfit", value: "right_paddle", zone: "dock", vehicle: "on_foot", proximity: 94 }),
  target({ id: "qizhen_dock_board", label: "小码头上船位", x: 710, y: 650, stand: { x: 610, y: 650 }, kind: "board", zone: "dock", vehicle: "on_foot", proximity: 126 }),
  target({ id: "qizhen_use_item_1", label: "码头储物柜", x: 390, y: 750, stand: { x: 430, y: 835 }, kind: "item_use", zone: "dock", vehicle: "on_foot", proximity: 118, value: "item_1_to_2", dropWidth: 118, dropHeight: 104, requiredMode: "light", acceptedItem: "rustedLockerKey" }),
  target({ id: "qizhen_dock_to_open", label: "划向大湖", x: 1430, y: 390, kind: "zone_portal", zone: "dock", targetZone: "open_water", vehicle: "kayak", proximity: 155 }),

  target({ id: "qizhen_open_to_dock", label: "返回小码头", x: 560, y: 820, kind: "zone_portal", zone: "open_water", targetZone: "dock", vehicle: "kayak", proximity: 138 }),
  target({ id: "qizhen_open_to_swan", label: "前往黑天鹅围栏", x: 1510, y: 500, kind: "zone_portal", zone: "open_water", targetZone: "swan_cove", vehicle: "kayak", proximity: 150 }),
  target({ id: "qizhen_open_to_channel", label: "进入浮排河道", x: 620, y: 110, kind: "zone_portal", zone: "open_water", targetZone: "channel", vehicle: "kayak", proximity: 135 }),
  target({ id: "qizhen_reflection_paper", label: "纸条倒影位置", x: 1320, y: 330, kind: "reflection", zone: "open_water", vehicle: "kayak", proximity: 170, value: "paper" }),
  target({ id: "qizhen_reflection_item_1", label: "钥匙倒影位置", x: 1040, y: 620, kind: "reflection", zone: "open_water", vehicle: "kayak", proximity: 165, value: "locker_key" }),
  target({ id: "qizhen_reflection_item_3", label: "网框倒影位置", x: 910, y: 360, kind: "reflection", zone: "open_water", vehicle: "kayak", proximity: 165, value: "net_frame" }),
  target({ id: "qizhen_reflection_fish", label: "鱼群倒影位置", x: 705, y: 585, kind: "reflection", zone: "open_water", vehicle: "kayak", proximity: 170, value: "fish" }),
  target({ id: "qizhen_fishing_rod", label: "漂浮的钓鱼竿", x: 620, y: 520, kind: "fishing_spot", zone: "open_water", vehicle: "kayak", proximity: 160, value: "fishing_rod" }),
  target({ id: "qizhen_paper_reflection", label: "纸条倒影", x: 1320, y: 330, kind: "paper", zone: "open_water", vehicle: "kayak", proximity: 160, value: "paper_reflection" }),
  target({ id: "qizhen_fishing_item_1", label: "倒影对应点一", x: 1040, y: 620, kind: "fishing_spot", zone: "open_water", vehicle: "kayak", proximity: 155, value: "item_1" }),
  target({ id: "qizhen_fishing_item_3", label: "旧木桩倒影", x: 910, y: 360, kind: "fishing_spot", zone: "open_water", vehicle: "kayak", proximity: 165, value: "item_3" }),
  target({ id: "qizhen_open_workbench", label: "浮标组合位", x: 840, y: 430, kind: "item_use", zone: "open_water", vehicle: "kayak", proximity: 165, value: "combine_net" }),
  target({ id: "qizhen_fishing_fish", label: "鱼群水纹", x: 705, y: 585, kind: "fishing_spot", zone: "open_water", vehicle: "kayak", proximity: 170, value: "fish" }),

  target({ id: "qizhen_swan_to_open", label: "返回大湖", x: 165, y: 510, kind: "zone_portal", zone: "swan_cove", targetZone: "open_water", vehicle: "kayak", proximity: 145 }),
  target({ id: "qizhen_swan_to_channel", label: "进入返航河道", x: 405, y: 840, kind: "zone_portal", zone: "swan_cove", targetZone: "channel", vehicle: "kayak", proximity: 150 }),
  target({ id: "qizhen_black_swan", label: "围栏里的黑天鹅", x: 1165, y: 470, stand: { x: 890, y: 505 }, kind: "swan", zone: "swan_cove", vehicle: "kayak", proximity: 190, value: "black_swan" }),
  target({ id: "qizhen_swan_workbench", label: "船头磁吸组合位", x: 760, y: 520, kind: "item_use", zone: "swan_cove", vehicle: "kayak", proximity: 165, value: "combine_magnetic_rod" }),
  target({ id: "qizhen_final_paper_cast", label: "纸条本体水纹", x: 760, y: 450, kind: "paper", zone: "swan_cove", vehicle: "kayak", proximity: 175, value: "paper_body" }),

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

export function findNearestQizhenTarget(
  x: number,
  y: number,
  targets: readonly QizhenLakeInteractionTarget[]
): QizhenLakeInteractionTarget | null {
  let nearest: QizhenLakeInteractionTarget | null = null;
  let bestDistance = Number.POSITIVE_INFINITY;
  targets.forEach((candidate) => {
    const stand = candidate.stand ?? candidate;
    const distance = Math.hypot(x - stand.x, y - stand.y);
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
