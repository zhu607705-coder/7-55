export const ZIJINGANG_WORLD = {
  width: 2400,
  height: 1600,
  spawn: { x: 700, y: 1530 },
  requiredItem: { x: 2250, y: 1335 },
  areas: {
    north_gate: { x: 700, y: 1530, width: 220, height: 96 },
    bridge: { x: 1185, y: 1104, width: 430, height: 96 },
    library: { x: 1630, y: 835, width: 240, height: 112 },
    game_kiosk: { x: 2250, y: 1380, width: 170, height: 90 }
  }
} as const;

export const ZIJINGANG_LANDMARK_SIGNATURES = {
  crescent_building: ["continuous_crescent", "stepped_roof", "glass_spine", "twin_cylinders"],
  main_library: ["double_courtyard", "hipped_roof_wings", "central_plaque"],
  qiushi_auditorium: ["tiered_hipped_roof", "front_colonnade", "raised_podium"],
  management_school: ["three_chamfered_towers", "connecting_wings", "roof_skylights"],
  foundation_library: ["ring_crown_tower", "l_shaped_wings", "glass_atrium"],
  zijingang_stadium: ["elliptical_shell", "diagonal_roof_fold", "radial_ribs"],
  south_gate: ["nine_arch_colonnade", "long_lintel", "qiushi_eagle"]
} as const;
