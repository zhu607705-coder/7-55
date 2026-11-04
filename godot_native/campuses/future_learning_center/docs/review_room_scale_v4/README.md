# Wider, lower workstations — FLC scale review v4 (2026-10-31)

## Integration status — 2026-11-01

The user authorized uploading the existing room-scale and wide-desk changes on 2026-11-01. The earlier publication hold below is historical, not the current instruction. This candidate is now combined with main through PR203 (`72fe2ed3`); it preserves PR202's robotics room/frontage, locker/coupling activities and camera setting. No new art or layout design is introduced. See `INTEGRATION_20261101.md` for the combined-source checks.

The PNGs remain genuine 2026-10-31 review captures, not new screenshots of the integrated main build. Upload does not mean ready-to-merge, deployed Web acceptance or resolution of unknown local-only edits.

## Scope and baseline

This revision applies only to the six 2F team desks and the 3F recording desk, their existing chairs/mounted devices, and the relocated project student. It is an increment over combined PR201/main200 tree `aa2d0b1d1e0976f27081c485c5185b3563f8b4c0` (reported PR head `0d6809fa`; identical local tree at `3af8cd4e5579f93c39f6d2f807e74f574729478a`). The current-main presentation, including tactile navigation, is preserved. No original object ID, activity model, save key, architectural module, doorway or navigation polygon is changed.

The player and NPCs retain the original .65 display scale, 19.5×14.625 foot box and common foot-center contract. `ART_BIBLE.md` explicitly preserves those coordinates and metrics. A full character frame is 62.4×83.2 at runtime, but the player's actual nontransparent height is about 70.2; these are not interchangeable measurements.

## Actual raster registration

`assets/room_props/wide_desk.png` is the unchanged second PNG downloaded from ChatGPT webpage generation. There was one geometry correction, not a local pixel edit, stretch or SVG replacement. SHA256: `e585752ad8b24e19a049a08dd57517cd248e2eb5d55a1219830301fc0ee5125b`. The sanitized manifest omits private generation links.

The visible alpha128 region is 1421×521 at (14,296). Uniform width 170 produces an image height 62.329. Source tabletop rear/front Y 296/530 and front-foot Y 816 give:
- projected tabletop depth 27.994 world pixels;
- actual vertical front-tabletop-to-foot span 34.215 world pixels;
- visible width 170, rather than the earlier 135.7.

The new tabletop remains shallower than the requested 35–45 depth range. This is retained as a documented limitation, not hidden by nonuniform scaling. Rear legs are inset: the inferred floor projection beneath the rear tabletop edge is source Y 582, while the visible rear-foot contacts are around Y 687. The rear tabletop edge, not the inset legs, meets the surveyed wall. Physical foot AABB, drawn bounds and baseline remain separate.

## Placement and mounting

- Team north wall: old `team_desk_6`, `team_desk_10`, `team_desk_18` at X 490/685/880. Both distinct activity anchors remain against the north wall. Three 170-wide tables leave 25-pixel gaps and do not squeeze the existing lockers.
- Team project group: old `team_desk_14`, `team_desk_22`, `team_desk_26` at X 520/720/920, front-foot baseline 4100. Student B moves to foot (1110,4170), outside the new group. Its ID and opt-in reply are unchanged.
- Recording: old `recording_desk_234` remains at X 1110 and the surveyed north wall. Existing divider, rail and baffle fit on the actual tabletop. The monitor stays on the media cart.
- Chairs retain their v3 dimensions. Desktop devices are not blindly enlarged with the table width. Their bottom contact lines are explicitly placed inside the new tabletop trapezoid; the old source IDs, parents and ordered baselines are preserved.
- Media carts, lockers, sofa, camera and softbox retain their prior dimensions. This table correction does not establish that every other size or the whole-room density is solved.

`object_registration.json` records the complete affected-room bounds, footprints, baselines, parent IDs, tabletop polygons and mount contacts. `apply_wide_desk_layout.mjs` runs after the previous stable-ID pass; it is deterministic and idempotent. Old row prefixes and unrelated-room geometry remain protected by regression tests.

## Visual evidence and limits

The paired north/south PNGs are actual Godot 4.7.1 OpenGL/llvmpipe captures, with the same camera and original actor size. `before_*` was newly captured from the combined baseline, not inferred from source or from an empty-room preview. `after_*` uses the new desk data. Neither pair is a physical-phone or deployed-Web acceptance result.

The wider table and shorter vertical leg section are visible in the comparisons. The recording room's southern area is still sparse; no claim is made that replacing one desk has solved that separate composition issue. This pass does not expand to other floors or quietly change actor size to make the furniture look larger.

## Verification

The v4 source was tested with pinned Godot 4.7.1 and isolated profiles. Results:

| Check | Result |
|---|---:|
| All 50 FLC suites, including NPCs, navigation and all original activity anchors | 6125 checks, 0 failures |
| Layout/projection builders | 8 tests, 0 failures |
| Native CI registration | 16 tests, 0 failures |
| Room-save codec | 1196 checks, 0 failures |
| Actual-file save integration | 19 checks, 0 failures |
| FLC font coverage | 10019 checks, 0 failures |
| Current-main tactile floor controls | 21 checks, 0 failures |
| Formal Main activity entry/return | 38 checks, 0 failures |
| Optional activity content cancellation | 21 checks, 0 failures |
| Full building rebuild | All three floor JSON files byte-identical |

The independent room-save file test initially exposed missing dynamically named chapter JSON files in the sparse QA fixture. Copying the exact combined-baseline data into that fixture resolved it; no production save code changed. The optional formal-Main test also required the original State, WebContent and WebDisplay autoloads. Initial runs with those missing failed or timed out; the complete isolated host fixture passed both host and cancellation tests. These were fixture corrections only. Tests do not ignore script errors just because their assertion counter is zero.

The actual Web-exported new desk `.import` and `.ctex` entries were found in `flc_activity_001`. The lossless partition covered all 10 entries of the focused room-prop export. A separate Godot process mounted the FLC pack only and loaded the 1448×1086 desk, without chapter 3/4 packs. This is a focused asset-pack proof, not a full-game Web deployment acceptance.

Mouse testing used the real FLC activity view in a graphical fixture. The player approached and opened the two distinct team anchors and the recording anchor, then returned through the ordinary exit control. Original NPC opt-in feedback also worked. Setup keys selected test positions only; they are not claimed as ordinary room travel. Native touch cases are covered by the automated suites; no physical phone was used.

The initial visual fixture omitted the current-main `TactileButtons` autoload. The paired PNGs in this directory were replaced by actual recaptures with that exact unchanged autoload and dependencies loaded. The original unadorned captures remain only in external QA history. The external audit records source/fixture SHA equality, launch commands, input logs and image hashes.

## Historical publication and local-version hold (2026-10-31)

On 2026-10-31 at 12:04 UTC, the publishing owner fetched and directly checked remote main `ecfca2b54ef29cde3fc3a79b7d4ef02e83c620aa` and PR201 `0d6809fa2a2fd6c9b3b68deaae6fe06631c90ae7`. All 2728 baseline file hashes matched PR201. However, the user clarified that the difference concerns their local computer. Its branch, files and any unpushed edits are unknown. Remote equality does not resolve that question.

This remains an unpublished candidate, not user acceptance or a replacement of the user's local work. Further design and publication are paused pending local screenshots/repository details. Full-game Web release/deployment coverage remains CI; native captures do not establish it. The recording south area and the shallow tabletop remain explicit limitations.
