import { readdir, readFile, stat } from "node:fs/promises";
import { resolve } from "node:path";

const outputDirectory = resolve(process.cwd(), "public/godot");
const entries = await readdir(outputDirectory, { withFileTypes: true }).catch(() => []);
const files = entries.filter((entry) => entry.isFile()).map((entry) => entry.name).sort();

if (!files.includes("index.html")) {
  throw new Error("Godot web export is missing public/godot/index.html.");
}

for (const extension of [".js", ".wasm", ".pck"]) {
  if (!files.some((file) => file.endsWith(extension))) {
    throw new Error(`Godot web export is missing a ${extension} artifact.`);
  }
}

let totalBytes = 0;
for (const file of files) {
  const fileStat = await stat(resolve(outputDirectory, file));
  if (fileStat.size === 0) {
    throw new Error(`Godot web artifact is empty: ${file}`);
  }
  totalBytes += fileStat.size;
}

const html = await readFile(resolve(outputDirectory, "index.html"), "utf8");
if (!/<canvas\b/i.test(html)) {
  throw new Error("Godot web shell does not contain a canvas element.");
}
if (!/\.js["']/i.test(html)) {
  throw new Error("Godot web shell does not reference its JavaScript loader.");
}
if (/\b(?:src|href)=["']https?:\/\//i.test(html)) {
  throw new Error("Godot web shell contains an unexpected external HTTP resource.");
}
if (totalBytes > 220 * 1024 * 1024) {
  throw new Error(`Godot web export exceeds the initial 220 MiB budget: ${totalBytes} bytes.`);
}

console.log(`verified Godot web export files=${files.length} bytes=${totalBytes}`);
