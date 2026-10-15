# Lake entry heading and full-hull placement

Entering the channel from open water could immediately cancel the live kayak
session. The ordinary campaign reproduced the failure twice: the channel appeared,
the boat reported an invalid position, and forward/reverse strokes did nothing.
The return portal still worked.

`world.gd` previously found a safe center before creating the kayak model. At that
point `can_stand()` used the destination zone's default heading (west for the
channel). It then created the model using the actual portal entry heading (north).
The rotated hull was taller than the hull used for placement.

The recorded center was `(828, 734.215393)`. Its north-facing 67 × 83 bounding body
extended to y=775.715393, overlapping the unchanged south bank starting at y=770
by 5.715393 source pixels. The live proof correctly rejected that pose.

The fix initializes the model and authored entry heading before the existing safe
placement search. Model position and safe/player position are assigned together
after the search. The same entry now resolves locally to approximately
`(824, 727.2872)` and remains valid on subsequent frames.

This retains the original 83 × 67 hull, entry definitions, zone art, collisions,
water areas, movement model, capsize rules, reward checks and live-session guards.
Source `QizhenLakeScene.ts` chooses the from-zone spawn in `getSpawn()` and applies
its heading in `rebuildZone()`; `syncKayakCollisionBody()` derives both body axes
from that heading. This change makes native placement use that same actual pose.

## Validation

- New entry regression: 48 checks; the unmodified runtime fails 5, the fix passes
  all 48. It covers every authored kayak entry into open water, channel and swan
  cove, real frame advancement, forward/reverse movement, renewed session ownership,
  and the saved failed center. These are isolated fixtures, not manual progress.
- Main-shell entry regression: 17 checks. The old <30-pixel center-distance
  assertion accepted the invalid heading-dependent body. It now also requires a
  legal full hull within 40 pixels and a running owner after actual frames.
- Existing kayak rotation contact: 872 checks; live lake source differential:
  4,370 checks; ordinary lake reload boundary: zero failures; complete production
  script graph: 335 scripts, zero failures.
- Actual ordinary-save retest: the unchanged failed main save was reopened, paddled
  to Return, and taken through open-water → channel again. Two forward strokes
  left the formerly blocked bank. A real rod drag opened the broken-net-frame
  fishing activity. Exit returned to the boat; reverse and forward movement worked.
  All Qizhen and inventory facts remained identical after normal Save/close.

The actual retest used desktop keyboard/mouse at 1180 × 812 with Dummy audio.
It did not start or win the net-frame chart. No physical-touch, hearing, full mobile
playthrough or browser-pixel-equivalence claim follows from it. Ordinary reload
uses the source safe checkpoint rather than restoring an exact mid-water pose.
The pre-existing need to focus the world after reload or activity Exit remains a
separate issue. Reflection-versus-catch-zone guidance is also outside this change.

Fresh Linux export and the complete packed Chapter 1–4 automated campaign passed.
Disk exhaustion then stopped setup of the remaining checks. After deduplicating
verified identical generated executable bytes, that same pack passed native-only
first/reload and all 48 focused checks. This is a reconciled gate, not an
uninterrupted run. The final standalone executable also passed the ordinary failed
save-copy → Return → reentry → paddle-away → Save/close route at 1180 × 812, with
all Qizhen and inventory facts unchanged. This focused change does not claim a new
full aggregate test sweep or Windows execution.
