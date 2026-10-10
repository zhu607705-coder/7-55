# Library counter stamp and return

## Scope

Based on `913bd512c19c70e842461e0357091dca3635d389` on `godot-version`. This is the Library front-desk service shown on presentation page 7, not Chapter 4 Room 201's plate press.

The original counter, two-frame clerk, 64×88 stamp PNG, paper palette and pixel font remain. The existing `identity_stamp.gd` scanner still opens from an accepted report interaction. Its scan gate and explicit stamp button remain. `library022.gd` still consumes `itemRecognitionReport`, grants `bagNonPersonProof`, and makes the existing dialogue eligible at 900 ms. The host now waits for the visible local paper handoff to finish before attaching that one proof dialogue. No story text, inventory ID, proof validation, save schema or audio transaction changes.

## Physical choreography

`library_stamp_motion.gd` is a pure presentation sampler. After real native preview showed the old 810 ms cycle was too abrupt, the ordinary local sequence is 1,480 ms:

| Time | Physical state |
| --- | --- |
| 0–260 ms | Original rigid stamp descends with continuous acceleration/deceleration |
| 260–340 ms | Visible alpha foot reaches the paper; local sheet load and ink build together |
| 340–460 ms | Stamp holds pressure; same paper and mark stay registered |
| 460–700 ms | Stamp lifts and paper relaxes |
| 700–820 ms | Brief clear view of the stamped sheet |
| 820–1300 ms | Same sheet moves left along fixed desk guides |
| 1300–1480 ms | Fully returned sheet transfers out with continuous opacity |

Incoming reports also move along those same guides. The stamp uses uniform 0.46 scale; its visible source alpha boundary, rather than the transparent full-rectangle bottom, defines contact. Paper is drawn first; its mark is below the stamp foot. The sheet retains its 46×28 extent and bends locally by at most 0.8 source pixel rather than stretching the full image. The clerk uses a small whole-frame lean under pressure.

Reduced motion uses the same bounded sequence over 420 ms, without clerk lean. It never skips the contact-before-ink / lift-before-return order. The renderer never writes progression. State replacement or scene reentry clears an interrupted local sequence and does not replay or duplicate an already earned proof.

## Dialogue handoff and interruption

The controller's original 900 ms eligibility delay is unchanged. Only `library_bag_nonperson_proof_issued` is held in its existing issued session while `Main` reports a live stamp presentation bound to the exact current state. The host attaches that same session on the next tick after the animation ends; it does not start another delay, award proof or alter global clocks. The layer ticks before gameplay input locks, so an issued story does not deadlock its animation.

The gate requires the actual world and frame to be visible, world processing enabled, the same Library scene and state, and a still-active layer. A hidden world, scene exit, state replacement or unavailable presentation releases this local wait to the existing controller/session policy. Reentry never restamps earned evidence. Low frame rates can lengthen the existing capped visual clock, but the dialogue waits for that real finish rather than hiding the moving paper. No recording flag participates in the production gate.

## Facing

An accepted `lib_scan` result rotates the actor once to the original `player_up_0.png` back-facing idle pose. It stops a pending point route, but does not lock facing each frame. The ordinary movement logic takes over again on the next movement. Distance, mode, selected-item and controller-refused attempts do not rotate the actor.

Open PR #104 changes the global actor turn state in `world.gd`. This patch does not import that unmerged module. When combining the two, the accepted-counter hook must select the immediate back pose and clear/satisfy any pending #104 turn state; asserting only the `facing` string would be insufficient. Current #107/#108 game and asset files are outside this patch.

## Reproduce

After normal source sync/import, run with official Godot 4.6.3:

```
godot --headless --single-threaded-scene --path godot_native --script res://tests/test_library_stamp_motion.gd
godot --headless --single-threaded-scene --path godot_native --script res://tests/test_library_stamp_facing.gd
godot --headless --single-threaded-scene --path godot_native --script res://tests/test_library_stamp_story_gate.gd
godot --headless --single-threaded-scene --path godot_native --script res://tests/test_library_world_layers.gd
```

Focused results: motion 28,359; story handoff 155; facing/controller 15; existing Library world 111; existing story sequence 718; zero failures. The motion suite samples every millisecond in normal/reduced sequences, checks rigid scale and contact, paper/ink registration, sequencing, opacity continuity, no progression writes, and mid-press / mid-return interruption. The facing suite uses the real World and original scanner/controller, with all four refusal gates and subsequent movement. Existing world-layer coverage retains real Main integration.

The review scene `scenes/library_stamp_review.tscn` instantiates the real Main, seeds only photo prerequisites and standing position, and obtains the report through the original controller. Drag that report to the counter and click the original stamp button. A passive render observer buffers the real frames and timestamps under writable `user://library_stamp_review`; it never supplies a game result. This scene is optional and does not change the project entry point. Unit checks and a local clip do not establish complete campaign traversal or physical mobile hardware behavior.
