import { preloadRpgImage, preloadRpgSpriteSheet } from "./RpgAssetLoader";
import Phaser from "phaser";
import { deferRpgRuntimeDebugCapture } from "./RpgRuntimeDebug";
import canteenInteriorMapUrl from "../../assets/rpg/interiors/canteen_interior.png";
import canteenCounterAuntiesSheetUrl from "../../assets/rpg/npcs/canteen/counter_aunties_2frame.png";
import canteenQueueStudentsSheetUrl from "../../assets/rpg/npcs/canteen/queue_students_2frame.png";
import canteenReturnAuntieSheetUrl from "../../assets/rpg/npcs/canteen/return_auntie_2frame.png";
import canteenSeatedStudentsExtraSheetUrl from "../../assets/rpg/npcs/canteen/seated_students_extra_2frame.png";
import canteenSeatedStudentsSheetUrl from "../../assets/rpg/npcs/canteen/seated_students_2frame.png";
import canteenShadowAuntieSheetUrl from "../../assets/rpg/npcs/canteen/shadow_auntie_3frame.png";
import canteenPromoBoardActiveUrl from "../../assets/rpg/canteen/promo/canteen_promo_board_active.png";
import canteenPromoBoardEmptyUrl from "../../assets/rpg/canteen/promo/canteen_promo_board_empty.png";
import canteenPromoDrinkInsertSheetUrl from "../../assets/rpg/canteen/promo/canteen_promo_drink_insert_4frame.png";
import canteenPromoFxSheetUrl from "../../assets/rpg/canteen/promo/canteen_promo_fx_3x2.png";
import canteenQueueStudentTurnUrl from "../../assets/rpg/canteen/promo/canteen_queue_student_turn.png";
import canteenPaperChickenBurstSheetUrl from "../../assets/rpg/canteen/pickup-cutscene/paper_chicken_burst_8frame.png";
import canteenPaperChickenShakeSheetUrl from "../../assets/rpg/canteen/pickup-cutscene/paper_chicken_shake_5frame.png";
import canteenShadowAuntiePushSheetUrl from "../../assets/rpg/canteen/pickup-cutscene/shadow_auntie_push_5frame.png";
import playerPushCartSheetUrl from "../../assets/rpg/player/player_push_cart_sheet.png";
import type { GameSubtitleTone } from "../../components/GameSubtitleFrame";
import type {
  CanteenDrinkIngredientId,
  CanteenExitId,
  CanteenHuntPhase,
  CanteenMode,
  GameState,
  ItemId
} from "../../core/types";
import canteenContent from "../../data/chapter3-canteen.content.json";
import { CANTEEN_EXIT_SEQUENCE } from "../../modules/ChapterThreeCanteenController";
import { getDeveloperCanteenDefenseStart } from "../../modules/DeveloperChannel";
import type { RpgBridge } from "./RpgBridge";
import { formatRpgInteractionHint } from "./RpgControlHints";
import { RPG_HUD_LAYOUT } from "./RpgHudLayout";
import {
  formatRpgModeRequirement,
  getRpgDropBounds,
  resolveRpgItemDrop
} from "./RpgInteractionContract";
import {
  configureRpgPlayerSprite,
  ensureRpgPlayerTextures,
  preloadRpgPlayerTextures,
  RpgPlayerAnimator,
  RPG_PLAYER_DISPLAY_SCALE,
  RPG_PLAYER_FOOT_COLLISION,
  RPG_PLAYER_WALK_FPS
} from "./RpgPlayerTextures";
import { clearRpgRuntimeDebugState, setRpgRuntimeDebugState } from "./RpgRuntimeDebug";
import {
  RPG_LOGICAL_HEIGHT,
  RPG_LOGICAL_WIDTH,
  setRpgLogicalCameraZoom,
  toRpgLogicalScreenPoint,
  zoomRpgCameraTo
} from "./RpgRenderResolution";
import { RpgInteriorDoorRuntime } from "./RpgInteriorDoor";
import { subscribeRpgSceneBridge } from "./RpgSceneBridgeSubscription";
import {
  CanteenDefenseRuntime,
  type CanteenDefenseExitId
} from "./CanteenDefenseRuntime";
import {
  CANTEEN_BLOCK_SPAWNS,
  CANTEEN_CARTS,
  CANTEEN_DRINK_MACHINES,
  CANTEEN_DRINK_SHELF,
  CANTEEN_ESCAPE_ANCHORS,
  CANTEEN_INTERACTION_TARGETS,
  CANTEEN_INTERIOR_WORLD,
  CANTEEN_OCCLUSION_RECTS,
  CANTEEN_MIX_STATION,
  CANTEEN_PHASE_SPAWNS,
  CANTEEN_PICKUP_WINDOWS,
  CANTEEN_SPAWN,
  CANTEEN_STATIC_COLLISION_RECTS,
  CANTEEN_PROMO_BOARD,
  CANTEEN_QUEUE_COLUMN_THREE,
  CANTEEN_SERVICE_WINDOWS,
  CANTEEN_SOUTHEAST_EXIT_DOOR,
  CANTEEN_TRAYS,
  CANTEEN_TRAY_SLOTS,
  findNearestCanteenTarget,
  type CanteenInteractionTarget
} from "./CanteenInteriorModel";

const CANTEEN_MAP_KEY = "chapter-3-canteen-interior-map";
const CANTEEN_EXIT_DOOR_LEFT_FRAME = "southeast-exit-left-leaf";
const CANTEEN_EXIT_DOOR_RIGHT_FRAME = "southeast-exit-right-leaf";
export const CANTEEN_INTERIOR_WARM_ASSET_URLS = Object.freeze([
  canteenInteriorMapUrl,
  canteenCounterAuntiesSheetUrl,
  canteenQueueStudentsSheetUrl,
  canteenReturnAuntieSheetUrl,
  canteenSeatedStudentsExtraSheetUrl,
  canteenSeatedStudentsSheetUrl,
  canteenShadowAuntieSheetUrl,
  canteenPromoBoardActiveUrl,
  canteenPromoBoardEmptyUrl,
  canteenPromoDrinkInsertSheetUrl,
  canteenPromoFxSheetUrl,
  canteenQueueStudentTurnUrl,
  canteenPaperChickenBurstSheetUrl,
  canteenPaperChickenShakeSheetUrl,
  canteenShadowAuntiePushSheetUrl,
  playerPushCartSheetUrl
]);
const CANTEEN_PUSH_CART_SHEET_KEY = "chapter-3-canteen-player-push-cart";
const CANTEEN_QUEUE_NPC_SHEET_KEY = "chapter-3-canteen-queue-npcs";
const CANTEEN_COUNTER_NPC_SHEET_KEY = "chapter-3-canteen-counter-npcs";
const CANTEEN_SEATED_NPC_SHEET_KEY = "chapter-3-canteen-seated-npcs";
const CANTEEN_SEATED_EXTRA_NPC_SHEET_KEY = "chapter-3-canteen-seated-extra-npcs";
const CANTEEN_RETURN_NPC_SHEET_KEY = "chapter-3-canteen-return-npc";
const CANTEEN_SHADOW_NPC_SHEET_KEY = "chapter-3-canteen-shadow-npc";
const CANTEEN_PROMO_BOARD_EMPTY_KEY = "chapter-3-canteen-promo-board-empty";
const CANTEEN_PROMO_BOARD_ACTIVE_KEY = "chapter-3-canteen-promo-board-active";
const CANTEEN_PROMO_DRINK_INSERT_KEY = "chapter-3-canteen-promo-drink-insert";
const CANTEEN_PROMO_FX_KEY = "chapter-3-canteen-promo-fx";
const CANTEEN_QUEUE_STUDENT_TURN_KEY = "chapter-3-canteen-queue-student-turn";
const CANTEEN_PROMO_BUBBLE_ANIM_KEY = "chapter-3-canteen-promo-bubbles";
const CANTEEN_PROMO_INSERT_ANIM_KEY = "chapter-3-canteen-promo-insert";
const CANTEEN_SHADOW_AUNTIE_PUSH_KEY = "chapter-3-canteen-shadow-auntie-push";
const CANTEEN_PAPER_CHICKEN_SHAKE_KEY = "chapter-3-canteen-paper-chicken-shake";
const CANTEEN_PAPER_CHICKEN_BURST_KEY = "chapter-3-canteen-paper-chicken-burst";
const CANTEEN_SHADOW_AUNTIE_PUSH_ANIM_KEY = "chapter-3-canteen-shadow-auntie-push-anim";
const CANTEEN_PAPER_CHICKEN_SHAKE_ANIM_KEY = "chapter-3-canteen-paper-chicken-shake-anim";
const CANTEEN_PAPER_CHICKEN_BURST_ANIM_KEY = "chapter-3-canteen-paper-chicken-burst-anim";
const CANTEEN_NPC_FRAME_WIDTH = 96;
const CANTEEN_NPC_FRAME_HEIGHT = 128;
const CANTEEN_NPC_DISPLAY_SCALE = RPG_PLAYER_DISPLAY_SCALE;
const CANTEEN_WORLD_DEPTH_OFFSET = 120;
const CANTEEN_COUNTER_NPC_Y = 214;
const CANTEEN_COUNTER_NPC_X = [301, 550, 790, 1035] as const;
const CANTEEN_QUEUE_NPC_Y = [246, 266, 286] as const;
const CANTEEN_COUNTER_FRONT_CROP = {
  left: 126,
  top: 176,
  right: 1314,
  bottom: 241,
  depth: 340
} as const;
const CANTEEN_SIDE_GAME_PHASES: readonly CanteenHuntPhase[] = [
  "tray_search", "drink_mix", "menu_order", "pickup_search", "chase_ready"
];
function canPlayCanteenSideGames(state: GameState): boolean {
  return state.canteenHunt.active && CANTEEN_SIDE_GAME_PHASES.includes(state.canteenHunt.phase);
}

function hasCompletedCanteenTrayTask(state: GameState): boolean {
  return CANTEEN_TRAYS
    .filter((tray) => tray.target)
    .every((tray) => state.canteenHunt.returnedTrayIds.includes(tray.id));
}

function canPlayCanteenDrinkPuzzle(state: GameState): boolean {
  return canPlayCanteenSideGames(state)
    && !state.canteenHunt.promoDrinkPlaced
    && !state.canteenHunt.queueGapOpened;
}
const CANTEEN_SEATED_NPC_PLACEMENTS = [
  { framePair: 0, x: 344, y: 377 },
  { framePair: 4, x: 408, y: 389 },
  { framePair: 1, x: 799, y: 383 },
  { framePair: 5, x: 863, y: 383 },
  { framePair: 2, x: 493, y: 486 },
  { framePair: 6, x: 557, y: 498 },
  { framePair: 3, x: 953, y: 601 },
  { framePair: 7, x: 1017, y: 601 }
] as const;
const CANTEEN_SEATED_EXTRA_NPC_PLACEMENTS = [
  { framePair: 0, x: 195, y: 486 },
  { framePair: 3, x: 259, y: 498 },
  { framePair: 1, x: 953, y: 486 },
  { framePair: 4, x: 1017, y: 498 },
  { framePair: 2, x: 493, y: 595 },
  { framePair: 5, x: 557, y: 607 }
] as const;
const CANTEEN_SEATED_TABLE_CROPS = [
  { left: 329, top: 374, right: 423, bottom: 402 },
  { left: 786, top: 374, right: 880, bottom: 402 },
  { left: 478, top: 483, right: 572, bottom: 512 },
  { left: 941, top: 592, right: 1035, bottom: 622 },
  { left: 180, top: 483, right: 274, bottom: 512 },
  { left: 941, top: 483, right: 1035, bottom: 510 },
  { left: 478, top: 592, right: 572, bottom: 623 }
] as const;
const CANTEEN_RETURN_NPC_POSITION = { x: 1515, y: 610 } as const;
const CANTEEN_QUEUE_NPC_DIALOGUE = [
  "前面没动，我也没动。大家都很稳定。",
  "你说的对。虽然不知道你说了什么。",
  "是啊，吃什么。",
  "今天有气泡水喝吗？",
  "早十不慌，先来个西红柿鸡蛋。",
  "为什么早上吃西红柿鸡蛋。"
] as const;
const CANTEEN_SEATED_NPC_DIALOGUE = [
  "刚才有张纸过去了。它没拿餐盘。",
  "看手机。",
  "依旧看手机。",
  "不用问了可以坐这里。"
] as const;
const CANTEEN_COUNTER_NPC_DIALOGUE = "要什么？快点，后面排着呢。";
const CANTEEN_TRAY_KEY = "chapter-3-canteen-tray";
const CANTEEN_DIRTY_TRAY_KEY = "chapter-3-canteen-dirty-tray";
const CANTEEN_CART_FRAME_KEYS = [
  "chapter-3-canteen-cart-0",
  "chapter-3-canteen-cart-1",
  "chapter-3-canteen-cart-2",
  "chapter-3-canteen-cart-3"
] as const;
const CANTEEN_PAPER_KEY = "chapter-3-canteen-paper";
const CANTEEN_PAPER_RUN_KEYS = [
  "chapter-3-canteen-paper-run-0",
  "chapter-3-canteen-paper-run-1",
  "chapter-3-canteen-paper-run-2",
  "chapter-3-canteen-paper-run-3"
] as const;
const WALK_SPEED = 165;
const RUN_SPEED = 228;
const DIALOGUE_STEP_MS = 2500;
const ENTRY_DIALOGUE_STEP_MS = 1600;
const ENTRY_CAMERA_ZOOM = 1.18;
const ENTRY_PAPER_TRIGGER_RADIUS = 360;
const CART_APPROACH_SPEED = 175;
const CART_MIN_ROLL_DURATION_MS = 520;
const CART_ROLL_FRAME_MS = 82;

interface TrayVisual {
  container: Phaser.GameObjects.Container;
  cleanImage: Phaser.GameObjects.Image;
  dirtyImage: Phaser.GameObjects.Image;
  sparkles: Phaser.GameObjects.Arc[];
}

interface OcclusionVisual {
  id: string;
  bounds: Phaser.Geom.Rectangle;
  sortY: number;
  image: Phaser.GameObjects.Image;
}

interface PickupWindowVisual {
  sign: Phaser.GameObjects.Container;
  standMarker: Phaser.GameObjects.Container;
  dropFrame: Phaser.GameObjects.Rectangle;
  dropLabel: Phaser.GameObjects.Text;
}

interface CanteenNpcSheetDefinition {
  key: string;
  url: string;
}

interface QueueNpcVisual {
  sprite: Phaser.GameObjects.Sprite;
  collision: Phaser.GameObjects.Rectangle;
  baseY: number;
}

export class CanteenInteriorScene extends Phaser.Scene {
  private bridge!: RpgBridge;
  private player!: Phaser.Physics.Arcade.Sprite;
  private playerAnimator!: RpgPlayerAnimator;
  private playerCollisionDebug: Phaser.GameObjects.Rectangle | null = null;
  private obstacles!: Phaser.Physics.Arcade.StaticGroup;
  private exitDoor!: RpgInteriorDoorRuntime;
  private cursors!: Phaser.Types.Input.Keyboard.CursorKeys;
  private keys!: Record<"W" | "A" | "S" | "D" | "SHIFT" | "TAB", Phaser.Input.Keyboard.Key>;
  private virtualDirection = { x: 0, y: 0 };
  private interactRequested = false;
  private promptText!: Phaser.GameObjects.Text;
  private darkOverlay!: Phaser.GameObjects.Rectangle;
  private modeFibers: Phaser.GameObjects.Arc[] = [];
  private trayVisuals = new Map<string, TrayVisual>();
  private trayInteractionTargets = new Map<string, CanteenInteractionTarget>();
  private carriedTrayVisual!: Phaser.GameObjects.Image;
  private exitTransitioning = false;
  private exitDoorProximityActive = false;
  private pickupWindowVisuals = new Map<string, PickupWindowVisual>();
  private cartVisuals = new Map<CanteenExitId, Phaser.GameObjects.Image>();
  private exitGlows = new Map<CanteenExitId, Phaser.GameObjects.Arc>();
  private paper!: Phaser.GameObjects.Image;
  private paperFloatTween!: Phaser.Tweens.Tween;
  private menuPanel: Phaser.GameObjects.Container | null = null;
  private drinkChoicePanel: Phaser.GameObjects.Container | null = null;
  private drinkChoiceItem: CanteenDrinkIngredientId | null = null;
  private drinkChoiceSelection: 0 | 1 = 0;
  private drinkChoiceControls: {
    takeButton: Phaser.GameObjects.Rectangle;
    takeLabel: Phaser.GameObjects.Text;
    cancelButton: Phaser.GameObjects.Rectangle;
    cancelLabel: Phaser.GameObjects.Text;
  } | null = null;
  private suppressWorldPointerUntil = 0;
  private mixerPanel: Phaser.GameObjects.Container | null = null;
  private mixerButtonOrder: CanteenDrinkIngredientId[] = [];
  private promoPanel: Phaser.GameObjects.Image | null = null;
  private promoEmptyCup: Phaser.GameObjects.Image | null = null;
  private promoDrinkInsert: Phaser.GameObjects.Sprite | null = null;
  private promoBubbleLoop: Phaser.GameObjects.Sprite | null = null;
  private promoDropFrame: Phaser.GameObjects.Rectangle | null = null;
  private thirdColumnQueue: QueueNpcVisual[] = [];
  private queueShiftAnimating = false;
  private currentMode: CanteenMode = "light";
  private currentPhase: GameState["canteenHunt"]["phase"] = "tray_search";
  private dialogueLocked = false;
  private paperBusy = false;
  private entryPaperPending = false;
  private entryPaperTriggered = false;
  private entryPaperIdleTween: Phaser.Tweens.Tween | null = null;
  private entryPaperRunTimer: Phaser.Time.TimerEvent | null = null;
  private cartPushBusy = false;
  private cartMotionExit: CanteenExitId | null = null;
  private cartMotionVector = new Phaser.Math.Vector2();
  private reducedMotion = false;
  private occlusionVisuals: OcclusionVisual[] = [];
  private activeOcclusionIds: string[] = [];
  private softenedOcclusionIds: string[] = [];
  private lightNpcSprites: Phaser.GameObjects.Sprite[] = [];
  private lightNpcCollisionBodies: Phaser.GameObjects.Rectangle[] = [];
  private initialNpcInteractionTargets: CanteenInteractionTarget[] = [];
  private returnAuntieTarget!: CanteenInteractionTarget;
  private shadowNpcSprite: Phaser.GameObjects.Sprite | null = null;
  private defenseRuntime: CanteenDefenseRuntime | null = null;
  private defenseRouteGraphics: Phaser.GameObjects.Graphics | null = null;
  private defenseRestartTimer: Phaser.Time.TimerEvent | null = null;

  constructor() {
    super("canteen-interior");
  }

  /**
   * Phaser keeps one Scene instance and calls create() again after a stop/start.
   * Only display objects are discarded automatically; scene-owned booleans,
   * maps, and modal references otherwise survive into the next visit.
   */
  private resetRestartLifecycleState(): void {
    this.playerCollisionDebug = null;
    this.virtualDirection = { x: 0, y: 0 };
    this.interactRequested = false;
    this.modeFibers = [];
    this.trayVisuals.clear();
    this.trayInteractionTargets.clear();
    this.exitTransitioning = false;
    this.exitDoorProximityActive = false;
    this.pickupWindowVisuals.clear();
    this.cartVisuals.clear();
    this.exitGlows.clear();
    this.menuPanel = null;
    this.drinkChoicePanel = null;
    this.drinkChoiceItem = null;
    this.drinkChoiceSelection = 0;
    this.drinkChoiceControls = null;
    this.suppressWorldPointerUntil = 0;
    this.mixerPanel = null;
    this.mixerButtonOrder = [];
    this.promoPanel = null;
    this.promoEmptyCup = null;
    this.promoDrinkInsert = null;
    this.promoBubbleLoop = null;
    this.promoDropFrame = null;
    this.thirdColumnQueue = [];
    this.queueShiftAnimating = false;
    this.dialogueLocked = false;
    this.paperBusy = false;
    this.entryPaperPending = false;
    this.entryPaperTriggered = false;
    this.entryPaperIdleTween = null;
    this.entryPaperRunTimer = null;
    this.cartPushBusy = false;
    this.cartMotionExit = null;
    this.cartMotionVector.set(0, 0);
    this.occlusionVisuals = [];
    this.activeOcclusionIds = [];
    this.softenedOcclusionIds = [];
    this.lightNpcSprites = [];
    this.lightNpcCollisionBodies = [];
    this.initialNpcInteractionTargets = [];
    this.shadowNpcSprite = null;
    this.defenseRuntime = null;
    this.defenseRouteGraphics = null;
    this.defenseRestartTimer = null;
  }

