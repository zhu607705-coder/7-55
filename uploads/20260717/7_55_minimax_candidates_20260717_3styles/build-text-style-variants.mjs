import { existsSync, mkdirSync, readdirSync, readFileSync, statSync, writeFileSync } from "node:fs";
import { join, dirname } from "node:path";
import { createHash } from "node:crypto";
import { fileURLToPath } from "node:url";

const root = dirname(fileURLToPath(import.meta.url));
const validDir = join(root, "text/valid");
const styles = {
  plain_case: {
    labelZh: "平实调查",
    delivery: "保持原文事实和句式，适合纸质证据、帖子正文和调查记录。",
    selection: "信息密度优先，避免额外情绪。"
  },
  dry_campus: {
    labelZh: "校园冷幽默",
    delivery: "保持事实不变，允许短句停顿、克制吐槽和校园论坛口吻；不提前公布答案。",
    selection: "适合男旁白、普通回复、操作反馈和剧情过场。"
  },
  procedural_minimal: {
    labelZh: "系统短句",
    delivery: "将同一信息压缩为可放进任务栏或系统提示的短句，优先动作、对象和状态。",
    selection: "适合任务键、进度栏、错误反馈和无障碍描述。"
  }
};

function hash(value) { return createHash("sha256").update(value).digest("hex"); }
function readJson(path) { return JSON.parse(readFileSync(path, "utf8")); }
function writeJson(path, value) { mkdirSync(dirname(path), { recursive: true }); writeFileSync(path, `${JSON.stringify(value, null, 2)}\n`); }

const validFiles = readdirSync(validDir).filter((file) => file.endsWith(".json")).map((file) => `valid/${file}`);
const rootFiles = readdirSync(join(root, "text")).filter((file) => file.endsWith(".json") && file !== "selected-index.json" && file !== "style-variants.json").map((file) => file);
const sourceFiles = [...validFiles, ...rootFiles].sort();
const entries = [];
for (const relativeFile of sourceFiles) {
  const source = `text/${relativeFile}`;
  const original = readJson(join(root, source));
  const contentHash = hash(JSON.stringify(original));
  const variants = {};
  for (const [style, definition] of Object.entries(styles)) {
    const candidate = {
      _candidateMeta: {
        style,
        styleLabelZh: definition.labelZh,
        delivery: definition.delivery,
        selection: definition.selection,
        source,
        sourceSha256: contentHash,
        contentPolicy: "事实字段保持一致；差异通过语气、节奏、排版和展示组件实现"
      },
      ...original
    };
    const output = `text/styles/${style}/${relativeFile}`;
    writeJson(join(root, output), candidate);
    variants[style] = { path: output, status: "generated", sourceSha256: contentHash, bytes: statSync(join(root, output)).size, sha256: hash(readFileSync(join(root, output))) };
  }
  entries.push({ id: relativeFile.replace(/\.json$/, ""), source, variants });
}

const result = { version: 1, generatedAt: new Date().toISOString(), integration: "none", styles, entries };
writeJson(join(root, "text/style-variants.json"), result);
writeJson(join(root, "reports/text-style-manifest.json"), result);
const matrixPath = join(root, "style-matrix.json");
if (existsSync(matrixPath)) {
  const matrix = readJson(matrixPath);
  matrix.textStyles = styles;
  matrix.text = entries;
  matrix.generatedAt = result.generatedAt;
  writeJson(matrixPath, matrix);
}
console.log(`text concepts=${entries.length} variants=${entries.length * Object.keys(styles).length}`);
