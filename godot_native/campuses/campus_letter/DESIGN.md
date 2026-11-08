---
name: "7:55 校园来信三维样段"
description: "第一人称物件操作与可切换的三维场景总览"
colors:
  navigation-ink: "#24464c"
  navigation-paper: "#e7e8dd"
  navigation-selected: "#cbded6"
  navigation-hover: "#ffffff"
  navigation-pressed: "#c1d3cc"
  navigation-focus: "#d1dfd9"
  focus-ring: "#26636a"
  disabled-ink: "#596b69"
  enamel: "#283b3f"
  woven-sage: "#56655c"
  brushed-steel: "#bec5c9"
  bronze: "#af8956"
  stone-tint: "#dddcd7"
  plaster: "#dfdcd4"
  joystick-well: "#22474a55"
  joystick-rim: "#eff3e7aa"
  joystick-knob: "#e5e8dcdd"
  joystick-center: "#446664"
typography:
  navigation:
    fontFamily: "Selected UI Coverage"
    fontSize: "18px"
    fontWeight: 400
  navigation-compact:
    fontFamily: "Selected UI Coverage"
    fontSize: "25px"
    fontWeight: 400
rounded:
  control: "5px"
spacing:
  control-block: "8px"
  control-inline: "12px"
  navigation-gap: "16px"
  screen-inline: "20px"
  screen-top: "16px"
  joystick-edge: "22px"
components:
  navigation-button:
    backgroundColor: "{colors.navigation-paper}"
    textColor: "{colors.navigation-ink}"
    typography: "{typography.navigation}"
    rounded: "{rounded.control}"
    padding: "8px 12px"
    height: "40px"
    width: "100px"
  navigation-button-selected:
    backgroundColor: "{colors.navigation-selected}"
    textColor: "{colors.navigation-ink}"
    typography: "{typography.navigation}"
    rounded: "{rounded.control}"
    padding: "8px 12px"
  navigation-button-hover:
    backgroundColor: "{colors.navigation-hover}"
    textColor: "{colors.navigation-ink}"
  navigation-button-pressed:
    backgroundColor: "{colors.navigation-pressed}"
    textColor: "{colors.navigation-ink}"
  navigation-button-focus:
    backgroundColor: "{colors.navigation-focus}"
    textColor: "{colors.navigation-ink}"
  navigation-button-compact:
    typography: "{typography.navigation-compact}"
    height: "62px"
    width: "144px"
  view-toggle:
    backgroundColor: "{colors.navigation-paper}"
    textColor: "{colors.navigation-ink}"
    typography: "{typography.navigation}"
    rounded: "{rounded.control}"
    padding: "8px 12px"
    width: "100px"
    height: "40px"
  restart-button:
    backgroundColor: "{colors.navigation-paper}"
    textColor: "{colors.navigation-ink}"
    typography: "{typography.navigation}"
    rounded: "{rounded.control}"
    padding: "8px 12px"
    width: "60px"
    height: "40px"
  walk-joystick:
    backgroundColor: "{colors.joystick-well}"
    size: "132px"
---

# Design System: 7:55 校园来信三维样段

## Overview

**Creative North Star: "亲手走入的校园"**

这个局部系统只约束 `campuses/campus_letter/` 的三维样段。画面以大学公共空间和可辨认的实物为主体：木桌、椅垫、手轮、砝码、纸张与灯具保留各自的几何、材质和操作范围。第一人称以人的眼高观察物件，第三人称提供可返回的空间总览。当前四个样段不加载被用户否决的校园人物模型及其坐姿、总览复用，移动体保留但不绘制人偶。既有正式主线的像素美术不由本文件改写。

界面保持克制。右上方只保留场景切换、总览与重来，左下方是移动摇杆。用户本轮要求默认不显示玩法说明，因此没有物体表面文字、悬浮标签、底部解说或常驻操作提示。浅色导航与深色文字保持可读，场景体积由真实几何、材质反光和光照产生。

**Key Characteristics:**

- 第一人称操作与第三人称总览分开。
- 独立物件、细化曲面和真实材料参考；当前样段不渲染被否决的校园人物模型。
- 必要导航之外，默认画面不放说明文字。
- 同一横屏逻辑画面等比适配桌面与触摸设备。

记录依据：`scripts/samples.gd`、`scripts/objects_3d.gd`、`scripts/world_3d.gd`、`scripts/navigation_pad.gd`，以及本轮桌面与 Chrome 触摸模拟的实际运行截图。上面的 tokens 使用 Godot 逻辑画面像素；它们不是 CSS 设备像素。

## Colors

