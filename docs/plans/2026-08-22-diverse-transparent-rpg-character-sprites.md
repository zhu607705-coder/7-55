# 多姿势透明 RPG 角色素材生成与接入记录

## 目标

- 消除第四章面包坊三名学生使用相同四帧并同步播放造成的重复动作。
- 将同一套多姿势规则用于主人公、保安和保洁阿姨。
- 保持角色身份、服装、像素密度、脚底锚点和透明背景一致。
- 运行时继续使用 `96 x 128` 角色逻辑帧和现有碰撞数据。

## MiniMax CLI 尝试

- CLI：`mmx 1.0.15`
- 模型：`image-01`
- 第一轮：`2048 x 2048`，服务端返回 `rpc timeout`，没有产生文件。
- 第二轮：`1024 x 1024`，成功产生候选图。
- 候选图没有遵守 `4 x 4` 网格，加入编号、门框和额外道具，背景为浅色画布，画风偏离现有像素角色，因此没有进入项目。

MiniMax 学生提示词：

```text
Create a production game sprite source sheet for the exact same black-haired male student shown in the subject reference. Pixel-art style, top-down three-quarter RPG view, full body. Exact layout: 4 columns by 4 rows, 16 isolated poses, equal cell size, one character per cell, feet aligned to the same baseline in every cell, consistent scale and proportions, no overlap. Cells 1 through 8 are one continuous natural 8-frame right-facing walk cycle: left heel strike, contact, passing, push-off, right heel strike, contact, passing, push-off; clearly different leg spacing, alternating arms, torso sway and center-of-gravity shift. Cells 9 and 10 are two distinct phone-glance poses. Cells 11 and 12 are two distinct backpack-strap adjustment poses. Cells 13 through 15 are three successive right-arm door-push poses. Cell 16 is a relaxed idle pose with the phone lowered. Preserve exactly the same face, black hair, charcoal jacket, black trousers, gray backpack, shoulder bag, earphones, phone and color palette. Background must be one perfectly flat solid pure #FF00FF field, no checkerboard, no gradients, no shadows outside the character, no floor, no grid lines, no text, no labels, no watermark, no extra props, no duplicated pose.
```

## 最终可复用生成提示词

四类角色统一使用以下基础约束，并在其后追加角色段落。参考图存在时必须保持参考图中的脸型、发型、服装、随身物品和主色，不得在不同动作格中改变身份特征。

```text
Create one production-ready pixel-art RPG character sprite source sheet on a truly transparent RGBA canvas. Top-down three-quarter view, full body visible in every cell, crisp hard pixel edges, limited coherent palette, consistent identity, anatomy, scale, lighting direction and camera angle. Use the exact grid and pose order stated below. Every cell has equal size; place exactly one complete pose inside each cell; keep the foot contact point on one shared baseline; leave transparent padding around the silhouette; do not let any pixel cross into a neighboring cell. All listed action frames must have visibly different limb positions, weight transfer and silhouettes while still reading as one continuous motion. No floor, cast shadow, glow, aura, checkerboard, colored background, grid line, border, number, text, label, watermark, duplicate pose, extra character, detached body fragment or unlisted prop. Preserve uniform X/Y scale. Output only the sprite sheet.
```

### 学生角色追加段落

```text
Exact layout: 4 columns by 4 rows, 16 poses. The same young male university student in every cell: short slightly messy black hair, charcoal school jacket over a light inner shirt, black trousers, dark sneakers with pale soles, compact gray backpack, small shoulder bag, wired earphones and a dark phone. Cells 1-8: one continuous right-facing eight-frame walk cycle, ordered heel strike, contact, passing, push-off, opposite heel strike, contact, passing, push-off, with alternating arms and natural torso shift. Cells 9-10: two different phone-glance poses. Cells 11-12: two different backpack-strap adjustment poses. Cells 13-15: three successive right-arm door-push poses. Cell 16: relaxed idle, phone lowered. Keep the student readable at 96 by 128 runtime pixels.
```

### 主人公追加段落

```text
Exact layout: 4 columns by 6 rows, 24 poses. The same young male protagonist in every cell: short black hair, blue jacket with dark collar and sleeves, dark trousers and dark shoes; no backpack, no weapon and no loose prop. Cells 1-8: one continuous eight-frame walk cycle facing down toward the camera. Cells 9-16: one continuous eight-frame walk cycle facing up away from the camera. Cells 17-24: one continuous eight-frame walk cycle facing right; the runtime will mirror these frames for left movement. Each direction must show clear alternating heel contact, passing and push-off poses. Preserve the established protagonist face, hair silhouette, blue-jacket color blocks and body proportions. Keep the character readable at 96 by 128 runtime pixels.
```

### 保安角色追加段落

```text
Exact layout: 4 columns by 4 rows, 16 poses. The same middle-aged male teaching-building security guard in every cell: short black hair, navy security uniform, black belt with keys and small utility pouch, dark trousers and black shoes. Cells 1-8: one continuous right-facing eight-frame patrol walk with clear alternating legs, arms and weight transfer. Cells 9-10: two checklist-inspection poses holding one small paper list. Cells 11-12: two watch-checking poses. Cells 13-14: two downward flashlight-inspection poses with a small flashlight and no light-beam background. Cells 15-16: two radio-speaking poses with one handheld radio. Preserve uniform badges and equipment placement; do not add weapons or police insignia.
```

