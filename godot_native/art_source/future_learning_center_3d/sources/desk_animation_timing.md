# Desk animation timing correction (2026-11-03)

## Scope

The viewer previously fed the walking collision time step (maximum 0.05 seconds) into desk animation. At a two-second RAF cadence, a 0.37 m lift at 0.12 m/s therefore took approximately 124 seconds instead of reaching its terminal height on the first frame after 3.083 seconds.

`web/frame_timing.js` now separates those clocks. Walking still receives at most 0.05 seconds per frame. Desks receive actual foreground frame time. Foreground frames of any duration advance the desk toward its clamped target. The earlier rule discarded gaps above five seconds as an inferred suspension. That rule was incorrect: a slow foreground frame is not evidence that the page paused. The correction removes that threshold; explicit visibility and focus signals still control pauses. Visibility changes and window blur/focus reset the baseline. Hidden or blurred frames do not advance the animation or write its instance matrices, and the first restored frame does not catch up.

Each desk records when its target changes, using the same performance clock as RAF. The first frame after a click receives only time after that click. A reversal starts from the currently displayed height and does not apply the pre-click interval to the new target. Different desks keep independent target timestamps. Direct `animateDesks(dt)` calls remain supported for deterministic tests; production frames also provide their RAF timestamp.

This changes timing only. It does not wait for animation before returning to overview, change input timeouts, use forced clicks, alter geometry/LOD/shadows, or claim to fix browser click delivery or rendering stalls.

## Validation

- Pure timing: 221 assertions. The new six-second cadence regression fails against the previous five-second cutoff. With the correction, 6 s, 10 s and 30 s foreground frames reach exactly 1.10 m on their first sampled frame. 60 fps lift reaches 1.10 m at 3083.33 ms. At 1 s and 2 s sampling it reaches that height at 4000 ms, the first sampled frame after the physical duration.
- Actual viewer plus source GLB in Node VM: 207 assertions for `building.glb`, 208 for `building.web.glb`. Both import the real timing module into the existing import-stripped VM harness.
- Integration covers 60 fps, one-, two-, six-, ten- and thirty-second foreground frames, immediate ordinary overview-handler exit while animation is unfinished, continued lift after exit, three enter/exit cycles, mid-flight reversal, exact low-frame terminal heights, hidden/blur pause, first-frame resume, explicit hidden/blur long gaps contrasted with foreground gaps, idle paused frames without animation-triggered draws, and actual `moveBody` displacement remaining bounded by speed × 0.05 seconds.
- Long-frame checks require exact standing and seated targets, not merely in-range heights. Each 6 s, 10 s and 30 s case also covers a late click (100 ms of motion), a late reversal (50 ms of motion), hidden/blur pause, repeated paused frames without matrix writes or draws, first-frame resume, and subsequent foreground completion. Ordinary overview exit is tested before a 10 s foreground frame while the lift is unfinished. Real walking displacement remains clamped during a 30 s foreground frame.
- Between-frame click: click 1900 ms after the preceding RAF, next RAF at 2000 ms. The desk moves 0.012 m, not 0.24 m. Reversal and independent target times for two desks are covered.
- Collision/navigation: 88 checks. Render gate: 42 checks. Workstation review: 18 variants, including lift and repeated cleanup. JavaScript syntax checks pass.
- Browser/furniture tests were not run for this narrow correction. Existing browser timeouts and ordinary-input scripts are unchanged; this result does not establish that any browser click timeout is fixed.

The VM mocks DOM, renderer, network, and optional generated-asset libraries. It parses actual GLB geometry and uses real viewer handlers, but does not establish GPU performance or real pointer/browser acceptance. Browser diagnostics remain a separate check. No Git or publication operation was performed here.
