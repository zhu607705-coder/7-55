import type { TheaterProgramId } from "../../core/types";

export const THEATER_INTERIOR_WORLD = { width: 1672, height: 941 } as const;

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
  { id: "stage_right_equipment", left: 1260, top: 42, right: 1512, bottom: 258 },
  { id: "stage_front", left: 390, top: 258, right: 1280, bottom: 316 },
  { id: "upper_left_seats", left: 235, top: 331, right: 534, bottom: 474 },
  { id: "upper_center_seats", left: 615, top: 330, right: 1053, bottom: 474 },
  { id: "upper_right_seats", left: 1135, top: 330, right: 1431, bottom: 474 },
  { id: "lower_left_seats", left: 235, top: 503, right: 534, bottom: 651 },
  { id: "lower_center_seats", left: 615, top: 503, right: 1053, bottom: 651 },
  { id: "lower_right_seats", left: 1234, top: 503, right: 1431, bottom: 651 },
  { id: "lighting_console", left: 1083, top: 462, right: 1197, bottom: 552 },
  { id: "auditorium_divider_west", left: 65, top: 649, right: 742, bottom: 713 },
  { id: "auditorium_divider_east", left: 929, top: 649, right: 1605, bottom: 713 },
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

export interface TheaterInteractionTarget {
  id: string;
  /** Visual entity anchor in source-pixel coordinates. */
  x: number;
  y: number;
  /** Reachable floor position from which the visual entity can be operated. */
  stand?: { x: number; y: number };
  proximity: number;
  kind: TheaterTargetKind;
  programId?: TheaterProgramId;
  acceptedItem?: string;
}

export const THEATER_INTERACTION_TARGETS: readonly TheaterInteractionTarget[] = [
  {
    id: "theater_poster",
    x: 282,
    y: 755,
    // The narrow aisle between the poster case and the lobby bin is the
    // reachable side of this fixture. Keep the player out of both collision
    // rectangles while retaining a short, physical interaction distance.
    stand: { x: 476, y: 755 },
    proximity: 48,
    kind: "poster",
    acceptedItem: "greaseTissue"
  },
  {
    id: "theater_ticket_kiosk",
    x: 1146,
    y: 755,
    stand: { x: 1080, y: 750 },
    proximity: 72,
    kind: "kiosk"
  },
  { id: "theater_ticket_gate", x: 836, y: 710, proximity: 98, kind: "gate", acceptedItem: "temporaryTheaterTicket" },
  { id: "theater_program_opening", x: 568, y: 405, proximity: 74, kind: "program", programId: "opening" },
  { id: "theater_program_spotlight", x: 1080, y: 594, proximity: 78, kind: "program", programId: "spotlight" },
  { id: "theater_program_finale", x: 1460, y: 418, proximity: 78, kind: "program", programId: "finale" },
  { id: "theater_light_console", x: 1070, y: 495, proximity: 105, kind: "console", acceptedItem: "spotlightRemote" },
  { id: "theater_prop_box", x: 292, y: 229, proximity: 92, kind: "prop" },
  { id: "theater_prop_scanner", x: 376, y: 226, proximity: 82, kind: "scanner", acceptedItem: "temporaryTheaterTicket" },
  { id: "theater_backstage_vent", x: 936, y: 145, proximity: 105, kind: "vent", acceptedItem: "fluorescentBrush" },
  { id: "theater_exit", x: 836, y: 842, proximity: 110, kind: "exit" }
] as const;

export const THEATER_LOBBY_SPAWN = { x: 836, y: 842 } as const;
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
    const stand = target.stand ?? target;
    const candidateDistance = Math.hypot(x - stand.x, y - stand.y);
    if (candidateDistance <= target.proximity && candidateDistance < distance) {
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
