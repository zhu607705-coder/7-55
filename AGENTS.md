# 7:55 Project Rules

## Structure

- `src/scenes/phone/`: phone scenes and scene-local interaction state.
- `src/components/`: shared phone-shell controls only.
- `src/assets/ui/`: bundled visual references used by scenes.
- `src/core/`: shared game state, routing, and types.
- `src/styles/`: shared tokens, shell layout, and scene-specific styling.
- `godot/`: archived implementation reference from the retired Godot migration; active builds, runtime selection, CI, and new feature work must not depend on it.
- `src/integrations/godot/`: archived compatibility code only; active application code must not import or mount its frame, loader, or scene-specific panels.
- `demo/index.html`: generated standalone game build; do not edit it by hand.

## Runtime Engine Decision

- On 2026-08-09 the product selected one browser-native runtime. React and TypeScript own the phone, shell, shared state, controllers, saves, task UI, inventory, audio direction, and presentation overlays; Phaser owns the campus map and landscape RPG interiors. The Chapter 4 misaligned-stair puzzle is the single approved Three.js rendering exception: it mounts inside `RpgGameHost`, replaces the Phaser surface while active, and still submits completion through the TypeScript Chapter 4 controller.
- The active scope includes campus, dorm, library, east canteen, theater, Qizhen Lake, the teaching building, and future landscape exploration scenes. Portrait phone pages and portrait mini-games continue in the React/TypeScript application; Phaser may also own canvas-based portrait mini-games.
- `RpgGameHost` mounts one active game surface. Phaser remains mounted for normal RPG scenes; while the Chapter 4 misaligned-stair puzzle is active, Phaser is paused and hidden and one Three.js canvas takes over the same `960 × 540` logical viewport. HTTP, deployed, offline single-file, desktop split, and mobile layouts use the same controller state and viewport contract.
- TypeScript `GameState`, controllers, `SaveStore`, `selectFeatureAccess`, and `selectQuestViewModel` remain the only progression authority. Phaser scenes render state and submit engine-neutral domain events; they must not own a second save, wallet, inventory, quest graph, or story controller.
- Shared runtime ports remain valid scene boundaries for state reads, intent writes, event subscriptions, viewport data, and checkpoints. They serve the Phaser scenes directly and must not introduce a second engine-specific gameplay path.
- No new Godot scene, export, synchronization step, CI check, runtime loader, iframe, compatibility panel, or migration task may be added. Existing Godot files remain historical reference material until an explicit cleanup request removes them.
- `demo/index.html` is the canonical distributable game and must exercise the same Phaser runtime as the Vite development build.

## Naming

- React components and exported types use `PascalCase`.
- Functions, state fields, and CSS utility classes use clear English names.
- Screenshot-backed assets use descriptive snake_case names.

## Canonical Phone Viewport

- Every phone scene uses one logical viewport: `430px × 860px`. This compact `1:2` frame is the shared presentation baseline for desktop and mobile.
- `PhoneShell` is the only owner of phone width, height, responsive scale, frame border, and outer centering.
- Scenes must fill the shared viewport with `width: 100%` and `height: 100%`; a scene must never change `--phone-width`, `--phone-height`, `--phone-scale`, or the frame aspect ratio.
- Reserve the top `40px` for the shared status bar. App headers, scroll regions, fixed actions, and bottom navigation must stay inside the remaining scene area.
- New app pages use native React/CSS layout with flex/grid and stable internal dimensions. Text, cards, icons, and controls must not resize the outer frame.
- Reference screenshots are visual guides. Do not use `object-fit: fill`, unequal `scaleX/scaleY`, or any other non-uniform image transform.
- When a screenshot ratio differs from `430×860`, keep the outer frame fixed and adapt the inner layout through native reconstruction, cropped decorative assets, scrolling, or bounded `object-fit: contain` media.
- Interactive hit areas must be anchored to their rendered control, not to viewport guesses. Minimum pointer target is `28px × 28px` unless the visible control is smaller and an invisible expanded target is required.
- Before delivery, visually inspect at logical `430×860` and at one scaled mobile viewport. Page changes must not resize or shift the phone frame.

## Web Client Compatibility

- The supported build baseline is Chrome and Edge 90+, Firefox 91+, and Safari and iOS Safari 15+. Every shared-shell, viewport, input, audio, fullscreen, or Phaser runtime change must remain functional in Blink, Gecko, and WebKit.
- Runtime branches use capability detection. Engine and platform detection are debug metadata only and must not become the authority for enabling a feature.
- `src/core/ClientCompatibility.ts` owns viewport metrics, capability snapshots, platform/input metadata, and legacy media-query subscriptions. React components use `src/components/useMediaQuery.ts`; scenes must not create parallel UA or `matchMedia` compatibility logic.
- Layouts use `--app-viewport-width` and `--app-viewport-height` with `100vh` fallbacks, and every safe-area `env()` call includes a `0px` fallback. A new use of dynamic viewport units or container-query units requires an executable baseline fallback.
- Pointer Events are the primary cross-device input contract and keyboard equivalents remain available. Hybrid devices use `any-pointer`; any coarse pointer preserves touch controls, while desktop split mode also requires a fine pointer, hover, landscape orientation, and at least `1100px` width.
- Validation covers desktop and mobile UA scenarios in Blink, Gecko, and WebKit. Minimum viewports are `1280×720`, a non-16:9 desktop viewport, and `390×844`; pass criteria include zero document overflow, stable `1:2` phone and `16:9` RPG ratios, real keyboard and touch movement, and zero page or console errors.
- The detailed fallback and QA matrix lives in `docs/client-compatibility.md` and must be updated when the support baseline or shared compatibility mechanism changes.

