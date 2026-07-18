# 《7:55》第三章完整开发报告

章节名：求是潮 755  
版本：V1.0  
日期：2026-07-11  
目标时长：首次 4–7 分钟，熟练重玩 2–3 分钟  
主要技术：React 18、TypeScript、Phaser 3.87、Arcade Physics、Canvas、Pointer/Keyboard Input、Vite 单文件构建

## 核心一句话

第二章恢复图书馆座位后，考试结束的人流进入求是潮。玩家打开手机中的“游戏”，进入三车道骑行关卡，在持续前进的 `755` 米路线中切换车道，避开自行车、路障和人群。玩家拥有三次机会；成功抵达终点后记录第三章完成，失败时可以立即重试，退出后保留章节入口。

## 一、章节定位

第三章负责从跨应用解谜切换到直接操作：

1. 缩短页面阅读时间，提供连续反应玩法。
2. 使用第二章已经建立的“考后求是潮拥堵”主题。
3. 让 `755` 同时承担标题、距离目标和时间符号。
4. 验证 Phaser 小游戏能在统一手机壳内稳定运行。
5. 为后续校园地图动作关提供输入、碰撞、HUD 和运行时快照基础。

章节以手机“游戏”图标作为入口。主玩法保持竖屏，避免在短章节中再次切换设备方向。

## 二、第二章衔接

### 目标衔接

第二章结束条件：

```text
libraryFinalsPhase === "seat_recovered"
```

满足后：

1. P13 手机主屏“游戏”图标解锁。
2. 图标显示一次黄色脉冲和未读标记。
3. 任务栏显示“穿过求是潮，距离 755 米”。
4. 玩家点击图标进入 P16。

### 实现结果

P13 已按 `seat_recovered` 检查入口；未完成第二章时不渲染“游戏”图标。解锁、完成状态和最佳记录均进入持久存档。

## 三、玩家目标

### 主目标

在机会耗尽前完成 `755m`。

### 操作目标

- 保持在三条车道之一。
- 使用左/右输入换道。
- 避开三类障碍。
- 发生碰撞后利用短暂无敌时间恢复节奏。
- 到达 `755m` 后进入成功结算。

### 失败条件

```text
lives === 0
```

### 成功条件

```text
distance >= 755
```

## 四、章节风格

| 方向 | 比例 | 表现 |
| --- | ---: | --- |
| 操作压力 | 45% | 自动前进、换道、障碍密度增长 |
| 校园荒诞 | 30% | 考后车流、临时路障、人群占道 |
| 像素街机 | 20% | 三车道、距离 HUD、机会方块、结果面板 |
| 剧情信息 | 5% | 开场和结算短句 |

章节不使用长对话。骑行阶段不播放旁白，防止语音干扰障碍判断。

## 五、场景节点

| 编号 | 状态 | 页面职责 | 输出 |
| --- | --- | --- | --- |
| C3-P00 | `locked` | 第二章未完成时隐藏入口 | 无 |
| C3-P01 | `intro` | 说明 755 米、三次机会和换道操作 | `ready` |
| C3-P02 | `playing` | 自动前进与障碍生成 | 运行时快照 |
| C3-P03 | `collision` | 扣除机会、短暂无敌 | 更新 lives |
| C3-P04 | `won` | 成功结算 | `bike_arcade_completed` |
| C3-P05 | `lost` | 失败结算 | 重试或退出 |
| C3-P06 | `replay` | 再次开始 | 新 runId |

## 六、完整流程图

