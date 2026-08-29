#!/usr/bin/env node

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
const contentPath = join(root, "src/data/pursuit.audio.content.json");
const generatedPath = join(root, "src/data/pursuit.audio.generated.json");
const checkpointPath = join(
  root,
  "node_modules/.cache/seven-fifty-five/pursuit.audio.checkpoint.json"
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
const previousAssets = {
  ...(previousManifest.assets ?? {}),
  ...(verifyOnly ? {} : previousCheckpoint.assets ?? {})
};
const tempDir = mkdtempSync(join(tmpdir(), "seven-fifty-five-pursuit-audio-"));
const MUSIC_MODEL = "music-2.6";
const SPEECH_MODEL = "speech-2.8-hd";
const REQUEST_GAP_MS = 2200;
const DURATION_TOLERANCE_MS = 90;
const generatedSourceByAsset = new Map();
const EMOTIONS = new Set([
  "happy", "sad", "angry", "fearful", "disgusted", "surprised", "calm", "fluent", "whisper"
]);

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

function wait(milliseconds) {
  Atomics.wait(new Int32Array(new SharedArrayBuffer(4)), 0, 0, milliseconds);
}

function runMmx(args, label) {
  let lastError;
  for (let attempt = 1; attempt <= 4; attempt += 1) {
    try {
      run(findMmx(), [...args, "--timeout", "180", "--non-interactive", "--quiet"], label);
      wait(REQUEST_GAP_MS);
      return;
    } catch (error) {
      lastError = error;
      const message = error instanceof Error ? error.message : String(error);
      const retryable = /timed out|timeout|network request failed|econnreset|enotfound|socket hang up|fetch failed|rate limit exceeded|too many requests|\b429\b/i.test(message);
      if (!retryable || attempt === 4) throw error;
      process.stderr.write(`${label} attempt ${attempt} did not complete; retrying.\n`);
      wait(attempt * 12000);
    }
  }
  throw lastError;
}

function outputPath(definition) {
  return join(audioRoot, definition.path);
}

function replaceValidatedFile(source, destination) {
  mkdirSync(dirname(destination), { recursive: true });
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

function probeAudio(path, kind, expectedDurationMs = null) {
  if (!existsSync(path)) throw new Error(`Missing pursuit ${kind} asset: ${path}`);
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
  const expectedSampleRate = kind === "music" ? 44100 : 32000;
  const expectedChannels = kind === "music" ? 2 : 1;
  if (!stream || stream.codec_name !== "mp3") throw new Error(`Pursuit asset must be mp3: ${path}`);
  if (!Number.isFinite(durationMs) || durationMs < 250 || durationMs > 60000) {
    throw new Error(`Unexpected pursuit ${kind} duration ${durationMs}ms: ${path}`);
  }
  if (expectedDurationMs !== null && Math.abs(durationMs - expectedDurationMs) > DURATION_TOLERANCE_MS) {
    throw new Error(`Unexpected pursuit music duration ${durationMs}ms: ${path}; expected ${expectedDurationMs}ms`);
  }
  if (Number(stream.sample_rate) !== expectedSampleRate || Number(stream.channels) !== expectedChannels) {
    throw new Error(
      `Pursuit ${kind} must be ${expectedSampleRate}Hz ${expectedChannels === 2 ? "stereo" : "mono"}: ${path}`
    );
  }
  run("ffmpeg", ["-v", "error", "-i", path, "-f", "null", "-"], `Decode ${path}`);
  return {
    durationMs,
    codec: stream.codec_name,
    sampleRate: Number(stream.sample_rate),
    channels: Number(stream.channels)
  };
}

function validateContent() {
  if (
    content.version !== 1
    || content.chapterId !== "cross-chapter-pursuit-audio"
    || content.models?.music !== MUSIC_MODEL
    || content.models?.speech !== SPEECH_MODEL
    || !Array.isArray(content.music)
    || content.music.length !== 1
    || !Array.isArray(content.lines)
    || content.lines.length !== 6
  ) {
    throw new Error("Invalid pursuit audio content catalog.");
  }
  const assets = new Set();
  const paths = new Set();
  for (const definition of [...content.music, ...content.lines]) {
    if (
      typeof definition.asset !== "string"
      || typeof definition.path !== "string"
      || assets.has(definition.asset)
      || paths.has(definition.path)
    ) {
      throw new Error(`Invalid or duplicate pursuit asset definition: ${JSON.stringify(definition)}`);
    }
    assets.add(definition.asset);
    paths.add(definition.path);
  }
  const music = content.music[0];
  if (
    music.asset !== "music_qizhen_swan_chase"
    || music.path !== `pursuit/music/${music.asset}.mp3`
    || !Number.isInteger(music.durationSeconds)
    || music.durationSeconds < 20
    || music.durationSeconds > 40
    || !Number.isInteger(music.bpm)
    || music.bpm < 90
    || music.bpm > 140
  ) {
    throw new Error("Invalid black-swan chase music definition.");
  }
  for (const line of content.lines) {
    const voice = content.voices?.[line.voiceRole];
    if (
      !/^vo_pursuit_(qizhen_swan|chapter4_guard)_[a-z]+$/.test(line.asset)
      || line.path !== `pursuit/voice/${line.asset}.mp3`
      || typeof line.voiceTextEn !== "string"
      || typeof line.subtitleZh !== "string"
      || typeof line.deliveryPromptZh !== "string"
      || line.deliveryPromptZh.trim().length < 12
      || !Number.isInteger(line.maxDurationMs)
      || line.maxDurationMs < 1600
      || line.maxDurationMs > 4200
      || typeof voice?.id !== "string"
      || voice.language !== "English"
      || line.pitch !== voice.basePitch
      || (line.emotion !== undefined && !EMOTIONS.has(line.emotion))
    ) {
      throw new Error(`Invalid pursuit voice line: ${JSON.stringify(line)}`);
    }
  }
}

function musicSourceConfig(definition) {
  return {
    model: MUSIC_MODEL,
    definition
  };
}

function voiceSourceConfig(line) {
  const voice = content.voices[line.voiceRole];
  return {
    model: SPEECH_MODEL,
    voiceId: voice.id,
    language: voice.language,
    speed: line.speed,
    pitch: line.pitch,
    emotion: line.emotion ?? null,
    voiceTextEn: line.voiceTextEn,
    sampleRate: 32000,
    channels: 1
  };
}

function generateMusic(definition, output) {
  const raw = join(tempDir, `${definition.asset}.raw.mp3`);
  const normalized = join(tempDir, `${definition.asset}.normalized.mp3`);
  try {
    runMmx([
      "music", "generate",
      "--model", MUSIC_MODEL,
      "--prompt", definition.prompt,
      "--genre", definition.genre,
      "--mood", definition.mood,
      "--instruments", definition.instruments,
      "--bpm", String(definition.bpm),
      "--avoid", definition.avoid,
      "--use-case", definition.useCase,
      "--structure", definition.structure,
      "--instrumental",
      "--format", "mp3",
      "--sample-rate", "44100",
      "--bitrate", "256000",
      "--out", raw
    ], `MiniMax pursuit music ${definition.cue}`);
    generatedSourceByAsset.set(definition.asset, `MiniMax ${MUSIC_MODEL}`);
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    if (!/Music API is no longer available|HTTP 410/i.test(message)) throw error;
    process.stderr.write(
      "MiniMax Music returned HTTP 410; using the deterministic local pursuit-bed fallback.\n"
    );
    run("ffmpeg", [
      "-y", "-hide_banner", "-loglevel", "error",
      "-f", "lavfi", "-i", `sine=frequency=55:duration=${definition.durationSeconds}:sample_rate=44100`,
      "-f", "lavfi", "-i", `sine=frequency=110:duration=${definition.durationSeconds}:sample_rate=44100`,
      "-f", "lavfi", "-i", `anoisesrc=color=pink:duration=${definition.durationSeconds}:sample_rate=44100`,
      "-f", "lavfi", "-i", `sine=frequency=220:duration=${definition.durationSeconds}:sample_rate=44100`,
      "-filter_complex",
      "[0:a]volume=0.12,tremolo=f=1.966:d=0.42[bass];"
        + "[1:a]volume=0.055,tremolo=f=3.933:d=0.72[pulse];"
        + "[2:a]highpass=f=1250,lowpass=f=5900,volume='if(lt(mod(t,0.508),0.085),0.16,0.008)':eval=frame[water];"
        + "[3:a]volume=0.028,tremolo=f=0.491:d=0.78,vibrato=f=4.1:d=0.08[warning];"
        + "[bass][pulse][water][warning]amix=inputs=4:duration=longest:normalize=0,"
        + "acompressor=threshold=-20dB:ratio=2.4:attack=8:release=120:makeup=2,"
        + "aecho=0.7:0.32:62|124:0.16|0.08[out]",
      "-map", "[out]",
      "-ar", "44100", "-ac", "2", "-b:a", "192k", raw
    ], `Synthesize local pursuit music ${definition.cue}`);
    generatedSourceByAsset.set(
      definition.asset,
      "Deterministic ffmpeg pursuit bed after MiniMax Music HTTP 410"
    );
  }
  const fadeOutStart = Math.max(0, definition.durationSeconds - 0.8);
  run("ffmpeg", [
    "-y", "-hide_banner", "-loglevel", "error", "-stream_loop", "-1", "-i", raw,
    "-t", String(definition.durationSeconds),
    "-af",
    `loudnorm=I=-24:TP=-1.5:LRA=8,apad=pad_dur=${definition.durationSeconds},atrim=duration=${definition.durationSeconds},afade=t=in:st=0:d=0.45,afade=t=out:st=${fadeOutStart}:d=0.8`,
    "-ar", "44100", "-ac", "2", "-b:a", "192k", normalized
  ], `Normalize pursuit music ${definition.cue}`);
  probeAudio(normalized, "music", definition.durationSeconds * 1000);
  replaceValidatedFile(normalized, output);
}

function generateVoice(line, output) {
  const voice = content.voices[line.voiceRole];
  const raw = join(tempDir, `${line.key}.raw.mp3`);
  const normalized = join(tempDir, `${line.key}.normalized.mp3`);
  const emotionArgs = line.emotion ? ["--emotion", line.emotion] : [];
  runMmx([
    "speech", "synthesize",
    "--model", SPEECH_MODEL,
    "--voice", voice.id,
    "--language", voice.language,
    "--speed", String(line.speed),
    "--volume", "1",
    "--pitch", String(line.pitch),
    "--sample-rate", "32000",
    "--bitrate", "128000",
    "--channels", "1",
    ...emotionArgs,
    "--text", line.voiceTextEn,
    "--out", raw
  ], `MiniMax pursuit voice ${line.key}`);
  run("ffmpeg", [
    "-y", "-hide_banner", "-loglevel", "error", "-i", raw,
    "-af",
    "silenceremove=start_periods=1:start_duration=0.04:start_threshold=-48dB,areverse,silenceremove=start_periods=1:start_duration=0.08:start_threshold=-48dB,areverse,acompressor=threshold=-18dB:ratio=2.2:attack=5:release=100:makeup=2,loudnorm=I=-16:TP=-1.5:LRA=7",
    "-ar", "32000", "-ac", "1", "-b:a", "128k", normalized
  ], `Normalize pursuit voice ${line.key}`);
  const metadata = probeAudio(normalized, "voice");
  if (metadata.durationMs > line.maxDurationMs) {
    throw new Error(`Pursuit voice ${line.key} exceeds budget: ${metadata.durationMs}ms > ${line.maxDurationMs}ms`);
  }
  replaceValidatedFile(normalized, output);
  generatedSourceByAsset.set(line.asset, `MiniMax ${SPEECH_MODEL} ${voice.id}`);
}

function writeCheckpoint(assets) {
  writeJsonAtomic(checkpointPath, {
    version: 1,
    updatedAt: new Date().toISOString(),
    assets
  });
}

function canonicalManifestMatches(assets) {
  return Object.entries(assets).every(([asset, metadata]) => {
    const canonical = previousManifest.assets?.[asset];
    return canonical?.sha256 === metadata.sha256
      && canonical?.sourceConfigHash === metadata.sourceConfigHash;
  }) && Object.keys(assets).length === content.music.length + content.lines.length;
}

function main() {
  validateContent();
  const definitions = [
    ...content.music.map((definition) => ({ kind: "music", definition })),
    ...content.lines.map((definition) => ({ kind: "voice", definition }))
  ];
  const assets = {};
  const generated = [];
  const seenHashes = new Map();

  for (const { kind, definition } of definitions) {
    const output = outputPath(definition);
    const config = kind === "music" ? musicSourceConfig(definition) : voiceSourceConfig(definition);
    const sourceConfigHash = hash(JSON.stringify(config));
    const cached = previousAssets[definition.asset];
    const reusable = !force
      && existsSync(output)
      && cached?.sourceConfigHash === sourceConfigHash
      && cached?.sha256 === hash(readFileSync(output));
    if (!reusable) continue;
    const expectedDuration = kind === "music" ? definition.durationSeconds * 1000 : null;
    const metadata = probeAudio(output, kind, expectedDuration);
    if (kind === "voice" && metadata.durationMs > definition.maxDurationMs) {
      throw new Error(`Pursuit voice ${definition.key} exceeds budget.`);
    }
    const sha256 = hash(readFileSync(output));
    if (seenHashes.has(sha256)) continue;
    seenHashes.set(sha256, definition.asset);
    assets[definition.asset] = {
      path: relative(audioRoot, output).replaceAll("\\", "/"),
      kind,
      ...metadata,
      sha256,
      sourceConfigHash,
      ...(kind === "voice" ? { sourceTextHash: hash(definition.voiceTextEn) } : {}),
      source: cached?.source ?? `MiniMax ${kind === "music" ? MUSIC_MODEL : SPEECH_MODEL}`
    };
  }

  for (const { kind, definition } of definitions) {
    if (assets[definition.asset]) continue;
    if (verifyOnly) throw new Error(`Pursuit audio requires regeneration: ${definition.asset}`);
    const output = outputPath(definition);
    if (kind === "music") generateMusic(definition, output);
    else generateVoice(definition, output);
    const expectedDuration = kind === "music" ? definition.durationSeconds * 1000 : null;
    const metadata = probeAudio(output, kind, expectedDuration);
    const sha256 = hash(readFileSync(output));
    const duplicate = seenHashes.get(sha256);
    if (duplicate) throw new Error(`Duplicate pursuit audio bytes for ${definition.asset} and ${duplicate}`);
    seenHashes.set(sha256, definition.asset);
    const config = kind === "music" ? musicSourceConfig(definition) : voiceSourceConfig(definition);
    assets[definition.asset] = {
      path: relative(audioRoot, output).replaceAll("\\", "/"),
      kind,
      ...metadata,
      sha256,
      sourceConfigHash: hash(JSON.stringify(config)),
      ...(kind === "voice" ? { sourceTextHash: hash(definition.voiceTextEn) } : {}),
      source: generatedSourceByAsset.get(definition.asset)
        ?? `MiniMax ${kind === "music" ? MUSIC_MODEL : SPEECH_MODEL}`
    };
    generated.push(definition.asset);
    writeCheckpoint(assets);
  }

  if (Object.keys(assets).length !== definitions.length) {
    throw new Error(`Pursuit audio manifest is incomplete: ${Object.keys(assets).length}/${definitions.length}`);
  }
  if (!verifyOnly && (generated.length > 0 || !canonicalManifestMatches(assets))) {
    writeJsonAtomic(generatedPath, {
      version: 1,
      chapterId: content.chapterId,
      generatedAt: new Date().toISOString(),
      assets
    });
  }
  if (!verifyOnly) rmSync(checkpointPath, { force: true });
  process.stdout.write(`${JSON.stringify({ generated, verified: Object.keys(assets), manifest: generatedPath }, null, 2)}\n`);
}

try {
  main();
} finally {
  rmSync(tempDir, { recursive: true, force: true });
}
