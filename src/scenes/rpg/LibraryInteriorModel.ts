import type { ItemId, LibraryLocationId, RpgCheckpointId } from "../../core/types";
import campusRuntimeData from "../../data/maps/zijingang-campus-runtime.json";

export const LIBRARY_INTERIOR_WORLD = {
  width: 1500,
  height: 900
} as const;

export interface LibraryCollisionRect {
  id: string;
  left: number;
  top: number;
  right: number;
  bottom: number;
}

// Bounds are authored directly against library_interior.png (1500 x 900).
// Keep these on visible solid pixels so clear floor remains traversable.
export const LIBRARY_STATIC_COLLISION_RECTS: readonly LibraryCollisionRect[] = [
  { id: "north_wall", left: 34, top: 12, right: 1468, bottom: 105 },
  { id: "west_wall_upper", left: 35, top: 69, right: 76, bottom: 401 },
  { id: "north_shelf_01", left: 124, top: 85, right: 166, bottom: 316 },
  { id: "north_shelf_02", left: 205, top: 85, right: 245, bottom: 316 },
  { id: "north_shelf_03", left: 283, top: 85, right: 325, bottom: 316 },
  { id: "north_shelf_04", left: 362, top: 85, right: 404, bottom: 316 },
  { id: "north_shelf_05", left: 442, top: 85, right: 484, bottom: 316 },
  { id: "north_display_shelf", left: 513, top: 108, right: 620, bottom: 234 },
  { id: "north_shelf_06", left: 643, top: 85, right: 684, bottom: 317 },
  { id: "north_shelf_07", left: 714, top: 85, right: 756, bottom: 317 },
  { id: "north_shelf_08", left: 787, top: 85, right: 830, bottom: 317 },
  { id: "reading_divider_shelf", left: 903, top: 68, right: 943, bottom: 342 },
  { id: "west_reading_table_01", left: 980, top: 123, right: 1141, bottom: 270 },
  { id: "east_reading_table_01", left: 1196, top: 123, right: 1371, bottom: 270 },
  { id: "west_reading_table_02", left: 982, top: 329, right: 1145, bottom: 484 },
  { id: "east_reading_table_02", left: 1195, top: 329, right: 1374, bottom: 485 },
  { id: "reading_west_planter", left: 920, top: 401, right: 979, bottom: 500 },
  { id: "reading_diagonal_rail_01", left: 925, top: 480, right: 944, bottom: 500 },
  { id: "reading_diagonal_rail_02", left: 934, top: 489, right: 953, bottom: 509 },
  { id: "reading_diagonal_rail_03", left: 943, top: 498, right: 962, bottom: 518 },
  { id: "reading_diagonal_rail_04", left: 952, top: 507, right: 971, bottom: 527 },
  { id: "reading_diagonal_rail_05", left: 961, top: 516, right: 980, bottom: 536 },
  { id: "reading_diagonal_rail_06", left: 970, top: 525, right: 989, bottom: 545 },
  { id: "reading_entry_west_post", left: 978, top: 518, right: 1002, bottom: 569 },
  { id: "reading_entry_east_post", left: 1074, top: 520, right: 1094, bottom: 570 },
  { id: "reading_south_rail", left: 1089, top: 534, right: 1428, bottom: 562 },
  { id: "reading_south_planter_west", left: 1095, top: 522, right: 1142, bottom: 579 },
  { id: "reading_south_planter_east", left: 1235, top: 520, right: 1282, bottom: 579 },
  { id: "reading_south_center_post", left: 1281, top: 518, right: 1300, bottom: 570 },
  { id: "reading_east_planter", left: 1386, top: 434, right: 1445, bottom: 528 },
  { id: "east_wall", left: 1413, top: 69, right: 1467, bottom: 735 },
  { id: "lost_found_room", left: 37, top: 400, right: 153, bottom: 558 },
  { id: "west_wall_middle", left: 36, top: 500, right: 76, bottom: 655 },
  { id: "front_desk_back", left: 184, top: 403, right: 486, bottom: 510 },
  { id: "front_desk_counter_left", left: 153, top: 517, right: 198, bottom: 611 },
  { id: "front_desk_counter", left: 181, top: 548, right: 461, bottom: 666 },
  { id: "front_desk_counter_right", left: 445, top: 497, right: 487, bottom: 612 },
  { id: "catalog_back_cabinets", left: 597, top: 424, right: 844, bottom: 506 },
  { id: "catalog_terminal_desk", left: 613, top: 516, right: 746, bottom: 613 },
  { id: "catalog_terminal_chair", left: 636, top: 594, right: 691, bottom: 646 },
  { id: "catalog_printer", left: 788, top: 510, right: 865, bottom: 614 },
  { id: "catalog_side_shelf", left: 908, top: 572, right: 944, bottom: 660 },
  { id: "west_wall_lower", left: 34, top: 649, right: 108, bottom: 802 },
  { id: "southwest_display_shelf", left: 187, top: 740, right: 325, bottom: 802 },
  { id: "entrance_west_plant", left: 462, top: 704, right: 520, bottom: 842 },
  { id: "entrance_west_glass", left: 515, top: 682, right: 655, bottom: 825 },
  { id: "entrance_turnstile_west", left: 667, top: 762, right: 695, bottom: 872 },
  { id: "entrance_turnstile_center", left: 737, top: 762, right: 763, bottom: 872 },
  { id: "entrance_turnstile_east", left: 807, top: 762, right: 834, bottom: 872 },
  { id: "entrance_east_glass", left: 845, top: 682, right: 986, bottom: 825 },
  { id: "entrance_east_plant", left: 982, top: 706, right: 1041, bottom: 842 },
  { id: "southeast_display_shelf", left: 1113, top: 741, right: 1305, bottom: 803 },
  { id: "east_wall_lower", left: 1370, top: 628, right: 1467, bottom: 803 }
] as const;

