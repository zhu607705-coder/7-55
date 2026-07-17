# P10 Treehole

- Scene ID: `treehole`
- Entry: backside treehole entry
- Reads: `items.avatarKey`, `items.waterDrop`, `items.lightBeam`, `digits.d4`
- Writes: `flags.treeUnlocked`, `flags.treeWatered`, `flags.treeLit`, `digits.d4 = "8"`
- Events: `solve_treehole`, `collect_digit`
- Assets: treehole door, seedling, fruit `8`
- Tests: all three requirements are needed before `d4=8`
