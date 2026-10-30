disposition: fix

输入边界：没有 PRODUCT.md、DESIGN.md、独立 QUALITY BAR 图卡或获批 comp；本轮是有明确既有美术权威的限定修订，按 context 的 SCOPED_EXISTING_ALLOWED 路径审阅。未重新访谈用户，采用调用方传入的用户原话、物件优先约束和本轮 brief。待完成的 PROJECTION_MOTION_VERIFICATION_20261030.json 不作为已交付凭据；未独立播放完整 mp4 或重跑引擎、浏览器、完整测试。这里的动画判断来自逐张重开的原生静帧、源码和所附测试报告。

## persistence

pass（限定修订范围）。`.impeccable/flc-projection-motion-brief.md` 与 `godot_native/campuses/future_learning_center/review/PROJECTION_MOTION_20261030.md` 保存投影、动作、模型权限和验收范围。美术权威为 `godot_native/docs/art/ART_BIBLE.md`、`art_direction_v1.json` 和实际既有物件；无新视觉世界、comp 或 concept-seed 的义务。Godot CanvasItem/Control 不适用 HTML/CSS detector，本轮没有运行第二次 detector。

全部 14 张指定截图已分别重开：桌面四张均 1280×720，移动四张均 844×390，动作六张均 960×540；内容、状态和名称一致，没有错误加载或空白捕获。移动图的侧边余区来自 16:9 等比拟合。另重开旧版 `solar_initial`、`signal_complete`、`mechanical_complete` 三张反例及本轮 `motion/solar_hinge_after.png`、`motion/solar_reduced.png`。旧版判定没有被用作本轮通过依据。

`desktop/object_input.json` 为 47/0、`mobile/object_input.json` 为 53/0，均记录正常实时输入、零键盘事件；`motion/presentation.json` 为 25/0，明确 `movieFixedStep: true`。这些报告支持所列路径，不代表生产存档、25 房间、完整套件、浏览器兼容矩阵、实机手机或发布验收。未把调用方传入的 5 项局部预检、536 项未跑内容扩写成完整通过。

此次源码快照：`signal_sync_view.gd` SHA-256 `7b108bebfc51864a012c798b68258b61fcbf7e8ba7f61f309feebbe597a4cf39`；`motion_lab_view.gd` `ef318014d61639da86fe4d38e991537b9063f4e2c6b426247d771e9fe1f08fb7`；`bench_projection.gd` `9a635d4b23958b4506b437fd8911034c8e01074e793acbfb22d8b1b8cab9aa6a`。修正后的判定须基于更新截图。

## fidelity

