# Future Learning Center · 投影与同物件动作扩展记录

## Overview

2026-10-30，Experience 模式的既有原生游戏修订：回应“同一物件的变化过少”和近景混用投影两个问题。范围为太阳能试车、运货轨道、传动装配、双屏同步四个独立原型。既有 [美术规范](../../../godot_native/docs/art/ART_BIBLE.md)、[执行配置](../../../godot_native/docs/art/art_direction_v1.json)、[原生字体](../../../godot_native/docs/UI_TYPOGRAPHY_AND_INPUT.md) 与模型权限继续生效；本文件记录局部扩展，不另设全局设计系统或 token。

已依次核对 [首次审阅](finish_review.md) 与 [修正评分](finish_verdict.md)，再重开下列八张当前原生截图。F1 显示器屏—杆—底座已连通；F2 面板稳定 30°／60° 的外露支撑、落脚点和受光有可见区别，减少动效时保留。`finish_verdict.md` 的 `ship` 仅覆盖 F1、F2。

| 当前证据 | 可支持的范围 |
| --- | --- |
| [桌面输入](desktop/object_input.json) 47/0；[模拟触屏输入](mobile/object_input.json) 53/0 | 1280×720、844×390，正常实时，均为零键盘事件；四台物件操作、取消、第二触点、回卷与退出的所列路径 |
| [桌面表现](motion_desktop/presentation.json)、[触屏表现](motion_mobile/presentation.json) 各 32/0 | `movieFixedStep: false`；四台屏幕实际渲染支杆探针、30°↔60° 正常／减少动效物件区域差异、预览／装配边界、失焦与两次不同改稿 |
| [录像表现](motion_movie/presentation.json) 32/0；[修正录像帧记录](movie_corrected_frames.json)、[视频元数据](video_metadata.json) | 真实原生渲染的固定步长 30 FPS 演示；651 帧、21.7 秒、960×540；[最终录像](/Users/zhu/.codex/visualizations/2026/10/27/01a17b09-ba73-70c3-8098-7c93af6df733/flc_gameplay_review/object_motion_20261030/objects_motion_native.mp4) 的完整 FFmpeg 解码在最终收据中记录为通过 |
| [运动模型](motion_models.log) 63/0；[信号模型](signal_models.log) 15/0；[楼层空间](floor_spatial.log) 1740/0 | 对应日志中的模型／空间检查 |
| [最终局部预检元数据](native_preflight_after_fixes_final.json.meta.json) | Godot 4.7.1；5 项通过、536 项未运行；`inputChangedDuringRun: false`、`fullSuitePassed: false` |
| [最终验证收据](../../../godot_native/campuses/future_learning_center/review/PROJECTION_MOTION_VERIFICATION_20261030.json) 的 Web 导出记录 | 独立 Godot Web 原型的 import、startup、web_export 均为 0；构建收据仍将浏览器验收列为独立事项 |
| 同收据的修正后浏览器烟测；[太阳能完成](browser_solar_complete.png)、[信号完成](browser_signal_complete.png)、[日志](browser_logs.json) | Codex 内置浏览器 1280×720，两条实际指针路径、零键盘事件；30 秒试车为 116.3 对 106.5 格，双屏依次同步稿件 2、0；两条日志均为空。范围限这两条桌面烟测 |

本次重开：[初始太阳能台](desktop/solar_initial.png)、[双屏完成](desktop/signal_complete.png)、[触屏拖动接收屏](mobile/signal_receiver_drag.png)、[桌面稳定 30°](motion_desktop/solar_hinge_after.png)、[桌面稳定 60°](motion_desktop/solar_60_stable.png)、[触屏减少动效 30°](motion_mobile/solar_reduced_30.png)、[触屏减少动效 60°](motion_mobile/solar_reduced.png)、[录像传动运行](motion_movie/drive_running.png)。未重新运行引擎或浏览器；动效判断结合命名静帧、当前源码及所附报告。旧 `motion/` 的 25 项报告、首段录像及 `movie_final_frames.json` 保留为历史。

工作树基线 HEAD 为 `4c5fa5f147ce3cdd492895a97f9cca69fd415efd`。最终收据按散列定位这次未提交的工作树，登记 29 份源码并记录 6 份受保护源码沿用前次物件优先版本。本次核对收据内 66 条文件散列均一致；六份指定投影／交互脚本及原生字体实现已读，三份修正关键脚本也匹配评分中的完整 SHA-256。浏览器两张完成截图另已重开。

## Colors

沿用安静的蓝灰金属工作面、奶油白车体／纸张、黑橡胶与克制黄铜。新增结构用成组色簇、接触边与明暗表达材质和状态，背景纹理先让出物件轮廓。既有 `755-campus-morning-32` 是美术权威；本批生成 cutout 未获得逐色严格 32 色验收，运行中的受光色也不构成该认证。

## Typography

