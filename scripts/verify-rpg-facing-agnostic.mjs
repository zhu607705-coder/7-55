import { readdir, readFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const repositoryRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const sourceRoot = path.join(repositoryRoot, "src");
const supportedExtensions = new Set([".ts", ".tsx", ".json"]);
const forbiddenPatterns = [
  { label: "requiredFacing field", pattern: /\brequiredFacing\b/g },
  { label: "facing tolerance field", pattern: /\bfacingToleranceDegrees\b/g },
  { label: "wrong_facing outcome", pattern: /\bwrong_facing\b/g },
  { label: "target-facing helper", pattern: /\bisPlayerFacingRpgTarget\b/g },
  { label: "facing-ready helper", pattern: /\bisPlayerReadyForRpgTarget\b/g },
  { label: "facing-vector helper", pattern: /\bisFacingVectorTowardRpgTarget\b/g },
  {
    label: "player-facing interaction prompt",
    pattern: /面向[^。\n]{0,24}(?:后|再)(?:操作|交互|使用)/g
  }
];

async function collectFiles(directory) {
  const entries = await readdir(directory, { withFileTypes: true });
  const nested = await Promise.all(entries.map(async (entry) => {
    const fullPath = path.join(directory, entry.name);
    if (entry.isDirectory()) return collectFiles(fullPath);
    return supportedExtensions.has(path.extname(entry.name)) ? [fullPath] : [];
  }));
  return nested.flat();
}

const files = await collectFiles(sourceRoot);
const failures = [];
for (const file of files) {
  const source = await readFile(file, "utf8");
  for (const { label, pattern } of forbiddenPatterns) {
    pattern.lastIndex = 0;
    for (const match of source.matchAll(pattern)) {
      const line = source.slice(0, match.index).split("\n").length;
      failures.push(`${path.relative(repositoryRoot, file)}:${line} ${label}: ${match[0]}`);
    }
  }
}

if (failures.length > 0) {
  console.error("RPG facing-agnostic contract FAIL");
  failures.forEach((failure) => console.error(`- ${failure}`));
  process.exit(1);
}

console.log(`RPG facing-agnostic contract PASS files=${files.length} forbiddenMatches=0`);
