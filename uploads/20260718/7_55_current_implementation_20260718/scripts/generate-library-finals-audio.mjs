import { createHash } from "node:crypto";
import { copyFileSync, existsSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { homedir, tmpdir } from "node:os";
import { dirname, join, relative, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { spawnSync } from "node:child_process";

const root = resolve(dirname(fileURLToPath(import.meta.url)), "..");
const contentPath = join(root, "src/data/library-finals.content.json");
const generatedPath = join(root, "src/data/library-finals.audio.generated.json");
const voiceDir = join(root, "src/assets/audio/library-finals/vo");
const musicDir = join(root, "src/assets/audio/library-finals/music");
const sfxDir = join(root, "src/assets/audio/library-finals/sfx");
const force = process.argv.includes("--force");
const verifyOnly = process.argv.includes("--verify-only");
const voiceOnly = process.argv.includes("--voice-only");
const mediaOnly = process.argv.includes("--media-only");
const requestedAsset = optionValue("--asset");
const content = JSON.parse(readFileSync(contentPath, "utf8"));
const previousGenerated = existsSync(generatedPath) ? JSON.parse(readFileSync(generatedPath, "utf8")) : { assets: {} };
const tempDir = mkdtempSync(join(tmpdir(), "seven-fifty-five-audio-"));
const VOICE_ID = content.voice.id;
const VOICE_LANGUAGE = content.voice.language;
const MUSIC_MODEL = "music-2.5";
const MUSIC_DURATION_SECONDS = 24;
const MUSIC_MIN_DURATION_SECONDS = 20;
const MIN_AUDIBLE_MEAN_DB = -70;

function optionValue(flag) {
  const inline = process.argv.find((argument) => argument.startsWith(`${flag}=`));
  if (inline) {
    return inline.slice(flag.length + 1);
  }
  const index = process.argv.indexOf(flag);
  if (index === -1) {
    return null;
  }
  const value = process.argv[index + 1];
  if (!value || value.startsWith("--")) {
    throw new Error(`${flag} 需要一个资产名。`);
  }
  return value;
}

const VOICE_PROFILES = {
  library_route_unlocked: { speed: 1.03, pitch: 0 },
  library_entered: { speed: 0.98, pitch: -1 },
  library_occupied_seat_found: { speed: 1.02, pitch: 0 },
  cc98_occupation_post_opened: { speed: 1.06, pitch: 1 },
  library_catalog_match_found: { speed: 1.01, pitch: 0 },
  library_archived_rule_recovered: { speed: 0.96, pitch: -1 },
  photo_bag_report_generated: { speed: 1.02, pitch: 0 },
  library_bag_nonperson_proof_issued: { speed: 1.04, pitch: 1 },
  library_seat_receipt_recovered: { speed: 1.05, pitch: 1 },
  tiyi_presence_proof_issued: { speed: 0.99, pitch: 0 },
  cc98_top_ten_reached: { speed: 1.08, pitch: 2 },
  library_seat_release_pass_issued: { speed: 0.98, pitch: -1 },
  library_backpack_evicted: { speed: 1.04, pitch: 0 },
  library_friend_contacted: { speed: 0.92, pitch: -2 }
};

const MUSIC_TRACKS = [
  {
    asset: "music_library_room_v3",
    prompt: "Finals week inside a modern Chinese university library. Quiet air conditioning, distant page turns and fluorescent room tone translated into restrained pixel ambience, no melody lead, immediate start and seamless stable loop.",
    genre: "minimal library pixel ambient",
    mood: "quiet, focused, faintly procedural",
    instruments: "muted FM pad, paper ticks, soft clock pulse, distant scanner blip",
    bpm: 68
  },
  {
    asset: "music_library_arrival_v2",
    prompt: "University library arrival at opening time. Quiet fluorescent room tone translated into pixel music, sparse clock pulse, short walking rhythm, immediate start, stable loop.",
    genre: "minimal campus chiptune",
    mood: "quiet, observant, slightly procedural",
    instruments: "soft clock tick, muted FM keys, dry footstep percussion, glassy pluck",
    bpm: 74
  },
  {
    asset: "music_library_evidence_v2",
    prompt: "The same university library during an evidence search. Tighter ticking rhythm, catalog scan pulses and restrained tension, clear space for dialogue, immediate stable loop.",
    genre: "pixel investigation electronica",
    mood: "focused, curious, restrained",
    instruments: "catalog scanner blips, muted bass pulse, paper clicks, short square-wave arpeggio",
    bpm: 96
  },
  {
    asset: "music_cc98_publicity_v2",
    prompt: "A campus forum evidence thread gains attention. Fast keyboard rhythm, compact notification hits and three short ascending rank motifs, immediate start and readable loop.",
    genre: "campus forum arcade chiptune",
    mood: "busy, comic, competitive",
    instruments: "keyboard taps, square-wave lead, notification pings, compact electronic drums",
    bpm: 116
  },
  {
    asset: "music_library_enforcement_v2",
    prompt: "The same library enters administrative enforcement mode. Firm stamp rhythm, low mechanical pulse, controlled rising accents for a seat-release pass, immediate loop.",
    genre: "procedural glitch chiptune",
    mood: "decisive, dry, controlled",
    instruments: "rubber stamp hit, low FM pulse, clipped snare, short confirmation bells",
    bpm: 104
  },
  {
    asset: "music_library_022_reveal_v2",
    prompt: "The same library after seat 022 is cleared, revealing a strange hidden contact and a missing attendance record. Sparse detuned bells, quiet pulse, unresolved final motif, immediate loop.",
    genre: "mysterious pixel ambient",
    mood: "uncertain, intimate, unresolved",
    instruments: "detuned music box, low square-wave pulse, soft reversed bell, distant clock",
    bpm: 66
  }
];

const SFX_GROUPS = [
  {
    id: "arrival",
    prompt: "Four isolated pixel game cues separated by silence. Library entrance gate scan; compact arrival record print; backpack discovery alert; paper note pickup.",
    cuts: [
      { asset: "fx_library_gate_scan_v2", start: 0, duration: 0.9 },
      { asset: "fx_arrival_record_v2", start: 4, duration: 0.9 },
      { asset: "fx_backpack_alert_v2", start: 8, duration: 1.0 },
      { asset: "fx_note_pickup_v2", start: 12, duration: 0.8 }
    ]
  },
  {
    id: "catalog",
    prompt: "Four isolated pixel game cues separated by silence. Catalog search scan; wrong book rejection; correct book confirmation; heavy bookshelf sliding one grid cell.",
    cuts: [
      { asset: "fx_catalog_search_v2", start: 0, duration: 1.0 },
      { asset: "fx_catalog_wrong_v2", start: 4, duration: 0.8 },
      { asset: "fx_catalog_correct_v2", start: 8, duration: 1.0 },
      { asset: "fx_shelf_slide_v2", start: 12, duration: 1.5 }
    ]
  },
  {
    id: "proofs",
    prompt: "Four isolated pixel game cues separated by silence. Photo glare fading; report printer; firm official stamp; narrow paper receipt sliding from a desk gap.",
    cuts: [
      { asset: "fx_photo_glare_clear_v2", start: 0, duration: 1.0 },
      { asset: "fx_report_print_v2", start: 4, duration: 1.3 },
      { asset: "fx_nonperson_stamp_v2", start: 8, duration: 1.0 },
      { asset: "fx_receipt_slide_v2", start: 12, duration: 1.1 }
    ]
  },
  {
    id: "resolution",
    prompt: "Four isolated pixel game cues separated by silence. Evidence upload; seat-release pass stamp; backpack transfer sweep; quiet seat sit followed by a strange signal ping.",
    cuts: [
      { asset: "fx_evidence_upload_v2", start: 0, duration: 0.9 },
      { asset: "fx_pass_stamp_v2", start: 4, duration: 1.1 },
      { asset: "fx_backpack_transfer_v2", start: 8, duration: 1.4 },
      { asset: "fx_022_signal_v2", start: 12, duration: 1.3 }
    ]
  }
];

function findMmx() {
  const candidates = [
    process.env.MMX_BIN,
    join(homedir(), ".hermes/node/bin/mmx"),
    "/opt/homebrew/bin/mmx",
    "/usr/local/bin/mmx"
  ].filter(Boolean);
  const candidate = candidates.find((path) => existsSync(path));
  if (!candidate) {
    throw new Error("MiniMax CLI 未找到。可通过 MMX_BIN 指定可执行文件。");
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
    const message = (result.stderr || result.stdout || "unknown error").trim().slice(0, 1200);
    throw new Error(`${label}失败：${message}`);
  }
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
      if (!retryable || attempt === 4) {
        throw error;
      }
      process.stderr.write(`${label}网络请求未完成，重试 ${attempt}/3\n`);
      Atomics.wait(new Int32Array(new SharedArrayBuffer(4)), 0, 0, attempt * 1200);
    }
  }
  throw lastError;
}

