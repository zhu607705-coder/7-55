# Inventory release coordinates

## Scope and provenance

This patch is based on `godot-version` commit `b52c19aee700c0ea0217634ce66d584b8ea7c33c`. It extracts the inventory-release correction from [PR #117](https://github.com/zhu607705-coder/7-55/pull/117), head `839108dd780301d4f0fcb8d1885e09fe1edcf4e8`, without that PR's new theater animations or clue objects. The original Chapter 3 poster and controller provide the integration fixture. The existing PR #139 focus and gait rules are unchanged.

## Cause and bounded correction

A native release event at `(158,371)` can differ from the polled pointer position `(344,495)`. [Godot 4.6.3 `Viewport::_perform_drop`](https://github.com/godotengine/godot/blob/4.6.3-stable/scene/main/viewport.cpp#L2228-L2234) obtains the target's local mouse position when completing a GUI drag. Root-dispatched or touch-emulated mouse events need not update the OS pointer to that same position.

The active source inventory item now records its release event on the existing native drag payload. The world bridge resolves that root-viewport point through the existing container transform **before** its surface-boundary check. The world picker also resolves the same snapshot when Godot dispatches directly to the world Control. Both routes derive a fresh world-local point from the same root snapshot; they do not compound transforms.

- Snapshot capture requires the active native drag and matching source item
- Snapshot use requires its source viewport, current process frame and finite coordinates
- A new drag has a new payload. The snapshot is transient, never saved
- A release outside the world is rejected even if the last motion hovered a valid target
- A valid release inside the world is considered even if the fallback coordinate is outside
- Original modal, presentation, item, target, proximity and controller gates remain authoritative
- Programmatic calls without a valid snapshot retain their supplied local coordinates
- Native GUI dispatch still chooses the receiving Control and performs the single drop. This patch does not replace Godot's global drag-target router or snap to a nearby object

## Fresh verification, 2026-10-15

These tests were run on this extracted branch with Godot 4.6.3 and isolated temporary profiles. Results from the broader PR #117 are not substituted for this branch's results.

- `test_inventory_release_coordinates.gd`: 324 checks. Three viewport shapes, three container scales and three map zooms cover exact mapping, source/item/frame isolation, both stale-fallback boundary directions, unchanged world acceptance gates and exact-once bridge dispatch
- `test_inventory_release_main.gd`: 152 checks. Real Main and root mouse/touch events at 390×844, 430×860, 844×390 and 1440×900 cover wrong item, cancel, release outside without a preceding motion, valid original poster drop, duplicate release and pointer-owner cleanup. Negative and positive subcases have independent fixtures
- A graphical baseline comparison uses the same fixture with only the four production files reverted to `b52c19a`. Keeping the OS pointer at `(344,495)` reproduces compact-screen failure and stale-hover false acceptance on the baseline. The corrected branch passes all eight size/input combinations
- A separate actual X11 pointer drag in the native 390×844 window moves the tissue from `(209,738)` to `(158,371)`. The original controller consumes the tissue and grants the original ticket. Before/after screenshots and runtime logs were inspected
- The fixture refuses a profile outside `/tmp/` before changing state. A sentinel-save check confirmed no writes to that refused profile

Related regression scripts cover viewport transforms, touch ownership, gesture lifecycle, native double-click, inventory precision, compact inventory, world combinations, bicycle and check-in world drops, PR #139 world input/animation, exact-arrival and Room 204 touch input, object picking, phone navigation, Chapter 3 and the controller campaign. The new tests are discovered by the existing native test runner. The PR records exact final local results and remote CI status.

The graphical tests are native Linux runtime fixtures. Touch uses Godot input events, not physical phone hardware. The chapter fixture is explicit setup, not an earned campaign traversal. No Windows runtime, mobile export, packaged build or complete manual campaign acceptance is claimed.

## Reproduce

Create a fresh `/tmp/755-native-check-*` directory. Set `XDG_DATA_HOME`, `XDG_CONFIG_HOME`, `XDG_CACHE_HOME` and `XDG_STATE_HOME` to separate children of it, and `GODOT_TEST_USER_DATA_DIR` to `$XDG_DATA_HOME/SevenFiftyFiveNative`.

```sh
godot --headless --path godot_native --script res://tests/test_inventory_release_coordinates.gd -- --fresh
godot --headless --path godot_native --script res://tests/test_inventory_release_main.gd -- --fresh
```

For a graphical window, omit `--headless`. To drive the source fixture with an OS pointer, append `--manual` after `--fresh`. Use F6 to reset and F11 to capture. Optional `INVENTORY_RELEASE_CAPTURE_DIR` must be under `/tmp/`. The manual fixture prints source and target screen points, actual mouse-button events, original controller feedback and the resulting item state.

## Publication validation record

All 18 focused native regressions, a full editor import/parse, fresh native startup and the Web critical suite (24/24) passed. The complete local Web release suite passed 32/35 validators, including the production build. Its unchanged offline single-file build was killed with exit 137; artifact verification and browser smoke then failed because `demo/` was absent. This is not a complete local release pass. Exact published-head Native and Web CI remain required. No repeated memory-heavy local build was attempted.

The independent review found no blocking issue in the four production files or final regression results. This is a separate work-branch delivery based on `b52c19a`, with no merge or Pages change. The implementation and verification record is kept in this bounded document rather than duplicating the repository's large historical progress log.
