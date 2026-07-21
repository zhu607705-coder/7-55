# P10 Treehole（已退役）

> 旧 `treehole` SceneId 已移除；现行数字与盆栽流程由 P10 Bonsai 及主屏交互承载。本文仅保留历史设计记录。

- Scene ID: `treehole`
- Entry: backside treehole entry
- Reads: `items.avatarKey`, `items.waterDrop`, `items.lightBeam`, `digits.d4`
- Writes: `flags.treeUnlocked`, `flags.treeWatered`, `flags.treeLit`, `digits.d4 = "8"`
- Events: `solve_treehole`, `collect_digit`
- Assets: treehole door, seedling, fruit `8`
- Tests: all three requirements are needed before `d4=8`
