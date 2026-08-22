# MiniMax H3：第三章至第四章衔接过场生成包

## 1. 采用方案

现有正式流程保持不动：

1. 第三章启真湖追逐完成，磁性连接件损坏。
2. 玩家完成第三章半的手机证据恢复。
3. 恢复回放显示纸条从启真湖进入仍亮灯的教学楼。
4. 回放结束后显示第四章任务卡，玩家确认后进入 A1 门厅。

H3 成片只替换恢复回放的视觉层。ChapterFourPrologueController、任务卡、字幕、声音、存档和第四章入口继续由现有 TypeScript 运行时控制。

当前正式运行时已在 `2026-08-22` 接入用户提供的三段实际成片。三段按原顺序、原速度统一到 `960×540 / 24 FPS / H.264 High / yuv420p`，总长 `43.833s`；最终版本经过高质量压缩并封装为 fragmented MP4，全部 H3 音轨已移除：

| 顺序 | 用户源文件 | 实际时长 | 运行时阶段 | 主要事件 |
| ---: | --- | ---: | --- | --- |
| 1 | img2video-31233a69-f533-4741-afe6-7ccfdf06ba25.mp4 | 13.667 s | snap + lake_exit | 磁性连接件断裂，纸条离开湖面 |
| 2 | flying-paper-arcade.mp4 | 15.083 s | arcade + entrance | 纸条经过夜间拱廊并随学生开门进入教学楼 |
| 3 | 09532bd73d59913e21df487ca7ee1629_raw.mp4 | 15.083 s | lobby + closing | 纸条穿过大厅，教学楼进入熄灯后的走廊状态 |

规范化输出为 `src/assets/rpg/cinematics/chapter4-prologue/chapter35_to_chapter4_h3_transition.mp4`，大小 `8282814` bytes，SHA-256 为 `d5cb9e9a91ef778337f5eeef74fad59643ca1f393607f993d7e5fc8196678aff`。与压缩前规范化成片的全帧 SSIM 为 `0.988282`。任务卡由 React 在 `43834ms` 显示，不写入视频帧。

下表保留最初的五段生成分镜目标，用于复查提示词和锚点；它不再提供正式运行时时长：

| 成片 | 目标时长 | 线路 | 现有阶段 | 主要事件 |
| --- | ---: | --- | --- | --- |
| c34_h3_01_snap_lake_exit.mp4 | 12.40 s | 正式版 | snap + lake_exit | 磁性连接件断裂，纸条离开湖面 |
| c34_h3_02_arcade.mp4 | 12.00 s | 正式版 | arcade | 纸条沿夜间拱廊向教学楼移动 |
| c34_h3_03_entrance.mp4 | 8.00 s | 正式版 | entrance | 离楼学生推开玻璃门，纸条进入入口 |
| c34_h3_04_lobby.mp4 | 11.80 s | 扩展版 | lobby | 纸条穿过湿地面上方，保洁员向内移动 |
| c34_h3_05_closing.mp4 | 7.40 s | 扩展版 | closing | 保安清楼，灯光逐段关闭，纸条进入深处 |

若生成入口只接受整数秒，正式版使用 12 / 12 / 8 秒，扩展版再生成 12 / 8 秒；剪辑时把第四段裁到 11.80 秒、第五段裁到 7.40 秒。不要用大幅变速补时。

### 1.1 当前源码对齐状态（2026-08-22）

- `PrologueTimeline.ts` 的活动 phase 为 `snap / lake_exit / arcade / entrance / lobby / closing`，精确场景切点来自三段实际视频的镜头检测和人工画面复核。
- `Chapter4PrologueOverlay.tsx` 以 H3 合并视频为主画面；常规 Vite 构建使用资源 URL，单文件构建把 Base64 分为 `256 KiB` 片段，经 Worker 解码并通过 `MediaSource / SourceBuffer` 顺序追加。Canvas 2D 回放继续覆盖加载失败、解码失败、自动播放失败和减少动态效果偏好。
- `DeveloperChannel.ts` 的序幕检查点已对齐 `0 / 6708 / 13667 / 23542 / 28750 / 33417 / 43834ms`。
- `chapter4-prologue-h3.asset.json` 锁定源文件顺序、输入哈希、成片哈希、帧数、音轨数、fragmented MP4 媒体类型和切点；剧情声音继续只由 `chapter4-prologue.audio.json` 控制。
- 序幕音乐使用 `music_ch4_prologue_h3_44s.mp3`：`44.000s / 353687 bytes / 64306 bit/s / 44.1kHz stereo`。该资源由现有第四章序幕音乐派生，原文件保持不变；其 SHA-256 为 `0b8e5a0eb47f431af5d96f13b9bbff07580419b1641de9e6637fa59d7c4685c6`。
- `Chapter4PrologueRuntimeGate` 是任务卡确认、controller 提交、requestId、20 秒超时、刷新恢复、A1 live-ready 和 `80ms` 释放的唯一所有者。下层 Phaser 在等待期保持挂载，并通过 `inert`、`aria-hidden`、Pointer 与 keyboard block 停止用户输入。

## 2. H3 标签与上传规则

完整全参考提示词使用六段英文结构：

1. subject_definitions
2. summary
3. retention_analysis
4. detailed_description
5. overall_soundscape
6. non_diegetic_music

图片上传槽从 ref_image_0 开始计数，提示词标签从 1 开始计数：

| 上传槽 | 提示词标签 |
| --- | --- |
| ref_image_0 | <Picture 1> |
| ref_image_1 | <Picture 2> |
| ref_image_2 | <Picture 3> |
| ref_image_3 | <Picture 4> |
| ref_image_4 | <Picture 5> |

