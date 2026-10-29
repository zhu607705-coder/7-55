# Future Learning Center · three-floor object and gameplay review

All storage now follows measured wall roots in the existing room masters. Across 18 spaces, cabinet groups increase from 29 to 71, accompanied by eight parts racks, the fitted pantry unit, and a separate refrigerator at the far right of the 3F pantry. Original walkable ground, doors and floor links remain unchanged. [Wall placement, quantities, verification and reproducible comparison captures](review/WALL_STORAGE_20261028.md).

The review now assembles separate 2F, 3F and 4F room masters, with continuous gray floors and independent furniture. The user-corrected 2F center is an open platform without an invented wall or door. The northeast and southwest stairs and the elevator have paired, flat arrival zones. Restroom interiors remain closed. Dimensions are enlarged game space, not surveyed measurements.

[Validation and remaining visual limits](review/VALIDATION.md). The local gameplay review is generated from `review/gameplay.html`; its object gallery shows actual Godot room captures, including before/after studio furnishings.

The actual Godot review scene uses the original shared player metrics. One ground union owns the complete foot box, door apertures and path graph. Swept movement prevents tunnelling. PNG outer-wall silhouettes are measured separately from their rectangular bounds, so door thresholds have painted floor and do not leave transparent gaps. Camera bounds, deadzone and zoom blend as the player enters or exits a room; elongated X-Lab rooms retain both side walls while following along their length. `Tab` is an overview of the active floor, never a travel shortcut.

This remains a review scene. No production controller, save or chapter route changed, and the production Web preset excludes `campuses/*`. Per-floor render counts are recorded in each floor manifest’s `objectCounts`, including mounted screens, dividers and equipment. Counts are not unique equipment counts or proof of site accuracy. Whole-building proportions, exact window locations and room-specific equipment positions remain subject to reference review.

The preceding user clarification places the missing sofa area and large central table in the **3F pantry/lounge**. Two two-seat sofas return beside separate low tea tables; the photo-derived dark curved table grows from 500 to 580 world pixels and now has five opposing seats on each side. Chairs, desks and the player keep their existing scales. The side worktop shifts within the room to leave a clear route from the doorway to the sofas, cupboards and all four table sides. The floor outline and door remain unchanged. The precise furniture arrangement and seat count are review choices. The gallery retains this actual Godot room capture and its comparison to the immediately preceding pantry pass.

The new **2F mechatronics/electrical work area** groups one independent assembly bench, two tool carts, two seats and one parts rack around a clear circulation loop. Clicking the bench routes the player to it; nearby Space opens the same native workbench view. Players install a gear, route and tension a belt, then watch the drive move a test piece toward a mark. The empty bench is generated raster art; gears, belt and test piece are separate live parts. [Workshop design and reproduction](review/WORKSHOP.md) records the control model, spatial checks and standalone Godot Web export. Equipment and experiment placement are a game proposal, not a surveyed laboratory inventory.

The earlier facing-desk pass adds a counterpart to each studio bank: two eight-seat islands per studio, front/rear chairs and monitors, and one shared divider per opposing pair. An isolated review spawn sits in the clear aisle beside the desks; production checkpoints are untouched. The user's site photographs supplied the dark curved communal table, wooden planter/tree, mixed chairs, fitted oak sink cupboards and separate microwaves. The separate sofa area now coexists with that photo-derived furniture. The atrium uses measured white/glass crops from a generated variant; void boundaries are unchanged. [Photographic evidence and user-confirmed floor attribution](review/PHOTO_REFERENCES_20261028.md) records what the images establish. The blue frame and colored stools belong to 2F, within the existing open platform and camera zone. Exact site coordinates remain under review. Four separate post colliders leave the center traversable. Seven non-overlapping source crops preserve front/rear post depth; only the canopy overlap with the actor fades. Fourteen stools remain independent objects.

Laboratory tool carts/racks/soldering stations remain from the earlier equipment-reference pass. The 2F platform activity islands are gameplay proposals. Contact shadows remain visible under diffuse light; directional window light and cast shadows change with the review clock. No floor texture was added to disguise empty space.

