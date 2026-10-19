# Local integration Git review

Refreshed: 2026-10-19T09:22:08.652650+00:00

A fresh `git fetch origin main godot-version` found both baselines unchanged. Current branch `integration/godot-complete-20261019` has no upstream; the following comparison explicitly uses `origin/godot-version`.

## 1. Working tree and untracked files

Tracked modifications: 106; untracked files: 232. These are integration implementation, recovered PR sources, tests, rules and evidence. No pre-existing user edits were present in the newly cloned checkout.

Generated tracked changes include initial state, SaveStore IR/domain/fixtures and the game-text source-line catalog. Ignored .godot caches, synchronized asset/media copies, dist/demo and exports are excluded from submission. Automatically created UID/albedo sidecars are excluded too; the source archive contains generated media required to run and excludes caches.

```text
 M .github/workflows/godot-native-ci.yml
 M .github/workflows/native-pr-integration.yml
 M AGENTS.md
 M README.md
 M docs/game-text-by-chapter.md
 M examples/blender_stair_sample/preview/assets/blender/stairwell_sample.glb.import
 M godot_native/README.md
 M godot_native/data/initial_state.json
 M godot_native/data/native/save-domains.json
 M godot_native/data/native/save_normalizer.json
 M godot_native/docs/PR_INTEGRATION_SOURCES_20261018.json
 M godot_native/scripts/chapters/c3_lake.gd
 M godot_native/scripts/entry.gd
 M godot_native/scripts/media/c3_rain_rescue.gd
 M godot_native/scripts/media/c3_swan_entrance.gd
 M godot_native/scripts/presentation/qizhen_swan_entrance_preview.gd
 M godot_native/scripts/state.gd
 M godot_native/scripts/world.gd
 M godot_native/tests/capture_c3_swan_entrance.gd
 M godot_native/tests/capture_maintenance_cover.gd
 M godot_native/tests/capture_phone_anchors_actual.gd
 M godot_native/tests/capture_wake_actual.gd
 M godot_native/tests/capture_world_overlay_layout.gd
 M godot_native/tests/export_lake_branch_source_fixtures.mjs
 M godot_native/tests/fixtures/canteen_handoff_source.json
 M godot_native/tests/fixtures/qizhen_branch_source.json
 M godot_native/tests/preview_lake_animation_stage.gd
 M godot_native/tests/preview_lake_assembly_paddles.gd
 M godot_native/tests/probe_whole_game_entry.gd
 M godot_native/tests/test_animation_batch_lifecycle.gd
 M godot_native/tests/test_bonsai_growth.gd
 M godot_native/tests/test_c3_bike_world_drop.gd
 M godot_native/tests/test_c3_canteen_devices_controls.gd
 M godot_native/tests/test_c3_canteen_source_parity.gd
 M godot_native/tests/test_c3_devices_controls.gd
 M godot_native/tests/test_c3_handoff_persistence.gd
 M godot_native/tests/test_c3_swan_entrance_shell.gd
 M godot_native/tests/test_canteen_bike_objective.gd
 M godot_native/tests/test_canteen_drink_handoff.gd
 M godot_native/tests/test_canteen_drink_performance.gd
 M godot_native/tests/test_canteen_menu_objective.gd
 M godot_native/tests/test_canteen_objective_journal.gd
 M godot_native/tests/test_canteen_pickup_objective.gd
 M godot_native/tests/test_canteen_victory_camera.gd
 M godot_native/tests/test_canteen_waiting_portrait.gd
 M godot_native/tests/test_chapter3_narrative_shell.gd
 M godot_native/tests/test_chapter3_promo_integration.gd
 M godot_native/tests/test_chapter3_reversal.gd
 M godot_native/tests/test_chapter4_chase_space_integration.gd
 M godot_native/tests/test_checkpoint_isolation.gd
 M godot_native/tests/test_compact_world_tasks.gd
 M godot_native/tests/test_dorm_cabinet_frames.gd
 M godot_native/tests/test_dorm_native_objects.gd
 M godot_native/tests/test_endless_stair_integration.gd
 M godot_native/tests/test_inventory_release_main.gd
 M godot_native/tests/test_journal_portability.gd
 M godot_native/tests/test_lake_assembly_shell.gd
 M godot_native/tests/test_lake_entry_heading.gd
 M godot_native/tests/test_lake_paddle_pointer.gd
 M godot_native/tests/test_lake_pursuit_feedback.gd
 M godot_native/tests/test_lake_reload_boundary.gd
 M godot_native/tests/test_lake_shell_input.gd
 M godot_native/tests/test_library_recovery_feedback.gd
 M godot_native/tests/test_library_reveal_handoff.gd
 M godot_native/tests/test_maintenance_cover_main.gd
 M godot_native/tests/test_mixer_layer_separation.gd
 M godot_native/tests/test_phone_anchor01_absence.gd
 M godot_native/tests/test_phone_anchor02_tiyi.gd
 M godot_native/tests/test_phone_anchor03_water.gd
 M godot_native/tests/test_phone_mechanism_feedback.gd
 M godot_native/tests/test_portrait_narrative_contract.gd
 M godot_native/tests/test_pr_integration_entry.gd
 M godot_native/tests/test_qizhen_branches.gd
 M godot_native/tests/test_qizhen_journal_save.gd
 M godot_native/tests/test_qizhen_swan_entrance.gd
 M godot_native/tests/test_room301_archive_main.gd
 M godot_native/tests/test_save_domain_guard.gd
 M godot_native/tests/test_save_integration.gd
 M godot_native/tests/test_theater_admission_feedback.gd
 M godot_native/tests/test_theater_gate_passage.gd
 M godot_native/tests/test_theater_preview_storage.gd
 M godot_native/tests/test_tiyi_presence_main.gd
 M godot_native/tests/test_wake_flash_source.gd
 M godot_native/tests/test_world_inventory_combinations.gd
 M godot_native/tests/test_world_overlay_integration.gd
 M godot_native/tests/test_zh_text_display.gd
 M godot_native/tests/verify_canteen_paper_art_source.mjs
 M godot_native/tests/verify_canteen_paper_effects_source.mjs
 M godot_native/tests/verify_continuity_entry.mjs
 M godot_native/tests/verify_lake_branch_source.mjs
 M godot_native/tests/verify_save_migration.mjs
 M godot_native/tools/package_swan_entrance.py
 M godot_native/tools/test_buct.mjs
 M godot_native/tools/test_endless_stair.mjs
 M godot_native/tools/validate_native.mjs
 M godot_native/tools/verify_pr_integration_pck.gd
 M package.json
 M progress.md
 M scripts/run-validation-suite.mjs
 M scripts/verify-native-pr-integration.mjs
 M src/core/GameState.ts
 M src/core/QuestModel.ts
 M src/core/SaveStore.ts
 M src/core/types.ts
 M src/modules/ChapterThreeQizhenLakeController.ts
 M src/scenes/rpg/RpgInventoryDock.tsx
?? .github/workflows/qizhen-blender-nearshore.yml
?? .github/workflows/state-write-policy.yml
?? docs/architecture/state-write-review.md
?? examples/legacy_godot_theater/.github/workflows/godot-spatial-slice.yml
?? examples/legacy_godot_theater/README.md
?? examples/legacy_godot_theater/SOURCE_ORIGIN.json
?? examples/legacy_godot_theater/docs/architecture/godot-migration.md
?? examples/legacy_godot_theater/godot-port/.gitignore
?? examples/legacy_godot_theater/godot-port/AGENTS.md
?? examples/legacy_godot_theater/godot-port/README.md
?? examples/legacy_godot_theater/godot-port/project.godot
?? examples/legacy_godot_theater/godot-port/scenes/theater.tscn
?? examples/legacy_godot_theater/godot-port/scripts/player.gd
?? examples/legacy_godot_theater/godot-port/scripts/theater.gd
?? examples/legacy_godot_theater/godot-port/tests/smoke.gd
?? examples/legacy_godot_theater/scripts/export-godot-theater.mjs
?? examples/legacy_godot_theater/scripts/lib/static-ts-data.mjs
?? examples/legacy_godot_theater/scripts/verify-godot-data.mjs
?? examples/legacy_godot_theater/src/assets/rpg/interiors/theater_interior.png
?? examples/legacy_godot_theater/src/assets/rpg/player/player_down_0.png
?? examples/legacy_godot_theater/src/assets/rpg/player/player_down_1.png
?? examples/legacy_godot_theater/src/assets/rpg/player/player_down_2.png
?? examples/legacy_godot_theater/src/assets/rpg/player/player_down_3.png
?? examples/legacy_godot_theater/src/assets/rpg/player/player_down_4.png
?? examples/legacy_godot_theater/src/assets/rpg/player/player_down_5.png
?? examples/legacy_godot_theater/src/assets/rpg/player/player_down_6.png
?? examples/legacy_godot_theater/src/assets/rpg/player/player_down_7.png
?? examples/legacy_godot_theater/src/assets/rpg/player/player_side_0.png
?? examples/legacy_godot_theater/src/assets/rpg/player/player_side_1.png
?? examples/legacy_godot_theater/src/assets/rpg/player/player_side_2.png
?? examples/legacy_godot_theater/src/assets/rpg/player/player_side_3.png
?? examples/legacy_godot_theater/src/assets/rpg/player/player_side_4.png
?? examples/legacy_godot_theater/src/assets/rpg/player/player_side_5.png
?? examples/legacy_godot_theater/src/assets/rpg/player/player_side_6.png
?? examples/legacy_godot_theater/src/assets/rpg/player/player_side_7.png
?? examples/legacy_godot_theater/src/assets/rpg/player/player_side_idle.png
?? examples/legacy_godot_theater/src/assets/rpg/player/player_up_0.png
?? examples/legacy_godot_theater/src/assets/rpg/player/player_up_1.png
?? examples/legacy_godot_theater/src/assets/rpg/player/player_up_2.png
?? examples/legacy_godot_theater/src/assets/rpg/player/player_up_3.png
?? examples/legacy_godot_theater/src/assets/rpg/player/player_up_4.png
?? examples/legacy_godot_theater/src/assets/rpg/player/player_up_5.png
?? examples/legacy_godot_theater/src/assets/rpg/player/player_up_6.png
?? examples/legacy_godot_theater/src/assets/rpg/player/player_up_7.png
?? examples/legacy_godot_theater/src/scenes/rpg/RpgPlayerTextures.ts
?? examples/legacy_godot_theater/src/scenes/rpg/TheaterInteriorModel.ts
?? examples/legacy_godot_theater/src/scenes/rpg/TheaterRuntimeContract.ts
?? examples/qizhen_blender_nearshore/ASSET_LICENSES.md
?? examples/qizhen_blender_nearshore/README.md
?? examples/qizhen_blender_nearshore/preview/.gitignore
?? examples/qizhen_blender_nearshore/preview/README.md
?? examples/qizhen_blender_nearshore/preview/SOURCE_SHA256.json
?? examples/qizhen_blender_nearshore/preview/assets/blender/blue.png
?? examples/qizhen_blender_nearshore/preview/assets/blender/blue.png.import
?? examples/qizhen_blender_nearshore/preview/assets/blender/grass.png
?? examples/qizhen_blender_nearshore/preview/assets/blender/grass.png.import
?? examples/qizhen_blender_nearshore/preview/assets/blender/orange.png
?? examples/qizhen_blender_nearshore/preview/assets/blender/orange.png.import
?? examples/qizhen_blender_nearshore/preview/assets/blender/path.png
?? examples/qizhen_blender_nearshore/preview/assets/blender/path.png.import
?? examples/qizhen_blender_nearshore/preview/assets/blender/qizhen_kayak.glb
?? examples/qizhen_blender_nearshore/preview/assets/blender/qizhen_kayak.glb.import
?? examples/qizhen_blender_nearshore/preview/assets/blender/qizhen_kayak_orange.png
?? examples/qizhen_blender_nearshore/preview/assets/blender/qizhen_kayak_orange.png.import
?? examples/qizhen_blender_nearshore/preview/assets/blender/qizhen_north_bank.glb
?? examples/qizhen_blender_nearshore/preview/assets/blender/qizhen_north_bank.glb.import
?? examples/qizhen_blender_nearshore/preview/assets/blender/qizhen_north_bank_blue.png
?? examples/qizhen_blender_nearshore/preview/assets/blender/qizhen_north_bank_blue.png.import
?? examples/qizhen_blender_nearshore/preview/assets/blender/qizhen_north_bank_grass.png
?? examples/qizhen_blender_nearshore/preview/assets/blender/qizhen_north_bank_grass.png.import
?? examples/qizhen_blender_nearshore/preview/assets/blender/qizhen_north_bank_path.png
?? examples/qizhen_blender_nearshore/preview/assets/blender/qizhen_north_bank_path.png.import
?? examples/qizhen_blender_nearshore/preview/assets/blender/qizhen_north_bank_stone.png
?? examples/qizhen_blender_nearshore/preview/assets/blender/qizhen_north_bank_stone.png.import
?? examples/qizhen_blender_nearshore/preview/assets/blender/qizhen_north_bank_wood.png
?? examples/qizhen_blender_nearshore/preview/assets/blender/qizhen_north_bank_wood.png.import
?? examples/qizhen_blender_nearshore/preview/assets/blender/scene_manifest.json
?? examples/qizhen_blender_nearshore/preview/assets/blender/shore_distance.png
?? examples/qizhen_blender_nearshore/preview/assets/blender/shore_distance.png.import
?? examples/qizhen_blender_nearshore/preview/assets/blender/stone.png
?? examples/qizhen_blender_nearshore/preview/assets/blender/stone.png.import
?? examples/qizhen_blender_nearshore/preview/assets/blender/wood.png
?? examples/qizhen_blender_nearshore/preview/assets/blender/wood.png.import
?? examples/qizhen_blender_nearshore/preview/assets/licenses/FUSION_PIXEL_FONT_OFL.txt
?? examples/qizhen_blender_nearshore/preview/assets/native/chapter3/black_swan_swim_atlas_v2.png
?? examples/qizhen_blender_nearshore/preview/assets/native/chapter3/black_swan_swim_atlas_v2.png.import
?? examples/qizhen_blender_nearshore/preview/assets/paddling/hand_grip.svg
?? examples/qizhen_blender_nearshore/preview/assets/paddling/hand_grip.svg.import
?? examples/qizhen_blender_nearshore/preview/assets/paddling/hand_palm.svg
?? examples/qizhen_blender_nearshore/preview/assets/paddling/hand_palm.svg.import
?? examples/qizhen_blender_nearshore/preview/assets/paddling/head.svg
?? examples/qizhen_blender_nearshore/preview/assets/paddling/head.svg.import
?? examples/qizhen_blender_nearshore/preview/assets/paddling/hull.svg
?? examples/qizhen_blender_nearshore/preview/assets/paddling/hull.svg.import
?? examples/qizhen_blender_nearshore/preview/assets/paddling/legs.svg
?? examples/qizhen_blender_nearshore/preview/assets/paddling/legs.svg.import
?? examples/qizhen_blender_nearshore/preview/assets/paddling/source/original_kayak.svg
?? examples/qizhen_blender_nearshore/preview/assets/paddling/source/original_kayak.svg.import
?? examples/qizhen_blender_nearshore/preview/assets/paddling/torso.svg
?? examples/qizhen_blender_nearshore/preview/assets/paddling/torso.svg.import
?? examples/qizhen_blender_nearshore/preview/assets/paddling/waist.svg
?? examples/qizhen_blender_nearshore/preview/assets/paddling/waist.svg.import
?? examples/qizhen_blender_nearshore/preview/assets/rpg/fonts/fusion_pixel_12px_proportional_zh_hans.ttf
?? examples/qizhen_blender_nearshore/preview/assets/rpg/fonts/fusion_pixel_12px_proportional_zh_hans.ttf.import
?? examples/qizhen_blender_nearshore/preview/docs/ASSET_PROVENANCE.json
?? examples/qizhen_blender_nearshore/preview/docs/BASELINE_README.md
?? examples/qizhen_blender_nearshore/preview/docs/BLENDER_SAMPLE_TECHNICAL.md
?? examples/qizhen_blender_nearshore/preview/docs/REFERENCE_AND_SCOPE.md
?? examples/qizhen_blender_nearshore/preview/docs/REFERENCE_GEOMETRY.json
?? examples/qizhen_blender_nearshore/preview/project.godot
?? examples/qizhen_blender_nearshore/preview/scenes/blender_lake_sample.tscn
?? examples/qizhen_blender_nearshore/preview/scenes/qizhen_large_world.tscn
?? examples/qizhen_blender_nearshore/preview/scripts/games/lake_geometry.gd
?? examples/qizhen_blender_nearshore/preview/scripts/games/large_world_model.gd
?? examples/qizhen_blender_nearshore/preview/scripts/presentation/blender_lake_sample.gd
?? examples/qizhen_blender_nearshore/preview/scripts/presentation/kayak_rig.gd
?? examples/qizhen_blender_nearshore/preview/scripts/presentation/kayak_stroke_timeline.gd
?? examples/qizhen_blender_nearshore/preview/scripts/presentation/lake_water.gdshader
?? examples/qizhen_blender_nearshore/preview/scripts/presentation/qizhen_large_world.gd
?? examples/qizhen_blender_nearshore/preview/scripts/presentation/qizhen_swan_swim_visual.gd
?? examples/qizhen_blender_nearshore/preview/tests/audit_large_world.gd
?? examples/qizhen_blender_nearshore/preview/tests/benchmark_blender_sample.gd
?? examples/qizhen_blender_nearshore/preview/tests/benchmark_runtime.gd
?? examples/qizhen_blender_nearshore/preview/tests/capture_blender_replay.gd
?? examples/qizhen_blender_nearshore/preview/tests/capture_blender_still.gd
?? examples/qizhen_blender_nearshore/preview/tests/capture_full_route.gd
?? examples/qizhen_blender_nearshore/preview/tests/capture_input_layouts.gd
?? examples/qizhen_blender_nearshore/preview/tests/capture_input_replay.gd
?? examples/qizhen_blender_nearshore/preview/tests/capture_material_compare.gd
?? examples/qizhen_blender_nearshore/preview/tests/capture_stills.gd
?? examples/qizhen_blender_nearshore/preview/tests/capture_visual_checks.gd
?? examples/qizhen_blender_nearshore/preview/tests/reproduce_pause_regression.gd
?? examples/qizhen_blender_nearshore/preview/tests/route_driver.gd
?? examples/qizhen_blender_nearshore/preview/tests/sample_route_driver.gd
?? examples/qizhen_blender_nearshore/preview/tests/test_blender_sample.gd
?? examples/qizhen_blender_nearshore/preview/tests/test_input_camera.gd
?? examples/qizhen_blender_nearshore/preview/tests/test_large_world.gd
?? examples/qizhen_blender_nearshore/preview/tests/test_route_30hz.gd
?? examples/qizhen_blender_nearshore/preview/tests/test_sample_route.gd
?? examples/qizhen_blender_nearshore/preview/打开说明.txt
?? examples/qizhen_blender_nearshore/render.sh
?? examples/qizhen_blender_nearshore/runtime/README.txt
?? examples/qizhen_blender_nearshore/source/build_lake_sample.py
?? examples/qizhen_blender_nearshore/source/build_shore_distance.py
?? examples/qizhen_blender_nearshore/source/package_sample.py
?? examples/qizhen_blender_nearshore/source/qizhen_north_bank.blend
?? examples/qizhen_blender_nearshore/verification/art-refinement-comparison.json
?? examples/qizhen_blender_nearshore/verification/capture-result.json
?? examples/qizhen_blender_nearshore/verification/depth-above-bank-visible.png
?? examples/qizhen_blender_nearshore/verification/depth-bank-occluded.png
?? examples/qizhen_blender_nearshore/verification/depth-water-visible.png
?? examples/qizhen_blender_nearshore/verification/files.json
?? examples/qizhen_blender_nearshore/verification/hud-1024x768.png
?? examples/qizhen_blender_nearshore/verification/hud-1280x720.png
?? examples/qizhen_blender_nearshore/verification/hud-390x844.png
?? examples/qizhen_blender_nearshore/verification/hud-844x390.png
?? examples/qizhen_blender_nearshore/verification/material-after-dock.png
?? examples/qizhen_blender_nearshore/verification/material-after-pickup.png
?? examples/qizhen_blender_nearshore/verification/material-before-dock.png
?? examples/qizhen_blender_nearshore/verification/material-before-pickup.png
?? examples/qizhen_blender_nearshore/verification/model_manifest.json
?? examples/qizhen_blender_nearshore/verification/native-visual-checks.json
?? examples/qizhen_blender_nearshore/verification/runtime-benchmark-before.json
?? examples/qizhen_blender_nearshore/verification/runtime-benchmark.json
?? examples/qizhen_blender_nearshore/verification/sample-map-context.png
?? examples/qizhen_blender_nearshore/verification/sample-map-narrow.png
?? examples/qizhen_blender_nearshore/verification/sample-route.json
?? examples/qizhen_blender_nearshore/verification/sample-tests.json
?? examples/qizhen_blender_nearshore/verification/sample-title-narrow.png
?? examples/qizhen_blender_nearshore/verification/video-probe.json
?? examples/qizhen_blender_nearshore/xorg.conf
?? godot_native/campuses/buct_pilots/chaoyang/assets/promenade-crowns.png
?? godot_native/campuses/buct_pilots/chaoyang/assets/promenade-ground.png
?? godot_native/campuses/buct_pilots/chaoyang/assets/promenade-shadows.png
?? godot_native/campuses/buct_pilots/chaoyang/assets/promenade-trunks.png
?? godot_native/campuses/buct_pilots/chaoyang/data/asset-contract.json
?? godot_native/campuses/buct_pilots/chaoyang/data/provenance.json
?? godot_native/campuses/buct_pilots/chaoyang/scenes/promenade.tscn
?? godot_native/campuses/buct_pilots/scripts/campus_visitor.gd
?? godot_native/campuses/buct_pilots/scripts/layered_tree.gd
?? godot_native/campuses/buct_pilots/scripts/pilot.gd
?? godot_native/data/native/chapter4-folded-chase.json
?? godot_native/docs/BUCT_LAYERED_PILOT.md
?? godot_native/docs/BUCT_STUDENT_CHARACTER.md
?? godot_native/docs/FOLDED_STAIR_CHASE_PROTOTYPE.md
?? godot_native/docs/FULL_INTEGRATION_20261019.md
?? godot_native/docs/FULL_INTEGRATION_SOURCES_20261019.json
?? godot_native/docs/HANDOFF_REVIEW_20261019.md
?? godot_native/docs/source_snapshots/pr143/test_endless_stair.mjs.source.txt
?? godot_native/docs/source_snapshots/pr143/test_endless_stair_integration.gd.source.txt
?? godot_native/docs/source_snapshots/pr144/package_swan_entrance.py.source.txt
?? godot_native/docs/source_snapshots/pr144/qizhen_swan_entrance_preview.gd.source.txt
?? godot_native/docs/source_snapshots/pr144/test_qizhen_swan_entrance.gd.source.txt
?? godot_native/docs/source_snapshots/pr148/stairwell_sample.glb.import.source.txt
?? godot_native/scenes/chapter4_folded_chase_preview.tscn
?? godot_native/scripts/games/chapter4_folded_chase_model.gd
?? godot_native/scripts/games/chapter4_side_chase_model.gd
?? godot_native/scripts/presentation/chapter4_folded_chase_view.gd
?? godot_native/tests/chapter4_late_continuity_recorder.gd
?? godot_native/tests/native_test_isolation.gd
?? godot_native/tests/probe_chapter4_late_entry.gd
?? godot_native/tests/test_buct_layered_pilot.gd
?? godot_native/tests/test_buct_student_artwork.gd
?? godot_native/tests/test_buct_student_distance.gd
?? godot_native/tests/test_buct_student_visual.gd
?? godot_native/tests/test_c1_autosave_resume.gd
?? godot_native/tests/test_chapter4_folded_chase_exit.gd
?? godot_native/tests/test_chapter4_folded_chase_model.gd
?? godot_native/tests/test_chapter4_folded_chase_view.gd
?? godot_native/tests/test_entry_previews.gd
?? godot_native/tests/test_lake_main_handoffs.gd
?? godot_native/tests/test_rain_rescue_ownership.gd
?? godot_native/tests/verify_c1_autosave_resume.mjs
?? godot_native/tests/verify_chapter4_late_continuity.mjs
?? godot_native/tests/verify_native_test_sandbox.mjs
?? godot_native/tools/native_test_sandbox.mjs
?? godot_native/tools/package_integration.mjs
?? godot_native/verification/integration_20261019/chapter1_continue.json
?? godot_native/verification/integration_20261019/chapter4_continue.json
?? godot_native/verification/integration_20261019/computer_use.json
?? godot_native/verification/integration_20261019/cross_pr.json
?? godot_native/verification/integration_20261019/lake_main_handoffs.json
?? godot_native/verification/integration_20261019/native_stages.json
?? godot_native/verification/integration_20261019/native_summary.json
?? godot_native/verification/integration_20261019/pck.json
?? godot_native/verification/integration_20261019/web_release.txt
?? godot_native/启动游戏.command
?? scripts/verify-full-integration.mjs
?? scripts/verify-qizhen-legacy-assembly.mjs
?? scripts/verify-state-write-policy.mjs
?? src/core/state/JsonSnapshotWriter.ts
?? src/modules/QizhenFinalAssembly.ts
```

