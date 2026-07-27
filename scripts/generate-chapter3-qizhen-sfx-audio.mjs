import { createHash } from "node:crypto";
import {
  copyFileSync,
  existsSync,
  mkdirSync,
  mkdtempSync,
  readFileSync,
  renameSync,
  rmSync,
  writeFileSync
} from "node:fs";
import { homedir, tmpdir } from "node:os";
import { delimiter, dirname, join, relative, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { spawnSync } from "node:child_process";

const root = resolve(dirname(fileURLToPath(import.meta.url)), "..");
const contentPath = join(root, "src/data/chapter3-qizhen.audio.content.json");
const generatedPath = join(root, "src/data/chapter3-qizhen-sfx.audio.generated.json");
const checkpointPath = join(
  root,
  "node_modules/.cache/seven-fifty-five/chapter3-qizhen-sfx.audio.checkpoint.json"
);
const audioRoot = join(root, "src/assets/audio");
const content = JSON.parse(readFileSync(contentPath, "utf8"));
const previousManifest = existsSync(generatedPath)
  ? JSON.parse(readFileSync(generatedPath, "utf8"))
  : { assets: {} };
const previousCheckpoint = existsSync(checkpointPath)
  ? JSON.parse(readFileSync(checkpointPath, "utf8"))
  : { assets: {} };
const force = process.argv.includes("--force");
const verifyOnly = process.argv.includes("--verify-only");
const checkpointExisting = process.argv.includes("--checkpoint-existing");
const previous = {
  ...previousManifest,
  assets: {
    ...(previousManifest.assets ?? {}),
    ...(verifyOnly ? {} : previousCheckpoint.assets ?? {})
  }
};
const tempDir = mkdtempSync(join(tmpdir(), "seven-fifty-five-qizhen-sfx-"));
const MODEL = "music-2.6";
const GENERATION_MODE = "isolated-one-shot-v1";

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
    const detail = (result.stderr || result.stdout || result.error?.message || "unknown error")
      .trim()
      .slice(0, 1800);
    throw new Error(`${label} failed: ${detail}`);
  }
  return result.stdout;
}

function findMmx() {
  const pathCandidates = (process.env.PATH ?? "")
    .split(delimiter)
    .filter(Boolean)
    .map((directory) => join(directory, "mmx"));
  const candidates = [
    process.env.MMX_BIN,
    ...pathCandidates,
    join(homedir(), ".hermes/node/bin/mmx"),
    "/opt/homebrew/bin/mmx",
    "/usr/local/bin/mmx"
  ].filter(Boolean);
  const found = candidates.find((candidate) => existsSync(candidate));
  if (!found) throw new Error("MiniMax CLI not found. Set MMX_BIN to an executable mmx path.");
  return found;
}

function runMmx(args, label) {
  let lastError;
  for (let attempt = 1; attempt <= 4; attempt += 1) {
    try {
      run(findMmx(), [...args, "--timeout", "180", "--non-interactive", "--quiet"], label);
      return;
    } catch (error) {
      lastError = error;
      const message = error instanceof Error ? error.message : String(error);
      const retryable = /timed out|timeout|network request failed|econnreset|enotfound|socket hang up|fetch failed/i.test(message);
      if (!retryable || attempt === 4) throw error;
      process.stderr.write(`${label} attempt ${attempt} did not complete; retrying.\n`);
      Atomics.wait(new Int32Array(new SharedArrayBuffer(4)), 0, 0, attempt * 1200);
    }
  }
  throw lastError;
}

function outputPath(definition) {
  return join(audioRoot, definition.path);
}

function replaceValidatedFile(source, destination) {
  const staged = `${destination}.tmp-${process.pid}`;
  rmSync(staged, { force: true });
  copyFileSync(source, staged);
  renameSync(staged, destination);
}

