# Zijingang Campus Artwork

## 当前运行基线

- Phaser 当前只加载 `zijingang_campus_loop_panorama.png`。正式尺寸为 `13668 × 1084`，保持源像素比例和横向伪 `2.5D` 视角。
- `zijingang_campus_plate.png` 与 `source/topdown/` 保留给 Godot 校园重建和空间参考，当前 Phaser 场景不加载它们。
- `source/panorama/zijingang_legacy_panorama.png` 是旧 `11744 × 1084` 拼接图的可复现输入。`qizhen_lake_reflection.png` 在旧图 `x=8400` 后插入 `1924px`，得到当前环湖图。
- 插入点位于首次剧场东侧。旧坐标 `x>=8400` 的建筑和入口统一右移 `1924px`，不允许场景文件各自补偿。

## 道路、空气墙和环线

- `zijingang_road_walkability_mask.png` 是运行时 `4px` 压缩网格的可审查展开图。
- 可走主面从 `y=864` 开始，覆盖整张图的连续道路。入口走廊、前景障碍和剧情站位由 `scripts/calibrate-wide-campus-runtime.py` 统一生成。
- 湖水、草坪、围栏、建筑立面和未标定区域保持阻挡。空气墙不得覆盖画面中连续的人行道、入口走廊、拼接缝或环线抵达点。
- 左右边界只在前景道路上触发双向环线。短淡入隐藏边界传送；剧情、道具、任务、存档和相机缩放保持不变。
- 人物统一读取 `RpgPlayerTextures.ts` 的深度曲线。远处为基础尺寸，靠近画面底部逐步放大；碰撞脚盒保持固定世界尺寸。
- 侧视建筑属于背景美术，顶视图的建筑矩形和遮挡多边形不得附加到当前环湖图。

## 剧情衔接

- 东区大食堂追逐完成后进入首次剧场。
- 首次剧场反转完成并离场后，玩家从 `campus_theater_junction` 进入一次性湖畔过场：湿纸和残留轨迹向东移动，在启真湖插入段前消失。
- 过场只建立“朝有水的方向移动”的证据，不显示最终地点答案。之后继续使用 CC98、馆藏和微信三条来源完成手机地图推断。
- `qizhenLake.locationBriefingSeen` 是过场完成事实。已完成存档直接恢复自由移动；未完成存档从安全的剧场路口重放。

## 修改和验证

1. 修改湖段拼接参数时编辑 `scripts/build-zijingang-loop-panorama.py`，运行 `npm run map:zijingang:rebuild`；不要手工改生成图。
2. 只修改空气墙或入口坐标时编辑 `scripts/calibrate-wide-campus-runtime.py`，运行 `npm run map:zijingang:walkability`。
3. 所有入口、剧情站位、插入边界、深度参数和环线点都写入 `src/data/maps/zijingang-campus-runtime.json`，场景只读取该文件。
4. 运行 `npm run map:zijingang` 验证图像哈希、完整道路、脚盒、入口、剧场到湖段路径和双向环线。
5. 运行 `npm run typecheck`、`npm run build:single`、`npm run verify:single`，再从真实浏览器完成键盘、点击移动、触摸、首次过场、退出重进和左右环线验收。

## Godot 迁移边界

- TypeScript `GameState`、控制器、存档和任务仍是唯一进度权威。
- Godot 校园场景接入前必须复现当前图像比例、世界坐标、碰撞网格、深度曲线、环线传送和食堂→剧场→启真湖状态流程。
- 当前 Phaser 图是迁移验收基线；Godot 通过资产、碰撞、输入、存档恢复和 Blink/Gecko/WebKit 全流程验收后再替换。
