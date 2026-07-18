# 7:55 Project Rules

## Structure

- `src/scenes/phone/`: phone scenes and scene-local interaction state.
- `src/components/`: shared phone-shell controls only.
- `src/assets/ui/`: bundled visual references used by scenes.
- `src/core/`: shared game state, routing, and types.
- `src/styles/`: shared tokens, shell layout, and scene-specific styling.
- `demo/index.html`: generated standalone game build; do not edit it by hand.

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

## Canonical RPG Viewport And Campus Map

- Phaser RPG scenes use one logical canvas: `960px × 540px`. Keep the rendered shell at `16:9`; fill the available desktop viewport and letterbox non-16:9 windows without stretching.
- Every current and future controllable RPG player sprite must use `configureRpgPlayerSprite` from `src/scenes/rpg/RpgPlayerTextures.ts`. That shared module alone owns the canonical `48px × 64px` display size, foot collision box, and name-label offset; individual scenes must not apply their own player scale, display size, or body geometry.
- Phone app scenes remain portrait-only. Entering the RPG changes to the horizontal runtime; it must not rotate or resize the shared `430px × 860px` phone shell.
- The campus RPG entry lives only in `浙大钉 → 校园地图`. A phone-home `游戏` icon may open a separate portrait mini-game, but it must never route into, unlock, or visually impersonate the campus RPG.
- Campus exploration uses one strict `90-degree` top-down pixel-art world with north facing up. The player moves in four directions on the generated road network; Phaser owns the player, collisions, depth, labels, hotspots, quest markers, camera, and state transitions.
- The user-selected repository panorama is the campus spatial and visual source of truth. It is the `5016px × 5016px` plate stitched from the archived `4 × 4` set of `1254px` full-map tiles and stored at `src/assets/rpg/campus/zijingang_campus_plate.png`.
- The runtime manifest owns world width, world height, spawn, library entrance, landmarks, and collision data. The plate, player, camera, minimap, labels, and story triggers all read this one `5016 × 5016` coordinate system; do not reuse the retired `2400 × 1920` or alternate `3840 × 3840` coordinates.
- The campus camera follows the player in both axes, supports bounded pointer panning and discrete zoom, and never stretches the map. A minimap may show the complete north-up plate, but it cannot replace the playable world.
- The selected panorama must render at source size `1:1`; runtime code must not resize, crop, reorder, or independently transform any quadrant.
- Every campus asset uses the same top-down projection, pixel density, lighting direction, and global scale. Side-on facades, isometric `45-degree` sprites, and mixed viewpoints are prohibited in the campus world.
- The restored repository runtime has no calibrated `5016 × 5016` collision rectangles, so campus movement remains unrestricted while the image, spawn, entrance, and labels stay aligned. Never attach the alternate `3840 × 3840` walkability mask to this panorama; any future collision pass must be authored and validated in the panorama coordinate system.
- Future GPT Image replacements must preserve the strict top-down viewpoint, north-up orientation, full `5016 × 5016` coordinate system, and landmark positions. MiniMax remains audio-only and must not generate campus artwork.
- Persistent map captions are limited to the campus title and the current objective. At most one nearby landmark name may appear; shape explanations, control hints, and repeated route reminders do not stay on the playfield.
- The RPG task drawer is owned by the `rpg-shell` overlay layer, not by the narrow task-trigger bar. It must be portaled directly into the shell and stay fully scrollable inside the `960px × 540px` logical map bounds at every rendered scale.
- The top of the Phaser canvas is reserved for the shared task bar. RPG dialogue, feedback subtitles, and interaction hints use the bottom safe zone defined by `src/scenes/rpg/RpgHudLayout.ts`: dialogue/feedback grows upward from the lower subtitle row and the interaction hint occupies the final row. Scene files must not restore local top-positioned feedback coordinates or render two subtitle surfaces at once.
- Virtual direction and interaction buttons are touch-only controls. Render them only when the primary input is a coarse pointer; fine-pointer desktop maps use keyboard input and must not expose, focus, or reserve space for the virtual D-pad.
- The single-screen map action is labelled `返回手机主页` and always restores `runtimeMode: "phone"` with `currentScene: "phone_home"`. It preserves the RPG scene, checkpoint, quest facts, and inventory so the player can return to the same map later.
- The Basic Library gate supports first entry and re-entry throughout every unfinished library phase. Re-entry must preserve `libraryFinalsPhase` and puzzle facts, select a safe interior checkpoint, and must never regress progress to `library_entered`.
- A pre-rendered RPG interior whose source image matches the world dimensions owns one source-pixel collision table in its model module. Static walls, furniture, and clear aisles must be calibrated from visible pixel bounds; repeated approximate obstacle grids are not allowed.
- Interior collision changes require three checks: solid-pixel samples are blocked, clear-floor samples and checkpoint spawns remain open, and a real player body stops at the expected source edge. Development-only collision overlays may be enabled by a URL flag but never appear in the single-file release.
- Validate campus identity at `1280×720` and one non-16:9 desktop viewport. Passing requires stable nonblank canvas rendering, readable landmark labels, preserved spatial relationships, and no overlap with the player, objectives, inventory, or controls.

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

