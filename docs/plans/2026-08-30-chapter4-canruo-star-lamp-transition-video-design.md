# 第四章“灿若星辰灯”像素转写实衔接视频脚本

## 1. 设计结论

采用用户确认的 C 方案：视频从第四章 A1 清晨门厅的像素画面开始，在主角穿过玻璃门时完成一次受遮挡的硬切，楼外部分转为写实电影镜头，最后回到现有正式“灿若星辰灯”素材的黑场起点。

完整顺序固定为：

```text
校园卡与签到纸完成双重验证
→ C4V-01 像素门厅：设备确认、照明恢复、主角走向出口
→ C4V-02 玻璃门：像素视角降低、玻璃反光遮挡、写实视角接续
→ C4V-03 楼外清晨：主角出门、镜头转向灯柱、未点亮灯体、纯黑保持
→ 现有 6200ms 灿若星辰灯正式分层点亮序列
→ 现有一次性 runtime proof 验证通过
→ 第四章完成并返回手机主页
```

本视频只承担演出。第四章阶段、签到事实、配电锁定、最后一分钟、收束 proof、存档与通关状态继续由 TypeScript 控制器持有。视频播放结束不能直接写入 `completed=true`。

## 2. 叙事作用

这段视频需要同时说明四个结果：

1. 五区配电恢复以后，楼内晨间照明和楼外纪念灯回路已经可用。
2. 大厅旧钟已经恢复为可信的 `07:55`。
3. 校园卡与签到纸完成双重验证，系统允许归档当日记录。
4. 玩家从门厅实际到达楼外，随后看见纪念灯进入正式点亮过程。

视频不新增解谜，不要求玩家再次核对配电、校友墙或签到顺序。它只展示此前结果，并把室内位置连续地过渡到楼外灯体。

## 3. 母版规格

| 项目 | 规格 |
| --- | --- |
| 逻辑画幅 | `960×540`，固定 `16:9` |
| 推荐生成尺寸 | `1920×1080`；模型不稳定时降为 `1280×720` |
| 帧率 | `24 FPS` 恒定帧率 |
| 生成片段 | `C4V-01 / C4V-02 / C4V-03`，每段 `6.000s / 144 帧` |
| 新增视频总长 | `18.000s / 432 帧` |
| 正式灯光序列 | 继续使用现有 `6200ms` 分层序列 |
| 完整收束时长 | 约 `24.2s` |
| 视频编码 | `H.264 High`、`yuv420p`、无 B 帧依赖的普通 MP4；运行时接入前再决定是否 fragmented MP4 |
| 视频音轨 | 生成阶段全部静音；游戏运行时单独控制对白、音效与配乐 |
| 文字 | 视频帧内不生成字幕、UI、门牌、章节名、时间数字或可读标识 |
| 镜头安全区 | 四周保留 `5%`，灯体和主角不得被 `960×540` 裁切 |

## 4. 正式素材与权威边界

### 4.1 现有正式素材

| 锚点 ID | 文件 | 用途 |
| --- | --- | --- |
| `ENV-A1-0755` | `src/assets/rpg/interiors/finale/chapter4-755/states/a1_0755_morning.png` | A1 清晨像素门厅、前台、玻璃门、照明与空间几何 |
| `ENV-ENTRANCE-PIXEL` | `src/assets/rpg/cinematics/chapter4-prologue/pixel/entrance_a.png` | 教学楼入口像素立面几何；夜间色彩只作结构参考 |
| `ENV-ENTRANCE-HIRES` | `src/assets/rpg/cinematics/chapter4-prologue/entrance_a.png` | 教学楼入口写实化立面几何；夜间色彩只作结构参考 |
| `PLAYER-UP` | `src/assets/rpg/player/player_up_0.png` | 像素主角背面身份 |
| `PLAYER-SIDE` | `src/assets/rpg/player/player_side_0.png` | 像素主角侧面身份 |
| `ITEMS-C4` | `src/assets/rpg/interiors/finale/chapter4-755/sprites/chapter4_story_items_v01.png` | 校园卡和签到纸形态参考 |
| `LAMP-DARK` | `src/assets/rpg/cinematics/chapter4-755/canruo-star-lamp/lamp_dark.png` | 未点亮灯体身份与最终构图 |
| `LAMP-OUTLINE` | `src/assets/rpg/cinematics/chapter4-755/canruo-star-lamp/lamp_outline.png` | 金属轮廓身份；不进入前三段生成画面 |
| `LAMP-LEDS` | `src/assets/rpg/cinematics/chapter4-755/canruo-star-lamp/lamp_leds.png` | 灯珠位置；只用于接缝复核 |
| `LAMP-CORE` | `src/assets/rpg/cinematics/chapter4-755/canruo-star-lamp/lamp_core.png` | 灯芯位置；只用于接缝复核 |
| `LAMP-GLOW` | `src/assets/rpg/cinematics/chapter4-755/canruo-star-lamp/lamp_glow.png` | 光晕范围；只用于接缝复核 |

正式灯素材保持 `1024×1536` 原始透明画布。灯体权威边界固定为：

```json
{
  "x": 361,
  "y": 27,
  "width": 307,
  "height": 1497
}
```

视频不得重新设计灯柱、金属球笼、灯珠分布、灯芯或顶部尖杆。前三段只允许使用 `LAMP-DARK` 作为未点亮主体参考，正式发光继续由现有五层素材完成。

### 4.2 需要制作的专用锚点

