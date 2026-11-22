# 2026-11-17 主角走路与站姿

- `standing.png` 按正面、侧面、背面排列三张站姿。
- `walk_side.png` 是 16 帧侧走，从原图第 6 格起播，向左共用镜像。
- `walk_down_thin_rim_16.png` 是 16 帧向下走，采用细描边试播版，按正面站姿校色。
- `walk_up_approved_16.png` 是确认的 16 帧向上走。保留原 8 帧预览的六张关键画，使用 Sprite Gen 的 RIFE 衔接两处换脚和其余过渡。保留动作本身的时间，减少外缘暗边。

用 Pillow 12.3.0 执行 `python godot_native/tools/build_player_locomotion.py` 可重建图集。每格 120 × 160，三行依次是侧面、正面、背面。每行前 16 格为走路，第 17 格为站姿。普通步行每轮 600 毫秒。图集使用无损 RGBA 导入和最近邻采样，输入与输出文件哈希记录在 `registration.json`。
