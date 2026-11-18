# 红衣女生第一版：修改前对照

本目录保留用户选中的第一版红衣 8 帧图集及当时的预览。三向依次为侧面、正面、背面，向左镜像。每行前 8 格为行走，第 9 格为暂用站姿，单格 120 × 160。动图仍保留当时 600 ms 的周期。

当前编辑器入口采用父目录的比例对齐版，当前男女共用的周期为 800 ms。本目录不会被入口自动加载。原始母版是父目录的 `red_jacket_source.png`，在仓库根目录使用 Pillow 13 重建本目录：

```sh
python3 godot_native/tools/build_female_walk_preview.py --variant original
```

[保留动图](walk_preview.webp) · [图集](walk_and_idle.png) · [回到当前版本](../README.md)
