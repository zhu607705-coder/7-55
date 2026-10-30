# Future Learning Center — physical object interaction extension

Documentation pass: 2026-10-30. Surface mode: **Experience**. This records the current ordinary native-game extension and its evidence. The incumbent art, typography, spatial data and model authority remain the sources of truth.

## Overview

The four workbenches make the apparatus itself the interaction surface. Players fit and turn parts, move the lamp, reconnect plugs, place pattern cards, operate a physical lever and turn a rewind crank. The movable notebook holds voluntary records and clues. Default play keeps the apparatus visible, with exit as the sole ordinary screen-space Button.

The standing object-interaction rule is recorded in [AGENTS.md](/Users/zhu/.codex/worktrees/north-clean-object-layers-20261027/755/AGENTS.md:36). The local scope is defined by the [surface brief](/Users/zhu/.codex/worktrees/north-clean-object-layers-20261027/755/.impeccable/flc-object-interaction-brief.md) and [implementation record](/Users/zhu/.codex/worktrees/north-clean-object-layers-20261027/755/godot_native/campuses/future_learning_center/review/OBJECT_INTERACTION_20261029.md). Visual authority remains [ART_BIBLE.md](/Users/zhu/.codex/worktrees/north-clean-object-layers-20261027/755/godot_native/docs/art/ART_BIBLE.md) and [native_typography.gd](/Users/zhu/.codex/worktrees/north-clean-object-layers-20261027/755/godot_native/scripts/ui/native_typography.gd). Missing PRODUCT.md/DESIGN.md does not make this an unestablished visual world. This pass adds only this scoped record; it creates no global design-system files and repairs no unrelated drift.

## Colors

The apparatus retains the project's blue-gray metal, warm cream ink and restrained brass accents. The following are observed code values and roles for this surface, not a second token authority.

| Observed color | Local role |
| --- | --- |
| Dark metal (`#202b35`) | Axles, screens, grooves, outlines and notebook ink |
| Slate metal (`#344452`) | Small engraved-label backing and structural surfaces |
| Steel (`#526b7a`, `#7993a1`) | Cable outlines, frames, socket rings and machinery |
| Cream (`#e8e0c8`) | Readable apparatus labels, measurements and feedback |
| Muted brass (`#c79b62`) | Grips, movable pieces and physical state marks |
| Blue (`#385b79`, `#83a7b6`) | Panels, parts and visible routes |

Small light apparatus labels now use opaque slate plates. Cream ink against that backing computes to **7.60:1** using sRGB relative luminance. These plates are read-only labels attached to objects. Generated raster materials and some local drawing colors have not received strict 32-color acceptance.

## Typography

The workbenches load `native_typography.gd.body_font()`, preserving **755 Morning Note Regular** and its explicit bundled symbol fallback. The shared font implementation disables system fallback and font antialiasing; the apparatus uses nearest sampling. No alternate display family is introduced.

At the reviewed mobile capture size, the complete 960×540 scene fits within 844×390 at a uniform scale of **390/540 = 0.7222**. Notebook and feedback body text use **23 logical px**, yielding **16.61 screen px**; secondary apparatus labels use **20 logical px**, yielding **14.44 screen px**. These measurements describe this captured scale. The notebook is uniformly enlarged to **480 logical px** wide, and its six-character body lines remain on the paper in the recapture. Apparatus label backing comes from [physical_bench.gd:137](/Users/zhu/.codex/worktrees/north-clean-object-layers-20261027/755/godot_native/campuses/future_learning_center/scripts/physical_bench.gd:137).

## Layout

The logical playfield stays **960×540**, with a complete 16:9 fit at both reviewed sizes: desktop 1280×720 and mobile 844×390. Mobile side fields are letterboxing. The close-up enlarges the active worktable while retaining room context at its margins.

The table's measured source crop uses one uniform scale. The shared `prop()` drawing helper derives height from the source aspect ratio. The shell reserves the upper-right corner for exit navigation, the right apparatus area for the physical lever and small notebook, and a short lower safe zone for five-second goals or manipulation feedback. The notebook can be opened, paged, moved and put away; its expanded reading surface appears only on request.

