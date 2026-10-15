# Native migration milestone validation

Build date: 2026-10-02 (Asia/Shanghai). Godot4.6.3 official, Compatibility renderer. This is a playable migration milestone with remaining presentation work, not final parity acceptance.

## Current typography and input baseline

The shared UI baseline passes **90/90 aggregate stages**, with no warnings or script/runtime errors. Independent UI regressions cover 783 checks; the compact chase/world overlay covers 184 and the shared theme covers 54. One inherited trailing space was then removed; 30 phone-page checks and the exported campaign reran against the final content. See `UI_TYPOGRAPHY_AND_INPUT.md` and `UI_BASELINE_VALIDATION.json`.

The final Linux PCK passes **768 continuous campaign checks / 1,268 trace entries**, plus 21 fresh and 17 second-process native-only checks. It runs in the official Godot runner from an empty working directory with an empty executable search PATH. Its 1,658 packed resources contain no JavaScript, TypeScript, HTML or WASM runtime files; the original browser source and npm dependencies are absent. The release template's path-override restriction is preserved. The actual exported Linux executable separately passed real mouse/keyboard alarm → wake → home actions and normal process restart, restoring the identical saved state. Graphical runs use the Dummy audio driver and do not verify audible playback.

The shared-control review includes phone/editor/modal views, long choice popups, actual button draw states and compact world/chase views. This is not a complete manual playthrough. The new node-by-node CUA acceptance is still open, and its first real alarm/wake review found source palette, large-button typography, subtitle scale and phone-toast differences that require correction and manual retest. No full parity or PR-ready claim follows from this baseline.

## Latest required-app batch

The latest fresh campaign passes **768 checks, 0 failures, 1,268 trace entries**. It now uses real compact Main/Home controls and genuine item drags for CC98, Library, timed WeChat, the three-source map, physical lake entrance and contextual Weather. The independent623-check ordinary-app suite spans390/430/1280. The33 actual graphical captures include saved source labels, map attribution/confirmation and the readable compact Weather controls.

Incoming collection deep-copy isolation passes362 checks, including all117 repeated developer snapshots; compact Weather presentation passes140 checks without physics or receipt changes. The frozen81/81-stage aggregate is warning-free. Final official Linux PCK passes768 campaign checks,623 actual app-input checks and21+16 fresh/reload resource checks from outside the checkout. The actual final Linux executable also passes startup and GUI alarm→home→process restart with identical saved state, plus three representative scene smoke captures. Windows is export-only. Batch hashes/results are in `LAKE_APP_VALIDATION.json`; final extracted-source archive acceptance is in the immutable distribution manifest.

## Earlier broad milestone gate

The broad milestone8512001 aggregate passed **77/77 stages**:62 native test/smoke scripts, import/startup,9 deterministic source catalogs,3 original-model oracles and the focused SaveStore differential. An isolated test teardown initially left MP3 playback references alive. The fixture now awaits the real shell/audio shutdown; three verbose reruns passed81 checks without warnings. The repeated final77-stage aggregate is also warning-free. No production-runtime change was needed.

## Earlier campaign evidence

`tests/test_full_campaign.gd` starts from exactly one fresh initial state and reaches Chapter4's final acknowledgement: **567 checks, 0 failures, 1,031 trace entries**. It uses real controller actions, native phone button/timer flows, minigame input traces, issued presentation/proof sessions, the promo visual boundary, reversal's two lines → actual inspector close → three lines, source rain-media handling, and four real audio auditions. It saves/reloads at chapter boundaries.

Stand-point positioning is explicitly performed by the test harness. This is not a complete manual map-navigation playthrough and does not establish browser-identical rendering.

## Earlier exported-resource evidence

- Windows x86_64 and Linux x86_64 release export succeeded using the official4.6.3 templates. Windows resources are embedded; Linux keeps its executable and `.pck` sibling. Windows is unsigned and was not executed on a Windows device.
- The exact Linux release `.pck` also passed the same fresh campaign: **567/0**, all four chapters. The official Godot runner loaded that pack from outside the source checkout. Only the five external test/helper scripts were relocated; every runtime/data/asset reference continued to resolve from the exported pack. Release executables do not expose Godot's external `--script` flag, so this evidence is correctly described as exported-pack testing.
- Exported-pack resource/startup/persistence checks:21 fresh checks plus16 second-process reload checks, all passed.
- The actual Linux executable was run graphically in the cloud. Real clicks exercised alarm start/dismissal, wake warning and home. Closing and reopening restored home with the same saved state. Source checkpoint rendering then exercised campus/Library entrance, live lake and Chapter4 maintenance. Those three scene captures are resource/lifecycle smoke checks, not progression proof.
- The actual Linux executable also passed headless startup. Visual checks used the Dummy audio driver; they are not claims of audible playback.

The self-contained native source ZIP was separately unpacked without the original repository. Initial concurrent imports were terminated with exit137 by the resource-limited host. After closing other task editors and serializing work, a fresh import with a temporary single-import/two-worker setting completed; the override was removed and standalone source startup passed without errors or warnings. All888 runtime/data/asset file hashes match the frozen project. The source guide documents the low-memory first-import option; no runtime rules or exported bytes changed.

## Source and visual evidence

- All718 original assets match their manifest SHA256 values,625,907,429 original bytes. Converted native video and the authored charging icon are identified separately.
- Source SaveStore normalizer:569 focused comparison cases and4,223 exhaustive comparison cases, zero differences. Actual native persistence and imported Chapter2 continuation:1,805 checks/233 imports. Domain guard:1,014 checks.
- Phone login/Library UI:135 checks; all12 Library dialogue sequences/53 lines:718 checks; Library world props/collision:108 checks.
- C3 source actor/prop layers:129 checks; issued promo integration24; reversal/save/layout42; original TS queue oracle21 schedules/49 line entries. Opening/paper readability817 and ordinary narrative readability20 checks preserve original wording, timing and the canonical world aspect.
- Reviewed71-view native gallery,12 Library physical-layer captures,27 C3 sequence/prop snapshots and12 responsive story-caption snapshots. Four stair captures report distinct actual `stair_a` through `stair_d` levels with completed reveals. These captures are explicitly marked as visual coverage, not a story playthrough.
- Critical story captions at390/430 widths have14–15px physical text floors and wrapping contained in the world surface. This bounded fix is not blanket mobile/device acceptance.

## Boundaries still open

The compact device-page visibility/input contrast fix passes694 actual Main/viewport checks; see `COMPACT_DEVICE_NAVIGATION.md`. The subsequent lake-app batch closes the named CC98/Library/WeChat/map/Weather entrances with623 actual Main/input checks, genuine inventory drags and source-timed messages; see `CHAPTER3_PHONE_ROUTES.md`. Final batch-specific aggregate, exported-pack and archive results are recorded separately in `LAKE_APP_VALIDATION.json`. A controller campaign alone is not proof of complete interactive-UI route coverage.


See `REMAINING_PRESENTATION.md` for source phone eligibility/loading, interruption/timing/audio, mixer option-order behavior, world/helper/device views, Library environmental details and selected Chapter4 effects. The cloud browser's original preview is blocked by an extension (`ERR_BLOCKED_BY_CLIENT`), so live browser pixel comparison is not complete. Android/iPhone/Windows real-device runtime testing remains unverified. No merge or deployment is included.

The adjacent `FINAL_NATIVE_VALIDATION.json` records the final aggregate labels/statuses and immutable runtime-tree digest. Distribution `BUILD_INFO.txt` records the local commit and platform artifact provenance.
