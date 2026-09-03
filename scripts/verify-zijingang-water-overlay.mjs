#!/usr/bin/env node

import { createHash } from "node:crypto";
import { readFile } from "node:fs/promises";
import { inflateSync } from "node:zlib";

const EXPECTED = Object.freeze({
  worldWidth: 4516,
  worldHeight: 3420,
  tileSize: 128,
  frameCount: 3,
  frameDurationMs: 500,
  edgeFeatherRadius: 3,
  naturalEdge: "feathered",
  roadEdge: "hard",
  maskAtlasColumns: 16,
  waterAtlasSha256: "49c077788d6be549cf67a128b03738c33759451046e5aaacdeb8634d7566c8bd",
  embeddedWaterRegions: [{ id: "north_mid_river", bounds: [1940, 650, 2110, 1250] }]
});

const paths = {
  manifest: new URL("../src/data/maps/zijingang-campus-water-overlay.json", import.meta.url),
  waterAtlas: new URL("../src/assets/rpg/campus/water/zijingang_water_frames.png", import.meta.url),
  maskAtlas: new URL("../src/assets/rpg/campus/water/zijingang_water_mask_atlas.png", import.meta.url),
  waterSource: new URL("../src/assets/rpg/campus/source/topdown/campus_water_source.png", import.meta.url),
  roadSource: new URL("../src/assets/rpg/campus/source/topdown/campus_roads_source.png", import.meta.url),
  buildingSource: new URL("../src/assets/rpg/campus/source/topdown/campus_buildings_source.png", import.meta.url),
  manualOverride: new URL("../src/assets/rpg/campus/source/topdown/campus_water_mask_override.png", import.meta.url),
  runtime: new URL("../src/scenes/rpg/CampusWaterLayer.ts", import.meta.url),
  assets: new URL("../src/scenes/rpg/ZijingangLandmarkAssets.ts", import.meta.url),
  bootScene: new URL("../src/scenes/rpg/BootScene.ts", import.meta.url),
  buildings: new URL("../src/scenes/rpg/CampusBuildings.ts", import.meta.url),
  gameHost: new URL("../src/scenes/rpg/RpgGameHost.tsx", import.meta.url)
};

const [
  manifestText,
  waterAtlas,
  maskAtlas,
  waterSource,
  roadSource,
  buildingSource,
  manualOverride,
  runtimeSource,
  assetSource,
  bootSceneSource,
  buildingSourceCode,
  gameHostSource
] = await Promise.all([
  readFile(paths.manifest, "utf8"),
  readFile(paths.waterAtlas),
  readFile(paths.maskAtlas),
  readFile(paths.waterSource),
  readFile(paths.roadSource),
  readFile(paths.buildingSource),
  readFile(paths.manualOverride),
  readFile(paths.runtime, "utf8"),
  readFile(paths.assets, "utf8"),
  readFile(paths.bootScene, "utf8"),
  readFile(paths.buildings, "utf8"),
  readFile(paths.gameHost, "utf8")
]);

const manifest = JSON.parse(manifestText);
const sha256 = (value) => createHash("sha256").update(value).digest("hex");

function parsePng(bytes, label) {
  if (bytes.subarray(0, 8).toString("hex") !== "89504e470d0a1a0a") {
    throw new Error(`${label} is not a PNG file`);
  }
  const chunks = [];
  let info;
  let offset = 8;
  while (offset + 12 <= bytes.length) {
    const length = bytes.readUInt32BE(offset);
    const type = bytes.subarray(offset + 4, offset + 8).toString("ascii");
    const dataStart = offset + 8;
    const dataEnd = dataStart + length;
    if (dataEnd + 4 > bytes.length) throw new Error(`${label} has a truncated ${type} chunk`);
    const data = bytes.subarray(dataStart, dataEnd);
    if (type === "IHDR") {
      info = {
        width: data.readUInt32BE(0),
        height: data.readUInt32BE(4),
        bitDepth: data[8],
        colorType: data[9],
        interlace: data[12]
      };
    } else if (type === "IDAT") {
      chunks.push(data);
    } else if (type === "IEND") {
      break;
    }
    offset = dataEnd + 4;
  }
  if (!info) throw new Error(`${label} is missing its IHDR chunk`);
  return { ...info, chunks };
}