锚点目录建议为：

```text
docs/assets/chapter4-canruo-transition/anchors/
```

| 锚点 ID | 建议文件名 | 规格 | 制作来源 | 作用 |
| --- | --- | --- | --- | --- |
| `A01-CHECKIN-DONE` | `a01_checkin_done_960x540.png` | `960×540` RGB | DEV `c4-755-checkin`，真实完成第二项签到后、关闭 UI 后截取 RPG 画面 | C4V-01 精确首帧 |
| `A02-DOOR-THRESHOLD` | `a02_door_threshold_960x540.png` | `960×540` RGB | A1 清晨场景，主角背对镜头站在玻璃门内侧 | C4V-01 尾帧、C4V-02 首帧 |
| `A03-PLAYER-PIXEL-ID` | `a03_player_pixel_identity_1024.png` | `1024×1024` RGB | `PLAYER-UP` 与 `PLAYER-SIDE` 最近邻放大后排入同一身份板 | 像素主角身份 |
| `A04-ITEM-DEVICE-ID` | `a04_checkin_devices_identity_1024.png` | `1024×1024` RGB | 正式读卡器、纸槽、校园卡和签到纸的无 UI 裁片 | 设备与道具数量、颜色和形态 |
| `A05-THRESHOLD-MID` | `a05_threshold_mid_1920x1080.png` | `1920×1080` RGB | 分镜草图；玻璃反光覆盖画面 `90%`，只保留主角背包外轮廓 | C4V-02 隐藏切点 |
| `A06-PLAYER-REAL-ID` | `a06_player_real_identity_1024.png` | `1024×1024` RGB | 根据像素主角生成的一张背面写实身份图 | 写实段主角身份，不生成正脸 |
| `A07-EXTERIOR-DAWN` | `a07_exterior_dawn_1920x1080.png` | `1920×1080` RGB | `ENV-ENTRANCE-HIRES` 保持几何，调整为 `07:55` 清晨并放置一盏未点亮灯 | C4V-02 尾帧、C4V-03 首帧 |
| `A08-LAMP-UNLIT-ID` | `a08_lamp_unlit_identity_1024x1536.png` | `1024×1536` RGBA 或黑底 RGB | 原样复制 `LAMP-DARK` | 灯体唯一身份 |
| `A09-LAMP-ALIGN` | `a09_lamp_alignment_960x540.png` | `960×540` RGB | 按正式运行时 `object-fit: contain` 与镜头起始值合成 `LAMP-DARK` | C4V-03 倒数第二个可见锚点 |
| `A10-BLACK` | `a10_black_960x540.png` | `960×540` RGB | 纯黑 `#000000` | C4V-03 精确尾帧、正式灯序列首帧 |

`A01` 与 `A02` 必须从正式 Phaser 运行时捕获，不能让视频模型重新绘制门厅。`A07` 只允许改变时间、天气和真实材质表现，教学楼正门、门框、台阶、窗格、树木与花池位置继续服从 `ENV-ENTRANCE-HIRES`。

## 5. 全局连续性合同

### 5.1 主角

- 始终只有一名主角。
- 像素段保留黑色短发、蓝色外套、深色长裤、灰白鞋和深色背包。
- 写实段只拍背面、侧后方或远景，避免模型自行生成新的正脸身份。
- 玻璃门遮挡前后的肩宽、背包高度、外套蓝色和步频保持一致。
- 不增加帽子、眼镜、围巾、校服标志、武器或手持物。
- 不复制四肢、背包、人物倒影或第二名主角。

### 5.2 教学楼与玻璃门

- 正门保持中央双扇玻璃门、左右固定玻璃窗、上方雨棚、两侧台阶和入口花池。
- C4V-01 中的门使用 A1 母图俯视位置；C4V-02 后半段使用入口立面锚点。
- 开门动作只发生一次。两扇门同时向左右滑开，不能旋转、折叠或变成木门。
- 从像素到写实的切换只能发生在玻璃反光和清晨曝光覆盖画面 `90%` 以上时。
- 禁止人物、门框、玻璃或建筑在切换过程中连续形变。

### 5.3 灯体

- 楼外只出现一盏灿若星辰灯。
- 灯体位于入口广场一侧的合理位置，地面基座完整落地，不悬空、不穿过建筑或花池。
- C4V-03 中灯保持未点亮，灯珠无自发光、灯芯无光、地面无灯光投影。
- 镜头靠近灯体后，构图必须收束到 `A09-LAMP-ALIGN`。
- C4V-03 最后 `8` 帧为 `A10-BLACK`，正式灯光序列从同样的纯黑开始。

### 5.4 时间与环境

- 时间固定为清晨 `07:55`。
- 室内使用浅暖白顶灯，楼外使用冷白清晨环境光与很弱的暖色室内漏光。
- 地面可以保留轻微潮湿反光，以延续此前夜间与清晨的环境，但不出现降雨、积水飞溅或暴风。
- 室外只有轻微树叶摆动、远处鸟声和早晨校园底噪。
- 不生成夜空、夕阳、正午强光、浓雾、雪或大雨。

### 5.5 文字和 UI

- 视频内所有招牌保持空白或不可读。
- `07:55`、任务提示、字幕和章节标题都由 React/字幕层绘制，不进入生成视频。
- 不生成 HUD、DEV、任务栏、物品栏、蓝色选择框、按钮、字幕、水印、Logo 或二维码。