function probeAudio(path) {
  const result = spawnSync(
    "ffprobe",
    [
      "-v",
      "error",
      "-show_entries",
      "format=duration:stream=codec_name,codec_type,sample_rate,channels",
      "-of",
      "json",
      path
    ],
    { encoding: "utf8" }
  );
  if (result.status !== 0) {
    throw new Error(`ffprobe 无法读取 ${path}：${(result.stderr || result.stdout).trim()}`);
  }
  let probe;
  try {
    probe = JSON.parse(result.stdout);
  } catch {
    throw new Error(`ffprobe 返回了无效 JSON：${path}`);
  }
  const stream = probe.streams?.find((candidate) => candidate.codec_type === "audio");
  const durationSeconds = Number.parseFloat(probe.format?.duration);
  if (!stream || !Number.isFinite(durationSeconds)) {
    throw new Error(`音频缺少可读的音轨或时长：${path}`);
  }
  return {
    codec: stream.codec_name,
    sampleRate: Number.parseInt(stream.sample_rate, 10),
    channels: stream.channels,
    durationSeconds,
    durationMs: Math.round(durationSeconds * 1000)
  };
}

function meanVolumeDb(path) {
  const result = spawnSync(
    "ffmpeg",
    ["-hide_banner", "-nostats", "-i", path, "-af", "volumedetect", "-f", "null", "-"],
    { encoding: "utf8", maxBuffer: 16 * 1024 * 1024 }
  );
  if (result.status !== 0) {
    throw new Error(`ffmpeg 无法检测响度 ${path}：${(result.stderr || result.stdout).trim().slice(-1200)}`);
  }
  const match = `${result.stderr}\n${result.stdout}`.match(/mean_volume:\s*(-?[\d.]+) dB/);
  const value = Number.parseFloat(match?.[1] ?? "NaN");
  if (!Number.isFinite(value)) {
    throw new Error(`音频没有可测量的非静音响度：${path}`);
  }
  return value;
}