export function isPointInsideLibraryCollision(
  x: number,
  y: number,
  rects: readonly LibraryCollisionRect[] = LIBRARY_STATIC_COLLISION_RECTS
): boolean {
  return rects.some((rect) => (
    x >= rect.left
    && x <= rect.right
    && y >= rect.top
    && y <= rect.bottom
  ));
}

export const CAMPUS_LIBRARY_GATE = {
  x: campusRuntimeData.libraryGate.x,
  y: campusRuntimeData.libraryGate.y,
  radius: campusRuntimeData.libraryGate.radius
} as const;

export const LIBRARY_ENTRANCE_DOOR = {
  x: 750,
  y: 724,
  closedLeftX: 697,
  closedRightX: 803,
  openOffset: 56,
  blockerY: 742,
  blockerWidth: 204,
  sensorHalfWidth: 156,
  sensorHalfHeight: 142
} as const;

export type LibraryInteractionTargetId =
  | "entrance_record"
  | "front_desk"
  | "lost_found_machine"
  | "catalog_terminal"
  | "printer"
  | "library_shelf_755"
  | "seat_022_backpack"
  | "seat_022_gap"
  | "occupancy_note"
  | "seat_022_chair";

export interface LibraryInteractionTarget {
  id: LibraryInteractionTargetId;
  x: number;
  y: number;
  width: number;
  height: number;
  proximity: number;
  label: string;
  location?: LibraryLocationId;
  checkpoint?: RpgCheckpointId;
  acceptedItem?: ItemId;
}

