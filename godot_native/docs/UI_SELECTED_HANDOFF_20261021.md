# 用户锁定的 5 项界面方案

来源：2026-10-21 用户在聊天粘贴的《7:55》界面评审全文；这不是从浏览器本地存储推测的选择。后续明确选择覆盖此前对旧对话方案的否定。所有原剧情/目标文案保持 controller 所有；预览里的虚构示例文字不进入游戏。

| 方案 | 既有游戏适配 | 衬底 |
|---|---|---|
| HUD-2（历史选择，后续已覆盖） | 地图不再常驻顶部/左侧任务柱；原任务在左下角手记按需查看 | 无常驻任务面板 |
| INTERACTION-1 底部物件提示 | 横向居中，贴住地图底部安全区；已有 nearby 物件原名称/动作提示；不改接近判定 | none |
| DIALOGUE-2 底部人物对话 | 保留右侧排版宽度，贴住可用区域下沿；Library 确认推进与 C3 定时叙事，以及普通 narrative 模态 | none |
| JOURNAL-3 单页手记 | 调查记录、原目标/进度、按需展开历史、原线索对照入口 | none |
| THEATER-1 下方双区控制 | 保留配置；实际梁祝扇影源缺失，未伪装成已有取票机或追光小游戏 | none |

用户粘贴的摘要没有 `layout.mode`。最初按候选名称映射为左侧任务柱、居中物件牌、右侧对话。2026-10-21 用户随后明确指出“提示不应该放在最底部吗”，覆盖其中的垂直居中位置：物件提示与对白改用底部安全边界。窄屏只调整位置、宽度、换行及滚动；锁定的字体、字号、颜色、透明衬底与剧情推进方式保留。

## 后续位置修正：底部安全区

交互提示在其实际文本高度完成布局后，保持底边距 8 个屏幕像素；空闲操作说明不再占用一条不可见的反馈行。原任务内容在按需打开的手记内保留滚动。对白同样贴住所选安全区域的下沿，避让地图内常驻的实际物品行。C3 影片保持原有镜头和可用字幕区域，字幕在该区域内贴底。文本不接管地图点按；剧情原文、确认方式和自动对白时钟均不变。

本地整合后的检查覆盖桌面、手机竖屏与短横屏，含 24 张真实世界渲染和 18 张源对白渲染；这些是开发场景检查，不替代完整剧情通关。验证记录见 `UPSTREAM156_157_INTEGRATION_20261021.json`。

## 锁定的文字角色

| 表面 | heading | body | button | tip |
|---|---|---|---|---|
| HUD | legacy 18 / 400 / #f1efdd / 1.6 | boutique 13 / 400 / #eedff1 / 1.7 | legacy 14 / 400 / #f1efdd / 1.6 | legacy 11 / 400 / #cbd6bb / 1.6 |
| 其余 4 项 | sans 18 / 700 / #f1efdd / 1.6 | sans 14 / 400 / #f1efdd / 1.6 | sans 14 / 400 / #f1efdd / 1.6 | sans 11 / 400 / #cbd6bb / 1.6 |

全部 tracking 0、shadow true、glyph outline 0；spacing 8、corner 6。通用字体滑杆 16 是 1.0 倍率，不覆盖角色字号。90% 是网页 `panelStyle` 的**背景 alpha**；none 下不把文字再乘 0.9，也不偷偷增加全屏遮罩。CSS 双层模糊阴影以 Godot 原生黑色阴影近似，不宣称逐像素相同。Button 阴影通过不接收输入/焦点、不改变最小尺寸的独立文字阴影层实现。

字体：legacy 为原 Campus UI Sans；sans 为预览原始 Noto Sans SC 真 400/700 子集；boutique 为预览原始 Boutique Bitmap 9×9 400。原文件字节保持，并增加同源、同字重的游戏文本覆盖 fallback。无系统字体依赖、无合成粗体。来源、哈希、许可证及生成方法见 `ui_assets/fonts/SELECTED_UI_FONTS.md`。

## 额外明确要求

手机入口采用 44×44 命中区内的 20×30 细描边手机轮廓，保留原 P/打开/返回与输入所有权。不是大“手机”文字矩形。入口按后续明确要求固定在实际地图右下角；未把网页模拟手机菜单复制成新的游戏应用。

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

## Phone launcher refinement (historical upstream choice, superseded)

