import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { describe, expect, it } from "vitest";

const root = resolve(import.meta.dirname, "../../..");

function readPngDimensions(relativePath: string) {
  const png = readFileSync(resolve(root, relativePath));
  expect(png.subarray(1, 4).toString("ascii")).toBe("PNG");
  return {
    width: png.readUInt32BE(16),
    height: png.readUInt32BE(20)
  };
}

describe("generated RPG interior assets", () => {
  it("keeps the dorm runtime artwork at the canonical 960 by 540 canvas size", () => {
    expect(readPngDimensions("src/assets/rpg/interiors/dorm_hub.png")).toEqual({ width: 960, height: 540 });
  });

  it("keeps the library runtime artwork aligned to its 1500 by 900 world", () => {
    expect(readPngDimensions("src/assets/rpg/interiors/library_interior.png")).toEqual({ width: 1500, height: 900 });
  });

  it("loads each generated asset through its owning Phaser scene", () => {
    const dormScene = readFileSync(resolve(root, "src/scenes/rpg/DormHubScene.ts"), "utf8");
    const libraryScene = readFileSync(resolve(root, "src/scenes/rpg/LibraryInteriorScene.ts"), "utf8");
    expect(dormScene).toContain("assets/rpg/interiors/dorm_hub.png");
    expect(libraryScene).toContain("assets/rpg/interiors/library_interior.png");
  });

  it("keeps the sports courts in a dedicated orthographic top-down source", () => {
    expect(readPngDimensions("src/assets/rpg/props/front-source/sports_courts.png"))
      .toEqual({ width: 362, height: 271 });
    const pipeline = readFileSync(resolve(root, "scripts/process-zijingang-environment-atlas.mjs"), "utf8");
    expect(pipeline).toContain('[10, "sports_courts.png"]');
  });
});
