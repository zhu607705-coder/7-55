# Chapter 3 source-sized actors, clues and promo choreography

## Authority and scope

`tools/export-c3-world-source.mjs` reads the unchanged original `CanteenInteriorScene.ts` and `TheaterInteriorScene.ts` AST. It exports 16 literal placement/dialogue constants and 34 original image imports with source hashes into `data/native/chapter3-world-source.json`. Shared player geometry continues to use the tested `player_metrics.gd` source contract. No replacement character/map assets are generated.

`ui/chapter3_world_layers.gd` is presentation-only. It exposes `sync`, `tick`, `draw_back`, `draw_front`, `adjusted_collisions` and `handles_target`. Shared world supplies the actual runtime `narrative_session`. Rendering partitions source depth against the player, with original counter/table crops. It never writes source quest fields.

## Implemented consumers

- All 31 canteen light NPCs: four counter workers, twelve queue students, eight seated students, six extra seated students, and one return worker. Original 96×128 sheets use uniform .65 scale, bottom-center anchors, frame-pair idle rates/delays, and light/dark visibility fade
- Original shadow auntie and seven-frame-index flicker pattern in dark mode; ordinary NPCs disappear. The twelve queue students and return worker have original 19.5×14.625 foot colliders only while the source light NPC mode is active. Third-column colliders move with its 36-pixel retreat and disable during the wave
- Original counter front and seven occupied-table crops keep bodies behind the source furniture while heads/arms remain visible
- Carried tray appears at player(x,y−48), .75 scale using the original generated 24×18 tray geometry. Pickup follows its original 360 ms (100 reduced) Back-in motion
- Return-worker interaction now matches the actual source NPC at (1515,610), stand (1466,608), radius64. All six queue/four seated/one counter optional original conversation strings are reachable through the existing timed source dialogue owner, using source shuffled placement and source phase/mode availability
- Theater inspector idle/scan assets at the original fixture offset, procedural ticket reader, two unchanged fixture collision rectangles, and a separately removed admission gate
- Source program scraps are 48×48 and phase-gated; dark glow and collection flight use source timing. The generic target renderer is suppressed for those scraps to avoid duplication
- Original prop/manager ghost assets, alternating manager poses and clue text appear only under their source dark/phase/unread conditions. Paper uses original flight0/residual/fluorescent variants and source idle motion; dark future-path, poster-half and light-only delivered-ticket receipt clue are distinct
- Root's `presentation/interior_door_layer.gd` reuses the exact source leaf crops and double-fold timing. Portal draws behind actors; leaves draw ahead of the actor and before the original foreground frame. `RpgInteriorDoor.ts` has no physics collider, so no new door collision is invented

## Promo sequence and source callback

`presentation/c3_promo_timeline.gd` is a pure source-derived presentation model. Its normal timings preserve `Math.round(normal*1.286)` at each original beat; total3999 ms, reduced1040 ms. The shared narrative host owns the camera from the actual starting camera through the promo board and third queue, then returns to the current player. Source ordinary walking remains available; interactions remain locked.

The world layer consumes actual timeline snapshots for empty-cup flashing, 10fps four-frame insertion, active-board reveal/flash/scale, 6fps bubbles, glow, first-student turn sprite, three staggered prompt frames, queue positions and collision disable/restore. Nothing is reconstructed by prematurely setting story flags.

Placing the drink consumes the item and sets only `promoDrinkPlaced`. At the original visual boundary, the host submits `c3_promo_visual_complete` with the identical controller-issued `c3_narrative_session`. The controller rejects dictionaries, foreign, stale and early sessions; only the authentic boundary sets `queueGapOpened` and `menu_order`. The same session then presents the two original queue-shift lines. Only their terminal `c3_story_complete` releases interaction. A saved interrupted promo reconstructs its original220 ms scene-start delay and does not consume another drink.

## Verification

- `export-c3-world-source.mjs --check`: 16 constants/34 source asset imports match original files
- `test_chapter3_world_layers.gd`: 129 checks covering actual assets, NPC counts/anchors/sheets, 13 NPC colliders, dark/defense visibility, source crops, carry/promo states, phase-only theater props, original optional NPC strings and interaction reachability; render calls do not mutate state
- `test_chapter3_promo_integration.gd`: 24 actual Main/State/world tests covering timeline layers/camera, all three collision changes, exact3999 ms callback, two later source lines, forged/foreign/early rejection, one-time consumption, save validity and interrupted recovery
- `test_c3_promo_timeline.gd`: independent pure source timing/model tests owned by the root integration task
- `test_interior_door_layer.gd`: source leaf timing/proximity tests owned by root integration
- Existing `test_chapter3.gd`72, narrative140, narrative-shell25 and audio-wiring43 checks pass with these layers integrated

Graphical captures and manual traversal remain separate acceptance evidence. The separate `c3_reversal_view.gd` now supplies the1320 ms original screen-space reveal; the shared narrative owner controls its2-line/inspector/3-line sequence and verified callbacks. Its42 actual Main/save/layout checks complement these layer tests. Shader-exact SCREEN blending, every pointer hover tween, and pixel-identical Phaser text rasterization are not claimed by these tests.