The phone home launches its existing apps with a consistent set of original 24×24 SVG glyphs in the existing 48×48 phone-local targets. Permanent app-name labels are removed; hover tooltips, keyboard-focus names and accessibility names preserve the actual app names. The original prologue settings gear remains an interactable story object. Notification cards and opened-page titles are not converted into anonymous icons.

The source has ten app IDs, shown conditionally, not six independent routes: `wechat`, `tiyi`, `zjuding`, `settings`, `photos`, `timeline_recovery`→`c35_recovery`, `voice_memos`→`c35_voice`, `cc98`, `control_center`, and currently unavailable `clock`. Campus map remains inside ZJU Ding; there is no invented standalone notes app. Original app order, route callbacks, drag/editing and gear progression remain intact. SVG assets are core boot content and are checked by loading the production dynamic helper from a real PCK in a source-less directory.

The later bottom-pouch and object-led handwritten-journal ideas remain preview directions, not applied replacements for the locked runtime choices.


## 2026-10-21 最后修正：保留原应用，地图内常驻物品

用户明确要求撤销上游手机主页图标替换。`phone_pages.gd` 已恢复整合前的原彩色 `_app_icon` 图案、应用名称和原有网格；不再实例化 `phone_launcher_icons.gd` 的线框 SVG。原排序、拖动编辑、可用性门槛、路由和独立设置齿轮仍由原逻辑负责。上节 SVG 记录只描述历史上游方案。

地图按可用窗口等比最大化；桌面保留原 `960×540` 空间合同，手机直接探索保持原源坐标与碰撞。手记/菜单与明暗切换放在实际地图左下角，右侧直接显示原物品图像，44×44 命中区、滚动、选择、查看、组合与拖放保留。地图不再显示背包开关，遗留排队回调不会改变布局。物品数量、选择、查看和滚动不参与地图尺寸或相机计算。交互提示与对白贴住这行控件上方的底部安全区。

地图右下角保留手机入口；手机右下角的地图入口只在已有地图可恢复时出现，返回原场景、位置和检查点。地图不再显示常驻顶部任务栏或模式文字。验证与源包摘要见 `UPSTREAM156_157_INTEGRATION_20261021.json`；手机物理设备、Gecko/WebKit 和新开完整四章手动通关仍需各自验收。

## 彩色系统图标（本次补充要求）

原手机应用的彩色图案是图标表现参照。地图手记、明暗切换、手机入口和手机上的返回地图改用填色像素物件：纸页/皮革手记、金色太阳、暖色月牙与蓝色夜空、蓝灰手机、彩色折叠地图。使用锁定 32 色中的 4–12 色、80×80 原生母版和最近邻显示。34px 图案与 44px 命中区分离，位置、路由、物品行和世界尺寸不变；原应用主页保持已恢复版本。规格和验证见 `COLORED_CORNER_ICONS_20261021.json`。

## 图标底板统一（后续明确修正）

底部手记、明暗切换、手机/地图入口及物品行统一使用同一个原生 `apply_slot_style`：44×44 米白色 `#F4EAD5` 底板、棕色边线、4px 像素圆角、零内容边距。所有鼠标/禁用状态保持同一底色，选中、焦点和悬停只改变边框；物品行与工具行共享 y 坐标。彩色物件图案保留。此项覆盖之前工具入口使用透明背景的记录，不改变原手机主页应用图案。

## 2026-10-22 签到页局部恢复

课堂签到按用户后续明确要求恢复原 P11 像素网格/课程卡/描边键盘，单独使用 Fusion Pixel 字体；成功打印回执采用细像素羊皮纸与单色文字印章。本项是签到页的局部覆盖，不将该像素字体套用到其他已锁定表面。原输入、四位码、缺勤0收集、出纸时钟和故事交接不变。详见 `CHECKIN_PIXEL_RESTORATION_20261022.json`。

### 2026-10-22 — Prologue downflow revision

User requested a very fast falling-character treatment inspired by stackedlol's ASCII animation and objected to flashing and an unexplained Continue. The active native prologue now uses a stable flowing glyph field, repeated continuously descending authored clue lines, fast physical word bodies and punctuation wakes. Read-only clue review remains the way to stop and read. Pause actions sit at the bottom and name the view they restore. This activity no longer uses an alternating whole-screen white strobe. Check-in paper/print-slot presentation and all controller proof gates remain intact.

