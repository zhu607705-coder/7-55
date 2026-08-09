import type { CanteenExitId } from "../../core/types";
import {
  isPlayerWithinRpgTarget,
  type RpgSpatialInteractionTarget
} from "./RpgInteractionContract";

export const CANTEEN_INTERIOR_WORLD = {
  width: 1672,
  height: 941
} as const;

export interface CanteenCollisionRect {
  id: string;
  left: number;
  top: number;
  right: number;
  bottom: number;
}

export interface CanteenOcclusionRect extends CanteenCollisionRect {
  sortY: number;
}

const TABLE_COLUMNS = [227, 376, 525, 675, 831, 985, 1144] as const;
const TABLE_ROWS = [361, 470, 579] as const;

// Bounds are authored once against canteen_interior.png (1672 x 941).
// Furniture colliders follow the painted solid area. Canteen traversal uses a
// small foot-point body, so narrow visible aisles remain usable without allowing
// the character to walk through chairs, tables or counter fronts.
export const CANTEEN_STATIC_COLLISION_RECTS: readonly CanteenCollisionRect[] = [
  { id: "north_service_wall", left: 126, top: 15, right: 1314, bottom: 241 },
  { id: "north_drink_wall", left: 1314, top: 14, right: 1643, bottom: 224 },
  { id: "west_wall_upper", left: 24, top: 16, right: 69, bottom: 191 },
  { id: "west_wall_lower", left: 27, top: 308, right: 54, bottom: 920 },
  { id: "east_wall", left: 1618, top: 18, right: 1647, bottom: 920 },
  { id: "west_planter_strip", left: 34, top: 314, right: 74, bottom: 547 },
  // Keep roughly a 25 px aisle between the drink wall and the shelf. The small
  // extra margin lets the player's foot collider pass without making it look wide.
  { id: "north_lost_found_shelf", left: 1350, top: 252, right: 1618, bottom: 379 },
  { id: "dish_return", left: 1260, top: 425, right: 1628, bottom: 592 },
  { id: "tray_station", left: 1253, top: 619, right: 1630, bottom: 760 },
  { id: "ordering_kiosks", left: 93, top: 676, right: 474, bottom: 850 },
  { id: "pickup_counter", left: 543, top: 679, right: 1088, bottom: 872 },
  { id: "pickup_left_pillar", left: 542, top: 662, right: 578, bottom: 872 },
  { id: "pickup_right_pillar", left: 1050, top: 664, right: 1105, bottom: 907 },
  { id: "southeast_wall_west_upper", left: 1155, top: 655, right: 1195, bottom: 700 },
  { id: "southeast_wall_west_lower", left: 1450, top: 354, right: 1483, bottom: 410 },
  { id: "southeast_wall_east", left: 1254, top: 760, right: 1643, bottom: 925 },
  { id: "table_1_1", left: 179, top: 315, right: 273, bottom: 401 },
  { id: "table_1_2", left: 329, top: 314, right: 423, bottom: 402 },
  { id: "table_1_3", left: 478, top: 314, right: 572, bottom: 401 },
  { id: "table_1_4", left: 628, top: 314, right: 722, bottom: 402 },
  { id: "table_1_5", left: 786, top: 317, right: 880, bottom: 402 },
  { id: "table_1_6", left: 940, top: 317, right: 1034, bottom: 402 },
  { id: "table_1_7", left: 1098, top: 318, right: 1192, bottom: 403 },
  { id: "table_2_1", left: 180, top: 432, right: 274, bottom: 512 },
  { id: "table_2_2", left: 329, top: 434, right: 423, bottom: 511 },
  { id: "table_2_3", left: 478, top: 431, right: 572, bottom: 512 },
  { id: "table_2_4", left: 628, top: 434, right: 722, bottom: 514 },
  { id: "table_2_5", left: 784, top: 432, right: 878, bottom: 512 },
  { id: "table_2_6", left: 941, top: 437, right: 1035, bottom: 510 },
  { id: "table_2_7", left: 1099, top: 434, right: 1193, bottom: 509 },
  { id: "table_3_1", left: 182, top: 543, right: 276, bottom: 621 },
  { id: "table_3_2", left: 331, top: 542, right: 425, bottom: 623 },
  { id: "table_3_3", left: 478, top: 545, right: 572, bottom: 623 },
  { id: "table_3_4", left: 633, top: 544, right: 727, bottom: 624 },
  { id: "table_3_5", left: 788, top: 544, right: 882, bottom: 624 },
  { id: "table_3_6", left: 941, top: 543, right: 1035, bottom: 622 },
  { id: "table_3_7", left: 1101, top: 544, right: 1195, bottom: 620 }
] as const;

