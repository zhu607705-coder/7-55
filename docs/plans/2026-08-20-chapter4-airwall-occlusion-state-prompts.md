# 第四章时间态场景空气墙与遮挡识图提示词

## 1. 适用范围

本文档逐张覆盖 `artifacts/chapter4-map-assets-20260820/overlays/` 下的 9 张时间态候选图，只依据当前候选图可见内容记录空气墙、动态门、光照非碰撞区域、遮挡深度和物品坐标。候选图尚未接入运行时，本文件中的坐标需要在选定最终母图后做像素级复核。

坐标与实现约定：

- 原点为左上角，单位为源图像素。
- 预标注矩形统一使用半开边界 `[x0,y0,x1,y1)`；`x1`、`y1` 不属于矩形。多边形格式为 `poly[(x1,y1),...]`。
- 逐图模型最终输出中的矩形必须转换为对象式 `{x,y,width,height}`，其中 `x=x0`、`y=y0`、`width=x1-x0`、`height=y1-y0`；禁止在最终 JSON 中保留四元组矩形。
- 下列所有目测坐标均明确标记 `approximate=true`。
- 角色碰撞以脚底锚点和物体底部 footprint 为准，禁止直接用整张物体美术包围盒作为碰撞体。
- 遮挡深度采用统一规则：`actor.footY < object.baselineY` 时物体绘制在角色前方；`actor.footY >= object.baselineY` 时角色绘制在物体前方。
- 灯光、阴影、窗光、黑暗遮罩、投影白屏、地面高光和紧急灯光池一律 `collision=false`。
- 看不到门扇或隔断实体时不得设置隐形碰撞；运行时显示对应精灵后，再启用与精灵同坐标的 collider。
- `1671×941` 图片应在右侧补 1 px 后统一到 `1672×941`，禁止横向拉伸。

## 2. A1 共用固定碰撞与遮挡表

适用于五张 A1 时间态图。

### 2.1 固定墙与建筑边界

- 北墙左段 `[45,17,734,154)`，`approximate=true`。
- 电梯与楼梯之间北墙 `[815,17,936,154)`，`approximate=true`。
- 北墙右段 `[1047,17,1627,154)`，`approximate=true`。
- 西外墙 `[14,16,53,906)`，`approximate=true`。
- 东外墙 `[1616,16,1660,906)`，`approximate=true`。
- 面包坊东墙 `[487,143,529,790)`，`approximate=true`。
- 面包坊南墙 `[47,783,529,860)`，`approximate=true`。
- 104/105 西墙分段：
  - `[1183,143,1222,283)`，`approximate=true`。
  - `[1183,354,1222,567)`，`approximate=true`。
  - `[1183,646,1222,802)`，`approximate=true`。
- 104/105 中间横墙 `[1183,472,1622,506)`，`approximate=true`。
- 东侧教室南墙 `[1183,787,1622,859)`，`approximate=true`。
- 大厅南侧非入口墙：
  - `[529,844,654,906)`，`approximate=true`。
  - `[1029,844,1184,906)`，`approximate=true`。

### 2.2 固定物品、动态门与遮挡

- 电梯门/门槛 `[735,56,815,158)`，`approximate=true`；关闭时为动态 gate，开启时移除门洞碰撞。
- 楼梯左扶手 `[938,120,956,231)`，`approximate=true`。
- 楼梯右扶手 `[1028,120,1047,231)`，`approximate=true`。
- 楼梯踏步区 `[956,145,1028,231)`，`approximate=true`；作为楼层切换区，不设置整块空气墙。
- 旧钟 `[943,11,1047,121)`，`approximate=true`；墙面物品，`collision=false`。
- 左植物座岛 `[640,240,752,515)`，`approximate=true`，`baselineY=509`。
- 右植物座岛 `[919,240,1035,515)`，`approximate=true`，`baselineY=509`。
- 接待台 `[748,577,934,688)`，`approximate=true`，`baselineY=680`。
- 主入口左玻璃与框架 `[654,735,774,889)`，`approximate=true`。
- 主入口右玻璃与框架 `[914,735,1030,889)`，`approximate=true`。
- 主入口双门 gate `[774,834,914,889)`，`approximate=true`；关闭时碰撞，开启时成为出入口 trigger。
- 入口左花池 `[590,807,657,889)`，`approximate=true`，`baselineY=885`。
- 入口右花池 `[1027,807,1106,889)`，`approximate=true`，`baselineY=885`。
- 面包坊烤炉组 `[99,170,296,270)`，`approximate=true`，`baselineY=266`。
- 面包架 `[302,169,431,271)`，`approximate=true`，`baselineY=268`。
- 面包坊柜台 `[82,289,472,383)`，`approximate=true`，`baselineY=377`。
- 面包坊六组桌椅：
  - `[119,432,210,531)`，`approximate=true`。
  - `[235,432,326,531)`，`approximate=true`。
  - `[346,432,437,531)`，`approximate=true`。
  - `[119,551,210,650)`，`approximate=true`。
  - `[235,551,326,650)`，`approximate=true`。
  - `[346,551,437,650)`，`approximate=true`。
