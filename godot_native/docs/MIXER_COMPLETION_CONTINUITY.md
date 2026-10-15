# Native mixer completion continuity

This follow-up was stacked on PR #89 (`00c65413`), whose tested local tree is
identical to local commit `383f3879`. After #89 merged, #93 was retargeted to
`godot-version`. The mixer changes affect presentation only; the separately
identified movement correction below was found by the full CI suite.

## Lifetime and authority

- `State.act` still consumes each ingredient, validates the authored recipe,
  grants the original good/bad drink, resets the sequence, increments the
  attempt and saves immediately. No controller, recipe or story asset changed.
- Accepted pour presentations are queued in actual input order. Fast input
  does not replace an in-flight bottle. Missing repeated clicks retain source
  feedback without replacing the accepted motion.
- The original mixer session closes on the terminal attempt. Its panel retains
  the existing independent glass/bottle assembly only for an optional tail.
- Normal motion finishes the existing 600 ms final pour, retains the full
  three-layer glass, settles for 100 ms, displays the controller result for
  340 ms and fades the native panel back to the retained world over 220 ms.
  The original world subtitle remains readable after the panel disappears.
- Reduced motion keeps the existing 220 ms pour with no bottle travel/wave,
  then shows the result for 160 ms and returns over 100 ms without settling.
- Escape/Exit remains immediate throughout the tail. Replacement state, scene
  exit, another attempt, teardown and synchronous dismissal cancel queued
  visual work. A stale completion cannot dispatch a second transaction or
  close a newly opened panel. Input targets use transparent disabled styles.

## Verification

- `test_mixer_completion_continuity.gd`: 110 deterministic assertions covering
  immediate exactly-once commitment; correct and incorrect mixtures; actual
  queued order; fixed cup contact; retained full glass; reduced motion; resize;
  transparent input lock; each dismissal phase; reentry; replacement/scene/
  attempt changes; and replacement, navigation or dismissal during dispatch.
- 15 focused native scripts: 27,444 checks, zero failures on the final source.
  Existing integration tests wait for presentation completion only after
  checking the already committed controller reward. These are focused checks,
  not a full native regression-suite or fresh-campaign claim.
- Original TypeScript mixer and C3 device fixture export checks remain equal.
- Godot 4.6.3 actual cloud Linux input at 1280×720: one uninterrupted correct
  recipe take, including physical bottle pours, completed glass, result,
  native fade and world subtitle. At 390×844: wrong-order completion,
  automatic return, physical Space reentry, missing feedback and Escape.
- One baseline take uses the original PR #89 scripts. The new demonstration
  uses one take at real captured wall timing and one fixed viewport crop.
  No intermediate cuts, reordered takes, optical-flow frames, inserted poses,
  CSS fades or fake completion events are used. Trailing idle time is trimmed.

## CI-discovered exact waypoint correction

The first full native CI run failed the unchanged canteen queue-floor test's
strict foot-center arrival assertion. The mixer tests and full campaign passed.
A deterministic native-frame probe reproduced early `arrived` at about 0.004
source pixels short: coordinate-relative `is_equal_approx` retired a waypoint
before `move_toward` reached its exact endpoint. This pre-existing movement bug
depends on the frame delta; an ordinary local rerun did not always expose it.

`world.gd` now retires only the exact waypoint returned by `move_toward` and
processes a zero-length waypoint through the same collision-checked path.
The original speed, 50 ms simulation cap, one-waypoint-per-frame behavior,
collision tests, input ownership and strict canteen assertion are unchanged.
`test_mobile_floor_exact_arrival.gd` deliberately stops 0.004 pixels short of
each real dogleg waypoint, then checks exact arrival, zero-length completion,
ordered large-delta traversal, the speed cap and unchanged progression.

## Limits

Chapter location, ingredients, read-shelf fact and shuffle seed are explicit
local fixtures before interaction. These captures do not prove earned
full-campaign, physical-phone, Windows, audio, export or release acceptance.
Some earlier desktop fixture processes were terminated after/before complete
capture; the shell reported `Killed` without a verified cause. The final
successful takes and compact reentry checks are saved separately. They are
not evidence of long-duration stability. Remote CI remains a separate gate.
