import { getClientCompatibilitySnapshot } from "../../core/ClientCompatibility";
import type { RpgSceneId, TheaterHuntState } from "../../core/types";

export type RpgRenderEngine = "phaser" | "godot";
export type RpgEnginePreference = "auto" | RpgRenderEngine;

export interface RpgRuntimeSelection {
  engine: RpgRenderEngine;
  preference: RpgEnginePreference;
  reason:
    | "accepted_godot_scene"
    | "forced_godot_preview"
    | "forced_phaser"
    | "scene_not_migrated"
    | "file_protocol"
    | "missing_web_capability"
    | "migration_preview_only";
}

const GODOT_PREVIEW_SCENES = new Set<RpgSceneId>(["theater_interior"]);
const GODOT_ACCEPTED_SCENES = new Set<RpgSceneId>();
const GODOT_THEATER_PREVIEW_PHASES = new Set<TheaterHuntState["phase"]>([
  "entry_ticket",
  "program_search",
  "prop_setup",
  "spotlight_ready",
  "complete"
]);

export function isGodotTheaterPreviewPhase(phase: TheaterHuntState["phase"]): boolean {
  return GODOT_THEATER_PREVIEW_PHASES.has(phase);
}

export function resolveRpgRuntimeSelection(
  sceneId: RpgSceneId,
  preference: RpgEnginePreference,
  protocol: string,
  capabilities: { webAssembly: boolean; webGl2: boolean }
): RpgRuntimeSelection {
  if (preference === "phaser") {
    return { engine: "phaser", preference, reason: "forced_phaser" };
  }
  if (!GODOT_PREVIEW_SCENES.has(sceneId)) {
    return { engine: "phaser", preference, reason: "scene_not_migrated" };
  }
  if (protocol === "file:") {
    return { engine: "phaser", preference, reason: "file_protocol" };
  }
  if (!capabilities.webAssembly || !capabilities.webGl2) {
    return { engine: "phaser", preference, reason: "missing_web_capability" };
  }
  if (preference === "godot") {
    return { engine: "godot", preference, reason: "forced_godot_preview" };
  }
  if (GODOT_ACCEPTED_SCENES.has(sceneId)) {
    return { engine: "godot", preference, reason: "accepted_godot_scene" };
  }
  return { engine: "phaser", preference, reason: "migration_preview_only" };
}

export function getRpgRuntimeSelection(sceneId: RpgSceneId): RpgRuntimeSelection {
  if (typeof window === "undefined") {
    return {
      engine: "phaser",
      preference: "auto",
      reason: "migration_preview_only"
    };
  }
  const requested = new URLSearchParams(window.location.search).get("rpgEngine");
  const preference: RpgEnginePreference = requested === "godot" || requested === "phaser"
    ? requested
    : "auto";
  const compatibility = getClientCompatibilitySnapshot();
  return resolveRpgRuntimeSelection(
    sceneId,
    preference,
    window.location.protocol,
    compatibility.capabilities
  );
}
