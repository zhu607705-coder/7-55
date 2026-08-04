# Godot 4 Web RPG 工作区

## 职责边界

此目录承载校园地图和横屏 RPG 内景的 Godot 4 Web 实现。React / TypeScript 继续持有
`GameState`、控制器、存档、钱包、任务、道具栏、音频调度和表现层。Godot 接收版本化
快照并提交意图，不直接写共享状态。

首个接入场景是剧院。契约版本为 `1.0.0`，定义在
`src/scenes/rpg/TheaterRuntimeContract.ts`；宿主和消息协议位于
`src/integrations/godot/`。

## 固定工具版本

- Godot `4.7.1.stable`
- 同版本官方 export templates
- Web 导出使用单线程兼容配置、WebAssembly 与 WebGL 2
- 逻辑视口固定为 `960 × 540`

macOS 默认命令查找：

```text
$HOME/Downloads/Godot.app/Contents/MacOS/Godot
```

可通过 `GODOT_BIN` 指向其他同版本可执行文件。

## 同步、导入与导出

```bash
npm run godot:sync
npm run godot:import
npm run godot:export:web
npm run godot:check
```

- `godot:sync` 从 TypeScript 场景模型和原始资产生成 `godot/data/`、
  `godot/assets/` 与资产哈希清单。
- `godot:import` 在无界面模式解析并导入项目。
- `godot:export:web` 同步资产、导出 `public/godot/theater/`、生成
  `build-manifest.json` 并执行一致性检查。
- `godot:check` 不调用 Godot 编辑器；它用于本地快速检查和 GitHub CI，要求已提交的
  Web 导出与当前源码及资产完全匹配。

`godot/assets/`、`godot/data/` 和 `public/godot/theater/` 都由命令生成，禁止手工
修改。需要调整碰撞、目标或剧情位置时，修改 TypeScript 单源模型或 Godot 场景源码，
然后重新同步和导出。

## 本地预览

先运行：

```bash
npm run dev
```

再打开：

```text
http://127.0.0.1:5173/?devCheckpoint=c3-theater-entry&dev=1
```

- 默认 `auto`：HTTP(S) 下剧院使用已验收的 Godot 运行时。
- `rpgEngine=godot`：显式使用 Godot，适合迁移诊断。
- `rpgEngine=phaser`：强制使用 Phaser 回退。
- 缺少 WebAssembly、WebGL 2 或 HTTP(S) 资源加载时，宿主显示可读原因并选择 Phaser。
- `demo/index.html` 通过 `file://` 打开时固定使用 Phaser；Godot Web 资源需要 HTTP(S)。

## 当前剧院覆盖

Godot 已覆盖 `entry_ticket`、`program_search`、`prop_setup`、`spotlight_ready`、
`spotlight_hunt`、`reversal` 和 `complete` 的画面、人物、碰撞、交互目标、三轮追光、
反转动画与状态同步。整段流程、回合与反转存档恢复、重新进入、道具拖放和离场已经通过
Blink、Gecko、WebKit 的桌面、非 `16:9` 与 `390 × 844` 验收，默认 `auto` 已切到 Godot。

## Standalone 剧院原型

`scenes/theatre_interactive.tscn` 和 `scenes/theatre_plaza.tscn` 保留来自
`godot剧院4.7` 的 640 × 360 standalone 原型，用于剧院空间探索、区域识别和后续二层
场景制作。它们依赖 `assets/maps/`、`assets/player/` 和 `scripts/theatre_*`，可在 Godot
编辑器中直接打开单场景预览。

该原型不替换 `project.godot` 的 `theater_runtime.tscn` 主入口，也不接管 React/TypeScript
运行契约；正式 Web runtime 仍由 `theater_runtime.gd`、`data/theater-runtime.json` 和
`public/godot/theater/` 负责。

## 提交检查

Godot 相关 PR 至少执行：

```bash
npm run godot:export:web
npm run map:zijingang
npm run typecheck
npm run build
npm run build:single
npm run verify:single
```

浏览器检查覆盖 Blink、Gecko、WebKit，包含 `1280 × 720`、非 `16:9` 桌面视口和
`390 × 844` 粗指针视口。检查画布比例、人物移动、交互键、道具拖放、深浅模式、阶段
回退、文档溢出、页面错误和控制台错误。
