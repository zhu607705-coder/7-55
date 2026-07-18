# P08 Settings

- Scene ID: `settings`
- Entry: desktop settings icon
- Reads: `flags.gearAligned`, `flags.gearUnscrewed`, `digits.d3`, `items.reverseGear`
- Writes: `flags.gearAligned`, `flags.gearUnscrewed`, `digits.d3 = "9"`, `items.reverseGear`
- Events: `solve_gear`, `collect_digit`, `get_item`
- Assets: gear slot, reverse gear, rotation feedback
- Tests: drag plus rotation or fallback grants `d3=9` and `reverseGear`