## Canonical RPG Viewport And Campus Map

- Every RPG implementation uses one logical canvas: `960px × 540px`. Keep the rendered shell at `16:9`; fill the available desktop viewport and letterbox non-16:9 windows without stretching. Phaser camera scaling preserves the same visible world extent and does not change collision coordinates.
- `src/scenes/rpg/RpgPlayerTextures.ts` is the player visual and collision reference. Runtime frames are `96px × 128px`; its display scale, campus depth curve, fixed world-space foot box, four-phase walk cycle, and name-label offset remain the only shared player values. Individual scenes must not define competing values.
- The active Chapter 4 `7:55` teaching-building plates keep one logical elevator with floor-specific visible apertures and interaction anchors authored in source pixels. The approved A1/A2/A3 visible elevator centers are `772.5`, `791`, and `787.5`; Phaser positions the door visual, stand point, travel zone, and arrival point from the active floor layout entry instead of a shared `x=836` constant. Elevator progression remains one controller-owned transport state.
- The formal Chapter 4 room-204 route requires the elevator and the approved Three.js stair puzzle as causal progression gates. After the A1 classroom comparisons, the player records the elevator history in dark observation, aligns the six-second passenger trace to the eight-second door interval in light operation, travels to A3 while A2 remains locked, records the A3 classroom reference, and completes both misaligned-stair levels before the controller relocates the player to the A2 corridor. A generic floor selector must never bypass or replace these gates.
- The A3 school-history honor wall uses verified real Zhejiang University figures with official university source URLs. Every portrait remains a proximity `Space` biography interaction. Zhu Kezhen stays the centered narrative portrait; completing both Zhu questions is controller-owned and gates the approved misaligned-stair entry. Later light-grid completion may write only the `canruo_star_lamp_primed` handoff fact for the already approved “灿若星辰灯” consumer; do not generate, replace, or impersonate that existing lamp asset.
- The Chapter 4 teaching-building player is confined to the active floor's exact `1672 × 941` source rectangle. Camera bounds are presentation-only; the Arcade Physics world bounds must switch to `[floorOffsetX, floorOffsetX + 1672] × [0, 941]` whenever the active floor changes, before player control resumes. The player must never enter the `192px` inter-floor storage gaps or any coordinate outside the visible floor plate.
- A1 contains two walkable passages behind the north portrait wall. Their marked walkable bounds remain collision-free, while matching foreground crops use authored `baselineY` depth so the wall covers the player only while the player's foot point is behind it. A walkable-behind-foreground region must never become a wall collider.
- Phone app scenes remain portrait-only. Entering the RPG changes to the horizontal runtime; it must not rotate or resize the shared `430px × 860px` phone shell.
- The campus RPG entry lives only in `浙大钉 → 校园地图`. A phone-home `游戏` icon may open a separate portrait mini-game, but it must never route into, unlock, or visually impersonate the campus RPG.
- Campus travel from the dorm through the Basic Library, East Canteen, and theater entrance uses IonicJian's checked-in north-up campus plate at `src/assets/rpg/campus/zijingang_campus_plate.png`. The active world is the source-sized `4516px × 3420px` plate with the matching compressed walkability data in `src/data/maps/zijingang-campus-runtime.json`. The former synthetic Tiled map remains reference material only and must not become the active campus renderer.
- The `13668px × 1084px` side-view panorama at `src/assets/rpg/campus/zijingang_campus_loop_panorama.png` is restricted to the completed-theater-to-Qizhen approach. It must not replace the dorm, library, canteen, or pre-entry theater campus routes.
- The two projections keep separate runtime data. `src/data/maps/zijingang-campus-runtime.json` owns the north-up plate, normal campus collisions, and the library, canteen, and theater route gates; `src/data/maps/zijingang-campus-loop-runtime.json` owns only the theater-to-Qizhen side-view approach. Coordinates must never cross between these datasets.
- The loop panorama inserts a `1924px` Qizhen Lake segment at old panorama `x=8400`, immediately east of the first theater. Those shifted coordinates belong only to the side-view approach scene; the IonicJian north-up plate retains its own library, canteen, theater, and spawn coordinates.
- `npm run map:zijingang:rebuild` validates the north-up plate and rebuilds the separate side-view approach from checked-in sources. `npm run map:zijingang:tilemap` is a retained reference generator only; `npm run map:zijingang:loop` recalibrates the theater-to-Qizhen approach. Neither command may overwrite the north-up plate or the other projection's runtime data.
- The theater-to-Qizhen scene is a bounded story corridor. It preserves checkpoint, inventory, quest, and save state, and it does not expose the panorama's former global wrap as a second campus navigation path.
- The campus camera follows the player, supports bounded pointer panning and discrete zoom, and never stretches either map. Nominal default zoom is `1.1`; the backing-store scale multiplies the actual camera value without changing the visible world extent. The north-up plate uses its stable player scale. The strong near/far depth curve applies only to the side-view theater-to-Qizhen approach. The overview minimap stays removed.
- The base plate renders at source size `1:1`. Runtime code must not resize, reorder, or independently transform source layers; tightly measured same-source building crops may be redrawn only for foot-depth occlusion.
- Every active asset uses one internally consistent projection, pixel density, and lighting direction. Dynamic actors may change uniform scale only through the projection's shared player contract; unequal `scaleX` and `scaleY`, mixed viewpoints inside one rendered segment, and scene-local perspective constants are prohibited.
- Normal campus walkability comes from the compressed mask authored against the IonicJian plate. The dorm route, library gate, canteen gate, theater gate, and their checkpoint spawns must share one connected walkable network inside the `4516px × 3420px` world.
- The theater-to-Qizhen corridor uses the separate compressed mask embedded in `src/data/maps/zijingang-campus-loop-runtime.json`. Side-view facades remain background art; collision comes from that manifest's calibrated foreground surface and measured props. Top-down landmark polygons must not be attached to it.
- The first completed theater flow exits at `campus_theater_junction` and switches from the north-up campus runtime to the bounded side-view Qizhen approach while `qizhenLake.locationBriefingSeen` is false. The wet paper and residual trail move east toward the lakeside segment, stop before revealing the final location answer, and then hand control to the existing three-source phone investigation. Reload after acknowledgement restores the appropriate safe approach checkpoint; reload before acknowledgement replays from the theater-side checkpoint.
- Future campus-art replacements must preserve the projection boundary, Qizhen-after-theater sequence, source-pixel gate calibration, strong approach depth curve, and engine-neutral TypeScript state authority. Generated cinematic media remains non-authoritative presentation material and must never replace either map runtime, collision data, checkpoint logic, or TypeScript progression authority.

