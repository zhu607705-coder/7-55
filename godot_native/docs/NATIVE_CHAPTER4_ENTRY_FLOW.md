# Native phone/world modes and Chapter 4 entry

The desktop split made the original world small, while the Recovery → Chapter 4 handoff shrank its text and controls into a landscape strip on phones. The accepted chapter transition could also run its paper animation behind the phone. This change keeps one visible phone or world surface and restores the original entry interaction in native Godot.

- The desktop world fills the play area. `P` opens the existing phone; `Esc` returns after child dialogs are closed. The retained world, camera, actor and controller remain the same instances. Portrait exploration uses the existing responsive camera. Resizing does not switch surfaces.
- Tasks, the expandable world inventory, dialogs, documents, activities and world effects retain exclusive input ownership. Surface changes cancel gestures; returning from a world modal/effect restores the existing world's keyboard focus.
- The accepted Recovery Replay transition opens one original movie without an extra generic Play page. Ordinary `replay_ready` startup uses the same admission. Explicit Return stays closed until another request; resize/refresh cannot reopen it.
- The original 16:9 movie is unchanged. Its subtitle and controls use physical text/target sizes. The task card preserves the original location and goal. Skip reaches the card and still requires an explicit acknowledgment. Only an accepted controller proof reveals the committed C4 world and original paper-flight effect.
- The source paper, typography, stamp and seven-second timing are retained. Portrait reflows the source close-up and clock-inspection text within the tall scene instead of scaling all text down with a 960×540 viewport.
- The hall-clock panel restores the original face, option labels, current/“刻痕清晰” status, wrapping arrow selection, Enter confirmation, Escape return and local rebound feedback. The required mark comes from the existing controller's read-only rule. The same controller remains the only owner of time/phase changes.

## Source correspondence

- `src/components/Chapter4PrologueRuntimeGate.tsx`: accepted Replay admission and committed-world handoff
- `src/modules/ChapterThreePhoneInterludeController.ts`: `startRecoveredReplay`
- `src/scenes/rpg/ChapterFourPaperPickupPresentation.ts`: paper geometry, original text, stamp and timing
- `src/scenes/rpg/ChapterFourTemporalMazeScene.ts`: `openClockPanel`, `paintClockPanel`, `updateClockPanelKeyboard`, `submitClockPanelSelection`
- Original OGV, font, floor/state images, player/prop atlases, controller data and collision logic are unchanged

The C4 hall remains a source background/state image plus separately drawn player/dynamic atlas layers and data-driven collision checks in a native Control/SubViewport. This change does not turn each wall or desk into an independent 3D mesh or physics body.

## Verification and limits

Initial actual earned-copy checks cover desktop world/phone/Tasks/bag returns, the full Recovery movie, explicit Return and Skip, C4 entry, paper pickup, the clock, wrong-time feedback, Escape/Space reentry, the 12:25 daylight change and the bakery objective. Later actual runs use verified 390×844 and 430×860 windows; earlier 426px runs remain labelled separately.

The real 390px run reproduces and then closes the missing Space focus problem after a clock modal. The original paper close-up has an actual entry-frame screenshot; its remaining timed poses are not all captured manually. The full 218-stage run initially passed 217 stages and caught an inventory-focus regression in the remaining test. The final conditional focus restoration passed all 11 affected scripts, including the unchanged 348-check bag-focus contract. This is a reconciled gate, not a claim that the initial full run passed uninterrupted on the final revision.

A fresh Linux pack passed the automated campaign, empty-PATH native first/reload, and packed surface, handoff and clock checks. Actual standalone desktop play repeated wrong/cancel/reopen/correct clock input, the daylight objective, bag inspection/reopening and phone/world return. A bound-window P-key automation failure was distinguished from desktop keyboard input: the unchanged pack passes P in both directions and ignores P while Tasks is open. A speculative shortcut change was reverted. Ordinary packaged reload at exact390×844 retains daylight, bakery objective and all six items. Actual Tasks/Return, double-click inspection, phone return and on-screen joystick movement pass. Fixture tests are not earned campaign proof.

These runs use Dummy audio and make no hearing claim. Physical phone/touch hardware, full campaign manual acceptance and browser pixel comparison remain open. Other phone pages retain their original canonical phone scaling; this is not a claim that every small label or landscape phone page is repaired. Original art remains the baseline; no rejected card/food replacement or bun-model sample is included.
