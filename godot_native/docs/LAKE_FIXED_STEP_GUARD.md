# Lake fixed-step movement validation

Ordinary high-speed paddling could cancel the live lake session with “船的位置已失效，请回到安全检查点。” even when the full hull was legal and the player exactly matched the simulation. Subsequent strokes were ignored until normal reload.

The kayak integrates at 120 Hz and carries an unprocessed fractional frame. The session validated displacement against only the current frame delta. After a 7.5 ms frame, a 1 ms frame can execute one full physics step: the real displacement is 2.817 px, while the former bound permits 2.34 px.

The session now uses the consumed simulation time: the bounded current delta plus the preceding remainder, minus the remainder still pending after integration. The previous remainder is sampled at binding and normal recovery. Invalid or invented remainder values are rejected. The existing speed bound, 2 px numerical margin, legal full hull, finite position, exact model/player agreement and controller-owned receipt remain required. Pending time cannot authorize displacement before a step executes.

No model, stroke impulse, turn, hull, obstacle, pursuit timing, capsize rule or story state changes. The proof clock is separate from the source-authored swan pressure clock.

A focused regression initially failed 18 of 61 checks, then passed all 61 with the correction. It covers accumulated and varying frame deltas, reverse motion, pause, safe recovery, renewed bindings, unearned movement, model disagreement, collision and invalid carry. Existing live-world/source comparisons and rotation/contact regressions pass. The first entry test used the wrong profile location and intentionally exited; its required isolated /tmp profile passed on rerun.

The actual uninstrumented exported failure is preserved separately. Normal reload of its unchanged save restored control. The synthetic timing reproduction independently proves the old guard defect, but does not establish the exact timing of that earlier CUA event. The corrected official Linux package passed the 61-check regression and actual 430×860 ordinary failed-save travel. The prior key order and later forward/turn/reverse inputs remained responsive. Normal Save, close, reload and renewed paddling passed; lake facts and items were unchanged. Actual runs used Dummy audio and provide no new catch, subjective-hearing or physical-touch-device claim. The main campaign save was untouched.
