# Independent Qizhen CHANNEL chase model

The local scene uses `scripts/games/qizhen_playable_chase.gd`, a rendering-independent `RefCounted`. Original kayak and swan models are unchanged.

## Player contract

- `new()` / `reset()` create an inactive intro state; `begin()` starts simulation. `reset(true)` skips the intro for retry
- `stroke("left"|"right", reverse=false) -> bool` accepts only real, globally spaced inputs, at least 0.20 seconds apart. Paused, intro, and completed attempts reject inputs
- `step(delta)` simulates at 120 Hz; `set_paused(bool)` freezes elapsed time and both actors
- Max forward speed 100 px/s. Alternating forward strokes apply 26 px/s; a non-alternating stroke applies 17 px/s. Drag is 0.65/s. Holding an alternating controller at 0.46-second cadence does not force a fixed completion time
- Same-side steering is allowed. Warnings begin at five consecutive strokes; fourteen consecutive strokes or excessive roll causes failure. These thresholds are configurable
- `accepted_inputs` records actual accepted events with tick, time, side, reverse, and alternating state. `route_history` contains sampled actual player positions

## Physical route

All coordinates use the original 1672 x 941 CHANNEL artwork. The complete original 28 `channel.kayakCollisions` rectangles are retained, including all world edges. The kayak hull is an oriented rectangle with half-length 38 and half-width 22, checked with SAT during translation and swept rotation.

The route begins at (1390,350), heading west. The raft can be passed through any physically legal upper or lower water. A route label never narrows the physical corridor. The final gate consists of local rectangles x230..250, y174..430 and y560..770. The passable gap is y430..560. A visible local rock at x235..272, y640..677 also has a collider.

Completion requires all of the following:

1. Actually pass the raft region and cross x410 westward
2. Actually cross x240 westward through the physical opening
3. Remain inside berth x115..190, y450..545, with a collision-free hull
4. Face west within 0.32 radians, move at no more than 18 px/s, and remain valid for 0.60 seconds

There is no elapsed-time victory, player teleport, auto-navigation, forced rail, scene transition, or save mutation. A completed berth takes priority over contact on the same simulation tick. The only story handoff is `next_story = "3.5"` after victory.

## Swan and safe inlet

The warning freezes `swan_lock_origin`, `swan_attack_heading`, and `swan_aim`. Warning lasts at least 1.25 seconds. The bird turns to the locked direction before charging, then holds its actual body direction for the entire attack. It cannot retarget the moving player during a charge.

Charge speed is 285 px/s for up to 1.35 seconds. Recovery lasts 3.4 seconds with an 8 px/s target; the first 0.45 seconds brake along the attack direction before turning. Tracking speed varies from 45 to 162 px/s with distance. All swimming is continuous, acceleration-limited, and blocked by the map. Navigation uses visible direct paths or the player's physically travelled water trail; no actor is teleported to the trail.

**天鹅在浮绳外终止追逐，玩家仍须减速停泊。** This is a local territorial rule for this independent level, not a change to the original swan model. The bird's whole body remains east of x272 (center at least x294 for radius22). It brakes before that border, and a charge reaching it enters recovery. The kayak can pass the gate and berth normally. Contact does not reach through the boundary. Initial idling still loses.

## Verification scope

`tests/test_playable_chase_model.gd` covers initialization, pause/resume/reset, minimum cadence, duplicate input rejection, no idle movement/time-win, idle capture, fixed aim, fixed charge direction, full oriented collision, collision escape by reverse stroke, original geometry retention, gate bypass prevention, legal upper/lower raft-corridor edges, all berth conditions, same-tick finish priority, continuous territorial braking, and final-state immutability.

The corridor-edge and berth tests deliberately use local fixtures to isolate physical rules. They do not claim a complete human playthrough. An earlier unsuccessful experimental navigation policy is excluded from the release source. It is not a passing test or demonstration and never drives the shipped scene.

The default suite now also replays the recorded successful upper-route keyboard attempt: 59 strokes, 3118 simulation ticks (25.983333 seconds), 0 collisions, 3 dodges, real gate passage, and 0.6-second low-speed berth. It finishes with `won → 3.5`. The video and original telemetry are separate artifacts. A second default fixture verifies the complete lower route with an explicitly automated input sequence: 74 strokes, 2456 ticks (20.466667 seconds), 0 collisions, 2 dodges, real gate passage, and 0.6-second berth. The input generator only mirrored an early recorded input prefix and then called `stroke` / `step`; it never set player/swan coordinates, changed model parameters, or disabled the swan. This is deterministic automated playability evidence, not human footage. Both routes are replayed from the normal start state in the default test suite.

An additional recorded complete attempt can be verified with:

```
godot --headless --path project --script res://tests/test_playable_chase_model.gd -- --replay=/absolute/path/result.json
```

The replay uses only accepted input events and ticks; it never applies recorded coordinates. Actual manual playthrough coverage and duration are recorded separately by the presentation controller.