function decodeRgbaPng(bytes, label) {
  const info = parsePng(bytes, label);
  if (info.bitDepth !== 8 || info.colorType !== 6 || info.interlace !== 0) {
    throw new Error(`${label} must remain a non-interlaced 8-bit RGBA PNG`);
  }
  const bytesPerPixel = 4;
  const stride = info.width * bytesPerPixel;
  const inflated = inflateSync(Buffer.concat(info.chunks));
  if (inflated.length !== (stride + 1) * info.height) {
    throw new Error(`${label} has an unexpected decompressed byte count`);
  }
  const pixels = Buffer.alloc(stride * info.height);
  const paeth = (left, up, upperLeft) => {
    const estimate = left + up - upperLeft;
    const leftDistance = Math.abs(estimate - left);
    const upDistance = Math.abs(estimate - up);
    const upperLeftDistance = Math.abs(estimate - upperLeft);
    if (leftDistance <= upDistance && leftDistance <= upperLeftDistance) return left;
    return upDistance <= upperLeftDistance ? up : upperLeft;
  };
  for (let y = 0; y < info.height; y += 1) {
    const inputOffset = y * (stride + 1);
    const filter = inflated[inputOffset];
    const outputOffset = y * stride;
    for (let x = 0; x < stride; x += 1) {
      const encoded = inflated[inputOffset + 1 + x];
      const left = x >= bytesPerPixel ? pixels[outputOffset + x - bytesPerPixel] : 0;
      const up = y > 0 ? pixels[outputOffset + x - stride] : 0;
      const upperLeft = y > 0 && x >= bytesPerPixel
        ? pixels[outputOffset + x - stride - bytesPerPixel]
        : 0;
      let decoded;
      if (filter === 0) decoded = encoded;
      else if (filter === 1) decoded = encoded + left;
      else if (filter === 2) decoded = encoded + up;
      else if (filter === 3) decoded = encoded + Math.floor((left + up) / 2);
      else if (filter === 4) decoded = encoded + paeth(left, up, upperLeft);
      else throw new Error(`${label} uses unsupported PNG filter ${filter}`);
      pixels[outputOffset + x] = decoded & 0xff;
    }
  }
  return { ...info, pixels };
}

const waterInfo = parsePng(waterAtlas, "Campus water atlas");
if (
  waterInfo.width !== EXPECTED.tileSize * EXPECTED.frameCount
  || waterInfo.height !== EXPECTED.tileSize
  || sha256(waterAtlas) !== EXPECTED.waterAtlasSha256
) {
  throw new Error("Campus water atlas must remain the approved 384x128 Godot frame strip");
}

const maskInfo = decodeRgbaPng(maskAtlas, "Campus water alpha atlas");
const atlasContract = manifest.rendering?.maskAtlas;
if (
  manifest.version !== 1
  || manifest.world?.width !== EXPECTED.worldWidth
  || manifest.world?.height !== EXPECTED.worldHeight
  || manifest.tileSize !== EXPECTED.tileSize
  || manifest.animation?.frameCount !== EXPECTED.frameCount
  || manifest.animation?.frameWidth !== EXPECTED.tileSize
  || manifest.animation?.frameHeight !== EXPECTED.tileSize
  || manifest.animation?.frameDurationMs !== EXPECTED.frameDurationMs
  || "horizontalMotion" in manifest.animation
  || manifest.animation?.sampling !== "nearest"
  || manifest.rendering?.edgeFeatherRadius !== EXPECTED.edgeFeatherRadius
  || manifest.rendering?.naturalEdge !== EXPECTED.naturalEdge
  || manifest.rendering?.roadEdge !== EXPECTED.roadEdge
  || JSON.stringify(manifest.rendering?.embeddedWaterRegions)
    !== JSON.stringify(EXPECTED.embeddedWaterRegions)
  || manifest.mask?.encoding !== "rgba-alpha-atlas"
  || atlasContract?.columns !== EXPECTED.maskAtlasColumns
  || atlasContract?.cellSize !== EXPECTED.tileSize
  || atlasContract?.width !== maskInfo.width
  || atlasContract?.height !== maskInfo.height
  || atlasContract?.width !== atlasContract.columns * atlasContract.cellSize
  || atlasContract?.height !== atlasContract.rows * atlasContract.cellSize
) {
  throw new Error("Campus water manifest no longer matches the approved alpha-atlas contract");
}

