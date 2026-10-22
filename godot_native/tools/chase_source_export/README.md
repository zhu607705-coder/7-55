# Original 755 riding-resource extraction

These tools execute the checked-in TypeScript geometry/rig code offline. The WebGL renderer is replaced only for extraction; no browser pixels are produced. Runtime rendering is native Godot and uses the generated packed scenes and exact source pose tables.

Requirements: repository locked Node dependencies (esbuild/three), Python with Pillow, NotoSansCJK-Regular for the source sign labels, and official Godot 4.6.3. From the repository root, run one process at a time:

1. `node godot_native/tools/chase_source_export/build.mjs`
2. `node godot_native/tools/chase_source_export/export.generated.mjs`
3. `node godot_native/tools/chase_source_export/export_rider.generated.mjs`
4. `node godot_native/tools/chase_source_export/export_people.generated.mjs`
5. `node godot_native/tools/chase_source_export/export_effects.generated.mjs`
6. `node godot_native/tools/chase_source_export/export_gust.generated.mjs`
7. `godot --headless --path godot_native --script res://tools/chase_source_export/import_source.gd`

Intermediate GLBs/data are written beneath `godot_native/.chase-source-export`. Native scenes/data go to `assets/native_755/ride`. The importer skips existing packed scenes; use a fresh destination when regenerating. Compare source geometry/pose tests rather than assuming native container bytes are stable across importer versions. Optional CANTEEN_SOURCE_ROOT and CANTEEN_NATIVE_ROOT select source and generated-resource roots. Static source imports remain relative to the repository.

The source world is batched with the original merge implementation in bounded 24-unit chunks. No triangle, texture or rig simplification occurs. The rider uses a 21-steer by 97-phase sample grid from the original IK; roadside actors retain original meshes and Walk animation samples. The separate transition exporter retains the authored24 fps frame domain. Each rig keeps its own skeleton, Skin and bind-axis correction.

Generated JavaScript bundles and intermediate GLBs are build products, not runtime or tracked source. The original Quaternius CC0 GLB already belongs to the source repository and is not duplicated here. Runtime shader code is shared. Exact cross-scene ArrayMesh storage differs after import; no unproven mesh substitution was made. The complete ride rider scene is501657bytes, including its own bindings; the18MB transition extraction GLB is not a runtime dependency.
