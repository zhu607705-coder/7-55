# 第三章食堂至剧院自行车衔接：A 方案正式设计

状态：用户已于 2026-08-23 选择 A 方案。先完成分镜、锚点、提示词和运行时交接设计；本文件不授权复用已拒绝视频，也不代表新 Hailuo 片段已经通过视觉验收。

本设计废止以下旧执行路径：

- 废止让 Hailuo 2.3 在一条视频内完成俯视地图、完整上车、后视骑行或剧院俯视交接。
- 废止把 700 米作为正式媒体交接点。700 米仅用于路线连续性调试。
- 禁止继续使用 picture_05_chase_755m_1920x1080.png 作为生成首帧。该图含横跨道路的剧院台阶。
- 已拒绝的两条衔接原片与宣传 MV 继续保持 integration_allowed=false。

## 1. 目标与边界

正式剧情链固定为：

~~~text
食堂外支付成功
→ 完整上车过场
→ 真实玩法从 0 米开放输入
→ 玩家连续完成 0–755 米
→ 755 米胜利判定
→ 完整刹车、停车、下车与移车过场
→ campus_theater_junction
→ 玩家在剧院外继续现有入口交互
~~~

运行时边界：

- TypeScript 控制器继续负责支付、一次性扣款、0 米启动、755 米判定、三次机会、存档与剧院检查点。
- Three.js 继续负责骑手、自行车、纸条、道路、剧院和 NPC 的确定性画面。
- Hailuo 2.3 只生成两个固定近景插镜：握把加脚踏，以及刹车把加前轮。
- 两个近景均不显示脸、纸条、NPC、建筑、标牌、HUD 或可读文字。
- Hailuo 媒体缺失、播放失败、超时或尚未通过用户验收时，使用同机位的原生 Three.js 近景。剧情始终可继续。

## 2. 选择 A 的具体含义

A 方案完整展示以下动作：

### 上车动作

1. 玩家站在自行车左侧。
2. 双手依次握住车把。
3. 右腿完整跨过车座。
4. 玩家坐稳，左脚仍在地面维持平衡。
5. 右脚落到右脚踏。
6. 左脚蹬地，自行车开始移动。
7. 双脚进入第一轮踩踏。
8. 镜头收束到真实玩法的 0 米首帧。

### 下车动作

1. 玩家停止踩踏。
2. 右手捏住刹车把。
3. 前轮连续减速。
4. 自行车在台阶前的平地停稳。
5. 左脚先落地。
6. 右腿完整跨回车座左侧。
7. 玩家双脚站稳并保持自行车直立。
8. 玩家把自行车推到画面右侧并停放。
9. 玩家松开自行车，朝剧院入口走两步。
10. 画面切到真实 campus_theater_junction。

这组动作不依赖生成模型完成肢体连续性。Hailuo 插镜只强化手、脚、踏板、刹车和轮速细节。

## 3. 权威状态与刷新恢复

不新增 CanteenHuntPhase，也不存储媒体播放秒数。现有事实组合形成四个互斥状态：

| 阶段 | 权威状态 | 画面 | 完成动作 |
|---|---|---|---|
| 等待支付 | phase=chase_ready 且 bikePaid=false | 校园实机 | payForBike() |
| 上车过场 | phase=chase_ready 且 bikePaid=true | Start gate | startChase() |
| 真实骑行 | phase=chasing 且 chaseCompleted=false | CanteenChaseOverlay | resolveChaseAttempt() |
| 下车过场 | phase=chasing 且 chaseCompleted=true 且 chaseBestDistance>=755 | Finish gate | completeChase() |
| 剧院外 | phase=theater_reached | campus_theater_junction | 现有入口交互 |

刷新恢复：

- 支付后刷新：重播完整上车过场，不重复扣款。
- 上车过场结束后刷新：从 0 米、3 次机会、中间车道安全重开真实骑行。
- 骑行中刷新：从 0 米安全重开。瞬时距离、车道和碰撞帧不进入正式存档。
- 755 米成功后刷新：重播完整下车过场，不重新挂载 0 米骑行。
- 下车过场结束后刷新：直接恢复 theater_reached 和 campus_theater_junction。

