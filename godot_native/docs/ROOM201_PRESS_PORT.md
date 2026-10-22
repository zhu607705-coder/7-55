# Room201 physical plate press

## Bounded route and source audit

Source audit base: `b2efa273b47e6b1d4e2de12efc6440aacb3b9e02`. Integration base: `29d979b585b9ee0ea08a8dd795122907f1c325a5` (`godot-version`), preserving merged Library PR79 and charging PR80.

The original native controller accepted `c4_solve_positioning_calibration` from a numeric answer without owning `items.clockPositioningPlate`. Its Room204 objective ordered calibration before the plate became available. This batch corrects that causal order:

1. Keep the original A1 investigation, elevator calibration/ride, A3 reference and four-level stair campaign
2. Restore Room204's original four furniture groups and complete its original projection
3. Collect the existing `clockPositioningPlate` from the podium drawer
4. Insert that same plate into the Room201 press, move its two rails and wind its spring, then pull the lever
5. Return using the existing elevator/stair routes and install the same plate in the A1 old clock
6. Use the existing native clock selector to stabilize `2245_maintenance`

The clock selector is an analog face with discrete detent controls and keyboard selection. This batch does not claim to add a pointer-drag clock. Room203 topology, evacuation-route evidence and elevator stop-chain requirements still gate installation. No new inventory item, unrelated fetch step, transport shortcut, blackout, chase or ending logic is introduced.

## Physical interaction contract

`room201_press_model.gd` is a pure bounded checkpoint model. The optional `native.c4_plate_press` stores version, plate insertion, horizontal/vertical/pressure settings and validated imprint status. Values derive from the original `chapter4-device-source.json` calibration ranges and registration. Object input submits `c4_plate_press_event`; only the Chapter4 controller mutates the checkpoint. Final `c4_solve_positioning_calibration` requires the owned plate and collection fact, original source registration, inserted checkpoint, correct time/floor/phase/mode/context and earned stairs.

The original completion fact is `a2_positioning_plate_calibrated`. Preparation and animation cannot grant it. A failed press preserves accepted adjustments and the item. A successful press retains the item for A1. Repeated collection, calibration and installation cannot award an extra item or fact.

The scene uses a plate/carriage, two orthogonal screw rails, a winding wheel and spring, and a wooden-grip pull lever. Three contact scars and one worn spring groove provide visual evidence without a numeric answer form. Pointer drag, touch, keyboard arrows, Q/E and Enter share controller intents. Escape, Return, focus loss, resize, authority changes and modal replacement release input ownership. Main reuses the existing Room302 exclusive fullscreen lifecycle; the underlying world camera/input and shell are restored on exit.

## Art and review status

The production candidate uses six additional generated PNG layers from the reviewed Room201 concept. The original `chapter4_a2_calibration_jig_v01.png` was inspected first: gunmetal frame, brass fixture, three contacts and orthogonal screw rails. The authoritative owned item remains `钟面定位片`: a transparent sheet with two short edge ticks. Brass belongs to its fixture, not a new inventory item.

`room201_press_art.gd` assembles native Sprite2D parts with explicit atlas regions and uniform registration. The stationary scene excludes moving actors. The transparent sheet preserves its real interior alpha. Low-alpha canvas strays below4/255 are discarded. Portrait layout deliberately rearranges independent parts instead of shrinking the full landscape machine into tiny controls. Visible knobs, wheel and lever own matching hit regions; operative labels retain at least14 screen pixels. Wheel picking inverse-transforms the actual rendered pose and samples its alpha silhouette with bounded padding, including outer rims at different pressure angles.

The generated down-pose attempts shifted the fixed pivot and were rejected. Only the usable up image supplies the fixed housing, rotating lever, ram, spring and platen parts. Native transforms produce exactly three pose families: idle/up, down/contact, and released/rebound. No generated rebound asset is claimed. A renderer test samples actual opaque platen pixels at all three calibrated contacts rather than relying on its rectangular bounding box. `assets/objectized/chapter4/room201/asset_provenance.json` records unchanged PNG hashes and alpha bounds. No original asset is overwritten.

## Save compatibility

The new checkpoint is optional. Old completed calibration facts are accepted unchanged without backfilling fictional press history. Present malformed checkpoints reject the ordinary snapshot. Partial insertion/rail/spring positions survive the actual State save/reload path. Gesture state, animation clocks, press requests and live callbacks are never serialized. Native snapshot validation does not synthesize transport/stair proof.

## Verification boundaries

`room201_projection_entry.json` is an isolated acceptance fixture. It retains prior native transport, stair replay and Room204 projection evidence and removes the old pre-plate calibration fact. It does not seed the new plate or press checkpoint. Tests earn those through ordinary controller actions. It is not evidence of a new human playthrough from chapter start.

Executed focused checks:

- Room201 authority and ordinary save round trip: 223
- Room201 native Main/root input including old-clock controls and legacy pre-pickup state: 67
- Room201 pointer/lifecycle and bounded layout: 49
- Native generated-layer renderer, opaque-contact coverage and wheel-rim picking: 389
- Compact production device navigation: 1170
- Original Chapter4 controller chain: 117
- Shared device compatibility: 2462
- Room302 authority: 279; Room302 Main lifecycle: 80
- Post-stair original transport: 78
- Projection and revised task order: 60

All listed checks passed with zero failures. The continuous native chapter1–4 campaign also passed (not a manual playthrough; a preexisting floor-panel anchor warning remains). Actual graphical fixture captures at1280×720 and390×844 cover insertion, idle, lever-down, failed rebound, calibrated contact, embossed rebound, completion and the original A1 clock after22:45. Both final graphical runs pass8/8. An earlier desktop run lost native window focus and could not finish the original timed elevator; that failed evidence is excluded. The QA helper now waits for genuine focus, logs it, and never labels a failed arrival as an A1 completion. An independent review found and prompted a fix for legacy calibration preceding pickup: the scene now preserves the fact but shows an empty press and204 guidance until real ownership exists. Combined post-rebase Library1729, charging147+53 and Room302 Main80 checks pass. Independent review cleared the final functional and visual changes, including the wheel-rim correction and61 additional padding-boundary checks. Aggregate and exact-head CI/publication receipts are tracked in the pull request. `capture_room201_press.gd` is an explicitly source-seeded real-Main graphical fixture. It uses native root events and freezes only presentation time to capture key poses; it is not a manual navigation claim.