- 配电/储物立柜 `[487,332,528,510)`，`approximate=true`，`baselineY=506`。
- 104 开门门扇 `[1197,282,1255,354)`，`approximate=true`；只碰撞可见门板，门洞保持可走。
- 105 开门门扇 `[1197,568,1255,646)`，`approximate=true`；只碰撞可见门板，门洞保持可走。
- 104 座席区 `[1268,282,1574,475)`，`approximate=true`；按三排分别设置 collider，避免封死排间通道，遮挡基线约 `341/408/474`。
- 105 座席区 `[1268,614,1574,800)`，`approximate=true`；按三排分别设置 collider，遮挡基线约 `671/736/800`。
- 104 讲桌 `[1376,224,1445,283)`，`approximate=true`，`baselineY=279`。
- 105 讲桌 `[1376,510,1445,590)`，`approximate=true`，`baselineY=585`。
- 东墙公告板 `[1616,651,1665,735)`，`approximate=true`；墙面物品，`collision=false`。

识图缺陷：中央大厅与面包坊之间未出现清楚门洞。当前图应把面包坊东墙视为连续实体墙。若剧情要求从大厅进入面包坊，需要先补画门洞，不能直接添加穿墙入口。

## 3. A1 07:54 断电追逐

文件：`chapter4_a1_0754_blackout_v01.png`

- 尺寸：`1672×941`。
- 相对母图：固定墙、门洞、植物座岛、接待台、教室和面包坊家具均应保持不变；未见新增实体。
- 动态碰撞：主入口、电梯按运行时开关状态启停 gate；104、105 门扇可见为开启状态，只碰撞门板；未看到面包坊卷帘门，不能设置卷帘门隐形碰撞。
- 光照非碰撞：入口至楼梯冷白光路约为 `[773,147,909,908)`，`approximate=true`；三处北墙应急灯光池、入口反光、全图深蓝黑遮罩均 `collision=false`。
- 遮挡：两座植物岛、接待台、入口玻璃前景、房间南墙沿用 A1 基线；黑暗不得改变遮挡深度。
- 物品表：旧钟、电梯、楼梯、两座植物岛、接待台、玻璃入口、面包坊烤炉/面包架/柜台/六组桌椅、两间教室座席和讲桌、公告板。
- 风险：亮区是视觉引导，禁止把两侧暗区转为空气墙。

逐图提示词：

```text
读取 chapter4_a1_0754_blackout_v01.png，源尺寸 1672×941，坐标原点为左上角，单位为源像素。输出 collision_occlusion_manifest JSON。所有目测坐标写 approximate:true。下文矩形预标注均为半开边界 [x0,y0,x1,y1)，最终 JSON 必须换算为对象 {x,y,width,height}，其中 width=x1-x0、height=y1-y0，禁止输出四元组矩形。

固定碰撞使用 A1 固定墙与物品表：北墙三段、东西外墙、面包坊东/南墙、104/105 分段墙、教室中间横墙、教室南墙、大厅南侧墙；电梯门为动态 gate；楼梯只碰撞左右扶手，踏步为楼层切换 trigger；两个植物座岛、接待台、入口花池、面包坊固定设备与桌椅、教室固定座席均设置物理 footprint。104/105 可见开门仅碰撞门板，门洞保持通行。

入口至楼梯的冷白光路 [773,147,909,908) approximate:true、应急灯、手机环境亮度、玻璃反光、阴影和深蓝黑遮罩全部标记 collision:false。禁止依据亮暗边缘新增空气墙。遮挡按 actor.footY 与各物体 baselineY 比较；植物 baselineY=509，接待台 baselineY=680，入口前景 baselineY=885。输出 walls、dynamicGates、solidObjects、occluders、triggers、nonCollidingVisuals、warnings 七个数组。
```

