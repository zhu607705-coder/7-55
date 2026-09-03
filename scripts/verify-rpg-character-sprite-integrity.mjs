#!/usr/bin/env node

import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { decodePng } from "./normalize-chapter4-755-assets.mjs";

const ROOT = resolve(fileURLToPath(new URL("..", import.meta.url)));
const ALPHA_THRESHOLD = 10;
const MIN_COMPONENT_AREA = 500;
const MIN_SHAPE_IOU = 0.44;
const MAX_SCALE_RATIO = 1.03;
const MAX_ASPECT_RATIO_ERROR = 0.03;
const MIN_EDGE_PADDING = 2;

function loadPng(path) {
  return decodePng(readFileSync(path), path);
}

function alphaAt(image, index) {
  return image.channels === 4 ? image.pixels[index * 4 + 3] : 255;
}

function extractComponents(image) {
  if (image.channels !== 4) throw new Error("character source sheets must use RGBA PNGs");
  const total = image.width * image.height;
  const visited = new Uint8Array(total);
  const queue = new Int32Array(total);
  const components = [];

  for (let start = 0; start < total; start += 1) {
    if (visited[start] || alphaAt(image, start) < ALPHA_THRESHOLD) continue;
    visited[start] = 1;
    let readIndex = 0;
    let writeIndex = 1;
    queue[0] = start;
    const pixels = [];
    let minX = image.width;
    let minY = image.height;
    let maxX = -1;
    let maxY = -1;

    while (readIndex < writeIndex) {
      const index = queue[readIndex];
      readIndex += 1;
      pixels.push(index);
      const x = index % image.width;
      const y = Math.floor(index / image.width);
      minX = Math.min(minX, x);
      minY = Math.min(minY, y);
      maxX = Math.max(maxX, x);
      maxY = Math.max(maxY, y);
      const neighbors = [
        x > 0 ? index - 1 : -1,
        x + 1 < image.width ? index + 1 : -1,
        y > 0 ? index - image.width : -1,
        y + 1 < image.height ? index + image.width : -1
      ];
      for (const neighbor of neighbors) {
        if (neighbor < 0 || visited[neighbor] || alphaAt(image, neighbor) < ALPHA_THRESHOLD) continue;
        visited[neighbor] = 1;
        queue[writeIndex] = neighbor;
        writeIndex += 1;
      }
    }

    if (pixels.length < MIN_COMPONENT_AREA) continue;
    const width = maxX - minX + 1;
    const height = maxY - minY + 1;
    const mask = new Uint8Array(width * height);
    for (const index of pixels) {
      const x = index % image.width;
      const y = Math.floor(index / image.width);
      mask[(y - minY) * width + (x - minX)] = 1;
    }
    components.push({ bounds: { x: minX, y: minY, width, height }, mask: { width, height, pixels: mask } });
  }
  return components;
}

function orderComponents(components, columns, rows) {
  const expected = columns * rows;
  if (components.length !== expected) {
    throw new Error(`expected ${expected} source poses, found ${components.length}`);
  }
  const byVerticalCenter = [...components].sort((left, right) => (
    (left.bounds.y + left.bounds.height / 2) - (right.bounds.y + right.bounds.height / 2)
  ));
  const ordered = [];
  for (let row = 0; row < rows; row += 1) {
    const rowComponents = byVerticalCenter.slice(row * columns, (row + 1) * columns);
    rowComponents.sort((left, right) => (
      (left.bounds.x + left.bounds.width / 2) - (right.bounds.x + right.bounds.width / 2)
    ));
    ordered.push(...rowComponents);
  }
  return ordered;
}

function alphaMask(image) {
  if (image.channels !== 4) throw new Error("runtime character frames must use RGBA PNGs");
  let minX = image.width;
  let minY = image.height;
  let maxX = -1;
  let maxY = -1;
  for (let y = 0; y < image.height; y += 1) {
    for (let x = 0; x < image.width; x += 1) {
      const index = y * image.width + x;
      if (alphaAt(image, index) < ALPHA_THRESHOLD) continue;
      minX = Math.min(minX, x);
      minY = Math.min(minY, y);
      maxX = Math.max(maxX, x);
      maxY = Math.max(maxY, y);
    }
  }
  if (maxX < minX || maxY < minY) throw new Error("runtime frame is empty");
  const width = maxX - minX + 1;
  const height = maxY - minY + 1;
  const mask = new Uint8Array(width * height);
  for (let y = 0; y < height; y += 1) {
    for (let x = 0; x < width; x += 1) {
      const sourceIndex = (minY + y) * image.width + minX + x;
      mask[y * width + x] = alphaAt(image, sourceIndex) >= ALPHA_THRESHOLD ? 1 : 0;
    }
  }
  return { bounds: { x: minX, y: minY, width, height }, mask: { width, height, pixels: mask } };
}