```text
第二章恢复 022
  ↓
P13 “游戏”图标解锁
  ↓ 玩家点击
C3-P01 求是潮 755 开场页
  ↓
显示：目标 755m / 机会 3 / 左右换道
  ↓ 点击“开始骑行”
C3-P02 三车道骑行
  ↓
距离自动增加
  ↓
随机生成：自行车 / 路障 / 人群
  ↓
玩家使用 A/D、方向键、触控按钮或左右半屏换道
  ↓
├─ 碰撞
│   ↓ 扣 1 次机会
│   画面震动 + 角色闪烁 + 900ms 无敌
│   ↓ lives > 0
│   返回骑行
│
├─ lives = 0
│   ↓
│ C3-P05 失败结算“原地结算”
│   ↓ 再骑一次 / 返回桌面
│
└─ distance = 755
    ↓
  C3-P04 成功结算“已通过”
    ↓
  写入第三章完成
    ↓ 再骑一次 / 返回桌面
```

## 七、C3-P00：章节解锁

### 解锁条件

```text
libraryFinalsPhase === "seat_recovered"
```

### 主屏表现

- “游戏”图标位于 P13 应用格。
- 未解锁时不显示按钮，避免无响应入口。
- 解锁时播放一次 `300ms` 黄色边框脉冲。
- 标签显示“游戏”。
- 图标内部显示 `7:55` 和简化车道线。

### 领域事件

```text
bike_arcade_unlocked
```

### 当前状态

图标、样式、路由和章节门槛均已实现。只有 `libraryFinalsPhase === "seat_recovered"` 时入口出现；首次解锁只播放一次 `300ms` 脉冲。

## 八、C3-P01：开场页

### 布局

手机画布：`430×930`。P16 内部分区：

| 区域 | 高度 | 内容 |
| --- | ---: | --- |
| 共享状态栏 | `40px` | 07:55、网络、电量 |
| 章节标题 | `56px` | GAME 07:55、求是潮 755、READY |
| HUD | `48px` | 距离与机会 |
| 赛道区域 | 自适应 | Phaser Canvas 与覆盖层 |
| 操作区 | `84px` | 左右按钮与 A/D 提示 |

### 开场内容

- 三车道预览。
- 玩家骑行标记位于中央车道。
- 一枚障碍标记位于前方。
- 目标说明：骑过 `755` 米。
- 主按钮：`开始骑行`。

### 操作

点击“开始骑行”：

1. `distance=0`。
2. `lives=3`。
3. `phase=playing`。
4. `runId+1`。
5. 异步载入 Phaser 和 `BikeRushScene`。

### 加载降级

- Phaser 载入期间按钮锁定。
- 超过 `3000ms` 未完成时显示“重新加载游戏”。
- 失败时允许返回桌面。
- 加载失败不能留下空白赛道。

## 九、C3-P02：赛道

### Phaser 配置

```ts
new Phaser.Game({
  type: Phaser.CANVAS,
  width: 390,
  height: 650,
  pixelArt: true,
  roundPixels: true,
  physics: { default: "arcade" },
  scale: { mode: Phaser.Scale.FIT }
});
```

### 坐标

```text
内部画布：390×650
原点：左上
x：向右
y：向下
```

三条车道中心：

```ts
const LANE_X = [88, 195, 302];
```

玩家初始位置：

```text
lane = 1
x = 195
y = 560
```

### 道路构成

- 中央道路宽 `314px`。
- 左右各有路边区域。
- 道路边缘使用黄色实线。
- 车道使用白色断续线。
- 路边树木按固定间距循环移动。
- 顶部标签显示“求是大道”。

所有骑行素材由 Phaser Graphics 运行时生成，不依赖外部整张赛道图。

## 十、距离系统

目标：

```ts
BIKE_ARCADE_GOAL = 755;
```

距离计算：

```ts
pace = 0.038 + min(distance, 755) * 0.000012;
distance += deltaMs * pace;
```

规则：

- 距离不能超过 755。
- `deltaMs < 0` 时按 0 处理。
- 距离越大，前进速度小幅提高。
- HUD 只显示取整后的距离。
- 数值使用三位补零：`000 / 755m`。

### 里程节点

已实现四个领域节点：