// Only the visible front faces are redrawn above the actor. The source map remains the
// visual authority; these crops add depth sorting without introducing invisible cover.
export const CANTEEN_OCCLUSION_RECTS: readonly CanteenOcclusionRect[] = [
  { id: "lost_found_front", left: 1344, top: 253, right: 1618, bottom: 407, sortY: 407 },
  { id: "dish_return_front", left: 1260, top: 425, right: 1628, bottom: 585, sortY: 585 },
  { id: "tray_station_front", left: 1258, top: 620, right: 1629, bottom: 761, sortY: 761 },
  { id: "ordering_kiosks_front", left: 51, top: 682, right: 469, bottom: 846, sortY: 846 },
  { id: "pickup_counter_front", left: 542, top: 688, right: 1087, bottom: 876, sortY: 876 },
  // Keep the doorway clear. The two wall frames still occlude the actor, while the
  // middle opening remains readable and walkable when entering or leaving the canteen.
  { id: "southeast_exit_west_frame", left: 1252, top: 760, right: 1310, bottom: 934, sortY: 934 },
  { id: "southeast_exit_east_frame", left: 1450, top: 760, right: 1643, bottom: 934, sortY: 934 },
  ...TABLE_ROWS.flatMap((y, rowIndex) => TABLE_COLUMNS.map((x, columnIndex) => ({
    id: `table_front_${rowIndex + 1}_${columnIndex + 1}`,
    left: x - 49,
    top: y - 50,
    right: x + 49,
    bottom: y + 50,
    sortY: y + 50
  })))
] as const;

export interface CanteenTrayDefinition {
  id: string;
  target: boolean;
}

export interface CanteenTraySlot {
  tableId: string;
  x: number;
  y: number;
  stand: { x: number; y: number };
}

// These are the fourteen tables without seated NPCs. Every table contributes four
// tabletop-corner slots, so one table can naturally hold up to four abandoned plates.
const CANTEEN_EMPTY_TABLES = [
  { id: "table_1_1", x: 227, y: 350 },
  { id: "table_1_3", x: 525, y: 350 },
  { id: "table_1_4", x: 675, y: 350 },
  { id: "table_1_6", x: 987, y: 350 },
  { id: "table_1_7", x: 1145, y: 350 },
  { id: "table_2_2", x: 376, y: 459 },
  { id: "table_2_4", x: 675, y: 459 },
  { id: "table_2_5", x: 831, y: 459 },
  { id: "table_2_7", x: 1146, y: 459 },
  { id: "table_3_1", x: 229, y: 568 },
  { id: "table_3_2", x: 378, y: 568 },
  { id: "table_3_4", x: 680, y: 568 },
  { id: "table_3_5", x: 835, y: 568 },
  { id: "table_3_7", x: 1148, y: 568 }
] as const;

const CANTEEN_TRAY_CORNER_OFFSETS = [
  // After the 90-degree rotation, the visible plate is about 10 x 17 px on a
  // 46 x 71 px tabletop. These offsets leave an even ~5 px inset on both edges.
  { x: -13, y: -22, standSide: "left" },
  { x: 13, y: -22, standSide: "right" },
  { x: -13, y: 22, standSide: "left" },
  { x: 13, y: 22, standSide: "right" }
] as const;

