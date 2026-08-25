# MiniMax H3：食堂上车、755 米骑行与剧院抵达衔接

> 已废止执行：本文件的跨投影整段生成、picture_05 终点首帧和旧中间分镜均不可继续使用。当前正式设计见 2026-08-23-canteen-bike-transition-option-a-design.md。

## 1. 范围结论

本次只设计以下链路：

```text
东区大食堂外完成 2.00 元支付
→ Clip 01：上车并接入骑行首帧
→ 当前运行时完成真实 0–755m 骑行
→ Clip 02：刹停、下车并接回剧院入口地图
→ campus_theater_junction
→ 玩家在入口执行交互后才进入 theater_lobby
```

当前项目证据：

- `docs/canteen-chase-3d-runtime.md` 规定扫码完成后直接进入固定 755 米追逐，终点为求是大讲堂入口；距离、碰撞、机会次数和剧情完成继续由 TypeScript 控制器负责。
- `ChapterThreeCanteenController.payForBike()` 在付款成功后写入 `phase: "chasing"` 并发布 `canteen_chase_started`。
- `CanteenChaseOverlay` 在距离达到 `755` 时提交胜利；当前实现等待 `900ms` 后继续。
- `ChapterThreeCanteenController.completeChase()` 将状态接到 `campus_theater_junction`。
- 剧院室内仍由 `ChapterThreeTheaterController.enterTheater()` 的后续入口交互开启。

因此，Clip 02 的末帧必须是剧院外部检查点，不能直接生成剧院大厅。

## 2. H3 参数与文件约束

- 模式：全参考生成。
- 输出比例：`16:9`。
- Clip 01：`6.0s`。
- Clip 02：`7.0s`。
- 推荐输出：先尝试 1440p；如任务失败，改为 768p，保持相同画幅和提示词。
- 帧率：按 H3 当前合同使用 24 FPS。
- 输入图片：PNG、8-bit sRGB、无 Alpha。
- 输入尺寸：本包最大 `2048×2048`，低于 `5760×5760`。
- 标签：保持 `<Picture N>`、`<Subject N>` 原样，不要改成中文标签。
- 音频：两个片段均生成静音画面，游戏继续控制骑行音效、旁白和音乐。

本轮未能从飞书登录页重新提取官方正文；上述全参考六段结构和标签规则沿用此前已完成的官方文档核对记录。正式批量生成前，仍应在当前 H3 页面确认一次可选时长、分辨率和图片槽数量。

## 3. 锚点设计

### 3.1 场景锚点

| 文件 | 来源 | H3 用途 |
|---|---|---|
| `picture_01_canteen_departure_1920x1080.png` | `c3-canteen-bike` 当前实机画面 | Clip 01 开始 |
| `picture_02_chase_000m_1920x1080.png` | 3D 追逐调试页 `distance=0` | Clip 01 结束 |
| `picture_03_chase_377m_1920x1080.png` | 3D 追逐调试页 `distance=377` | 沿途色板核对，不默认上传 |
| `picture_04_chase_700m_1920x1080.png` | 3D 追逐调试页 `distance=700` | 剧院接近比例核对，不默认上传 |
| `picture_05_chase_755m_1920x1080.png` | 3D 追逐调试页 `distance=755` | Clip 02 开始 |
| `picture_06_theater_arrival_1920x1080.png` | `c3-canteen-theater` 当前实机画面 | Clip 02 结束 |

### 3.2 主体锚点

