# 章节与地图衔接 CG：提示词与关键帧规范

## 目标

首批生成四组 `2×2` 关键帧板：

1. 寝室 → 基础图书馆
2. 图书馆 `022` → 东区大食堂
3. 东区大食堂 → 校园剧场
4. 校园剧场 → 湖畔调查区

生成图只承担表现。TypeScript 控制器继续拥有剧情阶段、任务、存档、道具与场景路由。A、B、C 每张分镜板包含两段相互独立的短过渡：`frame_01 → frame_02` 表示离开室内并回到可行走的 IonicJian 俯视校园地图，`frame_03 → frame_04` 表示玩家自行走到目标建筑后进入室内。`frame_02` 与 `frame_03` 之间不播放自动旅行动画。D 是唯一连续的伪 `2.5D` 地图转场。

## 统一视觉母版

- 输出一张无文字的 `2×2` 电影分镜板，四格大小完全一致，每格均为 `16:9`，格间使用纯黑窄分隔线。
- 高精度像素绘本质感，保持现有 RPG 底图的像素密度、夏日校园配色和光照方向。A、B、C 的室外帧保持 IonicJian 源图的严格北向朝上俯视视角；D 保持环湖伪 `2.5D` 侧视角。
- 林星宇固定为黑色短发男大学生，蓝灰色外套、深色长裤、白色运动鞋。四格中的脸型、发型、衣服、身高和像素比例一致。
- 湿纸固定为边缘浸湿的不规则白色纸片，带低饱和青蓝水痕；不添加眼睛、嘴、手脚或拟人表情。
- 摄像机稳定，门框、窗框和建筑线条保持连续。D 中人物靠近镜头时等比放大，远离时等比缩小；A、B、C 的人物比例由俯视瓦片场景的固定显示尺寸决定。
- 画面内不出现 UI、字幕、章节标题、地点名、方向文字、水印或后续谜题答案。

## 可行走俯视校园地图边界

- 寝室→图书馆、图书馆→食堂、食堂→剧场的中段都由 `campus_bootstrap` 俯视场景承担，玩家保持移动控制。
- 正式室外帧来自 IonicJian 提交的 `src/assets/rpg/campus/zijingang_campus_plate.png` 实际运行画面，地标和入口取自 `src/data/maps/zijingang-campus-runtime.json`。
- 旧 `src/data/maps/zijingang-campus.json` 瓦片方案不用于 A、B、C 的运行时转场，也不用于自动导航动画。
- A、B、C 只使用两类短过渡：`室内门边 → 黑场 120–180ms → 建筑外可行走出生点`，以及 `建筑外交互点 → 黑场 120–180ms → 室内入口`。
- 两段短过渡之间不显示路线光点、人物小图标、终点光圈或自动平移镜头。

## 统一负面提示词

```text
no text, no captions, no UI, no HUD, no watermark, no logos, no location labels,
no puzzle answer, no extra people, no photorealistic face, no anime illustration,
no smooth 3D render, no painterly brush strokes, no neon cyberpunk lighting,
no perspective mismatch, no top-down/side-view mixing inside one panel,
no stretched character, no costume change, no duplicated limbs, no floating props,
no broken doors, no misaligned roads, no blurry low-resolution output,
no speech bubbles, no numbered panels, no decorative border beyond thin black gutters
```

## A. 寝室 → 基础图书馆

### 四帧内容

1. 寝室出口：林星宇走到寝室下方门内，室内桌椅和床铺保持原布局。
2. 宿舍楼外：黑场退去，林星宇站在俯视瓦片地图的宿舍出生点，开始由玩家控制。
3. 图书馆门外：这是玩家完成地图行走后的独立起始帧，林星宇面向基础图书馆入口热区。
4. 图书馆入口：黑场退去，林星宇站在玻璃闸机内侧的安全出生点。

### 生成提示词

