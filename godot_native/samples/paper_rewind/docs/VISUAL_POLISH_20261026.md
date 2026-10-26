# Object-scene polish — preview, not formal-story integration

Starting evidence: the corrected 398540b preview has visible first contact, a
history window parked outside the trajectory, and explicit collection. The
user accepted the idea provisionally but found the scene visually crude.

## Bounded changes

- One active visual subject: remove duplicate sheet wireframe/connector, nested
  history rims/scanning lines, decorative notebook and dense wood lines.
- Warm paper/folder remain physical; blue-grey is reserved for recorded history;
  cream is the interaction cue. Neutral touch markers belong to the recording,
  not to the game state. Settings/help stay secondary.
- A short local trail and one small directional cue remain visible outside the
  thumb. No main-screen status narration or completion popup.
- Grip compression takes 120 ms, relaxes in 220 ms, without bounce. A dragged
  folder follows its owning hand quickly; a released cover settles over 560 ms.
  Model-owned landing keeps its existing 1.05 s path; shadow/angle settle onto
  the actual accepting page. Collection lifts first, then carries away over
  880 ms. None of these animations creates progression.
- Horizontal leftward cover pull matches the long-spine hinge. Releasing on the
  opened leaf is valid. System cancellation, outside-screen release and focus
  loss never commit the preview. Tap/upward fallback remains available.
- Existing campus tree artwork is sampled as an isotropic, low-contrast window
  view. Source pixels are unchanged; its selected crop contains no magenta key.
- Folder art is replaceable as separate cover/inner/base faces. Textures use the
  existing physical A4 rectangles, front pocket and hinge; hit/catch geometry
  stays unchanged. Source-art review and rendered review are separate gates.

## Evidence boundary

Focused headless tests cover model, ordinary input/geometry, two-hand ownership
and cancellation, and presentation-only animation state. Actual history pixel
clipping (including a negative control) and the six-step two-touch movie are
verified separately on the supported hosted GL renderer. Neither headless tests
nor automated touch movies are physical-phone acceptance or final-art approval.

Original PR180 is held until actual preview frames have been reviewed. No Main,
controller, formal item/proof/save, deployment, merge or review request changes.