- Preserve direct browser opening through the generated `demo/index.html`.
- Name every GitHub delivery from its actual `Asia/Shanghai` upload completion date. After push and merge finish, apply the final `YYYYMMDD` consistently to the upload directory, implementation directory, archive filename, `README.md` links, and `ASSETS.md`; crossing midnight uses the new completion date, and delivery is incomplete until the remote `main` paths are verified.
- Chapter completion must preserve the validated `GameState` and continue through a controller-owned entry method. `createInitialGameState()` is reserved for an explicit new-game action and must never be the default action on a chapter ending screen.
- Run `npm run typecheck` and `npm run build:single` after behavior changes.
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

- The shared task trigger must accept pointer, Enter, and Space input on phone, RPG, and split-screen layouts. Its drawer always labels `当前任务`, `当前进度`, and the next objective explicitly.
- The task drawer reveals only the current next objective. Locked future step labels must not be rendered, because even disabled checklist rows disclose the remaining puzzle chain. Completed paper documents may remain available only inside a collapsed acquired-material archive derived from completed facts.
- Chapter-one digit discoveries remain visible in both the task trigger/drawer and the inventory bar as four ordered slots. Unknown slots stay masked; acquired digits keep their original positions. Every surface reads `state.digits` directly and must not maintain a duplicate clue state.
- Phaser checkpoints that represent difficulty stages must set the real simulation value. Labels such as `377m` or `566m` cannot point to a zero-distance run.

## Scene Reuse And Audio Contrast

- Measure reuse at the scene-visual layer: existing page backgrounds, cards, app shells, lists, maps, and CSS-built controls should serve multiple story phases before a new full-page asset is added.
- A reused scene must still change its state, available actions, labels, hotspots, or overlays so the player can read the current phase.
- When a visible control is baked into a background asset, measure its source-pixel bounds and give that exact region an independent hotspot. Status captions remain display-only, use `pointer-events: none`, and cannot share the control's progression handler.
- Audio does not count toward the visual reuse target. Distinct story phases should have clearly different music, sound effects, pacing, and delivery, including multiple phases shown on the same screen.
- Keep one narrator identity unless the story explicitly introduces another speaker. Use speed, pitch, pauses, and emphasis to separate phase delivery.
- Game logic emits domain events only. `AudioDirector` and JSON timelines own filenames, subtitles, offsets, levels, ducking, and music replacement.
- Missing or blocked audio must never stop a state transition or prevent interaction.
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

