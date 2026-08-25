import { mkdirSync, statSync } from "node:fs";
import { dirname, resolve } from "node:path";
import { spawnSync } from "node:child_process";
import { fileURLToPath } from "node:url";

const projectRoot = resolve(dirname(fileURLToPath(import.meta.url)), "..");
const outputDirectory = resolve(projectRoot, "src/assets/audio/chapter4/details");

const assets = [
  {
    filename: "sfx_ch4_clock_stutter_loop.mp3",
    duration: 1.9,
    components: [
      { frequency: 760, duration: 0.055, delayMs: 0, volume: 0.26 },
      { frequency: 520, duration: 0.07, delayMs: 310, volume: 0.19 },
      { frequency: 810, duration: 0.05, delayMs: 790, volume: 0.24 },
      { frequency: 470, duration: 0.075, delayMs: 1260, volume: 0.18 },
      { frequency: 720, duration: 0.055, delayMs: 1600, volume: 0.22 }
    ]
  },
  {
    filename: "sfx_ch4_clock_tick_loop.mp3",
    duration: 1,
    components: [
      { frequency: 1040, duration: 0.035, delayMs: 0, volume: 0.2 },
      { frequency: 860, duration: 0.03, delayMs: 500, volume: 0.16 }
    ]
  },
  {
    filename: "sfx_ch4_cart_wheel_stuck.mp3",
    duration: 0.9,
    components: [
      { frequency: 88, duration: 0.9, delayMs: 0, volume: 0.08 },
      { frequency: 1180, duration: 0.24, delayMs: 70, volume: 0.16 },
      { frequency: 920, duration: 0.22, delayMs: 470, volume: 0.14 }
    ]
  },
  {
    filename: "sfx_ch4_cart_wheel_repaired.mp3",
    duration: 0.85,
    components: [
      { frequency: 82, duration: 0.85, delayMs: 0, volume: 0.1 },
      { frequency: 520, duration: 0.045, delayMs: 90, volume: 0.11 },
      { frequency: 470, duration: 0.04, delayMs: 520, volume: 0.09 }
    ]
  }
];

mkdirSync(outputDirectory, { recursive: true });

for (const asset of assets) {
  const outputPath = resolve(outputDirectory, asset.filename);
  const args = [
    "-hide_banner",
    "-loglevel",
    "error",
    "-y",
    "-f",
    "lavfi",
    "-i",
    `anullsrc=r=32000:cl=mono:d=${asset.duration}`
  ];
  asset.components.forEach((component) => {
    args.push(
      "-f",
      "lavfi",
      "-i",
      `sine=frequency=${component.frequency}:sample_rate=32000:duration=${component.duration}`
    );
  });

  const filteredComponents = asset.components.map((component, index) => {
    const fadeStart = Math.max(0, component.duration * 0.35).toFixed(4);
    const fadeDuration = Math.max(0.01, component.duration * 0.65).toFixed(4);
    return `[${index + 1}:a]volume=${component.volume},afade=t=out:st=${fadeStart}:d=${fadeDuration},adelay=${component.delayMs}[p${index}]`;
  });
  const inputLabels = ["[0:a]", ...asset.components.map((_component, index) => `[p${index}]`)].join("");
  const filter = [
    ...filteredComponents,
    `${inputLabels}amix=inputs=${asset.components.length + 1}:normalize=0:duration=first,alimiter=limit=0.82[out]`
  ].join(";");

  args.push(
    "-filter_complex",
    filter,
    "-map",
    "[out]",
    "-t",
    String(asset.duration),
    "-ar",
    "32000",
    "-ac",
    "1",
    "-codec:a",
    "libmp3lame",
    "-b:a",
    "96k",
    outputPath
  );

  const generated = spawnSync("ffmpeg", args, { cwd: projectRoot, stdio: "inherit" });
  if (generated.status !== 0) {
    throw new Error(`Failed to generate ${asset.filename}`);
  }
  if (statSync(outputPath).size < 1000) {
    throw new Error(`Generated asset is unexpectedly small: ${asset.filename}`);
  }
}

console.log(`Generated ${assets.length} Chapter 4 detail SFX assets in ${outputDirectory}`);
