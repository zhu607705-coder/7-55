# Stage-driven underwater fish visibility

Base: `godot-version` at `93c21feeaa9c8699b40c952c1184a9fd5d49d472` (PR81).
This is a read-only visual correction for the large blue fish below the float.
No PNG, lake plate, input control, hit area, chart, model, reward or save owner changes.

## Visual ownership

`LakeFishingMotion.depth_sample()` reads the original model:

- Casting retains the original depth of 0.16 field heights below the float's surface row. It is a submerged silhouette, slightly clearer than the previous permanent shadow.
- The original count-in after a valid cast smoothly reveals and raises the fish during the bite stage.
- Only `perfect`, `great` and `good` note judgments advance retrieval depth. A judged miss contributes zero; it cannot fake a nearly landed fish.
- During the fight, a loaded fish thrust can briefly dive and a held pull can draw it upward. These offsets read the existing beat/tension presentation; they do not create progress.
- Successful retrieval progressively reduces the water veil and raises the body toward the surface. Surface-contact ripples follow that body near the end.
- A failed encounter retreats to its deep silhouette. A completed successful chart reaches the shallow state.

The target ring, float, main fishing line endpoints, angler grips and tension-driven rod retain their existing anchors. As the large fish approaches the surface, its mouth projection smoothly converges to the original horizontal fish target while the small fish silhouette fades out. A short tension-aware submerged leader connects the actual float to that mouth, so the near-surface state reads as one fish. On narrow screens the trailing tail can swim beyond the edge; the tracked head and a readable body section remain inside without distorting the artwork. The secondary gold polyline previously drawn independently above the large fish while holding is removed, so it cannot read as an unconnected second rod or line.

Very short landscape fields (height below 420 pixels) uniformly scale the large fish down and cap its shallow rise below the beat panel. This keeps the near-surface silhouette clear of both the beat and tension panels. Desktop and portrait retain their previous uniform fish scales. A short time-based interpolation smooths rendered depth, projection and opacity after each discrete judgment. Semantic judgment counts remain exact. The leader shares the rendered breathing-adjusted mouth coordinate. Pause freezes any in-flight interpolation; retry/new attempts clear it. Reduced motion retains semantic stage/progress visibility but removes beat-driven depth excursions.

## Verification

The focused depth suite covers all four charts, successful/mixed/missed judgments, actual tension and held/released states, failed completion, read-only model sampling, pause after held-input neutralization, retry, and desktop/portrait/landscape geometry. The existing fishing motion, view, controls, pointer, focus return, audio, terminal/failure, model, Chapter3, Qizhen branch and reload tests are retained.

The native visual preview uses the checked-in `rhythm_locker_key.json` input trace, validated through the unchanged model. Before and after render identical model times and inputs from casting through seven successful retrievals. It is a compressed source-input replay for visual comparison, not a new manual campaign completion, real-time FPS measurement, phone-hardware test, subjective audio test, exported build or earned-save proof.

The source diff requires independent review and the exact PR-head native CI result before merge.
