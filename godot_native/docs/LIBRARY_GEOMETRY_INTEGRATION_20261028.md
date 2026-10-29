# Library geometry reading — native integration

The previous single-file design at `docs/art/library_geometry/index.html` is retained as the visual reference. The formal game now opens a native Godot reading activity from a small geometry notebook on the north-west study table. It does not mount HTML, a browser frame, or a second game runtime.

## Entry and ownership

`objects/library_geometry_notebook.gd` owns the independent transparent vector notebook, its original-map bounds `(1002,195,32,24)`, a slightly expanded pointer surface, and the approach anchor `(1018,280)`. The existing table remains the sole collision owner. The shared player-foot offset matters here: the anchor places the feet in the clear passage between the two table rows. The focused entry check also finds an unchanged-collision route from the reading-area gate to that anchor.

`library_world_layers.gd` paints and registers the notebook using the table's source depth. `chapters/library022.gd` owns `lib_geometry_study`. The activity is optional and repeatable when physically inside the library in RPG mode, without bypassing a pending library handoff or an active Chapter 2 story. It has no success callback, proof, inventory reward or persistent completion flag. The previous south-west paper/lamp activity remains separate and is covered by its existing regression.

The normal Main host opens `games/library_geometry/view.gd`, supplies available dimensions, and restores the same world and player position when it receives `cancelled`. The arrow and Escape use that existing cancellation path.

## Native presentation

The view uses Control/PanelContainer/GridContainer/ScrollContainer nodes and native vector drawing. Desktop retains three stationary cards, maximum row width 1200, 12-unit gaps, 20-unit corners, 202×202 diagrams, 17-unit titles and 15-unit captions. At 760 and below, the cards become one scrollable column. A reserved navigation strip prevents scrolling captions behind the return arrow. The icon slot can retain a 202-unit drawing without forcing horizontal overflow just above the breakpoint.

Solid ink uses 0.75-unit antialiased polylines. Guides are round 1.25-unit dots at four-unit intervals. Sphere meridian widths follow the authored sine function; no horizontal stretch changes stroke width. Plate separation, staggered offsets, spiral removal/regrowth and their faster interrupted returns use the original geometry and easing curves. Only the ink animates; card and pointer bounds remain fixed.

The original Inter WOFF2 is extracted unchanged from the supplied design and bundled with its OFL notice. The project's bundled CJK face supplies characters absent from Inter. Titles and captions reuse the existing design verbatim; no new narrative prose is introduced.

Entrance strokes draw once per running native session. Web also uses the original sessionStorage presentation key so reopening/reloading within that browser session does not replay entry. Entry blocks activation until it has settled. Fine mouse motion, touch taps and keyboard Enter/Space activate diagrams; a scroll drag is not a tap. System reduced-motion preference in Web and the native reduced-motion setting both settle the complete shapes. Focus loss cancels held input and moving effects. The preference listener is removed on exit.

## Evidence and review

Focused validation runs the new actual-entry test and the existing paper/lamp entry test, plus the required native preflight. The new test covers actual rendered notebook clicks, a safe approach/path, host resizing, touch activation, interrupted motion, reduced motion, return/re-entry, unchanged inventory/story facts and rejected out-of-room intent. The headless focused runners pass. The follow-up Impeccable pass also runs the graphical entry/input/return and keyboard-focus/scroll checks at 1280×720 and 390×844 with 37 checks and zero failures. The previous two graphical return/re-entry failures did not recur in the current runs; their original cause was not established. The current graphical.log records the current run.

The production export remains rooted at `scenes/entry.tscn`. A local-only review scene provides a nearby library position in a separately exported, isolated preview project. It seeds a review fixture, not controller-earned campaign progress. The same Main, world, controller, notebook, activity and media gate run there. The release Web template refuses command-line scene overrides, so the review project's main-scene setting is changed in its disposable copy instead. The failed override experiment is not deployment evidence.

Local review: `http://127.0.0.1:5277/geometry.html`. Its localhost/path guard prevents the fixture from replacing a remotely hosted production session. Production-source build: `exports/library-geometry-20261028`. Exact logs, source hashes, desktop/mobile images and browser observations are stored under `/Users/zhu/Library/Application Support/755-tools/verification/library-geometry-integration-20261028/`.

This is a local integration and export. It does not claim a merged PR, remote deployment, physical-device acceptance, or a full library chapter playthrough.

## Drawing budget and browser recheck

An earlier Web review stopped drawing after repeated resize/media changes with a WebGL vertex-array RangeError. The root cause was not proven. Profiling the native static reduced-motion view found 1060 draw calls. Guide dots now share a procedural radial texture and a batched ArrayMesh, and settled geometry stops rebuilding its draw commands. The same native measurement fell to 73 draw calls; this is not an FPS or physical-device performance claim.

The refreshed Web export was checked with an actual notebook click, three-card rendering, 800-wide layout, a scrollable 390×844 column, restoration to 1280×720, and real return/re-entry. A fresh post-interruption review also passed both arrow and Escape return, including after narrow-screen resizing, with no warning/error logs. Browser overrides were restored. Physical touch hardware and other browser engines were not tested.

## Impeccable refinement, 2026-10-28

Applied the user-selected Impeccable polish/harden/craft-floor guidance while preserving the explicit three-card visual brief. Secondary text now uses #62665e (5.76:1 against #fdfdfb). Matching two-line caption slots align headings when one caption wraps. Added static inset focus outlines, an explicit tab cycle and scroll-to-focused-card behavior; diagrams retain the original pointer, motion and reduced-motion contracts. Current native graphical tests include real Tab focus and bringing the last card entirely into the scroll viewport.

The fresh source passes the focused native preflight and geometry/raking runners. Current native captures replace the previous graphical captures. The local Web exports are rebuilt, but browser replay of this refinement is unavailable because Work settings disabled local browser use. Earlier browser evidence remains historical and is not represented as a current browser pass. See UI_DESIGN_WORKFLOW.md for the persistent project rule.

## Selected delivery — 2026-10-29

This submission is based on main 533ed6b7 and contains only the agreed geometry/Impeccable scope. It preserves main's SpatialRules foot-depth logic from PR186; the new notebook is drawn through that existing depth conversion. Local PR184 commits and the unsubmitted paper/lamp integration are excluded. Earlier working-tree evidence above is historical; the isolated selected source receives its own preparation, native validation, Web export and cloud CI before merge. The production entry remains unchanged.

Selected-source local validation completed: source sync, full-stream media conversion, strict import/startup/all-script parse, geometry entry, existing library world layers and shared world-space checks all pass. The real native window again passes 37 geometry entry/input/return/focus assertions at 1280×720 and 390×844; the narrow focused card capture was inspected. The production Web export passes at `godot_native/exports/library-ui-20261029`; its entry remains `scenes/entry.tscn`. Local browser replay remains unavailable under Work settings. Cloud PR checks and merge are subsequent delivery steps, not inferred from this local export.
