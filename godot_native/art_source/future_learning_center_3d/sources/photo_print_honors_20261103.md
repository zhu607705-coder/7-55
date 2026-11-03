# 打印台与荣誉柜：照片重建候选

这批模型依据用户 2026-11-03 02:16 UTC 提供的三张照片。建模前已经查看真实像素：一张打印台照片，以及同一荣誉柜的局部、全景照片。模型是可编辑的本地重建，不是照片扫描或厂家 CAD。所有尺寸均按照片比例暂定，不能代替现场测量。

## 六件独立资产

| ID | 结构依据 | 暂定外包尺寸 X / Y / Z（m） |
| --- | --- | --- |
| `photo_print_white_mfp` | 白色圆角机身、独立前门与拉手、黑色出纸区、斜面按钮区、扫描盖、不对称 ADF 白壳、两层黑色纸托、外伸下纸托、侧风口 | 0.446 / 0.567 / 0.483 |
| `photo_print_black_compact` | 矮宽黑机身、上盖细缝、前出纸槽、右侧高窗格与纵向隔条、低矮外伸托边 | 0.507 / 0.419 / 0.224 |
| `photo_honors_display_cabinet` | 下柜六块木门、白色台面、白色背板、上方六格木架、浅上楣、连续灯罩轮廓 | 3.630 / 0.526 / 2.328 |
| `photo_honors_lightwood_frame` | 浅木框四边、内退口、独立内容面、背板与后撑脚 | 0.330 / 0.146 / 0.252 |
| `photo_honors_certificate_stand` | 木质底座、微后倾的金属背板、独立空白面、薄边夹层 | 0.260 / 0.105 / 0.335 |
| `photo_honors_trophy_silhouette` | 黑金宽底台、黑色竖柱、金属切面柱体、银色开放方头 | 0.260 / 0.175 / 0.368 |

打印台上的两台白色设备复用同一个源模型。两张荣誉柜照片也只形成一个柜体资产。柜体门数、总宽和高度是当前候选的构图参数，不是现场盘点结果。设备内部、被遮挡的连接件和型号细节没有虚构成精确产品结构。

相框以横向规格保存。组合函数可沿 X / Z 改变画幅，并保留 Y 方向的厚度和后撑脚深度。它不是把整个相框等比放大，因而不会把薄木框变成厚盒子。组合中的物件数量和摆位用于近景评审，不代表现场数量。

## 内容面与材质

照片中的人物合影、姓名、证书文字、奖项名称、学校或品牌标识、二维码都没有烘入模型。内容面使用明显的灰白或蓝灰色空白板，并带有 `REPLACEABLE` 标记。没有自动生成新的证书内容、奖项或标志。奖杯只表现可见轮廓与材质，不声称对应任何特定奖项。

木纹由固定种子和公式生成，不含原照片像素。木质资产目录内的 `synthetic_oak_lod0.png`、`synthetic_oak_lod1.png`、`synthetic_oak_lod2.png` 分别为 384、192、96 像素。近景源内已打包贴图；GLB 内嵌实际使用的图片。打印机使用金属度、粗糙度和底色因子。没有法线图或 AO 图，不宣称完整扫描材质。

## 文件与复现

- 生成器：`scripts/build_photo_print_honors.py`。
- 每件源文件：`sources/models/photo_print_honors/<id>/<id>.blend`。
- 三档交换文件：同目录的 `lod0_source.glb`、`lod1_source.glb`、`lod2_source.glb`。
- 统计与 SHA-256：`review/photo_print_honors/build_report.json`。记录字段沿用 `asset`、`level`、`triangles`、`boundsBlenderXYZ`、`sizeBlenderXYZ`、`sha256`，近景档另记 `blendSha256`。
- 源场景复查：`review/photo_print_honors/source_scene_audit.json`，逐件打开六个 `.blend`，确认无展示舞台、相机或灯光，并确认图片已打包。
- GLB 二进制复查：`review/photo_print_honors/source_glb_audit.json`，读取全部 18 个源文件的实际三角形，确认无退化三角形、面数与报告一致、哈希一致。
- CPU 图：`review/photo_print_honors/photo_print_counter_near_view.png`、`photo_honors_cabinet_near_view.png`、`photo_print_white_mfp_close_view.png`。

```sh
blender -b --factory-startup -t 4 --python scripts/build_photo_print_honors.py -- --skip-render
blender -b --factory-startup -t 4 --python scripts/build_photo_print_honors.py -- --render-only
```

使用 Blender 4.3.2。LOD 降低圆角分段、按钮圆弧、风口数量与次要细节。三档都保留打印机 ADF、控制台、纸托，以及柜体和陈列件的主要轮廓。每个网格检查有限坐标、面面积、闭合边邻接、非零体积与已应用修改器。边界从更新后的世界矩阵和真实顶点计算。

灯光、相机、地面，以及打印台组合的中性台柜都只存在于渲染场景，不进入单件源文件或 GLB。PNG 使用 Cycles CPU 渲染，不能代替浏览器、手机或正式游戏验收。本批不修改已有资产、建筑主场景、网页入口、碰撞或正式 Godot 工程。Draco 压缩与实际集成由后续管线单独处理。
