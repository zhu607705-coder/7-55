# Selected UI: actual rendering review

## Reproducible evidence

- Draft PR 156; no merge or deployment.
- Actual Godot 4.6.3 / Xvfb rendering, not HTML mockups.
- Baseline source: `f963d47cbe31e5d799b405e36d4ad68cd97546fa`.
- Reviewed native-layer candidate: `fda1851d31de8239d3809528d282bb25bfcbb6ef`.
- Actions run: https://github.com/zhu607705-coder/7-55/actions/runs/39582642615
- Candidate artifact `12339475194`: 108 PNGs; ZIP SHA-256 `72eccd283a4808fa722aef800c6352fbea9d2a12d499a3b3b1839a9a86a620fb`.
- Capture logs contain no script/parse/render errors. That is not a substitute for reviewing the images.

## Reviewed results

| Actual views | Result |
|---|---|
| 24 world fixtures: eight registered world IDs at 1440×900, 390×844, 667×375 | Selected HUD/interaction text is contained; short-landscape objective first line is now visible; native-screen glyphs are no longer resampled through world texture. |
| Journal at 390×844 and 1440×900 | No exploration prompt painted through the transparent text; world remains visible; outer exploration chrome is suppressed. |
| Library dialogue at 390/568/1440 | Previous camera/world-crop regression fixed; world is visible behind the selected no-fill text. |
| C3 dialogue at 390/1440 | Previous HUD collision and double-rasterized glyphs fixed. |
| C3 dialogue at 568×320, short/long/paused | **Not accepted at fda1851**: body viewport clips the first line vertically. The host still reserves space for hidden movement controls. Follow-up must retain locked 14 px text and give it real usable height; do not conceal this with smaller type. |

The 18 dialogue fixtures were inspected individually. They use actual source text and real hosts, but isolated review states are not evidence of campaign completion.

## Scope boundaries

The `campus_qizhen_loop` fixture captures its existing authored cinematic, not a normal exploration HUD. Other scene UI not among the selected roles retains its existing identity. Source art, scene geometry, objective wording, inputs, dialogue advance/timing authority and saves are not redesigned by these fixtures.

The latest 梁祝 fan-shadow minigame is absent from the available source. THEATER-1 is reserved configuration only; the existing ticket machine, spotlight and theater-lobby screenshots are not evidence that this missing minigame was adapted. The request for all scenes therefore remains source-limited.

Locked fonts, colors and none/scrim settings are not silently changed to improve screenshot contrast. White text against bright scene artwork remains a user-selected tradeoff, documented rather than replaced with opaque panels.