function validateMusic(path) {
  const probe = probeAudio(path);
  if (probe.codec !== "mp3") {
    throw new Error(`配乐 codec 必须为 mp3，实际为 ${probe.codec}：${path}`);
  }
  if (probe.durationSeconds < MUSIC_MIN_DURATION_SECONDS) {
    throw new Error(
      `配乐时长必须至少 ${MUSIC_MIN_DURATION_SECONDS}s，实际为 ${probe.durationSeconds.toFixed(3)}s：${path}`
    );
  }
  const measuredMeanVolumeDb = meanVolumeDb(path);
  if (measuredMeanVolumeDb <= MIN_AUDIBLE_MEAN_DB) {
    throw new Error(`配乐响度过低：${measuredMeanVolumeDb.toFixed(1)} dB：${path}`);
  }
  return { ...probe, meanVolumeDb: measuredMeanVolumeDb };
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
    `旁白母带处理 ${output}`
  );
}

function normalizeBed(input, output, durationSeconds, loudness) {
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
      `loudnorm=I=${loudness}:TP=-1.5:LRA=8,afade=t=in:st=0:d=0.08,afade=t=out:st=${Math.max(0, durationSeconds - 0.18)}:d=0.18`,
      "-ar",
      "44100",
      "-ac",
      "2",
      "-b:a",
      "192k",
      output
    ],
    `配乐或音效母带处理 ${output}`
  );
}

function durationMs(path) {
  const result = spawnSync(
    "ffprobe",
    ["-v", "error", "-show_entries", "format=duration", "-of", "default=noprint_wrappers=1:nokey=1", path],
    { encoding: "utf8" }
  );
  const seconds = Number.parseFloat(result.stdout.trim());
  return Number.isFinite(seconds) ? Math.round(seconds * 1000) : null;
}

function hash(text) {
  return createHash("sha256").update(text).digest("hex").slice(0, 12);
}

function relativeAssetPath(path) {
  return relative(join(root, "src/assets/audio"), path).replaceAll("\\", "/");
}

