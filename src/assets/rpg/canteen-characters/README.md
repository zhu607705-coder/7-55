# Canteen chase character assets

## Structure and lifecycle

This folder contains only licensed, self-contained character GLB source files and their provenance. Use descriptive snake_case filenames. Runtime consumers live in `src/scenes/rpg/canteen-chase/`; do not place screenshots, converters, downloaded repositories, or caches here. Keep source models byte-identical; perform pose adaptation in the runtime. Remove an asset only together with its final consumer and provenance record.

## Casual character

- Author: Quaternius, Ultimate Modular Men Pack, CC0-1.0.
- Author page: https://quaternius.com/packs/ultimatemodularcharacters.html
- GitHub source: https://github.com/euuuuuuan/fatal-funnel-public/blob/29a6bdfd01ad175c389cbd0bac80c30f926ff96b/packages/renderer/assets/models/quaternius-men/casual-character.glb
- File-specific licence evidence: https://github.com/euuuuuuan/fatal-funnel-public/blob/29a6bdfd01ad175c389cbd0bac80c30f926ff96b/CREDITS.md
- Local file: `quaternius_casual.glb`
- SHA-256: `fea7e71271203e7073f1a073fa1208de7402df276f87f80e149bf7589b5d46b4`
- Retrieved: 2026-09-05. No code from the source repository is executed or imported.
- Active consumer: `ChaseHumanAsset.ts`, shared by the bicycle rider, native start/finish transitions and roadside pedestrians. The main rider uses a blue shirt material; the original GLB bytes remain unchanged. Riding poses use actual source bones and bind lengths; roadside pedestrians use the bundled Walk animation.
- Contents: 62 joints, 10 skinned mesh parts, 5776 source triangles and 24 embedded animations. No external buffers or textures. The cycling animation is runtime retargeting, not an animation claimed to exist in the original asset.
- Verification: local SHA-256 checked by `verify:canteen-chase-model`; actual side/front pose inspection and a complete Chromium 755m route. Offline build and final cross-engine checks are recorded in the canonical project report.
- Licence: https://creativecommons.org/publicdomain/zero/1.0/
