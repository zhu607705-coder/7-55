# Endless stair B3: independent native preview

## Scope and ancestry

This is the user-requested B3 prototype publication on `godot-version`, based on `2c8cc05ed9297a4040c2e0916351bd9d57ee3a15` (2026-10-16). It is an explicit scoped native-preview request after the repository's older browser-only policy. No browser runtime, formal story entry, chooser button, controller, State/save owner, project default scene, workflow or deployment is changed.

The physics reconstruction originated in PR #106 at `1992e63713e6d561476aa43f68971170c3fe37c8`. That PR is still a separate unmerged Draft. This patch carries the required base physics under `chapter4_endless_stair_physics.gd`; it does not depend on merging #106, overwrite its folded-stair paths, or claim that prototype is already integrated. A separate local atrium variant remains preserved and is not part of this B3 review.

## Run

From a Git checkout, use the existing source synchronization step, import once, then open the independent scene with F6 (F5 still starts the existing game):

```sh
node godot_native/tools/sync_source.mjs
godot --headless --path godot_native --editor --import --quit
godot --path godot_native res://scenes/chapter4_endless_stair_preview.tscn -- --fresh
```

`--fresh` avoids loading formal saves. The project's existing State autoload still initializes, but the preview never writes it or grants campaign completion. The isolated Linux test runner uses fresh HOME/XDG directories and verifies State/save invariants. Use a separate user profile for graphical QA too.

A/D or left/right moves, Space jumps, Esc pauses. Held intent follows platform turns; release and press again remaps screen direction. Touch: hold a side to move, swipe up or second-finger tap to jump. Return closes only when this preview owns `current_scene`; an embedded host receives `exited` and owns application lifetime.

## Authored pursuit

| Phase | Fast pattern | Slow pattern |
|---|---|---|
| Chase | At least 2.0 s, 3.36 m/s target | Same |
| Windup | 0.50 s, 1.5 m/s; quick raised torch and single click | 0.40 s at 3.6 m/s, then 0.70 s toward 0.8 m/s; longer raised torch and double click |
| Burst | 1.10 s toward 4.8 m/s | 1.30 s toward 5.2 m/s |
| Recovery | 1.0 s toward 2.55 m/s, exhale | Same |

Fast/slow alternate deterministically. Speed changes at no more than 6 m/s² (0.1 m/s per 60 Hz tick). Terrain lookahead delays or cancels unsafe bursts at corners, gaps and obstacles. There is no teleport, distance rubber-band or player slowdown. Wrist-mounted light and actual-travel footstep cadence provide visible/audible cues. Five small deterministic PCM clips are generated at setup, not reallocated every frame.

The route has twelve continuous flights, eleven turns and a finite exit. The reference raw-input replay completes in 3485 ticks / 58.083 s, six jumps, five fast and five slow bursts. Its gap is 2.408–5.495 m. Standing still is caught in 70 ticks; running without jumps is caught in 649 ticks. Twelve tested half-second hesitations can recover. These are simulated checks, not a human win.

## Retained B2 presentation

- Close view focuses on the current section. Previous 04 fades out before the next 04 enters; all 3485 replay ticks permit at most one nonzero marker
- Steps/rails assemble progressively ahead of travel; every piece is fully seated at least 4.69 m before the player. Collision geometry always exists; reversing cannot remove built treads
- Opaque independent shadow-only geometry survives visual assembly. Continuous fan-triangle/OBB clipping stops the air-path ribbon at floors, stairs, walls and narrow blockers, including blockers between old sampled rays
- Cached static OBBs, conservative local candidates and MultiMesh batches avoid repeated inverse transforms and thousands of separate static draws
- Pause, completion, failure and exit stop active audio. Exit clears resume state. Inactive presentation cannot start delayed warning cues; retry clears all queued sound/pose/state

## Verification

```sh
node godot_native/tools/test_endless_stair.mjs
# Optional full repository native suite (requires usual source/media/dependency preparation):
node godot_native/tools/validate_native.mjs
```

The existing aggregate automatically discovers the eight `test_endless_stair_*.gd` suites; no CI workflow modification is needed. Source paths are namespaced and no global `class_name` is introduced. Test JSON and optional captures go to `user://endless_stair_b3/`, not tracked source files. B2-only tests and stale generated reports are not shipped.

Five inherited B3 suites cover 8657 checks (75 route, 79 pursuit, 17 feedback, 10 full presentation, 8476 beam geometry). The additional integration suite passed 55 checks for real SceneTree input cancellation, embedded and standalone exit, audio cancellation, restart and unchanged State/save bytes (8712 focused checks total). See the PR for the fresh exact-head results; pre-publication standalone results do not substitute for integrated CI.

## Renderer evidence and limitations

The delivered standalone video was native Godot MovieWriter output, 26 s / 1560 distinct 60 Hz frames with actual procedural audio. It uses deterministic inputs and offline recording, not manual real-time play. Full native replay reached the exit. Capture files are intentionally not in Git.

Earlier standalone 1280×720 GL Compatibility / Mesa llvmpipe, no recording or fixed FPS, approximately 23 s measurement window:

| Metric | B2 | B3 |
|---|---:|---:|
| Average actual FPS | 82.97 | 73.45 |
| Frame interval p50 | 11.76 ms | 12.58 ms |
| Frame interval p95 | 15.89 ms | 21.08 ms |
| Draw calls p50 | 93 | 93 |
| Scene nodes | 702 | 711 |

