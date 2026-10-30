## verdict

本轮仅评分首次审阅的 F1、F2。已分别重开调用方要求的全部 14 张当前截图：桌面信号静止／拖动两张 1280×720，移动信号静止／拖动两张 844×390，`desktop/solar_initial.png` 1280×720，`motion_desktop/` 的 0°／30°／60°／减少动效 60° 四张 1280×720，`motion_mobile/` 的 0°／30°／60°／减少动效 30°／减少动效 60° 五张 844×390。各图内容、尺寸和状态有效。没有使用旧 `motion/` 或接触表代替逐张检查。

1. **F1 — resolved。** `desktop/signal_complete.png` 和 `mobile/signal_complete.png` 中四台屏幕的支杆均从屏框下方连续连接到桌面底座，先前断口与向下悬出的 T 形杆已消失；`desktop/signal_receiver_drag.png` 和 `mobile/signal_receiver_drag.png` 中被拖动屏幕仍保留完整的屏—杆—底座结构，接线端点随同移动。`signal_sync_view.gd:112-114` 使用上移后的基座和 `base+Plane45.offset(0,0,60)`，绘制顺序把杆顶收进屏框；第 79 行的底座触点随实际新位置更新。当前 desktop/mobile 的 presentation 报告各有四项实际渲染支杆探针通过，支持这次可见修正。
2. **F2 — resolved。** `motion_desktop/solar_hinge_before.png`、`solar_hinge_after.png`、`solar_60_stable.png` 中，固定铰链仍保持同一位置，30° 与 60° 的面板外侧支撑杆具有不同的外露长度、下方落脚点与表面明暗；差别在松手、移除临时角度字样后保留。`motion_mobile/` 对应三张图在原尺寸中仍能看见两侧杆件和落脚点的改变；`solar_reduced_30.png` 与 `solar_reduced.png` 保留相同稳定结构差别，减少动效没有抹掉状态。`motion_lab_view.gd:250-264` 的支撑深度、高度来自真实倾角，表面亮度来自当前模型太阳角和照度，`bench_projection.gd` 的共同正交投影未变。判断依据是可见结构变化；新报告中正常和减少动效的 30°↔60° 实际车辆区域差异检查只是补充证据。

当前 `desktop/object_input.json` 为 47/0，`mobile/object_input.json` 为 53/0，均记录正常实时指针／触屏输入、零键盘事件；`motion_desktop/presentation.json` 和 `motion_mobile/presentation.json` 各为 32/0，`movieFixedStep: false`，分别对应本轮 1280×720 与 844×390。旧 25 项报告和第一段录像没有被用作此次评分依据。

评分源码快照：`signal_sync_view.gd` SHA-256 `16c42be6519e5ec82e98beb88cb280be79f9536e8382eefa51959cc33640af07`；`motion_lab_view.gd` `6c0791bab3511e740299f3bec194c969617f29de0db4eb643c731033d7e43136`；`bench_projection.gd` `9a635d4b23958b4506b437fd8911034c8e01074e793acbfb22d8b1b8cab9aa6a`。

## remaining

clear（仅 F1、F2）。在这批修正的指定截图及相关输入记录中，未发现修正引入的可见回归。本判定表示两项所列修正均已解决，范围不扩展到整套场景的新一轮审阅、生产存档、完整测试、物理手机或发布。正在完成的验收记录、修正后浏览器烟测和新录像不属于本次两项评分，也未被当作已经交付的结果。

disposition: ship
