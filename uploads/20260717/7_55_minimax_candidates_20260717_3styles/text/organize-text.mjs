import { existsSync, mkdirSync, readdirSync, readFileSync, renameSync, statSync, writeFileSync } from "node:fs";
import { basename, dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const root = dirname(fileURLToPath(import.meta.url));
const partials = join(root, "partials");
const reportPath = join(root, "../reports/text-validation.json");
mkdirSync(partials, { recursive: true });
const valid = [];
const moved = [];

function inspectDir(dir, recursive = false) {
  for (const name of readdirSync(dir)) {
    const file = join(dir, name);
    if (statSync(file).isDirectory()) {
      if (recursive) inspectDir(file, false);
      continue;
    }
    if (!name.endsWith(".json") || name === "selected-index.json") continue;
    let parsed;
    try {
      parsed = JSON.parse(readFileSync(file, "utf8"));
      valid.push({ source: file.slice(root.length + 1), bytes: statSync(file).size, payload: parsed });
    } catch (error) {
      const target = join(partials, `${basename(name, ".json")}.partial.txt`);
      renameSync(file, target);
      moved.push({ source: file.slice(root.length + 1), target: target.slice(root.length + 1), reason: error instanceof Error ? error.message : String(error) });
    }
  }
}

inspectDir(root, false);
if (existsSync(join(root, "valid"))) inspectDir(join(root, "valid"), false);
const index = Object.fromEntries(valid.map(({ source, payload }) => [source, payload]));
writeFileSync(join(root, "selected-index.json"), `${JSON.stringify(index, null, 2)}\n`);
writeFileSync(reportPath, `${JSON.stringify({ generatedAt: new Date().toISOString(), validCount: valid.length, partialCount: moved.length, valid: valid.map(({ source, bytes }) => ({ source, bytes })), partials: moved }, null, 2)}\n`);
process.stdout.write(`valid=${valid.length} partials=${moved.length}\n`);
