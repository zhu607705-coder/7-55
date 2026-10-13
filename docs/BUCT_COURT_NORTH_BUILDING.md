# Chaoyang court-north short building

Base: Draft #130, commit `dca266a2bffcc8b460718f84930a49f19f184d30`, tree `d96e6ff04e2b4810f2c46de51a37062f39611313`. This is one independent outdoor object in the separately authorized BUCT native entry. Original ZJU story, other buildings, roads and student remain unchanged.

## Source and fixed registration

`west_courts_north_bar` corresponds to crop `[440,433,154,63]` of the approved 1448×1086 Chaoyang image. It is one connected low bar, not multiple objects at roof seams. No interior or courtyard is invented.

The original 1961×802 RGBA v2 body is unchanged: SHA256 `553579fb870f4d5cfc7cfde3068271c9018e0096bf7db6dc6ecf5a6e2fde4d94`. One uniform scale `137/1710` and origin `(437.7450292397661,430.92105263157896)` retain its padded texture. The two-level facade follows the original 18–19-source-pixel height. The first, too-short facade candidate was rejected rather than stretched.

## Runtime

- Two complementary depth passes share one production mipmapped texture and one 1961×1 RF footline texture
- One 3-source-pixel contact band follows visible wall ends, using a 28-point chain with 0.12-source-pixel simplification tolerance. Roof projection is not a collider
- Alpha picking uses the registered body, with no transparent-exterior polygon fallback
- The old UV body and guessed physical foot retire only after ownership checks. The approximate full-silhouette underlay is disabled
- Original paving permission remains authoritative. Both basketball courts stay closed; existing southern trees, canopy behavior and accepted four-direction student stay intact
- The neutral information card adds no visits, guide points, entrances, interiors or hide/move controls. The original tour still has 29 points and three POIs

The underlying campus painting is retained. This is not a fully erased building footprint and does not support arbitrary removal or movement.

## Bounded north-edge repair

Normal walking views exposed old equipment and a pale lip above the new left roof. Only the frozen 201 source pixels in `[447,433,56,16]` are repaired. No source pixel outside that allow-mask changes. The broad 586-pixel diagnostic envelope is not used.

The first cleanup candidate retained a pale lower row and was rejected. The final web-authored background is 2210×712 RGB. It is uniformly width-fitted with scale `56/2210` and a centered crop `[0,40.285714,2210,631.428571]`; no unequal axis stretch occurs. Only mask pixels are consumed. This is a small background-texture repair, not evidence of exact hidden scenery reconstruction.

Runtime loads a 56×16 RGBA imported texture, not the large source image. Its alpha is binary with exactly 201 opaque cells and zero RGBA outside. Nearest sampling and no mipmaps/alpha-border fill preserve the source-cell boundary. The static repair is behind objects, has no collision or picking, and adds one sprite and 3,584 decoded texture bytes. Its PNG is 754 bytes. Raw generation and rejected candidates remain provenance evidence outside runtime resources.

## Validation

On 2026-10-13, 50 source checks, 139 native checks and 41 existing-road checks with 1,322 actual student samples passed. Final normal road/full-map views and real roof click, transparent rejection, card close, entry return/re-entry and window close passed with exit 0. See `BUCT_COURT_NORTH_VALIDATION.json` for dated evidence.

Tiny original dark antialias edges remain outside the fixed mask near source `(472,437)`, `(471,439–440)` and `(497,439–440)`. At normal scale these are roughly 1–3-screen-pixel dark edges, rather than the former bright continuous strip. The lower complete vent boxes and right end post belong to the accepted v2 body. No further mask expansion or body edit was made. The new native fixture is included in the focused BUCT runner and is also found by the full validator's existing test scan. Missing evidence-output configuration is valid; explicitly requested output failures exit nonzero.

The unchanged body previously passed exact whole-vs-compact GPU comparison and all 24 accepted-student overlap poses. That body component measured five nodes and 8,400,868 texture bytes; CPU alpha uses 1,572,722 bytes. The extra repair has separate bounded cost. No median/p95 performance benchmark, LOD implementation, PCK export or full-game CI result is claimed here.
