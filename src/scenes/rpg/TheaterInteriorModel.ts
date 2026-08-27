import {
  distanceFromPlayerToRpgTarget,
  isPlayerWithinRpgTarget,
  type RpgSpatialInteractionTarget
} from "./RpgInteractionContract";
import { RPG_PLAYER_DISPLAY_SCALE, RPG_PLAYER_FRAME_HEIGHT } from "./RpgPlayerTextures";

export type TheaterProgramId = "opening" | "spotlight" | "finale";
export type TheaterMode = "light" | "dark";
export type TheaterItemId =
  | "greaseTissue"
  | "temporaryTheaterTicket"
  | "spotlightRemote"
  | "fluorescentBrush";

export const THEATER_INTERIOR_WORLD = { width: 1672, height: 941 } as const;
export const THEATER_TICKET_FIXTURE_OFFSET_Y = Math.round(
  RPG_PLAYER_FRAME_HEIGHT * RPG_PLAYER_DISPLAY_SCALE / 2
);

export interface TheaterCollisionRect {
  id: string;
  left: number;
  top: number;
  right: number;
  bottom: number;
}

export interface TheaterOcclusionRect extends TheaterCollisionRect {
  sortY: number;
}

export const THEATER_STATIC_COLLISION_RECTS: readonly TheaterCollisionRect[] = [
  { id: "north_wall", left: 386, top: 6, right: 1281, bottom: 55 },
  { id: "west_outer_wall", left: 65, top: 37, right: 145, bottom: 921 },
  { id: "east_outer_wall", left: 1512, top: 37, right: 1605, bottom: 921 },
  { id: "south_wall_west", left: 67, top: 856, right: 714, bottom: 934 },
  { id: "south_wall_east", left: 958, top: 856, right: 1605, bottom: 934 },
  { id: "stage_left_wing", left: 145, top: 40, right: 244, bottom: 258 },
  { id: "stage_prop_chest", left: 246, top: 118, right: 342, bottom: 213 },
  { id: "stage_prop_scanner", left: 343, top: 132, right: 384, bottom: 210 },
  { id: "stage_right_equipment", left: 1290, top: 90, right: 1478, bottom: 210 },
  { id: "stage_front", left: 390, top: 258, right: 1280, bottom: 316 },
  // Keep the visible red-carpet aisles open: the source artwork leaves a
  // narrow horizontal aisle between the seat banks and another at the lobby
  // rail. Collision should cover chair footprints, not the full red carpet.
  { id: "upper_left_seats", left: 235, top: 331, right: 534, bottom: 464 },
  { id: "upper_center_seats", left: 615, top: 330, right: 1053, bottom: 464 },
  { id: "upper_right_seats", left: 1135, top: 330, right: 1431, bottom: 464 },
  { id: "lower_left_seats", left: 235, top: 516, right: 534, bottom: 635 },
  { id: "lower_center_seats", left: 615, top: 516, right: 1053, bottom: 635 },
  { id: "lower_right_seats", left: 1234, top: 516, right: 1431, bottom: 635 },
  { id: "lighting_console", left: 1092, top: 470, right: 1188, bottom: 542 },
  { id: "auditorium_divider_west", left: 65, top: 662, right: 724, bottom: 713 },
  { id: "auditorium_divider_east", left: 947, top: 662, right: 1605, bottom: 713 },
  { id: "poster_case", left: 94, top: 678, right: 459, bottom: 835 },
  { id: "lobby_bin_west", left: 493, top: 744, right: 538, bottom: 806 },
  { id: "lost_found_box", left: 556, top: 724, right: 633, bottom: 817 },
  { id: "ticket_kiosk", left: 1100, top: 681, right: 1192, bottom: 827 },
  { id: "lobby_bin_east", left: 1198, top: 744, right: 1245, bottom: 807 },
  { id: "ticket_counter", left: 1255, top: 679, right: 1475, bottom: 850 },
  { id: "south_planter_west", left: 14, top: 836, right: 135, bottom: 931 },
  { id: "south_planter_east", left: 1535, top: 835, right: 1652, bottom: 931 }
] as const;

export const THEATER_OCCLUSION_RECTS: readonly TheaterOcclusionRect[] = [
  { id: "stage_front_face", left: 390, top: 258, right: 1280, bottom: 316, sortY: 316 },
  { id: "upper_left_seats_front", left: 235, top: 331, right: 534, bottom: 474, sortY: 474 },
  { id: "upper_center_seats_front", left: 615, top: 330, right: 1053, bottom: 474, sortY: 474 },
  { id: "upper_right_seats_front", left: 1135, top: 330, right: 1431, bottom: 474, sortY: 474 },
  { id: "lower_left_seats_front", left: 235, top: 503, right: 534, bottom: 651, sortY: 651 },
  { id: "lower_center_seats_front", left: 615, top: 503, right: 1053, bottom: 651, sortY: 651 },
  { id: "lower_right_seats_front", left: 1234, top: 503, right: 1431, bottom: 651, sortY: 651 },
  { id: "lighting_console_front", left: 1083, top: 462, right: 1197, bottom: 552, sortY: 552 },
  { id: "auditorium_divider_west_front", left: 65, top: 649, right: 742, bottom: 713, sortY: 713 },
  { id: "auditorium_divider_east_front", left: 929, top: 649, right: 1605, bottom: 713, sortY: 713 },
  { id: "poster_case_front", left: 94, top: 678, right: 459, bottom: 835, sortY: 835 },
  { id: "lost_found_box_front", left: 556, top: 724, right: 633, bottom: 817, sortY: 817 },
  { id: "ticket_kiosk_front", left: 1100, top: 681, right: 1192, bottom: 827, sortY: 827 },
  { id: "ticket_counter_front", left: 1255, top: 679, right: 1475, bottom: 850, sortY: 850 }
] as const;

