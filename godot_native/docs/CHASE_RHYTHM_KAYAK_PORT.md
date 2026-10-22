# Native chase, rhythm fishing, and kayak controls

## Implemented mechanics

- `scripts/ui/minigame_host.gd`: native Godot Control with `setup(config)`, `finished(result)` and `cancelled`. The logical surface is 960 × 540. Start, active play, pause, retry and verified-terminal presentation are mutually exclusive. Controls include keyboard, mouse and individually tracked touch pointers. Pause/focus loss clears held inputs and freezes simulation time; retry creates a new model. No direct success button or audio-dependent progress.
- `games/chase_stunt_model.gd`: fixed 120 Hz port of `ChaseStuntModel.ts` and the gameplay portion of `ChaseGeometry.ts`. Continuous steering/inertia, release-to-jump charge, ramps, source obstacle beats, correct obstacle heights, lives/replenishment, invulnerability, tray shield, gust boost, bell clearing, score/combo, and 755 m finish are retained. Result proof replays every input tick. Native display uses the original calibrated 273-frame distance atlas and rider sprite sheet, projected source lanes, runtime hazards and pickups.
- `games/rhythm_fishing_model.gd`: `lake-rhythm-v4`, including initial aim/charged cast, four-beat count-in, per-chart beat patterns, moving fish tracking, line tension/rushing, stable held-line requirement, release-time grading, 75% pass threshold and full input trace replay. Loads the four original chart JSON entries. Does not substitute the obsolete v3/four-button chart. `notes_hit` can be below `total_notes` on a legitimate passing run.
- `games/kayak_model.gd`: exact source forward/reverse impulse, drag, yaw, roll decay, alternating recovery, repeated-side capsize and cadence rules; retained isolated model fixtures. Actual gameplay now uses the live-world source boarding/controller portal/chase path; rainy launch uses its authored recovery sequence, not four strokes. Swan chase preserves the source release/tracking/telegraph/charge/recovery states, gap-sensitive speed curves, final-bank modifiers, lateral aim, grace period and catch threshold. Input proof replays to actual terminal success.
- World integration: `configure({phase:"world", bounded:false})`, set `position:Vector2` to the current source-map pose, call `stroke(side, reverse)` and `update(seconds)`. The map owner constrains proposed source coordinates, stops `speed` on a collision, and preserves `heading` and `roll`. This avoids duplicate general-purpose walking controls for a kayak.

## Controller contracts

- Chase: `{mode:"story", protocol:"chase-stunt-v1", distance:755, lives, collisions, score, stunts, ticks, inputs, success:true}`; verify with `Chase.validate_result(result)`.
- Fishing: original v4 result fields plus `spotId`, `session_id`, `success`, `notes_hit`, `total_notes`; verify with `Fishing.validate_result(result, expectedChartId)` and separately validate the pending session/target.
- Kayak: `{protocol:"kayak-strokes-v1", phase, session_id, target_zone, distance, goal, strokes, alternations, capsizes, ticks, inputs, success:true}`; verify with `Kayak.validate_result(result, pendingConfig)` and separately validate the session/target. Tutorial success uses the last four alternating forward strokes, so previous recoverable mistakes must not invalidate success.
- Trace validators accept finite integral JSON numbers, preserving replay after serialization. Bare summary dictionaries, wrong protocols, altered statistics and missing traces are rejected.

## Verification

Run from repository root, with writable XDG directories (the container's default user directory is read-only):

```sh
export XDG_DATA_HOME=/tmp/godot-game-data
export XDG_CONFIG_HOME=/tmp/godot-game-config
export XDG_CACHE_HOME=/tmp/godot-game-cache
godot --headless --path godot_native --script tests/test_minigame_models.gd
godot --headless --path godot_native --script tests/smoke_minigame_ui.gd
node godot_native/tests/verify_source_model_parity.mjs
```

The model suite generates reusable input-driven fixtures in `tests/fixtures/`; it covers actual collisions, charge/release, tray collection and shield, bell range, all four chart successes/replays, forged traces, idle clock, failed cast, same-side capsize, boarding/rain/travel/chase, reverse movement, world coordinates and JSON roundtrips. The independent TS oracle accepts all four unchanged native fishing traces (8/8 perfect) and produces the same chase distance/lives/collisions/score/stunts. The TS tool is test-only; native runtime does not use JavaScript.

## Explicit remaining parity gaps

- Native hazard art, fishing foreground, water/wake and swan presentation use simpler runtime drawing; the detailed Three.js chase rendering, roadside pedestrian decoration, full VFX, narrator/audio cue timeline and source camera choreography are not reproduced here. Original background/character art is retained. This is mechanics parity with native presentation, not a pixel-perfect presentation migration.
- The generic bounded kayak model remains a historical regression fixture only. Active lake controls now use original four-zone collision data, source instant portal transitions, live boarding and source-channel swan chase with controller-issued receipts. `test_lake_live_world.gd` (4370 source-oracle checks) and `test_lake_shell_input.gd` (16 real shell input checks) cover this integration.
- Pause currently caps a single process update at 100 ms to avoid an unresponsive stall advancing multiple seconds. This is an intentional wall-clock presentation difference; model replay itself is deterministic.
- The unchanged source chase collision rule (`abs(lane-obstacleLane) < .36`) permits riding between integer lanes. The native version preserves this rule; the input-generated win fixture exercises it. Tightening collision widths would be a gameplay balancing change, not a migration-only fix.
- Headless construction/input/pause/retry tests pass, but this environment has no display server. A real rendered 960 × 540 and scaled-touch visual inspection is still required before claiming visual QA.
