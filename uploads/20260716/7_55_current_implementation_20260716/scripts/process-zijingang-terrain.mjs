import { mkdirSync, rmSync } from "node:fs";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { spawnSync } from "node:child_process";

const root = resolve(dirname(fileURLToPath(import.meta.url)), "..");
const source = join(root, "src/assets/rpg/props/zijingang_environment.png");
const output = join(root, "src/assets/rpg/tiles/zijingang_terrain.png");
const temporary = join(root, ".tmp-zijingang-terrain");
mkdirSync(temporary, { recursive: true });

function run(args) {
  const result = spawnSync("magick", args, { encoding: "utf8" });
  if (result.status !== 0) {
    throw new Error(result.stderr || `ImageMagick failed: ${args.join(" ")}`);
  }
}

function file(name) {
  return join(temporary, `${name}.png`);
}

function sample(name, crop, transform = []) {
  run([source, "-crop", crop, "+repage", "-resize", "32x32!", ...transform, `PNG32:${file(name)}`]);
}

function seamlessSample(name, crop, transform = []) {
  const quadrant = file(`${name}-quadrant`);
  const horizontal = file(`${name}-horizontal`);
  run([source, "-crop", crop, "+repage", "-resize", "16x16!", ...transform, `PNG32:${quadrant}`]);
  run(["-size", "32x16", "canvas:none", quadrant, "-geometry", "+0+0", "-composite", "(", quadrant, "-flop", ")", "-geometry", "+16+0", "-composite", `PNG32:${horizontal}`]);
  run(["-size", "32x32", "canvas:none", horizontal, "-geometry", "+0+0", "-composite", "(", horizontal, "-flip", ")", "-geometry", "+0+16", "-composite", `PNG32:${file(name)}`]);
}

function transparent(name) {
  run(["-size", "32x32", "canvas:none", `PNG32:${file(name)}`]);
}

function maskTexture(name, texture, draw) {
  const mask = file(`${name}-mask`);
  run(["-size", "32x32", "xc:black", "-fill", "white", "-draw", draw, mask]);
  run([file(texture), mask, "-alpha", "off", "-compose", "CopyOpacity", "-composite", `PNG32:${file(name)}`]);
}

seamlessSample("grass-a", "32x32+230+1400");
seamlessSample("grass-b", "32x32+285+1410", ["-modulate", "96,103,100"]);
seamlessSample("lawn", "32x32+250+1430", ["-modulate", "106,102,100"]);
seamlessSample("stone", "32x32+720+1920");
seamlessSample("water-a", "32x32+730+950", ["-fuzz", "45%", "-transparent", "#ff00ff", "-background", "#317b88", "-alpha", "remove", "-alpha", "off", "-modulate", "103,108,100"]);
run([file("water-a"), "-roll", "+7+11", "-modulate", "97,104,100", `PNG32:${file("water-b")}`]);
sample("track", "64x64+1160+1380");
sample("court", "64x64+1320+1390");

for (let index = 4; index <= 7; index += 1) transparent(`blank-${index}`);
for (let index = 21; index <= 23; index += 1) transparent(`blank-${index}`);
for (let index = 24; index <= 25; index += 1) transparent(`blank-${index}`);

maskTexture("path-h", "stone", "rectangle 0,10 31,21");
run([file("path-h"), "-stroke", "#7e7b70", "-strokewidth", "1", "-draw", "line 0,9 31,9 line 0,22 31,22", `PNG32:${file("path-h")}`]);
run([file("path-h"), "-rotate", "90", `PNG32:${file("path-v")}`]);

