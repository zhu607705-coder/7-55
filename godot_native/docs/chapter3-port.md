# Chapter 3 / 3.5 native port

Source revision: `39ccde029b0cd25a6011739a4e4f98f8c898b2c3`. Original web code is unchanged. Native state uses the full original initial dictionary, never an alternate chapter-only save. Rules are in `scripts/chapters/chapter3.gd`, `c3_lake.gd`, and `c3_interlude.gd`.

## Implemented progression

- Canteen: independent tray and drink branches; twelve randomized physical trays, one carried tray at a time, exactly three dirty trays award 200 cents and reusable tissue; source-order drink mixing, failed drink item and repeat acquisition, promotion/queue opening; A–E menu with actual wrong meals and reordering; per-meal pickup windows and consumed ticket; active 60-second moving pushcart defense (source `CanteenDefenseRuntime`), with legacy three-cart completion removed; tissue cleaning retains tissue, 200-cent ride consumes wages. Light operation does not require dark observation. Dark observations never move items.
- The 755m chase result requires the shared native `ChaseStunt` deterministic input replay before completion. A fabricated distance/lives dictionary cannot advance the chapter.
- Theater: CC98 posted/accepted/failed/delivered ticket commission; campus Wi-Fi fails, cellular succeeds on either release wave; receipt code verification at the physical kiosk; poster tissue consumption and two-half ticket combination; retained admission ticket, three program pickups, correct order consumes fragments and grants remote; ticket scanner consumes ticket for brush; vent consumes brush; console consumes remote. Observations remain independent of physical actions.
- Spotlight: `c3_spotlight_model.gd` is a direct deterministic port of `TheaterSpotlightModel.ts`: 50ms steps, same food points, moving chairs, 60-tick delayed shadow, third-act wind/eye, nine-tick dash, 100-tick cooldown, 36-tick damage protection, 1600-tick timeout, exit-before-hazard precedence, three acts. Chapter rules replay every input. `c3_spotlight.gd` supplies keyboard/touch, start, focus-loss pause, progress and terminal result.
- Lake location: wet program is used independently at CC98, catalog and WeChat; three collected source keywords must be submitted to the map; only all three unlock the lake.
- Four lake source zones retain separate target coordinates, player vehicle and checkpoint fields. Dock equipment, weather warning, actual forced-launch stroke session, rescue to dorm, hair dryer, cloud-control puzzle and actual boarding session precede free traversal. `c3_weather.gd` ports source cloud initial/target positions, wind speeds, 30-unit control velocity, 50ms maximum step, ±8 tolerance, three deliberate controls and one-second stability requirement.
- Requested ordered fishing chain is preserved: decoy + rod → key catch → dock locker/cord → net-frame catch → cord/frame net → feed tin retrieval → pellet extraction → fish catch → swan exchange → magnetic rod → paper catch → channel chase. The later source convenience `completeSwanBranch` shortcut is deliberately not exposed. All four catches require a single-use, runtime-only session plus full `lake-rhythm-v4` replay validation. Failed/cancelled/forged results never transform items. Observations are optional assistance, not a light-mode prerequisite.
- Kayak tutorial, travel and 1000m chase validate `kayak-strokes-v1` input replay; phase/session/target/goal must match. Tutorial accepts recovery from earlier wrong/reverse strokes when the final four strokes alternate correctly. Chase completion consumes magnetic rod, breaks attachment, restores dock and starts phone recovery.
- Phone battery uses shared State app-open/network costs and a theater-only physical recharge target. The nonmodal station transaction waits the exact 2200ms (maximum100ms credited per frame), cancels on distance/mode/focus/phone/dialogue/minigame changes, then rechecks source geometry before restoring45%. A private runtime capability prevents forged or repeated recharge callbacks. Source prank presents the exact10-second warning followed by3.5seconds of “吓吓你的”, only after a debit at the existing1% reserve; it never changes battery or navigation. Recharge/developer reset rearms it.
- Chapter 3.5: journal closeout preserves exact source enum choices; seven original recovered photo frames including mirrored decoys; exact photo and voice order validation; exact source audio manifest references; official notice, correct unordered message pair, freely saved candidate network record; all four sources before old-time rejection; all three source/reason matches, frozen-clock rejection and correct network/destination matrix before replay. Replay only sets `replay_ready`/`replayUnlocked`; Chapter 4 performs its own entry/completion.

## API and presentation

The facade implements all methods in `PORT_CONTRACT.md`. Physical operations recheck scene/proximity, use full source rectangles, and preserve authored stand points for fixtures whose source stand exceeds the nominal center/edge radius. No facing gate exists. Target item fields require the correct inventory selection for light-mode physical use. Page forms never expose a direct minigame-success button.

- Specialized Control games implement `setup(Dictionary)` and `finished(Dictionary)`
- Spotlight request uses `script: res://scripts/games/c3_spotlight.gd`, plus round and attempt
- Weather request uses `script: res://scripts/games/c3_weather.gd`
- Interlude media returns `media:{command,session,on_event}`; `scripts/media/c3_media_host.gd` owns actual AudioStreamPlayer playback, and only the exact controller-issued `c3_voice_session.gd` object may acknowledge evidence
- Actual sampled playback must cross80% before `c35_listened` is persisted. Pause/resume retains actual offset; source sound-event excerpts seek to start−180ms/end+220ms and never earn full-clip audition. Leaving the page/focus stops playback. Early/forged/stale callback dictionaries cannot award evidence
- Missing media uses a timed readable rendition of original sound-event captions, matching the source's independent preview clock while recording `c35_reviewed` separately. It never claims absent audio was heard, and selection remains available after the source threshold
- Charging requests a nonmodal `world_effect` with `c3_charging.gd`, private session, and `on_event:c3_charge_result`. Host supplies `read_state` with transient `native.host` context and a source-to-overlay `project_position` callable
- Optional journal capture requests carry a runtime-only `c3_capture_session.gd`. Host provides actual visible-world framebuffer pixels; exact session identity, source position/zone, readable PNG and recipe are validated before saving a photo. Source recipe fields and actual `nativeCapture` camera metadata are kept distinct
- Target art uses `art`, `art_size`, `art_offset`; mirrored recovered frames use `mirror_art`
- Native tray/branch/swan SVGs under `assets/native/chapter3` transcribe the original Phaser procedural primitive geometry. They are derived source presentations, not replacement background art

