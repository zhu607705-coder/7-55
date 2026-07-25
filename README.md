# 7:55

[![Web CI](https://github.com/zhu607705-coder/7-55/actions/workflows/web-ci.yml/badge.svg?branch=main)](https://github.com/zhu607705-coder/7-55/actions/workflows/web-ci.yml)

《7:55》的可玩版本与技术框架。当前正式版本使用 Vite、TypeScript、React、Phaser 和 Zustand；Godot 迁移通过独立 PR 和灰度入口分阶段推进。

## 开始开发

需要 Node.js 22：

```bash
npm ci
npm run dev
```

本地快速检查：

```bash
npm run verify:structure
npm run typecheck
npm test
npm run build
```

完整 PR 检查：

```bash
npm run verify:pr
```

## 仓库预览与协作门户

生成统一预览页：

```bash
npm run build:project-preview
npm run verify:project-preview
```

输出位于 `demo/project-preview.html`，包含：

- 正式游戏、校园地图、Godot 迁移和 DEV 检查点入口。
- 仓库目录分类和依赖边界。
- 四人工作通道和共享高风险文件。
- 分支、拉取、堆叠 PR、合并和回退命令。
- 产品版本、候选版本、存档版本和桥协议版本。

团队分工配置位于 `config/team-workstreams.json`。首次使用时，把四个 `owner` 字段改成实际 GitHub 用户名。

## 离线演示

生成正式单文件：

```bash
npm run build:single
npm run verify:single
```

输出位于 `demo/index.html`。

生成独立校园大地图 Demo：

```bash
npm run build:campus-map-demo
npm run verify:campus-map-demo
```

输出位于 `demo/campus-map-demo.html`。它只加载当前紫金港大地图运行时与演示状态，不会写入正式剧情存档。

`demo/`、`dist/`、`public/godot/`、`godot/assets/generated/` 和 `artifacts/` 都是可重建产物，不提交到 Git。需要交付时，作为 Release 附件发布。

GitHub Actions 会对每个 PR 和每次推送到 `main` 执行仓库结构、地图契约、TypeScript、控制器与状态测试、生产构建和三个离线单文件校验。预览页相关 PR 还会运行桌面与移动端 Playwright 视觉检查。

## 目录

- `config`：团队职责和协作配置。
- `src/scenes/phone`：手机界面与剧情场景。
- `src/scenes/rpg`：Phaser RPG 场景和 Godot Web 宿主。
- `godot`：Godot 工程、场景、脚本和导出配置。
- `src/core`、`src/modules`：跨场景共享状态和玩法逻辑。
- `src/data`、`src/assets`：剧情、地图、物品、音频配置和正式素材。
- `src/demos`：独立预览入口。
- `tests`：控制器、状态、规则、存档和仓库契约测试。
- `scripts`：构建、地图、素材、测试和校验脚本。
- `docs`：策划、架构、迁移、PR、版本和验收文档。

完整目录边界见 [仓库目录与依赖边界](docs/REPOSITORY_STRUCTURE.md)。

## 四人协作

- [参与开发](CONTRIBUTING.md)
- [四人并行开发工作流](docs/FOUR_PERSON_WORKFLOW.md)
- [PR 与自动化测试规范](docs/PR_AND_TEST_POLICY.md)
- [版本管理规范](docs/VERSION_MANAGEMENT.md)
- [仓库目录与依赖边界](docs/REPOSITORY_STRUCTURE.md)
- [基线迁移记录](docs/BASELINE_MIGRATION_20260718.md)

`main` 只保留通过 PR 审查和必需检查的版本。禁止直接推送或强制推送 `main`。个人短分支可以在 rebase 后使用 `--force-with-lease`。
