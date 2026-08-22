# 《7:55》MiniMax H3 宣传 PV 生成方案

## 1. 交付结论

本方案将当前可运行剧情剪成一条 `35.0s` 宣传 PV：

```text
07:55 闹钟与异常签到
→ 四位数字调查与 0798 输入
→ 图书馆 022 号座位
→ 755 米自行车追踪
→ 剧院聚光灯
→ 启真湖皮划艇
→ 22:45 教学楼
→ 202 教室取回最后一分钟
→ 次日 07:55 完成双签到
→ 《7:55》片名
```

H3 负责生成三段无文字、无配乐的连续画面：`11s + 12s + 12s`。片名、字幕、配音、音乐和音效在剪辑层加入。全部场景锚点来自当前游戏实机截图，人物、纸条、自行车、皮划艇和两个路人 NPC 使用独立主体锚点。

当前章节四室外收束资产还未完成，因此本版 PV 停在教学楼 A1 的早晨双签到与 `07:55`，不展示未完成的室外结尾。

## 2. H3 生成参数

| 项目 | 设置 |
|---|---|
| 生成模式 | 全参考生成 |
| 片段数量 | 3 |
| 片段时长 | Clip 01 `11s`；Clip 02 `12s`；Clip 03 `12s` |
| 总时长 | `35s` |
| 比例 | `16:9` |
| 首选输出 | `1440p` |
| 失败回退 | `768p`，保持同一比例、时长和提示词 |
| 帧率 | `24 FPS` |
| 输入格式 | PNG、8-bit sRGB、无 Alpha |
| 输入尺寸 | `1024×1024`、`1920×1080`、`2048×1024` 或 `2048×2048` |
| 尺寸上限检查 | 本包最大边 `2048px`，低于 `5760×5760` |
| H3 音频 | 全部设为 `N/A`；宣传片音频由后期完成 |
| 文字处理 | H3 不生成标题、字幕、UI 文案或新标牌 |

标签必须保留英文形式：`<Picture 1>`、`<Subject 1>`。每次新建 H3 任务后重新核对上传槽位，避免页面自动排序造成引用错位。

在接口或日志中看到零起始引用名时，`ref_image_0` 对应页面里的 `<Picture 1>`，`ref_image_1` 对应 `<Picture 2>`，后续依次类推。提示词仍使用页面标签，不直接写 `ref_image_0`。

本轮未从飞书登录页重新读取官方正文；这里的全参考标签、六段式提示结构和参数范围沿用此前已核对的官方文档记录。正式批量生成前，应在 H3 当前页面复核时长、分辨率和图片槽数量。

## 3. 锚点目录与一致性规则

锚点根目录：

```text
docs/assets/minimax-h3-promo-pv-20260822/anchors/
```

### 3.1 场景截图锚点

| H3 场景 | 文件 | 剧情节点 | 控制重点 |
|---|---|---|---|
| `Picture A01` | `picture_01_alarm_0755_1920x1080.png` | 第一章闹钟 07:55 | 手机外框、闹钟数字、米白底色 |
| `Picture A02` | `picture_02_phone_code_hunt_1920x1080.png` | 首页调查 | 应用布局、天气卡、任务条、手机比例 |
| `Picture A03` | `picture_03_checkin_0798_1920x1080.png` | 0798 输入 | 数字键盘、四格输入框、签到失败弹窗 |
| `Picture A04` | `picture_04_library_022_1920x1080.png` | 图书馆 022 | 022 桌面、玩家位置、俯视地图、任务栏 |
| `Picture A05` | `picture_05_bike_chase_755_1920x1080.png` | 755 米骑行 | 三车道、后视骑手、低多边形校园、路边 NPC |
| `Picture A06` | `picture_06_theater_spotlight_1920x1080.png` | 剧院聚光灯 | 三个光圈、纸条、剧院界面、红黑背景 |
| `Picture A07` | `picture_07_qizhen_kayak_1920x1080.png` | 启真湖皮划艇 | 北向湖面、皮划艇、岸线、物品栏 |
| `Picture A08` | `picture_08_chapter4_2245_1920x1080.png` | 22:45 A1 大厅 | 夜间光照、前台、蓝色玻璃门、右侧纸条 |
| `Picture A09` | `picture_09_final_minute_202_1920x1080.png` | 202 最后一分钟 | 青色时间碎片、202 教室、玩家位置 |
| `Picture A10` | `picture_10_morning_checkin_0755_1920x1080.png` | 早晨双签到 | A1 日光、校园卡目标、考勤机目标 |

