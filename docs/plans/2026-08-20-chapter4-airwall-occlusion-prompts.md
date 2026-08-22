# 第四章候选素材逐图空气墙与遮挡识图提示词

## 1. 用途与边界

本套提示词用于对 `artifacts/chapter4-map-assets-20260820/` 中的 20 张候选 PNG 做第二次识图标注，输出空气墙、动态门、可通行区域、交互区域、前景遮挡和物品名称。它不直接修改图片，也不直接写入 Phaser 碰撞数据。

坐标只来自本轮生成候选图本身。当前运行时地图、碰撞文件和已有“灿若星辰”素材不参与识图参考。

所有人工预标注都必须保留 `approximate: true`。只有图片尺寸、精灵表声明 cell 和工具测得的 Alpha 边界可以写 `approximate: false` 或 `measured: true`。接入游戏前仍需在最终选定图片上逐像素复核。

## 2. 统一坐标和分类

- 原点：左上角。
- X 向右，Y 向下。
- 单位：输入 PNG 的源像素。
- 最终输出矩形统一使用对象：`{"x":0,"y":0,"width":0,"height":0}`。
- 最终输出多边形统一使用：`[{"x":0,"y":0}, ...]`。
- 文档中的预标注可能使用 `rect=[x,y,width,height]` 或半开边界 `[x0,y0,x1,y1)`；每个分册会在顶部声明。识图模型必须转换成上述对象格式，禁止原样混用。

| 分类 | 用途 | 是否阻挡玩家 | 是否参与遮挡 |
| --- | --- | :---: | :---: |
| `static_solid` | 外墙、固定柜台、固定花坛、桌脚占地 | 是 | 视高度决定 |
| `dynamic_solid` | 关闭门扇、展开隔断、运行时家具 | 按状态 | 是 |
| `transition_trigger` | 楼梯、电梯、出口门槛 | 否 | 否 |
| `interaction_trigger` | 旧钟、配电箱、纸张、导视碎片 | 否 | 通常否 |
| `occluder_only` | 墙帽、门楣、植物冠层、桌面前沿 | 否 | 是 |
| `floor_decal` | 定位点、残影、水迹、光路 | 否 | 否 |
| `visual_only` | 光晕、反射、阴影、投影白屏、黑暗遮罩 | 否 | 否 |

空气墙必须对应可见实体的地面占用或明确关闭状态。亮区边缘、暗区、辉光、阴影、残影、任务路线和不可读背景色块均不得转为空气墙。

## 3. 通用识图前缀

对任意一张图执行时，先粘贴本段，再追加对应图片分册中的专用提示词。

```text
你是一名 2D 俯视 RPG 地图碰撞与遮挡标注员。只分析输入图片的真实可见像素，并使用输入图片自己的源像素坐标。原点在左上角，X 向右，Y 向下。

任务：识别所有可见的建筑边界、固定实体、动态实体、真实门洞、楼梯踏步、交互物、地面提示和前景遮挡物。不要根据剧情补画图中不存在的门、墙或家具。若剧情规格要求某物但图中看不到，写入 warnings，不得生成隐形碰撞。

最终只输出一个 JSON 对象。所有矩形必须使用 {x,y,width,height}；多边形使用 [{x,y},...]；点使用 {x,y}。每个对象必须包含：
- id：稳定英文 id；
- label：明确中文物品或结构名称；
- role：static_solid、dynamic_solid、transition_trigger、interaction_trigger、occluder_only、floor_decal 或 visual_only；
- geometry：rect、polygon、circle 或 point；
- approximate：目测坐标为 true；
- collision：enabled、disabled 或 conditional；
- occlusion：none、y_sort、foreground_mask 或 wall_fixture；
- baselineY 或 pivot：适用时填写；
- stateCondition：仅动态对象填写；
- evidence：用一句话说明对应的可见像素依据。

碰撞只覆盖物体脚部或落地底座，不得把完整精灵 Alpha 包围盒当碰撞。楼梯两侧扶手为 solid，踏步为可走区域，楼梯下端设置 transition_trigger。关闭门扇启用 dynamic_solid，开门后移除门洞阻挡。墙上旧钟、面板、黑板、幕布和挂画由墙体阻挡，自身只设 interaction_trigger 或 visual_only。

遮挡统一使用玩家脚点 actorFootY。落地物体按底边基线排序：actorFootY 小于对象 baselineY 且 X 范围重叠时，对象前景覆盖玩家；actorFootY 大于等于 baselineY 时玩家绘制在对象前方。植物冠层、桌面前沿、沙发靠背、展柜前沿、门楣和墙帽应单独输出前景遮挡范围。地面残影、定位点、光路、窗光、黑暗、投影白区、辉光与阴影始终 collision=disabled、occlusion=none。

JSON 顶层必须包含：image、imageSize、coordinateSystem、objects、walkableRegions、doorways、warnings、qaChecks。qaChecks 至少检查：所有坐标在画布内；门洞没有被墙矩形覆盖；发光像素没有碰撞；楼梯踏步没有被整块封死；动态对象隐藏时没有残留碰撞；每个对象有中文 label。
```