| 元素／承诺 | 判定 | 可验证依据与影响 |
| --- | --- | --- |
| TYPE | match | 保留 native_typography 的晨札像素字形、浅纸色与深蓝灰铭牌；指定尺寸中可辨识主要物件、运行状态和退出。没有把热键说明恢复为默认玩法。 |
| MATERIAL | adaptation | 车辆、台灯、拉杆和笔记本保留细像素金属、橡胶、纸张材质；台面采用旧素材的空白金属纹理，几何齿轮、轨道和面板采用明确色簇。台面和显示器重建的依据是 brief 的共同投影要求；不把生成提示视为每个贴图像素的几何证明。 |
| GROUND | match | 实际画面保持安静的蓝灰金属工作面，物件轮廓先于纹理，符合现有色板与收敛孤立点状噪点的规范。无 comp 可做逐像素温度比较。 |
| 共同台面、模块、齿轮和环形物的 45° 基础 | match | 台面相对边平行，轨道模块在桌面上以一致深度压缩；`bench_projection.gd` 明确 X 水平、Y×sin45、Z×−cos45。转动中间帧保留该平面，不靠换镜头或拉伸场景完成。 |
| 显示器立面、支杆和底座连接 | contradicted | `desktop/signal_complete.png`、`mobile/signal_receiver_drag.png` 和 `motion/signal_packet_inflight.png` 均显示屏幕与 T 形底座断开。`signal_sync_view.gd:114` 使用 `base-Plane45.offset(0,0,60)`，将向上的高度投影反向送到桌面下方；屏底约在 at.y+78.54，杆却从 at.y+117 开始向下延伸。修正 45° 视图的核心承诺尚未成立。 |
| 太阳能板三个角度的物件状态可读性 | contradicted | 0°→30° 的边缘确实移动；30° 稳定帧 `motion/solar_hinge_after.png` 与已提交 60° 的 `motion/solar_reduced.png` 中面板自身相同。`bench_projection.gd:47-52` 的投影深度为 26×sin45×(cosθ+sinθ)，30° 与 60° 均为 25.114；`motion_lab_view.gd:245-249` 的近端支撑、网格和颜色也没有角度区别。松手后临时角度字样消失，玩家无法从同一物件分辨两个影响试验结果的角度。这延续了用户所说的“物件变化过少”。 |
| 操纵、装配与动作反馈 | match | `robot_rotation_mid` 可见连续旋转与离桌高度；`gear_held`、`gear_seating` 可见抓取、接触和落轴差别；真实行进驱动轮相位、齿轮、皮带接缝与送料块。没有用屏幕按钮行替代这些动作。 |
| 线缆、接收反馈与模型权限 | match | `signal_packet_inflight` 的包处于真实连线中途，接收显示仍保留各自稿件；源码按 model.running/elapsed 绘制包，扫描反馈不提交判题。报告保留两次不同修改、预览与提交的边界。支杆断开另列为视觉附着缺陷，不能由接线测试通过抵消。 |
| 触点、返回过程和中断 | match（所附路径范围） | 源码按当前 part_at、receiver_at、_port_position 判定重新抓取和端点位置，输入报告覆盖取消、第二触点、移屏后拔线、退出；presentation 报告覆盖失焦、关闭与减少动效。未独立重复操作，未推定物理手机触感或实时帧率。 |
| 首屏与移动适配 | adaptation | 工作台与实际物件占据主要视野，笔记本由玩家主动展开且可移动，原生横屏画布统一拟合移动尺寸；依据 brief 的 Experience 模式与既有 960×540 合同。主要状态保留场景内表现，退出是唯一普通 Button。 |

## ceiling

尚未用足的原生手段是由同一世界坐标推导的完整立面支撑，以及随真实倾角改变的铰链连杆、后支撑位置或受光色阶。它们能同时提高空间可信度和状态可读性；当前的拉杆落位、局部接触弧、轨道连续转动和传输包已有明确用途。两处未完成项属于现有场景内的修正，未达到需要更换整套视觉世界的 rebuild 条件。

## material_fixes

1. **F1 — 修正四台显示器的高度方向并让屏、杆、底座实际相连。** `signal_sync_view.gd:112-117` 应以同一底部世界点和正高度推导杆顶、屏底，消除当前向下支杆和约 38.5 逻辑像素的可见断口；保留接收屏身份、线缆端点、拖拽热区与模型判定。复核 `desktop/signal_complete.png`、`mobile/signal_receiver_drag.png`、`motion/signal_packet_inflight.png`，静止与拖动中都应能沿完整结构读到桌面上的落脚点。
2. **F2 — 让 30° 与 60° 的稳定面板状态通过物件本身可区分。** 保留共同正交投影和真实铰链，补画与倾角相连的后支撑／连杆、下表面或一致光源下的面板受光层次，使松手后仍有稳定差别；保持减少动效时同样可读。不要靠临时角度文字替代形态。按相同车辆、面板和光照截取 0°／30°／60° 稳定状态的桌面与移动物件区域，检查实际面板／机构像素的区别及原有预览、取消、提交边界；补上覆盖 30°↔60° 的针对性回归，现有 0°→30° 渲染变化检查不能证明该差别。

## keep

保留共同 45° 投影、既有房间和脚点、细像素材质身份、模型拥有进度、直接抓取物件与实体拉杆的完整指针／触控路径，以及可取消、可回卷、可减少动效的局部反馈。
