# Zijingang Campus Artwork

## Runtime ownership

- `zijingang_campus_plate.png` is the cohesive `4 x 4` pixel-art world plate used by Phaser.
- The plate contains terrain, roads, water, bridges, buildings, and vegetation only.
- Phaser owns the player, road-constrained movement, foreground occlusion, labels, interaction targets, task markers, and story transitions.
- The generated world is `3840 x 3840` and is sampled with `NEAREST` filtering.

## Source references

- `source/mosaic/tile_01.png` through `tile_16.png` are the user-selected strict top-down source tiles.
- `source/mosaic/zijingang_road_walkability_mask.png` is the generated full-resolution authoring mask.
- The source tiles and authoring mask are not imported by application code.

## Generation contract

- GPT Image owns campus artwork generation. MiniMax remains audio-only.
- `npm run map:zijingang` center-crops and normalizes the 16 tiles, places them in input order, paints connected seam roads, and writes the final plate and runtime manifest.
- The generator extracts dark neutral road pixels connected to tile borders, adds the seam network, applies the shared player-foot clearance, keeps the spawn-connected component, and stores a compact `8px` walkability grid in `zijingang-campus-runtime.json`.
- All tiles use one strict 90-degree top-down projection, north-up orientation, palette, pixel density, light direction, and final scale. Facade elevation and isometric 45-degree views are not accepted.

## Mosaic pipeline

- The layout is a deterministic `4 x 4` grid of `960px` normalized tiles.
- The only non-square source is center-cropped before the shared resize; no tile receives an independent runtime transform.
- Three vertical and three horizontal `80px` seam roads replace inconsistent source edges and keep all districts connected.
- Run `npm run map:zijingang -- --qa-output /tmp/zijingang-campus-road-qa.png` to produce a temporary road-overlay review image.
- Phaser reads the plate dimensions, spawn, library entrance, tile metadata, and road mask from `src/data/maps/zijingang-campus-runtime.json`.
