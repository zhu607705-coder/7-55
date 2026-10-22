# Compact exploration: in-world joystick and direct object taps

## Scope

Based on `codex/campus-ui-system-20261021@5907b166d4775e1288aef5d13d56bc99111d5c33` (#156). This is a separate branch from #157/#158's dorm experiments and #159's B3 motion patch. The old React `main` is not the implementation base.

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

The read-only `Native mobile touch proof` workflow records the source SHA, test report, screenshot fixture manifest, actual PNGs and render log. Ordinary Native, Web and Cross-PR workflows validate the exact PR head separately. A successful proof workflow is not a substitute for those suites.

Cloud headless Godot 4.6.3 is available. Local graphical capture could not start because the sandbox disallowed display sockets; its escalation also failed before starting Xorg. No screenshot is claimed from that path. CI rendering is the authorized proof route. Preserve failed/partial attempts in the PR report rather than treating later evidence as if they had never failed.
