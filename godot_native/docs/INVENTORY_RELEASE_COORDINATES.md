# Inventory release coordinates

Native portrait inspection exposed a pre-existing input discrepancy. A release event at `(158,371)` reached the root viewport correctly, but native drag completion used a different polled mouse position `(344,495)`. The same original poster drop failed with all new clue nodes removed. The item stayed owned and no success fact was committed.

Godot 4.6's [`Viewport::_perform_drop`](https://github.com/godotengine/godot/blob/4.6/scene/main/viewport.cpp#L2228-L2234) polls the target's local mouse position. Window-bound accessibility events and touch-emulated mouse events can have a different event position. The application now retains that release event on the active native inventory drag, then maps it through the existing root/container/canvas transform once before the original world picker runs.

- Only the current source item's active native drag can attach the transient snapshot
- The snapshot is tied to its source viewport and input frame; it is not a saved state field
- A replacement drag has a fresh payload. Cancel/focus/exit paths retain native drag cleanup
- An outside-surface release is rejected; no nearest-target snapping or forced acceptance is added
- Native GUI dispatch still performs the single drop. The original item, target, proximity and controller checks remain authoritative
- Direct/programmatic calls without a valid event snapshot retain their supplied local coordinates

## Verification

Godot 4.6.3 with isolated HOME/XDG profiles:

- `test_inventory_release_coordinates.gd`: 189 checks across portrait/desktop/landscape, three container scales and `.45/.85/1.6` map zoom; wrong source, wrong viewport, stale frame, out-of-surface and replacement-drag isolation
- `test_theater_clue_main.gd`: 62 checks, original desktop mouse/portrait touch drop, cancellation and exact-once accepted facts, settings/phone/reduced-motion interruption
- Existing compact inventory: 212; viewport transform: 24; touch ownership: 62; gesture lifecycle: 37; inventory combinations: 64; bicycle actual world drops: 250; zero failures
- Native 390x844 before/after fixture: the same mouse drag is rejected before the fix and accepted after it. A final real window-bound pointer drag from `(209,738)` to `(158,371)` also succeeded, with live native samples at 407/852/1222 ms. Mouse and touch-event capture variants both completed with zero fixture failures. Tissue consumption and ticket creation use the original controller. Native visual inspection confirms the clue stays clear of the HUD and touch controls

These are native runtime fixtures, including a window-bound pointer comparison. They do not claim physical phone hardware testing or an earned campaign traversal.