## 4. A1 07:55 清晨

文件：`chapter4_a1_0755_morning_v01.png`

- 尺寸：`1672×941`。
- 相对母图：固定结构不变；墙上肖像变为空框，只属于贴图内容变化。
- 动态碰撞：104、105 门扇显示为开启状态；主入口和电梯继续按 runtime 状态控制；面包坊卷帘门在图中无法辨认，不应新增碰撞。
- 光照非碰撞：南入口晨光向西北投射的大面积光斑约 `poly[(690,897),(1005,897),(629,574),(572,574)]`，`approximate=true`；教室和面包坊局部亮度差、墙灯、玻璃反光均 `collision=false`。
- 遮挡：沿用 A1；空肖像框和黑板不参与地面碰撞。
- 物品表：A1 固定物品全部存在；没有签到纸、校园卡、人物或新增地面道具。
- 风险：清晨图中的面包坊仍展示面包且未出现明确关闭卷帘，碰撞层不得自行推断卷帘位置。

逐图提示词：

```text
读取 chapter4_a1_0755_morning_v01.png，源尺寸 1672×941，以左上角为原点。生成逐物体碰撞与遮挡 JSON，所有目测坐标写 approximate:true。下文矩形预标注均为半开边界 [x0,y0,x1,y1)，最终 JSON 必须换算为对象 {x,y,width,height}，其中 width=x1-x0、height=y1-y0，禁止输出四元组矩形。

沿用 A1 固定墙与固定物品碰撞坐标。104/105 可见门扇设置 door_leaf collider，门洞保持开放；电梯和主入口使用动态 gate。墙上空肖像、黑板、公告板、旧钟均属于墙面装饰，不建立地面 collider。

晨光多边形 poly[(690,897),(1005,897),(629,574),(572,574)] approximate:true、窗光、反射、阴影与局部暗部全部 collision:false。不得根据晨光边缘或未照亮区域添加空气墙。面包坊卷帘在图中不可见，warnings 中记录“缺少可校准卷帘实体”，不得生成隐形卷帘碰撞。遮挡继续使用植物 baselineY=509、接待台 baselineY=680、入口框架 baselineY=885，并输出所有房间固定家具的名称、bounds、baselineY 和 collision 类型。
```

## 5. A1 12:25 面包坊营业

文件：`chapter4_a1_1225_bakery_v01.png`

- 尺寸：`1671×941`；使用前需右侧补 1 px。
- 相对母图：固定结构应保持不变；新增一排面包坊排队栏杆；烤炉火光、展示柜高光和正午光斑属于材质/光照变化。
- 新增空气墙：
  - 排队绳线约 `[129,398,454,417)`，`approximate=true`。
  - 六个栏杆底座中心约 `(132,440)`、`(196,440)`、`(260,440)`、`(325,440)`、`(389,440)`、`(453,440)`，每项 `approximate=true`。
  - 每个底座建议圆形 collider 半径约 `9 px`，绳线建议厚度 `8–10 px`，左右两端至少保留一处可通行缺口。
- 动态门：图中未出现可辨认卷帘；不能将营业状态直接换算为门碰撞。
- 光照非碰撞：面包坊暖光、南侧及西侧斜向日照、展示柜和烤炉亮点全部 `collision=false`。
- 遮挡：排队杆为低矮物体，`baselineY≈449`；其余沿用 A1。
- 新增物品：六个排队栏杆底座及连接绳。

逐图提示词：

