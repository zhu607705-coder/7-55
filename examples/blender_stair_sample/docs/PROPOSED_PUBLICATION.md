# Standalone Draft PR publication scope

Target prefix: `examples/blender_stair_sample/`

This scope is being saved on a new work branch and Draft PR against `godot-version`. No merge, deployment, campaign integration or modification to PR143/147 is included.

Include:
- README and asset provenance/license notes
- `source/stairwell_sample.blend` and `source/build_stair_sample.py`
- `preview/project.godot`, scene, scripts and sample data manifest
- `preview/assets/blender/` model, material textures and GLB import metadata
- Existing player/guard/jump pixel assets and the preserved font license
- Only the sample-scoped tests, capture harness and optional performance harness
- Final verification JSON, small test logs and file hashes

Exclude:
- `.godot/`, runtime user data, Xorg configuration/authentication, caches and recordings
- `.blend1` automatic backups and temporary integration scripts
- Videos, screenshots, AVI intermediates and ZIP artifacts
- Old twelve-flight tests/docs that assert a complete level
- Any production-file changes outside this independent example directory

One new path-filtered workflow, `.github/workflows/blender-stair-sample.yml`, imports and tests this isolated example. Existing general workflows are unchanged.

The exact publication paths are listed in `PROPOSED_PUBLICATION_FILES.txt`.