| 距离 | 用途 |
| ---: | --- |
| 188m | 首次节奏提升 |
| 377m | 障碍密度提升 |
| 566m | 最后路段提示 |
| 755m | 完成 |

每个节点只发布一次 `bike_arcade_milestone`；`377m` 追加拥堵配乐切换，`566m` 追加冲刺配乐更新。

## 十一、换道输入

### 支持输入

| 设备 | 输入 |
| --- | --- |
| 键盘 | A / D |
| 键盘 | Left / Right |
| 触摸 | 底部左右按钮 |
| 赛道 | 点击左半屏或右半屏 |

### 规则

```ts
nextLane = clamp(currentLane + direction, 0, 2);
```

- 左边界继续向左不移动。
- 右边界继续向右不移动。
- 玩家换道 tween 时长 `105ms`。
- 新输入会终止旧 tween 并从当前位置移动到新车道。
- phase 非 `playing` 时所有换道输入失效。

### 反馈

- 底部按钮按下时向下移动 `2px`。
- 玩家移动保持固定 y，仅改变 x。
- 每次有效换道可播放短促机械点击音。

## 十二、障碍系统

### 障碍类型

```ts
type BikeArcadeObstacleType =
  | "bicycle"
  | "barrier"
  | "crowd";
```

| 类型 | 视觉 | 碰撞框 | 阅读用途 |
| --- | --- | --- | --- |
| bicycle | 红色自行车和黄色横杆 | `34×50` | 窄、速度感强 |
| barrier | 黄黑路障 | `56×28` | 宽、纵向较短 |
| crowd | 三人组合 | `44×45` | 中等宽度 |

### 生成

- 每次随机选择车道和类型。
- 第一枚障碍在开场后约 `720ms` 出现。
- 基础生成间隔：`680–990ms`。
- 距离压力：`min(260, distance * 0.22)`。
- 最终间隔为基础间隔减去压力。

### 速度

```ts
obstacleSpeed = 180 + clamp(distance, 0, 755) * 0.14;
```

- 起点速度约 `180px/s`。
- 终点附近约 `285.7px/s`。
- 障碍移出画布底部后立即销毁。

### 难度约束

正式版本需要保证：

- 同一 y 区域不同时封死三条车道。
- 连续两枚障碍至少保留一次 `105ms` 换道窗口。
- 开场前 `1000ms` 不生成不可避组合。
- 三种障碍的宽度差异可以在手机缩放后辨认。

当前实现使用受约束波次生成：同一波最多占用两条车道，并根据换道时间窗拒绝不可解组合；开场保护期和同屏障碍上限同时生效。

## 十三、碰撞与机会

最大机会：

```ts
BIKE_ARCADE_MAX_LIVES = 3;
```

### 碰撞流程

1. 障碍与玩家 Arcade Physics 碰撞框重叠。
2. 当前障碍销毁。
3. `lives-1`，最低为 0。
4. 摄像机震动 `170ms`。
5. 玩家变红并降低透明度。
6. 进入 `900ms` 无敌状态。
7. 无敌结束后恢复颜色和透明度。

### 连续碰撞防护

`invulnerable=true` 时忽略新碰撞，避免同一帧扣除多次机会。

### HUD

```text
■■■  3 次
■■□  2 次
■□□  1 次
□□□  0 次
```

### 失败

机会降到 0 时立即执行 `finish("lost")`，暂停物理世界并清理玩家 tween。

## 十四、速度与节奏

### 当前曲线

- 距离速度线性增加。
- 障碍速度线性增加。
- 生成间隔随距离缩短。
- 玩家换道速度保持不变。

### 目标节奏

| 阶段 | 距离 | 目标体验 |
| --- | ---: | --- |
| 教学 | 0–188m | 认识换道和三种障碍 |
| 稳定 | 188–377m | 连续读取两枚障碍 |
| 压力 | 377–566m | 更短间隔和更快道路 |
| 冲刺 | 566–755m | 保留可解空间，提高反应要求 |

