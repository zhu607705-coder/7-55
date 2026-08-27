import fs from "node:fs";
import path from "node:path";
import process from "node:process";
import ts from "typescript";

const ROOT = process.cwd();
const SOURCE_ROOT = path.join(ROOT, "src");
const OUTPUT_PATH = path.join(ROOT, "docs", "game-text-by-chapter.md");
const CHECK_ONLY = process.argv.includes("--check");

const CHAPTERS = [
  ["chapter_one", "第一章"],
  ["chapter_two", "第二章"],
  ["chapter_three", "第三章"],
  ["chapter_three_half", "3.5章过渡"],
  ["chapter_four", "第四章"],
  ["ending", "结局"],
  ["shared", "跨章节与共用系统"]
];

const VISIBLE_CONTEXT_KEYS = new Set([
  "alt", "aria-label", "ariaLabel", "body", "caption", "content", "copy",
  "description", "detail", "dialogue", "feedback", "heading", "hint", "label",
  "message", "name", "nextAction", "objective", "placeholder", "prompt", "reason",
  "speaker", "status", "subtitle", "subtitleZh", "summary", "text", "title", "toast",
  "voiceTextEn", "revealZh", "labelZh", "code", "time"
]);

const PRODUCTION_ONLY_KEYS = new Set([
  "deliveryPromptZh", "productionPrompt", "eventEmphasisZh", "distanceZh",
  "decoyOverlapZh", "genre", "mood", "instruments"
]);

const AUDIO_CONTENT_VISIBLE_KEYS = new Set([
  "subtitleZh", "voiceTextEn", "revealZh", "labelZh", "code", "time"
]);

const EXCLUDED_FILE_PATTERNS = [
  /\.d\.ts$/,
  /\/src\/tools\//,
  /\/DeveloperChannel\.(ts|tsx)$/,
  /\/[^/]*Debug[^/]*\.(ts|tsx)$/,
  /\/RpgRuntimeDebug\.ts$/,
  /\/RpgRuntimePreload\.ts$/,
  /\/RpgAssetLoader\.ts$/,
  /\/ClientCompatibility\.ts$/,
  /\/SaveStore\.ts$/,
  /\/StorageKeys\.ts$/,
  /\/maps\/.*\.json$/,
  /\.audio\.generated\.json$/,
  /\/vo\.map\.json$/
];

const entriesByChapter = new Map(CHAPTERS.map(([id]) => [id, new Map()]));

for (const absolutePath of walkFiles(SOURCE_ROOT)) {
  const relativePath = normalizePath(path.relative(ROOT, absolutePath));
  if (EXCLUDED_FILE_PATTERNS.some((pattern) => pattern.test(`/${relativePath}`))) continue;
  const extension = path.extname(absolutePath);
  if (![".ts", ".tsx", ".json"].includes(extension)) continue;
  extractFile(absolutePath, relativePath);
}

validateEntries();
const generated = renderMarkdown();
if (CHECK_ONLY) {
  if (!fs.existsSync(OUTPUT_PATH)) {
    console.error(`Game text export missing: ${normalizePath(path.relative(ROOT, OUTPUT_PATH))}`);
    process.exit(1);
  }
  const current = fs.readFileSync(OUTPUT_PATH, "utf8");
  if (current !== generated) {
    console.error("Game text export is stale. Run npm run text:export.");
    process.exit(1);
  }
  console.log(summaryLine("verified"));
} else {
  fs.writeFileSync(OUTPUT_PATH, generated, "utf8");
  console.log(summaryLine("exported"));
}

