# 图2休闲座椅：修正版独立源

参考标记：`photo_reference_lounge_02`。已实际查看照片像素。照片只作观察，不作为模型贴图，也不进入源码包。没有复制私有文件标识。旧候选未被用户接受，本组是修正版，不把旧候选称为已通过。

## 照片支持的改动

- `lounge_single_corrected`：厚软包靠背和逐渐降低的两侧、独立平缓坐垫、细滚缝、黑色外部包覆、中央四星底架。
- `lounge_double_corrected`：同一家族的宽双人座。横向较平的靠背曲线单独定义，不直接横向拉伸圆碗。保留一整片坐垫和背部中央浅缝，不凭“双人”名称拆成两块坐垫。
- `lounge_loose_cushion`：可选松散靠枕。照片只证实前景单座上有一只，不应固定附加到每张单座或双座。没有映射明确的场景实例时不自动新增。

照片无法证明绝对尺寸、黑壳具体材料、真实壳厚、隐藏旋转机构或厂家型号。所有尺寸是视觉估计。隐藏连接采用简化中央支撑，不添加品牌、装饰图案或无依据机械结构。

## 尺寸与坐标

源坐标为 Blender Z-up，前方 -Y，米制。单件网格原点一致，变换已应用。运行时通过既有管线统一 yaw=180°，因此交付 glTF 为 Y-up、前方 -Z，地面中心原点，统一缩放为 1。

以下为解码后 LOD0 的 glTF **X宽 / Y高 / Z深**，单位米；微小尾数含量化误差。精确值以各运行时 `manifest.json` 为准。

| ID | X宽 | Y高 | Z深 | 三LOD运行时三角数 |
|---|---:|---:|---:|---:|
| lounge_single_corrected | 0.9739513 | 0.8520610 | 0.8307004 | 15712 / 7248 / 1996 |
| lounge_double_corrected | 1.5289471 | 0.8520592 | 0.8306997 | 15996 / 7532 / 1996 |
| lounge_loose_cushion | 0.3636400 | 0.3636400 | 0.1420001 | 2084 / 1252 / 332 |

靠枕源原点也在底部，摆放和倾斜属于实例层。背面和座底受照片遮挡，未假称测绘还原。

## 文件与复现

- 生成器：`scripts/build_photo_lounge_corrected.py`。独立、无旧整组自动执行副作用。
- Blender 4.3.2源：`sources/models/photo_lounge_corrected/<ID>/<ID>.blend`。
- 三LOD未压缩源：同目录 `lod0_source.glb`、`lod1_source.glb`、`lod2_source.glb`。
- 运行时：`web/assets/models/photo_lounge_corrected/<ID>/`，含各级普通GLB、Draco GLB和manifest。
- 材质：128px本地合成可平铺织物base-color与normal图，已打包进Blend/GLB。黑壳、钢脚和脚垫为PBR因子材质。未使用照片像素。

在art root运行：

    blender -b --factory-startup -t 4 --python scripts/build_photo_lounge_corrected.py -- --skip-render

需要CPU正面建模QA时使用 `--render-only`，或指定 `--asset=lounge_double_corrected`。背面检查可运行 `review/photo_lounge_corrected/render_rear.py`。单件Blend不含摄影棚、相机或灯光，QA相机只在渲染进程中创建。

每个ID运行既有 `pipeline/build_asset.mjs`，参数依次为LOD0源、输出目录、该源真实Z高度、yaw `180`、纹理预算 `512`、LOD1源、LOD2源、position bits `20`。这里的高度参数保持源尺寸，不是重新缩放家具。用锁定依赖安装方式复现，不提交本地node_modules符号链接。

    node review/photo_lounge_corrected/validate_runtime.mjs

## 已完成的验证

1. 三源×三LOD逐件检查：有限坐标、闭合/流形边、正有向体积、非退化面、有限单位法线、已应用修改器和统一对象变换。见 `review/photo_lounge_corrected/build_report.json`。
2. 真实Draco编码后，另一次NodeIO/Draco解码读取全部九个输出。实际比较三角数、每个POSITION对应的NORMAL数、三角面积、单位法线、双向点位/法线值及世界边界。见 `source_vs_draco.json`。Draco可合并量化后重复顶点，因此保留plain/decoded各自顶点法线计数，不把合法去重当成数据丢失。
3. 本次最终九项均通过。最大解码点位误差约0.000001245m，最大法线角差约0.004rad。LOD2除源曲面分段降低外，还经既有管线降至预算；它不是仅做整体缩小。
4. 已实际查看CPU前面、背面和靠枕。背面审查发现过软包穿壳，已修改壳的下部收束并重导/重验；最终背面不再露出橙色穿壳。
5. 源与运行时文件哈希见 `review/photo_lounge_corrected/source_freeze.json`。全部GLB纹理内嵌，交付文件未包含私有Library ID。

CPU图只用于建模QA，不证明浏览器viewer已加载新源，也不证明场景映射、地面贴合、相机视图或交互已验收。最终viewer验证由接入任务完成。本组未改旧源、原始冻结恢复树、场景JS或玩法，也未提交或推送。
