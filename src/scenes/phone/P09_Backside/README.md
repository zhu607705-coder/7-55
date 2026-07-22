# P09 Backside（已并入共享壳层）

> 旧 `dark_backside` SceneId 已移除；反面主题由共享手机壳层状态承载。本文仅保留历史设计记录。

- Scene ID: `dark_backside`
- Entry: dark mode slot after acquiring `reverseGear`
- Reads: `items.reverseGear`, `themeMode`
- Writes: `themeMode = "backside"`, `flags.backsideUnlocked`
- Events: `unlock_backside`
- Assets: backside app names and system skin
- Tests: cannot enter without `reverseGear`; successful use switches to backside
