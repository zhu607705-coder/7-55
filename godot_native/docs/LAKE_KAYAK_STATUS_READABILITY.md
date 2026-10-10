# Readable kayak status on narrow views

The original native kayak overlay put the complete keyboard and touch instructions,
movement mode and tilt on one fixed-width line. In the actual 390px replay the
line clipped at the viewport edge. Pursuit labels and progress used additional
fixed coordinates, which could overlap on short or narrow views.

The status now sits below the existing lake header in a measured dark panel.
Ordinary travel shows only the changing movement mode, tilt and existing capsize
warning. The original controls remain in the bottom hint and phone instructions.
Pursuit phase, danger, distance and segment progress use one or more measured rows;
wrapping prefers the existing phrase separators, retaining complete phrases such
as `追击距离 104`. The text has a 14 physical pixel minimum. The original font,
warning colors, risk values and reduced-motion behavior remain in use.

This is a read-only drawing change. All session code before `draw_status` is
byte-identical to the prior commit except for its new renderer preload. No input
target, paddle threshold, world camera, boat collision, simulation, proof guard,
story fact, source image or difficulty value changes.

## Verification

- The focused layout regression checks original movement, tilt, phase, danger and
  segment strings across seven viewport/scale contracts, including an expanded
  landscape bag. It verifies measured bounds, full phrases, no ellipsis, physical
  type size, row separation, risk-bar placement and paddle clearance: 7,251 checks,
  zero failures.
- Six serial affected tests pass: layout, lake live world, accumulated frame-time
  guard, paddle pointer ownership, lake shell input and mobile world feedback.
  No unrelated full suite was repeated for this presentation-only change.
- An unchanged earned channel save was actually replayed at 390×844. Physical
  downward paddle drags showed the complete reverse/tilt status. Expanded bag and
  desktop resize remained readable. Ordinary Save/close exited normally; inventory
  and lake facts match the input copy.
- Five separate frozen source-state visual fixtures cover pursuit critical text
  at 390×844, 430×860, 844×390, 844×390 with the bag open, and 1180×812. They exercise
  rendering only and are not an earned pursuit win or real finger-input test.

Initial layout-test failures were an empty-string assertion mistake, then corrected
without changing the renderer. Initial visual fixtures also exposed a phrase split
inside the distance label; phrase-aware wrapping was added and the regression and
all five native frames were repeated. The first bag fixture had no inventory item;
the corrected fixture seeds one campus card so the actual bag layout is exercised.

Fresh Linux export completed in 10.82s with the official 4.6.3 release template.
The packed layout test also passed all 7,251 checks. The exported game loaded the
ordinary saved copy at 430×860, accepted visible paddle clicks, opened Tasks, then
returned correctly after an OS resize to 842×388. The bag-open status remained
readable, and physical downward paddle drags showed reverse/tilt feedback. Normal
Save/close exited zero and preserved all inventory and lake facts. A short keyboard
chord attempt showed no visible movement, so it is not counted as keyboard
acceptance; the successful physical mouse gesture is recorded separately.

Release evidence records the exact input and PCK hashes. Dummy audio is used here, so this slice makes no hearing or PCM
acceptance claim. The main earned campaign remains at its prior C4 checkpoint;
these C3 checks use separate copies and do not increase formal acceptance counts.
