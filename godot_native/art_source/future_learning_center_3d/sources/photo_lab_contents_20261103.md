# Photo 3: visible laboratory contents, evidence-limited reconstruction

Original photograph and the identification report were visually read on 2026-11-03. Private photographs and crops are not inputs to the generator, textures, or delivery package. All dimensions below are estimates in metres, not manufacturer data or measurements. The unsuccessful Lenovo T24i-20, Walker and Cruzr comparisons are not used as model identity or scale.

## New independent sources

- `lab_closed_thin_device`: approximately 0.35 × 0.24 × 0.018. Closed lower chassis, lid seam and rear hinge. Two differently posed/scaled instances represent D01 and D02; the second could be a different thin device. No invented ports or brand.
- `lab_stepped_monitor`: nominal 0.57-wide landscape panel with separate lower rear housing, central mounting boss, support and broad base. The rear horizontal inset is unprinted. Three placements represent D03–D05. Rear display uses an explicitly recorded nonuniform scale to approximate the visible portrait silhouette; it is not a confirmed same-model monitor or a claim that an actual stand rotates this way. Screen content is blank.
- `lab_open_pc_chassis`: roughly 0.21 × 0.42 × 0.45. Separate top/bottom panels, corner rails, far panel, mainboard tray, plain board, slot brackets and four short cable bundles. The positive-X side is open and the interior is visible. Generic internal parts provide only visible structure, not an inventory, verified circuit design or exact component layout.
- `lab_unknown_white_case`: rounded 0.32 × 0.29 × 0.525 body, dark plinth, blank label silhouettes and loose cable. D12 function/model remains unknown. It is not labeled an air purifier or dehumidifier.
- `lab_desktop_small_items`: a removable cluster of separately named solids: dark instrument carton with cardboard edge, plain papers, small white stand, long white strip, cuboid adapter, blank pale-blue sign and three loose cables. The strip recesses do not assert a socket standard. No unseen instrument is modeled inside the carton.
- `lab_hard_transport_case`: deep dark case, divided lid, handle, latches, reinforcing ribs and corner protection. Two instances sit horizontal and vertical with staggered positions. No protection rating or manufacturer asserted.
- `lab_window_unknown_enclosure`: rounded light envelope with dark frame and smoked front. It has no invented nozzle, printer bed or spool mechanism. The interior is intentionally unspecified. This is an envelope proxy for D06, not an identified printer.

## Composition and remaining uncertainty

Existing table, chair, open shelves, two plain storage boxes, keyboard and mouse sources are loaded without source edits. A second scaled table stands in for the rear work surface. It is review context, not a surveyed window-sill reconstruction. The arrangement is deliberately staggered. Multi-screen overlaps, thin-device heights, desktop clutter, under-table equipment and horizontal/vertical cases preserve the main photo layers.

D07 stacked circular objects, D08 partial robot and D09 mechanical mast are omitted rather than replaced with an incorrect complete product. D11 ambiguous desk support/cabinet and unreadable labels remain unmodeled. Occluded furnishings, exact shelf inventory, walls and windows are not reconstructed. Further close-ups and one measured reference length would resolve these uncertainties. The composition is more complete than the prior furniture-only candidate but is not a complete inventory or measured digital twin.

`composition.json` records metres, Blender Z-up, every source hash, position, Euler rotation, scale and material overrides. `supportSurfaces` and each `supportSurfaceId` identify the intended ground, table or shelf contact. Cable segments can contact their supporting surface; rails, hinges, handles and layered panels intentionally intersect at their joints. Those local part intersections are not claims of Boolean-unioned watertight manufacturing geometry.

## Files and validation

Every new asset has one editable Blender 4.3.2 source and three separately exported GLBs. Each part is checked for finite vertices, nonzero face area, closed edge incidence, consistent winding, positive volume and applied modifiers. LOD triangle counts strictly decrease. The source files contain no review cameras or lighting. A tiny, mathematically generated packed PNG modulates selected PBR materials; it contains no photograph pixels, text, trademarks, device identifiers or external dependency.

`review/photo_lab_contents/build_report.json` records source export checks. `lab_contents_composition.blend` is an assembly review, not a production master scene. The two PNGs are Cycles CPU views. No Godot/runtime performance acceptance is claimed. Independent validator results remain separate.

Rebuild with Blender 4.3.2: `blender -b --factory-startup -t 4 --python scripts/build_photo_lab_contents.py`. Use `-- --skip-render` for sources or `-- --composition-only` to reassemble unchanged sources and render both views. No existing 48 sources, main scene, runtime code or repository permission was changed; no push or paid installation occurred.