startChase() 与 completeChase() 都必须幂等。媒体 ended、watchdog timeout 和 React 重入同时发生时，控制器动作只能执行一次。

## 4. 24 FPS 正式分镜

### 4.1 Start gate：共 91 帧，3.792 秒

| 镜号 | 帧 | 时长 | 来源 | 画面与动作 | 接点 |
|---|---:|---:|---|---|---|
| O1 | F000–F009 | 0.417s | 真实校园运行时 | 食堂外支付完成，玩家位于自行车左侧；输入与 HUD 已锁定 | F009 记录人物与车的屏幕中心 |
| O2 | F010–F040 | 1.292s | 原生 Three.js 全身镜头 | 固定 35 度后侧机位；双手握把，右腿跨座，坐稳，左脚着地，右脚找踏板 | F040 的手、脚、车把、踏板姿态必须等于近景锚点 |
| O3 | F041–F070 | 1.250s | Hailuo 2.3 固定近景；未批准时用原生近景 | 右手收紧握把，右鞋压下脚踏，曲柄只转 35–45 度，链条开始移动 | 首尾与原生相机位置差不超过 2px |
| O4 | F071–F090 | 0.833s | 原生 Three.js 全身镜头 | 左脚蹬地，车体从静止进入直行，双脚开始踩踏；最后 6 帧收束到 0 米玩法构图 | F090 后挂载 CanteenChaseOverlay，首个可操作状态为 0 米 |

O1 到 O2 使用一次直接剪切。剪切发生在自行车解锁声的瞬态位置，人物与自行车的左右关系保持一致。镜头不进行投影变形。

O2 到 O3 与 O3 到 O4 都是同一套 Three.js 骑手模型的宽景和近景切换。近景首帧直接由 O2 的确定性姿态渲染。

### 4.2 真实骑行：完整 0–755 米

| 节点 | 合同 |
|---|---|
| 0 米 | 唯一输入开放点；distance=0、goal=755、lives=3、lane=1 |
| 188 / 377 / 566 米 | 现有难度节点继续运行 |
| 700 米 | 只用于调试与连续性截图；不写状态、不切媒体、不锁输入 |
| 755 米 | 仅当 mode=story、distance=755、lives>0 时写 chaseCompleted=true |

### 4.3 Finish gate：共 133 帧，5.542 秒

| 镜号 | 帧 | 时长 | 来源 | 画面与动作 | 接点 |
|---|---:|---:|---|---|---|
| E1 | F000–F009 | 0.417s | 原生 Three.js 干净 755 米宽景 | 保留骑行方向、轮速、人物姿态和单张纸；不显示 HUD；移除错误横向台阶 | F009 的右手、刹车把、前轮姿态等于刹车近景锚点 |
| E2 | F010–F039 | 1.250s | Hailuo 2.3 固定近景；未批准时用原生近景 | 右手捏刹车，前轮降到开场轮速约 35%，轮胎接地点固定 | F039 仍保持慢速旋转，避免近景直接静止 |
| E3 | F040–F090 | 2.125s | 原生 Three.js 全身镜头 | 继续减速至零；左脚落地；右腿跨回左侧；双脚站稳；车体保持直立 | F090 完成全部下车动作 |
| E4 | F091–F120 | 1.250s | 原生 Three.js 全身镜头 | 单张纸进入中央门；玩家把自行车推到右边界并停放，松手后朝入口走两步 | 自行车离开最终地图裁切，解释剧院检查点无车 |
| E5 | F121–F132 | 0.500s | 确定性遮挡与真实校园运行时 | 剧院门柱或入口暗面覆盖全屏时执行一次硬切；最后 6 帧保持真实 picture_06 构图 | F132 后调用 completeChase() |

E3 必须在任何投影剪切之前完成完整下车动作。E4 明确展示自行车离开最终裁切，因此不需要在 theater_reached 场景新增永久自行车。

