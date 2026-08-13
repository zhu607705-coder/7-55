import { cloneSerializable } from "../../core/ClientCompatibility";

export interface RpgRuntimeDebugState {
  engine?: "phaser";
  coordinateSystem: "Phaser world coordinates, origin at top-left, x right, y down";
  world: { width: number; height: number };
  player: {
    x: number;
    y: number;
    facing: "down" | "up" | "side";
    cardinalFacing?: "up" | "down" | "left" | "right";
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
  scene?: "campus_bootstrap" | "campus_qizhen_loop" | "dorm_hub" | "library_interior" | "canteen_interior" | "theater_interior" | "qizhen_lake" | "duan_yongping_temporal_maze";
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
    frameIndex: number;
    frameCount: number;
    offsetPx: number;
    paperVisible: boolean;
  };
  frontDeskStaff?: {
    frameIndex: number;
    animationKey: string | null;
    visible: boolean;
    x: number;
    y: number;
    depth: number;
  };
  frontDeskStampService?: {
    stage: "missing_report" | "ready" | "scanning" | "stamped";
    motion: "idle" | "receiving" | "checking" | "stamping" | "returning" | "complete";
    reportVisible: boolean;
    stampHeadY: number;
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
      objectBounds?: { width: number; height: number };
      stand?: { x: number; y: number };
      proximity: number;
      dropBounds?: { left: number; top: number; right: number; bottom: number; width: number; height: number };
      acceptedItem?: string;
      requiredMode?: "light" | "dark";
      requiredFacing?: string | readonly string[];
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
      playerReady?: boolean;
      playerInPosition?: boolean;
      stand?: { x: number; y: number };
      maxDistance?: number;
      requiredFacing?: string | readonly string[];
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
  chapterFour?: {
    phase: string;
    mode: "light" | "dark";
    cycle: 1 | 2;
    airflowObserved: boolean;
    paperGuidedToElevator: boolean;
    mapPreviewOnly?: boolean;
    mapAssetId?: string;
    mapAssetIds?: readonly string[];
    stitchedWorld?: boolean;
    currentFloor?: 1 | 2 | 3;
    floorOffsetX?: number;
    elevatorPanelOpen?: boolean;
    nearbyTravelZone?: string | null;
    nearbyTargetId?: string | null;
    nearbyPartitionId?: string | null;
    a1NearbyTargetId?: string | null;
    a1PendingAction?: {
      requestId: string;
      action: string;
      targetId: string;
    } | null;
    currentLandmark?: string | null;
    npcFrames?: ReadonlyArray<{
      id: string;
      residualId: string;
      animationId: string;
      frame: number;
      residualFrame: number;
      normalVisible: boolean;
      residualVisible: boolean;
      routeVisible: boolean;
      x: number;
      y: number;
    }>;
    targetBounds?: ReadonlyArray<{
      id: string;
      label: string;
      floor: 1 | 2 | 3;
      kind: "anchor" | "partition";
      bounds: { left: number; top: number; right: number; bottom: number };
      stand: { x: number; y: number };
      proximity: number;
      requiredMode: "light" | "dark";
      requiredFacing: string | readonly string[];
    }>;
    pendingAction?: {
      requestId: string;
      action: string;
      targetId: string;
      partitionId?: string;
      fragmentId?: string;
      order?: readonly string[];
    } | null;
    storyAnchors?: ReadonlyArray<{
      id: string;
      label: string;
      floor: 1 | 2 | 3;
      bounds: { left: number; top: number; right: number; bottom: number };
    }>;
    gameplayTargetsActive?: number;
    routeState?:
      | "baseline"
      | "schedule_observed"
      | "corridor_reconfigured"
      | "wayfinding_aligned"
      | "return_window";
    activeCollisionIds?: readonly string[];
    activeTargetIds?: readonly string[];
    visibleNpcIds?: readonly string[];
    residualNpcIds?: readonly string[];
    activeDoorIds?: readonly string[];
    activePartitionIds?: readonly string[];
    safeRouteRects?: ReadonlyArray<{
      id: string;
      floor: 1 | 2 | 3;
      left: number;
      top: number;
      right: number;
      bottom: number;
    }>;
    transportCore?: {
      coordinateSpace: "floor-local";
      elevator: {
        id: string;
        centerX: number;
        storyFloors: readonly ("A1" | "A2" | "A3")[];
      };
      stair: {
        id: string;
        left: number;
        top: number;
        right: number;
        bottom: number;
        storyFloors: readonly ("A1" | "A2" | "A3")[];
      };
    };
    currentStoryFloor?: "A1" | "A2" | "A3";
    currentSafeCheckpoint?: string;
    elevatorHistoryObserved?: boolean;
    elevatorTrackAligned?: boolean;
    elevatorReplayAttempts?: number;
    elevatorPlayerBoarded?: boolean;
    elevatorRuntimePhase?: string;
    elevatorDoorProgress?: number;
    elevatorTargetFloor?: 1 | 2 | 3 | null;
    elevatorDisplayFloor?: 1 | 2 | 3;
    elevatorWaitRemainingMs?: number;
    historicalElevatorDoorOpen?: boolean;
    historicalElevatorEntryRemainingMs?: number;
    historicalElevatorRideInProgress?: boolean;
    lastAppliedCheckpoint?: string | null;
    stairEchoObserved?: boolean;
    stairRotationQuarterTurns?: 0 | 1 | 2 | 3;
    stairAlignmentSolved?: boolean;
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
    requiredFacing?: string | readonly string[];
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
