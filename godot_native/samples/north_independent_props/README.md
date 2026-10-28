# 北教逐对象调试预览（尚未通过净地板验收）

**范围：7 类真实网页素材、53 个独立物件节点，不是整层重建。**

普通启动和正式导出仍使用 `main`（PR173）的原 A1 墙面/合体桌椅配置，不加载这批独立物件，也不启用它们新增的补底清理。只有显式调试预览启用 53 节点。`755_production` 或非 debug 构建即使带环境变量也不能开启。

- 105：讲台、书柜、黑板、小公告框、盆栽，各 1 个。
- 原 24 组桌椅：每组独立桌 + 独立椅，共 48 个节点；仍是 24 组、48 个原基座。
- 第一批两物件的独立检查点：`9fe616af50248745148475403bb79210a78d48e2`。

## 当前视觉边界

物件拆分、脚点、原交互、五时态和缺图回退已有检查。**旧地板清理条带有可见矩形接缝，当前候选未通过该项视觉验收。**
两次原生补底实验出现拖影，已拒收；后续程序地板又产生明显材质/边界差异，已备份并从活动项目撤下。104 的两次网页净底修改改变了原网格，均未接入；105 尚无合格净底。没有把缺失、网格错位或风格不同的底图当成可用素材。

原网页 PNG 有真实 alpha。可见地板矩形来自旧母图去物件后的补底条带，不是 PNG 的不透明背景。不能以素材透明或单元测试通过代替净地板视觉验收。

## 运行实际游戏检查点

```sh
GODOT_BIN=/path/to/Godot-4.7.1 node godot_native/samples/north_independent_props/run.mjs
```

启动器仅为子进程设置 `NORTH_PROP_OBJECT_PREVIEW=1`，并使用一次性存档目录。普通 `godot --path godot_native` 不启用预览；环境变量不写入存档。`north-baseline-objects.json` 是 PR173 默认配置的逐字节快照；两条路径共用碰撞、时态和墙体合成方法。

原生世界、原玩家、原控制器和原 UI；WASD / 方向键移动，Space 使用原讲台交互。启动器使用一次性 DEV 存档目录，不读写正式存档，也不代表完成正式剧情。
缺任意所需真实新图时，预览拒绝启动；正式世界整组回退到原母图、原遮挡和原碰撞。

## 绘制顺序

```text
Background：原时态底图与有界清理
BehindActorSourceCoordinates：独立后景物件 + 墙挂背景外观
ActorAndFrontTargets：原角色与目标绘制
WallRevealSingleAlpha：墙 + 两个墙挂 reveal 外观，一次 0.78 合成
FrontOfActorSourceCoordinates：独立前景物件
LegacyForegroundAndHUD：原前景、UI
```

- 不提升 z_index；不越过原 UI。
- 地面物件按脚底线独立前后排序。桌脚线为原 B−5.8，椅脚线为原 B。
- 黑板/小框的视觉底边与墙深度 584 分开；不烘焙回墙面。统一一次 reveal 保留角色 22% 可见，避免两次 0.78 后只剩 4.84%。
- 原下载母版不修改；nearest + 等比注册。材质将基础颜色映射到既定 shared32，接受像素的基础 alpha 为 1、其余为 0；之后再施加当前时态与模式调光。

## 明确保留

墙碰撞 `[1226,584,381,12]`。讲台目标 `a1_classroom_105_lectern_terminal`，矩形 `[1380,558,62,56]`、半径 100、浅色模式、动作 `c4_class105`。其余新物件不增加动作；105 黑板不冒用 104 擦痕交互，小框不冒用大厅公告板交互。

原 24 组坐标、48 个基座 ID/数值、剧情/存档结构及 A2/A3 保持不变。

## 验证

`test_north_independent_props.gd`：真实资产哈希、独立节点、脚点、墙挂深度、桌椅间排序、五时态、原交互。
`test_north_prop_fail_closed.gd`：7 类素材各自缺失、整组回退及楼层隔离。
`test_north_preview_gate.gd`：默认配置哈希、默认无独立节点/新增清理、production 拒绝、显式 53 节点预览、两路径相同碰撞/交互/存档、PR173 墙体精确接触。
Headless 检查不等于图形、浏览器或物理手机验收。

实际图形桌面截图：

```sh
NORTH_PROP_CAPTURE_DIR=/absolute/captures GODOT_BIN=/path/to/Godot-4.7.1 \
  node godot_native/samples/north_independent_props/capture.mjs
```

支持环境变量：
- `NORTH_PROP_CAPTURE_CLEANUP_ONLY=1`：隐藏新物件/角色，直接检验旧图清理，不把该诊断图当完整游戏。
- `NORTH_PROP_CAPTURE_ALPHA_PROBE=1`：实际 GPU 三帧对照检验墙后角色 22% 混合。
- `NORTH_PROP_CAPTURE_PALETTE_PROBE=1`：实际 GPU 逐素材验证基础 shared32 与二值 alpha。
- `NORTH_PROP_PLAY_CAPTURE_DIR=/absolute/path`：在可玩预览中按 F8 保存原生 viewport 和实际位置/事实观察。

所有图形捕获器均拒绝 headless，不用离线拼图冒充运行截图。
