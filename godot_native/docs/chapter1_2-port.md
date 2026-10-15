# Chapters 1–2 native port

## Implemented ownership

- `scripts/chapters/chapter1_2.gd`: chapter-one phone interactions, network and brightness controls, inventory combinations, check-in validation, prologue terminal validation, chapter-two inventory/movement/identity/payment/reservation gates
- `scripts/chapters/library022.gd`: library investigation, catalog, photo/report, proof form, forum evidence and BD password, recovery application, physical PASS use, seated conversation, chapter-three handoff
- `scripts/games/prologue_interception.gd`: actual interactive interception and hold simulation
- `scripts/games/virtual_run.gd`: ten ordered user-operated positioning points
- `scripts/games/identity_stamp.gd`: report scan followed by explicit stamp interaction
- `scripts/ui/phone_pages.gd`: native source-styled phone scene hierarchy and physical hotspots, 424-pixel inner content uniformly mapped into the unchanged 430×860 shell
- `scripts/chapters/phone_utilities.gd`: shared Settings and home-app management intent validation, independent background-music mute, low-power state, and developer-only fictional-post maintenance
- `scripts/data/cc98_store.gd`: independent, validated local CC98 document persistence and browser-storage import interface
- `scripts/ui/home_app_button.gd` and `phone_drop_button.gd`: real native mouse/touch long press, drag, keyboard editing and inventory drop targets
- `data/native_phone_photos.json`: exact 12-entry photo metadata extracted from the original TypeScript photo catalog; existing images are reused

All progression uses the original shared state dictionary. Player-edited CC98 documents are intentionally stored separately, matching the original localStorage separation. Files under `src/` were read, not modified. Original JSON and assets are read from the native project's copied source data. No web runtime is used.

## Mechanics retained

### Chapter one

Alarm → wake screen → phone. Opening the friend chat starts the authored scatter sequence: code appears at 900 ms, attack at 2000 ms, skip becomes available at 4000 ms. The original audio manifest supplies the 11942-ms attack and 5380-ms laugh lengths; native presentation uses those clocks even when audio is absent. Four concealed glyphs fly along the original pixel-step vectors for one second. Closing the chat cancels the pending visual sequence without granting scattering. The controller commits only after the timeline reports its full terminal proof. Absence record gives the first digit only after scattering; Tiyi requires cellular data, while wrong-network load increments crash count. Auto-rotation separately loosens the settings gear and friend-avatar slash; three subsequent taps take the slash. Music must play before headphone retrieval. Rain and headphone combine into a water container; slash and gear combine into the tower key. The tower has a real inventory drop target. Its key inserts for 650 ms, rotates 90° for 800 ms, then finishes at 1700 ms; the controller consumes the key and grants fertilizer only after that completion. A duplicate drop cannot restart an active insertion. Water, light at brightness ≥80, and fertilizer are independent plant facts. Bloom exposes the flower numeral; a separate pickup grants the final digit. Check-in validates campus Wi-Fi and exact code. Items and inventory selection are removed/hidden immediately on successful check-in.

The prologue uses the original three multi-bend path equations, 2200/1900/1650 ms flight durations, 38%-width error-window paddle, 54%-per-second keyboard movement, three-block goal, three-miss failure, 350/650 ms impact/miss pauses, 1400 ms continuous hold, release reset, and full four-line exchange. Success stamp, coordinate error, red flash, seven-second blackout, deployment, white bursts and whiteout are separate phases. Retry skips the blackout. Focus loss pauses and clears a pending hold. Controller rejects forged-looking incomplete result dictionaries. No direct success action is exposed in phone controls.

### Movement prelude

Friend exchange → system inventory request → dorm desk card → system return → movement quest. Card ownership, identity, exercise, triangle taps, weather drop, mentor-line release, arrow assembly, decimal shift, purchase, installed controls, manual displacement and reservation are independent facts.

Name and student number are entered by the player. Ten virtual-run points must produce the original ten-minute/three-kilometre result. Exercise enables pacing, not player input. Weather water is independent of triangle collection. Arrow is retained after balance shift. Purchase validates authenticated campus-network CC98 and the 600-cent price; it cannot deduct twice. Gamepad must be applied to the named, exercising dorm character before manual control. First actual movement is accepted only through host-provided positive displacement and keyboard/touch input. Current-source system reservation briefing and exact library/room/seat validation remain required before leaving.

The CC98 story login requires reading the campus-card identity. Its fictional password hints are separately revealed. The first three attempts are immediate; the third failure begins a 30-second absolute lock and each further failed attempt adds 30 seconds. The lock timestamp and count persist in original state.

### Library

Library entry, record screen, backpack, note, terminal, shelf, front desk, receipt, PASS and chair use real source-coordinate RPG targets. Host distance/item/mode checks remain required; controller validates phase and item facts. Physical operations also reject dark mode in the chapter controller.

