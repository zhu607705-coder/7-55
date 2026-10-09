# Design-book anchor03: collectible weather drop

Original catalogue: `7-55-animation-design-book.pdf`, Library
`libfile_d43f28f086c08191bea643826c3d3bf8`, v1, page6. One anchor.

The actual `HomeLiveWaterDrop` still calls `c1_rain_drop`. The original
controller immediately commits `waterDropTaken=true` and `items.waterDrop=true`.
Only that accepted rising edge starts the340ms copy of its8×14 authored blue
shape. Other rain marks and the cloud/phone plate remain stationary.

At0ms the top-anchored drop is0.88×1.18. At120ms it falls18 logical pixels,
compresses1.32×0.58 and emits two4px contact ripples. At260ms it becomes the
existing `PhoneChrome.PIXEL_ICONS.waterDrop` silhouette and clears by340ms.
Its original source/hotspot is gone immediately after acceptance; it never
looks like an additional collectible and never grants another item.

## Verified geometry adaptation

The original catalogue assumes a nearby visible item slot. In the real
starting layout, the inventory is closed and often empty before this first
item. The newly visible backpack receipt is about150px from the source; a
full flight there would violate the catalogue's60px limit. The implementation
therefore does not invent a target or open a drawer without input:

- A real visible waterDrop slot within60px receives the bounded short arc
- A hidden or distant slot uses the local18px fall/recovery/fade, accompanied
  by the already-updated real backpack count/item receipt
- Visible-slot positions are sampled after the existing Container layout pass
- Only this water item's old generic acquisition VFX is replaced; other item
  receipts, inventory state, ownership, counts and input remain unchanged

The parent accepted this geometry-dependent branch on2026-10-09. Tests verify
both branches and the maximum measured Bezier arc length. No invisible target
is used. Reduced motion has a stationary standard silhouette without squashing,
travel or ripples; authoritative item/count feedback remains the same.

The existing18_ rising-edge sound route is byte-unchanged. The new layer adds
no sound, voice, state field, proof callback or transaction delay.

`test_phone_anchor03_water.gd`:379 passing checks at390×844,430×860,1180×812,
including mouse/synthetic touch, nearby/open/distant/closed inventory layouts,
repeat/early rejection, continued input, modal/state/rebuild cancellation and
ordinary disk save/reload. Source c1-code-hunt fixture, with explicitly set
inventory layout preferences for geometric branch tests. Actual cloud Linux mouse operation now passes at1180×812,430×860 and390×844
for the ordinary closed-inventory branch: the live source disappears and the
real backpack immediately shows one item. Timestamped frame sequences and
three clips preserve the observed acquisition frame intervals. The nearby
open-slot branch is covered by automated native-input tests, not the actual
mouse captures. Physical-phone/hearing acceptance remains unverified.
