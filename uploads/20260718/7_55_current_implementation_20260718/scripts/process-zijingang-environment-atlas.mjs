import { existsSync, mkdirSync, rmSync } from "node:fs";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { spawnSync } from "node:child_process";

const root = resolve(dirname(fileURLToPath(import.meta.url)), "..");
const source = join(root, "src/assets/rpg/props/zijingang_environment_source.png");
const frontSourceDirectory = join(root, "src/assets/rpg/props/front-source");
const sideSourceDirectory = join(root, "src/assets/rpg/props/side-source");
const landscapeSourceDirectory = join(root, "src/assets/rpg/props/landscape-source");
const output = join(root, "src/assets/rpg/props/zijingang_environment.png");
const temporary = join(root, ".tmp-zijingang-environment");

const frontFrameSources = new Map([
  [0, "teaching_courtyard.png"],
  [1, "dorm_cluster.png"],
  [2, "research_cluster.png"],
  [3, "service_block.png"],
  [6, "lake_heart_island.png"],
  [7, "nanhuayuan.png"],
  [10, "sports_courts.png"],
  [11, "greenhouse_garden.png"],
  [14, "bike_shelter.png"],
  [15, "campus_kiosk.png"]
]);

const sideFrameSources = new Map([
  [16, "dorm_cluster_side.png"],
  [17, "teaching_courtyard_side.png"],
  [18, "service_block_side.png"],
  [19, "greenhouse_garden_side.png"]
]);

const landscapeFrameSources = new Map([
  [4, "tree_grove.png"],
  [5, "willow_bank.png"],
  [20, "avenue_tree_row.png"]
]);

function run(args) {
  const result = spawnSync("magick", args, { encoding: "utf8" });
  if (result.status !== 0) {
    throw new Error(result.stderr || `ImageMagick failed: ${args.join(" ")}`);
  }
  return result.stdout.trim();
}

const [sourceWidth, sourceHeight] = run(["identify", "-format", "%w %h", source]).split(" ").map(Number);
mkdirSync(temporary, { recursive: true });

const frames = [];
for (let row = 0; row < 4; row += 1) {
  for (let column = 0; column < 4; column += 1) {
    const frameIndex = row * 4 + column;
    const left = Math.round(column * sourceWidth / 4) + 2;
    const right = Math.round((column + 1) * sourceWidth / 4) - 2;
    const top = Math.round(row * sourceHeight / 4) + 2;
    const bottom = Math.round((row + 1) * sourceHeight / 4) - 2;
    const frame = join(temporary, `frame-${frameIndex}.png`);
    const frontFilename = frontFrameSources.get(frameIndex);
    const landscapeFilename = landscapeFrameSources.get(frameIndex);
    const generatedSource = frontFilename
      ? join(frontSourceDirectory, frontFilename)
      : landscapeFilename
        ? join(landscapeSourceDirectory, landscapeFilename)
        : null;

    if (generatedSource && !existsSync(generatedSource)) {
      throw new Error(`Missing generated environment source: ${generatedSource}`);
    }

    const sourceArguments = generatedSource
      ? [generatedSource]
      : [
          source,
          "-crop", `${right - left}x${bottom - top}+${left}+${top}`,
          "+repage"
        ];
    run([
      ...sourceArguments,
      "-alpha", "on",
      "-fuzz", generatedSource ? "20%" : "46%",
      "-transparent", "#ff00ff",
      "-trim",
      "+repage",
      "-resize", "480x480>",
      "-gravity", "south",
      "-background", "none",
      "-extent", "512x512",
      `PNG32:${frame}`
    ]);
    frames.push(frame);
  }
}

for (const [frameIndex, filename] of sideFrameSources) {
  const sideSource = join(sideSourceDirectory, filename);
  if (!existsSync(sideSource)) {
    throw new Error(`Missing side environment source: ${sideSource}`);
  }
  const frame = join(temporary, `frame-${frameIndex}.png`);
  run([
    sideSource,
    "-alpha", "on",
    "-fuzz", "20%",
    "-transparent", "#ff00ff",
    "-trim",
    "+repage",
    "-resize", "480x480>",
    "-gravity", "south",
    "-background", "none",
    "-extent", "512x512",
    `PNG32:${frame}`
  ]);
  frames.push(frame);
}

for (const [frameIndex, filename] of landscapeFrameSources) {
  if (frameIndex < 16) continue;
  const landscapeSource = join(landscapeSourceDirectory, filename);
  if (!existsSync(landscapeSource)) {
    throw new Error(`Missing landscape environment source: ${landscapeSource}`);
  }
  const frame = join(temporary, `frame-${frameIndex}.png`);
  run([
    landscapeSource,
    "-alpha", "on",
    "-fuzz", "20%",
    "-transparent", "#ff00ff",
    "-trim",
    "+repage",
    "-resize", "480x480>",
    "-gravity", "south",
    "-background", "none",
    "-extent", "512x512",
    `PNG32:${frame}`
  ]);
  frames.push(frame);
}

const atlasRows = Math.ceil(frames.length / 4);
const compositeArgs = ["-size", `2048x${atlasRows * 512}`, "canvas:none"];
frames.forEach((frame, index) => {
  compositeArgs.push(
    frame,
    "-geometry", `+${index % 4 * 512}+${Math.floor(index / 4) * 512}`,
    "-composite"
  );
});
compositeArgs.push(`PNG32:${output}`);
run(compositeArgs);
rmSync(temporary, { recursive: true, force: true });
process.stdout.write(`${output}\n`);