```text
Create one clean 2-by-2 transition storyboard sheet for a detailed pixel-art campus game. Use the supplied dorm interior, the real running IonicJian north-up campus screenshots, the library entrance and the player sprite as strict references. The sheet contains two separate doorway transitions. Panels 1 and 2 are one transition. Panels 3 and 4 are another transition after interactive gameplay. Do not portray or imply automatic travel between panels 2 and 3.

Lin Xingyu is the same Chinese male university student in every panel: short black hair, blue-gray jacket, dark trousers and white sneakers. Keep his face, clothing, height and pixel proportions identical.

Panel 1: inside the supplied dorm, Lin reaches the bottom doorway; preserve the exact two bunk-bed groups on the left, four desks on the right and clear center aisle. Panel 2: after a brief full-black occlusion, show the actual IonicJian north-up campus view immediately outside the dorm, with Lin standing at the safe playable spawn and no route line or marker. Panel 3: a separate later moment after player-controlled walking, using the same actual north-up campus view at the Basic Library entrance; Lin faces the measured entrance hotspot. Panel 4: after a brief full-black occlusion, show Lin at the safe spawn just inside the supplied library glass turnstiles.

High-detail 32-bit pixel art, strict north-up orientation in panels 2 and 3, exact tile and building geometry, thin pure-black gutters, no labels or panel numbers. Do not redesign the campus map and do not add a travel montage. Apply the shared negative prompt.
```

## B. 图书馆 022 → 东区大食堂

### 四帧内容

1. 图书馆出口：林星宇站在玻璃闸机内侧，湿纸从闸机上方掠过，两三枚青蓝水痕指向门外。
2. 图书馆门外：黑场退去，林星宇站在俯视瓦片地图的图书馆门前，湿纸已离开画面，玩家恢复控制。
3. 食堂门外：这是玩家完成地图行走后的独立起始帧，林星宇站在东区大食堂入口热区。
4. 食堂入口：黑场退去，湿纸从门边进入室内，林星宇出现在食堂入口的可站立位置。

### 生成提示词

```text
Create one clean 2-by-2 transition storyboard sheet for a pixel-art campus mystery game. Use the supplied library interior, the real running IonicJian north-up campus screenshots, the canteen entrance and the canteen interior as strict references. The sheet contains two separate doorway transitions. Panels 1 and 2 form the library exit. Panels 3 and 4 form the canteen entry after interactive player-controlled walking. Do not portray or imply automatic travel between panels 2 and 3.

The same student appears in every panel: Lin Xingyu, a Chinese male university student with short black hair, a blue-gray jacket, dark trousers and white sneakers. Keep exactly the same face, hairstyle, clothing, proportions and pixel scale. A small irregular wet white paper with blue-gray damp edges moves close to the ground and leaves sparse cyan droplets.

Panel 1: inside the library at the glass turnstiles, Lin stands behind the gate while the wet paper darts toward the exit and leaves only two or three cyan droplets. Panel 2: after a brief full-black occlusion, show the actual IonicJian north-up campus view immediately outside the Basic Library, with Lin at the safe playable spawn; the paper is already off-screen and there is no route marker. Panel 3: a separate later moment after player-controlled walking, using the same actual north-up campus view at the east-campus canteen entrance; Lin stands inside the measured entrance hotspot. Panel 4: after a brief full-black occlusion, show the canteen interior entrance, the wet paper slipping farther into the hall and Lin at the safe stand position.

High-detail 32-bit pixel art, exact tile and building geometry in panels 2 and 3, consistent interior pixel density, thin pure-black gutters, no labels or panel numbers. Do not add a route trace, destination pulse or travel montage. Apply the shared negative prompt.
```

## C. 东区大食堂 → 校园剧场

### 四帧内容

1. 食堂出口：纸条从东南出口窜出，林星宇在门内追到出口，餐盘车和窗口留在后方。
2. 食堂门外：圆形黑场退去，林星宇出现在俯视瓦片地图的食堂门前，可在真实场景中接续骑行追逐。
3. 剧场门外：这是玩家完成 755 米追逐后的独立起始帧，林星宇停在俯视瓦片地图的剧场入口热区。
4. 剧场入口：黑场退去，纸条从门缝进入，林星宇出现在剧场大堂的安全出生点。

### 生成提示词