function mirrored(mask) {
  const pixels = new Uint8Array(mask.pixels.length);
  for (let y = 0; y < mask.height; y += 1) {
    for (let x = 0; x < mask.width; x += 1) {
      pixels[y * mask.width + x] = mask.pixels[y * mask.width + (mask.width - 1 - x)];
    }
  }
  return { ...mask, pixels };
}

function shapeIou(first, second) {
  let intersection = 0;
  let union = 0;
  for (let y = 0; y < first.height; y += 1) {
    const secondY = Math.min(second.height - 1, Math.floor(y * second.height / first.height));
    for (let x = 0; x < first.width; x += 1) {
      const secondX = Math.min(second.width - 1, Math.floor(x * second.width / first.width));
      const left = first.pixels[y * first.width + x] !== 0;
      const right = second.pixels[secondY * second.width + secondX] !== 0;
      if (left && right) intersection += 1;
      if (left || right) union += 1;
    }
  }
  return union === 0 ? 1 : intersection / union;
}

function crop(image, x, y, width, height) {
  const pixels = Buffer.alloc(width * height * image.channels);
  for (let row = 0; row < height; row += 1) {
    const sourceStart = ((y + row) * image.width + x) * image.channels;
    const targetStart = row * width * image.channels;
    image.pixels.copy(pixels, targetStart, sourceStart, sourceStart + width * image.channels);
  }
  return { ...image, width, height, pixels };
}

function splitAtlas(path, frameWidth, frameHeight, count) {
  const atlas = loadPng(path);
  if (atlas.width !== frameWidth * count || atlas.height !== frameHeight) {
    throw new Error(`${path} expected ${frameWidth * count}x${frameHeight}, got ${atlas.width}x${atlas.height}`);
  }
  return Array.from({ length: count }, (_, index) => crop(atlas, index * frameWidth, 0, frameWidth, frameHeight));
}

function verifyRole(
  role,
  sourcePath,
  columns,
  rows,
  groups,
  enforceScaleRatio = true,
  maxAspectRatioError = MAX_ASPECT_RATIO_ERROR
) {
  const components = orderComponents(extractComponents(loadPng(sourcePath)), columns, rows);
  for (const [groupName, frames] of Object.entries(groups)) {
    const scales = [];
    for (const frame of frames) {
      const sourceComponent = components[frame.sourceIndex];
      const { bounds, mask: runtimeMask } = alphaMask(frame.image);
      const topPadding = bounds.y;
      const bottomPadding = frame.image.height - bounds.y - bounds.height;
      if (topPadding < MIN_EDGE_PADDING || bottomPadding < MIN_EDGE_PADDING) {
        throw new Error(`${frame.label} clips its silhouette padding: top=${topPadding} bottom=${bottomPadding}`);
      }
      if (frame.expectedHeight !== undefined && bounds.height !== frame.expectedHeight) {
        throw new Error(`${frame.label} expected silhouette height ${frame.expectedHeight}, got ${bounds.height}`);
      }
      const sourceMask = frame.sourceMirrored ? mirrored(sourceComponent.mask) : sourceComponent.mask;
      const iou = shapeIou(runtimeMask, sourceMask);
      if (iou < MIN_SHAPE_IOU) {
        throw new Error(`${frame.label} lost source silhouette pixels: IoU=${iou.toFixed(3)}`);
      }
      const sourceAspect = sourceComponent.bounds.width / sourceComponent.bounds.height;
      const runtimeAspect = bounds.width / bounds.height;
      const aspectError = Math.abs(runtimeAspect / sourceAspect - 1);
      if (aspectError > maxAspectRatioError) {
        throw new Error(`${frame.label} changed source silhouette proportions: error=${aspectError.toFixed(3)}`);
      }
      scales.push(bounds.height / sourceComponent.bounds.height);
    }
    const scaleRatio = Math.max(...scales) / Math.min(...scales);
    if (enforceScaleRatio && scaleRatio > MAX_SCALE_RATIO) {
      throw new Error(`${role}/${groupName} changes character scale between frames: ratio=${scaleRatio.toFixed(3)}`);
    }
  }
}