每个成片都重新从 <Picture 1> 编号。不要在提示词里写 image_0、image_1 或字段全称。

## 3. 全局连续性合同

### 3.1 画面

- 比例固定 16:9，逻辑画幅固定 960×540。
- 画风固定为清晰硬边像素动画，保持当前游戏的有限色阶、像素簇和夜间蓝色环境。
- 建筑、栏杆、门框、楼梯和地面透视服从各自环境锚点。
- 不混合俯视地图、伪 2.5D 和写实摄影视角。
- 不生成 UI、字幕、章节标题、地点名、路线箭头、任务标记、水印或可读的新文字。
- 所有建筑招牌保持空白。

### 3.2 纸条

- 同一张小型不规则旧纸，主体为暖米白色，边缘和表面保留棕褐色磨损像素。
- 右上区域固定保留暗红色八角星形印记。
- 表面不生成可读文字，也不新增线稿、图案或第二个印记。
- 潮湿感只由场景中的冷蓝色高光与地面反射表达，不把纸边改成蓝色。
- 移动由磁力、钓线回弹、风压和地面气流产生。
- 不添加脸、眼睛、嘴、手脚或任何生物结构。
- 青蓝风痕属于场景效果，与纸条主体颜色分离；痕迹稀疏、短促、断开。

### 3.3 人物与声音

- 离楼学生、保洁员和保安分别使用各自精灵图作为身份依据。
- 人物服装、发型、年龄和身体比例在所属片段中固定。
- NPC 动作锚点中的多个人形表示同一角色的连续动作阶段，每个目标画面只出现对应的一名角色和一套道具。
- NPC 锚点的纯色蓝灰背景只用于主体分离，目标视频继续使用对应环境锚点。
- 人物全程安静，嘴巴自然闭合，无对白、无人声、无念白、无歌唱、无口型变化。
- 人物动作持续且明确，避免直视镜头站立。
- H3 输出只取视频轨。交付前移除 H3 音轨，继续使用现有 chapter4-prologue.audio.json 及本地配音、音乐和音效。
- 每段提示词均使用 overall_soundscape: N/A 与 non_diegetic_music: N/A。

## 4. 参考图锚点

### 4.1 环境锚点

| ID | 文件 |
| --- | --- |
| ENV-SNAP-A | docs/assets/minimax-h3-chapter3-4/anchors/transition/c34_01_start_snap_h3_1672x941.png |
| ENV-LAKE-B | docs/assets/minimax-h3-chapter3-4/anchors/transition/c34_01_end_lake_exit_h3_1672x941.png |
| ENV-ARCADE-A | docs/assets/minimax-h3-chapter3-4/anchors/transition/c34_02_start_arcade_h3_1672x941.png |
| ENV-ARCADE-B | docs/assets/minimax-h3-chapter3-4/anchors/transition/c34_02_end_arcade_h3_1672x941.png |
| ENV-ENTRANCE-A | docs/assets/minimax-h3-chapter3-4/anchors/transition/c34_03_start_entrance_h3_1672x941.png |
| ENV-ENTRANCE-B | docs/assets/minimax-h3-chapter3-4/anchors/transition/c34_03_end_entrance_h3_1672x941.png |
| ENV-LOBBY-A | docs/assets/minimax-h3-chapter3-4/anchors/transition/c34_04_start_lobby_h3_1672x941.png |
| ENV-LOBBY-B | docs/assets/minimax-h3-chapter3-4/anchors/transition/c34_04_end_lobby_h3_1672x941.png |
| ENV-CLOSING-A | docs/assets/minimax-h3-chapter3-4/anchors/transition/c34_05_start_closing_h3_1672x941.png |
| ENV-CLOSING-B | docs/assets/minimax-h3-chapter3-4/anchors/transition/c34_05_end_closing_h3_1672x941.png |
| A1-HANDOFF | docs/assets/minimax-h3-chapter3-4/anchors/transition/c34_exit_a1_2245_h3_1672x941.png |

这些文件是可直接上传或用于回接验收的 `1672×941`、8-bit sRGB、无透明通道 PNG。ENV-SNAP-A、ENV-LOBBY-A、ENV-LOBBY-B 与 ENV-CLOSING-B 已把必要的纸条、钓线或 NPC 固定到首尾构图；其他环境锚点保持空场，供主体从画外进入或离开。A1-HANDOFF 只用于运行时回接，不占用 H3 图片槽。

### 4.2 主体锚点

| ID | 文件 |
| --- | --- |
| PAPER-A | docs/assets/minimax-h3-chapter3-4/anchors/paper/paper_flight_front_h3_1024.png |
| PAPER-B | docs/assets/minimax-h3-chapter3-4/anchors/paper/paper_flight_fold_h3_1024.png |
| PAPER-C | docs/assets/minimax-h3-chapter3-4/anchors/paper/paper_flight_lowlight_h3_1024.png |
| STUDENT-IDLE | docs/assets/minimax-h3-chapter3-4/anchors/npc/student_idle_h3_1024.png |
| STUDENT-MOTION | docs/assets/minimax-h3-chapter3-4/anchors/npc/student_push_door_h3_1536x1024.png |
| CLEANER-IDLE | docs/assets/minimax-h3-chapter3-4/anchors/npc/cleaner_idle_h3_1024.png |
| CLEANER-MOTION | docs/assets/minimax-h3-chapter3-4/anchors/npc/cleaner_push_cart_h3_3584x1024.png |
| GUARD-IDLE | docs/assets/minimax-h3-chapter3-4/anchors/npc/guard_check_watch_h3_1024.png |
| GUARD-MOTION | docs/assets/minimax-h3-chapter3-4/anchors/npc/guard_walk_h3_2048x1024.png |
| CLEANER-LIGHT | docs/assets/minimax-h3-chapter3-4/anchors/npc/cleaner_toggle_lights_h3_1536x1024.png |

