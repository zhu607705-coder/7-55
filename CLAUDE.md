# 7:55 Project Rules

`AGENTS.md` is the canonical repository rule file. Read and follow it in full before changing this project.

The runtime decision was updated on 2026-10-22: PR #105 was externally merged into `main`, which is now the Godot integration target under `godot_native/`. The user-requested editor and matching Web template baseline is Godot 4.7.1. Preserve the retained React/TypeScript/Phaser source as a behavioral reference, not the production browser runtime. Ancestry and native tests do not establish Godot Web release acceptance; keep exact engine/SHA evidence and historical reports distinct. See `godot_native/docs/BRANCH_CONSOLIDATION.md` for the current single-entry consolidation.

The retired `godot/` and `src/integrations/godot/` hybrid integration must not be restored. Native scenes, source-sync tools, exports and native CI are allowed in the current migration scope. Preserve authored story/data and controller-owned progression; use separate Web and native validation evidence.

If this file and `AGENTS.md` appear to differ, `AGENTS.md` is authoritative. Keep this compatibility entrypoint concise so repository rules do not diverge again.
