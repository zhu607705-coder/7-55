# 参与开发

本项目由 4 名协作者共同维护。完整规则见
[版本管理规范](docs/VERSION_MANAGEMENT.md)。

Godot 原生任务从 `godot-version` 或明确的依赖分支创建功能分支，PR 指向相应基线；
通用规范修订可从 `main` 独立提交，合并后需同步到迁移及活动功能分支，避免旧规则继续影响审查。
不要因规则修订而合并未验收功能。引擎边界见 [AGENTS.md](AGENTS.md)。

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
npm run validate:release
```

`validate:release` 只执行一次 TypeScript 类型检查，随后使用 unchecked 构建入口生成生产包和单文件，避免在同一验证批次重复运行 `tsc --noEmit`。

行为级验证、仓库契约、浏览器启动检查和扩展内容审计的边界见
[测试策略](docs/TESTING.md)。新增验证器时，需要明确它属于日常阻断、手动扩展审计或发布级端到端验证。

旧 `godot/` 与 `src/integrations/godot/` 混合运行时仍不得恢复。
当前 `godot_native/` 的 Godot 4.6.3 原生场景、导出、同步工具和测试允许开发。
上述 npm 命令用于 Web 验证；原生变更按迁移分支 `godot_native/README.md` 运行同步、
导入/启动/原生测试及相关源模型差分。共享源数据或控制器变更需要两侧相关验证。
文档修订核对链接、差异和规范一致性即可，不能把文档检查写成游戏验收。

仓库的 pre-push hook 和 GitHub Actions 会执行当前登记的检查；新增验证器后，应同步更新
测试策略、本文档和对应 Web 或原生工作流。

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