## Qizhen Lake Kayak Runtime

- The side-view `campus_qizhen_loop` scene ends at the Qizhen gate. Entering `qizhen_lake` switches to a north-up kayak runtime and must never continue the pseudo-`2.5D` campus projection inside the lake.
- The lake runtime uses four separate `1672px × 941px` source maps: `qizhen_lake_dock.png`, `qizhen_lake_open_water.png`, `qizhen_lake_channel.png`, and `qizhen_lake_swan_cove.png`. Dock, open water, straight chase channel, and swan enclosure each own one measured collision dataset and safe spawn.
- The player, kayak, paddles, paper, fishing targets, fish, swans, gates, and collectible props remain dynamic runtime objects. They must not be baked into any lake background. The seated player animation, hull, left willow-branch paddle, and right triangular warning-sign paddle are separate render layers.
- On foot movement is available only on the dock's authored land. Water traversal requires the kayak. The formal lake exit exists only at the small dock; every other zone exposes a readable return waterway or safe recovery action.
- Kayak input is stroke-based. Desktop uses `A` or left arrow for the left paddle and `D` or right arrow for the right paddle. Those strokes move forward by default; holding `S` or down arrow while pressing either paddle performs a reverse stroke and produces bow-side reverse wake. Coarse-pointer layouts render one control for each paddle: swiping upward performs a forward stroke, swiping downward performs a reverse stroke, and a short tap falls back to a forward stroke. Alternating strokes in one travel direction generate speed and recover balance. Repeated same-side strokes rotate the hull and increase roll; reverse strokes invert the yaw impulse. Exceeding the balance limit causes a visible capsize, increments the persisted capsize count, and restores the latest safe zone checkpoint.
- A kayak collision with a visible bank, world edge, buoy, rock, raft, net, mooring, or dock stops motion into that surface while preserving heading and roll. Collision alone never capsizes the kayak and never rotates it. Stale blocked flags must not suppress velocity that moves away from the surface, so the player can hold reverse and alternate the two paddles to back out without a checkpoint reset.
- Boarding is a short authored balance tutorial using the same left/right stroke contract. A missed or repeated-side sequence may capsize but cannot consume story items or corrupt progression. Instantaneous velocity, roll, wake particles, and input timing remain runtime-only; saves store the current zone, vehicle mode, phase, and safe spawn.
- `深色观察` records the reflection location and item silhouettes. `浅色操作` performs boarding, casting, pickup, combination, feeding, and capture. A light-mode cast at an unobserved coordinate is rejected with the next corrective action. Casting directly at the paper is a readable failure and never advances the puzzle.
- The ordered lake item chain is controller-owned: fishing rod plus decoy bait catches item 1 `rustedLockerKey`; item 1 opens the dock locker and grants item 2 `nylonCord`; the rod catches item 3 `brokenNetFrame`; items 2 and 3 combine into item 4 `improvisedDipNet`; item 4 retrieves item 5 `sealedFeedTin`; opening item 5 grants item 6 `fishFeedPellets`; item 6 catches `smallCarp`; feeding the fish to the black swan grants item 7 `swanMagnet`; item 7 combines with the rod into `magneticFishingRod`, which can capture the clipped paper.
- A successful paper capture releases the enclosure bird and enters the straight-channel chase. The chase returns to the dock, marks the magnetic attachment as broken, releases the paper into the next transition, and persists a completed safe checkpoint. Failure restarts only the chase segment.
- The black-swan chase uses the actual swan-to-kayak gap as its pursuit authority. Far pursuit speed must exceed the kayak maximum, near pursuit speed must fall below it, a short start grace prevents an immediate catch, and physical contact causes a chase-only failure before restoring the channel checkpoint. The finish condition is evaluated before contact on the same frame, and runtime debug state exposes gap, pursuit speed, catch distance, and grace readiness.
- Chase collision keeps every visible channel obstacle active, including the raft, net, mooring posts, rocks, buoys, dock, and stepped banks. Collision rectangles are authored in source pixels against the channel plate, while the kayak body derives its axis-aligned bounds from the rendered hull size and current heading. The authored start lane must allow a complete alternating-stroke run without crossing visible geometry.
- Every item-use attempt reports accepted, missed target, wrong item, too far, wrong mode, unobserved location, or direct-paper failure. Items disappear immediately after their final successful use, including stale selected or dragged state.
- The four authored fishing catches use a two-step transaction: a controller-owned, read-only precheck opens one runtime-only rhythm session, and the original item transform runs only after that same session passes and resolves once. Judgment, visual rings, input, and the procedural beat fallback share one monotonic clock. Failure, cancellation, page hiding, and scene shutdown preserve story items and never resume a partial chart.
- Every RPG interaction is facing-agnostic. Player facing and kayak heading remain movement, animation, wake, chase, and visual-orientation values only; they must never gate inspection, pickup, dragging, item use, devices, doors, elevators, stairs, casting, feeding, or story intents.
- Old `reflection_hunt`, `sign_alignment`, `decoy_setup`, `mist_timing`, and `chase_ready` saves migrate into safe kayak checkpoints. Completed old lake progress must not regress to location search. The Phaser lake remains incomplete until all four zones, kayak input, item drag, save/reload, chase, and Blink/Gecko/WebKit validation pass.
- Persistent map captions are limited to the campus title and the current objective. At most one nearby landmark name may appear; shape explanations, control hints, and repeated route reminders do not stay on the playfield.
- The RPG task drawer is owned by the `rpg-shell` overlay layer, not by the narrow task-trigger bar. It must be portaled directly into the shell and stay fully scrollable inside the `960px × 540px` logical map bounds at every rendered scale.
- The top of the RPG canvas is reserved for the shared React task bar. RPG dialogue, feedback subtitles, and interaction hints use the bottom safe zone defined by `src/scenes/rpg/RpgHudLayout.ts`. Scene files must not restore local top-positioned feedback coordinates or render two subtitle surfaces at once.
- Virtual direction and interaction buttons are touch-only controls. Render them only when the primary input is a coarse pointer; fine-pointer desktop maps use keyboard input and must not expose, focus, or reserve space for the virtual D-pad.
- The single-screen map action is labelled `返回手机主页` and always restores `runtimeMode: "phone"` with `currentScene: "phone_home"`. It preserves the RPG scene, checkpoint, quest facts, and inventory so the player can return to the same map later.
- The Basic Library gate supports first entry and re-entry throughout every unfinished library phase. Re-entry must preserve `libraryFinalsPhase` and puzzle facts, select a safe interior checkpoint, and must never regress progress to `library_entered`.
- A pre-rendered RPG interior whose source image matches the world dimensions owns one source-pixel collision dataset. Phaser model coordinates remain traceable to the source image; repeated approximate obstacle grids are not allowed.
- Interior collision changes require three checks: solid-pixel samples are blocked, clear-floor samples and checkpoint spawns remain open, and the real Phaser player body stops at the expected source edge. Development-only collision overlays may be enabled by a URL flag but never appear in a release build.
- Validate campus identity at `1280×720` and one non-16:9 desktop viewport. Passing requires stable nonblank canvas rendering, readable landmark labels, preserved spatial relationships, and no overlap with the player, objectives, inventory, or controls.

