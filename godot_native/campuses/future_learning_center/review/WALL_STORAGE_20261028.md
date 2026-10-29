# 全楼柜体贴墙与扩充

按用户“所有柜子”的要求，调整未来学习中心 2F、3F、4F 的全部储物柜、零件架及茶水柜，覆盖 18 个空间。柜体复用已有独立透明素材。

| 楼层 | 原储物柜 | 当前储物柜 | 当前零件架 | 当前茶水柜 |
| --- | ---: | ---: | ---: | ---: |
| 2F | 9 | 18 | 8 | 0 |
| 3F | 5 | 20 | 0 | 1 |
| 4F | 15 | 33 | 0 | 0 |
| 合计 | 29 | 71 | 8 | 1 |

“组”指独立柜体实例，不是柜门数。新增数量是游戏布局选择，不代表现场清点。工作室每间 4 组，四楼专注区和协作区各 6 组；储藏室按原图墙面宽度放 5 组。茶水区原有整体柜和柜上设备一起移动，另增两组储物柜。根据用户后续补充，整体茶水柜最右侧新增一台独立冰箱，仍按北墙墙根放置。冰箱的银灰色外观与尺寸为评审近似，位置及存在由用户确认。

## 贴墙依据

`data/wall_storage_seams.json` 保存 14 种房间原图的 SHA-256、北墙落地点和可放柜的横向范围。部分行走多边形比画面墙根更靠内，不能直接当作墙线。现在按原图墙根放柜，将柜前可达位置约束在原有行走区内；地面、门、房间轮廓及跨层关系保持不变。

研讨室原图有四组窗，原有近似采光标记不能作为家具避窗依据。柜体改靠窗间凸出的墙柱，另记录实际窗框矩形用于遮挡检查。

`tools/place_wall_storage.mjs` 是统一重建步骤，保留原柜体 ID，新增柜体使用稳定 ID。从墙边空位成组布置，排除门口、到达点及其他家具，保留柜前通道。柜体保持原方向和等比缩放。原图发生变化时，构建要求重新测量墙线。

## 验证

- Godot 4.7.1：柜体专项 **831 项**通过，包括全部 81 件柜架及电器的墙根、柜前可达性、完整脚部阻挡、后退和实际窗框遮挡。
- 三层楼原有空间回归 **1,740 项**通过，包括房间、门、楼梯/电梯、工作台绕行、碰撞和相机。
- 桌面 `1280 × 720` 和缩放手机窗口 `390 × 844`：原生输入检查各 **13 项**通过。研讨室最终摆位再次完成空间回归及两种尺寸截图。
- 18 个空间的前后截图来自 Godot 运行场景，每间前后使用相同脚点和机位；逐间检查贴墙、窗框和原图边缘。
- 与调整前快照比较，`ground`、`modules`、`doors`、`transits`、`world`、`links`、`atriums`、`rooms` 完全一致。
- 原生定向验证通过源数据准备、存档隔离、导入/解析、启动、全部脚本解析及 FLC 房间测试；这不是全项目发布验收。

证据保存在 `/Users/zhu/Downloads/755/artifacts/flc-wall-cabinets/`。`index.html` 提供全楼及分楼层的 18 间前后对比；`before/` 保存调整前的三个布局。网页在桌面与手机宽度检查了全部图片、房间切换和溢出。

## 重现

将 `GODOT_BIN` 设为项目固定的 Godot 4.7.1 可执行文件，再运行：

```sh
node godot_native/campuses/future_learning_center/tools/build_building.mjs
node godot_native/campuses/future_learning_center/tests/run_wall_storage.mjs --headless
node godot_native/samples/future_learning_center/run.mjs --test --headless
```

`run_wall_storage.mjs --capture --resolution 1280x720` 使用 `FLC_CAPTURE_DIR` 和 `FLC_WALL_BEFORE` 两个绝对目录。`FLC_TOUCH=1` 配合 `--resolution 390x844` 获取缩放触屏视图；`FLC_INPUT_CHECK=1` 执行原生输入检查。运行器使用现有隔离测试存档协议。

```sh
node godot_native/campuses/future_learning_center/tools/build_wall_storage_review.mjs /absolute/review-output /absolute/captures /absolute/before
```

本轮属于 FLC 独立评审场景，未因此发布正式章节或生产网页。

本次冰箱补充的最新证据为 `fridge-tests.json`、`fridge-floor-tests.json`、`fridge-native.log` 和 `fridge-delivery.json`；原有 `delivery.json` 保留为前一轮柜体交付快照。
