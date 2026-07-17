# 7:55 Mobile RPG Framework Design

## Goal

Build an empty but runnable mobile Web game framework for the first chapter of
`7:55`, ready for collaborators to add phone-system puzzle scenes now and simple
2D RPG movement/trigger scenes later.

## Chosen Stack

- Vite + TypeScript for fast local development and a small static build.
- React for the first chapter's fake mobile operating system UI.
- Phaser 3 for later 2D RPG scenes with movement, collision, trigger zones, and
  tile maps.
- Zustand for a single shared `GameState` store.
- Vitest + Testing Library for core state, routing, and lightweight UI tests.

This hybrid stack keeps chapter one efficient to build as UI while reserving a
real game runtime for later RPG-style chapters.

## Architecture

The app has two runtime modes: `phone` and `rpg`. The first chapter starts in
`phone` mode and renders React scene components inside a fixed mobile viewport.
Later chapters can switch to `rpg` mode and mount a Phaser canvas without
rewriting shared game progress.

All gameplay progress flows through the same core layer:

- `GameState` defines scene, runtime mode, network, theme, digits, items, and
  flags.
- `EventBus` records and broadcasts named gameplay events.
- `SceneRouter` changes scenes and emits `enter_scene`.
- `DigitCollector`, `InventoryController`, and `NetworkController` mutate only
  the shared store.
- React phone scenes and Phaser RPG scenes are consumers of the core API, not
  owners of progress state.

## File Boundaries

- `src/core`: shared state, event, routing, persistence contracts.
- `src/modules`: gameplay managers that update `GameState`.
- `src/scenes/phone`: P00-P12 first-chapter scene folders.
- `src/scenes/rpg`: Phaser boot scene and later RPG scene folders.
- `src/components`: shared UI shell and reusable controls.
- `src/data`: editable JSON for dialogue, scenes, items, and QA smoke cases.
- `src/assets`: replaceable UI, icon, animation, audio, and RPG asset folders.
- `docs`: collaborator-facing documentation and checklists.

Phone scene folders follow the PDF contract: `index.tsx`, `view.tsx`,
`logic.ts`, `README.md`, and optional `*.test.tsx`. Scenes do not import other
scene internals.

## Data Flow

User actions call scene logic. Scene logic calls module APIs. Modules update
`GameState` and emit events. React components subscribe to selected state slices.
Phaser scenes receive the same context through a bridge object and dispatch the
same module APIs from collision or trigger callbacks.

The initial scaffold only provides placeholder scenes and a debug-friendly
shell. It does not implement final puzzle content.

## RPG Reserve

The Phaser layer is intentionally thin in the scaffold:

- `RpgGameHost` mounts and destroys a Phaser game instance.
- `BootScene` demonstrates a minimal scene lifecycle.
- `RpgBridge` exposes `getState`, `goToPhoneScene`, `emit`, and future trigger
  helpers.

Later collaborators can add tile maps, player movement, collisions, NPC
triggers, and chapter transitions without changing phone scene APIs.

## Error Handling

Unknown scene IDs route to a safe placeholder screen and emit
`scene_missing`. Invalid digit, item, or network operations throw typed errors
in tests and surface as developer-visible messages during local development.
Persistence failures do not block play; they emit `save_failed`.

## Testing

Core behavior is covered first:

- default `GameState` matches the PDF contract;
- router updates current scene and emits `enter_scene`;
- digit collector returns `0798` only when all digits are collected;
- inventory item add/use rules update flags predictably;
- network controller enforces Tiyi and check-in rules.

UI smoke tests verify the app renders the phone shell, known scene placeholders,
and can switch to the RPG host.

## Collaboration Rules

The PDF remains the content contract. This framework adds executable structure
around it. Any collaborator adding story scenes should update the relevant scene
README, data JSON, and QA checklist in the same change.

No source asset file should use Chinese characters or spaces. The original PDF
can remain at the project root as reference material.