for (const [label, bytes, expected] of [
  ["water atlas", waterAtlas, manifest.source?.waterAtlasSha256],
  ["water alpha atlas", maskAtlas, manifest.source?.maskAtlasSha256],
  ["water authoring layer", waterSource, manifest.source?.waterLayerSha256],
  ["road authoring layer", roadSource, manifest.source?.roadLayerSha256],
  ["building authoring layer", buildingSource, manifest.source?.buildingLayerSha256],
  ["manual water correction layer", manualOverride, manifest.source?.manualOverrideSha256]
]) {
  if (!expected || sha256(bytes) !== expected) {
    throw new Error(`Campus ${label} hash does not match the generated manifest`);
  }
}
const overrideInfo = parsePng(manualOverride, "Campus manual water correction layer");
if (
  overrideInfo.width !== EXPECTED.worldWidth
  || overrideInfo.height !== EXPECTED.worldHeight
  || manifest.source?.manualOverride
    !== "src/assets/rpg/campus/source/topdown/campus_water_mask_override.png"
  || manifest.source?.maskAtlas
    !== "src/assets/rpg/campus/water/zijingang_water_mask_atlas.png"
) {
  throw new Error("Campus water authoring and runtime masks must remain source-pixel aligned");
}

if (!Array.isArray(manifest.tiles) || manifest.tiles.length !== manifest.mask?.tileCount) {
  throw new Error("Campus water tile placements do not match the manifest count");
}
const totalPixels = EXPECTED.worldWidth * EXPECTED.worldHeight;
const worldAlpha = Buffer.alloc(totalPixels);
const occupiedWorldTiles = new Set();
manifest.tiles.forEach((tile, tileIndex) => {
  const worldTileKey = `${tile.x},${tile.y}`;
  if (
    !Number.isInteger(tile.x)
    || !Number.isInteger(tile.y)
    || !Number.isInteger(tile.width)
    || !Number.isInteger(tile.height)
    || tile.x % EXPECTED.tileSize !== 0
    || tile.y % EXPECTED.tileSize !== 0
    || tile.width <= 0
    || tile.height <= 0
    || tile.width > EXPECTED.tileSize
    || tile.height > EXPECTED.tileSize
    || tile.x + tile.width > EXPECTED.worldWidth
    || tile.y + tile.height > EXPECTED.worldHeight
    || tile.maskIndex !== tileIndex
    || tile.maskIndex >= atlasContract.columns * atlasContract.rows
    || occupiedWorldTiles.has(worldTileKey)
  ) {
    throw new Error(`Campus water tile ${tileIndex} has an invalid placement`);
  }
  occupiedWorldTiles.add(worldTileKey);
  const sourceX = (tile.maskIndex % atlasContract.columns) * EXPECTED.tileSize;
  const sourceY = Math.floor(tile.maskIndex / atlasContract.columns) * EXPECTED.tileSize;
  let nonEmpty = false;
  for (let y = 0; y < tile.height; y += 1) {
    for (let x = 0; x < tile.width; x += 1) {
      const sourceOffset = ((sourceY + y) * maskInfo.width + sourceX + x) * 4 + 3;
      const alpha = maskInfo.pixels[sourceOffset];
      worldAlpha[(tile.y + y) * EXPECTED.worldWidth + tile.x + x] = alpha;
      nonEmpty ||= alpha > 0;
    }
  }
  if (!nonEmpty) throw new Error(`Campus water tile ${tileIndex} is empty`);
});