### 2026-10-22 · 连续字符词云

用户保留前段字形精度和时间，要求中段无停顿并统一拼字。活动线索和目标均使用同一ASCII汉字采样；线索词云两列连续向下穿过读线索与拦截的切换。固定旁白、操作控件和主动回看使用清晰字体。词云独立时钟不改变目标生成、物理碰撞或章节推进。详见 `PROLOGUE_TERMINAL_DENSE_20261022.json`。

追加：小字符从四侧汇入笔画，0.28秒完成，大字仍保持原下落精度和时间。背景格缩小为4×6，笔画最小3×4。错误窗统一终端像素字形；重试、回看、关闭回看和可选帮助集中在画面右下角148×34的小控件列，保留键盘焦点与触屏点击。


### 2026-10-22 · 最新覆盖：纯净字流

用户明确要求删掉失败说明、“再试这段字流”和“重看完整线索”。原生场景已删除失败标题/原因、重试、回看/关闭回看、落点帮助及 R 快捷键，并删除底部常驻“字句仍在流走”。本节覆盖上面的右下角小控件方案。真实失误后直接继续当前阶段，保留已接字与持有输入，只重新发出缺少的字；连续失误不会自动过关。原密集字符、实际错误窗、剧情旁白和已完成记录保留。显式系统暂停仍可恢复，减少动效仍呈现原静态线索。验收见 `PROLOGUE_CLEAN_FLOW_20261022.json`。

### 2026-10-22 · 加速与递进难度

按用户后续要求提高实际拦截难度：三个阶段目标速度由360/390/420提高到580/660/740px/s，出字间隔从950ms缩至600/540/480ms；窗口移动由440提高到600px/s，保持快速拖动响应。流动线索由260提高到430px/s，正常读线索前置时间减半，减少动效仍保留原静态阅读时长。首词等待220ms、失误补发350ms、阶段切换280ms。真实扫掠碰撞、原语义与顺序、六词门槛、失误保留和最终长按均沿用。验收见 `PROLOGUE_FAST_FLOW_20261022.json`。

### 2026-10-22 · 用户澄清覆盖：只加快中间接续

上一节是误解后的候选，已撤回。用户指的是中间接续段落慢，关键反应字维持原节奏：360/390/420px/s、950ms出字间隔、首词350ms、重试700ms和窗口440px/s。仅普通段落前置阅读减半、段落完成切换650→280ms，以及非交互线索字符流260→430px/s。减少动效仍保留原阅读时间；原目标、碰撞、字幕音频、长按和存档门槛不变。当前验收见 `PROLOGUE_FLOW_TRANSITIONS_20261022.json`。

### 2026-10-22 · 字流开始至抓住旁白约40秒

用户明确计时范围后，先通过 ChatGPT 网页端 Extra High 评审，再按“发现挡板—辨认坐标—重组旁白”编排连续遭遇。三段合计27个原词体，其中六个原目标、21个原干扰词；首次真实反弹作为不计失误的教学，后续干扰词正常检验。目标反应速度、950ms基础节奏、窗口速度和六词门槛保持原样。成功立即衔接，失误保留进度和当前词流编排，只补已经出现过的缺字；不能靠故意失败跳出未来答案。顺利实际输入路线从字流到抓住旁白实测38.85秒，暂停不计入，等待不能通关。方案与网页来源见 `PROLOGUE_40S_DESIGN_20261022.md`；最终验收见 `PROLOGUE_FORTY_SECOND_FLOW_20261022.json`。

### 2026-10-22 · 续玩页生图重构

用户标注的“未完成的拦截”页已替换为黑底终端续页：原创新生成的终端、回执与逸出字符插画，固定16色和细像素网格；标题及文字左对齐，底部仅突出继续入口，操作说明通过次级入口在插画区域内展开。保留原继续资格、单次意图、存档与拦截玩法；不影响约40秒字流节奏。实际 Godot Web 电脑及触屏模拟各555项检查通过，额外原生四尺寸布局/触摸检查59项通过。5241和用户原标注标签页均已切到新版，停在续玩页。素材/提示词及指纹见 `art/ENDING_RESUME_ART_20261022.json`，验收见 `ENDING_RESUME_ILLUSTRATED_20261022.json`。
