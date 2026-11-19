# Public-edition save recovery, 2026-11-16

## Reproduced source and scope

- Main: `358fdba968604eb201369e9e33fb20b8cb8abf5d`, merged PR #256 head `2026d7c928055cfb47b8e7c4694f6910b5ac3d96`.
- The public `build-manifest.json` reported that same main commit, Godot `4.7.1.stable.official`, and `releasePolicy.publicChapterLimit: 2`. Its source input digest was `b9f2595b3a2f87c66b443d168e620bbcabe804607fd9876c5c7ae3c8e05a91db`.
- [Backup review](https://github.com/zhu607705-coder/7-55/pull/256#discussion_r4579049764) and [guest-document review](https://github.com/zhu607705-coder/7-55/pull/256#discussion_r4579049767) remained unresolved. No later fix or open PR was found before this work.
- Tests used Godot `4.7.1.stable.official.a13da4feb` and separate temporary `user://` directories. No real player save or document was read or changed.

## Before and after

1. Create a valid Chapter 3 primary and previous snapshot. Apply the serialized public-edition policy, explicitly restart, and save two distinct new checkpoints. The old source kept the Chapter 3 backup despite successfully archiving it. Corrupting the new primary then blocked continuation instead of recovering the new campaign. A control without a locked backup recovered normally.
2. Create a valid legacy Chapter 3 save plus separate personal and quest-post edits. Activate the guest profile and explicitly restart. The old source left both guest document paths absent, including after re-entry. The original legacy files remained byte-identical; the failure was missing migration, not deletion. A playable legacy-save control migrated both documents normally.

The writer now rotates a chapter-locked backup only when its archive contains exactly the same bytes. Missing, conflicting or damaged archives cannot authorize overwriting the old backup. The original restart and chapter-availability gates remain in place.

Guest documents migrate independently of story availability. This also repairs missing documents for guests who already restarted under the affected release. Existing guest documents are never replaced. Invalid or failed document migration leaves source files intact, rolls back a partial document pair, and disables persistence until activation succeeds.

## Verification

Command, after source/media preparation:

```sh
GODOT_BIN=/path/to/Godot_v4.7.1-stable_linux.x86_64 \
node godot_native/tools/validate_native.mjs --profile changed \
  --test test_public_chapter_save_recovery.gd \
  --test test_public_chapter_limit.gd \
  --test test_cloud_profiles.gd \
  --test test_cloud_guest_return.gd \
  --test test_future_native_saves.gd \
  --test test_save_integration.gd \
  --test test_save_domain_guard.gd
```

All 12 selected stages passed, including preparation/isolation, import, startup and 1,162-script parsing. Focused results: new recovery regression 100 checks; cloud profiles 148; guest return 14; future saves 28; domain guard 1,010; save integration 1,853 checks and 236 real-file browser-save imports. The existing public chapter-limit test also passed.

The new test covers successful restart, subsequent backup rotation, corrupt-primary recovery, archive conflicts/damage, playable legacy controls, missing guest documents after an earlier restart, preservation of newer guest edits, invalid document input, failed second-document promotion, rollback and retry.

This is native real-file validation, not a new browser/IndexedDB or physical-device run. The focused suite is not full release acceptance. PR browser and full native CI remain separate gates; creating this change does not publish it.
