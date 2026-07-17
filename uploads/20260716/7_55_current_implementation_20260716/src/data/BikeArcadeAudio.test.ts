import { createHash } from "node:crypto";
import { existsSync, readFileSync } from "node:fs";
import { basename, join, resolve } from "node:path";
import { spawnSync } from "node:child_process";
import { describe, expect, it } from "vitest";

type ContentCue = {
  cue: string;
  [key: string]: unknown;
};

type BikeArcadeContent = {
  chapterId: string;
  voice: { id: string; language: string };
  subtitles: Record<string, string>;
  music: Array<ContentCue & { stage: string; bpm: number; instruments: string }>;
  sfx: Array<ContentCue & { action: string }>;
  narration: Array<
    ContentCue & {
      stage: string;
      text: string;
      subtitle: string;
      profile: { speed: number; pitch: number };
    }
  >;
};

type AudioRoute = {
  version: number;
  events: Record<string, { cues: NativeAudioCue[] }>;
};

type NativeAudioCue = {
  channel: "music" | "sfx" | "voice" | "text";
  asset?: string;
  action?: "play" | "update" | "stop";
  offsetMs?: number;
  startMs?: number;
  durationMs?: number;
  volume?: number;
  loop?: boolean;
  playbackRate?: number;
  subtitleKey?: string;
  subtitleSurface?: "toast" | "scene";
  duckMusicTo?: number;
  once?: boolean;
};

type GeneratedCue = {
  path: string;
  kind: "music" | "sfx" | "voice";
  durationMs: number;
  codec: string;
  sampleRate: number;
  channels: number;
  sha256: string;
  source: string;
};

type GeneratedManifest = {
  version: number;
  generatedAt: string;
  assets: Record<string, GeneratedCue>;
};

const root = process.cwd();
const contentPath = join(root, "src/data/bike-arcade.content.json");
const routePath = join(root, "src/data/bike-arcade.audio.json");
const generatedPath = join(root, "src/data/bike-arcade.audio.generated.json");
const audioRoot = join(root, "src/assets/audio");
const packagePath = join(root, "package.json");
const generatorPath = join(root, "scripts/generate-bike-arcade-audio.mjs");

function requireJson<T>(path: string): T {
  expect(existsSync(path), `missing ${path}`).toBe(true);
  return JSON.parse(readFileSync(path, "utf8")) as T;
}

function probeAudio(path: string) {
  const result = spawnSync(
    "ffprobe",
    [
      "-v",
      "error",
      "-show_entries",
      "stream=codec_name,codec_type,sample_rate,channels:format=duration",
      "-of",
      "json",
      path
    ],
    { encoding: "utf8" }
  );
  expect(result.status, result.stderr || `ffprobe failed for ${path}`).toBe(0);
  return JSON.parse(result.stdout) as {
    streams: Array<{ codec_name: string; codec_type: string; sample_rate: string; channels: number }>;
    format: { duration: string };
  };
}

