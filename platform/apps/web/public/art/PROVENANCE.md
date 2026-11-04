# Display asset provenance

The user requested matching the 7:55 game's pixel style on 2026-10-23.

- `campus-night.png`: exact copy of `src/assets/rpg/cinematics/chapter4-prologue/pixel/lake_exit_a.png` at repository commit `32dfc73c113de980ca42b1c48a893d068e122127`. Display-only campus landscape, no story state or puzzle answers. Source is 960×540, preserve aspect ratio and pixel edges.
- `../fonts/fusion-pixel.woff2`: WOFF2 compression of that commit's `src/assets/rpg/fonts/fusion_pixel_12px_proportional_zh_hans.ttf`; glyphs unchanged. Original and component OFL licenses retained alongside. Conversion uses fontTools with Brotli.

These are standalone copies. Platform build and runtime never read the game's asset directories.