## 6. 全局坐标与镜头锚点

所有坐标以 `960×540` 成片画幅为准。

| 片段 | 对象 | 起点 | 中间锚点 | 终点 | 容差 |
| --- | --- | ---: | ---: | ---: | ---: |
| C4V-01 | 主角脚点 | `(480,356)` | `(480,410)` | `(480,466)` | `±12px` |
| C4V-01 | 玻璃门中轴 | `(480,448)` | 固定 | `(480,448)` | `±4px` |
| C4V-02 | 主角背包中心 | `(480,394)` | `(480,330)` | `(480,360)` | `±16px` |
| C4V-02 | 玻璃高光覆盖 | `0%` | `90–100%` | `35%` | 切换时必须 `≥90%` |
| C4V-03 | 主角脚点 | `(480,468)` | `(356,470)` | 画外左下 | `±20px` |
| C4V-03 | 灯柱基座 | `(724,508)` | `(620,520)` | 画外下方 | `±18px` |
| C4V-03 | 灯球中心 | `(724,270)` | `(600,210)` | `(480,162)` | 终点 `±6px` |
| C4V-03 | 灯柱中轴 | `x=724` | `x=600` | `x=480` | 终点 `±4px` |

C4V-01 使用正交俯视镜头。C4V-02 仅在隐藏切点前改变镜头高度，隐藏切点后使用等效 `35mm` 视角。C4V-03 使用固定 `35mm` 焦段完成平移、仰角和上摇，不在一个镜头中改变焦段。

## 7. 逐秒分镜

### 7.1 C4V-01：双签到完成与走向出口

目标：保留正式像素门厅，让此前所有解谜结果产生可见反馈，并把主角移动到玻璃门内侧。

| 时间 | 帧 | 画面与动作 | 摄像机 | 声音与字幕锚点 |
| --- | ---: | --- | --- | --- |
| `0.000–0.500s` | `0–11` | 严格匹配 `A01-CHECKIN-DONE`。读卡器和纸槽都保持绿色状态；主角站在前台中央，不移动。 | 正交俯视，完全静止。 | `0.10s` 双确认短响；字幕：“双项记录核验完成。” |
| `0.500–1.500s` | `12–35` | 前台台面指示灯从左右两侧向中央依次点亮，签到纸槽吐出一小截归档回执；禁止出现可读文字。 | 轻微向前台推近 `3%`，不得改变透视。 | 纸张滚轮、继电器轻响；字幕：“时间：07:55。地点：段永平教学楼 A1。” |
| `1.500–2.800s` | `36–66` | 门厅顶灯按“前台上方—两侧走廊—玻璃门上方”顺序恢复。地面反光同步增强。 | 缓慢拉回到初始画幅。 | 三次分离的灯控触发声；室内电气底噪开始。 |
| `2.800–3.600s` | `67–85` | 值班助理保持站位，主角向右后方转身，再朝玻璃门方向。人物动作使用现有四向像素行走节奏。 | 镜头开始跟随主角，保持正交俯视。 | 值班助理画外音：“楼外纪念灯的晨间回路已经恢复，请到门外确认。” |
| `3.600–5.200s` | `86–124` | 主角沿大厅中轴走向南侧玻璃门。两侧学生和工作人员只做低幅度待机，不穿过主角路线。 | 沿中轴向下平移，速度恒定。 | 像素脚步声每两步一次，门禁解锁声位于 `4.90s`。 |
| `5.200–6.000s` | `125–143` | 收束到 `A02-DOOR-THRESHOLD`。主角停在门内侧，玻璃门仍关闭；最后 `8` 帧完全稳定。 | 镜头停止。 | 室内底噪继续，无新增对白。 |

#### C4V-01 中文提示词

```text
使用全参考图生成六秒、24 FPS、16:9 的清晰硬边像素动画。首帧严格匹配 A01：段永平教学楼 A1 清晨门厅，前台、玻璃门、地砖、花池、主角和工作人员位置全部保持。主角是唯一一名黑色短发、蓝色外套、深色长裤、灰白鞋、深色背包的学生。读卡器与纸条签到槽已经显示绿色确认状态。前 0.5 秒稳定构图；随后设备灯由左右向中央点亮，纸槽吐出一小截没有可读文字的回执；大厅顶灯从前台向走廊和玻璃门方向逐段恢复。2.8 秒后主角转身，沿大厅中轴走向南侧玻璃门。摄像机保持正交俯视，只做平滑平移，不旋转、不改变像素密度。结尾严格匹配 A02，主角背对镜头站在玻璃门内侧，门仍关闭，最后 8 帧保持静止。视频无字幕、无 UI、无可读文字、无水印、无生成音轨。
```

#### C4V-01 H3 全参考英文提示词

