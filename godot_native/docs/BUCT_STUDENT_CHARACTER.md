# BUCT student visual for the Chaoyang pilot

This change is stacked on PR #120. The existing **朝阳步道 · 分层试点** entry opens the two-tree region with the shared student artwork. No new chooser entry is needed. The full-campus walk and Zhejiang story keep their previous actors and controllers.

## Registration and ownership

`campuses/buct_shared/student/scripts/registered_character_visual.gd` is a visual-only atlas player. It does not read input, choose routes, collide, move its parent, or write save state. `data/student-movement-profile.json` registers every accepted frame using its actual atlas region, local foot anchor, and common per-sheet reference height. Asset pixels are preserved. No assumption of equal sprite-sheet cells is required.

The pilot CharacterBody2D remains the movement authority. Its origin is the feet. Root scale is `(1,1)` and foot radius is `1.65`, exactly the former effective radius `3 × 0.55`. The visual is a separate child with a target height of 10 source-world pixels. The soft foot shadow is independent of body artwork; the diagnostic cyan ring is hidden by default. Sprite proportions, atlas bounds, and animation frame changes cannot alter the collision radius.

The pilot feeds **actual displacement after `move_and_slide()`** to the visual. Gait phase advances by distance, not elapsed render frames or attempted input. A wall, released button, paused scene, or stopped guide cannot keep walking in place. Reset and guide restart reset the pose before teleporting, so relocation does not count as walked distance. Facing follows motion; stopping keeps the last directional idle.

## Pace and navigation

Only this short 256×160 pilot uses **8 source-world pixels/second**, for both manual walking and its authored guide. This matches the accepted character preview's provisional stride. The existing full-campus route and original story speeds are unchanged. Shift retains the pilot's existing manual speed multiplier.

The existing direction buttons work with mouse and touch. WASD/arrows, guide, reset and return controls are unchanged. Releasing outside a button or losing focus stops movement and returns the visual to idle. Returning to the chooser during a guide frees the student visual, textures and scene-owned input actions. The same entry can be opened again without accumulating actors or writing saves.

The accepted asset set contains 10 unmodified RGBA PNGs: four directional idle poses, 8 right / 8 left / 8 down / 6 up genuine walking phases. Repeated source contact drawings were not counted as new phases. The exact hashes, original dimensions and adopted regions are recorded in `campuses/buct_shared/student/data/provenance.json`. Private generation conversation links and service-file identities are omitted from the public repository. Low-alpha exterior noise is discarded by the documented 0.04 shader cutoff; pixels above 0.95 alpha become solid, without rewriting any PNG.

The first walk artwork is an artistic student concept, not an official uniform or a named person. Registration and stride are visual estimates, not measured biomechanics. A renderer's frame count is distinct from the number of genuine artwork poses. Artwork acceptance and actual GUI review are recorded separately from synthetic mechanism tests.

## Safe verification

From the repository root on Linux, after the ordinary native asset synchronization/import:

```sh
node godot_native/tools/test_buct.mjs
node godot_native/tools/validate_native.mjs
```

These runners create fresh isolated user-data directories. Do not manually run the save-writing entry fixture against a personal profile. The fixture refuses undeclared, mismatched or preexisting save locations.

- `test_buct_student_visual.gd`: explicitly synthetic atlas/transform mechanism tests
- `test_buct_student_distance.gd`: equal-distance phase at 24/30/60/144/240/480 updates per second
- `test_buct_student_artwork.gd`: actual RGBA resources, four-direction publication gate, registered feet, native controller interruption/reset, visual cleanup
- `test_buct_layered_pilot.gd`: same tree collisions, paving, route points, actual guide completion and component cleanup
- `test_buct_entry.gd`: repeated chooser entry/return, mobile-sized controls, real touch input, original story and exact save-byte preservation

Exact-head CI and actual GUI results belong in the stacked Draft PR. Physical-phone and native-Web-export validation are not implied by compact desktop-window checks.
