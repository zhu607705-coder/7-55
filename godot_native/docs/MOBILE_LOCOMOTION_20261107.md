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
