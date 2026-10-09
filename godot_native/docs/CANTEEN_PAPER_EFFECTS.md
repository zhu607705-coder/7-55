# Canteen entry afterimages and contact effects

Scope: native presentation from the original `CanteenInteriorScene.ts` methods
`playEntryPaperEscapeRoute`, `spawnEntryPaperAfterimage`, `finishEntryPaperEscape`,
`flashDefenseRoute`, `startDefense.onTurnaround` and `finishDefense`.
`CanteenDefenseRuntime.updatePaper` remains the contact authority. No controllers,
source art commands, collision dimensions, route selection, RNG, input proof,
60-second defense duration or story writes change.

## Restored contracts

| Effect | Normal | Reduced motion |
| --- | --- | --- |
| First entry afterimage | Frame2 at156ms | Frame2 at240ms |
| Following entry afterimages | Every156ms | Every240ms |
| Ghost lifetime | 220ms | 90ms |
| Ghost geometry | Capture paper position, angle and current frame; scale0.82 shrinks by0.82 | Same |
| Ghost color | Multiplicative tint `#bdefff`, alpha0.24 →0, linear | Same |
| Contact route flash | 760ms | 420ms |
| Contact shake | 75ms, intensity0.0025 | Disabled |

The route flash freezes the paper's post-recoil position and new route at contact.
It never drags its start with subsequent paper movement. Its5px line is `#78ddff`
at0.88 opacity. Only even-index route waypoints receive radius5 `#dff9ff` dots at
0.9 opacity. Both multiply the graphic's0.95 →0 linear fade. A fresh contact
replaces the old path and restarts the fade, matching `killTweensOf` and `clear`.

Ghosts use the controller-issued session clock. Focus pause/repeated paint cannot
advance or duplicate them. Coarse samples reconstruct crossed even timer callbacks
at their authored route position and age. Reset, rewind, cancellation and scene exit
clear old sprites; escape stops new emissions and allows existing sprites to fade.

Defense presentation observes each accepted model step and stores only its own
copied route and effect clocks. Pause freezes these clocks. A failed attempt can
finish its fade during the1150ms retry wait. Both manual/automatic retry clear
visual state. A final-tick contact survives the existing victory hold and fades on a presentation-only clock. Pause/focus loss freezes the hold and effects; resume continues them without stepping the terminal model. Expiry or exit clears the contact flash and camera shake.
The model's historical760ms `route_flash` is untouched, including reduced mode.

The75ms shake uses stable presentation-only noise rather than consuming the model
or global random stream. Its bounds and camera composition follow Phaser's
`Shake.update` and `Camera.preRender`: intensity × viewport size × zoom, pixel
rounding, then camera zoom. Random samples are intentionally not claimed to match
Phaser's unseeded `Math.random`. There is no invented decaying envelope.

Desktop, landscape compact, portrait close view and portrait overview share one
source-world geometry. Each camera supplies its own viewport/zoom. Its room,
route, cart and paper receive one common translation. Overview annotations use
that same offset. HUD and controls remain stationary; simulation coordinates and
input proof are unchanged.

## Verification

`CANTEEN_SOURCE_ROOT=/path/to/original node godot_native/tests/verify_canteen_paper_effects_source.mjs`

This executes the original TypeScript entry and flash methods in a small test-only
scheduler, then launches an asset-free headless native test and compares the
first ghost's source position/angle/frame/scale/tint and half-life geometry.
It checks native lifecycle, repeated contacts, reduced duration, all four camera
compositions, original Canvas draw calls and normal/reduced complete3600-tick,
82-contact proof/RNG equivalence. No browser, GUI, asset import or copied textures
are needed. `CANTEEN_EFFECTS_SOURCE_ONLY=1` skips Godot for source-only review.

The native tests are `tests/test_canteen_paper_effects.gd` and the direct-host terminal-contact regression `tests/test_canteen_defense_terminal_effects.gd`; the aggregate native
validator automatically discovers `test_*.gd`. The source oracle is registered in the
aggregate oracle list. It requires the shared `Paper.draw`
optional `axis_scale` and `tint` arguments appended after `parent_transform`.

Pixel screenshots and real-device input are separate integration checks; these
headless/source tests do not claim a complete manual visual pass.

## Integrated acceptance, 2026-10-09

The original-method oracle and all 96 native effect checks pass, including full
3,600-tick / 82-contact proof and RNG equivalence. The direct-host terminal
contact regression passes 24 checks. The original folded-leg draw oracle and
181 shared paper-art checks also pass.

Real native arrival footage shows the restored blue ghost and folded-leg motion.
Desktop and portrait manual footage covers both run directions and all four
model frames. Pause freezes the recorded paper pose and model tick; resume
continues. Retry was manually observed after each recording, not within it.
Two complete real-time source-input replays record the active contact effects,
controller-validated victory, visible dialogue and ordinary departure. They are
explicitly labeled automated replay rather than manually won gameplay.
