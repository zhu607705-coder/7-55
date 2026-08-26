# 紫金港动态时间与天气美术提示词 v01

## 1. 使用边界

- `src/assets/rpg/campus/zijingang_campus_plate.png` 继续作为 `4516 × 3420` 正式地图、坐标、碰撞、入口和建筑关系的唯一基准。
- 本文生成的整图用于天气美术定调、颜色采样和图层拆分参考。生成模型可能改变建筑细节，禁止直接替换正式地图或据此重标碰撞。
- 正式运行时使用“固定底图 + 时间调色 + 天气效果 + 地表响应 + 水面响应”的可组合结构。
- 时间、天气和剧情阶段由 TypeScript controller 保存和校验；图片只负责表现，不写入剧情事实。
- 角色、车辆、皮划艇、船桨、天鹅、鱼、纸张、任务标记、提示牌和 UI 均保持动态对象，禁止烘焙进背景。

## 2. 一致性总提示词

以下内容放在每次紫金港天气生成提示词的最前面：

```text
Use case: lighting-weather
Asset type: 2D top-down pixel-art game map weather variant and consistency reference for Zhejiang University Zijingang campus.
Input image 1 is the edit target and strict geometry reference. Preserve its exact north-up top-down projection, complete full-map framing, source-pixel spatial relationships, roads, crosswalks, building footprints, courtyards, sports fields, trees, rivers, lakes, bridges, gates, entrances, and collision-readable boundaries.
Keep the original campus identity, pixel density, map scale, and gameplay readability. Change only environmental lighting, atmosphere, surface response, water response, and weather particles explicitly requested below.
Style: polished 2D pixel art, crisp hard pixel edges, consistent top-down RPG tileset language, no painterly blur, no photorealism.
Composition constraints: no crop, rotation, skew, projection change, non-uniform scaling, district resizing, topology change, added or removed structures, moved shoreline, or changed entrance silhouette.
Content constraints: no characters, no vehicles, no boats, no kayaks, no paddles, no UI, no labels, no text, no logos, no watermark.
```

## 3. 可组合状态模型

```ts
type CampusTimeOfDay = "dawn" | "morning" | "noon" | "dusk" | "night";
type CampusWeather = "clear" | "overcast_dry" | "light_rain" | "post_rain";
type SurfaceState = "dry" | "wet" | "puddled";
type WindState = "calm" | "breeze" | "gust";
type WaterState = "calm" | "rippled" | "choppy";
type VisibilityState = "good" | "reduced" | "poor";

interface CampusAtmosphereState {
  timeOfDay: CampusTimeOfDay;
  minuteOfDay: number;
  weather: CampusWeather;
  surface: SurfaceState;
  wind: WindState;
  water: WaterState;
  visibility: VisibilityState;
  precipitation: "none" | "light";
  transitionSettled: boolean;
}
```

同一时间可配不同天气，同一天气也可换到其他时间。时间只改变色温、亮度、阴影方向和灯光；天气只改变云层影响、降水、湿润度、雾、风和水面。两者禁止合成一个不可拆分的枚举。

## 4. 运行时图层合同

从下到上保持以下顺序：

1. `basePlate`：正式紫金港底图，完全不变。
2. `timeGrade`：时间调色 LUT 或全屏混合层。
3. `cloudShadow`：低频、低透明度云影；只在阴天、雨天和雨后启用。
4. `surfaceResponse`：湿路反光、局部浅水、高光；使用固定掩模，禁止改变碰撞。
5. `waterResponse`：水面涟漪、雨点和风浪；只覆盖现有水域掩模。
6. `weatherParticles`：雨线、细雾和偶发落叶；跟随相机，不能成为碰撞对象。
7. `dynamicWorld`：角色、车辆、任务物品、皮划艇、天鹅等动态对象。
8. `foregroundOcclusion`：现有建筑和树冠前景遮挡。
9. `hud`：任务、天气说明和交互反馈。

## 5. 四个紫金港完整提示词

### 5.1 晴朗清晨 07:55

```text
Primary request: change only the weather and environmental lighting to a clear, dry Hangzhou morning at 07:55 after an overnight cold front. Use clean pale-gold sunlight from the upper left, crisp but short soft-edged shadows, a bright blue sky influence on water, dry roads, clear distant visibility, fresh green foliage, and small sun glints on lakes and rivers. The scene must remain easy to read as a playable RPG map.
Lighting and mood: calm clear early morning, high readability, inviting but restrained saturation.
Color palette: warm pale sunlight, fresh green, clean blue water, charcoal roads, original brick and concrete identity colors.
Materials: dry asphalt and stone, dew only on grass and leaves, restrained sun glints on water.
Negative constraints: no rain, no puddles, no wet road reflections, no mist that hides entrances, no new objects, no topology changes.
```

