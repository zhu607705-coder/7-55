import { createHash } from "node:crypto";
import { readdir, readFile, writeFile } from "node:fs/promises";
import { relative, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const repoRoot = resolve(fileURLToPath(new URL("..", import.meta.url)));
const manifestPath = resolve(repoRoot, "public/godot/theater/build-manifest.json");

async function collectGodotMetadata(directory) {
  const paths = [];
  for (const entry of await readdir(directory, { withFileTypes: true })) {
    const absolute = resolve(directory, entry.name);
    if (entry.isDirectory()) {
      if (entry.name !== ".godot" && entry.name !== ".generated") {
        paths.push(...await collectGodotMetadata(absolute));
      }
    } else if (entry.name.endsWith(".import") || entry.name.endsWith(".uid")) {
      paths.push(relative(repoRoot, absolute).split("\\").join("/"));
    }
  }
  return paths;
}

const sourcePaths = [
  "godot/project.godot",
  "godot/export_presets.cfg",
  "godot/scenes/theater_runtime.tscn",
  "godot/scripts/theater_runtime.gd",
  "godot/asset-manifest.json",
  "godot/data/theater-runtime.json",
  ...await collectGodotMetadata(resolve(repoRoot, "godot"))
].sort();

const artifactPaths = [
  "public/godot/theater/index.html",
  "public/godot/theater/index.js",
  "public/godot/theater/index.wasm",
  "public/godot/theater/index.pck",
  "public/godot/theater/index.png",
  "public/godot/theater/index.icon.png",
  "public/godot/theater/index.apple-touch-icon.png",
  "public/godot/theater/index.audio.worklet.js",
  "public/godot/theater/index.audio.position.worklet.js"
];

async function describe(path) {
  const bytes = await readFile(resolve(repoRoot, path));
  return {
    path,
    bytes: bytes.byteLength,
    sha256: createHash("sha256").update(bytes).digest("hex")
  };
}

const manifest = {
  schemaVersion: 1,
  godotVersion: "4.7.1",
  runtimeContractVersion: "1.0.0",
  sources: await Promise.all(sourcePaths.map(describe)),
  artifacts: await Promise.all(artifactPaths.map(describe))
};

await writeFile(manifestPath, `${JSON.stringify(manifest, null, 2)}\n`);
console.log(
  `recorded Godot Web export sources=${manifest.sources.length} artifacts=${manifest.artifacts.length}`
);