function probeAudio(path) {
  if (!existsSync(path)) throw new Error(`Missing Qizhen sound effect: ${path}`);
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
  if (!stream || stream.codec_name !== "mp3") throw new Error(`Qizhen sound effect must be mp3: ${path}`);
  if (!Number.isFinite(durationMs) || durationMs < 300 || durationMs > 1800) {
    throw new Error(`Unexpected Qizhen sound-effect duration ${durationMs}ms: ${path}`);
  }
  const sampleRate = Number(stream.sample_rate);
  const channels = Number(stream.channels);
  if (sampleRate !== 44100 || channels !== 2) {
    throw new Error(`Qizhen sound effect must be 44100Hz stereo: ${path}`);
  }
  run("ffmpeg", ["-v", "error", "-i", path, "-f", "null", "-"], `Decode ${path}`);
  return { durationMs, codec: stream.codec_name, sampleRate, channels };
}

function sourceConfigHash(definition) {
  return hash(JSON.stringify({
    model: MODEL,
    generationMode: GENERATION_MODE,
    cue: definition.cue,
    description: definition.description,
    durationSeconds: definition.durationSeconds
  }));
}

function validateContent() {
  if (content.chapterId !== "chapter-3-qizhen-audio" || !Array.isArray(content.sfx) || content.sfx.length !== 10) {
    throw new Error("Qizhen sound design requires exactly ten one-shot effects.");
  }
  for (const key of ["cue", "asset", "path"]) {
    const values = content.sfx.map((definition) => definition[key]);
    if (values.some((value) => typeof value !== "string" || !value) || new Set(values).size !== values.length) {
      throw new Error(`Qizhen sound-effect ${key} values must be unique.`);
    }
  }
  const groups = [...new Set(content.sfx.map(({ group }) => group))];
  if (groups.length !== 2 || groups.some((group) => content.sfx.filter((item) => item.group === group).length !== 5)) {
    throw new Error("Qizhen sound design requires two groups with five cues each.");
  }
}

function generateDefinition(definition) {
  const raw = join(tempDir, `${definition.asset}.raw.mp3`);
  const normalized = join(tempDir, `${definition.asset}.normalized.mp3`);
  const output = outputPath(definition);
  const fadeOutStart = Math.max(0, definition.durationSeconds - 0.08);
  runMmx([
    "music", "generate",
    "--model", MODEL,
    "--prompt", `One isolated non-musical game sound effect: ${definition.description}. Start the sound immediately and leave silence after it.`,
    "--genre", "game sound effects",
    "--mood", "dry, concise, readable",
    "--instruments", "water foley, paper foley, short digital UI tones, compact mechanical clicks",
    "--avoid", "vocals, song structure, sustained pad, continuous beat, long reverb, repeated cues, delayed attack",
    "--use-case", `one-shot cue ${definition.cue} for a top-down pixel RPG lake investigation`,
    "--structure", "one immediate transient followed by silence",
    "--instrumental",
    "--format", "mp3",
    "--sample-rate", "44100",
    "--bitrate", "256000",
    "--out", raw
  ], `MiniMax Qizhen sound effect ${definition.cue}`);
  run("ffmpeg", [
    "-y", "-hide_banner", "-loglevel", "error", "-i", raw,
    "-af",
    `silenceremove=start_periods=1:start_duration=0.02:start_threshold=-50dB,atrim=duration=${definition.durationSeconds},loudnorm=I=-18:TP=-1.5:LRA=6,apad=pad_dur=${definition.durationSeconds},atrim=duration=${definition.durationSeconds},afade=t=in:st=0:d=0.02,afade=t=out:st=${fadeOutStart}:d=0.08`,
    "-ar", "44100", "-ac", "2", "-b:a", "160k", normalized
  ], `Normalize ${definition.cue}`);
  probeAudio(normalized);
  replaceValidatedFile(normalized, output);
}

function writeJsonAtomic(path, value) {
  mkdirSync(dirname(path), { recursive: true });
  const staged = `${path}.tmp-${process.pid}`;
  writeFileSync(staged, `${JSON.stringify({
    ...value
  }, null, 2)}\n`);
  renameSync(staged, path);
}

function writeManifest(assets) {
  writeJsonAtomic(generatedPath, {
    version: 1,
    generatedAt: new Date().toISOString(),
    assets
  });
}

