# Restore the original boundary recovery hint

An actual open-water approach repeatedly stopped without an explanation. Backing
out still worked. Source review found that both versions intentionally stop boat
speed at a blocked edge, but the original also displays its authored reverse
instructions. Native World only reset position and speed.

The native stop now emits the exact `boarding.boundaryBlocked` content. Its display
duration is the original 2.2 seconds and its repeat cooldown is 2,400 milliseconds,
from `QizhenLakeScene.stopKayakAtBoundary`. The cooldown belongs to the transient
lake scene: changing zones retains it; leaving/re-entering the scene or importing
state resets it. Existing world/footer layout measures the complete paragraph.

No movement, hull, collision, navigation, timing/proof rule, item, artwork or
source wording changes. In particular, this does not add continuous sliding or
shrink a collider to make the route easier.

## Separate inherited geometry finding

The original `lily_piles` rectangle spans x=1020–1260, y=520–765. A real approach was
saved at (968.496,510.360); its rotated full hull contacts this coarse rectangle
while some water ahead appears visually open. This source-art/collision mismatch
remains a separate geometry task. Restoring feedback does not resolve it or claim
that every visible obstacle is independently modeled.

## Verification

- Initial focused regression: 8 checks, 3 expected failures for missing feedback,
  duration and cooldown owner. Initial repair: 14/0. Strengthened check: 23/0.
- The actual full-hull fixture still stops at the unchanged rectangle and leaves
  through an ordinary reverse step. The proof session and lake facts remain valid.
- Cooldown checks cover 2,399ms refusal, 2,400ms admission, same-time duplication,
  same-scene zone changes, scene/reset lifetime and 2.2s clear-water expiry.
- Original full text fits the compact footer at390/430 contracts without covering
  the visible paddle rectangles.
- Actual source candidate: normal reload of the saved approach uses the authored
  safe checkpoint/heading. Ordinary strokes meet the original island boundary and
  visibly show the instructions; S plus alternating strokes backs out. Normal
  Save/close retains all items and lake facts. This is not a forced replay of the
  exact pre-close boat heading or a seeded manual pose.

The preceding diagnostic route had one genuine capsize from four consecutive
same-side strokes. That is an input failure, not a balance defect. Its ordinary
recovery, and the separate silent-boundary observation, are retained in evidence.
GUI checks use Dummy audio and make no hearing/PCM or new catch/pursuit-win claim.
Main campaign and formal acceptance counts remain unchanged.

Eight affected serial scripts pass. A fresh official Godot4.6.3 Linux export
completed in12.86s, and the packed regression passes23/0. Actual exported430×860
and OS-resized390×846 both show the full original paragraph, retain visible
paddles, and allow physical downward mouse drags to back out. Ordinary Save/close
exits zero; all items/lake facts match the input copy. Exact390×844 and precise
cooldown/expiry boundaries are automated checks. No real finger or subjective
hearing claim is inferred. Release evidence retains exact inputs and package hashes.