## Browser RPG Integration Contract

- `src/scenes/rpg/TheaterRuntimeContract.ts` is the first exercised versioned scene port. Generalize the same state-read, intent-write, event-subscription, viewport, and checkpoint contract for other Phaser scenes; do not connect scene code directly to `GameStore` mutation.
- `RpgGameHost` owns Phaser lifecycle, focus, visibility pause, responsive placement, Pointer Events forwarding, keyboard focus, audio unlock, fullscreen, error handling, and teardown. One RPG canvas may be mounted at a time.
- Phaser scenes submit engine-neutral intents such as inspect, interact, inventory drop, movement checkpoint, dialogue continue, and scene exit. TypeScript controllers validate each intent and publish the resulting state and presentation events through the shared port.
- Inventory drag feedback remains owned by the shared React dock. Phaser scenes report exact world-space drop bounds, accepted item ids, distance rules, mode rules, and rejection reasons so the dock can display accepted, missed target, wrong item, too far, wrong mode, and locked states consistently. `requiredFacing`, facing tolerances, and `wrong_facing` are prohibited interaction fields and outcomes.
- One checked-in web asset remains the source of truth for each visual. Derived files must have an explicit active browser consumer; retired Godot copies do not participate in asset validation.
- Every landscape scene requires browser validation in Blink, Gecko, and WebKit at `1280×720`, one non-16:9 desktop viewport, and `390×844`, including keyboard, touch, inventory drag, save/reload, and entry/exit flow.

