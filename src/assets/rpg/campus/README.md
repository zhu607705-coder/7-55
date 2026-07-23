# Zijingang Campus Artwork

## Runtime ownership

- `zijingang_campus_plate.png` is the only campus panorama loaded by Phaser. Its approved dimensions are `11744 × 1084`; runtime code does not position or scale the nine source scenes independently.
- The plate owns buildings, roads, lake, sidewalks, landscaping, and other static artwork. Phaser owns the player, fixed foot collision, vertical perspective scale, camera, labels, interactions, and story transitions.
- The world renders from this source coordinate system without stretching. The campus minimap is intentionally absent.

## Visual contract

- The plate uses one continuous wide `2.5D` pixel-art panorama. The player grows uniformly toward the lower foreground through the shared perspective curve in `RpgPlayerTextures.ts`.
- The west and middle joins use source-aligned local transitions. The former east joins at world `x=8939` and `x=10133` are replaced by one continuous regenerated campus strip. Sky, treeline, lake bank, water, sidewalk, curb, road surface, and lane markings remain continuous across every join.
- The upper sky uses one coherent colour treatment across the final plate; gray placeholder bands are prohibited.
- GPT Image owns campus artwork editing. MiniMax remains audio-only.
- Do not run the retired square `4×4` panorama builder against this asset. It uses a different `5016 × 5016` coordinate system.

## Collision and entrance contract

- `zijingang_road_walkability_mask.png` is the reviewable nearest-neighbor expansion of the runtime `4px` collision grid.
- The continuous foreground road and sidewalk surface starts at source `y=864`; this keeps the canonical player foot box on the visible paving at the `y=842` story checkpoint. Lane markings, drains, curb shadows, and scene joins cannot create collision holes.
- Seven source-pixel entrance approaches connect the foreground promenade to the visible canteen and campus-building doors: three measured rectangular forecourts and four public-path polygons. The foundation-library route follows the real L-shaped paving through the right-side gap and door forecourt; its interaction gate is `(9000,770)` and safe approach checkpoint is `(9070,770)`.
- The central and east flower beds below the foundation-library forecourt remain blocked.
- `npm run map:zijingang:rebuild` and `npm run map:zijingang:walkability` both run `scripts/calibrate-wide-campus-runtime.py`. The script preserves the approved artwork, rebuilds the complete promenade and entrance geometry, regenerates the compressed bitset, and synchronizes plate/mask hashes.
- `npm run map:zijingang` is read-only. It verifies dimensions, the selected plate hash, runtime coordinates, the bitset, the mask hash, all seam-crossing sidewalk samples, every entrance approach, and representative blocked scenery/prop samples.

## Current selected asset

- Plate SHA-256: `6dc300c8812ca95340824a08649478443e37b5b4a1789e0b64bb86261d032741`.
- Runtime manifest: `src/data/maps/zijingang-campus-runtime.json`.
- World: `11744 × 1084`; walkability grid: `2936 × 271`; cell size: `4px`.
