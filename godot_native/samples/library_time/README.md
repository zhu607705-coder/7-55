# 书脊的两个时刻 · independent library sample

Godot **4.7.1**, GL Compatibility. Open this directory's `project.godot` (not the campaign project).

The player moves two read-only historical windows with two hands. A return tote hides the lower spine in the morning; a hanging folio hides the upper spine later. The brass shelf corner and ribbon clip stay fixed. The player combines the two visible markings, then pulls that book from today's shelf. Today's order differs: copying an old position chooses a recoverable decoy.

- Drag either historical window by its surface/frame. Each finger keeps its own window. A mouse can park them sequentially.
- Pull a current book downward. Wrong books slide back; books are never destroyed. Both viewed fragments and an actual correct pull are required. Waiting, hidden clues, history taps and completion animation cannot solve the puzzle.
- `···` / Escape opens a safety menu. Cancel, focus loss, app pause, leaving the surface or resizing releases every pointer. Continue is explicit. Reset is local.
- Default play has no answer panel, password, always-on instructions or narrative proof.

## Boundaries

This is an original **local shelf vignette**, not a reconstruction of a real library plan. It is not wired into the campaign, inventory, chapter gates, saves or map collision. The three SubViewports own different World3Ds, cameras, materials, geometry and lights. Historical worlds receive no model or current-book state.

The prototype's six covers deliberately repeat each half-symbol. A circle alone leaves three candidates; two bars alone leaves two. The complete circle/two-bar pair is unique. The selected historical book sits under the ribbon; the present book at that old position is a plausible wrong choice.

## Reuse, without a framework

`../observation_kit/README.md` documents four small helpers, their provenance and five-step integration. Copies in `kit/` keep this project portable. `library_model.gd`, shelf geometry, clue/occluder rules, and completion remain level-specific. No earlier prototype was refactored.

```sh
node godot_native/samples/observation_kit/tools/sync_kit.mjs --check
GODOT_BIN=/path/to/Godot_v4.7.1-stable_linux.x86_64 node godot_native/samples/library_time/tools/run.mjs
node godot_native/samples/library_time/tests/test_isolation.mjs
```

Headless checks prove imports, model/input/geometry and save boundaries, **not rendering or physical-phone acceptance**. `.github/workflows/library-time-demo.yml` records ordinary InputEventScreenTouch/Drag input with GitHub-hosted Xvfb/Mesa and the pinned official engine. It retains source SHA, MP4, entry/comparison/result PNGs, viewport images and negative-control pixel logs. Inspect those before extending this pattern to another level.

No automatic batch generation, mainline placement, merge or deployment is included.
