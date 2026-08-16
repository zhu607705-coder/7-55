import { execFileSync } from "node:child_process";
import { mkdirSync, readdirSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const repoRoot = join(dirname(fileURLToPath(import.meta.url)), "..");
const sourceDir = join(repoRoot, "src/assets/rpg/cinematics/chapter4-prologue");
const outputDir = join(sourceDir, "pixel");
const portraitSourceDir = join(repoRoot, "src/assets/rpg/portraits/finale");
const portraitOutputDir = join(portraitSourceDir, "runtime");
const scenePattern = /^(snap|lake_exit|arcade|entrance|lobby|closing)_[ab]\.png$/;
const portraitPattern = /^(cleaner|guard|departing_student)_[ab]\.png$/;

mkdirSync(outputDir, { recursive: true });
mkdirSync(portraitOutputDir, { recursive: true });

for (const filename of readdirSync(sourceDir).filter((name) => scenePattern.test(name)).sort()) {
  const source = join(sourceDir, filename);
  const output = join(outputDir, filename);
  execFileSync("magick", [
    source,
    "-colorspace", "sRGB",
    "-filter", "Lanczos",
    "-resize", "480x270!",
    "-brightness-contrast", "14x8",
    "-gamma", "1.12",
    "-modulate", "108,112,100",
    "-unsharp", "0x0.7",
    "-dither", "None",
    "-colors", "72",
    "-filter", "point",
    "-resize", "960x540!",
    "-strip",
    output
  ]);
  process.stdout.write(`built ${filename}\n`);
}

for (const filename of readdirSync(portraitSourceDir).filter((name) => portraitPattern.test(name)).sort()) {
  const source = join(portraitSourceDir, filename);
  const output = join(portraitOutputDir, filename);
  execFileSync("magick", [
    source,
    "-alpha", "on",
    "-channel", "A",
    "-fx", "((r>0.22)&&(b>0.22)&&(g<0.48)&&(r>g*1.28)&&(b>g*1.28))?0:a",
    "+channel",
    "-trim", "+repage",
    "-filter", "point",
    "-resize", "280x300>",
    "-gravity", "south",
    "-background", "none",
    "-extent", "300x310",
    "-strip",
    output
  ]);
  process.stdout.write(`built portrait ${filename}\n`);
}
