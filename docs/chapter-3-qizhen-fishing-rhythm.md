# 启真湖节奏钓鱼设计与实现契约

本章是「节奏钓鱼」玩法的唯一权威设计与模块接口契约。实现代码时以此文件为准；若实现与本文件冲突，先改代码，再回改本文件。

## 1. 概述

启真湖现有四次钓取（生锈的柜门钥匙、破损网框、小鲤鱼、纸条本体）改为场景内节奏玩法：皮划艇、湖面、目标水纹与浮标留在原场景中，节拍提示围绕浮标收缩。左右输入沿用左右桨（A/←、D/→），交互键在钓鱼阶段临时改为「提竿」（Space）。

- 漂浮钓鱼竿仍是普通拾取物，不进节奏玩法。
- 普通鱼钩直接抛向纸条倒影（`directPaperCast`）继续走原有即时失败逻辑，不启动音游。
- 只有四个已配置目标进入节奏玩法，spotId 与谱面 id 一一对应：
  `locker_key`（钥匙，教程谱面）、`net_frame`（网框）、`fish`（小鲤鱼）、`paper`（纸条本体）。

## 2. 音乐《水纹 7:55》

- 96 BPM、4/4 拍、8 小节、20.000 秒；每拍 `0.625 s`。
- D Dorian；木质收线轮点击承担四分音符脉冲，低音正弦落在每小节 1、3 拍，马林巴与玻璃水滴承担八分装饰，短拨弦主旋律，薄空气感合成器随张力上升；无人声、无重鼓组、无长混响尾。
- 第 4、6、8 小节（10.0 s / 15.0 s / 20.0 s）各设一个可结束的和声落点，四次钓鱼分别播放 10 s / 15 s / 15 s / 20 s。
- 八小节结构：1 Dm(add9) 预备 → 2 C6 咬钩 → 3 G6/B→A7sus4 左右交替 → 4 Dm6/9 第一结束点（钥匙）→ 5 Em7→G6 加八分与阻力 → 6 Dm6/9 第二结束点（网框、小鲤鱼）→ 7 G6→A7 纸条挣脱 → 8 Dm6/9 最终提竿。
- 主旋律三短句（7/5/5 音，隐性呼应 7-55）：`D5 A4 C5 E5 D5 C5 A4` / `E5 G5 E5 D5 B4` / `A4 C5 E5 D5 A4`。

生成提示词（写入 `src/data/chapter3-qizhen.audio.content.json` 的 `prompt` 字段）：

```text
Immediate-start modular rhythm-fishing cue for a top-down pixel RPG at a university lake, exactly 20.0 seconds, strict 96 BPM, 4/4, eight bars, D Dorian.

A clear quarter-note pulse must begin on the first audio sample. Include clean musical landing points at exactly 10.0 seconds, 15.0 seconds, and 20.0 seconds.

Use muted marimba water droplets, dry wooden fishing-reel clicks, soft plucked strings, low sine bass pulses, and a restrained airy synth layer. Bars 1 to 4 feel calm and instructional. Bars 5 to 6 add tighter reeling tension. Bars 7 to 8 build toward a magnetic paper catch and end cleanly.

No vocals, no rubato, no tempo drift, no pickup, no fade-in, no fade-out, no cinematic drums, no dense lead melody, and no reverb tail beyond 20 seconds.
```

内容配置条目：

```json
{
  "cue": "qizhen.fishing",
  "asset": "music_qizhen_fishing",
  "path": "chapter3-qizhen/music/music_qizhen_fishing.mp3",
  "durationSeconds": 20,
  "genre": "minimal rhythm fishing pixel game soundtrack",
  "mood": "calm, precise, lightly tense, playful",
  "instruments": "wooden reel clicks, muted marimba, glass droplets, soft plucked strings, low sine bass, airy synth",
  "bpm": 96
}
```

**判定时钟原则**：生成音乐不承担判定时钟。判定、视觉环与输入统一引用同一个单调时钟 `now()`（场景注入 Web Audio `AudioContext.currentTime`，不可用时回退 `performance.now()/1000`）：`t_n = t_0 + 0.625 × b_n`。禁止用 `setTimeout` 累积计时。

