import { cp, mkdir, readFile, rm, stat } from "node:fs/promises";
import { dirname, resolve } from "node:path";

const root = process.cwd();
const manifestPath = resolve(root, "godot/assets/asset-manifest.json");
const generatedRoot = resolve(root, "godot/assets/generated");
const manifest = JSON.parse(await readFile(manifestPath, "utf8"));

if (manifest.version !== 1 || !Array.isArray(manifest.assets) || manifest.assets.length === 0) {
  throw new Error("godot/assets/asset-manifest.json is invalid or empty.");
}

await rm(generatedRoot, { recursive: true, force: true });
await mkdir(generatedRoot, { recursive: true });

let copiedBytes = 0;
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

  await mkdir(dirname(target), { recursive: true });
  await cp(source, target, { force: true });
  copiedBytes += sourceStat.size;
}

await mkdir(generatedRoot, { recursive: true });
console.log(`synced Godot assets count=${manifest.assets.length} bytes=${copiedBytes}`);