export const CANTEEN_TRAY_SLOTS: readonly CanteenTraySlot[] = CANTEEN_EMPTY_TABLES.flatMap((table) => (
  CANTEEN_TRAY_CORNER_OFFSETS.map((corner) => ({
    tableId: table.id,
    x: table.x + corner.x,
    y: table.y + corner.y,
    stand: {
      x: table.x + (corner.standSide === "left" ? -72 : 72),
      y: table.y + corner.y
    }
  }))
));

// Runtime placement randomly assigns these twelve ids to twelve distinct corner
// slots. The target ids therefore remain invisible in light mode.
export const CANTEEN_TRAYS: readonly CanteenTrayDefinition[] = [
  { id: "tray_blue_01", target: true },
  { id: "tray_plain_01", target: false },
  { id: "tray_plain_02", target: false },
  { id: "tray_plain_03", target: false },
  { id: "tray_plain_04", target: false },
  { id: "tray_plain_05", target: false },
  { id: "tray_plain_06", target: false },
  { id: "tray_blue_02", target: true },
  { id: "tray_plain_07", target: false },
  { id: "tray_plain_08", target: false },
  { id: "tray_plain_09", target: false },
  { id: "tray_blue_03", target: true }
] as const;

export interface CanteenInteractionTarget extends RpgSpatialInteractionTarget {
  kind:
    | "tray"
    | "kiosk"
    | "pickup"
    | "cart"
    | "exit"
    | "npc"
    | "drink_machine"
    | "drink_shelf"
    | "mixer"
    | "promo"
    | "queue_gap";
  value?: string;
  dialogue?: string;
}

export const CANTEEN_DRINK_MACHINES: readonly CanteenInteractionTarget[] = [
  {
    id: "drink-machine-sparkling",
    label: "蓝色饮料机",
    x: 1421,
    y: 148,
    stand: { x: 1421, y: 208 },
    proximity: 48,
    kind: "drink_machine",
    value: "sparklingWater"
  },
  {
    id: "drink-machine-lemon",
    label: "白色饮料机",
    x: 1473,
    y: 148,
    stand: { x: 1473, y: 208 },
    proximity: 48,
    kind: "drink_machine",
    value: "lemonTea"
  },
  {
    id: "drink-machine-coffee",
    label: "黑色饮料机",
    x: 1525,
    y: 148,
    stand: { x: 1525, y: 208 },
    proximity: 48,
    kind: "drink_machine",
    value: "blackCoffee"
  }
] as const;

export const CANTEEN_DRINK_SHELF: CanteenInteractionTarget = {
  id: "drink-bottle-shelf",
  label: "查看右侧瓶罐架",
  x: 1425,
  y: 315,
  stand: { x: 1320, y: 400 },
  proximity: 72,
  kind: "drink_shelf"
};

export const CANTEEN_MIX_STATION: CanteenInteractionTarget = {
  id: "canteen-mixer",
  label: "使用混合台",
  x: 260,
  y: 760,
  stand: { x: 260, y: 870 },
  proximity: 76,
  kind: "mixer"
};

export const CANTEEN_PROMO_BOARD: CanteenInteractionTarget = {
  id: "canteen-promo-board",
  label: "第五个窗口宣传灯箱空杯位",
  x: 1232,
  y: 130,
  stand: { x: 1232, y: 285 },
  proximity: 64,
  dropWidth: 150,
  dropHeight: 100,
  acceptedItem: "dailySpecialSparklingWater",
  requiredMode: "light",
  kind: "promo"
};

export const CANTEEN_QUEUE_COLUMN_THREE: CanteenInteractionTarget = {
  id: "queue-column-three-front",
  label: "询问第三列第一个同学",
  x: 790,
  y: 246,
  stand: { x: 735, y: 255 },
  proximity: 62,
  kind: "queue_gap"
};

export interface CanteenPickupWindowDefinition extends CanteenInteractionTarget {
  kind: "pickup";
  value: "1" | "2" | "3" | "4" | "5";
}

