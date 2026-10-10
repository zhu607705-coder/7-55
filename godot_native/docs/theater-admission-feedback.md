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
