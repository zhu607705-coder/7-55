import { createHash } from "node:crypto";
import { existsSync, readFileSync, statSync, writeFileSync } from "node:fs";
import { join, dirname } from "node:path";
import { fileURLToPath } from "node:url";

const root = dirname(fileURLToPath(import.meta.url));
const matrix = JSON.parse(readFileSync(join(root, "style-matrix.json"), "utf8"));
const hash = (path) => createHash("sha256").update(readFileSync(path)).digest("hex");
const checkVariant = (variant) => {
  const absolute = join(root, variant.path);
  const present = existsSync(absolute) && statSync(absolute).size > 0;
  return { ...variant, present, ...(present ? { bytes: statSync(absolute).size, sha256: hash(absolute) } : {}) };
};
const sections = {};
const missing = [];
let primaryCount = 0;
function collect(section, entries) {
  sections[section] = entries.map((entry) => {
    const variants = Object.fromEntries(Object.entries(entry.variants).map(([style, variant]) => {
      const checked = checkVariant(variant);
      primaryCount += 1;
      if (!checked.present) missing.push(`${section}:${entry.id}:${style}:${checked.path}`);
      return [style, checked];
    }));
    return { id: entry.id, sourcePath: entry.sourcePath || entry.source, variants, legacyVariant: entry.legacyVariant };
  });
}
collect("visual", matrix.visual);
collect("music", matrix.audio.music);
collect("voice", matrix.audio.voice);
collect("sfx", matrix.audio.sfx);
collect("text", matrix.text);

const statusCounts = {};
for (const section of Object.values(sections)) for (const entry of section) for (const variant of Object.values(entry.variants)) statusCounts[variant.status] = (statusCounts[variant.status] || 0) + 1;
const report = {
  version: 1,
  generatedAt: new Date().toISOString(),
  integration: "none",
  styleKeys: {
    visual: Object.keys(matrix.styles),
    music: Object.keys(matrix.audioStyles.music),
    voice: Object.keys(matrix.audioStyles.voice),
    sfx: Object.keys(matrix.audioStyles.sfx),
    text: Object.keys(matrix.textStyles)
  },
  conceptCounts: Object.fromEntries(Object.entries(sections).map(([key, value]) => [key, value.length])),
  primaryVariantCount: primaryCount,
  statusCounts,
  missing,
  sections,
  requirement: "每个概念恰好列出三种主风格；legacyVariant 只作为额外历史候选，不计入主风格覆盖。"
};
writeFileSync(join(root, "reports/style-coverage.json"), `${JSON.stringify(report, null, 2)}\n`);
console.log(JSON.stringify({ conceptCounts: report.conceptCounts, primaryVariantCount: report.primaryVariantCount, statusCounts, missing: missing.length }));
if (missing.length) process.exitCode = 1;
