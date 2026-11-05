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