碰撞不降低距离，避免失败后重复已完成路段。

## 十五、C3-P04：成功结算

### 触发

```text
distance >= 755
```

### 演出

1. 物理世界暂停。
2. 玩家换道 tween 停止。
3. 道路继续滚动 `180ms` 后停住。
4. 结果层从底部进入。
5. 显示时间 `07:55:00`。
6. 标题：`已通过`。
7. 显示完成说明。
8. 发送 `bike_arcade_completed`。

### 按钮

- `再骑一次`：清空本次运行态并重新开始。
- `返回桌面`：返回 P13，保留章节完成状态。

### 存档目标

```text
completed = true
bestDistance = 755
bestLives = max(previousBestLives, currentLives)
attemptCount += 1
```

成功结算通过 `BikeArcadeChapterController` 写入全局章节完成状态；刷新后恢复完成标记和最佳记录。

## 十六、C3-P05：失败结算

### 触发

```text
lives === 0
```

### 演出

- 显示时间 `07:55:01`。
- 标题：`原地结算`。
- 记录本次距离。
- 保留最高距离。

### 按钮

- `再骑一次`：立即开始新 run。
- `返回桌面`：返回 P13，不标记章节完成。

### 重试原则

- 重试不重载 React 应用。
- 旧 Phaser 实例必须销毁后再创建。
- `clearBikeArcadeSnapshot()` 清理旧快照。
- 失败不影响第二章完成状态。

## 十七、运行时快照

当前实现使用：

```ts
interface BikeArcadeSnapshot {
  coordinateSystem: "390x650 canvas, origin at top-left, x right, y down";
  phase: "intro" | "playing" | "won" | "lost";
  distance: number;
  goal: 755;
  lives: number;
  lane: number;
  invulnerable: boolean;
  obstacles: Array<{
    lane: number;
    type: "bicycle" | "barrier" | "crowd";
    y: number;
  }>;
}
```

用途：

- `render_game_to_text()` 输出当前可玩状态。
- 浏览器 QA 判断 Canvas 是否运行。
- 自动测试读取距离、机会、车道和最多 8 个障碍。

快照只保存在运行内存，不进入长期存档。

## 十八、建议持久状态

新增：

```ts
interface BikeArcadeChapterState {
  unlocked: boolean;
  completed: boolean;
  attemptCount: number;
  bestDistance: number;
  bestLives: number;
}
```

规则：

- 第二章完成时 `unlocked=true`。
- 每次成功或失败结算时更新尝试次数和最佳距离。
- 成功后 `completed=true`，重玩不回退。
- 运行时 obstacle 列表不保存。

## 十九、领域事件

建议事件：

```text
bike_arcade_unlocked
bike_arcade_opened
bike_arcade_run_started { attempt }
bike_arcade_lane_changed { from, to }
bike_arcade_milestone { distance }
bike_arcade_collision { obstacleType, lives }
bike_arcade_last_life
bike_arcade_won { lives, attempt }
bike_arcade_lost { distance, attempt }
bike_arcade_restarted
bike_arcade_near_miss { obstacleType, lane }
bike_arcade_congestion_started { distance }
bike_arcade_sprint_started { distance }
bike_arcade_paused
bike_arcade_resumed
bike_arcade_closed
bike_arcade_completed
```

`PresentationDirector` 将共享状态和这些事件归一为稳定 cue。视觉演出与音频时间线独立消费 cue，不修改距离、车道或机会。

## 二十、音频设计

### 当前实现

P16 已使用 MiniMax CLI 生成并接入独立音频包：

- 4 段配乐。
- 10 个动作音效。
- 3 条英文女声旁白。
- `AudioDirector` 只消费稳定 `presentation_cue`，关卡状态不等待音频结束。
- 离开页面会取消尚未触发的章节 cue，并停止当前旁白和配乐。

