# 3F pantry slow-water extension — documentation comparison

Reviewed 2026-10-30. **Outcome: preserve-incumbent.** This is the final comparison record for an ordinary extension of the existing miniature system. It does not regenerate DESIGN.md, its sidecar, a visual identity, or a new set of normative tokens. No PRODUCT.md was supplied or needed for this bounded comparison.

The authority is the slow-water section of [flc-pantry-brief.md](../../flc-pantry-brief.md), together with the incumbent [DESIGN.md](../../../godot_native/campuses/future_learning_center/design/miniatures/DESIGN.md) and its [sidecar](../../../godot_native/campuses/future_learning_center/design/miniatures/.impeccable/design.json). Both files retain their expected SHA-256:

- DESIGN.md: `83a1e14d876c3f7e7bc3826f28305430f8752151e080d47b37cf821749360335`
- Sidecar: `c057b79fe0452670b81a5274fed6db71844a5a3795e3e24042555d282084a175`

Base HEAD is `4c5fa5f147ce3cdd492895a97f9cca69fd415efd`, branch `codex/flc-transcript-level-design-20261029`. HEAD names the base, not a commit containing the extension. The companion JSON pins the reviewed uncommitted source hashes. Pre-existing work was retained; this pass writes only these two documentation-review files.

## Evidence checked

Read the three pantry implementation files, the shared projection/rendering/shell implementation, both pantry test sources, the extension report, and saved final validation receipts. Opened **29 capture files** with the image viewer: ten native states at each of 1280×720 and simulated-touch 844×390, plus nine browser captures at 903×862. The JSON lists every opened file. These show empty glasses, flowing water, pourback, lowered and balanced trays, delivery, all three support stops, and optional reading. All 34 available native PNGs postdate the final three implementation files.

[browser_handoff.jpg](browser_handoff.jpg) is the empty-cup start and is byte-identical to browser_initial.jpg; it is not delivery evidence. The historical browser_capacity_stop.jpg predates F1–F3 corrections and was excluded from this final comparison. The documenter did not operate the browser, change its viewport, or rerun gameplay suites.

| Saved final evidence | Bounded result |
| --- | --- |
| desktop.log / desktop/pantry_input.json | 39 checks, 0 failures, 0 keyboard events; actual elapsed-time filling. |
| mobile.log / mobile/pantry_input.json | 39 checks, 0 failures, 0 keyboard events; simulated touch. |
| model.log / floor.log / design.log | 52 model assertions; 1740 floor checks; 833 design-coverage checks. Coverage is not acceptance of all 25 rooms. |
| preflight-final.json and metadata | 5 selected checks pass; 536 not run; inputs stable during the run; fullSuitePassed is false. |
| export.log | Matching Godot 4.7.1 import, startup, and standalone Web export pass. |
| browser_verification.json | Ordinary pointer flow, real elapsed water filling, zero keyboard events and model-state writes, no warning/error logs or document overflow. Final displayed A65/B85/C115/D155 ml; order A–D–C–B. |

The [finish review](finish_review.md) supplies the original findings; the [limited fix verdict](fix_verdict.md) closes F1–F3 with disposition ship. The sampled final images agree with the lowered-tray recovery, stream connected to the pouring lip, and separated support caption. This comparison does not reopen or broaden that verdict. Final receipts supersede the earlier review's pre-correction counts and quantities.

## Incumbent comparison

