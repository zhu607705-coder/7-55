# Original Room204 table drag feedback

Picking the independently modeled original table previously showed only `桌椅组 ↑`. The candidate preserves that label and carries the exact original atlas texture with a160ms lift (9rendered pixels,5.5% scale) and a pointer-velocity lean bounded to0.065rad. The source table dims while held. A missed/cancelled drop uses a240ms centre-preserving visual settle. Correct placement still goes immediately through the unchanged controller and its original three-desk/chair restoration.

Only this one table changes. Its root transform, static foot, interaction area, target and controller are unchanged. The animation acts only on the Sprite2D child; the drag ghost has no physics/input owner. Scene context, phone hiding, focus loss, resize and drag end reset the visual owner. Repeated pickup resets the original sprite before constructing a new ghost, preventing accumulated deformation. Reduced-motion uses a static ghost and immediate return.

## Verification

- Final focused motion436, original native-object1315 and inherited mobile group-input126 checks pass. The last covers390/430/1440 synthetic root-pointer paths; it is not hardware touch.
- Actual desktop first revision: original-texture drag/return and accepted first group;3piece save09:16:42. The final revision restores the original direction label and hardens rapid repick.
- Actual final390: pickup/missed return, drag outside the world, phone detour/return, original dark residual review, light placement and exactly3pieces. Final save09:33:5684cad7bc…7d55. Ordinary uninstrumented1180 restart retains the restored group and no stale table or ghost.
- Final3.3333s clip has24 actual native frames with measured timestamps, repeated as needed at24fps; no generated interpolation or audio. Passive viewport sampler is excluded from production.
- Native source-project verification only; no new package/full aggregate. Dummy audio, no hearing or real-finger acceptance. Reduced-motion/focus/resize are focused-test results, not actual settings-switch claims. SpecificF10 denial remains untouched. A separate ordinary Return click succeeded on its single authorized retry.

## Preserved history

An inherited test was initially missing from this small copy; it was copied unchanged. The new test initially used unqualified notification constants and then a stale fixture-player location, both corrected. Motion429 passed before the extra rapid-repick/label assertions; final436 passed afterward. The inherited mobile test initially lacked its portrait base fixture; after copying it unchanged,126passed. All failed logs remain. Actual desktop target misses are retained and not attributed to changed hit boxes.

## Scope

Six proposed files: scripts/world.gd; scripts/objects/room204_table.gd; scripts/objects/room204_table_adapter.gd; scripts/ui/room204_drag_preview.gd; tests/test_room204_drag_motion.gd; this document. The first three build on the frozen native-table candidate. No controller, original asset, scene collision, save schema or other group implementation changed. This is separate from the earlier35-path integration union; no Git staging/commit/publication occurred.
