# Photo 6 electronics workstation sources, 2026-11-03

## Evidence and scope
The original 2048 × 1151 photograph `17bbf66f7667bc31e4894c87d6856da5.jpg` was actually viewed. Visible: thick light wood worktops, paired grey drawers, square steel legs, tall grey square-hole back panels, shelves, green cutting mats, instrument shells with screens and controls, small black storage bins, monitor and tools. Photographic proportions are estimates in metres, not a measurement survey.

Six separate sources are provided. Instrument shells reproduce only broad visible silhouettes, blank dark screens and neutral controls. They do not identify a brand, model, electrical capability, wiring, readable display, or exact control inventory. The repeated horizontal instrument is a neutral approximation of several visibly different original devices. Drawer interiors, rear mechanisms, obscured wires, clutter, chairs and unidentified robotic apparatus are omitted.

## Reuse
`composition.json` beside the sources is the placement manifest. Eight existing workshop square-hole panels retain their original geometry and unit scale. Only the combination applies grey enamel instead of black sheet steel; original files are untouched. Existing blue driver rack, red flat cases and desktop monitor are reused. Different positions and repetitions do not create new source models. Joint seams in the tiled back panels are a reuse compromise, not claimed seams from the photograph.

## Materials and exports
Every new source has one Blender 4.3.2 master and three progressively simpler GLB files. The masters contain meshes only, with no review camera, light, stage or floor. All bevels are applied. Small packed 128 × 128 synthetic wood/grid images and metallic-roughness factors supply PBR inputs. The original photograph, personal information, labels, branding and text are never baked into assets.

| Source ID | LOD0 / LOD1 / LOD2 triangles |
|---|---|
| photo_electronics_back_shelf_frame | 2068 / 1188 / 484 |
| photo_electronics_drawer_bench | 5788 / 3308 / 1348 |
| photo_electronics_green_cutting_mat | 188 / 108 / 44 |
| photo_electronics_open_bin | 1316 / 756 / 220 |
| photo_electronics_tall_instrument_shell | 4696 / 2696 / 908 |
| photo_electronics_wide_instrument_shell | 3412 / 1972 / 608 |

## Review and tests
Run from repository root:

    blender -b --factory-startup -t 4 --python godot_native/art_source/future_learning_center_3d/scripts/build_photo_electronics_bench.py

Use `--skip-render` for geometry/export validation and `--render-only` to regenerate CPU views from saved sources. `review/photo_electronics/build_report.json` records triangle counts, bounds, SHA256 and zero-defect mesh tests (finite vertices, degenerate faces, nonmanifold edges, winding, positive volume, unapplied modifiers). `source_freeze.json` records all final source hashes. Six single-asset CPU Cycles PNGs and a photo-oriented two-bench combination are review images only. They are not web, runtime, Godot collision or performance acceptance. No main scene or old source was changed, and no commit/push was performed by this builder.
