disposition: fix

Missing formal context: PRODUCT.md and DESIGN.md. The scoped existing-game extension is reviewable against the supplied user instruction, surface brief and project art bible; no approved comp, new-world concept contract or quality-bar card applies.

## persistence

Pass for this scoped extension. This is a fresh delegated review of the replacement, using the supplied user quotes and `.impeccable/flc-object-interaction-brief.md`; the rejected action-strip interface and its earlier verdict are not authorities. The standing rule is recorded in AGENTS.md. Impeccable context permits scoped work against the incumbent implementation despite the documentation gaps above.

All eight required captures exist, were opened, match their named states, and show actual scene content: desktop `solar_initial`, `robot_blocked`, `signal_complete`, `mechanical_complete` at 1280×720; mobile `room_joystick`, `solar_notebook`, `robot_loop_complete`, `signal_complete` at 844×390. The mobile content occupies a complete 16:9 viewport at uniform scale 390/540 = 0.7222; the side fields are intentional letterboxing. Also opened mobile `mechanical_complete` to inspect its small labels.

Reviewed worktree base: `4c5fa5f147ce3cdd492895a97f9cca69fd415efd`, with uncommitted implementation. The eight captures postdate the reviewed source files. Source SHA-256 prefixes: physical_bench `eb1212d523593360`; motion_lab_view `da8f5e49d2bec3b1`; signal_sync_view `41d308d2e0351c8b`; workbench_view `12e5adb311152e5a`; touch_stick `d9c63cb88e8a13b0`; floor_view `ab56695ba4061cf0`.

The supplied object-input reports contain 43 desktop-pointer and 49 simulated-touch checks, zero failures and zero keyboard events. The packet reports motion 63, signal 15 and floor 1740 checks. This pass reviewed the captures and source, and did not replay those tests. No HTML/CSS detector applies to these native CanvasItem/Control views. Browser, physical-phone, novice-difficulty and production save/chapter acceptance remain outside this verdict.

## fidelity

| Element / promise | State | Evidence |
| --- | --- | --- |
| Core operations occur on visible objects | match | Parts are dragged onto vehicles/axles, modules are moved or rotated, cables meet actual sockets, pattern cards enter the editor, and the lever controls trials. The only ordinary bench Button is exit navigation. |
| Physical lever and rewind crank | match | Both controls have recognizable grips, bounded movement and a physical commit gesture. Mere taps produce a short recovery instruction. The three lever positions align with run/stop/return labels. |
| Solar lamp manipulation | contradicted | `motion_lab_view.gd:117–118` updates only `drag_value`, while `lamp_grip()` and the lamp/light drawing at lines 91 and 165–184 continue reading committed `solar.sky`. The lamp stays still throughout a drag and jumps after release; the manipulated object's motion does not show the pending operation. |
| Movable receiver monitors | contradicted | `signal_sync_view.gd:62–64,81–82,117–118` records a screen gesture and swaps fixed slots after release; there is no screen movement preview. A receiver dragged toward another location remains stationary until the slot swap commits. |
| Cancellation, ownership and recovery | match | One pointer owns each apparatus gesture. Cancelled/out-of-viewport releases avoid model commits; focus loss clears ownership and stops or pauses trials; opening a bench cancels locomotion. Robot changes invalidate traversal proof and restore cargo safely. The input reports include cancellation, second-finger, undo and exit checks. |
| Joystick with tap-to-approach | match | Mobile `room_joystick` shows one analog stick. Source preserves analog magnitude, owns the initiating pointer, releases to neutral, clears on focus/visibility changes, and feeds the same legal movement path. |
| Optional notebook and unobstructed default | match | Clues are voluntarily opened and paged; the notebook can be moved. The default shows the apparatus without an action row, hotkeys or persistent tutorial. Required notebook capture has complete lines within the paper. |
| TYPE | contradicted | The native project font is retained, but effective mobile sizes fall below the art bible's reading targets: 20 logical px becomes 14.44 screen px for notebook/feedback body, 18 becomes 13 for monitor and lever labels, and 14 becomes 10.11 for mechanical component labels. This is visible in the required mobile captures and supplemental mechanical capture. |
| MATERIAL | match | The table, lever, book, lamp, panels, robots and monitor bodies visibly use their raster assets; moving gears, cables and track grooves remain legible schematic geometry. No decorative imitation material or replacement visual world is introduced. Generation prompts and original-source hashes are recorded in `object_control_generation.json`; no strict 32-color acceptance is claimed. |
| GROUND | match | The gray/blue metal surface and retained room margins follow the existing world and brief. Small cream labels on that surface still fail the text-contrast floor: adjacent sampled backgrounds give approximately 3.1–3.7:1 against #e8e0c8, below 4.5:1 at their mobile body sizes. |
| Model/controller and spatial authority | adaptation | The close-up enlarges the active apparatus while retaining room context, as explicitly permitted by the surface brief. Model-owned simulation/completion and floor-space movement remain separate from presentation; no production progression writer is added. |

## ceiling

The remaining native devices are immediate drag previews and scale-aware text/contrast. The pixel world, apparatus silhouettes and uniform viewport do not require replacement. Adding a new visual world, more permanent instructions, decorative motion or a panel of controls would not address these findings.

## material_fixes

1. Restore the lamp's continuous manipulation feedback: render the lamp/head and its light preview from the owned pending gesture in [motion_lab_view.gd](/Users/zhu/.codex/worktrees/north-clean-object-layers-20261027/755/godot_native/campuses/future_learning_center/scripts/motion_lab_view.gd:117); commit the discrete light state only on a valid release and restore the original on cancel. Supply one mid-drag capture showing the grip and object agree.
2. Show receiver movement before the slot swap: use the owned pointer to preview the dragged monitor, with its socket/cable anchored to that preview, in [signal_sync_view.gd](/Users/zhu/.codex/worktrees/north-clean-object-layers-20261027/755/godot_native/campuses/future_learning_center/scripts/signal_sync_view.gd:62); valid release may snap to the destination slot while cancellation restores position and identity. Supply one mid-drag capture; retain the existing identity/evidence checks.
3. Make the actual landscape-mobile text meet the project's reading floor in [physical_bench.gd](/Users/zhu/.codex/worktrees/north-clean-object-layers-20261027/755/godot_native/campuses/future_learning_center/scripts/physical_bench.gd:137) and the three apparatus label renderers: target at least 16 effective screen px for notebook/feedback body and 14 for secondary labels, with ≥4.5:1 contrast for small text. At the captured scale this means at least 23 and 20 logical px respectively, or an equivalent scale-aware treatment. Give low-contrast apparatus labels a quiet local physical backing/ink treatment, then recapture the notebook, signal and mechanical mobile states to check wrapping and clearance.

## keep

Keep object-owned gestures, the visible lever/analog joystick, single-pointer cancellation, model-owned completion, optional movable notebook, quiet default playfield, source-aligned floor movement and uniform 16:9 fit.
