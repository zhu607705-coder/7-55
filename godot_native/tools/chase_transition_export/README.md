# Deterministic native chase transition extraction

This build tool reads the existing TypeScript transition renderer and original Quaternius GLB. It never renders WebGL pixels and does not provide source screenshot evidence. A no-op renderer adapter records the exact source rig/IK, node transforms, cameras, visibility, geometry and materials.

Requirements for regeneration: full original repository, its locked Node dependencies, Python with Pillow, NotoSansCJK Regular at the path in node_adapter.ts, and Godot 4.6.3. Runtime playback needs none of these build tools; it uses the generated native scene and frame tables. Building on another OS requires choosing an equivalent label font backend; glyph rasterization remains an explicit comparison limitation.

From repository root, one process at a time:

1. node godot_native/tools/chase_transition_export/build.mjs
2. node godot_native/tools/chase_transition_export/export_source.mjs
3. POSE_ONLY=1 node godot_native/tools/chase_transition_export/export_source.mjs
4. python godot_native/tools/chase_transition_export/compact_manifest.py
5. godot --headless --editor --path godot_native --import
6. godot --headless --path godot_native --script res://tools/chase_transition_export/bake_geometry.gd

Do not use imported glTF clip interpolation for playback: Godot's default resampling/optimization changed the source contact poses. The runtime binds exact24 fps source node/bone matrices directly. A fixed imported-bone bind-axis correction preserves the original skinned mesh. Runtime uses source_runtime.json (7 visibility flags) instead of the full1801-node debug snapshot. The compactor proves identical visibility for all 224 frames.

The batch keeps original triangle topology, UVs, colors, material properties and texture bytes. Non-uniform normal transforms use inverse-transpose; SurfaceTool.append_from's ordinary-basis normal transform is not used. Dynamic rider, bicycle and NPC geometry/skins remain unchanged. No collision, simulation, proof or progression code is part of this exporter.

Rendering remains under visual review. Actual original WebGL pixel comparison was blocked by the browser extension. Godot light radiance uses the documented1/PI conversion; PBR/ACES, hemisphere/fog adaptation and label rasterization are still comparison boundaries.