## RPG Reality Modes And Spatial Item Use

- `src/scenes/rpg/RpgInteractionContract.ts` is the shared authority for reality-mode labels, item drop bounds, distance limits, accepted item ids, required modes, target ordering, and drop rejection classes. Every Phaser RPG scene consumes the same authored target data, and no scene may add a local facing gate.
- The global mode rule is fixed: `深色观察` reads clues, residual images, routes, rhythms, and abnormal state; it never performs physical pickup, drag, cleaning, payment, pushing, scanning, or device activation. `浅色操作` performs those physical actions after any required observation has been recorded.
- The mode toggle always states the current mode and the destination mode. A control labelled only with the destination mode is prohibited because it does not tell the player which rule currently applies.
- A physical item use point declares one visible target label, exact world-space drop bounds, an accepted item id, a reachable stand position or visible-edge distance, and `requiredMode: "light"` when the scene supports reality modes.
- Drag feedback distinguishes `missed_target`, `wrong_item`, `too_far`, `wrong_mode` or another controller-owned lock, and `accepted`. A failed drop keeps the item and states the next corrective action.
- Repeating the same observation on multiple equivalent objects cannot become a prerequisite chain. One observation may register all simultaneously visible equivalent targets; independent collectible branches remain order-independent unless the order itself carries puzzle information.
- Scene instructions mention `Space` only for an action currently accepted through the shared interaction event. Item-only targets tell the player to drag the named item into the named frame and do not advertise `Space`.

## Portrait Mini-games

- Standalone phone mini-games stay inside the shared `430px × 860px` portrait shell and preserve the top `40px` status-bar reservation.
- Use the project's existing React, TypeScript, and Phaser runtime. Do not add a second game engine for a phone mini-game.
- A mini-game must provide an intro, complete controls, visible progress, failure, victory, replay, and a return path to the phone home screen.
- Mini-game state is local unless a later story specification explicitly connects a result to shared progression. Audio, narration, or game-over UI must not own shared route or quest transitions.
- When a story specification connects a mini-game to chapter progression, gate entry from validated shared state and persist unlock, completion, attempts, and best results through `SaveStore`; scene-local UI state must not become the progression source of truth.
- Chapter controllers validate terminal conditions before writing shared state. A distance goal requires the goal value, and a failure result requires the configured failure condition.
- Phaser mini-games pause on `visibilitychange`, show an explicit resume state, and destroy the game instance, input listeners, timers, and runtime snapshot on unmount or retry.
- Every Phaser scene subscription to the shared RPG bridge must detach on both scene `shutdown` and `destroy`. A stopped or destroyed scene must never consume pointer, movement, camera, or inventory events; use the shared lifecycle subscription helper instead of a shutdown-only listener.
- A scene-close domain event must cancel queued chapter audio cues and stop chapter voice and music before routing to another scene.

## Delivery

- Before any staging, commit, pull, merge, rebase, or push, fetch the relevant GitHub remote and present the user with three separate views: local working-tree changes, local commits relative to the tracked remote branch, and remote commits not present locally. Include untracked files and identify generated or unrelated changes. The user chooses the exact submission scope before any Git mutation beyond the read-only fetch. Never infer approval to commit from a request to implement, continue, build, or upload another chapter.
- Preserve direct browser opening through the generated `demo/index.html`. The same Phaser RPG runtime must work under local HTTP, deployed HTTP(S), and the generated offline single file without an engine-specific loader.
- Name every GitHub delivery from its actual `Asia/Shanghai` upload completion date. After push and merge finish, apply the final `YYYYMMDD` consistently to the upload directory, implementation directory, archive filename, `README.md` links, and `ASSETS.md`; crossing midnight uses the new completion date, and delivery is incomplete until the remote `main` paths are verified.
- Chapter completion must preserve the validated `GameState` and continue through a controller-owned entry method. `createInitialGameState()` is reserved for an explicit new-game action and must never be the default action on a chapter ending screen.
- Run `npm run typecheck` and `npm run build:single` after React, shared-state, controller, bridge, or Phaser behavior changes.
- `.github/workflows/web-ci.yml` is the canonical repository CI. It verifies the complete Chapter 3 audio contract, campus map contract, TypeScript, production build, and offline single-file runtime for every PR and push to `main`. Retired Godot sources and exports are outside the active delivery gate.
- Automated tests and test-only dependencies are intentionally excluded from this workspace unless the user explicitly asks to restore them.
- Validate new interactions in a real browser, including the complete navigation chain.
- Keep temporary screenshots and browser QA artifacts outside the deliverable and delete them after inspection.
- Record meaningful implementation and verification updates in `progress.md`.
- Persist controller-owned gameplay facts automatically, but sanitize transient UI before writing: control center closed, inventory closed, and no selected drag item.
- Keep one validated previous snapshot beside the primary save and recover it when the primary JSON cannot be loaded.
- Developer checkpoints use session-only state and must never overwrite the formal local save.
- Story reset lives in the control center and requires an inline second confirmation. It clears chapter, item, puzzle, and bike progress while preserving player-edited CC98 post content.

