# 《7:55》四人并行开发工作流

本文给出四名协作者同时开发时的分支、拉取、审查、合并、版本和冲突处理规则。目标是让每个人持续推进自己的模块，同时让 `main` 始终保持可构建、可试玩、可回退。

## 1. 基本模型

团队使用短分支主线开发：

- `main` 保存当前可演示版本。
- 每个人在自己的短分支工作。
- 所有变更通过 Pull Request 进入 `main`。
- 默认使用 Squash merge。
- 有明确依赖时使用堆叠 PR，不建立长期共享开发分支。
- 发布冻结期才建立短期 `release/*` 分支。

四人不要共同向一个 feature 分支连续推送。共享分支会失去清晰的提交归属，也容易出现一人 rebase 后覆盖其他人的提交。

## 2. 分支命名

```text
<type>/<github-user>/<area>-<topic>
```

允许的 `type`：

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

`area` 使用稳定模块名，例如：

```text
phone
core
save
chapter1
chapter2
chapter3
campus
library
canteen
godot
assets
ci
preview
```

## 3. 每日开始流程

```bash
git switch main
git pull --ff-only
git switch -c feat/<github-user>/<area>-<topic>
```

开始前在 Issue 或团队群登记：

```text
负责人：
工作通道：A / B / C / D
目标：
主要文件：
依赖 PR：
预计首个可审查提交：
```

登记的重点是文件重叠。两个人计划修改同一个高风险文件时，应先确定先后顺序，后开始的人基于前一个 PR 建立堆叠分支。

## 4. 开发中的拉取方式

### 4.1 独立 PR

分支直接面向 `main` 时：

```bash
git fetch origin
git rebase origin/main
```

解决冲突后：

```bash
git add <已解决文件>
git rebase --continue
npm run verify:pr
git push --force-with-lease
```

`--force-with-lease` 只允许用于自己的短分支。任何人都不能对 `main` 使用强制推送。

### 4.2 已推送但不需要改写历史

只新增提交时：

```bash
git pull --rebase origin <当前分支>
git push
```

禁止使用无参数 `git pull` 产生意外 merge commit。推荐全员设置：

```bash
git config pull.ff only
git config rebase.autoStash true
```

## 5. 堆叠 PR

某个功能依赖尚未合并的基础 PR 时，后续分支从基础分支创建，并把 PR base 指向基础分支。

示例：

```text
PR A  feat/alice/godot-foundation  → main
PR B  feat/bob/campus-collision   → feat/alice/godot-foundation
PR C  feat/carol/library-interior  → feat/bob/campus-collision
```

创建 B：

```bash
git fetch origin
git switch -c feat/bob/campus-collision origin/feat/alice/godot-foundation
```

A 合并后处理 B：

```bash
git fetch origin
git switch feat/bob/campus-collision
git rebase --onto origin/main origin/feat/alice/godot-foundation
git push --force-with-lease
```

然后把 B 的 PR base 改为 `main`。C 以相同方式向前移动。

堆叠规则：

1. PR 标题和正文必须注明 `Depends on #<number>`。
2. 基础 PR 发生破坏性修改时，依赖分支负责人当天 rebase。
3. 基础 PR 未通过 CI 时，下游 PR 不进入最终审查。
4. 堆叠深度通常不超过 3 层。超过时应拆成数据契约或接口 PR。

## 6. 提交规则

提交格式：

```text
<type>(<scope>): <说明>
```

示例：

```text
feat(godot): decode campus walkability mask
fix(save): recover backup after invalid primary JSON
test(chapter3): cover bike payment retry
```

一个提交应满足：

- 可以独立说明目的。
- 不包含无关格式化。
- 不混入临时截图、日志或候选素材。
- 修改依赖时同时提交 `package.json` 与 `package-lock.json`。
- 生成目录不进入提交。

PR 合并时使用 Squash，因此分支内允许保留便于审查的小提交。

## 7. PR 建议规模

推荐范围：

- 20 个文件以内。
- 800 行增删以内。
- 一个主要玩法闭环或一个基础设施主题。

超过 30 个文件或 1500 行增删时，正文必须写“大型 PR 拆分说明”。地图底图、存档版本、引擎迁移、依赖体系和 CI 通常分别提交。

## 8. 审查分配

每个 PR 至少需要一名非作者审查。

推荐交叉审查：

