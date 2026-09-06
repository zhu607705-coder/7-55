import { execFileSync } from "node:child_process";
import { fileURLToPath } from "node:url";

const script = (name) => fileURLToPath(new URL(`./${name}`, import.meta.url));
for (const name of [
  "verify-chapter4-history-restoration.mjs",
  "verify-chapter4-restored-scene.mjs",
  "verify-chapter4-chase-stairwell.mjs",
  "verify-chapter4-guard-presentation.mjs"
]) {
  execFileSync(process.execPath, [script(name)], { stdio: "inherit" });
}
console.log("Chapter 4 runtime PASS: restored interactions, save/reload, stairwell retries, scene binding, and guard presentation.");
