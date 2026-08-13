import Phaser from "phaser";
import type { RpgCheckpointId } from "../../core/types";
import teachingBuildingFloor1Url from "../../assets/rpg/interiors/finale/teaching_building_floor_1.png";
import teachingBuildingFloor2Url from "../../assets/rpg/interiors/finale/teaching_building_floor_2.png";
import teachingBuildingFloor3Url from "../../assets/rpg/interiors/finale/teaching_building_floor_3.png";
import teachingBuildingElevatorDoorsUrl from "../../assets/rpg/interiors/finale/teaching_building_elevator_doors.png";
import mazeContent from "../../data/chapter4-temporal-maze.content.json";
import mazeLayout from "../../data/chapter4-three-floor-maze.layout.json";
import {
  CHAPTER_FOUR_MAZE_CLUES,
  CHAPTER_FOUR_MAZE_IDS,
  selectChapterFourMazeProjection,
  type ChapterFourMazeProjection,
  type ChapterFourMazeRouteState
} from "../../modules/ChapterFourMazeProjection";
import type { RpgBridge } from "./RpgBridge";
import {
  ensureFinaleNpcAnimations,
  FINALE_NPC_ANIMATIONS,
  preloadFinaleNpcTextures,
  type FinaleNpcAnimationId
} from "./FinaleNpcTextures";
import {
  distanceFromPlayerToRpgTarget,
  isPlayerFacingRpgTarget,
  type RpgRealityMode,
  type RpgSpatialInteractionTarget
} from "./RpgInteractionContract";
import {
  configureRpgPlayerSprite,
  ensureRpgPlayerTextures,
  preloadRpgPlayerTextures,
  RpgPlayerAnimator
} from "./RpgPlayerTextures";
import { clearRpgRuntimeDebugState, setRpgRuntimeDebugState } from "./RpgRuntimeDebug";
import { subscribeRpgSceneBridge } from "./RpgSceneBridgeSubscription";

type DisplayFloor = 1 | 2 | 3;
type StoryFloor = "A1" | "A2" | "A3";
type TravelZoneId = "elevator" | "stair_up" | "stair_down";
type MazeMoveRoute = "elevator" | "stair";
type MazeMoveResult = "accepted" | "already_complete" | "misaligned" | "wrong_mode" | "locked" | "inactive";
type MazeAction =
  | "observe_npc_schedule"
  | "reconfigure_corridor_bay"
  | "collect_wayfinding_fragment"
  | "observe_old_signage"
  | "observe_bridge_history"
  | "open_second_floor_return_window";
type A1TargetAction =
  | "observe_airflow"
  | "guide_paper"
  | "inspect_elevator"
  | "board_elevator";
type A1Action = A1TargetAction
  | "elevator_replay_missed"
  | "complete_elevator_ride";

interface MapRect {
  left: number;
  top: number;
  right: number;
  bottom: number;
}

interface MapCollisionRect extends MapRect {
  id: string;
}

interface LayoutAnchor {
  id: string;
  label: string;
  bounds: MapRect;
}

interface LayoutPoint {
  id: string;
  x: number;
  y: number;
  facing: "up" | "down";
}

interface LayoutStairLanding {
  id: string;
  direction: "up" | "down";
  targetStoryFloor: StoryFloor;
  bounds: MapRect;
  standPosition: { x: number; y: number };
  arrivalPosition: { x: number; y: number };
  requiredFacing: "up";
}

type FloorAssetId =
  | "teaching-building-floor-1"
  | "teaching-building-floor-2"
  | "teaching-building-floor-3";

interface LayoutFloor {
  displayFloor: DisplayFloor;
  storyFloor: StoryFloor;
  checkpoint: RpgCheckpointId;
  roomId: "a1_lobby" | "a2_corridor" | "a3_wayfinding";
  assetId: FloorAssetId;
  staticCollisions: MapCollisionRect[];
  anchors: LayoutAnchor[];
  stairLandings: LayoutStairLanding[];
  elevatorStand: LayoutPoint;
  safeSpawn: LayoutPoint;
}

interface LayoutSafeRoute extends MapRect {
  displayFloor: DisplayFloor;
  width: number;
  height: number;
}

interface LayoutDynamicGate {
  id: string;
  collisionId: string;
  displayFloor: DisplayFloor;
  kind: "door" | "partition";
  bounds: MapRect;
  closedRouteStates: ChapterFourMazeRouteState[];
}

interface ChapterFourMazeLayout {
  schemaVersion: 1;
  worldSize: { width: number; height: number };
  floors: LayoutFloor[];
  transportCore: {
    elevators: Array<{ id: string; centerX: number; storyFloors: StoryFloor[] }>;
    stairs: Array<MapRect & { id: string; storyFloors: StoryFloor[] }>;
  };
  safeRoutes: Record<string, LayoutSafeRoute>;
  dynamicGates: LayoutDynamicGate[];
}

const LAYOUT = mazeLayout as ChapterFourMazeLayout;
const FLOOR_SIZE = LAYOUT.worldSize;
const FLOOR_GAP = 192;
const FLOOR_STRIDE = FLOOR_SIZE.width + FLOOR_GAP;
const WORLD = {
  width: FLOOR_SIZE.width * LAYOUT.floors.length + FLOOR_GAP * (LAYOUT.floors.length - 1),
  height: FLOOR_SIZE.height
} as const;
const PLAYER_SPEED = 176;
const ELEVATOR_DOORS_TEXTURE = "teaching-building-elevator-doors";
const ELEVATOR_DOOR_FRAME_COUNT = 6;

type ElevatorRuntimePhase =
  | "idle"
  | "waiting"
  | "arriving"
  | "doors_opening"
  | "boarding"
  | "selecting"
  | "doors_closing"
  | "traveling"
  | "destination_opening"
  | "exiting"
  | "destination_closing";

interface ElevatorFloorVisual {
  floor: DisplayFloor;
  centerX: number;
  door: Phaser.GameObjects.Sprite;
  indicatorBack: Phaser.GameObjects.Rectangle;
  indicatorText: Phaser.GameObjects.Text;
  callLamp: Phaser.GameObjects.Arc;
}

const MAIN_ELEVATOR = LAYOUT.transportCore.elevators[0];
const MAIN_STAIR = LAYOUT.transportCore.stairs[0];
const ELEVATOR_LOCAL_CENTER_X = MAIN_ELEVATOR.centerX;
const ELEVATOR_DOOR_CENTER_Y = 111;
const ELEVATOR_INSIDE_Y = 142;
const ELEVATOR_WAIT_STEP_MS = 620;
const ELEVATOR_ARRIVAL_MS = 420;
const ELEVATOR_DOOR_MS = 620;
const ELEVATOR_BOARD_MS = 560;
const ELEVATOR_TRAVEL_STEP_MS = 720;
const HISTORICAL_ELEVATOR_RIDE_MS = mazeContent.elevator.timeline.rideDurationMs;

interface FloorDefinition {
  floor: DisplayFloor;
  storyFloor: StoryFloor;
  roomId: LayoutFloor["roomId"];
  id: FloorAssetId;
  url: string;
  offsetX: number;
  shortTitle: string;
  checkpoint: RpgCheckpointId;
  staticCollisions: readonly MapCollisionRect[];
  anchors: readonly LayoutAnchor[];
  stairLandings: readonly LayoutStairLanding[];
  elevatorStand: LayoutPoint;
  safeSpawn: LayoutPoint;
}

const FLOOR_ASSET_URLS: Readonly<Record<FloorAssetId, string>> = {
  "teaching-building-floor-1": teachingBuildingFloor1Url,
  "teaching-building-floor-2": teachingBuildingFloor2Url,
  "teaching-building-floor-3": teachingBuildingFloor3Url
};

const FLOOR_TITLES: Readonly<Record<DisplayFloor, string>> = {
  1: "1F · 麦斯威面包坊餐厅",
  2: "2F · 教室与开放学习区",
  3: "3F · 校友荣誉门厅"
};

const FLOORS: readonly FloorDefinition[] = LAYOUT.floors.map((floor) => ({
  floor: floor.displayFloor,
  storyFloor: floor.storyFloor,
  roomId: floor.roomId,
  id: floor.assetId,
  url: FLOOR_ASSET_URLS[floor.assetId],
  offsetX: (floor.displayFloor - 1) * FLOOR_STRIDE,
  shortTitle: FLOOR_TITLES[floor.displayFloor],
  checkpoint: floor.checkpoint,
  staticCollisions: floor.staticCollisions,
  anchors: floor.anchors,
  stairLandings: floor.stairLandings,
  elevatorStand: floor.elevatorStand,
  safeSpawn: floor.safeSpawn
}));

interface StoryAnchor {
  id: string;
  label: string;
  floor: DisplayFloor;
  bounds: MapRect;
}

interface TravelZone extends RpgSpatialInteractionTarget {
  id: TravelZoneId;
  requiredFacing: "up";
  targetStoryFloor?: StoryFloor;
  landingId?: string;
}

const STORY_ANCHORS: readonly StoryAnchor[] = FLOORS.flatMap((floor) =>
  floor.anchors.map((anchor) => ({ ...anchor, floor: floor.floor }))
);

const WORLD_STATIC_COLLISIONS: readonly MapCollisionRect[] = FLOORS.flatMap((floor) =>
  floor.staticCollisions.map((rect) => ({
    ...rect,
    id: `floor_${floor.floor}_${rect.id}`,
    left: rect.left + floor.offsetX,
    right: rect.right + floor.offsetX
  }))
);

const SAFE_ROUTE_RECTS = Object.entries(LAYOUT.safeRoutes).map(([id, route]) => {
  const floor = getFloor(route.displayFloor);
  return {
    id,
    floor: route.displayFloor,
    left: route.left + floor.offsetX,
    top: route.top,
    right: route.right + floor.offsetX,
    bottom: route.bottom
  };
});

interface PendingMazeMove {
  requestId: string;
  fromFloor: DisplayFloor;
  targetFloor: DisplayFloor;
  route: MazeMoveRoute;
}

type MazeTargetAction = MazeAction | A1TargetAction | "open_wayfinding_board";
type PendingActionName = MazeTargetAction | A1Action;

interface MazeInteractionTarget extends RpgSpatialInteractionTarget {
  floor: DisplayFloor;
  bounds: MapRect;
  stand: { x: number; y: number };
  requiredMode: RpgRealityMode;
  requiredFacing: "toward_target";
  action: MazeTargetAction;
  visualKind: "observation" | "fragment" | "board" | "window" | "airflow" | "paper" | "elevator";
}

interface MazePartitionTarget extends RpgSpatialInteractionTarget {
  floor: DisplayFloor;
  bounds: MapRect;
  stand: { x: number; y: number };
  requiredMode: "light";
  requiredFacing: "toward_target";
}

interface MazeTargetConfig {
  stand: { x: number; y: number };
  proximity: number;
  requiredMode: RpgRealityMode;
  action: MazeTargetAction;
  visualKind: MazeInteractionTarget["visualKind"];
}

interface PendingMazeAction {
  requestId: string;
  action: PendingActionName;
  targetId: string;
  partitionId?: string;
  fragmentId?: string;
  order?: readonly string[];
}

interface NpcRouteDefinition {
  id: string;
  residualId: string;
  texture: FinaleNpcAnimationId;
  start: { x: number; y: number };
  end: { x: number; y: number };
  scale: number;
  durationMs: number;
  phaseOffsetMs: number;
  forwardFlipX?: boolean;
}

interface NpcRouteVisual {
  definition: NpcRouteDefinition;
  normal: Phaser.GameObjects.Sprite;
  residual: Phaser.GameObjects.Sprite;
  route: Phaser.GameObjects.Graphics;
  frame: number;
  residualFrame: number;
}

interface StudyNpcDefinition {
  id: string;
  residualId: string;
  texture: "student_phone_glance" | "student_adjust_bag";
  x: number;
  y: number;
  scale: number;
  phaseOffsetMs: number;
  flipX?: boolean;
}

interface StudyNpcVisual {
  definition: StudyNpcDefinition;
  normal: Phaser.GameObjects.Sprite;
  residual: Phaser.GameObjects.Sprite;
}

const TARGET_CONFIGS: Readonly<Record<string, MazeTargetConfig>> = {
  [CHAPTER_FOUR_MAZE_IDS.scheduleTarget]: {
    stand: { x: 836, y: 470 },
    proximity: 64,
    requiredMode: "dark",
    action: "observe_npc_schedule",
    visualKind: "observation"
  },
  [CHAPTER_FOUR_MAZE_IDS.fragments[0]]: {
    stand: { x: 600, y: 639 },
    proximity: 72,
    requiredMode: "light",
    action: "collect_wayfinding_fragment",
    visualKind: "fragment"
  },
  [CHAPTER_FOUR_MAZE_IDS.fragments[1]]: {
    stand: { x: 1040, y: 639 },
    proximity: 72,
    requiredMode: "light",
    action: "collect_wayfinding_fragment",
    visualKind: "fragment"
  },
  [CHAPTER_FOUR_MAZE_IDS.returnWindowTarget]: {
    stand: { x: 1100, y: 720 },
    proximity: 64,
    requiredMode: "light",
    action: "open_second_floor_return_window",
    visualKind: "window"
  },
  [CHAPTER_FOUR_MAZE_IDS.oldSignageTarget]: {
    stand: { x: 600, y: 300 },
    proximity: 72,
    requiredMode: "dark",
    action: "observe_old_signage",
    visualKind: "observation"
  },
  [CHAPTER_FOUR_MAZE_IDS.wayfindingBoardTarget]: {
    stand: { x: 600, y: 575 },
    proximity: 72,
    requiredMode: "light",
    action: "open_wayfinding_board",
    visualKind: "board"
  },
  [CHAPTER_FOUR_MAZE_IDS.bridgeHistoryTarget]: {
    stand: { x: 1060, y: 320 },
    proximity: 72,
    requiredMode: "dark",
    action: "observe_bridge_history",
    visualKind: "observation"
  }
};

