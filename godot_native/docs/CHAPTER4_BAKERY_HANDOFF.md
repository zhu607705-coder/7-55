# Chapter 4 bakery-to-clock handoff

The original bakery route had three migration defects: its front art could hide the player, endpoint-only movement rejection could stop the full foot box short of the narrow legal lane, and Tasks stayed on the conveyor objective after the hand was collected. This candidate restores the source draw order, reaches legal contact without changing geometry, and selects the existing source task for the exposed/held hand.

## Source correspondence

- `src/modules/ChapterFourElevatorDepthModel.ts` returns player depth9900. Normal bakery crops, machinery, baker and crowd have lower source depths. The two normal A1 bakery crops (`a1_foreground_018`, `a1_midday_queue_front`) and bakery layers remain below the player. Special reveal walls and entrance rules are unchanged; this is not a blanket foot-offset change.
- Original counter bounds are `(80,292,397,90)` and the queue rope is `(129,398,325,10)`. Full foot size is19.5×14.625, with anchor offsetY24.375…39. The 16px gap admits anchorY357.625…359.0. Whole-frame rejection left the actual saved actor atY359.449, so its leftward path remained blocked by0.449px.
- The locked Phaser3.90.0 Arcade `SeparateY`/`ProcessY.RunImmovableBody2` path separates to contact. C4 native axis movement now checks bounded substeps and bisects only the first blocked step to its last legal point. It continues using `can_stand` for the complete body and every current obstacle. Speeds, authored geometry, ranges, floor routes and controller authority are unchanged. An already-overlapped start retains the prior legal-endpoint escape rule; it is not automatically relocated.
- `src/core/QuestModel.ts:selectChapterFour755TaskKey` selects `explore_bakery` → `collect_hour_hand` → `install_hour_hand` from earned facts/items. Native `objective` now follows the same branch and uses the existing source strings. It does not grant facts or change the puzzle.

## Verification and evidence boundaries

Before/after regressions: bakery paint order27checks/2failures →27/0; contact41checks/11failures →41/0; source objective11checks/4failures →11/0. Contact cases cover120/60/30/20FPS, exact source body/blockers, thin-wall contact, displacement limits and invalid-start escape. Early contact-fixture parse/preload failures are preserved in the evidence history, then corrected; they are not called an uninterrupted initial pass.

Actual1180×812 same-earned-copy replay now shows the player, reaches the inspection lamp, runs the original conveyor stop, collects the hand and leaves the narrow lane. Later actual426×860 (window-manager result, not exact430) normal reload shows “回大厅装回旧时针”. The ordinary upper-hall route returns to the clock. A full-desktop pointer drag installs the hand, consumes it once and advances to `room204_restore`. Tasks then says “返回大厅重新调节旧钟”. A normal1180×812 restart preserves the installed fact, consumed hand and original12:25 time. No later puzzle is claimed from this segment.

Two earlier bound-window CUA drags missed. A separate passive print showed Godot receiving root(434,862), the desktop pointer left after resizing, rather than the requested(268,145). The supported full-desktop pointer delivered(268,145) and the existing target accepted it. A full native pointer fixture also succeeds. No speculative target enlargement or drop-routing change was added. The final actual success was repeated on uninstrumented code. This is not physical phone-touch acceptance.

The primary canonical save remains at the earlier bakery approach. The successful continuation uses an explicitly labeled copy derived from that earned save and ordinary inputs; no quest state was injected. Source-assisted navigation and known original target placement are disclosed. Audio used Dummy; no subjective hearing claim. No new art, whitebox prototype, package/release workflow or reading-anchor repair belongs to this scope.

## Proposed submission

Three runtime files: `scripts/world.gd`, `scripts/ui/chapter4_world_layers.gd`, `scripts/chapters/chapter4.gd`.
Three tests: existing `tests/test_chapter4_world.gd`; new `tests/test_chapter4_contact_movement.gd` and `tests/test_chapter4_bakery_objective.gd`.
This document is the seventh file. Diagnostic print scripts and white collision-view prototype remain outside production. Fresh independent bakery-only Linux export passes four packed fixtures (92 checks) and actual1180×812 hand installation/Tasks return. Source affected suite:20/20. This package excludes the separate reading fix, debug whitebox and logging. Scope selection, staging and publication are still pending.