## 5. 锚点体系

所有图均满足用户确认的 5760×5760 上限。正式输出采用 PNG、8-bit sRGB、无 Alpha。

### 5.1 可继续使用的现有锚点

| ID | 文件 | 尺寸 | 用途 | 上传 Hailuo |
|---|---|---:|---|---|
| A0 | anchors/picture_01_canteen_departure_1920x1080.png | 1920×1080 | O1 校园事实与位置关系 | 否 |
| A1-old | anchors/picture_02_chase_000m_1920x1080.png | 1920×1080 | 0 米旧构图参考；共享骑手重构后需重新截图 | 否 |
| A377 | anchors/picture_03_chase_377m_1920x1080.png | 1920×1080 | 路线色板核对 | 否 |
| A700 | anchors/picture_04_chase_700m_1920x1080.png | 1920×1080 | 调试连续性 | 否 |
| A3 | anchors/picture_06_theater_arrival_1920x1080.png | 1920×1080 | E5 正式剧院外末帧 | 否 |
| S-player | anchors/subject_01_player_identity_2048x2048.png | 2048×2048 | 玩家人工一致性核对 | 否 |
| S-paper | anchors/subject_04_paper_identity_2048x1024.png | 2048×1024 | 单张纸人工一致性核对 | 否 |
| S-npc-white | anchors/subject_05_npc_white_hoodie_2048x1024.png | 2048×1024 | 白衣 NPC 人工核对 | 否 |
| S-npc-green | anchors/subject_06_npc_green_hoodie_2048x1024.png | 2048×1024 | 绿衣 NPC 人工核对 | 否 |

### 5.2 禁用锚点

| ID | 文件 | 原因 |
|---|---|---|
| A755-invalid | anchors/picture_05_chase_755m_1920x1080.png | 横向台阶覆盖道路，剧院几何不适合生成 |
| SB01-old | storyboards/sb01_mounting_mid.png | 来源与当前原生骑手模型不一致 |
| SB02-old | storyboards/sb02_theater_threshold_mid.png | 透视、人物和剧院细节不属于当前运行时 |

### 5.3 A 方案必须新截取的锚点

| ID | 计划文件 | 尺寸 | 原生时间点 | 用途 |
|---|---|---:|---|---|
| A7 | anchors/picture_07_mount_wide_start_1920x1080.png | 1920×1080 | O2 F010 | 全身上车开始 |
| A8 | anchors/picture_08_mount_grip_pedal_macro_1920x1080.png | 1920×1080 | O2 F040 | Hailuo 任务 M1 唯一上传图 |
| A9 | anchors/picture_09_chase_000m_final_1920x1080.png | 1920×1080 | O4 F090 | 真实 0 米接管终帧 |
| A10 | anchors/picture_10_finish_clean_755m_1920x1080.png | 1920×1080 | E1 F000 | 干净 755 米宽景 |
| A11 | anchors/picture_11_brake_lever_wheel_macro_1920x1080.png | 1920×1080 | E1 F009 | Hailuo 任务 M2 唯一上传图 |
| A12 | anchors/picture_12_dismount_wide_1920x1080.png | 1920×1080 | E3 F040 | 全身刹停和下车起点 |
| A13 | anchors/subject_02_bicycle_canonical_2048x2048.png | 2048×2048 | 共享骑手模型六视图 | 自行车结构人工核对 |
| A14 | anchors/subject_03_rider_action_canonical_2048x1024.png | 2048×1024 | 共享骑手模型动作表 | 上车、踩踏、刹车、下车人工核对 |

### 5.4 两个 Hailuo 上传图的构图要求

A8：

- 画面只含一只自然右手、一段蓝色袖口、一只右鞋、一个右脚踏、一个曲柄、一段链条和同一辆蓝色自行车的局部。
- 手与握把持续接触；鞋与脚踏持续接触。
- 不含脸、第二只手、第二只鞋、纸条、NPC、道路标线、建筑、标牌、UI 或文字。
- 固定相机，静态背景至少保留三个可测量的硬边特征点。

