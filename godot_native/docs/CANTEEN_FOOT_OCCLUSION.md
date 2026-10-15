# Canteen ground-plane occlusion

This is a renderer-only correction. It does not change source artwork, actor scales, object positions, collision polygons, interaction targets, door predicates, story facts or inventory.

## Reproduced causes

- Seventy-four split props placed their upper portion at depth 1, even when that portion was a horizontal tabletop or an upright cabinet.
- A second full-image player-only layer at alpha 0.52, plus alpha 0.58 front pieces, tried to compensate. That produced see-through overlap and did not apply to NPCs.
- Floor mats were sorted at the bottom of their painted rectangle like upright furniture.
- A whole prop's sibling order was used for all its pieces. Source-depth values in the same 40-unit z bucket could therefore interleave incorrectly after a prop was split.

The player's position is a sprite-center-style anchor: the collision foot bottom is anchor.y + 39. NPC entries already use a bottom anchor and matching foot-body bottom. These are converted to the same world ground coordinate; NPCs must not receive another +39 offset.

## Narrow rendering contract

- Floor mats stay on the ground layer.
- Upright cabinets stay opaque at their existing floor-contact depth.
- The four service windows keep their painted back wall behind staff and their counter front in front of staff. The shorter fifth window is a front-only fixture.
- Table and bench top surfaces follow their existing longitudinal footprint. The original asset row at the wood-surface/front-face boundary is registered once per asset: table 540, left bench 550, right bench 482, relative to the alpha crop. Legs and front faces keep the existing floor-contact depth.
- Surface pieces are created only at overlapping actors' ground planes and the contact planes of objects resting on the surface. Their boundaries are integer source rows, shared by adjacent pieces. There is no regular grid of tiny strips, whole-prop alpha fade, new asset, stretch or duplicate paint.
- All pieces use siblings in the existing source-coordinate space, retaining exact depth order inside the existing small z range. Interaction picking uses those same ordered pieces. The original prop still owns its collision and target identity.
- Table plants, resting collectible trays, the return tray stack and cabinet signs inherit their supporting surface's contact depth, so correcting furniture cannot hide objects resting on it. Every collectible tray has an actual alpha-picking assertion.
- The moving pickup tray starts at the resting tray's support depth and interpolates to the held tray's ground plane. Both pickup and held trays partition overlapping tabletops. The pickup presentation and defense rendering reuse the same partition function. The defense model and all progression logic are unchanged.

## Reproduction fixture

`test_canteen_foot_occlusion.gd` creates an explicitly declared Chapter 3 fixture. It is not a complete earned chapter run.

First-row empty table and adjacent aisles, in source actor-anchor coordinates:

| Approach | Actor anchor | Foot-bottom y |
|---|---:|---:|
| Rear | (675, 273) | 312 |
| Front | (675, 390) | 429 |
| Left middle | (616, 325) | 364 |
| Right middle | (743, 325) | 364 |
| Left before front plane | (616, 360) | 399 |
| Left after front plane | (616, 370) | 409 |

The test verifies these approach points are walkable. It also checks exact original-image partitioning, multiple simultaneous NPC/player planes, all opaque surfaces, floor mats, supported props, sibling order, bounded node count, unchanged story/inventory, and portrait/landscape captures. `CANTEEN_OCCLUSION_CAPTURE_DIR` and `CANTEEN_OCCLUSION_REPORT` opt into screenshots and a JSON report. Performance data are measured on the current host and are not device-wide guarantees.

## Shared-renderer audit boundary

The older `chapter3_world_layers.gd.canteen_occlusion` fade belongs to the prior painted-map path. The independent canteen no longer depends on it. The theater and other rooms have their own foreground logic; this change does not claim their occlusion has been audited or fixed.

Two shared-path audit leads are deliberately left unchanged:

1. `World._draw_actor_pass` compares `player.y` with generic foreground `baselineY/sortY`; only its old canteen branch converts to `PlayerMetrics.foot_rect(player).end.y`. Each other scene must be checked against the coordinate convention of its authored baseline before changing this. A possible 39-pixel offset is a code-level hypothesis, not a verified visual defect for every room.
2. The guard is painted in `World._draw_tail_pass`, after foreground furniture. That lacks actor-foot interleaving and warrants a scene-specific foreground screenshot. It is not changed here because the Chapter 4 chase is a separate active workstream.

## Verification

Final source is based on the actual #97/#98 merge, `1c7e200b9727f216a4df563405957f0c480b70d0`.

- Offline data audit: all 132 original object positions, scales, collision footprints, target IDs and asset SHA-256 declarations unchanged; all structure polygons unchanged
- Offline exact-row partition checks: 315 cases across the 63 longitudinal table/bench objects
- Complete 478-script parse passed; focused final native tests: foot occlusion 10,011, objects 37, lifecycle 9, door integration 79, return stack 38, pickup continuity 176, pickup cinematic 122, all zero failures
- Graphical fixture (before the final moving-tray handover refinement): 10,019 checks, zero failures; includes all 56 authored tray slots tested via actual alpha picking in batches, original story/inventory retained, all eight saved viewport screenshots inspected
- Idle frames cause zero furniture geometry rebuilds; a moving actor invalidates only intersecting props; repeated warmed walking creates no new surface nodes
- A real before/after screenshot review caught trays hidden in an intermediate implementation. Support planes and all-slot alpha-picking assertions fix this; intermediate captures are superseded
- Baseline and final wide replays: identical 36 legal input frames at 20 simulation FPS, y=325→391→325, zero failures. These are short fixture demonstrations, not full earned chapter runs
- Final portrait screenshot and geometry checks passed. An optional extra portrait replay could not be saved when host storage reached zero available bytes; it is not counted as passed. The capture helper now exits cleanly on an image/report write failure
- Independent review caught a moving-tray handover omission after the static GUI pass. Final headless verification covers four legal side/rear/front pickup approaches × normal/reduced motion × seven time samples: 176 continuity checks pass, including real furniture alpha overlap and paint order; the 10,011-check foot suite passes again. No extra graphical replay is claimed for this final handover refinement
- Full Main/campaign was not repeated in this constrained local window; aggregate CI must be checked separately before merge

### Local performance diagnostics

The same baseline/final wide fixture, 31 NPCs, original 12 resting tray targets, same camera and movement:

| Metric | Baseline | Final |
|---|---:|---:|
| Scene nodes | 775 | 757 |
| Draw calls | 55–57 | 66–69 |
| Explicit configure call median | 7.71 ms | 9.12 ms |
| World process mean | 3.77 ms | 3.68 ms |
| World process median | 2.57 ms | 3.05 ms |

The final stress fixture retains 319 pooled pieces, 262 active pieces and 814 total nodes after visiting all 56 tray slots; 120 configuration calls take 1.05–1.21 seconds on the test host. Ordinary same-route node count is 18 below baseline after removing redundant wrapper nodes. Additional draw calls preserve opaque original pixels and supported tray/plant ordering. Cached geometry and affected-object invalidation avoid the initial every-frame rebuild cost. These are short debug measurements on the current software renderer, not device-wide frame-rate guarantees.

Re-run `measure_occlusion_cost.gd` for configuration timings or `capture_canteen_foot_occlusion.gd` with `CANTEEN_OCCLUSION_REPLAY_DIR` for per-frame movement, timing, node and draw-call JSON. Use a writable output path with enough free space.
