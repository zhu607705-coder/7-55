# Publication verification · 2026-10-17

## Scope

This is a standalone **functional prototype**, submitted for Draft PR review against `godot-version` at `2c8cc05ed9297a4040c2e0916351bd9d57ee3a15`. It does not change the formal game entry point, story triggers, progression authority, save format, or existing lake scenes.

Only `examples/qizhen_large_world/**` and `.github/workflows/qizhen-large-world-example.yml` are added. The earlier playable-chase example/PR is not part of this change. No production integration or merge is implied.

The reviewed source archive was restored and all 53 SHA-256 manifest entries verified before packaging. The 24 original files under assets/scripts/scenes, `project.godot`, and the input-only route driver remain byte-identical. Packaging updates only make test/capture outputs use Godot `user://`, add file-open failure handling, and clarify documentation/provenance. Generated import files, caches, video, screenshots, raw logs and input traces are excluded.

## Fresh local checks

Engine: Godot `4.6.3.stable.official.7d41c59c4`, Linux headless. A new import cache was generated for the nested standalone project. All commands exited 0, with no `ERROR:`, `SCRIPT ERROR:` or parse-error lines.

| Check | Result |
| --- | --- |
| Clean editor resource import | PASS |
| `tests/test_large_world.gd` | PASS · 20 assertions |
| `tests/audit_large_world.gd` | PASS · 41 assertions |
| `tests/test_route_30hz.gd` | PASS · input-only full route |
| Runtime/scene/asset/driver comparison against reviewed archive | Identical |
| 14 inherited asset SHA-256 values | Match |

60 Hz successful route: **110.692 s**, 25,559.99 world pixels, 225 strokes, 2 shore contacts, 0 swan hits, 2 warning/charge cycles. The independent audit measured **106.183 s above 30 px/s** and verified ordinary inputs, physical displacement/turn bounds, ordered objectives, pause/map behavior, restart, interaction eligibility, shore collision and loss/win states. No minimum-duration win gate is present.

Fresh headless 30 Hz route: **109.683 s**, 25,547.80 pixels, 222 strokes, 1 shore contact, 0 swan hits. It is a separate run from the delivered native scene recording (**108.642 s**, 220 strokes). Do not combine their metrics.

The existing repository Web CI is left unchanged. The new workflow imports and runs the three focused suites only when this example/workflow changes. It uses read-only repository permissions and the official Godot 4.6.3 Linux archive, verified against release SHA-256 `d0bc2113065e481c9c2c2b2c37daa4e8be3fe9e27f0ab9ab0b6096e9a37907f3`. GitHub check results are authoritative for remote CI; local focused tests are not a claim that all formal-game tests ran locally.

## Evidence and limits

`INDEPENDENT_AUDIT.md`, `INDEPENDENT_AUDIT_RESULTS.json`, `ROUTE_RESULT.json`, `NATIVE_CAPTURE.md`, `NATIVE_CAPTURE_RESULT.json`, and `PERFORMANCE.json` preserve the pre-publication prototype evidence. The source manifest describes the current published files and excludes itself and generated caches.

The delivered video is a continuous 1× **automated ordinary-input replay** of the native Godot scene, not manual play. Fixed-placement stills are presentation checks, not route evidence. Art, building details, vegetation and shoreline materials remain prototype quality. The blue dock's exact placement/shape, east-channel widening and gameplay objectives are adaptations; bridge clearance, public access and real-world navigability are not verified.

Docking currently checks speed, orientation and range; physical dock collision, rope fixing and disembarking animation are not implemented. Shore collision approximates a boat by nine circular samples. Human feel, touch input, broad device performance and final-art quality still need review.

## Rights and sources

The bundled Fusion Pixel font retains its complete SIL Open Font License notice. Other reused assets/scripts retain their existing project provenance and rights; no blanket new open-source license is asserted. Official ZJU photographs and map raster are linked for reference rather than redistributed. The source-derived geometry is not a survey or an open-license claim. See `ASSET_PROVENANCE.json` and `REFERENCE_AND_SCOPE.md`.

## Input/camera update · 2026-10-18

The original publication audit above describes commit `6db72961629c0bb737c714f82558415dbf3ca635`. This incremental update preserves its portable test outputs, asset provenance, model, geometry, scene and complete-route driver. It fixes idempotent pause/stroke state, adds touch input and direct target taps, and updates camera/HUD behavior. The 70 new scene/input checks, original 41-check audit, model checks and 30 Hz route pass locally. The Godot example CI now also runs the 70-check suite.

The separately delivered 38-second, 1280×720/30 FPS native video uses synthetic touch/key events. It is neither manual play nor physical touchscreen validation. Its 70 model strokes and 70 visual strokes are a partial-route recording, not a complete-route win. Layout fixtures and video/cache files are not committed. See `INPUT_CAMERA_VERIFICATION_20261018.md` for scope, evidence and limitations.
