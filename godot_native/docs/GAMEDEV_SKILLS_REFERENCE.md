# Game-development skill reference

User-selected reference,2026-10-22: [gamedev-skills/awesome-gamedev-agent-skills](https://github.com/gamedev-skills/awesome-gamedev-agent-skills).
Reviewed repository HEAD:`38a4c2500eeb5ff9ac084336b8f66108069d2f8d`.
Read the catalog and [router](https://github.com/gamedev-skills/awesome-gamedev-agent-skills/blob/38a4c2500eeb5ff9ac084336b8f66108069d2f8d/router/SKILL.md).
The upstream reference is Apache-2.0. This note links to it; no upstream scripts or assets were copied or executed.

At a new development phase, detect the actual engine and version, select the smallest relevant skill set, then verify in the project. Continue using the loaded skill within the same concern; re-route when the engine or concern changes. Existing game choices and pinned versions stay authoritative.

| Work | Reference skills |
| --- | --- |
| Native code and reusable scenes | `godot-gdscript`, `godot-nodes-scenes` |
| Characters, proportions and coherent art | `create-game-assets`, `godot-animation` |
| Framing, readable scale and following | `camera-systems` |
| Touch and responsive interface | `godot-ui-control`, `game-ui-ux`, `input-systems` |
| Interaction and spatial boundaries | `godot-physics`, `level-design` |
| Puzzles and progressive discovery | `level-design`, `puzzle`, `dialogue-systems` |
| Measured performance | `performance-optimization` |
| Distribution and native regressions | `godot-export`, `godot-gdscript-headless-testing` |

Relevant Godot, camera, level-design, asset and performance skills are already available in this Codex environment. This review did not install or replace the entire toolkit. Load available entries on demand and inspect any missing upstream entry before adopting it. Retained Web examples must be checked against this project's own dependency locks.

For7:55, verify an asset's visible size against neighboring furniture, preserve its calibrated foot contact, use uniform scale and nearest filtering, and inspect desktop/portrait/short-screen captures. Keep movement, collisions and controller-owned progress separate from visual size. The2026-10-22 dorm experiment correction follows this process.
