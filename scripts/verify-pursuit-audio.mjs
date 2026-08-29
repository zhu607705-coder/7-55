#!/usr/bin/env node

import { createHash } from "node:crypto";
import { existsSync, readFileSync } from "node:fs";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { spawnSync } from "node:child_process";

const root = resolve(dirname(fileURLToPath(import.meta.url)), "..");
const readJson = (path) => JSON.parse(readFileSync(join(root, path), "utf8"));
const readText = (path) => readFileSync(join(root, path), "utf8");
const content = readJson("src/data/pursuit.audio.content.json");
const timeline = readJson("src/data/pursuit.audio.json");
const generated = readJson("src/data/pursuit.audio.generated.json");
const qizhenContent = readJson("src/data/chapter3-qizhen-lake.content.json");
const chapterFourContent = readJson("src/data/chapter4-755.content.json");
const audioDirectorSource = readText("src/modules/AudioDirector.ts");
const presentationDirectorSource = readText("src/modules/PresentationDirector.ts");
const qizhenSceneSource = readText("src/scenes/rpg/QizhenLakeScene.ts");
const chapterFourSceneSource = readText("src/scenes/rpg/ChapterFourTemporalMazeScene.ts");
const chapterFourTimeline = readJson("src/data/chapter4-755.audio.json");
let assertions = 0;

function assert(condition, message) {
  assertions += 1;
  if (!condition) throw new Error(message);
}

function sha256(path) {
  return createHash("sha256").update(readFileSync(path)).digest("hex");
}

function probe(path) {
  const result = spawnSync("ffprobe", [
    "-v", "error",
    "-select_streams", "a:0",
    "-show_entries", "stream=codec_name,codec_type,sample_rate,channels:format=duration",
    "-of", "json",
    path
  ], { cwd: root, encoding: "utf8" });
  if (result.status !== 0) throw new Error(`ffprobe failed for ${path}: ${result.stderr}`);
  const parsed = JSON.parse(result.stdout);
  return {
    stream: parsed.streams?.find(({ codec_type }) => codec_type === "audio"),
    durationMs: Math.round(Number(parsed.format?.duration) * 1000)
  };
}

assert(content.version === 1, "Pursuit audio content version must be 1.");
assert(content.chapterId === "cross-chapter-pursuit-audio", "Unexpected pursuit audio chapter id.");
assert(content.music.length === 1, "Pursuit bundle must define one black-swan music bed.");
assert(content.lines.length === 6, "Pursuit bundle must define six sparse voice lines.");
assert(generated.chapterId === content.chapterId, "Generated pursuit manifest must match the content catalog.");

const requiredEvents = [
  "rpg_qizhen_chase_started",
  "rpg_qizhen_chase_restarted",
  "qizhen_swan_chase_telegraph",
  "qizhen_swan_chase_telegraph_voice",
  "qizhen_swan_chase_surge",
  "qizhen_swan_chase_release",
  "qizhen_swan_chase_final_bank",
  "rpg_qizhen_chase_failed",
  "rpg_qizhen_escape_completed_requested",
  "final_chase_started",
  "final_chase_pressure_catch_up",
  "final_chase_pressure_tracking",
  "final_chase_pressure_close",
  "final_chase_close_voice",
  "final_chase_floor_changed"
];
for (const eventId of requiredEvents) {
  assert(Array.isArray(timeline.events[eventId]?.cues), `Missing pursuit timeline event ${eventId}.`);
}

const qizhenStartMusic = timeline.events.rpg_qizhen_chase_started.cues
  .find((cue) => cue.channel === "music");
assert(qizhenStartMusic?.asset === "music_qizhen_swan_chase", "Black-swan chase must start its dedicated music.");
assert(qizhenStartMusic?.loop === true, "Black-swan chase music must loop.");
assert(
  timeline.events.rpg_qizhen_chase_restarted.cues.some(
    (cue) => cue.channel === "music" && cue.asset === "music_qizhen_swan_chase"
  ),
  "Black-swan retry must restore the chase bed after failure."
);
assert(
  timeline.events.rpg_qizhen_chase_failed.cues.some((cue) => cue.channel === "music" && cue.action === "stop"),
  "Black-swan failure must stop the chase bed."
);
assert(
  timeline.events.rpg_qizhen_escape_completed_requested.cues.some(
    (cue) => cue.channel === "music" && cue.action === "stop"
  ),
  "Black-swan success must stop the chase bed."
);
assert(
  chapterFourTimeline.events.final_chase_started.cues.some(
    (cue) => cue.channel === "music" && cue.asset === "music_ch4_prologue_night_pursuit"
  ),
  "Guard chase must retain the established night-pursuit music identity."
);
assert(
  timeline.events.final_chase_started.cues.every((cue) => cue.channel !== "music"),
  "The pursuit extension must not replace the established guard chase music."
);

