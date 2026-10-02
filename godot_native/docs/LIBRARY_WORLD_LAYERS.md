# Library native layered props

## Source-backed rendering

`ui/library_world_layers.gd` reads `data/native/library-world-source.json`, generated from the active `LibraryInteriorScene.ts`, `LibraryInteriorModel.ts` and `LibraryShelfRevealMotion.ts`. The exporter evaluates the original backpack-construction method (41 vector parts) and shelf model/motion rather than replacing them with a newly designed asset. Existing PNG files remain unchanged.

The moving shelf uses the original 25-vertex silhouette, clipped by textured-polygon UVs to the original 1500×900 map. Its 123×123 original footprint at `(502,110)` is replaced, at background depth, by the exact authored floor sample at `(502,270)`. The cabinet shifts through all thirteen source delayed frames, ending at +16 pixels. The fixed mechanism and paper use the source depths. The replacement floor never becomes a foreground rectangle over the player.

The shelf collision is the union of the fixed rails and translated cabinet: `left = 502 + min(0, offset)`, `right = 625 + max(0, offset)`, `top = 108`, `bottom = 234`. This is intentionally not a simple translation of the original solid. `world.gd` consumes the live replacement in real `can_stand` checks. Source movement blocking lasts through the shelf's paper-transfer completion.

After backpack eviction, the baked bag is replaced by the exact 34×38 clean-table sample from `(1080,392)`, centered at `(1255,407)`, at background depth 2. A transient native vector backpack repeats the source's nine 70 ms forward/reverse shake cycles, then its 1900 ms wait and 1200 ms transfer to `(334,634)`. The clear patch survives completion and save reload; the animated sprite does not.

A source nuance is preserved: Phaser's default `Stepped` easing has one step and returns 1 for every positive input. Consequently, the backpack visually jumps/fades just after the transfer starts at 3160 ms, while its completion callback remains at 4360 ms. The native implementation is checked against the actual installed Phaser easing function. It does not replace the source motion with an invented smooth path.

The front-desk attendant uses the original 192×128 two-frame PNG, frame size 96×128, position `(334,632)`, bottom-center origin, scale 0.72 and depth 706. Idle playback is `[0,0,0,1,1,0]` at 1.8 fps with a 900 ms repeat delay. The original counter crop `(148,606,341,68)` at depth 728 covers the lower attendant correctly. The source stamp PNG, status panel, validation lights, report, checking/stamping frames and reduced-motion idle have live consumers. No substitute NPC or generated artwork is used.

Source sorting is preserved relative to `player.y + 120`; notably the cabinet depth is 330, mechanism 418, paper 425, seat status 548, backpack 557, attendant 706, counter 728 and stamp service 742. The capture fixture now uses the same `PlayerMetrics.visual_rect` and retained player texture as production.

## State and integration

The renderer reads facts and never writes puzzle state. `sync(state, scene_changed)` observes successful controller transitions during an existing visit; initial mount, reentry and replacement save dictionaries restore finished poses without replaying historical animations. `tick(delta_seconds, state)` advances runtime-only timers.

Production integration uses `draw_back`, `draw_front`, `replace_collision`, `blocks_movement`, `backpack_eviction_active` and `take_cues`. The latter preserves source reveal-completed and four backpack-broadcast events. The global Library story host remains the dialogue owner, and all controller acknowledgement gates are unchanged. Backpack transfer itself does not freeze free movement in the source; only sitting at the chair is guarded until transfer completion.

## Verification

- `node godot_native/tests/export_library_world_source.mjs --check`: source hashes, original geometry/timelines, easing outputs and source-backed native data match
- `godot --headless --path godot_native --script res://tests/test_library_world_layers.gd`: 108 checks pass, including all shelf frame boundaries, rail/cabinet collision union, authentic controller-triggered live world transitions, real `can_stand` changes, movement blocking, save/reentry poses, backpack timing, staff animation and reduced motion
- Existing Library story suite: 718 checks still pass
- Actual graphical Godot run through the cloud desktop produced twelve screenshots under `.screenshots/library-world/`; inspected the before/after backpack, moving shelf, player-depth case and attendant/counter rendering
- Capture command: `godot --audio-driver Dummy --path godot_native --script res://tests/test_library_world_layers.gd -- --capture`; `/workspace/shared/run755library.sh` is a local launch convenience

## Remaining limits

These captures are focused prop acceptance, not a continuous manual campaign. This layer does not claim complete parity for the separate entrance automatic-door/device presentation or every catalog/ambient effect. The source evidence-transfer particles to the inventory, some stamp indicator pulses and exact Phaser font/rasterization are not reproduced here. Those limits do not change the restored shelf/body collisions, bag removal, staff/counter layering or narrative/controller facts.
