/* @vitest-environment node */

import { createHash } from "node:crypto";
import { spawnSync } from "node:child_process";
import { existsSync, readFileSync } from "node:fs";
import { basename, resolve } from "node:path";
import { describe, expect, it } from "vitest";

type VoiceConfig = {
  id: string;
  language: string;
};

type NarrationLine = {
  text: string;
  subtitleZh?: string;
  tone: string;
  delivery?: string;
  segments?: Array<{ text: string; profile: { speed: number; pitch: number } }>;
};

type GeneratedAsset = {
  path: string;
  durationMs: number;
  source: string;
  sourceTextHash?: string;
};

type GeneratedManifest = {
  assets: Record<string, GeneratedAsset>;
};

type AudioTimeline = {
  events: Record<string, { cues: Array<{
    channel: string;
    asset?: string;
    subtitleKey?: string;
    subtitleSurface?: "toast" | "scene";
  }> }>;
};

type LegacyVoiceLine = {
  line_id: string;
  voice_key: string;
  speaker: "narrator" | "xiaoying" | "system";
  subtitle_zh: string;
  voice_text_en: string;
  delivery: string;
};

const root = resolve(import.meta.dirname, "../..");
const audioRoot = resolve(root, "src/assets/audio");
const readJson = <T,>(path: string): T => JSON.parse(readFileSync(resolve(root, path), "utf8")) as T;
const sha256 = (text: string): string => createHash("sha256").update(text).digest("hex");
const hasCjk = (text: string): boolean => /[\u3400-\u9fff]/u.test(text);
const isAscii = (text: string): boolean => /^[\x20-\x7e]+$/.test(text);

const actOneContent = readJson<{
  voices: { chapterOne: VoiceConfig; prologueNarrator: VoiceConfig; chapterTwo: VoiceConfig };
  audioNarration: Record<string, NarrationLine>;
}>("src/data/act-one-bootstrap.content.json");
const libraryContent = readJson<{
  voice: VoiceConfig;
  narration: Record<string, NarrationLine>;
}>("src/data/library-finals.content.json");
const bikeContent = readJson<{
  voice: VoiceConfig;
  subtitles: Record<string, string>;
  narration: Array<{
    cue: string;
    text: string;
    subtitle: string;
    delivery: string;
    profile: { speed: number; pitch: number };
  }>;
}>("src/data/bike-arcade.content.json");

const actOneManifest = readJson<GeneratedManifest>("src/data/act-one.audio.generated.json");
const libraryManifest = readJson<GeneratedManifest>("src/data/library-finals.audio.generated.json");
const bikeManifest = readJson<GeneratedManifest>("src/data/bike-arcade.audio.generated.json");
const legacyVoiceLines = readJson<LegacyVoiceLine[]>("src/data/dialogue.lines.json");
const actOneTimeline = readJson<AudioTimeline>("src/data/act-one.audio.json");
const libraryTimeline = readJson<AudioTimeline>("src/data/library-finals.audio.json");
const bikeTimeline = readJson<AudioTimeline>("src/data/bike-arcade.audio.json");

