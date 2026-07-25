# 《7:55》React / Phaser 到 Godot 的分阶段迁移方案

## 1. 决策与目标

2026 年 7 月 25 日，项目重新启动 Godot 迁移。最终目标是让 Godot 承担校园 RPG、室内场景、竖屏小游戏、手机界面、剧情状态、存档和多端导出，现有 React / Phaser 工程在迁移期间继续作为已验证实现与行为参照。

迁移采用逐段可运行的方式。每个阶段都要具备真实入口、明确状态、自动化测试和回退路径。任何尚未达到行为等价的 Godot 场景都不能直接替换默认正式入口。

## 2. 当前迁移策略

### 2.1 双运行时过渡

迁移期保留两个 RPG 宿主：

- 默认：React + Phaser，使用现有正式流程。
- 迁移预览：React 外壳 + Godot Web，使用 `?engine=godot` 开启。

示例：

```text
http://localhost:5173/?engine=godot&devCheckpoint=c2-library-gate
```

React 继续提供手机壳、任务栏、剧情演出层和开发者检查点。Godot 当前承载校园地图、人物、镜头与运行时状态快照。达到完整等价后，再把默认值切换为 Godot。

### 2.2 状态归属

第一阶段由 React `GameState` 继续作为剧情事实来源。React 通过 `postMessage` 向 Godot 发送精简状态：

```json
{
  "source": "seven-fifty-five-react",
  "type": "hydrate",
  "payload": {
    "state": {
      "runtimeMode": "rpg",
      "rpgScene": "campus_bootstrap",
      "rpgCheckpoint": "campus_library_gate",
      "themeMode": "normal",
      "quest": {},
      "canteenHunt": {}
    }
  }
}
```

Godot 通过同一协议回传：

- `ready`：引擎已启动。
- `snapshot`：人物位置、镜头、场景和检查点。
- `event`：Godot 产生的领域事件。

后续阶段会把控制器和存档逐步迁入 Godot。状态归属切换必须按模块完成，禁止同一剧情事实同时由两侧写入。

### 2.3 素材归属

迁移期间，现有仓库素材仍是唯一源文件。`godot/assets/asset-manifest.json` 声明需要同步的内容，`npm run godot:sync` 将其复制到 `godot/assets/generated/`。

首批同步：

- `4516 × 3420` 紫金港校园底图。
- 校园运行时坐标与碰撞清单 JSON。
- 人物上、下、侧向共 12 帧 PNG。

`godot/assets/generated/` 是可重建目录，不进入 Git 历史。素材替换先修改现有源文件与清单，再执行同步和测试。

## 3. 阶段安排

## 阶段 0：迁移基础与校园可运行切片

本阶段由当前分支实现。

范围：

- 建立 Godot 4.7.1 工程。
- 使用 GL Compatibility，保证 Web 导出覆盖面。
- 建立素材同步清单。
- 迁移校园底图、人物动画、WASD / 方向键移动、Shift 加速、镜头跟随和缩放。
- 读取原运行时清单中的校园、图书馆和食堂检查点。
- 建立 React 与 Godot 消息桥。
- 提供 `?engine=godot` 灰度入口。
- 加入 Godot 无界面测试和 Playwright 视觉冒烟。

当前明确缺口：

- 尚未解析现有压缩可行走位图。
- 尚未迁移点击寻路、空气墙、建筑遮挡和场景入口交互。
- 寝室、图书馆、食堂仍由 Phaser 实现。
- 手机应用与剧情控制器仍由 React / TypeScript 实现。
- Godot Web 导出尚未进入现有离线单文件交付包。

阶段完成条件：

- Godot 工程可在 macOS 与 CI 无界面启动。
- 校园底图和 12 帧人物素材成功导入。
- 角色在 canonical spawn、图书馆检查点和食堂检查点正确生成。
- 桌面键盘和 `390 × 844` 触控均能移动人物并停止输入。
- 镜头缩放上下界有效。
- Playwright 截图中 Canvas 非空、无文档溢出、关键控件不重叠。
- Phaser 默认入口保持原行为。

## 阶段 1：校园运行时等价

范围：

- 在 Godot 中解析 `walkability.bitsBase64`。
- 生成或导入导航区域与碰撞边界。
- 迁移点击寻路、不可达反馈和路径指示。
- 迁移图书馆、食堂地标与入口触发。
- 迁移建筑遮挡裁片、纵深和人物名称标签。
- 迁移残影脚印、深色光照和校园追踪状态。
- 实现检查点重入与移动端交互按钮。

验收用例：

1. 默认出生点到图书馆门口可达。
2. 图书馆花坛、水体和未开放区域不可穿越。
3. 食堂入口进入与返回保持同一检查点。
4. 点击不可达区域不会让人物卡进碰撞体。
5. `canteen-hunt` 状态的脚印与暗色表现可读取。
6. Blink、Gecko、WebKit 的输入与画布比例一致。

