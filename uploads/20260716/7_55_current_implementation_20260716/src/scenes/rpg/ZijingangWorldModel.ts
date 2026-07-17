import campusRuntimeData from "../../data/maps/zijingang-campus-runtime.json";

interface CampusRuntimeModel {
  world: Readonly<{ width: number; height: number }>;
  spawn: Readonly<{ x: number; y: number }>;
  libraryGate: Readonly<{ x: number; y: number; radius: number }>;
}

const campusRuntime = campusRuntimeData as CampusRuntimeModel;

export const ZIJINGANG_WORLD = {
  width: campusRuntime.world.width,
  height: campusRuntime.world.height,
  spawn: campusRuntime.spawn,
  libraryGate: campusRuntime.libraryGate,
  projection: "top-down-90deg",
  northUp: true
} as const;

export const ZIJINGANG_LANDMARK_SIGNATURES = {
  crescent_building: ["continuous_crescent", "twin_cylinders", "glass_spine"],
  main_library: ["double_courtyard", "hipped_roof_wings", "central_plaque"],
  qiushi_auditorium: ["tiered_hipped_roof", "front_colonnade", "raised_podium"],
  foundation_library: ["ring_crown_tower", "connected_wings", "glass_atrium"],
  stadium: ["wide_elliptical_shell", "central_roof_fold", "radial_ribs"],
  south_gate: ["long_nine_bay_facade", "central_passage", "east_eagle_marker"]
} as const;