- A successful `0798` check-in does not enter a static ending page. It must run the authored sequence: red check-in flash, seven-second blackout, moving narrator orb, pointer hold capture, player/system exchange, repeated white burst, then return to the existing phone home screen with the next services unlocked.
- The narrator orb is captured through Pointer Events so mouse, touch, and pen share one interaction. Releasing before the hold threshold cancels capture; holding past the threshold freezes the orb and advances through controller-validated state only after the full exchange finishes.
- The old bootstrap route based on a login receipt, free CC98 controls, a game cartridge, and visiting four map areas is retired. Do not restore those gates in UI, controllers, saves, or reports.
- The dorm campus card belongs to chapter one. After the check-in digits scatter, the phone-home ZJU Ding notice must expose the route `浙大钉 → 校园地图 → 寝室`; picking up the card from the right-side personal desk grants it, and the yellow middle `0` in `¥0.06` provides the first digit. The room background stays item-free; Phaser owns the card sprite, hotspot, pickup animation, and removal.
- The canonical dorm plate is `src/assets/rpg/interiors/dorm_hub.png`, a user-selected `941×1672` strict top-down pixel map. Its fixed structure is two bunk-bed groups with their long edges on the left wall and exactly four desks with their long edges on the right wall. Replacing, independently resizing, perspective-warping, or adding central furniture to this plate requires explicit user approval.
- `DormHubModel.ts` owns the dorm source-pixel collision and interaction coordinates. The `960×540` Phaser camera may follow and zoom over the tall world, but furniture collision must continue to match visible source pixels and the central aisle and bottom doorway must remain walkable. Large furniture interactions measure proximity from the visible target rectangle edge, not only from its center.
- Chapter two inherits the campus card and recovered backpack from chapter one. The system dialogue must acknowledge the owned card and continue to the movement quest. `inventory_required` remains a migration fallback for old saves only.
- Chapter two movement readiness is assembled from reusable scenes: campus-card identity, department directory, ZJU Sports, phone-home notification, Weather, WeChat mentor avatar, campus-card balance, CC98 marketplace, and the dorm mini-game.
- The movement puzzle keeps independent validated facts for character naming, automatic exercise movement, triangle collection, weather water, mentor-line release, right-arrow assembly, balance shift, gamepad purchase, first manual movement, and dorm exit. Scene-local animation state must never replace these facts.
- Automatic exercise movement and manual gamepad movement are different capabilities. Exercise makes the character pace without player control; buying the gamepad stops pacing and enables input only after the character has a name and an active exercise record.
- RPG desktop controls use `WASD` for movement and `Space` for entering, inspecting, and continuing dialogue. `A` is the move-left key and must never be presented as an interaction key; touch controls may emit the same interaction event through a button labelled `空格`.
- The dorm exit remains locked until the player has produced one manual movement input after buying the gamepad. That first input publishes the `can leave` cue; crossing the exit then completes the movement gate and opens the campus route toward the library.
- Phone/RPG actions publish domain events. Music, voice, sound effects, subtitles, flashes, screen shake, and transition animation consume presentation cues independently and cannot unlock a puzzle step.
- The phone backpack appears as soon as at least one item is owned. It stays hidden only during the legacy `inventory_required` fallback. Visibility must not depend on `inventoryRecovered` outside that fallback, because migrated saves may own valid items without that legacy fact.

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
- Desktop split mode applies only to RPG runtime at a landscape fine-pointer viewport of at least `1100px`. It keeps one phone shell, one Phaser canvas, one task bar, one presentation layer, and one toast layer mounted against the shared game state.
- `ITEM_CATALOG` owns inspect mode, paper document content, target use, and retain/consume/transform semantics. Controller validation owns every successful use; UI drop zones only submit requests.
- A paper item opens on an unmoved click or Enter. Dragging past the shared threshold suppresses inspection. Submitted paper remains readable through the task or upload record after the inventory instance is consumed.
- Only `StoryLine.kind === "dialogue"` with an explicit `voiceRole` may play speech. Male narrator dialogue uses `English_expressive_narrator` at base pitch `-4`; female system dialogue uses `English_Graceful_Lady`. Player, seat 022, task, success, failure, and taunt lines are text-only.
- Text feedback duration is `clamp(2400, 6500, 1600 + 120 * visibleGraphemeCount)`. Audio paths use exact generated-manifest entries; fuzzy filename matching and audio-owned progression are prohibited.
- Audio generation filters retired voice assets from manifests. Running `npm run audio:chapters:english` twice consecutively must report no unexpected regenerated voice files.
