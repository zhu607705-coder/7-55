# One small Chaoyang ambient squirrel

## Scope

One independent, transparent 2D squirrel lives beside the existing round tree at the south end of the library lawn. It is a direct child of the existing feet-sorted `IndependentRegisteredObjects` container. It has one sprite and one visibility notifier. It owns no collision, input, selection, story, save, or navigation state.

The approved campus plate, four-direction student, tree canopy, building art, opened roads, and existing physical bodies are unchanged. This addition does not implement interiors or a formal TileMap.

## Artwork and scale

- The original 1536 × 1024 RGBA PNG is retained unchanged; SHA-256 is recorded in `ambient-squirrel-provenance.json`.
- Eight distinct source poses comprise one idle, one forward peek, two tail-flick poses, and four changing-limb run poses. These are not eight run poses. Capture or rendering FPS must not be reported as a distinct-artwork count.
- All frames use one common 8/313 uniform scale. Maximum tail height is eight campus source pixels. The unchanged student is eighteen source pixels tall. No scale, squash, stretch, glow, or phase-specific fitting creates animation.
- The eight atlas regions were measured independently. A generated run pose crosses the nominal four-column grid, so regular equal-cell cropping would cut the nose/forepaw.
- The foot origin follows the body and ground line. All run images use source-sheet ground Y=866, including airborne images. The lowest opaque pixel and tail height are not ground anchors.
- The original image has real transparency. Low-alpha generated haze is discarded below 0.04, and one mipmapped atlas provides stable miniature sampling. The PNG itself is not repainted.

## Behavior

The squirrel rests, briefly peeks, rests, flicks its tail, rests, runs 24 source pixels, and stops in a true idle pose. Long rests vary deterministically between 9, 15, 21, and 12 seconds across visits. Quiet stillness occupies most of its time.

Its route is (722,690) ↔ (746,690), beside the existing `promenade_west_round_canopy` at (712,689). The route is on the gray paving below the lawn steps, not the statue or planted lawn. The existing radius-three player legality check validates the entire route before installation and every movement segment. If validity changes, the actor stops safely. It never opens a cell or changes a blocker.

Movement is eighteen source pixels per second. Four run poses advance from actual displacement over a provisional 7.5-source-pixel stride. Off-screen or unfocused activity pauses without catching up later. A frame stall is capped at 0.1 seconds of simulation. Scene exit removes the node and its cached pose resources; re-entry installs one new actor.

## Verification status

Passed on an isolated PR #134-era Chaoyang stage:

- 17 dependency-free source checks, including original RGBA integrity and 49 half-pixel route samples
- One-asset import only, using Godot 4.6.3
- 60 native assertions: 30/60/120 Hz deterministic simulation, stationary actions, four run poses in both directions, mirrored foot anchors, invalidated-route stop, off-screen/focus pause, cached textures, no collision authority, full route physics traversal, and two complete campus entry/exit cycles

Native visual review confirms that the eight-source-pixel squirrel is readable and smaller than the unchanged student. The continuous 18.025-second capture contains the initial nine-second rest, real peek, both tail poses, all four moving-limb run poses, one continuous 24-pixel run, and a stationary stop. All 233 captured samples remained focused, on-screen and legal; none was blocked. The short 10.025-second excerpt begins at source time 8.0 seconds and retains the complete action without speeding it up. Timestamp-based 30fps sample-and-hold encoding duplicates frames only; it does not synthesize gait poses. The resulting MP4 durations are 18.033333 and 10.033333 seconds, within one output frame of the source intervals.

The generated animal remains more side-on, round-eyed, and sharp than the requested high aerial style; its original still contact with the ground looked a little light. The four-pose gait is a small ambient illustration, not a biomechanically exact support-cycle model. No further artwork regeneration, glow, scale inflation, or unrelated optimization was added. The isolated checks are supplemented by the exact combined-baseline regression recorded below; full published-head CI and Draft publication remain pending.

### Contact-shadow revision

The approved revision adds three cached, warm gray-brown ellipse commands under the original foot point, offset only (0,+0.10) source pixels. Their alpha values are 0.035, 0.045, and 0.055; the combined center is below 13% opacity. The actor still has only its original sprite and visibility notifier. No per-tick geometry, image asset, or collision was added.

