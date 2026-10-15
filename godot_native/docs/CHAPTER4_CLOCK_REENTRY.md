# Required-time clock admission

After the hour hand was actually installed, the normal save correctly retained `room204_restore` with `1225_bakery`. The world offered the hall clock, but its action was rejected by the phase/time alignment guard. This prevented selecting the required 18:50 interval.

The original scene opens its clock panel locally before submitting a time-change intent (`ChapterFourTemporalMazeScene.ts`, hall-clock interaction and `openClockPanel`). Its controller continues to reject unrelated actions during this mismatch. The native exception therefore applies only to opening `c4_clock` on A1 in light mode with an existing required time. The original selection, floor, mode and progression checks remain in place.

## Proposed separate scope

- `scripts/chapters/chapter4.gd`: bounded panel-admission exception
- `tests/test_chapter4_clock_reentry.gd`: required-time admission and actual State/Main control checks
- This validation document, when submission scope is selected

The frozen bakery objective change is an inherited prerequisite in this isolated test checkout, not part of this delta. Reading-anchor and elevator presentation candidates are separate. Nothing is staged or committed.

## Evidence

- Actual unmodified installed-hand copy: `../chapter4-room204-earned-route/clock-classroom-1180/manifest.json`; Space rejected the offered clock
- Focused before: 25 checks, 3 failed admissions; after: 30 checks, zero failures. Five additional checks become reachable only once the real modal opens
- Existing clock panel: 47 checks; Chapter4 controller: 114 checks; both pass
- Actual repaired source run: `actual-source/manifest.json`, 20 files. Escape/reopen, unchanged12:25, wrong22:45 and accepted18:50 were operated normally
- The same run reached the original104/105 records and saved at03:56:32, SHA256 `3b8c27ea998b0f7bd51c64a324b236ed9ed4265c67d93e8474619854f17eb852`
- The next ordinary run reloaded that save and retained the calibration objective; its closed evidence is `../chapter4-room204-earned-route/elevator-1180/manifest.json`

This is actual source-run Linux1180×812 with Dummy audio, not a new export, mobile acceptance, independent discovery or hearing claim. The later elevator presentation failure is separate. Canonical main remains the01:19:12 bakery checkpoint; these earned continuation copies are labeled.
