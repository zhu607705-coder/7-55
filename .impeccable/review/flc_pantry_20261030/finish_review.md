# 3F pantry extension — fresh finish review

## 1. Direction / brief fidelity

Reviewed against `.impeccable/flc-pantry-brief.md`, the incumbent miniature `DESIGN.md` and sidecar, the supplied user constraints, Impeccable's craft floor, and the native Godot 3D / Control guidance. This is a precise extension of an established surface, so the confirmed packet substitutes for another design interview. There is no supplied approved comp, QUALITY BAR card, or PRODUCT.md; this review does not invent one.

The extension follows the intended direction. Four equal-size clear cups communicate load through visibly different liquid heights. Cup swaps, the bail handle, and the later support tab are actual scene objects. A failed trial tilts the tray; a successful lift holds it level; delivery visibly relocates it to the rear table. The three clue pages are requested through the notebook. No action-button strip or keyboard instruction has displaced the apparatus.

The room screenshots retain the pixel map and furniture composition. The served room state moves the independent tray prop to the existing coffee table. The closeup inherits the fixed orthographic miniature camera, materials, shared lighting, and reversible gesture system. Native model state owns lift and delivery results. Its session-local scope is represented honestly; this is not formal chapter or save integration.

## 2. Craft-floor check

- **Composition and responsive framing:** all required captures are valid. Desktop, simulated touch, and the user's browser size retain the same landscape composition and uniform scaling. The dark margins in the latter two are intentional letterboxing, not missing content. Cups, handle, notebook, exit, and feedback remain inside the playfield.
- **Object legibility:** water height, coaster spacing, handle placement, and tilt communicate the puzzle without a numeric torque display. Liquid surfaces remain level during the tilted pose. The served state and changed support position are distinguishable at touch scale.
- **Depth and attached labels:** the shared projection is coherent, but the two table tops intersect and produce an ambiguous join; the destination label also touches the sofa. This is the material visual issue F1 below.
- **Type and copy:** the title, feedback, and notebook remain readable in the supplied captures. The optional book can cover part of the apparatus, with the exit still drawn above it. The notebook's record page does not truthfully track trial state; see F2. The awkward final short line on clue page 3 is minor and is not a requested fix.
- **States and motion:** initial, failure, balanced lift, transport, delivered, advanced support, clue, and returned room states are evidenced. Source inspection confirms owned gestures, invalid-drop return, cancellation, focus recovery, reduced-motion handling, and model-driven completion. Still frames cannot independently prove motion timing or continuous liquid behavior.
- **Floor conventions:** the native geometry, notebook paper, shared light, and small navigation control fit this surface. There is no new decorative card scaffold, fake metric, glyph-icon substitute, or unrequested visual identity. The HTML/CSS detector has no verdict on this Godot surface and was correctly omitted.

## 3. Material findings, evidence, and bounded fixes

### F1 — Separate the destination table from the source table

**Evidence:** `desktop/pantry_initial.png`, `desktop/pantry_balanced.png`, `desktop/pantry_served.png`, their mobile counterparts, and `browser_initial.png` / `browser_served.png`. The rear table's front edge merges into the communal table's rear edge, leaving broad triangular wedges along the join. It reads as intersecting slabs rather than two separate furniture surfaces. The “沙发茶几” label ends on the sofa's left arm; the white “提手” cue also straddles the light table / dark table boundary in the resting pose.

The source establishes a physical intersection, not merely a screenshot illusion: `pantry_miniature.gd:13` places the coffee-table top at height 0 with depth 178; line 17 places the communal-table top at the same height with depth 306. With centers at projected y = 213 and 369, their planar extents overlap by approximately 15 logical screen pixels. The destination is a core manipulation target, so this weakens the required start-to-destination reading.

**Fix:** adjust only the closeup table placement or depth to leave a visible gap between non-intersecting table meshes. Preserve enough landing area for the full tray, and keep its destination and carry motion aligned with that surface. Place “沙发茶几” beside the actual destination in clear space; keep the handle cue on a consistent contrasting background. Do not change the pixel floor, furniture footprints, camera projection, puzzle model, or controls to solve this.

**Acceptance:** initial, held, carrying, and served captures at all three supplied sizes show two clean, separate tabletop silhouettes with no coplanar wedges. The served tray rests wholly on its table, and the two affected labels do not cross furniture edges. Ordinary handle delivery still succeeds.

### F2 — Make the notebook's record agree with the actual trial

**Evidence:** `pantry_tray_view.gd:125-127` always renders the page-0 title “上一次试提” and the statement “两边各两杯，仍向水多的一侧偏。” This is returned before any lift and after a balanced trial or completed delivery. The incumbent notebook contract says that the model supplies records, while the clue pages are voluntary guidance. The supplied `pantry_hint.png` captures show page 3 only; they do not disprove the deterministic page-0 contradiction.

**Fix:** make page 0 a truthful record using the model's attempts and last trial outcome, with an explicit no-trial state. If no model record is intended, remove the “last trial” claim and make the page a clearly neutral introduction. Preserve the three requested clue tiers and keep reading entirely non-authoritative.

**Acceptance:** before the first lift, page 0 does not claim a completed trial. After an unbalanced lift it describes that result; after a stable lift or delivery it does not claim that the last tray tilted. Changing cups or support must not silently invent a new completed trial. Add evidence for these page-0 states; no redesign of the notebook is requested.

These two findings are the complete fix list. No additional polish pass is requested.

## 4. Evidence / coverage limitations

Opened and independently checked all 22 supplied PNGs:

| Evidence set | Required states | Result |
| --- | --- | --- |
| `desktop/`, 1280 × 720 | room, initial, tilted, balanced, carrying, served, advanced, hint, room_served | All 9 valid |
| `mobile/`, 844 × 390 | Same 9 states | All 9 valid; simulated touch |
| Browser, 903 × 862 | initial, tilted, served, room_served | All 4 valid |

The five reviewed implementation files predate the corresponding final captures. The checked input reports record 24 / 24 checks for desktop and 24 / 24 for simulated touch, zero failures and zero keyboard events. Their tests cover cup conservation on invalid drops, touch cancellation and pointer ownership, focus interruption during transport, ordinary delivery, advanced support with reduced motion, legal room return, and the four incumbent bench entries. I inspected these tests and reports; I did not rerun them or operate a browser.

The build packet additionally reports 39 passing model checks, ordinary WASM browser completion with empty warning/error output, 1,740 passing floor checks, and 831 passing design-coverage checks. The latter two were supplied during review and are not independent visual findings. `preflight-final.json` and its metadata independently confirm Godot `4.7.1.stable.official.a13da4feb`, five passing selected checks, 536 not run, and `fullSuitePassed: false`.

Physical-device touch, all supported browser engines, separate hover/focus imagery, every notebook page/state, continuous animation quality, production saves, campaign integration, and release acceptance are outside this evidence. Neither the test counts nor this visual review establish them. No new raster assets were introduced.

## 5. Final disposition

fix
