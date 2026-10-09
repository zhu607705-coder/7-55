# World HUD and subtitle safe layout

The source map, actor feet, collisions, zoom range and inverse pointer transform remain unchanged. `world_overlay_layout.gd` accepts screen extent and display scale, never map zoom. It measures the existing Fusion Pixel Chinese font and applies the saved `native.settings.text_scale`.

## Reproduced defects

- Exploration clamped its camera against the full 960×540 surface. At zoom 0.85, the canteen's southeast mat (source y=935) appeared at y=534.9, underneath the footer. With a clear rectangle ending at y=492, safe camera framing puts it at y=486.9.
- Chapter 3 dialogue used a fixed 136-source-pixel desktop card and compensated the font inside a small 16:9 portrait film. The card therefore occupied a large part of the film.
- Identity-stamp completion could publish feedback while its activity still owned the surface. The root notification survived the return to the world and then overlapped the separate Library dialogue.

## Ownership

- PR97's authored-camera callback runs first. Victory continues using its complete 960×540 source shot; ordinary exploration cannot reframe it.
- Ordinary camera clamping uses the HUD-safe region at map edges; interior follow remains centered on the original player/pan target. Mobile movement controls and ordinary dialogue reserve their actual screen bounds. The visible frame may show extra empty background at an edge so a map-edge object remains usable.
- Screen text uses one compact typography scale: approximately 15px body on narrow surfaces, gradually reaching 18px on a wide desktop, multiplied by the user's saved text-size setting. Camera zoom does not change it. Title and speaker roles retain their small hierarchy. Long or enlarged text uses a bounded scroll container; the complete text remains available without moving the touch controls into the header. Scroll-wheel input, including either scroll boundary, belongs to the text rather than world zoom.
- C3 dialogue retains its session, timing and input locks. Portrait films put its existing view in the host's screen-space gap below the film. Short landscape films use a side letterbox; desktop films use a bounded left-hand caption to keep the southeast exit visible. Ordinary exploration retains its world-view UI and clears the movement controls. Authored films omit idle navigation bars, but keep a real system feedback message at the top.
- A notification crossing from an activity to visible world UI transfers its exact text and remaining life to the existing world feedback owner. It is not replayed. Library feedback stacks above the measured dialogue when their screen regions would overlap. Both share a budget that reserves at least one feedback line, so enlarged Library dialogue cannot consume its entire space.
- Closing the story restores the ordinary footer; a hidden world also hides an externally placed C3 subtitle. No controller facts, rewards, session proof, source artwork or collision data are modified.

## Verification

New focused scripts: `test_world_overlay_layout.gd` (pure geometry/type metrics), `test_world_overlay_integration.gd` (real Main, three viewports, zoom, notice handoff and Library stacking).

Required regression: narrative readability, portrait narrative contract, mobile world feedback, canteen victory camera, portrait exploration, object picking and existing compact HUD tests. Run each in an isolated `/tmp` save profile. GUI review must include desktop, portrait and mobile landscape at .45/.85/1.6 zoom, ordinary movement after dialogue close, and live resize during the full-room victory.

This document describes implementation and required checks. Test results are recorded only after execution; a static assertion is not visual acceptance or a physically tested phone.

### Local checks, 2026-10-09

Completed first-pass native checks:

- Pure layout: 118 checks; narrative readability: 20
- Real Main integration: 86; canteen victory camera: 1,140
- Portrait narrative: 1,261; mobile world feedback: 832
- Library story sequences: 718; portrait exploration: 334
- World object picking: 53; compact overlay: 190; native surface modes: 424
- All listed checks reported zero failures. Each script ran in its own process and isolated `/tmp` save profile
- Native GUI capture produced 15 desktop/portrait/mobile-landscape snapshots with zero fixture assertions. All 15 were visually inspected. Ordinary exploration kept the southeast doorway above the HUD at .45/.85/1.6 zoom; the Library feedback and dialogue were separate
- GUI review identified three details and the candidate was corrected: landscape victory dialogue now uses a side letterbox or the left 65% of the room; short captions use measured overflow rather than stale/subpixel scroll ranges; portrait Library dialogue sits immediately below the film
- Final focused rerun after those corrections: narrative readability 30; canteen victory camera 1,630; real Main overlay integration 86; Library story sequences 718; portrait narrative 1,261. All reported zero failures. Victory tests include 960×720 medium desktop, actual door geometry, the source arrival point, 3× user text scaling, live resize, owner cancellation/restoration and untouched source timing
- Final native GUI capture and visual review: eight images covering victory and Library feedback/dialogue at 1440×900, 960×720, 390×844 and 844×390. Door and arrival area remain clear; short subtitles have no false scrollbar; Library feedback and dialogue do not overlap. Capture reported zero failures using Godot 4.6.3, OpenGL Compatibility/llvmpipe
- These captures are explicit presentation fixtures that use the production Main/renderers and original story text. They do not claim a manually earned campaign/stamp replay. The existing victory test separately passes the controller-validated defense proof through real Main

The initial fresh Main run was killed after 3.7 seconds with only the engine banner (observed peak RSS 394,644 KiB). Kernel logs were inaccessible and cgroup counters unavailable, so the cause was not established. After other tasks released resources, one authorized retry passed all 86 Main checks in 11.37 seconds (observed peak RSS 602,680 KiB); the later regressions and GUI capture also completed. The earlier kill is not evidence that Main generally cannot run. No physical phone has been tested.

### Full-suite regression follow-up

The first full native CI for PR102 exposed four cases outside the focused set. The follow-up keeps their behavioral assertions:

- A short landscape inventory viewport could put the bicycle under the header because the first implementation centered the player in the entire control-subtracted strip. The camera now preserves interior player-centered follow and applies the safe rectangle only at the map boundary. The real item drag/drop success, cancellation, wrong-item and payment tests remain unchanged.
- The proximity-triggered canteen discovery sequence also owns a canonical camera. Its first camera sample now bypasses exploration framing, alongside the existing narrative owner. The canonical-source-camera assertion remains unchanged.
- Kayak paddle rectangles now share the measured feedback boundary for both drawing and hit testing. Original idle size/position is retained; taller text lifts the controls. Enlarged-text touch-owner checks cover that shifted position.
- The queue regression keeps the original source-world approach, wall near-miss and exact corrected foot center. It projects those same points through the live camera into root input instead of replaying obsolete screen pixels. Collision, six-pixel correction, unchanged planner, continuous movement, story-state and arrival assertions remain intact.

The combined candidate starts with merged PR100 (`37c795a7702942b053f772fecfd272227b425a39`). Its object/depth, pickup and native-layout files are preserved byte-for-byte; HUD changes are disjoint. The combined local no-Main subset passed: pure layout 119, kayak boundary/target ownership 31, foot occlusion 10,011, pickup continuity 176 and kayak fixed-step guard 61 checks. The first bicycle Main fixture printed its 1440×900 viewport, then the environment killed the process even with `--single-threaded-scene`; no assertion failure was emitted and the cause is unconfirmed. No Main retry was attempted. Bicycle, queue, waiting and other combined Main coverage remain for the follow-up head’s full remote CI before merge. The previous GUI evidence belongs to the initial head; it is not presented as a new combined-build capture.
