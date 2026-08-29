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
const directionFrameCounts = new Map([
  ["down", 8],
  ["up", 8],
  ["side", 12]
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
  "verified 28 unique high-resolution RPG player frames at 96x128 "
  + "(8 down, 8 up, 12 side) and the north-up campus 50% display contract"
);