## Locked Feature Visual Contract

- A future app, service, or navigation entry that is gated by story progress keeps its original card or control frame, original icon, original name, and grid position while locked. The visible name reserves the same line height as the unlocked entry so mixed grids remain aligned.
- A locked icon entry renders no helper copy, badge, or `xxx`; its icon and name are static non-interactive content with no button semantics, focus target, click handler, or toast.
- When the formal feature gate opens, the same slot becomes interactive without changing its label or grid geometry. Story state remains the only authority for that transition.
- Text-only redactions and unreleased content may continue to use `xxx`; never use `xxx` in place of a known app or control icon.
- Decorative placeholder banners with no current action or information must be removed instead of occupying a disabled feature slot.

## Developer Channel

- The generated offline build shows the collapsed `DEV` trigger by default so a reviewer can recover from a stale save or jump to a gameplay checkpoint. `?dev=0` is the explicit presentation-only opt-out.
- Developer navigation uses chapter groups only as the first level. Every entry must seed a named gameplay checkpoint with all required quest, item, scene, runtime, and UI facts.
- Granular checkpoints cover puzzle starts, intermediate evidence states, presentation handoffs, action gates, and chapter results. A route-only scene change is not a valid checkpoint.
- `?devCheckpoint=<id>` is the stable direct-entry contract for both Vite and the generated single file. `Ctrl+Shift+D` toggles the panel.
- Before the first developer jump, preserve the current state and provide an explicit restore action. Developer seeds must not become reachable through normal story controls.

## Quest And Inventory Feedback

- 持续显示的全局目标、后续路线与跨页面行动只由共享任务栏呈现。手机页面、RPG 页面、道具详情和成功反馈只报告本地状态或操作结果，不重复“下一步：”或“接下来”的全局路线；当前小游戏操作、交互失败纠正和持有道具的当前用途仍可在原位置显示。
- The shared task trigger must accept pointer, Enter, and Space input on phone, RPG, and split-screen layouts. Its drawer always labels `当前任务`, `当前进度`, and the next objective explicitly.
- The task drawer reveals only the current next objective. Locked future step labels must not be rendered, because even disabled checklist rows disclose the remaining puzzle chain. Completed paper documents may remain available only inside a collapsed acquired-material archive derived from completed facts.
- Chapter-one digit discoveries remain visible only in the shared task trigger/drawer as four ordered slots. Unknown slots stay masked and acquired digits keep their original positions. The inventory bar must not repeat the digit strip or compact digit string; the task UI reads `state.digits` directly and remains the sole visual owner.
- RPG checkpoints that represent difficulty stages must set the real simulation value. Labels such as `377m` or `566m` cannot point to a zero-distance run.
- Every phone or RPG item-use attempt must resolve to one visible result: accepted, missed target, wrong item, too far from the real target, or locked by the current story phase. Holding or starting to drag an item shows its current-use guidance, and valid DOM targets highlight their measured hit area. Silent early returns are prohibited.
- A light/dark two-mode puzzle persists the relevant observation fact in dark mode before its light-mode action becomes available. Controllers reject out-of-order requests, and scenes must not open an actionable choice panel before the observation fact exists.

## Scene Reuse And Audio Contrast

- Measure reuse at the scene-visual layer: existing page backgrounds, cards, app shells, lists, maps, and CSS-built controls should serve multiple story phases before a new full-page asset is added.
- A reused scene must still change its state, available actions, labels, hotspots, or overlays so the player can read the current phase.
- When a visible control is baked into a background asset, measure its source-pixel bounds and give that exact region an independent hotspot. Status captions remain display-only, use `pointer-events: none`, and cannot share the control's progression handler.
- Audio does not count toward the visual reuse target. Distinct story phases should have clearly different music, sound effects, pacing, and delivery, including multiple phases shown on the same screen.
- Keep one narrator identity unless the story explicitly introduces another speaker. Use speed, pitch, pauses, and emphasis to separate phase delivery.
- Game logic emits domain events only. `AudioDirector` and JSON timelines own filenames, subtitles, offsets, levels, ducking, and music replacement.
- Missing or blocked audio must never stop a state transition or prevent interaction.
- A generated audio manifest is runtime-readable only when its complete authored asset set has passed path, format, duration, configuration-hash, file-hash, and duplicate-byte checks. Interrupted generation writes recovery progress only to an ignored cache checkpoint; it must never replace the canonical manifest with a partial asset set. `--verify-only` is strictly read-only, and validated media plus canonical manifests use staged atomic replacement.
- Every spoken voice asset ships in English. Every on-screen voice subtitle uses Chinese and has exactly one owner: a scene dialogue surface when that scene already renders the line, or the shared `ToastLayer` for voice-only cues. Set `subtitleSurface: "scene"` for scene-owned lines and never emit the same text through both surfaces. Shared toasts keep their global position, type size, and audio-derived duration contract unchanged. TTS source text, voice language, generated manifests, and runtime audio must use English.
- Preserve role continuity: every narrator line uses the established English male narrator voice at the shared base pitch; context may change wording, pauses, emphasis, and speed without changing narrator timbre or pitch. The system uses the established English female voice. Narrator sarcasm stays dry and condescending, while system frustration reads as restrained irritation and reluctant assistance.
- The legacy `playVo` scene lines and data-driven `AudioDirector` cues belong to the same English voice contract and must be regenerated and validated together.