## 3. 谱面数据

文件：`src/data/chapter3-qizhen-fishing.charts.json`（运行时由模型直接 import）。

动作：`H`=提竿(hook)，`L`=左收线(left)，`R`=右收线(right)，`~1`=长按 1 拍。拍号以音乐开始为 0，前四拍预备（第 4 拍为第一个「提竿」音符）。

JSON Schema：

```json
{
  "version": 1,
  "bpm": 96,
  "beatSeconds": 0.625,
  "leadSeconds": 1.25,
  "assistLeadSeconds": 1.5625,
  "charts": {
    "<chartId>": {
      "spotId": "<同 chartId>",
      "label": "<中文目标名>",
      "bars": 4,
      "durationSeconds": 10,
      "notes": [
        { "beat": 4, "action": "hook" },
        { "beat": 6, "action": "left", "cue": "left_intro" }
      ]
    }
  }
}
```

- `cue` 仅用于钥匙教程谱面：首次出现 left/right 时各标一次（`left_intro`/`right_intro`），视觉层据此显示「左收线」「右收线」文字，之后只显示图标。
- `hold` 字段：`{ "beat": 16, "action": "left", "hold": 1 }` 表示长按 1 拍。

### 3.1 locker_key（生锈钥匙，教程）— 4 小节 10 s，8 音符，纯四分音符

```text
4H  6L  8R  10L  12R  13L  14R  15H
```

### 3.2 net_frame（破损网框，阻力）— 6 小节 15 s，14 音符，首次长按

```text
4H  6L  8R  10L  11R  12L  14R
16L~1  18R  19L  20R  21L  22R  23H
```

### 3.3 fish（小鲤鱼，换向）— 6 小节 15 s，20 音符，八分错位

```text
4H
5.5L  6.5R  7.5L  8.5R
9L  10.5R  11.5L  12.5R
13.5L  14R  15.5L  16.5R
17L  18.5R  19.5L  20R
21L  22R  23H
```

### 3.4 paper（纸条本体，最终）— 8 小节 20 s，26 音符，两次长按 + 连续换向

```text
4H
5L  6R  7L  8.5R  9L  10R  11.5L
12R~1  14L  15R
16.5L  17R  18L  19.5R
20.5L  21R  22L  23R
24.5L~1  26R  27L  28R  29L  30R
31H
```

最后 `31H` 位于 19.375 s，剩余 0.625 s 用于捕获动画与纸条释放音效。

## 4. 判定与张力

### 4.1 时间判定

输入误差 `e = t_input − t_n`（毫秒）。窗口（辅助模式见 §5）：

| 判定 | 误差范围 | 权重 |
|---|---|---|
| perfect | \|e\| ≤ 70 | 1.00 |
| great | 70 < \|e\| ≤ 130 | 0.80 |
| good | 130 < \|e\| ≤ 190 | 0.55 |
| miss | \|e\| > 190（含超时未输入） | 0.00 |

- 一次输入只匹配时间上最近、尚未判定的一个音符；窗口内无音符则忽略该输入。
- 方向错误（窗口内最近音符动作与输入不同）：该音符判 miss，张力 +16（代替 miss 的 −14）。
- 长按：按下时刻判定 perfect/great/good；须持续按住至 `timeSec + holdSec − 0.08 s`；提前松开 → 该音符改判 miss，张力 −12，触发 `onHoldBroken`。
- 超时自动 miss：`now > timeSec + good窗口` 仍未输入。

### 4.2 张力系统

范围 0–100，初始 50。

| 事件 | 张力变化 |
|---|---|
| perfect | 向 50 回调 4 点（越过 50 即止） |
| great | 提前 +3 / 延后 −3 |
| good | 提前 +7 / 延后 −7 |
| miss（超时） | −14 |
| 方向错误 | +16 |
| 长按过早松开 | −12 |

- 张力 < 20：钓线下垂 + 向下箭头 + 数值（`onWarning("tension_low")`）；> 80：钓线震动 + 向上箭头 + 数值（`onWarning("tension_high")`）。颜色只能辅助，必须同时有图形与数值。警告为边沿触发，回到 [30, 70] 后重新武装。
- 越界失败：张力 ≤ 0（脱钩 `hook_escaped`）或 ≥ 100（断线 `line_snapped`），且越界状态**持续 350 ms** 才结束本轮（防单帧抖动）。

