# Native phone app fidelity pass

This is an implementation/QA record, not a claim of pixel-perfect source parity.

## Viewport contract

- Source phone: 430 × 860 outer / 424 × 854 interior
- Main owns the 40 px status area and overlays; app roots occupy at least 424 × 814 underneath it
- Existing builder coordinates remain 378 px wide and are uniformly scaled by 424/378; bare alarm/desktop retain 854 px interior height
- App roots and wrapper clip content. Authored long gallery/thread content remains tall for Main's scroll container; Zjuding/CC98 use internal scroll regions and fixed bottom tabs
- Shared header labels no longer wrap into or under navigation

## Implemented

- Real native 44-ish px back/exit/close targets replace inert chevron labels
- WeChat, photos, weather, bonsai, Tiyi, CC98, Settings and Control Center can leave their authored surface
- Campus card and department directory return to Zjuding
- Check-in returns to Zjuding's `learn` local view; its measured source screenshot hotspot reopens check-in, and Back returns to the hub
- Library subordinate pages return to library home; library home returns to Zjuding
- CC98 generic thread Close returns to feed, alongside existing Back
- Control Center emits an overlay-close intent; Main keeps the underlying app and its local view mounted, with a separate full-interior 424 × 854 overlay builder
- Zjuding uses the source eleven-app registry and access checks; profile card, identity shortcuts, search keywords, personal menu, five bottom tabs, course expansion, network detail, service routing, contacts, messages, language cards, visitor preview, feedback draft and categorized workbench are native views
- Zjuding learn uses the exact existing source `zjuding_home.png` and the CSS-measured 108% crop and check-in hotspot
- Department directory uses the source obscured public support number, actual editable identity fields, a campus-card drop/click reader with the authored 650 ms delay, and controller-owned identity validation
- Weather now follows the source 18°C rain / 19°C overcast projection, cloud silhouette, 1.15 s rain cycle, four detail tiles and full source water collection card; its availability still depends on controller state
- Source Control Center uses network cards, side-by-side music and vertical yellow-fill brightness, four toggles, battery meter, low-power management, and inline source save/reset confirmation; its headphones animate for 550 ms before the collection intent
- Early WeChat restores the four source rows, source-sized text, native avatar silhouettes, authored row toasts and mentor inventory drop target
- Tiyi now uses the exact source `tiyi_main.png` with its original 852/1846 ratio, full-phone-height crop, and percentage-anchored 47 hotspot
- Source system dialogue is a modal over Zjuding and advances one line at a time. Only the final click sends completion. Exact `act2_system_*` source cues emit per line; player and reservation lines remain unvoiced, as in source
- Settings → About exposes the explicitly labeled native extension “存档管理”, emitting `native_save_tools`

## Source references

- `src/components/PhoneNavButton.tsx`
- `src/scenes/phone/P15_Zjuding/index.tsx`, `ZjudingAppRegistry.ts`, `ZjudingUtilityPanel.tsx`
- `src/styles/scenes/p15-zjuding.css`, `src/styles/phone-app-ui.css`
- `src/scenes/phone/P07_Weather/index.tsx`, `src/modules/CampusWeatherModel.ts`, `src/styles/scenes/ch2-movement.css`
- `src/scenes/phone/P04_CampusCard/index.tsx`, `P06_Tiyi/index.tsx`, `P10_Bonsai/index.tsx`, `P11_Checkin/index.tsx`, `P14_Wechat/index.tsx`

## Remaining fidelity gaps

- Home now uses measured source CSS geometry for the campus silhouette, tower, bonsai, weather widget and app grid. Native polygon/gradient/step rasterization is not screenshot-diff certified; source notification entrance animation remains an approximation
- WeChat friend-chat bubbles/attack layout still use earlier native reconstruction; full list source artwork is reconstructed from CSS shapes, not screenshot-diff certified
- Tiyi loading/crash timing remains 1400 ms / 3000 ms + 620 ms; final loading fade and detailed glitch filter are native approximations
- Check-in now has the source bottom-anchored keypad, slot/card dimensions, ready frame, entry pulse, wrong-code state and preserved draft. Native tween easing does not exactly reproduce every CSS stepped keyframe
- Campus card now uses the source CSS portrait, crest, field layout, four shortcuts, full news block, bottom navigation and real inventory-drop balance target. Its native gradient/border rasterization is not screenshot-diff certified
- Library source home, nested rooms/reservation/seat-map/list, catalog and recovery are now native interactive surfaces without generic action fallbacks. Submitted proof opens a read-only source-document modal. Fine CSS animation/filter equivalence still needs screenshot-diff certification. A connected `document_requested` consumer now mounts the same inspector as a full 424×854 Main overlay and blocks shared chrome; standalone tests retain a local fallback
- CC98 authentication now includes the source dark panels, identity reader, sequential hint fragments, password visibility, preserved form drafts, attempt counters, 250 ms lockout countdown and bottom-left exit. A presentation-only native shader applies the source blur/saturation/brightness; its finite sample kernel is not a browser-identical Gaussian
- Zjuding utility fonts and card geometry are source-based, but they are not screenshot-diff-certified. Later-chapter home notifications now use source conditions, timestamps and existing app routes. Main owns general inventory inspection; the exact-document renderer covers submitted Library proofs
- Control Center commits pointer brightness on release to avoid destroying active native drag state; the source browser updates shared brightness continuously during drag. Keyboard uses the source ten-point steps, and the displayed fill follows pointer position immediately
- Source CSS uses pixel-stepped transitions in several places. Native tweens preserve existing durations but do not yet reproduce every step/shape/motion detail

