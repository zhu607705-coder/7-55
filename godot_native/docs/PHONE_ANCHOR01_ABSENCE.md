# Design-book anchor01: absence zero

Original catalogue: `7-55-animation-design-book.pdf`, Library
`libfile_d43f28f086c08191bea643826c3d3bf8`, v1, page4. This is one anchor.

The actual `CheckinAbsenceZero` button and `c1_absence` controller action remain
the only input/transaction path. Main records the old visible glyph before
calling the action. The new presentation starts only after the matching
`cardZeroTaken` false→true result also contains `digits.d1=0`. The action,
autosave and next input are never delayed by the 360ms drawing.

The source25×25 frame never moves. A read-only glyph compresses at its bottom
contact, lifts6px/8degrees at110ms, follows a bounded-bend arc to the actual
visible first clue digit at280ms, and settles by360ms. The old record remains
a gray0 with a2px pale imprint. PhoneChrome supplies the destination from the
live rendered label and font metrics, rather than a guessed viewport position.

The layer owns no reward/proof/audio callbacks. It clears on next input,
page/rebuild, state replacement, modal/world ownership and reset. Ordinary
reload restores the gray0 and the top clue directly, with no replay. Reduced
motion presents the accepted clue statically. No transient fields enter saves.

The actual original source function uses `playSfx("11_")`, whose existing
catalogue asset is `11_p04_campus_card_balance_zero_click`. Native audio now
uses that once on the exact accepted action edge. The design book's optional
10_ suggestion is not substituted for this verified source call.

Verification: `test_phone_anchor01_absence.gd` passes298 checks with real Main
mouse and synthetic native touch input at390×844,430×860,1180×812, including
rejection, repeat, typed-digit separation, interruption and disk save/reload.
The fixture is the original `c1-code-hunt` snapshot, not an earned fresh
campaign. Actual cloud Linux mouse operation now passes at1180×812,430×860 and390×844.
A first capture revealed the success toast masking part of the flight. The
digit-only layer was raised above that toast, then all three layouts were
replayed with actual clicks and timestamped frames. Modal, Control Center and
phone-document interruption still clear the copy. Exact numerical poses are
automated evidence; screenshot names do not certify exact rendered phases.
Physical-phone and listening acceptance remain unverified.