```text
Create one clean 2-by-2 transition storyboard sheet for the same pixel-art campus mystery game. Use the supplied canteen interior, the real running IonicJian north-up campus screenshots, the theater entrance, the theater interior and the player sprite as strict references. The sheet contains two separate doorway transitions. Panels 1 and 2 form the canteen exit. Panels 3 and 4 form the theater entry after the interactive 755-meter chase. Do not portray or imply automatic travel between panels 2 and 3.

Lin Xingyu remains identical in every panel: short black hair, blue-gray jacket, dark trousers, white sneakers. He rides a simple shared bicycle with correctly aligned wheels and pedals. The same wet white paper travels ahead and leaves a sparse cyan trail.

Panel 1: the paper bursts through the canteen's southeast exit while Lin reaches the doorway; tray carts and numbered food windows remain behind him. Panel 2: a circular full-black occlusion reveals the actual IonicJian north-up campus view immediately outside the canteen, with Lin at the playable chase start and no route line or marker. Panel 3: a separate later moment after the completed chase, using the same actual north-up campus view at the round theater entrance; Lin has stopped inside the measured entrance hotspot. Panel 4: after a brief full-black occlusion, show the theater lobby safe spawn while the wet paper disappears deeper through the doorway.

Exact tile and building geometry in panels 2 and 3, consistent interior pixel density, thin pure-black gutters, no speed text, route trace, destination pulse, labels or panel numbers. Apply the shared negative prompt.
```

## D. 校园剧场 → 湖畔调查区

这组是 `campus_qizhen_loop` 专用的连续伪 `2.5D` 转场，可以表现离开剧场后的完整追踪过程。

### 四帧内容

1. 剧场舞台：最后一束追光熄灭前照到替身纸条，真正湿纸沿舞台侧边逃向出口。
2. 黑场桥帧：红色幕布合拢形成黑场，中央只剩逐渐缩小的圆形追光与湿纸青蓝残影。
3. 剧场外追逐：幕布黑场横向退去，连接到剧场外夏日道路；林星宇沿人行道追赶湿纸。
4. 湖畔停点：水面、柳树与前景人行道出现；湿纸在水光旁消失，林星宇停下观察，画面不显示地点名称。

### 生成提示词

```text
Create one clean 2-by-2 cinematic storyboard sheet for the same pixel-art campus mystery game. The panels form a continuous transition from a red-curtained theater stage to an unlabelled lakeside investigation area. Use the supplied theater interior, theater exterior, lakeside frame and player sprite as strict references. Preserve the supplied pixel density, architecture, daylight direction and character proportions.

Lin Xingyu remains the same short-haired male student in a blue-gray jacket, dark trousers and white sneakers. The wet paper is a small irregular white sheet with damp blue-gray edges and a sparse cyan trace.

Panel 1: on the theater stage, the last warm spotlight catches a decoy paper while the real wet paper escapes along the stage wing; Lin turns toward the exit. Panel 2: a mostly black transition frame formed by closing red curtains; one shrinking circular spotlight and a cyan paper afterimage remain in the center. Panel 3: the curtain-black recedes sideways into the sunny round-theater exterior; Lin runs right on the foreground walkway while the wet paper leads him by one body length. Panel 4: an unlabelled waterfront with willow trees, reflected daylight and a foreground pavement; the paper disappears near the water glint and Lin stops to investigate.

Stable lateral camera, matched horizon and foot line, thin pure-black gutters, no location name, no puzzle solution, no labels or panel numbers. Apply the shared negative prompt.
```

## 裁帧与运行时连接

- 每张板按四个等宽等高象限裁为 `frame_01` 至 `frame_04`。
- A、B、C 的 `frame_02` 和 `frame_03` 必须来自实际运行的 `campus_bootstrap` 俯视瓦片场景截帧。生成模型可以用这些截帧作为严格首尾帧参考，不重画建筑与道路。
- A、B、C 各自播放两次短动画：离开建筑时播放 `frame_01 → frame_02`；玩家在地图上抵达目标热区后播放 `frame_03 → frame_04`。
- A、B、C 的 `frame_02 → frame_03` 不存在播放关系。这个区间完全由玩家在可行走瓦片地图上完成。
- D 在 `campus_qizhen_loop` 中按 `frame_01 → frame_02 → frame_03 → frame_04` 连续播放，与现有剧场后湿纸追踪状态同步。
- 单帧统一到 `1920×1080`，使用最近邻缩放保留像素边缘。
- A、B、C 的每次短过渡使用 `120–180ms` 全黑遮罩；D 可以使用 `160–320ms` 遮罩、横向运镜和透明度交叉。
- `prefers-reduced-motion` 下，A、B、C 只播放全黑 `120ms` 后显示对应的门外或门内帧；D 只播放 `frame_01 → 全黑 120ms → frame_04`。
- 动画结束只向控制器提交“表现已完成”；场景推进由控制器当前状态再次确认。
