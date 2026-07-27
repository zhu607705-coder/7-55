import type { QizhenLakePhase } from "../../core/types";
import {
  isPlayerWithinRpgTarget,
  type RpgSpatialInteractionTarget
} from "./RpgInteractionContract";

export const QIZHEN_LAKE_WORLD = { width: 1672, height: 941 } as const;

export type QizhenLakePlateId = "reflection" | "signs" | "decoy" | "mist";

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

export type QizhenLakeTargetKind = "water" | "reflection_spot" | "sign" | "decoy_spot" | "mister" | "exit";

export interface QizhenLakeInteractionTarget extends RpgSpatialInteractionTarget {
  kind: QizhenLakeTargetKind;
  value?: string;
}

export interface QizhenLakePlateDefinition {
  id: QizhenLakePlateId;
  spawn: { x: number; y: number };
  collisions: readonly QizhenLakeCollisionRect[];
  occlusions: readonly QizhenLakeOcclusionRect[];
}

const EDGE_LEFT: QizhenLakeCollisionRect = { id: "edge_left", left: 0, top: 0, right: 42, bottom: 941 };
const EDGE_RIGHT: QizhenLakeCollisionRect = { id: "edge_right", left: 1630, top: 0, right: 1672, bottom: 941 };

export const QIZHEN_LAKE_PLATES: Readonly<Record<QizhenLakePlateId, QizhenLakePlateDefinition>> = {
  reflection: {
    id: "reflection",
    spawn: { x: 836, y: 690 },
    collisions: [
      EDGE_LEFT,
      EDGE_RIGHT,
      { id: "lake_water", left: 0, top: 0, right: 1672, bottom: 430 },
      { id: "lakeside_bed_left", left: 0, top: 430, right: 600, bottom: 535 },
      { id: "lakeside_bed_center", left: 620, top: 430, right: 825, bottom: 535 },
      { id: "lakeside_bed_right", left: 1380, top: 430, right: 1672, bottom: 535 },
      { id: "front_wall", left: 0, top: 810, right: 1672, bottom: 941 }
    ],
    occlusions: [
      { id: "west_tree", left: 0, top: 0, right: 300, bottom: 520, sortY: 520 },
      { id: "center_willow", left: 570, top: 120, right: 850, bottom: 535, sortY: 535 },
      { id: "east_willow", left: 1420, top: 70, right: 1672, bottom: 540, sortY: 540 },
      { id: "front_stone_wall", left: 0, top: 805, right: 1672, bottom: 920, sortY: 920 }
    ]
  },
  signs: {
    id: "signs",
    spawn: { x: 836, y: 710 },
    collisions: [
      EDGE_LEFT,
      EDGE_RIGHT,
      { id: "lake_and_garden", left: 0, top: 0, right: 1672, bottom: 470 },
      { id: "garden_east", left: 930, top: 470, right: 1672, bottom: 610 },
      { id: "road", left: 0, top: 810, right: 1672, bottom: 941 }
    ],
    occlusions: [
      { id: "west_willow", left: 0, top: 80, right: 330, bottom: 505, sortY: 505 },
      { id: "center_willows", left: 580, top: 40, right: 940, bottom: 540, sortY: 540 },
      { id: "east_garden", left: 930, top: 260, right: 1672, bottom: 700, sortY: 700 }
    ]
  },
  decoy: {
    id: "decoy",
    spawn: { x: 836, y: 770 },
    collisions: [
      EDGE_LEFT,
      EDGE_RIGHT,
      { id: "garden_and_lake", left: 0, top: 0, right: 1672, bottom: 690 },
      { id: "road", left: 0, top: 825, right: 1672, bottom: 941 }
    ],
    occlusions: [
      { id: "west_canopy", left: 0, top: 0, right: 610, bottom: 700, sortY: 700 },
      { id: "front_hedge", left: 600, top: 610, right: 1672, bottom: 735, sortY: 735 }
    ]
  },
  mist: {
    id: "mist",
    spawn: { x: 836, y: 690 },
    collisions: [
      EDGE_LEFT,
      EDGE_RIGHT,
      { id: "lake", left: 0, top: 0, right: 1672, bottom: 445 },
      { id: "west_planter", left: 0, top: 445, right: 270, bottom: 635 },
      { id: "east_planter", left: 1425, top: 445, right: 1672, bottom: 690 },
      { id: "road", left: 0, top: 760, right: 1672, bottom: 941 },
      { id: "flagpole_base", left: 480, top: 420, right: 570, bottom: 555 },
      { id: "palm_bases", left: 1040, top: 440, right: 1375, bottom: 610 }
    ],
    occlusions: [
      { id: "west_tree", left: 0, top: 0, right: 260, bottom: 650, sortY: 650 },
      { id: "palm_row", left: 1010, top: 150, right: 1420, bottom: 625, sortY: 625 },
      { id: "east_sign", left: 1410, top: 475, right: 1650, bottom: 700, sortY: 700 }
    ]
  }
} as const;

