import campusRuntimeData from "../../data/maps/zijingang-campus-runtime.json";

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
  occlusionPolygons: ReadonlyArray<ReadonlyArray<Readonly<{ x: number; y: number }>>>;
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

export const ZIJINGANG_PLATE = {
  width: campusRuntimeData.world.width,
  height: campusRuntimeData.world.height,
  campusBounds: {
    left: 0,
    top: 0,
    right: campusRuntimeData.world.width,
    bottom: campusRuntimeData.world.height
  }
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

// Side-view facades remain part of the panorama. The top-down crop/occlusion
// polygons are intentionally inert in this coordinate system.
export const ZIJINGANG_CAMPUS_LANDMARKS: Record<string, CampusLandmarkLayout> = {};

export const ZIJINGANG_DISTRICTS = {
  west_canteen: { center: { x: 800, y: 920 }, radius: 900 },
  west_garden: { center: { x: 3200, y: 900 }, radius: 1400 },
  central_culture: { center: { x: 6500, y: 900 }, radius: 1500 },
  qizhen_lake: { center: { x: 9362, y: 900 }, radius: 1100 },
  east_library: { center: { x: 10924, y: 900 }, radius: 950 },
  east_academic: { center: { x: 12700, y: 900 }, radius: 1200 }
} as const;
