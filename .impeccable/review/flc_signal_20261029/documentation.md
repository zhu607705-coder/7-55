# 2F 双屏同步谜题：既有系统扩展文档复核

复核日期：2026-10-29（Asia/Taipei）。范围：未来学习中心 2F 团队工作室的双屏同步原型，以及它进入、退出现有房间的表现。

本次按 Impeccable `new-work.md` 第 7 节的 ordinary extension 分支完成文档复核：对照完成版与既有系统，保存原有系统文件，记录检查证据和现有偏差。它不是 Argon 复核，也不代表全部 25 个房间的设计已经过 Argon 优化。

## 文档边界

- 既有视觉依据为 [ART_BIBLE.md](../../../godot_native/docs/art/ART_BIBLE.md)、[art_direction_v1.json](../../../godot_native/docs/art/art_direction_v1.json) 和 [native_typography.gd](../../../godot_native/scripts/ui/native_typography.gd)。项目没有 `PRODUCT.md` 或 `DESIGN.md`；这不改变既有系统的权威，也不构成新建视觉系统的理由。
- 本复核只写本文件。没有创建或改写全项目 `DESIGN.md`、`.impeccable/design.json`，没有修改代码、素材、地图、正式控制器或存档。
- 主线程已尝试 Impeccable context；其下载因代理失败中止，并已说明直接读取既有上下文的 fallback。本复核没有重试下载，没有额外有效 context 指令。
- 已读取 Impeccable `reference/document.md` 与 `reference/new-work.md` 的扩展及完成要求；没有读取 documenter 的 agent 定义文件。
- 这是 Godot 原生界面，未用 HTML/CSS detector 对其作出判定。主线程提供的运行版本是 Godot 4.7.1；本次是对已提供原生运行证据的只读复核，没有重新启动引擎或重跑测试。

## 检查的证据

源码范围为 [signal_sync_view.gd](../../../godot_native/campuses/future_learning_center/scripts/signal_sync_view.gd)、[signal_sync_model.gd](../../../godot_native/campuses/future_learning_center/scripts/signal_sync_model.gd)、[floor_view.gd](../../../godot_native/campuses/future_learning_center/scripts/floor_view.gd) 和 [play.gd](../../../godot_native/samples/future_learning_center/play.gd)。既有操作台的 [workbench_view.gd](../../../godot_native/campuses/future_learning_center/scripts/workbench_view.gd) 用于比较局部交互范式与配色。

桌面与模拟横屏手机的七组 PNG 均已逐一打开。它们分别为 1280×720 和 844×390；没有把黑色留边误作空白画面，也没有将传输中的截图当作未加载完成。

| 状态 | 桌面证据 | 模拟横屏证据 | 实际可见内容 |
| --- | --- | --- | --- |
| 房间 | [signal_room.png](desktop/signal_room.png) | [signal_room.png](mobile/signal_room.png) | 2F 房间、玩家、独立工作桌与显示器；屏幕上的小图案与局部模型对应 |
| 初始 | [signal_initial.png](desktop/signal_initial.png) | [signal_initial.png](mobile/signal_initial.png) | 编辑稿 B、回放 A、两台接收屏版本不同；源、线、端口和屏幕同时可见 |
| 首层提示 | [signal_hint.png](desktop/signal_hint.png) | [signal_hint.png](mobile/signal_hint.png) | 提示 1/3；失败现场保留，提示置于顶部 |
| 末层提示 | [signal_hint_last.png](desktop/signal_hint_last.png) | [signal_hint_last.png](mobile/signal_hint_last.png) | 提示 3/3、已到最后一层、收起线索；两行正文没有覆盖端口或连线 |
| 记录 | [signal_notes.png](desktop/signal_notes.png) | [signal_notes.png](mobile/signal_notes.png) | 制作便条与试用记录；接线关系仍可观察 |
| 传输 | [signal_transmitting.png](desktop/signal_transmitting.png) | [signal_transmitting.png](mobile/signal_transmitting.png) | 白色信号点沿线路传播，接收屏尚未一起更新，修改按钮处于禁用状态 |
| 成功 | [signal_success.png](desktop/signal_success.png) | [signal_success.png](mobile/signal_success.png) | 交换后的接收屏都显示 B；端口身份仍随甲/乙保留，结果说明位于底部 |

[桌面输入记录](desktop/signal_input.json) 为 19 项、0 failures，`touch: false`；[模拟横屏输入记录](mobile/signal_input.json) 为 18 项、0 failures，`touch: true`。两者包括接近工作桌后打开、原接线失败、提示不推进完成、逐层提示需主动请求、记录不推进完成、点选接线、第二次不同修改验证、交换屏幕后端口身份、断开与撤回、原位置退出、重新打开保留接线、失焦取消，以及其他楼层不能打开此交互。桌面另有鼠标拖线检查；模拟触控记录没有这一项。

