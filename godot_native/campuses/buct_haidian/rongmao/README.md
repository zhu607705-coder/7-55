# Rongmao fixed RGBA object

The body, limited ground and short contact-shadow PNGs were generated through the project-authorized image-editing workflow on 2026-10-12 from its Haidian campus art. Original PNG bytes are preserved and SHA-256 hashes are in data/library-profile.json. Generated completion behind formerly occluded surfaces is artistic inference, not surveyed architecture. The Rongmao name follows the official historic campus reference already cited in the campus source provenance.

Selection uses visible body alpha only. Shadows and transparent rectangle do not select. Body RGB uses mipmap sampling and alpha uses LOD0. All image-to-world transforms are uniform. The 141-source-pixel ground mask is a technical usage limit, not generated art. The hidden 13997-pixel core is an approximate native paving support, not a complete clean plate. Therefore this ordinary building is fixed: no library hide/move controls or whole-removal claim.

The compact renderer shares one full body texture, one 1115-sample RF footline and three mutually exclusive depth passes. It retains exact per-column feet, rather than approximating a slope with a few horizontal baselines. Only actor feet and the relevant nearby south-tree baseline enter the pass intervals. Multi-courtyard/multiple-footline-in-one-column buildings require a separately certified surface field; they are outside this contract.

Runtime costs and verification are recorded in the parent campus README. No new interior, route speed, character collision or story/save state is introduced. Source PNG dimensions, raw hashes and registration are authoritative; imported ground texture may use a lower sampling resolution without changing the logical world rectangle.

## Packaged resource validation

Both Haidian building loaders validate a loadable Texture2D and its expected imported dimensions before installation. If its original PNG is present, SHA-256 must still match the profile. Exported packages may contain only the .import remap and .ctex: absence of the raw PNG alone is not failure. Missing, unloadable, wrong-sized resources and corrupt available source bytes fail closed. This does not add source PNGs to export include filters. The ground import is238×256 while its logical registration still derives from the unchanged1210×1300 original.

Release regression: an actual6696-byte PCK containing the production validator and a54×58 imported texture passed20checks over9cases. Valid imported texture without source PNG is accepted; missing/corrupt ctex, wrong dimensions/type and corrupt available PNG are rejected. Eight loader ERROR lines are intentional failures in the two broken-resource fixtures. The subsequent production72-check Haidian test passed with zero unexpected errors,513physics ticks and0illegal feet. Read-only source checks: Haidian395, shared student37, Changping74. No export include filter or PNG bytes changed.

### Reproduce the packaged-source regression

From the repository root, with Python3 and official Godot4 installed:

```sh
python3 godot_native/tools/test_buct_texture_package.py --output-root /path/to/owned/workspace/qa
```

`--godot /path/to/godot` may select an existing executable. The runner creates a fresh `buct-texture-package-*` child directory; it never removes or overwrites the supplied root. All temporary files and XDG state stay in that child. Existing54×58ctex cache is reused when present. Otherwise only that one small technical mask is imported into an isolated miniature project, never the full game. The actual test runs another empty project with the generated PCK mounted, ensuring the omitted source cannot leak in from the importer directory.

The public builder and20-check test are in `tests/build_buct_texture_package.gd` and `tests/fixtures/buct_texture_package.gd`. Outputs include the tiny PCK, setup/case JSON and logs; none is a committed fixture. Nine cases cover valid source-less texture, valid source-present texture, corrupt available PNG, wrong hash, wrong dimensions, missing resource, missing imported payload, corrupt imported payload and wrong resource type. Expected ERROR logs from the deliberately broken imported resources are not production failures. This test is separate from the72-item campus check; that check alone does not exercise a source-less package. No CI workflow is changed.

The public command above was also executed from a cold cache on2026-10-12:20/20checks passed in a6632-byte PCK after importing only the54×58mask. The valid case confirmed source PNG absent, the test project contained no loose PNG, and no save files were created.

The packaged-only case script is under `tests/fixtures/` so the ordinary aggregate runner does not launch its deliberately invalid-resource cases outside their isolated PCK.