```text
读取 chapter4_a1_1225_bakery_v01.png，源尺寸 1671×941。先在元数据中标记 requiresCanvasNormalization:true，recommendedNormalization:"padRight1px,noScale"。坐标原点左上，全部目测坐标 approximate:true。下文矩形预标注均为半开边界 [x0,y0,x1,y1)，最终 JSON 必须换算为对象 {x,y,width,height}，其中 width=x1-x0、height=y1-y0，禁止输出四元组矩形。

沿用 A1 固定墙、固定家具和遮挡坐标。新增 queue_barrier：连接绳 bounds=[129,398,454,417) approximate:true，厚度 8 到 10 像素；六个底座中心分别为 (132,440)、(196,440)、(260,440)、(325,440)、(389,440)、(453,440)，每项 approximate:true，圆形 footprint 半径约 9 像素。两端通道不得被扩大的 collider 封死。排队杆 baselineY=449。

正午斜光、烤炉火光、面包和玻璃高光、墙灯和阴影均 collision:false。图中没有可辨认卷帘门，禁止添加隐形卷帘 collider，在 warnings 中注明。输出新增对象与母图不变对象的差异清单，并输出 walls、dynamicGates、solidObjects、occluders、nonCollidingVisuals。
```

## 6. A1 22:45 修钟/清楼

文件：`chapter4_a1_2245_maintenance_v01.png`

- 尺寸：`1672×941`。
- 相对母图：未见新增清洁车、撬棍、油瓶或实体作业灯；固定结构应保持不变。
- 动态碰撞：电梯、入口 gate 按 runtime 状态；教室门保持可见开启门扇规则；未出现保洁车，当前图不得预留不可见保洁车空气墙。
- 光照非碰撞：
  - 面包坊局部作业光约 `[67,149,468,655)`，`approximate=true`。
  - 大厅中央顶部暖光池约 `[681,139,1133,477)`，`approximate=true`。
  - 接待台至入口灯带约 `[733,537,1143,900)`，`approximate=true`。
  - 东侧教室门口灯光均 `collision=false`。
- 遮挡：沿用 A1；光照分段不改变 depth。
- 物品表：只有 A1 固定物品；剧情所需保洁车、撬棍、润滑油均未烘焙。

逐图提示词：

```text
读取 chapter4_a1_2245_maintenance_v01.png，1672×941，左上原点，全部目测坐标 approximate:true。下文矩形预标注均为半开边界 [x0,y0,x1,y1)，最终 JSON 必须换算为对象 {x,y,width,height}，其中 width=x1-x0、height=y1-y0，禁止输出四元组矩形。沿用 A1 固定墙、家具、入口、电梯、楼梯、植物座岛和教室门碰撞。

把面包坊局部光 [67,149,468,655)、大厅顶部光 [681,139,1133,477)、接待台至入口光 [733,537,1143,900) 以及所有墙灯光晕标为 collision:false。禁止把亮区边缘、暗角或巡逻视野写入 wall 数组。

当前图没有保洁车、撬棍、润滑油和可见作业灯实体，因此不生成对应 collider。为后续 runtimeObjects 输出规则：只有当透明精灵出现时，按其脚部 footprint 建立 collider，并用精灵底边作为 baselineY；精灵隐藏后立即移除 collider。输出固定对象、动态 gate、遮挡物、非碰撞光照和缺失动态物 warnings。
```

## 7. A1 22:45 开场

文件：`chapter4_a1_2245_opening_v01.png`

- 尺寸：`1671×941`；使用前需右侧补 1 px。
- 相对母图：只观察到夜色、室内灯光和墙面画框内容变化；未见新增实体。
- 动态碰撞：电梯和入口按运行时 gate；104/105 可见开门门扇沿用 A1；面包坊卷帘门状态无法从图中辨认。
- 光照非碰撞：大厅主光区约 `[522,139,1187,832)`，`approximate=true`；南入口冷蓝反光约 `[654,736,1028,931)`，`approximate=true`；西面包坊和东教室低照度区域均 `collision=false`。
- 遮挡：沿用 A1。
- 物品表：A1 固定物品；无纸条、旧时针、人物或移动障碍。
- 风险：宽度少 1 px；未显示可校准卷帘门实体。

逐图提示词：