## 4. 逐图分册

- [5 张母图：空气墙、门洞、走廊、遮挡和物品表](./2026-08-20-chapter4-airwall-occlusion-base-prompts.md)
- [9 张时间态：动态碰撞、光照非碰撞和状态差异](./2026-08-20-chapter4-airwall-occlusion-state-prompts.md)
- [6 张精灵表：切片、Alpha、pivot、碰撞盒和深度](./2026-08-20-chapter4-airwall-occlusion-sprite-prompts.md)

## 5. 二十张图片覆盖表

| 序号 | 图片 | 分册 |
| ---: | --- | --- |
| 1 | `base/chapter4_a1_base_v01.png` | 母图 |
| 2 | `base/chapter4_a2_base_v01.png` | 母图 |
| 3 | `base/chapter4_a2_base_v02.png` | 母图 |
| 4 | `base/chapter4_a3_base_v01.png` | 母图 |
| 5 | `base/chapter4_a3_base_v02.png` | 母图 |
| 6 | `overlays/chapter4_a1_0754_blackout_v01.png` | 时间态 |
| 7 | `overlays/chapter4_a1_0755_morning_v01.png` | 时间态 |
| 8 | `overlays/chapter4_a1_1225_bakery_v01.png` | 时间态 |
| 9 | `overlays/chapter4_a1_2245_maintenance_v01.png` | 时间态 |
| 10 | `overlays/chapter4_a1_2245_opening_v01.png` | 时间态 |
| 11 | `overlays/chapter4_a2_0754_chase_v01.png` | 时间态 |
| 12 | `overlays/chapter4_a2_1850_evening_v01.png` | 时间态 |
| 13 | `overlays/chapter4_a2_lecture_final_minute_v01.png` | 时间态 |
| 14 | `overlays/chapter4_a3_1850_reference_v01.png` | 时间态 |
| 15 | `sprites/chapter4_a2_dynamic_structures_v01.png` | 精灵表 |
| 16 | `sprites/chapter4_a2_room204_dark_residual_v02.png` | 精灵表 |
| 17 | `sprites/chapter4_a2_room204_furniture_v02.png` | 精灵表 |
| 18 | `sprites/chapter4_clock_states_v01.png` | 精灵表 |
| 19 | `sprites/chapter4_power_panel_states_v01.png` | 精灵表 |
| 20 | `sprites/chapter4_story_items_v01.png` | 精灵表 |

## 6. 必须报告的生成图问题

识图模型不能掩盖以下问题：

1. `1671×941` 图片不能横向拉伸到 `1672×941`；需要补右侧 1 像素并重新校准。
2. A1 面包坊与大厅之间缺少可信门洞时，应报告不可达，不能添加穿墙入口。
3. A2/A3 的不同版本具有不同门洞和交通核心，不能跨版本复用同一组坐标。
4. 时间态的明暗区域不改变碰撞；只有实际出现的门扇、隔断、栏杆和家具能改变阻挡。
5. 透明精灵表禁止直接执行 `alpha-to-collision`；辉光、阴影、残影和状态灯会产生错误空气墙。
6. 所有坐标提示都是预标注。运行时接入前必须完成实图采样、门洞连通、玩家脚部盒停靠和前景遮挡四项验证。