function playerGroups() {
  const root = resolve(ROOT, "src/assets/rpg/player");
  const sourceSpecs = {
    down: Array.from({ length: 8 }, (_, index) => [index, false]),
    up: [...Array.from({ length: 7 }, (_, index) => [index + 8, false]), [12, true]]
  };
  return Object.fromEntries(Object.entries(sourceSpecs).map(([direction, specs]) => [
    direction,
    specs.map(([sourceIndex, sourceMirrored], phase) => ({
      label: `player_${direction}_${phase}`,
      sourceIndex,
      image: loadPng(resolve(root, `player_${direction}_${phase}.png`)),
      sourceMirrored
    }))
  ]));
}

function lowerBodySpread(image, startY = 98) {
  let minX = image.width;
  let maxX = -1;
  for (let y = startY; y < image.height; y += 1) {
    for (let x = 0; x < image.width; x += 1) {
      if (alphaAt(image, y * image.width + x) < ALPHA_THRESHOLD) continue;
      minX = Math.min(minX, x);
      maxX = Math.max(maxX, x);
    }
  }
  if (maxX < minX) throw new Error("side walk frame has no lower-body pixels");
  return maxX - minX + 1;
}

function alphaIouInRegion(first, second, x, y, width, height) {
  let intersection = 0;
  let union = 0;
  for (let row = y; row < y + height; row += 1) {
    for (let column = x; column < x + width; column += 1) {
      const index = row * first.width + column;
      const left = alphaAt(first, index) >= ALPHA_THRESHOLD;
      const right = alphaAt(second, index) >= ALPHA_THRESHOLD;
      if (left && right) intersection += 1;
      if (left || right) union += 1;
    }
  }
  return union === 0 ? 1 : intersection / union;
}

function npcGroups(role) {
  const root = resolve(ROOT, "src/assets/rpg/npcs/finale");
  const definitions = {
    student: [["walk", "student_walk_8frame.png", 96, [0, 1, 2, 3, 4, 5, 6, 7]], ["phone", "student_phone_glance_2frame.png", 96, [8, 9]], ["bag", "student_adjust_bag_2frame.png", 96, [10, 11]], ["door", "student_push_door_3frame.png", 112, [12, 13, 14]], ["idle", "student_idle_1frame.png", 96, [15]]],
    guard_action: [["list", "guard_check_list_2frame.png", 96, [8, 9]], ["watch", "guard_check_watch_2frame.png", 96, [10, 11]], ["flashlight", "guard_flashlight_down_2frame.png", 128, [12, 13]], ["radio", "guard_radio_2frame.png", 96, [14, 15]]],
    guard_walk_side: [["walk_side", "guard_walk_8frame.png", 96, [0, 1, 2, 3, 4, 5, 6, 7]]],
    guard_walk_down: [["walk_down", "guard_walk_down_8frame.png", 96, [0, 1, 2, 3, 4, 5, 6, 7]]],
    guard_walk_up: [["walk_up", "guard_walk_up_8frame.png", 96, [0, 1, 2, 3, 4, 5, 6, 7]]],
    cleaner_action: [["mop", "cleaner_mop_4frame.png", 144, [4, 5, 6, 7]], ["cart", "cleaning_cart_1frame.png", 144, [8]], ["sign", "cleaner_place_sign_2frame.png", 128, [9, 10]], ["lights", "cleaner_toggle_lights_2frame.png", 112, [11, 12]], ["rest", "cleaner_rest_1frame.png", 96, [13]]],
    cleaner_idle: [["idle", "cleaner_idle_8frame.png", 96, [0, 1, 2, 3, 4, 5, 6, 7]]],
    cleaner_push_side: [["push_side", "cleaner_push_cart_8frame.png", 192, [0, 1, 2, 3, 4, 5, 6, 7]]],
    cleaner_push_down: [["push_down", "cleaner_push_cart_down_8frame.png", 192, [0, 1, 2, 3, 4, 5, 6, 7]]],
    cleaner_push_up: [["push_up", "cleaner_push_cart_up_8frame.png", 192, [0, 1, 2, 3, 4, 5, 6, 7]]]
  };
  return Object.fromEntries(definitions[role].map(([groupName, fileName, frameWidth, sourceIndices]) => {
    const images = splitAtlas(resolve(root, fileName), frameWidth, 128, sourceIndices.length);
    return [groupName, sourceIndices.map((sourceIndex, index) => ({
      label: `${groupName}_${index}`,
      sourceIndex,
      image: images[index]
    }))];
  }));
}

