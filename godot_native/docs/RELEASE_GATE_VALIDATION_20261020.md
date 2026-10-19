# 发布入口验收补记 · 2026-10-20

发布入口与 Web 旧 QA 会话保存修复已于上海时间 10 月 19 日 23:49 推送到草稿 PR #153。远端 `bc5dcd5c53e1bf59244d11450baa08eafcad6667` 与本地 `9dbaa14472985097801a5c676022c06326ac7297` 的源码树均为 `4e44ba4238563de0d1fe38fb2dab5dd42b0e5205`。本记仅补齐随后完成的原生验证与一条测试来源摘要，不含下一批 C1 文字玩法或通知改版。

完整 `validate_native.mjs` 在正确 GODOT_BIN、Node 22.23.3、Godot 4.7.2、四 worker 与逐阶段隔离存档下运行。417 阶段中 416 通过、1 个来源检查失败；全部 378 个独立 GD 入口与 731 脚本解析通过。原始进程如实以 1 退出，不能称为一次不中断的 417 PASS。运行前后 2834 个原生生产文件与验证代码摘要相同。

唯一失败是独立 `export_library_story_source.mjs --check` 的测试 fixture 陈旧。`sync_source.mjs` 不生成这一 fixture；Web 开发面板门禁改变了 `src/App.tsx` 整文件 SHA。正常专用生成器刷新后，严格 JSON 差异只有 `/sources/0/sha256` 一处，所有映射、对白、时长与其他来源均相同；该 fixture 不进入生产 PCK。随后实际复跑来源检查及两个正式消费者，三项全部通过，其中 story sequences 为 718 项检查。

完整原始结果与重跑报告保存在忽略的 `exports/verification/release_20261020/full_native/`；包含输入摘要、唯一差分及原始报告 SHA 的简表见 `../verification/integration_20261019/release_native_acceptance_20261020.json`。本次提交冻结后按实际日期重建 PCK 与源码 ZIP，并验证远端与本地 tree 完全相等。此前 PCK 或上一精确 head 的 8/8 CI 仅为各自基线；新 head 的 CI 单独观察。

完整人工四章通关、实体手机、Windows/GPU 与音频听验仍须分别验收。原分支和 PR 保留；未合并迁移主分支或 main，未对外替代发布。