Room entry remains a tap on the physical workbench followed by a legal approach. The analog joystick supplies displacement and magnitude to the existing floor movement path. Opening a bench or changing floor clears locomotion. The floor linkage is visible in [floor_view.gd:231](/Users/zhu/.codex/worktrees/north-clean-object-layers-20261027/755/godot_native/campuses/future_learning_center/scripts/floor_view.gd:231); this record does not expand the scope to a whole-building acceptance.

## Elevation & Depth

Room margins, the tabletop, independent apparatus and temporary feedback form the visible layers. Metal faces and fine outlines establish physical depth; the machinery, tracks and cables are independently drawn stateful objects. During receiver movement, the dragged monitor is drawn after its peer, while its socket and cable endpoint use the same pending displacement. The captured overlapping receiver therefore remains legible throughout the gesture.

The table, lever pedestal, handle, notebook, lamp and spare panels come from generated transparent assets. [object_control_frames.json](/Users/zhu/.codex/worktrees/north-clean-object-layers-20261027/755/godot_native/campuses/future_learning_center/assets/puzzles/object_control_frames.json) records measured source rectangles. [object_control_generation.json](/Users/zhu/.codex/worktrees/north-clean-object-layers-20261027/755/godot_native/campuses/future_learning_center/assets/puzzles/object_control_generation.json) retains prompts, tool attribution, original paths, dimensions and hashes, with `productionAcceptance: false`. This pass verified both archived-original hashes and both runtime-file hashes. Original and runtime PNG IHDR/IDAT chunks match, supporting the recorded metadata-only derivation without a pixel rewrite.

## Shapes

Shape communicates function: a graspable lever head and slot, a rotary crank, a dial hand, sockets and plugs, distinct track grooves, toothed gears, loose belt loops and a folded notebook page. Hit regions stay with those visible objects. Small label plates have no independent action. Measured source crops and uniform scaling govern the table and generated props; this extension does not establish a new global radius or container system.

## Components

| Implementation | Observed contract |
| --- | --- |
| [physical_bench.gd:71](/Users/zhu/.codex/worktrees/north-clean-object-layers-20261027/755/godot_native/campuses/future_learning_center/scripts/physical_bench.gd:71) | A single mouse pointer or touch owns a gesture. Valid release dispatches the operation; cancelled or outside-playfield release does not commit the object preview. Focus loss clears ownership and delegates trial cleanup. Lever travel, crank rotation, notebook and exit share this shell. |
| [motion_lab_view.gd:100](/Users/zhu/.codex/worktrees/north-clean-object-layers-20261027/755/godot_native/campuses/future_learning_center/scripts/motion_lab_view.gd:100) | Solar: drag the panel hinge, fit panels/gears and move the lamp; lever run/neutral/return uses the same solar model. Robot: fit, swap or quarter-turn modules, move the return guide, then run the actual delivery and empty return. The notebook exposes evidence on request. |
| [signal_sync_view.gd:25](/Users/zhu/.codex/worktrees/north-clean-object-layers-20261027/755/godot_native/campuses/future_learning_center/scripts/signal_sync_view.gd:25) | Plug-to-socket dragging changes cables; dragging an input plug into empty space disconnects it. Pattern cards enter the editor, and two distinct edits establish live synchronization. Receiver movement previews its body, socket and cable together; valid drop swaps slots while logical identity and evidence remain attached to the receiver. |
| [workbench_view.gd:41](/Users/zhu/.codex/worktrees/north-clean-object-layers-20261027/755/godot_native/campuses/future_learning_center/scripts/workbench_view.gd:41) | Gears and belts are dragged onto the assembly, an installed belt can be twisted, and the tension dial previews its position. The physical lever runs or stops the model-owned feed trial. |
| [touch_stick.gd:19](/Users/zhu/.codex/worktrees/north-clean-object-layers-20261027/755/godot_native/campuses/future_learning_center/scripts/touch_stick.gd:19) | One recognizable analog stick owns its initiating pointer, retains analog magnitude outside its dead zone and returns to neutral on release, cancellation, hiding or focus loss. A second finger cannot release the active stick. |

Keyboard equivalents remain secondary handlers. Default views show no hotkey instructions, numbered-port button row or permanent tutorial. The current archived pointer/touch runs use zero keyboard events. Simulation and completion stay in the apparatus models; the presentation supplies gestures and draws state.

## Do's and Don'ts

