import { readFile } from "node:fs/promises";
import { resolve } from "node:path";
import { test } from "node:test";
import assert from "node:assert/strict";

const root = process.cwd();

async function read(path: string): Promise<string> {
  return readFile(resolve(root, path), "utf8");
}

test("四人工作通道配置具有唯一职责和交叉审查关系", async () => {
  const config = JSON.parse(await read("config/team-workstreams.json")) as {
    version: number;
    lanes: Array<{ id: string; owner: string; paths: string[]; reviewPartners: string[] }>;
    sharedCriticalPaths: string[];
    generatedPaths: string[];
    mergeMethod: string;
  };

  assert.equal(config.version, 1);
  assert.equal(config.lanes.length, 4);
  assert.equal(new Set(config.lanes.map((lane) => lane.id)).size, 4);
  assert.equal(config.mergeMethod, "squash");
  assert.ok(config.sharedCriticalPaths.includes("src/core/GameState.ts"));
  assert.ok(config.generatedPaths.includes("demo/**"));

  const laneIds = new Set(config.lanes.map((lane) => lane.id));
  for (const lane of config.lanes) {
    assert.ok(lane.owner.length > 0, `${lane.id} 缺少 owner`);
    assert.ok(lane.paths.length > 0, `${lane.id} 缺少 paths`);
    assert.ok(lane.reviewPartners.length > 0, `${lane.id} 缺少 reviewPartners`);
    lane.reviewPartners.forEach((partner) => assert.ok(laneIds.has(partner), `${lane.id} 引用了未知通道 ${partner}`));
  }
});

test("仓库预览入口包含构建、目录、分工、PR 和版本五个区域", async () => {
  const [html, source, styles] = await Promise.all([
    read("project-preview.html"),
    read("src/demos/project-preview.tsx"),
    read("src/demos/project-preview.css")
  ]);

  assert.match(html, /project-preview\.tsx/);
  for (const text of [
    "统一预览入口",
    "文件分类与依赖边界",
    "四人并行开发通道",
    "分支、拉取与合并方式",
    "版本与发布规则"
  ]) {
    assert.ok(source.includes(text), `预览页缺少区域：${text}`);
  }
  for (const href of ["./index.html?dev=0", "./campus-map-demo.html", "engine=godot", "devCheckpoint=c1-alarm"]) {
    assert.ok(source.includes(href), `预览页缺少入口：${href}`);
  }
  assert.match(styles, /@media \(max-width: 760px\)/);
  assert.match(styles, /prefers-reduced-motion/);
});

test("构建和 CI 同时验证三个离线入口与 Playwright 视觉证据", async () => {
  const [packageJson, viteConfig, webCi, previewCi, verifier] = await Promise.all([
    read("package.json"),
    read("vite.config.ts"),
    read(".github/workflows/web-ci.yml"),
    read(".github/workflows/project-preview-ci.yml"),
    read("scripts/verify-single-file-build.mjs")
  ]);

  const pkg = JSON.parse(packageJson) as { scripts: Record<string, string> };
  for (const script of [
    "build:project-preview",
    "verify:project-preview",
    "verify:structure",
    "test:project-preview:visual"
  ]) {
    assert.ok(pkg.scripts[script], `package.json 缺少脚本：${script}`);
  }
  assert.ok(pkg.scripts["verify:pr"].includes("build:project-preview"));
  assert.ok(viteConfig.includes('mode === "project-preview"'));
  assert.ok(webCi.includes("npm run build:project-preview"));
  assert.ok(previewCi.includes("npm run test:project-preview:visual"));
  assert.ok(verifier.includes("project-preview.html"));
});

test("协作文档规定个人短分支、堆叠 PR、安全 rebase 和 squash", async () => {
  const [workflow, structure, version, contributing] = await Promise.all([
    read("docs/FOUR_PERSON_WORKFLOW.md"),
    read("docs/REPOSITORY_STRUCTURE.md"),
    read("docs/VERSION_MANAGEMENT.md"),
    read("CONTRIBUTING.md")
  ]);

  for (const text of ["堆叠 PR", "--force-with-lease", "Squash merge", "release/v0.4.0"]) {
    assert.ok(workflow.includes(text), `四人工作流缺少：${text}`);
  }
  assert.ok(structure.includes("config/team-workstreams.json"));
  assert.ok(version.includes("SaveEnvelope.version"));
  assert.ok(version.includes("protocolVersion"));
  assert.ok(contributing.includes("<github-user>/<area>-<topic>"));
});
