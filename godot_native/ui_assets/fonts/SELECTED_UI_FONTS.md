# User-selected UI fonts (2026-10-21)

Historical preview mapping. The user's2026-10-23 instruction supersedes these
font-family choices with the project Morning Note Regular/Medium faces. Existing
surface geometry, sizes, colors, leading and shadows remain; the six older font
files stay as source references and are excluded from production presets.
See `docs/MORNING_NOTE_FONT_LIBRARY.md` from the native project root for the
current source grids, coverage and runtime roles.

Only the locked HUD-2 / interaction-1 / dialogue-2 / journal-3 / theater-1
surfaces use `selected_ui_theme.gd`. Existing phone/application identities and
`native_typography.gd` remain unchanged.

## Exact preview mapping

| Preview ID | Primary file | True weight | License |
|---|---|---|---|
| legacy | CampusUISans-Regular.otf | 400 | OFL.txt |
| sans | SelectedSans-Regular.otf | 400 | SELECTED_NOTO_LICENSE.txt |
| sans | SelectedSans-Bold.otf | 700 | SELECTED_NOTO_LICENSE.txt |
| boutique | SelectedBoutique-Regular.ttf | 400 | SELECTED_BOUTIQUE_OFL.txt |

Primary files are byte-identical copies of the user's playground assets
`font.otf`, `lab-sans-regular.otf`, `lab-sans-bold.otf`, and `boutique.ttf`.
The manifest records their hashes. No synthetic emboldening is used. In
particular, the sans heading is a real 700 font, not a 400 face with an outline.

The playground's sans subsets contain only 725 codepoints. Every primary sans
glyph's decomposed outline was compared with the original SC face 2 of the
recorded Noto CJK TTCs: all match, in both weights. Bundled coverage companions
extend missing characters using that same source and true weight. They cover
the union of the previously shipped game font, preview sans subsets and
current native-script/data Chinese text (2419 codepoints at this revision). Boutique and legacy use the regular companion for absent glyphs.
Fusion Pixel is a final bundled symbol fallback, with its original license at
`assets/rpg/fonts/licenses/FUSION_PIXEL_FONT_OFL.txt`. All system fallback is
disabled; arbitrary future user text is not guaranteed and must be checked.

Rebuild or verify companions, without network access:

```sh
python godot_native/tools/build_selected_ui_coverage.py --source-dir /path/to/noto
python godot_native/tools/build_selected_ui_coverage.py --source-dir /path/to/noto --check
```

Requires fonttools 4.61.1 and exact original TTC hashes in the build script.
Derived companion family and CFF names are renamed `Selected UI Coverage`.
Original copyright/license metadata remains. The original source is Noto Sans
CJK SC 2.004, https://github.com/notofonts/noto-cjk.

## Rendering boundary

Exact role sizes, weights, colors, tracking zero, leading and glyph-outline
zero come from the locked selection, not the earlier generic 16px recommendation.
Godot Label line spacing is integer-valued: baseline separation differs by at
most half a logical pixel from requested `font size × leading`. The same Font
instance is used for measurement and drawing.

CSS's two blurred text-shadow layers do not have a direct Label equivalent.
Godot uses a black downward 1px shadow with shadow-outline spread 3; glyph
`outline_size` remains zero. This is a renderer approximation, not a claim of
pixel-identical CSS shadows. The `.9` opacity is **background alpha only**;
transparent/no-background selections retain text alpha 1. Button faces are
transparent in normal, hover, pressed, hover-pressed and disabled states;
keyboard focus keeps a visible thin outline. Godot Button lacks Label shadow
support; the helper attaches one behind-parent, mouse-ignoring Label with a
transparent foreground to render only the shadow. Reapplication updates that
same child rather than stacking copies; it tracks the existing button text and
alignment without adding any gameplay/input handler.
