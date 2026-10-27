# Actual 3D rendering, same paper experiment

The previous accepted spatial prototype used 2D CanvasItem polygons and a shared
mathematical projection. Its GL capture proved visible output, not real light /
material / shadow rendering. This revision replaces physical scene drawing with
MeshInstance3D, Camera3D, StandardMaterial3D and DirectionalLight3D shadows.

## Kept exactly

- Existing paper Model, touch ownership, cancellation, retry, explicit collect,
  and no formal story/save integration.
- User-recognized orthographic elevation 50° / yaw 8°, same world dimensions,
  planar contact and world→screen mapping. No perspective change to fit textures.
- Original PNG bytes and measured Atlas crop / pocket seam; no generated edits.

## Small render scene

- World coordinates (x, depth, height) become Godot (x, height, depth) / 100.
- Real thick table, wall with an actual window opening, frame/mullions/sill,
  folder base, two separately culled cover faces rotating about a real hinge,
  raised pocket and alpha-cutout paper meshes.
- One shadow-casting directional light plus uniform ambient light. Rough opaque
  room materials and alpha-scissor artwork use ordinary depth testing. No fake
  painted contact shadow, DOF, SSAO, bloom, ray tracing, or global illumination.
- Only the distant foliage image is intentionally unlit; it is a background,
  not a claim that an exterior campus has been modeled.
- Current and recorded views have separate World3D, camera, nodes and mutable
  materials. The outer clipped 2D observation window samples the recorded
  viewport. It never changes the live model, nodes, or input ownership.
- Closed pocket compresses below the cover; open pocket returns to the same
  approved 12-unit occlusion plane. This does not alter catch logic or paper path.

## Evidence

The local harness adds 28 checks to the existing 221: Camera3D projection and
ray-plane inverse at 390×844 / 320×568 / 844×390; distinct worlds/materials;
record-time isolation; surface normal; shadow/alpha settings; closed/open pocket
stacking; bounded mesh count. Headless checks do not establish visible shading.

The hosted real-render test retains five history pixel/ownership checks and adds
actual light-off and shadows-off image comparisons. Those are ordinary render
outputs, not illustrative recolors. The recording still performs six normal
input-flow assertions and labels automated dual-touch, not physical phone input.

First actual 3D preview: 0d14ed9, run 40325449516. It revealed shadow acne and the
closed-pocket height issue; it is superseded by the corrected preview, not final
visual acceptance. Corrected preview: 27e8b4f, run 40326253437 (result recorded in
the delivery receipt after actual inspection).

## Limits

This is a small rasterized lighting scene, not photorealistic/path-traced output
or a physically simulated flexible sheet. Both full-size viewports are bounded
but have not been performance-tested on a physical phone. Fine art/material
refinement, clipped receiver and formal story integration remain separate.