## Puzzle Information Architecture

- Objective text, quest strips, presentation overlays, subtitles, and narration must describe the current problem or evidence category. They must not state an unsolved answer, exact route, floor sequence, code, or parameter set.
- A main inference requires at least three evidence carriers distributed across at least two fictional speakers, pages, or applications. One control label or one narrator line cannot contain the complete solution.
- Reading, inspection, filtering, and evidence-selection progress that gates a main puzzle must live in shared validated state and survive scene changes. UI-local state is limited to animation, temporary selection, and failed-attempt feedback.
- Do not auto-scroll, auto-focus, highlight, or open the answer-bearing control immediately after a cleanup action. The player must identify the next source from visible relationships such as quotes, timestamps, attachments, or role conflicts.
- Decoy options must fail for a readable reason: missing source, contradictory timestamp, incomplete attachment, or unsupported conclusion. Randomly indistinguishable choices are not acceptable.
- Failure hints use three tiers. First failure reports the mismatch category; second failure explains the structural rule; third and later failures point back to the relevant evidence type. Hints still must not print the exact answer.
- Exact routes, codes, and parameter values may appear in confirmation UI only after the controller has validated the player input.
- Controllers enforce evidence gates and terminal answers. Components cannot advance a puzzle by route changes, animation completion, or audio completion alone.
- Functional app surfaces such as catalog search, post search, filters, and lists must remain usable before their story clue is unlocked. Story gates control evidence collection and progression only; they cannot make an otherwise valid search appear broken.
- `PresentationDirector` converts domain/state changes into stable presentation cues. `PresentationLayer` and `AudioDirector` consume the same cue independently; neither consumer triggers the other or writes puzzle progress.

## Prologue Exit And Chapter Two Movement Gate

- A successful `0798` check-in does not enter a static ending page. It must run the authored sequence: brief check-in success, a `经度与纬度不存在` error window, red flash, seven-second blackout, error-window interception game, final hold capture, player/system exchange, repeated white burst, then return to the existing phone home screen with the next services unlocked.
- The exact check-in error window becomes the interception board in the ending scene. Pointer drag or `A/D` and left/right keys move it across the lower exit; the player must block three narrator paths, while three misses expose a retry state.
- The final narrator lock uses Pointer Events so mouse, touch, and pen share one interaction, with `Space` and `Enter` as keyboard equivalents. Releasing before `1400ms` clears the hold; chapter progression requires the controller to validate three interceptions, the completed hold, and the full exchange.
- The old bootstrap route based on a login receipt, free CC98 controls, a game cartridge, and visiting four map areas is retired. Do not restore those gates in UI, controllers, saves, or reports.
- Chapter one keeps the campus card unavailable and the campus map locked and static. The first digit `0` comes from the `本周缺勤 0 次` record on the check-in page, without an RPG route.
- The canonical dorm plate is `src/assets/rpg/interiors/dorm_hub.png`, a user-selected `941×1672` strict top-down pixel map. Its fixed structure is two bunk-bed groups with their long edges on the left wall and exactly four desks with their long edges on the right wall. Replacing, independently resizing, perspective-warping, or adding central furniture to this plate requires explicit user approval.
- `DormHubModel.ts` remains the source for dorm source-pixel collision and interaction coordinates. The `960×540` RPG camera may follow and zoom over the tall world, but furniture collision must continue to match visible source pixels and the central aisle and bottom doorway must remain walkable. Large furniture interactions measure proximity from the visible target rectangle edge, not only from its center.
- Chapter two opens the dorm map only after the system requests an inventory. The player retrieves the campus card from the right-side personal desk; this grants `items.campusCard`, restores the inventory, and advances to `system_return_required`.
- Chapter two movement readiness is assembled from reusable scenes: campus-card identity, department directory, ZJU Sports, phone-home notification, Weather, WeChat mentor avatar, campus-card balance, CC98 marketplace, and the dorm mini-game.
- The movement puzzle keeps independent validated facts for character naming, automatic exercise movement, triangle collection, weather water, mentor-line release, right-arrow assembly, balance shift, gamepad purchase, first manual movement, and dorm exit. Scene-local animation state must never replace these facts.
- Automatic exercise movement and manual gamepad movement are different capabilities. Exercise makes the character pace without player control; buying the gamepad stops pacing and enables input only after the character has a name and an active exercise record.
- RPG desktop controls use `WASD` for movement and `Space` for entering, inspecting, and continuing dialogue. `A` is the move-left key and must never be presented as an interaction key; touch controls may emit the same interaction event through a button labelled `空格`.
- The dorm exit remains locked until the player has produced one manual movement input after buying the gamepad. That first input publishes the `can leave` cue; crossing the exit then completes the movement gate and opens the campus route toward the library.
- Phone/RPG actions publish domain events. Music, voice, sound effects, subtitles, flashes, screen shake, and transition animation consume presentation cues independently and cannot unlock a puzzle step.
- The phone inventory appears after the first owned chapter-one item. A successful `0798` check-in hides it immediately, before the coordinate-error notification and interception sequence. It stays hidden while `checkinDone` is true and `inventoryRecovered` is false, then returns when the dorm campus card is collected.

