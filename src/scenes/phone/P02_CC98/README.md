# P02 CC98

## 首次统一身份认证

- 第一次进入 CC98 时先经过剧情内的浙江大学统一身份认证页；认证完成后，后续章节和旧进度不重复拦截。
- 学号只从随身校园卡读取，使用主角既有身份 `3250100755`。
- 密码由三段有序提示唯一组成：`ZJU`、`1897`、`!`，答案为 `ZJU1897!`。
- 前三次提交可立即尝试；第 3 次失败后等待 30 秒，此后每多一次失败增加 30 秒。锁定使用绝对截止时间并随正式存档保存。
- `ActOneBootstrapController` 是认证、失败累计和锁定的唯一进度写入方；页面只保存输入框、显隐和反馈等临时 UI。
- 开发入口 `c2-cc98-login` 停在未认证页，`c2-gamepad-market` 从已认证的二手交易帖继续。

- Scene ID: `cc98`
- Entry: 手机主页 CC98 应用图标
- Reads: `networkMode`
- Network rule: normal CC98 browsing requires `campus_wifi`. The theater commission is the sole cached-page exception: after the player has accepted it, its phone ticket portal may be resumed on `cellular` for the two release waves. Offline entry still fails validation and returns to the phone home screen.
- Viewport: shared `430 × 860` phone canvas
- Default post data: `src/data/cc98.posts.json`
- Runtime editing: top-right `编辑/保存`; persisted to `localStorage` key `seven-fifty-five.cc98-posts.v2`
- Reset: top-right menu → `恢复默认帖子`
- Interaction: time tabs, bottom navigation, full-page post details, editable title/author/board/metrics/time/body
- Search: typo-tolerant local material search; library-finals results live in `src/data/library-finals.content.json`
- Thread scaffold: owner floor, operation log, reply floors, pagination, `bd = 帮顶` explanation, eight numbered reply posts, and a persistent four-digit BD password
- Forum-treasure asset: `src/assets/ui/cc98_forum_treasure.png`
- Visual reference: `pageexample/cc98_hot_topics_reference.png`
