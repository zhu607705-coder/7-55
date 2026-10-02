# Chapter 3 source dialogue queues and approach

## Source consumers

The native `chapter3.gd` controller now consumes the active authored dialogue queues instead of returning newline-joined, overwritable feedback. Every line is loaded from the unmodified copied `chapter3-canteen.content.json`, `chapter3-theater.content.json`, or `chapter3-qizhen-lake.content.json`.

The source oracle executes the original `CanteenInteriorScene.queueDialogue`, `TheaterInteriorScene.queueDialogue` (including the original `AudioDirector.textFeedbackDuration`), and `QizhenLoopScene.queueTransitionSubtitles` in a deterministic timer context. `export_chapter3_narrative_source.mjs --check` verifies 21 queue schedules / 49 line entries and source hashes. It does not reproduce native scheduling code as its own expected result.

| Source queue | Native consumer |
| --- | --- |
| Canteen tray intro (3) | `canteen_tray_intro` |
| Tray third return: correct-return reply + completion (5) | `canteen_tray_complete` |
| Tray ordinary return (1), after completion (1) | `canteen_tray_return`, `canteen_tray_done` |
| Queue challenge (2), bad drink (2), queue shift (2) | `canteen_queue`, `canteen_bad_drink`, `canteen_queue_shift` |
| Correct/wrong order (1 each), pickup dark clue (1) | `canteen_order`, `canteen_pickup_clue` |
| Defense victory escape (3) | `canteen_escape` |
| Theater entry (3), ticket printed (1), ticket combined (2), admission (3) | `theater_entry`, `theater_printed`, `theater_combined`, `theater_admission` |
| Wrong program (2), prop ghost/manager (2), incomplete console (2) | `theater_wrong_order`, `theater_prop_ghost`, `theater_console` |
| Theater → lake approach: 3 visual lines interleaved with 4 dialogue lines | `qizhen_approach` |

The final theater reversal now uses this same exclusive owner: the exact1320 ms locked/cracked/fragments/escape presentation, two original lines, automatic real decoy inspector, actual user close, then three original lines. Its two source queues are independently evaluated by the oracle. The old audio-only reversal queues are suppressed for this owner. Canteen entry paper and final 022 opening likewise remain with `c3_scene_host`, documented separately in `CHAPTER3_SCENE_TIMELINES.md`.

## Timing, input and voice ownership

`c3_narrative_session.gd` is runtime-only and state-/host-bound. Canteen normal queues use the original 2500 ms step (2380 ms visible, 120 ms gap); victory uses 1200 ms. Theater uses the original speaker-stripped grapheme duration plus 120 ms. These source queues are timed, not click-to-skip dialogues.

`c3_narrative_host.gd` mounts the native subtitle Control inside the actual960×540 world SubViewport, plus source-projected paper/trail view. Split/mobile layout cannot spill the subtitle onto the phone. Hidden-world and focus pause retain the same line and voice position. Ordinary subtitles block interaction, item drop, mode change and underlying progression but preserve real collision-aware walking. Approach and victory animations additionally block movement. Focus pause/resume and reset stop or pause only `chapter3_story_line` voice ownership. The exact original normalized subtitle key is emitted once at each line's onset, rather than asking audio to interpret a multi-line summary. The old wrong-order audio scheduler is suppressed while this new owner is active; its rejection sound remains.

State/main/world hooks share one controller queue. `State.get_c3_narrative_session(delta_ms=0)` obtains the current session; `host.setup(world,state_reader,provider,State.act,cue_sink,runtime_reader)` installs playback. `blocks_input()` and `blocks_movement()` are deliberately separate. Only `c3_story_complete` with the issued, fully played session can acknowledge a callback.

The host forwards Main's actual RPG `world_display_scale` to the subtitle view. The logical world remains 960 × 540; narrow-screen body text is sized to at least 15 physical pixels and speaker text to at least 13, with font-metric wrapping rather than an unreachable logical-width mobile check. `test_narrative_readability.gd` verifies physical sizes, exact text and wrapped containment at 390, 430, 960 and 1280 pixels. The separate opening and canteen-paper owners use a 14-pixel story-text floor, documented in `CHAPTER3_SCENE_TIMELINES.md`.

## Causal callbacks and recovery

- Auntie introduction now starts the tray task only after all three source lines, as the original scene callback does
- Delivery wages/items retain the original controller timing before dialogue; repeated conversation cannot issue them again. The third delivery includes the previously omitted initial correct-return reply
- Defense still requires the genuine full input replay. Its final actor/paper positions are recovered from replay, not trusted terminal coordinates. Then source victory motion (760+260 ms, reduced 160+60), three escape lines, and exit traversal (175+300 ms, reduced 46+120) precede the actual campus transition
- The bike uses the original north-up campus anchor (3220,650), radius 170. It is no longer an invented interior object, so the automatic source exit preserves the following puzzle
- Reversal grants its original source facts only from the genuine1320 ms visual receipt. Interaction stays locked through two lines, a real inspector close and the last three. Boolean `native.c3_reversal_pending` is presentation-only and shape-validated: interrupted native saves resume the unacknowledged narrative without duplicating source rewards; original completed source imports without the marker remain completed.
- Theater admission keeps the original immediate checkpoint/phase fact; its full dialogue and fade precede physical auditorium placement
- Approach uses the original map waypoints, wet-paper geometry, lead/trail/fade timings, and 160 ms startup. At 20800 ms after startup the controller alone sets `locationBriefingSeen` and `campus_qizhen_transition_stop`. No early final answer is added
- The promo sequence adds a same-session `c3_promo_visual_complete` source boundary before the two queue-shift lines; it sets `queueGapOpened` only after3999 ms (1040 reduced), with a220 ms startup on interrupted-save recovery.
- Cancel/reopen restarts an unacknowledged runtime queue. Replacement state invalidates old receipts. Incomplete approach reload starts at the theater-side route; completed approach does not replay. Theater entry follows the original scene-mount condition (entry_ticket, uncleaned poster, unread code)
- Phone summary pages no longer dump future theater/approach dialogue or the canteen's post-escape prompts before the presentation

## Verification and remaining visual limits

- `test_chapter3_narrative.gd`: source-oracle schedules, voice onsets, early/foreign/forged/stale acknowledgements, pause/cancel/reopen, one-time flags/rewards, verified defense exit, bike continuation, actual presentation-host waypoints and source-valid save fields
- `test_chapter3_narrative_shell.gd`: actual `main.tscn` + shared State + real world collision/movement/input hooks; source dialogue, source route, reset, mode/navigation/item locks, successful actual-file saves
- `test_chapter3.gd`: 72 chapter-chain checks now complete genuine timed sessions instead of bypassing them; lake sections retain their separate real-world owner
- `test_gameplay_audio_wiring.gd`: 43 source-event checks, including sole wrong-order voice ownership and real native playback

These tests establish content, temporal order, controller causality and native lifecycle integration. They do not claim pixel-identical browser rendering or a complete manual campaign playthrough. Graphical captures are separately generated from actual Main/State-issued sessions. Canteen promo/queue choreography and source door leaves now have separate native source consumers documented in `CHAPTER3_WORLD_LAYERS.md`. Theater reversal additionally has `test_chapter3_reversal.gd`:42 checks against actual Main inspector and actual save_game/load_game before and after1320 ms and during inspection, repeated callbacks, source fact timing, split/narrow viewport containment, and hidden-world pause without duplicated voice.