`Picture Axx` 是本方案中的资产编号。进入单条 H3 任务时，按照该任务的上传表重新映射为 `<Picture 1>`、`<Picture 2>` 等标签。

### 3.2 主体锚点

| 全局主体 | 文件 | 约束 |
|---|---|---|
| 玩家 | `subject_01_player_identity_2048x2048.png` | 同一名短黑发学生；蓝色外套、深色长裤、灰白鞋；只出现一个实例 |
| 纸条 | `subject_02_paper_identity_2048x1024.png` | 同一张米黄色污渍纸；多格只表示飞行阶段；只出现一张 |
| 自行车 | `subject_03_bicycle_1024x1024.png` | 蓝色校园自行车、前篮、黑色座椅与轮胎；不得变成电动车或摩托车 |
| 骑行动作 | `subject_04_rider_action_2048x1024.png` | 同一玩家的连续踩踏动作；不得生成多名骑手 |
| 皮划艇 | `subject_05_kayak_1024x1024.png` | 同一橙色艇体与乘员俯视造型；双帧只表示桨叶阶段 |
| 白衣 NPC | `subject_06_npc_white_hoodie_2048x1024.png` | 白色连帽衫、蓝色背包、手机；只能出现在人行道，最多一个 |
| 绿衣 NPC | `subject_07_npc_green_hoodie_2048x1024.png` | 绿色连帽衫、浅色背包、饮料；只能出现在人行道，最多一个 |

主体图使用 `#667386` 实色背景。所有多格参考均表示同一主体的连续姿态，不得被解释成多个角色或多个道具。未上传主体锚点的镜头只保留场景截图已有的小比例 NPC，不新增可辨识角色。

### 3.3 锚点选择原则

1. 场景结构、UI 和构图由 `<Picture N>` 控制。
2. 人物、纸条、车辆与 NPC 身份由 `<Subject N>` 控制。
3. H3 画面内的 UI 只能沿用锚点，不允许生成新数字、新按钮、新中文或新图标。
4. 每个片段首尾至少稳定 `8–12` 帧，便于剪辑硬切。
5. 复杂场景切换只在全屏遮挡、白光或黑帧时执行一次硬切。
6. 三段视频都应静音导出，后期统一使用游戏现有音频。

## 4. Clip 01：异常签到与 022 号座位

### 4.1 上传映射

| 上传顺序 | H3 标签 | 文件 |
|---|---|---|
| 1 | `<Picture 1>` | `picture_01_alarm_0755_1920x1080.png` |
| 2 | `<Picture 2>` | `picture_02_phone_code_hunt_1920x1080.png` |
| 3 | `<Picture 3>` | `picture_03_checkin_0798_1920x1080.png` |
| 4 | `<Picture 4>` | `picture_04_library_022_1920x1080.png` |
| 5 | `<Subject 1>` | `subject_01_player_identity_2048x2048.png` |
| 6 | `<Subject 2>` | `subject_02_paper_identity_2048x1024.png` |

### 4.2 逐秒分镜

| 时间 | 画面 | 转场与剪辑点 |
|---|---|---|
| `0.0–1.5s` | 完整保持 `<Picture 1>`，闹钟数字 `07:55` 可读。 | 首 12 帧稳定；慢速推进手机屏幕。 |
| `1.5–3.0s` | 手机屏幕占满画面。 | 屏幕完全占满时硬切；进入 `<Picture 2>`。 |
| `3.0–5.0s` | 保持首页应用布局与任务条，轻微向签到入口推进。 | 不生成触控手指；用短促白框遮挡切到 `<Picture 3>`。 |
| `5.0–7.0s` | 严格保持数字键盘、四格输入和失败弹窗。 | 只允许已有按钮产生一次亮度变化；禁止重写 `0798`。 |
| `7.0–8.0s` | 蓝色按钮区域扩展到全屏。 | 全屏蓝色遮挡中执行一次硬切。 |
| `8.0–11.0s` | 进入 `<Picture 4>`，镜头向 022 桌轻推，玩家走近桌边。 | 最后 12 帧停止移动，构图收束到实机锚点。 |