| 主体 | 文件 | 一致性要求 |
|---|---|---|
| `<Subject 1>` 玩家 | `subject_01_player_identity_2048x2048.png` | 黑色短发、蓝色外套、深色长裤、灰白鞋；只生成一名玩家 |
| `<Subject 2>` 自行车 | `subject_02_bicycle_1024x1024.png` | 蓝色车架、前篮、黑色座椅和黑色轮胎；不能改色或变成电动车 |
| `<Subject 3>` 骑行动作 | `subject_03_rider_action_2048x1024.png` | 六格是同一玩家的踩踏阶段；最终镜头只能出现一名骑手 |
| `<Subject 4>` 纸条 | `subject_04_paper_identity_2048x1024.png` | 六格是同一张纸的飞行阶段；画面内始终只有一张纸 |
| `<Subject 5>` 白衣 NPC | `subject_05_npc_white_hoodie_2048x1024.png` | 白色连帽衫、蓝色背包、手机；只出现在人行道 |
| `<Subject 6>` 绿衣 NPC | `subject_06_npc_green_hoodie_2048x1024.png` | 绿色连帽衫、浅色背包、手持饮料；只出现在人行道 |

主体图统一使用 `#667386` 实色背景。多帧图只表达动作变化，不能被解释为多名角色、多辆自行车或多张纸。

## 4. Clip 01 分镜：食堂外上车并接入 0m

### 4.1 上传映射

| 上传次序 | H3 标签 | 文件 |
|---|---|---|
| 1 | `<Picture 1>` | `picture_01_canteen_departure_1920x1080.png` |
| 2 | `<Picture 2>` | `sb01_mounting_mid.png` |
| 3 | `<Picture 3>` | `picture_02_chase_000m_1920x1080.png` |
| 4–9 | `<Subject 1>`–`<Subject 6>` | 六张主体锚点，顺序见 3.2 |

### 4.2 逐秒分镜

| 时间 | 画面与动作 | 镜头与接缝 |
|---|---|---|
| `0.0–1.0s` | 严格贴合 `<Picture 1>`。玩家站在蓝色自行车左侧，纸条在前方道路方向。 | 北向俯视，先稳定 8 帧，不生成 UI。 |
| `1.0–2.4s` | 玩家左手握车把、右腿跨过车座，坐稳并把双脚放到脚踏。自行车保持原位置。 | 镜头缓慢下降并朝玩家背后靠近，参考 `<Picture 2>`。 |
| `2.4–3.0s` | 玩家蓝色后背占据画面 90% 以上。 | 在蓝色外套完全遮挡画面的时刻执行一次隐藏硬切，禁止溶解和人物形变。 |
| `3.0–4.8s` | 切入后视低面数像素 3D。玩家开始踩踏，纸条沿中间车道前进，NPC 留在人行道。 | 镜头从玩家后方拉开，车把与前轮保持清晰。 |
| `4.8–6.0s` | 严格收束到 `<Picture 3>`，骑手居中、前轮回正、纸条在道路前方。 | 最后稳定 8 帧，供真实骑行首帧无闪动接入。 |

### 4.3 可直接粘贴的 H3 全参考提示词