  preload(): void {
    if (!this.textures.exists(CANTEEN_MAP_KEY)) {
      preloadRpgImage(this, CANTEEN_MAP_KEY, canteenInteriorMapUrl);
    }
    if (!this.textures.exists(CANTEEN_PUSH_CART_SHEET_KEY)) {
      preloadRpgSpriteSheet(this, CANTEEN_PUSH_CART_SHEET_KEY, playerPushCartSheetUrl, {
        frameWidth: 314,
        frameHeight: 314
      });
    }
    const npcSheets: readonly CanteenNpcSheetDefinition[] = [
      { key: CANTEEN_QUEUE_NPC_SHEET_KEY, url: canteenQueueStudentsSheetUrl },
      { key: CANTEEN_COUNTER_NPC_SHEET_KEY, url: canteenCounterAuntiesSheetUrl },
      { key: CANTEEN_SEATED_NPC_SHEET_KEY, url: canteenSeatedStudentsSheetUrl },
      { key: CANTEEN_SEATED_EXTRA_NPC_SHEET_KEY, url: canteenSeatedStudentsExtraSheetUrl },
      { key: CANTEEN_RETURN_NPC_SHEET_KEY, url: canteenReturnAuntieSheetUrl },
      { key: CANTEEN_SHADOW_NPC_SHEET_KEY, url: canteenShadowAuntieSheetUrl }
    ];
    npcSheets.forEach(({ key, url }) => {
      if (this.textures.exists(key)) return;
      preloadRpgSpriteSheet(this, key, url, {
        frameWidth: CANTEEN_NPC_FRAME_WIDTH,
        frameHeight: CANTEEN_NPC_FRAME_HEIGHT
      });
    });
    if (!this.textures.exists(CANTEEN_PROMO_BOARD_EMPTY_KEY)) {
      preloadRpgImage(this, CANTEEN_PROMO_BOARD_EMPTY_KEY, canteenPromoBoardEmptyUrl);
    }
    if (!this.textures.exists(CANTEEN_PROMO_BOARD_ACTIVE_KEY)) {
      preloadRpgImage(this, CANTEEN_PROMO_BOARD_ACTIVE_KEY, canteenPromoBoardActiveUrl);
    }
    if (!this.textures.exists(CANTEEN_PROMO_DRINK_INSERT_KEY)) {
      preloadRpgSpriteSheet(this, CANTEEN_PROMO_DRINK_INSERT_KEY, canteenPromoDrinkInsertSheetUrl, {
        frameWidth: 48,
        frameHeight: 64
      });
    }
    if (!this.textures.exists(CANTEEN_PROMO_FX_KEY)) {
      preloadRpgSpriteSheet(this, CANTEEN_PROMO_FX_KEY, canteenPromoFxSheetUrl, {
        frameWidth: 48,
        frameHeight: 48
      });
    }
    if (!this.textures.exists(CANTEEN_QUEUE_STUDENT_TURN_KEY)) {
      preloadRpgImage(this, CANTEEN_QUEUE_STUDENT_TURN_KEY, canteenQueueStudentTurnUrl);
    }
    if (!this.textures.exists(CANTEEN_SHADOW_AUNTIE_PUSH_KEY)) {
      preloadRpgSpriteSheet(this, CANTEEN_SHADOW_AUNTIE_PUSH_KEY, canteenShadowAuntiePushSheetUrl, {
        frameWidth: 96,
        frameHeight: 128
      });
    }
    if (!this.textures.exists(CANTEEN_PAPER_CHICKEN_SHAKE_KEY)) {
      preloadRpgSpriteSheet(this, CANTEEN_PAPER_CHICKEN_SHAKE_KEY, canteenPaperChickenShakeSheetUrl, {
        frameWidth: 64,
        frameHeight: 80
      });
    }
    if (!this.textures.exists(CANTEEN_PAPER_CHICKEN_BURST_KEY)) {
      preloadRpgSpriteSheet(this, CANTEEN_PAPER_CHICKEN_BURST_KEY, canteenPaperChickenBurstSheetUrl, {
        frameWidth: 96,
        frameHeight: 96
      });
    }
    preloadRpgPlayerTextures(this);
  }

  create(): void {
    this.resetRestartLifecycleState();
    this.bridge = this.registry.get("rpgBridge") as RpgBridge;
    this.reducedMotion = window.matchMedia?.("(prefers-reduced-motion: reduce)").matches === true;
    this.currentMode = this.bridge.getState().canteenHunt.mode;
    this.currentPhase = this.bridge.getState().canteenHunt.phase;
    this.entryPaperPending = this.bridge.getState().canteenHunt.active
      && this.currentPhase === "tray_search"
      && !this.bridge.getState().canteenHunt.entryPaperEscaped;
    this.cameras.main.setBackgroundColor(0x0b0d0f);
    this.physics.world.setBounds(28, 16, CANTEEN_INTERIOR_WORLD.width - 56, CANTEEN_INTERIOR_WORLD.height - 34);
    this.obstacles = this.physics.add.staticGroup();
    this.drawInterior();
    this.ensureCanteenExitDoorFrames();
    const exitOpening = CANTEEN_SOUTHEAST_EXIT_DOOR.opening;
    this.exitDoor = new RpgInteriorDoorRuntime(this, {
      id: "canteen_southeast_exit",
      centerX: CANTEEN_SOUTHEAST_EXIT_DOOR.center.x,
      centerY: CANTEEN_SOUTHEAST_EXIT_DOOR.center.y,
      openingWidth: exitOpening.right - exitOpening.left,
      openingHeight: exitOpening.bottom - exitOpening.top,
      motion: "double-fold",
      motionEase: "Sine.easeInOut",
      durationMs: 460,
      depth: 920,
      palette: {
        portal: 0x111716,
        spill: 0xc8e7dc,
        leaf: 0x3a3935,
        inset: 0x4c4a43,
        trim: 0x171713,
        handle: 0xb8b6a7
      },
      portalAlpha: 1,
      spillAlphaClosed: 0,
      spillAlphaOpen: 0.12,
      leafTextures: {
        left: { key: CANTEEN_MAP_KEY, frame: CANTEEN_EXIT_DOOR_LEFT_FRAME },
        right: { key: CANTEEN_MAP_KEY, frame: CANTEEN_EXIT_DOOR_RIGHT_FRAME }
      },
      hideLeavesWhenOpen: true,
      foreground: {
        textureKey: CANTEEN_MAP_KEY,
        left: 1248,
        top: 752,
        right: 1497,
        bottom: 833,
        sortY: 900
      }
    }, this.reducedMotion);
    this.ensureCanteenTextures();
    ensureRpgPlayerTextures(this);
    this.createCanteenNpcs();
    this.createInitialNpcInteractions();

    const entryPreview = import.meta.env.DEV
      && new URLSearchParams(window.location.search).get("canteenEntryPreview") === "1";
    const spawn = entryPreview && this.entryPaperPending
      ? { x: 1053, y: 660 }
      : this.currentPhase === "drink_mix"
      ? CANTEEN_PHASE_SPAWNS.drink_mix
      : this.currentPhase === "menu_order"
      ? CANTEEN_PHASE_SPAWNS.menu_order
      : this.currentPhase === "pickup_search"
        ? CANTEEN_PHASE_SPAWNS.pickup_search
        : this.currentPhase === "exit_blocking"
          ? CANTEEN_BLOCK_SPAWNS[Math.min(2, this.bridge.getState().canteenHunt.blockHits)]
          : CANTEEN_SPAWN;
    this.player = this.physics.add.sprite(spawn.x, spawn.y, "act1-player-up-0");
    this.player.setCollideWorldBounds(true);
    configureRpgPlayerSprite(this.player);
    this.applyPlayerCollisionBody();
    this.updatePlayerWorldDepth();
    if (
      import.meta.env.DEV
      && new URLSearchParams(window.location.search).get("rpgCollision") === "1"
    ) {
      this.playerCollisionDebug = this.add.rectangle(0, 0, 1, 1, 0xffef66, 0.5)
        .setStrokeStyle(3, 0xffffff, 1)
        .setDepth(6100);
      this.updatePlayerCollisionDebug();
    }
    this.playerAnimator = new RpgPlayerAnimator(this.player, "up");
    this.physics.add.collider(this.player, this.obstacles);

    this.cursors = this.input.keyboard!.createCursorKeys();
    this.keys = this.input.keyboard!.addKeys("W,A,S,D,SHIFT,TAB") as Record<
      "W" | "A" | "S" | "D" | "SHIFT" | "TAB",
      Phaser.Input.Keyboard.Key
    >;
    this.input.keyboard!.addCapture(Phaser.Input.Keyboard.KeyCodes.TAB);
    this.input.keyboard!.addCapture(Phaser.Input.Keyboard.KeyCodes.SPACE);
    this.input.keyboard!.addCapture(Phaser.Input.Keyboard.KeyCodes.LEFT);
    this.input.keyboard!.addCapture(Phaser.Input.Keyboard.KeyCodes.RIGHT);
    this.input.keyboard!.addCapture(Phaser.Input.Keyboard.KeyCodes.ENTER);
    this.input.keyboard!.addCapture(Phaser.Input.Keyboard.KeyCodes.ESC);
    const requestKeyboardInteraction = (event: KeyboardEvent) => {
      event.preventDefault();
      if (this.hasModalPanel()) return;
      if (!event.repeat) this.interactRequested = true;
    };
    const handleModalKeyboard = (event: KeyboardEvent) => this.handleModalKeyboard(event);
    const handleScenePointer = (pointer: Phaser.Input.Pointer) => {
      this.handleMenuPointer(pointer);
      this.handleDrinkChoicePointer(pointer);
      this.handleMixerPointer(pointer);
    };
    this.input.keyboard!.on("keydown-SPACE", requestKeyboardInteraction);
    this.input.keyboard!.on("keydown", handleModalKeyboard);
    this.input.on("pointerdown", handleScenePointer);
    this.events.once(Phaser.Scenes.Events.SHUTDOWN, () => {
      this.input.keyboard?.off("keydown-SPACE", requestKeyboardInteraction);
      this.input.keyboard?.off("keydown", handleModalKeyboard);
      this.input.off("pointerdown", handleScenePointer);
      this.entryPaperIdleTween?.stop();
      this.entryPaperRunTimer?.remove(false);
      this.defenseRestartTimer?.remove(false);
      this.defenseRuntime?.destroy();
      this.closeMenuPanel();
      this.closeDrinkChoicePanel();
      this.closeMixerPanel();
      this.resetRestartLifecycleState();
    });

    setRpgLogicalCameraZoom(
      this,
      this.entryPaperPending ? ENTRY_CAMERA_ZOOM : 1,
      this.cameras.main.setBounds(0, 0, CANTEEN_INTERIOR_WORLD.width, CANTEEN_INTERIOR_WORLD.height)
    )
      .centerOn(this.player.x, this.player.y);

    this.createTrays();
    this.carriedTrayVisual = this.add.image(0, 0, CANTEEN_TRAY_KEY)
      .setScale(0.75)
      .setDepth(2300)
      .setVisible(false);
    this.createCarts();
    this.createPickupWindowSigns();
    this.createPaper();
    if (this.entryPaperPending) this.prepareEntryPaperQueuePose();
    this.createWorldHotspots();
    this.createPromoBoardVisual();
    this.createDarkModeLayer();
    this.createPrompt();
    this.syncWorldFromState(this.bridge.getState(), true);

    subscribeRpgSceneBridge(
      this.events,
      this.bridge,
      (event) => this.handleBridgeEvent(event.name, event.payload),
      clearRpgRuntimeDebugState
    );
    this.bridge.setRpgLocation("canteen_interior", "canteen_entrance");
    this.bridge.emit("rpg_booted", { scene: "canteen_interior", checkpoint: "canteen_entrance" });
    this.bridge.emit("canteen_interior_opened");

    this.cameras.main.startFollow(this.player, true, 0.13, 0.13, 0, 24).setDeadzone(250, 150);
    if (this.currentPhase === "exit_blocking") {
      this.startDefense();
    }
    const initialState = this.bridge.getState();
    if (
      canPlayCanteenSideGames(initialState)
      && initialState.canteenHunt.promoDrinkPlaced
      && !initialState.canteenHunt.queueGapOpened
    ) {
      this.time.delayedCall(220, () => this.animatePromoAndQueueShift());
    }
  }

  update(_time: number, deltaMs: number): void {
    // Phaser can deliver one final update while a stopped interior is being
    // replaced by the bike overlay. The player body has already been released
    // at that point, so the stale frame must not write velocity into it.
    if (!this.player?.active || !this.player.body) return;
    const state = this.bridge.getState();
    this.syncWorldFromState(state);
    this.updateCarriedTrayVisual(state);
    const requestedDefenseStartMs = getDeveloperCanteenDefenseStart();
    if (
      state.canteenHunt.phase === "exit_blocking"
      && this.defenseRuntime
      && this.defenseRuntime.getDebugSnapshot().startElapsedMs !== requestedDefenseStartMs
    ) {
      // DEV checkpoints can switch between start, middle, and final validation
      // while this Phaser scene remains active. Recreate only the transient
      // defense simulation so the requested clock and speed take effect.
      this.finishDefense();
      this.startDefense();
    }
    if (
      state.canteenHunt.phase === "exit_blocking"
      && !this.defenseRuntime
      && !this.paperBusy
    ) {
      this.startDefense();
    }

    if (
      !this.defenseRuntime
      && Phaser.Input.Keyboard.JustDown(this.keys.TAB)
      && !this.hasModalPanel()
      && !this.dialogueLocked
    ) {
      this.requestModeToggle();
    }

    const keyboardX = Number(this.cursors.right.isDown || this.keys.D.isDown)
      - Number(this.cursors.left.isDown || this.keys.A.isDown);
    const keyboardY = Number(this.cursors.down.isDown || this.keys.S.isDown)
      - Number(this.cursors.up.isDown || this.keys.W.isDown);
    const vector = new Phaser.Math.Vector2(
      Phaser.Math.Clamp(keyboardX + this.virtualDirection.x, -1, 1),
      Phaser.Math.Clamp(keyboardY + this.virtualDirection.y, -1, 1)
    );
    const keyboardInteract = Phaser.Input.Keyboard.JustDown(this.cursors.space);
    if (this.defenseRuntime) {
      const defenseMotion = this.defenseRuntime.update(
        deltaMs,
        vector,
        keyboardInteract || this.interactRequested
      );
      this.playerAnimator.update(defenseMotion, this.time.now);
      this.updateOcclusion();
      this.exitDoor.updateActorOcclusion(this.player);
      this.updateCarriedTrayVisual(state);
      this.updatePlayerCollisionDebug();
      this.promptText.setVisible(false);
      this.publishDebugState(null, state);
      this.interactRequested = false;
      return;
    }
    // Text overlays only pause interactions. A short prompt or a story line must
    // not freeze navigation across the canteen.
    const movementAllowed = this.isMovementAllowed(state);
    if (movementAllowed && vector.lengthSq() > 0) {
      vector.normalize().scale(this.keys.SHIFT.isDown ? RUN_SPEED : WALK_SPEED);
    } else {
      vector.set(0, 0);
    }
    this.player.setVelocity(vector.x, vector.y);
    this.syncCanteenExitDoorProximity(state);
    this.updatePlayerWorldDepth();
    this.playerAnimator.update(
      this.cartPushBusy && this.cartMotionVector.lengthSq() > 0 ? this.cartMotionVector : vector,
      this.time.now
    );
    this.updateOcclusion();
    this.exitDoor.updateActorOcclusion(this.player);
    this.updateCarriedTrayVisual(state);
    this.updatePlayerCollisionDebug();

    if (
      this.entryPaperPending
      && !this.entryPaperTriggered
      && Phaser.Math.Distance.Between(this.player.x, this.player.y, this.paper.x, this.paper.y)
        <= ENTRY_PAPER_TRIGGER_RADIUS
    ) {
      this.startEntryPaperDiscovery();
      this.promptText.setVisible(false);
      this.interactRequested = false;
      return;
    }

    const activeTargets = this.getActiveTargets(state);
    const nearest = findNearestCanteenTarget(this.player.x, this.player.y, activeTargets);
    this.updatePrompt(nearest, state);
    this.publishDebugState(nearest, state);

    if (nearest && !this.dialogueLocked && !this.hasModalPanel() && !this.paperBusy && !this.cartPushBusy && (keyboardInteract || this.interactRequested)) {
      this.triggerTarget(nearest, state);
    }
    this.interactRequested = false;
  }

  private drawInterior(): void {
    this.add.image(0, 0, CANTEEN_MAP_KEY).setOrigin(0).setDepth(-1000);
    this.occlusionVisuals = CANTEEN_OCCLUSION_RECTS.map((definition) => ({
      id: definition.id,
      bounds: new Phaser.Geom.Rectangle(
        definition.left,
        definition.top,
        definition.right - definition.left,
        definition.bottom - definition.top
      ),
      sortY: definition.sortY,
      image: this.add.image(0, 0, CANTEEN_MAP_KEY)
        .setOrigin(0)
        .setCrop(
          definition.left,
          definition.top,
          definition.right - definition.left,
          definition.bottom - definition.top
        )
        .setDepth(-900)
        .setVisible(false)
    }));
    this.rebuildStaticCollisionBodies();
  }

  private ensureCanteenExitDoorFrames(): void {
    const texture = this.textures.get(CANTEEN_MAP_KEY);
    const frames = [
      [CANTEEN_EXIT_DOOR_LEFT_FRAME, CANTEEN_SOUTHEAST_EXIT_DOOR.leftLeafSource],
      [CANTEEN_EXIT_DOOR_RIGHT_FRAME, CANTEEN_SOUTHEAST_EXIT_DOOR.rightLeafSource]
    ] as const;
    frames.forEach(([name, source]) => {
      if (!texture.has(name)) {
        texture.add(name, 0, source.x, source.y, source.width, source.height);
      }
    });
  }

  private createCanteenNpcs(): void {
    this.lightNpcSprites = [];
    this.lightNpcCollisionBodies = [];

    CANTEEN_COUNTER_NPC_X.forEach((x, index) => {
      this.createLightNpc(
        x,
        CANTEEN_COUNTER_NPC_Y,
        CANTEEN_COUNTER_NPC_SHEET_KEY,
        index,
        300,
        1.7 + index * 0.08,
        260 + index * 83
      );
    });

    // The authored counter front stays above workers, but below customers and
    // the player. This keeps heads in the service opening and bodies behind food trays.
    this.add.image(0, 0, CANTEEN_MAP_KEY)
      .setOrigin(0)
      .setCrop(
        CANTEEN_COUNTER_FRONT_CROP.left,
        CANTEEN_COUNTER_FRONT_CROP.top,
        CANTEEN_COUNTER_FRONT_CROP.right - CANTEEN_COUNTER_FRONT_CROP.left,
        CANTEEN_COUNTER_FRONT_CROP.bottom - CANTEEN_COUNTER_FRONT_CROP.top
      )
      .setDepth(CANTEEN_COUNTER_FRONT_CROP.depth);

    let queueIndex = 0;
    const queueGapAlreadyOpen = this.bridge.getState().canteenHunt.queueGapOpened;
    this.thirdColumnQueue = [];
    CANTEEN_COUNTER_NPC_X.forEach((x, columnIndex) => {
      CANTEEN_QUEUE_NPC_Y.forEach((y, rowIndex) => {
        const shiftedY = y + (columnIndex === 2 && queueGapAlreadyOpen ? 36 : 0);
        const sprite = this.createLightNpc(
          x,
          shiftedY,
          CANTEEN_QUEUE_NPC_SHEET_KEY,
          queueIndex,
          shiftedY + 120,
          1.35 + (queueIndex % 4) * 0.1,
          180 + ((columnIndex * 3 + rowIndex) * 137) % 520
        );
        const collision = this.createLightNpcFootCollision(x, shiftedY, `queue-${queueIndex}`);
        if (columnIndex === 2) {
          this.thirdColumnQueue.push({ sprite, collision, baseY: y });
        }
        queueIndex += 1;
      });
    });

    CANTEEN_SEATED_NPC_PLACEMENTS.forEach((placement, index) => {
      this.createLightNpc(
        placement.x,
        placement.y,
        CANTEEN_SEATED_NPC_SHEET_KEY,
        placement.framePair,
        placement.y + 120,
        1.45 + (index % 4) * 0.12,
        220 + (index * 149) % 640
      );
    });
    CANTEEN_SEATED_EXTRA_NPC_PLACEMENTS.forEach((placement, index) => {
      this.createLightNpc(
        placement.x,
        placement.y,
        CANTEEN_SEATED_EXTRA_NPC_SHEET_KEY,
        placement.framePair,
        placement.y + 120,
        1.5 + (index % 3) * 0.13,
        310 + (index * 173) % 620
      );
    });

    // Redraw the occupied table bodies above the seated sprites. Heads, arms and
    // plates remain readable while knees and feet tuck behind the table edge.
    CANTEEN_SEATED_TABLE_CROPS.forEach((crop) => {
      this.add.image(0, 0, CANTEEN_MAP_KEY)
        .setOrigin(0)
        .setCrop(crop.left, crop.top, crop.right - crop.left, crop.bottom - crop.top)
        .setDepth(crop.bottom + CANTEEN_WORLD_DEPTH_OFFSET);
    });

    this.createLightNpc(
      CANTEEN_RETURN_NPC_POSITION.x,
      CANTEEN_RETURN_NPC_POSITION.y,
      CANTEEN_RETURN_NPC_SHEET_KEY,
      0,
      CANTEEN_RETURN_NPC_POSITION.y + 120,
      1.65,
      390
    );
    this.createLightNpcFootCollision(
      CANTEEN_RETURN_NPC_POSITION.x,
      CANTEEN_RETURN_NPC_POSITION.y,
      "return-worker"
    );

    const shadowAnimationKey = `${CANTEEN_SHADOW_NPC_SHEET_KEY}-flicker`;
    if (!this.anims.exists(shadowAnimationKey)) {
      this.anims.create({
        key: shadowAnimationKey,
        frames: [0, 0, 1, 0, 0, 0, 2].map((frame) => ({
          key: CANTEEN_SHADOW_NPC_SHEET_KEY,
          frame
        })),
        frameRate: 7,
        repeat: -1,
        repeatDelay: 780
      });
    }
    this.shadowNpcSprite = this.add.sprite(
      CANTEEN_COUNTER_NPC_X[2],
      CANTEEN_COUNTER_NPC_Y,
      CANTEEN_SHADOW_NPC_SHEET_KEY,
      0
    )
      .setOrigin(0.5, 1)
      .setScale(CANTEEN_NPC_DISPLAY_SCALE)
      .setDepth(310)
      .setBlendMode(Phaser.BlendModes.SCREEN);
    if (!this.reducedMotion) this.shadowNpcSprite.play(shadowAnimationKey);
    this.applyCanteenNpcMode(this.currentMode, true);
  }