### 4.3 可直接粘贴的 H3 全参考提示词

```text
subject_definitions:
<Subject 1> is the only playable student. Preserve the same short black hair, blue jacket, dark trousers, gray-white shoes, body proportions, and pixel-art rendering shown in the subject sheet. Use exactly one instance. <Subject 2> is one stained beige paper sheet with one dark red stain. Every pose in its sheet is a successive deformation of the same single sheet, never multiple sheets.

summary:
Create one eleven-second promotional gameplay montage that begins from the exact 07:55 alarm composition in <Picture 1>, passes through the exact phone investigation layout in <Picture 2> and the exact 0798 check-in interface in <Picture 3>, and ends at the exact Library 022 gameplay composition in <Picture 4>. Preserve the real game interfaces as referenced images. Use clean concealed hard cuts when a phone screen, white interface panel, or blue button area completely covers the frame. End with the playable student approaching the 022 desk. Generate no dialogue, narration, captions, title, logo, new UI text, or additional numbers.

retention_analysis:
Preserve the centered 430-by-860 phone frame, black outer field, cream alarm screen, bell icon, existing 07:55 digits, existing blue button, and all spacing from <Picture 1>. Preserve the exact application grid, weather card, task bar, icon positions, phone proportions, and current text shapes from <Picture 2>. Preserve the exact four input boxes, numeric keypad, existing failure dialog, 0798 task context, and gray-blue interface hierarchy from <Picture 3>. Preserve the top-down library floor plan, 022 table, furniture, plants, counters, task bar, inventory dock, and player scale from <Picture 4>. Do not redraw, translate, replace, scramble, duplicate, or invent any readable UI text, digits, buttons, icons, notifications, signage, or HUD. Do not stretch the phone frame. Do not soften pixel edges. Do not introduce a hand, cursor, second phone, second player, second paper, motion blur, depth-of-field blur, photorealistic surfaces, cross-dissolves, or camera rotation.

detailed_description:
0.0-1.5 seconds: reproduce <Picture 1> exactly. Hold the first twelve frames. Push slowly toward the phone screen while the frame remains centered and undistorted. Keep the existing 07:55 digits fully readable. 1.5-3.0 seconds: continue until the phone screen completely fills the frame. Execute one hard cut only after the cream screen covers the full image. Emerge into <Picture 2>, preserving its exact application grid and task strip. 3.0-5.0 seconds: keep the phone interface static and use a subtle camera push toward the existing check-in entry. Do not create a finger, pointer, cursor, or new highlight. Let an existing pale interface region briefly cover the frame and perform one hard cut into <Picture 3>. 5.0-7.0 seconds: hold the exact check-in screen. Preserve every keypad position, input box, dialog boundary, and visible digit. Allow one short brightness pulse on the existing blue action area only. Do not animate or replace the digits. 7.0-8.0 seconds: expand the existing blue action area until it completely covers the frame, then perform one concealed hard cut. 8.0-10.2 seconds: emerge into the exact top-down library world in <Picture 4>. Preserve the same map, camera scale, task bar, and inventory dock. The single <Subject 1> walks two or three small steps toward the 022 table with a valid four-phase pixel walk cycle. Keep all furniture fixed. If <Subject 2> is visible on the table, use only one sheet. 10.2-11.0 seconds: stop the player at the referenced stand position and converge precisely to <Picture 4>. Hold the final twelve frames for a clean edit.

overall_soundscape:
N/A. Generate silent video. Post-production will use the current game alarm, digit, check-in, library, and interface sounds.

non_diegetic_music:
N/A. Do not generate music.
```

## 5. Clip 02：755 米、剧院与启真湖

### 5.1 上传映射