export interface CanteenServiceWindowDefinition {
  id: string;
  value: CanteenPickupWindowDefinition["value"];
  x: number;
  counterNpc: { x: number; y: number };
  queueNpcPositions: readonly { x: number; y: number }[];
}

// 新版过场统一读取这张窗口坐标表；实际交互规则仍使用旧版定义。
export const CANTEEN_SERVICE_WINDOWS: readonly CanteenServiceWindowDefinition[] = (
  [
    ["1", 301],
    ["2", 550],
    ["3", 790],
    ["4", 1035],
    ["5", 1235]
  ] as const
).map(([value, x]) => ({
  id: `canteen-service-window-${value}`,
  value,
  x,
  counterNpc: { x, y: 214 },
  queueNpcPositions: [246, 266, 286].map((y) => ({ x, y }))
}));

// The pickup route uses all five bays of the north service counter.
// Window 3 shares the ghost-auntie and paper-burst beat.
// Every coordinate below is in the source image's 1672 x 941 pixel system.
export const CANTEEN_PICKUP_WINDOWS: readonly CanteenPickupWindowDefinition[] = [
  {
    id: "pickup_window_1",
    label: "1号取餐窗口验票槽",
    x: 301,
    y: 218,
    stand: { x: 301, y: 260 },
    proximity: 58,
    dropWidth: 140,
    dropHeight: 74,
    kind: "pickup",
    value: "1"
  },
  {
    id: "pickup_window_2",
    label: "2号取餐窗口验票槽",
    x: 550,
    y: 218,
    stand: { x: 550, y: 260 },
    proximity: 58,
    dropWidth: 140,
    dropHeight: 74,
    kind: "pickup",
    value: "2"
  },
  {
    id: "pickup_window_3",
    label: "3号取餐窗口验票槽",
    x: 790,
    y: 218,
    stand: { x: 790, y: 260 },
    proximity: 58,
    dropWidth: 140,
    dropHeight: 74,
    kind: "pickup",
    value: "3"
  },
  {
    id: "pickup_window_4",
    label: "4号取餐窗口验票槽",
    x: 1035,
    y: 218,
    stand: { x: 1035, y: 260 },
    proximity: 58,
    dropWidth: 140,
    dropHeight: 74,
    kind: "pickup",
    value: "4"
  },
  {
    id: "pickup_window_5",
    label: "5号取餐窗口验票槽",
    x: 1235,
    y: 218,
    stand: { x: 1235, y: 260 },
    proximity: 58,
    dropWidth: 140,
    dropHeight: 74,
    kind: "pickup",
    value: "5"
  }
] as const;

export interface CanteenCartDefinition {
  exitId: CanteenExitId;
  x: number;
  y: number;
  /** Player offset from the trolley origin while both hands stay on the rear handle. */
  handleOffsetX: number;
  handleOffsetY: number;
  standX: number;
  standY: number;
  pushToX: number;
  pushToY: number;
  proximity: number;
  /** Source-pixel movement speed. All routes use the same readable walking cadence. */
  pushSpeed: number;
}

// Each trolley owns an explicit rear-handle offset. The scene keeps the player at
// that offset while rolling, so the cart never pulls the player from its centre.
export const CANTEEN_CARTS: Readonly<Record<CanteenExitId, CanteenCartDefinition>> = {
  west: {
    exitId: "west",
    x: 150,
    y: 287,
    // After the westbound flip, the rear U-handle sits on the cart's right
    // edge. Keep the actor's hand close to that edge instead of leaving a gap.
    handleOffsetX: 54,
    handleOffsetY: -19,
    standX: 204,
    standY: 268,
    pushToX: 82,
    // The paper crosses the west service opening at y=250. Park the trolley
    // on that same line so the visible cart covers the interception point.
    pushToY: 250,
    proximity: 70,
    pushSpeed: 112
  },
  southeast: {
    exitId: "southeast",
    x: 1198,
    y: 824,
    handleOffsetX: -56,
    handleOffsetY: -20,
    standX: 1142,
    standY: 804,
    pushToX: 1368,
    pushToY: 852,
    proximity: 70,
    pushSpeed: 118
  },
  steam: {
    exitId: "steam",
    x: 1212,
    y: 300,
    handleOffsetX: 15,
    handleOffsetY: 56,
    standX: 1227,
    standY: 356,
    pushToX: 1212,
    pushToY: 245,
    proximity: 70,
    pushSpeed: 108
  }
};

