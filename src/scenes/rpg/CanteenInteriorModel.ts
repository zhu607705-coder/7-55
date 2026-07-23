import type { CanteenExitId } from "../../core/types";

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
const TABLE_ROWS = [359, 466, 573] as const;

// Bounds are authored once against canteen_interior.png (1672 x 941).
// The rectangles cover visible solid pixels; the floor loops between rows and columns remain open.
export const CANTEEN_STATIC_COLLISION_RECTS: readonly CanteenCollisionRect[] = [
  { id: "north_service_wall", left: 126, top: 15, right: 1314, bottom: 241 },
  { id: "north_drink_wall", left: 1314, top: 14, right: 1643, bottom: 242 },
  { id: "west_wall_upper", left: 27, top: 17, right: 72, bottom: 192 },
  { id: "west_wall_lower", left: 27, top: 315, right: 58, bottom: 920 },
  { id: "east_wall", left: 1618, top: 18, right: 1647, bottom: 920 },
  { id: "west_planter_strip", left: 34, top: 314, right: 74, bottom: 547 },
  { id: "north_lost_found_shelf", left: 1344, top: 253, right: 1618, bottom: 407 },
  { id: "dish_return", left: 1260, top: 425, right: 1628, bottom: 585 },
  { id: "tray_station", left: 1258, top: 620, right: 1629, bottom: 761 },
  { id: "ordering_kiosks", left: 51, top: 682, right: 469, bottom: 846 },
  { id: "pickup_counter", left: 542, top: 688, right: 1087, bottom: 876 },
  { id: "pickup_left_pillar", left: 526, top: 665, right: 578, bottom: 892 },
  { id: "pickup_right_pillar", left: 1060, top: 664, right: 1112, bottom: 893 },
  { id: "southeast_wall_west", left: 1252, top: 760, right: 1310, bottom: 934 },
  { id: "southeast_wall_east", left: 1450, top: 760, right: 1643, bottom: 934 },
  ...TABLE_ROWS.flatMap((y, rowIndex) => TABLE_COLUMNS.map((x, columnIndex) => ({
    id: `table_${rowIndex + 1}_${columnIndex + 1}`,
    left: x - 49,
    top: y - 50,
    right: x + 49,
    bottom: y + 50
  })))
] as const;

// Only the visible front faces are redrawn above the actor. The source map remains the
// visual authority; these crops add depth sorting without introducing invisible cover.
export const CANTEEN_OCCLUSION_RECTS: readonly CanteenOcclusionRect[] = [
  { id: "lost_found_front", left: 1344, top: 253, right: 1618, bottom: 407, sortY: 407 },
  { id: "dish_return_front", left: 1260, top: 425, right: 1628, bottom: 585, sortY: 585 },
  { id: "tray_station_front", left: 1258, top: 620, right: 1629, bottom: 761, sortY: 761 },
  { id: "ordering_kiosks_front", left: 51, top: 682, right: 469, bottom: 846, sortY: 846 },
  { id: "pickup_counter_front", left: 542, top: 688, right: 1087, bottom: 876, sortY: 876 },
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
  x: number;
  y: number;
  target: boolean;
  queueCollision?: boolean;
}

export const CANTEEN_TRAYS: readonly CanteenTrayDefinition[] = [
  { id: "tray_blue_01", x: 299, y: 287, target: true },
  { id: "tray_blue_02", x: 751, y: 516, target: true },
  { id: "tray_blue_03", x: 1134, y: 642, target: true },
  { id: "tray_plain_01", x: 454, y: 296, target: false },
  { id: "tray_plain_02", x: 907, y: 410, target: false },
  { id: "tray_queue_01", x: 1222, y: 338, target: false, queueCollision: true }
] as const;

export interface CanteenInteractionTarget {
  id: string;
  x: number;
  y: number;
  proximity: number;
  kind: "tray" | "kiosk" | "pickup" | "cart" | "exit";
  value?: string;
}

export const CANTEEN_INTERACTION_TARGETS: readonly CanteenInteractionTarget[] = [
  ...CANTEEN_TRAYS.map((tray) => ({
    id: tray.id,
    x: tray.x,
    y: tray.y,
    proximity: 72,
    kind: "tray" as const,
    value: tray.id
  })),
  { id: "ordering_kiosk", x: 460, y: 654, proximity: 105, kind: "kiosk" },
  { id: "pickup_window_1", x: 654, y: 650, proximity: 90, kind: "pickup", value: "1" },
  { id: "pickup_window_2", x: 815, y: 650, proximity: 90, kind: "pickup", value: "2" },
  { id: "pickup_window_3", x: 978, y: 650, proximity: 90, kind: "pickup", value: "3" },
  { id: "cart_west", x: 150, y: 287, proximity: 88, kind: "cart", value: "west" },
  { id: "cart_southeast", x: 1198, y: 824, proximity: 96, kind: "cart", value: "southeast" },
  { id: "cart_steam", x: 1212, y: 300, proximity: 92, kind: "cart", value: "steam" },
  { id: "southeast_exit", x: 1380, y: 835, proximity: 100, kind: "exit" }
] as const;

export const CANTEEN_ESCAPE_ANCHORS: Record<CanteenExitId, { x: number; y: number }> = {
  west: { x: 82, y: 250 },
  southeast: { x: 1381, y: 853 },
  steam: { x: 1235, y: 227 }
};

export const CANTEEN_SPAWN = { x: 1380, y: 838 } as const;
export const CANTEEN_PHASE_SPAWNS = {
  tray_search: CANTEEN_SPAWN,
  menu_order: { x: 500, y: 650 },
  pickup_search: { x: 900, y: 650 },
  exit_blocking: { x: 1154, y: 824 }
} as const;
export const CANTEEN_BLOCK_SPAWNS = [
  CANTEEN_PHASE_SPAWNS.exit_blocking,
  { x: 1165, y: 286 },
  { x: 120, y: 287 }
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
    const distance = Math.hypot(x - target.x, y - target.y);
    if (distance <= target.proximity && distance < nearestDistance) {
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
