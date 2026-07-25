# 7:55

[![Web CI](https://github.com/zhu607705-coder/7-55/actions/workflows/web-ci.yml/badge.svg?branch=main)](https://github.com/zhu607705-coder/7-55/actions/workflows/web-ci.yml)

《7:55》的可玩版本与技术框架。当前已验证版本使用 Vite、TypeScript、React、Phaser 和 Zustand，Godot 4.7.1 迁移于 2026 年 7 月 25 日重新启动。

迁移采用双运行时过渡：

- 默认入口继续使用 React + Phaser。
- `?engine=godot` 加载 Godot Web 校园切片。
- 现有素材与坐标清单仍是唯一源文件，通过清单同步到 Godot。
- 达到完整行为等价前，不删除现有正式实现。

完整阶段、状态归属和验收条件见 [Godot 迁移方案](docs/GODOT_MIGRATION_PLAN.md)。

## 开始开发

需要 Node.js 22。默认 Web 版本：

```bash
npm ci
npm run dev
```

Godot 迁移环境：

```bash
npm run godot:sync
npm run godot:verify
npm run godot:check
npm run godot:test
npm run godot:export:web
npm run dev
```

macOS 默认使用：

```text
/Applications/Godot.app/Contents/MacOS/Godot
```

自定义路径可通过 `GODOT_BIN` 指定。Godot 迁移预览示例：

```text
http://localhost:5173/?engine=godot&devCheckpoint=c2-library-gate
```

提交前执行：

```bash
npm run map:zijingang
npm run typecheck
npm run build
npm run build:single
npm run verify:single
```

修改 `godot/`、Godot 桥或迁移宿主时追加：

```bash
npm run godot:verify
npm run godot:check
npm run godot:test
npm run godot:export:web
```

## 离线演示

生成正式单文件演示：

```bash
npm run build:demo
```

输出位于 `demo/index.html`。`demo/` 和 `dist/` 是可重建产物，不提交到 Git。

独立校园大地图 Demo：

```bash
npm run build:campus-map-demo
npm run verify:campus-map-demo
```

输出位于 `demo/campus-map-demo.html`，它不会写入正式剧情存档。需要交付离线演示时，请作为 Release 附件发布。

Godot Web 导出位于 `public/godot/`，由 `npm run godot:export:web` 重建。React 构建会把该目录复制进最终站点，当前尚未内联进 `demo/index.html`。

## 目录

- `src/scenes/phone`：React 手机界面与剧情场景。
- `src/scenes/rpg`：Phaser 正式场景与 Godot 过渡宿主。
- `src/core`、`src/modules`：当前跨场景共享状态和玩法逻辑。
- `src/data`：对话、剧情、物品与音频配置。
- `godot`：Godot 工程、脚本、测试、导出配置和素材同步清单。
- `scripts`：地图、素材、音频、Godot 同步和验证脚本。
- `docs`：框架、关卡设计、迁移方案和开发记录。

运行时包含 `phone` 和 `rpg` 两种界面模式。迁移第一阶段仍由 React `GameState` 提供剧情事实，Godot 通过消息桥读取状态并回传运行时快照。后续按控制器逐项迁移状态写入权。

新增剧情或迁移场景前请先阅读 [AGENTS.md](AGENTS.md)、[Godot 迁移方案](docs/GODOT_MIGRATION_PLAN.md) 与 [框架说明](docs/framework-spec.md)。

## 四人协作

- [参与开发](CONTRIBUTING.md)
- [版本管理规范](docs/VERSION_MANAGEMENT.md)
- [本次基线迁移记录](docs/BASELINE_MIGRATION_20260718.md)

`main` 只保留已验证版本。运行时、状态、地图、构建和迁移改动应通过独立分支 PR 合并，禁止强制推送。