| 上传顺序 | H3 标签 | 文件 |
|---|---|---|
| 1 | `<Picture 1>` | `picture_05_bike_chase_755_1920x1080.png` |
| 2 | `<Picture 2>` | `picture_06_theater_spotlight_1920x1080.png` |
| 3 | `<Picture 3>` | `picture_07_qizhen_kayak_1920x1080.png` |
| 4 | `<Subject 1>` | `subject_01_player_identity_2048x2048.png` |
| 5 | `<Subject 2>` | `subject_02_paper_identity_2048x1024.png` |
| 6 | `<Subject 3>` | `subject_03_bicycle_1024x1024.png` |
| 7 | `<Subject 4>` | `subject_04_rider_action_2048x1024.png` |
| 8 | `<Subject 5>` | `subject_05_kayak_1024x1024.png` |
| 9 | `<Subject 6>` | `subject_06_npc_white_hoodie_2048x1024.png` |
| 10 | `<Subject 7>` | `subject_07_npc_green_hoodie_2048x1024.png` |

如当前 H3 页面主体槽数量不足，先移除 `<Subject 6>` 和 `<Subject 7>`，同时保留提示词中的“不得新增 NPC”和“已有路人留在人行道”规则。玩家、纸条、自行车、骑行动作与皮划艇不得移除。

### 5.2 逐秒分镜

| 时间 | 画面 | 转场与剪辑点 |
|---|---|---|
| `0.0–3.8s` | 从 `<Picture 1>` 开始，骑手在中间车道追踪前方纸条。 | 后视跟拍；路人只在人行道；最后由纸条遮满镜头。 |
| `3.8–4.2s` | 米黄色纸面全屏。 | 只执行一次硬切。 |
| `4.2–7.8s` | 进入 `<Picture 2>`，三个聚光灯依次亮起，纸条保持一张。 | 保留原界面；中央白光扩展到全屏。 |
| `7.8–8.2s` | 白光全屏。 | 白光硬切到湖面高光。 |
| `8.2–12.0s` | 进入 `<Picture 3>`，同一皮划艇向远处纸条划行。 | 北向俯视；最后 12 帧回到实机锚点构图。 |

### 5.3 可直接粘贴的 H3 全参考提示词

