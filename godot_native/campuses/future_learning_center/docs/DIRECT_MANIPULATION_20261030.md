# Direct manipulation follow-up

Base: #194 head `0acc01523b2fa9bf378299b96d9c0f208f1d34fe`.
That head's four hosted workflows passed. This follow-up is separate and must
be validated on its own head.

The user reported that operating objects felt slow / unlike real objects. We
did not infer that every animation should be faster. Inspection identified
specific mismatches between a held object and the pointer:

| Room | Observed mismatch | Correction |
| --- | --- | --- |
| projection | Dragging drew a line while the folded solid stayed still; release jumped slots | Same solid and support show continuous model-owned constrained pose; commit once near a detent |
| solid_projection | The held 3D block became a flat rectangle, then appeared on the base at release | Preserve actual block geometry, grip offset, support and swept clearance; nearby valid landing only |
| rail | Pointer moved but the cart waited; release queued fixed-step movement | Cart and trailer move along legal rail edges in the same input callback; occupied track blocks the whole body |
| platform | One large pointer step that hit an obstacle rejected all progress | Move up to the last legal contact position, then allow retreat / rerouting |
| coupled | Translation or rotation rejected the entire step on any sampled contact | Preserve the legal partial motion up to the actual boundary |
| recording | The baffle ghost could cross the moving part, then snap back | Render the swept model pose, preserve grip offset and restore on cancellation |
| balance | Dragging to the destination then releasing reset the tray to the source and replayed transport | Settle from the actual held destination pose; no source teleport |
| robotics | The arrow preview followed the gesture, but release always toggled the track | Continuous arrow/stop and lever preview; commit the visible nearest detent, not an unconditional toggle |
| formula | A tiny initial knob movement jumped from 0/60 to 30 degrees | Begin from the actual angle, show continuous bracket preview and commit only near a detent |

Formula parts and the car also preserve their grab offset. A release without a
matching visible pointer motion cannot install a part or teleport the car.
The car must be placed at the visible starting gate; the same model resets its
actual distance to that gate rather than snapping from an arbitrary track drop.

## Preserved experiment timing

The 30-second solar trial, robot transport speed, actual loading/unloading,
recording feed speed and exposure are unchanged. Rail's explicit automatic
operation retains its original per-cell timing. Dragged objects no longer wait
for those command-style animations. A tray placed by hand only settles the last
small distance onto the destination surface.

## Gesture and evidence rules

- The object pose changes during pointer motion, before mouseup, without a timer.
- Preserve the grab point; do not jump the object center onto the pointer.
- Collision applies to the same geometry being rendered, including attachments.
- Release commits only the already-visible nearby valid pose. A distant release
  event alone cannot place or rotate an object.
- Cancellation restores the gesture start without creating completion evidence.
- Preview motion does not append undo history on every frame.
- An experiment cannot validate a temporary uncommitted pose.
- Robotics pauses a running trial while its track is held. Ordinary gesture
  cancellation can resume that trial; application focus loss must keep it paused.

## Verification

All 25 native puzzle suites, 230 room-entry checks, floor-placement checks and
1,740 original floor assertions passed in 69.963 seconds. All 195 Node contract
tests passed. Nine rooms received real desktop mouse checks; selected before/after
frames and observer logs are in `../review_direct_manipulation/OBSERVATION.md`.
Touch-device and held-cancellation checks are automated input tests, not claimed
as physical-device GUI coverage. The graphical observer records input and poses; it
does not assign successful model states. Old/new platform and coupled GUI
captures may both reach the same boundary when the desktop supplies many small
motion events. Their improved large-step guarantee is demonstrated separately
by model tests, not exaggerated as a visible difference in that capture.