```text
读取 chapter4_a1_2245_opening_v01.png，源尺寸 1671×941。输出 requiresCanvasNormalization:true 和 recommendedNormalization:"padRight1px,noScale"。坐标原点左上，所有目测坐标 approximate:true。下文矩形预标注均为半开边界 [x0,y0,x1,y1)，最终 JSON 必须换算为对象 {x,y,width,height}，其中 width=x1-x0、height=y1-y0，禁止输出四元组矩形。

沿用 A1 固定墙及固定物品碰撞。电梯门和主入口为动态 gate；104/105 的开门门扇只碰撞可见门板。大厅主光区 [522,139,1187,832) approximate:true、入口蓝色反光 [654,736,1028,931) approximate:true、玻璃高光、墙灯、阴影、低照度区域全部 collision:false。不得用光线轮廓缩小可走区域。

图中没有人物、纸条、旧时针或移动障碍；面包坊卷帘不可辨认，不生成隐形碰撞并加入 warning。遮挡按 A1 baselineY 规则输出。
```

## 8. A2 共用固定碰撞与遮挡表

适用于三张 A2 时间态图。

### 8.1 固定墙、门洞与交通核心

- 西外墙 `[12,18,53,879)`，`approximate=true`。
- 东外墙 `[1618,18,1661,879)`，`approximate=true`。
- 南外墙/窗带 `[12,865,1661,929)`，`approximate=true`。
- 电梯 `[739,29,847,145)`，`approximate=true`；门为动态 gate。
- 楼梯左扶手 `[893,19,915,198)`，`approximate=true`。
- 楼梯右扶手 `[1032,19,1054,198)`，`approximate=true`。
- 楼梯踏步 `[915,54,1032,198)`，`approximate=true`；作为楼层 trigger。
- 201 南门洞 `[278,336,380,379)`，`approximate=true`。
- 202 南门洞 `[1299,334,1407,379)`，`approximate=true`。
- 204 北门洞 `[278,500,380,543)`，`approximate=true`。
- 203 北门洞 `[1299,500,1407,543)`，`approximate=true`。
- 门洞两侧墙体分别设置分段 collider，禁止用整条房间墙封住门洞。

### 8.2 固定物品、遮挡和动态结构

- 左植物座岛 `[630,244,748,469)`，`approximate=true`，`baselineY=466`。
- 右植物座岛 `[920,244,1031,469)`，`approximate=true`，`baselineY=466`。
- 中央书架与两端花盆 `[628,546,1058,615)`，`approximate=true`，`baselineY=610`。
- 西休息岛 `[621,667,808,808)`，`approximate=true`，`baselineY=802`。
- 东休息岛 `[878,667,1062,808)`，`approximate=true`，`baselineY=802`。
- 201 工具墙/后柜 `[90,52,529,157)`，`approximate=true`。
- 201 主工作台 `[181,171,471,267)`，`approximate=true`，`baselineY=264`。
- 201 南工作台 `[115,299,484,340)`，`approximate=true`，`baselineY=337`。
- 202 黑板和幕布 `[1208,54,1577,130)`，`approximate=true`，墙面物品。
- 202 讲台 `[1308,130,1384,190)`，`approximate=true`，`baselineY=187`。
- 202 三排阶梯座席：
  - `[1227,211,1551,263)`，`approximate=true`。
  - `[1227,261,1551,311)`，`approximate=true`。
  - `[1227,309,1551,337)`，`approximate=true`。
- 204 投影屏 `[245,519,355,575)`，`approximate=true`，墙面物品。
- 204 小讲台 `[179,549,220,601)`，`approximate=true`，`baselineY=597`。
- 204 地面定位点网格约位于 `[96,617,480,830)`，`approximate=true`，`collision=false`。
- 203 三排电脑桌：
  - `[1219,590,1559,663)`，`approximate=true`。
  - `[1219,684,1559,756)`，`approximate=true`。
  - `[1219,779,1559,846)`，`approximate=true`。
- 203 两侧设备柜：
  - `[1167,523,1204,611)`，`approximate=true`。
  - `[1577,522,1614,611)`，`approximate=true`。

动态隔断与 203 门扇在三张场景图中均未清楚出现，因此默认 `collision=false`；精灵显示后才能启用。

## 9. A2 07:54 最终追逐

文件：`chapter4_a2_0754_chase_v01.png`

