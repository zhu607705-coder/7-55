# Canteen queue floor-tap precision

This bounded input repair keeps the canteen's source rectangles, actor feet, movement speed, existing route planner, object picker and story authority unchanged. An empty-floor request whose full feet narrowly overlap a rectangle can resolve to the nearest legal full-foot position within **6 physical screen pixels**. It applies only in the canteen with its rectangle-only collision data. Other scenes and mask-based floors retain their prior destination behavior.

Raw centers inside a solid rectangle, visual frames outside the world, and valid but unreachable destinations do not redirect. The nearest legal correction must also be unowned by objects, actor pixels and reserved HUD controls. Ownership vetoes the correction; it never searches for a farther alternative. Every movement frame still uses the existing collision test. Accepted destinations have a stronger pale ring; rejected floor destinations have an amber X on a dark disk.

## Reconstructed queue endpoint

The 390×844 recorded run contains four world wheel-down presses and these client inputs: `(168,330)`, `(329,695)`, `(45,341)`, `(79,321)`. The four presses take a fresh canteen zoom from `0.85` to `0.45`. Main's world rectangle is `(10,66,370,712)`, consistent with the saved pre-tap screenshot.

The ordinary post-tray save starts at actor `(1440,574.368042)`. Root-input reconstruction walks first to `(1200.888889,234.368056)`, then to `(867.555556,258.8125)`, matching the reported pre-keyboard actor. At that actor position, camera `(867.555556,470.5)` transforms the later `(79,321)` input as follows:

| Quantity | Source coordinates |
|---|---|
| Requested foot center | `(609.777778,246.055556)` |
| Requested actor anchor | `(609.777778,214.368056)` |
| Full feet | `x600.027778..619.527778`, `y238.743056..253.368056` |
| Blocking source rectangle | `north_service_wall`, bottom `y241` |
| Full-foot overlap | `2.256944` source pixels, about `1.015625` screen pixels |
| Corrected foot center | `(609.777778,248.3125)` |
| Corrected actor anchor | `(609.777778,216.625)` |

The same planner returns `(809.75,261.875) → (770.25,261.875) → (609.777778,216.625)`. Both real root mouse and touch input reach it through normal Main frames with legal full feet throughout. The raw point has no object/actor/HUD veto in this reconstruction. The planner correctly rejected the original invalid endpoint; this change is an input precision repair.

The trace does not contain per-frame actor/camera/NPC state or an F12 capture of either stalled endpoint. The earlier `(45,341)` tap can encounter a transient NPC pick in some unsaved runtime configurations. The portable regression therefore explicitly seeds NPC dialogue assignments with `755` and uses animation phase `0` for that approach. These are fixture controls, not claims about the recorded session. Queue collision placement is deterministic; dialogue assignments and visual frames are separate. The production patch retains the original ownership veto.

## Automated checks

`test_canteen_queue_floor_tap.gd` runs 89 checks using a clearly labelled source fixture. `EARNED_QUEUE_REPLAY=1` instead uses the ordinary save already loaded from an isolated profile, with the same 89 checks. Both pass. Their movement comparisons exclude only position fields; inventory, wallet, story facts and action counts remain unchanged. The copied ordinary save remains byte-identical.

The final patch also passes existing floor routing (73), orientation/bag/cancellation coverage (123), Room204 drag routing (126), object picking (53), and compact feedback (810). This is 1,363 checks including both new test modes. The new tests cover the exact corrected endpoint, valid raw goals, solid centers, outside-world requests, actor/HUD ownership, painted nearest-point veto, physical-radius overflow, hard barriers, and canteen-only scope. They are headless input tests, not new manual CUA acceptance or physical-phone evidence.

Run the portable test:

```
godot --headless --audio-driver Dummy --path godot_native --script res://tests/test_canteen_queue_floor_tap.gd
```

The optional `QUEUE_REPORT` environment variable names a JSON output file. A graphical run with `QUEUE_CAPTURE_DIR` set saves before/accepted/arrived fixtures; index `2` is the exact repaired mouse request and index `5` is its touch repeat. Dummy headless rendering cannot produce screenshots. These captures are automated fixtures, not manual evidence.

## Actual CUA retest recipe

Use a separate ordinary-profile copy of `earned-three-dirty-trays-save.json` from the post-tray run. Do not replace the active campaign save. Start Main normally at 390×844, with the inventory collapsed. Use the visible ordinary return-to-world action. Confirm the world content starts at client `(10,66)` and measures `370×712` before using coordinates below.

1. At client `(195,408)`, send four wheel-down detents. The original two 160-pixel downward scroll calls yielded these four presses. Confirm zoom `0.45` in a read-only trace if recording.
2. Click client `(168,330)` and let walking finish. Expected actor `(1200.888889,234.368056)`. Clicking the actual interact control `(329,695)` preserves the source request to select the corresponding item.
3. Click client `(45,341)` and let walking finish. Expected actor `(867.555556,258.8125)`. If a transient NPC owns this press, record its feedback and stop treating that attempt as the exact endpoint replay; do not bypass its ownership or force the saved actor.
4. Save an F12 frame, then click client `(79,321)`. The accepted marker should be about one screen pixel lower, at `(79,322.016)` before camera movement. The actor should walk around the queue and finish at `(609.777778,216.625)`. Save an arrival frame and ordinary save. Queue/story facts, inventory and wallet must remain unchanged.
5. At the resulting camera, client approximately `(226.6,317.8)` requests solid wall center `(680,239)`. It must show an amber rejection marker and cause no movement. Repeat a legal floor tap and an actor/HUD press to confirm normal ownership.

For a window whose client origin is global `(470,70)`, steps 2–4 use global `(638,400)`, `(515,411)` and `(549,391)`. Add the actual observed client origin if the window moved. Do not copy global coordinates across a different viewport or camera.

This repair does not select the third student or interact automatically. Reaching the queue's source stand point and using the real interaction remains a separate player action. No graphical acceptance is claimed until that CUA replay is recorded.