for (const eventId of [
  "qizhen_swan_chase_telegraph",
  "qizhen_swan_chase_surge",
  "final_chase_pressure_catch_up",
  "final_chase_pressure_tracking",
  "final_chase_pressure_close"
]) {
  assert(
    timeline.events[eventId].cues.some((cue) => cue.channel === "music" && cue.action === "update"),
    `${eventId} must update the active pursuit bed without restarting it.`
  );
}
assert(
  timeline.events.qizhen_swan_chase_telegraph.cues.every((cue) => cue.channel !== "voice"),
  "Repeated swan telegraphs must not replay dialogue."
);
assert(
  timeline.events.final_chase_pressure_close.cues.every((cue) => cue.channel !== "voice"),
  "Repeated close-band transitions must not replay guard dialogue."
);

const expectedVoiceEvents = new Map([
  ["vo_pursuit_qizhen_swan_start", "rpg_qizhen_chase_started"],
  ["vo_pursuit_qizhen_swan_warning", "qizhen_swan_chase_telegraph_voice"],
  ["vo_pursuit_qizhen_swan_final", "qizhen_swan_chase_final_bank"],
  ["vo_pursuit_chapter4_guard_start", "final_chase_started"],
  ["vo_pursuit_chapter4_guard_stair", "final_chase_floor_changed"],
  ["vo_pursuit_chapter4_guard_close", "final_chase_close_voice"]
]);
for (const [asset, eventId] of expectedVoiceEvents) {
  assert(
    timeline.events[eventId].cues.some((cue) => cue.channel === "voice" && cue.asset === asset),
    `${asset} must be routed through ${eventId}.`
  );
}

const playerFacingVoiceCues = Object.values(timeline.events)
  .flatMap(({ cues }) => cues)
  .filter((cue) => cue.channel === "voice");
assert(
  playerFacingVoiceCues.every((cue) => cue.subtitleKey === undefined),
  "Pursuit voice cues must leave Chinese subtitles to the RPG safe-zone surface."
);

const expectedSubtitles = new Set(content.lines.map((line) => line.subtitleZh));
for (const subtitle of Object.values(qizhenContent.chase.voiceSubtitles)) {
  assert(expectedSubtitles.has(subtitle), `Qizhen subtitle is not paired with generated voice: ${subtitle}`);
}
for (const key of ["chase.started", "chase.close", "chase.floor_changed"]) {
  const subtitle = chapterFourContent.dialogues[key]?.[0]?.text;
  assert(expectedSubtitles.has(subtitle), `Chapter 4 subtitle is not paired with generated voice: ${key}`);
}

for (const definition of [...content.music, ...content.lines]) {
  const metadata = generated.assets[definition.asset];
  assert(Boolean(metadata), `Generated manifest missing ${definition.asset}.`);
  const path = join(root, "src/assets/audio", definition.path);
  assert(existsSync(path), `Generated audio file missing: ${definition.path}.`);
  assert(sha256(path) === metadata.sha256, `Generated audio hash drift: ${definition.asset}.`);
  const { stream, durationMs } = probe(path);
  assert(stream?.codec_name === "mp3", `${definition.asset} must decode as MP3.`);
  if (metadata.kind === "music") {
    assert(Number(stream.sample_rate) === 44100, `${definition.asset} must be 44100Hz.`);
    assert(Number(stream.channels) === 2, `${definition.asset} must be stereo.`);
    assert(Math.abs(durationMs - definition.durationSeconds * 1000) <= 90, `${definition.asset} duration drift.`);
  } else {
    assert(Number(stream.sample_rate) === 32000, `${definition.asset} must be 32000Hz.`);
    assert(Number(stream.channels) === 1, `${definition.asset} must be mono.`);
    assert(durationMs <= definition.maxDurationMs, `${definition.asset} exceeds its scene budget.`);
    assert(metadata.source.startsWith("MiniMax speech-2.8-hd"), `${definition.asset} must keep the approved MiniMax voice source.`);
  }
}

assert(audioDirectorSource.includes("mergeAudioTimelines("), "AudioDirector must merge duplicate event beats.");
assert(audioDirectorSource.includes("pursuitTimelineData"), "AudioDirector must load pursuit timeline data.");
assert(audioDirectorSource.includes("pursuitGeneratedAudioData"), "AudioDirector must load pursuit duration metadata.");
assert(presentationDirectorSource.includes("pursuitTimelineData"), "PresentationDirector must publish pursuit events.");
assert(qizhenSceneSource.includes('this.emitDomain("qizhen_swan_chase_telegraph_voice"'), "Swan chase must emit its one-shot warning voice event.");
assert(qizhenSceneSource.includes("!this.chaseTelegraphVoicePlayed"), "Swan warning voice must be attempt-scoped.");
assert(qizhenSceneSource.includes('this.emitDomain("rpg_qizhen_chase_restarted"'), "Swan retry must restart its music after the failure animation.");
assert(chapterFourSceneSource.includes("step.state.pursuitBand !== this.finalChaseAudioBand"), "Guard music intensity must follow pursuit-band transitions.");
assert(chapterFourSceneSource.includes("!this.finalChaseCloseVoicePlayed"), "Guard close voice must play at most once per attempt.");
assert(chapterFourSceneSource.includes('this.safeBridgeEmit("final_chase_floor_changed"'), "Guard floor-transition voice event must be emitted.");

console.log(`Pursuit audio verification passed (${assertions} assertions).`);