### 演出与音频独立性

- P16 的开场、道路滚动、换道倾斜、碰撞碎片、近失闪光、里程牌和胜负遮罩只读取玩法快照。
- P17 的道路延展、节点上升、结果数据和按钮入场只读取持久化结果。
- `PresentationLayer` 负责章节牌、倒数、里程、碰撞和结算的 DOM 视觉演出。
- 音频文件、字幕偏移、ducking、配乐替换和 cue 延迟只存在于 JSON 时间线。
- Phaser 动画结束、CSS `animationend` 和音频 `ended` 均不触发成功、失败或路由跳转。

### 配乐

| 阶段 | 资源名 | 声音方向 |
| --- | --- | --- |
| 开场 | `music_bike_755_intro` | 稀疏像素节拍，速度低 |
| 0–377m | `music_bike_755_run_a` | 稳定节拍，保留操作空间 |
| 377–755m | `music_bike_755_run_b` | 更高 BPM 和更明显低频 |
| 结算 | `music_bike_755_result` | 成功、失败使用不同结尾 cue |

### 音效

```text
fx_bike_755_button
fx_bike_755_lane_change
fx_bike_755_near_miss
fx_bike_755_collision
fx_bike_755_damage
fx_bike_755_milestone
fx_bike_755_pause
fx_bike_755_resume
fx_bike_755_success
fx_bike_755_failure
```

### 旁白

沿用第二章英文女声，只保留三个节点：

1. 进入开场页。
2. 首次只剩一次机会。
3. 成功或首次失败。

骑行过程中不播放长句。字幕最多一行，不覆盖 HUD 和车道。

### 对轴原则

- 换道音在 lane 更新时立即播放。
- 碰撞音与 camera shake 同帧开始。
- 最后一条机会提示延迟 `180ms`，避开碰撞峰值。
- 成功音在物理暂停后 `80ms` 播放。
- 状态推进不等待配乐或旁白结束。

## 二十一、视觉设计

### 色彩

| 用途 | 色值 |
| --- | --- |
| 道路 | `#474e52` |
| 路边 | `#73945f` |
| 黄线/主按钮 | `#f0d54e` |
| 警告/机会 | `#e97b70` |
| 蓝色信息 | `#8fc7d1` |
| 深色面板 | `#20272f` |
| 浅色面板 | `#e7e2d4` |

### 稳定尺寸

- 标题栏 `56px`。
- HUD `48px`。
- 控制区 `84px`。
- 左右按钮 `78×58px`。
- 赛道 Canvas 填满剩余高度。
- HUD 数字使用等宽字体，距离变化不引起布局位移。

### 结果层

- 全屏深色遮罩。
- 成功标题黄色。
- 失败标题红色。
- 两个按钮垂直排列，宽度固定。

## 二十二、性能与生命周期

### 创建

- 用户点击开始后动态 import Phaser。
- 每个 `runId` 对应一个新的 Phaser.Game。
- `postBoot` 后保存场景引用。

### 销毁

React effect cleanup 时：

```text
cancelled = true
sceneRef = null
clearBikeArcadeSnapshot()
game.destroy(true)
gameRef = null
```

### 性能目标

- 常规移动端保持 50–60 FPS。
- 同屏障碍快照最多记录 8 个。
- 离屏障碍立即销毁。
- Phaser Canvas 不使用高分辨率整图。
- 页面离开后无键盘监听和物理更新残留。

### 页面隐藏

已监听 `visibilitychange`：

- 页面隐藏时暂停 Phaser。
- 页面恢复时显示 1 秒继续提示。
- 暂停期间不增加距离或生成障碍。

页面恢复后显示 1 秒“继续骑行”，并通过事件独立触发暂停和恢复音效。

## 二十三、输入与可访问性

### HTML 层

