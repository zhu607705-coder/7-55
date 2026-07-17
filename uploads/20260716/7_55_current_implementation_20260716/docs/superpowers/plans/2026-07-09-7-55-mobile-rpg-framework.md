# 7:55 Mobile RPG Framework Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a runnable empty Vite/React/Phaser framework for `7:55` chapter one and future 2D RPG scenes.

**Architecture:** React owns the phone-system scene shell, Phaser owns future 2D RPG scenes, and both share TypeScript core modules over a Zustand `GameState` store. Managers expose stable APIs for routing, events, digits, inventory, network, and future scene triggers.

**Tech Stack:** Vite, TypeScript, React, Phaser 3, Zustand, Vitest, Testing Library.

## Global Constraints

- The first chapter scene IDs are `alarm`, `desktop`, `cc98`, `avatar_puzzle`, `campus_card`, `control_center`, `tiyi`, `weather`, `settings`, `dark_backside`, `treehole`, `checkin`, and `ending`.
- Runtime modes are `phone` and `rpg`.
- `GameState` is the single source of truth for scene, runtime mode, network, theme, digits, items, and flags.
- Phone scenes must not import other phone scene internals.
- P0 content is placeholder-only in this scaffold; collaborators add final剧情关卡 later.
- Assets under `src/assets` use lowercase English, numbers, and underscores only.

---

### Task 1: Project Configuration

**Files:**
- Create: `package.json`
- Create: `index.html`
- Create: `tsconfig.json`
- Create: `tsconfig.node.json`
- Create: `vite.config.ts`
- Create: `vitest.setup.ts`

**Interfaces:**
- Produces: npm scripts `dev`, `build`, `test`, `test:run`, `typecheck`.

- [x] Add Vite, React, Phaser, Zustand, Vitest, and Testing Library configuration.
- [x] Install dependencies.

### Task 2: Core Tests

**Files:**
- Create: `src/core/GameState.test.ts`
- Create: `src/core/SceneRouter.test.ts`
- Create: `src/modules/DigitCollector.test.ts`
- Create: `src/modules/InventoryController.test.ts`
- Create: `src/modules/NetworkController.test.ts`

**Interfaces:**
- Consumes: none.
- Produces: failing tests for core contracts.

- [x] Write tests before implementation.
- [x] Run tests and verify they fail because implementation files are missing.

### Task 3: Core Implementation

**Files:**
- Create: `src/core/types.ts`
- Create: `src/core/GameState.ts`
- Create: `src/core/EventBus.ts`
- Create: `src/core/SceneRouter.ts`
- Create: `src/core/SaveStore.ts`
- Create: `src/modules/DigitCollector.ts`
- Create: `src/modules/InventoryController.ts`
- Create: `src/modules/NetworkController.ts`

**Interfaces:**
- Produces: `createInitialGameState`, `createGameStore`, `EventBus`, `SceneRouter`, `DigitCollector`, `InventoryController`, `NetworkController`.

- [x] Implement minimal core logic to satisfy tests.
- [x] Run tests and verify they pass.

### Task 4: React Phone Shell

**Files:**
- Create: `src/main.tsx`
- Create: `src/App.tsx`
- Create: `src/styles.css`
- Create: `src/components/PhoneShell.tsx`
- Create: `src/components/ScenePlaceholder.tsx`
- Create: `src/scenes/phone/registry.tsx`
- Create: phone scene placeholder folders and README files.

**Interfaces:**
- Consumes: core store and router.
- Produces: visible phone runtime with P00-P12 placeholders.

- [x] Add a mobile-first phone shell and scene registry.
- [x] Keep UI restrained and functional for development handoff.

### Task 5: Phaser RPG Reserve

**Files:**
- Create: `src/scenes/rpg/RpgGameHost.tsx`
- Create: `src/scenes/rpg/BootScene.ts`
- Create: `src/scenes/rpg/RpgBridge.ts`
- Create: `src/scenes/rpg/README.md`

**Interfaces:**
- Consumes: core store, router, event bus.
- Produces: mountable Phaser host for future movement and triggers.

- [x] Add minimal Phaser lifecycle.
- [x] Add bridge documentation for future 2D RPG contributors.

### Task 6: Data and Documentation

**Files:**
- Create: `src/data/dialogue.lines.json`
- Create: `src/data/scenes.config.json`
- Create: `src/data/items.config.json`
- Create: `src/data/qa.smoke.json`
- Create: `docs/framework-spec.md`
- Create: `docs/pipeline.md`
- Create: `docs/qa-checklist.md`
- Create: `README.md`

**Interfaces:**
- Produces: collaborator handoff documentation.

- [x] Add editable data placeholders.
- [x] Add direct instructions for developers adding剧情关卡.
- [x] Run build, typecheck, and tests.
