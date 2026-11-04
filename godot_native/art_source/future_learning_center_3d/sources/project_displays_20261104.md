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

