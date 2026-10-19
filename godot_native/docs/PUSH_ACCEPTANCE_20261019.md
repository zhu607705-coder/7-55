# 2026-10-19 推送与继续验收

用户在本轮明确要求继续验收并开始推送。重新 fetch 后，`main` 与 `godot-version` 均没有本地缺少的提交。工作区三视图与提交来源见 `INTEGRATION_GIT_REVIEW_20261019.md`；本轮提交范围是已经整合的源码、原始 PR 素材、规则、构建工具、测试与验收记录，排除生成缓存、25 个本机新增 nearshore 导入侧车和 exports 大文件。

审阅分支为 `codex/godot-complete-20261019`，目标为 `godot-version`。这次推送不修改远端 `main`、`godot-version` 或既有 PR 的 head，也不关闭原 PR。迁移仍是审阅候选。

## 精确来源与传输

本机 HTTPS Git 没有推送凭据，因此使用已连接的 GitHub Git Data 接口传输 Git blob、tree 和 commit。八次本地合并在远端保持原来的父子关系及原 PR 父提交；GitHub 重新签发提交元数据会改变 commit SHA。每一步都要求远端 tree SHA 与本地 tree SHA 完全相等，映射归档在 `../verification/integration_20261019/github_merge_mapping.json`。最终工作区提交也按同一方式核验 tree；不把两个不同 commit SHA 冒称为同一提交。

来源清单还发现普通 Git ignore 会漏掉 PR #151 的 27 个原始 UID 和 6 份原始验收日志。只将这些来源文件精确 force-add；其他自动 UID/日志保持排除。源码打包工具现在只允许来源清单明确登记的 9 份原始日志，并强制核查 sourceRoots 内 2627 个独特来源/证据路径，避免本机存在而干净检出或解压后缺件。

## 继续验收结果

- 原生归档 413 个阶段都有通过结果，当前 374 个 GD 入口全部覆盖。918 个输入与原归档逐字节相同；唯一授权变化为补原始证据的打包工具，另做强制来源预检和负向检查。PCK 的 494 个运行输入保持相同，既有 15 项无源码包检查仍有效。
- 当前 Web 完整发布检查 36/36，通过记录在 `../verification/integration_20261019/web_release.txt`。本轮又定向检查了状态写入 12/12、旧存档最终组装、415 个原始 SHA 与 6 份原文件快照。
- 9 份 workflow 和全部 shell 块语法通过。原生跨 PR workflow 的两个 step 去掉了 HOME 改写，Linux 继续使用 `/tmp` 下的 XDG 隔离目录；没有改生产玩法或削弱保存校验。
- 新源码 ZIP 在提交后重新生成并做完整解压、逐文件校验、空导入缓存与入口/剧情启动验收。输出和校验报告位于 `exports/`，不嵌入包含自身哈希的源码提交。

本机实测环境是 macOS、Node 22.23.3、Godot 4.7.2 和 Blender 5.2.2 LTS。GitHub 的 Node 24 / Linux Godot 4.6.3 需以该审阅分支实际 Actions 结果为准。完整人工四章通关、实体手机、Windows/GPU 和真实音频听验仍未被自动化结果替代。
