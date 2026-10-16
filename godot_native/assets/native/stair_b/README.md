# Original stair_b: refined native asset integration

Ten source-space GLBs replace only the original stair_b presentation meshes.
The chapter4 source data, graph, three allowed puzzle views, sequence and proof
validation are unchanged. Other three stair levels retain their original assets.
This is an integration preview; HTML is not replaced.

## Ownership and motion

All assets retain original Godot world coordinates and identity asset roots.
The renderer parents rotating/lifting/sliding assets below the existing owner,
then applies `T(pivot) * R_y(angle) * T(-pivot)` or the source axis displacement.
It does not recenter and does not add the source position a second time.

The previous renderer interpolated the origin of its pivot-offset matrix,
which made the physical rotation pivot drift during the tween. The new renderer
computes the continuous pivot matrix. A rider is transformed from its source
local node on every frame. Rotation wraps use the requested signed quarter-turn;
linear wraps interpolate between the two legal source endpoints and never
overshoot to a nonexistent state. Endpoints snap to the unchanged source model.

Fixed platforms and door stay outside mechanism ownership. The door base keeps
the original position and Y=pi rotation. Its frame stays fixed; its leaf and
attached handle/fittings rotate around the explicit hinge. Source door dimensions
are unchanged. Cosmetic meshes introduce no physical colliders or graph edges.

## Materials and rebuild

The GLBs embed authored 128-square nearest-filtered PNGs and standard glTF PBR
factors. No Blender-only shader is required. `provenance.json` locks each file.
Builders live at `tools/stair_visual_study/`:

- `build_refined_lower_stair.py` recreates the approved first object
- `build_refined_upper_stair.py` recreates the 11-step upper stair
- `build_moving_platforms.py` recreates lift and slide, using a saved refined
  stair `.blend` as its material template (`--template`)
- `door_platform_assets/scripts/build_door_platforms.py` recreates fixed slabs,
  separate railing subtrees and the native-sized hinged school door

Run Blender single-threaded with `--output` targeting an empty build directory.
The authoring folder's older whitebox/fixed-building variants remain history.
Generated preview PNGs, `.blend` sources and import caches are not runtime inputs.

## Preview and acceptance

Open `tests/preview_stair_b_assets.tscn` in the native project to run this level.
It uses the actual production renderer and buttons, but an isolated activity
session; it does not produce a complete chapter proof or modify a formal save.
Missing any of the ten GLBs activates the complete original geometry fallback,
rather than a partly empty mixed asset scene.

Current native import and independent rule/live tests are recorded separately.
Graph correctness is not a rigid-body collision test. Player sprites retain
real depth testing; new railing visibility still requires actual rendered QA.
The source door jamb/lintel exterior overlap can leave a tiny dark edge seam in
Blender; exact source bounds are preserved for this first integrated sample.
Do not describe the assets or this isolated fixture as full campaign acceptance.

## Rendered integration checkpoint (2026-10-10)

Actual Godot 4.6.3 frames confirmed source character depth, both rotating stairs,
lift/slide and the independent door in the original three-view scene. Automated
input traversed the lower seam, carried the actor on moving pieces, traversed the
upper seam and reached stair_c. This is not a manual or formal-story completion.
The original background wall and planters are intentionally still visible.

Actual-renderer enumeration of all 432 states found 10 local connectivity
topologies, 27 undirected local paths and no branched or fixed-state full route.
The puzzle remains one chain reconnected in stages. 1,248 illegal moves were
rejected. Separate input tests checked disconnected clicks, busy-state actions,
repeated resets, ride motion, perspective changes and bidirectional crossing.

Visual review caught the first hinged door opening toward the waiting player;
the corrected direction is positive local Y (toward world +Z). Its swept volume
and the actual exit animation are verified separately from graph correctness.

Final door revision: the axis is at base local `(-.62, 0, -.072)`, with
compensating child offsets. The negative opening direction is forbidden.
Independent actual-GLB sweeps found no positive-angle intersection with 217
obstacle configurations; the live renderer contract passed 2,715 checks with
141 actual opening/traversal samples and zero door/actor sweep hits. The CI
contract also samples both source jambs and lintel through 91 opening angles.

A separate actual Godot final-state capture confirmed the corrected door opening
and handoff into stair_c. The delivered clip identifies this short repeated
segment; its earlier mechanism section is the original native automated capture.

## Low-noise native stone finish

The original embedded GLB stone albedo is retained as authoring history. The
native adapter replaces only materials named `Campus grey terrazzo` with the
shared `terrazzo_clean_pixel_albedo.png`: 32 surfaces, four colours, about 15%
clustered aggregate and no per-pixel random base grain. All other surfaces,
lighting, UVs, PBR values, nearest+mipmap filtering and geometry are unchanged.
Each material is duplicated before applying the shared texture; the source
PackedScene and its reusable materials are not modified in place. The tiny
shared texture is a required member of the same atomic asset set.

Rebuild the deterministic texture with Python (Pillow and NumPy installed):
`python3 tools/stair_visual_study/generate_clean_terrazzo.py --output /tmp/755-clean-stone`.
The resulting PNG bytes match this committed asset in the validated environment.

`tests/preview_stair_b_presentation.tscn` is an automatic pure-scene presentation:
no text, buttons, validation labels or navigation dots are displayed. It uses
the real source mechanism actions, door traversal and dismantle/reveal timing.
Its optional `capture_directory` is empty by default, so normal preview writes
no image files. The separate interactive preview and production touch controls
remain available. The yellow wall's original mild texture is unchanged.

The final clean-material/presentation regression passed 7,388 checks. It also
rebuilds the next level after `_process` and fires `frame_pre_draw`, verifying
navigation dots are hidden before the first new-level draw. Actual captures of
that first frame and subsequent frames confirm no marker flash. The final native
capture records all 15 actions and the unchanged dismantle/reveal transition,
reaching stair_c in 19.504 seconds of recorded frames. The test exits with an
ObjectDB cleanup warning; no script or parse failure was reported.