```text
subject_definitions:
<Subject 1> is the only playable student with short black hair, a blue jacket, dark trousers, and gray-white shoes. <Subject 2> is one stained beige paper sheet with one dark red stain; every pose represents the same single sheet. <Subject 3> is one blue campus bicycle with a front basket, black saddle, black tires, and the exact frame geometry in its reference. <Subject 4> shows successive pedaling stages of the same <Subject 1> riding the same <Subject 3>, not multiple riders. <Subject 5> is one orange top-down kayak with the same seated student and separate paddle phases; its two reference frames are the same kayak at successive moments. <Subject 6> is one white-hoodie campus pedestrian with a blue backpack and phone. <Subject 7> is one green-hoodie campus pedestrian with a light backpack and drink. Use at most one instance of each subject.

summary:
Create one twelve-second promotional gameplay montage from the exact 755-meter bicycle chase in <Picture 1>, through the exact theater spotlight puzzle in <Picture 2>, into the exact Qizhen Lake kayak scene in <Picture 3>. The same student pursues the same stained paper through all three sections. Use one paper occlusion to cut from the road to the theater and one white spotlight occlusion to cut from the theater to the lake. Preserve the referenced gameplay HUD and scene layouts without generating new text. Generate no dialogue, narration, captions, title, logo, new UI, or additional characters.

retention_analysis:
Preserve the three-lane road, centered rear camera, low-poly campus buildings, hard pixel edges, roadside trees, cones, road markings, bicycle scale, rider scale, task bar, and HUD from <Picture 1>. Preserve the three spotlight circles, paper position, red-black theater background, interaction panel geometry, task bar, and existing button shapes from <Picture 2>. Preserve the north-up water projection, shore geometry, lily pads, kayak scale, interaction mode, inventory dock, and distant paper position from <Picture 3>. Preserve exactly one player, one paper, one bicycle in the road section, and one kayak in the lake section. Multiple frames inside a subject sheet are motion phases. Keep <Subject 6> and <Subject 7> on sidewalks only and never duplicate them. Do not add cars, motorcycles, crowds, extra boats, extra paddles, extra spotlight rings, new obstacles, new HUD, readable generated text, speed lines, camera shake, soft pixel edges, motion blur, depth-of-field blur, photorealistic water, cross-dissolves, or mixed map projections.

detailed_description:
0.0-0.6 seconds: match <Picture 1> exactly and hold the first twelve frames. Keep the rider centered in the middle lane, the bicycle upright, and one paper ahead. 0.6-3.2 seconds: follow the same rider from behind. Use the pedaling phases in <Subject 4> as one continuous cycle. The front wheel stays mostly straight. The road and buildings advance at a stable game-like rate. If <Subject 6> or <Subject 7> appears, keep each on a sidewalk and at most once. The single <Subject 2> moves toward the camera while staying ahead of the rider. 3.2-4.2 seconds: let the same stained paper cross the lens until beige paper texture and the single dark red stain fully cover the frame. Perform one concealed hard cut only during full occlusion. 4.2-4.8 seconds: emerge into <Picture 2> and hold the exact theater layout. Use only one paper. 4.8-7.4 seconds: light the three existing spotlight circles in sequence from left to center to right, without adding rings or changing the panel. The paper shifts slightly only inside its existing interaction lane. Keep every existing UI shape fixed and do not redraw text. 7.4-8.2 seconds: expand the central white spotlight until it completely covers the frame, then perform one hard cut while the screen is white. 8.2-8.8 seconds: emerge from a matching white reflection into <Picture 3>. Preserve the exact north-up lake projection and shore. 8.8-11.2 seconds: the single <Subject 5> advances with a restrained alternating left-right paddle cycle. Keep the orange hull and seated blue-jacket student intact. The same paper remains far ahead on the water. No bank collision, capsize, turning spin, or chase failure occurs. 11.2-12.0 seconds: converge precisely to <Picture 3> and hold the last twelve frames.

overall_soundscape:
N/A. Generate silent video. Post-production will use the current bicycle-lane, spotlight-hit, water-reflection, paddle, and interface sounds.

non_diegetic_music:
N/A. Do not generate music.
```

## 6. Clip 03：22:45、最后一分钟与 07:55

### 6.1 上传映射

| 上传顺序 | H3 标签 | 文件 |
|---|---|---|
| 1 | `<Picture 1>` | `picture_08_chapter4_2245_1920x1080.png` |
| 2 | `<Picture 2>` | `picture_09_final_minute_202_1920x1080.png` |
| 3 | `<Picture 3>` | `picture_10_morning_checkin_0755_1920x1080.png` |
| 4 | `<Picture 4>` | `picture_01_alarm_0755_1920x1080.png` |
| 5 | `<Subject 1>` | `subject_01_player_identity_2048x2048.png` |
| 6 | `<Subject 2>` | `subject_02_paper_identity_2048x1024.png` |

### 6.2 逐秒分镜

| 时间 | 画面 | 转场与剪辑点 |
|---|---|---|
| `0.0–3.0s` | 从 `<Picture 1>` 开始；玩家在 22:45 的 A1 大厅看见右侧纸条。 | 夜间俯视；纸条移动到镜头前并遮满画面。 |
| `3.0–3.4s` | 纸面转为黑帧。 | 硬切到 202 教室。 |
| `3.4–7.2s` | 进入 `<Picture 2>`；玩家走到青色时间碎片前，碎片亮度提高。 | 青色碎片占满画面后切换。 |
| `7.2–10.0s` | 进入 `<Picture 3>`；玩家依次面向校园卡与考勤机。 | 只突出已有目标，不生成成功文字。 |
| `10.0–12.0s` | 硬切到 `<Picture 4>`，完整保持 `07:55`。 | 最后 12 帧稳定；片名在后期覆盖。 |

### 6.3 可直接粘贴的 H3 全参考提示词

