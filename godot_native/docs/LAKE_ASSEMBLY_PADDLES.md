# Lake assembly and independent paddles

Base: `913bd512`, native Godot 4.6.3. Presentation-only addition.

## Four-part assembly

The original `C3Lake.combine_items` still validates and consumes exactly `nylonCord`, `brokenNetFrame`, `swanMagnet`, and `fishingRod`, then grants `magneticFishingRod` and advances to the existing `paper_capture` phase. Only an accepted result emits the new view cue. No net, feed, or fish prerequisite was added.

The revised 7.2-second close-up shows the frame socket meeting the rod tip, three rope turns tightening around that joint, the magnetic clasp seating on the frame rim, a tug and settle, then a uniformly scaled stow. Rod, frame, rope, clasp and articulated hands are separate native Node3D hierarchies with owned meshes, named contact markers and independent transforms. A cloud-web generated transparent reference informed the four original identities and material details. Hands follow physical component anchors, including smooth transfer between grips. The camera closes in during wrapping and magnetic contact, then widens for the pull-test. The view uses the existing native shell over either phone or world without changing scenes.

The transaction precedes the cue. The view has no completion action and cannot change inventory, rewards, story, or saves. Escape, focus loss, cancellation, scene reset, and reload retire the transient view. The saved result remains complete. Reduced motion uses the settled assembly pose for 1.1 seconds. Background movement/input is paused by the existing world-effect lock.

## Kayak layers

`hull.svg` and `seated_player.svg` are literal layer extraction from `src/assets/rpg/qizhen/source/kayak_overhead_frame_a.svg`. Both retain the original 128×160 viewBox and share the original uniform `.52` render scale. Arm and paddle geometry uses the same source palette, pivot positions, wooden willow blade, and triangular warning-sign identity. No whole-boat two-frame flip or anisotropic scaling drives a stroke.

The hull, seated player, left/right arm rigs, left/right paddle rigs and wake are independently addressable native nodes in packed scenes. Shoulder/elbow/grip pivots and explicit scene ordering preserve contact and foreground occlusion. Each side samples its own latest immutable `kayak_model.inputs` event against the existing 120 Hz tick. A 680 ms stroke has entry, pull, exit, and recovery poses. The reverse flag reverses the blade sweep; left willow flex is local to the shaft and the right sign stays rigid. Hands meet the exact shaft grip coordinate. Each blade creates its own wet contact line and exit droplets. Hull/body roll follows existing model roll. Original forward/reverse wake formulas and dramatic capsize presentation parameters remain supported.

`games/kayak_model.gd`, input routing, physics, collision, tutorial, and controller settlement are unchanged. Rehydrated models have no recorded stroke and render neutral paddles. Two overlapping strokes remain independent; an opposite-side stroke cannot reset the first side.

## Validation and preview

- `tests/test_lake_assembly_paddles.gd`: deterministic phase/contact, no-write, original-art bounds, four-part transaction and overlapping/reverse stroke checks
- `tests/test_lake_assembly_shell.gd`: actual native shell at 390×844 and 1180×812, phone/world origins, input lock, cancellation, duplicate attempts and real export/import during presentation
- `tests/preview_lake_animation_stage.gd`: split-screen native-renderer reel of assembly and actual model-driven paddle poses; separate from manual input acceptance
- `tests/preview_lake_assembly_paddles.gd`: isolated actual-game preview. A/D paddle, S reverses, F6 repeats assembly, F12 captures. Requires `/tmp` XDG_DATA_HOME. `-- --capture` writes actual rendered key-pose frames to `.screenshots/lake_assembly_paddles`; fixed-time capture is visual evidence, not a claim of manual input verification

These are articulated runtime poses and derived original vector layers, not a claim of 24 hand-drawn frames. Full campaign and physical mobile-device acceptance remain separate from focused native checks.

### Initial revision verified 2026-10-11

Native Godot import/parse passed. Focused results: animation/contact 96, actual shell lifecycle 44, lake branch/source parity 416 with 25 disk saves, live-world/source differential 4,370, hull rotation/collision 872, original inventory drag 64, paddle pointer 32, failure body 48, fixed-step guard 61, rain rescue 17; each had zero failures. Existing lake reload-boundary regression also passed.

Actual graphical native-shell review verified A/D forward motion, S+A/D reverse motion and bow wake, source-scene rendering, and F6 assembly followed by Escape then a successful new paddle input. Two real-render capture passes reviewed the frame, rope, clasp, tug, and stow. A visible hand-to-joint gap found during review was corrected and recaptured. The final graphical capture and interactive logs contain no script/runtime errors; the cloud driver reports its pre-existing unsupported VSync warning. The 8-second split reel is a native-renderer close-up of the same animation code, not a substituted game runtime or a full-campaign acceptance claim.

### Native-object revision

See `LAKE_ASSEMBLY_PARTS_3D.md` and `KAYAK_NATIVE_OBJECT_RIG.md` for object ownership, anchors and node APIs. The assembly uses an isolated SubViewport with actual depth/occlusion. The cord is a progressively revealed braided tube with 3.35 turns and a tightening knot, not a scaled icon. The accepted controller transaction and original kayak model remain authoritative.

Revised focused coverage includes 899 geometry/ownership/physical-pole-contact checks, 97 live assembly contact/lifecycle/alpha checks, 95 motion/controller checks, 44 shell/save/interruption checks, 699 kayak-node checks, 19 rain-node checks and the existing fixed-step/contact/rescue regressions. The final native graphical pass inspected all assembly phases and all forward/reverse paddle poses. It corrected forearm occlusion, reel/net tabletop clipping and true pole-to-rim contact (both sole centers are tested against actual rim triangles). Real A/D, S+A/D and F6→Escape→A inputs produced the expected original model events. Final renderer logs contain no script/runtime errors; the cloud driver retains its unsupported VSync warning. An 8-second native-renderer clip was captured for user review. Existing live-world 4,370-check, pointer 32-check, failure 48-check and reload-boundary suites also passed. Full remote aggregate CI remains a separate gate, and no physical mobile or full campaign acceptance is claimed.
