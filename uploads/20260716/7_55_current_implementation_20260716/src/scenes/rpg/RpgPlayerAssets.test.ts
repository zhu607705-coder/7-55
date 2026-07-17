import { readdirSync, readFileSync } from "node:fs";
import { resolve } from "node:path";
import { describe, expect, it, vi } from "vitest";
import {
  configureRpgPlayerSprite,
  ensureRpgPlayerTextures,
  RPG_PLAYER_DISPLAY_SCALE,
  RPG_PLAYER_FOOT_COLLISION,
  RPG_PLAYER_FRAME_HEIGHT,
  RPG_PLAYER_FRAME_WIDTH,
  RPG_PLAYER_NAME_OFFSET_Y
} from "./RpgPlayerTextures";

const root = resolve(import.meta.dirname, "../../..");
const frameNames = [
  "player_down_0.png",
  "player_down_1.png",
  "player_up_0.png",
  "player_up_1.png",
  "player_side_0.png",
  "player_side_1.png"
] as const;

function readPng(relativePath: string) {
  const png = readFileSync(resolve(root, relativePath));
  return {
    signature: png.subarray(1, 4).toString("ascii"),
    width: png.readUInt32BE(16),
    height: png.readUInt32BE(20),
    colorType: png.readUInt8(25)
  };
}

describe("RPG player generated assets", () => {
  it.each(frameNames)("keeps %s at the shared transparent frame size", (frameName) => {
    const png = readPng(`src/assets/rpg/player/${frameName}`);
    expect(png).toMatchObject({ signature: "PNG", width: 48, height: 64 });
    expect([4, 6]).toContain(png.colorType);
  });

  it("loads all generated frames through the Phaser texture preloader", () => {
    const source = readFileSync(resolve(root, "src/scenes/rpg/RpgPlayerTextures.ts"), "utf8");
    frameNames.forEach((frameName) => expect(source).toContain(frameName));
    expect(source).toContain("preloadRpgPlayerTextures");
  });

  it("generates every fallback direction at the canonical frame size", () => {
    let graphics: Record<string, unknown>;
    const chain = vi.fn(() => graphics);
    const scaleCanvas = vi.fn(() => graphics);
    const generateTexture = vi.fn();
    const destroy = vi.fn();
    graphics = {
      scaleCanvas,
      fillStyle: chain,
      fillEllipse: chain,
      fillRect: chain,
      lineStyle: chain,
      strokeRect: chain,
      fillCircle: chain,
      strokeCircle: chain,
      generateTexture,
      destroy
    };

    ensureRpgPlayerTextures({
      textures: { exists: vi.fn(() => false) },
      make: { graphics: vi.fn(() => graphics) }
    } as never);

    expect(scaleCanvas).toHaveBeenCalledTimes(frameNames.length);
    expect(scaleCanvas).toHaveBeenCalledWith(RPG_PLAYER_FRAME_WIDTH / 28, RPG_PLAYER_FRAME_HEIGHT / 43);
    expect(generateTexture).toHaveBeenCalledTimes(frameNames.length);
    expect(generateTexture.mock.calls.every(([, width, height]) =>
      width === RPG_PLAYER_FRAME_WIDTH && height === RPG_PLAYER_FRAME_HEIGHT
    )).toBe(true);
    expect(destroy).toHaveBeenCalledTimes(frameNames.length);
  });

  it("uses the canonical full-size player while preserving the established foot collision", () => {
    const setOffset = vi.fn();
    const setSize = vi.fn(() => ({ setOffset }));
    const setScale = vi.fn();

    configureRpgPlayerSprite({ setScale, body: { setSize } } as never);

    expect({ width: RPG_PLAYER_FRAME_WIDTH, height: RPG_PLAYER_FRAME_HEIGHT }).toEqual({
      width: 48,
      height: 64
    });
    expect(RPG_PLAYER_DISPLAY_SCALE).toBe(1);
    expect(RPG_PLAYER_NAME_OFFSET_Y).toBe(44);
    expect(setScale).toHaveBeenCalledWith(RPG_PLAYER_DISPLAY_SCALE);
    expect(setSize).toHaveBeenCalledWith(
      RPG_PLAYER_FOOT_COLLISION.width,
      RPG_PLAYER_FOOT_COLLISION.height
    );
    expect(setOffset).toHaveBeenCalledWith(
      RPG_PLAYER_FOOT_COLLISION.offsetX,
      RPG_PLAYER_FOOT_COLLISION.offsetY
    );
  });

  it("routes every controllable RPG scene through the shared player configuration", () => {
    const sceneRoot = resolve(root, "src/scenes/rpg");
    const controllableSceneFiles = readdirSync(sceneRoot)
      .filter((fileName) => fileName.endsWith("Scene.ts"))
      .filter((fileName) =>
        readFileSync(resolve(sceneRoot, fileName), "utf8").includes("this.player = this.physics.add.sprite")
      );

    expect(controllableSceneFiles).toEqual(expect.arrayContaining([
      "BootScene.ts",
      "DormHubScene.ts",
      "LibraryInteriorScene.ts"
    ]));

    controllableSceneFiles.forEach((fileName) => {
      const source = readFileSync(resolve(sceneRoot, fileName), "utf8");
      expect(source, fileName).toContain("configureRpgPlayerSprite(this.player)");
      expect(source, fileName).not.toMatch(/this\.player\.(?:setScale|setDisplaySize)\(/);
      expect(source, fileName).not.toMatch(/this\.player\.body\??\.(?:setSize|setOffset)\(/);
    });
  });
});
