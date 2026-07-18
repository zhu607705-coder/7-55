# P05 Control Center

- Scene ID: `control_center`
- Entry: desktop or backside control center
- Reads: `networkMode`, `themeMode`, `items.lightBeam`
- Writes: `networkMode`, `items.lightBeam`
- Events: `network_changed`, `get_item`
- Assets: network toggle, brightness slider
- Tests: cellular enables Tiyi; campus Wi-Fi enables check-in; backside brightness grants `lightBeam`