### 4.3 通关与等级

加权准确率 `accuracy = Σ权重 / 总音符数`。

通关（`passed`）需同时满足：

1. 开头提竿（第一个音符）与结尾提竿（最后一个音符）均非 miss；
2. `accuracy ≥ 0.70`；
3. 最终张力 ∈ [15, 85]。

等级：S = accuracy ≥ 0.95 且无 miss；A = ≥ 0.85；B = ≥ 0.70；否则 C（未通过）。S/A 只影响水花、评级文本与统计，不锁主线。

## 5. 辅助模式

同一目标连续失败 2 次后自动进入（场景侧运行态计数，成功后清零，不入存档）：

- good 窗口扩大到 230 ms；
- 八分音符（非整数拍）简化为四分音符（直接移除这些音符；首尾提竿均在整数拍，不受影响）；
- 音符提前量 2.5 拍（`assistLeadSeconds = 1.5625`）；
- 水纹脉冲对比度增强；
- 张力越界需持续 700 ms 才失败。

## 6. 输入契约

| 动作 | 桌面 | 触屏 |
|---|---|---|
| 左收线 left | `A` 或 `←` | 轻触「左收线」按钮 |
| 右收线 right | `D` 或 `→` | 轻触「右收线」按钮 |
| 提竿 hook | `Space` | 轻触「提竿」按钮 |
| 长按 | 按住对应键 | 按住对应按钮 |

- 触屏节奏状态下**关闭划桨手势识别**，`pointerdown` 立即记拍，`pointerup`/`pointercancel` 记松开。一次按下只生成一次节奏输入，不得同时触发划桨移动。
- 节奏状态下三枚触屏按钮等宽；`390×844` 视口下实际触控区域 ≥ `44×44 CSS px`。
- 无双指同时输入、无左右和弦音符。
- 桌面端钓鱼期间 A/D/←/→/Space 全部路由到节奏模型，不再驱动皮划艇；`A` 在此玩法中是「左收线」而非交互键（不违反 AGENTS.md 的 A 键约束）。

## 7. 视觉契约（`QizhenFishingRhythmVisual`）

- 判定锚点 = 浮标世界坐标（抛竿动画落点）。音符提前 2 拍（`leadSeconds`）出现：浮标外侧半径 72 px 水纹环向浮标内圈（约 14 px）匀速收缩，重合瞬间为判定时刻。
- 图标语言：left = 柳树枝左桨图标 + `←`；right = 三角牌右桨图标 + `→`；hook = 向上鱼钩图标 + `↑`。沿用现有左右桨视觉区分。
- 长按音符显示环形弧线，按住期间弧线随剩余时间闭合。
- 顶部窄状态栏（`scrollFactor(0)`，位于共享任务栏下方、不遮挡其区域）：`目标：{label}  {judged}/{total}  张力 {n}  连击 {n}`。
- 钓线：从船头到浮标；张力 <20 明显下垂 + ▼；>80 震动 + ▲。
- 钓鱼期间：右下道具栏由宿主卸载；底部普通任务提示隐藏；摄像机 `stopFollow()` 并锁定浮标；船速清零；深浅模式切换锁定；环境动画（黑天鹅、水纹、柳枝）继续播放。
- 完成后约 800 ms 等级反馈 + 道具飞入动画，不弹大型结算页。paper 谱面不播评级动画，直接衔接纸条挣脱与黑天鹅追逐。
- `prefers-reduced-motion`：取消缩放动画，水纹环改为离散半径跳变（72→48→32→14），保留图标与整数拍数字倒计时。

## 8. 流程与事件链

### 8.1 时序

