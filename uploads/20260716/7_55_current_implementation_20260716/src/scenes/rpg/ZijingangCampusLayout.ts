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

export const ZIJINGANG_PLATE = {
  width: 2400,
  height: 1920,
  campusBounds: { left: 175, top: 80, right: 2225, bottom: 1840 }
} as const;

export function projectOfficialCampusPoint(point: OfficialCampusPoint): { x: number; y: number } {
  const { minX, minY, maxX, maxY } = ZIJINGANG_OFFICIAL_BOUNDS;
  const { left, top, right, bottom } = ZIJINGANG_PLATE.campusBounds;
  return {
    x: Math.round(left + ((point.x - minX) / (maxX - minX)) * (right - left)),
    y: Math.round(top + ((maxY - point.y) / (maxY - minY)) * (bottom - top))
  };
}

export const ZIJINGANG_CAMPUS_LANDMARKS = {
  main_library: {
    id: "main_library",
    label: "主图书馆",
    officialCenter: { x: 1_867_559.917, y: 1_977_930.465 },
    officialFootprintMeters: [92.5, 75],
    worldCenter: { x: 462, y: 730 },
    visualFootprint: { width: 130, height: 105 },
    scaleClass: "major",
    entrance: "south",
    adjacentTo: ["qiushi_auditorium", "west_academic_spine"],
    silhouette: ["double_courtyard", "hipped_roof_wings", "central_plaque"]
  },
  qiushi_auditorium: {
    id: "qiushi_auditorium",
    label: "求是大讲堂",
    officialCenter: { x: 1_867_473.512, y: 1_977_873.646 },
    officialFootprintMeters: [159.9, 78.9],
    worldCenter: { x: 368, y: 792 },
    visualFootprint: { width: 216, height: 105 },
    scaleClass: "landmark",
    entrance: "south",
    adjacentTo: ["main_library", "west_academic_spine"],
    silhouette: ["tiered_hipped_roof", "front_colonnade", "raised_podium"]
  },
  crescent_building: {
    id: "crescent_building",
    label: "月牙楼",
    officialCenter: { x: 1_868_187.175, y: 1_977_867.037 },
    officialFootprintMeters: [172.2, 103.3],
    worldCenter: { x: 1141, y: 799 },
    visualFootprint: { width: 230, height: 140 },
    scaleClass: "landmark",
    entrance: "south",
    adjacentTo: ["qizhen_lake", "zijingang_theatre", "yangming_bridge"],
    silhouette: ["continuous_crescent", "stepped_roof", "glass_spine", "twin_cylinders"]
  },
  foundation_library: {
    id: "foundation_library",
    label: "基础图书馆",
    officialCenter: { x: 1_868_290.293, y: 1_977_694.692 },
    officialFootprintMeters: [86.1, 88],
    worldCenter: { x: 1252, y: 985 },
    visualFootprint: { width: 118, height: 118 },
    scaleClass: "landmark",
    entrance: "south",
    adjacentTo: ["information_tower", "qizhen_lake", "east_academic_spine"],
    silhouette: ["ring_crown_tower", "l_shaped_wings", "glass_atrium"]
  },
  information_tower: {
    id: "information_tower",
    label: "图书信息C楼",
    officialCenter: { x: 1_868_238.686, y: 1_977_714.849 },
    officialFootprintMeters: [38.3, 90.6],
    worldCenter: { x: 1197, y: 964 },
    visualFootprint: { width: 52, height: 122 },
    scaleClass: "major",
    entrance: "east",
    adjacentTo: ["foundation_library", "qizhen_lake"],
    silhouette: ["slender_tower", "dark_glass_grid", "shared_library_plinth"]
  },
  asia_games_hall: {
    id: "asia_games_hall",
    label: "亚运比赛馆",
    officialCenter: { x: 1_868_474.265, y: 1_977_824.442 },
    officialFootprintMeters: [115.5, 83],
    worldCenter: { x: 1452, y: 845 },
    visualFootprint: { width: 158, height: 112 },
    scaleClass: "landmark",
    entrance: "south",
    adjacentTo: ["indoor_stadium", "east_sports_spine"],
    silhouette: ["elliptical_shell", "central_roof_fold", "radial_ribs"]
  },
  indoor_stadium: {
    id: "indoor_stadium",
    label: "风雨操场",
    officialCenter: { x: 1_868_626.28, y: 1_977_777.797 },
    officialFootprintMeters: [148, 75],
    worldCenter: { x: 1616, y: 895 },
    visualFootprint: { width: 200, height: 105 },
    scaleClass: "major",
    entrance: "south",
    adjacentTo: ["asia_games_hall", "east_sports_spine"],
    silhouette: ["wide_arched_roof", "low_sports_hall", "glass_entry_band"]
  },
  west_track: {
    id: "west_track",
    label: "西田径场",
    officialCenter: { x: 1_867_802.515, y: 1_978_014.609 },
    officialFootprintMeters: [141.3, 123.1],
    worldCenter: { x: 724, y: 639 },
    visualFootprint: { width: 255, height: 225 },
    scaleClass: "athletics",
    entrance: "south",
    adjacentTo: ["east_track", "west_academic_spine"],
    silhouette: ["oval_track", "football_pitch", "south_stands"]
  },
  east_track: {
    id: "east_track",
    label: "东田径场",
    officialCenter: { x: 1_867_931.166, y: 1_977_976.939 },
    officialFootprintMeters: [130.7, 125.9],
    worldCenter: { x: 864, y: 680 },
    visualFootprint: { width: 245, height: 230 },
    scaleClass: "athletics",
    entrance: "south",
    adjacentTo: ["west_track", "qizhen_lake"],
    silhouette: ["oval_track", "football_pitch", "court_cluster"]
  },
  nanhuayuan: {
    id: "nanhuayuan",
    label: "南华园",
    officialCenter: { x: 1_867_747.104, y: 1_977_390.759 },
    officialFootprintMeters: [19.6, 13.7],
    worldCenter: { x: 664, y: 1314 },
    visualFootprint: { width: 150, height: 120 },
    scaleClass: "landscape",
    entrance: "east",
    adjacentTo: ["south_academic_spine", "qizhen_lake"],
    silhouette: ["garden_courtyard", "dark_tiled_pavilion", "dense_tree_ring"]
  },
  south_gate: {
    id: "south_gate",
    label: "南大门",
    officialCenter: { x: 1_868_180, y: 1_976_965 },
    officialFootprintMeters: [210, 24],
    worldCenter: { x: 1133, y: 1774 },
    visualFootprint: { width: 284, height: 46 },
    scaleClass: "landmark",
    entrance: "south",
    adjacentTo: ["south_perimeter_road", "qiushi_eagle"],
    silhouette: ["nine_arch_colonnade", "long_lintel", "horizontal_gate_line"]
  }
} as const satisfies Record<string, CampusLandmarkLayout>;

export const ZIJINGANG_DISTRICTS = {
  west_academic: { center: { x: 520, y: 920 }, radius: 360 },
  central_lake: { center: { x: 1032, y: 1057 }, radius: 360 },
  east_academic: { center: { x: 1260, y: 1260 }, radius: 390 },
  north_residential: { center: { x: 1510, y: 430 }, radius: 470 },
  east_sports: { center: { x: 1540, y: 820 }, radius: 330 },
  south_garden: { center: { x: 690, y: 1420 }, radius: 330 }
} as const;
