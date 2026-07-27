import { createHash } from "node:crypto";
import { existsSync, mkdirSync, mkdtempSync, readFileSync, renameSync, rmSync, writeFileSync } from "node:fs";
import { homedir, tmpdir } from "node:os";
import { delimiter, dirname, join, relative, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { spawnSync } from "node:child_process";

const root = resolve(dirname(fileURLToPath(import.meta.url)), "..");
const contentPath = join(root, "src/data/chapter3-canteen.audio.content.json");
const generatedPath = join(root, "src/data/chapter3-canteen.audio.generated.json");
const audioRoot = join(root, "src/assets/audio");
const content = JSON.parse(readFileSync(contentPath, "utf8"));
const previous = existsSync(generatedPath)
  ? JSON.parse(readFileSync(generatedPath, "utf8"))
  : { assets: {} };
const force = process.argv.includes("--force");
const verifyOnly = process.argv.includes("--verify-only");
const tempDir = mkdtempSync(join(tmpdir(), "seven-fifty-five-canteen-audio-"));

const MUSIC_MODEL = "music-2.6";
const SFX_STEM_SECONDS = 15.5;
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
  const match = candidates.find((path) => existsSync(path));
  if (!match) throw new Error("MiniMax CLI not found. Set MMX_BIN to an executable mmx path.");
  return match;
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

function probeAudio(path, limits) {
  if (!existsSync(path)) throw new Error(`Missing audio file: ${path}`);
  const output = run(
    "ffprobe",
    [
      "-v", "error",
      "-select_streams", "a:0",
      "-show_entries", "stream=codec_name,codec_type,sample_rate,channels:format=duration",
      "-of", "json",
      path
    ],
    `Probe ${path}`
  );
  const parsed = JSON.parse(output);
  const stream = parsed.streams?.find(({ codec_type }) => codec_type === "audio");
  const durationMs = Math.round(Number(parsed.format?.duration) * 1000);
  const sampleRate = Number(stream?.sample_rate);
  const channels = Number(stream?.channels);
  if (!stream || stream.codec_name !== "mp3") {
    throw new Error(`Unexpected codec for ${path}: ${stream?.codec_name ?? "none"}`);
  }
  if (!Number.isFinite(durationMs) || durationMs < limits.minDurationMs || durationMs > limits.maxDurationMs) {
    throw new Error(`Unexpected duration for ${path}: ${durationMs}ms, expected ${limits.minDurationMs}-${limits.maxDurationMs}ms`);
  }
  if (!Number.isInteger(sampleRate) || sampleRate <= 0 || !Number.isInteger(channels) || channels <= 0) {
    throw new Error(`Invalid stream metadata for ${path}`);
  }
  run("ffmpeg", ["-v", "error", "-i", path, "-f", "null", "-"], `Decode ${path}`);
  return { durationMs, codec: stream.codec_name, sampleRate, channels };
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
      if (attempt < 3) {
        process.stderr.write(`${label} attempt ${attempt} rejected; retrying.\n`);
      }
    }
  }
  throw lastError;
}

function outputPath(definition) {
  return join(audioRoot, definition.path);
}

function normalizeBed(input, output, durationSeconds, loudness) {
  const fadeOutStart = Math.max(0, durationSeconds - 0.2);
  run(
    "ffmpeg",
    [
      "-y", "-hide_banner", "-loglevel", "error", "-stream_loop", "-1", "-i", input,
      "-t", String(durationSeconds),
      "-af", `loudnorm=I=${loudness}:TP=-1.5:LRA=8,afade=t=in:st=0:d=0.06,afade=t=out:st=${fadeOutStart}:d=0.2`,
      "-ar", "44100", "-ac", "2", "-b:a", "192k", output
    ],
    `Normalize ${output}`
  );
}

function cutSfx(stem, definition) {
  const output = outputPath(definition);
  const fadeOutStart = Math.max(0, definition.durationSeconds - 0.08);
  run(
    "ffmpeg",
    [
      "-y", "-hide_banner", "-loglevel", "error", "-i", stem,
      "-ss", String(definition.cutStartSeconds),
      "-t", String(definition.durationSeconds),
      "-af", `loudnorm=I=-18:TP=-1.5:LRA=6,afade=t=in:st=0:d=0.02,afade=t=out:st=${fadeOutStart}:d=0.08`,
      "-ar", "44100", "-ac", "2", "-b:a", "160k", output
    ],
    `Cut ${definition.cue}`
  );
  probeAudio(output, LIMITS.sfx);
}

function validateContent() {
  if (content.chapterId !== "chapter-3-canteen-audio") throw new Error(`Unexpected chapter id: ${content.chapterId}`);
  if (content.music?.length !== 3 || content.sfx?.length !== 10) {
    throw new Error("Canteen audio requires exactly 3 music beds and 10 one-shot effects.");
  }
  const definitions = [...content.music, ...content.sfx];
  for (const key of ["cue", "asset", "path"]) {
    const values = definitions.map((definition) => definition[key]);
    if (values.some((value) => typeof value !== "string" || value.length === 0) || new Set(values).size !== values.length) {
      throw new Error(`Canteen audio ${key} values must be non-empty and unique.`);
    }
  }
  const groups = [...new Set(content.sfx.map(({ group }) => group))];
  if (groups.length !== 2 || groups.some((group) => content.sfx.filter((item) => item.group === group).length !== 5)) {
    throw new Error("Canteen sound design must contain two five-cue stems.");
  }
}

