# P02 CC98

- Scene ID: `cc98`
- Entry: 手机主页 CC98 应用图标
- Reads: `networkMode`
- Network rule: only `campus_wifi` may enter; mobile data and offline entries fail validation and return to the phone home screen.
- Viewport: shared `430 × 860` phone canvas
- Default post data: `src/data/cc98.posts.json`
- Runtime editing: top-right `编辑/保存`; persisted to `localStorage` key `seven-fifty-five.cc98-posts.v2`
- Reset: top-right menu → `恢复默认帖子`
- Interaction: time tabs, bottom navigation, full-page post details, editable title/author/board/metrics/time/body
- Search: typo-tolerant local material search; library-finals results live in `src/data/library-finals.content.json`
- Thread scaffold: owner floor, operation log, reply floors, pagination, `bd = 帮顶` explanation, eight numbered reply posts, and a persistent four-digit BD password
- Forum-treasure asset: `src/assets/ui/cc98_forum_treasure.png`
- Visual reference: `pageexample/cc98_hot_topics_reference.png`