verifyRole("player", resolve(ROOT, "src/assets/rpg/player/source/player_walk_24pose_transparent_v2.png"), 4, 6, playerGroups());

const sideFrames = Array.from({ length: 8 }, (_, phase) => (
  loadPng(resolve(ROOT, `src/assets/rpg/player/player_side_${phase}.png`))
));
const sideIdle = loadPng(resolve(ROOT, "src/assets/rpg/player/player_side_idle.png"));
for (const [label, frame] of [["side idle", sideIdle], ...sideFrames.map((frame, phase) => [`side ${phase}`, frame])]) {
  const { bounds } = alphaMask(frame);
  const topPadding = bounds.y;
  const bottomPadding = frame.height - bounds.y - bounds.height;
  if (topPadding < MIN_EDGE_PADDING || bottomPadding < MIN_EDGE_PADDING) {
    throw new Error(`${label} clips its silhouette padding: top=${topPadding} bottom=${bottomPadding}`);
  }
}
const sideHeights = sideFrames.map((frame) => alphaMask(frame).bounds.height);
if (sideHeights.some((height) => height !== 104) || alphaMask(sideIdle).bounds.height !== 104) {
  throw new Error(`side walk resizes the character between frames: heights=${sideHeights.join(",")}`);
}
const headIous = sideFrames.map((frame) => alphaIouInRegion(sideIdle, frame, 20, 20, 56, 60));
if (Math.min(...headIous) < 0.82) {
  throw new Error(`side walk changes the locked head/upper-body silhouette: IoU=${headIous.map((value) => value.toFixed(3)).join(",")}`);
}
const contactSpreads = [0, 4].map((phase) => lowerBodySpread(sideFrames[phase]));
const passingSpreads = [2, 6].map((phase) => lowerBodySpread(sideFrames[phase]));
const recoverySpreads = [1, 3, 5, 7].map((phase) => lowerBodySpread(sideFrames[phase]));
const idleSpread = lowerBodySpread(sideIdle);
if (
  Math.min(...contactSpreads) < 58
  || Math.max(...passingSpreads) > 27
  || Math.min(...recoverySpreads) < 27
  || Math.max(...recoverySpreads) > 36
  || idleSpread > 30
) {
  throw new Error(
    `side gait must alternate contacts, compact recoveries, and joined-leg passing poses: `
    + `contacts=${contactSpreads.join(",")} passing=${passingSpreads.join(",")} `
    + `recovery=${recoverySpreads.join(",")} idle=${idleSpread}`
  );
}

const npcSourceRoot = resolve(ROOT, "src/assets/rpg/npcs/finale/source");
for (const [role, sourceFile, columns, rows] of [
  ["student", "finale_student_source_grid_v2.png", 4, 4],
  ["guard_action", "finale_guard_source_grid_v2.png", 4, 4],
  ["guard_walk_side", "finale_guard_walk_side_source_grid_v3.png", 4, 2],
  ["guard_walk_down", "finale_guard_walk_down_source_grid_v3.png", 4, 2],
  ["guard_walk_up", "finale_guard_walk_up_source_grid_v3.png", 4, 2],
  ["cleaner_action", "finale_cleaner_source_grid_v2.png", 4, 4],
  ["cleaner_idle", "finale_cleaner_idle_source_grid_v3.png", 4, 2],
  ["cleaner_push_side", "finale_cleaner_push_side_source_grid_v3.png", 4, 2],
  ["cleaner_push_down", "finale_cleaner_push_down_source_grid_v3.png", 4, 2],
  ["cleaner_push_up", "finale_cleaner_push_up_source_grid_v3.png", 4, 2]
]) {
  verifyRole(role, resolve(npcSourceRoot, sourceFile), columns, rows, npcGroups(role));
}

console.log("RPG character sprite validation PASS roles=12 runtime-silhouettes=complete side-idle=stationary-only side-gait=full-body-grounded-crossing scale=stable mapping=verified");
