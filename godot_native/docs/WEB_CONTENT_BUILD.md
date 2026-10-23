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
`PCKPacker` to produce one boot core and deferred packs targeting 6,000,000
bytes each. A single indivisible resource may occupy a larger pack by itself,
with an explicit `sizeException` receipt; the hard limit remains 24,000,000
bytes. Size-descending, then English path order, followed by first-fit packing
gives deterministic membership for identical input. It does not promise stable
membership after a resource is added or changes size. This repackages existing bytes without changing `res://` paths,
controllers, item data or save data.

Cache reuse is based on verified content identity, not on the chapter name.
The first upgrade from the former 24 MB grouping changes PCK membership and
hashes, so previously cached whole chapter packs cannot satisfy the new packs.
Unchanged boot chunks remain reusable. Subsequent retries reuse verified static
slices and complete packs with matching identities; interrupted, unverified
bytes are downloaded again. This pass keeps the existing chapter-family entry
gates, so smaller transfers do not reduce the total resources required to enter
a chapter.

The published directory contains:

- `index.pck`: the boot core, including the main/entry/state scripts, shared data,
  fonts and resources selected by the conservative startup dependency scan.
- `content/<group>-<sha256-prefix>.pck`: immutable deferred chapter/campus packs.
- `content/chunks/<group>-<index>-<sha256-prefix>.bin`: 1 MiB static slices only
  for the single-resource packs above the 6 MB target. The complete original
  PCK remains available; ordinary packs have no duplicate transport files.
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
The optional v1 `packPolicy` declares the new target and hard limit. Each large
pack's `transportChunks` table is checked against the original PCK byte for byte,
including offset continuity, final length, each slice hash, reconstructed PCK
hash, exact directory membership and regular-file types. Do not name the field
`chunks`: older loaders reserve that name for boot resources. They ignore
`transportChunks` and keep using the full PCK. Existing manifests without the new
policy remain verifiable under their original 24 MB budget.

`build-manifest.json` reports `initialPayloadBytes` separately from
`totalPayloadBytes`; splitting does not reduce the total authored content.
The site budget counts both complete originals and transport slices and remains
950,000,000 bytes. `logicalPayloadBytes` removes only the duplicate boot and
deferred transport copies. All deferred PCKs and slices stay outside the initial
payload. The small content manifest itself remains part of startup delivery.
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
node godot_native/tools/test_web_content_chunks.mjs
```
