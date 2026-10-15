# Native canteen pickup film

The accepted third-window ticket action still owns the transition to `exit_blocking` and creates the existing defense session. The new film is a presentation-only prelude inside that same activity. It does not submit victory, consume an item, modify a saved fact, or advance the defense simulation.

## Restored source sequence

| Time (ms) | Source presentation |
| --- | --- |
| 0–850 | 0755 ticket travels to window 3, then shrinks away |
| 850–1500 | Window glow and quiet beat |
| 1500–2630 | Camera pushes to the window |
| 2630–4030 | Original 5-frame auntie push sheet at 3.6 fps |
| 4030–4930 | Original package waits with 6 fps bubbles; auntie fades for 260 ms |
| 4930–5980 | Original package frames 0,1,0,2,3,4 at 5.7 fps |
| 5980–6500 | Original 4×2 burst sheet at 15.4 fps and 22 local particles |
| 6500–6980 | Camera impact and “本人马上回来。” |
| 6980–8040 | Original folded paper flies and bounces twice |
| 8040–8930 | Crowd retires; camera pulls back, with the authored brief cart preview |
| 8930–9580 | Cart flashes twice and settles |
| 9580–11380 | Two original dialogue lines, then the existing defense starts |

Original sheets are reused without regeneration. `c3_paper_art.gd` remains the source of folded-paper geometry. `c3_pickup_timeline.gd` is a pure time sampler; frame rates, delays and cue boundaries are independent of render frame rate. Reduced motion preserves the complete 11.38-second sequence, suppresses camera shake and shortens burst particles to the original 160 ms.

`Main` supplies the existing native furniture renderer, actor animation clock, player position and camera before setup. The film makes a private presentation snapshot for the 31 source light-mode actors, retaining their queue offsets and source animation phases until 8040 ms. The actual controller state remains `exit_blocking`. Furniture stays on the same registered native object geometry during the film and the defense.

The chase camera follows the paper using a deterministic 60 Hz presentation sampler with the source .07 follow factor and 90×60 deadzone. Burst particle variations are stable local presentation values and do not consume the defense RNG. These are native presentation implementations, not a claim of engine-level pixel identity. Compact screens use one clipped film viewport; the normal overview, movement controls and simulation return only at the final handoff.

## Validation

- `node godot_native/tests/verify_canteen_pickup_source.mjs` executes the original `animatePaperBurst` method with a chronological test scheduler and verifies both motion preferences, all eight source cues, all animation frame sequences, actor admissions and dialogue timings. `CANTEEN_SOURCE_ROOT` may point to a complete source checkout for sparse native worktrees
- `godot --headless --path godot_native --script res://tests/test_canteen_pickup_timeline.gd` checks all timeline boundaries, sprite frames, bounces, fades, reduced motion, cart flashes and subtitle windows
- `test_canteen_pickup_cinematic.gd` checks original sheet dimensions, actor retention, same furniture ownership, read-only state, frozen simulation, pause/rotation/resume, single cue ownership and the final handoff. Its optional `CANTEEN_PICKUP_CAPTURE` directory enables controlled render screenshots on a graphical renderer; these are staged time samples, not an earned playthrough
- Existing `test_canteen_defense_mobile.gd`, `test_canteen_defense_owners.gd`, `test_canteen_defense_resume.gd` and source defense replay remain regression gates

Actual graphical review and an ordinary controller-entry playthrough must be reported separately from these deterministic tests. The defense model, authoritative session validation, failure/retry, 60-second duration and inactive legacy cart interactions are unchanged.

## Focused verification record (2026-10-09)

- Source-method chronological oracle: passed in both normal and reduced-motion modes
- Pure native timeline: 108 checks, zero failures
- Native cinematic fixture: 122 checks, zero failures; clean headless Godot 4.6.3 run
- Existing real-shell defense owner regression: 22 checks, zero failures. That earlier isolated run reported an unrelated missing dorm-cabinet atlas in its asset cache; the cinematic fixture was clean
- Independent read-only review caught bounce return easing, follow-camera deadzone/initialization and shadow depth. These were corrected and the focused suites rerun

Known visual difference: the immediate-mode native film currently uses ordinary alpha for the shadow auntie, push sprite and glow where Phaser uses SCREEN. The original images are unchanged, but dark portions can appear darker. This is a remaining visual-fidelity limit, not covered by the timing/state tests. Graphical inspection is still required before claiming final visual parity.
