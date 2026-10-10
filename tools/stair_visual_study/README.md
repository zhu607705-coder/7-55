# Stair visual study: source-faithful Blender checkpoint

This is a reproducible **architectural study**, not a game replacement. Review the rendered sample before integrating assets or merging. The current HTML remains unchanged.

## Which scene this addresses

- HTML `media-v2/stairs3d-clean` is the original `stair_b` misaligned-stair puzzle. The snapshot and orthographic camera here reproduce that scene.
- HTML `media-v2/chase-clean` is the older top-down stairwell chase.
- PR #106 is a separate four-fold oblique chase prototype and is not the right-hand HTML clip. Its warm flashlight, tiny blue phone light, controls, collision, and proof model are unchanged by this study.

The source snapshot preserves platforms, treads, mechanism owners, state transforms and navigation records. Perspective puzzle links remain the original model's responsibility. A screen-space overlap is not a new physical passage. No collider or navigation edge is generated here.

## Reproduce

Requires Blender 4.3 (tested 4.3.2, installed distribution).

```
blender --background --factory-startup -t 1 \
  --python tools/stair_visual_study/build_stair_sample.py -- \
  --output /tmp/755-stair-study --variant structure --render
```

Outputs: editable `.blend`, PNG and geometry/camera manifest. This checkpoint uses provisional grey materials. `--variant source` keeps the original abbreviated rail treatment for comparison. Both use the same original camera, projection, world coordinates and mechanism state.

37 checks run against actual Blender transforms before saving: source platform position/height, transformed navigation nodes, and orthographic projection. The verified build generated 139 objects and a 640×360 CPU render. Denoising is disabled because this Blender build lacks OpenImageDenoise. No Godot gameplay tests are claimed for this asset-only checkpoint.

## Provenance and limits

- Base: `godot-version` 913bd512c19c70e842461e0357091dca3635d389
- Original level definitions: `src/tools/chapter4-stair/levels.ts`, blob `9c6de2e210c8dae16683c4bad38e6b027bf9c32e`
- Original engine: `src/tools/chapter4-stair/engine.ts`, blob `c812b72369695f2693b9f68784e600200d140466`
- Snapshot extracted from the existing generated `chapter4-native-source.json`; its full SHA-256 is recorded inside the snapshot.
- Original campus references: `src/assets/rpg/interiors/finale/finale_stairwell.png` and `teaching_building_floor_2.png`.
- The separate web-generated concept is an appearance reference only. Its narrow door landing and incorrectly joined rail are not production geometry.
- Monument Valley reference principles: orthographic spatial relationships, clean layering and a readable architectural composition. No third-party images, characters, level layouts or assets are included. Official references: https://ustwogames.co.uk/our-games/monument-valley/ and https://ustwo.com/blog/monument-valley-out-now/

Next: pixel material study aligned with the reviewed campus concept; exportable assets; an isolated native render; door/rail clearance and collision checks before gameplay integration. User preview approval remains required before merge.
