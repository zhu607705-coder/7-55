# Configurable workstation and poster displays

Baseline: PR #212, commit 2c9f23d78819a542273f2dd30cea6944a2413efa. This candidate is separate from that branch. It does not change check-in, geometry, room identity, team membership, colliders or desk animation.

## Behavior

- Click a photo monitor panel/bezel or original authored Screen/Monitor frame. The exact instanceId identifies its desk. Keyboard, mouse, support and table surfaces keep their previous behavior.
- Click a corridor poster. Each existing placeholder has its own stable display ID.
- A native dialog shows the assigned exhibit in overview or walk mode. Close/Escape returns to the same camera and walk state. Input is cleared on opening and closing.
- Links are optional exhibit.url values. Only local ./ paths and HTTPS are accepted. External links open in a separate tab with noopener noreferrer. No actual project links were supplied, so the shipping config shows no jump links.
- All three poster bindings use the existing, explicitly provisional office-corridor-poster exhibit. Workstations without an assignment show an unconfigured message, never an invented project.

## Configuration

exhibition_config.json keeps content in exhibits and object bindings in displayAssignments.
Each binding has targetId (the stable desk spatial ID, or flc/f4/poster/seminar_1 through seminar_3) and exhibitId (an existing exhibit). Duplicate or unknown targets/content are rejected; the building remains usable when assignments fail validation. Obtain desk IDs from the existing flcReview.spatial().catalog.objects diagnostics, not array order.

The existing roomAssignments and teams are unchanged. Object binding does not assert that a team owns a room. Images keep the approved local raster whitelist. Broken images retain readable text.

## Verification recorded here

Passed locally: test_project_displays.mjs 52 assertions; test_spatial_overlay.mjs 14 assertions; test_spatial_state.mjs 165 assertions; JavaScript syntax checks.
The new unit tests cover instance zero and multiple owners, LOD filtering, control precedence, authored fallback, walls, config replacement, unsafe URLs, modal repeat/close/reopen, missing content and broken image fallback.

The new browser_tests/project_displays_browser.mjs is registered in flc-spatial-browser.yml. It exercises a clearly labeled DOM fixture at desktop and simulated-mobile viewport sizes, preserves screenshots, and does not claim a real 3D scene test. Existing actual WebGL acceptance still runs independently if a new check fails.

Not run locally: actual GLB viewer VM, actual building raycast/occlusion tests, Chromium DOM fixture, aggregate validate:quick/release. The sparse environment lacked runtime assets and Playwright installation. Its local server was not reachable from the available cloud browser (ERR_CONNECTION_REFUSED), so no screenshot was produced. The Impeccable skill was not present; no visual restyle was attempted.

The reference ramen website's interaction was not observed, so this candidate makes no claim to reproduce its appearance or behavior. Keep existing visual styling until reference evidence is available. No push, PR, merge or deployment was performed.

## Remaining acceptance

Run the registered CI tests on the exact final commit, then in the real building tap visible screen panels in both overview and walk modes, test two different workstation owners, lift a desk and retest the moving screen, close and reopen, verify walls occlude clicks, and check 4F posters. Capture actual scene screenshots. Do not call this candidate browser-accepted before those results are available.


## Added actual-building acceptance (publication follow-on)

`project_displays_building_browser.mjs` now loads the actual building GLBs for independent desktop and simulated-touch runs. The test uses ordinary canvas clicks/taps and camera drags, never forced clicks or direct content-opening hooks. Read-only diagnostics project current instanced geometry and check the same nearest visible ray hit as the real picker. They also verify that a blocked sample intersects an actual wall before an actual display on the same ray.

The gate requires two different overview monitor owners, walk-mode screen opening, close/Escape/reopen, an actual desk-edge control followed by a moving screen click, real full-height wall occlusion, and a corridor poster. It saves exact head/checkout/tree provenance, screenshots, per-check results and traces, including failure evidence. Existing DOM and spatial tests remain independent. The workflow checks out the exact PR head.

The DOM fixture now waits for the native asynchronous close event before checking its onClose result. No UI behavior or action timeout was changed for that correction. New actual-building tests have passed syntax checks only in this sparse workspace; exact-head hosted execution is required.

## Diagnostic work-budget correction

The initial real-building harness queried all display geometry even for active-dialog and camera reads. The follow-on separates those lightweight reads, including current desk animation state, from ray queries. Geometry scans filter by type/owner, retain each shared geometry's computed bounds, examine at most three candidates per request, and return the first verified target. The caller paginates remaining candidates rather than silently skipping them. Wall tests still require a real wall hit before the real screen on the same ray.

Each diagnostic evaluation has a 15-second host-side deadline. Search phases and completed checks are written immediately. Failure recovery uses only a bounded lightweight snapshot, then bounded screenshot/trace/cleanup attempts; it does not start another geometry scan. A timed-out browser evaluation is not claimed to have been cancelled by the deadline itself. Closing its context is the cleanup step.

Eleven additional mock contracts verify budgets, shared bounding-box caching, pagination, owner/type filtering, early return and genuine two-hit occlusion requirements. These tests do not replace real Chromium/GLB acceptance.

## Direct-control survey and independent evidence segments

The bd78 browser traces showed a test-selection defect: deskControls() supplies an assisted interaction anchor, not the control mesh center. At the retained spawn, desk008's anchor ray reached the floor at 4.89 m; desk011's anchor ray hit foreground furniture at 1.75 m. Rotating yaw did not change either world-space line of sight. This does not establish that the actual controller is broken.

The revised diagnostic projects actual instanced parts whose entry.control is true and still requires that the nearest visible hit is a control belonging to that exact desk. It samples normal downward gazes and a short collision-constrained strafe through ordinary mouse/touch/keyboard controls. No hit-assistance relaxation or geometry replacement is used. Two added mock contracts protect this distinction.

Monitor, controller/lift, wall-occlusion and corridor-poster segments now record results independently from legitimate viewer entry URLs. A controller failure no longer suppresses wall/poster evidence. Any failed segment still fails the aggregate acceptance. This follow-on is locally syntax/contract-tested only until its exact-head real browser execution completes.
