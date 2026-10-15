# Phone tower alignment restoration

## Cause and bounded repair

The presentation's later mechanism recordings reused the old native home drawing. The earlier straight-tower UI reference had a centred portal and frontal stairs. PR83 fixed the disabled tower-button mask, gear-only motion and available-app layout, but deliberately left the tower artwork unchanged. Replacing a still with that later recording therefore brought the old geometry back.

This patch restores the structural geometry visible in the historical `phone-ui-v4-430x860-tower.png` and `phone-ui-v4-390x844-tower.png` reference captures. It does not claim recovery of the exact earlier source commit.

- Cap, upper chamber, shaft, portal and stair support share the existing clock/key axis x325
- Draw the shaft first, then the complete foreground portal; the shaft no longer paints over the doorway
- Replace diagonal detached treads with horizontal, widening steps and continuous risers into the plinth
- Retain original colours, window-strip shading, foliage and bonsai artwork

Only `scripts/ui/phone_home_art.gd` changes production behaviour. No controller, phone page, input region, key transform, timer, app order, gear or reward code changes. The transparent button states and complete solid-nine pickup from PR83 remain intact.

## Verification on b1177e10 plus this patch

- New tower geometry/order regression: 39 checks, zero failures
- Existing phone mechanism suite: 6806 checks, zero failures, including 117 checkpoint layouts, 390×844 / 430×860 / 1180×812, wrong-item and duplicate inputs, actual emulated drags, save/reload and rewards
- Phone pages: 30 layouts, zero failures
- Phone effects: four timed sequences, zero failures
- Phone navigation: 197 checks, zero failures
- Phone chrome: 60 checks, zero failures
- Loading/notice layout: 170 checks, zero failures
- Phone utilities: 42 checks, zero failures
- Independent review reran the 39 / 30 / 6806 focused checks against the frozen production source hash

Actual Linux Godot 4.6.3 CUA operation was also recorded at a complete 430×860 phone viewport: inventory key drag, insertion/rotation, fertilizer receipt, source-controlled gear rotation/fall, complete-nine pickup and digit 9 receipt. Both phone-home media segments were recaptured so the composite cannot alternate between old and restored tower geometry. The prior full-screen bonsai sequence was retained. These are isolated prepared checkpoint fixtures, not a fresh full campaign or physical-phone/Windows verification.

Production artwork SHA256: `9df6451a19edd4fcc00583b59112955fa2afc87bcb744e90b4fab76e204a7f7c`.
