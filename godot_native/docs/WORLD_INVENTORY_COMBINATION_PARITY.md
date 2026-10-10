# World inventory uses the existing item recipes

In an actual earned lake save, the cord and broken-frame descriptions suggested
using the parts together. Dropping the cord on the frame in the world inventory
reported that nothing usable was hit. The same physical drop in the phone drawer
correctly reached the original recipe and explained that four parts were required.
No parts were consumed in either attempt.

The world row used the shared drag-source button without an item drop target.
Its new small subclass accepts another owned inventory item within the visible
button bounds and emits the same combination request as the existing phone drawer.
Main checks current world visibility, ownership and its existing modal, story,
activity and capture guards before calling the unchanged recipe handler.

This restores a missing input route. It does not make the two-part cord/frame pair
a valid recipe, add an answer, grant missing parts, change any recipe or replace art.
The original controller still accepts or refuses each action and owns consumption.
Native drag dispatch remains the sole release path; the shared touch/mouse gesture
implementation is unchanged. Surface changes, hiding, resizing, focus loss and
Escape still cancel the existing source gesture.

## Evidence boundaries

- An unchanged earned net-frame reload save was used for the actual desktop
  comparison. Before, the world row gave its generic missed-target message; after,
  the same drag gives the original four-part refusal directly in the world. Normal
  Save/close preserves every item and lake fact.
- A separate preceding current-runtime fishing attempt failed 0/8. Its Retry,
  count-in Pause and Exit returned safely. The crafting comparison uses the prior
  actually earned net-frame checkpoint and is not presented as a new catch from
  that failed attempt. The old successful checkpoint involved source/Pause
  assistance and does not establish uninterrupted skill or hearing acceptance.
- The initial root-pointer regression failed 15 of 48 checks before the repair and
  passed all 48 after. The strengthened test passes 64 checks at 390, 430 and desktop,
  covering both refusal and an accepted original bait recipe, one dispatch,
  retained/consumed items, duplicate release, target bounds, malformed/unowned/self
  payloads, disabled targets, focus/resize/Tasks/surface cancellation and synthetic
  touch followed by an emulated mouse release.
- Synthetic touch events do not establish physical finger-hardware acceptance.
  Current desktop evidence uses actual mouse input. Dummy audio is used in these
  GUI runs, so no PCM or subjective listening claim is made.

Nine affected serial tests pass, including the existing phone/compact inventory,
touch ownership, focus, C3 narrative and lake checks. A fresh official Godot4.6.3
Linux export completed in13.4s; the packed combination regression also passes64/0.
The exported game actually reloads the checked save at430×860. After opening and
horizontally scrolling the bag, the same physical drop reaches the original recipe.
An OS resize to390×846 and another actual drop also pass. Normal Save/close exits
zero and preserves all item/lake facts. Exact390×844 remains automated coverage;
the physical resize was390×846. Accepted-recipe consumption and synthetic touch
are automated coverage here; the actual earned-copy comparison intentionally tests
the incomplete source recipe and does not invent the missing fourth material.

The focused release evidence records exact input/package hashes. Main campaign
progress and formal acceptance counts remain unchanged.
