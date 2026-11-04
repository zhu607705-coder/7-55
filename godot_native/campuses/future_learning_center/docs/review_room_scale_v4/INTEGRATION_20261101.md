# Existing wide-desk revision integrated with main — 2026-11-01

## Authority and source boundary

The user authorized uploading the existing room proportions and wide desks. This integration introduces no new art, furniture design or room scope. It starts from PR201 `0d6809fa2a2fd6c9b3b68deaae6fe06631c90ae7` and merges the real main commit `72fe2ed3dab84c99cedb2e427a4d639fca135472` (PR203). The merge commit is `0ef8c46f3ffad99ab0539f3863b5ee092d792bfb`; both remote commits are its actual parents, not merely equivalent local trees. PR204's separate UI work is not included at this stage.

The 18-file v4 candidate was verified against its archived SHA256 list before use. Sixteen non-generated files were brought across only after checking their old base hashes or absence. Neither old floor JSON was copied over main. Both floors were regenerated from the combined builders. The wide desk keeps its original downloaded bytes (`e585752ad8b24e19a049a08dd57517cd248e2eb5d55a1219830301fc0ee5125b`).

## Semantic merge

- `floor_2.json`: regenerated, retaining main's robotics details, glass frontage, door thresholds, closed-glass collision and `.90` camera override.
- `build_building.mjs`: retains robotics details/frontage before projection and room-layout passes. The final room-layout pass keeps stable IDs and uses the approved v4 geometry.
- `floor_view.gd`: retains both locker/coupling entry, pending, input and cancellation paths and PR201's NPC lifecycle. Entering the new stations clears pending NPC state; talking to an NPC clears pending locker/coupling targets. No new model or save namespace is added.
- The 2F layout baseline is explicitly rebased to main's approved PR202 geometry. Its architecture hash and non-target object hash are derived from main, not from the candidate. Main's ordered 194-object prefix remains intact before room-specific additions. Floors 3 and 4 keep their existing baselines.
- All three floor architecture fields and every object outside team/recording exactly match main. Team/recording objects and NPC positions exactly match the approved v4 candidate. Floor 4 is byte-identical to main.
- The PR203 workflow/performance changes, `world.gd` cache isolation fix and its canteen regression are unchanged. The only native-tools difference from main is the existing/new explicit FLC test registration.

## Evidence and limitations

`MAIN_PRESERVATION.json`, `REBUILD.json` and the final integration receipt are external QA artifacts. The full rebuild is byte-identical on all three floors. Node layout/projection tests pass 8/8; registration tests pass 17/17. Combined native results: **52 suites, 6261 checks, 0 failures** using Godot 4.7.1 and a fresh standard `/tmp` profile per suite. This includes 31 old/new activity anchors (133 route checks), 172 NPC/integration checks, 1785 floor checks, 307 registered-station checks and both standalone locker/coupling models. The Web resource-policy/planner check also passed.

The first all-suite attempt reached an integration process that ended with SIGKILL and no assertion result. Its custom QA profile was also outside the test guard's required `/tmp` location. It is retained as failed attempt history, not acceptance. The canonical-profile focused rerun and complete 52-suite rerun passed. The first sparse Web-policy invocation lacked the unchanged `web/content_loader.js`; extending the sparse checkout to include the original Web folder resolved that fixture omission. No source assertions or thresholds were weakened.

The save codec, State, formal activity host and player metrics are byte-identical to the previously verified v4 candidate. The additional combined save/font/Main-host run is deferred while video capture has CPU priority; earlier counts are historical, not a claim of a new combined run. Full formal CI must cover those boundaries before release.

The existing north/south PNGs in this directory are actual 2026-10-31 v4 review captures, not new screenshots of this combined source. Video recording has GUI/CPU priority. Headless event tests do not establish new pixel acceptance or physical-phone acceptance. The earlier focused Web pack proof demonstrates the exact desk asset; the complete combined Web export and CI remain publication checks.

The table's projected depth is still 27.994 world pixels, below the earlier requested 35–45 range. The recording room's south area remains sparse. These limitations are unchanged and are not hidden by stretching assets or changing player size. Uploading the candidate does not authorize marking the PR ready, merging or deploying it.