- 开始、返回、重试、左右换道均为原生 button。
- 所有按钮具有唯一 `aria-label`。
- HUD 使用 `aria-live="polite"`，更新频率需要限流，避免逐米朗读。
- focus-visible 轮廓为蓝色 `3px`。

### Canvas 层

- Canvas 标记为“三车道骑行区域”。
- 主要操作仍由 HTML 按钮提供。
- 键盘 A/D 与方向键功能一致。

### reduced motion

- 关闭 camera shake。
- 玩家碰撞改为颜色变化。
- 结果层直接淡入。
- 道路滚动作为核心玩法保持，但降低视觉对比和树木移动频率。

## 二十四、错误恢复

| 情况 | 恢复 |
| --- | --- |
| Phaser import 失败 | 显示重载和返回按钮 |
| Canvas 初始化失败 | 保留开场覆盖层，允许重试 |
| 按键在边界继续输入 | 忽略，不播放换道音 |
| 同帧多次碰撞 | `invulnerable` 阻止重复扣血 |
| 玩家离开页面 | 销毁 Phaser 和快照 |
| 重试 | 创建新 run，清空运行态 |
| 浏览器切后台 | 暂停并在返回时倒数 |
| 音频失败 | 玩法继续 |
| 单文件直接打开 | Phaser 和所有资源已内嵌 |

## 二十五、组件与文件

### 当前文件

- `src/scenes/phone/P16_BikeArcade/index.tsx`
- `src/scenes/phone/P16_BikeArcade/BikeRushScene.ts`
- `src/scenes/phone/P16_BikeArcade/BikeArcadeRules.ts`
- `src/scenes/phone/P16_BikeArcade/BikeArcadeRuntime.ts`
- `src/scenes/phone/P16_BikeArcade/BikeArcadeRules.test.ts`
- `src/scenes/phone/registry.tsx`
- `src/styles/scenes.css`
- `src/main.tsx`

### 新增文件

- `src/modules/BikeArcadeChapterController.ts`
- `src/modules/BikeArcadeChapterController.test.ts`
- `src/data/bike-arcade.content.json`
- `src/data/bike-arcade.audio.json`
- `src/data/bike-arcade.audio.generated.json`
- `scripts/generate-bike-arcade-audio.mjs`
- `src/scenes/phone/P17_ChapterTransition/index.tsx`

## 二十六、素材清单

### 当前视觉素材

全部由 Phaser Graphics 生成：

- 玩家自行车。
- 障碍自行车。
- 黄黑路障。
- 三人组合。
- 道路、黄线、白色车道线。
- 路边树木。

新增整页图片：0。

### 已补充

- 求是潮沿线可识别的两个小型地标轮廓。
- 里程牌 `188 / 377 / 566 / 755`。
- 章节完成徽记。
- 专属配乐、音效与三条短旁白。

地标与里程牌均使用 Phaser Graphics，保持道路可读性；章节完成信息由 P17 原生 DOM 页面承载。

## 二十七、测试清单

### 纯规则

- 车道保持在 0–2。
- 距离不超过 755。
- 负 delta 不推进距离。
- 障碍速度随距离增加。
- 机会最低为 0。

### 场景行为

- 开始后 phase 变为 playing。
- A/D、方向键和按钮均能换道。
- 边界输入不越界。
- 碰撞只扣一次机会。
- 900ms 后解除无敌。
- lives=0 进入 lost。
- distance=755 进入 won。
- 重试创建新 run。
- 返回桌面销毁 Canvas。

### 手工浏览器

- `430×930` 逻辑视口完成一次成功和失败。
- `390×844` 视口无 HUD、Canvas、按钮重叠。
- Chromium 和 Firefox 各完成一次键盘操作。
- 触摸模拟完成一次左右换道。
- 页面切后台后不会继续增加距离。
- 静音状态可完成关卡。
- 单文件打开时 Canvas 非空。

### 像素检查

