# NPC interaction feedback

The native world gives existing NPC interactions a short visual acknowledgement. The cues read existing target geometry and controller results; they do not change actor artwork, actor motion, interaction radius, input selection, rewards or save data.

## Presentation

| Event | Cue | Duration | Trigger |
| --- | --- | --- | --- |
| Approach | Two small pixel glints above the actor | 0.44 s | The current eligible nearby target remains in its existing interaction radius for 120 ms |
| Accepted dialogue | Three small square dots | 0.64 s | The existing controller returns a positive, supported dialogue result |
| Earned completion | Four pixel glints spread and settle | 0.88 s | An observed controller transition earns one of the completion receipts below |

An approach cue plays once per continuous encounter. Re-entry has a 1.8 s cooldown. At most three cues are active, with completion taking priority over dialogue and approach for the same actor. Repeated input does not continuously restart a cue. There are no permanent markers, input surfaces, particles, imported textures or new runtime dependencies.

Each cue has eight authored poses in an 80 × 80 logical pixel space and at most four colours. Rendering uses integer-aligned rectangles, stepped alpha and the existing world zoom. The logical canvas is scaled down to fit beside the original actor. Reduced motion holds a single static pose for the same short lifetime.

Placement comes from the painted actor's existing texture/frame transform, not the counter's broad interaction rectangle. The renderer tries above the head, then either side, within the existing exploration safe rectangle. It excludes the actual visible C3/library dialogue panel, including panels in the root UI viewport. If no position fits, the cue is omitted. The narrow canteen fixture exercises this omission when the actor is mostly above the viewport; it does not move the camera or UI to make space.

## Supported interactions

- Library: the existing front-desk actor, with dialogue acknowledgement for a normal accepted reply. Queued library story results without a positive dialogue receipt retain their existing story presentation.
- Canteen: auntie and the initial counter, queue and seated NPCs. Dialogue cues require the existing narrative-owned result in the supported light-mode phases. An ambiguous short reply does not count as an accepted dialogue receipt.
- Chapter 4: the A1 front-desk attendant, A2 elevator attendant and A3 reference teacher, through their existing actions and floor/time/phase conditions. Opening the elevator attendant's deduction page keeps the world hidden as before.
- Completion: returning the third distinct valid blue tray to auntie, and first earning `elevator_stop_chain_reconstructed` through the existing A2 deduction controller. Wrong answers, invalid/duplicate trays and already-owned facts do not produce a success cue. Other quests have no completion binding in this change.

The A2 completion happens on an existing phone page. One transient receipt may wait for a direct return from that same deduction page to the same state owner and world context. Changing page, loading, changing mode/floor/time/phase or leaving the scene cancels it. It is not serialized or reconstructed from a loaded completion fact.

## Ownership and lifecycle

`presentation/npc_interaction_feedback.gd` owns only short-lived visual state. `presentation/npc_feedback_bindings.gd` contains read-only target, result and painted-geometry selectors. `world.gd` forwards accepted interactions and `State.action_completed` transitions, and draws through the existing world tail pass.

State-object identity and scene/mode/chapter context delimit cue ownership. Hidden worlds, scene transitions, scripted world presentation, capture and actor-hidden states clear visible cues. Focus loss and existing shell modals freeze their clocks; resuming uses actual elapsed active frame time. World teardown clears pending work and disconnects the completion listener. No animation callback grants progression or completes a narrative capability.

## pixelfx reference

Reference revision: [`patch-gg/pixelfx@a84159688af3ca37a4be05a0d422b94451b2e24e`](https://github.com/patch-gg/pixelfx/tree/a84159688af3ca37a4be05a0d422b94451b2e24e), version 0.3.0, containing 244 catalog effects.

- [`ui/exclamation.js`](https://github.com/patch-gg/pixelfx/blob/a84159688af3ca37a4be05a0d422b94451b2e24e/src/fx/ui/exclamation.js): compact attention/settling timing reference.
- [`pickups/collect-burst.js`](https://github.com/patch-gg/pixelfx/blob/a84159688af3ca37a4be05a0d422b94451b2e24e/src/fx/pickups/collect-burst.js) and [`pickups/_lib.js`](https://github.com/patch-gg/pixelfx/blob/a84159688af3ca37a4be05a0d422b94451b2e24e/src/fx/pickups/_lib.js): short glint and outward-motion references.
- [`ui/quest-complete.js`](https://github.com/patch-gg/pixelfx/blob/a84159688af3ca37a4be05a0d422b94451b2e24e/src/fx/ui/quest-complete.js): completion timing reference; its banner and checkmark are not used.
- [`skills/pixelfx/SKILL.md`](https://github.com/patch-gg/pixelfx/blob/a84159688af3ca37a4be05a0d422b94451b2e24e/skills/pixelfx/SKILL.md): inspect, render and refine workflow.

The GDScript implementation and three-dot dialogue cue are independently authored for this game's palette, scale and lifecycle. No upstream JavaScript, sprites, gallery fonts or other assets are bundled. Upstream credits and licensing remain available in its [MIT license](https://github.com/patch-gg/pixelfx/blob/a84159688af3ca37a4be05a0d422b94451b2e24e/LICENSE).

## Verification

`tests/test_npc_pixel_feedback.gd` checks cue timing/priority, eight poses and palette limits, reduced motion, placement/exclusions, actual controller success/rejection edges, unchanged gameplay authority, live proximity, focus/visibility, state replacement, scene/floor changes and pending-page completion. It is discovered automatically by the existing native validation catalog; no CI coverage is reduced.

At implementation, Godot 4.7.1 focused native validation passed 153 checks across four suites: the new feedback suite (108), existing NPC interaction motion (26), world presentation lifecycle (12), and modal world input (7). Each suite used isolated user data; source hashes were unchanged across the run.

The rendered fixtures use the actual Main scene and resources at 1280 × 720, 390 × 844 and 844 × 390, covering all three cues plus an actual canteen narrative panel. Cue ages are held for inspection; these are presentation fixtures, not a completed campaign playthrough or physical-phone acceptance. The associated PR records cloud CI status separately.

For a full checkout with the pinned Godot binary, the existing validator can select the new suite:

```sh
GODOT_BIN=/path/to/godot-4.7.1 node godot_native/tools/validate_native.mjs --profile changed --test test_npc_pixel_feedback.gd
```

Changes to shared `world.gd` still expand the repository's changed-path plan to full coverage. Local focused results do not replace the PR's native, source-Web and actual Godot Web CI gates.
