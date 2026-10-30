# 3F pantry extension — F1 / F2 verdict pass

## 1. Scope

Limited to the two material findings in `finish_review.md`. This pass scores their corrections only; it is not a new whole-surface review or a release approval. No additional polish findings were sought.

## 2. Fix scores

| Finding | Score | Evidence and reason |
| --- | --- | --- |
| F1 — Separate the destination table from the source table | **resolved** | Desktop and touch initial, balanced, carrying, and served captures show cleanly separated tabletop edges. Browser initial, balanced, and served captures confirm the same correction at 903 × 862. The former triangular coplanar join is gone; the tray remains fully supported by the destination when served. “沙发茶几” now occupies clear space beside that table, and the resting “提手” label is legible on the dark source table. `pantry_miniature.gd:18` moves the source-table center to y383 and reduces its depth to 264, creating a positive planar gap while retaining the coffee table, tray destination, and shared camera. |
| F2 — Make the notebook's record agree with the actual trial | **resolved** | The new page-0 captures show neutral guidance before the first trial, the actual rightward failure, a level tray explicitly not yet delivered, and successful delivery. Desktop and touch evidence covers all four states; browser captures confirm the initial and served text. `pantry_tray_view.gd:125-135` now selects text from the actual phase and uses `last_moment` for failure direction. It returns to neutral guidance after configuration changes or canceled trials, rather than fabricating another completed trial. The three voluntary clue pages remain separate. |

## 3. Evidence checked

Independently opened these 21 current captures; every file showed its named state and was valid:

- Both `desktop/` and `mobile/`: `pantry_initial.png`, `pantry_balanced.png`, `pantry_carrying.png`, `pantry_served.png`, plus `pantry_record_initial.png`, `pantry_record_tilted.png`, `pantry_record_balanced.png`, and `pantry_record_served.png` — 16 images.
- Browser: `browser_initial.png`, `browser_balanced.png`, `browser_served.png`, `browser_record_initial.png`, and `browser_record_served.png` — 5 images.

The revised native input reports record 29 checks, zero failures, and zero keyboard events for each of desktop 1280 × 720 and simulated touch 844 × 390. The inspected test source adds five record-truth assertions, including neutral text after a cup-layout change. The ordinary delivery checks still pass. I reviewed the reports and source; I did not rerun the tests or operate the browser.

## 4. Coverage limits

The build packet reports the rebuilt WASM browser replay and empty warning/error logs. This verdict directly uses its static captures; native `pantry_carrying.png` supplies the transport-midpoint evidence. `browser_delivery_start.png` was not treated as a midpoint capture.

The final preflight metadata still records five passing selected checks, 536 not run, unchanged inputs during the run, and `fullSuitePassed: false`. Physical-device touch, other browser engines, production save/campaign integration, and full-release acceptance remain outside this verdict. No new raster assets were created. The remaining recaptured room, hint, advanced, and failure images were not re-reviewed for unrelated issues in this limited pass.

## 5. Final disposition

Both listed fixes are resolved at the reviewed scope.

ship
