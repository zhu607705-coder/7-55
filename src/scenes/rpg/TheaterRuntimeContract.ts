import type { GameEvent, GameState, RpgCheckpointId } from "../../core/types";
import type { RpgBridge } from "./RpgBridge";

export const THEATER_RUNTIME_CONTRACT_VERSION = "1.0.0" as const;
export const THEATER_RUNTIME_LOGICAL_VIEWPORT = { width: 960, height: 540 } as const;
export type TheaterRuntimeSpawnZone = "lobby" | "auditorium" | "stage";

export function selectTheaterRuntimeSpawnZone(
  state: Pick<GameState, "theaterHunt">
): TheaterRuntimeSpawnZone {
  if (!state.theaterHunt.admitted || state.theaterHunt.phase === "complete") return "lobby";
  if (["prop_setup", "spotlight_ready", "spotlight_hunt", "reversal"].includes(state.theaterHunt.phase)) {
    return "stage";
  }
  return "auditorium";
}

export type TheaterRuntimeIntentName =
  | "rpg_booted"
  | "rpg_item_use_feedback"
  | "rpg_subtitle"
  | "rpg_theater_admission_requested"
  | "rpg_theater_exit_requested"
  | "rpg_theater_mode_requested"
  | "rpg_theater_poster_tissue_requested"
  | "rpg_theater_program_collect_requested"
  | "rpg_theater_program_order_read_requested"
  | "rpg_theater_program_panel_requested"
  | "rpg_theater_program_order_set_requested"
  | "rpg_theater_program_order_submit_requested"
  | "rpg_theater_prop_inspect_requested"
  | "rpg_theater_prop_ticket_requested"
  | "rpg_theater_reversal_complete_requested"
  | "rpg_theater_spotlight_attempt"
  | "rpg_theater_spotlight_start_requested"
  | "rpg_theater_ticket_code_submitted"
  | "rpg_theater_ticket_combine_requested"
  | "rpg_theater_ticket_kiosk_requested"
  | "rpg_theater_vent_brush_requested"
  | "theater_dark_mode_enabled"
  | "theater_decoy_inspect_requested"
  | "theater_interior_opened"
  | "theater_light_mode_enabled";

/**
 * Stable boundary between the theater presentation runtime and the shared game
 * domain. A replacement renderer consumes this port; it must not own saves,
 * quest transitions, item grants, or theater progression.
 */
export interface TheaterRuntimePort {
  readonly contractVersion: typeof THEATER_RUNTIME_CONTRACT_VERSION;
  readonly logicalViewport: typeof THEATER_RUNTIME_LOGICAL_VIEWPORT;
  getState: () => GameState;
  setRpgLocation: (scene: "theater_interior", checkpoint: RpgCheckpointId) => void;
  emit: (name: TheaterRuntimeIntentName, payload?: Record<string, unknown>) => void;
  subscribe: (listener: (event: GameEvent) => void) => () => void;
}

export function createTheaterRuntimePort(bridge: RpgBridge): TheaterRuntimePort {
  return {
    contractVersion: THEATER_RUNTIME_CONTRACT_VERSION,
    logicalViewport: THEATER_RUNTIME_LOGICAL_VIEWPORT,
    getState: bridge.getState,
    setRpgLocation: (scene, checkpoint) => bridge.setRpgLocation(scene, checkpoint),
    emit: (name, payload) => bridge.emit(name, payload),
    subscribe: bridge.subscribe
  };
}

export function requireTheaterRuntimePort(value: unknown): TheaterRuntimePort {
  const port = value as Partial<TheaterRuntimePort> | null;
  if (
    !port
    || port.contractVersion !== THEATER_RUNTIME_CONTRACT_VERSION
    || port.logicalViewport?.width !== THEATER_RUNTIME_LOGICAL_VIEWPORT.width
    || port.logicalViewport?.height !== THEATER_RUNTIME_LOGICAL_VIEWPORT.height
    || typeof port.getState !== "function"
    || typeof port.setRpgLocation !== "function"
    || typeof port.emit !== "function"
    || typeof port.subscribe !== "function"
  ) {
    throw new Error(`Unsupported theater runtime contract; expected ${THEATER_RUNTIME_CONTRACT_VERSION}.`);
  }
  return port as TheaterRuntimePort;
}
