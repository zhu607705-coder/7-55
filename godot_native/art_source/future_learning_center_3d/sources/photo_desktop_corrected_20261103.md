# Photo desktop correction, 2026-11-03

## Evidence and bounded changes

The original desktop photograph was inspected before this correction. Its visible tabletop is pale warm wood, while the existing 1400×600×35 mm height-adjustable tabletop uses the near-white `Warm desk` material. `web/photo_desk_materials.js` supplies a separately cached material for photo-bound tabletops only. It changes colour and roughness, not desk dimensions, lift columns, controls, collision or moving parts. The colour is an approximation under unknown photographic lighting, not a measured colour or a wood-species identification. No private photograph is shipped as a texture. The helper intentionally does not invent grain, logos or additional structural details.

For the mouse, the original source's top and side renderings were directly compared with the official Logitech PRO X SUPERLIGHT 2 gallery:

- Product page: https://www.logitechg.com/en-us/shop/p/pro-x2-superlight-wireless-mouse.910-006628
- Top: https://resource.logitechg.com/content/dam/gaming/en/products/pro-x-superlight-2/new-gallery-assets-2025/pro-x-superlight-2-mice-top-angle-black-gallery-1.png
- Side: https://resource.logitechg.com/content/dam/gaming/en/products/pro-x-superlight-2/new-gallery-assets-2025/pro-x-superlight-2-mice-profile-left-angle-black-gallery-4-2-award.png

The old top outline had a pointed tail, the wheel opening had angular ends, and the side buttons were small rectangular blocks. The new independent source uses a curved nose and elliptical tail, a rounded elongated wheel opening, and curved capsule-shaped side buttons following the flank. These are silhouette corrections, not a claim that the photograph uniquely establishes a product generation. No logo or guessed charging port was added. The pale/coral colour treatment from the prior photo candidate is retained; the black official image supplies shape evidence, not colour evidence.

## Deliverables and metric contract

- Builder: `scripts/build_photo_mouse_corrected.py`, self-contained; no frozen-source import at build time.
- Source: `sources/models/photo_desktop_corrected/photo_mouse/photo_mouse.blend` plus `lod0_source.glb`, `lod1_source.glb`, `lod2_source.glb`.
- Runtime: `web/assets/models/photo_desktop_corrected/photo_mouse` with manifest and three plain/Draco LOD pairs.
- Exact intended envelope: Blender XYZ=63.5×125×40 mm; glTF XYZ=63.5×40×125 mm. Blender front is −Y; glTF front is +Z. Runtime pipeline yaw is zero.
- Sub-millimetre detail overshoot is baked into the source envelope. Scene integration must not normalize or reshape the asset.

## Validation performed

Blender source export completed for all three levels. Independent NodeIO/Draco reading checked actual decoded positions, triangle areas, finite attributes, normal lengths, normal-angle differences, geometry bounds and both directions of decoded/plain vertex comparison. All passed. Runtime triangle counts are 20086 / 7997 / 1996. Maximum decoded/plain bounds difference is below 0.000000075 m. Full numeric results are in `review/photo_desktop_corrected/source_vs_draco.json`.

CPU Cycles top and side views were rendered and visually inspected after the final rebuild. The rounded tail, rounded slot and capsule buttons are present; whole-mouse framing is retained. Files: `review/photo_desktop_corrected/mouse_top.png` and `mouse_side.png`. The first render attempt failed because this Blender build lacks OpenImageDenoise; rerunning with denoising disabled succeeded. No access restriction was involved.

The material helper's clone isolation, cache reuse and tabletop-only name matching were tested with Node assertions. It remains an integration helper; browser-level material appearance, mouse facing and desk scale belong to the actual viewer acceptance pass.

## Reproduction

From art root:

    blender -b -t 3 --python scripts/build_photo_mouse_corrected.py
    node pipeline/build_asset.mjs sources/models/photo_desktop_corrected/photo_mouse/lod0_source.glb web/assets/models/photo_desktop_corrected/photo_mouse 0.04 0 1024 sources/models/photo_desktop_corrected/photo_mouse/lod1_source.glb sources/models/photo_desktop_corrected/photo_mouse/lod2_source.glb 18
    node review/photo_desktop_corrected/validate_runtime.mjs
    blender -b -t 3 --python review/photo_desktop_corrected/render_views.py

No frozen recovery source, published tree or viewer.js was edited by this worker, and no push was performed.