## 阶段 2：RPG 室内场景迁移

按三个独立 PR 推进：

1. 寝室：校园卡拾取、自动移动、手柄启用、出口门控。
2. 图书馆：入口记录、022、书架、失物登记、PASS 与重入。
3. 食堂：深浅模式、餐盘、点单、取餐、封堵出口、自行车车锁。

每张内景继续使用当前批准的源图和 source-pixel 碰撞表。Godot 场景必须覆盖：

- 可见家具阻挡。
- 清晰通道。
- 正确出生点。
- 道具拖放或等价操作。
- 动画中断与重入恢复。
- 键盘、指针和触控入口。

## 阶段 3：控制器、任务和存档迁移

范围：

- 将 `ActOneBootstrapController`、`LibraryFinalsController`、`ChapterThreeCanteenController` 和 Bike Arcade 规则迁入 Godot。
- 使用 Autoload 与 Resource 组织领域状态。
- 为领域事件建立类型化名称和载荷校验。
- 迁移 `FeatureAccess` 与任务 ViewModel。
- 迁移存档版本、备份恢复和旧版本清洗。
- 提供 React 存档到 Godot 存档的一次性导入器。

状态切换原则：

- 一个控制器迁入后，其成功状态只由 Godot 写入。
- React 在过渡期只消费 Godot 快照和事件。
- 迁移完成的字段需要加入跨引擎一致性测试。
- 存档切换前保留原 JSON 备份和回退入口。

## 阶段 4：手机界面与竖屏小游戏迁移

范围：

- 使用 Godot `Control`、`Container`、`Theme` 和可复用场景重建 `430 × 860` 手机逻辑框。
- 迁移闹钟、微信、CC98、浙大钉、体艺、天气、照片、签到、盆栽等页面。
- 迁移控制中心、任务栏、物品栏、文档查看和拖放。
- 迁移求是潮骑行小游戏。
- 统一横屏 RPG 与竖屏手机的场景切换和输入焦点。

手机页面按功能组迁移，每个 PR 只覆盖一个完整操作链。视觉等价由截图基线、文字可读性和触控热区共同判断。

## 阶段 5：默认切换与旧运行时退出

切换前必须满足：

- 第一章、第二章和第三章已有流程全部可通关。
- 所有正式 DEV 检查点拥有 Godot 等价入口。
- 旧 React 存档可以导入。
- 桌面、移动端和离线交付均通过。
- 关键帧时间、加载体积和内存符合预算。
- Godot 版本经过一次完整发布候选回归。

切换步骤：

1. 将默认 RPG 引擎改为 Godot，保留 `?engine=phaser` 回退一个发布周期。
2. 将手机界面默认入口切到 Godot。
3. 停止在 Phaser 中新增玩法。
4. 删除无引用的 Phaser 场景、React 页面与桥接代码。
5. 移除 `phaser`、`react`、`react-dom`、`zustand` 等依赖前，再执行一次全仓库引用扫描。

## 4. 目录结构

```text
godot/
  project.godot
  export_presets.cfg
  assets/
    asset-manifest.json
    generated/              # npm run godot:sync 生成
  scenes/
    main.tscn
  scripts/
    main.gd
    migration_state.gd
    web_bridge.gd
    campus_runtime.gd
    player_controller.gd
  tests/
    smoke_test.gd

src/
  core/GodotBridge.ts       # React 过渡桥
  core/RuntimeEngine.ts     # engine=godot 灰度开关
  scenes/rpg/GodotRpgGameHost.tsx
```

## 5. 开发命令

```bash
npm ci
npm run godot:sync
npm run godot:verify
npm run godot:check
npm run godot:test
npm run godot:export:web
npm run dev
```

macOS 默认查找：

```text
/Applications/Godot.app/Contents/MacOS/Godot
```

也可以显式指定：

```bash
GODOT_BIN=/path/to/Godot npm run godot:test
```

迁移预览：

```text
http://localhost:5173/?engine=godot&devCheckpoint=c2-library-gate
```

## 6. 测试顺序

每次迁移 PR 按以下顺序验收：

1. 动态边界测试：Godot 无界面启动、状态切换、坐标极值、场景重入和输入停止。
2. Playwright 视觉检查：桌面与移动视口、Canvas 非空、真实操作、溢出、比例和重叠。
3. 静态审查：GDScript 解析、TypeScript、资源清单、生成目录、导出结构和 `git diff --check`。

失败时记录具体检查点、当前场景、输入方式、坐标、错误日志和截图。禁止通过删除断言或扩大无条件等待掩盖问题。

## 7. 回退

当前阶段的回退开关为 URL 参数：

```text
默认或 ?engine=phaser  -> 现有 Phaser RPG
?engine=godot          -> Godot 迁移预览
```

Godot 导出失败时不会影响默认 Phaser 构建。迁移 PR 使用独立分支和 Squash 合并；若进入 `main` 后出现阻断，可整体 revert 对应迁移 PR。
