# Recovery035 reading-area inventory clearance

The collapsed inventory rail covered the start of the photo instruction and two numbered selection rows on an ordinary 430-pixel saved-game replay. The same rail also covered the opening lines of the building notice. Recovery and Voice already used a clear header/outer-margin anchor.

The existing reading anchor now also covers the active journal, photos, notice, messages and network pages. Home's ordinary `photos` route joins it only when the lake is complete and Recovery is unfinished, matching the existing app-content alias. Other pages and completed-Recovery behavior retain their previous placement.

Only the page eligibility function changes. Original artwork, text, scroll canvas, puzzle order, evidence/controller state, item inventory and expanded drawer geometry are unchanged. Existing anchor-change gesture cancellation and 44-physical-pixel hit padding remain in use.

## Verification

- The expanded anchor regression reproduces 155 failures / 802 checks on the previous runtime; it passes 814 checks after the fix. The conditional painted-face assertions account for the count difference.
- Coverage includes 390×844, 430×860, 1180×812 and 844×390; header separation, physical hit target, state preservation, expanded drawer, drag cancellation, page transition, and the completed/lake-phase guards.
- Five affected scripts pass: PhoneChrome, inventory gestures, Recovery photo layout, Recovery UI motion and modal/world input.
- Actual same-save 430 replay: Home Photos → open bag → inspect campus card → close → select a frame → Return → reenter Photos → Reorder → notice page → Save. The three numbered slots and the original notice text remain clear. Item, lake and interlude facts are unchanged; the test selection was reset.
- Fresh Linux export passes. The same814 assertions pass against the final PCK from outside the source project. Actual1180×812/390×844 final package replay confirms clear photo text, bag open/close, safe off-target item drop, independent Tasks, and selected-frame Save/restart. Reorder and Back restore the original Recovery0/4 page.

Actual evidence: `recovery-consumer-flow-stage/photo-overlap-before-430` and `photo-overlap-after-430`, `actual-final-390` and `actual-final-reload-390`. Main campaign save remains unchanged. The reading replay does not claim a new puzzle solution, hearing acceptance or physical-phone acceptance; its audio driver was Dummy. No full-suite rerun is claimed for this page-list change.
