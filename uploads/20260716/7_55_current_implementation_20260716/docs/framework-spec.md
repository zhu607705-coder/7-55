# 7:55 Framework Spec

## Technical Decision

Use `Vite + TypeScript + React + Phaser 3 + Zustand + Vitest`.

React is the main runtime for chapter one's fake phone UI. Phaser is included
from day one so later chapters can add simple 2D RPG movement, trigger zones,
tile maps, and character interaction without replacing the app shell.

## Shared State Contract

`src/core/GameState.ts` owns the initial state. `src/core/types.ts` owns the
public state types. All scenes and managers read or write through this contract.

Key fields:

- `runtimeMode`: `phone` or `rpg`
- `currentScene`: P00-P12 scene ID
- `networkMode`: `campus_wifi`, `cellular`, or `offline`
- `themeMode`: `normal`, `dark`, or `backside`
- `digits`: `d1`, `d2`, `d3`, `d4`
- `items`: `waterDrop`, `avatarKey`, `reverseGear`, `lightBeam`
- `flags`: puzzle and ending flags from the PDF spec

## Scene Rules

Phone scenes belong under `src/scenes/phone`. A real scene folder should contain:

- `index.tsx`: scene entry
- `view.tsx`: render-only UI pieces
- `logic.ts`: local scene actions calling modules
- `README.md`: entry condition, state reads, state writes, events, assets, tests

Scenes may import `src/core`, `src/modules`, `src/components`, and `src/data`.
They must not import another scene folder's internal files.

## RPG Rules

Future RPG work belongs under `src/scenes/rpg`.

Phaser scenes should use `RpgBridge` for:

- reading current `GameState`;
- emitting trigger and chapter events;
- returning to phone scenes when needed.

Do not duplicate inventory, flags, dialogue progress, or scene progress inside
Phaser-only state.

## Asset Rules

Use lowercase English, numbers, and underscores for source asset names:

- `icon_cc98_normal.svg`
- `ui_desktop_backside.png`
- `sfx_code_erased.ogg`
- `vo_xiaoying_XY_P02_HIDE_CODE_001.ogg`

Temporary files must end with `_temp`.

## Testing Rules

Core managers need Vitest coverage before content PRs are merged. Scene PRs
should include either a unit test for scene logic or a QA checklist update.

Before merging work that affects P0 flow, run:

```bash
npm test -- --run
npm run typecheck
npm run build
```