纸条原始游戏精灵只有 `64×64`，不再直接上传。PAPER-A、PAPER-B、PAPER-C 均为 `1024×1024` 的 H3 专用派生锚点，低于 `5760×5760` 上限：原始画布最近邻放大到 `768×768`，居中放在统一的 `#273142` 无纹理背景上。三张图分别固定正面、弯折面和低照度颜色，不包含荧光版本。

NPC 原始精灵高度只有 `128px`，同样不再直接上传。身份锚点使用 `1024×1024` 画布，动作锚点按帧数使用 `1536×1024`、`2048×1024` 或 `3584×1024` 画布，全部低于 `5760×5760` 上限。统一的 `#667386` 背景只用于主体分离，不进入目标视频；动作图中的多个人形是同一角色的连续动作阶段，不能生成多名角色。

### 4.3 960×540 画面坐标锚点

| 成片 | 对象 | 起点 | 终点 | 约束 |
| --- | --- | ---: | ---: | --- |
| 01 | 纸条 | (484,396) | (930,270) | 起点在湖面中央偏下；尾段从右侧离开 |
| 01 | 钓线 | (44,92) | (474,322) | 断裂前形成斜向张力 |
| 02 | 纸条 | (32,272) | (930,272) | 拱廊中上部横向移动 |
| 03 | 纸条 | (30,316) | (518,272) | 从左侧进入玻璃门中心 |
| 03 | 离楼学生脚点 | (836,482) | (514,482) | 先看手机，再推门，最后离开门区 |
| 04 | 纸条 | (472,374) | (918,250) | 从入口中下部升到头部以上 |
| 04 | 保洁员脚点 | (286,478) | (744,478) | 先拖地，再推车向右 |
| 05 | 纸条 | (64,268) | (690,268) | 保持头部以上高度 |
| 05 | 保安脚点 | (888,490) | (802,490) | 右侧入场，看表、照地、使用对讲机 |
| 05 | 保洁员脚点 | (150,476) | (150,476) | 左侧固定操作灯控 |

### 4.4 接缝规划与实际接入

下表保留五段生成方案的原接缝规划，供单段素材复查：

| 接缝 | 前一画面 | 后一画面 | 时长 | 处理规则 |
| --- | --- | --- | ---: | --- |
| S0 游戏→成片 01 | 第三章半确认“播放恢复回放”后的启真湖画面 | ENV-SNAP-A | 0.32 s | 保留现有 `RECOVERED TIMELINE` UI；用 8 个像素块从左到右覆盖，再从同一构图揭开成片 01。音频时钟从 `0ms` 开始。 |
| S1 成片 01→02 | ENV-LAKE-B，纸条从右侧离开 | ENV-ARCADE-A，纸条从左侧进入 | 2 帧 | 24 FPS 下直接动作匹配剪切；纸条高度保持在逻辑画布 `y=270±12`，不做溶解。 |
| S2 成片 02→03 | ENV-ARCADE-B，纸条从右侧离开 | ENV-ENTRANCE-A，纸条从左侧进入 | 2 帧 | 保持从左向右速度；用前景柱边完成遮挡剪切，不叠放两张纸。 |
| S3 正式版：成片 03→任务卡→A1 | ENV-ENTRANCE-B | React 任务卡，再到 A1-HANDOFF | 0.50 s + 等待确认 + 0.24 s | 尾帧保持 12 帧；任务卡从右侧分 8 个像素步进进入。确认后任务卡和过场层继续遮挡，等 `c4_a1_lobby` 发出 ready，再用 6 个像素步进揭开 A1。 |
| S3E 扩展版：成片 03→04 | ENV-ENTRANCE-B，纸条进入玻璃门 | ENV-LOBBY-A，镜头位于门内 | 4 帧 | 以玻璃门竖框为切点；先让门框占画面中央，再切到门厅中轴。学生只属于成片 03，保洁员只属于成片 04。 |
| S4E 扩展版：成片 04→05 | ENV-LOBBY-B，纸条从右侧离开 | ENV-CLOSING-A，纸条从左侧进入 | 2 帧 | 保持纸条高度与方向；用右侧墙面切到下一段左侧墙面，不做交叉淡化。 |
| S5E 扩展版：成片 05→任务卡→A1 | ENV-CLOSING-B | React 任务卡，再到 A1-HANDOFF | 0.50 s + 等待确认 + 0.24 s | 处理规则与正式版 S3 相同。 |

原方案的 `32.40s / 51.60s` 只描述计划生成时长。当前合并视频使用三个实际源文件，接缝为：`13.667s` 的湖岸→拱廊、`28.750s` 的玻璃入口→门厅，以及 `43.834s` 的视频→React 任务卡。三个接缝均为直接剪切，不做交叉溶解。任务卡确认后写状态、A1 ready 后释放遮罩的控制顺序保持不变。

## 5. 成片 01：磁扣断裂与离开湖面

上传顺序：

| 上传槽 | 文件 |
| --- | --- |
| <Picture 1> | ENV-SNAP-A |
| <Picture 2> | ENV-LAKE-B |
| <Picture 3> | PAPER-A |
| <Picture 4> | PAPER-B |
| <Picture 5> | PAPER-C |

~~~text
How the reference pictures align with the target video — Picture 1 (from Shot 1) aligns with the 0.00-second mark of the target video; Picture 2 (from Shot 2) aligns with the 12.40-second mark of the target video.

