# FLC motion · 既有界面延伸记录

日期：2026-10-29。范围：未来学习中心独立 Godot 样例中的太阳能车距离竞赛与机器人送货／空车返程。基线 HEAD：`4c5fa5f147ce3cdd492895a97f9cca69fd415efd`；本次检查对象包含尚未提交的工作区文件。

按 Impeccable `reference/document.md` 的扫描方法记录已实现的视觉事实。方向来自 `.impeccable/flc-motion-brief.md`、现有房间、`signal_sync_view.gd`、原生字体与美术规范。根目录没有 `PRODUCT.md` 或 `DESIGN.md`；此次仅编写这份局部记录，没有建立或替换全局设计系统。

## Overview

**结论：两套实验作为现有房间的局部延伸，保持了原生工作台的视觉关系；最终截图支持 R1 停车边界及 R2 方向／文字对比修正交付到本地样例。**

既有双屏工作台把主要操作放在中央实物区，标题、说明和线索在上方，恢复／记录／提示操作在下方。新实验延续这一结构：太阳能板与小车是观察主体，机器人、货物、接缝和选中模块是操作主体。房间截图中小车置于现有工作台台面，没有另造地图或替换房间外观。

本次进行了源码、最终静帧、原始图集和已有输入结果的文档复核；没有重新运行游戏或观看整段视频。以下“截图可见”与“源码／结果文件支持”分别记录，不能由完成截图推断整个交互过程。

## Colors

保留了双屏工作台的深蓝灰底、暖浅文字和金属边线。新实验将台面变亮，便于读取距离、凹槽、车体和货物；形状和文字同时表达状态。

| 用途 | 已实现颜色及来源 | 观察 |
| --- | --- | --- |
| 页面／操作条 | 背景 `#18242D`、按钮 `#344452`、文字 `#E8E0C8`；两份 view 共用 | 保留既有外壳的明暗层级 |
| 当前模块 | 浅面 `#C5C1A9`、浅色轮廓；普通模块 `#929D9C` | 选中态有完整边框，旁边另写列、行和模块名称 |
| 单向入口 | 箭头 `#202B35`，箭头背后留与模块同色的净空 | 最终桌面／手机阻挡截图都能分清右向单行箭头与左向返程 |
| 日照读数 | 明台面 `#A9ACA7` 上用 `#202B35`；阴影时切换浅文字 | 最终竞赛图的距离、时间、刻度和车体互不遮盖 |

按源码中的不透明 sRGB 颜色计算，机器人侧栏文字／台面为 **4.93:1**，普通模块方向箭头为 **5.16:1**，选中模块方向箭头为 **7.94:1**，太阳能明台面读数为 **6.27:1**，新按钮悬停／焦点文字为 **5.24:1**。这是对应色对的名义比值，不是全屏像素或全部状态的无障碍认证。

**既存偏差，仅记录：** `signal_sync_view.gd` 已使用 `#101820`、`#18242D`、`#B7C8CC`、`#BFD0B7` 四个规范 32 色之外的字面颜色。它原有悬停／焦点底色 `#526B7A` 与文字 `#E8E0C8` 的名义对比度约 **4.26:1**，低于美术规范的 4.5:1 目标。本轮没有改动该工作台。新实验也包含规范色板外的台面／状态颜色，不能据此声明严格 32 色验收。

## Typography

两份工作台都通过 `native_typography.gd.body_font()` 使用项目的 Morning Note Regular，并沿用打包的符号后备字体、无系统字体后备和 nearest 采样。新实验标题为 24 逻辑单位（旧双屏为 22），正文、按钮与底部反馈为 23，辅助读数为 20。该变化增强新实验的标题层级，没有引入第二字体体系。

在 844 × 390 的完整 16:9 等比显示中，23／20 逻辑单位分别约为 16.6／14.4 屏幕像素。最终提示图中第三层线索、状态栏与底部反馈完整显示，未覆盖轨道或按钮。此记录不把字体族复用等同于全项目 scale-aware 文本机制验收。

## Layout

