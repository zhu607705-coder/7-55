# P08 Settings（已并入主屏）

> 旧 `settings` SceneId 已移除；齿轮互动由 P13 手机主页承载。本文仅保留历史设计记录。

- Scene ID: `settings`
- Entry: desktop settings icon
- Reads: `flags.gearAligned`, `flags.gearUnscrewed`, `digits.d3`, `items.reverseGear`
- Writes: `flags.gearAligned`, `flags.gearUnscrewed`, `digits.d3 = "9"`, `items.reverseGear`
- Events: `solve_gear`, `collect_digit`, `get_item`
- Assets: gear slot, reverse gear, rotation feedback
- Tests: drag plus rotation or fallback grants `d3=9` and `reverseGear`