导航以深青文字配浅灰纸色，场景以深木色、灰绿织物、冷灰石材和分开的金属本色组成。前置 tokens 是数值来源，以下说明颜色用途。侧车中的渐变色阶仅供设计面板预览，不扩大运行时调色板。

### Primary

- **深青导航文字**（`navigation-ink`）：所有正常、悬停、按下、按下悬停与焦点状态都保持同一深色文字。
- **浅灰绿选中面**（`navigation-selected`）：表示当前场景，选中仅改变导航表面。
- **深青焦点边**（`focus-ring`）：为焦点状态提供细边，配合焦点底色使用。

### Secondary

- **石墨青金属漆**（`enamel`）：家具支架、灯具筒身和装置结构。
- **灰绿织物**（`woven-sage`）：椅垫和布面书封，细节来自织物法线与粗糙度。
- **黄铜配件**（`bronze`）：旋钮、圈环及制造连接件，保持材料用途。

### Neutral

- **导航纸色、白色悬停面、按下面与焦点面**：只为必要导航的操作状态服务；不额外覆盖整条白色页眉。
- **禁用文字**（`disabled-ink`）：共享按钮的禁用状态值，当前场景导航没有新增禁用流程。
- **钢色、石材着色与墙面灰白**：配合材质通道形成实际表面，不作为无纹理替代色。
- **半透明摇杆色**：井、外圈、旋钮和中心点分别使用对应 token，保留底下场景的可见度。

**The Physical Material Rule.** 木材、石材、织物和金属通过各自的共享 PBR 材质区分；不把导航底色当成场景物体的统一涂色。

当前共享材料从 `objects_3d.gd:pbr()` 读取。下表是已有运行配置，不是所有后续物件必须复刻的外观目标；近景检查仍决定调整。

| 材料族 | 贴图与色彩来源 | 粗糙度系数 | 法线幅度 | 三向投影尺度 |
| --- | --- | --- | --- | --- |
| 木材 | Wood051 颜色、法线、粗糙度 | 0.82 | 0.20 | 1.15 |
| 石材 | Concrete034 颜色、法线、粗糙度，加石材着色 | 0.85 | 0.45 | 0.85 |
| 墙面 | 墙面灰白与 Concrete034 法线、粗糙度 | 0.90 | 0.18 | 1.40 |
| 织物 | 灰绿本色与 Fabric041 法线、粗糙度 | 0.95 | 0.28 | 2.00 |
| 钢 / 黄铜 / 金属漆 | 各自本色与 Metal032 法线、粗糙度 | 0.32 / 0.42 / 0.65 | 0.08 | 4.00 |

钢和黄铜的金属度为 0.90，金属漆为 0.30；共用三向投影与带各向异性的线性 mipmap 过滤。木色来自实际图像，不另造一个纯色 token 代替。

## Typography

**Navigation Font:** `Selected UI Coverage` Regular，来自 `ui_assets/fonts/SelectedCoverage-Regular.otf`；名称已按字体内部 name 表核对。Godot 直接加载这份字库，没有声明另一个中文回退字体。

### Hierarchy

- **Navigation**：常规导航字号（18 个逻辑像素），Regular，用于场景、总览与重来。
- **Navigation Compact**：实际窗口宽度小于 1000 像素时使用较大的导航字号（25 个逻辑像素），避免横屏缩放后过小。

默认画面没有展示字号、正文或说明字号层级。隐藏的品牌标题、提示、帮助和反馈字号不进入前置 tokens。HTML 竖屏旋转提示使用浏览器 `system-ui`，是独立的设备方向兜底，不是原生游戏的展示字体。

**The Navigation Text Rule.** 文字用于必要导航，不写在物体上，也不作为悬浮标签覆盖物件。当前隐藏的说明字号不属于可复用排版层级。

## Layout

独立预览按 1280×720 逻辑画面排版并保持 16:9，非同等比例窗口留出等比显示所需的边缘。手机竖屏先显示转横屏提示；不得将横屏游戏拉伸填满竖屏。

必要导航靠右放在透明容器中。容器与左右边缘相距 20 个逻辑像素，顶部为 16；按钮间距为 16。常规场景按钮最小宽度为 100、最小高度为 40；紧凑分支增加到 144×62，总览按钮最小宽度增加到 190。返回第一人称的较长文字允许原生容器按实际文本展开。前置组件尺寸表示这些最小尺寸，不是裁切文字的固定盒子。

摇杆的交互区域为 132×132，距左边和底边各 22 个逻辑像素。图形在区域内留白，外圈半径为 54，旋钮半径为 21，可偏移半径为 38；界面位置与实际触摸区一致。

