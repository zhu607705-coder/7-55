import { build } from "esbuild";
import { createHash } from "node:crypto";
import { copyFile, mkdir, readFile, writeFile } from "node:fs/promises";
import { dirname, relative, resolve } from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";

const repoRoot = resolve(dirname(fileURLToPath(import.meta.url)), "..");
const godotRoot = resolve(repoRoot, "godot");
const webExportRoot = resolve(repoRoot, "public", "godot", "theater");
const generatedModuleRoot = resolve(godotRoot, ".generated");

const assetCopies = [
  {
    source: "src/assets/rpg/interiors/theater_interior.png",
    target: "godot/assets/rpg/interiors/theater_interior.png"
  },
  {
    source: "src/assets/rpg/fonts/fusion_pixel_12px_proportional_zh_hans.ttf",
    target: "godot/assets/rpg/fonts/fusion_pixel_12px_proportional_zh_hans.ttf"
  },
  ...["down", "side", "up"].flatMap((facing) =>
    [0, 1, 2, 3].map((frame) => ({
      source: `src/assets/rpg/player/player_${facing}_${frame}.png`,
      target: `godot/assets/rpg/player/player_${facing}_${frame}.png`
    }))
  )
];

function sha256(buffer) {
  return createHash("sha256").update(buffer).digest("hex");
}

function repoPath(path) {
  return relative(repoRoot, path).split("\\").join("/");
}

async function loadTypeScriptModule(sourcePath, outputName) {
  const generatedModulePath = resolve(generatedModuleRoot, outputName);
  await mkdir(dirname(generatedModulePath), { recursive: true });
  await build({
    entryPoints: [resolve(repoRoot, sourcePath)],
    bundle: true,
    format: "esm",
    platform: "node",
    target: "node22",
    outfile: generatedModulePath,
    logLevel: "silent"
  });
  return import(`${pathToFileURL(generatedModulePath).href}?v=${Date.now()}`);
}

const [theaterModel, spotlightModel] = await Promise.all([
  loadTypeScriptModule("src/scenes/rpg/TheaterInteriorModel.ts", "theater-model.mjs"),
  loadTypeScriptModule("src/scenes/rpg/TheaterSpotlightModel.ts", "theater-spotlight-model.mjs")
]);
await mkdir(webExportRoot, { recursive: true });
const runtimeData = {
  schemaVersion: 1,
  contractVersion: "1.0.0",
  sceneId: "theater_interior",
  logicalViewport: { width: 960, height: 540 },
  world: theaterModel.THEATER_INTERIOR_WORLD,
  collisions: theaterModel.THEATER_STATIC_COLLISION_RECTS,
  occlusions: theaterModel.THEATER_OCCLUSION_RECTS,
  targets: theaterModel.THEATER_INTERACTION_TARGETS,
  spawns: {
    lobby: theaterModel.THEATER_LOBBY_SPAWN,
    auditorium: theaterModel.THEATER_AUDITORIUM_SPAWN,
    stage: theaterModel.THEATER_STAGE_SPAWN
  },
  gateBlocker: theaterModel.THEATER_GATE_BLOCKER,
  spotlight: {
    rounds: spotlightModel.THEATER_SPOTLIGHT_ROUNDS,
    baseAssist: spotlightModel.getTheaterSpotlightAssist(0),
    failureAssist: spotlightModel.getTheaterSpotlightAssist(3),
    assistMistakes: 3,
    readyMs: 900,
    retryMs: 1100,
    hitMs: 350,
    reversalMs: 1320
  }
};
const runtimeTarget = resolve(godotRoot, "data/theater-runtime.json");
const runtimeBytes = Buffer.from(`${JSON.stringify(runtimeData, null, 2)}\n`);
await mkdir(dirname(runtimeTarget), { recursive: true });
await writeFile(runtimeTarget, runtimeBytes);

const manifestFiles = [];
for (const entry of assetCopies) {
  const source = resolve(repoRoot, entry.source);
  const target = resolve(repoRoot, entry.target);
  await mkdir(dirname(target), { recursive: true });
  await copyFile(source, target);
  const bytes = await readFile(target);
  manifestFiles.push({
    source: entry.source,
    target: entry.target,
    bytes: bytes.byteLength,
    sha256: sha256(bytes)
  });
}

manifestFiles.push({
  source: "src/scenes/rpg/TheaterInteriorModel.ts",
  target: repoPath(runtimeTarget),
  bytes: runtimeBytes.byteLength,
  sha256: sha256(runtimeBytes)
});

const manifest = {
  schemaVersion: 1,
  godotVersion: "4.7.1",
  runtimeContractVersion: "1.0.0",
  files: manifestFiles
};
const manifestTarget = resolve(godotRoot, "asset-manifest.json");
await writeFile(manifestTarget, `${JSON.stringify(manifest, null, 2)}\n`);

console.log(
  `synced Godot RPG assets files=${manifestFiles.length} theaterTargets=${runtimeData.targets.length} collisions=${runtimeData.collisions.length}`
);
