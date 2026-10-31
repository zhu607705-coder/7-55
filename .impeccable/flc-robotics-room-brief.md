# Robotics room furnishing, 2026-10-31

Mode: Experience. Preserve the existing native Godot 4.7.1 room, fine-pixel art,
gray continuous floor, source plan and shared player dimensions.

The user identified the room overview, not the apparatus overlay: the room needs
a large central table full of components and a closer, more varied composition.
Primary focus is the shared assembly island and its playable delivery robot.
Secondary groups are mechanical assembly, electronic testing, printing and
parts storage. Components are independent alpha-backed mounted objects.
No persistent object labels or new control buttons.

The north wall storage and east threshold remain fixed. A four-sided walk loop
and doorway route surround the island. Only this room requests 0.90 camera zoom
(was about 0.73), with the existing bounded follow and uniform viewport scale.
Other rooms and puzzle-controller/save semantics are outside this change.

Impeccable context was already resolved earlier in this session; it is not rerun.
Layout source assessment found generic repeated benches, an undersized center
desk, and an empty-room sampling point inside the new table footprint. A dedicated
post-furnishing pass retains existing IDs instead of renumbering other rooms.
The native CanvasItem scene is not covered by DOM/CSS detectors (scan returns []).
Verify using native spatial/interaction tests and real browser renders at desktop
and the user's 903×862 preview, plus narrow landscape simulated touch.
