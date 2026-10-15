# Compact exploration: tap the floor

In compact exploration, a tap on visible empty floor requests a walking route around the current collision geometry. The marker denotes the player's collision-foot center. The player keeps the existing movement speed, foot shape, collision checks and camera behavior; reaching the marker never activates an object or advances the story.

The bounded visibility graph uses only the current visible world rectangle and existing obstacles. It allows at most192 corners and4096 edge checks. Each walking step checks current collision state again. A blocked request shows a small crossed marker. It does not teleport, reveal unseen targets, or enlarge furniture passages.

Manual movement, a new destination, camera/viewport changes, focus loss, modal ownership, inventory dragging and scene changes cancel the route. Furniture dragging in room204 takes ownership before overlapping target picking. Object clicks, item drops, keyboard movement, kayak controls and cinematics retain their existing dispatch paths.

Verification is in `test_mobile_floor_route.gd`, `test_mobile_floor_route_orientations.gd`, `test_mobile_floor_room204_drag.gd` and the existing portrait-control suite. The room204 regression checks press, held motion and genuine release, including one authoritative placement per correct drop. Automated input and desktop-rendered narrow windows do not establish physical-phone acceptance.
