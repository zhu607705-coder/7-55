export interface RpgRuntimeDebugState {
  coordinateSystem: "Phaser world coordinates, origin at top-left, x right, y down";
  world: { width: number; height: number };
  player: { x: number; y: number; facing: "down" | "up" | "side" };
  input?: {
    gameEnabled: boolean;
    sceneEnabled: boolean;
    keyboardEnabled: boolean;
    keys: { up: boolean; down: boolean; left: boolean; right: boolean; interact: boolean };
  };
  camera: { scrollX: number; scrollY: number; zoom: number; mode: "follow" | "manual" };
  scene?: "campus_bootstrap" | "dorm_hub" | "library_interior";
  checkpoint?: string;
  entranceDoor?: {
    state: "closed" | "opening" | "open" | "closing";
    accessGranted: boolean;
  };
  entranceRecord?: {
    open: boolean;
    read: boolean;
    entries?: Array<{ time: string; location: string }>;
    calculation?: string;
  };
  shelfReveal?: {
    phase: "idle" | "shaking" | "sliding" | "paper" | "complete";
    offsetPx: number;
    paperVisible: boolean;
  };
  activeTargets?: Array<{
    id: string;
    x: number;
    y: number;
    width: number;
    height: number;
    acceptedItem?: string;
  }>;
  collisionRects?: ReadonlyArray<{
    id: string;
    left: number;
    top: number;
    right: number;
    bottom: number;
  }>;
}

let currentState: RpgRuntimeDebugState | null = null;

export function setRpgRuntimeDebugState(state: RpgRuntimeDebugState): void {
  currentState = state;
}

export function getRpgRuntimeDebugState(): RpgRuntimeDebugState | null {
  return currentState ? structuredClone(currentState) : null;
}

export function clearRpgRuntimeDebugState(): void {
  currentState = null;
}
