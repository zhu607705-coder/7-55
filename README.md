# 7:55

[![Web CI](https://github.com/zhu607705-coder/7-55/actions/workflows/web-ci.yml/badge.svg?branch=main)](https://github.com/zhu607705-coder/7-55/actions/workflows/web-ci.yml)

《7:55》的可玩版本与技术框架。当前项目使用 Vite、TypeScript、React、Zustand、
Phaser 和 Three.js。React / TypeScript 负责手机端、共享状态、控制器、存档、任务、
道具和表现层；Phaser 负责校园地图与横屏 RPG 内景；第四章错位楼梯是
唯一经过批准的 Three.js 场景。

## 开始开发

需要 Node.js 22：

```bash
npm ci
npm run dev
```

剧院 Phaser 正式运行可使用开发检查点：

```text
http://127.0.0.1:5173/?devCheckpoint=c3-theater-entry&dev=1
```

HTTP、部署环境和直接打开 `demo/index.html` 均使用同一浏览器原生运行时。

提交前执行：

```bash
npm run validate:release
```

该入口依次执行类型检查、关键玩法合同、地图与音频合同、生产构建、Chromium 启动检查、离线单文件构建与结构校验。局部开发可先运行 `npm run validate:quick`，控制器、存档、输入或 Phaser 行为变更运行 `npm run validate:critical`。完整分层、覆盖边界与扩展审计命令见 [Validation Strategy](docs/TESTING.md)。

生成单文件离线演示：

```bash
npm run build:demo
```

输出位于 `demo/index.html`。`demo/` 和 `dist/` 是可重建产物，不提交到普通 Git；
需要交付离线演示时，以完成日期命名并作为 GitHub Release 附件发布。

当前离线版本：[7-55-demo-20260904.html](https://github.com/zhu607705-coder/7-55/releases/download/demo-20260904/7-55-demo-20260904.html)。对应实现归档与文件校验信息见 [ASSETS.md](ASSETS.md)。

### 独立校园大地图 Demo

```bash
npm run build:campus-map-demo
npm run verify:campus-map-demo
```

输出位于 `demo/campus-map-demo.html`。它只加载当前紫金港大地图运行时与演示状态，不会写入正式剧情存档。
需要交付离线演示时，请作为 Release 附件发布。

`npm run build` 已包含 TypeScript 类型检查。后续 demo 构建直接执行 Vite，避免在同一批次重复运行 `tsc --noEmit`。

GitHub Actions 会对包含 Markdown 与 `docs/` 以外变更的 PR 和 `main` 推送执行关键玩法行为回归、
第三章音频、校园地图、第四章 7:55、类型检查、生产构建、Chromium 启动检查和离线单文件验证。
纯文档变更会跳过自动流程，仍可在 Actions 页面手动执行包含扩展内容审计的全量验证。

## 目录

- `src/scenes/phone`：手机界面与剧情场景。
- `src/scenes/rpg`：RPG 领域契约与 Phaser 场景。
- `src/core`、`src/modules`：跨场景共享状态和玩法逻辑。
- `src/data`：对话、剧情、物品与音频配置。
- `scripts`：地图、素材和音频辅助脚本。
- `docs`：框架、关卡设计和开发记录。

运行时包含 `phone` 和 `rpg` 两种模式；两者应共用 `src/core` 与 `src/modules`
中的剧情进度和状态。

2026-08-25 起，退役的 Godot 源码、Web 导出、React 兼容层和同步脚本均已删除，
不得重新加入活动构建或 CI。

新增剧情前请先阅读 [CLAUDE.md](CLAUDE.md) 与
[框架说明](docs/framework-spec.md)。

## 四人协作

- [参与开发](CONTRIBUTING.md)
- [测试策略](docs/TESTING.md)
- [版本管理规范](docs/VERSION_MANAGEMENT.md)
- [本次基线迁移记录](docs/BASELINE_MIGRATION_20260718.md)

`main` 只保留已验证版本；4 名协作者可按规范直接推送，禁止强制推送。