## 2. Local commits absent from remote migration branch

Count: 71. This includes reviewed PR ancestry and eight local merge commits. HEAD: `0592269fb2d72944eef8c5aadf72a612cf99ea0f`. Subsequent implementation fixes remain uncommitted in the working tree.

```text
0592269 Merge remote-tracking branch 'origin/codex/theater-clue-reactions-20261011' into integration/godot-complete-20261019
c113bb4 Merge remote-tracking branch 'origin/feat/native-lake-assembly-paddles-20261011' into integration/godot-complete-20261019
679c9c0 Merge remote-tracking branch 'origin/feat/native-guard-chase-space-20261009' into integration/godot-complete-20261019
6886aff Merge remote-tracking branch 'origin/dot/maintenance-cover-hinge-20261009' into integration/godot-complete-20261019
6752e90 Merge remote-tracking branch 'origin/dot/room301-index-strips-20261009' into integration/godot-complete-20261019
0eb1fd0 Merge remote-tracking branch 'origin/fix/native-phone-anchors-01-03-20261009' into integration/godot-complete-20261019
3e23b17 Merge remote-tracking branch 'origin/godot/native-animation-integration-20261011' into integration/godot-complete-20261019
1b0f112 Merge remote-tracking branch 'origin/docs/runtime-migration-policy-20261010' into integration/godot-complete-20261019
eeda325 fix(native): persist chapter three narrative handoffs across Continue
0cfa162 Include subtitle timing dependency in isolated canteen effects parity test
3634fcf Merge reviewed PR149 native rescue test fix into Chinese text branch
502d67b Exercise revised Chinese in rule-action and portrait readability tests
dd9f37e test(godot): observe the first native rescue frame before timer polling
9df6fc9 Align remaining native display assertions with approved Chinese revisions
275e8bc Revise native Chinese text while preserving existing voice playback
c47a846 test(godot): verify full viewport bounds and capture actual rescue window
15674ef Make integration CI fail closed through logged pipelines
c1e7a46 Integrate controller-owned lake presentations and verify PR compatibility
98f6f15 Integrate PR #148 source snapshot for compatibility verification
7ce70e7 Integrate PR #147 source snapshot for compatibility verification
fee2ea8 Integrate PR #146 source snapshot for compatibility verification
e1e1083 Integrate PR #145 source snapshot for compatibility verification
f526810 Integrate PR #144 source snapshot for compatibility verification
95bc9ff Integrate PR #143 source snapshot for compatibility verification
9f8f7c5 feat(examples): add Blender-authored playable stair sample
f9ecd18 feat(godot): preserve B4 gait and refine stair camera input
9a1ca38 fix: preserve Qizhen strokes and unify responsive input/camera
6db7296 feat: add isolated Qizhen large-world Godot prototype
7ec8f23 feat(examples): add isolated playable Qizhen Lake chase
65f07d8 feat(samples): add isolated Qizhen rain rescue presentation
7d9e688 feat(godot): add approved 16-pose swan hop study
1386d88 feat(godot): add isolated Qizhen swan entrance and swim review
19b7104 feat(godot): add isolated endless-stair B3 rhythm preview
839108d Refine theater vent powder contact and soft paper flutter
801563c Model lake assembly and kayak animation as independent native objects
a9a47ef Integrate tested native animation batch and repair shared facing lifecycles
983cbf9 fix(native): use inventory release events across world viewports
80f6c18 feat(native): animate theater clues as independent Godot objects
2a667c3 Animate native lake rod assembly and independent kayak paddles
aca2b2f art(theater): register low-reflection acrylic and bronze ticket materials
41ccefe fix(theater): use transparent retracting ticket wings with safe closure
d55dfb0 fix(theater): show accepted ticket gate passage and preserve entry flow
2d571f6 Show native theater ticket acceptance and preserve auditorium handoff
457aa43 refine(godot): reduce stone noise and present clean native mechanism motion
10baff4 fix(godot): clear the door swept volume and lock native mechanism regressions
e957615 feat(godot): integrate refined stair_b assets with exact pivot motion and source graph
cd49419 docs: reconcile Godot native migration with retained Web baseline
320d7de Restore source paper styling and readable interaction states to Library verification
0f3fedc Slow Library stamp and defer dialogue until the visible paper handoff completes
c6838d6 Replay a complete first-pair sequence with recorded real pointer destinations
89469f5 feat(godot): register library stamp contact and guided paper return
ef8181c Show local enemy-hit feedback and remove verbose echo labels
31d17ff Regenerate theater text catalog and cover transparent pause button states
505f5e9 Document paired theater rules and verify damage precedence for cooperative light
c5ddfc1 Add paired light relay and third-act delayed cooperative echo
ff6620d Preserve analog arrival steps to stop pointer overshoot
6ab0f10 Strengthen static funhouse optics and replace opaque HUD panels
9a5557e fix(godot): guard optional theater preview diagnostic writes
e0dc90a refine(godot): retain theater wood and package editable stage model
24f253a feat(godot): model the theater through an input-calibrated funhouse lens
93de449 feat(godot): give each drink outlet a forward cup-pushed paddle
5182790 fix(godot): actuate drink flow with continuous cup and paddle contact
4f8fee0 feat(godot): dispense mixer ingredients through physical machine presses
9434639 fix(godot): reconnect source character directions and turn poses
634da6e Clarify successful Main coverage and remaining GUI boundary
065ab45 Bound chase proof sampling without cutting obstacle corners
26ed7bb feat(godot): integrate longer guard chase space with adaptive input validation
54987ed Add the source maintenance wheel-cover hinge and bounded load cleanup
647545d Merge verified native lamp baseline into phone anchors candidate
f7426ec Add Room301 source drawer with three integrated index strips
701efd1 feat(native): restore P01 wake and design anchors01–03 phone pickups
```

## 3. Remote commits absent locally

`HEAD..origin/godot-version`: 0; `HEAD..origin/main`: 0.

```text
(none)
```

Delivery is a reviewable local working tree, source ZIP and PCK. No final staging/commit/push, GitHub PR merge/closure or release was performed. AGENTS.md Delivery requires these three views and the user choice of exact submission scope before further Git mutation; that separate step is not inferred from implementation work.
