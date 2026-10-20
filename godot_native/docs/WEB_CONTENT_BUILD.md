# Godot Web content-pack build

`tools/build_web.mjs` keeps the existing command-line options. Its default output
is a split delivery of the independent Godot runtime:

```sh
GODOT_BIN=/path/to/Godot node godot_native/tools/build_web.mjs \
  --output=godot_native/exports/web-streaming
node godot_native/tools/build_web.mjs \
  --verify-only --output=godot_native/exports/web-streaming
```

The build exports the complete Godot project first and checks all required
campuses, formal scenes, production features and resource exclusions. It then
uses `plan_web_content.mjs --startup=conservative` and official Godot
`PCKPacker` to produce one boot core and deferred packs of at most 24,000,000
bytes each. This repackages existing bytes without changing `res://` paths,
controllers, item data or save data.

The published directory contains:

- `index.pck`: the boot core, including the main/entry/state scripts, shared data,
  fonts and resources selected by the conservative startup dependency scan.
- `content/<group>-<sha256-prefix>.pck`: immutable deferred chapter/campus packs.
- `content-manifest.json`: the `755-web-content-v1` transport manifest consumed
  by the browser loader and native resource coordinator.
- `content-inventory.json`: every full-export resource path, original size,
  MD5, SHA-256 and single owning pack, plus full-export provenance.
- `content-loader.js`: copied from the tracked `web/content_loader.js` input.
- The existing Godot engine, worklets, HTML and build/source/core inventories.

The complete original PCK, grouping plan, official packer/mount-verification
logs and each intermediate pack inventory remain outside the published
directory under `exports/verification/godot-web-build/`. The website therefore
does not publish a second complete PCK.

`--verify-only` checks every published file hash, the source-input digest,
complete-entry coverage, unique pack ownership, payload MD5/SHA-256, pack
filenames and individual deferred-pack budgets. A missing, duplicated, changed
or unlisted pack fails verification. It does not rewrite build provenance.

`build-manifest.json` reports `initialPayloadBytes` separately from
`totalPayloadBytes`; splitting does not reduce the total authored content.
`pack` describes the core; `fullPack` and `content` describe the original export
and complete partition. `sourceDirty` continues to reflect the actual checkout.

`--monolithic` is retained only to inspect an internal full-export intermediate;
it is not the default production delivery and is not a replacement release.
Packaging checks do not prove browser startup, chapter transitions, interrupted
download recovery, caching, audio behavior or mobile performance. Those require
the separate browser acceptance gate against the final split output.

Focused packer checks, including an actual Godot missing-pack negative control:

```sh
GODOT_BIN=/path/to/Godot node godot_native/tools/test_partition_web_pack.mjs
```
