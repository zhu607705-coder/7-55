# Stair visual study: source-faithful Blender checkpoint

This is a reproducible **architectural study**, not a game replacement. Review the rendered sample before integrating assets or merging. The current HTML remains unchanged.

## Which scene this addresses

- HTML `media-v2/stairs3d-clean` is the original `stair_b` misaligned-stair puzzle. The snapshot and orthographic camera here reproduce that scene.
- HTML `media-v2/chase-clean` is the older top-down stairwell chase.
- PR #106 is a separate four-fold oblique chase prototype and is not the right-hand HTML clip. Its warm flashlight, tiny blue phone light, controls, collision, and proof model are unchanged by this study.

The source snapshot preserves platforms, treads, mechanism owners, state transforms and navigation records. Perspective puzzle links remain the original model's responsibility. A screen-space overlap is not a new physical passage. No collider or navigation edge is generated here.

## Reproduce

Requires Blender 4.3 (tested 4.3.2, installed distribution).

```
blender --background --factory-startup -t 1 \
  --python tools/stair_visual_study/build_stair_sample.py -- \
  --output /tmp/755-stair-study --variant structure --render
```

Outputs: editable `.blend`, PNG and geometry/camera manifest. This checkpoint uses provisional grey materials. `--variant source` keeps the original abbreviated rail treatment for comparison. Both use the same original camera, projection, world coordinates and mechanism state.

37 checks run against actual Blender transforms before saving: source platform position/height, transformed navigation nodes, and orthographic projection. The verified build generated 139 objects and a 640×360 CPU render. Denoising is disabled because this Blender build lacks OpenImageDenoise. No Godot gameplay tests are claimed for this asset-only checkpoint.

## Provenance and limits

- Base: `godot-version` 913bd512c19c70e842461e0357091dca3635d389
- Original level definitions: `src/tools/chapter4-stair/levels.ts`, blob `9c6de2e210c8dae16683c4bad38e6b027bf9c32e`
- Original engine: `src/tools/chapter4-stair/engine.ts`, blob `c812b72369695f2693b9f68784e600200d140466`
- Snapshot extracted from the existing generated `chapter4-native-source.json`; its full SHA-256 is recorded inside the snapshot.
- Original campus references: `src/assets/rpg/interiors/finale/finale_stairwell.png` and `teaching_building_floor_2.png`.
- The separate web-generated concept is an appearance reference only. Its narrow door landing and incorrectly joined rail are not production geometry.
- Monument Valley reference principles: orthographic spatial relationships, clean layering and a readable architectural composition. No third-party images, characters, level layouts or assets are included. Official references: https://ustwogames.co.uk/our-games/monument-valley/ and https://ustwo.com/blog/monument-valley-out-now/

## Current direction: independent illusion mechanisms

The later user correction supersedes the fixed-building material study. Preserve independent rotating stairs, lifting/sliding blocks, platforms and door. The optional `pixel` variant is a retained historical appearance experiment, not the approved target.

`render_module_inspection.py` renders the same lower stair from right/left/front/back/top/bottom, using Godot world-axis face names and a common orthographic scale. `--single lower` creates the isolated object source pack. `--video --motion-only` renders an 8-second exploded-mechanism motion check. It does not show a playable whole level.

`render_transparent_module.py` exports the lower stair alone as RGBA with Blender film transparency, for art generation. Its 12 treads, 1.34 m width, source pivot and dimensions are unchanged. No background removal or AI geometry replacement is used for this source image.

`check_source_links.gd` runs against the original native model and its generated data in a Godot project. It checks all 432 mechanism/view combinations, both perspective links becoming invalid in nonmatching views, and a 13-action original-model route from B_START to B_EXIT. The six face names are intentionally rejected by the formal game model: inspection cameras do not expand gameplay permissions. The original model's `physical` edges are navigation-graph classifications, not rigid-body collision tests. PR106 chase collisions are separate.

`render_source_alignment.py` is prepared to consume an optional `--trace` JSON emitted by that test, for a whole-rig visual replay. It has not yet been rendered; no whole-level visual acceptance is claimed.

Next user-facing asset must show a substantive art change and genuine RGBA transparency. Whitebox geometry checks are internal evidence, not finished art. No HTML or game runtime is replaced. User preview approval remains required before merge.


## Latest validation checkpoint