const MAZE_INTERACTION_TARGETS: readonly MazeInteractionTarget[] = STORY_ANCHORS.flatMap((anchor) => {
  const config = TARGET_CONFIGS[anchor.id];
  if (!config) return [];
  return [{
    id: anchor.id,
    label: anchor.label,
    floor: anchor.floor,
    bounds: anchor.bounds,
    x: (anchor.bounds.left + anchor.bounds.right) / 2,
    y: (anchor.bounds.top + anchor.bounds.bottom) / 2,
    width: anchor.bounds.right - anchor.bounds.left,
    height: anchor.bounds.bottom - anchor.bounds.top,
    stand: config.stand,
    proximity: config.proximity,
    requiredMode: config.requiredMode,
    requiredFacing: "toward_target",
    action: config.action,
    visualKind: config.visualKind
  }];
});

const A2_NPC_ROUTES: readonly NpcRouteDefinition[] = [
  {
    id: "a2_discussion_group",
    residualId: "a2_discussion_group_residual",
    texture: "student_walk",
    start: { x: 920, y: 458 },
    end: { x: 708, y: 458 },
    scale: 0.56,
    durationMs: 6200,
    phaseOffsetMs: 0
  },
  {
    id: "a2_headphone_student",
    residualId: "a2_headphone_student_residual",
    texture: "student_walk",
    start: { x: 760, y: 516 },
    end: { x: 982, y: 516 },
    scale: 0.56,
    durationMs: 6800,
    phaseOffsetMs: 2100,
    forwardFlipX: true
  },
  {
    id: "a2_clearance_staff",
    residualId: "a2_clearance_staff_residual",
    texture: "cleaner_push_cart",
    start: { x: 574, y: 206 },
    end: { x: 1098, y: 206 },
    scale: 0.52,
    durationMs: 9200,
    phaseOffsetMs: 900
  },
  {
    id: "a2_security_patrol",
    residualId: "a2_security_patrol_residual",
    texture: "guard_walk",
    start: { x: 1090, y: 274 },
    end: { x: 1090, y: 520 },
    scale: 0.54,
    durationMs: 7800,
    phaseOffsetMs: 3200
  },
  {
    id: "a2_upper_corridor_student",
    residualId: "a2_upper_corridor_student_residual",
    texture: "student_walk",
    start: { x: 1090, y: 196 },
    end: { x: 660, y: 196 },
    scale: 0.54,
    durationMs: 9800,
    phaseOffsetMs: 4700
  },
  {
    id: "a2_returning_student",
    residualId: "a2_returning_student_residual",
    texture: "student_walk",
    start: { x: 610, y: 546 },
    end: { x: 1040, y: 546 },
    scale: 0.55,
    durationMs: 10400,
    phaseOffsetMs: 1600,
    forwardFlipX: true
  }
];

const A2_STUDY_NPCS: readonly StudyNpcDefinition[] = [
  {
    id: "a2_study_student_201_west",
    residualId: "a2_study_student_201_west_residual",
    texture: "student_phone_glance",
    x: 122,
    y: 418,
    scale: 0.52,
    phaseOffsetMs: 0
  },
  {
    id: "a2_study_student_201_east",
    residualId: "a2_study_student_201_east_residual",
    texture: "student_adjust_bag",
    x: 316,
    y: 418,
    scale: 0.52,
    phaseOffsetMs: 740,
    flipX: true
  },
  {
    id: "a2_study_student_204_west",
    residualId: "a2_study_student_204_west_residual",
    texture: "student_adjust_bag",
    x: 143,
    y: 674,
    scale: 0.51,
    phaseOffsetMs: 1320
  },
  {
    id: "a2_study_student_204_east",
    residualId: "a2_study_student_204_east_residual",
    texture: "student_phone_glance",
    x: 310,
    y: 674,
    scale: 0.51,
    phaseOffsetMs: 1980,
    flipX: true
  }
];

const A2_STUDY_TABLE_CROPS = [
  { id: "201-west", left: 77, top: 388, right: 194, bottom: 426 },
  { id: "201-east", left: 232, top: 388, right: 382, bottom: 426 },
  { id: "204-west", left: 83, top: 639, right: 198, bottom: 676 },
  { id: "204-east", left: 211, top: 639, right: 373, bottom: 676 }
] as const;

const A1_TARGET_IDS = Object.freeze({
  airflow: "a1_airflow_trace",
  paperGuide: "a1_maxwell_warm_air",
  elevatorInspect: "a1_main_elevator_history",
  elevatorBoard: "a1_main_elevator_boarding"
});
const A1_TARGET_ACTIONS = new Set<A1TargetAction>([
  "observe_airflow",
  "guide_paper",
  "inspect_elevator",
  "board_elevator"
]);

function isA1TargetAction(action: PendingActionName): action is A1TargetAction {
  return A1_TARGET_ACTIONS.has(action as A1TargetAction);
}

function getFloor(displayFloor: DisplayFloor): FloorDefinition {
  return FLOORS.find((floor) => floor.floor === displayFloor) ?? FLOORS[0];
}

function getDisplayFloor(storyFloor: string): DisplayFloor | null {
  return FLOORS.find((floor) => floor.storyFloor === storyFloor)?.floor ?? null;
}

function distanceToBounds(
  point: { x: number; y: number },
  bounds: MapRect
): number {
  const dx = Math.max(bounds.left - point.x, 0, point.x - bounds.right);
  const dy = Math.max(bounds.top - point.y, 0, point.y - bounds.bottom);
  return Math.hypot(dx, dy);
}

function createTravelZones(floor: FloorDefinition): TravelZone[] {
  const elevator: TravelZone = {
    id: "elevator",
    label: "主电梯",
    x: floor.elevatorStand.x,
    y: floor.elevatorStand.y - 6,
    width: 144,
    height: 107,
    proximity: 54,
    requiredFacing: "up"
  };
  const stairs = floor.stairLandings.map((landing): TravelZone => ({
    id: landing.direction === "up" ? "stair_up" : "stair_down",
    label: landing.direction === "up" ? "相邻楼梯上行口" : "相邻楼梯下行口",
    x: (landing.bounds.left + landing.bounds.right) / 2,
    y: (landing.bounds.top + landing.bounds.bottom) / 2,
    width: landing.bounds.right - landing.bounds.left,
    height: landing.bounds.bottom - landing.bounds.top,
    proximity: 54,
    requiredFacing: landing.requiredFacing,
    targetStoryFloor: landing.targetStoryFloor,
    landingId: landing.id
  }));
  return [elevator, ...stairs];
}

export class ChapterFourTemporalMazeScene extends Phaser.Scene {
  private bridge!: RpgBridge;
  private player!: Phaser.Physics.Arcade.Sprite;
  private staticObstacles!: Phaser.Physics.Arcade.StaticGroup;
  private dynamicObstacles!: Phaser.Physics.Arcade.StaticGroup;
  private cursors!: Phaser.Types.Input.Keyboard.CursorKeys;
  private keys!: Record<"W" | "A" | "S" | "D", Phaser.Input.Keyboard.Key>;
  private interactKey!: Phaser.Input.Keyboard.Key;
  private confirmKey!: Phaser.Input.Keyboard.Key;
  private escapeKey!: Phaser.Input.Keyboard.Key;
  private floorKeys!: Record<DisplayFloor, Phaser.Input.Keyboard.Key>;
  private animator!: RpgPlayerAnimator;
  private virtualDirection = { x: 0, y: 0 };
  private interactionRequested = false;
  private currentFloor: DisplayFloor = 1;
  private nearbyTravelZone: TravelZone | null = null;
  private nearbyTarget: MazeInteractionTarget | null = null;
  private nearbyPartitionId: string | null = null;
  private nearbyAnchor: StoryAnchor | null = null;
  private floorPanel: Phaser.GameObjects.Container | null = null;
  private floorPanelSelection: DisplayFloor = 1;
  private floorPanelButtons: Array<{
    floor: DisplayFloor;
    button: Phaser.GameObjects.Rectangle;
    label: Phaser.GameObjects.Text;
  }> = [];
  private floorCaption!: Phaser.GameObjects.Text;
  private interactionHint!: Phaser.GameObjects.Text;
  private feedbackText!: Phaser.GameObjects.Text;
  private feedbackTimer: Phaser.Time.TimerEvent | null = null;
  private elevatorVisuals = new Map<DisplayFloor, ElevatorFloorVisual>();
  private elevatorPhase: ElevatorRuntimePhase = "idle";
  private elevatorTargetFloor: DisplayFloor | null = null;
  private elevatorDisplayFloor: DisplayFloor = 1;
  private elevatorDoorProgress = 0;
  private elevatorWaitEndsAt = 0;
  private elevatorRideFromFloor: DisplayFloor = 1;
  private projection!: ChapterFourMazeProjection;
  private projectionSignature = "";
  private dynamicGateRevision = 0;
  private dynamicGateVisuals = new Map<string, Phaser.GameObjects.Rectangle>();
  private targetVisuals = new Map<string, Phaser.GameObjects.Container>();
  private npcVisuals = new Map<string, NpcRouteVisual>();
  private studyNpcVisuals = new Map<string, StudyNpcVisual>();
  private activeDynamicCollisionRects: MapCollisionRect[] = [];
  private pendingMazeMove: PendingMazeMove | null = null;
  private pendingMazeMoveTimer: Phaser.Time.TimerEvent | null = null;
  private mazeMoveRequestSerial = 0;
  private pendingMazeAction: PendingMazeAction | null = null;
  private pendingMazeActionTimer: Phaser.Time.TimerEvent | null = null;
  private mazeActionRequestSerial = 0;
  private historicalDoorOpen = false;
  private historicalEntryWindowEndsAt = 0;
  private historicalEntryTimer: Phaser.Time.TimerEvent | null = null;
  private historicalRideInProgress = false;
  private lastAppliedCheckpoint: RpgCheckpointId | null = null;
  private lastAppliedLocationSignature = "";

  constructor() {
    super("chapter-four-temporal-maze");
  }

  preload(): void {
    for (const floor of FLOORS) {
      if (!this.textures.exists(floor.id)) this.load.image(floor.id, floor.url);
    }
    if (!this.textures.exists(ELEVATOR_DOORS_TEXTURE)) {
      this.load.spritesheet(ELEVATOR_DOORS_TEXTURE, teachingBuildingElevatorDoorsUrl, {
        frameWidth: 72,
        frameHeight: 96
      });
    }
    preloadRpgPlayerTextures(this);
    preloadFinaleNpcTextures(this);
  }