- 尺寸：`1672×941`。
- 相对母图：固定结构不变；未见动态隔断或独立门扇。
- 动态碰撞：四个房间门洞当前按开放处理；202 门槛 `[1299,334,1407,379)`，`approximate=true`，应作为完成 trigger；203 动态门不可见，不能启用 collider。
- 光照非碰撞：
  - 楼梯下方光池约 `[906,116,1055,338)`，`approximate=true`。
  - 201 门灯约 `[273,334,383,432)`，`approximate=true`。
  - 204 门灯约 `[273,499,383,579)`，`approximate=true`。
  - 203 门灯约 `[1296,499,1410,580)`，`approximate=true`。
  - 202 室内暖光 `[1160,42,1618,340)`，`approximate=true`。
- 遮挡：沿用 A2；黑暗不改变书架、座岛和家具 depth。
- 物品表：A2 全部固定物品；无可见追逐 NPC、隔断、门扇或任务道具。
- 风险：楼梯到 202 门口之间的中间走廊偏暗，光路没有形成连续视觉带；不得用空气墙强制玩家沿亮区移动。

逐图提示词：

```text
读取 chapter4_a2_0754_chase_v01.png，1672×941，左上原点，全部目测坐标 approximate:true。下文矩形预标注均为半开边界 [x0,y0,x1,y1)，最终 JSON 必须换算为对象 {x,y,width,height}，其中 width=x1-x0、height=y1-y0，禁止输出四元组矩形。沿用 A2 固定墙、交通核心、植物座岛、书架、休息岛和四个房间固定家具的碰撞。

四个门洞当前均保持 passable。202 门槛 [1299,334,1407,379) approximate:true 设置为 chase_finish trigger，collision:false。203 动态门和两组移动隔断在图中不可见，禁止生成隐形 collider。

楼梯光池 [906,116,1055,338)、201 门灯 [273,334,383,432)、204 门灯 [273,499,383,579)、203 门灯 [1296,499,1410,580)、202 暖光 [1160,42,1618,340) 以及全部暗区均 collision:false。warnings 中记录“楼梯到 202 之间缺少连续光带”，但不得用空气墙替代视觉引导。输出完整 walls、solidObjects、occluders、triggers、dynamicGates、nonCollidingVisuals。
```

## 10. A2 18:50 晚课前

文件：`chapter4_a2_1850_evening_v01.png`

- 尺寸：`1672×941`。
- 相对母图：结构不变；204 中央保持空地，仅出现低对比定位点。
- 动态碰撞：204 当前没有可移动桌椅，房间中央不得产生碰撞；所有门洞当前开放；动态隔断与 203 门扇不可见，不启用。
- 光照非碰撞：全图均匀顶灯、蓝色窗带、屏幕反光、204 浅灰投影面均 `collision=false`。
- 遮挡：沿用 A2。
- 物品表：201 工具设备和工作台；202 阶梯座席；204 小讲台、投影屏和定位点；203 三排电脑桌；中央植物岛、书架、两组沙发。
- 风险：204 定位点只承担提示/吸附作用，不能转换为小型障碍。

逐图提示词：

```text
读取 chapter4_a2_1850_evening_v01.png，1672×941，左上原点，全部目测坐标 approximate:true。下文矩形预标注均为半开边界 [x0,y0,x1,y1)，最终 JSON 必须换算为对象 {x,y,width,height}，其中 width=x1-x0、height=y1-y0，禁止输出四元组矩形。按 A2 固定碰撞表输出 manifest。

204 房间定位点区域 [96,617,480,830) approximate:true 全部标记 collision:false、role:"snap_hint"。204 中央没有桌椅，禁止生成任何隐形家具 collider。202、201、203 固定设备与中央座岛、书架、沙发按 footprint 碰撞；墙面黑板、投影屏和窗带不碰撞。

全图晚间顶灯、窗外蓝光、屏幕反光和地面亮度差均加入 nonCollidingVisuals。动态隔断和 203 门扇没有显示，保持 disabled。遮挡使用各固定对象 baselineY，尤其植物 baselineY=466、书架 baselineY=610、休息岛 baselineY=802。
```

## 11. A2 阶梯教室最后一分钟

文件：`chapter4_a2_lecture_final_minute_v01.png`