No other renderer was running during either B3 window. B3's p95 regressed; **stable locked 60 FPS is not established**. These are standalone measurements before the namespaced repository integration and should not be represented as integrated benchmark results. Native hardware/mobile/Windows performance remains unverified.

Optional actual-renderer helpers, with an isolated user profile and your own absolute output destination:

```sh
godot --path godot_native --resolution 1280x720 --disable-vsync --script res://tests/benchmark_endless_stair.gd -- --fresh
godot --path godot_native --fixed-fps 60 --write-movie /absolute/path/endless-stair.avi --script res://tests/capture_endless_stair.gd -- --fresh --full-run
```

The original player and guard PNGs match source bytes and are reused through normal sync. Only the small Noto CJK subset font is added with its license/provenance. No dedicated jump atlas exists in the source baseline: airborne poses reuse existing frames with true ballistic movement. The raised forearm uses a few pixel-block meshes, not a newly drawn full character animation. No campaign completion, full manual campaign, phone hardware or Windows execution is claimed.

## Local publication acceptance

On the namespaced patch based on `2c8cc05`, Godot 4.6.3 full asset import passed without parse errors. The five unchanged production Chapter 4 suites also passed: controller 117, guard 17, capture 64, chase rules 70, chase view 119 (387 checks). The complete native script graph loaded successfully. These focused local results are separate from the complete repository CI result recorded on the PR.

## Stair-contact animation revision (2026-10-16)

The original eight directional walk cells were complete and distinct. The defect was their timing: the player's fixed seven-tick sprite cadence covered about 5.06 treads per eight-frame loop, while the collision body auto-stepped by 0.165 m in one tick. On the first flight, 18 of 20 rises did not even change the sprite cell. This was not a missing PNG import.

`endless_stair_step_pose.gd` now samples sixteen alternating-foot stair phases from actual route distance and real floor rectangles. A supporting shoe stays at a fixed world contact; the other lifts, clears the next riser, plants, and transfers weight. No missing tread becomes a fictional landing. The first pose begins at the collision body's actual front-edge contact, including turn-to-flight entries.

`endless_stair_gait.gd` reuses the original source pixels. On stairs, a continuous original-texture upper mesh and the legs share one two-tread phase. The old eight-cell upper cycle repeated the same arm sweep twice; it is not used as an independent clock. Pelvis lead, torso lean, partial head counter-rotation and opposing arms all follow the actual contact phase. Near-foot identity is derived from camera depth on both stair headings. A narrow shoulder/elbow/wrist weight band avoids moving the backpack with the arm. The phone and its light stay anchored to the same warped original hand, and the guard keeps the original torch hand and windup overlay. Two small meshes bend strips of the **existing** trouser and shoe pixels around the knees; no replacement character art or source PNG is introduced. Original nearest filtering, palette, leg width and shoes are retained. The torso uses a bounded visual offset, not a changed collision path. Stop freezes by distance, platforms and airborne frames retain the original sprites, and landing re-entry removes the offset discontinuity over 0.50 m of actual travel. Guard footstep sounds use the same tread-contact token. Static source textures and mesh instances are reused; repeated render-only frames do not rebuild upper or leg meshes or re-trigger sounds. Conservative static floor buckets reduce each pose query from 262 boxes to at most 11 candidates, with exact cached/uncached parity across the full replay.

Fresh local verification:

- Eight focused suites: 8776 checks, zero failures (the previous 8712 plus 23 step-pose and 41 actual-view lifecycle/whole-body checks)
- Five unchanged production Chapter 4 suites: 387 checks, zero failures; full graph: 586 scripts, zero failures
- All 3485 player/guard/pursuit ticks match the independent published B3 replay, not just a new model compared with itself
- Player trace SHA-256: `3d48528af32e48f2817af4c5154b96d614fdcd10666a81d862720446c9df1e81`
- Full player/guard/pursuit trace SHA-256: `0364bc9122b979fc0202553837d4c745c668a18acf702ffcce0a242b303f7d80`
- 453 ordinary risers including landing-blend intervals: maximum visual body increment 0.023834 m (player-only 0.01490 m), instead of 0.165 m
- Six landings per actor: maximum first-moving-tick downward adjustment 0.002847 m; maximum absolute visual offset 0.164996 m, below the 0.18 m bound
- Repeated presentation, 90 stopped ticks, pause and restart verify mesh/contact/audio freezing and complete reset
- All 28 original character PNG hashes match the published B3 assets; cropped upper-body and hand/face/pelvis socket coordinates use the same deformation
- Near-hand versus near-foot correlation on both headings: player approximately -0.973, guard approximately -0.975; two-tread cycle closure below 0.000001 m
- Phone remains on one original near-hand pixel; maximum adjacent-tick local displacement 0.020731 m across the full replay

The full-body review uses identical 60 Hz reference inputs and cameras. It shows the preceding lower-body-only revision first, then the shared full-body revision, then an explicitly labelled 0.5x playback inspection. This silent near-view clip is for visual review; acceptance and PR publication remain pending. Earlier lower-body comparisons are superseded, not evidence that the full-body revision was accepted. Every video frame is captured from the native Godot renderer; it is **offline 60 Hz recording with simulated input**, not a claim of real-time locked 60 FPS or human play. Native frames, videos, test output, benchmark profiles and intermediate previews are kept outside Git. Mainline scenes, saves, lighting/occlusion, pursuit rules, route data and physics sources remain unchanged.