- 逻辑画布仍为 960 × 540；桌面截图为 1280 × 720，横屏触控截图为 844 × 390。后者居中等比容纳，左右留边；实验板、文字与车体没有横向拉伸。
- 旧双屏采用一排 44 单位高动作按钮；新实验将配置与执行拆成两排，均为 48 单位高，保留顶部“返回房间”和底部反馈。板面结束在逻辑 y=368／364，配置排从 y=378 开始，执行排从 y=436 开始。
- 机器人采用 5 × 3 模块区域，右侧单独列出载货状态和选中模块；太阳能车采用两条距离轨道。最终竞赛与阻挡截图均无车体、测量文字和动作条重叠。
- 48 单位按钮在 844 × 390 等比显示中约为 34.7 屏幕像素，高于规范 28 的绝对下限，但没有达到 44 的主要触点目标。旧双屏同样使用整幅等比缩放。本次仅确认模拟横屏布局，物理手机触达舒适度仍未实测。

## Elevation & Depth

延续房间中灰色金属工作台与双屏近景的实物层次：贴图承担车轮、底盘、空车厢的体积；平面矩形、凹槽深线和窄桌沿承担实验台结构。没有新增悬浮卡片、装饰阴影或发光成功徽章。

两张透明母版保持固定相机的四向构图，`frames.json` 为方向提供独立裁切。渲染按 `right/down/left/up` 选帧并统一缩放，没有旋转整张斜俯视位图。太阳能板与货箱由运行时独立绘制，车厢空／满可直接观察。

## Shapes

外壳沿用方角、1 单位细边按钮；焦点用 2 单位边线。选中模块同时改变面色并描边。方向使用明确箭头，状态使用“载货去程／空车返程”和“货物：在车上／已送达”等文字，避免只靠色相判断。

R1 的停车尺寸来自同一个 `motion_prop_metrics.gd`：模块中心距 126 × 72，机器人帧统一缩放 0.16，停车余量 2 逻辑单位。左向帧宽 605，半宽为 48.4；停止比例为 `0.5 - (48.4 + 2) / 126 = 0.1`。模型把这个边界映射回移动缓动进度，view 复用同一帧尺寸。最终阻挡图中夹爪仍位于目标模块可见边缘外，空托盘和已放在送达站的货箱同时可见。

## Components

| 实际检查的截图（相对本记录目录） | 可直接确认的状态 | 对照依据 |
| --- | --- | --- |
| `desktop/solar_complete.png` | 30.0 / 30 秒；改装车 116.3 格、基准车 106.5 格；刻度、时间和车体分离 | 两条轨道、独立面板、控制条与读数实现 |
| `desktop/robotics_return_blocked.png` | 空车朝左停在反向单行模块前；货物已送达；选中模块有边框与名称 | 共享道具尺寸、模型接缝停止规则 |
| `mobile/robotics_return_blocked.png` | 同一停车位置与方向关系；动作、说明及反馈均完整 | 844 × 390 等比布局 |
| `mobile/robotics_hint_final.png` | 第三层线索可见并可收起；轨道和动作条仍可读 | 三层提示只由主动请求推进 |
| `signal_regression/signal_initial.png` | 旧双屏标题、浅文字、中央实物与底部动作排 | 既有视觉基线 |
| `desktop/solar_room.png` | 既有工作台上有独立小车，玩家在台侧 | 房间到近景的物件连续性 |
| `desktop/robotics_loaded.png` | 车朝右，箱子在车厢中，“载货去程” | 独立货物状态与方向帧 |
| `desktop/robotics_unloading.png` | 箱子处于离车移向站台的中间位置，文案说明送达只是一半 | 装卸插值与阶段文案 |

提示最终截图本身已处于完成状态，不能单独证明“提示没有完成作用”。源码 `_hint()` 只更新面板开关和层数；已有桌面、触控输入结果分别记录 **52 项通过、0 失败**，包含主动提示、完整 30 秒竞赛、卸货尚未完成、空车实际返回、失焦、中止及原位退出。双屏回归结果另记 **19 项通过、0 失败**。这些结果是本次读取的既有运行证据，没有在文档步骤重跑。

## Do's and Don'ts

- **Do** 继续从现有房间工作台进入实验，保持独立道具与同方向近景；方向、选中、载货和阻挡同时给出形状与文字。
- **Do** 共用帧尺寸来定位渲染与停止前缘；用已发生的试跑轨迹和用户主动请求的线索解释现象。
- **Don't** 把读取提示、装卸动画或一张完成截图当作成功判定；机器人成功条件仍是送达后实际回到起点。
- **Don't** 将这份局部记录升级为全楼、全部 25 间房间、物理手机、严格色板或正式发布验收；不要借本次记录修复既存双屏／房间漂移。

