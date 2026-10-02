# Chapter 4 native port: implemented contracts and remaining work

This is an in-progress native reconstruction, **not a completed fidelity sign-off**. Original TypeScript/React/Three.js source files remain unchanged. The native chapter operates on the complete serialized `createInitialGameState()` shape supplied by `data/initial_state.json`; it does not create a reduced chapter-only save or reset earlier chapter items.

## Source authority

- `src/modules/ChapterFourTemporalMazeController.ts` is the active 755 phase/fact authority
- `chapter4-755.content.json`, `chapter4-three-floor-maze.layout.json`, and the elevator timeline provide phase, prose, time, placement and source-pixel data
- `src/tools/chapter4-stair/{levels,engine,types}.ts` supplies all four projection levels and three camera definitions
- `ChapterFourAlumniHonorWall.ts` supplies the original portraits, biographies, university citations and final question choices
- `ChapterFourStarLampClosure`, `ChapterFourStarLampSequence` and `ChapterFourStarLampThreeRenderer` supply closure identity, explicit acknowledgement and the original five-layer artwork/timeline

### Conflicting source descriptions

The active controller still checks the duty-board, positioning-calibration, power-topology and evacuation facts and still exposes archive/media puzzles. It accepts the two Zhu question answers at `exterior_closure`, not at the A3 portrait. Some AGENTS summaries call the inserted UI retired and describe a prior Zhu-before-stairs gate. The native implementation follows the executable controller: it does not delete required causal facts or insert an extra early mandatory question gate. The honor wall remains an inspectable source-backed biography interaction.

The active `RpgInteractionContract.ts` group target predicate requires both A3 reference and A2 residual facts before furniture placement and sets proximity to 64 source pixels. This contradicts the older unordered-placement summary in AGENTS and the first native test. The native controller and targets now follow that active predicate; the original sources remain unchanged. Placement groups can still be completed in any order.

## Implemented