建议状态：`morning + clear + dry + calm + calm + good`。

### 5.2 无降水阴天 09:30

```text
Primary request: change only weather and environmental lighting to a dry overcast Hangzhou morning around 09:30. There is no falling rain and no active precipitation. Use a continuous pale gray cloud deck, cool diffuse shadowless light, dry but slightly dark asphalt, soft low-contrast building surfaces, calm water with broad restrained ripples, and a light breeze visible only through subtle tree-canopy variation. Visibility is good and all gameplay routes remain highly readable.
Lighting and mood: quiet dry overcast campus, cool neutral mood, stable visibility, safe non-storm conditions.
Color palette: cool concrete gray, restrained green, desaturated blue water, charcoal dry roads, original brick colors.
Materials: dry asphalt and stone, matte roofs, calm lightly rippled water, no puddles, no mirror-like wet reflections.
Negative constraints: no rain streaks, no rain impacts, no puddles, no storm darkness, no new objects, no topology changes.
```

建议状态：`morning + overcast_dry + dry + breeze + rippled + good`。

### 5.3 小雨清晨 07:55

```text
Primary request: transform only the weather and environmental lighting into a Hangzhou light-rain morning at 07:55. The rain is steady but not stormy. Add cool blue-gray overcast ambient light, fine diagonal rain streaks, small circular splash pixels on roads and lake surfaces, subtle wet asphalt reflections, darker wet tree foliage, muted building highlights, slightly stronger water ripples, and a thin low mist over distant open lawns.
Lighting and mood: cool rainy early morning, readable and cautious, enough contrast to distinguish roads, walkable lawns, water edges, bridges, and building entrances.
Color palette: cool slate blue, desaturated green, wet charcoal roads, subdued warm brick; preserve original identity colors under the weather grade.
Materials: wet asphalt, damp stone, wet leaves, rain-dimpled water, restrained puddle highlights only on plausible flat surfaces.
Negative constraints: no severe storm, no flooding, no changed water level, no hidden entrances, no new objects, no topology changes.
```

建议状态：`morning + light_rain + wet + breeze + choppy + reduced`。

### 5.4 雨后转晴 16:40

```text
Primary request: change only weather, lighting, and surface response to a Hangzhou post-rain clearing period around 16:40. Falling rain has completely stopped. Broken gray clouds reveal warm low sunlight from the upper left. Roads and stone paths remain wet, with restrained narrow reflections and a few shallow puddle highlights. Trees are dark and freshly washed. Lake and river surfaces still show medium ripples left by the rain, but no dangerous waves. Visibility is rapidly improving. The image should read as a transition state between rainy investigation and safe outdoor travel.
Lighting and mood: clearing weather, wet surfaces, warm light returning through cool cloud cover, high gameplay readability.
Color palette: cool rain-washed blue-gray shadows, fresh deep greens, subdued warm amber highlights, dark wet charcoal roads, original brick and concrete identity colors.
Materials: wet asphalt, damp stone, washed foliage, sparse shallow puddles, medium water ripples, no active rain streaks or splash circles.
Negative constraints: no falling rain, no storm darkness, no water-level change, no new objects, no topology changes.
```

建议状态：`dusk + post_rain + wet + breeze + rippled + good`。进入此状态后仍需等待 `transitionSettled=true` 才能重新开放水上流程。

## 6. 启真湖码头雨天完整提示词

以 `src/assets/rpg/interiors/qizhen_lake_dock.png` 为输入图：

```text
Use case: lighting-weather
Asset type: 2D top-down pixel-art game map weather reference for the Qizhen Lake kayak dock.
Input image 1 is the edit target and strict geometry reference. Preserve the exact 1672 by 941 top-down projection, full framing, lake shoreline, stone plaza, paths, wooden dock, steps, railings, vegetation, trees, lights, benches, roof shapes, walkable routes, and every spatial relationship.
Primary request: change only weather, environmental lighting, and water/surface response to a steady Hangzhou light-rain period that is visibly unsuitable for launching a recreational kayak. Add fine diagonal pixel rain, repeated small circular rain impacts across the water, visibly stronger short choppy ripples near the dock, wet darkened timber planks, slick stone with restrained broken reflections, darker saturated foliage, cool blue-gray overcast ambient light, and a little mist over the far water. Keep the disturbance readable without depicting a severe storm or flooding.
Style: polished 2D top-down pixel art matching the original asset's pixel density, crisp hard pixel edges, no painterly blur, no photorealism.
Composition constraints: preserve the full source-pixel layout, shoreline, dock collision edges, paths, and existing object locations. No crop, rotation, skew, non-uniform scaling, projection change, water-level change, added or removed structures, or moved shoreline.
Content constraints: no characters, kayak, boat, paddles, swans, fish, paper, safety signs, props, UI, labels, text, logos, or watermark.
```

