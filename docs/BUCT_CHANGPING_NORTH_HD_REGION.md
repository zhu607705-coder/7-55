# Changping: contiguous northern high-detail region

## Scope and baseline

This change extends the accepted Wenli region northward. It does not complete Changping or either other campus. The two outer rectangles have a union of 109,440 source pixels (6.96% of the 950 × 1656 map); their non-overlapping 216 × 216 cores total 93,312 pixels (5.93%). Outer collars retain the original-map fallback.

- Base: PR #138, `72fcafd285dd388eed2735be71b60fa23f428548`
- Required prior dependency: the recovered 28-file Wenli HD patch, tree `d0d88bf3aaf93ec5cdb057f704b4d660b6506d04`
- Whole source map SHA-256: `f92a8de6ef703bab4b2e471a49acc082dd4d128d264d99d3ed1818fdb0c93707`
- New ROI `[630,399,240,240]`, core `[642,411,216,216]`
- Old ROI `[630,615,240,240]`, core `[642,627,216,216]`
- Shared band `[630,615,240,24]`, core boundary `y=627`

The runtime enables the two components by default. The registry is an audit manifest, not a camera-streaming implementation. Only explicitly reviewed profiles are installed.

## Independent building

The existing stable ID is `north_sports_hall`. The neutral player-facing name is “北侧长灰楼”; its real function and interior are not established. Its card records no history, visit or tour progress. Central stepped roof equipment remains solid; it is not a courtyard.

The entire original 1275 × 1233 RGBA image is retained byte-for-byte. SHA-256: `3dd06f813a1cedcf1099e39a27ece391c1b228bddad25ce796c3b3c69755386e`.

Registration uses one uniform scale `0.09108724621776279` and translation `[622.6595986517207,435.9534373285255]`. There is no rotation, deformation or independent axis scale. Four actual roof observations have RMS residual 1.7233 source pixels, maximum 2.4554 pixels. This is an approximate art registration, not zero-error alignment.

Original anchor `[679,539]` and footprint `[[649,501],[708,482],[723,519],[670,539]]` are unchanged. Original collision masks/layers, transforms, source IDs, points of interest, spawn, 41 guide points, student foot shape, height 18 and speed 88 are frozen by runtime snapshot comparisons.

A single surface uses two complementary common-quad passes, not hundreds of depth slices. Alpha comes from the original RGBA, including holes and antialiasing. The surface ID field covers the full image domain; otherwise nearest surface sampling incorrectly removed 43 bilinear-alpha edge pixels. The first failed GPU result is retained. The corrected entire RGBA matches the original with zero differing pixels at five actor-foot depths, both on true transparency and over the opaque original source map.

## Ground, seam and foliage

Ground is a uniform 1254 → 1200 Lanczos resampling of the original v1 generated image, SHA-256 `37747cb27e55eeb0ed4a57c70aad785e448c839237db8b080157d3aab9d5d174`. Runtime PNG SHA-256: `cf27670553b536138d33d4fae397c7c48444aaf06907d9bbeb951559d4783b9e`. The v2 road-paint revision was rejected in full; no v2 pixels or permission masks are used. Some pale source road marks are artistically strengthened. They are not verified traffic markings. Ground beneath the removed building is inferred.

Twelve local road/curb checks found 0.20–0.63 source-pixel coarse displacement with NCC 0.955–0.986. These are image-consistency checks, not surveying evidence.

The north component is the sole opaque owner of the active shared band. It blends two high-detail RGB sources. It does not layer two source-faded sprites. The old unfeathered Wenli north strip is recovered from original v1 SHA-256 `73744c50370cebbcaa0bb6fd5d010370e8b844309a63dadea1e2504c0e8c5ab3`; the old localized courtyard correction has no support there. A two-row sampling gutter adds no coverage. When coverage is one, the shader returns detail directly, avoiding source-dependent floating-point rounding. Replacing the source sampler with opaque magenta changes zero shared-core pixels. Reverse neighbor installation also changes zero pixels.

