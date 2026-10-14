# Six-region Changping HD stage

Local source checkpoint: six default HD terrain regions and one newly accepted original-anchor dorm_nw_02 RGBA. Changping terrain coverage: 310,684 / 1,573,200 = 19.7485%. Seven left/northern body envelopes plus rejected Hill/Shelter retain originals; other campuses have no new accepted HD terrain in this package. This is a stage of the requested three-campus full replacement, not overall completion.

Coverage transition: the earlier six-ground-region checkpoint was 307,728 source pixels (19.5606%). Accepting dorm_nw_02 retires its original low-detail fallback owner, so 2,956 previously excluded source pixels now show the accepted HD ground beneath the independent building. This gives 307,728 + 2,956 = 310,684 (19.7485%). The source campus canvas and logical region footprints have not expanded; building texture area is not added to terrain coverage. Hill/Shelter and the other unaccepted original owners remain excluded.

All six layer allocations total 52,283,306 bytes. Registered independent bodies total 39,885,725 bytes, separately charged. Per-layer/6slot/57,597,600 layer caps are unchanged. An opt-in visible-camera release/reentry policy passed four source-authority transitions; its production flag remains false for the current six-region checkpoint. Before a seventh tile rollout, enable/register through the policy, rather than raising the cap or eager-loading every texture.

One concentrated current regression passed 347 native checks: original north/east/library/west245, V4 current-default91, new dorm7 and opt-in display-residency4. The latest library route followed 2,079 actual physics frames. Normal X11/Mesa 2.8× view and full-campus view exit0; first V4 29-check actual ownership proof is reused. No repeated source-poison/GPU matrix, manual northern walking, full story validation, or hardware VRAM/performance claim is made. The minimal QA shell uses the exact campus source while excluding unrelated story/runtime assets. Broader full-project CI is pending publication.

Recovery requires applying the cumulative overlay to exact PR138 source commit72fcafd285dd388eed2735be71b60fa23f428548. Target branch is godot-version, whose read-only head is f08bdc4ebbee5a5c112e35f93e1cee13ee5636f2. PR138 remains unmerged. Source publication therefore includes its existing code, not all-new modifications.

Publication uses the unique work/buct-campus-hd-resume-20261014 branch, a new Draft PR to godot-version, and no merge. Prior unknown write is not replayed or overwritten. Validation JSON publication flags describe their local acceptance snapshot before upload. Current remote publication status belongs to the PR, once created.

## Clean-checkout publication repair, 2026-10-14

PR #140's first full native CI run (38557513567) failed because the source overlay omitted the 15 new PNG `.import` configurations. Fresh Godot defaults lacked the required mipmaps and could alter transparent RGB, so strict asset registration correctly refused the HD layers. The fix commits lossless, mipmaps-enabled, no-alpha-border-rewrite import configuration as source; `.godot` caches remain excluded. Original PNG bytes, RGBA hashes and registrations are unchanged.

The same run exposed a real cached-campus detach/reentry issue: the northern road retired its authored permission on exit without restoring it on reentry. Its lifecycle now restores only the same validated polygon/guard under its original owner, while explicit uninstall remains retired. Existing old water assertions now retain 81 original paving polygons plus the already accepted east/north additions (83 total); the preparation test checks all 59 exact repaired boundary segments instead of the pre-repair count60.

A fresh empty-cache campus import and targeted reruns of the ten failed related scripts passed. No old test was disabled, no new GPU matrix was added, and the earlier local 347-check stage evidence remains a historical record. Complete-project CI is rerun on the correction commit; use the current PR check status for its result.
