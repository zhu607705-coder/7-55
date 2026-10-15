# Changping library approach connectivity repair

## Defect and exact correction

The approved `950 × 1656` source image has SHA-256 `f92a8de6ef703bab4b2e471a49acc082dd4d128d264d99d3ed1818fdb0c93707`. Its paved road south of Wenli continues through source `(700, 863)` toward the library.

The northern road expanded the east-road feet-guard rectangle to x=659. Its partial joined-union boundary incorrectly included `[[700,856],[700,870]]`, an internal seam across the already authored library road. Removing only that segment restores ten existing two-pixel grid centers: x=699 or701, y=859,861,863,865,867. No polygon or waypoint is added or moved. No previous allowed cell is removed.

## Logical road and visual residency

`enable_north_road_extension` is an independent logical-road switch, enabled by default. The campus installs the authored northern road independently of `enable_north_hd_region`. HD regions no longer own or uninstall roads. Missing visual resources, visual unloading and all-HD-disabled startup therefore preserve the same road network. Explicit logical-road uninstall remains available and restores the original east-road cap without creating a library barrier.

The original east-road-only test now disables the logical north road explicitly. The north-region test now expects visual uninstall to preserve roads, and tests malformed road admission only after explicit logical-road removal. Those changes express the independent-road contract; they do not relax radius, boundary or collision checks.

## Isolated candidate verification

64/64 assertions passed in Godot4.6.3. Headless execution used fixed60Hz simulation frames and the real production `CharacterBody2D` physics code. No movement speed override or manual physics calls were used.

- Original41 guide waypoints all connect; the original guided walk completes and credits exactly3 existing POIs
- Continuous actual spawn → library `(566,816)` → north endpoint `(666,548)` → library → south gate:2101 physics frames, zero illegal-foot frames, zero position writes after spawn, maximum observed speed88.00363px/s (float error), radius3 unchanged
- Arrival uses the existing path follower's2.5px tolerance to its snapped grid endpoint. Requested targets can differ by up to√2px from that endpoint. The return-library feet were `(566.99896,819.01294)`,2.01294px from snapped endpoint `(567,817)` and approximately3.174px from the raw target. No runtime arrival threshold was changed
- Held-key fixtures toward library wall, lake, road edge and north-road grass stop legally; release produces zero drift. Explicit native collision still rejects library wall crossing
- All150 physics records,83 walkable polygons, blocker data, source route/POI data, character height18, speed88 and radius3 have identical before/after hashes
- All-HD uninstall, missing-HD rejection and all-HD-disabled fresh startup preserve navigation
- Independent CPU source-coordinate audit samples6825 positions at0.25px spacing. All759 restored local samples remain on previously authored paving and fit an unchanged radius3 circle sampled at361 angles

The original frozen scene was tested before modification. Its four library targets were unreachable; their repaired AStar paths have435–451 nodes. Both northern targets remain reachable with their original430/496-node paths.

## Same-tree production verification

The integrated production tree passed all191 assertions: library connectivity64/64, north-region and independent-road lifecycle86/86, east-road regression41/41. All three commands used the actual project and `res://tests/` scripts. No isolated script/profile override was used. All processes exited0; no parser or runtime script errors were reported. The same2101-frame round trip,10-cell restoration and identical authority hashes were reproduced.

## Repeatable production checks

`tests/test_buct_changping_library_connectivity.gd` recreates the old spurious guard in its first isolated scene, then tests the unmodified production scene, real movement, visual residency and independent road lifecycle. Optional `BUCT_LIBRARY_ROUTE_QA_DIR` selects an output directory. Related regression tests are `test_buct_changping_north_region.gd` and `test_buct_changping_east_road.gd`.

This is outdoor navigation verification. It does not claim visual acceptance, whole-map completion, new interior access, or changed story progression.
