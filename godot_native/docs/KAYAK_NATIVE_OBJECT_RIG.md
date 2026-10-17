# Native kayak object rig

The lake kayak is an actual Godot scene: `scenes/objects/kayak_rig.tscn`.
Open it directly in the Godot editor to inspect the source-art hull, seated
player, both arms, both paddles and wake without opening the game or running a
preview. The scene has an authored rest pose, so it is visible in the 2D editor.

## Object hierarchy and ownership

- `Kayak`: presentation root, source scale `0.52 × zoom`, heading and overall alpha
- `Wake`: four independent `Line2D` ellipses; stern responds to forward speed,
  bow responds to reverse speed
- `BodyRoll`: the existing roll, body offset and dramatic rain-capsize transform
  - `Hull`: original extracted `128 × 160` SVG as a centered `Sprite2D`
  - `SeatedPlayer`: original extracted `128 × 160` SVG as a centered `Sprite2D`
  - `LeftPaddle`: willow-paddle packed scene, transform origin at `Grip`
  - `LeftArm`: arm packed scene, shoulder → elbow → hand transform chain
  - `RightPaddle`: rigid warning-sign-paddle packed scene, origin at `Grip`
  - `RightArm`: separate instance of the arm scene and its own joint chain

Each paddle has real `Shaft`, `BladePivot`, blade artwork, water-contact ripple
and exit-droplet nodes. Only the willow's intermediate shaft point flexes. The
warning triangle, warning dot and slash remain rigid together below its blade
pivot. The hand's grip marker and the paddle's grip marker coincide after the
camera, heading, roll and capsize transforms. There is no per-frame node creation.

The subtree uses equal native z indices and explicit scene-tree painter order.
This keeps every part between the world's `BeforeKayak` and `AfterKayak` passes.
Front targets, foreground crops and HUD therefore still cover the entire boat;
no arm or paddle escapes that order with a global z-index override.

`kayak_visual.gd` now provides read-only articulation samples. It contains no
`_draw`, draw helpers or centralized drawing calls. The rig changes only node
transforms, line geometry and visibility. The four existing phases, 680 ms stroke
clock, forward/reverse sweep, hand positions and per-side input history remain
unchanged. `games/kayak_model.gd`, controller actions, input, collisions, saves and
story progression are not modified by this extraction.

## Lifecycle and consumers

`world.gd` owns a `NativeKayak` adapter. It creates the packed rig for the active
lake kayak, hides it while another presenter owns the actor, and frees it on
scene exit or disembark. Reentry creates a fresh instance. The adapter does not
advance physics or hold a second movement state.

The forced-rain presenter instantiates the same rig. Its authored route supplies
per-side stroke history, so a new opposite-side stroke does not reset a paddle
still returning from its previous stroke. The walking approach/rescue actor is a
separate `Sprite2D`; each capsize splash ring is an independent `Line2D`. These
nodes are owned and freed by the presenter. Video, skip, cancellation, real-time
receipt and controller settlement are unchanged.

## Focused verification

2026-10-11: native rig **699**, rain-object **19**, fixed-step **61**, boundary
feedback **31**, rotation/contact **872**, world geometry **9** and real rain
rescue **17** checks passed in isolated headless Godot 4.6.3 runs.
Rendered GUI review remains separate from these checks.

Use isolated XDG data/config/cache folders under `/tmp`, then run:

```sh
godot --headless --path godot_native --script res://tests/test_kayak_native_rig.gd
godot --headless --path godot_native --script res://tests/test_kayak_rain_nodes.gd
godot --headless --path godot_native --script res://tests/test_lake_assembly_paddles.gd
godot --headless --path godot_native --script res://tests/test_kayak_frame_budget.gd
godot --headless --path godot_native --script res://tests/test_rain_rescue.gd
```

The new rig test checks native scene/node identity, source bounds, authored rest
pose, all stroke phases in both directions at three roll values, exact transformed
joint/grip positions, wake direction, capsize transforms, node reuse, ordered
world integration, hiding/restoration, disembark and destruction/reentry.

`test_kayak_rain_nodes.gd` additionally checks the real rain presenter's native
objects, overlapping independent stroke phases, walking/kayak/cinematic handoffs,
constant-width splash, state isolation and cancellation cleanup.

These are focused object and lifecycle tests. They do not establish complete
chapter parity, Windows execution or physical-device acceptance.