  private createLightNpc(
    x: number,
    y: number,
    sheetKey: string,
    framePair: number,
    depth: number,
    frameRate: number,
    repeatDelay: number
  ): Phaser.GameObjects.Sprite {
    const animationKey = `${sheetKey}-idle-${framePair}`;
    if (!this.anims.exists(animationKey)) {
      this.anims.create({
        key: animationKey,
        frames: [framePair * 2, framePair * 2 + 1].map((frame) => ({
          key: sheetKey,
          frame
        })),
        frameRate,
        repeat: -1,
        repeatDelay
      });
    }
    const sprite = this.add.sprite(x, y, sheetKey, framePair * 2)
      .setOrigin(0.5, 1)
      .setScale(CANTEEN_NPC_DISPLAY_SCALE)
      .setDepth(depth);
    this.lightNpcSprites.push(sprite);
    if (!this.reducedMotion) {
      this.time.delayedCall(repeatDelay % 540, () => {
        if (sprite.active) sprite.play(animationKey, true);
      });
    }
    return sprite;
  }

  private createLightNpcFootCollision(
    x: number,
    footBottomY: number,
    npcId: string
  ): Phaser.GameObjects.Rectangle {
    const width = RPG_PLAYER_FOOT_COLLISION.width * RPG_PLAYER_DISPLAY_SCALE;
    const height = RPG_PLAYER_FOOT_COLLISION.height * RPG_PLAYER_DISPLAY_SCALE;
    const showCollision = import.meta.env.DEV
      && new URLSearchParams(window.location.search).get("rpgCollision") === "1";
    const collision = this.add.rectangle(
      x,
      footBottomY - height / 2,
      width,
      height,
      showCollision ? 0x58e3ff : 0x000000,
      showCollision ? 0.35 : 0
    ).setDepth(showCollision ? 4902 : footBottomY + 1);
    collision.setData("debugVisible", showCollision);
    collision.setData("npcId", npcId);
    if (showCollision) collision.setStrokeStyle(2, 0xdffaff, 0.95);
    this.obstacles.add(collision);
    this.lightNpcCollisionBodies.push(collision);
    return collision;
  }

  private createInitialNpcInteractions(): void {
    const queuePositions = CANTEEN_COUNTER_NPC_X.flatMap((x) => (
      CANTEEN_QUEUE_NPC_Y.map((y) => ({ x, y }))
    ));
    const seatedPositions = [
      ...CANTEEN_SEATED_NPC_PLACEMENTS,
      ...CANTEEN_SEATED_EXTRA_NPC_PLACEMENTS
    ];
    const shuffledQueue = Phaser.Utils.Array.Shuffle([...queuePositions]);
    const shuffledSeated = Phaser.Utils.Array.Shuffle([...seatedPositions]);
    const counterIndex = Phaser.Math.Between(0, CANTEEN_COUNTER_NPC_X.length - 1);

    const queueTargets = CANTEEN_QUEUE_NPC_DIALOGUE.map((dialogue, index) => {
      const position = shuffledQueue[index];
      return {
        id: `initial-queue-npc-${index}`,
        label: "交谈",
        x: position.x,
        y: position.y,
        proximity: 48,
        kind: "npc" as const,
        dialogue
      };
    });
    const seatedTargets = CANTEEN_SEATED_NPC_DIALOGUE.map((dialogue, index) => {
      const position = shuffledSeated[index];
      return {
        id: `initial-seated-npc-${index}`,
        label: "交谈",
        x: position.x,
        y: position.y - 30,
        width: 72,
        height: 88,
        proximity: 54,
        kind: "npc" as const,
        dialogue
      };
    });
    const counterX = CANTEEN_COUNTER_NPC_X[counterIndex];
    const counterTarget: CanteenInteractionTarget = {
      id: "initial-counter-npc",
      label: "交谈",
      x: counterX,
      y: CANTEEN_COUNTER_NPC_Y,
      stand: { x: counterX, y: 265 },
      width: 64,
      height: 80,
      proximity: 56,
      kind: "npc",
      dialogue: CANTEEN_COUNTER_NPC_DIALOGUE
    };

    this.returnAuntieTarget = {
      id: "return-auntie",
      label: "与收餐口阿姨交谈",
      x: CANTEEN_RETURN_NPC_POSITION.x,
      y: CANTEEN_RETURN_NPC_POSITION.y,
      // This is the clear strip immediately beside the visible return worker.
      stand: { x: 1466, y: 608 },
      width: 46,
      height: 70,
      proximity: 64,
      kind: "npc"
    };

    this.initialNpcInteractionTargets = [
      ...queueTargets,
      ...seatedTargets,
      counterTarget,
      this.returnAuntieTarget
    ];
  }

  private applyCanteenNpcMode(mode: CanteenMode, immediate = false): void {
    const showSceneNpcs = (this.currentPhase !== "exit_blocking" || this.paperBusy)
      && !this.defenseRuntime;
    const showLightNpcs = showSceneNpcs && mode === "light";
    const showShadowNpc = showSceneNpcs && mode === "dark";
    const duration = immediate || this.reducedMotion ? 0 : 180;

    const transitionSprite = (sprite: Phaser.GameObjects.Sprite, visible: boolean) => {
      this.tweens.killTweensOf(sprite);
      if (duration === 0) {
        sprite.setVisible(visible).setAlpha(visible ? 1 : 0);
        return;
      }
      if (visible) sprite.setVisible(true).setAlpha(0);
      this.tweens.add({
        targets: sprite,
        alpha: visible ? 1 : 0,
        duration,
        ease: "Sine.easeInOut",
        onComplete: () => sprite.setVisible(visible)
      });
    };

    this.lightNpcSprites.forEach((sprite) => transitionSprite(sprite, showLightNpcs));
    if (this.shadowNpcSprite) transitionSprite(this.shadowNpcSprite, showShadowNpc);
    this.lightNpcCollisionBodies.forEach((collision) => {
      const body = collision.body as Phaser.Physics.Arcade.StaticBody | null;
      if (body) body.enable = showLightNpcs;
      collision.setVisible(Boolean(collision.getData("debugVisible")) && showLightNpcs);
    });
  }

  private rebuildStaticCollisionBodies(): void {
    this.obstacles.clear(true, true);
    const showCollision = import.meta.env.DEV
      && new URLSearchParams(window.location.search).get("rpgCollision") === "1";
    CANTEEN_STATIC_COLLISION_RECTS.forEach((rect) => {
      const collision = this.add.rectangle(
        (rect.left + rect.right) / 2,
        (rect.top + rect.bottom) / 2,
        rect.right - rect.left,
        rect.bottom - rect.top,
        showCollision ? 0xff3355 : 0x000000,
        showCollision ? 0.24 : 0
      ).setDepth(showCollision ? 4900 : rect.bottom - 20);
      if (showCollision) collision.setStrokeStyle(2, 0xffd4dc, 0.9);
      this.obstacles.add(collision);
    });
  }

  private updateOcclusion(): void {
    const body = this.player.body as Phaser.Physics.Arcade.Body | null;
    const footY = body?.bottom ?? this.player.y;
    const playerBounds = this.player.getBounds();
    const activeIds: string[] = [];
    const softenedIds: string[] = [];

    this.player.setDepth(footY + CANTEEN_WORLD_DEPTH_OFFSET);
    this.occlusionVisuals.forEach((visual) => {
      const horizontalOverlap = playerBounds.right > visual.bounds.left
        && playerBounds.left < visual.bounds.right;
      const actorBehind = horizontalOverlap && footY < visual.sortY - 1;
      const intersectsActor = actorBehind
        && Phaser.Geom.Intersects.RectangleToRectangle(playerBounds, visual.bounds);
      const targetAlpha = intersectsActor ? 0.52 : 1;
      const nextAlpha = this.reducedMotion
        ? targetAlpha
        : Phaser.Math.Linear(visual.image.alpha, targetAlpha, 0.18);

      visual.image
        .setDepth(actorBehind ? this.player.depth + 2 : -900)
        .setVisible(actorBehind)
        .setAlpha(nextAlpha);
      if (actorBehind) activeIds.push(visual.id);
      if (intersectsActor) softenedIds.push(visual.id);
    });

    this.activeOcclusionIds = activeIds;
    this.softenedOcclusionIds = softenedIds;
  }

  private updatePlayerWorldDepth(): void {
    const body = this.player.body as Phaser.Physics.Arcade.Body | null;
    this.player.setDepth((body?.bottom ?? this.player.y) + CANTEEN_WORLD_DEPTH_OFFSET);
  }

  private ensureCanteenTextures(): void {
    if (!this.textures.exists(CANTEEN_TRAY_KEY)) {
      const g = this.add.graphics();
      g.fillStyle(0x172028, 0.28).fillEllipse(12, 14, 22, 5);
      g.fillStyle(0x9eabad).fillRoundedRect(1, 2, 22, 13, 3);
      g.fillStyle(0xe7ece9).fillRoundedRect(3, 4, 18, 9, 2);
      g.lineStyle(1, 0x59686d).strokeRoundedRect(1, 2, 22, 13, 3);
      g.generateTexture(CANTEEN_TRAY_KEY, 24, 18);
      g.destroy();
    }
    if (!this.textures.exists(CANTEEN_DIRTY_TRAY_KEY)) {
      const g = this.add.graphics();
      g.fillStyle(0x172028, 0.3).fillEllipse(12, 14, 22, 5);
      g.fillStyle(0x89989a).fillRoundedRect(1, 2, 22, 13, 3);
      g.fillStyle(0xcbd1c9).fillRoundedRect(3, 4, 18, 9, 2);
      g.fillStyle(0x8a4f28, 0.95)
        .fillEllipse(9, 8, 8, 5)
        .fillCircle(16, 10, 3)
        .fillRect(6, 11, 8, 2);
      g.fillStyle(0xc59142, 0.9).fillCircle(13, 6, 2);
      g.lineStyle(1, 0x4d5b60).strokeRoundedRect(1, 2, 22, 13, 3);
      g.generateTexture(CANTEEN_DIRTY_TRAY_KEY, 24, 18);
      g.destroy();
    }
    CANTEEN_CART_FRAME_KEYS.forEach((key, phase) => {
      if (this.textures.exists(key)) return;
      const g = this.add.graphics();
      // East-facing three-tier stainless-steel trolley. The shelves, stacked
      // trays, corner bumpers, push handle and caster forks remain distinct at
      // the world camera's default zoom.
      g.fillStyle(0x081014, 0.3).fillEllipse(52, 65, 94, 14);
      g.fillStyle(0x10191e).fillRoundedRect(16, 17, 74, 42, 5);
      g.fillStyle(0x667b80).fillRoundedRect(19, 19, 68, 36, 3);
      g.fillStyle(0xc9d5d2)
        .fillRect(22, 21, 62, 5)
        .fillRect(22, 34, 62, 5)
        .fillRect(22, 47, 62, 5);
      g.fillStyle(0x26373b)
        .fillRect(24, 27, 58, 5)
        .fillRect(24, 40, 58, 5);
      g.fillStyle(0xe8ece7)
        .fillRoundedRect(34, 10, 42, 7, 2)
        .fillRoundedRect(39, 5, 32, 6, 2)
        .fillRoundedRect(44, 1, 22, 5, 2);
      g.lineStyle(3, 0x152126)
        .strokeRoundedRect(16, 17, 74, 42, 5)
        .lineBetween(7, 17, 7, 57)
        .lineBetween(7, 17, 18, 17)
        .lineBetween(7, 57, 18, 57)
        .lineBetween(90, 20, 99, 25)
        .lineBetween(90, 55, 99, 50);
      g.lineStyle(2, 0xf3f7f2, 0.65)
        .lineBetween(23, 22, 82, 22)
        .lineBetween(23, 35, 82, 35)
        .lineBetween(23, 48, 82, 48);
      g.fillStyle(0xe6b953)
        .fillRoundedRect(18, 30, 6, 11, 2)
        .fillRoundedRect(82, 30, 6, 11, 2);
      g.fillStyle(0x284958).fillRoundedRect(48, 27, 20, 8, 2);
      g.fillStyle(0x91d4e6).fillRect(51, 29, 14, 2);
      const wheelLift = phase % 2 === 0 ? 0 : 1;
      const spokeOffset = phase < 2 ? 0 : 2;
      [[27, 61], [79, 61]].forEach(([x, y]) => {
        g.fillStyle(0x11191e).fillRoundedRect(x - 5, y - 7, 10, 7, 2);
        g.fillStyle(0x0c1216).fillCircle(x, y - wheelLift, 8);
        g.fillStyle(0x718286).fillCircle(x, y - wheelLift, 4);
        g.fillStyle(0xe5ebe7).fillRect(x - 1, y - 5 + spokeOffset, 2, 10 - spokeOffset * 2);
        g.fillStyle(0xe5ebe7).fillRect(x - 5 + spokeOffset, y - 1, 10 - spokeOffset * 2, 2);
      });
      g.generateTexture(key, 104, 74);
      g.destroy();
    });
    if (!this.textures.exists(CANTEEN_PAPER_KEY)) {
      const g = this.add.graphics();
      // Low-pixel 2.5D paper model: a separate shadow, dark thickness,
      // three folded planes, a raised corner and a tiny 0755 dot-matrix print.
      g.fillStyle(0x0d1c2d, 0.34).fillEllipse(32, 43, 54, 10);
      g.fillStyle(0x60717c).fillPoints([
        new Phaser.Geom.Point(7, 9),
        new Phaser.Geom.Point(48, 6),
        new Phaser.Geom.Point(58, 34),
        new Phaser.Geom.Point(17, 46),
        new Phaser.Geom.Point(5, 36)
      ], true);
      g.fillStyle(0xd7e0e3).fillPoints([
        new Phaser.Geom.Point(5, 5),
        new Phaser.Geom.Point(46, 2),
        new Phaser.Geom.Point(55, 30),
        new Phaser.Geom.Point(15, 41),
        new Phaser.Geom.Point(3, 32)
      ], true);
      g.fillStyle(0xf3f6f3).fillPoints([
        new Phaser.Geom.Point(5, 5),
        new Phaser.Geom.Point(25, 8),
        new Phaser.Geom.Point(15, 41),
        new Phaser.Geom.Point(3, 32)
      ], true);
      g.fillStyle(0xe5ebec).fillPoints([
        new Phaser.Geom.Point(25, 8),
        new Phaser.Geom.Point(46, 2),
        new Phaser.Geom.Point(55, 30),
        new Phaser.Geom.Point(34, 27),
        new Phaser.Geom.Point(15, 41)
      ], true);
      g.fillStyle(0xc1ced4).fillPoints([
        new Phaser.Geom.Point(46, 2),
        new Phaser.Geom.Point(55, 30),
        new Phaser.Geom.Point(41, 18)
      ], true);
      g.lineStyle(2, 0x4a6371, 0.95).strokePoints([
        new Phaser.Geom.Point(5, 5),
        new Phaser.Geom.Point(46, 2),
        new Phaser.Geom.Point(55, 30),
        new Phaser.Geom.Point(15, 41),
        new Phaser.Geom.Point(3, 32)
      ], true);
      g.lineStyle(2, 0x91a4ae, 0.88)
        .lineBetween(25, 8, 15, 41)
        .lineBetween(34, 27, 55, 30)
        .lineBetween(41, 18, 46, 2);

      const digitPixels: Record<string, readonly string[]> = {
        "0": ["111", "101", "101", "101", "111"],
        "5": ["111", "100", "111", "001", "111"],
        "7": ["111", "001", "010", "010", "010"]
      };
      g.fillStyle(0x236f9d, 0.98);
      [..."0755"].forEach((digit, digitIndex) => {
        digitPixels[digit].forEach((row, rowIndex) => {
          [...row].forEach((pixel, columnIndex) => {
            if (pixel === "1") {
              g.fillRect(13 + digitIndex * 8 + columnIndex * 2, 12 + rowIndex * 2, 2, 2);
            }
          });
        });
      });
      g.fillStyle(0x58c7ff, 0.9)
        .fillRect(13, 24, 27, 2)
        .fillRect(13, 29, 18, 2);
      g.fillStyle(0x2f86b4, 0.92)
        .fillRect(44, 23, 3, 3)
        .fillRect(48, 22, 3, 3)
        .fillRect(45, 28, 6, 2);
      g.generateTexture(CANTEEN_PAPER_KEY, 64, 50);
      g.destroy();
    }
    CANTEEN_PAPER_RUN_KEYS.forEach((key, frame) => {
      if (!this.textures.exists(key)) this.generatePaperRunTexture(key, frame);
    });
  }

  private generatePaperRunTexture(key: string, frame: number): void {
    const g = this.add.graphics();
    const lift = frame % 2 === 0 ? 2 : 0;
    const leftKick = frame === 1 ? -5 : frame === 3 ? 4 : 0;
    const rightKick = frame === 1 ? 4 : frame === 3 ? -5 : 0;
    const y = (value: number) => value - lift;

    g.fillStyle(0x0d1c2d, 0.3).fillEllipse(32, 45, frame % 2 === 0 ? 48 : 55, 8);
    // Two folded corners act as tiny legs. Their exaggerated alternating step
    // remains readable after the whole-map camera zooms out.
    g.fillStyle(0x41535e)
      .fillPoints([
        new Phaser.Geom.Point(16, y(36)),
        new Phaser.Geom.Point(24, y(38)),
        new Phaser.Geom.Point(21 + leftKick, 47),
        new Phaser.Geom.Point(14 + leftKick, 46)
      ], true)
      .fillPoints([
        new Phaser.Geom.Point(39, y(34)),
        new Phaser.Geom.Point(48, y(33)),
        new Phaser.Geom.Point(50 + rightKick, 44),
        new Phaser.Geom.Point(43 + rightKick, 46)
      ], true);
    g.fillStyle(0x60717c).fillPoints([
      new Phaser.Geom.Point(7, y(9)),
      new Phaser.Geom.Point(48, y(6)),
      new Phaser.Geom.Point(58, y(34)),
      new Phaser.Geom.Point(17, y(46)),
      new Phaser.Geom.Point(5, y(36))
    ], true);
    g.fillStyle(0xd7e0e3).fillPoints([
      new Phaser.Geom.Point(5, y(5)),
      new Phaser.Geom.Point(46, y(2)),
      new Phaser.Geom.Point(55, y(30)),
      new Phaser.Geom.Point(15, y(41)),
      new Phaser.Geom.Point(3, y(32))
    ], true);
    g.fillStyle(0xf3f6f3).fillPoints([
      new Phaser.Geom.Point(5, y(5)),
      new Phaser.Geom.Point(25, y(8)),
      new Phaser.Geom.Point(15, y(41)),
      new Phaser.Geom.Point(3, y(32))
    ], true);
    g.fillStyle(0xe5ebec).fillPoints([
      new Phaser.Geom.Point(25, y(8)),
      new Phaser.Geom.Point(46, y(2)),
      new Phaser.Geom.Point(55, y(30)),
      new Phaser.Geom.Point(34, y(27)),
      new Phaser.Geom.Point(15, y(41))
    ], true);
    g.fillStyle(0xc1ced4).fillPoints([
      new Phaser.Geom.Point(46, y(2)),
      new Phaser.Geom.Point(55, y(30)),
      new Phaser.Geom.Point(41, y(18))
    ], true);
    g.lineStyle(2, 0x4a6371, 0.95).strokePoints([
      new Phaser.Geom.Point(5, y(5)),
      new Phaser.Geom.Point(46, y(2)),
      new Phaser.Geom.Point(55, y(30)),
      new Phaser.Geom.Point(15, y(41)),
      new Phaser.Geom.Point(3, y(32))
    ], true);
    g.lineStyle(2, 0x91a4ae, 0.88)
      .lineBetween(25, y(8), 15, y(41))
      .lineBetween(34, y(27), 55, y(30));
    g.fillStyle(0x236f9d, 0.98)
      .fillRect(13, y(13), 30, 3)
      .fillRect(13, y(20), 24, 2)
      .fillRect(13, y(25), 29, 2);
    g.fillStyle(0x58c7ff, 0.92)
      .fillRect(45, y(22), 3, 3)
      .fillRect(49, y(21), 3, 3)
      .fillRect(46, y(28), 6, 2);
    g.generateTexture(key, 64, 50);
    g.destroy();
  }

