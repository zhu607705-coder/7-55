# Original character-facing assets: native wiring audit

Baseline: `godot-version` at `37c795a7702942b053f772fecfd272227b425a39`.

This patch reuses existing source artwork. It changes presentation state, not story gates, physical feet, collision geometry, movement speed, save proof, or camera behavior. The projection stair puzzle and new side-chase prototype are separate changes.

## Character inventory

| Character / source | Original resources | Native result |
|---|---|---|
| Player, `src/scenes/rpg/RpgPlayerTextures.ts` | Front/down 8 frames, back/up 8, right-side 8, right-side idle; left is the original whole-side mirror | Shared selection now follows actual post-collision displacement, turns in place when blocked, keeps heading when released, and correctly reverses during automatic dorm pacing |
| Player turn animation, same source | Original pose → side pose (±6° whole-frame tilt) or front pose for side reversal → target pose; 132/150/170 ms | Restored the omitted transition sequence using original complete poses; CanvasItem, canteen Sprite2D, and alpha picking share texture, handedness, and pivot |
| Patrolling / chasing guard, `FinaleNpcTextures.ts` | `guard_walk_8frame`, `guard_walk_down_8frame`, `guard_walk_up_8frame`; 96×128 cells | Replaced fixed side sheet and global-time marching with real-direction selection and movement-local animation; stationary guards retain heading |
| A2 elevator attendant | Same guard directional resources, plus authored watch action | Turns toward a nearby visitor with real directional frames; resumes the authored watch action when not approached |
| Theater ticket inspector | `ticket_inspector_idle_front/back/left/right.png`, each 96×128; scan action | All four existing idle resources are now selected toward nearby visitors; scanning keeps the original action. React previously imported only front despite shipping all four |
| Bakery students | Original `student_walk` is left-facing; 8 frames, plus phone, bag-adjust and idle | Existing rightward mirror/leftward original remains; remaining endpoint pause now uses true idle instead of resuming walk in place |
| Maintenance cleaner and cart | Side/up/down 8-frame push sheets, 192×128 cells; authored action sheets | Resources are already copied byte-for-byte. The current authored route is horizontal `(1138,716) → (1072,716)`, with side art and its 96-pixel character crop. Preserve that correct route; do not apply this side crop to front/back cart sheets |
| Canteen queues, seated students, counter and return staff | Source multi-character two-frame atlases; queue students already face the counter with backs toward the viewer | Already connected. Preserve authored seating/service orientation and unique identities |
| Library/front desk staff | Source two-frame service pose | Already connected. No invented mirrored-front side/back drawing |

Source audit checked 50 relevant NPC/inspector/canteen PNGs against the original repository bytes. They are already present locally; this patch adds no replacement art. Merely having an unused direction in the asset folder is distinguished from having an authored movement/action route that calls for it.

## Facing contract

- Logical facing reacts to actual displacement; blocked input may turn the actor without movement
- Exact diagonals retain the previous dominant axis, preventing visual jitter
- The source turn animation is presentation-only and finishes after a quick key release
- Pan and zoom do not change a 2D world heading
- Stopping resets the walk clock and retains the last facing
- Alpha picking uses the same rotated whole-frame transform as rendering
- Existing whole-side mirroring remains the complete fallback. A future authored left cycle is used only if all 8 left frames exist
- Three-dimensional camera-relative heading belongs to the separate stair-puzzle renderer

## Verification

- `test_character_facing.gd`: 101 checks passed, including actual `World._process` movement, wall sliding/contact, stop/zoom, source turn timings, original inspector resources, guard sheets, nearby-guard facing, bakery pause and native canteen Sprite2D selection
- Final-code focused reruns passed: player metrics; world guard (71); world object picking (53); chapter3 world layers (129); chapter4 world (27); chapter4 phase world (37); canteen foot occlusion (10011)
- Full `test_world.gd` and `test_mobile_floor_route.gd` were terminated by the local environment with exit 137 under shared resource pressure. These are incomplete runs, not a full regression pass
- Native graphical verification is tracked in the PR. A seeded production-World input fixture is not an earned full-campaign playthrough
