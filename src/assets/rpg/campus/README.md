# Zijingang Campus Artwork

## Runtime ownership

- `zijingang_campus_plate.png` is the single panorama loaded by Phaser. Its final size is `5016 x 5016`; the runtime never positions or scales individual source tiles.
- The plate contains terrain, roads, water, bridges, buildings, and vegetation only.
- Phaser owns the player, movement, foreground occlusion, labels, interaction targets, task markers, and story transitions.
- The world is `5016 x 5016`, renders at source size without stretching, and is sampled with `LINEAR` filtering so fractional camera zoom does not make the detailed plate shimmer.

## Source references

- The selected panorama is rebuilt from `~/Downloads/大地图/` in row-major order: `(1,1)` through `(1,4)`, then rows `2`, `3`, and `4` in the same order.
- Twelve source images are `1254 x 1254`. `(3,1)`, `(3,2)`, and `(4,1)` are `1477 x 1065`; `(4,2)` is `1364 x 1153`. Those four are normalized to `1254 x 1254` with Lanczos resampling before composition.
- The source images do not meet continuously at their internal edges. The rebuild converts all three vertical and three horizontal joins into continuous campus connector roads inside the final PNG, preventing visible hard offsets at every camera zoom.
- `source/mosaic/tile_01.png` through `tile_16.png` and `source/mosaic/zijingang_road_walkability_mask.png` belong to the alternate `3840 x 3840` mosaic and are not imported by application code.

## Generation contract

- GPT Image owns campus artwork generation. MiniMax remains audio-only.
- `npm run map:zijingang:rebuild` deterministically rebuilds the selected PNG from the source folder and reports its SHA-256.
- `npm run map:zijingang` verifies the selected panorama, its SHA-256, dimensions, runtime coordinates, compressed walkability bitset, and the matching mask PNG without rewriting assets.
- `npm run map:zijingang:mosaic` remains available only for rebuilding the alternate `3840 x 3840` candidate. Running it changes the active plate and therefore requires an explicit selection decision before delivery.
- All tiles use one strict 90-degree top-down projection, north-up orientation, palette, pixel density, light direction, and final scale. Facade elevation and isometric 45-degree views are not accepted.

## Selected panorama contract

- The selected plate SHA-256 is `600e3010c7b1ccb4e4c697850e9ee37b6670d84aaec3ba5ce8fc0c1274a718bd`.
- Phaser reads the `5016 x 5016` world, spawn, library entrance, landmarks, and compressed `4px` walkability grid from `src/data/maps/zijingang-campus-runtime.json`.
- `zijingang_road_walkability_mask.png` is the reviewable `5016 x 5016` nearest-neighbor expansion of that grid. Runtime code merges blocked grid cells into static collision runs, so the player's foot box remains on the connected road region.