  private createTrays(): void {
    const shuffledPositions = Phaser.Utils.Array.Shuffle(
      CANTEEN_TRAY_SLOTS.map((slot) => ({ ...slot, stand: { ...slot.stand } }))
    ).slice(0, CANTEEN_TRAYS.length);
    CANTEEN_TRAYS.forEach((tray, index) => {
      const position = shuffledPositions[index];
      const cleanImage = this.add.image(0, 0, CANTEEN_TRAY_KEY)
        .setScale(0.75)
        .setAngle(90);
      const dirtyImage = this.add.image(0, 0, CANTEEN_DIRTY_TRAY_KEY)
        .setScale(0.75)
        .setAngle(90)
        .setVisible(false);
      const sparkles = [
        this.add.circle(-9, -7, 2, 0x7ce7ff, 0.95),
        this.add.circle(8, -9, 1.5, 0xbbefff, 0.9),
        this.add.circle(11, 4, 1.5, 0x4fcaff, 0.92)
      ];
      sparkles.forEach((sparkle, sparkleIndex) => {
        sparkle.setVisible(false);
        this.tweens.add({
          targets: sparkle,
          y: sparkle.y - 4 - sparkleIndex,
          alpha: { from: 0.22, to: 1 },
          duration: 430 + sparkleIndex * 90,
          yoyo: true,
          repeat: -1,
          ease: "Stepped"
        });
      });
      const container = this.add.container(
        position.x,
        position.y,
        [cleanImage, dirtyImage, ...sparkles]
      )
        .setDepth(position.y + 110)
        .setSize(30, 24)
        .setInteractive({ useHandCursor: true });
      const target: CanteenInteractionTarget = {
        id: tray.id,
        label: "桌上的餐盘",
        x: position.x,
        y: position.y,
        stand: position.stand,
        width: 20,
        height: 28,
        proximity: 54,
        kind: "tray",
        value: tray.id
      };
      container.on("pointerdown", () => {
        this.triggerPointerTarget(target);
      });
      this.trayInteractionTargets.set(tray.id, target);
      this.trayVisuals.set(tray.id, { container, cleanImage, dirtyImage, sparkles });
    });
  }

  private applyPlayerCollisionBody(): void {
    const body = this.player.body as Phaser.Physics.Arcade.Body | null;
    if (!body) return;
    body.enable = true;
    body
      .setSize(RPG_PLAYER_FOOT_COLLISION.width, RPG_PLAYER_FOOT_COLLISION.height)
      .setOffset(RPG_PLAYER_FOOT_COLLISION.offsetX, RPG_PLAYER_FOOT_COLLISION.offsetY);
  }

  private updatePlayerCollisionDebug(): void {
    if (!this.playerCollisionDebug) return;
    const body = this.player.body as Phaser.Physics.Arcade.Body | null;
    if (!body) return;
    this.playerCollisionDebug
      .setPosition(body.center.x, body.center.y)
      .setSize(body.width, body.height)
      .setDisplaySize(body.width, body.height);
  }

  private createCarts(): void {
    Object.values(CANTEEN_CARTS).forEach((definition) => {
      const { exitId, x, y } = definition;
      const glow = this.add.circle(x, y, 47, 0x2aaeff, 0.12)
        .setStrokeStyle(4, 0x7ad8ff, 0.9)
        .setDepth(y + 19)
        .setVisible(false);
      const cart = this.add.image(x, y, CANTEEN_CART_FRAME_KEYS[0])
        .setDepth(y + 20)
        .setVisible(false)
        .setInteractive({ useHandCursor: true });
      // Carts are visual-only. Pushing never enlarges the player's collider,
      // and the cart silhouette itself does not block traversal.
      this.applyCartOrientation(cart, definition);
      cart.on("pointerdown", () => {
        const target = CANTEEN_INTERACTION_TARGETS.find((candidate) => candidate.id === `cart_${exitId}`);
        if (target) this.triggerPointerTarget(target);
      });
      this.cartVisuals.set(exitId, cart);
      this.exitGlows.set(exitId, glow);
      this.tweens.add({
        targets: glow,
        scale: { from: 0.82, to: 1.18 },
        alpha: { from: 0.3, to: 0.9 },
        duration: 1000,
        yoyo: true,
        repeat: -1,
        ease: "Sine.easeInOut"
      });
    });
  }

  private createPickupWindowSigns(): void {
    CANTEEN_PICKUP_WINDOWS.forEach((window) => {
      const plate = this.add.rectangle(0, 0, 154, 38, 0x173544, 0.98)
        .setStrokeStyle(3, 0xe2c866, 0.96);
      const badge = this.add.rectangle(-59, 0, 28, 28, 0xe2c866, 1)
        .setStrokeStyle(2, 0x3b3013, 1);
      const digit = this.add.text(-59, 0, window.value, {
        color: "#172128",
        fontFamily: "monospace",
        fontSize: "21px",
        fontStyle: "bold"
      }).setOrigin(0.5);
      const label = this.add.text(17, 0, "号取餐窗口", {
        color: "#fff7df",
        fontFamily: "monospace",
        fontSize: "15px",
        fontStyle: "bold"
      }).setOrigin(0.5);
      const sign = this.add.container(window.x, window.y + 15, [plate, badge, digit, label])
        .setDepth(1705)
        .setSize(160, 44);

      const dropBounds = getRpgDropBounds(window);
      const dropFrame = this.add.rectangle(
        window.x,
        window.y,
        dropBounds.width,
        dropBounds.height,
        0x173544,
        0.18
      ).setStrokeStyle(4, 0x7ad8ff, 1)
        .setDepth(1712)
        .setVisible(false);
      const dropLabel = this.add.text(
        window.x,
        window.y - dropBounds.height / 2 - 7,
        `拖入 0755 · ${window.value}号`,
        {
          color: "#e9fbff",
          backgroundColor: "#102b3bee",
          fontFamily: "monospace",
          fontSize: "12px",
          fontStyle: "bold",
          padding: { x: 6, y: 3 }
        }
      ).setOrigin(0.5, 1)
        .setDepth(1713)
        .setVisible(false);

      const guide = this.add.rectangle(0, -21, 3, 18, 0x7ad8ff, 0.82);
      const ring = this.add.circle(0, 0, 21, 0x103347, 0.32)
        .setStrokeStyle(3, 0x7ad8ff, 0.96);
      const standDigit = this.add.text(0, 0, window.value, {
        color: "#fff7df",
        fontFamily: "monospace",
        fontSize: "17px",
        fontStyle: "bold"
      }).setOrigin(0.5);
      const standLabel = this.add.text(31, 0, "站这里 · 再拖票", {
        color: "#e9fbff",
        backgroundColor: "#102b3bdd",
        fontFamily: "monospace",
        fontSize: "12px",
        padding: { x: 5, y: 3 }
      }).setOrigin(0, 0.5);
      const standMarker = this.add.container(
        window.stand!.x,
        window.stand!.y,
        [guide, ring, standDigit, standLabel]
      ).setDepth(1604).setSize(136, 48);

      this.pickupWindowVisuals.set(window.id, { sign, standMarker, dropFrame, dropLabel });
    });
  }

  private createPaper(): void {
    const steamWindow = CANTEEN_PICKUP_WINDOWS[2];
    this.paper = this.add.image(steamWindow.x, steamWindow.y, CANTEEN_PAPER_KEY)
      .setDepth(2100)
      .setVisible(false);
    this.paperFloatTween = this.tweens.add({
      targets: this.paper,
      scaleY: { from: 0.96, to: 1.04 },
      angle: { from: -3, to: 3 },
      duration: 720,
      yoyo: true,
      repeat: -1,
      ease: "Sine.easeInOut",
      paused: true
    });
  }

  private prepareEntryPaperQueuePose(): void {
    const queueTail = CANTEEN_SERVICE_WINDOWS[3].queueNpcPositions.at(-1)!;
    this.paperFloatTween.pause();
    this.paper
      .setTexture(CANTEEN_PAPER_KEY)
      .setPosition(queueTail.x + 18, queueTail.y + 16)
      .setScale(0.76)
      .setAngle(-2)
      .setAlpha(1)
      .setDepth(queueTail.y + CANTEEN_WORLD_DEPTH_OFFSET + 2)
      .setVisible(true);
    this.entryPaperIdleTween = this.tweens.add({
      targets: this.paper,
      y: this.paper.y - 3,
      angle: { from: -2, to: 2 },
      duration: this.reducedMotion ? 620 : 900,
      yoyo: true,
      repeat: -1,
      ease: "Sine.easeInOut"
    });
  }

  private startEntryPaperDiscovery(): void {
    if (!this.entryPaperPending || this.entryPaperTriggered) return;
    this.entryPaperTriggered = true;
    this.paperBusy = true;
    this.dialogueLocked = true;
    this.player.setVelocity(0, 0);
    this.playerAnimator.update(new Phaser.Math.Vector2(), this.time.now);
    this.entryPaperIdleTween?.pause();

    const camera = this.cameras.main;
    camera.stopFollow().setDeadzone(0, 0);
    const discoveryFocusX = Phaser.Math.Linear(this.paper.x, this.player.x, 0.24);
    const discoveryFocusY = Phaser.Math.Linear(this.paper.y, this.player.y, 0.38);
    camera.pan(
      discoveryFocusX,
      discoveryFocusY,
      this.reducedMotion ? 120 : 520,
      "Sine.easeInOut"
    );
    zoomRpgCameraTo(this, 1.22, this.reducedMotion ? 120 : 520, "Sine.easeInOut", camera);
    this.time.delayedCall(this.reducedMotion ? 160 : 820, () => this.playEntryPaperSurprise());
  }

  private playEntryPaperSurprise(): void {
    if (!this.paper.active) return;
    const originX = this.paper.x;
    const originY = this.paper.y;
    const alarm = this.add.text(originX, originY - 32, "!", {
      color: "#fff7df",
      backgroundColor: "#173544ee",
      fontFamily: "monospace",
      fontSize: "22px",
      fontStyle: "bold",
      padding: { x: 7, y: 2 }
    }).setOrigin(0.5, 1).setDepth(5002).setAlpha(0);

    this.bridge.emit("canteen_entry_paper_spotted");
    this.tweens.add({
      targets: alarm,
      alpha: 1,
      y: alarm.y - 5,
      duration: this.reducedMotion ? 60 : 110,
      yoyo: true,
      hold: this.reducedMotion ? 80 : 300,
      onComplete: () => alarm.destroy()
    });
    this.tweens.add({
      targets: this.paper,
      y: originY - 12,
      duration: this.reducedMotion ? 55 : 105,
      yoyo: true,
      ease: "Back.easeOut",
      onComplete: () => {
        this.paper.setY(originY);
        this.tweens.add({
          targets: this.paper,
          x: originX - 6,
          duration: this.reducedMotion ? 45 : 62,
          yoyo: true,
          repeat: 3,
          onComplete: () => this.paper.setX(originX)
        });
      }
    });

    this.time.delayedCall(this.reducedMotion ? 120 : 360, () => {
      this.showEntrySpeechBubble("玩家：找到了。", this.player.x, this.player.y - 72, 108, 1050);
    });
    this.time.delayedCall(this.reducedMotion ? 620 : 1420, () => {
      this.showEntrySpeechBubble("纸条：！", this.paper.x + 43, this.paper.y - 32, 70, 760);
    });
    this.time.delayedCall(this.reducedMotion ? 1120 : 2380, () => this.playEntryPaperEscapeRoute());
  }

  private showEntrySpeechBubble(
    text: string,
    x: number,
    y: number,
    width: number,
    durationMs: number
  ): void {
    const panel = this.add.rectangle(0, 0, width, 30, 0xfff6df, 0.97)
      .setStrokeStyle(2, 0x243947, 1);
    const tail = this.add.triangle(-width * 0.2, 20, 0, 0, 10, 0, 3, 9, 0xfff6df, 1)
      .setStrokeStyle(1, 0x243947, 1);
    const label = this.add.text(0, 0, text, {
      color: "#172932",
      fontFamily: "monospace",
      fontSize: "13px",
      fontStyle: "bold"
    }).setOrigin(0.5);
    const bubble = this.add.container(x, y, [panel, tail, label])
      .setDepth(5001)
      .setAlpha(0)
      .setScale(0.86);
    this.tweens.add({
      targets: bubble,
      alpha: 1,
      scale: 1,
      duration: this.reducedMotion ? 60 : 110,
      ease: "Back.easeOut"
    });
    this.time.delayedCall(durationMs, () => {
      if (!bubble.active) return;
      this.tweens.add({
        targets: bubble,
        alpha: 0,
        duration: this.reducedMotion ? 50 : 120,
        onComplete: () => bubble.destroy(true)
      });
    });
  }

  private playEntryPaperEscapeRoute(): void {
    if (!this.paper.active) return;
    this.bridge.emit("canteen_entry_paper_escape_started");
    this.entryPaperIdleTween?.stop();
    this.entryPaperIdleTween = null;
    this.paper
      .setDepth(2100)
      .setScale(0.82)
      .setAngle(-6)
      .setTexture(CANTEEN_PAPER_RUN_KEYS[0]);

    const camera = this.cameras.main;
    camera.startFollow(this.paper, true, 0.075, 0.075, 0, 24).setDeadzone(100, 68);
    zoomRpgCameraTo(this, 1.22, this.reducedMotion ? 100 : 260, "Sine.easeOut", camera);
    let frame = 0;
    this.entryPaperRunTimer?.remove(false);
    this.entryPaperRunTimer = this.time.addEvent({
      delay: this.reducedMotion ? 120 : 78,
      loop: true,
      callback: () => {
        if (!this.paper.active || !this.paper.visible) return;
        frame = (frame + 1) % CANTEEN_PAPER_RUN_KEYS.length;
        this.paper.setTexture(CANTEEN_PAPER_RUN_KEYS[frame]);
        if (frame % 2 === 0) this.spawnEntryPaperAfterimage();
      }
    });

    const duration = (normal: number) => this.reducedMotion ? Math.max(120, normal * 0.62) : normal;
    this.tweens.add({
      targets: this.paper,
      x: 944,
      y: 300,
      duration: duration(190),
      ease: "Sine.easeIn",
      onComplete: () => {
        this.tweens.add({
          targets: this.paper,
          x: 186,
          y: 274,
          angle: -9,
          duration: duration(1120),
          ease: "Linear",
          onComplete: () => {
            this.tweens.add({
              targets: this.paper,
              x: 92,
              y: 252,
              angle: 68,
              duration: duration(260),
              ease: "Quad.easeOut",
              onComplete: () => {
                this.time.delayedCall(duration(200), () => {
                  this.tweens.add({
                    targets: this.paper,
                    x: 166,
                    y: 252,
                    angle: -10,
                    duration: duration(230),
                    ease: "Quad.easeInOut",
                    onComplete: () => {
                      this.tweens.add({
                        targets: this.paper,
                        x: 166,
                        y: 82,
                        angle: -88,
                        duration: duration(430),
                        ease: "Cubic.easeIn",
                        onComplete: () => {
                          this.tweens.add({
                            targets: this.paper,
                            y: -56,
                            duration: duration(220),
                            ease: "Cubic.easeIn",
                            onComplete: () => this.finishEntryPaperEscape()
                          });
                        }
                      });
                    }
                  });
                });
              }
            });
          }
        });
      }
    });
  }

  private spawnEntryPaperAfterimage(): void {
    const ghost = this.add.image(this.paper.x, this.paper.y, this.paper.texture.key)
      .setScale(this.paper.scaleX, this.paper.scaleY)
      .setAngle(this.paper.angle)
      .setAlpha(0.24)
      .setTint(0xbdefff)
      .setDepth(this.paper.depth - 1);
    this.tweens.add({
      targets: ghost,
      alpha: 0,
      scaleX: ghost.scaleX * 0.82,
      scaleY: ghost.scaleY * 0.82,
      duration: this.reducedMotion ? 90 : 220,
      onComplete: () => ghost.destroy()
    });
  }

  private finishEntryPaperEscape(): void {
    this.entryPaperRunTimer?.remove(false);
    this.entryPaperRunTimer = null;
    this.paper.setVisible(false).setTexture(CANTEEN_PAPER_KEY).setAngle(0).setScale(1);
    const camera = this.cameras.main;
    camera.stopFollow().setDeadzone(0, 0);
    const cameraPauseMs = this.reducedMotion ? 100 : 500;
    const cameraReturnMs = this.reducedMotion ? 160 : 720;
    this.showEntrySystemPrompts(
      canteenContent.entryDialogue,
      cameraPauseMs + cameraReturnMs + 40
    );
    this.time.delayedCall(cameraPauseMs, () => {
      camera.pan(this.player.x, this.player.y, cameraReturnMs, "Sine.easeInOut");
      zoomRpgCameraTo(this, 1, cameraReturnMs, "Sine.easeInOut", camera);
      this.time.delayedCall(cameraReturnMs + 40, () => {
        this.entryPaperPending = false;
        this.paperBusy = false;
        this.dialogueLocked = false;
        camera.startFollow(this.player, true, 0.13, 0.13, 0, 24).setDeadzone(250, 150);
        this.bridge.emit("rpg_canteen_entry_paper_escape_completed");
      });
    });
  }

  private showEntrySystemPrompts(lines: readonly string[], startDelayMs = 0): void {
    lines.forEach((line, index) => {
      this.time.delayedCall(startDelayMs + index * ENTRY_DIALOGUE_STEP_MS, () => {
        const prompt = this.add.text(
          RPG_LOGICAL_WIDTH / 2,
          RPG_LOGICAL_HEIGHT - 86,
          line,
          {
            color: "#f5fbff",
            backgroundColor: "#102633ee",
            fontFamily: "monospace",
            fontSize: "15px",
            fontStyle: "bold",
            padding: { x: 14, y: 9 },
            stroke: "#07131a",
            strokeThickness: 2
          }
        ).setOrigin(0.5, 1)
          .setScrollFactor(0)
          .setDepth(6000)
          .setAlpha(0);
        this.tweens.add({
          targets: prompt,
          alpha: 1,
          y: prompt.y - 4,
          duration: this.reducedMotion ? 70 : 120,
          yoyo: true,
          hold: ENTRY_DIALOGUE_STEP_MS - (this.reducedMotion ? 190 : 280),
          onComplete: () => prompt.destroy()
        });
      });
    });
  }

  private createWorldHotspots(): void {
    const hotspotBounds: Record<string, { x: number; y: number; width: number; height: number }> = {
      ordering_kiosk: { x: 790, y: 238, width: 150, height: 92 },
      ...Object.fromEntries(CANTEEN_PICKUP_WINDOWS.map((window) => [
        window.id,
        {
          x: window.x,
          y: (window.y + window.stand!.y) / 2,
          width: 166,
          height: 112
        }
      ])),
      southeast_exit: { x: 1380, y: 835, width: 170, height: 150 }
    };
    Object.entries(hotspotBounds).forEach(([targetId, bounds]) => {
      const target = CANTEEN_INTERACTION_TARGETS.find((candidate) => candidate.id === targetId);
      if (!target) return;
      this.add.zone(bounds.x, bounds.y, bounds.width, bounds.height)
        .setDepth(bounds.y + 1)
        .setInteractive({ useHandCursor: true })
        .on("pointerdown", () => this.triggerPointerTarget(target));
    });

    const drinkPuzzleHotspots: Array<{
      target: CanteenInteractionTarget;
      x?: number;
      y?: number;
      width: number;
      height: number;
    }> = [
      ...CANTEEN_DRINK_MACHINES.map((target) => ({ target, width: 46, height: 104 })),
      ...CANTEEN_DRINK_MACHINES.map((target) => ({
        target,
        x: target.stand?.x ?? target.x,
        y: target.stand?.y ?? target.y,
        width: 42,
        height: 68
      })),
      { target: CANTEEN_DRINK_SHELF, width: 260, height: 132 },
      { target: CANTEEN_MIX_STATION, width: 420, height: 170 },
      { target: CANTEEN_PROMO_BOARD, width: 150, height: 96 },
      { target: CANTEEN_QUEUE_COLUMN_THREE, width: 88, height: 100 }
    ];
    drinkPuzzleHotspots.forEach(({ target, x = target.x, y = target.y, width, height }) => {
      this.add.zone(x, y, width, height)
        .setDepth(y + 2)
        .setInteractive({ useHandCursor: true })
        .on("pointerdown", () => this.triggerPointerTarget(target));
    });
  }

  private createPromoBoardVisual(): void {
    this.promoEmptyCup = this.add.image(
      CANTEEN_PROMO_BOARD.x,
      CANTEEN_PROMO_BOARD.y,
      CANTEEN_PROMO_BOARD_EMPTY_KEY
    ).setScale(0.5).setDepth(1698).setVisible(false);

    this.promoPanel = this.add.image(
      CANTEEN_PROMO_BOARD.x,
      CANTEEN_PROMO_BOARD.y,
      CANTEEN_PROMO_BOARD_ACTIVE_KEY
    ).setScale(0.5).setDepth(1700).setVisible(false);

    if (!this.anims.exists(CANTEEN_PROMO_INSERT_ANIM_KEY)) {
      this.anims.create({
        key: CANTEEN_PROMO_INSERT_ANIM_KEY,
        frames: this.anims.generateFrameNumbers(CANTEEN_PROMO_DRINK_INSERT_KEY, { start: 0, end: 3 }),
        frameRate: 10,
        repeat: 0
      });
    }
    if (!this.anims.exists(CANTEEN_PROMO_BUBBLE_ANIM_KEY)) {
      this.anims.create({
        key: CANTEEN_PROMO_BUBBLE_ANIM_KEY,
        frames: this.anims.generateFrameNumbers(CANTEEN_PROMO_FX_KEY, { start: 0, end: 2 }),
        frameRate: 6,
        repeat: -1
      });
    }
    this.promoDrinkInsert = this.add.sprite(
      CANTEEN_PROMO_BOARD.x - 14,
      CANTEEN_PROMO_BOARD.y + 8,
      CANTEEN_PROMO_DRINK_INSERT_KEY,
      0
    ).setScale(1.2).setDepth(1703).setVisible(false);
    this.promoBubbleLoop = this.add.sprite(
      CANTEEN_PROMO_BOARD.x - 15,
      CANTEEN_PROMO_BOARD.y + 2,
      CANTEEN_PROMO_FX_KEY,
      0
    ).setScale(0.56).setDepth(1704).setVisible(false);

    this.promoDropFrame = this.add.rectangle(
      CANTEEN_PROMO_BOARD.x,
      CANTEEN_PROMO_BOARD.y,
      150,
      100,
      0x3bc5ef,
      0.08
    ).setStrokeStyle(3, 0x6fe2ff, 0.92).setDepth(1702).setVisible(false);
  }