| 作者通道 | 首选审查通道 | 关注内容 |
|---|---|---|
| A 手机端与界面 | B 或 D | 状态调用、输入、响应式、可访问性 |
| B 状态与控制器 | A 或 C | 状态边界、重试、存档、事件语义 |
| C 地图与引擎 | B 或 D | 坐标、碰撞、性能、运行时生命周期 |
| D 内容与交付 | A 或 C | 构建复现、资源清单、测试证据、文档一致性 |

以下文件需要两个通道共同确认，即使仓库规则暂时只要求一名批准：

```text
src/core/types.ts
src/core/GameState.ts
src/core/SaveStore.ts
package.json
package-lock.json
vite.config.ts
.github/workflows/**
```

## 9. 合并顺序

同一批次存在多个 PR 时，按以下顺序处理：

1. 数据契约和共享类型。
2. 状态与控制器。
3. 场景和界面。
4. 素材和表现。
5. 测试、文档与发布包装。

每个 PR 合并后，其他三人执行：

```bash
git fetch origin
git rebase origin/main
```

涉及相同高风险文件时，应立即同步，不积累到当天结束。

## 10. 合并门槛

合并前必须满足：

1. PR 不是 Draft。
2. 标题和正文契约通过。
3. 必需 CI 全部通过。
4. 至少一名非作者批准。
5. Review thread 全部解决。
6. 已同步最新 base。
7. 未覆盖项不会影响当前发布目标。
8. 行为变化有测试或明确的补测 Issue。
9. UI、地图、动画有桌面和移动端证据。
10. 存档改动包含旧版本恢复或迁移样例。

默认合并按钮只使用 Squash merge。

## 11. 冲突处理

### 11.1 普通文本冲突

由后合并分支的负责人解决。解决者必须理解两边行为，禁止简单选择 ours 或 theirs 后直接提交。

### 11.2 状态与类型冲突

先形成最终字段契约，再分别修改控制器、场景和测试。不要在冲突编辑器中临时拼合两套状态模型。

### 11.3 地图与二进制资源冲突

二进制文件不能手工合并。确定一份正式源文件，重新运行生成脚本，并在 PR 中记录哈希与坐标校验结果。

### 11.4 锁文件冲突

保留最终 `package.json`，删除冲突后的锁文件并重新运行：

```bash
npm install --package-lock-only
npm ci
```

随后运行完整验证。

## 12. 版本管理

### 12.1 产品版本

1.0 之前采用：

```text
v0.MINOR.PATCH
```

- 新增完整玩法闭环或章节能力，提升 `MINOR`。
- 修复、性能优化和局部表现，提升 `PATCH`。
- 合并 PR 不一定立即打标签。完成一个可演示批次后统一发布。

### 12.2 候选版本

演示、答辩或公开试玩前：

```text
v0.4.0-rc.1
v0.4.0-rc.2
```

进入 RC 后只接受阻断缺陷、兼容性修复和发布文档更新。

### 12.3 三类独立版本

- 产品版本：`package.json.version` 与 Git 标签。
- 存档版本：`SaveEnvelope.version`。
- React / Godot 桥协议：`protocolVersion`。

三者分别递增。调整桥消息格式不应无意义提升存档版本。

## 13. 发布分支

平时不维护长期 `develop`。临近固定演示日期时，可建立：

```text
release/v0.4.0
```

规则：

- 从通过完整回归的 `main` 创建。
- 只接收发布阻断修复。
- 修复同时合回 `main`，避免分叉。
- 发布完成后打标签并删除 release 分支。

## 14. 紧急修复

```bash
git switch main
git pull --ff-only
git switch -c fix/<github-user>/hotfix-<topic>
```

紧急修复仍走 PR、CI 和审查。可以缩短说明，不能绕过测试。合并后立即创建补充测试或复盘任务。

## 15. 推荐 GitHub 设置

`main` 建议启用：

- Require a pull request before merging。
- Require 1 approval。
- Dismiss stale approvals。
- Require conversation resolution。
- Require required status checks。
- Require linear history。
- Block force pushes。
- Block deletions。
- 只保留 Squash merge。

必需检查至少包括：

```text
PR metadata contract
Verify web build
```

Godot 相关 PR 再要求：

```text
Verify Godot migration
```

## 16. 每周协作检查

每周用 15 分钟检查：

1. 是否出现超过 5 天的开放开发分支。
2. 是否有多人反复修改同一高风险文件。
3. 堆叠 PR 是否已经失去清晰依赖。
4. 预览页的入口是否都能打开。
5. `config/team-workstreams.json` 的负责人是否仍准确。
6. 最新标签是否对应真实可演示构建。
