# Future Learning Center: formal optional activity

## Source reconciliation

This work starts from main `8d1f464789f7dd5041f12d364deee7d753a5abf7`
(PR #196), then reconciles the tested #197 stack. The latest main's five physical
bench implementations are retained. They are not silently treated as equivalent
to differently authored exercises in the earlier 25-room implementation.

There are **25 rooms and 29 activity objects**, not 29 room completions:

| Room | Latest-main object retained | Distinct original exercise retained |
| --- | --- | --- |
| Electrical | Physical gear/belt/tension bench | Reverse target merged into that same bench |
| Formula | Solar miniature bench at workbench 0 | Power-limited comparison at workbench 1 |
| Robotics | Modular delivery track at workbench 30 | Directed return/unloading target at workbench 31 |
| Team | Live/cached screen wiring at desk 6 | Movable-screen synchronization at desk 18 |
| Pantry | Slow water filling and support balance at island 250 | Fixed-weight, direct-carry tray at desk 262 |

The remaining 20 room goals are unchanged. Physical table geometry and legal
approaches determine entry. An active station blocks underlying movement and
other station entry. The original and additional exercises keep separate save
identities; opening an object never awards either exercise's completion.

## Formal entry and ownership

The ordinary entry chooser exposes Future Learning Center free exploration.
It enters the real Main activity owner, not a sample launcher or developer
checkpoint. A Control adapter hosts the existing floor in a 960×540 SubViewport,
fits it uniformly, and keeps the return control reachable on small screens.
The dedicated entry does not start the story phone/world behind the activity.

The player's existing story scene, player position, inventory, checkpoint and
chapter flags remain unchanged. This optional activity adds no story gates,
rewards, item grants or fictional geographic connection to another campus.

## Durable checkpoints

`State.native.flc_rooms` is an optional versioned namespace. Old saves without it
remain valid and have no inferred learning-center completion. A pure core codec
validates checkpoints even before the optional content pack is loaded. The
existing State atomic file replacement, previous-valid backup and browser
persistence acknowledgement remain the storage authority.

Room checkpoints preserve committed configuration and genuine model evidence.
Active pointer ownership, dragging previews and live timers are not a saved
operation. Close, focus loss and activity exit cancel input before checkpointing;
completed proof changes can be checkpointed while the activity remains open.
Reload returns to a validated floor position with experiments stopped. It does
not replay a partially completed trial, call a model's completion method or
invent a completion from visits, clue reads or elapsed time. Records remain
available through the physical notebooks.

The optional floor location is checked against current collision geometry before
use. Invalid standing coordinates fall back to the authored floor spawn.

## Production delivery boundary

The production story-only feature remains enabled. Only the explicit
`flc_activity` lazy family is added. Other research campuses, their assets and
unknown campus paths remain excluded. The normal FLC entrance requests its
required content before mounting the activity; a failed load cannot be reported
as an empty successful family.

## Verification ledger

Local checks completed before submission:
- All 25 original puzzle suites and retained external model suites.
- Physical workbench: 143 assertions; floor approaches: 22; object integration:
  307, including 29 unique anchors and mutually exclusive ordinary object entry.
- Actual Main entry, return, repeated entry, three viewport sizes, visibility and
  browser touch-cancellation dispatch without changing story state: 37 host checks.
- Optional FLC loading cancellation, retry, concurrent story waiters and late
  callbacks: 21 checks; unchanged loader regression: 84 checks.
- Codec behavior and schema: 1196 checks across all 29 models; real-file
  reload/import/export, old-save acceptance, failed-write rollback and previous-valid
  backup recovery: 19 checks. Tests use the existing native test isolation guard.
- Production-family policy and real export/browser acceptance are separate from
  standalone native checks. Desktop touch injection is not a physical-phone test.

The source critical suite passed all 27 validators. The local release suite
passed 35 of 38, including the production source build. The offline single-file
build was terminated (`Killed`, exit 137); its two dependent artifact/browser
checks consequently had no artifact. Exact-head CI remains the release gate.

Native GUI evidence shows ordinary entry, a physical 30-degree knob change,
return and re-entry with that configuration retained. This is not a Web reload
claim: the shared desktop browser reports WebGL2 unavailable. The standard CI
runner has a separate two-profile FLC entry/object/save/reload acceptance job.

No merge or deployment is performed by this work.
