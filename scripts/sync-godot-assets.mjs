import { copyFile, mkdir, readFile, stat } from "node:fs/promises";
import { dirname, resolve } from "node:path";

const root = process.cwd();
const manifestPath = resolve(root, "godot/assets/asset-manifest.json");
const generatedRoot = resolve(root, "godot/assets/generated");
const manifest = JSON.parse(await readFile(manifestPath, "utf8"));

if (manifest.version !== 1 || !Array.isArray(manifest.assets) || manifest.assets.length === 0) {
  throw new Error("godot/assets/asset-manifest.json is invalid or empty.");
}

await mkdir(generatedRoot, { recursive: true });

let copiedFiles = 0;
let reusedFiles = 0;
let totalBytes = 0;
for (const entry of manifest.assets) {
  if (!entry || typeof entry.source !== "string" || typeof entry.target !== "string") {
    throw new Error("Godot asset manifest entries require source and target strings.");
  }
  if (!entry.target.startsWith("godot/assets/generated/")) {
    throw new Error(`Refusing to copy outside generated Godot assets: ${entry.target}`);
  }

  const source = resolve(root, entry.source);
  const target = resolve(root, entry.target);
  const sourceStat = await stat(source).catch(() => null);
  if (!sourceStat?.isFile()) {
    throw new Error(`Godot source asset is missing: ${entry.source}`);
  }

  totalBytes += sourceStat.size;
  const targetStat = await stat(target).catch(() => null);
  let changed = !targetStat?.isFile() || targetStat.size !== sourceStat.size;
  if (!changed) {
    const [sourceBytes, targetBytes] = await Promise.all([readFile(source), readFile(target)]);
    changed = !sourceBytes.equals(targetBytes);
  }

  if (changed) {
    await mkdir(dirname(target), { recursive: true });
    await copyFile(source, target);
    copiedFiles += 1;
  } else {
    reusedFiles += 1;
  }
}

console.log(
  `synced Godot assets count=${manifest.assets.length} copied=${copiedFiles} reused=${reusedFiles} bytes=${totalBytes}`
);
