# 剧场箱内机关与立体堆放

2026-10-23，接续原箱体正上方近看对象。用户选择新增“符号片、转盘零件、夹层线索”，随后要求错落堆放、实际体积、遮挡与高低差，并要求使用 Computer Use 精细检查。

## 交互

原世界扫码器仍立即完成临时剧场票 → 荧光粉刷的原交易。近看中的折扇、蝴蝶、灯光三枚铜片可以选取、装槽和换位；装回转柄后点击中轴顺时针转动。纸条给出从上方开始顺时针的符号顺序；正确排列后拉开右下夹层，看到后台通风口示意。这个机关没有成为原通风口/荧光粉刷主线的新门槛，也不发放新的存档物品。

机关归 Chapter3 临时会话管理。原扫码器和箱子的原始合法交互距离都可启动同一个近看，保持各自源坐标。离开、切换上下文或关闭会取消会话；重新打开会复位。本轮没有扩展保存格式或跨关闭保存机关进度。

## 物件与投影

- 箱体沿用 `prop_chest_overhead_body_v2.png` 的独立底面、内壁、箱身、铰链与盖子分区。
- 铜片、转盘、转柄、纸片衬底、垫圈和夹层构件使用 Godot `Node3D` / `MeshInstance3D`。铜片有倒角和厚度，松散铜片倾斜叠放，选中后实际抬起。
- 内部 `SubViewport` 为 1448×1086，正交镜头垂直看向箱底。X/Z 对应既有素材的 X/Y，整体等比显示。顶视相机保持 90°，倾斜只发生在散落物件自身。
- 纹理取自同一箱子及同一铜制机关素材集。灯光生成实际阴影；放置同时插值位置和姿态，轮盘的最终姿态接续旋转动画。
- 输入先命中可见物件轮廓，再分配扩展触控区域；叠放时避免下层或中轴的扩大热区抢走实际可见的目标。
- 纸条和夹层可以近看。输入在动画中暂时锁住，退出始终可用；减少动态效果立即落到同一正确姿态。

## 文件

- `scripts/objects/theater_chest_object.gd`：原箱体分区与开盖。
- `scripts/objects/theater_chest_contents.gd`：源坐标桥接、纸条/线索绘制、3D 纹理合成。
- `scripts/objects/theater_chest_contents_3d.gd`：真实网格、正交相机、堆叠与装配变换。
- `scripts/ui/theater_chest_closeup.gd`：点选、镜头与显示状态。
- `scripts/games/theater_chest_mechanism.gd`：运行时会话及机关规则。
- `tests/test_theater_chest_focus.gd`：真实 Main、原扫码流程、鼠标/模拟触控、相机和退出。
- `tests/test_theater_chest_mechanism.gd`：会话/状态边界、主线独立性及原扫描器站位。

## 素材生成记录

内置 `image_gen`，`transparent_background=true`。最终素材 `assets/native/theater_chest_20261023/puzzle_kit.png`，1536×1024 RGBA。逐个测量素材轮廓再在运行时使用 atlas 区域；未把预览图中忽略 alpha 显示的棕色背景当作有效背景。原始生成文件保留在本会话 generated_images 中。

初始生成提示词：

> Create ONE game-prop sprite atlas, a coherent six-part clockwork puzzle kit for a dark reddish wooden theater chest with aged brass fittings. Fine detailed hard-edged pixel art, top-left warm light, directly overhead orthographic 90-degree camera. Transparent background. Atlas layout exactly a 3-column by 2-row grid, six equal square cells, each object entirely isolated within its cell with generous clear transparent margin. No cell frames, no text or numbers. Top left cell: one small square aged-brass token engraved with a clear folding FAN silhouette. Top middle cell: one square aged-brass token engraved with a BUTTERFLY silhouette. Top right cell: one square aged-brass token engraved with a THEATER SPOTLIGHT silhouette. All three tiles have identical rounded square shape and size, readable dark engraved silhouettes. Bottom left cell: an aged brass circular ROTOR PLATE viewed perfectly from above, with three EMPTY square recessed tile sockets arranged as a triangle around a missing central spindle, one socket at 12 o'clock and two below left/right. No tiles in this rotor. Bottom middle cell: a detached short brass crank handle with one round spindle end and a dark wooden grip, lying flat, clear silhouette, fits the rotor. Bottom right cell: a small folded worn cream paper clue note, dog-eared, no visible writing or symbols; its face is blank so the game can overlay its own clue. These six pieces form one consistent inventory kit. Match antique theater equipment, restrained gold/bronze metal, warm dark wood accents. Crisp fine pixel texture, no heavy outlines, no glossy 3D plastic, no floor or shadow outside each small prop, no chest itself, no background checkerboard baked into alpha. All six objects must be separate, centered in their own atlas cells with at least 15% empty margin, with no overlap across cells.

透明边缘编辑提示词：

> Remove the entire brown gradient/background and all outside glow or diffuse shadows from this sprite atlas. Keep exactly these six separate antique brass and paper objects at the exact same positions, sizes and appearance. Do not redraw or add objects. True transparent alpha background; alpha=0 everywhere outside the precise silhouettes. The holes between the crank arms and around the rotor must be transparent. Keep the three empty rotor sockets dark because those are recessed inside the rotor, but the center shaft hole may be dark. Preserve the original 3-column/2-row layout and existing six objects, each cleanly isolated. No replacement backdrop, no checkerboard painted into the image. Crisp pixel cutout edges, no blurry brown halo.

本轮使用安装的 Godot 3D、动画和资源制作技能，参考项目指定技能路由。模型为原生网格；本轮没有生成新的 Blender 文件。

## 验证边界

Godot 4.7.1 隔离存档。Computer Use 操作实际原生窗口，不以单张效果图代替交互。最新测试、截图及文件哈希见同名验收 JSON。原生与模拟触控结果不代表 Godot Web 导出或实体手机验收；本轮没有发布浏览器构建。
