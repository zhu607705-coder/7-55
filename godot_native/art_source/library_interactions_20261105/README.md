# Library interaction animation family · 2026-11-05

Generated with the built-in `image_gen` tool, using the current backpack,
receptionist and approved library animation family as references. The tool does
not expose a model selector/backend identifier. Exact prompts are in `brief.json`;
untouched transparent source sheets and their hashes are in `originals/` and
`generation.json`. The first paper draft is retained as a rejected source; the
revised sheet removes the hard book-like binding and uses a single folded note.

Three 16-cell transparent sheets were normalized with the same alpha cleanup and
32-color palette as the walk family. Fixed per-family scaling and registration
prevent frame-by-frame resizing. `normalization.json` records actual cuts, ink
bounds and distinct-frame counts. The original source files remain unchanged.

Runtime usage:

- Backpack: eight empty-pocket frames open the zip during an accepted inspection.
  The open pocket remains after inspection; a loaded save settles immediately.
  The later generated cells contain a painted-in note and are source alternatives
  only. The physical occupancy note remains a separate, single interactive object.
- Loose note: sixteen fold/opening cells follow the original paper reveal and
  pickup clocks. Receipt extraction uses the same paper material family. Generated
  handwriting has no authoritative clue values; readable labels remain native.
- Receptionist: twelve idle, blink, acknowledgement, receiving and checking cells
  replace the old two-frame artwork. Accepted desk interactions start a response.
  Scan/stamp clocks choose the document-checking gestures. Held-stamp alternate
  cells remain source only; the existing calibrated stamp owns contact and ink.

All frames are disposable presentation. No new story/save authority, inventory
transaction, dialogue bypass or collision geometry is added. Reduced motion,
scene changes, visibility cancellation and loaded final poses retain their owners.

`preview_backpack.apng`, `preview_paper.apng`, and `preview_staff.apng` loop the exact
normalized raster poses. They are pose previews, not independent gameplay clocks.
`pack_previews.py` packs PNG animation containers without painting new artwork.

Rebuild derived assets with pinned Godot 4.7.1:

```sh
godot --headless --path godot_native --script res://tools/normalize_library_interactions.gd -- /absolute/path/to/godot_native
python3 godot_native/art_source/library_interactions_20261105/pack_previews.py
```

Focused native validation passed: 179 generated-interaction checks, 72 seat-motion
checks, 33 object-feedback checks, 143 scene checks, 28,359 stamp-motion checks and
155 stamp-story-gate checks. Preflight, complete script parsing and the Web export
also passed. These checks do not constitute a full manual chapter playthrough.

The local isolated review routes are `/library-bag.html` and `/library-staff.html`
on `http://127.0.0.1:8622`. They start at the relevant object using validated review
saves; refreshing resets the supplied preset. The ordinary library and entrance
routes retain the full playable scene.

Real Chromium WebAssembly acceptance passed at 1436×810 (mouse) and 844×390
(emulated touch): initial bag inspection, authored-dialogue completion, physical
note pickup and receptionist interaction. No page or Godot script errors were
recorded. This does not establish a physical-phone test. See `acceptance.json`.