A11：

- 画面只含一只自然右手、一段蓝色袖口、一个刹车把、一个握把、一支前叉、一个前轮和轮胎接地点。
- 轮胎为完整圆形投影，接地点在同一像素位置。
- 不含脸、第二只手、第二个车轮、纸条、NPC、剧院、标牌、UI 或文字。
- 固定相机，路面仅作为无纹理色块。

Hailuo 2.3 CLI 每个任务只接受一张首帧，因此 S-player、S-paper、S-npc-white 与 S-npc-green 不上传。它们只参与生成前后人工核对。

## 6. 玩家、自行车、纸条和 NPC 的一致性合同

### 玩家

- 同一名短黑发学生。
- 蓝色外套、深色长裤、灰白鞋、深蓝背包。
- 全身动作由共享 Three.js rig 驱动。
- Hailuo 近景不出现脸，也不生成新的身体比例。

### 自行车

- 统一为蓝色校园自行车，黑色轮胎、黑色座椅、金属灰轮毂。
- 共享 rig 增加明确的右刹车把、手部、脚踏、曲柄、链条和小型前篮。
- ChaseThreeRenderer 与过场渲染器使用同一个模型构建函数与同一组比例。
- 禁止蓝色车架在骑行画面中变为黄色、电动车、摩托车或无脚踏车型。

### 纸条

- 始终只有一张米黄色污渍纸条。
- 纸条只出现在原生宽景与真实骑行，不进入 Hailuo 近景。
- Start gate 中纸条位于前方道路；Finish gate 中纸条先于玩家进入剧院中央门。
- 纸条不接触自行车、车轮、脚部或 NPC。

### NPC

- NPC 只由现有运行时生成，始终留在人行道或剧院边缘。
- Hailuo 两个近景均禁止 NPC。
- subject_05 与 subject_06 保留为人工核对图，尺寸均为 2048×1024，符合上限。
- 不因过场新增 NPC 存档、碰撞体、任务事实或互动目标。

## 7. Hailuo 2.3 任务 M1：握把与脚踏近景

唯一上传图：A8 picture_08_mount_grip_pedal_macro_1920x1080.png。

运行时使用模型输出的 F000–F029，共 1.250 秒。生成的完整约 141 帧都必须通过实体数量与几何稳定性检查；不可通过裁掉错误帧掩盖失败。

可直接粘贴的英文提示词：

~~~text
Use the input Three.js rider-rig render as the exact first frame. Create the default-length 16:9 fixed-camera low-poly gameplay detail clip. The crop shows only one student's natural bare right hand and blue jacket cuff on one bicycle handlebar grip, plus the same student's right gray-white shoe on one right pedal, the visible crank and one short chain segment. Preserve the exact blue bicycle paint, black grip, metal crank, pedal geometry, hard-edged materials, flat lighting direction and pixel-like low-poly rendering.

[Static shot] Hold the exact input composition for the first 0.20 seconds. From 0.20 to 0.55 seconds, the existing right hand closes naturally around the existing grip while the wrist remains fixed. From 0.45 to 1.10 seconds, the existing right shoe presses the pedal and the crank rotates smoothly only 35 to 45 degrees. The chain begins moving with restrained mechanical motion. From 1.10 to 1.25 seconds, hold the resulting pose. Keep the rest of the generated clip nearly still.

Exactly one hand, one forearm, one shoe, one pedal, one crank, one chain and one bicycle. Keep the hand touching the grip and the shoe touching the pedal in every frame. No face, second limb, extra finger, missing finger, extra pedal, extra wheel, paper, pedestrian, NPC, building, sign, text, HUD, camera movement, zoom, pan, tilt, focus change, frame bending, bicycle deformation, background reconstruction, motion blur, depth-of-field blur or photorealistic texture. No audio.
~~~

## 8. Hailuo 2.3 任务 M2：刹车把与前轮近景

只有 M1 获得用户明确视觉通过后，才提交 M2。

