# 3F pantry — extension documentation review

The finished pantry apparatus inherits the existing miniature system. This is an ordinary extension, with no authorized shared design-system change. The incumbent `DESIGN.md` and `.impeccable/design.json` remain unchanged; no code, whole-product art bible, or asset was edited by this documenter.

Reviewed 2026-10-30T07:58:32.496457+00:00 against the confirmed pantry brief, current native sources, the two review reports, and representative final captures. No `PRODUCT.md` was supplied. The precise extension packet and incumbent implementation provide the applicable direction; no new visual identity or interview is inferred.

## Preserved authority

| Incumbent file | SHA256, verified against the prior miniature receipt |
| --- | --- |
| `godot_native/campuses/future_learning_center/design/miniatures/DESIGN.md` | `83a1e14d876c3f7e7bc3826f28305430f8752151e080d47b37cf821749360335` |
| `godot_native/campuses/future_learning_center/design/miniatures/.impeccable/design.json` | `c057b79fe0452670b81a5274fed6db71844a5a3795e3e24042555d282084a175` |

Both hashes match `MINIATURES_VERIFICATION_20261030.json`. The sidecar remains schema 2 and keeps its gallery examples as documentation-only previews. Its narrative and the Markdown explicitly cover the original four apparatuses. That historical scope is preserved; the pantry brief and this review record the fifth apparatus's inheritance without silently extending system-wide rules.

## Actual inheritance checked

| Contract | Current source evidence and result |
| --- | --- |
| Projection and framing | `miniature_bench.gd:26–34,65–70` keeps a 1440 × 810 SubViewport, orthographic size 5.4, camera at (0,12,12) looking at the origin, U=0.01 and Q=0.7071067811865476. `physical_bench.gd:212–215` draws to 960 × 540; `standalone.gd:29–31` uniformly scales and centers it. Desktop, touch, and browser captures retain this composition. |
| Materials and light | Teal `#36777b`, orange `#db8248`, graphite `#263f47`, rubber `#202d32`, ivory `#e2e2d5`, metal `#a5b4b1`, and surround `#c7ccc8` match the incumbent. Key rotation (-48,-28,0), energy 0.8, ambient 0.48, roughness 0.52, shared shadows, bevels, and mesh helpers are inherited. |
| Type and exit | Font name tables confirm Noto Sans CJK SC Regular plus Selected UI Coverage Regular; system fallback is disabled. Title remains 24 logical px at (32,39). The sole screen-space action is the square exit at (808,7), size 144 × 40, 20 px, `#344452` / `#e8e0c8`. |
| Notebook | The common 476 × 266 square paper, `#f6edd7` / `#202b35`, 23 px reading text, 27 px baseline step, 20 px caption, movable placement, and page-fold gesture remain. The closed book is at (884,105). Three clue pages are voluntary and non-authoritative. |
| Manipulation and recovery | Cups, bail handle, and earned support tab are native objects. Their hit anchors derive from `local_point()` and the shared screen projection. The shared shell retains pointer ownership, off-playfield cancellation, focus recovery, part-return easing, and exit cancellation. The pantry model owns lift, delivery, configuration revision, and completion. |
| Feedback and motion | The lower strip remains (16,486,928,46), `#253e46` / `#f5f1e4`, expiring after five seconds. Part return is 0.22 seconds; contact cues are 0.28 seconds. Reduced motion removes optional returns/ripples and immediately settles the tray pose while retaining model state changes. |
| Floor boundary | All three floor manifests match the prior miniature receipt, as do the prior four puzzle models, shared physical shell, projection helper, motion view, and signal view. The room captures retain the pixel furniture scene, with the independent tea-tray prop moving from the communal table to the existing coffee table. |

`miniature_bench.gd` now dispatches the pantry renderer and omits the unrelated generic lever/handwheel for that mode. The existing camera, material definitions, and shared shell values above still match the incumbent contract. This dispatch extension is not a new rendering system.

## Local differences and drift

No pre-existing drift was found in the checked shared contract. The fifth apparatus has three explicit local differences; none is promoted into a shared token or silently repaired:

- Pantry feedback uses **20 logical px**, the existing body scale, at `pantry_tray_view.gd:146`; the common strip uses 21 px. The original feedback token and gallery preview remain unchanged.
- Sofa cushions (`#769692`), clear glass (`#d5e8e3`, alpha 0.20), and tea (`#b7793c` sides / `#b99562` surface) are object-specific materials. The floor and tables use shaded incumbent colors. These values do not redefine the shared palette.
- The tray's physical layout and timing are local: home (430,377), destination (430,213), lift 0.65 seconds, delivery 1.4 seconds, and pose settle `1 - exp(-15 × dt)`. Cups, handle, and support replace the other apparatuses' mechanisms while preserving their interaction principles.

The final source puts the communal tabletop at y = 383 with depth 264; the coffee table stays at y = 213 with depth 178. Their projected ground-plane edges have about **13.73 logical px** of separation. The current screenshots show the distinct surfaces and the served tray fully on its destination. The notebook's page 0 uses current phase and actual tilt direction, with neutral text before a trial or after configuration changes. These observations support the existing F1/F2 resolution; they do not expand the review's scope.

## Evidence and limits

Independently opened **18 pantry captures**: nine desktop images (initial, served, carrying, four record states, room, room_served); five simulated-touch images (initial, served, served record, advanced, clue page 3); and four browser images (initial, served, initial record, served record). Also compared three incumbent mobile captures: solar initial, solar notebook, and signal initial. Exact paths, dimensions, formats, and hashes are in `documentation_review.json`. The native inventory contains 13 states at each size, 1280 × 720 and 844 × 390. The four browser images decode at 903 × 862. Selected pantry captures postdate the five reviewed implementation files.

Read the current input reports and test sources: **29 desktop / 29 simulated-touch checks**, zero failures and zero keyboard events. Read the floor log (**1,740 checks**), design log (**831 checks**, design coverage rather than 25 delivered games), and final preflight (**5 passed / 536 not run**, `fullSuitePassed: false`). Engine evidence identifies `4.7.1.stable.official.a13da4feb`. The build packet reports 39 passing model checks and ordinary browser completion without warnings/errors. This documenter inspected the sources, reports, and static captures; it did not rerun the tests or operate the browser.

The independent finish review requested F1 (intersecting tables/labels) and F2 (fabricated notebook record). Its final verdict is **ship**, limited to both fixes being resolved. This documentation result is **ordinary-extension comparison complete**, not a new whole-surface review or release approval. Formal chapter/save integration, physical-device touch, full browser compatibility, continuous-motion assessment, and novice difficulty measurements remain outside the evidence.