const ACT_TWO_DIALOGUE_KEYS = new Set([
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
const LEGACY_DIALOGUE_KEYS = new Set(["wake_narration", "wake_flash", "xy_attack", "xy_laugh"]);
const actTwoPreludeLines = Object.entries(actOneContent.audioNarration).filter(([key]) => key.startsWith("act2_"));
const actTwoDialogueLines = actTwoPreludeLines.filter(([key]) => ACT_TWO_DIALOGUE_KEYS.has(key));
const actTwoFeedbackLines = actTwoPreludeLines.filter(([key]) => !ACT_TWO_DIALOGUE_KEYS.has(key));
const chapterOneLines = Object.entries(actOneContent.audioNarration).filter(
  ([key]) => key.startsWith("act1_")
);
const prologueNarratorIntro = actOneContent.audioNarration.prologue_narrator_intro;
const prologueNarratorLines = Object.entries(actOneContent.audioNarration).filter(([key]) => key.startsWith("prologue_"));
const libraryLines = Object.entries(libraryContent.narration);
const bikeLines = bikeContent.narration;

function probeVoice(path: string): { codec: string; sampleRate: number; channels: number; durationMs: number } {
  const result = spawnSync(
    "ffprobe",
    [
      "-v",
      "error",
      "-select_streams",
      "a:0",
      "-show_entries",
      "stream=codec_name,sample_rate,channels:format=duration",
      "-of",
      "json",
      path
    ],
    { encoding: "utf8" }
  );
  expect(result.status, result.stderr || `ffprobe failed for ${path}`).toBe(0);
  const parsed = JSON.parse(result.stdout) as {
    streams: Array<{ codec_name: string; sample_rate: string; channels: number }>;
    format: { duration: string };
  };
  const stream = parsed.streams[0];
  return {
    codec: stream.codec_name,
    sampleRate: Number(stream.sample_rate),
    channels: stream.channels,
    durationMs: Math.round(Number(parsed.format.duration) * 1000)
  };
}

function expectEnglishLine(line: { text: string; delivery?: string }): void {
  expect(isAscii(line.text), line.text).toBe(true);
  expect(hasCjk(line.text), line.text).toBe(false);
  expect(line.text.trim().split(/\s+/).length, line.text).toBeGreaterThan(1);
  expect(line.delivery?.trim().length ?? 0, line.text).toBeGreaterThan(10);
}

function expectVoiceAsset(
  manifest: GeneratedManifest,
  asset: string,
  text: string,
  expectedVoice: string,
  expectedBasename = asset
): void {
  const entry = manifest.assets[asset];
  expect(entry, asset).toBeDefined();
  expect(entry.source, asset).toBe(`MiniMax speech-2.8-hd ${expectedVoice}`);
  expect(entry.sourceTextHash, asset).toBe(sha256(text).slice(0, entry.sourceTextHash?.length ?? 64));

  const absolutePath = resolve(audioRoot, entry.path);
  expect(absolutePath.startsWith(`${audioRoot}/`), asset).toBe(true);
  expect(existsSync(absolutePath), absolutePath).toBe(true);
  expect(basename(absolutePath, ".mp3"), asset).toBe(expectedBasename);

  const probe = probeVoice(absolutePath);
  expect(probe.codec, asset).toBe("mp3");
  expect(probe.sampleRate, asset).toBe(32000);
  expect(probe.channels, asset).toBe(1);
  expect(probe.durationMs, asset).toBeGreaterThan(0);
  expect(Math.abs(entry.durationMs - probe.durationMs), asset).toBeLessThanOrEqual(20);

  const volume = spawnSync(
    "ffmpeg",
    ["-hide_banner", "-nostats", "-i", absolutePath, "-af", "volumedetect", "-f", "null", "-"],
    { encoding: "utf8" }
  );
  expect(volume.status, volume.stderr || `volume scan failed for ${absolutePath}`).toBe(0);
  const maxVolume = Number.parseFloat(volume.stderr.match(/max_volume:\s*(-?[\d.]+) dB/)?.[1] ?? "-Infinity");
  expect(maxVolume, asset).toBeGreaterThan(-30);
}

describe("Whole-game English voice contract", () => {
  it("separates voiced story dialogue from unvoiced operation feedback", () => {
    expect(actTwoPreludeLines).toHaveLength(21);
    expect(actTwoDialogueLines).toHaveLength(9);
    expect(actTwoFeedbackLines).toHaveLength(12);
    expect(libraryLines).toHaveLength(14);
    expect(bikeLines).toHaveLength(3);

    const expectedVoice = actOneContent.voices.chapterTwo;
    expect(expectedVoice).toEqual({ id: "English_Graceful_Lady", language: "English" });
    expect(libraryContent.voice).toEqual(expectedVoice);
    expect(bikeContent.voice).toEqual(expectedVoice);

    for (const [key, line] of [...actTwoPreludeLines, ...libraryLines]) {
      expectEnglishLine(line);
      expect(hasCjk(line.subtitleZh ?? ""), key).toBe(true);
    }
    for (const line of bikeLines) {
      expectEnglishLine(line);
      expect(hasCjk(bikeContent.subtitles[line.subtitle] ?? ""), line.cue).toBe(true);
      expect(line.profile.speed).toBeGreaterThan(0);
      expect(Number.isFinite(line.profile.pitch)).toBe(true);
    }
  });

  it("keeps Chapter 1 operation feedback as Chinese subtitle text without voice assets", () => {
    expect(actOneContent.voices.chapterOne).toEqual({
      id: "English_Graceful_Lady",
      language: "English"
    });
    expect(chapterOneLines.length).toBeGreaterThan(0);
    for (const [key, line] of chapterOneLines) {
      expectEnglishLine(line);
      expect(hasCjk(line.subtitleZh ?? ""), key).toBe(true);
      expect(actOneManifest.assets[`vo_${key}`], key).toBeUndefined();
    }
  });

  it("uses an English male narrator performance for every prologue line", () => {
    expect(actOneContent.voices.prologueNarrator).toEqual({
      id: "English_expressive_narrator",
      language: "English"
    });
    expectEnglishLine(prologueNarratorIntro);
    for (const [key, line] of prologueNarratorLines) {
      expectEnglishLine(line);
      expect(hasCjk(line.subtitleZh ?? ""), key).toBe(true);
      expectVoiceAsset(actOneManifest, `vo_${key}`, line.text, actOneContent.voices.prologueNarrator.id);
    }
    expect(prologueNarratorIntro.segments).toHaveLength(4);
    expect(prologueNarratorIntro.segments?.map(({ text }) => text).join(" ")).toBe(prologueNarratorIntro.text);
    expect(new Set(prologueNarratorIntro.segments?.map(({ profile }) => profile.pitch))).toEqual(new Set([-4]));
    expect(new Set(prologueNarratorIntro.segments?.map(({ profile }) => profile.speed)).size).toBe(4);

    const actOneGenerator = readFileSync(resolve(root, "scripts/generate-act-one-audio.mjs"), "utf8");
    expect(actOneGenerator).toContain("const NARRATOR_BASE_PITCH = -4;");
    expect(actOneGenerator.match(/pitch: NARRATOR_BASE_PITCH/g)).toHaveLength(4);
  });

  it("voices only the four legacy story lines and leaves legacy operation feedback silent", () => {
    expect(legacyVoiceLines).toHaveLength(9);
    for (const [index, line] of legacyVoiceLines.entries()) {
      expect(hasCjk(line.subtitle_zh), line.line_id).toBe(true);
      expectEnglishLine({ text: line.voice_text_en, delivery: line.delivery });
      if (!LEGACY_DIALOGUE_KEYS.has(line.voice_key)) {
        expect(actOneManifest.assets[`vo_legacy_${line.voice_key}`], line.voice_key).toBeUndefined();
        continue;
      }
      const voice = line.speaker === "narrator"
        ? actOneContent.voices.prologueNarrator.id
        : actOneContent.voices.chapterOne.id;
      expectVoiceAsset(
        actOneManifest,
        `vo_legacy_${line.voice_key}`,
        line.voice_text_en,
        voice,
        `all_shadow_vo_${String(index + 2).padStart(3, "0")}`
      );
    }
  });

  it("assigns each story voice to the scene and each feedback cue to one Chinese text owner", () => {
    const subtitles: Record<string, string> = {
      ...Object.fromEntries(Object.entries(actOneContent.audioNarration).map(([key, line]) => [key, line.subtitleZh ?? ""])),
      ...Object.fromEntries(Object.entries(libraryContent.narration).map(([key, line]) => [key, line.subtitleZh ?? ""])),
      ...bikeContent.subtitles
    };
    const timelines = [actOneTimeline, libraryTimeline, bikeTimeline];
    const sceneOwnedEvents = new Set([
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

    for (const timeline of timelines) {
      for (const [event, beat] of Object.entries(timeline.events)) {
        for (const cue of beat.cues.filter(({ channel }) => channel === "voice")) {
          expect(cue.subtitleKey, event).toBeTruthy();
          expect(hasCjk(subtitles[cue.subtitleKey ?? ""] ?? ""), `${event}:${cue.subtitleKey}`).toBe(true);
          expect(sceneOwnedEvents.has(event), event).toBe(true);
          expect(cue.subtitleSurface, event).toBe("scene");
          expect(cue.asset, event).toBeTruthy();
        }
        for (const cue of beat.cues.filter(({ channel }) => channel === "text")) {
          expect(cue.subtitleKey, event).toBeTruthy();
          expect(hasCjk(subtitles[cue.subtitleKey ?? ""] ?? ""), `${event}:${cue.subtitleKey}`).toBe(true);
          expect(cue.asset, event).toBeUndefined();
        }
      }
    }

    const baseCss = readFileSync(resolve(root, "src/styles/base.css"), "utf8");
    expect(baseCss).toMatch(/\.toast-layer\s*\{[^}]*bottom:\s*18px;[^}]*left:\s*12px;[^}]*right:\s*12px;/s);
    expect(baseCss).toMatch(/\.px-toast\s*\{[^}]*font-size:\s*14px;[^}]*line-height:\s*1\.45;[^}]*padding:\s*9px 13px;/s);
  });

  it("ships only the approved male narrator and female system dialogue assets", () => {
    const voice = actOneContent.voices.chapterTwo.id;
    for (const [key, line] of actTwoDialogueLines) {
      expectVoiceAsset(actOneManifest, `vo_${key}`, line.text, voice);
    }
    expect(Object.keys(actOneManifest.assets).filter((asset) => asset.startsWith("vo_"))).toHaveLength(16);
    expect(Object.keys(libraryManifest.assets).filter((asset) => asset.startsWith("vo_"))).toEqual([]);
    expect(Object.keys(bikeManifest.assets).filter((asset) => asset.startsWith("vo_"))).toEqual([]);
  });

  it("filters deprecated voices during the idempotent aggregate audio command", () => {
    const actOneGenerator = readFileSync(resolve(root, "scripts/generate-act-one-audio.mjs"), "utf8");
    const libraryGenerator = readFileSync(resolve(root, "scripts/generate-library-finals-audio.mjs"), "utf8");
    const bikeGenerator = readFileSync(resolve(root, "scripts/generate-bike-arcade-audio.mjs"), "utf8");
    const packageJson = readJson<{ scripts: Record<string, string> }>("package.json");

    expect(actOneGenerator).toContain("delivery: line.delivery");
    expect(actOneGenerator).toContain("STORY_VOICE_KEYS.has(key)");
    expect(actOneGenerator).toContain("LEGACY_STORY_VOICE_KEYS.has(voice_key)");
    expect(libraryGenerator).toContain('!asset.startsWith("vo_")');
    expect(bikeGenerator).toContain('process.argv.includes("--voice-only")');
    expect(bikeGenerator).not.toContain('...content.narration.map((definition) => ({ kind: "voice"');
    expect(packageJson.scripts["audio:chapters:english"]).toContain("--voice-only");
  });
});
