# Native source audio and presentation consumer

## Runtime and ownership

`res://scripts/media/audio_director.gd` is a Node owned by Main. It receives a read-only snapshot Callable through `setup`, listens to `State.action_completed(action, previous, next, result)` through `update_state`, and accepts source event IDs through `cue(id, payload)`. It never imports State, calls a controller, writes a save, grants an item, or completes an activity. Audio failure is always optional.

Main must route native game `presentation_requested(id, payload)` and phone `presentation_requested(id)` signals to this consumer. Remove earlier duplicate legacy music/voice/effect handlers. `subtitle(text, surface)` is backwards-compatible; `subtitle_timed(text, surface, duration_ms, tone)` and `last_subtitle` preserve original toast timing/tone when the shell supports them. Scene subtitles stay with their existing scene owner. `visual_requested(definition)` supplies original enabled presentation definitions, including exact title, detail, mark, priority, and duration.

The existing C3 media host owns voice-memo audition proof, 80% listening threshold and excerpt seek. Chapter4Activity emits its prologue cues to the global director when connected; its standalone fallback remains available for isolated scene inspection. Star-lamp narration remains locally owned. Main excludes only `chapter35_voice_audition_`, so memo forwarding cannot produce a second playback. The connected C4 activity creates no local audio players. Standalone tests can remove these exclusions to exercise all source manifests. The director does not grant memo listening proof.

`reset()` cancels pending cues, stops every player, clears once reservations and lifecycle pauses. `shutdown()` additionally waits for actual AudioStreamPlayback weak references to be released by the audio thread before a test/process exits. It returns false after a three-second failure deadline; it does not silently assume a fixed sleep released resources.

## Exact build-time source export

Run `node godot_native/tools/export-audio-director.mjs`, then use `--check` for reproducibility. Build-time esbuild evaluates the original StoryLine and presentation catalogs. The delivered Godot runtime does not load JavaScript, Node, a browser or a web wrapper.

The export contains:

- 237 IDs merged in the same nine-manifest order as AudioDirector.ts, including both final_chase_started contributions
- All 152 entries of STORY_LINE_CATALOG, including the absence of voice roles on unvoiced lines
- 223 exact asset identifiers, including generated aliases whose filename differs from the identifier, with all referenced existing paths under res://assets/audio
- Every checked-in *.audio.generated.json asset record, including C4 records the old global director did not import
- Original presentation definitions, the exact chapter-four cancellation set, and grapheme-based source text-duration calculations
- The exact source useChiptune.ts twelve-note melody and envelope/timing values

The source act1_area_visited beat references fx_route_checkpoint, which does not exist in the source assets or generated manifests. The consumer intentionally skips this one missing sound and continues. No replacement asset is invented. The 223 resolvable identifiers all load as native AudioStreams in tests.

## Playback behavior

Music, owner-keyed ambient, overlapping SFX and singleton voice use actual AudioStreamPlayer nodes. Text has no audio player. Cue offsets use monotonic scheduling; same-turn ID plus normalized payload is deduplicated. `once` reserves the source asset/key when scheduled, matching the source even if a later scene cancellation prevents it playing. A reset starts a new presentation session.

Asset/start offsets, duration cutoffs, volume, loop, playback rate, event pan and event-preview clamps are preserved. Stereo SFX receive an isolated AudioEffectPanner bus, removed when playback ends. Voice temporarily ducks music and restores its last target gain at finish, replacement or cancellation. Scene-close events implement the source prologue/C4/lake/memo cancellation sets. Missing audio retains a voiced line's source subtitle where the source surface is a toast.

Voiced catalog lines require both kind=dialogue and an explicit voiceRole. Tasks, taunts and unvoiced player/022 entries cannot become voice merely because a payload or cue supplies an asset. Source-authored direct recordings without subtitle keys are played as existing media, as in the original AudioDirector. Chapter-four explicitly authored male_player clips remain source assets owned by Chapter4Activity. There is no TTS or speech-generation implementation.