## 7. 天气对应的游戏流程

| 天气 | 校园流程 | 启真湖岸边流程 | 是否允许下水 | 玩家可见原因与下一步 |
| --- | --- | --- | --- | --- |
| 晴朗 | 常规路线；远处地标和干燥纸面线索清晰 | 正常码头检查与登艇教学 | 允许 | `天气稳定，完成码头检查后可以下水。` |
| 无降水阴天 | 常规路线；阴影线索减弱，声音和位置线索权重提高 | 检查风向旗、水面和救生设备 | 低风时允许 | `没有降水，水面平稳；检查装备后可以下水。` |
| 小雨 | 开启屋檐、连廊和积水绕行；湿纸轨迹与反光线索增强 | 码头关闭；沿岸寻找湿纸、漂移方向和停航记录 | 禁止 | `小雨持续，码头暂停下水；沿岸调查湿纸轨迹。` |
| 雨后转晴 | 湿路反光保留；云隙光和残留积水提供过渡线索 | 先检查风、水面和能见度；通过后开放登艇 | 条件允许 | `降雨已停，水面仍在恢复；完成安全检查。` |

雨天不会让主线停住。玩家在岸上完成的调查应为后续划船提供有效收益，例如：提前标记漂流方向、缩小第一片水域的搜索范围、记录障碍位置、获得一次安全重置点。

## 8. 皮划艇开放条件

```ts
function canLaunchKayak(atmosphere: CampusAtmosphereState): boolean {
  return atmosphere.precipitation === "none"
    && atmosphere.wind !== "gust"
    && atmosphere.water !== "choppy"
    && atmosphere.visibility !== "poor"
    && atmosphere.transitionSettled;
}
```

controller 应返回结构化结果：

```ts
type KayakLaunchResult =
  | { accepted: true }
  | {
      accepted: false;
      reason: "active_rain" | "strong_wind" | "choppy_water" | "poor_visibility" | "weather_transition";
      nextObjective: string;
    };
```

建议反馈：

- `active_rain`：`小雨持续，暂停下水；沿岸调查湿纸轨迹。`
- `strong_wind`：`阵风过强，暂停下水；检查风向旗并返回避风处。`
- `choppy_water`：`近岸水面仍有短浪；完成岸边线索记录后再检查一次。`
- `poor_visibility`：`湖面能见度不足；先从岸边确认浮标与回航路线。`
- `weather_transition`：`雨已停，安全检查尚未完成；依次确认风、水面和能见度。`

## 9. 时间调节规则

- 时间变化不能重载地图、重置任务、移动角色或改变碰撞。
- `minuteOfDay` 只驱动太阳角度、色温、环境亮度、灯光开关和阴影强度。
- 天气切换保留当前时间；例如 `07:55 clear → 07:55 light_rain` 只更新天气图层。
- 调整时间保留当前天气；例如 `light_rain 07:55 → light_rain 16:40` 只更新调色与光照。
- 夜间最低可读亮度应保证道路、水岸、入口和可交互轮廓仍可辨识。
- 每次转换使用固定时长过渡，不使用瞬间闪切；任务规则在 controller 状态切换完成后生效。

## 10. 已生成参考图

- `src/assets/rpg/campus/weather/zijingang_weather_clear_0755_concept_v01.png`
- `src/assets/rpg/campus/weather/zijingang_weather_overcast_dry_concept_v01.png`
- `src/assets/rpg/campus/weather/zijingang_weather_rain_0755_concept_v01.png`
- `src/assets/rpg/campus/weather/zijingang_weather_post_rain_1640_concept_v01.png`
- `src/assets/rpg/interiors/weather/qizhen_lake_dock_rain_concept_v01.png`

这些文件是设计参考。正式运行图层应从原图提取水域、道路、屋顶、植被与天空影响区域的固定掩模，再叠加可调参数，避免生成图造成坐标漂移。
