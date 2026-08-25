# 剧院网页运行时契约

## 目标

剧院流程的存档、剧情、任务、钱包和道具状态由 React/TypeScript 主应用管理。Phaser 承接剧院画面、碰撞、动画和输入，并通过版本化契约读取状态和提交意图。

当前场景契约入口是 `src/scenes/rpg/TheaterRuntimeContract.ts`，版本为 `1.1.0`。交互使用真实物体边界距离，不包含朝向门禁。`RpgGameHost` 只挂载 Phaser canvas；`rpgEngine` URL 参数不再切换引擎。

## 固定边界

- 逻辑画布固定为 `960 × 540`，外部实现只做等比缩放和留黑。
- `getState()` 是唯一状态快照来源。
- `emit()` 只能发送 `TheaterRuntimeIntentName` 中声明的意图。
- `subscribe()` 接收主应用发布的领域事件，用于播放动画、字幕和阶段反馈。
- `setRpgLocation()` 只更新剧院场景检查点。
- Phaser 场景不得直接写存档、发放道具、扣款、推进任务或维护第二套剧情状态。
- `temporaryTheaterTicket` 的两次使用都保留道具：入口右侧读票器验票、后台道具箱旁扫描器解锁。
- CC98 手机票务页负责两波抢票；Phaser 取票机只显示实体票打印码面板。取票码与节目单排序结果均由 TypeScript 控制器验证。
- 道具拖放由共享 React 道具栏处理，画布坐标统一换算到 `960 × 540` 后提交契约意图。

## 当前接入状态

| 剧院阶段 | 画面运行时 | 状态与判定 |
| --- | --- | --- |
| `entry_ticket` | Phaser + 手机 CC98 | 手机完成两波抢票；TypeScript 控制实体票打印与入口验票 |
| `program_search` | Phaser | Phaser 节目单面板提交给 TypeScript 控制器 |
| `prop_setup` | Phaser | React 道具栏拖放到 Phaser 精确目标 |
| `spotlight_ready` | Phaser | TypeScript 控制追光准备状态 |
| `spotlight_hunt` | Phaser | Phaser 播放三轮轨迹并提交实测锁定数据 |
| `reversal` | Phaser | Phaser 播放纸条破裂与残影逃离，TypeScript 验证完成 |
| `complete` | Phaser | TypeScript 保留完成事实与离场判定 |

开发验收可通过 `?devCheckpoint=c3-theater-entry&dev=1` 直接进入。HTTP(S)、本地 HTTP 和离线单文件均使用该 Phaser 运行时。

## 交互与失败规则

- 人物脚点到真实可见物体边界的最近距离是交互距离权威。
- 墙面设备和多侧接近物体都只检查真实边界距离，不检查人物朝向。
- 拖放反馈覆盖 `accepted`、`missed_target`、`wrong_item`、`too_far`、`wrong_mode` 和控制器拒绝。
- 契约版本不匹配时中止场景交互并报告可读错误。
- 缺少音频或动画时仍要提交已经完成的领域意图，表现层不得阻断剧情。
- Pointer Events 是鼠标、触摸和笔的统一输入协议；键盘交互只显示真实可用的按键。
- 输入、全屏、音频、可见性暂停、存档恢复和卸载清理覆盖 Blink、Gecko 与 WebKit 支持基线。

## 退役边界

退役的 `godot/`、`public/godot/` 和 `src/integrations/godot/` 已于 2026-08-25 删除。后续剧院行为只修改 Phaser 场景和共享 TypeScript 控制器，禁止恢复旧导出、加载器、协议桥或验证脚本。
