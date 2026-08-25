import { createHash } from "node:crypto";
import { existsSync, readFileSync } from "node:fs";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { spawnSync } from "node:child_process";

const root = resolve(dirname(fileURLToPath(import.meta.url)), "..");
const audioRoot = join(root, "src/assets/audio");
const contentPath = join(root, "src/data/chapter3-interlude-voice-memos.audio.content.json");
const generatedPath = join(root, "src/data/chapter3-interlude-voice-memos.audio.generated.json");
const timelinePath = join(root, "src/data/chapter4-prologue.audio.json");
const interludeContentPath = join(root, "src/data/chapter3InterludeContent.ts");
const controllerPath = join(root, "src/modules/ChapterThreePhoneInterludeController.ts");
const scenePath = join(root, "src/scenes/phone/P21_VoiceMemos/index.tsx");
const audioDirectorPath = join(root, "src/modules/AudioDirector.ts");

const EXPECTED_IDS = [
  "lake",
  "stone",
  "lobby",
  "broadcast",
  "decoy_canteen",
  "decoy_theater",
  "decoy_library"
];
const CORRECT_ORDER = ["lake", "stone", "lobby", "broadcast"];
const DECOY_IDS = ["decoy_canteen", "decoy_theater", "decoy_library"];
const EXPECTED_SPEECH_ASSETS = [
  "vo_ch35_lake_player",
  "vo_ch35_decoy_canteen",
  "vo_ch35_decoy_theater",
  "vo_ch35_decoy_library"
];
const WAVEFORM_BIN_COUNT = 32;
const VALID_EVENT_DISTANCES = new Set(["near", "mid", "far"]);
const VALID_SPEECH_DENSITIES = new Set(["none", "sparse", "moderate", "dense"]);
const ID_PATTERN = /^[a-z0-9]+(?:_[a-z0-9]+)*$/;
const FORBIDDEN_EVENT_LABEL_PATTERN = /正确|错误|干扰|顺序|答案|目的地|段永平|北教|A1/i;

function fail(message) {
  throw new Error(`Chapter 3.5 voice memo validation failed: ${message}`);
}

function readJson(path, label) {
  if (!existsSync(path)) fail(`missing ${label}: ${path}`);
  try {
    return JSON.parse(readFileSync(path, "utf8"));
  } catch (error) {
    fail(`invalid ${label}: ${error instanceof Error ? error.message : String(error)}`);
  }
}

function readText(path, label) {
  if (!existsSync(path)) fail(`missing ${label}: ${path}`);
  return readFileSync(path, "utf8");
}

function sameMembers(actual, expected) {
  return actual.length === expected.length
    && [...actual].sort().every((value, index) => value === [...expected].sort()[index]);
}

function hashFile(path) {
  return createHash("sha256").update(readFileSync(path)).digest("hex");
}

function run(command, args, label) {
  const result = spawnSync(command, args, { cwd: root, encoding: "utf8", maxBuffer: 16 * 1024 * 1024 });
  if (result.status !== 0) {
    fail(`${label}: ${(result.stderr || result.stdout || result.error?.message || "unknown error").trim()}`);
  }
  return result.stdout;
}

function probeAudio(path) {
  const raw = run("ffprobe", [
    "-v", "error",
    "-select_streams", "a:0",
    "-show_entries", "stream=codec_name,codec_type,sample_rate,channels:format=duration",
    "-of", "json",
    path
  ], `ffprobe ${path}`);
  const parsed = JSON.parse(raw);
  const stream = parsed.streams?.find(({ codec_type }) => codec_type === "audio");
  const durationMs = Math.round(Number(parsed.format?.duration) * 1000);
  if (!stream || stream.codec_name !== "mp3") fail(`asset is not MP3: ${path}`);
  if (Number(stream.sample_rate) !== 32000 || Number(stream.channels) !== 1) {
    fail(`asset must be 32000Hz mono: ${path}`);
  }
  run("ffmpeg", ["-v", "error", "-i", path, "-f", "null", "-"], `decode ${path}`);
  return { durationMs, sampleRate: Number(stream.sample_rate), channels: Number(stream.channels) };
}

const content = readJson(contentPath, "content catalog");
if (content.version !== 1 || content.model !== "speech-2.8-hd") fail("unexpected content version or model");
if (!Array.isArray(content.speech) || content.speech.length !== 4) fail("content must contain exactly four MiniMax speech lines");
if (!Array.isArray(content.recordings) || content.recordings.length !== 7) fail("content must contain exactly seven recordings");

