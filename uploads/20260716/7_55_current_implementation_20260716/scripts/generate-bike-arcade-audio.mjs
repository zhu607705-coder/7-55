import { createHash } from "node:crypto";
import { existsSync, mkdirSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { homedir, tmpdir } from "node:os";
import { basename, dirname, join, relative, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { spawnSync } from "node:child_process";

const root = resolve(dirname(fileURLToPath(import.meta.url)), "..");
const contentPath = join(root, "src/data/bike-arcade.content.json");
const generatedPath = join(root, "src/data/bike-arcade.audio.generated.json");
const audioRoot = join(root, "src/assets/audio");
const content = JSON.parse(readFileSync(contentPath, "utf8"));
const previous = existsSync(generatedPath)
  ? JSON.parse(readFileSync(generatedPath, "utf8"))
  : { assets: {} };
const force = process.argv.includes("--force");
const verifyOnly = process.argv.includes("--verify-only");
const voiceOnly = process.argv.includes("--voice-only");
const tempDir = mkdtempSync(join(tmpdir(), "seven-fifty-five-bike-arcade-audio-"));

const MUSIC_MODEL = "music-2.6";
const SPEECH_MODEL = "speech-2.8-hd";
const SFX_STEM_SECONDS = 15.5;

const OUTPUT_FILES = {
  "music.start": "bike-arcade/music/music_bike_755_intro.mp3",
  "music.congestion": "bike-arcade/music/music_bike_755_run_a.mp3",
  "music.sprint": "bike-arcade/music/music_bike_755_run_b.mp3",
  "music.result": "bike-arcade/music/music_bike_755_result.mp3",
  "sfx.lane_change": "bike-arcade/sfx/fx_bike_755_lane_change.mp3",
  "sfx.near_miss": "bike-arcade/sfx/fx_bike_755_near_miss.mp3",
  "sfx.collision": "bike-arcade/sfx/fx_bike_755_collision.mp3",
  "sfx.damage": "bike-arcade/sfx/fx_bike_755_damage.mp3",
  "sfx.milestone": "bike-arcade/sfx/fx_bike_755_milestone.mp3",
  "sfx.pause": "bike-arcade/sfx/fx_bike_755_pause.mp3",
  "sfx.resume": "bike-arcade/sfx/fx_bike_755_resume.mp3",
  "sfx.success": "bike-arcade/sfx/fx_bike_755_success.mp3",
  "sfx.failure": "bike-arcade/sfx/fx_bike_755_failure.mp3",
  "sfx.button": "bike-arcade/sfx/fx_bike_755_button.mp3"
};

const FINAL_LIMITS = {
  music: { minDurationMs: 10000, maxDurationMs: 26000 },
  sfx: { minDurationMs: 350, maxDurationMs: 1800 },
  voice: { minDurationMs: 500, maxDurationMs: 7000 }
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
  const candidate = candidates.find((path) => existsSync(path));
  if (!candidate) {
    throw new Error("MiniMax CLI not found. Set MMX_BIN to an executable mmx path.");
  }
  return candidate;
}

function run(command, args, label) {
  const result = spawnSync(command, args, {
    cwd: root,
    encoding: "utf8",
    maxBuffer: 16 * 1024 * 1024
  });
  if (result.status !== 0) {
    const message = (result.stderr || result.stdout || result.error?.message || "unknown error")
      .trim()
      .slice(0, 1600);
    throw new Error(`${label} failed: ${message}`);
  }
  return result.stdout;
}

function probeAudio(path, { minDurationMs, maxDurationMs }) {
  if (!existsSync(path)) {
    throw new Error(`Missing audio file: ${path}`);
  }
  const result = spawnSync(
    "ffprobe",
    [
      "-v",
      "error",
      "-select_streams",
      "a:0",
      "-show_entries",
      "stream=codec_name,codec_type,sample_rate,channels:format=duration",
      "-of",
      "json",
      path
    ],
    { cwd: root, encoding: "utf8", maxBuffer: 4 * 1024 * 1024 }
  );
  if (result.status !== 0) {
    throw new Error(`ffprobe failed for ${path}: ${(result.stderr || result.error?.message || "unknown error").trim()}`);
  }

  let parsed;
  try {
    parsed = JSON.parse(result.stdout);
  } catch (error) {
    throw new Error(`ffprobe returned invalid JSON for ${path}: ${error instanceof Error ? error.message : String(error)}`);
  }
  const stream = parsed.streams?.find(({ codec_type }) => codec_type === "audio");
  const durationMs = Math.round(Number(parsed.format?.duration) * 1000);
  const sampleRate = Number(stream?.sample_rate);
  const channels = Number(stream?.channels);
  if (!stream || stream.codec_name !== "mp3") {
    throw new Error(`Unexpected codec for ${path}: ${stream?.codec_name ?? "none"}`);
  }
  if (!Number.isFinite(durationMs) || durationMs < minDurationMs || durationMs > maxDurationMs) {
    throw new Error(`Unexpected duration for ${path}: ${durationMs}ms, expected ${minDurationMs}-${maxDurationMs}ms`);
  }
  if (!Number.isInteger(sampleRate) || sampleRate <= 0 || !Number.isInteger(channels) || channels <= 0) {
    throw new Error(`Invalid stream metadata for ${path}`);
  }

  run("ffmpeg", ["-v", "error", "-i", path, "-f", "null", "-"], `Decode ${path}`);
  return { durationMs, codec: stream.codec_name, sampleRate, channels };
}

function verifyFinal(path, kind) {
  return probeAudio(path, FINAL_LIMITS[kind]);
}

function generateMmxFile(args, output, label, minDurationMs) {
  let lastError;
  for (let attempt = 1; attempt <= 3; attempt += 1) {
    rmSync(output, { force: true });
    try {
      run(
        findMmx(),
        [...args, "--timeout", "180", "--non-interactive", "--quiet"],
        label
      );
      probeAudio(output, { minDurationMs, maxDurationMs: 600000 });
      return;
    } catch (error) {
      lastError = error;
      if (attempt < 3) {
        const message = error instanceof Error ? error.message : String(error);
        process.stderr.write(`${label} attempt ${attempt} rejected; retrying: ${message}\n`);
      }
    }
  }
  throw lastError;
}

function normalizeVoice(input, output) {
  run(
    "ffmpeg",
    [
      "-y",
      "-hide_banner",
      "-loglevel",
      "error",
      "-i",
      input,
      "-af",
      "silenceremove=start_periods=1:start_duration=0.04:start_threshold=-48dB,areverse,silenceremove=start_periods=1:start_duration=0.08:start_threshold=-48dB,areverse,loudnorm=I=-16:TP=-1.5:LRA=7",
      "-ar",
      "32000",
      "-ac",
      "1",
      "-b:a",
      "128k",
      output
    ],
    `Normalize voice ${output}`
  );
}

function normalizeBed(input, output, durationSeconds, loudness) {
  const fadeOutStart = Math.max(0, durationSeconds - 0.2);
  run(
    "ffmpeg",
    [
      "-y",
      "-hide_banner",
      "-loglevel",
      "error",
      "-i",
      input,
      "-t",
      String(durationSeconds),
      "-af",
      `loudnorm=I=${loudness}:TP=-1.5:LRA=8,afade=t=in:st=0:d=0.06,afade=t=out:st=${fadeOutStart}:d=0.2`,
      "-ar",
      "44100",
      "-ac",
      "2",
      "-b:a",
      "192k",
      output
    ],
    `Normalize bed ${output}`
  );
}

function cutSfx(stem, definition, output) {
  const fadeOutStart = Math.max(0, definition.durationSeconds - 0.08);
  run(
    "ffmpeg",
    [
      "-y",
      "-hide_banner",
      "-loglevel",
      "error",
      "-i",
      stem,
      "-ss",
      String(definition.cutStartSeconds),
      "-t",
      String(definition.durationSeconds),
      "-af",
      `loudnorm=I=-18:TP=-1.5:LRA=6,afade=t=in:st=0:d=0.02,afade=t=out:st=${fadeOutStart}:d=0.08`,
      "-ar",
      "44100",
      "-ac",
      "2",
      "-b:a",
      "160k",
      output
    ],
    `Cut sound effect ${definition.cue}`
  );
}

function outputPath(cue) {
  const relativePath = OUTPUT_FILES[cue];
  if (!relativePath) {
    throw new Error(`No output path declared for cue ${cue}`);
  }
  return join(audioRoot, relativePath);
}

function assetName(cue) {
  return basename(OUTPUT_FILES[cue], ".mp3");
}

function relativeAudioPath(path) {
  return relative(audioRoot, path).replaceAll("\\", "/");
}

function validateContent() {
  if (content.chapterId !== "bike-arcade-755") {
    throw new Error(`Unexpected chapter id: ${content.chapterId}`);
  }
  if (content.music?.length !== 4 || content.sfx?.length !== 10 || content.narration?.length !== 3) {
    throw new Error("Bike arcade content must contain 4 music cues, 10 sound effects, and 3 narration lines.");
  }
  const definitions = [...content.music, ...content.sfx];
  const cues = definitions.map(({ cue }) => cue);
  if (new Set(cues).size !== cues.length) {
    throw new Error("Bike arcade cue ids must be unique.");
  }
  if (cues.sort().join("\n") !== Object.keys(OUTPUT_FILES).sort().join("\n")) {
    throw new Error("Generator output paths and content cue ids do not match.");
  }
  const bpms = content.music.map(({ bpm }) => bpm);
  if (Math.max(...bpms) - Math.min(...bpms) < 60) {
    throw new Error("Music stages need at least a 60 BPM design spread.");
  }
  for (const narration of content.narration) {
    const subtitle = content.subtitles?.[narration.subtitle];
    if (!subtitle || subtitle === narration.text || !/[\u3400-\u9fff]/u.test(subtitle)) {
      throw new Error(`Text feedback lacks a decoupled Chinese subtitle: ${narration.cue}`);
    }
  }
}

function canReuse(cue, kind, configHash) {
  if (force || !existsSync(outputPath(cue))) return false;
  if (previous.assets?.[assetName(cue)]?.sourceConfigHash !== configHash) return false;
  try {
    verifyFinal(outputPath(cue), kind);
    return true;
  } catch {
    return false;
  }
}

function generateMusic(definition) {
  const raw = join(tempDir, `${definition.stage}.raw.mp3`);
  generateMmxFile(
    [
      "music",
      "generate",
      "--model",
      MUSIC_MODEL,
      "--prompt",
      definition.prompt,
      "--genre",
      definition.genre,
      "--mood",
      definition.mood,
      "--instruments",
      definition.instruments,
      "--bpm",
      String(definition.bpm),
      "--avoid",
      "vocals, cinematic orchestra, long intro, long outro, heavy sub bass, continuous sound effects",
      "--use-case",
      "looping background music for a portrait mobile bicycle arcade game",
      "--structure",
      "immediate start, one compact loop, small variations, clean ending",
      "--instrumental",
      "--format",
      "mp3",
      "--sample-rate",
      "44100",
      "--bitrate",
      "256000",
      "--out",
      raw
    ],
    raw,
    `MiniMax music ${definition.cue}`,
    10000
  );
  normalizeBed(raw, outputPath(definition.cue), definition.durationSeconds, -23);
  verifyFinal(outputPath(definition.cue), "music");
}

function generateSfxGroup(group, definitions) {
  const raw = join(tempDir, `sfx-${group}.raw.mp3`);
  const stem = join(tempDir, `sfx-${group}.stem.mp3`);
  const sequence = definitions
    .map(({ description }, index) => `${index + 1}. ${description}.`)
    .join(" ");
  generateMmxFile(
    [
      "music",
      "generate",
      "--model",
      MUSIC_MODEL,
      "--prompt",
      `Five isolated non-musical game cues in this exact order, with at least two seconds of silence between cues. ${sequence} No continuous melody or ambience.`,
      "--genre",
      "game sound effects",
      "--mood",
      "dry, concise, readable",
      "--instruments",
      "digital UI tones, bicycle mechanics, short noise sweeps, compact arcade signals",
      "--avoid",
      "vocals, song structure, sustained pad, continuous beat, long reverb, overlapping cues",
      "--use-case",
      "isolated one-shot effects for a mobile bicycle arcade game",
      "--structure",
      "five one-shot cues with long silence between each cue",
      "--instrumental",
      "--format",
      "mp3",
      "--sample-rate",
      "44100",
      "--bitrate",
      "256000",
      "--out",
      raw
    ],
    raw,
    `MiniMax sound-design stem ${group}`,
    16000
  );
  normalizeBed(raw, stem, SFX_STEM_SECONDS, -18);
  for (const definition of definitions) {
    cutSfx(stem, definition, outputPath(definition.cue));
    verifyFinal(outputPath(definition.cue), "sfx");
  }
}

function generateVoice(definition) {
  const raw = join(tempDir, `${definition.stage}.voice.raw.mp3`);
  generateMmxFile(
    [
      "speech",
      "synthesize",
      "--model",
      SPEECH_MODEL,
      "--voice",
      content.voice.id,
      "--language",
      content.voice.language,
      "--speed",
      String(definition.profile.speed),
      "--volume",
      "1",
      "--pitch",
      String(definition.profile.pitch),
      "--sample-rate",
      "32000",
      "--bitrate",
      "128000",
      "--channels",
      "1",
      "--text",
      definition.text,
      "--out",
      raw
    ],
    raw,
    `MiniMax narration ${definition.cue}`,
    500
  );
  normalizeVoice(raw, outputPath(definition.cue));
  verifyFinal(outputPath(definition.cue), "voice");
}

function main() {
  if (verifyOnly && voiceOnly) {
    throw new Error("--verify-only cannot be combined with --voice-only.");
  }
  validateContent();
  for (const relativePath of Object.values(OUTPUT_FILES)) {
    mkdirSync(dirname(join(audioRoot, relativePath)), { recursive: true });
  }

  const configHashes = new Map();
  const generated = new Set();

  for (const definition of content.music) {
    const configHash = hash(JSON.stringify({ model: MUSIC_MODEL, definition }));
    configHashes.set(definition.cue, configHash);
    if (!verifyOnly && !voiceOnly && !canReuse(definition.cue, "music", configHash)) {
      generateMusic(definition);
      generated.add(definition.cue);
    }
  }

  const sfxGroups = [...new Set(content.sfx.map(({ group }) => group))];
  for (const group of sfxGroups) {
    const definitions = content.sfx.filter((definition) => definition.group === group);
    const stemHash = hash(JSON.stringify({ model: MUSIC_MODEL, group, definitions }));
    const groupHashes = new Map();
    for (const definition of definitions) {
      const configHash = hash(JSON.stringify({ stemHash, definition }));
      groupHashes.set(definition.cue, configHash);
      configHashes.set(definition.cue, configHash);
    }
    const reusable = definitions.every((definition) =>
      canReuse(definition.cue, "sfx", groupHashes.get(definition.cue))
    );
    if (!verifyOnly && !voiceOnly && !reusable) {
      generateSfxGroup(group, definitions);
      for (const definition of definitions) generated.add(definition.cue);
    }
  }

  const typedDefinitions = [
    ...content.music.map((definition) => ({ kind: "music", definition })),
    ...content.sfx.map((definition) => ({ kind: "sfx", definition }))
  ];
  const assets = {};
  const seenHashes = new Map();

  for (const { kind, definition } of typedDefinitions) {
    const path = outputPath(definition.cue);
    const metadata = verifyFinal(path, kind);
    const sha256 = fileHash(path);
    const duplicateCue = seenHashes.get(sha256);
    if (duplicateCue) {
      throw new Error(`Duplicate audio bytes for ${definition.cue} and ${duplicateCue}`);
    }
    seenHashes.set(sha256, definition.cue);

    const source =
      kind === "voice"
        ? `MiniMax ${SPEECH_MODEL} ${content.voice.id}`
        : kind === "sfx"
          ? `MiniMax ${MUSIC_MODEL} sound-design cut`
          : `MiniMax ${MUSIC_MODEL}`;
    assets[assetName(definition.cue)] = {
      path: relativeAudioPath(path),
      kind,
      ...metadata,
      sha256,
      source,
      sourceConfigHash: configHashes.get(definition.cue),
      ...(kind === "voice"
        ? {
            sourceTextHash: hash(definition.text),
            sourceProfileHash: hash(
              JSON.stringify({ voice: content.voice, profile: definition.profile, delivery: definition.delivery })
            )
          }
        : {})
    };
  }

  const manifest = {
    version: 1,
    generatedAt: new Date().toISOString(),
    assets
  };
  writeFileSync(generatedPath, `${JSON.stringify(manifest, null, 2)}\n`, "utf8");
  process.stdout.write(
    `${JSON.stringify(
      {
        generated: [...generated].map((cue) => assetName(cue)),
        verified: Object.entries(assets).map(([asset, metadata]) => ({
          asset,
          path: metadata.path,
          durationMs: metadata.durationMs,
          codec: metadata.codec
        })),
        manifest: generatedPath
      },
      null,
      2
    )}\n`
  );
}

try {
  main();
} finally {
  rmSync(tempDir, { recursive: true, force: true });
}
