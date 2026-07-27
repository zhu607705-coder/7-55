# 剧院运行时替换契约

## 目标

剧院流程的存档、剧情、任务、钱包和道具状态继续由 React/TypeScript 主应用管理。Godot 4 Web 承接剧院画面、碰撞、动画和输入，并通过版本化契约读取状态和提交意图。

当前契约入口是 `src/scenes/rpg/TheaterRuntimeContract.ts`，版本为 `1.0.0`。现有 Phaser 剧院与 Godot 剧院预览都通过该契约运行。React 宿主位于 `src/integrations/godot/`，Godot 项目位于 `godot/`，已登记的 Web 导出位于 `public/godot/theater/`。

## 固定边界

- 逻辑画布固定为 `960 × 540`，外部实现自行做等比缩放和留黑。
- `getState()` 是唯一状态快照来源。
- `emit()` 只能发送 `TheaterRuntimeIntentName` 中声明的意图。
- `subscribe()` 接收主应用发布的领域事件，用于播放动画、字幕和阶段反馈。
- `setRpgLocation()` 只更新剧院场景检查点。
- 外部实现不得直接写存档、发放道具、扣款、推进任务或维护第二套剧情状态。
- `temporaryTheaterTicket` 的两次使用都保留道具：入口右侧读票器验票、后台道具箱旁扫描器解锁。
- 取票码和节目单排序继续由 React DOM 面板收集输入并交给 TypeScript 控制器验证；Godot 只请求打开面板，不复制题目状态。
- 道具拖放继续由共享 React 道具栏处理，iframe 画布坐标统一换算到 `960 × 540` 后再提交契约意图。
- Godot Web 使用自适应 canvas 策略填满宿主 `16:9` 区域；完成态按 TypeScript 快照中的 `admitted + phase` 选择出生区，`complete` 必须直接落在大厅出口。

## 当前接入状态

| 剧院阶段 | 当前画面运行时 | 状态与判定 |
| --- | --- | --- |
| `entry_ticket` | Godot 预览 | TypeScript 控制入口验票与取票码 |
| `program_search` | Godot 预览 | React 节目单面板提交控制器 |
| `prop_setup` | Godot 预览 | React 道具栏拖放到 Godot 精确目标 |
| `spotlight_ready` | Godot 预览 | TypeScript 控制追光准备状态 |
| `spotlight_hunt` / `reversal` | Phaser 回退 | 三轮追光玩法尚未迁入 Godot |
| `complete` | Godot 预览 | TypeScript 保留完成事实与离场判定 |

默认 `auto` 模式仍使用 Phaser。开发验收通过
`?devCheckpoint=c3-theater-entry&rpgEngine=godot&dev=1` 显式开启 Godot；使用
`rpgEngine=phaser` 可强制检查回退。`file://` 单文件固定回退 Phaser，完整 Godot Web
运行时必须由 HTTP(S) 提供 `.wasm`、`.pck` 和脚本资源。

## 已验证链路

- 完成态隔离存档重载后仍为 `phase=complete`，人物位于大厅出口 `(836,842)`，`theater_exit` 为当前目标。
- Space 离场后进入 `campus_bootstrap / campus_theater_junction`，启真湖阶段为 `location_search`。
- `1280 × 720` HTTP 预览中 iframe 与内部 canvas 同为 `1280 × 720`；可见灯控台拖放按 `960 × 540` 逻辑坐标命中。
- WebKit `390 × 844` 中 Godot 画布为 `390 × 219.375`，触控移动、精确拖放和外层布局无溢出。

## 后续替换顺序

1. 把 `spotlight_hunt` 与 `reversal` 的三轮追光玩法迁入同一个 Godot 场景。
2. 用 `c3-theater-entry`、`c3-theater-code`、`c3-theater-program`、`c3-theater-prop`、`c3-theater-spotlight`、`c3-theater-spotlight-round`、`c3-theater-complete` 七个 DEV 检查点复验。
3. 完成入口、两次观演票拖放、节目单排序、道具箱、三轮追光、离场、保存恢复和重新进入的完整浏览器链路。
4. 在 Blink、Gecko、WebKit 的桌面、非 `16:9` 与 `390 × 844` 环境通过后，才把剧院 `auto` 模式切到 Godot。

## 兼容与失败规则

- 契约版本不匹配时必须中止挂载并报告错误，不能静默降级。
- 缺少音频或动画时仍要提交已经完成的领域意图，表现层不能阻塞剧情。
- Pointer Events 为鼠标、触摸和笔的统一输入协议；键盘交互只显示真实可用的按键。
- 输入、全屏、音频和可见性暂停需要覆盖 Blink、Gecko 与 WebKit 支持基线。
- `npm run godot:sync` 生成可追踪资产副本，`npm run godot:export:web` 生成并登记 Web 产物，`npm run godot:check` 在本地和 CI 验证源码、资产与已提交导出哈希一致。
