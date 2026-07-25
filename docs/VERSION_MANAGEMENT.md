# 《7:55》版本管理规范

详细协作命令见 [四人并行开发工作流](FOUR_PERSON_WORKFLOW.md)，目录归属见 [仓库目录与依赖边界](REPOSITORY_STRUCTURE.md)，测试门槛见 [PR 与自动化测试规范](PR_AND_TEST_POLICY.md)。

## 1. 唯一版本源

- 唯一远端仓库：`https://github.com/zhu607705-coder/7-55.git`。
- `main` 表示通过质量门槛、可构建、可演示、可回退的最新版本。
- ZIP、聊天附件、本地复制目录和未推送分支只能作为临时备份，不能继续承载团队开发。
- 每位成员使用自己的 GitHub 账号和本地克隆，不共享账号、令牌或 `.git` 目录。

## 2. 三类独立版本

项目同时维护三种版本，不能混用。

### 2.1 产品版本

1.0 之前采用：

```text
v0.MINOR.PATCH
```

- 完成一个新章节、主要玩法闭环或可独立演示能力时提升 `MINOR`。
- 修复缺陷、优化性能、调整局部表现时提升 `PATCH`。
- PR 合并不自动创建版本标签。完成一个可演示批次后统一发布。

### 2.2 存档版本

`SaveEnvelope.version` 只描述持久化结构。

以下情况需要递增：

- 字段删除、改名或语义变化。
- 旧值需要转换才能继续游玩。
- 主存档和备份恢复策略变化。

每次递增必须提供：

- 上一正式版本样例。
- 正常迁移测试。
- 主存档损坏后的备份恢复测试。
- 无法迁移时的明确降级行为。

### 2.3 运行时桥协议

React、Phaser、Godot 或 iframe 之间的消息格式使用独立 `protocolVersion`。

以下情况需要递增：

- 消息类型重命名。
- 必需字段变化。
- 同一字段的单位或坐标系变化。
- 旧运行时无法安全忽略的新行为。

桥协议变化不应无意义提升产品版本或存档版本。

## 3. 候选版本

固定演示、答辩或公开试玩前使用：

```text
v0.4.0-rc.1
v0.4.0-rc.2
```

进入 RC 后只接受：

- 阻断游玩的缺陷。
- 存档、浏览器或设备兼容修复。
- 发布说明、哈希和交付包装更新。

新增玩法继续进入 `main` 的下一版本批次，不混入当前 RC。

## 4. `main` 规则

所有变更通过 Pull Request 进入 `main`。仓库所有者应启用：

- Require a pull request before merging。
- Require 1 approval。
- Dismiss stale approvals when new commits are pushed。
- Require conversation resolution before merging。
- Require status checks to pass。
- Require linear history。
- Block force pushes。
- Block deletions。
- 管理员遵守相同规则。

基础必需检查：

```text
PR metadata contract
Verify web build
```

命中 Godot 相关路径时增加：

```text
Verify Godot migration
```

命中仓库预览与协作门户时增加：

```text
Verify project preview
```

仓库只保留 Squash merge。关闭普通 Merge commit，避免与 linear history 冲突。

## 5. 四人工作通道

`config/team-workstreams.json` 保存四条工作通道、负责人、路径和交叉审查关系。

默认通道：

| 通道 | 主要范围 |
|---|---|
| A 手机端与界面 | 手机页面、组件、样式、字幕、可访问性 |
| B 剧情状态与玩法控制器 | 状态、任务、存档、控制器、领域事件 |
| C 地图与引擎迁移 | Phaser RPG、Godot、地图、碰撞、寻路、镜头 |
| D 内容资源与交付质量 | 数据、素材、测试、脚本、CI、文档、Release |

通道用于降低文件冲突。跨通道功能仍可以合作，PR 必须写明涉及路径和审查人。

## 6. 分支命名

```text
<type>/<github-user>/<area>-<topic>
```

常用类型：

```text
feat
fix
test
docs
chore
refactor
integration
```

示例：

```text
feat/zhangsan/phone-checkin-animation
fix/lisi/chapter3-bike-lock
feat/wangwu/godot-campus-collision
test/zhaoliu/save-migration-matrix
```

短分支在合并后删除。普通功能分支不应存在超过一个迭代周期。

## 7. 日常同步

开始工作：

```bash
git switch main
git pull --ff-only
git switch -c feat/<github-user>/<area>-<topic>
```

提交前同步：

```bash
git fetch origin
git rebase origin/main
```

更新已推送的个人分支：

```bash
git push --force-with-lease
```

`--force-with-lease` 只用于自己的短分支。禁止对 `main` 或他人的分支使用强制推送。

推荐本地设置：

