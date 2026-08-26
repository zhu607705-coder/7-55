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
npm run map:zijingang
npm run audio:chapter3:verify
npm run audio:chapter3-interlude-voice-memos:verify
npm run chapter4:validate-runtime
npm run typecheck
npm run build
npm run build:single
npm run verify:single
```

退役的 Godot 源码、导出、兼容层和同步脚本已经删除，提交不得重新引入这些模块。

仓库的 pre-push hook 和 GitHub Actions 会执行当前登记的检查；新增验证器后，应同步加入
`package.json`、本文档和 `.github/workflows/web-ci.yml`。

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

小型低风险改动允许直接向 `main` 推送，绝不允许强制推送。引擎、共享状态、存档或完整
关卡改动使用 PR，并在多人同时修改同一模块前明确负责人和文件范围。
