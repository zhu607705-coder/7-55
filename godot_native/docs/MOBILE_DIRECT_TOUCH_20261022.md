# Compact exploration: in-world joystick and direct object taps

## Scope

Originally based on `codex/campus-ui-system-20261021@5907b166d4775e1288aef5d13d56bc99111d5c33` (#156). External repository activity subsequently merged #157/#158/#159 into that UI branch and #156 into `codex/godot-complete-20261019@2d8e3257540c40f492c904f9f1961bc5e63e5f60`. PR160 now targets that formal Godot branch. This task did not perform those merges; its diff contains only the requested controls, regression coverage and verification infrastructure. The old React `main` is not the implementation base.

The ordinary compact world retains the existing inventory, locked HUD/interaction/journal components, source objects, collisions, controller actions and save shape. No mini-game control scheme or kayak paddles are replaced.

## Input contract

| Gesture | Result |
| --- | --- |
| Hold the lower-left translucent thumb pad | Movement only; one pointer owns it |
| Tap and release the same nearby visible object | Existing proximity/mode/item-gated action, once |
| Tap a distant object | No remote action; arriving later never auto-confirms |
| Drag out and back, cancel, duplicate release, emulated mouse event | No object tap |
| Open a modal/phone/inventory, lose focus, rotate/resize | Retire the prior movement/pointer; late release cannot revive it |
| PC direction keys + Space | Existing movement and interaction |

A compact nearby object has no textual interaction plaque until confirmed. The existing selected plaque style is unchanged. Range exit, dismissal and context changes clear the confirmation. Desktop nearby prompts are unchanged.

The joystick is drawn over the world corner. There is no separate confirmation button or full-width reserved joystick row. The existing feedback surface may lift this corner hit area without reserving a new world strip. The bag remains the existing separate bag, not a redesigned bottom joystick panel.

The shell fits compact world/chrome/inventory to native safe-area bounds. On Web, CSS `env(safe-area-inset-*, 0px)` supplies logical insets; unsupported values fall back to zero. Test fixtures inject safe-area values through `_world_safe_insets()` rather than claiming a physical device was connected.

## Verification

New `test_mobile_direct_touch.gd` uses actual Main/World, the original dorm lamp target and controller, and root-routed input. It covers direct/remote/arrival behavior, multi-pointer ownership, interruption, duplicate events, original inventory handoff, desktop keys and compact geometry.

`capture_mobile_direct_touch.gd` captures actual Godot-rendered frames at 390×844, 430×860 (safe insets), 844×390 (safe insets), and 568×320. It includes unconfirmed/confirmed objects, held joystick, and the existing inventory/journal. DEV checkpoints and frozen render samples are explicit; this is not full-campaign manual play or physical iPhone/Android acceptance.

Run the focused tests with the existing isolated runner:

```sh
node godot_native/tools/sync_source.mjs
node godot_native/tools/validate_native.mjs --filter 'Godot asset import and editor parse|test_mobile_direct_touch.gd|test_portrait_exploration.gd|test_mobile_world_feedback.gd|test_mobile_floor_room204_drag.gd|test_inventory_touch_ownership.gd|test_collapsed_inventory_focus.gd'
```

The read-only `Native mobile touch proof` push workflow records the exact branch head SHA, test report, screenshot fixture manifest, actual PNGs and render log. Ordinary Native, Web and Cross-PR workflows validate the PR integration context (GitHub's merge ref against its current base), not the standalone branch head. A successful proof workflow is not a substitute for those suites.

## Engine versions and evidence boundaries

At the user's request, this PR's Native CI, Cross-PR integration and mobile proof workflows use official **Godot 4.7.1**. The official Linux x86_64 ZIP SHA-256 is `c7ff14fd28472c8d4f193043de30278dcf7e5241a1dcf7566b02e27addaa33ba`; the verified binary reports `4.7.1.stable.official.a13da4feb`. Local validation uses a separate binary and import cache. Put its directory on `PATH` as well as setting `GODOT_BIN`, because some existing packaging helpers invoke `godot` directly. The project's `4.6` compatibility feature is not an executable version selector and is not changed.

The existing production Web export remains **Godot 4.7.2 with matching 4.7.2 templates**. Its PCK/manifest contracts and byte-pinned audio compatibility transform require a separate, actual-template migration and browser validation before changing versions. This mobile PR does not silently downgrade that release chain, change Blender, or deploy. The retained `Web CI` suite is not proof of a new 4.7.1 native-Web export. Older independent example/proof workflows are also not claimed as aligned. Cloud Native 4.7.1 coverage and unchanged Web 4.7.2 compatibility must be reported separately, not as full-chain version alignment.

Initial 4.6.3 results are historical diagnostics, not 4.7.1 acceptance. Local graphical capture could not start because the sandbox disallowed display sockets; its escalation also failed before starting Xorg. No screenshot is claimed from that path. CI rendering is the authorized proof route. Preserve failed/partial attempts in the PR report rather than treating later evidence as if they had never failed.
