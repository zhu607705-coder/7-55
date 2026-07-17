import { readdirSync } from "node:fs";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { spawnSync } from "node:child_process";

const root = resolve(dirname(fileURLToPath(import.meta.url)), "..");
const sourceDirectory = join(root, "src/assets/rpg/landmarks/source");
const outputDirectory = join(root, "src/assets/rpg/landmarks");

for (const name of readdirSync(sourceDirectory).filter((entry) => entry.endsWith(".png"))) {
  const chromaFuzz = "20%";
  const result = spawnSync("magick", [
    join(sourceDirectory, name),
    "-alpha", "on",
    "-fuzz", chromaFuzz,
    "-transparent", "#ff00ff",
    "-trim",
    "+repage",
    `PNG32:${join(outputDirectory, name)}`
  ], { encoding: "utf8" });
  if (result.status !== 0) {
    throw new Error(result.stderr || `Failed to process ${name}`);
  }
}

process.stdout.write(`${outputDirectory}\n`);