```text
subject_definitions:
<Subject 1> is the only playable student: short black hair, blue jacket, dark trousers, gray-white shoes. Preserve his face, clothing colors, body proportions, and hairstyle from the reference sheet. <Subject 2> is the only bicycle: a blue campus share bicycle with a front basket, black saddle, black tires, and the same frame geometry as the reference. <Subject 3> shows successive pedaling phases of the same <Subject 1> riding the same <Subject 2>; it does not represent multiple riders. <Subject 4> is one stained beige paper sheet with one dark red stain; its six reference poses are successive flight deformations of the same single sheet. <Subject 5> is one white-hoodie student with a blue backpack and phone. <Subject 6> is one green-hoodie student with a light backpack and a drink. If pedestrians are visible, keep <Subject 5> and <Subject 6> on sidewalks only, with no duplicate instance.

summary:
Create one continuous six-second transition from the exact north-up East Canteen composition in <Picture 1>, through the bicycle-mounting composition in <Picture 2>, into the exact rear-view 755-meter chase starting composition in <Picture 3>. The student mounts the blue bicycle, pushes off, and begins pursuing the single stained paper. Use one concealed hard cut while the blue back of <Subject 1> fully covers the frame to change from the top-down campus view to the low-poly pixel 3D chase view. End at the playable 0-meter chase frame. No dialogue, captions, HUD, distance counter, or generated title.

retention_analysis:
Preserve the East Canteen footprint, road directions, crosswalk placement, trees, and the existing Chinese canteen sign from <Picture 1>. Preserve the three-lane road, roadside trees, low-poly block geometry, hard pixel edges, camera height, and centered rider scale from <Picture 3>. Preserve exactly one <Subject 1>, one <Subject 2>, and one <Subject 4>. The multiple poses inside every subject sheet are motion stages, not extra entities. Do not duplicate the rider, bicycle, paper, wheels, limbs, backpack, basket, or pedestrians. Do not change the bicycle into a scooter, motorcycle, or electric bicycle. Do not put pedestrians in a traffic lane. Do not add vehicles near the player. Keep the stained paper in front of the rider and never attach it to the bicycle. Do not invent new signs, logos, QR codes, readable interface text, speed lines, motion blur, depth-of-field blur, soft shadows, photorealistic surfaces, or cross-dissolves.

detailed_description:
0.0-1.0 seconds: match <Picture 1> exactly. Hold the north-up composition for the first eight frames. <Subject 1> stands on the left side of <Subject 2>. The bicycle wheels are still and aligned with the road. One <Subject 4> is ahead in the road direction. 1.0-2.4 seconds: <Subject 1> grips the handlebar, swings the right leg over the saddle, sits, places both feet on the pedals, and keeps the bicycle stationary until balanced. Approach the action and composition of <Picture 2>. The movement is anatomically continuous and the bicycle remains grounded. 2.4-3.0 seconds: the camera descends and pushes directly toward the back of the blue jacket until the blue back fills more than ninety percent of the frame. Execute one concealed hard cut only while the jacket fully occludes the view. Do not morph the character or bicycle during the cut. 3.0-4.8 seconds: emerge behind the same rider in the low-poly pixel 3D road. <Subject 1> starts a steady pedaling cycle from <Subject 3>. The same blue bicycle accelerates straight in the center lane. The single paper moves ahead at a readable distance. Any referenced pedestrians stay on sidewalks and appear at most once each. 4.8-6.0 seconds: converge precisely to <Picture 3>. Center the rider, straighten the handlebar and front wheel, preserve the visible three-lane road and roadside campus objects, and keep one paper ahead. Hold the final composition for the last eight frames so the game can resume at 0 meters without a flash or position jump.

overall_soundscape:
N/A. Generate silent video. The game runtime owns bicycle unlock sound, tire sound, ambience, narration, and collision audio.

non_diegetic_music:
N/A. Do not generate music.
```

## 5. Clip 02 分镜：755m 完成并抵达剧院入口

### 5.1 上传映射

| 上传次序 | H3 标签 | 文件 |
|---|---|---|
| 1 | `<Picture 1>` | `picture_05_chase_755m_1920x1080.png` |
| 2 | `<Picture 2>` | `sb02_theater_threshold_mid.png` |
| 3 | `<Picture 3>` | `picture_06_theater_arrival_1920x1080.png` |
| 4–9 | `<Subject 1>`–`<Subject 6>` | 六张主体锚点，顺序见 3.2 |

### 5.2 逐秒分镜

| 时间 | 画面与动作 | 镜头与接缝 |
|---|---|---|
| `0.0–1.0s` | 严格贴合 `<Picture 1>`，剧院已经处于近景，骑手仍在中间车道。 | 先稳定 8 帧，不显示完成卡和 HUD。 |
| `1.0–3.0s` | 骑手停止踩踏、轻捏刹车并向中央入口减速；纸条沿同一路径进入门内。 | 后视跟拍继续前移，剧院按真实距离放大，参考 `<Picture 2>`。 |
| `3.0–4.5s` | 自行车停在入口外右侧，玩家左脚落地并从左侧下车。 | 车轮停止，车身保持直立，不发生撞门或摔倒。 |
| `4.5–5.5s` | 玩家向入口走两到三步；自行车留在画面右下边缘并逐渐离开最终裁切。 | 镜头垂直升高并下俯，白色弧顶短暂遮住画面，在完全遮挡时执行一次隐藏硬切。 |
| `5.5–7.0s` | 严格收束到 `<Picture 3>`：玩家位于剧院入口外道路，纸条已经进入室内，自行车不在最终画面。 | 北向俯视，最后稳定 8 帧，接入 `campus_theater_junction`。 |

