# 7:55 Project Rules

`AGENTS.md` is the canonical repository rule file. Read and follow it in full before changing this project.

The engine decision was explicitly revised on 2026-07-26:

- React and TypeScript own the phone UI, shared shell, `GameState`, controllers, saves, task UI, inventory, audio direction, and presentation overlays.
- Godot 4 Web owns the campus map and every landscape RPG interior, including dorm, library, east canteen, theater, Qizhen Lake, and future exploration scenes.
- Supported wide desktop layouts place the fixed `430 × 860` React phone surface beside one fixed `960 × 540` RPG canvas. Mobile and single-screen layouts switch surfaces without changing either logical viewport.
- Godot reads versioned TypeScript state snapshots and submits intents through scene runtime contracts. It must not own a second save, wallet, inventory, quest graph, or story controller.
- Existing Phaser landscape scenes remain per-scene migration references and compatibility fallbacks until the corresponding Godot Web scene passes the acceptance gates defined in `AGENTS.md`.
- Portrait phone pages and portrait mini-games remain in the React/TypeScript application. Existing Phaser portrait mini-games may remain.

If this file and `AGENTS.md` appear to differ, `AGENTS.md` is authoritative. Update `AGENTS.md` first and keep this compatibility entrypoint concise so repository rules do not diverge again.