这些是现有 JSON 记录的复核结论，不是本复核另行执行的 37 次操作。截图证明对应可见状态；状态转换的证据来自记录与生成这些记录的 `check_signal_sync()` 源码。

## 与既有系统的对应

| 方向契约 | 完成版证据 | 文档判定 |
| --- | --- | --- |
| 复用房间与独立透明物件 | `floor_2.json` 中 `team` 使用 `f2_team_ambient.png`；操作入口是现有 `team_desk_6`；房间屏幕是 `team_monitor_front_9`、`team_monitor_front_13` | 复用已有场景和物件标定，没有新增房间几何 |
| 保持同一空间表现 | 世界继续使用原房间模块；操作界面沿用局部工作台的平面展示方式，四个屏幕复用同一显示器母版与同一裁切 | 没有新绘一套冲突视角；本复核不将其扩大为对原房间透视的重新验收 |
| 960×540 逻辑视口等比缩放 | `play.gd` 的 `SubViewport` 固定 960×540，`fit()` 使用两轴比例的最小值，`Vector2.ONE * ratio` | 桌面完整铺满；844×390 内有效画面约 693.33×390，两侧各约 75.33 像素留边，比例未拉伸 |
| 原生文字 | `signal_sync_view.gd` 从 `native_typography.gd.body_font()` 取字体；文字由 Label、Button、`draw_string()` 绘制 | 沿用 Morning Note Regular 及已有显式符号 fallback，没有把提示文字烘焙进图片 |
| 屏幕、线端、传播同屏 | 七个编号端口、源和四个屏幕保持固定构图；`_wire()` 按路径绘制信号点 | 提示和记录位于顶部区域，实物状态仍可比较 |
| 形状、编号与颜色等价 | A/B/C 各自有字母与不同九宫格形状；端口有 1–7，接收屏有甲/乙；颜色只作补充 | 判断同步无需单独依赖色相 |
| 操作反馈由对象状态表达 | 接线即时变化；传输中有线路信号点；接收屏更新后再给结果文字；房间内两个屏幕也绘制模型图案 | 延续可观察操作台范式，没有以独立结果卡替代屏幕状态 |
| 不改正式进度或存档 | 模型是局部 `RefCounted`，只持有接线、验证和运行状态；没有生产任务、背包或存档 API；进入时停止房间移动，退出恢复原位置 | 这是局部实验状态；重新打开保留接线不等于跨进程存档持久化 |

### 素材来源

已打开两份原素材，并将当前文件 SHA-256 与素材清单及 HEAD 字节比较：均一致。

| 素材 | 清单来源与尺寸 | SHA-256 |
| --- | --- | --- |
| [monitor_front.png](../../../godot_native/campuses/future_learning_center/assets/objects/monitor_front.png) | `object_assets.json`：builtin imagegen，独立透明母版，原字节保留，review draft；1536×1024 | `95f9fdc626aa31adc160e60a2ff354526ba91a2ad1861d5afed836401efdbc68` |
| [f2_team_ambient.png](../../../godot_native/campuses/future_learning_center/assets/rooms/f2_team_ambient.png) | `room_assets.json`：builtin imagegen，独立透明母版，neutral ambient，原字节保留；1211×1299 | `43a1423ef0b385c74c20f54c4fd778bfe96a3e61d8172f17d3c21e637651ec9c` |

显示器使用清单中 `(336, 193, 864, 645)` 的同源裁切，界面缩放系数为 `190 / 864`，宽高使用同一系数。两张图本次均未替换。来源清单证明的是已登记的生成素材及文件身份，不证明素材是实地照片或具有实测尺寸。PNG 未带可见的文本来源块；原有来源记录在 JSON 中，本次未补写元数据。

## 字号、线索与难度边界

完成版正文和按钮字为 23 逻辑像素，提示进度辅助字为 20。模拟横屏比例为 `390 / 540 = 0.72222`，对应约 16.61 与 14.44 截图像素。两组截图里的提示、记录和底部反馈均可见，没有正文穿过线端或被控件截断。

常态文字 `#e8e0c8` 对按钮底色 `#344452` 的静态对比度约 7.60:1。桌面焦点/悬停截图中的文字实际采样为 `#f3f3f3`，对 `#526b7a` 约 5.06:1；不能以常态字体色替代状态字体色而误判该截图。此处只核对上述已采样组合，没有据此声明所有全局主题状态均已通过对比度审计。