export const QIZHEN_LAKE_TARGETS: readonly QizhenLakeInteractionTarget[] = [
  { id: "qizhen_water", label: "启真湖水面", x: 836, y: 455, proximity: 145, kind: "water" },
  { id: "qizhen_reflection_left", label: "左侧倒影拦截点", x: 430, y: 650, proximity: 112, kind: "reflection_spot", value: "left" },
  { id: "qizhen_reflection_center", label: "中央倒影拦截点", x: 836, y: 650, proximity: 112, kind: "reflection_spot", value: "center" },
  { id: "qizhen_reflection_right", label: "右侧倒影拦截点", x: 1240, y: 650, proximity: 112, kind: "reflection_spot", value: "right" },
  { id: "qizhen_sign_0", label: "左侧指示牌", x: 430, y: 675, proximity: 118, kind: "sign", value: "0" },
  { id: "qizhen_sign_1", label: "中央指示牌", x: 836, y: 675, proximity: 118, kind: "sign", value: "1" },
  { id: "qizhen_sign_2", label: "右侧指示牌", x: 1240, y: 675, proximity: 118, kind: "sign", value: "2" },
  {
    id: "qizhen_decoy_notice",
    label: "公告栏前假纸条夹位",
    x: 330,
    y: 755,
    stand: { x: 330, y: 780 },
    proximity: 82,
    dropWidth: 164,
    dropHeight: 86,
    requiredMode: "light",
    kind: "decoy_spot",
    value: "notice",
    acceptedItem: "decoyPaper"
  },
  {
    id: "qizhen_decoy_bridge",
    label: "桥影前假纸条夹位",
    x: 836,
    y: 755,
    stand: { x: 836, y: 780 },
    proximity: 82,
    dropWidth: 164,
    dropHeight: 86,
    requiredMode: "light",
    kind: "decoy_spot",
    value: "bridge",
    acceptedItem: "decoyPaper"
  },
  {
    id: "qizhen_decoy_lamp",
    label: "路灯前假纸条夹位",
    x: 1360,
    y: 755,
    stand: { x: 1360, y: 780 },
    proximity: 82,
    dropWidth: 164,
    dropHeight: 86,
    requiredMode: "light",
    kind: "decoy_spot",
    value: "lamp",
    acceptedItem: "decoyPaper"
  },
  { id: "qizhen_mister", label: "湖心喷雾器", x: 836, y: 655, proximity: 135, kind: "mister" },
  { id: "qizhen_exit", label: "离开启真湖", x: 100, y: 740, proximity: 115, kind: "exit" }
] as const;

export function plateForQizhenPhase(phase: QizhenLakePhase): QizhenLakePlateId {
  if (phase === "sign_alignment") return "signs";
  if (phase === "decoy_setup") return "decoy";
  if (phase === "mist_timing" || phase === "chase_ready") return "mist";
  return "reflection";
}

export function findNearestQizhenTarget(
  x: number,
  y: number,
  targets: readonly QizhenLakeInteractionTarget[]
): QizhenLakeInteractionTarget | null {
  let nearest: QizhenLakeInteractionTarget | null = null;
  let bestDistance = Number.POSITIVE_INFINITY;
  targets.forEach((target) => {
    const stand = target.stand ?? target;
    const distance = Math.hypot(x - stand.x, y - stand.y);
    if (isPlayerWithinRpgTarget(target, x, y) && distance < bestDistance) {
      nearest = target;
      bestDistance = distance;
    }
  });
  return nearest;
}
