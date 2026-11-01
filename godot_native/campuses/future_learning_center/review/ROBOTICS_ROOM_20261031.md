# 2F ASABE robotics room: assembly island

This records the furnishing pass before the door correction. Its unchanged
architecture claims are comparisons with the previous game build, not validation
against the original design. See `ROBOTICS_GLASS_FRONTAGE_20261031.md` for the
subsequent source-plan correction of the incorrect wooden east door.

The user's annotation identifies the room overview: the real room has a large
central table full of components. This pass replaces the four repetitive tall
benches and small central printer desk with one shared assembly island, two
secondary work areas, north-wall parts racks, a printer station and a tool cart.

The central table carries eight independently rendered groups: hardware boxes,
wheels, motors, wires, a controller with battery, hand tools, structural parts
and a second spare-parts box. The working delivery robot remains the physical
entry to the existing puzzle. These new parts are room dressing; they do not
claim new assembly mechanics or grant puzzle progress.

## Scope and assets

- Native Godot 4.7.1, branch `codex/flc-transcript-level-design-20261029`,
  uncommitted room update on `9d28feb6`.
- A room-local 0.90 zoom replaces about 0.73 for this room. The shared actor,
  floor/door coordinates, camera bounds and uniform 960×540 viewport stay fixed.
- `apply_robotics_details.mjs` runs after generic furnishing. It preserves
  `robotics_workbench_30` and unrelated puzzle IDs; repeated application is
  idempotent. All other room objects and all architectural datasets compare
  byte-equivalent as parsed data to the pre-change snapshot.
- Table and eight component regions are generated RGBA art. Original PNG bytes
  are preserved; only crop metadata is calibrated. Provenance, alpha checks,
  original filenames and SHA-256 values are in
  `data/robotics_asset_receipt_20261031.json`.
- This is a playable furnishing proposal informed by the user's photos and
  correction, not a measured reconstruction of unseen furniture placement.

## Verification

Evidence folder: `.impeccable/review/flc_robotics_room_20261031/` at repository root.

- 2F/3F/4F spatial regression: 1,768 checks passed, including original door
  apertures, room reachability, complete-foot collision and room camera bounds.
- Native 1280×720 mouse: 49 checks passed. Native 844×390 simulated touch:
  50 checks passed, including touch cancellation. Neither path requires a key.
- Both runs circle all four sides, cross the original doorway, stop at the
  table's solid base, back away, tap the table from the doorway, enter the robot
  trial and return to the same legal foot position. The delivery and return
  routes, failed path, repair, rotation and undo remain operational.
- Native and browser screenshots show the actor's lower body occluded behind
  the table. New components stay on the tabletop instead of the floor.
- Browser review uses the exported Godot scene at 1280×720, 903×862 and 844×390.
  Entry and exit are verified through ordinary canvas clicks. The 903×862 view
  keeps the table, robot and east-side approach legible. The camera reveals
  north-wall storage as the player walks north. Browser logs contain no errors.
- Impeccable layout scan returns no findings, but it cannot inspect drawn
  Godot controls. Rendered screenshots and input checks supply that evidence.
- Source sync and native preflight are recorded separately. The first
  preflight's exact-content receipt was invalidated by concurrently written
  screenshot evidence; `native_preflight_final.json` is the sequential rerun.

The standalone Web build has no production autoload/save access. This room
review does not establish formal-chapter integration, physical phone acceptance,
or a GitHub merge/release. Remote refresh was attempted but blocked by the local
proxy/connection failure; no claim is made that the remote branch was pulled.

## Asset generation brief

Recorded generation brief (the complete per-call prompts remain in the tool
conversation): use the incumbent fine-pixel white worktable as the projection
and material reference; transparent background, horizontal front edges,
orthographic oblique view, no floor, characters, labels or room walls.

The final table is three joined white assembly surfaces with a broad visible
top, metal legs and an open lower structure. An initially too-shallow table was
rejected; the final top occupies roughly sixty percent of the silhouette height.
Components are a separate 4×2 atlas with clear alpha gutters: hardware, wheel
groups, motors, wire coils, controller/battery, partly assembled chassis, hand
tools and brackets. Preserve a clear center for the live robot when placing
the independent regions. No post-generation bitmap edits were applied.

## Layout review

The large white island leads; the two smaller desks support it; storage belongs
to the north wall. Related parts form tight tabletop groups, while the four-side
walk loop and east door remain open. The enlarged view follows the player rather
than shrinking the whole room to fit. Narrow viewports letterbox uniformly and
retain the native joystick. No new persistent object labels or action buttons
were added. Existing room navigation and the apparatus subtitles are retained.