export const LIBRARY_INTERACTION_TARGETS: readonly LibraryInteractionTarget[] = [
  {
    id: "entrance_record",
    x: 750,
    y: 770,
    width: 118,
    height: 72,
    proximity: 96,
    label: "查看入馆记录",
    location: "entrance",
    checkpoint: "library_entrance"
  },
  {
    id: "front_desk",
    x: 315,
    y: 585,
    width: 320,
    height: 150,
    proximity: 140,
    label: "询问信息台",
    location: "front_desk",
    checkpoint: "library_front_desk"
  },
  {
    id: "lost_found_machine",
    x: 160,
    y: 520,
    width: 108,
    height: 126,
    proximity: 112,
    label: "失物身份登记机",
    location: "lost_found",
    checkpoint: "library_front_desk",
    acceptedItem: "itemRecognitionReport"
  },
  {
    id: "catalog_terminal",
    x: 653,
    y: 555,
    width: 112,
    height: 96,
    proximity: 105,
    label: "馆藏检索终端",
    location: "catalog_terminal"
  },
  {
    id: "printer",
    x: 820,
    y: 555,
    width: 102,
    height: 92,
    proximity: 98,
    label: "自助打印机",
    location: "printer"
  },
  {
    id: "library_shelf_755",
    x: 548,
    y: 230,
    width: 124,
    height: 210,
    proximity: 122,
    label: "文学书架夹层",
    location: "shelf_755",
    checkpoint: "library_shelf_755",
    acceptedItem: "callNumber755"
  },
  {
    id: "seat_022_backpack",
    x: 1330,
    y: 410,
    width: 70,
    height: 60,
    proximity: 105,
    label: "检查占座书包",
    location: "seat_022",
    checkpoint: "library_seat_022",
    acceptedItem: "seatReleasePass"
  },
  {
    id: "seat_022_gap",
    x: 1368,
    y: 445,
    width: 66,
    height: 46,
    proximity: 96,
    label: "桌面夹缝",
    location: "seat_022",
    checkpoint: "library_seat_022",
    acceptedItem: "rightArrow"
  },
  {
    id: "occupancy_note",
    x: 1282,
    y: 422,
    width: 42,
    height: 32,
    proximity: 86,
    label: "拿起占座纸条",
    location: "seat_022",
    checkpoint: "library_seat_022"
  },
  {
    id: "seat_022_chair",
    x: 1302,
    y: 500,
    width: 80,
    height: 64,
    proximity: 94,
    label: "坐到 022",
    location: "seat_022",
    checkpoint: "library_seat_022"
  }
] as const;

export const LIBRARY_CHECKPOINT_SPAWNS: Record<RpgCheckpointId, { x: number; y: number }> = {
  campus_library_gate: { x: CAMPUS_LIBRARY_GATE.x, y: CAMPUS_LIBRARY_GATE.y + 72 },
  library_entrance: { x: 715, y: 842 },
  library_seat_022: { x: 1180, y: 505 },
  library_front_desk: { x: 430, y: 700 },
  library_shelf_755: { x: 625, y: 355 }
};

export function shouldOpenLibraryEntranceDoor(
  accessGranted: boolean,
  playerX: number,
  playerY: number
): boolean {
  return accessGranted
    && Math.abs(playerX - LIBRARY_ENTRANCE_DOOR.x) <= LIBRARY_ENTRANCE_DOOR.sensorHalfWidth
    && Math.abs(playerY - LIBRARY_ENTRANCE_DOOR.y) <= LIBRARY_ENTRANCE_DOOR.sensorHalfHeight;
}

export function getLibraryTarget(targetId: LibraryInteractionTargetId): LibraryInteractionTarget {
  const target = LIBRARY_INTERACTION_TARGETS.find((candidate) => candidate.id === targetId);
  if (!target) {
    throw new Error(`Unknown library target: ${targetId}`);
  }
  return target;
}

export function findLibraryTargetAt(
  x: number,
  y: number,
  targets: readonly LibraryInteractionTarget[] = LIBRARY_INTERACTION_TARGETS
): LibraryInteractionTarget | null {
  return targets.find((target) => (
    x >= target.x - target.width / 2
    && x <= target.x + target.width / 2
    && y >= target.y - target.height / 2
    && y <= target.y + target.height / 2
  )) ?? null;
}

export function findNearestLibraryTarget(
  x: number,
  y: number,
  targets: readonly LibraryInteractionTarget[]
): LibraryInteractionTarget | null {
  let nearest: LibraryInteractionTarget | null = null;
  let nearestDistance = Number.POSITIVE_INFINITY;
  for (const target of targets) {
    const distance = Math.hypot(x - target.x, y - target.y);
    if (distance <= target.proximity && distance < nearestDistance) {
      nearest = target;
      nearestDistance = distance;
    }
  }
  return nearest;
}

export function acceptsLibraryItem(target: LibraryInteractionTarget, itemId: ItemId): boolean {
  return target.acceptedItem === itemId;
}

export function getVisibleLibraryMarkerIds(
  activeTargets: readonly LibraryInteractionTarget[],
  nearest: LibraryInteractionTarget | null,
  selectedItem: ItemId | null
): LibraryInteractionTargetId[] {
  if (selectedItem) {
    const matchingTargets = activeTargets
      .filter((target) => target.acceptedItem === selectedItem)
      .map((target) => target.id);
    if (matchingTargets.length > 0) {
      return matchingTargets;
    }
  }
  return nearest ? [nearest.id] : [];
}