提示只由按钮或 H 请求；失败、等待、传输与成功没有自动调用提示。第一层提示观察哪台屏幕未随修改，第二层提示追踪一次变化停在哪里，第三层指向制作便条和回放记录。它们没有直接列出解答端口组合。记录提供“第一轮 A 改 B”和“回放保留 A”的可比较事实；查记录不授予完成。

局部模型要求两台接收屏实际收到至少两种不同的新图案。线路改动、断开或撤回清除本轮验证；回放画面偶然与当前角标相同不会被当作实时收到。传播时长、图案和结果说明均由同一局部模型驱动。提示改善了观察路径，但没有替代操作验证。

主线程交接的 finish reviewer 最终 disposition 为 **ship**，其回合范围是三项修复：23/20 字号、顶部线索不遮线路、H3 终层和收起按钮；三项均被记为 resolved。本文件对照了这些截图，不把该 verdict 扩写为全部界面、全部 25 个房间或最终难度曲线的无问题证明。

## 保存的现有偏差

以下只记录，不在此次局部文档任务中扩大修复：

- **规范色板与既有操作台并非完全一致。** 新界面的主要墨色、文字、边线、琥珀与蓝灰取自 32 色表，但 `#18242d`、`#b7c8cc`、`#bfd0b7` 已存在于未改动的 `workbench_view.gd`，`#101820` 已存在于预览宿主背景；它们不在规范 32 色列表内。不能称为全项目严格限色验收完成。
- **房间外壳 HUD 的小字是继承状态。** `floor_view.gd` 的原有标题为 17、地点为 14、移动提示为 13 逻辑像素，模拟横屏约为 12.28、10.11、9.39 像素。截图中它们比新谜题正文显著小；这些字号的代码在 HEAD 中已存在。当前 23/20 的复核结论只适用于谜题界面。
- **44 是逻辑按钮高度。** 新按钮及端口热区高 44 逻辑像素，在该模拟横屏截图中约为 31.78 像素，超过项目的 28 最低数值但没有证明达到 44 CSS 像素的主要触点目标。输入记录通过不等于实体手机可用性验收；端口宽度 54 逻辑像素对应约 39 像素。
- **字体复用与 scale-aware 路径须区分。** 本界面使用已有字体对象与 nearest，但源码直接调用 `body_font()` 和 `draw_string()`，没有调用 `apply_body()` 或 `enable_scale_aware_text()`。当前两种尺寸的可读性已有截图证据，不据此声称更小视口、全部缩放倍率或任意系统字体行为均已验证。

## 版本与证据身份

复核时基线 HEAD 为 `4c5fa5f147ce3cdd492895a97f9cca69fd415efd`。双屏源码尚属工作区变更，其中两份 `signal_sync_*.gd` 为未跟踪文件；因此 HEAD 本身不是包含该完成版的提交。下列哈希界定本次读取的实际源码：

| 文件 | SHA-256 |
| --- | --- |
| `signal_sync_view.gd` | `bf183f4cf0558310f5bf76001205575090cc037c24c197d6d6bd03d338bbb931` |
| `signal_sync_model.gd` | `f4d41e52a82630aad337cd615af009a9ca79e4518c2c4a71798271a1be102ecd` |
| `floor_view.gd` | `5037aa860e5a242bb0ec6ccfa36d66e19c5ed60027d38401e7b383c5fc0a48a4` |
| `samples/future_learning_center/play.gd` | `5221a13d4b1102f2f9f4b7bcb81dcd85c6ce12931b330682fe05c476ac8b3864` |
| `desktop/signal_input.json` | `2bffc902708957fc1540fd57c4b4794eb66b0773ec4827b9ae14040245a6213f` |
| `mobile/signal_input.json` | `2c847893e78c7afc97dc9f0e714717d40a90cbe60903b3084e54e9e0341efa42` |

读取时桌面 PNG 的文件修改时间为 15:50:58–15:51:04，模拟横屏 PNG 为 15:47:36–15:47:42；均晚于 `signal_sync_view.gd` 的 15:47:33。时间次序只是新鲜度线索，源码、状态内容和输入记录才是本次对应证据。

`floor_2.json`、`floor_3.json`、`floor_4.json`、两份来源图、ART_BIBLE、art_direction_v1 和 native_typography 均与基线 HEAD 相同。未生成新的全局设计规范；本次文档复核未改动它们。

后续若改动上述视图、模型、宿主、素材或截图，应重新核对受影响部分。正式控制器接入、跨会话保存、Web 浏览器验收、实体手机、部署发布，以及 Argon 对 25 房间的提示/线索/难度评审，均不由本文件代为证明。
