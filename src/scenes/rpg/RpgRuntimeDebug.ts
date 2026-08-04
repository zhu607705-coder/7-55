import { cloneSerializable } from "../../core/ClientCompatibility";

export interface RpgRuntimeDebugState {
  engine?: "phaser" | "godot";
  coordinateSystem:
    | "Phaser world coordinates, origin at top-left, x right, y down"
    | "Godot world coordinates, origin at top-left, x right, y down";
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
  campusLoop?: {
    enabled: boolean;
    wrapping: boolean;
    wrapCount: number;
    leftTriggerX: number;
    rightTriggerX: number;
  };
  qizhenApproach?: {
    active: boolean;
    briefingSeen: boolean;
    stop: { x: number; y: number };
  };
  scene?: "campus_bootstrap" | "campus_qizhen_loop" | "dorm_hub" | "library_interior" | "canteen_interior" | "theater_interior" | "qizhen_lake";
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
    pickupTimeErrorSeen?: boolean;
    pickupDarkClueRead: boolean;
    defenseDrinkUsed?: boolean;
    identifiedExitIds: string[];
    blockHits: number;
    activeTarget: string | null;
    pickupTargets?: Array<{
      id: string;
      window: string;
      anchor: { x: number; y: number };
      stand: { x: number; y: number };
      proximity: number;
      dropBounds?: { left: number; top: number; right: number; bottom: number; width: number; height: number };
      acceptedItem?: string;
      requiredMode?: "light" | "dark";
    }>;
    menuOpen: boolean;
    dialogueLocked: boolean;
    paperBusy: boolean;
    activeOcclusionIds?: string[];
    softenedOcclusionIds?: string[];
  };
  theater?: {
    runtimeContractVersion: string;
    phase: string;
    spawnZone?: "lobby" | "auditorium" | "stage";
    mode: "light" | "dark";
    activeTarget: string | null;
    panel: "code" | "program" | null;
    spotlightChoiceOpen: boolean;
    ticketDropGuide?: {
      targetId: string;
      targetLabel: string;
      visible: boolean;
      playerInPosition: boolean;
      stand: { x: number; y: number };
      dropBounds: { x: number; y: number; width: number; height: number };
    } | null;
	    spotlight?: {
	      stage: "idle" | "preview" | "ready" | "tracking" | "awaiting" | "hit" | "miss" | "reversal";
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
    label?: string;
    x: number;
    y: number;
    width: number;
    height: number;
    dropWidth?: number;
    dropHeight?: number;
    stand?: { x: number; y: number };
    proximity?: number;
    acceptedItem?: string;
    requiredMode?: "light" | "dark";
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
