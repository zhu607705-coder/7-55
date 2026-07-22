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

// Panorama plate stitched from 9 generated campus scenes after seam alignment = 11744 x 1084.
export const ZIJINGANG_PLATE = {
  width: 11744,
  height: 1084,
  campusBounds: { left: 0, top: 0, right: 11744, bottom: 1084 }
} as const;

export function projectOfficialCampusPoint(point: OfficialCampusPoint): { x: number; y: number } {
  const { minX, minY, maxX, maxY } = ZIJINGANG_OFFICIAL_BOUNDS;
  const { left, top, right, bottom } = ZIJINGANG_PLATE.campusBounds;
  return {
    x: Math.round(left + ((point.x - minX) / (maxX - minX)) * (right - left)),
    y: Math.round(top + ((maxY - point.y) / (maxY - minY)) * (bottom - top))
  };
}

// The campus is now a side-view panorama: buildings are backdrop art, not top-down
// footprints. Leave the landmark set empty so the building occlusion layer and the
// GIS-projected labels stay inert; collision comes solely from the walkability mask.
export const ZIJINGANG_CAMPUS_LANDMARKS: Record<string, CampusLandmarkLayout> = {};

export const ZIJINGANG_DISTRICTS = {
  west_academic: { center: { x: 1087, y: 2403 }, radius: 752 },
  central_lake: { center: { x: 2157, y: 2761 }, radius: 752 },
  east_academic: { center: { x: 2633, y: 3292 }, radius: 815 },
  north_residential: { center: { x: 3156, y: 1124 }, radius: 982 },
  east_sports: { center: { x: 3219, y: 2143 }, radius: 690 },
  south_garden: { center: { x: 1442, y: 3710 }, radius: 690 }
} as const;