```text
subject_definitions:
<Subject 1> is the only playable student. Preserve the same short black hair, blue jacket, dark trousers, gray-white shoes, body proportions, and pixel-art identity in every landscape scene. Use exactly one instance. <Subject 2> is one stained beige paper sheet with one dark red stain. Every pose in its subject sheet is a successive deformation of the same single paper.

summary:
Create one twelve-second promotional gameplay montage from the exact 22:45 A1 lobby in <Picture 1>, through the exact 202 classroom final-minute scene in <Picture 2>, into the exact morning dual-check-in lobby in <Picture 3>, and finish on the exact 07:55 alarm screen in <Picture 4>. The student follows one stained paper, reaches the cyan final-minute fragment, returns to the bright lobby, performs the two existing check-in target motions, and reaches 07:55. Use concealed hard cuts during full paper, black, cyan, or phone-screen coverage. Preserve every referenced map, UI, and digit. Generate no exterior ending, dialogue, narration, captions, title, logo, success message, new interface text, or additional character.

retention_analysis:
Preserve the dark A1 lobby, reception counter, doors, floor tiles, light pools, paper position, task bar, and inventory dock from <Picture 1>. Preserve the 202 classroom layout, rows of seats, dark corridor, cyan final-minute fragment, player scale, task bar, and inventory dock from <Picture 2>. Preserve the bright A1 morning lighting, reception counter, campus-card target, attendance-device target, doors, task bar, and inventory dock from <Picture 3>. Preserve the centered 430-by-860 phone, black outer field, cream background, bell icon, existing 07:55 digits, and blue button from <Picture 4>. Use exactly one player and one paper. Do not duplicate the cyan fragment, player, paper, campus card, attendance device, doors, chairs, counters, HUD, or phone. Do not invent readable text, numbers, check marks, timestamps, confirmation panels, buildings, outdoor scenery, other students, motion blur, depth-of-field blur, soft pixel edges, photorealistic materials, cross-dissolves, or camera rotation.

detailed_description:
0.0-0.6 seconds: reproduce <Picture 1> exactly and hold the first twelve frames. Keep the night lighting, reception counter, doors, and player position fixed. 0.6-2.6 seconds: the single <Subject 1> takes two or three controlled steps toward the single <Subject 2> on the right side. The paper lifts slightly and moves toward the lens. Keep the map and HUD unchanged. 2.6-3.4 seconds: the same paper covers the full frame, its beige surface darkens into a brief full black frame, and one concealed hard cut occurs. 3.4-4.0 seconds: emerge into <Picture 2> with the exact 202 classroom composition. 4.0-6.6 seconds: the student approaches the existing cyan final-minute fragment. The fragment brightens without changing its shape or creating a duplicate. Keep all seats and walls fixed. 6.6-7.2 seconds: let the cyan light fill the full frame and perform one hard cut. 7.2-7.8 seconds: emerge into the bright lobby of <Picture 3>. Preserve the exact morning lighting and target positions. 7.8-9.0 seconds: the student turns toward the existing campus-card target and makes one short contact motion. 9.0-10.0 seconds: the same student turns toward the existing attendance-device target and makes one short contact motion. Do not generate confirmation text, a check mark, a new screen, or a new number. 10.0-10.4 seconds: use one clean hard cut through a pale full-screen field. 10.4-12.0 seconds: reproduce <Picture 4> exactly. Keep the existing 07:55 digits fully readable and unchanged. Hold the last twelve frames so the editor can add the final title card over the stable screenshot.

overall_soundscape:
N/A. Generate silent video. Post-production will use the current clock, paper, time-fragment, card-scan, attendance, and interface sounds.

non_diegetic_music:
N/A. Do not generate music.
```

## 7. 35 秒正式剪辑时间线

