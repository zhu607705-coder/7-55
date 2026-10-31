# Object-first interaction pass — 2026-10-31

## Scope

All 25 room activities retain their models, targets, saved fields and progression. The 24 dedicated puzzle views and shared electrical workbench now share a physical affordance vocabulary: ribbed grips identify movable parts; press/turn marks match the accepted gesture; destination corners appear while holding the relevant part. Cues follow held pieces rather than their empty tray positions. They do not mark the puzzle solution.

Long objective lines and repeated instructions move into the existing notebooks. Necessary identifiers, measurements and result marks remain visible. Formula retains the real miniature race and its original energy model. Schedule's cards depict photographs, assembly and comparison; the same artifact pictures appear in its output rack. Collaboration/assembly revision counters and history move into the requested record page.

Discrete touch actions submit on the owning finger's release on the same target. Cancellation, focus loss, another finger, a release away and a late release cannot commit them. Existing mouse/keyboard paths remain. Sync restores a canceled tape shift; Flex does not disconnect a receiver on pickup; Perspective supports picking up a previously selected piece again. Shared physical workbenches reject synthesized mouse events after touch release.

## Verification

Pinned native engine: Godot 4.7.1. No engine/assets/dependency migration.

- All 35 room/integration/floor/external/new input suites ran sequentially against a frozen source snapshot with the existing imported resource cache; 4,245 checks passed and all 35 processes exited zero. This route uses the prepared project's autoloads with isolated user data.
- The clean-import isolated aggregate timed out during font import before running its suites. Its failure is retained; it is not counted as a pass. The existing-cache run is the bounded recovery, not a claim of a successful fresh import.
- Three varied-order rounds of host (38), actual file save (19), loader cancellation (21), shared navigation (55), grip/real input (80) and formal-host scaled input (33) passed: 738 checks. The loader transport is a test fixture, not live HTTP.
- Shared typography coverage and Formula presentation checks passed. After the final shared touch guard, three new varied-order rounds of host/save/loader/physical-touch checks passed (369 checks). The old code fails the new physical-touch negative control in eight places; the corrected code passes all 45 checks. The final pantry-only guidance exception also passed physical-touch (45), pantry (52) and typography coverage (9,834) reruns.
- Supplemental screenshot-writing object/pantry/presentation scripts were not counted as headless passes: the first was stopped while awaiting a render frame, and its successors were not run in that mode.
- The new root and campus tests are registered for ordinary native CI. No model test was replaced by a screenshot check.

## Actual rendered review

Actual OpenGL/llvmpipe native captures cover Formula, Schedule, Focus and Koala at 1280×720 and 844×390. The review fixture uses the formal host and legal room approach positions, not a complete campus walk. Ordinary mouse input placed the car on its start line, started the race with its gate, moved a schedule card, and opened the notebooks. Viewport-routed touch tests also cover 390×844, second fingers, cancellation, reentry and shared return navigation.

The existing fixed 960×540 apparatus composition still makes some secondary labels about 9–10 screen pixels at 844×390. Host return controls remain 44 screen pixels tall. This is not a complete responsive-layout redesign, physical-device acceptance, all-25-room manual playthrough, or all-25-room 3D conversion.

Production Web loading and durable reload acceptance must be checked by exact-head CI after publication. The previously known Wenli GPU failures are unrelated and must not be described as an all-green native baseline. No merge or deployment is part of this change.
