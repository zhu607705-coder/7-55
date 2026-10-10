# Library 022 authored story sequences

## Source and ownership

The active source is `src/data/library-finals.content.json`, routed by `src/data/libraryFinalsStory.ts`, `src/App.tsx`, and `src/components/LibraryStoryOverlay.tsx`. `LibraryFinalsController.ts` owns the acknowledgement facts. The native source JSON remains byte-identical; no author dialogue is rewritten.

`library022.gd` now requests all twelve authored `storyDialogues` sequences (53 speaker/text lines). `library_story_session.gd` plays one line at a time. `library_story_view.gd` owns the only visible subtitle and modal input surface. `library_story_host.gd` queues presentation, emits the source `library_story_line` cue with exact subtitle key, and submits a controller-issued completion receipt. Neither timing nor audio writes gameplay facts.

The separate twenty-line `library_friend_contacted` conversation still belongs exclusively to the existing `c3_scene_session.gd` / `c3_scene_host.gd` opening, including its seven cinematic beats and Chapter 3 handoff. The source App event map also names `library_route_unlocked`, but the authored data has no sequence with that ID; the native implementation likewise does not invent one.

## Exact event coverage

| Native successful intent | Source sequence | Lines |
| --- | --- | ---: |
| First `lib_enter` only | `library_entered` | 12 |
| `lib_backpack` | `library_occupied_seat_found` | 4 |
| `lib_investigate` | `cc98_occupation_post_opened` | 3 |
| `lib_catalog_select` | `library_catalog_match_found` | 2 |
| `lib_read_rule` | `library_archived_rule_recovered` | 7 |
| Eligible `lib_front_desk` request | `library_front_desk_proof_request` | 5 |
| `lib_scan_result`, delayed 900 ms | `library_bag_nonperson_proof_issued` | 2 |
| `lib_audit` | `tiyi_presence_proof_issued` | 5 |
| Fourth valid `lib_upload` | `cc98_evidence_set_completed` | 4 |
| Successful `lib_bd_submit` | `cc98_top_ten_reached` | 1 |
| `lib_generate_pass` | `library_seat_release_pass_issued` | 2 |
| `lib_apply_pass` | `library_backpack_evicted` | 6 |

This restores, among other omitted lines, the system's reveal that her friend is seat 022 and the backpack exchange “什么时候？” / “三分钟。”

## Acknowledgements and interaction

The rule, front desk, bd, and PASS acknowledgement flags stay false until their complete sequence has been presented. Only `library022.gd:lib_story_complete` may write them, after it validates both an authentic state-bound, single-use session and current puzzle prerequisites. Passing a dictionary, an unissued object, an early receipt, a receipt from another save, or an already-consumed receipt cannot advance the story.

The final bd line requires a click, touch, Space, or Enter. A timer can never acknowledge it. The old `lib_bd_briefing` action now requests dialogue; it no longer bypasses it. Missing rule, bd, and PASS acknowledgements are recovered after load with the same source priority. The front-desk request can be repeated through the actual front desk if interrupted, as in the source.

Timers use the source `clamp(1600 + 120 × visible graphemes, 2400, 6500)` duration for all 53 current lines. Each line gets a new timer; a long frame cannot skip multiple lines. Native focus loss pauses timers and input. This focus/catch-up policy is an intentional native safety adaptation; the source browser uses `setTimeout`. The 900 ms stamp delay uses focused frame time, with per-frame catch-up capped at 100 ms. The delay itself does not block input; the dialogue blocks only after it begins.

Every key event is captured by the modal, including Tab and Escape; only Space/Enter advance, and Tab retains focus. Pointer/touch events are captured before lower UI controls. Emulated mouse-from-touch events do not double-advance. World targets are temporarily absent while a story is pending.

## Integration API

- State provider: `get_library_story_session(delta_ms: float = 0)`, delegating to the chapter-one/two controller's `library.story_session(d, delta_ms)`
- Host: `setup(state_reader, session_provider, action_sink, cue_sink, runtime_state_reader)`
- State reader must return the authoritative dictionary, not a duplicate, to retain receipt identity
- Action sink receives `lib_story_complete` and the runtime receipt
- Cue sink is the existing audio/presentation cue consumer
- `blocks_input()` belongs in the shared world/input lock
- Reset host on state load/reset and gallery switches; do not serialize sessions or replay timers

## Verification

`node godot_native/tests/export_library_story_source.mjs --check` checks the source-derived fixture, including hashes, source App event mapping, 900 ms delay, required-confirmation set, every speaker/text pair, every generated subtitle key and every source-evaluated grapheme duration. It also asserts that copied native library content is byte-identical.

`godot --headless --path godot_native --script res://tests/test_library_story_sequences.gd` passes 718 checks. It traverses all 12 sequences/53 lines through the actual controller, validates one-time/stale/early/forged completion gates, checks the delayed stamp and mandatory bd confirmation, exercises real viewport keyboard/mouse/touch input, and checks real shell State/world integration, and checks all lines for clipping at 390×844, 430×860, 960×540 and 1440×900.

`test_chapter3_scene_timelines.gd` independently passes 81 checks, confirming the existing final022/C3 opening owner is unchanged.

For graphical acceptance, run the story test with `-- --capture` in a graphical Godot session. It writes eight entry-reveal/bd-confirmation screenshots across the four viewports under `.screenshots/library-story/`. The headless line-fit checks are not a raster visual review or a full continuous manual playthrough. Real shell integration is also exercised in the suite. GUI acceptance remains separate.
