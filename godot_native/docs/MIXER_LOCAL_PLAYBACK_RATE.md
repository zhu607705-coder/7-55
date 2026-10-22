# Native mixer local 0.75 playback

The 0.75 rate originated at base 1c7e200b. Cup-paddle presentation durations were revised on 2026-10-10; see MACHINE_PRESS_INTERACTION.md. Only c3_mixer_motion and c3_mixer_panel presentation clocks change. Engine.time_scale, source transactions, inventory, recipe validation and reward commits are unchanged.

| Beat | Local logical time | Wall time at 0.75 |
|---|---:|---:|
| Ordinary cup-paddle cycle | 1050ms | 1400ms |
| Terminal cup-paddle cycle | 1350ms | 1800ms |
| Settle + result + return | 660ms | 880ms |
| Reduced ordinary pour | 140ms | 186.67ms |
| Reduced terminal pour | 220ms | 293.33ms |
| Reduced return | 260ms | 346.67ms |

Three rapid clicks still commit their three original controller actions immediately. Their optional animation presentations remain queued. Escape, replacement save, scene change, and teardown still cancel only the presentation.

Tests executed in isolated /tmp profiles with Godot 4.6.3 headless: test_mixer_playback_rate 27 checks, zero failures; test_canteen_mixer 312 checks, zero failures. test_mixer_completion_continuity 110 checks, zero failures (rerun with a 20-second external process limit). Total: 449 checks, zero failures. Neither a headless run nor simulated delta steps measure real rendered FPS.

Source presentation video is still the v13 original, with 30fps repeated-nearest-frame encoding from a lower-rate wall-clock capture. HTML rate 0.75 means an 8s loop for its 6s source. This is not interpolation or native recapture.
