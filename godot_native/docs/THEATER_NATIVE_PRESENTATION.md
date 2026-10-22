# Native TheaterImpossibleShow presentation

`games/c3_spotlight.gd` mounts a native modeled stage and planar gameplay art in one warped scene SubViewport. Curtains, floorboards, apron, chairs and an independent articulated followspot have real meshes. The light creature/hat/face, punctuation, mouth, delayed actors, eye, trail and audience remain planar ink. Native HUD, captions and buttons stay outside the lens. See `THEATER_OBJECT_AUDIT.md`; this is not a complete per-object reconstruction or an exact source raster match.

The fixed funhouse sampling function is shared by scene rendering and inverse pointer mapping. Pointer steering uses bounded analog steps; keyboard takes precedence. Mouse/touch ownership includes device and touch index. Pause, focus loss, cancellation and reuse clear retained input. The existing movement and Space dash controls serve all three acts.

## Current gameplay contract

The Godot model and mirrored `TheaterSpotlightModel.ts` share these rules:

- Act 1 intercepts four moving commas within a 25-pixel radius
- Act 2 uses moving question-mark pairs `[0,2]` and `[4,3]`. Each endpoint requires 20 focus ticks within 75 pixels. Priming the first opens only its partner for a 110-tick exclusive window. The expiry tick resets before charging. Central ID 1 unlocks only after both pairs, then requires its own 20 focus ticks
- Act 3 uses fixed pairs `[0,2]`, `[4,3]` and `[5,1]`. A harmless echo follows the exact 60-tick-old position. The live actor and echo must illuminate opposite endpoints simultaneously for 16 consecutive ticks, each within 75 pixels
- Chairs occlude a light-to-target segment at a distance below 26 pixels. Both act-3 rays are checked. Act 2 retains its damaging delayed shadow; act 3 retains chairs, eye and wind but its echo does no damage
- Damage occurs before new charging and cancels temporary focus/priming. Completed groups and history remain. An already-complete set can still exit before hazard damage

All distances refer to the unwarped source model. See `THEATER_MODEL_PREVIEW.md` for decay, timing, retry and evidence details. The game is no longer three rounds of simply collecting the nearest target.

## Authority and review limits

The 50 ms step, 1,600-tick limit, three lives and version-2 input proof remain. Each terminal trace is submitted to chapter authority. The result remains mounted until the primary button explicitly requests the next act, retry or reversal. Rendering, labels and capture helpers cannot award completion.

`test_theater_show_ui.gd` exercises the Main/State/Control path with inverse-mapped input. `test_theater_balance.gd` compares source/native rules and pair/echo boundaries. The nine current source-generated QA routes show reachability only; they do not measure player difficulty or completion time. Historical nearest-target capture results are not evidence for the revised challenge.

Limited manual mouse-input validation reached the first act-3 pair (0/6 to 2/6); later direct paths failed under chair/eye hazards. This is not a full manual playthrough or a usability claim. Physical mobile input and complete rendered three-act acceptance remain open.