## Evidence record

检查根目录：`/Users/zhu/.codex/worktrees/north-clean-object-layers-20261027/755`。除上表八张截图外，还实际查看了 `solar_chassis_atlas.png` 与 `delivery_robot_atlas.png` 两张原始图集。

已读文件：

- `.impeccable/flc-motion-brief.md`
- `godot_native/campuses/future_learning_center/scripts/motion_lab_view.gd`（全部；布局、字体、状态、绘制）
- `godot_native/campuses/future_learning_center/scripts/motion_prop_metrics.gd`（全部；帧尺寸与停止距离）
- `godot_native/campuses/future_learning_center/scripts/signal_sync_view.gd`（全部；既有视觉基线）
- `godot_native/campuses/future_learning_center/scripts/robot_delivery_model.gd`（75–129 行；缓动边界、货物与完成条件）
- `godot_native/scripts/ui/native_typography.gd`、`godot_native/docs/art/ART_BIBLE.md`、`godot_native/docs/art/art_direction_v1.json`
- `godot_native/campuses/future_learning_center/assets/puzzles/provenance.json`、`frames.json`
- `godot_native/campuses/future_learning_center/review/MOTION_PUZZLES_20261029.md`
- 本目录的 `desktop/motion_input.json`、`mobile/motion_input.json`、`signal_regression/signal_input.json`、`native_preflight.json` 与 `native_preflight.json.meta.json`

核心源码 SHA-256：

| 文件 | SHA-256 |
| --- | --- |
| `motion_lab_view.gd` | `0817e933c1330824e26375b6420c34acb45a43290dbf7f5666e533dbdcae5a4f` |
| `motion_prop_metrics.gd` | `26a1748bbb589e29e1d2b8777deaa410f68bee74dc28d9e730720d3f5526b81c` |
| `signal_sync_view.gd` | `bf183f4cf0558310f5bf76001205575090cc037c24c197d6d6bd03d338bbb931` |

四张必需最终截图身份：

| 截图 | 尺寸 | 文件修改时间 UTC | SHA-256 |
| --- | --- | --- | --- |
| `desktop/solar_complete.png` | 1280 × 720 | 2026-10-29 10:42:44 | `9d89a2a7436226b7ecc9d2aacfd3c5b500c3b240ebd75c40b57439910fdbc4ac` |
| `desktop/robotics_return_blocked.png` | 1280 × 720 | 2026-10-29 10:42:54 | `ba298ae2f63912a521efcf02cd86cad07036146637e3f164ba5b01ca7ef5715b` |
| `mobile/robotics_return_blocked.png` | 844 × 390 | 2026-10-29 10:44:47 | `35068badcf6239aee2e24ccfa4c5bb8a01a0f726c981b6d1476f5bf3de5d7ad1` |
| `mobile/robotics_hint_final.png` | 844 × 390 | 2026-10-29 10:44:57 | `ea5593c44672993c59c35c93e84bc76293739e9a105b6aa495669640a3adbfe6` |

两张母版均为 1254 × 1254。逐字节 SHA-256 同时匹配 `provenance.json` 与其中记录的本机生成原文件：太阳能底盘 `8d114908c94fad76d998d23e05c95f3f8798f5fca08666ac995999cd465c9c4e`；机器人 `d4c110d988f13844a163955ef00dfab6b0caf97e5726507dffbd13597132f377`。`productionAcceptance` 为 `false`；`alphaRange: [0,255]` 仅记录透明度范围，不能推断只有二值 alpha。没有加工或覆盖原图。

原生 preflight 元数据注明 Godot **4.7.1.stable.official.a13da4feb**，选中 5 项全部通过，但 `partial=true`、`fullSuitePassed=false`，另有 536 项未运行。该 preflight 早于这四张最终截图，不能作为最终完整内容的全套验收。真实新玩家难度、物理移动设备、全楼美术与正式集成／发布仍在本记录范围之外。

本次写入仅为本文件；没有修改脚本、素材、全局设计文件或既存偏差。
