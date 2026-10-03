# Kayak contact after a paddle turn

A normal lake save could become unplayable immediately after boarding. A paddle turns the full 83 × 67 source hull. Its new axis-aligned bounds then overlap the dock. Native movement rolled position back but retained the new heading, so the live session rejected the still-overlapping pose and stopped accepting every later stroke.

The actual failure was reproduced from the ordinary campaign after weather recovery. The authored dock spawn is `(714, 390)`; the dock begins at `y=430`. Even its north-facing hull extends to `431.5`, so existing world entry first finds a nearby legal position. A first left reverse stroke at that legal position expands the hull again. The unchanged-runtime diagnostic observes `running → cancelled` on the next frame, then an empty response to forward input.

## Restoration

`world.gd` resolves only the body expansion caused by an accepted paddle turn. It computes candidate contact offsets from the unchanged source blockers and selects the smallest legal correction. Each axis is bounded by the increase in that hull's half extent. It cannot shrink the boat, remove a wall, or move a deeply invalid origin to safety.

`c3_lake_world_session.gd` first verifies that the pre-stroke position is the last accepted, legal, synchronized world/model pose. After the owned stroke and bounded separation it records that resolved pose for the next movement check. The existing displacement limit, live-host binding, completion receipt, distance, speed, roll, balance and source stroke math remain unchanged.

The same defect also affected capsize retries. The controlled retry now sets the source heading first and uses the same full-hull safe placement as ordinary world entry. A collision still stops into-surface motion, preserves heading, and does not itself capsize the boat. A subsequent away-going stroke remains usable.

Source reference: `src/scenes/rpg/QizhenLakeScene.ts` uses the same 83 × 67 rotated Arcade body and physical collider separation; `updateKayakMotion`/`stopKayakAtBoundary` preserve heading and roll. No source asset, map, collision rectangle, story, save schema or difficulty setting changes.

## Validation

- Unchanged-runtime diagnostic reproduces the first-stroke cancellation
- 872 focused checks advance real world frames between strokes, including forward/reverse first strokes, dock contact and escape, the original failed-save position, four-stroke tutorial, same-side capsize/retry, fresh host binding and forged-position rejection
- Existing lake geometry, live source differential, actual shell-input, reload-boundary and branch/save suites pass
- Additional shared world, player metrics, portrait, object picking and chapter geometry checks are recorded in the review manifest
- Final combined production parse: 333 scripts, no failures; the scratch diagnostic is excluded
- Fresh Linux export, packaged Chapter 1–4 campaign, native-only first/reload and both focused tests against the PCK pass; Windows is not rebuilt for this follow-up
- Actual ordinary failed save, with no field edits: reverse contact succeeds, the next forward stroke moves away, four same-side strokes still capsize, safe retry works, then four actual alternating strokes at 430 px reach open water
- Normal Save, close and ordinary reload preserve the earned open-water result; another actual paddle stroke is accepted and Qizhen/item facts remain equal

The final standalone Linux export also accepts the original reverse/forward failure case, reaches open water at 430 px, saves and closes normally. Its capsize/retry and story reload are covered by the earlier exact-source replay; they were not repeated in this final GUI run.

The actual replay used cloud keyboard/pointer input and Dummy audio. It does not establish physical touchscreen or hearing acceptance. The pre-existing clipped portrait kayak HUD, mouse-only use of the drawn touch paddles, and phone-to-world focus/Tasks return costs remain separate. No broad lake-art or rain-film claim is made.