subject_definitions:
<Subject 1> is the same small irregular aged paper defined by <Picture 3>, <Picture 4>, and <Picture 5>. It has a warm ivory body, fixed brown worn pixels and stains, one dark-red eight-point star-shaped seal mark near the upper-right area, and no readable writing. <Picture 3> fixes the front view, <Picture 4> fixes the folded view, and <Picture 5> fixes the low-light color response. Its outline, seal position, stain pattern, scale, and pixel density remain constant.
<Subject 2> is the night Qizhen Lake environment established by <Picture 1>, including the curved stone shoreline, calm blue water, willow silhouettes, distant campus lights, mountain horizon, and fixed moonlit reflections.
<Subject 3> is the lakeside path environment established by <Picture 2>, including the wet stone pavement, black railing, stone posts, trees, one warm lamp, and distant lit campus buildings.
<Picture 1> is the exact first frame of [Shot 1] at 0.00 seconds.
<Picture 2> is the exact final frame of [Shot 2] at 12.40 seconds.

summary:
[keyframe completion + reference generation] The target video begins from <Picture 1>, shows a magnetic clasp and fishing line losing connection above <Subject 1>, then follows the same paper as wind pressure lifts it from <Subject 2> and carries it toward <Subject 3>, ending on <Picture 2>.

retention_analysis:
<Subject 1> (appears in [Shot 1], [Shot 2]): fully_preserved - the paper's irregular outline, warm ivory body, brown worn pixels, fixed dark-red eight-point seal mark, stain pattern, and hard-edged pixel style remain unchanged.
<Subject 2> (appears in [Shot 1]): fully_preserved - the shoreline, waterline, distant buildings, moon reflection, willow placement, horizon, and night palette remain fixed.
<Subject 3> (appears in [Shot 2]): fully_preserved - the railing, stone posts, pavement perspective, lamp position, foliage, distant buildings, and blue night lighting remain fixed.
<Picture 1> ([Shot 1] first frame): fully_preserved - framing, environment geometry, color palette, horizon, and water reflections are retained at 0.00 seconds.
<Picture 2> ([Shot 2] final frame): fully_preserved - the final camera angle, path geometry, railing, foliage, lighting, and empty exit composition are reached at 12.40 seconds.

detailed_description:
The target video uses crisp hard-edged pixel animation with limited color ramps in a fixed 16:9 frame. Pixel clusters remain visible, straight architecture stays stable, and the camera never rolls or changes lens distortion. No readable text, interface, title, sign, caption, watermark, or logo appears.
[Shot 1] The shot begins exactly from <Picture 1>. A static medium-wide view holds <Subject 2>. <Subject 1> lies at approximately x=484, y=396, just above the dark-blue water near the lower center. A pale fishing line enters from x=44, y=92 and runs diagonally to a small metal magnetic clasp near x=474, y=322. The line gradually straightens and trembles with small amplitude while the paper remains the same size and orientation. Fine cracks appear only on the clasp. At 00:02.100, the clasp separates into two small metal parts; the line recoils toward the upper-left and the paper drops by only a few pixels. A brief water ripple expands beneath the paper. The environment remains geometrically unchanged.
[Shot 2] At 00:04.200, a circular water-ripple aperture transitions to <Subject 3>. The camera becomes a stable lateral tracking shot at slow-to-normal speed. Wind pressure lifts <Subject 1> from the wet path while preserving the exact outline, dark-red eight-point seal mark, brown worn pixels, stain pattern, and low-light response shown by <Picture 3>, <Picture 4>, and <Picture 5>. The paper travels from approximately x=484, y=362 toward x=930, y=270. It rises above the railing height, bends once along its existing crease, rotates less than forty degrees, and settles back toward a flatter orientation. A small cool-blue wet highlight may cross the paper surface as scene lighting, but it never recolors the paper edge. Only three to five short broken cyan wind marks appear behind it; there is no solid trail. The railing, stone posts, lamp, trees, path perspective, distant buildings, and moonlit reflections stay fixed. The paper exits through the right edge. The shot reaches the exact environment framing and lighting of <Picture 2> at 12.40 seconds.
All visible people are absent. The paper has no face, limbs, eyes, mouth, or biological movement.

overall_soundscape:
N/A

non_diegetic_music:
N/A
~~~

## 6. 成片 02：夜间拱廊

上传顺序：

| 上传槽 | 文件 |
| --- | --- |
| <Picture 1> | ENV-ARCADE-A |
| <Picture 2> | ENV-ARCADE-B |
| <Picture 3> | PAPER-A |
| <Picture 4> | PAPER-B |
| <Picture 5> | PAPER-C |

~~~text
How the reference pictures align with the target video — Picture 1 (from Shot 1) aligns with the 0.00-second mark of the target video; Picture 2 (from Shot 1) aligns with the 12.00-second mark of the target video.

subject_definitions:
<Subject 1> is the same aged paper defined by <Picture 3>, <Picture 4>, and <Picture 5>, with an irregular warm ivory outline, fixed brown worn pixels and stains, one dark-red eight-point star-shaped seal mark near the upper-right area, and no readable writing. The three pictures fix its front view, folded view, and low-light color response.
<Subject 2> is the covered night arcade established by <Picture 1> and <Picture 2>, including the repeating gray stone columns, arched openings, dark garden on the left, warm windows on the right, evenly spaced ceiling lamps, and wet reflective pavement.
<Picture 1> is the exact first frame of [Shot 1] at 0.00 seconds.
<Picture 2> is the exact final frame of [Shot 1] at 12.00 seconds.

summary:
[keyframe completion + reference generation] The target video uses one continuous lateral tracking shot through <Subject 2>. Wind pressure carries <Subject 1> from the left edge to the right edge at head height while the arcade geometry and paper identity remain fully preserved.

