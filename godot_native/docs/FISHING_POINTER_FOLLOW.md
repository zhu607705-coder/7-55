# Fishing pointer following

A stationary press on the water used to keep steering in its initial direction. In an actual1180×812 paper challenge, holding at x600 for1500ms moved the float from x418 to x932. The target was not updated as the model moved, so the cast was rejected as off-target.

The host now retains the normalized pointer target and checks it before and after each existing model update. Reaching the original0.08 deadband releases only the pointer's directional input. Holding still continues to reel; it does not follow the fish. Keyboard input keeps its independent owner. Release, cancellation, pause, focus loss, resize and Retry retire the pointer target.

This is a bounded interaction correction. The original `LakeFishingRitualVisual.ts` also chooses direction in its pointer-move handler. Its browser event delivery was not independently rendered for this comparison, so this report does not classify the problem as exclusively introduced by the port.

The rhythm model,1.3 steering speed, timing windows, line tension, cast charge, fish movement, input receipt and replay validation remain unchanged. The host still uses its existing0.1-second update cap for fishing. No position is assigned directly and no success is granted by the pointer adapter.

## Validation

- Initial stationary-pointer regression:28 checks,16 failures; the narrow runtime correction passes28/28
- Strengthened regression:76/76 at1180×812,390×844,430×860 and844×390. It covers stationary mouse and touch,60Hz and100ms steps, drag reversal, elapsed-time preservation, neutral interruption, outside release and independent keyboard ownership
- The first strengthened fixture had an unqualified Node notification constant. That test-only parse error was corrected and retained in the work evidence
- Six affected scripts pass: fishing view, control scheme, focus return, audio lifecycle, deterministic minigame models and gameplay audio wiring
- Actual baseline: normal materials save opens the paper challenge; water casting, Pause, failure feedback, Retry, Exit and ordinary Save work. The first lift was source/Pause-assisted and missed; the remainder was deliberately allowed to miss. This is not a new successful paper attempt
- The baseline fixed-pointer reproduction is a separate casting diagnostic. The long hold intentionally tests position retention, not valid cast power

The fresh official Linux export passes the same76-check fixture with runtime/assets loaded from its PCK outside the source project. Actual final-package1180×812 repeats the baseline x600/1500ms hold: the float now stops nearx581 rather thanx932, inside the original deadband. A subsequent valid650ms cast reaches count-in. Actual430×860 and390×846 repeat stationary and reversed targets, with visible touch fallback, Pause, Retry, paused resize, Exit, Tasks Return and normal Save. The copy’s items and lake facts stay identical. Exact390×844 and844×390 remain automated dimensions.

A source/Pause-assisted first-lift attempt still missed after the fix and was abandoned through Retry. This does not establish a new paper win or attribute the old failed attempt solely to pointer control. Long stationary-hold diagnostics deliberately exceed valid cast charge and do not test cast success. Headless/touch events and actual desktop pointer use are not physical finger or audible-play acceptance. All original art, story and earned inventory are retained.