  create(): void {
    this.bridge = this.registry.get("rpgBridge") as RpgBridge;
    const state = this.bridge.getState();
    this.projection = selectChapterFourMazeProjection(state.chapter4);
    this.currentFloor = getDisplayFloor(state.chapter4.floor) ?? 1;
    const checkpoint = state.rpgCheckpoint.startsWith("c4_")
      ? state.rpgCheckpoint
      : this.projection.safeCheckpoint;

    this.cameras.main.setBackgroundColor(0x07111d).setRoundPixels(true);
    for (const floor of FLOORS) {
      this.add.image(floor.offsetX, 0, floor.id).setOrigin(0).setDepth(0);
      this.textures.get(floor.id).setFilter(Phaser.Textures.FilterMode.NEAREST);
    }
    this.physics.world.setBounds(0, 0, WORLD.width, WORLD.height);
    this.createCollisionGroups();
    this.createElevatorVisuals();
    ensureFinaleNpcAnimations(this);
    this.createNpcVisuals();

    ensureRpgPlayerTextures(this);
    const initialFloor = getFloor(this.currentFloor);
    const initialSpawn = checkpoint === "c4_a1_main_elevator"
      ? initialFloor.elevatorStand
      : initialFloor.safeSpawn;
    this.player = this.physics.add.sprite(
      initialFloor.offsetX + initialSpawn.x,
      initialSpawn.y,
      `act1-player-${initialSpawn.facing}-0`
    ).setCollideWorldBounds(true);
    configureRpgPlayerSprite(this.player);
    this.player.setScale(0.75);
    this.animator = new RpgPlayerAnimator(this.player, initialSpawn.facing);
    this.physics.add.collider(this.player, this.staticObstacles);
    this.physics.add.collider(this.player, this.dynamicObstacles);
    this.lastAppliedCheckpoint = checkpoint;
    this.lastAppliedLocationSignature = this.createLocationSignature(state);

    this.cursors = this.input.keyboard!.createCursorKeys();
    this.keys = this.input.keyboard!.addKeys("W,A,S,D") as Record<"W" | "A" | "S" | "D", Phaser.Input.Keyboard.Key>;
    this.interactKey = this.input.keyboard!.addKey(Phaser.Input.Keyboard.KeyCodes.SPACE);
    this.confirmKey = this.input.keyboard!.addKey(Phaser.Input.Keyboard.KeyCodes.ENTER);
    this.escapeKey = this.input.keyboard!.addKey(Phaser.Input.Keyboard.KeyCodes.ESC);
    this.floorKeys = {
      1: this.input.keyboard!.addKey(Phaser.Input.Keyboard.KeyCodes.ONE),
      2: this.input.keyboard!.addKey(Phaser.Input.Keyboard.KeyCodes.TWO),
      3: this.input.keyboard!.addKey(Phaser.Input.Keyboard.KeyCodes.THREE)
    };
    this.createHud();
    this.configureCameraForFloor();
    this.syncProjection(true);

    subscribeRpgSceneBridge(
      this.events,
      this.bridge,
      (event) => {
        if (event.name === "chapter4_airflow_completed") {
          this.time.delayedCall(0, () => {
            this.syncProjection(true);
            this.syncCurrentFloorFromState();
          });
          return;
        }
        if (
          event.name === "chapter4_airflow_observed"
          || event.name === "chapter4_elevator_history_observed"
        ) {
          this.time.delayedCall(0, () => this.syncProjection(true));
          return;
        }
        if (event.name === "chapter4_elevator_replay_started") {
          this.time.delayedCall(0, () => {
            this.beginHistoricalElevatorEntryWindow(Number(event.payload?.entryWindowSeconds) || 6);
          });
          return;
        }
        if (event.name === "chapter4_elevator_player_boarded") {
          this.time.delayedCall(0, () => this.beginHistoricalElevatorBoarding());
          return;
        }
        if (event.name === "chapter4_elevator_ride_completed") {
          this.time.delayedCall(0, () => this.finishHistoricalElevatorTravel());
          return;
        }
        if (event.name === "chapter4_maze_action_resolved") {
          this.handleMazeActionResolved(event.payload);
          return;
        }
        if (event.name === "chapter4_wayfinding_panel_resolved") {
          this.handleWayfindingPanelResolved(event.payload);
          return;
        }
        if (event.name === "chapter4_maze_move_resolved") {
          this.handleMazeMoveResolved(event.payload);
          return;
        }
        if (event.name === "rpg_direction_changed") {
          const x = Number(event.payload?.x) || 0;
          const y = Number(event.payload?.y) || 0;
          if (this.elevatorPhase === "selecting" && this.floorPanel) {
            if (x !== 0 || y !== 0) {
              const delta = x > 0 || y > 0 ? 1 : -1;
              this.setFloorPanelSelection(
                Phaser.Math.Clamp(this.floorPanelSelection + delta, 1, 3) as DisplayFloor
              );
            }
            this.virtualDirection = { x: 0, y: 0 };
            return;
          }
          if (this.elevatorPhase !== "idle") {
            this.virtualDirection = { x: 0, y: 0 };
            return;
          }
          this.virtualDirection = { x, y };
          return;
        }
        if (event.name === "rpg_interact") {
          if (this.elevatorPhase === "selecting" && this.floorPanel) {
            this.requestElevatorDestination(this.floorPanelSelection);
          } else {
            this.interactionRequested = true;
          }
        }
      },
      clearRpgRuntimeDebugState
    );

    this.bridge.setRpgLocation("duan_yongping_temporal_maze", checkpoint);
    this.bridge.emit("rpg_booted", {
      scene: "duan_yongping_temporal_maze",
      checkpoint,
      stitchedFloors: LAYOUT.floors.length,
      layoutSchemaVersion: LAYOUT.schemaVersion
    });
    this.refreshProximityState();
    this.publishDebug();
    if (
      state.chapter4.phase === "elevator_track_sync"
      && state.chapter4.elevatorPlayerBoarded
      && this.currentFloor === 1
    ) {
      this.historicalDoorOpen = true;
      this.setElevatorDoorProgress(1, 1);
      this.time.delayedCall(0, () => this.beginHistoricalElevatorBoarding());
    } else if (
      state.chapter4.phase === "elevator_track_sync"
      && state.chapter4.elevatorTrackAligned
      && state.chapter4.elevatorHistoryObserved
      && this.currentFloor === 1
    ) {
      this.time.delayedCall(
        0,
        () => this.beginHistoricalElevatorEntryWindow(
          mazeContent.elevator.timeline.entryWindowMs / 1000
        )
      );
    }
  }

  update(): void {
    this.syncProjection();
    this.syncCurrentFloorFromState();
    this.updateNpcVisuals(this.time.now);
    if (this.floorPanel) {
      this.player.setVelocity(0, 0);
      this.animator.update(new Phaser.Math.Vector2(), this.time.now);
      if (Phaser.Input.Keyboard.JustDown(this.cursors.left)) {
        this.setFloorPanelSelection(Math.max(1, this.floorPanelSelection - 1) as DisplayFloor);
      }
      if (Phaser.Input.Keyboard.JustDown(this.cursors.right)) {
        this.setFloorPanelSelection(Math.min(3, this.floorPanelSelection + 1) as DisplayFloor);
      }
      if (Phaser.Input.Keyboard.JustDown(this.cursors.up)) {
        this.setFloorPanelSelection(Math.max(1, this.floorPanelSelection - 1) as DisplayFloor);
      }
      if (Phaser.Input.Keyboard.JustDown(this.cursors.down)) {
        this.setFloorPanelSelection(Math.min(3, this.floorPanelSelection + 1) as DisplayFloor);
      }
      if (Phaser.Input.Keyboard.JustDown(this.confirmKey)) {
        this.requestElevatorDestination(this.floorPanelSelection);
      }
      if (Phaser.Input.Keyboard.JustDown(this.floorKeys[1])) this.requestElevatorDestination(1);
      if (Phaser.Input.Keyboard.JustDown(this.floorKeys[2])) this.requestElevatorDestination(2);
      if (Phaser.Input.Keyboard.JustDown(this.floorKeys[3])) this.requestElevatorDestination(3);
      if (Phaser.Input.Keyboard.JustDown(this.escapeKey)) this.cancelElevatorRide();
      if (this.interactionRequested) this.requestElevatorDestination(this.floorPanelSelection);
      this.interactionRequested = false;
      this.publishDebug();
      return;
    }

    if (this.elevatorPhase !== "idle") {
      this.player.setVelocity(0, 0);
      const elevatorMotion = this.elevatorPhase === "boarding"
        ? new Phaser.Math.Vector2(0, -PLAYER_SPEED)
        : this.elevatorPhase === "exiting"
          ? new Phaser.Math.Vector2(0, PLAYER_SPEED)
          : new Phaser.Math.Vector2();
      this.animator.update(elevatorMotion, this.time.now);
      this.interactionRequested = false;
      this.publishDebug();
      return;
    }

    const vector = new Phaser.Math.Vector2(
      Number(this.cursors.right.isDown || this.keys.D.isDown) - Number(this.cursors.left.isDown || this.keys.A.isDown) + this.virtualDirection.x,
      Number(this.cursors.down.isDown || this.keys.S.isDown) - Number(this.cursors.up.isDown || this.keys.W.isDown) + this.virtualDirection.y
    );
    if (vector.lengthSq() > 0) vector.normalize().scale(PLAYER_SPEED);
    this.player.setVelocity(vector.x, vector.y).setDepth(this.player.y + 4000);
    this.animator.update(vector, this.time.now);
    this.refreshProximityState();

    if (Phaser.Input.Keyboard.JustDown(this.interactKey) || this.interactionRequested) {
      this.handleInteraction();
    }
    this.interactionRequested = false;
    this.publishDebug();
  }

  private createHud(): void {
    const baseStyle: Phaser.Types.GameObjects.Text.TextStyle = {
      fontFamily: "'Fusion Pixel', 'Courier New', monospace",
      color: "#f7f1dc",
      fontSize: "18px",
      stroke: "#07111d",
      strokeThickness: 5,
      shadow: { color: "#07111d", blur: 0, offsetX: 2, offsetY: 2, fill: true }
    };
    this.floorCaption = this.add.text(24, 58, "", baseStyle)
      .setScrollFactor(0)
      .setDepth(10000);
    this.interactionHint = this.add.text(480, 494, "", {
      ...baseStyle,
      fontSize: "16px",
      align: "center"
    }).setOrigin(0.5).setScrollFactor(0).setDepth(10000).setVisible(false);
    this.feedbackText = this.add.text(480, 454, "", {
      ...baseStyle,
      fontSize: "16px",
      color: "#8fe8ff",
      align: "center"
    }).setOrigin(0.5).setScrollFactor(0).setDepth(10000).setVisible(false);
  }

  private configureCameraForFloor(): void {
    const floor = getFloor(this.currentFloor);
    this.cameras.main
      .setBounds(floor.offsetX, 0, FLOOR_SIZE.width, FLOOR_SIZE.height)
      .setZoom(1)
      .startFollow(this.player, true, 0.12, 0.12);
  }

  private createCollisionGroups(): void {
    const showDebug = new URLSearchParams(window.location.search).get("debugColliders") === "1";
    this.staticObstacles = this.physics.add.staticGroup();
    this.dynamicObstacles = this.physics.add.staticGroup();
    for (const rect of WORLD_STATIC_COLLISIONS) {
      const obstacle = this.add.rectangle(
        (rect.left + rect.right) / 2,
        (rect.top + rect.bottom) / 2,
        rect.right - rect.left,
        rect.bottom - rect.top,
        showDebug ? 0xff315b : 0x000000,
        showDebug ? 0.22 : 0
      );
      this.physics.add.existing(obstacle, true);
      this.staticObstacles.add(obstacle);
    }
  }

  private createNpcVisuals(): void {
    const floor = getFloor(2);
    for (const definition of A2_NPC_ROUTES) {
      const asset = FINALE_NPC_ANIMATIONS[definition.texture];
      const normal = this.add.sprite(
        floor.offsetX + definition.start.x,
        definition.start.y,
        definition.texture,
        0
      ).setOrigin(asset.footAnchor.x, asset.footAnchor.y)
        .setScale(definition.scale)
        .setFlipX(Boolean(definition.forwardFlipX))
        .setVisible(false);
      normal.play(definition.texture, true);
      const residual = this.add.sprite(
        floor.offsetX + definition.start.x,
        definition.start.y,
        definition.texture,
        Math.min(1, asset.frameCount - 1)
      ).setOrigin(asset.footAnchor.x, asset.footAnchor.y)
        .setScale(definition.scale)
        .setFlipX(Boolean(definition.forwardFlipX))
        .setTint(0x79e6ff)
        .setBlendMode(Phaser.BlendModes.ADD)
        .setVisible(false);
      const route = this.add.graphics().setDepth(3380).setVisible(false);
      route.lineStyle(3, 0x79e6ff, 0.34);
      route.lineBetween(
        floor.offsetX + definition.start.x,
        definition.start.y,
        floor.offsetX + definition.end.x,
        definition.end.y
      );
      for (let step = 0; step <= 4; step += 1) {
        const progress = step / 4;
        route.fillStyle(0xb3f3ff, 0.5 - step * 0.055);
        route.fillCircle(
          floor.offsetX + Phaser.Math.Linear(definition.start.x, definition.end.x, progress),
          Phaser.Math.Linear(definition.start.y, definition.end.y, progress),
          3
        );
      }
      this.npcVisuals.set(definition.id, {
        definition,
        normal,
        residual,
        route,
        frame: 0,
        residualFrame: Math.min(1, asset.frameCount - 1)
      });
    }

    for (const definition of A2_STUDY_NPCS) {
      const asset = FINALE_NPC_ANIMATIONS[definition.texture];
      const studyAnimationKey = `a2-study-${definition.texture}`;
      if (!this.anims.exists(studyAnimationKey)) {
        this.anims.create({
          key: studyAnimationKey,
          frames: this.anims.generateFrameNumbers(definition.texture, {
            start: 0,
            end: asset.frameCount - 1
          }),
          frameRate: asset.fps,
          repeat: -1,
          yoyo: true,
          repeatDelay: 680
        });
      }
      const normal = this.add.sprite(
        floor.offsetX + definition.x,
        definition.y,
        definition.texture,
        0
      ).setOrigin(asset.footAnchor.x, asset.footAnchor.y)
        .setScale(definition.scale)
        .setFlipX(Boolean(definition.flipX))
        .setDepth(definition.y + 3900)
        .setVisible(false);
      normal.play(studyAnimationKey, true);
      normal.anims.setProgress(
        (definition.phaseOffsetMs % Math.max(1, 1000 / asset.fps * asset.frameCount))
        / Math.max(1, 1000 / asset.fps * asset.frameCount)
      );
      const residual = this.add.sprite(
        floor.offsetX + definition.x,
        definition.y - 2,
        definition.texture,
        Math.min(1, asset.frameCount - 1)
      ).setOrigin(asset.footAnchor.x, asset.footAnchor.y)
        .setScale(definition.scale)
        .setFlipX(Boolean(definition.flipX))
        .setTint(0x79e6ff)
        .setBlendMode(Phaser.BlendModes.ADD)
        .setAlpha(0.42)
        .setDepth(definition.y + 3890)
        .setVisible(false);
      this.studyNpcVisuals.set(definition.id, { definition, normal, residual });
    }

    // Match the canteen seating treatment: redraw the source table fronts over
    // the students so their upper bodies stay readable and their legs tuck
    // behind the authored desks instead of floating above the furniture.
    const floorTexture = this.textures.get(floor.id);
    for (const crop of A2_STUDY_TABLE_CROPS) {
      const frameName = `a2-study-table-${crop.id}`;
      if (!floorTexture.has(frameName)) {
        floorTexture.add(
          frameName,
          0,
          crop.left,
          crop.top,
          crop.right - crop.left,
          crop.bottom - crop.top
        );
      }
      this.add.image(
        floor.offsetX + crop.left,
        crop.top,
        floor.id,
        frameName
      ).setOrigin(0)
        .setDepth(crop.bottom + 3900);
    }
  }