retention_analysis:
<Subject 1> (appears in [Shot 1]): fully_preserved - outline, warm ivory body, brown worn pixels, stain pattern, dark-red eight-point seal mark, scale, and hard-edged pixel density remain constant.
<Subject 2> (appears in [Shot 1]): fully_preserved - column spacing, arches, lamps, garden, windows, pavement perspective, wet reflections, light direction, and blue night palette remain fixed.
<Picture 1> ([Shot 1] first frame): fully_preserved - the opening composition is used without changing the architecture.
<Picture 2> ([Shot 1] final frame): fully_preserved - the final composition and lighting are reached exactly after the paper leaves the right side.

detailed_description:
The target video uses crisp hard-edged pixel animation in a fixed 16:9 frame. The shot preserves intentional square pixels and limited color ramps. No readable text, interface, title, caption, sign, watermark, logo, route marker, or new person appears.
[Shot 1] The shot begins exactly from <Picture 1>. A stable tracking camera moves right at normal speed with the repeating arcade perspective held rigid. <Subject 1> enters from x=32, y=272 and moves toward x=930, y=272. It stays above the walking surface and near adult head height. The same irregular warm ivory outline, brown worn pixels, stain pattern, and fixed dark-red eight-point seal mark from <Picture 3>, <Picture 4>, and <Picture 5> remain visible whenever its front surface faces the camera. Cool-blue wet highlights come only from nearby scene lighting and do not change the paper's base colors.
During the first three seconds it maintains a shallow forward tilt and oscillates by less than ten pixels vertically. Between 00:03.000 and 00:06.300, one nearby column passes across the foreground and briefly occludes the paper without changing its trajectory. Between 00:06.500 and 00:07.600, a crosswind bends the existing crease and lifts the upper corner by a small amount; the paper rotates less than forty-five degrees, then returns to a flatter orientation. Between 00:07.600 and 00:10.800, the paper gains steady horizontal speed while staying within the same y=252 to y=290 band. The final second shows it reaching the far-right arcade opening and leaving the frame.
Only short broken cyan wind marks appear behind the paper. Each mark is thin, separated from the next mark, and disappears within a short distance. No continuous beam, solid ribbon, thick fog, spark explosion, or large particle field appears. Wet pavement reflections remain aligned to the ceiling lamps and warm windows. Columns remain vertical, arch widths do not change, and the right-side windows do not shift. Garden foliage moves by only a few pixels. The camera finishes on the exact framing, architecture, lighting, and empty corridor state of <Picture 2> at 12.00 seconds.

overall_soundscape:
N/A

non_diegetic_music:
N/A
~~~

## 7. 成片 03：玻璃入口

上传顺序：

| 上传槽 | 文件 |
| --- | --- |
| <Picture 1> | ENV-ENTRANCE-A |
| <Picture 2> | ENV-ENTRANCE-B |
| <Picture 3> | PAPER-A |
| <Picture 4> | STUDENT-IDLE |
| <Picture 5> | STUDENT-MOTION |

~~~text
How the reference pictures align with the target video — Picture 1 (from Shot 1) aligns with the 0.00-second mark of the target video; Picture 2 (from Shot 1) aligns with the 8.00-second mark of the target video.

subject_definitions:
<Subject 1> is the same small aged paper defined by <Picture 3>, with an irregular warm ivory outline, fixed brown worn pixels and stains, one dark-red eight-point star-shaped seal mark near the upper-right area, and no readable writing. Wetness is expressed only by scene-light highlights and reflections.
<Subject 2> is the teaching-building entrance established by <Picture 1> and <Picture 2>, including the centered glass doors, blank sign panel, symmetrical steps, blue-gray facade, warm lobby light, wet forecourt, tree, and planted borders.
<Subject 3> is the departing male university student defined by <Picture 4> and <Picture 5>, with the same short black hair, dark-green top, dark trousers, backpack, body proportions, and hard-edged pixel style. <Picture 4> is one identity pose. <Picture 5> shows three successive door-opening poses of the same student, not three students. The flat blue-gray isolation background in both pictures must not appear in the target video.
<Picture 1> is the exact first frame of [Shot 1] at 0.00 seconds.
<Picture 2> is the exact final frame of [Shot 1] at 8.00 seconds.

summary:
[keyframe completion + reference generation] The target video begins from <Picture 1>. <Subject 3> moves from the right side to the centered glass entrance, checks his phone, adjusts his bag, and pushes a door open. Wind pressure carries <Subject 1> through that opening. The shot ends on <Picture 2>.

retention_analysis:
<Subject 1> (appears in [Shot 1]): fully_preserved - paper shape, warm ivory body, brown worn pixels, stain pattern, fixed dark-red eight-point seal mark, and pixel density remain unchanged.
<Subject 2> (appears in [Shot 1]): fully_preserved - facade symmetry, steps, glass-door position, blank sign, planted borders, tree, pavement, lighting, and perspective remain fixed.
<Subject 3> (appears in [Shot 1]): fully_preserved - hair, clothing, backpack, proportions, and identity from <Picture 4> and <Picture 5> remain unchanged.
<Picture 1> ([Shot 1] first frame): fully_preserved - opening composition and lighting are used exactly.
<Picture 2> ([Shot 1] final frame): fully_preserved - final architecture and entrance composition are reached exactly.

