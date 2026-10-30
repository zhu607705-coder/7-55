# Reverse-order batch 3: 2F and the 25-room review

Base: stacked Draft PR #193, head `7188f19241fe5aa32dbd7700fc17206a4446e1d1`.
This batch continues 4F → 3F → 2F. It preserves the existing building, legal
walking paths, stairs, elevator, and the original electrical workbench.

## Existing work is reused, not erased

- Electrical already had a native gear/belt/tension/feed model and 88 checks.
  This batch extends that work rather than creating another controller.
- Platform already had a browser geometry prototype in `review/gameplay.mjs`.
  The native implementation uses its geometry as a reference; it is not a claim
  that the browser prototype was absent.
- Team was declared an existing isolated native signal-sync sample by the
  original plan. Its source could not be recovered from the current accessible
  workspace, Library, or repository lookup. The user then requested all rooms
  be finished. `puzzles/signal_sync_*` is therefore a **replacement based on the
  authoritative room design**, not recovered original source. The original
  declaration remains valid provenance; no unavailable file was overwritten.

## Room coverage and integration

| Floor | Room | Native model/view |
| --- | --- | --- |
| 2 | koala | koala |
| 2 | machinery | machinery |
| 2 | electrical | existing workbench, extended |
| 2 | seminar | solid_projection; review area `seminar_2f` |
| 2 | platform | platform |
| 2 | robotics | robotics |
| 2 | team | signal_sync replacement |
| 2 | formula | formula |

The previous batches provide seven 4F rooms and ten 3F rooms. There are now 24
registry entries plus the original electrical workbench entry. The 2F and 3F
seminar rooms have distinct review keys; no room shadows another dictionary key.
The isolated entry remains `samples/future_learning_center/standalone.gd`;
`FLC_REVIEW_AREA` or Web `?area=` selects the furniture approach, not a teleport
into the puzzle. All new furniture anchors existed before this patch.

## Acceptance requirements

- Actual object interaction changes geometry, wiring, mechanism or experiment.
- A visible apparatus opens only at a legal nearby floor position. Closing and
  reopening preserves its model and returns to the same world position.
- Failure can be retried. Touch cancellation and another finger must not commit
  or steal an in-progress operation. Closing stops simulation work.
- The 2F platform stores separate successful photographs for the two lighting
  conditions; moving its board between photographs is permitted here.
- Team requires two different source changes to reach both receivers; identical
  static images do not pass. Moving screens does not invalidate correct wiring.
- Robotics must load, unload and return continuously in one run and configuration.
- Electrical includes an opposite-direction target using the same drivetrain.
- Formula uses an explicit teaching simulation, not calibrated vehicle physics.
  The supplied panel masses/areas can make the wide panel weakly dominate a
  compact panel at fixed angle/ratio. No secret penalty is added to fabricate
  a small-panel victory. The physical model is verified separately for power,
  energy balance and timestep convergence.

## Validation status

The final integrated snapshot passed all 25 room suites, 230 furniture-entry,
close/reopen and floor-transit assertions, 16 2F approach checks, 15 3F placement
checks, and the unchanged 1,740 building checks. The native validation protocol,
Web acceptance workflow and table-builder contracts passed 195 Node tests.
The final rerun includes the touch-cancellation correction and the last
formula/machinery view tests. New 2F suites: koala 27, machinery 26, electrical
133, solid_projection 27, platform 17, robotics 27, signal_sync 23, formula 202.
These are assertions, not separate gameplay scenarios. Formula includes a
36-configuration numerical enumeration; electrical retains the original checks.

A cross-room input review found that six older views checked cancellation only
inside the released-touch branch. They now also release an owned canceled
press, reject an orphan canceled press, and allow the next finger to interact.
The three views inheriting collab receive the same correction. Tests cover
these inheritance paths explicitly, rather than counting them as new rooms.

Actual GUI validation has already completed both platform lighting photographs
and two different signal updates under one wiring revision. A 780×438 standalone
window also completed the signal task through real floor/table entry and returned
to exactly the same player position `(668.9423, 3653.036)`. Mouse-based scaled
window checks do not substitute for physical-phone testing.

The standalone runner copies only actual resource files; dynamic load directory
prefixes are skipped, while every puzzle script is still copied explicitly.
This avoids interpreting a dynamic script-path prefix as a file during isolated
resource collection. Source compilation or headless checks alone are not visual
evidence.

This is the isolated FLC review, not production chapter/save integration or
real-phone acceptance. Earlier CI evidence, including the unrelated canteen
200 ms timing assertion, stays attached to its own head and is not rewritten.

## Final graphical evidence

All 25 frozen station views rendered with Godot 4.7.1/OpenGL Mesa llvmpipe;
every PNG returned success and no game script error occurred. The driver-only
V-Sync warning is retained in `review_2f/render_final25.txt`.
All eight 2F rooms were also completed with real desktop mouse input. In
particular, robotics failed on the default return route before its physical
switch was changed; machinery hit its clamp after cutting and then released
the same sample after the clamp moved; formula actually ran all 30 seconds and
finished 62.52 against 52.35. No acceptance helper assigned success to a model.

`review_2f/GUI_ACCEPTANCE.md` records the exact paths and the temporary harness
failure when it initially loaded the legacy electrical view from the wrong
folder. That harness was corrected; the failed load is not counted as a game
pass. The original electrical view and its controller remained in place.
The only post-aggregate code edit moved platform lamp labels below the lamps
so the album did not hide them. Its 17 relevant checks passed again, and the
final 25-image render uses that corrected source.
