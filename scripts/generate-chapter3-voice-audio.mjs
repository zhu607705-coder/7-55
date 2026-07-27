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
const contentPath = join(root, "src/data/chapter3-story-lines.json");
const generatedPath = join(root, "src/data/chapter3-story.audio.generated.json");
const checkpointPath = join(
  root,
  "node_modules/.cache/seven-fifty-five/chapter3-story.audio.checkpoint.json"
);
const audioRoot = join(root, "src/assets/audio");
const voiceDir = join(audioRoot, "chapter3/vo");
const content = JSON.parse(readFileSync(contentPath, "utf8"));
const previousManifest = existsSync(generatedPath)
  ? JSON.parse(readFileSync(generatedPath, "utf8"))
  : { assets: {} };
const previousCheckpoint = existsSync(checkpointPath)
  ? JSON.parse(readFileSync(checkpointPath, "utf8"))
  : { assets: {} };
const force = process.argv.includes("--force");
const verifyOnly = process.argv.includes("--verify-only");
const previous = {
  ...previousManifest,
  assets: {
    ...(previousManifest.assets ?? {}),
    ...(verifyOnly ? {} : previousCheckpoint.assets ?? {})
  }
};
const tempDir = mkdtempSync(join(tmpdir(), "seven-fifty-five-chapter3-voice-"));
const MODEL = "speech-2.8-hd";
const REQUEST_GAP_MS = 2200;

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
  if (!found) {
    throw new Error("MiniMax CLI not found. Set MMX_BIN to an executable mmx path.");
  }
  return found;
}

function runMmx(args, label) {
  let lastError;
  for (let attempt = 1; attempt <= 4; attempt += 1) {
    try {
      run(findMmx(), [...args, "--timeout", "180", "--non-interactive", "--quiet"], label);
      Atomics.wait(new Int32Array(new SharedArrayBuffer(4)), 0, 0, REQUEST_GAP_MS);
      return;
    } catch (error) {
      lastError = error;
      const message = error instanceof Error ? error.message : String(error);
      const retryable = /timed out|timeout|network request failed|econnreset|enotfound|socket hang up|fetch failed|rate limit exceeded|too many requests|\brpm\b|\b429\b/i.test(message);
      if (!retryable || attempt === 4) throw error;
      process.stderr.write(`${label} attempt ${attempt} did not complete; retrying.\n`);
      Atomics.wait(new Int32Array(new SharedArrayBuffer(4)), 0, 0, attempt * 15000);
    }
  }
  throw lastError;
}

function probeAudio(path) {
  if (!existsSync(path)) throw new Error(`Missing Chapter 3 voice asset: ${path}`);
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
  if (!stream || stream.codec_name !== "mp3") {
    throw new Error(`Chapter 3 voice asset must be mp3: ${path}`);
  }
  if (!Number.isFinite(durationMs) || durationMs < 250 || durationMs > 30000) {
    throw new Error(`Unexpected Chapter 3 voice duration ${durationMs}ms: ${path}`);
  }
  const sampleRate = Number(stream.sample_rate);
  const channels = Number(stream.channels);
  if (sampleRate !== 32000 || channels !== 1) {
    throw new Error(`Chapter 3 voice must be 32000Hz mono: ${path}`);
  }
  run("ffmpeg", ["-v", "error", "-i", path, "-f", "null", "-"], `Decode ${path}`);
  return { durationMs, codec: stream.codec_name, sampleRate, channels };
}

function normalizeVoice(input, output) {
  run("ffmpeg", [
    "-y", "-hide_banner", "-loglevel", "error", "-i", input,
    "-af",
    "silenceremove=start_periods=1:start_duration=0.04:start_threshold=-48dB,areverse,silenceremove=start_periods=1:start_duration=0.08:start_threshold=-48dB,areverse,loudnorm=I=-16:TP=-1.5:LRA=7",
    "-ar", "32000", "-ac", "1", "-b:a", "128k", output
  ], `Normalize ${output}`);
}

function replaceValidatedFile(source, destination) {
  const staged = `${destination}.tmp-${process.pid}`;
  rmSync(staged, { force: true });
  copyFileSync(source, staged);
  renameSync(staged, destination);
}