function configHash(definition, groupDefinitions) {
  return hash(JSON.stringify({ model: MUSIC_MODEL, definition, groupDefinitions }));
}

function canReuse(definition, kind, currentConfigHash) {
  const output = outputPath(definition);
  if (force || !existsSync(output)) return false;
  const cached = previous.assets?.[definition.asset];
  if (cached?.sourceConfigHash !== currentConfigHash || cached?.sha256 !== fileHash(output)) return false;
  try {
    probeAudio(output, LIMITS[kind]);
    return true;
  } catch {
    return false;
  }
}

function generateMusic(definition) {
  const raw = join(tempDir, `${definition.stage}.raw.mp3`);
  generateMmxFile(
    [
      "music", "generate", "--model", MUSIC_MODEL,
      "--prompt", definition.prompt,
      "--genre", definition.genre,
      "--mood", definition.mood,
      "--instruments", definition.instruments,
      "--bpm", String(definition.bpm),
      "--avoid", "vocals, orchestral trailer, long intro, long outro, heavy sub bass, continuous sound effects",
      "--use-case", "looping background music for a top-down pixel RPG",
      "--structure", "immediate start, one compact loop, small variations, clean ending",
      "--instrumental", "--format", "mp3", "--sample-rate", "44100", "--bitrate", "256000",
      "--out", raw
    ],
    raw,
    `MiniMax music ${definition.cue}`,
    10000
  );
  normalizeBed(raw, outputPath(definition), definition.durationSeconds, -23);
  probeAudio(outputPath(definition), LIMITS.music);
}

function generateSfxGroup(group, definitions) {
  const raw = join(tempDir, `sfx-${group}.raw.mp3`);
  const stem = join(tempDir, `sfx-${group}.stem.mp3`);
  const sequence = definitions.map(({ description }, index) => `${index + 1}. ${description}.`).join(" ");
  generateMmxFile(
    [
      "music", "generate", "--model", MUSIC_MODEL,
      "--prompt", `Five isolated non-musical game cues in this exact order, with at least two seconds of silence between cues. ${sequence} No continuous melody or ambience.`,
      "--genre", "game sound effects",
      "--mood", "dry, concise, readable",
      "--instruments", "foley, short digital UI tones, compact noise sweeps, dry mechanical impacts",
      "--avoid", "vocals, song structure, sustained pad, continuous beat, long reverb, overlapping cues",
      "--use-case", "isolated one-shot effects for a top-down pixel RPG",
      "--structure", "five one-shot cues with long silence between each cue",
      "--instrumental", "--format", "mp3", "--sample-rate", "44100", "--bitrate", "256000",
      "--out", raw
    ],
    raw,
    `MiniMax sound-design stem ${group}`,
    16000
  );
  normalizeBed(raw, stem, SFX_STEM_SECONDS, -18);
  definitions.forEach((definition) => cutSfx(stem, definition));
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
    const reusable = canReuse(definition, "music", currentHash);
    if (!reusable && verifyOnly) {
      throw new Error(`Canteen music requires regeneration: ${definition.asset}`);
    }
    if (!reusable) {
      generateMusic(definition);
      generated.push(definition.asset);
    }
  }

  for (const group of [...new Set(content.sfx.map(({ group }) => group))]) {
    const groupDefinitions = content.sfx.filter((definition) => definition.group === group);
    const reuseChecks = groupDefinitions.map((definition) => {
      const currentHash = configHash(definition, groupDefinitions);
      hashes.set(definition.cue, currentHash);
      return canReuse(definition, "sfx", currentHash);
    });
    const reusable = reuseChecks.every(Boolean);
    if (!reusable && verifyOnly) {
      throw new Error(`Canteen sound-effect group requires regeneration: ${group}`);
    }
    if (!reusable) {
      generateSfxGroup(group, groupDefinitions);
      generated.push(...groupDefinitions.map(({ asset }) => asset));
    }
  }

  const assets = {};
  const seenFileHashes = new Map();
  for (const { kind, definition } of definitions) {
    const path = outputPath(definition);
    const metadata = probeAudio(path, LIMITS[kind]);
    const sha256 = fileHash(path);
    const duplicate = seenFileHashes.get(sha256);
    if (duplicate) throw new Error(`Duplicate audio bytes for ${definition.asset} and ${duplicate}`);
    seenFileHashes.set(sha256, definition.asset);
    assets[definition.asset] = {
      path: relative(audioRoot, path).replaceAll("\\", "/"),
      kind,
      ...metadata,
      sha256,
      source: kind === "music" ? `MiniMax ${MUSIC_MODEL}` : `MiniMax ${MUSIC_MODEL} sound-design cut`,
      sourceConfigHash: hashes.get(definition.cue)
    };
  }

  const manifest = {
    version: 1,
    generatedAt: new Date().toISOString(),
    assets
  };
  if (!verifyOnly && generated.length > 0) {
    const staged = `${generatedPath}.tmp-${process.pid}`;
    writeFileSync(staged, `${JSON.stringify(manifest, null, 2)}\n`, "utf8");
    renameSync(staged, generatedPath);
  }
  process.stdout.write(`${JSON.stringify({ generated, verified: assets, manifest: generatedPath }, null, 2)}\n`);
}

try {
  main();
} finally {
  rmSync(tempDir, { recursive: true, force: true });
}
