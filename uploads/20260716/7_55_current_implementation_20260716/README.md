# 7:55

Chapter one demo and technical framework for `7:55`.

## Stack

- Vite + TypeScript
- React for the fake phone-system UI
- Phaser 3 reserved for later 2D RPG movement and trigger scenes
- Zustand vanilla store for shared `GameState`
- Vitest for core logic and shell tests

## Commands

```bash
npm install
npm run dev
npm test -- --run
npm run typecheck
npm run build
npm run build:single
npm run audio:library-finals -- --force
```

`npm run build:single` builds the React game directly into `demo/index.html` as a standalone
single-file playable demo. The old roadshow slide deck remains in `pitch-755.html`, but it is no
longer embedded into the playable demo.

## Runtime Model

The app has two runtime modes:

- `phone`: React renders the chapter-one phone scenes inside a fixed `430 × 930` logical viewport.
- `rpg`: Phaser renders future 2D movement scenes.

Both modes must use `src/core` and `src/modules` instead of keeping separate
story progress.

## Where To Add Chapter Content

- Add or replace phone scene UI in `src/scenes/phone`.
- Add shared gameplay logic in `src/modules`.
- Add dialogue, scene, item, and QA rows in `src/data`.
- Add future 2D RPG scenes in `src/scenes/rpg`.
- Keep implementation notes in each scene README.
- Edit the default CC98 feed in `src/data/cc98.posts.json`; the in-page editor stores local overrides in the browser.
- Edit CC98 reply-floor placeholders and the `bd` forum-treasure reply in `src/data/library-finals.content.json`.
- Review candidate campus puzzle concepts in `docs/level-design-ideas.md`.
- Edit the library-finals plot, narrator lines, Top Ten post, and search materials in `src/data/library-finals.content.json`.
- Edit event-to-audio timing in `src/data/library-finals.audio.json`; generated durations live in `src/data/library-finals.audio.generated.json`.
- Review the cross-app level flow and scene reuse matrix in `docs/library-finals-level-design.md`.

The library-finals level reuses the existing library, campus-card, ZJU Sports, and CC98 visuals. Its story phases use separate MiniMax music tracks and sound cues. Audio listens to domain events and does not control gameplay progression.

Read `CLAUDE.md` and `docs/framework-spec.md` before adding story levels.
