# 参与开发

本项目由 4 名协作者共同维护。完整规则见
[版本管理规范](docs/VERSION_MANAGEMENT.md)。

## 开始工作

```bash
git switch main
git pull --ff-only
npm ci
git config core.hooksPath .githooks
```

每位成员只使用自己的 GitHub 账号和本地克隆，不共享账号、令牌或 `.git`
目录，也不通过复制整个项目文件夹来传递版本。

## 提交前

```bash
npm run typecheck
npm run build
```

仓库的 pre-push hook 会自动执行以上检查。当前项目尚无自动测试套件；新增测试框架后，
应把测试命令加入这里和 pre-push hook。

提交信息采用：

```text
<type>(<scope>): <简短说明>
```

常用 `type`：`feat`、`fix`、`docs`、`refactor`、`test`、`chore`。

## 直接推送

```bash
git add <明确的文件>
git commit -m "fix(scope): 简短说明"
git pull --rebase origin main
git push origin main
```

若远端已被其他成员更新，Git 会拒绝非快进推送。此时先 rebase、解决冲突并重新验证。

允许直接向 `main` 推送，但绝不允许强制推送。大改动或多人同时修改同一模块前，先在
团队群里明确负责人和文件范围。
