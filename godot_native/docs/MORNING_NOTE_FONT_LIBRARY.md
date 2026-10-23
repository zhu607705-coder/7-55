# 晨札像素 / 755 Morning Note

《7:55》的可编辑像素字体家族，当前版本0.1.1。正文、标题、手机签到、回执、地图提示、剧场UI和字流共用这套字形规则。世界图片、演员和物品图标不因换字体改变尺寸、滤镜或碰撞。

## 字形规则

| 项目 | 规格 |
| --- | --- |
| 原生格网 | 24×24；基线20；上升20、下降4 |
| 汉字 | 字宽24；主体约20–22格；密集部件留至少1格空隙 |
| 主笔画 | 原创字形主笔2格，复杂部件内横1格；短方收笔，拐角靠连续色簇转折 |
| 拉丁字母 | 大写与数字高16、小写主体高12；下伸最多4格；窄字和宽字独立字宽 |
| 数字 | 每字前进12格；0与O、1与I/l区别明确；冒号沿同一基线 |
| 正文 | Regular400；不加描边或伪粗体 |
| 标题 | 独立Medium500文件；密字内白不作无差别膨胀 |
| 渲染 | 像素轮廓、无MSDF、无子像素位移；文本局部nearest，保留按实际显示比例重采样 |

0.1.1重画全部62个数字和字母：降低瘦高字身，采用更细的阶梯弧线、开放字腔和分明的大小写比例。数字仍是12格等宽；中文字形和标点保留。原创数字/字母在Regular与Medium中共用同一主字形，不能据文件的400/500元数据声称每个ASCII都有不同笔重。

本轮字形、布局、实际Godot桌面/手机渲染及签到浏览器验收记录见[数字与字母第二稿](MORNING_NOTE_LATIN_ACCEPTANCE_20261023.json)。

风格来自校园笔记与清晨纸面：开放的字腔、稳定的足线、克制的阶梯转折。不要随机敲掉笔画、加无意义的点、挖断汉字部件，或把字压扁以塞入按钮。正文优先可读；世界与手机保持原有逻辑视口。

## 文件与来源

- [Regular TTF](../ui_assets/fonts/MorningNote-Regular.ttf)：正文、按钮和说明。
- [Medium TTF](../ui_assets/fonts/MorningNote-Medium.ttf)：标题、强调和字流轮廓。
- [实际覆盖清单](../ui_assets/fonts/morning_note_manifest.json)：字体hash、字重、覆盖、来源与构建规则。
- [原创矩阵](../art_source/fonts/morning_note_v1/original_glyphs.json)：137个逐字设计的可编辑矩阵，包含95个可打印ASCII和42个汉字。
- [完整格网](../art_source/fonts/morning_note_v1/derived_grids.json)：每字Regular/Medium的24格矩阵及来源标签。
- [字体样张](../art_source/fonts/morning_note_v1/specimen.html)：浏览器可交互查看小字号、字重、中文、数字及黑底效果；同目录`web/`提供WOFF2。

137个原创矩阵没有从外部字形提取。其余剧情汉字从项目已有的OFL Noto CJK子集重建到统一格网，少量符号来自OFL Fusion Pixel；来源逐字登记。**本库是原创字形与开源衍生字形组成的家族，不能称为完全原创的完整中文字库。** 静态剧情覆盖由实际文件生成，任意新名字和未来文案仍需检查。

组合字体文件采用SIL OFL1.1，[项目字体许可](../ui_assets/fonts/MORNING_NOTE_OFL.txt)、[Noto原许可](../ui_assets/fonts/OFL.txt)及[Fusion原许可](../assets/rpg/fonts/licenses/FUSION_PIXEL_FONT_OFL.txt)随包提供。原创矩阵与构建工具沿用项目Apache-2.0；不会把上游字体改标为Apache。

## 接入边界

`scripts/ui/native_typography.gd`缓存两款真实字重，显式禁用系统字体回退。`selected_ui_theme.gd`保留已选HUD、对话、日志和剧场的布局、字号、颜色与阴影，只统一字体。`theater_typography.gd`、签到页及回执使用同族；手机文本的测量和绘制用同一资源。

字流仍用20×20的汉字采样格与原有细字符图集，轮廓改由Morning Note Medium生成。物理目标、窗口、时间、输入和剧情条件不变。三维楼梯墙上的既有物理字牌、照片/视频里已经烘焙的文字不在这次动态UI替换范围。

六款旧UI实验字体留在原位置作为历史来源，不再进入生产导出。新双字体与显式符号回退、许可必须随第一章核心一起加载，不能为减小首包而让正文先显示缺字框。

## 构建与扩字

构建只需要本项目已有字体和矩阵，不使用系统字体、网络服务或私人字体目录。工具依赖为`fonttools[woff]==4.61.1`、`Pillow==11.3.0`，只在构建时需要。

```sh
python godot_native/tools/build_morning_note_font.py
python godot_native/tools/build_prologue_ascii_masks.py
python godot_native/tools/build_morning_note_font.py --check
python godot_native/tools/build_prologue_ascii_masks.py --check
```

新增原创字先编辑`original_glyphs.json`，按原生格画笔画并保留`origin`。构建器验证许可源hash，追踪当前静态剧情字符，并将生成TTF交给独立FreeType栅格器回读，逐字检查轮廓、边距与基线能否还原格网。输出可重复生成，`--check`不改文件。

## 验收取舍

不再断言“必须叫Campus UI Sans”“正文标题必须同一个Font实例”或“禁止像素字体”。仍检查真实字形覆盖、真实字重、无隐式系统回退、字号下的排版、物品/输入框命中范围，以及字体与许可在实际PCK中的闭包。详见[自测审查](FONT_TEST_REVIEW_20261023.md)。

实际查看桌面1280×720与1440×900、手机390×844和横屏；DPR与非整数缩放单独检查。样张与静态字符覆盖通过，不能代替长文、输入、底部字幕和真实字流的运行检查。手机模拟不当作物理设备验收。
