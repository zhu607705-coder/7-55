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

If that ordinary plan exceeds the browser's unchanged 100-pack ceiling, a
count-budget fallback merges the smallest eligible same-family pair until the
plan reaches 100. Each merge removes one pack; no extra merges are performed.
Single-resource exceptions are never merged. The 24,000,000-byte hard limit,
chapter/phone admission, original paths and boot core remain unchanged. All
unaffected packs retain their IDs and members; the earlier ID survives each
merge, so unrelated cached packs remain reusable. If no safe pair exists, the
build fails instead of promoting content to core or relaxing a hard limit.

Only pressured builds add the `countBudget` policy and `pack-count-pressure`
size-exception receipts. Verification rebuilds ordinary first-fit bins from the
complete-export inventory and repeats the deterministic merges, checking exact
membership and exception receipts. Unnecessary pressure declarations, forged
exceptions, mixed-family membership, and altered pack limits are rejected.
Existing manifests without this policy remain readable. Merged packs over the
6 MB target use the same independently verified 1 MiB transport slices; the
extra slices also count toward the existing 950 MB delivery budget.

Cache reuse uses verified byte identities. Unchanged boot slices can be reused
across releases. When PCK membership changes, matching slices and complete
packs are reusable. Interrupted transfers keep their already verified and
committed blocks.

Chapter 2 loads shared actor, dorm, audio and phone resources through
`chapter2`. The north-up map and its layer data travel in `chapter2_campus`.
Library interior and catalog art travel in `chapter2_library`. The saved scene
and the active phone view determine which packs must mount before the view
opens. The Chapter 1 entry leaves both world packs deferred. The dorm warms
the campus pack, and the campus warms the library pack. Chapters 3, 3.5 and
4 retain their shared chapter dependencies for earlier inventory and clues.

The browser warms one eligible family at a time. Verified packs with a complete
IndexedDB receipt stay in browser storage until a view requests them. At that
point the loader reads and revalidates the cached bytes before Godot mounts the
PCK. A foreground request can promote an in-flight transfer immediately. The
existing mount and CacheStorage fallback handles unavailable persistent block
storage. Background traffic pauses when the page is hidden, offline, or Data
Saver is enabled.

The published directory contains:

- `index.pck`: the boot core, including the main/entry/state scripts, shared data,
  fonts and resources selected by the conservative startup dependency scan.
- `content/<group>-<sha256-prefix>.pck`: immutable deferred chapter/campus packs.
- `content/chunks/<group>-<index>-<sha256-prefix>.bin`: 1 MiB static slices only
  for single-resource exceptions and count-budget merged packs above the 6 MB target. The complete original
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
node godot_native/tools/test_web_content_packing.mjs
```