The earlier disposable browser prototype remains available in a collapsed section and tests a separate proposed mechanic: move a whiteboard to shade a demonstration marker while keeping the camera clear, then repeat under opposite lighting. Added equipment blocks the complete board footprint and fast drags cannot tunnel through it. NPC idle frames and state-dependent dialogue are review behavior; native NPC walking, the proposed 3F/4F tasks, and production persistence are not implemented by this prototype.

## Reproduce

Use the project-pinned Godot 4.7.1 executable in `GODOT_BIN`.

```sh
node godot_native/campuses/future_learning_center/tools/build_building.mjs
node godot_native/samples/future_learning_center/run.mjs --test --headless
node godot_native/campuses/future_learning_center/tests/test_gameplay_prototype.mjs
node godot_native/samples/future_learning_center/run.mjs --resolution 1280x720
```

The runner creates an isolated native test profile. It does not read or write the player's real save. Set `FLC_CAPTURE_DIR` to an absolute output directory to capture each room and the overview. Add `FLC_EXPORT_MAP=1` for the full assembled PNG, `FLC_CAPTURE_MOTION=1` for 420 frames of actual Godot route-following/camera behavior, and `FLC_INPUT_CHECK=1` for ordinary keyboard and scaled pointer/touch tests. `FLC_WORKSHOP_CHECK=1` additionally exercises approach, dragging, trial feedback, completion, focus loss and return from the workbench. `FLC_TOUCH=1` enables simulated coarse-pointer controls. The map and captures are generated artifacts; originals and room placements remain separate.

Encode the motion PNGs at 30 fps into `room_camera_walkthrough.mp4`, then run `tools/build_review.mjs <FLC_CAPTURE_DIR>` for the local pan/zoom art review. That HTML is an art viewer, not an alternate game runtime.

Build the gameplay and object review using `node godot_native/campuses/future_learning_center/tools/build_gameplay_review.mjs <output-directory> <current-capture-directory> <previous-studio-capture-directory> [previous-pantry-capture-directory]`, then serve the output directory over localhost. Current captures must include `FLC_WORKSHOP_CHECK=1`. Export the linked playable scene with `GODOT_WEB_TEMPLATE=/path/to/4.7.1.stable/web_nothreads_release.zip node godot_native/samples/future_learning_center/build_web.mjs <output-directory>/lab` using the same pinned `GODOT_BIN`. The studio baseline shows the same-direction desks. Pass the immediate pre-lounge pantry capture separately for the current before/after comparison; omitting it retains the older shared baseline.

## Sources and assets

- [Floor requirements and supplied 2F/3F/4F drawings](https://zju-xlab.feishu.cn/wiki/NKVGwp4KxikWgSktPoucZzsvnUf)
- [X-Lab arrangement](https://zju-xlab.feishu.cn/wiki/SpJ3wj5Ghi3gKRkcXcTcDBY5nHp)
- [Accessible mechatronics laboratory arrangement](https://zju-xlab.feishu.cn/wiki/EhARw3BJdinWhmkqtjGcAL5On5f)

Private reference exports are not copied into this repository. Raster assets use the built-in imagegen tool. Original generated bytes are preserved in `assets/`; `data/room_assets.json` and `data/object_assets.json` record dimensions, alpha bounds and SHA-256. `data/floor_2.json`, `floor_3.json` and `floor_4.json` bind the masters to rendering, camera and collision. `data/generation_20261028.json` preserves the complete prompt set. The unused `f2_classroom` and old narrow `monitor` masters are retained as superseded drafts, not active scene assets.

## Validation

The focused suite checks all three floors: room counts, uniform image transforms, clear/blocked samples, door return paths, the open 2F platform, paired transit, complete-footprint boundaries, furniture collisions, camera limits, and directional lighting. Runtime input checks cover desktop and scaled mobile windows. They do not establish physical-device acceptance, final visual fidelity, the three-floor story, or a production Web release.
