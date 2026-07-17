import { existsSync, mkdirSync, readFileSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const root = dirname(fileURLToPath(import.meta.url));
const plan = JSON.parse(readFileSync(join(root, "generation-plan.json"), "utf8"));

const styles = {
  classic_pixel: {
    labelZh: "经典像素校园",
    description: "16-bit strict top-down/cardinal pixel art, crisp tile grid, restrained campus palette, readable silhouettes, no perspective drift, no text",
    use: "地图、场景和角色的默认基准"
  },
  paper_archive: {
    labelZh: "档案纸张",
    description: "two-tone campus archive print, paper grain, risograph blocks, navy ink and warm ivory paper, flat orthographic/cardinal composition, clean blank areas, no readable text",
    use: "纸质道具、调查证据和可读界面的备选"
  },
  rainy_scanline: {
    labelZh: "雨夜扫描线",
    description: "dark navy and cyan CRT scanline pixel art, restrained yellow evidence accents, rainy university morning atmosphere, high contrast but legible, orthographic/cardinal composition, no readable text",
    use: "雨天、系统界面和悬疑场景的备选"
  }
};

function dimensionsFor(path) {
  if (path.includes("/phone/")) return [768, 1536];
  if (path.includes("/rpg/") && path.includes("sports")) return [1024, 1024];
  if (path.includes("/rpg/") || path.includes("/characters/")) return [1536, 864];
  if (path.includes("/props/") && !path.includes("attachment_slots")) return [1024, 1024];
  return [1280, 960];
}

function slugFor(path) {
  return path.replace(/^images\//, "").replace(/_candidate_a\.png$/, "");
}

function stylePrompt(basePrompt, styleKey, path) {
  const style = styles[styleKey];
  const subjectGuard = path.includes("/rpg/")
    ? "Keep the whole game-space layout readable and strictly top-down or cardinal; buildings must not become isometric."
    : path.includes("/phone/")
      ? "Keep a single complete 9:16 phone composition with aligned cards, empty locked slots, and no invented UI text."
      : "Keep each object or panel separated, front-facing, and usable as a game asset; do not add captions or fake glyphs.";
  return `${basePrompt}; ${style.description}; ${subjectGuard}`;
}

const visuals = plan.visualCandidates
  .filter(([path]) => path.endsWith("_candidate_a.png"))
  .map(([path, basePrompt]) => {
    const slug = slugFor(path);
    const legacy = path.replace(/_candidate_a\.png$/, "_candidate_b.png");
    const entry = {
      id: slug,
      category: path.split("/")[1],
      sourcePrompt: basePrompt,
      dimensions: dimensionsFor(path),
      variants: {
        classic_pixel: { path, status: existsSync(join(root, path)) ? "existing" : "missing" },
        paper_archive: {
          path: `images/styles/paper_archive/${slug}__paper_archive.png`,
          prompt: stylePrompt(basePrompt, "paper_archive", path),
          status: existsSync(join(root, `images/styles/paper_archive/${slug}__paper_archive.png`)) ? "existing" : "planned"
        },
        rainy_scanline: {
          path: `images/styles/rainy_scanline/${slug}__rainy_scanline.png`,
          prompt: stylePrompt(basePrompt, "rainy_scanline", path),
          status: existsSync(join(root, `images/styles/rainy_scanline/${slug}__rainy_scanline.png`)) ? "existing" : "planned"
        }
      }
    };
    if (existsSync(join(root, legacy))) entry.legacyVariant = { path: legacy, label: "旧像素变体" };
    return entry;
  });

const matrix = {
  version: 1,
  generatedAt: new Date().toISOString(),
  integration: "none",
  rule: "每个素材概念至少提供 classic_pixel、paper_archive、rainy_scanline 三种可选择风格；未选中的候选继续隔离，不接入运行时。",
  styles,
  visual: visuals,
  audio: { music: [], voice: [], sfx: [] },
  text: []
};

mkdirSync(join(root, "reports"), { recursive: true });
writeFileSync(join(root, "style-matrix.json"), `${JSON.stringify(matrix, null, 2)}\n`);
process.stdout.write(`visual concepts=${visuals.length}\n`);
