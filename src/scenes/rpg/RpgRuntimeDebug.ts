import { cloneSerializable } from "../../core/ClientCompatibility";
import type { QizhenPhotoRecipe, QizhenPhotoSpotId } from "../../core/types";

export interface QizhenPhotoSessionDebugRequest {
  spotId: QizhenPhotoSpotId;
  recipe: QizhenPhotoRecipe;
  speed: number;
  roll: number;
  kind: "main" | "spot";
  capturedAtSeconds?: number;
}

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
    depth?: number;
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
  interiorDoor?: {
    id: string;
    state: "closed" | "opening" | "open" | "closing";
    progress: number;
    passable: boolean;
    actorOccluded: boolean;
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
    queueGapOpened?: boolean;
    queueColumnThreeYs?: number[];
    defense?: {
      startElapsedMs: number;
      elapsedMs: number;
      remainingMs: number;
      currentExit: "northwest" | "south_gap" | "southeast";
      paused: boolean;
    };
    activeTarget: string | null;
    pickupTargets?: Array<{
      id: string;
      window: string;
      anchor: { x: number; y: number };
      objectBounds: { width: number; height: number };
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
      playerReady: boolean;
      maxDistance: number;
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
    photoCamera?: {
      resolvedSpotId: QizhenPhotoSpotId | null;
      standAreaHit: boolean;
      speed: number;
      roll: number;
      sessionOpen: boolean;
      sessionSpotId: QizhenPhotoSpotId | null;
      lastSessionRequest: QizhenPhotoSessionDebugRequest | null;
    };
    activeOcclusionIds?: string[];
    softenedOcclusionIds?: string[];
  };
  chapterFour?: {
    /** Compatibility summary. Use committed/applied below for authority comparisons. */
    phase: string;
    mode: "light" | "dark";
    committed?: {
      phase: string;
      timeState: string;
      timeAuthority: string;
      worldTimeSeconds: number;
      phoneStatusTimeSeconds: number;
      phoneStatusTimeTrusted: boolean;
      floor: string;
      roomId: string;
      checkpoint: string;
      plateSignature: string;
      plateIds: Readonly<Record<"A1" | "A2" | "A3", string>>;
      targetIds: readonly string[];
    };
    activeFloorBounds?: {
      x: number;
      y: number;
      width: number;
      height: number;
    };
    applied?: {
      phase: string;
      timeState: string | null;
      mode: "light" | "dark";
      storyFloor: "A1" | "A2" | "A3";
      displayFloor: 1 | 2 | 3;
      plateSignature: string;
      plateIds: Readonly<Record<"A1" | "A2" | "A3", string>>;
      targetIds: readonly string[];
    };
    warmup?: {
      requiredPhase: "entry" | "transport" | "maintenance" | "closure";
      ready: boolean;
      loadedPhases: readonly ("entry" | "transport" | "maintenance" | "closure")[];
      inFlightPhases: readonly ("entry" | "transport" | "maintenance" | "closure")[];
      failures: ReadonlyArray<{
        phase: "entry" | "transport" | "maintenance" | "closure";
        urls: readonly string[];
        retryNotBeforeMs: number;
      }>;
    };
    realityVisuals?: {
      renderedMode: "light" | "dark";
      darkLayerAlpha: number;
      lightLayerAlpha: number;
      atmosphereDepth: number;
      targetDepth: number;
      activeTargetMarkerIds: readonly string[];
      dormantTargetMarkerIds: readonly string[];
    };
    runtimeEntities?: ReadonlyArray<{
      targetId: string;
      entityId: string;
      displayFloor: 1 | 2 | 3;
      storyFloor: "A1" | "A2" | "A3";
      source: {
        kind: "runtime_entity";
        floor: "A1" | "A2" | "A3";
        entityId: string;
      };
      bounds: { x: number; y: number; width: number; height: number };
      worldBounds: { x: number; y: number; width: number; height: number };
      rendered: boolean;
    }>;
    ordinaryGuard?: {
      active: boolean;
      mode: string | null;
      position: { x: number; y: number } | null;
      heading: { x: number; y: number } | null;
      previousWaypointId: string | null;
      targetWaypointId: string | null;
      pauseRemainingMs: number;
      visibleForMs: number;
      sightLostForMs: number;
      lastVisiblePosition: { x: number; y: number } | null;
      animationId: string | null;
      travelDirection: "down" | "up" | "side";
      flipX: boolean | null;
      entityBounds: { x: number; y: number; width: number; height: number } | null;
    };
    bakeryCrowd?: ReadonlyArray<{
      routeIndex: number;
      position: { x: number; y: number };
      from: { x: number; y: number };
      to: { x: number; y: number };
      flipX: boolean;
      animationId: string | null;
    }>;
    finalChase?: {
      active: boolean;
      phase: string | null;
      floor: "A1" | "A2" | null;
      guardFloor: "A1" | "A2" | null;
      attempt: number;
      targetWaypointId: string | null;
      targetHoldMs: number;
      predictedPlayerPosition: { x: number; y: number } | null;
      pursuitBand: "catch_up" | "tracking" | "close" | null;
      audioBand: "catch_up" | "tracking" | "close" | null;
      closeVoicePlayed: boolean;
      floorVoicePlayed: boolean;
      pursuitSpeed: number | null;
      guardToPlayerRouteDistance: number | null;
      contactHoldMs: number;
      contactGraceRemainingMs: number;
      portalApplied: boolean;
      portalRequested: boolean;
      portalRemainingDistance: number;
      remainingRouteDistance: number | null;
      finishInside: boolean;
      finishRequested: boolean;
      contact: boolean;
      failureRequested: boolean;
      guardBounds: { x: number; y: number; width: number; height: number } | null;
    };
    lightGrid?: {
      mask: number;
      locked: boolean;
      panelSession: {
        open: boolean;
        openRequestId: string | null;
        targetId: string | null;
      };
    };
    room204Runtime?: {
      presentation: "interactive" | "restored" | "hidden";
      completePlacements: boolean;
      mountedPieceCount: number;
      visibleDeskCount: number;
      visibleChairCount: number;
      visibleDiscussionTableCount: number;
      podiumVisible: boolean;
    };
    room202Door?: {
      state: "open" | "closed" | "inactive";
      colliderRequired: boolean;
      colliderActive: boolean;
      sourceBounds: { x: number; y: number; width: number; height: number };
      appliedBounds: { x: number; y: number; width: number; height: number } | null;
    };
    spatialAttestation?: {
      requestId: string;
      attestationId: string;
      targetId: string;
      result: "responded" | "rejected";
      reason: string | null;
    } | null;
    contract?: {
      failures: ReadonlyArray<{
        source: "runtime" | "plate" | "spatial_attestation";
        code: string;
        detail: string | null;
        raw: string;
      }>;
      lastFailure: {
        source: "runtime" | "plate" | "spatial_attestation";
        code: string;
        detail: string | null;
        raw: string;
      } | null;
    };
    developerCheckpoint?: {
      id: string | null;
      source: "panel" | "url" | null;
    };
    elevatorVisualDepths?: ReadonlyArray<{
      floor: 1 | 2 | 3;
      door: number;
      indicator: number;
      lamp: number;
      playerInFront: boolean;
    }>;
    currentFloor?: 1 | 2 | 3;
    currentStoryFloor?: "A1" | "A2" | "A3";
    floorOffsetX?: number;
    projectedPlateIds?: Readonly<Record<"A1" | "A2" | "A3", string>>;
    appliedPlateIds?: Readonly<Record<"A1" | "A2" | "A3", string>>;
    appliedPlateSignature?: string;
    projectedCollisionIds?: readonly string[];
    appliedCollisionIds?: readonly string[];
    projectedOcclusionIds?: readonly string[];
    appliedOcclusionIds?: readonly string[];
    projectedTargetIds?: readonly string[];
    renderedTargetIds?: readonly string[];
    actionableTargetIds?: readonly string[];
    safeCheckpoint?: string;
    contractFailures?: readonly string[];
    frameRegistration?: {
      manifestEntries: number;
      registered: number;
      reused: number;
      skippedEmpty: number;
      registeredKeys: readonly string[];
    };
    lightZones?: ReadonlyArray<{
      id: string;
      label: string;
      on: boolean;
    }>;
    lightGridLocked?: boolean;
    elevator?: {
      phase: string;
      targetFloor: 1 | 2 | 3 | null;
      doorProgress: number;
      panelOpen: boolean;
      nearbyTravelZone: string | null;
    };
    stairAlignment?: {
      echoObserved: boolean;
      rotationQuarterTurns: 0 | 1 | 2 | 3;
      solved: boolean;
    };
    floorElevators?: ReadonlyArray<{
      floor: 1 | 2 | 3;
      id: string;
      visibleBounds: { x: number; y: number; width: number; height: number };
      doorCenter: { x: number; y: number };
      standPosition: { id?: string; x: number; y: number; facing: "up" | "down" };
      arrivalPosition: { id?: string; x: number; y: number; facing: "up" | "down" };
      travelBounds: { x: number; y: number; width: number; height: number };
    }>;
    foregroundOcclusions?: ReadonlyArray<{
      id: string;
      floor: 1 | 2 | 3;
      sourceAnnotationId?: string;
      maskBounds: { x: number; y: number; width: number; height: number };
      baselineY: number;
      renderMode: "foot_behind_baseline";
      depth: number;
      visible: boolean;
    }>;
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
  collisionRects?: ReadonlyArray<
    | {
        id: string;
        sourceAnnotationId?: string;
        x: number;
        y: number;
        width: number;
        height: number;
      }
    | {
        id: string;
        left: number;
        top: number;
        right: number;
        bottom: number;
      }
  >;
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
