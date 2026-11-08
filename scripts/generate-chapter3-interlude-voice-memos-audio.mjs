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
import { tmpdir } from "node:os";
import { dirname, join, relative, resolve, sep } from "node:path";
import { fileURLToPath } from "node:url";
import { spawnSync } from "node:child_process";

const root = resolve(dirname(fileURLToPath(import.meta.url)), "..");
const contentPath = join(root, "src/data/chapter3-interlude-voice-memos.audio.content.json");
const generatedPath = join(root, "src/data/chapter3-interlude-voice-memos.audio.generated.json");
const checkpointPath = join(
  root,
  "node_modules/.cache/seven-fifty-five/chapter3-interlude-voice-memos.audio.checkpoint.json"
);
const audioRoot = join(root, "src/assets/audio");
const outputDir = join(audioRoot, "chapter3-interlude/voice-memos");
const componentDir = join(outputDir, "components");
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
const tempDir = mkdtempSync(join(tmpdir(), "seven-fifty-five-chapter35-voice-memos-"));

const MODEL = "mlx-community/fish-audio-drama-3-4bit";
const MIX_PROFILE = "phone_memo_field_recording_v1";
const MIX_FILTER_VERSION = 1;
const TARGET_SAMPLE_RATE = 32000;
const TARGET_CHANNELS = 1;
const TARGET_BITRATE = 128000;
const EXPECTED_SPEECH_COUNT = 6;
const EXPECTED_RECORDING_COUNT = 7;
const EXPECTED_CORRECT_COUNT = 4;
const EXPECTED_DECOY_COUNT = 3;
const TARGET_RECORDING_DURATION_MS = 5200;
const RECORDING_DURATION_TOLERANCE_MS = 90;
const WAVEFORM_BIN_COUNT = 32;
const WAVEFORM_SAMPLE_RATE = 8000;
const ID_PATTERN = /^[a-z0-9]+(?:_[a-z0-9]+)*$/;
const ASSET_PATTERN = /^(?:vo|voice_memo)_ch35_[a-z0-9]+(?:_[a-z0-9]+)*$/;
const SHA256_PATTERN = /^[a-f0-9]{64}$/;
const VALID_EVENT_DISTANCES = new Set(["near", "mid", "far"]);
const VALID_SPEECH_DENSITIES = new Set(["none", "sparse", "moderate", "dense"]);
const FORBIDDEN_EVENT_LABEL_PATTERN = /正确|错误|干扰|顺序|答案|目的地|段永平|北教|A1/i;

function hash(value) {
  return createHash("sha256").update(value).digest("hex");
}

function fileHash(path) {
  return hash(readFileSync(path));
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
      .slice(0, 2200);
    throw new Error(`${label} failed: ${detail}`);
  }
  return result.stdout;
}

function runBuffer(command, args, label) {
  const result = spawnSync(command, args, {
    cwd: root,
    encoding: null,
    maxBuffer: 32 * 1024 * 1024
  });
  if (result.status !== 0) {
    const stderr = Buffer.isBuffer(result.stderr) ? result.stderr.toString("utf8") : result.stderr;
    const stdout = Buffer.isBuffer(result.stdout) ? result.stdout.toString("utf8") : result.stdout;
    const detail = (stderr || stdout || result.error?.message || "unknown error")
      .trim()
      .slice(0, 2200);
    throw new Error(`${label} failed: ${detail}`);
  }
  return result.stdout;
}

