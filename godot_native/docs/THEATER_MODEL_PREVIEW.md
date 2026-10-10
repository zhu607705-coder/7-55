# Modeled funhouse theater: review slice

This replaces the native spotlight mini-game presentation only. It does not replace the theater exploration map or modify the original browser implementation.

## Scene

- Independent Node3D followspot: hanging yoke, tilt pivot, steel housing, cooling rings, lens rim and barn doors
- Shadow-casting light aimed at the original light-creature position; restrained translucent dust cone, no bloom
- Three layers of pleated curtain geometry, rigging, staggered floorboards, exposed stage apron and footlights
- Independent upholstered walking-chair meshes
- Original light creature, punctuation, shadow, eyes, mouth exit, three-act titles and source rules retained

## Lens and input

A static asymmetric funhouse polynomial affects only the scene SubViewport. The CPU pointer transform is the same polynomial as the fragment shader. Labels, captions and buttons stay outside the lens. A Newton inverse projects source gameplay positions for tests and presentation. No time-varying camera wobble is introduced.

The source 960 × 540 logical frame, model bounds, 50ms ticks, hazard paths, collection rules and terminal proof remain unchanged. Pointer ownership records device/type/touch index; cancellation, pause, focus loss and reuse clear ownership. No presentation node writes save state.

## Run

Import the normal native project and run `tests/preview_theater.tscn` with F6. This scene is a real playable three-act review fixture. It replays submitted proof through the original model, then lets the reviewer continue or retry. It never writes story saves. F9 saves an actual viewport PNG to the sibling evidence directory.

The real game continues to mount the same `c3_spotlight.gd` through Main's original flow.

## Early verification

- `test_theater_lens.gd`: 2,497 checks; inverse roundtrips, positive Jacobian, CPU/shader coefficients, model anchors, logical-to-physical scaling, real viewport event routing, device ownership, pause/reentry/reset and full 1,600-tick proof validation
- `test_theater_show_ui.gd`: 30 checks; all three acts played through inverse-mapped pointer events, actual Main/State acceptance and explicit final acknowledgment
- Original `c3_spotlight_model.gd` unchanged from base 913bd512
- GUI visual review and rendering/performance acceptance are ongoing. This is a draft review slice, not an approved final visual or release
