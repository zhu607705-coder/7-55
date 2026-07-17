# Zijingang Campus Artwork

## Runtime ownership

- `zijingang_campus_plate.png` is the cohesive pixel-art world plate used by Phaser.
- The plate contains terrain, roads, water, bridges, buildings, and vegetation only.
- Phaser owns the player, collisions, foreground occlusion, labels, interaction targets, task markers, and story transitions.
- The world plate is authored at `2400 x 1920` and is sampled with `NEAREST` filtering.

## Source references

- `source/zijingang_official_map_reference.png` is a stitched WMS reference from the official Zhejiang University map service.
- `source/zijingang_official_hotspots_reference.json` is the official WFS feature snapshot used to measure named-building centers and footprints.
- `source/zijingang_reference_{nw,ne,sw,se}.png` are overlapping generation references.
- Official references never become runtime backgrounds and are not imported by application code.

## Generation contract

- GPT Image owns campus artwork generation. MiniMax remains audio-only.
- Generate four overlapping sectors from the shared spatial model, then crop and stitch them into the runtime plate.
- All sectors use one strict 90-degree top-down projection, north-up orientation, palette, pixel density, light direction, and world scale. Facade elevation and isometric 45-degree views are not accepted.
- Update `ZijingangWorldModel.ts` collision and trigger geometry whenever the stitched plate changes.

## Four-sector pipeline

- `sectors/manifest.json` fixes the world at `2400 x 1920` and divides it into `NW / NE / SW / SE` sectors.
- Every sector is `1320 x 1080`; adjacent sectors share `240px` of overlap on both axes. Roads, water edges, bridges, and building footprints inside each overlap must be repeated from the same coordinate template.
- `npm run map:zijingang:split` creates four exact fallback crops from the current plate. GPT Image outputs can replace those files only when they retain the same dimensions and crop coordinates.
- `npm run map:zijingang:stitch` recomposes the four sectors with feathered overlap. Use `npm run map:zijingang:stitch -- --normalize-palette` when separately generated sectors require one shared 192-color palette.
- The stitched image never owns collision or trigger logic; Phaser continues to read those from `src/data/maps/zijingang-campus-runtime.json`.
