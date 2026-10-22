# 7:55 Godot spatial migration experiment

**Draft. This is a theater spatial slice, not a converted playable campaign.**
The production React/Phaser/Three application and save schema remain unchanged.
Baseline: `39ccde029b0cd25a6011739a4e4f98f8c898b2c3`.

## Run from the repository root

Install Node 22 dependencies and the standard Godot 4.7.2 editor, then:

```sh
npm ci
node scripts/verify-godot-data.mjs
node scripts/export-godot-theater.mjs
godot --headless --path godot-port --editor --import
godot --path godot-port
```

On macOS the editor binary can be invoked as
`/Applications/Godot.app/Contents/MacOS/Godot` instead of `godot`.
Generated assets are required before opening the project. They are ignored by
Git and rebuilt from existing source files, with PNG dimensions and SHA-256
recorded. The exporter rejects unsupported executable expressions and LFS
pointers. It does not run/import application modules or fetch new game assets.
The original TypeScript constants remain the only authored geometry source.

## What is implemented

- Existing theater artwork, 27 static collision rectangles plus the closed gate,
  14 occlusion regions, three authored spawn points, and 25 player frames.
- CharacterBody2D foot collision, native movement, Camera2D, and native Y sorting.
- WASD/arrows, test movement buttons and explicit debug spawn buttons.
- A focus-loss release handler and an engine smoke test for source collider
  counts, spawn overlap, movement, gate blocking and focus release.

Legacy spawn coordinates refer to the sprite center. The Godot body origin is
the bottom of the foot box. The adapter derives the offset from the original
frame/scale/foot contract. World coordinates remain source-image pixels. Movement
speed is a rehearsal value of 220 px/s; production movement/timing parity is not
claimed. The gate stays closed; debug warps never grant admission/story facts.

## Test status and promotion gates

Seven local Node fixture boundary tests passed, including non-execution of
application code, rejected computed syntax, size/depth limits and invalid
geometry/player contracts. JS syntax checking passed after those dynamic tests.
The local environment lacks a complete repository checkout and Godot. Therefore
real-asset export, native GDScript compilation, actual engine smoke execution,
and native visual checks were **not run locally**. The CI job runs the actual
source exporter and native engine checks; inspect its result before use.

The Playwright checks associated with the separate state-writer PR exercise the
web helper. They provide no native Godot visual evidence. Before promotion,
inspect lobby/auditorium/stage at desktop and portrait sizes, including feet,
seat occlusion, map boundaries, touch-release behavior and camera clipping.
Record screenshots from the actual renderer and fix any overlap or clipping.

```sh
# Native dynamic tests, after import:
godot --headless --path godot-port --script res://tests/smoke.gd
# Static native checks follow dynamic testing:
godot --headless --path godot-port --check-only --script res://scripts/player.gd
godot --headless --path godot-port --check-only --script res://scripts/theater.gd
```

Not implemented: phone UI, dialogue, inventory drag/drop, admissions/program/
spotlight puzzles, audio/video behavior, save migration, other chapters, or Web
export packaging. No generated binary is promised by this draft. Converting a
full campaign requires those explicit behavioral parity gates; changing file
extensions cannot translate React components, TypeScript closures or Phaser APIs.

See `../docs/architecture/godot-migration.md` for state ownership and staged work.
