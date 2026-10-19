# 7:55 Project Rules

`AGENTS.md` is the canonical repository rule file. Read and follow it in full before changing this project.

The runtime decision was updated on 2026-10-10: preserve the existing React/TypeScript/Phaser Web compatibility baseline while developing the independent Godot 4.6.3 native target under `godot_native/` on `godot-version` and dependent branches. PR #105 is not yet merged; native migration is not declared complete or release-accepted.

The retired `godot/` and `src/integrations/godot/` hybrid integration must not be restored. Native scenes, source-sync tools, exports and native CI are allowed in the current migration scope. Preserve authored story/data and controller-owned progression; use separate Web and native validation evidence.

If this file and `AGENTS.md` appear to differ, `AGENTS.md` is authoritative. Keep this compatibility entrypoint concise so repository rules do not diverge again.
