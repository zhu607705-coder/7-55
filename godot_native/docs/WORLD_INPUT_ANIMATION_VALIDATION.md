# World input and gait regression verification

Date: 2026-10-14 UTC. Base: `godot-version` at `f08bdc4ebbee5a5c112e35f93e1cee13ee5636f2`.

## Scope

`world.gd` now clears transient exploration input on window focus loss for desktop and compact layouts. It settles on-foot gait time and facing once, from actual displacement after automatic and manual movement. The original automatic pacing formula, movement speed, collision geometry, and controller-owned first-manual-input branch are unchanged. Kayak displacement is excluded from this on-foot calculation.

No changes to BUCT maps, assets, progression controllers, or background simulation policy are included. Clearing an old click target does not mean that kayaking, guards, or automatic exercise simulation pause when the application loses focus.

## Focused regression

`tests/test_world_input_animation.gd` runs the real World script, original source collision geometry, PlayerMetrics, and Chapter 2 controller. It uses a seeded source checkpoint and synthetic GUI events/window notifications. It does not claim an earned campaign playthrough.

The unchanged baseline World script has seven failing assertions among the same 43 checks: three observations of a retained desktop click target; automatic gait time/frame progression; automatic turning; and a stale gait clock at a blocked manual step. These are several observations of related defects, not seven independent defects. The patched script passes all 43 checks and exits normally with code 0.

During 68 automatic pacing samples, the original position moved while the gait clock stayed zero, the side-idle condition remained true, and horizontal facing never flipped. The patched gait clock advanced from 0.05 to 3.4 seconds, visited all eight frame indices, and followed both horizontal directions. Automatic pacing did not grant manual-control progression or change inventory.

The test also checks a fresh click after focus regain, repeated focus-loss cleanup, compact touch/floor/paddle ownership, stopped exercise, unchanged manual speed, one-time manual progression, and real source-wall contact. It fails closed unless Godot resolves the declared fresh `755-native-check-*/data/SevenFiftyFiveNative` save sandbox and no primary, backup, or temporary save already exists.

## Same-tree related tests

All nine scripts below ran serially against the independent patched checkout and exited 0 without script/parse errors or leak warnings:

| Script | Result |
|---|---|
| `test_world_input_animation.gd` | 43 checks, 0 failures |
| `test_player_metrics.gd` | PASS |
| `test_chapter1_2.gd` | 87 checks, 0 failures |
| `test_chapter4_contact_movement.gd` | 41 checks, 0 failures |
| `test_native_modal_world_input.gd` | 7 checks, 0 failures |
| `test_world_presentation_lifecycle.gd` | 0 failures |
| `test_mobile_floor_route.gd` | 73 checks, 0 failures |
| `test_dorm_native_objects.gd` | 92 checks, 0 failures |
| `test_world_guard.gd` | 71 checks, 0 failures |

The new `test_*.gd` script is discovered by the existing native validator. No new workflow or alternate runtime was added. This focused run is not the full native suite or exported-package verification.

## Input preparation and traceability

The independent checkout reused only necessary asset bytes that matched the formal asset manifest, matching import products, and 57 source JSON files whose Git blob identities matched the formal base. No shared writable import cache or map candidate files were used. No full import was needed.

An initial restricted asset copy missed the dynamically constructed Chapter 4 background directory. That made three guard assertions fail on both original and patched World scripts because the required background was absent. After adding the verified background inputs, both baseline and patched guard tests passed 71/71; the production patch was unchanged. All nine tests were then rerun with the complete inputs listed above.

Engine: `4.6.3.stable.official.7d41c59c4`, Linux headless, Dummy audio.

- Engine binary SHA256: `f64d4ed19fc9df9440321653fcc80df8c6e365ba7b6de0a29e2cfa9fa71bfeb3`
- Original World SHA256: `aac7a5dcc3d85a904b18a9adca10fd4ff996f0438040087b4ff95f07d59132a9`
- Patched World SHA256: `4ef02cb2f2ed8e659d09166635a14310079c8cc0fb61a33bc67f513f051e8557`
- Focused test SHA256: `cec0df737454328f7404ab3bd5fa7f26c00cb0348c33f29e41fb52a3e7768210`

All save, configuration, cache, runtime, and temporary directories were fresh disposable test directories. The existing dorm-object test specifically requires its user-data directory under `/tmp`; that single unmodified test used a fresh `/tmp/755-native-check-*` save directory. No real saves were read or overwritten.

## Graphical verification

A real Main-window check passed all 8 assertions on the Linux cloud desktop at 02:09 UTC. An actual mouse click started movement, then an actual Alt-Tab switched from Godot to Chromium for approximately 7.4 seconds. Returning with Alt-Tab produced no stale-target replay. The probe did not generate input or focus notifications itself.

The player moved from `(480,670)` before losing focus; maximum positional drift during the background interval and after focus regain was exactly 0. The process exited normally with code 0. The test used X11, OpenGL Compatibility, Mesa llvmpipe software rendering. The driver emitted an unsupported V-Sync warning, with no script error.

This verifies OS focus dispatch and Main-shell behavior on that desktop. It does not establish pixel-perfect animation quality, Windows or mobile behavior, dangerous-simulation pause policy, full campaign parity, or final exported-package verification.
