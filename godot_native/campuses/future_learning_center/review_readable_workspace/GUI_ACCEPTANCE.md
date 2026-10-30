# Readable-layout actual GUI QA

2026-10-30. Godot 4.7.1 official / X11 Mesa, linked only to `flc-readable-layout-20261030`. Actual desktop mouse input via CUA. The observer only renders/captures state; it never sets puzzle model values or injects simulated input. PNGs are real viewport captures, not generated images or realtime video.

## Koala final 48-check revision

- Dragged modules 5,4,3 from shelf into sockets 0,1,2; clicked physical crank.
- Dragged B card into input clamp and cranked again. Both revision3 receipts passed; completed=true.
- `koala_card_in_hand.png` captures actual held B card in transit. It retains the same 86×72 body and four miniature tokens as on shelf, without resizing into the input display.
- Opened physical notebook, inspected steps; clicking outside closed it without triggering the underlying crank.
- Closed and reopened same view at780×438. Completion and chain preserved. Clicked notebook at scaled coordinates; hit geometry remained aligned.
- Final images: koala_initial_960, koala_card_in_hand, koala_completed_960, koala_notebook, koala_reopened_780.

## Formula final layout

- Physically installed large panel and 1.6 gear, dragged tilt knob24px to30°, carried car to visible lower start gate, and clicked physical starting lever.
- Waited the unaccelerated30-second trial: player62.5170716 vs reference52.3500652; completed=true.
- Final960 and780 images show separate player/reference numbered results and retained physical configuration samples. Timer moved clear of the reference car. Labels no longer overlap the assembly car badge or gear numbers.
- Closed/reopened at780×438 preserved results; actual scaled notebook click opened the history page.
- Final zero-second re-entry check is recorded in formula_final.txt and formula_new_trial_zero.png.

## Evidence selection

Use final `koala.txt`, `formula_final.txt` and non-`earlier_` captures. Earlier screenshots remain solely to show issues found and fixed. `formula_earlier.log` includes the first isolated font-import warning; final logs use imported MorningNote plus symbol font and have no resource/script error (display driver emits a VSync capability warning).

This is desktop GUI coverage, not physical-phone touch testing. No gameplay source was edited by the GUI observer. Close/reopen uses the same instantiated puzzle, not persistence across process restart.

The 780px Formula reopen capture uses the final layout before the final model-only outcome reset; the new-trial-zero capture separately verifies that final model change.
