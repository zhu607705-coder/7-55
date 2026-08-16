import { execFileSync, spawnSync } from "node:child_process";
import { createHash } from "node:crypto";
import { mkdtemp, mkdir, readFile, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const repoRoot = resolve(dirname(fileURLToPath(import.meta.url)), "..");
const assetRoot = resolve(repoRoot, "src/assets/rpg/npcs/finale");
const sourceRoot = resolve(assetRoot, "source");

const sourceGrids = {
  student: {
    path: resolve(sourceRoot, "finale_student_source_grid.png"),
    columns: 4,
    rows: 3
  },
  cleaner: {
    path: resolve(sourceRoot, "finale_cleaner_source_grid.png"),
    columns: 4,
    rows: 4
  },
  guard: {
    path: resolve(sourceRoot, "finale_guard_source_grid.png"),
    columns: 4,
    rows: 3
  }
};

const animations = [
  { id: "student_walk", source: "student", frames: [0, 1, 2, 3], frameWidth: 96, frameHeight: 128, maxWidth: 82, maxHeight: 112, fps: 9, loop: true },
  { id: "student_phone_glance", source: "student", frames: [4, 5], frameWidth: 96, frameHeight: 128, maxWidth: 82, maxHeight: 112, fps: 3, loop: true },
  { id: "student_adjust_bag", source: "student", frames: [6, 7], frameWidth: 96, frameHeight: 128, maxWidth: 86, maxHeight: 112, fps: 4, loop: false },
  { id: "student_push_door", source: "student", frames: [8, 9, 10], frameWidth: 112, frameHeight: 128, maxWidth: 102, maxHeight: 112, fps: 6, loop: false },
  { id: "student_idle", source: "student", frames: [11], frameWidth: 96, frameHeight: 128, maxWidth: 82, maxHeight: 112, fps: 1, loop: true },
  { id: "cleaner_push_cart", source: "cleaner", frames: [0, 1, 2, 3], frameWidth: 192, frameHeight: 128, maxWidth: 180, maxHeight: 112, fps: 8, loop: true },
  { id: "cleaner_mop", source: "cleaner", frames: [4, 5, 6], frameWidth: 144, frameHeight: 128, maxWidth: 132, maxHeight: 112, fps: 6, loop: true },
  { id: "cleaning_cart", source: "cleaner", frames: [7], frameWidth: 144, frameHeight: 128, maxWidth: 132, maxHeight: 104, fps: 1, loop: true },
  { id: "cleaner_place_sign", source: "cleaner", frames: [8, 9], frameWidth: 128, frameHeight: 128, maxWidth: 116, maxHeight: 112, fps: 4, loop: false },
  { id: "cleaner_toggle_lights", source: "cleaner", frames: [10, 11], frameWidth: 112, frameHeight: 128, maxWidth: 100, maxHeight: 112, fps: 4, loop: false },
  { id: "cleaner_rest", source: "cleaner", frames: [12, 13], frameWidth: 96, frameHeight: 128, maxWidth: 84, maxHeight: 112, fps: 2, loop: true },
  { id: "cleaner_idle", source: "cleaner", frames: [14, 15], frameWidth: 96, frameHeight: 128, maxWidth: 84, maxHeight: 112, fps: 2, loop: true },
  { id: "guard_walk", source: "guard", frames: [0, 1, 2, 3], frameWidth: 96, frameHeight: 128, maxWidth: 84, maxHeight: 112, fps: 8, loop: true },
  { id: "guard_check_list", source: "guard", frames: [4, 5], frameWidth: 96, frameHeight: 128, maxWidth: 84, maxHeight: 112, fps: 3, loop: true },
  { id: "guard_check_watch", source: "guard", frames: [6, 7], frameWidth: 96, frameHeight: 128, maxWidth: 84, maxHeight: 112, fps: 3, loop: true },
  { id: "guard_flashlight_down", source: "guard", frames: [8, 9], frameWidth: 128, frameHeight: 128, maxWidth: 116, maxHeight: 112, fps: 4, loop: true },
  { id: "guard_radio", source: "guard", frames: [10, 11], frameWidth: 96, frameHeight: 128, maxWidth: 84, maxHeight: 112, fps: 3, loop: true }
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

function sha256(buffer) {
  return createHash("sha256").update(buffer).digest("hex");
}

async function normalizeGrid(source, workRoot) {
  const normalized = resolve(workRoot, `${source}-transparent.png`);
  const config = sourceGrids[source];
  runMagick([
    config.path,
    "-alpha", "on",
    "-bordercolor", "white",
    "-border", "1",
    "-fuzz", "10%",
    "-fill", "none",
    "-draw", "alpha 0,0 floodfill",
    "-shave", "1x1",
    normalized
  ]);
  const cellPattern = resolve(workRoot, `${source}-cell-%02d.png`);
  runMagick([
    normalized,
    "-crop", `${config.columns}x${config.rows}@`,
    "+repage",
    cellPattern
  ]);
}

function cellPath(workRoot, source, frame) {
  return resolve(workRoot, `${source}-cell-${String(frame).padStart(2, "0")}.png`);
}

async function buildAnimation(animation, workRoot) {
  const normalizedFrames = [];
  for (const [sequenceIndex, sourceFrame] of animation.frames.entries()) {
    const target = resolve(workRoot, `${animation.id}-${String(sequenceIndex).padStart(2, "0")}.png`);
    runMagick([
      cellPath(workRoot, animation.source, sourceFrame),
      "-trim", "+repage",
      "-filter", "point",
      "-resize", `${animation.maxWidth}x${animation.maxHeight}>`,
      "-gravity", "south",
      "-background", "none",
      "-extent", `${animation.frameWidth}x${animation.frameHeight}`,
      target
    ]);
    normalizedFrames.push(target);
  }

  const output = resolve(assetRoot, `${animation.id}_${animation.frames.length}frame.png`);
  runMagick([...normalizedFrames, "+append", output]);
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
  await Promise.all(Object.keys(sourceGrids).map((source) => normalizeGrid(source, workRoot)));
  const builtAnimations = [];
  for (const animation of animations) {
    builtAnimations.push(await buildAnimation(animation, workRoot));
  }

  const sources = {};
  for (const [id, config] of Object.entries(sourceGrids)) {
    sources[id] = {
      file: `src/assets/rpg/npcs/finale/source/${config.path.split("/").at(-1)}`,
      columns: config.columns,
      rows: config.rows,
      sha256: sha256(await readFile(config.path))
    };
  }

  const manifest = {
    schemaVersion: 1,
    generatedAt: "source-derived",
    logicalFrame: { width: 96, height: 128 },
    sourceView: "top_down_front_pixel",
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