function writeCheckpoint(assets) {
  writeJsonAtomic(checkpointPath, {
    version: 1,
    updatedAt: new Date().toISOString(),
    assets
  });
}

function canonicalManifestMatches(assets, configHashes) {
  return content.sfx.every((definition) => {
    const current = assets[definition.asset];
    const canonical = previousManifest.assets?.[definition.asset];
    return current
      && canonical?.sha256 === current.sha256
      && canonical?.sourceConfigHash === configHashes.get(definition.asset);
  });
}

function main() {
  validateContent();
  for (const definition of content.sfx) mkdirSync(dirname(outputPath(definition)), { recursive: true });
  const generated = [];
  const configHashes = new Map();
  for (const definition of content.sfx) {
    configHashes.set(definition.asset, sourceConfigHash(definition));
  }

  const assets = {};
  const seenHashes = new Map();
  for (const definition of content.sfx) {
    const output = outputPath(definition);
    const configHash = configHashes.get(definition.asset);
    const cached = previous.assets?.[definition.asset];
    const reusable = !force
      && existsSync(output)
      && cached?.sourceConfigHash === configHash
      && cached?.sha256 === hash(readFileSync(output));
    if (reusable) {
      try {
        const metadata = probeAudio(output);
        const sha256 = hash(readFileSync(output));
        if (!seenHashes.has(sha256)) {
          seenHashes.set(sha256, definition.asset);
          assets[definition.asset] = {
            path: relative(audioRoot, output).replaceAll("\\", "/"),
            kind: "sfx",
            ...metadata,
            sha256,
            sourceConfigHash: configHash,
            source: `MiniMax ${MODEL} isolated one-shot`
          };
        }
      } catch (error) {
        if (verifyOnly) throw error;
        // Regenerate invalid cached files below.
      }
    }
  }

  if (checkpointExisting) {
    const incomplete = Object.keys(assets).length !== content.sfx.length;
    if (incomplete) {
      writeCheckpoint(assets);
      process.exitCode = 1;
    } else {
      if (!canonicalManifestMatches(assets, configHashes)) writeManifest(assets);
      rmSync(checkpointPath, { force: true });
    }
    process.stdout.write(`${JSON.stringify({
      generated,
      verified: Object.keys(assets),
      incomplete,
      manifest: incomplete ? null : generatedPath,
      checkpoint: incomplete ? checkpointPath : null
    }, null, 2)}\n`);
    return;
  }

  for (const definition of content.sfx) {
    if (assets[definition.asset]) continue;
    if (verifyOnly) throw new Error(`Qizhen sound effect requires regeneration: ${definition.asset}`);
    generateDefinition(definition);
    const output = outputPath(definition);
    const metadata = probeAudio(output);
    const sha256 = hash(readFileSync(output));
    const duplicate = seenHashes.get(sha256);
    if (duplicate) {
      throw new Error(`Duplicate Qizhen sound-effect bytes for ${definition.asset} and ${duplicate}`);
    }
    seenHashes.set(sha256, definition.asset);
    assets[definition.asset] = {
      path: relative(audioRoot, output).replaceAll("\\", "/"),
      kind: "sfx",
      ...metadata,
      sha256,
      sourceConfigHash: configHashes.get(definition.asset),
      source: `MiniMax ${MODEL} isolated one-shot`
    };
    generated.push(definition.asset);
    writeCheckpoint(assets);
  }

  if (Object.keys(assets).length !== content.sfx.length) {
    throw new Error(`Qizhen sound-effect manifest is incomplete: ${Object.keys(assets).length}/${content.sfx.length}`);
  }
  if (!verifyOnly && (!canonicalManifestMatches(assets, configHashes) || generated.length > 0)) {
    writeManifest(assets);
  }
  if (!verifyOnly) rmSync(checkpointPath, { force: true });
  process.stdout.write(`${JSON.stringify({
    generated,
    verified: Object.keys(assets),
    manifest: generatedPath
  }, null, 2)}\n`);
}

try {
  main();
} finally {
  rmSync(tempDir, { recursive: true, force: true });
}
