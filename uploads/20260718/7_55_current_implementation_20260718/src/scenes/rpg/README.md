# RPG Runtime Reserve

This folder is reserved for later 2D RPG-style scenes.

Use Phaser for movement, collision, tile maps, NPC triggers, and chapter
transitions. Do not store story progress inside Phaser scene fields. Call the
`RpgBridge` instead so phone scenes and RPG scenes share the same `GameState`.

Suggested future structure:

- `PlayerController.ts`: movement and animation state.
- `TriggerZone.ts`: overlap callbacks that emit gameplay events.
- `maps/`: Tiled JSON map files and tileset files.
- `Chapter02DormScene.ts`: the first real RPG scene after the phone ending.
