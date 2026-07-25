# 参与开发

本项目由四名协作者并行维护。所有进入 `main` 的变更都通过 Pull Request 完成。

开始前阅读：

- [四人并行开发工作流](docs/FOUR_PERSON_WORKFLOW.md)
- [仓库目录与依赖边界](docs/REPOSITORY_STRUCTURE.md)
- [PR 与自动化测试规范](docs/PR_AND_TEST_POLICY.md)
- [版本管理规范](docs/VERSION_MANAGEMENT.md)

## 1. 首次设置

```bash
git clone https://github.com/zhu607705-coder/7-55.git
cd 7-55
npm ci
git config pull.ff only
git config rebase.autoStash true
git config core.hooksPath .githooks
```

每位成员使用自己的 GitHub 账号和本地克隆。禁止共享账号、令牌、`.git` 目录或整份开发文件夹。

## 2. 认领工作

在 Issue 或团队群登记：

```text
负责人：
工作通道：A / B / C / D
目标：
主要文件：
依赖 PR：
预计首个可审查提交：
```

四条通道和路径范围位于 `config/team-workstreams.json`。修改共享高风险文件前先确认没有另一人同时工作。

## 3. 创建分支

```bash
git switch main
git pull --ff-only
git switch -c feat/<github-user>/<area>-<topic>
```

常用前缀：

- `feat/`：新增玩法、页面或场景。
- `fix/`：修复缺陷。
- `test/`：测试和质量门槛。
- `docs/`：正式文档。
- `chore/`：构建、依赖和仓库维护。
- `refactor/`：保持行为的内部调整。
- `integration/`：只用于明确负责人和退出日期的短期整合。

示例：

```text
feat/zhangsan/phone-checkin-animation
fix/lisi/chapter3-bike-lock
feat/wangwu/godot-campus-collision
test/zhaoliu/save-migration-matrix
```

## 4. 提交前验证

快速门槛：

```bash
npm run verify:structure
npm run typecheck
npm test
npm run build
```

完整 PR 门槛：

```bash
npm run verify:pr
```

预览页相关改动还应运行：

```bash
npm run build:project-preview
npm run verify:project-preview
```

Playwright 视觉测试由 `Project Preview CI` 自动执行。仓库的 pre-push hook 会运行类型检查、单元测试和生产构建，禁止使用 `--no-verify` 绕过失败。

## 5. 提交与推送

提交信息：

```text
<type>(<scope>): <简短说明>
```

独立 PR 分支同步主线：

```bash
git add <明确的文件>
git commit -m "feat(scope): 简短说明"
git fetch origin
git rebase origin/main
git push -u origin HEAD
```

已经推送过且 rebase 改写历史时：

```bash
git push --force-with-lease
```

`--force-with-lease` 只允许用于自己的短分支。禁止对 `main` 或他人的分支使用强制推送。

不要默认使用 `git add -A` 提交混合工作区。提交前确认没有密钥、个人信息、临时截图、日志、生成目录或候选素材。

## 6. 堆叠 PR

依赖尚未合并的基础 PR 时，从基础分支创建：

```bash
git fetch origin
git switch -c feat/<github-user>/<area>-<topic> origin/<基础分支>
```

创建 PR 时把 base 指向基础分支，并在正文写：

```text
Depends on #<基础 PR 编号>
```

基础 PR 合并后：

```bash
git fetch origin
git rebase --onto origin/main origin/<基础分支>
git push --force-with-lease
```

然后把 PR base 改为 `main`。堆叠深度通常不超过三层。

## 7. 创建 PR

PR 标题沿用提交格式。正文必须填写：

- 改动。
- 原因。
- 协作范围与依赖。
- 验证。
- 风险与回滚。
- 未覆盖。

超过 30 个文件，或增删总量超过 1500 行时，还要填写大型 PR 拆分说明。

UI、地图和动画改动附截图或录屏。涉及状态、存档、移动端输入、Godot 或离线单文件时，写明实际触发路径和验证环境。

## 8. 审查与合并

合并前需要：

- 至少一名非作者协作者批准。
- 所有 review thread 已解决。
- `PR metadata contract` 通过。
- `Verify web build` 通过。
- 改动命中 Godot 时，`Verify Godot migration` 通过。
- 改动命中预览门户时，`Verify project preview` 通过。
- PR 已同步最新 base。

共享高风险文件建议由两个工作通道共同确认。合并方式使用 Squash merge。发现问题时使用 `git revert` 或 GitHub Revert，禁止重写 `main` 历史。

## 9. 合并后同步

任一 PR 合并后，其他成员执行：

```bash
git fetch origin
git rebase origin/main
```

修改相同高风险文件的分支应立即同步。已经完成的短分支在合并后删除。