detailed_description:
The target video uses crisp hard-edged pixel animation in a fixed 16:9 frame. Architecture remains stable and symmetrical. The blank sign panel remains blank. No readable text, interface, caption, title, watermark, logo, route marker, or extra person appears.
[Shot 1] The shot begins exactly from <Picture 1>. The camera holds a static medium-wide view of <Subject 2>. <Subject 3> enters from the right with his feet near x=836, y=482. He walks toward x=688 using a consistent four-phase pixel walk cycle. He stops without looking at the camera, lowers his gaze to his phone for about one second, closes his mouth, and keeps a neutral face. He adjusts one backpack strap, walks to x=548, and pushes one glass door inward using the three successive arm and body poses established by <Picture 5>. Render one student at a time; never place the three reference poses together in one frame. His hair, dark-green top, dark trousers, backpack, height, and body proportions stay identical to <Picture 4>. The flat blue-gray reference background is absent.
At the same time, <Subject 1> enters from the left near x=30, y=316. It moves toward the glass entrance on a shallow rising path and reaches approximately x=518, y=272. The paper keeps the exact irregular warm ivory outline, brown worn pixels, stain pattern, and dark-red eight-point seal mark shown in <Picture 3>. A small pressure change near the opened door lifts the paper by less than forty pixels and rotates it less than thirty degrees. The paper passes through the open doorway without touching the student or changing size. Any cool-blue wet highlight comes only from the entrance lighting. Three or fewer short cyan marks remain briefly behind it, with no continuous trail.
After opening the door, <Subject 3> steps through, moves toward x=514, and leaves the central doorway clear. He remains silent with his lips fully closed. The door moves on its existing hinge and does not stretch, split, or duplicate. Glass reflections follow the door angle. The steps, facade, tree, planted borders, wet pavement, warm interior light, and blank sign panel remain fixed. The final second lets the door return toward its resting position while the paper has already moved inside. The shot reaches the exact framing, geometry, lighting, and calm entrance state of <Picture 2> at 8.00 seconds.

overall_soundscape:
N/A

non_diegetic_music:
N/A
~~~

## 8. 扩展成片 04：门厅湿地

上传顺序：

| 上传槽 | 文件 |
| --- | --- |
| <Picture 1> | ENV-LOBBY-A |
| <Picture 2> | ENV-LOBBY-B |
| <Picture 3> | PAPER-A |
| <Picture 4> | CLEANER-IDLE |
| <Picture 5> | CLEANER-MOTION |

~~~text
How the reference pictures align with the target video — Picture 1 (from Shot 1) aligns with the 0.00-second mark of the target video; Picture 2 (from Shot 1) aligns with the 11.80-second mark of the target video.

subject_definitions:
<Subject 1> is the same small aged paper defined by <Picture 3>, with an irregular warm ivory outline, fixed brown worn pixels and stains, one dark-red eight-point star-shaped seal mark near the upper-right area, and no readable writing. Wetness is expressed only by scene-light highlights and floor reflections.
<Subject 2> is the bright teaching-building lobby established by <Picture 1> and <Picture 2>, including the centered glass entrance, left stair, elevator panels, ceiling grid, tiled floor, side corridors, planters, and wet floor reflections.
<Subject 3> is the female cleaner defined by <Picture 4> and <Picture 5>, with the same blue work cap, blue-gray uniform, pale gloves, practical shoes, body proportions, and hard-edged pixel style. <Picture 4> shows two identity frames of the same cleaner. <Picture 5> shows four successive cart-pushing poses of that same cleaner and one cart, not four cleaners or four carts. The flat blue-gray isolation background in both pictures must not appear in the target video.
<Picture 1> is the exact first frame of [Shot 1] at 0.00 seconds.
<Picture 2> is the exact final frame of [Shot 1] at 11.80 seconds.

summary:
[keyframe completion + reference generation] The target video begins from <Picture 1>. Wind pressure carries <Subject 1> from the entrance across <Subject 2> above head height. <Subject 3> pauses her mopping, notices the moving paper, then pushes her cart toward the right corridor. The shot ends on <Picture 2>.

retention_analysis:
<Subject 1> (appears in [Shot 1]): fully_preserved - the paper's outline, warm ivory body, brown worn pixels, stain pattern, dark-red eight-point seal mark, scale, and pixel density remain unchanged.
<Subject 2> (appears in [Shot 1]): fully_preserved - lobby geometry, stair, doors, elevator panels, planters, ceiling grid, tile lines, reflections, and lighting remain fixed.
<Subject 3> (appears in [Shot 1]): fully_preserved - cleaner identity, cap, uniform, gloves, proportions, cart, and motion reference remain unchanged.
<Picture 1> ([Shot 1] first frame): fully_preserved - the opening lobby composition is used exactly.
<Picture 2> ([Shot 1] final frame): fully_preserved - the final lobby composition and lighting are reached exactly.

detailed_description:
The target video uses crisp hard-edged pixel animation in a fixed 16:9 frame. The camera preserves straight verticals, the centered lobby axis, and the original tile perspective. No readable text, interface, caption, title, watermark, logo, route marker, or extra person appears.
[Shot 1] The shot begins exactly from <Picture 1>. A static wide view holds <Subject 2>. <Subject 3> stands on the left with her feet near x=286, y=478 and uses a restrained repeating mopping motion. Her blue work cap, blue-gray uniform, pale gloves, face, height, and body proportions stay identical to <Picture 4>. Render one cleaner and one cleaning cart; the four poses in <Picture 5> are successive motion stages and never appear together. The cleaning cart remains beside her and matches <Picture 5>. She looks at the floor, keeps her mouth naturally closed, and does not address the camera. The flat blue-gray reference background is absent.
After the entrance doors finish opening, <Subject 1> appears near x=472, y=374. Wind pressure moves it toward x=918, y=250. During the first third of the shot, the paper rises steadily above head height. During the middle third, it maintains that height, bends once along its existing crease, and rotates less than thirty-five degrees. During the final third, it moves toward the right corridor with only small vertical oscillation. Its irregular warm ivory outline, fixed brown worn pixels, stain pattern, and dark-red eight-point seal mark remain identical to <Picture 3>. A small cool-blue wet highlight may cross its surface because of the lobby lighting, but the edge stays warm brown. Four or fewer broken cyan wind marks appear behind it and disappear quickly. No solid trail, thick glow, fog ribbon, or large particle field appears.
At about 00:03.200, <Subject 3> stops mopping and turns her head toward the paper while keeping her lips closed. She grips the cart handle and begins pushing the cart right. Her feet remain aligned with y=478 while her x-position changes from approximately 286 toward 744. The cart wheels stay attached and roll on the tile surface without sliding. She follows at a stable distance and does not reach the paper. The paper remains above her head and never touches her, the cart, the stair, the elevator panels, or the planters.
Ceiling lights, glass reflections, tile lines, stair geometry, doors, elevator panels, planters, and distant exterior remain fixed. The paper leaves through the right edge and the cleaner slows near the right corridor. The shot reaches the exact framing, architecture, lighting, and final lobby composition of <Picture 2> at 11.80 seconds.

