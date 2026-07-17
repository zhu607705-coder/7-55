import { describe, expect, it } from "vitest";
import { ZIJINGANG_LANDMARK_SIGNATURES, ZIJINGANG_WORLD } from "./ZijingangWorldModel";

describe("ZIJINGANG_WORLD", () => {
  it("is a multi-screen world rather than a 960x540 backdrop", () => {
    expect(ZIJINGANG_WORLD.width).toBeGreaterThanOrEqual(1920);
    expect(ZIJINGANG_WORLD.height).toBeGreaterThanOrEqual(1200);
  });

  it("keeps every required task area inside the world", () => {
    Object.values(ZIJINGANG_WORLD.areas).forEach((area) => {
      expect(area.x - area.width / 2).toBeGreaterThanOrEqual(0);
      expect(area.y - area.height / 2).toBeGreaterThanOrEqual(0);
      expect(area.x + area.width / 2).toBeLessThanOrEqual(ZIJINGANG_WORLD.width);
      expect(area.y + area.height / 2).toBeLessThanOrEqual(ZIJINGANG_WORLD.height);
    });
  });

  it("spawns near the south gate on the west side of Qiuzhen Lake", () => {
    const gate = ZIJINGANG_WORLD.areas.north_gate;
    expect(Math.hypot(ZIJINGANG_WORLD.spawn.x - gate.x, ZIJINGANG_WORLD.spawn.y - gate.y)).toBeLessThan(80);
    expect(gate.x).toBeLessThan(ZIJINGANG_WORLD.areas.bridge.x);
  });

  it("keeps the official-map silhouette signature for every major landmark", () => {
    expect(ZIJINGANG_LANDMARK_SIGNATURES).toMatchObject({
      crescent_building: expect.arrayContaining(["continuous_crescent", "glass_spine"]),
      foundation_library: expect.arrayContaining(["ring_crown_tower", "glass_atrium"]),
      zijingang_stadium: expect.arrayContaining(["elliptical_shell", "diagonal_roof_fold"]),
      south_gate: expect.arrayContaining(["nine_arch_colonnade", "qiushi_eagle"])
    });
  });
});
