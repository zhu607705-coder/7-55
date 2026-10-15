# Room204: one original table as an independent native scene

The first discussion table now has its own Node2D scene. Its original atlas sprite, StaticBody2D foot shape and Area2D pick shape share one source-space transform. World reads those shapes for its existing full-foot movement and central drag dispatcher. The original Chapter4 controller still validates and saves all placements.

Coverage is exactly `table:group_table_1` in Room204. The room background, other tables/chairs, story, source geometry and puzzle rules are unchanged. This is a native 2D scene, not a new 3D model or whole-room conversion. There are no new image assets.

## Source and ownership

- Original atlas: `assets/rpg/interiors/finale/chapter4-755/sprites/chapter4_a2_room204_furniture_v02.png`
- Original manifest and placement sources: `finale_environment_manifest.json`, `chapter4-three-floor-maze.layout.json`, `chapter4-755.content.json`
- Root: `(72,710)`, original90° rotation; source scale0.25
- Visible source trim: `(1056,34,438,178)`, pivot `(1275,210)`
- Foot: original `(1068,137,415,71)`, native103.75×17.75 rectangle
- Production pick: existing sourceRect `(1056,34,439,178)`, native109.75×44.5 rectangle. The separate demo used the manifest's wider interactionBounds; the production parity check caught that difference, and the adapter preserves the established picker instead
- Original collision metadata is `approximate:true`; this change does not claim a newly measured silhouette collider

`room204_table_adapter.gd` derives existence and transform from `Room204.entities(state)`. It writes no progress or save data. Its Area2D is not independently input-pickable. The existing World drag handler submits exactly one original controller intent.

The old table1 draw, foot calculation and pick rectangle are omitted only while the native scene owns that entity. On accepted group restoration, the controller removes that table and reveals its original three desks. The adapter detaches the entire native table immediately, including collision and input shapes. Floor/phase return and World disposal also retire the node. An unchanged pre-placement state can create exactly one new instance.

World's existing rendering commands are separated into callable passes. Two child draw canvases place the native Sprite2D at the same position in that order. The current native y-order, original atlas sampling, foreground, player and HUD behavior are preserved. This is not a claim that all inherited C4 occlusion rules already match the browser source; the existing player/furniture overlap behavior remains a separate migration issue.

## Validation

- Eight affected scripts pass: native object geometry/lifecycle, Chapter4 world,390/430/1440 root-pointer Room204 drag, contact movement, world object picking, modal/world input, inventory viewport transform, and the isolated elevator visibility prerequisite
- Final native object test:1315 checks,0 failures. Source foot/pick parity is checked over actual coordinates, not only node existence. Camera and zoom leave source geometry unchanged; moving the native root moves appearance/foot/pick and changes its occlusion pass. A final two-check strengthening derives that pass directly from the node position; ordinary synchronized poses are unchanged from the actual captures
- Actual earned campaign first completed the original A3 observations and all four stairs, saved/restarted at A2, then walked physically through the Room204 doorway. No campaign facts were injected
- Actual1180 pointer run: wrong target and out-of-reach rejection retained; after moving closer, the original group was accepted, exactly three placements were saved, and the old table footprint was walked through
- Final1180 screenshot matches the original earned baseline pixel-for-pixel:0 changed pixels across1180×812. Initial native atlas edge sampling differed by76 pixels; enabling region edge clipping restored exact output without altering source pixels
- Actual390×844 run: source table visible, real desktop-pointer drag accepted once, original three desks appear, phone opens and Escape returns, normal Save retains three placements
- Normal restart of that unchanged save opens its saved phone page; Return restores the same room. Actual426×860 and438×860 views were observed, with a saved426 screenshot and another walk through the old footprint. The window manager snapped between these sizes; exact430 is scripted coverage, not actual CUA
- Dummy audio; no subjective hearing or hardware finger-input acceptance. Actual runs used source projects, not a fresh exported package

The group target/proximity code was inspected while diagnosing rejected drops. The actual successful inputs prove operation and ownership, not first-time independent puzzle discovery. Existing generic out-of-reach feedback and furniture/player occlusion were not expanded into this one-object patch.

## Review boundary

This isolated candidate layers on the already isolated bakery world fixes. Clock/elevator fixes were prerequisites for the actual earned route, but are not part of this seven-file table patch. The shared checkout, canonical main save, Git index and published branch are unchanged. Commit scope selection, package validation and publication remain separate pending steps.
