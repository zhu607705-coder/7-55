# Native UI visual proof — 2026-10-21

## Reproducible capture

`tests/capture_ui_redesign.gd` renders production scenes and controls at **1440×900** and **390×844**. The dedicated `ui-redesign-proof.yml` workflow runs the same harness against the unchanged public Godot base `f963d47` and the candidate commit. It uses Godot 4.6.3, Xvfb and an isolated `/tmp/755-ui-profile` save directory. It neither deploys nor changes a player's save.

Every screenshot is a **DEV fixture**, not proof of completing the campaign. The capture report records source SHA, dimensions and fixture context. Headless `UI_CAPTURE_VALIDATE=1` validates fixture setup but produces no images; it is not visual acceptance. Graphical capture fails on image-save errors, script errors and the 180-second watchdog.

## Findings from actual images

The original root causes were visible in the baseline, not inferred from CSS or a mockup:

- A screen-wide 3px grid was drawn above phone text and artwork.
- Generic short dialogs retained a 700px height and a large blank body.
- World feedback occupied the full scene width regardless of text length.
- Body prose used the same pixel face as display lettering, with a separate 0.8 shrink in the recovery app.

The first broad candidate (`5d92937`, visual run [39557974167](https://github.com/zhu607705-coder/7-55/actions/runs/39557974167)) produced 28 real images without script errors. Review confirmed cleaner Chinese, real item icons, correctly bounded short dialogs and retained world artwork. It also rejected three aspects of that candidate: paper nested inside paper in the journal, the short desktop feedback still spanning roughly 700px, and uniformly emphasized settings actions.

The next candidate therefore introduces distinct investigation-folder and loose-document silhouettes, removes the nested journal card, fits short feedback to its measured text, separates settings actions by emphasis, and adds visible selected-item shape feedback. This is an iteration based on evidence, not a claim that cream rectangles alone constitute a design.

## Current capture coverage

Each surface is captured at both viewport sizes (40 images):

- Entry chooser; phone home; ZJU Ding; library app; phone settings.
- Recovery, network and voice evidence pages.
- Dorm world; expanded world inventory; journal; control center; inventory; short dialog.
- Campus map/world; selected clue comparison; actual item document.
- Real library dialogue; theater terminal error; chapter-four locked device.

The harness uses original item artwork and original story/device controllers. It does not fabricate dialogue, map locations, stamps, clues, completion badges or new input shortcuts. Test-only item grants are labeled fixtures.

## Acceptance boundaries

Geometry, font coverage, selection, focus, save compatibility and input ownership are checked independently of visual review. Bundled `Campus UI Sans` is an OFL-licensed Noto CJK SC subset with a bundled pixel fallback; its manifest records coverage and unsupported arbitrary-input limits. The font import, fontdata and OFL are explicitly kept in the Web boot content.

Desktop and compact screenshots do not establish real-device browser/DPR, safe-area, screen-reader or every authored minigame acceptance. The complete native CI run on the final commit is a separate gate. Source-specific device colors and original world/art geometry are not globally recolored to match stationery.

## Second review and pending verification

Run [39559466267](https://github.com/zhu607705-coder/7-55/actions/runs/39559466267), candidate `2530fc2`, rendered all 40 images for each source without script errors. Its journal remained an intermediate: the equal-width action stack did not yet establish a convincing investigation-book hierarchy. The next iteration adds a live current-scene thumbnail, compact primary resume action, subordinate ruled rows, a current-page title index and binding loops. These changes require the next actual GPU review before visual acceptance.

That review also found unsupported phone symbols and wrapping of the short CC98 display mark, a portrait device using a landscape geometry decision, and duplicate theater feedback. Targeted tests cover the subsequent fixes. The earlier library-dialogue fixture captured before the library host had consumed the final shell layout; its capture ordering is corrected, without altering authored world coordinates. The baseline chapter-four locked-device fixture renders a blank strip and is **not a valid visual before/after comparison**.

The supplementary `capture_phone_symbols.gd` adds 12 actual phone images (home, ZJU Ding, library app, control center, lake map, completed weather device at both sizes). Together the two harnesses now request 52 images per source. The phone lake map is distinct from the world exploration map. Weather completion and music activity are explicit DEV fixtures, not earned progress.
