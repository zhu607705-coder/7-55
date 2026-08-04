# 7:55

[![Web CI](https://github.com/zhu607705-coder/7-55/actions/workflows/web-ci.yml/badge.svg?branch=main)](https://github.com/zhu607705-coder/7-55/actions/workflows/web-ci.yml)

《7:55》的可玩版本与技术框架。当前项目使用 Vite、TypeScript、React、Zustand、
Phaser 和 Godot 4 Web。

2026-07-26 起，React / TypeScript 继续负责手机端、共享状态、控制器、存档、任务、
道具和表现层；Godot 4 Web 分阶段接管校园地图与横屏 RPG 内景。尚未通过整段验收的
场景继续使用 Phaser 回退，避免迁移期间出现不可玩的剧情断点。

## 开始开发

需要 Node.js 22：

```bash
npm ci
npm run dev
```

剧院 Godot 正式运行使用本地 HTTP 地址：

```text
http://127.0.0.1:5173/?devCheckpoint=c3-theater-entry&dev=1
```

剧院已通过整段验收，HTTP(S) 下默认 `auto` 使用 Godot。`rpgEngine=godot` 可显式检查
Godot，`rpgEngine=phaser` 强制检查兼容回退。直接打开 `demo/index.html` 时仍选择
Phaser，因为浏览器不能从 `file://` 正常加载 Godot 的 `.wasm` 和 `.pck`。

提交前执行：

```bash
npm run map:zijingang
npm run godot:check
npm run typecheck
npm run build
npm run build:single
npm run verify:single
```

修改 `godot/`、同步资源或 Godot Web 导出后，还要安装 Godot `4.7.1` 与同版本导出
模板，并执行：

```bash
npm run godot:export:web
```

该命令同步 TypeScript 资产契约，重新导出 `public/godot/theater/`，记录构建哈希，
并校验源码与 Web 产物一致性。详细说明见
[Godot RPG 工作区](godot/README.md)。

生成单文件离线演示：

```bash
npm run build:demo
```

输出位于 `demo/index.html`。`demo/` 和 `dist/` 是可重建产物，不提交到 Git。
`public/godot/theater/` 是部署所需的已审核 Web 导出，随对应 Godot 源码和
`build-manifest.json` 一并提交，禁止手工修改。

### 独立校园大地图 Demo

```bash
npm run build:campus-map-demo
npm run verify:campus-map-demo
```

输出位于 `demo/campus-map-demo.html`。它只加载当前紫金港大地图运行时与演示状态，不会写入正式剧情存档。
需要交付离线演示时，请作为 Release 附件发布。

GitHub Actions 会对每个 PR 和每次推送到 `main` 执行地图契约、Godot
源码—已提交 Web 导出哈希一致性、类型检查、生产构建与单文件回退检查。CI 不下载
Godot 编辑器和导出模板；修改 Godot 源码的提交者必须先在本地运行
`npm run godot:export:web`。工作流不恢复已经移除的自动测试体系。

## 目录

- `src/scenes/phone`：手机界面与剧情场景。
- `src/scenes/rpg`：RPG 领域契约与迁移期 Phaser 场景。
- `src/integrations/godot`：React 宿主、版本化桥接与兼容回退。
- `godot`：Godot 4 Web 场景、脚本、同步资产与导出配置。
- `public/godot`：经哈希登记的 Godot Web 部署产物。
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