Background score follows native.settings.music && !ui.musicMuted. Effects/ambient follow native.settings.effects; this does not suppress story voice. Global volume applies independently. ui.musicPlaying is a separate puzzle fact: it starts/stops the original procedural chiptune, irrespective of background-score/effect toggles. The chiptune is local PCM square-wave synthesis with frequencies 523,587,659,587,523,440,494,523,392,440,494,523 Hz; each 260 ms step sounds for 240 ms, with gain exponentially falling from 0.03 to 0.001 over 220 ms. The 3.12-second loop has 48 kHz mono 16-bit samples. ui.musicMuted stops it; window focus loss suspends it without advancing the audio offset. Battery rules still belong to controllers, which change ui.musicPlaying.

## State-derived and explicit event coverage

The complete original PresentationDirector state derivation is ported verbatim in behavior: temporal-maze entry clocks, clock repair, final-chase start, failed-attempt restart, success, and scene close. `tests/export_audio_state_fixtures.mjs` invokes the actual original TypeScript method for 4,096 transition pairs; the Godot test compares every result. No additional state events are claimed to come from that director.

Other source cues are domain or UI events. Native controllers can return `presentation: [{cueId: "source_event_id", payload: {...}}]`; each event is passed unchanged except defensive copying and source cue normalization. A single string or dictionary is also supported. An explicit event ID supersedes the corresponding compatibility-map event even when its payload is richer, preventing duplicate audio from adapters. Transient events such as spotlight hits, chase pressure, timeline sounds and a newly displayed dialogue line must be emitted by the owner at that event. The audio consumer never infers these from Chinese feedback text.

The source-backed compatibility map in the director covers the following native transitions:

- P00/P01 alarm start/stop, wake narration (400 ms), wake warning; P14 attack/laugh aliases; P13 key rotation only, with insertion silent
- P05 network/headphone, P07 water drop, P08 gear drop, P09 key combination, P10 three plant treatments, P11 check-in: the corresponding source flags/items must actually rise
- ActOneBootstrapController: successful c2 recovery, identity, exercise result, triangle/weather/mentor collection, arrow assembly, balance, gamepad purchase/connection, reservation, friend exchange, inventory request, movement quest, completion, and actual dorm/library entry
- LibraryFinalsController: source field changes for entrance record, occupied seat, note, CC98 investigation, catalog success, rule opening/reading, photo label/report, stamped nonperson proof, receipt, attendance proof/rejection, evidence uploads, BD selection, recovery uploads, pass grant/application, backpack eviction and seating; corresponding phase changes for route/entry/complete evidence/top ten/recovery form
- Library 022 dialogue-next uses the exact source `library_story_library_friend_contacted_XX` key, preserving text-only player/022 roles

Each map is guarded by both the native action and the persisted fact/phase/list change. Failed or repeated actions do not play success cues. The action map does not claim transient events absent from those snapshots.

## Early prologue timing

`prologue_interception.gd` emits source P12_Ending event IDs and payloads at actual simulation transitions: blackout start (durationMs 7000); narrator intro on entering deploy/retry; each interception or miss; round failure; lock ready (requiredHoldMs 1400); caught; bargain at caught elapsed 5200 ms; white burst at 8900 ms. Its two player dialogue steps have no voice event. The three exact narrator subtitle segments change at intro elapsed 3400/6800 ms.

The additional transport-only events prologue_playback_paused/resumed/scene_closed are native lifecycle adapters, not story events. They freeze/resume owned players and pending offsets or cancel all prologue-prefixed playback. Closing an old prologue never stops a newly started act-two score. The separate act2_system_dialogue_closed transport event cancels only source system-dialogue voice/SFX, preserving newly issued task-update cues. No audio callback advances the game.

## Verification

