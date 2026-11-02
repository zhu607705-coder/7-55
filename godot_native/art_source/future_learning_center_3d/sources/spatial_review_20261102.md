# Spatial review skeleton — 2026-11-02

Base: PR208 `a72dc6aab65b760f9297e037746e85680ac9e5a0`; fresh remote main `72fe2ed3`, PR207 `3de82772`. No source drift was found at task start.

## Visitor flow

```text
Four-layer presentation (1F explicitly pending)
  → select source floor → isolate selected floor
    → select source room → crop/reframe presentation only
      → select existing object → close inspection
      ← cancel restores exact prior camera/observer
    ← Back to floor
  ← Back to expanded building
```

Stable building `flc`, floors `flc/f1`…`flc/f4`, rooms use explicit versioned mappings (e.g. `flc/f3/r08` maps the source `xlab`). Object IDs derive from floor and authored GLTF node name, not labels, tenancy, traversal index or random UUIDs. Preserve these node names when replacing geometry; a rename needs an explicit migration.

`web/assets/exhibition_config.json` independently defines teams, exhibits and space assignments. Visitor view only: no editing backend, account, persistence or network write. Change that reviewed JSON to replace content; use a new revision, validate with `validateExhibitionConfig`, and keep space IDs. An approved raster may live below `web/assets/exhibits/`; external URLs, traversal, SVG and executable URLs are rejected. Empty/team-free configuration is intentional, not a claim about current tenants.

## Modeling boundaries

- Source layout and both building GLBs remain unchanged. Expand changes only render-root Y; collapse/walk restores source transforms. Room clipping never changes collisions, mesh vertices or meters.
- 1F: no approved plan. A labeled layer diagram and versioned null geometry reserve the slot. The schematic border borrows the stack extent only to communicate hierarchy, not to assert 1F geometry, elevation or renovation.
- 3F: use existing north exhibit area, pantry/living area and xlab workstation source. The detailed electrical/machining source is on 2F; it was not silently moved to 3F. Hardware/software sub-zones, honors, art and equipment lists remain unapproved placeholders.
- 4F: retain office/auxiliary boundaries and all original furniture assets. This visitor entry shows office outlines and three explicitly provisional corridor-poster slots, not office interiors. Poster size/location and images are illustrative/pending, not surveyed or approved. New entry disables 4F interior walking; 2F/3F walk, collision and adjustable desks remain.
- Six independent prop samples and their separate review entry remain available and byte-unchanged. Main Godot, sign-in/dialogue, solar-page UI and gameplay remain untouched.

## Actual tests and remaining gate

- Original 530 non-browser checks rerun successfully.
- New tests: spatial state 165; real Three display/material restoration 126; actual source-GLB viewer integration 52; content projection/safe raster paths 14. Total **887** non-browser checks.
- VM integration parses the real 12,862-node /12,656-mesh building and registers 76 original tools/desks, tests camera restore, repeated transitions, cross-floor cancellation and actual instanced desk motion. It mocks DOM/WebGL/network and strips embedded image references in memory. It is **not** a browser/visual/pointer pass.
- Chromium was attempted normally in the refreshed cloud environment; startup failed `socket() failed: Operation not permitted`. No bypass, elevated retry or unauthorized Mac access. Actual browser screenshots are **not yet available**.
- `.github/workflows/flc-spatial-browser.yml` installs pinned Playwright/Chromium and runs `browser_tests/spatial_browser.mjs` on the Draft source. It must produce `review/spatial_browser/report.json` and desktop/mobile PNGs. Until that workflow succeeds and images are inspected, the visual/interaction acceptance gate remains open. Headless Chromium may use software WebGL; the report records renderer and exact tree, not physical hardware acceptance.

From the art directory:

```sh
npm ci --prefix pipeline --ignore-scripts
node scripts/test_spatial_state.mjs
node scripts/test_spatial_presentation.mjs
node scripts/test_spatial_viewer_integration.mjs
node scripts/test_spatial_overlay.mjs
# On an authorized browser-capable runner only:
npm ci --prefix browser_tests --ignore-scripts
node browser_tests/node_modules/playwright/cli.js install --with-deps chromium
node browser_tests/spatial_browser.mjs
```

The browser harness starts its own local static server and exercises ordinary controls; it does not mutate state via debug setters. It captures failed partial runs as failed reports, never as acceptance evidence.

## First actual Chromium attempt and corrective regression

PR210 head `3d9abc9a`, run `41456230106` successfully launched Chromium, drew the initial four-layer view and isolated 3F. Its fifth assertion failed because the test compared the restored GLB Float32 Y (`4.050000190734863`) with decimal design JSON `4.05` using strict equality. This was an invalid expected value, not measured transform drift. The fix keeps geometry/transforms unchanged, records an immutable independent source-root position at import, and strictly compares restored Y with that authored source value. No tolerance was widened. Node integration verifies that the baseline stays fixed while expanded Y differs, then restores exactly. The next browser run remains required; the initial failed report and screenshot remain historical evidence, not full acceptance.

## Second actual Chromium attempt

Head `f8824065`, run `41460120064`, passed exact source-elevation restoration and room/object entry, then ordinary `#inspect-exit` click timed out after its original 30 seconds. Three real screenshots were retained. The return button is visibly unobstructed; the selected desk is surrounded/occluded by other desks and transparent chairs. That is a confirmed close-view isolation defect, not proof of the timeout cause.

The scoped repair renders a temporary proxy containing only the selected desk's instance parts, borrowing the same source geometry/materials. It follows existing desk animation, hides surrounding nodes reversibly and removes the proxy without disposing source resources. New regression tests verify this lifecycle. The next unchanged ordinary click test remains the acceptance gate. Browser traces plus three checkpoint snapshots record actual hit target, frame gap, render duration and draw counts; no timeout was increased and no forced click/state setter replaces input.