overall_soundscape:
N/A

non_diegetic_music:
N/A
~~~

## 9. 扩展成片 05：清楼与关灯

上传顺序：

| 上传槽 | 文件 |
| --- | --- |
| <Picture 1> | ENV-CLOSING-A |
| <Picture 2> | ENV-CLOSING-B |
| <Picture 3> | PAPER-C |
| <Picture 4> | GUARD-IDLE |
| <Picture 5> | CLEANER-LIGHT |

~~~text
How the reference pictures align with the target video — Picture 1 (from Shot 1) aligns with the 0.00-second mark of the target video; Picture 2 (from Shot 1) aligns with the 7.40-second mark of the target video.

subject_definitions:
<Subject 1> is the same small aged paper defined by <Picture 3>, with an irregular warm ivory outline, fixed brown worn pixels and stains, one dark-red eight-point star-shaped seal mark near the upper-right area, and no readable writing. Wetness is expressed only by scene-light highlights and floor reflections.
<Subject 2> is the upper teaching-building corridor established by <Picture 1> and <Picture 2>, including the centered long corridor, white tile floor, blue-gray walls, two side doors, upper balcony opening, clock frame, potted plants, and repeated ceiling lamps.
<Subject 3> is the male security guard defined by <Picture 4>, with the same short dark hair, navy uniform, utility belt, watch-checking pose, body proportions, and hard-edged pixel style. <Picture 4> shows two successive watch-checking poses of the same guard, not two guards.
<Subject 4> is the female cleaner defined by <Picture 5>, with the same blue work cap, blue-gray uniform, pale gloves, body proportions, and light-control action. <Picture 5> shows two successive switch-operating poses of the same cleaner, not two cleaners. The flat blue-gray isolation background in <Picture 4> and <Picture 5> must not appear in the target video.
<Picture 1> is the exact first frame of [Shot 1] at 0.00 seconds.
<Picture 2> is the exact final frame of [Shot 1] at 7.40 seconds.

summary:
[keyframe completion + reference generation] The target video begins from <Picture 1>. <Subject 3> enters from the right, checks his watch, directs a flashlight toward the floor, and uses his radio while <Subject 4> operates the light controls on the left. Wind pressure carries <Subject 1> through the corridor above head height. The lamps dim in sequence and the shot ends on <Picture 2>.

retention_analysis:
<Subject 1> (appears in [Shot 1]): fully_preserved - paper outline, warm ivory body, brown worn pixels, stain pattern, dark-red eight-point seal mark, scale, and pixel density remain unchanged.
<Subject 2> (appears in [Shot 1]): fully_preserved - corridor axis, tile grid, walls, doors, upper opening, clock frame, plants, ceiling lamps, and perspective remain fixed.
<Subject 3> (appears in [Shot 1]): fully_preserved - guard identity, uniform, belt, watch pose, body proportions, and pixel style remain unchanged.
<Subject 4> (appears in [Shot 1]): fully_preserved - cleaner identity, cap, uniform, gloves, proportions, and light-control action remain unchanged.
<Picture 1> ([Shot 1] first frame): fully_preserved - the opening corridor composition is used exactly.
<Picture 2> ([Shot 1] final frame): fully_preserved - the final corridor composition, dimmed lighting, and stable geometry are reached exactly.

detailed_description:
The target video uses crisp hard-edged pixel animation in a fixed 16:9 frame. The camera holds a centered static corridor view with stable verticals and fixed tile perspective. No readable text, interface, caption, title, watermark, logo, route marker, or extra person appears. The wall clock contains no readable time.
[Shot 1] The shot begins exactly from <Picture 1>. <Subject 3> enters from the right with his feet near x=888, y=490 and walks to approximately x=802, y=490. His navy uniform, short dark hair, utility belt, face, height, and proportions remain identical to <Picture 4>. Render one guard; the two reference poses are consecutive stages of one watch check. He stops, checks his wristwatch, lowers a flashlight toward the floor, and later raises a radio near his shoulder. He remains silent with his mouth naturally closed and does not look directly at the camera. The flat blue-gray reference background is absent.
<Subject 1> enters from the left near x=64, y=268 and moves toward x=690, y=268. It stays above head height, maintains a small irregular silhouette, and oscillates vertically by less than ten pixels. Its low-light warm ivory body, brown worn pixels, stain pattern, and fixed dark-red eight-point seal mark remain identical to <Picture 3>. The dim corridor may reduce brightness, but its hue and markings do not change. It rotates less than twenty-five degrees and does not change scale. Three or fewer broken cyan marks appear behind it and disappear quickly. The paper does not touch the guard, walls, doors, clock, lamps, or plants.
At approximately 00:05.000, <Subject 4> appears at the left-side light controls with her feet near x=150, y=476. Her blue work cap, blue-gray uniform, pale gloves, and body proportions remain identical to <Picture 5>. Render one cleaner; the two reference poses are consecutive stages of one switch operation. She operates the fixed control with one restrained arm motion while keeping her lips closed. The ceiling lamps then dim from the near-left area toward the deep corridor in a clear sequence. The light change affects brightness only; walls, doors, tile lines, clock frame, plants, balcony opening, and corridor perspective do not move. The frame remains readable in cool blue low light and never becomes fully black.
During the final second, <Subject 1> continues deeper into the corridor and the separate cyan wind wake reduces to one short mark. <Subject 3> remains near the right side with the radio lowered. <Subject 4> stays beside the light control. The shot reaches the exact composition, stable geometry, restrained dim-light state, and final framing of <Picture 2> at 7.40 seconds.