The investigation keeps the 23-floor thread and exactly five optional, non-gating ac01 replies. Catalog shows five authored result cards and distinct decoy reasons. The matching query/result yields the 755 locator, which is consumed at the physical shelf. Original rule reading gates the proof inference. Photo exposure requires brightness ≤20; the original twelve-photo roll and matching 022 old photograph must then be inspected before report generation. Decorative old photographs cannot certify the report. Scan requires an actual 720-ms scan plus stamp, producing non-person proof. Arrow pushes out the 022 receipt. Tiyi's later audit is separate from exercise and validates the three evidence-backed fields. Four valid uploads are required before the BD briefing; original eight numbered replies and ordered four-selection password are retained. Three separate originals must be submitted to recovery before PASS generation. PASS must be used on the physical backpack, followed by sitting and all twenty authored 022 dialogue lines. Handoff preserves previous inventory and evidence and activates the canteen story.

Acquired proof records remain readable on the materials page after submission consumes their inventory instances.

### Phone utility behavior and independent documents

P08 Settings has all eight source sections, working search, precise app-order arrows, default-order restoration, optional-app recovery, independent background-music mute, source brightness state, network summary/link to Control Center, source permission descriptions, activity records and diagnostics. Privacy rows are fictional information, not requests for actual device permissions. Current source marks the old chapter-four Settings audit as legacy-only; no retired progression controls were restored.

The home app grid reads `ui.homeAppOrder` and `ui.hiddenHomeAppIds`. A 460-ms native mouse/touch hold or F2 enters editing; available icons swap through native drag, and arrows, Delete/Backspace and Escape have their source meanings. Locked `xxx` slots have no icon, focus or button. Home swaps reject locked destinations. Settings order controls preserve the source's broader order-list behavior. Only Tiyi can be removed, and only after both automatic exercise and library presence proof; Settings can restore it. Finishing editing stops movement and ordinary activation stays suppressed for the drag release.

Control Center exposes the source low-power toggle. Enabling it clamps brightness to 45 and stops `ui.musicPlaying`; reopening apps is owned by State's original 1%/2% battery cost. Network switching keeps the 1% reserve. `ui.musicMuted` is independent of the music-playing puzzle. P08's own brightness slider uses its source 0–100 range (its source `FlagController.setUi` does not apply the Control Center clamp). The central audio host must map background music to `native.settings.music && !ui.musicMuted`; source voices and effects remain independent.

CC98 displays all 52 authored ordinary posts and phase-appropriate quest posts, original metadata and replies, current/new/followed/board/recent views, and a usable text filter before evidence unlocks. Source top time tabs remain static. The note search shows four actual candidate records with original distinct rejection reasons; dropping the note or pressing Search shows candidates, and choosing the matching record alone submits the investigation intent. Ordinary browsing does not grant story evidence. CC98 preserves its 1600-ms network rejection plus 620-ms exit sequence.

Developer checkpoints alone expose editing, matching source. Author, board, title, reply count, views and time edit in the feed; body has its own native TextEdit page. Explicit Save writes the edited fictional posts; leaving an unsaved session discards local drafts. `user://cc98-posts.json` and `user://cc98-quest-post-overrides.json` survive `State.new_game` and plain story-save imports. Baseline authored replies refresh from source while edited body/metadata survive, and the investigation's rank/reply count remain controller-derived. Restore Defaults is an explicit developer action. Normal player interaction has no editor controls.

`cc98_store.validate_bundle(stores)` and `import_bundle(stores)` accept `{posts?:Array, questPostOverrides?:Dictionary}` (at least one supplied key) from an explicit browser-storage bundle. The importing State service must fully validate the story save before applying these stores. Absent keys in a partial browser-storage bundle leave the corresponding native documents untouched. If the second store cannot be committed, the first store is restored to its exact prior bytes (or its original absence). A plain GameState envelope must not call that import. Tests inject separate file paths and never write the normal document stores.

The builder emits presentation-only cues `xiaoying_attack`, `xy_laugh`, `tower_key_insert` and `tower_key_rotate` through `presentation_requested`. Main connects the two legacy voice cues and key sounds to native audio playback. These cues cannot alter story state or substitute for the original comprehensive audio/presentation director.

## Active-source resolutions

The active controllers/data differ from historical bullets in `AGENTS.md`:

1. Dorm exit currently requires a post-movement system briefing and a `基础馆 / 一层书库 / 022` reservation, in addition to manual movement
2. Active `library-finals.puzzle.json` uses four ordered BD reply IDs (the evidence-derived 3027 sequence), not the older A/C/E reply set
3. Right arrow is retained after the balance operation but consumed at the receipt, matching both `LibraryFinalsController.ts` and `itemCatalog.ts`
4. Current shelf and dialogue data use the one-floor library source map and its measured 755 shelf target

The native port follows those active controllers and source JSON. It does not restore retired login-receipt, free-controls, cartridge, four-map-area, 63-floor, 18-ac01, or citation-chain solutions.