```text
How the reference pictures align with the target video — Picture 1 aligns with the exact 0.00-second first frame; Picture 2 aligns with the exact 6.00-second final frame.

subject_definitions:
<Subject 1> is the only playable university student defined by <Picture 3>: short black hair, blue jacket, dark trousers, gray-white shoes, and one dark backpack. The front, back, and side poses in the identity sheet are successive views of the same single student, not multiple students.
<Subject 2> is the A1 morning teaching-building lobby established by <Picture 1> and <Picture 2>, including the exact front desk, tiled floor, central axis, planters, southern glass entrance, furniture, staff position, and warm-white morning lights.
<Subject 3> is the pair of check-in fixtures defined by <Picture 4>: one compact campus-card reader and one brown-gold attendance-paper slot. The campus card, paper, reader, and slot each appear exactly once.
<Picture 1> is the exact first frame at 0.00 seconds.
<Picture 2> is the exact final frame at 6.00 seconds.

summary:
Create one continuous six-second hard-edged pixel-animation shot. Start from the exact completed check-in composition in <Picture 1>. Show both check-in fixtures confirming, a short blank receipt extending from the paper slot, and the lobby lights restoring in a clear front-desk-to-corridor-to-glass-door sequence. The same single student then turns and walks down the central lobby axis to the inside of the glass entrance. End exactly on <Picture 2>. Generate silent video with no embedded interface or text.

retention_analysis:
Preserve the exact A1 floor geometry, front-desk shape, glass-door width, tiled-floor grid, planters, classroom walls, furniture, staff position, pixel density, and morning palette from <Picture 1> and <Picture 2>. Preserve exactly one <Subject 1>, one campus-card reader, one paper slot, one campus card, and one attendance paper. Preserve the student's hair, jacket, trousers, shoes, backpack, body scale, and four-direction pixel-walk identity. Do not duplicate, stretch, redraw, rotate, or relocate the front desk, entrance, staff, student, devices, doors, plants, furniture, or receipt. Do not invent readable writing.

detailed_description:
0.00-0.50 seconds: match <Picture 1> exactly and hold the first twelve frames. The student stands still at the completed check-in position. Both device status lamps are green. 0.50-1.50 seconds: the two fixture lamps pulse once from the outer sides toward the center. A short blank paper receipt advances a few centimeters from the attendance slot. Keep the paper rigid enough to read as one receipt and generate no legible characters. 1.50-2.80 seconds: restore warm-white ceiling illumination in three spatially separated steps, first above the desk, then the side corridors, then above the southern glass entrance. Increase only the matching floor reflections. 2.80-3.60 seconds: the same student turns through one natural pixel transition pose and faces the southern exit. 3.60-5.20 seconds: the student walks down the exact central floor path using one continuous hard-edged pixel walk cycle. Keep staff and background students in low-amplitude idle motion and outside the walking lane. Keep the camera orthographic and translate it smoothly without rotation or perspective change. 5.20-6.00 seconds: converge exactly to <Picture 2>, with the student facing away from the camera at the inside glass-door threshold. The glass doors remain closed. Hold the last eight frames perfectly still.

overall_soundscape:
N/A. Generate silent video. The game runtime owns device beeps, relay sounds, footsteps, ambience, dialogue, subtitles, and music.

non_diegetic_music:
N/A. Do not generate music.
```

### 7.2 C4V-02：玻璃门遮挡与视觉转换

目标：利用同一扇玻璃门完成一次隐藏硬切，让像素俯视画面和写实楼外画面保持动作连续。

| 时间 | 帧 | 画面与动作 | 摄像机 | 声音与字幕锚点 |
| --- | ---: | --- | --- | --- |
| `0.000–0.500s` | `0–11` | 严格匹配 `A02-DOOR-THRESHOLD`，保持 `8` 帧后门禁灯亮绿。 | 正交俯视，静止。 | 门禁确认声。 |
| `0.500–1.700s` | `12–40` | 玻璃双门向左右滑开。主角向前走两步，门框在角色两侧保持对称。 | 镜头沿主角移动方向降低并推近，仍保持像素画面。 | 玻璃门电机、两步脚步。 |
| `1.700–2.900s` | `41–69` | 镜头接近主角背包和玻璃门；清晨反光在玻璃上快速增强，收束到 `A05-THRESHOLD-MID`。 | 从俯视降到肩后视角；镜头轴始终通过主角背包中心。 | 室内声音逐渐降低，楼外环境声逐渐提高。 |
| `2.900–3.300s` | `70–78` | 玻璃高光覆盖画面 `90–100%`。仅在完全遮挡的 2–3 帧内执行一次硬切。 | 切换前后都沿同一中轴向前运动。 | 使用门框经过镜头的短促空气声遮盖切点。 |
| `3.300–4.800s` | `79–114` | 切换为写实电影画面。主角的写实背面继续相同步幅穿过同一扇门；建筑门框、玻璃分格和台阶延续。 | 固定 `35mm`，稳定肩后跟拍，不使用景深虚化。 | 楼外轻风、鸟声进入；脚步材质从室内地砖转为室外石材。 |
| `4.800–6.000s` | `115–143` | 主角走到门外平台，收束到 `A07-EXTERIOR-DAWN` 的人物与建筑位置；最后 `8` 帧稳定。 | 摄像机在门外停下，保持主角背面和完整入口。 | 室内电机声结束；无对白。 |

#### C4V-02 中文提示词

```text
生成六秒、24 FPS、16:9 的单次视觉转换镜头。首帧严格匹配 A02 的俯视像素门厅，主角背对镜头站在玻璃门内侧。玻璃双门向左右平移打开，主角向前走，摄像机沿门厅中轴降低并推近主角背包。到 2.9 秒时，玻璃反光和清晨曝光覆盖画面 90% 以上，只在完全遮挡的 2 至 3 帧内进行一次硬切；禁止人物、门框和建筑连续变形。硬切后改为写实电影画面，同一名主角以相同步幅从同一扇门继续走出，黑色短发、蓝色外套、深色长裤、灰白鞋和深色背包保持。教学楼入口、门框、玻璃分格、台阶、花池和树木服从像素及高分辨率入口锚点。写实段固定 35mm 焦段，不使用景深和运动模糊。尾帧严格匹配 A07 的清晨楼外构图，最后 8 帧稳定。无字幕、无 UI、无可读标牌、无水印、无生成音轨。
```

