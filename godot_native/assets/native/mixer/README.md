# Mixer anchor 28: independent source-derived parts

The runtime backdrop is the existing clean tasting-counter image. It contains
no foreground glass, three ingredient bottles, or their contact shadows. The
whole original concept is never drawn underneath the active objects.

The original concept is the visual reference for one empty clear glass and the
three original ingredient identities: black coffee (bean label), sparkling
water (blue bubble label), and lemon tea (citrus/leaf label). No item ID, recipe,
reward, or ownership rule is created by these files.

Four transparent PNGs were obtained through image editing of that reference.
The generated canvases did not all retain exact registration. `components.json`
therefore identifies the visible source regions and runtime bottom-center
anchors. Every region is scaled uniformly; the original returned PNG bytes
remain unchanged. Source-region clipping excludes faint alpha noise outside
the actual parts. There are no opaque rectangular covers over the worktop.
The glass-center alpha is 2/255, so the actual underlying scene remains visible.

The original PNG bottle is divided into body and cap regions without raster
rewriting. Its cap opens independently before the bottle travels and tilts.
The cup's fill and stream are native geometry, clipped inside a fixed
perspective interior mask. The glass, its contact point, and the counter never
scale or jump on a result. Bubble and foam effects are local to the vessel.

`c3_mixer_surface.gd` mounts the physical objects in the existing mixer modal.
Buttons target the bottles rather than replacing them with text or colored
rectangles. The original randomized slot order and missing-ingredient feedback
are preserved. `c3_mixer_motion.gd` also supplies the normal-world performance.
Only `mixer_counter` uses the clean worktop crop; `drink_shelf` retains its
original cabinet and baked drink-dispenser artwork as a different object.

## SHA-256 provenance

- `canteen_tasting_counter_clean_background.png`: `1c11116324f137a9795025ae069320424a96abf01cda4e2b13baa739b6244e85`
- `canteen_tasting_counter_concept.png`: `55cccaff02372cf25f0f069f329b3f9badd6f6c92a6fec7df3774260876a9452`
- `glass_rgba_v1.png`: `1947dd5c871bcabd38f019ea5650fff62088ccd28f6ac78b9aeedec0d1dc5715`
- `blackCoffee_rgba_v1.png`: `2aa19e22701ed12dab64840fd3072bfe05bea27d14a859a7673e731ed0995586`
- `sparklingWater_rgba_v1.png`: `ce2b1125a9e2b7e40d6fa5d744a5f734a58badd34f883c4406f7fdce53aab4bd`
- `lemonTea_rgba_v1.png`: `f370938d083232c26ededd925ba16058081a7fc4cc739fac9420a95b84fdff57`

The reference concept is retained in the development evidence and source
Library. It is not a runtime dependency. The clean backdrop and four transparent
parts are the runtime assets. Actual in-game visual acceptance is recorded
separately from alpha/source-identity tests and assembly previews.
