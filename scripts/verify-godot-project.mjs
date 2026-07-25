import { readFile, stat } from "node:fs/promises";
import { resolve } from "node:path";

const root = process.cwd();
const requiredTextFiles = [
  "godot/project.godot",
  "godot/export_presets.cfg",
  "godot/scenes/main.tscn",
  "godot/scripts/main.gd",
  "godot/scripts/campus_runtime.gd",
  "godot/scripts/player_controller.gd",
  "godot/scripts/migration_state.gd",
  "godot/scripts/web_bridge.gd",
  "godot/assets/asset-manifest.json"
];

for (const relativePath of requiredTextFiles) {
  const fileStat = await stat(resolve(root, relativePath)).catch(() => null);
  if (!fileStat?.isFile() || fileStat.size === 0) {
    throw new Error(`Godot project contract is missing: ${relativePath}`);
  }
}

const project = await readFile(resolve(root, "godot/project.godot"), "utf8");
for (const required of [
  'run/main_scene="res://scenes/main.tscn"',
  'MigrationState="*res://scripts/migration_state.gd"',
  'WebBridge="*res://scripts/web_bridge.gd"',
  'renderer/rendering_method="gl_compatibility"'
]) {
  if (!project.includes(required)) {
    throw new Error(`Godot project.godot is missing contract: ${required}`);
  }
}

const manifest = JSON.parse(await readFile(resolve(root, "godot/assets/asset-manifest.json"), "utf8"));
if (manifest.version !== 1 || !Array.isArray(manifest.assets) || manifest.assets.length < 14) {
  throw new Error("Godot asset manifest must contain the campus plate, runtime data and 12 player frames.");
}

let generatedBytes = 0;
for (const entry of manifest.assets) {
  const sourceStat = await stat(resolve(root, entry.source)).catch(() => null);
  const targetStat = await stat(resolve(root, entry.target)).catch(() => null);
  if (!sourceStat?.isFile()) {
    throw new Error(`Godot source asset missing: ${entry.source}`);
  }
  if (!targetStat?.isFile()) {
    throw new Error(`Run npm run godot:sync; generated asset missing: ${entry.target}`);
  }
  if (sourceStat.size !== targetStat.size) {
    throw new Error(`Godot generated asset size mismatch: ${entry.target}`);
  }
  generatedBytes += targetStat.size;
}

const bridge = await readFile(resolve(root, "godot/scripts/web_bridge.gd"), "utf8");
if (!bridge.includes("JavaScriptBridge") || !bridge.includes("window.parent.postMessage")) {
  throw new Error("Godot web bridge must expose the browser postMessage protocol.");
}

console.log(`verified Godot project files=${requiredTextFiles.length} assets=${manifest.assets.length} bytes=${generatedBytes}`);
