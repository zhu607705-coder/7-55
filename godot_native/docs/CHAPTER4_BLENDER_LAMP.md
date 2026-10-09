# Item 54: approved Blender lamp in the native closure

The production `ChapterFourStarLampClosure` now selects the approved low-glow
Blender LOD1 mesh. This is the game consumer, not a separate demonstration. The
original five-layer PNG renderer remains available with the source-only
`lampPresentation: "layered"` configuration for rollback.

## Asset and presentation boundary

- `assets/native/canruo/canruo_star_lamp_lowglow_LOD1.glb` is byte-identical to the
  reviewed low-glow delivery: SHA-256
  `f6b48857f10ab41f9026bf9cc2541a60e052b0273b68c98c9cb5626bfc0c7bfe`
- The runtime loads 14 real meshes and 30,318 triangles. The GLB is self-contained
  and has no external image textures. Original layered PNGs are not pasted onto
  planes to impersonate geometry
- The low-angle path is the reviewed camera reconstruction: position
  `(0.5, 0.5, 7.9)` to `(0.5, 1.7, 6.4)`, looking at `(0, 6.12, 0)` to
  `(0, 7.12, 0)`, with the 29.839371711-degree vertical field of view at 16:9
- A narrow viewport widens only the camera field of view when needed to keep the
  cage visible. It does not stretch the lamp. The final summary uses separate
  image and text regions, with scrolling for limited-height controls
- LED emission peaks at 1.8 and core emission at 0.85. Materials are duplicated
  per instance; imported resources are never modified. One neutral unshadowed
  directional key reveals the metal. Measured, redundant local point-light
  passes and MSAA are removed while full render resolution is retained. The
  closed opaque mesh uses runtime backface culling; the GLB's default
  double-sided materials remain unchanged on disk
  Compatibility rendering uses no post-process Glow, so exact Blender Cycles
  bloom or point-light spill is not claimed
- 640 seeded, depth-positioned stars use one two-triangle instanced mesh. The
  original 6,320-point CPU drawing path is hidden while the Blender view is active
- The isolated SubViewport accepts no input. It renders once per changed
  geometry/light frame. Caption-only and reveal-composite changes do not dirty
  the 3D scene. Static final views do not continuously redraw the 3D world

## Story, input, and lifecycle remain original

The presentation consumes the existing `chapter4_lamp_sequence.gd`; it has no
independent clock, process loop, action dispatch, save, reward, or sound owner.
No controller, `main.gd`, question option, or final message was changed.

Both Zhu questions still have to save through the original controller. Original
entry/dissolve and saved-confirmation timing is retained. Normal playback lasts
5,800 ms; the already-issued reduced-motion session lasts 3,600 ms and keeps the
camera at its final pose. Playback completion only opens the original explicit
acknowledgement. There is no early skip or alternate proof authority.

Focus loss freezes the owning clock and camera. Disposal stops rendering. Saved
answers retain the original reentry and replay behavior. The existing controller
continues rejecting stale sessions, shortened playback, client-selected duration,
and premature/repeated acknowledgement.

## Validation status

The initial local implementation passed all ten targeted scripts:

- New Blender integration: 171 checks
- Unchanged source time oracle: 888 comparisons, maximum error 4.71e-7
- Existing original-question/source consumer: 103 checks
- Closure lifecycle: 9 checks; ordinary save-mode validation: 27 checks
- Closure admission: 24 checks; closure guidance: 38 checks
- Audio ownership: 12 checks; Chapter 4 controller: 117 checks
- Complete native script graph: 439 scripts, zero failures

## Actual native window and ordinary-save checks (2026-10-09)

The final runtime at `beb99d833d46fc88bbbb836ba9f845a8a180d24a` was rendered in
actual Linux Godot windows. The full cage, needle, low-angle shape, both original
questions, original answer summary and acknowledgement are readable at
1180×812, 430×860, 390×844 and 844×390. Native Control-input tests at all four
sizes and a separate reduced-motion run kept completion false before explicit
acknowledgement and true afterward. Final static views requested no additional
3D redraws. The inner 3D viewport reported at most 13 visible draw calls.

Physical mouse input then selected both original answers. The window was closed
normally at the final page without acknowledging. Ordinary save/reopen retained
both selected answers and `completed=false`, skipped repeat questions and replayed
the original lamp sequence. A physical click on Continue completed the controller;
another normal reopen retained `completed=true` and the same answers. This used
an isolated ordinary-save profile seeded once from the source closure checkpoint,
not a new full-campaign playthrough. Closing during earlier playback remains
covered by lifecycle tests, not by this particular physical close sample.

### Software-renderer performance boundary

These are complete-playback wall-frame samples on the cloud's Mesa llvmpipe
software renderer. They are not the user's GPU, Windows or physical-phone results.

| Actual viewport | Mean FPS | p95 frame time |
| --- | ---: | ---: |
| 1180×812 normal | 25.31 | 54.21ms |
| 430×860 normal | 55.16 | 28.30ms |
| 390×844 normal | 68.92 | 25.52ms |
| 844×390 normal | 72.54 | 20.89ms |
| 1180×812 reduced motion | 31.66 | 44.96ms |

The original full-size candidate measured about 12.01 FPS on this same software
renderer. Profiling identified MSAA and redundant point-light passes as the
largest costs; instanced stars were a small cost. The final implementation does
not reduce viewport resolution or model geometry. The broad desktop case still
does not establish 60 FPS, and startup/first-frame spikes remain in the samples.
Functional integration and readable visuals are verified within this scope;
hardware performance and full-game/platform acceptance remain open. Audio used
the Dummy driver, so no new listening acceptance is claimed.

Source and model provenance are recorded in
`assets/native/canruo/provenance.json`. This batch does not include GitHub upload,
PR publication, merge, or deployment.

Technical references:

- [Godot SubViewport update modes](https://docs.godotengine.org/en/stable/classes/class_subviewport.html)
- [Godot Camera3D aspect and field of view](https://docs.godotengine.org/en/stable/classes/class_camera3d.html)