## Verification

`tests/test_chapter3.gd`: 72 assertions passing under Godot 4.6.3. It runs the complete controller chain from canteen through Chapter 3.5, with source 60-second defense plus all three spotlight acts driven by an input solver, 755m chase/four fishing catches/rain/boarding/travel/chase driven by replayable physical-input fixtures. It also checks distance rejection, no dark prerequisite, idempotent rewards, wrong food/order/source behavior, forged terminal rejection, single-use rhythm sessions, weather stability threshold and destination conflicts.

`tests/solve_spotlight.gd` regenerates three winning spotlight traces from real input simulation. Shared `tests/test_minigame_models.gd` owns the chase/rhythm/kayak fixtures.

Example:

```
HOME=/tmp/c3-godot-home XDG_DATA_HOME=/tmp/c3-godot-home XDG_CONFIG_HOME=/tmp/c3-godot-home XDG_CACHE_HOME=/tmp/c3-godot-home godot --headless --path godot_native --script res://tests/test_chapter3.gd
```

`tests/test_chapter3_phone_ui.gd`: 51 native UI checks passing: all eight app surfaces construct; full interlude is completed through actual native Button signals (photo selection/order, voice audition/selection/separate-order stage, official notice, route message pair, network candidate, three decoy reasons, destination and replay). Selection and filtering are verified not to auto-complete story evidence. Voice selection in this route now waits for real AudioStreamPlayer auditions, rather than clicking a completion shortcut.

`tests/test_chapter3_media.gd`:29 checks pass for actual playback, pause/resume, event seeking, invalid/stale callback rejection, unavailable-media review, navigation cancellation, the exact station transaction and battery-prank boundaries.

`tests/test_qizhen_journal.gd`:105 source-oracle and transaction checks pass. See `QIZHEN_JOURNAL_PORT.md` for fixture provenance, source caption/assistance nuances, and capture API.

`tests/test_qizhen_journal_save.gd` is a separate shared-State integration regression. At this module handoff it exposes4 failures in the shared null-template schema, which rejects legitimate photo/draft dictionaries. The shared-state owner is repairing this; do not count this test as passing until rerun against that repair.

All chapter/support scripts pass `--check-only` parsing.

## Remaining fidelity work / known differences

This is an implemented progression port, not a claim of finished source presentation parity.

- Eight source-specific phone pages now use `scripts/ui/chapter3_phone_pages.gd`: recovery, journal closeout, seven-frame photo grid, voice memo list/order, official notice, message selection, three-filter network records, and CC98 ticket commission/archive. These are native Control reconstructions with original content/assets. Source CSS colors, pixel-style hard borders, card shadows, 286px investigation ring geometry, 14px app padding, shuffled voice catalog order, and manifest waveforms have been translated to native controls. Pixel-matched screenshot parity with the original React app is not yet established
- Active canteen/theater dialogue queues and the theater-to-lake approach now have native sequential source-line, timing, voice, input-lock and acknowledgement consumers. The auntie task and approach seen flag wait for their original terminal callbacks; defense victory includes all three escape lines and automatic campus exit. See `CHAPTER3_NARRATIVE_QUEUES.md` for the 21 source-executed schedules, lifecycle tests and remaining animation-specific limits. Canteen entry is separately implemented in `CHAPTER3_SCENE_TIMELINES.md`. Source promo/queue choreography,31 canteen NPCs, carried trays, theater dynamic props and exact door leaves now have dedicated consumers and actual-shell tests in `CHAPTER3_WORLD_LAYERS.md`. Theater reversal now has the exact1320 ms source physical reveal and actual2-line/inspector/3-line lock, with actual-save interruption tests in `test_chapter3_reversal.gd`
- Spotlight now reconstructs the active TheaterImpossibleShow source stage, characters, hazards, source overlays and result lifecycle with native drawing;30 actual Main/State/input tests pass. Exact raster comparison remains pending (see THEATER_NATIVE_PRESENTATION.md)
- Swan SVG is a source-derived static pose; full wing/wake/depth animation remains shared-renderer work
- Four-zone lake world collision/vehicle rendering is shared-host work. Travel/chase minigame uses the shared bounded native simulation; that does not establish complete source-map visual/collision parity
- Lake journal source recipes/tags, constrained titles/statuses/captions, seeded floor/reply projection, duplicate handling and close/retake rollback are now implemented by `c3_journal.gd` with source-oracle tests and separate native UI. Actual shared-host framebuffer capture and schema-aware save integration need end-to-end rendered validation; source recipe framing must not be confused with an un-reframed viewport image. Source assistance fields have no production writer/consumer, so the native port does not invent rewards
- The memo UI now includes real80%-playback gating, pause/resume, separate selection/order stages, source event chips and exact bounded seeks. Entire chapter presentation/audio cue graphs are still not wired
- Full desktop/mobile visual and save/reload QA remains necessary. Passing controller/model tests does not substitute for that QA