  private createDarkModeLayer(): void {
    this.darkOverlay = this.add.rectangle(
      CANTEEN_INTERIOR_WORLD.width / 2,
      CANTEEN_INTERIOR_WORLD.height / 2,
      CANTEEN_INTERIOR_WORLD.width,
      CANTEEN_INTERIOR_WORLD.height,
      0x071127,
      0.56
    ).setDepth(1500).setAlpha(this.currentMode === "dark" ? 0.56 : 0);
    const fiberPoints = [
      { x: CANTEEN_PICKUP_WINDOWS[2].x, y: CANTEEN_PICKUP_WINDOWS[2].y },
      { x: 82, y: 250 }, { x: 1380, y: 850 }, { x: 1235, y: 227 }
    ];
    this.modeFibers = fiberPoints.map((point, index) => {
      const fiber = this.add.circle(point.x, point.y, 2 + index % 2, 0x8be6ff, 0.92)
        .setDepth(1602)
        .setVisible(this.currentMode === "dark");
      this.tweens.add({
        targets: fiber,
        x: point.x + (index % 2 === 0 ? 11 : -9),
        y: point.y - 9,
        alpha: { from: 0.2, to: 0.95 },
        duration: 420 + index * 37,
        yoyo: true,
        repeat: -1,
        ease: "Stepped"
      });
      return fiber;
    });
  }

  private createPrompt(): void {
    this.promptText = this.add.text(RPG_HUD_LAYOUT.centerX, RPG_HUD_LAYOUT.promptBottomY, "", {
      color: "#fff7df",
      fontFamily: "monospace",
      fontSize: "13px",
      stroke: "#07111c",
      strokeThickness: 4,
      align: "center"
    }).setOrigin(0.5, 1).setScrollFactor(0).setDepth(5200).setVisible(false);
  }

  private handleBridgeEvent(name: string, payload?: Record<string, unknown>): void {
    if (!this.sys?.isActive()) return;
    if (name === "rpg_direction_changed") {
      this.virtualDirection = { x: Number(payload?.x) || 0, y: Number(payload?.y) || 0 };
      return;
    }
    if (name === "rpg_interact") {
      this.interactRequested = true;
      return;
    }
    if (name === "rpg_inventory_drop_requested") {
      this.handleInventoryDrop(payload);
      return;
    }
    if (name === "rpg_canteen_toggle_mode") {
      this.requestModeToggle();
      return;
    }
    if (name === "canteen_mode_changed") {
      this.playModeTransition(String(payload?.mode) === "dark" ? "dark" : "light");
      return;
    }
    if (name === "canteen_tray_task_started") {
      return;
    }
    if (name === "canteen_tray_collect_wrong_mode") {
      this.showFeedback(canteenContent.tray.collectWrongMode, "system");
      return;
    }
    if (name === "canteen_tray_hands_full") {
      this.showFeedback(canteenContent.tray.handsFull, "system");
      return;
    }
    if (name === "canteen_tray_empty_handed") {
      this.showFeedback(canteenContent.tray.emptyHanded, "narrator");
      return;
    }
    if (name === "canteen_tray_collected") {
      const trayId = String(payload?.trayId ?? "");
      this.animateTrayCollection(trayId);
      return;
    }
    if (name === "canteen_tray_delivered") {
      const target = payload?.target === true;
      const completed = payload?.completed === true;
      const response = target
        ? canteenContent.tray.correctReturn
        : canteenContent.tray.wrongReturn;
      this.queueDialogue(
        completed ? [response, ...canteenContent.tray.completionDialogue] : [response]
      );
      return;
    }
    if (name === "canteen_trays_completed") return;
    if (name === "canteen_queue_challenge_read") {
      this.queueDialogue(canteenContent.drinks.queueDialogue);
      return;
    }
    if (name === "canteen_drink_collected") {
      return;
    }
    if (name === "canteen_drink_already_owned") {
      this.showFeedback(canteenContent.drinks.alreadyOwned, "system");
      return;
    }
    if (name === "canteen_drink_shelf_read") {
      this.showFeedback(`${canteenContent.drinks.shelfPrompt}\n${canteenContent.drinks.shelfOrder}`, "system", 3000);
      return;
    }
    if (name === "canteen_mix_ingredient_added") {
      this.refreshMixerPanel();
      return;
    }
    if (name === "canteen_mix_failed") {
      this.closeMixerPanel();
      this.showFeedback(canteenContent.drinks.wrongMix, "system", 2600);
      return;
    }
    if (name === "canteen_mix_solved") {
      this.closeMixerPanel();
      this.showFeedback(canteenContent.drinks.correctMix, "success", 2600);
      return;
    }
    if (name === "canteen_mix_missing_drink") {
      this.showFeedback(canteenContent.drinks.ingredientMissing, "system");
      return;
    }
    if (name === "canteen_bad_drink_consumed") {
      this.queueDialogue(canteenContent.drinks.badDrinkConsumed);
      return;
    }
    if (name === "canteen_promo_activated") {
      this.animatePromoAndQueueShift();
      return;
    }
    if (name === "canteen_queue_gap_opened") return;
    if (name === "canteen_menu_dark_clue_read") {
      return;
    }
    if (name === "canteen_menu_order_locked") {
      this.showFeedback(canteenContent.menu.orderLocked, "system");
      return;
    }
    if (name === "canteen_order_already_active") {
      this.showFeedback(canteenContent.menu.alreadyActive, "system");
      return;
    }
    if (name === "canteen_order_wrong") {
      this.closeMenuPanel();
      this.queueDialogue(canteenContent.menu.wrongGeneric);
      return;
    }
    if (name === "canteen_order_solved") {
      this.closeMenuPanel();
      this.queueDialogue(canteenContent.menu.correct);
      return;
    }
    if (name === "canteen_pickup_missing_ticket") {
      this.showFeedback(canteenContent.pickup.noTicket, "system");
      return;
    }
    if (name === "canteen_pickup_dark_clue_read") {
      this.queueDialogue([canteenContent.pickup.darkClueRead]);
      return;
    }
    if (name === "canteen_pickup_dark_window_empty") {
      this.showFeedback(canteenContent.pickup.darkEmpty, "system");
      return;
    }
    if (name === "canteen_pickup_order_locked") {
      this.showFeedback(canteenContent.pickup.orderLocked, "system");
      return;
    }
    if (name === "canteen_pickup_wrong_window") {
      this.showFeedback(canteenContent.pickup.wrongWindow, "system");
      return;
    }
    if (name === "canteen_correct_meal_time_error") {
      this.queueDialogue(canteenContent.pickup.timeError);
      return;
    }
    if (name === "canteen_wrong_meal_collected") {
      const optionId = String(payload?.optionId ?? "") as keyof typeof canteenContent.pickup.foodCollected;
      this.showFeedback(canteenContent.pickup.foodCollected[optionId] ?? "窗口正常出餐。", "success", 2800);
      return;
    }
    if (name === "canteen_pickup_solved") {
      this.animatePaperBurst();
      return;
    }
    if (name === "canteen_defense_completed") {
      this.animateDefenseVictory(() => {
        this.finishDefense();
        this.queueDialogue(canteenContent.blocking.escapeDialogue, () => {
          this.beginCanteenExit();
        }, 1200);
      });
      return;
    }
    if (name === "canteen_exit_dark_clue_read") {
      return;
    }
    if (name === "canteen_exit_dark_clue_missed") {
      this.showFeedback(canteenContent.blocking.darkClueMissed, "system");
      return;
    }
    if (name === "canteen_exit_block_unidentified") {
      this.showFeedback(canteenContent.blocking.orderLocked, "system");
      this.finishCartMotion(String(payload?.exitId ?? "west") as CanteenExitId);
      return;
    }
    if (name === "canteen_exit_block_wrong") {
      const exitId = String(payload?.exitId ?? "west") as CanteenExitId;
      this.animateValidatedCartPush(exitId, () => {
        this.animateWrongBlock(exitId, String(payload?.expected ?? "west") as CanteenExitId);
      });
      return;
    }
    if (name === "canteen_exit_block_rejected") {
      this.finishCartMotion(String(payload?.exitId ?? "west") as CanteenExitId);
      return;
    }
    if (name === "canteen_exit_blocked") {
      const exitId = String(payload?.exitId ?? "west") as CanteenExitId;
      this.animateValidatedCartPush(exitId, () => {
        this.animateCorrectBlock(exitId, Number(payload?.blockHits) || 1, false);
      });
      return;
    }
    if (name === "canteen_exit_blocking_completed") {
      const exitId = String(payload?.exitId ?? "steam") as CanteenExitId;
      this.animateValidatedCartPush(exitId, () => this.animateCorrectBlock(exitId, 3, true));
    }
  }

  private requestModeToggle(): void {
    if (this.cartPushBusy || this.defenseRuntime) return;
    const state = this.bridge.getState();
    if (!["tray_search", "drink_mix", "menu_order", "pickup_search", "chase_ready"].includes(state.canteenHunt.phase)) return;
    const mode: CanteenMode = state.canteenHunt.mode === "light" ? "dark" : "light";
    this.bridge.emit("rpg_canteen_mode_requested", { mode });
  }

  private playModeTransition(mode: CanteenMode): void {
    this.currentMode = mode;
    this.applyCanteenNpcMode(mode);
    const duration = this.reducedMotion ? 120 : 450;
    this.tweens.killTweensOf(this.darkOverlay);
    this.tweens.add({
      targets: this.darkOverlay,
      alpha: mode === "dark" ? 0.56 : 0,
      duration,
      ease: "Sine.easeInOut"
    });
    this.modeFibers.forEach((fiber, index) => {
      fiber.setVisible(true).setAlpha(mode === "dark" ? 0 : fiber.alpha);
      this.tweens.add({
        targets: fiber,
        alpha: mode === "dark" ? 0.9 : 0,
        duration: this.reducedMotion ? 120 : 220,
        delay: this.reducedMotion ? 0 : Math.min(80, index * 9),
        onComplete: () => fiber.setVisible(mode === "dark")
      });
    });
    this.refreshMenuPanel();
    this.bridge.emit(mode === "dark" ? "canteen_dark_mode_enabled" : "canteen_light_mode_enabled");
  }

  private getActiveTargets(state: GameState): CanteenInteractionTarget[] {
    // Ordinary exploration has no story puzzle targets. Keep the physical exit
    // available so the scene reads as a normal visit and has a deterministic return.
    if (!state.canteenHunt.active) {
      return CANTEEN_INTERACTION_TARGETS.filter((target) => target.kind === "exit");
    }
    if (this.entryPaperPending) return [];
    if (!canPlayCanteenSideGames(state)) return [];

    const targets: CanteenInteractionTarget[] = [
      ...CANTEEN_INTERACTION_TARGETS.filter((target) => target.kind === "exit")
    ];
    if (
      state.canteenHunt.phase === "menu_order"
      || (state.canteenHunt.phase === "pickup_search"
        && state.canteenHunt.mode === "dark"
        && !state.canteenHunt.menuDarkClueRead)
    ) {
      targets.push(...CANTEEN_INTERACTION_TARGETS.filter((target) => target.kind === "kiosk"));
    }
    if (state.canteenHunt.phase === "pickup_search") {
      targets.push(...CANTEEN_INTERACTION_TARGETS.filter((target) => target.kind === "pickup"));
    }
    if (state.canteenHunt.mode === "light") {
      if (["tray_search", "drink_mix"].includes(state.canteenHunt.phase)) {
        targets.push(...this.initialNpcInteractionTargets.filter((target) => (
          target.id !== "return-auntie"
          && !(
            target.id.startsWith("initial-queue-npc-")
            && Math.abs(target.x - CANTEEN_QUEUE_COLUMN_THREE.x) < 1
          )
        )));
      }
      targets.push(this.returnAuntieTarget);
      if (state.canteenHunt.trayTaskStarted && !hasCompletedCanteenTrayTask(state)) {
        targets.push(...this.trayInteractionTargets.values());
      }
      if (canPlayCanteenDrinkPuzzle(state)) {
        targets.push(
          CANTEEN_QUEUE_COLUMN_THREE,
          ...CANTEEN_DRINK_MACHINES,
          CANTEEN_DRINK_SHELF,
          CANTEEN_MIX_STATION,
          CANTEEN_PROMO_BOARD
        );
      }
    }
    return [...new Map(targets.map((target) => [target.id, target])).values()];
  }

  private canLeaveThroughDoor(state: GameState): boolean {
    return !state.canteenHunt.active || canPlayCanteenSideGames(state);
  }

  private syncCanteenExitDoorProximity(state: GameState): void {
    if (this.exitTransitioning) {
      this.exitDoorProximityActive = true;
      return;
    }
    const within = (bounds: Readonly<{
      left: number;
      top: number;
      right: number;
      bottom: number;
    }>) => (
      this.player.x >= bounds.left
      && this.player.x <= bounds.right
      && this.player.y >= bounds.top
      && this.player.y <= bounds.bottom
    );
    const shouldHoldOpen = this.exitDoorProximityActive
      ? within(CANTEEN_SOUTHEAST_EXIT_DOOR.holdOpenBounds)
      : within(CANTEEN_SOUTHEAST_EXIT_DOOR.approachBounds);
    const canOpen = shouldHoldOpen && this.canLeaveThroughDoor(state);
    if (canOpen === this.exitDoorProximityActive) return;
    this.exitDoorProximityActive = canOpen;
    if (canOpen) this.exitDoor.open();
    else this.exitDoor.close();
  }

  private triggerTarget(target: CanteenInteractionTarget, state: GameState): void {
    if (target.kind === "npc") {
      if (target.id === "return-auntie") {
        if (hasCompletedCanteenTrayTask(state)) {
          this.queueDialogue([canteenContent.tray.afterCompletion]);
          return;
        }
        if (!state.canteenHunt.trayTaskStarted) {
          this.queueDialogue(canteenContent.tray.introDialogue, () => {
            this.bridge.emit("rpg_canteen_tray_task_start_requested");
          });
          return;
        }
        this.bridge.emit("rpg_canteen_tray_delivery_requested");
        return;
      }
      if (target.dialogue) this.queueDialogue([target.dialogue]);
      return;
    }
    if (target.kind === "queue_gap") {
      this.bridge.emit("rpg_canteen_queue_challenge_requested");
      return;
    }
    if (target.kind === "drink_machine") {
      this.openDrinkChoicePanel(String(target.value) as CanteenDrinkIngredientId);
      return;
    }
    if (target.kind === "drink_shelf") {
      this.bridge.emit("rpg_canteen_drink_shelf_requested");
      return;
    }
    if (target.kind === "mixer") {
      this.openMixerPanel();
      return;
    }
    if (target.kind === "promo") {
      this.showFeedback(canteenContent.drinks.promoDropHint, "system");
      return;
    }
    if (target.kind === "tray") {
      this.triggerTrayById(target.value ?? target.id);
      return;
    }
    if (target.kind === "kiosk") {
      this.openMenuPanel();
      return;
    }
    if (target.kind === "pickup") {
      if (state.canteenHunt.mode === "dark") {
        this.bridge.emit("rpg_canteen_pickup_clue_requested", { windowId: target.value });
      } else {
        this.bridge.emit("rpg_canteen_pickup_selected", { windowId: target.value });
      }
      return;
    }
    if (target.kind === "cart") {
      this.triggerCart(String(target.value) as CanteenExitId);
      return;
    }
    if (target.kind === "exit") {
      this.beginCanteenExit();
    }
  }

  private beginCanteenExit(): void {
    const state = this.bridge.getState();
    if (
      this.exitTransitioning
      || !this.canLeaveThroughDoor(state)
      || this.dialogueLocked
      || this.hasModalPanel()
      || this.paperBusy
      || this.cartPushBusy
      || this.defenseRuntime
    ) {
      this.exitDoor.reject();
      return;
    }
    this.exitTransitioning = true;
    this.player.setVelocity(0, 0);
    this.promptText.setVisible(false);
    this.exitDoor.open();
    this.time.delayedCall(this.exitDoor.passableDelayMs, () => {
      if (!this.scene.isActive() || !this.player.active) return;
      this.tweens.add({
        targets: this.player,
        x: CANTEEN_SOUTHEAST_EXIT_DOOR.exitPoint.x,
        y: CANTEEN_SOUTHEAST_EXIT_DOOR.exitPoint.y,
        duration: this.reducedMotion ? 120 : 300,
        ease: "Stepped",
        onUpdate: () => {
          this.updatePlayerWorldDepth();
          this.exitDoor.updateActorOcclusion(this.player);
        },
        onComplete: () => this.bridge.emit("rpg_canteen_leave_requested")
      });
    });
  }

  private triggerPointerTarget(target: CanteenInteractionTarget): void {
    const state = this.bridge.getState();
    if (
      this.time.now < this.suppressWorldPointerUntil
      || this.dialogueLocked
      || this.hasModalPanel()
      || this.paperBusy
      || this.cartPushBusy
    ) return;
    if (!this.getActiveTargets(state).some((candidate) => candidate.id === target.id)) return;
    if (!findNearestCanteenTarget(this.player.x, this.player.y, [target])) return;
    this.triggerTarget(target, state);
  }

  private handleInventoryDrop(payload?: Record<string, unknown>): void {
    const itemId = String(payload?.itemId ?? "") as ItemId;
    const canvasX = Number(payload?.canvasX);
    const canvasY = Number(payload?.canvasY);
    if (!Number.isFinite(canvasX) || !Number.isFinite(canvasY)) {
      this.bridge.emit("rpg_item_use_feedback", { itemId, reason: "missed_target" });
      return;
    }
    const state = this.bridge.getState();
    const worldPoint = this.cameras.main.getWorldPoint(canvasX, canvasY);
    if (itemId === "badDrink") {
      if (Phaser.Math.Distance.Between(worldPoint.x, worldPoint.y, this.player.x, this.player.y - 24) <= 58) {
        this.bridge.emit("rpg_canteen_bad_drink_requested");
        this.bridge.emit("rpg_item_use_feedback", {
          itemId,
          reason: "accepted",
          targetLabel: "玩家自己"
        });
      } else {
        this.bridge.emit("rpg_item_use_feedback", {
          itemId,
          reason: "missed_target",
          detail: "把难喝饮料拖到人物自己身上才能喝掉。"
        });
      }
      return;
    }
    const dropTargets = this.getActiveTargets(state)
      .filter((target) => target.acceptedItem !== undefined);
    const result = resolveRpgItemDrop({
      targets: dropTargets,
      itemId,
      dropX: worldPoint.x,
      dropY: worldPoint.y,
      playerX: this.player.x,
      playerY: this.player.y,
      mode: state.canteenHunt.mode
    });
    if (!result.target) {
      this.bridge.emit("rpg_item_use_feedback", {
        itemId,
        reason: "missed_target",
        detail: itemId === "dailySpecialSparklingWater"
          ? "请拖到第五个打饭窗口下方宣传板的发光空杯位。"
          : "小票不需要拖拽：靠近取餐窗口后按空格使用。"
      });
      return;
    }
    if (result.kind === "wrong_item") {
      this.bridge.emit("rpg_item_use_feedback", {
        itemId,
        reason: "wrong_item",
        targetLabel: result.target.label
      });
      return;
    }
    if (result.kind === "wrong_mode") {
      this.bridge.emit("rpg_item_use_feedback", {
        itemId,
        reason: "locked",
        targetLabel: result.target.label,
        detail: formatRpgModeRequirement(result.expectedMode ?? "light")
      });
      return;
    }
    if (result.kind === "too_far") {
      this.bridge.emit("rpg_item_use_feedback", {
        itemId,
        reason: "too_far",
        targetLabel: result.target.label,
        detail: result.target.kind === "promo"
          ? "落点正确；人物还没有靠近宣传板。"
          : "落点正确；靠近设施后再操作。"
      });
      return;
    }
    if (result.kind !== "accepted") return;
    if (result.target.kind === "promo") {
      this.bridge.emit("rpg_canteen_promo_requested");
      this.bridge.emit("rpg_item_use_feedback", {
        itemId,
        reason: "accepted",
        targetLabel: result.target.label
      });
      return;
    }
    this.bridge.emit("rpg_canteen_pickup_selected", { windowId: result.target.value });
  }

  private triggerTrayById(trayId: string): void {
    const state = this.bridge.getState();
    if (!canPlayCanteenSideGames(state) || hasCompletedCanteenTrayTask(state) || this.dialogueLocked) return;
    const definition = CANTEEN_TRAYS.find((tray) => tray.id === trayId);
    if (!definition) return;
    this.bridge.emit("rpg_canteen_tray_requested", { trayId });
  }

