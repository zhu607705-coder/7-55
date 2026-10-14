# Changping high-detail region registry: historical four-region snapshot

Historical acceptance snapshot retained on 2026-10-14, before the northern expansion. The four-region figures and streaming statement below describe that earlier checkpoint only. For the current six-region state, use [the stage summary](BUCT_CHANGPING_SIX_REGION_STAGE.md) and `godot_native/campuses/buct_changping/data/hd_region_registry.json`: 310,684 source pixels (19.7485%), with visible-camera residency implemented but still opt-in/default false.

Four contiguous regions are enabled and locally accepted: Wenli, its northern neighbor, and the two western regions. The registry describes the actual default scene. It does not claim whole-campus completion or automatic streaming.

## Source and coverage

- Original source: 950 × 1656, SHA-256 `f92a8de6ef703bab4b2e471a49acc082dd4d128d264d99d3ed1818fdb0c93707`
- Required restored baseline: PR #138 `72fcafd285dd388eed2735be71b60fa23f428548`, followed by the accepted 28-file Wenli overlay tree `d0d88bf3aaf93ec5cdb057f704b4d660b6506d04`
- Wenli: ROI `[630,615,240,240]`, core `[642,627,216,216]`
- North: ROI `[630,399,240,240]`, core `[642,411,216,216]`
- Shared overlap `[630,615,240,24]`; cores meet at `y=627`
- West north: ROI `[398,399,256,240]`, core `[426,411,216,216]`
- West south: ROI `[398,615,256,240]`, core `[426,627,216,216]`
- Four non-overlapping 216×216 logical cores cover 186,624 of 1,573,200 source pixels, or 11.8627%. Outer fallback collars are not counted.

All other areas and both other campuses remain outside this four-region HD acceptance.

## Runtime and owner contract

`godot_native/campuses/buct_changping/data/hd_region_registry.json` is a checked audit manifest. The default scene explicitly installs the accepted legacy Wenli component and the profile-driven northern component plus the atomic west pair. It does not discover, stream or accept regions from this manifest automatically.

The independent body owners are `wenli_building`, `north_sports_hall`, and `teaching_2`. The pre-existing library RGBA is reused and not counted as a new regional body. Buildings remain complete objects even if future region boundaries cross them. Their original anchors and foot collisions stay unchanged. The new building is displayed neutrally as 北侧长灰楼; no real function, interior or history is asserted.

Wenli retains its nine existing alpha owners and owned shadow. North has three separately traced local crown alpha owners. Their RGB comes from the exact same new HD ground. The northern object had no owned shadow polygon, so its profile explicitly declares no independent building shadow. A missing shadow is not replaced by a borrowed Wenli shadow.

The new source-traced road connects the old `y=670` cap to the verified southwest junction near `[666,548]`. Its combined union removes the internal cap. The uncertain planted frontage stays closed. Foreground leaves add no collision or grass permission.

## Shared-band ownership and rollback

North is the sole opaque shared-band owner while Wenli is active. It blends the new north detail with a recovered unfeathered strip from the original Wenli master. It never stacks two translucent source-faded collars. The actual GPU source-poison test shows zero shared-core pixel differences; reverse installation order also matches exactly.

The original Wenli PNG, nine foreground masks and source body registration remain unchanged. Removing north restores the accepted Wenli view. Removing Wenli leaves north's own outer fallback intact. Preparation validates hashes, profiles and ownership before mutation. Failures and uninstalls may only restore their own owners. Road geometry is completely validated before committing permission or replacing union guards.

## Explicit memory scope

Admission is enforced at six region components, at most 12 MB of layer textures per new region and 57,597,600 resident layer bytes. Automatic camera streaming is **not implemented**.

North layers use 8,587,240 bytes; its independent body uses 9,956,875. Wenli layers use 9,599,600; its independent body uses 9,977,076. The west pair adds 18,203,202 region-layer bytes and a 9,984,162-byte teaching body. All four region layers total 36,390,042 bytes; their three independent body owners total 29,918,113 bytes. The combined 66,308,155 bytes are logical uncompressed mip/data allocations, not measured VRAM.

This sum excludes the original map, other independent buildings and actors, framebuffers and transient validation copies. PNG file sizes are not GPU memory estimates.

## Validation and consistency

Run `node scripts/check-buct-hd-region-registry.mjs`. It compares the manifest to actual production default flags, actual profiles, source geometry, owners, allocation and hash-pinned acceptance evidence. An enabled region requires accepted status and a real profile. Enabled neighbors require passed shared-band evidence.

Ten rejection fixtures include pending-but-enabled status, null profile, a contradictory runtime flag, missing or pending seam evidence, false proof hash false allocation, false wider-west core, wrong atomic group, and double-counted reused library. Do not make the checker pass by deleting acceptance requirements or retaining a stale “one accepted region” assertion.

See [north scope and validation](BUCT_CHANGPING_NORTH_HD_REGION.md), [machine-readable acceptance](BUCT_CHANGPING_NORTH_HD_REGION_VALIDATION.json), and the preserved [Wenli acceptance](BUCT_CHANGPING_WENLI_HD_REGION.md). Controlled GPU image poses, automatic physical route capture and actual human-input entry/return are reported separately.

## West-specific ownership

NW owns the entire horizontal overlap and the separable four-source corner. Exact source-coordinate east strips remain display dependencies. A small accepted NE court patch is permanently precomposed into NW so neighbor unload cannot restore the rejected trees. Teaching2 remains one RGBA across the tile join. The two true transparent courtyard holes received one mask-only correction; original candidates remain retained.

The optional lake HD RGB borrows the existing SW texture under the original alpha/distance/clock. Outer lake regions remain source fallback. `set_west_hd_resident(wanted)` loads or unloads the display pair without changing logical roads. The west profiles add no walkable polygons.

See [west validation](BUCT_CHANGPING_WEST_HD_VALIDATION.md) and [machine-readable west acceptance](BUCT_CHANGPING_WEST_HD_VALIDATION.json), including the retained invalid-pose, moving-water-fixture and first manual-window failures and their bounded corrections.
