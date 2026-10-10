# Chapter 3 ordinary-app evidence, map and Weather routes

## Source ownership

The lake investigation stays inside the original ordinary apps. No Home icon is globally redirected to a generic quest screen. The native shared builder delegates only contextual additions to `scripts/ui/c3_lake_app_context.gd`.

- CC98: `src/scenes/phone/P02_CC98/index.tsx:67–85,547–560,580–582,695–711,870–886,1092–1102`
- WeChat: `src/scenes/phone/P14_Wechat/index.tsx:194–195,304–310,503–510,1034–1048`
- Zjuding/Library/map: `src/scenes/phone/P15_Zjuding/index.tsx:705–729,904–921,1085–1168,1422–1509,1670–1685`
- Weather: `src/scenes/phone/P07_Weather/index.tsx:16–95,129–179`
- Domain facts and item use: `src/modules/ChapterThreeQizhenLakeController.ts:180–317,472–566,1457–1493`

All authored content comes from the unchanged copied `chapter3-qizhen-lake.content.json`. Local UI never grants items or advances a phase directly.

## Reachable ordinary app flow

### CC98

The normal feed, network/authentication rules, other quest posts and post navigation remain. Active location search adds the source wet-program search/drop panel. Searching with the owned wet program reveals the witness post without granting evidence. The witness has the original three replies, floors, timestamps and personas. Only its explicit `Cc98BridgeKeyword` save sends `c3_clue:bridge`; the saved button remains disabled on reread.

### Library catalogue

Home → Zjuding → Library → Catalogue uses the existing native Library implementation. Exact query `签到记录夹页` or the wet-program drop reveals the original record; only `LibraryReflectionKeyword` saves it. A persisted reflection remains reviewable after leaving/re-entering, including after the wet program is consumed. An unrelated subsequent query does not erase an already visible anomaly, matching the source component.

### WeChat

All four normal rows and earlier friend history remain. Active lake location search changes only the friend preview and appends the original three messages at260/780/1300ms. The save control appears after the third line. A local visit clock survives same-page rebuilds; destroyed page timers cannot collect evidence or act on a replacement page. Closing the friend subview cancels its timer; leaving the app resets transient state. The saved source opens fully visible with a disabled save button.

### Three-source map

The existing Zjuding campus-map tile opens a contextual `campus_map` subpage. Rows preserve source identity/excerpt, missing/owned/imported status and the0–3 count. Import buttons and the drop region use `c3_map:<source>`; each import consumes its keyword. The third import does not confirm automatically. `QizhenMapConfirm` changes only `location_search` to `lake_unlocked`, retaining the source result/reason on the phone.

The separate `QizhenMapEnter` uses `c3_map_enter` to enter `campus_qizhen_loop` at `campus_qizhen_gate`, without initializing the lake. Its explicit `open_world` presentation intent reveals the compact world. Only the actual physical gate invokes existing `c3_lake_enter`. Reopening the map after a source-eligible world entry uses `c3_map_resume` and preserves the existing scene/checkpoint/position.

### Weather

Home's normal Weather widget preserves its header/hero/details. For the source lake context, only its advice and lower card change. The dryer slot requires rescue complete, adjustment requested, owned dryer and uncleared rain recovery. No selection opens the inventory; a wrong item gives source feedback; correct selected/dropped dryer starts the existing native calibration. Start closes inventory/selection without consuming the dryer. Cancel/retry preserves it. Only validated success consumes it and returns to Weather's completed state, with no automatic travel.

Both start and result recheck the original active-app, dock/on-foot, rescue/request/item guards. `currentScene == weather` is required; runtimeMode may remain RPG in desktop split mode. Numeric result fields must be finite, moves an integer, all bands intentionally controlled and stability/offset bounds valid. The public page registry uses ordinary `weather`, rather than the old generic `c3_weather` alias.

## Idempotency and navigation

The clue collector now preserves source one-time rewards: after a keyword is imported, rereading that source cannot regrant it while another source is outstanding. All six collection orders retain the wet program until the third distinct saved clue. Confirm checks the named source set, not merely an arbitrary list length.

Main's `open_world` and `open_inventory` hooks are presentation-only. They do not create story facts or replace domain receipts. The previously added compact device-page handler remains responsible for revealing explicit controller page intents; ordinary refreshes do not choose a surface.

## Verification

`tests/test_lake_app_routes.gd` covers623 checks at390/430/1280: actual Home/app buttons, reachable physical control bounds, pointer-driven search/save/import/confirm, source WeChat timing, catalogue reread, actual physical campus gate, wrong Weather item, inventory selection, cancel/retry, and keyboard-controlled native Weather completion. No terminal weather positions or success receipt are fabricated. Separate controller checks cover all six source orders, duplicate rewards and source Weather rejection conditions. Saved-clue controls retain readable source disabled colors; their tested text/background contrast is6.42 for CC98,6.02 for WeChat and4.93 for Library.

The independent fresh-state campaign now uses real compact Main/Home app controls and genuine inventory drags for this section, rather than direct clue/map/weather-start intents. It retains the source spatial-fixture disclosure for physical navigation.

Focused existing regressions passed: Chapter3, phone navigation, Library/login, phone effects and chrome. Actual graphical app captures are generated separately from the same live UI sequence. This is not a claim of a complete physical-device/browser pixel-parity test.

The final graphical sequence produced33 real-route captures at390/430/1280 and completed623 checks without errors. Independent review included saved CC98/Library/WeChat controls, owned/confirmed map states, actual campus-gate entry, Weather calibration390/430 and completed Weather. Required text and controls were readable and bounded after source disabled-color and Weather typography corrections; the world/gameplay viewport remained unchanged.

## Compact Weather presentation and checkpoint isolation

The960×540 native calibration preserves its existing physics/proof contract. At compact widths its light caption has a15px physical font floor, buttons14px and touch targets30px; text wraps and all three row controls plus start/return stay within the surface. Desktop row geometry remains unchanged. `test_weather_readability.gd` passes140 checks. Actual390/430 captures are separate evidence, not original Weather overlay pixel equivalence.

`State.merge_defaults` deep-copies incoming Array/Dictionary containers instead of aliasing cached developer snapshots. `test_checkpoint_isolation.gd` passes362 checks including every117 repeated checkpoint, nested collection independence and preservation of formal-save data. Scalar values and normalizer rules are unchanged.