  private triggerCart(exitId: CanteenExitId): void {
    const state = this.bridge.getState();
    if (!state.canteenHunt.active || state.canteenHunt.phase !== "exit_blocking" || this.paperBusy || this.cartPushBusy) return;
    if (CANTEEN_EXIT_SEQUENCE.indexOf(exitId) < state.canteenHunt.blockHits) return;
    if (state.canteenHunt.mode === "dark") {
      this.bridge.emit("rpg_canteen_cart_clue_requested", { exitId });
      return;
    }
    if (!this.cartVisuals.get(exitId)?.visible) return;

    // The controller validates the requested exit before the visual sequence
    // begins. The subsequent result event selects either a settle or a return.
    this.cartPushBusy = true;
    this.cartMotionExit = exitId;
    this.cartMotionVector.set(0, 0);
    this.player.setVelocity(0, 0);
    this.bridge.emit("rpg_canteen_exit_block_requested", { exitId });
  }

  private animateValidatedCartPush(exitId: CanteenExitId, onSettled: () => void): void {
    const definition = CANTEEN_CARTS[exitId];
    const cart = this.cartVisuals.get(exitId);
    if (!cart || !cart.visible) {
      this.finishCartMotion(exitId);
      return;
    }

    this.applyPlayerCollisionBody();
    const handleX = cart.x + definition.handleOffsetX;
    const handleY = cart.y + definition.handleOffsetY;
    const approachVector = new Phaser.Math.Vector2(handleX - this.player.x, handleY - this.player.y);

    const startRoll = () => {
      this.rollCartTo(exitId, definition.pushToX, definition.pushToY, onSettled);
    };

    if (approachVector.lengthSq() <= 4) {
      startRoll();
      return;
    }

    this.cartMotionVector.copy(approachVector).normalize().scale(WALK_SPEED);
    this.tweens.add({
      targets: this.player,
      x: handleX,
      y: handleY,
      duration: this.reducedMotion ? 120 : Phaser.Math.Clamp(
        Math.round(approachVector.length() / CART_APPROACH_SPEED * 1000),
        120,
        320
      ),
      ease: "Sine.easeOut",
      onUpdate: () => this.updatePlayerWorldDepth(),
      onComplete: startRoll
    });
  }

  private rollCartTo(exitId: CanteenExitId, targetX: number, targetY: number, onComplete: () => void): void {
    const definition = CANTEEN_CARTS[exitId];
    const cart = this.cartVisuals.get(exitId);
    if (!cart) {
      onComplete();
      return;
    }

    const startX = cart.x;
    const startY = cart.y;
    const rollVector = new Phaser.Math.Vector2(targetX - startX, targetY - startY);
    const distance = rollVector.length();
    if (distance <= 1) {
      this.placeCart(exitId, targetX, targetY, 0);
      onComplete();
      return;
    }

    this.cartMotionVector.copy(rollVector).normalize().scale(WALK_SPEED);
    this.setPushFacing(rollVector.x, rollVector.y);
    const motion = { progress: 0 };
    const duration = this.reducedMotion
      ? 120
      : Math.max(CART_MIN_ROLL_DURATION_MS, Math.round(distance / definition.pushSpeed * 1000));
    this.bridge.emit("canteen_cart_roll_started", {
      exitId,
      direction: targetX === definition.x && targetY === definition.y ? "return" : "forward"
    });

    this.tweens.add({
      targets: motion,
      progress: 1,
      duration,
      ease: "Sine.easeInOut",
      onUpdate: () => {
        const x = Phaser.Math.Linear(startX, targetX, motion.progress);
        const y = Phaser.Math.Linear(startY, targetY, motion.progress);
        const wheelFrame = Math.floor(this.time.now / CART_ROLL_FRAME_MS) % CANTEEN_CART_FRAME_KEYS.length;
        this.placeCart(exitId, x, y, wheelFrame);
        this.player.setPosition(x + definition.handleOffsetX, y + definition.handleOffsetY);
        this.updatePlayerWorldDepth();
      },
      onComplete: () => {
        this.placeCart(exitId, targetX, targetY, 0);
        this.player.setPosition(targetX + definition.handleOffsetX, targetY + definition.handleOffsetY);
        this.updatePlayerWorldDepth();
        this.time.delayedCall(this.reducedMotion ? 0 : 90, onComplete);
      }
    });
  }

  private restoreFailedCartPush(exitId: CanteenExitId, onComplete: () => void): void {
    const definition = CANTEEN_CARTS[exitId];
    const cart = this.cartVisuals.get(exitId);
    if (!cart) {
      this.finishCartMotion(exitId);
      onComplete();
      return;
    }
    this.rollCartTo(exitId, definition.x, definition.y, () => {
      this.finishCartMotion(exitId);
      onComplete();
    });
  }

  private finishCartMotion(exitId: CanteenExitId): void {
    if (this.cartMotionExit !== exitId) return;
    const playerBody = this.player.body as Phaser.Physics.Arcade.Body | null;
    if (playerBody) {
      this.applyPlayerCollisionBody();
      playerBody.reset(this.player.x, this.player.y);
    }
    this.cartPushBusy = false;
    this.cartMotionExit = null;
    this.cartMotionVector.set(0, 0);
  }

  private placeCart(exitId: CanteenExitId, x: number, y: number, wheelFrame = 0): void {
    const cart = this.cartVisuals.get(exitId);
    if (!cart) return;
    cart
      .setTexture(CANTEEN_CART_FRAME_KEYS[wheelFrame % CANTEEN_CART_FRAME_KEYS.length])
      .setPosition(x, y)
      .setDepth(y + 20);
    this.applyCartOrientation(cart, CANTEEN_CARTS[exitId]);
    this.exitGlows.get(exitId)?.setPosition(x, y).setDepth(y + 19);
  }

  private applyCartOrientation(cart: Phaser.GameObjects.Image, definition: typeof CANTEEN_CARTS[CanteenExitId]): void {
    const deltaX = definition.pushToX - definition.x;
    const deltaY = definition.pushToY - definition.y;
    if (Math.abs(deltaX) >= Math.abs(deltaY)) {
      cart.setAngle(0).setFlipX(deltaX < 0);
      return;
    }
    // The authored texture faces east with its handle on the left. A 90-degree
    // rotation keeps the handle behind the player for the vertical service route.
    cart.setAngle(deltaY < 0 ? -90 : 90).setFlipX(false);
  }

  private setPushFacing(deltaX: number, deltaY: number): void {
    if (Math.abs(deltaX) > Math.abs(deltaY)) {
      this.playerAnimator.setFacing("side", deltaX < 0, false);
      return;
    }
    this.playerAnimator.setFacing(deltaY < 0 ? "up" : "down");
  }

  private updatePrompt(nearest: CanteenInteractionTarget | null, state: GameState): void {
    if (!nearest || this.exitTransitioning || this.dialogueLocked || this.hasModalPanel() || this.paperBusy || this.cartPushBusy) {
      this.promptText.setVisible(false);
      return;
    }
    let label = nearest.label;
    if (nearest.kind === "tray") {
      label = state.canteenHunt.carriedTrayIds.length > 0
        ? "先把手上的餐盘交给阿姨"
        : "拿起桌上的餐盘";
    } else if (nearest.kind === "kiosk") {
      label = "使用点餐机";
    } else if (nearest.kind === "pickup") {
      label = state.canteenHunt.mode === "dark"
        ? `查看${nearest.value}号窗口`
        : state.items.pickupTicket0755
          ? `使用小票 · ${nearest.value}号窗口`
          : `${nearest.value}号取餐窗口`;
    } else if (nearest.kind === "promo") {
      label = state.items.dailySpecialSparklingWater
        ? "把今日新品放入宣传板空杯位"
        : "宣传板空杯位";
    } else if (nearest.kind === "cart") {
      label = state.canteenHunt.mode === "dark"
        ? "确认蓝色轨迹指向"
        : "靠近餐盘车把手";
    } else if (nearest.kind === "exit") {
      label = "靠近东南门离开食堂";
    }
    this.promptText.setText(formatRpgInteractionHint(label)).setVisible(true);
  }

  private syncWorldFromState(state: GameState, immediate = false): void {
    const phaseChanged = state.canteenHunt.phase !== this.currentPhase;
    this.currentPhase = state.canteenHunt.phase;
    if (state.canteenHunt.mode !== this.currentMode) {
      if (immediate) {
        this.currentMode = state.canteenHunt.mode;
        this.darkOverlay?.setAlpha(this.currentMode === "dark" ? 0.56 : 0);
        this.applyCanteenNpcMode(this.currentMode, true);
      } else {
        this.playModeTransition(state.canteenHunt.mode);
      }
    } else if (phaseChanged) {
      this.applyCanteenNpcMode(this.currentMode, immediate);
    }
    this.pickupWindowVisuals.forEach((visual) => {
      visual.sign.setVisible(false);
      visual.standMarker.setVisible(false);
      visual.dropFrame.setVisible(false);
      visual.dropLabel.setVisible(false);
    });
    const sideGamesAvailable = canPlayCanteenSideGames(state);
    const drinkPuzzleAvailable = canPlayCanteenDrinkPuzzle(state);
    const promoVisible = sideGamesAvailable && !this.entryPaperPending;
    const promoActivationPending = state.canteenHunt.promoDrinkPlaced
      && !state.canteenHunt.queueGapOpened;
    if (!this.queueShiftAnimating) {
      this.promoPanel?.setVisible(
        promoVisible && state.canteenHunt.promoDrinkPlaced && !promoActivationPending
      );
      this.promoEmptyCup?.setVisible(
        promoVisible && (!state.canteenHunt.promoDrinkPlaced || promoActivationPending)
      );
      this.promoBubbleLoop?.setVisible(
        promoVisible && state.canteenHunt.promoDrinkPlaced && !promoActivationPending
      );
      if (this.promoBubbleLoop?.visible && !this.promoBubbleLoop.anims.isPlaying) {
        this.promoBubbleLoop.play(CANTEEN_PROMO_BUBBLE_ANIM_KEY, true);
      }
    }
    this.promoDropFrame?.setVisible(false);
    this.trayVisuals.forEach((visual, trayId) => {
      const definition = CANTEEN_TRAYS.find((tray) => tray.id === trayId);
      const removed = state.canteenHunt.returnedTrayIds.includes(trayId)
        || state.canteenHunt.carriedTrayIds.includes(trayId);
      const visible = sideGamesAvailable && !this.entryPaperPending && !removed;
      const dirtyVisible = visible
        && !hasCompletedCanteenTrayTask(state)
        && state.canteenHunt.trayTaskStarted
        && state.canteenHunt.mode === "dark"
        && definition?.target === true;
      visual.container
        .setVisible(visible)
        .setDepth(dirtyVisible ? 1605 : visual.container.y + 110);
      visual.cleanImage.setVisible(visible && !dirtyVisible);
      visual.dirtyImage.setVisible(dirtyVisible);
      visual.sparkles.forEach((sparkle) => sparkle.setVisible(dirtyVisible));
    });
    this.updateCarriedTrayVisual(state);
    const blocking = state.canteenHunt.phase === "exit_blocking";
    const defenseReady = blocking && !this.paperBusy;
    if (defenseReady) {
      this.tweens.killTweensOf(this.darkOverlay);
      this.darkOverlay.setAlpha(0);
      this.modeFibers.forEach((fiber) => fiber.setVisible(false));
    }
    this.cartVisuals.forEach((cart, exitId) => {
      const isAnimating = this.cartPushBusy && this.cartMotionExit === exitId;
      const definition = CANTEEN_CARTS[exitId];
      if (!isAnimating) {
        this.placeCart(exitId, definition.x, definition.y);
      }
      cart.setVisible(false);
    });
    this.exitGlows.forEach((glow) => glow.setVisible(false));
    if (defenseReady && !this.paper.visible) {
      this.paper.setPosition(836, 470).setVisible(true);
      this.paperFloatTween.restart();
    } else if (!blocking && !this.entryPaperPending && !this.paperBusy && !this.defenseRuntime) {
      this.paper.setVisible(false);
    }
  }

  private animateTrayCollection(trayId: string): void {
    const visual = this.trayVisuals.get(trayId);
    if (!visual) return;
    this.dialogueLocked = true;
    const pickupVisual = this.add.image(
      visual.container.x,
      visual.container.y,
      CANTEEN_TRAY_KEY
    ).setScale(0.75).setDepth(2300);
    visual.container.setVisible(false);
    this.bridge.emit("canteen_tray_slide_started", { trayId });
    this.tweens.add({
      targets: pickupVisual,
      x: this.player.x,
      y: this.player.y - 48,
      scale: 0.58,
      duration: this.reducedMotion ? 100 : 360,
      ease: "Back.easeIn",
      onComplete: () => {
        pickupVisual.destroy();
        this.dialogueLocked = false;
        this.bridge.emit("canteen_tray_slide_completed", { trayId });
      }
    });
  }

  private updateCarriedTrayVisual(state: GameState): void {
    if (!this.carriedTrayVisual) return;
    const carrying = canPlayCanteenSideGames(state)
      && state.canteenHunt.carriedTrayIds.length > 0;
    this.carriedTrayVisual
      .setPosition(this.player.x, this.player.y - 48)
      .setDepth(this.player.depth + 4)
      .setVisible(carrying && !this.dialogueLocked);
  }

  private animatePromoAndQueueShift(): void {
    if (this.queueShiftAnimating || this.bridge.getState().canteenHunt.queueGapOpened) return;
    this.queueShiftAnimating = true;
    this.dialogueLocked = true;
    this.closeDrinkChoicePanel();
    this.closeMixerPanel();
    this.player.setVelocity(0, 0);
    this.playerAnimator.setFacing("up");
    this.promoPanel?.setVisible(false).setAlpha(1).setScale(0.5);
    this.promoEmptyCup?.setVisible(true).setAlpha(1).setScale(0.5);
    this.promoDrinkInsert?.setVisible(false);
    this.promoBubbleLoop?.setVisible(false);

    // Stretch the complete normal-motion cutscene from about 3.1 s to 4 s
    // without changing the perpetual three-frame bubble loop's 6 fps rate.
    const promoBeatMs = (reducedMs: number, normalMs: number) => (
      this.reducedMotion ? reducedMs : Math.round(normalMs * 1.286)
    );
    const camera = this.cameras.main;
    const focusMs = promoBeatMs(90, 260);
    camera.stopFollow().setDeadzone(0, 0);
    camera.pan(
      CANTEEN_PROMO_BOARD.x,
      CANTEEN_PROMO_BOARD.y + 28,
      focusMs,
      "Sine.easeInOut"
    );
    zoomRpgCameraTo(this, 2.1, focusMs, "Sine.easeInOut", camera);

    const finishQueueShift = () => {
      this.thirdColumnQueue.forEach((entry) => {
        const height = RPG_PLAYER_FOOT_COLLISION.height * RPG_PLAYER_DISPLAY_SCALE;
        entry.sprite.setVisible(true).setY(entry.baseY + 36);
        entry.collision.setPosition(entry.sprite.x, entry.sprite.y - height / 2);
        const body = entry.collision.body as Phaser.Physics.Arcade.StaticBody | null;
        if (body) {
          body.enable = true;
          body.updateFromGameObject();
        }
      });
      const returnMs = promoBeatMs(120, 480);
      camera.pan(this.player.x, this.player.y, returnMs, "Sine.easeInOut");
      zoomRpgCameraTo(this, 1, returnMs, "Sine.easeInOut", camera);
      this.time.delayedCall(returnMs + promoBeatMs(30, 30), () => {
        this.queueShiftAnimating = false;
        this.dialogueLocked = false;
        camera.startFollow(this.player, true, 0.13, 0.13, 0, 24).setDeadzone(250, 150);
        this.bridge.emit("rpg_canteen_queue_shift_completed");
        this.queueDialogue(canteenContent.drinks.queueShiftDialogue);
      });
    };

    const shiftThirdColumn = () => {
      const frontStudent = this.thirdColumnQueue[0];
      let turnFrame: Phaser.GameObjects.Image | null = null;
      if (frontStudent) {
        frontStudent.sprite.setVisible(false);
        turnFrame = this.add.image(
          frontStudent.sprite.x,
          frontStudent.sprite.y,
          CANTEEN_QUEUE_STUDENT_TURN_KEY
        ).setOrigin(0.5, 1)
          .setScale(CANTEEN_NPC_DISPLAY_SCALE)
          .setDepth(frontStudent.sprite.depth + 2);
      }

      const glanceMs = promoBeatMs(70, 220);
      this.time.delayedCall(glanceMs, () => {
        turnFrame?.destroy();
        frontStudent?.sprite.setVisible(true);
        const waveStepMs = promoBeatMs(65, 145);
        const moveMs = promoBeatMs(100, 310);
        this.thirdColumnQueue.forEach((entry, index) => {
          const body = entry.collision.body as Phaser.Physics.Arcade.StaticBody | null;
          if (body) body.enable = false;
          this.time.delayedCall(waveStepMs * index, () => {
            const promptFrame = index === 0 ? 3 : 4;
            const prompt = this.add.sprite(
              entry.sprite.x,
              entry.sprite.y - 78,
              CANTEEN_PROMO_FX_KEY,
              promptFrame
            ).setScale(0.55).setDepth(entry.sprite.depth + 8);
            this.tweens.add({
              targets: prompt,
              alpha: 0,
              y: prompt.y - 8,
              duration: promoBeatMs(90, 300),
              ease: "Sine.easeOut",
              onComplete: () => prompt.destroy()
            });
            this.tweens.add({
              targets: entry.sprite,
              y: entry.baseY + 36,
              duration: moveMs,
              ease: "Sine.easeInOut"
            });
          });
        });
        const totalShiftMs = waveStepMs * Math.max(0, this.thirdColumnQueue.length - 1)
          + moveMs
          + promoBeatMs(40, 40);
        this.time.delayedCall(totalShiftMs, finishQueueShift);
      });
    };

    const revealActivatedBoard = () => {
      this.promoDrinkInsert?.setVisible(false).stop();
      this.promoEmptyCup?.setVisible(false).setAlpha(1);
      this.promoPanel?.setVisible(true).setAlpha(0).setScale(0.46);
      const glow = this.add.rectangle(
        CANTEEN_PROMO_BOARD.x,
        CANTEEN_PROMO_BOARD.y,
        158,
        108,
        0x9af4ff,
        0.34
      ).setDepth(1699);
      if (this.promoPanel) {
        this.tweens.add({
          targets: this.promoPanel,
          alpha: 1,
          scale: 0.5,
          duration: promoBeatMs(90, 180),
          ease: "Back.easeOut"
        });
        this.time.delayedCall(promoBeatMs(90, 190), () => {
          if (!this.promoPanel) return;
          this.tweens.add({
            targets: this.promoPanel,
            alpha: 0.46,
            duration: promoBeatMs(55, 80),
            repeat: this.reducedMotion ? 0 : 1,
            yoyo: true
          });
        });
      }
      this.promoBubbleLoop?.setVisible(true).play(CANTEEN_PROMO_BUBBLE_ANIM_KEY, true);
      this.tweens.add({
        targets: glow,
        alpha: 0,
        scale: 1.08,
        duration: promoBeatMs(100, 420),
        ease: "Sine.easeOut",
        onComplete: () => glow.destroy()
      });
      const queueFocusMs = promoBeatMs(100, 280);
      this.time.delayedCall(promoBeatMs(120, 430), () => {
        camera.pan(
          (CANTEEN_PROMO_BOARD.x + CANTEEN_QUEUE_COLUMN_THREE.x) / 2,
          210,
          queueFocusMs,
          "Sine.easeInOut"
        );
        zoomRpgCameraTo(this, 1.55, queueFocusMs, "Sine.easeInOut", camera);
        this.time.delayedCall(queueFocusMs + promoBeatMs(20, 20), shiftThirdColumn);
      });
    };

    this.time.delayedCall(focusMs + promoBeatMs(20, 20), () => {
      if (!this.promoEmptyCup) {
        revealActivatedBoard();
        return;
      }
      this.tweens.add({
        targets: this.promoEmptyCup,
        alpha: 0.34,
        duration: promoBeatMs(45, 80),
        repeat: this.reducedMotion ? 0 : 1,
        yoyo: true,
        onComplete: () => {
          this.promoEmptyCup?.setAlpha(1);
          if (!this.promoDrinkInsert) {
            revealActivatedBoard();
            return;
          }
          this.promoDrinkInsert.setVisible(true).play(CANTEEN_PROMO_INSERT_ANIM_KEY, true);
          this.time.delayedCall(promoBeatMs(110, 410), revealActivatedBoard);
        }
      });
    });
  }

  private hasModalPanel(): boolean {
    return this.menuPanel !== null || this.drinkChoicePanel !== null || this.mixerPanel !== null;
  }

  private isMovementAllowed(state: GameState): boolean {
    return state.actOne.movementEnabled
      && !this.hasModalPanel()
      && !this.paperBusy
      && !this.cartPushBusy
      && !this.exitTransitioning;
  }

  private handleModalKeyboard(event: KeyboardEvent): void {
    if (this.drinkChoicePanel) {
      if (event.code === "ArrowLeft" || event.code === "KeyA" || event.key === "ArrowLeft" || event.key.toLowerCase() === "a") {
        event.preventDefault();
        this.drinkChoiceSelection = 0;
        this.refreshDrinkChoiceSelection();
        return;
      }
      if (event.code === "ArrowRight" || event.code === "KeyD" || event.key === "ArrowRight" || event.key.toLowerCase() === "d") {
        event.preventDefault();
        this.drinkChoiceSelection = 1;
        this.refreshDrinkChoiceSelection();
        return;
      }
      if ((event.code === "Enter" || event.code === "Space" || event.key === "Enter" || event.key === " " || event.key === "Spacebar") && !event.repeat) {
        event.preventDefault();
        this.confirmDrinkChoiceSelection();
        return;
      }
      if ((event.code === "Escape" || event.key === "Escape") && !event.repeat) {
        event.preventDefault();
        this.closeDrinkChoicePanel();
      }
      return;
    }
    if (this.mixerPanel && (event.code === "Escape" || event.key === "Escape") && !event.repeat) {
      event.preventDefault();
      this.closeMixerPanel();
    }
  }

