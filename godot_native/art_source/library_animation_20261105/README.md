# Library animation family · 2026-11-05

Generated with the built-in `image_gen` tool using the existing player and library
as identity/style references. The requested model name was `image2.6`; the tool
does not expose its model selector or backend identifier, so that model is **not
verified**. Exact prompts and constraints are in `brief.json`; original output
filenames and SHA-256 values are in `generation.json`.

- `originals/`: untouched transparent generated sheets, three actor directions and
  one book extraction/opening/page-turn sheet.
- `masters/`: 120×160 actor masters, using a shared per-direction scale, measured
  head center and fixed bottom registration. Extra idle candidates are preserved.
- Runtime player cells are 96×128; the original player rectangle, library scale,
  movement speed and fixed collision foot box remain the active geometry.
- Each actor direction has 16 distinct walk drawings. Shared stride duration is
  still 880 ms; the new family samples it every 55 ms. Neutral standing has its
  own frame. Left movement mirrors the same side family.
- `preview_*.apng`: looping previews of the actual 16 runtime frames at the
  runtime cadence; these are animation containers, not newly painted poses.
- `preview_book.png`: the exact 16 runtime book cells. Closed-cover texture is
  normalized to broad cloth-color clusters; interior paper and hinge details stay.
- Runtime book atlas is 768×640, with 192×160 cells, pivot (80,154), and a 110 px
  book height. Pulling and page-turn timing belong to the existing presentation;
  controller intents alone grant evidence and change progression.
- `normalization.json` records the actual grid cuts, scales, pivots, silhouette
  bounds and unique-frame counts. Alpha is binary, disconnected edge specks are
  removed, and opaque pixels use the approved 32-color palette.

Rebuild deterministic derived assets with Godot 4.7.1:

```sh
godot --headless --path godot_native --script res://tools/normalize_library_animation.gd -- /absolute/path/to/godot_native
```

This family is currently scoped to the library presentation. Original actor
assets remain available as the fallback and as the shared movement reference.
Generation, deterministic checks and browser acceptance are separate records;
the original generated sheets alone are not runtime acceptance.

Acceptance on 2026-11-05: Godot 4.7.1 preflight and the five focused suites
passed (609 animation-asset checks, 210 facing checks, 200 book-pull checks,
143 library-object checks, and shared player-metric parity). This is targeted
validation, not the complete repository suite. The earlier object test's old
empty-floor expectation was updated to match the already interactive glass door.

The Web export `library-generated-animation-20261105` passed provenance
verification. Real Chromium WebAssembly runs verified short-pull return, mouse
and emulated-touch extraction, landscape reader scrolling and completion at
1436×810 and 844×390. These are browser checks, not a physical-phone acceptance.
The local review URL is http://127.0.0.1:8622/library.html?v=animation-20261105.
Refreshing this isolated review route resets its supplied preset.

## Earlier full-body side walk, 2026-11-11

`originals/walk_side_full_20261111.png` is a new 3×3 transparent sheet
generated with the built-in image tool. Its first eight drawings form two
alternating steps, and the last is a matching standing pose. Each cel has
its own intact head, neck, body and limbs. The shared side-walk pipeline's
single proportional Lanczos reduction and head/foot registration place
all poses on the 120×160 master grid. Each foot baseline is registered at
row 159, and the upper silhouette rises and falls with the full pose.

The original and exact prompt are recorded in
`side_walk_full_20261111_generation.json`. The compiled atlas at
`assets/native/library_animation_20261105/player_side_walk.png` uses the
project's palette with distinct hair and jacket ramps. Godot draws each
120×160 cel directly into the existing shared player rectangle at physical
viewport resolution. Each side cel lasts 110 ms, and the loop lasts 880 ms.

```sh
godot --headless --path godot_native --script res://tools/build_library_side_walk.gd -- /absolute/path/to/godot_native
```

## Earlier three-direction sheet, 2026-11-11

`originals/walk_full_20261111.png` is the original transparent generation of
all 18 complete drawings in the earlier six-frame pass. The original prompt
and SHA-256 hashes are in `walk_full_20261111_generation.json`.

## Archived 16-frame walk cycles, 2026-11-11

The `originals/walk_16_*_20261111.png` sheets each contain 16 complete drawings.
The campus walk provides the character and motion reference. The earlier
library side walk provides the reference for the profile stride. The runtime
cycles face right, down and up, at 55 ms per pose. Left mirrors right. In the
right-facing cycle, poses 1 and 9 show the two opposite contacts. Exact
references, prompts and hashes are in `walk_16_20261111_generation.json`.

The earlier builder ordered the complete drawings by step and registered them on
the 120×160 player master grid with nearest-neighbor sampling. Four front-facing
drawings use whole-frame mirroring for their opposite-foot poses. Retained
pixels preserve their source RGBA values. Godot imports the atlas losslessly
and uploads uncompressed frame textures.

The previous runtime atlas is preserved as `archived_player_walk_16_20261111.png`.

## Archived walk cycles generated without reference images, 2026-11-11

The three `originals/walk_fresh_*_20261111.png` sheets each contain 16 complete
poses. `walk_fresh_20261111_generation.json` records the prompts, unmodified
source files and hashes. Its atlas is archived alongside the sources.

## Active eight-frame walk cycles, 2026-11-11

`originals/walk_8_side_20261111.png` supplies its first row. The two rows of
`originals/walk_8_vertical_20261111.png` supply the down and up cycles, with
opposite arm swings at poses 1 and 5. Left mirrors right. The builder uses a
shared alignment for each row and packs full drawings into 120×160 cells.
The eight cels last 110 ms each. `walk_8_20261111_sources.json` identifies the
exact source images and atlas. Runtime textures preserve RGBA8 values.

```sh
godot --headless --path godot_native --script res://tools/build_library_walk_sheet.gd
```
