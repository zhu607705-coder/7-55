# 7:55 版本管理规范

详细的 PR 规模、风险分级和测试矩阵见 [PR 与自动化测试规范](PR_AND_TEST_POLICY.md)。

## 1. 唯一版本源

- 唯一远端仓库：`https://github.com/zhu607705-coder/7-55.git`。
- `main` 始终表示通过质量门槛、可构建、可演示的最新版本。
- 旧目录、ZIP、聊天附件和本地副本只能作为备份，不能继续承载开发。
- 每位成员使用自己的 GitHub 账号和本地克隆，禁止共享账号、令牌或 `.git` 目录。

## 2. 权限

- 日常协作者使用 `Write` 权限。
- 仓库设置、协作者管理、规则集和发布由仓库所有者负责。
- 成员离组时及时移除权限，并轮换曾经共享的密钥。
- 任何密钥、令牌、学号、手机号和私有素材都不得写入 Git 历史。

## 3. `main` 规则

所有变更通过 PR 进入 `main`。仓库所有者应启用：

- Require a pull request before merging。
- Require 1 approval。
- Dismiss stale approvals when new commits are pushed。
- Require conversation resolution before merging。
- Require status checks to pass。
- 必需检查：`PR metadata contract`、`Verify web build`。
- Block force pushes。
- Block deletions。
- Require linear history。

推荐只保留 Squash merge，关闭 Merge commit。管理员也应遵守相同规则。

## 4. 首次设置

```bash
git clone https://github.com/zhu607705-coder/7-55.git
cd 7-55
npm ci
git config pull.ff only
git config core.hooksPath .githooks
```

`.githooks/pre-push` 会运行类型检查、单元测试和生产构建。

## 5. 日常开发

开始工作：

```bash
git switch main
git pull --ff-only
git switch -c feat/<账号>-<主题>
```

完成修改：

```bash
git add <明确的文件>
git commit -m "feat(scope): 简短说明"
git pull --rebase origin main
git push -u origin HEAD
```

随后创建 PR。禁止直接推送 `main`，禁止强制推送任何共享分支。

## 6. 分支命名

- `feat/<账号>-<主题>`：新增功能。
- `fix/<账号>-<主题>`：修复问题。
- `test/<账号>-<主题>`：测试与质量门槛。
- `docs/<账号>-<主题>`：正式文档。
- `chore/<账号>-<主题>`：构建、依赖与仓库维护。

短期分支在 PR 合并后删除。长期开发应持续从 `main` rebase，避免一次性积累大量冲突。

## 7. 提交格式

```text
<type>(<scope>): <简短说明>
```

常用类型：

- `feat`：新增功能。
- `fix`：修复问题。
- `test`：测试相关。
- `docs`：只改文档。
- `refactor`：行为不变的代码调整。
- `perf`：性能优化。
- `build`：构建系统。
- `ci`：持续集成。
- `chore`：仓库维护。

提交应小而单一。一个提交不应混合地图替换、状态迁移和无关文案修改。

## 8. PR 规模

推荐：

- 不超过 20 个文件。
- 增删总量不超过 800 行。
- 一个主要玩法闭环或一个基础设施主题。

超过 30 个文件，或增删总量超过 1500 行时，必须在 PR 正文填写大型 PR 拆分说明。

地图底图、坐标、存档版本、构建配置和大资源更新优先使用独立 PR。

## 9. 文件与资源

必须跟踪：

- `src/`、`public/`、`scripts/`、`tests/`、正式文档和项目配置。
- `package.json` 与 `package-lock.json`，依赖变化时同步更新。
- `.github/workflows/`、PR 模板和仓库质量脚本。

不得跟踪：

- `node_modules/`。
- `dist/`、`demo/`、`.test-dist/`、`coverage/` 等可重建产物。
- `uploads/`、`artifacts/` 等候选素材和临时交付目录。
- ZIP、日志、系统元数据、编辑器缓存和 `.env`。

新增或替换二进制资源前：

1. 确认运行时实际引用。
2. 删除重复源文件。
3. 压缩图片和音频。
4. 单文件超过 20 MiB 时在 PR 中说明。
5. 单文件超过 50 MiB 时先决定 Git LFS、Release 或外部素材库方案。

## 10. 本地质量门槛

快速检查：

```bash
npm run typecheck
npm test
npm run build
```

完整 PR 检查：

```bash
npm run verify:pr
```

完整检查包含地图契约、TypeScript、单元测试、生产构建、正式离线单文件、校园地图单文件和两个产物校验。

禁止使用 `--no-verify` 绕过 pre-push。生成失败时修复源码或脚本，不提交手工修改后的生成目录。

## 11. 审查

PR 至少由一名非作者协作者审查。审查重点：

- 状态前置、成功、失败、重试和重入。
- 存档迁移与旧版本兼容。
- React 与 Phaser 事件边界。
- 地图坐标、碰撞和遮挡。
- 键盘、指针和触控路径。
- 手机和 RPG 逻辑比例。
- 离线单文件资源。
- 未覆盖项是否影响当前发布目标。

所有 review thread 解决后才能合并。新增提交会使旧批准失效时，应重新审查变化部分。

## 12. 合并与回退

- 合并方式使用 Squash merge。
- Squash 标题使用规范化 PR 标题。
- 合并后删除短期分支。
- 出现问题时使用 `git revert` 或 GitHub Revert。
- 禁止通过重写 `main` 历史处理已发布问题。

## 13. 发布

发布使用语义化标签：

```text
v主版本.次版本.修订号
```

示例：`v0.2.0`。

标签只能创建在 `main` 已验证提交上。发布说明包含：

- 新功能。
- 修复。
- 已知问题。
- 验证方式。
- 离线单文件 SHA-256。
- 存档版本和兼容范围。

`demo/index.html` 与 `demo/campus-map-demo.html` 作为 Release 附件发布，不提交进 Git 历史。

## 14. 冲突处理

```bash
git fetch origin
git rebase origin/main
```

解决冲突后：

```bash
git add <已解决文件>
git rebase --continue
npm run typecheck
npm test
npm run build
git push --force-with-lease
```

`--force-with-lease` 仅用于更新自己的 PR 分支，不能用于 `main` 或他人的共享分支。无法确认冲突语义时，与相关模块负责人共同处理，禁止用整目录覆盖解决冲突。
