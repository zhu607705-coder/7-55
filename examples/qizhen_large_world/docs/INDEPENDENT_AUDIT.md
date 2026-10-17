# Independent large-world route audit

Result: **PASS, 41 automated checks, 0 failures** after the restart fixes.

## Input-only route evidence

The successful route starts from a fresh model. The controller calls the same four input channels as the scene: thrust, turn, brake, and interaction. Source review found no assignment to model position, heading, speed, elapsed time, or objective state. Runtime snapshots verified that controller calls change no gameplay state before physics advances.

| Measurement | Observed result |
|---|---:|
| Successful simulated duration | 110.692 s |
| Actual travel above 30 px/s | 106.183 s |
| Thrust input held | 103.767 s |
| Interaction input held | 5.025 s |
| Distance traveled | 25559.99 px |
| Alternating paddle strokes | 225 |
| Shoreline contacts | 2 |
| Swan hits | 0 |
| Swan warning / charge cycles | 2 / 2 |
| Maximum 60 Hz displacement | 4.725 px |

Every sample respected the 285 px/s speed bound and 1.5 rad/s turn bound. Every boat sample stayed within the navigable collision-clear water region. The nine goal events were emitted once each, in order. Natural travel, braking, and objective interactions account for the duration; there is no minimum elapsed-time win gate.

The >90 s finding describes this successful continuous route. It is not a mathematical lower bound on all possible player routes. The existing `active_time` field alone is not evidence of travel because steering, braking, and interaction also increment it; this audit independently measured displacement above 30 px/s instead.

## Regression coverage

- Model pause freezes movement, hazard state, interaction progress, timers, and event logs; resume works
- Restart resets position, progress, outcome, metrics, feedback, held input, checkpoint, and last stroke
- Inspection rejects missing interaction and excessive speed, and requires the hold duration
- Collection marks the bag recovered after eligible interaction
- Docking rejects a missing bag, excessive speed, and a non-north-facing heading
- Later objectives cannot skip the current objective; leaving the range resets the interaction
- Repeated shore impacts cannot tunnel through the bank
- Swan contact causes damage; cooldown prevents immediate repeat damage; three hits lose
- Win and loss states stop simulation
- Real scene handlers: title does not consume time; W moves the boat; P pauses and clears keys; M map view does not pad time; returning resumes; focus loss pauses; R starts cleanly without reusing thrust

## Bugs found and resolved

The initial independent run found three reset failures: stale outcome feedback, retained input channels, and retained checkpoint/last-stroke fields. The implementation owner fixed these. The final audit passes all three model assertions and the scene-level R restart checks.

## Source/story/save isolation

The standalone project has no State/story/save autoload and no production save/story write path. Runtime production scripts only expose an explicitly requested diagnostic `--trace=` file write. Automated test reports are written outside the project. The original independent audit did not modify production implementation or access the original game's save data. Publication packaging subsequently moved report outputs to Godot `user://`.

This confirms architectural isolation by inspected code; a byte-for-byte original-repository integrity claim requires the implementation owner's source manifest/baseline comparison.

## Limits and nonblocking risks

- Collision clearance is a center point plus eight circle samples at radius 31 px. It is an approximation, not an exact continuous hull polygon collision
- The geometry and island-east passage are explicitly provisional game adaptations, not verified real-world boat navigation
- Automated scene tests call the scene's keyboard handler. They test the binding logic, but do not replace human playability review or OS-level input capture
- Headless tests establish simulated-time duration. The separate runtime recording should establish presentation and wall-clock behavior
- Unit-test fixtures directly assign state to isolate docking, order, and hazard conditions. Those fixtures are separate from the successful input-only route and are not route evidence

## Reproduction

From this example directory, import with `godot --headless --editor --path . --import --quit`, then run `godot --headless --path . --script res://tests/audit_large_world.gd`. The machine-readable report is `user://audit-results.json`; the complete check list is printed to stdout.

## Audited file hashes

- `scripts/games/lake_geometry.gd`: `d1ea15f66a9f1716099815fb424ffd4c541597d22c14289dfc95227727a87352`
- `scripts/games/large_world_model.gd`: `b27afeacd6b78597e47fb6c57b346a9a279b5f3d2c01f107255f5056aeb6fbd4`
- `scripts/presentation/qizhen_large_world.gd`: `7cc2ac8d3f4250e4f84992ba333db0c0490c567dd64dbcb85fdd4c1c879f173f`
- `tests/route_driver.gd`: `20af65938162febfb9ff8a9c6f49d0e2415fd3ca38ad7d878db39fecbce453d1`
- `tests/audit_large_world.gd`: `b94c5070a4671244bb1b64d39ab8f07bbd1897d6bf85cf69fe51d600c7aaf4c8`

## Post-cache verification

The implementation owner reran this same 41-check audit after static terrain caching and final HUD changes. It passed with zero failures. The baseline presentation hash above belongs to the earlier independent review; current published file hashes are in `../SOURCE_SHA256.json`. Model and route-driver behavior are unchanged.

## Publication retest

Test output paths were made portable for a fresh nested checkout. The production model, geometry, route driver, presentation, and actor assets are unchanged from the recorded prototype. See `PUBLICATION.md` for the current clean-import results.