  private updateNpcVisuals(now: number): void {
    const state = this.bridge.getState().chapter4;
    const normalIds = new Set(this.projection.visibleNpcIds);
    const residualIds = new Set(this.projection.residualNpcIds);
    const onSecondFloor = this.currentFloor === 2;
    const floor = getFloor(2);
    for (const visual of this.npcVisuals.values()) {
      const definition = visual.definition;
      const asset = FINALE_NPC_ANIMATIONS[definition.texture];
      const cycleProgress = ((now + definition.phaseOffsetMs) % definition.durationMs) / definition.durationMs;
      const movingForward = cycleProgress < 0.5;
      const movementProgress = movingForward
        ? cycleProgress * 2
        : (1 - cycleProgress) * 2;
      const x = floor.offsetX + Phaser.Math.Linear(
        definition.start.x,
        definition.end.x,
        movementProgress
      );
      const y = Phaser.Math.Linear(definition.start.y, definition.end.y, movementProgress);
      const residualFrame = Math.min(
        Math.floor(movementProgress * asset.frameCount),
        asset.frameCount - 1
      );
      visual.frame = visual.normal.anims.currentFrame?.index ?? 0;
      visual.residualFrame = residualFrame;
      visual.normal
        .setPosition(x, y)
        .setFlipX(
          Math.abs(definition.end.x - definition.start.x) < 1
            ? Boolean(definition.forwardFlipX)
            : movingForward
              ? Boolean(definition.forwardFlipX)
              : !Boolean(definition.forwardFlipX)
        )
        .setAlpha(1)
        .setDepth(y + 3900)
        .setVisible(onSecondFloor && state.mode === "light" && normalIds.has(definition.id));
      visual.residual
        .setFrame(residualFrame)
        .setPosition(x, y - 2)
        .setFlipX(
          Math.abs(definition.end.x - definition.start.x) < 1
            ? Boolean(definition.forwardFlipX)
            : movingForward
              ? Boolean(definition.forwardFlipX)
              : !Boolean(definition.forwardFlipX)
        )
        .setAlpha(0.42)
        .setDepth(y + 3890)
        .setVisible(
          onSecondFloor
          && state.mode === "dark"
          && residualIds.has(definition.residualId)
        );
      visual.route.setVisible(
        onSecondFloor
        && state.mode === "dark"
        && residualIds.has(definition.residualId)
      );
    }

    for (const visual of this.studyNpcVisuals.values()) {
      const { definition } = visual;
      visual.normal.setVisible(
        onSecondFloor
        && state.mode === "light"
        && normalIds.has(definition.id)
      );
      visual.residual.setVisible(
        onSecondFloor
        && state.mode === "dark"
        && residualIds.has(definition.residualId)
      );
    }
  }

  private getActiveA1Targets(): MazeInteractionTarget[] {
    const state = this.bridge.getState().chapter4;
    if (
      this.currentFloor !== 1
      || state.floor !== "A1"
      || this.elevatorPhase !== "idle"
    ) {
      return [];
    }
    const floor = getFloor(1);
    const mainEntrance = floor.anchors.find((anchor) => anchor.id === "main_entrance");
    const maxwell = floor.anchors.find((anchor) => anchor.id === "maxwell_bakery");
    if (!mainEntrance || !maxwell) return [];

    if (
      (state.phase === "arrival" || state.phase === "airflow_overlay")
      && !state.airflowObserved
    ) {
      const centerX = (mainEntrance.bounds.left + mainEntrance.bounds.right) / 2;
      const bounds = {
        left: centerX - 52,
        top: mainEntrance.bounds.top - 76,
        right: centerX + 52,
        bottom: mainEntrance.bounds.top - 22
      };
      return [{
        id: A1_TARGET_IDS.airflow,
        label: "门厅中央水迹",
        floor: 1,
        bounds,
        x: centerX,
        y: (bounds.top + bounds.bottom) / 2,
        width: bounds.right - bounds.left,
        height: bounds.bottom - bounds.top,
        stand: { x: centerX, y: bounds.bottom + 28 },
        proximity: 64,
        requiredMode: "dark",
        requiredFacing: "toward_target",
        action: "observe_airflow",
        visualKind: "airflow"
      }];
    }

    if (
      state.phase === "airflow_overlay"
      && state.airflowObserved
      && !state.paperGuidedToElevator
    ) {
      const bounds = {
        left: maxwell.bounds.left + 100,
        top: maxwell.bounds.top + 118,
        right: maxwell.bounds.right - 110,
        bottom: maxwell.bounds.top + 310
      };
      return [{
        id: A1_TARGET_IDS.paperGuide,
        label: "Maxwell 暖风与卷帘门",
        floor: 1,
        bounds,
        x: (bounds.left + bounds.right) / 2,
        y: (bounds.top + bounds.bottom) / 2,
        width: bounds.right - bounds.left,
        height: bounds.bottom - bounds.top,
        stand: { x: (bounds.left + bounds.right) / 2, y: bounds.bottom + 30 },
        proximity: 72,
        requiredMode: "light",
        requiredFacing: "toward_target",
        action: "guide_paper",
        visualKind: "paper"
      }];
    }

    if (state.phase !== "elevator_track_sync" || !state.paperGuidedToElevator) return [];
    if (state.elevatorPlayerBoarded) return [];
    const bounds = {
      left: floor.elevatorStand.x - 42,
      top: 62,
      right: floor.elevatorStand.x + 42,
      bottom: 158
    };
    const boardReady = state.elevatorTrackAligned && this.historicalDoorOpen;
    const replayReady = state.elevatorHistoryObserved && !boardReady;
    return [{
      id: boardReady ? A1_TARGET_IDS.elevatorBoard : A1_TARGET_IDS.elevatorInspect,
      label: boardReady
        ? "已对齐的历史电梯"
        : replayReady
          ? "主电梯历史重放"
          : "主电梯历史轨道",
      floor: 1,
      bounds,
      x: floor.elevatorStand.x,
      y: (bounds.top + bounds.bottom) / 2,
      width: bounds.right - bounds.left,
      height: bounds.bottom - bounds.top,
      stand: { x: floor.elevatorStand.x, y: floor.elevatorStand.y },
      proximity: 54,
      requiredMode: boardReady || replayReady ? "light" : "dark",
      requiredFacing: "toward_target",
      action: boardReady ? "board_elevator" : "inspect_elevator",
      visualKind: "elevator"
    }];
  }

  private getActiveInteractionTargets(): MazeInteractionTarget[] {
    const activeMazeTargetIds = new Set(this.projection.activeTargetIds);
    return [
      ...this.getActiveA1Targets(),
      ...MAZE_INTERACTION_TARGETS.filter((target) => activeMazeTargetIds.has(target.id))
    ];
  }

  private syncProjection(force = false): void {
    const chapter = this.bridge.getState().chapter4;
    const next = selectChapterFourMazeProjection(chapter);
    const signature = JSON.stringify({
      phase: chapter.phase,
      floor: chapter.floor,
      airflowObserved: chapter.airflowObserved,
      paperGuidedToElevator: chapter.paperGuidedToElevator,
      elevatorHistoryObserved: chapter.elevatorHistoryObserved,
      elevatorTrackAligned: chapter.elevatorTrackAligned,
      elevatorPlayerBoarded: chapter.elevatorPlayerBoarded,
      historicalDoorOpen: this.historicalDoorOpen,
      elevatorPhase: this.elevatorPhase,
      routeState: next.routeState,
      visibleNpcIds: next.visibleNpcIds,
      residualNpcIds: next.residualNpcIds,
      activeDoorIds: next.activeDoorIds,
      activePartitionIds: next.activePartitionIds,
      activeCollisionIds: next.activeCollisionIds,
      activeTargetIds: next.activeTargetIds,
      safeCheckpoint: next.safeCheckpoint
    });
    this.projection = next;
    if (!force && signature === this.projectionSignature) return;
    this.projectionSignature = signature;
    this.refreshDynamicGates();
    this.refreshTargetVisuals();
  }

  private refreshTargetVisuals(): void {
    for (const visual of this.targetVisuals.values()) {
      this.tweens.killTweensOf(visual);
      visual.destroy(true);
    }
    this.targetVisuals.clear();
    for (const target of this.getActiveInteractionTargets()) {
      const floor = getFloor(target.floor);
      const color = target.requiredMode === "dark" ? 0x67ddff : 0xffd36f;
      const width = target.width ?? 40;
      const height = target.height ?? 40;
      const container = this.add.container(
        floor.offsetX + target.x,
        target.y
      ).setDepth(3550);
      const outline = this.add.rectangle(0, 0, width, height, color, 0.055)
        .setStrokeStyle(2, color, 0.72)
        .setInteractive({ useHandCursor: true })
        .on("pointerup", () => this.tryTargetInteraction(target));
      const markerSize = target.visualKind === "fragment" ? 18 : 12;
      const marker = this.add.rectangle(0, 0, markerSize, markerSize, color, 0.9)
        .setAngle(target.visualKind === "fragment" ? 45 : 0)
        .setStrokeStyle(2, 0xf7f1dc, 0.86);
      const decoration = this.add.graphics();
      if (target.visualKind === "airflow") {
        decoration.lineStyle(3, color, 0.62);
        decoration.beginPath();
        decoration.moveTo(-width * 0.4, height * 0.24);
        decoration.lineTo(-width * 0.12, -height * 0.18);
        decoration.lineTo(width * 0.12, height * 0.08);
        decoration.lineTo(width * 0.4, -height * 0.28);
        decoration.strokePath();
        for (const point of [-0.4, -0.12, 0.12, 0.4]) {
          decoration.fillStyle(0xb6f3ff, 0.72);
          decoration.fillCircle(width * point, point % 0.2 === 0 ? -height * 0.28 : height * 0.08, 3);
        }
      } else if (target.visualKind === "paper") {
        decoration.lineStyle(3, color, 0.58);
        for (let row = -1; row <= 1; row += 1) {
          decoration.lineBetween(-width * 0.4, row * 13, width * 0.28, row * 13 - 8);
          decoration.lineBetween(width * 0.28, row * 13 - 8, width * 0.4, row * 13 - 2);
        }
      } else if (target.visualKind === "elevator") {
        decoration.lineStyle(2, color, 0.62);
        decoration.lineBetween(-width * 0.18, -height * 0.42, -width * 0.18, height * 0.42);
        decoration.lineBetween(width * 0.18, -height * 0.42, width * 0.18, height * 0.42);
      }
      container.add([outline, decoration, marker]);
      this.tweens.add({
        targets: marker,
        alpha: { from: 0.48, to: 0.96 },
        duration: 760,
        yoyo: true,
        repeat: -1
      });
      this.targetVisuals.set(target.id, container);
    }
  }

  private createPartitionTarget(gate: LayoutDynamicGate): MazePartitionTarget {
    const centerX = (gate.bounds.left + gate.bounds.right) / 2;
    const centerY = (gate.bounds.top + gate.bounds.bottom) / 2;
    return {
      id: gate.id,
      label: gate.id === CHAPTER_FOUR_MAZE_IDS.partitions[0] ? "西侧可见隔断" : "东侧可见隔断",
      floor: gate.displayFloor,
      bounds: gate.bounds,
      x: centerX,
      y: centerY,
      width: gate.bounds.right - gate.bounds.left,
      height: gate.bounds.bottom - gate.bounds.top,
      stand: { x: centerX, y: gate.bounds.bottom + 44 },
      proximity: 64,
      requiredMode: "light",
      requiredFacing: "toward_target"
    };
  }

  private getVisiblePartitionTargets(): MazePartitionTarget[] {
    const visibleIds = new Set(this.projection.activePartitionIds);
    return LAYOUT.dynamicGates
      .filter((gate) => gate.kind === "partition" && visibleIds.has(gate.id))
      .map((gate) => this.createPartitionTarget(gate));
  }

  private refreshDynamicGates(): void {
    const revision = ++this.dynamicGateRevision;
    this.dynamicObstacles.clear(true, true);
    this.activeDynamicCollisionRects = [];
    for (const visual of this.dynamicGateVisuals.values()) {
      this.tweens.killTweensOf(visual);
      visual.destroy();
    }
    this.dynamicGateVisuals.clear();

    const visibleIds = new Set([
      ...this.projection.activeDoorIds,
      ...this.projection.activePartitionIds
    ]);
    const collisionIds = new Set(this.projection.activeCollisionIds);
    for (const gate of LAYOUT.dynamicGates) {
      if (!visibleIds.has(gate.id)) continue;
      const floor = getFloor(gate.displayFloor);
      const rect = {
        id: gate.collisionId,
        left: gate.bounds.left + floor.offsetX,
        top: gate.bounds.top,
        right: gate.bounds.right + floor.offsetX,
        bottom: gate.bounds.bottom
      };
      const visual = this.add.rectangle(
        (rect.left + rect.right) / 2,
        (rect.top + rect.bottom) / 2,
        rect.right - rect.left,
        rect.bottom - rect.top,
        gate.kind === "door" ? 0x8a725f : 0x5f8291,
        0.82
      ).setStrokeStyle(2, gate.kind === "door" ? 0xd6b88f : 0x9fd8e8, 0.96)
        .setDepth(3600);
      if (gate.kind === "partition") {
        visual
          .setInteractive({ useHandCursor: true })
          .on("pointerup", () => this.tryPartitionInteraction(this.createPartitionTarget(gate)));
      }
      this.dynamicGateVisuals.set(gate.id, visual);

      const closed = collisionIds.has(gate.collisionId)
        && gate.closedRouteStates.includes(this.projection.routeState);
      const closedScale = gate.kind === "door" ? { x: 1, y: 1 } : { x: 1, y: 1 };
      const openScale = gate.kind === "door" ? { x: 1, y: 0.12 } : { x: 0.12, y: 1 };
      if (!closed) {
        visual.setScale(openScale.x, openScale.y).setAlpha(0.34);
        continue;
      }

      visual.setScale(openScale.x, openScale.y).setAlpha(0.42);
      this.tweens.add({
        targets: visual,
        scaleX: closedScale.x,
        scaleY: closedScale.y,
        alpha: 0.82,
        duration: 180,
        ease: "Sine.Out",
        onComplete: () => {
          if (
            revision !== this.dynamicGateRevision
            || !this.projection.activeCollisionIds.includes(gate.collisionId)
          ) {
            return;
          }
          this.addDynamicCollision(rect);
        }
      });
    }
  }

