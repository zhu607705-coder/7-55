import { createHash } from "node:crypto";
import { readFile } from "node:fs/promises";

const root = new URL("../src/assets/rpg/player/", import.meta.url);
const playerContractSource = await readFile(
  new URL("../src/scenes/rpg/RpgPlayerTextures.ts", import.meta.url),
  "utf8"
);
const campusSceneSource = await readFile(
  new URL("../src/scenes/rpg/BootScene.ts", import.meta.url),
  "utf8"
);
const playerBuilderSource = await readFile(
  new URL("./build-rpg-player-frames.py", import.meta.url),
  "utf8"
);
const stairPlayerSource = await readFile(
  new URL("../src/tools/chapter4-stair/playerSprite.ts", import.meta.url),
  "utf8"
);
const canteenSceneSource = await readFile(
  new URL("../src/scenes/rpg/CanteenInteriorScene.ts", import.meta.url),
  "utf8"
);
const directionFrameCounts = new Map([
  ["down", 8],
  ["up", 8],
  ["side", 8]
]);
const hashes = new Set();
let totalFrameCount = 0;

for (const [direction, frameCount] of directionFrameCounts) {
  for (let phase = 0; phase < frameCount; phase += 1) {
    const name = `player_${direction}_${phase}.png`;
    const bytes = await readFile(new URL(name, root));
    if (bytes.subarray(0, 8).toString("hex") !== "89504e470d0a1a0a") {
      throw new Error(`${name} is not a PNG`);
    }
    const width = bytes.readUInt32BE(16);
    const height = bytes.readUInt32BE(20);
    if (width !== 96 || height !== 128) {
      throw new Error(`${name} must be 96x128; received ${width}x${height}`);
    }
    if (bytes.length < 5000) {
      throw new Error(`${name} is unexpectedly small and may have lost source detail`);
    }
    hashes.add(createHash("sha256").update(bytes).digest("hex"));
    totalFrameCount += 1;
  }
}

if (hashes.size !== totalFrameCount) {
  throw new Error("The directional player cycles contain duplicate runtime frames");
}

const sideIdle = await readFile(new URL("player_side_idle.png", root));
if (
  sideIdle.subarray(0, 8).toString("hex") !== "89504e470d0a1a0a"
  || sideIdle.readUInt32BE(16) !== 96
  || sideIdle.readUInt32BE(20) !== 128
  || sideIdle.length < 5000
) {
  throw new Error("player_side_idle.png must remain a detailed 96x128 PNG");
}

for (const required of [
  '"act1-player-side-idle": playerSideIdleUrl',
  "RPG_PLAYER_SIDE_WALK_FRAME_COUNT = 8",
  'idle && facing === "side"'
]) {
  if (!playerContractSource.includes(required)) {
    throw new Error(`The shared player contract is missing ${required}`);
  }
}
if (/playerSide(?:8|9|10|11)Url|act1-player-side-(?:8|9|10|11)/.test(playerContractSource)) {
  throw new Error("The shared player contract still references retired twelve-frame side poses");
}
for (const required of [
  "player_side_walk_8frame_generated_v4.png",
  "player_side_model_9pose_generated_v4.png",
  "render_aligned_side_pose",
  "SIDE_WALK_POSE_SPECS"
]) {
  if (!playerBuilderSource.includes(required)) {
    throw new Error(`The side-frame builder is missing ${required}`);
  }
}
if (/compose_side_frame|SIDE_UPPER_BODY_CUT_Y|pull_lower_body_inward/.test(playerBuilderSource)) {
  throw new Error("Side frames must remain intact whole-body poses without waist slicing or limb shifting");
}
if (!/if \(!moving\)[\s\S]{0,220}this\.applyPose\(this\.targetFacing, 0, this\.targetFlipX, 0, true\)/.test(playerContractSource)) {
  throw new Error("The dedicated side idle must be selected by the zero-velocity branch");
}
if (/this\.applyPose\(this\.turn\.[^\n;]+true\)/.test(playerContractSource)) {
  throw new Error("A moving direction turn must not display the stationary side idle");
}
if (!canteenSceneSource.includes('this.playerAnimator.setFacing("side", deltaX < 0, false)')) {
  throw new Error("Scripted canteen side movement must request a walk pose instead of side idle");
}
if (!/this\.walking\s*\?\s*this\.frames\[this\.facing\]\[this\.frame\]\s*:\s*this\.idleFrames\[this\.facing\]/.test(stairPlayerSource)) {
  throw new Error("The stair player must reserve its idle texture for the non-walking state");
}

for (const sourceName of [
  "source/player_side_walk_8frame_generated_v4.png",
  "source/player_side_model_9pose_generated_v4.png"
]) {
  const bytes = await readFile(new URL(sourceName, root));
  if (bytes.subarray(0, 8).toString("hex") !== "89504e470d0a1a0a" || bytes.length < 100_000) {
    throw new Error(`${sourceName} must remain a detailed generated PNG source sheet`);
  }
}

if (!/RPG_NORTH_UP_CAMPUS_PLAYER_SCALE_MULTIPLIER\s*=\s*0\.5\s*;/.test(playerContractSource)) {
  throw new Error("The north-up campus player must render at 50% of the shared RPG visual scale");
}
if (!/configureNorthUpCampusRpgPlayerSprite\(this\.player\)/.test(campusSceneSource)) {
  throw new Error("BootScene must use the dedicated north-up campus player scale contract");
}
if (/configureRpgPlayerSprite\(this\.player\)/.test(campusSceneSource)) {
  throw new Error("BootScene must not fall back to the full-size shared RPG player scale");
}

console.log(
  "verified 24 unique high-resolution RPG walk frames plus side idle at 96x128 "
  + "(8 down, 8 up, 8 side) and the north-up campus 50% display contract"
);
