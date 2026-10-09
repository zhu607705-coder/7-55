# Native phone mechanism feedback repair

Local candidate based on `93c21feeaa9c8699b40c952c1184a9fd5d49d472`.
This work is intentionally not published to GitHub while publication is paused.

## Verified original problems

The actual v7 tower and gear videos reproduce the base implementation:

- TowerDropTarget becomes disabled during the existing key sequence. Its disabled theme style was not overridden, so an opaque default Button panel covered the original tower artwork
- Auto-rotation transformed the complete Settings Button, including its square frame and hit area
- Unavailable applications consumed grid positions and rendered literal `xxx` labels
- The fallen reward was a rounded button containing `✱ 9`, with a different location from the ending gear animation

The digit request refers to that fallen reward. CC98 is unchanged.

## Bounded implementation

`phone_pages.gd` now provides transparent normal, hover, pressed, hover-pressed,
disabled and focus styles for the existing artwork-backed drop control.
The existing `phone_home_art.gd` tower drawing is byte-unchanged. The key still
inserts, turns, and only then submits the original 1700 ms completion intent.
The original controller consumes the key and grants fertilizer once.

The original gear glyph is an input-transparent object separate from the fixed
Settings frame, label and activation area. After theme inheritance, its actual
font rectangle is centered on the frame. Its endpoint and the later digit
pickup use one shared rectangle. A 64×88 pickup contains the original pixel
font's 85 px minimum height at size 56; its only visible content is a complete,
high-contrast `9`, without a star, outline, badge or background. Pointer and
keyboard activation still submit `c1_collect_gear` to the original controller.

Home layouts filter unavailable apps before allocating grid positions. Hidden
apps are omitted only under the existing removal rule. Compact arrow-key
navigation translates the visible neighbor back to its full saved-order index;
unavailable IDs keep their original saved slots and no availability fact changes.

No changes to Chapter 1/2 controllers, eligibility utilities, save schema,
original artwork/assets, CC98, or the independent fishing-depth candidate.

## Verification boundaries

- Focused suite: 6806 assertions, zero failures, across all 117 source checkpoints
- Real Main mouse/key/drag emulation at 390×844, 430×860 and 1180×812
- Themed gear origin/endpoint, fixed frame, full digit bounds, real pickup,
  all transparent states, duplicate input, one tower receipt, compact ordering,
  hidden/restored apps, corpus immutability and actual save/reload
- Existing utility suite: 42 assertions; existing phone-effect suite: four timed
  sequences; both pass
- Actual cloud native operation verifies a real inventory key drag, unchanged
  tower art during the sequence, and the fertilizer result. The digit's real
  pointer pickup also records `digits.d3=9`. The final dark-digit version is
  being re-recorded through the ordinary native controls

These are isolated source-state fixtures. They are not a fresh full campaign,
Windows execution, or physical-phone testing. Native source modifications and
new demo footage are separate from the paused GitHub publication workflow.
