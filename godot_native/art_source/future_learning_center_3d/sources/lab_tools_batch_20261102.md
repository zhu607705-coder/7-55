# 第二批：实验工具设备方案样板

基线`9cf0d22bced86434b3596181aa00cefa03123c5a`（首批`a028f96`加独立资产CI）。本批不是手持工具的另一套型号，而是机电区现有工具设备的细化样板。

| 独立样板ID | 既有对应项 | 沿用尺寸（宽×深×高） | 依据和本次边界 |
|---|---|---|---|
| printer_enclosure_study | printer_h2c | 492×514×626mm | asset_catalog原有H2C尺寸；2026-11-02重新读取厂家规格页确认。已有`review/h2c_inspection.png`实际像素已查看。只细化原场景的封闭外壳、门框、床板与导杆示意，不是H2C外观精确复刻 |
| laser_enclosure_study | laser_p2s | 1000×639×268mm | asset_catalog原有P2S尺寸摘录；本轮厂家wiki请求超时。沿用`build_scene.py:laser_p2s()`与原场景布局，只作封闭设备方案，不称已复核厂家外观 |
| bench_power_supply | Bench power supply | 300×250×280mm | `build_scene.py:electronics_lab()`已有机电台面设计。现有`review/mechatronics_walk.png`实际像素已查看。无品牌、型号、额定输出或现场尺寸断言 |

H2C尺寸文字来源：<https://bambulab.cn/zh-cn/h2c/specs>，本轮可读取。P2S原始来源：<https://wiki.xtool.cn/zh/p2/specification>，本轮未成功读取。官方图片检索未返回可用图，不把自行设计的机壳冒称厂家产品复刻。既有截图是作者原场景证据，不是厂家照片或本批新截图。

## 细化内容

- 打印设备方案：分开的壳板、门框、玻璃、铰链、把手、床板、导杆与支架；屏幕为空白，内部为示意。
- 激光设备方案：分开的箱体、闭合透视盖、铰链、把手、支撑格栅与导轨；不建激光束、不模拟安全联锁或工作状态。
- 台式电源方案：机壳、面板、空白显示窗、旋钮、通风造型与脚垫；端子未接线，没有电压、电流、极性文字或功能代码。颜色不是电气接线教程或产品认证。

所有模型是静态装饰/近看样板，没有控制功能、机械运动、通电、测量或操作承诺。实际设备安全要求不由这些模型表达。

## 管线与材质

`现有场景和尺寸依据 → Blender4.3.2独立细化 → 三档真实几何 → glTF Transform/Draco → Three.js独立复用模块`。

不调用Hi3D/Hyper3D，不购买服务，不覆盖原5.2.2主场景。材质采用明确的PBR颜色、金属度、粗糙度和玻璃透射因子，没有伪称PBR贴图。玻璃通过真实`KHR_materials_transmission`保存，不能把CPU截图视作浏览器透射效果验收。

薄片倒角曾出现零面积面；现将倒角限制在最短边的45%以内，从几何源修正。编码保持严格「解码前后面数相等」，没有跳过检查。新增可选位置精度参数（16–20bit，默认仍16）；本批用20bit保留微小紧固件。高精度不替代减少面数；三档仍独立建模并真实减少面数。

## 文件与复现

- `scripts/build_lab_tools.py`：生成器，单位米。
- `sources/models/lab_tools/<id>/<id>.blend`：独立编辑源，仅含物件；没有展示台、镜头或灯光。
- 同目录`lod0/1/2_source.glb`：三档独立几何。
- `web/assets/models/lab_tools/<id>/`：plain/Draco GLB及逐档manifest。
- `web/lab_tools_assets.js`：按投影高度选档，多实例共享几何/材质；尚未在主viewer调用。
- `review/lab_tools/*.png`：本轮Blender CPU Cycles近景，不是网页截图。

```sh
blender -b --factory-startup -t 2 --python scripts/build_lab_tools.py
npm ci --prefix pipeline
node pipeline/build_lab_tools.mjs
node pipeline/test_lab_tools.mjs
```

源生成和摄影可分别使用`-- --skip-render`、`-- --render-only`；单件摄影可追加`--asset=<id>`。摄影台、镜头和灯光不会导出到GLB或独立物件blend。

## 验证边界

本批重新运行首批324项回归，另做本批真实Draco解码、尺寸、索引、材料、空白显示、部件和LOD测试。原建筑、房间、碰撞、游戏UI、签到对白与Godot存档均不改变。浏览器socket权限限制仍在，不重试绕过；网页集成、物理手机、正式Godot仍未验收。

另提供`printer_enclosure_study_cutaway.png`：摄影时仅隐藏前玻璃，便于检查内部支架和床板。它是构造查看图，不是开门动画、不表示设备有该运行状态。普通闭合盖图仍保留。CPU64采样玻璃存在噪点，不能据此认定最终网页材质效果。