function extractFile(absolutePath, relativePath) {
  const sourceText = fs.readFileSync(absolutePath, "utf8");
  const scriptKind = relativePath.endsWith(".tsx")
    ? ts.ScriptKind.TSX
    : relativePath.endsWith(".json")
      ? ts.ScriptKind.JSON
      : ts.ScriptKind.TS;
  const sourceFile = ts.createSourceFile(
    relativePath,
    sourceText,
    ts.ScriptTarget.Latest,
    true,
    scriptKind
  );
  const defaultChapter = classifyFile(relativePath);

  visit(sourceFile);

  function visit(node) {
    if (ts.isJsxText(node)) {
      addCandidate(node.getText(sourceFile), node, null, true);
    } else if (ts.isTemplateExpression(node)) {
      addCandidate(renderTemplate(node, sourceFile), node, contextKey(node), false);
      return;
    } else if (ts.isNoSubstitutionTemplateLiteral(node)) {
      addCandidate(node.text, node, contextKey(node), false);
    } else if (ts.isStringLiteral(node)) {
      if (!isPropertyName(node) && !isModuleSpecifier(node)) {
        addCandidate(node.text, node, contextKey(node), false);
      }
    }
    ts.forEachChild(node, visit);
  }

  function addCandidate(rawText, node, key, jsxText) {
    const text = normalizeText(rawText);
    if (!isPlayerFacingCandidate(text, node, key, jsxText, relativePath)) return;
    const line = sourceFile.getLineAndCharacterOfPosition(node.getStart(sourceFile)).line + 1;
    const chapter = refineChapter(defaultChapter, relativePath, sourceText, node.getStart(sourceFile), text);
    const chapterEntries = entriesByChapter.get(chapter);
    const normalizedKey = text.toLocaleLowerCase("zh-CN");
    const existing = chapterEntries.get(normalizedKey) ?? { text, sources: [] };
    if (!existing.sources.some((source) => source.file === relativePath && source.line === line)) {
      existing.sources.push({ file: relativePath, line });
    }
    chapterEntries.set(normalizedKey, existing);
  }
}

