import { existsSync, readFileSync, writeFileSync } from "node:fs";
import { join, dirname } from "node:path";
import { fileURLToPath } from "node:url";

const root = dirname(fileURLToPath(import.meta.url));
const matrixPath = join(root, "style-matrix.json");
const matrix = JSON.parse(readFileSync(matrixPath, "utf8"));
function normalize(variant) {
  if (variant.derivedFrom) variant.status = "derived";
  else if (variant.path.includes("/styles/") || variant.path.includes("music_prologue_blackout_candidate_a")) variant.status = "generated";
  else if (existsSync(join(root, variant.path))) variant.status = "existing";
  return variant;
}
for (const concept of matrix.visual) for (const variant of Object.values(concept.variants)) normalize(variant);
for (const entries of Object.values(matrix.audio)) for (const concept of entries) for (const variant of Object.values(concept.variants)) normalize(variant);
for (const concept of matrix.text) for (const variant of Object.values(concept.variants)) normalize(variant);
matrix.generatedAt = new Date().toISOString();
writeFileSync(matrixPath, `${JSON.stringify(matrix, null, 2)}\n`);
console.log("normalized style status");