  private openDrinkChoicePanel(itemId: CanteenDrinkIngredientId): void {
    if (this.hasModalPanel()) return;
    const presentation: Record<CanteenDrinkIngredientId, { name: string; color: number; accent: number }> = {
      sparklingWater: { name: "气泡水（蓝色）", color: 0x43bce9, accent: 0xe9fbff },
      lemonTea: { name: "柠檬茶（白色）", color: 0xf2f0dc, accent: 0xd0a636 },
      blackCoffee: { name: "黑咖啡（黑色）", color: 0x1b1d20, accent: 0x8b6846 }
    };
    const drink = presentation[itemId];
    const panel = this.add.container(480, 270).setScrollFactor(0).setDepth(6100);
    const shade = this.add.rectangle(0, 0, 470, 278, 0x07131d, 0.98)
      .setStrokeStyle(4, 0x63d4ef, 0.96);
    const header = this.add.rectangle(0, -116, 458, 34, 0x123c54, 0.98);
    const title = this.add.text(-205, -125, drink.name, {
      color: "#f4fbff",
      fontFamily: "monospace",
      fontSize: "20px",
      fontStyle: "bold"
    });
    const bottle = this.add.graphics();
    bottle.fillStyle(drink.accent).fillRect(-128, -66, 50, 92);
    bottle.fillStyle(drink.color).fillRect(-120, -50, 34, 66);
    bottle.fillStyle(0xf0cb59).fillRect(-112, -78, 18, 12);
    bottle.lineStyle(4, 0x142c3b).strokeRect(-128, -66, 50, 92);
    const prompt = this.add.text(18, -45, canteenContent.drinks.machinePrompt, {
      color: "#d9f6ff",
      fontFamily: "monospace",
      fontSize: "17px"
    }).setOrigin(0.5);
    const takeButton = this.add.rectangle(-95, 82, 164, 48, 0x17637a, 1)
      .setStrokeStyle(3, 0x75e4ff, 1);
    const takeLabel = this.add.text(-95, 82, canteenContent.drinks.takeOption, {
      color: "#ffffff",
      fontFamily: "monospace",
      fontSize: "17px"
    }).setOrigin(0.5);
    const cancelButton = this.add.rectangle(95, 82, 164, 48, 0x293039, 1)
      .setStrokeStyle(3, 0x82919b, 1);
    const cancelLabel = this.add.text(95, 82, canteenContent.drinks.cancelOption, {
      color: "#dce2e3",
      fontFamily: "monospace",
      fontSize: "17px"
    }).setOrigin(0.5);
    const keyboardHint = this.add.text(0, 121, "← / → 选择 · 空格 / 回车确认 · Esc 退出", {
      color: "#8fb5c3",
      fontFamily: "monospace",
      fontSize: "11px"
    }).setOrigin(0.5);
    panel.add([
      shade, header, title, bottle, prompt,
      takeButton, takeLabel, cancelButton, cancelLabel, keyboardHint
    ]);
    this.drinkChoiceItem = itemId;
    this.drinkChoiceSelection = 0;
    this.drinkChoiceControls = { takeButton, takeLabel, cancelButton, cancelLabel };
    this.drinkChoicePanel = panel;
    this.refreshDrinkChoiceSelection();
    const chooseTake = () => {
      if (this.drinkChoicePanel !== panel) return;
      this.drinkChoiceSelection = 0;
      this.confirmDrinkChoiceSelection(true);
    };
    const chooseCancel = () => {
      if (this.drinkChoicePanel !== panel) return;
      this.drinkChoiceSelection = 1;
      this.closeDrinkChoicePanel(true);
    };
    const bindChoiceButton = (
      target: Phaser.GameObjects.Rectangle | Phaser.GameObjects.Text,
      action: () => void
    ) => {
      target.setInteractive({ useHandCursor: true }).on(
        "pointerdown",
        (
          _pointer: Phaser.Input.Pointer,
          _localX: number,
          _localY: number,
          event: Phaser.Types.Input.EventData
        ) => {
          event.stopPropagation();
          action();
        }
      );
    };
    bindChoiceButton(takeButton, chooseTake);
    bindChoiceButton(takeLabel, chooseTake);
    bindChoiceButton(cancelButton, chooseCancel);
    bindChoiceButton(cancelLabel, chooseCancel);
  }

  private handleDrinkChoicePointer(pointer: Phaser.Input.Pointer): void {
    if (!this.drinkChoicePanel || !this.drinkChoiceItem) return;
    const logical = toRpgLogicalScreenPoint(this, pointer.x, pointer.y);
    const localX = logical.x - 480;
    const localY = logical.y - 270;
    if (Math.abs(localY - 82) > 30) return;
    if (Math.abs(localX + 95) <= 88) {
      this.drinkChoiceSelection = 0;
      this.confirmDrinkChoiceSelection(true);
    } else if (Math.abs(localX - 95) <= 88) {
      this.drinkChoiceSelection = 1;
      this.confirmDrinkChoiceSelection(true);
    }
  }

  private refreshDrinkChoiceSelection(): void {
    if (!this.drinkChoiceControls) return;
    const takeSelected = this.drinkChoiceSelection === 0;
    this.drinkChoiceControls.takeButton
      .setFillStyle(takeSelected ? 0x17637a : 0x20323b, 1)
      .setStrokeStyle(3, takeSelected ? 0x75e4ff : 0x58727c, 1);
    this.drinkChoiceControls.cancelButton
      .setFillStyle(takeSelected ? 0x293039 : 0x4e5760, 1)
      .setStrokeStyle(3, takeSelected ? 0x82919b : 0x75e4ff, 1);
    this.drinkChoiceControls.takeLabel
      .setText(`${takeSelected ? "▶ " : ""}${canteenContent.drinks.takeOption}`)
      .setColor(takeSelected ? "#ffffff" : "#a9bac0");
    this.drinkChoiceControls.cancelLabel
      .setText(`${takeSelected ? "" : "▶ "}${canteenContent.drinks.cancelOption}`)
      .setColor(takeSelected ? "#b7c1c5" : "#ffffff");
  }

  private confirmDrinkChoiceSelection(suppressWorldPointer = false): void {
    const itemId = this.drinkChoiceItem;
    if (!itemId) return;
    if (this.drinkChoiceSelection === 0) {
      this.bridge.emit("rpg_canteen_drink_requested", { itemId });
    }
    this.closeDrinkChoicePanel(suppressWorldPointer);
  }

  private closeDrinkChoicePanel(suppressWorldPointer = false): void {
    if (suppressWorldPointer) {
      this.suppressWorldPointerUntil = this.time.now + 500;
    }
    this.drinkChoicePanel?.destroy(true);
    this.drinkChoicePanel = null;
    this.drinkChoiceItem = null;
    this.drinkChoiceControls = null;
  }

  private openMixerPanel(): void {
    if (this.hasModalPanel()) return;
    const state = this.bridge.getState();
    if (this.mixerButtonOrder.length === 0) {
      const recipeOrder: CanteenDrinkIngredientId[] = ["blackCoffee", "sparklingWater", "lemonTea"];
      this.mixerButtonOrder = Phaser.Utils.Array.Shuffle([...recipeOrder]);
      if (this.mixerButtonOrder.every((ingredient, index) => ingredient === recipeOrder[index])) {
        this.mixerButtonOrder.push(this.mixerButtonOrder.shift()!);
      }
    }
    const panel = this.add.container(480, 245).setScrollFactor(0).setDepth(6100);
    const shade = this.add.rectangle(0, 0, 690, 390, 0x08151c, 0.985)
      .setStrokeStyle(5, 0xe0b858, 1);
    const header = this.add.rectangle(0, -170, 676, 42, 0x183847, 1);
    const title = this.add.text(-318, -182, "食堂新品混合台", {
      color: "#fff3c4",
      fontFamily: "monospace",
      fontSize: "22px",
      fontStyle: "bold"
    });
    const exitButton = this.add.rectangle(274, -170, 126, 30, 0x2a4651, 1)
      .setStrokeStyle(2, 0xe0b858, 1);
    const exitLabel = this.add.text(274, -170, "退出  Esc", {
      color: "#fff3c4",
      fontFamily: "monospace",
      fontSize: "14px"
    }).setOrigin(0.5);

    const worktop = this.add.rectangle(0, 62, 620, 58, 0x8a6135, 1)
      .setStrokeStyle(4, 0x3f2b20, 1);
    const glass = this.add.graphics();
    glass.fillStyle(0xdff8ff, 0.13).fillRect(-56, -94, 112, 158);
    const colors: Record<CanteenDrinkIngredientId, number> = {
      sparklingWater: 0x40bfe8,
      lemonTea: 0xf0edcf,
      blackCoffee: 0x242226
    };
    state.canteenHunt.drinkMixSequence.forEach((ingredient, index) => {
      glass.fillStyle(colors[ingredient], 0.92).fillRect(-49, 37 - index * 38, 98, 36);
    });
    glass.lineStyle(5, 0xb9e6ee, 1)
      .lineBetween(-58, -98, -50, 64)
      .lineBetween(58, -98, 50, 64)
      .lineBetween(-50, 64, 50, 64)
      .lineBetween(-58, -98, 58, -98);
    const glassLabel = this.add.text(0, -118, "大玻璃杯", {
      color: "#c8f3ff",
      fontFamily: "monospace",
      fontSize: "14px"
    }).setOrigin(0.5);
    const instruction = this.add.text(0, 98, canteenContent.drinks.mixerPrompt, {
      color: "#fff2c4",
      fontFamily: "monospace",
      fontSize: "15px"
    }).setOrigin(0.5);
    const shelfStatus = this.add.text(0, 122, state.canteenHunt.drinkShelfRead
      ? "货架提示已记录：黑色 → 蓝色 → 白色"
      : "货架提示：尚未查看", {
      color: state.canteenHunt.drinkShelfRead ? "#91e4ba" : "#e3b878",
      fontFamily: "monospace",
      fontSize: "13px"
    }).setOrigin(0.5);
    panel.add([
      shade, header, title, exitButton, exitLabel,
      worktop, glass, glassLabel, instruction, shelfStatus
    ]);

    const ingredientPresentation: Record<CanteenDrinkIngredientId, { name: string; color: number }> = {
      blackCoffee: { name: "黑咖啡", color: 0x242226 },
      sparklingWater: { name: "气泡水", color: 0x40bfe8 },
      lemonTea: { name: "柠檬茶", color: 0xf0edcf }
    };
    const buttonPositions = [-210, 0, 210] as const;
    const buttons = this.mixerButtonOrder.map((id, index) => ({
      id,
      ...ingredientPresentation[id],
      x: buttonPositions[index]
    }));
    buttons.forEach((button) => {
      const owned = state.items[button.id];
      const frame = this.add.rectangle(button.x, 160, 174, 48, owned ? 0x164b59 : 0x263038, 1)
        .setStrokeStyle(3, owned ? 0x6cdcf3 : 0x56636a, 1);
      const swatch = this.add.rectangle(button.x - 57, 160, 18, 24, button.color, 1)
        .setStrokeStyle(2, 0xc7d9dc, 0.85);
      const label = this.add.text(button.x + 10, 160, owned ? `倒入${button.name}` : `${button.name}·未持有`, {
        color: owned ? "#f4fbff" : "#7f8d92",
        fontFamily: "monospace",
        fontSize: "13px"
      }).setOrigin(0.5);
      panel.add([frame, swatch, label]);
    });
    this.mixerPanel = panel;
  }

  private handleMixerPointer(pointer: Phaser.Input.Pointer): void {
    if (!this.mixerPanel) return;
    const logical = toRpgLogicalScreenPoint(this, pointer.x, pointer.y);
    const localX = logical.x - 480;
    const localY = logical.y - 245;
    if (Math.abs(localX - 274) <= 66 && Math.abs(localY + 170) <= 20) {
      this.closeMixerPanel();
      return;
    }
    if (Math.abs(localY - 160) > 27) return;
    const buttonPositions = [-210, 0, 210] as const;
    const candidates = this.mixerButtonOrder.map((id, index) => ({ id, x: buttonPositions[index] }));
    const candidate = candidates.find((entry) => Math.abs(localX - entry.x) <= 88);
    if (!candidate) return;
    if (!this.bridge.getState().items[candidate.id]) {
      this.showFeedback(canteenContent.drinks.ingredientMissing, "system");
      return;
    }
    this.bridge.emit("rpg_canteen_mix_ingredient_requested", { itemId: candidate.id });
  }

  private closeMixerPanel(resetButtonOrder = true): void {
    this.mixerPanel?.destroy(true);
    this.mixerPanel = null;
    if (resetButtonOrder) this.mixerButtonOrder = [];
  }

  private refreshMixerPanel(): void {
    if (!this.mixerPanel) return;
    this.closeMixerPanel(false);
    this.openMixerPanel();
  }

  private openMenuPanel(): void {
    if (this.menuPanel) return;
    const state = this.bridge.getState();
    const isDark = state.canteenHunt.mode === "dark";
    const canOrder = !isDark;
    const panel = this.add.container(480, 270).setScrollFactor(0).setDepth(6000);
    const shade = this.add.rectangle(0, 0, 570, 376, isDark ? 0x080a0d : 0xf7f4ea, 0.98)
      .setStrokeStyle(4, isDark ? 0x6d8390 : 0x5a4932, 0.95);
    const title = this.add.text(0, -148, isDark ? canteenContent.menu.darkIntro : canteenContent.menu.lightIntro, {
      color: isDark ? "#e8f7ff" : "#241f19",
      fontFamily: "monospace",
      fontSize: "20px",
      align: "center"
    }).setOrigin(0.5);
    panel.add([shade, title]);
    canteenContent.menu.options.forEach((option, index) => {
      const y = -94 + index * 55;
      const button = this.add.rectangle(0, y, 430, 42, isDark ? 0x1b2126 : 0xffffff, 0.96)
        .setStrokeStyle(2, isDark ? 0x75818a : 0x8a775b, 0.9);
      const label = this.add.text(0, y, `${option.id}  ${isDark ? option.dark : option.light}`, {
        color: isDark ? "#86dcff" : "#201d19",
        fontFamily: "monospace",
        fontSize: "18px"
      }).setOrigin(0.5);
      button.setData("optionId", option.id);
      panel.add([button, label]);
    });
    const close = this.add.text(255, -168, "×", {
      color: isDark ? "#fff7df" : "#3b3025",
      fontFamily: "monospace",
      fontSize: "28px"
    }).setOrigin(0.5);
    panel.add(close);
    const gateText = isDark
      ? "观察模式 · 菜名留下了另一层字"
      : "选择一份餐品 · 取餐前不能重复下单";
    panel.add(this.add.text(0, 166, gateText, {
      color: isDark ? "#91d8f5" : "#6c5236",
      fontFamily: "monospace",
      fontSize: "13px"
    }).setOrigin(0.5));
    this.menuPanel = panel;
    if (state.canteenHunt.mode === "dark") {
      this.bridge.emit("rpg_canteen_menu_clue_requested");
    }
  }

  private handleMenuPointer(pointer: Phaser.Input.Pointer): void {
    if (!this.menuPanel) return;
    const logical = toRpgLogicalScreenPoint(this, pointer.x, pointer.y);
    const localX = logical.x - 480;
    const localY = logical.y - 270;
    if (Math.abs(localX - 255) <= 28 && Math.abs(localY + 168) <= 28) {
      this.closeMenuPanel();
      return;
    }
    const state = this.bridge.getState();
    if (state.canteenHunt.mode !== "light") {
      this.showFeedback(canteenContent.menu.orderLocked, "system");
      return;
    }
    if (Math.abs(localX) > 215) return;
    const option = canteenContent.menu.options.find((_candidate, index) => (
      Math.abs(localY - (-94 + index * 55)) <= 21
    ));
    if (option) this.bridge.emit("rpg_canteen_menu_selected", { optionId: option.id });
  }

  private closeMenuPanel(): void {
    this.menuPanel?.destroy(true);
    this.menuPanel = null;
  }

  private refreshMenuPanel(): void {
    if (!this.menuPanel) return;
    this.closeMenuPanel();
    this.openMenuPanel();
  }