家族仍为晨札像素 / 755 Morning Note。本操作台通过 `native_typography.body_font()` 使用 Regular，显式携带 Fusion Pixel 缺字回退；常规铭牌与退出文字为 20、笔记及临时反馈为 23 逻辑像素，采用 nearest。文字保持原生，标签附着在器械旁；热键不承担默认玩法说明。此次没有重新定义字体或字号系统，也未逐项重测字体规范的对比度目标。

## Layout

Godot 4.7.1 `CanvasItem`／`Control` 使用同一 960×540 逻辑画布，桌面与横屏模拟触屏等比适配；844×390 样本的侧余区属于等比拟合。主要视野留给实物，唯一普通 `Button` 是“离开操作台”。记录与分层线索由玩家打开、翻页并移动笔记本；失败提示短暂出现。触屏输入报告还覆盖场景内模拟摇杆幅度、移动、释放与触点归属。

楼层底图、房间相邻关系、门、墙、电梯、楼梯、脚点和房间镜头沿用原几何；近景台面的重建不授权调整它们。HTML/CSS detector 不适用于这次原生绘制，未据此构造检测结果。

## Elevation & Depth

`bench_projection.gd` 的共同基为 `P(x,y,z) = (x, y·sin45° − z·cos45°)`，俯角 45°、偏航 0；`floor_point()` 提供对应逆映射。台面相对边平行，方形轨道格距为 `114 × 114·sin45°`，齿轮、环、箱体、松散零件与太阳能板使用同一深度／高度投影。旧台面只提供无物件的金属纹理区域。

显示器立面高度、桌面底座和正高度支杆分别投影，杆顶收进屏框，底座留在零件盘之前。面板绕真实 X 铰链改变深度与高度；30°／60° 在本相机中可共享轮廓，因此实际后支撑位置、杆长和依照模型日照角／照度的受光共同区分稳定状态。临时角度文字不是这一区分的依据。

## Shapes

车辆保留原有奶油白底盘、深蓝运货盆、轮胎及前叉身份；拉杆座、独立手柄、台灯与笔记本作为透明 cutout 组合。`assets/puzzles/oblique45_frames.json` 保存实测帧，`motion_prop_metrics.gd` 从四向帧尺寸和统一比例推导机器人可见前缘与停止余量。

[来源记录](../../../godot_native/campuses/future_learning_center/assets/puzzles/oblique45_generation.json)、[完整提示](../../../godot_native/campuses/future_learning_center/assets/puzzles/oblique45_prompts.json) 与同目录 `sources/` 保存生成来源、透明原稿及 SHA-256。本次核对两个 PNG 的运行／原稿散列，IHDR 与解压后的 IDAT 图像数据均相同；运行文件仅多文本来源元数据。提示中的 45° 是相机要求，不能证明生成栅格的每个像素都精确符合该角度。

## Components

| 同一物件 | 目前的变化与权限边界 |
| --- | --- |
| 太阳能板、车辆、台灯 | 拖动铰链先预览，合法释放才配置；装入后局部落稳，轮相位跟随真实行驶距离；灯具和待确认光照一起预览。试跑由模型实走 30 秒后判定 |
| 轨道、机器人、货箱 | 模块可离桌、连续转动，释放后提交四分之一转；装货、送达、卸货和空车返程跟随真实模型阶段；局部制动标记实际受阻处 |
| 齿轮、皮带、送料块 | 抓取、装轴、落稳分别可见；齿面厚度、传动相位、皮带接缝与送料位移来自模型，松带增加局部摆动；装配修改保留原判题／回卷规则 |
| 插头、线缆、接收屏 | 同一根线随持有端点弯曲，移动接收屏时插座和线端跟随身份；信号包仅在模型实际传输区间前进，接收扫描回应真实显示变化；通过仍要求两次不同改稿 |

共同表现预算为最多 12 个短接触／制动事件（0.28／0.4 秒）、一次 0.14 秒拉杆落位，以及取消后回盘的 0.22 秒表现。零件按当前渲染位置重新抓取，命中区与物件同源；表现时钟、接触弧和 Tween 均不提交试验结果。运行时修改由实际交互和模型边界控制，装配变更使旧运行证明失效。

浏览器读取系统减少动效偏好，原生支持 `FLC_REDUCED_MOTION=1` 与 `set_reduced_motion()`：去掉附加抬升、回盘飞行、拉杆 Tween 和接收扫描移动，保留即时状态、稳定支撑与必要反馈。失焦清除手势归属和待完成表现；太阳能、机械、信号试验中断，机器人暂停。关闭清理表现并隐藏，隐藏时不推进这些视图。

## Do's and Don'ts

- 保留实际物件操作、同源命中区、预览／合法释放的边界，以及可取消、可回卷、可退出的普通指针／触屏路径。
- 扩展时沿用同一投影、材质身份和模型权限；必要导航以外的动作继续在器械上发生，线索继续由玩家主动请求。
- 这里的证据只支持四个独立原型和所列路径。生产存档接入、完整 25 房间实现、完整测试套件、物理手机、Argon、合并及发布均未因此获得验收。