function analyzeRecording(path, label = path) {
  const pcm = runBuffer("ffmpeg", [
    "-v", "error",
    "-i", path,
    "-map", "0:a:0",
    "-ac", "1",
    "-ar", String(WAVEFORM_SAMPLE_RATE),
    "-codec:a", "pcm_s16le",
    "-f", "s16le",
    "-"
  ], `Extract waveform ${label}`);
  const sampleCount = Math.floor(pcm.length / 2);
  if (sampleCount < WAVEFORM_BIN_COUNT) {
    throw new Error(`${label} has too few decoded samples for a ${WAVEFORM_BIN_COUNT}-bin waveform.`);
  }
  const rmsBins = [];
  for (let binIndex = 0; binIndex < WAVEFORM_BIN_COUNT; binIndex += 1) {
    const startSample = Math.floor((binIndex * sampleCount) / WAVEFORM_BIN_COUNT);
    const endSample = Math.floor(((binIndex + 1) * sampleCount) / WAVEFORM_BIN_COUNT);
    let sumSquares = 0;
    for (let sampleIndex = startSample; sampleIndex < endSample; sampleIndex += 1) {
      const sample = pcm.readInt16LE(sampleIndex * 2) / 32768;
      sumSquares += sample * sample;
    }
    rmsBins.push(Math.sqrt(sumSquares / Math.max(1, endSample - startSample)));
  }
  const peakRms = Math.max(...rmsBins);
  if (!Number.isFinite(peakRms) || peakRms <= 0) {
    throw new Error(`${label} produced a silent or invalid waveform.`);
  }
  return {
    durationMs: Math.round(sampleCount * 1000 / WAVEFORM_SAMPLE_RATE),
    waveformBins: rmsBins.map((rms) => Number((rms / peakRms).toFixed(3)))
  };
}

function probeAudio(path, label = path) {
  if (!existsSync(path)) throw new Error(`Missing audio asset: ${path}`);
  const raw = run("ffprobe", [
    "-v", "error",
    "-select_streams", "a:0",
    "-show_entries", "stream=codec_name,codec_type,sample_rate,channels,bit_rate:format=duration,bit_rate",
    "-of", "json",
    path
  ], `Probe ${label}`);
  const parsed = JSON.parse(raw);
  const stream = parsed.streams?.find(({ codec_type: codecType }) => codecType === "audio");
  if (!stream) throw new Error(`No decodable audio stream in ${label}`);
  const durationMs = Math.round(Number(parsed.format?.duration) * 1000);
  const sampleRate = Number(stream.sample_rate);
  const channels = Number(stream.channels);
  const bitrate = Number(stream.bit_rate ?? parsed.format?.bit_rate);
  if (!Number.isFinite(durationMs) || durationMs <= 0 || durationMs > 120000) {
    throw new Error(`Unexpected audio duration ${durationMs}ms in ${label}`);
  }
  if (!Number.isFinite(sampleRate) || !Number.isInteger(channels) || channels <= 0) {
    throw new Error(`Invalid audio stream metadata in ${label}`);
  }
  run("ffmpeg", ["-v", "error", "-i", path, "-f", "null", "-"], `Decode ${label}`);
  return {
    durationMs,
    codec: stream.codec_name,
    sampleRate,
    channels,
    ...(Number.isFinite(bitrate) ? { bitrate } : {})
  };
}

function probeGeneratedAudio(path, { label, maxDurationMs, targetDurationMs } = {}) {
  const metadata = probeAudio(path, label);
  if (metadata.codec !== "mp3") {
    throw new Error(`${label ?? path} must use the mp3 codec.`);
  }
  if (metadata.sampleRate !== TARGET_SAMPLE_RATE || metadata.channels !== TARGET_CHANNELS) {
    throw new Error(`${label ?? path} must be ${TARGET_SAMPLE_RATE}Hz mono.`);
  }
  if (
    Number.isFinite(metadata.bitrate)
    && Math.abs(metadata.bitrate - TARGET_BITRATE) > 2000
  ) {
    throw new Error(`${label ?? path} must use a 128kbps MP3 stream.`);
  }
  if (Number.isFinite(maxDurationMs) && metadata.durationMs > maxDurationMs) {
    throw new Error(
      `${label ?? path} exceeds its duration budget: ${metadata.durationMs}ms > ${maxDurationMs}ms`
    );
  }
  if (
    Number.isFinite(targetDurationMs)
    && Math.abs(metadata.durationMs - targetDurationMs) > RECORDING_DURATION_TOLERANCE_MS
  ) {
    throw new Error(
      `${label ?? path} must be approximately ${targetDurationMs}ms; got ${metadata.durationMs}ms.`
    );
  }
  return metadata;
}

