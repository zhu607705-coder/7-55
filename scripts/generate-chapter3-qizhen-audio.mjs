import { createHash } from "node:crypto";
import { existsSync, mkdirSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { homedir, tmpdir } from "node:os";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { spawnSync } from "node:child_process";

const root = resolve(dirname(fileURLToPath(import.meta.url)), "..");
const contentPath = join(root, "src/data/chapter3-qizhen.audio.content.json");
const generatedPath = join(root, "src/data/chapter3-qizhen.audio.generated.json");
const audioRoot = join(root, "src/assets/audio");
const content = JSON.parse(readFileSync(contentPath, "utf8"));
const previous = existsSync(generatedPath)
  ? JSON.parse(readFileSync(generatedPath, "utf8"))
  : { assets: {} };
const force = process.argv.includes("--force");
const verifyOnly = process.argv.includes("--verify-only");
const tempDir = mkdtempSync(join(tmpdir(), "seven-fifty-five-qizhen-audio-"));

function hash(value) {
  return createHash("sha256").update(value).digest("hex");
}

function run(command, args, label) {
  const result = spawnSync(command, args, {
    cwd: root,
    encoding: "utf8",
    maxBuffer: 16 * 1024 * 1024
  });
  if (result.status !== 0) {
    const detail = (result.stderr || result.stdout || result.error?.message || "unknown error").trim().slice(0, 1800);
    throw new Error(`${label} failed: ${detail}`);
  }
  return result.stdout;
}

function findMmx() {
  const candidates = [
    process.env.MMX_BIN,
    join(homedir(), ".hermes/node/bin/mmx"),
    "/opt/homebrew/bin/mmx",
    "/usr/local/bin/mmx"
  ].filter(Boolean);
  const found = candidates.find((candidate) => existsSync(candidate));
  if (!found) throw new Error("MiniMax CLI not found. Set MMX_BIN to an executable mmx path.");
  return found;
}

function outputPath(definition) {
  return join(audioRoot, definition.path);
}

function sourceConfigHash(definition) {
  return hash(JSON.stringify({ model: content.model, definition }));
}

function probeAudio(path, expectedDurationSeconds) {
  if (!existsSync(path)) throw new Error(`Missing Qizhen audio file: ${path}`);
  const raw = run("ffprobe", [
    "-v", "error",
    "-select_streams", "a:0",
    "-show_entries", "stream=codec_name,codec_type,sample_rate,channels:format=duration",
    "-of", "json",
    path
  ], `Probe ${path}`);
  const parsed = JSON.parse(raw);
  const stream = parsed.streams?.find(({ codec_type }) => codec_type === "audio");
  const durationMs = Math.round(Number(parsed.format?.duration) * 1000);
  const expectedDurationMs = Math.round(expectedDurationSeconds * 1000);
  if (!stream || stream.codec_name !== "mp3") throw new Error(`Unexpected codec for ${path}`);
  if (Math.abs(durationMs - expectedDurationMs) > 80) {
    throw new Error(`Unexpected duration for ${path}: ${durationMs}ms; expected ${expectedDurationMs}ms`);
  }
  run("ffmpeg", ["-v", "error", "-i", path, "-f", "null", "-"], `Decode ${path}`);
  return {
    durationMs,
    codec: stream.codec_name,
    sampleRate: Number(stream.sample_rate),
    channels: Number(stream.channels)
  };
}

function generate(definition) {
  const raw = join(tempDir, `${definition.asset}.raw.mp3`);
  run(findMmx(), [
    "music", "generate",
    "--model", content.model,
    "--prompt", definition.prompt,
    "--genre", definition.genre,
    "--mood", definition.mood,
    "--instruments", definition.instruments,
    "--bpm", String(definition.bpm),
    "--avoid", "vocals, orchestral trailer, heavy bass, long intro, long outro, continuous sound effects",
    "--use-case", "looping background music for a top-down pixel RPG lake investigation",
    "--structure", "immediate start, compact loop, small variations, clean ending",
    "--instrumental",
    "--format", "mp3",
    "--sample-rate", "44100",
    "--bitrate", "256000",
    "--out", raw,
    "--timeout", "180",
    "--non-interactive",
    "--quiet"
  ], `MiniMax music ${definition.cue}`);
  const fadeOutStart = Math.max(0, definition.durationSeconds - 0.2);
  run("ffmpeg", [
    "-y", "-hide_banner", "-loglevel", "error", "-i", raw,
    "-t", String(definition.durationSeconds),
    "-af", `loudnorm=I=-23:TP=-1.5:LRA=8,afade=t=in:st=0:d=0.06,afade=t=out:st=${fadeOutStart}:d=0.2`,
    "-ar", "44100", "-ac", "2", "-b:a", "192k", outputPath(definition)
  ], `Normalize ${definition.asset}`);
}

function validateContent() {
  if (content.chapterId !== "chapter-3-qizhen-audio" || content.model !== "music-2.6") {
    throw new Error("Unexpected Qizhen audio content metadata");
  }
  if (!Array.isArray(content.music) || content.music.length !== 3) {
    throw new Error("Qizhen audio requires exactly three music beds");
  }
  for (const key of ["cue", "asset", "path"]) {
    const values = content.music.map((definition) => definition[key]);
    if (values.some((value) => typeof value !== "string" || value.length === 0) || new Set(values).size !== values.length) {
      throw new Error(`Qizhen audio ${key} values must be non-empty and unique`);
    }
  }
}

function main() {
  validateContent();
  const generated = [];
  for (const definition of content.music) {
    const path = outputPath(definition);
    mkdirSync(dirname(path), { recursive: true });
    const configHash = sourceConfigHash(definition);
    const previousHash = previous.assets?.[definition.asset]?.sourceConfigHash;
    const reusable = existsSync(path) && !force && (!previousHash || previousHash === configHash);
    if (!reusable) {
      if (verifyOnly) throw new Error(`Qizhen audio requires regeneration: ${definition.asset}`);
      generate(definition);
      generated.push(definition.asset);
    }
    probeAudio(path, definition.durationSeconds);
  }

  const assets = {};
  for (const definition of content.music) {
    const path = outputPath(definition);
    const metadata = probeAudio(path, definition.durationSeconds);
    assets[definition.asset] = {
      path: definition.path,
      ...metadata,
      sha256: hash(readFileSync(path)),
      sourceConfigHash: sourceConfigHash(definition)
    };
  }
  writeFileSync(generatedPath, `${JSON.stringify({
    version: 1,
    chapterId: content.chapterId,
    model: content.model,
    generatedAt: new Date().toISOString(),
    assets
  }, null, 2)}\n`);
  process.stdout.write(`${JSON.stringify({ generated, verified: Object.keys(assets), manifest: generatedPath })}\n`);
}

try {
  main();
} finally {
  rmSync(tempDir, { recursive: true, force: true });
}
