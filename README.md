# 7:55

[![Web CI](https://github.com/zhu607705-coder/7-55/actions/workflows/web-ci.yml/badge.svg?branch=main)](https://github.com/zhu607705-coder/7-55/actions/workflows/web-ci.yml)

《7:55》的可玩版本与技术框架。当前项目使用 Vite、TypeScript、React、Phaser 和
Zustand。

## 开始开发

需要 Node.js 22：

```bash
npm ci
npm run dev
```

提交前执行：

```bash
npm run map:zijingang
npm run typecheck
npm run build
npm run build:single
npm run verify:single
```

生成单文件离线演示：

```bash
npm run build:demo
```

输出位于 `demo/index.html`。`demo/` 和 `dist/` 是可重建产物，不提交到 Git；
需要交付离线演示时，请作为 Release 附件发布。

GitHub Actions 会对每个 PR 和每次推送到 `main` 执行上述检查。工作流不恢复已经移除的
自动测试体系，也不执行 Godot 构建。

## 目录

- `src/scenes/phone`：手机界面与剧情场景。
- `src/scenes/rpg`：RPG 场景。
- `src/core`、`src/modules`：跨场景共享状态和玩法逻辑。
- `src/data`：对话、剧情、物品与音频配置。
- `scripts`：地图、素材和音频辅助脚本。
- `docs`：框架、关卡设计和开发记录。

运行时包含 `phone` 和 `rpg` 两种模式；两者应共用 `src/core` 与 `src/modules`
中的剧情进度和状态。

新增剧情前请先阅读 [CLAUDE.md](CLAUDE.md) 与
[框架说明](docs/framework-spec.md)。

## 四人协作

- [参与开发](CONTRIBUTING.md)
- [版本管理规范](docs/VERSION_MANAGEMENT.md)
- [本次基线迁移记录](docs/BASELINE_MIGRATION_20260718.md)

`main` 只保留已验证版本；4 名协作者可按规范直接推送，禁止强制推送。
