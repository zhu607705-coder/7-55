# 7:55 — 启真湖可玩追逐独立样例

Godot 4.6.3 / GL Compatibility。打开 `project.godot`，等待导入，按 F5。

## 本轮范围

同一张原 CHANNEL 地图：天鹅出场 → 锁向预兆与闪避 → 浮排上/下路线 → 开口对线 → 反划减速靠岸。移动必须来自划桨输入。闲置会被抓，碰撞会失速，失败后可直接重试。

本工程独立于正式游戏。成功只返回 `next_story = "3.5"` 并显示“未同步记录”，不读写主线状态或存档。没有落水救援。原 `kayak_model.gd`、原天鹅模型及地图28个碰撞矩形保持不变。

## 操作

| 目标 | 键鼠 | 触屏 / 鼠标按钮 |
| --- | --- | --- |
| 前进 | 按住空格自动交替划桨 | 单指按住中间划行按钮 |
| 转向 | A / D 或左右键，点按/按住 | 左右桨按钮点按/按住 |
| 反划制动 | S / 下键 + 划桨 | 按住按钮后向下拖超过24 px |
| 收桨 | 松开 | 松开 |
| 暂停 | P / Esc | 暂停按钮 |
| 重试 | R | 重试按钮 |

键盘左右同时按会交替划桨。空格与单侧键同时按时，单侧优先转向。失焦自动暂停；继续前应松开按键。重试跳过出场。

## 已测结果与限制

- 原生窗口键盘交互录制来源：云端实际键盘实玩，上路25.983秒、59桨、零碰撞、3次闪避、过口和低速稳泊成功
- 自动来源：下路纯 `stroke/step` 输入回归，20.467秒、74桨、零碰撞、2次闪避；不是人工录像
- 双路线重放均从正常起点开始，未应用记录的坐标，没有传送或关闭天鹅
- 模型498项、输入94项通过；证据文件见 `docs/PLAYABLE_CHASE_ACCEPTANCE.md`
- 参考45–75秒尚未达到。实玩有效操作25.98秒，暂停观察不计入关卡时长
- 手机触摸事件与窄屏按钮布局已自动测试，实体手机手感尚未实测；目前建议横屏
- 新视频是约30fps实时桌面录制，只剪短暂停片段，未加速、未插帧。此前动作研究60fps离线视频不能用于证明本关实时性能

## 源码入口

- `scripts/games/qizhen_playable_chase.gd`：独立局部物理/追逐/过门/停泊模型
- `scripts/presentation/qizhen_playable_chase_view.gd`：键鼠触控、暂停重试、HUD与模型绑定
- `scripts/presentation/qizhen_chase_swan_actor.gd`：复用短扑/平游资产的只读表现层
- `scripts/presentation/kayak_rig.gd`：船、上身、头、双臂、双叶桨、水面遮挡与水花分层动作
- `tests/fixtures/playable_upper_manual_input.json`：真实键盘输入序列
- `tests/fixtures/playable_lower_automated_input.json`：自动输入序列，明确非人工

## 回归

```sh
godot --headless --path . --editor --import --quit
godot --headless --path . --script res://tests/test_playable_chase_model.gd
godot --headless --path . --script res://tests/test_playable_chase_inputs.gd
```

`tests/benchmark_playable_chase.gd` 必须在原生渲染窗口运行，不使用 `--fixed-fps` 或 `--write-movie`。其脚本输入仅用于稳定工作负载，不替代人工实玩。

## 后续最小扩展建议（未实施）

1. 在宽水面增加一次可读的左右选择：天鹅蓄势锁定后，玩家决定向浮排上路还是下路避让。由空间变化增加决策，不添加按钮或强制等待
2. 将最终靠岸扩成两段操作：先绕一个清晰可见的浮标转正，再利用反划停泊。保持现有手感，并先用初次玩家测试校准长度，不为凑45秒降低速度

本包保留四套分层划桨回归依赖的旧观察场景，默认入口仍为新追逐场景。旧研究文档不作为本轮验收依据。正式主线接入、移动设备实测、长期关卡长度调整均未完成。
