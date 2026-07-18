# 7:55 版本管理规范

## 1. 唯一版本源

- 唯一远端仓库：`https://github.com/zhu607705-coder/7-55.git`
- `main` 始终表示可构建、可演示的最新稳定版本。
- 迁移完成后，旧目录、ZIP、聊天附件只能作为备份，不能再作为开发基准。
- 每位成员从远端单独克隆；禁止共享 GitHub 账号、访问令牌或 `.git` 目录。

## 2. 四人权限

仓库所有者邀请另外 3 名成员为 GitHub Collaborator，4 人均使用自己的账号：

- 日常开发权限：`Write`。
- 仓库设置、协作者管理和分支保护：由仓库所有者负责。
- 成员离组时及时移除权限，并轮换曾共享过的密钥。

邀请完成后，在 GitHub 的 `Settings → Collaborators` 中逐一确认 4 个账号均已接受。

## 3. `main` 分支保护

本次基线替换完成后，在 `Settings → Branches` 为 `main` 启用：

- Require linear history。
- Block force pushes。
- Block deletions。

不要启用 Pull Request 或 CI 必须通过的规则；4 名协作者可直接推送 `main`。
本次从无 Git 历史的合并目录建立新基线，是唯一一次迁移例外。之后不得重写
`main` 历史。

## 4. 首次设置

```bash
git clone https://github.com/zhu607705-coder/7-55.git
cd 7-55
npm ci
git config pull.ff only
git config core.hooksPath .githooks
```

`core.hooksPath` 会启用仓库内置的 pre-push 检查。每位协作者只需设置一次。

## 5. 日常直接推送

开始工作前：

```bash
git switch main
git pull --ff-only
```

完成修改后：

```bash
git add <明确的文件>
git commit -m "feat(scope): 简短说明"
git pull --rebase origin main
git push origin main
```

pre-push hook 会在推送前执行类型检查和生产构建。如果远端已被其他成员更新，Git 会
拒绝非快进推送；先 rebase、解决冲突并重新验证，禁止用强制推送覆盖他人提交。

预计超过一天、会改动共享核心模块的大任务可以使用临时分支
`feature/<账号>-<主题>`，完成后在本地验证并快进合并到 `main`，不要求 PR。

多人同时开发时，在群里简单登记“负责人 + 模块/文件 + 预计完成时间”，避免同时改同一
文件。提交尽量小而单一，不把多个无关功能塞进同一提交。

## 6. 提交格式

```text
<type>(<scope>): <简短说明>
```

常用类型：

- `feat`：新增功能。
- `fix`：修复问题。
- `docs`：只改文档。
- `refactor`：不改变行为的代码调整。
- `test`：测试相关。
- `chore`：构建、依赖或仓库维护。

UI 改动在群里附截图或录屏；涉及存档、剧情进度、资源体积或移动端交互时，说明验证
结果。提交前确认没有密钥、账号、个人信息或临时素材。

## 7. 文件与大资源

必须跟踪：

- `src/`、`public/`、`scripts/`、正式文档和项目配置。
- `package.json` 与 `package-lock.json` 必须一起更新。

不得跟踪：

- `node_modules/`。
- `dist/`、`demo/` 等可重建产物。
- `uploads/`、`artifacts/` 等临时上传或候选素材。
- ZIP、日志、系统元数据、编辑器缓存和 `.env`。

离线单文件演示由 `npm run build:demo` 生成，作为 Release 附件或其他交付物发布，
不要提交进 Git 历史。

新增或替换二进制资源前：

1. 确认运行时确实引用，删除重复源文件。
2. 尽量压缩图片和音频。
3. 单文件超过 20 MiB 时在群里说明；超过 50 MiB 时先由团队决定使用 Git LFS、
   Release 或外部素材库，不直接提交。

## 8. 质量门槛

每次推送至少执行：

```bash
npm run typecheck
npm run build
```

`.githooks/pre-push` 会自动执行以上命令。当前仓库尚无自动测试套件；增加测试后，
必须把 `npm test` 同时加入 `package.json`、pre-push hook 和本规范。

生成目录只能由脚本生成，禁止手工修改。生成失败时修复源码或脚本，不提交半成品。

如果 pre-push 检查失败，修复后重新提交或补充提交；不要用 `--no-verify` 绕过。

## 9. 发布与回退

- 发布版本使用语义化标签：`v主版本.次版本.修订号`，例如 `v0.2.0`。
- 标签只打在 `main` 已验证的提交上。
- 发布说明列出功能、修复、已知问题和验证方式。
- 已推送的问题使用 `git revert <commit>` 回退，禁止重写 `main`。
- 基线迁移前的远端版本保存在专用归档分支，详情见
  [基线迁移记录](BASELINE_MIGRATION_20260718.md)。

## 10. 冲突处理

```bash
git fetch origin
git rebase origin/main
```

解决冲突后：

```bash
git add <已解决文件>
git rebase --continue
npm run typecheck
npm run build
git push origin main
```

不能确定时，与相关成员共同确认；不要使用 `git reset --hard`、整目录覆盖或
`git push --force` 来“解决”冲突。
