import { createHash } from "node:crypto";
import { access, readFile, stat } from "node:fs/promises";
import { resolve } from "node:path";
import { fileURLToPath } from "node:url";

const repoRoot = resolve(fileURLToPath(new URL("..", import.meta.url)));
const manifestPath = resolve(repoRoot, "godot/asset-manifest.json");
const manifest = JSON.parse(await readFile(manifestPath, "utf8"));
const webBuildManifestPath = resolve(repoRoot, "public/godot/theater/build-manifest.json");
const failures = [];

function sha256(bytes) {
  return createHash("sha256").update(bytes).digest("hex");
}

if (manifest.schemaVersion !== 1) failures.push("asset manifest schemaVersion must be 1");
if (manifest.godotVersion !== "4.7.1") failures.push("asset manifest must target Godot 4.7.1");
if (manifest.runtimeContractVersion !== "1.0.0") failures.push("runtime contract must be 1.0.0");

for (const required of [
  "godot/project.godot",
  "godot/export_presets.cfg",
  "godot/scenes/theater_runtime.tscn",
  "godot/scripts/theater_runtime.gd",
  "godot/data/theater-runtime.json"
]) {
  try {
    await access(resolve(repoRoot, required));
  } catch {
    failures.push(`missing ${required}`);
  }
}

for (const file of manifest.files ?? []) {
  const sourcePath = resolve(repoRoot, file.source);
  const targetPath = resolve(repoRoot, file.target);
  try {
    const [sourceBytes, targetBytes] = await Promise.all([readFile(sourcePath), readFile(targetPath)]);
    const sourceHash = sha256(sourceBytes);
    const targetHash = sha256(targetBytes);
    if (file.source.endsWith("TheaterInteriorModel.ts")) {
      if (targetHash !== file.sha256) failures.push(`generated runtime data changed: ${file.target}`);
    } else {
      if (sourceHash !== targetHash) failures.push(`asset copy differs from source: ${file.target}`);
      if (targetHash !== file.sha256) failures.push(`asset manifest hash differs: ${file.target}`);
    }
    if (targetBytes.byteLength !== file.bytes) failures.push(`asset byte count differs: ${file.target}`);
  } catch {
    failures.push(`missing synced asset: ${file.target}`);
  }
}

const runtime = JSON.parse(await readFile(resolve(repoRoot, "godot/data/theater-runtime.json"), "utf8"));
if (runtime.sceneId !== "theater_interior") failures.push("theater runtime scene id mismatch");
if (runtime.logicalViewport?.width !== 960 || runtime.logicalViewport?.height !== 540) {
  failures.push("theater runtime viewport must be 960x540");
}
if (runtime.world?.width !== 1672 || runtime.world?.height !== 941) {
  failures.push("theater runtime world must match the approved source plate");
}
if (!Array.isArray(runtime.collisions) || runtime.collisions.length < 20) {
  failures.push("theater runtime collision data is incomplete");
}
if (!Array.isArray(runtime.targets) || runtime.targets.length < 10) {
  failures.push("theater runtime interaction targets are incomplete");
}

const exportFiles = [
  "public/godot/theater/index.html",
  "public/godot/theater/index.js",
  "public/godot/theater/index.wasm",
  "public/godot/theater/index.pck"
];
for (const exportFile of exportFiles) {
  try {
    const info = await stat(resolve(repoRoot, exportFile));
    if (info.size <= 0) failures.push(`empty Godot Web export: ${exportFile}`);
  } catch {
    failures.push(`missing Godot Web export: ${exportFile}`);
  }
}

try {
  const webBuildManifest = JSON.parse(await readFile(webBuildManifestPath, "utf8"));
  if (webBuildManifest.schemaVersion !== 1) failures.push("Godot Web build manifest schemaVersion must be 1");
  if (webBuildManifest.godotVersion !== manifest.godotVersion) failures.push("Godot Web build version mismatch");
  if (webBuildManifest.runtimeContractVersion !== manifest.runtimeContractVersion) {
    failures.push("Godot Web build runtime contract mismatch");
  }
  for (const entry of [...(webBuildManifest.sources ?? []), ...(webBuildManifest.artifacts ?? [])]) {
    try {
      const bytes = await readFile(resolve(repoRoot, entry.path));
      if (bytes.byteLength !== entry.bytes) failures.push(`Godot Web build byte count differs: ${entry.path}`);
      if (sha256(bytes) !== entry.sha256) failures.push(`Godot Web build hash differs: ${entry.path}`);
    } catch {
      failures.push(`missing Godot Web build file: ${entry.path}`);
    }
  }
  if ((webBuildManifest.sources ?? []).length < 20) {
    failures.push("Godot Web build source manifest is missing import metadata");
  }
  if ((webBuildManifest.artifacts ?? []).length < 9) failures.push("Godot Web build artifact manifest is incomplete");
} catch {
  failures.push("missing or invalid public/godot/theater/build-manifest.json");
}

if (failures.length > 0) {
  console.error(failures.map((failure) => `- ${failure}`).join("\n"));
  process.exit(1);
}

console.log(
  `verified Godot project version=${manifest.godotVersion} assets=${manifest.files.length} targets=${runtime.targets.length} collisions=${runtime.collisions.length} webBuild=matched`
);
