# Photo-derived workshop tool group · 2026-11-03

## Reference and scope

The worker inspected the actual pixels of the two user-supplied photographs before modeling. Reference identities: `src_ref_750145fd053312e5110b3b2e85b0f9f3` (wide view of two green tool cabinets) and `src_ref_e93491da63b7c6cd6a712c836ff473a8` (close view of the blue-handled drivers, red cases and small vise).

Six independent Blender 4.3.2 assets are authored under `sources/models/photo_workshop/`. These are reusable sources, not a change to the main scene or the older furniture models. Blender coordinates use Z up; GLB export uses glTF Y up. Every dimension below is an estimate from photograph proportions, not a survey or manufacturer specification.

| Asset ID | Visible evidence retained | Approximate complete bounds, Blender XYZ (m) |
|---|---|---|
| `photo_workshop_green_tool_cart` | Green cabinet, five shallow black drawer fronts plus one deep lower front, long silver pulls, caster wheels, black work mat, left accessory tray and right push handle | 1.013 × 0.508 × 0.904 |
| `photo_workshop_square_hole_board` | Black folded sheet, square perforation pattern, side stiffeners and silver fasteners. Reconstructed 24 × 18 hole density; 432 genuine through-holes at every LOD | 0.788 × 0.031 × 0.645 |
| `photo_workshop_blue_driver_rack` | Black open rack, blue metal grips, silver collars and exposed shafts. Eight representative drivers retain the visible cluster; full inventory and exact tip types are not asserted | 0.314 × 0.101 × 0.296 |
| `photo_workshop_red_flat_case` | Shallow rounded red shells, lid split, diagonal raised ribs, small catches and rear hinges. A separate source can be instanced into the photographed stack | 0.420 × 0.214 × 0.055 |
| `photo_workshop_black_red_case` | Black shallow case with lid relief and two prominent red catches. A true opening remains inside its small carry loop | 0.331 × 0.243 × 0.071 |
| `photo_workshop_small_vise` | Small dark cast body, two metal jaws, visible spindle, cross handle and mounting lugs | 0.160 × 0.241 × 0.128 |

The source cabinet is deliberately closed. The partly open lower drawer in the wide photo is not modeled with invented contents or slide hardware. Both cabinets in the review arrangement use the same independent cabinet source. The board is a separate asset so an empty cabinet can also be used.

## Source and material contracts

- Each asset folder contains `<assetId>.blend`, `lod0_source.glb`, `lod1_source.glb`, and `lod2_source.glb`.
- Each LOD is independently authored. Edge tessellation, circular sections and tiny hardware reduce with distance; the board's holes remain real openings.
- All source files contain asset meshes and their materials only. No review floor, lights or camera are saved into individual sources.
- Materials use metallic/roughness PBR factors. The cart's black mat adds one locally generated 128 × 128 repeating normal tile, `synthetic_rubber_tile.png`, packed into Blender. No reference-image pixels, readable labels, brands, identifying text, or private imagery are used.
- Opaque tool cases do not claim unseen contents. Rear lab equipment, transparent goggles, small bit trays and hanging circular tools are omitted because this batch is the cabinet-and-tools group, not an invented inventory of the room.

## Validation and review

`review/photo_workshop/build_report.json` records all 18 exports with asset ID, level, triangle count, Blender XYZ bounds and size, mesh-part count, SHA-256 and checks. Every mesh must have finite coordinates, no zero-area faces, exactly two face uses per edge, consistent edge winding, positive signed volume and no unapplied modifiers. Triangle counts must strictly decrease across all three LODs.

Review sources and renders are isolated under `review/photo_workshop/`. The two-cart assembly updates Blender's dependency graph before reading imported object transforms. CPU Cycles renders show an assembled view and key single-object geometry. These views are studio checks, not a measured reconstruction of room placement.

Draco packaging and independent decoded-output validation are coordinated separately by the parent task. This source worker does not modify runtime assets, commit, push, install software or alter repository access.

Additional source-only checks in `review/photo_workshop/source_review_qa.json` reopen all six `.blend` files, confirm that their scenes contain only asset meshes and that image datablocks are packed. A ray test passes through the center of each of the 432 board holes, while a control ray hits the solid margin. The separate pipeline worker also validates every source/plain/Draco board LOD using five rays per hole and steel checks between holes; that independent result is under `review/photo_expansion/photo_workshop_validation.json`.
