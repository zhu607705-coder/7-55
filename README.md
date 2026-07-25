# 7:55

[![Web CI](https://github.com/zhu607705-coder/7-55/actions/workflows/web-ci.yml/badge.svg?branch=main)](https://github.com/zhu607705-coder/7-55/actions/workflows/web-ci.yml)

《7:55》的可玩版本与技术框架。当前项目使用 Vite、TypeScript、React、Phaser 和 Zustand。

项目运行时统一使用 React 与 Phaser。Godot 迁移路线已于 2026-07-21 停止，活动源码、依赖和构建流程均不接入 Godot。

## 开始开发

需要 Node.js 22：

```bash
npm ci
npm run dev
```

本地快速检查：

```bash
npm run typecheck
npm test
npm run build
```

完整 PR 检查：

```bash
npm run verify:pr
```

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

`demo/` 和 `dist/` 是可重建产物，不提交到 Git。需要交付离线演示时，请作为 Release 附件发布。

GitHub Actions 会对每个 PR 和每次推送到 `main` 执行地图契约、TypeScript、控制器与状态测试、生产构建和两个离线单文件校验。

## 目录

- `src/scenes/phone`：手机界面与剧情场景。
- `src/scenes/rpg`：RPG 场景。
- `src/core`、`src/modules`：跨场景共享状态和玩法逻辑。
- `src/data`：对话、剧情、物品与音频配置。
- `tests`：控制器、状态、规则、存档和仓库契约测试。
- `scripts`：地图、素材、测试和音频辅助脚本。
- `docs`：框架、关卡设计、PR 和开发记录。

运行时包含 `phone` 和 `rpg` 两种模式；两者共用 `src/core` 与 `src/modules` 中的剧情进度和状态。

新增剧情前请先阅读 [CLAUDE.md](CLAUDE.md) 与 [框架说明](docs/framework-spec.md)。

## 协作

- [参与开发](CONTRIBUTING.md)
- [PR 与自动化测试规范](docs/PR_AND_TEST_POLICY.md)
- [版本管理规范](docs/VERSION_MANAGEMENT.md)
- [本次基线迁移记录](docs/BASELINE_MIGRATION_20260718.md)

`main` 只保留通过 PR 审查和必需检查的版本。禁止直接推送或强制推送 `main`。
