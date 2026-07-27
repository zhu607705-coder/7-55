import { cloneSerializable } from "../../core/ClientCompatibility";
import type { GameState, ItemId, RpgSceneId, TheaterHuntState } from "../../core/types";
import {
  selectTheaterRuntimeSpawnZone,
  type TheaterRuntimeIntentName,
  type TheaterRuntimeSpawnZone
} from "../../scenes/rpg/TheaterRuntimeContract";

export const GODOT_RPG_PROTOCOL_VERSION = "1.0.0" as const;
export const GODOT_RPG_LOGICAL_VIEWPORT = { width: 960, height: 540 } as const;
export const GODOT_REACT_MESSAGE_SOURCE = "7-55-react" as const;
export const GODOT_RUNTIME_MESSAGE_SOURCE = "7-55-godot" as const;

export type GodotHostCommandName =
  | "rpg_direction_changed"
  | "rpg_interact"
  | "rpg_inventory_drag_started"
  | "rpg_inventory_drag_ended"
  | "rpg_inventory_drop_requested";

export interface GodotTheaterSnapshot {
  sceneId: "theater_interior";
  checkpoint: GameState["rpgCheckpoint"];
  spawnZone: TheaterRuntimeSpawnZone;
  inputBlocked: boolean;
  selectedItem: ItemId | null;
  theater: TheaterHuntState;
  items: Pick<
    GameState["items"],
    | "greaseTissue"
    | "temporaryTheaterTicket"
    | "spotlightRemote"
    | "fluorescentBrush"
    | "decoyPaper"
  >;
}

export interface GodotStateSnapshotMessage {
  source: typeof GODOT_REACT_MESSAGE_SOURCE;
  version: typeof GODOT_RPG_PROTOCOL_VERSION;
  type: "state_snapshot";
  sceneId: RpgSceneId;
  requestId: string;
  revision: number;
  snapshot: GodotTheaterSnapshot;
}

export interface GodotHostCommandMessage {
  source: typeof GODOT_REACT_MESSAGE_SOURCE;
  version: typeof GODOT_RPG_PROTOCOL_VERSION;
  type: "host_command";
  sceneId: RpgSceneId;
  requestId: string;
  command: {
    name: GodotHostCommandName;
    payload: Record<string, unknown>;
  };
}

export interface GodotLifecycleMessage {
  source: typeof GODOT_REACT_MESSAGE_SOURCE;
  version: typeof GODOT_RPG_PROTOCOL_VERSION;
  type: "lifecycle";
  sceneId: RpgSceneId;
  requestId: string;
  paused: boolean;
  inputBlocked: boolean;
}

export interface GodotHostHelloMessage {
  source: typeof GODOT_REACT_MESSAGE_SOURCE;
  version: typeof GODOT_RPG_PROTOCOL_VERSION;
  type: "host_hello";
  sceneId: RpgSceneId;
  requestId: string;
}

export type GodotHostMessage =
  | GodotStateSnapshotMessage
  | GodotHostCommandMessage
  | GodotLifecycleMessage
  | GodotHostHelloMessage;

export type GodotRuntimeMessage =
  | {
      source: typeof GODOT_RUNTIME_MESSAGE_SOURCE;
      version: typeof GODOT_RPG_PROTOCOL_VERSION;
      type: "runtime_ready";
      sceneId: RpgSceneId;
      viewport: { width: number; height: number };
    }
  | {
      source: typeof GODOT_RUNTIME_MESSAGE_SOURCE;
      version: typeof GODOT_RPG_PROTOCOL_VERSION;
      type: "intent";
      sceneId: RpgSceneId;
      requestId: string;
      name: TheaterRuntimeIntentName;
      payload?: Record<string, unknown>;
    }
  | {
      source: typeof GODOT_RUNTIME_MESSAGE_SOURCE;
      version: typeof GODOT_RPG_PROTOCOL_VERSION;
      type: "debug_snapshot";
      sceneId: RpgSceneId;
      revision: number;
      debug: Record<string, unknown>;
    }
  | {
      source: typeof GODOT_RUNTIME_MESSAGE_SOURCE;
      version: typeof GODOT_RPG_PROTOCOL_VERSION;
      type: "runtime_error";
      sceneId: RpgSceneId;
      code: string;
      detail: string;
    };

