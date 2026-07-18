/* @vitest-environment node */

import { spawnSync } from "node:child_process";
import { existsSync, readFileSync } from "node:fs";
import { resolve } from "node:path";
import { describe, expect, it } from "vitest";

const root = resolve(import.meta.dirname, "../..");
const manifestPath = resolve(root, "src/data/library-finals.audio.generated.json");
const manifest = JSON.parse(readFileSync(manifestPath, "utf8")) as {
  assets: Record<string, { durationMs: number; path: string }>;
};

const musicAssets = [
  "music_library_arrival_v2",
  "music_library_evidence_v2",
  "music_cc98_publicity_v2",
  "music_library_enforcement_v2",
  "music_library_022_reveal_v2"
] as const;

const sfxAssets = [
  "fx_library_gate_scan_v2",
  "fx_arrival_record_v2",
  "fx_backpack_alert_v2",
  "fx_note_pickup_v2",
  "fx_catalog_search_v2",
  "fx_catalog_wrong_v2",
  "fx_catalog_correct_v2",
  "fx_shelf_slide_v2",
  "fx_photo_glare_clear_v2",
  "fx_report_print_v2",
  "fx_nonperson_stamp_v2",
  "fx_receipt_slide_v2",
  "fx_evidence_upload_v2",
  "fx_pass_stamp_v2",
  "fx_backpack_transfer_v2",
  "fx_022_signal_v2"
] as const;

function assetPath(asset: string): string {
  return resolve(root, "src/assets/audio", manifest.assets[asset].path);
}

function probeAudio(path: string) {
  const result = spawnSync(
    "ffprobe",
    [
      "-v",
      "error",
      "-show_entries",
      "format=duration:stream=codec_name,codec_type",
      "-of",
      "json",
      path
    ],
    { encoding: "utf8" }
  );

  expect(result.status, result.stderr).toBe(0);
  return JSON.parse(result.stdout) as {
    format: { duration: string };
    streams: Array<{ codec_name: string; codec_type: string }>;
  };
}

describe("Library Finals V2 generated audio", () => {
  it("contains every music and SFX asset while keeping progress feedback text-only", () => {
    const expected = [...musicAssets, ...sfxAssets];

    expect(Object.keys(manifest.assets)).toHaveLength(expected.length);
    expect(Object.keys(manifest.assets).filter((asset) => asset.startsWith("vo_"))).toEqual([]);
    expected.forEach((asset) => {
      const entry = manifest.assets[asset];
      expect(entry, asset).toBeDefined();
      expect(entry.durationMs, asset).toBeGreaterThan(0);
      expect(existsSync(assetPath(asset)), asset).toBe(true);
    });
  });

  it.each(musicAssets)("keeps %s as an audible MP3 bed of at least 20 seconds", (asset) => {
    const path = assetPath(asset);
    const probe = probeAudio(path);
    const audioStream = probe.streams.find((stream) => stream.codec_type === "audio");

    expect(audioStream?.codec_name).toBe("mp3");
    expect(Number.parseFloat(probe.format.duration)).toBeGreaterThanOrEqual(20);
    expect(manifest.assets[asset].durationMs).toBe(
      Math.round(Number.parseFloat(probe.format.duration) * 1000)
    );

    const volume = spawnSync(
      "ffmpeg",
      ["-hide_banner", "-nostats", "-i", path, "-af", "volumedetect", "-f", "null", "-"],
      { encoding: "utf8" }
    );
    expect(volume.status, volume.stderr).toBe(0);
    const match = volume.stderr.match(/mean_volume:\s*(-?[\d.]+) dB/);
    expect(Number.parseFloat(match?.[1] ?? "-Infinity")).toBeGreaterThan(-70);
  });
});
