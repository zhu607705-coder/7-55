# Anchor 50: Room301 index drawer and film

Original base: `93c21feeaa9c8699b40c952c1184a9fd5d49d472`; safely rebased onto `2bbb5f02e0494969d01e88283affc39bc90d3788` before the index-strip refinement, then rebased onto `de39f07479c62a00149cfc99d8fc75c6c535615c` for the publication candidate. This is the design book's original anchor 50, not a new numbered task or a collection of new anchors. The design book has 54 anchors / 196 key poses. Room201 and Room302 remain intact.

## Story and authority

The original A3 / `room204_restore` archive entrance, three selection dimensions, and correct answer are unchanged: `1991_1998`, `A3`, `wayfinding`. The only submitted action is `c4_solve_archive_index`. The existing Chapter4 controller alone grants `a3_archive_film_retrieved`; no inventory item, save schema, controller, prerequisite, transport route, or narrative text is changed.

The revised proposal replaces the nine outside option cards with three narrow index strips attached to the original drawer. Tap an end or swipe horizontally to move one step through that original field's choices. A held gesture does not auto-repeat. A vertical drag on a strip cannot pull the drawer, and a horizontal handle drag cannot change an index. Pull/tap the brass handle to submit. Up/Down focuses a strip, Left/Right changes its value, and Enter submits. Return retains normal keyboard activation. These are equivalent input paths, not extra mandatory puzzle steps. The original dark-mode evidence remains read-only. Wrong answers preserve the current local selections. Unfinished close/reopen discards them, exactly like the original ephemeral device session.

The view uses the existing exclusive native device host. Closing restores the retained world viewport, player, camera, pan, focus, shell visibility, and input. A real ordinary save reload replaces the State owner, retires the old modal and its gesture, and prevents stale callbacks from acting on the replacement session.

## Original object art and independent parts

Production rendering uses only the original `chapter4_a3_archive_film_v01.png` (96 × 82): SHA-256 `51f085170a7167fa1c18da4e670bf94cecf94d5d80e419885949402b598868cc`.

`room301_archive_art.gd` separates source regions for the fixed upper case, moving front board, amber film, and a same-source paper cover after film removal. It does not rewrite the PNG. Both near-view and world rendering retain uniform source registration. Attached index strips are native paper controls with source-derived palette and source JSON labels, not replacement room artwork. A newly generated higher-resolution atlas was left as an unapproved local candidate; production code does not reference it.

The original world anchor is `(290,350)` with source extent `96 × 82`. The film presentation is not a clickable collectible, and cannot grant anything. Picking and story interaction remain at the existing archive target.

## Design-book timing and bounded differences

- Opening: the front reveals 5 source pixels over 220 ms; input is not locked by that entrance motion
- Cancel: local world front closes within 180 ms
- First accepted result: controller commit is immediate; the world film handoff waits for the existing panel to close
- World handoff: film reaches its local lift at 480 ms, moves right/up and fades by 760 ms, and the front returns by 1000 ms
- Completed reentry/reload: empty-film terminal state; no acquisition replay, fact grant, or generated interaction checkpoint
- Reduced motion: no extra lift/rebound; the accepted terminal state and original input requirements remain intact

The extension beyond the design page is a dedicated object close-up. Following feedback on the external nine-card layout, a reversible proposal integrates the three fields into the drawer itself. The design page originally described retaining the generic selector panel. No extra selection field or solve step was added. Acquisition still occurs at the source world anchor after close, with the player's existing camera. It counts as anchor 50 only.

## Validation and evidence limits

Focused automated checks cover source answers, dark read-only behavior, local wrong feedback, cancellation, one touch/device ownership, unrelated releases, strip swipes and independent handle drags, keyboard alternatives, resize/focus/hide/input-family changes, pending and completed duplicate submits, completed reentry, current-state identity, stale retired callbacks, ordinary State save/reload, exact source animation boundaries, and reduced motion.

`test_room301_archive.gd`: 84 new index-strip checks. `test_room301_archive_main.gd`: 49 checks through the revised real selector controls. Both pass for the prototype. The earlier nine-card version's 90-check result is archived separately and is not reused as evidence for this input revision. Shared regressions passed: device panels 2462, device Main 38, Room201 Main 67, Room302 Main 80, and Chapter4 phase world 37.

The Main test reuses the existing `room302_earned_film_entry.json` native A3 fixture and removes only the original archive result. It then earns that result through the original solver. This is not a new human walkthrough from Chapter4's beginning. The first attempted test used a developer checkpoint without valid ordinary elevator proof; the save correctly rejected it. The test fixture was corrected; save validation was not relaxed.

The earlier nine-card variant's actual cloud-Linux CUA input exercised wrong and correct cards, card-to-drawer dragging, a downward handle pull, completed Enter, Return keyboard activation, original-world archive reentry, and a live 390×844 to 1180×812 resize. The final source-polygon/side-rail correction was recaptured and reviewed at 1280×720 and 390×844: 20 actual renderer images cover wrong/success/reentry and the four source world-handoff poses, with 2/2 fixture assertions at each size. The film no longer leaves an orange edge and the pulled front stays connected by native source rails. The world pose images freeze presentation time only; they do not replace actual input evidence. The new attached-index proposal has two native layout previews at 1280×720 and 390×844 (4/4 preview assertions), plus its new 84+49 automated checks. A separate fresh native CUA pass on 2026-10-09 at 390×844 now covers the revised controls: three wrong values with original rejection; two leftward strip swipes, each one step; horizontal handle movement without submission; downward pull with a single accepted original fact; completed Enter without a duplicate; cancellation of a partial selection and original-world reentry with all three values reset; and native keyboard selection followed by a real handle pull. Closing after that world-origin success shows the film at the original drawer, then original-object reentry shows the terminal empty-film state. Two manual-event logs separately record the phone-origin and world-origin sessions. The latter has exactly one solve, false→true; reentry has no second grant. Live CUA handoff and reentry screenshots are distinct from frozen renderer poses. Native touch remains synthetic root-input coverage, not physical phone evidence. Final publication remains pending coordination.

The optional MovieMaker fixture uses the project's fixed 1440×900 capture surface. An earlier 390×844 runtime resize caused a cropped encoded movie despite passing 4/4 gameplay assertions; that movie is rejected and not a delivery artifact. See the local QA result for the corrected movie's separate encoding/framing review.

The persistence test refuses execution outside an isolated `/tmp` profile before replacing any State or writing a save. A non-temporary test profile correctly exited 2 with primary and backup sentinels unchanged; the isolated 49-check Main run then passed again. Scaled 390 × 844 and synthetic touch-event tests are not physical Android/iPhone execution. Audio, Windows, exhaustive campaign traversal, and publication are outside this bounded claim. No GitHub writes have been performed for this candidate; publication and merge are coordinated separately.
