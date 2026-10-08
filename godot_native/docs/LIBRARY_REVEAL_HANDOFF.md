# Library shelf → archived rule handoff

## Bounded repair

Base: `b2efa273b47e6b1d4e2de12efc6440aacb3b9e02` (PR78, including PR77).

The original `lib_shelf` controller consumes the earned `callNumber755`, grants
`archivedLeaveRule`, and saves before emitting its existing `library_rule` page
intent. It never creates a book item. The shell now retains the visible Library
world until its existing cabinet/paper reveal completes, then reveals the same
reader once. It does not dispatch `lib_read_rule` or repeat the controller action.

The source animation is unchanged: 13 delayed frames, paper at 2215 ms, completion
at 2895 ms; reduced motion uses 140/380 ms. The cabinet ends at +16 source pixels.
Collision retains the original rail/cabinet union and movement remains blocked
through the reveal. No replacement native Library scene or new asset is added.

## Ownership and interruption

The pending handoff retains the actual `State.d` identity, the exact Library layer,
and its runtime serial. Only the matching existing completion cue, with
`itemId=archivedLeaveRule` and that serial, can reveal the reader after completion.
Equal-content snapshots, retired layers, stale serials, early or repeated cues,
and cancelled or replaced state cannot reopen it.

Esc cancels the reveal and remains in the world. The existing phone button/P
cancels and opens the homepage. Page/scene changes, runtime reset, modal/story
replacement and actual save reload also retire the pending owner. Cancellation
settles the already-earned cabinet without a completion cue. Reload/re-entry
shows the final pose without replay. The layer's optional finish method only
converges presentation and queues the same cue; it cannot acquire or read an item.

## Verification

- New integration test: 1729 assertions, zero failures, at 390×844, 430×860 and
  1440×900. Includes source-controller-earned prerequisite actions, native
  root-viewport inventory drags, every source cabinet frame, both timelines,
  actual file save/load, repeat use, owner/serial attacks, skip, ten interruption
  routes, scene re-entry, and actual new-game reset
- Existing focused suites: Library layers 111, rule action 234, return-to-scene
  156 and Room302 Main 80 assertions, all passing in the initial focused run
- Actual cloud Linux Godot 4.6.3 CUA: earned number dragged onto the rendered
  cabinet; normal processing retained visible shaking/sliding/paper; the
  existing reader opened once at the 2895 ms settled source clock, with
  `archivedRuleRead=false`. A second actual drag interrupted by P opened the
  homepage; Esc returned to the final cabinet and retained rule, with no delayed
  reader reopening
- The manual CUA harness uses the same controller-earned test fixture with an
  explicit near-shelf spatial placement. It is not a fresh full-chapter traversal
- Automated pointer input is emulated. Actual CUA ran at 1180×812 on Linux
  llvmpipe. No physical phone or Windows runtime claim is made

Run `res://tests/test_library_reveal_handoff.gd` with isolated XDG directories.
Optional `--manual` keeps an 1180×812 earned fixture running for CUA, and
`LIBRARY_REVEAL_CAPTURE_DIR` captures actual rendered phase frames. The ordinary
headless report uses `LIBRARY_REVEAL_REPORT`. The broader native/source aggregate
and exact-head CI must be checked separately before merge.
