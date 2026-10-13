# Approved BUCT student in the formal full maps

The approved four-direction artwork is attached to the real `CampusVisitor` in both `campuses/buct` (Chaoyang) and `campuses/buct_haidian` (Haidian). This is not the tree-only character pilot.

- Source assets, registration profile, and renderer are copied unchanged from the accepted student branch, tree `2e5399a5d730c0df99c33abc1817a1d27f01695b` (PR #121).
- Integration base is PR #124 head `7f8d2532bb4d9d2b90e147f0b47b0eb73147d653`.
- Right, left, and down have 8 effective walk frames each. Up has 6. Every direction has its own idle frame.
- The visual child uses a uniform 18-source-pixel target height. It registers each frame to the unchanged physical foot point. The original `CharacterBody2D`, radius-3 feet collider, speed 88, guide speed 106, native sorting, input actions, paving restrictions, and route navigation retain their original ownership.
- The visual advances from displacement measured after `move_and_slide()`. Paused and blocked movement therefore renders idle. The per-frame render path never reconfigures or resets the visual.
- The old procedural body and default decorative foot ring are removed from the visitor drawing. Existing selective under-canopy location aids remain unchanged.
- Desktop receives no new touch-direction buttons. Existing touch-to-walk, adaptive map layout, and keyboard input stay unchanged.
- In walking view, landmark buttons move clear of the real registered student animation bounds and remain inside the usable map area. Placement starts from the original anchor every frame; the full-cycle artwork rectangle prevents frame-edge jitter. Overview buttons and their original click callbacks remain unchanged.
- No indoor scenes, room assets, story scripts, state fields, or progression changes are included.

## Verification

Run `node godot_native/tools/test_buct.mjs` from the repository root. The existing Linux-only runner creates a fresh, explicitly isolated save directory for every Godot process and checks its safety guards before any entry fixture writes. It includes the actual visitor attachment, four-direction movement, idle/blocked animation, foot registration, and repeated gate-return checks in both maps. Do not launch fixture scripts directly against your everyday Godot user-data directory.

`tests/test_buct_student_pin_layout.gd` checks real-scene label clearance, compact viewports, clamping, repeated updates, and overview behavior.

`tests/capture_buct_student_maps.gd` is a reproducible real-scene capture driver. It defaults to Haidian; set `BUCT_STUDENT_CAPTURE_CAMPUS=buct` for the separately authored Chaoyang routes. It uses the existing movement actions and does not supply another player controller. Use a normal renderer for visual evidence. `BUCT_STUDENT_CAPTURE_DIR` optionally writes frames into an explicit caller-selected directory.

The immutable source profile uses 0.65 body heights per cycle for its small character pilot. Each formal-map visitor clones that profile at setup and calibrates its visual stride to 2.6 body heights per cycle. At an 18px target height this is 46.8 source pixels per cycle, or about 1.88 cycles/second at the unchanged 88px/s movement speed (2.26 at guide speed 106). Animation still advances by actual post-collision displacement. This is map-scale visual calibration, not a biomechanically exact no-slip model. Visual review is required in addition to the movement assertions.

Changping is maintained as a separate full-map source prototype, not a formal repository campus entry. It is not added to this branch.