```bash
git config pull.ff only
git config rebase.autoStash true
git config core.hooksPath .githooks
```

## 8. 堆叠 PR

存在明确依赖时，后续分支从基础 PR 分支创建，PR base 指向基础分支。

```text
PR A  feat/alice/godot-foundation  → main
PR B  feat/bob/campus-collision   → feat/alice/godot-foundation
PR C  feat/carol/library-interior  → feat/bob/campus-collision
```

正文必须写：

```text
Depends on #<基础 PR 编号>
```

A 合并后，B 执行：

```bash
git fetch origin
git rebase --onto origin/main origin/feat/alice/godot-foundation
git push --force-with-lease
```

随后把 B 的 base 改为 `main`。堆叠深度通常不超过三层。

## 9. PR 规模

推荐：

- 不超过 20 个文件。
- 增删总量不超过 800 行。
- 一个主要玩法闭环或一个基础设施主题。

超过 30 个文件或 1500 行增删时，必须填写大型 PR 拆分说明。

以下内容优先拆成独立 PR：

- 地图底图和坐标。
- 存档版本迁移。
- Godot 工程或桥协议。
- 新章节状态机。
- 构建和依赖体系。
- 音频与大体积素材。

## 10. 共享高风险文件

修改前在群内登记：

```text
package.json
package-lock.json
vite.config.ts
src/core/types.ts
src/core/GameState.ts
src/core/SaveStore.ts
.github/workflows/**
```

同一时间只安排一名主修改者。其他相关工作从该 PR 建立堆叠分支。

## 11. 提交格式

```text
<type>(<scope>): <简短说明>
```

示例：

```text
feat(godot): decode campus walkability mask
fix(save): recover backup after invalid primary JSON
test(chapter3): cover bike payment retry
```

提交应小而单一，不混合地图替换、状态迁移、无关格式化和候选素材。

## 12. 本地质量门槛

快速检查：

```bash
npm run verify:structure
npm run typecheck
npm test
npm run build
```

完整 PR 检查：

```bash
npm run verify:pr
```

预览页改动：

```bash
npm run build:project-preview
npm run verify:project-preview
```

动态、视觉和静态检查必须同时通过。禁止通过删除测试、降低断言或使用 `--no-verify` 处理失败。

## 13. 审查与合并顺序

同一批次按以下顺序合并：

1. 数据契约和共享类型。
2. 状态与控制器。
3. 场景和界面。
4. 素材和表现。
5. 测试、文档和发布包装。

每个 PR 至少由一名非作者审查。共享高风险文件建议由两个工作通道共同确认。

合并方式：

- 使用 Squash merge。
- Squash 标题沿用规范化 PR 标题。
- 合并后删除短分支。
- 其他协作者立即 fetch + rebase。

## 14. 冲突处理

普通冲突由后合并分支负责人解决。状态和类型冲突应先确认最终契约，再修改调用方。

锁文件冲突：

```bash
npm install --package-lock-only
npm ci
```

二进制资源冲突不能手工拼合。选定正式源文件后重新运行生成脚本，并记录资源哈希和坐标验证。

## 15. 生成目录与资源

必须跟踪：

- `src/`、`godot/` 正式源码、`scripts/`、`tests/`、正式文档和项目配置。
- 依赖变化时同时更新 `package.json` 和 `package-lock.json`。

不得跟踪：

```text
node_modules/
dist/
demo/
public/godot/
godot/assets/generated/
artifacts/
uploads/
```

ZIP、日志、系统元数据、编辑器缓存和 `.env` 也不得进入 Git 历史。

单文件超过 20 MiB 时在 PR 中说明。超过 50 MiB 时先决定 Git LFS、Release 或外部素材库方案。

## 16. 发布

标签只创建在通过完整验证的 `main` 提交上。发布说明包含：

- 新功能。
- 修复。
- 已知问题。
- 验证方式。
- 三个离线预览文件的 SHA-256。
- 产品版本、存档版本和桥协议版本。
- 兼容浏览器和设备范围。

Release 附件可以包含：

```text
demo/index.html
demo/campus-map-demo.html
demo/project-preview.html
```

生成文件不提交进 Git 历史。

## 17. 发布分支

平时不维护长期 `develop`。固定演示前可以创建：

```text
release/v0.4.0
```

该分支只接收发布阻断修复。修复同时回到 `main`，发布完成后打标签并删除 release 分支。

## 18. 回退

已进入 `main` 的问题使用 `git revert` 或 GitHub Revert。禁止重写主线历史。

回退 PR 应包含：

- 原 PR 编号。
- 触发路径。
- 影响版本。
- 回退后的验证结果。
- 后续修复 Issue。
