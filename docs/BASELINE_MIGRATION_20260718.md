# 2026-07-18 合并基线迁移记录

## 迁移决定

- 将开发者已合并的 `projecttest1 2` 目录作为新的唯一内容基线。
- 该目录迁移前没有 `.git` 历史，因此以新的根提交建立 `main`。
- 远端仓库仍为 `zhu607705-coder/7-55`，只替换 `main`；其他已有分支不删除。

## 回退点

- 替换前远端 `main`：`fa50085c0899d95767fdcd4ce839719f279273e5`
- 归档分支：`archive/main-before-baseline-20260718`

如需查看迁移前内容，从归档分支创建临时分支或工作树；不要再次把旧目录当作开发基准。

## 纳入和排除

新基线纳入应用源码、运行时资源、脚本、配置和正式文档。

以下内容保留为本地文件或可重建交付物，不进入 Git：

- `node_modules/`
- `dist/`
- `demo/`
- `artifacts/`
- `uploads/`
- `.DS_Store`、`*.textClipping` 等系统临时文件

其中 `artifacts/` 是未接入运行时的候选素材；`demo/` 由 `npm run build:demo`
生成。它们不影响源码构建。

## 迁移后规则

本次替换是一次性迁移。完成后立即按
[版本管理规范](VERSION_MANAGEMENT.md)保护 `main`。4 名协作者可直接推送，但必须启用
pre-push 检查、先同步远端，并且不再强制推送 `main`。
