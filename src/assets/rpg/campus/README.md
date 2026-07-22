# Zijingang Campus Artwork

## Runtime ownership

- `zijingang_campus_plate.png` is the only campus panorama loaded by Phaser. Its approved dimensions are `11744 × 1084`; runtime code does not position or scale the nine source scenes independently.
- The plate owns buildings, roads, lake, sidewalks, landscaping, and other static artwork. Phaser owns the player, fixed foot collision, vertical perspective scale, camera, labels, interactions, and story transitions.
- The world renders from this source coordinate system without stretching. The campus minimap is intentionally absent.

## Visual contract

- The plate uses one continuous wide `2.5D` pixel-art panorama. The player grows uniformly toward the lower foreground through the shared perspective curve in `RpgPlayerTextures.ts`.
- The museum join at world `x=7079` has one locally generated and blended transition. Sky, treeline, lake bank, water, sidewalk, curb, road surface, and lane markings must remain continuous there.
- GPT Image owns campus artwork editing. MiniMax remains audio-only.
- Do not run the retired square `4×4` panorama builder against this asset. It uses a different `5016 × 5016` coordinate system.

## Collision and entrance contract

- `zijingang_road_walkability_mask.png` is the reviewable nearest-neighbor expansion of the runtime `4px` collision grid.
- The foundation-library approach follows the visible clear stone path at `x=9072..9172`, from the road to the building front. The interaction gate is `(9120,780)` and the safe approach checkpoint is `(9120,824)`.
- The flower beds immediately west and east of the approach, plus the lamp at the east edge, remain blocked.
- `npm run map:zijingang:rebuild` and `npm run map:zijingang:walkability` both run `scripts/calibrate-wide-campus-runtime.py`. The script preserves the approved artwork, recalibrates the measured entrance corridor, rebuilds the compressed bitset, and synchronizes plate/mask hashes.
- `npm run map:zijingang` is read-only. It verifies dimensions, the selected plate hash, runtime coordinates, the bitset, the mask hash, the complete entrance corridor, and blocked planter samples.

## Current selected asset

- Plate SHA-256: `9bb6c5593697601fa1347655e43dc563bbc2e32768987df2d602aca31f525986`.
- Runtime manifest: `src/data/maps/zijingang-campus-runtime.json`.
- World: `11744 × 1084`; walkability grid: `2936 × 271`; cell size: `4px`.
