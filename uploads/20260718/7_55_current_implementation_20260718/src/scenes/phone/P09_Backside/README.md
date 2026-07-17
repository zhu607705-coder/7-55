# P09 Backside

- Scene ID: `dark_backside`
- Entry: dark mode slot after acquiring `reverseGear`
- Reads: `items.reverseGear`, `themeMode`
- Writes: `themeMode = "backside"`, `flags.backsideUnlocked`
- Events: `unlock_backside`
- Assets: backside app names and system skin
- Tests: cannot enter without `reverseGear`; successful use switches to backside
