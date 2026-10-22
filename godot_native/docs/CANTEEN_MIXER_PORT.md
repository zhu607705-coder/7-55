# Canteen mixer and Chapter 3 world devices

This candidate activates the previously isolated source-backed mixer helpers. It also restores the theater keypad and program-draft device controls. It is a local migration patch, not a release or full-campaign acceptance claim.

## Source authority

- `CanteenInteriorScene.ts:3186–3310`: shuffled ingredient slots, identity permutation rotated away from recipe order, stable slots until close, missing-item feedback, source-colored actual liquid layers, and retained partial sequence
- `ChapterThreeCanteenController.ts:301–331`: only the controller consumes ingredients, judges the completed recipe, increments attempts and awards the authored drink
- `TheaterInteriorScene.ts:1497–1594,1655–1670`: a four-digit keypad with backspace; wrong submission remains editable; a new opening clears local keypad text. Program cards append to a persistent controller draft, reject duplicates, and expose undo, clear and submit
- `ChapterThreeTheaterController.ts:305–350`: valid collected-card draft; wrong submission retracts the final card; correct order consumes the fragments, awards the remote and records `theater_stage`
- `CanteenInteriorScene.ts:1077–1106`: actual body-foot depth, actor-bound overlap and 0.52 soft foreground occlusion

`export_canteen_mixer_source.mjs` and `export_c3_devices_source.mjs` execute these original TypeScript methods with recording surface/store stubs. Their fixtures retain source hashes. No TypeScript or source evaluator is loaded by the game.

## Integration

`Main` owns the blocking modal. Split desktop uniformly scales each original 960×540 device to the world rectangle. Compact portrait and landscape use separate, unscaled modal arrangements with physical body labels at least 14px and buttons at least 44×44px. The compact mixer stacks its pour controls; theater retains the same keypad and draft actions. This mobile presentation is an explicitly authorized adaptation, not an original-source geometry claim. The world remains mounted. Opening clears queued movement; existing modal guards block keyboard movement, camera input, phone chrome and inventory actions. Escape/close releases the modal; a changed state identity or scene closes the device. Partial drink and program drafts remain controller-owned; keypad text and shuffled slot order are not saved.

Generic answer forms for the three devices are retired. Legacy saved page IDs retain a proximity-checked route back to the physical device. The authored bad-drink tasting action remains available on the canteen page.

Canteen foreground now uses the original actor-foot/softening rule. The small neutral glass and “混合台” plate at the existing southwest hotspot are an authorized discoverability refinement, not an original-source art claim. They reveal no color order and change no collision, item, hotspot location, story or progression gate.

## Verification boundaries

- Actual cloud-desktop CUA from the declared `c3-canteen-drinks` DEV checkpoint: walked to shelf and drink machines; read shelf; collected all three drinks; walked to mixer; opened shuffled world device; poured coffee; closed/reopened with coffee retained; poured remaining ingredients; received 今日新品气泡水 and the modal closed
- This is chapter-local test-entry acceptance. The earlier chapters and initial checkpoint facts were not earned in this run. The CUA run did not cover wrong mixture, theater devices, save/reload, canteen promotion/defense, chase, or lake
- Later local actual-Control matrix covers split 1280×720, compact landscape 960×540 and 844×390 and compact portrait 390×844 and 430×860: mixer success/failure/missing ingredients/reopen, keypad typing/backspace/wrong code/reopen/no phone release, program undo/clear/duplicate rejection/reopen/wrong-order persistence/correct submission, modal movement blocking, physical-font/target dimensions, containment, non-overlap, and compact↔desktop resize retention
- Source-geometry tests and headless controls do not constitute physical mobile or final visual acceptance. `capture_c3_devices.gd` is an explicitly seeded graphical fixture for layout inspection, never manual campaign proof

## Final graphical review (2026-10-02 UTC)

26 distinct seeded screenshots were inspected, including ready mixer/keypad,
wrong-code refusal, program draft, the neutral mixer landmark and the softened
shelf crop. Five program frames were recaptured after fixing an inherited dark
hover-text color. Compact 390×844, 430×860, 960×540 and 844×390 frames show readable
text and complete controls. These captures exercise declared fixture states;
they do not extend the manual CUA or earned campaign claim.

Compact captions mirror only the existing world's currently active subtitle and
timer. They do not read future dialogue lines, play duplicate speech, advance a
story, or persist an extra notification state.

## Commands

```
node godot_native/tests/export_canteen_mixer_source.mjs --check
node godot_native/tests/export_c3_devices_source.mjs --check
godot --headless --path godot_native --script res://tests/test_canteen_mixer.gd
godot --headless --path godot_native --script res://tests/test_c3_devices_controls.gd
```

Run tests with a new XDG profile under `/tmp`, as the project validation runner does. The export tools accept `--source-root` for isolated staging. The fixture capture script requires the lead's exclusive graphical slot.
