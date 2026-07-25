import type { EventBus } from "./EventBus";
import { selectQuestViewModel } from "./QuestModel";
import type { GameState, GameStore } from "./types";

const REACT_SOURCE = "seven-fifty-five-react";
const GODOT_SOURCE = "seven-fifty-five-godot";

export interface GodotRuntimeSnapshot {
  scene: string;
  checkpoint: string;
  world: { width: number; height: number };
  player: { x: number; y: number; velocityX: number; velocityY: number };
  camera: { zoom: number };
  engine?: Record<string, unknown>;
}

interface GodotEnvelope {
  source: typeof GODOT_SOURCE;
  type: "ready" | "snapshot" | "event";
  payload?: Record<string, unknown>;
}

interface CreateGodotBridgeOptions {
  iframe: HTMLIFrameElement;
  store: GameStore;
  events: EventBus;
  onReady: (engine: Record<string, unknown>) => void;
  onSnapshot: (snapshot: GodotRuntimeSnapshot) => void;
  onError: (message: string) => void;
}

export interface GodotBridgeController {
  sendCommand: (type: string, payload?: Record<string, unknown>) => void;
  destroy: () => void;
}

export function createGodotBridge({
  iframe,
  store,
  events,
  onReady,
  onSnapshot,
  onError
}: CreateGodotBridgeOptions): GodotBridgeController {
  let ready = false;
  let destroyed = false;

  const post = (type: string, payload: Record<string, unknown> = {}) => {
    if (destroyed || !iframe.contentWindow) return;
    iframe.contentWindow.postMessage({ source: REACT_SOURCE, type, payload }, "*");
  };

  const hydrate = () => {
    if (!ready) return;
    post("hydrate", { state: selectGodotState(store.getState()) });
  };

  const onMessage = (event: MessageEvent<unknown>) => {
    if (event.source !== iframe.contentWindow || !isGodotEnvelope(event.data)) return;
    const message = event.data;
    if (message.type === "ready") {
      ready = true;
      const engine = isRecord(message.payload?.engine) ? message.payload.engine : {};
      onReady(engine);
      hydrate();
      return;
    }
    if (message.type === "snapshot" && isGodotSnapshot(message.payload)) {
      onSnapshot(message.payload);
      return;
    }
    if (message.type === "event") {
      const name = typeof message.payload?.name === "string" ? message.payload.name : "";
      const payload = isRecord(message.payload?.payload) ? message.payload.payload : undefined;
      if (name) events.emit(name, payload);
    }
  };

  const onFrameError = () => onError("Godot Web 导出未加载，请先运行 npm run godot:export:web。");
  window.addEventListener("message", onMessage);
  iframe.addEventListener("error", onFrameError);
  const unsubscribe = store.subscribe(hydrate);

  return {
    sendCommand: post,
    destroy: () => {
      destroyed = true;
      ready = false;
      unsubscribe();
      window.removeEventListener("message", onMessage);
      iframe.removeEventListener("error", onFrameError);
    }
  };
}

function selectGodotState(state: GameState): Record<string, unknown> {
  const quest = selectQuestViewModel(state);
  return {
    runtimeMode: state.runtimeMode,
    rpgScene: state.rpgScene,
    rpgCheckpoint: state.rpgCheckpoint,
    currentScene: state.currentScene,
    networkMode: state.networkMode,
    themeMode: state.themeMode,
    quest: {
      id: quest.id,
      title: quest.title,
      objective: quest.objective,
      completed: quest.completed,
      total: quest.total,
      targetSurface: quest.targetSurface,
      recommendedScene: quest.recommendedScene
    },
    canteenHunt: state.canteenHunt
  };
}

function isGodotEnvelope(value: unknown): value is GodotEnvelope {
  if (!isRecord(value) || value.source !== GODOT_SOURCE) return false;
  return value.type === "ready" || value.type === "snapshot" || value.type === "event";
}

function isGodotSnapshot(value: unknown): value is GodotRuntimeSnapshot {
  if (!isRecord(value) || typeof value.scene !== "string" || typeof value.checkpoint !== "string") return false;
  if (!isRecord(value.world) || !isRecord(value.player) || !isRecord(value.camera)) return false;
  return typeof value.world.width === "number"
    && typeof value.world.height === "number"
    && typeof value.player.x === "number"
    && typeof value.player.y === "number"
    && typeof value.camera.zoom === "number";
}

function isRecord(value: unknown): value is Record<string, any> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}