| 成片时间 | 素材 | 画面任务 | 声音与字幕 |
|---|---|---|---|
| `00.0–02.0` | Clip 01 | 07:55 闹钟 | 闹钟振动；字幕：`07:55，一次签到失败。` |
| `02.0–05.0` | Clip 01 | 首页调查与四位数字 | 数字散落与输入音；字幕：`四个数字留下了异常记录。` |
| `05.0–07.0` | Clip 01 | 0798 输入 | 输入 tick；保留界面文字，不加重复说明 |
| `07.0–11.0` | Clip 01 | 图书馆 022 | 背包警示音；字幕：`线索从 022 号座位继续。` |
| `11.0–15.0` | Clip 02 | 755 米骑行 | 骑行车道音；字幕：`追踪距离：755 米。` |
| `15.0–19.0` | Clip 02 | 剧院聚光灯 | 聚光灯命中音；字幕：`剧院确认了纸条的运动路径。` |
| `19.0–23.0` | Clip 02 | 启真湖皮划艇 | 水面反光音；字幕：`路径进入启真湖。` |
| `23.0–26.0` | Clip 03 | 22:45 A1 大厅 | 音乐压低；字幕：`22:45，段永平教学楼 A1。` |
| `26.0–29.5` | Clip 03 | 202 最后一分钟 | 青色时间音；字幕：`202 教室保留着最后一分钟。` |
| `29.5–33.0` | Clip 03 | 早晨双签到 | 校园卡与考勤提示音；字幕：`取回一分钟，完成双签到。` |
| `33.0–35.0` | Clip 03 + 后期片名 | 07:55 与片名 | 时钟音；叠加 `《7:55》` 与 `校园解谜 · 多端交互 · 像素 RPG` |

字幕应由剪辑软件生成，位置统一在画面底部安全区。游戏自带任务条、按钮和数字需要保持可读，字幕不得覆盖这些元素。

## 8. 配音文案

建议使用一名中性青年声线，语速约 `4.0–4.3` 字/秒，语气克制，停顿清晰。配音只覆盖关键剧情，玩法画面留出音效空间。

```text
07:55，一次签到失败，留下了一条异常记录。

线索从 022 号座位开始，经过图书馆、食堂、剧场和启真湖。

距离、光线、倒影和校园规则，持续改变追踪路径。

22:45，教学楼的时钟仍显示 07:54。最后一分钟位于 202。

取回一分钟，完成双签到，时间记录恢复为 7:55。
```

如果不录制配音，保留第 7 节的短字幕即可。配音和字幕同时存在时，字幕按配音逐句同步，不再增加另一组说明文字。

## 9. 后期音频方案

### 9.1 连续音乐底

使用：

```text
src/assets/audio/chapter4/prologue/music_ch4_prologue_night_pursuit.mp3
```

截取前 `35s`，起始电平约 `-18 LUFS`，配音出现时再压低 `3–5 dB`。整条 PV 使用同一音乐底，保持连续节奏。

### 9.2 节点音效

| 时间 | 音效文件 | 建议峰值 |
|---|---|---|
| `00.0s` | `src/assets/audio/sfx/05_p00_alarm_phone_vibrate_loop.mp3` | `-8 dBFS` |
| `02.0s` | `src/assets/audio/sfx/09_p14_friend_chat_digits_scatter_noise.mp3` | `-9 dBFS` |
| `04.5s` | `src/assets/audio/sfx/25_p11_checkin_digit_input_tick.mp3` | `-10 dBFS` |
| `08.5s` | `src/assets/audio/library-finals/sfx/fx_backpack_alert_v2.mp3` | `-8 dBFS` |
| `11.0s` | `src/assets/audio/chapter3-canteen/sfx/fx_canteen_chase_lane.mp3` | `-8 dBFS` |
| `15.0s` | `src/assets/audio/chapter3-theater/sfx/fx_theater_spotlight_hit.mp3` | `-8 dBFS` |
| `19.0s` | `src/assets/audio/chapter3-qizhen/sfx/fx_qizhen_reflection_shimmer.mp3` | `-8 dBFS` |
| `33.0s` | `src/assets/audio/chapter4/prologue/sfx_ch4_clock_chime.mp3` | `-7 dBFS` |

交付包中的 `seven_fifty_five_promo_pv_animatic_35s.mp4` 已按以上时间点混合游戏音乐与音效。该文件用于判断节奏和镜头占比，画面仍是实机截图硬切预演。

## 10. H3 生成与返工顺序

