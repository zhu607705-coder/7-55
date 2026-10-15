# C3 original fishing presentation and return flow

This candidate restores the active original `QizhenLakeScene → QizhenFishingRhythmVisual → LakeFishingRitualVisual` presentation in native Godot. The baseline was a small simplified fishing field with the old lake hint visible beneath it. The existing dawn lake and angler/skiff textures now fill the activity surface, with source-shaped fish/swan/rod/line and visible target, cast, four-beat and result cues. Native controls occupy their own physical rows. The retired lane/tutorial renderer is not the reference.

The original PNG bytes, rhythm model, scoring, chart timing, result proof, lake controller, map and world collision remain unchanged. There is no new artwork or full-3D claim. The new CanvasItem view reads the existing model. It cannot update that model, submit a result or save progress. Native Ready/Pause/Retry and the existing 0.9-second result hold are retained; this is not a claim that every browser presentation detail or browser input convention is already identical.

A source-style water press/drag owns one held hook plus one direction. Outside release completes one release; canceled touch, resize, focus loss and Pause neutralize the controls. Main restores the existing world input focus after the activity returns. This fixes the demonstrated extra-click cost after Exit.

Pause/Retry/Exit also needed an ownership repair. The old broad `qizhen_fishing_` pause key survived after native beat cleanup, leaving warning playback paused and the source lakeside-return cue queued. Retirement now closes both scopes once, before the fresh return cue or accepted-result callback. Later host deletion cannot stop the new return score. No source sound asset, gain or beat schedule is replaced.

## Actual acceptance and limits

The latest candidate was exercised on ordinary earned-save copies. The main C4 save remains SHA256 `520d4d56991ca08fbbfa34e42b24e24cdd7778c00ec98ea5c594236396c75460`.

- At 1180×812, the action row is hidden by default. A real 650 ms water press/release reached four-beat preparation, and Escape paused. The original lake and angler fill the field; the old world hint is hidden.
- The native window was resized while paused to exactly 390×844 and 844×390. The same preparation phase remained paused. The explicit fallback works at both sizes. At 390, real control-button input produced authored misalignment feedback; an aimed water press then reached preparation. These are cloud mouse tests at mobile dimensions, not physical touch-device certification.
- The restored official Linux executable was launched at exactly 430×860. After the separate approach failure described below, a normal reload and ordinary paddling reached the key water. Physical rod drag, fallback, successful pointer cast, paused Retry/Start and paused Exit passed. Immediate physical reverse strokes moved the boat after Exit without another world click. Normal Save and close succeeded. An earlier source resize measured 428×860; it is not substituted for this exact-430 exported check.
- Hook release outside its button remains a scored release, matching the original React pointer capture. Canceled input, focus loss, Pause, resize and control-mode changes use neutral release. Toolbar drag-out feedback is distinct from the held-hook release rule.
- Actual runs used Dummy audio. Audio ownership and playback timing are verified by focused automated checks; this batch provides no PCM, subjective hearing, new catch or unassisted rhythm-skill acceptance.

Evidence folders are `lake-fishing-flow-stage/actual-input-aware-1180`, `exported-final-430` and `exported-reload-430`, each with an immutable-input scope, screenshots, normal saves and resource log. Earlier 430 source-art checks and the 11:45 cloud disconnection remain historical evidence. The connection returned on a fresh host at 18:00; the exact base and all 1,209 candidate export inputs were restored before testing.

## Validation chronology

The unchanged full serial suite initially passed 220 of 221 stages. Its sole failure was an old assertion that rhythm must not own an activity layout. The corrected test positively checks the full physical fishing surface and retains kayak's old contract; its focused 29-check rerun passed. This is a reconciled result, not an uninterrupted 221-pass run.

After the input-aware refinement, the 180-check control test and six affected scripts passed. Seven packed tests passed after restoring an omitted, byte-identical `chase.json` fixture to the external mobile-chase harness. Its initial timeout is retained as a harness failure. The earlier pack also passed the continuous automated chapters 1–4 campaign and native-only empty-PATH save/reload checks; these preceded the final input refinement.

A strengthened audio test reproduces the prior-frame timer mismatch: a 100 ms SceneTreeTimer could return after 1 ms wall time, before the unchanged 40 ms lakeside cue. The cue then played normally at 49 ms. The test now checks actual unpaused playback using a monotonic 40–1500 ms window. No runtime delay was weakened.

After host replacement, the identical 1,209 source inputs produced a fresh Linux pack of 583,711,804 bytes, SHA256 `b9d4a2a27a3d91c669b13fdc77448cf755ef1de5c605892ff593a339cca10bda`. Its audio-lifecycle, focus-return and control-mode checks passed again, followed by the actual exported 430 run above. Runtime manifest: `cbcc899cb4f42ae0ac5b1d23e7e672d5b836761e83837c8141498fc4c580ef21`. The previous lost pack had the same size and source inputs but a different archive hash; it is not presented as the current artifact.

Official release templates disable command-line path overrides. External packed tests therefore use the official editor binary; the executable is tested through its normal sibling-PCK boot. The unsupported release-template harness attempt and a prior forced-smoke ObjectDB warning remain recorded. No Windows rebuild is claimed.

## Separate open lake issue

The first exported approach showed “船的位置已失效，请回到安全检查点。” and stopped accepting paddle movement before fishing opened. Normal reload of the unchanged failed save restored control. A separate synthetic timing reproducer on the unchanged PR65 world/session/model demonstrates a pre-existing guard defect: after a 7.5 ms accumulated frame, a 1 ms frame can execute one 1/120 s model step, moving 2.817 px while the frame-delta guard permits 2.34 px. The full hull remains legal and model/player positions agree. This independently proves the timing defect; the uninstrumented CUA failure is only possibly related. The guard, collision and simulation are not changed in this presentation slice.

The original lake phone page's stale boarding sentence and clipped exploration control hint also remain separately recorded. This batch does not claim every lake surface or source presentation detail is complete.

## Input-aware control refinement

The later user request removes the persistent left/hold/right action row for keyboard/mouse use. It is enabled by touch capability, completed touch input, or the always-visible “触控按键” fallback; viewport width only affects spacing. An explicit choice wins over later input detection. A new touch cannot reflow the field while its gesture is held. Changing the control scheme during play uses the existing Pause and neutral-input path, preserving the current attempt and clock. A/D or arrows, Space, pointer casting, Pause, Retry and Exit remain available; T toggles the fallback, R retries and X exits this activity.

The source palette and font remain. Button borders and hit rectangles share integer coordinates; held controls use a distinct face. Touch toolbar feedback clears when dragged outside or canceled. Its paired emulated mouse is consumed so a single touch cannot activate twice. These refinements apply to the current fishing activity, not every minigame or the exploration paddles.