function generateVoice(key, line) {
  const asset = `vo_${key}`;
  const output = join(voiceDir, `${asset}.mp3`);
  const profile = VOICE_PROFILES[key] ?? { speed: 1, pitch: 0 };
  const sourceTextHash = hash(line.text);
  const sourceProfileHash = hash(JSON.stringify({ voice: VOICE_ID, language: VOICE_LANGUAGE, delivery: line.delivery, ...profile }));
  const previous = previousGenerated.assets?.[asset];
  if (
    !force &&
    existsSync(output) &&
    previous?.sourceTextHash === sourceTextHash &&
    previous?.sourceProfileHash === sourceProfileHash
  ) {
    return { asset, output, sourceTextHash, sourceProfileHash, generated: false };
  }
  const raw = join(tempDir, `${asset}.raw.mp3`);
  runMmx(
    [
      "speech",
      "synthesize",
      "--model",
      "speech-2.8-hd",
      "--voice",
      VOICE_ID,
      "--language",
      VOICE_LANGUAGE,
      "--speed",
      String(profile.speed),
      "--volume",
      "1",
      "--pitch",
      String(profile.pitch),
      "--sample-rate",
      "32000",
      "--bitrate",
      "128000",
      "--channels",
      "1",
      "--text",
      line.text,
      "--out",
      raw
    ],
    `MiniMax 旁白 ${key}`
  );
  normalizeVoice(raw, output);
  return { asset, output, sourceTextHash, sourceProfileHash, generated: true };
}

function generateMusic(track) {
  const output = join(musicDir, `${track.asset}.mp3`);
  if (!force && existsSync(output)) {
    try {
      return { asset: track.asset, output, verification: validateMusic(output) };
    } catch (error) {
      process.stderr.write(`${track.asset} 现有文件无效，将重新生成：${error.message}\n`);
    }
  }
  const raw = join(tempDir, `${track.asset}.raw.mp3`);
  const normalized = join(tempDir, `${track.asset}.normalized.mp3`);
  let rawValidationError;
  for (let attempt = 1; attempt <= 3; attempt += 1) {
    rmSync(raw, { force: true });
    runMmx(
      [
        "music",
        "generate",
        "--model",
        MUSIC_MODEL,
        "--prompt",
        track.prompt,
        "--genre",
        track.genre,
        "--mood",
        track.mood,
        "--instruments",
        track.instruments,
        "--bpm",
        String(track.bpm),
        "--avoid",
        "vocals, cinematic orchestra, heavy bass, long intro, long outro, emotional climax",
        "--use-case",
        "looping background music for a mobile puzzle game",
        "--structure",
        "steady loop with small variations",
        "--instrumental",
        "--out",
        raw
      ],
      `MiniMax 分阶段配乐 ${track.asset}`
    );
    try {
      validateMusic(raw);
      rawValidationError = null;
      break;
    } catch (error) {
      rawValidationError = error;
      if (attempt < 3) {
        process.stderr.write(`${track.asset} MiniMax 产物无效，重试 ${attempt}/2：${error.message}\n`);
      }
    }
  }
  if (rawValidationError) {
    throw new Error(`${track.asset} 连续三次生成无效：${rawValidationError.message}`);
  }
  normalizeBed(raw, normalized, MUSIC_DURATION_SECONDS, -24);
  const verification = validateMusic(normalized);
  copyFileSync(normalized, output);
  return { asset: track.asset, output, verification };
}

function cutSfx(stem, cut) {
  const output = join(sfxDir, `${cut.asset}.mp3`);
  if (!force && existsSync(output)) {
    return { asset: cut.asset, output };
  }
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
      String(cut.start),
      "-t",
      String(cut.duration),
      "-af",
      `loudnorm=I=-18:TP=-1.5:LRA=6,afade=t=in:st=0:d=0.02,afade=t=out:st=${Math.max(0, cut.duration - 0.08)}:d=0.08`,
      "-ar",
      "44100",
      "-ac",
      "2",
      "-b:a",
      "160k",
      output
    ],
    `音效切分 ${cut.asset}`
  );
  return { asset: cut.asset, output };
}

