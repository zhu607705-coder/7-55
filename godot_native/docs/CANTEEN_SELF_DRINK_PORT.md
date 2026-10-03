# Canteen failed-drink self-use repair

A wrong native mixer recipe grants `badDrink`. Previously, dragging it onto the visible player fell through the generic world-object picker and was rejected. The native adapter now restores the original self-use action and its eligibility guard.

## Source contract

- `src/scenes/rpg/CanteenInteriorScene.ts:2418`: `badDrink` has a dedicated branch before ordinary item/target resolution. Its source-space acceptance circle is centered on `(player.x, player.y - 24)` with radius 58 inclusive. It does not require light mode. Miss feedback is the original “把难喝饮料拖到人物自己身上才能喝掉。”
- `src/data/itemCatalog.ts:135`: `badDrink` consumes against `rpg-player`.
- `src/modules/ChapterThreeCanteenController.ts:336`: self-use requires an owned drink, active canteen hunt, and phase `tray_search`, `drink_mix`, `menu_order`, `pickup_search`, or `chase_ready`. It consumes only the failed drink and emits the existing consumption event.
- `CanteenInteriorScene.ts:2074,3914` queues the existing two authored lines. Starts are 0 and 2500 ms; each caption displays for 2380 ms; normal completion is at 5000 ms. No phase, recipe, promotion, queue, or wallet change accompanies self-use.

## Runtime changes

Only two runtime files change:

1. `scripts/world.gd`: route only `badDrink` drops in `canteen_interior` through that exact source circle, after the existing capture, hidden-actor, modal, narrative, and blocking-effect guards. Mobile HUD and controls retain their input ownership. This branch does not add a generic target, expand the ordinary picker, reveal an answer, select a recipe, or consume anything directly.
2. `scripts/chapters/chapter3.gd`: restore the source controller's missing `side_active` guard on the existing `c3_bad_drink` action. That action remains the sole consumption and narrative authority.

The existing `tell`/narrative session and its timing are untouched. The source's special self-use circle intentionally differs from sprite-alpha object picking and preserves its original item-specific priority.

## Initial isolated verification (before integration)

`export_canteen_self_drink_source.mjs` executes the original TypeScript scene/controller/dialogue methods. Its checked fixture covers 12 boundary points, 80 phase/activity/mode/ownership combinations, repeat requests, exact authored text, and timing.

`test_canteen_self_drink.gd` uses the real Main scene, inventory buttons, root mouse/touch events, and SubViewport coordinate conversion. It makes the wrong mixture through the native mixer controls, then tests valid self-drops at 1440×900, 430×860, 390×844, 844×390, and 960×540 in both modes. It also covers off-body misses, the exact 58px boundary, wrong items, modal cancellation, Escape/touch cancellation, mobile control ownership, outside-scene rejection, repeat/stale drops, and natural five-second narrative completion. Controller-only phase matrices and direct geometry fixtures are explicitly separate from routed input checks.

The portable fixture and the unchanged ordinary earned pre-mix save each pass 427 checks. The same initial regression against the frozen unpatched runtime fails 71 checks, confirming that it detects the missing self-drop route and the missing source eligibility guard. A separate replay loaded the exact CUA-earned failed-mixture save normally and passed 417 checks. These isolated checks totaled 5,158 assertions with the related suites.

Existing mixer, portrait input, object picking, chapter-three narrative, chapter-three controller, and device-control suites pass 3,887 checks in total. The device suite enforces a `/tmp` profile; its first invocation rejected the workspace-isolated profile before running tests and passed after rerunning under `/tmp`.

Those initial automated UI tests were headless and did not constitute manual acceptance. During that isolated stage, shared assets, data and import cache were linked read-only, and all 1,058 files in the then-frozen shared runtime stayed unchanged. The subsequent integrated and actual-input results are recorded below.

## Reproduction

Run from the native project with isolated `XDG_DATA_HOME`, `XDG_CONFIG_HOME`, and `XDG_CACHE_HOME`:

```
node tests/export_canteen_self_drink_source.mjs --source-root /path/to/source/repo --check
godot --headless --audio-driver Dummy --path . --script res://tests/test_canteen_self_drink.gd
```

To replay a normal pre-mix save, copy it unchanged to the isolated `XDG_DATA_HOME/SevenFiftyFiveNative/save.json` and set `EARNED_SELF_DRINK=1`. For a normal save that already owns the CUA-earned failed drink, set `EARNED_SELF_DRINK_MIXED=1`. Saves remain byte-identical because the test enables the existing non-saving test mode after the normal State load. Later phase/layout/mode cases use explicit in-memory fixture copies, not campaign evidence.

The repair is applied on top of three-UX release `cacb5a7255e215074d2e62dc2b0a556e3468b691`. The integrated runtime and fresh exports passed the final checks recorded below and in `CANTEEN_SELF_DRINK_VALIDATION.json`.

## Actual input retest

A normal restart of the unchanged failed-drink save at 430 × 860 now retains the item after an off-body miss and consumes it after the same physical player-body drop that failed before the repair. The first authored line was captured; the second is present in the passive visible-text trace, followed by normal completion. Inventory changes from four to three while canteen facts and wallet remain unchanged. This was an earned side-save replay, separate from the continuous main route. No subjective listening or physical-phone claim is made.

The final revision passed a clean 179-stage aggregate, both native export builds, 795 packed campaign checks, and 25/21 native-only startup/reload checks. A standalone Linux desktop replay also consumed the retained failed drink through physical pointer input, showed the authored dialogue, preserved canteen facts and wallet, and closed normally without script or ObjectDB errors. The known unsupported V-Sync driver warning remains. Windows was built but not executed.
