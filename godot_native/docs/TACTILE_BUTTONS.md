# Native tactile buttons

## Scope and ownership

The existing `NativeUi` API remains the entry point. Its legacy palette arguments
are semantic hints, not new app-specific face colors. `NativeUi.tactile_material`
is the single native material factory. `TactileButtons` adopts real `Button`
instances after their authored construction, including late-created controls.
The adapter owns presentation only. It never handles input, emits gameplay
signals, changes focus neighbors, changes disabled/toggle values, or writes saves.

Coverage in the main Godot project:

- Entry, alarm/wake actions, pause/settings, journal, confirmations and notices.
- Phone app actions, recovery controls, library/CC98, native file dialogs.
- Device keypads, theater/canteen controls, minigame start/exit/action buttons.
- Main533ed6b Future Learning Center overview/direction controls use secondary
  material while retaining native-resolved compact navigation targets. Its
  runner uses the main project, so it is covered despite living under samples.
- Navigation, home app icons, tool launchers, check controls and compound list
  rows retain authored hit layouts; ghost is used on light surfaces. File-dialog
  keys use secondary on the existing dark panel to preserve contrast.
- Buttons formerly rendered as light text on dark world artwork become light
  keys; gray ghost text on that same artwork would not be readable.

Explicit non-button exceptions (not omissions):

- `phone_drop_button.gd`, `inventory_item.gd`, `clock_visual_card.gd`: physical
  paper, inventory objects and clock cards, including drag/drop ownership.
- Clock mechanism parts, identity stamp, device evidence paper and Tiyi's
  draggable source digit: explicitly marked `tactile_exempt` at construction.
- Charging dock/phone/cable contacts and WeChat collectible-avatar hit areas:
  retain object interaction and transparent rendering. Full-screen dismissal/
  dialogue-advance surfaces keep their authored scrims; they are not UI keys.
- Theater chest physical part hotspots: exempt; its close control is restyled.
- Scene sprites, object hit regions and native PopupMenu/ItemList rows are not
  replaced with standalone buttons. Existing item-row input and neutral native
  selection/focus conventions remain in place.

Independent projects under `godot_native/samples/` do not load the main project's
Autoload. This change does **not** claim to restyle those standalone projects.
PR176/184 own their pending prototype changes; when integrating them, reuse this
material factory and preserve their pointer-cancel and natural HUD fixes. Do not
copy this adapter into a second divergent kit.

## Material contract

The five variants are `primary`, `secondary`, `tertiary`, `ghost`, `text`.
Metadata can select `tactile_variant`, `tactile_size` (`md`/`lg`),
`tactile_keep_layout` or `tactile_exempt`. No Button API or signal is replaced.
Standard labels are 14/16 px. All rendered lengths use `u = label_size / 14`,
including float-valued radius, border, shadows, arrow and the 1u pressed offset.
The minimum key height is 40u; larger authored touch targets remain larger.
Compound rows retain their custom insets and hit targets instead of being
flattened into 40px rows. Existing focus styles are intentionally retained.
The weather game retains its existing physical-type compensation inside the
scaled 960x540 world viewport: otherwise 16 authored pixels become roughly6px
on a phone. Its material unit follows that compensated label size. This is an
explicit readability/layout exception to the standard md/lg authored sizes.

Face, edge, inset highlights/shading, contact and lift are drawn in one native
`StyleBox`. There is no corner-masking child overlay. Rest and pressed retain the
same inset draw slots. Transform, shadow and color channels settle in
120/140/160ms. The face/content move, while the hit rectangle does not.
The old opening-only 3px translation was removed to avoid double movement.

A custom class must derive from **StyleBox**, not StyleBoxFlat: the latter's C++
`draw()` bypasses the script `_draw` hook. The dedicated regression test explicitly
calls the engine draw entry point and checks that our hook ran. Compatible color
and shadow-bound fields support existing layout/contrast readers; actual geometry
uses float units, not rounded StyleBoxFlat metadata.

## Known rendering differences requiring visual acceptance

- Godot has no native CSS inset/drop blur stack. Native shadows use 12-band
  geometry and three inset falloff bands. This is an approximation, **not** a
  pixel-identical CSS blur. Check corner alignment and the recessed pressed state
  in real GL close-ups before approval.
- The bundled Morning Note assets are fixed Regular400 and Medium500. There is
  no same-family600 or variable weight. Buttons use existing Medium500 rather
  than an unapproved replacement/synthetic font. The Library platform-font
  exception is retained. This does not claim exact600 weight.
- Native font and icon theme constants are integer-valued; the rendered material
  itself keeps fractional lg geometry. Multiline native labels retain native
  layout and do not get a guessed single-line shadow.
- Disabled text stays opaque and readable. In this game, some disabled buttons
  display persistent selected ordinals; reducing their opacity would hide state.
  Input blocking remains entirely native. Gray disabled ink is #62645f on light
  keys and #c3c2be on slate.

## Reproduction and evidence

Use pinned Godot4.7.1, synchronized/imported assets and an isolated profile.

```sh
node godot_native/tools/sync_source.mjs
godot --headless --path godot_native --editor --import --quit
godot --headless --path godot_native --script res://tests/test_tactile_buttons.gd
# UI_CAPTURE_DIR must be an output directory; do not use --headless below.
xvfb-run -a godot --audio-driver Dummy --path godot_native --script res://tests/capture_tactile_buttons.gd
xvfb-run -a godot --audio-driver Dummy --path godot_native --script res://tests/capture_ui_redesign.gd
```

`capture_tactile_buttons.gd` records md/lg close-ups of five variants and five
states. States on this board are forced and labeled, not claimed as input proof.
`capture_ui_redesign.gd` records the actual entry, phone pages and menu at desktop
and mobile viewport sizes. Headless tests cover synthetic native pointer,
keyboard and touch paths, not physical phone verification. Images must be
inspected after hosted rendering; a passing parse/test log is not visual proof.

## Palette refinement after actual game review (2026-10-28)

The user found the initial cool slate/white keys discordant with the retained
paper surfaces. Shared web/native tokens now use charcoal #454441→#302f2c,
warm-neutral white #fffefa→#f3f1eb, and gray #eeede8→#e2e0d9.
Explicit hover pairs are #504f4b→#3b3a36, #fffffc→#faf9f5,
#f5f4ef→#eae8e1. Geometry, timing, layer alpha, typography and backgrounds
are unchanged. The main pause menu keeps Save primary, import/export tertiary,
and auxiliary actions ghost; light paper modal close is compact ghost.

Compact controls keep even zero original content insets; their caption press
shift is bounded by the original bottom inset to avoid negative engine margins.
Native symbol controls retain transparent source text under their drawn icons.
The fallen home-screen nine is a physical pickup and explicitly exempt.
Rain-rescue skip retains the same existing canvas-scale font compensation as
the weather game, not a forced16px authored size inside a scaled viewport.