### 保洁阿姨角色追加段落

```text
Exact layout: 4 columns by 4 rows, 16 poses. The same middle-aged female cleaner in every cell: black hair tied into a low bun, blue-gray work uniform with narrow yellow reflective trim, white work gloves and dark work shoes. Cells 1-4: four successive right-facing poses pushing the same orange-and-gray cleaning cart. Cells 5-8: four successive mopping poses with the same wooden-handled white mop. Cell 9: the cleaning cart alone, fully visible and centered. Cells 10-11: two successive poses placing the same yellow wet-floor warning sign. Cells 12-13: two poses operating a wall light switch. Cell 14: one lower-back-rest pose. Cells 15-16: two relaxed idle breathing poses. Keep her female facial features, bun, uniform and body proportions consistent. Props appear only in their assigned cells and must remain complete.
```

## 最终生成规格

MiniMax 候选未通过后，按备用路径使用图像生成工具生成真实 Alpha 图片。四张正式源图均保留在版本化路径中，没有覆盖旧源图。

### 面包坊学生

- 源图：`src/assets/rpg/npcs/finale/source/finale_student_source_grid_v2.png`
- 结构：`4 x 4`，共 `16` 个姿势。
- 单元格 1–8：右向八帧步行。
- 单元格 9–10：查看手机。
- 单元格 11–12：调整背包。
- 单元格 13–15：推门动作。
- 单元格 16：放下手机后的站立。

### 主人公

- 源图：`src/assets/rpg/player/source/player_walk_24pose_transparent_v2.png`
- 源图视觉上接近 `4 x 6`，但人物轮廓没有落在严格等分的数学网格中；构建器按整张图的 Alpha 连通轮廓提取 `24` 个完整姿势。
- 有效轮廓 1–8：朝下八帧步行。
- 有效轮廓 9–15：朝上七个独立姿势；第八帧由第 13 个有效轮廓水平镜像补齐，保持全程背向。
- 有效轮廓 16–24：九个朝右候选；运行时选取前八个，朝左由 Phaser 水平镜像。

### 保安

- 源图：`src/assets/rpg/npcs/finale/source/finale_guard_source_grid_v2.png`
- 结构：`4 x 4`，共 `16` 个姿势。
- 单元格 1–8：八帧步行。
- 单元格 9–10：查看清单。
- 单元格 11–12：查看手表。
- 单元格 13–14：手电检查。
- 单元格 15–16：使用对讲机。

### 保洁阿姨

- 源图：`src/assets/rpg/npcs/finale/source/finale_cleaner_source_grid_v2.png`
- 结构：`4 x 4`，共 `16` 个姿势。
- 单元格 1–4：推清洁车。
- 单元格 5–8：拖地。
- 单元格 9：清洁车单体。
- 单元格 10–11：放置警示牌。
- 单元格 12–13：操作照明开关。
- 单元格 14：扶腰休息。
- 单元格 15–16：站立呼吸。

## 透明背景和裁切规则

- 源图必须包含 RGBA 通道，画布四角 Alpha 为 `0`。
- 本批生成源图虽然视觉上排成多行多列，但人物会跨越等分网格边界。禁止再按画布宽高直接均分，否则上一行脚部和下一行头部会被截断。
- `scripts/build-rpg-player-frames.py` 在整张主人公源图上识别 `24` 个完整 Alpha 连通轮廓，再按轮廓中心的行列顺序排序和映射方向。
- `scripts/build-finale-npc-atlases.mjs` 在每张 NPC 源图上识别 `16` 个面积超过阈值的完整 Alpha 连通轮廓，再按行列顺序构建动作条。
- 每个方向组或角色只计算一次固定统一缩放比例。禁止按单帧高度分别填满目标框，否则残缺帧会被额外放大并造成动画大小跳变。
- 每帧保留至少 `2px` 的头顶与脚底透明安全留白；脚部锚点继续使用 `{x: 0.5, y: 1}`，运行时碰撞脚框保持不变。
- 运行帧的透明掩膜直接来自原图 Alpha 阈值。禁止对已经裁出的单帧再次依赖连通区域标签编号，以免 ImageMagick 标签排序变化把透明背景误写为不透明矩形。

## 回归校验

- `scripts/verify-rpg-character-sprite-integrity.mjs` 使用仓库已有 PNG 解码能力，同时检查主人公、学生、保安和保洁阿姨四类角色，不再依赖 Python 或 Pillow。
- 校验内容包括源图有效轮廓数量、头顶和脚底留白、源图与运行帧轮廓重合度、宽高比误差、同动画固定缩放比和主人公镜像补帧映射。
- 当前门限：轮廓宽高比误差不超过 `3%`，同动画最大与最小缩放比不超过 `1.03`，头顶和脚底至少各保留 `2px`。
- 执行入口：`npm run verify:rpg-character-sprites`。

## 运行时节奏

- 主人公：八帧，单帧 `110ms`，约 `9.1 FPS`，完整循环约 `880ms`。
- 学生：八帧，`8 FPS`。
- 保安：八帧，`8 FPS`。
- 保洁推车：四帧，`8 FPS`。
- 保洁拖地：四帧，`6 FPS`。
- 面包坊三名学生分别从第 `0 / 3 / 6` 帧开始播放，避免同步姿势。
