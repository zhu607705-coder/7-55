# Evidence log

- Base checked via GitHub: main `0713f50999ac1516d732b69a1b40ce946bd5c723`, 2026-10-26.
- Separate working branch: `dot/library-two-times-20261026`; PR 182 is not changed.
- Local runtime: official Godot `4.7.1.stable.official.a13da4feb`.
- Clean import, ordinary startup, independent World3D and actual occluder-ray checks passed in an isolated XDG sandbox. No campaign save is accessed.
- Ordinary scripted two-touch event path passed: move both windows, inspect exposed halves, reject a same-upper-symbol book, retrieve the unique complete match. This local run is headless, not visual evidence.
- First actual hosted GL run `40352945807` at `bf5025d` recorded a full 20-second ordinary two-touch playthrough and passed graphical safety/input checks. Pixel negative controls correctly failed because a fragment was not fully exposed.
- Reviewed first-frame PNGs: lowered the morning tote rim, raised the afternoon folio, replaced center-only evidence with complete-stroke probes, and fixed orthographic visibility rays. All six covers now share a color, so a lower mark plus cover color cannot leak the upper mark. Added the single-half ambiguity regression.
- Refined actual GL run `40354027319` at `4314c722`: normal 390×844 comparison/complete frames and 430×860, 1280×720, 844×390 captures reviewed. Full ordinary input and recording passed. Both fragments are now complete and same-colored candidate books require both marks.
- Its morning pixel counterfactual caught incomplete test setup: hiding only the tote body left the rim across the view. Register the complete tote/folio mesh groups for the negative control; keep the original pixel thresholds. No visible geometry changes in this test repair. Final hosted rerun pending.
- Physical mobile hardware and campaign integration: not performed / out of scope.

## 2026-10-27 · retrieval and keyboard corrections

- Repair base: main `0df813401992bbd8dbe2dd9de29e67114976c134`. Work is isolated from the earlier prototype directory.
- Removed history movement, observation and dwell credentials from the local model. The player may infer the answer without moving either window; a correct visible book still requires an actual pull. Hidden current books, short pulls, wrong books and canceled grabs remain invalid.
- Added a sample-local keyboard owner with the same exclusive ownership checks as touch and mouse. Canceling one owner returns only that owner's book, if any, without dropping another hand's window or book. The shared kit is unchanged.
- Updated model regressions and the two-touch recording script. Recording checks actual fragment visibility rather than stored observation credit. Keyboard focus, grab/release and movement are view-level fallback controls; they add no permanent help panel.
- The corrected model passed `test_library_model.gd` on official `4.7.1.stable.official.a13da4feb` in a separate temporary project with isolated XDG directories. This proves model transitions and scoped ownership cancellation, not rendered input.
- Isolated `tools/run.mjs` passed clean import, model, geometry, ordinary input and startup on Godot 4.7.1. The input regression covers the complete keyboard solution, direct retrieval with untouched windows, wrong-book return, mixed pointer/keyboard ownership, hidden-current rejection, focus changes, Escape/Continue, resize and keyboard Reset. Formal-save sentinels, standalone isolation and unchanged shared-kit checks passed. These local runs are headless; refreshed hosted GL evidence is still pending. Historical frames above do not validate this correction.