- `node godot_native/tools/export-audio-director.mjs --check`
- `node godot_native/tests/export_audio_state_fixtures.mjs --check`
- `godot --headless --path godot_native --script res://tests/test_audio_director.gd -- --fresh`
- `godot --headless --path godot_native --script res://tests/test_prologue_audio.gd -- --fresh`
- Existing `test_early_games.gd` must remain passing

Use writable XDG_DATA_HOME/XDG_CACHE_HOME/XDG_CONFIG_HOME directories in a sandbox. The tests exercise real streams, channel nodes, scheduling, seek, panning, per-role refusal, once/deduplication, settings, chiptune samples, cancellation, source state parity, resource retirement and zero snapshot mutation. They distinguish broad cue playback support from whether another native scene has emitted every transient source event.

Latest focused cloud run: 4,643 audio-director checks, 25 prologue-audio checks, and 15 existing early-game checks, all passing with no Godot SCRIPT ERROR/ERROR output. Native Main also starts cleanly with the integrated director. This was the earlier milestone; the expansion and teardown regression counts below supersede it.

## Expanded active gameplay wiring and freeze evidence

`test_gameplay_audio_wiring.gd` adds real-controller and real-player coverage beyond merely accepting event IDs. It verifies C3 order/pickup/bike/ticket/program/clue/recovery actions, C4 repair and power payloads, procedural sounds and live model-to-presentation adapters. `test_chapter4_audio_ownership.gd` verifies the actual connected Activity/Director pair: no duplicate local players, voice with effects disabled, focus pause, and closing an old prologue without stopping newer clock/chase channels.

The pickup defense request now carries a presentation-only source prelude. Its six authored audio timestamps are 0, 850, 4030, 4930, 5980 and 6500 ms. The source camera/paper/return chains reach the two final dialogue lines at 9580 and 10480 ms, and defense starts at 11380 ms. Reduced-motion preferences do not collapse this narrative timing, matching source `animatePaperBurst`. No physics tick or completion receipt is granted during the prelude.

Procedural fishing and bicycle audio are exported by executing the original `LakeFishingAudio.ts` functions and the original `CanteenChaseOverlay.tsx` sound function against a build-time recording AudioContext. This exports oscillator types, start/end frequencies, ramps, volumes and offsets. Godot creates native 48 kHz AudioStreamWAV samples from those instructions. No browser or JavaScript runs in the delivered game.

The C3 voice mapping now implements the source `chapterThreeStoryLineKeyForSubtitle` trim/whitespace-normalization and exact lookup. It never searches approximately, strips arbitrary speaker names, or voices an entire joined message. The actively referenced Theater wrong-order and reversal arrays are separately exported with the source speaker-stripped grapheme duration plus 120 ms spacing. Reversal requests the existing decoy inspector after its first two lines; inspector close starts the remaining three. Most old C3 catalog lines are not present in current active content and remain silent just as the source lookup does.

The intermittent media-test leak was isolated with Godot `--verbose` to `07_p14_chat_message_notification_ping.mp3`, not the memo playback. The notification-prank owner now stops and detaches both reset/rearmed pings, tracks each actual playback weak reference and supplies an awaited shutdown. The media test awaits both owners before quitting. Three consecutive verbose media runs completed with 30 checks and zero resource/ObjectDB errors.

See `AUDIO_WIRING_COVERAGE.md` for concrete reached routes and explicitly outstanding native presentation work. Broad manifest support must not be described as proof that every source scene milestone already exists natively.

Final focused freeze (2026-10-01): director 4,646 checks; prologue 26; gameplay wiring 43; unified C4 ownership 12; early games 15; Chapter 1/2 46; Chapter 3 controller 69; actual media/charging 30; Chapter 4 114. Canteen defense, deterministic minigame models and minigame UI smoke also passed. The strict run rejects script errors, ERROR output, ObjectDB leaks and resources still in use. Exports pass their --check modes and git diff --check is clean. The source physics model files were not changed by this audio work.
