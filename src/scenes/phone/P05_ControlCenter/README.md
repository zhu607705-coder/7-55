# P05 Control Center（已转为共享覆盖层）

> 旧 `control_center` SceneId 已移除；现行实现位于 `src/components/ControlCenter.tsx`。本文仅保留历史设计记录。

- Scene ID: `control_center`
- Entry: desktop or backside control center
- Reads: `networkMode`, `themeMode`, `items.lightBeam`
- Writes: `networkMode`, `items.lightBeam`
- Events: `network_changed`, `get_item`
- Assets: network toggle, brightness slider
- Tests: cellular enables Tiyi; campus Wi-Fi enables check-in; backside brightness grants `lightBeam`
