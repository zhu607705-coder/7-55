# Room204 original task and projection feedback

Restoring all12 desk-chair pairs previously left the native Tasks drawer at a generic “核对现场记录与204投影”. If the duty-board record was still missing, the projection controller incorrectly said furniture remained incomplete. The source QuestModel instead lists the remaining original floor-two records, stop reconstruction and floor-one records in order. Its projection rejection identifies the actual missing prerequisite.

The patch restores that ordered task selection and exact source rejection strings. Original content and acceptance remain authoritative. No record, target geometry, placement,900ms timing, save schema or result proof is changed.

Source correspondence: src/core/QuestModel.ts835–860; src/modules/ChapterFourTemporalMazeController.ts665–696 and1333–1347; source chapter4-755.content.json tasks and intentFeedback. The readiness predicate is unchanged.

Validation: initial17 checks failed6; the same17 pass after repair. Strengthened source-branch coverage passes57, both with a copy of the recorded input and as a standalone synthetic fixture. Existing chapter114, guard17, clock reentry30 and bakery objective11 checks pass. This is affected validation, not a fresh aggregate/export.

Actual source-run replay at1180×812: unmodified earned all12 autosave a430e120 loaded normally; Tasks names the remaining second-floor records; actual projection rejection named the missing A1 duty board; ordinary walking and return elevator reachedA1 while retaining12 placements and no projection completion. Immediate CUA showed the rejection sentence, but the later F12 image caught its expired state. That F12 image is not sentence proof. Input/navigation was source-assisted. Dummy audio is not hearing acceptance.

Separate open finding: the room-wide residual rectangle covers most of the podium drawer, intercepting ordinary center clicks. The exposed upper strip reaches it. No pick-order repair is included. Specific F10 Save was denied twice in the previous run, remains unverified and was not retried. Ordinary autosave/reload and normal window close were observed.

Scope: one controller file, one focused test, this document. This isolated follow-up does not alter the frozen26-file integration proposal. No Git staging, commit or publication has occurred. A production submission also requires the repository progress entry after exact scope selection.
