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
