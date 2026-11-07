# Mobile locomotion and direct interaction

## Scope

Restore the user-requested movement-only analog joystick inside the existing
playfield. Keep direct floor taps and automatic physical approach to distant
objects. There is no interaction-confirmation button and no persistent tutorial.
The canonical world size, camera projection, chapter gates, collision geometry,
inventory ownership and save/controller authority are unchanged.

The stick has a visible ring, four direction marks and a displaced thumb cap.
Its outer diameter is 104 display pixels where space permits, with an 8-pixel
playfield inset. It shrinks only to fit the actual safe playfield. Layout tests
cover 390×844,430×860,844×390 and568×320, including simulated safe-area insets.
Its passive Control draws above scene objects and does not capture GUI input.
World input uses the same circular bounds that are painted.

## Ownership and movement

- One touch owns the stick. A radial 15% deadzone ramps continuously to full
  movement. The existing collision-resolved movement code consumes the axis;
  keyboard and automatic route speeds retain their original behavior.
- The stick's geometry remains fixed during its gesture. Camera follow cannot
  retire its owner. New scene fingers during the hold are ignored, including
  their late drag/release after the stick owner lifts. Inventory and modal
  controls still take priority. Release the stick to pan or pinch the map.
- Acquisition cancels the previous automatic route and pending interaction.
  Release cannot restart them. A fresh map/object tap works immediately.
- Outside-viewport release, browser touch cancellation, window/application
  focus loss, resize, scene/state replacement, inventory and modal ownership
  neutralize movement. Emulated mouse events do not duplicate touch actions.
- Kayaks keep their original paddle gestures, without a locomotion stick.
  The pre-installation dorm movement gate does not expose the stick.

## Verification and limitations

Base: 8e442ee5a46b347ac09130a3f270f1eadc15d392. Tests run against the working
patch with official Godot 4.7.1.stable.official.a13da4feb, in disposable Linux
user-data directories. Source sync and independent asset import completed.
The focused native results are recorded in progress.md. They include root-routed
input, safe geometry, character/shadow separation from controls, direct approach,
collision-preserving paths, ordinary input interruption and unchanged kayak input.

The Web read-only snapshot reports the real stick center, rectangle and owner.
The existing direct-world browser case now also tests stick movement/release,
touchCancel, held-modal and held-orientation cancellation at its configured DPRs.
It retains the current distant-tap approach case instead of selecting the retired
no-approach branch. These browser additions have syntax/runner-unit coverage but
have not been executed here against a graphical Web export.

Design review follows the repository's existing object-first UI direction,
Impeccable 4.8.0 craft floor/adaptation references and Godot 4.7 UI/input guidance.
This is a narrow existing-surface refinement, not a visual redesign. No raster
asset or new dependency was introduced. Native graphical capture is unavailable
in this environment; the capture fixture is only layout/input validation here.
Full native validation, actual WebGL rendering, physical phones, thumb comfort
and device-specific safe-area behavior remain separate acceptance gates.

## Room204 overlap and native drag follow-up

The actual Web checks for the initial patch passed separately. Native CI then
found that the old Room204 fixture selected a furniture point underneath the
newly painted stick. In the 390×844 fixture, the map is first rotated to 844×390.
Its local world remains 960×540: the stick rectangle is approximately
(11.27,238.40,146.57,146.57), with center (84.56,311.69) and radius 73.28.
The authored source (78,618) projects to (66.30,253.03), inside that circle.
This is a real but recoverable overlap, not evidence that the object is always
visible or that the fixture's old gesture-area check excluded painted controls.

The fixture now excludes the actual stick circle when selecting a clear source
and drop target. A separate regression deliberately retains the original
obstruction. It presses and drags from the covered source, then releases over
its matching target: no furniture drag or controller action may occur. It then
uses ordinary root touch input at world-local (720,150), dragging upward 65
display pixels, to reveal the source outside the stick. The observed source
moves to approximately(66.30,121.70). A real touch furniture drag then submits
exactly one original controller action and places exactly three pieces. A late
release cannot submit again. No direct camera or puzzle-state setter performs
the recovery. World processing is paused in this geometry/gesture fixture;
unchanged feet here is not a live held-stick movement measurement.

This new test exposed an actual second input route: Godot's touch-emulated
mouse could request native GUI drag data despite the stick owning the touch.
The reverse order also allowed a second finger to acquire the stick while a
furniture drag was already held. Narrow acquisition guards now reject both
competing owners. An existing furniture preview and its original release stay
active when the second stick finger presses and releases. Existing desktop and
mobile furniture drag regressions remain required, alongside the 541-check
root-touch suite and 139-check direct-world suite. The stick does not jump to a
different corner, and hidden furniture does not receive input through it.

On the final guarded patch, official Godot 4.7.1 in isolated headless profiles
passes Room204 mobile drag 186, root touch 541, furniture drag motion 436, native
objects 1317, residual target 23, second table 870 and direct-world interaction 139
checks, all with zero failures. These are focused native results; they do not
replace the new exact-commit CI, graphical Web or physical-device gates.

## Integration with main UI revision #233

The combined base `3d2b55f` retains #233's display-pixel world backing, paper
interaction styling, right-hand tool row and story-owned mode unlock. Its first
combined mobile run found a real paper/stick overlap, not a coordinate-only
failure. At 390×844, the displayed stick was (11,322,98,98) and the paper was
(49.08,401,291.84,63); three heading glyphs crossed the stick. The short 568×320
layout also crossed it. The bottom tools remained separate.

The selected paper now receives the actual painted stick rectangle as a
presentation-only exclusion. Only when its normal centred rectangle intersects
that exclusion does it use the remaining right-hand area, with an 8-pixel gap
and normal text wrapping. Both immediate layout and deferred container
settlement apply the same rule. Paper style, fonts, bottom anchor and pointer
pass-through are unchanged. The measured 390-wide paper becomes (117,401,262,63);
the 844-wide paper remains centred at (212,255,420,63). The native test relaxes
horizontal centring only for this reserved lane. Complete paper, glyph/shadow,
safe-area and tool-clearance assertions are retained or strengthened.

A presentation-only long-title fixture uses an ordinary object tap first, then
applies long display copy after source targets refresh. It checks every glyph,
extra-frame layout stability and ordinary touch access to the journal at 390×844,
568×320 and 844×390. It does not inject a controller result. Graphical and physical
phone acceptance remain separate from these native layout/input checks.
