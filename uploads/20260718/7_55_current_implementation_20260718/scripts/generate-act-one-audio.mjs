import { createHash } from "node:crypto";
import { existsSync, mkdirSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { homedir, tmpdir } from "node:os";
import { dirname, join, relative, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { spawnSync } from "node:child_process";

const root = resolve(dirname(fileURLToPath(import.meta.url)), "..");
const contentPath = join(root, "src/data/act-one-bootstrap.content.json");
const dialoguePath = join(root, "src/data/dialogue.lines.json");
const voMapPath = join(root, "src/data/vo.map.json");
const generatedPath = join(root, "src/data/act-one.audio.generated.json");
const voiceDir = join(root, "src/assets/audio/act-one/vo");
const legacyVoiceDir = join(root, "src/assets/audio/vo");
const sfxDir = join(root, "src/assets/audio/act-one/sfx");
const musicDir = join(root, "src/assets/audio/act-one/music");
const force = process.argv.includes("--force");
const voiceOnly = process.argv.includes("--voice-only");
const sfxOnly = process.argv.includes("--sfx-only");
const content = JSON.parse(readFileSync(contentPath, "utf8"));
const dialogueLines = JSON.parse(readFileSync(dialoguePath, "utf8"));
const voMap = JSON.parse(readFileSync(voMapPath, "utf8"));
const previous = existsSync(generatedPath) ? JSON.parse(readFileSync(generatedPath, "utf8")) : { assets: {} };
const tempDir = mkdtempSync(join(tmpdir(), "seven-fifty-five-act-one-audio-"));
const CHAPTER_ONE_VOICE = content.voices.chapterOne;
const PROLOGUE_NARRATOR_VOICE = content.voices.prologueNarrator;
const CHAPTER_TWO_VOICE = content.voices.chapterTwo;
const NARRATOR_BASE_PITCH = -4;

const VOICE_PROFILES = {
  act1_locked_entry: { speed: 1.04, pitch: -1 },
  act1_identity_verified: { speed: 1.08, pitch: 0 },
  act1_phone_linked: { speed: 1.06, pitch: 0 },
  act1_controls_installed: { speed: 1.1, pitch: 1 },
  act1_movement_enabled: { speed: 1.05, pitch: 0 },
  act1_required_item_collected: { speed: 1.08, pitch: 0 },
  act1_map_completed: { speed: 1.02, pitch: -1 },
  prologue_narrator_intro: { speed: 0.92, pitch: NARRATOR_BASE_PITCH },
  prologue_narrator_caught: { speed: 1.13, pitch: NARRATOR_BASE_PITCH },
  prologue_narrator_bargain: { speed: 0.94, pitch: NARRATOR_BASE_PITCH },
  act2_system_found_intro: { speed: 0.95, pitch: -1 },
  act2_system_inventory_demand: { speed: 0.98, pitch: -2 },
  act2_system_inventory_missing: { speed: 1.1, pitch: 1 },
  act2_system_just_find_it: { speed: 0.82, pitch: -2 },
  act2_system_departure: { speed: 1.04, pitch: 0 },
  act2_system_confession: { speed: 0.9, pitch: -2 },
  act2_system_friend: { speed: 0.94, pitch: -1 },
  act2_system_library: { speed: 1, pitch: 0 },
  act2_system_move_now: { speed: 1.11, pitch: 1 },
  act2_character_cannot_hear: { speed: 1, pitch: -1 },
  act2_character_named: { speed: 1.01, pitch: 0 },
  act2_exercise_started: { speed: 1.04, pitch: 1 },
  act2_push_triangle_collected: { speed: 1.05, pitch: 1 },
  act2_weather_water_collected: { speed: 0.98, pitch: 0 },
  act2_mentor_line_stuck: { speed: 0.97, pitch: -1 },
  act2_mentor_line_released: { speed: 1.03, pitch: 1 },
  act2_right_arrow_assembled: { speed: 1, pitch: 0 },
  act2_balance_shifted: { speed: 1.04, pitch: 1 },
  act2_gamepad_purchase_rejected: { speed: 1.06, pitch: 0 },
  act2_gamepad_purchased: { speed: 1.04, pitch: 0 },
  act2_exit_ready: { speed: 0.9, pitch: -1 }
};

const LEGACY_VOICE_PROFILES = {
  wake_narration: { speed: 0.9, pitch: NARRATOR_BASE_PITCH },
  wake_flash: { speed: 1.12, pitch: 1 },
  xy_attack: { speed: 1.07, pitch: 0 },
  xy_laugh: { speed: 0.94, pitch: -1 },
  sys_balance: { speed: 0.9, pitch: -2 },
  sys_net_try: { speed: 0.88, pitch: -2 },
  sys_no_money: { speed: 0.96, pitch: -1 },
  tiyi_47: { speed: 0.86, pitch: -2 },
  gear_pickup: { speed: 0.9, pitch: -1 }
};

// Only story dialogue is voiced. Operation feedback remains authored in the
// content files for subtitles, but the generator must never recreate it.
const STORY_VOICE_KEYS = new Set([
  "prologue_narrator_intro",
  "prologue_narrator_caught",
  "prologue_narrator_bargain",
  "act2_system_found_intro",
  "act2_system_inventory_demand",
  "act2_system_inventory_missing",
  "act2_system_just_find_it",
  "act2_system_departure",
  "act2_system_confession",
  "act2_system_friend",
  "act2_system_library",
  "act2_system_move_now"
]);

const LEGACY_STORY_VOICE_KEYS = new Set([
  "wake_narration",
  "wake_flash",
  "xy_attack",
  "xy_laugh"
]);

const RETAINED_VOICE_ASSETS = new Set([
  ...[...STORY_VOICE_KEYS].map((key) => `vo_${key}`),
  ...[...LEGACY_STORY_VOICE_KEYS].map((key) => `vo_legacy_${key}`)
]);

const SFX_CUTS = [
  { asset: "fx_act1_login_stamp", start: 0, duration: 0.9 },
  { asset: "fx_act1_phone_link", start: 3, duration: 1.05 },
  { asset: "fx_act1_controls_install", start: 6, duration: 1.0 },
  { asset: "fx_act1_movement_unlock", start: 9, duration: 1.1 },
  { asset: "fx_act1_cartridge_pickup", start: 12, duration: 1.0 },
  { asset: "fx_act1_map_complete", start: 15, duration: 1.35 },
  { asset: "fx_narrator_circle_appear", start: 18, duration: 1.15 },
  { asset: "fx_narrator_grab", start: 21, duration: 0.9 },
  { asset: "fx_narrator_white_burst", start: 24, duration: 1.1 },
  { asset: "fx_friend_reply_send", start: 27, duration: 0.65 },
  { asset: "fx_system_emerge", start: 30, duration: 1.0 },
  { asset: "fx_inventory_chest_open", start: 33, duration: 1.25 },
  { asset: "fx_act2_quest_update", start: 36, duration: 0.9 }
];

const MOVEMENT_SFX_CUTS = [
  { asset: "fx_character_name_lock", start: 0, duration: 1.0 },
  { asset: "fx_exercise_pacing_start", start: 3, duration: 1.2 },
  { asset: "fx_triangle_pickup", start: 6, duration: 0.8 },
  { asset: "fx_weather_drop_pickup", start: 9, duration: 0.9 },
  { asset: "fx_adhesive_release", start: 12, duration: 1.1 },
  { asset: "fx_right_arrow_assemble", start: 15, duration: 1.0 },
  { asset: "fx_balance_decimal_shift", start: 18, duration: 1.25 },
  { asset: "fx_gamepad_purchase", start: 21, duration: 1.1 },
  { asset: "fx_manual_control_ready", start: 24, duration: 1.0 }
];

const MUSIC_TRACKS = [
  {
    asset: "music_dorm_room_v3",
    prompt: "Rainy early morning inside a lived-in Chinese university dorm. Quiet ceiling fan rotation, window rain and fluorescent room tone translated into restrained pixel ambience. Immediate start, stable loop, broad empty space for dialogue and movement sounds.",
    genre: "minimal campus pixel ambient",
    mood: "sleepy, practical, lightly tense",
    instruments: "soft fan pulse, rain ticks, muted FM keys, low square-wave room tone",
    bpm: 64
  },
  {
    asset: "music_prologue_blackout",
    prompt: "Seven-second black screen after a failed university check-in. Sparse low digital pulse, long silence gaps, immediate start, restrained tension.",
    genre: "minimal glitch chiptune",
    mood: "uncertain, dry, restrained",
    instruments: "low square-wave pulse, muted clock tick, distant digital noise",
    bpm: 58
  },
  {
    asset: "music_narrator_chase",
    prompt: "A sarcastic red interface circle tries to leave the screen. Quick uneven pixel steps, short comic stabs, clear empty space for speech, immediate start.",
    genre: "comic arcade chiptune",
    mood: "evasive, sarcastic, brisk",
    instruments: "short square-wave plucks, dry electronic taps, tiny descending whistle synth",
    bpm: 126
  },
  {
    asset: "music_act2_search",
    prompt: "Exploring a university phone interface to locate a hidden system. Sparse notification ticks and curious clipped synth notes, stable quiet loop.",
    genre: "pixel puzzle electronica",
    mood: "curious, procedural, lightly comic",
    instruments: "muted FM pluck, keyboard ticks, soft square-wave bass",
    bpm: 88
  },
  {
    asset: "music_act2_movement_puzzle",
    prompt: "Assembling an absurd movement permission chain across campus apps. Alternating footstep rhythm, clipped menu tones and a playful unresolved pulse, stable loop.",
    genre: "campus puzzle chiptune",
    mood: "busy, playful, unresolved",
    instruments: "pixel footsteps, woodblock, square-wave arpeggio, dry UI clicks",
    bpm: 112
  },
  {
    asset: "music_act2_manual_control",
    prompt: "A second-hand gamepad finally gives manual control. Clear directional rhythm, compact upbeat bass and short confirmation notes, stable loop with no climax.",
    genre: "light arcade chiptune",
    mood: "controlled, active, concise",
    instruments: "8-bit bass, dry electronic drums, four-note square-wave motif",
    bpm: 124
  }
];

mkdirSync(voiceDir, { recursive: true });
mkdirSync(legacyVoiceDir, { recursive: true });
mkdirSync(sfxDir, { recursive: true });
mkdirSync(musicDir, { recursive: true });

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

function normalizeVoice(input, output) {
  run(
    "ffmpeg",
    [
      "-y", "-hide_banner", "-loglevel", "error", "-i", input,
      "-af",
      "silenceremove=start_periods=1:start_duration=0.04:start_threshold=-48dB,areverse,silenceremove=start_periods=1:start_duration=0.08:start_threshold=-48dB,areverse,loudnorm=I=-16:TP=-1.5:LRA=7",
      "-ar", "32000", "-ac", "1", "-b:a", "128k", output
    ],
    `第一章旁白母带处理 ${output}`
  );
}

function normalizeStem(input, output) {
  run(
    "ffmpeg",
    [
      "-y", "-hide_banner", "-loglevel", "error", "-i", input, "-t", "40",
      "-af", "loudnorm=I=-18:TP=-1.5:LRA=6,afade=t=in:st=0:d=0.02,afade=t=out:st=39.8:d=0.2",
      "-ar", "44100", "-ac", "2", "-b:a", "160k", output
    ],
    "第一章音效干轨母带处理"
  );
}

function normalizeBed(input, output, duration, loudness = -24) {
  run(
    "ffmpeg",
    [
      "-y", "-hide_banner", "-loglevel", "error", "-i", input, "-t", String(duration),
      "-af", `loudnorm=I=${loudness}:TP=-1.5:LRA=7,afade=t=in:st=0:d=0.08,afade=t=out:st=${Math.max(0, duration - 0.25)}:d=0.25`,
      "-ar", "44100", "-ac", "2", "-b:a", "160k", output
    ],
    `第一、二章音频母带处理 ${output}`
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

function assetPath(path) {
  return relative(join(root, "src/assets/audio"), path).replaceAll("\\", "/");
}

function voiceForKey(key) {
  if (key.startsWith("prologue_")) {
    return PROLOGUE_NARRATOR_VOICE;
  }
  return key.startsWith("act2_") ? CHAPTER_TWO_VOICE : CHAPTER_ONE_VOICE;
}

function generateVoiceTake(text, profile, output, label) {
  runMmx(
    [
      "speech", "synthesize", "--model", "speech-2.8-hd", "--voice", label.voice.id,
      "--language", label.voice.language, "--speed", String(profile.speed), "--volume", "1",
      "--pitch", String(profile.pitch), "--sample-rate", "32000", "--bitrate", "128000",
      "--channels", "1", "--text", text, "--out", output
    ],
    label.text
  );
}

function generateVoice(key, line) {
  const asset = `vo_${key}`;
  const output = join(voiceDir, `${asset}.mp3`);
  const profile = VOICE_PROFILES[key] ?? { speed: 1, pitch: 0 };
  const voice = voiceForKey(key);
  const textHash = hash(line.text);
  const profileHash = hash(JSON.stringify({ voice: voice.id, language: voice.language, delivery: line.delivery, segments: line.segments, ...profile }));
  const cached = previous.assets?.[asset];
  if (!force && existsSync(output) && cached?.sourceTextHash === textHash && cached?.sourceProfileHash === profileHash) {
    return { asset, output, textHash, profileHash, voice, generated: false };
  }
  const raw = join(tempDir, `${asset}.raw.mp3`);
  const chapterLabel = key.startsWith("prologue_")
    ? "序章英式男声"
    : key.startsWith("act2_")
      ? "第二章英文"
      : "第一章英文";
  if (Array.isArray(line.segments) && line.segments.length > 0) {
    const segmentPaths = line.segments.map((segment, index) => {
      const segmentOutput = join(tempDir, `${asset}.segment-${index + 1}.mp3`);
      generateVoiceTake(segment.text, segment.profile ?? profile, segmentOutput, {
        voice,
        text: `MiniMax ${chapterLabel}旁白 ${key} 分段 ${index + 1}`
      });
      return segmentOutput;
    });
    const concatList = join(tempDir, `${asset}.concat.txt`);
    writeFileSync(concatList, `${segmentPaths.map((path) => `file '${path}'`).join("\n")}\n`, "utf8");
    run(
      "ffmpeg",
      ["-y", "-hide_banner", "-loglevel", "error", "-f", "concat", "-safe", "0", "-i", concatList, "-c:a", "copy", raw],
      `${chapterLabel}旁白分段合并 ${key}`
    );
  } else {
    generateVoiceTake(line.text, profile, raw, {
      voice,
      text: `MiniMax ${chapterLabel}旁白 ${key}`
    });
  }
  normalizeVoice(raw, output);
  return { asset, output, textHash, profileHash, voice, generated: true };
}

function generateLegacyVoice(line) {
  const key = line.voice_key;
  const suffix = voMap.files?.[key];
  if (!key || !suffix || !line.voice_text_en) {
    throw new Error(`旧版配音缺少 voice_key、文件映射或英文文本：${line.line_id ?? "unknown"}`);
  }
  const asset = `vo_legacy_${key}`;
  const output = join(legacyVoiceDir, `all_shadow_vo_${suffix}.mp3`);
  const profile = LEGACY_VOICE_PROFILES[key] ?? { speed: 1, pitch: 0 };
  const voice = line.speaker === "narrator" ? PROLOGUE_NARRATOR_VOICE : CHAPTER_ONE_VOICE;
  const textHash = hash(line.voice_text_en);
  const profileHash = hash(JSON.stringify({ voice: voice.id, language: voice.language, delivery: line.delivery, ...profile }));
  const cached = previous.assets?.[asset];
  if (!force && existsSync(output) && cached?.sourceTextHash === textHash && cached?.sourceProfileHash === profileHash) {
    return { asset, output, textHash, profileHash, voice, generated: false };
  }
  const raw = join(tempDir, `${asset}.raw.mp3`);
  generateVoiceTake(line.voice_text_en, profile, raw, {
    voice,
    text: `MiniMax 第一章旧场景英文配音 ${key}`
  });
  normalizeVoice(raw, output);
  return { asset, output, textHash, profileHash, voice, generated: true };
}

function generateSfx() {
  const outputs = SFX_CUTS.map((cut) => join(sfxDir, `${cut.asset}.mp3`));
  if (!force && outputs.every((path) => existsSync(path))) {
    return SFX_CUTS.map((cut, index) => ({ asset: cut.asset, output: outputs[index] }));
  }
  const raw = join(tempDir, "act_one_sfx.raw.mp3");
  const normalized = join(tempDir, "act_one_sfx.normalized.mp3");
  runMmx(
    [
      "music", "generate",
      "--prompt",
      "Thirteen isolated pixel game cues separated by clear silence: login stamp; phone data handshake; four directional keys snapping into place; two quick sneaker steps; cartridge pickup sparkle; compact map-complete fanfare; red narrator orb materializing; hand grabbing a moving UI object; three sharp white flash impacts; short chat-message send; system orb extracting from an app icon; wooden treasure chest opening with card sparkle; concise quest-update chime. No continuous melody.",
      "--genre", "game sound effects", "--mood", "dry, sarcastic, concise",
      "--instruments", "digital UI clicks, rubber stamp, short modem chirp, pixel footsteps, square-wave sparkle",
      "--avoid", "vocals, sustained pads, continuous beat, long reverb, song structure",
      "--use-case", "isolated one-shot sound effects for a campus RPG", "--structure", "six short cues with silence between cues",
      "--instrumental", "--out", raw
    ],
    "MiniMax 第一章音效干轨"
  );
  normalizeStem(raw, normalized);
  return SFX_CUTS.map((cut) => {
    const output = join(sfxDir, `${cut.asset}.mp3`);
    run(
      "ffmpeg",
      [
        "-y", "-hide_banner", "-loglevel", "error", "-i", normalized,
        "-ss", String(cut.start), "-t", String(cut.duration),
        "-af", `afade=t=in:st=0:d=0.02,afade=t=out:st=${Math.max(0, cut.duration - 0.08)}:d=0.08`,
        "-ar", "44100", "-ac", "2", "-b:a", "160k", output
      ],
      `第一章音效切分 ${cut.asset}`
    );
    return { asset: cut.asset, output };
  });
}

function generateMovementSfx() {
  const outputs = MOVEMENT_SFX_CUTS.map((cut) => join(sfxDir, `${cut.asset}.mp3`));
  if (!force && outputs.every((path) => existsSync(path))) {
    return MOVEMENT_SFX_CUTS.map((cut, index) => ({ asset: cut.asset, output: outputs[index] }));
  }
  const raw = join(tempDir, "act_two_movement_sfx.raw.mp3");
  const normalized = join(tempDir, "act_two_movement_sfx.normalized.mp3");
  runMmx(
    [
      "music", "generate",
      "--prompt",
      "Nine isolated non-musical pixel game cues separated by clear silence: campus identity name locks in; sneaker pacing begins; triangular notification icon pops free; single clean rain drop collected; sticky vertical line slides loose; triangle and line snap into a right arrow; decimal point shifts right two places with coin ticks; second-hand gamepad purchase confirmation; four directional inputs unlock a dorm exit. No continuous melody.",
      "--genre", "game sound effects", "--mood", "dry, comic, concise",
      "--instruments", "digital UI clicks, short footsteps, single water drop, adhesive peel, coin tick, square-wave confirmation",
      "--avoid", "vocals, sustained pads, continuous beat, long reverb, song structure",
      "--use-case", "isolated one-shot sound effects for a mobile campus puzzle game",
      "--structure", "nine short cues with silence between cues",
      "--instrumental", "--out", raw
    ],
    "MiniMax 第二章移动谜题音效干轨"
  );
  normalizeBed(raw, normalized, 28, -18);
  return MOVEMENT_SFX_CUTS.map((cut) => {
    const output = join(sfxDir, `${cut.asset}.mp3`);
    run(
      "ffmpeg",
      [
        "-y", "-hide_banner", "-loglevel", "error", "-i", normalized,
        "-ss", String(cut.start), "-t", String(cut.duration),
        "-af", `afade=t=in:st=0:d=0.02,afade=t=out:st=${Math.max(0, cut.duration - 0.08)}:d=0.08`,
        "-ar", "44100", "-ac", "2", "-b:a", "160k", output
      ],
      `第二章移动谜题音效切分 ${cut.asset}`
    );
    return { asset: cut.asset, output };
  });
}

function generateMusic(track) {
  const output = join(musicDir, `${track.asset}.mp3`);
  if (!force && existsSync(output)) {
    return { asset: track.asset, output };
  }
  const raw = join(tempDir, `${track.asset}.raw.mp3`);
  runMmx(
    [
      "music", "generate", "--model", "music-2.5",
      "--prompt", track.prompt,
      "--genre", track.genre,
      "--mood", track.mood,
      "--instruments", track.instruments,
      "--bpm", String(track.bpm),
      "--avoid", "vocals, cinematic orchestra, heavy bass, long intro, long outro, emotional climax",
      "--use-case", "looping background music for a mobile puzzle game",
      "--structure", "steady 24 second loop with small variations",
      "--instrumental", "--out", raw
    ],
    `MiniMax 第一、二章分阶段配乐 ${track.asset}`
  );
  normalizeBed(raw, output, 24, -24);
  return { asset: track.asset, output };
}

try {
  const assets = Object.fromEntries(
    Object.entries(previous.assets ?? {}).filter(
      ([asset]) => !asset.startsWith("vo_") || RETAINED_VOICE_ASSETS.has(asset)
    )
  );
  const generatedVoiceAssets = [];
  if (!sfxOnly) {
    for (const [key, line] of Object.entries(content.audioNarration).filter(
      ([key]) => STORY_VOICE_KEYS.has(key)
    )) {
      const generated = generateVoice(key, line);
      assets[generated.asset] = {
        path: assetPath(generated.output),
        durationMs: durationMs(generated.output),
        sourceTextHash: generated.textHash,
        sourceProfileHash: generated.profileHash,
        source: `MiniMax speech-2.8-hd ${generated.voice.id}`
      };
      if (generated.generated) {
        generatedVoiceAssets.push(generated.asset);
      }
    }
    for (const line of dialogueLines.filter(({ voice_key }) => LEGACY_STORY_VOICE_KEYS.has(voice_key))) {
      const generated = generateLegacyVoice(line);
      assets[generated.asset] = {
        path: assetPath(generated.output),
        durationMs: durationMs(generated.output),
        sourceTextHash: generated.textHash,
        sourceProfileHash: generated.profileHash,
        source: `MiniMax speech-2.8-hd ${generated.voice.id}`
      };
      if (generated.generated) {
        generatedVoiceAssets.push(generated.asset);
      }
    }
  }
  if (!voiceOnly) {
    for (const generated of [...generateSfx(), ...generateMovementSfx()]) {
      assets[generated.asset] = {
        path: assetPath(generated.output),
        durationMs: durationMs(generated.output),
        source: "MiniMax music-2.5 sound-design cut"
      };
    }
    for (const generated of MUSIC_TRACKS.map(generateMusic)) {
      assets[generated.asset] = {
        path: assetPath(generated.output),
        durationMs: durationMs(generated.output),
        source: "MiniMax music-2.5"
      };
    }
  }
  writeFileSync(
    generatedPath,
    `${JSON.stringify({ version: 1, generatedAt: new Date().toISOString(), assets }, null, 2)}\n`,
    "utf8"
  );
  process.stdout.write(`${JSON.stringify({ generated: voiceOnly ? generatedVoiceAssets : Object.keys(assets), manifest: generatedPath }, null, 2)}\n`);
} finally {
  rmSync(tempDir, { recursive: true, force: true });
}
