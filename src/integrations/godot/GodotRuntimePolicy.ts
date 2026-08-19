import type { RpgSceneId, TheaterHuntState } from "../../core/types";

/**
 * Archived compatibility surface.
 *
 * The active product selected a browser-only React + Phaser runtime on
 * 2026-08-09. Keeping this small module prevents stale imports in historical
 * tools from re-enabling the former Godot Web branch.
 */
export type RpgRenderEngine = "phaser";
export type RpgEnginePreference = "auto" | "phaser" | "godot";

export interface RpgRuntimeSelection {
  engine: "phaser";
  preference: RpgEnginePreference;
  reason: "web_runtime_only";
}

export const GODOT_ACCEPTED_SCENES: ReadonlySet<RpgSceneId> = new Set();

export function isGodotTheaterPreviewPhase(_phase: TheaterHuntState["phase"]): boolean {
  return false;
}

export function resolveRpgRuntimeSelection(
  _sceneId: RpgSceneId,
  preference: RpgEnginePreference,
  _protocol: string,
  _capabilities: { webAssembly: boolean; webGl2: boolean }
): RpgRuntimeSelection {
  return { engine: "phaser", preference, reason: "web_runtime_only" };
}

export function getRpgRuntimeSelection(_sceneId: RpgSceneId): RpgRuntimeSelection {
  return {
    engine: "phaser",
    preference: "auto",
    reason: "web_runtime_only"
  };
}