export const CANTEEN_INTERACTION_TARGETS: readonly CanteenInteractionTarget[] = [
  // The queue makes room directly in front of the third service window. That
  // window is the point-of-order machine as well as the later pickup route.
  {
    id: "ordering_kiosk",
    label: "第三窗口点餐机",
    x: 790,
    y: 218,
    stand: { x: 790, y: 260 },
    proximity: 58,
    kind: "kiosk"
  },
  ...CANTEEN_PICKUP_WINDOWS,
  ...Object.values(CANTEEN_CARTS).map((cart) => ({
    id: `cart_${cart.exitId}`,
    label: `${cart.exitId}出口餐盘车`,
    x: cart.x,
    y: cart.y,
    stand: { x: cart.standX, y: cart.standY },
    proximity: cart.proximity,
    kind: "cart" as const,
    value: cart.exitId
  })),
  {
    id: "southeast_exit",
    label: "食堂东南出口",
    x: 1380,
    y: 835,
    stand: { x: 1380, y: 835 },
    proximity: 100,
    kind: "exit"
  }
] as const;

export const CANTEEN_ESCAPE_ANCHORS: Record<CanteenExitId, { x: number; y: number }> = {
  west: { x: 82, y: 250 },
  southeast: { x: 1381, y: 853 },
  steam: { x: 1235, y: 227 }
};

// This is the clear inner lobby directly west of the southeast doors. It avoids
// spawning the actor beneath the doorway art or inside a static collision rect.
export const CANTEEN_SPAWN = { x: 1194, y: 834 } as const;
export const CANTEEN_PHASE_SPAWNS = {
  tray_search: CANTEEN_SPAWN,
  drink_mix: { x: 1473, y: 208 },
  menu_order: { x: 790, y: 260 },
  pickup_search: {
    x: CANTEEN_PICKUP_WINDOWS[2].stand!.x,
    y: CANTEEN_PICKUP_WINDOWS[2].stand!.y
  },
  exit_blocking: { x: CANTEEN_CARTS.southeast.standX, y: CANTEEN_CARTS.southeast.standY }
} as const;
export const CANTEEN_BLOCK_SPAWNS = [
  CANTEEN_PHASE_SPAWNS.exit_blocking,
  { x: CANTEEN_CARTS.steam.standX, y: CANTEEN_CARTS.steam.standY },
  { x: CANTEEN_CARTS.west.standX, y: CANTEEN_CARTS.west.standY }
] as const;
export const CANTEEN_RETURN_POINT = { x: 1222, y: 520 } as const;

export function findNearestCanteenTarget(
  x: number,
  y: number,
  targets: readonly CanteenInteractionTarget[]
): CanteenInteractionTarget | null {
  let nearest: CanteenInteractionTarget | null = null;
  let nearestDistance = Number.POSITIVE_INFINITY;
  targets.forEach((target) => {
    // Pickup windows only require getting close to the counter itself. Their
    // former stand coordinates remain visual layout data, not a movement gate.
    const interactionPoint = target.kind === "pickup" ? target : target.stand ?? target;
    const distance = Math.hypot(x - interactionPoint.x, y - interactionPoint.y);
    const withinRange = target.kind === "pickup"
      ? distance <= target.proximity
      : isPlayerWithinRpgTarget(target, x, y);
    if (withinRange && distance < nearestDistance) {
      nearest = target;
      nearestDistance = distance;
    }
  });
  return nearest;
}

export function isCanteenPointBlocked(x: number, y: number): boolean {
  return CANTEEN_STATIC_COLLISION_RECTS.some((rect) => (
    x >= rect.left && x <= rect.right && y >= rect.top && y <= rect.bottom
  ));
}
