# Chaoyang two-tree layered-art pilot

This stacked Draft depends on PR #119. The original story and full-campus BUCT walk remain available through their existing chooser buttons. A third button, **朝阳步道 · 分层试点**, opens this bounded regional scene. **返回入口** returns to the same chooser without changing story or save state.

## Scope and artwork

Only two round-canopy trees in the source rectangle `(625, 565, 256, 160)` are reconstructed as complete independent objects. Four unmodified 1586×992 PNGs provide continuous repaired ground, actual-alpha crowns, restored branch/trunk structures, and translucent ground shadows. Other trees, the sculpture, steps and surrounding paving remain static background context.

Each tree uses native AtlasTexture regions registered to its source footprint. Its crown rotates at the branch joint while its trunk remains fixed. The independent ground shadow renders below the actor; only the small trunk footprint is a collider. Transparent atlas space and ground-shadow pixels cannot select a tree. Hiding an individual crown also removes that crown from selection.

The accepted PNGs and SHA256s are recorded in `campuses/buct_pilots/chaoyang/data/provenance.json`. The original approved source remains in #119; the source rectangle and inferred registration are documented in `asset-contract.json`. These assets are reference-guided artistic reconstruction, not a source-pixel-identical copy or surveyed hidden geography. Tree branches, covered ground and shadows include plausible completions. This is not a reconstruction of the entire campus or forest.

The pilot student is a separately registered visual child. See [BUCT student character](BUCT_STUDENT_CHARACTER.md) for its asset, movement and collision contract.

## Controls

- WASD/arrows or hold the visible direction buttons: walk on the bounded paving
- Click/tap a visible crown or trunk, or **选择下一株**: select a tree
- Q/E or **树冠左摆 / 树冠右摆**: adjust that crown, leaving trunk/shadow independent
- Space or the wind button: toggle gentle crown motion
- G or **绕树导览**: return to the start and follow the native collision-aware route around both trees
- R or **复位**: reset visitor, selection, crown poses and wind
- Escape: stop a guide, clear a selection, then return to entry; the return button always returns directly

Pointer release outside a direction button and focus loss both stop held movement. The UI adapts to portrait and compact landscape viewports. `buct_pilot_walk_*` actions are removed on exit without erasing preexisting actions. No global window scaling, State mutation, save writes, external tools, capture/debug controls or desktop-only service are part of this scene.

## Run and validate

After the ordinary native asset synchronization/import, use the game chooser or directly run `res://campuses/buct_pilots/chaoyang/scenes/promenade.tscn` in the native project. The standalone source project remains independently openable; this integration does not replace that source package.

Safe headless checks from the repository root (Linux):

```sh
node godot_native/tools/test_buct.mjs
node godot_native/tools/validate_native.mjs
```

Both runners use fresh isolated user-data directories. The save-writing entry fixture refuses undeclared, mismatched, unsupported-platform or preexisting-save locations. The new actual-art test checks PNG hashes/alpha, per-object independence, crown reset, selection, collision, real guided movement and lifecycle cleanup. The entry test covers both BUCT scenes, desktop/compact layouts, pointer/touch controls, repeated return, original story continuation and exact save-byte preservation.

The upstream regional source passed actual-renderer front/back occlusion and manual selection/reset checks. Integrated GUI and exact-head CI results are recorded in the Draft PR, separately from headless tests. No physical-phone or Web-export verification is implied.
