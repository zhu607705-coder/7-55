# 《梁祝》角色骨骼规范

2026-10-21。本批使用 **完整 cel 姿势图 + 实际骨骼挂点**：`Skeleton2D` 下15个 `Bone2D` 驱动腕部和道具挂点；角色轮廓仍来自完整姿势格。没有 `Polygon2D` 权重、网格蒙皮或整图弹性变形，不把本批描述为完整骨骼蒙皮动画。

## 坐标和层级

- 唯一姿势图 `assets/native/liangzhu_performance_20261021/actors.png`，480×320，4列×2行，每格120×160；SHA256 `41b42f9486ecbec2745239daa3a75937055105ff73a2da6eb22cc07db7a0ff32`。
- 每格固定脚点 `(60,150)`；舞台逻辑单位换算 `(sourcePoint − footPoint) / 5`，对应完整24×32逻辑格内的 `(12,30)`。rig 原点就是舞台脚点。图格保持比例和完整袖缘；不按姿势独立缩放。
- 主链 `Hip → Torso → Head`；两臂 `Torso → Left/RightShoulder → Left/RightElbow → Left/RightWrist`；两腿 `Hip → Left/RightKnee → Left/RightFoot`。右腕下 `FanSocket`，左腕下 `LeftFanSocket`，根下 `FootAnchor`。衣袖辅助骨在各侧 Elbow 下，独立于 Wrist。
- `POSES` 是逐行逐姿势的原图坐标表。头、肩与藏在衣内的支撑关节为美术绑定点，并非照片解剖测量。膝脚被长袍遮住，明确为推定支撑点；无碰撞或剧情含义。
- 两行均默认右手持扇。抬袖姿势 row0/frame2 右腕 `(109,90)`；row1/frame2 右腕 `(109,80)`，后者以原图像素复核，`(109,82)` 已在透明边外。其他持扇腕点亦需落在不透明角色像素上。
- 54秒终场新增双手持扇，row1/frame2 左掌经原图皮肤像素复核为 `(33,67)`；初估 `(25,84)` 在白长袖中，已校正，不让放蝶扇子从袖中漂出。
- 水平翻转围绕脚点，以根矩阵的 X 轴反射完成；反射绝对倍率为1，不允许压扁/拉长。舞台父级5倍栅格变换只应用一次。

## 接口与真实消费者

脚本 `scripts/presentation/liangzhu_actor_rig.gd`；每位演员保留一个实例，不在 `_draw` 创建节点。

`configure_pose(frame, row, foot, flip, time_ms=0, reduced=false) -> bool` 按姿势表更新真实骨链；非法帧、行、非有限位置/时间不改变上一个合法姿态。

`attachment_global_transform("FanSocket")` 直接读取实际 `Marker2D.global_transform`；`attachment_local("FanSocket")` 返回该挂点在 rig 父节点（舞台）坐标下的 `Transform2D`。持扇绘制读取该变换，不能用第二套硬编码手点。`sample_socket(...)` 只为历史放飞帧按同一关节表累乘 FK；当前持物始终读活节点。

衣袖附属角默认±3°，硬上限±6°，减少动态效果时为0；仅 `LeftSleeveTip`/`RightSleeveTip` 端点，不改变整幅 cel 或将手腕拉离原图。rig 不自动绘制：可见衣袖效果若接入，应由舞台在 cel 之后、道具及前幕之前显式绘制；未接入时不宣称衣袖像素已变形。未来真正分层蒙皮需要另做部件、权重及遮挡验收。

## 开源依据与边界

已只读核查官方 [Skeleton2D Demo README](https://github.com/godotengine/godot-demo-projects/blob/34fc99545fc41520a958248f607101e7d0b95b05/2d/skeleton/README.md) 与 [GBot 骨架场景](https://github.com/godotengine/godot-demo-projects/blob/34fc99545fc41520a958248f607101e7d0b95b05/2d/skeleton/player/player.tscn)，固定提交 `34fc99545fc41520a958248f607101e7d0b95b05`。该场景实际用 Hip/Chest/Head 与双臂、双腿骨链并有7个 Polygon2D；其完整蒙皮范围比本批更广。原场景81337字节，SHA256 `efb5f6d1d532249396d98ce5c741aabb3a1f3830555954de719d5e57f999e388`。

该仓库 [MIT 许可](https://github.com/godotengine/godot-demo-projects/blob/34fc99545fc41520a958248f607101e7d0b95b05/LICENSE.md) 与 README 分别注明项目、GBot 美术及初始绑定的版权。本实现借鉴父子骨链组织，全部项目代码自行编写，未复制 GBot 图像、场景、代码、动画轨或音频。

官方 [cutout 动画教程](https://docs.godotengine.org/en/stable/tutorials/animation/cutout_animation.html) 支持 cel 与分件骨骼混用，强调正确枢轴和相对父节点变换；该页提示尚未更新到4.7，因此不以其旧 IK 段落作为运行时 API 依据。实际节点/rest API 另核对 [Bone2D 文档](https://docs.godotengine.org/en/stable/classes/class_bone2d.html)；rest 是非奇异的父级相对矩阵，`bone_angle` 仅为骨骼示意角，不拿它代替节点旋转。

## 验证边界

`tests/test_liangzhu_actor_rig.gd` 检查真实骨链注册、8姿势/两种翻转、原图腕点、父级缩放/旋转、实际祖先旋转对挂点的影响、真实子道具跟随、固定脚点、角限制及无效输入原子拒绝。舞台消费者、演出往返与浏览器存档不变另由演出集成和实际 Web 验收验证；单测不等于那些整链通过。
