# 昌平：图中桥南露水段独立分层

本补丁在 Draft #135 的精确树 `a431a3a5cbdd20fe26ad9c10a93dec059ed958a5` 上，只新增柳湖南桥南侧、下一浅色横跨构件之前的一段可见水面。它没有独立官方池名，不命名新地理地点。

## 原画与边界

- 源图 `godot_native/campuses/buct_changping/assets/approved-changping.png`：950×1656，SHA-256 `f92a8de6ef703bab4b2e471a49acc082dd4d128d264d99d3ed1818fdb0c93707`
- 固定源裁框 `[395,867,24,21]`；保守水色连通域 116 像素，向内退 1 个源像素后保留 72 像素
- 实际 alpha 外接范围为 x400–408、y872–882。非透明 RGB 与原图逐字节一致
- 主桥、桥底难辨暗色、两岸、东侧树叶、下方横跨构件、下一水段全部静态；不补不可见桥下水
- 旧主池 7,140 水像素、素材、距离图、shader、组件代码及动画参数均未改变。两层 alpha 不重叠，共 7,212 像素

已核对存储的官方 2023 年 6 月校园图和在线卫星影像。官方图支持柳湖与南向水系的相对位置；原画决定可提取的像素。官方图由[北区办校园图页面](https://bq.buct.edu.cn/233/listm.htm)提供。在线影像拍摄日期未核实。本分段不是测绘、现实水位或水文连通性结论。

## 为什么保持静态

保留 2 像素静止边缘后，仅剩 22 内部像素，最大内部距离为 4 像素，没有容纳旧主池 8 像素渐变带的完整核心。使用一个无动画 shader 的 `Sprite2D`，不扩岸线、不强行加波纹、不生成新画面。

## 双层所有权与选择

`LiuLakeSouthBridgeWater` 先验证注册位置、正式导入纹理和可见 RGBA 校验值，再原子替换底图材质。底图同时挖去旧主池和本段的真实 alpha；隐藏本段会露出真实挖空，不能从原底图看到重复水面。`hide()` 用于独立可见性，保留挖空；`free()` 是退出清理，将该部分所有权恢复给原底图。

- 本段先退出：恢复旧主池原有 cutout 材质
- 旧主池先退出：恢复主池像素，继续保留本段挖空
- 最后一个对象退出：恢复完整原底图
- 后续外部对象已替换底图材质：清理不覆盖新所有者
- 失败或重复安装不改变底图，不留下半成品

鼠标和触屏只按真实 alpha 选择，透明岸边不误选；旧主池与本段选择互斥。水面没有碰撞、寻路、POI 或进度权力。原 41 个路点、3 个 POI、82 个铺装多边形、共享四向学生和原东路保持不变。最近既有铺装距本段约 144.73 源像素。

## 验证与复现

源检查沿用 `scripts/check-buct-changping-liuhu.mjs`；native 测试加入原 `godot_native/tools/test_buct.mjs` 的串行集合。完成正式项目资源导入后可在已有隔离测试环境中执行：

```sh
node scripts/check-buct-changping-liuhu.mjs
godot --headless --path godot_native --script res://tests/test_buct_changping_south_bridge_water.gd
godot --headless --path godot_native --script res://tests/test_buct_changping_liuhu.gd
godot --headless --path godot_native --script res://tests/test_buct_changping_east_road.gd
```

仅需要仍图 GPU 诊断时，设置工作区内的 `BUCT_SOUTH_BRIDGE_OUTPUT`，使用已有显示环境执行 `capture_buct_changping_south_bridge_water.gd`。脚本不启动显示服务器，不录制视频；它是固定相机像素诊断，不冒充连续行走。

已完成：CPU 源几何 11 项、公开源检查 103 项、新段 native 50 项、旧主池 native 59 项、原东路 native 41 项均通过。GPU 8 项严格像素检查通过：静态全窗 0 差；隐藏只改变 1,152 屏幕像素（72×4²），外部 0 差；主池两个波相仍有变化，本段与主池外 0 差；先退出主池和退出全部对象均恢复到原画 0 差。实际截图 960×720，固定 4×相机，7 张仍图；目视桥岸树完整、没有明显亮缝或黑边。唯一日志提示是驱动不支持切换 VSync，未见 ERROR/RID/ObjectDB。没有重录视频或宣称人工鼠标测试。具体证据与 GPU 结果见同目录 `BUCT_CHANGPING_SOUTH_BRIDGE_WATER_VALIDATION.json`。

边界：仅保守分离 72 个明确露水像素；不声明完整提取每个岸边混合像素。没有新增路网、内部场景、正式 TileMap 替换、下一水段或海淀校外水渠。本地有限测试不等同完整仓库 aggregate 或发布后的 CI。