## Completion pass (2026-10-01)

- `native_checkin_page.gd`: source keypad/form layout, local draft, entry/ready/error visuals and existing controller-only ending handoff
- `cc98_login_page.gd`: full source authentication layout and local drafts; gameplay identity/hints/attempts/lockout are controller-owned
- `native_library_pages.gd`: source reader hero, locked static `xxx` slots, library chooser, list/quick modes, exact `1080×2376` source crop `(173,684,298,328)`, original 32-seat table order and all 160-seat lists, date/time/filter sheets, reservation confirmation, original five book covers, terminal-gated evidence and three matching-item recovery slots
- `phone_document_modal.gd`: exact `item_catalog.json` document fields/body/footer and `items.config.json` metadata, preserved after consumption; close/escape and keyboard scroll work without exposing a Use action
- `phone_home_art.gd`: read-only original CSS decoration in 424×854 source coordinates; no new bitmap art or progression state
- `phone_pages.gd`: full-widget weather hit area, source home notifications across chapters, original CSS campus-card art, live reusable-arrow inventory drop, and Control Center interruption preserving authentication drafts/nested Library navigation
- The Chapter 3 `c3_lake_catalog` route now reuses the native catalog, including wet-program input, source abnormal-loan fields and separate controller-owned reflection collection. Normal search stays functional outside Chapter 2

## Validation

- `test_phone_library_login.gd`: 135 checks, 0 failures, including real pointer input, source dimensions, sequential hints, lockout expiry, all seat sections, source catalog gates, recovery mismatched drops, consumed-document modal, balance-arrow retention, later notification entry and evidence-backed time labels
- The focused fixture acknowledges actual controller-issued Library story sessions between independent app actions; it does not bypass their commit contract. Dialogue timing and global presentation are covered by the separate Library story suite
- Actual cloud-native app captures at `.screenshots/phone-fidelity-completion` were reviewed: room photo is a cropped original image rather than a miniature screenshot, dark authentication panels and nested seat/recovery content are legible. Review exposed and fixed float-formatted initial counters and an inherited gray catalog input. The later document, catalog/Lake catalog, notification variants, source-shaped campus card and 390px mobile captures were also inspected. A gradient-texture intrinsic-size overflow was found during the next pass, fixed by assigning ignore-size before dimensions and adding card clipping, and guarded by a new geometry assertion. The 20:04 card recapture confirmed the gradient is bounded by its original frame. The check-in recapture confirmed the source bottom keyboard, source-sized slots and ready frame; a rapid-input multi-pulse discrepancy was fixed to keep only the latest source entry pulse. Shared Main document-shell integration passed seven assertions, including full 424×854 coverage and chrome blocking

- `test_phone_navigation.gd`: 196 actual-input and source-contract checks, 0 failures
- `test_phone_utilities.gd`: 40 Settings/CC98 regressions, 0 failures
- `test_phone_pages.gd`: 30 layouts, 0 failures
- `test_phone_effects.gd`: 4 native timelines, 0 failures
- `test_phone_chrome.gd`: 59 checks, 0 failures
- Headless Godot run command requires writable sandbox data/cache directories:
  `XDG_DATA_HOME=/tmp/godot_phone_fidelity/data XDG_CACHE_HOME=/tmp/godot_phone_fidelity/cache godot --headless --path godot_native --script res://tests/test_phone_navigation.gd`
- Reviewed actual desktop Weather and Zjuding captures confirmed legible source content and working exits. The subsequent ordinary lake app batch also has623 input checks and33 rendered views. Control Center / Tiyi / WeChat lifecycle and running-source visual differences remain in `REMAINING_PRESENTATION.md`; headless checks do not establish pixel equivalence