1. 先生成 Clip 02 的 `768p` 预览，因为它包含角色、车辆、NPC、剧院 UI 和皮划艇，风险最高。
2. Clip 02 通过主体数量与场景切换检查后，再生成 Clip 01 的 `768p` 预览。
3. Clip 03 最后生成，重点核对夜间与早晨光照、202 时间碎片和 `07:55` 数字。
4. 三段低清预览全部通过后，使用原提示词和原上传顺序生成 `1440p` 正式版。
5. 返工时一次只改一类变量：主体锚点、场景锚点、动作描述或切点。不要同时替换多项。
6. H3 若重写 UI，缩短该段动作并加强 `preserve exact referenced interface`，仍失败时将该处改为剪辑软件中的实机截图停帧。
7. H3 若生成多个 NPC，移除两个 NPC 主体图，并保留“不得新增 NPC”与“已有路人最多一次”的约束。
8. H3 若生成多辆车、多张纸或多个皮划艇，保留对应主体图并强化 `exactly one` 与 `successive motion stages`。

## 11. 模型输出验收清单

### 11.1 全局

- 输出为 `16:9`，无拉伸、无额外黑边、无裁掉关键 UI。
- 三段首尾各有至少 `8–12` 个稳定帧。
- 像素边缘清晰，没有写实材质、景深、运动模糊或柔化。
- 没有生成新标题、新字幕、新按钮、新数字、新中文、新图标或新标牌。
- 玩家服装、纸条污渍、自行车、皮划艇和 NPC 身份保持一致。
- 多格主体锚点只产生一个主体实例。
- 画面没有多余肢体、重复车轮、重复桨叶、重复纸条、重复 NPC 或重复建筑。
- 场景之间只在规定遮挡或全屏色块中发生硬切。
- H3 输出无配乐、无对白、无随机音效。

### 11.2 Clip 01

- 开始画面保留原始 `07:55`，数字无变化。
- 手机比例始终为 `430:860`，无横向拉伸。
- 首页、签到和数字键盘布局与截图相符。
- `0798` 不被重写、不增减位数。
- 结尾停在图书馆 022 桌面，玩家只有一个。

### 11.3 Clip 02

- 骑行镜头中只有一名骑手、一辆蓝色自行车和一张纸。
- 白衣与绿衣 NPC 只在人行道，每人最多一个。
- 剧院只保留三个已有光圈，纸条只出现一张。
- 湖面保持北向俯视投影，不混入自行车镜头透视。
- 皮划艇保持一条，划桨动作不会产生额外桨叶或翻船。

### 11.4 Clip 03

- 夜间 A1 与早晨 A1 的布局一致，光照阶段明确。
- 202 教室只出现一个青色时间碎片。
- 双签到动作只指向已有校园卡与考勤机目标。
- 不生成室外结尾、不生成额外教学楼场景。
- 结尾完整保留实机 `07:55`，片名由后期叠加。

当前 H3 实际生成、播放与模型一致性验收次数为 `0`。本轮完成的是可上传锚点、提示词、剪辑结构与实机截图节奏预演。第一轮 H3 预览通过后，模型一致性验证计数才记为 `1`。

## 12. 文件交付

```text
docs/assets/minimax-h3-promo-pv-20260822/
├── README.md
├── manifest.json
├── anchors/
│   ├── picture_01_alarm_0755_1920x1080.png
│   ├── ...
│   ├── picture_10_morning_checkin_0755_1920x1080.png
│   ├── subject_01_player_identity_2048x2048.png
│   ├── ...
│   └── subject_07_npc_green_hoodie_2048x1024.png
├── source-captures/
│   └── 当前实机原始截图副本
└── storyboards/
    ├── pv_anchor_contact_sheet_1920x1080.png
    ├── storyboard_clip01_signin_anomaly.png
    ├── storyboard_clip02_campus_pursuit.png
    ├── storyboard_clip03_last_minute.png
    ├── pv_end_card_1920x1080.png
    ├── pv_edit_timeline.csv
    └── seven_fifty_five_promo_pv_animatic_35s.mp4
```

## 13. 交付边界

本次没有修改游戏运行时代码，也没有把 H3 视频接入游戏。宣传 PV 可独立生成、剪辑和发布，不改变 `GameState`、控制器、任务条件、存档、碰撞或章节推进。正式生成视频返回后，需要另做一次逐帧验收与最终剪辑导出。
