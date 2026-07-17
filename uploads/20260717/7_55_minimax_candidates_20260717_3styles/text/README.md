# 文本候选

三个 prompt 文件通过 MiniMax Text CLI 生成候选 JSON：

- `story_candidate_prompt.txt`：三章对白、任务、提示和音频角色方向。
- `cc98_candidate_prompt.txt`：首页帖子、调查帖、回复、附件说明和版务提示。
- `ui_microcopy_prompt.txt`：手机界面、任务栏、物品正文、吐槽和无障碍文案。

`valid/` 保存通过 JSON 解析的候选，`selected-index.json` 汇总可筛选内容；`partials/` 保存 CLI 超时或截断的原始片段，并在 `reports/text-validation.json` 中标记。所有 JSON 只供人工筛选，不会覆盖 `src/data`。
