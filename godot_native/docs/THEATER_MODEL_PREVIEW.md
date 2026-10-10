# Modeled funhouse theater: review slice

This replaces the native spotlight mini-game presentation only. It does not replace the theater exploration map or modify the original browser implementation.

## Scene

- Independent Node3D followspot: hanging yoke, tilt pivot, steel housing, cooling rings, lens rim and barn doors
- Shadow-casting light aimed at the original light-creature position; restrained translucent dust cone, no bloom
- Three layers of pleated curtain geometry, rigging, staggered floorboards, exposed stage apron and footlights
- Independent upholstered walking-chair meshes
- Original light creature, punctuation, shadow, eyes, mouth exit, three-act titles and source rules retained

## Lens and input

A fixed S-glass function with alternating local magnification affects only the scene SubViewport. The CPU pointer transform is the same sampling function as the fragment shader. Labels, captions and buttons stay outside the lens. A Newton inverse projects source gameplay positions for tests and presentation. No time-varying camera wobble is introduced. Displacement exceeds 80 authored pixels and local horizontal scale varies by over 2× while the center keeps its horizontal scale. Opaque header/footer/dialog slabs are removed; text has a small glyph shadow. Steering stops within 3 physical display pixels, and the touch marker retains a constant display radius. Edge targets and display-space distances are tested at 1280×720, 1024×768, 390×844 and 844×390.

The source 960 × 540 logical frame, model bounds, 50ms ticks, hazard paths, collection rules and terminal proof remain unchanged. Pointer ownership records device/type/touch index; cancellation, pause, focus loss and reuse clear ownership. No presentation node writes save state.

## Run

Import the normal native project and run `tests/preview_theater.tscn` with F6. This scene is a real playable three-act review fixture. It replays submitted proof through the original model, then lets the reviewer continue or retry. It never writes story saves. F9 saves an actual viewport PNG under `user://theater_review`. The review fixture also offers deterministic three-act capture with R. The editable baked model is `scenes/theater/funhouse_stage_editable.scn`; regenerate it with `tests/export_theater_model.gd`.

The real game continues to mount the same `c3_spotlight.gd` through Main's original flow.

## Early verification

- `test_theater_lens.gd`: 2,559 checks; inverse roundtrips, positive Jacobian, CPU/shader coefficients, model anchors, logical-to-physical scaling, real viewport event routing, device ownership, pause/reentry/reset and full 1,600-tick proof validation
- `test_theater_show_ui.gd`: 30 checks; all three acts played through inverse-mapped pointer events, actual Main/State acceptance and explicit final acknowledgment
- Original `c3_spotlight_model.gd` unchanged from base 913bd512
- `test_theater_preview_storage.gd`: optional measurement failure never interrupts play; default files use writable user data, not the source project
- `test_theater_stage_model.gd`: 75 checks; real independent lamp hierarchy, ray-projected floor anchors, source texture, shadow budget, batched geometry and pose-update isolation
- `test_chapter3.gd`: 72 source controller checks
- Actual Godot Compatibility preview, physical mouse drag, 705 rendered replay frames across all three acts, and clean isolated portable-package import/startup verified
- Cloud llvmpipe software renderer at 1152×648: 480-frame sample mean31.8fps, median35fps, p10 28.8fps, 174 frame draw calls. This is a software-renderer observation, not a desktop/mobile performance guarantee
- Actual device mobile and Windows/Mac execution remain unverified. This is a draft review slice, not approved final art or release
- See `THEATER_OBJECT_AUDIT.md` for source-by-source status and remaining planar objects; do not call this complete per-object reconstruction
