# Mobile exploration

Compact exploration uses the available screen area instead of shrinking a 960×540 world into a short portrait strip. The world keeps its original coordinates, uniform zoom, collision geometry and progression authority. The camera derives its bounds from the displayed viewport and follows the player. Desktop split view retains its existing layout.

Portrait places the expandable inventory below the scene. Compact landscape places the open inventory in a side tray. The scene title, mode control, interaction control and movement pad use physical-pixel dimensions. Nearby text says “交互”; keyboard Space still invokes the same interaction.

A finger on the movement pad moves the player. Dragging empty scene space pans within a bounded distance; movement recenters the view. A tap can inspect a visible object. An inventory gesture remains owned by its slot, and a drop uses the displayed camera transform. Small invisible tolerance applies only to visible object pixels, excludes HUD-covered areas, and does not search for a compatible hidden answer. Resize, focus loss, modal ownership and scene changes cancel transient gestures.

Authored scene presentations, narrative owners and minigames retain their original aspect contracts. When they release ownership, the exploration layout returns without writing story or save facts. Phone applications keep their portrait composition.

The library's completed dialogue queues return keyboard focus to the visible world after the overlay closes. The handoff cannot steal focus from a new modal, a hidden scene or another active/pending presentation. The entrance-record action appears next to the record card and uses the existing controller label and availability.

Acceptance distinguishes routed engine tests, seeded graphical fixtures and continuous player-earned cloud play. Real 390 px earned play reentered the library, used the interaction control to photograph the bag, adjusted brightness through the normal Control Center and matched the old photograph. This is cloud mouse/keyboard evidence; physical Android/iPhone touch and full mobile chapter coverage remain unverified.

Actor rendering keeps the mirrored frame over the same physical foot and shadow. Godot treats a negative destination width as a texture flip while preserving its position; adding a frame-width offset displaced left-facing art from its exact pixel picker. The correction removes only that offset. The native-render fixture `tests/capture_actor_flip_rendering.gd` covers idle and all eight walk frames in both directions at 390/430/1440 widths: 328 checks pass, and reinstating the original line produces 137 failures. It requires an actual rendering driver and is deliberately separate from the headless test aggregate.

Validation of this increment: the portrait/Library runtime completed one clean 144-stage headless aggregate and a fresh exported native-only campaign. The subsequent one-line actor rendering correction is recorded as a separate runtime revision, with affected world/picking/layout tests and a rebuilt export. Neither automated campaign nor seeded rendering replaces the outstanding player-earned walkthrough or physical-device testing.
