# Native phone shell chrome

`phone_chrome.gd` reconstructs the shared React phone overlays with native Godot Controls, Buttons, drawing primitives, and native drag-and-drop. It is a presentation-only component; it does not mutate the progression state.

## Integration contract

- Keep the outer phone at 430 × 860 with its source 3px border. Mount the chrome and app content as siblings in the inner 424 × 854 Control. Both fill the same rectangle; do not add a status/task spacer or global footer.
- Call `setup(read_state_callable)` once and `refresh(state)` on state changes. `set_input_blocked(bool)` controls the overlay inputs.
- Connect `page_requested("control_center")`, `task_requested`, and `inspect_requested(item_metadata)` to Main’s native page/objective/inspect implementations.
- Connect `utility_requested("inventory_toggle")` to Main’s `ui.inventoryOpen` toggle. Connect `item_selected(id)` to selection/clearing (the empty string clears) and `items_combined(from_id,to_id)` to the existing item-combination dispatcher. Drag payloads remain `{kind: "inventory_item", item: item_id}` for existing scene drop targets.
- Main-owned control center, task drawer, item inspection, dialogue, and toast layers retain their respective source stacking. The control center is z65, above the brightness veil and pixel grid but below the z76 task trigger.

## Source coverage

References: `src/components/PhoneShell.tsx`, `StatusBar.tsx`, `QuestClueStrip.tsx`, `InventoryBar.tsx`, `InventoryAcquisitionFeedback.tsx`, `PixelIcon.tsx`, `src/styles/base.css`, and `src/styles/shell.css`.

- Absolute 40px status overlay, 76 × 30 task trigger at centered y5, expanding to 136px for the chapter-one code hint. Source chapter-two task suppression retained.
- Authored local Fusion Pixel font, time letter spacing, network-label tracking, native wifi/cellular/5G and battery drawing. Low battery red, critical blink, low-power “省”, offline label, chapter-four state clock and trust warning.
- Left inventory starts at y240. The collapsed source handle, count badge, 74px expanded body, 52px vertical item targets, 8px gaps, bounded scroll, and source movement clamps are reconstructed.
- Every pixel icon uses the exact `PixelIcon.tsx` rows and palettes; the 11 raster overrides load the existing original assets. Inventory ordering and item metadata are source-owned.
- Native object selection, double-click object inspection, single-click paper inspection, Enter inspection, Space selection, item dragging and item-to-item combination intents.
- Ownership changes trigger the source-timed 980ms stepped acquisition flight, clearing at 1150ms. Restored initial inventory does not play a false acquisition.
- Alarm, desktop, and ending are bare. Inventory is absent when empty and suppressed while check-in has completed but inventory has not been recovered.
- Source brightness veil `max(0, (70 - brightness) / 70) * 0.3`, with the source dark tint. Native multiply-blended 3px texture grid and hard-edged source shadows.

## Validation and remaining differences

`tests/test_phone_chrome.gd` passes 59 assertions under Godot 4.6.3 with an isolated user-data directory, including actual Viewport drag state, geometry, signals, font/art, keyboard, brightness, network, clock trust, inventory recovery, and scaled logical dimensions.

Main now integrates the task drawer, item/document inspection, control center and toasts; State and chapter controllers own scene-drop acceptance, and AudioDirector owns global audio. Frame/shake and source transient effects retain the differences listed below. Native drag-start distance and scroll feel use Godot platform behavior rather than React pointer-capture implementation. The short task-update scan, slot-arrival flash, and handle-arrival shake are not yet reproduced. Actual cloud graphical captures now cover phone/app views at430px and390px, including compact device forms, required lake app controls and shell containment. The earlier X-display capture limitation is resolved. Running-original browser pixel comparison remains unverified because its preview is blocked by the environment extension; physical-phone testing is also unverified. Geometry/input checks and native visual review do not establish screenshot-perfect parity.