function isPlayerFacingCandidate(text, node, key, jsxText, relativePath) {
  if (!text || text.length === 1 && /^[{}()[\],.:;]$/.test(text)) return false;
  if (PRODUCTION_ONLY_KEYS.has(key ?? "")) return false;
  if (/\.audio\.content\.json$/.test(relativePath) && !AUDIO_CONTENT_VISIBLE_KEYS.has(key ?? "")) {
    return false;
  }
  if (/<(?:style|main|section|div|canvas)\b|debug-shell|color-scheme\s*:/i.test(text)) return false;
  if (/^(https?:|data:|file:|src\/|assets\/|audio\/|image\/)/i.test(text)) return false;
  if (/^[a-z0-9_.:/-]+$/i.test(text) && !VISIBLE_CONTEXT_KEYS.has(key ?? "")) return false;
  if (/^(rgb|hsl)a?\(|^#[0-9a-f]{3,8}$/i.test(text)) return false;
  if (isInsideImportLikeCall(node)) return false;
  if (/console\.(log|warn|error)|throw new Error/.test(node.parent?.getText?.() ?? "")) return false;
  if (/\p{Script=Han}/u.test(text)) return true;
  if (jsxText) return /[A-Za-z0-9]/.test(text);
  return VISIBLE_CONTEXT_KEYS.has(key ?? "") && /[A-Za-z0-9]/.test(text);
}

function classifyFile(relativePath) {
  const value = relativePath.toLowerCase();
  if (/p12_ending|endingruntime|\/ending/.test(value)) return "ending";
  if (/chapter3[-_]?interlude|chapterthreeinterlude|p20_timeline|p21_voicememos/.test(value)) {
    return "chapter_three_half";
  }
  if (/chapter4|chapter-four|chapterfour|temporal-maze|temporal_maze|p19_clock/.test(value)) {
    return "chapter_four";
  }
  if (/chapter3|chapterthree|qizhen|canteen|theater|p18_photos/.test(value)) {
    return "chapter_three";
  }
  if (/library|p04_campuscard/.test(value)) return "chapter_two";
  if (/act-one|actone|dormhub|p00_alarm|p01_desktop|p06_tiyi|p10_bonsai|p11_checkin|unifiedidentitylogin|ac01filter|controlexchange|toptenrise/.test(value)) {
    return "chapter_one";
  }
  return "shared";
}

function refineChapter(defaultChapter, relativePath, sourceText, position, text) {
  if (defaultChapter !== "shared") return defaultChapter;
  const nearby = sourceText.slice(Math.max(0, position - 900), Math.min(sourceText.length, position + 250));
  if (/chapterThreeInterlude|chapter_three_interlude|第三章半|3\.5章/.test(nearby)) return "chapter_three_half";
  if (/chapter4|chapter_four|chapter-four|第四章/.test(nearby)) return "chapter_four";
  if (/chapter3|chapter_three|chapter-three|第三章/.test(nearby)) return "chapter_three";
  if (/chapter2|chapter_two|chapter-two|第二章/.test(nearby)) return "chapter_two";
  if (/chapter1|chapter_one|chapter-one|第一章/.test(nearby)) return "chapter_one";
  if (/结局|通关|ending/i.test(`${nearby} ${text}`)) return "ending";
  return "shared";
}

function renderMarkdown() {
  const totalEntries = [...entriesByChapter.values()].reduce((sum, entries) => sum + entries.size, 0);
  const totalSources = new Set(
    [...entriesByChapter.values()].flatMap((entries) => [...entries.values()])
      .flatMap((entry) => entry.sources.map((source) => source.file))
  ).size;
  const lines = [
    "# 《7:55》游戏文本总表",
    "",
    "> 本文件由 `npm run text:export` 从当前 `src/` 自动生成。请修改源文件后重新导出，不要只修改本文件。",
    "",
    `- 文本条目：${totalEntries}`,
    `- 来源文件：${totalSources}`,
    "- 收录范围：剧情对白、字幕、任务说明、交互提示、按钮、页面标题、帖子、物品说明、失败反馈与玩家可见状态文案。",
    "- 排除范围：开发者面板、测试断言、内部 ID、CSS 类名、资源路径、存档字段和运行时调试信息。",
    "- 去重规则：同一章节内完全相同的文本合并为一条，全部源码位置仍保留。",
    "- 模板规则：动态表达式显示为 `{{表达式}}`。",
    "",
    "## 章节索引",
    "",
    "| 章节 | 文本条目 |",
    "| --- | ---: |"
  ];

  for (const [chapterId, chapterLabel] of CHAPTERS) {
    lines.push(`| [${chapterLabel}](#${markdownAnchor(chapterLabel)}) | ${entriesByChapter.get(chapterId).size} |`);
  }

  for (const [chapterId, chapterLabel] of CHAPTERS) {
    const entries = [...entriesByChapter.get(chapterId).values()]
      .sort((a, b) => compareSources(a.sources[0], b.sources[0]) || a.text.localeCompare(b.text, "zh-CN"));
    lines.push("", `## ${chapterLabel}`, "");
    if (entries.length === 0) {
      lines.push("_当前没有提取到文本。_", "");
      continue;
    }
    entries.forEach((entry, index) => {
      lines.push(`${index + 1}. ${escapeMarkdown(entry.text)}`);
      lines.push(`   来源：${entry.sources.sort(compareSources).map(renderSourceLink).join("；")}`);
    });
  }

  lines.push("");
  return `${lines.join("\n")}\n`;
}

function validateEntries() {
  const forbidden = [
    [/<style|debug-shell/i, "embedded debug HTML"],
    [/\/src\/tools\//, "debug tool source"],
    [/\/DeveloperChannel\.(ts|tsx)$/, "developer channel source"],
    [/deliveryPromptZh|productionPrompt|eventEmphasisZh|decoyOverlapZh/, "audio production prompt"]
  ];
  for (const entries of entriesByChapter.values()) {
    for (const entry of entries.values()) {
      const sourceText = entry.sources.map((source) => source.file).join(" ");
      for (const [pattern, label] of forbidden) {
        if (pattern.test(`${entry.text} ${sourceText}`)) {
          throw new Error(`Game text export contains ${label}: ${entry.text.slice(0, 120)}`);
        }
      }
    }
  }
}

function renderSourceLink(source) {
  const target = `../${source.file}#L${source.line}`;
  return `[${source.file}:${source.line}](${encodeURI(target)})`;
}

function renderTemplate(node, sourceFile) {
  let value = node.head.text;
  for (const span of node.templateSpans) {
    const expression = span.expression.getText(sourceFile).replace(/\s+/g, " ").trim();
    value += `{{${expression}}}${span.literal.text}`;
  }
  return value;
}

function contextKey(node) {
  const parent = node.parent;
  if (!parent) return null;
  if (ts.isPropertyAssignment(parent) && parent.initializer === node) return propertyName(parent.name);
  if (ts.isJsxAttribute(parent)) return parent.name.getText();
  if (ts.isCallExpression(parent)) {
    const callName = parent.expression.getText();
    if (/toast|subtitle|feedback|announce|dialogue/i.test(callName)) return "message";
  }
  return contextKey(parent);
}

function propertyName(node) {
  if (ts.isIdentifier(node) || ts.isPrivateIdentifier(node)) return node.text;
  if (ts.isStringLiteral(node) || ts.isNumericLiteral(node)) return node.text;
  return node.getText().replace(/["']/g, "");
}

function isPropertyName(node) {
  const parent = node.parent;
  return Boolean(
    parent
    && (ts.isPropertyAssignment(parent) || ts.isMethodDeclaration(parent) || ts.isPropertySignature(parent))
    && parent.name === node
  );
}

function isModuleSpecifier(node) {
  const parent = node.parent;
  return Boolean(parent && (
    (ts.isImportDeclaration(parent) || ts.isExportDeclaration(parent)) && parent.moduleSpecifier === node
  ));
}

function isInsideImportLikeCall(node) {
  let cursor = node.parent;
  while (cursor && !ts.isStatement(cursor)) {
    if (ts.isCallExpression(cursor) && /^(require|import)$/.test(cursor.expression.getText())) return true;
    cursor = cursor.parent;
  }
  return false;
}

function normalizeText(value) {
  return String(value)
    .replace(/\r\n?/g, "\n")
    .split("\n")
    .map((line) => line.trim())
    .filter(Boolean)
    .join(" / ")
    .replace(/\s+/g, " ")
    .trim();
}

function escapeMarkdown(value) {
  return value
    .replace(/\\/g, "\\\\")
    .replace(/([\[\]*_`])/g, "\\$1")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/\|/g, "\\|");
}

function markdownAnchor(value) {
  return value.toLowerCase().replace(/\s+/g, "-").replace(/[^\p{Letter}\p{Number}-]/gu, "");
}

function compareSources(a, b) {
  return a.file.localeCompare(b.file) || a.line - b.line;
}

function walkFiles(directory) {
  const files = [];
  for (const entry of fs.readdirSync(directory, { withFileTypes: true })) {
    const absolutePath = path.join(directory, entry.name);
    if (entry.isDirectory()) files.push(...walkFiles(absolutePath));
    else if (entry.isFile()) files.push(absolutePath);
  }
  return files.sort();
}

function normalizePath(value) {
  return value.split(path.sep).join("/");
}

function summaryLine(action) {
  const counts = CHAPTERS.map(([id, label]) => `${label}=${entriesByChapter.get(id).size}`).join(" ");
  const total = [...entriesByChapter.values()].reduce((sum, entries) => sum + entries.size, 0);
  return `Game text ${action}: total=${total} ${counts} output=${normalizePath(path.relative(ROOT, OUTPUT_PATH))}`;
}
