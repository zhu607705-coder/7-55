# 《梁祝》54秒演出与QTE接入

2026-10-21。`liangzhu-performance.content.json` 是本批原创中文对白/cue/桌椅布局的唯一数据。三场为0–20秒同窗相送、20–38秒楼台会、38–54秒明确“后来/墓前”的化蝶结尾；现代唱词摘录不采用。声音尚待实际生成校准，不宣称已完成原唱或正宗越剧唱腔。

舞台逻辑长度54秒。交互默认在15秒接扇、29秒向左回身、46秒按住并松开放蝶处等待真实操作，因此实际游玩时间另含等待/重试。0/8/20/38/54秒仍为四个绘制beat。桌椅和两位角色保留同一舞台坐标；第三场梁山伯缺席，只留空椅，英台左右两手的扇各从真实腕点化蝶。48秒是规范离线动作的放飞时点。

## 唯一输入模型

`Model.new(reduced=false, mode="interactive")`；显式 `mode="passive"` 为静看，不触发QTE，也不写任何QTE成功回执。运行后不允许切换mode绕过输入。`pose_at()` 是只读规范演出采样，标注 `samplingMode="canonical-passive-presentation"`，不能当作玩家QTE通过证据。

`tick(delta, focused=true, blocked=false)` 以实际单调delta累计；未暂停的等待窗口、按住时长和演出时间同源。等待将舞台时间精确停在该cue，命中后续当前拍。缺帧跨过cue时先呈现cue，不直接花掉反应窗口。暂停/失焦/遮挡均不耗时；焦点返回需明确resume。

`qte_input(action, phase="tap", direction="", owner="keyboard")`：

- `catch` / `tap`。
- `turn` / `swipe` / `left`；向右是本拍可恢复失误。
- `butterfly` / `press` 后由同一owner提交 `release`；用实时腕边稳定反馈，不在默认UI写秒数。重复press或其他设备release不能抢走owner。

失败为 `status="failure"`，当前拍和时钟暂停；`retry_qte()` 只重试此cue，保留前cue成功。`request_qte_help()` 分层给观察/输入说明。`interrupt_input(reason)` 清除held，等待中设focus_paused以要求明确resume；resize、触摸取消及失焦调用它，不能拿旧release续按。cancel清除当前owner/会话。状态和回执仅在演出实例，不调用State/保存/谜题proof。

`snapshot.qte`：id/action/title/prompt/retryLabel、status、elapsedMs/windowMs、holding/holdProgress、hintTier/helpText、failure/feedback、targetAttachment。接扇和放蝶target为英台 `FanSocket`；回身target为山伯 `FootAnchor` 加逻辑offset `[0,-12]`。同一可见实体坐标同时生成提示与至少44CSS像素热区。默认只显示短动作，首次失误才出现观察提示，进一步help才显示输入说明。

字幕字段：sceneId/sceneTitle、speaker/text、cueId、lineStartMs/lineEndMs、delivery、兼容caption。三QTE均位于台词起点，后续音频消费者应在waiting/failure时暂停，不让生成声音越过被阻住的舞台时间。

扇道具字段 `attachment.kind`：socket（actor/socket）、handoff（fromActor/fromSocket/toActor/toSocket/amount/arc）、release（actor/socket/launchMs/progress/start/end）、fixed。render只读真实rig挂点；历史放飞用同pose的 `sample_socket`，不再用旧22秒硬编码时刻。旧22秒模型和测试仅留在ignored verification的baseline-22s，不能当新版本验收。

验证：模型测试覆盖原创台词完整边界、舞台/遮幕/缺席角色/持扇数据、减少动态效果、明确passive与离线采样；QTE单测覆盖输入、超时/重试、owner、方向、按住前后边界、暂停/失焦/resize/遮挡/取消。实际实体点击/划动、触摸热区、音频准入/同步、返回原谜题和Web存档不变由视图与浏览器验收另证。
