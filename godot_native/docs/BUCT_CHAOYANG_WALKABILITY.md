# Chaoyang outdoor west-road expansion

The original 29-stop South Gate → Main Building → Library guide and its three landmark records are unchanged. Free walking now also reaches two connected northbound branches:

| Branch | Connection to the original route | Added northern endpoint, in source pixels |
|---|---|---|
| West sports-side lane | Existing west lane at (422, 748) | Paved sports-side junction at (416, 436) |
| Library-west avenue | Existing rear-garden connection at (613, 711) | Visible library-west avenue at (612, 416) |

The names describe the approved illustration. They are not verified real entrance names or surveyed navigation instructions. Both endpoints are reachable from the original (744, 979) spawn through the existing road network. They are free-walk destinations, not new guide stops or story gates.

## Source-space geometry

- 35 narrow, manually traced road-segment polygons are added to the original 22. Their nominal width is 18 source pixels. This is a polygon count, not a road count or campus coverage percentage
- The polygons follow the visible paved centre of each lane. Short longitudinal overlaps preserve continuous clearance through bends
- The existing three-pixel foot circle and native speed remain unchanged. Native navigation still requires the centre and four cardinal three-pixel offsets to lie inside the union of paving. Building footprints retain their 3.2-pixel navigation clearance
- `exploration_sectors` attributes every new polygon to an ordered source-space segment. It records the few foliage-obscured joins separately. These are conservative gameplay inferences between visible paving, not additional visible or surveyed paths
- The planting strip around y≈590 is **not** an east-west shortcut. The courts, running field, central lawn, building interiors, roofs and unreviewed northern/eastern roads remain closed
- The old route and landmark data, accepted L-enabled building-layer manifest and registered scene, source map PNG and student movement script are hash-locked by the source regression

## Limited roadside depth

Two small original-image crown groups are added where a walking student can pass beneath the road-edge foliage: the yellow-green west-lane curb crown, and a western crown group beside the library avenue. Each retains exact source-image UV coordinates. No image was generated or repainted.

Only the inferred 1.5-pixel trunk foot is a native collision object. The crown is not a solid wall. Shared inferred foot-depth anchors are explicitly recorded; these groups do not constitute complete individual-tree extraction or a campus tree census. The original eight crown groups and the existing library's genuine-alpha body and physics are unchanged.

## Checks

Run the dependency-free source guard:

```sh
node godot_native/tests/verify_buct_chaoyang_walkability_source.mjs
```

It checks protected source hashes, original guide records, both branches, all newly added allowed grid cells, endpoint reachability with edge sampling, and representative blocked roofs, courts, planting and unreviewed-road probes. The source model is deliberately conservative. It is not presented as a native physics pass.

`tests/test_buct_chaoyang_walkability.gd` separately instantiates the real campus, uses Godot AStar with corner cutting disabled, samples every returned edge, and walks the actual shared student from the old spawn to both northern endpoints at the original speed. It checks held-input curb blocking, tiny native trunk collisions, behind/in-front canopy poses, reset and owned-input cleanup. Endpoint arrival allows at most six source pixels: the four-pixel navigation grid and unchanged 2.5-pixel waypoint stop rule do not promise exact subpixel endpoint placement. The existing playable regression still completes the unchanged three-landmark guide. The focused `tools/test_buct.mjs` runner includes both the source and native fixtures.

Native pixel-depth review is a separate graphics stage. Source geometry, native movement and rendered evidence must not be conflated. Validation results are recorded separately after those stages finish.

## Remaining scope

This expands one connected outdoor sector. It does not make the entire campus traversable. Northern and eastern road sectors, courts/field access and any uncertain campus boundary need their own source review and connected movement checks. Interior development is outside this change.

## Measured validation (2026-10-12)

- Source guards: 1,320 road/geometry assertions, 31 shared-student assertions and 271 unchanged Haidian-source assertions passed
- Native Godot 4.6.3: new road checks **41/41**, with **1,322 actual physics samples** and no paving violation; the original guide **115/115**, reaching all three landmarks in 741 ticks; source/building layers **284/284**
- Actual llvmpipe OpenGL: all four new crown poses passed. Both overlays change **zero empty-background pixels**. The two behind-crown probes hide 58 and 79 student pixels respectively; both front poses hide zero
- Continuous graphics capture: west sports-side lane out and back, existing southern garden connection, then library-west avenue. Four arrivals, **763 physics ticks**, **254 JPEG frames**, no paving violation and no sampled teleport/overspeed. At 60 fixed physics ticks per second this represents **12.717 seconds of simulation**; recording took **14.695 seconds of wall time**. The initial placement is only at the already-open west-lane junction
- The original capture and its raw report are retained. A stale reset caption in that first capture was corrected in the capture fixture only, followed by one final recording in a separate folder. No production logic, source artwork, road geometry or physics changed for that correction
- Full repository CI, physical mobile hardware and campus-wide traversability are not claimed by these focused results

See `BUCT_CHAOYANG_WALKABILITY_VALIDATION.json` for machine-readable results, including the initial test-fixture failures and final passes. Assertion totals include dense geometry samples; they are not counts of independent user journeys.

## Local integration on the accepted L building and PR #126

The same road data is now merged onto the formal three-campus entry base and the independently accepted genuine-alpha west-inner L building. The controller merge preserves L alpha selection, its neutral information card, the three source-derived foot contacts, and four exact-source leaf fragments. The road contribution to that controller is still only the original overview status sentence. Both Changping and road source checks remain wired in the focused runner.

The accepted L fragments contain 2,300 nonzero-alpha pixels in total. Testing those exact source-pixel centres against both new road crown polygons finds **zero duplicate ownership**. Neither the L fragments nor the two road crown groups were changed.

The merged local scene passes **37 integration assertions**: the actual student walks from the original south-gate spawn through the west-road out/back journey, original southern connector and library-west endpoint in **1,152 physics ticks**, with no repositioning, off-paving step or overspeed. The neutral L card preserves the three-landmark count. After a separate explicit reset, the original guide reaches all three landmarks in **743 ticks** without leaving valid ground. The existing road regression also passes **41 assertions** and **1,322 actual walking samples**. Source guards pass 1,322 road, 271 Haidian, 37 shared-student and 60 Changping assertions.

This local merge was not published. The original video remains pre-L evidence; no new combined-scene video or GPU claim is made. Entry/State and unrelated campus sources are unchanged, but these focused checks do not replace full CI or a whole-game save/resume test. See `BUCT_ROADS_L_INTEGRATION_VALIDATION.json`.
