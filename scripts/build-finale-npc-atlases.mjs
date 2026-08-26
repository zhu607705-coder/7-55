import { execFileSync, spawnSync } from "node:child_process";
import { createHash } from "node:crypto";
import { mkdtemp, mkdir, readFile, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const repoRoot = resolve(dirname(fileURLToPath(import.meta.url)), "..");
const assetRoot = resolve(repoRoot, "src/assets/rpg/npcs/finale");
const sourceRoot = resolve(assetRoot, "source");
const alphaThreshold = "4%";
const minimumComponentArea = 500;
const bottomPadding = 2;

const sourceGrids = {
  student: {
    path: resolve(sourceRoot, "finale_student_source_grid_v2.png"),
    columns: 4,
    rows: 4,
    canonicalHeight: 112
  },
  cleanerAction: {
    path: resolve(sourceRoot, "finale_cleaner_source_grid_v2.png"),
    columns: 4,
    rows: 4,
    canonicalHeight: 112
  },
  cleanerIdle: {
    path: resolve(sourceRoot, "finale_cleaner_idle_source_grid_v3.png"),
    columns: 4,
    rows: 2,
    canonicalHeight: 112
  },
  cleanerPushDown: {
    path: resolve(sourceRoot, "finale_cleaner_push_down_source_grid_v3.png"),
    columns: 4,
    rows: 2,
    canonicalHeight: 112
  },
  cleanerPushUp: {
    path: resolve(sourceRoot, "finale_cleaner_push_up_source_grid_v3.png"),
    columns: 4,
    rows: 2,
    canonicalHeight: 112
  },
  cleanerPushSide: {
    path: resolve(sourceRoot, "finale_cleaner_push_side_source_grid_v3.png"),
    columns: 4,
    rows: 2,
    canonicalHeight: 112
  },
  guardAction: {
    path: resolve(sourceRoot, "finale_guard_source_grid_v2.png"),
    columns: 4,
    rows: 4,
    canonicalHeight: 112
  },
  guardWalkDown: {
    path: resolve(sourceRoot, "finale_guard_walk_down_source_grid_v3.png"),
    columns: 4,
    rows: 2,
    canonicalHeight: 112
  },
  guardWalkUp: {
    path: resolve(sourceRoot, "finale_guard_walk_up_source_grid_v3.png"),
    columns: 4,
    rows: 2,
    canonicalHeight: 112
  },
  guardWalkSide: {
    path: resolve(sourceRoot, "finale_guard_walk_side_source_grid_v3.png"),
    columns: 4,
    rows: 2,
    canonicalHeight: 112
  }
};

const animations = [
  { id: "student_walk", source: "student", frames: [0, 1, 2, 3, 4, 5, 6, 7], frameWidth: 96, frameHeight: 128, maxWidth: 90, maxHeight: 112, fps: 8, loop: true },
  { id: "student_phone_glance", source: "student", frames: [8, 9], frameWidth: 96, frameHeight: 128, maxWidth: 86, maxHeight: 112, fps: 3, loop: true },
  { id: "student_adjust_bag", source: "student", frames: [10, 11], frameWidth: 96, frameHeight: 128, maxWidth: 90, maxHeight: 112, fps: 4, loop: false },
  { id: "student_push_door", source: "student", frames: [12, 13, 14], frameWidth: 112, frameHeight: 128, maxWidth: 104, maxHeight: 112, fps: 6, loop: false },
  { id: "student_idle", source: "student", frames: [15], frameWidth: 96, frameHeight: 128, maxWidth: 86, maxHeight: 112, fps: 1, loop: true },
  { id: "cleaner_push_cart", source: "cleanerPushSide", frames: [0, 1, 2, 3, 4, 5, 6, 7], frameWidth: 192, frameHeight: 128, maxWidth: 180, maxHeight: 112, fps: 9, loop: true },
  { id: "cleaner_push_cart_down", source: "cleanerPushDown", frames: [0, 1, 2, 3, 4, 5, 6, 7], frameWidth: 192, frameHeight: 128, maxWidth: 180, maxHeight: 112, fps: 9, loop: true },
  { id: "cleaner_push_cart_up", source: "cleanerPushUp", frames: [0, 1, 2, 3, 4, 5, 6, 7], frameWidth: 192, frameHeight: 128, maxWidth: 180, maxHeight: 112, fps: 9, loop: true },
  { id: "cleaner_mop", source: "cleanerAction", frames: [4, 5, 6, 7], frameWidth: 144, frameHeight: 128, maxWidth: 134, maxHeight: 112, fps: 6, loop: true },
  { id: "cleaning_cart", source: "cleanerAction", frames: [8], frameWidth: 144, frameHeight: 128, maxWidth: 134, maxHeight: 104, fps: 1, loop: true },
  { id: "cleaner_place_sign", source: "cleanerAction", frames: [9, 10], frameWidth: 128, frameHeight: 128, maxWidth: 118, maxHeight: 112, fps: 4, loop: false },
  { id: "cleaner_toggle_lights", source: "cleanerAction", frames: [11, 12], frameWidth: 112, frameHeight: 128, maxWidth: 102, maxHeight: 112, fps: 4, loop: false },
  { id: "cleaner_rest", source: "cleanerAction", frames: [13], frameWidth: 96, frameHeight: 128, maxWidth: 86, maxHeight: 112, fps: 1, loop: true },
  { id: "cleaner_idle", source: "cleanerIdle", frames: [0, 1, 2, 3, 4, 5, 6, 7], frameWidth: 96, frameHeight: 128, maxWidth: 84, maxHeight: 112, fps: 6, loop: true },
  { id: "guard_walk", source: "guardWalkSide", frames: [0, 1, 2, 3, 4, 5, 6, 7], frameWidth: 96, frameHeight: 128, maxWidth: 90, maxHeight: 112, fps: 9, loop: true },
  { id: "guard_walk_down", source: "guardWalkDown", frames: [0, 1, 2, 3, 4, 5, 6, 7], frameWidth: 96, frameHeight: 128, maxWidth: 90, maxHeight: 112, fps: 9, loop: true },
  { id: "guard_walk_up", source: "guardWalkUp", frames: [0, 1, 2, 3, 4, 5, 6, 7], frameWidth: 96, frameHeight: 128, maxWidth: 90, maxHeight: 112, fps: 9, loop: true },
  { id: "guard_check_list", source: "guardAction", frames: [8, 9], frameWidth: 96, frameHeight: 128, maxWidth: 86, maxHeight: 112, fps: 3, loop: true },
  { id: "guard_check_watch", source: "guardAction", frames: [10, 11], frameWidth: 96, frameHeight: 128, maxWidth: 86, maxHeight: 112, fps: 3, loop: true },
  { id: "guard_flashlight_down", source: "guardAction", frames: [12, 13], frameWidth: 128, frameHeight: 128, maxWidth: 118, maxHeight: 112, fps: 4, loop: true },
  { id: "guard_radio", source: "guardAction", frames: [14, 15], frameWidth: 96, frameHeight: 128, maxWidth: 86, maxHeight: 112, fps: 3, loop: true }
];

function ensureMagick() {
  const result = spawnSync("magick", ["-version"], { stdio: "ignore" });
  if (result.status !== 0) {
    throw new Error("ImageMagick is required to build finale NPC atlases.");
  }
}

function runMagick(args) {
  execFileSync("magick", args, { stdio: "inherit" });
}

function inspectConnectedComponents(path) {
  const output = execFileSync("magick", [
    path,
    "-alpha", "extract",
    "-threshold", alphaThreshold,
    "-define", "connected-components:verbose=true",
    "-connected-components", "8",
    "null:"
  ], { encoding: "utf8" });
  return output
    .split("\n")
    .map((line) => line.match(
      /^\s+\d+:\s+(\d+)x(\d+)\+(\d+)\+(\d+)\s+([0-9.]+),([0-9.]+)\s+([0-9.eE+-]+)\s+(.+)$/
    ))
    .filter(Boolean)
    .map((match) => ({
      width: Number(match[1]),
      height: Number(match[2]),
      x: Number(match[3]),
      y: Number(match[4]),
      centerX: Number(match[5]),
      centerY: Number(match[6]),
      area: Number(match[7]),
      meanColor: match[8]
    }))
    .filter((component) => (
      component.area >= minimumComponentArea
      && component.meanColor.includes("255")
    ));
}

function sha256(buffer) {
  return createHash("sha256").update(buffer).digest("hex");
}

async function extractComponentPoses(source, workRoot) {
  const config = sourceGrids[source];
  const components = inspectConnectedComponents(config.path);
  const expected = config.columns * config.rows;
  if (components.length !== expected) {
    throw new Error(
      `NPC source ${source} expected ${expected} complete silhouettes, found ${components.length}.`
    );
  }
  components.sort((left, right) => left.centerY - right.centerY);
  const orderedComponents = [];
  for (let row = 0; row < config.rows; row += 1) {
    const rowComponents = components
      .slice(row * config.columns, (row + 1) * config.columns)
      .sort((left, right) => left.centerX - right.centerX);
    orderedComponents.push(...rowComponents);
  }
  for (const [frame, component] of orderedComponents.entries()) {
    runMagick([
      config.path,
      "-crop", `${component.width}x${component.height}+${component.x}+${component.y}`,
      "+repage",
      cellPath(workRoot, source, frame)
    ]);
  }
  return orderedComponents;
}

function cellPath(workRoot, source, frame) {
  return resolve(workRoot, `${source}-cell-${String(frame).padStart(2, "0")}.png`);
}

async function buildAnimation(animation, workRoot, sourceComponents, sourceScale) {
  const normalizedFrames = [];
  for (const [sequenceIndex, sourceFrame] of animation.frames.entries()) {
    const sourceComponent = sourceComponents[sourceFrame];
    const expectedWidth = Math.round(sourceComponent.width * sourceScale);
    const expectedHeight = Math.round(sourceComponent.height * sourceScale);
    if (expectedWidth > animation.maxWidth || expectedHeight > animation.maxHeight) {
      throw new Error(
        `${animation.id} frame ${sourceFrame} exceeds its runtime content box after fixed scaling: `
        + `${expectedWidth}x${expectedHeight} > ${animation.maxWidth}x${animation.maxHeight}`
      );
    }
    const mask = resolve(workRoot, `${animation.id}-${String(sequenceIndex).padStart(2, "0")}-mask.png`);
    const cleaned = resolve(workRoot, `${animation.id}-${String(sequenceIndex).padStart(2, "0")}-cleaned.png`);
    const target = resolve(workRoot, `${animation.id}-${String(sequenceIndex).padStart(2, "0")}.png`);
    runMagick([
      cellPath(workRoot, animation.source, sourceFrame),
      "-alpha", "extract",
      "-threshold", alphaThreshold,
      mask
    ]);
    runMagick([
      cellPath(workRoot, animation.source, sourceFrame),
      mask,
      "-alpha", "off",
      "-compose", "CopyOpacity",
      "-composite",
      cleaned
    ]);
    runMagick([
      cleaned,
      "-trim", "+repage",
      "-filter", "Lanczos",
      "-resize", `${sourceScale * 100}%`,
      "-gravity", "south",
      "-background", "none",
      "-extent", `${animation.frameWidth}x${animation.frameHeight - bottomPadding}`,
      "-gravity", "north",
      "-extent", `${animation.frameWidth}x${animation.frameHeight}`,
      target
    ]);
    normalizedFrames.push(target);
  }

  const output = resolve(assetRoot, `${animation.id}_${animation.frames.length}frame.png`);
  runMagick([...normalizedFrames, "+append", "-strip", output]);
  const bytes = await readFile(output);
  return {
    id: animation.id,
    file: `src/assets/rpg/npcs/finale/${animation.id}_${animation.frames.length}frame.png`,
    frameWidth: animation.frameWidth,
    frameHeight: animation.frameHeight,
    frameCount: animation.frames.length,
    fps: animation.fps,
    loop: animation.loop,
    footAnchor: { x: 0.5, y: 1 },
    sha256: sha256(bytes)
  };
}

ensureMagick();
await mkdir(assetRoot, { recursive: true });
const workRoot = await mkdtemp(resolve(tmpdir(), "seven-fifty-five-finale-npcs-"));

try {
  const sourceComponents = Object.fromEntries(await Promise.all(
    Object.keys(sourceGrids).map(async (source) => [
      source,
      await extractComponentPoses(source, workRoot)
    ])
  ));
  const sourceScales = Object.fromEntries(Object.entries(sourceGrids).map(([source, config]) => [
    source,
    config.canonicalHeight / Math.max(
      ...sourceComponents[source].map((component) => component.height)
    )
  ]));
  const builtAnimations = [];
  for (const animation of animations) {
    builtAnimations.push(await buildAnimation(
      animation,
      workRoot,
      sourceComponents[animation.source],
      sourceScales[animation.source]
    ));
  }

  const sources = {};
  for (const [id, config] of Object.entries(sourceGrids)) {
    sources[id] = {
      file: `src/assets/rpg/npcs/finale/source/${config.path.split("/").at(-1)}`,
      columns: config.columns,
      rows: config.rows,
      extraction: "ordered_alpha_components",
      componentAreaThreshold: minimumComponentArea,
      fixedUniformScale: sourceScales[id],
      sha256: sha256(await readFile(config.path))
    };
  }

  const manifest = {
    schemaVersion: 1,
    generatedAt: "imagegen-derived-2026-08-26",
    logicalFrame: { width: 96, height: 128 },
    sourceView: "top_down_front_pixel",
    generation: {
      requestedProvider: "built-in image_gen",
      rejectedMiniMaxReason: "retained historical source metadata only",
      selectedProvider: "OpenAI image_gen",
      alphaRole: "chroma_key_postprocessed_transparent_cutout"
    },
    sources,
    animations: builtAnimations
  };
  await writeFile(
    resolve(assetRoot, "finale_npc_manifest.json"),
    `${JSON.stringify(manifest, null, 2)}\n`
  );
  console.log(`built finale NPC atlases animations=${builtAnimations.length}`);
} finally {
  await rm(workRoot, { recursive: true, force: true });
}