- Exact source chapter4 state keys, source phase/time contracts and preservation of all prior chapter state
- Source H3 prologue OGV playback, original Chinese subtitle timeline and source English voice/SFX/music manifest entries; explicit task-card confirmation after 43,834 ms or the original skip-to-card gesture. Escape/skip never commits the chapter. Replay resets video and owned cues. The original static fallback geometry/portrait cut-in is used for reduced motion or missing video with an explicit notice. Godot 4.6 video seeking keeps media within the source 250ms drift threshold against the 48ms-capped subtitle/cue clock. Missing audio does not own or prevent progress
- In-world 1,900ms original paper flight and seven-second paper closeup from `ChapterFourPaperPickupPresentation.ts`: original vector shapes, crease/perforations/barcode, time mismatch stamp, source Chinese prose and entrance/stamp/shrink/fade timings. Timed external-time rejection, original 4,700ms in-world clock inspection and clock-setting validation; cancellation/re-entry resumes unfinished evidence handoffs
- Source-coordinate bakery conveyor slats, bread trays, rails, rollers, status lamp and glint; original cropped auntie animation and three students with authored routes, speed, endpoint poses and pauses. Stop cues slow at 120ms, pause at 360ms, reveal the original hour-hand sprite at 520ms, and commit at 700ms. Physical hour-hand pickup and consumed installation retain the old time until the player adjusts the clock
- Independent 104 dark residual and 105 light replay facts
- Elevator history and six-second trace calibration in either order. Start time is validated as exactly 81811. A3 requires both classrooms, calibration and a distinct, timed elevator-ride transaction. A2 requires actual completed stair proof; phase names never grant transport facts
- Original A3/A1 honor-wall portraits and full source biographies/citations
- Native 3D four-level projection campaign, exact authored platforms/stair spans, transforms, nodes, physical edges, mechanism edges, three orthographic views, six-pixel seam test and opposing projected tangent test. Moving platforms retain their board-at-zero/ride/leave-at-two requirements. Input controls never directly stamp success. Full action logs are replayed by the chapter controller; all four exits and final traversal are required
- Native animated camera changes and mechanism movement, click-to-walk and WASD/arrow navigation, visible reset/return controls; source plaster/concrete/metal textures, 256px luminance quantization, original palette and world-density UVs, hard outlines, original eight-frame billboard character, source rails/nosings/decorations and sliding fire doors
- Four Room204 groups expanded to twelve original pair/slot entries. Source atlas frames, trims, pivots, 0.25 scale and rotated collision bounds produce four initial discussion tables/12 turned chairs, then 12 aligned desk/chair pairs plus the fixed podium. Original dark residual sprites stay behind actors. A short 480ms native interpolation makes relocation visible without changing destination physics or facts. Optional native dragging submits the same grouped intent as Space; the controller checks evidence, group, upward orientation, exact drop rectangle and real player foot-center proximity. All three full-width source aisles remain clear
- Room204 projection is automatically launched when the last required observation/placement completes the source composite set. Original screen at [245,519,110,56], four record fragments and partial door geometry use the 120/360/900ms misalignment/stability/commit sequence, composited at source depth; re-entry also retains a retry target
- Original device questions, choices and validators for duty board, archive index, media alignment, positioning calibration, power topology and evacuation route
- Three-floor door/call records and actual-arrival/unserved-call deduction
- Maintenance diagnosis and the original two-step tool chain; oil repairs both linked wheel and clock gear, consuming the original final-use items
- In-world final clock endpoint interaction with real pointer/touch/keyboard input, source 240ms hand tween, 680ms paper flight and 1,040ms controller commit. Cancelling before commit preserves clock state and paper. The obsolete generic clock-diagram activity is removed. Exact XOR light-grid masks and the lamp-primed-only handoff remain controller-owned
- Source maintenance cart/cleaner sprites with exact foot rectangles, the original failed five-pixel push cycle and 900ms repaired roll, rotated wheel cover and temporary oil reveal. Consumed tools cannot be regenerated by repeating diagnosis
- Original registered clock atlas plus independent blank-face/hands/gears; source five-region blackout overlays and power-panel atlas; source vector card reader/paper slot with accepted colors and original three morning students
- Source Room202 closed recovery barrier and original minute-shard sprite; arrival now atomically returns the original [1453,306] safe interior spawn and c4_a2_room202 checkpoint, and recovery reopens the route
- Actual keyboard/pointer-driven native chase stairwell on the original plate and exact authored walkable union. A pursuing guard uses the original authored graph with body-clear dynamic endpoints and 260ms repathing; stopping permits capture. Retry is local to the stair activity. A returned trace is checked for speed, walkability, both ordered landings and the exit
- 202 arrival, recovered minute/paper, return route, exact 07:55 restoration, order-independent card/paper acceptance and explicit exterior closure
- Registered closure consumer name `ChapterFourStarLampClosure`; questions are saved through the controller before playback. Re-entry shows saved choices for explicit confirmation. All five original lamp assets remain unaltered, with source reveal/rise/ignition timing and light levels; the native star field uses the same LCG seeds, 6,320 source positions and 44-degree perspective camera motion. Playback alone never marks completion; final acknowledgement is mandatory

## Terminal proof interfaces

Custom activities expose `setup(config)`, `completed(result)`, `cancelled`. In-world handoffs return `world_effect` with `blocks_input:true` and expose `setup(config)`, `event(action,value)`, `cancel()`. Their lock belongs to the live Control, never the saved state. Cancellation emits a nonce-checked presentation cancellation and cannot advance story.
Every controller-launched game includes a runtime session nonce; a result must match the pending action, phase and floor. No completion handler is exposed as a normal page action.

- Elevator alignment: `session`, exact `startSeconds`, `elapsedMs >= 6000`, `boarded`
- Elevator transport: matching session, originating floor and destination; `boarded`, `arrived`; elapsed at least `2720 + 620 * floorDistance` ms. A1→A3 is 3,960ms, A2→A1 is 3,340ms. The six original 72×96 door frames, 440ms door tweens, 420ms boarding/exit and 620ms-per-floor travel +120ms settle are presented before the controller writes the actual transport facts and fresh-native provenance marker
- Stair campaign: `kind: chapter4_stair_campaign`, `session`, ordered `levels[{id, actions}]`, `doorTraversed`; each action is replay-validated against the original projection graph
- Chase stairwell: matching `expectedAttempt`, `escaped`, time-stamped `path[{x,y,t}]`, elapsed duration; path must cross both original landing rectangles then the original exit
- Closure: saved valid `answers`, `consumer: ChapterFourStarLampClosure`, matching session, `playbackMs >= 5800`, explicit `acknowledged`

