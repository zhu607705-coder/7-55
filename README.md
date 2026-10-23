# 7:55

[![Web CI](https://github.com/zhu607705-coder/7-55/actions/workflows/web-ci.yml/badge.svg?branch=main)](https://github.com/zhu607705-coder/7-55/actions/workflows/web-ci.yml)

《7:55》Godot 原生游戏与保留的网页版本。

项目原创源代码采用 [Apache License 2.0](LICENSE)，署名及第三方许可说明见 [NOTICE](NOTICE)。引擎、依赖、字体和素材保留各自许可，素材来源见 [ASSETS.md](ASSETS.md)。

当前 Godot 后续开发在[独立 Godot 库](https://github.com/zhu607705-coder/7-55-godot)进行，该库当前为公开库。2026-10-21 的本机候选包含图书馆、剧场独立物件、实体门通行、可重玩的《借扇成蝶》，以及点地行走和直接触摸物件的手机操作。网页构建从 `godot_native/` 导出独立 Godot WebAssembly；手机应用保持竖屏，地图和舞台提供横屏入口。构建与验收方式见 [Godot 浏览器交付](godot_native/docs/GODOT_WEB_RELEASE.md)。原公开站的发布状态与本机候选分开记录。

2026-10-23 当前源码已通过 [Godot PR #2](https://github.com/zhu607705-coder/7-55-godot/pull/2) 合并，合并提交为 `e66550c2be4f8d17eed0fcb2454d9a0730eda9fb`；原库同步见 [7-55 PR #164](https://github.com/zhu607705-coder/7-55/pull/164)。实现目录为 [`godot_native/`](godot_native/README.md)，包括真实章节懒加载、gzip 传输与缓存、手机返回和认证对白、独立控件重建的学在浙大入口，以及此前保留的本地整合内容。聚焦验收和限制分别见[加载记录](godot_native/docs/PERFORMANCE_LAZY_LOADING_20261023.md)与[签到入口记录](godot_native/docs/NATIVE_LEARN_REBUILD_20261023.md)，素材来源见 [ASSETS.md](ASSETS.md)。本次未生成新的 Release 归档，源码合并不代表线上已替换；全量原生检查仍有未解决用例。

2026-10-22 选定的双库8个PR已合并远端；本地后续整合见[合并记录](godot_native/docs/TWO_REPOSITORY_MERGES_20261022.json)与[手机操作适配验收](godot_native/docs/PR160_LOCAL_ADAPTATION_20261022.json)。本机 `exports/web-pr160-integrated-20261022/` 保留底部工具、直接展示的物品和右下角手机入口；未提交的本地修改尚未上传。寝室独立样段的人物比例见[尺寸校准](godot_native/docs/DORM_CHARACTER_SCALE_20261022.json)，后续开发采用[游戏技能参考规则](godot_native/docs/GAMEDEV_SKILLS_REFERENCE.md)。

2026-10-23 已合并公开库 #161，包含 #162 的手机文件选择与提示修复，并整合进当前本地 Godot 分支。本机候选保留密集字流、原应用图标、画面内物品栏、底部提示及直接点按操作；原有本地改动已备份，未自动提交上传。具体范围、501 个原生阶段、实际 Godot 浏览器验收及限制见[本轮整合记录](godot_native/docs/UPSTREAM161_LOCAL_INTEGRATION_20261023.json)。

本轮设计与操作见[图书馆、剧场和直接触摸](godot_native/docs/LIBRARY_THEATER_DIRECT_TOUCH_20261021.md)，具体构建及验证范围见[20261021 验收记录](godot_native/docs/LIBRARY_THEATER_ACCEPTANCE_20261021.json)。

正式 Godot 主线现为 [`main`](https://github.com/zhu607705-coder/7-55/tree/main)，不是旧的 React 主线快照。当前统一引擎与 Web 模板基线为 **Godot 4.7.1**；[PR #161](https://github.com/zhu607705-coder/7-55/pull/161) 已合入 `main`，分支来源与版本边界见 [整合记录](godot_native/docs/BRANCH_CONSOLIDATION.md)。打开
[`godot_native/project.godot`](godot_native/project.godot)，或在 Mac 上双击
[`godot_native/启动游戏.command`](godot_native/启动游戏.command)。当前整合、PR 来源和实测边界见
[`godot_native/docs/FULL_INTEGRATION_20261019.md`](godot_native/docs/FULL_INTEGRATION_20261019.md)。
编辑器开发入口包含正式剧情、校园漫游及独立动画与原型预览；正式网页仅开放剧情，不含章节跳转和北化研究地图。完整 Git 检出需先准备资源：

```bash
npm ci
npm run native:sync
npm run native:media # 需要 ffmpeg
npm run native:validate
```

自带 `assets/` 与 `data/source/` 的原生源码包可直接打开，无需 Node。
`npm run native:package` 生成这种自包含源码包；`npm run build` 和 `npm run web:build`
继续生成保留的 Web 参考版。开发边界见 [AGENTS.md](AGENTS.md)，详细原生说明见
[原生 README](godot_native/README.md)。远端合并状态与本地工作树分别记录在上述20261022合并记录中。
本轮推送范围、提交映射和后续验收边界见 [推送验收记录](godot_native/docs/PUSH_ACCEPTANCE_20261019.md)。

保留的 Web 参考版使用 Vite、TypeScript、React、Zustand、
Phaser 和 Three.js。React / TypeScript 负责手机端、共享状态、控制器、存档、任务、
道具和表现层；Phaser 负责校园地图与横屏 RPG 内景；第四章错位楼梯是
唯一经过批准的 Three.js 场景。

## 开始开发

需要 Node.js 22：

```bash
npm ci
npm run dev
```

剧院 Phaser 正式运行可使用开发检查点：

```text
http://127.0.0.1:5173/?devCheckpoint=c3-theater-entry&dev=1
```

保留的 Web 参考版在 HTTP、部署环境和直接打开 `demo/index.html` 时均使用同一 React/Phaser 运行时。

提交前执行：

```bash
npm run validate:release
```

该入口依次执行类型检查、关键玩法合同、地图与音频合同、生产构建、Chromium 启动检查、离线单文件构建与结构校验。局部开发可先运行 `npm run validate:quick`，控制器、存档、输入或 Phaser 行为变更运行 `npm run validate:critical`。完整分层、覆盖边界与扩展审计命令见 [Validation Strategy](docs/TESTING.md)。

生成单文件离线演示：

```bash
npm run build:demo
```

输出位于 `demo/index.html`。`demo/` 和 `dist/` 是可重建产物，不提交到普通 Git；
需要交付离线演示时，以完成日期命名并作为 GitHub Release 附件发布。

本分支离线预发布：[7-55-demo-20260905.html](https://github.com/zhu607705-coder/7-55/releases/download/demo-20260905/7-55-demo-20260905.html)。源码、资源与实现归档对应 `codex/release-20260905` / `demo-20260905`；本次上传不合并 `main`。对应实现归档与文件校验信息见 [ASSETS.md](ASSETS.md)。

已合并的上一版：[7-55-demo-20260904.html](https://github.com/zhu607705-coder/7-55/releases/download/demo-20260904/7-55-demo-20260904.html)。

### 独立校园大地图 Demo

```bash
npm run build:campus-map-demo
npm run verify:campus-map-demo
```

输出位于 `demo/campus-map-demo.html`。它只加载当前紫金港大地图运行时与演示状态，不会写入正式剧情存档。
需要交付离线演示时，请作为 Release 附件发布。

`npm run build` 已包含 TypeScript 类型检查。后续 demo 构建直接执行 Vite，避免在同一批次重复运行 `tsc --noEmit`。

GitHub Actions 会对包含 Markdown 与 `docs/` 以外变更的 PR 和 `main` 推送执行关键玩法行为回归、
第三章音频、校园地图、第四章 7:55、类型检查、生产构建、Chromium 启动检查和离线单文件验证。
纯文档变更会跳过自动流程，仍可在 Actions 页面手动执行包含扩展内容审计的全量验证。

## 目录

- `src/scenes/phone`：手机界面与剧情场景。
- `src/scenes/rpg`：RPG 领域契约与 Phaser 场景。
- `src/core`、`src/modules`：跨场景共享状态和玩法逻辑。
- `src/data`：对话、剧情、物品与音频配置。
- `scripts`：地图、素材和音频辅助脚本。
- `docs`：框架、关卡设计和开发记录。

运行时包含 `phone` 和 `rpg` 两种模式；两者应共用 `src/core` 与 `src/modules`
中的剧情进度和状态。

2026-08-25 清理的旧 `godot/` 与 `src/integrations/godot/` 混合运行时仍不得恢复。
该历史清理不禁止当前独立 `godot_native/` 迁移、原生导出、同步工具或原生 CI。
Web CI 与 Pages 继续验证和交付浏览器版本；原生 CI 验证 Godot 导入、启动、原生测试及
部分 TypeScript 模型差分。通过其中一套不能代替另一套验证或完整实际通关验收。

新增剧情前请先阅读 [CLAUDE.md](CLAUDE.md) 与
[框架说明](docs/framework-spec.md)。

## 四人协作

- [参与开发](CONTRIBUTING.md)
- [测试策略](docs/TESTING.md)
- [版本管理规范](docs/VERSION_MANAGEMENT.md)
- [本次基线迁移记录](docs/BASELINE_MIGRATION_20260718.md)

`main` 只保留已验证版本；4 名协作者可按规范直接推送，禁止强制推送。

## 20260906 源码整合

当前主线与第四章细节任务的合并范围、来源和验证状态见 [整合记录](docs/releases/20260906-integration.md)。本次为源码上传，既有 Release 下载链接仍对应其原始日期，未生成 20260906 单文件游戏包。
