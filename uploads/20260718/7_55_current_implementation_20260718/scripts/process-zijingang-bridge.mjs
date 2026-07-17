import { mkdirSync, rmSync } from "node:fs";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { spawnSync } from "node:child_process";

const root = resolve(dirname(fileURLToPath(import.meta.url)), "..");
const source = join(root, "src/assets/rpg/props/zijingang_environment.png");
const output = join(root, "src/assets/rpg/props/qizhen_bridge_segment.png");
const temporary = join(root, ".tmp-zijingang-bridge");

function run(args) {
  const result = spawnSync("magick", args, { encoding: "utf8" });
  if (result.status !== 0) {
    throw new Error(result.stderr || `ImageMagick failed: ${args.join(" ")}`);
  }
}

mkdirSync(temporary, { recursive: true });
const frame = join(temporary, "frame.png");
const sourceAlpha = join(temporary, "source-alpha.png");
const stoneMask = join(temporary, "stone-mask.png");
const finalMask = join(temporary, "final-mask.png");
const isolated = join(temporary, "isolated.png");
const rotated = join(temporary, "rotated.png");
const leftCap = join(temporary, "left-cap.png");
const centerDeck = join(temporary, "center-deck.png");
const rightCap = join(temporary, "right-cap.png");

run([source, "-crop", "512x512+512+1536", "+repage", `PNG32:${frame}`]);
run([frame, "-alpha", "extract", sourceAlpha]);

// Generated frame 13 contains blue water beneath the bridge. Stone pixels stay
// warm-neutral (red >= blue), so this mask removes the baked water while
// preserving the textured deck, railings and their dark neutral shadows.
run([frame, "-alpha", "off", "-fx", "b <= r+0.025 ? 1 : 0", stoneMask]);
run([sourceAlpha, stoneMask, "-compose", "multiply", "-composite", finalMask]);
run([
  frame,
  finalMask,
  "-compose", "CopyAlpha",
  "-composite",
  "-trim",
  "+repage",
  `PNG32:${isolated}`
]);

// Rotate the source bridge onto the east-west Tiled corridor.
run([
  isolated,
  "-background", "none",
  "-filter", "point",
  "-rotate", "29",
  "-trim",
  "+repage",
  `PNG32:${rotated}`
]);

// Preserve both bridgeheads and lengthen only the central deck. The resulting
// 430x132 model has one continuous railing and tile grid with no runtime seam.
run([rotated, "-crop", "70x132+0+0", "+repage", `PNG32:${leftCap}`]);
run([
  rotated,
  "-crop", "128x132+70+0",
  "+repage",
  "-filter", "point",
  "-resize", "290x132!",
  `PNG32:${centerDeck}`
]);
run([rotated, "-crop", "70x132+198+0", "+repage", `PNG32:${rightCap}`]);
run([leftCap, centerDeck, rightCap, "+append", `PNG32:${output}`]);

rmSync(temporary, { recursive: true, force: true });
process.stdout.write(`${output}\n`);