const recordingIds = content.recordings.map(({ id }) => id);
const recordingAssets = content.recordings.map(({ asset }) => asset);
const recordingCodes = content.recordings.map(({ code }) => code);
if (!sameMembers(recordingIds, EXPECTED_IDS)) fail("recording IDs do not match the seven approved candidates");
if (new Set(recordingIds).size !== 7 || new Set(recordingAssets).size !== 7 || new Set(recordingCodes).size !== 7) {
  fail("recording IDs, assets and codes must be unique");
}
const correctIds = content.recordings.filter(({ correct }) => correct).map(({ id }) => id);
if (correctIds.length !== 4 || !CORRECT_ORDER.every((id, index) => correctIds[index] === id)) {
  fail("correct recordings must be lake, stone, lobby and broadcast in that order");
}
const decoyIds = content.recordings.filter(({ correct }) => !correct).map(({ id }) => id);
if (decoyIds.length !== 3 || !sameMembers(decoyIds, DECOY_IDS)) {
  fail("decoy recordings must be the three approved decoy IDs");
}
if (content.recordings.some(({ targetDurationMs }) => targetDurationMs !== 5200)) fail("all recordings must target 5200ms");

const speechAssets = content.speech.map(({ asset }) => asset);
if (!sameMembers(speechAssets, EXPECTED_SPEECH_ASSETS)) fail("unexpected MiniMax speech asset set");
if (new Set(content.speech.map(({ voiceTextEn }) => voiceTextEn)).size !== 4) fail("MiniMax speech lines must be unique");
if (new Set(content.speech.map(({ subtitleZh }) => subtitleZh)).size !== 4) fail("Chinese transcriptions must be unique");
for (const line of content.speech) {
  const voice = content.voices?.[line.voiceRole];
  if (!voice?.id || voice.language !== "English" || line.emotion !== "calm") {
    fail(`invalid voice contract for ${line.asset}`);
  }
}

const speechAssetSet = new Set(speechAssets);
for (const recording of content.recordings) {
  const productionPrompt = recording.productionPrompt;
  if (
    !productionPrompt
    || typeof productionPrompt.eventEmphasisZh !== "string"
    || productionPrompt.eventEmphasisZh.trim().length < 12
    || typeof productionPrompt.distanceZh !== "string"
    || productionPrompt.distanceZh.trim().length < 12
    || !VALID_SPEECH_DENSITIES.has(productionPrompt.speechDensity)
    || typeof productionPrompt.decoyOverlapZh !== "string"
    || productionPrompt.decoyOverlapZh.trim().length < 12
  ) {
    fail(`${recording.id} needs event emphasis, distance, speech density and overlap prompt data`);
  }
  if (!Array.isArray(recording.soundEvents) || recording.soundEvents.length < 2 || recording.soundEvents.length > 4) {
    fail(`${recording.id} needs two to four authored sound events`);
  }
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
      fail(`${recording.id} has an invalid sound event: ${JSON.stringify(event)}`);
    }
    previousEventStartMs = event.startMs;
  }
  if (!Array.isArray(recording.layers) || recording.layers.length < 2) fail(`${recording.id} needs at least two mix layers`);
  for (const layer of recording.layers) {
    if (layer.kind === "speech") {
      if (!speechAssetSet.has(layer.asset)) fail(`${recording.id} references unknown speech asset ${layer.asset}`);
      continue;
    }
    if (layer.kind !== "file" || typeof layer.path !== "string" || !existsSync(join(audioRoot, layer.path))) {
      fail(`${recording.id} references a missing local component: ${layer.path ?? "unknown"}`);
    }
  }
}

const generated = readJson(generatedPath, "generated manifest");
const manifestAssets = generated.assets ?? {};
const expectedManifestAssets = [...EXPECTED_SPEECH_ASSETS, ...recordingAssets];
if (!sameMembers(Object.keys(manifestAssets), expectedManifestAssets)) {
  fail("generated manifest must contain exactly four dry voices and seven mixed recordings");
}

