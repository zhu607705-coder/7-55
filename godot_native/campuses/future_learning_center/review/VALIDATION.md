# 3F room assembly review · 2026-10-28

![Assembled floor](floor_3_assembled_preview.png)

![Actual native room camera](studio_room.png)

[Actual Godot doorway/camera walkthrough, 14 seconds](room_camera_walkthrough.mp4)

Generated from `data/floor_3.json` by the native review runner, Godot 4.7.1.stable.official.a13da4feb. The full-size PNG is 5325 × 8096; the embedded floor image is a uniformly reduced review copy. The video uses the actual room view, shared player frames, foot-space route and camera code. Its movement is scripted for capture; separate ordinary keyboard and scaled-touch checks were run.

Validation on the working tree based on `80ad46aa4b52bc1076f7d7c675f9e710a1207036`:

- Six room master PNGs: dimensions, true alpha, SHA-256 and outer-wall contour metadata verified.
- 132 focused geometry, room adjacency, doorway, route, complete-footprint and camera checks passed.
- Desktop 1280 × 720: five real engine-input checks passed; no illegal-foot frames.
- Scaled 390 × 844 window: five keyboard/touch checks passed; no illegal-foot frames. The game viewport remains 16:9. This is not a physical-device claim.
- Native source/media sync completed; staged native validation passed prepared inputs, isolated saves, editor asset import/parse, startup, all-script parse and the new room test entrypoint. This is a targeted run, not full release acceptance.

The current result is an empty 3F architectural review with room-focused framing. Transit cores and restroom detail still come from the earlier overview; 2F/4F individual rooms and paired inter-floor transit are not yet delivered. Props and NPCs are intentionally separate future layers. No production story/save/controller was changed.
