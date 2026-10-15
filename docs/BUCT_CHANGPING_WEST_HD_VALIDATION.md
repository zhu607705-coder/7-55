# Changping west HD pair

This adds two west-adjacent ground regions and one complete independent Second Teaching Building to the accepted Wenli+north pair. See the adjacent validation JSON for current acceptance state. Do not infer acceptance from this document's presence.

## Source contract

| Region | Source ROI | Logical core | Runtime texture |
|---|---|---|---|
| West north | 398,399,256,240 | 426,411,216,216 | 1280×1200 |
| West south | 398,615,256,240 | 426,627,216,216 | 1280×1200 |

- Source canvas remains 950×1656. Every transform uses one uniform scale
- The wider west context protects the complete teaching building; it does not enlarge the logical core
- The 24px overlaps have one display owner. NW owns the horizontal band and four-way corner
- The original three teaching collision feet and all existing paths remain unchanged. The new terrain grants no walk permission
- Existing library RGBA, registration and physical feet are reused
- The two real teaching courtyard holes stay transparent. Inner walls and the central connection stay opaque

## Art provenance and corrections

One whole teaching RGBA, one NW ground and one SW ground were generated. One bounded correction restores courtyard vegetation/paving. Original candidates remain archived. Only 21,233 raw candidate pixels changed in the two permitted holes; zero pixels outside the permission mask changed. A second runtime-space mask prevents resampling from leaking outside the permitted holes.

The small NE sports court is a permanent same-coordinate copy of the accepted NE artwork in the NW derived runtime texture. It survives NE unload. The original NW candidate is untouched.

A suspected new lake pier was checked against original pixels and exact water alpha. The source already contains the same-direction pale projection. No wood-colored pixels occupy original water alpha in the measured area. The static reconstruction was accepted; no water or shoreline artwork was regenerated.

## Water and visibility

The existing lake object retains alpha, distance, clock, static/dynamic switch and exclusions. It borrows the SW ground RGB resource. Base and displaced HD samples reject dry texels. Unload restores original inputs. No extra lake RGB texture is allocated.

Within the SW intersection, 4043 source-pixel-equivalent water area is fully HD; 660 belongs to the outer blend and 113 to the original collar. The rest of the lake is not claimed HD. The logical core contains 3001 fully-HD water pixels.

Only three existing approach-side crowns gain depth masks. They sample the same HD ground RGB. They create no trunk collider. Teaching and library shadows are restrained 14%-opacity projections of existing authored polygons, not new generated RGBA shadow art.

## Validation and retained failures

- Whole teaching RGBA native GPU proof: 23/23, exact reconstruction across all tested foot depths and both backgrounds
- West headless lifecycle/ownership suite: see JSON for final count, including default production without an enable override
- First full GPU batch: 19 assertions, one invalid test-foot failure. All full-core source-poison, four-way/reverse-neighbor, old-library-owner and water-alpha tests passed
- First legal-foot short batch: two legality assertions passed, but four unrelated time-varying pixels remained in the full-screen front comparison. The shortened fixture had omitted the full batch's water-clock freeze
- Corrected isolated crown batch: 3/3, legal behind 84 changed pixels, front 0. No leaf mask, sort rule or threshold was weakened
- Initial manual fixture failed to present a game frame and logged XServer BadValue. It was closed normally and retained as a failure. The replacement uses the established current_scene manual boot shape, without viewport/title overrides
- Actual manual results, related source-less PCK tests and old-region regressions are recorded separately in the JSON

NW held-out checks and both core support checks remain archived. SW has seven of eight independent locations within 1px; [560,641] measures 1.21px at NCC .932. Source localization uncertainty is approximately 1px. Parent review accepted this explicit exception after 2.1×/4.8× rendering showed no double curb or kink. The global threshold was not changed.

## Memory scope

| Allocation estimate | Bytes |
|---|---:|
| New NW region layers | 9,053,411 |
| New SW region layers | 9,149,791 |
| New teaching whole body | 9,984,162 |
| All four region layers | 36,390,042 |
| Three independent bodies owned by four regions | 29,918,113 |
| Layers plus those bodies | 66,308,155 |

These are logical uncompressed mip allocations, not measured VRAM. The existing library/first teaching, actors, original map, framebuffers and transient validation buffers are outside these figures. The 57,597,600-byte residency cap applies only to region layers. `set_west_hd_resident(wanted)` is an explicit atomic display-loading hook; no automatic streaming is claimed.

## Reproduction

Use the exact PR #138 base and cumulative overlay manifest. Keep all temp/XDG paths in the workspace. Run only one Godot process at a time.

1. Import the project with the installed approved Godot 4.6.3
2. Run `test_buct_changping_west_regions.gd`, then the existing north headless suite
3. Run the static west adapter checker with both actual profile paths and the registry checker with required rejection cases
4. Run `python godot_native/tools/north_package_validation.py --body-id teaching_2 --output-root <workspace QA path>` for actual small source-less packages. This is resource-method QA, not an executable game export
5. Run actual-renderer scripts and manual input on a real display. A headless pass does not establish visual correctness

The ultimate request is full-map HD coverage. This delivery covers four contiguous Changping cores only; later rows, the western lake and other campuses remain pending.

## Existing route limitation found during preview setup

The local library approach is legal, but the original south-spawn guide is disconnected between [733,863] and [700,863]. HD install/uninstall leaves the authority hashes unchanged. The successful manual local W/S test does not prove global reachability. No road permission or collision was changed to bypass this limit. The final preview physically follows the already verified path to [731,676] (430 nodes), then uses camera-only views of the contiguous HD region, teaching building and library/lake. Its caption explicitly says the library-west entrance connection remains pending.
