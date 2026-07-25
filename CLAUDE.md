# 7:55 Claude Rules

`AGENTS.md` is the canonical implementation rule source for this repository. Read it before changing code, assets, maps, story state, build configuration or tests.

Additional required references:

- `docs/PR_AND_TEST_POLICY.md`：PR 规模、风险分级、审查门槛和测试矩阵。
- `docs/VERSION_MANAGEMENT.md`：分支、提交、合并、发布和回退规则。
- `CONTRIBUTING.md`：协作者日常命令。

## Runtime

- The active runtime is React, TypeScript and Phaser.
- Do not restore Godot, a Godot bridge, Three.js gameplay ownership or a second state model without an explicit project decision.
- Phone and RPG surfaces share `src/core` and `src/modules` state and controllers.
- The active campus source is the north-up `4516×3420` top-down plate defined in `AGENTS.md` and the runtime manifest. Retired panorama coordinates cannot be reused.

## Pull Requests

- All changes enter `main` through a pull request.
- PR titles use `<type>(<scope>): <summary>`.
- PR bodies include `改动`, `原因`, `验证`, `风险与回滚`, and `未覆盖`.
- Runtime changes require a non-author approval, resolved review threads, `PR metadata contract`, and `Verify web build`.
- Use Squash merge and preserve `main` history.

## Tests

- Run `npm run typecheck`, `npm test`, and `npm run build` after behavior changes.
- Run `npm run verify:pr` before marking a runtime PR ready.
- Tests under `tests/` are required. Do not remove or weaken a regression test to make a change pass.
- Controller facts own progression. Animation, audio, route changes and local UI state cannot create gameplay completion.
- Browser validation still covers the complete navigation chain, relevant desktop and mobile viewports, and offline single-file behavior.

## Delivery

- Generated `demo/`, `dist/`, `.test-dist/` and temporary QA artifacts stay outside Git.
- Record meaningful implementation and validation updates in `progress.md`.
- Keep secrets, personal information, temporary screenshots and candidate assets out of commits.
