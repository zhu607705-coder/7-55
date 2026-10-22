# Combined native animation review branch

Base: `godot-version` at `913bd512c19c70e842461e0357091dca3635d389`.

This branch combines the existing, reviewed native changes in one runnable Main. It is a development review candidate, not formal campaign or all-platform acceptance. The official Godot branch is not merged or deployed by this work.

## Provenance and scope

- #107 three-outlet cup/paddle drinks: `93de44908b853da031903cc6082c8693df8a8f59`
- #108 theater stage, lens and paired spotlight rules: `c6838d6e60719d015a0f922da8bc4b2d39d88d32`
- #109 Library stamp contact/return: `0f3fedcae9c4f3ab85380b4e33e291f825ec58e5`
- #110 stacked Library paper UI: `320d7def6d74620b32e47c156e9169dc09d2ca71`; its #109 ancestry is included once
- #113 stair B assets and pivot-safe motion: `457aa430120c8a337a809a9a6535485200157db6`; includes the required #112 model, without a second separate application
- #114 theater admission/acrylic gate: `aca2b2fad3a3f558c1d1f0e5fccc58833ea7c386`
- #104 character direction source port: `943463932fe0af77fc524693b7e71292b3487f8c`, rebased onto the current base with the same-frame route-arrival correction described in `CHARACTER_FACING_PORT.md`

The separate #106 side-chase draft is not part of this integration. Existing production chase/controller behavior is preserved. No Web rewrite, original story replacement, save-schema change, progression bypass, asset regeneration or global timing change is introduced. #108's already-reviewed TypeScript theater model and text-catalog changes remain necessary source-oracle companions.

## Shared-file reconciliation

1. A blocked/rejected Library scanner request retains the exact current visual heading. An accepted scan uses the original back-facing idle immediately and clears the pending global turn, so an old side/front transition cannot replace the clerk-facing pose.
2. The theater inspector preserves #114's accepted scan/nod and narrative clock. Before/after that sequence, actual rendered/pickable idle entries use #104's four original visitor-facing drawings.
3. Floor-route completion retires the walk frame in the same movement tick. This fixes the wall-tap regression through correct stopped pixels, without changing collision, click tolerance or the original assertion.
4. The generated source-asset manifest now includes #114's actual ticket-wing material, with its verified hash. Original source assets are otherwise preserved.

## Additional integrated regression coverage

- `test_character_facing.gd`: 209 checks, including actual inspector entries outside/inside admission, every route-arrival walk phase, collision slide and stopped facing
- `test_library_stamp_facing.gd`: 20 checks, including rejected pending turns, immediate rendered back pixels and post-service movement
- `test_animation_batch_lifecycle.gd`: 35 checks on one Main/World instance, normal/reduced motion, queued mixer cancellation, same-state reload boundary, stale scanner callbacks, stamp-return settling, interrupted admission and stale teleport rejection
- Existing admission (123), gate passage (204) and unchanged queue-floor tap (97) tests pass on the combined candidate

All tests use isolated temporary user profiles. The new load-boundary test installs the normalized state and emits the actual reset signal; it is not a separate file-import implementation or a claim of fresh earned campaign traversal. The complete native aggregate and exact-head CI are separate required checks and are recorded in the PR once finished.

## Local build limitation

Original web release validation passed 32 of 35 stages, including type checking, text/source contracts and production compilation. The memory-heavy offline single-file bundle was killed with exit 137 in the shared cloud host, including a retry after the native diagnostic run was stopped. Its dependent file/browser checks therefore could not complete locally. Exact-head repository CI must validate this distributable. A process kill is not a successful build and is not counted as one.

## Visual acceptance

Existing isolated previews are real Godot renderers, not HTML substitutes: Library review uses Main with seeded prerequisites; the mixer and clean stair previews are automated presentation fixtures; the theater review uses its real game renderer. Any captured evidence must identify that setup. Real graphical inspection, physical phones, Windows/macOS execution and a fresh unassisted campaign remain distinct from headless checks.
