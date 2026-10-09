# Source-faithful defense victory paper

Source audit: 2026-10-09. Implementation base: `cefba738`.

## Source contract

`src/scenes/rpg/CanteenDefenseRuntime.ts` calls `updatePaper` before marking
the final update completed. Further updates return immediately. The final
64×50 running texture, horizontal mirror and angle therefore remain frozen
when `CanteenInteriorScene.animateDefenseVictory` starts. The image origin is
the centered `(32,25)` used by the shared native paper geometry. The starting
scale is `(1.16,1.16)` and opacity is 1.

| Channel | Source victory behavior |
| --- | --- |
| Position | From terminal replay point to `(1380,852)` |
| X scale | `1.16 → 0.28` |
| Y scale | `1.16 → 0.84` |
| Angle | From terminal replay angle to `86°` |
| Ease | `Quad.easeIn`, independently applied to every interpolated channel |
| Texture / flip / opacity | Frozen run frame / terminal mirror / opacity 1 |
| Normal duration / hold | 760 ms / 260 ms |
| Reduced duration / hold | 160 ms / 60 ms |
| Loop | None; no yoyo or repeat |

At 1020 ms normal or 220 ms reduced, the original completion callback runs
`finishDefense`. Runtime destruction resets texture to idle, flip to false,
angle to zero and scale to one. The scene hides the image before starting
three 1200 ms dialogue slots (1080 ms text plus 120 ms gap). The first southeast
door/player departure step begins only after that existing dialogue queue.

## Native change and authority

- The existing validated replay in `chapter3.gd` now supplies `paperFrame`,
  `paperFlip` and `paperAngle` beside `paperStart` and `playerStart`. No submitted
  terminal coordinates or pose fields are used as evidence
- The narrative sampler reproduces independent scale axes and quadratic
  interpolation from the replay angle. It holds the last running pose, then
  returns the restored hidden idle pose at the original handoff boundary
- The actual narrative world view forwards frame, mirror and both scale axes
  to the shared source-generated art
- The shared `PaperArt.draw` API appends `axis_scale = Vector2.ONE` and
  `tint = Color.WHITE` after its existing `parent_transform` argument. Its
  scalar `factor` remains a uniform multiplier. Transform order is local
  nonuniform scale + mirror, rotation, position, then parent camera
- RGB tint is multiplicative and does not modify source/sprite opacity. This
  supports the separately integrated arrival ghost's authored `#bdefff` tint;
  this change does not modify that ghost's timing or view

Existing controller facts, terminal validation, rewards, inventory, model
simulation, saves, shared Main, dialogue timing and exit gates are unchanged.
No assets are generated or copied by this patch.

## Executable evidence

`tests/verify_canteen_victory_source.mjs` executes the original source methods
for update completion ordering, victory, runtime destruction, scene cleanup
and dialogue. It checks eight initial frame/flip/angle cases and 112 samples
including quarter/midpoint, exact tween end, hold end minus 1 ms, hide boundary
and all dialogue onsets. The checked-in JSON fixture is regenerated only with
`--write`; ordinary execution verifies it. The source update's physics helper
is a controlled terminal-pose stub here. Full simulation/trace parity remains
the separate defense oracle's responsibility.

`tests/test_canteen_victory_pose.gd` compares the real native session to those
source samples, checks actual controller trace validation against spoofed
pose/position fields, cancellation/reopen, non-mutating repaint and blur, and
executes the actual narrative world draw call.

`tests/test_canteen_paper_art.gd` retains all five original command-geometry
comparisons and existing callers. Added checks cover independent axes, flips,
rotation, camera composition, centered origin, default tint, source-blue tint
and opacity preservation. Its CanvasItem probe also executes the appended API.

### Checked in this isolated patch

- Offline original-method oracle: passed, eight cases / 112 samples
- Node syntax checks for the new oracle and aggregate runner: passed
- `git diff --check`: passed

### Integrated acceptance, 2026-10-09

- Godot 4.6.3: victory pose 739, shared paper art 181, terminal-contact hold 24,
  chapter narrative 140 and narrative shell 25 checks passed
- Defense, mobile (199), world return (11), session owners (22), scene timeline
  (81) and readability (815) regressions passed on the combined runtime
- Normal 1180×812 and reduced 390×844 real-time source-input replays completed
  all 3,600 original inputs. Both submitted their actual proof to the original
  controller, which accepted the run and supplied frame 3 / flip true / angle 0
- The ordinary narrative displayed every authored line in order and exited to
  campus. The reduced portrait run also exercised a real human pause/resume
- These recordings are labeled automated source input replay, not a manually
  earned campaign win. Manual movement, pause/resume and retry were checked
  separately in both viewports

The Godot test is auto-discovered by `tools/validate_native.mjs`; the source
oracle is explicitly registered there. Final remote CI is reported on the PR.
The source full-room camera is retained through flight, dialogue and departure;
see `CANTEEN_VICTORY_CAMERA.md` for the selective stale-fade correction and its
1,122-check lifecycle regression. New wide/reduced-portrait captures verify this
final framing. Focused acceptance does not claim physical-mobile testing or
audio listening.
