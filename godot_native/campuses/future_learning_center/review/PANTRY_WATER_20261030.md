# 3F pantry: slow water and tray balance

The user found the prefilled-cup puzzle too simple and explicitly requested adding water with especially slow flow. The fifth room prototype now starts with four empty glasses. A physical dispenser, orange valve and drain basin extend the existing fixed orthographic miniature. The room entrance remains the actual charcoal communal table.

## Play

Local export: `http://127.0.0.1:8139/pantry_water_20261030/?area=pantry` (requires the existing local server).

1. Drag a glass from its coaster to the dispenser on the right.
2. Drag the orange valve upward to open it, downward to close it. The thin visible stream adds **4 ml/s**; a full 180 ml glass takes **45 seconds**. There is no countdown or timed failure.
3. Fill to the band between the two copper marks. The four glasses request different amounts. To remove excess, hold the docked glass over the lower basin; release to stop pouring and restore it under the spout.
4. Return the glass to a tray coaster. A return onto an occupied coaster exchanges the two glasses.
5. When all four portions are prepared, lift the tray by its handle. Observe which side drops; drag the handle down to lower it, adjust placement or water, and try again. Only a correctly filled, balanced tray can be delivered to the sofa coffee table.

The notebook offers three voluntary clues: recognise the fill bands, compare inside/outside positions, then consider fine water adjustments. A shifted-support variation becomes available after delivery. Exit remains navigation; there is no gameplay button strip or keyboard-required action.

## Model and difficulty

`pantry_tray_model.gd` owns volume, valve state, docking, weight, trials and completion. The render cannot grant results. Each glass holds at most 180 ml. Requested centres are 60, 90, 120 and 150 ml, each with an 8 ml band on either side. Glass tare is 40 g, tray tare is 120 g, and arm positions are −2, −1, +1 and +2. Water mass follows its measured volume.

All 24 permutations of the exact requested centres miss the balance tolerance. Successful configurations require both placement and small adjustments within the visible bands; no exact one-millilitre answer is required. For validation, volumes [65, 85, 115, 155] with order [A, D, C, B] balance exactly. [66, 86, 114, 154] also works. These are test witnesses, not displayed solutions. Optional support offsets ±0.25 retain feasible configurations and account for the tray's own weight.

About 105 seconds of actual water flow prepares a typical set of portions. The overall 4–7 minute target remains a design estimate, not a measured novice-playtest result. The slow flow is a user-requested interaction constraint; water quantity also changes the physical puzzle rather than serving only as a waiting gate.

## Recovery and scope

Pickup, cancellation, focus loss, closure and capacity stop flow. Already poured water remains; returning to a page never catches up elapsed background time. Pourback removes 48 ml/s while the glass is held over the basin. Invalid drops return the glass. An extra finger cannot finish another finger's gesture. Cancelled delivery earns no completion and retains prepared water. Reduced motion preserves all necessary state feedback.

The three floor manifests, furniture footprints, collisions, source assets and four earlier puzzle models are retained. This remains a session-only, isolated Godot sample. Production chapter integration, persistent saves, seated-student payoff and physical-phone acceptance are outside this delivery.

## Verification

Engine: `4.7.1.stable.official.a13da4feb`, with matching Web templates. Evidence and captures are under `.impeccable/review/flc_pantry_water_20261030/`; the final receipt records exact source and export hashes, test counts, actual browser interactions and independent review scope.

The model passes 52 assertions. Final desktop pointer and simulated-touch runs each pass 39 checks with zero keyboard events. These include four edge positions around the basin, downward recovery from a tilted tray with water preserved, and all three support-caption positions. Floor regression passes 1740 checks; design coverage passes 833 checks and is not acceptance of all 25 rooms as playable games.

The final 903×862 browser replay fills and pours back water using ordinary pointer input, prepares displayed amounts A65/B85/C115/D155 ml, lowers a tilted tray, exchanges cups, lifts level and delivers to the coffee table. The record and room tray reflect delivery. Browser warning/error logs are empty, with no document overflow. The capacity-stop browser capture is from before the three presentation/recovery fixes and is labelled historical; the unchanged model also tests the capacity limit. Native captures use 1280×720 and 844×390, not physical phone hardware.

The independent full review requested three corrections: downward recovery from a tilted tray, a pourback stream attached to the glass mouth, and clearance between the support caption and volume tags. One correction batch addressed all three. The limited follow-up inspected 45 refreshed captures and both final input reports, scored F1–F3 resolved, and returned `disposition: ship` for those fixes. It is not a new whole-surface or release approval.

The final focused native preflight passes five selected checks with 536 not run and no inputs changing during validation. Matching standalone import, startup and Web export pass. These results do not imply a complete native suite or production release.

Reproduce using the pinned `GODOT_BIN`:

```sh
node godot_native/samples/future_learning_center/run.mjs --pantry-test --headless
FLC_CAPTURE_DIR=/absolute/path/desktop node godot_native/samples/future_learning_center/run.mjs --pantry-input-test --resolution 1280x720
FLC_TOUCH=1 FLC_CAPTURE_DIR=/absolute/path/mobile node godot_native/samples/future_learning_center/run.mjs --pantry-input-test --resolution 844x390
node godot_native/samples/future_learning_center/run.mjs --test --headless
node godot_native/campuses/future_learning_center/tools/build_room_puzzle_review.mjs
```

Input tests use real elapsed time and ordinary pointer/finger gestures to fill and deliver all four glasses. When macOS focus interruption closes the valve, the harness explicitly restores focus and reopens the physical valve through input; the game never resumes itself. No model writes or fast-forward prepare the cups. Browser acceptance is separate from native checks and full release acceptance.

No new raster assets are used. Native glass, water, spout, valve and basin meshes inherit the incumbent camera and material system. DESIGN.md and `.impeccable/design.json` remain authoritative and unchanged.

The fresh documenter inspected 29 representative final captures and saved source/validation records. Its comparison preserves the incumbent system and records the pantry's local feedback text size and tray-settling coefficient separately. Both design-file hashes match the starting values. The comparison lives in `documentation_review.md` and `documentation_review.json` beside the other local evidence; it does not widen the limited fix verdict or rewrite the normative design files.
