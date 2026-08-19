# 第三章半手机取证照片提示词

## 设计约束

- 用途：`P18_Photos` 的“恢复的项目（7）”相册。
- 画风：与启真湖运行地图一致的清晰像素画，硬边像素簇，有限色阶，不使用写实笔触、柔焦或高频颗粒。
- 机位：手机动态照片的固定机位，湖岸平视略俯，所有连续帧的灯柱、栏杆、岸线和远景位置必须完全一致。
- 动态线索：纸条依次经过左、中、右；圆形水纹向右拉开；船头只产生很小位移。
- 地图兼容：远处只出现“仍亮灯的校园长廊建筑”轮廓和入口暖光，不出现楼梯、电梯、教室编号、楼层平面或可用于反推第四章地图结构的细节。
- 素材安全：无文字、无界面、无商标、无水印、无白边。

## Image 2 生成提示词

```text
Use case: stylized-concept
Asset type: pixel-art game evidence contact sheet for a recovered mobile live photo
Primary request: create one perfectly aligned 3-column by 2-row contact sheet. Every panel is an equal-size square and uses the exact same fixed camera position at a university lake shore at night. The sheet will be mechanically cropped into six game assets.
Input images: Image 1 is the Qizhen Lake palette and pixel-density reference; Image 2 is the night lakeside lighting and architecture-style reference.
Scene/backdrop: wet stone lakeside path in the foreground, a single black metal lamp post slightly left of center, low railing and water behind it, moonlit ripples, willow foliage at the outer edge, and only a distant silhouette of a still-lit campus corridor building with warm entrance light. Keep the distant building generic and partly obscured so no floor plan, stairs, elevator, room number, or exact facade can be inferred.
Subject and panel sequence:
top-left: a small wet paper just above the water on the left side of the lamp post, with a complete circular ripple beneath it and a tiny kayak bow low in frame;
top-middle: the same paper crossing the middle beside the same lamp post, with the ripple beginning to stretch to the right and the kayak bow almost unchanged;
top-right: the same paper on the right side of the same lamp post, lifted slightly by wind, with the ripple stretched farther right and the kayak bow shifted only a few pixels;
bottom-left: an earlier lake-center memory frame with open water, distant buoy, no lamp-post crossing, no directional paper sequence;
bottom-middle: a second earlier lake-center memory frame with open water and a partial kayak reflection, no lamp-post crossing, no directional paper sequence;
bottom-right: a neutral calibration frame of the same lakeside camera without paper, used only as a consistency reference.
Style/medium: crisp 16-bit-inspired pixel art matching a polished browser RPG; intentional square pixels; restrained 48-64 color palette; each material uses about three brightness levels; clean readable silhouettes.
Composition/framing: six equal panels, exact 3×2 grid, straight horizontal and vertical gutters, identical horizon and camera framing in the three top panels; no panel labels.
Lighting/mood: clear moonlit blue water, warm practical light from the lamp and distant entrance, readable rather than dark.
Color palette: teal-blue water, blue-gray stone, muted green foliage, small warm amber lights, off-white wet paper.
Constraints: preserve the same static background geometry across the three top panels; show only the listed motion changes; keep the paper small but clearly readable; no people; no swan; no interface; no text; no numbers; no logos; no watermark; no white border.
Avoid: photorealism, painterly gradients, cinematic blur, anti-aliased vector shapes, oily highlights, over-detailed distant architecture, multiple lamp posts, changing perspective between panels, irregular panel sizes.
```

## 裁切与运行时映射

- `paper_left`：第一行第一格。
- `paper_middle`：第一行第二格。
- `paper_right`：第一行第三格。
- `lake_memory_a`：第二行第一格。
- `lake_memory_b`：第二行第二格。
- `mirrored_a`、`mirrored_b`：由连续帧素材在相册中水平翻转，不另生成，避免额外机位漂移。
- 第二行第三格仅用于人工检查机位一致性，不进入游戏。

## 后续第四章照片提示词原则

第四章地图重制完成前，证据照片只拍摄局部稳定对象：门牌、公告栏、导视板、门禁记录、墙面反光和人物经过方向。所有涉及走廊全景、楼梯位置、电梯数量与房间相对关系的照片延后生成，届时以最终运行地图为唯一构图参考。
