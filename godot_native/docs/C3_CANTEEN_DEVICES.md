# Canteen device surfaces

This slice restores the drink and menu device interactions and adapts the existing bicycle lock interaction to a native modal. It does not add a quest, inventory item, code answer, or progression gate.

| Existing route | Previous native behavior | New player interaction |
| --- | --- | --- |
| Shelf → three machines → mixer | Space on a machine immediately granted its bottle | The named bottle is shown with Take and Cancel. Left/A and Right/D select; Enter/Space confirms. Escape or pointer/touch Cancel returns empty-handed. |
| Promotion → ordering kiosk → 0755 ticket → matching pickup | Light menu used a phone answer selector; dark menu emitted a text paragraph | The five source dish names appear on the kiosk. Mode changes show the authored alternate words. Dark selection gives the source refusal. A light choice issues the existing order and dismisses the kiosk before its authored dialogue. |
| Defense → campus bike → owned tissue → owned wages → chase | Generic phone actions listed inspection, cleaning, payment and chase | A lock surface shows its glare, optional dark edge impression, existing cash balance and owned-item actions. Cleaning retains the tissue. Payment consumes the earned wages and ¥2 exactly once. Ride enters the existing chase. |

The bicycle source is an in-world lock interaction, not an original modal. This modal is a native presentation adaptation of `BootScene` and `ChapterThreeCanteenController`; its lock drawing is an abstract impression, not a new QR code or puzzle answer. The existing controller remains authoritative. Native world inventory drops did not expose a bicycle accepted-item target before this slice; that source gesture is still a separate gap. The panel exposes the existing owned-item actions. Reading the dark imprint is optional, exactly as in source.

## Input and layout

One Main modal owner blocks movement, item dragging and underlying world clicks. Closing returns focus to the world. Device opening keeps overlay focus until explicit navigation or confirmation; Take remains the default drink choice. Drink pointer actions finish dismissal after the current input event; launching the chase occurs after dismissal, preventing detached-Control input errors. Reopen never resets inventory, cleaned-lock state, payment, current order or cash.

Desktop drink controls and menu option rectangles retain their source logical positions in the 960 × 540 world surface. Mode and close actions are accessible native additions below the desktop menu board. Compact portrait and landscape use independent, unscaled layouts with at least 14 physical px text and 44 × 44 px targets. They share the same controller and source labels. Refusal captions mirror only the currently active world subtitle and its existing timer; no second dialogue or audio owner is created.

## Authority and source checks

`tests/export_c3_canteen_devices_source.mjs` executes extracted original TypeScript scene/controller methods with recording ports. Its fixture carries source file and extracted-method hashes, positions, source text and transaction outcomes. It runs as a normal build-time source catalog check, never at game runtime.

`test_c3_canteen_source_parity.gd` compares 23 source scenarios and 45 steps, including no grant on cancel, repeat collection, dark menu refusals, pending-order rejection, optional dark bike observation, repeat cleaning, insufficient cash, retained tissue and repeat payment. The source comparison caught a stale-state case: `queueGapOpened=true` blocks further drink collection even if `promoDrinkPlaced=false`. Both the explicit Take intent and device opener now enforce it.

`test_c3_canteen_devices_controls.gd` uses the actual Main/world opening path and root viewport keyboard, mouse and touch input at 1280 × 720, 960 × 540, 390 × 844, 430 × 860 and 844 × 390. Assertions cover physical control/text sizes, visibility, focus, no-grant cancellation, refusal captions, existing item actions and actual chase launch. Source-authored stand placement is test setup, not physical-navigation evidence.

## Acceptance boundary

These automated scenarios and `capture_c3_canteen_devices.gd` are declared, isolated Chapter 3 fixtures. They do not prove uninterrupted C1–C3 completion or actual phone hardware acceptance. The bounded CUA report, final test totals and reviewed image hashes are in the accompanying staging validation report. Final merged-tree campaign/export checks belong to the integration lead.

### Graphical review and manual result

Thirty-two graphical fixtures cover all three bottles, dark-menu refusal, light menu, bike glare, dark-mode refusal and paid lock at 1280 × 720, 390 × 844, 430 × 860 and 844 × 390. Review corrected the desktop light-menu feedback label, which was dark text below the beige board. These fixtures precede the final opening-focus hardening; that change does not alter geometry, labels or controller effects and was checked in the manual route below.

Actual CUA used the original `c3-canteen-drinks` developer checkpoint in a separate profile, then walked through the aisle to the blue drink machine. The final build visibly opened Take/Cancel without adding the bottle. Right/Enter canceled with unchanged inventory. A second opening followed by Enter added the bottle. Screenshots preserve both outcomes. This is local DEV-checkpoint acceptance, not an earned complete chapter.

An earlier CUA sequence raised concern about opening Space and auto-focus, so opening now leaves focus on the overlay and drink key releases are consumed. The old-focus negative control still passed synthetic multi-frame key tests. Therefore this is input hardening; an auto-grant bug is not conclusively reproduced, and delayed screen observation remains a possible explanation. Final keyboard, mouse and touch tests use OS-style input across rendered frames and pass.