- Original source model: 432 exhaustive states, 986 assertions including trace-file write and the 13-action route
- Lower stair six-view metadata: 55 checks, including explicitly refreshed camera matrices and six viewing-axis assertions
- 96-frame mechanism movement: 247 checks, including fixed rotation pivot, pure vertical lift, source geometry and corrected inspection cameras; 8.0 s encoded at 12 fps
- RGBA source image: 1024×1024, alpha bounding box (132,83,891,937), 805991 transparent pixels, 236964 opaque pixels, 5621 partial-alpha edge pixels
- Whole-rig alignment script: 24 oracle/camera checks in a no-render simulation; the full-level movie is intentionally not rendered or accepted yet
- The single-object six views and motion clip are structural evidence. The next user-facing art deliverable comes from the separate material-generation process.

```
# Same model, six object views (not gameplay camera extensions):
blender -b --factory-startup -t 1 --python tools/stair_visual_study/render_module_inspection.py -- --output /tmp/755-lower-views --single lower
# Transparent geometry constraint image for art work:
blender -b --factory-startup -t 1 --python tools/stair_visual_study/render_transparent_module.py -- --output /tmp/755-lower-rgba
# Whole-rig oracle simulation; add --render only when actual frames are needed:
blender -b --factory-startup -t 1 --python tools/stair_visual_study/render_source_alignment.py -- --output /tmp/755-source-alignment --trace tools/stair_visual_study/evidence/source_replay.json
```

## Historical first-asset checkpoint, 2026-10-10

The following records the standalone asset checkpoint published in PR112.
Current native integration is documented in
`godot_native/assets/native/stair_b/README.md`; its independent rule and input
regressions are recorded under `godot_native/tests/evidence/stair_b_assets/`.

`build_refined_lower_stair.py` builds the lower rotating stair in canonical
mechanism state 0. It keeps all 12 original tread positions and dimensions,
1.34 m width and the source pivot `(-2.15, 0.3, 1.35)`. The owner remains an
identity transform; consumers must use the original pivot-relative mechanism
matrix, not rotate the asset about world zero. It is not yet wired into the game.

The new appearance follows the user-reviewed independent lower-stair artwork:
grey terrazzo, three anti-slip lines, dark round rails, joint collars and small
base fixings. The reference is appearance guidance only; it is not a projected
image, texture or collision replacement. The side/underside is a single closed
stepped prism. The original walking surfaces remain unchanged. Added side faces
extend 2 mm cosmetically; no collision objects or navigation edges are generated.

Material portability is explicit: the deterministic authored 128×128 terrazzo
PNG is embedded in the GLB as a standard PBR base-colour texture. Metallic and
roughness values use standard glTF factors. There are no required Blender-only
procedural shader nodes. All stone faces use nearest filtering.

```
blender -b --factory-startup -t 1 \
  --python tools/stair_visual_study/build_refined_lower_stair.py -- \
  --output /tmp/755-refined-lower --render --turntable
```

This produces an editable `.blend`, `lower_rotating_stair.glb`, the authored
texture, 1024² RGBA three-quarter/reverse/bottom views and 32 turntable frames.
The three-quarter direction follows the earlier source constraint view, with
an explicit 5.1 m orthographic framing; it is not a pixel-aligned overlay.
Encode the same-model orbit at 8 fps for a 4-second inspection movie.
The PNGs have genuine transparent backgrounds; the MP4 has an opaque backdrop.
The small `sample_asset/` GLB and PNG are the exact tested export, not caches.

### Verified on the final asset

- Blender: 12 source-tread transform/dimension assertions and identity owner;
  closed-body edge incidence 2 and non-coplanar riser construction assertions
- Godot 4.6.3: 94 checks, 0 failures; 177 imported meshes, 13 textured surfaces,
  0 collision bodies; all 12 original tread world positions and dimensions
  survive the Blender→glTF→Godot coordinate conversion
- All 13 stone surfaces retain the 128×128 PNG base pixels exactly, nearest
  sampling and original roughness. Mipmaps are excluded only from the byte
  comparison of the base image, not from the runtime material
- All 3 PNGs are RGBA with nonempty fully transparent and fully opaque areas;
  three-quarter alpha bbox `(145,86,879,940)` is inside the 1024² frame
- Turntable: 32 actual rendered frames, 480², 8 fps, 4.000 seconds; same model

For the isolated Godot import check, put the GLB, PNG and snapshot in a temporary
Godot project, import the GLB, then run `check_refined_import.gd`. Exact evidence
and hashes are under `evidence/refined_*`.

These checks establish geometry and material-data portability. Godot rendered
appearance, lighting equivalence, live mechanism motion and game integration
were untested at this standalone checkpoint. Its delivered images/movie are Blender renders.
The original formal puzzle, PR106 chase and HTML are unchanged. This Draft PR
required user preview approval before integration. The user subsequently approved starting integration; merging remains subject to integrated-preview approval.
