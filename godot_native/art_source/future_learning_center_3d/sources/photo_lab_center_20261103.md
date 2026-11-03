# Photo 3: central laboratory furniture candidates

## Evidence and scope

The original user reference `63e86027f06d235dc7ce8f8d4806b80c.jpg` was visually inspected on 2026-11-03. It remains outside the repository. No photograph pixels, labels, brand names, personal text, screen content or inferred instrument readouts enter these assets.

This is a reconstruction of the main visible furniture, not a complete inventory of the laboratory. The robot, articulated mast, obscured instruments, cables, loose papers, plush objects and uncertain devices are omitted. The shelf is a representative three-bay segment, not a claim about the full wall length. Rear connections, undersides, material composition and exact dimensions cannot be established from this photograph.

## Independent source IDs and estimated dimensions

All figures are approximate metres, inferred from proportions, not measured specifications.

- `photo_lab_center_four_leg_table`: 2.20 × 1.00 × 0.75. Pale thin rectangular top with four separate square charcoal legs. This is not the prior standing desk or capsule table.
- `photo_lab_center_black_task_chair`: approximately 0.65 × 0.63 × 0.91. Broad low curved back, no headrest, arm pads and five twin-caster spokes. Existing `office_chair` has a taller mesh back and headrest; a color-only substitution would misrepresent the silhouette. This limited variant omits concealed adjustment controls and does not claim the photographed upholstery construction.
- `photo_lab_center_open_shelf`: 1.865 × 0.425 × 2.20. Thin steel frame, open shelf levels and representative wood-lined cubbies. Full bay count is not asserted.
- `photo_lab_center_plain_storage_box`: 0.36 × 0.27 × 0.222. One reusable unmarked closed box with lid. Three placements reuse this single source.
- `photo_lab_center_black_transit_case`: approximately 0.64 × 0.47 × 0.428. Tall dark body, broad top lid, latches and carry grip. The existing workshop flat red/black case has a different height and silhouette. No interior, hardware maker or protective rating is asserted.

## Reuse and composition

`sources/models/photo_lab_center/composition.json` records every instance in Blender Z-up metres, including independent ID, source path/hash, position, Euler rotation, scale and material overrides. Existing `photo_desktop` monitor, keyboard and mouse sources are reused without edits. Their imported review instances receive black neutral material variants. The original monitor's back envelope and stand are reused as a provisional approximation; no manufacturer-specific ports are invented. Keyboard and mouse are included as generic workstation context, not exact recovery of mostly obscured devices in photo 3.

The saved composition is a review file only. It is not a merged production asset. It is saved before adding camera, floor or lighting. The rendered PNG is a CPU Cycles review from approximately the photograph's front side, with the monitor back toward the camera. It does not prove browser or Godot integration.

## Materials and validation

A deterministic, locally synthesized 128 × 128 wood-grain PNG is packed into the relevant blend source and embedded into the table GLBs. Other surfaces use metallic-roughness PBR factors. No original photo texture or external texture dependency is required.

Each asset has one editable `.blend` and three `lod0_source.glb` through `lod2_source.glb` files. Source builds contain mesh objects only, no stage, cameras or lights. Mesh validation checks finite coordinates, nonzero face area, two faces per edge, consistent winding, positive signed volume and no unapplied modifiers. Intersecting components at joints remain separate closed solids, not one Boolean-unioned volume. Three LOD triangle counts strictly decrease.

`review/photo_lab_center/build_report.json` contains per-asset/per-LOD bounds, material names, mesh counts, triangles, checks and SHA256. `source_freeze.json` records frozen source hashes. Plain/Draco downstream validation is a separate pipeline step, not claimed here.

## Reproduction

From the repository root, with Blender 4.3.2:

    blender -b --factory-startup -t 4 --python godot_native/art_source/future_learning_center_3d/scripts/build_photo_lab_center.py

Optional `-- --skip-render` builds sources only. `-- --render-only` renders existing sources. `-- --composition-only` rebuilds the review layout from unchanged single sources.

No existing model, master scene, Godot file, collision, gameplay or UI was changed. No commit or push was performed.
