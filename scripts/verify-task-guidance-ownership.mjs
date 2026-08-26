import { readdir, readFile } from "node:fs/promises";
import path from "node:path";

const SOURCE_ROOTS = ["src/scenes", "src/components", "src/data"];
const SOURCE_EXTENSIONS = new Set([".ts", ".tsx", ".json"]);
const TASK_UI_OWNER = path.normalize("src/components/QuestClueStrip.tsx");
const FORBIDDEN_PATTERNS = [
  { label: "页面内的‘下一步：’全局路线提示", pattern: /下一步[：:]/g },
  { label: "页面内的‘接下来’全局路线提示", pattern: /接下来/g }
];

async function collectFiles(directory) {
  const entries = await readdir(directory, { withFileTypes: true });
  const files = [];
  for (const entry of entries) {
    const target = path.join(directory, entry.name);
    if (entry.isDirectory()) {
      files.push(...await collectFiles(target));
    } else if (SOURCE_EXTENSIONS.has(path.extname(entry.name))) {
      files.push(target);
    }
  }
  return files;
}

const files = (await Promise.all(SOURCE_ROOTS.map(collectFiles))).flat();
const violations = [];

for (const file of files) {
  const normalized = path.normalize(file);
  if (normalized === TASK_UI_OWNER) continue;
  const content = await readFile(file, "utf8");
  const lines = content.split(/\r?\n/);
  lines.forEach((line, index) => {
    FORBIDDEN_PATTERNS.forEach(({ label, pattern }) => {
      pattern.lastIndex = 0;
      if (pattern.test(line)) {
        violations.push(`${normalized}:${index + 1} ${label}\n  ${line.trim()}`);
      }
    });
  });
}

if (violations.length > 0) {
  console.error("任务提示所有权校验失败：持续的全局路线提示只能由共享任务栏显示。\n");
  console.error(violations.join("\n"));
  process.exit(1);
}

console.log(`任务提示所有权校验通过：检查 ${files.length} 个源文件，未发现页面内重复的全局路线提示。`);
