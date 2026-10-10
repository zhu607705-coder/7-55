# Modeled funhouse theater: review slice

The native spotlight mini-game now combines a modeled stage, a scene-only funhouse lens, and a revised three-act challenge. `scripts/games/c3_spotlight_model.gd` and `src/scenes/rpg/TheaterSpotlightModel.ts` implement the same current rules. Browser target feedback was updated with that model. The separate theater exploration map remains outside this slice.

## Scene

- Independent Node3D followspot: hanging yoke, tilt pivot, steel housing, cooling rings, lens rim and barn doors
- Shadow-casting light aimed at the light-creature position; restrained translucent dust cone, no bloom
- Three layers of pleated curtain geometry, rigging, batched floorboards, exposed stage apron and footlights
- Independent upholstered walking-chair meshes
- Planar light creature, punctuation, delayed actors, eye, audience and mouth exit inside the same scene viewport

See `THEATER_OBJECT_AUDIT.md` for per-object status. The light creature and punctuation have not become 3D models. The decorative chair moon and original third-act upper audience/streaks remain open fidelity items.

## Lens and input

A fixed S-glass function with alternating local magnification affects only the scene SubViewport. The CPU pointer transform uses the fragment shader's sampling function. Labels, captions and buttons stay outside the lens. A Newton inverse projects source gameplay positions for tests and presentation. No time-varying camera wobble is introduced. Displacement exceeds 80 authored pixels and local horizontal scale varies by over 2× while the center keeps its horizontal scale. Opaque header/footer/dialog slabs are removed; text has a small glyph shadow and one-pixel outline.

Pointer steering submits a bounded analog final step so it can reach a stationary target without oscillation. The touch marker keeps a constant display radius. Keyboard movement takes priority over pointer steering. The revised challenges add no new player inputs: use the existing pointer/touch or WASD/arrow movement and Space dash.

The 960 × 540 logical frame, source head bounds (`x=71..889`, `y=145..396`), 50 ms ticks, three lives and 1,600-tick/80-second limit remain. Pointer ownership records device/type/touch index. Cancellation, pause, focus loss and reuse clear ownership. No presentation node writes save state.

## Current three-act rules

IDs below are zero-based model IDs. Distances are source-space pixels before the funhouse lens.

| Act | Targets | Completion rule |
|---|---|---|
| 1: moving commas | IDs 0–3 follow bounded, phase-offset paths | Enter a 25-pixel radius for one eligible tick; collect all four and reach the mouth |
| 2: paired moving question marks | Pairs `[0,2]` and `[4,3]`; central ID 1 unlocks last | Charge either endpoint, then its partner before the exclusive deadline; complete both pairs, then charge ID 1 |
| 3: delayed-light cooperation | Fixed anchors in pairs `[0,2]`, `[4,3]`, `[5,1]` | The live actor and its harmless three-second echo light opposite endpoints together for 16 consecutive ticks |

### Act 2: timed handoff

- Both moving endpoints use a 75-pixel light radius and require 20 focus ticks: one second of uninterrupted illumination is sufficient
- An eligible, unblocked target gains one focus tick per model step. An unselected target loses two, down to zero. Dash cannot add focus
- Completing the first endpoint primes it without collecting either endpoint. Only its partner can then charge
- The partner window starts at 110 ticks (5.5 seconds). Each later step decrements it before charging. A remaining value of one expires on the next step before that step can complete the pair
- Completing the partner permanently collects both endpoints. Either pair can be completed first, and either endpoint can start a pair
- ID 1 becomes eligible only after both pairs are permanent. It needs the same 20 focus ticks; it has no partner
- The 60-tick delayed shadow remains a damage hazard in this act

### Act 3: simultaneous cooperation

- All six anchors are fixed. The live actor and echo each use a 75-pixel light radius
- At tick 60 the echo first displays the original position. Thereafter it follows the exact position from 60 ticks earlier. It is a harmless light source, not a shadow hazard
- The actors must illuminate different endpoints of one unfinished pair at the same time. Each ray must be clear. The same pair must remain lit for 16 consecutive ticks (0.8 seconds)
- A gap, blocked ray or dash resets unfinished simultaneous focus. Both actors standing at the same endpoint cannot complete a pair
- Completed pairs stay collected. There is no sequential priming deadline in this act; the 110-tick handoff belongs to act 2
- Moving chairs, the eye hazard and wind still apply. The player plans a route with the existing controls; there is no second-actor control or automatic player steering

### Occlusion, damage and persistence

