# Desk animation timing correction (2026-11-03)

## Scope

The viewer previously fed the walking collision time step (maximum 0.05 seconds) into desk animation. At a two-second RAF cadence, a 0.37 m lift at 0.12 m/s therefore took approximately 124 seconds instead of reaching its terminal height on the first frame after 3.083 seconds.

`web/frame_timing.js` now separates those clocks. Walking still receives at most 0.05 seconds per frame. Desks receive actual foreground frame time. A gap above five seconds is treated as an unannounced suspension and discarded, rather than causing a catch-up jump. Visibility changes and window blur/focus reset the baseline. Hidden or blurred frames do not advance the animation or write its instance matrices, and the first restored frame does not catch up.

Each desk records when its target changes, using the same performance clock as RAF. The first frame after a click receives only time after that click. A reversal starts from the currently displayed height and does not apply the pre-click interval to the new target. Different desks keep independent target timestamps. Direct `animateDesks(dt)` calls remain supported for deterministic tests; production frames also provide their RAF timestamp.

This changes timing only. It does not wait for animation before returning to overview, change input timeouts, use forced clicks, alter geometry/LOD/shadows, or claim to fix browser click delivery or rendering stalls.

## Validation

- Pure timing: 209 assertions. 60 fps lift reaches 1.10 m at 3083.33 ms. At 1 s and 2 s sampling it reaches that height at 4000 ms, the first sampled frame after the physical duration.
- Actual viewer plus source GLB in Node VM: 154 assertions for `building.glb`, 155 for `building.web.glb`. Both import the real timing module into the existing import-stripped VM harness.
- Integration covers 60 fps, one- and two-second frames, immediate ordinary overview-handler exit while animation is unfinished, continued lift after exit, three enter/exit cycles, mid-flight reversal, exact low-frame terminal heights, hidden/blur pause, first-frame resume, long suspension, idle paused frames without animation-triggered draws, and actual `moveBody` displacement remaining bounded by speed × 0.05 seconds.
- Between-frame click: click 1900 ms after the preceding RAF, next RAF at 2000 ms. The desk moves 0.012 m, not 0.24 m. Reversal and independent target times for two desks are covered.
- Collision/navigation: 88 checks. Render gate: 42 checks. Workstation review: 18 variants, including lift and repeated cleanup. JavaScript syntax checks pass.
- Legacy `test:furniture` could not start: it imports unavailable `/private/tmp/flc-viewer-qa/node_modules/playwright-core/index.mjs`. This is a missing environment dependency, not a failed behavioral assertion.

The VM mocks DOM, renderer, network, and optional generated-asset libraries. It parses actual GLB geometry and uses real viewer handlers, but does not establish GPU performance or real pointer/browser acceptance. Browser diagnostics remain a separate check. No Git or publication operation was performed here.