const GODOT_THEATER_INTENTS = new Set<string>([
  "rpg_booted",
  "rpg_item_use_feedback",
  "rpg_subtitle",
  "rpg_theater_admission_requested",
  "rpg_theater_exit_requested",
  "rpg_theater_mode_requested",
  "rpg_theater_poster_tissue_requested",
  "rpg_theater_program_collect_requested",
  "rpg_theater_program_order_read_requested",
  "rpg_theater_program_panel_requested",
  "rpg_theater_program_order_set_requested",
  "rpg_theater_program_order_submit_requested",
  "rpg_theater_prop_inspect_requested",
  "rpg_theater_prop_ticket_requested",
  "rpg_theater_reversal_complete_requested",
  "rpg_theater_spotlight_attempt",
  "rpg_theater_spotlight_start_requested",
  "rpg_theater_ticket_code_submitted",
  "rpg_theater_ticket_combine_requested",
  "rpg_theater_ticket_kiosk_requested",
  "rpg_theater_vent_brush_requested",
  "theater_dark_mode_enabled",
  "theater_decoy_inspect_requested",
  "theater_interior_opened",
  "theater_light_mode_enabled"
]);

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

function parseMessageCandidate(value: unknown): unknown {
  if (typeof value !== "string") return value;
  try {
    return JSON.parse(value);
  } catch {
    return null;
  }
}

export function inspectGodotRuntimeProtocolVersion(value: unknown): string | null {
  const candidate = parseMessageCandidate(value);
  return isRecord(candidate)
    && candidate.source === GODOT_RUNTIME_MESSAGE_SOURCE
    && typeof candidate.version === "string"
    ? candidate.version
    : null;
}

export function parseGodotRuntimeMessage(value: unknown): GodotRuntimeMessage | null {
  const candidate = parseMessageCandidate(value);
  if (!isRecord(candidate)) return null;
  if (
    candidate.source !== GODOT_RUNTIME_MESSAGE_SOURCE
    || candidate.version !== GODOT_RPG_PROTOCOL_VERSION
    || typeof candidate.type !== "string"
    || typeof candidate.sceneId !== "string"
  ) {
    return null;
  }
  if (candidate.type === "intent") {
    if (
      typeof candidate.requestId !== "string"
      || typeof candidate.name !== "string"
      || !GODOT_THEATER_INTENTS.has(candidate.name)
      || (candidate.payload !== undefined && !isRecord(candidate.payload))
    ) {
      return null;
    }
  } else if (candidate.type === "runtime_ready") {
    if (
      !isRecord(candidate.viewport)
      || candidate.viewport.width !== GODOT_RPG_LOGICAL_VIEWPORT.width
      || candidate.viewport.height !== GODOT_RPG_LOGICAL_VIEWPORT.height
    ) {
      return null;
    }
  } else if (candidate.type === "debug_snapshot") {
    if (!Number.isInteger(candidate.revision) || !isRecord(candidate.debug)) return null;
  } else if (candidate.type === "runtime_error") {
    if (typeof candidate.code !== "string" || typeof candidate.detail !== "string") return null;
  } else {
    return null;
  }
  return candidate as GodotRuntimeMessage;
}

export function selectGodotTheaterSnapshot(
  state: GameState,
  inputBlocked: boolean
): GodotTheaterSnapshot {
  return cloneSerializable({
    sceneId: "theater_interior",
    checkpoint: state.rpgCheckpoint,
    spawnZone: selectTheaterRuntimeSpawnZone(state),
    inputBlocked,
    selectedItem: state.ui.selectedItem,
    theater: state.theaterHunt,
    items: {
      greaseTissue: state.items.greaseTissue,
      temporaryTheaterTicket: state.items.temporaryTheaterTicket,
      spotlightRemote: state.items.spotlightRemote,
      fluorescentBrush: state.items.fluorescentBrush,
      decoyPaper: state.items.decoyPaper
    }
  });
}

export function createGodotRequestId(prefix: string, sequence: number): string {
  return `${prefix}-${Date.now().toString(36)}-${sequence.toString(36)}`;
}
