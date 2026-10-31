# Reverse-order batch 2: ten 3F rooms, direct object interaction

Base: PR #192 head `911ba7677b26ad431af210fa8578d176c8c8e615`.
This is a stacked change, not a duplicate delivery of the seven 4F rooms.

The user's October 30 clarification asks for fewer buttons and interaction with
actual objects. Here, input changes the rendered object, not just a state label.
Examples include lifting a tray handle, sliding a pin through two holes, rotating
a folding lid, moving a perforated plate, and plugging a transparent circuit.

## Verified reuse and new work

Existing floor geometry/furniture/navigation/transit remains authoritative.
All 3F design anchors existed except the small-room display table. Its new solid
footprint is `[4620,5780,140,70]`. Native complete-foot tests verify four sides,
round trips to the existing spawn, and the unchanged door-ground passage.
The builder is deterministic and idempotent; 2F/4F data is unchanged.

| Room, in reverse plan order | Actual objects | Completion evidence |
| --- | --- | --- |
| xlab_box | Two voxel plates, supported depth/height slots, rotating holder, camera, removable paper mask | Two views of one fixed geometry; base two valid solutions, masked extension enumerated separately |
| xlab_south | Hinged narrow/wide lids, flexible cable, plugs, route pegs, accessory | Continuous swept clearance, powered-open trial, actual closing and template fit; valid alternate order accepted |
| xlab_north | Three test blocks, contacts, transparent circuit plates, clamp | Four physical contact observations under one circuit; changing input blocks is not changing the circuit |
| pantry | Four independent cups, tray handle, movable fulcrum, destination table | Actual torque, trial lift and delivery of the same balanced configuration |
| seminar | Task magnets, individual camera/workbench tools, clockwork handle, output tray | Three real beats; prerequisites snapshot before each beat, tools cannot be used twice simultaneously |
| recording | Baffle, feed lever/handwheel, camera | Same-trial actual transport then shielding and exposure; baffle movement does not erase the needed transport history |
| studio_4 | Supports, shaft, hinge cover and handle | Shaft crosses both holes and the connected lid actually opens/closes without collision; valid alternate assembly sequence accepted |
| studio_3 | Two draggable event tapes, feed handle, spare tape reel | Two same-identity anchors disambiguate repeated flashes, followed by a complete current-version run |
| studio_2 | Two blocks, removable pin and rotation grip | Supported collision-free transport and connected end contacts; separate transport and longitudinal coupled transport both valid |
| studio_1 | Four models, notched photo cards, viewing footprints and camera | One physical arrangement satisfies opposite-view constraints; 180° transforms both rows and columns, short-side transfer uses 90° |

All station views remain native Godot Controls in the isolated FLC review. The
new 3F room objects open through the same real walk-to-furniture entry as 4F.
Production narrative/save integration is not claimed by this batch.

## 4F corrections from the latest feedback

The extension rectangle on the railway is replaced by an actual draggable
trailer. Attaching it checks the available tail cell and does not teleport either
cart; attaching at the destination cannot earn a long-load completion. Cable
routing uses draggable clips and physical pegs rather than “inner/outer” text
buttons. Workstation docks, cable spool and auxiliary power module now read as
objects. These are new changes in this batch; PR #192's historical screenshots
are not represented as acceptance of the revised versions.

## Validation and review

```sh
GODOT_BIN=/path/to/godot-4.7.1 \
  node godot_native/campuses/future_learning_center/tests/run_puzzles.mjs
node --test godot_native/campuses/future_learning_center/tests/test_projection_table_builder.mjs
```

The same runner covers the 4F regressions, ten 3F models and input paths, native
floor entry/close/reentry, display-table placement, and the unchanged building
suite. CI uses separate one-slot registered stages rather than a nested pool.

Godot 4.7.1/OpenGL llvmpipe viewport snapshots are stored in `review_3f/`.
They are actual native renders, not generated concept art. `capture_puzzles.gd`
requires a graphical renderer and fails explicitly under headless dummy mode.

Review areas: `?area=xlab_box`, `xlab_south`, `xlab_north`, `pantry`, `seminar`,
`recording`, `studio_4`, `studio_3`, `studio_2`, `studio_1`; native standalone uses
`FLC_REVIEW_AREA`. The building camera stays fixed while the projection holder
turns. Phone event/cancellation tests are not a claim of real-phone acceptance.

## Next: 2F without duplicating existing work

2F electrical already has a native workbench; platform already has a browser
geometry prototype. They need incremental extension/migration, not replacement.
The original plan declares an existing isolated `signal_sync_model/view` for
team, but source has not been recovered from currently accessible artifacts.
Its status remains **declared existing, source unlocated**, not “unimplemented.”
The 3F event-tape synchronizer is not that 2F dual-screen sample.

The remaining 2F rooms, formal story integration, and final art/phone acceptance
are not claimed complete here. PR #192 also retains a separately documented
canteen 200 ms CI timing failure; this patch does not relax that assertion.

### Recorded acceptance of this batch

- Actual mouse: projection was photographed from both directions after moving
  the same B plate to depth slot 2. A shutter request while rotating was rejected.
- Actual mouse: fold first stopped against its cable, then succeeded after
  rerouting, an open powered trial, and continuously closing both lids.
- Actual mouse: recording transported to its stop before moving the baffle back
  for a clear photograph. Sync completed only after moving its event tape and
  running the transport sequence.
- Actual building entry: clicking the new display apparatus opened projection;
  closing returned to floor 3 at exactly `(4555.0, 5783.312)`.
- All 17 station views were rendered with real OpenGL. The environment emitted
  a V-Sync driver warning; there were no GDScript errors and every PNG save
  returned success. This is not claimed as browser or real-phone acceptance.

Local focused run: all seven revised 4F suites and ten 3F suites passed, along
with 161 floor-integration assertions, 15 placement assertions and the original
1,740 building assertions. The source/registration/builder contracts passed 161
Node tests. In the access suite, 91 of its 115 assertions are continuous-angle
sweep samples, not 91 separate gameplay scenarios.
