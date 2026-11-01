# Future Learning Center local asset pipeline

This is a build-time route for the independent metric authoring viewer. It does
not introduce another gameplay controller or change the Godot game/save runtime.

## Deployment decision, checked 2026-11-02

The host is an arm64 Apple M4 Max Mac with64GiB unified memory. The APFS volume
reports1858.2GiB total and1321.9GiB free. Storage is sufficient; the blocker is the
official Hi3D inference backend, not disk capacity.

[Hi3D v1.0's official release](https://github.com/hi3d-official/Hi3Dv1.0) requires
Linux, Python3.10, NVIDIA compute capability8.0+, CUDA12.0–12.5, flash-attn,
spconv and Triton. It has no CPU inference path; no supported Apple MPS route is
provided. The highest1536³ mode was validated on a96GB H20. Minimum VRAM on
smaller cards is not established, so this is not a claim that every mode needs96GB.

The release refines an existing coarse mesh using a reference image. It outputs
geometry without textures/materials/vertex colors and normalizes world scale.
It cannot directly replace the quoted image-to-textured-PBR service pipeline.
See the [official scope](https://github.com/hi3d-official/Hi3Dv1.0#scope-and-reproducibility).
The publisher's2-million-asset training statement is not a local benchmark.
Its custom [Hi3D license](https://github.com/hi3d-official/Hi3Dv1.0/blob/main/LICENSE)
is not a blanket MIT/Apache license for the complete model release.

No incompatible CUDA installation or large model-weight download was attempted.
The user authorized Hyper3D as the fallback, and one standard-tier chair was
submitted. `hyper3d_chair_receipt.json` preserves the real task ID, original hash
and permanent result page. Resume/check that task; do not silently regenerate it.

## Inputs and provenance

- `sources/concepts/ergonomic_chair_turnaround_20261102.png` is an unbranded
  three-view concept generated with built-in imagegen. Its exact model version
  was not exposed by the tool; do not label it GPT-Image-2.5. The full image
  prompt is saved beside it.
- `sources/models/hyper3d_ergonomic_chair_original.glb` is the unmodified provider
  output:208132 triangles,4040632bytes,97 primitives. The service auto-selected
  n-gons. This is a new generic chair, not a scan/CAD file of a verified site chair.
- The provider delivered5 factor-based PBR materials and **no texture images**.
  Do not describe this job as providing a complete set of PBR texture maps.
- `sources/models/authored_ergonomic_chair.glb` preserves the earlier dimension-led
  local model as a comparison source. Existing caliper/screwdriver and other
  dimension-based assets remain reusable; new paid jobs are not needed per instance.

Provider output is tracked under the account/service terms; no open model license
is inferred from the GLB. The viewer uses locally vendored MIT Three.js and
Apache-2.0 Draco decoder files, with their notices. Credentials, presigned URLs,
login links and Feishu HTML are excluded from the project.

## Rebuild the local derivatives

Run from this art-source directory with Node and Blender installed:

```sh
npm ci --prefix pipeline
node pipeline/build_asset.mjs sources/models/hyper3d_ergonomic_chair_original.glb web/assets/models/ergonomic_chair/hyper3d 1.29 180
node pipeline/split_building.mjs
node pipeline/validate_asset.mjs
```

The optional comparison model can be re-extracted without modifying the master:

```sh
/Applications/Blender.app/Contents/MacOS/Blender --background --factory-startup --python scripts/extract_chair.py
node pipeline/build_asset.mjs sources/models/authored_ergonomic_chair.glb web/assets/models/ergonomic_chair/authored 1.29
```

The pipeline rejects rigs/animations. It uses a **uniform** height scale, grounded
center pivot and180° yaw correction for the generated chair's facing. It preserves
the raw source, then joins compatible materials, simplifies, and emits plain and
Draco GLBs. Actual levels—not just requested polygon targets—are in each manifest.
Open borders and the error cap can prevent reaching a requested triangle target.
The near generated level remains28616 triangles despite its20000 target.

Each compressed file is decoded again. Triangle counts must match its plain
counterpart and encoded envelope error must stay below1mm. Absolute scale comes
from the selected1.29m reference height, not an on-site measurement. Derived
near geometry is approximately708×663×1290mm.

Draco reduces storage/transfer, not triangles, draw calls or GPU cost. See
[glTF Transform simplification](https://gltf-transform.dev/modules/functions/functions/simplify)
and [Three.js decoder guidance](https://threejs.org/docs/pages/DRACOLoader.html).

## Viewer behavior and acceptance

The default viewer uses the generated chair. `?chair=authored` compares the earlier
local chair. One Draco decoder loads the three levels asynchronously.124 ordinary
chairs use shared geometry in per-floor, per-material instance batches; one3F
chair remains separately inspectable. The originals'125 transforms and metadata
are retained in `building.web.glb`; the full `building.glb` is unchanged.

Projected chair height selects LOD0 at150px or more, LOD1 at55px or more, and
LOD2 below55px. A per-chair camera-frustum test excludes off-screen instances.
This also excludes their off-screen shadow contributions, so the viewer remains
an architectural review, not a final light-baking acceptance. A missing optional
asset/decoder/assembly falls back to the full authored building furniture.

`scripts/test_asset_pipeline.mjs` verifies real WASM decoding, near/far selection,
ordinary movement and inspection, mobile fit and an injected missing-LOD fallback.
Existing furniture/browser/material/collision checks are run for the final viewer.
The screenshot review covers front/back/room scale. Fine woven geometry still
needs material/antialias refinement; factor-only PBR is not final texture approval.

Profiling uses headless local Chrome at1280×800, DPR1,90rAF samples per route.
The baseline and candidate reports record submitted triangles, draw calls, CPU
task duration, frame interval and asset transfer separately. These capped local
samples do not establish a higher FPS or physical-mobile acceptance.

This pass implements the reference→Hyper3D→local LOD/Draco→Three.js asset path.
Music, sea shaders and particle systems are not part of the current FLC chair
integration. Native Godot export/release acceptance remains separate.
