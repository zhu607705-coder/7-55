# Team / recording room layout review — 2026-10-31

## Scope and provenance

This pass changes only the 2F team room and 3F recording room, plus the shared optional NPC presentation/interaction path. The old 173 / 379 / 193 object-ID prefixes are preserved in order. The original modules, floor polygons, doors, links, navigation waypoints, window data and wall covers are unchanged; all other room objects remain byte-for-byte equivalent as JSON values. No puzzle keys, progression fields or save schemas were added.

The two new PNG masters (`assets/room_props/media_cart.png` and `softbox.png`) were generated separately in the ChatGPT webpage. Original downloaded bytes and alpha are preserved. Their sanitized manifest records SHA256 and source registration; it intentionally contains no private conversation URL. Cable coils, tabletop monitors, the rail/baffle and the notebook reuse existing approved webpage PNG masters. Storage, furniture and student art reuse existing assets without relabelling their provenance.

## Layout

- **Team:** four workstation groups align with the measured north wall seam (source Y=275). Desk/chair/divider/monitor groups use 115% scale. Chairs are pulled forward into normal seated positions, with reachable front approaches. Two existing desks form a central project area at Y=4100. Two lockers use the wall's free right end. A mobile equipment cart carries an existing monitor and a separate cable reel. Two stationary students stand outside the workbench and doorway approaches.
- **Recording:** workstation, media cart and sofa form a north-wall working band (source Y=321). The desk/chair group uses 115%; the oversized legacy sofa is independently corrected to 180 world-pixel width. The camera tripod is 95 pixels high; the new light stand is 110 pixels high. Both retain the source aspect ratio. A student stands in the free eastern work area, not in the entrance.
- **Scale is not a blanket multiplier.** Furniture is compared to the existing player in actual rendered views. NPCs use the same Body metrics as the player (96×128 source frame, scale .65; 19.5×14.625 full-foot collision), not the enlarged furniture scale.
- The cart's visible region, wheel contacts and solid footprint are separate. Mounted devices share its sort baseline and do not become floor obstacles. `object_registration.json` lists every target-room object's bounds, footprint, baseline and parent, plus all NPC feet.

`tools/apply_room_layout.mjs` runs after every legacy ordinal-ID furniture pass. New independent objects have explicit stable IDs; applying the pass twice is a no-op. A complete building rebuild is deterministic.

## Evidence and limits

The paired PNGs are actual Godot **4.7.1.stable.official.a13da4feb**, OpenGL compatibility/llvmpipe captures from an isolated graphical fixture. `before_*` uses the merged #199-equivalent source tree `b0fea22cbd21b6373929922dbe10fb5b8963164f`, not an older empty-room preview. `after_*` uses this room layout. North and south are separate camera views of each tall room; a north view alone is not full-room coverage.

The grey outer letterboxing is the QA host's viewport, not new room art. The fixed room camera and navigation were not changed to hide placement issues. These captures are not physical-phone or deployed-Web acceptance.

NPCs are static existing sprites, with transparent-pixel picking, foot-depth sorting, shared navigation obstacles, and brief opt-in replies. They add no labels, quest gates, rewards or persistent dialogue state. The ordinary exit/back controls remain navigation, not object annotations. Historical independent activities outside the seven previously revised workbenches keep their existing presentation.

## Final verification

All native results below use the pinned **4.7.1.stable.official.a13da4feb** executable and isolated user/config/cache directories. Production autoloads are absent from the focused puzzle runner.

| Check | Result |
| --- | --- |
| All 50 isolated FLC suites, after the NPC bundle fix | 6,125 checks, 0 failures |
| Included: all 29 existing activity entry points | Integration 307 and door/approach/return routes 125, 0 failures |
| Included: all three NPCs | 155 checks, 0 failures |
| Included: recording / cable scaled-host input | 57 / 81 checks, 0 failures |
| Additional wall-storage / font / room-save / save-integration | 851 / 10,019 / 1,196 / 19 checks, 0 failures |
| Node layout/projection builders | 7 tests, 0 failures |
| Native CI registration contract | 16 tests, 0 failures |
| Complete building rebuild | All three floor JSON files retain identical SHA256 |

Run the focused suite with `GODOT_BIN=/path/to/Godot_v4.7.1 FLC_TEST_WORKERS=1 node godot_native/campuses/future_learning_center/tests/run_puzzles.mjs`. This machine needed one worker: an earlier three-worker attempt exceeded the 120-second floor-test timeout. The completed serial run, not that interrupted attempt, is the result recorded above. CI has separate registered layout, NPC and builder stages under its existing scheduler.

Actual mouse input in the formal activity host covered: team doorway → project student → short reply; approach/open/close the existing team sync workbench; approach/open/close the separate old signal bench; and approach/open/close the existing recording workbench. A 390×844 viewport also accepted a mouse approach to the recording student and displayed the reply. The 844×390 viewport was captured, but a landscape-sized puzzle opening was not completed manually. Touch-event paths, cancellation and scaled hosts were covered by automated input tests, not a physical touchscreen.

### NPC Web-pack closure

The two reused student PNGs are now byte-identical local copies under `assets/npcs/`, with their original paths and SHA256 in that folder's manifest. Referencing the old finale/canteen resource paths would require chapter 4/3 packs that FLC entry does not load. The new FLC paths avoid that hidden dependency without changing story pack policy or the original sprites.

A focused **real Web PCK export**, not only a filename assertion, was produced with Godot 4.7.1. The unchanged production planner discovered both `.png.import` entries and both anonymous `.ctex` payloads in `flc_activity_001`. The unchanged partitioner verified exact byte coverage and independently mounted all eight exported entries. A fresh Godot process then mounted only the FLC content pack and successfully loaded both textures at 192×128; no chapter 3 or 4 pack was mounted. Source subset PCK SHA256: `b9372e5ee2d73a7e14c0d9d18b934b8a52d85b14fbc93447efb12383dbd73b6f`.

This focused pack proof does **not** replace the full-game Web export, deployment or browser acceptance. Those remain the release CI's final coverage. The last GUI captures predate only the relocation to byte-identical NPC PNG copies; room geometry, sprite pixels and interaction code are the same.
