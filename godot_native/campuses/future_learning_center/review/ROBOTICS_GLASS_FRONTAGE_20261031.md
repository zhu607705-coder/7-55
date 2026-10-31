# ASABE east frontage correction

The prior room used a generic opaque wooden double door. This did not match the
original 2F drawing or the supplied photographs. Passing movement tests for that
old doorway established navigability, not architectural fidelity.

The local export of `[external]未来学习中心234层建设需求说明书.md` identifies the
west/south 2F room as ASABE. Its `d7e9b5e4023c60de0e5fb570d3a20b09.png` plan draws
an operable frontage along the east edge. User photographs show neutral gray
metal frames, large glazed panels and safety dots. The plan itself is marked as
needing some updates; panel count, exact folds and opening angle are interpreted
for this playable view, not claimed as surveyed construction detail.

`f2_robotics_glass_frontage.png` replaces the entire east-side opaque frontage
with glazing and folded leaves. The 1212 × 1298 source canvas and existing uniform
world transform are retained. The opening is recalibrated to source y=676; only
its threshold, two doorway waypoints, east outside contour and foreground covers
change. Furniture, room extent, other floors and progression are not changed.

The original PNG remains available for comparison. The new PNG is the built-in
image generation result copied byte-for-byte, without raster resizing or filters.
The prompt, references and SHA-256 are recorded in
`data/robotics_glass_receipt_20261031.json`.

Verification evidence is in `.impeccable/review/flc_robotics_glass_20261031/` at
repository root. This is a standalone room review, not formal chapter acceptance.

- Godot 4.7.1 spatial regression: 1,768 checks, zero failures across 2F/3F/4F.
- Native 1280 × 720 pointer: 54 checks, zero failures. Simulated 844 × 390 touch:
  55 checks, zero failures. Both cross the opening in both directions, retain
  ground contact, reject closed-glass samples, circle the table and exercise the
  existing delivery puzzle. No keyboard events are required.
- Source sync, PNG dimensions/alpha/hash checks and combined generator
  idempotence pass. `scope_integrity.json` records identical furniture, room
  bounds, unrelated modules/ground and complete 3F/4F data.
- The standalone Web export passes import, startup and export using matching
  4.7.1 templates. Browser clicks exercise room → opening → corridor → room.
  Actual rendered captures show the folded glass leaves and retained table.
