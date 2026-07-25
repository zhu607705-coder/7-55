import { readFile, stat } from "node:fs/promises";
import { spawnSync } from "node:child_process";
import { extname, resolve } from "node:path";

const root = process.cwd();
const configPath = resolve(root, "config/team-workstreams.json");
const config = JSON.parse(await readFile(configPath, "utf8"));
const failures = [];

if (config.version !== 1) failures.push("config/team-workstreams.json version must be 1");
if (!Array.isArray(config.lanes) || config.lanes.length !== 4) failures.push("team workstream config must define exactly four lanes");
if (!Array.isArray(config.sharedCriticalPaths) || config.sharedCriticalPaths.length === 0) failures.push("sharedCriticalPaths must not be empty");
if (!Array.isArray(config.generatedPaths) || config.generatedPaths.length === 0) failures.push("generatedPaths must not be empty");

const laneIds = new Set();
for (const lane of config.lanes ?? []) {
  if (!lane || typeof lane.id !== "string" || lane.id.length === 0) failures.push("every lane requires an id");
  if (laneIds.has(lane.id)) failures.push(`duplicate lane id: ${lane.id}`);
  laneIds.add(lane.id);
  if (typeof lane.label !== "string" || typeof lane.owner !== "string" || typeof lane.mission !== "string") {
    failures.push(`lane ${lane.id ?? "unknown"} requires label, owner and mission strings`);
  }
  if (!Array.isArray(lane.paths) || lane.paths.length === 0) failures.push(`lane ${lane.id ?? "unknown"} requires paths`);
  if (!Array.isArray(lane.reviewPartners) || lane.reviewPartners.length < 1) failures.push(`lane ${lane.id ?? "unknown"} requires reviewPartners`);
}

for (const lane of config.lanes ?? []) {
  for (const partner of lane.reviewPartners ?? []) {
    if (!laneIds.has(partner)) failures.push(`lane ${lane.id} references unknown review partner ${partner}`);
  }
}

const requiredPaths = [
  "config",
  "docs",
  "scripts",
  "src/assets",
  "src/components",
  "src/core",
  "src/data",
  "src/demos",
  "src/modules",
  "src/scenes/phone",
  "src/scenes/rpg",
  "tests/core",
  "tests/repo",
  ".github/workflows",
  "project-preview.html",
  "docs/REPOSITORY_STRUCTURE.md",
  "docs/FOUR_PERSON_WORKFLOW.md"
];

for (const path of requiredPaths) {
  const info = await stat(resolve(root, path)).catch(() => null);
  if (!info) failures.push(`required repository path is missing: ${path}`);
}

const gitResult = spawnSync("git", ["ls-files", "-z"], { cwd: root, encoding: "utf8" });
if (gitResult.status !== 0) {
  failures.push(`git ls-files failed: ${gitResult.stderr.trim()}`);
} else {
  const tracked = gitResult.stdout.split("\0").filter(Boolean);
  const forbiddenPrefixes = [
    "node_modules/",
    "dist/",
    "demo/",
    "coverage/",
    ".test-dist/",
    "artifacts/",
    "uploads/",
    "public/godot/",
    "godot/assets/generated/"
  ];
  const forbiddenNames = new Set([".DS_Store", "Thumbs.db", "Desktop.ini"]);
  const forbiddenRootExtensions = new Set([".zip", ".log", ".tmp", ".bak", ".mov", ".mp4"]);

  for (const path of tracked) {
    if (forbiddenPrefixes.some((prefix) => path.startsWith(prefix))) {
      failures.push(`generated or temporary path is tracked: ${path}`);
    }
    const name = path.split("/").at(-1) ?? path;
    if (forbiddenNames.has(name)) failures.push(`system metadata is tracked: ${path}`);
    if (!path.includes("/") && forbiddenRootExtensions.has(extname(path).toLowerCase())) {
      failures.push(`temporary binary is stored at repository root: ${path}`);
    }
  }
}

const gitignore = await readFile(resolve(root, ".gitignore"), "utf8");
for (const requiredIgnore of ["dist/", "demo/", "artifacts/", "uploads/", "public/godot/", "godot/assets/generated/"]) {
  if (!gitignore.includes(requiredIgnore)) failures.push(`.gitignore is missing ${requiredIgnore}`);
}

const previewSource = await readFile(resolve(root, "src/demos/project-preview.tsx"), "utf8");
for (const requiredText of ["统一预览入口", "文件分类与依赖边界", "四人并行开发通道", "分支、拉取与合并方式", "版本与发布规则"]) {
  if (!previewSource.includes(requiredText)) failures.push(`project preview source is missing section: ${requiredText}`);
}

if (failures.length > 0) {
  console.error("Repository structure verification failed:\n" + failures.map((failure) => `- ${failure}`).join("\n"));
  process.exit(1);
}

console.log(`repository structure verified lanes=${config.lanes.length} criticalPaths=${config.sharedCriticalPaths.length}`);
