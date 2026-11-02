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
- New tests: spatial state 165; real Three display/material restoration 126; actual source-GLB viewer integration 41; content projection/safe raster paths 14. Total **876** non-browser checks.
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
