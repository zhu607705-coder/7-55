# Campus-letter 3D play review — current user-directed revision

The user rejected both flat pixel diagrams and the subsequent distant diorama camera. Latest binding brief:
- First-person, normal human eye height for all actual operation and gameplay.
- Separately switchable third-person scene overview only.
- Detailed independent objects, credible geometry/materials/scale. Reuse existing rigged campus student and environment assets, refine others in Blender.
- No text on objects, no floating world labels. Object explanation goes in the fixed UI inspector.
- Four fully playable standalone samples: library seat lifecycle; lake survey wheels; paper bridge loading; sculpture lighting/cooperation.
- Actual game captures replace the final four sample figures in the existing proposal PDF.

Code-led native Godot 4.7.1 build, locally served at http://127.0.0.1:8795. This scoped new world overrides the parent game's pixel brief, without changing formal main-story saves or release entry.

Art direction: campus interiors and a physical outdoor installation; satin ash wood, muted green enamel, machined metal, daylight with warm local light. Source geometry includes rounded furniture, supports with adjusting knobs, lathed weights, a detailed projector, handwheel assemblies, and cast hands extracted from the existing rigged student. All have individual scene nodes and separate picking proxies. Read PRODUCT.md and AGENTS.md in this directory.

Current native captures /tmp/letter3d-{library,liuhu,bridge,light}.png will be refreshed at the finish gate. Browser acceptance captures belong under exports/verification/campus-letter. Older flat sample screenshots are rejected, not reference truth. No approved static comp is applicable: user directly prescribed the view and model revision.

Check the first-person entry/action/overview/return paths, pick vs camera-drag ownership, readable fixed UI and responsive screen bounds. Inspect the actual source and runnable build; distinguish browser emulation from physical-device acceptance. Report concrete remaining issues, not a generic styling checklist. Do not write code or alter main-game visual rules.


Latest user revision: no explanatory text is needed in the default scene (not a request to remove people). Header explanations, footer commentary, hover labels and help entry are now hidden; only navigation and locomotion remain. Material/rendering refinement must use real internet references and more detailed geometry. REFERENCES.md lists HAY, Nikari, Anglepoise, ERCO and the actual ambientCG CC0 material sets. Inspect final updated browser captures, not older captures with the explanation footer. Indoor ceilings and east/south walls hide only in overview; actual play remains first person with an enclosed room. No world Label3D exists.

Latest material family uses shared Wood051, Concrete034, Metal032 and Fabric041 color/normal/roughness channels as appropriate. Curved seats, rounded worktable edges, machined weights, knurled support wheels, articulated reading lamps, separate cloth/paper book layers and cast-hand subdivision are exported from Blender 5.2.2. Editable packed source is authoring/campus_objects.blend (excluded from runtime import with .gdignore). Source GLB mesh counts are in assets3d/detail/mesh_metrics.json.

2026-11-07 最新现场反馈：移除当前黑衣人物及其在四样段的复用。母校之光由可见的实体信箱承接来信投递；不设置不可见人物接收区。