1. 深色观察已记录对应水纹；玩家切回浅色操作；船位/朝向/道具/阶段通过检查。
2. 场景发 `rpg_qizhen_fishing_attempt_requested`（替代原直接 `rpg_qizhen_fish_requested`）。
3. 宿主调控制器 `precheckCast(spotId)` 只读验证；失败走既有 `rpg_item_use_feedback` 反馈，不发后续事件。
4. 验证通过：宿主记录 pending session 并发 `qizhen_fishing_prechecked`；场景播抛竿动画（约 360 ms），浮标落水后锁镜头、清零船速、锁模式。
5. 场景创建模型 + 视觉，发 `qizhen_fishing_started`（时间线播放 `music_qizhen_fishing`），第一小节四拍预备。
6. 节奏输入：桌面场景内键盘；触屏宿主发 `rpg_qizhen_fishing_input`。
7. 模型事件 → 场景转发领域事件 + 驱动视觉反馈。
8. 自然结束且 `passed`：场景发 `rpg_qizhen_fishing_resolve_requested`；宿主核对 sessionId 后调 `castAt(spotId)` 结算（控制器内部再兜底验证），成功则发 `qizhen_fishing_completed`。
9. 失败（grade 不达标 / 断线 / 脱钩 / castAt 意外失败）：发 `qizhen_fishing_failed`，保留全部剧情道具，回到浮标等待状态。
10. 页面隐藏或场景卸载：发 `qizhen_fishing_cancelled`，本轮作废。

### 8.2 事件与载荷（精确契约）

```ts
// 场景 → 宿主（intent）
"rpg_qizhen_fishing_attempt_requested": {
  sessionId: string; spotId: "locker_key" | "net_frame" | "fish" | "paper";
  targetId: string; itemId: string;
}
// 宿主 → 场景（bridge）
"qizhen_fishing_prechecked": { sessionId: string; spotId: string; chartId: string }
// 场景 → 全局（domain，音频时间线消费）
"qizhen_fishing_started": {
  sessionId: string; spotId: string; chartId: string;
  targetLabel: string; totalNotes: number; assist: boolean;
}
// 宿主 → 场景（节奏输入）
"rpg_qizhen_fishing_input": {
  action: "left" | "right" | "hook"; type: "press" | "release"; pointerType?: string;
}
// 场景 → 全局（domain）
"qizhen_fishing_note_hit": { sessionId: string; spotId: string; index: number; judgment: string }   // 仅非 miss，绑命中音效
"qizhen_fishing_note_judged": { sessionId: string; spotId: string; index: number; judgment: string; errorMs: number; tension: number; combo: number }
"qizhen_fishing_warning": { sessionId: string; spotId: string; kind: "tension_low" | "tension_high" | "hold_broken"; tension: number }
// 场景 → 宿主（intent）
"rpg_qizhen_fishing_resolve_requested": { sessionId: string; spotId: string; result: QizhenFishingResult }
// 宿主 → 全局
"qizhen_fishing_completed": { sessionId: string; spotId: string; grade: string; accuracy: number }
// 场景或宿主 → 全局
"qizhen_fishing_failed": { sessionId: string; spotId: string; reason: string }
"qizhen_fishing_cancelled": { sessionId: string; spotId: string; reason: "hidden" | "shutdown" }
```

- `sessionId` 由场景在 attempt 时生成（如 `fish-${Date.now()}-${counter}`）；宿主暂存 pending session，resolve 时核对一致才调用 `castAt`，且每个 session 只结算一次（验收 10）。
- 宿主在 `qizhen_fishing_completed/failed/cancelled` 后清除钓鱼 UI 状态。

### 8.3 音频时间线（`src/data/chapter3-qizhen.audio.json` 新增键）

| 事件键 | cues |
|---|---|
| `qizhen_fishing_started` | music `music_qizhen_fishing` play（loop:false, volume ≈0.22）+ sfx `fx_qizhen_fishing_start` |
| `qizhen_fishing_note_hit` | sfx `fx_qizhen_fishing_hit`（volume ≈0.22） |
| `qizhen_fishing_warning` | sfx `fx_qizhen_fishing_warning` |
| `qizhen_fishing_completed` | music stop + sfx `fx_qizhen_fishing_success` |
| `qizhen_fishing_failed` | music stop + sfx `fx_qizhen_fishing_fail` |
| `qizhen_fishing_cancelled` | music stop |