  private animatePaperBurst(): void {
    if (this.paperBusy) return;
    const steamWindow = CANTEEN_PICKUP_WINDOWS[2];
    // This is a narrative cutscene, so its readable 8-12 second rhythm is
    // preserved even when the OS requests reduced motion. That preference only
    // disables camera shake below; it must not collapse the story into a summary.
    const beatMs = (_reducedMs: number, normalMs: number) => normalMs;
    this.paperBusy = true;
    this.dialogueLocked = true;
    this.player.setVelocity(0, 0);
    this.playerAnimator.setFacing("up");
    this.player.setVisible(false);
    this.promptText.setVisible(false);
    this.paperFloatTween.pause();
    this.shadowNpcSprite?.setVisible(true).setAlpha(0.68);
    this.paper.setVisible(false);

    if (!this.anims.exists(CANTEEN_SHADOW_AUNTIE_PUSH_ANIM_KEY)) {
      this.anims.create({
        key: CANTEEN_SHADOW_AUNTIE_PUSH_ANIM_KEY,
        frames: this.anims.generateFrameNumbers(CANTEEN_SHADOW_AUNTIE_PUSH_KEY, { start: 0, end: 4 }),
        frameRate: 3.6,
        repeat: 0
      });
    }
    if (!this.anims.exists(CANTEEN_PAPER_CHICKEN_SHAKE_ANIM_KEY)) {
      this.anims.create({
        key: CANTEEN_PAPER_CHICKEN_SHAKE_ANIM_KEY,
        frames: [0, 1, 0, 2, 3, 4].map((frame) => ({
          key: CANTEEN_PAPER_CHICKEN_SHAKE_KEY,
          frame
        })),
        frameRate: 5.7,
        repeat: 0
      });
    }
    if (!this.anims.exists(CANTEEN_PAPER_CHICKEN_BURST_ANIM_KEY)) {
      this.anims.create({
        key: CANTEEN_PAPER_CHICKEN_BURST_ANIM_KEY,
        frames: this.anims.generateFrameNumbers(CANTEEN_PAPER_CHICKEN_BURST_KEY, { start: 0, end: 7 }),
        frameRate: 15.4,
        repeat: 0
      });
    }

    const camera = this.cameras.main;
    const windowGlow = this.add.circle(
      steamWindow.x,
      steamWindow.y + 10,
      46,
      0x8ae5ff,
      0.14
    ).setBlendMode(Phaser.BlendModes.SCREEN).setDepth(1603).setAlpha(0);

    const ticketShadow = this.add.rectangle(2, 3, 48, 27, 0x08121a, 0.42);
    const ticketBody = this.add.rectangle(0, 0, 48, 27, 0xe9e6d8, 1)
      .setStrokeStyle(2, 0x36789b, 1);
    const ticketText = this.add.text(0, 0, "0755", {
      color: "#234d67",
      fontFamily: "monospace",
      fontSize: "13px",
      fontStyle: "bold"
    }).setOrigin(0.5);
    const ticket = this.add.container(
      this.player.x,
      this.player.y - 50,
      [ticketShadow, ticketBody, ticketText]
    ).setDepth(2200);
    this.bridge.emit("canteen_pickup_ticket_handoff");
    this.tweens.add({
      targets: ticket,
      x: steamWindow.x,
      y: steamWindow.y + 22,
      scale: 0.72,
      duration: beatMs(100, 650),
      ease: "Sine.easeInOut",
      onComplete: () => {
        this.tweens.add({
          targets: ticket,
          alpha: 0,
          scale: 0.16,
          duration: beatMs(70, 200),
          ease: "Quad.easeIn",
          onComplete: () => ticket.destroy(true)
        });
      }
    });

    const showFinalPreparation = (previewCart: Phaser.GameObjects.Sprite) => {
      const flashMs = beatMs(45, 100);
      previewCart.setVisible(true).setAlpha(0);
      this.tweens.add({
        targets: previewCart,
        alpha: 1,
        duration: flashMs,
        yoyo: true,
        repeat: 1,
        onComplete: () => previewCart.setAlpha(1)
      });
      this.time.delayedCall(beatMs(140, 650), () => {
        this.bridge.emit("canteen_paper_burst_completed");
        this.queueDialogue(["玩家：那是鸡吗？", "系统：现在不是了。"], () => {
          previewCart.destroy();
          windowGlow.destroy();
          this.paperBusy = false;
          this.dialogueLocked = false;
          this.startDefense();
        }, 900);
      });
    };

    const pullBackToEmptyCanteen = () => {
      this.lightNpcSprites.forEach((sprite) => sprite.setVisible(false));
      this.lightNpcCollisionBodies.forEach((collision) => {
        const body = collision.body as Phaser.Physics.Arcade.StaticBody | null;
        if (body) body.enable = false;
        collision.setVisible(false);
      });
      this.shadowNpcSprite?.setVisible(false);
      this.modeFibers.forEach((fiber) => fiber.setVisible(false));
      this.tweens.killTweensOf(this.darkOverlay);
      const pullBackMs = beatMs(120, 850);
      this.tweens.add({
        targets: [this.darkOverlay, windowGlow],
        alpha: 0,
        duration: pullBackMs,
        ease: "Sine.easeOut"
      });
      const fullMapZoom = Math.min(
        RPG_LOGICAL_WIDTH / CANTEEN_INTERIOR_WORLD.width,
        RPG_LOGICAL_HEIGHT / CANTEEN_INTERIOR_WORLD.height
      ) * 0.985;
      camera.stopFollow().setDeadzone(0, 0);
      camera.pan(
        CANTEEN_INTERIOR_WORLD.width / 2,
        CANTEEN_INTERIOR_WORLD.height / 2,
        pullBackMs,
        "Sine.easeOut"
      );
      zoomRpgCameraTo(this, fullMapZoom, pullBackMs, "Sine.easeOut", camera);
      const previewCart = this.add.sprite(908, 628, CANTEEN_PUSH_CART_SHEET_KEY, 8)
        .setScale(0.3)
        .setOrigin(0.5, 0.74)
        .setDepth(760)
        .setAlpha(0);
      this.time.delayedCall(Math.round(pullBackMs * 0.48), () => {
        this.tweens.add({
          targets: previewCart,
          alpha: 1,
          duration: beatMs(40, 90),
          yoyo: true
        });
      });
      this.time.delayedCall(pullBackMs + beatMs(20, 40), () => showFinalPreparation(previewCart));
    };

    const flyPaperToCenter = () => {
      this.paper
        .setTexture(CANTEEN_PAPER_KEY)
        .setPosition(steamWindow.x, steamWindow.y + 24)
        .setScale(2.15)
        .setAlpha(1)
        .setAngle(-12)
        .setVisible(true);
      camera.startFollow(this.paper, true, 0.07, 0.07).setDeadzone(90, 60);
      zoomRpgCameraTo(this, 1.42, beatMs(100, 700), "Sine.easeOut", camera);
      this.tweens.add({
        targets: this.paper,
        x: 836,
        y: 470,
        scale: 1.12,
        angle: 348,
        duration: beatMs(120, 700),
        ease: "Quad.easeOut",
        onComplete: () => {
          this.tweens.add({
            targets: this.paper,
            y: 458,
            duration: beatMs(40, 90),
            repeat: 1,
            yoyo: true,
            ease: "Quad.easeOut",
            onComplete: pullBackToEmptyCanteen
          });
        }
      });
    };

    const slapPaperOntoCamera = () => {
      this.bridge.emit("canteen_paper_camera_impact");
      camera.shake(this.reducedMotion ? 0 : 90, 0.0045);
      const paperCard = this.add.rectangle(0, 0, 330, 170, 0xf5efd9, 0.98)
        .setStrokeStyle(5, 0x58717e, 1);
      const paperTexture = this.add.image(0, -4, CANTEEN_PAPER_KEY)
        .setScale(4.9)
        .setAlpha(0.23)
        .setAngle(-7);
      const closeLine = this.add.text(0, 4, "本人马上回来。", {
        color: "#172128",
        fontFamily: "monospace",
        fontSize: "26px",
        fontStyle: "bold"
      }).setOrigin(0.5);
      const closeup = this.add.container(
        RPG_LOGICAL_WIDTH / 2,
        RPG_LOGICAL_HEIGHT / 2,
        [paperCard, paperTexture, closeLine]
      ).setScrollFactor(0).setDepth(6500).setScale(0.76).setAngle(-5);
      this.tweens.add({
        targets: closeup,
        scale: 1,
        angle: 0,
        duration: beatMs(60, 120),
        ease: "Back.easeOut"
      });
      this.time.delayedCall(beatMs(140, 480), () => {
        closeup.destroy(true);
        flyPaperToCenter();
      });
    };

    const burstPackage = (packageVisual: Phaser.GameObjects.Sprite, bubbleLoop: Phaser.GameObjects.Sprite) => {
      packageVisual.setVisible(false).stop();
      bubbleLoop.destroy();
      this.bridge.emit("canteen_paper_burst_started");
      const burst = this.add.sprite(
        steamWindow.x,
        steamWindow.y + 8,
        CANTEEN_PAPER_CHICKEN_BURST_KEY,
        0
      ).setScale(1.18).setDepth(2120);
      burst.anims.timeScale = 1;
      burst.play(CANTEEN_PAPER_CHICKEN_BURST_ANIM_KEY);
      this.emitPaperChickenBurst(burst.x, burst.y);
      camera.shake(this.reducedMotion ? 0 : 120, 0.006);
      this.time.delayedCall(beatMs(120, 520), () => {
        burst.destroy();
        slapPaperOntoCamera();
      });
    };

    const shakePackage = (packageVisual: Phaser.GameObjects.Sprite, bubbleLoop: Phaser.GameObjects.Sprite) => {
      this.bridge.emit("canteen_paper_package_shake");
      packageVisual.anims.timeScale = 1;
      packageVisual.play(CANTEEN_PAPER_CHICKEN_SHAKE_ANIM_KEY);
      this.time.delayedCall(beatMs(150, 1050), () => burstPackage(packageVisual, bubbleLoop));
    };

    const holdPackageStill = (auntiePush: Phaser.GameObjects.Sprite) => {
      const packageVisual = this.add.sprite(
        steamWindow.x,
        steamWindow.y + 8,
        CANTEEN_PAPER_CHICKEN_SHAKE_KEY,
        0
      ).setOrigin(0.5, 1).setScale(0.62).setDepth(2110);
      const bubbleLoop = this.add.sprite(
        steamWindow.x + 17,
        steamWindow.y - 26,
        CANTEEN_PROMO_FX_KEY,
        0
      ).setScale(0.38).setDepth(2112).play(CANTEEN_PROMO_BUBBLE_ANIM_KEY, true);
      this.tweens.add({
        targets: auntiePush,
        alpha: 0,
        duration: beatMs(80, 260),
        onComplete: () => auntiePush.destroy()
      });
      this.bridge.emit("canteen_paper_package_wait");
      this.time.delayedCall(beatMs(180, 900), () => shakePackage(packageVisual, bubbleLoop));
    };

    const pushPackageFromShadow = () => {
      this.shadowNpcSprite?.setVisible(false);
      const auntiePush = this.add.sprite(
        steamWindow.x,
        steamWindow.y + 30,
        CANTEEN_SHADOW_AUNTIE_PUSH_KEY,
        0
      ).setOrigin(0.5, 1)
        .setScale(0.68)
        .setDepth(2105)
        .setBlendMode(Phaser.BlendModes.SCREEN);
      auntiePush.anims.timeScale = 1;
      auntiePush.play(CANTEEN_SHADOW_AUNTIE_PUSH_ANIM_KEY);
      this.time.delayedCall(beatMs(170, 1400), () => holdPackageStill(auntiePush));
    };

    const pushCameraIntoWindow = () => {
      const pushInMs = beatMs(120, 1100);
      camera.stopFollow().setDeadzone(0, 0);
      camera.pan(steamWindow.x, steamWindow.y + 18, pushInMs, "Sine.easeInOut");
      zoomRpgCameraTo(this, 2.18, pushInMs, "Sine.easeInOut", camera);
      this.time.delayedCall(pushInMs + beatMs(20, 30), pushPackageFromShadow);
    };

    this.time.delayedCall(beatMs(170, 850), () => {
      this.bridge.emit("canteen_pickup_cutscene_quiet");
      this.tweens.add({
        targets: windowGlow,
        alpha: 1,
        duration: beatMs(90, 300)
      });
      this.time.delayedCall(beatMs(120, 650), pushCameraIntoWindow);
    });
  }

  private emitPaperChickenBurst(x: number, y: number): void {
    const colors = [0xffce55, 0x7bdbff, 0xffffff, 0xd98b44] as const;
    Array.from({ length: 22 }, (_unused, index) => {
      const angle = Phaser.Math.DegToRad((360 / 22) * index + Phaser.Math.Between(-9, 9));
      const distance = Phaser.Math.Between(46, 118);
      const shape = index % 3 === 0
        ? this.add.rectangle(x, y, 7, 4, colors[index % colors.length], 0.95)
        : this.add.circle(x, y, index % 4 === 0 ? 6 : 3, colors[index % colors.length], 0.9);
      shape.setDepth(2120 + index);
      this.tweens.add({
        targets: shape,
        x: x + Math.cos(angle) * distance,
        y: y + Math.sin(angle) * distance - (index % 4) * 7,
        alpha: 0,
        scale: index % 3 === 0 ? 1.4 : 0.45,
        duration: this.reducedMotion ? 160 : Phaser.Math.Between(480, 760),
        ease: "Quad.easeOut",
        onComplete: () => shape.destroy()
      });
    });
  }

  private startDefense(): void {
    if (this.defenseRuntime || this.bridge.getState().canteenHunt.phase !== "exit_blocking") return;
    if (!this.player?.active || !this.player.body || !this.paper?.active) {
      this.showFeedback("场景仍在初始化，请稍后再试。", "system", 1200);
      return;
    }
    this.currentPhase = "exit_blocking";
    this.bridge.emit("canteen_defense_started");
    this.applyCanteenNpcMode(this.currentMode, true);
    this.tweens.killTweensOf(this.darkOverlay);
    this.darkOverlay.setAlpha(0);
    this.modeFibers.forEach((fiber) => fiber.setVisible(false));
    // Recreate the Arcade bodies from the authored rectangles when the chase
    // starts. This prevents a long-lived Phaser scene (including dev HMR) from
    // retaining the pre-calibration obstacle geometry.
    this.rebuildStaticCollisionBodies();
    this.paperFloatTween.pause();
    this.cartVisuals.forEach((cart) => {
      cart.setVisible(false);
    });
    this.applyPlayerCollisionBody();
    this.exitGlows.forEach((glow) => glow.setVisible(false));
    this.promptText.setVisible(false);
    this.dialogueLocked = false;
    this.paperBusy = false;

    const camera = this.cameras.main;
    const fullMapZoom = Math.min(
      RPG_LOGICAL_WIDTH / CANTEEN_INTERIOR_WORLD.width,
      RPG_LOGICAL_HEIGHT / CANTEEN_INTERIOR_WORLD.height
    ) * 0.985;
    setRpgLogicalCameraZoom(
      this,
      fullMapZoom,
      camera.stopFollow().setDeadzone(0, 0)
    )
      .centerOn(CANTEEN_INTERIOR_WORLD.width / 2, CANTEEN_INTERIOR_WORLD.height / 2);

    this.defenseRuntime = new CanteenDefenseRuntime(
      this,
      this.player,
      this.paper,
      {
        onComplete: () => {
          this.showFeedback("纸条暂时没有找到能钻出去的流程。", "success", 1500);
          this.bridge.emit("rpg_canteen_defense_completed");
        },
        onFailure: (exitId) => {
          const exitLabel: Record<CanteenDefenseExitId, string> = {
            northwest: "左上门",
            south_gap: "左中下通道",
            southeast: "右下门"
          };
          this.showFeedback(`纸条从${exitLabel[exitId]}溜走了。`, "system", 1100);
          this.defenseRestartTimer?.remove(false);
          this.defenseRestartTimer = this.time.delayedCall(1150, () => {
            this.defenseRuntime?.restartAttempt();
            this.defenseRestartTimer = null;
          });
        },
        onTurnaround: (_exitId, route) => {
          this.flashDefenseRoute(route);
          this.cameras.main.shake(this.reducedMotion ? 0 : 75, 0.0025);
        }
      },
      getDeveloperCanteenDefenseStart()
    );
  }

  private finishDefense(): void {
    this.defenseRestartTimer?.remove(false);
    this.defenseRestartTimer = null;
    this.defenseRuntime?.destroy();
    this.defenseRuntime = null;
    this.defenseRouteGraphics?.clear().setVisible(false);
    this.tweens.killTweensOf(this.darkOverlay);
    this.darkOverlay.setAlpha(0);
    this.modeFibers.forEach((fiber) => fiber.setVisible(false));
    this.paperFloatTween.pause();
    this.paper.setVisible(false);
    if (this.player?.active) this.player.setVelocity(0, 0);
  }

  private flashDefenseRoute(route: readonly Phaser.Math.Vector2[]): void {
    if (!this.defenseRouteGraphics) {
      this.defenseRouteGraphics = this.add.graphics().setDepth(1604);
    }
    const graphics = this.defenseRouteGraphics;
    this.tweens.killTweensOf(graphics);
    graphics.clear().setVisible(true).setAlpha(0.95);
    graphics.lineStyle(5, 0x78ddff, 0.88).beginPath();
    graphics.moveTo(this.paper.x, this.paper.y);
    route.forEach((point) => graphics.lineTo(point.x, point.y));
    graphics.strokePath();
    route.forEach((point, index) => {
      if (index % 2 === 0) graphics.fillStyle(0xdff9ff, 0.9).fillCircle(point.x, point.y, 5);
    });

    this.tweens.add({
      targets: graphics,
      alpha: 0,
      duration: this.reducedMotion ? 420 : 760,
      onComplete: () => {
        graphics.clear().setVisible(false);
      }
    });
  }

  private animateDefenseVictory(onComplete: () => void): void {
    if (this.paperBusy) return;
    this.paperBusy = true;
    const destination = { x: 1380, y: 852 };
    this.tweens.add({
      targets: this.paper,
      x: destination.x,
      y: destination.y,
      scaleX: 0.28,
      scaleY: 0.84,
      angle: 86,
      duration: this.reducedMotion ? 160 : 760,
      ease: "Quad.easeIn",
      onComplete: () => {
        this.time.delayedCall(this.reducedMotion ? 60 : 260, () => {
          this.paperBusy = false;
          onComplete();
        });
      }
    });
  }

  private animateWrongBlock(exitId: CanteenExitId, expectedExit: CanteenExitId): void {
    if (this.paperBusy) return;
    this.paperBusy = true;
    const anchor = CANTEEN_ESCAPE_ANCHORS[expectedExit];
    const origin = { x: this.paper.x, y: this.paper.y };
    this.tweens.add({
      targets: this.paper,
      x: anchor.x,
      y: anchor.y,
      angle: "+=160",
      duration: this.reducedMotion ? 120 : 360,
      yoyo: true,
      hold: 80,
      onYoyo: () => this.showFeedback(canteenContent.blocking.wrong, "system"),
      onComplete: () => {
        this.paper.setPosition(origin.x, origin.y);
        this.restoreFailedCartPush(exitId, () => {
          this.paperBusy = false;
        });
      }
    });
  }

  private animateCorrectBlock(exitId: CanteenExitId, blockHits: number, complete: boolean): void {
    if (this.paperBusy) return;
    this.paperBusy = true;
    const anchor = CANTEEN_ESCAPE_ANCHORS[exitId];
    const paperOrigin = { x: this.paper.x, y: this.paper.y };
    this.bridge.emit("canteen_paper_block_impact", { blockHits, exitId });
    this.tweens.add({
      targets: this.paper,
      x: anchor.x,
      y: anchor.y,
      angle: "+=120",
      duration: this.reducedMotion ? 120 : 320,
      ease: "Cubic.easeIn",
      onComplete: () => {
        this.cameras.main.shake(this.reducedMotion ? 0 : 90, 0.004);
        if (!complete) {
          const feedback = blockHits === 1 ? canteenContent.blocking.correct[0] : canteenContent.blocking.correct[1];
          this.showFeedback(feedback, "success");
          this.tweens.add({
            targets: this.paper,
            x: paperOrigin.x,
            y: paperOrigin.y,
            angle: "+=180",
            duration: this.reducedMotion ? 120 : 420,
            ease: "Back.easeOut",
            onComplete: () => {
              this.paperBusy = false;
              this.finishCartMotion(exitId);
            }
          });
          return;
        }
        this.paperBusy = false;
        this.finishCartMotion(exitId);
        this.queueDialogue(canteenContent.blocking.escapeDialogue, () => {
          this.bridge.emit("rpg_canteen_leave_requested");
        });
      }
    });
  }

  private queueDialogue(
    lines: readonly string[],
    onComplete?: () => void,
    stepMs = DIALOGUE_STEP_MS
  ): void {
    this.dialogueLocked = true;
    lines.forEach((text, index) => {
      this.time.delayedCall(index * stepMs, () => {
        this.showFeedback(text, this.dialogueToneFor(text), stepMs - 120);
      });
    });
    this.time.delayedCall(lines.length * stepMs, () => {
      this.dialogueLocked = false;
      onComplete?.();
    });
  }

  private dialogueToneFor(text: string): GameSubtitleTone {
    if (text.startsWith("玩家：")) return "player";
    if (text.startsWith("系统：")) return "system";
    if (text.startsWith("任务：")) return "task";
    return "narrator";
  }

  private showFeedback(text: string, tone: GameSubtitleTone, durationMs = DIALOGUE_STEP_MS - 120): void {
    this.bridge.emit("rpg_subtitle", {
      text,
      tone,
      durationMs
    });
  }

  private publishDebugState(nearest: CanteenInteractionTarget | null, state: GameState): void {
    if (deferRpgRuntimeDebugCapture(() => this.publishDebugState(nearest, state))) return;
    const modalPanelOpen = this.hasModalPanel();
    setRpgRuntimeDebugState({
      coordinateSystem: "Phaser world coordinates, origin at top-left, x right, y down",
      world: CANTEEN_INTERIOR_WORLD,
      player: {
        x: Math.round(this.player.x),
        y: Math.round(this.player.y),
        facing: this.playerAnimator.facing,
        cardinalFacing: this.playerAnimator.cardinalFacing,
        texture: this.playerAnimator.textureKey,
        turning: this.playerAnimator.isTurning,
        walkFps: RPG_PLAYER_WALK_FPS,
        collisionWidth: Number((this.player.body?.width ?? 0).toFixed(2)),
        collisionHeight: Number((this.player.body?.height ?? 0).toFixed(2))
      },
      input: {
        gameEnabled: this.game.input.enabled,
        sceneEnabled: this.input.enabled,
        keyboardEnabled: this.input.keyboard?.enabled ?? false,
        keys: {
          up: this.cursors.up.isDown || this.keys.W.isDown,
          down: this.cursors.down.isDown || this.keys.S.isDown,
          left: this.cursors.left.isDown || this.keys.A.isDown,
          right: this.cursors.right.isDown || this.keys.D.isDown,
          interact: this.cursors.space.isDown
        }
      },
      camera: {
        scrollX: Math.round(this.cameras.main.scrollX),
        scrollY: Math.round(this.cameras.main.scrollY),
        zoom: Number(this.cameras.main.zoom.toFixed(2)),
        mode: this.defenseRuntime ? "manual" : "follow"
      },
      scene: "canteen_interior",
      interiorDoor: this.exitDoor.getDebugSnapshot(),
      interiorDoorTrigger: {
        proximityActive: this.exitDoorProximityActive,
        approachBounds: CANTEEN_SOUTHEAST_EXIT_DOOR.approachBounds,
        holdOpenBounds: CANTEEN_SOUTHEAST_EXIT_DOOR.holdOpenBounds
      },
      activeTargets: this.getActiveTargets(state).map((target) => {
        const bounds = getRpgDropBounds(target);
        return {
          id: target.id,
          label: target.label,
          x: target.x,
          y: target.y,
          width: bounds.width,
          height: bounds.height,
          dropWidth: target.dropWidth,
          dropHeight: target.dropHeight,
          stand: target.stand,
          proximity: target.proximity,
          acceptedItem: target.acceptedItem,
          requiredMode: target.requiredMode
        };
      }),
      canteen: {
        phase: state.canteenHunt.phase,
        mode: state.canteenHunt.mode,
        identifiedTrayIds: state.canteenHunt.identifiedTrayIds,
        returnedTrayIds: state.canteenHunt.returnedTrayIds,
        menuDarkClueRead: state.canteenHunt.menuDarkClueRead,
        pickupDarkClueRead: state.canteenHunt.pickupDarkClueRead,
        identifiedExitIds: state.canteenHunt.identifiedExitIds,
        blockHits: state.canteenHunt.blockHits,
        queueGapOpened: state.canteenHunt.queueGapOpened,
        queueColumnThreeYs: this.thirdColumnQueue.map((entry) => Math.round(entry.sprite.y)),
        defense: this.defenseRuntime?.getDebugSnapshot(),
        activeTarget: nearest?.id ?? null,
        pickupTargets: CANTEEN_PICKUP_WINDOWS.map((window) => ({
          id: window.id,
          window: window.value,
          anchor: { x: window.x, y: window.y },
          objectBounds: {
            width: window.width ?? getRpgDropBounds(window).width,
            height: window.height ?? getRpgDropBounds(window).height
          },
          proximity: window.proximity,
          dropBounds: getRpgDropBounds(window),
          acceptedItem: window.acceptedItem,
          requiredMode: window.requiredMode
        })),
        menuOpen: this.menuPanel !== null,
        dialogueLocked: this.dialogueLocked,
        paperBusy: this.paperBusy,
        entryPaperPending: this.entryPaperPending,
        entryPaperTriggered: this.entryPaperTriggered,
        entryPaperDistance: this.paper?.active
          ? Number(Phaser.Math.Distance.Between(this.player.x, this.player.y, this.paper.x, this.paper.y).toFixed(1))
          : null,
        entryPaperTriggerRadius: ENTRY_PAPER_TRIGGER_RADIUS,
        movementAllowed: this.isMovementAllowed(state),
        movementBlockers: {
          storyMovementDisabled: !state.actOne.movementEnabled,
          modalPanelOpen,
          paperBusy: this.paperBusy,
          cartPushBusy: this.cartPushBusy,
          exitTransitioning: this.exitTransitioning
        },
        activeOcclusionIds: this.activeOcclusionIds,
        softenedOcclusionIds: this.softenedOcclusionIds
      },
      collisionRects: CANTEEN_STATIC_COLLISION_RECTS
    });
  }
}
