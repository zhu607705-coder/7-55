# P03 Avatar Puzzle（已退役）

> 旧 `avatar_puzzle` SceneId 已移除；现行头像斜线互动位于 P14 微信场景。本文仅保留历史设计记录。

- Scene ID: `avatar_puzzle`
- Entry: click friend avatar in CC98
- Reads: `items.avatarKey`
- Writes: `items.avatarKey`
- Events: `solve_avatar_key`, `get_item`
- Assets: avatar puzzle pieces, friend voice placeholder
- Tests: solved puzzle grants `avatarKey` once