describe("BikeArcadeAudio asset contract", () => {
  it("passes the raw MiniMax media output path into every generation verifier", () => {
    const generator = readFileSync(generatorPath, "utf8");

    expect(generator).toMatch(/\],\s*raw,\s*`MiniMax music \$\{definition\.cue\}`/);
    expect(generator).toMatch(/\],\s*raw,\s*`MiniMax sound-design stem \$\{group\}`/);
  });

  it("declares four music stages, ten action sounds, and three text-only feedback lines", () => {
    const content = requireJson<BikeArcadeContent>(contentPath);
    const packageJson = requireJson<{ scripts: Record<string, string> }>(packagePath);

    expect(content.chapterId).toBe("bike-arcade-755");
    expect(packageJson.scripts["audio:bike-arcade"]).toBe("node scripts/generate-bike-arcade-audio.mjs");
    expect(content.music.map(({ stage }) => stage)).toEqual(["start", "congestion", "sprint", "result"]);
    expect(content.music).toHaveLength(4);
    expect(Math.max(...content.music.map(({ bpm }) => bpm)) - Math.min(...content.music.map(({ bpm }) => bpm))).toBeGreaterThanOrEqual(60);
    expect(new Set(content.music.map(({ instruments }) => instruments)).size).toBe(4);

    expect(content.sfx.map(({ action }) => action)).toEqual([
      "lane_change",
      "near_miss",
      "collision",
      "damage",
      "milestone",
      "pause",
      "resume",
      "success",
      "failure",
      "button"
    ]);

    expect(content.voice.language).toBe("English");
    expect(content.voice.id).toMatch(/Lady|Female|Woman/i);
    expect(content.narration.map(({ stage }) => stage)).toEqual(["start", "last-life", "result"]);
    expect(content.narration).toHaveLength(3);
    expect(new Set(content.narration.map(({ profile }) => JSON.stringify(profile))).size).toBe(3);
    for (const line of content.narration) {
      expect(line.text).toMatch(/^[\x20-\x7E]+$/);
      expect(line.text.trim().split(/\s+/).length).toBeGreaterThan(1);
      expect(line.text.trim().split(/\s+/).length).toBeLessThanOrEqual(10);
      expect(content.subtitles[line.subtitle]).toMatch(/[\u3400-\u9fff]/u);
      expect(content.subtitles[line.subtitle]).not.toBe(line.text);
    }
  });

  it("uses the AudioDirector native schema for every domain event", () => {
    const content = requireJson<BikeArcadeContent>(contentPath);
    const route = requireJson<AudioRoute>(routePath);
    const generated = requireJson<GeneratedManifest>(generatedPath);
    const allowedFields = new Set([
      "action",
      "asset",
      "channel",
      "duckMusicTo",
      "durationMs",
      "loop",
      "offsetMs",
      "once",
      "playbackRate",
      "startMs",
      "subtitleKey",
      "subtitleSurface",
      "volume"
    ]);
    const routedAssets = new Set<string>();

    expect(route.version).toBe(1);
    expect(Object.keys(route.events)).toEqual(
      expect.arrayContaining([
        "bike_arcade_opened",
        "bike_arcade_run_started",
        "bike_arcade_lane_changed",
        "bike_arcade_near_miss",
        "bike_arcade_collision",
        "bike_arcade_last_life",
        "bike_arcade_milestone",
        "bike_arcade_paused",
        "bike_arcade_resumed",
        "bike_arcade_congestion_started",
        "bike_arcade_sprint_started",
        "bike_arcade_won",
        "bike_arcade_lost",
        "bike_arcade_closed",
        "bike_arcade_button_pressed"
      ])
    );

    for (const [event, beat] of Object.entries(route.events)) {
      expect(event === "chapter_transition_opened" || /^bike_arcade_/.test(event)).toBe(true);
      expect(Object.keys(beat)).toEqual(["cues"]);
      expect(beat.cues.length).toBeGreaterThan(0);
      for (const cue of beat.cues) {
        expect(Object.keys(cue).every((field) => allowedFields.has(field))).toBe(true);
        expect(["music", "sfx", "text"]).toContain(cue.channel);
        if (cue.channel === "text") {
          expect(cue.asset, event).toBeUndefined();
          expect(cue.subtitleKey, event).toBeTruthy();
        } else {
          expect(cue.asset, event).toBeTruthy();
          expect(generated.assets[cue.asset ?? ""], `missing native asset ${cue.asset}`).toBeDefined();
        }
        expect(cue.offsetMs === undefined || (Number.isInteger(cue.offsetMs) && cue.offsetMs >= 0)).toBe(true);
        expect(cue.duckMusicTo === undefined || (cue.duckMusicTo >= 0 && cue.duckMusicTo <= 1)).toBe(true);
        if (cue.channel === "music") expect(cue.action).toBeDefined();
        if (cue.subtitleKey) expect(content.subtitles[cue.subtitleKey]).toBeDefined();
        if (cue.asset) routedAssets.add(cue.asset);
      }
    }

    expect(readFileSync(routePath, "utf8")).not.toMatch(/"cue"|"subtitle"|"offset"|"ducking"|"replace"|\.mp3|src\/assets/);
    expect([...routedAssets].sort()).toEqual(Object.keys(generated.assets).sort());
  });

  it("ships every native asset as a distinct, decodable MP3 with ffprobe metadata", () => {
    const content = requireJson<BikeArcadeContent>(contentPath);
    const generated = requireJson<GeneratedManifest>(generatedPath);
    const expected = [...content.music, ...content.sfx];

    expect(generated.version).toBe(1);
    expect(Number.isNaN(Date.parse(generated.generatedAt))).toBe(false);
    expect(Object.keys(generated.assets)).toHaveLength(expected.length);

    const hashes = new Set<string>();
    const musicHashes = new Set<string>();
    for (const [asset, metadata] of Object.entries(generated.assets)) {
      expect(metadata.path.startsWith("bike-arcade/")).toBe(true);
      expect(metadata.path.endsWith(".mp3")).toBe(true);
      expect(asset).toBe(basename(metadata.path, ".mp3"));
      expect(metadata.source).toMatch(/^MiniMax /);

      const absolutePath = resolve(audioRoot, metadata.path);
      expect(absolutePath.startsWith(`${audioRoot}/`)).toBe(true);
      expect(existsSync(absolutePath), `missing ${absolutePath}`).toBe(true);
      const bytes = readFileSync(absolutePath);
      const sha256 = createHash("sha256").update(bytes).digest("hex");
      expect(metadata.sha256).toBe(sha256);
      expect(hashes.has(sha256), `duplicate audio bytes for ${asset}`).toBe(false);
      hashes.add(sha256);
      if (metadata.kind === "music") musicHashes.add(sha256);

      const probe = probeAudio(absolutePath);
      const stream = probe.streams.find(({ codec_type }) => codec_type === "audio");
      expect(stream?.codec_name).toBe("mp3");
      expect(metadata.codec).toBe(stream?.codec_name);
      expect(metadata.sampleRate).toBe(Number(stream?.sample_rate));
      expect(metadata.channels).toBe(stream?.channels);
      expect(Math.abs(metadata.durationMs - Number(probe.format.duration) * 1000)).toBeLessThanOrEqual(20);

      const decode = spawnSync("ffmpeg", ["-v", "error", "-i", absolutePath, "-f", "null", "-"], {
        encoding: "utf8"
      });
      expect(decode.status, decode.stderr || `decode failed for ${absolutePath}`).toBe(0);
    }

    expect(hashes.size).toBe(expected.length);
    expect(musicHashes.size).toBe(4);
  });
});