### 5.3 可直接粘贴的 H3 全参考提示词

```text
subject_definitions:
<Subject 1> is the only playable student: short black hair, blue jacket, dark trousers, gray-white shoes. Preserve his face, clothing colors, body proportions, and hairstyle from the reference sheet. <Subject 2> is the only blue campus share bicycle with a front basket, black saddle, black tires, and the exact frame geometry shown in the reference. <Subject 3> contains successive pedaling phases of the same <Subject 1> on the same <Subject 2>; it is one rider in motion. <Subject 4> is one stained beige paper sheet with one dark red stain; every reference pose belongs to the same single paper. <Subject 5> is one white-hoodie student with a blue backpack and phone. <Subject 6> is one green-hoodie student with a light backpack and a drink. If pedestrians remain visible near the theater approach, keep them outside the road and use no more than one instance of each referenced NPC.

summary:
Create one continuous seven-second arrival transition from the exact 755-meter finish composition in <Picture 1>, through the auditorium-threshold composition in <Picture 2>, to the exact north-up theater-junction composition in <Picture 3>. The same rider brakes, stops outside the central entrance, dismounts on the left side, leaves the bicycle near the lower-right edge, and takes a few steps toward the entrance while the single stained paper passes through the central doorway. Raise the camera into the top-down campus view. Use one concealed hard cut only while the white curved auditorium roof completely covers the frame. End outside the theater at campus_theater_junction; do not enter or show the theater lobby.

retention_analysis:
Preserve the low-poly pixel 3D Qiushi Grand Auditorium in <Picture 1> and <Picture 2>: white curved roof, dark blue glass facade, white vertical columns, central double-door entrance, broad pale steps, flowerbeds, black campus lamps, and hard-edged shadows. Preserve the north-up campus road geometry, auditorium footprint, adjacent building, planting beds, road loop, and player scale from <Picture 3>. Preserve exactly one player, one bicycle until it leaves the final crop, and one paper until it crosses the doorway. Multiple subject poses are successive motion stages, not additional people or objects. Do not duplicate the paper, rider, bicycle, wheels, limbs, doors, roof, lamps, or NPCs. Do not change the bicycle color or geometry. Do not let the rider collide with the door, mount the stairs while still riding, fall, jump, teleport, or pass through the bicycle. Do not show an interior lobby. Do not add tickets, crowds, vehicles, signage, UI, completion cards, distance text, subtitles, motion blur, depth-of-field blur, photorealistic textures, cross-dissolves, or a second theater.

detailed_description:
0.0-1.0 seconds: reproduce <Picture 1> exactly and hold the first eight frames. Keep the rider centered in the middle lane, the front wheel straight, the auditorium directly ahead, and one stained paper on the center approach. 1.0-3.0 seconds: the same rider stops pedaling and applies a controlled brake. The wheels decelerate while remaining grounded. Continue a close rear follow so the auditorium grows only from forward movement. The single paper stays ahead and passes through the central doorway. Approach the composition of <Picture 2> without changing the building or rider identity. 3.0-4.5 seconds: stop the bicycle on level pavement outside the steps, slightly to the right of the central path. <Subject 1> places the left foot on the ground, swings the right leg over the saddle, and stands on the left side while holding the handlebar. The bicycle remains upright and stationary. 4.5-5.5 seconds: <Subject 1> releases the bicycle and walks two or three steps toward the entrance. Keep the bicycle near the lower-right edge so it can leave the final crop. Raise the camera vertically and tilt it toward a north-up view. Allow the white curved roof to fill and fully occlude the frame, then execute one concealed hard cut while the roof covers everything. Do not use a dissolve. 5.5-7.0 seconds: emerge into the exact north-up campus composition in <Picture 3>. Place the same student at the theater-junction road position and preserve his size and orientation. The bicycle is outside the final crop and the paper is already inside, so neither is visible in the final held frame. Do not show the lobby or advance the story beyond the exterior checkpoint. Hold the final composition for the last eight frames for a clean gameplay handoff.

overall_soundscape:
N/A. Generate silent video. The game runtime owns braking, tire, footstep, paper, ambience, narration, and transition audio.

non_diegetic_music:
N/A. Do not generate music.
```