#### C4V-02 H3 全参考英文提示词

```text
How the reference pictures align with the target video — Picture 1 aligns with the exact 0.00-second first frame; Picture 2 defines the pixel entrance geometry; Picture 3 defines the high-resolution entrance geometry; Picture 4 aligns with the fully occluded midpoint; Picture 5 aligns with the exact 6.00-second final frame.

subject_definitions:
<Subject 1> is the same single student defined by the pixel identity reference and the rear-view realistic identity reference: short black hair, blue jacket, dark trousers, gray-white shoes, and one dark backpack. The realistic view is a faithful material translation of the same silhouette. Do not reveal or invent a new frontal face.
<Subject 2> is one teaching-building entrance defined jointly by the pixel entrance and high-resolution entrance references: centered sliding glass double doors, fixed side glazing, rectangular glass divisions, entrance canopy, steps, planters, facade windows, and one tree. Both references describe the same building at different visual resolutions.
<Picture 1> is the exact first frame at 0.00 seconds.
<Picture 4> is the required full-occlusion transition composition around 3.00 seconds.
<Picture 5> is the exact final frame at 6.00 seconds.

summary:
Create one continuous six-second threshold shot that starts as exact hard-edged top-down pixel animation and ends as a stable realistic cinematic rear view. The same student walks through the same sliding glass entrance. Use exactly one concealed hard cut while glass reflection and dawn exposure cover at least ninety percent of the frame. Continue the student's step and camera direction across the cut. End on the exterior dawn composition in <Picture 5>. Generate silent video with no embedded text.

retention_analysis:
Preserve one student, one backpack, one entrance, two sliding door panels, all fixed glass divisions, canopy, steps, planters, facade windows, and the tree positions. Preserve the central entrance axis throughout the shot. Preserve the student's black hair, blue jacket, dark trousers, gray-white shoes, shoulder width, backpack height, stride phase, and movement speed across the hidden cut. The pixel and high-resolution references are two representations of the same building. Do not create a second building, second entrance, duplicate student, duplicate backpack, extra limbs, extra door panels, rotating doors, wooden doors, escalators, signs, crowds, cars, or readable text. Do not morph objects during the style change.

detailed_description:
0.00-0.50 seconds: match <Picture 1> exactly and hold the first eight frames. The student faces away from the camera at the inside threshold. 0.50-1.70 seconds: the two glass door panels slide horizontally left and right exactly once. The student takes two forward steps. The camera follows the central floor axis, moves closer, and lowers from the orthographic top-down position while the image remains hard-edged pixel art. 1.70-2.90 seconds: move toward the backpack center and the glass surface. Increase only physically plausible dawn reflection and exposure on the glass until the composition reaches <Picture 4>. 2.90-3.30 seconds: glass reflection and bright exterior exposure cover ninety to one hundred percent of the image. Execute one hard cut inside two or three fully covered frames. Do not cross-dissolve and do not animate any morph between pixel and realistic materials. 3.30-4.80 seconds: reveal the same student from behind in a realistic cinematic view, continuing the same stride through the same entrance. Use a fixed thirty-five-millimeter field of view, stable focus across the scene, hard architectural edges, and no artificial depth-of-field blur. 4.80-6.00 seconds: the student reaches the exterior platform and the camera stops behind him. Converge exactly to <Picture 5> and hold the last eight frames.

overall_soundscape:
N/A. Generate silent video. The runtime owns door motor, footsteps, indoor-to-outdoor ambience transition, dialogue, subtitles, and music.

non_diegetic_music:
N/A. Do not generate music.
```

### 7.3 C4V-03：楼外确认与灯体接入

目标：建立楼外空间，展示唯一未点亮灯体，并用纯黑尾帧无闪动接回现有正式点亮序列。

| 时间 | 帧 | 画面与动作 | 摄像机 | 声音与字幕锚点 |
| --- | ---: | --- | --- | --- |
| `0.000–0.600s` | `0–14` | 严格匹配 `A07-EXTERIOR-DAWN`。主角背对镜头位于入口平台；未点亮灯位于画面右侧中景。 | 固定 `35mm`，静止。 | 清晨风、鸟声、远处校园底噪。 |
| `0.600–1.800s` | `15–43` | 主角向左前方走两步并停下，让出灯柱视线。主角不触摸灯。 | 摄像机向右平移并轻微绕过主角肩部。 | 两到三步室外脚步；字幕：“所有记录已经对齐。” |
| `1.800–3.300s` | `44–78` | 灯柱完整进入画面。镜头沿灯柱中轴缓慢上摇，先经过基座与柱身。 | 平移结束后只做上摇，不改变焦段。 | 很轻的电力待机低频开始，灯仍不发光。 |
| `3.300–4.600s` | `79–109` | 镜头到达金属球笼，使用 `A08-LAMP-UNLIT-ID` 保持精确结构。背景建筑逐渐降低亮度，但仍可辨识。 | 灯球中心移动到 `(480,162)`，柱体中轴移动到 `x=480`。 | 一次很轻的接触器预备声，禁止发光声提前出现。 |
| `4.600–5.300s` | `110–126` | 收束到 `A09-LAMP-ALIGN`。背景使用暗角逐渐压到黑色，灯体仍未点亮。 | 相机停止，灯体位置锁定。 | 环境声在 `5.20s` 前衰减至 `-24dB`。 |
| `5.300–5.667s` | `127–135` | 灯体轮廓随背景一起淡出到纯黑，不出现白闪或发光。 | 完全静止。 | 低频停止。 |
| `5.667–6.000s` | `136–143` | 严格保持 `A10-BLACK` 共 `8` 帧。 | 完全静止。 | 纯静音；下一帧交给正式 6200ms 灯光序列。 |