- 尺寸：`1671×941`；使用前需右侧补 1 px。
- 相对母图：只增加 202 室内暖光与纯白投影区域，固定结构不应改变。
- 动态碰撞：202 门槛约 `[1299,334,1407,379)`，`approximate=true`；画面无法明确区分门扇，默认按可通行 trigger。若剧情要求门关闭，应先叠加独立门精灵，再启用相同位置 gate。其余门洞开放。
- 光照非碰撞：202 暖光 `[1160,40,1618,341)`，`approximate=true`；白色投影区 `[1372,56,1514,120)`，`approximate=true`；门口应急灯和全图深蓝遮罩均 `collision=false`。
- 遮挡：202 三排座席、讲台沿用 A2；投影白屏为墙面视觉层。
- 物品表：202 黑板、投影幕、讲台、三排座席；没有最后一分钟纸条实体。
- 交互点：白屏中心 `(1443,88)`，`approximate=true`，可作为墙面交互射线目标，不作为地面碰撞。

逐图提示词：

```text
读取 chapter4_a2_lecture_final_minute_v01.png，源尺寸 1671×941，输出 requiresCanvasNormalization:true，recommendedNormalization:"padRight1px,noScale"。原点左上，全部目测坐标 approximate:true。下文矩形预标注均为半开边界 [x0,y0,x1,y1)，最终 JSON 必须换算为对象 {x,y,width,height}，其中 width=x1-x0、height=y1-y0，禁止输出四元组矩形。

沿用 A2 固定碰撞。202 门槛 [1299,334,1407,379) approximate:true 当前作为可通行 room_entry trigger；若独立关闭门精灵未显示，不启用 gate。202 三排座席和讲台保持固定 collider 与 baselineY。

202 暖光 [1160,40,1618,341) approximate:true、白色投影区 [1372,56,1514,120) approximate:true、应急灯和暗色覆盖全部 collision:false。白屏中心交互目标 (1443,88) approximate:true 可标记为 wall_interaction_target，不能标记为地面障碍。图中没有最后一分钟纸条实体，在 warnings 中注明道具需 runtime sprite。
```

## 12. A3 共用固定碰撞与遮挡表

适用于当前一张 A3 时间态图。

- 西外墙 `[11,13,49,925)`，`approximate=true`。
- 东外墙 `[1631,12,1662,925)`，`approximate=true`。
- 南墙/窗带 `[11,837,1662,925)`，`approximate=true`。
- 电梯 `[726,10,851,149)`，`approximate=true`；门为动态 gate。
- 楼梯左扶手 `[894,43,915,220)`，`approximate=true`。
- 楼梯右扶手 `[1010,43,1031,220)`，`approximate=true`。
- 楼梯踏步 `[915,72,1010,220)`，`approximate=true`；楼层 trigger。
- 301 南门洞 `[251,369,311,405)`，`approximate=true`。
- 304 南门洞 `[1353,370,1423,405)`，`approximate=true`。
- 302 北门洞 `[251,470,311,503)`，`approximate=true`。
- 303 北门洞 `[1353,470,1423,503)`，`approximate=true`。
- 左植物座岛 `[619,243,718,466)`，`approximate=true`，`baselineY=463`。
- 右植物座岛 `[887,243,984,466)`，`approximate=true`，`baselineY=463`。
- 历史连廊暗门/门槛 `[1046,212,1133,320)`，`approximate=true`；当前按关闭 gate。
- 301 中央档案台 `[159,210,401,299)`，`approximate=true`，`baselineY=296`。
- 301 北侧三组展柜 `[132,117,431,162)`，`approximate=true`。
- 301 南侧展柜 `[130,321,432,376)`，`approximate=true`。
- 304 舞台 `[1263,136,1511,209)`，`approximate=true`，`baselineY=206`。
- 304 左座席块 `[1186,211,1366,370)`，`approximate=true`。
- 304 右座席块 `[1411,211,1603,370)`，`approximate=true`。
- 302 绿幕 `[160,509,352,615)`，`approximate=true`，`baselineY=611`。
- 302 摄像机与灯具：
  - `[63,520,139,765)`，`approximate=true`。
  - `[348,516,407,609)`，`approximate=true`。
  - `[417,502,485,739)`，`approximate=true`。
