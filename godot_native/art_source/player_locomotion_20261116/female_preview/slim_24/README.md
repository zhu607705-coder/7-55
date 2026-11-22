# 红衣女生三向 24 帧行走试作

本版沿用消抖前的瘦高原稿及原有 8 张关键姿势。每对相邻关键帧之间用本机 RIFE 补入 1/3、2/3 两张，三向各 24 帧，向左镜像。第 8 张关键帧到第 1 张也补齐循环过渡。关键帧保存在 `walk_keyframes.png`，运行图集每行前 24 格为行走，第 25 格为站姿。

单格 120 × 160，行走周期 600 ms，与已有移动、碰撞、朝向、Shift 和触控入口共用。站姿暂取原稿中接近中立的姿势。坐姿、手持物品和演出仍需后续单独适配。

## 对照版本

当前运行入口采用父目录保留第一版外观的比例对齐稿。本目录保留瘦高 24 帧素材与当时 600 ms 的预览。

## 生成与补帧

`../red_jacket_slim_source.png` 为 ImageGen 的瘦高原稿，`../red_jacket_source.png` 为早期红衣参考。瘦高稿参考 [PR #260](https://github.com/zhu607705-coder/7-55/pull/260) 的主角动画，保留短发、砖红夹克和背包。

补帧使用 [RIFE ncnn Vulkan 官方 20221029 版](https://github.com/nihui/rife-ncnn-vulkan/releases/tag/20221029) 的 `rife-v4` 模型。外部工具按机器配置传入，模型和可执行文件的哈希保存在 `registration.json`。工具及模型留在本机工具库。

```sh
python3 godot_native/tools/build_female_walk_preview.py --variant slim-24 \
  --rife-bin /path/to/rife-ncnn-vulkan \
  --rife-model /path/to/rife-v4
```

需 Pillow 13。原画按统一比例切帧、对齐，再插帧。RGB 与透明轮廓同时补帧，插值结果恢复二值透明和固定色板，每第 3 格保留原关键帧完整字节。原生图集和 WebP 动图时长 600 ms，WebP 每帧为 25 ms。GIF 使用 20/30 ms 交替表示同一周期。

Godot 4.7.1 定向验证覆盖 24 帧读取、朝向、左右镜像、停止和脚盒，原生窗口已在图书馆驱动本版行走。

[24 帧循环](walk_preview.webp) · [GIF](walk_preview.gif) · [生成提示词](../prompt.txt)