Runtime session nonces are deliberately not restored after cancellation/reload. Story facts and validated results persist; unfinished activities restart safely.

## Current fidelity gaps

1. Source-sized shared world guard simulation has been integrated by the shared-world owner: A1/A2 final-chase approaches and maintenance patrol now consume the native models. End-to-end visual/physical acceptance across the complete chapter still needs a fresh integrated run. Pure models and source 14px body-expanded A-star navigation are independently tested
2. Stair geometry, source materials/quantization, original player billboard, nonwalkable-wall ray-occlusion filtering, valid/invalid seam feedback, source decorative fixtures and continuous per-level reveal/breakup have native consumers. Full authored floating-fragment/energy-trace effect matching and visual screenshot acceptance still remain. The exact authored navigation solutions are tested; visual parity is not claimed
3. Room204 furniture, source collisions and projection compositing now have native consumers. Integrated screenshots/manual interaction still need acceptance; the 480ms group relocation easing is a native presentation addition, not an original source timing
4. Paper/bakery/projection/elevator/clock handoffs now run inside the world viewport with source artwork and authored timing. Elevator transit temporarily redraws the appropriate floor plate and door/player sequence; source decorative NPC/portrait overlays during that brief redraw and exact sound-cue alignment still need integration review. Six-second elevator calibration retains its native timeline control rather than every original near-view visual
5. Native lamp field/camera/artwork timeline is ported, but original CSS screen-blending, glow blur, color filters, vignette and question spark-dissolve animation are not yet pixel-matched
6. Device puzzles use native multi-field controls. Source SVG near views, topology previews and physical magnetic-tile drag visuals are not fully reconstructed
7. Central native save import now owns source-version migration; Chapter4 marks fresh native elevator completion only at the validated transport terminal. Imported provenance must still be checked centrally and must not synthesize missing transport proof
8. No rendered desktop/mobile screenshot acceptance has yet been established in this environment. UI construction smoke is not visual parity testing

## Data reproducibility

`tools/export-chapter4-data.mjs` deterministically exports original TypeScript constants using Node's TypeScript stripping and a minimal vector-data implementation. The generated **tracked** `data/native/chapter4-native-source.json` is separate from the copied, ignored `data/source/` assets. It contains no alternate story. Run:

```
node godot_native/tools/export-chapter4-data.mjs
```

## Verification

```
XDG_DATA_HOME=/tmp/godot-chapter4/data \
XDG_CONFIG_HOME=/tmp/godot-chapter4/config \
XDG_CACHE_HOME=/tmp/godot-chapter4/cache \
godot --headless --path godot_native --script res://tests/test_chapter4.gd
```

Current result: **114 chapter/controller checks, 17 guard/navigation checks and 24 world-layer checks, zero failures**. Includes a full controller chain from authorized interlude replay through final explicit closure; all four exact authored stair solutions; denial of fabricated/incomplete stair results, phase-only A2 access and incomplete closure; independent elevator-history/calibration order; active source Room204 observation/placement gates; item retention/consumption; exact pending clock swaps.

`tests/test_chapter4_guard.gd` additionally validates source cone/LOS, 400ms confirmation, 900ms sight-loss recovery, foot contact, four-frame/two-second chase arming, finish-before-contact, portal outcomes and collision-safe A-star detours.

`tests/smoke_chapter4_ui.gd` constructs all four native 3D stair levels and prologue/elevator/chase/clock/lamp controls. Construction completed without script errors. The final smoke also exits without leaked-resource errors after explicitly stopping media and allowing 300ms for the audio mixer to release its playback. This construction smoke still does not establish screenshot or manual gameplay acceptance.

## Shared-world guard integration API

`chapter4_guard_model.gd` owns pure calculations only. Each tick must start from the actual post-collision guard foot center; the renderer/physics scene applies returned velocities. `maintenance_step` returns source mode transitions and velocity. `chase_step` returns source arming, portal-transfer, failure/finish requests and velocity. `resolve_portal`, `resolve_finish`, `resolve_failure` acknowledge controller outcomes. Do not mutate chapter facts from the model.

