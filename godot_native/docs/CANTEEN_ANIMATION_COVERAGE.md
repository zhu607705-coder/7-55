# Canteen animation coverage

Audit date: 2026-10-09. This ledger covers the complete scene, not only the six
numbered prop anchors. “Retained” means original multi-frame art and authored
behavior are reused and checked; it does not mean newly generated artwork.

The authority remains `scripts/chapters/chapter3.gd` and the source-derived
60-second defense model. Presentation never earns an item, creates a second
reward, changes a source departure threshold or substitutes a result for replay validation.

## Fourteen motion groups

Paths in the table are relative to `godot_native/`, unless prefixed `src/`.
GUI recordings use declared prerequisite fixtures with real controller input;
they are not claimed to be a manually earned full campaign.

| # | Motion group and source reference | Treatment / current status | Regression and visual evidence | PR |
|---|---|---|---|---|
| 1 | **25: scattered trays, pickup, carrying.** `src/scenes/rpg/CanteenInteriorScene.ts:animateTrayCollection` | Rebuilt: original idle/carried SVG endpoints plus seven generated registered poses; same 360/100 ms path | `test_canteen_tray_frames.gd` (1,325 checks), `test_canteen_pickup_continuity.gd`; actual pickup full/detail recordings | [96](https://github.com/zhu607705-coder/7-55/pull/96) |
| 2 | **26: return station / receiving auntie.** Original return branch and two-frame worker atlas | Rebuilt top-tray turn/contact/lay sequence; rigid stack. Retained worker pair, 320/160 ms and original reward | `test_canteen_return_stack.gd`, `test_canteen_native_objects.gd`; actual return full/detail recordings | [96](https://github.com/zhu607705-coder/7-55/pull/96) |
| 3 | **27: three dispensers.** Original machines, colors and controller drink-take branch | Rebuilt eight-pose filling closeup with separate source spout/backplate/grille. Immediate grant; optional 640 ms tail, stable 160 ms reduced | `test_canteen_drink_performance.gd` (1,363), `test_c3_canteen_devices_controls.gd` (3,492); all colors, portrait, repeat Take, owned reentry and Esc checked in native GUI | [96](https://github.com/zhu607705-coder/7-55/pull/96) |
| 4 | **28: mixer.** Original ingredient/recipe rules and reviewed separated native art | Retained approved layered mixer and completion continuity; no replacement in canteen batches | `test_canteen_mixer.gd`, `test_mixer_completion_continuity.gd`, `test_mixer_layer_separation.gd`; prior dedicated native acceptance and combined regression | [89](https://github.com/zhu607705-coder/7-55/pull/89), [93](https://github.com/zhu607705-coder/7-55/pull/93) |
| 5 | **29: promo lightbox / third queue column.** `animatePromoAndQueueShift` | Retained four insertion cells, three looping bubbles, prompt cells and turn pose; exact 36 px queue movement and source camera timeline | `test_c3_promo_timeline.gd`, `test_chapter3_promo_integration.gd`; native GUI insertion, queue retreat and camera return recorded through a real Space action | Existing native implementation; current audit |
| 6 | **30: ticket / auntie / package / burst / crowd handoff.** `animatePaperBurst` and original pickup sequence | Restored original five push, five shake, eight burst cells, ticket, 0755 slap and 31-actor crowd; exact 11.38 s sequence | Source execution oracle; 108 timeline, 122 rendered integration and 22 owner checks; actual wide and portrait ticket-to-defense recordings | [95](https://github.com/zhu607705-coder/7-55/pull/95), merged |
| 7 | **Arrival discovery / paper escape.** `prepareEntryPaperQueuePose`, `startEntryPaperDiscovery`, `playEntryPaperEscapeRoute`, `spawnEntryPaperAfterimage` | Retained rest + four folded-leg poses, source route/camera/dialogue. Restored source frame-2 ghost onset and blue tint; no new artwork | `test_chapter3_scene_timelines.gd`, `test_chapter3_scene_readability.gd`, paper command oracle; actual 12 s arrival recording verifies resting paper, folded legs, blue ghosts, turn and entry completion | [97](https://github.com/zhu607705-coder/7-55/pull/97), CI pending |
| 8 | **31 ambient light NPCs.** `createCanteenNpcs/createLightNpc/applyCanteenNpcMode` | Retained 62 genuine source cells: 4 counter + 12 queue + 8 seated + 6 extra seated + 1 return actor. Rates, delays, foot anchors, occlusion and 180 ms mode fades preserved | `test_chapter3_world_layers.gd`, `test_canteen_native_layers.gd`, `test_canteen_native_objects.gd`; crowd visible in pickup GUI; all-family full-room idle and dark/light restoration recorded in native GUI | Retained art; [95](https://github.com/zhu607705-coder/7-55/pull/95) crowd snapshot |
| 9 | **Shadow auntie / mode transition / four blue fibers.** `createDarkModeLayer/playModeTransition` | Retained shadow sequence `[0,0,1,0,0,0,2]` at 7 fps. Restored four source circles, stepped yoyo legs and fades; stationary reduced-motion points | Fiber model/view: 677 checks; original Phaser oracle: 516 samples. Independent review passed. 17 production Main/renderer checks pass, including phone and SceneTree pause; native GUI dark/light, phone return and reduced mode checked | [97](https://github.com/zhu607705-coder/7-55/pull/97), CI pending |
| 10 | **Order receipt feedback.** `src/modules/ChapterThreeCanteenController.ts:selectMenuOption`; `src/data/chapter3-canteen.audio.json` | Retained immediate ticket grant, dialogue and +420 ms print sound. **Original has no physical receipt/printing animation**; adding one would be a new enhancement | `test_c3_canteen_source_parity.gd`, `test_c3_canteen_devices_controls.gd`, `test_gameplay_audio_wiring.gd`, `test_audio_director.gd`; native GUI correct order and immediate ticket/dialogue checked; audio timing remains automated evidence (capture has no audio) | Existing source-faithful behavior |
| 11 | **Active pushcart defense.** `src/scenes/rpg/CanteenDefenseRuntime.ts`; `flashDefenseRoute` | Retained original four-direction × four-frame 314 px cells, directional pivots, 104/72 ms stepping and 60 s model. Restored frozen contact-route snapshot, even waypoint dots, 75/0 ms shake and 760/420 ms flash | `test_canteen_defense.gd`, source-model oracle, mobile/resume/owner regressions; full controller-validated campaign passes. Actual source-input replay records contact routes and frozen waypoints in both viewports | [95](https://github.com/zhu607705-coder/7-55/pull/95) native-room continuity; [97](https://github.com/zhu607705-coder/7-55/pull/97) source effects |
| 12 | **Defense running paper / impact.** `generatePaperRunTexture` and `CanteenDefenseRuntime.updatePaper` | Restored exact folded-leg drawing commands for four poses instead of body-only bob; existing heading, frame clock and 34 px recoil stay model-owned | 181 model/CanvasItem/transform/tint checks plus original drawing-command oracle; independent review passed. Both directions and frames 0–3, portrait/overview and pause/resume recorded; retry manually observed after recordings | [97](https://github.com/zhu607705-coder/7-55/pull/97), CI pending |
| 13 | **Defense victory paper flight / dialogue.** `animateDefenseVictory` | Restored frozen replay-derived run frame/flip/angle, quadratic flight and scale `(1.16,1.16) → (.28,.84)`; 760/160 ms flight + 260/60 ms hold | Existing narrative and world-return tests; 739 source-pose checks and 24 terminal-contact hold/pause checks pass; normal wide and reduced portrait real-time source-input replays both accepted by the unmodified controller; frozen frame 3 / flip true, full-room flight, all three visible dialogue lines and campus exit recorded; stale entry fade cleared only for accepted victory | [97](https://github.com/zhu607705-coder/7-55/pull/97), CI pending |
| 14 | **Southeast door / player departure.** Original door frame/leaf identity; `interior_door_layer.gd` | Eight true registered hinge poses ready; original closed endpoint and stationary frame retained. Existing 460/120 ms motion and 38% departure/passable threshold must remain aligned to measured visible aperture | `test_interior_door_layer.gd`; 4,267 raw art/aperture checks and 79 mounted renderer checks pass; real approach/hold/retreat, opening reversal, fully-open same-scene save reload, reduced portrait and timed source-replay departure recorded | [98](https://github.com/zhu607705-coder/7-55/pull/98), CI pending |

## Retained-source details

- Promo normal/reduced boundaries: insert 772/200 ms; reveal 1299/310;
  front-student turn 2238/550; camera return 3343/890; visual completion
  3999/1040. Source dialogues remain after the visual boundary
- NPC atlas dimensions: counter 768×128, queue 768×384, seated 768×256,
  extra seated 576×256, return 192×128. Each actor uses a 96×128 pair
- Arrival: source proximity radius 360 px; running frames every 78/120 ms.
  Normal run starts at 3200 ms and camera return completes at 7110 ms
- Pushcart atlas: original 1256×1256, sixteen 314×314 cells. A newer unused
  atlas is not substituted merely because it contains more cells
- Paper contact does not have a separate invented impact pose. Source retains
  the current run frame during its 34 px recoil and route-flash effect
- Neither source-only audio feedback nor retained source artwork is counted as
  newly generated art. Command parity is not claimed as pixel-identical GPU output

The door’s 38% threshold delays the scripted departure walk by 175/46 ms.
It is not a separate dynamic collision wall. Approach/hold sensors, ordinary
scene geometry and the authored departure route retain their original roles.

## Evidence and remaining acceptance

PR 95's exact tree and the combined 95+96 tree passed source oracles and targeted
regressions, including the continuous chapters 1–4 campaign. Required remote CI
and merge status are tracked on the PRs, not inferred from local test success.
Actual native previews and accepted generated source backups are delivered
privately through Library; no private conversation/account/download URLs are
included in this repository.

All fourteen groups now have scoped source and native acceptance evidence.
The source-effects and door batches are submitted as PRs 97 and 98 and await remote CI;
the whole rebuild is not yet marked delivered. Remaining visual polish: the
existing bottom instruction HUD obscures part of the southeast doorway. The
actual recordings preserve that overlay. Portrait retains a small source-logical
full-room view; this is not a claim that all mobile visual adaptation is complete.
No physical-mobile hardware or audio
listening test is claimed.

The victory recordings are explicitly **automated source input replay**, not
manual wins. They feed the original 3,600 inputs through the normal game input
fields at real-time 60 Hz, then use the ordinary finished signal, controller
proof validation, narrative and departure. Active simulation time was 60.027 s
(normal) and 60.008 s (reduced portrait); the latter includes a separately
recorded human pause/resume. All three authored lines were visible in order.
Manual movement, pause/resume and retry were checked separately in both viewports.


The final source-camera regression passes 1,122 checks. Removing only the world
camera-owner hook in a temporary test runtime causes 144 failures; restoring it
returns a clean pass. The original source camera block and actual exit method
are executed by the oracle. Live native recordings retain the original full-room
zoom through the flight and use no entry fade over the short reduced animation.

A separate scripted lifetime diagnostic ran 12 scene round trips, 12 mixer
open/close cycles and 12 full fixture reconstructions in both headless and GUI
modes. All completed with zero orphan nodes; retired watched instances released,
and GUI texture memory returned from about 353 MiB active to 29–30 MiB after
teardown. An earlier capture process was terminated by the host; its cause was
not established and was not reproduced by this finite probe. This is not a claim
that every possible memory path has been exhaustively proved leak-free.