## Verification

Run from repository root with writable HOME/XDG dirs if needed:

    godot --headless --path godot_native --script res://tests/test_chapter1_2.gd
    godot --headless --path godot_native --script res://tests/test_early_games.gd
    godot --headless --path godot_native --script res://tests/test_phone_pages.gd
    godot --headless --path godot_native --script res://tests/test_phone_effects.gd
    godot --headless --path godot_native --script res://tests/test_phone_utilities.gd

Verified on Godot 4.6.3: 46 controller checks, 15 simulation checks, 30 layout checks, 4 real-time UI-effect checks and 40 native utility interaction/persistence checks pass. Coverage includes the complete first/second-chapter progression path and negative gates for wrong network, partial hold/exchange/run, missing light, identity mismatch, login lock, duplicate purchase, nonmovement, wrong reservation, catalog decoy, photo exposure, incomplete scan, wrong audit, wrong BD and missing recovery evidence. Simulation tests exercise real path equations, misses, retry, release reset, full dialogue, ten positioning interactions and timed scan. Utility tests deliver actual viewport mouse events for Settings buttons and held-pointer app swapping, exercise F2/arrow/Escape editing with retained focus, brightness drag commits, restore/removal gates, search/list/thread/editor controls, explicit Save and post-reset document retention, all eight Settings subpages, and explicit browser-storage bundle import. UI timeline tests run the actual native gear, slash, tower and skippable scatter presentation.

Godot headless editor script parsing passed. Cloud graphical validation also rendered the native alarm and exercised start/ring/close/wake/warning; its screenshot was visually reviewed. Layout tests include source424-pixel inner width and uniform338-pixel mobile scaling. Full source-coordinate walkability, comprehensive screenshot comparison and touch-device acceptance belong to integrated host QA and are not claimed by unit tests.

## Remaining parity gaps

This is a functional native controller and puzzle port, not a pixel-identical port of the web phone scenes.

- Main phone surfaces now have dedicated native layouts, source CSS palette and pixel font, original icon art or native equivalent shapes, source-aligned visual hierarchy and interactive hotspots. Remaining differences include exact browser CSS shadows/clipping and some lower-priority utility pages; this is not a pixel-diff-certified replica
- Settings gear and avatar rotation now use the original automatic 1500/1100-ms animated timelines, with validated callback results; they no longer grant progress from inspection clicks. Alarm ringing, flashing wake warning, decimal arrow motion and flower-number pop use native tweens
- WeChat friend/scatter and tower insertion now retain their source phases and timings. Friend list and chat are separate native surfaces; the post-prologue three-message exchange uses its 700/1550/2150-ms delivery. Tiyi has its original 1400-ms normal load and 3000-ms plus 620-ms crash presentation; the native sports page is reconstructed rather than a pasted full-page screenshot. Bonsai reuses original art with independent foreground interaction and growth/number presentation
- Native playback covers friend attack/laugh, wake voice and collection/network/plant/key sounds. Subsequent AudioDirector integration and lifecycle tests are documented in `AUDIO_DIRECTOR_PORT.md` and `AUDIO_WIRING_COVERAGE.md`; audio is not a progression authority
- Library cupboard translation, backpack relocation animation, signal waves and detailed photo exposure rendering are left to the world/presentation host. The gate, inventory effect, scan and conversation are native and validated
- Campus-card identity inputs normalize full-width ASCII and whitespace; browser NFKC contains additional Unicode compatibility mappings that are not exhaustively reproduced
- Settings and ordinary CC98 utility behavior are implemented. Exact utility-page CSS shadows, avatar decoration and browser scrollbar styling still differ. General text search is a native addition over the source's evidence-specific search and board filters. Current-source legacy chapter-four phone puzzle surfaces remain intentionally inactive. Theater quest-post navigation delegates to the existing `c3_ticket_post` UI; mandatory interlude closeout delegates to `c35_journal`

These gaps must remain visible in final delivery notes rather than describing the entire original presentation as migrated.

## Second-batch snapshot notes

The first immutable milestone is `ca7697c`. This batch closes its Settings manager, ordinary CC98 documents and compressed friend/tower presentation gaps. Source anchors: `P08_Settings/index.tsx`, `core/PhoneHomeApps.ts`, `P02_CC98/index.tsx`, `P02_CC98/ThreadPage.tsx`, `P13_PhoneHome/index.tsx`, `P14_Wechat/index.tsx`, and their scene styles. The source shell remains 430×860 with a 424-pixel content interior and uniform scaling.

Headless tests check width and real UI input. The integrated native desktop alarm screenshot from the first milestone was visually reviewed. Subsequent actual phone/CC98 captures and AudioDirector integration are recorded in their focused documents. Running-original pixel comparison remains unverified; this earlier snapshot is not a pixel-identical acceptance claim.