## 6. 生成顺序与返工策略

1. 先生成 Clip 01 的单个低成本预览，确认玩家、自行车、纸条数量和隐藏切点。
2. Clip 01 通过后再生成 1440p 正式版。
3. 再生成 Clip 02 预览，重点检查下车动作、纸条入门和最终外部检查点。
4. Clip 02 通过后再生成 1440p 正式版。
5. 某一段失败时只调整该段。不要同时替换主体锚点和镜头提示词，否则无法判断漂移来源。

返工优先级：

1. 主体数量错误：强化 `exactly one` 和 `successive motion stages`，不要新增参考图。
2. 身份漂移：保留主体图，缩短动作描述，删除会改变衣着或材质的形容词。
3. 接缝闪动：增加首尾稳定帧，隐藏切点保持在蓝色外套或白色弧顶完全遮挡时。
4. 纸条消失过早：只改逐秒段落中纸条的位置，不更换纸条锚点。
5. NPC 抢占画面：保留 NPC 身份图，将其明确限制在人行道远景；仍不稳定时从该次上传中移除 `<Subject 5>` 和 `<Subject 6>`，同时要求不生成新行人。

## 7. 模型输出验收清单

### Clip 01

- 首 8 帧与 `<Picture 1>` 构图一致，玩家和自行车位置无跳变。
- 玩家完整完成握把、跨车、坐稳和起步，四肢数量正常。
- 蓝色外套遮挡时只发生一次硬切，没有交叉溶解。
- 结束时只有一名骑手、一辆蓝色自行车和一张纸。
- 最后 8 帧与 `<Picture 3>` 接近，骑手居中、前轮回正、纸条在前。

### Clip 02

- 首 8 帧与 755 米终点一致，剧院外形不变。
- 刹车、停车、左脚落地和左侧下车顺序连续。
- 纸条只出现一张，并且先于玩家进入中央门。
- 自行车停在入口外，没有骑上台阶、撞门或穿模。
- 白色弧顶完全遮挡时只发生一次硬切。
- 最后 8 帧严格停在剧院外部检查点；不出现大厅、观众席或票务画面。

### 两段共同要求

- `16:9`、无黑边、无画幅拉伸。
- 玩家衣着、自行车颜色、纸条污渍和 NPC 身份保持一致。
- 没有新增 HUD、字幕、里程数字、按钮、二维码或生成标牌。
- 没有双影、叠帧、软化像素边缘、运动模糊或景深。
- 视频可静音导出，游戏音频继续使用现有事件链。

当前 H3 实际生成与播放验证次数为 `0`。以上锚点和提示词通过本地图片检查，仍需以 H3 第一轮预览作为模型一致性验证 1。

## 8. 后续运行时接入点

本轮未改运行时代码。以后接入正式视频时，建议使用以下边界：

- Clip 01：接在 `canteen_chase_started` 之后，视频 `ended` 后再开放 0 米骑行输入。
- Clip 02：接在 `canteen_chase_finish` 的 `won` 结果之后，视频 `ended` 后再调用当前 `onContinue` / `completeChase()`。
- 当前 `CanteenChaseOverlay` 的固定 `900ms` 终点等待无法容纳 7 秒视频。正式接入时应改为媒体 `ended` 握手，并保留加载失败时的有界回退。
- 视频只控制展示。`phase`、`distance`、`chaseCompleted`、`campus_theater_junction` 和存档继续由 TypeScript 控制器持有。
