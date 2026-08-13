# Chapter 4 stair material set

The runtime consumes the checked-in `1K-JPG` maps in this directory. It never
loads textures from the network while the game is running, so the standalone
single-file build remains offline-capable.

Source assets:

- `Plaster001` from <https://ambientcg.com/a/Plaster001>
- `Concrete010` from <https://ambientcg.com/a/Concrete010>
- `Metal012` from <https://ambientcg.com/a/Metal012>

All three assets are distributed by ambientCG under `CC0-1.0`. The official
license page explicitly permits modification, redistribution, commercial use,
and inclusion of the raw files in a video game:
<https://docs.ambientcg.com/license/>.

`manifest.json` records every runtime file, byte size, SHA-256 checksum, source
page, download package, material role, color-space rule, and sampling policy.
The checked-in color maps are retained without image-generation or resampling
changes. At runtime, the renderer builds one `64x64` tile per material in
memory. Color is reduced to a small grayscale luminance palette and then
modulated by the existing Chapter 4 palette. Plaster stays in the restrained
`248-255` range, while concrete and metal retain stronger discrete detail, so
photographic source detail does not introduce a competing visual style.
Normal, roughness, and metalness maps stay
outside the runtime because continuous PBR lighting conflicts with this game's
hard-edged pixel rendering.
