# 早期剧院空间迁移实验 · PR #54

这是保留的独立空间实验，入口和生成目录全部隔离在本目录，不连接《7:55》剧情或正式存档。原始 head：`08c48f99cfb3c467c332854e250cec735feb75bd`。

在仓库根目录安装现有 Node 依赖后运行：

```sh
node examples/legacy_godot_theater/scripts/verify-godot-data.mjs
node examples/legacy_godot_theater/scripts/export-godot-theater.mjs
godot --headless --path examples/legacy_godot_theater/godot-port --editor --import --quit
godot --path examples/legacy_godot_theater/godot-port
```

也可从正式 Godot 入口的“动画与原型预览”打开。首次打开前需要完成素材导出。测试命令：

```sh
godot --headless --path examples/legacy_godot_theater/godot-port --script res://tests/smoke.gd
```

`src/` 仅为该实验使用的三份 TypeScript 几何/角色合同和二十六张原始 PNG 快照；没有复制整套网页应用。脚本使用仓库现有的 TypeScript 依赖，生成文件只写本目录 `godot-port/generated/`。`SOURCE_ORIGIN.json` 记录来源。原始文档和 `.github/workflows/` 保留历史内容，隔离目录中的 workflow 不会注册为仓库 CI。

原始 README 指定的 Godot 4.7.2 是历史环境记录；本次组合使用本机 Godot 版本重新验证。实验不包含剧情、背包、剧院谜题、音频或完整章节迁移。
