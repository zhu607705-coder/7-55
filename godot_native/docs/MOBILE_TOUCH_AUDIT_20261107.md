# Mobile touch audit

## Evidence boundary

The deployed source examined was `8e442ee5a46b347ac09130a3f270f1eadc15d392`.
Its [Web acceptance run](https://github.com/zhu607705-coder/7-55/actions/runs/42364604566)
contains ordinary-touch inputs, engine observations and PNG captures, not only
test status. The inspected standard/Retina world, phone-recovery and library
artifacts all identify this source and Godot 4.7.1. Screenshot SHA-256 values
were checked against their acceptance receipts.

These are Chromium touch emulation results. They are not physical iPhone or
Android testing. The cloud interactive browser could not initialize WebGL 2;
no successful fresh manual campaign or physical thumb-comfort result is claimed.

## Reproduced problems and focused changes

| Finding | Deployed evidence | Candidate change |
| --- | --- | --- |
| Requested joystick absent | Real engine snapshot reports `stick: null`; source and native test explicitly omit it | A visible, movement-only analog stick inside the playfield, alongside direct taps and automatic approach |
| Library rule too small in portrait | At 390×844, the fixed spread is about 390×219; body is about 8.5 CSS px and close target about 18.7 px high | Compact reflow with 18px body and 48px close target; desktop spread retained |

The joystick does not add a confirmation button. It preserves original movement,
collision, inventory, scene and controller authority. One finger owns the stick;
release, cancellation, modal interruption, focus loss and rotation stop movement.
Another map finger cannot queue an accidental object tap during the hold.

The document preserves authored text and existing read/record actions. A resize
preserves scroll position without treating a layout change as reading the end.

## What the deployed touch evidence establishes

- Distant-object input reaches the actual lamp picker, walks from about 248 to
  60 source units away, then submits exactly one original action in range.
- Dragging out and back is not a tap. Touch cancellation clears ownership and
  movement. Inventory and modal interactions retain their own input priority.
- The canvas fits 390×844 at DPR 1 and 3 without document overflow. Landscape
  844×390 and phone/world round trips preserve state.
- Ordinary library swipes and close/save/reload work. This did not make the
  original 8.5px text readable; the screenshot was reviewed separately.

## Candidate verification

The implementation notes list focused Godot 4.7.1 tests for
[locomotion](MOBILE_LOCOMOTION_20261107.md) and
[library reading](LIBRARY_MOBILE_READING_20261107.md).
The Web runner now exercises real touch movement/release, touchCancel, held
modal and rotation interruption, and measures the close target in CSS pixels.
Exact-candidate Web execution and new screenshot review are separate gates;
adding these assertions alone is not a passed result.

Physical thumb reach, hand obstruction, edge gestures, device safe areas, mobile
Safari behavior, thermal performance and a full four-chapter touch playthrough
remain unverified. No merge or deployment is part of this audit.