唯一上传图：A11 picture_11_brake_lever_wheel_macro_1920x1080.png。

运行时使用模型输出的 F000–F029，共 1.250 秒。完整模型输出仍需逐帧检查。

可直接粘贴的英文提示词：

~~~text
Use the input Three.js rider-rig render as the exact first frame. Create the default-length 16:9 fixed-camera low-poly gameplay braking detail clip. The crop shows only one student's natural bare right hand around one bicycle brake lever and grip in the upper frame, plus the same bicycle's front fork, single front wheel and exact tire-to-road contact point in the lower frame. Preserve the exact blue jacket cuff, blue bicycle paint, black tire, metal lever, fork geometry, hard-edged materials, flat road color, lighting direction and pixel-like low-poly rendering.

[Static shot] Hold the exact input composition for the first 0.20 seconds. From 0.20 to 0.60 seconds, the existing fingers pull the existing brake lever smoothly while the wrist stays fixed. From 0.45 to 1.10 seconds, the existing front wheel visibly decelerates to about 35 percent of its opening rotation speed. The wheel does not fully stop in this selected interval. From 1.10 to 1.25 seconds, hold the brake position and maintain slow wheel rotation. Keep the rest of the generated clip nearly still.

Exactly one hand, one forearm, one brake lever, one grip, one fork, one front wheel and one bicycle. The tire stays round and touches the same road point in every frame. No face, second hand, extra finger, missing finger, extra wheel, duplicate fork, paper, pedestrian, NPC, theater, building, sign, text, HUD, camera movement, zoom, pan, tilt, focus change, wheel deformation, frame bending, road reconstruction, collision, skid, smoke, motion blur, depth-of-field blur or photorealistic texture. No audio.
~~~

## 9. 模型输出验收

### 9.1 自动与可测量条件

- 源锚点先缩放到模型输出尺寸，再比较首帧。
- 固定背景特征点在 960×540 运行时尺寸下漂移不超过 2px。
- 轮胎宽高比变化不超过 1.5%。
- 握把、刹车把、曲柄和脚踏的可见长度变化不超过 2%。
- 近景首尾与原生渲染的手、鞋、轮轴位置差不超过 2px。
- 近景首尾的车把、脚踏和前轮角度差不超过 3 度。
- 输出保持 16:9、24 FPS、H.264、yuv420p、无音轨。
- 运行时派生片统一为 960×540。

### 9.2 全帧人工条件

- 每帧实体数量完全符合提示词。
- 没有多手、多脚、多轮、少指、车架弯折或轮胎形变。
- 没有脸、纸条、NPC、建筑、标牌、文字和 UI。
- 相机没有平移、缩放、旋转和焦点变化。
- 画风没有转为照片材质、柔化边缘或景深画面。
- 任一帧失败，整条任务标记 rejected，不进入运行时和宣传 PV。

### 9.3 接缝条件

- O2→O3→O4 与 E1→E2→E3 各自制作 5 帧接触表。
- 接触表必须同时显示原生末帧、模型首帧、模型中间帧、模型末帧、原生续帧。
- 不允许用长黑场、重复定帧或大幅模糊隐藏位置跳变。
- 音效可覆盖剪切瞬态，不可改变动作次序。

## 10. 运行时过场门

Start gate：

1. payForBike() 只完成一次性扣款并保持 phase=chase_ready。
2. bikePaid=true 立即挂载 Start gate，并锁住 Phaser、键盘、触摸、物品栏、任务栏、相机和返回按钮。
3. Start gate 完整播放到 O4 F090。
4. ended 或有界 timeout 触发 startChase()。
5. startChase() 写 phase=chasing 并发布 canteen_chase_started。
6. CanteenChaseOverlay 首帧发布 distance=0、goal=755、lives=3、lane=1。

Finish gate：

