# Shared lounge and adjacent pantry correction

The latest two user photographs were viewed before this change. They show a
shared room: an elongated charcoal table and mixed chairs, orange lounge seats,
a window-side high counter, and an adjacent pale-wood pantry with a white top,
green vertical tiles, open upper shelves, sink and appliances. The refrigerator
is outside these two frames. Its wood surround and adjacency to the pantry use
the existing `photo_pantry_composition.json` evidence, not a new inferred object.

This replaces the previous dense standing-table / two small-table arrangement
in the independent building viewer. It is not a Godot gameplay or measured
architecture change. The preserved room is 7.694 by 5.825 model metres. Neither
its source outline, walls, doorway nor neighbouring rooms have been widened.
Instead the furniture is arranged around one shared table and a clear loop.
All furniture dimensions and placement remain estimates.

The same existing GLB resources form a 23-part composition: continuous pantry
and fridge/surround, capsule table, six wood chairs, table planter, three equal-size orange
single seats and one loose cushion, a round side table, window bar and two high chairs. It does not
claim an exact inventory from partially obscured photographs. The fridge remains
on the right of the service wall. No source asset is scaled or regenerated. The user subsequently confirmed that
the refrigerator is beside the microwave. The microwave is at the fridge-side
end of the counter; the sink and white appliance are farther away. Both doors
face the service aisle. Their body-edge gap is about 0.82 model metres, occupied
by the existing wood-side / dispenser-recess transition, not another appliance.
This estimated gap is not a measured site dimension.

The loaded composition atomically replaces furniture within the original pantry
bounds. Walls, floor, ceiling and windows are not suppressed. The full and web
building variants are both covered, including web-only empty chair/static
anchors. Collision changes occur only after every required model and LOD loads.
Failure leaves the original scene geometry and colliders intact. The original vending machine and its collider are explicitly excluded from furniture removal. The workshop,
40 adjustable desks, floor navigation and other floors are unchanged.

The actual-GLB Node tests cover both building variants, every configured part,
room bounds, the preserved non-furniture colliders, complete circulation via
ordinary collision steps, solid-body blocking and atomic asset failure. The
viewer VM integration passed 204 checks for building.glb and separately 205
checks for building.web.glb. These are separate totals, not one failed check.

Browser tests were updated for the new composition, ordinary pantry walk entry,
repeat inspection and return, full circulation, desktop/mobile screenshots and
failure/reload. Local Chromium could not launch because the executor denies
its singleton socket. No restriction was bypassed. Browser visual acceptance
and screenshots must come from the updated CI workflow at the final SHA.
A CPU composition render is authoring QA only, not a browser screenshot.

## Retained contents and corrected chair interpretation

The user clarified that the three orange shell chairs in lounge photo 2 are
the same size. The historical `photo_lounge_orange_double` and its corrected
wide variant came from that same photograph, not a separately evidenced sofa.
Their width was an authoring error: the corrected wide chair is 1.529 m versus
0.974 m for the single. This layout therefore uses three rigid instances of
`lounge_single_corrected`, with no instance scaling, and retains one cushion.
The older wide source files remain available but are not a fourth scene seat.
Absolute dimensions remain estimates; different image widths can still result
from camera distance, orientation and occlusion.

The original vending machine stays at its authored location. Its 29 source
meshes and original collision rectangle are preserved, including on atomic
asset failure. Existing product shapes are only schematic; no new brand or
product inventory has been inferred. The chair group is shifted along the
left wall to clear the machine, without changing room or wall dimensions.
The full loop and approaches to all three chairs and vending machine are
checked against actual geometry and continuous collision steps.