新增 5 个音效（`group: "fishing"`，各 0.3–1.8 s）：`fx_qizhen_fishing_start`（约 0.8 s 抛竿入水+收线轮）、`fx_qizhen_fishing_hit`（0.3 s 短促木鱼/收线点击）、`fx_qizhen_fishing_warning`（约 0.6 s 钓线绷紧吱声）、`fx_qizhen_fishing_success`（约 1.2 s 水花+明亮捕获音）、`fx_qizhen_fishing_fail`（约 1.0 s 断线闷响+轻水花）。

场景另运行常开低音量 Web Audio 节拍器（每拍一次短促点击，gain ≤ 0.05）：既辅助节奏，也在浏览器阻止 HTMLAudio 时保证「视觉水纹 + 程序化点击」仍可完成主线（验收 8）。判定反馈音以时间线 `fx_qizhen_fishing_hit` 为主，不再叠加程序化判定音，避免双重发声。

## 9. 模块 API 契约

### 9.1 `src/scenes/rpg/QizhenFishingRhythmModel.ts`（纯 TypeScript，禁止 import Phaser）

```ts
export type QizhenFishingAction = "left" | "right" | "hook";
export type QizhenFishingChartId = "locker_key" | "net_frame" | "fish" | "paper";
export type QizhenFishingJudgment = "perfect" | "great" | "good" | "miss";
export type QizhenFishingGrade = "S" | "A" | "B" | "C";
export type QizhenFishingFailReason = "line_snapped" | "hook_escaped";
export type QizhenFishingSessionPhase = "idle" | "running" | "completed" | "failed" | "cancelled";
export type QizhenFishingWarningKind = "tension_low" | "tension_high";

export interface QizhenFishingNote {
  index: number; beat: number; timeSec: number; spawnSec: number;
  action: QizhenFishingAction; holdBeats: number; holdSec: number;
  cue: "left_intro" | "right_intro" | null;
  judgment: QizhenFishingJudgment | null; holding: boolean;
}

export interface QizhenFishingResult {
  chartId: QizhenFishingChartId; grade: QizhenFishingGrade; passed: boolean;
  accuracy: number; perfect: number; great: number; good: number; miss: number;
  maxCombo: number; finalTension: number;
}

export interface QizhenFishingModelEvents {
  onNoteJudged(note: QizhenFishingNote, judgment: QizhenFishingJudgment, errorMs: number, tension: number): void;
  onHoldBroken(note: QizhenFishingNote, tension: number): void;
  onWarning(kind: QizhenFishingWarningKind, tension: number): void;
  onCompleted(result: QizhenFishingResult): void;
  onFailed(reason: QizhenFishingFailReason, tension: number): void;
}

export interface QizhenFishingRhythmModelOptions {
  chartId: QizhenFishingChartId;
  now: () => number; // 单调递增秒（Web Audio 时钟）
  assist?: boolean;
  events: QizhenFishingModelEvents;
}

export class QizhenFishingRhythmModel {
  constructor(options: QizhenFishingRhythmModelOptions);
  readonly phase: QizhenFishingSessionPhase;
  readonly tension: number; readonly combo: number; readonly maxCombo: number;
  readonly judgedCount: number; readonly totalNotes: number;
  readonly notes: readonly QizhenFishingNote[];
  readonly elapsedSec: number; readonly leadSec: number; readonly assist: boolean;
  start(): void;                       // t0 = now()
  handlePress(action: QizhenFishingAction): void;
  handleRelease(action: QizhenFishingAction): void;
  update(): void;                      // 每帧调用：超时 miss、长按完成、越界计时、结算
  cancel(): void;                      // phase → "cancelled"，之后不再发任何事件
}
```

同时导出常量：

```ts
export const QIZHEN_FISHING_TIMING = {
  beatSec: 0.625, leadSec: 1.25, assistLeadSec: 1.5625,
  perfectMs: 70, greatMs: 130, goodMs: 190, assistGoodMs: 230,
  holdReleaseSlackSec: 0.08,
} as const;
export const QIZHEN_FISHING_TENSION = {
  initial: 50, min: 0, max: 100,
  perfectRecover: 4, greatShift: 3, goodShift: 7,
  missPenalty: 14, wrongActionPenalty: 16, holdBreakPenalty: 12,
  warnLow: 20, warnHigh: 80, passMin: 15, passMax: 85,
  failSustainMs: 350, assistFailSustainMs: 700,
} as const;
```

