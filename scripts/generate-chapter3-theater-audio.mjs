import { createHash } from "node:crypto";
import { existsSync, mkdirSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { homedir, tmpdir } from "node:os";
import { dirname, join, relative, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { spawnSync } from "node:child_process";

const root = resolve(dirname(fileURLToPath(import.meta.url)), "..");
const contentPath = join(root, "src/data/chapter3-theater.audio.content.json");
const generatedPath = join(root, "src/data/chapter3-theater.audio.generated.json");
const audioRoot = join(root, "src/assets/audio");
const content = JSON.parse(readFileSync(contentPath, "utf8"));
const hasPreviousManifest = existsSync(generatedPath);
const previous = existsSync(generatedPath)
  ? JSON.parse(readFileSync(generatedPath, "utf8"))
  : { assets: {} };
const force = process.argv.includes("--force");
const verifyOnly = process.argv.includes("--verify-only");
const tempDir = mkdtempSync(join(tmpdir(), "seven-fifty-five-theater-audio-"));
const MUSIC_MODEL = "music-2.6";
const LIMITS = {
  music: { minDurationMs: 15000, maxDurationMs: 26000 },
  sfx: { minDurationMs: 300, maxDurationMs: 1800 }
};

function hash(value) {
  return createHash("sha256").update(value).digest("hex");
}

function fileHash(path) {
  return hash(readFileSync(path));
}

function findMmx() {
  const candidates = [
    process.env.MMX_BIN,
    join(homedir(), ".hermes/node/bin/mmx"),
    "/opt/homebrew/bin/mmx",
    "/usr/local/bin/mmx"
  ].filter(Boolean);
  const found = candidates.find((path) => existsSync(path));
  if (!found) throw new Error("MiniMax CLI not found. Set MMX_BIN to an executable mmx path.");
  return found;
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

function probeAudio(path, limits) {
  if (!existsSync(path)) throw new Error(`Missing audio file: ${path}`);
  const output = run("ffprobe", [
    "-v", "error",
    "-select_streams", "a:0",
    "-show_entries", "stream=codec_name,codec_type,sample_rate,channels:format=duration",
    "-of", "json",
    path
  ], `Probe ${path}`);
  const parsed = JSON.parse(output);
  const stream = parsed.streams?.find(({ codec_type }) => codec_type === "audio");
  const durationMs = Math.round(Number(parsed.format?.duration) * 1000);
  const sampleRate = Number(stream?.sample_rate);
  const channels = Number(stream?.channels);
  if (!stream || stream.codec_name !== "mp3") throw new Error(`Unexpected codec for ${path}: ${stream?.codec_name ?? "none"}`);
  if (!Number.isFinite(durationMs) || durationMs < limits.minDurationMs || durationMs > limits.maxDurationMs) {
    throw new Error(`Unexpected duration for ${path}: ${durationMs}ms`);
  }
  if (!Number.isInteger(sampleRate) || sampleRate <= 0 || !Number.isInteger(channels) || channels <= 0) {
    throw new Error(`Invalid stream metadata for ${path}`);
  }
  run("ffmpeg", ["-v", "error", "-i", path, "-f", "null", "-"], `Decode ${path}`);
  return { durationMs, codec: stream.codec_name, sampleRate, channels };
}

function probeAudibility(path) {
  const result = spawnSync("ffmpeg", [
    "-hide_banner", "-i", path,
    "-af", "volumedetect", "-f", "null", "-"
  ], {
    cwd: root,
    encoding: "utf8",
    maxBuffer: 4 * 1024 * 1024
  });
  if (result.status !== 0) throw new Error(`Audibility probe failed for ${path}`);
  const match = result.stderr.match(/max_volume:\s*(-?\d+(?:\.\d+)?)\s*dB/);
  const maxVolumeDb = Number(match?.[1]);
  if (!Number.isFinite(maxVolumeDb) || maxVolumeDb <= -45) {
    throw new Error(`Silent or unreadable sound effect: ${path} (${maxVolumeDb} dB)`);
  }
  return maxVolumeDb;
}

function generateMmxFile(args, output, label, minDurationMs) {
  let lastError;
  for (let attempt = 1; attempt <= 3; attempt += 1) {
    rmSync(output, { force: true });
    try {
      run(findMmx(), [...args, "--timeout", "180", "--non-interactive", "--quiet"], label);
      probeAudio(output, { minDurationMs, maxDurationMs: 600000 });
      return;
    } catch (error) {
      lastError = error;
      if (attempt < 3) process.stderr.write(`${label} attempt ${attempt} rejected; retrying.\n`);
    }
  }
  throw lastError;
}

function outputPath(definition) {
  return join(audioRoot, definition.path);
}

function normalizeBed(input, output, durationSeconds, loudness) {
  const fadeOutStart = Math.max(0, durationSeconds - 0.2);
  run("ffmpeg", [
    "-y", "-hide_banner", "-loglevel", "error", "-i", input,
    "-t", String(durationSeconds),
    "-af", `loudnorm=I=${loudness}:TP=-1.5:LRA=8,afade=t=in:st=0:d=0.06,afade=t=out:st=${fadeOutStart}:d=0.2`,
    "-ar", "44100", "-ac", "2", "-b:a", "192k", output
  ], `Normalize ${output}`);
}

function cutSfx(stem, definition, cutStartSeconds = definition.cutStartSeconds) {
  const output = outputPath(definition);
  const fadeOutStart = Math.max(0, definition.durationSeconds - 0.08);
  run("ffmpeg", [
    "-y", "-hide_banner", "-loglevel", "error", "-i", stem,
    "-ss", String(cutStartSeconds),
    "-t", String(definition.durationSeconds),
    "-af", `loudnorm=I=-18:TP=-1.5:LRA=6,afade=t=in:st=0:d=0.02,afade=t=out:st=${fadeOutStart}:d=0.08`,
    "-ar", "44100", "-ac", "2", "-b:a", "160k", output
  ], `Cut ${definition.cue}`);
  probeAudio(output, LIMITS.sfx);
  probeAudibility(output);
}

function validateContent() {
  if (content.chapterId !== "chapter-3-theater-audio") throw new Error(`Unexpected chapter id: ${content.chapterId}`);
  if (content.music?.length !== 3 || content.sfx?.length !== 10) {
    throw new Error("Theater audio requires exactly 3 music beds and 10 one-shot effects.");
  }
  const definitions = [...content.music, ...content.sfx];
  for (const key of ["cue", "asset", "path"]) {
    const values = definitions.map((definition) => definition[key]);
    if (values.some((value) => typeof value !== "string" || value.length === 0) || new Set(values).size !== values.length) {
      throw new Error(`Theater audio ${key} values must be non-empty and unique.`);
    }
  }
  const groups = [...new Set(content.sfx.map(({ group }) => group))];
  if (groups.length !== 2 || groups.some((group) => content.sfx.filter((item) => item.group === group).length !== 5)) {
    throw new Error("Theater sound design must contain two five-cue stems.");
  }
}

function configHash(definition, groupDefinitions) {
  return hash(JSON.stringify({ model: MUSIC_MODEL, definition, groupDefinitions }));
}

function canReuse(definition, kind, currentHash) {
  const output = outputPath(definition);
  if (force || !existsSync(output)) return false;
  const previousHash = previous.assets?.[definition.asset]?.sourceConfigHash;
  if (previousHash !== currentHash && (hasPreviousManifest || previousHash)) return false;
  try {
    probeAudio(output, LIMITS[kind]);
    if (kind === "sfx") probeAudibility(output);
    return true;
  } catch {
    return false;
  }
}

function generateMusic(definition) {
  const raw = join(tempDir, `${definition.stage}.raw.mp3`);
  generateMmxFile([
    "music", "generate", "--model", MUSIC_MODEL,
    "--prompt", definition.prompt,
    "--genre", definition.genre,
    "--mood", definition.mood,
    "--instruments", definition.instruments,
    "--bpm", String(definition.bpm),
    "--avoid", "vocals, orchestral trailer, long intro, long outro, heavy sub bass, continuous sound effects",
    "--use-case", "looping background music for a top-down pixel RPG theater",
    "--structure", "immediate start, one compact loop, small variations, clean ending",
    "--instrumental", "--format", "mp3", "--sample-rate", "44100", "--bitrate", "256000",
    "--out", raw
  ], raw, `MiniMax music ${definition.cue}`, 10000);
  normalizeBed(raw, outputPath(definition), definition.durationSeconds, -23);
  probeAudio(outputPath(definition), LIMITS.music);
}

function generateSfx(definition) {
  let lastError;
  for (let attempt = 1; attempt <= 3; attempt += 1) {
    const raw = join(tempDir, `${definition.cue.replaceAll(".", "-")}-${attempt}.raw.mp3`);
    try {
      generateMmxFile([
        "music", "generate", "--model", MUSIC_MODEL,
        "--prompt", `Create exactly one isolated non-musical game sound at the very beginning: ${definition.description}. The cue must start within the first 0.05 seconds. After the cue, leave silence.`,
        "--genre", "dry cinematic game foley",
        "--mood", "concise, tactile, readable",
        "--instruments", "foley, compact mechanical transients, short digital UI tones",
        "--avoid", "vocals, melody, harmony, rhythm, song structure, sustained pad, long reverb, ambience, delayed start, multiple cues",
        "--use-case", "one immediate one-shot sound effect for a top-down pixel RPG theater",
        "--structure", "single sound at zero seconds, then silence",
        "--instrumental", "--format", "mp3", "--sample-rate", "44100", "--bitrate", "256000",
        "--out", raw
      ], raw, `MiniMax sound effect ${definition.cue}`, 10000);
      cutSfx(raw, definition, 0);
      return;
    } catch (error) {
      lastError = error;
      if (attempt < 3) process.stderr.write(`MiniMax sound effect ${definition.cue} attempt ${attempt} rejected; retrying.\n`);
    }
  }
  throw lastError;
}

function main() {
  validateContent();
  const definitions = [
    ...content.music.map((definition) => ({ kind: "music", definition })),
    ...content.sfx.map((definition) => ({ kind: "sfx", definition }))
  ];
  definitions.forEach(({ definition }) => mkdirSync(dirname(outputPath(definition)), { recursive: true }));
  const hashes = new Map();
  const generated = [];
  for (const definition of content.music) {
    const currentHash = configHash(definition);
    hashes.set(definition.cue, currentHash);
    if (!verifyOnly && !canReuse(definition, "music", currentHash)) {
      generateMusic(definition);
      generated.push(definition.asset);
    }
  }
  for (const definition of content.sfx) {
    const currentHash = configHash(definition);
    hashes.set(definition.cue, currentHash);
    if (!verifyOnly && !canReuse(definition, "sfx", currentHash)) {
      generateSfx(definition);
      generated.push(definition.asset);
    }
  }
  const assets = {};
  const seenHashes = new Map();
  for (const { kind, definition } of definitions) {
    const path = outputPath(definition);
    const metadata = probeAudio(path, LIMITS[kind]);
    const maxVolumeDb = kind === "sfx" ? probeAudibility(path) : undefined;
    const sha256 = fileHash(path);
    if (seenHashes.has(sha256)) throw new Error(`Duplicate audio bytes for ${definition.asset} and ${seenHashes.get(sha256)}`);
    seenHashes.set(sha256, definition.asset);
    assets[definition.asset] = {
      path: relative(audioRoot, path).replaceAll("\\", "/"),
      kind,
      ...metadata,
      ...(maxVolumeDb === undefined ? {} : { maxVolumeDb }),
      sha256,
      source: kind === "music" ? `MiniMax ${MUSIC_MODEL}` : `MiniMax ${MUSIC_MODEL} sound-design cut`,
      sourceConfigHash: hashes.get(definition.cue)
    };
  }
  const manifest = {
    version: 1,
    generatedAt: verifyOnly && typeof previous.generatedAt === "string" ? previous.generatedAt : new Date().toISOString(),
    assets
  };
  writeFileSync(generatedPath, `${JSON.stringify(manifest, null, 2)}\n`, "utf8");
  process.stdout.write(`${JSON.stringify({ generated, verified: assets, manifest: generatedPath }, null, 2)}\n`);
}

try {
  main();
} finally {
  rmSync(tempDir, { recursive: true, force: true });
}
