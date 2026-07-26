import { cloneSerializable } from "../../core/ClientCompatibility";

export interface RpgRuntimeDebugState {
  coordinateSystem: "Phaser world coordinates, origin at top-left, x right, y down";
  world: { width: number; height: number };
  player: {
    x: number;
    y: number;
    facing: "down" | "up" | "side";
    texture?: string;
    turning?: boolean;
    walkFps?: number;
    angle?: number;
    normalizedDepth?: number;
    perspectiveMultiplier?: number;
    displayScale?: number;
    displayWidth?: number;
    displayHeight?: number;
    collisionWidth?: number;
    collisionHeight?: number;
  };
  input?: {
    gameEnabled: boolean;
    sceneEnabled: boolean;
    keyboardEnabled: boolean;
    keys: { up: boolean; down: boolean; left: boolean; right: boolean; interact: boolean };
  };
  camera: { scrollX: number; scrollY: number; zoom: number; mode: "follow" | "manual" };
  path?: { followingPath: boolean; pathLength: number };
  scene?: "campus_bootstrap" | "dorm_hub" | "library_interior" | "canteen_interior" | "theater_interior" | "qizhen_lake";
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
  backpack?: {
    visible: boolean;
    mapVisible?: boolean;
    overlayVisible?: boolean;
    clearPatchVisible?: boolean;
    x: number;
    y: number;
    scaleX: number;
    scaleY: number;
    angle: number;
    evictionAnimating: boolean;
  };
  shelfReveal?: {
    phase: "idle" | "shaking" | "sliding" | "paper" | "complete";
    offsetPx: number;
    paperVisible: boolean;
  };
  lostFoundStampMachine?: {
    stage: "missing_report" | "ready" | "scanning" | "stamped";
    motion: "idle" | "feeding" | "scanning" | "stamping" | "ejecting" | "complete";
    reportVisible: boolean;
    stampHeadY: number;
    leverAngle: number;
    stampVisible: boolean;
  };
  canteen?: {
    phase: string;
    mode: "light" | "dark";
    identifiedTrayIds: string[];
    returnedTrayIds: string[];
    menuDarkClueRead: boolean;
    pickupDarkClueRead: boolean;
    identifiedExitIds: string[];
    blockHits: number;
    activeTarget: string | null;
    menuOpen: boolean;
    dialogueLocked: boolean;
    paperBusy: boolean;
    activeOcclusionIds?: string[];
    softenedOcclusionIds?: string[];
  };
  theater?: {
    phase: string;
    mode: "light" | "dark";
    activeTarget: string | null;
    panel: "code" | "program" | null;
    spotlightChoiceOpen: boolean;
    spotlight?: {
      stage: "idle" | "preview" | "ready" | "tracking" | "hit" | "miss";
      round: number;
      aimX: number;
      aimLane: "left" | "center" | "right";
      beamActive: boolean;
      actionElapsedMs: number;
      actionRemainingMs: number;
      currentLockMs: number;
      maxContinuousLockMs: number;
      requiredLockMs: number;
      earlyExposureMs: number;
      assistActive: boolean;
      lastFailureReason: string | null;
      target: { x: number; y: number; visible: boolean } | null;
      decoyVisible: boolean;
    };
    activeOcclusionIds?: string[];
    softenedOcclusionIds?: string[];
  };
  qizhenLake?: {
    phase: string;
    mode: "light" | "dark";
    plate: "reflection" | "signs" | "decoy" | "mist";
    activeTarget: string | null;
    reflectionRound: number;
    signRotations: [number, number, number];
    decoyPlacedAt: string | null;
    mistRhythmRead: boolean;
    mistPhase: number;
    activeOcclusionIds?: string[];
    softenedOcclusionIds?: string[];
  };
  activeTargets?: Array<{
    id: string;
    x: number;
    y: number;
    width: number;
    height: number;
    dropWidth?: number;
    dropHeight?: number;
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
  return currentState ? cloneSerializable(currentState) : null;
}

export function clearRpgRuntimeDebugState(): void {
  currentState = null;
}