- 302 控制台 `[141,734,407,825)`，`approximate=true`，`baselineY=821`。
- 303 讲桌 `[1318,557,1465,610)`，`approximate=true`，`baselineY=607`。
- 303 桌椅网格 `[1206,602,1590,829)`，`approximate=true`；按 6 列×4 行逐件设置，行基线约 `657/718/779/834`。
- 荣誉门厅范围 `[606,547,1065,849)`，`approximate=true`。
- 荣誉门厅北侧中央入口 `[716,547,956,578)`，`approximate=true`；作为通道，不能整条封墙。
- 两侧奖杯柜：
  - `[634,592,696,673)`，`approximate=true`。
  - `[975,592,1038,673)`，`approximate=true`。
- 南侧三组展柜 `[683,785,989,846)`，`approximate=true`，`baselineY=842`。
- 荣誉门厅外左侧空白导视牌 `[524,627,596,694)`，`approximate=true`，`baselineY=691`。
- 北侧空白墙框 `[565,113,704,182)`，`approximate=true`；墙面物品，不设置地面碰撞。

## 13. A3 18:50 参照层

文件：`chapter4_a3_1850_reference_v01.png`

- 尺寸：`1672×941`。
- 相对母图：固定墙、展陈、报告厅、媒体室、荣誉厅和 303 标准桌椅布局均不变；只有晚间照明状态。
- 动态碰撞：历史连廊暗门 `[1046,212,1133,320)`，`approximate=true`，当前关闭；301、302、303、304 门洞均按开放处理；电梯按运行时 gate。
- 光照非碰撞：全部顶灯、展柜灯、屏幕白面、窗外蓝色带和地砖明暗均 `collision=false`；历史连廊门内的黑色区域不能单独扩大为空气墙，只使用门槛 gate 阻挡。
- 遮挡：植物岛 `baselineY=463`；档案中央桌 `baselineY=296`；报告厅舞台 `baselineY=206`；绿幕和摄影设备使用各自底座深度；控制台 `baselineY=821`；303 桌椅按四行基线；荣誉厅南侧展柜 `baselineY=842`。
- 物品表：档案展柜、档案桌、地球仪、报告厅幕布/舞台/座席、绿幕、摄影灯、摄像机、设备架、控制台、303 黑板/讲桌/24 组桌椅、荣誉画像和奖杯柜、空白导视牌、连廊暗门。
- 风险：历史连廊门表现为黑色开口，视觉上容易误判为开放；当前剧情规格应明确赋予关闭 gate。

逐图提示词：

```text
读取 chapter4_a3_1850_reference_v01.png，1672×941，左上原点，所有目测坐标 approximate:true。下文矩形预标注均为半开边界 [x0,y0,x1,y1)，最终 JSON 必须换算为对象 {x,y,width,height}，其中 width=x1-x0、height=y1-y0，禁止输出四元组矩形。依据 A3 固定碰撞表输出逐物体 collision_occlusion_manifest。

301、302、303、304 的四个门洞保持开放；电梯为动态 gate；历史连廊暗门 [1046,212,1133,320) approximate:true 设置 state:"closed" 和 collision:true，只在门槛/门板区域阻挡，禁止把门后的黑色画面扩大为整块空气墙。

303 桌椅网格 [1206,602,1590,829) approximate:true 按 6 列×4 行拆分，四行 baselineY 分别约 657、718、779、834。报告厅两块座席、媒体室设备、档案展柜、荣誉厅展柜按可见底座设置 collider 和 occluder。墙面幕布、黑板、肖像、空白墙框不建立地面碰撞。

全部晚间灯光、展柜高光、投影白屏、窗外蓝光和阴影标记 collision:false。输出 walls、doors、solidObjects、occluders、triggers、nonCollidingVisuals、warnings；每个物品必须包含中文 label、bounds、approximate、collision、baselineY 或 wallMounted。
```

## 14. 汇总结论

- 九张图中只有 A1 12:25 的排队栏杆构成清楚的新增实体碰撞。
- A2 三张图都没有显示动态隔断或独立 203 门扇，不能设置隐形墙。
- A3 历史连廊黑门应以门槛 gate 阻挡，黑色区域本身不参与碰撞。
- A1 面包坊缺少从大厅进入的清楚门洞，也缺少可校准卷帘门；需要先修图再落实对应玩法。
- A2 07:54 的追逐光路不够连续；应修正照明，不能用碰撞限制玩家只走亮区。
- 所有时间态仍属于候选场景图，固定碰撞在最终接入前需要和选定母图做像素级叠加校验。