第一人称相机的站立眼高为 1.65 个世界单位，坐下为 1.12，视场角为 66°。总览视场角为 43°，各场景保留自己的总览位置。总览隐藏室内顶面、东侧与南侧房屋壳体以呈现内部；返回后恢复第一人称空间。场景物件不随导航布局缩放而改变世界坐标。

## Elevation & Depth

场景深度来自真实模型、受光表面与投影；按钮和导航容器不使用投影装饰。天空供反射，方向光和局部灯具共同塑造材质。各场景照明参数只描述当前光源，不规定所有场景必须同样亮或同样暗。模型是否可读，必须在实际第一人称距离检查。

**The Geometric Depth Rule.** 轮廓、倒角、接缝和光影来自三维对象与光源；屏幕导航保持平面，不复制场景阴影作为按钮装饰。

材质与灯光不会改变物件的操作范围、投射目标或完成判定。纸桥形变、灯座移动和物件拾取应给出对应的空间变化；总览是观察视角，不代替物件操作。

## Shapes

屏幕控件使用轻微圆角，圆角值来自 `rounded.control`。摇杆以圆形井与可移动旋钮表达方向，不用字符图标模拟操纵杆。

三维物件保留连续曲面、细化倒角、连接件与接缝：弯曲座板、灯具关节与灯罩、砝码车削轮廓、支点调节轮、独立书页及长椅构件。实际模型和手轮对象单独导出、实例化，碰撞与拾取采用独立简化体。新增细分应落在近景可见的轮廓和弯曲表面，不把整个场景的平面无差别加密。

## Components

### Navigation Buttons

紧凑、浅色、只承担必要导航。共享按钮使用前置 token 的圆角、左右及上下内边距。悬停改变底色，按下使用灰绿按下面，焦点叠加细边。所有活动状态文字保持深青；禁用状态使用禁用文字 token。状态切换是即时反馈，没有额外缩放或弹跳动画。

### Scene Navigation

四个场景按钮在同一横向容器中，当前场景以选中面表示。导航切换不把桌面文字或说明贴到三维对象上，也不显示一套独立的任务卡片。

### View Toggle

`场景总览` 与 `返回第一人称` 使用同一按钮。总览中隐藏移动摇杆并停止第一人称行走；返回保留玩家位置。室内壳体的剖开效果随总览状态切换，实际操作视角仍为完整室内。

### Restart

`重来` 沿用导航按钮风格，仅使用较窄的最小宽度；它重置当前样段，不使用额外结果卡抢占画面。

### Physical Letterbox

投递对象是独立信箱模型，使用与装置一致的金属外壳、投信口和可转动盖板。来信可以拿起，再交给可见投信口；成功后信件位置落在信箱中。盖板依现有规则呈现开闭，距离和完成条件仍归样段控制器。当前实现没有透明人物代替投递目标，也不借总览显示已移除的人物。

### Walk Joystick

半透明圆形井、浅色旋钮与深色中心点组成固定左下角控制。拖动方向跟随实际指针；松开、取消、失焦或离开样段回到中心。一个指针拥有一次操纵，另一根手指不会抢走该次输入。场景中的手轮和灯座继续由其可见物件本身操作。

当前默认隐藏的品牌、玩法提示、底部反馈、悬停说明与帮助入口不作为本系统的展示组件。HTML/CSS 侧车样例仅是设计面板的原生外观示意，不是另一套游戏界面或输入实现。

## Do's and Don'ts

### Do:

- **Do** 以第一人称距离检查模型轮廓、木纹尺度、织物法线和金属反光。
- **Do** 复用共享材质，保留独立物件节点、操作轴与简化拾取体之间的一致性。
- **Do** 将第三人称用于场景总览，并在返回时恢复玩家的第一人称位置。
- **Do** 在桌面与横屏触摸尺寸检查普通操作、拖拽取消、焦点丢失和总览返回。
- **Do** 使用有来源记录的实物参考与素材，材质许可及原始文件记录保存在 REFERENCES.md 和 assets3d/pbr/sources.json。

### Don't:

- **Don't** 在物品表面或上方叠加说明文字。
- **Don't** 把当前隐藏的标题、底部解说、帮助面板和悬停说明重新当成默认画面组件。
- **Don't** 用像素背景、远距离模型台镜头或一排屏幕操作按钮替代这组样段的第一人称物件操作。
- **Don't** 以增加面数本身代替近景轮廓与材质质量，也不把某张截图的偏暗区域固化成品牌要求。
- **Don't** 把已移除的校园人物换到坐姿、其他样段或总览里继续渲染，也不留下隐形人物交互。
- **Don't** 让材质、相机或演出写入第二套进度，也不把这套局部视觉约束推广到未改动的正式主线。
