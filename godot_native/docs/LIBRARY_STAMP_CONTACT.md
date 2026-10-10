# Library counter stamp and return

## Scope

Based on `913bd512c19c70e842461e0357091dca3635d389` on `godot-version`. This is the Library front-desk service shown on presentation page 7, not Chapter 4 Room 201's plate press.

The original counter, two-frame clerk, 64×88 stamp PNG, paper palette and pixel font remain. The existing `identity_stamp.gd` scanner still opens from an accepted report interaction. Its scan gate and explicit stamp button remain. `library022.gd` still consumes `itemRecognitionReport`, grants `bagNonPersonProof`, and schedules the existing dialogue at 900 ms. No story text, inventory ID, proof validation, save schema or audio transaction changes.

## Physical choreography

`library_stamp_motion.gd` is a pure presentation sampler. Its ordinary 810 ms window is retained:

| Time | Physical state |
| --- | --- |
| 0–140 ms | Original rigid stamp descends with continuous acceleration/deceleration |
| 140–180 ms | Visible alpha foot reaches the paper; local sheet load and ink build together |
| 180–230 ms | Stamp holds pressure; same paper and mark stay registered |
| 230–350 ms | Stamp lifts and paper relaxes |
| 350–420 ms | Brief clear view of the stamped sheet |
| 420–720 ms | Same sheet moves left along fixed desk guides |
| 720–810 ms | Fully returned sheet transfers out with continuous opacity |

Incoming reports also move along those same guides. The stamp uses uniform 0.46 scale; its visible source alpha boundary, rather than the transparent full-rectangle bottom, defines contact. Paper is drawn first; its mark is below the stamp foot. The sheet retains its 46×28 extent and bends locally by at most 0.8 source pixel rather than stretching the full image. The clerk uses a small whole-frame lean under pressure.

Reduced motion uses the same bounded sequence over 270 ms, without clerk lean. It never skips the contact-before-ink / lift-before-return order. The renderer never writes progression. State replacement or scene reentry clears an interrupted local sequence and does not replay or duplicate an already earned proof.

## Facing

An accepted `lib_scan` result rotates the actor once to the original `player_up_0.png` back-facing idle pose. It stops a pending point route, but does not lock facing each frame. The ordinary movement logic takes over again on the next movement. Distance, mode, selected-item and controller-refused attempts do not rotate the actor.

Open PR #104 changes the global actor turn state in `world.gd`. This patch does not import that unmerged module. When combining the two, the accepted-counter hook must select the immediate back pose and clear/satisfy any pending #104 turn state; asserting only the `facing` string would be insufficient. Current #107/#108 game and asset files are outside this patch.

## Reproduce

After normal source sync/import, run with official Godot 4.6.3:

```
godot --headless --single-threaded-scene --path godot_native --script res://tests/test_library_stamp_motion.gd
godot --headless --single-threaded-scene --path godot_native --script res://tests/test_library_stamp_facing.gd
godot --headless --single-threaded-scene --path godot_native --script res://tests/test_library_world_layers.gd
```

Initial focused results: motion 17,199; facing/controller 15; existing Library world 111; zero failures. The motion suite samples every millisecond in normal/reduced sequences, checks rigid scale and contact, paper/ink registration, sequencing, opacity continuity, no progression writes, and mid-press / mid-return interruption. The facing suite uses the real World and original scanner/controller, with all four refusal gates and subsequent movement. Existing world-layer coverage retains real Main integration.

This source checkpoint precedes fresh GUI capture and exact-head remote CI. Unit checks do not establish complete campaign traversal or physical mobile hardware behavior.