- **Do** make the pending pose, visible grip, hit region and eventual model operation agree; restore the original state after cancellation.
- **Do** preserve notebook clues as voluntary, and give concise recovery feedback for a specific failed manipulation.
- **Do** keep the analog stick and tap-to-approach on the same legal movement path.
- **Don't** replace apparatus operation with an action strip, numbered socket buttons or default hotkey prompts; this is the standing user rule.
- **Don't** promote the current close-up worktable composition into a required layout for every other room. The existing art and spatial authorities continue to govern those surfaces.

## Evidence and acceptance

This documentation pass read the five component implementations above and their current authorities, reopened the twelve native captures listed below plus the two browser captures linked afterward, parsed both current object-input reports and the final verification receipt, read the three targeted model/space logs, checked source/capture freshness and verified the new table/control asset hashes. It did not replay the tests or the browser session. All twelve reopened native captures postdate the five reviewed scripts.

| Reopened capture | Visible evidence |
| --- | --- |
| [desktop/solar_initial.png](/Users/zhu/.codex/worktrees/north-clean-object-layers-20261027/755/.impeccable/review/flc_object_interaction_20261029/desktop/solar_initial.png) | Default apparatus, separate parts, lamp, physical lever, small notebook and exit |
| [desktop/solar_lamp_drag.png](/Users/zhu/.codex/worktrees/north-clean-object-layers-20261027/755/.impeccable/review/flc_object_interaction_20261029/desktop/solar_lamp_drag.png) | Lamp displaced during drag with pending light cone |
| [desktop/signal_receiver_drag.png](/Users/zhu/.codex/worktrees/north-clean-object-layers-20261027/755/.impeccable/review/flc_object_interaction_20261029/desktop/signal_receiver_drag.png) | Receiver between slots, above its peer, with attached socket/cable endpoint |
| [desktop/mechanical_complete.png](/Users/zhu/.codex/worktrees/north-clean-object-layers-20261027/755/.impeccable/review/flc_object_interaction_20261029/desktop/mechanical_complete.png) | Assembled drivetrain, feed block at its mark and readable local labels |
| [desktop/robot_blocked.png](/Users/zhu/.codex/worktrees/north-clean-object-layers-20261027/755/.impeccable/review/flc_object_interaction_20261029/desktop/robot_blocked.png) | Robot stopped before the blocked return entrance, with a specific recovery message |
| [mobile/room_joystick.png](/Users/zhu/.codex/worktrees/north-clean-object-layers-20261027/755/.impeccable/review/flc_object_interaction_20261029/mobile/room_joystick.png) | A single visible analog stick in the room |
| [mobile/solar_notebook.png](/Users/zhu/.codex/worktrees/north-clean-object-layers-20261027/755/.impeccable/review/flc_object_interaction_20261029/mobile/solar_notebook.png) | Enlarged notebook, complete body lines on paper, apparatus still visible |
| [mobile/signal_complete.png](/Users/zhu/.codex/worktrees/north-clean-object-layers-20261027/755/.impeccable/review/flc_object_interaction_20261029/mobile/signal_complete.png) | Synchronized receivers and readable backed labels after two distinct updates |
| [mobile/mechanical_complete.png](/Users/zhu/.codex/worktrees/north-clean-object-layers-20261027/755/.impeccable/review/flc_object_interaction_20261029/mobile/mechanical_complete.png) | Readable component labels and complete drivetrain at the fitted mobile scale |
| [mobile/robot_loop_complete.png](/Users/zhu/.codex/worktrees/north-clean-object-layers-20261027/755/.impeccable/review/flc_object_interaction_20261029/mobile/robot_loop_complete.png) | Delivery/unloading/empty-return completion state, with the upper route visible |
| [mobile/solar_lamp_drag.png](/Users/zhu/.codex/worktrees/north-clean-object-layers-20261027/755/.impeccable/review/flc_object_interaction_20261029/mobile/solar_lamp_drag.png) | Pending lamp/light feedback at mobile scale |
| [mobile/signal_receiver_drag.png](/Users/zhu/.codex/worktrees/north-clean-object-layers-20261027/755/.impeccable/review/flc_object_interaction_20261029/mobile/signal_receiver_drag.png) | Pending receiver/socket/cable movement at mobile scale |

Current source SHA-256 identifiers, checked against the reopened captures' modification times:

