# Zijingang Campus Artwork

## 当前运行基线

- 普通校园探索加载 IonicJian 提交的 `src/assets/rpg/campus/zijingang_campus_plate.png`，源图和世界尺寸均为 `4516 × 3420`。`src/data/maps/zijingang-campus-runtime.json` 统一管理宿舍、图书馆、东区大食堂和剧场的入口、碰撞与出生点。
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
2. 修改湖段拼接参数时编辑 `scripts/build-zijingang-loop-panorama.py`，运行 `npm run map:zijingang:rebuild`；不要手工改生成图。
3. 只修改启真湖衔接空气墙或入口坐标时编辑 `scripts/calibrate-wide-campus-runtime.py`，运行 `npm run map:zijingang:loop`。
4. 运行 `npm run map:zijingang` 同时验证 IonicJian 源图哈希、普通校园连通性、2.5D 图像哈希、启真湖脚盒与衔接站位。
5. 运行 `npm run typecheck`、`npm run build:single`、`npm run verify:single`，再从真实浏览器完成宿舍→图书馆→食堂→剧场的俯视移动，以及剧场→启真湖的侧视过场、退出与重进。

## Godot 迁移边界

- TypeScript `GameState`、控制器、存档和任务仍是唯一进度权威。
- Godot 校园场景接入前必须分别复现普通瓦片校园与剧场→启真湖侧视衔接的图像比例、世界坐标、碰撞网格和状态流程。
- 当前 Phaser 图是迁移验收基线；Godot 通过资产、碰撞、输入、存档恢复和 Blink/Gecko/WebKit 全流程验收后再替换。
