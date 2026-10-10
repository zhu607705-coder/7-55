# Theater ticket admission feedback

Scope: native presentation only, based on `godot-version` 913bd512. This is independent of the spotlight PR and stair work.

The actual accepted-ticket state edge starts the original 0.9-second scan. The existing front and side scanner art are followed by a single 4-source-pixel / 3-degree acknowledgement and the existing right-facing idle pose. A drawn green check replaces the small cyan bar on the actual reader, and settles without looping. No new story object or text is added.

The bound narrative session clock owns the gesture while the admission dialogue is active, including focus pause. Invalid/cancelled/replaced sessions settle immediately. A restored admitted save shows the settled check without replaying the scan. Reduced motion retains a 160ms scan and clear check, without nod or pulse.

The controller remains unchanged: a valid combined ticket in light mode at the gate is required; the original three lines retain their timing; the ticket remains in inventory; the original 260ms fade (80ms reduced) and consumed-session callback are the sole auditorium handoff to (1080,590). The feedback renderer never grants admission, consumes an item, changes collisions, or teleports the player.

## Validation

- `test_theater_admission_feedback.gd`: 123 checks, including invalid/dark/far refusal, accepted state, original dialogue duration, early/forged/repeated acknowledgement, actual Main/World handoff once, retained ticket, cancellation, replacement/reentry, and actual actor-position freeze through 11 seconds of unfocused world ticking
- Main tested at 1280×720 and 390×844, including reduced motion
- Existing world layers, narrative model/shell, portrait narrative contract, chapter 3 progression and audio wiring regressions run separately

Review recording uses a prepared pre-admission checkpoint with the already-combined ticket. A physical click on the rendered reader issues the real interaction. It must retain the original dialogue timing and terminal handoff; it is not footage of earning the ticket from a new game.

## Ticket-passage correction

The first review clip began inside the exterior door's existing proximity sensor. That unrelated double door therefore opened before the reader was clicked. Neither its rotation nor the original admission destination was incorrect. The corrected capture starts at (842,740), inside the reader radius and outside both exterior-door sensor bands, and frames the actual ticket passage above the exterior entrance.

Two thin translucent acrylic wings now represent the existing `THEATER_GATE_BLOCKER`. They meet between the original side fixtures (x786..883), and retract horizontally into those fixtures after the existing accepted-ticket event. They do not rotate upward. The reader green check, original scanner poses and small acknowledgement remain.

`c3_ticket_gate_view.gd` owns presentation-only openness. Valid admitted players approaching the passage open it; an occupied actual foot-body strip forces it fully open. After the player leaves the wider approach zone, the wings stay open for 450ms and close over 420ms (120ms reduced). Re-entry during closure opens before a wing can touch the foot body. Restore/reset settles open for an admitted player in the passage and closed for a distant player, without replaying the scan. Active admission animation follows the bound narrative clock, including pause. No visual state is serialized or granted authority over admission, collision removal, ticket inventory or the original auditorium callback.

`test_theater_gate_passage.gd` now has 204 checks: safe reader position, exterior sensor closure, original pre-admission blocking, exactly one removed collision, unchanged remaining collision, accepted-edge feedback, wing geometry/sorting, pause, collision-safe northward input, retained ticket, once-only original handoff, normal/reduced opening/closure, occupied wait, interrupted closure, pure drawing and restored-state safety. The full admission test and existing narrative/world/portrait/audio regressions remain separate.

The corrected review clip preserves the original three dialogue lines and timing. Physical reader click opens the actual wings, ordinary W input moves the player through the ticket passage, the original callback reaches (1080,590), and the clear wings close behind. The exterior entrance remains closed throughout. The earlier raised-arm clip was superseded by this user-requested transparent-wing design.