  private addDynamicCollision(rect: MapCollisionRect): void {
    const showDebug = new URLSearchParams(window.location.search).get("debugColliders") === "1";
    const obstacle = this.add.rectangle(
      (rect.left + rect.right) / 2,
      (rect.top + rect.bottom) / 2,
      rect.right - rect.left,
      rect.bottom - rect.top,
      showDebug ? 0xffb52e : 0x000000,
      showDebug ? 0.28 : 0
    );
    this.physics.add.existing(obstacle, true);
    this.dynamicObstacles.add(obstacle);
    this.activeDynamicCollisionRects.push(rect);
  }

  private createLocationSignature(state: ReturnType<RpgBridge["getState"]>): string {
    return `${state.chapter4.floor}:${state.chapter4.roomId}:${state.rpgCheckpoint}`;
  }

  private markCurrentLocationApplied(): void {
    const state = this.bridge.getState();
    this.lastAppliedCheckpoint = state.rpgCheckpoint;
    this.lastAppliedLocationSignature = this.createLocationSignature(state);
  }

  private getCheckpointSpawn(
    floor: FloorDefinition,
    checkpoint: RpgCheckpointId
  ): LayoutPoint {
    if (checkpoint === "c4_a1_main_elevator" && floor.floor === 1) {
      return floor.elevatorStand;
    }
    return floor.safeSpawn;
  }

  private syncCurrentFloorFromState(): void {
    if (this.elevatorPhase !== "idle" || this.pendingMazeMove) return;
    const state = this.bridge.getState();
    const target = getDisplayFloor(state.chapter4.floor);
    if (!target) return;
    const signature = this.createLocationSignature(state);
    if (target === this.currentFloor && signature === this.lastAppliedLocationSignature) return;
    this.currentFloor = target;
    const floor = getFloor(target);
    const spawn = this.getCheckpointSpawn(floor, state.rpgCheckpoint);
    this.player.setPosition(
      floor.offsetX + spawn.x,
      spawn.y
    ).setVelocity(0, 0);
    this.animator.setFacing(spawn.facing);
    const body = this.player.body as Phaser.Physics.Arcade.Body;
    body.reset(this.player.x, this.player.y);
    this.lastAppliedCheckpoint = state.rpgCheckpoint;
    this.lastAppliedLocationSignature = signature;
    this.configureCameraForFloor();
    this.cameras.main.centerOn(this.player.x, this.player.y);
    this.syncProjection(true);
    this.refreshProximityState();
  }

  private createElevatorVisuals(): void {
    this.textures.get(ELEVATOR_DOORS_TEXTURE).setFilter(Phaser.Textures.FilterMode.NEAREST);
    for (const floor of FLOORS) {
      const centerX = floor.offsetX + ELEVATOR_LOCAL_CENTER_X;
      const door = this.add.sprite(
        centerX,
        ELEVATOR_DOOR_CENTER_Y,
        ELEVATOR_DOORS_TEXTURE,
        0
      ).setDepth(5002);
      const indicatorBack = this.add.rectangle(centerX, 45, 48, 21, 0x071018, 0.94)
        .setStrokeStyle(2, 0xb88f48, 1)
        .setDepth(5004);
      const indicatorText = this.add.text(centerX, 45, `${this.currentFloor}F`, {
        fontFamily: "'Fusion Pixel', 'Courier New', monospace",
        fontSize: "13px",
        color: "#ffd56f",
        align: "center"
      }).setOrigin(0.5).setDepth(5005);
      const callLamp = this.add.circle(centerX + 50, 111, 5, 0x55d9ff, 1)
        .setStrokeStyle(2, 0xd9f7ff, 1)
        .setDepth(5005)
        .setVisible(false);
      this.elevatorVisuals.set(floor.floor, {
        floor: floor.floor,
        centerX,
        door,
        indicatorBack,
        indicatorText,
        callLamp
      });
    }
    this.elevatorDisplayFloor = this.currentFloor;
    this.setElevatorIndicator(this.currentFloor, "idle");
  }

  private setElevatorIndicator(
    floor: DisplayFloor,
    direction: "up" | "down" | "idle"
  ): void {
    this.elevatorDisplayFloor = floor;
    const prefix = direction === "up" ? "▲" : direction === "down" ? "▼" : "";
    for (const visual of this.elevatorVisuals.values()) {
      visual.indicatorText.setText(`${prefix}${floor}F`);
      visual.indicatorBack.setStrokeStyle(2, direction === "idle" ? 0xb88f48 : 0x55d9ff, 1);
    }
  }

  private showElevatorDoors(floor: DisplayFloor, visible: boolean): void {
    const visual = this.elevatorVisuals.get(floor);
    if (!visual) return;
    visual.door.setVisible(visible);
    if (!visible) visual.callLamp.setVisible(false);
  }

  private setElevatorDoorProgress(floor: DisplayFloor, progress: number): void {
    const visual = this.elevatorVisuals.get(floor);
    if (!visual) return;
    const clamped = Phaser.Math.Clamp(progress, 0, 1);
    this.elevatorDoorProgress = clamped;
    visual.door.setFrame(Math.round(clamped * (ELEVATOR_DOOR_FRAME_COUNT - 1)));
  }

  private tweenElevatorDoors(
    floor: DisplayFloor,
    from: number,
    to: number,
    onComplete: () => void
  ): void {
    this.setElevatorDoorProgress(floor, from);
    this.tweens.addCounter({
      from,
      to,
      duration: ELEVATOR_DOOR_MS,
      ease: "Sine.InOut",
      onUpdate: (tween) => this.setElevatorDoorProgress(floor, tween.getValue() ?? to),
      onComplete
    });
  }

  private refreshProximityState(): void {
    const floor = getFloor(this.currentFloor);
    const localPoint = { x: this.player.x - floor.offsetX, y: this.player.y };
    const state = this.bridge.getState().chapter4;
    this.nearbyTravelZone = createTravelZones(floor)
      .map((zone) => ({
        zone,
        distance: distanceFromPlayerToRpgTarget(zone, localPoint.x, localPoint.y)
      }))
      .filter((candidate) => candidate.distance <= 54)
      .sort((a, b) => a.distance - b.distance)[0]?.zone ?? null;
    this.nearbyTarget = this.getActiveInteractionTargets()
      .filter((target) => target.floor === this.currentFloor)
      .map((target) => ({
        target,
        distance: distanceFromPlayerToRpgTarget(target, localPoint.x, localPoint.y)
      }))
      .filter((candidate) => candidate.distance <= candidate.target.proximity)
      .sort((a, b) => a.distance - b.distance)[0]?.target ?? null;
    this.nearbyPartitionId = this.getVisiblePartitionTargets()
      .filter((target) => target.floor === this.currentFloor)
      .map((target) => ({
        target,
        distance: distanceFromPlayerToRpgTarget(target, localPoint.x, localPoint.y)
      }))
      .filter((candidate) => candidate.distance <= candidate.target.proximity)
      .sort((a, b) => a.distance - b.distance)[0]?.target.id ?? null;
    this.nearbyAnchor = STORY_ANCHORS
      .filter((anchor) => anchor.floor === this.currentFloor)
      .map((anchor) => ({ anchor, distance: distanceToBounds(localPoint, anchor.bounds) }))
      .filter((candidate) => candidate.distance <= 72)
      .sort((a, b) => a.distance - b.distance)[0]?.anchor ?? null;

    const floorLabel = floor.shortTitle;
    this.floorCaption.setText(this.nearbyAnchor ? `${floorLabel} · ${this.nearbyAnchor.label}` : floorLabel);
    if (this.nearbyTarget) {
      const target = this.nearbyTarget;
      const storyReady = this.isTargetStoryReady(target);
      const modeReady = state.mode === target.requiredMode;
      const facingReady = isPlayerFacingRpgTarget(
        target,
        localPoint.x,
        localPoint.y,
        this.animator.cardinalFacing
      );
      const hint = this.pendingMazeAction
        ? `正在确认 · ${target.label}`
        : !storyReady
          ? `当前步骤尚未开放 · ${target.label}`
          : !modeReady
            ? `切到${target.requiredMode === "dark" ? "深色观察" : "浅色操作"} · ${target.label}`
            : !facingReady
              ? `面向${target.label}后再交互`
              : `Space / 交互 · ${this.getTargetActionLabel(target)}`;
      this.interactionHint.setText(hint).setVisible(true);
      return;
    }

    const nearbyPartition = this.nearbyPartitionId
      ? this.getVisiblePartitionTargets().find((target) => target.id === this.nearbyPartitionId) ?? null
      : null;
    if (nearbyPartition) {
      const storyReady = this.isPartitionStoryReady(nearbyPartition);
      const modeReady = state.mode === nearbyPartition.requiredMode;
      const facingReady = isPlayerFacingRpgTarget(
        nearbyPartition,
        localPoint.x,
        localPoint.y,
        this.animator.cardinalFacing
      );
      const hint = this.pendingMazeAction
        ? `正在确认 · ${nearbyPartition.label}`
        : !this.projection.activeCollisionIds.includes(nearbyPartition.id)
          ? `${nearbyPartition.label}已移开`
          : !storyReady
            ? `先记录人员残影 · ${nearbyPartition.label}`
            : !modeReady
              ? `切到浅色操作 · ${nearbyPartition.label}`
              : !facingReady
                ? `面向${nearbyPartition.label}后再交互`
                : `Space / 交互 · 移动${nearbyPartition.label}`;
      this.interactionHint.setText(hint).setVisible(true);
      return;
    }

    if (!this.nearbyTravelZone) {
      this.interactionHint.setVisible(false);
      return;
    }
    const facingCorrect = isPlayerFacingRpgTarget(
      this.nearbyTravelZone,
      localPoint.x,
      localPoint.y,
      this.animator.cardinalFacing
    );
    const travelReady = this.isTravelZoneStoryReady(this.nearbyTravelZone);
    const action = this.nearbyTravelZone.id === "elevator"
      ? "呼叫"
      : this.nearbyTravelZone.id === "stair_up"
        ? "上楼"
        : "下楼";
    this.interactionHint
      .setText(this.pendingMazeAction || this.pendingMazeMove
        ? "交互状态正在确认"
        : !travelReady
          ? `当前楼层通道尚未开放 · ${this.nearbyTravelZone.label}`
          : facingCorrect
            ? `Space / 交互 · ${this.nearbyTravelZone.label}${action}`
            : `面向${this.nearbyTravelZone.label}后再交互`)
      .setVisible(true);
  }

  private getTargetActionLabel(target: MazeInteractionTarget): string {
    if (target.action === "observe_airflow") return "读取断续水迹";
    if (target.action === "guide_paper") return "接续暖风路径";
    if (target.action === "inspect_elevator") {
      return target.requiredMode === "light" ? "打开历史重放" : "读取历史轨道";
    }
    if (target.action === "board_elevator") return "进入已对齐电梯";
    if (target.action === "observe_npc_schedule") return "记录人员时刻";
    if (target.action === "collect_wayfinding_fragment") return "拾取导视碎片";
    if (target.action === "observe_old_signage") return "读取旧导视残影";
    if (target.action === "open_wayfinding_board") return "打开导视板";
    if (target.action === "observe_bridge_history") return "读取连廊历史";
    if (target.action === "open_second_floor_return_window") return "检查返程取证窗口";
    return target.label;
  }

  private isTargetStoryReady(target: MazeInteractionTarget): boolean {
    const state = this.bridge.getState().chapter4;
    const active = this.getActiveInteractionTargets().some((candidate) => candidate.id === target.id);
    if (!active) return false;
    if (getDisplayFloor(state.floor) !== target.floor) return false;
    if (target.action === "observe_airflow") {
      return (state.phase === "arrival" || state.phase === "airflow_overlay")
        && !state.airflowObserved;
    }
    if (target.action === "guide_paper") {
      return state.phase === "airflow_overlay"
        && state.airflowObserved
        && !state.paperGuidedToElevator;
    }
    if (target.action === "inspect_elevator") {
      return state.phase === "elevator_track_sync"
        && state.paperGuidedToElevator
        && !state.elevatorPlayerBoarded;
    }
    if (target.action === "board_elevator") {
      return state.phase === "elevator_track_sync"
        && state.elevatorTrackAligned
        && !state.elevatorPlayerBoarded
        && this.historicalDoorOpen;
    }
    if (target.action === "observe_npc_schedule") return state.phase === "npc_schedule_route";
    if (target.action === "collect_wayfinding_fragment") {
      return state.phase === "wayfinding_fragment_board"
        && state.solvedPuzzleIds.includes("corridor_bay_reconstruction");
    }
    if (target.action === "observe_old_signage") {
      return state.phase === "wayfinding_fragment_board"
        && state.clueIds.includes(CHAPTER_FOUR_MAZE_CLUES.fragmentWestCollected)
        && state.clueIds.includes(CHAPTER_FOUR_MAZE_CLUES.fragmentEastCollected);
    }
    if (target.action === "open_wayfinding_board") {
      return state.phase === "wayfinding_fragment_board"
        && state.clueIds.includes(CHAPTER_FOUR_MAZE_CLUES.oldSignageObserved);
    }
    if (target.action === "observe_bridge_history") {
      return state.phase === "bridge_floor_discrimination"
        && state.solvedPuzzleIds.includes("wayfinding_fragment_board");
    }
    if (target.action === "open_second_floor_return_window") {
      return state.phase === "bridge_floor_discrimination"
        && state.clueIds.includes(CHAPTER_FOUR_MAZE_CLUES.bridgeHistoryObserved);
    }
    return false;
  }

