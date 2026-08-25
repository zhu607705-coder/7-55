# 7:55 Project Rules

`AGENTS.md` is the canonical repository rule file. Read and follow it in full before changing this project.

The engine decision was explicitly revised on 2026-08-25:

- React and TypeScript own the phone UI, shared shell, `GameState`, controllers, saves, task UI, inventory, audio direction, and presentation overlays.
- Phaser owns the campus map, landscape RPG interiors, and portrait canvas mini-games. The Chapter 4 misaligned-stair puzzle is the single approved Three.js exception.
- Supported wide desktop layouts place the fixed `430 × 860` React phone surface beside one fixed `960 × 540` RPG canvas. Mobile and single-screen layouts switch surfaces without changing either logical viewport.
- Phaser scenes read versioned TypeScript state snapshots and submit intents through scene runtime contracts. They must not own a second save, wallet, inventory, quest graph, or story controller.
- The retired Godot source, export, compatibility, and tooling trees were removed after explicit user approval. They must not be restored.
- Portrait phone pages remain in the React/TypeScript application; portrait canvas mini-games use the existing Phaser runtime.

If this file and `AGENTS.md` appear to differ, `AGENTS.md` is authoritative. Update `AGENTS.md` first and keep this compatibility entrypoint concise so repository rules do not diverge again.
