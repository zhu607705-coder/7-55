# 首批小物件：独立材质与几何样板

基线：PR207 / `3de82772c7b96f779a922358bd36e7de58468da7`。

| 样板 | 已有场景依据 | 尺寸边界 | 本次细化 |
|---|---|---|---|
| `caliper_150` 数显卡尺 | `build_scene.py:212–225` 与 `asset_catalog.json` | 长233mm；尺身16mm；外爪40mm；爪厚3.5mm | 锥形量爪、分离滑块、锁紧螺丝、滚轮纹理、刻度、嵌入式空白LCD |
| `screwdriver_3x100` 一字螺丝刀 | `build_scene.py:226–230` 与 `asset_catalog.json` | 长204mm；杆/刀段100mm；刀头3×0.5mm；柄径23mm | 连续握柄轮廓、一体式凹入防滑嵌面、尾盖、套环、金属杆与平刃 |
| `display_tray` 展示托盘 | `build_scene.py` 的 Bottle group display tray | 已有设计420×320×40mm，不是实测/厂家尺寸 | 空心圆角折边、2mm壁厚、可分离防护垫、底部脚垫 |

前两件沿用现有厂商尺寸摘录，不宣称是厂家CAD或现场品牌。第三件沿用场景设计，没有新增玩法含义。卡尺显示屏保持空白，不伪造测量结果；螺丝刀配色不构成绝缘电气认证。模型为静态近看样板，没有新增可操作状态。

这是已有尺寸→Blender本地细化→真实LOD→Draco→Three.js复用的分支。没有调用Hi3D/Hyper3D，也没有付费生成或把手工模型称为AI生成结果。本轮没有新增参考图来源；参考依据是已有场景模型和尺寸表。

## 文件与重建

- `scripts/build_small_props.py`：Blender4.3.2确定性建模，独立新文件，不加载原5.2.2主场景。
- `sources/models/small_props/<id>/<id>.blend`：独立可编辑LOD0物件。
- 同目录`lod0/1/2_source.glb`：按细节预算实际构建，不是给同一网格改标签。
- `web/assets/models/small_props/<id>/`：沿用`pipeline/build_asset.mjs`生成plain/Draco三档与manifest。
- `web/small_props_assets.js`：独立复用接口；多实例共享geometry/material，不改原viewer入口或既有玩法。
- `review/small_props/*.png`：本轮Blender CPU Cycles渲染，不是浏览器验收截图。

```sh
blender -b --factory-startup -t 2 --python scripts/build_small_props.py
npm ci --prefix pipeline
node pipeline/build_small_props.mjs
node pipeline/test_small_props.mjs
node pipeline/test_table_dimensions.mjs
```

所有PBR材质为明确的颜色/金属度/粗糙度因子；没有伪称完整PBR贴图。刻度是几何。GLB不依赖Blender程序纹理。近景采用中性展示台；展示台、镜头、灯光不进入GLB或可编辑物件文件。

## 当前边界

独立样板未替换已提交建筑GLB，避免未经浏览器检查的场景热替换。原房间、碰撞、物件ID、交互、正式Godot工程和存档均不变。网页调用模块的运行效果仍需可启动浏览器环境复验；本云端Chrome socket受限，未绕过限制。Blender渲染不等于浏览器视觉验收。
