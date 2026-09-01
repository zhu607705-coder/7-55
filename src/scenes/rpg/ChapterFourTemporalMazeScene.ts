import Phaser from "phaser";
import type {
  ChapterFourFactId,
  ChapterFourLightZoneId,
  ChapterFourRoom204GroupId,
  ChapterFourRoom204PieceId,
  ChapterFourRoom204SlotId,
  GameState,
  ItemId,
  RpgCheckpointId
} from "../../core/types";
import { DEVELOPER_ACTIVE_KEY, DEVELOPER_SOURCE_KEY } from "../../core/StorageKeys";
import chapterFourContent from "../../data/chapter4-755.content.json";
import mazeLayout from "../../data/chapter4-three-floor-maze.layout.json";
import {
  CHAPTER_FOUR_ALUMNI_HONOR_WALL,
  getChapterFourAlumniFigureByTargetId,
  type ChapterFourAlumniHonorWallFigure
} from "../../data/ChapterFourAlumniHonorWall";
import {
  CHAPTER_FOUR_CONTEXT_INTERACTION_TARGET_IDS
} from "../../data/ChapterFourInteractionContent";
import {
  selectChapterFourMazeProjection,
  type ChapterFourMazeProjection
} from "../../modules/ChapterFourMazeProjection";
import {
  CHAPTER_FOUR_MAINTENANCE_GUARD_RULES,
  chapterFourGuardFootContact,
  createChapterFourMaintenanceGuardRecoveryState,
  createChapterFourMaintenanceGuardState,
  stepChapterFourMaintenanceGuard,
  type ChapterFourMaintenanceGuardState
} from "../../modules/ChapterFourGuardModel";
import {
  createChapterFourGuardPresentationState,
  stepChapterFourGuardPresentation,
  type ChapterFourGuardPresentationResult,
  type ChapterFourGuardPresentationState
} from "../../modules/ChapterFourGuardPresentationModel";
import {
  CHAPTER_FOUR_FINAL_CHASE_POINTS,
  CHAPTER_FOUR_FINAL_CHASE_RULES,
  chapterFourFinalChaseFootContact,
  createChapterFourFinalChaseState,
  resolveChapterFourFinalChaseFailure,
  resolveChapterFourFinalChaseFinish,
  resolveChapterFourFinalChasePortal,
  stepChapterFourFinalChase,
  type ChapterFourFinalChaseState,
  type ChapterFourFinalChaseStepResult
} from "../../modules/ChapterFourFinalChaseModel";
import {
  CHAPTER_FOUR_ELEVATOR_VISUAL_DEPTH,
  CHAPTER_FOUR_PLAYER_DEPTH_BASE,
  CHAPTER_FOUR_PLAYER_TOP_DEPTH,
  chapterFourPlayerDepth
} from "../../modules/ChapterFourElevatorDepthModel";
import { CHAPTER_FOUR_ELEVATOR } from "../../modules/ChapterFourElevatorModel";
import {
  CHAPTER_FOUR_ELEVATOR_FLOOR_RECORDS,
  chapterFourElevatorCollectedRecordCount,
  chapterFourElevatorRecordForDisplayFloor,
  chapterFourElevatorRecordsComplete,
  type ChapterFourElevatorDeductionFloor,
  type ChapterFourElevatorRecordFloor
} from "../../modules/ChapterFourElevatorFloorInvestigation";
import type { ChapterFour755Intent } from "../../modules/ChapterFourTemporalMazeController";
import {
  clearAllChapterFourVisualHints,
  clearChapterFourVisualHintPuzzle,
  createChapterFourVisualHintModel,
  recordChapterFourVisualHintFailure,
  selectChapterFourVisualHintForDetail,
  selectChapterFourVisualHintPuzzleForIntent,
  selectChapterFourVisualHintSession,
  type ChapterFourVisualHintModel,
  type ChapterFourVisualHintPuzzleId
} from "../../modules/ChapterFourVisualHintModel";
import { chapterFourInsertedPuzzleForTarget } from "../../modules/ChapterFourInsertedPuzzleModel";
import {
  RPG_PIXEL_FONT_FAMILY,
  setRpgLogicalCameraZoom
} from "./RpgRenderResolution";
import type { RpgBridge } from "./RpgBridge";
import {
  createChapterFourContextInteractionIntent,
  resolveChapterFourContextInteractionSubtitle
} from "./ChapterFourContextInteractionFlow";
import {
  CHAPTER_FOUR_755_MANIFEST_FRAME_COUNT,
  CHAPTER_FOUR_755_PLATES,
  CHAPTER_FOUR_755_SPRITESHEETS,
  getChapterFour755ManifestFrame,
  registerChapterFour755ManifestFrames,
  type ChapterFour755FrameRegistrationReport,
  type ChapterFour755PlateId
} from "./FinaleEnvironmentTextures";
import {
  FINALE_NPC_ANIMATIONS,
  ensureFinaleNpcAnimations,
  type FinaleNpcAnimationId
} from "./FinaleNpcTextures";
import {
  CHAPTER_FOUR_BAKERY_STAFF_TEXTURE_KEY,
  CHAPTER_FOUR_ELEVATOR_TEXTURE_KEY,
  CHAPTER_FOUR_FRONT_DESK_TEXTURE_KEY,
  CHAPTER_FOUR_WARMUP_PHASES,
  chapterFourWarmupPhaseForState,
  getChapterFourWarmupAssetsThroughPhase,
  getChapterFourWarmupPhaseAssets,
  getNextChapterFourWarmupPhase,
  queueChapterFourWarmupAsset,
  type ChapterFourWarmupAsset,
  type ChapterFourWarmupPhase
} from "./ChapterFourWarmupAssets";
import { CHAPTER_FOUR_INSERTED_PUZZLE_ASSETS } from "./ChapterFourInsertedPuzzleAssets";
import {
  inspectChapterFourWarmupPhaseReadiness,
  runChapterFourWarmupAssetBatch,
  selectChapterFourWarmupRetryBlocker,
  type ChapterFourWarmupPriority
} from "./ChapterFourWarmupLoadPolicy";
import {
  CHAPTER_FOUR_755_INTERACTION_TARGETS,
  CHAPTER_FOUR_755_SCENE_KEY,
  getChapterFour755RuntimeTargetInstallation,
  isChapterFour755TargetStateActive,
  isChapterFour755SpatialAttestationRequest,
  selectChapterFour755BakeryCommittedRuntimeState,
  selectChapterFour755AcceptedItem,
  selectChapterFour755RequiredMode,
  type ChapterFour755InteractionTargetContract,
  type ChapterFour755RuntimeTargetContext,
  type RpgHalfOpenWorldRect
} from "./RpgInteractionContract";
import {
  ROOM204_GROUPS,
  ROOM204_GROUP_ORDER,
  ROOM204_DISCUSSION_TABLES,
  ROOM204_FURNITURE_SCALE,
  ROOM204_INITIAL_PIECE_LAYOUTS,
  ROOM204_INITIAL_PIECE_POSITIONS,
  ROOM204_PAIR_OFFSETS,
  ROOM204_PIECE_FRAME_BINDINGS,
  ROOM204_PIECE_ORDER,
  ROOM204_PODIUM_DRAWER_RUNTIME_ENTITY_ID,
  ROOM204_PODIUM_LAYOUT,
  ROOM204_PROJECTION_HANDSHAKE,
  ROOM204_RESIDUAL_GROUP_BOUNDS,
  ROOM204_RESIDUAL_GROUP_RUNTIME_ENTITY_ID,
  ROOM204_SLOT_CENTERS,
  ROOM204_SLOT_LAYOUTS,
  ROOM204_SLOT_ORDER,
  findRoom204PlacementForPiece,
  isRoom204PlacementSetComplete,
  normalizeRoom204Placements,
  room204GroupIdFromTargetId,
  room204GroupRuntimeEntityId,
  room204GroupTargetId,
  room204SlotRuntimeEntityId,
  selectRoom204RuntimePresentation
} from "../rpg/ChapterFourRoom204Model";
import {
  configureRpgPlayerSprite,
  ensureRpgPlayerTextures,
  preloadRpgPlayerTextures,
  RPG_PLAYER_SIDE_WALK_FPS,
  RPG_PLAYER_WALK_FPS,
  RpgPlayerAnimator
} from "./RpgPlayerTextures";
import { clearRpgRuntimeDebugState, setRpgRuntimeDebugState } from "./RpgRuntimeDebug";
import { subscribeRpgSceneBridge } from "./RpgSceneBridgeSubscription";

type DisplayFloor = 1 | 2 | 3;
type StoryFloor = "A1" | "A2" | "A3";
type TravelRoute = "elevator" | "stair";
type NpcTravelDirection = "down" | "up" | "side";
const CHAPTER_FOUR_WARMUP_PHASE_LABELS: Readonly<Record<ChapterFourWarmupPhase, string>> = {
  entry: "A1 入口",
  transport: "电梯与楼层",
  maintenance: "维修与追逐",
  closure: "收束场景"
};
type ElevatorPhase =
  | "idle"
  | "opening"
  | "boarding"
  | "selecting"
  | "closing"
  | "traveling"
  | "destination_opening"
  | "exiting"
  | "destination_closing";

interface MapRect extends RpgHalfOpenWorldRect {}
interface CollisionRect extends MapRect { id: string; sourceAnnotationId?: string }
interface ForegroundDefinition {
  id: string;
  sourceAnnotationId?: string;
  maskBounds: MapRect;
  baselineY: number;
  renderMode: "foot_behind_baseline";
}
interface LayoutPoint { id?: string; x: number; y: number; facing?: "up" | "down" }
interface LayoutElevator {
  id: string;
  sourceAnnotationId?: string;
  visibleBounds: MapRect;
  doorCenter: { x: number; y: number };
  standPosition: LayoutPoint;
  arrivalPosition: LayoutPoint;
  travelBounds: MapRect;
}
interface LayoutStairLanding {
  id: string;
  direction: "up" | "down";
  targetStoryFloor: StoryFloor;
  bounds: MapRect;
  standPosition: { x: number; y: number };
  arrivalPosition: { x: number; y: number };
}
interface LayoutAnchor { id: string; label: string; bounds: MapRect }
interface LayoutFloor {
  displayFloor: DisplayFloor;
  storyFloor: StoryFloor;
  roomId: string;
  checkpoint: RpgCheckpointId;
  assetId: "a1_base" | "a2_base" | "a3_base";
  staticCollisions: CollisionRect[];
  walkableRegions?: CollisionRect[];
  foregroundOcclusions: ForegroundDefinition[];
  anchors: LayoutAnchor[];
  stairLandings: LayoutStairLanding[];
  elevator: LayoutElevator;
  safeSpawn: LayoutPoint;
}
interface PlatePhysicalDelta {
  id: string;
  storyFloor: StoryFloor;
  statePlateIds: string[];
  activation: "plate_active" | "runtime_furniture_visible";
  collisionBounds?: CollisionRect[];
  occlusionBounds?: ForegroundDefinition[];
  collisionSource?: string;
  worldRoomBounds?: MapRect;
}
interface ChapterFourMazeLayout {
  schemaVersion: 2;
  worldSize: { width: number; height: number };
  playerFootBoxContract: {
    sourceFootBox: MapRect;
    worldFootBox: { width: number; height: number };
  };
  bakeryRuntime: BakeryRuntimeContract;
  maintenanceRuntime: MaintenanceRuntimeContract;
  finalClockRuntime: FinalClockRuntimeContract;
  lightGridRuntime: LightGridRuntimeContract;
  finalChaseRuntime: FinalChaseRuntimeContract;
  finalMinuteRuntime: FinalMinuteRuntimeContract;
  frontDeskRuntime: FrontDeskRuntimeContract;
  supportNpcRuntimes: SupportNpcRuntimeContract[];
  morningCheckinRuntime: MorningCheckinRuntimeContract;
  floors: LayoutFloor[];
  physicalDeltas: PlatePhysicalDelta[];
  evidenceDetails: EvidenceDetailContract[];
  transportCore: {
    elevators: Array<{ id: string; storyFloors: StoryFloor[] }>;
    stairs: Array<{ id: string; bounds: MapRect; storyFloors: StoryFloor[] }>;
  };
}
interface EvidenceDetailPlacement {
  id?: string;
  storyFloor: StoryFloor;
  phaseIds: GameState["chapter4"]["phase"][];
  statePlateIds?: string[];
  requiredFacts?: ChapterFourFactId[];
  bounds: MapRect;
}
interface EvidenceDetailContract {
  id: string;
  family: string;
  visual: string;
  glyph?: string;
  color: string;
  source: EvidenceDetailPlacement;
  echoes: EvidenceDetailPlacement[];
}
interface FrontDeskRuntimeContract {
  storyFloor: "A1";
  npcId: "a1_front_desk_attendant";
  texture: "chapter-four-front-desk-staff";
  animation: "chapter-four-front-desk-staff-idle";
  frames: number[];
  frameRate: number;
  origin: { x: 0.5; y: 1 };
  uniformScale: number;
  position: { x: number; y: number };
  interactionAnchorId: "a1_front_desk_attendant";
  counterForegroundOcclusionId: string;
  activePhases: GameState["chapter4"]["phase"][];
  collision: false;
}
interface SupportNpcRuntimeContract {
  storyFloor: "A2" | "A3";
  npcId: "a2_elevator_attendant" | "a3_reference_teacher";
  visualSource: "finale_npc" | "front_desk_staff";
  animation: FinaleNpcAnimationId | "chapter-four-front-desk-staff-idle";
  origin: { x: 0.5; y: 1 };
  uniformScale: number;
  position: { x: number; y: number };
  interactionAnchorId: "a2_elevator_attendant" | "a3_reference_teacher";
  activePhases: GameState["chapter4"]["phase"][];
  collision: false;
}
interface FinalChaseRuntimeContract {
  storyTimeSeconds: 28440;
  playerSpeed: 208;
  guardSpeed: 196;
  stableCommittedFramesToArm: 4;
  maxStepMs: 50;
  transportId: "main_stair";
  restartCheckpoint: "c4_a1_lobby";
  playerStart: { storyFloor: "A1"; x: number; y: number };
  guardSpawn: { storyFloor: "A1"; x: number; y: number };
  waypoints: Array<{ id: string; storyFloor: "A1" | "A2"; x: number; y: number; role: string }>;
  decoyBranches: Array<{ id: string; storyFloor: "A1" | "A2"; x: number; y: number; canAdvance: false }>;
  finishThreshold: {
    targetId: "a2_202_threshold";
    point: { x: number; y: number };
    bounds: MapRect;
    priority: "finish_before_contact_same_frame";
  };
  room202Door: {
    id: "a2_room202_door";
    barrierBounds: MapRect;
    states: Readonly<Record<"final_chase" | "final_minute_recovery" | "return_to_clock", {
      state: "open" | "closed";
      collider: boolean;
    }>>;
    visual: "procedural_status_only";
    officialClosedDoorSprite: false;
  };
}
interface FinalMinuteRuntimeContract {
  storyFloor: "A2";
  statePlateId: "a2_202_final_minute";
  targetId: "a2_202_projection";
  entityId: string;
  texture: "chapter4_story_items";
  frame: "final_minute_shard";
  pivot: { x: number; y: number };
  uniformScale: number;
  installationBounds: MapRect;
  standPosition: { x: number; y: number };
  recoveryPlayerSpawn: { x: number; y: number };
  proximity: number;
  requiredMode: "light";
  collision: false;
}
interface MorningCheckinRuntimeTargetContract {
  targetId: "a1_campus_card_reader" | "a1_attendance_paper_slot";
  entityId: string;
  installationBounds: MapRect;
  standPosition: { x: number; y: number };
  proximity: number;
  boundsDerivation: {
    kind: string;
    zoneSource: "visibleFixture.getBounds";
  };
  approximate: false;
}
interface MorningCheckinRuntimeContract {
  storyFloor: "A1";
  statePlateId: "a1_0755_morning";
  approximate: false;
  deskCenter: { x: number; y: number };
  targetEntities: MorningCheckinRuntimeTargetContract[];
}
interface FinalClockRuntimeContract {
  storyFloor: "A1";
  statePlateId: "a1_2245_maintenance";
  clockFrame: "gear_running";
  clockCenter: { x: number; y: number };
  visualRegistration: {
    axis: { x: number; y: number };
    sourceFrameFaceRadius: number;
    statePlateFaceRadius: number;
    uniformScale: number;
    framePivotRole: "clock_axis";
    authority: string;
    approximate: false;
  };
  minuteHandRadius: number;
  initialAngleDegrees: number;
  targetAngleDegrees: number;
  releaseToleranceDegrees: number;
  endpoint: {
    targetId: "a1_hall_clock_minute_endpoint";
    entityId: string;
    installationBounds: MapRect;
    standPosition: { x: number; y: number };
    proximity: number;
    approximate: boolean;
  };
  presentation: {
    lockAtMs: number;
    minuteHandAtMs: number;
    paperFlightAtMs: number;
    commitAtMs: number;
    feedbackAtMs: number;
  };
  approximate: boolean;
}
interface LightGridRuntimeContract {
  storyFloor: "A1";
  statePlateId: "a1_0754_blackout";
  panel: {
    targetId: "a1_power_panel";
    entityId: string;
    installationBounds: MapRect;
    visibleBoxBounds: MapRect;
    standPosition: { x: number; y: number };
    proximity: number;
    frames: ReadonlyArray<"closed" | "open_powered" | "open_partial" | "open_restored">;
    approximate: true;
  };
  visualRegions: Array<{
    id: ChapterFourLightZoneId;
    bounds: MapRect;
    nonColliding: true;
    visualOnly: true;
    approximate: true;
  }>;
  approximate: true;
}
interface MaintenanceRuntimeTargetDefinition {
  targetId:
    | "a1_cleaning_cart_wheel_inspection"
    | "a1_bakery_back_pry_bar"
    | "a1_cleaning_cart_wheel_cover"
    | "a1_cleaning_cart_oil_bottle"
    | "a1_cleaning_cart_wheel"
    | "a1_hall_clock_gear";
  entityId: string;
  installationBounds: MapRect;
  standPosition: { x: number; y: number };
  proximity: number;
  frame?: "short_pry_tool_candidate" | "lubricating_oil";
  pivot?: { x: number; y: number };
  uniformScale?: number;
  frameBefore?: "gear_stuttering";
  frameAfter?: "gear_running";
  boundsDerivation:
    | {
        kind: "visible_story_item_manifest_interaction";
        spritesheetId: "chapter4_story_items";
        interactionId: string;
      }
    | {
        kind: "visible_cleaning_cart_frame_local_region";
        source: "maintenanceRuntime.cleaningCart.wheelRegion";
        visualState?: "programmatic_open_cover";
      }
    | {
        kind: "visible_clock_frame_manifest_world_interaction";
        spritesheetId: "chapter4_clock_states";
        interactionId: "a1_world_trigger";
        floor: "A1";
      };
}
interface MaintenanceRuntimeContract {
  storyFloor: "A1";
  statePlateId: "a1_2245_maintenance";
  pryBar: {
    frame: "short_pry_tool_candidate";
    pivot: { x: number; y: number };
    uniformScale: number;
  };
  cleaningCart: {
    texture: "cleaning_cart";
    position: { x: number; y: number };
    uniformScale: number;
    visibleBounds: MapRect;
    footBounds: MapRect;
    wheelRegion: {
      coordinateSpace: "cleaning_cart_frame_local";
      sourceFrameSize: { width: 144; height: 128 };
      origin: { x: 0.5; y: 1 };
      bounds: MapRect;
      visualRole: "programmatic_wheel_cover_and_wheel_interaction";
    };
  };
  cleaner: {
    animationId: "cleaner_idle";
    position: { x: number; y: number };
    uniformScale: number;
    footBounds: MapRect;
  };
  guard: {
    animationId: "guard_walk";
    position: { x: number; y: number };
    uniformScale: number;
    footBox: { width: number; height: number };
  };
  repairedPush: {
    animationId: "cleaner_push_cart_up";
    from: { x: number; y: number };
    to: { x: number; y: number };
    durationMs: number;
  };
  targetEntities: MaintenanceRuntimeTargetDefinition[];
}
interface BakeryRuntimeTargetDefinition {
  targetId:
    | "a1_bakery_inspection_lamp"
    | "a1_bakery_conveyor_edge"
    | "a1_bakery_hour_hand_pickup";
  entityId: string;
  installationBounds: MapRect;
  standPosition: { x: number; y: number };
  proximity: number;
  visual?: {
    texture: "chapter4_story_items";
    frame: "old_clock_hour_hand";
    pivot: { x: number; y: number };
    uniformScale: number;
    sourceInteractionBounds: MapRect;
    sourceCell: MapRect;
    sourcePivot: { x: number; y: number };
  };
}
interface BakeryRuntimeContract {
  storyFloor: "A1";
  statePlateId: "a1_1225_bakery";
  targetEntities: BakeryRuntimeTargetDefinition[];
  baker: {
    textureFile: string;
    framePair: number;
    frames: number[];
    origin: { x: 0.5; y: 1 };
    uniformScale: number;
    position: { x: number; y: number };
    visibleSourceHeight: number;
    collision: false;
    foregroundOcclusionId: string;
    activePhases: Array<"bakery_hour_hand" | "morning_checkin">;
  };
  crowd: {
    texture: "student_walk";
    collisionProfile: "playerFootBoxContract.worldFootBox";
    origin: { x: 0.5; y: 1 };
    displayScale: number;
    routes: Array<{
      id: string;
      from: { x: number; y: number };
      to: { x: number; y: number };
      speed: number;
      endpointPauseMs: number;
    }>;
  };
  walkabilityRoutes: Array<{
    id: string;
    waypoints: Array<{ x: number; y: number }>;
  }>;
}
interface FloorDefinition extends LayoutFloor { offsetX: number; title: string }
interface TravelTarget {
  id: "elevator" | "stair_up" | "stair_down";
  label: string;
  bounds: MapRect;
  targetFloor?: DisplayFloor;
  route: TravelRoute;
}
interface PendingMove {
  requestId: string;
  fromFloor: DisplayFloor;
  targetFloor: DisplayFloor;
  route: TravelRoute;
}
interface PendingStoryRequest {
  requestId: string;
  intentType: ChapterFour755Intent["type"];
  targetId?: string;
  timer: Phaser.Time.TimerEvent;
}
type StoryPresentation =
  | "idle"
  | "paper_flight"
  | "external_time_rejection"
  | "hall_clock_inspection"
  | "first_clock_pull"
  | "bakery_conveyor_stop"
  | "room204_projection"
  | "minute_theft";
interface ElevatorVisual {
  floor: DisplayFloor;
  door: Phaser.GameObjects.Sprite;
  indicator: Phaser.GameObjects.Text;
  lamp: Phaser.GameObjects.Arc;
}
interface AppliedForeground {
  id: string;
  floor: DisplayFloor;
  sourceAnnotationId?: string;
  maskBounds: MapRect;
  baselineY: number;
  renderMode: "foot_behind_baseline";
  image: Phaser.GameObjects.Image;
}
interface ProjectedTarget {
  contract: ChapterFour755InteractionTargetContract;
  floor: DisplayFloor;
  bounds: Readonly<MapRect>;
  acceptedItem: ItemId | null | undefined;
}
interface PreparedForeground {
  id: string;
  floor: DisplayFloor;
  sourceAnnotationId?: string;
  worldBounds: MapRect;
  localBounds: MapRect;
  baselineY: number;
  plateId: ChapterFour755PlateId;
}
interface PreparedPlateGroup {
  signature: string;
  plateIds: Readonly<Record<StoryFloor, ChapterFour755PlateId>>;
  preparedStoryFloors: StoryFloor[];
  colliders: CollisionRect[];
  foregrounds: PreparedForeground[];
  deferredFailures: string[];
}
interface StagedPlateApplication {
  foregrounds: AppliedForeground[];
  obstacles: Phaser.Physics.Arcade.StaticGroup;
  playerCollider: Phaser.Physics.Arcade.Collider;
  colliderDebugObjects: Phaser.GameObjects.Rectangle[];
}
interface BackgroundTextureSnapshot {
  floor: DisplayFloor;
  image: Phaser.GameObjects.Image;
  textureKey: string;
  frameName: string | number;
}
type BakeryBoundsObject = Phaser.GameObjects.Rectangle | Phaser.GameObjects.Sprite;
interface BakeryRuntimeTargetBinding {
  targetId: BakeryRuntimeTargetDefinition["targetId"];
  entityId: string;
  boundsObject: BakeryBoundsObject;
}
interface BakeryCrowdActor {
  sprite: Phaser.Physics.Arcade.Sprite;
  tween: Phaser.Tweens.Tween;
  routeIndex: number;
  route: BakeryRuntimeContract["crowd"]["routes"][number];
  hasLeftInitialEndpoint: boolean;
  activeEndpoint: "from" | "to" | null;
  endpointTimer: Phaser.Time.TimerEvent | null;
}
interface Room204RuntimePiece {
  pieceId: ChapterFourRoom204PieceId;
  deskSprite: Phaser.GameObjects.Sprite;
  chairSprite: Phaser.GameObjects.Sprite;
  deskObstacle: Phaser.GameObjects.Zone;
  chairObstacle: Phaser.GameObjects.Zone;
}
interface Room204DiscussionTableRuntime {
  id: string;
  pieceIds: readonly ChapterFourRoom204PieceId[];
  sprite: Phaser.GameObjects.Sprite;
  obstacle: Phaser.GameObjects.Zone;
}
interface Room204RuntimeTargetBinding {
  targetId: string;
  entityId: string;
  boundsObject: Phaser.GameObjects.Zone;
}
interface PhaseRuntimeTargetBinding {
  targetId: string;
  entityId: string;
  floor: DisplayFloor;
  boundsObject: Phaser.GameObjects.Rectangle | Phaser.GameObjects.Zone;
}
export type ChapterFourPlateTransactionFaultPoint =
  | "foreground_stage"
  | "collision_stage"
  | "background_set_texture"
  | "activation";
export interface ChapterFourPlateTransactionFaultContext {
  point: ChapterFourPlateTransactionFaultPoint;
  index?: number;
  floor?: DisplayFloor;
  id?: string;
  step?: "body" | "player_collider" | "activate_new" | "deactivate_old";
}
export const CHAPTER_FOUR_PLATE_TRANSACTION_FAULT_INJECTOR_KEY =
  "chapterFourPlateTransactionFaultInjector";

const LAYOUT = mazeLayout as ChapterFourMazeLayout;
const FLOOR_SIZE = LAYOUT.worldSize;
const FLOOR_GAP = 192;
const FLOOR_STRIDE = FLOOR_SIZE.width + FLOOR_GAP;
const WORLD = Object.freeze({
  width: FLOOR_SIZE.width * LAYOUT.floors.length + FLOOR_GAP * (LAYOUT.floors.length - 1),
  height: FLOOR_SIZE.height
});
const PLAYER_SPEED = 176;
const PLAYER_DEPTH_BASE = CHAPTER_FOUR_PLAYER_DEPTH_BASE;
const PLAYER_TOP_DEPTH = CHAPTER_FOUR_PLAYER_TOP_DEPTH;
const MAIN_ENTRANCE_FOREGROUND_ID = "floor_1_a1_foreground_017";
const MAIN_ENTRANCE_OCCLUSION_DEPTH = PLAYER_TOP_DEPTH + 1;
const REALITY_MODE_ATMOSPHERE_DEPTH = PLAYER_TOP_DEPTH - 100;
const REALITY_MODE_TARGET_DEPTH = PLAYER_TOP_DEPTH - 50;
const REALITY_MODE_TRANSITION_MS = 240;
const ELEVATOR_TEXTURE = CHAPTER_FOUR_ELEVATOR_TEXTURE_KEY;
const BAKERY_COUNTER_BAKER_TEXTURE = CHAPTER_FOUR_BAKERY_STAFF_TEXTURE_KEY;
const BAKERY_COUNTER_BAKER_ANIMATION = "chapter-four-bakery-counter-auntie-pair-3";
const FRONT_DESK_STAFF_TEXTURE = CHAPTER_FOUR_FRONT_DESK_TEXTURE_KEY;
const FRONT_DESK_STAFF_ANIMATION = "chapter-four-front-desk-staff-idle";
const ELEVATOR_FRAME_COUNT = 6;
const ELEVATOR_FRAME_WIDTH = 72;
const ELEVATOR_FRAME_HEIGHT = 96;
const ELEVATOR_DOOR_MS = 440;
const ELEVATOR_BOARD_MS = 420;
const ELEVATOR_TRAVEL_PER_FLOOR_MS = 620;
const REQUEST_TIMEOUT_MS = 1800;
const STORY_REQUEST_TIMEOUT_MS = 2600;
const FINAL_CLOCK_DRAG_SAFETY_TIMEOUT_MS = 30000;
const STORY_RETRY_DELAY_MS = 900;
const CHAPTER_FOUR_WORLD_PIXELS_PER_METER = 48;
const PLATE_RETRY_BASE_MS = 120;
const PLATE_RETRY_MAX_MS = 1920;
const EXPECTED_MANIFEST_ENTRY_COUNT = 62;
const EXPECTED_EMPTY_FRAME_COUNT = 1;
const RUNTIME_MANAGED_DYNAMIC_COLLISION_IDS: ReadonlySet<string> = new Set([
  "a1_guard_chase_body",
  "a2_guard_chase_body"
]);
const FLOOR_TITLES: Readonly<Record<DisplayFloor, string>> = Object.freeze({
  1: "A1 · 麦思威面包坊与门厅",
  2: "A2 · 教室与开放学习区",
  3: "A3 · 校友荣誉门厅"
});
const FLOORS: readonly FloorDefinition[] = LAYOUT.floors.map((floor) => ({
  ...floor,
  offsetX: (floor.displayFloor - 1) * FLOOR_STRIDE,
  title: FLOOR_TITLES[floor.displayFloor]
}));
const LIGHT_ZONES = chapterFourContent.lightGrid.zones as readonly {
  id: ChapterFourLightZoneId;
  label: string;
  bit: number;
}[];
const OPENING_HANDSHAKE = chapterFourContent.openingHandshake;
const CHAPTER_FOUR_DIALOGUES = chapterFourContent.dialogues as Readonly<
  Record<string, ReadonlyArray<{ speaker: string; text: string }>>
>;

function chapterFourDialogueText(key: string, entryIndex = 0): string {
  return CHAPTER_FOUR_DIALOGUES[key]?.[entryIndex]?.text ?? "";
}

function chapterFourDialogueSequence(key: string): string {
  return CHAPTER_FOUR_DIALOGUES[key]?.map((entry) => entry.text).join(" ") ?? "";
}
const OPENING_PHASES: ReadonlySet<GameState["chapter4"]["phase"]> = new Set([
  "opening_handoff",
  "opening_paper_caught",
  "hall_clock_inspection"
]);
const BAKERY_RUNTIME = LAYOUT.bakeryRuntime;
const FRONT_DESK_RUNTIME = LAYOUT.frontDeskRuntime;
const SUPPORT_NPC_RUNTIMES = LAYOUT.supportNpcRuntimes;
const MAINTENANCE_RUNTIME = LAYOUT.maintenanceRuntime;
const FINAL_CLOCK_RUNTIME = LAYOUT.finalClockRuntime;
const LIGHT_GRID_RUNTIME = LAYOUT.lightGridRuntime;
const FINAL_CHASE_RUNTIME = LAYOUT.finalChaseRuntime;
const FINAL_MINUTE_RUNTIME = LAYOUT.finalMinuteRuntime;
const MORNING_CHECKIN_RUNTIME = LAYOUT.morningCheckinRuntime;
const TASK7_LIVE_READY_TARGET_IDS: ReadonlySet<string> = new Set([
  "a1_noticeboard_paper",
  "a1_hall_clock"
]);

/** Task 9 extends the playable chain through the A3 reference, A2 residuals, and the positioning plate. */
export const TASK9_ACTIONABLE_TARGET_IDS: ReadonlySet<string> = new Set([
  "a1_noticeboard_paper",
  "a1_hall_clock",
  "a1_bakery_inspection_lamp",
  "a1_bakery_conveyor_edge",
  "a1_bakery_hour_hand_pickup",
  "a1_hall_clock_hour_hand_socket",
  "a1_front_desk_attendant",
  "a2_elevator_attendant",
  "a3_reference_teacher",
  ...CHAPTER_FOUR_CONTEXT_INTERACTION_TARGET_IDS,
  "a3_alumni_su_buqing",
  "a3_alumni_zhu_kezhen",
  "a3_alumni_lu_yongxiang",
  "a3_alumni_chen_jiangong",
  "a3_alumni_tan_jiazhen",
  "a3_alumni_cheng_kaijia",
  "a1_classroom_104_blackboard_residual",
  "a1_classroom_105_lectern_terminal",
  "a3_reference_classroom_layout",
  "a2_room204_residual_group",
  "a2_room204_podium_drawer",
  "a1_hall_clock_positioning_plate_slot",
  ...Object.keys(CHAPTER_FOUR_755_INTERACTION_TARGETS).filter((targetId) => (
    targetId.startsWith("a2_room204_slot_")
  ))
]);
export const TASK10_ACTIONABLE_TARGET_IDS: ReadonlySet<string> = new Set([
  ...TASK9_ACTIONABLE_TARGET_IDS,
  "a1_cleaning_cart_wheel_inspection",
  "a1_bakery_back_pry_bar",
  "a1_cleaning_cart_wheel_cover",
  "a1_cleaning_cart_oil_bottle",
  "a1_cleaning_cart_wheel",
  "a1_hall_clock_gear"
]);
export const TASK11_ACTIONABLE_TARGET_IDS: ReadonlySet<string> = new Set([
  ...TASK10_ACTIONABLE_TARGET_IDS,
  "a1_hall_clock_minute_endpoint",
  "a1_power_panel"
]);
export const TASK12_ACTIONABLE_TARGET_IDS: ReadonlySet<string> = new Set([
  ...TASK11_ACTIONABLE_TARGET_IDS,
  "a2_202_projection"
]);
export const TASK13_ACTIONABLE_TARGET_IDS: ReadonlySet<string> = new Set([
  ...TASK12_ACTIONABLE_TARGET_IDS,
  "a1_campus_card_reader",
  "a1_attendance_paper_slot"
]);
const MAINTENANCE_RUNTIME_TARGET_IDS = Object.freeze([
  "a1_cleaning_cart_wheel_inspection",
  "a1_bakery_back_pry_bar",
  "a1_cleaning_cart_wheel_cover",
  "a1_cleaning_cart_oil_bottle",
  "a1_cleaning_cart_wheel",
  "a1_hall_clock_gear"
] as const);
const FINAL_CLOCK_RUNTIME_TARGET_IDS = Object.freeze([
  "a1_hall_clock_minute_endpoint"
] as const);
const LIGHT_GRID_RUNTIME_TARGET_IDS = Object.freeze([
  "a1_power_panel"
] as const);
const MORNING_CHECKIN_RUNTIME_TARGET_IDS = Object.freeze([
  "a1_campus_card_reader",
  "a1_attendance_paper_slot"
] as const);
const PHASE_TRAVEL_ROOM_OVERRIDES: Readonly<Partial<Record<
  GameState["chapter4"]["phase"],
  Partial<Record<DisplayFloor, { roomId: string; checkpoint: RpgCheckpointId }>>
>>> = Object.freeze({
  room204_restore: Object.freeze({
    1: { roomId: "a1_hall_clock", checkpoint: "c4_a1_lobby" as RpgCheckpointId },
    2: { roomId: "a2_corridor", checkpoint: "c4_a2_corridor" as RpgCheckpointId },
    3: { roomId: "a3_wayfinding", checkpoint: "c4_a3_wayfinding" as RpgCheckpointId }
  }),
  final_chase: Object.freeze({
    1: { roomId: "a1_lobby", checkpoint: "c4_a1_lobby" as RpgCheckpointId },
    2: { roomId: "a2_corridor", checkpoint: "c4_a2_corridor" as RpgCheckpointId }
  }),
  return_to_clock: Object.freeze({
    1: { roomId: "a1_lobby", checkpoint: "c4_a1_lobby" as RpgCheckpointId },
    2: { roomId: "a2_corridor", checkpoint: "c4_a2_corridor" as RpgCheckpointId }
  }),
  morning_checkin: Object.freeze({
    1: { roomId: "a1_checkin", checkpoint: "c4_a1_lobby" as RpgCheckpointId }
  }),
  exterior_closure: Object.freeze({
    1: { roomId: "a1_exterior", checkpoint: "c4_a1_lobby" as RpgCheckpointId }
  }),
  complete: Object.freeze({
    1: { roomId: "a1_exterior", checkpoint: "c4_a1_lobby" as RpgCheckpointId }
  })
});

function isRoom204SlotTargetId(targetId: string): targetId is `a2_room204_slot_${ChapterFourRoom204SlotId}` {
  return targetId.startsWith("a2_room204_slot_");
}

function getFloor(displayFloor: DisplayFloor): FloorDefinition {
  const floor = FLOORS.find((candidate) => candidate.displayFloor === displayFloor);
  if (!floor) throw new Error(`Missing Chapter 4 display floor: ${displayFloor}`);
  return floor;
}
function displayFloorFor(storyFloor: string): DisplayFloor | null {
  return FLOORS.find((floor) => floor.storyFloor === storyFloor)?.displayFloor ?? null;
}
function rectRight(rect: Readonly<MapRect>): number { return rect.x + rect.width }
function rectBottom(rect: Readonly<MapRect>): number { return rect.y + rect.height }
function rectCenterX(rect: Readonly<MapRect>): number { return rect.x + rect.width / 2 }
function rectCenterY(rect: Readonly<MapRect>): number { return rect.y + rect.height / 2 }
function rectEquals(a: Readonly<MapRect>, b: Readonly<MapRect>): boolean {
  return a.x === b.x && a.y === b.y && a.width === b.width && a.height === b.height;
}
function pointInsideRect(point: Readonly<{ x: number; y: number }>, rect: Readonly<MapRect>): boolean {
  return point.x >= rect.x && point.x < rect.x + rect.width
    && point.y >= rect.y && point.y < rect.y + rect.height;
}
function shortestAngleDistance(a: number, b: number): number {
  return Math.abs(((a - b + 540) % 360) - 180);
}
function lightZoneBit(zoneId: ChapterFourLightZoneId): number {
  const zone = LIGHT_ZONES.find((candidate) => candidate.id === zoneId);
  if (!zone) throw new Error(`chapter4_light_zone_missing:${zoneId}`);
  return zone.bit;
}
function offsetRect(rect: Readonly<MapRect>, offsetX: number): MapRect {
  return { x: rect.x + offsetX, y: rect.y, width: rect.width, height: rect.height };
}
function structuredContractFailure(
  source: "runtime" | "plate" | "spatial_attestation",
  raw: string
): {
  source: "runtime" | "plate" | "spatial_attestation";
  code: string;
  detail: string | null;
  raw: string;
} {
  const separator = raw.indexOf(":");
  return {
    source,
    code: separator < 0 ? raw : raw.slice(0, separator),
    detail: separator < 0 ? null : raw.slice(separator + 1),
    raw
  };
}
function rectIsValid(rect: Readonly<MapRect>): boolean {
  return Number.isFinite(rect.x) && Number.isFinite(rect.y)
    && Number.isFinite(rect.width) && Number.isFinite(rect.height)
    && rect.width > 0 && rect.height > 0;
}
function rectInsideFloor(rect: Readonly<MapRect>): boolean {
  return rectIsValid(rect) && rect.x >= 0 && rect.y >= 0
    && rectRight(rect) <= FLOOR_SIZE.width && rectBottom(rect) <= FLOOR_SIZE.height;
}
function pointDistanceToRect(point: { x: number; y: number }, rect: Readonly<MapRect>): number {
  const dx = Math.max(rect.x - point.x, 0, point.x - rectRight(rect));
  const dy = Math.max(rect.y - point.y, 0, point.y - rectBottom(rect));
  return Math.hypot(dx, dy);
}
function basePlateFor(storyFloor: StoryFloor): ChapterFour755PlateId {
  return `${storyFloor.toLowerCase()}_base` as ChapterFour755PlateId;
}
function plateForFloor(
  projection: ChapterFourMazeProjection,
  storyFloor: StoryFloor
): ChapterFour755PlateId {
  const prefix = `${storyFloor.toLowerCase()}_`;
  return (projection.activePlateIds.find((id) => id.startsWith(prefix))
    ?? basePlateFor(storyFloor)) as ChapterFour755PlateId;
}
function desiredPlateGroup(
  projection: ChapterFourMazeProjection
): Readonly<Record<StoryFloor, ChapterFour755PlateId>> {
  return Object.freeze({
    A1: plateForFloor(projection, "A1"),
    A2: plateForFloor(projection, "A2"),
    A3: plateForFloor(projection, "A3")
  });
}
function createBaseAppliedProjection(
  projection: ChapterFourMazeProjection,
  storyFloor: StoryFloor
): ChapterFourMazeProjection {
  const activePlateIds = FLOORS.map((floor) => basePlateFor(floor.storyFloor));
  return {
    ...projection,
    activePlateIds,
    plateId: basePlateFor(storyFloor),
    availableTargetIds: [],
    dynamicCollisionIds: [],
    occlusionIds: [],
    npcIds: [],
    guardMode: "absent",
    doorStates: {},
    visibleNpcIds: [],
    residualNpcIds: [],
    activeDoorIds: [],
    activePartitionIds: [],
    activeCollisionIds: [],
    activeTargetIds: []
  };
}
export function chapterFourPlateRetryDelayMs(failedAttempts: number): number {
  const normalizedAttempts = Number.isFinite(failedAttempts)
    ? Math.max(1, Math.floor(failedAttempts))
    : 1;
  const exponent = Math.max(0, Math.min(4, normalizedAttempts - 1));
  return Math.min(PLATE_RETRY_MAX_MS, PLATE_RETRY_BASE_MS * (2 ** exponent));
}
function hasOwnInventoryItem(
  items: GameState["items"],
  value: unknown
): value is ItemId {
  return typeof value === "string"
    && Object.prototype.hasOwnProperty.call(items, value);
}
function createTravelTargets(floor: FloorDefinition): TravelTarget[] {
  const targets: TravelTarget[] = [{
    id: "elevator",
    label: "主电梯",
    bounds: floor.elevator.travelBounds,
    route: "elevator"
  }];
  for (const landing of floor.stairLandings) {
    const targetFloor = displayFloorFor(landing.targetStoryFloor);
    if (!targetFloor) continue;
    targets.push({
      id: landing.direction === "up" ? "stair_up" : "stair_down",
      label: landing.direction === "up" ? "楼梯上行口" : "楼梯下行口",
      bounds: landing.bounds,
      targetFloor,
      route: "stair"
    });
  }
  return targets;
}
function resultReason(payload?: Record<string, unknown>): string {
  const result = payload?.result;
  return typeof result === "object" && result !== null && "reason" in result
    ? String((result as { reason?: unknown }).reason ?? "locked")
    : "locked";
}
function resultAccepted(payload?: Record<string, unknown>): boolean {
  const result = payload?.result;
  return typeof result === "object" && result !== null
    && (result as { accepted?: unknown }).accepted === true;
}
function errorMessage(error: unknown): string {
  return error instanceof Error ? error.message : String(error);
}
function hasChapterFourFact(state: GameState, factId: ChapterFourFactId): boolean {
  return state.chapter4.factIds.includes(factId);
}
export function selectA1FrontDeskDialogueKey(state: GameState): string {
  if (state.chapter4.phase === "bakery_hour_hand") return "frontDesk.bakery";
  if (state.chapter4.phase === "morning_checkin") return "frontDesk.morning_checkin";
  if (state.chapter4.phase === "exterior_closure") return "frontDesk.exterior_closure";
  const observed104 = hasChapterFourFact(state, "classroom_104_chalk_residual_observed");
  const checked105 = hasChapterFourFact(state, "classroom_105_terminal_replay_checked");
  if (observed104 && checked105) return "frontDesk.classrooms_done";
  if (observed104) return "frontDesk.classroom_104_done";
  if (checked105) return "frontDesk.classroom_105_done";
  return "frontDesk.classrooms_none";
}

export class ChapterFourTemporalMazeScene extends Phaser.Scene {
  private bridge!: RpgBridge;
  private player!: Phaser.Physics.Arcade.Sprite;
  private animator!: RpgPlayerAnimator;
  private staticObstacles!: Phaser.Physics.Arcade.StaticGroup;
  private plateObstacles!: Phaser.Physics.Arcade.StaticGroup;
  private platePlayerCollider: Phaser.Physics.Arcade.Collider | null = null;
  private backgrounds = new Map<DisplayFloor, Phaser.GameObjects.Image>();
  private elevatorVisuals = new Map<DisplayFloor, ElevatorVisual>();
  private appliedForegrounds: AppliedForeground[] = [];
  private targetVisuals = new Map<string, Phaser.GameObjects.Container>();
  private insertedPuzzleProps = new Map<string, Phaser.GameObjects.Image>();
  private darkRealityVisuals: Phaser.GameObjects.Container | null = null;
  private lightRealityVisuals: Phaser.GameObjects.Container | null = null;
  private renderedRealityMode: GameState["chapter4"]["mode"] | null = null;
  private debugOverlayObjects: Phaser.GameObjects.GameObject[] = [];
  private plateColliderDebugObjects: Phaser.GameObjects.Rectangle[] = [];
  private cursors!: Phaser.Types.Input.Keyboard.CursorKeys;
  private keys!: Record<"W" | "A" | "S" | "D", Phaser.Input.Keyboard.Key>;
  private interactKey!: Phaser.Input.Keyboard.Key;
  private confirmKey!: Phaser.Input.Keyboard.Key;
  private escapeKey!: Phaser.Input.Keyboard.Key;
  private floorKeys!: Record<DisplayFloor, Phaser.Input.Keyboard.Key>;
  private currentFloor: DisplayFloor = 1;
  private virtualDirection = { x: 0, y: 0 };
  private interactionRequested = false;
  private nearbyTravelTarget: TravelTarget | null = null;
  private nearbyTravelTargetHasPriority = false;
  private nearbyStoryTarget: ProjectedTarget | null = null;
  private nearbyAlumniFigure: ChapterFourAlumniHonorWallFigure | null = null;
  private nearbyLandmark: LayoutAnchor | null = null;
  private floorPanel: Phaser.GameObjects.Container | null = null;
  private floorPanelMode: "floors" | "elevator_calibration" | "elevator_route_deduction" = "floors";
  private floorPanelSelection: DisplayFloor = 1;
  private elevatorReplayStartSeconds = CHAPTER_FOUR_ELEVATOR.selectableStartMinSeconds;
  private elevatorCalibrationGraphics: Phaser.GameObjects.Graphics | null = null;
  private elevatorCalibrationReadout: Phaser.GameObjects.Text | null = null;
  private elevatorCalibrationFailed = false;
  private floorPanelButtons: Array<{
    floor: DisplayFloor;
    enabled: boolean;
    background: Phaser.GameObjects.Rectangle;
    label: Phaser.GameObjects.Text;
    detail: Phaser.GameObjects.Text;
    status: Phaser.GameObjects.Text;
  }> = [];
  private floorPanelTitle: Phaser.GameObjects.Text | null = null;
  private floorPanelDescription: Phaser.GameObjects.Text | null = null;
  private floorPanelEvidence: Phaser.GameObjects.Text | null = null;
  private floorPanelProgress: Phaser.GameObjects.Text | null = null;
  private floorPanelPrimaryButton: Phaser.GameObjects.Rectangle | null = null;
  private floorPanelPrimaryLabel: Phaser.GameObjects.Text | null = null;
  private floorPanelDeductionButton: Phaser.GameObjects.Rectangle | null = null;
  private floorPanelDeductionLabel: Phaser.GameObjects.Text | null = null;
  private elevatorDeductionArrivalFloor: ChapterFourElevatorDeductionFloor = "A2";
  private elevatorDeductionUnservedFloor: ChapterFourElevatorDeductionFloor = "A3";
  private elevatorDeductionFeedback = "";
  private elevatorDeductionGraphics: Phaser.GameObjects.Graphics | null = null;
  private elevatorDeductionReadout: Phaser.GameObjects.Text | null = null;
  private alumniPanel: Phaser.GameObjects.Container | null = null;
  private alumniPanelFigure: ChapterFourAlumniHonorWallFigure | null = null;
  private alumniWallObjects: Phaser.GameObjects.GameObject[] = [];
  private elevatorPhase: ElevatorPhase = "idle";
  private elevatorTargetFloor: DisplayFloor | null = null;
  private elevatorDoorProgress = 0;
  private pendingMove: PendingMove | null = null;
  private pendingMoveTimer: Phaser.Time.TimerEvent | null = null;
  private pendingStoryRequest: PendingStoryRequest | null = null;
  private storyPresentation: StoryPresentation = "idle";
  private storyPresentationTimers: Phaser.Time.TimerEvent[] = [];
  private storyRetryNotBeforeMs = 0;
  private lastPublishedStoryInputLock = false;
  private lastPublishedStoryPointerAllowed = false;
  private lastPublishedStoryKeyboardAllowed = false;
  private handoffReleased = false;
  private liveReadySignature = "";
  private openingPaperSprite: Phaser.GameObjects.Sprite | null = null;
  private hallClockStateSprite: Phaser.GameObjects.Sprite | null = null;
  private externalTimeOverlay: Phaser.GameObjects.Container | null = null;
  private bakeryRuntimeSignature = "";
  private bakeryRuntimeTargets = new Map<string, BakeryRuntimeTargetBinding>();
  private bakeryRuntimeObjects: Phaser.GameObjects.GameObject[] = [];
  private bakeryBaker: Phaser.GameObjects.Sprite | null = null;
  private bakeryCrowdActors: BakeryCrowdActor[] = [];
  private bakeryCrowdCollider: Phaser.Physics.Arcade.Collider | null = null;
  private bakeryConveyorGlint: Phaser.GameObjects.Rectangle | null = null;
  private bakeryConveyorTween: Phaser.Tweens.Tween | null = null;
  private bakeryHourHandSprite: Phaser.GameObjects.Sprite | null = null;
  private bakeryHourHandGlint: Phaser.GameObjects.Arc | null = null;
  private bakeryHourHandGlintTween: Phaser.Tweens.Tween | null = null;
  private bakeryApproachCueSignature = "";
  private bakeryActivityPaused = false;
  private frontDeskAttendant: Phaser.GameObjects.Sprite | null = null;
  private supportNpcSprites = new Map<SupportNpcRuntimeContract["npcId"], Phaser.GameObjects.Sprite>();
  private phaseRuntimeTargets = new Map<string, PhaseRuntimeTargetBinding>();
  private phaseRuntimeObjects: Phaser.GameObjects.GameObject[] = [];
  private maintenanceSignature = "";
  private maintenanceCart: Phaser.Physics.Arcade.Sprite | null = null;
  private maintenanceCleaner: Phaser.Physics.Arcade.Sprite | null = null;
  private maintenancePryBar: Phaser.GameObjects.Sprite | null = null;
  private maintenanceOilBottle: Phaser.GameObjects.Sprite | null = null;
  private maintenanceCoverVisual: Phaser.GameObjects.Rectangle | null = null;
  private maintenanceObstacleGroup: Phaser.Physics.Arcade.StaticGroup | null = null;
  private maintenanceObstacleCollider: Phaser.Physics.Arcade.Collider | null = null;
  private maintenancePushTween: Phaser.Tweens.Tween | null = null;
  private maintenanceSettledCart: Phaser.GameObjects.Sprite | null = null;
  private maintenanceAttemptSprite: Phaser.GameObjects.Sprite | null = null;
  private maintenanceAttemptTween: Phaser.Tweens.Tween | null = null;
  private maintenanceAttemptTimer: Phaser.Time.TimerEvent | null = null;
  private maintenancePushCompleted = false;
  private maintenanceGuardState: ChapterFourMaintenanceGuardState | null = null;
  private maintenanceGuardPresentationState: ChapterFourGuardPresentationState | null = null;
  private maintenanceGuard: Phaser.Physics.Arcade.Sprite | null = null;
  private maintenanceGuardWallCollider: Phaser.Physics.Arcade.Collider | null = null;
  private maintenanceGuardPlayerOverlap: Phaser.Physics.Arcade.Collider | null = null;
  private maintenanceGuardVision: Phaser.GameObjects.Graphics | null = null;
  private maintenanceGuardAlert: Phaser.GameObjects.Text | null = null;
  private maintenanceGuardVisualId: FinaleNpcAnimationId | null = null;
  private maintenanceGuardTravelDirection: NpcTravelDirection = "side";
  private maintenanceGuardTravelFlipX = true;
  private finalChaseGuardTravelDirection: NpcTravelDirection = "side";
  private finalChaseGuardTravelFlipX = false;
  private finalClockMinuteLine: Phaser.GameObjects.Line | null = null;
  private finalClockEndpointHandle: Phaser.GameObjects.Arc | null = null;
  private finalClockEndpointZone: Phaser.GameObjects.Zone | null = null;
  private finalClockDragActive = false;
  private finalClockDragPointerId: number | null = null;
  private finalClockDragDomPointerId: number | null = null;
  private finalClockPendingDomPointerId: number | null = null;
  private finalClockDomCanvas: HTMLCanvasElement | null = null;
  private finalClockDomCancelListening = false;
  private finalClockDragAutoCommit = false;
  private finalClockMinuteAngle = 180;
  private finalClockDragSafetyTimer: Phaser.Time.TimerEvent | null = null;
  private finalClockTween: Phaser.Tweens.Tween | null = null;
  private minuteTheftPaperSprite: Phaser.GameObjects.Sprite | null = null;
  private minuteTheftPaperTween: Phaser.Tweens.Tween | null = null;
  private lightGridPanelSprite: Phaser.GameObjects.Sprite | null = null;
  private lightGridOverlays = new Map<ChapterFourLightZoneId, Phaser.GameObjects.Rectangle>();
  private hostPowerPanelOpen = false;
  private hostPowerPanelSession: { openRequestId: string; targetId: string } | null = null;
  private finalChaseState: ChapterFourFinalChaseState | null = null;
  private finalChaseStep: ChapterFourFinalChaseStepResult | null = null;
  private finalChaseAudioBand: ChapterFourFinalChaseState["pursuitBand"] | null = null;
  private finalChaseCloseVoicePlayed = false;
  private finalChaseFloorVoicePlayed = false;
  private finalChaseInsideFinish = false;
  private finalChaseContact = false;
  private chaseGuard: Phaser.Physics.Arcade.Sprite | null = null;
  private chaseGuardStaticCollider: Phaser.Physics.Arcade.Collider | null = null;
  private chaseGuardPlateCollider: Phaser.Physics.Arcade.Collider | null = null;
  private finalMinuteSprite: Phaser.GameObjects.Sprite | null = null;
  private finalMinuteTargetZone: Phaser.GameObjects.Zone | null = null;
  private morningCheckinVisuals = new Map<string, {
    fixture: Phaser.GameObjects.Rectangle;
    details: Phaser.GameObjects.Graphics;
    label: Phaser.GameObjects.Text;
  }>();
  private morningCheckinStudents: Phaser.GameObjects.Sprite[] = [];
  private room202DoorBarrier: Phaser.GameObjects.Zone | null = null;
  private room202DoorCollider: Phaser.Physics.Arcade.Collider | null = null;
  private room202DoorVisual: Phaser.GameObjects.Rectangle | null = null;
  private room202DoorLabel: Phaser.GameObjects.Text | null = null;
  private lastPhaseSignature = "";
  private room204RuntimePieces = new Map<ChapterFourRoom204PieceId, Room204RuntimePiece>();
  private room204DiscussionTables: Room204DiscussionTableRuntime[] = [];
  private room204ResidualSprites: Phaser.GameObjects.Sprite[] = [];
  private room204SlotBoundsObjects = new Map<ChapterFourRoom204SlotId, Phaser.GameObjects.Zone>();
  private room204RuntimeTargets = new Map<string, Room204RuntimeTargetBinding>();
  private room204PodiumSprite: Phaser.GameObjects.Sprite | null = null;
  private room204PodiumObstacle: Phaser.GameObjects.Zone | null = null;
  private room204ProjectionOverlay: Phaser.GameObjects.Container | null = null;
  private room204ObstacleGroup: Phaser.Physics.Arcade.StaticGroup | null = null;
  private room204ObstacleCollider: Phaser.Physics.Arcade.Collider | null = null;
  private room204SelectedPieceId: ChapterFourRoom204PieceId | null = null;
  private room204CarryGhost: Phaser.GameObjects.Sprite | null = null;
  private nearbyRoom204PieceId: ChapterFourRoom204PieceId | null = null;
  private evidenceDetailObjects: Phaser.GameObjects.GameObject[] = [];
  private evidenceDetailTweens: Phaser.Tweens.Tween[] = [];
  private evidenceDetailSignature = "";
  private evidenceDetailPhase: GameState["chapter4"]["phase"] | null = null;
  private visualHintModel: ChapterFourVisualHintModel = createChapterFourVisualHintModel();
  private requestSerial = 0;
  private floorCaption!: Phaser.GameObjects.Text;
  private interactionHint!: Phaser.GameObjects.Text;
  private feedbackText!: Phaser.GameObjects.Text;
  private warmupStatusText!: Phaser.GameObjects.Text;
  private feedbackTimer: Phaser.Time.TimerEvent | null = null;
  private projection!: ChapterFourMazeProjection;
  private projectionSignature = "";
  private pendingProjectionSignature = "";
  private projectionRetryFailures = 0;
  private projectionRetryNotBeforeMs = 0;
  private appliedChapterMode: GameState["chapter4"]["mode"] = "light";
  private appliedLightMask = 0;
  private appliedLightLocked = false;
  private appliedPlateSignature = "";
  private appliedPlateIds: Readonly<Record<StoryFloor, ChapterFour755PlateId>> = Object.freeze({
    A1: "a1_base", A2: "a2_base", A3: "a3_base"
  });
  private appliedCollisionIds: string[] = [];
  private appliedCollisionRects: CollisionRect[] = [];
  private appliedOcclusionIds: string[] = [];
  private renderedTargetIds: string[] = [];
  private persistentContractFailures = new Set<string>();
  private plateContractFailures = new Set<string>();
  private spatialAttestationLast: {
    requestId: string;
    attestationId: string;
    targetId: string;
    result: "responded" | "rejected";
    reason: string | null;
  } | null = null;
  private frameRegistration!: ChapterFour755FrameRegistrationReport;
  private preloadedWarmupPhase: ChapterFourWarmupPhase = "entry";
  private loadedWarmupPhases = new Set<ChapterFourWarmupPhase>();
  private phaseLoadPromises = new Map<ChapterFourWarmupPhase, Promise<boolean>>();
  private phaseLoadFailures = new Map<ChapterFourWarmupPhase, readonly string[]>();
  private phaseLoadRetryNotBeforeMs = new Map<ChapterFourWarmupPhase, number>();
  private phaseLoadCancelled = false;
  private warmupLoadGeneration = 0;
  private scheduledWarmupTimer: Phaser.Time.TimerEvent | null = null;
  private pendingWarmupSettlers = new Set<() => void>();
  private retryWarmupKey!: Phaser.Input.Keyboard.Key;

  constructor() { super("chapter-four-temporal-maze") }

  /**
   * Phaser reuses the same Scene instance after stop/start. Game objects from the
   * previous run are destroyed by Scene shutdown, but class-field references are
   * not reset automatically. Clear every restart-sensitive cache before create()
   * rebuilds the active Chapter 4 projection.
   */
  private resetRestartLifecycleState(): void {
    this.platePlayerCollider = null;
    this.backgrounds.clear();
    this.elevatorVisuals.clear();
    this.appliedForegrounds = [];
    this.targetVisuals.clear();
    this.insertedPuzzleProps.clear();
    this.darkRealityVisuals = null;
    this.lightRealityVisuals = null;
    this.renderedRealityMode = null;
    this.debugOverlayObjects = [];
    this.plateColliderDebugObjects = [];

    this.virtualDirection = { x: 0, y: 0 };
    this.interactionRequested = false;
    this.nearbyTravelTarget = null;
    this.nearbyTravelTargetHasPriority = false;
    this.nearbyStoryTarget = null;
    this.nearbyAlumniFigure = null;
    this.nearbyLandmark = null;
    this.destroyEvidenceDetailRuntime();
    this.visualHintModel = clearAllChapterFourVisualHints();
    this.evidenceDetailPhase = null;

    this.floorPanel = null;
    this.floorPanelMode = "floors";
    this.floorPanelSelection = 1;
    this.elevatorReplayStartSeconds = CHAPTER_FOUR_ELEVATOR.selectableStartMinSeconds;
    this.elevatorCalibrationGraphics = null;
    this.elevatorCalibrationReadout = null;
    this.elevatorCalibrationFailed = false;
    this.floorPanelButtons = [];
    this.floorPanelTitle = null;
    this.floorPanelDescription = null;
    this.floorPanelEvidence = null;
    this.floorPanelProgress = null;
    this.floorPanelPrimaryButton = null;
    this.floorPanelPrimaryLabel = null;
    this.floorPanelDeductionButton = null;
    this.floorPanelDeductionLabel = null;
    this.elevatorDeductionArrivalFloor = "A2";
    this.elevatorDeductionUnservedFloor = "A3";
    this.elevatorDeductionFeedback = "";
    this.elevatorDeductionGraphics = null;
    this.elevatorDeductionReadout = null;

    this.alumniPanel = null;
    this.alumniPanelFigure = null;
    this.alumniWallObjects = [];

    this.elevatorPhase = "idle";
    this.elevatorTargetFloor = null;
    this.elevatorDoorProgress = 0;
    this.pendingMove = null;
    this.pendingMoveTimer = null;
    this.pendingStoryRequest = null;
    this.storyPresentation = "idle";
    this.storyPresentationTimers = [];
    this.storyRetryNotBeforeMs = 0;
    this.lastPublishedStoryInputLock = false;
    this.lastPublishedStoryPointerAllowed = false;
    this.lastPublishedStoryKeyboardAllowed = false;
    this.liveReadySignature = "";
    this.openingPaperSprite = null;
    this.hallClockStateSprite = null;
    this.externalTimeOverlay = null;
    this.frontDeskAttendant = null;
    this.supportNpcSprites.clear();
    this.lastPhaseSignature = "";
    this.requestSerial = 0;
    this.feedbackTimer = null;

    this.projectionSignature = "";
    this.pendingProjectionSignature = "";
    this.projectionRetryFailures = 0;
    this.projectionRetryNotBeforeMs = 0;
    this.appliedPlateSignature = "";
    this.appliedPlateIds = Object.freeze({
      A1: "a1_base", A2: "a2_base", A3: "a3_base"
    });
    this.appliedCollisionIds = [];
    this.appliedCollisionRects = [];
    this.appliedOcclusionIds = [];
    this.renderedTargetIds = [];
    this.persistentContractFailures.clear();
    this.plateContractFailures.clear();
    this.spatialAttestationLast = null;
  }

  preload(): void {
    const bridge = this.registry.get("rpgBridge") as RpgBridge | undefined;
    this.preloadedWarmupPhase = bridge
      ? chapterFourWarmupPhaseForState(bridge.getState())
      : "entry";
    for (const asset of getChapterFourWarmupAssetsThroughPhase(this.preloadedWarmupPhase)) {
      queueChapterFourWarmupAsset(this, asset);
    }
    preloadRpgPlayerTextures(this);
  }

  create(): void {
    this.resetRestartLifecycleState();
    this.warmupLoadGeneration += 1;
    this.phaseLoadCancelled = false;
    for (const settle of [...this.pendingWarmupSettlers]) settle();
    this.pendingWarmupSettlers.clear();
    this.phaseLoadPromises.clear();
    this.phaseLoadFailures.clear();
    this.phaseLoadRetryNotBeforeMs.clear();
    this.loadedWarmupPhases.clear();
    const preloadedPhaseIndex = CHAPTER_FOUR_WARMUP_PHASES.indexOf(this.preloadedWarmupPhase);
    const preloadedPhases = CHAPTER_FOUR_WARMUP_PHASES.slice(0, preloadedPhaseIndex + 1);
    const readiness = inspectChapterFourWarmupPhaseReadiness(
      preloadedPhases,
      (key) => this.textures.exists(key)
    );
    readiness.readyPhases.forEach((phase) => this.loadedWarmupPhases.add(phase));
    for (const phase of preloadedPhases) {
      const missingKeys = new Set(readiness.missingByPhase[phase]);
      if (missingKeys.size === 0) continue;
      const missingUrls = getChapterFourWarmupPhaseAssets(phase)
        .filter((asset) => missingKeys.has(asset.key))
        .map((asset) => asset.url.startsWith("data:") ? `inline:${asset.key}` : asset.url);
      this.phaseLoadFailures.set(phase, Object.freeze(missingUrls));
    }
    this.bridge = this.registry.get("rpgBridge") as RpgBridge;
    const state = this.bridge.getState();
    this.handoffReleased = state.chapter4.prologueSeen
      && state.chapter4.phase !== "opening_handoff";
    this.currentFloor = displayFloorFor(state.chapter4.floor) ?? 1;
    this.projection = createBaseAppliedProjection(
      selectChapterFourMazeProjection(state),
      getFloor(this.currentFloor).storyFloor
    );
    this.appliedChapterMode = state.chapter4.mode;
    this.appliedLightMask = state.chapter4.lightGrid.mask;
    this.appliedLightLocked = state.chapter4.lightGrid.locked;
    this.refreshLoadedChapterFourAssets();
    this.cameras.main.setBackgroundColor(0x07111d).setRoundPixels(true);
    this.createBaseBackgrounds();
    this.createInsertedPuzzleProps();
    this.createAlumniHonorWallPortraits();
    this.physics.world.setBounds(0, 0, WORLD.width, WORLD.height);
    this.createCollisionGroups();
    this.createElevatorVisuals();

    ensureRpgPlayerTextures(this);
    const initialFloor = getFloor(this.currentFloor);
    const initialSpawn = state.chapter4.phase === "final_chase"
      ? { ...FINAL_CHASE_RUNTIME.playerStart, facing: "down" as const }
      : state.rpgCheckpoint === "c4_a2_room202"
        ? { ...FINAL_MINUTE_RUNTIME.recoveryPlayerSpawn, facing: "up" as const }
        : state.rpgCheckpoint === "c4_a1_main_elevator"
          ? initialFloor.elevator.standPosition
          : initialFloor.safeSpawn;
    this.player = this.physics.add.sprite(
      initialFloor.offsetX + initialSpawn.x,
      initialSpawn.y,
      `act1-player-${initialSpawn.facing ?? "down"}-0`
    ).setCollideWorldBounds(true);
    configureRpgPlayerSprite(this.player);
    this.player.setDepth(PLAYER_TOP_DEPTH);
    this.animator = new RpgPlayerAnimator(this.player, initialSpawn.facing ?? "down");
    this.physics.add.collider(this.player, this.staticObstacles);
    this.platePlayerCollider = this.physics.add.collider(this.player, this.plateObstacles);

    this.cursors = this.input.keyboard!.createCursorKeys();
    this.keys = this.input.keyboard!.addKeys("W,A,S,D") as Record<"W" | "A" | "S" | "D", Phaser.Input.Keyboard.Key>;
    this.interactKey = this.input.keyboard!.addKey(Phaser.Input.Keyboard.KeyCodes.SPACE);
    this.confirmKey = this.input.keyboard!.addKey(Phaser.Input.Keyboard.KeyCodes.ENTER);
    this.escapeKey = this.input.keyboard!.addKey(Phaser.Input.Keyboard.KeyCodes.ESC);
    this.retryWarmupKey = this.input.keyboard!.addKey(Phaser.Input.Keyboard.KeyCodes.R);
    this.floorKeys = {
      1: this.input.keyboard!.addKey(Phaser.Input.Keyboard.KeyCodes.ONE),
      2: this.input.keyboard!.addKey(Phaser.Input.Keyboard.KeyCodes.TWO),
      3: this.input.keyboard!.addKey(Phaser.Input.Keyboard.KeyCodes.THREE)
    };
    this.createHud();
    this.createRealityModeVisuals(state.chapter4.mode);
    this.configureCameraForCurrentFloor();
    this.syncProjection(true);
    this.refreshProximity();
    this.bindBridgeEvents();
    const checkpoint = state.rpgCheckpoint.startsWith("c4_")
      ? state.rpgCheckpoint
      : this.projection.safeCheckpoint;
    this.bridge.setRpgLocation("duan_yongping_temporal_maze", checkpoint);
    this.bridge.emit("rpg_booted", {
      scene: "duan_yongping_temporal_maze",
      checkpoint,
      stitchedFloors: FLOORS.length,
      layoutSchemaVersion: LAYOUT.schemaVersion
    });
    this.publishDebug();
  }

  update(_time: number, delta: number): void {
    this.syncProjection();
    if (Phaser.Input.Keyboard.JustDown(this.retryWarmupKey)) this.retryRequiredWarmupPhase();
    this.syncWarmupStatus();
    const warmupReady = this.isWarmupPhaseLoaded(
      chapterFourWarmupPhaseForState(this.bridge.getState())
    );
    if (warmupReady) {
      this.syncExternalFloorWhenIdle();
      this.syncPhaseSideEffects();
      this.syncOpeningPresentation();
      this.syncBakeryPresentation();
      this.updateBakeryCrowdEndpointActions();
      this.syncRoom204ProjectionPresentation();
      this.maybeEmitBakeryApproachCue();
      this.updateMaintenanceGuard(delta);
      this.updateFinalChaseRuntime(delta);
    }
    this.syncStoryInputLock();
    this.syncMainEntranceForegroundDepth();
    if (this.alumniPanel) {
      this.player.setVelocity(0, 0);
      this.animator.update(new Phaser.Math.Vector2(), this.time.now);
      this.updateRoom204CarryGhost();
      this.updateAlumniPanelKeyboard();
      this.interactionRequested = false;
      this.publishDebug();
      return;
    }
    if (this.isStoryInputLocked()) {
      this.player.setVelocity(0, 0);
      this.animator.update(new Phaser.Math.Vector2(), this.time.now);
      this.updateRoom204CarryGhost();
      this.interactionRequested = false;
      this.publishDebug();
      return;
    }
    if (this.hostPowerPanelOpen || this.finalClockDragActive) {
      this.player.setVelocity(0, 0);
      this.animator.update(new Phaser.Math.Vector2(), this.time.now);
      this.updateRoom204CarryGhost();
      this.interactionRequested = false;
      this.publishDebug();
      return;
    }
    if (this.floorPanel) {
      this.player.setVelocity(0, 0);
      this.animator.update(new Phaser.Math.Vector2(), this.time.now);
      this.updateRoom204CarryGhost();
      this.updateFloorPanelKeyboard();
      this.interactionRequested = false;
      this.publishDebug();
      return;
    }
    if (this.elevatorPhase !== "idle") {
      this.player.setVelocity(0, 0);
      this.animator.update(new Phaser.Math.Vector2(), this.time.now);
      this.updateRoom204CarryGhost();
      this.interactionRequested = false;
      this.publishDebug();
      return;
    }
    const movement = new Phaser.Math.Vector2(
      Number(this.cursors.right.isDown || this.keys.D.isDown)
        - Number(this.cursors.left.isDown || this.keys.A.isDown) + this.virtualDirection.x,
      Number(this.cursors.down.isDown || this.keys.S.isDown)
        - Number(this.cursors.up.isDown || this.keys.W.isDown) + this.virtualDirection.y
    );
    const movementSpeed = this.bridge.getState().chapter4.phase === "final_chase"
      ? CHAPTER_FOUR_FINAL_CHASE_RULES.playerSpeed
      : PLAYER_SPEED;
    if (movement.lengthSq() > 0) movement.normalize().scale(movementSpeed);
    this.player.setVelocity(movement.x, movement.y).setDepth(PLAYER_TOP_DEPTH);
    this.animator.update(movement, this.time.now);
    this.updateRoom204CarryGhost();
    this.refreshProximity();
    if (Phaser.Input.Keyboard.JustDown(this.interactKey) || this.interactionRequested) {
      this.handleStoryOrTravelInteraction();
    }
    this.interactionRequested = false;
    this.publishDebug();
  }

  private syncMainEntranceForegroundDepth(): void {
    const entrance = this.appliedForegrounds.find(
      (visual) => visual.id === MAIN_ENTRANCE_FOREGROUND_ID
    );
    if (!entrance) return;
    const playerBody = this.player.body as Phaser.Physics.Arcade.Body | undefined;
    const playerFootY = playerBody?.bottom ?? this.player.y;
    const playerBehindDoor = this.currentFloor === entrance.floor
      && playerFootY < entrance.baselineY;
    const nextDepth = playerBehindDoor
      ? MAIN_ENTRANCE_OCCLUSION_DEPTH
      : PLAYER_DEPTH_BASE + entrance.baselineY;
    if (entrance.image.depth !== nextDepth) entrance.image.setDepth(nextDepth);
  }

  private bindBridgeEvents(): void {
    this.events.on(Phaser.Scenes.Events.RESUME, this.handleSceneResume, this);
    subscribeRpgSceneBridge(this.events, this.bridge, (event) => {
      if (event.name === "rpg_chapter4_755_intent_resolved") {
        this.handleIntentResolved(event.payload);
      } else if (event.name === "rpg_chapter4_755_handoff_released") {
        this.handoffReleased = true;
        this.syncOpeningPresentation();
      } else if (event.name === "rpg_chapter4_755_live_ready_retry_requested") {
        const requestId = typeof event.payload?.requestId === "string"
          ? event.payload.requestId
          : undefined;
        const requiredPhase = chapterFourWarmupPhaseForState(this.bridge.getState());
        if (!this.isWarmupPhaseLoaded(requiredPhase)) {
          this.retryRequiredWarmupPhase();
        } else {
          this.publishLiveReady(true, requestId);
        }
      } else if (event.name === "rpg_inventory_drop_requested") {
        this.handleInventoryDrop(event.payload);
      } else if (event.name === "rpg_chapter4_power_panel_open_state_changed") {
        this.hostPowerPanelOpen = event.payload?.open === true;
        this.hostPowerPanelSession = this.hostPowerPanelOpen
          && typeof event.payload?.openRequestId === "string"
          && typeof event.payload?.targetId === "string"
          ? {
              openRequestId: event.payload.openRequestId,
              targetId: event.payload.targetId
            }
          : null;
        if (this.hostPowerPanelOpen) {
          this.player.setVelocity(0, 0);
          this.virtualDirection = { x: 0, y: 0 };
        }
      } else if (event.name === "rpg_chapter4_power_panel_attempt_abandoned") {
        if (this.bridge.getState().chapter4.phase === "blackout_light_grid") {
          this.recordVisualHintFailure("power_route_comparison");
        }
      } else if (event.name === "rpg_chapter4_755_spatial_attestation_requested") {
        this.handleSpatialAttestationRequest(event.payload);
      } else if (event.name === "rpg_chapter4_755_spatial_attestation_failed") {
        this.spatialAttestationLast = {
          requestId: String(event.payload?.requestId ?? ""),
          attestationId: String(event.payload?.attestationId ?? ""),
          targetId: String(event.payload?.targetId ?? ""),
          result: "rejected",
          reason: String(event.payload?.reason ?? "unknown")
        };
      } else if (event.name === "rpg_direction_changed") {
        const x = Number(event.payload?.x) || 0;
        const y = Number(event.payload?.y) || 0;
        if (this.floorPanel) {
          if (x !== 0 || y !== 0) {
            const delta = x > 0 || y > 0 ? 1 : -1;
            if (this.floorPanelMode === "elevator_calibration") this.shiftElevatorReplayStart(delta);
            else if (this.floorPanelMode === "elevator_route_deduction") {
              if (x !== 0) this.shiftElevatorDeductionArrival();
              if (y !== 0) this.shiftElevatorDeductionUnserved();
            }
            else this.shiftFloorPanelSelection(delta);
          }
          this.virtualDirection = { x: 0, y: 0 };
        } else {
          this.virtualDirection = this.elevatorPhase === "idle"
            && !this.isStoryInputLocked()
            && !this.hostPowerPanelOpen
              ? { x, y }
              : { x: 0, y: 0 };
        }
      } else if (event.name === "rpg_interact") {
        if (this.alumniPanel) {
          this.closeAlumniPanel();
        } else if (this.floorPanel) {
          if (this.floorPanelMode === "elevator_calibration") this.submitElevatorCalibration();
          else if (this.floorPanelMode === "elevator_route_deduction") this.submitElevatorStopChain();
          else this.activateFloorPanelPrimary();
        }
        else if (!this.isStoryInputLocked() && !this.hostPowerPanelOpen) this.interactionRequested = true;
      }
    }, () => {
      this.events.off(Phaser.Scenes.Events.RESUME, this.handleSceneResume, this);
      this.warmupLoadGeneration += 1;
      this.phaseLoadCancelled = true;
      for (const settle of [...this.pendingWarmupSettlers]) settle();
      this.scheduledWarmupTimer?.remove(false);
      this.scheduledWarmupTimer = null;
      this.pendingMoveTimer?.remove(false);
      this.pendingStoryRequest?.timer.remove(false);
      this.pendingStoryRequest = null;
      this.clearStoryPresentationTimers();
      this.destroyBakeryRuntime("scene_shutdown");
      this.destroyBakeryCounterStaff();
      this.destroyRoom204Runtime("scene_shutdown");
      this.destroyEvidenceDetailRuntime();
      this.visualHintModel = clearAllChapterFourVisualHints();
      this.destroyPhaseRuntime("scene_shutdown");
      this.destroyTask11Runtime("scene_shutdown");
      this.destroyTask12Runtime("scene_shutdown");
      this.destroyRealityModeVisuals();
      this.destroyExternalTimeOverlay();
      this.closeFloorPanel();
      this.closeAlumniPanel();
      this.hostPowerPanelOpen = false;
      this.hostPowerPanelSession = null;
      this.storyPresentation = "idle";
      this.syncStoryInputLock(true);
      this.feedbackTimer?.remove(false);
      this.clearProjectedTargetVisuals();
      this.destroyInsertedPuzzleProps();
      this.resetRestartLifecycleState();
      clearRpgRuntimeDebugState();
    });
  }

  private handleSceneResume(): void {
    const requiredPhase = chapterFourWarmupPhaseForState(this.bridge.getState());
    if (!this.isWarmupPhaseLoaded(requiredPhase)) {
      this.requestWarmupPhase(requiredPhase, "required");
      return;
    }
    this.createBaseBackgrounds();
    this.createInsertedPuzzleProps();
    this.syncProjection(true);
    this.syncExternalFloorWhenIdle();
    this.refreshProximity();
  }

  private refreshLoadedChapterFourAssets(): void {
    this.frameRegistration = registerChapterFour755ManifestFrames(this);
    this.validateFrameRegistrationReport(this.frameRegistration);
    ensureFinaleNpcAnimations(this);
    this.refreshSupportNpcAnimations();
    this.ensureBakeryBakerAnimation();
    this.ensureFrontDeskStaffAnimation();
    this.createBaseBackgrounds();
    this.createInsertedPuzzleProps();
    this.createAlumniHonorWallPortraits();
  }

  private isWarmupPhaseLoaded(phase: ChapterFourWarmupPhase): boolean {
    const targetIndex = CHAPTER_FOUR_WARMUP_PHASES.indexOf(phase);
    for (const candidate of CHAPTER_FOUR_WARMUP_PHASES.slice(0, targetIndex + 1)) {
      if (this.loadedWarmupPhases.has(candidate)) continue;
      const assetsReady = getChapterFourWarmupPhaseAssets(candidate)
        .every((asset) => this.textures.exists(asset.key));
      if (!assetsReady) return false;
      this.loadedWarmupPhases.add(candidate);
      this.phaseLoadFailures.delete(candidate);
      this.phaseLoadRetryNotBeforeMs.delete(candidate);
    }
    return true;
  }

  private scheduleNextWarmupPhase(currentPhase: ChapterFourWarmupPhase): void {
    const nextPhase = getNextChapterFourWarmupPhase(currentPhase);
    if (!nextPhase) return;
    this.scheduleWarmupPhase(nextPhase);
  }

  private scheduleWarmupPhase(phase: ChapterFourWarmupPhase): void {
    if (this.isWarmupPhaseLoaded(phase)) return;
    if (this.phaseLoadPromises.has(phase) || this.scheduledWarmupTimer) return;
    this.scheduledWarmupTimer = this.time.delayedCall(90, () => {
      this.scheduledWarmupTimer = null;
      this.requestWarmupPhase(phase, "speculative");
    });
  }

  private requestWarmupPhase(
    phase: ChapterFourWarmupPhase,
    priority: ChapterFourWarmupPriority
  ): void {
    if (this.phaseLoadCancelled || this.isWarmupPhaseLoaded(phase)) return;
    const targetIndex = CHAPTER_FOUR_WARMUP_PHASES.indexOf(phase);
    const phases = CHAPTER_FOUR_WARMUP_PHASES.slice(0, targetIndex + 1);
    if (phases.some((candidate) => this.phaseLoadPromises.has(candidate))) return;
    const blocker = selectChapterFourWarmupRetryBlocker(
      phases,
      (candidate) => this.isWarmupPhaseLoaded(candidate),
      this.phaseLoadRetryNotBeforeMs,
      this.time.now
    );
    if (blocker && blocker.retryAfterMs > 0) return;
    void this.ensureWarmupPhaseLoaded(phase, priority);
  }

  private async ensureWarmupPhaseLoaded(
    targetPhase: ChapterFourWarmupPhase,
    priority: ChapterFourWarmupPriority
  ): Promise<boolean> {
    this.safeBridgeEmit("rpg_chapter4_warmup_phase_requested", {
      phase: targetPhase,
      priority
    });
    const targetIndex = CHAPTER_FOUR_WARMUP_PHASES.indexOf(targetPhase);
    for (const phase of CHAPTER_FOUR_WARMUP_PHASES.slice(0, targetIndex + 1)) {
      if (this.isWarmupPhaseLoaded(phase)) continue;
      const loaded = await this.loadWarmupPhase(phase, priority);
      if (!loaded) return false;
    }
    return true;
  }

  private loadWarmupPhase(
    phase: ChapterFourWarmupPhase,
    priority: ChapterFourWarmupPriority
  ): Promise<boolean> {
    if (this.isWarmupPhaseLoaded(phase)) return Promise.resolve(true);
    const existing = this.phaseLoadPromises.get(phase);
    if (existing) return existing;
    const loadGeneration = this.warmupLoadGeneration;
    let needsSpeculativeContinuation = false;
    const promise = (async () => {
      const phaseAssets = getChapterFourWarmupPhaseAssets(phase);
      const result = await runChapterFourWarmupAssetBatch({
        assets: phaseAssets,
        priority,
        constraints: this.warmupConstraints(),
        isCancelled: () => this.phaseLoadCancelled,
        isLoaded: (asset) => this.textures.exists(asset.key),
        waitForIdle: () => this.waitForWarmupIdleSlice(),
        loadAsset: (asset) => this.loadWarmupAsset(asset)
      });
      if (result.cancelled || this.phaseLoadCancelled) return false;
      if (result.failedUrls.length > 0) {
        const failedDetails = result.failedUrls.map((url) => {
          const asset = phaseAssets.find((candidate) => candidate.url === url);
          return url.startsWith("data:") ? `inline:${asset?.key ?? "unknown"}` : url;
        });
        const retryNotBeforeMs = this.time.now + 1_500;
        this.phaseLoadFailures.set(phase, Object.freeze(failedDetails));
        this.phaseLoadRetryNotBeforeMs.set(phase, retryNotBeforeMs);
        this.safeBridgeEmit("rpg_chapter4_warmup_phase_failed", {
          phase,
          phaseLabel: CHAPTER_FOUR_WARMUP_PHASE_LABELS[phase],
          failedUrls: failedDetails,
          retryNotBeforeMs
        });
        this.syncWarmupStatus();
        return false;
      }
      if (result.limited) {
        needsSpeculativeContinuation = true;
        return false;
      }
      if (!result.ready) return false;
      this.loadedWarmupPhases.add(phase);
      this.phaseLoadFailures.delete(phase);
      this.phaseLoadRetryNotBeforeMs.delete(phase);
      this.syncWarmupStatus();
      this.refreshLoadedChapterFourAssets();
      const statePhase = chapterFourWarmupPhaseForState(this.bridge.getState());
      if (this.isWarmupPhaseLoaded(statePhase)) this.syncProjection(true);
      return true;
    })().finally(() => {
      if (this.phaseLoadPromises.get(phase) === promise) this.phaseLoadPromises.delete(phase);
      if (needsSpeculativeContinuation
        && loadGeneration === this.warmupLoadGeneration
        && !this.phaseLoadCancelled) {
        this.scheduleWarmupPhase(phase);
      }
    });
    this.phaseLoadPromises.set(phase, promise);
    return promise;
  }

  private loadWarmupAsset(asset: ChapterFourWarmupAsset): Promise<boolean> {
    if (this.textures.exists(asset.key)) return Promise.resolve(true);
    return new Promise<boolean>((resolve) => {
      const completeEvent = Phaser.Loader.Events.COMPLETE;
      let settled = false;
      const settle = (loaded: boolean) => {
        if (settled) return;
        settled = true;
        this.load.off(completeEvent, onComplete);
        this.pendingWarmupSettlers.delete(cancel);
        resolve(loaded);
      };
      const onComplete = () => settle(this.textures.exists(asset.key));
      const cancel = () => settle(false);
      this.pendingWarmupSettlers.add(cancel);
      try {
        if (!queueChapterFourWarmupAsset(this, asset)) {
          settle(true);
          return;
        }
        this.load.once(completeEvent, onComplete);
        this.load.start();
      } catch {
        settle(false);
      }
    });
  }

  private warmupConstraints(): { constrainedNetwork: boolean; lowMemory: boolean } {
    const runtimeNavigator = navigator as Navigator & {
      connection?: { saveData?: boolean; effectiveType?: string };
      deviceMemory?: number;
    };
    const effectiveType = runtimeNavigator.connection?.effectiveType;
    return {
      constrainedNetwork: runtimeNavigator.connection?.saveData === true
        || effectiveType === "slow-2g"
        || effectiveType === "2g",
      lowMemory: typeof runtimeNavigator.deviceMemory === "number"
        && runtimeNavigator.deviceMemory > 0
        && runtimeNavigator.deviceMemory <= 4
    };
  }

  private waitForWarmupIdleSlice(): Promise<boolean> {
    if (this.phaseLoadCancelled) return Promise.resolve(false);
    const idleWindow = window as Window & {
      requestIdleCallback?: (callback: () => void, options?: { timeout: number }) => number;
      cancelIdleCallback?: (handle: number) => void;
    };
    return new Promise<boolean>((resolve) => {
      let settled = false;
      let idleHandle: number | null = null;
      let timeoutHandle: number | null = null;
      const settle = (ready: boolean) => {
        if (settled) return;
        settled = true;
        if (idleHandle !== null) idleWindow.cancelIdleCallback?.(idleHandle);
        if (timeoutHandle !== null) window.clearTimeout(timeoutHandle);
        this.pendingWarmupSettlers.delete(cancel);
        resolve(ready && !this.phaseLoadCancelled);
      };
      const cancel = () => settle(false);
      this.pendingWarmupSettlers.add(cancel);
      if (idleWindow.requestIdleCallback) {
        idleHandle = idleWindow.requestIdleCallback(() => settle(true), { timeout: 800 });
      } else {
        timeoutHandle = window.setTimeout(() => settle(true), 32);
      }
    });
  }

  private validateFrameRegistrationReport(report: ChapterFour755FrameRegistrationReport): void {
    for (const failure of report.contractFailures) this.persistentContractFailures.add(failure);
    const allSpritesheetsLoaded = Object.values(CHAPTER_FOUR_755_SPRITESHEETS)
      .every((sheet) => this.textures.exists(sheet.id));
    if (CHAPTER_FOUR_755_MANIFEST_FRAME_COUNT !== EXPECTED_MANIFEST_ENTRY_COUNT) {
      this.persistentContractFailures.add(
        `manifest_source_frame_count:${CHAPTER_FOUR_755_MANIFEST_FRAME_COUNT}/${EXPECTED_MANIFEST_ENTRY_COUNT}`
      );
    }
    if (allSpritesheetsLoaded && report.manifestFrameCount !== EXPECTED_MANIFEST_ENTRY_COUNT) {
      this.persistentContractFailures.add(
        `manifest_frame_count:${report.manifestFrameCount}/${EXPECTED_MANIFEST_ENTRY_COUNT}`
      );
    }
    if (allSpritesheetsLoaded && report.skippedEmptyFrameCount !== EXPECTED_EMPTY_FRAME_COUNT) {
      this.persistentContractFailures.add(
        `manifest_empty_frame_count:${report.skippedEmptyFrameCount}/${EXPECTED_EMPTY_FRAME_COUNT}`
      );
    }
    if (report.registeredFrameCount + report.reusedFrameCount + report.skippedEmptyFrameCount
      !== report.manifestFrameCount) {
      this.persistentContractFailures.add("manifest_frame_registration_incomplete");
    }
  }

  private createBaseBackgrounds(): void {
    for (const floor of FLOORS) {
      const plateId = basePlateFor(floor.storyFloor);
      const existing = this.backgrounds.get(floor.displayFloor);
      if (existing?.active) continue;
      this.backgrounds.delete(floor.displayFloor);
      if (!this.textures.exists(plateId)) continue;
      this.backgrounds.set(
        floor.displayFloor,
        this.add.image(floor.offsetX, 0, plateId).setOrigin(0).setDepth(0)
      );
      this.textures.get(plateId).setFilter(Phaser.Textures.FilterMode.NEAREST);
    }
  }

  private createInsertedPuzzleProps(): void {
    for (const asset of CHAPTER_FOUR_INSERTED_PUZZLE_ASSETS) {
      const existing = this.insertedPuzzleProps.get(asset.puzzleId);
      if (existing?.active || !this.textures.exists(asset.textureKey)) continue;
      const displayFloor = displayFloorFor(asset.floor);
      if (!displayFloor) continue;
      const floor = getFloor(displayFloor);
      this.textures.get(asset.textureKey).setFilter(Phaser.Textures.FilterMode.NEAREST);
      const displaySize = "displaySize" in asset ? asset.displaySize : asset.sourceSize;
      const image = this.add.image(
        floor.offsetX + asset.center.x,
        asset.center.y,
        asset.textureKey
      ).setDisplaySize(
        displaySize.width,
        displaySize.height
      )
        .setDepth(asset.depth);
      this.insertedPuzzleProps.set(asset.puzzleId, image);
    }
    this.syncInsertedPuzzlePropPresentation(this.bridge?.getState().chapter4.mode ?? this.appliedChapterMode);
  }

  private syncInsertedPuzzlePropPresentation(mode: GameState["chapter4"]["mode"]): void {
    for (const image of this.insertedPuzzleProps.values()) {
      if (!image.active) continue;
      if (mode === "dark") {
        image.setTint(0x64d9ff).setAlpha(0.78);
      } else {
        image.clearTint().setAlpha(1);
      }
    }
  }

  private destroyInsertedPuzzleProps(): void {
    for (const image of this.insertedPuzzleProps.values()) image.destroy();
    this.insertedPuzzleProps.clear();
  }

  private createAlumniHonorWallPortraits(): void {
    if (this.alumniWallObjects.some((object) => object.active)) return;
    if (CHAPTER_FOUR_ALUMNI_HONOR_WALL.some(
      (figure) => !this.textures.exists(figure.portraitTextureKey)
    )) return;
    for (const figure of CHAPTER_FOUR_ALUMNI_HONOR_WALL) {
      const floor = getFloor(figure.floor);
      const wallDisplayDepth = CHAPTER_FOUR_PLAYER_DEPTH_BASE + (figure.floor === 1 ? 160 : 840);
      this.textures.get(figure.portraitTextureKey).setFilter(Phaser.Textures.FilterMode.NEAREST);
      if ("drawRuntimeFrame" in figure && figure.drawRuntimeFrame) {
        const frame = this.add.rectangle(
          floor.offsetX + rectCenterX(figure.frameBounds),
          rectCenterY(figure.frameBounds),
          figure.frameBounds.width,
          figure.frameBounds.height,
          0x281f18,
          1
        ).setStrokeStyle(3, 0xb8964d, 1).setDepth(wallDisplayDepth);
        this.alumniWallObjects.push(frame);
      }
      const matte = this.add.rectangle(
        floor.offsetX + rectCenterX(figure.imageBounds),
        rectCenterY(figure.imageBounds),
        figure.imageBounds.width,
        figure.imageBounds.height,
        0x17191d,
        1
      ).setDepth(wallDisplayDepth + 1);
      const portrait = this.add.image(
        floor.offsetX + rectCenterX(figure.imageBounds),
        rectCenterY(figure.imageBounds),
        figure.portraitTextureKey
      ).setDisplaySize(figure.imageBounds.width, figure.imageBounds.height)
        .setDepth(wallDisplayDepth + 2);
      const hitTarget = this.add.zone(
        floor.offsetX + rectCenterX(figure.frameBounds),
        rectCenterY(figure.frameBounds),
        Math.max(52, figure.frameBounds.width),
        Math.max(68, figure.frameBounds.height)
      ).setDepth(wallDisplayDepth + 3).setInteractive({ useHandCursor: true });
      hitTarget.on("pointerover", () => {
        if (this.currentFloor === figure.floor && !this.isStoryInputLocked()) {
          portrait.setTint(0xffe8a3);
        }
      });
      hitTarget.on("pointerout", () => portrait.clearTint());
      hitTarget.on("pointerdown", () => {
        portrait.clearTint();
        if (this.currentFloor !== figure.floor || this.isStoryInputLocked()) return;
        this.openAlumniPanel(figure.targetId);
      });
      this.alumniWallObjects.push(matte, portrait, hitTarget);
    }
  }

  private openAlumniPanel(targetId: string): void {
    const figure = getChapterFourAlumniFigureByTargetId(targetId);
    if (!figure) {
      this.showRuntimeInteractionFailure(`unknown_alumni_target:${targetId}`);
      return;
    }
    this.closeAlumniPanel();
    this.alumniPanelFigure = figure;
    this.alumniPanel = this.add.container(0, 0).setScrollFactor(0).setDepth(10040);
    this.redrawAlumniPanel();
    this.syncStoryInputLock(true);
  }

  private closeAlumniPanel(): void {
    this.alumniPanel?.destroy(true);
    this.alumniPanel = null;
    this.alumniPanelFigure = null;
    this.syncStoryInputLock(true);
  }

  private redrawAlumniPanel(): void {
    const panel = this.alumniPanel;
    const figure = this.alumniPanelFigure;
    if (!panel || !figure) return;
    panel.removeAll(true);
    const backdrop = this.add.rectangle(480, 270, 960, 540, 0x02060b, 0.78)
      .setScrollFactor(0)
      .setInteractive();
    const card = this.add.rectangle(480, 286, 760, 420, 0x101b2b, 0.98)
      .setStrokeStyle(3, 0xe9c34b, 1);
    const title = this.add.text(145, 96, `${figure.name}  ${figure.years}`, {
      fontFamily: "'Fusion Pixel', 'Courier New', monospace",
      fontSize: "28px",
      color: "#f6d45a"
    });
    const role = this.add.text(145, 134, figure.role, {
      fontFamily: "'Fusion Pixel', 'Courier New', monospace",
      fontSize: "16px",
      color: "#8fe8ff",
      wordWrap: { width: 650, useAdvancedWrap: true }
    });
    const portraitMatte = this.add.rectangle(248, 294, 160, 244, 0x1b1d22, 1)
      .setStrokeStyle(3, 0xb8964d, 1);
    const portrait = this.add.image(248, 294, figure.portraitTextureKey).setDisplaySize(150, 232);
    const source = this.add.text(352, 428, `资料依据：${figure.sourceLabel}`, {
      fontFamily: "'Fusion Pixel', 'Courier New', monospace",
      fontSize: "13px",
      color: "#9ba9b8",
      wordWrap: { width: 430, useAdvancedWrap: true }
    });
    const close = this.add.text(835, 96, "×", {
      fontFamily: "'Fusion Pixel', 'Courier New', monospace",
      fontSize: "30px",
      color: "#f7f1dc"
    }).setOrigin(0.5).setScrollFactor(0).setInteractive({ useHandCursor: true });
    close.on("pointerdown", () => this.closeAlumniPanel());
    panel.add([backdrop, card, title, role, portraitMatte, portrait, source, close]);

    panel.add(this.add.text(352, 184, figure.biography.map((line) => `• ${line}`).join("\n\n"), {
      fontFamily: "'Fusion Pixel', 'Courier New', monospace",
      fontSize: "16px",
      color: "#f7f1dc",
      lineSpacing: 6,
      wordWrap: { width: 445, useAdvancedWrap: true }
    }));
    const actionButton = this.add.rectangle(730, 470, 190, 42, 0x315e7c, 1)
      .setStrokeStyle(2, 0xf6d45a, 1)
      .setScrollFactor(0)
      .setInteractive({ useHandCursor: true });
    actionButton.on("pointerdown", () => this.closeAlumniPanel());
    panel.add([
      this.add.text(352, 470, "Space / Enter · 返回    Esc · 返回", {
        fontFamily: "'Fusion Pixel', 'Courier New', monospace",
        fontSize: "14px",
        color: "#9ba9b8"
      }).setOrigin(0, 0.5),
      actionButton,
      this.add.text(730, 470, "返回地图", {
        fontFamily: "'Fusion Pixel', 'Courier New', monospace",
        fontSize: "16px",
        color: "#fff4bb"
      }).setOrigin(0.5)
    ]);
  }

  private updateAlumniPanelKeyboard(): void {
    if (Phaser.Input.Keyboard.JustDown(this.escapeKey)) {
      this.closeAlumniPanel();
      return;
    }
    if (Phaser.Input.Keyboard.JustDown(this.confirmKey)
      || Phaser.Input.Keyboard.JustDown(this.interactKey)) this.closeAlumniPanel();
  }

  private createCollisionGroups(): void {
    this.staticObstacles = this.physics.add.staticGroup();
    this.plateObstacles = this.physics.add.staticGroup();
    const staticRects: CollisionRect[] = [];
    for (const floor of FLOORS) {
      for (const local of floor.staticCollisions) {
        const rect = {
          ...offsetRect(local, floor.offsetX),
          id: `floor_${floor.displayFloor}_${local.id}`,
          sourceAnnotationId: local.sourceAnnotationId
        };
        staticRects.push(rect);
        this.addPhysicsRect(this.staticObstacles, rect, "static");
      }
    }
    this.appliedCollisionRects = staticRects;
    this.appliedCollisionIds = staticRects.map((rect) => rect.id);
  }

  private addPhysicsRect(
    group: Phaser.Physics.Arcade.StaticGroup,
    rect: CollisionRect,
    kind: "static" | "plate",
    plateDebugObjects: Phaser.GameObjects.Rectangle[] = this.plateColliderDebugObjects,
    debugVisible = true
  ): void {
    const showDebug = import.meta.env.DEV
      && new URLSearchParams(window.location.search).get("debugColliders") === "1";
    const obstacle = this.add.zone(
      rectCenterX(rect), rectCenterY(rect), rect.width, rect.height
    );
    try {
      this.physics.add.existing(obstacle, true);
      group.add(obstacle);
      if (showDebug) {
        const overlay = this.add.rectangle(
          rectCenterX(rect), rectCenterY(rect), rect.width, rect.height,
          kind === "static" ? 0xff315b : 0xffb347, 0.2
        ).setDepth(9997).setVisible(debugVisible);
        if (kind === "plate") plateDebugObjects.push(overlay);
      }
    } catch (error) {
      obstacle.destroy();
      throw error;
    }
  }

  private createHud(): void {
    const style: Phaser.Types.GameObjects.Text.TextStyle = {
      fontFamily: RPG_PIXEL_FONT_FAMILY,
      color: "#f7f1dc", fontSize: "17px", stroke: "#07111d", strokeThickness: 1
    };
    this.floorCaption = this.add.text(24, 58, "", style).setScrollFactor(0).setDepth(10000);
    this.interactionHint = this.add.text(480, 500, "", {
      ...style, fontSize: "16px", align: "center"
    }).setOrigin(0.5).setScrollFactor(0).setDepth(10000).setVisible(false);
    this.feedbackText = this.add.text(480, 458, "", {
      ...style, color: "#8fe8ff", fontSize: "16px", align: "center"
    }).setOrigin(0.5).setScrollFactor(0).setDepth(10000).setVisible(false);
    this.warmupStatusText = this.add.text(480, 430, "", {
      ...style, color: "#ffd86b", fontSize: "14px", align: "center"
    }).setOrigin(0.5).setScrollFactor(0).setDepth(10000).setVisible(false)
      .setInteractive({ useHandCursor: true });
    this.warmupStatusText.on("pointerdown", () => this.retryRequiredWarmupPhase());
    this.syncWarmupStatus();
  }

  private createRealityModeVisuals(initialMode: GameState["chapter4"]["mode"]): void {
    this.destroyRealityModeVisuals();

    // Match Chapter 3's uninterrupted full-scene wash. Screen-space line
    // geometry aliases at responsive scales and can appear as a horizontal seam.
    this.darkRealityVisuals = this.add.container(0, 0, [
      this.add.rectangle(480, 270, 960, 540, 0x071127, 0.56)
    ]).setScrollFactor(0).setDepth(REALITY_MODE_ATMOSPHERE_DEPTH);

    this.lightRealityVisuals = this.add.container(0, 0, [
      this.add.rectangle(480, 270, 960, 540, 0xffe2a6, 0.07)
    ]).setScrollFactor(0).setDepth(REALITY_MODE_ATMOSPHERE_DEPTH);

    this.renderedRealityMode = null;
    this.syncRealityModeVisuals(initialMode, true);
  }

  private syncRealityModeVisuals(
    mode: GameState["chapter4"]["mode"],
    immediate = false
  ): void {
    if (!this.darkRealityVisuals || !this.lightRealityVisuals) return;
    if (!immediate && mode === this.renderedRealityMode) return;

    const darkAlpha = mode === "dark" ? 1 : 0;
    const lightAlpha = mode === "light" ? 1 : 0;
    this.tweens.killTweensOf(this.darkRealityVisuals);
    this.tweens.killTweensOf(this.lightRealityVisuals);
    if (immediate) {
      this.darkRealityVisuals.setAlpha(darkAlpha);
      this.lightRealityVisuals.setAlpha(lightAlpha);
    } else {
      this.tweens.add({
        targets: this.darkRealityVisuals,
        alpha: darkAlpha,
        duration: REALITY_MODE_TRANSITION_MS,
        ease: "Sine.easeOut"
      });
      this.tweens.add({
        targets: this.lightRealityVisuals,
        alpha: lightAlpha,
        duration: REALITY_MODE_TRANSITION_MS,
        ease: "Sine.easeOut"
      });
    }
    this.renderedRealityMode = mode;
  }

  private destroyRealityModeVisuals(): void {
    if (this.darkRealityVisuals) this.tweens.killTweensOf(this.darkRealityVisuals);
    if (this.lightRealityVisuals) this.tweens.killTweensOf(this.lightRealityVisuals);
    this.darkRealityVisuals?.destroy(true);
    this.lightRealityVisuals?.destroy(true);
    this.darkRealityVisuals = null;
    this.lightRealityVisuals = null;
    this.renderedRealityMode = null;
  }

  private retryRequiredWarmupPhase(): void {
    if (this.phaseLoadCancelled) return;
    const requiredPhase = chapterFourWarmupPhaseForState(this.bridge.getState());
    const requiredIndex = CHAPTER_FOUR_WARMUP_PHASES.indexOf(requiredPhase);
    for (const phase of CHAPTER_FOUR_WARMUP_PHASES.slice(0, requiredIndex + 1)) {
      if (this.isWarmupPhaseLoaded(phase)) continue;
      this.phaseLoadRetryNotBeforeMs.delete(phase);
    }
    this.requestWarmupPhase(requiredPhase, "required");
    this.syncWarmupStatus();
  }

  private syncWarmupStatus(): void {
    if (!this.warmupStatusText) return;
    const requiredPhase = chapterFourWarmupPhaseForState(this.bridge.getState());
    const requiredIndex = CHAPTER_FOUR_WARMUP_PHASES.indexOf(requiredPhase);
    const phases = CHAPTER_FOUR_WARMUP_PHASES.slice(0, requiredIndex + 1);
    const failedPhase = phases.find((phase) => (this.phaseLoadFailures.get(phase)?.length ?? 0) > 0);
    if (!failedPhase || this.isWarmupPhaseLoaded(requiredPhase)) {
      this.warmupStatusText.setVisible(false);
      return;
    }
    const failedCount = this.phaseLoadFailures.get(failedPhase)?.length ?? 0;
    this.warmupStatusText
      .setText(`${CHAPTER_FOUR_WARMUP_PHASE_LABELS[failedPhase]}资源准备失败（${failedCount} 项）· R 重试`)
      .setVisible(true);
  }

  private syncProjection(force = false): void {
    const state = this.bridge.getState();
    const requiredWarmupPhase = chapterFourWarmupPhaseForState(state);
    if (!this.isWarmupPhaseLoaded(requiredWarmupPhase)) {
      this.requestWarmupPhase(requiredWarmupPhase, "required");
      return;
    }
    this.createBaseBackgrounds();
    const next = selectChapterFourMazeProjection(state);
    const signature = JSON.stringify({
      phase: next.phase,
      timeState: next.timeState,
      activePlateIds: next.activePlateIds,
      availableTargetIds: next.availableTargetIds,
      dynamicCollisionIds: next.dynamicCollisionIds,
      occlusionIds: next.occlusionIds,
      safeCheckpoint: next.safeCheckpoint,
      mode: state.chapter4.mode,
      lightMask: state.chapter4.lightGrid.mask,
      lightLocked: state.chapter4.lightGrid.locked
    });
    if (signature !== this.pendingProjectionSignature) {
      this.pendingProjectionSignature = signature;
      this.projectionRetryFailures = 0;
      this.projectionRetryNotBeforeMs = 0;
    }
    if (!force && signature === this.projectionSignature) {
      this.syncRealityModeVisuals(state.chapter4.mode);
      this.syncInsertedPuzzlePropPresentation(state.chapter4.mode);
      this.syncBakeryRuntime(state, next);
      this.syncRoom204Runtime(state);
      this.syncPhaseRuntime(state);
      this.syncEvidenceDetailRuntime(state, next);
      return;
    }
    if (!force && this.time.now < this.projectionRetryNotBeforeMs) return;

    const applied = this.applyAtomicPlateGroup(next);
    if (!applied) {
      this.projectionRetryFailures = Math.min(this.projectionRetryFailures + 1, 32);
      this.projectionRetryNotBeforeMs = this.time.now
        + chapterFourPlateRetryDelayMs(this.projectionRetryFailures);
      return;
    }

    this.projection = next;
    this.projectionSignature = signature;
    this.appliedChapterMode = state.chapter4.mode;
    this.appliedLightMask = state.chapter4.lightGrid.mask;
    this.appliedLightLocked = state.chapter4.lightGrid.locked;
    this.syncRealityModeVisuals(state.chapter4.mode, force);
    this.syncInsertedPuzzlePropPresentation(state.chapter4.mode);
    this.projectionRetryFailures = 0;
    this.projectionRetryNotBeforeMs = 0;
    this.syncBakeryRuntime(state, next);
    this.syncRoom204Runtime(state);
    this.syncPhaseRuntime(state);
    this.syncEvidenceDetailRuntime(state, next);
    this.refreshProjectedTargetVisuals();
    this.refreshProximity();
    this.publishLiveReady();
    this.scheduleNextWarmupPhase(requiredWarmupPhase);
  }

  private syncEvidenceDetailRuntime(
    state: GameState,
    projection: ChapterFourMazeProjection
  ): void {
    if (this.evidenceDetailPhase !== state.chapter4.phase) {
      this.visualHintModel = clearAllChapterFourVisualHints();
      this.evidenceDetailPhase = state.chapter4.phase;
    }
    const hintSignature = Object.values(this.visualHintModel.sessions)
      .filter((session): session is NonNullable<typeof session> => Boolean(session))
      .map((session) => `${session.puzzleId}:${session.failureCount}:${session.level}`)
      .sort();
    const signature = JSON.stringify({
      phase: state.chapter4.phase,
      facts: state.chapter4.factIds,
      plates: projection.activePlateIds,
      hints: hintSignature
    });
    if (signature === this.evidenceDetailSignature) return;
    this.destroyEvidenceDetailRuntime();
    this.evidenceDetailSignature = signature;

    for (const detail of LAYOUT.evidenceDetails) {
      const placements = [detail.source, ...detail.echoes];
      for (const placement of placements) {
        if (!placement.phaseIds.includes(state.chapter4.phase)) continue;
        if (placement.statePlateIds
          && !placement.statePlateIds.some((plateId) => projection.activePlateIds.includes(plateId))) {
          continue;
        }
        if (placement.requiredFacts
          && !placement.requiredFacts.every((factId) => hasChapterFourFact(state, factId))) {
          continue;
        }
        this.createEvidenceDetailMark(detail, placement);
      }
    }
  }

  private createEvidenceDetailMark(
    detail: EvidenceDetailContract,
    placement: EvidenceDetailPlacement
  ): void {
    const floor = getFloor(displayFloorFor(placement.storyFloor) ?? 1);
    const bounds = placement.bounds;
    const color = Phaser.Display.Color.HexStringToColor(detail.color).color;
    const hint = selectChapterFourVisualHintForDetail(this.visualHintModel, detail.id);
    const emphasized = hint.level >= 3 ? hint.paired : hint.emphasized;
    const alpha = emphasized ? 0.88 : 0.34;
    const lineWidth = emphasized ? 3 : 1;
    const graphics = this.add.graphics()
      .setPosition(floor.offsetX, 0)
      .setDepth(PLAYER_TOP_DEPTH - 60)
      .setAlpha(alpha);
    graphics.lineStyle(lineWidth, color, 0.92);
    if (detail.visual === "wet_trace" || detail.visual === "wear" || detail.visual === "strip") {
      graphics.lineBetween(bounds.x, bounds.y + bounds.height / 2, bounds.x + bounds.width, bounds.y + bounds.height / 2);
    } else if (detail.visual === "digits" && detail.glyph) {
      const text = this.add.text(
        floor.offsetX + bounds.x,
        bounds.y,
        detail.glyph,
        {
          fontFamily: RPG_PIXEL_FONT_FAMILY,
          fontSize: `${Math.max(7, Math.min(12, bounds.height))}px`,
          color: detail.color
        }
      ).setDepth(PLAYER_TOP_DEPTH - 60).setAlpha(alpha);
      this.evidenceDetailObjects.push(text);
    } else if (detail.visual === "node" || detail.visual === "gear") {
      graphics.strokeCircle(
        bounds.x + bounds.width / 2,
        bounds.y + bounds.height / 2,
        Math.max(3, Math.min(bounds.width, bounds.height) / 2)
      );
    } else {
      graphics.strokeRect(bounds.x, bounds.y, bounds.width, bounds.height);
    }
    this.evidenceDetailObjects.push(graphics);
    if (hint.level >= 2 && emphasized) {
      this.evidenceDetailTweens.push(this.tweens.add({
        targets: graphics,
        alpha: { from: alpha, to: Math.max(0.28, alpha * 0.42) },
        duration: 520,
        yoyo: true,
        repeat: -1,
        ease: "Sine.InOut"
      }));
    }
  }

  private recordVisualHintFailure(
    puzzleId: ChapterFourVisualHintPuzzleId
  ): void {
    const before = selectChapterFourVisualHintSession(this.visualHintModel, puzzleId);
    this.visualHintModel = recordChapterFourVisualHintFailure(this.visualHintModel, puzzleId);
    const after = selectChapterFourVisualHintSession(this.visualHintModel, puzzleId);
    if (after?.positionalAudio && !before?.positionalAudio) {
      const state = this.bridge.getState();
      const sourceDetail = LAYOUT.evidenceDetails.find((detail) =>
        after.emphasizedDetailIds.includes(detail.id)
      );
      const sourcePlacement = sourceDetail
        ? [sourceDetail.source, ...sourceDetail.echoes].find((placement) =>
          placement.phaseIds.includes(state.chapter4.phase)
            && (!placement.requiredFacts
              || placement.requiredFacts.every((factId) => hasChapterFourFact(state, factId)))
        )
        : undefined;
      const sourceFloor = sourcePlacement
        ? getFloor(displayFloorFor(sourcePlacement.storyFloor) ?? 1)
        : null;
      const sourceWorldX = sourcePlacement && sourceFloor
        ? sourceFloor.offsetX + sourcePlacement.bounds.x + sourcePlacement.bounds.width / 2
        : this.player.x;
      this.bridge.emit("chapter4_environment_hint_pulse", {
        puzzleId,
        failureCount: after.failureCount,
        hintLevel: after.level,
        detailIds: after.pairedEmphasis ? after.pairedDetailIds : after.emphasizedDetailIds,
        sourceWorldX,
        sourceWorldY: sourcePlacement
          ? sourcePlacement.bounds.y + sourcePlacement.bounds.height / 2
          : this.player.y,
        playerWorldX: this.player.x,
        pan: Phaser.Math.Clamp((sourceWorldX - this.player.x) / 480, -1, 1)
      });
    }
    this.evidenceDetailSignature = "";
    this.syncEvidenceDetailRuntime(this.bridge.getState(), this.projection);
  }

  private clearVisualHintForIntent(intentType: string, targetId?: string): void {
    const puzzleId = selectChapterFourVisualHintPuzzleForIntent(intentType, targetId);
    if (!puzzleId) return;
    this.visualHintModel = clearChapterFourVisualHintPuzzle(this.visualHintModel, puzzleId);
    this.evidenceDetailSignature = "";
  }

  private destroyEvidenceDetailRuntime(): void {
    for (const tween of this.evidenceDetailTweens) tween.remove();
    for (const object of this.evidenceDetailObjects) object.destroy();
    this.evidenceDetailTweens = [];
    this.evidenceDetailObjects = [];
    this.evidenceDetailSignature = "";
  }

  private publishLiveReady(force = false, requestId?: string): void {
    const state = this.bridge.getState();
    if (!state.chapter4.prologueSeen || this.projection.phase !== "opening_handoff") return;
    const projectedTargetIds = this.resolveProjectedTargets().map((target) => target.contract.id).sort();
    const renderedTargetIds = [...this.renderedTargetIds].sort();
    const desired = desiredPlateGroup(this.projection);
    const task7TargetContractIds = [...TASK7_LIVE_READY_TARGET_IDS].sort();
    const task7TargetsReady = task7TargetContractIds.every((targetId) => {
      const target = CHAPTER_FOUR_755_INTERACTION_TARGETS[
        targetId as keyof typeof CHAPTER_FOUR_755_INTERACTION_TARGETS
      ];
      return Boolean(target?.bounds && rectInsideFloor(target.bounds));
    });
    const contractReady = this.appliedPlateSignature.length > 0
      && this.appliedPlateIds.A1 === "a1_2245_opening"
      && (Object.keys(desired) as StoryFloor[]).every((floor) => (
        desired[floor] === this.appliedPlateIds[floor]
      ))
      && JSON.stringify(projectedTargetIds) === JSON.stringify(renderedTargetIds)
      && this.appliedCollisionIds.length > 0
      && this.appliedOcclusionIds.length > 0
      && task7TargetsReady;
    if (!contractReady) return;
    const signature = JSON.stringify({
      phase: this.projection.phase,
      appliedPlateSignature: this.appliedPlateSignature,
      projectedTargetIds,
      renderedTargetIds
    });
    if (!force && signature === this.liveReadySignature) return;
    this.liveReadySignature = signature;
    this.bridge.emit("rpg_chapter4_755_live_ready", {
      phase: this.projection.phase,
      appliedPlateId: this.appliedPlateIds.A1,
      appliedPlateSignature: this.appliedPlateSignature,
      projectedTargetIds,
      renderedTargetIds,
      task7TargetContractIds,
      contractReady,
      ...(requestId ? { requestId } : {})
    });
  }

  private applyAtomicPlateGroup(projection: ChapterFourMazeProjection): boolean {
    const desired = desiredPlateGroup(projection);
    const attemptSignature = JSON.stringify({ desired, dynamicCollisionIds: projection.dynamicCollisionIds });
    this.plateContractFailures.clear();
    const prepared = this.preparePlateGroup(desired, projection, attemptSignature);
    if (!prepared) return false;

    let stagedForegrounds: AppliedForeground[];
    try {
      stagedForegrounds = this.stagePlateForegrounds(prepared.foregrounds);
    } catch (error) {
      this.plateContractFailures.add(
        `plate_group_foreground_stage_failed:${errorMessage(error)}`
      );
      return false;
    }

    let stagedCollision: Omit<StagedPlateApplication, "foregrounds">;
    try {
      stagedCollision = this.stagePlateCollision(prepared.colliders);
    } catch (error) {
      this.destroyForegrounds(stagedForegrounds, "collision_stage_rollback");
      this.plateContractFailures.add(
        `plate_group_collision_stage_failed:${errorMessage(error)}`
      );
      return false;
    }

    const staged: StagedPlateApplication = {
      foregrounds: stagedForegrounds,
      ...stagedCollision
    };
    let backgroundSnapshots: BackgroundTextureSnapshot[];
    try {
      backgroundSnapshots = this.snapshotBackgroundTextures();
    } catch (error) {
      this.disposeStagedPlateApplication(staged, "background_snapshot_rollback");
      this.plateContractFailures.add(
        `plate_group_background_snapshot_failed:${errorMessage(error)}`
      );
      return false;
    }

    try {
      prepared.preparedStoryFloors.forEach((storyFloor, index) => {
        const floor = FLOORS.find((candidate) => candidate.storyFloor === storyFloor);
        if (!floor) throw new Error(`floor_missing:${storyFloor}`);
        const plateId = prepared.plateIds[floor.storyFloor];
        const background = this.backgrounds.get(floor.displayFloor);
        if (!background) throw new Error(`background_missing:${floor.displayFloor}`);
        this.injectPlateTransactionFault({
          point: "background_set_texture",
          index,
          floor: floor.displayFloor,
          id: plateId
        });
        background.setTexture(plateId);
        this.textures.get(plateId).setFilter(Phaser.Textures.FilterMode.NEAREST);
      });
    } catch (error) {
      this.restoreBackgroundTextures(backgroundSnapshots, "background_commit_rollback");
      this.disposeStagedPlateApplication(staged, "background_commit_rollback");
      this.plateContractFailures.add(
        `plate_group_background_commit_failed:${errorMessage(error)}`
      );
      return false;
    }

    const previous = {
      foregrounds: this.appliedForegrounds,
      obstacles: this.plateObstacles,
      playerCollider: this.platePlayerCollider,
      colliderDebugObjects: this.plateColliderDebugObjects
    };
    try {
      this.injectPlateTransactionFault({ point: "activation", step: "activate_new" });
      for (const visual of staged.foregrounds) visual.image.setVisible(true);
      for (const object of staged.colliderDebugObjects) object.setVisible(true);
      staged.playerCollider.active = true;
      this.injectPlateTransactionFault({ point: "activation", step: "deactivate_old" });
      if (previous.playerCollider) previous.playerCollider.active = false;
      for (const visual of previous.foregrounds) visual.image.setVisible(false);
      for (const object of previous.colliderDebugObjects) object.setVisible(false);
    } catch (error) {
      this.attemptPlateRollback("old_collider_active", () => {
        if (previous.playerCollider) previous.playerCollider.active = true;
      });
      previous.foregrounds.forEach((visual) => {
        this.attemptPlateRollback(`old_foreground_visible:${visual.id}`, () => {
          visual.image.setVisible(true);
        });
      });
      previous.colliderDebugObjects.forEach((object, index) => {
        this.attemptPlateRollback(`old_collider_debug_visible:${index}`, () => {
          object.setVisible(true);
        });
      });
      this.attemptPlateRollback("new_collider_inactive", () => {
        staged.playerCollider.active = false;
      });
      staged.foregrounds.forEach((visual) => {
        this.attemptPlateRollback(`new_foreground_hidden:${visual.id}`, () => {
          visual.image.setVisible(false);
        });
      });
      staged.colliderDebugObjects.forEach((object, index) => {
        this.attemptPlateRollback(`new_collider_debug_hidden:${index}`, () => {
          object.setVisible(false);
        });
      });
      this.restoreBackgroundTextures(backgroundSnapshots, "activation_rollback");
      this.disposeStagedPlateApplication(staged, "activation_rollback");
      this.plateContractFailures.add(
        `plate_group_activation_failed:${errorMessage(error)}`
      );
      return false;
    }

    // No render or physics step can occur inside this synchronous switch. New
    // resources now own the scene; cleanup failures are isolated below.
    this.appliedForegrounds = staged.foregrounds;
    this.plateObstacles = staged.obstacles;
    this.platePlayerCollider = staged.playerCollider;
    this.plateColliderDebugObjects = staged.colliderDebugObjects;
    if (this.chaseGuard?.active) {
      this.chaseGuardPlateCollider?.destroy();
      this.chaseGuardPlateCollider = this.physics.add.collider(this.chaseGuard, this.plateObstacles);
    }

    const staticRects = FLOORS.flatMap((floor) => floor.staticCollisions.map((local) => ({
      ...offsetRect(local, floor.offsetX),
      id: `floor_${floor.displayFloor}_${local.id}`,
      sourceAnnotationId: local.sourceAnnotationId
    })));
    this.appliedPlateSignature = prepared.signature;
    this.appliedPlateIds = Object.freeze({
      ...this.appliedPlateIds,
      ...Object.fromEntries(prepared.preparedStoryFloors.map((storyFloor) => (
        [storyFloor, prepared.plateIds[storyFloor]]
      )))
    }) as Readonly<Record<StoryFloor, ChapterFour755PlateId>>;
    this.appliedCollisionRects = [...staticRects, ...prepared.colliders];
    this.appliedCollisionIds = this.appliedCollisionRects.map((rect) => rect.id);
    this.appliedOcclusionIds = staged.foregrounds.map((visual) => visual.id);
    for (const failure of prepared.deferredFailures) this.plateContractFailures.add(failure);
    this.disposePreviousPlateApplication(previous);
    try {
      this.rebuildDevelopmentOverlays();
    } catch (error) {
      this.plateContractFailures.add(`plate_group_debug_rebuild_failed:${errorMessage(error)}`);
    }
    return true;
  }

  private stagePlateForegrounds(definitions: readonly PreparedForeground[]): AppliedForeground[] {
    const staged: AppliedForeground[] = [];
    try {
      definitions.forEach((definition, index) => {
        this.injectPlateTransactionFault({
          point: "foreground_stage",
          index,
          floor: definition.floor,
          id: definition.id
        });
        const image = this.add.image(
          getFloor(definition.floor).offsetX, 0, definition.plateId
        );
        const visual: AppliedForeground = {
          id: definition.id,
          floor: definition.floor,
          sourceAnnotationId: definition.sourceAnnotationId,
          maskBounds: definition.worldBounds,
          baselineY: definition.baselineY,
          renderMode: "foot_behind_baseline",
          image
        };
        staged.push(visual);
        image.setOrigin(0)
          .setCrop(
            definition.localBounds.x, definition.localBounds.y,
            definition.localBounds.width, definition.localBounds.height
          )
          .setDepth(PLAYER_DEPTH_BASE + definition.baselineY)
          .setVisible(false);
      });
      if (staged.length !== definitions.length) {
        throw new Error(`foreground_stage_count:${staged.length}/${definitions.length}`);
      }
      staged.forEach((visual, index) => {
        const definition = definitions[index];
        if (visual.image.visible
          || !visual.image.isCropped
          || visual.image.texture.key !== definition.plateId
          || visual.image.depth !== PLAYER_DEPTH_BASE + definition.baselineY) {
          throw new Error(`foreground_stage_invalid:${definition.id}`);
        }
      });
      return staged;
    } catch (error) {
      this.destroyForegrounds(staged, "foreground_stage_rollback");
      throw error;
    }
  }

  private stagePlateCollision(
    colliders: readonly CollisionRect[]
  ): Omit<StagedPlateApplication, "foregrounds"> {
    let obstacles: Phaser.Physics.Arcade.StaticGroup | null = null;
    let playerCollider: Phaser.Physics.Arcade.Collider | null = null;
    const colliderDebugObjects: Phaser.GameObjects.Rectangle[] = [];
    try {
      obstacles = this.physics.add.staticGroup();
      colliders.forEach((rect, index) => {
        this.injectPlateTransactionFault({
          point: "collision_stage",
          step: "body",
          index,
          id: rect.id
        });
        this.addPhysicsRect(obstacles!, rect, "plate", colliderDebugObjects, false);
      });
      this.injectPlateTransactionFault({
        point: "collision_stage",
        step: "player_collider"
      });
      playerCollider = this.physics.add.collider(this.player, obstacles);
      playerCollider.active = false;
      const children = obstacles.getChildren();
      if (children.length !== colliders.length || playerCollider.active) {
        throw new Error(`collision_stage_count:${children.length}/${colliders.length}`);
      }
      children.forEach((child, index) => {
        const zone = child as Phaser.GameObjects.Zone & {
          body: Phaser.Physics.Arcade.StaticBody | null;
        };
        const expected = colliders[index];
        if (!zone.body
          || zone.x !== rectCenterX(expected)
          || zone.y !== rectCenterY(expected)
          || zone.body.width !== expected.width
          || zone.body.height !== expected.height) {
          throw new Error(`collision_stage_invalid:${expected.id}`);
        }
      });
      return { obstacles, playerCollider, colliderDebugObjects };
    } catch (error) {
      if (playerCollider) this.destroyCollider(playerCollider, "collision_stage_rollback");
      if (obstacles) this.destroyObstacleGroup(obstacles, "collision_stage_rollback");
      this.destroyGameObjects(colliderDebugObjects, "collision_stage_rollback_debug");
      throw error;
    }
  }

  private snapshotBackgroundTextures(): BackgroundTextureSnapshot[] {
    return FLOORS.flatMap((floor) => {
      const image = this.backgrounds.get(floor.displayFloor);
      if (!image) return [];
      return [{
        floor: floor.displayFloor,
        image,
        textureKey: image.texture.key,
        frameName: image.frame.name
      }];
    });
  }

  private restoreBackgroundTextures(
    snapshots: readonly BackgroundTextureSnapshot[],
    phase: string
  ): void {
    for (const snapshot of [...snapshots].reverse()) {
      try {
        snapshot.image.setTexture(snapshot.textureKey, snapshot.frameName);
      } catch (error) {
        this.plateContractFailures.add(
          `plate_group_rollback_failed:${phase}:floor_${snapshot.floor}:${errorMessage(error)}`
        );
      }
    }
  }

  private attemptPlateRollback(label: string, action: () => void): void {
    try {
      action();
    } catch (error) {
      this.plateContractFailures.add(
        `plate_group_rollback_failed:${label}:${errorMessage(error)}`
      );
    }
  }

  private disposeStagedPlateApplication(stage: StagedPlateApplication, phase: string): void {
    stage.playerCollider.active = false;
    this.destroyCollider(stage.playerCollider, phase);
    this.destroyObstacleGroup(stage.obstacles, phase);
    this.destroyForegrounds(stage.foregrounds, phase);
    this.destroyGameObjects(stage.colliderDebugObjects, `${phase}_debug`);
  }

  private disposePreviousPlateApplication(previous: {
    foregrounds: readonly AppliedForeground[];
    obstacles: Phaser.Physics.Arcade.StaticGroup;
    playerCollider: Phaser.Physics.Arcade.Collider | null;
    colliderDebugObjects: readonly Phaser.GameObjects.Rectangle[];
  }): void {
    if (previous.playerCollider) this.destroyCollider(previous.playerCollider, "previous_commit_cleanup");
    this.destroyObstacleGroup(previous.obstacles, "previous_commit_cleanup");
    this.destroyForegrounds(previous.foregrounds, "previous_commit_cleanup");
    this.destroyGameObjects(previous.colliderDebugObjects, "previous_commit_cleanup_debug");
  }

  private destroyCollider(collider: Phaser.Physics.Arcade.Collider, phase: string): void {
    try {
      collider.active = false;
      collider.destroy();
    } catch (error) {
      this.plateContractFailures.add(
        `plate_group_cleanup_failed:${phase}:collider:${errorMessage(error)}`
      );
    }
  }

  private destroyObstacleGroup(
    group: Phaser.Physics.Arcade.StaticGroup,
    phase: string
  ): void {
    try {
      group.destroy(true, true);
    } catch (error) {
      this.plateContractFailures.add(
        `plate_group_cleanup_failed:${phase}:obstacles:${errorMessage(error)}`
      );
    }
  }

  private destroyForegrounds(foregrounds: readonly AppliedForeground[], phase: string): void {
    for (const visual of foregrounds) {
      try {
        visual.image.destroy();
      } catch (error) {
        this.plateContractFailures.add(
          `plate_group_cleanup_failed:${phase}:foreground:${visual.id}:${errorMessage(error)}`
        );
      }
    }
  }

  private destroyGameObjects(
    objects: readonly Phaser.GameObjects.GameObject[],
    phase: string
  ): void {
    for (const object of objects) {
      try {
        object.destroy();
      } catch (error) {
        this.plateContractFailures.add(
          `plate_group_cleanup_failed:${phase}:debug:${errorMessage(error)}`
        );
      }
    }
  }

  private injectPlateTransactionFault(context: ChapterFourPlateTransactionFaultContext): void {
    if (!import.meta.env.DEV) return;
    const injector = this.registry.get(CHAPTER_FOUR_PLATE_TRANSACTION_FAULT_INJECTOR_KEY);
    if (typeof injector === "function") {
      (injector as (value: ChapterFourPlateTransactionFaultContext) => void)(context);
    }
  }

  private preparePlateGroup(
    plateIds: Readonly<Record<StoryFloor, ChapterFour755PlateId>>,
    projection: ChapterFourMazeProjection,
    signature: string
  ): PreparedPlateGroup | null {
    const fatal: string[] = [];
    const deferredFailures: string[] = [];
    const colliders: CollisionRect[] = [];
    const foregrounds: PreparedForeground[] = [];
    const preparedStoryFloors: StoryFloor[] = [];
    const committedDisplayFloor = displayFloorFor(this.bridge.getState().chapter4.floor);
    for (const floor of FLOORS) {
      const plateId = plateIds[floor.storyFloor];
      const asset = CHAPTER_FOUR_755_PLATES[plateId];
      if (!asset) {
        fatal.push(`plate_missing:${floor.storyFloor}:${plateId}`);
        continue;
      }
      if (!this.textures.exists(plateId)) {
        if (floor.displayFloor === this.currentFloor
          || floor.displayFloor === committedDisplayFloor) {
          fatal.push(`plate_missing:${floor.storyFloor}:${plateId}`);
        }
        continue;
      }
      preparedStoryFloors.push(floor.storyFloor);
      const source = this.textures.get(plateId).getSourceImage() as { width?: number; height?: number };
      if (asset.sourceSize.width !== FLOOR_SIZE.width || asset.sourceSize.height !== FLOOR_SIZE.height
        || source.width !== FLOOR_SIZE.width || source.height !== FLOOR_SIZE.height) {
        fatal.push(`plate_size:${plateId}:${String(source.width)}x${String(source.height)}`);
        continue;
      }
      for (const definition of floor.foregroundOcclusions) {
        if (!rectInsideFloor(definition.maskBounds)
          || !Number.isFinite(definition.baselineY)
          || definition.renderMode !== "foot_behind_baseline") {
          fatal.push(`foreground_geometry:${definition.id}`);
          continue;
        }
        foregrounds.push({
          id: `floor_${floor.displayFloor}_${definition.id}`,
          floor: floor.displayFloor,
          sourceAnnotationId: definition.sourceAnnotationId,
          worldBounds: offsetRect(definition.maskBounds, floor.offsetX),
          localBounds: { ...definition.maskBounds },
          baselineY: definition.baselineY,
          plateId
        });
      }
    }

    for (const delta of LAYOUT.physicalDeltas) {
      if (!preparedStoryFloors.includes(delta.storyFloor)) continue;
      const displayFloor = displayFloorFor(delta.storyFloor);
      if (!displayFloor) {
        fatal.push(`physical_delta_floor:${delta.id}`);
        continue;
      }
      const floor = getFloor(displayFloor);
      if (!delta.statePlateIds.includes(plateIds[delta.storyFloor])) continue;
      if (delta.activation === "runtime_furniture_visible") {
        if (projection.dynamicCollisionIds.includes(delta.id)
          && delta.id !== "a2_room202_recovery_barrier") {
          deferredFailures.push(`dynamic_collision_pending:${delta.id}`);
        }
        if (!delta.collisionSource || !delta.worldRoomBounds || !rectInsideFloor(delta.worldRoomBounds)) {
          fatal.push(`physical_delta_runtime_contract:${delta.id}`);
        }
        continue;
      }
      if (delta.activation !== "plate_active") {
        fatal.push(`physical_delta_activation:${delta.id}`);
        continue;
      }
      for (const local of delta.collisionBounds ?? []) {
        if (!rectInsideFloor(local)) {
          fatal.push(`physical_delta_collision:${delta.id}:${local.id}`);
          continue;
        }
        colliders.push({
          ...offsetRect(local, floor.offsetX),
          id: `floor_${displayFloor}_${local.id}`,
          sourceAnnotationId: local.sourceAnnotationId
        });
      }
      for (const definition of delta.occlusionBounds ?? []) {
        if (!rectInsideFloor(definition.maskBounds)
          || !Number.isFinite(definition.baselineY)
          || definition.renderMode !== "foot_behind_baseline") {
          fatal.push(`physical_delta_occlusion:${delta.id}:${definition.id}`);
          continue;
        }
        foregrounds.push({
          id: `floor_${displayFloor}_${definition.id}`,
          floor: displayFloor,
          sourceAnnotationId: definition.sourceAnnotationId,
          worldBounds: offsetRect(definition.maskBounds, floor.offsetX),
          localBounds: { ...definition.maskBounds },
          baselineY: definition.baselineY,
          plateId: plateIds[delta.storyFloor]
        });
      }
    }

    const physicalDeltaIds = new Set(LAYOUT.physicalDeltas.map((delta) => delta.id));
    for (const projectedId of projection.dynamicCollisionIds) {
      if (!physicalDeltaIds.has(projectedId)
        && !RUNTIME_MANAGED_DYNAMIC_COLLISION_IDS.has(projectedId)) {
        deferredFailures.push(`dynamic_collision_unresolved:${projectedId}`);
      }
    }
    if (fatal.length > 0) {
      for (const failure of fatal) this.plateContractFailures.add(failure);
      this.plateContractFailures.add(`plate_group_rejected:${signature}`);
      return null;
    }
    return {
      signature,
      plateIds,
      preparedStoryFloors,
      colliders,
      foregrounds,
      deferredFailures
    };
  }

  private rebuildDevelopmentOverlays(): void {
    for (const object of this.debugOverlayObjects) object.destroy();
    this.debugOverlayObjects = [];
    const showOcclusions = import.meta.env.DEV
      && new URLSearchParams(window.location.search).get("debugOcclusions") === "1";
    if (!showOcclusions) return;
    for (const visual of this.appliedForegrounds) {
      const graphics = this.add.graphics().setDepth(9998);
      graphics.fillStyle(0x39f2d0, 0.08).fillRect(
        visual.maskBounds.x, visual.maskBounds.y,
        visual.maskBounds.width, visual.maskBounds.height
      );
      graphics.lineStyle(2, 0x39f2d0, 0.9).strokeRect(
        visual.maskBounds.x, visual.maskBounds.y,
        visual.maskBounds.width, visual.maskBounds.height
      );
      graphics.lineStyle(3, 0xffcc5c, 0.96).lineBetween(
        visual.maskBounds.x, visual.baselineY,
        visual.maskBounds.x + visual.maskBounds.width, visual.baselineY
      );
      this.debugOverlayObjects.push(graphics);
    }
  }

  private ensureBakeryBakerAnimation(): void {
    if (!this.textures.exists(BAKERY_COUNTER_BAKER_TEXTURE)
      || this.anims.exists(BAKERY_COUNTER_BAKER_ANIMATION)) return;
    this.anims.create({
      key: BAKERY_COUNTER_BAKER_ANIMATION,
      frames: BAKERY_RUNTIME.baker.frames.map((frame) => ({
        key: BAKERY_COUNTER_BAKER_TEXTURE,
        frame
      })),
      frameRate: 1.8,
      repeat: -1,
      repeatDelay: 260
    });
  }

  private ensureFrontDeskStaffAnimation(): void {
    if (!this.textures.exists(FRONT_DESK_STAFF_TEXTURE)
      || this.anims.exists(FRONT_DESK_STAFF_ANIMATION)) return;
    this.anims.create({
      key: FRONT_DESK_STAFF_ANIMATION,
      frames: FRONT_DESK_RUNTIME.frames.map((frame) => ({
        key: FRONT_DESK_STAFF_TEXTURE,
        frame
      })),
      frameRate: FRONT_DESK_RUNTIME.frameRate,
      repeat: -1,
      repeatDelay: 320
    });
  }

  private syncFrontDeskAttendant(state: GameState): void {
    const active = state.chapter4.floor === FRONT_DESK_RUNTIME.storyFloor
      && FRONT_DESK_RUNTIME.activePhases.includes(state.chapter4.phase)
      && this.projection.npcIds.includes(FRONT_DESK_RUNTIME.npcId);
    if (!active) {
      this.frontDeskAttendant?.destroy();
      this.frontDeskAttendant = null;
      return;
    }
    if (this.frontDeskAttendant?.active) return;
    const floor = getFloor(1);
    this.frontDeskAttendant = this.add.sprite(
      floor.offsetX + FRONT_DESK_RUNTIME.position.x,
      FRONT_DESK_RUNTIME.position.y,
      FRONT_DESK_STAFF_TEXTURE,
      FRONT_DESK_RUNTIME.frames[0]
    ).setOrigin(FRONT_DESK_RUNTIME.origin.x, FRONT_DESK_RUNTIME.origin.y)
      .setScale(FRONT_DESK_RUNTIME.uniformScale)
      .setDepth(PLAYER_DEPTH_BASE + FRONT_DESK_RUNTIME.position.y);
    this.frontDeskAttendant.play(FRONT_DESK_STAFF_ANIMATION, true);
  }

  private syncSupportNpcs(state: GameState): void {
    const activeIds = new Set(
      SUPPORT_NPC_RUNTIMES
        .filter((definition) => (
          state.chapter4.floor === definition.storyFloor
          && definition.activePhases.includes(state.chapter4.phase)
          && this.projection.npcIds.includes(definition.npcId)
        ))
        .map((definition) => definition.npcId)
    );
    for (const [npcId, sprite] of this.supportNpcSprites) {
      if (activeIds.has(npcId)) continue;
      sprite.destroy();
      this.supportNpcSprites.delete(npcId);
    }
    for (const definition of SUPPORT_NPC_RUNTIMES) {
      if (!activeIds.has(definition.npcId) || this.supportNpcSprites.has(definition.npcId)) continue;
      const displayFloor = displayFloorFor(definition.storyFloor);
      if (!displayFloor) continue;
      const floor = getFloor(displayFloor);
      const finaleAnimation = definition.visualSource === "finale_npc"
        ? FINALE_NPC_ANIMATIONS[definition.animation as FinaleNpcAnimationId]
        : null;
      const texture = finaleAnimation?.id ?? FRONT_DESK_STAFF_TEXTURE;
      const frame = finaleAnimation ? 0 : FRONT_DESK_RUNTIME.frames[0];
      const animation = finaleAnimation?.id ?? FRONT_DESK_STAFF_ANIMATION;
      const sprite = this.add.sprite(
        floor.offsetX + definition.position.x,
        definition.position.y,
        texture,
        frame
      ).setOrigin(definition.origin.x, definition.origin.y)
        .setScale(definition.uniformScale)
        .setDepth(PLAYER_DEPTH_BASE + definition.position.y);
      if (this.anims.exists(animation)) sprite.play(animation, true);
      this.supportNpcSprites.set(definition.npcId, sprite);
    }
  }

  private refreshSupportNpcAnimations(): void {
    for (const definition of SUPPORT_NPC_RUNTIMES) {
      const sprite = this.supportNpcSprites.get(definition.npcId);
      if (!sprite?.active) continue;
      const finaleAnimation = definition.visualSource === "finale_npc"
        ? FINALE_NPC_ANIMATIONS[definition.animation as FinaleNpcAnimationId]
        : null;
      const animation = finaleAnimation?.id ?? FRONT_DESK_STAFF_ANIMATION;
      if (this.anims.exists(animation) && sprite.anims.currentAnim?.key !== animation) {
        sprite.play(animation, true);
      }
    }
  }

  private syncBakeryRuntime(
    state: GameState,
    projection: ChapterFourMazeProjection
  ): void {
    const active = state.chapter4.phase === "bakery_hour_hand"
      && state.chapter4.timeState === "1225_bakery"
      && projection.activePlateIds.includes(BAKERY_RUNTIME.statePlateId);
    if (!active) {
      if (this.bakeryRuntimeSignature) this.destroyBakeryRuntime("plate_or_phase_change");
      return;
    }
    if (!this.bakeryRuntimeSignature) this.createBakeryRuntime();

    const lampInspected = hasChapterFourFact(state, "bakery_conveyor_lamp_inspected");
    const exposed = hasChapterFourFact(state, "bakery_hour_hand_exposed");
    const collected = hasChapterFourFact(state, "bakery_hour_hand_collected")
      || state.items.oldClockHourHand;
    this.paintBakeryInspectionLamp(lampInspected);
    if (exposed) {
      this.pauseBakeryActivity();
      this.revealBakeryHourHand(!collected);
    } else if (!lampInspected) {
      this.resumeBakeryActivity();
      this.revealBakeryHourHand(false);
    }
  }

  private createBakeryRuntime(): void {
    this.destroyBakeryRuntime("runtime_recreate");
    const floor = getFloor(1);
    const targetById = new Map(BAKERY_RUNTIME.targetEntities.map((entry) => [entry.targetId, entry]));
    const lampDefinition = targetById.get("a1_bakery_inspection_lamp");
    const conveyorDefinition = targetById.get("a1_bakery_conveyor_edge");
    const hourDefinition = targetById.get("a1_bakery_hour_hand_pickup");
    if (!lampDefinition || !conveyorDefinition || !hourDefinition?.visual) {
      this.persistentContractFailures.add("bakery_runtime_definition_missing");
      return;
    }

    const createTargetRectangle = (
      definition: BakeryRuntimeTargetDefinition,
      fillColor: number,
      fillAlpha: number
    ) => {
      const bounds = definition.installationBounds;
      const rectangle = this.add.rectangle(
        floor.offsetX + rectCenterX(bounds),
        rectCenterY(bounds),
        bounds.width,
        bounds.height,
        fillColor,
        fillAlpha
      ).setDepth(PLAYER_DEPTH_BASE + rectBottom(bounds) - 1)
        .setStrokeStyle(1, fillColor, 0.72);
      this.bakeryRuntimeTargets.set(definition.targetId, {
        targetId: definition.targetId,
        entityId: definition.entityId,
        boundsObject: rectangle
      });
      this.bakeryRuntimeObjects.push(rectangle);
      return rectangle;
    };

    createTargetRectangle(lampDefinition, 0x907b53, 0.34);
    createTargetRectangle(conveyorDefinition, 0xaab8c6, 0.16);

    const visual = hourDefinition.visual;
    const hourSprite = this.add.sprite(
      floor.offsetX + visual.pivot.x,
      visual.pivot.y,
      visual.texture,
      visual.frame
    ).setOrigin(
      (visual.sourcePivot.x - visual.sourceCell.x) / visual.sourceCell.width,
      (visual.sourcePivot.y - visual.sourceCell.y) / visual.sourceCell.height
    ).setScale(visual.uniformScale)
      .setDepth(PLAYER_DEPTH_BASE + visual.pivot.y + 2)
      .setVisible(false);
    this.bakeryHourHandSprite = hourSprite;
    this.bakeryRuntimeObjects.push(hourSprite);

    const triggerLeft = visual.pivot.x
      + (visual.sourceInteractionBounds.x - visual.sourcePivot.x) * visual.uniformScale;
    const triggerTop = visual.pivot.y
      + (visual.sourceInteractionBounds.y - visual.sourcePivot.y) * visual.uniformScale;
    const triggerWidth = visual.sourceInteractionBounds.width * visual.uniformScale;
    const triggerHeight = visual.sourceInteractionBounds.height * visual.uniformScale;
    const hourTrigger = this.add.rectangle(
      floor.offsetX + triggerLeft + triggerWidth / 2,
      triggerTop + triggerHeight / 2,
      triggerWidth,
      triggerHeight,
      0xffffff,
      0.001
    ).setDepth(PLAYER_DEPTH_BASE + visual.pivot.y + 3).setVisible(false);
    this.bakeryRuntimeTargets.set(hourDefinition.targetId, {
      targetId: hourDefinition.targetId,
      entityId: hourDefinition.entityId,
      boundsObject: hourTrigger
    });
    this.bakeryRuntimeObjects.push(hourTrigger);

    this.bakeryHourHandGlint = this.add.circle(
      floor.offsetX + rectCenterX(hourDefinition.installationBounds),
      rectCenterY(hourDefinition.installationBounds),
      9,
      0xfff3a8,
      0.2
    ).setStrokeStyle(2, 0xfff3a8, 0.9)
      .setDepth(PLAYER_DEPTH_BASE + rectBottom(hourDefinition.installationBounds) + 3)
      .setVisible(false);
    this.bakeryRuntimeObjects.push(this.bakeryHourHandGlint);
    this.bakeryHourHandGlintTween = this.tweens.add({
      targets: this.bakeryHourHandGlint,
      alpha: { from: 0.18, to: 0.92 },
      scale: { from: 0.82, to: 1.22 },
      duration: 520,
      yoyo: true,
      repeat: -1,
      paused: true,
      ease: "Sine.InOut"
    });

    this.bakeryConveyorGlint = this.add.rectangle(
      floor.offsetX + conveyorDefinition.installationBounds.x + 2,
      rectCenterY(conveyorDefinition.installationBounds),
      3,
      Math.max(5, conveyorDefinition.installationBounds.height - 4),
      0xeaf7ff,
      0.78
    ).setDepth(PLAYER_DEPTH_BASE + rectBottom(conveyorDefinition.installationBounds));
    this.bakeryRuntimeObjects.push(this.bakeryConveyorGlint);
    this.bakeryConveyorTween = this.tweens.add({
      targets: this.bakeryConveyorGlint,
      x: floor.offsetX + rectRight(conveyorDefinition.installationBounds) - 2,
      duration: 430,
      repeat: -1,
      ease: "Linear"
    });

    const crowdSprites: Phaser.Physics.Arcade.Sprite[] = [];
    for (const [routeIndex, route] of BAKERY_RUNTIME.crowd.routes.entries()) {
      const sprite = this.physics.add.sprite(
        floor.offsetX + route.from.x,
        route.from.y,
        BAKERY_RUNTIME.crowd.texture,
        0
      ).setOrigin(
        BAKERY_RUNTIME.crowd.origin.x,
        BAKERY_RUNTIME.crowd.origin.y
      ).setScale(BAKERY_RUNTIME.crowd.displayScale)
        .setDepth(PLAYER_DEPTH_BASE + route.from.y);
      const body = sprite.body as Phaser.Physics.Arcade.Body;
      body.setAllowGravity(false).setImmovable(true);
      body.pushable = false;
      body.setSize(
        LAYOUT.playerFootBoxContract.sourceFootBox.width,
        LAYOUT.playerFootBoxContract.sourceFootBox.height
      ).setOffset(
        LAYOUT.playerFootBoxContract.sourceFootBox.x,
        LAYOUT.playerFootBoxContract.sourceFootBox.y
      );
      // The authored side-view student faces left. Mirror only when travelling right.
      sprite.setFlipX(route.to.x > route.from.x).play({
        key: "student_walk",
        startFrame: (routeIndex * 3) % FINALE_NPC_ANIMATIONS.student_walk.frameCount
      }, true);
      const duration = Math.round(
        Phaser.Math.Distance.Between(route.from.x, route.from.y, route.to.x, route.to.y)
        / route.speed * 1000
      );
      const tween = this.tweens.add({
        targets: sprite,
        x: floor.offsetX + route.to.x,
        y: route.to.y,
        duration,
        yoyo: true,
        repeat: -1,
        hold: route.endpointPauseMs,
        repeatDelay: route.endpointPauseMs,
        ease: "Linear",
        onYoyo: () => sprite.setFlipX(!sprite.flipX),
        onRepeat: () => sprite.setFlipX(!sprite.flipX),
        onUpdate: () => sprite.setDepth(PLAYER_DEPTH_BASE + sprite.y)
      });
      this.bakeryCrowdActors.push({
        sprite,
        tween,
        routeIndex,
        route,
        hasLeftInitialEndpoint: false,
        activeEndpoint: null,
        endpointTimer: null
      });
      this.bakeryRuntimeObjects.push(sprite);
      crowdSprites.push(sprite);
    }
    this.bakeryCrowdCollider = this.physics.add.collider(this.player, crowdSprites);
    this.bakeryRuntimeSignature = `${BAKERY_RUNTIME.storyFloor}:${BAKERY_RUNTIME.statePlateId}`;
    this.validateBakeryRuntimeBounds();
  }

  private validateBakeryRuntimeBounds(): void {
    for (const definition of BAKERY_RUNTIME.targetEntities) {
      const binding = this.bakeryRuntimeTargets.get(definition.targetId);
      const bounds = binding ? this.outwardBakeryRuntimeBounds(binding) : null;
      if (!bounds
        || bounds.x !== definition.installationBounds.x
        || bounds.y !== definition.installationBounds.y
        || bounds.width !== definition.installationBounds.width
        || bounds.height !== definition.installationBounds.height) {
        this.persistentContractFailures.add(
          `bakery_runtime_bounds:${definition.targetId}:${JSON.stringify(bounds)}`
        );
      }
    }
  }

  private outwardBakeryRuntimeBounds(binding: BakeryRuntimeTargetBinding): MapRect | null {
    if (!binding.boundsObject.active) return null;
    const floor = getFloor(1);
    const bounds = binding.boundsObject.getBounds();
    const left = Math.floor(bounds.left - floor.offsetX);
    const top = Math.floor(bounds.top);
    const right = Math.ceil(bounds.right - floor.offsetX);
    const bottom = Math.ceil(bounds.bottom);
    const result = { x: left, y: top, width: right - left, height: bottom - top };
    return rectInsideFloor(result) ? result : null;
  }

  private paintBakeryInspectionLamp(lit: boolean): void {
    const lamp = this.bakeryRuntimeTargets.get("a1_bakery_inspection_lamp")?.boundsObject;
    if (!(lamp instanceof Phaser.GameObjects.Rectangle)) return;
    lamp.setFillStyle(lit ? 0xffd66b : 0x4d4330, lit ? 0.72 : 0.34)
      .setStrokeStyle(2, lit ? 0xfff1a8 : 0x907b53, 0.92);
  }

  private pauseBakeryActivity(): void {
    this.bakeryActivityPaused = true;
    this.bakeryConveyorTween?.pause();
    this.bakeryConveyorGlint?.setVisible(false);
    this.bakeryBaker?.anims.pause();
    for (const actor of this.bakeryCrowdActors) {
      actor.tween.pause();
      if (actor.endpointTimer) actor.endpointTimer.paused = true;
      actor.sprite.anims.pause();
      actor.sprite.setVelocity(0, 0);
    }
  }

  private resumeBakeryActivity(): void {
    this.bakeryActivityPaused = false;
    if (this.bakeryConveyorTween) {
      this.bakeryConveyorTween.timeScale = 1;
      this.bakeryConveyorTween.resume();
    }
    this.bakeryConveyorGlint?.setVisible(true);
    this.bakeryBaker?.anims.resume();
    for (const actor of this.bakeryCrowdActors) {
      actor.tween.resume();
      if (actor.endpointTimer) actor.endpointTimer.paused = false;
      actor.sprite.anims.resume();
    }
  }

  private updateBakeryCrowdEndpointActions(): void {
    if (this.bakeryActivityPaused || !this.bakeryRuntimeSignature) return;
    const floor = getFloor(1);
    for (const actor of this.bakeryCrowdActors) {
      if (!actor.sprite.active) continue;
      const local = { x: actor.sprite.x - floor.offsetX, y: actor.sprite.y };
      const distanceFrom = Phaser.Math.Distance.Between(
        local.x,
        local.y,
        actor.route.from.x,
        actor.route.from.y
      );
      const distanceTo = Phaser.Math.Distance.Between(
        local.x,
        local.y,
        actor.route.to.x,
        actor.route.to.y
      );
      if (!actor.hasLeftInitialEndpoint) {
        if (distanceFrom > 3) actor.hasLeftInitialEndpoint = true;
        continue;
      }
      const endpoint = distanceFrom <= 0.75
        ? "from"
        : distanceTo <= 0.75
          ? "to"
          : null;
      if (!endpoint) {
        actor.activeEndpoint = null;
        continue;
      }
      if (actor.activeEndpoint === endpoint) continue;
      actor.activeEndpoint = endpoint;
      actor.endpointTimer?.remove(false);
      const actionId: FinaleNpcAnimationId = (
        actor.routeIndex + (endpoint === "to" ? 1 : 0)
      ) % 2 === 0
        ? "student_phone_glance"
        : "student_adjust_bag";
      actor.sprite.play(actionId, true);
      actor.endpointTimer = this.time.delayedCall(
        Math.max(180, Math.min(360, actor.route.endpointPauseMs - 40)),
        () => {
          actor.endpointTimer = null;
          if (!actor.sprite.active || this.bakeryActivityPaused) return;
          actor.sprite.play({
            key: "student_walk",
            startFrame: (actor.routeIndex * 3) % FINALE_NPC_ANIMATIONS.student_walk.frameCount
          }, true);
        }
      );
    }
  }

  private revealBakeryHourHand(visible: boolean): void {
    this.bakeryHourHandSprite?.setVisible(visible);
    const trigger = this.bakeryRuntimeTargets.get("a1_bakery_hour_hand_pickup")?.boundsObject;
    trigger?.setVisible(visible);
    this.bakeryHourHandGlint?.setVisible(visible);
    if (visible) this.bakeryHourHandGlintTween?.resume();
    else this.bakeryHourHandGlintTween?.pause();
  }

  private rollbackBakeryConveyorStopToCommittedState(
    feedback: string,
    scheduleRetry = true
  ): void {
    this.clearStoryPresentationTimers();
    const committed = selectChapterFour755BakeryCommittedRuntimeState(this.bridge.getState());
    this.paintBakeryInspectionLamp(committed.lampLit);
    if (committed.conveyorStopped || committed.crowdPaused) this.pauseBakeryActivity();
    else this.resumeBakeryActivity();
    this.revealBakeryHourHand(committed.hourHandVisible && committed.glintVisible);
    this.storyPresentation = "idle";
    this.storyRetryNotBeforeMs = scheduleRetry && committed.retryStopHandshake
      ? this.time.now + STORY_RETRY_DELAY_MS
      : 0;
    if (feedback) {
      this.persistentContractFailures.add(`bakery_recovery:${feedback}`);
      this.showFeedback("进度已恢复，请重试当前操作。");
    }
    this.syncStoryInputLock();
  }

  private destroyBakeryRuntime(reason: string): void {
    this.bakeryCrowdCollider?.destroy();
    this.bakeryCrowdCollider = null;
    this.bakeryConveyorTween?.remove();
    this.bakeryConveyorTween = null;
    this.bakeryHourHandGlintTween?.remove();
    this.bakeryHourHandGlintTween = null;
    for (const actor of this.bakeryCrowdActors) {
      actor.endpointTimer?.remove(false);
      actor.tween.remove();
    }
    this.bakeryCrowdActors = [];
    for (const object of this.bakeryRuntimeObjects) {
      if (object.active) object.destroy();
    }
    this.bakeryRuntimeObjects = [];
    this.bakeryRuntimeTargets.clear();
    this.bakeryConveyorGlint = null;
    this.bakeryHourHandSprite = null;
    this.bakeryHourHandGlint = null;
    this.bakeryRuntimeSignature = "";
    this.bakeryApproachCueSignature = "";
    this.bakeryActivityPaused = false;
    if (reason === "plate_or_phase_change" && this.storyPresentation === "bakery_conveyor_stop") {
      this.clearStoryPresentationTimers();
      this.storyPresentation = "idle";
      this.syncStoryInputLock();
    }
  }

  private createRoom204Runtime(): void {
    this.destroyRoom204Runtime("runtime_recreate");
    const floor = getFloor(2);
    this.room204ObstacleGroup = this.physics.add.staticGroup();
    this.room204ObstacleCollider = this.physics.add.collider(this.player, this.room204ObstacleGroup);
    for (const pieceId of ROOM204_PIECE_ORDER) {
      const binding = ROOM204_PIECE_FRAME_BINDINGS[pieceId];
      const desk = this.createRoom204FurnitureEntity(binding.deskFrame);
      const chair = this.createRoom204FurnitureEntity(binding.chairFrame);
      if (!desk || !chair) {
        this.persistentContractFailures.add(`room204_piece_frame_missing:${pieceId}`);
        continue;
      }
      this.room204RuntimePieces.set(pieceId, {
        pieceId,
        deskSprite: desk.sprite,
        chairSprite: chair.sprite,
        deskObstacle: desk.obstacle,
        chairObstacle: chair.obstacle
      });
    }
    for (const tableLayout of ROOM204_DISCUSSION_TABLES) {
      const table = this.createRoom204FurnitureEntity(tableLayout.frame);
      if (!table) {
        this.persistentContractFailures.add(`room204_group_table_frame_missing:${tableLayout.id}`);
        continue;
      }
      this.layoutRoom204FurnitureEntity(
        table.sprite,
        table.obstacle,
        tableLayout.frame,
        tableLayout.position,
        tableLayout.angle,
        true
      );
      this.room204DiscussionTables.push({
        id: tableLayout.id,
        pieceIds: tableLayout.pieceIds,
        sprite: table.sprite,
        obstacle: table.obstacle
      });
    }
    const podium = this.createRoom204FurnitureEntity(ROOM204_PODIUM_LAYOUT.frame);
    if (podium) {
      this.layoutRoom204FurnitureEntity(
        podium.sprite,
        podium.obstacle,
        ROOM204_PODIUM_LAYOUT.frame,
        ROOM204_PODIUM_LAYOUT.position,
        0,
        true
      );
      this.room204PodiumSprite = podium.sprite;
      this.room204PodiumObstacle = podium.obstacle;
    } else {
      this.persistentContractFailures.add("room204_podium_frame_missing");
    }
    for (const [index, pieceId] of ROOM204_PIECE_ORDER.entries()) {
      const binding = ROOM204_PIECE_FRAME_BINDINGS[pieceId];
      const residualFrame = getChapterFour755ManifestFrame(
        "chapter4_room204_residual",
        binding.residualFrame
      );
      if (!residualFrame?.pivot) {
        this.persistentContractFailures.add(`room204_residual_frame_missing:${pieceId}`);
        continue;
      }
      const slotId = ROOM204_SLOT_ORDER[index] as ChapterFourRoom204SlotId;
      const slot = ROOM204_SLOT_CENTERS[slotId];
      const residual = this.add.sprite(
        floor.offsetX + slot.x,
        slot.y,
        "chapter4_room204_residual",
        binding.residualFrame
      ).setOrigin(
        (residualFrame.pivot.x - residualFrame.sourceRect.x) / residualFrame.sourceRect.width,
        (residualFrame.pivot.y - residualFrame.sourceRect.y) / residualFrame.sourceRect.height
      ).setScale(ROOM204_FURNITURE_SCALE)
        .setAlpha(0.88)
        .setTint(0x78dfff)
        .setDepth(PLAYER_DEPTH_BASE - 200)
        .setVisible(false);
      this.room204ResidualSprites.push(residual);
    }
    for (const slotId of ROOM204_SLOT_ORDER) {
      const bounds = ROOM204_SLOT_LAYOUTS[slotId].bounds;
      const zone = this.createRoom204RuntimeTargetZone(
        `a2_room204_slot_${slotId}`,
        room204SlotRuntimeEntityId(slotId),
        bounds
      );
      this.room204SlotBoundsObjects.set(slotId, zone);
    }
    for (const groupId of ROOM204_GROUP_ORDER) {
      this.createRoom204RuntimeTargetZone(
        room204GroupTargetId(groupId),
        room204GroupRuntimeEntityId(groupId),
        ROOM204_GROUPS[groupId].targetBounds
      );
    }
    this.createRoom204RuntimeTargetZone(
      "a2_room204_residual_group",
      ROOM204_RESIDUAL_GROUP_RUNTIME_ENTITY_ID,
      ROOM204_RESIDUAL_GROUP_BOUNDS
    );
    this.createRoom204RuntimeTargetZone(
      "a2_room204_podium_drawer",
      ROOM204_PODIUM_DRAWER_RUNTIME_ENTITY_ID,
      ROOM204_PODIUM_LAYOUT.drawerBounds
    );
  }

  private createRoom204RuntimeTargetZone(
    targetId: string,
    entityId: string,
    bounds: Readonly<MapRect>
  ): Phaser.GameObjects.Zone {
    const floor = getFloor(2);
    const zone = this.add.zone(
      floor.offsetX + rectCenterX(bounds),
      rectCenterY(bounds),
      bounds.width,
      bounds.height
    ).setVisible(true);
    this.room204RuntimeTargets.set(targetId, { targetId, entityId, boundsObject: zone });
    const measured = this.outwardRoom204Bounds(zone);
    if (!measured
      || measured.x !== bounds.x
      || measured.y !== bounds.y
      || measured.width !== bounds.width
      || measured.height !== bounds.height) {
      this.persistentContractFailures.add(
        `room204_runtime_bounds:${targetId}:${JSON.stringify(measured)}`
      );
    }
    return zone;
  }

  private createRoom204FurnitureEntity(frameId: string): {
    sprite: Phaser.GameObjects.Sprite;
    obstacle: Phaser.GameObjects.Zone;
  } | null {
    const frame = getChapterFour755ManifestFrame("chapter4_room204_furniture", frameId);
    if (!frame?.pivot || !frame.collisionBounds?.[0]?.bounds) return null;
    const sprite = this.add.sprite(0, 0, "chapter4_room204_furniture", frameId)
      .setOrigin(
        (frame.pivot.x - frame.sourceRect.x) / frame.sourceRect.width,
        (frame.pivot.y - frame.sourceRect.y) / frame.sourceRect.height
      )
      .setScale(ROOM204_FURNITURE_SCALE)
      .setVisible(false);
    const obstacle = this.add.zone(0, 0, 1, 1).setVisible(false).setActive(false);
    this.physics.add.existing(obstacle, true);
    this.room204ObstacleGroup?.add(obstacle);
    return { sprite, obstacle };
  }

  private layoutRoom204FurnitureEntity(
    sprite: Phaser.GameObjects.Sprite,
    obstacle: Phaser.GameObjects.Zone,
    frameId: string,
    point: Readonly<{ x: number; y: number }>,
    angle: number,
    visible: boolean
  ): void {
    const floor = getFloor(2);
    const frame = getChapterFour755ManifestFrame("chapter4_room204_furniture", frameId);
    const collision = frame?.collisionBounds?.[0]?.bounds;
    if (!frame?.pivot || !collision) {
      this.persistentContractFailures.add(`room204_collision_frame_missing:${frameId}`);
      this.setRoom204ObstacleEnabled(obstacle, false);
      sprite.setVisible(false);
      return;
    }
    sprite
      .setPosition(floor.offsetX + point.x, point.y)
      .setAngle(angle)
      .setDepth(PLAYER_DEPTH_BASE + point.y + 1)
      .setVisible(visible);
    const radians = Phaser.Math.DegToRad(angle);
    const localCenterX = (collision.x + collision.width / 2 - frame.pivot.x)
      * ROOM204_FURNITURE_SCALE;
    const localCenterY = (collision.y + collision.height / 2 - frame.pivot.y)
      * ROOM204_FURNITURE_SCALE;
    const cos = Math.cos(radians);
    const sin = Math.sin(radians);
    const rotatedCenterX = localCenterX * cos - localCenterY * sin;
    const rotatedCenterY = localCenterX * sin + localCenterY * cos;
    const sourceWidth = collision.width * ROOM204_FURNITURE_SCALE;
    const sourceHeight = collision.height * ROOM204_FURNITURE_SCALE;
    const width = Math.abs(sourceWidth * cos) + Math.abs(sourceHeight * sin);
    const height = Math.abs(sourceWidth * sin) + Math.abs(sourceHeight * cos);
    obstacle.setPosition(
      floor.offsetX + point.x + rotatedCenterX,
      point.y + rotatedCenterY
    ).setSize(width, height);
    const body = obstacle.body as Phaser.Physics.Arcade.StaticBody | undefined;
    if (body) {
      body.setSize(width, height);
      body.enable = visible;
      body.updateFromGameObject();
    }
    obstacle.setActive(visible);
  }

  private setRoom204ObstacleEnabled(obstacle: Phaser.GameObjects.Zone, enabled: boolean): void {
    const body = obstacle.body as Phaser.Physics.Arcade.StaticBody | undefined;
    if (body) {
      body.enable = enabled;
      body.updateFromGameObject();
    }
    obstacle.setActive(enabled);
  }

  private outwardRoom204Bounds(object: Phaser.GameObjects.GameObject & Phaser.GameObjects.Components.GetBounds): MapRect | null {
    if (!object.active) return null;
    const floor = getFloor(2);
    const bounds = object.getBounds();
    const left = Math.floor(bounds.left - floor.offsetX);
    const top = Math.floor(bounds.top);
    const right = Math.ceil(bounds.right - floor.offsetX);
    const bottom = Math.ceil(bounds.bottom);
    const result = { x: left, y: top, width: right - left, height: bottom - top };
    return rectInsideFloor(result) ? result : null;
  }

  private syncRoom204Runtime(state: GameState): void {
    const presentation = selectRoom204RuntimePresentation(
      state.chapter4.phase,
      hasChapterFourFact(state, "room204_restored"),
      state.chapter4.room204Placements
    );
    if (presentation === "hidden") {
      if (this.room204RuntimePieces.size > 0
        || this.room204ResidualSprites.length > 0
        || this.room204RuntimeTargets.size > 0) {
        this.destroyRoom204Runtime("phase_change");
      }
      return;
    }
    if (this.room204RuntimePieces.size === 0) this.createRoom204Runtime();
    const interactive = presentation === "interactive";
    if (!interactive || this.currentFloor !== 2) this.room204SelectedPieceId = null;
    if (this.room204SelectedPieceId
      && findRoom204PlacementForPiece(state.chapter4.room204Placements, this.room204SelectedPieceId)) {
      this.room204SelectedPieceId = null;
    }
    const pieceVisible = this.currentFloor === 2;
    const residualVisible = interactive
      && pieceVisible
      && (state.chapter4.mode === "dark" || this.storyPresentation === "room204_projection");
    this.room204ResidualSprites.forEach((sprite) => sprite
      .setVisible(residualVisible)
      .setBlendMode(state.chapter4.mode === "dark" ? Phaser.BlendModes.ADD : Phaser.BlendModes.NORMAL)
      .setDepth(state.chapter4.mode === "dark" ? REALITY_MODE_TARGET_DEPTH : PLAYER_DEPTH_BASE - 200));
    for (const pieceId of ROOM204_PIECE_ORDER) {
      const runtimePiece = this.room204RuntimePieces.get(pieceId);
      if (!runtimePiece) continue;
      const placement = findRoom204PlacementForPiece(state.chapter4.room204Placements, pieceId);
      const point = placement ? ROOM204_SLOT_CENTERS[placement.slotId] : ROOM204_INITIAL_PIECE_POSITIONS[pieceId];
      this.layoutRoom204Piece(
        runtimePiece,
        point,
        pieceVisible && this.room204SelectedPieceId !== pieceId,
        placement !== null
      );
    }
    for (const table of this.room204DiscussionTables) {
      const tableLayout = ROOM204_DISCUSSION_TABLES.find((entry) => entry.id === table.id);
      if (!tableLayout) continue;
      const visible = pieceVisible && table.pieceIds.some((pieceId) => (
        !findRoom204PlacementForPiece(state.chapter4.room204Placements, pieceId)
      ));
      this.layoutRoom204FurnitureEntity(
        table.sprite,
        table.obstacle,
        tableLayout.frame,
        tableLayout.position,
        tableLayout.angle,
        visible
      );
    }
    if (this.room204PodiumSprite && this.room204PodiumObstacle) {
      this.layoutRoom204FurnitureEntity(
        this.room204PodiumSprite,
        this.room204PodiumObstacle,
        ROOM204_PODIUM_LAYOUT.frame,
        ROOM204_PODIUM_LAYOUT.position,
        0,
        pieceVisible
      );
    }
    this.updateRoom204CarryGhost();
  }

  private layoutRoom204Piece(
    runtimePiece: Room204RuntimePiece,
    point: { x: number; y: number },
    visible: boolean,
    placed: boolean
  ): void {
    const binding = ROOM204_PIECE_FRAME_BINDINGS[runtimePiece.pieceId];
    const initial = ROOM204_INITIAL_PIECE_LAYOUTS[runtimePiece.pieceId];
    this.layoutRoom204FurnitureEntity(
      runtimePiece.deskSprite,
      runtimePiece.deskObstacle,
      binding.deskFrame,
      { x: point.x + ROOM204_PAIR_OFFSETS.desk.x, y: point.y + ROOM204_PAIR_OFFSETS.desk.y },
      placed ? 0 : initial.angle,
      visible && placed
    );
    this.layoutRoom204FurnitureEntity(
      runtimePiece.chairSprite,
      runtimePiece.chairObstacle,
      binding.chairFrame,
      { x: point.x + ROOM204_PAIR_OFFSETS.chair.x, y: point.y + ROOM204_PAIR_OFFSETS.chair.y },
      placed ? 0 : initial.angle,
      visible
    );
  }

  private updateRoom204CarryGhost(): void {
    if (!this.room204SelectedPieceId || this.currentFloor !== 2) {
      this.room204CarryGhost?.setVisible(false);
      return;
    }
    const binding = ROOM204_PIECE_FRAME_BINDINGS[this.room204SelectedPieceId];
    if (!this.room204CarryGhost || this.room204CarryGhost.frame.name !== binding.deskFrame) {
      this.room204CarryGhost?.destroy();
      this.room204CarryGhost = this.add.sprite(
        this.player.x,
        this.player.y - 20,
        "chapter4_room204_furniture",
        binding.deskFrame
      ).setOrigin(0.5, 1)
        .setScale(ROOM204_FURNITURE_SCALE * 0.86)
        .setAlpha(0.86);
    }
    this.room204CarryGhost
      .setPosition(this.player.x, this.player.y - 18)
      .setDepth(PLAYER_DEPTH_BASE + this.player.y + 28)
      .setVisible(true);
  }

  private resolveNearbyRoom204PieceId(): ChapterFourRoom204PieceId | null {
    const state = this.bridge.getState();
    if (state.chapter4.phase !== "room204_restore"
      || state.chapter4.mode !== "light"
      || this.currentFloor !== 2
      || this.room204SelectedPieceId) return null;
    const floor = getFloor(2);
    const foot = this.playerFootPoint(floor);
    const localPlayer = { x: foot.x, y: foot.y };
    let best: { pieceId: ChapterFourRoom204PieceId; distance: number } | null = null;
    for (const pieceId of ROOM204_PIECE_ORDER) {
      if (findRoom204PlacementForPiece(state.chapter4.room204Placements, pieceId)) continue;
      const runtimePiece = this.room204RuntimePieces.get(pieceId);
      if (!runtimePiece?.chairSprite.visible) continue;
      const measured = this.outwardRoom204Bounds(runtimePiece.chairSprite);
      if (!measured) continue;
      const rect = measured;
      const distance = pointDistanceToRect(localPlayer, rect);
      if (distance > 56) continue;
      if (!best || distance < best.distance) best = { pieceId, distance };
    }
    return best?.pieceId ?? null;
  }

  private selectRoom204Piece(pieceId: ChapterFourRoom204PieceId): void {
    this.room204SelectedPieceId = pieceId;
    this.updateRoom204CarryGhost();
  }

  private destroyRoom204Runtime(reason: string): void {
    this.room204SelectedPieceId = null;
    this.nearbyRoom204PieceId = null;
    this.room204CarryGhost?.destroy();
    this.room204CarryGhost = null;
    this.room204ObstacleCollider?.destroy();
    this.room204ObstacleCollider = null;
    if (this.room204ObstacleGroup) {
      this.destroyObstacleGroup(this.room204ObstacleGroup, `room204_${reason}`);
      this.room204ObstacleGroup = null;
    }
    for (const runtimePiece of this.room204RuntimePieces.values()) {
      runtimePiece.deskSprite.destroy();
      runtimePiece.chairSprite.destroy();
    }
    this.room204RuntimePieces.clear();
    for (const table of this.room204DiscussionTables) table.sprite.destroy();
    this.room204DiscussionTables = [];
    this.room204PodiumSprite?.destroy();
    this.room204PodiumSprite = null;
    this.room204PodiumObstacle = null;
    for (const zone of new Set(
      [...this.room204RuntimeTargets.values()].map((binding) => binding.boundsObject)
    )) zone.destroy();
    this.room204RuntimeTargets.clear();
    this.room204SlotBoundsObjects.clear();
    for (const sprite of this.room204ResidualSprites) sprite.destroy();
    this.room204ResidualSprites = [];
    this.destroyRoom204ProjectionOverlay();
  }

  private syncPhaseRuntime(state: GameState): void {
    this.syncBakeryCounterStaff(state);
    this.syncFrontDeskAttendant(state);
    this.syncSupportNpcs(state);
    if (state.chapter4.phase === "maintenance_repair") {
      this.ensureMaintenanceRuntime(state);
    }
    else if (this.hasPhaseRuntimeTargets(MAINTENANCE_RUNTIME_TARGET_IDS)) {
      this.destroyPhaseRuntime("maintenance_phase_change");
    }

    const finalClockAvailable = (
      state.chapter4.phase === "maintenance_repair"
        && hasChapterFourFact(state, "clock_gear_repaired")
    ) || (
      state.chapter4.phase === "return_to_clock"
        && state.chapter4.floor === "A1"
        && hasChapterFourFact(state, "final_minute_recovered")
        && !hasChapterFourFact(state, "final_minute_installed")
        && state.items.finalMinute
    );
    if (finalClockAvailable) this.ensureFinalClockRuntime(state);
    else this.destroyFinalClockRuntime("final_clock_unavailable");

    if (state.chapter4.phase === "blackout_light_grid" || state.chapter4.phase === "final_chase") {
      this.ensureLightGridRuntime(state);
    } else {
      this.destroyLightGridRuntime("phase_change");
    }

    if (state.chapter4.phase === "morning_checkin") this.ensureMorningCheckinRuntime(state);
    else if (this.hasPhaseRuntimeTargets(MORNING_CHECKIN_RUNTIME_TARGET_IDS)) {
      this.destroyPhaseRuntime("checkin_phase_change");
    }

    this.ensureFinalChaseRuntime(state);
    if (state.chapter4.phase === "final_minute_recovery") {
      this.ensureRoom202RecoveryBarrier();
      this.ensureFinalMinuteRuntime(state);
    } else {
      this.destroyRoom202RecoveryBarrier("phase_change");
      this.destroyFinalMinuteRuntime("phase_change");
    }
  }

  private syncBakeryCounterStaff(state: GameState): void {
    const baker = BAKERY_RUNTIME.baker;
    const active = state.chapter4.floor === BAKERY_RUNTIME.storyFloor
      && (baker.activePhases as readonly string[]).includes(state.chapter4.phase)
      && this.textures.exists(BAKERY_COUNTER_BAKER_TEXTURE);
    if (!active) {
      this.destroyBakeryCounterStaff();
      return;
    }
    if (this.bakeryBaker?.active) return;

    const floor = getFloor(1);
    const counterForeground = floor.foregroundOcclusions.find(
      (definition) => definition.id === baker.foregroundOcclusionId
    );
    this.ensureBakeryBakerAnimation();
    this.bakeryBaker = this.add.sprite(
      floor.offsetX + baker.position.x,
      baker.position.y,
      BAKERY_COUNTER_BAKER_TEXTURE,
      baker.frames[0]
    ).setOrigin(baker.origin.x, baker.origin.y)
      .setScale(baker.uniformScale)
      .setCrop(0, 0, 96, baker.visibleSourceHeight)
      .setDepth(PLAYER_DEPTH_BASE + (counterForeground?.baselineY ?? baker.position.y) + 1);
    if (this.anims.exists(BAKERY_COUNTER_BAKER_ANIMATION)) {
      this.bakeryBaker.play(BAKERY_COUNTER_BAKER_ANIMATION, true);
    }
  }

  private destroyBakeryCounterStaff(): void {
    this.bakeryBaker?.destroy();
    this.bakeryBaker = null;
  }

  private hasPhaseRuntimeTargets(targetIds: readonly string[]): boolean {
    return targetIds.some((targetId) => this.phaseRuntimeTargets.has(targetId));
  }

  private ensureMaintenanceRuntime(state: GameState): void {
    const created = !this.hasPhaseRuntimeTargets(MAINTENANCE_RUNTIME_TARGET_IDS);
    if (created) {
      this.createMaintenanceRuntime();
    }
    const wheelInspected = hasChapterFourFact(state, "cart_wheel_inspected");
    const coverOpened = hasChapterFourFact(state, "cart_wheel_cover_opened");
    const wheelRepaired = hasChapterFourFact(state, "cart_wheel_repaired");
    const gearRepaired = hasChapterFourFact(state, "clock_gear_repaired");
    this.setPhaseRuntimeTargetVisible(
      "a1_cleaning_cart_wheel_inspection",
      !wheelInspected && !coverOpened && !wheelRepaired && !gearRepaired
    );
    this.setPhaseRuntimeTargetVisible(
      "a1_bakery_back_pry_bar",
      false
    );
    this.setPhaseRuntimeTargetVisible(
      "a1_cleaning_cart_wheel_cover",
      wheelInspected && !coverOpened
    );
    this.setPhaseRuntimeTargetVisible(
      "a1_cleaning_cart_oil_bottle",
      false
    );
    this.setPhaseRuntimeTargetVisible(
      "a1_cleaning_cart_wheel",
      coverOpened && !wheelRepaired
    );
    this.setPhaseRuntimeTargetVisible(
      "a1_hall_clock_gear",
      false
    );
    this.maintenancePryBar?.setVisible(false);
    this.maintenanceOilBottle?.setVisible(false);
    if (this.maintenanceCoverVisual) {
      this.maintenanceCoverVisual
        .setVisible(!wheelRepaired)
        .setAngle(coverOpened ? -42 : 0)
        .setFillStyle(coverOpened ? 0x8295a8 : 0x44505c, coverOpened ? 0.54 : 0.82);
    }
    try {
      this.ensureHallClockStateSprite(gearRepaired ? "gear_running" : "gear_stuttering");
    } catch (error) {
      this.persistentContractFailures.add(`maintenance_clock_gear_visual:${errorMessage(error)}`);
    }
    if (wheelRepaired) {
      this.cancelMaintenanceFailedPushAttempt();
      this.startOrRestoreMaintenancePush(!created);
    } else {
      this.scheduleMaintenanceFailedPushAttempt();
    }
  }

  private createMaintenanceRuntime(): void {
    this.destroyPhaseRuntime("maintenance_runtime_recreate");
    const floor = getFloor(1);
    const targetById = new Map(
      MAINTENANCE_RUNTIME.targetEntities.map((entry) => [entry.targetId, entry])
    );
    const pryDefinition = targetById.get("a1_bakery_back_pry_bar");
    const oilDefinition = targetById.get("a1_cleaning_cart_oil_bottle");
    const inspectionDefinition = targetById.get("a1_cleaning_cart_wheel_inspection");
    const coverDefinition = targetById.get("a1_cleaning_cart_wheel_cover");
    const wheelDefinition = targetById.get("a1_cleaning_cart_wheel");
    const gearDefinition = targetById.get("a1_hall_clock_gear");
    if (!pryDefinition || !oilDefinition || !inspectionDefinition
      || !coverDefinition || !wheelDefinition || !gearDefinition) {
      this.persistentContractFailures.add("maintenance_runtime_definition_missing");
      return;
    }

    const pry = MAINTENANCE_RUNTIME.pryBar;
    this.maintenancePryBar = this.add.sprite(
      floor.offsetX + pry.pivot.x,
      pry.pivot.y,
      "chapter4_story_items",
      pry.frame
    ).setScale(pry.uniformScale)
      .setDepth(PLAYER_DEPTH_BASE + pry.pivot.y + 3);
    this.phaseRuntimeObjects.push(this.maintenancePryBar);
    const pryBounds = this.deriveStoryItemManifestInteractionBounds(
      this.maintenancePryBar,
      pryDefinition
    );
    if (pryBounds) this.createMaintenanceTargetZone(pryDefinition, pryBounds);

    if (oilDefinition?.pivot && oilDefinition.frame && oilDefinition.uniformScale) {
      this.maintenanceOilBottle = this.add.sprite(
        floor.offsetX + oilDefinition.pivot.x,
        oilDefinition.pivot.y,
        "chapter4_story_items",
        oilDefinition.frame
      ).setScale(oilDefinition.uniformScale)
        .setDepth(PLAYER_DEPTH_BASE + oilDefinition.pivot.y + 5)
        .setVisible(true);
      this.phaseRuntimeObjects.push(this.maintenanceOilBottle);
      const oilBounds = this.deriveStoryItemManifestInteractionBounds(
        this.maintenanceOilBottle,
        oilDefinition
      );
      if (oilBounds) this.createMaintenanceTargetZone(oilDefinition, oilBounds);
    } else {
      this.persistentContractFailures.add("maintenance_oil_visual_definition_missing");
    }

    const cart = MAINTENANCE_RUNTIME.cleaningCart;
    this.maintenanceCart = this.physics.add.sprite(
      floor.offsetX + cart.position.x,
      cart.position.y,
      cart.texture,
      0
    ).setOrigin(0.5, 1)
      .setScale(cart.uniformScale)
      .setDepth(PLAYER_DEPTH_BASE + cart.position.y);
    this.configureMaintenanceFootBody(
      this.maintenanceCart,
      cart.position,
      cart.footBounds,
      cart.uniformScale,
      144,
      128
    );
    this.phaseRuntimeObjects.push(this.maintenanceCart);
    const wheelBounds = this.deriveVisibleFrameLocalBounds(
      this.maintenanceCart,
      cart.wheelRegion.sourceFrameSize,
      cart.wheelRegion.bounds
    );
    for (const definition of [inspectionDefinition, coverDefinition, wheelDefinition]) {
      if (definition.boundsDerivation.kind !== "visible_cleaning_cart_frame_local_region") {
        this.persistentContractFailures.add(
          `maintenance_cart_derivation_kind:${definition.targetId}`
        );
        continue;
      }
      if (wheelBounds) this.createMaintenanceTargetZone(definition, wheelBounds);
    }

    const cleaner = MAINTENANCE_RUNTIME.cleaner;
    this.maintenanceCleaner = this.physics.add.sprite(
      floor.offsetX + cleaner.position.x,
      cleaner.position.y,
      cleaner.animationId,
      0
    ).setOrigin(0.5, 1)
      .setScale(cleaner.uniformScale)
      .setDepth(PLAYER_DEPTH_BASE + cleaner.position.y);
    this.maintenanceCleaner.play(cleaner.animationId, true);
    this.configureMaintenanceFootBody(
      this.maintenanceCleaner,
      cleaner.position,
      cleaner.footBounds,
      cleaner.uniformScale,
      96,
      128
    );
    this.phaseRuntimeObjects.push(this.maintenanceCleaner);
    this.maintenanceObstacleCollider = this.physics.add.collider(
      this.player,
      [this.maintenanceCart, this.maintenanceCleaner]
    );

    if (wheelBounds) {
      this.maintenanceCoverVisual = this.add.rectangle(
        floor.offsetX + wheelBounds.x,
        wheelBounds.y + wheelBounds.height / 2,
        wheelBounds.width,
        Math.max(5, wheelBounds.height * 0.42),
        0x44505c,
        0.82
      ).setOrigin(0.08, 0.5)
        .setDepth(PLAYER_DEPTH_BASE + wheelBounds.y + wheelBounds.height + 6)
        .setStrokeStyle(1, 0xb9c4cf, 0.76);
      this.phaseRuntimeObjects.push(this.maintenanceCoverVisual);
    }

    try {
      this.ensureHallClockStateSprite(gearDefinition.frameBefore ?? "gear_stuttering");
      const gearBounds = this.deriveClockManifestInteractionBounds(
        this.hallClockStateSprite,
        gearDefinition
      );
      if (gearBounds) this.createMaintenanceTargetZone(gearDefinition, gearBounds);
    } catch (error) {
      this.persistentContractFailures.add(`maintenance_gear_target:${errorMessage(error)}`);
    }

    this.createMaintenanceGuardRuntime();
    this.maintenanceSignature = `${MAINTENANCE_RUNTIME.storyFloor}:${MAINTENANCE_RUNTIME.statePlateId}`;
    this.validateMaintenanceRuntimeBounds();
  }

  private createMaintenanceTargetZone(
    definition: MaintenanceRuntimeTargetDefinition,
    derivedBounds: MapRect
  ): Phaser.GameObjects.Zone {
    const floor = getFloor(1);
    const zone = this.add.zone(
      floor.offsetX + derivedBounds.x + derivedBounds.width / 2,
      derivedBounds.y + derivedBounds.height / 2,
      derivedBounds.width,
      derivedBounds.height
    ).setDepth(PLAYER_DEPTH_BASE + derivedBounds.y + derivedBounds.height + 4);
    this.phaseRuntimeTargets.set(definition.targetId, {
      targetId: definition.targetId,
      entityId: definition.entityId,
      floor: 1,
      boundsObject: zone
    });
    this.phaseRuntimeObjects.push(zone);
    return zone;
  }

  private deriveStoryItemManifestInteractionBounds(
    sprite: Phaser.GameObjects.Sprite,
    definition: MaintenanceRuntimeTargetDefinition
  ): MapRect | null {
    const derivation = definition.boundsDerivation;
    if (derivation.kind !== "visible_story_item_manifest_interaction"
      || !definition.frame
      || sprite.texture.key !== derivation.spritesheetId
      || String(sprite.frame.name) !== definition.frame
      || Math.abs(sprite.scaleX - sprite.scaleY) > 0.000001
      || sprite.scaleX <= 0) {
      this.persistentContractFailures.add(
        `maintenance_story_item_derivation:${definition.targetId}`
      );
      return null;
    }
    const frame = getChapterFour755ManifestFrame(derivation.spritesheetId, definition.frame);
    const interaction = frame?.interactionBounds?.find((candidate) => (
      candidate.id === derivation.interactionId
      && candidate.coordinateSpace === "source_sheet"
    ));
    if (!frame?.pivot || !interaction) {
      this.persistentContractFailures.add(
        `maintenance_story_item_manifest_interaction:${definition.targetId}`
      );
      return null;
    }
    const floor = getFloor(1);
    return {
      x: sprite.x - floor.offsetX
        + (interaction.bounds.x - frame.pivot.x) * sprite.scaleX,
      y: sprite.y + (interaction.bounds.y - frame.pivot.y) * sprite.scaleY,
      width: interaction.bounds.width * sprite.scaleX,
      height: interaction.bounds.height * sprite.scaleY
    };
  }

  private deriveVisibleFrameLocalBounds(
    sprite: Phaser.GameObjects.Sprite,
    sourceFrameSize: { width: number; height: number },
    sourceLocalBounds: MapRect
  ): MapRect | null {
    if (Math.abs(sprite.scaleX - sprite.scaleY) > 0.000001
      || sprite.scaleX <= 0
      || sprite.frame.realWidth !== sourceFrameSize.width
      || sprite.frame.realHeight !== sourceFrameSize.height) {
      this.persistentContractFailures.add("maintenance_cart_frame_local_transform");
      return null;
    }
    const floor = getFloor(1);
    return {
      x: sprite.x - floor.offsetX
        + (sourceLocalBounds.x - sourceFrameSize.width * sprite.originX) * sprite.scaleX,
      y: sprite.y
        + (sourceLocalBounds.y - sourceFrameSize.height * sprite.originY) * sprite.scaleY,
      width: sourceLocalBounds.width * sprite.scaleX,
      height: sourceLocalBounds.height * sprite.scaleY
    };
  }

  private deriveClockManifestInteractionBounds(
    sprite: Phaser.GameObjects.Sprite | null,
    definition: MaintenanceRuntimeTargetDefinition
  ): MapRect | null {
    const derivation = definition.boundsDerivation;
    if (!sprite
      || derivation.kind !== "visible_clock_frame_manifest_world_interaction"
      || sprite.texture.key !== derivation.spritesheetId) {
      this.persistentContractFailures.add("maintenance_clock_visible_frame_missing");
      return null;
    }
    const frameName = String(sprite.frame.name);
    if (frameName !== definition.frameBefore && frameName !== definition.frameAfter) {
      this.persistentContractFailures.add(`maintenance_clock_visible_frame:${frameName}`);
      return null;
    }
    const frame = getChapterFour755ManifestFrame(derivation.spritesheetId, frameName);
    const interactions = frame?.interactionBounds as ReadonlyArray<{
      id: string;
      floor?: StoryFloor;
      coordinateSpace: "source_sheet" | "world";
      bounds: MapRect;
    }> | undefined;
    const interaction = interactions?.find((candidate) => (
      candidate.id === derivation.interactionId
      && candidate.floor === derivation.floor
      && candidate.coordinateSpace === "world"
    ));
    if (!interaction) {
      this.persistentContractFailures.add(`maintenance_clock_manifest_interaction:${frameName}`);
      return null;
    }
    return { ...interaction.bounds };
  }

  private configureMaintenanceFootBody(
    sprite: Phaser.Physics.Arcade.Sprite,
    localPosition: { x: number; y: number },
    localFootBounds: MapRect,
    scale: number,
    sourceWidth: number,
    sourceHeight: number
  ): void {
    const body = sprite.body as Phaser.Physics.Arcade.Body;
    const sourceLeft = localPosition.x - sourceWidth * scale / 2;
    const sourceTop = localPosition.y - sourceHeight * scale;
    body.setAllowGravity(false).setImmovable(true);
    body.pushable = false;
    body.setSize(localFootBounds.width / scale, localFootBounds.height / scale)
      .setOffset(
        (localFootBounds.x - sourceLeft) / scale,
        (localFootBounds.y - sourceTop) / scale
      );
  }

  private validateMaintenanceRuntimeBounds(): void {
    for (const definition of MAINTENANCE_RUNTIME.targetEntities) {
      const binding = this.phaseRuntimeTargets.get(definition.targetId);
      const bounds = binding ? this.outwardPhaseRuntimeBounds(binding) : null;
      if (!bounds
        || bounds.x !== definition.installationBounds.x
        || bounds.y !== definition.installationBounds.y
        || bounds.width !== definition.installationBounds.width
        || bounds.height !== definition.installationBounds.height) {
        this.persistentContractFailures.add(
          `maintenance_runtime_bounds:${definition.targetId}:${JSON.stringify(bounds)}`
        );
      }
    }
  }

  private startOrRestoreMaintenancePush(animate: boolean): void {
    if (!this.maintenanceCleaner || this.maintenancePushCompleted || this.maintenancePushTween) return;
    this.cancelMaintenanceFailedPushAttempt();
    this.maintenanceObstacleCollider?.destroy();
    this.maintenanceObstacleCollider = null;
    if (this.maintenanceCart) {
      this.maintenanceCart.disableBody(false, true);
      this.maintenanceCart.destroy();
      this.maintenanceCart = null;
    }
    this.maintenanceCleaner.disableBody(false, false);
    this.maintenanceCleaner
      .setTexture(MAINTENANCE_RUNTIME.repairedPush.animationId, 0)
      .setPosition(
        getFloor(1).offsetX + MAINTENANCE_RUNTIME.repairedPush.from.x,
        MAINTENANCE_RUNTIME.repairedPush.from.y
      )
      .setVisible(true);
    if (!animate) {
      this.maintenanceCleaner
        .setPosition(
          getFloor(1).offsetX + MAINTENANCE_RUNTIME.repairedPush.to.x,
          MAINTENANCE_RUNTIME.repairedPush.to.y
        )
        .setDepth(PLAYER_DEPTH_BASE + MAINTENANCE_RUNTIME.repairedPush.to.y);
      this.settleMaintenanceCleanerAfterPush();
      this.maintenancePushCompleted = true;
      return;
    }
    this.maintenanceCleaner.play(MAINTENANCE_RUNTIME.repairedPush.animationId, true);
    this.safeBridgeEmit("maintenance_cart_roll_started", {
      phase: "maintenance_repair",
      durationMs: MAINTENANCE_RUNTIME.repairedPush.durationMs
    });
    this.maintenancePushTween = this.tweens.add({
      targets: this.maintenanceCleaner,
      x: getFloor(1).offsetX + MAINTENANCE_RUNTIME.repairedPush.to.x,
      y: MAINTENANCE_RUNTIME.repairedPush.to.y,
      duration: MAINTENANCE_RUNTIME.repairedPush.durationMs,
      ease: "Sine.InOut",
      onUpdate: () => {
        this.maintenanceCleaner?.setDepth(PLAYER_DEPTH_BASE + (this.maintenanceCleaner?.y ?? 0));
      },
      onComplete: () => {
        this.maintenancePushTween = null;
        this.maintenancePushCompleted = true;
        this.settleMaintenanceCleanerAfterPush();
      }
    });
  }

  private scheduleMaintenanceFailedPushAttempt(delayMs = 1100): void {
    if (this.maintenanceAttemptTimer
      || this.maintenanceAttemptTween
      || this.maintenancePushTween
      || this.maintenancePushCompleted) return;
    this.maintenanceAttemptTimer = this.time.delayedCall(delayMs, () => {
      this.maintenanceAttemptTimer = null;
      this.playMaintenanceFailedPushAttempt();
    });
  }

  private playMaintenanceFailedPushAttempt(): void {
    const state = this.bridge.getState();
    if (state.chapter4.phase !== "maintenance_repair"
      || hasChapterFourFact(state, "cart_wheel_repaired")
      || !this.maintenanceCart
      || !this.maintenanceCleaner
      || this.maintenanceAttemptTween) return;
    const floor = getFloor(1);
    if (!this.maintenanceAttemptSprite?.active) {
      this.maintenanceAttemptSprite = this.add.sprite(
        floor.offsetX + MAINTENANCE_RUNTIME.repairedPush.from.x,
        MAINTENANCE_RUNTIME.repairedPush.from.y,
        MAINTENANCE_RUNTIME.repairedPush.animationId,
        0
      ).setOrigin(0.5, 1)
        .setScale(MAINTENANCE_RUNTIME.cleaner.uniformScale)
        .setDepth(PLAYER_DEPTH_BASE + MAINTENANCE_RUNTIME.repairedPush.from.y + 2)
        .setVisible(false);
      this.phaseRuntimeObjects.push(this.maintenanceAttemptSprite);
    }
    this.maintenanceCart.setVisible(false);
    this.maintenanceCleaner.setVisible(false);
    this.maintenanceAttemptSprite
      .setPosition(
        floor.offsetX + MAINTENANCE_RUNTIME.repairedPush.from.x,
        MAINTENANCE_RUNTIME.repairedPush.from.y
      )
      .setVisible(true)
      .play(MAINTENANCE_RUNTIME.repairedPush.animationId, true);
    this.maintenanceAttemptTween = this.tweens.add({
      targets: this.maintenanceAttemptSprite,
      y: MAINTENANCE_RUNTIME.repairedPush.from.y - 5,
      duration: 240,
      hold: 80,
      yoyo: true,
      ease: "Sine.InOut",
      onUpdate: () => {
        this.maintenanceAttemptSprite?.setDepth(
          PLAYER_DEPTH_BASE + (this.maintenanceAttemptSprite?.y ?? 0) + 2
        );
      },
      onComplete: () => {
        this.maintenanceAttemptTween = null;
        this.maintenanceAttemptSprite?.stop().setVisible(false);
        this.maintenanceCart?.setVisible(true);
        this.maintenanceCleaner?.setVisible(true).play(
          MAINTENANCE_RUNTIME.cleaner.animationId,
          true
        );
        this.scheduleMaintenanceFailedPushAttempt(2800);
      }
    });
  }

  private cancelMaintenanceFailedPushAttempt(): void {
    this.maintenanceAttemptTimer?.remove(false);
    this.maintenanceAttemptTimer = null;
    this.maintenanceAttemptTween?.remove();
    this.maintenanceAttemptTween = null;
    this.maintenanceAttemptSprite?.stop().setVisible(false);
    this.maintenanceCart?.setVisible(true);
    if (this.maintenanceCleaner?.active && !this.maintenancePushCompleted) {
      this.maintenanceCleaner.setVisible(true).play(
        MAINTENANCE_RUNTIME.cleaner.animationId,
        true
      );
    }
  }

  private settleMaintenanceCleanerAfterPush(): void {
    const cleaner = this.maintenanceCleaner;
    if (!cleaner?.active) return;
    const floor = getFloor(1);
    const finalCartPosition = {
      x: MAINTENANCE_RUNTIME.repairedPush.to.x
        + MAINTENANCE_RUNTIME.cleaningCart.position.x
        - MAINTENANCE_RUNTIME.repairedPush.from.x,
      y: MAINTENANCE_RUNTIME.repairedPush.to.y
    };
    const finalCleanerPosition = {
      x: MAINTENANCE_RUNTIME.repairedPush.to.x
        + MAINTENANCE_RUNTIME.cleaner.position.x
        - MAINTENANCE_RUNTIME.repairedPush.from.x,
      y: MAINTENANCE_RUNTIME.repairedPush.to.y
    };
    if (!this.maintenanceSettledCart?.active) {
      this.maintenanceSettledCart = this.add.sprite(
        floor.offsetX + finalCartPosition.x,
        finalCartPosition.y,
        MAINTENANCE_RUNTIME.cleaningCart.texture,
        0
      ).setOrigin(0.5, 1)
        .setScale(MAINTENANCE_RUNTIME.cleaningCart.uniformScale)
        .setDepth(PLAYER_DEPTH_BASE + finalCartPosition.y);
      this.phaseRuntimeObjects.push(this.maintenanceSettledCart);
    }
    cleaner.stop()
      .setTexture("cleaner_rest", 0)
      .setOrigin(0.5, 1)
      .setScale(MAINTENANCE_RUNTIME.cleaner.uniformScale)
      .setPosition(floor.offsetX + finalCleanerPosition.x, finalCleanerPosition.y)
      .setDepth(PLAYER_DEPTH_BASE + finalCleanerPosition.y + 1)
      .setVisible(true);
  }

  private createMaintenanceGuardRuntime(): void {
    const floor = getFloor(1);
    const guard = MAINTENANCE_RUNTIME.guard;
    this.maintenanceGuardState = createChapterFourMaintenanceGuardState();
    this.maintenanceGuardPresentationState = createChapterFourGuardPresentationState();
    this.maintenanceGuard = this.physics.add.sprite(
      floor.offsetX + guard.position.x,
      guard.position.y,
      guard.animationId,
      0
    ).setOrigin(0.5, 1)
      .setScale(guard.uniformScale)
      .setDepth(PLAYER_DEPTH_BASE + guard.position.y);
    this.maintenanceGuard.play(guard.animationId, true);
    this.maintenanceGuardVisualId = guard.animationId;
    this.maintenanceGuardTravelDirection = "side";
    this.maintenanceGuardTravelFlipX = true;
    this.maintenanceGuard.setFlipX(this.maintenanceGuardTravelFlipX);
    const body = this.maintenanceGuard.body as Phaser.Physics.Arcade.Body;
    body.setAllowGravity(false).setImmovable(false);
    body.pushable = false;
    const sourceWidth = 96;
    const sourceHeight = 128;
    const sourceFootWidth = guard.footBox.width / guard.uniformScale;
    const sourceFootHeight = guard.footBox.height / guard.uniformScale;
    body.setSize(sourceFootWidth, sourceFootHeight).setOffset(
      (sourceWidth - sourceFootWidth) / 2,
      sourceHeight - sourceFootHeight
    );
    this.positionMaintenanceGuardFoot(guard.position);
    this.maintenanceGuardWallCollider = this.physics.add.collider(
      this.maintenanceGuard,
      this.staticObstacles
    );
    this.maintenanceGuardPlayerOverlap = this.physics.add.overlap(
      this.player,
      this.maintenanceGuard,
      () => this.tryMaintenancePatrolCapture()
    );
    this.maintenanceGuardVision = this.add.graphics().setDepth(PLAYER_DEPTH_BASE - 240);
    this.maintenanceGuardAlert = this.add.text(
      this.maintenanceGuard.x,
      this.maintenanceGuard.y - 92,
      "!",
      {
        fontFamily: "'Fusion Pixel', monospace",
        fontSize: "24px",
        color: "#ffef8a",
        stroke: "#5b1b1b",
        strokeThickness: 4
      }
    ).setOrigin(0.5).setDepth(PLAYER_DEPTH_BASE + guard.position.y + 90).setVisible(false);
    this.phaseRuntimeObjects.push(
      this.maintenanceGuard,
      this.maintenanceGuardVision,
      this.maintenanceGuardAlert
    );
  }

  private updateMaintenanceGuard(deltaMs: number): void {
    const state = this.bridge?.getState();
    if (!state
      || state.chapter4.phase !== "maintenance_repair"
      || state.chapter4.guardMode !== "patrol"
      || !this.maintenanceGuard
      || !this.maintenanceGuardState) return;
    const visible = this.currentFloor === 1;
    this.maintenanceGuard.setVisible(visible);
    this.maintenanceGuardVision?.setVisible(visible);
    this.maintenanceGuardAlert?.setVisible(
      visible && this.maintenanceGuardPresentationState?.phase === "notice"
    );
    if (!visible || this.pendingStoryRequest?.intentType === "recover_from_maintenance_patrol") {
      this.maintenanceGuard.setVelocity(0, 0);
      return;
    }
    const floor = getFloor(1);
    const playerFoot = this.playerFootPoint(floor);
    const guardFoot = this.maintenanceGuardFootPoint(floor);
    if (!guardFoot) {
      this.maintenanceGuard.setVelocity(0, 0);
      return;
    }
    const next = stepChapterFourMaintenanceGuard(this.maintenanceGuardState, {
      deltaMs,
      guardPosition: { x: guardFoot.x, y: guardFoot.y },
      playerPosition: { x: playerFoot.x, y: playerFoot.y },
      walls: getFloor(1).staticCollisions
    });
    this.maintenanceGuardState = {
      ...next.state,
      position: { x: guardFoot.x, y: guardFoot.y }
    };
    if (next.enteredPursuit) {
      this.safeBridgeEmit("maintenance_patrol_warning", {
        phase: state.chapter4.phase,
        floor: "A1",
        guardMode: next.state.mode
      });
    }
    this.maintenanceGuard
      .setVelocity(next.desiredVelocity.x, next.desiredVelocity.y)
      .setDepth(PLAYER_DEPTH_BASE + guardFoot.y + 2);
    const patrolIdleVariant = [
      "west_north",
      "east_south"
    ].includes(next.state.previousWaypointId ?? "")
      ? "watch" as const
      : "list" as const;
    const presentation = stepChapterFourGuardPresentation(
      this.maintenanceGuardPresentationState ?? createChapterFourGuardPresentationState(),
      {
        deltaMs,
        authorityMode: next.state.mode,
        playerVisible: next.playerVisible,
        enteredPursuit: next.enteredPursuit,
        disengaged: next.disengaged,
        desiredMotion: next.desiredVelocity,
        authorityHeading: next.state.heading,
        patrolIdleVariant
      }
    );
    this.maintenanceGuardPresentationState = presentation.state;
    this.applyMaintenanceGuardPresentation(presentation);
    this.playMaintenanceGuardAnimation(presentation.animationId);
    this.paintMaintenanceGuardVision(presentation);
    this.maintenanceGuardAlert
      ?.setPosition(this.maintenanceGuard.x, this.maintenanceGuard.y - 92)
      .setDepth(PLAYER_DEPTH_BASE + this.maintenanceGuard.y + 90)
      .setText(presentation.alertText)
      .setVisible(presentation.alertVisible);
    this.tryMaintenancePatrolCapture();
  }

  private applyMaintenanceGuardPresentation(
    presentation: ChapterFourGuardPresentationResult
  ): void {
    this.maintenanceGuardTravelDirection = presentation.state.direction;
    this.maintenanceGuardTravelFlipX = presentation.state.flipX;
    this.maintenanceGuard?.setFlipX(presentation.state.flipX);
  }

  private playMaintenanceGuardAnimation(animationId: FinaleNpcAnimationId): void {
    const guard = this.maintenanceGuard;
    if (!guard?.active || this.maintenanceGuardVisualId === animationId) return;
    const floor = getFloor(1);
    const foot = this.maintenanceGuardFootPoint(floor);
    const asset = FINALE_NPC_ANIMATIONS[animationId];
    const scale = MAINTENANCE_RUNTIME.guard.uniformScale;
    const sourceFootWidth = MAINTENANCE_RUNTIME.guard.footBox.width / scale;
    const sourceFootHeight = MAINTENANCE_RUNTIME.guard.footBox.height / scale;
    guard.play(animationId, true);
    const body = guard.body as Phaser.Physics.Arcade.Body;
    body.setSize(sourceFootWidth, sourceFootHeight).setOffset(
      (asset.frameWidth - sourceFootWidth) / 2,
      asset.frameHeight - sourceFootHeight
    );
    if (foot) this.positionMaintenanceGuardFoot(foot);
    this.maintenanceGuardVisualId = animationId;
  }

  private resolveFinalChaseGuardTravelAnimation(
    velocity: { x: number; y: number }
  ): FinaleNpcAnimationId {
    const speedThreshold = 8;
    const previousDirection = this.finalChaseGuardTravelDirection;
    const previousFlipX = this.finalChaseGuardTravelFlipX;
    const absX = Math.abs(velocity.x);
    const absY = Math.abs(velocity.y);
    let direction = previousDirection;
    let flipX = previousFlipX;
    if (Math.hypot(velocity.x, velocity.y) >= speedThreshold) {
      if (absX >= absY) {
        direction = "side";
        flipX = velocity.x < 0;
      } else {
        direction = velocity.y < 0 ? "up" : "down";
        flipX = false;
      }
    }
    this.finalChaseGuardTravelDirection = direction;
    this.finalChaseGuardTravelFlipX = flipX;
    this.chaseGuard?.setFlipX(flipX);
    if (direction === "up") return "guard_walk_up";
    if (direction === "down") return "guard_walk_down";
    return "guard_walk";
  }

  private paintMaintenanceGuardVision(
    presentation: ChapterFourGuardPresentationResult
  ): void {
    const graphics = this.maintenanceGuardVision;
    const state = this.maintenanceGuardState;
    if (!graphics || !state) return;
    const floor = getFloor(1);
    const x = floor.offsetX + state.position.x;
    const y = state.position.y;
    // The cone angle remains the exact authority heading so the readable
    // detection area does not diverge from LOS. Only the sprite facing uses
    // presentation hysteresis.
    const headingAngle = Math.atan2(state.heading.y, state.heading.x);
    const halfAngle = CHAPTER_FOUR_MAINTENANCE_GUARD_RULES.coneHalfAngleDegrees * Math.PI / 180;
    graphics.clear();
    graphics.fillStyle(presentation.visionColor, presentation.visionConeAlpha);
    graphics.beginPath();
    graphics.moveTo(x, y);
    graphics.arc(
      x,
      y,
      CHAPTER_FOUR_MAINTENANCE_GUARD_RULES.coneRange * presentation.visionRangeScale,
      headingAngle - halfAngle,
      headingAngle + halfAngle,
      false
    );
    graphics.closePath();
    graphics.fillPath();
    graphics.fillStyle(presentation.visionColor, presentation.visionCloseAlpha);
    graphics.fillCircle(x, y, CHAPTER_FOUR_MAINTENANCE_GUARD_RULES.closeRadius);
  }

  private tryMaintenancePatrolCapture(): void {
    const state = this.bridge.getState();
    if (state.chapter4.phase !== "maintenance_repair"
      || state.chapter4.guardMode !== "patrol"
      || this.maintenanceGuardState?.mode !== "pursuit"
      || this.pendingStoryRequest
      || this.time.now < this.storyRetryNotBeforeMs
      || !this.maintenanceGuard) return;
    const playerBody = this.player.body as Phaser.Physics.Arcade.Body | undefined;
    const guardBody = this.maintenanceGuard.body as Phaser.Physics.Arcade.Body | undefined;
    if (!playerBody || !guardBody) return;
    const floor = getFloor(1);
    if (!chapterFourGuardFootContact({
      x: guardBody.center.x - floor.offsetX,
      y: guardBody.center.y
    }, {
      x: playerBody.left - floor.offsetX,
      y: playerBody.top,
      width: playerBody.width,
      height: playerBody.height
    })) return;
    this.requestStoryIntent({ type: "recover_from_maintenance_patrol" });
  }

  private resetMaintenanceGuardAfterRecovery(): void {
    const floor = getFloor(1);
    this.maintenanceGuardState = createChapterFourMaintenanceGuardRecoveryState();
    this.maintenanceGuardPresentationState = createChapterFourGuardPresentationState();
    this.positionMaintenanceGuardFoot(this.maintenanceGuardState.position);
    this.maintenanceGuardTravelDirection = "side";
    this.maintenanceGuardTravelFlipX = false;
    this.maintenanceGuard?.setVelocity(0, 0).setFlipX(false);
    this.maintenanceGuardVisualId = null;
    this.playMaintenanceGuardAnimation("guard_walk");
    this.maintenanceGuardAlert?.setVisible(false);
    this.player.setPosition(floor.offsetX + 836, 716)
      .setVelocity(0, 0)
      .setDepth(PLAYER_TOP_DEPTH);
    this.animator.setFacing("up");
    this.cameras.main.centerOn(this.player.x, this.player.y);
    this.paintMaintenanceGuardVision(stepChapterFourGuardPresentation(
      this.maintenanceGuardPresentationState,
      {
        deltaMs: 0,
        authorityMode: this.maintenanceGuardState.mode,
        playerVisible: false,
        enteredPursuit: false,
        disengaged: false,
        desiredMotion: { x: 0, y: 0 },
        authorityHeading: this.maintenanceGuardState.heading,
        patrolIdleVariant: "list"
      }
    ));
  }

  private maintenanceGuardFootPoint(
    floor: FloorDefinition
  ): { x: number; y: number; worldX: number } | null {
    const body = this.maintenanceGuard?.body as Phaser.Physics.Arcade.Body | undefined;
    if (!body) return null;
    return {
      x: body.center.x - floor.offsetX,
      y: body.center.y,
      worldX: body.center.x
    };
  }

  /** Spawn/recovery-only placement; ordinary updates are owned by Arcade velocity and collision. */
  private positionMaintenanceGuardFoot(position: { x: number; y: number }): void {
    if (!this.maintenanceGuard) return;
    const floor = getFloor(1);
    this.maintenanceGuard.setPosition(
      floor.offsetX + position.x,
      position.y + MAINTENANCE_RUNTIME.guard.footBox.height / 2
    );
    (this.maintenanceGuard.body as Phaser.Physics.Arcade.Body | undefined)
      ?.updateFromGameObject();
  }

  private ensureMorningCheckinRuntime(state: GameState): void {
    if (!this.hasPhaseRuntimeTargets(MORNING_CHECKIN_RUNTIME_TARGET_IDS)) {
      this.destroyPhaseRuntime("checkin_runtime_recreate");
      this.createMorningCheckinRuntimeTarget(
        "a1_campus_card_reader",
        0x16394a,
        0x7ce9ff,
        "校园卡"
      );
      this.createMorningCheckinRuntimeTarget(
        "a1_attendance_paper_slot",
        0x493917,
        0xffd36f,
        "纸条"
      );
    }
    this.ensureMorningCheckinStudents();
    const cardAccepted = state.chapter4.checkinCardAccepted
      || hasChapterFourFact(state, "checkin_card_accepted");
    const paperAccepted = state.chapter4.checkinPaperAccepted
      || hasChapterFourFact(state, "checkin_paper_accepted");
    this.setPhaseRuntimeTargetVisible("a1_campus_card_reader", !cardAccepted);
    this.setPhaseRuntimeTargetVisible("a1_attendance_paper_slot", !paperAccepted);
    const cardVisual = this.morningCheckinVisuals.get("a1_campus_card_reader");
    if (cardVisual) this.paintMorningCheckinFixture(
      "a1_campus_card_reader",
      cardVisual.details,
      cardVisual.fixture.getBounds(),
      cardAccepted
    );
    cardVisual?.label.setText(cardAccepted ? "已刷卡" : "校园卡");
    const paperVisual = this.morningCheckinVisuals.get("a1_attendance_paper_slot");
    if (paperVisual) this.paintMorningCheckinFixture(
      "a1_attendance_paper_slot",
      paperVisual.details,
      paperVisual.fixture.getBounds(),
      paperAccepted
    );
    paperVisual?.label.setText(paperAccepted ? "已签到" : "纸条");
  }

  private ensureMorningCheckinStudents(): void {
    if (this.morningCheckinStudents.some((student) => student.active)) return;
    const floor = getFloor(1);
    const students: ReadonlyArray<{
      x: number;
      y: number;
      animationId: FinaleNpcAnimationId;
      flipX: boolean;
    }> = Object.freeze([
      { x: 582, y: 700, animationId: "student_phone_glance", flipX: false },
      { x: 1078, y: 704, animationId: "student_adjust_bag", flipX: true },
      { x: 1110, y: 570, animationId: "student_idle", flipX: true }
    ]);
    this.morningCheckinStudents = students.map((entry) => {
      const asset = FINALE_NPC_ANIMATIONS[entry.animationId];
      const student = this.add.sprite(
        floor.offsetX + entry.x,
        entry.y,
        entry.animationId,
        0
      ).setOrigin(asset.footAnchor.x, asset.footAnchor.y)
        .setScale(BAKERY_RUNTIME.crowd.displayScale)
        .setFlipX(entry.flipX)
        .setDepth(PLAYER_DEPTH_BASE + entry.y);
      if (asset.frameCount > 1) student.play(entry.animationId, true);
      this.phaseRuntimeObjects.push(student);
      return student;
    });
  }

  private createMorningCheckinRuntimeTarget(
    targetId: string,
    fillColor: number,
    strokeColor: number,
    labelText: string
  ): Phaser.GameObjects.Zone | null {
    const installation = getChapterFour755RuntimeTargetInstallation(
      targetId as keyof typeof CHAPTER_FOUR_755_INTERACTION_TARGETS
    );
    const target = CHAPTER_FOUR_755_INTERACTION_TARGETS[
      targetId as keyof typeof CHAPTER_FOUR_755_INTERACTION_TARGETS
    ];
    const layoutTarget = MORNING_CHECKIN_RUNTIME.targetEntities.find(
      (entry) => entry.targetId === targetId
    );
    const floor = installation ? displayFloorFor(target?.boundsSource.floor ?? "") : null;
    if (!installation
      || !layoutTarget
      || installation.entityId !== layoutTarget.entityId
      || !rectEquals(installation.bounds, layoutTarget.installationBounds)
      || !floor) {
      this.persistentContractFailures.add(`phase_runtime_installation_missing:${targetId}`);
      return null;
    }
    const bounds = installation.bounds;
    const fixture = this.add.rectangle(
      getFloor(floor).offsetX + rectCenterX(bounds),
      rectCenterY(bounds),
      bounds.width,
      bounds.height,
      fillColor,
      0.01
    ).setDepth(PLAYER_DEPTH_BASE + rectBottom(bounds) + 6)
      .setStrokeStyle(1, strokeColor, 0.01)
      .setVisible(true);
    const measured = fixture.getBounds();
    const derived = {
      x: Math.floor(measured.left - getFloor(floor).offsetX),
      y: Math.floor(measured.top),
      width: Math.ceil(measured.right - getFloor(floor).offsetX)
        - Math.floor(measured.left - getFloor(floor).offsetX),
      height: Math.ceil(measured.bottom) - Math.floor(measured.top)
    };
    if (!rectEquals(derived, bounds)) {
      fixture.destroy();
      this.persistentContractFailures.add(
        `morning_checkin_visible_bounds:${targetId}:${JSON.stringify(derived)}`
      );
      return null;
    }
    const details = this.add.graphics()
      .setDepth(PLAYER_DEPTH_BASE + rectBottom(bounds) + 6);
    this.paintMorningCheckinFixture(targetId, details, fixture.getBounds(), false);
    const label = this.add.text(
      getFloor(floor).offsetX + rectCenterX(derived),
      derived.y - 8,
      labelText,
      {
        fontFamily: "'Fusion Pixel', monospace",
        fontSize: "8px",
        color: "#f7f1dc",
        backgroundColor: "#07111dcc",
        padding: { x: 2, y: 1 }
      }
    ).setOrigin(0.5, 1)
      .setDepth(PLAYER_DEPTH_BASE + rectBottom(bounds) + 7);
    const zone = this.add.zone(
      getFloor(floor).offsetX + rectCenterX(derived),
      rectCenterY(derived),
      derived.width,
      derived.height
    );
    const zoneBounds = zone.getBounds();
    const measuredZone = {
      x: Math.floor(zoneBounds.left - getFloor(floor).offsetX),
      y: Math.floor(zoneBounds.top),
      width: Math.ceil(zoneBounds.right - getFloor(floor).offsetX)
        - Math.floor(zoneBounds.left - getFloor(floor).offsetX),
      height: Math.ceil(zoneBounds.bottom) - Math.floor(zoneBounds.top)
    };
    if (!rectEquals(measuredZone, bounds)) {
      fixture.destroy();
      label.destroy();
      zone.destroy();
      this.persistentContractFailures.add(
        `morning_checkin_zone_bounds:${targetId}:${JSON.stringify(measuredZone)}`
      );
      return null;
    }
    this.phaseRuntimeTargets.set(targetId, {
      targetId,
      entityId: installation.entityId,
      floor,
      boundsObject: zone
    });
    this.phaseRuntimeObjects.push(fixture, details, label, zone);
    this.morningCheckinVisuals.set(targetId, { fixture, details, label });
    return zone;
  }

  private paintMorningCheckinFixture(
    targetId: string,
    graphics: Phaser.GameObjects.Graphics,
    bounds: Phaser.Geom.Rectangle,
    accepted: boolean
  ): void {
    const x = Math.round(bounds.left);
    const y = Math.round(bounds.top);
    const width = Math.round(bounds.width);
    const height = Math.round(bounds.height);
    const statusColor = accepted ? 0x7ee79a : 0x75e6ff;
    graphics.clear();

    if (targetId === "a1_campus_card_reader") {
      graphics.fillStyle(0x07131c, 0.98);
      graphics.fillPoints([
        new Phaser.Geom.Point(x + 3, y),
        new Phaser.Geom.Point(x + width - 3, y),
        new Phaser.Geom.Point(x + width, y + 4),
        new Phaser.Geom.Point(x + width - 2, y + height),
        new Phaser.Geom.Point(x + 2, y + height),
        new Phaser.Geom.Point(x, y + 4)
      ], true);
      graphics.lineStyle(1, 0x9eafaa, 0.96).strokeRect(x + 2, y + 3, width - 4, height - 5);
      graphics.fillStyle(0xbadfdc, 1).fillRect(x + 6, y + 5, width - 12, 8);
      graphics.fillStyle(0x1a6271, 0.85).fillRect(x + 7, y + 6, width - 14, 2);
      graphics.fillStyle(statusColor, 0.95).fillRect(x + 7, y + 9, width - 14, 1);
      graphics.fillStyle(0x0b0908, 1).fillRect(x + 7, y + height - 7, width - 14, 2);
      graphics.fillStyle(statusColor, 1).fillRect(x + width - 7, y + height - 5, 3, 2);
      graphics.fillStyle(0x9aa9a9, 0.9).fillRect(x + 5, y + height - 5, 2, 2);
      graphics.fillStyle(0xe8f2e9, 1).fillRect(x + 9, y + height - 4, 6, 1);
      return;
    }

    graphics.fillStyle(0x261c13, 0.99);
    graphics.fillPoints([
      new Phaser.Geom.Point(x + 3, y + 3),
      new Phaser.Geom.Point(x + width - 3, y + 3),
      new Phaser.Geom.Point(x + width, y + 7),
      new Phaser.Geom.Point(x + width - 2, y + height),
      new Phaser.Geom.Point(x + 2, y + height),
      new Phaser.Geom.Point(x, y + 7)
    ], true);
    graphics.lineStyle(1, accepted ? 0x94d7a1 : 0xc89a55, 0.98)
      .strokeRect(x + 2, y + 6, width - 4, height - 8);
    graphics.fillStyle(0xf0e4c8, 1).fillRect(x + 8, y, width - 16, 9);
    graphics.fillStyle(0xc1b090, 1).fillRect(x + 10, y + 2, width - 20, 1);
    graphics.fillStyle(0xc1b090, 1).fillRect(x + 10, y + 5, width - 23, 1);
    graphics.fillStyle(0x080707, 1).fillRect(x + 5, y + 11, width - 10, 4);
    graphics.fillStyle(0x705032, 1).fillRect(x + 7, y + 12, width - 14, 1);
    graphics.fillStyle(statusColor, 1).fillRect(x + width - 8, y + height - 6, 3, 3);
    graphics.fillStyle(0xc8b27a, 0.92).fillRect(x + 6, y + height - 5, width - 18, 2);
    graphics.fillStyle(0xe0c68c, 1).fillRect(x + 3, y + 7, 1, 1);
    graphics.fillStyle(0xe0c68c, 1).fillRect(x + width - 4, y + 7, 1, 1);
  }

  private createPhaseDecorationRect(
    floorNumber: DisplayFloor,
    x: number,
    y: number,
    width: number,
    height: number,
    fillColor: number,
    fillAlpha: number,
    strokeColor: number
  ): void {
    const floor = getFloor(floorNumber);
    const rectangle = this.add.rectangle(
      floor.offsetX + x + width / 2,
      y + height / 2,
      width,
      height,
      fillColor,
      fillAlpha
    ).setDepth(PLAYER_DEPTH_BASE + y + height + 2)
      .setStrokeStyle(1, strokeColor, 0.76);
    this.phaseRuntimeObjects.push(rectangle);
  }

  private setPhaseRuntimeTargetVisible(targetId: string, visible: boolean): void {
    this.phaseRuntimeTargets.get(targetId)?.boundsObject.setVisible(visible);
  }

  private outwardPhaseRuntimeBounds(binding: PhaseRuntimeTargetBinding): MapRect | null {
    if (!binding.boundsObject.active || !binding.boundsObject.visible) return null;
    const floor = getFloor(binding.floor);
    const bounds = binding.boundsObject.getBounds();
    const left = Math.floor(bounds.left - floor.offsetX);
    const top = Math.floor(bounds.top);
    const right = Math.ceil(bounds.right - floor.offsetX);
    const bottom = Math.ceil(bounds.bottom);
    const result = { x: left, y: top, width: right - left, height: bottom - top };
    return rectInsideFloor(result) ? result : null;
  }

  private destroyPhaseRuntime(reason: string): void {
    this.destroyTask11Runtime(reason);
    this.maintenanceAttemptTimer?.remove(false);
    this.maintenanceAttemptTimer = null;
    this.maintenanceAttemptTween?.stop();
    this.maintenanceAttemptTween?.remove();
    this.maintenanceAttemptTween = null;
    this.maintenancePushTween?.stop();
    this.maintenancePushTween?.remove();
    this.maintenancePushTween = null;
    this.maintenanceObstacleCollider?.destroy();
    this.maintenanceObstacleCollider = null;
    this.maintenanceGuardWallCollider?.destroy();
    this.maintenanceGuardWallCollider = null;
    this.maintenanceGuardPlayerOverlap?.destroy();
    this.maintenanceGuardPlayerOverlap = null;
    for (const object of this.phaseRuntimeObjects) {
      if (object.active) object.destroy();
    }
    this.phaseRuntimeObjects = [];
    this.phaseRuntimeTargets.clear();
    this.morningCheckinVisuals.clear();
    this.maintenanceSignature = "";
    this.maintenanceCart = null;
    this.maintenanceCleaner = null;
    this.maintenancePryBar = null;
    this.maintenanceOilBottle = null;
    this.maintenanceCoverVisual = null;
    this.maintenanceSettledCart = null;
    this.maintenanceAttemptSprite = null;
    this.maintenanceObstacleGroup = null;
    this.maintenancePushCompleted = false;
    this.maintenanceGuardState = null;
    this.maintenanceGuardPresentationState = null;
    this.maintenanceGuard = null;
    this.maintenanceGuardVision = null;
    this.maintenanceGuardAlert = null;
    this.maintenanceGuardVisualId = null;
    this.maintenanceGuardTravelDirection = "side";
    this.maintenanceGuardTravelFlipX = true;
    this.morningCheckinStudents = [];
    this.persistentContractFailures.delete(`phase_runtime_cleanup:${reason}`);
  }

  private ensureFinalChaseRuntime(state: GameState): void {
    if (state.chapter4.phase !== "final_chase") {
      this.destroyChaseRuntime();
      return;
    }
    if (this.finalChaseState?.attempt === state.chapter4.chaseAttempt && this.chaseGuard?.active) {
      return;
    }
    // A new runtime is created only from committed persistent state. Failed
    // or stale intent responses therefore cannot move either actor.
    this.destroyChaseRuntime();
    this.finalChaseState = createChapterFourFinalChaseState(state.chapter4.chaseAttempt);
    this.finalChaseAudioBand = null;
    this.finalChaseCloseVoicePlayed = false;
    this.finalChaseFloorVoicePlayed = false;
    const floor = getFloor(1);
    this.currentFloor = 1;
    this.player.setPosition(
      floor.offsetX + FINAL_CHASE_RUNTIME.playerStart.x,
      FINAL_CHASE_RUNTIME.playerStart.y
    ).setVelocity(0, 0).setDepth(PLAYER_TOP_DEPTH);
    this.animator.setFacing("up");
    this.configureCameraForCurrentFloor();
    this.cameras.main.centerOn(this.player.x, this.player.y);

    this.chaseGuard = this.physics.add.sprite(
      floor.offsetX + FINAL_CHASE_RUNTIME.guardSpawn.x,
      FINAL_CHASE_RUNTIME.guardSpawn.y,
      "guard_walk",
      0
    ).setOrigin(0.5, 1)
      .setScale(0.68)
      .setDepth(PLAYER_DEPTH_BASE + FINAL_CHASE_RUNTIME.guardSpawn.y + 2)
      .setVisible(false);
    this.chaseGuard.play("guard_walk", true);
    this.finalChaseGuardTravelDirection = "side";
    this.finalChaseGuardTravelFlipX = false;
    const body = this.chaseGuard.body as Phaser.Physics.Arcade.Body;
    body.setAllowGravity(false).setImmovable(false);
    body.pushable = false;
    body.setSize(
      LAYOUT.playerFootBoxContract.sourceFootBox.width,
      LAYOUT.playerFootBoxContract.sourceFootBox.height
    ).setOffset(
      LAYOUT.playerFootBoxContract.sourceFootBox.x,
      LAYOUT.playerFootBoxContract.sourceFootBox.y
    );
    this.chaseGuardStaticCollider = this.physics.add.collider(this.chaseGuard, this.staticObstacles);
    this.chaseGuardPlateCollider = this.physics.add.collider(this.chaseGuard, this.plateObstacles);
  }

  private updateFinalChaseRuntime(deltaMs: number): void {
    const committed = this.bridge?.getState();
    const runtime = this.finalChaseState;
    const guard = this.chaseGuard;
    if (!committed || committed.chapter4.phase !== "final_chase" || !runtime || !guard) return;
    const playerFloorNumber = this.currentFloor === 2 ? 2 : 1;
    const playerFloor = getFloor(playerFloorNumber);
    const guardFloorNumber: DisplayFloor = runtime.guardFloor === "A2" ? 2 : 1;
    const guardFloor = getFloor(guardFloorNumber);
    const playerFoot = this.playerFootPoint(playerFloor);
    const guardBody = guard.body as Phaser.Physics.Arcade.Body;
    const playerBody = this.player.body as Phaser.Physics.Arcade.Body;
    const sameFloor = playerFloorNumber === guardFloorNumber;
    const guardContact = sameFloor && chapterFourFinalChaseFootContact(
      {
        x: guardBody.center.x - guardFloor.offsetX,
        y: guardBody.center.y
      },
      {
        x: playerBody.x - playerFloor.offsetX,
        y: playerBody.y,
        width: playerBody.width,
        height: playerBody.height
      }
    );
    const playerInsideFinish = playerFloorNumber === 2
      && pointInsideRect({ x: playerFoot.x, y: playerFoot.y }, FINAL_CHASE_RUNTIME.finishThreshold.bounds);
    this.finalChaseInsideFinish = playerInsideFinish;
    this.finalChaseContact = guardContact;
    const a1Stair = getFloor(1).stairLandings.find((landing) => landing.targetStoryFloor === "A2");
    const playerEnteredMainStair = playerFloorNumber === 1
      && Boolean(a1Stair && pointInsideRect({ x: playerFoot.x, y: playerFoot.y }, a1Stair.bounds));
    const committedStoryFloor: StoryFloor = committed.chapter4.floor === "A2" ? "A2" : "A1";
    const expectedPlate = committedStoryFloor === "A2" ? "a2_0754_chase" : "a1_0754_blackout";
    const committedAndApplied = this.projection.phase === "final_chase"
      && this.projectionSignature === this.pendingProjectionSignature
      && displayFloorFor(committed.chapter4.floor) === this.currentFloor
      && this.appliedPlateIds[committedStoryFloor] === expectedPlate;
    const step = stepChapterFourFinalChase(runtime, {
      deltaMs,
      committedAndApplied,
      floor: playerFloorNumber === 2 ? "A2" : "A1",
      playerPosition: { x: playerFoot.x, y: playerFoot.y },
      guardPosition: {
        x: guardBody.center.x - guardFloor.offsetX,
        y: guardBody.center.y
      },
      playerInsideFinish,
      playerEnteredMainStair,
      guardContact
    });
    this.finalChaseState = step.state;
    this.finalChaseStep = step;
    if (step.state.pursuitBand !== this.finalChaseAudioBand) {
      this.finalChaseAudioBand = step.state.pursuitBand;
      this.safeBridgeEmit(`final_chase_pressure_${step.state.pursuitBand}`, {
        attempt: committed.chapter4.chaseAttempt,
        routeDistance: Math.round(step.guardToPlayerRouteDistance)
      });
      if (step.state.pursuitBand === "close" && !this.finalChaseCloseVoicePlayed) {
        this.finalChaseCloseVoicePlayed = true;
        this.safeBridgeEmit("final_chase_close_voice", {
          attempt: committed.chapter4.chaseAttempt
        });
        this.safeBridgeEmit("rpg_subtitle", {
          text: chapterFourDialogueText("chase.close"),
          tone: "system",
          speaker: "保安",
          durationMs: 2500
        });
      }
    }
    if (step.guardPortalArrival) {
      const arrivalFloor = getFloor(2);
      guard.setPosition(
        arrivalFloor.offsetX + FINAL_CHASE_RUNTIME.waypoints.find(
          (entry) => entry.id === "a2_main_stair_arrival"
        )!.x,
        CHAPTER_FOUR_FINAL_CHASE_POINTS.a2Arrival.y
      );
      if (!this.finalChaseFloorVoicePlayed) {
        this.finalChaseFloorVoicePlayed = true;
        this.safeBridgeEmit("final_chase_floor_changed", {
          attempt: committed.chapter4.chaseAttempt,
          floor: "A2"
        });
        this.safeBridgeEmit("rpg_subtitle", {
          text: chapterFourDialogueText("chase.floor_changed"),
          tone: "system",
          speaker: "保安",
          durationMs: 3100
        });
      }
    }
    const activeGuardFloor: DisplayFloor = step.state.guardFloor === "A2" ? 2 : 1;
    const visible = step.guardVisible && this.currentFloor === activeGuardFloor;
    guard.setVisible(visible);
    if (visible) {
      guard.setVelocity(step.desiredGuardVelocity.x, step.desiredGuardVelocity.y)
        .setDepth(PLAYER_DEPTH_BASE + guard.y + 2);
      const guardAnimation = this.resolveFinalChaseGuardTravelAnimation(
        step.desiredGuardVelocity
      );
      if (guard.anims.currentAnim?.key !== guardAnimation) {
        guard.play(guardAnimation, true);
      }
    } else {
      guard.setVelocity(0, 0);
    }

    if (step.portalRequested && !this.pendingMove && !this.pendingStoryRequest) {
      this.requestMove(2, "stair");
      return;
    }
    if (step.finishRequested && !this.pendingStoryRequest) {
      this.requestStoryIntent({
        type: "reach_202_threshold",
        targetId: FINAL_CHASE_RUNTIME.finishThreshold.targetId,
        expectedAttempt: committed.chapter4.chaseAttempt,
        spatial: { distance: "within_range" }
      }, FINAL_CHASE_RUNTIME.finishThreshold.targetId);
      return;
    }
    if (step.failureRequested && !this.pendingStoryRequest) {
      this.requestStoryIntent({
        type: "fail_chase",
        expectedAttempt: committed.chapter4.chaseAttempt
      });
    }
  }

  private ensureRoom202RecoveryBarrier(): void {
    if (this.room202DoorBarrier?.active) return;
    const floor = getFloor(2);
    const bounds = FINAL_CHASE_RUNTIME.room202Door.barrierBounds;
    const zone = this.add.zone(
      floor.offsetX + rectCenterX(bounds),
      rectCenterY(bounds),
      bounds.width,
      bounds.height
    );
    this.physics.add.existing(zone, true);
    this.room202DoorBarrier = zone;
    this.room202DoorCollider = this.physics.add.collider(this.player, zone);
    this.room202DoorVisual = this.add.rectangle(
      floor.offsetX + rectCenterX(bounds),
      rectCenterY(bounds),
      bounds.width,
      bounds.height,
      0x17202b,
      0.94
    ).setStrokeStyle(2, 0x82a9bd, 0.9)
      .setDepth(PLAYER_DEPTH_BASE + rectBottom(bounds) + 3);
    this.room202DoorLabel = this.add.text(
      floor.offsetX + rectCenterX(bounds),
      bounds.y - 8,
      "202 门已关闭",
      {
        fontFamily: "'Fusion Pixel', monospace",
        fontSize: "12px",
        color: "#d9edf2",
        stroke: "#07111d",
        strokeThickness: 3
      }
    ).setOrigin(0.5, 1).setDepth(PLAYER_DEPTH_BASE + rectBottom(bounds) + 4);
  }

  private ensureFinalMinuteRuntime(state: GameState): void {
    if (hasChapterFourFact(state, "final_minute_recovered") || state.items.finalMinute) {
      this.destroyFinalMinuteRuntime("already_recovered");
      return;
    }
    if (this.finalMinuteSprite?.active && this.finalMinuteTargetZone?.active) return;
    this.destroyFinalMinuteRuntime("recreate");
    const floor = getFloor(2);
    const sprite = this.add.sprite(
      floor.offsetX + FINAL_MINUTE_RUNTIME.pivot.x,
      FINAL_MINUTE_RUNTIME.pivot.y,
      FINAL_MINUTE_RUNTIME.texture,
      FINAL_MINUTE_RUNTIME.frame
    ).setScale(FINAL_MINUTE_RUNTIME.uniformScale)
      .setDepth(PLAYER_DEPTH_BASE + FINAL_MINUTE_RUNTIME.pivot.y + 6);
    this.finalMinuteSprite = sprite;
    const measured = sprite.getBounds();
    const derived = {
      x: Math.floor(measured.left - floor.offsetX),
      y: Math.floor(measured.top),
      width: Math.ceil(measured.right - floor.offsetX) - Math.floor(measured.left - floor.offsetX),
      height: Math.ceil(measured.bottom) - Math.floor(measured.top)
    };
    if (!rectEquals(derived, FINAL_MINUTE_RUNTIME.installationBounds)) {
      this.persistentContractFailures.add(`final_minute_get_bounds:${JSON.stringify(derived)}`);
      sprite.destroy();
      this.finalMinuteSprite = null;
      return;
    }
    const zone = this.add.zone(
      floor.offsetX + rectCenterX(derived),
      rectCenterY(derived),
      derived.width,
      derived.height
    ).setDepth(PLAYER_DEPTH_BASE + rectBottom(derived) + 7);
    this.finalMinuteTargetZone = zone;
    this.phaseRuntimeTargets.set(FINAL_MINUTE_RUNTIME.targetId, {
      targetId: FINAL_MINUTE_RUNTIME.targetId,
      entityId: FINAL_MINUTE_RUNTIME.entityId,
      floor: 2,
      boundsObject: zone
    });
  }

  private destroyFinalMinuteRuntime(_reason: string): void {
    this.phaseRuntimeTargets.delete(FINAL_MINUTE_RUNTIME.targetId);
    this.finalMinuteTargetZone?.destroy();
    this.finalMinuteTargetZone = null;
    this.finalMinuteSprite?.destroy();
    this.finalMinuteSprite = null;
  }

  private destroyRoom202RecoveryBarrier(_reason: string): void {
    this.room202DoorCollider?.destroy();
    this.room202DoorCollider = null;
    this.room202DoorBarrier?.destroy();
    this.room202DoorBarrier = null;
    this.room202DoorVisual?.destroy();
    this.room202DoorVisual = null;
    this.room202DoorLabel?.destroy();
    this.room202DoorLabel = null;
  }

  private destroyChaseRuntime(): void {
    this.chaseGuardStaticCollider?.destroy();
    this.chaseGuardStaticCollider = null;
    this.chaseGuardPlateCollider?.destroy();
    this.chaseGuardPlateCollider = null;
    this.chaseGuard?.destroy();
    this.chaseGuard = null;
    this.finalChaseGuardTravelDirection = "side";
    this.finalChaseGuardTravelFlipX = false;
    this.finalChaseState = null;
    this.finalChaseStep = null;
    this.finalChaseAudioBand = null;
    this.finalChaseCloseVoicePlayed = false;
    this.finalChaseFloorVoicePlayed = false;
    this.finalChaseInsideFinish = false;
    this.finalChaseContact = false;
  }

  private destroyTask12Runtime(reason: string): void {
    this.destroyChaseRuntime();
    this.destroyFinalMinuteRuntime(reason);
    this.destroyRoom202RecoveryBarrier(reason);
  }

  private syncPhaseSideEffects(): void {
    if (this.storyPresentation === "minute_theft") return;
    const state = this.bridge.getState();
    if (this.projection.phase !== state.chapter4.phase) return;
    const signature = [
      state.chapter4.phase,
      state.chapter4.timeState
    ].join(":");
    if (signature === this.lastPhaseSignature) return;
    this.lastPhaseSignature = signature;
    switch (state.chapter4.phase) {
      case "maintenance_repair":
        this.safeBridgeEmit("rpg_subtitle", {
          text: chapterFourDialogueText("maintenance.cleaner"),
          tone: "system",
          durationMs: 2600
        });
        break;
      case "final_chase":
        this.safeBridgeEmit("rpg_subtitle", {
          text: chapterFourDialogueText("chase.started"),
          tone: "system",
          speaker: "保安",
          durationMs: 2200
        });
        break;
      case "morning_checkin":
        this.safeBridgeEmit("rpg_subtitle", {
          text: chapterFourDialogueText("morning.entry"),
          tone: "system",
          durationMs: 2400
        });
        break;
      case "exterior_closure":
        this.safeBridgeEmit("rpg_subtitle", {
          text: chapterFourDialogueText("exterior.closure"),
          tone: "system",
          durationMs: 2200
        });
        break;
      default:
        break;
    }
  }

  private syncRoom204ProjectionPresentation(): void {
    const state = this.bridge.getState();
    if (hasChapterFourFact(state, "room204_projection_completed")) {
      if (this.storyPresentation !== "room204_projection") {
        this.destroyRoom204ProjectionOverlay();
      }
      return;
    }
    if (this.pendingStoryRequest
      || this.storyPresentation !== "idle"
      || this.time.now < this.storyRetryNotBeforeMs
      || state.chapter4.phase !== "room204_restore"
      || this.currentFloor !== 2
      || !hasChapterFourFact(state, "a3_reference_observed")
      || !hasChapterFourFact(state, "room204_residual_observed")
      || !hasChapterFourFact(state, "room204_restored")
      || !isRoom204PlacementSetComplete(state.chapter4.room204Placements)) return;
    this.beginRoom204ProjectionPresentation();
  }

  private beginRoom204ProjectionPresentation(): void {
    if (this.storyPresentation !== "idle" || this.pendingStoryRequest) return;
    const state = this.bridge.getState();
    if (state.chapter4.phase !== "room204_restore"
      || this.currentFloor !== 2
      || !hasChapterFourFact(state, "a3_reference_observed")
      || !hasChapterFourFact(state, "room204_residual_observed")
      || !hasChapterFourFact(state, "room204_restored")
      || hasChapterFourFact(state, "room204_projection_completed")
      || !isRoom204PlacementSetComplete(state.chapter4.room204Placements)) return;

    this.storyPresentation = "room204_projection";
    this.syncStoryInputLock();
    this.clearStoryPresentationTimers();
    this.destroyRoom204ProjectionOverlay();

    const floor = getFloor(2);
    const bounds = ROOM204_PROJECTION_HANDSHAKE.screenBounds;
    const centerX = floor.offsetX + rectCenterX(bounds);
    const centerY = rectCenterY(bounds);
    const overlay = this.add.container(centerX, centerY)
      .setDepth(PLAYER_DEPTH_BASE + rectBottom(bounds) - 100);
    const glow = this.add.rectangle(0, 0, bounds.width + 16, bounds.height + 12, 0x4edcff, 0.14);
    const screen = this.add.rectangle(0, 0, bounds.width, bounds.height, 0x071827, 0.94)
      .setStrokeStyle(2, 0x7ce9ff, 0.92);
    const title = this.add.text(0, -12, "07:55 残影投影", {
      fontFamily: "'Fusion Pixel', monospace",
      fontSize: "10px",
      color: "#8fe8ff",
      align: "center"
    }).setOrigin(0.5);
    const status = this.add.text(0, 8, "校准中……", {
      fontFamily: "'Fusion Pixel', monospace",
      fontSize: "9px",
      color: "#f7f1dc",
      align: "center"
    }).setOrigin(0.5);
    overlay.add([glow, screen, title, status]);
    this.room204ProjectionOverlay = overlay;

    this.scheduleStoryPresentation(ROOM204_PROJECTION_HANDSHAKE.misalignedAtMs, () => {
      if (!overlay.active) return;
      overlay.setX(centerX + 3);
      screen.setStrokeStyle(2, 0xff8d82, 0.92);
      status.setText("偏移·3px");
    });
    this.scheduleStoryPresentation(ROOM204_PROJECTION_HANDSHAKE.stableAtMs, () => {
      if (!overlay.active) return;
      overlay.setX(centerX);
      screen.setStrokeStyle(2, 0x7ce9ff, 0.96);
      status.setText(ROOM204_PROJECTION_HANDSHAKE.stableText);
    });
    this.scheduleStoryPresentation(ROOM204_PROJECTION_HANDSHAKE.commitAtMs, () => {
      if (this.storyPresentation !== "room204_projection") return;
      this.requestStoryIntent({ type: "complete_room204_projection" });
    });
  }

  private rollbackRoom204ProjectionToCommittedState(feedback: string): void {
    this.clearStoryPresentationTimers();
    this.destroyRoom204ProjectionOverlay();
    this.storyPresentation = "idle";
    this.storyRetryNotBeforeMs = this.time.now + STORY_RETRY_DELAY_MS;
    if (feedback) {
      this.persistentContractFailures.add(`room204_recovery:${feedback}`);
      this.showFeedback("进度已恢复，请重试当前操作。");
    }
    this.syncStoryInputLock();
  }

  private destroyRoom204ProjectionOverlay(): void {
    this.room204ProjectionOverlay?.destroy(true);
    this.room204ProjectionOverlay = null;
  }

  private resolveProjectedTargets(): ProjectedTarget[] {
    const phase = this.projection.phase;
    if (!phase) return [];
    return this.projection.availableTargetIds.flatMap((targetId) => {
      if (!TASK13_ACTIONABLE_TARGET_IDS.has(targetId)) return [];
      const contract = CHAPTER_FOUR_755_INTERACTION_TARGETS[
        targetId as keyof typeof CHAPTER_FOUR_755_INTERACTION_TARGETS
      ];
      if (!contract) return [];
      if (contract.boundsSource.kind === "runtime_entity") {
        const bakeryBinding = this.bakeryRuntimeTargets.get(contract.id);
        const room204Binding = this.room204RuntimeTargets.get(contract.id);
        const phaseBinding = this.phaseRuntimeTargets.get(contract.id);
        const binding = bakeryBinding ?? room204Binding ?? phaseBinding;
        const bounds = bakeryBinding
          ? this.outwardBakeryRuntimeBounds(bakeryBinding)
          : room204Binding
            ? this.outwardRoom204Bounds(room204Binding.boundsObject)
            : phaseBinding
              ? this.outwardPhaseRuntimeBounds(phaseBinding)
            : null;
        const floor = displayFloorFor(contract.boundsSource.floor);
        if (!binding
          || binding.entityId !== contract.boundsSource.entityId
          || !bounds
          || !binding.boundsObject.visible
          || !floor) return [];
        return [{
          contract,
          floor,
          bounds,
          acceptedItem: selectChapterFour755AcceptedItem(contract, phase) as ItemId | null | undefined
        }];
      }
      if (!contract.bounds) return [];
      const floor = displayFloorFor(contract.boundsSource.floor);
      if (!floor) return [];
      return [{
        contract,
        floor,
        bounds: contract.bounds,
        acceptedItem: selectChapterFour755AcceptedItem(contract, phase) as ItemId | null | undefined
      }];
    });
  }

  private resolveActionableTargets(): ProjectedTarget[] {
    return this.resolveProjectedTargets().filter((target) => (
      TASK13_ACTIONABLE_TARGET_IDS.has(target.contract.id)
    ));
  }

  /** Uses only outward-rounded bounds measured from the active Phaser entity. */
  private resolveRuntimeTargetContext(
    target: ChapterFour755InteractionTargetContract,
    bounds: Readonly<MapRect>
  ): ChapterFour755RuntimeTargetContext | null {
    if (target.boundsSource.kind !== "runtime_entity") return null;
    return { targetId: target.id, entityId: target.boundsSource.entityId, bounds: { ...bounds } };
  }

  private handleSpatialAttestationRequest(payload?: Record<string, unknown>): void {
    if (!isChapterFour755SpatialAttestationRequest(payload)
      || payload.sceneKey !== CHAPTER_FOUR_755_SCENE_KEY
      || !this.sys.isActive()) return;
    const state = this.bridge.getState();
    if (state.rpgScene !== "duan_yongping_temporal_maze"
      || state.chapter4.phase !== payload.committedPhase
      || this.projection.phase !== payload.committedPhase
      || this.appliedPlateSignature.length === 0) return;
    const actionableTarget = this.resolveActionableTargets().find((candidate) => (
      candidate.contract.id === payload.targetId
      && candidate.floor === this.currentFloor
    ));
    const thresholdContract = CHAPTER_FOUR_755_INTERACTION_TARGETS.a2_202_threshold;
    const automaticThresholdTarget: ProjectedTarget | null = payload.targetId === thresholdContract.id
      && state.chapter4.phase === "final_chase"
      && this.currentFloor === 2
      && this.finalChaseInsideFinish
      && this.finalChaseState?.phase === "finish_pending"
      && isChapterFour755TargetStateActive(state, thresholdContract)
      && thresholdContract.bounds
      ? {
          contract: thresholdContract,
          floor: 2,
          bounds: thresholdContract.bounds,
          acceptedItem: null
        }
      : null;
    const target = actionableTarget ?? automaticThresholdTarget;
    if (!target || (!automaticThresholdTarget
      && !this.renderedTargetIds.includes(target.contract.id))) return;
    const context = target.contract.boundsSource.kind === "runtime_entity"
      ? this.resolveRuntimeTargetContext(target.contract, target.bounds)
      : {
          targetId: target.contract.id,
          entityId: target.contract.boundsSource.anchorId,
          bounds: { ...target.bounds }
        };
    if (!context
      || context.targetId !== payload.targetId
      || context.entityId !== payload.entityId
      || !rectEquals(context.bounds, payload.bounds)) return;
    const floor = getFloor(target.floor);
    const foot = this.playerFootPoint(floor);
    if (!Number.isFinite(foot.x) || !Number.isFinite(foot.y)) return;
    this.spatialAttestationLast = {
      requestId: payload.requestId,
      attestationId: payload.attestationId,
      targetId: payload.targetId,
      result: "responded",
      reason: null
    };
    this.safeBridgeEmit("rpg_chapter4_755_spatial_attestation_response", {
      requestId: payload.requestId,
      attestationId: payload.attestationId,
      sceneKey: CHAPTER_FOUR_755_SCENE_KEY,
      committedPhase: payload.committedPhase,
      targetId: payload.targetId,
      entityId: context.entityId,
      bounds: { ...context.bounds },
      appliedPhase: this.projection.phase,
      appliedPlateSignature: this.appliedPlateSignature,
      playerFootPoint: { x: foot.x, y: foot.y }
    });
  }

  private refreshProjectedTargetVisuals(): void {
    this.clearProjectedTargetVisuals();
    const targets = this.resolveProjectedTargets();
    const showBounds = import.meta.env.DEV
      && new URLSearchParams(window.location.search).get("debugTargets") === "1";
    for (const target of targets) {
      const floor = getFloor(target.floor);
      const mode = this.projection.phase
        ? selectChapterFour755RequiredMode(target.contract, this.projection.phase)
        : undefined;
      const color = mode === "dark" ? 0x67ddff : mode === "light" ? 0xffd36f : 0xf7f1dc;
      const modeActive = mode === undefined || mode === this.appliedChapterMode;
      const isAlumniPortrait = getChapterFourAlumniFigureByTargetId(target.contract.id) !== null;
      if (isAlumniPortrait && !showBounds) continue;
      const container = this.add.container(
        floor.offsetX + rectCenterX(target.bounds), rectCenterY(target.bounds)
      ).setDepth(REALITY_MODE_TARGET_DEPTH)
        .setAlpha(modeActive ? 1 : 0.22)
        .setScale(modeActive ? 1 : 0.72);
      if (!isAlumniPortrait && mode === "light") {
        container.add(this.add.rectangle(0, 0, 13, 13, color, 0.12)
          .setRotation(Math.PI / 4)
          .setStrokeStyle(2, color, 0.94));
        container.add(this.add.circle(0, 0, 3, color, 0.96));
      } else if (!isAlumniPortrait) {
        container.add(this.add.circle(0, 0, 10, color, 0.08)
          .setStrokeStyle(2, color, 0.94));
        container.add(this.add.circle(0, 0, 3, color, 0.96));
      }
      if (showBounds) {
        container.add(this.add.rectangle(
          0, 0, target.bounds.width, target.bounds.height, color, 0.04
        ).setStrokeStyle(2, color, 0.72));
      }
      this.targetVisuals.set(target.contract.id, container);
    }
    this.renderedTargetIds = targets.map((target) => target.contract.id);
  }

  private clearProjectedTargetVisuals(): void {
    for (const visual of this.targetVisuals.values()) {
      this.tweens.killTweensOf(visual);
      visual.destroy(true);
    }
    this.targetVisuals.clear();
    this.renderedTargetIds = [];
  }

  private createElevatorVisuals(): void {
    for (const floor of FLOORS) {
      const aperture = floor.elevator.visibleBounds;
      const uniformScale = Math.min(
        aperture.width / ELEVATOR_FRAME_WIDTH,
        aperture.height / ELEVATOR_FRAME_HEIGHT
      );
      const door = this.add.sprite(
        floor.offsetX + floor.elevator.doorCenter.x,
        floor.elevator.doorCenter.y,
        ELEVATOR_TEXTURE,
        0
      ).setScale(uniformScale)
        .setDepth(CHAPTER_FOUR_ELEVATOR_VISUAL_DEPTH.door);
      const indicator = this.add.text(
        floor.offsetX + floor.elevator.doorCenter.x,
        Math.max(18, aperture.y - 13),
        `${floor.displayFloor}F`,
        {
          fontFamily: "'Fusion Pixel', monospace", fontSize: "13px",
          color: "#ffe493", backgroundColor: "#111827", padding: { x: 4, y: 2 }
        }
      ).setOrigin(0.5).setDepth(CHAPTER_FOUR_ELEVATOR_VISUAL_DEPTH.indicator);
      const lamp = this.add.circle(
        floor.offsetX + aperture.x + aperture.width + 8,
        floor.elevator.doorCenter.y,
        3, 0xffd36f, 0.95
      ).setDepth(CHAPTER_FOUR_ELEVATOR_VISUAL_DEPTH.lamp).setVisible(false);
      this.elevatorVisuals.set(floor.displayFloor, { floor: floor.displayFloor, door, indicator, lamp });
    }
  }

  private setElevatorDoorProgress(floor: DisplayFloor, progress: number): void {
    const value = Phaser.Math.Clamp(progress, 0, 1);
    this.elevatorVisuals.get(floor)?.door.setFrame(Math.round(value * (ELEVATOR_FRAME_COUNT - 1)));
    this.elevatorDoorProgress = value;
  }
  private tweenElevatorDoor(floor: DisplayFloor, from: number, to: number, done: () => void): void {
    const state = { progress: from };
    this.setElevatorDoorProgress(floor, from);
    this.tweens.add({
      targets: state, progress: to, duration: ELEVATOR_DOOR_MS, ease: "Sine.InOut",
      onUpdate: () => this.setElevatorDoorProgress(floor, state.progress),
      onComplete: done
    });
  }
  private configureCameraForCurrentFloor(): void {
    const floor = getFloor(this.currentFloor);
    this.physics.world.setBounds(
      floor.offsetX,
      0,
      FLOOR_SIZE.width,
      FLOOR_SIZE.height,
      true,
      true,
      true,
      true
    );
    setRpgLogicalCameraZoom(
      this,
      1,
      this.cameras.main.setBounds(floor.offsetX, 0, FLOOR_SIZE.width, FLOOR_SIZE.height)
    ).startFollow(this.player, true, 0.12, 0.12);
  }

  /** All story distance checks use the shared player's authored foot body. */
  private playerFootPoint(floor: FloorDefinition): { x: number; y: number; worldX: number } {
    const body = this.player.body as Phaser.Physics.Arcade.Body | undefined;
    const worldX = body?.center.x ?? this.player.x;
    const y = body?.center.y ?? this.player.y;
    return { x: worldX - floor.offsetX, y, worldX };
  }

  private refreshProximity(): void {
    const floor = getFloor(this.currentFloor);
    const foot = this.playerFootPoint(floor);
    const localPlayer = { x: foot.x, y: foot.y };
    this.nearbyRoom204PieceId = this.resolveNearbyRoom204PieceId();
    this.nearbyStoryTarget = this.resolveActionableTargets()
      .filter((target) => target.floor === this.currentFloor)
      .map((target) => ({
        target,
        distance: pointDistanceToRect(localPlayer, target.bounds)
      }))
      .filter(({ target, distance }) => distance <= target.contract.proximity)
      .sort((a, b) => a.distance - b.distance)[0]?.target ?? null;
    this.nearbyAlumniFigure = CHAPTER_FOUR_ALUMNI_HONOR_WALL
      .filter((figure) => figure.floor === this.currentFloor)
      .map((figure) => ({
        figure,
        distance: pointDistanceToRect(localPlayer, figure.frameBounds)
      }))
      .filter(({ distance }) => distance <= 72)
      .sort((a, b) => a.distance - b.distance)[0]?.figure ?? null;
    const nearbyTravelCandidate = this.projection.phase && OPENING_PHASES.has(this.projection.phase)
      ? undefined
      : createTravelTargets(floor)
          .map((target) => ({ target, distance: pointDistanceToRect(localPlayer, target.bounds) }))
          .filter(({ distance }) => distance <= 76)
          .sort((a, b) => a.distance - b.distance)[0];
    this.nearbyTravelTarget = nearbyTravelCandidate?.target ?? null;
    this.nearbyTravelTargetHasPriority = nearbyTravelCandidate !== undefined
      && nearbyTravelCandidate.distance <= 12;
    this.nearbyLandmark = floor.anchors
      .map((anchor) => ({ anchor, distance: pointDistanceToRect(localPlayer, anchor.bounds) }))
      .filter(({ distance }) => distance <= 44)
      .sort((a, b) => a.distance - b.distance)[0]?.anchor ?? null;
    this.floorCaption.setText(
      this.nearbyLandmark ? `${floor.title} · ${this.nearbyLandmark.label}` : floor.title
    );
    if (this.currentFloor === 2 && this.bridge.getState().chapter4.phase === "room204_restore") {
      const nearbyGroupId = this.nearbyStoryTarget
        ? room204GroupIdFromTargetId(this.nearbyStoryTarget.contract.id)
        : null;
      if (nearbyGroupId) {
        this.interactionHint.setText(
          this.bridge.getState().chapter4.mode === "light"
            ? `Space · 按${ROOM204_GROUPS[nearbyGroupId].label}复原一组桌椅`
            : `当前为深色观察；${ROOM204_GROUPS[nearbyGroupId].label}需在浅色操作中复原`
        ).setVisible(true);
        return;
      }
      if (this.room204SelectedPieceId
        && this.nearbyStoryTarget
        && isRoom204SlotTargetId(this.nearbyStoryTarget.contract.id)) {
        this.interactionHint.setText("Space · 把已搬起的桌椅放到残影槽位")
          .setVisible(true);
        return;
      }
      if (!this.room204SelectedPieceId && this.nearbyRoom204PieceId) {
        this.interactionHint.setText(
          this.bridge.getState().chapter4.mode === "light"
            ? "Space · 搬动一组桌椅"
            : "当前为深色观察；搬动桌椅需要浅色操作"
        ).setVisible(true);
        return;
      }
      if (!this.room204SelectedPieceId
        && this.nearbyStoryTarget
        && isRoom204SlotTargetId(this.nearbyStoryTarget.contract.id)) {
        this.interactionHint.setText(
          this.bridge.getState().chapter4.mode === "light"
            ? "先搬一组桌椅，再放到残影槽位。"
            : "搬动桌椅需要浅色操作；当前仍可查看残影槽位。"
        ).setVisible(true);
        return;
      }
    }
    if (this.nearbyTravelTargetHasPriority
      && this.nearbyTravelTarget
      && !this.pendingMove
      && !this.pendingStoryRequest) {
      this.interactionHint.setText(`Space · ${this.nearbyTravelTarget.label}`).setVisible(true);
      return;
    }
    if (this.nearbyAlumniFigure && !this.pendingStoryRequest) {
      this.interactionHint.setText(`Space · 查看${this.nearbyAlumniFigure.name}生平`)
        .setVisible(true);
      return;
    }
    if (this.nearbyStoryTarget && !this.pendingStoryRequest) {
      if (this.nearbyStoryTarget.acceptedItem !== undefined
        && this.nearbyStoryTarget.acceptedItem !== null) {
        this.interactionHint.setText(
          `把对应道具拖到${this.nearbyStoryTarget.contract.label}`
        ).setVisible(true);
        return;
      }
      this.interactionHint.setText(`Space · ${this.nearbyStoryTarget.contract.label}`)
        .setVisible(true);
      return;
    }
    if (!this.nearbyTravelTarget || this.pendingMove || this.pendingStoryRequest) {
      this.interactionHint.setVisible(false);
      return;
    }
    this.interactionHint.setText(`Space · ${this.nearbyTravelTarget.label}`).setVisible(true);
  }

  private isStoryInputLocked(): boolean {
    return this.storyPresentation !== "idle"
      || this.alumniPanel !== null
      || this.pendingStoryRequest !== null
      || this.pendingMove !== null
      || this.finalClockDragActive;
  }

  private syncStoryInputLock(force = false): void {
    const locked = this.isStoryInputLocked();
    const allowScenePointer = locked
      && (this.alumniPanel !== null
        || (this.finalClockDragActive
          && this.storyPresentation === "idle"
          && this.pendingStoryRequest === null));
    const allowSceneKeyboard = locked && this.alumniPanel !== null;
    if (!force
      && locked === this.lastPublishedStoryInputLock
      && allowScenePointer === this.lastPublishedStoryPointerAllowed
      && allowSceneKeyboard === this.lastPublishedStoryKeyboardAllowed) return;
    this.lastPublishedStoryInputLock = locked;
    this.lastPublishedStoryPointerAllowed = allowScenePointer;
    this.lastPublishedStoryKeyboardAllowed = allowSceneKeyboard;
    this.safeBridgeEmit("rpg_chapter4_story_input_lock_changed", {
      locked,
      allowScenePointer,
      allowSceneKeyboard,
      presentation: this.storyPresentation,
      pendingIntent: this.pendingStoryRequest?.intentType ?? null
    });
  }

  private storySpatialResult(target: ProjectedTarget): {
    distance: "within_range" | "too_far";
  } {
    const floor = getFloor(target.floor);
    const foot = this.playerFootPoint(floor);
    const localPlayer = { x: foot.x, y: foot.y };
    return {
      distance: pointDistanceToRect(localPlayer, target.bounds) <= target.contract.proximity
        ? "within_range"
        : "too_far"
    };
  }

  private handleStoryOrTravelInteraction(): void {
    const storyTarget = this.nearbyStoryTarget;
    const state = this.bridge.getState();
    if (this.nearbyTravelTargetHasPriority) {
      this.handleTravelInteraction();
      return;
    }
    if (this.nearbyAlumniFigure) {
      this.openAlumniPanel(this.nearbyAlumniFigure.targetId);
      return;
    }
    if (state.chapter4.phase === "room204_restore"
      && this.currentFloor === 2
      && !this.room204SelectedPieceId
      && this.nearbyRoom204PieceId
      && !storyTarget) {
      if (state.chapter4.mode !== "light") {
        this.showFeedback("切到浅色操作后再搬动桌椅。");
        return;
      }
      this.selectRoom204Piece(this.nearbyRoom204PieceId);
      this.refreshProximity();
      return;
    }
    if (storyTarget) {
      const spatial = this.storySpatialResult(storyTarget);
      if (state.chapter4.phase === "room204_restore" && this.currentFloor === 2) {
        const groupId = room204GroupIdFromTargetId(storyTarget.contract.id);
        if (groupId) {
          const runtimeTarget = this.resolveRuntimeTargetContext(
            storyTarget.contract,
            storyTarget.bounds
          );
          if (!runtimeTarget) {
            this.showRuntimeInteractionFailure("room204_group_runtime_bounds_missing");
            return;
          }
          this.requestStoryIntent({
            type: "place_room204_group",
            groupId: groupId as ChapterFourRoom204GroupId,
            targetId: storyTarget.contract.id,
            spatial
          }, storyTarget.contract.id, runtimeTarget);
          return;
        }
        if (this.room204SelectedPieceId && isRoom204SlotTargetId(storyTarget.contract.id)) {
          const runtimeTarget = this.resolveRuntimeTargetContext(
            storyTarget.contract,
            storyTarget.bounds
          );
          if (!runtimeTarget) {
            this.showRuntimeInteractionFailure("room204_slot_runtime_bounds_missing");
            return;
          }
          this.requestStoryIntent({
            type: "place_room204_piece",
            pieceId: this.room204SelectedPieceId,
            slotId: storyTarget.contract.id.replace("a2_room204_slot_", "") as ChapterFourRoom204SlotId,
            orientation: "up",
            targetId: storyTarget.contract.id,
            spatial
          }, storyTarget.contract.id, runtimeTarget);
          return;
        }
        if (!this.room204SelectedPieceId && this.nearbyRoom204PieceId) {
          if (state.chapter4.mode !== "light") {
            this.showFeedback("切到浅色操作后再搬动桌椅。");
            return;
          }
          this.selectRoom204Piece(this.nearbyRoom204PieceId);
          this.refreshProximity();
          return;
        }
        if (!this.room204SelectedPieceId && isRoom204SlotTargetId(storyTarget.contract.id)) {
          this.showFeedback("先搬一组桌椅，再放到对应残影位置。");
          return;
        }
      }
      if (storyTarget.contract.id === "a1_noticeboard_paper") {
        this.requestStoryIntent({
          type: "catch_attendance_paper",
          targetId: "a1_noticeboard_paper",
          spatial
        }, storyTarget.contract.id);
        return;
      }
      if (storyTarget.contract.id === "a1_hall_clock") {
        const intent: ChapterFour755Intent = state.chapter4.phase === "opening_paper_caught"
          ? { type: "inspect_hall_clock", targetId: "a1_hall_clock", spatial }
          : { type: "pull_hall_clock", targetId: "a1_hall_clock", spatial };
        this.requestStoryIntent(intent, storyTarget.contract.id);
        return;
      }
      if (storyTarget.contract.id === "a1_bakery_inspection_lamp") {
        const runtimeTarget = this.resolveRuntimeTargetContext(
          storyTarget.contract,
          storyTarget.bounds
        );
        if (!runtimeTarget) {
          this.showRuntimeInteractionFailure("bakery_lamp_runtime_bounds_missing");
          return;
        }
        this.requestStoryIntent({
          type: "inspect_bakery_conveyor_lamp",
          targetId: "a1_bakery_inspection_lamp",
          spatial
        }, storyTarget.contract.id, runtimeTarget);
        return;
      }
      if (storyTarget.contract.id === "a1_bakery_conveyor_edge") {
        const runtimeTarget = this.resolveRuntimeTargetContext(
          storyTarget.contract,
          storyTarget.bounds
        );
        if (!runtimeTarget) {
          this.showRuntimeInteractionFailure("bakery_conveyor_runtime_bounds_missing");
          return;
        }
        this.requestStoryIntent({
          type: "inspect_bakery_conveyor_edge",
          targetId: "a1_bakery_conveyor_edge",
          spatial
        }, storyTarget.contract.id, runtimeTarget);
        return;
      }
      if (storyTarget.contract.id === "a1_bakery_hour_hand_pickup") {
        const runtimeTarget = this.resolveRuntimeTargetContext(
          storyTarget.contract,
          storyTarget.bounds
        );
        if (!runtimeTarget) {
          this.showRuntimeInteractionFailure("hour_hand_runtime_bounds_missing");
          return;
        }
        this.requestStoryIntent({
          type: "collect_hour_hand",
          targetId: "a1_bakery_hour_hand_pickup",
          spatial
        }, storyTarget.contract.id, runtimeTarget);
        return;
      }
      if (storyTarget.contract.id === "a1_classroom_104_blackboard_residual") {
        this.requestStoryIntent({
          type: "observe_classroom_104_chalk_residual",
          targetId: "a1_classroom_104_blackboard_residual",
          spatial
        }, storyTarget.contract.id);
        return;
      }
      if (storyTarget.contract.id === "a1_front_desk_attendant") {
        this.requestStoryIntent({
          type: "talk_to_a1_front_desk_attendant",
          targetId: "a1_front_desk_attendant",
          spatial
        }, storyTarget.contract.id);
        return;
      }
      if (storyTarget.contract.id === "a2_elevator_attendant"
        || storyTarget.contract.id === "a3_reference_teacher") {
        this.requestStoryIntent({
          type: "talk_to_chapter_four_support_npc",
          targetId: storyTarget.contract.id,
          spatial
        }, storyTarget.contract.id);
        return;
      }
      const contextInteractionIntent = createChapterFourContextInteractionIntent({
        targetId: storyTarget.contract.id,
        spatial
      });
      if (contextInteractionIntent) {
        this.requestStoryIntent(contextInteractionIntent, storyTarget.contract.id);
        return;
      }
      if (getChapterFourAlumniFigureByTargetId(storyTarget.contract.id)) {
        this.requestStoryIntent({
          type: "inspect_alumni_figure",
          targetId: storyTarget.contract.id as Extract<
            ChapterFour755Intent,
            { type: "inspect_alumni_figure" }
          >["targetId"],
          spatial
        }, storyTarget.contract.id);
        return;
      }
      if (storyTarget.contract.id === "a1_classroom_105_lectern_terminal") {
        this.requestStoryIntent({
          type: "check_classroom_105_terminal_replay",
          targetId: "a1_classroom_105_lectern_terminal",
          spatial
        }, storyTarget.contract.id);
        return;
      }
      if (storyTarget.contract.id === "a3_reference_classroom_layout") {
        this.requestStoryIntent({
          type: "observe_a3_reference",
          targetId: "a3_reference_classroom_layout",
          spatial
        }, storyTarget.contract.id);
        return;
      }
      if (storyTarget.contract.id === "a2_room204_residual_group") {
        const runtimeTarget = this.resolveRuntimeTargetContext(
          storyTarget.contract,
          storyTarget.bounds
        );
        if (!runtimeTarget) {
          this.showRuntimeInteractionFailure("room204_residual_runtime_bounds_missing");
          return;
        }
        this.requestStoryIntent({
          type: "observe_room204_residual",
          targetId: "a2_room204_residual_group",
          spatial
        }, storyTarget.contract.id, runtimeTarget);
        return;
      }
      if (storyTarget.contract.id === "a2_room204_podium_drawer") {
        const runtimeTarget = this.resolveRuntimeTargetContext(
          storyTarget.contract,
          storyTarget.bounds
        );
        if (!runtimeTarget) {
          this.showRuntimeInteractionFailure("room204_drawer_runtime_bounds_missing");
          return;
        }
        this.requestStoryIntent({
          type: "collect_positioning_plate",
          targetId: "a2_room204_podium_drawer",
          spatial
        }, storyTarget.contract.id, runtimeTarget);
        return;
      }
      if (storyTarget.contract.id === "a1_cleaning_cart_wheel_inspection") {
        const runtimeTarget = this.resolveRuntimeTargetContext(
          storyTarget.contract,
          storyTarget.bounds
        );
        if (!runtimeTarget) {
          this.showRuntimeInteractionFailure("cart_wheel_inspection_runtime_bounds_missing");
          return;
        }
        this.requestStoryIntent({
          type: "inspect_cart_wheel",
          targetId: "a1_cleaning_cart_wheel_inspection",
          spatial
        }, storyTarget.contract.id, runtimeTarget);
        return;
      }
      if (storyTarget.contract.id === "a1_bakery_back_pry_bar") {
        const runtimeTarget = this.resolveRuntimeTargetContext(
          storyTarget.contract,
          storyTarget.bounds
        );
        if (!runtimeTarget) {
          this.showRuntimeInteractionFailure("pry_bar_runtime_bounds_missing");
          return;
        }
        this.requestStoryIntent({
          type: "collect_short_pry_bar",
          targetId: "a1_bakery_back_pry_bar",
          spatial
        }, storyTarget.contract.id, runtimeTarget);
        return;
      }
      if (storyTarget.contract.id === "a1_cleaning_cart_oil_bottle") {
        const runtimeTarget = this.resolveRuntimeTargetContext(
          storyTarget.contract,
          storyTarget.bounds
        );
        if (!runtimeTarget) {
          this.showRuntimeInteractionFailure("lubricating_oil_runtime_bounds_missing");
          return;
        }
        this.requestStoryIntent({
          type: "collect_lubricating_oil",
          targetId: "a1_cleaning_cart_oil_bottle",
          spatial
        }, storyTarget.contract.id, runtimeTarget);
        return;
      }
      if (storyTarget.contract.id === "a1_hall_clock_minute_endpoint"
        && state.chapter4.phase === "maintenance_repair") {
        this.requestFinalClockDrag(true, null);
        return;
      }
      if (storyTarget.contract.id === "a1_power_panel") {
        const runtimeTarget = this.resolveRuntimeTargetContext(
          storyTarget.contract,
          storyTarget.bounds
        );
        if (!runtimeTarget) {
          this.showRuntimeInteractionFailure("power_panel_runtime_bounds_missing");
          return;
        }
        this.requestStoryIntent({
          type: "open_power_panel",
          targetId: "a1_power_panel",
          spatial
        }, storyTarget.contract.id, runtimeTarget);
        return;
      }
      if (storyTarget.contract.id === "a2_202_threshold") {
        this.requestStoryIntent({
          type: "reach_202_threshold",
          targetId: "a2_202_threshold",
          expectedAttempt: this.bridge.getState().chapter4.chaseAttempt,
          spatial
        }, storyTarget.contract.id);
        return;
      }
      if (storyTarget.contract.id === "a2_202_projection") {
        const runtimeTarget = this.resolveRuntimeTargetContext(
          storyTarget.contract,
          storyTarget.bounds
        );
        if (!runtimeTarget) {
          this.showRuntimeInteractionFailure("final_minute_runtime_bounds_missing");
          return;
        }
        this.requestStoryIntent({
          type: "collect_final_minute",
          targetId: "a2_202_projection",
          spatial
        }, storyTarget.contract.id, runtimeTarget);
        return;
      }
      if (storyTarget.acceptedItem !== undefined && storyTarget.acceptedItem !== null) {
        this.showFeedback(`请从道具栏拖动道具到${storyTarget.contract.label}。`);
        return;
      }
    }
    this.handleTravelInteraction();
  }

  private handleTravelInteraction(): void {
    if (this.projection.phase && OPENING_PHASES.has(this.projection.phase)) return;
    const target = this.nearbyTravelTarget;
    if (!target || this.pendingMove) return;
    if (target.route === "elevator") {
      const state = this.bridge.getState();
      const phase = state.chapter4.phase;
      if (phase === "final_chase" || phase === "return_to_clock") {
        this.showFeedback(phase === "final_chase"
          ? "追逐中电梯已锁，请进入主楼梯。"
          : "返程只能沿主楼梯回到一楼旧钟。");
        return;
      }
      if (phase === "room204_restore" && this.currentFloor === 1) {
        if (!hasChapterFourFact(state, "elevator_history_observed")) {
          if (state.chapter4.mode === "dark") {
            this.requestStoryIntent({ type: "observe_elevator_history" });
            return;
          }
        }
        if (!hasChapterFourFact(state, "elevator_history_calibrated")
          && state.chapter4.mode !== "light") {
          this.showFeedback("当前可继续观察；轿厢重放校准需要浅色操作。");
          return;
        }
      }
      if (phase === "room204_restore"
        && this.currentFloor === 3
        && !hasChapterFourFact(state, "misaligned_stair_solved")) {
        this.showFeedback("电梯的历史片段只保留上行记录。请从三楼主楼梯返回二楼。");
        return;
      }
      this.openElevatorForSelection();
    }
    else if (target.targetFloor) {
      const state = this.bridge.getState();
      if (state.chapter4.phase === "room204_restore"
        && this.currentFloor === 3
        && target.targetFloor === 2
        && !hasChapterFourFact(state, "misaligned_stair_solved")) {
        if (!hasChapterFourFact(state, "a3_reference_observed")) {
          this.showFeedback("先在三楼晨间教室记录桌椅、入口与投影边界。");
          return;
        }
        this.bridge.emit("rpg_chapter4_stair_alignment_requested", {
          fromFloor: "A3",
          toFloor: "A2",
          checkpoint: state.rpgCheckpoint
        });
        return;
      }
      this.requestMove(target.targetFloor, "stair");
    }
  }

  private openElevatorForSelection(): void {
    const phase = this.bridge.getState().chapter4.phase;
    if (this.elevatorPhase !== "idle"
      || OPENING_PHASES.has(phase)
      || phase === "final_chase"
      || phase === "return_to_clock") return;
    this.elevatorPhase = "opening";
    this.elevatorVisuals.get(this.currentFloor)?.lamp.setVisible(true);
    this.player.setVelocity(0, 0);
    this.tweenElevatorDoor(this.currentFloor, 0, 1, () => {
      this.elevatorPhase = "boarding";
      const floor = getFloor(this.currentFloor);
      (this.player.body as Phaser.Physics.Arcade.Body).enable = false;
      this.tweens.add({
        targets: this.player,
        x: floor.offsetX + floor.elevator.doorCenter.x,
        y: floor.elevator.doorCenter.y,
        duration: ELEVATOR_BOARD_MS,
        ease: "Sine.InOut",
        onComplete: () => this.openFloorPanel()
      });
    });
  }

  private openFloorPanel(): void {
    const state = this.bridge.getState();
    if (state.chapter4.phase === "room204_restore"
      && this.currentFloor === 1
      && !hasChapterFourFact(state, "elevator_history_calibrated")) {
      this.openElevatorCalibrationPanel();
      return;
    }
    this.elevatorPhase = "selecting";
    this.floorPanelMode = "floors";
    this.floorPanelSelection = this.currentFloor;
    const panel = this.add.container(480, 270).setScrollFactor(0).setDepth(11000);
    panel.add([
      this.add.rectangle(0, 0, 690, 390, 0x07111d, 0.98).setStrokeStyle(3, 0xd7b654, 0.96),
      this.add.rectangle(-270, 0, 2, 298, 0x6f8394, 0.58),
      this.add.text(-316, -168, "A 楼主电梯", {
        fontFamily: "'Fusion Pixel', monospace", fontSize: "24px", color: "#f7f1dc"
      }).setOrigin(0, 0.5),
      this.add.text(-316, -139, "18:50 运行复核", {
        fontFamily: "'Fusion Pixel', monospace", fontSize: "13px", color: "#d7b654"
      }).setOrigin(0, 0.5)
    ]);
    this.floorPanelProgress = this.add.text(312, -153, "", {
      fontFamily: "'Fusion Pixel', monospace", fontSize: "13px", color: "#b8c7d2"
    }).setOrigin(1, 0.5);
    panel.add(this.floorPanelProgress);
    this.floorPanelButtons = [];
    for (const displayFloor of [3, 2, 1] as const) {
      const record = chapterFourElevatorRecordForDisplayFloor(displayFloor);
      const y = displayFloor === 3 ? -76 : displayFloor === 2 ? 10 : 96;
      const enabled = this.isElevatorFloorReachable(displayFloor, state);
      const background = this.add.rectangle(-270, y, 128, 70, 0x17263a, 1)
        .setStrokeStyle(2, 0x7f93aa, 1)
        .setInteractive({ useHandCursor: true })
        .on("pointerup", () => {
          this.floorPanelSelection = displayFloor;
          this.paintFloorPanelSelection();
        });
      const label = this.add.text(-318, y - 12, `${displayFloor}F`, {
        fontFamily: "'Fusion Pixel', monospace", fontSize: "21px", color: "#f7f1dc"
      }).setOrigin(0, 0.5);
      const detail = this.add.text(-318, y + 14, record.shortLabel, {
        fontFamily: "'Fusion Pixel', monospace", fontSize: "10px", color: "#a9bac7"
      }).setOrigin(0, 0.5);
      const status = this.add.text(-218, y - 14, "", {
        fontFamily: "'Fusion Pixel', monospace", fontSize: "9px", color: "#d7b654"
      }).setOrigin(1, 0.5);
      panel.add([background, label, detail, status]);
      this.floorPanelButtons.push({ floor: displayFloor, enabled, background, label, detail, status });
    }

    this.floorPanelTitle = this.add.text(-178, -102, "", {
      fontFamily: "'Fusion Pixel', monospace", fontSize: "19px", color: "#f7f1dc"
    }).setOrigin(0, 0.5);
    this.floorPanelDescription = this.add.text(-178, -66, "", {
      fontFamily: "'Fusion Pixel', monospace", fontSize: "12px", color: "#b8c7d2",
      wordWrap: { width: 454 }, lineSpacing: 5
    }).setOrigin(0, 0);
    this.floorPanelEvidence = this.add.text(-178, -7, "", {
      fontFamily: "'Fusion Pixel', monospace", fontSize: "11px", color: "#d8e7ec",
      wordWrap: { width: 454 }, lineSpacing: 7
    }).setOrigin(0, 0);
    this.floorPanelPrimaryButton = this.add.rectangle(-34, 104, 286, 44, 0x274d63, 1)
      .setStrokeStyle(2, 0xd7b654, 0.92)
      .setInteractive({ useHandCursor: true })
      .on("pointerup", () => this.activateFloorPanelPrimary());
    this.floorPanelPrimaryLabel = this.add.text(-34, 104, "", {
      fontFamily: "'Fusion Pixel', monospace", fontSize: "14px", color: "#f7f1dc"
    }).setOrigin(0.5);
    this.floorPanelDeductionButton = this.add.rectangle(213, 104, 180, 44, 0x17263a, 1)
      .setStrokeStyle(2, 0x60768c, 1)
      .setInteractive({ useHandCursor: true })
      .on("pointerup", () => this.openElevatorDeductionPanel());
    this.floorPanelDeductionLabel = this.add.text(213, 104, "", {
      fontFamily: "'Fusion Pixel', monospace", fontSize: "12px", color: "#a9bac7"
    }).setOrigin(0.5);
    panel.add([
      this.floorPanelTitle,
      this.floorPanelDescription,
      this.floorPanelEvidence,
      this.floorPanelPrimaryButton,
      this.floorPanelPrimaryLabel,
      this.floorPanelDeductionButton,
      this.floorPanelDeductionLabel,
      this.add.text(0, 166, "↑↓ 选层 · Enter 执行 · Space 复核 · Esc 离开", {
        fontFamily: "'Fusion Pixel', monospace", fontSize: "11px", color: "#8298af"
      }).setOrigin(0.5)
    ]);
    this.floorPanel = panel;
    this.paintFloorPanelSelection();
  }

  private isElevatorFloorReachable(
    targetFloor: DisplayFloor,
    state: GameState = this.bridge.getState()
  ): boolean {
    if (targetFloor === this.currentFloor) return true;
    if (state.chapter4.phase === "room204_restore"
      && targetFloor === 2
      && !hasChapterFourFact(state, "misaligned_stair_solved")) return false;
    return true;
  }

  private openElevatorCalibrationPanel(): void {
    this.elevatorPhase = "selecting";
    this.floorPanelMode = "elevator_calibration";
    this.elevatorReplayStartSeconds = CHAPTER_FOUR_ELEVATOR.selectableStartMinSeconds;
    this.elevatorCalibrationFailed = false;
    const panel = this.add.container(480, 270).setScrollFactor(0).setDepth(11000);
    panel.add([
      this.add.rectangle(0, 0, 540, 304, 0x07111d, 0.98).setStrokeStyle(3, 0xffd36f, 0.94),
      this.add.text(0, -126, "同步电梯历史", {
        fontFamily: "'Fusion Pixel', monospace", fontSize: "22px", color: "#f7f1dc"
      }).setOrigin(0.5),
      this.add.text(0, -96, "让一楼开门记录完整覆盖人物的六秒进入窗口", {
        fontFamily: "'Fusion Pixel', monospace", fontSize: "13px", color: "#9bb0c7"
      }).setOrigin(0.5)
    ]);
    this.elevatorCalibrationGraphics = this.add.graphics();
    this.elevatorCalibrationReadout = this.add.text(0, 74, "", {
      align: "center",
      fontFamily: "'Fusion Pixel', monospace",
      fontSize: "14px",
      color: "#f7f1dc"
    }).setOrigin(0.5);
    panel.add([this.elevatorCalibrationGraphics, this.elevatorCalibrationReadout]);

    const addControl = (x: number, label: string, onActivate: () => void) => {
      const button = this.add.rectangle(x, 116, label === "重放校准" ? 132 : 56, 38, 0x17263a, 1)
        .setStrokeStyle(2, 0x7f93aa, 1)
        .setInteractive({ useHandCursor: true })
        .on("pointerup", onActivate);
      const text = this.add.text(x, 116, label, {
        fontFamily: "'Fusion Pixel', monospace", fontSize: "14px", color: "#f7f1dc"
      }).setOrigin(0.5);
      panel.add([button, text]);
    };
    addControl(-120, "−1 秒", () => this.shiftElevatorReplayStart(-1));
    addControl(0, "重放校准", () => this.submitElevatorCalibration());
    addControl(120, "+1 秒", () => this.shiftElevatorReplayStart(1));
    panel.add(this.add.text(0, 144, "←/→ 调整 · Enter 重放 · Esc 离开", {
      fontFamily: "'Fusion Pixel', monospace", fontSize: "12px", color: "#8298af"
    }).setOrigin(0.5));
    this.floorPanel = panel;
    this.paintElevatorCalibrationPanel();
  }

  private shiftElevatorReplayStart(delta: number): void {
    this.elevatorReplayStartSeconds = Phaser.Math.Clamp(
      this.elevatorReplayStartSeconds + delta,
      CHAPTER_FOUR_ELEVATOR.selectableStartMinSeconds,
      CHAPTER_FOUR_ELEVATOR.selectableStartMaxSeconds
    );
    this.elevatorCalibrationFailed = false;
    this.paintElevatorCalibrationPanel();
  }

  private paintElevatorCalibrationPanel(): void {
    const graphics = this.elevatorCalibrationGraphics;
    const readout = this.elevatorCalibrationReadout;
    if (!graphics || !readout) return;
    const timelineX = -220;
    const timelineY = -54;
    const timelineWidth = 440;
    const timelineDuration = CHAPTER_FOUR_ELEVATOR.timelineEndSeconds
      - CHAPTER_FOUR_ELEVATOR.timelineStartSeconds;
    const toX = (seconds: number) => timelineX
      + ((seconds - CHAPTER_FOUR_ELEVATOR.timelineStartSeconds) / timelineDuration) * timelineWidth;
    const doorStart = this.elevatorReplayStartSeconds;
    const doorEnd = doorStart + CHAPTER_FOUR_ELEVATOR.firstFloorDoorOpenDurationSeconds;
    const playerStart = CHAPTER_FOUR_ELEVATOR.playerWindowStartSeconds;
    const playerEnd = CHAPTER_FOUR_ELEVATOR.playerWindowEndSeconds;

    graphics.clear();
    graphics.fillStyle(0x102033, 1).fillRect(timelineX, timelineY, timelineWidth, 60);
    graphics.lineStyle(2, 0x60768c, 1).strokeRect(timelineX, timelineY, timelineWidth, 60);
    graphics.fillStyle(0x4ca7c7, 0.9).fillRect(toX(doorStart), timelineY + 10, Math.max(4, toX(doorEnd) - toX(doorStart)), 16);
    graphics.fillStyle(0xffcf58, 0.96).fillRect(toX(playerStart), timelineY + 34, Math.max(4, toX(playerEnd) - toX(playerStart)), 14);
    graphics.lineStyle(2, 0xf7f1dc, 0.9);
    graphics.lineBetween(toX(doorStart + CHAPTER_FOUR_ELEVATOR.riseOffsetSeconds), timelineY + 4, toX(doorStart + CHAPTER_FOUR_ELEVATOR.riseOffsetSeconds), timelineY + 54);

    const formatClock = (seconds: number) => {
      const hours = Math.floor(seconds / 3600).toString().padStart(2, "0");
      const minutes = Math.floor((seconds % 3600) / 60).toString().padStart(2, "0");
      const secs = Math.floor(seconds % 60).toString().padStart(2, "0");
      return `${hours}:${minutes}:${secs}`;
    };
    readout.setText([
      `蓝色 门体开放 ${formatClock(doorStart)}—${formatClock(doorEnd)}`,
      `黄色 人物进入 ${formatClock(playerStart)}—${formatClock(playerEnd)}`,
      this.elevatorCalibrationFailed ? "重放失败：门体没有覆盖完整进入窗口" : "白线 轿厢开始上行"
    ]).setColor(this.elevatorCalibrationFailed ? "#ff987d" : "#f7f1dc");
  }

  private submitElevatorCalibration(): void {
    if (this.elevatorPhase !== "selecting" || this.pendingStoryRequest) return;
    this.requestStoryIntent({
      type: "calibrate_elevator_history",
      startSeconds: this.elevatorReplayStartSeconds
    });
  }

  private updateFloorPanelKeyboard(): void {
    if (this.floorPanelMode === "elevator_calibration") {
      if (Phaser.Input.Keyboard.JustDown(this.cursors.left)
        || Phaser.Input.Keyboard.JustDown(this.cursors.up)) this.shiftElevatorReplayStart(-1);
      if (Phaser.Input.Keyboard.JustDown(this.cursors.right)
        || Phaser.Input.Keyboard.JustDown(this.cursors.down)) this.shiftElevatorReplayStart(1);
      if (Phaser.Input.Keyboard.JustDown(this.confirmKey)) this.submitElevatorCalibration();
      if (Phaser.Input.Keyboard.JustDown(this.escapeKey)) this.cancelElevatorSelection();
      return;
    }
    if (this.floorPanelMode === "elevator_route_deduction") {
      if (Phaser.Input.Keyboard.JustDown(this.cursors.left)
        || Phaser.Input.Keyboard.JustDown(this.cursors.right)) this.shiftElevatorDeductionArrival();
      if (Phaser.Input.Keyboard.JustDown(this.cursors.up)
        || Phaser.Input.Keyboard.JustDown(this.cursors.down)) this.shiftElevatorDeductionUnserved();
      if (Phaser.Input.Keyboard.JustDown(this.confirmKey)) this.submitElevatorStopChain();
      if (Phaser.Input.Keyboard.JustDown(this.escapeKey)) this.returnToElevatorFloorPanel();
      return;
    }
    if (Phaser.Input.Keyboard.JustDown(this.cursors.left)
      || Phaser.Input.Keyboard.JustDown(this.cursors.up)) this.shiftFloorPanelSelection(-1);
    if (Phaser.Input.Keyboard.JustDown(this.cursors.right)
      || Phaser.Input.Keyboard.JustDown(this.cursors.down)) this.shiftFloorPanelSelection(1);
    if (Phaser.Input.Keyboard.JustDown(this.floorKeys[1])) this.selectFloorPanelFloor(1);
    if (Phaser.Input.Keyboard.JustDown(this.floorKeys[2])) this.selectFloorPanelFloor(2);
    if (Phaser.Input.Keyboard.JustDown(this.floorKeys[3])) this.selectFloorPanelFloor(3);
    if (Phaser.Input.Keyboard.JustDown(this.confirmKey)) this.activateFloorPanelPrimary();
    if (Phaser.Input.Keyboard.JustDown(this.interactKey)) this.openElevatorDeductionPanel();
    if (Phaser.Input.Keyboard.JustDown(this.escapeKey)) this.cancelElevatorSelection();
  }

  private selectFloorPanelFloor(floor: DisplayFloor): void {
    this.floorPanelSelection = floor;
    this.paintFloorPanelSelection();
  }

  private shiftFloorPanelSelection(delta: number): void {
    this.floorPanelSelection = Phaser.Math.Clamp(this.floorPanelSelection + delta, 1, 3) as DisplayFloor;
    this.paintFloorPanelSelection();
  }
  private paintFloorPanelSelection(): void {
    const state = this.bridge.getState();
    const facts = state.chapter4.factIds;
    for (const entry of this.floorPanelButtons) {
      const selected = entry.floor === this.floorPanelSelection;
      const record = chapterFourElevatorRecordForDisplayFloor(entry.floor);
      const recordCollected = hasChapterFourFact(state, record.factId);
      const current = entry.floor === this.currentFloor;
      entry.enabled = this.isElevatorFloorReachable(entry.floor, state);
      entry.background
        .setFillStyle(selected ? 0x263f50 : current ? 0x1c3241 : 0x142230, 1)
        .setStrokeStyle(2, selected ? 0xd7b654 : current ? 0x6fb6c6 : 0x65798b, 1);
      entry.label.setColor(selected ? "#ffe493" : "#f7f1dc");
      entry.detail.setColor(entry.enabled ? "#a9bac7" : "#7d8c98");
      entry.status.setText(
        current
          ? "当前层"
          : recordCollected
            ? "已归档"
            : entry.enabled
              ? "可直达"
              : "楼梯绕行"
      ).setColor(current ? "#79d4db" : recordCollected ? "#83d2a7" : entry.enabled ? "#d7b654" : "#b09575");
    }

    const record = chapterFourElevatorRecordForDisplayFloor(this.floorPanelSelection);
    const collected = hasChapterFourFact(state, record.factId);
    const current = this.floorPanelSelection === this.currentFloor;
    const reachable = this.isElevatorFloorReachable(this.floorPanelSelection, state);
    const recordCount = chapterFourElevatorCollectedRecordCount(facts);
    const chainSolved = hasChapterFourFact(state, "elevator_stop_chain_reconstructed");
    this.floorPanelProgress?.setText(`跨层档案 ${recordCount}/3${chainSolved ? " · 已复核" : ""}`)
      .setColor(chainSolved ? "#83d2a7" : "#b8c7d2");
    this.floorPanelTitle?.setText(`${record.displayFloor}F · ${record.shortLabel}`);
    this.floorPanelDescription?.setText([
      record.destinationLabel,
      `${record.recordTitle}  ${record.timestamp}`
    ]);
    this.floorPanelEvidence?.setText(collected
      ? [`■ ${record.evidence[0]}`, `■ ${record.evidence[1]}`]
      : current && record.floor === "A1"
        ? ["□ 一楼记录来自门外三条时间轨。", "离开轿厢后切到深色观察，在门前完成记录。"]
        : current
          ? ["□ 本层门机日志尚未归档。", state.chapter4.mode === "dark"
            ? "当前可直接读取，记录后不会限制其他楼层的调查顺序。"
            : "离开轿厢切到深色观察，再进入电梯读取本层记录。"]
          : reachable
            ? ["□ 到达该层后可读取门机记录。", "线索归档顺序不影响楼层通行。"]
            : ["□ 轿厢没有该层的历史开门记录。", "先乘到三楼，再从主楼梯完成空间校准并进入二楼。"]);

    const primaryLabel = current
      ? collected
        ? "本层记录已归档"
        : record.floor === "A1"
          ? "离开轿厢读取一楼门体轨"
          : state.chapter4.mode === "dark"
            ? `读取${record.recordTitle}`
            : "需切换深色观察"
      : reachable
        ? `前往 ${record.displayFloor}F`
        : "查看主楼梯绕行说明";
    this.floorPanelPrimaryLabel?.setText(primaryLabel).setColor(collected && current ? "#9eb0bb" : "#f7f1dc");
    this.floorPanelPrimaryButton?.setFillStyle(collected && current ? 0x1a2731 : 0x274d63, 1)
      .setStrokeStyle(2, collected && current ? 0x5e707d : 0xd7b654, 0.92);

    const deductionReady = chapterFourElevatorRecordsComplete(facts);
    this.floorPanelDeductionLabel?.setText(chainSolved
      ? "停靠链已复核"
      : deductionReady
        ? "复核停靠链"
        : `运行复核 ${recordCount}/3`)
      .setColor(chainSolved ? "#83d2a7" : deductionReady ? "#ffe493" : "#8799a6");
    this.floorPanelDeductionButton?.setFillStyle(deductionReady ? 0x3a3d2a : 0x17263a, 1)
      .setStrokeStyle(2, deductionReady ? 0xd7b654 : 0x60768c, 1);
  }

  private activateFloorPanelPrimary(): void {
    if (this.floorPanelMode !== "floors" || this.pendingMove || this.pendingStoryRequest) return;
    const state = this.bridge.getState();
    const record = chapterFourElevatorRecordForDisplayFloor(this.floorPanelSelection);
    const current = this.floorPanelSelection === this.currentFloor;
    if (!current) {
      if (!this.isElevatorFloorReachable(this.floorPanelSelection, state)) {
        this.showFeedback("二楼没有历史开门记录。先到三楼完成荣誉墙与影像调查，再从主楼梯校准空间并进入二楼。");
        return;
      }
      this.requestElevatorDestination(this.floorPanelSelection);
      return;
    }
    if (hasChapterFourFact(state, record.factId)) {
      this.showFeedback(`${record.displayFloor}F ${record.recordTitle}已经归档。`);
      return;
    }
    if (record.floor === "A1") {
      this.showFeedback("一楼起行记录位于电梯门外。离开轿厢后切到深色观察，在门前读取三条时间轨。");
      this.cancelElevatorSelection();
      return;
    }
    if (state.chapter4.mode !== "dark") {
      this.showFeedback("门机旧记录只在深色观察中可读。离开轿厢切换模式后再进入电梯。");
      return;
    }
    this.requestStoryIntent({
      type: "observe_elevator_floor_record",
      floor: record.floor as ChapterFourElevatorRecordFloor
    });
  }

  private openElevatorDeductionPanel(): void {
    if (this.floorPanelMode !== "floors" || this.pendingMove || this.pendingStoryRequest) return;
    const state = this.bridge.getState();
    if (hasChapterFourFact(state, "elevator_stop_chain_reconstructed")) {
      this.showFeedback("停靠链已复核：1F 起行，轿厢越过 2F 后在 3F 到站；2F 外呼未得到响应。");
      return;
    }
    if (!chapterFourElevatorRecordsComplete(state.chapter4.factIds)) {
      this.showFeedback(`还缺 ${3 - chapterFourElevatorCollectedRecordCount(state.chapter4.factIds)} 段楼层记录。三段可按任意顺序归档。`);
      return;
    }
    if (state.chapter4.mode !== "light") {
      this.showFeedback("记录已经齐全。离开轿厢切回浅色操作，再打开面板完成运行复核。");
      return;
    }
    this.closeFloorPanel();
    this.floorPanelMode = "elevator_route_deduction";
    this.elevatorDeductionArrivalFloor = "A2";
    this.elevatorDeductionUnservedFloor = "A3";
    this.elevatorDeductionFeedback = "";
    const panel = this.add.container(480, 270).setScrollFactor(0).setDepth(11000);
    panel.add([
      this.add.rectangle(0, 0, 690, 390, 0x07111d, 0.98).setStrokeStyle(3, 0xd7b654, 0.96),
      this.add.text(-316, -164, "复原 18:50 停靠链", {
        fontFamily: "'Fusion Pixel', monospace", fontSize: "23px", color: "#f7f1dc"
      }).setOrigin(0, 0.5),
      this.add.text(316, -164, "3/3 记录齐全", {
        fontFamily: "'Fusion Pixel', monospace", fontSize: "12px", color: "#83d2a7"
      }).setOrigin(1, 0.5)
    ]);
    const recordRows: Array<[string, string, string]> = [
      ["1F", "18:49:58", "门开八秒；18:50:06 转为上行"],
      ["2F", "18:50:04", "下行外呼亮起；门机没有开门记录"],
      ["3F", "18:50:12", "到站铃响；随后门机完整开启"]
    ];
    recordRows.forEach(([floor, timestamp, evidence], index) => {
      const y = -108 + index * 48;
      panel.add([
        this.add.rectangle(0, y, 628, 38, index === 1 ? 0x1a2833 : 0x14222d, 1)
          .setStrokeStyle(1, 0x506475, 1),
        this.add.text(-294, y, floor, {
          fontFamily: "'Fusion Pixel', monospace", fontSize: "14px", color: "#ffe493"
        }).setOrigin(0, 0.5),
        this.add.text(-246, y, timestamp, {
          fontFamily: "'Fusion Pixel', monospace", fontSize: "11px", color: "#86bfc9"
        }).setOrigin(0, 0.5),
        this.add.text(-166, y, evidence, {
          fontFamily: "'Fusion Pixel', monospace", fontSize: "11px", color: "#d7e2e7"
        }).setOrigin(0, 0.5)
      ]);
    });
    this.elevatorDeductionGraphics = this.add.graphics();
    this.elevatorDeductionReadout = this.add.text(0, 112, "", {
      align: "center",
      fontFamily: "'Fusion Pixel', monospace",
      fontSize: "11px",
      color: "#f7f1dc",
      wordWrap: { width: 610 }
    }).setOrigin(0.5);
    panel.add([
      this.elevatorDeductionGraphics,
      this.elevatorDeductionReadout,
      this.add.text(-292, 36, "轿厢离开 1F 后实际到站：", {
        fontFamily: "'Fusion Pixel', monospace", fontSize: "12px", color: "#d7e2e7"
      }).setOrigin(0, 0.5),
      this.add.text(-292, 82, "有外呼但未得到开门响应：", {
        fontFamily: "'Fusion Pixel', monospace", fontSize: "12px", color: "#d7e2e7"
      }).setOrigin(0, 0.5)
    ]);
    const addChoice = (
      x: number,
      y: number,
      label: string,
      onActivate: () => void
    ) => {
      panel.add([
        this.add.rectangle(x, y, 72, 34, 0x17263a, 0.01)
          .setInteractive({ useHandCursor: true })
          .on("pointerup", onActivate),
        this.add.text(x, y, label, {
          fontFamily: "'Fusion Pixel', monospace", fontSize: "13px", color: "#f7f1dc"
        }).setOrigin(0.5)
      ]);
    };
    addChoice(190, 36, "2F", () => {
      this.elevatorDeductionArrivalFloor = "A2";
      this.paintElevatorDeductionPanel();
    });
    addChoice(278, 36, "3F", () => {
      this.elevatorDeductionArrivalFloor = "A3";
      this.paintElevatorDeductionPanel();
    });
    addChoice(190, 82, "2F", () => {
      this.elevatorDeductionUnservedFloor = "A2";
      this.paintElevatorDeductionPanel();
    });
    addChoice(278, 82, "3F", () => {
      this.elevatorDeductionUnservedFloor = "A3";
      this.paintElevatorDeductionPanel();
    });
    panel.add([
      this.add.rectangle(0, 148, 190, 42, 0x274d63, 1)
        .setStrokeStyle(2, 0xd7b654, 0.94)
        .setInteractive({ useHandCursor: true })
        .on("pointerup", () => this.submitElevatorStopChain()),
      this.add.text(0, 148, "提交运行复核", {
        fontFamily: "'Fusion Pixel', monospace", fontSize: "14px", color: "#f7f1dc"
      }).setOrigin(0.5),
      this.add.text(0, 178, "←→ 选择实际到站 · ↑↓ 选择未响应层 · Enter 提交 · Esc 返回", {
        fontFamily: "'Fusion Pixel', monospace", fontSize: "10px", color: "#8298af"
      }).setOrigin(0.5)
    ]);
    this.floorPanel = panel;
    this.paintElevatorDeductionPanel();
  }

  private shiftElevatorDeductionArrival(): void {
    this.elevatorDeductionArrivalFloor = this.elevatorDeductionArrivalFloor === "A2" ? "A3" : "A2";
    this.elevatorDeductionFeedback = "";
    this.paintElevatorDeductionPanel();
  }

  private shiftElevatorDeductionUnserved(): void {
    this.elevatorDeductionUnservedFloor = this.elevatorDeductionUnservedFloor === "A2" ? "A3" : "A2";
    this.elevatorDeductionFeedback = "";
    this.paintElevatorDeductionPanel();
  }

  private paintElevatorDeductionPanel(): void {
    const graphics = this.elevatorDeductionGraphics;
    const readout = this.elevatorDeductionReadout;
    if (!graphics || !readout) return;
    graphics.clear();
    graphics.fillStyle(0xd7b654, 0.16).fillRoundedRect(
      this.elevatorDeductionArrivalFloor === "A2" ? 154 : 242,
      19,
      72,
      34,
      3
    );
    graphics.fillStyle(0x79c5cf, 0.12).fillRoundedRect(
      this.elevatorDeductionUnservedFloor === "A2" ? 154 : 242,
      65,
      72,
      34,
      3
    );
    graphics.lineStyle(2, 0xd7b654, 0.96).strokeRoundedRect(
      this.elevatorDeductionArrivalFloor === "A2" ? 154 : 242,
      19,
      72,
      34,
      3
    );
    graphics.lineStyle(2, 0x79c5cf, 0.96).strokeRoundedRect(
      this.elevatorDeductionUnservedFloor === "A2" ? 154 : 242,
      65,
      72,
      34,
      3
    );
    readout.setText(
      this.elevatorDeductionFeedback || "比较三段记录，再分别确认实际到站层和未响应外呼层。"
    ).setColor(this.elevatorDeductionFeedback ? "#ff9b82" : "#8298af");
  }

  private submitElevatorStopChain(): void {
    if (this.floorPanelMode !== "elevator_route_deduction" || this.pendingStoryRequest) return;
    this.requestStoryIntent({
      type: "reconstruct_elevator_stop_chain",
      actualArrivalFloor: this.elevatorDeductionArrivalFloor,
      unservedCallFloor: this.elevatorDeductionUnservedFloor
    });
  }

  private returnToElevatorFloorPanel(): void {
    this.closeFloorPanel();
    this.openFloorPanel();
  }

  private closeFloorPanel(): void {
    this.floorPanel?.destroy(true);
    this.floorPanel = null;
    this.floorPanelMode = "floors";
    this.floorPanelButtons = [];
    this.elevatorCalibrationGraphics = null;
    this.elevatorCalibrationReadout = null;
    this.floorPanelTitle = null;
    this.floorPanelDescription = null;
    this.floorPanelEvidence = null;
    this.floorPanelProgress = null;
    this.floorPanelPrimaryButton = null;
    this.floorPanelPrimaryLabel = null;
    this.floorPanelDeductionButton = null;
    this.floorPanelDeductionLabel = null;
    this.elevatorDeductionGraphics = null;
    this.elevatorDeductionReadout = null;
  }
  private requestElevatorDestination(targetFloor: DisplayFloor): void {
    if (this.elevatorPhase !== "selecting"
      || this.pendingMove
      || OPENING_PHASES.has(this.bridge.getState().chapter4.phase)) return;
    const state = this.bridge.getState();
    if (state.chapter4.phase === "room204_restore"
      && this.currentFloor === 1
      && targetFloor === 2
      && !hasChapterFourFact(state, "misaligned_stair_solved")) {
      this.showFeedback("二楼外呼存在，但轿厢没有开门记录。先乘到三楼，再从错位主楼梯进入二楼。");
      return;
    }
    if (targetFloor === this.currentFloor) {
      this.showFeedback(`当前已在 ${targetFloor}F`);
      return;
    }
    this.requestMove(targetFloor, "elevator");
  }
  private cancelElevatorSelection(): void {
    if (this.elevatorPhase !== "selecting" || this.pendingMove) return;
    this.closeFloorPanel();
    this.beginElevatorExit(this.currentFloor);
  }

  private ensureFinalClockRuntime(state: GameState = this.bridge.getState()): void {
    if (this.finalClockEndpointZone?.active
      && this.phaseRuntimeTargets.has(FINAL_CLOCK_RUNTIME.endpoint.targetId)) return;
    this.destroyFinalClockRuntime("recreate");
    try {
      this.ensureHallClockStateSprite(
        state.chapter4.phase === "return_to_clock"
          ? "0754_calibrated"
          : FINAL_CLOCK_RUNTIME.clockFrame
      );
    } catch (error) {
      this.persistentContractFailures.add(`final_clock_visible_frame:${errorMessage(error)}`);
      return;
    }
    const floor = getFloor(1);
    const endpoint = this.finalClockPointForAngle(FINAL_CLOCK_RUNTIME.initialAngleDegrees);
    this.finalClockMinuteAngle = FINAL_CLOCK_RUNTIME.initialAngleDegrees;
    this.finalClockMinuteLine = this.add.line(
      0,
      0,
      floor.offsetX + FINAL_CLOCK_RUNTIME.clockCenter.x,
      FINAL_CLOCK_RUNTIME.clockCenter.y,
      floor.offsetX + endpoint.x,
      endpoint.y,
      0xd8edf0,
      0.96
    ).setOrigin(0, 0)
      .setLineWidth(3, 2)
      .setDepth(PLAYER_DEPTH_BASE + 160);
    this.finalClockEndpointHandle = this.add.circle(
      floor.offsetX + endpoint.x,
      endpoint.y,
      FINAL_CLOCK_RUNTIME.endpoint.installationBounds.width / 2,
      0xf2d47b,
      0.92
    ).setStrokeStyle(2, 0xf7f1dc, 0.98)
      .setDepth(PLAYER_DEPTH_BASE + 162);
    const visibleBounds = this.finalClockEndpointHandle.getBounds();
    const derived = {
      x: Math.floor(visibleBounds.left - floor.offsetX),
      y: Math.floor(visibleBounds.top),
      width: Math.ceil(visibleBounds.right - floor.offsetX) - Math.floor(visibleBounds.left - floor.offsetX),
      height: Math.ceil(visibleBounds.bottom) - Math.floor(visibleBounds.top)
    };
    if (!rectEquals(derived, FINAL_CLOCK_RUNTIME.endpoint.installationBounds)) {
      this.persistentContractFailures.add(`final_clock_endpoint_bounds:${JSON.stringify(derived)}`);
      this.destroyFinalClockRuntime("invalid_bounds");
      return;
    }
    this.finalClockEndpointZone = this.add.zone(
      floor.offsetX + rectCenterX(derived),
      rectCenterY(derived),
      derived.width,
      derived.height
    );
    this.phaseRuntimeTargets.set(FINAL_CLOCK_RUNTIME.endpoint.targetId, {
      targetId: FINAL_CLOCK_RUNTIME.endpoint.targetId,
      entityId: FINAL_CLOCK_RUNTIME.endpoint.entityId,
      floor: 1,
      boundsObject: this.finalClockEndpointZone
    });
    if (state.chapter4.phase === "maintenance_repair") {
      this.finalClockEndpointHandle.setInteractive({ useHandCursor: true });
      this.finalClockEndpointHandle.on("pointerdown", (pointer: Phaser.Input.Pointer) => {
        const domPointerId = this.finalClockPendingDomPointerId;
        this.finalClockPendingDomPointerId = null;
        this.requestFinalClockDrag(false, pointer.id, domPointerId);
      });
      this.input.on("pointermove", this.handleFinalClockPointerMove, this);
      this.input.on("pointerup", this.handleFinalClockPointerUp, this);
      this.input.on("pointerupoutside", this.handleFinalClockPointerUp, this);
      this.finalClockDomCanvas = this.game.canvas;
      this.finalClockDomCanvas.addEventListener(
        "pointerdown",
        this.handleFinalClockDomPointerDown,
        { capture: true, passive: true }
      );
    }
  }

  private requestFinalClockDrag(
    autoCommit: boolean,
    pointerId: number | null,
    domPointerId: number | null = null
  ): void {
    if (this.pendingStoryRequest || this.storyPresentation !== "idle") return;
    const target = this.resolveActionableTargets().find(
      (candidate) => candidate.contract.id === FINAL_CLOCK_RUNTIME.endpoint.targetId
    );
    if (!target) {
      this.showRuntimeInteractionFailure("minute_endpoint_missing");
      return;
    }
    const runtimeTarget = this.resolveRuntimeTargetContext(target.contract, target.bounds);
    if (!runtimeTarget) {
      this.showRuntimeInteractionFailure("minute_endpoint_runtime_bounds_missing");
      return;
    }
    this.finalClockDragAutoCommit = autoCommit;
    this.finalClockDragPointerId = pointerId;
    this.finalClockDragDomPointerId = domPointerId;
    this.requestStoryIntent({
      type: "begin_final_clock_drag",
      targetId: FINAL_CLOCK_RUNTIME.endpoint.targetId,
      spatial: this.storySpatialResult(target)
    }, target.contract.id, runtimeTarget);
  }

  private beginAcceptedFinalClockDrag(): void {
    this.finalClockDragActive = true;
    this.installFinalClockDomCancelListener();
    this.storyPresentation = "idle";
    this.syncStoryInputLock();
    this.finalClockDragSafetyTimer?.remove(false);
    this.finalClockDragSafetyTimer = this.time.delayedCall(
      FINAL_CLOCK_DRAG_SAFETY_TIMEOUT_MS,
      () => {
        this.finalClockDragSafetyTimer = null;
        if (!this.finalClockDragActive) return;
        this.rollbackMinuteTheftToCommittedState("拨钟操作已取消，旧钟和纸条均已恢复，可重试。");
      }
    );
    const binding = this.phaseRuntimeTargets.get(FINAL_CLOCK_RUNTIME.endpoint.targetId);
    const bounds = binding ? this.outwardPhaseRuntimeBounds(binding) : null;
    this.safeBridgeEmit("final_clock_drag_started", {
      targetId: FINAL_CLOCK_RUNTIME.endpoint.targetId,
      bounds,
      approximate: FINAL_CLOCK_RUNTIME.endpoint.approximate,
      input: this.finalClockDragAutoCommit ? "keyboard" : "pointer"
    });
    if (this.finalClockDragAutoCommit) this.finishFinalClockDrag();
  }

  private handleFinalClockPointerMove(pointer: Phaser.Input.Pointer): void {
    if (!this.finalClockDragActive || this.finalClockDragPointerId !== pointer.id) return;
    const floor = getFloor(1);
    const world = this.cameras.main.getWorldPoint(pointer.x, pointer.y);
    const localX = world.x - floor.offsetX;
    const angle = Phaser.Math.RadToDeg(Math.atan2(
      world.y - FINAL_CLOCK_RUNTIME.clockCenter.y,
      localX - FINAL_CLOCK_RUNTIME.clockCenter.x
    ));
    this.setFinalClockMinuteAngle(angle);
    if (shortestAngleDistance(angle, FINAL_CLOCK_RUNTIME.targetAngleDegrees)
      <= FINAL_CLOCK_RUNTIME.releaseToleranceDegrees) {
      this.finishFinalClockDrag();
    }
  }

  private handleFinalClockPointerUp(pointer: Phaser.Input.Pointer): void {
    if (!this.finalClockDragActive || this.finalClockDragPointerId !== pointer.id) return;
    if (pointer.wasCanceled) {
      this.rollbackMinuteTheftToCommittedState("拨钟操作已取消，旧钟和纸条均已恢复，可重试。");
      return;
    }
    this.finishFinalClockDrag();
  }

  private readonly handleFinalClockDomPointerDown = (event: PointerEvent): void => {
    this.finalClockPendingDomPointerId = event.pointerId;
  };

  private readonly handleFinalClockDomPointerCancel = (event: PointerEvent): void => {
    if (!this.finalClockDragActive
      || this.finalClockDragDomPointerId === null
      || event.pointerId !== this.finalClockDragDomPointerId) return;
    this.rollbackMinuteTheftToCommittedState(
      "拨钟操作已取消，旧钟和纸条均已恢复，可重试。"
    );
  };

  private installFinalClockDomCancelListener(): void {
    if (!this.finalClockDomCanvas
      || this.finalClockDragDomPointerId === null
      || this.finalClockDomCancelListening) return;
    this.finalClockDomCanvas.addEventListener(
      "pointercancel",
      this.handleFinalClockDomPointerCancel,
      true
    );
    this.finalClockDomCancelListening = true;
  }

  private removeFinalClockDomCancelListener(): void {
    if (this.finalClockDomCanvas && this.finalClockDomCancelListening) {
      this.finalClockDomCanvas.removeEventListener(
        "pointercancel",
        this.handleFinalClockDomPointerCancel,
        true
      );
    }
    this.finalClockDomCancelListening = false;
    this.finalClockDragDomPointerId = null;
  }

  private finishFinalClockDrag(): void {
    if (!this.finalClockDragActive) return;
    this.removeFinalClockDomCancelListener();
    this.finalClockDragSafetyTimer?.remove(false);
    this.finalClockDragSafetyTimer = null;
    this.finalClockDragActive = false;
    this.finalClockDragPointerId = null;
    this.beginMinuteTheftPresentation();
  }

  private beginMinuteTheftPresentation(): void {
    const state = this.bridge.getState();
    if (this.storyPresentation !== "idle"
      || this.pendingStoryRequest
      || state.chapter4.phase !== "maintenance_repair"
      || !hasChapterFourFact(state, "clock_gear_repaired")
      || !state.items.attendanceRecordPaper) {
      this.rollbackMinuteTheftToCommittedState("最终拨钟条件尚未满足，可重试。");
      return;
    }
    this.storyPresentation = "minute_theft";
    this.syncStoryInputLock();
    this.clearStoryPresentationTimers();
    this.phaseRuntimeTargets.get(FINAL_CLOCK_RUNTIME.endpoint.targetId)?.boundsObject.setVisible(false);
    const tweenState = { angle: this.finalClockMinuteAngle };
    this.finalClockTween?.stop();
    this.finalClockTween = this.tweens.add({
      targets: tweenState,
      angle: FINAL_CLOCK_RUNTIME.targetAngleDegrees,
      duration: FINAL_CLOCK_RUNTIME.presentation.minuteHandAtMs,
      ease: "Sine.Out",
      onUpdate: () => this.setFinalClockMinuteAngle(tweenState.angle),
      onComplete: () => {
        this.finalClockTween = null;
        this.setFinalClockMinuteAngle(FINAL_CLOCK_RUNTIME.targetAngleDegrees);
      }
    });
    this.scheduleStoryPresentation(FINAL_CLOCK_RUNTIME.presentation.paperFlightAtMs, () => {
      this.startMinuteTheftPaperFlight();
    });
    this.scheduleStoryPresentation(FINAL_CLOCK_RUNTIME.presentation.commitAtMs, () => {
      this.requestStoryIntent({ type: "complete_minute_theft" });
    });
    this.scheduleStoryPresentation(FINAL_CLOCK_RUNTIME.presentation.feedbackAtMs, () => {
      const committed = this.bridge.getState();
      if (committed.chapter4.phase !== "blackout_light_grid"
        || committed.chapter4.timeState !== "0754_blackout"
        || committed.chapter4.worldTimeSeconds !== 28440
        || committed.chapter4.phoneStatusTimeSeconds !== 28440
        || !committed.chapter4.phoneStatusTimeTrusted
        || committed.items.attendanceRecordPaper
        || !hasChapterFourFact(committed, "paper_temporarily_out_of_inventory")) return;
      try {
        this.ensureHallClockStateSprite("0754_calibrated");
      } catch (error) {
        this.persistentContractFailures.add(`minute_theft_0754_visual:${errorMessage(error)}`);
      }
      this.minuteTheftPaperSprite?.destroy();
      this.minuteTheftPaperSprite = null;
      this.storyPresentation = "idle";
      this.syncStoryInputLock();
      this.safeBridgeEmit("rpg_subtitle", {
        text: "时间校准至 07:54。纸条带走了最后一分钟。",
        tone: "system",
        durationMs: 2600
      });
    });
  }

  private startMinuteTheftPaperFlight(): void {
    const floor = getFloor(1);
    const endpoint = this.finalClockPointForAngle(FINAL_CLOCK_RUNTIME.targetAngleDegrees);
    const foot = this.playerFootPoint(floor);
    this.minuteTheftPaperSprite?.destroy();
    this.minuteTheftPaperSprite = this.add.sprite(
      foot.worldX,
      foot.y - 34,
      "chapter4_story_items",
      "sign_in_record_paper"
    ).setScale(0.15)
      .setDepth(PLAYER_DEPTH_BASE + 220)
      .setAngle(-12);
    this.safeBridgeEmit("minute_theft_paper_flight", {
      from: { x: foot.worldX, y: foot.y - 34 },
      to: { x: floor.offsetX + endpoint.x, y: endpoint.y },
      targetId: FINAL_CLOCK_RUNTIME.endpoint.targetId
    });
    this.minuteTheftPaperTween?.stop();
    this.minuteTheftPaperTween = this.tweens.add({
      targets: this.minuteTheftPaperSprite,
      x: floor.offsetX + endpoint.x,
      y: endpoint.y,
      angle: 28,
      duration: Math.max(120, FINAL_CLOCK_RUNTIME.presentation.commitAtMs
        - FINAL_CLOCK_RUNTIME.presentation.paperFlightAtMs - 40),
      ease: "Sine.InOut",
      onComplete: () => { this.minuteTheftPaperTween = null; }
    });
  }

  private setFinalClockMinuteAngle(angle: number): void {
    this.finalClockMinuteAngle = angle;
    const floor = getFloor(1);
    const endpoint = this.finalClockPointForAngle(angle);
    this.finalClockEndpointHandle?.setPosition(floor.offsetX + endpoint.x, endpoint.y);
    this.finalClockMinuteLine?.setTo(
      floor.offsetX + FINAL_CLOCK_RUNTIME.clockCenter.x,
      FINAL_CLOCK_RUNTIME.clockCenter.y,
      floor.offsetX + endpoint.x,
      endpoint.y
    );
  }

  private finalClockPointForAngle(angleDegrees: number): { x: number; y: number } {
    const radians = Phaser.Math.DegToRad(angleDegrees);
    return {
      x: Math.round(
        FINAL_CLOCK_RUNTIME.clockCenter.x
          + Math.cos(radians) * FINAL_CLOCK_RUNTIME.minuteHandRadius
      ),
      y: Math.round(
        FINAL_CLOCK_RUNTIME.clockCenter.y
          + Math.sin(radians) * FINAL_CLOCK_RUNTIME.minuteHandRadius
      )
    };
  }

  private rollbackMinuteTheftToCommittedState(feedback: string): void {
    this.clearStoryPresentationTimers();
    this.removeFinalClockDomCancelListener();
    this.finalClockDragSafetyTimer?.remove(false);
    this.finalClockDragSafetyTimer = null;
    this.finalClockTween?.stop();
    this.finalClockTween = null;
    this.minuteTheftPaperTween?.stop();
    this.minuteTheftPaperTween = null;
    this.minuteTheftPaperSprite?.destroy();
    this.minuteTheftPaperSprite = null;
    this.finalClockDragActive = false;
    this.finalClockDragPointerId = null;
    this.finalClockDragAutoCommit = false;
    const committed = this.bridge.getState();
    const retryable = committed.chapter4.phase === "maintenance_repair"
      && committed.chapter4.mode === "light"
      && hasChapterFourFact(committed, "clock_gear_repaired")
      && committed.items.attendanceRecordPaper
      && !hasChapterFourFact(committed, "paper_temporarily_out_of_inventory");
    if (retryable) {
      this.setFinalClockMinuteAngle(FINAL_CLOCK_RUNTIME.initialAngleDegrees);
      this.phaseRuntimeTargets.get(FINAL_CLOCK_RUNTIME.endpoint.targetId)?.boundsObject.setVisible(true);
      try {
        this.ensureHallClockStateSprite("gear_running");
      } catch (error) {
        this.persistentContractFailures.add(`minute_theft_rollback_clock:${errorMessage(error)}`);
      }
    } else {
      this.destroyFinalClockRuntime("minute_theft_not_retryable");
    }
    this.storyPresentation = "idle";
    this.storyRetryNotBeforeMs = this.time.now + STORY_RETRY_DELAY_MS;
    if (feedback) {
      this.persistentContractFailures.add(`minute_theft_recovery:${feedback}`);
      this.showFeedback("进度已恢复，请重试当前操作。");
    }
    this.syncStoryInputLock();
  }

  private ensureLightGridRuntime(state: GameState): void {
    if (!this.phaseRuntimeTargets.has(LIGHT_GRID_RUNTIME.panel.targetId)) {
      this.createLightGridRuntime();
    }
    const targetVisible = state.chapter4.phase === "blackout_light_grid"
      && !state.chapter4.lightGrid.locked
      && !hasChapterFourFact(state, "light_grid_locked");
    this.phaseRuntimeTargets.get(LIGHT_GRID_RUNTIME.panel.targetId)?.boundsObject.setVisible(targetVisible);
    for (const region of LIGHT_GRID_RUNTIME.visualRegions) {
      const on = (state.chapter4.lightGrid.mask & (1 << lightZoneBit(region.id))) !== 0;
      this.lightGridOverlays.get(region.id)?.setFillStyle(0x020711, on ? 0.08 : 0.7);
    }
    const panelFrame = state.chapter4.lightGrid.locked
      ? "open_restored"
      : this.hostPowerPanelOpen
        ? state.chapter4.lightGrid.mask === chapterFourContent.lightGrid.initialMask
          ? "open_powered"
          : "open_partial"
        : "closed";
    if (this.lightGridPanelSprite?.active
      && this.lightGridPanelSprite.frame.name !== panelFrame) {
      this.lightGridPanelSprite.setFrame(panelFrame);
    }
  }

  private createLightGridRuntime(): void {
    this.destroyLightGridRuntime("recreate");
    const floor = getFloor(1);
    const bounds = LIGHT_GRID_RUNTIME.panel.installationBounds;
    const zone = this.add.zone(
      floor.offsetX + rectCenterX(bounds),
      rectCenterY(bounds),
      bounds.width,
      bounds.height
    );
    const outward = zone.getBounds();
    const derived = {
      x: Math.floor(outward.left - floor.offsetX),
      y: Math.floor(outward.top),
      width: Math.ceil(outward.right - floor.offsetX) - Math.floor(outward.left - floor.offsetX),
      height: Math.ceil(outward.bottom) - Math.floor(outward.top)
    };
    if (!rectEquals(derived, bounds)) {
      zone.destroy();
      this.persistentContractFailures.add(`light_grid_panel_bounds:${JSON.stringify(derived)}`);
      return;
    }
    this.phaseRuntimeTargets.set(LIGHT_GRID_RUNTIME.panel.targetId, {
      targetId: LIGHT_GRID_RUNTIME.panel.targetId,
      entityId: LIGHT_GRID_RUNTIME.panel.entityId,
      floor: 1,
      boundsObject: zone
    });
    this.lightGridPanelSprite = this.add.sprite(
      floor.offsetX + rectRight(LIGHT_GRID_RUNTIME.panel.visibleBoxBounds),
      LIGHT_GRID_RUNTIME.panel.visibleBoxBounds.y,
      "chapter4_power_panel_states",
      "closed"
    ).setOrigin(1, 0)
      .setScale(0.11)
      .setDepth(PLAYER_DEPTH_BASE + LIGHT_GRID_RUNTIME.panel.visibleBoxBounds.y + 4);
    for (const region of LIGHT_GRID_RUNTIME.visualRegions) {
      const overlay = this.add.rectangle(
        floor.offsetX + rectCenterX(region.bounds),
        rectCenterY(region.bounds),
        region.bounds.width,
        region.bounds.height,
        0x020711,
        0.7
      ).setDepth(PLAYER_DEPTH_BASE - 180);
      this.lightGridOverlays.set(region.id, overlay);
    }
  }

  private destroyFinalClockRuntime(_reason: string): void {
    this.input?.off("pointermove", this.handleFinalClockPointerMove, this);
    this.input?.off("pointerup", this.handleFinalClockPointerUp, this);
    this.input?.off("pointerupoutside", this.handleFinalClockPointerUp, this);
    this.removeFinalClockDomCancelListener();
    if (this.finalClockDomCanvas) {
      this.finalClockDomCanvas.removeEventListener(
        "pointerdown",
        this.handleFinalClockDomPointerDown,
        true
      );
    }
    this.finalClockDomCanvas = null;
    this.finalClockPendingDomPointerId = null;
    this.finalClockDragSafetyTimer?.remove(false);
    this.finalClockDragSafetyTimer = null;
    this.finalClockTween?.stop();
    this.finalClockTween = null;
    this.minuteTheftPaperTween?.stop();
    this.minuteTheftPaperTween = null;
    this.finalClockMinuteLine?.destroy();
    this.finalClockMinuteLine = null;
    this.finalClockEndpointHandle?.destroy();
    this.finalClockEndpointHandle = null;
    this.finalClockEndpointZone?.destroy();
    this.finalClockEndpointZone = null;
    this.minuteTheftPaperSprite?.destroy();
    this.minuteTheftPaperSprite = null;
    this.phaseRuntimeTargets.delete(FINAL_CLOCK_RUNTIME.endpoint.targetId);
    this.finalClockDragActive = false;
    this.finalClockDragPointerId = null;
    this.finalClockDragAutoCommit = false;
    this.finalClockMinuteAngle = FINAL_CLOCK_RUNTIME.initialAngleDegrees;
  }

  private destroyLightGridRuntime(_reason: string): void {
    this.phaseRuntimeTargets.get(LIGHT_GRID_RUNTIME.panel.targetId)?.boundsObject.destroy();
    this.phaseRuntimeTargets.delete(LIGHT_GRID_RUNTIME.panel.targetId);
    this.lightGridPanelSprite?.destroy();
    this.lightGridPanelSprite = null;
    for (const overlay of this.lightGridOverlays.values()) overlay.destroy();
    this.lightGridOverlays.clear();
    this.hostPowerPanelOpen = false;
  }

  private destroyTask11Runtime(reason: string): void {
    this.destroyFinalClockRuntime(reason);
    this.destroyLightGridRuntime(reason);
  }

  private preferredDestinationForFloor(targetFloor: DisplayFloor): {
    roomId: string;
    checkpoint: RpgCheckpointId;
  } {
    const state = this.bridge.getState();
    const override = PHASE_TRAVEL_ROOM_OVERRIDES[state.chapter4.phase]?.[targetFloor];
    if (override) return override;
    const floor = getFloor(targetFloor);
    return { roomId: floor.roomId, checkpoint: floor.checkpoint };
  }

  private requestMove(targetFloor: DisplayFloor, route: TravelRoute): void {
    if (this.pendingMove
      || targetFloor === this.currentFloor
      || OPENING_PHASES.has(this.bridge.getState().chapter4.phase)) return;
    const destinationFloor = getFloor(targetFloor);
    const destination = this.preferredDestinationForFloor(targetFloor);
    const requestId = `c4-755-scene-${++this.requestSerial}`;
    this.pendingMove = { requestId, fromFloor: this.currentFloor, targetFloor, route };
    this.pendingMoveTimer?.remove(false);
    this.pendingMoveTimer = this.time.delayedCall(REQUEST_TIMEOUT_MS, () => {
      if (this.pendingMove?.requestId !== requestId) return;
      if (this.pendingMove.route === "stair" && this.finalChaseState?.phase === "portal_transfer") {
        this.finalChaseState = resolveChapterFourFinalChasePortal(this.finalChaseState, false);
      }
      this.pendingMove = null;
      this.pendingMoveTimer = null;
      this.showRuntimeInteractionFailure("floor_request_timeout");
    });
    const state = this.bridge.getState();
    const authoredStairTransfer = route === "stair"
      && ((state.chapter4.phase === "final_chase" && this.currentFloor === 1 && targetFloor === 2)
        || (state.chapter4.phase === "return_to_clock" && this.currentFloor === 2 && targetFloor === 1));
    if (authoredStairTransfer) {
      this.request755Intent({
        type: "traverse_main_stair",
        fromFloor: getFloor(this.currentFloor).storyFloor as "A1" | "A2",
        toFloor: destinationFloor.storyFloor as "A1" | "A2",
        expectedAttempt: state.chapter4.chaseAttempt
      }, requestId);
      return;
    }
    this.request755Intent({
      type: "move_to_location",
      floor: destinationFloor.storyFloor,
      roomId: destination.roomId,
      checkpoint: destination.checkpoint
    }, requestId);
  }

  private requestStoryIntent(
    intent: ChapterFour755Intent,
    targetId?: string,
    runtimeTarget?: ChapterFour755RuntimeTargetContext
  ): void {
    if (this.pendingStoryRequest) return;
    const requestId = `c4-755-story-${++this.requestSerial}`;
    const timer = this.time.delayedCall(STORY_REQUEST_TIMEOUT_MS, () => {
      if (this.pendingStoryRequest?.requestId !== requestId) return;
      const timedOutIntentType = this.pendingStoryRequest.intentType;
      this.pendingStoryRequest = null;
      if (timedOutIntentType === "complete_bakery_conveyor_stop") {
        this.rollbackBakeryConveyorStopToCommittedState(
          "传送带停机确认超时，已恢复到当前进度，将自动重试。"
        );
        return;
      }
      if (timedOutIntentType === "complete_room204_projection") {
        this.rollbackRoom204ProjectionToCommittedState(
          "07:55 残影投影确认超时，已回到已完成的教室布局，将自动重试。"
        );
        return;
      }
      if (timedOutIntentType === "begin_final_clock_drag"
        || timedOutIntentType === "complete_minute_theft") {
        this.rollbackMinuteTheftToCommittedState(
          "最终拨钟确认超时，已恢复转动的旧钟和签到纸条，可重试。"
        );
        return;
      }
      if (timedOutIntentType === "reach_202_threshold"
        && this.finalChaseState?.phase === "finish_pending") {
        this.finalChaseState = resolveChapterFourFinalChaseFinish(this.finalChaseState, false);
      }
      if (timedOutIntentType === "fail_chase"
        && this.finalChaseState?.phase === "failure_pending") {
        this.finalChaseState = resolveChapterFourFinalChaseFailure(this.finalChaseState, false);
      }
      this.storyPresentation = "idle";
      this.destroyExternalTimeOverlay();
      this.storyRetryNotBeforeMs = this.time.now + STORY_RETRY_DELAY_MS;
      this.showRuntimeInteractionFailure(`story_intent_timeout:${timedOutIntentType}`);
      this.syncStoryInputLock();
    });
    this.pendingStoryRequest = { requestId, intentType: intent.type, targetId, timer };
    this.syncStoryInputLock();
    this.request755Intent(intent, requestId, runtimeTarget);
  }

  private request755Intent(
    intent: ChapterFour755Intent,
    requestId = `c4-755-scene-${++this.requestSerial}`,
    runtimeTarget?: ChapterFour755RuntimeTargetContext
  ): void {
    this.bridge.emit("rpg_chapter4_755_intent_requested", {
      requestId,
      intent,
      ...(runtimeTarget ? { runtimeTarget } : {})
    });
  }

  private handleIntentResolved(payload?: Record<string, unknown>): void {
    const intentType = String(payload?.intentType ?? "");
    const targetId = this.pendingStoryRequest
      && String(payload?.requestId ?? "") === this.pendingStoryRequest.requestId
        ? this.pendingStoryRequest.targetId
        : undefined;
    const visualHintPuzzleId = selectChapterFourVisualHintPuzzleForIntent(intentType, targetId);
    if (visualHintPuzzleId) {
      if (resultAccepted(payload)) {
        this.clearVisualHintForIntent(intentType, targetId);
      } else if (!["invalid_request", "duplicate_request", "system_failure", "already_complete"]
        .includes(resultReason(payload))) {
        this.recordVisualHintFailure(visualHintPuzzleId);
      }
    }
    if (this.pendingStoryRequest
      && String(payload?.requestId ?? "") === this.pendingStoryRequest.requestId) {
      this.handleStoryIntentResolved(payload);
      return;
    }
    const pending = this.pendingMove;
    if (!pending || String(payload?.requestId ?? "") !== pending.requestId) return;
    this.pendingMoveTimer?.remove(false);
    this.pendingMoveTimer = null;
    this.pendingMove = null;
    if (!resultAccepted(payload)) {
      if (pending.route === "stair" && this.finalChaseState?.phase === "portal_transfer") {
        this.finalChaseState = resolveChapterFourFinalChasePortal(this.finalChaseState, false);
      }
      const reason = resultReason(payload);
      const feedback: Readonly<Record<string, string>> = {
        already_complete: "当前楼层状态已经同步。",
        wrong_mode: "请切回浅色操作后再移动。",
        locked: "当前剧情阶段没有开放这条楼层通道。",
        inactive: "当前无法前往该楼层。"
      };
      if (["invalid_request", "duplicate_request", "system_failure"].includes(reason)) {
        this.showRuntimeInteractionFailure(`floor_request_rejected:${reason}`);
      } else {
        this.showFeedback(feedback[reason] ?? "当前无法前往该楼层。");
      }
      return;
    }
    if (pending.route === "stair" && this.finalChaseState?.phase === "portal_transfer") {
      this.finalChaseState = resolveChapterFourFinalChasePortal(this.finalChaseState, true);
    }
    // Transfer animation starts only after the controller accepts the authored
    // move or main-stair transaction.
    if (pending.route === "elevator") this.beginAcceptedElevatorTravel(pending);
    else this.beginAcceptedStairTransfer(pending);
  }

  private handleStoryIntentResolved(payload?: Record<string, unknown>): void {
    const pending = this.pendingStoryRequest;
    if (!pending) return;
    pending.timer.remove(false);
    this.pendingStoryRequest = null;
    if (!resultAccepted(payload)) {
      const detail = String(payload?.feedback ?? "当前剧情条件尚未满足。");
      if (pending.intentType === "calibrate_elevator_history") {
        this.elevatorCalibrationFailed = true;
        this.paintElevatorCalibrationPanel();
        this.showFeedback("门体开放区间未完整覆盖六秒进入窗口。调整重放起点后再试。");
        this.syncStoryInputLock();
        return;
      }
      if (pending.intentType === "reconstruct_elevator_stop_chain"
        && this.floorPanelMode === "elevator_route_deduction") {
        this.elevatorDeductionFeedback = "复核不一致：重新比较二楼外呼与三楼门机时间。";
        this.paintElevatorDeductionPanel();
        this.showFeedback("实际到站层与未响应外呼层不能互换。重新比较三段记录。");
        this.syncStoryInputLock();
        return;
      }
      if (pending.intentType === "reach_202_threshold"
        && this.finalChaseState?.phase === "finish_pending") {
        this.finalChaseState = resolveChapterFourFinalChaseFinish(this.finalChaseState, false);
      }
      if (pending.intentType === "fail_chase"
        && this.finalChaseState?.phase === "failure_pending") {
        this.finalChaseState = resolveChapterFourFinalChaseFailure(this.finalChaseState, false);
      }
      if (pending.intentType === "complete_bakery_conveyor_stop") {
        this.rollbackBakeryConveyorStopToCommittedState(
          `${detail}已恢复到当前进度，将自动重试。`
        );
        return;
      }
      if (pending.intentType === "complete_room204_projection") {
        this.rollbackRoom204ProjectionToCommittedState(
          `${detail}已回到已完成的教室布局，将自动重试。`
        );
        return;
      }
      if (pending.intentType === "begin_final_clock_drag"
        || pending.intentType === "complete_minute_theft") {
        this.rollbackMinuteTheftToCommittedState(
          `${detail}已恢复转动的旧钟和签到纸条，可重试。`
        );
        return;
      }
      this.storyPresentation = "idle";
      this.destroyExternalTimeOverlay();
      this.storyRetryNotBeforeMs = this.time.now + STORY_RETRY_DELAY_MS;
      let inventoryFeedbackEmitted = false;
      if (pending.intentType === "install_hour_hand") {
        this.emitDropFeedback("oldClockHourHand", resultReason(payload), detail);
        inventoryFeedbackEmitted = true;
      }
      if (pending.intentType === "install_final_minute") {
        this.emitDropFeedback("finalMinute", resultReason(payload), detail);
        inventoryFeedbackEmitted = true;
      }
      if (pending.intentType === "read_campus_card") {
        this.emitDropFeedback("campusCard", resultReason(payload), detail);
        inventoryFeedbackEmitted = true;
      }
      if (pending.intentType === "submit_attendance_paper") {
        this.emitDropFeedback("attendanceRecordPaper", resultReason(payload), detail);
        inventoryFeedbackEmitted = true;
      }
      if (pending.intentType === "open_cart_wheel_cover") {
        this.emitDropFeedback("shortPryBar", resultReason(payload), detail);
        inventoryFeedbackEmitted = true;
      }
      if (pending.intentType === "lubricate_cart_wheel"
        || pending.intentType === "lubricate_clock_gear") {
        this.emitDropFeedback("universalLubricatingOil", resultReason(payload), detail);
        inventoryFeedbackEmitted = true;
      }
      if (!inventoryFeedbackEmitted) this.showFeedback(detail);
      this.syncStoryInputLock();
      return;
    }
    switch (pending.intentType) {
      case "complete_opening_paper_flight":
        this.storyPresentation = "idle";
        this.ensureOpeningPaperAtNoticeboard();
        break;
      case "catch_attendance_paper":
        this.openingPaperSprite?.destroy();
        this.openingPaperSprite = null;
        this.storyPresentation = "idle";
        this.beginExternalTimeRejection();
        break;
      case "resolve_external_time_rejection":
        this.destroyExternalTimeOverlay();
        this.storyPresentation = "idle";
        break;
      case "resolve_hall_clock_inspection":
        this.storyPresentation = "idle";
        break;
      case "inspect_hall_clock":
        this.storyPresentation = "idle";
        this.beginHallClockInspection();
        break;
      case "pull_hall_clock":
        this.storyPresentation = "idle";
        this.beginFirstHallClockPullPresentation();
        break;
      case "inspect_bakery_conveyor_lamp":
        this.storyPresentation = "idle";
        this.beginBakeryConveyorStopPresentation();
        break;
      case "complete_bakery_conveyor_stop": {
        const state = this.bridge.getState();
        if (!hasChapterFourFact(state, "bakery_hour_hand_exposed")) {
          this.rollbackBakeryConveyorStopToCommittedState(
            "传送带停机结果缺少已提交记录，已恢复到当前进度，将自动重试。"
          );
          break;
        }
        this.pauseBakeryActivity();
        this.revealBakeryHourHand(true);
        this.storyPresentation = "idle";
        break;
      }
      case "collect_hour_hand":
        this.revealBakeryHourHand(false);
        this.storyPresentation = "idle";
        break;
      case "install_hour_hand":
        this.emitDropFeedback(
          "oldClockHourHand",
          "accepted",
          "金属时针已装回旧钟，时间已切换到 18:50。"
        );
        this.storyPresentation = "idle";
        break;
      case "talk_to_a1_front_desk_attendant": {
        this.storyPresentation = "idle";
        const state = this.bridge.getState();
        this.safeBridgeEmit("rpg_subtitle", {
          text: chapterFourDialogueSequence(selectA1FrontDeskDialogueKey(state)),
          tone: "system",
          durationMs: 3600
        });
        break;
      }
      case "talk_to_chapter_four_support_npc": {
        this.storyPresentation = "idle";
        const state = this.bridge.getState();
        const dialogueKey = pending.targetId === "a3_reference_teacher"
          ? (hasChapterFourFact(state, "a3_reference_observed")
            ? "supportNpc.a3_recorded"
            : "supportNpc.a3_reference")
          : (!hasChapterFourFact(state, "classroom_104_chalk_residual_observed")
              || !hasChapterFourFact(state, "classroom_105_terminal_replay_checked"))
            ? "supportNpc.a2_checks_required"
            : !hasChapterFourFact(state, "a3_reference_observed")
              ? "supportNpc.a2_reference_required"
              : "supportNpc.a2_room204";
        this.safeBridgeEmit("rpg_subtitle", {
          text: chapterFourDialogueSequence(dialogueKey),
          tone: "system",
          durationMs: 3600
        });
        break;
      }
      case "inspect_chapter_four_context": {
        this.storyPresentation = "idle";
        const state = this.bridge.getState();
        const insertedPuzzleId = pending.targetId
          ? chapterFourInsertedPuzzleForTarget(pending.targetId)
          : null;
        const subtitle = resolveChapterFourContextInteractionSubtitle({
          targetId: pending.targetId,
          phase: this.projection.phase,
          timeState: state.chapter4.timeState,
          mode: state.chapter4.mode,
          result: payload?.result
        });
        if (subtitle) {
          this.safeBridgeEmit("rpg_subtitle", { ...subtitle });
        } else if (!insertedPuzzleId) {
          this.safeBridgeEmit("rpg_subtitle", {
            text: "当前教室没有新增状态记录。",
            tone: "system" as const,
            durationMs: 4400 as const
          });
        }
        break;
      }
      case "inspect_alumni_figure":
        this.storyPresentation = "idle";
        if (pending.targetId) this.openAlumniPanel(pending.targetId);
        break;
      case "observe_classroom_104_chalk_residual":
        this.storyPresentation = "idle";
        this.safeBridgeEmit("rpg_subtitle", {
          text: chapterFourDialogueSequence("classroom104.chalk_residual"),
          tone: "system",
          durationMs: 4200
        });
        break;
      case "check_classroom_105_terminal_replay":
        this.storyPresentation = "idle";
        this.safeBridgeEmit("rpg_subtitle", {
          text: chapterFourDialogueSequence("classroom105.terminal_replay"),
          tone: "system",
          durationMs: 4200
        });
        break;
      case "observe_elevator_history":
        this.storyPresentation = "idle";
        this.safeBridgeEmit("rpg_subtitle", {
          text: "已记录门体开放、人物进入和轿厢上行三条时间轨。轿厢重放校准可独立在浅色操作中完成。",
          tone: "system",
          durationMs: 3600
        });
        break;
      case "calibrate_elevator_history":
        this.storyPresentation = "idle";
        this.elevatorCalibrationFailed = false;
        this.closeFloorPanel();
        this.openFloorPanel();
        break;
      case "observe_elevator_floor_record": {
        this.storyPresentation = "idle";
        const state = this.bridge.getState();
        const record = chapterFourElevatorRecordForDisplayFloor(this.currentFloor);
        this.paintFloorPanelSelection();
        this.safeBridgeEmit("rpg_subtitle", {
          text: `${record.displayFloor}F ${record.recordTitle}已归档。${record.evidence[0]}`,
          tone: "system",
          durationMs: 4200
        });
        if (chapterFourElevatorRecordsComplete(state.chapter4.factIds)) {
          this.showFeedback("三层运行记录已经齐全。切回浅色操作后，可在面板中复核停靠链。");
        }
        break;
      }
      case "reconstruct_elevator_stop_chain":
        this.storyPresentation = "idle";
        this.closeFloorPanel();
        this.openFloorPanel();
        this.safeBridgeEmit("rpg_subtitle", {
          text: "跨层运行链已复核：轿厢从一楼直达三楼，二楼外呼没有得到开门响应。定位片的楼层基准已确认。",
          tone: "success",
          durationMs: 4800
        });
        break;
      case "observe_a3_reference":
        this.storyPresentation = "idle";
        this.safeBridgeEmit("rpg_subtitle", {
          text: chapterFourDialogueText("room204.a3_reference_recorded"),
          tone: "system",
          durationMs: 2200
        });
        break;
      case "observe_room204_residual":
        this.storyPresentation = "idle";
        this.safeBridgeEmit("rpg_subtitle", {
          text: chapterFourDialogueText("room204.residual_recorded"),
          tone: "system",
          durationMs: 2200
        });
        break;
      case "place_room204_piece":
      case "place_room204_group":
        this.room204SelectedPieceId = null;
        this.updateRoom204CarryGhost();
        this.showFeedback(
          `已复原 ${Math.floor(normalizeRoom204Placements(
            this.bridge.getState().chapter4.room204Placements
          ).length / 3)}/${ROOM204_GROUP_ORDER.length}`
        );
        this.storyPresentation = "idle";
        break;
      case "complete_room204_projection": {
        const state = this.bridge.getState();
        if (!hasChapterFourFact(state, "room204_projection_completed")) {
          this.rollbackRoom204ProjectionToCommittedState(
            "07:55 投影结果缺少已提交记录，将自动重试。"
          );
          break;
        }
        this.clearStoryPresentationTimers();
        this.destroyRoom204ProjectionOverlay();
        this.storyPresentation = "idle";
        break;
      }
      case "collect_positioning_plate":
        this.storyPresentation = "idle";
        break;
      case "install_positioning_plate":
        this.emitDropFeedback(
          "clockPositioningPlate",
          "accepted",
          "定位盘已装回旧钟，现在线索转入 22:45 维护时段。"
        );
        this.storyPresentation = "idle";
        break;
      case "inspect_cart_wheel":
        this.storyPresentation = "idle";
        break;
      case "collect_short_pry_bar":
        this.storyPresentation = "idle";
        break;
      case "open_cart_wheel_cover":
        this.emitDropFeedback("shortPryBar", "accepted", "轮罩已打开，短撬棍完成了最后一次用途。");
        this.storyPresentation = "idle";
        break;
      case "collect_lubricating_oil":
        this.storyPresentation = "idle";
        break;
      case "lubricate_cart_wheel":
        this.emitDropFeedback(
          "universalLubricatingOil",
          "accepted",
          "保洁车轮已修好，瓶里还剩一半润滑油。"
        );
        this.storyPresentation = "idle";
        break;
      case "lubricate_clock_gear":
        this.emitDropFeedback(
          "universalLubricatingOil",
          "accepted",
          "旧钟齿轮已恢复转动。"
        );
        try {
          this.ensureHallClockStateSprite("gear_running");
        } catch (error) {
          this.persistentContractFailures.add(`maintenance_clock_running:${errorMessage(error)}`);
        }
        this.storyPresentation = "idle";
        break;
      case "recover_from_maintenance_patrol":
        this.resetMaintenanceGuardAfterRecovery();
        this.storyPresentation = "idle";
        this.safeBridgeEmit("rpg_subtitle", {
          text: "已回到大厅安全点。维修进度和道具均已保留。",
          tone: "system",
          durationMs: 2200
        });
        break;
      case "begin_final_clock_drag":
        this.beginAcceptedFinalClockDrag();
        break;
      case "complete_minute_theft": {
        const committed = this.bridge.getState();
        if (committed.chapter4.phase !== "blackout_light_grid"
          || committed.chapter4.timeState !== "0754_blackout"
          || committed.chapter4.guardMode !== "absent"
          || committed.chapter4.lightGrid.mask !== chapterFourContent.lightGrid.initialMask
          || committed.chapter4.lightGrid.locked
          || committed.items.attendanceRecordPaper
          || !hasChapterFourFact(committed, "paper_temporarily_out_of_inventory")) {
          this.rollbackMinuteTheftToCommittedState(
            "偷走最后一分钟的提交不完整，已恢复旧钟和纸条，可重试。"
          );
          break;
        }
        this.safeBridgeEmit("minute_theft_committed", {
          phase: committed.chapter4.phase,
          timeState: committed.chapter4.timeState,
          worldTimeSeconds: committed.chapter4.worldTimeSeconds,
          phoneStatusTimeSeconds: committed.chapter4.phoneStatusTimeSeconds
        });
        break;
      }
      case "open_power_panel":
        this.storyPresentation = "idle";
        break;
      case "trigger_minute_theft":
        this.storyPresentation = "idle";
        break;
      case "lock_light_grid":
        this.storyPresentation = "idle";
        break;
      case "reach_202_threshold":
        if (this.finalChaseState?.phase === "finish_pending") {
          this.finalChaseState = resolveChapterFourFinalChaseFinish(this.finalChaseState, true);
        }
        this.destroyChaseRuntime();
        this.currentFloor = 2;
        this.player.setPosition(
          getFloor(2).offsetX + FINAL_MINUTE_RUNTIME.recoveryPlayerSpawn.x,
          FINAL_MINUTE_RUNTIME.recoveryPlayerSpawn.y
        ).setVelocity(0, 0)
          .setDepth(PLAYER_DEPTH_BASE + FINAL_MINUTE_RUNTIME.recoveryPlayerSpawn.y);
        this.animator.setFacing("up");
        this.configureCameraForCurrentFloor();
        this.cameras.main.centerOn(this.player.x, this.player.y);
        this.storyPresentation = "idle";
        break;
      case "fail_chase":
        if (this.finalChaseState?.phase === "failure_pending") {
          this.finalChaseState = resolveChapterFourFinalChaseFailure(this.finalChaseState, true);
        }
        this.destroyChaseRuntime();
        this.ensureFinalChaseRuntime(this.bridge.getState());
        this.storyPresentation = "idle";
        this.safeBridgeEmit("rpg_subtitle", {
          text: chapterFourDialogueText("chase.retry"),
          tone: "system",
          durationMs: 2200
        });
        break;
      case "collect_final_minute":
        this.destroyFinalMinuteRuntime("collected");
        this.destroyRoom202RecoveryBarrier("collected");
        this.storyPresentation = "idle";
        this.safeBridgeEmit("rpg_subtitle", {
          text: chapterFourDialogueText("lecture.recovered_result"),
          tone: "success",
          durationMs: 2400
        });
        break;
      case "install_final_minute":
        this.destroyFinalClockRuntime("final_minute_installed");
        try {
          this.ensureHallClockStateSprite("0755_complete");
        } catch (error) {
          this.persistentContractFailures.add(`final_clock_0755:${errorMessage(error)}`);
        }
        this.emitDropFeedback(
          "finalMinute",
          "accepted",
          "最后一分钟已装回旧钟。时间已恢复到 07:55。"
        );
        this.storyPresentation = "idle";
        break;
      case "read_campus_card":
        this.emitDropFeedback(
          "campusCard",
          "accepted",
          "校园卡已通过签到校验。"
        );
        this.storyPresentation = "idle";
        break;
      case "submit_attendance_paper":
        this.emitDropFeedback(
          "attendanceRecordPaper",
          "accepted",
          "签到记录已提交。"
        );
        this.storyPresentation = "idle";
        break;
      case "acknowledge_exterior_closure":
        this.storyPresentation = "idle";
        this.safeBridgeEmit("rpg_subtitle", {
          text: chapterFourDialogueSequence("exterior.closure"),
          tone: "success",
          durationMs: 4200
        });
        break;
      default:
        this.storyPresentation = "idle";
        break;
    }
    this.syncStoryInputLock();
  }

  private syncOpeningPresentation(): void {
    if (!this.handoffReleased
      || this.pendingStoryRequest
      || this.storyPresentation !== "idle"
      || this.time.now < this.storyRetryNotBeforeMs) return;
    const state = this.bridge.getState();
    if (state.chapter4.phase === "opening_handoff") {
      if (hasChapterFourFact(state, "opening_paper_at_noticeboard")) {
        if (!hasChapterFourFact(state, "opening_paper_caught")) {
          this.ensureOpeningPaperAtNoticeboard();
        }
      } else {
        this.beginOpeningPaperFlight();
      }
      return;
    }
    if (state.chapter4.phase === "opening_paper_caught"
      && !hasChapterFourFact(state, "external_time_rejected")) {
      this.beginExternalTimeRejection();
      return;
    }
    if (state.chapter4.phase === "hall_clock_inspection"
      && !hasChapterFourFact(state, "hall_clock_inspected")) {
      this.beginHallClockInspection();
    }
  }

  private syncBakeryPresentation(): void {
    if (this.pendingStoryRequest
      || this.storyPresentation !== "idle"
      || this.time.now < this.storyRetryNotBeforeMs) return;
    const state = this.bridge.getState();
    if (state.chapter4.phase !== "bakery_hour_hand") return;
    if (hasChapterFourFact(state, "bakery_conveyor_lamp_inspected")
      && !hasChapterFourFact(state, "bakery_hour_hand_exposed")
      && !hasChapterFourFact(state, "bakery_hour_hand_collected")
      && !hasChapterFourFact(state, "hour_hand_installed")) {
      this.beginBakeryConveyorStopPresentation();
    }
  }

  private beginBakeryConveyorStopPresentation(): void {
    if (this.storyPresentation !== "idle" || this.pendingStoryRequest) return;
    const state = this.bridge.getState();
    if (state.chapter4.phase !== "bakery_hour_hand"
      || !hasChapterFourFact(state, "bakery_conveyor_lamp_inspected")
      || hasChapterFourFact(state, "bakery_hour_hand_exposed")) return;
    const source = BAKERY_RUNTIME.targetEntities.find(
      (entry) => entry.targetId === "a1_bakery_conveyor_edge"
    )!.installationBounds;
    const floor = getFloor(1);
    const foot = this.playerFootPoint(floor);
    this.storyPresentation = "bakery_conveyor_stop";
    this.syncStoryInputLock();
    this.clearStoryPresentationTimers();
    this.paintBakeryInspectionLamp(true);
    this.safeBridgeEmit("chapter4_bakery_conveyor_stop", {
      sourceWorldX: floor.offsetX + rectCenterX(source),
      playerWorldX: foot.worldX,
      distance: pointDistanceToRect({ x: foot.x, y: foot.y }, source),
      phase: "lamp_accepted"
    });
    this.scheduleStoryPresentation(120, () => {
      if (this.bakeryConveyorTween) this.bakeryConveyorTween.timeScale = 0.45;
    });
    this.scheduleStoryPresentation(360, () => this.pauseBakeryActivity());
    this.scheduleStoryPresentation(520, () => {
      this.revealBakeryHourHand(true);
      this.safeBridgeEmit("chapter4_bakery_hour_hand_revealed", {
        sourceWorldX: floor.offsetX + rectCenterX(source),
        playerWorldX: foot.worldX,
        distance: pointDistanceToRect({ x: foot.x, y: foot.y }, source),
        committed: false
      });
    });
    this.scheduleStoryPresentation(700, () => {
      this.requestStoryIntent({ type: "complete_bakery_conveyor_stop" });
    });
  }

  private maybeEmitBakeryApproachCue(): void {
    const state = this.bridge.getState();
    if (state.chapter4.phase !== "bakery_hour_hand" || this.currentFloor !== 1) return;
    const source = BAKERY_RUNTIME.targetEntities.find(
      (entry) => entry.targetId === "a1_bakery_conveyor_edge"
    )!.installationBounds;
    const floor = getFloor(1);
    const foot = this.playerFootPoint(floor);
    const distance = pointDistanceToRect({ x: foot.x, y: foot.y }, source);
    if (distance > 320) return;
    const signature = `${state.chapter4.phase}:${state.chapter4.timeState}`;
    if (signature === this.bakeryApproachCueSignature) return;
    this.bakeryApproachCueSignature = signature;
    this.safeBridgeEmit("chapter4_bakery_approach", {
      sourceWorldX: floor.offsetX + rectCenterX(source),
      playerWorldX: foot.worldX,
      distance
    });
  }

  private beginOpeningPaperFlight(): void {
    if (this.storyPresentation !== "idle" || this.pendingStoryRequest) return;
    this.storyPresentation = "paper_flight";
    this.syncStoryInputLock();
    this.clearStoryPresentationTimers();
    this.openingPaperSprite?.destroy();
    const target = CHAPTER_FOUR_755_INTERACTION_TARGETS.a1_noticeboard_paper;
    if (!target.bounds) {
      this.storyPresentation = "idle";
      this.syncStoryInputLock();
      this.storyRetryNotBeforeMs = this.time.now + STORY_RETRY_DELAY_MS;
      this.showRuntimeInteractionFailure("noticeboard_paper_runtime_bounds_missing");
      return;
    }
    const vectors = {
      up: { x: 0, y: -1 }, down: { x: 0, y: 1 },
      left: { x: -1, y: 0 }, right: { x: 1, y: 0 }
    } as const;
    const vector = vectors[this.animator.cardinalFacing];
    const floor = getFloor(this.currentFloor);
    const foot = this.playerFootPoint(floor);
    const startDistance = OPENING_HANDSHAKE.paper.startDistanceMeters
      * CHAPTER_FOUR_WORLD_PIXELS_PER_METER;
    const startX = Phaser.Math.Clamp(foot.worldX + vector.x * startDistance, 24, FLOOR_SIZE.width - 24);
    const startY = Phaser.Math.Clamp(foot.y + vector.y * startDistance, 44, FLOOR_SIZE.height - 24);
    const endX = rectCenterX(target.bounds);
    const endY = rectBottom(target.bounds);
    const paper = this.add.sprite(
      startX,
      startY,
      "chapter4_story_items",
      "sign_in_record_paper"
    ).setScale(0.18).setDepth(PLAYER_DEPTH_BASE + startY + 4).setAlpha(0.96);
    this.openingPaperSprite = paper;
    try {
      this.tweens.add({
        targets: paper,
        x: endX,
        y: endY,
        angle: 18,
        duration: 1900,
        ease: "Sine.InOut",
        onUpdate: () => paper.setDepth(PLAYER_DEPTH_BASE + paper.y + 4),
        onComplete: () => {
          paper.setPosition(endX, endY).setAngle(0).setDepth(PLAYER_DEPTH_BASE + endY + 4);
          this.requestStoryIntent({ type: "complete_opening_paper_flight" });
        }
      });
    } catch {
      paper.setPosition(endX, endY).setAngle(0).setDepth(PLAYER_DEPTH_BASE + endY + 4);
      this.requestStoryIntent({ type: "complete_opening_paper_flight" });
    }
  }

  private ensureOpeningPaperAtNoticeboard(): void {
    const target = CHAPTER_FOUR_755_INTERACTION_TARGETS.a1_noticeboard_paper;
    if (!target.bounds) return;
    if (!this.openingPaperSprite?.active) {
      this.openingPaperSprite = this.add.sprite(
        rectCenterX(target.bounds),
        rectBottom(target.bounds),
        "chapter4_story_items",
        "sign_in_record_paper"
      ).setScale(0.18);
    }
    this.openingPaperSprite
      .setPosition(rectCenterX(target.bounds), rectBottom(target.bounds))
      .setAngle(0)
      .setVisible(true)
      .setDepth(PLAYER_DEPTH_BASE + rectBottom(target.bounds) + 4);
  }

  private beginExternalTimeRejection(): void {
    if (this.storyPresentation !== "idle" || this.pendingStoryRequest) return;
    this.storyPresentation = "external_time_rejection";
    this.syncStoryInputLock();
    this.clearStoryPresentationTimers();
    try {
      this.createExternalTimeOverlay();
    } catch (error) {
      this.persistentContractFailures.add(`external_time_overlay:${errorMessage(error)}`);
    }
    this.scheduleStoryPresentation(5600, () => this.safeBridgeEmit("rpg_subtitle", {
      text: "记录回来了，你没有回到记录发生的时候。",
      tone: "system",
      durationMs: 2400
    }));
    this.scheduleStoryPresentation(7000, () => {
      this.requestStoryIntent({ type: "resolve_external_time_rejection" });
    });
  }

  private createExternalTimeOverlay(): void {
    this.destroyExternalTimeOverlay();
    const labelStyle: Phaser.Types.GameObjects.Text.TextStyle = {
      fontFamily: "'Fusion Pixel', monospace",
      color: "#f7f1dc",
      fontSize: "18px",
      align: "center"
    };
    const overlay = this.add.container(480, 270).setScrollFactor(0).setDepth(12500);
    const shade = this.add.rectangle(0, 0, 960, 540, 0x02060d, 0.84);
    const panel = this.add.rectangle(0, 0, 660, 360, 0x0b1726, 0.98)
      .setStrokeStyle(3, 0x8fe8ff, 0.9);
    const externalTitle = this.add.text(-205, -125, "外部现场", {
      ...labelStyle, color: "#9bb0c7", fontSize: "16px"
    }).setOrigin(0.5);
    const externalTime = this.add.text(-205, -60, "22:45", {
      ...labelStyle, color: "#ffd36f", fontSize: "48px"
    }).setOrigin(0.5);
    const divider = this.add.rectangle(0, 0, 2, 238, 0x52708f, 0.76);
    const phone = this.add.rectangle(205, 4, 230, 286, 0x111827, 1)
      .setStrokeStyle(4, 0xd8e5f2, 0.9);
    const phoneSpeaker = this.add.rectangle(205, -114, 54, 5, 0x61738a, 0.92);
    const phoneTitle = this.add.text(205, -82, "手机状态栏 · 冻结", {
      ...labelStyle, color: "#9bb0c7", fontSize: "14px"
    }).setOrigin(0.5);
    const phoneTime = this.add.text(205, -24, "07:55:23", {
      ...labelStyle, color: "#f7f1dc", fontSize: "31px"
    }).setOrigin(0.5);
    const trust = this.add.text(205, 46, "不可信", {
      ...labelStyle, color: "#ff786f", fontSize: "24px"
    }).setOrigin(0.5);
    const detail = this.add.text(0, 142, "外部时间与手机冻结时间冲突 · 签到提交已拒绝", {
      ...labelStyle, color: "#8fe8ff", fontSize: "16px"
    }).setOrigin(0.5);
    overlay.add([
      shade, panel, externalTitle, externalTime, divider,
      phone, phoneSpeaker, phoneTitle, phoneTime, trust, detail
    ]);
    this.externalTimeOverlay = overlay;
  }

  private destroyExternalTimeOverlay(): void {
    this.externalTimeOverlay?.destroy(true);
    this.externalTimeOverlay = null;
  }

  private beginHallClockInspection(): void {
    if (this.storyPresentation !== "idle" || this.pendingStoryRequest) return;
    this.storyPresentation = "hall_clock_inspection";
    this.syncStoryInputLock();
    this.clearStoryPresentationTimers();
    try {
      this.ensureHallClockStateSprite("2245_missing_hour_hand");
    } catch (error) {
      this.persistentContractFailures.add(`opening_clock_visual:${errorMessage(error)}`);
    }
    this.safeBridgeEmit("rpg_subtitle", {
      text: "旧钟停在 22:45。表盘能被拨动，但响应方向和幅度都不对。",
      tone: "system",
      durationMs: 2600
    });
    this.scheduleStoryPresentation(1700, () => {
      try {
        this.ensureHallClockStateSprite("gear_stuttering");
      } catch (error) {
        this.persistentContractFailures.add(`opening_clock_gear_visual:${errorMessage(error)}`);
      }
      this.safeBridgeEmit("rpg_chapter4_clock_cue", {
        cue: "gear_stuttering",
        committed: false
      });
    });
    this.scheduleStoryPresentation(3200, () => {
      try {
        this.ensureHallClockStateSprite("2245_missing_hour_hand");
      } catch (error) {
        this.persistentContractFailures.add(`opening_clock_missing_hand_visual:${errorMessage(error)}`);
      }
    });
    this.scheduleStoryPresentation(4700, () => {
      this.requestStoryIntent({ type: "resolve_hall_clock_inspection" });
    });
  }

  private beginFirstHallClockPullPresentation(): void {
    if (this.storyPresentation !== "idle" || this.pendingStoryRequest) return;
    const state = this.bridge.getState();
    const projection = selectChapterFourMazeProjection(state);
    const committed = state.chapter4.phase === "bakery_hour_hand"
      && state.chapter4.timeAuthority === "hall_clock"
      && state.chapter4.timeState === "1225_bakery"
      && state.chapter4.worldTimeSeconds === 44700
      && state.chapter4.phoneStatusTimeSeconds === 44700
      && state.chapter4.phoneStatusTimeTrusted
      && projection.activePlateIds.includes("a1_1225_bakery");
    if (!committed) {
      this.storyRetryNotBeforeMs = this.time.now + STORY_RETRY_DELAY_MS;
      this.showRuntimeInteractionFailure("first_clock_pull_commit_incomplete");
      return;
    }

    this.storyPresentation = "first_clock_pull";
    this.syncStoryInputLock();
    this.clearStoryPresentationTimers();
    try {
      this.ensureHallClockStateSprite("gear_stuttering");
    } catch (error) {
      this.persistentContractFailures.add(`first_clock_pull_visual:${errorMessage(error)}`);
    }
    this.safeBridgeEmit("rpg_chapter4_clock_cue", {
      cue: "gear_stuttering",
      committed: true,
      timeState: state.chapter4.timeState
    });
    for (const delayMs of [0, 110, 230, 360]) {
      this.scheduleStoryPresentation(delayMs, () => {
        try {
          this.cameras.main.flash(68, 255, 244, 198, false);
        } catch (error) {
          this.persistentContractFailures.add(`first_clock_pull_flash:${errorMessage(error)}`);
        }
      });
    }
    this.scheduleStoryPresentation(430, () => {
      try {
        this.ensureHallClockStateSprite("1225_missing_hour_hand");
      } catch (error) {
        this.persistentContractFailures.add(`first_clock_pull_1225_visual:${errorMessage(error)}`);
      }
      this.safeBridgeEmit("rpg_chapter4_clock_cue", {
        cue: "1225_missing_hour_hand",
        committed: true,
        timeState: "1225_bakery"
      });
    });
    this.scheduleStoryPresentation(950, () => {
      this.storyPresentation = "idle";
      this.syncStoryInputLock();
      this.safeBridgeEmit("rpg_subtitle", {
        text: "旧钟停在 12:25。",
        tone: "system",
        durationMs: 2600
      });
    });
  }

  private ensureHallClockStateSprite(frameName: string): void {
    if (!this.textures.exists("chapter4_clock_states")
      || !this.textures.get("chapter4_clock_states").has(frameName)) {
      throw new Error(`chapter4_clock_states_frame_missing:${frameName}`);
    }
    const floor = getFloor(1);
    const registration = FINAL_CLOCK_RUNTIME.visualRegistration;
    if (!this.hallClockStateSprite?.active) {
      this.hallClockStateSprite = this.add.sprite(
        floor.offsetX + registration.axis.x,
        registration.axis.y,
        "chapter4_clock_states",
        frameName
      );
    } else {
      this.hallClockStateSprite.setTexture("chapter4_clock_states", frameName);
    }
    this.hallClockStateSprite
      .setPosition(floor.offsetX + registration.axis.x, registration.axis.y)
      .setScale(registration.uniformScale)
      .setVisible(true)
      .setDepth(PLAYER_DEPTH_BASE - 180);
  }

  private scheduleStoryPresentation(delayMs: number, callback: () => void): void {
    let timer: Phaser.Time.TimerEvent;
    timer = this.time.delayedCall(delayMs, () => {
      this.storyPresentationTimers = this.storyPresentationTimers.filter((entry) => entry !== timer);
      try {
        callback();
      } catch (error) {
        this.persistentContractFailures.add(`story_presentation_callback:${errorMessage(error)}`);
      }
    });
    this.storyPresentationTimers.push(timer);
  }

  private clearStoryPresentationTimers(): void {
    for (const timer of this.storyPresentationTimers) timer.remove(false);
    this.storyPresentationTimers = [];
  }

  private safeBridgeEmit(name: string, payload?: Record<string, unknown>): void {
    try {
      this.bridge.emit(name, payload);
    } catch (error) {
      this.persistentContractFailures.add(`story_bridge_emit:${name}:${errorMessage(error)}`);
    }
  }

  private beginAcceptedElevatorTravel(pending: PendingMove): void {
    this.closeFloorPanel();
    this.elevatorTargetFloor = pending.targetFloor;
    this.elevatorPhase = "closing";
    this.tweenElevatorDoor(pending.fromFloor, 1, 0, () => {
      this.elevatorPhase = "traveling";
      this.player.setVisible(false);
      const path = this.floorPath(pending.fromFloor, pending.targetFloor);
      const direction = pending.targetFloor > pending.fromFloor ? "↑" : "↓";
      path.forEach((floor, index) => {
        this.time.delayedCall((index + 1) * ELEVATOR_TRAVEL_PER_FLOOR_MS, () => {
          this.elevatorVisuals.get(floor)?.indicator.setText(`${floor}F ${direction}`);
        });
      });
      this.time.delayedCall(
        Math.max(1, path.length) * ELEVATOR_TRAVEL_PER_FLOOR_MS + 120,
        () => this.arriveAcceptedElevator(pending)
      );
    });
  }
  private floorPath(from: DisplayFloor, to: DisplayFloor): DisplayFloor[] {
    const step = from < to ? 1 : -1;
    const path: DisplayFloor[] = [];
    for (let value = from + step; step > 0 ? value <= to : value >= to; value += step) {
      path.push(value as DisplayFloor);
    }
    return path;
  }
  private arriveAcceptedElevator(pending: PendingMove): void {
    this.currentFloor = pending.targetFloor;
    const floor = getFloor(this.currentFloor);
    this.player.setPosition(
      floor.offsetX + floor.elevator.doorCenter.x,
      floor.elevator.doorCenter.y
    );
    this.configureCameraForCurrentFloor();
    this.cameras.main.centerOn(this.player.x, this.player.y);
    this.elevatorPhase = "destination_opening";
    this.elevatorVisuals.get(this.currentFloor)?.lamp.setVisible(true);
    this.setElevatorDoorProgress(this.currentFloor, 0);
    this.tweenElevatorDoor(this.currentFloor, 0, 1, () => {
      this.beginElevatorExit(this.currentFloor);
    });
  }
  private beginElevatorExit(floorNumber: DisplayFloor): void {
    this.elevatorPhase = "exiting";
    const floor = getFloor(floorNumber);
    this.player.setVisible(true).setDepth(chapterFourPlayerDepth(floor.elevator.doorCenter.y + 2));
    this.animator.setFacing("down");
    this.tweens.add({
      targets: this.player,
      x: floor.offsetX + floor.elevator.arrivalPosition.x,
      y: floor.elevator.arrivalPosition.y,
      duration: ELEVATOR_BOARD_MS,
      ease: "Sine.InOut",
      onComplete: () => {
        const body = this.player.body as Phaser.Physics.Arcade.Body;
        body.enable = true;
        body.reset(this.player.x, this.player.y);
        this.player.setDepth(PLAYER_TOP_DEPTH);
        this.elevatorPhase = "destination_closing";
        this.tweenElevatorDoor(floorNumber, 1, 0, () => {
          this.elevatorVisuals.get(floorNumber)?.lamp.setVisible(false);
          this.elevatorVisuals.get(floorNumber)?.indicator.setText(`${floorNumber}F`);
          this.elevatorPhase = "idle";
          this.elevatorTargetFloor = null;
          this.refreshProximity();
        });
      }
    });
  }
  private beginAcceptedStairTransfer(pending: PendingMove): void {
    const source = getFloor(pending.fromFloor);
    const destination = getFloor(pending.targetFloor);
    const arrival = destination.stairLandings.find(
      (landing) => landing.targetStoryFloor === source.storyFloor
    )?.arrivalPosition ?? destination.safeSpawn;
    this.currentFloor = pending.targetFloor;
    this.player.setPosition(destination.offsetX + arrival.x, arrival.y)
      .setVelocity(0, 0).setDepth(PLAYER_DEPTH_BASE + arrival.y);
    this.animator.setFacing("down");
    this.configureCameraForCurrentFloor();
    this.cameras.main.centerOn(this.player.x, this.player.y);
    this.refreshProximity();
  }

  private syncExternalFloorWhenIdle(): void {
    if (this.pendingMove || this.elevatorPhase !== "idle") return;
    const state = this.bridge.getState();
    const stateFloor = displayFloorFor(state.chapter4.floor);
    if (!stateFloor || stateFloor === this.currentFloor) return;
    if (!this.isFloorPresentationReady(stateFloor, state)) return;
    const previousFloor = getFloor(this.currentFloor);
    const floor = getFloor(stateFloor);
    const stairArrival = state.chapter4.phase === "room204_restore"
      && previousFloor.storyFloor === "A3"
      && floor.storyFloor === "A2"
      && hasChapterFourFact(state, "misaligned_stair_solved")
        ? floor.stairLandings.find((landing) => landing.targetStoryFloor === "A3")?.arrivalPosition
        : undefined;
    const spawn = stairArrival
      ? { ...stairArrival, facing: "down" as const }
      : floor.safeSpawn;
    this.currentFloor = stateFloor;
    this.player.setPosition(floor.offsetX + spawn.x, spawn.y)
      .setVelocity(0, 0).setDepth(PLAYER_DEPTH_BASE + spawn.y);
    this.animator.setFacing(spawn.facing ?? "down");
    this.configureCameraForCurrentFloor();
    this.cameras.main.centerOn(this.player.x, this.player.y);
    this.refreshProximity();
  }

  private isFloorPresentationReady(displayFloor: DisplayFloor, state: GameState): boolean {
    const floor = getFloor(displayFloor);
    const expectedProjection = selectChapterFourMazeProjection(state);
    const expectedPlateId = plateForFloor(expectedProjection, floor.storyFloor);
    const background = this.backgrounds.get(displayFloor);
    return this.appliedPlateSignature.length > 0
      && this.projection.phase === expectedProjection.phase
      && this.appliedPlateIds[floor.storyFloor] === expectedPlateId
      && Boolean(background?.active)
      && background?.texture.key === expectedPlateId;
  }

  private handleInventoryDrop(payload?: Record<string, unknown>): void {
    const rawItemId = payload?.itemId;
    const items = this.bridge.getState().items;
    if (!hasOwnInventoryItem(items, rawItemId)) {
      this.persistentContractFailures.add(`invalid_drop_item:${rawItemId}`);
      const detail = "无法使用该道具。";
      this.bridge.emit("rpg_item_use_feedback", { reason: "invalid_item", detail });
      return;
    }
    const itemId = rawItemId;
    const canvasX = Number(payload?.canvasX);
    const canvasY = Number(payload?.canvasY);
    if (!Number.isFinite(canvasX) || !Number.isFinite(canvasY)) {
      this.emitDropFeedback(itemId, "missed_target", "未命中有效目标。");
      return;
    }
    const floor = getFloor(this.currentFloor);
    const world = this.cameras.main.getWorldPoint(canvasX, canvasY);
    const local = { x: world.x - floor.offsetX, y: world.y };
    const candidates = this.resolveActionableTargets().filter((target) => (
      target.floor === this.currentFloor
      && target.acceptedItem !== undefined && target.acceptedItem !== null
      && local.x >= target.bounds.x && local.x < target.bounds.x + target.bounds.width
      && local.y >= target.bounds.y && local.y < target.bounds.y + target.bounds.height
    ));
    if (candidates.length === 0) {
      this.emitDropFeedback(itemId, "missed_target", "未命中当前阶段的可见道具目标。");
      return;
    }
    const target = candidates[0];
    if (itemId !== target.acceptedItem) {
      this.emitDropFeedback(itemId, "wrong_item", `${target.contract.label}需要另一件道具。`);
      return;
    }
    if (target.contract.id === "a1_hall_clock_hour_hand_socket"
      && itemId === "oldClockHourHand") {
      this.requestStoryIntent({
        type: "install_hour_hand",
        itemId,
        targetId: "a1_hall_clock_hour_hand_socket",
        spatial: this.storySpatialResult(target)
      }, target.contract.id);
      return;
    }
    if (target.contract.id === "a1_hall_clock_positioning_plate_slot"
      && itemId === "clockPositioningPlate") {
      this.requestStoryIntent({
        type: "install_positioning_plate",
        itemId,
        targetId: "a1_hall_clock_positioning_plate_slot",
        spatial: this.storySpatialResult(target)
      }, target.contract.id);
      return;
    }
    if (target.contract.id === "a1_hall_clock_minute_endpoint"
      && itemId === "finalMinute") {
      const runtimeTarget = this.resolveRuntimeTargetContext(target.contract, target.bounds);
      if (!runtimeTarget) {
        this.emitDropRuntimeFailure(itemId, "final_clock_minute_runtime_bounds_missing");
        return;
      }
      this.requestStoryIntent({
        type: "install_final_minute",
        itemId,
        targetId: "a1_hall_clock_minute_endpoint",
        spatial: this.storySpatialResult(target)
      }, target.contract.id, runtimeTarget);
      return;
    }
    if (target.contract.id === "a1_campus_card_reader"
      && itemId === "campusCard") {
      const runtimeTarget = this.resolveRuntimeTargetContext(target.contract, target.bounds);
      if (!runtimeTarget) {
        this.emitDropRuntimeFailure(itemId, "campus_card_reader_runtime_bounds_missing");
        return;
      }
      this.requestStoryIntent({
        type: "read_campus_card",
        itemId,
        targetId: "a1_campus_card_reader",
        spatial: this.storySpatialResult(target)
      }, target.contract.id, runtimeTarget);
      return;
    }
    if (target.contract.id === "a1_attendance_paper_slot"
      && itemId === "attendanceRecordPaper") {
      const runtimeTarget = this.resolveRuntimeTargetContext(target.contract, target.bounds);
      if (!runtimeTarget) {
        this.emitDropRuntimeFailure(itemId, "attendance_slot_runtime_bounds_missing");
        return;
      }
      this.requestStoryIntent({
        type: "submit_attendance_paper",
        itemId,
        targetId: "a1_attendance_paper_slot",
        spatial: this.storySpatialResult(target)
      }, target.contract.id, runtimeTarget);
      return;
    }
    const runtimeTarget = this.resolveRuntimeTargetContext(target.contract, target.bounds);
    if (target.contract.id === "a1_cleaning_cart_wheel_cover" && itemId === "shortPryBar") {
      if (!runtimeTarget) {
        this.emitDropRuntimeFailure(itemId, "cart_wheel_cover_runtime_bounds_missing");
        return;
      }
      this.requestStoryIntent({
        type: "open_cart_wheel_cover",
        itemId,
        targetId: "a1_cleaning_cart_wheel_cover",
        spatial: this.storySpatialResult(target)
      }, target.contract.id, runtimeTarget);
      return;
    }
    if (target.contract.id === "a1_cleaning_cart_wheel"
      && itemId === "universalLubricatingOil") {
      if (!runtimeTarget) {
        this.emitDropRuntimeFailure(itemId, "cart_wheel_runtime_bounds_missing");
        return;
      }
      this.requestStoryIntent({
        type: "lubricate_cart_wheel",
        itemId,
        targetId: "a1_cleaning_cart_wheel",
        spatial: this.storySpatialResult(target)
      }, target.contract.id, runtimeTarget);
      return;
    }
    if (target.contract.id === "a1_hall_clock_gear"
      && itemId === "universalLubricatingOil") {
      if (!runtimeTarget) {
        this.emitDropRuntimeFailure(itemId, "clock_gear_runtime_bounds_missing");
        return;
      }
      this.requestStoryIntent({
        type: "lubricate_clock_gear",
        itemId,
        targetId: "a1_hall_clock_gear",
        spatial: this.storySpatialResult(target)
      }, target.contract.id, runtimeTarget);
      return;
    }
    this.emitDropRuntimeFailure(itemId, `drop_target_unwired:${target.contract.id}`);
  }
  private emitDropFeedback(itemId: ItemId, reason: string, detail: string): void {
    this.bridge.emit("rpg_item_use_feedback", { itemId, reason, detail });
  }
  private emitDropRuntimeFailure(itemId: ItemId, code: string): void {
    this.persistentContractFailures.add(code);
    this.emitDropFeedback(itemId, "locked", "交互失败，请重新靠近目标后重试。");
  }
  private showRuntimeInteractionFailure(code: string): void {
    this.persistentContractFailures.add(code);
    this.showFeedback("交互失败，请重新靠近目标后重试。");
  }
  private showFeedback(message: string): void {
    this.feedbackTimer?.remove(false);
    this.feedbackText.setText(message).setVisible(true);
    this.feedbackTimer = this.time.delayedCall(1900, () => {
      this.feedbackText.setVisible(false);
      this.feedbackTimer = null;
    });
  }

  private publishDebug(): void {
    const state = this.bridge.getState();
    const floor = getFloor(this.currentFloor);
    const body = this.player.body as Phaser.Physics.Arcade.Body | undefined;
    const projectedTargets = this.resolveProjectedTargets();
    const actionableTargets = this.resolveActionableTargets();
    const projectedPlateIds = desiredPlateGroup(this.projection);
    const projectedPhysicalIds = LAYOUT.physicalDeltas.flatMap((delta) => {
      if (!delta.statePlateIds.includes(projectedPlateIds[delta.storyFloor])) return [];
      const displayFloor = displayFloorFor(delta.storyFloor);
      if (!displayFloor) return [];
      return (delta.collisionBounds ?? []).map((rect) => `floor_${displayFloor}_${rect.id}`);
    });
    const projectedCollisionIds = [
      ...FLOORS.flatMap((entry) => entry.staticCollisions.map((rect) => (
        `floor_${entry.displayFloor}_${rect.id}`
      ))),
      ...projectedPhysicalIds,
      ...this.projection.dynamicCollisionIds
    ];
    const targetDebug = projectedTargets.map((target) => ({
      id: target.contract.id,
      label: target.contract.label,
      x: getFloor(target.floor).offsetX + target.bounds.x,
      y: target.bounds.y,
      width: target.bounds.width,
      height: target.bounds.height,
      acceptedItem: target.acceptedItem ?? undefined,
      requiredMode: this.projection.phase
        ? selectChapterFour755RequiredMode(target.contract, this.projection.phase)
        : undefined,
      proximity: target.contract.proximity
    }));
    const contractFailures = [...new Set([
      ...this.persistentContractFailures,
      ...this.plateContractFailures
    ])];
    const runtimeEntities = projectedTargets.flatMap((target) => {
      const source = target.contract.boundsSource;
      if (source.kind !== "runtime_entity") return [];
      const targetFloor = getFloor(target.floor);
      return [{
        targetId: target.contract.id,
        entityId: source.entityId,
        displayFloor: target.floor,
        storyFloor: targetFloor.storyFloor,
        source: {
          kind: "runtime_entity" as const,
          floor: source.floor,
          entityId: source.entityId
        },
        bounds: { ...target.bounds },
        worldBounds: offsetRect(target.bounds, targetFloor.offsetX),
        rendered: this.renderedTargetIds.includes(target.contract.id)
      }];
    });
    const maintenanceGuardBody = this.maintenanceGuard?.body as Phaser.Physics.Arcade.Body | undefined;
    const ordinaryGuardEntityBounds = maintenanceGuardBody
      ? {
          x: maintenanceGuardBody.left - getFloor(1).offsetX,
          y: maintenanceGuardBody.top,
          width: maintenanceGuardBody.width,
          height: maintenanceGuardBody.height
        }
      : null;
    const chaseGuardBody = this.chaseGuard?.body as Phaser.Physics.Arcade.Body | undefined;
    const chaseGuardFloor = this.finalChaseState?.guardFloor === "A2" ? getFloor(2) : getFloor(1);
    const chaseGuardBounds = chaseGuardBody
      ? {
          x: chaseGuardBody.left - chaseGuardFloor.offsetX,
          y: chaseGuardBody.top,
          width: chaseGuardBody.width,
          height: chaseGuardBody.height
        }
      : null;
    const doorPhase = state.chapter4.phase === "final_chase"
      || state.chapter4.phase === "final_minute_recovery"
      || state.chapter4.phase === "return_to_clock"
      ? state.chapter4.phase
      : null;
    const doorContract = doorPhase ? FINAL_CHASE_RUNTIME.room202Door.states[doorPhase] : null;
    const appliedDoorWorldBounds = this.room202DoorBarrier?.active
      ? this.room202DoorBarrier.getBounds()
      : null;
    const appliedDoorBounds = appliedDoorWorldBounds
      ? {
          x: Math.floor(appliedDoorWorldBounds.left - getFloor(2).offsetX),
          y: Math.floor(appliedDoorWorldBounds.top),
          width: Math.ceil(appliedDoorWorldBounds.right - getFloor(2).offsetX)
            - Math.floor(appliedDoorWorldBounds.left - getFloor(2).offsetX),
          height: Math.ceil(appliedDoorWorldBounds.bottom) - Math.floor(appliedDoorWorldBounds.top)
        }
      : null;
    const structuredFailures = [
      ...[...this.persistentContractFailures].map((raw) => structuredContractFailure("runtime", raw)),
      ...[...this.plateContractFailures].map((raw) => structuredContractFailure("plate", raw)),
      ...(this.spatialAttestationLast?.result === "rejected"
        ? [structuredContractFailure(
            "spatial_attestation",
            `${this.spatialAttestationLast.reason ?? "unknown"}:${this.spatialAttestationLast.targetId}`
          )]
        : [])
    ];
    let developerCheckpointId: string | null = null;
    let developerCheckpointSource: "panel" | "url" | null = null;
    try {
      developerCheckpointId = window.sessionStorage.getItem(DEVELOPER_ACTIVE_KEY);
      const source = window.sessionStorage.getItem(DEVELOPER_SOURCE_KEY);
      developerCheckpointSource = source === "panel" || source === "url" ? source : null;
    } catch {
      // Debug metadata remains optional when sessionStorage is unavailable.
    }

    setRpgRuntimeDebugState({
      engine: "phaser",
      coordinateSystem: "Phaser world coordinates, origin at top-left, x right, y down",
      world: { ...WORLD },
      player: {
        x: this.player.x,
        y: this.player.y,
        facing: this.animator.facing,
        cardinalFacing: this.animator.cardinalFacing,
        texture: this.animator.textureKey,
        turning: this.animator.isTurning,
        walkFps:
          this.animator.facing === "side"
            ? RPG_PLAYER_SIDE_WALK_FPS
            : RPG_PLAYER_WALK_FPS,
        collisionWidth: body?.width,
        collisionHeight: body?.height,
        collisionBounds: body
          ? {
              x: body.left,
              y: body.top,
              width: body.width,
              height: body.height
            }
          : undefined,
        depth: this.player.depth
      },
      input: {
        gameEnabled: this.game.input.enabled,
        sceneEnabled: this.input.enabled,
        keyboardEnabled: this.input.keyboard?.enabled ?? false,
        keys: {
          up: this.cursors.up.isDown,
          down: this.cursors.down.isDown,
          left: this.cursors.left.isDown,
          right: this.cursors.right.isDown,
          interact: this.interactKey.isDown
        }
      },
      camera: {
        scrollX: this.cameras.main.scrollX,
        scrollY: this.cameras.main.scrollY,
        zoom: this.cameras.main.zoom,
        mode: "follow"
      },
      scene: "duan_yongping_temporal_maze",
      checkpoint: state.rpgCheckpoint,
      activeTargets: targetDebug,
      collisionRects: this.appliedCollisionRects,
      chapterFour: {
        phase: this.projection.phase ?? "inactive",
        mode: this.appliedChapterMode,
        committed: {
          phase: state.chapter4.phase,
          timeState: state.chapter4.timeState,
          timeAuthority: state.chapter4.timeAuthority,
          worldTimeSeconds: state.chapter4.worldTimeSeconds,
          phoneStatusTimeSeconds: state.chapter4.phoneStatusTimeSeconds,
          phoneStatusTimeTrusted: state.chapter4.phoneStatusTimeTrusted,
          floor: state.chapter4.floor,
          roomId: state.chapter4.roomId,
          checkpoint: state.rpgCheckpoint,
          plateSignature: this.pendingProjectionSignature,
          plateIds: projectedPlateIds,
          targetIds: projectedTargets.map((target) => target.contract.id)
        },
        applied: {
          phase: this.projection.phase ?? "inactive",
          timeState: this.projection.timeState,
          mode: this.appliedChapterMode,
          storyFloor: floor.storyFloor,
          displayFloor: this.currentFloor,
          plateSignature: this.appliedPlateSignature,
          plateIds: this.appliedPlateIds,
          targetIds: [...this.renderedTargetIds]
        },
        warmup: {
          requiredPhase: chapterFourWarmupPhaseForState(state),
          ready: this.isWarmupPhaseLoaded(chapterFourWarmupPhaseForState(state)),
          loadedPhases: [...this.loadedWarmupPhases],
          inFlightPhases: [...this.phaseLoadPromises.keys()],
          failures: [...this.phaseLoadFailures.entries()].map(([phase, urls]) => ({
            phase,
            urls: [...urls],
            retryNotBeforeMs: this.phaseLoadRetryNotBeforeMs.get(phase) ?? 0
          }))
        },
        realityVisuals: {
          renderedMode: this.renderedRealityMode ?? this.appliedChapterMode,
          darkLayerAlpha: this.darkRealityVisuals?.alpha ?? 0,
          lightLayerAlpha: this.lightRealityVisuals?.alpha ?? 0,
          atmosphereDepth: REALITY_MODE_ATMOSPHERE_DEPTH,
          targetDepth: REALITY_MODE_TARGET_DEPTH,
          activeTargetMarkerIds: targetDebug
            .filter((target) => this.targetVisuals.has(target.id))
            .filter((target) => target.requiredMode === undefined
              || target.requiredMode === this.appliedChapterMode)
            .map((target) => target.id),
          dormantTargetMarkerIds: targetDebug
            .filter((target) => this.targetVisuals.has(target.id))
            .filter((target) => target.requiredMode !== undefined
              && target.requiredMode !== this.appliedChapterMode)
            .map((target) => target.id)
        },
        activeFloorBounds: {
          x: floor.offsetX,
          y: 0,
          width: FLOOR_SIZE.width,
          height: FLOOR_SIZE.height
        },
        runtimeEntities,
        ordinaryGuard: {
          active: state.chapter4.phase === "maintenance_repair"
            && state.chapter4.guardMode === "patrol"
            && this.maintenanceGuardState !== null,
          mode: this.maintenanceGuardState?.mode ?? null,
          position: this.maintenanceGuardState
            ? { ...this.maintenanceGuardState.position }
            : null,
          heading: this.maintenanceGuardState
            ? { ...this.maintenanceGuardState.heading }
            : null,
          previousWaypointId: this.maintenanceGuardState?.previousWaypointId ?? null,
          targetWaypointId: this.maintenanceGuardState?.targetWaypointId ?? null,
          pauseRemainingMs: this.maintenanceGuardState?.pauseRemainingMs ?? 0,
          visibleForMs: this.maintenanceGuardState?.visibleForMs ?? 0,
          sightLostForMs: this.maintenanceGuardState?.sightLostForMs ?? 0,
          lastVisiblePosition: this.maintenanceGuardState?.lastVisiblePosition
            ? { ...this.maintenanceGuardState.lastVisiblePosition }
            : null,
          animationId: this.maintenanceGuardVisualId,
          travelDirection: this.maintenanceGuardTravelDirection,
          flipX: this.maintenanceGuard?.flipX ?? null,
          entityBounds: ordinaryGuardEntityBounds
        },
        bakeryCrowd: this.bakeryCrowdActors.map((actor) => ({
          routeIndex: actor.routeIndex,
          position: {
            x: actor.sprite.x - getFloor(1).offsetX,
            y: actor.sprite.y
          },
          from: { ...actor.route.from },
          to: { ...actor.route.to },
          flipX: actor.sprite.flipX,
          animationId: actor.sprite.anims.currentAnim?.key ?? null
        })),
        bakeryStaff: this.bakeryBaker?.active
          ? {
              visible: this.bakeryBaker.visible,
              position: {
                x: this.bakeryBaker.x - getFloor(1).offsetX,
                y: this.bakeryBaker.y
              },
              frame: Number(this.bakeryBaker.frame.name),
              animationId: this.bakeryBaker.anims.currentAnim?.key ?? null,
              activePhases: [...BAKERY_RUNTIME.baker.activePhases]
            }
          : null,
        finalChase: {
          active: state.chapter4.phase === "final_chase" && this.finalChaseState !== null,
          phase: this.finalChaseState?.phase ?? null,
          floor: this.finalChaseState?.floor ?? null,
          guardFloor: this.finalChaseState?.guardFloor ?? null,
          attempt: this.finalChaseState?.attempt ?? state.chapter4.chaseAttempt,
          targetWaypointId: this.finalChaseState?.guardTargetWaypointId ?? null,
          targetHoldMs: this.finalChaseState?.guardTargetHoldMs ?? 0,
          predictedPlayerPosition: this.finalChaseState?.predictedPlayerPosition
            ? { ...this.finalChaseState.predictedPlayerPosition }
            : null,
          pursuitBand: this.finalChaseState?.pursuitBand ?? null,
          audioBand: this.finalChaseAudioBand,
          closeVoicePlayed: this.finalChaseCloseVoicePlayed,
          floorVoicePlayed: this.finalChaseFloorVoicePlayed,
          pursuitSpeed: this.finalChaseState?.pursuitSpeed ?? null,
          guardToPlayerRouteDistance: this.finalChaseStep?.guardToPlayerRouteDistance ?? null,
          contactHoldMs: this.finalChaseState?.contactHoldMs ?? 0,
          contactGraceRemainingMs: this.finalChaseState?.contactGraceRemainingMs ?? 0,
          portalApplied: this.finalChaseState?.portalApplied ?? false,
          portalRequested: this.finalChaseStep?.portalRequested ?? false,
          portalRemainingDistance: this.finalChaseState?.portalRemainingDistance ?? 0,
          remainingRouteDistance: this.finalChaseStep?.remainingRouteDistance ?? null,
          finishInside: this.finalChaseInsideFinish,
          finishRequested: this.finalChaseStep?.finishRequested ?? false,
          contact: this.finalChaseContact,
          failureRequested: this.finalChaseStep?.failureRequested ?? false,
          guardBounds: chaseGuardBounds
        },
        lightGrid: {
          mask: this.appliedLightMask,
          locked: this.appliedLightLocked,
          panelSession: {
            open: this.hostPowerPanelOpen,
            openRequestId: this.hostPowerPanelSession?.openRequestId ?? null,
            targetId: this.hostPowerPanelSession?.targetId ?? null
          }
        },
        room204Runtime: {
          presentation: selectRoom204RuntimePresentation(
            state.chapter4.phase,
            hasChapterFourFact(state, "room204_restored"),
            state.chapter4.room204Placements
          ),
          completePlacements: isRoom204PlacementSetComplete(state.chapter4.room204Placements),
          mountedPieceCount: this.room204RuntimePieces.size,
          visibleDeskCount: [...this.room204RuntimePieces.values()]
            .filter((piece) => piece.deskSprite.visible).length,
          visibleChairCount: [...this.room204RuntimePieces.values()]
            .filter((piece) => piece.chairSprite.visible).length,
          visibleDiscussionTableCount: this.room204DiscussionTables
            .filter((table) => table.sprite.visible).length,
          podiumVisible: this.room204PodiumSprite?.visible ?? false
        },
        room202Door: {
          state: doorContract?.state ?? "inactive",
          colliderRequired: doorContract?.collider ?? false,
          colliderActive: this.room202DoorCollider?.active === true,
          sourceBounds: { ...FINAL_CHASE_RUNTIME.room202Door.barrierBounds },
          appliedBounds: appliedDoorBounds
        },
        spatialAttestation: this.spatialAttestationLast
          ? { ...this.spatialAttestationLast }
          : null,
        contract: {
          failures: structuredFailures,
          lastFailure: structuredFailures.length > 0
            ? structuredFailures[structuredFailures.length - 1]
            : null
        },
        developerCheckpoint: {
          id: developerCheckpointId,
          source: developerCheckpointSource
        },
        elevatorVisualDepths: FLOORS.map((candidateFloor) => {
          const visual = this.elevatorVisuals.get(candidateFloor.displayFloor);
          const door = visual?.door.depth ?? Number.NaN;
          const indicator = visual?.indicator.depth ?? Number.NaN;
          const lamp = visual?.lamp.depth ?? Number.NaN;
          return {
            floor: candidateFloor.displayFloor,
            door,
            indicator,
            lamp,
            playerInFront: this.player.depth > Math.max(door, indicator, lamp)
          };
        }),
        currentFloor: this.currentFloor,
        currentStoryFloor: floor.storyFloor,
        floorOffsetX: floor.offsetX,
        projectedPlateIds,
        appliedPlateIds: this.appliedPlateIds,
        appliedPlateSignature: this.appliedPlateSignature,
        projectedCollisionIds,
        appliedCollisionIds: [...this.appliedCollisionIds],
        projectedOcclusionIds: [...this.projection.occlusionIds],
        appliedOcclusionIds: [...this.appliedOcclusionIds],
        projectedTargetIds: projectedTargets.map((target) => target.contract.id),
        renderedTargetIds: [...this.renderedTargetIds],
        actionableTargetIds: actionableTargets.map((target) => target.contract.id),
        safeCheckpoint: this.projection.safeCheckpoint,
        contractFailures,
        frameRegistration: {
          manifestEntries: this.frameRegistration.manifestFrameCount,
          registered: this.frameRegistration.registeredFrameCount,
          reused: this.frameRegistration.reusedFrameCount,
          skippedEmpty: this.frameRegistration.skippedEmptyFrameCount,
          registeredKeys: [...this.frameRegistration.frameKeys]
        },
        lightZones: LIGHT_ZONES.map((zone) => ({
          id: zone.id,
          label: zone.label,
          on: (this.appliedLightMask & (1 << zone.bit)) !== 0
        })),
        lightGridLocked: this.appliedLightLocked,
        elevator: {
          phase: this.elevatorPhase,
          targetFloor: this.elevatorTargetFloor,
          doorProgress: this.elevatorDoorProgress,
          panelOpen: this.floorPanel !== null,
          panelMode: this.floorPanelMode,
          selectedFloor: this.floorPanelSelection,
          recordProgress: chapterFourElevatorCollectedRecordCount(state.chapter4.factIds),
          records: ([1, 2, 3] as const).map((displayFloor) => {
            const record = chapterFourElevatorRecordForDisplayFloor(displayFloor);
            return {
              floor: displayFloor,
              factId: record.factId,
              collected: hasChapterFourFact(state, record.factId),
              reachable: this.isElevatorFloorReachable(displayFloor, state)
            };
          }),
          stopChainReconstructed: hasChapterFourFact(state, "elevator_stop_chain_reconstructed"),
          deduction: this.floorPanelMode === "elevator_route_deduction"
            ? {
                actualArrivalFloor: this.elevatorDeductionArrivalFloor,
                unservedCallFloor: this.elevatorDeductionUnservedFloor,
                feedback: this.elevatorDeductionFeedback
              }
            : null,
          nearbyTravelZone: this.nearbyTravelTarget?.id ?? null
        },
        floorElevators: FLOORS.map((entry) => ({
          floor: entry.displayFloor,
          id: entry.elevator.id,
          visibleBounds: offsetRect(entry.elevator.visibleBounds, entry.offsetX),
          doorCenter: {
            x: entry.offsetX + entry.elevator.doorCenter.x,
            y: entry.elevator.doorCenter.y
          },
          standPosition: {
            x: entry.offsetX + entry.elevator.standPosition.x,
            y: entry.elevator.standPosition.y,
            facing: entry.elevator.standPosition.facing ?? "up"
          },
          arrivalPosition: {
            x: entry.offsetX + entry.elevator.arrivalPosition.x,
            y: entry.elevator.arrivalPosition.y,
            facing: entry.elevator.arrivalPosition.facing ?? "down"
          },
          travelBounds: offsetRect(entry.elevator.travelBounds, entry.offsetX)
        })),
        foregroundOcclusions: this.appliedForegrounds.map((visual) => ({
          id: visual.id,
          floor: visual.floor,
          sourceAnnotationId: visual.sourceAnnotationId,
          maskBounds: visual.maskBounds,
          baselineY: visual.baselineY,
          renderMode: visual.renderMode,
          depth: visual.image.depth,
          visible: visual.image.visible,
          occludesPlayer: visual.id === MAIN_ENTRANCE_FOREGROUND_ID
            && visual.floor === this.currentFloor
            && (body?.bottom ?? this.player.y) < visual.baselineY
        }))
      }
    });
  }
}
