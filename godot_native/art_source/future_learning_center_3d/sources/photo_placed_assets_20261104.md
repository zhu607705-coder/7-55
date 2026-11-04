# Place the existing lounge and workshop models · 2026-11-04

This change is in the independent Three.js building viewer. It does not change
Godot gameplay, room numbering, a source photograph, or any model source file.
The four relevant lounge/workshop/electronics reference images were inspected.
They are not copied into this delivery. All model dimensions remain estimates.

## Default scene, not an inspection-only preview

`photo_scene_config.json` now binds two corrected single seats to the original
3F pantry `office_chair.043` and `.044`. The original double sofa remains.
Only `.043` carries one loose cushion. Thus the photo family has one double,
two singles and one cushion. The other two conversation chairs remain unchanged.
This is a candidate adaptation to the existing room, not a measured recreation
of the photograph's arrangement.

The single seats use the original ground anchors plus 0.10 m outward offsets,
without scaling. An additional half turn makes their -Z fronts face the
existing tables. Their world X/Z centres are approximately (14.7734, 38.0009)
and (16.3734, 38.0009). Each retains its original source-node spatial identity.
The nearest table-edge gap is 34.65 mm. This is furniture separation, not a
walkable passage; the ordinary approach to both seats is from their north side.
The right seat has about 284.65 mm to the east wall's inner face. No claim of
wheelchair access or physical-site ergonomics is made.

The cushion foot is at Y=0.45675 m. A ray against actual single-seat triangles
finds support within 0.5 mm at each LOD. It is not duplicated on every seat.

## Workshop candidate inside the confirmed long 3F X-Lab range

The existing room is `xlab`: X=18.8584–25.8737 m, Z=12.9781–42.3263 m.
It is not renamed 304. No 2F object or room is relocated.

A composition uses the existing `xlab window base` as its stable source identity,
retains that window geometry, and has an explicit floor anchor (24.9, 0, 20).
The source asset resources are shared. Positions below are in floor coordinates,
with no second axis conversion or scale:

- Two green carts at (24.9, 0, 18) and (24.9, 0, 22), fronts toward west.
- Cart one carries the small vise, blue driver rack and red flat case.
- Cart two provisionally carries the soldering set, wire spool and test leads.
  It is a candidate support arrangement, not the long electronics bench seen
  in the reference photograph.
- Tools rest on the actual decoded rubber-mat top at Y=0.8875 m. Each complete
  footprint fits the mat, and separate tools have no overlapping AABBs.

Each cart's complete footprint is X=24.64625–25.15375 m and Z=centre±0.50650 m.
The nearest ordinary desk edge is about 0.87 m west of the cart. The east window
wall has about 0.67 m clearance. The west entry, west aisle and east aisle at
X=24.1 m remain passable with the existing 0.24 m avatar radius.

## Collision, identity and failure

There are three new bindings: `rest/single-43`, `rest/single-44`, and
`xlab/workshop-candidate`. They contain 2, 1 and 8 parts respectively, and produce
one static inspectable root per binding. All original 40 photo desktops and
four static photo bindings remain. LOD resources are loaded once per asset.
`photo_static_placement.js` shares geometry and stores rigid part transforms;
it does not scale or rebuild the models. Inspection continues using the actual
room and existing return path. Desk lifting and frame timing are unchanged.

Only successfully loaded compositions install collision. The two old chair
colliders are replaced locally by conservative all-LOD seat footprints. The two
cart colliders are added only after every required part and LOD has loaded.
A failed cushion retains the entire original first chair; a failed workshop
part retains the window and adds no invisible cart collision. Draco decoding
failure still retries the existing uncompressed GLB.

## Deliberately unresolved items

The loose pegboard is 0.788 m wide while the cart mat is only 0.737 m wide.
Without a verified mounting arrangement it is not balanced on the mat. The
larger electronics bench, six instruments, quadrotor, remaining tool cases,
round lounge table, bar chairs, high stools, window counter, PC cases, and large
desk/counter replacements need their own support and
placement checks. They remain available source models, not silently deleted.
This is eleven new placed parts, not completion of all 68 available models.
No presumed instrument inventory, hidden mounting structure or room ownership
is invented to make them appear complete.

## Verification

`test_placed_assets.mjs` parses actual uncompressed GLB geometry for both
`building.glb` and `building.web.glb`. It checks all eleven placed parts, all
three LODs, foot contact, actual mat support, room/wall bounds, and separation
from retained furniture. Furniture comparisons are asserted nonzero: 19,096
for the full building and 7,672 for the web building. The support test compares
conservative all-LOD item bounds with every LOD's actual mat bounds.

The test uses `moveBody`'s ordinary 0.07 m maximum collision steps along the
X-Lab entrance, full west/east aisle lengths, and pantry entrance to both seat
approaches and cabinet/refrigerator fronts. It checks solid bodies and atomic
partial-load failure. It does not label the table/seat gap a walkable route.

Existing photo loader, spatial integration (both building files), workstation,
frame timing, collision, spatial-state, presentation and overlay tests pass.
The separate placed-assets browser harness adds ordinary desktop/mobile input,
default visibility, room selection, repeated inspection, resource identity,
collision samples and failure/reload checks. Browser rendering and screenshots
remain CI acceptance work: no local Chromium socket restriction was bypassed,
and Node geometry checks are not described as browser visual acceptance.
