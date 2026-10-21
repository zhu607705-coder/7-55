# 用户锁定的 5 项界面方案

来源：2026-10-21 用户在聊天粘贴的《7:55》界面评审全文；这不是从浏览器本地存储推测的选择。后续明确选择覆盖此前对旧对话方案的否定。所有原剧情/目标文案保持 controller 所有；预览里的虚构示例文字不进入游戏。

| 方案 | 既有游戏适配 | 衬底 |
|---|---|---|
| HUD-2 左侧任务柱 | 所有 8 个已登记世界的地点、时钟、当前任务 | 仅局部渐隐 scrim |
| INTERACTION-1 居中物件牌 | 已有 nearby 物件原名称/动作提示；不改接近判定 | none |
| DIALOGUE-2 右侧人物对话 | Library 确认推进与 C3 定时叙事，以及普通 narrative 模态 | none |
| JOURNAL-3 单页手记 | 调查记录、原目标/进度、按需展开历史、原线索对照入口 | none |
| THEATER-1 下方双区控制 | 保留配置；实际梁祝扇影源缺失，未伪装成已有取票机或追光小游戏 | none |

用户粘贴的摘要没有 `layout.mode`。预览历史 compact CSS 与一些候选名称有位置冲突。经父任务确认，按用户明确名称映射：左侧任务柱、居中物件牌、右侧对话。窄屏只调整位置、宽度、换行及滚动，不声称已核对用户浏览器完整截图，不擅自重现大块 expanded 面板。

## 锁定的文字角色

| 表面 | heading | body | button | tip |
|---|---|---|---|---|
| HUD | legacy 18 / 400 / #f1efdd / 1.6 | boutique 13 / 400 / #eedff1 / 1.7 | legacy 14 / 400 / #f1efdd / 1.6 | legacy 11 / 400 / #cbd6bb / 1.6 |
| 其余 4 项 | sans 18 / 700 / #f1efdd / 1.6 | sans 14 / 400 / #f1efdd / 1.6 | sans 14 / 400 / #f1efdd / 1.6 | sans 11 / 400 / #cbd6bb / 1.6 |

全部 tracking 0、shadow true、glyph outline 0；spacing 8、corner 6。通用字体滑杆 16 是 1.0 倍率，不覆盖角色字号。90% 是网页 `panelStyle` 的**背景 alpha**；none 下不把文字再乘 0.9，也不偷偷增加全屏遮罩。CSS 双层模糊阴影以 Godot 原生黑色阴影近似，不宣称逐像素相同。Button 阴影通过不接收输入/焦点、不改变最小尺寸的独立文字阴影层实现。

字体：legacy 为原 Campus UI Sans；sans 为预览原始 Noto Sans SC 真 400/700 子集；boutique 为预览原始 Boutique Bitmap 9×9 400。原文件字节保持，并增加同源、同字重的游戏文本覆盖 fallback。无系统字体依赖、无合成粗体。来源、哈希、许可证及生成方法见 `ui_assets/fonts/SELECTED_UI_FONTS.md`。

## 额外明确要求

手机入口采用 44×44 命中区内的 20×30 细描边手机轮廓，保留原 P/打开/返回与输入所有权。不是大“手机”文字矩形。入口沿用既有安全顶栏位置，避免与右下移动/交互目标重叠；未把网页模拟手机菜单复制成新的游戏应用。

## 验收边界

- 现有手机应用、背包、物理设备和小游戏不是这 5 个任意通用皮肤的替换对象；保留应用语义，逐场景检查它们与新常驻层的边界/遮挡。
- 测试 fixture 与截图并非完整剧情通关；完整清单见 `UI_SCENE_ADAPTATION_MATRIX_20261021.md`。
- 新截图必须绑定本次提交；之前奶油面板/统一单字族候选不是这次用户锁定方案的视觉验收。
- 白字/13px 像素正文在明亮场景的可读性是必须实际查看的风险；如不足，报告具体画面，不自行修改用户锁定色值/字号。
- 梁祝源仍是明确缺口；THEATER-1 配置存在不等于真实梁祝已适配。

## Actual GPU findings and structural follow-up

The first selected-theme capture at `6d94498` (108 candidate PNGs) exposed issues not detected by size-only tests: transparent journal text overlapped exploration prompts; short landscape HUD clipped its objective; C3 dialogue and HUD glyphs still passed through the world's low-resolution texture. These are not accepted visual results.

The follow-up renders selected exploration UI and C3 dialogue in the root viewport at native screen resolution. The pixel-art world retains its own render target and camera. Reading/narrative owners suppress nonessential exploration overlays, and a transparent selected modal suppresses outer exploration chrome without changing visibility-based world bounds. Closing restores presentation. A right-side dialogue no longer reserves its top edge as the bottom edge of the entire world. Existing timed feedback pauses only its presentation countdown while hidden so it is not silently missed. Short-landscape location/time share one row; locked role sizes, colors, spacing, and source objective text remain unchanged.

The next GPU capture must verify the same cases before these fixes are called visually confirmed. This does not resolve the missing latest 梁祝 source.

Follow-up headless checks: native-layer contract 80/80 (including unchanged camera, viewport size and world rectangle through journal open/close); selected layout 1296/1296; feedback ownership/real touch scrolling/wheel boundaries 98/98; static cross-PR integration 2546/2546. Real rendering remains a separate requirement, not inferred from these checks.

A real pointer regression was also found and fixed: a non-overflowing task column must not swallow authored floor taps. The original food-hall queue pointer/blocked-marker test passes unchanged (97 checks). The task column accepts scrolling only when its content actually overflows. Victory camera/doorway/arrival checks (1640) and reversal/pause checks (42) pass with assertions converted from obsolete world-local text coordinates to the actual native-screen rectangles and the user-selected 14 px role (accessibility scaling preserved).