#### C4V-03 中文提示词

```text
生成六秒、24 FPS、16:9 的写实清晨电影镜头。首帧严格匹配 A07：同一名蓝色外套学生背对镜头站在教学楼入口平台，教学楼正门、台阶、玻璃、花池和树木保持；画面右侧中景只有一盏未点亮的灿若星辰灯。主角向左前方走两步并停下，为灯柱让出完整视线，不能触碰灯。摄像机使用固定 35mm 焦段向右平移，随后沿灯柱中轴上摇，经过基座、柱身和球形金属灯体。灯柱必须严格服从 A08 的原始形状：同一根白灰色锥形柱、同一球形金属网笼、同一顶部尖杆，灯珠、灯芯和地面都不发光。4.6 秒时灯球中心锁定在画面坐标 (480,162)，灯柱中轴锁定 x=480，构图匹配 A09。随后背景和未点亮灯体共同淡到纯黑，最后 8 帧严格匹配 A10 的纯黑。禁止灯提前点亮，禁止生成第二盏灯，禁止变形、悬空、穿过建筑、镜头变焦、景深、强光斑、字幕、UI、可读标牌、水印和生成音轨。
```

#### C4V-03 H3 全参考英文提示词

```text
How the reference pictures align with the target video — Picture 1 aligns with the exact 0.00-second first frame; Picture 2 defines the only unlit lamp identity; Picture 3 aligns with the last visible lamp composition around 5.20 seconds; Picture 4 aligns with the exact 6.00-second pure-black final frame.

subject_definitions:
<Subject 1> is the same single rear-view university student from the previous clip: short black hair, blue jacket, dark trousers, gray-white shoes, and one dark backpack. He remains a secondary foreground figure and does not reveal a new frontal face.
<Subject 2> is the only Canruo Star Lamp defined exactly by <Picture 2>: one tapered light-gray pole, one fixed spherical metal lattice containing the same unlit LED nodes and central core geometry, one upper needle, and one grounded base. <Picture 2> fixes the lamp silhouette, proportions, lattice topology, node placement, core placement, pole taper, and upper needle. It remains completely unlit throughout this clip.
<Subject 3> is the dawn teaching-building exterior from <Picture 1>, including the exact entrance, glazing, canopy, steps, planters, facade windows, tree, plaza surface, and cold-white early-morning environment light.
<Picture 1> is the exact first frame at 0.00 seconds.
<Picture 3> is the required last visible lamp alignment around 5.20 seconds.
<Picture 4> is the exact pure-black final frame at 6.00 seconds.

summary:
Create one continuous six-second realistic cinematic exterior shot. Start exactly from <Picture 1>. The single student takes two short steps left and stops, clearing the line of sight to the only unlit lamp. The camera translates right, then tilts upward along the lamp pole to the spherical lattice. Preserve the exact lamp identity from <Picture 2> and keep every LED and the central core unlit. Reach <Picture 3>, fade the environment and unlit lamp together to black, then hold the exact <Picture 4> pure-black frame for the final eight frames. Generate silent video.

retention_analysis:
Preserve exactly one student, one backpack, one teaching-building entrance, and one Canruo Star Lamp. Preserve the building geometry and dawn lighting from <Picture 1>. Preserve the lamp silhouette, pole taper, grounded base, sphere size, lattice topology, LED-node count and placement, central core geometry, and upper needle from <Picture 2>. Do not redesign, simplify, duplicate, bend, shorten, widen, recolor, illuminate, suspend, or relocate the lamp during the camera move. Do not add another lamp, signage, flags, statues, crowds, vehicles, readable text, interface, or generated title. Do not let the student touch or operate the lamp.

detailed_description:
0.00-0.60 seconds: reproduce <Picture 1> exactly and hold the initial composition. The student is rear-facing on the entrance platform. One unlit lamp stands in the right middle distance. 0.60-1.80 seconds: the student takes two short natural steps toward the left foreground and stops. Translate the camera gently to the right so the lamp becomes unobstructed. Keep a fixed thirty-five-millimeter field of view and stable scene-wide focus. 1.80-3.30 seconds: end the lateral move and tilt upward along the grounded lamp base and tapered pole. Keep the entire lamp rigid and fixed in the plaza. 3.30-4.60 seconds: reach the spherical lattice. Match <Picture 2> exactly. Move the sphere center to logical coordinate 480,162 and the pole axis to x=480. Every LED node and the central core remain dark. 4.60-5.30 seconds: stop camera movement and converge precisely to <Picture 3>. Apply a controlled vignette and reduce the building background toward black without producing any lamp glow, flare, flash, or exposure pulse. 5.30-5.67 seconds: fade the unlit lamp silhouette and the remaining environment together to pure black. 5.67-6.00 seconds: reproduce <Picture 4> exactly and hold the final eight frames completely still.

overall_soundscape:
N/A. Generate silent video. The game runtime owns exterior ambience, footsteps, electrical preparation, dialogue, subtitles, and the following official lamp sequence.

non_diegetic_music:
N/A. Do not generate music.
```

