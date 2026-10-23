# 剧场原箱子：正上方俯视重建

本文件保留首版实现与验证记录。用户随后要求补足盒体深度、进一步纠正俯视表现；当前素材与对象修正见 `THEATER_CHEST_BODY_20261023.md`。

2026-10-23。用户最终要求为保留剧场已有箱子的身份与原流程，抠出并重建可打开对象；特写镜头从正上方垂直向下，完整看见箱底。此前的 45° 示意及新增转盘、夹层流程已撤回。Godot 运行基线为 4.7.1。

## 对象与视角

- 原场景对象为 `stage_prop_chest`，布局 `data/native/theater-object-layout.json` 中源矩形为 `[255,145,84,74]`，当前透明箱子素材为 `assets/native/theater_rebuild_20261020/prop_chest.png`。该场景坐标、碰撞与扫码器距离保持原值。
- 俯视素材沿用原深色木板、黄铜包角、中央锁扣，向远侧展开箱盖。箱体、内壁、箱底与箱盖作为独立源图图层构建，整件对象等比适配；箱盖投影围绕远端铰链变化，箱体固定。
- 初次展示包含整件开箱对象。点箱底可继续推近，再点恢复；点返回或 Escape 回到剧场，恢复原镜头、平移与缩放。手机热区和渲染使用同一投影。
- 这是箱内检查时的镜头例外，普通剧场地图仍保留原场景投影。

## 原有流程

原世界扫码器仍验证浅色模式、临时票、阶段与原始距离。成功即原子消费 `temporaryTheaterTicket`、授予 `fluorescentBrush`、记录 `propBoxOpened=true`，然后展示开盖动画。近看界面不提交新剧情动作、不新增解谜、不追加领取步骤。

已开箱存档直接呈现打开的箱子；已经领取的荧光刷不再画成可领取物，空箱也不会补奖。返回、中断或关闭动画均不能撤销或重复原交易。减少动态效果立即呈现最终状态。失焦暂停动画，返回窗口后继续。世界隐藏、布局切换或状态上下文更换会释放临时镜头。

## 素材来源

内置 `image_gen` 图像编辑工具，以现有箱子透明素材为身份参考；先前生成的斜俯视开箱图仅作为本次视角修正输入，未用作交付素材。没有调用付费三维生成服务。

交付：`assets/native/theater_chest_20261023/prop_chest_overhead_open.png`，1336×1177，RGBA。

SHA-256：`4b18a7e4d8746cd0a203562c7acc8f36ed34ccdb3d1e31e750ba373e764960b4`。

原箱子 SHA-256：`a7d865b643664b6ff0d99c67da346e2ddd4c751175ad1d5d6036ac5a3f65aad9`。

最终生成提示词：

> Use case: precise-object-edit. Asset: transparent fine-pixel-art game prop for an existing Godot theater. Image 1 is the open chest edit target; image 2 is its original small scene sprite, identity reference. CORRECT ONLY THE CAMERA PROJECTION AND LID ANGLE: make a TRUE DIRECTLY OVERHEAD 90-degree orthographic top view, the camera points STRAIGHT DOWN vertically. NOT 45-degree, NOT isometric, NOT an oblique front view. Keep the same dark reddish wooden planks, aged brass corner fittings, hinges and centered latch, the exact existing chest identity. Chest edges are axis-aligned parallel rectangular edges with no vanishing point. The near vertical outer front face must NOT be visible except its thin upper rim and the little latch edge. The interior floor is a broad full rectangular area, clearly visible in its entirety, about 80% of the box opening; only thin inner walls surround it. The lid opens all the way away from the viewer toward the TOP of the canvas and lies nearly flat beyond the far hinge, so it never overlaps or covers the cavity. In this true top view the lid is a separate upper rectangular wooden panel and the open box is the lower rectangular wooden frame enclosing a large empty plank floor. The lid and cavity should be comparable widths. Show entire chest with safe transparent margins. No objects in the cavity, no puzzles or symbols, no background, no text, no UI, no new decorative flourishes. Use crisp small fine-pixel detail matching the references, consistent top-left warm lighting, no blurry airbrush. Physically convincing thickness at the rims, darker shallow inner wall strips and a distinct large bottom surface. The main visible surface in the lower half must be the FLOOR, never a tall front facade.

## 验证入口

`tests/test_theater_chest_focus.gd` 使用隔离存档、真实 Main、原控制器、鼠标和 ScreenTouch，检查原扫码事务、近看不产生剧情动作、镜头还原、移动阻断、旧存档、减少动态效果、隐藏与布局切换。`--manual` 通过原世界扫码打开预览；`--closed` 先看锁闭状态；`--portrait` 为 390×844；F6 重置锁闭箱，F7 走原扫码交互，F11 截图。

桌面与模拟触控属于原生窗口验收；不能替代 Godot Web 导出、浏览器或实体手机验收。未发布新版本。

最终原生验证：基于 `03790d8c951f5ec3b3aaa9727dafdbf40c001f70` 的当前未提交工作区；文件哈希见 `THEATER_CHEST_ACCEPTANCE_20261023.json`。4.7.1 的第三章 72 项、箱子视图 136 项、剧场对象 1935 项均零失败；实际 OpenGL 窗口在 1440×900 与 390×844 执行鼠标/触控路径，共 144 项零失败，无引擎报错，保存八张截图。另在可见的 1280×820 原生预览中直接点击箱底，确认推近与恢复整箱取景。