| File | SHA-256 |
| --- | --- |
| physical_bench.gd | `e72be25a0403cfd66c14fc8a33ac11970ca552547d702adfe184be722a0e1b0b` |
| motion_lab_view.gd | `f6137da46b27efe1561fa5a9387378b860ce763ce0124908c8c98c1bab753317` |
| signal_sync_view.gd | `761880399d2f8980410a421e8287af63e9308a165767b3a78390405265ee6709` |
| workbench_view.gd | `0135c9e933d55fdc0d688a2e87c6811b8a4a6368be0612205f7d87971c977fa4` |
| touch_stick.gd | `d9c63cb88e8a13b013669c06a6f370720394f0bb18cf2d5a52fe926d93abdd94` |

The working tree is uncommitted over base `4c5fa5f147ce3cdd492895a97f9cca69fd415efd`. The current [desktop input report](/Users/zhu/.codex/worktrees/north-clean-object-layers-20261027/755/.impeccable/review/flc_object_interaction_20261029/desktop/object_input.json) contains **47 checks** and the [simulated-touch report](/Users/zhu/.codex/worktrees/north-clean-object-layers-20261027/755/.impeccable/review/flc_object_interaction_20261029/mobile/object_input.json) contains **53 checks**; every listed result passes, with **zero failures and zero keyboard events** in both. They cover assembly, invalid drops, pointer ownership, cancellation, notebook movement, the real-time thirty-second race, two robot return routes, cable/pattern updates, receiver identity, undo, trial completion and exit. Touch is simulated, not a physical-phone result.

The current [object-interaction verification receipt](/Users/zhu/.codex/worktrees/north-clean-object-layers-20261027/755/godot_native/campuses/future_learning_center/review/OBJECT_INTERACTION_VERIFICATION_20261029.json) associates these input reports with the five source hashes above. The reviewed targeted-run logs record motion **63/0** with ten winning solar builds, signal **15/0** and floor spatial **1740/0** checks/failures: [motion_models.log](/Users/zhu/.codex/worktrees/north-clean-object-layers-20261027/755/.impeccable/review/flc_object_interaction_20261029/motion_models.log), [signal_models.log](/Users/zhu/.codex/worktrees/north-clean-object-layers-20261027/755/.impeccable/review/flc_object_interaction_20261029/signal_models.log), [floor_spatial.log](/Users/zhu/.codex/worktrees/north-clean-object-layers-20261027/755/.impeccable/review/flc_object_interaction_20261029/floor_spatial.log). Older motion/signal verification receipts describe an earlier interface and are not current object-interface acceptance.

The final receipt also records two completed **Codex in-app browser desktop smoke flows**, using CUA pointer clicks/drags and zero keyboard events in the actual Godot export. The reopened [browser_robot_complete.png](/Users/zhu/.codex/worktrees/north-clean-object-layers-20261027/755/.impeccable/review/flc_object_interaction_20261029/browser_robot_complete.png) shows cargo at the right destination and the empty robot at home; [browser_solar_complete.png](/Users/zhu/.codex/worktrees/north-clean-object-layers-20261027/755/.impeccable/review/flc_object_interaction_20261029/browser_solar_complete.png) shows a full 30.0/30-second race with **116.3** modified distance versus **106.5** baseline. The coordinator's receipt records empty warning/error logs after each flow. This covers those two desktop smoke flows; the full cross-browser/mobile and product-release matrix remains unaccepted.

The current [native preflight metadata](/Users/zhu/.codex/worktrees/north-clean-object-layers-20261027/755/.impeccable/review/flc_object_interaction_20261029/native_preflight_final.json.meta.json) identifies **Godot 4.7.1.stable.official.a13da4feb** and records **5 selected stages passed out of 541**, with **536 not run**, `partial: true` and `fullSuitePassed: false`. Its five stages are prepared inputs, save isolation, import/editor parse, startup and the complete script-parse graph. This is focused preflight evidence.

The [finish verdict](/Users/zhu/.codex/worktrees/north-clean-object-layers-20261027/755/.impeccable/review/flc_object_interaction_20261029/finish_verdict.md) is **ship for its three scored fixes only**: pending lamp feedback; receiver/socket/cable preview; and mobile text size/label contrast. Current source and reopened captures support those resolutions. The verdict does not establish formal game-save/chapter integration, complete native-suite or browser release acceptance, strict 32-color compliance, novice difficulty, physical-phone acceptance, deployment or whole-building completion.