## 8. 全局负面提示词

以下内容附加到每一段生成任务：

```text
no extra protagonist, no duplicate student, no duplicate backpack, no extra limbs, no face replacement, no front-face close-up, no crowd crossing the path, no duplicate doors, no revolving door, no wooden door, no architecture morph, no floating object, no teleportation, no cross-dissolve at the style transition, no visible morph between pixel and realistic materials, no second lamp, no redesigned lamp, no illuminated lamp before the official sequence, no changed LED topology, no bent pole, no shortened pole, no missing base, no readable sign, no subtitles, no UI, no HUD, no task bar, no inventory, no DEV panel, no watermark, no logo, no QR code, no extra text, no rain, no storm, no fog, no night sky, no sunset, no noon sun, no motion blur, no depth-of-field blur, no handheld shake, no fisheye lens, no zoom pulse, no lens dirt, no strong cinematic flare, no generated audio, no narration, no singing, no lip sync
```

## 9. 对白、字幕与声音脚本

生成视频保持静音。以下内容由游戏音频和字幕层按同一主时钟播放：

| 全局时间 | 类型 | 内容 | 声音位置与要求 |
| --- | --- | --- | --- |
| `00.10s` | SFX | 双设备确认短响 | 前台中央；两声间隔 `120ms` |
| `00.25s` | 系统字幕/配音 | “双项记录核验完成。” | 无人物口型，系统声线 |
| `00.65s` | SFX | 纸槽滚轮与回执停止声 | 画面右侧前台 |
| `00.90s` | 系统字幕/配音 | “时间：07:55。地点：段永平教学楼 A1。” | 系统声线，字幕停留约 `2.4s` |
| `01.55s / 01.95s / 02.35s` | SFX | 三段照明继电器与灯管启动声 | 前台、走廊、玻璃门依次移动 |
| `02.90s` | 值班助理画外音 | “楼外纪念灯的晨间回路已经恢复，请到门外确认。” | 来自主角后方，不要求人物口型 |
| `03.70s–05.10s` | SFX | 像素脚步 | 每两步一次，音量低于对白 |
| `04.90s` | SFX | 门禁解锁 | 玻璃门中央 |
| `06.50s–07.20s` | SFX | 玻璃门电机 | 左右声道对应门扇移动 |
| `07.40s–09.20s` | SFX | 室内脚步与门框空气声 | 隐藏切点前后步频连续 |
| `09.00s–10.20s` | 环境 | 室内底噪淡出、清晨校园底噪淡入 | 两条环境声交叉约 `1.2s` |
| `12.60s` | 环境 | 风、两到三声远处鸟鸣 | 不使用连续鸟群声 |
| `13.10s–13.80s` | SFX | 室外石材脚步 | 两到三步 |
| `13.30s` | 主角字幕/轻声 | “所有记录已经对齐。” | 主角背对镜头，无可见口型 |
| `15.20s` | SFX | 很轻的电力待机低频 | 灯柱方向；灯仍不亮 |
| `16.20s` | SFX | 单次接触器预备声 | 不加入点亮声和闪光声 |
| `17.20s–18.00s` | 环境 | 所有环境声衰减至静音 | 为正式灯序列留出黑场 |
| `18.00s` | BGM | 正式灯光音乐进入或延续 | 由现有灯光序列的节拍控制 |

现有文案“时间同意了”不进入本视频。建议最终对白保持事实性表达，避免把系统或时间写成人格主体。

## 10. 配乐要求

- C4V-01 前 `2.8s` 不进入完整旋律，只保留设备、继电器和轻微室内底噪。
- 主角开始走向出口时加入极低音量的持续和弦，速度建议 `68–72 BPM`。
- C4V-02 隐藏切点处不使用重拍、撞击或大幅上升音效，避免强调视觉切换。
- C4V-03 镜头沿灯柱上摇时逐步增加高频泛音，但灯正式点亮前不出现明亮钟声或合唱。
- 正式灯光序列开始后再进入主要主题动机；第一次明显和声展开应对齐 LED 层首次稳定点亮的时刻。
- 配乐全程不使用歌词。

## 11. 片段接缝

| 接缝 | 前一画面 | 后一画面 | 处理规则 |
| --- | --- | --- | --- |
| 游戏→C4V-01 | 第二项签到成功后的正式 A1 画面 | `A01-CHECKIN-DONE` | 用运行时捕获的完全相同帧直接切入；首 `12` 帧无相机运动 |
| C4V-01→C4V-02 | `A02-DOOR-THRESHOLD` | 同一 `A02` | 两段各自保留 `8` 帧稳定帧；剪辑时删除重复的后 `8` 帧，只保留一组 |
| C4V-02 像素→写实 | `A05-THRESHOLD-MID` 的像素侧 | 同一锚点的写实侧 | 玻璃高光覆盖 `≥90%` 时单次硬切；禁止溶解和变形 |
| C4V-02→C4V-03 | `A07-EXTERIOR-DAWN` | 同一 `A07` | 动作匹配硬切；删除重复稳定帧 |
| C4V-03→正式灯序列 | `A10-BLACK` 共 `8` 帧 | 现有灯序列的纯黑首帧 | 直接硬切；禁止白闪、Logo、标题卡或额外淡化 |

## 12. 生成与返工顺序