  private isPartitionStoryReady(target: MazePartitionTarget): boolean {
    const state = this.bridge.getState().chapter4;
    return getDisplayFloor(state.floor) === target.floor
      && state.phase === "corridor_bay_reconstruction"
      && (
        state.clueIds.includes(CHAPTER_FOUR_MAZE_CLUES.scheduleObserved)
        || state.solvedPuzzleIds.includes("npc_schedule_route")
      )
      && this.projection.activeCollisionIds.includes(target.id);
  }

  private isTravelZoneStoryReady(zone: TravelZone): boolean {
    if (zone.id === "elevator") {
      return FLOORS.some((floor) => (
        floor.floor !== this.currentFloor
        && this.isMazeTravelAllowed(floor.storyFloor, "elevator")
      ));
    }
    return zone.targetStoryFloor
      ? this.isMazeTravelAllowed(zone.targetStoryFloor, "stair")
      : false;
  }

  private isMazeTravelAllowed(targetFloor: StoryFloor, route: MazeMoveRoute): boolean {
    const chapter = this.bridge.getState().chapter4;
    const currentFloor = chapter.floor;
    if (currentFloor !== "A1" && currentFloor !== "A2" && currentFloor !== "A3") return false;
    if (targetFloor === currentFloor) return false;
    if (!chapter.solvedPuzzleIds.includes("elevator_track_sync")) return false;
    const targetNumber = Number(targetFloor.slice(1));
    const currentNumber = Number(currentFloor.slice(1));
    if (route === "stair" && Math.abs(targetNumber - currentNumber) !== 1) return false;

    const crossesUpperPair = (
      (currentFloor === "A2" && targetFloor === "A3")
      || (currentFloor === "A3" && targetFloor === "A2")
    );
    const returnWindowOpen = chapter.clueIds.includes(
      CHAPTER_FOUR_MAZE_CLUES.secondFloorReturnWindowOpen
    ) || chapter.solvedPuzzleIds.includes("bridge_floor_discrimination");
    if (crossesUpperPair && !returnWindowOpen && route !== "stair") return false;
    const hasBothFragments = chapter.clueIds.includes(CHAPTER_FOUR_MAZE_CLUES.fragmentWestCollected)
      && chapter.clueIds.includes(CHAPTER_FOUR_MAZE_CLUES.fragmentEastCollected);
    if (
      targetFloor === "A3"
      && !hasBothFragments
      && !chapter.solvedPuzzleIds.includes("wayfinding_fragment_board")
    ) {
      return false;
    }
    if (
      currentFloor === "A3"
      && targetFloor === "A2"
      && !chapter.clueIds.includes(CHAPTER_FOUR_MAZE_CLUES.bridgeHistoryObserved)
    ) {
      return false;
    }
    if (
      (currentFloor === "A1" && targetFloor === "A3")
      || (currentFloor === "A3" && targetFloor === "A1")
    ) {
      return route === "elevator" && returnWindowOpen;
    }
    return true;
  }

  private handleInteraction(): void {
    if (this.pendingMazeAction) {
      this.emitInteractionFeedback("当前交互正在确认。");
      return;
    }
    if (this.nearbyTarget) {
      this.tryTargetInteraction(this.nearbyTarget);
      return;
    }
    if (this.nearbyPartitionId) {
      const partition = this.getVisiblePartitionTargets()
        .find((target) => target.id === this.nearbyPartitionId);
      if (partition) {
        this.tryPartitionInteraction(partition);
        return;
      }
    }
    this.handleTravelInteraction();
  }

  private tryTargetInteraction(target: MazeInteractionTarget): void {
    const activeTarget = this.getActiveInteractionTargets()
      .some((candidate) => candidate.id === target.id);
    if (
      target.floor !== this.currentFloor
      || !activeTarget
    ) {
      this.emitInteractionFeedback("该交互点当前未开放。");
      return;
    }
    const floor = getFloor(this.currentFloor);
    const localX = this.player.x - floor.offsetX;
    const localY = this.player.y;
    if (distanceFromPlayerToRpgTarget(target, localX, localY) > target.proximity) {
      this.emitInteractionFeedback(`距离${target.label}太远，请靠近可见目标。`);
      return;
    }
    if (
      isA1TargetAction(target.action)
      && this.bridge.getState().chapter4.mode !== target.requiredMode
    ) {
      this.emitInteractionFeedback(
        `切到${target.requiredMode === "dark" ? "深色观察" : "浅色操作"}后再操作${target.label}。`
      );
      return;
    }
    if (!isPlayerFacingRpgTarget(target, localX, localY, this.animator.cardinalFacing)) {
      this.emitInteractionFeedback(`请先面向${target.label}。`);
      return;
    }
    if (target.action === "open_wayfinding_board") {
      this.requestWayfindingPanel(target);
      return;
    }
    if (isA1TargetAction(target.action)) {
      this.requestChapterFourAction(target.action, target.id);
      return;
    }
    const extras = target.action === "collect_wayfinding_fragment"
      ? { fragmentId: target.id }
      : undefined;
    this.requestMazeAction(target.action, target.id, extras);
  }

  private tryPartitionInteraction(target: MazePartitionTarget): void {
    if (
      target.floor !== this.currentFloor
      || !this.projection.activePartitionIds.includes(target.id)
    ) {
      this.emitInteractionFeedback("该隔断当前未开放。");
      return;
    }
    const floor = getFloor(this.currentFloor);
    const localX = this.player.x - floor.offsetX;
    const localY = this.player.y;
    if (distanceFromPlayerToRpgTarget(target, localX, localY) > target.proximity) {
      this.emitInteractionFeedback(`距离${target.label}太远，请靠近隔断边缘。`);
      return;
    }
    if (!isPlayerFacingRpgTarget(target, localX, localY, this.animator.cardinalFacing)) {
      this.emitInteractionFeedback(`请先面向${target.label}。`);
      return;
    }
    this.requestMazeAction(
      "reconfigure_corridor_bay",
      target.id,
      { partitionId: target.id }
    );
  }

  private requestWayfindingPanel(target: MazeInteractionTarget): void {
    if (this.pendingMazeAction) return;
    const requestId = `c4-panel-${++this.mazeActionRequestSerial}`;
    this.pendingMazeAction = {
      requestId,
      action: "open_wayfinding_board",
      targetId: target.id
    };
    this.armMazeActionTimeout(requestId);
    this.bridge.emit("chapter4_wayfinding_panel_requested", {
      requestId,
      action: "open_wayfinding_board",
      targetId: target.id
    });
  }

  private requestMazeAction(
    action: MazeAction,
    targetId: string,
    extras: { partitionId?: string; fragmentId?: string; order?: readonly string[] } = {}
  ): void {
    if (this.pendingMazeAction) return;
    const requestId = `c4-action-${++this.mazeActionRequestSerial}`;
    this.pendingMazeAction = { requestId, action, targetId, ...extras };
    this.armMazeActionTimeout(requestId);
    this.bridge.emit("chapter4_maze_action_requested", {
      requestId,
      action,
      targetId,
      ...extras,
      ...(extras.order ? { order: [...extras.order] } : {})
    });
  }

  private requestChapterFourAction(action: A1Action, targetId: string): void {
    if (this.pendingMazeAction) return;
    const requestId = `c4-a1-${++this.mazeActionRequestSerial}`;
    this.pendingMazeAction = { requestId, action, targetId };
    this.pendingMazeActionTimer?.remove(false);
    if (this.elevatorPhase === "idle") this.refreshProximityState();
    this.bridge.emit("rpg_chapter4_action_requested", {
      requestId,
      action,
      targetId
    });
    this.pendingMazeActionTimer = this.time.delayedCall(0, () => {
      if (this.pendingMazeAction?.requestId !== requestId) return;
      this.pendingMazeAction = null;
      this.pendingMazeActionTimer = null;
      this.syncProjection(true);
      this.syncCurrentFloorFromState();
      if (this.elevatorPhase === "idle") this.refreshProximityState();
    });
  }

  private beginHistoricalElevatorEntryWindow(entryWindowSeconds: number): void {
    const state = this.bridge.getState().chapter4;
    if (
      state.floor !== "A1"
      || state.phase !== "elevator_track_sync"
      || !state.elevatorTrackAligned
      || state.elevatorPlayerBoarded
      || this.historicalRideInProgress
    ) {
      return;
    }
    this.historicalEntryTimer?.remove(false);
    this.historicalEntryTimer = null;
    this.historicalEntryWindowEndsAt = 0;
    this.historicalDoorOpen = false;
    this.elevatorPhase = "doors_opening";
    this.player.setVelocity(0, 0);
    this.virtualDirection = { x: 0, y: 0 };
    this.nearbyTarget = null;
    this.interactionHint.setVisible(false);
    this.showElevatorDoors(1, true);
    this.syncProjection(true);
    this.tweenElevatorDoors(1, 0, 1, () => {
      const current = this.bridge.getState().chapter4;
      if (
        current.floor !== "A1"
        || current.phase !== "elevator_track_sync"
        || !current.elevatorTrackAligned
        || current.elevatorPlayerBoarded
      ) {
        this.elevatorPhase = "idle";
        this.historicalDoorOpen = false;
        this.setElevatorDoorProgress(1, 0);
        this.syncCurrentFloorFromState();
        return;
      }
      this.elevatorPhase = "idle";
      this.historicalDoorOpen = true;
      const windowMs = Math.max(1, entryWindowSeconds) * 1000;
      this.historicalEntryWindowEndsAt = this.time.now + windowMs;
      this.historicalEntryTimer = this.time.delayedCall(windowMs, () => {
        this.expireHistoricalElevatorEntryWindow();
      });
      this.syncProjection(true);
      this.refreshProximityState();
    });
  }

  private expireHistoricalElevatorEntryWindow(): void {
    this.historicalEntryTimer = null;
    this.historicalEntryWindowEndsAt = 0;
    const state = this.bridge.getState().chapter4;
    if (
      !this.historicalDoorOpen
      || this.historicalRideInProgress
      || state.floor !== "A1"
      || state.phase !== "elevator_track_sync"
      || state.elevatorPlayerBoarded
    ) {
      return;
    }
    this.historicalDoorOpen = false;
    this.elevatorPhase = "doors_closing";
    this.nearbyTarget = null;
    this.interactionHint.setVisible(false);
    this.syncProjection(true);
    this.requestChapterFourAction("elevator_replay_missed", A1_TARGET_IDS.elevatorInspect);
    this.tweenElevatorDoors(1, 1, 0, () => {
      this.elevatorPhase = "idle";
      this.syncProjection(true);
      this.refreshProximityState();
    });
  }

  private beginHistoricalElevatorBoarding(): void {
    const state = this.bridge.getState().chapter4;
    if (
      this.historicalRideInProgress
      || !this.historicalDoorOpen
      || state.floor !== "A1"
      || state.phase !== "elevator_track_sync"
      || !state.elevatorTrackAligned
      || !state.elevatorPlayerBoarded
    ) {
      return;
    }
    this.historicalRideInProgress = true;
    this.historicalDoorOpen = false;
    this.historicalEntryTimer?.remove(false);
    this.historicalEntryTimer = null;
    this.historicalEntryWindowEndsAt = 0;
    this.elevatorRideFromFloor = 1;
    this.elevatorTargetFloor = 2;
    this.elevatorPhase = "boarding";
    this.player.setVelocity(0, 0);
    this.virtualDirection = { x: 0, y: 0 };
    this.interactionHint.setVisible(false);
    this.syncProjection(true);

    const floor = getFloor(1);
    const body = this.player.body as Phaser.Physics.Arcade.Body;
    body.enable = false;
    this.animator.setFacing("up");
    this.player.setDepth(5001);
    this.tweens.add({
      targets: this.player,
      x: floor.offsetX + floor.elevatorStand.x,
      y: ELEVATOR_INSIDE_Y,
      duration: ELEVATOR_BOARD_MS,
      ease: "Sine.InOut",
      onComplete: () => {
        this.elevatorPhase = "doors_closing";
        this.tweenElevatorDoors(1, 1, 0, () => this.beginHistoricalElevatorTravel());
      }
    });
  }

  private beginHistoricalElevatorTravel(): void {
    if (!this.historicalRideInProgress) return;
    this.elevatorPhase = "traveling";
    this.player.setVisible(false);
    this.setElevatorIndicator(1, "up");
    this.elevatorWaitEndsAt = this.time.now + HISTORICAL_ELEVATOR_RIDE_MS;
    this.time.delayedCall(Math.floor(HISTORICAL_ELEVATOR_RIDE_MS / 2), () => {
      if (this.historicalRideInProgress) this.setElevatorIndicator(2, "up");
    });
    this.time.delayedCall(HISTORICAL_ELEVATOR_RIDE_MS, () => {
      if (!this.historicalRideInProgress) return;
      this.requestChapterFourAction("complete_elevator_ride", A1_TARGET_IDS.elevatorBoard);
      this.time.delayedCall(0, () => {
        const state = this.bridge.getState().chapter4;
        if (state.floor === "A2" && state.phase === "npc_schedule_route") return;
        this.recoverHistoricalElevatorAtA1();
      });
    });
  }