For acts 2 and 3, a chair blocks light when its center is less than 26 pixels from the **segment** between the light actor and target (`chair radius 21 + margin 5`). This is neither a target-only proximity test nor an infinite ray. The echo's ray is checked separately. Moving to a different safe vantage can restore illumination.

Each step moves the actor and records history before evaluating damage. If a collected set was already complete, entering the mouth still wins before hazard damage. Otherwise, damage is resolved before any new charge: it clears temporary priming/focus and prevents charging on that tick. It preserves completed groups and movement history. A new attempt starts with fresh history and temporary state; already completed acts remain controller-owned.

The movement/dash contract remains nine dash ticks, 100-tick cooldown and 36-tick damage protection. The version-2 proof remains `round`, `attempt` and bounded `x/y/dash` inputs. Chapter authority replays the full trace; UI outcome flags never award success. Saves persist completed round/attempt counts, not partial focus or movement traces. An old trace must satisfy the current rules when replayed; it cannot assert its previous outcome.

## Feedback

Targets use group colors, focus rings and muted locked states. Acts 1 and 2 show short predicted-motion dots; act 3 keeps its anchors fixed. Rays show light from the warm live actor and cyan echo. Crossed target marks indicate chair occlusion. The act-2 status shows the handoff countdown; act 3 uses a short pair-status label; verbose actor/delay explanations were removed. An actual model injury triggers a 0.65-second scene-local impact ring and fragments, short squash/stretch and warm/red-white flicker, plus a burst at the removed HUD wick. Hurt copy persists for 1.3 seconds. The feedback has no gameplay timers or damage writes, freezes on pause, and clears on reuse. These displays read model state and do not complete targets themselves.

## Run

Import the normal native project and run `tests/preview_theater.tscn` with F6. It mounts the same `c3_spotlight.gd` used by Main, validates submitted proof, and allows continuation or retry without writing story saves. F9 saves the viewport PNG and input proof under `user://theater_review`.

R/F10 replays the three source QA routes. F11 records a 15-second act-3 excerpt (ticks 155–455) from saved physical mouse/Space inputs. It shows one pair completed, ends at 2/6 with the act still running, and does not claim full completion. The prefix is replayed from a fresh state rather than teleported. Rendering samples the 20 Hz model at 30 fps without speeding up time. These are QA capture controls, not player controls. The editable baked scene is `scenes/theater/funhouse_stage_editable.scn`; `tests/export_theater_model.gd` regenerates it.

## Verification scope

- `test_theater_lens.gd`: inverse roundtrips, positive Jacobian, CPU/shader agreement, model anchors, viewport event routing, pointer device ownership and lifecycle boundaries
- `test_theater_pointer_arrival.gd`: stationary arrival, lens extremes, wind and post-dash convergence at 1280×720, 1024×768, 390×844 and 844×390
- `test_theater_stage_model.gd`: independent lamp hierarchy, ray-projected anchors, source texture, shadow budget, batched geometry and pose-update isolation
- `test_theater_show_ui.gd` and `test_chapter3.gd`: actual Main/State acceptance, replay authority, retained result and explicit continuation
- `test_theater_balance.gd`: source/native sampled state comparison, pair deadline and damage precedence, clear/blocked ray witnesses, exact echo delay, harmless echo and simultaneous-pair semantics
- `test_theater_hit_feedback.gd`: one visual burst per authoritative injury, unchanged lives/protection, pause/retry cleanup and removed labels
- `test_theater_preview_storage.gd`: optional capture/measurement failure must not interrupt play; output belongs in writable user data

The current `spotlight_balance_samples.json` contains nine QA-generated winning routes: all three acts at attempts 0, 1 and 2. Its source hash matches the TypeScript model at the 2026-10-10 documentation review. These fixtures establish route reachability and provide parity inputs. They do **not** establish player difficulty, expected completion time, tutorial clarity or usability. The QA route planner is not shipped as player steering. Regenerate these fixtures after intentional rule changes with `node godot_native/tools/export-theater-balance-fixtures.mjs`.

Manual mouse-input validation observed one act-3 first pair advance from 0/6 to 2/6. Later naive direct paths failed under chairs/eye hazards. This is limited input/mechanism evidence, not a formal usability study or a completed manual three-act run. Earlier exposure-only runs and their completion times do not validate the current pair/echo challenge.

An earlier 480-frame cloud llvmpipe sample at 1152×648 measured mean 31.8 fps, median 35 fps, p10 28.8 fps and 174 frame draw calls. It is a historical software-renderer observation, not a current hardware performance guarantee. Physical mobile, Windows/Mac execution, final full-web build and final art acceptance remain pending. Synthetic scaled input and automated successful routes cannot replace those checks.
