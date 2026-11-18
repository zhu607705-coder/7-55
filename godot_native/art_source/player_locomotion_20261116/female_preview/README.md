# 红衣女生：第一版外观与男生比例对齐

当前本地预览保留第一版的红外套、短发、浅色内搭和背包，参考已合入 PR #260 的男生步行素材重新校正头身比和躯干宽度。三向依次为侧面、正面、背面，向左镜像。每行前 8 格为行走，第 9 格为暂用站姿。单格 120 × 160，男女角色使用相同的显示矩形和脚部碰撞；全身等比缩放，不单独拉长或压窄。

普通步行从 165 降至 123.75 源像素/秒（降低 25%），步行周期从 600 延至 800 ms。男生仍有 16 个步行样本，女生有 8 个，均在 800 ms 内完成同一轮。寝室与教学楼普通行走同比放慢，冲刺倍率保留；剧情末段追逐的位移速度沿用原值。

在仓库根目录使用 Godot 4.7.1 编辑器可执行文件和测试存档启动，进入普通地图后使用方向键或原触控摇杆。

```sh
godot --path godot_native --audio-driver Dummy -- --player-look=female
```

重新生成当前版本需要 Pillow 13。

```sh
python3 godot_native/tools/build_female_walk_preview.py
```

源图为 `red_jacket_aligned_source.png`，由内置 ImageGen 同时参考最初红衣女生和男生的八个关键姿势生成。`registration.json` 记录源图、图集和帧数。站姿暂取接近中立的步行帧，坐姿、手持物品及演出需要单独适配。女生入口仅限编辑器启动参数，尚未作为正式角色选择功能发布。

[男女三向同步步行](male_female_walk.webp) · [男女站姿比例](male_female_scale.png) · [女生动图](walk_preview.webp) · [图集](walk_and_idle.png)

修改前的第一版 8 帧图集保存在 [original_8](original_8/README.md)，使用 `--variant original` 重建。瘦高 24 帧版本保存在 [slim_24](slim_24/README.md)。使用 `--variant slim-24` 并提供该目录文档里的 RIFE 参数可重建对照版本。
