# Canteen dark-mode blue fibers

## Audit and scope

The approved native base already retained the 31 original light-NPC frame pairs,
the original three-frame shadow-auntie sheet and seven-index animation sequence,
and 180 ms NPC mode fades. Those implementations and all original art stay intact.
The four procedural circles from `CanteenInteriorScene.createDarkModeLayer` were
missing. This change restores those circles, not a new particle system.

Source authority is the original `CanteenInteriorScene.ts` methods
`createDarkModeLayer` (line 1945) and `playModeTransition` (line 2190), plus
`CanteenInteriorModel.ts`'s third `CANTEEN_PICKUP_WINDOWS` point. The source oracle
records exact method hashes and locations in the checked-in fixture.

| Property | Source value |
| --- | --- |
| Centers | (790,218), (82,250), (1380,850), (1235,227) |
| Radius | 2, 3, 2, 3 source pixels |
| Fill | #8be6ff, fill alpha 0.92 |
| Depth | 1602 |
| Motion endpoint | (+11,-9), (-9,-9), (+11,-9), (-9,-9) |
| Yoyo leg duration | 420, 457, 494, 531 ms |
| Idle object alpha | 0.2 → 0.95 |
| Mode fade | 220 ms linear, delays 0/9/18/27 ms |
| Mode fade target | Dark 0.9; light 0 |
| Reduced mode fade | 120 ms, no stagger |

The installed source Phaser `Stepped` ease defaults to **one step**. Therefore the
original motion holds its endpoint and returns to the start on a yoyo boundary;
it is not a smooth bob. The fixture includes 516 samples produced by the actual
installed Phaser `TweenData` implementation, including non-divisible 17 ms ticks.
The Godot model follows those samples, without using or reseeding gameplay RNG.
Fill opacity multiplies the independent object alpha, as in the source circle.

## Ownership and lifecycle

`c3_mode_fibers.gd` is a read-only presentation model. The existing Chapter 3
world-layer clock ticks it. Repeated draws, paused world/phone views and negative
deltas do not advance the model. Scene reentry resets its transient clock.
Defense entry hides the circles immediately; completion cannot resurrect them
without a fresh mode switch or scene entry. There are no completion callbacks,
controller events, scene transitions, random calls, or item/save/fact writes.

Rapid mode changes replace the current fade. This avoids stale alpha/hide
callbacks from an old mode. Unlike overlapping original Phaser alpha tweens, the
single native consumer gives the current mode transition sole opacity ownership
while it runs. It retains the original transition timing and target values.
Reduced motion keeps the original four points and stable 0.9 object alpha after
the source 120 ms fade, suppressing the perpetual flicker/displacement.

The existing native room tint and NPC fades are deliberately unchanged. This
batch does not claim shader-exact dark-overlay parity or full-scene pixel parity.

## Native rendering integration

`c3_mode_fiber_view.gd` consumes circle snapshots in a dedicated native `Node2D`.
Its source-space parent applies the shared camera transform. It must be registered
in the independent canteen scene's source-depth sort at 1602 and native z bucket
`Prop.draw_layer(1602)`. It has no timer, input surface, interaction ID, or physics
body. Ordinary mode changes reuse the same view; scene exit clears its samples.

The independent object-scene file belongs to the integration owner. This branch
therefore leaves it untouched. The companion integration patch targets the props
batch commit `bf8861f365f38c50b3a3b5aed1f985de685a4c1b`. Apply it after integrating
that batch. Merely adding circle entries to `chapter3_world_layers.gd` is not
sufficient: the production canteen renderer has its own draw path.

`test_canteen_mode_fibers_native.gd` intentionally requires the real mounted view,
its four visible samples, depth, reduced mode, no pick surfaces, no duplicate
nodes on redraw, defense clearing and scene exit/reentry. It will fail if the
integration hook is omitted.

## Verified in this batch

- Original-method/Phaser source oracle: four circles, four transition variants,
  and 516 actual TweenData samples verified
- Isolated Godot 4.6.3 model/native-view test: **677 checks, 0 failures**
- Node syntax checks, `git diff --check`, passive-authority guards and integration
  patch applicability against the designated props commit all passed
- Production renderer test and graphical acceptance require the integration
  owner’s object-scene hook; they were not run in this isolated worktree

## Verification commands

- `node godot_native/tests/export_canteen_mode_fibers_source.mjs --source-root <original-source-root> --check`
- `godot --headless --path godot_native --script res://tests/test_canteen_mode_fibers.gd`
- After the object-scene hook is integrated: `godot --headless --path godot_native --script res://tests/test_canteen_mode_fibers_native.gd`
- Existing regression: `test_chapter3_world_layers.gd`, `test_canteen_native_layers.gd`, `test_canteen_scene_lifecycle.gd`

The focused model/view test can also run in an isolated minimal Godot project
containing only the two presentation scripts, its test and source fixture; no
art imports or shared caches are needed. The production test uses the normal
prepared native project. Real graphical capture and manual review remain
separate acceptance steps; headless node checks are not visual-parity evidence.
