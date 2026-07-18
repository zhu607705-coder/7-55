# Zijingang Campus Artwork

## Runtime ownership

- `zijingang_campus_plate.png` is the selected repository panorama used by Phaser. It is a cohesive `4 x 4` plate of `1254px` source tiles with a final size of `5016 x 5016`.
- The plate contains terrain, roads, water, bridges, buildings, and vegetation only.
- Phaser owns the player, movement, foreground occlusion, labels, interaction targets, task markers, and story transitions.
- The world is `5016 x 5016`, renders at source size without stretching, and is sampled with `NEAREST` filtering.

## Source references

- The selected panorama originated from the archived repository implementation at `7-55-main/uploads/20260716/7_55_current_implementation_20260716/`.
- `source/mosaic/tile_01.png` through `tile_16.png` and `source/mosaic/zijingang_road_walkability_mask.png` belong to the alternate `3840 x 3840` mosaic and are not imported by application code.

## Generation contract

- GPT Image owns campus artwork generation. MiniMax remains audio-only.
- `npm run map:zijingang` verifies the selected repository panorama, its SHA-256, dimensions, and runtime coordinates without rewriting the asset.
- `npm run map:zijingang:mosaic` remains available only for rebuilding the alternate `3840 x 3840` candidate. Running it changes the active plate and therefore requires an explicit selection decision before delivery.
- All tiles use one strict 90-degree top-down projection, north-up orientation, palette, pixel density, light direction, and final scale. Facade elevation and isometric 45-degree views are not accepted.

## Selected panorama contract

- The selected plate SHA-256 is `63ff841fce9e29fd73775b6f42cf3ef65ae303993a55f3a555c90ec0a5ff98c2`.
- Phaser reads the `5016 x 5016` world, spawn, library entrance, landmarks, and collision arrays from `src/data/maps/zijingang-campus-runtime.json`.
- The archived runtime provides empty collision arrays; movement stays unrestricted until a collision map is calibrated against this exact panorama.
