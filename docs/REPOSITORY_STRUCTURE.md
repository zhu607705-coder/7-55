# 《7:55》仓库目录与依赖边界

本文规定仓库文件应放置的位置、各层职责和允许的依赖方向。新增文件先确定所属层，再开始实现。无法归类的文件应在 PR 中说明原因，避免继续堆放在仓库根目录。

## 1. 当前目录图

```text
7-55/
├── config/                     团队、预览与协作配置
├── docs/                       策划、架构、验收、迁移和发布文档
├── godot/                      Godot 工程、GDScript、场景与导出配置
├── scripts/                    构建、资源处理、校验和测试辅助脚本
├── src/
│   ├── assets/                 正式运行时素材
│   ├── components/             跨页面 React 组件与壳层
│   ├── core/                   状态、事件、路由、存档和共享类型
│   ├── data/                   剧情、任务、地图、音频和静态配置
│   ├── demos/                  独立预览入口和预览页样式
│   ├── modules/                控制器、导演层和跨场景玩法逻辑
│   ├── scenes/
│   │   ├── phone/              手机应用与竖屏小游戏
│   │   └── rpg/                Phaser RPG 场景和迁移宿主
│   ├── App.tsx                 产品运行时装配
│   └── main.tsx                Web 启动入口
├── tests/
│   ├── core/                   控制器、状态、存档和规则测试
│   └── repo/                   仓库契约、PR 规范和结构测试
├── .github/                    CI、PR 模板和 GitHub 配置
├── index.html                  正式游戏入口
├── campus-map-demo.html        校园地图独立入口
└── project-preview.html        仓库预览与协作门户入口
```

## 2. 依赖方向

推荐依赖方向如下：

```text
src/data
   ↓
src/core ← src/modules
   ↓          ↓
src/components / src/scenes/phone / src/scenes/rpg / godot bridge
   ↓
src/App.tsx
```

具体约束：

1. `src/core` 保存跨运行时事实，不导入 React 页面、Phaser Scene 或 Godot 生成产物。
2. `src/modules` 可以依赖 `src/core` 与 `src/data`，不直接操作 DOM、Canvas 或具体场景节点。
3. 页面和场景提交请求给控制器，动画结束、音频结束和路由变化不能直接写剧情进度。
4. `src/data` 只保存静态数据、类型安全的配置和素材索引，不在模块加载时修改状态。
5. `src/scenes/phone` 与 `src/scenes/rpg` 不相互导入页面实现，共享逻辑移入 `core` 或 `modules`。
6. Godot 迁移期通过协议桥读取共享事实。正式存档写入权在独立 PR 验证完成前继续由 React 状态层持有。

## 3. 文件分类规则

### 3.1 运行时代码

运行时代码进入 `src/` 或 `godot/`。仓库根目录不新增普通业务脚本。

- React 组件使用 `.tsx`。
- 纯领域逻辑使用 `.ts`。
- Godot 逻辑使用 `.gd`，场景使用 `.tscn`。
- 一个文件只承担一个清晰职责。超过约 500 行时，应优先拆出模型、规则、渲染或适配层。

### 3.2 数据和素材

- 剧情与任务配置进入 `src/data/`。
- 正式图片、音频和图标进入 `src/assets/`。
- 原始候选素材、临时放大图和 AI 生成中间稿不进入 Git 历史。
- Godot 使用 `godot/assets/asset-manifest.json` 从正式素材源同步，避免维护两份人工副本。
- 二进制文件替换必须在 PR 中说明来源、用途、尺寸变化和压缩结果。

### 3.3 测试

- 状态、控制器、存档和规则测试进入 `tests/core/`。
- PR、目录、构建和仓库约束测试进入 `tests/repo/`。
- 浏览器端到端测试进入后续统一的 `tests/e2e/`。
- 测试生成的截图、trace、日志进入 `artifacts/`，由 CI 上传，不能提交。

### 3.4 文档

- 长期有效的规则和设计进入 `docs/`。
- `README.md` 只承担项目入口、常用命令和关键文档导航。
- 过程记录保留结论、触发方式和验证证据，不复制整段终端输出。
- 行为与规则同时变化时，代码和文档在同一个 PR 更新。

### 3.5 生成目录

以下目录由脚本生成，不进入 Git 历史：

```text
dist/
demo/
public/godot/
godot/assets/generated/
artifacts/
```

生成失败时修复源码、配置或生成脚本。禁止直接修改生成结果后提交。

## 4. 四人并行时的路径所有权

`config/team-workstreams.json` 是团队路径分工的事实来源。每个通道设置一名主负责人，并设置两个交叉审查通道。

默认分区：

| 通道 | 主要范围 | 常见交付 |
|---|---|---|
| A 手机端与界面 | `src/scenes/phone`、`src/components`、`src/styles` | 手机页面、布局、字幕、可访问性 |
| B 状态与控制器 | `src/core`、`src/modules`、`tests/core` | 状态机、任务、存档、领域事件 |
| C 地图与引擎 | `src/scenes/rpg`、`godot`、地图脚本 | 场景、碰撞、寻路、镜头、迁移 |
| D 内容与交付 | `src/data`、`src/assets`、`tests`、`scripts`、`.github`、`docs` | 文案、素材、测试、CI、发布 |

路径所有权用于降低冲突，并不阻止协作。跨通道修改需要在 PR 正文写出涉及路径和审查人。

## 5. 共享高风险文件

以下文件容易影响所有人的工作，修改前应登记：

```text
package.json
package-lock.json
vite.config.ts
src/core/types.ts
src/core/GameState.ts
src/core/SaveStore.ts
.github/workflows/**
```

处理方式：

1. 群内登记负责人和预计完成时间。
2. 其他三人暂停对同一文件进行独立重构。
3. PR 保持单一目的，并由相邻通道审查。
4. 基础 PR 合并后，其他分支立即 rebase。

## 6. 根目录允许文件

根目录只保留：

- 产品与演示 HTML 入口。
- Node、TypeScript、Vite 和 Git 配置。
- `README.md`、`CONTRIBUTING.md`、`AGENTS.md`、`CLAUDE.md`。
- 许可证、锁文件和正式清单。

ZIP、截图、日志、临时 JSON、录屏和候选素材不得放在根目录。`npm run verify:structure` 会检查常见违规文件。

## 7. 新模块落位检查

新增功能提交前确认：

1. 领域事实是否已经进入 `core` 或控制器。
2. 场景是否只负责输入、动画和表现。
3. 数据是否可以由测试构造和读取。
4. 新路径是否已经加入团队职责清单。
5. 新生成物是否已加入 `.gitignore`。
6. 预览入口、测试命令和验收文档是否同步更新。