Three local crown groups have explicit same-HD RGB and leaf-shaped R8 alpha: `north_road_crown_01`, `02`, `03`. They do not borrow the old nine Wenli owners. At legal road-foot positions, the actual student is obscured behind and visible in front of each crown. Without the actor, all three layers together differ from the underlying RGB at only three pixels by one LSB. Leaves do not become walls. No trunk is inferred on the road.

The old object has no owned cast-shadow polygon. This change adds no invented building shadow and never reuses the Wenli building shadow. Painted ground shading, building light/shadow appearance and actor-foot occlusion remain distinct concerns.

## Continuous physical route and failure safety

The old east-road cap ended at `y=670`, leaving a 31-pixel gap to the new ROI. One conservative source-traced pavement polygon now joins that cap to the southwest junction `[666,548]`. The combined exposed union has 60 segments and removes the internal old cap. The uncertain planted south-frontage branch stays closed. Grass, roofs, water and courts gain no permission.

New road configuration is completely validated before mutation: finite numeric coordinates, point counts, bounded nondegenerate polygon, valid nonzero edge pairs and valid guard rectangle. The old union includes a tail beyond the local guard rectangle; those edges stay source-bounded while the new polygon must fit the guard. Missing fields, short rectangles/edges, NaN and Infinity reject without changing old walk polygons, guards, nodes or ownership.

The region prepares textures, alpha, owners and detached bodies before committing. Failed assets do not hide the source building, append road permission or steal neighboring materials. Uninstall restores only owned state. Neighbor removal, reverse install order, cached scene detach/re-add, failed late preparation and repeated scene exit are covered.

## Memory and residency

These are full uncompressed GPU texture/mip-chain byte estimates, not PNG file sizes:

| Allocation | Bytes |
|---|---:|
| New ground, seam, ownership and three crowns | 8,587,240 |
| New RGBA body, surface R8 and RF depth row | 9,956,875 |
| Total new textures | 18,544,115 |
| Existing Wenli region layers | 9,599,600 |
| Existing Wenli independent body | 9,977,076 |
| Known two-region and two-body total | 38,120,791 |

Admission allows at most six region components, with 12 MB per-region layer and 57,597,600-byte resident layer caps. Independent bodies are counted separately. This is not a complete engine or campus memory ceiling: source map, other buildings, actors, framebuffers and transient validation copies are excluded. Automatic camera streaming is not implemented.

## Validation and reproduction

`BUCT_CHANGPING_NORTH_HD_REGION_VALIDATION.json` records the exact current results and remaining gates. Evidence uses isolated workspace XDG data/config/cache/state/runtime and temporary paths.

- `node scripts/check-buct-changping-north-region.mjs`: provenance, geometry, raw fields and memory calculation
- `bash scripts/test-buct-changping-north-region.sh headless`: default installation, immutable production snapshot, failure safety and lifecycle
- `bash scripts/test-buct-changping-north-region.sh walk`: actual keyboard-input forward/reverse physical traversal; no position writes after spawn
- `bash scripts/test-buct-changping-north-region.sh proof`: real 1280 × 720 GPU frames, exact whole-RGBA, shared-source poisoning, order and crown depth tests
- `bash scripts/test-buct-changping-north-region.sh preview`: actual physical approach from south spawn, then 12 seconds of continuous north/return navigation and a source-sized 950 × 1656 native full-map render
- `bash scripts/test-buct-changping-north-region.sh manual`: real chooser for human input, entry and return checks
- `python3 godot_native/tools/north_package_validation.py --output-root <workspace-evidence-dir>`: small real source-less PCK resource checks; no full-project export

Use `BUCT_NORTH_QA_DIR` to choose evidence output. The GUI modes require a real display. Automated controlled poses are image fixtures, not claimed manual gameplay. Preview uses actual production navigation at the shared speed; it is not a frame-rate benchmark. The whole-map output contains exactly the two partial HD regions and otherwise original artwork.

No interior, TileMap replacement, GitHub merge, force push or repository publication is part of this local implementation.