function writeJsonAtomic(path, value) {
  mkdirSync(dirname(path), { recursive: true });
  const staged = `${path}.tmp-${process.pid}`;
  writeFileSync(staged, `${JSON.stringify(value, null, 2)}\n`);
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

function validateContent() {
  if (content.version !== 1 || !Array.isArray(content.lines) || content.lines.length === 0) {
    throw new Error("Invalid Chapter 3 story-line catalog.");
  }
  const keys = new Set();
  const subtitles = new Set();
  for (const line of content.lines) {
    if (
      typeof line.key !== "string"
      || typeof line.subtitleZh !== "string"
      || typeof line.voiceTextEn !== "string"
      || !["male_narrator", "female_system"].includes(line.voiceRole)
    ) {
      throw new Error(`Invalid Chapter 3 story line: ${JSON.stringify(line)}`);
    }
    if (keys.has(line.key)) throw new Error(`Duplicate Chapter 3 story key: ${line.key}`);
    if (subtitles.has(line.subtitleZh)) throw new Error(`Duplicate Chapter 3 subtitle: ${line.subtitleZh}`);
    keys.add(line.key);
    subtitles.add(line.subtitleZh);
    const voice = content.voices?.[line.voiceRole];
    if (!voice?.id || voice.language !== "English") {
      throw new Error(`Invalid voice profile for ${line.key}`);
    }
    if (line.voiceRole === "male_narrator" && line.pitch !== voice.basePitch) {
      throw new Error(`Narrator pitch drift for ${line.key}: expected ${voice.basePitch}`);
    }
  }
}

function sourceConfig(line) {
  const voice = content.voices[line.voiceRole];
  return {
    model: MODEL,
    voiceId: voice.id,
    language: voice.language,
    speed: line.speed,
    pitch: line.pitch,
    volume: 1,
    sampleRate: 32000,
    bitrate: 128000,
    channels: 1,
    voiceTextEn: line.voiceTextEn
  };
}

function canonicalManifestMatches(assets) {
  return content.lines.every((line) => {
    const asset = `vo_${line.key}`;
    const current = assets[asset];
    const canonical = previousManifest.assets?.[asset];
    return current
      && canonical?.sha256 === current.sha256
      && canonical?.sourceTextHash === hash(line.voiceTextEn)
      && canonical?.sourceConfigHash === hash(JSON.stringify(sourceConfig(line)));
  });
}

function generateVoice(line, output) {
  const voice = content.voices[line.voiceRole];
  const raw = join(tempDir, `${line.key}.raw.mp3`);
  const normalized = join(tempDir, `${line.key}.normalized.mp3`);
  runMmx([
    "speech", "synthesize",
    "--model", MODEL,
    "--voice", voice.id,
    "--language", voice.language,
    "--speed", String(line.speed),
    "--volume", "1",
    "--pitch", String(line.pitch),
    "--sample-rate", "32000",
    "--bitrate", "128000",
    "--channels", "1",
    "--text", line.voiceTextEn,
    "--out", raw
  ], `MiniMax Chapter 3 voice ${line.key}`);
  normalizeVoice(raw, normalized);
  probeAudio(normalized);
  replaceValidatedFile(normalized, output);
}

function main() {
  validateContent();
  mkdirSync(voiceDir, { recursive: true });
  const generated = [];
  const assets = {};
  const seenHashes = new Map();

  for (const line of content.lines) {
    const asset = `vo_${line.key}`;
    const output = join(voiceDir, `${asset}.mp3`);
    const sourceTextHash = hash(line.voiceTextEn);
    const sourceConfigHash = hash(JSON.stringify(sourceConfig(line)));
    const cached = previous.assets?.[asset];
    const reusable = !force
      && existsSync(output)
      && cached?.sourceTextHash === sourceTextHash
      && cached?.sourceConfigHash === sourceConfigHash
      && cached?.sha256 === hash(readFileSync(output));
    if (!reusable) continue;
    try {
      const metadata = probeAudio(output);
      const sha256 = hash(readFileSync(output));
      if (seenHashes.has(sha256)) continue;
      seenHashes.set(sha256, asset);
      assets[asset] = {
        path: relative(audioRoot, output).replaceAll("\\", "/"),
        ...metadata,
        sha256,
        sourceTextHash,
        sourceConfigHash,
        source: `MiniMax ${MODEL} ${content.voices[line.voiceRole].id}`
      };
    } catch {
      // Regenerate invalid cached files below.
    }
  }

  for (const line of content.lines) {
    const asset = `vo_${line.key}`;
    if (assets[asset]) continue;
    const output = join(voiceDir, `${asset}.mp3`);
    const sourceTextHash = hash(line.voiceTextEn);
    const sourceConfigHash = hash(JSON.stringify(sourceConfig(line)));
    if (verifyOnly) throw new Error(`Chapter 3 voice requires regeneration: ${asset}`);
    generateVoice(line, output);
    generated.push(asset);
    const metadata = probeAudio(output);
    const sha256 = hash(readFileSync(output));
    const duplicate = seenHashes.get(sha256);
    if (duplicate) throw new Error(`Duplicate Chapter 3 voice bytes for ${asset} and ${duplicate}`);
    seenHashes.set(sha256, asset);
    assets[asset] = {
      path: relative(audioRoot, output).replaceAll("\\", "/"),
      ...metadata,
      sha256,
      sourceTextHash,
      sourceConfigHash,
      source: `MiniMax ${MODEL} ${content.voices[line.voiceRole].id}`
    };
    writeCheckpoint(assets);
  }

  if (Object.keys(assets).length !== content.lines.length) {
    throw new Error(`Chapter 3 voice manifest is incomplete: ${Object.keys(assets).length}/${content.lines.length}`);
  }
  if (!verifyOnly && (!canonicalManifestMatches(assets) || generated.length > 0)) {
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