export type TheaterTargetKind = "poster" | "kiosk" | "gate" | "program" | "console" | "prop" | "scanner" | "vent" | "exit";

export interface TheaterInteractionTarget extends RpgSpatialInteractionTarget {
  kind: TheaterTargetKind;
  programId?: TheaterProgramId;
}

export const THEATER_INTERACTION_TARGETS: readonly TheaterInteractionTarget[] = [
  {
    id: "theater_poster",
    label: "入口海报玻璃",
    x: 282,
    y: 755,
    // The narrow aisle between the poster case and the lobby bin is the
    // reachable side of this fixture. Keep the player out of both collision
    // rectangles while retaining a short, physical interaction distance.
    stand: { x: 476, y: 755 },
    width: 230,
    height: 160,
    proximity: 80,
    dropWidth: 96,
    dropHeight: 96,
    kind: "poster",
    acceptedItem: "greaseTissue",
    requiredMode: "light"
  },
  {
    id: "theater_ticket_kiosk",
    label: "临时票打印机",
    x: 1146,
    y: 755,
    stand: { x: 1080, y: 750 },
    width: 92,
    height: 146,
    proximity: 72,
    kind: "kiosk"
  },
  {
    id: "theater_ticket_gate",
    label: "检票闸机右侧读票器",
    x: 907,
    y: 690 + THEATER_TICKET_FIXTURE_OFFSET_Y,
    stand: { x: 907, y: 770 + THEATER_TICKET_FIXTURE_OFFSET_Y },
    width: 90,
    height: 148,
    proximity: 88,
    dropWidth: 90,
    dropHeight: 100,
    kind: "gate",
    acceptedItem: "temporaryTheaterTicket",
    requiredMode: "light"
  },
  { id: "theater_program_opening", label: "开场节目单残页", x: 568, y: 405, proximity: 74, requiredMode: "light", kind: "program", programId: "opening" },
  { id: "theater_program_spotlight", label: "追光节目单残页", x: 1080, y: 594, proximity: 78, requiredMode: "light", kind: "program", programId: "spotlight" },
  { id: "theater_program_finale", label: "终场节目单残页", x: 1460, y: 418, proximity: 78, requiredMode: "light", kind: "program", programId: "finale" },
  {
    id: "theater_light_console",
    label: "剧院灯光控制台",
    x: 1140,
    y: 500,
    stand: { x: 1140, y: 590 },
    width: 160,
    height: 100,
    proximity: 64,
    dropWidth: 130,
    dropHeight: 110,
    kind: "console",
    acceptedItem: "spotlightRemote",
    requiredMode: "light"
  },
  {
    id: "theater_prop_box",
    label: "后台道具箱",
    x: 294,
    y: 165,
    width: 96,
    height: 95,
    proximity: 72,
    kind: "prop"
  },
  {
    id: "theater_prop_scanner",
    label: "道具箱旁票据扫描器",
    x: 364,
    y: 170,
    stand: { x: 420, y: 218 },
    width: 42,
    height: 78,
    proximity: 72,
    dropWidth: 76,
    dropHeight: 94,
    kind: "scanner",
    acceptedItem: "temporaryTheaterTicket",
    requiredMode: "light"
  },
  {
    id: "theater_backstage_vent",
    label: "后台通风口",
    x: 936,
    y: 145,
    stand: { x: 936, y: 228 },
    width: 78,
    height: 55,
    proximity: 64,
    dropWidth: 78,
    dropHeight: 55,
    kind: "vent",
    acceptedItem: "fluorescentBrush",
    requiredMode: "light"
  },
  { id: "theater_exit", label: "剧院出口", x: 836, y: 842, proximity: 90, kind: "exit" }
] as const;

// Spawn above the south-wall collision line so the route to the kiosk reads as
// one continuous lobby aisle instead of asking the player to first sidestep an
// invisible wall edge.
export const THEATER_LOBBY_SPAWN = { x: 836, y: 820 } as const;
export const THEATER_AUDITORIUM_SPAWN = { x: 1080, y: 590 } as const;
// Keep the player's foot box above the stage-front collision at y = 258.
export const THEATER_STAGE_SPAWN = { x: 420, y: 200 } as const;
export const THEATER_GATE_BLOCKER = { left: 774, top: 650, right: 900, bottom: 713 } as const;

export function findNearestTheaterTarget(
  x: number,
  y: number,
  targets: readonly TheaterInteractionTarget[]
): TheaterInteractionTarget | null {
  let nearest: TheaterInteractionTarget | null = null;
  let distance = Number.POSITIVE_INFINITY;
  targets.forEach((target) => {
    const candidateDistance = distanceFromPlayerToRpgTarget(target, x, y);
    if (isPlayerWithinRpgTarget(target, x, y) && candidateDistance < distance) {
      nearest = target;
      distance = candidateDistance;
    }
  });
  return nearest;
}

export function isTheaterPointBlocked(x: number, y: number): boolean {
  return THEATER_STATIC_COLLISION_RECTS.some((rect) => (
    x >= rect.left && x <= rect.right && y >= rect.top && y <= rect.bottom
  ));
}
