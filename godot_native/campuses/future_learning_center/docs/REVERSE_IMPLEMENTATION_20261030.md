# Reverse-order implementation: 4F first

Baseline checked: `ff5e1866edeb637462b8016cbfaf62f4043081d4` (main, 2026-10-30).
Latest object-first guidance takes precedence over the older “await Argon” note.
Order: **4F → 3F → 2F**, reusing completed work rather than rebuilding it.

## What already existed

Main already had the three furnished floor assemblies, spatial navigation,
paired stairs/elevator, wall-storage occlusion, and the 2F electrical workbench.
These remain in place. The new patch adds no substitute building layout.

The revised plan describes 25 rooms. The seven 4F apparatus controllers were
absent from checked main and the fetched FLC branch (merged PR #190). This patch
implements those seven only. Absence from main is not proof that a prototype
never existed elsewhere. In particular, the previously delivered signal-sync
sample must be reconciled with newer/unmerged work before starting 2F.

## Seven native stations

| Existing room | Physical interaction | Actual completion evidence |
| --- | --- | --- |
| flex_c | Carry one patch board, plug cables, rotate adapter, change cable routing/length | Two distinct input patterns reach functional ports at both stations; actual path length and pillar collision |
| collab_b | Move baffles, switch light, rotate fixture, operate camera/feed lever | Two-light, camera and feed receipts share one geometry version |
| focus_a | Plug devices into branches, change work mode, trial devices | Idle and work loads fit both branches; auxiliary-load extension |
| storage | Move boxes, swing cabinet door, use temporary tray | Geometric extraction/return, swept collisions and support |
| seminar_3 | Move/remove bracket on the same optics rig | Combined shading and full-width feed clearance, not separately pasted successes |
| seminar_2 | Move carts and switch siding | Occupied rail cells prevent passing through another cart; long-cart extension |
| seminar_1 | Move magnetic tiles and pull test lever | Discriminating experiment followed by a new transfer pair |

Station entry uses the existing furniture: point at it, walk along a valid path,
then operate nearby. Close returns to the same position. Reopening retains the
same model. Floor changes cancel active interaction. Touch movement uses one
captured analog-stick finger; other fingers are free for object interactions.
No default keyboard instruction wall was added. Notebooks are opened on demand.

## Scope and verification

This is an **isolated FLC native review**, not a new production story chapter.
Production save/progression authority remains unchanged. The station visuals
are native 2D/2.5D apparatus, not final 3D artwork.

Reproducible focused checks (Godot 4.7.1):

```sh
GODOT_BIN=/path/to/Godot_v4.7.1-stable_linux.x86_64 \
  node godot_native/campuses/future_learning_center/tests/run_puzzles.mjs
```

The runner imports a disposable no-autoload project once, then runs three
independent suites at a time. It also runs the existing floor regression suite.
CI registers each suite separately in the existing one-slot scheduler, without
adding another worker pool or changing historical validation stages.

Review entry: the existing standalone export supports `?area=flex_c`, `collab_b`,
`focus_a`, `storage`, `seminar_3`, `seminar_2`, `seminar_1`; native standalone uses
`FLC_REVIEW_AREA` with the same values. Click the visible apparatus to enter.
The previous default 2F workbench and `area=stairs` remain available.

Real-render snapshots in `review_4f/` were captured with Godot 4.7.1, OpenGL 4.5
Mesa llvmpipe, from the actual Control draw code. They are not AI mockups.
`tests/capture_puzzles.gd` reproduces these with a graphical renderer and
`FLC_CAPTURE_DIR`; a headless dummy renderer is not a visual acceptance test.

Remaining acceptance: real phone multitouch, production narrative/save integration,
and final art refinement. 3F's ten rooms and 2F's eight rooms are **not claimed
complete** by this patch; the next pass starts at 3F xlab_box and works backward.

Actual mouse acceptance also exercised collab and assembly in the native GUI:
baffles were dragged, both light exposures taken, feed operated, and each
completed instance closed/reopened without losing its configuration. Assembly
first stopped against the central bracket; moving the bracket invalidated the
current receipts, then re-photographing and feeding completed the trial.
`gui_08_collab.png`, `gui_12_assembly.png`, `gui_18_assembly.png` show those states.

Local result: seven apparatus suites passed (36/31/25/29/14/22/20 checks),
71 integration checks passed, and the unchanged floor suite passed 1,740 checks.
The registration/workflow source contracts passed 25 tests. These counts are
assertions, not a claim of 1,000 independent gameplay scenarios.