let pixelCount = 0;
let opaquePixelCount = 0;
let coverageSum = 0;
let minX = EXPECTED.worldWidth;
let minY = EXPECTED.worldHeight;
let maxX = 0;
let maxY = 0;
const alphaLevels = new Set();
for (let index = 0; index < worldAlpha.length; index += 1) {
  const alpha = worldAlpha[index];
  if (alpha === 0) continue;
  const x = index % EXPECTED.worldWidth;
  const y = Math.floor(index / EXPECTED.worldWidth);
  pixelCount += 1;
  opaquePixelCount += alpha === 255 ? 1 : 0;
  coverageSum += alpha;
  alphaLevels.add(alpha);
  minX = Math.min(minX, x);
  minY = Math.min(minY, y);
  maxX = Math.max(maxX, x + 1);
  maxY = Math.max(maxY, y + 1);
}
const actualBounds = [minX, minY, maxX, maxY];
if (
  manifest.mask?.sha256 !== sha256(worldAlpha)
  || manifest.mask?.pixelCount !== pixelCount
  || manifest.mask?.opaquePixelCount !== opaquePixelCount
  || manifest.mask?.coverageSum !== coverageSum
  || manifest.mask?.alphaLevelCount !== alphaLevels.size
  || JSON.stringify(manifest.mask?.bounds) !== JSON.stringify(actualBounds)
) {
  throw new Error("Campus water alpha atlas differs from its source-sized manifest statistics");
}
if (
  pixelCount < 1000000
  || pixelCount > 1400000
  || manifest.tiles.length < 170
  || manifest.tiles.length > 230
  || alphaLevels.size < 5
) {
  throw new Error("Campus water corrections moved too far outside the reviewed water envelope");
}

const alphaAt = (x, y) => worldAlpha[y * EXPECTED.worldWidth + x];
for (const [label, point] of [
  ["west lake", [1800, 2200]],
  ["east lake", [3500, 1900]],
  ["north river", [3700, 500]],
  ["south river", [3350, 2650]],
  ["approved building-layer river", [2025, 850]]
]) {
  if (alphaAt(...point) < 160) throw new Error(`${label} must remain visible animated water`);
}
for (const [label, point] of [
  ["campus spawn", [2550, 650]],
  ["library gate", [3706, 1696]],
  ["theater approach", [3300, 1360]],
  ["canteen approach", [3120, 650]],
  ["north-mid tennis courts", [2170, 850]],
  ["north-mid west building", [1900, 850]]
]) {
  if (alphaAt(...point) !== 0) throw new Error(`${label} must remain outside animated water`);
}

for (const [label, source, required] of [
  ["asset preload", assetSource, ["zijingang_water_frames.png", "zijingang_water_mask_atlas.png", "preloadRpgSpriteSheet", "preloadRpgImage"]],
  ["campus scene", bootSceneSource, ["new CampusWaterLayer(this)", "this.waterLayer.build()"]],
  ["water runtime", runtimeSource, ["CanvasTexture", "FilterMode.NEAREST", "maskSource", "destination-in", "destination-out", "frameDurationMs !== 500", "roadEdge", "Scenes.Events.SHUTDOWN", "Scenes.Events.DESTROY"]],
  ["building foreground", buildingSourceCode, ["eraseCampusAnimatedWaterFromContext", "ZIJINGANG_CAMPUS_WATER_MASK_KEY"]]
]) {
  for (const token of required) {
    if (!source.includes(token)) throw new Error(`${label} is missing ${token}`);
  }
}
if (/from\s+["'][^"']*godot/i.test(assetSource + runtimeSource + bootSceneSource + buildingSourceCode)) {
  throw new Error("Active campus water code must not import the archived Godot runtime");
}
if (!gameHostSource.includes("type: Phaser.CANVAS")) {
  throw new Error("Campus water must remain validated against the canonical Canvas renderer");
}

console.log(
  `verified animated campus water atlas=${waterInfo.width}x${waterInfo.height} `
  + `mask=${maskInfo.width}x${maskInfo.height} pixels=${pixelCount} `
  + `tiles=${manifest.tiles.length} alphaLevels=${alphaLevels.size} embedded=north_mid_river`
);