Godot scales the small-radius circle's antialias fringe along with its body. The first candidate's nominal 4×1 ellipse therefore affected about 8×2 source pixels and was rejected. The final draw radii are halved to (1,0.25), (0.7,0.175), and (0.4,0.10), targeting a maximum visible 4×1-source-pixel extent including that fringe. The diagnostic compares actual before/after GPU pixels at both camera scales; it allows one screen pixel for boundary coverage, requires darkening only, and fails when the measured extent exceeds the contract. Nominal parameter checks alone do not establish the visible footprint.

The revised source passes 18 source checks, 63 native behavior assertions, and both actual GPU extent checks. At 2.1×, only 14 screen pixels change within a 9×2 bounding box, with maximum channel darkening 12/255. At 6×, 111 pixels change within 24×7, with maximum darkening 13/255. No channel brightens. Both results fit the 4×1-source-pixel contract with the documented one-screen-pixel boundary allowance. Visual review accepts the subtle grounding improvement without a black oval or glow.

The original 233-frame motion evidence and its derived movies retain their old unshadowed bytes. Shadow comparisons use new `contact-shadow-v2-*` filenames so the two revisions cannot be confused. The original PNG, registration scale, feet, route, and action timing are unchanged. The v2 runtime remains frozen, with exact combined-baseline regression recorded below. The old motion recording is not presented as a re-recording of v2.

`tests/capture_buct_ambient_squirrel.gd` creates a native normal-camera still at 2.1× and a continuous real-time 18-second close-up at a uniform 6× camera zoom. It never enlarges the squirrel itself or steps through poses artificially. Its ledger stores actual timestamps, source coordinates, phase, and source-pose index. The student is placed once on the already-open lower paving for this diagnostic, then remains still. No squirrel position is changed by the capture driver. The normal still hides landmark pins and explicitly identifies its fixed scale-inspection camera; the close-up hides UI. These changes affect only the diagnostic fixture, not production UI. `BUCT_SQUIRREL_CAPTURE_MODE=normal-only` recaptures that still without replacing the motion ledger or movie frames.

## Integration

Copy only the additive overlay files. Add the script preload, optional member, and installer call immediately after the existing `_build_grid()` call in the normal Chaoyang scene. Register the source verifier and native test in the existing `godot_native/tools/test_buct.mjs` runner; do not replace unrelated test entries. The preparation helper checks these exact anchors before writing either integration file. Re-run against the approved combined baseline before publication.


## Final combined-baseline integration (2026-10-13)

The frozen contact-shadow v2 is now attached to the exact `godot-version` base `f08bdc4ebbee5a5c112e35f93e1cee13ee5636f2`, tree `070f6fc4460550e7edaa7b3e15c5d2211fb41714`. Runtime artwork and behavior files are byte-identical to the reviewed v2. The only existing production-script change is the three-line preload/member/installer hook. The existing runner retains all thirteen native and seven source registrations, adds the squirrel's two registrations, and otherwise preserves its save/evidence isolation byte-for-byte.

The local focused aggregate exits 0: fourteen native scripts, eight source groups, eleven save-isolation cases and four unsupported-platform guards all pass. Native assertions total 2,354, including 1,234 real three-campus entry/return checks and 63 squirrel checks. Source assertions total 2,258. Existing Chaoyang walkability/L/court tests, shared student and pin tests, Haidian east-road tests, and Changping east-road/lake/bridge-south-water tests pass. Seventy-three matching source/import artifacts were reused without any repository-wide import. The initial lightweight-stage omission of synchronized JSON inputs was resolved by materializing the exact base's 57 JSON blobs, after which the entire aggregate was rerun cleanly.

The focused stage deliberately uses the existing campus-only test option. Its final transition into the Zhejiang story scene and the corresponding phone-home resume assertion were not run locally; the published head must pass the complete Native and Web CI with normal story resources. Story controllers, saves, shared state and other campus production files are unchanged. No additional GUI capture, artwork or feature expansion was performed. Publication is an independent Draft only; these results do not authorize a merge.
