# 7:55 Project Rules

`AGENTS.md` is the canonical repository rule file. Read it before changing runtime code, story state, maps, assets, builds, or tests.

## Godot migration decision

- The project explicitly reopened the React / Phaser to Godot migration on 2026-07-25.
- The migration uses Godot 4.7.1 and follows `docs/GODOT_MIGRATION_PLAN.md`.
- The current verified product remains available through the Phaser default path while Godot runs behind `?engine=godot`.
- Existing React / Phaser assets and behavior remain the reference until the corresponding Godot slice passes dynamic, visual, and static acceptance checks.
- Do not remove a verified React / Phaser flow in the same PR that first introduces its Godot replacement.
- During phase 0, React `GameState` owns story facts. Godot reads a reduced snapshot and emits runtime snapshots or domain events; it must not write the formal save directly.
- Synchronized Godot assets come only from `godot/assets/asset-manifest.json` and `npm run godot:sync`. Do not hand-edit `godot/assets/generated/`.
- Godot changes require `npm run godot:verify`, `npm run godot:check`, `npm run godot:test`, `npm run godot:export:web`, React type-checking, and Playwright visual smoke.

## Runtime and visual contracts

- Phone scenes keep the canonical `430 × 860` logical frame.
- RPG scenes keep the canonical `960 × 540` logical frame and `16:9` presentation.
- The approved campus source remains `src/assets/rpg/campus/zijingang_campus_plate.png` with runtime coordinates from `src/data/maps/zijingang-campus-runtime.json`.
- Existing story, puzzle, save, audio, item, accessibility, and developer-checkpoint contracts in `AGENTS.md` remain active throughout migration.