overall_soundscape:
N/A

non_diegetic_music:
N/A
~~~

## 10. 生成顺序

1. 先生成成片 01。
2. 逐帧检查纸条外形、暗红印记、湿边、湖岸透视和尾帧。
3. 通过后，从成片 01 导出一帧纸条正面最清楚的画面，作为后续成片的可选第六张主体参考；原有 <Picture 1> 至 <Picture 5> 编号不变。
4. 依次生成成片 02、03。
5. 根据实际交付素材确认后续大厅与熄灯走廊内容；当前第三个源文件已经包含这两个阶段。
6. 每段最多保留一个通过版本。不要在多个版本间拼接同一段内部动作。
7. 按用户确认的源文件顺序合并，统一画幅、帧率、像素格式和编码；移除全部 H3 音轨。
8. 按实际镜头切点更新 PROLOGUE_PHASES、PROLOGUE_BEATS、PROLOGUE_SUBTITLES 与 DEV 偏移。
9. 当前正式任务卡在 `43.834s` 由 React 层显示。任务卡不烘焙进视频。

## 11. 一致性验收

### 11.1 每段

- 首帧与 <Picture 1> 的建筑结构一致。
- 尾帧与 <Picture 2> 的建筑结构一致。
- 纸条暗红印记始终在同一角。
- 纸条湿边颜色和大小不跳变。
- 纸条无脸、无肢体、无生物表情。
- 青蓝痕迹为短线段，且数量受限。
- 门、栏杆、柱、楼梯、地砖和灯具没有移动或变形。
- 人物嘴巴闭合，无口型。
- 无字幕、无可读新文字、无 UI、无水印。
- 无额外人物。
- 无写实皮肤、无平滑 3D、无镜头滚转、无非均匀拉伸。

### 11.2 跨段

- 三个实际源文件中的纸条外形、暗红印记和湿边保持连续。
- 夜空、冷蓝环境和暖色室内灯的色温连续。
- 成片 02 尾部与成片 03 入口的运动方向均为从左向右。
- 第二个源文件的玻璃门尾段与第三个源文件的门厅开场形成入楼连续动作。
- 正式合并成片总视觉时长为 `43.833s`，共 `1052` 帧。
- 合并文件无 H3 音轨。

## 12. 建议生成配置

- 模型：MiniMax H3
- 分辨率：优先 1440p
- 比例：16:9
- 帧率：模型原生 24 FPS
- 单段时长：以实际通过的三个源文件为准
- 音频：请求完全静音；交付前仍强制移除生成音轨
- 水印：关闭
- 输出：每段独立 MP4，最终再使用高码率合并

## 13. 接入边界

- 视频加载或解码失败时保留当前 Canvas 2D 回放作为降级路径。
- 当前正式版接入一条 `43.833s` 合并视频，并在 `43834ms` 显示任务卡。
- `lobby` 与 `closing` 已由第三个实际源文件启用；对应环境音只通过本地音频时间线发出。
- 视频播放结束只通知表现层完成。
- ended 事件不能直接写 chapter4.prologueSeen。
- 玩家点击任务卡确认后，App 根级 `Chapter4PrologueRuntimeGate` 才向 `ChapterFourTemporalMazeController.resolve755Intent()` 提交 `complete_prologue_handoff`。
- 第四章入口固定为 `duan_yongping_temporal_maze / c4_a1_lobby / a1_2245_opening`。
- 原有第三章半证据门槛继续有效。
- Gate 在下层 runtime 挂载期间保持输入与可访问性阻断，并要求 Scene 回传同一 `requestId`、`a1_2245_opening` 与 `contractReady=true`。匹配后延迟 `80ms` 释放序幕层；20 秒超时只显示可重试反馈，不卸载 Phaser。
- 单文件视频只通过 Worker 分块解码与 MSE 追加；不得恢复整段 `data:` URL 或主线程巨型 Blob 构造。
- 旧 `c4-prologue-task-card` DEV ID 只参与兼容迁移，canonical 检查点为 `c4-755-opening`。正式已提交的 `opening_handoff` 刷新恢复从 `43834ms` 初始化，并在 A1 ready 后自动释放。

## 14. 官方依据

- H3 能力、时长、分辨率、参考素材说明和静默人物写法：<https://vrfi1sk8a0.feishu.cn/wiki/FIWjwgL33ipnkekzk30crmKUnIh>
- 全参考六段提示词结构及 <Subject N>、<Picture N>、<Video N>、<Audio N> 标签：<https://huggingface.co/MiniMaxAI/MiniMax-H3/blob/main/docs/VIDEO_PROMPT_WRITING_GUIDE_ref_en.md>
- 首尾帧对齐句式、声音场景和非叙事音乐字段：<https://huggingface.co/MiniMaxAI/MiniMax-H3/blob/main/docs/VIDEO_PROMPT_WRITING_GUIDE_base_en.md>