1. CanteenChaseOverlay 在 755 米提交 resolveChaseAttempt()，删除原有 900ms 自动进入剧院计时器。
2. chaseCompleted=true 后立即卸载骑行层并挂载 Finish gate。
3. Finish gate 完整播放到 E5 F132。
4. ended 或有界 timeout 触发 completeChase()。
5. completeChase() 写 theater_reached 与 campus_theater_junction。

两个 gate 使用 finishOnce() 合并 ended、timeout、media_error、play_rejected 与 reduced_motion。页面隐藏时暂停媒体和 watchdog，恢复可见后继续；隐藏期间不得自动越过 0 米或剧院检查点。

## 11. 音频设计

视频保持静音。AudioDirector 处理以下事件：

| 时间点 | 事件 | 声音 |
|---|---|---|
| 支付成功 | canteen_bike_paid | 支付确认与车锁弹开 |
| O2 开始 | canteen_chase_start_transition_started | 轻微车架与衣物动作 |
| O3 | canteen_chase_mount_detail | 握把、脚踏、链条起动 |
| O4 | canteen_chase_started | 启动现有追逐音乐与轮胎声 |
| 755 米胜利 | canteen_chase_story_cleared | 停止碰撞反馈，保持音乐 |
| E2 | canteen_chase_brake_detail | 刹车把与轮胎减速 |
| E3 | canteen_chase_dismount | 左脚落地、车架轻响 |
| E4 | canteen_chase_paper_door | 单张纸进入门内 |
| E5 完成 | canteen_chase_completed | 停止追逐音乐并播放现有纸条冲击声 |

现有 canteen_chase_finish 的纸条爆发声需移到胜利专用事件，避免三次机会耗尽时播放胜利音效。

## 12. 生成与审批顺序

1. 先重构并验证共享骑手模型。
2. 截取 A7–A14，生成新的 manifest 与两张五帧原生接触表。
3. 只提交 M1 一条 Hailuo 2.3 任务。
4. 抽取完整 141 帧检查结果与正式五帧接触表。
5. 等待用户明确通过 M1。
6. M1 通过后再提交 M2。
7. M2 通过后才制作 960×540 运行时派生片。
8. 两条均通过后接入运行时媒体；任一未通过时继续使用原生 Three.js 近景。
9. 过场链通过浏览器验收后，才允许把已通过的近景用于宣传 PV。

不得一次提交两条付费任务。不得把整条 5.875 秒输出直接接入正式时间线。

## 13. 验收矩阵

浏览器覆盖 Blink、Gecko、WebKit；视口覆盖 1280×720、一个非 16:9 桌面尺寸和 390×844。

Start gate：

- 支付只扣一次。
- 刷新重播上车过场。
- 完整显示握把、跨座、坐稳、脚踏和蹬地。
- 0 米前无键盘、触摸或物品输入穿透。
- 第一个可操作状态精确为 0 米。

真实骑行：

- 连续完成 0–755 米。
- 700 米没有媒体、状态或输入变化。
- 三次机会耗尽仍从 0 米重试。
- 755 米成功后不再回到 0 米。

Finish gate：

- 使用干净 755 米宽景，不出现错误横向台阶。
- 完整显示捏刹车、减速、停车、左脚落地、跨腿、站稳与移车。
- 单张纸先进入剧院门。
- 自行车离开最终裁切后再切到 picture_06。
- 媒体失败、404、解码错误、play() 拒绝和 reduced-motion 均能通过原生回退到达剧院。
- 玩家最终位于 theater_reached 与 campus_theater_junction，仍需执行现有剧院入口交互。

## 14. 当前验证状态

- 旧失败视频：2 条用户拒绝，运行时接入权限为 false。
- 现有锚点尺寸与色彩检查：1 次，全部低于 5760×5760。
- A 方案分镜与状态合同：1 次代码路径审阅，当前等级为假说。
- 新共享骑手模型：0 次实现验证。
- 新 A7–A14 锚点：0 张已生成。
- Hailuo M1：0 次生成。
- Hailuo M2：0 次生成。
- A 方案完整浏览器链：0 次验证。

在新 M1、M2 和浏览器链分别通过前，不得将本设计描述为已完成过场。
