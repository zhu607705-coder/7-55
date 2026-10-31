# Workbench consistency pass — 2026-10-30

## Scope

Reuse the existing miniature bench's ivory/teal/graphite materials and Noto close-up typography. The campus world and story UI keep their existing typography. Shared native navigation replaces separately drawn close targets; the formal host presents “返回入口” and, only while an apparatus is open, “离开操作台”. Both host targets remain 44 screen pixels high, including the 390px-wide save-retry state. Standalone apparatus views retain their own close control.

The original Formula energy-budget activity now uses the existing Camera3D miniature renderer through a presentation-only adapter. Its original model, input anchors, 30-second race, saved fields and comparison goal remain intact. This does not replace the separate solar prototype and does not claim that all 25 rooms have new 3D artwork.

## Verification

- All existing isolated FLC puzzle suites passed after the shared changes.
- Three consecutive runs on the same shared style/host/font snapshot each passed 55 navigation/input checks and 38 formal-host lifecycle checks. These include touch cancellation, focus loss, reentry, save failure/retry and target bounds.
- Formula: 221 existing model/input checks and 29 presentation checks passed. The presentation tests cover projected controls, camera/mesh construction, track surface normals, mesh reuse and hidden-view rendering suspension.
- Actual GUI: desktop and 844×390 Formula part dragging, gear selection, continuous tilt, placing the car, running, opening the physical notebook and returning to the floor. An actual race produced 62.52 versus 52.35. Focus/Koala/existing physical apparatus were also inspected at desktop and 844×390; both navigation levels were exercised.
- The FLC-only font companion covers 19 previously missing characters. Its generator uses the same locked Noto source and leaves historical SelectedCoverage and Morning Note inputs unchanged. The runtime corpus scan passed 10,018 character assertions, including an explicit non-empty-corpus guard; this count is character coverage, not 10,018 independent gameplay scenarios.

## Remaining boundary

The formal 844×390 host fits the 960×540 apparatus plane into approximately 601×338 pixels. Some secondary 13–16 logical-pixel labels therefore remain around 9–10 screen pixels. Navigation is touch-sized, but this pass is not a claim that every mobile label or every room's artwork has been fully redesigned.

Production Web acceptance is a separate gate: admission, actual object input, exact save acknowledgment, independent IndexedDB inspection and real document reload must pass on the uploaded commit. Local headless/GUI results are not substituted for that gate.
