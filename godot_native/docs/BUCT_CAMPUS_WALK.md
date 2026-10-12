# BUCT Chaoyang campus walk

The native default launch opens a small entry chooser. **Continue 7:55** loads the existing Zhejiang story scene without resetting it. **BUCT campus walk** loads an independent exploration scene. Its return button, or Escape after closing a landmark/overview, returns to the chooser.

The existing `--fresh`, `--story`, `--preview=`, `--checkpoint=`, `--page=` and `--screenshot` launch arguments bypass the chooser once, preserving story recovery and test launches. `scenes/main.tscn`, the story controllers, State autoload and save schema are unchanged.

## Open corridor

South gate → main-building forecourt → west-side garden/promenade → library forecourt. This is a bounded playable corridor, not a claim that every campus path is open. Unopened lawns and building footprints block movement. Some short connections under foliage are inferred gameplay geometry; the JSON identifies them explicitly.

- WASD/arrows: walk; Shift: faster walk
- Click/tap open paving: navigate using the same native CharacterBody2D and collision model
- Click/tap a landmark, nearby-landmark button, or E: information card
- Guide / reset / overview / zoom: visible pointer and touch controls
- Escape: close the card, then close overview, then return to entry
- Focus loss stops navigation and releases this module's movement actions

## Rendering and isolation

All runtime resources are under `res://campuses/buct/`. The approved 1448×1086 artwork remains source-sized. Forty-four independent native building groups, 91 authored building colliders, a 6,188-cell repair TileMapLayer and source-pixel polygon UVs are retained. The main facade has separate native depth baselines. All 11 authored ground shadows render below actors.

Tree crowns use the same source artwork. Their small trunk colliders are distinct from the overhanging leaves, allowing feet to pass under canopies. A small foot ring shows only when a crown covers the character's head; it does not fade trees or turn crowns into walls. The source plate and cleanplate PNGs are unchanged from the approved input.

BUCT does not reference State, write saves, install generic `walk_*` actions, change the global window scale, launch external tools, or depend on a desktop-only service. Its `buct_walk_*` actions are removed on exit. The UI uses the actual viewport and screen-space landmark targets. Debug views, capture controls, screenshots, recordings, build caches and development dumps are excluded from this integration.

## Regression checks

Run from the repository root after `node godot_native/tools/sync_source.mjs` and the ordinary native import:

```sh
godot --headless --path godot_native --script res://tests/test_buct_source_layers.gd
godot --headless --path godot_native --script res://tests/test_buct_playable.gd
godot --headless --path godot_native --script res://tests/test_buct_entry.gd
node godot_native/tools/validate_native.mjs
```

The entry regression uses isolated test saves in the standard validator. It compares full State snapshots and primary/backup file bytes across repeated campus visits, and exercises the actual chooser and map controls at 1440×900, 1280×720, 390×844, 844×390 and 667×375. The playable regression traverses the actual route, tests paving and native collisions, interaction, guide interruption, canopy ordering and reset. The source-layer regression tests every building's UVs, independent move/hide/restore and colliders.

Compact viewport and injected touch-event tests establish input/layout compatibility. They do not constitute a physical iPhone/Android run or a Web export; the repository currently supplies native Linux/Windows presets.

## Draft validation status (2026-10-12)

The focused source-layer, actual route and packed-resource checks pass. Actual desktop interactions verify two chooser/campus return cycles, the full three-landmark guide, keyboard movement, landmark cards and continuation into the unchanged Zhejiang opening. Compact desktop windows at 392×844 and 667×375 keep the controls and cards usable. A real graphics comparison reports zero changed source-image pixels and correct head occlusion behind/in front of the same tree.

The original ground-shadow reparenting exposed a teardown leak in both Dummy and GLES3 rendering: serialized anonymous Polygon2D names collided with new automatic names. Each shadow now receives a stable, object-specific name before reparenting. Regression tests retain a WeakRef to every ground shadow and require all to release on exit. This preserves their transforms, polygons, UVs and textures. Final integrated headless checks pass: 277 entry/lifecycle assertions, 101 gameplay assertions and 269 source-layer assertions. Final GLES3 source-pixel/occlusion verification and two GUI entry/return cycles exit cleanly without those resource warnings. The PR remains Draft while CI and the incomplete local Web-release stage are reviewed.

The unchanged root Web release suite passed 32 of 35 validators locally. Its large single-file build was killed with exit 137; the dependent single-file verifier and browser smoke then lacked the output. This is an incomplete local Web-release check, not a successful browser verification.