`chapter4_guard_navigation.gd` exposes `setup(walls, width=1672, height=941)` and `path(from,to)`, plus `foot_open` and `line`. Cache the navigation instance per collision revision. Its 14px graph and 10×7 half-foot expansion follow the source navigation helper.

`c4_recover_patrol` and `c4_fail_chase {expectedAttempt,failureFloor}` return an explicit `teleport` for safe recovery. Failure preserves story evidence and items. The latter rejects stale attempts and uses source floor-specific retry checkpoints.

## World-layer integration

`chapter4_world_layers.gd` is a RefCounted renderer with `draw_back(canvas,context,state)`, `draw_front(...)`, `tick(delta,state)`, `collisions(state)`, `pick_drag(worldpos,state)` and `resolve_drag(payload,worldpos,state)`. Context contains `origin` (screen-space world origin), uniform `zoom`, source player anchor `player`, `scene_id` and `floor`. Furniture depth compares source anchor y; controller proximity uses the shared `PlayerMetrics` foot-center offset. Source Fusion font is loaded explicitly.

`collisions` returns native Rect2 values for visible furniture and bakery students. Group targets use the original content rectangles and proximity 64; residual bounds are [44,556,372,246] with proximity76; podium drawer is [179,549,41,52] with proximity60. Neither residual art nor projection glow creates collisions.

`tests/test_chapter4_world.gd` checks layout/entity counts before and after grouped placement, rotated table collisions, full-foot aisle clearance, source preferred-slot fallback, evidence gates, wrong group/orientation/drop, proximity, duplicate drops, old-duration transport rejection, fresh native provenance, three crowd colliders, and runtime cancellation cleanup. It samples native drawing of furniture, projection, bakery, paper flight/closeup and elevator phases without script errors. This is not screenshot fidelity acceptance.


## Independent fidelity fixes, 2026-10-01

Additional focused regression suites:

- `test_chapter4_phase_world.gd`: 37 checks for source prop transforms, failed/repaired push timing, live/reloaded repair, collision removal, recovery door, original atlas availability, clock modes, no presentation writes, repeated-diagnosis rejection, theft prerequisites, safe Room 202 arrival, 4,700ms inspection, 20 portrait assets and context-sensitive support dialogue
- `test_chapter4_prologue_media.gd`: 19 checks for missing/reduced-motion fallback, original portrait frames, skip/Escape/replay, single acknowledgement, skipped cue ownership, 48ms cap, and actual bundled OGV seeking/250ms resynchronization on Godot 4.6
- `test_chapter4_clock_handoff.gd`: 13 checks for actual endpoint pointer input, cancellation, keyboard gesture, no automatic progress while waiting, 680ms paper flight and 1,040ms terminal transaction

These suites execute native Godot drawing/media and controller code. They are not manual gameplay or pixel-equivalence acceptance. Scene-sized/zoomed screenshots and a continuous native traversal remain required. The maintenance tool-contact spark strokes, power-success light pulse/label sequence, exact fallback CSS shadow treatment and inserted device near-view controls remain fidelity gaps.

The 20 original A1/A3 honor portraits now have real native image consumers within their authored matte bounds (uniform fit preserves the original image ratio), together with animated front-desk/reference/elevator staff and original context dialogue. Final acknowledgement now returns the original three-line exterior exchange; minute-recovery and chase-retry result subtitles remain present.

`test_chapter4_lamp_lifecycle.gd` passes 12 checks and exercises actual first/second answer callbacks, saved choices, removal of question controls, natural process advancement and final acknowledgement. `visual_gallery.gd` uses this same controller-issued lifecycle and live playback for lamp captures, never direct stage/elapsed writes. It also captures seven source-checkpoint Ch4 prop views as visual-only DEV samples.

The phase renderer is `scripts/ui/chapter4_phase_layers.gd`, called internally by `chapter4_world_layers.gd`. The shared world continues using its existing draw/tick/collisions contract; the added cart/cleaner and Room202 barrier use that collision API without a separate state authority.
