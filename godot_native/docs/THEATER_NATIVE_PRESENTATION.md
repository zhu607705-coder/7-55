# Native TheaterImpossibleShow presentation

`games/c3_spotlight.gd` now directly reconstructs the active original `TheaterImpossibleShow.ts` using native drawing and Controls. It does not use older spotlight-beam artwork or a simplified circle-only stage.

Retained source components: velvet curtains/hem, seated moon, audience/third-act ceiling, plank stage/current, animated chair hazards, shadow and eye hazards, mouth/teeth exit, punctuation aura/glyphs, multilayer light-creature trail/top hat/face, source HUD/status, intro/pause/awaiting/result panels, and the original three act palettes/copy.

Pointer movement remains limited to the authored stage, keyboard takes precedence over pointer steering, and dash is a queued one-step action rather than an indefinitely held button. Pause clears pointer/dash and freezes simulation. Each terminal trace is submitted to the controller while the native result screen remains mounted; only its explicit primary button proceeds to the next act or reversal. Source result wording is selected from actual validated success and final-act state.

`tests/test_theater_show_ui.gd` passes30 checks through the real Main/State/Control signal path, with actual pointer steering and queued dash inputs solving all three original models. It checks correct act setup, dark-surface label contrast, pause, controller validation, retained result screens and final acknowledgement. This is automated runtime input, not a manual playthrough or screenshot pixel match.
