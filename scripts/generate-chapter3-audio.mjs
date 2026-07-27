import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { spawnSync } from "node:child_process";

const root = resolve(dirname(fileURLToPath(import.meta.url)), "..");
const verifyOnly = process.argv.includes("--verify-only");
const force = process.argv.includes("--force");
const voiceOnly = process.argv.includes("--voice-only");
const mediaOnly = process.argv.includes("--media-only");

if (voiceOnly && mediaOnly) {
  throw new Error("--voice-only and --media-only cannot be used together.");
}

const mediaScripts = [
  "generate-chapter3-canteen-audio.mjs",
  "generate-chapter3-theater-audio.mjs",
  "generate-chapter3-qizhen-audio.mjs",
  "generate-chapter3-qizhen-sfx-audio.mjs"
];
const voiceScripts = ["generate-chapter3-voice-audio.mjs"];
const scripts = voiceOnly
  ? voiceScripts
  : mediaOnly
    ? mediaScripts
    : [...mediaScripts, ...voiceScripts];
const forwardedArgs = [
  ...(verifyOnly ? ["--verify-only"] : []),
  ...(force ? ["--force"] : [])
];
const results = [];

for (const script of scripts) {
  const result = spawnSync(process.execPath, [join(root, "scripts", script), ...forwardedArgs], {
    cwd: root,
    encoding: "utf8",
    maxBuffer: 32 * 1024 * 1024,
    env: process.env
  });
  if (result.status !== 0) {
    const detail = (result.stderr || result.stdout || result.error?.message || "unknown error")
      .trim()
      .slice(0, 3000);
    throw new Error(`${script} failed: ${detail}`);
  }
  const output = result.stdout.trim();
  let parsed = output;
  try {
    parsed = JSON.parse(output);
  } catch {
    // Retain the bounded textual output for scripts with legacy reporting.
  }
  results.push({ script, result: parsed });
}

process.stdout.write(`${JSON.stringify({
  mode: verifyOnly ? "verify-only" : force ? "force" : "incremental",
  scripts: results
}, null, 2)}\n`);
