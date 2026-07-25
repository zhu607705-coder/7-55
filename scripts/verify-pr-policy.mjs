import { appendFile } from "node:fs/promises";

const title = (process.env.PR_TITLE ?? "").trim();
const body = process.env.PR_BODY ?? "";
const changedFiles = toNonNegativeInteger(process.env.PR_CHANGED_FILES);
const additions = toNonNegativeInteger(process.env.PR_ADDITIONS);
const deletions = toNonNegativeInteger(process.env.PR_DELETIONS);
const totalChangedLines = additions + deletions;

const errors = [];
const warnings = [];

const titlePattern = /^(feat|fix|docs|refactor|test|perf|build|ci|chore|revert|hotfix)(\([a-z0-9._/-]+\))?:\s+\S.{2,}$/i;
if (!titlePattern.test(title)) {
  errors.push("PR 标题需使用 `<type>(<scope>): <说明>`，例如 `test(ci): 增加第三章回归测试`。");
}

const requiredHeadings = [
  "## 改动",
  "## 原因",
  "## 验证",
  "## 风险与回滚",
  "## 未覆盖"
];

for (const heading of requiredHeadings) {
  if (!body.includes(heading)) {
    errors.push(`PR 正文缺少必需章节：${heading}`);
  }
}

const visibleBody = body
  .replace(/<!--[\s\S]*?-->/g, "")
  .replace(/^\s*[-*]\s*$/gm, "")
  .trim();
if (visibleBody.length < 80) {
  errors.push("PR 正文信息不足，请填写实际改动、原因、验证结果、风险和未覆盖项。");
}

const isLargePullRequest = changedFiles > 30 || totalChangedLines > 1500;
if (isLargePullRequest) {
  const largeSection = readSection(body, "## 大型 PR 拆分说明");
  if (!largeSection || /^(不适用|无|n\/a)[。.!\s]*$/i.test(stripComments(largeSection))) {
    errors.push(
      `该 PR 共有 ${changedFiles} 个文件、${totalChangedLines} 行增删，必须填写“## 大型 PR 拆分说明”。`
    );
  }
}

if (changedFiles > 20 || totalChangedLines > 800) {
  warnings.push(
    `PR 规模高于推荐值：${changedFiles} 个文件、${totalChangedLines} 行增删。请再次确认是否可拆分。`
  );
}

const summary = [
  "# PR metadata contract",
  "",
  `- 标题：\`${escapeMarkdown(title || "<empty>")}\``,
  `- 文件数：${changedFiles}`,
  `- 增删行：${totalChangedLines}`,
  `- 大型 PR：${isLargePullRequest ? "是" : "否"}`,
  `- 错误：${errors.length}`,
  `- 提醒：${warnings.length}`,
  ""
];

if (warnings.length > 0) {
  summary.push("## 提醒", "", ...warnings.map((warning) => `- ${warning}`), "");
  warnings.forEach((warning) => console.warn(`warning: ${warning}`));
}

if (errors.length > 0) {
  summary.push("## 必须修正", "", ...errors.map((error) => `- ${error}`), "");
  errors.forEach((error) => console.error(`error: ${error}`));
} else {
  summary.push("PR 标题、正文结构和规模说明符合仓库契约。", "");
}

if (process.env.GITHUB_STEP_SUMMARY) {
  await appendFile(process.env.GITHUB_STEP_SUMMARY, `${summary.join("\n")}\n`, "utf8");
}

if (errors.length > 0) {
  process.exitCode = 1;
}

function toNonNegativeInteger(value) {
  const parsed = Number(value ?? 0);
  return Number.isSafeInteger(parsed) && parsed >= 0 ? parsed : 0;
}

function stripComments(value) {
  return value.replace(/<!--[\s\S]*?-->/g, "").trim();
}

function readSection(markdown, heading) {
  const start = markdown.indexOf(heading);
  if (start < 0) return "";
  const contentStart = start + heading.length;
  const nextHeading = markdown.indexOf("\n## ", contentStart);
  return markdown.slice(contentStart, nextHeading < 0 ? markdown.length : nextHeading).trim();
}

function escapeMarkdown(value) {
  return value.replace(/`/g, "\\`");
}
