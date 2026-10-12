# Changping library: independent exterior RGBA object

The original approved campus painting, existing 41-point route, ten route canopy objects, and accepted four-way student remain unchanged. This adds one connected library exterior object. It does not add an interior, entrance, lake route, or general campus navigation.

## Registration and rendering

- Original PNG: 1225 × 1284, RGBA, full transparent padding retained
- Source reference: approved 950 × 1656 campus image, crop [505, 687, 630, 818)
- Uniform scale: 0.11036930895608213
- Explicit source-space origin: [501.6515664578408, 683.7275776496026]
- Central triangular glass is opaque roof; the southeast exterior recess is transparent
- One imported production Texture2D is shared by at most eight total depth passes
- Two manually reviewed face IDs select separate contact-depth rows; no whole-image bottommost-alpha mask
- RGB uses mipmaps. Rendering and selection use original bilinear alpha at LOD0
- Alpha cutoff is 0.04; alpha at or above 0.97 becomes solid in the shader. Original PNG bytes are unchanged

The fit prioritizes actual visible ground contacts. The source image and generated detail are not pixel-identical. No ground-repair image is installed: native arrival and recess review did not show a clear old-wall double image or bright ground patch that justified repainting.

## Collision and selection

The installer validates this exact library-owned legacy group before replacing its source silhouette, raster guard, and two old depth slices. It disables only the exact library body underlay. The separate original ground shadow, neighboring objects, trees, lake, and paths remain.

The original south GroundFootprint0 is unchanged. Only the library-owned east GroundFootprint1 is corrected to a narrow inward band along the actual concave facade contact. The same two footprints feed native physics and the existing 3.2-pixel navigation blocker expansion. A collision-free recess test pose does not enable off-route travel. The opaque roof remains non-walkable.

Selection samples actual alpha, so exterior recess and padded points cannot select the old broad polygon. Information, close, return-to-gate, repeat entry, and release use the existing campus flow.

## Reproduce

Run each command sequentially from the repository root with Godot 4.6.3 available:

```sh
node scripts/check-buct-changping-library.mjs godot_native
bash scripts/test-buct-changping-library.sh godot_native import
bash scripts/test-buct-changping-library.sh godot_native headless
bash scripts/test-buct-changping-library.sh godot_native student
# Requires a working display and OpenGL compatibility driver:
bash scripts/test-buct-changping-library.sh godot_native proof
```

The runner writes temporary data and captures under `.buct-library-qa` by default. Set `BUCT_LIBRARY_QA_DIR` to another checkout-local directory if needed. Do not commit runtime caches or proof captures. Keep the explicit `library_body.png.import` even when broad ignore rules exclude import files. Production loads the imported PNG resource, not PNG bytes through FileAccess. Existing export presets must retain their `*.bin` and `*.json` include filters for semantic data.

## Verified results

- 1,016 native library assertions passed, including radius-3 four-way wall stops, recess clearance, corrected navigation blockers, alpha selection, information/return, repeated entry, and descendant release
- 86 accepted-student assertions passed; the unchanged three-POI route completed with zero boundary violations
- Actual circle contact versus exact sloped-segment support differed by at most 0.083 source pixels
- 17 automated OpenGL assertions passed using the same imported production texture
- Five depth poses had zero alpha-support difference from the whole-PNG reference; maximum channel difference was one 8-bit level
- All four real-student before/after contact probes showed the intended depth change

A short real mouse/keyboard check also passed: glass selection, Esc close, an unobstructed transparent-recess click, movement and release, return to entry, and re-entry at the original south-gate spawn. A second transparent coordinate overlapped the screen-space landmark Button, so its ordinary Button action was excluded from alpha-picking evidence.

The initial unshipped manual logger emitted an ObjectDB warning during Alt+F4 shutdown; that warning is retained. A separate run of the normal project, without any manual SceneTree driver, completed chooser → Changping → chooser → Changping → normal quit with exit 0 and no ERROR, ObjectDB, or RID warning. Only the known llvmpipe VSync warning remained. Production bytes were unchanged between runs. This clean comparison does not establish the exact helper leak cause.

See `BUCT_CHANGPING_LIBRARY_VALIDATION.json` for the bounded record. No physical mobile GPU, complete-story, or new exported-package test is claimed.
