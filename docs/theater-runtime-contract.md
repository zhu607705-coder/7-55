# 剧院运行时替换契约

## 目标

剧院流程的存档、剧情、任务、钱包和道具状态继续由 React/TypeScript 主应用管理。Godot 4 Web 承接剧院画面、碰撞、动画和输入，并通过版本化契约读取状态和提交意图。

当前契约入口是 `src/scenes/rpg/TheaterRuntimeContract.ts`，版本为 `1.0.0`。现有 Phaser 剧院已通过该契约运行，它同时是迁移期基准实现和 Godot 适配的领域边界。

## 固定边界

- 逻辑画布固定为 `960 × 540`，外部实现自行做等比缩放和留黑。
- `getState()` 是唯一状态快照来源。
- `emit()` 只能发送 `TheaterRuntimeIntentName` 中声明的意图。
- `subscribe()` 接收主应用发布的领域事件，用于播放动画、字幕和阶段反馈。
- `setRpgLocation()` 只更新剧院场景检查点。
- 外部实现不得直接写存档、发放道具、扣款、推进任务或维护第二套剧情状态。
- `temporaryTheaterTicket` 的两次使用都保留道具：入口右侧读票器验票、后台道具箱旁扫描器解锁。

## 替换实现接入顺序

1. 在 `godot/` 剧院场景和 `src/integrations/godot/` 宿主适配器中实现 `TheaterRuntimePort`，保持契约版本与逻辑画布一致。
2. 逐项实现 `TheaterRuntimeIntentName`，不要添加未声明的旁路事件。
3. 用 `c3-theater-entry`、`c3-theater-code`、`c3-theater-program`、`c3-theater-prop`、`c3-theater-spotlight`、`c3-theater-spotlight-round`、`c3-theater-complete` 七个 DEV 检查点验收。
4. 通过入口取票、两次观演票拖放、节目单排序、道具箱、三轮追光和离场完整流程。
5. 在独立分支提交 Godot Web 宿主挂载层。React 和 Phaser 基准实现保留到 Godot 剧院通过完整验收，再切换该场景的默认运行时。

## 兼容与失败规则

- 契约版本不匹配时必须中止挂载并报告错误，不能静默降级。
- 缺少音频或动画时仍要提交已经完成的领域意图，表现层不能阻塞剧情。
- Pointer Events 为鼠标、触摸和笔的统一输入协议；键盘交互只显示真实可用的按键。
- 输入、全屏、音频和可见性暂停需要覆盖 Blink、Gecko 与 WebKit 支持基线。
