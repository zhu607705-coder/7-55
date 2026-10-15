# Completed reduced-motion lamp saves

Integration exposed an inconsistency: the restored source reduced-motion sequence completed in3600ms, but the older native save validator required5800ms for every ending. The controller could finish the reduced sequence while its subsequent ordinary save was rejected.

The controller now writes playbackMode from the already-validated issued session, overwriting any client-supplied value. The save validator accepts only normal or reduced_motion; an absent marker retains the legacy normal5800ms requirement. Numeric, finite playback duration and existing prerequisites, nonce, saved answers and explicit acknowledgement checks remain. Changing settings after a normal session is issued or adding a client reduced marker cannot lower that session's threshold.

Regression before:25 checks,4 failures, including a rejected reduced-mode ordinary write. After:27 checks,zero failures; the two additional assertions become reachable when the reduced save successfully writes and reloads. Normal/reduced completed snapshots both round-trip through ordinary save_game/load_game, old unmarked5800 proofs remain compatible, old unmarked3600 and short/unknown mode proofs are rejected. Another headless read uses the exact actual earned71eb legacy completed save and passes unchanged; that is a reader compatibility check, not new GUI coverage.

This is an explicit integration correction on the final proposed combined tree. Earlier ten-file presentation and five-file admission snapshots remain frozen. No new art, puzzle state, elapsed-time shortcut, Git staging or publication is included.