行为要点（全部见 §4/§5）：`start()` 时 `phase="running"`；`elapsedSec = now() − t0`；辅助模式在构造时剔除小数拍音符；`onCompleted` 在 `elapsedSec ≥ durationSeconds` 且全部音符已判定后触发；越界计时在 `update()` 内累计。

### 9.2 `src/scenes/rpg/QizhenFishingRhythmVisual.ts`（Phaser 视觉，可 import 模型类型与常量）

```ts
export interface QizhenFishingRhythmVisualOptions {
  scene: Phaser.Scene;
  model: QizhenFishingRhythmModel;
  anchor: { x: number; y: number };        // 浮标世界坐标
  targetLabel: string;
  lineFrom?: () => { x: number; y: number } // 船头世界坐标（钓线）
  reducedMotion: boolean;
  depth?: number;                           // 默认 2600
}

export class QizhenFishingRhythmVisual {
  constructor(options: QizhenFishingRhythmVisualOptions);
  update(): void;                                                    // 每帧
  notifyJudgment(note: QizhenFishingNote, judgment: QizhenFishingJudgment, errorMs: number): void;
  notifyHoldBroken(note: QizhenFishingNote): void;
  notifyWarning(kind: QizhenFishingWarningKind, tension: number): void;
  playResult(result: QizhenFishingResult, onComplete: () => void): void;  // ≥800 ms 评级 + 飞入
  playFailure(reason: QizhenFishingFailReason | "grade", onComplete: () => void): void; // ≥600 ms
  destroy(): void;
}
```

### 9.3 控制器（`src/modules/ChapterThreeQizhenLakeController.ts`）

```ts
/** castAt 的只读镜像：相同验证、零副作用、零事件、零存档写入。 */
precheckCast(spotId: QizhenFishingSpotId): QizhenActionResult
```

实现方式：把 `castAt` 的验证段抽成私有纯函数（`direct_paper_failure` 分支只返回结果、**不**递增计数器），`castAt` 保持对外行为不变（其内部的纸条直抛计数等副作用维持原样）。

## 10. 文件改动清单

新增：

- `src/data/chapter3-qizhen-fishing.charts.json` — 四张谱面（§3）
- `src/scenes/rpg/QizhenFishingRhythmModel.ts` — 判定/张力引擎（§9.1）
- `src/scenes/rpg/QizhenFishingRhythmVisual.ts` — 水纹环/图标/状态栏/钓线（§9.2）
- `docs/chapter-3-qizhen-fishing-rhythm.md` — 本文件

修改：

| 文件 | 内容 |
|---|---|
| `src/modules/ChapterThreeQizhenLakeController.ts` | 抽验证 + `precheckCast`（§9.3） |
| `src/scenes/rpg/QizhenLakeScene.ts` | 拦截抛竿链路、会话状态机、镜头/船速/模式锁、键盘路由、事件转发、取消与恢复 |
| `src/scenes/rpg/RpgGameHost.tsx` | attempt/resolve 路由、钓鱼触屏按钮（pointerdown 记拍）、隐藏道具栏与模式切换 |
| `src/styles/rpg.css` | `.rpg-kayak-controls.is-fishing` 等宽三键、390×844 ≥44px |
| `src/data/chapter3-qizhen.audio.content.json` | 1 首音乐 + 5 个音效条目 |
| `src/data/chapter3-qizhen.audio.json` | §8.3 时间线键 |
| `scripts/generate-chapter3-qizhen-audio.mjs` | 音乐数量校验 3 → 4 |
| `scripts/generate-chapter3-qizhen-sfx-audio.mjs` | 音效数量校验 10 → 15、2 组 ×5 → 3 组 ×5 |

## 11. 生命周期与存档规则

