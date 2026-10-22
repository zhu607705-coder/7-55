# Kenney-inspired dorm interaction experiment

Independent entry: open `scenes/kenney_visual_slice.tscn` and run the current scene (F6). CLI: `godot --path godot_native res://scenes/kenney_visual_slice.tscn`. Run source sync/import first for a Git checkout. This builds on modular dorm candidate #157 at `799034f`, itself dependent on selected-UI #156. It does not replace the main entry, production dorm, save schema or story gates. Starting movement here is a practice-only affordance, not a bypass of the real story's movement unlock.

## What was borrowed

- [Kenney City Builder](https://github.com/KenneyNL/Starter-Kit-City-Builder/tree/4535092b740b378b700efd9df9e27a631815b84a): object roots and object data distinct from the presentation. Existing #157 18 furniture roots, 20 loose props, original character and canonical 0755 paper are reused. No Kenney low-poly art, building economy, save code or camera script was imported.
- [Kenney Match-3](https://github.com/KenneyNL/Starter-Kit-Match-3/tree/4ddb3d2a50cbf247c79cafe9e7884d7d8f99c012): localized focus → action → feedback → return cycle. Here this becomes small corner marks, a reversible lamp state, a short brightness pulse and a small paper annotation. Unlike the template, pixel art is not squashed or elastically stretched. Prior tweens are cancelled before a new one; focus loss clears movement.
- No racing, FPS or match-three gameplay replaces the campus narrative.

The references' code is MIT; Kenney graphics/audio are CC0, and their included Lilita fonts have SIL OFL notices. This experiment copies none of those files. Existing game assets and bundled UI fonts retain their existing licenses. Concept references are not a new CC0 grant for 7:55 assets.

## Compare and operate

Arrow keys move; Space opens/closes nearby paper or toggles the desk lamp. Clicking floor walks directly toward it with collision (no pathfinder); clicking an object approaches its stand point, then clicking again inspects. Tool buttons do not take keyboard focus. The movement reminder hides after first movement and stays hidden through retry. "重来" resets only ephemeral trial state. "反馈" disables/enables candidate focus/pulse for an A/B comparison of the same modular scene, NOT a screenshot comparison with the original production dorm. All source UI role/font values are reused without editing the locked theme. This experiment does not instantiate or replace the five production surfaces.

The 480 switch uses an 854×480 nearest-filtered world SubViewport and a zoom-adjusted camera. Window-resolution text remains outside that viewport. 540 is the default. Camera display coordinates are rounded in render-pixel space; the smooth logical camera remains continuous. World field of view is preserved vertically (the rounded 854 width has a tiny horizontal aspect difference). Portrait windows narrow the world viewport down to a 2:3 minimum aspect instead of shrinking the whole landscape scene to a tiny strip; this changes horizontal visibility, not world scale or UI font roles. Window fitting may be fractional, and moving objects are not all quantized. This is **not a no-shimmer guarantee** or accepted global pixel pipeline. No global resolution change occurs.

## Validation and limits

`tests/test_kenney_visual_slice.gd` exercises repeated paper/lamp actions, focus loss, modal-to-navigation interruption, actual collision-world displacement, viewport fitting, resolution return, camera-grid math, reduced motion, and unchanged `State.d`. Dedicated CI captures the actual Godot framebuffer for baseline, paper/lamp feedback, 480 comparison and compact layout. Capture harness positions the actor deliberately; it is not a full campaign walkthrough. No physical mobile/joystick acceptance. The existing generated dorm candidate's provisional sink, simplified props and non-identical extraction remain #157 limitations, not newly verified real-room geometry.
