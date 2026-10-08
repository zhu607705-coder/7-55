# Native canteen objects and tray choreography

This batch provides the previously unshipped native canteen scene required by the tray animations. It is deliberately larger than the three-file return-pose delta.

## Scope and ownership

- Preserve the supplied 34 PNGs byte-for-byte: an empty floor and 33 separate object images. The manifest places 132 object instances and 15 structure polygons. Two redundant decorations are retained in the source set without duplicate placement.
- Preserve 31 original NPC source-sheet actors. This is not 31 new character animations.
- The regional adapter owns visual ordering, alpha picking, visible-foot collisions and bounded floor routes in the canteen only. A same-tile region patch exposes the southeast doorway while preserving its original interaction target.
- Pickup lasts 360 ms, or 100 ms with reduced motion, and meets the original 24 px held-tray footprint without a size/position jump.
- Return contact lasts 320 ms, or 160 ms in reduced motion. A single tray approaches, rotates flat, compresses the stack from its base and retires. Player overlap gets a temporary front layer and matching alpha surface; neither can survive completion or departure.
- The existing in-world mixer visual and its pure motion helper are required by the regional adapter. The separate full-screen mixer redesign and background are not part of this batch.

World receives only canteen-specific lifecycle, drawing, picking, collision and navigation seams. Existing Room204 objects synchronize before any canteen early return. Main, State, source Chapter3 logic, recipe session, defense model, shared player metrics and the global object picker remain unchanged. The defense game keeps its existing board and solids.

Accepted controller facts remain the only progression authority. Animations cannot grant trays, wages, ingredients or progression. Replacing the state object, leaving the scene and repeated synchronization cannot replay a return. No save-schema change, authored source replacement, generated export or unrelated regional overlay is included.

## Verification

Godot 4.6.3 import/parse passed. 29 focused and shared regression scripts passed with clean logs. Coverage includes geometry/picking 37, story layers 11, pickup continuity 18, return stack 31, cross-scene retirement 9, native queue-floor input 89, original Room204 objects and both tables, source Chapter3 parity, existing mixer/self-drink/defense flows, common floor routes, save imports and guardrails. The structured validation report records the individual results.

Independent review caught an early-return lifecycle issue: already-mounted Room204 tables could survive a switch to the canteen. The new 9-check cross-scene test covers Room204→canteen→Room204→canteen→campus. The old queue-floor trace also assumed the prior wall geometry. Its new exact center boundary is 246.3125 and its artificial blocker now belongs to the active native geometry owner. The initial failed logs were retained; the report uses the subsequent clean pass.

Fresh native desktop input on the remote-base project verified a visible tray click, walking to the return aisle, clicking the original auntie, opening the original Settings save page, pressing Save progress, normal window close and an ordinary same-profile restart. The restarted state retained one returned tray, no carried tray, no wages and zero cash. It emitted no new action and did not replay the return. Chapter prerequisites, the first tray position and the nearby starting point were controlled fixtures, not earned campaign progress.

The base was advanced to the merged fishing commit 0659d72. Its 19 files have no overlap with this batch and remain byte-identical. CI must pass on the final PR head before merge. Passing focused tests does not claim a full manual campaign, successful defense playthrough, physical-phone validation, subjective audio, a 60 fps benchmark or a new executable build.

Controlled native views at 1280×720, 1440×900 and 390×844 were rendered and reviewed. They use the same saved returned-tray state and a fixed 0.65 source zoom. This is layout inspection, not additional earned progress.