- 谱面运行时间、当前音符、瞬时张力全部 runtime-only，不入存档；存档只保留既有道具与剧情阶段（本玩法不新增存档字段）。
- 页面隐藏（`visibilitychange` → hidden）或场景 shutdown：取消本轮（`qizhen_fishing_cancelled`），模型 `cancel()`，视觉销毁，镜头/输入/模式锁全部恢复。
- 重新加载检查点不会恢复到进行中的谱面（天然满足：会话无持久态）。
- 失败/取消后玩家可立即再次抛竿，新一轮从四拍预备开始。

## 12. 验收条件

1. Blink/Gecko/WebKit 中，第 31 拍视觉位置与 Web Audio 时钟偏差 ≤ 25 ms。
2. `390×844` 下三枚按钮均可见，实际触控区域 ≥ `44×44 CSS px`。
3. 触屏一次按下只生成一次节奏输入，不同时触发划桨移动。
4. 钓鱼期间皮划艇不漂出交互半径，不因残留速度撞上障碍。
5. 钓鱼失败不提前获得钥匙、网框、小鲤鱼或纸条。
6. 小鲤鱼失败不消耗鱼食颗粒。
7. 普通鱼钩碰纸条继续走原有即时失败逻辑。
8. 音频被浏览器阻止时，视觉水纹与低音量程序化点击仍允许完成主线。
9. `prefers-reduced-motion` 下取消大幅缩放，只保留离散半径变化、图标与数字倒计时。
10. 成功捕获纸条后只触发一次围栏开启与黑天鹅追逐。
11. 离线单文件（`npm run build:single`）中音乐、谱面 JSON、音效与判定逻辑全部可用。
12. 重新加载检查点时不会恢复到一段已经进行一半的谱面。

## 13. 实施顺序

先打通钥匙 10 秒教程谱面的完整闭环（音乐节拍 → 浮标判定 → 触控输入 → 剧情延迟发奖），验证通过后再扩展到网框、小鲤鱼与纸条谱面。

## 14. 2026-08-11 实施状态

已实施：

- 四张 JSON 谱面、纯 TypeScript 判定/张力模型和 Phaser 水纹视觉全部接入启真湖场景。
- 钥匙、网框、小鲤鱼、纸条均改为 `precheck → rhythm → resolve` 延迟结算；漂浮鱼竿拾取与普通鱼钩直抛纸条继续走原有即时逻辑。
- 桌面键盘和移动端三键输入已接入；演奏期间船速归零、镜头锁浮标、划桨手势停用，模式切换、道具栏、普通字幕不显示。
- 同目标两次失败后第三次显示“辅助”并启用宽判定；成功后该目标失败计数清零。
- 页面隐藏、场景卸载和运行状态变更会取消本轮，不写入存档，不消耗剧情道具。

实玩证据：

- 四张谱面使用可控单调时钟逐音回放，均得到 `S / passed=true / accuracy=1 / tension=50`。
- Blink `1280×720` 以真实键盘事件完成 10 秒钥匙谱：开始前钥匙为 `false`，通过后才变为 `true`；过程中摄像机为 `fishing_lock`、船速为 `0`。
- Blink `390×844` 以真实触摸事件命中首个提竿音符，判定 `perfect`，三个按钮约为 `75×75 CSS px`，文档无溢出，船速仍为 `0`。
- 小鲤鱼谱无输入失败后，`fishFeedPellets=true / smallCarp=false / fishCaught=false`。
- 20 秒纸条谱以真实键盘事件完成后，`paperCaptured=true / phase=swan_chase / zone=channel / chaseAttempts=1`；`qizhen_paper_captured` 与 `qizhen_fishing_completed` 各发生一次，且 `playResult` 未调用。
- Chromium、Firefox、WebKit 均完成首个提竿判定，无页面或控制台错误。

音频边界：

- `qizhen.fishing` 内容配置、生成参数和时间线键已写入。MiniMax CLI 在本轮再次返回“已达到 Token Plan 用量上限”，因此 `music_qizhen_fishing.mp3` 与四曲生成清单仍未产生。
- 为保证主线可玩，场景使用与判定同源的 `AudioContext.currentTime` 短点击节拍器；音频上下文不可用时回退到 `performance.now()`。
- 新增 5 个专用钓鱼 SFX 尚未生成，当前时间线临时复用已验证的启真湖短音效。恢复额度后才能完成音频验收条目 1 和 11。
