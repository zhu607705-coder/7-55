# Story paper/ink UI — scoped review, 2026-11-01

This is a presentation update on main `2ceae4766d0e95513b4fde1d48741dd6da1fbab3`, not a new engine, gameplay layout or world-art pass. The reference was the actual public [Catch page](https://kevintngo.github.io/statechart-art/catch/) and its public source at `kevintngo/statechart-art` commit `09c959c79e25767cc34a5beddf3df234b085636e`. Cloud Chrome used the page's own poster fallback because WebGL was disabled; the Hold/3D interaction was not visually accepted. No reference artwork, font, logo or code was copied.

## Design contract

Use warm paper `#f6efe2`, dark ink `#1d1a1e`, secondary ink `#4a4038`, fine pen edge `#6f655a` and brick-red focus `#a43b32`. Keep a quiet deterministic grain and short offset shadow. Hover lightens the face without motion; press flattens its shadow; disabled controls remain legible. Transparent navigation/artwork hit regions do not become raised cards. Physical apparatus exemptions win before inherited skin selection.

The existing Morning Note family, type sizes, all control rectangles, insets, focus order, touch ownership, cancellation, navigation, save authority and story clocks stay unchanged. The library geometry reader retains its existing Inter/font fallback, 20px card corners and motion; only its neutral palette joins the paper family. Pixel world art, the printer receipt, digital character field, physical stage mechanisms and source app identity artwork retain their authored appearance.

## Covered demonstration path

| Surface | Change |
|---|---|
| Native entry and late-created Main buttons | Opt-in paper material through existing TactileButtons registry |
| Phone, check-in, Learn and library pages | Paper headers, form frames and ordinary reading/cards; source icons and art retained |
| Control Center | Paper panels; explicit dark selected network face behind existing white nested labels |
| Campus journal, library dialogue, timed chapter dialogue | Light reading surface, dark text, original geometry and scroll/focus behavior |
| Digital-flow game | Narration and pause chrome only; moving symbols and physical board unchanged |
| Liangzhu and fan rehearsal | Paper HUD, caption/feedback/help/folio surfaces; actors, fan, light, curtain and QTE unchanged |
| Godot Web boot | The three existing boot buttons and boot status panel use matching scoped CSS; retained React is untouched |

Shared selected text roles also require matching paper behind the existing Kenney slice tutorial/journal. That compatibility adjustment is same-rectangle, input-transparent and does not add the slice to the video scope. Other campuses and standalone research scenes retain their behavior and apparatus art.

## Acceptance evidence and limits

- Godot 4.7.1: 26 focused suites pass. They cover entry, material scope, existing tactile behavior, dialogue sizing, overlay integration, Learn and phone routes, library login, check-in, brightness, digit flow, Liangzhu QTE, fan rehearsal and ordinary geometry notebook entry/return. Mouse and simulated multi-touch/focus/cancel checks are tests, not physical-phone acceptance.
- Native before/after fixtures at 1280×720, 390×844 and 844×390 preserve visible button/panel rectangles and button font sizes. Separate dialogue fixtures at 1440×900, 390×844 and 568×320 preserve complete glyph rows and scrolling. Screenshots are renderer fixtures, not natural campaign completion.
- Cloud-native manual pointer/keyboard checks include ordinary story start, phone navigation, brightness drag, enabled/disabled check-in, wrong-code feedback, back navigation, network selection, library gate record, notebook entry/animation/return, physical theater fan/curtain, QTE retry, rehearsal menu and return to the theater. Chapter segments use a declared isolated checkpoint; they are not presented as a single earned campaign.
- The initial phone brightness is 33. Its unchanged black veil is `(1 - brightness/100) * .65`, so initial screenshots are deliberately dim. A real Control Center slider can brighten the recording. This update does not change brightness defaults or puzzle facts.
- Web source/material packaging passes 19 checks; exact font/license packaging passes 16. Full same-tree Web export/startup/input remains a draft-CI gate. No old PCK/new-script splice is accepted as a Web test.
- Local evidence is kept outside the repository in `handdrawn-ui-evidence-20261101`: source parity manifest, focused logs, before/after geometry JSON, original native PNGs and manual input receipt. Runtime assets/imports are immutable shared references; no full project cache was duplicated. Renderer audio uses Dummy in this environment.

The scope is the mature Zhejiang demonstration route, not a claim that every chapter and every device panel in the game has been redesigned. BUCT entry functionality is preserved but excluded from the requested recording. No PR201/v4 layout or PR203 CI changes are included.