  private finishHistoricalElevatorTravel(): void {
    const state = this.bridge.getState().chapter4;
    if (
      !this.historicalRideInProgress
      || state.floor !== "A2"
      || state.phase !== "npc_schedule_route"
      || this.currentFloor !== 1
    ) {
      return;
    }
    this.historicalRideInProgress = false;
    this.historicalDoorOpen = false;
    this.historicalEntryWindowEndsAt = 0;
    this.elevatorWaitEndsAt = 0;
    this.arriveAtElevatorDestination(1, 2);
  }

  private recoverHistoricalElevatorAtA1(): void {
    if (!this.historicalRideInProgress) return;
    this.historicalRideInProgress = false;
    this.historicalDoorOpen = false;
    this.historicalEntryWindowEndsAt = 0;
    this.elevatorWaitEndsAt = 0;
    this.elevatorTargetFloor = null;
    this.elevatorPhase = "idle";
    this.player.setVisible(true);
    const floor = getFloor(1);
    this.player.setPosition(floor.offsetX + floor.elevatorStand.x, floor.elevatorStand.y);
    const body = this.player.body as Phaser.Physics.Arcade.Body;
    body.enable = true;
    body.reset(this.player.x, this.player.y);
    this.animator.setFacing("up");
    this.setElevatorDoorProgress(1, 0);
    this.syncProjection(true);
    this.refreshProximityState();
  }

  private armMazeActionTimeout(requestId: string): void {
    this.pendingMazeActionTimer?.remove(false);
    this.pendingMazeActionTimer = this.time.delayedCall(1600, () => {
      if (this.pendingMazeAction?.requestId !== requestId) return;
      this.pendingMazeAction = null;
      this.pendingMazeActionTimer = null;
      this.emitInteractionFeedback("交互状态未确认，请重试。");
      this.refreshProximityState();
    });
  }

  private clearPendingMazeAction(requestId: string): boolean {
    if (this.pendingMazeAction?.requestId !== requestId) return false;
    this.pendingMazeActionTimer?.remove(false);
    this.pendingMazeActionTimer = null;
    this.pendingMazeAction = null;
    return true;
  }

  private handleMazeActionResolved(payload?: Record<string, unknown>): void {
    const requestId = String(payload?.requestId ?? "");
    if (!this.clearPendingMazeAction(requestId)) return;
    this.syncProjection(true);
    this.refreshProximityState();
  }

  private handleWayfindingPanelResolved(payload?: Record<string, unknown>): void {
    const requestId = String(payload?.requestId ?? "");
    if (!this.clearPendingMazeAction(requestId)) return;
    this.syncProjection(true);
    this.refreshProximityState();
  }

  private emitInteractionFeedback(message: string): void {
    this.bridge.emit("rpg_subtitle", {
      text: message,
      tone: "system",
      durationMs: 3000
    });
  }

  private handleTravelInteraction(): void {
    if (this.pendingMazeMove) {
      this.showFeedback("楼层状态正在确认");
      return;
    }
    if (!this.nearbyTravelZone) {
      this.showFeedback("附近没有可用的楼层通道");
      return;
    }
    if (!this.isTravelZoneStoryReady(this.nearbyTravelZone)) {
      this.showFeedback("当前证据尚未开放这条楼层通道");
      return;
    }
    const floor = getFloor(this.currentFloor);
    const localPoint = { x: this.player.x - floor.offsetX, y: this.player.y };
    if (!isPlayerFacingRpgTarget(
      this.nearbyTravelZone,
      localPoint.x,
      localPoint.y,
      this.animator.cardinalFacing
    )) {
      this.showFeedback(`请先面向${this.nearbyTravelZone.label}`);
      return;
    }
    if (this.nearbyTravelZone.id === "elevator") {
      this.callElevator();
      return;
    }
    const targetFloor = this.nearbyTravelZone.targetStoryFloor
      ? getDisplayFloor(this.nearbyTravelZone.targetStoryFloor)
      : null;
    if (!targetFloor) {
      this.showFeedback("该楼梯落点未通过布局校验");
      return;
    }
    this.requestMazeMove(targetFloor, "stair");
  }

  private callElevator(): void {
    if (this.elevatorPhase !== "idle") return;
    this.elevatorPhase = "waiting";
    this.elevatorTargetFloor = null;
    this.elevatorRideFromFloor = this.currentFloor;
    this.elevatorDoorProgress = 0;
    this.virtualDirection = { x: 0, y: 0 };
    this.player.setVelocity(0, 0);
    this.interactionHint.setVisible(false);

    const visual = this.elevatorVisuals.get(this.currentFloor);
    visual?.callLamp.setFillStyle(0x55d9ff, 1).setVisible(true);
    const startFloor: DisplayFloor = this.currentFloor === 1 ? 3 : 1;
    const floors = this.getElevatorFloorPath(startFloor, this.currentFloor);
    const direction = startFloor < this.currentFloor ? "up" : "down";
    this.elevatorWaitEndsAt = this.time.now + Math.max(1, floors.length) * ELEVATOR_WAIT_STEP_MS + ELEVATOR_ARRIVAL_MS;
    this.setElevatorIndicator(floors[0], direction);
    floors.slice(1).forEach((floor, index) => {
      this.time.delayedCall((index + 1) * ELEVATOR_WAIT_STEP_MS, () => {
        this.setElevatorIndicator(floor, direction);
      });
    });
    this.time.delayedCall(floors.length * ELEVATOR_WAIT_STEP_MS, () => {
      this.beginElevatorArrival();
    });
  }

  private getElevatorFloorPath(from: DisplayFloor, to: DisplayFloor): DisplayFloor[] {
    const step = from < to ? 1 : -1;
    const path: DisplayFloor[] = [from];
    for (let floor = from + step; step > 0 ? floor <= to : floor >= to; floor += step) {
      path.push(floor as DisplayFloor);
    }
    return path;
  }

  private beginElevatorArrival(): void {
    this.elevatorPhase = "arriving";
    this.elevatorWaitEndsAt = this.time.now + ELEVATOR_ARRIVAL_MS;
    this.setElevatorIndicator(this.currentFloor, "idle");
    const visual = this.elevatorVisuals.get(this.currentFloor);
    visual?.callLamp.setFillStyle(0x8dffb0, 1);
    if (visual) {
      this.tweens.add({
        targets: [visual.indicatorBack, visual.callLamp],
        alpha: 0.35,
        duration: 105,
        yoyo: true,
        repeat: 1
      });
    }
    this.cameras.main.shake(90, 0.0015);
    this.time.delayedCall(ELEVATOR_ARRIVAL_MS, () => this.openElevatorForBoarding());
  }

  private openElevatorForBoarding(): void {
    this.elevatorPhase = "doors_opening";
    this.elevatorWaitEndsAt = 0;
    this.showElevatorDoors(this.currentFloor, true);
    this.tweenElevatorDoors(this.currentFloor, 0, 1, () => this.boardElevator());
  }

  private boardElevator(): void {
    this.elevatorPhase = "boarding";
    const floor = getFloor(this.currentFloor);
    const body = this.player.body as Phaser.Physics.Arcade.Body;
    body.enable = false;
    this.animator.setFacing("up");
    this.player.setDepth(5001);
    this.tweens.add({
      targets: this.player,
      x: floor.offsetX + floor.elevatorStand.x,
      y: ELEVATOR_INSIDE_Y,
      duration: ELEVATOR_BOARD_MS,
      ease: "Sine.InOut",
      onComplete: () => {
        this.elevatorPhase = "selecting";
        this.openFloorPanel();
      }
    });
  }

  private openFloorPanel(): void {
    if (this.floorPanel) return;
    this.floorPanelSelection = this.currentFloor;
    this.floorPanelButtons = [];
    const panel = this.add.container(874, 270).setScrollFactor(0).setDepth(12000);
    const background = this.add.rectangle(0, 0, 132, 260, 0x27343a, 0.98)
      .setStrokeStyle(3, 0xaebdc1, 1);
    const title = this.add.text(0, -106, "轿厢", {
      fontFamily: "'Fusion Pixel', 'Courier New', monospace",
      fontSize: "17px",
      color: "#f7f1dc"
    }).setOrigin(0.5);
    const display = this.add.text(0, -76, `${this.currentFloor}F`, {
      fontFamily: "'Fusion Pixel', 'Courier New', monospace",
      fontSize: "18px",
      color: "#ffd56f",
      backgroundColor: "#071018",
      padding: { x: 18, y: 5 }
    }).setOrigin(0.5);
    panel.add([background, title, display]);

    ([1, 2, 3] as const).forEach((floor, index) => {
      const y = -25 + index * 55;
      const button = this.add.rectangle(0, y, 82, 42, 0x18364a, 1)
        .setStrokeStyle(2, 0x5f9bb1, 1)
        .setInteractive({ useHandCursor: true })
        .on("pointerup", () => {
          this.setFloorPanelSelection(floor);
          this.requestElevatorDestination(floor);
        });
      const label = this.add.text(0, y, `${floor}F`, {
        fontFamily: "'Fusion Pixel', 'Courier New', monospace",
        fontSize: "20px",
        color: "#f7f1dc"
      }).setOrigin(0.5);
      this.floorPanelButtons.push({ floor, button, label });
      panel.add([button, label]);
    });
    const controls = this.add.text(0, 112, "↑ ↓  Enter", {
      fontFamily: "'Fusion Pixel', 'Courier New', monospace",
      fontSize: "11px",
      color: "#c8d5d8"
    }).setOrigin(0.5);
    panel.add(controls);
    this.floorPanel = panel;
    this.setFloorPanelSelection(this.floorPanelSelection);
    this.interactionHint.setVisible(false);
  }

  private setFloorPanelSelection(floor: DisplayFloor): void {
    this.floorPanelSelection = floor;
    for (const entry of this.floorPanelButtons) {
      const selected = entry.floor === floor;
      const current = entry.floor === this.currentFloor;
      entry.button
        .setFillStyle(selected ? 0xb38a42 : current ? 0x314047 : 0x18364a, 1)
        .setStrokeStyle(2, selected ? 0xffe6a6 : current ? 0x71858c : 0x5f9bb1, 1);
      entry.label.setColor(selected ? "#20170b" : current ? "#9fb0b5" : "#f7f1dc");
    }
  }

  private closeFloorPanel(): void {
    this.floorPanel?.destroy(true);
    this.floorPanel = null;
    this.floorPanelButtons = [];
    if (this.elevatorPhase === "idle") this.refreshProximityState();
  }

  private requestElevatorDestination(target: DisplayFloor): void {
    if (this.elevatorPhase !== "selecting" || !this.floorPanel) return;
    if (this.pendingMazeMove) return;
    if (target === this.currentFloor) {
      this.setFloorPanelSelection(target);
      this.showFeedback(`当前已在 ${target}F`);
      return;
    }
    this.elevatorTargetFloor = target;
    this.requestMazeMove(target, "elevator");
  }

  private cancelElevatorRide(): void {
    if (this.elevatorPhase !== "selecting" || this.pendingMazeMove) return;
    this.closeFloorPanel();
    this.elevatorTargetFloor = null;
    this.beginElevatorExit();
  }

  private beginElevatorTravel(target: DisplayFloor): void {
    const fromFloor = this.currentFloor;
    this.elevatorPhase = "traveling";
    this.player.setVisible(false);
    const floors = this.getElevatorFloorPath(fromFloor, target);
    const direction = fromFloor < target ? "up" : "down";
    const travelFloors = floors.slice(1);
    this.setElevatorIndicator(fromFloor, direction);
    const duration = Math.max(1, travelFloors.length) * ELEVATOR_TRAVEL_STEP_MS;
    this.elevatorWaitEndsAt = this.time.now + duration;
    travelFloors.forEach((floor, index) => {
      this.time.delayedCall((index + 1) * ELEVATOR_TRAVEL_STEP_MS, () => {
        this.setElevatorIndicator(floor, direction);
      });
    });
    this.time.delayedCall(duration + 180, () => this.arriveAtElevatorDestination(fromFloor, target));
  }

  private arriveAtElevatorDestination(fromFloor: DisplayFloor, target: DisplayFloor): void {
    const previousVisual = this.elevatorVisuals.get(fromFloor);
    previousVisual?.callLamp.setVisible(false);
    this.showElevatorDoors(fromFloor, false);
    this.currentFloor = target;
    this.markCurrentLocationApplied();
    const floor = getFloor(target);
    this.player.setPosition(floor.offsetX + floor.elevatorStand.x, ELEVATOR_INSIDE_Y);
    this.configureCameraForFloor();
    this.cameras.main.centerOn(this.player.x, this.player.y);
    this.setElevatorIndicator(target, "idle");
    this.elevatorWaitEndsAt = 0;
    this.showElevatorDoors(target, true);
    this.setElevatorDoorProgress(target, 0);
    const destinationVisual = this.elevatorVisuals.get(target);
    destinationVisual?.callLamp.setFillStyle(0x8dffb0, 1).setVisible(true);
    this.elevatorPhase = "destination_opening";
    this.tweenElevatorDoors(target, 0, 1, () => this.beginElevatorExit());
  }

  private beginElevatorExit(): void {
    this.elevatorPhase = "exiting";
    const floor = getFloor(this.currentFloor);
    this.player.setVisible(true).setDepth(5001);
    this.animator.setFacing("down");
    this.tweens.add({
      targets: this.player,
      x: floor.offsetX + floor.elevatorStand.x,
      y: floor.elevatorStand.y,
      duration: ELEVATOR_BOARD_MS,
      ease: "Sine.InOut",
      onComplete: () => this.finishElevatorExit()
    });
  }

