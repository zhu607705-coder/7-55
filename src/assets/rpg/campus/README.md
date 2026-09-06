# Zijingang Campus Artwork

## 当前运行基线

- 普通校园探索加载 IonicJian 提交的 `src/assets/rpg/campus/zijingang_campus_plate.png`，源图和世界尺寸均为 `4516 × 3420`。`src/data/maps/zijingang-campus-runtime.json` 统一管理宿舍、图书馆、东区大食堂和剧场的入口、碰撞与出生点。
- 大地图水面使用 `water/zijingang_water_frames.png` 的三张 `128 × 128` 浏览器正式帧，以及生成的 `water/zijingang_water_mask_atlas.png` 灰度 Alpha 图集。`CampusWaterLayer` 按源像素分块绘制，每帧持续 `500ms`，不再叠加横向位移。纹理本身使用 nearest 采样，遮罩和岸线坐标始终静止。自然岸线支持透明过渡，道路和桥面则在羽化后按道路 Alpha 硬裁切。除独立水层外，只额外接纳建筑层坐标 `[1940,650]–[2110,1250]` 内已确认的中上部河道；其他蓝屋顶、球场和装饰池塘不参与。
- 高于水层的同源建筑遮挡裁片会再次读取最终水域 Alpha，并用 `destination-out` 扣除裁片内的旧水像素。这样月牙楼、基础图书馆等不规则遮挡多边形仍可负责人物前后景深度，但不会把底图旧水重新盖到动画水面上。
- `zijingang_campus_loop_panorama.png` 的尺寸为 `13668 × 1084`。它只由 `campus_qizhen_loop` 加载，负责首次剧场结束后的启真湖追踪过场与湖区返回。
- `src/data/maps/zijingang-campus.json` 及其瓦片图集保留为旧方案参考，不得覆盖当前普通校园入口、空气墙或渲染底图。
- `source/panorama/zijingang_legacy_panorama.png` 是旧 `11744 × 1084` 拼接图的可复现输入。`qizhen_lake_reflection.png` 在旧图 `x=8400` 后插入 `1924px`，得到当前环湖图。
- 插入点位于首次剧场东侧。旧坐标 `x>=8400` 的建筑和入口统一右移 `1924px`，不允许场景文件各自补偿。

## 道路、空气墙和投影边界

- 普通校园碰撞由 `zijingang_road_walkability_mask.png` 和运行时内置的 `4px` 压缩网格共同约束。键盘移动、点击寻路和入口判定必须读取同一份数据。
- `zijingang_loop_walkability_mask.png` 是启真湖衔接场景 `4px` 压缩网格的可审查展开图；它不参与普通校园碰撞。
- 启真湖衔接限定在剧场与湖区之间，不再开放旧全景的左右环线。人物只在该侧视场景读取近大远小曲线，普通瓦片校园使用固定显示比例。
- 两套坐标禁止混用：普通校园读取 `zijingang-campus-runtime.json`，启真湖衔接读取 `zijingang-campus-loop-runtime.json`。

## 剧情衔接

- 东区大食堂追逐完成后进入首次剧场。
- 首次剧场反转完成并离场后，玩家从 `campus_theater_junction` 进入一次性湖畔过场：湿纸和残留轨迹向东移动，在启真湖插入段前消失。
- 过场只建立“朝有水的方向移动”的证据，不显示最终地点答案。之后继续使用 CC98、馆藏和微信三条来源完成手机地图推断。
- `qizhenLake.locationBriefingSeen` 是过场完成事实。已完成存档直接恢复自由移动；未完成存档从安全的剧场路口重放。

## 修改和验证

1. 更换 IonicJian 普通校园源图、空气墙或入口坐标时，同步更新 `zijingang-campus-runtime.json` 及可审查遮罩，运行 `npm run map:zijingang:topdown`。
2. 修改普通校园水层、道路层、建筑层或正式水纹帧后，运行 `npm run map:zijingang:water:build` 重建 Alpha 图集和分块清单，再运行 `npm run map:zijingang:water`。生成过程以明显水色作连通种子，吸收相邻深色和白色波纹，用建筑层局部水纹避免把岸边整块扣空，并在最后以道路 Alpha 硬裁切桥面；运行时不按颜色判断水域，也不读取 `godot/`。
3. 修改湖段拼接参数时编辑 `scripts/build-zijingang-loop-panorama.py`，运行 `npm run map:zijingang:rebuild`；不要手工改生成图。
4. 只修改启真湖衔接空气墙或入口坐标时编辑 `scripts/calibrate-wide-campus-runtime.py`，运行 `npm run map:zijingang:loop`。
5. 运行 `npm run map:zijingang` 同时验证 IonicJian 源图哈希、普通校园连通性、动态水面遮罩、2.5D 图像哈希、启真湖脚盒与衔接站位。
6. 运行 `npm run typecheck`、`npm run build:single`、`npm run verify:single`，再从真实浏览器完成宿舍→图书馆→食堂→剧场的俯视移动，以及剧场→启真湖的侧视过场、退出与重进。

### 手工修正水域边缘

`source/topdown/campus_water_mask_override.png` 是一张与底图严格对齐的 `4516 × 3420` 灰度修正层；当前文件已经写入完整的现行遮罩，可直接手绘调整。把它叠在 `zijingang_campus_plate.png` 上编辑，保持画布尺寸、位置和 RGBA 透明通道不变：

- 透明区域：继续采用自动识别结果。
- `100%` 不透明纯白：最终水面覆盖率为 `100%`。
- `100%` 不透明纯黑：最终水面覆盖率为 `0%`。
- `100%` 不透明灰色：灰度就是最终覆盖率，例如 `RGB 128` 约为 `50%`；可直接画黑→灰→白渐变来精修羽化边缘。
- 修正图本身的半透明笔刷也有效：PNG Alpha 会在“自动结果”和笔刷灰度之间混合。自动自然岸线已有 `3px` 柔边，只有局部仍需调整时才手动画渐变；道路和桥面会在修正层之后再次硬裁切，因此不会被灰色笔刷改成软边。

当前图层为全不透明，因此直接修改黑、白、灰即可；若要让某一小块重新采用自动识别结果，再把该处擦成透明。

保存后运行 `npm run map:zijingang:water:build` 和 `npm run map:zijingang:water`。需要整图预览时可运行 `python scripts/build-zijingang-water-overlay.py --preview <输出 PNG 路径>`；预览中的洋红色区域就是最终水域范围与柔化边缘。

## 网页运行边界

- TypeScript `GameState`、控制器、存档和任务是唯一进度权威。
- Phaser 校园场景分别保留普通俯视校园与剧场→启真湖侧视衔接的图像比例、世界坐标、碰撞网格和状态流程。
- Vite 开发版和离线单文件均使用同一 Phaser 场景，不存在引擎切换分支。
