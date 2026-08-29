# Chapter 4 `7:55` Teaching-Building Asset Contract

This directory contains the formal browser assets for the three-floor Chapter 4 runtime. The files under `artifacts/chapter4-map-assets-20260820/` remain provenance sources; Phaser consumes only the tracked files under this directory.

## Authority Layers

1. `artifacts/chapter4-map-assets-20260820/chapter4-structure-annotations-user-v01.json` is the human-authored source-pixel review record for elevator apertures, air walls, required passages, foreground occlusion, and the bakery opening.
2. `src/data/chapter4-three-floor-maze.layout.json` is the active runtime collision, occlusion, transport, physical-delta, spawn, portal, and target contract.
3. `src/data/chapter4-temporal-maze.topology.json` is the active A1/A2/A3 navigation contract. Its schema 2 route assertions replace the retired A1–A4/B2/B3 topology.
4. `src/assets/rpg/interiors/finale/finale_environment_manifest.json` schema 3 binds formal files, hashes, geometry authorities, atlas trims, pivots, collision bounds, and interaction bounds.

All map coordinates use a top-left source-pixel origin. Rectangles are half-open and use `{x,y,width,height}`.

## Structural Base Plates

The three base files remain byte-for-byte copies of the user-reviewed source images.

| Floor | Formal file | Approved source ID | Size | SHA-256 | Elevator `visibleBounds` | Visible center |
| --- | --- | --- | ---: | --- | --- | --- |
| A1 | `base/a1.png` | `chapter4_a1_base_v01` | `1672×941` | `0df950f034d70b57429239871b5977acbd546b960fa0b89918b3718665f485e3` | `{x:742,y:64,width:61,height:83}` | `(772.5,105.5)` |
| A2 | `base/a2.png` | `chapter4_a2_base_v02` | `1672×941` | `b1d09d66f13e4a0c63a34ff6eff5a3f446c6925061e8cb421f437e5ac6e7fb04` | `{x:758,y:67,width:66,height:69}` | `(791,101.5)` |
| A3 | `base/a3.png` | `chapter4_a3_base_v01` | `1672×941` | `3077b3f6a2f16d97ecee866c516f1fd80341889f7a38779cc892680d5ba0a02e` | `{x:747,y:47,width:81,height:95}` | `(787.5,94.5)` |

The elevator is one controller-owned transport mechanism with three floor-specific visible apertures, stand points, travel zones, and arrival points. A shared `x=836` visual/interaction constant is invalid for these plates.

A1 has two walkable passages behind the north portrait wall: `{x:50,y:47,width:630,height:87}` and `{x:1141,y:51,width:448,height:79}`. They remain collision-free. Matching foreground crops use `foot_behind_baseline`, so the wall covers the player only while the player's foot point is behind it.

## Opaque State Plates

Every state is an opaque `1672×941` RGB plate with `renderMode: opaque_full_plate`. Its structural geometry and base collision profile come from the corresponding A1/A2/A3 base entry. Each manifest entry records five floor registration anchors and its physical delta IDs.

| Plate ID | Formal file | `normalizedFrom` source ID | Normalization | Output SHA-256 | Calibration |
| --- | --- | --- | --- | --- | --- |
| `a1_2245_opening` | `states/a1_2245_opening.png` | `chapter4_a1_2245_opening_v01` | copy source column `1670` to new column `1671` | `722c89e62b8b3efdd83deacf7ca90d9950f387c3b05dd813f24ad02f8551d47e` | `approved_floor_geometry_contract` |
| `a1_1225_bakery` | `states/a1_1225_bakery.png` | `chapter4_a1_1225_bakery_v01` | copy source column `1670` to new column `1671` | `6400a796a87ad3b98247560e1c9f1bd3b94bc408a9584284f661d7a645383f44` | `approved_floor_geometry_contract` |
| `a2_1850_evening` | `states/a2_1850_evening.png` | `chapter4_a2_1850_evening_v01` | byte copy | `52621f2fffb2273991a58f534198f8e5fbbeac26dc5cb3631e72658402830b0f` | `approved_floor_geometry_contract` |
| `a3_1850_reference` | `states/a3_1850_reference.png` | `chapter4_a3_1850_reference_v01` | byte copy | `e577321b077a70428a8819a376f066633fc5875e40431196eedc7160992b0836` | `approved_floor_geometry_contract` |
| `a1_2245_maintenance` | `states/a1_2245_maintenance.png` | `chapter4_a1_2245_maintenance_v01` | byte copy | `8059218cf9e49bbcda71bb34307adae2345b1bbcd2e592f65cd71c8fee27b2a3` | `approved_floor_geometry_contract` |
| `a1_0754_blackout` | `states/a1_0754_blackout.png` | `chapter4_a1_0754_blackout_v01` | byte copy | `47a72533a5312d65fe6961b430a0d08216af0aa18d4deb2ce4d586325ea0eef7` | `approved_floor_geometry_contract` |
| `a2_0754_chase` | `states/a2_0754_chase.png` | `chapter4_a2_0754_chase_v01` | byte copy | `9444e7bc9ac33fb73166134f54e3658d7151a0c476252716df52a9ab05d086dd` | `approved_floor_geometry_contract` |
| `a2_202_final_minute` | `states/a2_202_final_minute.png` | `chapter4_a2_lecture_final_minute_v01` | copy source column `1670` to new column `1671` | `171f05d4762794ef9d96db04a6c05ff24535a817639a336caea19760ef66a5e1` | `approved_floor_geometry_contract` |
| `a1_0755_morning` | `states/a1_0755_morning.png` | `chapter4_a1_0755_morning_v01` | byte copy | `ce7922dc71b68bf100b9952adb385e1cfa685b8bda55b3e9499b0a056b013db7` | `approved_floor_geometry_contract` |

