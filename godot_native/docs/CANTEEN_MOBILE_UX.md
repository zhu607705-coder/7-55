# Canteen mobile interaction fixes

The canteen now keeps the next action visible while the player earns the three tray returns, mixes the drink, places it on the promotional board, and reaches the menu. The existing journal opens directly from an 84 × 44 pixel Tasks button in compact exploration.

The floor-tap change addresses a measured endpoint beside the northern service wall. The selected floor center was outside the wall, but the actor’s full feet overlapped it by about 1.016 screen pixels. In the canteen only, an empty-floor tap may resolve to the nearest legal full-foot position within 6 physical pixels. Furniture, actor and HUD ownership still veto correction; taps inside solids still reject. The same route planner and collision shapes remain authoritative.

## Actual input evidence

- At 390 × 844, the player opened Tasks from the world, returned without movement leaking through the journal, reached the mixer through visible floor routes, and poured black coffee.
- A repeated pour was refused. Escape retained the partial mixture. A normal save, application close and restart retained the black layer and consumed bottle. The blue and white pours then produced the correct drink.
- The completed drink was dragged from the compact bag into the visible board cup. The drink was consumed, the authored board/queue presentation ran, and ordinary exploration returned.
- The first run exposed a generic objective after that transition. The final helper restores the original menu title and its two mode hints. A new normal restart at 430 × 860 showed the corrected journal, and the player reached the real menu, inspected the dark names, tested the ordering refusal, switched light and closed it safely.
- The exact wall-edge endpoint was compared with the prior World script using unchanged ordinary earned saves. The old version stayed at `(867.5555, 258.8125)`; the repaired version walked around the queue to `(609.7778, 216.625)`. A true wall-center tap still rejected. Canteen facts, inventory and wallet were unchanged.

The first candidate approach encountered an existing randomized NPC near-pick. It remains recorded separately. The exact endpoint comparison starts from the unchanged normal save genuinely earned in the baseline replay; no actor or story values were edited.

## Validation boundary

The final runtime is identified by the adjacent validation JSON. An earlier 176-stage aggregate passed before the final menu-title restoration; it is not the final revision’s gate. The final revision then passed a fresh 177-stage aggregate, Linux and Windows export builds, 795 packed campaign checks, and 25/21 native-only startup/reload checks. A standalone Linux GUI replay verified the 430-pixel journal and native menu; its normal close produced no script or ObjectDB warning. The graphics driver still reports its known unsupported V-Sync warning.

The runtime uses Godot scenes and GDScript. Source TypeScript remains an oracle for tests. Native-only exported checks run with an empty executable search path and without the web source as a runtime dependency.

Actual computer-use evidence covers 390 and 430 portrait windows. Responsive landscape and control ownership also have routed input regressions. Physical phone hardware and subjective speaker listening remain unverified.

## Separate known issue

The wrong recipe correctly creates the failed drink and does not advance the queue. A later actual check found that dragging this drink onto the player does not reach the original optional tasting action. That missing self-use target is being repaired separately; it is not represented as fixed by this batch.
