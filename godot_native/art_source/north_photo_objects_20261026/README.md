# 北教独立对象候选 · 20261026

**11 张实拍参照美术候选，尚未接入游戏。** PNG 原样复制，没有本地改绘、重采样、裁剪或 alpha 修正。图片不会证明现实的尺寸、坐标、楼层配置或当前家具清单。

目录位于既有 `art_source/.gdignore` 下，不成为生产场景资源；本次不改运行时、交互、碰撞、存档、导出配置或地图。对象后续应接入独立对象层，不烘焙到四栋建筑底板。

## 对象索引

稳定 ID 不随文件版本变化。文件名采用仓库 snake_case；原下载文件名、原始 SHA256、尺寸、字节数及逐像素 alpha 统计均在 [objects.json](objects.json)。

| 稳定 ID / PNG | 来源可确认的位置 | 保留特征 / 补全边界 |
| --- | --- | --- |
| [north1_104_microwave](png/north1_104_microwave_photo_ref_web_v1.png) | 北1-104咖啡区 | 白机身、暗色窗、双旋钮；隐藏侧面、脚部及俯视转换为补全 |
| [north1_104_loveseat](png/north1_104_loveseat_photo_ref_web_v1.png) | 北1-104咖啡区 | 灰弧背、双坐垫；底部与转换视角为补全 |
| [north1_104_pendant](png/north1_104_pendant_photo_ref_web_v2.png) | 北1-104咖啡区 | 黄铜浅罩；顶面、吊线长度与安装细节非实测 |
| [north3_109_doorplate](png/north3_109_doorplate_photo_ref_web_v1.png) | 实拍门牌写北3-109；不推断楼层 | 深色横框、银边、绿侧条；屏幕留空，厚度与反光补全 |
| [north3_building_display](png/north3_building_display_photo_ref_web_v1.png) | 北3；楼层未知 | 黑色大横屏；内容留空，生成比例不是设备尺寸 |
| [north_complex_locker](png/north_complex_locker_photo_ref_web_v2.png) | 北教楼群；栋号/房号未知 | 浅柜、暗把手、窄控制列；背部与底座简化 |
| [north_complex_speaker](png/north_complex_speaker_photo_ref_web_v1.png) | 北教学楼；栋号/房号未知 | 黑色竖椭圆音箱；网孔与支架非厂家规格 |
| [north_complex_clock](png/north_complex_clock_photo_ref_web_v1.png) | 同上 | 薄黑数字钟壳；数字不烘焙，厚度/侧控为补全 |
| [north_complex_double_door](png/north_complex_double_door_photo_ref_web_v2.png) | 同上 | 木质双门叶、竖玻璃、执手；被遮挡下部补全，仍有轻微投影斜度；仅一张关闭状态，不是逐扇动画 |
| [north_complex_power_module](png/north_complex_power_module_photo_ref_web_v2.png) | 北教楼群；栋号/房号未知 | 楔形壳、浅面板；插孔仅视觉近似，非电气安装图 |
| [north_complex_study_divider](png/north_complex_study_divider_photo_ref_web_v2.png) | 同上 | 黄绿直板、浅边；安装片与背面简化，少量低 alpha 彩边保留 |

## 来源与时间

- [浙江大学后勤餐饮指南](https://zulg.zju.edu.cn/guide/food.htm)：地址为教1-104，照片未给拍摄日期。
- [浙江大学官方澎湃号：智慧教学楼](https://m.thepaper.cn/baijiahao_20011689)：发布于2022-09-22。只有两张照片的标牌能进一步确认北3/109，其余不得分配具体楼栋或房号。
- [材料学院现场教学报道](https://mse.zju.edu.cn/2025/0610/c51029a3060469/page.htm)：发布于2025-06-10，文中活动日期2025-05-22；没有单独照片拍摄时间，也没有具体栋号/房号。

原照片逐件直链见 registry。来源照片不随本 PR 再分发；公开访问不等于开放许可。候选是基于照片的 AI 美术解释，不是大学背书、竣工图或2026现状证明。仅使用公开实拍作为网页生图参考，未上传既有生成场景；不含纯文字门扇概念、失败版本、原照片、聊天链接、过程截图或工具记录。

## 使用契约与 QA

- 坐标原点是完整 PNG 画布左上角。`visible_bbox_alpha128` 使用右/下边界不包含的约定，只用于视觉 QA，**不得作房间/碰撞/可行走多边形**。
- `preview.pivot_canvas_px` 与 `uniform_scale` 是艺术预览提示，不是测量。只允许等比缩放；吊灯使用悬挂点，其余按各自支撑或安装点解释。所有世界坐标、实测尺寸、碰撞、导航和实例保持空值。
- 11张均有真实 alpha=0 外围。沙发 alpha 为0/255，其余大部分实体约247–254，保留网页原生柔和 alpha 与少量低 alpha 彩边。不要把 `reported_core_alpha_range` 当成重新测得的保证：它是生成批次的主体采样记录；独立校验重新计算全图透明/不透明/半透明计数与可见包围盒。
- 不清除 alpha=0 像素的隐藏 RGB；应以 alpha 合成，不应把 RGB-only 视图当成不透明棋盘素材。
- 逐张原图已目视检查；**游戏内目标尺寸、相机投影、遮挡、动画、实体手机与正式美术风格验收仍未完成**。候选不能仅凭图片或哈希测试称为 production-ready。

从仓库根运行（Node，复用现有只读 PNG decoder，不安装新依赖）：

```sh
node godot_native/tools/verify_north_photo_objects.mjs
node godot_native/tools/test_north_photo_objects.mjs
```

校验范围：精确11个唯一 ID/路径、完整 SHA256/字节数、原生尺寸/RGBA、真实 alpha 计数、包围盒、来源、锚点范围、等比预览值、无虚构落位。负例覆盖篡改、重复、目录越界、未知来源、伪造位置/测量/几何及 alpha 错误。测试只读，不修改图片，也不是完整游戏验收。
