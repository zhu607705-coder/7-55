# Chapter 2 → 3 opening and canteen entry paper

## Source authority

- `src/components/ChapterThreeOpeningOverlay.tsx` supplies the exact opening beat builder, advance/skip controls, focus pause, 100 ms visible-frame catch-up limit, and presentation cues
- `src/styles/chapter-three-opening.css` supplies the library plate, 022 record panel, mode card, paper burst, footprint/cart route, chapter card, subtitles, mission arrival, and letterboxed 960 × 540 layout
- `src/data/library-finals.content.json` supplies all 20 current 022 lines without rewriting. The existing source slices yield 27 beats, not 26 dialogue lines
- `src/scenes/rpg/CanteenInteriorScene.ts` supplies source queue paper origin (1053,302), idle bounce, 360 px discovery radius, surprise/dialogue delays, seven-segment escape, camera behavior, four procedural paper walking frames, afterimages, and post-escape prompts
- `src/modules/LibraryFinalsController.ts:complete022Dialogue` and `ChapterThreeCanteenController.ts:completeEntryPaperEscape` remain the progression reference

## Native ownership

`library022.scene_session(state)` and `chapter3.scene_session(state)` issue runtime-only `c3_scene_session.gd` capabilities bound to the authoritative state dictionary and one presentation host. They never serialize session objects, elapsed times, or renderer fields.

`lib_dialogue_next` cannot grant the chapter. The native modal presents the exact dialogue automatically, allows click/Enter/Space to advance the current beat, traps Tab between advance and skip, and sends skip to the arrival beat. The user must advance arrival or let its complete duration elapse. Only `lib_opening_complete` with the controller's completed capability initializes the canteen hunt and returns to `campus_library_gate`.

Entering the canteen no longer sets `entryPaperEscaped`. The queue paper is visible and floats until the player's collision-resolved state position is within 360 px. Discovery locks world input while the original surprise, chase route, and camera return play. All world targets and physical controller actions are gated until the authentic `c3_entry_paper_complete` receipt. Both original system prompts appear afterward at 1600 ms intervals, without blocking movement.

`c3_scene_host.gd` processes after the world (`process_priority=50`), uses separate authoritative and copied-runtime readers, and owns:

- `c3_opening_view.gd`: full-screen native 960 × 540 letterbox and controls
- `c3_canteen_paper_view.gd`: world-projected paper, speech, alarm, afterimages, and prompts
- `c3_paper_art.gd`: literal Phaser-generated 64 × 50 polygons, dot-matrix print, and four walking frames

No replacement map or illustrated paper image is substituted. The opening uses the original library image. Source CSS presentation is rebuilt as native drawing and native controls rather than embedded HTML.

On narrow screens, story text has a 14-physical-pixel minimum. The opening is already in Main's screen space and uses a measured, wrapped bottom panel inside its unchanged 16:9 letterbox. Canteen speech bubbles and post-entry prompts remain children of the 960 × 540 world; their font sizes compensate for Main's actual `world_display_scale`, and their readable rectangles are clamped to the visible world. World coordinates, camera zoom, source content and timers are unchanged. Desktop opening and paper typography keep their original layout.

`test_chapter3_scene_readability.gd` adds 817 actual-shell checks at 390, 430 and 1280 pixels: all 27 controller-issued opening beats, original text preservation, measured wrapping, physical font floor, panels bounded to half the world, non-overlapping advance controls, real scale propagation, canteen speech/tail containment and the authentic entry completion lifecycle. The source advance triangle is drawn as native button geometry because the bundled pixel font does not render its glyph; its action, hitbox and arrival label remain unchanged. Graphical acceptance uses separate real-session captures; these checks do not substitute for real mobile-device testing.

## Lifecycle and integrity

- Generic result dictionaries, foreign/early sessions, foreign hosts, spoofed proximity, and duplicate completions cannot advance either gate
- Replacing the state dictionary on save import invalidates the old session. Loading a pending checkpoint reconstructs a fresh scene from the original starting pose
- Leaving the scene or story reset cancels the presentation without granting progress or retaining input/camera locks
- Window focus loss pauses timelines; a hidden root host does not run while the visual-gallery preview is active
- Reduced motion preserves dialogue duration and every route stage. Its player/paper speech bubbles overlap as they do in the source
- The canteen host does not change shared player visibility, so it cannot interfere with the rain-rescue actor handoff

## Verification

- `node godot_native/tests/export_chapter3_scene_source.mjs --check`: verifies the committed fixture is identical to evaluating the original TypeScript opening beat helper
- `godot --headless --path godot_native --script res://tests/test_chapter3_scene_timelines.gd`: focused controller/model/host tests, including a real `main.tscn` + `State` + `world.gd` integration and reset
- `test_chapter1_2.gd`: the story handoff now completes the actual native opening session, rather than trusting repeated phone actions
- `test_chapter3.gd`: its later-mechanics fixture explicitly begins after the separately tested entry scene
- `visual_gallery.gd`: original developer checkpoints `c2-seat-dialogue` and `c3-canteen-entry`, actual controller-issued sessions, source-phase/timestamp metadata, normal native controls, and real rendered viewport captures. These captures explicitly do not claim a full interactive story playthrough

The logical opening beat data, progression gates, dialogue, and entry timing are parity-tested. Native drawing is a reconstruction of the source presentation; pixel-identical browser CSS rendering is not claimed.
