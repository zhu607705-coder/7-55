# Source-pixel loop panorama tiles

The original `13668 × 1084` loop panorama exceeds Firefox's measured `8192` texture limit. The library/theater handoff can finish with every content family ready while the GPU background remains black. The source-pixel world, compressed walkability, perspective, foreground baselines, actors, checkpoints and controller remain unchanged.

`source_tiled_texture.gd` draws seven independent lossless PNGs. Each core is at most `2046 × 1084`; a one-pixel neighboring-source gutter on all sides produces physical textures no larger than `2048 × 1086`. Only outer source edges clamp. Core source rectangles remain contiguous and map into the original world with no resizing. `clip_uv=false` lets linear filtering sample the gutter; each piece inherits the same canvas filter. Both world base/foreground crops and the generic `c3_location` narrative art use this adapter. The Web preset excludes the giant GPU texture; its original file remains the synchronization/reconstruction oracle.

Godot 4 Web exports require WebGL 2 and the Compatibility renderer ([Godot export documentation](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_web.html#webgl-version)). The underlying [OpenGL ES 3.0.6 specification, Table 6.28, printed page 273](https://registry.khronos.org/OpenGL/specs/es/3.0/es_spec_3.0.pdf#page=285) specifies a minimum `MAX_TEXTURE_SIZE` of 2048. This addresses texture dimensions; it does not claim every minimum-spec physical mobile device has been tested.

Rebuild from the checked-in original source, without Godot import/export or image resizing:

```sh
node godot_native/tools/build_panorama_tiles.mjs
node godot_native/tools/build_panorama_tiles.mjs --check
```

The normal `node godot_native/tools/sync_source.mjs` chain generates these tiles after copying the original source assets. Native CI, Web builds and source packaging already run that full synchronization; prologue-only early exits do not generate unrelated assets. Derived PNGs retain the existing `assets/*` ignore policy and need not duplicate about 25MB in Git. The generator validates PNG CRCs, decodes RGB/RGBA source filters, writes lossless tiles, decodes its output again, and reconstructs every original source pixel before accepting the manifest. `--check` is read-only and also requires generated tile and manifest bytes to equal deterministic regeneration. `test_source_tiled_texture.gd` independently decodes them through Godot, verifies reconstruction/gutters, exact cross-tile foreground crops, bounds clipping, deferred-resource retry and the narrative consumer. `render_source_tiled_texture.gd` compares actual nearest/linear GPU rendering near every seam with small same-source reference crops; it never uploads the giant source texture.

The GPU-only `render_source_tiled_texture.gd` uses an explicit graphics launch; its name excludes it from the automatic `test_*` headless sweep. The source-pixel and Main consumer tests remain in that normal sweep. A graphics run must use the same isolated native test sandbox as other tests.