## Chapter Two: Library 022 Backpack

- `docs/chapter-2-library-story.md` is the canonical story and dialogue source. `docs/chapter-2-library-development-spec.md` is the canonical implementation, gating, and acceptance source. If wording conflicts with behavior notes, story text follows the story document and mechanics follow the development specification.
- The movement gate above remains the chapter prelude. After the first validated manual movement and dorm exit, the campus RPG opens the Basic Library route and the chapter objective becomes finding the system's friend at seat `022`.
- The former `63`-floor CC98 archaeology, `18`-item `ac01` filter, `47 → 12 → 1` citation chain, route screenshot, recovery code, and temporary PASS flow is retired from active chapter progression. Legacy save values may migrate forward, but the old path must not remain reachable as a parallel solution.
- The active chapter is RPG-first. The library interior owns the entrance record, information desk, lost-and-found identity machine, catalog terminal, south second-floor shelf, seat `022`, occupied backpack, receipt gap, and final PASS application. Phone apps process, certify, and publicize evidence gathered in the RPG.
- Required evidence chain: reservation note → CC98 `23`-floor investigation → catalog number `755` → archived leave rule; dimmed photo → item report → stamped non-person proof; persistent right arrow → `022` receipt; Tiyi form `7 / 47 / 3` → presence proof; four CC98 uploads + valid A/C/E `bd` replies → top-ten rank `01`; three library recovery slots → eviction PASS; PASS on the RPG backpack → restored seat and `022` dialogue.
- The right arrow is a reusable physical tool. Shifting the campus-card decimal must not destroy it, because the same arrow later pushes the `022` receipt from the desk gap.
- ZJU Sports has two phase-specific roles: it starts automatic pacing during the movement prelude, then reads the recorded library route for the presence-proof form. The later form must not restart or alter character movement.
- Weather is allowed only in the movement prelude that creates the right arrow. It is not a core evidence source inside the library investigation.
- CC98 keeps exactly five optional `ac01` joke replies in the new `23`-floor post. They do not gate progress. Only A, C, and E evidence replies can advance rank `04 → 03 → 02 → 01` after all four evidence uploads are validated.
- CC98 non-evidence replies use fictional identities, stay relevant to the active post, and read as concise campus water-chat: queue-forming, running jokes, casual digressions, and partial observations. Do not write them as formal help text or expose a complete puzzle answer.
- The library recovery application unlocks only after rank `01`. It accepts presence proof, non-person proof, and the `022` receipt; the archived rule remains effective through the CC98 public record.
- Applying the PASS, moving the backpack, sitting down, and the abnormal `022` conversation are controller-owned transitions. Animation or audio completion may acknowledge these transitions but cannot create them.
- Chapter completion unlocks the third-chapter objective `找到那本借走签到记录的书` and adds the authored library, CC98, and photo notifications without resetting first- or second-chapter inventory and evidence history.

## Flow Access, Shared Quest UI, Items, And Story Audio

- `selectFeatureAccess(state)` is the only feature-unlock authority. Components and routes derive access from story facts; do not add parallel unlock booleans.
- `selectQuestViewModel(state)` is the only task-progress authority. Phone, RPG, and desktop split mode render one `QuestTaskBar`; task navigation may change the relevant surface or scene but must never execute a puzzle action.
- Locked or irrelevant application slots remain non-interactive static `xxx` elements with no icon, button semantics, focus, toast, or developer-copy feedback.
- Desktop split mode applies only to RPG runtime at a landscape fine-pointer viewport of at least `1100px`. It keeps one phone shell, one active Phaser canvas, one task bar, one presentation layer, and one toast layer mounted against the shared game state.
- `ITEM_CATALOG` owns inspect mode, paper document content, target use, and retain/consume/transform semantics. Controller validation owns every successful use; UI drop zones only submit requests.
- A paper item opens on an unmoved click or Enter. Dragging past the shared threshold suppresses inspection. Submitted paper remains readable through the task or upload record after the inventory instance is consumed.
- Only `StoryLine.kind === "dialogue"` with an explicit `voiceRole` may play speech. Male narrator dialogue uses `English_expressive_narrator` at base pitch `-4`; female system dialogue uses `English_Graceful_Lady`. Player, seat 022, task, success, failure, and taunt lines are text-only.
- Text feedback duration is `clamp(2400, 6500, 1600 + 120 * visibleGraphemeCount)`. Audio paths use exact generated-manifest entries; fuzzy filename matching and audio-owned progression are prohibited.
- Audio generation filters retired voice assets from manifests. Running `npm run audio:chapters:english` twice consecutively must report no unexpected regenerated voice files.
