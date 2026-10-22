# Anchor 28 — tasting-counter layer separation

## Verified problem

The earlier normal-world mixer was placed over `drink_station_cabinet`, whose
transparent PNG contains three drink urns and cup stacks. The same image is a
valid asset for the separate drinks shelf, but not a clean mixing worktop.
`canteen_mixer_performance.gd` also changed its complete root scale from 0.36
up to 0.64 during a result, making the glass, bottle and liquid grow together
in front of the baked objects. The old mixer popup drew a flat outlined cup
and small generic colored bottle rectangles.

## Bounded repair

- Reuse the existing clean tasting-counter background and independent
  source-derived RGBA glass and three ingredient bottle parts
- Preserve uniform part aspect and fixed cup/table contact; uncap, lift,
  tilt and return the active bottle independently
- Draw each accepted liquid layer and pour stream separately; clip liquid
  to the glass interior and keep local feedback out of the backdrop
- Retain the original shuffle, item ownership, original source recipe,
  partial mixture, feedback and controller rewards
- Dispatch accepted ingredients immediately. The third ingredient closes the
  original popup immediately; the existing world view owns the remaining
  result motion. No extra completion gate, camera move or button is added
- Replace only `mixer_counter`'s baked cabinet with a source crop of the clean
  worktop. Its original position, collision footprint, depth and target IDs
  remain. The separate `drink_shelf` asset is unchanged
- Keep bottle captions to the three drink names. Dim missing bottles while
  preserving their original action/missing tooltip and rejection feedback
- Put the already-recorded shelf clue below the title. One fixed bottom strip
  displays either the short operation hint or the current source feedback,
  never both. No extra instruction line overlays the counter lettering

The source session/controller files are byte-unchanged. Six old assertions
that pinned the now-replaced flat button geometry now verify that the actual
independent bottle lies within its own >=44px target. Four consumed-slot checks
verify the dim bottle and original missing tooltip instead of the removed
caption suffix. All original shuffle, consumption, reward, repeat, cancellation
and reentry assertions remain.

## Verification boundaries

The new guarded test exercises real native controls at 1280×720, 960×540,
390×844, 430×860 and 844×390. It checks the four exact PNG hashes, alpha,
interior mask ownership, fixed success/failure transforms, single active
bottle, partial save/reload through real native files and original immediate
third-ingredient completion. This is a seeded chapter fixture and automated
input, not a physical phone or an unseeded campaign.

## Final validation — 2026-10-09

Integrated onto `godot-version` base `b1177e10` before final checks. Import and
editor parse passed with Godot 4.6.3. Fourteen focused native scripts passed,
27,322 checks in total, zero failures:

| Native test | Checks |
| --- | ---: |
| Mixer layer separation and five-size text/layout bounds | 480 |
| Original mixer session/panel | 310 |
| C3 device controls | 2,956 |
| Canteen native objects / layers / lifecycle | 37 / 11 / 9 |
| Pickup continuity / return stack | 18 / 31 |
| Canteen routed device controls | 3,477 |
| Executed-source canteen parity, 23 scenarios / 45 steps | 17,613 |
| Drink handoff, 192 source cases | 1,826 |
| Original self-drink consumer | 442 |
| Chapter 3 / native surface save | 72 / 40 |

Both TypeScript export checks, `export_canteen_mixer_source.mjs --check` and
`export_c3_canteen_devices_source.mjs --source-root . --check`, matched their
executed original-source fixtures. The new layout test also sends all three
source nonterminal feedback strings through the live Main feedback owner and
checks that only one footer label is visible and the text fits.

Actual cloud-desktop input and rendered captures were verified after the final
text cleanup, using an isolated local chapter fixture and the real native
window, Compatibility renderer, and Dummy audio:

- 1280×720: empty assembly, missing repeat feedback, two accepted pours,
  Escape dismissal, Space reopening with both layers preserved, then original
  correct third-pour reward and immediate return to the world
- 390×844: independent bottle/stream motion and accepted feedback, missing
  repeat rejection, three-pour wrong recipe and original bad-drink reward;
  no bottom text overlap or clipped controls
- 430×860: canonical portrait text/art bounds, readable labels and a physical
  click on Exit returning to the world

The desktop/mobile screenshots depict the final reviewed source. The earlier
assembly preview and pre-cleanup captures are not final acceptance evidence.
Independent read-only review found no blocking issue in the final source.
These are focused native tests and cloud Linux input, not a full fresh campaign,
physical Android/iPhone test, Windows run, audio test, or release export. The PR
CI result remains a separate gate.
