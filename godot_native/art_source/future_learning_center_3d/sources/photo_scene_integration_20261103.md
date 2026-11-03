# Photo assets in the real Three.js viewer (2026-11-03)

This is an independent architectural viewer, not a Godot/gameplay release.

## Bound objects

`web/assets/photo_scene_config.json` lists explicit original GLB node names. The
loader uses GLTFLoader's `userData.name` because runtime `name` removes periods
and replaces spaces. Existing spatial review IDs still use the original runtime
naming contract; this change does not rename them.

Forty existing 3F `office_desk.008` through `.047` receive the same shared photo
monitor, keyboard and GPX-shaped mouse assets. No desk is moved. The original
1.4 × 0.6 m desktop, telescopic columns, controller and 0.73/1.10 m lift remain.
This is **not** a new lifting-desk industrial design. Only the old monitor arm,
screen, keyboard and mouse primitives are replaced, atomically after every
replacement LOD has loaded. Paper and the original controls remain.

- Monitor: the earlier 614 mm casing candidate, with a blank 598 × 336.4 mm display. Its roughly 27-inch diagonal is a model calculation, not a size verified from the photograph. The workstation review offers alternative widths; no final screen size is claimed.
- Keyboard: approximately 370 × 145 mm plan, 39.31 mm total height.
- Mouse: corrected LOD0 bounds 63.5 × 125 × 40 mm (W × D × H).
- Photo monitor and keyboard use a rigid 180° yaw to face the original desk's
  -Z seated side. The mouse scroll wheel faces +Z. Its location is on the
  user's right (-X when seated at -Z facing the desk).

Runtime glTF files already use metres and Y-up. The viewer never applies a
second coordinate conversion or anisotropic scale. It rejects scaled anchors.
Each part's transform is the original desk transform times one placement.
All desktop components have liftFactor 1. Shared InstancedMesh batches retain
per-desk lift, near/mid/far LOD selection and isolated inspection proxies.

The reused runtime assets occupy `models/photo_scene_20261103/`. Monitor, keyboard and two countertop appliances are copied from the publication-clean asset batch, not over the old scene tree. The corrected GPX uses `models/photo_desktop_corrected/photo_mouse`; the corrected sofa uses `models/photo_lounge_corrected/lounge_double_corrected`. Each manifest preserves its source/hash/LOD provenance. Private Library locators are not published.
The software/hardware area's internal placement under 405 is not resolved into
coordinates here. The config keeps `hardware-304` pending; no equipment is
moved from 2F and no walls, room IDs or save semantics are changed. The subsequently approved refrigerator-only collider change is described below.

## Failure and resource behavior

A Draco failure retries that level's uncompressed GLB. A missing asset/LOD keeps
the corresponding complete original desk. A missing config keeps all original
objects. Pending bindings never fetch or instantiate assets. Geometry/material
resources are loaded once per asset/LOD, then shared by instances. Inspection
borrows resources and never disposes the originals.

## Validation boundary

Local Node tests parse real building GLBs and real uncompressed desktop GLBs,
then execute viewer functions with a mocked renderer/DOM. They are not GPU or
pointer acceptance. The separate browser harness retains normal clicks/taps,
30-second actionability timeout, desktop/mobile paths and repeated navigation.
Its photo assertions run against `flcReview.photoAssets()` in the actual viewer.

Local Chromium launch failed with `socket() failed: Operation not permitted`.
No launch workaround, permission bypass, force-click or timeout reduction was
used. CI must run the committed browser harness before browser acceptance can
be claimed. The pre-existing overview return failure on software GPU remains
unresolved until that exact browser run passes.

The additive `flc-photo-scene.yml` runs photo/workstation Node contracts, both actual building GLBs, the pinned Blender source/composition checks, and independent photo/workstation Chromium jobs with always-uploaded evidence. The existing `flc-spatial-browser.yml` ordinary-navigation gate remains mandatory and unchanged. Desk timing and its pause/cancellation contracts are also registered in the new workflow.

## Pantry binding and remaining fit limits

- `Static asset pantry_sofa`: corrected double sofa, 1.528947 × 0.830700 ×
  0.852059 m (W × D × H), same anchor, front -Z, no scale.
- `Coffee machine` plus `Coffee cup niche`: grey round-front photo appliance,
  0.391 × 0.4615 × 0.360 m, at original X/Z centre and bottom Y=.920 m.
- `Microwave` plus `Microwave door`: white clear-top photo appliance,
  0.350 × 0.3875 × 0.4475 m, at original X/Z centre and bottom Y=.920 m.
  Both receive neutral appearance labels, not confirmed appliance identities.
  All LOD bounds fit the existing countertop. Their horizontal gap is .4795 m.
- The 2.4 m photo counter cannot simply replace a 4.9 m counter without leaving
  large areas of invisible collision. It remains pending.
- The .902 m photo fridge is .152 m wider than the existing .750 m proxy.
  At the old centre its right edge overlaps the east wall's inner face by about
  1 mm. Its left gap to the cabinet would be .496 m; front gap to the nearby
  conversation chair is 1.120 m. The approved local update moves its centre 10 mm left and changes only the
  3F Refrigerator collider X bounds. East-wall model clearance is now 9 mm,
  the left cabinet gap is .486 m, and front gap remains 1.120 m. This is not
  a surveyed installation or construction clearance. Original fallback fridge
  geometry also remains inside the slightly larger collider.
- The 1.558 m wood surround, 1.6195 × .6695 m desk divider, separate monitor arm,
  single lounge chair/cushion, and hardware-area placement remain pending.
  The divider exceeds the 1.4 × .6 m desktop, and the current monitor includes
  its stand. No second support is overlaid on that monitor.

The asset loader waits for all level outcomes before releasing failed-owned
geometry/material/textures. A successful neighboring asset's shared resources
are retained. Failure/reload recovery and idempotent disposal are tested.
The render loop switches desk LOD before synchronizing the inspection proxy;
LOD2-to-inspection tests check nonzero visible matrices on the first frame and
while idle, rather than only checking the selected LOD variable.

## Refrigerator-only approved geometry/collision adjustment

`Pantry refrigerator` and its five door/gasket/handle primitives are replaced
as one unit. The photo fridge is .902 × .700 × 1.814 m (W × D × H).
The root placement is original centre plus (-.010, -1.000, 0) m and yaw π:
the Y offset changes the old centre-origin to the new ground-origin.
Only the original `Refrigerator` collider X bounds change:
[16.2484104, 16.9984104] → [16.1624104, 17.0644104].
Its Z range [41.4762609, 42.1762609] stays unchanged. Tests check all LODs
inside the collider, the 9 mm wall gap, the front approach, impassable body and
repeated floor expansion/collapse without placement drift.