function generateSfxGroup(group) {
  const outputs = group.cuts.map((cut) => join(sfxDir, `${cut.asset}.mp3`));
  if (!force && outputs.every((path) => existsSync(path))) {
    return group.cuts.map((cut, index) => ({ asset: cut.asset, output: outputs[index] }));
  }
  const raw = join(tempDir, `library_finals_${group.id}.raw.mp3`);
  const normalized = join(tempDir, `library_finals_${group.id}.normalized.mp3`);
  runMmx(
    [
      "music",
      "generate",
      "--prompt",
      `${group.prompt} No continuous melody or ambience.`,
      "--genre",
      "game sound effects",
      "--mood",
      "dry, comic, concise",
      "--instruments",
      "digital UI tones, bicycle bell, short noise sweep, keyboard clicks",
      "--avoid",
      "vocals, song structure, sustained pads, continuous beat, long reverb",
      "--use-case",
      "isolated one-shot sound effects for a mobile puzzle game",
      "--structure",
      "four short cues with silence between cues",
      "--instrumental",
      "--out",
      raw
    ],
    `MiniMax 图书馆期末周音效干轨 ${group.id}`
  );
  normalizeBed(raw, normalized, 16, -18);
  return group.cuts.map((cut) => cutSfx(normalized, cut));
}

function generateSfxSet() {
  return SFX_GROUPS.flatMap((group) => generateSfxGroup(group));
}

function musicManifestEntry(music) {
  return {
    path: relativeAssetPath(music.output),
    durationMs: music.verification.durationMs,
    source: `MiniMax ${MUSIC_MODEL}`
  };
}

function writeGeneratedManifest(assets, generated = Object.keys(assets)) {
  writeFileSync(
    generatedPath,
    `${JSON.stringify({ generatedAt: new Date().toISOString(), assets }, null, 2)}\n`,
    "utf8"
  );
  process.stdout.write(`${JSON.stringify({ generated, manifest: generatedPath }, null, 2)}\n`);
}

function verifyExistingAssets() {
  const definitions = [
    ...MUSIC_TRACKS.map((track) => ({
      asset: track.asset,
      output: join(musicDir, `${track.asset}.mp3`),
      kind: "music"
    })),
    ...SFX_GROUPS.flatMap((group) => group.cuts.map((cut) => ({
      asset: cut.asset,
      output: join(sfxDir, `${cut.asset}.mp3`),
      kind: "sfx"
    })))
  ];

  const verified = definitions.map((definition) => {
    if (!existsSync(definition.output)) {
      throw new Error(`缺少音频文件：${definition.output}`);
    }
    const probe = definition.kind === "music" ? validateMusic(definition.output) : probeAudio(definition.output);
    if (probe.codec !== "mp3" || probe.durationMs <= 0) {
      throw new Error(`音频必须为可解码 MP3：${definition.output}`);
    }
    return {
      asset: definition.asset,
      path: relativeAssetPath(definition.output),
      durationMs: probe.durationMs,
      codec: probe.codec
    };
  });

  process.stdout.write(`${JSON.stringify({ generated: [], verified, manifest: generatedPath }, null, 2)}\n`);
}

try {
  if (verifyOnly) {
    if (force || voiceOnly || mediaOnly || requestedAsset) {
      throw new Error("--verify-only 不能与生成参数同时使用。");
    }
    verifyExistingAssets();
  } else if (requestedAsset) {
    if (voiceOnly || mediaOnly) {
      throw new Error("--asset 不能与 --voice-only 或 --media-only 同时使用。");
    }
    const track = MUSIC_TRACKS.find((candidate) => candidate.asset === requestedAsset);
    if (!track) {
      throw new Error(`--asset 仅支持已配置的配乐资产：${requestedAsset}`);
    }
    const music = generateMusic(track);
    const assets = { ...(previousGenerated.assets ?? {}) };
    assets[music.asset] = musicManifestEntry(music);
    writeGeneratedManifest(assets, [music.asset]);
  } else {
    const assets = voiceOnly
      ? Object.fromEntries(
          Object.entries(previousGenerated.assets ?? {}).filter(([asset]) => !asset.startsWith("vo_"))
        )
      : {};
    const generatedVoiceAssets = [];

    if (!voiceOnly) {
      for (const track of MUSIC_TRACKS) {
        const music = generateMusic(track);
        assets[music.asset] = musicManifestEntry(music);
      }
      for (const sfx of generateSfxSet()) {
        assets[sfx.asset] = {
          path: relativeAssetPath(sfx.output),
          durationMs: durationMs(sfx.output),
          source: "MiniMax music-2.5 sound-design cut"
        };
      }
      rmSync(join(musicDir, "library_finals_music_master.mp3"), { force: true });
      rmSync(join(sfxDir, "library_finals_sfx_stem.mp3"), { force: true });
    }

    writeGeneratedManifest(assets, voiceOnly ? generatedVoiceAssets : Object.keys(assets));
  }
} finally {
  rmSync(tempDir, { recursive: true, force: true });
}
