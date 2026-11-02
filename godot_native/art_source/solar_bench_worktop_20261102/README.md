# Solar test-bench background — 2026-11-02

This asset changes only the Formula solar-car page. It does not change the
separate solar endurance bench, the phone, check-in, dialogue, or shared themes.

## Source and composition

- Original generated bitmap: `generated_source.png`; exact prompt in `prompt.txt`.
- Built-in OpenAI image generation, requested for this project. No external art
  or font was copied. The generated plate contains no text, controls or cars.
- Source 1672×941; deterministic crop `(116,38,1556,848)` yields 1440×810.
- Runtime placement is 960×540, a uniform 2/3 scale, with nearest filtering.
- `asset.json` records hashes and provenance. `.gdignore` keeps source files out
  of runtime imports; only the cropped PNG in `assets/puzzles` is consumed.

The timber assembly area and inset grey-green testing mat replace the large
white slabs. The track, cars, parts, tilt mechanism, lamp, shutter, gate and
configuration samples remain live native 3D objects at their original anchors.
The readouts remain native text. The original 3D camera, viewport, object
geometry, lighting clock and input ownership are unchanged. Static daylight
on the background is room illumination, not the model's simulated irradiance.

This is a textured raster backdrop under the existing non-pixel apparatus
renderer. It does not claim exact 32-colour or whole-game art-style compliance.

## Scope and checks

Baseline: main `72fe2ed3dab84c99cedb2e427a4d639fca135472`, tree
`a6ff943809253e255e1bb549b8c69a7ad35dacde`.

Only `formula_view.gd` and `formula_miniature.gd` change presentation. The former
adds a non-interactive background and darker local ink; the latter makes its
viewport transparent and omits the three white surface meshes. No model,
parameter range, input/drag/cancel/exit function, shared style or font changes.

Godot 4.7.1 focused checks: original Formula **221/0**; extended presentation
**38/0**; isolated scaled input/JSON-codec helper **60/0**. The helper covers
1280×720, 844×390 and 390×844, but is not a physical-device or full-floor test.

Native cloud review uses the real Formula Control with the production host's
960×540 SubViewport and 52px navigation placement. It is not a full floor-entry
or persistent-store host. Actual drag-to-track, gate start, a 30-second run,
records and room close were exercised. The same configuration reaches 56.01
versus 52.35 model units. Desktop and narrow captures are review artifacts,
not baked into the game. Full floor routing, disk persistence and Web export
remain the complete-repository CI gate before acceptance.

The inherited portrait layout still letterboxes the landscape apparatus and
renders its captions small. This page-only backdrop does not change that
existing geometry or claim to solve portrait interaction ergonomics.
