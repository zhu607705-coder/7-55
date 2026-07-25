# 参与开发

本项目由多名协作者共同维护。所有进入 `main` 的变更都通过 Pull Request 完成。完整规则见：

- [PR 与自动化测试规范](docs/PR_AND_TEST_POLICY.md)
- [版本管理规范](docs/VERSION_MANAGEMENT.md)

## 开始工作

```bash
git switch main
git pull --ff-only
npm ci
git config core.hooksPath .githooks
```

每位成员只使用自己的 GitHub 账号和本地克隆，不共享账号、令牌或 `.git` 目录，也不通过复制整个项目文件夹传递开发版本。

## 创建分支

```bash
git switch -c feat/<账号>-<主题>
```

常用前缀：

- `feat/`：新增玩法或界面。
- `fix/`：修复缺陷。
- `test/`：测试和质量门槛。
- `docs/`：正式文档。
- `chore/`：构建、依赖和仓库维护。

## 提交前

本地快速门槛：

```bash
npm run typecheck
npm test
npm run build
```

完整 PR 门槛：

```bash
npm run verify:pr
```

仓库的 pre-push hook 会运行类型检查、单元测试和生产构建。禁止使用 `--no-verify` 绕过失败。

## 提交与推送

提交信息采用：

```text
<type>(<scope>): <简短说明>
```

示例：

```bash
git add <明确的文件>
git commit -m "test(ci): 增加第三章状态回归"
git pull --rebase origin main
git push -u origin HEAD
```

不要默认使用 `git add -A` 提交混合工作区。提交前确认没有密钥、个人信息、临时截图、生成目录或候选素材。

## 创建 PR

PR 标题沿用提交格式。正文必须填写：

- 改动。
- 原因。
- 验证。
- 风险与回滚。
- 未覆盖。

超过 30 个文件，或增删总量超过 1500 行时，还要填写大型 PR 拆分说明。

UI、地图和动画改动应附截图或录屏。涉及状态、存档、移动端输入或离线单文件时，应写明实际触发路径和验证环境。

## 审查与合并

合并前需要：

- 至少一名非作者协作者批准。
- 所有 review thread 已解决。
- `PR metadata contract` 通过。
- `Verify web build` 通过。
- PR 已同步最新 `main`。

合并方式使用 Squash merge。发现线上问题时使用 `git revert` 或 GitHub Revert，禁止重写 `main` 历史。