The three narrow sources are normalized by adding one copied right-edge column. The normalizer does not resize, interpolate, color-correct, or redraw them. When all local provenance sources are present, the asset validator decodes source and output pixels, compares every original pixel, and proves that every appended pixel equals source column `1670`. A clean Git checkout intentionally omits the ignored `artifacts/` provenance directory; in that mode the validator checks the tracked output SHA-256, recorded source hash/canvas contract, and equality of output columns `1670` and `1671`. A partial provenance directory is rejected so CI cannot silently mix proof modes.

## Active Transparent Sprite Sheets

Only these five sheets are active for the `7:55` path:

| Manifest ID | Formal file | Explicit frames | Collision rule |
| --- | --- | ---: | --- |
| `chapter4_clock_states` | `sprites/chapter4_clock_states_v01.png` | 9 | Wall fixture; all frames explicitly `none`. |
| `chapter4_power_panel_states` | `sprites/chapter4_power_panel_states_v01.png` | 4 | Wall fixture; all frames explicitly `none`. |
| `chapter4_story_items` | `sprites/chapter4_story_items_v01.png` | 8 cells, one empty | Pickup/drop triggers; all item frames explicitly `none`. |
| `chapter4_room204_furniture` | `sprites/chapter4_a2_room204_furniture_v02.png` | 29 | Each visible object has one explicit low foot box and one placement trigger. |
| `chapter4_room204_residual` | `sprites/chapter4_a2_room204_dark_residual_v02.png` | 12 | All frames explicitly `none`; one shared dark-observation bounds registers the group. |

Each non-empty frame has an explicit source rectangle, Alpha `>=5%` measured trim, source-sheet pivot, collision bounds, and interaction bounds. Furniture and residuals use stable explicit object slots. Runtime code must not derive collisions from Alpha, glow, shadow, reflection, or residual pixels.

`chapter4_a2_dynamic_structures_v01.png` is excluded from the active contract. Its old partitions, guide fragments, and 203 return-door path do not appear in the formal sprite directory, active topology, or layout targets.

## State Physical Deltas

- `a1_midday_queue_rails` adds the visible rope and six low queue-base collisions only while `a1_1225_bakery` is active.
- `a2_room204_disordered_furniture` uses the furniture sheet's explicit foot boxes with one uniform transform inside room 204. Snap hints and residuals remain non-colliding.
- `a3_reference_classroom_furniture` uses six separated foot boxes per row, preserving gaps instead of turning a full row into one wall.
- Light, darkness, projection, glow, residuals, shadows, floor hints, and the 202 threshold remain non-colliding visual or trigger data.

## Rebuild And Validation

```bash
npm run art:finale-environments
npm run chapter4:validate-assets
npm run chapter4:validate-topology
```

`art:finale-environments` is a local authoring command: it requires all approved provenance sources, verifies their hashes, reconstructs the formal state/sprite directories, and then rebuilds the schema 3 manifest. CI runs the asset validator against tracked formal outputs and does not require ignored candidates. The validator rejects unexpected files, partial provenance inputs, candidate paths in the runtime registry, non-RGB plates, non-RGBA sheets, missing frame contracts, changed hashes, and invalid column padding.

## Existing Official Closing Material

The official “灿若星辰” layered material is registered separately at
`src/assets/rpg/cinematics/chapter4-755/canruo-star-lamp/` and consumed by
`src/components/temporal-maze/ChapterFourStarLampClosure.tsx`. The finale
environment contract still does not generate or replace that material.