1. 先制作 `A01–A10` 锚点，不启动批量视频生成。
2. 首次只生成 `C4V-02` 的低成本预览，因为它决定像素与写实是否能稳定转换。
3. 检查玻璃高光覆盖率、主角身份、门体几何和硬切连续性。当前实际生成验证次数为 `0`，所有提示词仍处于设计假说阶段。
4. 用户确认 `C4V-02` 预览后，再生成该段正式版本。
5. 生成 `C4V-01`，重点检查门厅几何、主角数量、设备数量、顶灯顺序和尾帧。
6. 生成 `C4V-03`，重点检查唯一灯体、原始灯形、未点亮状态、灯球终点坐标与纯黑尾帧。
7. 每段单独完成身份、几何和尾帧检查以后再合并。不要为了修复一段而更换其他两段锚点。
8. 合并后移除模型音轨，统一到 `960×540 / 24 FPS / H.264 High / yuv420p`。
9. 最后再接现有 `6200ms` 灯光序列，检查第 `431→432` 帧及视频→灯光首帧是否闪动。

返工优先级：

1. 人物或灯体数量错误：强化 `exactly one`，减少无关主体锚点。
2. 建筑漂移：保留环境首尾帧，减少动作描述，不增加新的入口参考图。
3. 像素转写实发生形变：延长完全遮挡帧到 `4–6` 帧，并明确只允许硬切。
4. 主角正脸被生成：限制为背面和侧后方，删除含正脸的参考图。
5. 灯体结构改变：C4V-03 改为以 `A08` 为唯一灯主体参考，并缩短灯柱出现后的动作描述。
6. 接缝闪动：增加稳定帧并使用锚点硬切，不用交叉溶解补救。

## 13. 后期输出与运行时接入合同

建议成片文件：

```text
src/assets/rpg/cinematics/chapter4-755/canruo-transition/
  c4v_01_checkin_to_door.mp4
  c4v_02_pixel_to_real_threshold.mp4
  c4v_03_exterior_to_black.mp4
  chapter4_755_canruo_transition_master.mp4
  chapter4_755_canruo_transition.asset.json
```

未来运行时接入需要满足：

- 第二项签到由控制器接受后，先进入视频演出 gate；演出期间暂停 Phaser 输入。
- 视频播放结束只允许进入现有 `exterior_closure` 灯光会话。
- `ChapterFourClosureSessionRegistry` 仍然只在正式五层灯光序列真实播放完成后签发 proof。
- 视频加载失败、自动播放失败、页面隐藏或解码失败时，使用 `A01→A02→A10` 的有界静帧回退，再进入正式灯光序列。
- 跳过视频时仍需先进入正式灯光序列；不能通过跳过视频直接完成第四章。
- 存档不记录视频帧进度。刷新后从安全的 `exterior_closure` 或双签到完成状态重新进入。
- 生成视频不拥有 `GameStore`、`SaveStore`、章节阶段、任务事实、道具或完成回执。

## 14. 成片验收清单

### C4V-01

- 首帧与实际双签到完成画面一致。
- 只有一名主角、一个读卡器、一个纸槽、一张校园卡和一张签到纸。
- 灯光恢复顺序清楚，空间位置对应前台、走廊、出口。
- 主角沿可通行中轴走向玻璃门，没有穿过前台、花池或门体。
- 尾帧与 `A02` 一致，最后 `8` 帧稳定。

### C4V-02

- 玻璃门只开一次，门扇平移方向正确。
- 主角在视觉切换前后保持外套颜色、背包、身高、肩宽和步相。
- 玻璃高光覆盖 `90%` 以上以后才发生硬切。
- 切换过程中没有人物、建筑或门体形变。
- 尾帧与 `A07` 一致，主角仍位于楼外入口平台。

### C4V-03

- 全片只有一盏灿若星辰灯。
- 灯柱完整落地；球笼、灯珠、灯芯和尖杆保持正式素材结构。
- 灯在正式分层序列开始前始终未点亮。
- 灯球中心最终为 `(480,162)±6px`，灯柱中轴为 `x=480±4px`。
- 最后 `8` 帧为纯黑，接入现有灯光序列时没有白闪和位置跳变。

### 全片

- `16:9`，无拉伸、黑边和非等比缩放。
- 无 UI、字幕、任务栏、DEV、物品栏、水印和可读生成文字。
- 无多余人物、灯柱、门扇、背包、四肢和倒影主体。
- 无模型音轨；所有声音由运行时控制。
- 页面隐藏、视频失败或跳过不会写入章节完成状态。
- 只有正式 `6200ms` 灯光序列完成并通过 proof 后，章节才可完成。

## 15. 当前状态与下一步

当前已完成：

- C 方案视觉结构。
- 三段逐秒分镜。
- 正式素材与待制锚点清单。
- 中英文生成提示词。
- 全局负面提示词。
- 对白、字幕、声音、配乐和接缝合同。
- 分段生成、返工、后期和运行时接入边界。

当前未执行：

- 未制作 `A01–A10` 专用锚点。
- 未调用 MiniMax、Hailuo、Runway 或其他视频生成服务。
- 未消耗任何视频生成额度。
- 未生成、剪辑、编码或接入新视频。
- 未修改第四章控制器、宿主、灯光 consumer、存档或任务状态。

下一步应先制作锚点并只生成 `C4V-02` 的一个低成本预览。该预览通过用户视觉确认后，才进入其余两段生成。