function ensureInsideAudioRoot(path, label) {
  const resolvedPath = resolve(path);
  const rootPrefix = `${resolve(audioRoot)}${sep}`;
  if (!resolvedPath.startsWith(rootPrefix)) {
    throw new Error(`${label} resolves outside src/assets/audio: ${path}`);
  }
  return resolvedPath;
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

function writeCheckpoint(assets) {
  writeJsonAtomic(checkpointPath, {
    version: 1,
    updatedAt: new Date().toISOString(),
    assets
  });
}

function validateContent() {
  if (
    content.version !== 1
    || content.chapterId !== "chapter-3-interlude-voice-memos"
    || content.model !== MODEL
    || !/^[a-f0-9]{40}$/.test(content.modelRevision)
    || content.mixProfile !== MIX_PROFILE
    || !content.voices
    || !Array.isArray(content.speech)
    || content.speech.length !== EXPECTED_SPEECH_COUNT
    || !Array.isArray(content.recordings)
    || content.recordings.length !== EXPECTED_RECORDING_COUNT
  ) {
    throw new Error("Invalid Chapter 3.5 voice-memo audio catalog header or item count.");
  }

  const speechIds = new Set();
  const speechAssets = new Set();
  const speechTexts = new Set();
  for (const speech of content.speech) {
    const voice = content.voices[speech.voiceRole];
    const take = speech.localTake;
    if (
      typeof speech.id !== "string"
      || !ID_PATTERN.test(speech.id)
      || typeof speech.asset !== "string"
      || !ASSET_PATTERN.test(speech.asset)
      || typeof speech.clipId !== "string"
      || !ID_PATTERN.test(speech.clipId)
      || !voice
      || typeof voice.id !== "string"
      || voice.language !== "English"
      || !ID_PATTERN.test(voice.referenceAsset)
      || !SHA256_PATTERN.test(voice.referenceSha256)
      || typeof speech.deliveryPromptZh !== "string"
      || speech.deliveryPromptZh.trim().length < 12
      || typeof speech.subtitleZh !== "string"
      || speech.subtitleZh.trim().length < 4
      || typeof speech.voiceTextEn !== "string"
      || speech.voiceTextEn.trim().length < 8
      || !take
      || !SHA256_PATTERN.test(take.sha256)
      || take.sourceTextHash !== hash(speech.voiceTextEn)
      || !Number.isSafeInteger(take.seed)
      || !Number.isFinite(take.temperature)
      || !(take.temperature > 0 && take.temperature <= 2)
      || !Number.isFinite(take.topP)
      || !(take.topP > 0 && take.topP <= 1)
      || (take.topK !== null && (!Number.isSafeInteger(take.topK) || take.topK < 1))
      || !Number.isInteger(speech.maxDurationMs)
      || speech.maxDurationMs < 500
      || speech.maxDurationMs > TARGET_RECORDING_DURATION_MS
    ) {
      throw new Error(`Invalid Chapter 3.5 dry-speech definition: ${JSON.stringify(speech)}`);
    }
    if (speechIds.has(speech.id)) throw new Error(`Duplicate dry-speech id: ${speech.id}`);
    if (speechAssets.has(speech.asset)) throw new Error(`Duplicate dry-speech asset: ${speech.asset}`);
    if (speechTexts.has(speech.voiceTextEn)) throw new Error(`Duplicate dry-speech text: ${speech.voiceTextEn}`);
    speechIds.add(speech.id);
    speechAssets.add(speech.asset);
    speechTexts.add(speech.voiceTextEn);
  }

  const recordingIds = new Set();
  const recordingAssets = new Set();
  const recordingCodes = new Set();
  let correctCount = 0;
  let decoyCount = 0;
  for (const recording of content.recordings) {
    const productionPrompt = recording.productionPrompt;
    if (
      typeof recording.id !== "string"
      || !ID_PATTERN.test(recording.id)
      || typeof recording.asset !== "string"
      || !ASSET_PATTERN.test(recording.asset)
      || typeof recording.code !== "string"
      || recording.code.trim().length < 4
      || typeof recording.correct !== "boolean"
      || typeof recording.time !== "string"
      || typeof recording.revealZh !== "string"
      || recording.revealZh.trim().length < 8
      || recording.targetDurationMs !== TARGET_RECORDING_DURATION_MS
      || !productionPrompt
      || typeof productionPrompt.eventEmphasisZh !== "string"
      || productionPrompt.eventEmphasisZh.trim().length < 12
      || typeof productionPrompt.distanceZh !== "string"
      || productionPrompt.distanceZh.trim().length < 12
      || !VALID_SPEECH_DENSITIES.has(productionPrompt.speechDensity)
      || typeof productionPrompt.decoyOverlapZh !== "string"
      || productionPrompt.decoyOverlapZh.trim().length < 12
      || !Array.isArray(recording.soundEvents)
      || recording.soundEvents.length < 2
      || recording.soundEvents.length > 4
      || !Array.isArray(recording.layers)
      || recording.layers.length < 2
    ) {
      throw new Error(`Invalid Chapter 3.5 recording definition: ${JSON.stringify(recording)}`);
    }
    if (recordingIds.has(recording.id)) throw new Error(`Duplicate recording id: ${recording.id}`);
    if (recordingAssets.has(recording.asset)) throw new Error(`Duplicate recording asset: ${recording.asset}`);
    if (recordingCodes.has(recording.code)) throw new Error(`Duplicate recording code: ${recording.code}`);
    recordingIds.add(recording.id);
    recordingAssets.add(recording.asset);
    recordingCodes.add(recording.code);
    if (recording.correct) correctCount += 1;
    else decoyCount += 1;

    let previousEventStartMs = -1;
    for (const event of recording.soundEvents) {
      if (
        !Number.isInteger(event.startMs)
        || !Number.isInteger(event.endMs)
        || event.startMs < 0
        || event.endMs <= event.startMs
        || event.endMs > recording.targetDurationMs
        || event.startMs < previousEventStartMs
        || typeof event.category !== "string"
        || !ID_PATTERN.test(event.category)
        || typeof event.labelZh !== "string"
        || event.labelZh.trim().length < 2
        || event.labelZh.trim().length > 18
        || FORBIDDEN_EVENT_LABEL_PATTERN.test(event.labelZh)
        || !VALID_EVENT_DISTANCES.has(event.distance)
      ) {
        throw new Error(`Invalid sound event in ${recording.id}: ${JSON.stringify(event)}`);
      }
      previousEventStartMs = event.startMs;
    }

    for (const layer of recording.layers) {
      if (
        !["file", "speech"].includes(layer.kind)
        || !Number.isInteger(layer.startMs)
        || layer.startMs < 0
        || layer.startMs >= recording.targetDurationMs
        || !Number.isFinite(layer.volume)
        || layer.volume <= 0
        || layer.volume > 2
      ) {
        throw new Error(`Invalid layer in ${recording.id}: ${JSON.stringify(layer)}`);
      }
      if (layer.kind === "speech" && !speechAssets.has(layer.asset)) {
        throw new Error(`Unknown speech asset ${layer.asset} in ${recording.id}`);
      }
      if (layer.kind === "file") {
        if (
          typeof layer.path !== "string"
          || layer.path.length === 0
          || layer.path.startsWith("/")
          || layer.path.split(/[\\/]/).includes("..")
        ) {
          throw new Error(`Invalid local audio path in ${recording.id}: ${layer.path}`);
        }
        const input = ensureInsideAudioRoot(join(audioRoot, layer.path), `${recording.id} layer`);
        if (!existsSync(input)) throw new Error(`Missing source layer for ${recording.id}: ${layer.path}`);
      }
    }
  }
  if (correctCount !== EXPECTED_CORRECT_COUNT || decoyCount !== EXPECTED_DECOY_COUNT) {
    throw new Error(
      `Chapter 3.5 recordings require ${EXPECTED_CORRECT_COUNT} correct and ${EXPECTED_DECOY_COUNT} decoy clips.`
    );
  }
  for (const speech of content.speech) {
    const recording = content.recordings.find(({ id }) => id === speech.clipId);
    if (!recording?.layers.some((layer) => layer.kind === "speech" && layer.asset === speech.asset)) {
      throw new Error(`Dry speech ${speech.asset} is missing from recording ${speech.clipId}.`);
    }
  }
}

function relativeAudioPath(path) {
  return relative(audioRoot, path).replaceAll("\\", "/");
}

function makeSpeechManifestEntry(speech, output) {
  if (!existsSync(output) || fileHash(output) !== speech.localTake.sha256) {
    throw new Error(`Missing or changed local Drama 3 take: ${speech.asset}`);
  }
  const sourceConfigHash = hash(JSON.stringify({
    model: MODEL,
    modelRevision: content.modelRevision,
    voice: content.voices[speech.voiceRole],
    localTake: speech.localTake
  }));
  const metadata = probeGeneratedAudio(output, {
    label: speech.asset,
    maxDurationMs: speech.maxDurationMs
  });
  return {
    kind: "speech",
    path: relativeAudioPath(output),
    ...metadata,
    sha256: speech.localTake.sha256,
    sourceTextHash: speech.localTake.sourceTextHash,
    sourceConfigHash,
    source: "Built with Fish Audio · local Drama 3 MLX 4-bit"
  };
}

function cachedEntryIsReusable({ asset, output, sourceConfigHash, probe }) {
  const cached = previousAssets[asset];
  if (
    force
    || !cached
    || !existsSync(output)
    || cached.sourceConfigHash !== sourceConfigHash
    || cached.sha256 !== fileHash(output)
  ) {
    return false;
  }
  try {
    probe(output);
    return true;
  } catch (error) {
    if (verifyOnly) throw error;
    return false;
  }
}

function resolveRecordingLayers(recording, speechAssets, inputProbeCache) {
  const componentAssetHashes = {};
  const layers = recording.layers.map((layer, index) => {
    const key = layer.kind === "speech" ? layer.asset : layer.path;
    const input = layer.kind === "speech"
      ? join(audioRoot, speechAssets[layer.asset].path)
      : ensureInsideAudioRoot(join(audioRoot, layer.path), `${recording.id} layer`);
    if (!existsSync(input)) throw new Error(`Missing source layer for ${recording.id}: ${key}`);
    if (layer.kind === "speech") {
      const voiceEvent = recording.soundEvents.find(({ category }) => category === "voice");
      const speechEndMs = layer.startMs + speechAssets[layer.asset].durationMs;
      const powerCut = recording.soundEvents.find(({ category }) => category === "power");
      if (!voiceEvent || voiceEvent.startMs !== layer.startMs
        || speechEndMs > voiceEvent.endMs + 36
        || speechEndMs > (powerCut?.startMs ?? recording.targetDurationMs)) {
        throw new Error(`Local take ${key} does not fit its voice event in ${recording.id}.`);
      }
    }
    if (!inputProbeCache.has(input)) inputProbeCache.set(input, probeAudio(input, key));
    const sha256 = fileHash(input);
    componentAssetHashes[key] = sha256;
    return {
      index,
      key,
      input,
      sha256,
      startMs: layer.startMs,
      volume: layer.volume
    };
  });
  return { layers, componentAssetHashes };
}

function recordingSourceConfig(recording, layers) {
  return {
    kind: "ffmpeg-field-recording-mix",
    mixProfile: MIX_PROFILE,
    mixFilterVersion: MIX_FILTER_VERSION,
    targetDurationMs: recording.targetDurationMs,
    sampleRate: TARGET_SAMPLE_RATE,
    bitrate: TARGET_BITRATE,
    channels: TARGET_CHANNELS,
    recording: {
      id: recording.id,
      asset: recording.asset,
      code: recording.code,
      correct: recording.correct,
      time: recording.time,
      layers: layers.map(({ key, sha256, startMs, volume }) => ({
        key,
        sha256,
        startMs,
        volume
      }))
    },
    processing: {
      highpassHz: 140,
      lowpassHz: 6500,
      compressorThreshold: 0.12,
      compressorRatio: 2.5,
      integratedLoudness: -19,
      truePeakDb: -2,
      loudnessRange: 8
    }
  };
}

function mixRecording(recording, layers, output) {
  const staged = join(tempDir, `${recording.asset}.mixed.mp3`);
  const inputArgs = layers.flatMap(({ input }) => ["-i", input]);
  const layerFilters = layers.map(({ index, startMs, volume }) => (
    `[${index}:a]aresample=${TARGET_SAMPLE_RATE},`
    + "aformat=sample_fmts=fltp:channel_layouts=mono,"
    + `volume=${volume},adelay=${startMs}:all=1,`
    + `apad=pad_dur=${recording.targetDurationMs / 1000}[layer${index}]`
  ));
  const mixInputs = layers.map(({ index }) => `[layer${index}]`).join("");
  const finalFilter = `${mixInputs}amix=inputs=${layers.length}:duration=longest:dropout_transition=0:normalize=0,`
    + "highpass=f=140,lowpass=f=6500,"
    + "acompressor=threshold=0.12:ratio=2.5:attack=5:release=150:makeup=1.5,"
    + "loudnorm=I=-19:TP=-2:LRA=8,"
    + `apad=pad_dur=${recording.targetDurationMs / 1000},`
    + `atrim=duration=${recording.targetDurationMs / 1000},asetpts=N/SR/TB[out]`;
  run("ffmpeg", [
    "-y",
    "-hide_banner",
    "-loglevel", "error",
    ...inputArgs,
    "-filter_complex", [...layerFilters, finalFilter].join(";"),
    "-map", "[out]",
    "-map_metadata", "-1",
    "-id3v2_version", "0",
    "-codec:a", "libmp3lame",
    "-ar", String(TARGET_SAMPLE_RATE),
    "-ac", String(TARGET_CHANNELS),
    "-b:a", "128k",
    staged
  ], `Mix ${recording.asset}`);
  probeGeneratedAudio(staged, {
    label: recording.asset,
    targetDurationMs: recording.targetDurationMs
  });
  replaceValidatedFile(staged, output);
}

function makeRecordingManifestEntry(recording, output, sourceConfigHash, componentAssetHashes) {
  const metadata = probeGeneratedAudio(output, {
    label: recording.asset,
    targetDurationMs: recording.targetDurationMs
  });
  const analysis = analyzeRecording(output, recording.asset);
  // MP3 container duration includes encoder delay and padding on some ffprobe builds.
  if (analysis.durationMs !== recording.targetDurationMs) {
    throw new Error(`${recording.asset} decodes to ${analysis.durationMs}ms, expected ${recording.targetDurationMs}ms.`);
  }
  return {
    kind: recording.correct ? "correct" : "decoy",
    path: relativeAudioPath(output),
    ...metadata,
    sha256: fileHash(output),
    sourceConfigHash,
    source: `FFmpeg ${MIX_PROFILE} mix`,
    ...analysis,
    soundEvents: recording.soundEvents.map((event) => ({ ...event })),
    componentAssetHashes
  };
}

function stableJson(value) {
  if (Array.isArray(value)) {
    return `[${value.map((entry) => stableJson(entry)).join(",")}]`;
  }
  if (value && typeof value === "object") {
    const entries = Object.entries(value)
      .sort(([left], [right]) => left.localeCompare(right))
      .map(([key, entry]) => `${JSON.stringify(key)}:${stableJson(entry)}`);
    return `{${entries.join(",")}}`;
  }
  return JSON.stringify(value);
}

function reportManifestMismatch(reason) {
  process.stderr.write(`Chapter 3.5 manifest mismatch: ${reason}\n`);
  return false;
}

function manifestAssetsMatch(actualAssets) {
  const manifestAssets = previousManifest.assets ?? {};
  const manifestNames = Object.keys(manifestAssets).sort();
  const actualNames = Object.keys(actualAssets).sort();
  if (stableJson(manifestNames) !== stableJson(actualNames)) {
    return reportManifestMismatch("asset names differ");
  }

  for (const asset of actualNames) {
    const manifestEntry = manifestAssets[asset];
    const actualEntry = actualAssets[asset];
    if (!manifestEntry || !actualEntry) {
      return reportManifestMismatch(`${asset} is missing`);
    }

    if (
      Number.isFinite(manifestEntry.bitrate)
      && Number.isFinite(actualEntry.bitrate)
      && Math.abs(manifestEntry.bitrate - actualEntry.bitrate) > 2000
    ) {
      return reportManifestMismatch(`${asset} bitrate differs by more than 2kbps`);
    }

    const manifestWaveform = manifestEntry.waveformBins;
    const actualWaveform = actualEntry.waveformBins;
    if (Boolean(manifestWaveform) !== Boolean(actualWaveform)) {
      return reportManifestMismatch(`${asset} waveform presence differs`);
    }
    if (manifestWaveform) {
      if (manifestEntry.durationMs !== actualEntry.durationMs) {
        return reportManifestMismatch(`${asset} decoded duration differs`);
      }
      if (manifestWaveform.length !== actualWaveform.length) {
        return reportManifestMismatch(`${asset} waveform bin count differs`);
      }
      if (manifestWaveform.some((value, index) => (
        Math.abs(value - actualWaveform[index]) > 0.01
      ))) {
        return reportManifestMismatch(`${asset} waveform differs by more than 0.01`);
      }
    }

    const omitPlatformProbeValues = ({
      durationMs: _durationMs,
      bitrate: _bitrate,
      waveformBins: _waveformBins,
      ...stableEntry
    }) => stableEntry;
    if (
      stableJson(omitPlatformProbeValues(manifestEntry))
      !== stableJson(omitPlatformProbeValues(actualEntry))
    ) {
      return reportManifestMismatch(`${asset} stable fields differ`);
    }
  }
  return true;
}

function assertCompleteAndUnique(assets) {
  const expectedNames = [
    ...content.speech.map(({ asset }) => asset),
    ...content.recordings.map(({ asset }) => asset)
  ];
  const actualNames = Object.keys(assets);
  if (
    actualNames.length !== EXPECTED_SPEECH_COUNT + EXPECTED_RECORDING_COUNT
    || expectedNames.some((asset) => !assets[asset])
  ) {
    throw new Error(
      `Chapter 3.5 generated manifest is incomplete: ${actualNames.length}/${expectedNames.length}`
    );
  }
  const seenHashes = new Map();
  for (const asset of expectedNames) {
    const entry = assets[asset];
    const duplicate = seenHashes.get(entry.sha256);
    if (duplicate) {
      throw new Error(`Duplicate generated audio bytes for ${asset} and ${duplicate}.`);
    }
    seenHashes.set(entry.sha256, asset);
  }
}

function main() {
  if (verifyOnly && force) {
    throw new Error("--verify-only cannot be combined with --force.");
  }
  validateContent();
  if (!verifyOnly) {
    mkdirSync(componentDir, { recursive: true });
    mkdirSync(outputDir, { recursive: true });
  }

  const assets = {};
  const rebuiltRecordings = [];

  for (const speech of content.speech) {
    const output = join(componentDir, `${speech.asset}.mp3`);
    assets[speech.asset] = makeSpeechManifestEntry(speech, output);
  }

  const speechAssets = Object.fromEntries(
    content.speech.map(({ asset }) => [asset, assets[asset]])
  );
  const inputProbeCache = new Map();
  for (const recording of content.recordings) {
    const output = join(outputDir, `${recording.asset}.mp3`);
    const { layers, componentAssetHashes } = resolveRecordingLayers(
      recording,
      speechAssets,
      inputProbeCache
    );
    const sourceConfigHash = hash(JSON.stringify(recordingSourceConfig(recording, layers)));
    const reusable = cachedEntryIsReusable({
      asset: recording.asset,
      output,
      sourceConfigHash,
      probe: (path) => probeGeneratedAudio(path, {
        label: recording.asset,
        targetDurationMs: recording.targetDurationMs
      })
    });
    if (!reusable) {
      if (verifyOnly) {
        throw new Error(`Chapter 3.5 recording requires local rebuild: ${recording.asset}`);
      }
      mixRecording(recording, layers, output);
      rebuiltRecordings.push(recording.asset);
    }
    assets[recording.asset] = makeRecordingManifestEntry(
      recording,
      output,
      sourceConfigHash,
      componentAssetHashes
    );
    if (!verifyOnly) writeCheckpoint(assets);
  }

  assertCompleteAndUnique(assets);
  if (verifyOnly && !manifestAssetsMatch(assets)) {
    throw new Error("Chapter 3.5 generated manifest does not match the verified audio files.");
  }
  if (!verifyOnly && (!manifestAssetsMatch(assets) || rebuiltRecordings.length)) {
    writeJsonAtomic(generatedPath, {
      version: 1,
      generatedAt: new Date().toISOString(),
      assets
    });
  }
  if (!verifyOnly) rmSync(checkpointPath, { force: true });

  process.stdout.write(`${JSON.stringify({
    verifiedLocalSpeech: Object.keys(speechAssets),
    rebuiltRecordings,
    verified: Object.keys(assets),
    manifest: generatedPath,
    networkUsed: false
  }, null, 2)}\n`);
}

try {
  main();
} finally {
  rmSync(tempDir, { recursive: true, force: true });
}
