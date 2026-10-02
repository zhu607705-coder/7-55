# Current canteen defense, native port

The active `CanteenInteriorScene.startDefense()` invokes `CanteenDefenseRuntime`, a 60-second moving-pushcart game. The older three static cart/exit actions are not equivalent gameplay. `canteen_defense.gd` and `canteen_defense_model.gd` implement the active runtime; Chapter 3 now requests this specialized Control and accepts only replay-verified completion.

## Preserved

- Full source 1672 × 941 canteen plate, original push-cart 4 × 4 sprite sheet, original whole-map camera ratio, source direction-dependent sprite origin and animation cadence
- All 37 original collision rectangles from `data/worlds.json`, exact shared foot body (19.5 × 14.625 source pixels with the original actor-relative offset), authored world bounds, source table/furniture foreground crops
- Player/paper starts; 8 × 4 navigation graph; left/right/up/down BFS link order; all three exact exit/gateway routes and the 24 px escape radius
- 154 normal speed, 264 dash speed, 430 ms dash duration, 1650 ms dash cooldown
- Paper acceleration from 78 to 118 over 60 seconds, source texture-sized rotated paper AABB, 34 px knockback, 720 ms recontact cooldown, 500 ms initial protection
- Seeded Phaser Alea random-exit algorithm, exclusion of the previous exit after contact, automatic retry after 1150 ms with RNG continuity. Failed attempt traces are included in validation before replaying the successful attempt
- Input-driven native keyboard, mouse and touch movement, dash; pause/focus loss freezes time; Escape/P pause; Enter starts/resumes; cancellation does not complete the chapter

Normal runs always begin at zero elapsed time. The source developer `startElapsedMs` shortcut is intentionally not accepted by the normal story request. A manual reset starts the authorized session over; automatic failure retries preserve the original RNG sequence.

## Result contract

Request `{script:"res://scripts/games/canteen_defense.gd", session_id, seed:String, on_success:"c3_defense_result"}`. Result contains `protocol:"canteen-defense-v1"`, same `session_id`/`seed`, 60,000 elapsed ms, 3,600 input ticks, turnaround count, failed-attempt traces and the successful trace. Controller verifies pending session and calls `Model.validate_result(result, pending.seed)`. The validator independently replays movement, source obstacles, paper navigation, collisions, RNG and timing. A bare success flag cannot advance the chapter.

## Tests

Using the writable XDG settings described in `CHASE_RHYTHM_KAYAK_PORT.md`:

- `godot --headless --path godot_native --script tests/test_canteen_defense.gd`
- `godot --headless --path godot_native --script tests/smoke_canteen_defense_ui.gd`
- `node godot_native/tests/verify_canteen_defense_source.mjs`

The input-generated fixture `tests/fixtures/canteen_defense.json` uses seed `"1"` and survives 60 seconds with 82 actual cart/paper contacts. There is no terminal-state seed. The original unmodified TypeScript runtime independently matches all 3,600 paper/exit/BFS/dash/interception steps; maximum paper-position difference is 0.00039 source pixels. The original runtime oracle receives the native collision-integrated player coordinates, so it does not assert physics-engine corner-resolution equivalence. Separate tests cover collision metadata, idle escape, full replay, JSON roundtrip, wrong seed, forged summary, failed-attempt retry, native UI completion and paused/resumed replay.

## Explicit differences and open visual QA

Native movement uses deterministic fixed-60 Hz, axis-separated AABB obstacle resolution. The source uses Phaser Arcade; complex diagonal corner contacts may separate by slightly different subpixel amounts, although rectangles, body, bounds, speed and navigation are unchanged. Source elapsed-time accumulation can land a few picoseconds below 60 seconds; native integer ticks end exactly at 3,600. A paper escape on the terminal tick takes precedence over completion, preventing the original failure-plus-completion callback edge case.

Folded paper is recreated with native geometry and source colors; small foot/shadow/VFX details and voice cues are not fully reproduced. A pause bug discovered during native QA was fixed: pause no longer mutates previous-tick velocity outside the replay trace. The real Control's 60-second paused/resumed run passes replay validation. The main-shell native gallery includes the defense surface at960×540; source-model and input/replay checks establish the simulation contract. Complete physical-device and running-original visual equivalence remain unverified.
