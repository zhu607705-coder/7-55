## verdict

Limited verdict pass on F1–F3 from `finish_review.md`; no broader polish review was reopened. All 15 requested recaptures were opened individually and are valid: six desktop states, the corresponding six mobile states, and the three actual-browser solar light states at 903 × 862. Intentional letterboxing preserves the playfield.

| Finding | Score | Evidence |
| --- | --- | --- |
| F1 — Shared sunlight result | resolved | Desktop, mobile, and actual-browser initial captures show a shared golden illuminated area across the two belts and the space between them. The shadow interval removes the strong golden field and visibly dims both cars and belt surfaces; the closed-shutter captures darken them further and show the closed plate. The widened overhead diffuser makes the shared source legible. These states are now distinguishable from their rendered surfaces without relying on the percentage caption or distance values. |
| F2 — Visible belt travel | resolved | The seams are visibly above both decks in every recaptured solar state. In each desktop/mobile running A/B pair, separated by 0.4 seconds, the seams move left while the cars remain beside the meter. Both belts show movement, and the seams remain legible at touch scale without reintroducing ruler numbers. The JSON pixel checks corroborate rendered belt movement independently of the distance text. |
| F3 — Labels during physical movement | resolved | In both receiver-drag recaptures, the stationary receiver name is suppressed where it would otherwise be painted across the dragged screen; the active receiver identity remains above its screen. The solar operating cue is now above the gantry and outside the shutter/handle path in desktop, mobile, and actual-browser closed-shutter captures. |

The supplied input JSON now records 52 desktop checks and 58 touch checks, with zero failures and zero keyboard events; the presentation JSON records 40 checks with zero failures. These support the recaptured states and remain automated input evidence rather than human playtesting or physical-phone validation. No material regression introduced by this fix batch is visible in the recaptured F1–F3 states.

## remaining

Clear for F1–F3. The reviewer scored all three listed fixes resolved. This verdict covers those fixes only and does not claim a new whole-surface audit, all-room completion, formal campaign/save integration, a physical-device test, or whole-release acceptance. Preserve the single side meter, physical controls, fixed projection, four-prototype scope, and existing model/room boundary. The separate documentation step remains part of the original finish workflow.

disposition: ship
