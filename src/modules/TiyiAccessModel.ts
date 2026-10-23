import type { ActOneBootstrapPhase, GameState } from "../core/types";

const UPDATE_PHASES: readonly ActOneBootstrapPhase[] = [
  "movement_required", "reservation_briefing_required", "reservation_required", "movement_ready",
  "identity_required", "phone_link_required", "controls_required", "item_required", "map_required",
  "chapter_two_ready", "complete"
];

/** The first visit keeps its network puzzle. The later movement task needs an updated client. */
export function tiyiUpdateRequired(state: GameState): boolean {
  return UPDATE_PHASES.includes(state.actOne.phase) || state.ui.libraryFinalsPhase !== "idle";
}

export function tiyiUpdateInstalled(state: GameState): boolean {
  return state.actOne.tiyiUpdateStage === "installed" || state.actOne.tiyiUpdateStage === "legacy_ready";
}

/** Read-only access rule shared by entry presentation and progression controllers. */
export function canAccessTiyi(state: GameState): boolean {
  return state.networkMode === "cellular" && (!tiyiUpdateRequired(state) || tiyiUpdateInstalled(state));
}
