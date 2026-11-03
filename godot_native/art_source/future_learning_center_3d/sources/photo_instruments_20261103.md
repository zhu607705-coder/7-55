# Photo 6: six sources for seven independent bench instruments

## Evidence and uncertainty

The seven native-pixel photo crops, the original equipment view, the manufacturer's DP800 front/side dimension drawing and a DP832 distributor photograph were inspected. The distributor example is a panel reference only: **the photographed instruments are not identified as DP832 or DP831**. Both bottom instruments are a strong DP800-series exterior candidate. All brand markings, tiny labels and screen readouts remain blank. No reference-photo pixels are in these assets or their textures.

Official family dimensions: 239 mm width × 157 mm height × 418 mm chassis depth. The drawing also shows 429.5 mm total depth with front projections. The DP800 candidate implements both envelopes, in real metres, with a long case, impact corners, side carry bars, side perforation recesses, five below-screen softkeys, three coloured channel keys, radial numeric keys, large dial and seven lower binding-post silhouettes. Dark inset closed polygons represent ventilation/connector recesses; they do not describe internal engineering.

Source: https://www.rigol.com/dam/global/downloads/brochures/en/user-manual/dc-powers/DP800_UserGuide_EN.pdf (PDF page 21, printed 1-3).
Comparison image: https://www.tequipment.net/RigolDP832.html

## Source map

- L3 and R3: `photo_instrument_dp800_series_candidate`. Shared family-candidate source, not confirmed model.
- L1: `photo_instrument_l1_dark_signal_candidate`. Estimated 270 × 106 × 310 mm chassis. Dark narrow face, left display, six horizontal softkeys, 3-column keypad, upper-right rotary and one visible lower-right socket silhouette.
- L2: `photo_instrument_l2_light_test_unknown`. Estimated 282 × 112 × 325 mm chassis. Light fascia, near-screen stacked circular controls, right matrix, lower round silhouettes, small lower-left red point.
- C1: `photo_instrument_c1_wide_scope_candidate`. Approximately 342 × 240 × 121 mm finished envelope. Wide glass face, narrow pale control column, paired upper rotaries, vertical keys and lower connection silhouettes. Exact port functions/count are not asserted; the photo's attached probes obscure the lower edge.
- R1: `photo_instrument_r1_dark_rf_candidate`. Estimated 259 × 114 × 292 mm chassis. Wider display proportion than L1, denser 4-column matrix, upper corner rotary, two lower-right socket silhouettes, one yellow ring.
- R2: `photo_instrument_r2_light_test_unknown`. Estimated 271 × 118 × 304 mm chassis. Independent from L2: different screen proportion, tighter matrix, differently spaced circular controls, staggered lower silhouettes and heavier lower lip/right cheek. Similarity is not proof of the same model.

Except DP800 family dimensions, all sizes are photographic relative estimates, not measurements or substituted specifications of a similar product. The five unknown sources are deliberately separate meshes. Their small controls are coarse visual reconstruction at the evidence resolution, not exact functional faceplates. No invisible rear interfaces are invented.

## Geometry, materials and review

Each asset folder in `sources/models/photo_instruments/` contains a Blender 4.3.2 source, three decreasing LOD GLBs and a 32-square authored packed roughness tile. The neutral PBR materials use no image of a real device. Each mesh component is closed and checked for finite coordinates, zero degenerate faces, consistent winding and positive volume. Parts may overlap as assembled manufactured components; they are not one boolean-unioned solid.

Blender coordinates: metres, +Z up, front points -Y; X is centred; bottom is Z=0. The chassis front is Y=0 and its body extends +Y. Controls project towards -Y. Sources contain meshes only, with `assetId`, `photoPosition`, `evidenceStatus`, and `dimensionsUnit` properties.

`review/photo_instruments/build_report.json` records actual triangle counts, measured bounds, GLB hashes and topology checks. `review/photo_instruments/seven_instrument_comparison.png` is a CPU-rendered seven-item comparison: two irregular three-unit stacks and the wide centre instrument. Its seven transforms are in `sources/models/photo_instruments/comparison_instances.json`. It is **not the final electronics-bench layout**. Separate CPU renders show each source.

No old source asset, main scene or other group's file is edited. Source photographs/crops are not included in this deliverable.
