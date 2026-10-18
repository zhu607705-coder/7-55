# 7:55 · Blender 楼梯可玩样段

这是一份独立 Godot 工程。它将两跑楼梯和两个转角平台的程序粗几何替换为真实 Blender / GLB 网格。
此样段以 `examples/blender_stair_sample/` 独立 Draft PR 保存供评审。它不是十二跑完整关卡，不改变正式游戏入口，也未合并到主线。

## 打开与操作

1. 用 Godot 4.6.x 打开 `preview/project.godot`，等待资源导入
2. F6/F5 运行，点击“开始向上”
3. A/D 或左右键沿路线移动；Space 跳过平台维修挡架；Esc 暂停
4. 触屏左右按住移动，上滑或第二指触碰跳跃

相机画幅、角色比例、像素人物、手机蓝光、原追逐节奏和固定 60 Hz 物理保留。
方向键可以持续按住完成平台转弯。这里只支持沿路线前后移动和跳跃，不支持横向绕行。

## 结构与材质

- 两跑整体踏步，连续斜底板，踏步鼻口和双防滑槽
- 厚平台与等高最后一级相接，真实可通行的扶手回转
- 弯管扶手、立柱、底座与固定件
- 真实门窗开口、深门框、嵌入门扇、门把手、窗框及窗台
- 凹入玻璃、04 标牌、低对比墙裙和平台收缝
- 0.55 m 高的折叠维修挡架，保留原碰撞尺寸
- 无新增光晕、发光描边或高噪点贴图

运行时加载 `assets/blender/stairwell_sample.glb`。可见环境不再显示旧 BoxMesh 粗几何。
真实 GLB 网格直接投射保安黄光阴影；不可见实体代理只服务于光束空气路径的保守裁剪。
镂空挡架的中间允许光通过，横杆与腿会遮光。窗洞没有被装饰油漆面覆盖。

## 编辑与重建

- Blender 源：`source/stairwell_sample.blend`
- 可重复生成脚本：`source/build_stair_sample.py`
- GLB：`preview/assets/blender/stairwell_sample.glb`
- 生成清单：`preview/assets/blender/stairwell_manifest.json`

在本目录执行：

```sh
blender -b --threads 2 --python source/build_stair_sample.py
godot --headless --path preview --editor --import
```

模型用米制。脚本显式转换 Godot Y-up 与 Blender Z-up 坐标。
Blender 4.3.2、Godot 4.6.3 已验证。不需要外部建模插件、下载材质或手工贴图烘焙。
`build_stair_sample.py` 重建模型和材质，不会重写 Godot 运行逻辑。

## 已验证的范围

```sh
godot --headless --path preview --script res://tests/test_blender_sample.gd
godot --headless --path preview --script res://tests/test_blender_sample_camera_input.gd
godot --headless --path preview --script res://tests/test_endless_stair_beam.gd
```

- GLB 真实实例化、可见粗网格为零、真实网格投影
- 从实际 GLB 三角面向下射线，核对全样段踏步/平台高度与原碰撞一致
- 楼板上穿光束裁剪、挡架开孔透光/横杆遮光、窗洞凹入玻璃
- 自动输入通关、需要跳跃、不跳会被障碍拦住并被追上、原证明回放有效
- 四种画幅的脚部/头部/前方预见、转角镜头连续、输入释放与暂停复位

单次理想输入通关 685 tick，约 11.42 秒，有 2 个楼梯门槛与 1 次真实跳跃。
短视频是普通 D/Space 自动输入：完整第一遍、0.8 秒结果菜单、第二遍局部。
视频是 Godot MovieWriter 30 fps 离线输出，物理仍为 60 Hz；不代表真人试玩或手机实机帧率。

资源预算与环境基准见 `verification/`。这里是专项测试，不把旧十二跑整关测试冒称为全量通过。

## 后续边界

本次只验两跑样段。继续铺十二跑、增加可绕行分支、修改追逐机制或整合主线，均不在这份交付内。
原生移动端 GPU、真人触屏体验和整关综合性能尚未验收。
资产来源和现有字体许可证见 `ASSET_LICENSES.md`。
