import campusOcclusionData from "../../data/maps/zijingang-campus-occlusion.json";

export type CampusScaleClass = "landmark" | "major" | "campus_block" | "landscape" | "athletics";

export interface OfficialCampusPoint {
  x: number;
  y: number;
}

export interface CampusLandmarkLayout {
  id: string;
  label: string;
  officialCenter: OfficialCampusPoint;
  officialFootprintMeters: readonly [width: number, height: number];
  worldCenter: Readonly<{ x: number; y: number }>;
  visualFootprint: Readonly<{ width: number; height: number }>;
  occlusionEnabled: boolean;
  occlusionPolygons: readonly (readonly Readonly<{ x: number; y: number }>[])[];
  scaleClass: CampusScaleClass;
  entrance: "north" | "east" | "south" | "west";
  adjacentTo: readonly string[];
  silhouette: readonly string[];
}

export const ZIJINGANG_OFFICIAL_BOUNDS = {
  minX: 1_867_295.0663178791,
  minY: 1_976_904.1468487254,
  maxX: 1_869_188.5869699426,
  maxY: 1_978_532.0626899807
} as const;

// User-selected north-up top-down campus plate. Every campus runtime coordinate
// is authored directly in this 4516x3420 source-pixel space.
export const ZIJINGANG_PLATE = {
  width: 4516,
  height: 3420,
  campusBounds: { left: 0, top: 0, right: 4516, bottom: 3420 }
} as const;

export const CAMPUS_LANDMARK_LABEL_TOP_INSET = 12;

export function projectOfficialCampusPoint(point: OfficialCampusPoint): { x: number; y: number } {
  const { minX, minY, maxX, maxY } = ZIJINGANG_OFFICIAL_BOUNDS;
  const { left, top, right, bottom } = ZIJINGANG_PLATE.campusBounds;
  return {
    x: Math.round(left + ((point.x - minX) / (maxX - minX)) * (right - left)),
    y: Math.round(top + ((maxY - point.y) / (maxY - minY)) * (bottom - top))
  };
}

const SHARED_OCCLUSION_POLYGONS = Object.fromEntries(
  campusOcclusionData.buildings.map((building) => [building.id, building.polygons])
) as Record<string, CampusLandmarkLayout["occlusionPolygons"]>;

function sharedOcclusion(id: string): CampusLandmarkLayout["occlusionPolygons"] {
  const polygons = SHARED_OCCLUSION_POLYGONS[id];
  if (!polygons) {
    throw new Error(`Missing shared campus occlusion polygons for ${id}`);
  }
  return polygons;
}

// This is the manual authority for landmark labels and same-source occlusion.
// Enabled polygons are stored in the shared JSON manifest consumed by Phaser and Godot.
export const ZIJINGANG_CAMPUS_LANDMARKS: Record<string, CampusLandmarkLayout> = {
  ziyun_bifeng: {
    id: "ziyun_bifeng",
    label: "紫云碧峰",
    officialCenter: { x: 0, y: 0 },
    officialFootprintMeters: [0, 0],
    worldCenter: { x: 2572, y: 525 },
    visualFootprint: { width: 466, height: 190 },
    occlusionEnabled: false,
    occlusionPolygons: [[
      { x: 2340, y: 430 },
      { x: 2805, y: 430 },
      { x: 2805, y: 620 },
      { x: 2340, y: 620 }
    ]],
    scaleClass: "campus_block",
    entrance: "south",
    adjacentTo: ["east_canteen"],
    silhouette: ["paired_residential_blocks", "south_courtyard"]
  },
  east_canteen: {
    id: "east_canteen",
    label: "东区大食堂",
    officialCenter: { x: 0, y: 0 },
    officialFootprintMeters: [0, 0],
    worldCenter: { x: 3112, y: 525 },
    visualFootprint: { width: 266, height: 140 },
    occlusionEnabled: false,
    occlusionPolygons: [[
      { x: 2980, y: 455 },
      { x: 3035, y: 455 },
      { x: 3035, y: 475 },
      { x: 3165, y: 475 },
      { x: 3165, y: 455 },
      { x: 3245, y: 455 },
      { x: 3245, y: 570 },
      { x: 3225, y: 570 },
      { x: 3225, y: 595 },
      { x: 3030, y: 595 },
      { x: 3030, y: 575 },
      { x: 2980, y: 575 }
    ]],
    scaleClass: "major",
    entrance: "south",
    adjacentTo: ["ziyun_bifeng", "baisha"],
    silhouette: ["white_t_plan", "glass_south_atrium"]
  },
  foundation_library: {
    id: "foundation_library",
    label: "基础图书馆",
    officialCenter: { x: 0, y: 0 },
    officialFootprintMeters: [0, 0],
    worldCenter: { x: 3718, y: 1568 },
    visualFootprint: { width: 216, height: 196 },
    occlusionEnabled: true,
    occlusionPolygons: sharedOcclusion("foundation_library"),
    scaleClass: "landmark",
    entrance: "south",
    adjacentTo: ["east_academic", "campus_river"],
    silhouette: ["ring_crown_tower", "glass_atrium", "south_forecourt"]
  },
  crescent_building: {
    id: "crescent_building",
    label: "月牙楼",
    officialCenter: { x: 0, y: 0 },
    officialFootprintMeters: [0, 0],
    worldCenter: { x: 3365, y: 1190 },
    visualFootprint: { width: 390, height: 220 },
    occlusionEnabled: true,
    // The only walkable overlap is the north road ending at x=3324..3399,
    // y<=1130. The shared same-source silhouette covers a player approaching
    // south from that road without affecting side-adjacent areas.
    occlusionPolygons: sharedOcclusion("crescent_building"),
    scaleClass: "landmark",
    entrance: "south",
    adjacentTo: ["central_lake", "cultural_square"],
    silhouette: ["crescent_lakefront_complex", "central_glass_spine", "cylindrical_tower"]
  }
};

export const ZIJINGANG_DISTRICTS = {
  west_academic: { center: { x: 650, y: 1850 }, radius: 700 },
  central_lake: { center: { x: 1900, y: 2050 }, radius: 650 },
  east_academic: { center: { x: 3900, y: 2350 }, radius: 720 },
  north_residential: { center: { x: 2550, y: 350 }, radius: 620 },
  east_sports: { center: { x: 4100, y: 1000 }, radius: 520 },
  south_garden: { center: { x: 3100, y: 2500 }, radius: 650 }
} as const;
