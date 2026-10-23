# Phone icon restoration — 2026-10-22

## Authority and scope

The user reported the ZJUWLAN icon looking like a QR/random-pixel replacement,
then instructed that similar small icons use the original Web shapes, colors
and meanings, allowing only necessary size/clarity adaptation. This latest
instruction supersedes the earlier approved uniform ivory launcher style
recorded in `UI_SELECTED_HANDOFF_20261021.md`; it does not reopen the selected
grid, typography, layout, hit targets, inventory, story logic or little-lamp
candidate design. The task handoff conveyed that instruction on 2026-10-22.

Source reference: **`32dfc73c113de980ca42b1c48a893d068e122127`**. Original React
artwork remains in the repository; no replacement art generation was used.

## Source map

| Role | Source | Native restoration |
| --- | --- | --- |
| Wi-Fi | `ControlCenter.tsx` `.cc-wifi-icon`; `shell.css:1638–1665` | Two top-border arcs, square dot, original ink/white bubble; dedicated `WifiMark` |
| WeChat | `P13_PhoneHome/index.tsx`, `p13-phone-home.css` `.wechat-icon/.bubble/.eye` | Green tile, two white bubbles, four green eyes |
| Tiyi | Same, `.runner` | Orange tile, original white head/body/limbs and transforms |
| Zjuding | `src/assets/ui/zjuding.png`, `.b-light/.zjuding-img` | Original PNG bytes on original light tile |
| Settings | `p13-home-widgets.css` `.gear-sprite` | Existing `✱` renderer and original gear color on gray; story gear untouched |
| Photos | `.photo-flower` | Four original colored petals, yellow center, light tile |
| Recovery | `chapter-three-interlude.css` `.recovery-document/.recovery-clock` | Document, folded corner and yellow clock on `#173948` |
| Voice | Same, `.voice-microphone/.voice-icon-wave` | Red microphone and three authored-height waves on `#0a0a0c` |
| CC98 | `.cc98-text`, base blue token | White unbroken `CC98` wordmark on blue, not a generic forum icon |
| Control center | `.control` pseudo-elements | Original overlapping white frames on purple |
| Clock art | `p19-clock.css:707–715` | Yellow/dark dial and original 330° / 237° hands; **does not unlock an unavailable app** |

Native buttons retain 48×48 hit areas, grid/order, tooltips, accessibility names,
focus captions and route callbacks. Seven vector images retain 24×24 slots;
Zjuding uses 24×24 original-image pixels. CC98 retains the readable 42×31 / 16px
wordmark, and settings its 42×42 internal gear slot. This is source-geometry
adaptation, not a claim of pixel-identical screenshots across rendering engines.

## Regression origin and exclusions

The source Wi-Fi was already approximated with `≋` at early native baseline
`ef0024a56011268b263e6bc7955c6c880305385b`. Commit
`74ba4a273609d841c419d01fc80f7f65fa8fb0e5` introduced the deterministic 9×9
symbol matrix that produced the QR-like appearance. PR160/161/162 did not
introduce that change. Reverting to the early native version would therefore
not restore the original Web Wi-Fi.

Do **not** globally replace `≋`: it is the original vibration symbol too.
Other Unicode fallbacks keep their source text and existing font-independent
renderer where no fixed original outline has been established. Removing them
would create missing glyphs in the bundled fonts. This restoration does not
claim those font-dependent outlines or legacy weather drawings are pixel-identical.

All68 original pixel maps (rows and palettes), all 11 original raster item
images, and the Zjuding image are protected by source comparison. They were
already correct and have not been redesigned. No inventory asset is changed.

## Verification and evidence boundaries

- `node godot_native/tests/verify_phone_icon_source.mjs`: independent source
  CSS/asset comparisons, not renderer self-consistency alone.
- Native `test_phone_symbol_icons.gd`, `test_phone_launcher_icons.gd`,
  `test_phone_chrome.gd` and related phone input regressions preserve semantics.
- `test_phone_icon_pack.mjs`: seven active CSS vectors load from a source-less
  PCK; PNG/wordmark/gear retain their normal existing renderer dependencies.
- Existing mobile-touch proof retains its 18 world captures. A separate
  `phone-icon-proof/` directory captures 27 actual game-rendered DEV fixture
  states: desktop 1440×900, portrait 390×844, landscape 844×390; home/interlude,
  Wi-Fi active/cellular/offline, navigation, lake map and weather.
- The constructed DEV snapshots are **not earned progression or physical-device
  proof**. Headless validate-only runs check fixtures, not visual correctness.
  Actual PNGs require the existing CI renderer and subsequent visual review.
