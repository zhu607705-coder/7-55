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

## Short-landscape follow-up

`e5cc890ca03488ae48ad4adc12b15705c88ab51a` GPU run https://github.com/zhu607705-coder/7-55/actions/runs/39583913318 produced candidate artifact `12339432190` (ZIP SHA-256 `0bb00f3a8d3c2a5377a3d18ba0c6bdf979c6fd264216db967cda145535551d9d`). The actual 568×320 C3 short, long and paused images have been opened and inspected: complete body glyphs are now visible with the locked role font sizes. This closes the preceding half-line rendering defect; it does not imply every full-suite interaction test has passed.

The remaining 15 dialogue captures at e5cc890 were also opened individually: no new body clipping, unexpected wrapping or HUD overlap at 1440/390; Library's restored world framing remains intact. On 390 C3 the dialogue moves down about 56 px within the newly available region, retains the complete source line and does not cover the exit door. No synthetic advance control was added.

## Pointer regression follow-up

Full-suite discovery found a Room204 drag failure when the fixture paused Main processing: the task column's old minimum size could leave a non-overflowing HUD as an oversized pointer blocker until another process tick. The component now settles its own layout and hit filtering from container size signals, without changing furniture input or altering the original test. Room204 drag126/126, food-hall floor tap97/97, and selected layout/pointer1308/1308 pass. The added case performs a single long-to-short update without Main polling and verifies a real pointer reaches the world. The visual styling is unchanged.

## Full-suite corrections after the pointer follow-up

A theater regression independently reproduced a same-idle deferred-layout loop. The fix schedules at most one settlement on the next process frame, applies the final size once, and removes native UI relayout from world drawing. Repeated resize and long/short changes are checked for eventual inactivity; the engine queue limit is not increased.

The transparent task prose must also yield real world pointer drags. Only the visible scrollbar captures drag; wheel events over overflowing task text scroll it without zoom leakage. Raw touch is scoped to a finger starting on the scrollbar, with platform-emulated mouse deduplication and cancellation when hidden. Original furniture and theater drop/reward assertions remain unchanged. Final same-SHA CI and rendering are required independently of these local checks.