- 开始后 Canvas 非纯色。
- 三条车道可辨认。
- 玩家位于可视区域内。
- 障碍至少出现一种非背景色像素簇。
- 结果层不会被 Canvas 覆盖。

## 二十八、当前实现状态

已完成：

- 第二章完成门槛、P16 页面和手机主屏入口。
- `390×650` Phaser Canvas。
- 三车道换道。
- A/D、方向键、底部按钮和半屏点击。
- `755m` 自动距离。
- 三种障碍。
- 距离递增难度。
- 三次机会和 `900ms` 无敌。
- 成功、失败、重试和返回桌面。
- 运行时快照与纯规则测试。
- `prefers-reduced-motion` 的 CSS transition 降级。
- 全局 `completed / bestDistance / bestLives / attemptCount` 存档与刷新恢复。
- 4 段专属配乐、10 个音效和 3 条短旁白。
- 页面隐藏暂停、恢复提示和音频生命周期清理。
- 障碍波次可解性约束与近失反馈。
- `188 / 377 / 566 / 755m` 里程节点演出。
- P17 下一章节出口、返回桌面和重玩入口。

## 二十九、验收标准

1. 第二章未完成时不能进入第三章。
2. 第二章完成后“游戏”图标出现并可点击。
3. 开场页明确显示 `755m` 和三次机会。
4. A/D、方向键、触控按钮和半屏点击均可换道。
5. 玩家始终位于三条车道范围内。
6. 自行车、路障和人群可清楚区分。
7. 难度随距离增加，且不存在三车道同时封死。
8. 单次碰撞只扣除一次机会。
9. 无敌时间结束后恢复正常碰撞。
10. 距离达到 755 时立即成功。
11. 机会耗尽时立即失败。
12. 成功和失败都能重试或返回桌面。
13. 成功后章节完成状态持久化。
14. 退出页面后 Phaser 实例和监听器全部清理。
15. 页面隐藏时游戏暂停。
16. 静音时仍可完成。
17. `render_game_to_text()` 能读取 phase、distance、lives、lane 和障碍。
18. 手机缩放后 HUD 和操作按钮不重叠。
19. 单文件构建内嵌 Phaser 与章节资源。

## 三十、最小可玩流程

```text
完成第二章
→ P13 解锁“游戏”
→ 进入求是潮 755
→ 点击开始骑行
→ 使用 A/D 或左右按钮换道
→ 避开自行车、路障和人群
→ 碰撞后扣除机会并继续
→ 抵达 755m
→ 显示“已通过”
→ 写入第三章完成
→ 继续下一章、返回桌面或重玩
```

## 三十一、章节结论

第三章已经完成第二章门槛、入口解锁、开始、操作、碰撞、里程演出、胜负、存档、音频、后台暂停、重试和 P17 出口。求是潮 755 当前可以从 P13 完整进入，成功后写入持久状态并进入下一章节过渡页；Phaser 运行基础继续供后续动作场景复用。

## 三十二、V1.1 演出与移动端收口

- P16 增加开场入场、道路预览移动、骑手起伏、换道倾斜、近失闪光、碰撞碎片、速度线、里程牌和胜负遮罩。
- P17 增加道路展开、节点上升、标题锁定、统计栏和按钮分段入场。
- P17 主内容高度改为 `calc(100% - 40px)`，扣除共享状态栏后不再越出场景底部。
- `PresentationDirector` 同时处理状态迁移与领域事件，对重复 cue 去重；P16/P17 不再自行触发开场音频事件。
- `AudioDirector` 只读取稳定 `presentation_cue` 和 JSON 时间线，动画删除或重排不会阻止音效、旁白和配乐 cue。
- `390×844` 实测手机框为 `354×765.63`，比例保持 `430:930`；HUD、`390×650` 逻辑 Canvas 和底部控制区连续排列，无横向页面滚动。
- 浏览器控制台 warning/error 为 0；最终 168 项测试和单文件构建通过。