const outputHashes = new Set();
const outputPaths = new Set();
for (const assetName of expectedManifestAssets) {
  const entry = manifestAssets[assetName];
  if (!entry?.path || !entry.sha256 || !entry.sourceConfigHash || !entry.source) fail(`incomplete manifest entry for ${assetName}`);
  const assetPath = join(audioRoot, entry.path);
  if (!existsSync(assetPath)) fail(`missing generated asset ${assetName}: ${assetPath}`);
  const actualHash = hashFile(assetPath);
  if (entry.sha256 !== actualHash) fail(`hash mismatch for ${assetName}`);
  const metadata = probeAudio(assetPath);
  if (
    !Number.isFinite(entry.durationMs)
    || entry.durationMs <= 0
    || entry.sampleRate !== 32000
    || entry.channels !== 1
  ) {
    fail(`manifest metadata mismatch for ${assetName}`);
  }
  if (recordingAssets.includes(assetName)) {
    const recording = content.recordings.find(({ asset }) => asset === assetName);
    if (Math.abs(metadata.durationMs - 5200) > 80) fail(`${assetName} duration must be 5200ms ±80ms`);
    if (Math.abs(entry.durationMs - 5200) > 80) fail(`${assetName} manifest duration must be 5200ms ±80ms`);
    if (entry.kind !== "correct" && entry.kind !== "decoy") fail(`${assetName} needs a recording kind`);
    if (!entry.componentAssetHashes || Object.keys(entry.componentAssetHashes).length < 2) {
      fail(`${assetName} needs component hashes`);
    }
    if (outputPaths.has(entry.path)) fail(`duplicate mixed recording path detected: ${entry.path}`);
    outputPaths.add(entry.path);
    if (outputHashes.has(actualHash)) fail(`duplicate mixed recording bytes detected: ${assetName}`);
    outputHashes.add(actualHash);
    if (
      !Array.isArray(entry.waveformBins)
      || entry.waveformBins.length !== WAVEFORM_BIN_COUNT
      || entry.waveformBins.some((bin) => !Number.isFinite(bin) || bin < 0 || bin > 1)
      || Math.max(...entry.waveformBins) < 0.999
    ) {
      fail(`${assetName} needs ${WAVEFORM_BIN_COUNT} normalized RMS waveform bins in the 0..1 range`);
    }
    if (JSON.stringify(entry.soundEvents) !== JSON.stringify(recording?.soundEvents)) {
      fail(`${assetName} manifest sound events do not match the authored content`);
    }
    if (entry.soundEvents.some(({ startMs, endMs }) => startMs < 0 || endMs <= startMs || endMs > metadata.durationMs)) {
      fail(`${assetName} has a sound event outside the final MP3 duration`);
    }
  } else {
    const speech = content.speech.find(({ asset }) => asset === assetName);
    if (!speech || metadata.durationMs > speech.maxDurationMs || entry.durationMs > speech.maxDurationMs) {
      fail(`${assetName} exceeds its authored speech duration budget`);
    }
  }
}
if (outputPaths.size !== 7 || outputHashes.size !== 7) {
  fail("the seven final mixed MP3 files must use unique paths and unique bytes");
}

const timeline = readJson(timelinePath, "audio timeline");
for (const id of EXPECTED_IDS) {
  const event = timeline.events?.[`chapter35_voice_audition_${id}`];
  const expectedAsset = content.recordings.find((recording) => recording.id === id)?.asset;
  if (!event || event.cues?.length !== 1 || event.cues[0]?.channel !== "voice" || event.cues[0]?.asset !== expectedAsset) {
    fail(`audio timeline lacks a controlled preview cue for ${id}`);
  }
}
if (!timeline.events?.chapter35_voice_audition_stop) fail("audio timeline lacks chapter35_voice_audition_stop");

const controllerSource = readText(controllerPath, "interlude controller");
const interludeContentSource = readText(interludeContentPath, "interlude content entry");
for (const id of DECOY_IDS) {
  if (!interludeContentSource.includes(`"${id}"`)) fail(`interlude content candidate type lacks ${id}`);
}
if (
  !interludeContentSource.includes("voiceMemoAudioContent.recordings")
  || !interludeContentSource.includes("voiceCandidateIds: recordings.map")
  || !controllerSource.includes("chapterThreeInterludeValidationContract.voiceCandidateIds")
  || !controllerSource.includes("VOICE_CANDIDATES.includes")
) {
  fail("controller must validate all seven catalog candidates before exact-order comparison");
}

const sceneSource = readText(scenePath, "voice memo scene");
if (!sceneSource.includes("chapter3-interlude-voice-memos.audio.content.json")) fail("scene must consume the recording catalog");
if (!sceneSource.includes("chapter3-interlude-voice-memos.audio.generated.json")) fail("scene must consume real recording durations");
if (!sceneSource.includes("selected.length >= 4") || !sceneSource.includes("chapter35_voice_audition_stop")) {
  fail("scene must cap selection at four and stop controlled previews");
}

const audioDirectorSource = readText(audioDirectorPath, "audio director");
if (!audioDirectorSource.includes("chapter3InterludeVoiceMemosGeneratedAudioData")) fail("AudioDirector must register the voice-memo manifest");
if (!audioDirectorSource.includes('cueId === "chapter35_voice_audition_stop"')) fail("AudioDirector must stop voice-memo previews explicitly");
if (!audioDirectorSource.includes("cue.asset && !cue.subtitleKey")) fail("AudioDirector must permit asset-backed voice previews without story subtitles");

process.stdout.write(
  `Chapter 3.5 voice memo validation passed: ${content.recordings.length} recordings, `
  + `${correctIds.length} canonical, ${decoyIds.length} decoys, `
  + `${WAVEFORM_BIN_COUNT} RMS bins per final MP3, ${content.speech.length} MiniMax speech assets.\n`
);