  private finishElevatorExit(): void {
    const body = this.player.body as Phaser.Physics.Arcade.Body;
    body.enable = true;
    body.reset(this.player.x, this.player.y);
    this.player.setDepth(this.player.y + 4000);
    this.elevatorPhase = "destination_closing";
    const changedFloor = this.currentFloor !== this.elevatorRideFromFloor;
    if (changedFloor) {
      this.showFeedback(`电梯已到 ${this.currentFloor}F`);
    }
    this.tweenElevatorDoors(this.currentFloor, 1, 0, () => {
      this.showElevatorDoors(this.currentFloor, true);
      const visual = this.elevatorVisuals.get(this.currentFloor);
      visual?.callLamp.setVisible(false);
      this.elevatorPhase = "idle";
      this.elevatorTargetFloor = null;
      this.elevatorDoorProgress = 0;
      this.elevatorWaitEndsAt = 0;
      this.refreshProximityState();
    });
  }

  private requestMazeMove(target: DisplayFloor, route: MazeMoveRoute): void {
    if (target === this.currentFloor) {
      this.showFeedback(`当前已在 ${target}F`);
      return;
    }
    if (this.pendingMazeMove) return;
    const floor = getFloor(target);
    const requestId = `c4-maze-${++this.mazeMoveRequestSerial}`;
    this.pendingMazeMove = {
      requestId,
      fromFloor: this.currentFloor,
      targetFloor: target,
      route
    };
    this.pendingMazeMoveTimer?.remove(false);
    this.pendingMazeMoveTimer = this.time.delayedCall(1600, () => {
      if (this.pendingMazeMove?.requestId !== requestId) return;
      this.pendingMazeMove = null;
      this.pendingMazeMoveTimer = null;
      if (route === "elevator") this.elevatorTargetFloor = null;
      this.showFeedback("楼层状态未确认，请重试");
    });
    this.bridge.emit("chapter4_maze_move_requested", {
      requestId,
      floor: floor.storyFloor,
      roomId: floor.roomId,
      checkpoint: floor.checkpoint,
      route
    });
  }

  private handleMazeMoveResolved(payload?: Record<string, unknown>): void {
    const pending = this.pendingMazeMove;
    if (!pending || String(payload?.requestId ?? "") !== pending.requestId) return;
    const result = String(payload?.result ?? "locked") as MazeMoveResult;
    this.pendingMazeMoveTimer?.remove(false);
    this.pendingMazeMoveTimer = null;
    this.pendingMazeMove = null;

    if (result !== "accepted" && result !== "already_complete") {
      if (pending.route === "elevator") this.elevatorTargetFloor = null;
      const feedback: Record<MazeMoveResult, string> = {
        accepted: "楼层状态已确认。",
        already_complete: "楼层状态已同步。",
        misaligned: "楼层时间轨道未对齐。",
        wrong_mode: "切回浅色操作后再移动。",
        locked: "当前证据尚未开放这条楼层通道。",
        inactive: "第四章教学楼流程尚未开始。"
      };
      this.showFeedback(feedback[result] ?? feedback.locked);
      return;
    }

    if (pending.route === "elevator") {
      this.closeFloorPanel();
      this.elevatorPhase = "doors_closing";
      this.tweenElevatorDoors(
        pending.fromFloor,
        1,
        0,
        () => this.beginElevatorTravel(pending.targetFloor)
      );
      return;
    }
    this.commitStairTransfer(pending.fromFloor, pending.targetFloor);
  }

  private commitStairTransfer(fromFloor: DisplayFloor, target: DisplayFloor): void {
    this.currentFloor = target;
    this.markCurrentLocationApplied();
    const sourceFloor = getFloor(fromFloor);
    const floor = getFloor(target);
    const targetLanding = floor.stairLandings.find(
      (landing) => landing.targetStoryFloor === sourceFloor.storyFloor
    );
    const arrival = targetLanding?.arrivalPosition ?? floor.safeSpawn;
    this.player.setPosition(floor.offsetX + arrival.x, arrival.y).setVelocity(0, 0);
    this.animator.setFacing("down");
    this.configureCameraForFloor();
    this.cameras.main.centerOn(this.player.x, this.player.y);
    this.showFeedback(`楼梯已到 ${target}F`);
    this.syncProjection(true);
    this.refreshProximityState();
  }

  private showFeedback(message: string): void {
    this.feedbackTimer?.remove(false);
    this.feedbackText.setText(message).setVisible(true);
    this.feedbackTimer = this.time.delayedCall(1800, () => {
      this.feedbackText.setVisible(false);
      this.feedbackTimer = null;
    });
  }

  private publishDebug(): void {
    const state = this.bridge.getState().chapter4;
    const body = this.player.body as Phaser.Physics.Arcade.Body | undefined;
    const floor = getFloor(this.currentFloor);
    const anchorDebug = STORY_ANCHORS.map((anchor) => ({
      id: anchor.id,
      label: anchor.label,
      floor: anchor.floor,
      bounds: {
        left: anchor.bounds.left + getFloor(anchor.floor).offsetX,
        top: anchor.bounds.top,
        right: anchor.bounds.right + getFloor(anchor.floor).offsetX,
        bottom: anchor.bounds.bottom
      }
    }));
    const activeInteractionTargets = this.getActiveInteractionTargets();
    const partitionTargets = this.getVisiblePartitionTargets();
    const activeTargetDebug = [
      ...activeInteractionTargets.map((target) => {
        const targetFloor = getFloor(target.floor);
        return {
          id: target.id,
          label: target.label,
          x: targetFloor.offsetX + target.x,
          y: target.y,
          width: target.width ?? 0,
          height: target.height ?? 0,
          stand: {
            x: targetFloor.offsetX + target.stand.x,
            y: target.stand.y
          },
          proximity: target.proximity,
          requiredMode: target.requiredMode,
          requiredFacing: target.requiredFacing
        };
      }),
      ...partitionTargets.map((target) => {
        const targetFloor = getFloor(target.floor);
        return {
          id: target.id,
          label: target.label,
          x: targetFloor.offsetX + target.x,
          y: target.y,
          width: target.width ?? 0,
          height: target.height ?? 0,
          stand: {
            x: targetFloor.offsetX + target.stand.x,
            y: target.stand.y
          },
          proximity: target.proximity,
          requiredMode: target.requiredMode,
          requiredFacing: target.requiredFacing
        };
      })
    ];
    const targetBounds = [
      ...activeInteractionTargets.map((target) => {
        const targetFloor = getFloor(target.floor);
        return {
          id: target.id,
          label: target.label,
          floor: target.floor,
          kind: "anchor" as const,
          bounds: {
            left: target.bounds.left + targetFloor.offsetX,
            top: target.bounds.top,
            right: target.bounds.right + targetFloor.offsetX,
            bottom: target.bounds.bottom
          },
          stand: {
            x: target.stand.x + targetFloor.offsetX,
            y: target.stand.y
          },
          proximity: target.proximity,
          requiredMode: target.requiredMode,
          requiredFacing: target.requiredFacing
        };
      }),
      ...partitionTargets.map((target) => {
        const targetFloor = getFloor(target.floor);
        return {
          id: target.id,
          label: target.label,
          floor: target.floor,
          kind: "partition" as const,
          bounds: {
            left: target.bounds.left + targetFloor.offsetX,
            top: target.bounds.top,
            right: target.bounds.right + targetFloor.offsetX,
            bottom: target.bounds.bottom
          },
          stand: {
            x: target.stand.x + targetFloor.offsetX,
            y: target.stand.y
          },
          proximity: target.proximity,
          requiredMode: target.requiredMode,
          requiredFacing: target.requiredFacing
        };
      })
    ];
    const npcFrames = [
      ...[...this.npcVisuals.values()].map((visual) => ({
        id: visual.definition.id,
        residualId: visual.definition.residualId,
        animationId: visual.definition.texture,
        frame: visual.frame,
        residualFrame: visual.residualFrame,
        normalVisible: visual.normal.visible,
        residualVisible: visual.residual.visible,
        routeVisible: visual.route.visible,
        x: visual.normal.x,
        y: visual.normal.y
      })),
      ...[...this.studyNpcVisuals.values()].map((visual) => ({
        id: visual.definition.id,
        residualId: visual.definition.residualId,
        animationId: visual.definition.texture,
        frame: visual.normal.anims.currentFrame?.index ?? 0,
        residualFrame: Number(visual.residual.frame.name) || 0,
        normalVisible: visual.normal.visible,
        residualVisible: visual.residual.visible,
        routeVisible: false,
        x: visual.normal.x,
        y: visual.normal.y
      }))
    ];
    setRpgRuntimeDebugState({
      engine: "phaser",
      coordinateSystem: "Phaser world coordinates, origin at top-left, x right, y down",
      world: { ...WORLD },
      player: {
        x: this.player.x,
        y: this.player.y,
        facing: this.animator.facing,
        cardinalFacing: this.animator.cardinalFacing,
        collisionWidth: body?.width,
        collisionHeight: body?.height
      },
      input: {
        gameEnabled: this.game.input.enabled,
        sceneEnabled: this.input.enabled,
        keyboardEnabled: this.input.keyboard?.enabled ?? false,
        keys: {
          up: this.cursors?.up.isDown ?? false,
          down: this.cursors?.down.isDown ?? false,
          left: this.cursors?.left.isDown ?? false,
          right: this.cursors?.right.isDown ?? false,
          interact: this.interactKey?.isDown ?? false
        }
      },
      camera: {
        scrollX: this.cameras.main.scrollX,
        scrollY: this.cameras.main.scrollY,
        zoom: this.cameras.main.zoom,
        mode: "follow"
      },
      scene: "duan_yongping_temporal_maze",
      checkpoint: this.bridge.getState().rpgCheckpoint,
      activeTargets: activeTargetDebug,
      collisionRects: [...WORLD_STATIC_COLLISIONS, ...this.activeDynamicCollisionRects],
      chapterFour: {
        phase: state.phase,
        mode: state.mode,
        cycle: state.cycle,
        airflowObserved: state.airflowObserved,
        paperGuidedToElevator: state.paperGuidedToElevator,
        mapAssetId: floor.id,
        mapAssetIds: FLOORS.map((entry) => entry.id),
        stitchedWorld: true,
        currentFloor: this.currentFloor,
        floorOffsetX: floor.offsetX,
        elevatorPanelOpen: this.floorPanel !== null,
        elevatorRuntimePhase: this.elevatorPhase,
        elevatorDoorProgress: this.elevatorDoorProgress,
        elevatorTargetFloor: this.elevatorTargetFloor,
        elevatorDisplayFloor: this.elevatorDisplayFloor,
        elevatorWaitRemainingMs: Math.max(0, Math.round(this.elevatorWaitEndsAt - this.time.now)),
        historicalElevatorDoorOpen: this.historicalDoorOpen,
        historicalElevatorEntryRemainingMs: Math.max(
          0,
          Math.round(this.historicalEntryWindowEndsAt - this.time.now)
        ),
        historicalElevatorRideInProgress: this.historicalRideInProgress,
        lastAppliedCheckpoint: this.lastAppliedCheckpoint,
        nearbyTravelZone: this.nearbyTravelZone?.id ?? null,
        nearbyTargetId: this.nearbyTarget?.id ?? this.nearbyPartitionId,
        nearbyPartitionId: this.nearbyPartitionId,
        a1NearbyTargetId: this.currentFloor === 1 ? this.nearbyTarget?.id ?? null : null,
        a1PendingAction: this.pendingMazeAction && (
          isA1TargetAction(this.pendingMazeAction.action)
          || this.pendingMazeAction.action === "elevator_replay_missed"
          || this.pendingMazeAction.action === "complete_elevator_ride"
        )
          ? {
              requestId: this.pendingMazeAction.requestId,
              action: this.pendingMazeAction.action,
              targetId: this.pendingMazeAction.targetId
            }
          : null,
        currentLandmark: this.nearbyAnchor?.id ?? null,
        npcFrames,
        targetBounds,
        pendingAction: this.pendingMazeAction
          ? {
              ...this.pendingMazeAction,
              ...(this.pendingMazeAction.order
                ? { order: [...this.pendingMazeAction.order] }
                : {})
            }
          : null,
        storyAnchors: anchorDebug,
        gameplayTargetsActive: activeInteractionTargets.length,
        routeState: this.projection.routeState,
        activeCollisionIds: [...this.projection.activeCollisionIds],
        activeTargetIds: activeInteractionTargets.map((target) => target.id),
        visibleNpcIds: [...this.projection.visibleNpcIds],
        residualNpcIds: [...this.projection.residualNpcIds],
        activeDoorIds: [...this.projection.activeDoorIds],
        activePartitionIds: [...this.projection.activePartitionIds],
        safeRouteRects: SAFE_ROUTE_RECTS,
        transportCore: {
          coordinateSpace: "floor-local",
          elevator: {
            id: MAIN_ELEVATOR.id,
            centerX: MAIN_ELEVATOR.centerX,
            storyFloors: [...MAIN_ELEVATOR.storyFloors]
          },
          stair: {
            id: MAIN_STAIR.id,
            left: MAIN_STAIR.left,
            top: MAIN_STAIR.top,
            right: MAIN_STAIR.right,
            bottom: MAIN_STAIR.bottom,
            storyFloors: [...MAIN_STAIR.storyFloors]
          }
        },
        currentStoryFloor: floor.storyFloor,
        currentSafeCheckpoint: this.projection.safeCheckpoint
      }
    });
  }
}