run(["-size", "32x20", "xc:#4e5557", "-seed", "755", "-attenuate", "0.08", "+noise", "Gaussian", `PNG32:${file("asphalt")}`]);
run(["-size", "32x32", "canvas:none", file("asphalt"), "-geometry", "+0+6", "-composite", "-stroke", "#d4d0c1", "-strokewidth", "2", "-draw", "line 0,5 31,5 line 0,26 31,26", "-stroke", "#e4ce69", "-strokewidth", "1", "-draw", "line 2,16 8,16 line 13,16 19,16 line 24,16 30,16", `PNG32:${file("road-h")}`]);
run([file("road-h"), "-rotate", "90", `PNG32:${file("road-v")}`]);
run(["-size", "32x32", "canvas:none", file("road-h"), "-composite", file("road-v"), "-composite", `PNG32:${file("road-cross")}`]);
run([file("road-h"), "-distort", "SRT", "0", `PNG32:${file("road-corner-a")}`]);
run([file("road-v"), "-distort", "SRT", "0", `PNG32:${file("road-corner-b")}`]);

maskTexture("bank-n", "water-a", "rectangle 0,6 31,31");
run([file("bank-n"), "-fill", "#c8bea2", "-draw", "rectangle 0,4 31,6", "-fill", "#62735b", "-draw", "rectangle 0,7 31,8", `PNG32:${file("bank-n")}`]);
maskTexture("bank-s", "water-b", "rectangle 0,0 31,25");
run([file("bank-s"), "-fill", "#62735b", "-draw", "rectangle 0,23 31,24", "-fill", "#c8bea2", "-draw", "rectangle 0,25 31,27", `PNG32:${file("bank-s")}`]);
maskTexture("bank-w", "water-a", "rectangle 6,0 31,31");
run([file("bank-w"), "-fill", "#c8bea2", "-draw", "rectangle 4,0 6,31", "-fill", "#62735b", "-draw", "rectangle 7,0 8,31", `PNG32:${file("bank-w")}`]);
maskTexture("bank-e", "water-b", "rectangle 0,0 25,31");
run([file("bank-e"), "-fill", "#62735b", "-draw", "rectangle 23,0 24,31", "-fill", "#c8bea2", "-draw", "rectangle 25,0 27,31", `PNG32:${file("bank-e")}`]);

run([file("grass-b"), "-modulate", "84,82,100", `PNG32:${file("dirt")}`]);
run(["-size", "32x32", "canvas:none", "-fill", "#5d804b", "-draw", "rectangle 0,0 31,31", "-fill", "#d87974", "-draw", "circle 7,8 9,8 circle 21,11 23,11", "-fill", "#e7c66d", "-draw", "circle 14,22 16,22", "-fill", "#87a965", "-draw", "rectangle 6,9 7,16 rectangle 20,12 21,20 rectangle 13,23 14,29", `PNG32:${file("flowers")}`]);
run(["-size", "32x32", "canvas:none", "-fill", "#54794a", "-draw", "rectangle 0,0 31,31", "-stroke", "#9bb777", "-strokewidth", "2", "-draw", "line 3,30 8,10 line 10,30 14,5 line 17,30 21,12 line 24,30 29,7", `PNG32:${file("reeds")}`]);
run([file("lawn"), "-stroke", "#9ab77b", "-strokewidth", "2", "-draw", "line 0,5 31,5 line 0,14 31,14 line 0,23 31,23", `PNG32:${file("lawn-stripe")}`]);

const orderedTiles = [
  "grass-a", "grass-b", "lawn", "stone",
  "blank-4", "blank-5", "blank-6", "blank-7",
  "path-h", "path-v", "road-h", "road-v", "road-cross", "road-corner-a", "road-corner-b", "water-a",
  "water-b", "bank-n", "bank-s", "bank-w", "bank-e", "blank-21", "blank-22", "blank-23",
  "blank-24", "blank-25", "track", "court", "dirt", "flowers", "reeds", "lawn-stripe"
];

const compositeArgs = ["-size", "256x128", "canvas:none"];
orderedTiles.forEach((name, index) => {
  compositeArgs.push(file(name), "-geometry", `+${index % 8 * 32}+${Math.floor(index / 8) * 32}`, "-composite");
});
compositeArgs.push(`PNG32:${output}`);
run(compositeArgs);
rmSync(temporary, { recursive: true, force: true });
process.stdout.write(`${output}\n`);
