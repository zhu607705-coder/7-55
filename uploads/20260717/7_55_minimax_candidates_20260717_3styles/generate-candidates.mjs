import { createHash } from "node:crypto";
import { existsSync, mkdirSync, readFileSync, statSync, writeFileSync } from "node:fs";
import { dirname, join, resolve } from "node:path";
import { spawnSync } from "node:child_process";
import { fileURLToPath } from "node:url";

const here = dirname(fileURLToPath(import.meta.url));
const planPath = join(here, "generation-plan.json");
const plan = JSON.parse(readFileSync(planPath, "utf8"));
const manifestPath = join(here, "reports/manifest.json");
const failuresPath = join(here, "reports/generation-failures.log");
const force = process.argv.includes("--force");
const requestedKinds = new Set(process.argv.filter((argument) => argument.startsWith("--kind=")).map((argument) => argument.slice(7)));
const kinds = requestedKinds.size > 0 ? requestedKinds : new Set(["images", "music", "voice", "sfx"]);

mkdirSync(join(here, "reports"), { recursive: true });
const manifest = existsSync(manifestPath)
  ? JSON.parse(readFileSync(manifestPath, "utf8"))
  : { project: plan.project, generatedAt: new Date().toISOString(), integration: "none", assets: {} };
const failures = [];

function hashFile(path) {
  return createHash("sha256").update(readFileSync(path)).digest("hex");
}

function dimensionsFor(path) {
  if (path.includes("/phone/")) return [768, 1536];
  if (path.includes("/rpg/") && path.includes("sports")) return [1024, 1024];
  if (path.includes("/rpg/") || path.includes("/characters/")) return [1536, 864];
  if (path.includes("/props/") && !path.includes("attachment_slots")) return [1024, 1024];
  return [1280, 960];
}

function run(command, args, label) {
  const result = spawnSync(command, args, { cwd: resolve(here, "../../.."), encoding: "utf8", maxBuffer: 16 * 1024 * 1024 });
  if (result.status !== 0) {
    const output = `${result.stderr || ""}\n${result.stdout || ""}`.trim().slice(-1800);
    throw new Error(`${label} failed: ${output || `exit ${result.status}`}`);
  }
  return result.stdout || "";
}

function runMmx(args, label) {
  let lastError;
  for (let attempt = 1; attempt <= 3; attempt += 1) {
    try {
      return run("mmx", [...args, "--timeout", "180", "--non-interactive", "--quiet"], label);
    } catch (error) {
      lastError = error;
      if (attempt < 3) {
        process.stderr.write(`${label}: retry ${attempt}/2\n`);
      }
    }
  }
  throw lastError;
}

function record(path, kind, prompt, extra = {}) {
  const absolute = join(here, path);
  const item = {
    path,
    kind,
    prompt,
    ...extra,
    generatedAt: new Date().toISOString(),
    bytes: statSync(absolute).size,
    sha256: hashFile(absolute)
  };
  manifest.assets[path] = item;
}

function shouldSkip(path) {
  return !force && existsSync(join(here, path)) && statSync(join(here, path)).size > 0;
}

function generateImage([path, prompt]) {
  if (shouldSkip(path)) return record(path, "image", prompt, { status: "existing" });
  const output = join(here, path);
  mkdirSync(dirname(output), { recursive: true });
  const [width, height] = dimensionsFor(path);
  runMmx(["image", "generate", "--prompt", prompt, "--width", String(width), "--height", String(height), "--response-format", "url", "--out", output], `image ${path}`);
  record(path, "image", prompt, { status: "generated", width, height });
}

function generateMusic([path, prompt]) {
  if (shouldSkip(path)) return record(path, "music", prompt, { status: "existing" });
  const output = join(here, path);
  mkdirSync(dirname(output), { recursive: true });
  runMmx(["music", "generate", "--model", "music-2.6", "--prompt", prompt, "--instrumental", "--format", "mp3", "--out", output], `music ${path}`);
  record(path, "music", prompt, { status: "generated", model: "music-2.6" });
}

function generateVoice([path, role, text]) {
  if (shouldSkip(path)) return record(path, "voice", text, { status: "existing", voiceRole: role });
  const output = join(here, path);
  mkdirSync(dirname(output), { recursive: true });
  const voice = role === "female_system" ? "English_Graceful_Lady" : "English_expressive_narrator";
  const pitch = role === "female_system" ? -1 : -4;
  runMmx(["speech", "synthesize", "--model", "speech-2.8-hd", "--voice", voice, "--text", text, "--speed", "1.0", "--pitch", String(pitch), "--language", "en", "--format", "mp3", "--sample-rate", "32000", "--bitrate", "128000", "--channels", "1", "--out", output], `voice ${path}`);
  record(path, "voice", text, { status: "generated", voiceRole: role, voice, pitch });
}

function generateSfx([path, prompt]) {
  if (shouldSkip(path)) return record(path, "sfx", prompt, { status: "existing" });
  const output = join(here, path);
  mkdirSync(dirname(output), { recursive: true });
  const stem = `${output}.stem.mp3`;
  runMmx(["music", "generate", "--model", "music-2.6", "--prompt", prompt, "--instrumental", "--format", "mp3", "--out", stem], `sfx ${path}`);
  run("ffmpeg", ["-y", "-hide_banner", "-loglevel", "error", "-i", stem, "-t", "1.8", "-af", "afade=t=in:st=0:d=0.03,afade=t=out:st=1.62:d=0.18", "-ar", "44100", "-ac", "2", "-b:a", "192k", output], `cut sfx ${path}`);
  run("rm", ["-f", stem], `clean sfx stem ${path}`);
  record(path, "sfx", prompt, { status: "generated", model: "music-2.6", durationSeconds: 1.8 });
}

function processKind(kind, entries, generator) {
  if (!kinds.has(kind)) return;
  for (const entry of entries) {
    const label = entry[0];
    process.stdout.write(`[${kind}] ${label}\n`);
    try {
      generator(entry);
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      failures.push(`${new Date().toISOString()}\t${kind}\t${label}\t${message}`);
      manifest.assets[label] = { path: label, kind, prompt: entry[1], status: "failed", error: message };
      process.stderr.write(`${message}\n`);
    }
    writeFileSync(manifestPath, `${JSON.stringify(manifest, null, 2)}\n`);
  }
}

processKind("images", plan.visualCandidates, generateImage);
processKind("music", plan.musicCandidates, generateMusic);
processKind("voice", plan.voiceCandidates, generateVoice);
processKind("sfx", plan.sfxCandidates, generateSfx);

manifest.finishedAt = new Date().toISOString();
manifest.failureCount = failures.length;
writeFileSync(manifestPath, `${JSON.stringify(manifest, null, 2)}\n`);
writeFileSync(failuresPath, failures.length ? `${failures.join("\n")}\n` : "");
process.stdout.write(`completed assets=${Object.keys(manifest.assets).length} failures=${failures.length}\n`);