| Area | Observed implementation and comparison |
| --- | --- |
| Camera and light | Same 960×540 playfield, 1440×810 SubViewport, uniform scale and letterboxing. Orthographic camera size 5.4 at (0,12,12), 45° elevation and zero yaw; construction scale 0.01 and depth/height factor 0.7071067811865476. Shared key rotation (−48°,−28°,0°), energy 0.8, ambient energy 0.48, ordinary roughness 0.52. Pantry adds no camera or active auxiliary light. |
| Colors and depth | Reuses teal equipment, orange grips, graphite recesses/table, ivory coasters/rims, metal supports, sage surround, and existing annotation/notebook/navigation colors. Native bevels and shared cast shadows remain the depth mechanism. Source colors are material albedos; lit capture RGB is not a second palette. |
| Type | Inherits SelectedSans-Regular.otf plus SelectedCoverage-Regular.otf, grayscale primary antialiasing, no system fallback. Title 24; notebook 23 with 27 baseline step; exit 20; object names 18; water/support captions and quantity tags 17; flow-rate and secondary captions 16 logical px. No new face, weight, line-height scale, or tracking token. |
| Layout and shapes | Same square exit at (808,7,144,40), title at (32,39), movable optional notebook, and five-second lower feedback strip at (16,486,928,46). The front communal table, rear coffee table, tray, and right-hand water station remain simultaneously legible. Mesh bevel helpers are reused; there is no new card/radius system or raster asset. |
| Interaction and motion | Visible glasses, valve, handle, and support grip submit intents to the session model. Quantity labels follow cups/tray and suppress the dragged cup label. Shared return motion remains 0.22 s cubic-out and contact cues 0.28 s. Reduced motion removes optional ripple/droplet motion and tray settling while retaining water timing and model-gated delivery. |

## Observed extension values

These are source-backed pantry parameters, not additions to the normative system. Some were already pantry-specific before the slow-water change.

- **Materials:** glass wall `#d5e8e3`, alpha 0.20, double-sided, no cast shadow; liquid side `#5b9aaf`; surface and streams `#9bcdd8`. Sofa cushions use `#769692`; the local floor uses `Color("c7ccc8") * .68` and coffee table/shelf use `METAL * .7`. Preserve these source expressions rather than inventing replacement palette tokens.
- **Apparatus:** tray home (430,377), destination (430,213), dock (870,352), basin (870,443), arm spacing 90 logical units. Tray dimensions are (522,10,142). Equal glasses have radius 26 and height 72 logical units, with 32 wall segments and a liquid radius of 23. Two orange/copper arcs mark each requested band; liquid height is derived from measured volume.
- **Direct controls:** valve grip moves 30 logical px between closed/open poses, with a gesture threshold greater than 8 px. Valve, handle, support, and cup hit radii are 29, 34, 28, and 37 px. Dock drop radius is 47; active pourback radius is 42. Pourback uses a −0.65 rad glass pose, with the stream starting at that same transformed lip and a bounded landing within the 115×46 basin. Stream radii are 1.4 for filling and 1.8 for pourback.
- **Water and trial authority:** four empty cups; 4 ml/s inflow; 180 ml capacity; 48 ml/s pourback. Requested centres 60/90/120/150 ml with ±8 ml bands. Arms −2/−1/+1/+2; glass tare 40, tray tare 120; moment tolerance 8. The frame contribution is capped at 0.1 s, so there is no background catch-up. Delivery requires portions, balance, no docked cup, and the current trial revision.
- **Tray presentation:** lift evaluation 0.65 s; delivery 1.4 s; lifted height 48; tilt clamp ±0.18 rad from moment ×0.0012; settling `1 − exp(−15 × dt)`. The transport uses smoothstep position and a sine height arc. The optional supports are −0.25/0/+0.25. Support-caption offset is now (−36,+52), retaining the 17 px type size.

## Recorded differences and limits

The pantry feedback text is **20 logical px**, while the incumbent feedback token and shared draw_tools implementation are **21 px**. This one-pixel local difference is recorded without changing either source or normative token. The tray's settling coefficient 15 is a pantry-specific motion choice; the incumbent coefficient 20 describes panel tilt and has not been replaced. The incumbent document still explicitly describes four closeups; this comparison records the fifth pantry extension without silently widening that document's scope. No further system drift was identified within the sampled camera, light, material-role, type-family, or shape comparison.

This remains an independent playable sample with session-only results, no formal story/save changes, and no new rasters. Saved images establish visible states; actual elapsed-time claims come from the input receipts and browser record, not from still images. The 4–7 minute novice duration remains an estimate; typical target quantities imply about 105 seconds of flow before adjustments. No novice study, physical-phone acceptance, browser-engine matrix, full native suite, campaign integration, or release approval is established by this documenter pass.
