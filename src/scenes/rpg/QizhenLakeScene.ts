import Phaser from "phaser";
import qizhenChannelUrl from "../../assets/rpg/interiors/qizhen_lake_channel.png";
import qizhenDockUrl from "../../assets/rpg/interiors/qizhen_lake_dock.png";
import qizhenDockNoSignUrl from "../../assets/rpg/interiors/qizhen_lake_dock_no_sign.png";
import qizhenOpenWaterUrl from "../../assets/rpg/interiors/qizhen_lake_open_water.png";
import qizhenSwanCoveUrl from "../../assets/rpg/interiors/qizhen_lake_swan_cove.png";
import safetyOfficerSheetUrl from "../../assets/rpg/npcs/finale/guard_check_watch_2frame.png";
import qizhenContent from "../../data/chapter3-qizhen-lake.content.json";
import type { GameSubtitleTone } from "../../components/GameSubtitleFrame";
import type {
  GameState,
  ItemId,
  QizhenLakeMode,
  QizhenPaddleDirection,
  QizhenPhotoRecipe,
  QizhenPhotoSpotId
} from "../../core/types";
import type { RpgBridge } from "./RpgBridge";
import { formatRpgDragHint, formatRpgInteractionHint } from "./RpgControlHints";
import { RPG_HUD_LAYOUT } from "./RpgHudLayout";
import {
  formatRpgModeRequirement,
  getRpgDropBounds,
  isPlayerWithinRpgTarget,
  isRpgDropPointWithin,
  RPG_REALITY_MODE_CONTRACT
} from "./RpgInteractionContract";
import {
  configureRpgPlayerSprite,
  ensureRpgPlayerTextures,
  preloadRpgPlayerTextures,
  RpgPlayerAnimator,
  RPG_PLAYER_WALK_FPS
} from "./RpgPlayerTextures";
import { clearRpgRuntimeDebugState, setRpgRuntimeDebugState } from "./RpgRuntimeDebug";
import {
  getRpgLogicalCameraZoom,
  setRpgLogicalCameraZoom
} from "./RpgRenderResolution";
import { subscribeRpgSceneBridge } from "./RpgSceneBridgeSubscription";
import {
  QIZHEN_DOCK_AFTER_RAIN_PUDDLES,
  QIZHEN_DOCK_RAIN_EFFECT_PROFILE,
  QIZHEN_DOCK_RAIN_SPLASH_SITES,
  QIZHEN_LAKE_TARGETS,
  QIZHEN_LAKE_WORLD,
  QIZHEN_LAKE_ZONES,
  buildQizhenPhotoRecipe,
  clampKayakToWater,
  findNearestQizhenTarget,
  isQizhenAfterRainPuddleFootHit,
  nearestQizhenPhotoSpot,
  qizhenTargetAcceptsItem,
  resolveQizhenPhotoSpot,
  targetsForQizhenZone,
  type QizhenLakeInteractionTarget,
  type QizhenLakeOcclusionRect,
  type QizhenLakeVehicle,
  type QizhenLakeZoneId
} from "./QizhenLakeModel";
import {
  createQizhenBlackSwanVisual,
  preloadQizhenKayakTextures,
  QIZHEN_KAYAK_TEXTURE_ASSET_URLS,
  QizhenKayakVisual,
  type QizhenBlackSwanVisual,
  type QizhenPaddleSide
} from "./QizhenKayakTextures";
import { detectInputProfile, getAudioContextConstructor } from "../../core/ClientCompatibility";
import { DEVELOPER_QIZHEN_RHYTHM_SPAWN_KEY } from "../../core/StorageKeys";
import {
  QIZHEN_FISHING_TIMING,
  QizhenFishingRhythmModel,
  type QizhenFishingAction,
  type QizhenFishingChartId,
  type QizhenFishingFailReason,
  type QizhenFishingResult
} from "./QizhenFishingRhythmModel";
import { QizhenFishingRhythmVisual } from "./QizhenFishingRhythmVisual";

const ZONE_TEXTURE_KEYS: Readonly<Record<QizhenLakeZoneId, string>> = {
  dock: "chapter-3-qizhen-dock",
  open_water: "chapter-3-qizhen-open-water",
  channel: "chapter-3-qizhen-channel",
  swan_cove: "chapter-3-qizhen-swan-cove"
};
export const QIZHEN_LAKE_WARM_ASSET_URLS = Object.freeze([
  qizhenChannelUrl,
  qizhenDockUrl,
  qizhenDockNoSignUrl,
  qizhenOpenWaterUrl,
  qizhenSwanCoveUrl,
  ...QIZHEN_KAYAK_TEXTURE_ASSET_URLS
  ,safetyOfficerSheetUrl
]);
const DOCK_NO_SIGN_TEXTURE_KEY = "chapter-3-qizhen-dock-no-sign";
const SAFETY_OFFICER_TEXTURE_KEY = "chapter-3-qizhen-safety-officer";
const SAFETY_OFFICER_ANIMATION_KEY = "chapter-3-qizhen-safety-officer-idle";

const WALK_SPEED = 165;
const RUN_SPEED = 228;
const KAYAK_MAX_SPEED = 340;
const KAYAK_MAX_REVERSE_SPEED = 230;
const KAYAK_STROKE_SPEED = 104;
const KAYAK_SAME_SIDE_SPEED = 52;
const KAYAK_REVERSE_STROKE_SPEED = 84;
const KAYAK_REVERSE_SAME_SIDE_SPEED = 42;
const KAYAK_DRAG_PER_SECOND = 0.68;
const KAYAK_ROLL_DECAY_PER_SECOND = 1.05;
const KAYAK_TURN_PER_STROKE = 0.16;
const KAYAK_CAPSIZE_THRESHOLD = 0.92;
const KAYAK_COLLISION_LENGTH = 83;
const KAYAK_COLLISION_WIDTH = 67;
const SWAN_CHASE_INITIAL_GAP = 230;
const SWAN_CHASE_CATCH_DISTANCE = 104;
const SWAN_CHASE_NEAR_DISTANCE = 150;
const SWAN_CHASE_FAR_DISTANCE = 360;
const SWAN_CHASE_NEAR_SPEED = 168;
const SWAN_CHASE_FAR_SPEED = 440;
const SWAN_CHASE_GRACE_SECONDS = 4;
const SWAN_CHASE_SWAY = 16;
const SWAN_CHASE_FINISH_X = 190;
const FEEDBACK_MS = 2700;
const LOCKED_PORTAL_HINT_REPEAT_MS = 6000;
const SAME_SIDE_HINT_COOLDOWN_MS = 2600;
const BOUNDARY_BLOCKED_HINT_COOLDOWN_MS = 2400;
/** 相机打开期间瞬时速度的指数衰减率(每秒),让船速缓慢归零而不是突停。 */
const PHOTO_SESSION_SPEED_DAMPING_PER_SECOND = 2.4;
/** 黑天鹅静态视觉锚点(源像素),与 createZoneSwan 的站位一致。 */
const SWAN_COVE_SWAN_ANCHOR = { x: 1160, y: 400 } as const;

const CHAIN_ITEMS = {
  fishingRod: "fishingRod",
  key: "rustedLockerKey",
  cord: "nylonCord",
  netFrame: "brokenNetFrame",
  dipNet: "improvisedDipNet",
  feedTin: "sealedFeedTin",
  pellets: "fishFeedPellets",
  fish: "smallCarp",
  magnet: "swanMagnet",
  magneticRod: "magneticFishingRod",
  decoy: "decoyPaper"
} as const satisfies Record<string, ItemId>;

/** 四个节奏钓鱼目标：targetId → spotId（spotId 与谱面 id 一一对应）。 */
const QIZHEN_FISHING_SPOT_BY_TARGET: Readonly<Record<string, QizhenFishingChartId>> = {
  qizhen_fishing_item_1: "locker_key",
  qizhen_fishing_item_3: "net_frame",
  qizhen_fishing_fish: "fish",
  qizhen_final_paper_cast: "paper"
};
const QIZHEN_FISHING_SPOT_LABELS: Readonly<Record<QizhenFishingChartId, string>> = {
  locker_key: "生锈的柜门钥匙",
  net_frame: "破损网框",
  fish: "小鲤鱼",
  paper: "纸条本体"
};

function isQizhenWaterRippleTarget(target: QizhenLakeInteractionTarget): boolean {
  return target.kind === "reflection"
    || target.kind === "paper"
    || (target.kind === "fishing_spot" && target.value !== "fishing_rod");
}
/** 宿主预检回包超时兜底（正常为同一事件轮回包）。 */
const FISHING_PRECHECK_TIMEOUT_MS = 2000;

type QizhenRuntimePhase =
  | "inactive"
  | "location_search"
  | "lake_unlocked"
  | "dock_outfitting"
  | "boarding_tutorial"
  | "rain_recovery"
  | "lake_exploration"
  | "tool_chain"
  | "swan_exchange"
  | "paper_capture"
  | "swan_chase"
  | "complete"
  | "reflection_hunt"
  | "sign_alignment"
  | "decoy_setup"
  | "mist_timing"
  | "chase_ready";

interface QizhenRuntimeProjection {
  phase: QizhenRuntimePhase;
  mode: QizhenLakeMode;
  zone: QizhenLakeZoneId;
  vehicle: QizhenLakeVehicle;
  introSeen: boolean;
  kayakEquipped: boolean;
  leftPaddleEquipped: boolean;
  rightPaddleEquipped: boolean;
  rainSafetyCleared: boolean;
  boardingStrokeCount: number;
  boardingLastSide: QizhenPaddleSide | null;
  boardingTutorialCompleted: boolean;
  capsizeCount: number;
  rodFound: boolean;
  decoyBaitAttached: boolean;
  reflectionLocationObserved: boolean;
  observedFishingSpotIds: string[];
  directPaperCastFailures: number;
  lockerOpened: boolean;
  netCombined: boolean;
  feedTinRetrieved: boolean;
  feedTinOpened: boolean;
  fishCaught: boolean;
  swanFed: boolean;
  magneticRodCombined: boolean;
  paperCaptured: boolean;
  swanReleased: boolean;
  chaseDistance: number;
  chaseBestDistance: number;
  chaseAttempts: number;
  magneticAttachmentBroken: boolean;
  transitionReady: boolean;
  safeSpawnId: string;
}

interface OcclusionVisual {
  definition: QizhenLakeOcclusionRect;
  bounds: Phaser.Geom.Rectangle;
  image: Phaser.GameObjects.Image;
}

interface TargetVisual {
  target: QizhenLakeInteractionTarget;
  root: Phaser.GameObjects.Container;
  label: Phaser.GameObjects.Text;
  pulse: Phaser.GameObjects.Shape;
  color: number;
  sparkles: Phaser.GameObjects.Arc[];
  rippleBands: Phaser.GameObjects.Ellipse[];
  rippleCenter: Phaser.GameObjects.Arc | null;
}

interface DropGuideVisual {
  target: QizhenLakeInteractionTarget;
  targetOutline: Phaser.GameObjects.Rectangle;
}

interface QizhenFishingAttempt {
  sessionId: string;
  spotId: QizhenFishingChartId;
  target: QizhenLakeInteractionTarget;
  itemId: ItemId;
  targetLabel: string;
}

export class QizhenLakeScene extends Phaser.Scene {
  private bridge!: RpgBridge;
  private player!: Phaser.Physics.Arcade.Sprite;
  private playerAnimator!: RpgPlayerAnimator;
  private playerCollider!: Phaser.Physics.Arcade.Collider;
  private obstacles!: Phaser.Physics.Arcade.StaticGroup;
  private mapImage!: Phaser.GameObjects.Image;
  private kayak!: QizhenKayakVisual;
  private darkOverlay!: Phaser.GameObjects.Rectangle;
  private promptText!: Phaser.GameObjects.Text;
  private statusText!: Phaser.GameObjects.Text;
  private zoneText!: Phaser.GameObjects.Text;
  private cursors!: Phaser.Types.Input.Keyboard.CursorKeys;
  private keys!: Record<"W" | "A" | "S" | "D" | "C" | "SHIFT" | "TAB", Phaser.Input.Keyboard.Key>;

  private currentZone: QizhenLakeZoneId = "dock";
  private currentVehicle: QizhenLakeVehicle = "on_foot";
  private currentPhase: QizhenRuntimePhase = "dock_outfitting";
  private currentMode: QizhenLakeMode = "light";
  private currentDockSignRemoved = false;
  private currentRainSafetyCleared = false;
  private virtualDirection = { x: 0, y: 0 };
  private lastVirtualPaddleX = 0;
  private virtualReverseHeld = false;
  private reverseInputHeld = false;
  private interactRequested = false;
  private dialogueLocked = false;
  private zoneTransitioning = false;
  private capsizing = false;
  private rainRescueAnimating = false;
  private reducedMotion = false;

  private targetVisuals: TargetVisual[] = [];
  private dropGuides: DropGuideVisual[] = [];
  private ambientVisuals: Phaser.GameObjects.GameObject[] = [];
  private occlusionVisuals: OcclusionVisual[] = [];
  private activeOcclusionIds: string[] = [];
  private softenedOcclusionIds: string[] = [];
  private staticSwan: QizhenBlackSwanVisual | null = null;
  private chaseSwan: QizhenBlackSwanVisual | null = null;

  private kayakHeading = -Math.PI / 2;
  private kayakSpeed = 0;
  private kayakRoll = 0;
  private lastStrokeSide: QizhenPaddleSide | null = null;
  private lastStrokeDirection: QizhenPaddleDirection | null = null;
  private sameSideStreak = 0;
  private strokeIndex = 0;
  private lastStrokeAt = 0;
  private lastChaseProgressSent = 0;
  private chaseStartX = 0;
  private chaseElapsedSeconds = 0;
  private chaseActualGap = SWAN_CHASE_INITIAL_GAP;
  private chaseSwanSpeed = 0;
  private chaseIntensity = 0;
  private chaseSwanX = 0;
  private chaseSwanY = 0;
  private chaseAnnounced = false;
  private chaseCompleting = false;
  private chaseFailing = false;
  private lockedPortalHintId: string | null = null;
  private lockedPortalHintAt = 0;
  private sameSideHintAt = 0;
  private boundaryBlockedHintAt = Number.NEGATIVE_INFINITY;
  private kayakBoundaryBlocked = false;
  private boundaryBlockCount = 0;
  private boundaryHeadingAtBlock = 0;
  private boundaryRollAtBlock = 0;
  private reflectionDialoguePlayed = false;
  private enteredAfterRainPuddleIds = new Set<string>();
  private activeAfterRainPuddleId: string | null = null;

  private photoSessionOpen = false;
  private photoSessionSpotId: QizhenPhotoSpotId | null = null;
  private lastPhotoSessionRequest: {
    spotId: QizhenPhotoSpotId;
    recipe: QizhenPhotoRecipe;
    speed: number;
    roll: number;
    kind: "main" | "spot";
    capturedAtSeconds: number;
  } | null = null;
  private photoCameraButton: Phaser.GameObjects.Container | null = null;

  private fishingPendingAttempt: QizhenFishingAttempt | null = null;
  private fishingActiveAttempt: QizhenFishingAttempt | null = null;
  private fishingModel: QizhenFishingRhythmModel | null = null;
  private fishingVisual: QizhenFishingRhythmVisual | null = null;
  private fishingPrecheckTimer: Phaser.Time.TimerEvent | null = null;
  private fishingAudioContext: AudioContext | null = null;
  private fishingClockNow: () => number = () => performance.now() / 1000;
  private fishingUsesAudioClock = false;
  private fishingStartedAtSec = 0;
  private fishingNextMetronomeBeat = 0;
  private fishingSessionSerial = 0;
  private fishingResolving = false;
  private fishingHeldActions = new Set<QizhenFishingAction>();
  private readonly fishingFailureCounts: Record<QizhenFishingChartId, number> = {
    locker_key: 0,
    net_frame: 0,
    fish: 0,
    paper: 0
  };
  private fishingVisibilityHandler: (() => void) | null = null;

  constructor() {
    super("qizhen-lake");
  }

  preload(): void {
    const sources: Readonly<Record<QizhenLakeZoneId, string>> = {
      dock: qizhenDockUrl,
      open_water: qizhenOpenWaterUrl,
      channel: qizhenChannelUrl,
      swan_cove: qizhenSwanCoveUrl
    };
    (Object.keys(sources) as QizhenLakeZoneId[]).forEach((zone) => {
      if (!this.textures.exists(ZONE_TEXTURE_KEYS[zone])) {
        this.load.image(ZONE_TEXTURE_KEYS[zone], sources[zone]);
      }
    });
    if (!this.textures.exists(DOCK_NO_SIGN_TEXTURE_KEY)) {
      this.load.image(DOCK_NO_SIGN_TEXTURE_KEY, qizhenDockNoSignUrl);
    }
    if (!this.textures.exists(SAFETY_OFFICER_TEXTURE_KEY)) {
      this.load.spritesheet(SAFETY_OFFICER_TEXTURE_KEY, safetyOfficerSheetUrl, {
        frameWidth: 96,
        frameHeight: 128
      });
    }
    preloadQizhenKayakTextures(this);
    preloadRpgPlayerTextures(this);
  }

  create(): void {
    this.resetTransientKayakState();
    this.bridge = this.registry.get("rpgBridge") as RpgBridge;
    const state = this.bridge.getState();
    const runtime = readQizhenRuntime(state);
    this.currentZone = runtime.zone;
    this.currentVehicle = runtime.vehicle;
    this.currentPhase = runtime.phase;
    this.currentMode = runtime.mode;
    this.currentDockSignRemoved = runtime.rightPaddleEquipped;
    this.currentRainSafetyCleared = runtime.rainSafetyCleared;
    this.strokeIndex = runtime.boardingStrokeCount;
    this.lastStrokeSide = runtime.boardingLastSide;
    this.reducedMotion = window.matchMedia?.("(prefers-reduced-motion: reduce)").matches === true;

    this.cameras.main.setBackgroundColor(0x031722);
    this.physics.world.setBounds(0, 0, QIZHEN_LAKE_WORLD.width, QIZHEN_LAKE_WORLD.height);
    this.obstacles = this.physics.add.staticGroup();
    this.mapImage = this.add.image(0, 0, this.getZoneTextureKey(this.currentZone)).setOrigin(0).setDepth(-1000);

    ensureRpgPlayerTextures(this);
    if (!this.anims.exists(SAFETY_OFFICER_ANIMATION_KEY)) {
      this.anims.create({
        key: SAFETY_OFFICER_ANIMATION_KEY,
        frames: this.anims.generateFrameNumbers(SAFETY_OFFICER_TEXTURE_KEY, { start: 0, end: 1 }),
        frameRate: 2,
        repeat: -1
      });
    }
    const spawn = this.getInitialSpawn(runtime);
    this.player = this.physics.add.sprite(spawn.x, spawn.y, "act1-player-up-0");
    if ("heading" in spawn) this.kayakHeading = spawn.heading;
    this.player.setCollideWorldBounds(true).setDepth(spawn.y + 120);
    configureRpgPlayerSprite(this.player);
    this.playerAnimator = new RpgPlayerAnimator(this.player, "up");
    this.playerCollider = this.physics.add.collider(this.player, this.obstacles);
    this.kayak = new QizhenKayakVisual(this);

    this.cursors = this.input.keyboard!.createCursorKeys();
    this.keys = this.input.keyboard!.addKeys("W,A,S,D,C,SHIFT,TAB") as Record<
      "W" | "A" | "S" | "D" | "C" | "SHIFT" | "TAB",
      Phaser.Input.Keyboard.Key
    >;
    this.input.keyboard!.addCapture([
      Phaser.Input.Keyboard.KeyCodes.TAB,
      Phaser.Input.Keyboard.KeyCodes.SPACE,
      Phaser.Input.Keyboard.KeyCodes.LEFT,
      Phaser.Input.Keyboard.KeyCodes.RIGHT,
      Phaser.Input.Keyboard.KeyCodes.DOWN,
      Phaser.Input.Keyboard.KeyCodes.A,
      Phaser.Input.Keyboard.KeyCodes.D,
      Phaser.Input.Keyboard.KeyCodes.S
    ]);

    setRpgLogicalCameraZoom(
      this,
      1,
      this.cameras.main.setBounds(0, 0, QIZHEN_LAKE_WORLD.width, QIZHEN_LAKE_WORLD.height)
    )
      .startFollow(this.player, true, 0.13, 0.13, 0, 18)
      .setDeadzone(250, 150);

    this.darkOverlay = this.add.rectangle(
      QIZHEN_LAKE_WORLD.width / 2,
      QIZHEN_LAKE_WORLD.height / 2,
      QIZHEN_LAKE_WORLD.width,
      QIZHEN_LAKE_WORLD.height,
      0x06142d,
      0.66
    ).setDepth(3000).setAlpha(this.currentMode === "dark" ? 0.66 : 0).setInteractive(false);

    this.zoneText = this.add.text(18, 78, "", {
      color: "#e9ffff",
      fontFamily: "monospace",
      fontSize: "13px",
      stroke: "#07111c",
      strokeThickness: 4
    }).setScrollFactor(0).setDepth(5200);
    this.statusText = this.add.text(18, 112, "", {
      color: "#fff2b6",
      fontFamily: "monospace",
      fontSize: "12px",
      stroke: "#07111c",
      strokeThickness: 4
    }).setScrollFactor(0).setDepth(5200);
    this.promptText = this.add.text(RPG_HUD_LAYOUT.centerX, RPG_HUD_LAYOUT.promptBottomY, "", {
      color: "#fff7df",
      fontFamily: "monospace",
      fontSize: "13px",
      stroke: "#07111c",
      strokeThickness: 4,
      align: "center"
    }).setOrigin(0.5, 1).setScrollFactor(0).setDepth(5200).setVisible(false);

    this.createPhotoCameraButton();
    this.rebuildZone(this.currentZone, this.currentVehicle, null, false);
    this.applyVehicle(this.currentVehicle, false);

    subscribeRpgSceneBridge(
      this.events,
      this.bridge,
      (event) => this.handleBridgeEvent(event.name, event.payload),
      clearRpgRuntimeDebugState
    );
    this.fishingVisibilityHandler = () => {
      if (document.visibilityState === "hidden") {
        this.cancelFishingSession("visibility_hidden");
      }
    };
    document.addEventListener("visibilitychange", this.fishingVisibilityHandler);
    this.events.once(Phaser.Scenes.Events.SHUTDOWN, () => {
      this.cancelFishingSession("scene_shutdown");
      if (this.fishingVisibilityHandler) {
        document.removeEventListener("visibilitychange", this.fishingVisibilityHandler);
        this.fishingVisibilityHandler = null;
      }
      const audioContext = this.fishingAudioContext;
      this.fishingAudioContext = null;
      if (audioContext && audioContext.state !== "closed") {
        void audioContext.close().catch(() => undefined);
      }
      this.resetTransientKayakState();
      this.kayak.destroy();
      this.staticSwan?.destroy();
      this.chaseSwan?.destroy();
    });

    this.emitDomain("rpg_booted", {
      scene: "qizhen_lake",
      zone: this.currentZone,
      vehicle: this.currentVehicle,
      projection: "top-down-water"
    });
    const prologueReplayActive = state.chapterThreeInterlude.phase === "replay_ready"
      && state.chapterThreeInterlude.replayUnlocked
      && !state.chapter4.prologueSeen;
    if (!prologueReplayActive) {
      this.emitDomain("qizhen_lake_opened", {
        phase: this.currentPhase,
        zone: this.currentZone,
        vehicle: this.currentVehicle
      });
    }
    if (!runtime.introSeen && runtime.phase === "dock_outfitting") {
      this.queueDialogue(
        qizhenContent.dock.intro.slice(0, 2),
        () => this.emitDomain("rpg_qizhen_intro_seen_requested")
      );
    } else {
      this.maybePlayReflectionDialogue();
    }
  }

  update(_time: number, delta: number): void {
    const state = this.bridge.getState();
    const runtime = readQizhenRuntime(state);
    this.syncState(runtime);

    if (this.rainRescueAnimating) {
      this.player.setVelocity(0, 0);
      this.playerAnimator.update(new Phaser.Math.Vector2(0, 0), this.time.now);
      this.interactRequested = false;
      return;
    }

    if (this.fishingPendingAttempt || this.fishingActiveAttempt) {
      this.updateFishingSession(runtime);
      this.interactRequested = false;
      return;
    }

    if (
      Phaser.Input.Keyboard.JustDown(this.keys.TAB)
      && !this.dialogueLocked
      && !this.zoneTransitioning
      && !this.photoSessionOpen
    ) {
      if (runtime.phase === "swan_chase" || runtime.phase === "complete") {
        this.showFeedback(qizhenContent.mist.modeLocked, "system");
      } else {
        this.emitDomain("rpg_qizhen_mode_requested", {
          mode: runtime.mode === "dark" ? "light" : "dark"
        });
      }
    }

    if (Phaser.Input.Keyboard.JustDown(this.keys.C)) {
      this.requestPhotoSession();
    }

    if (this.currentVehicle === "kayak") {
      this.updateKayakInput(runtime);
      this.updateKayakMotion(delta / 1000, runtime);
    } else {
      this.updateOnFootMovement(state);
    }
    this.updateAfterRainPuddleEvidence();

    this.updateOcclusion();
    const targets = this.getActiveTargets(state, runtime);
    const nearest = findNearestQizhenTarget(this.player.x, this.player.y, targets);
    this.updateTargetVisuals(targets, nearest, state, runtime);
    this.updatePrompt(nearest, runtime);
    this.updateStatus(runtime);
    this.syncPhotoCameraButton();
    this.updateLockedPortalHint(targets, runtime);
    this.publishDebugState(nearest, targets, runtime);

    const keyboardInteract = Phaser.Input.Keyboard.JustDown(this.cursors.space);
    if (
      nearest
      && !this.dialogueLocked
      && !this.zoneTransitioning
      && !this.capsizing
      && !this.photoSessionOpen
      && (keyboardInteract || this.interactRequested)
    ) {
      this.triggerTarget(nearest, state, runtime);
    }
    this.interactRequested = false;
  }

  private updateOnFootMovement(state: GameState): void {
    const keyboardX = Number(this.cursors.right.isDown || this.keys.D.isDown)
      - Number(this.cursors.left.isDown || this.keys.A.isDown);
    const keyboardY = Number(this.cursors.down.isDown || this.keys.S.isDown)
      - Number(this.cursors.up.isDown || this.keys.W.isDown);
    const vector = new Phaser.Math.Vector2(
      Phaser.Math.Clamp(keyboardX + this.virtualDirection.x, -1, 1),
      Phaser.Math.Clamp(keyboardY + this.virtualDirection.y, -1, 1)
    );
    if (state.actOne.movementEnabled && !this.dialogueLocked && !this.zoneTransitioning && !this.photoSessionOpen && vector.lengthSq() > 0) {
      vector.normalize().scale(this.keys.SHIFT.isDown ? RUN_SPEED : WALK_SPEED);
    } else {
      vector.set(0, 0);
    }
    this.player.setVelocity(vector.x, vector.y).setDepth(this.player.y + 120);
    this.playerAnimator.update(vector, this.time.now);
  }

  private updateKayakInput(runtime: QizhenRuntimeProjection): void {
    this.reverseInputHeld = this.cursors.down.isDown || this.keys.S.isDown || this.virtualReverseHeld;
    if (this.dialogueLocked || this.zoneTransitioning || this.capsizing || this.photoSessionOpen) return;
    const direction: QizhenPaddleDirection = this.reverseInputHeld ? "reverse" : "forward";
    if (Phaser.Input.Keyboard.JustDown(this.cursors.left) || Phaser.Input.Keyboard.JustDown(this.keys.A)) {
      this.performPaddleStroke("left", direction, runtime);
    }
    if (Phaser.Input.Keyboard.JustDown(this.cursors.right) || Phaser.Input.Keyboard.JustDown(this.keys.D)) {
      this.performPaddleStroke("right", direction, runtime);
    }
  }

  private resetTransientKayakState(): void {
    this.virtualDirection = { x: 0, y: 0 };
    this.lastVirtualPaddleX = 0;
    this.virtualReverseHeld = false;
    this.reverseInputHeld = false;
    this.kayakSpeed = 0;
    this.kayakRoll = 0;
    this.lastStrokeDirection = null;
    this.sameSideStreak = 0;
    this.lastStrokeAt = 0;
    this.capsizing = false;
    this.rainRescueAnimating = false;
    this.chaseFailing = false;
    this.chaseSwanSpeed = 0;
    this.chaseActualGap = SWAN_CHASE_INITIAL_GAP;
    this.boundaryBlockedHintAt = Number.NEGATIVE_INFINITY;
    this.kayakBoundaryBlocked = false;
    this.boundaryBlockCount = 0;
    this.boundaryHeadingAtBlock = this.kayakHeading;
    this.boundaryRollAtBlock = 0;
    this.photoSessionOpen = false;
    this.photoSessionSpotId = null;
    this.lastPhotoSessionRequest = null;
    this.enteredAfterRainPuddleIds.clear();
    this.activeAfterRainPuddleId = null;
  }

  private performPaddleStroke(
    side: QizhenPaddleSide,
    direction: QizhenPaddleDirection,
    runtime: QizhenRuntimeProjection,
    emitIntent = true
  ): void {
    if (this.currentVehicle !== "kayak" || this.capsizing || this.zoneTransitioning || this.chaseCompleting) return;
    const now = this.time.now;
    const withinCadence = now - this.lastStrokeAt <= 1450;
    const sameDirection = withinCadence && this.lastStrokeDirection === direction;
    const alternating = sameDirection && this.lastStrokeSide !== null && this.lastStrokeSide !== side;
    const repeated = sameDirection && this.lastStrokeSide === side;
    this.sameSideStreak = repeated ? this.sameSideStreak + 1 : 1;
    this.strokeIndex += 1;
    const directionSign = direction === "reverse" ? -1 : 1;
    const sideSign = side === "left" ? 1 : -1;
    const strokeSpeed = direction === "reverse" ? KAYAK_REVERSE_STROKE_SPEED : KAYAK_STROKE_SPEED;
    const sameSideSpeed = direction === "reverse" ? KAYAK_REVERSE_SAME_SIDE_SPEED : KAYAK_SAME_SIDE_SPEED;
    const addStrokeImpulse = (amount: number) => {
      this.kayakSpeed = Phaser.Math.Clamp(
        this.kayakSpeed + directionSign * amount,
        -KAYAK_MAX_REVERSE_SPEED,
        KAYAK_MAX_SPEED
      );
    };
    const turnAmount = KAYAK_TURN_PER_STROKE + Math.min(0.13, this.sameSideStreak * 0.025);
    this.kayakHeading += sideSign * directionSign * turnAmount * (alternating ? 2 : 1);

    if (alternating) {
      addStrokeImpulse(strokeSpeed);
      this.kayakRoll *= 0.36;
      this.sameSideStreak = 1;
    } else {
      addStrokeImpulse(sameSideSpeed);
      this.kayakRoll += sideSign * (0.23 + Math.min(0.18, this.sameSideStreak * 0.035));
    }

    this.lastStrokeAt = now;
    this.lastStrokeSide = side;
    this.lastStrokeDirection = direction;
    this.kayak.stroke(side, direction, repeated ? 1.2 : 1);
    if (emitIntent) {
      this.emitDomain("rpg_qizhen_paddle_requested", {
        side,
        direction,
        zone: this.currentZone,
        strokeIndex: this.strokeIndex,
        alternating,
        sameSideStreak: this.sameSideStreak,
        speed: Math.round(this.kayakSpeed),
        tilt: Number(this.kayakRoll.toFixed(3))
      });
    }

    const tutorialAllowance = runtime.boardingTutorialCompleted
      ? 0
      : Math.max(0, 0.3 - runtime.boardingStrokeCount * 0.045);
    if (
      this.sameSideStreak >= 4
      || Math.abs(this.kayakRoll) >= KAYAK_CAPSIZE_THRESHOLD + tutorialAllowance
    ) {
      this.triggerCapsize("same_side_strokes", runtime);
    }
  }

  private updateKayakMotion(deltaSeconds: number, runtime: QizhenRuntimeProjection): void {
    if (this.capsizing || this.zoneTransitioning) {
      this.player.setVelocity(0, 0);
      return;
    }
    if (this.photoSessionOpen) {
      // 相机打开期间:冻结位置与碰撞推进,瞬时速度与侧倾缓慢归零,
      // 关闭相机返回时船体不会突跳。
      this.kayakSpeed *= Math.exp(-PHOTO_SESSION_SPEED_DAMPING_PER_SECOND * deltaSeconds);
      if (Math.abs(this.kayakSpeed) < 1) this.kayakSpeed = 0;
      this.kayakRoll *= Math.exp(-KAYAK_ROLL_DECAY_PER_SECOND * deltaSeconds);
      this.player.setVelocity(0, 0).setDepth(this.player.y + 120);
      this.kayak.setPose({
        x: this.player.x,
        y: this.player.y,
        heading: this.kayakHeading,
        roll: this.kayakRoll,
        speed: 0,
        chasing: false
      });
      return;
    }
    this.kayakSpeed *= Math.exp(-KAYAK_DRAG_PER_SECOND * deltaSeconds);
    if (Math.abs(this.kayakSpeed) < 0.4) this.kayakSpeed = 0;
    this.kayakRoll *= Math.exp(-KAYAK_ROLL_DECAY_PER_SECOND * deltaSeconds);
    const velocityX = Math.cos(this.kayakHeading) * this.kayakSpeed;
    const velocityY = Math.sin(this.kayakHeading) * this.kayakSpeed;
    const wasBoundaryBlocked = this.kayakBoundaryBlocked;
    let boundaryBlockedNow = false;
    this.syncKayakCollisionBody();
    this.player.setVelocity(velocityX, velocityY).setDepth(this.player.y + 120);

    const water = clampKayakToWater(this.currentZone, this.player.x, this.player.y);
    if (!water.contained) {
      this.player.setPosition(water.x, water.y);
      boundaryBlockedNow = true;
    }

    const body = this.player.body as Phaser.Physics.Arcade.Body;
    const movingIntoBlockedEdge = (
      (body.blocked.left && velocityX < 0)
      || (body.blocked.right && velocityX > 0)
      || (body.blocked.up && velocityY < 0)
      || (body.blocked.down && velocityY > 0)
    );
    if (movingIntoBlockedEdge) {
      boundaryBlockedNow = true;
    }
    if (boundaryBlockedNow) {
      this.stopKayakAtBoundary(!wasBoundaryBlocked);
    } else {
      this.kayakBoundaryBlocked = false;
    }

    this.kayak.setPose({
      x: this.player.x,
      y: this.player.y,
      heading: this.kayakHeading,
      roll: this.kayakRoll,
      speed: this.kayakSpeed,
      chasing: runtime.phase === "swan_chase"
    });
    if (runtime.phase === "swan_chase" && this.currentZone === "channel") {
      this.updateSwanChase(deltaSeconds, runtime);
    }
  }

  private stopKayakAtBoundary(newEncounter: boolean): void {
    this.kayakBoundaryBlocked = true;
    this.kayakSpeed = 0;
    this.player.setVelocity(0, 0);
    if (newEncounter) {
      this.boundaryBlockCount += 1;
      this.boundaryHeadingAtBlock = this.kayakHeading;
      this.boundaryRollAtBlock = this.kayakRoll;
    }
    if (this.time.now - this.boundaryBlockedHintAt >= BOUNDARY_BLOCKED_HINT_COOLDOWN_MS) {
      this.boundaryBlockedHintAt = this.time.now;
      this.showFeedback(qizhenContent.boarding.boundaryBlocked, "system", 2200);
    }
  }

  private updateSwanChase(deltaSeconds: number, runtime: QizhenRuntimeProjection): void {
    if (!this.chaseSwan) this.createChaseSwan();
    const chaseDeltaSeconds = Math.min(deltaSeconds, 0.05);
    this.chaseElapsedSeconds += chaseDeltaSeconds;
    const playerDx = this.player.x - this.chaseSwanX;
    const playerDy = this.player.y - this.chaseSwanY;
    const distanceBeforeMove = Math.hypot(playerDx, playerDy);
    const distanceFactor = Phaser.Math.Clamp(
      (distanceBeforeMove - SWAN_CHASE_NEAR_DISTANCE)
        / (SWAN_CHASE_FAR_DISTANCE - SWAN_CHASE_NEAR_DISTANCE),
      0,
      1
    );
    const easedDistanceFactor = distanceFactor * distanceFactor * (3 - 2 * distanceFactor);
    const targetSpeed = Phaser.Math.Linear(
      SWAN_CHASE_NEAR_SPEED,
      SWAN_CHASE_FAR_SPEED,
      easedDistanceFactor
    );
    const graceRamp = Phaser.Math.Clamp(this.chaseElapsedSeconds / SWAN_CHASE_GRACE_SECONDS, 0, 1);
    const easedGrace = graceRamp * graceRamp * (3 - 2 * graceRamp);
    const graceLimitedSpeed = Phaser.Math.Linear(76, targetSpeed, easedGrace);
    const speedBlend = 1 - Math.exp(-4.8 * chaseDeltaSeconds);
    this.chaseSwanSpeed = Phaser.Math.Linear(this.chaseSwanSpeed, graceLimitedSpeed, speedBlend);

    const pursuitY = this.player.y
      + Math.sin(this.chaseElapsedSeconds * 4.2) * SWAN_CHASE_SWAY * easedDistanceFactor;
    const dx = this.player.x - this.chaseSwanX;
    const dy = pursuitY - this.chaseSwanY;
    const distanceToPursuit = Math.hypot(dx, dy);
    if (distanceToPursuit > 0.001) {
      const step = Math.min(distanceToPursuit, this.chaseSwanSpeed * chaseDeltaSeconds);
      this.chaseSwanX += dx / distanceToPursuit * step;
      this.chaseSwanY += dy / distanceToPursuit * step;
    }
    this.chaseActualGap = Math.hypot(
      this.chaseSwanX - this.player.x,
      this.chaseSwanY - this.player.y
    );
    if (this.chaseElapsedSeconds < SWAN_CHASE_GRACE_SECONDS) {
      const protectedGap = SWAN_CHASE_CATCH_DISTANCE + 18;
      if (this.chaseActualGap < protectedGap) {
        const awayX = this.chaseSwanX - this.player.x;
        const awayY = this.chaseSwanY - this.player.y;
        const awayLength = Math.max(0.001, Math.hypot(awayX, awayY));
        this.chaseSwanX = this.player.x + awayX / awayLength * protectedGap;
        this.chaseSwanY = this.player.y + awayY / awayLength * protectedGap;
        this.chaseActualGap = protectedGap;
      }
    }
    this.chaseIntensity = 1 - Phaser.Math.Clamp(
      (this.chaseActualGap - SWAN_CHASE_CATCH_DISTANCE)
        / (SWAN_CHASE_FAR_DISTANCE - SWAN_CHASE_CATCH_DISTANCE),
      0,
      1
    );
    const heading = Math.atan2(this.player.y - this.chaseSwanY, this.player.x - this.chaseSwanX);
    const beat = this.reducedMotion
      ? 0
      : Math.sin(this.time.now / (105 - this.chaseIntensity * 48)) * (0.42 + this.chaseIntensity * 0.78);
    this.chaseSwan?.update(this.chaseSwanX, this.chaseSwanY, heading, beat, this.chaseIntensity);

    const progress = Math.max(runtime.chaseDistance, this.chaseStartX - this.player.x);
    if (progress >= this.lastChaseProgressSent + 20) {
      this.lastChaseProgressSent = progress;
      this.emitDomain("rpg_qizhen_chase_progress", { distance: Math.round(progress), zone: "channel" });
    }
    if (!this.chaseCompleting && this.player.x <= SWAN_CHASE_FINISH_X) {
      this.chaseCompleting = true;
      this.kayakSpeed = 0;
      this.player.setVelocity(0, 0);
      this.emitDomain("rpg_qizhen_escape_completed_requested", {
        zone: "dock",
        distance: Math.max(runtime.chaseDistance, Math.round(this.chaseStartX - this.player.x)),
        completion: "far_bank_reached"
      });
      return;
    }
    if (
      !this.chaseFailing
      && !this.chaseCompleting
      && this.chaseElapsedSeconds >= SWAN_CHASE_GRACE_SECONDS
      && this.chaseActualGap <= SWAN_CHASE_CATCH_DISTANCE
    ) {
      this.triggerSwanCatch(runtime);
    }
  }

  private triggerSwanCatch(runtime: QizhenRuntimeProjection): void {
    if (this.chaseFailing || this.chaseCompleting || this.capsizing) return;
    this.chaseFailing = true;
    this.capsizing = true;
    this.kayakSpeed = 0;
    this.player.setVelocity(0, 0);
    this.chaseSwanSpeed = 0;
    this.chaseSwanX = this.player.x + Math.cos(this.kayakHeading + Math.PI) * SWAN_CHASE_CATCH_DISTANCE;
    this.chaseSwanY = this.player.y + Math.sin(this.kayakHeading + Math.PI) * SWAN_CHASE_CATCH_DISTANCE;
    this.chaseActualGap = SWAN_CHASE_CATCH_DISTANCE;
    this.chaseSwan?.update(
      this.chaseSwanX,
      this.chaseSwanY,
      Math.atan2(this.player.y - this.chaseSwanY, this.player.x - this.chaseSwanX),
      1,
      1
    );
    if (!this.reducedMotion) {
      this.cameras.main.shake(260, 0.009);
      this.cameras.main.flash(150, 224, 246, 255, false);
    }
    this.showFeedback(`${qizhenContent.chase.caught}${qizhenContent.chase.failed}`, "system", 3000);
    this.emitDomain("rpg_qizhen_chase_failed", {
      reason: "swan_caught",
      zone: this.currentZone,
      distance: Math.max(runtime.chaseDistance, Math.round(this.chaseStartX - this.player.x)),
      attempt: runtime.chaseAttempts + 1,
      restartCheckpoint: "qizhen_chase"
    });
    this.kayak.playCapsize(() => {
      const safe = this.getSpawn("channel", "kayak", null);
      this.player.setPosition(safe.x, safe.y).setVelocity(0, 0);
      this.kayakHeading = "heading" in safe ? safe.heading : Math.PI;
      this.kayakSpeed = 0;
      this.kayakRoll = 0;
      this.sameSideStreak = 0;
      this.lastStrokeSide = null;
      this.lastStrokeDirection = null;
      this.lastStrokeAt = 0;
      this.resetChaseSwan();
      this.capsizing = false;
      this.chaseFailing = false;
    });
  }

  private triggerCapsize(reason: "same_side_strokes", runtime: QizhenRuntimeProjection): void {
    if (this.capsizing) return;
    this.capsizing = true;
    this.kayakSpeed = 0;
    this.player.setVelocity(0, 0);
    this.showFeedback(
      runtime.phase === "swan_chase"
        ? `${qizhenContent.boarding.capsizeSameSide}${qizhenContent.chase.failed}`
        : qizhenContent.boarding.capsizeSameSide,
      "system"
    );
    this.emitDomain("rpg_qizhen_capsized", {
      zone: this.currentZone,
      reason,
      count: runtime.capsizeCount + 1,
      safeSpawnId: runtime.safeSpawnId
    });
    this.kayak.playCapsize(() => {
      const safe = this.getSpawn(this.currentZone, "kayak", null);
      this.player.setPosition(safe.x, safe.y).setVelocity(0, 0);
      this.kayakHeading = "heading" in safe ? safe.heading : -Math.PI / 2;
      this.kayakRoll = 0;
      this.sameSideStreak = 0;
      this.lastStrokeSide = null;
      this.lastStrokeDirection = null;
      this.lastStrokeAt = 0;
      if (this.currentZone === "channel" && runtime.phase === "swan_chase") {
        this.resetChaseSwan();
      }
      this.capsizing = false;
    });
  }

  private syncState(runtime: QizhenRuntimeProjection): void {
    if (runtime.phase !== this.currentPhase) {
      const previous = this.currentPhase;
      this.currentPhase = runtime.phase;
      if (runtime.phase === "swan_chase" && previous !== "swan_chase" && !this.chaseAnnounced) {
        this.chaseAnnounced = true;
        this.emitDomain("rpg_qizhen_chase_started", { zone: runtime.zone });
        this.showFeedback(qizhenContent.swan.gateRelease, "system");
      }
      if (runtime.phase !== "swan_chase") this.chaseAnnounced = false;
    }
    if (runtime.zone !== this.currentZone && !this.zoneTransitioning) {
      this.transitionToZone(runtime.zone, runtime.vehicle);
      return;
    }
    if (runtime.vehicle !== this.currentVehicle && !this.zoneTransitioning) {
      this.currentVehicle = runtime.vehicle;
      this.applyVehicle(runtime.vehicle, true);
      this.rebuildCollision(runtime.vehicle);
    }
    if (runtime.rightPaddleEquipped !== this.currentDockSignRemoved) {
      this.applyDockSignVariant(runtime.rightPaddleEquipped);
    }
    if (runtime.rainSafetyCleared !== this.currentRainSafetyCleared) {
      this.currentRainSafetyCleared = runtime.rainSafetyCleared;
      if (this.currentZone === "dock") this.rebuildZone(this.currentZone, this.currentVehicle, null, false);
    }
    if (runtime.mode !== this.currentMode) this.playModeTransition(runtime.mode);
  }

  private transitionToZone(zone: QizhenLakeZoneId, vehicle: QizhenLakeVehicle): void {
    const previousZone = this.currentZone;
    this.zoneTransitioning = true;
    this.player.setVelocity(0, 0);
    this.kayakSpeed = 0;
    const fadeMs = this.reducedMotion ? 50 : 180;
    this.cameras.main.fadeOut(fadeMs, 3, 12, 20);
    this.time.delayedCall(fadeMs, () => {
      this.currentZone = zone;
      this.currentVehicle = vehicle;
      this.rebuildZone(zone, vehicle, previousZone, true);
      this.applyVehicle(vehicle, false);
      this.cameras.main.fadeIn(fadeMs, 3, 12, 20);
      this.zoneTransitioning = false;
      this.maybePlayReflectionDialogue();
    });
  }

  private maybePlayReflectionDialogue(): void {
    if (this.reflectionDialoguePlayed || this.currentZone !== "open_water") return;
    const runtime = readQizhenRuntime(this.bridge.getState());
    if (runtime.reflectionLocationObserved) return;
    if (!["lake_exploration", "tool_chain", "swan_exchange", "paper_capture"].includes(runtime.phase)) return;
    this.reflectionDialoguePlayed = true;
    this.queueDialogue(qizhenContent.reflection.dialogue);
  }

  private rebuildZone(
    zone: QizhenLakeZoneId,
    vehicle: QizhenLakeVehicle,
    fromZone: QizhenLakeZoneId | null,
    reposition: boolean
  ): void {
    this.mapImage.setTexture(this.getZoneTextureKey(zone));
    this.destroyZoneVisuals();
    this.rebuildCollision(vehicle);
    this.createOcclusionVisuals();
    this.createAmbientVisuals();
    this.createTargetVisuals();
    this.createZoneSwan();
    if (reposition) {
      const spawn = this.getSpawn(zone, vehicle, fromZone);
      this.player.setPosition(spawn.x, spawn.y).setVelocity(0, 0);
      if ("heading" in spawn) this.kayakHeading = spawn.heading;
      this.kayakRoll = 0;
      this.kayakSpeed = 0;
      this.cameras.main.centerOn(spawn.x, spawn.y);
    }
    if (zone === "channel" && this.currentPhase === "swan_chase") {
      this.resetChaseSwan();
    }
  }

  private rebuildCollision(vehicle: QizhenLakeVehicle): void {
    this.obstacles.clear(true, true);
    const collisions = this.getActiveCollisionRects(vehicle);
    const collisionVisible = import.meta.env.DEV
      && new URLSearchParams(window.location.search).get("rpgCollision") === "1";
    collisions.forEach((rect) => {
      const collision = this.add.rectangle(
        (rect.left + rect.right) / 2,
        (rect.top + rect.bottom) / 2,
        rect.right - rect.left,
        rect.bottom - rect.top,
        collisionVisible ? 0xff365b : 0x000000,
        collisionVisible ? 0.25 : 0
      ).setDepth(collisionVisible ? 4950 : rect.bottom - 20);
      if (collisionVisible) collision.setStrokeStyle(2, 0xffd6de, 0.9);
      this.obstacles.add(collision);
    });
  }

  private getActiveCollisionRects(vehicle: QizhenLakeVehicle) {
    const definition = QIZHEN_LAKE_ZONES[this.currentZone];
    return vehicle === "kayak" ? definition.kayakCollisions : definition.onFootCollisions;
  }

  private createOcclusionVisuals(): void {
    const textureKey = this.getZoneTextureKey(this.currentZone);
    QIZHEN_LAKE_ZONES[this.currentZone].occlusions.forEach((definition) => {
      const image = this.add.image(0, 0, textureKey)
        .setOrigin(0)
        .setCrop(
          definition.left,
          definition.top,
          definition.right - definition.left,
          definition.bottom - definition.top
        )
        .setDepth(-900)
        .setVisible(false);
      this.occlusionVisuals.push({
        definition,
        bounds: new Phaser.Geom.Rectangle(
          definition.left,
          definition.top,
          definition.right - definition.left,
          definition.bottom - definition.top
        ),
        image
      });
    });
  }

  private getZoneTextureKey(zone: QizhenLakeZoneId): string {
    return zone === "dock" && this.currentDockSignRemoved
      ? DOCK_NO_SIGN_TEXTURE_KEY
      : ZONE_TEXTURE_KEYS[zone];
  }

  private applyDockSignVariant(removed: boolean): void {
    this.currentDockSignRemoved = removed;
    if (this.currentZone !== "dock") return;
    const textureKey = this.getZoneTextureKey("dock");
    this.mapImage.setTexture(textureKey);
    this.occlusionVisuals.forEach(({ definition, image }) => {
      image
        .setTexture(textureKey)
        .setCrop(
          definition.left,
          definition.top,
          definition.right - definition.left,
          definition.bottom - definition.top
        );
    });
  }

  private createAmbientVisuals(): void {
    const rainingAtDock = this.currentZone === "dock" && !this.currentRainSafetyCleared;
    if (rainingAtDock) this.createDockRainVisuals();
    if (this.currentZone === "dock" && this.currentRainSafetyCleared) {
      QIZHEN_DOCK_AFTER_RAIN_PUDDLES.forEach((puddle, index) => {
        const surface = this.add.ellipse(
          puddle.x,
          puddle.y,
          puddle.width,
          puddle.height,
          0x39758c,
          0.32
        ).setStrokeStyle(2, 0x9fd6df, 0.42).setDepth(-820);
        const reflection = this.add.ellipse(
          puddle.x - puddle.width * 0.14,
          puddle.y - puddle.height * 0.12,
          puddle.width * 0.34,
          Math.max(3, puddle.height * 0.16),
          0xe1f7f8,
          0.38
        ).setDepth(-819);
        this.ambientVisuals.push(surface, reflection);
        if (!this.reducedMotion) {
          this.tweens.add({
            targets: reflection,
            alpha: { from: 0.18, to: 0.48 },
            duration: 1250 + index * 170,
            yoyo: true,
            repeat: -1,
            ease: "Sine.easeInOut"
          });
        }
      });
    }
    const bands: ReadonlyArray<readonly [number, number, number]> = this.currentZone === "channel"
      ? [[330, 340, 110], [930, 600, 150], [1320, 390, 94]]
      : this.currentZone === "swan_cove"
        ? [[380, 360, 120], [735, 610, 156], [1180, 650, 96]]
        : this.currentZone === "dock"
          ? [[930, 290, 145], [1220, 540, 118], [1480, 340, 84]]
          : [[560, 500, 130], [915, 350, 180], [1320, 620, 112]];
    if (rainingAtDock) return;
    bands.forEach(([x, y, width], index) => {
      const glint = this.add.ellipse(x, y, width, 12, 0xd7fbff, 0)
        .setStrokeStyle(2, 0xd7fbff, 0.32)
        .setDepth(1120);
      this.ambientVisuals.push(glint);
      if (!this.reducedMotion) {
        this.tweens.add({
          targets: glint,
          scaleX: 1.35,
          alpha: { from: 0.1, to: 0.48 },
          duration: 1700 + index * 260,
          ease: "Sine.easeInOut",
          yoyo: true,
          repeat: -1,
          delay: index * 360
        });
      } else {
        glint.setAlpha(0.28);
      }
    });
  }

  private createDockRainVisuals(): void {
    const rainTint = this.add.rectangle(
      QIZHEN_LAKE_WORLD.width / 2,
      QIZHEN_LAKE_WORLD.height / 2,
      QIZHEN_LAKE_WORLD.width,
      QIZHEN_LAKE_WORLD.height,
      0x31566f,
      0.23
    ).setDepth(-850);
    this.ambientVisuals.push(rainTint);

    QIZHEN_DOCK_AFTER_RAIN_PUDDLES.forEach((puddle, index) => {
      const wetSurface = this.add.ellipse(
        puddle.x,
        puddle.y,
        puddle.width * 1.34,
        puddle.height * 1.3,
        0x285b70,
        0.14
      ).setStrokeStyle(1, 0xb6dce5, 0.1).setDepth(-820);
      const wetLobe = this.add.ellipse(
        puddle.x + puddle.width * 0.16,
        puddle.y + puddle.height * 0.05,
        puddle.width * 0.92,
        puddle.height * 1.04,
        0x285b70,
        0.09
      ).setDepth(-820);
      const sheen = this.add.ellipse(
        puddle.x - puddle.width * 0.12,
        puddle.y - puddle.height * 0.14,
        puddle.width * 0.42,
        Math.max(3, puddle.height * 0.14),
        0xd7edf1,
        0.14
      ).setDepth(-819);
      this.ambientVisuals.push(wetSurface, wetLobe, sheen);
      if (!this.reducedMotion) {
        this.tweens.add({
          targets: sheen,
          alpha: { from: 0.05, to: 0.18 },
          duration: 780 + index * 120,
          yoyo: true,
          repeat: -1,
          ease: "Sine.easeInOut"
        });
      }
    });

    const createStreakLayer = (
      count: number,
      seedX: number,
      seedY: number,
      stepX: number,
      stepY: number,
      length: number,
      drift: number,
      fall: number,
      duration: number,
      color: number,
      alpha: number,
      depth: number,
      lineWidth: number
    ) => {
      for (let index = 0; index < count; index += 1) {
        const x = (index * stepX + seedX) % QIZHEN_LAKE_WORLD.width;
        const y = (index * stepY + seedY) % QIZHEN_LAKE_WORLD.height;
        const variableLength = length + (index % 4) * 4;
        const streak = this.add.line(x, y, 0, 0, -variableLength * 0.28, variableLength, color, alpha)
          .setOrigin(0.5)
          .setLineWidth(lineWidth, Math.max(1, lineWidth - 1))
          .setDepth(depth);
        this.ambientVisuals.push(streak);
        if (!this.reducedMotion) {
          this.tweens.add({
            targets: streak,
            x: x - drift,
            y: y + fall,
            duration: duration + (index % 5) * 26,
            delay: (index * 29) % duration,
            repeatDelay: (index * 17) % 140,
            repeat: -1,
            ease: "Linear"
          });
        }
      }
    };

    createStreakLayer(
      QIZHEN_DOCK_RAIN_EFFECT_PROFILE.farStreakCount,
      41,
      17,
      137,
      79,
      24,
      34,
      178,
      760,
      0x8dbdd1,
      0.34,
      4320,
      1
    );
    createStreakLayer(
      QIZHEN_DOCK_RAIN_EFFECT_PROFILE.nearStreakCount,
      97,
      53,
      223,
      131,
      46,
      52,
      238,
      570,
      0xd4f0fb,
      0.64,
      4460,
      2
    );

    const mistBands: ReadonlyArray<readonly [number, number, number, number, number]> = [
      [500, 190, 760, 118, 0.075],
      [1030, 380, 900, 142, 0.065],
      [1290, 720, 680, 110, 0.055]
    ];
    mistBands.forEach(([x, y, width, height, alpha], index) => {
      const mist = this.add.ellipse(x, y, width, height, 0xc5dbe1, alpha).setDepth(1180);
      this.ambientVisuals.push(mist);
      if (!this.reducedMotion) {
        this.tweens.add({
          targets: mist,
          x: x + (index % 2 === 0 ? 74 : -64),
          alpha: { from: alpha * 0.55, to: alpha },
          duration: 4100 + index * 620,
          yoyo: true,
          repeat: -1,
          ease: "Sine.easeInOut"
        });
      }
    });

    QIZHEN_DOCK_RAIN_SPLASH_SITES.forEach((site, index) => {
      const ring = this.add.ellipse(
        site.x,
        site.y,
        site.width * 1.25,
        Math.max(6, site.width * 0.34),
        0x000000,
        0
      ).setStrokeStyle(2, 0xd8f5ff, 0.66).setDepth(1210).setScale(0.32);
      const impact = this.add.ellipse(
        site.x - 2,
        site.y,
        5,
        2,
        0xe8f9ff,
        0.62
      ).setDepth(1211);
      this.ambientVisuals.push(ring, impact);
      if (!this.reducedMotion) {
        const cycle = 980 + (index % 4) * 130;
        this.tweens.add({
          targets: ring,
          scaleX: 1.35,
          scaleY: 1.35,
          alpha: { from: 0.62, to: 0 },
          duration: 620,
          delay: (index * 157) % 920,
          repeatDelay: Math.max(180, cycle - 620),
          repeat: -1,
          ease: "Quad.easeOut"
        });
        this.tweens.add({
          targets: impact,
          alpha: { from: 0.72, to: 0 },
          y: site.y - 3,
          duration: 240,
          delay: (index * 157) % 920,
          repeatDelay: Math.max(560, cycle - 240),
          repeat: -1,
          ease: "Quad.easeOut"
        });
      }
    });
  }

  private createTargetVisuals(): void {
    QIZHEN_LAKE_TARGETS.filter((target) => target.zone === this.currentZone).forEach((target) => {
      const isOutfit = target.kind === "outfit";
      const isWaterRipple = isQizhenWaterRippleTarget(target);
      const color = target.kind === "zone_portal" || target.kind === "escape"
        ? 0xffe36d
        : target.kind === "reflection"
          ? 0x7de8ff
          : isWaterRipple
            ? 0xffdf6b
            : target.kind === "swan"
              ? 0xffd1a4
              : 0xb8ffd7;
      const pulse = target.kind === "zone_portal" || target.kind === "escape"
        ? this.add.triangle(0, 0, -22, -18, 24, 0, -22, 18, color, 0.25).setStrokeStyle(3, color, 0.88)
        : isOutfit
          ? this.add.ellipse(0, 0, 64, 30, color, 0.1).setStrokeStyle(3, color, 0.9)
          : isWaterRipple
            ? this.add.ellipse(
                0,
                0,
                target.width ?? 156,
                target.height ?? 72,
                0x07111c,
                0.28
              ).setStrokeStyle(4, color, 1)
            : this.add.ellipse(0, 0, 72, 34, color, 0.08).setStrokeStyle(3, color, 0.82);
      pulse.setVisible(false);
      const label = this.add.text(0, -34, target.label, {
        color: "#f4ffff",
        backgroundColor: "#09212dda",
        fontFamily: "monospace",
        fontSize: "11px",
        padding: { x: 6, y: 3 }
      }).setOrigin(0.5, 1).setVisible(false);
      const sparkles: Phaser.GameObjects.Arc[] = [];
      if (target.kind === "reflection") {
        const sparkleOffsets: ReadonlyArray<readonly [number, number, number]> = [[-16, -10, 2], [14, -13, 1.5], [20, 6, 1.5]];
        sparkleOffsets.forEach(([offsetX, offsetY, radius], sparkleIndex) => {
          const sparkle = this.add.circle(offsetX, offsetY, radius, sparkleIndex === 1 ? 0xbbefff : 0x7ce7ff, 0.95);
          sparkle.setVisible(false);
          sparkles.push(sparkle);
          if (!this.reducedMotion) {
            this.tweens.add({
              targets: sparkle,
              y: offsetY - 4 - sparkleIndex,
              alpha: { from: 0.22, to: 1 },
              duration: 430 + sparkleIndex * 90,
              yoyo: true,
              repeat: -1,
              ease: "Stepped"
            });
          }
        });
      }
      const rippleBands: Phaser.GameObjects.Ellipse[] = [];
      let rippleCenter: Phaser.GameObjects.Arc | null = null;
      if (isWaterRipple) {
        const rippleWidth = target.width ?? 156;
        const rippleHeight = target.height ?? 72;
        [0.66, 1.28].forEach((scale, bandIndex) => {
          const band = this.add.ellipse(
            0,
            0,
            rippleWidth * scale,
            rippleHeight * scale,
            0x000000,
            0
          ).setStrokeStyle(
            bandIndex === 0 ? 3 : 2,
            bandIndex === 0 ? 0xf8ffff : color,
            bandIndex === 0 ? 0.96 : 0.7
          ).setVisible(false);
          rippleBands.push(band);
          if (!this.reducedMotion) {
            band.setScale(bandIndex === 0 ? 0.94 : 0.9);
            this.tweens.add({
              targets: band,
              scaleX: bandIndex === 0 ? 1.06 : 1.1,
              scaleY: bandIndex === 0 ? 1.06 : 1.1,
              duration: 760 + bandIndex * 230,
              delay: bandIndex * 170,
              yoyo: true,
              repeat: -1,
              ease: "Sine.easeInOut"
            });
          }
        });
        rippleCenter = this.add.circle(0, 0, 5, 0xf8ffff, 1)
          .setStrokeStyle(2, 0x07111c, 0.95)
          .setVisible(false);
      }
      const prop = this.createDockOutfitProp(target);
      const rootChildren: Phaser.GameObjects.GameObject[] = prop
        ? [prop, ...rippleBands, pulse, ...(rippleCenter ? [rippleCenter] : []), label, ...sparkles]
        : [...rippleBands, pulse, ...(rippleCenter ? [rippleCenter] : []), label, ...sparkles];
      const root = this.add.container(target.x, target.y, rootChildren)
        .setDepth(target.y + 48)
        .setSize(Math.max(88, target.dropWidth ?? 88), Math.max(64, target.dropHeight ?? 64))
        .setInteractive({ useHandCursor: true })
        .setVisible(false)
        .setName("qizhenTarget");
      root.setData("targetId", target.id);
      root.on("pointerdown", () => this.triggerPointerTarget(target));
      this.targetVisuals.push({
        target,
        root,
        label,
        pulse,
        color,
        sparkles,
        rippleBands,
        rippleCenter
      });
    });
    this.createDropGuides();
  }

  private createDropGuides(): void {
    QIZHEN_LAKE_TARGETS
      .filter((target) => (
        target.zone === this.currentZone
        && (target.acceptedItem !== undefined || target.acceptedItems !== undefined)
      ))
      .forEach((target) => {
        const bounds = getRpgDropBounds(target);
        const targetOutline = this.add.rectangle(
          target.x,
          target.y,
          bounds.width,
          bounds.height,
          0x000000,
          0
        ).setStrokeStyle(2, 0x72dcff, 0.9)
          .setDepth(4960)
          .setVisible(false);
        this.dropGuides.push({ target, targetOutline });
      });
  }

  private createDockOutfitProp(target: QizhenLakeInteractionTarget): Phaser.GameObjects.GameObject | null {
    if (target.kind === "safety_officer") {
      return this.add.sprite(0, 46, SAFETY_OFFICER_TEXTURE_KEY, 0)
        .setOrigin(0.5, 1)
        .setScale(0.52)
        .play(SAFETY_OFFICER_ANIMATION_KEY);
    }
    if (target.kind !== "outfit") return null;
    const graphics = this.add.graphics();
    if (target.value === "left_paddle") {
      graphics.lineStyle(5, 0x67472c, 0.96);
      graphics.beginPath();
      graphics.moveTo(-34, 11);
      graphics.lineTo(31, -10);
      graphics.strokePath();
      graphics.lineStyle(2, 0xa57947, 0.88);
      graphics.beginPath();
      graphics.moveTo(-8, 3);
      graphics.lineTo(-17, -7);
      graphics.moveTo(12, -4);
      graphics.lineTo(20, -15);
      graphics.strokePath();
      return graphics;
    }
    if (target.value === "right_paddle") {
      graphics.destroy();
      return null;
    }
    return null;
  }

  private createZoneSwan(): void {
    this.staticSwan?.destroy();
    this.staticSwan = null;
    if (this.currentZone !== "swan_cove" || this.currentPhase === "swan_chase") return;
    this.staticSwan = createQizhenBlackSwanVisual(this);
    this.staticSwan.update(1160, 400, 2.8, 0.08);
  }

  private createChaseSwan(): void {
    this.chaseSwan?.destroy();
    this.chaseSwan = createQizhenBlackSwanVisual(this);
    this.resetChaseSwan();
  }

  private resetChaseSwan(): void {
    this.chaseStartX = this.player.x;
    this.chaseElapsedSeconds = 0;
    this.chaseActualGap = SWAN_CHASE_INITIAL_GAP;
    this.chaseSwanSpeed = 0;
    this.chaseIntensity = 0;
    this.lastChaseProgressSent = 0;
    this.chaseCompleting = false;
    this.chaseFailing = false;
    this.chaseSwanX = Math.min(QIZHEN_LAKE_WORLD.width - 70, this.player.x + SWAN_CHASE_INITIAL_GAP);
    this.chaseSwanY = this.player.y;
    this.chaseSwan?.update(this.chaseSwanX, this.chaseSwanY, Math.PI, 0);
  }

  private destroyZoneVisuals(): void {
    this.targetVisuals.forEach(({ root, pulse, sparkles, rippleBands, rippleCenter }) => {
      this.tweens.killTweensOf(root);
      this.tweens.killTweensOf(pulse);
      sparkles.forEach((sparkle) => this.tweens.killTweensOf(sparkle));
      rippleBands.forEach((band) => this.tweens.killTweensOf(band));
      if (rippleCenter) this.tweens.killTweensOf(rippleCenter);
      root.destroy(true);
    });
    this.targetVisuals = [];
    this.dropGuides.forEach((guide) => {
      guide.targetOutline.destroy();
    });
    this.dropGuides = [];
    this.ambientVisuals.forEach((visual) => {
      this.tweens.killTweensOf(visual);
      visual.destroy();
    });
    this.ambientVisuals = [];
    this.occlusionVisuals.forEach(({ image }) => image.destroy());
    this.occlusionVisuals = [];
    this.staticSwan?.destroy();
    this.staticSwan = null;
    this.chaseSwan?.destroy();
    this.chaseSwan = null;
  }

  private applyVehicle(vehicle: QizhenLakeVehicle, reposition: boolean): void {
    this.currentVehicle = vehicle;
    const body = this.player.body as Phaser.Physics.Arcade.Body;
    if (vehicle === "kayak") {
      this.player.setVisible(false).setAlpha(0).setScale(1).setOrigin(0.5, 0.5);
      this.syncKayakCollisionBody();
      this.kayak.setVisible(true);
      if (reposition) {
        const spawn = this.getSpawn(this.currentZone, vehicle, null);
        this.player.setPosition(spawn.x, spawn.y).setVelocity(0, 0);
        if ("heading" in spawn) this.kayakHeading = spawn.heading;
      }
      this.kayak.setPose({
        x: this.player.x,
        y: this.player.y,
        heading: this.kayakHeading,
        roll: 0,
        speed: 0
      });
    } else {
      this.kayak.setVisible(false);
      this.player.setVisible(true).setAlpha(1);
      configureRpgPlayerSprite(this.player);
      this.playerAnimator.setFacing("up");
      if (reposition) {
        const spawn = QIZHEN_LAKE_ZONES[this.currentZone].onFootSpawn;
        this.player.setPosition(spawn.x, spawn.y).setVelocity(0, 0);
      }
    }
  }

  private syncKayakCollisionBody(): void {
    const body = this.player.body as Phaser.Physics.Arcade.Body;
    const absCos = Math.abs(Math.cos(this.kayakHeading));
    const absSin = Math.abs(Math.sin(this.kayakHeading));
    const width = KAYAK_COLLISION_LENGTH * absCos + KAYAK_COLLISION_WIDTH * absSin;
    const height = KAYAK_COLLISION_LENGTH * absSin + KAYAK_COLLISION_WIDTH * absCos;
    body.setSize(width, height, true);
  }

  private getActiveTargets(state: GameState, runtime: QizhenRuntimeProjection): QizhenLakeInteractionTarget[] {
    const zoneTargets = targetsForQizhenZone(this.currentZone, this.currentVehicle).map((target) => {
      if (target.id !== "qizhen_swan_workbench" || this.currentVehicle !== "kayak") return target;
      const bowOffset = 52;
      return {
        ...target,
        x: this.player.x + Math.cos(this.kayakHeading) * bowOffset,
        y: this.player.y + Math.sin(this.kayakHeading) * bowOffset,
        stand: { x: this.player.x, y: this.player.y }
      };
    });
    return zoneTargets.filter((target) => {
      if (target.kind === "exit") return runtime.phase !== "swan_chase";
      if (target.kind === "outfit") {
        if (target.value === "kayak") return !runtime.kayakEquipped;
        if (target.value === "left_paddle") return !runtime.leftPaddleEquipped;
        if (target.value === "right_paddle") return !runtime.rightPaddleEquipped;
        return false;
      }
      if (target.kind === "board") {
        return runtime.kayakEquipped
          && runtime.leftPaddleEquipped
          && runtime.rightPaddleEquipped
          && this.currentVehicle === "on_foot";
      }
      if (target.kind === "zone_portal") {
        if (target.id === "qizhen_dock_to_open") return runtime.boardingTutorialCompleted;
        if (target.id === "qizhen_open_to_dock") return runtime.phase !== "swan_chase";
        if (target.id === "qizhen_open_to_swan") return runtime.phase !== "swan_chase";
        if (target.id === "qizhen_open_to_channel") return runtime.phase !== "swan_chase";
        if (target.id === "qizhen_swan_to_open") return runtime.phase !== "swan_chase" && !runtime.paperCaptured;
        if (target.id === "qizhen_swan_to_channel") return runtime.phase === "swan_chase" || runtime.swanReleased;
        if (target.id === "qizhen_channel_from_swan") return false;
        if (target.id === "qizhen_channel_to_open") return runtime.phase !== "swan_chase";
        return true;
      }
      if (target.kind === "reflection") {
        return ["lake_exploration", "tool_chain", "swan_exchange", "paper_capture"].includes(runtime.phase)
          && runtime.mode === "dark"
          && !runtime.observedFishingSpotIds.includes(String(target.value));
      }
      if (target.kind === "fishing_spot") {
        if (runtime.mode !== "light") return false;
        if (target.value === "fishing_rod") {
          return !runtime.rodFound;
        }
        if (target.value === "item_1") {
          return runtime.rodFound
            && runtime.decoyBaitAttached
            && !hasItem(state, CHAIN_ITEMS.key)
            && !runtime.lockerOpened;
        }
        if (target.value === "item_3") {
          return runtime.decoyBaitAttached
            && !hasItem(state, CHAIN_ITEMS.netFrame)
            && !runtime.netCombined;
        }
        if (target.value === "fish") {
          return runtime.rodFound
            && hasItem(state, CHAIN_ITEMS.pellets)
            && !hasItem(state, CHAIN_ITEMS.fish)
            && !runtime.fishCaught;
        }
        return false;
      }
      if (target.kind === "item_use") {
        if (runtime.mode !== "light") return false;
        if (target.value === "item_1_to_2") return hasItem(state, CHAIN_ITEMS.key) && !runtime.lockerOpened;
        if (target.value === "combine_final_rig") {
          return hasItem(state, CHAIN_ITEMS.cord)
            && hasItem(state, CHAIN_ITEMS.netFrame)
            && hasItem(state, CHAIN_ITEMS.magnet)
            && hasItem(state, CHAIN_ITEMS.fishingRod)
            && !runtime.magneticRodCombined;
        }
        return false;
      }
      if (target.kind === "swan") {
        return runtime.mode === "light" && runtime.phase === "tool_chain" && !runtime.swanFed;
      }
      if (target.kind === "paper") {
        if (runtime.mode !== "light") return false;
        if (target.value === "paper_reflection") {
          return runtime.rodFound
            && !runtime.paperCaptured;
        }
        return runtime.magneticRodCombined
          && !runtime.paperCaptured;
      }
      if (target.kind === "escape") return runtime.phase === "swan_chase";
      return true;
    });
  }

  private requestFishingAttempt(target: QizhenLakeInteractionTarget, itemId: ItemId): void {
    const spotId = QIZHEN_FISHING_SPOT_BY_TARGET[target.id];
    if (!spotId || this.fishingPendingAttempt || this.fishingActiveAttempt) return;

    const attempt: QizhenFishingAttempt = {
      sessionId: `qizhen-${spotId}-${++this.fishingSessionSerial}-${Math.round(performance.now())}`,
      spotId,
      target,
      itemId,
      targetLabel: QIZHEN_FISHING_SPOT_LABELS[spotId]
    };
    this.prepareFishingAudioClock();
    this.fishingPendingAttempt = attempt;
    this.lockFishingPresentation();
    this.fishingPrecheckTimer?.remove();
    this.fishingPrecheckTimer = this.time.delayedCall(FISHING_PRECHECK_TIMEOUT_MS, () => {
      if (this.fishingPendingAttempt?.sessionId !== attempt.sessionId) return;
      this.showFeedback("节奏钓取未能启动，道具已保留，请重试。", "system");
      this.cancelFishingSession("precheck_timeout");
    });
    this.emitDomain("rpg_qizhen_fishing_attempt_requested", {
      sessionId: attempt.sessionId,
      spotId,
      chartId: spotId,
      targetId: target.id,
      targetLabel: attempt.targetLabel,
      itemId
    });
  }

  private prepareFishingAudioClock(): void {
    if (!this.fishingAudioContext) {
      const AudioContextConstructor = getAudioContextConstructor();
      if (AudioContextConstructor) {
        try {
          this.fishingAudioContext = new AudioContextConstructor();
        } catch {
          this.fishingAudioContext = null;
        }
      }
    }
    if (this.fishingAudioContext?.state === "suspended") {
      void this.fishingAudioContext.resume().catch(() => undefined);
    }
  }

  private beginFishingSession(attempt: QizhenFishingAttempt): void {
    if (!this.sys?.isActive() || this.fishingPendingAttempt?.sessionId !== attempt.sessionId) return;
    const audioContext = this.fishingAudioContext;
    this.fishingUsesAudioClock = audioContext?.state === "running";
    this.fishingClockNow = this.fishingUsesAudioClock && audioContext
      ? () => audioContext.currentTime
      : () => performance.now() / 1000;
    this.fishingActiveAttempt = attempt;
    this.fishingPendingAttempt = null;
    this.fishingResolving = false;
    this.fishingHeldActions.clear();

    const assist = this.fishingFailureCounts[attempt.spotId] >= 2;
    const model = new QizhenFishingRhythmModel({
      chartId: attempt.spotId,
      now: () => this.fishingClockNow(),
      assist,
      events: {
        onNoteJudged: (note, judgment, errorMs, tension) => {
          this.fishingVisual?.notifyJudgment(note, judgment, errorMs);
          this.emitDomain("qizhen_fishing_note_judged", {
            sessionId: attempt.sessionId,
            spotId: attempt.spotId,
            action: note.action,
            judgment,
            errorMs: Math.round(errorMs),
            tension: Math.round(tension)
          });
        },
        onHoldBroken: (note, tension) => {
          this.fishingVisual?.notifyHoldBroken(note);
          this.emitDomain("qizhen_fishing_hold_broken", {
            sessionId: attempt.sessionId,
            spotId: attempt.spotId,
            action: note.action,
            tension: Math.round(tension)
          });
        },
        onWarning: (kind, tension) => {
          this.fishingVisual?.notifyWarning(kind, tension);
          this.emitDomain("qizhen_fishing_warning", {
            sessionId: attempt.sessionId,
            spotId: attempt.spotId,
            kind,
            tension: Math.round(tension)
          });
        },
        onCompleted: (result) => this.resolveFishingModelResult(attempt, result),
        onFailed: (reason) => this.resolveFishingModelFailure(attempt, reason)
      }
    });
    this.fishingModel = model;
    this.fishingVisual = new QizhenFishingRhythmVisual({
      scene: this,
      model,
      anchor: { x: attempt.target.x, y: attempt.target.y },
      targetLabel: attempt.targetLabel,
      lineFrom: () => ({
        x: this.player.x + Math.cos(this.kayakHeading) * 44,
        y: this.player.y + Math.sin(this.kayakHeading) * 44
      }),
      reducedMotion: this.reducedMotion
    });
    this.cameras.main.stopFollow();
    this.cameras.main.centerOn(attempt.target.x, attempt.target.y);
    this.fishingNextMetronomeBeat = 0;
    model.start();
    this.fishingStartedAtSec = this.fishingClockNow() - model.elapsedSec;
    this.emitDomain("qizhen_fishing_started", {
      sessionId: attempt.sessionId,
      spotId: attempt.spotId,
      chartId: attempt.spotId,
      targetLabel: attempt.targetLabel,
      totalNotes: model.totalNotes,
      durationSec: model.durationSec,
      experience: model.experience,
      assist
    });
    if (attempt.spotId === "paper") {
      this.emitDomain("qizhen_fishing_final_tension_started", {
        sessionId: attempt.sessionId,
        spotId: attempt.spotId,
        durationSec: model.durationSec
      });
    }
  }

  private updateFishingSession(runtime: QizhenRuntimeProjection): void {
    const attempt = this.fishingActiveAttempt ?? this.fishingPendingAttempt;
    if (!attempt) return;
    if (
      runtime.mode !== "light"
      || runtime.vehicle !== "kayak"
      || runtime.zone !== attempt.target.zone
      || !["tool_chain", "swan_exchange", "paper_capture"].includes(runtime.phase)
    ) {
      this.cancelFishingSession("runtime_changed");
      return;
    }

    this.lockFishingPresentation();
    this.player.setVelocity(0, 0);
    this.kayakSpeed = 0;
    this.kayakRoll = 0;
    this.kayak.setPose({
      x: this.player.x,
      y: this.player.y,
      heading: this.kayakHeading,
      roll: 0,
      speed: 0,
      chasing: false
    });

    const model = this.fishingModel;
    if (model) {
      this.updateFishingKeyboardInput(model);
      model.update();
      this.scheduleFishingMetronome();
      this.fishingVisual?.update();
    }
    this.updateOcclusion();
    this.publishDebugState(null, [], runtime);
  }

  private updateFishingKeyboardInput(model: QizhenFishingRhythmModel): void {
    const leftPressed = Phaser.Input.Keyboard.JustDown(this.keys.A);
    const rightPressed = Phaser.Input.Keyboard.JustDown(this.keys.D);
    if (leftPressed) this.applyFishingInput(model, "left", "press");
    if (rightPressed) this.applyFishingInput(model, "right", "press");
    if (Phaser.Input.Keyboard.JustDown(this.keys.S)) this.applyFishingInput(model, "hook", "press");

    const leftReleased = Phaser.Input.Keyboard.JustUp(this.keys.A) && !this.keys.A.isDown;
    const rightReleased = Phaser.Input.Keyboard.JustUp(this.keys.D) && !this.keys.D.isDown;
    if (leftReleased) this.applyFishingInput(model, "left", "release");
    if (rightReleased) this.applyFishingInput(model, "right", "release");
    if (Phaser.Input.Keyboard.JustUp(this.keys.S)) this.applyFishingInput(model, "hook", "release");
  }

  private applyFishingInput(
    model: QizhenFishingRhythmModel,
    action: QizhenFishingAction,
    type: "press" | "release"
  ): void {
    if (type === "press") {
      if (this.fishingHeldActions.has(action)) return;
      this.fishingHeldActions.add(action);
      model.handlePress(action);
      return;
    }
    if (!this.fishingHeldActions.delete(action)) return;
    model.handleRelease(action);
  }

  private scheduleFishingMetronome(): void {
    const audioContext = this.fishingAudioContext;
    const model = this.fishingModel;
    if (!this.fishingUsesAudioClock || !audioContext || audioContext.state !== "running" || model?.phase !== "running") {
      return;
    }
    const scheduleUntil = audioContext.currentTime + 0.12;
    while (
      this.fishingStartedAtSec + this.fishingNextMetronomeBeat * QIZHEN_FISHING_TIMING.beatSec
      <= scheduleUntil
    ) {
      const beatIndex = this.fishingNextMetronomeBeat;
      const beatTime = Math.max(
        audioContext.currentTime,
        this.fishingStartedAtSec + beatIndex * QIZHEN_FISHING_TIMING.beatSec
      );
      try {
        const oscillator = audioContext.createOscillator();
        const gain = audioContext.createGain();
        const finaleProgress = model.experience === "finale_full"
          ? Phaser.Math.Clamp(model.elapsedSec / model.durationSec, 0, 1)
          : 0;
        oscillator.type = "sine";
        oscillator.frequency.setValueAtTime(
          (beatIndex % 4 === 0 ? 820 : 610) + finaleProgress * (beatIndex % 4 === 0 ? 140 : 90),
          beatTime
        );
        gain.gain.setValueAtTime(0.0001, beatTime);
        gain.gain.exponentialRampToValueAtTime(
          (beatIndex % 4 === 0 ? 0.035 : 0.022) * (1 + finaleProgress * 0.45),
          beatTime + 0.004
        );
        gain.gain.exponentialRampToValueAtTime(0.0001, beatTime + 0.055);
        oscillator.connect(gain).connect(audioContext.destination);
        oscillator.start(beatTime);
        oscillator.stop(beatTime + 0.06);
      } catch {
        this.fishingUsesAudioClock = false;
        break;
      }
      this.fishingNextMetronomeBeat += 1;
    }
  }

  private resolveFishingModelResult(attempt: QizhenFishingAttempt, result: QizhenFishingResult): void {
    if (this.fishingResolving || this.fishingActiveAttempt?.sessionId !== attempt.sessionId) return;
    this.fishingResolving = true;
    if (!result.passed) {
      this.fishingFailureCounts[attempt.spotId] += 1;
      this.fishingVisual?.playFailure("grade", () => {
        this.finishFishingFailure(attempt, "grade", result);
      });
      return;
    }
    const submit = () => {
      if (this.fishingActiveAttempt?.sessionId !== attempt.sessionId) return;
      this.emitDomain("rpg_qizhen_fishing_resolve_requested", {
        sessionId: attempt.sessionId,
        spotId: attempt.spotId,
        targetId: attempt.target.id,
        itemId: attempt.itemId,
        result: result as unknown as Record<string, unknown>
      });
    };
    if (attempt.spotId === "paper") {
      submit();
    } else {
      this.fishingVisual?.playResult(result, submit);
    }
  }

  private resolveFishingModelFailure(attempt: QizhenFishingAttempt, reason: QizhenFishingFailReason): void {
    if (this.fishingResolving || this.fishingActiveAttempt?.sessionId !== attempt.sessionId) return;
    this.fishingResolving = true;
    this.fishingFailureCounts[attempt.spotId] += 1;
    this.fishingVisual?.playFailure(reason, () => this.finishFishingFailure(attempt, reason));
  }

  private finishFishingFailure(
    attempt: QizhenFishingAttempt,
    reason: QizhenFishingFailReason | "grade",
    result?: QizhenFishingResult
  ): void {
    if (this.fishingActiveAttempt?.sessionId !== attempt.sessionId) return;
    this.clearFishingSession();
    this.emitDomain("qizhen_fishing_failed", {
      sessionId: attempt.sessionId,
      spotId: attempt.spotId,
      reason,
      result: result as unknown as Record<string, unknown> | undefined,
      failures: this.fishingFailureCounts[attempt.spotId],
      assistNext: this.fishingFailureCounts[attempt.spotId] >= 2
    });
    this.showFeedback(
      this.fishingFailureCounts[attempt.spotId] >= 2
        ? "未通过：道具已保留。下次将扩大判定窗口并精简节拍。"
        : "未通过：道具已保留，靠近同一水纹可立即重试。",
      "system"
    );
  }

  private lockFishingPresentation(): void {
    this.zoneText?.setVisible(false);
    this.statusText?.setVisible(false);
    this.promptText?.setVisible(false);
    this.photoCameraButton?.setVisible(false);
    this.targetVisuals.forEach((visual) => visual.root.setVisible(false));
    this.dropGuides.forEach((guide) => guide.targetOutline.setVisible(false));
  }

  private clearFishingSession(): void {
    this.fishingPrecheckTimer?.remove();
    this.fishingPrecheckTimer = null;
    this.fishingModel?.cancel();
    this.fishingVisual?.destroy();
    this.fishingModel = null;
    this.fishingVisual = null;
    this.fishingPendingAttempt = null;
    this.fishingActiveAttempt = null;
    this.fishingHeldActions.clear();
    this.fishingResolving = false;
    this.fishingUsesAudioClock = false;
    this.fishingClockNow = () => performance.now() / 1000;
    this.zoneText?.setVisible(true);
    this.statusText?.setVisible(true);
    this.syncPhotoCameraButton();
    if (this.cameras?.main && this.player) {
      this.cameras.main
        .startFollow(this.player, true, 0.13, 0.13, 0, 18)
        .setDeadzone(250, 150);
    }
  }

  private cancelFishingSession(reason: string): void {
    const attempt = this.fishingActiveAttempt ?? this.fishingPendingAttempt;
    if (!attempt) return;
    this.clearFishingSession();
    if (this.bridge) {
      this.emitDomain("qizhen_fishing_cancelled", {
        sessionId: attempt.sessionId,
        spotId: attempt.spotId,
        reason
      });
    }
  }

  private triggerTarget(
    target: QizhenLakeInteractionTarget,
    state: GameState,
    runtime: QizhenRuntimeProjection
  ): void {
    if ((target.kind === "outfit" || target.kind === "board") && runtime.mode !== "light") {
      this.showFeedback(
        `${qizhenContent.mist.darkPrompt} ${formatRpgModeRequirement("light")}`,
        "system"
      );
      return;
    }
    if (target.kind === "exit") {
      this.emitDomain("rpg_qizhen_leave_requested");
      return;
    }
    if (target.kind === "outfit") {
      this.emitDomain("rpg_qizhen_outfit_requested", {
        targetId: target.id,
        part: target.value
      });
      return;
    }
    if (target.kind === "board") {
      this.emitDomain("rpg_qizhen_board_requested", { targetId: target.id });
      return;
    }
    if (target.kind === "safety_officer") {
      this.emitDomain("rpg_qizhen_safety_officer_requested", { targetId: target.id });
      return;
    }
    if (target.kind === "zone_portal" && target.targetZone) {
      this.emitDomain("rpg_qizhen_zone_requested", {
        zone: target.targetZone,
        from: this.currentZone,
        entry: target.id
      });
      return;
    }
    if (target.kind === "reflection") {
      this.emitDomain("rpg_qizhen_reflection_observe_requested", {
        targetId: target.value ?? target.id,
        zone: this.currentZone
      });
      return;
    }
    if (target.kind === "fishing_spot") {
      if (target.value === "fishing_rod") {
        this.emitDomain("rpg_qizhen_rod_requested", { targetId: target.id });
        this.animateFishingCast(target, false);
        return;
      }
      const itemId = target.value === "fish" ? CHAIN_ITEMS.pellets : CHAIN_ITEMS.fishingRod;
      this.requestFishingAttempt(target, itemId);
      return;
    }
    if (target.kind === "item_use") {
      if (target.value === "combine_final_rig") {
        this.emitDomain("rpg_qizhen_combine_requested", {
          itemIds: [CHAIN_ITEMS.cord, CHAIN_ITEMS.netFrame, CHAIN_ITEMS.magnet, CHAIN_ITEMS.fishingRod],
          targetId: target.id
        });
        return;
      }
      if (target.value === "combine_magnetic_rod") {
        this.emitDomain("rpg_qizhen_combine_requested", {
          itemIds: [CHAIN_ITEMS.magnet, CHAIN_ITEMS.fishingRod],
          targetId: target.id
        });
        return;
      }
      const itemId = target.value === "item_1_to_2"
        ? CHAIN_ITEMS.key
        : target.value === "item_4_to_5" ? CHAIN_ITEMS.dipNet : CHAIN_ITEMS.feedTin;
      this.emitDomain("rpg_qizhen_item_use_requested", { targetId: target.id, itemId });
      return;
    }
    if (target.kind === "swan") {
      this.emitDomain("rpg_qizhen_swan_branch_requested", { targetId: target.id });
      return;
    }
    if (target.kind === "paper") {
      if (target.value === "paper_reflection") {
        this.emitDomain("rpg_qizhen_fish_requested", {
          targetId: target.id,
          itemId: CHAIN_ITEMS.fishingRod,
          directPaperCast: true
        });
        this.animateFishingCast(target, true);
        return;
      }
      this.requestFishingAttempt(target, CHAIN_ITEMS.magneticRod);
      return;
    }
    if (target.kind === "escape") {
      this.emitDomain("rpg_qizhen_escape_completed_requested", {
        zone: "dock",
        distance: Math.max(runtime.chaseDistance, Math.round(this.chaseStartX - this.player.x))
      });
    }
  }

  private triggerPointerTarget(target: QizhenLakeInteractionTarget): void {
    if (this.dialogueLocked || this.zoneTransitioning || this.capsizing || this.photoSessionOpen) return;
    const state = this.bridge.getState();
    const runtime = readQizhenRuntime(state);
    if (!this.getActiveTargets(state, runtime).some((candidate) => candidate.id === target.id)) {
      const lockedHint = this.lockedPortalHintFor(target, runtime);
      if (lockedHint) this.showFeedback(lockedHint, this.dialogueToneFor(lockedHint));
      return;
    }
    if (!findNearestQizhenTarget(this.player.x, this.player.y, [target])) {
      this.showFeedback(qizhenContent.drop.tooFarGeneric, "system");
      return;
    }
    this.triggerTarget(target, state, runtime);
  }

  private handleInventoryDrop(payload?: Record<string, unknown>): void {
    const itemId = String(payload?.itemId ?? "") as ItemId;
    const canvasX = Number(payload?.canvasX);
    const canvasY = Number(payload?.canvasY);
    if (!Number.isFinite(canvasX) || !Number.isFinite(canvasY)) {
      this.emitDropFailure(itemId, "missed_target", undefined, qizhenContent.drop.missedTargetNoCoords);
      return;
    }
    const world = this.cameras.main.getWorldPoint(canvasX, canvasY);
    const state = this.bridge.getState();
    const runtime = readQizhenRuntime(state);
    const targets = this.getActiveTargets(state, runtime)
      .filter((candidate) => isRpgDropPointWithin(candidate, world.x, world.y))
      .sort((a, b) => getRpgDropBounds(a).width * getRpgDropBounds(a).height
        - getRpgDropBounds(b).width * getRpgDropBounds(b).height);
    const target = targets[0];
    if (!target) {
      this.emitDropFailure(itemId, "missed_target", undefined, qizhenContent.drop.missedTarget);
      return;
    }
    if (runtime.mode !== "light") {
      this.emitDropFailure(itemId, "wrong_mode", target.label, qizhenContent.drop.wrongMode);
      return;
    }
    if (!isPlayerWithinRpgTarget(target, this.player.x, this.player.y)) {
      this.emitDropFailure(itemId, "too_far", target.label, qizhenContent.drop.tooFar);
      return;
    }
    if (target.value === "paper_reflection") {
      if (itemId === CHAIN_ITEMS.decoy && !runtime.decoyBaitAttached) {
        this.emitDomain("rpg_qizhen_bait_requested", { itemId, targetId: target.id });
        return;
      }
      if (itemId === CHAIN_ITEMS.fishingRod) {
        this.emitDomain("rpg_qizhen_fish_requested", { targetId: target.id, itemId, directPaperCast: true });
        this.animateFishingCast(target, true);
        return;
      }
    }
    if (target.kind === "fishing_spot") {
      if (target.value === "fish" && itemId === CHAIN_ITEMS.pellets) {
        this.requestFishingAttempt(target, itemId);
        return;
      }
      if (["item_1", "item_3"].includes(String(target.value)) && itemId === CHAIN_ITEMS.fishingRod) {
        this.requestFishingAttempt(target, itemId);
        return;
      }
    }
    if (target.value === "item_1_to_2" && itemId === CHAIN_ITEMS.key) {
      this.emitDomain("rpg_qizhen_item_use_requested", { targetId: target.id, itemId });
      return;
    }
    if (target.value === "item_4_to_5" && itemId === CHAIN_ITEMS.dipNet) {
      this.emitDomain("rpg_qizhen_item_use_requested", { targetId: target.id, itemId });
      return;
    }
    if (target.value === "item_5_to_6" && itemId === CHAIN_ITEMS.feedTin) {
      this.emitDomain("rpg_qizhen_item_use_requested", { targetId: target.id, itemId });
      return;
    }
    if (target.value === "combine_final_rig"
      && [CHAIN_ITEMS.cord, CHAIN_ITEMS.netFrame, CHAIN_ITEMS.magnet, CHAIN_ITEMS.fishingRod].includes(itemId as never)) {
      this.emitDomain("rpg_qizhen_combine_requested", {
        itemIds: [CHAIN_ITEMS.cord, CHAIN_ITEMS.netFrame, CHAIN_ITEMS.magnet, CHAIN_ITEMS.fishingRod],
        targetId: target.id
      });
      return;
    }
    if (target.value === "combine_magnetic_rod" && [CHAIN_ITEMS.magnet, CHAIN_ITEMS.fishingRod].includes(itemId as never)) {
      this.emitDomain("rpg_qizhen_combine_requested", {
        itemIds: [CHAIN_ITEMS.magnet, CHAIN_ITEMS.fishingRod],
        targetId: target.id
      });
      return;
    }
    if (target.value === "paper_body" && itemId === CHAIN_ITEMS.magneticRod) {
      this.requestFishingAttempt(target, itemId);
      return;
    }
    this.emitDropFailure(itemId, "wrong_item", target.label, this.dropCorrectionFor(target));
  }

  private handleBridgeEvent(name: string, payload?: Record<string, unknown>): void {
    if (!this.sys?.isActive()) return;
    if (name === "qizhen_fishing_prechecked") {
      const sessionId = String(payload?.sessionId ?? "");
      const attempt = this.fishingPendingAttempt;
      if (!attempt || attempt.sessionId !== sessionId) return;
      this.fishingPrecheckTimer?.remove();
      this.fishingPrecheckTimer = null;
      this.animateFishingCast(attempt.target, true, () => this.beginFishingSession(attempt));
      return;
    }
    if (name === "qizhen_fishing_precheck_failed") {
      const sessionId = String(payload?.sessionId ?? "");
      if (this.fishingPendingAttempt?.sessionId === sessionId) {
        this.cancelFishingSession(String(payload?.reason ?? "precheck_failed"));
      }
      return;
    }
    if (name === "rpg_qizhen_fishing_input") {
      const model = this.fishingModel;
      const action = String(payload?.action ?? "");
      const type = String(payload?.type ?? "");
      if (
        model
        && (action === "left" || action === "right" || action === "hook")
        && (type === "press" || type === "release")
      ) {
        this.applyFishingInput(model, action, type);
      }
      return;
    }
    if (name === "qizhen_fishing_completed" || name === "qizhen_fishing_failed") {
      const sessionId = String(payload?.sessionId ?? "");
      const attempt = this.fishingActiveAttempt ?? this.fishingPendingAttempt;
      if (attempt?.sessionId === sessionId) {
        if (name === "qizhen_fishing_completed") this.fishingFailureCounts[attempt.spotId] = 0;
        this.clearFishingSession();
      }
      return;
    }
    if (name === "qizhen_fishing_cancelled") return;

    if (name === "qizhen_photo_session_opened") {
      this.handlePhotoSessionOpened(payload);
      return;
    }
    if (name === "qizhen_photo_session_closed") {
      this.handlePhotoSessionClosed();
      return;
    }
    if (this.photoSessionOpen && (
      name === "rpg_direction_changed"
      || name === "rpg_interact"
      || name === "rpg_qizhen_paddle_input"
      || name === "rpg_qizhen_reverse_changed"
      || name === "rpg_inventory_drop_requested"
    )) return;

    if (this.fishingPendingAttempt || this.fishingActiveAttempt) {
      if (
        name === "rpg_direction_changed"
        || name === "rpg_interact"
        || name === "rpg_qizhen_paddle_input"
        || name === "rpg_qizhen_reverse_changed"
        || name === "rpg_inventory_drop_requested"
      ) return;
    }
    if (name === "rpg_direction_changed") {
      const x = Number(payload?.x) || 0;
      const y = Number(payload?.y) || 0;
      if (this.currentVehicle === "kayak") {
        this.virtualReverseHeld = y > 0;
        const direction: QizhenPaddleDirection = this.virtualReverseHeld ? "reverse" : "forward";
        if (x < 0 && this.lastVirtualPaddleX >= 0) this.performPaddleStroke("left", direction, readQizhenRuntime(this.bridge.getState()));
        if (x > 0 && this.lastVirtualPaddleX <= 0) this.performPaddleStroke("right", direction, readQizhenRuntime(this.bridge.getState()));
        this.lastVirtualPaddleX = x;
        this.virtualDirection = { x: 0, y: 0 };
      } else {
        this.virtualDirection = { x, y };
      }
      return;
    }
    if (name === "rpg_interact") {
      this.interactRequested = true;
      return;
    }
    if (name === "rpg_qizhen_paddle_input" && typeof payload?.pointerType === "string") {
      const side = String(payload?.side) === "right" ? "right" : "left";
      const direction: QizhenPaddleDirection = String(payload?.direction) === "reverse" ? "reverse" : "forward";
      this.performPaddleStroke(side, direction, readQizhenRuntime(this.bridge.getState()));
      return;
    }
    if (name === "rpg_qizhen_reverse_changed") {
      this.virtualReverseHeld = payload?.held === true;
      this.reverseInputHeld = this.virtualReverseHeld;
      return;
    }
    if (name === "rpg_inventory_drop_requested") {
      this.handleInventoryDrop(payload);
      return;
    }
    if (name === "qizhen_mode_changed") {
      this.playModeTransition(String(payload?.mode) === "dark" ? "dark" : "light");
      return;
    }
    if (name === "qizhen_outfit_part_collected") {
      return;
    }
    if (name === "qizhen_kayak_boarded") {
      return;
    }
    if (name === "qizhen_dock_safety_warning_recorded") {
      this.showFeedback(qizhenContent.dock.safetyRainBlock, "system", 4200);
      return;
    }
    if (name === "qizhen_dock_safety_warning_repeated") {
      this.showFeedback(qizhenContent.dock.safetyWarningRepeated, "system", 3600);
      return;
    }
    if (name === "qizhen_rain_forced_launch_started") {
      this.playRainRescueSequence();
      return;
    }
    if (name === "qizhen_dock_safety_cleared" || name === "qizhen_dock_weather_adjusted") {
      this.showFeedback(qizhenContent.dock.safetyCleared, "success", 4200);
      return;
    }
    if (name === "qizhen_dock_safety_checked") {
      this.showFeedback(qizhenContent.dock.safetyAlreadyCleared, "system", 3000);
      return;
    }
    if (name === "qizhen_kayak_board_rejected") {
      this.showFeedback(qizhenContent.dock.boardRainRejected, "system", 3600);
      return;
    }
    if (name === "qizhen_boarding_stroke_recorded") {
      if (payload?.alternating !== true && this.time.now - this.sameSideHintAt > SAME_SIDE_HINT_COOLDOWN_MS) {
        this.sameSideHintAt = this.time.now;
        this.showFeedback(qizhenContent.boarding.sameSide, "system", 1800);
      }
      return;
    }
    if (name === "qizhen_boarding_completed") {
      this.showFeedback(qizhenContent.boarding.complete, "success");
      return;
    }
    if (name === "qizhen_capsize_loss_subtitle_unlocked") {
      this.showFeedback(qizhenContent.boarding.capsizeLossSubtitle, "narrator", 6500);
      return;
    }
    if (name === "qizhen_reflection_observed") {
      if (String(payload?.spotId ?? "") === "paper") {
        this.showFeedback(qizhenContent.reflection.afterPaper[0], "system");
      } else {
        this.showFeedback(qizhenContent.reflection.correct, "success");
      }
      return;
    }
    if (name === "qizhen_fishing_rod_found") {
      this.queueDialogue([qizhenContent.lake.rodFound]);
      return;
    }
    if (name === "qizhen_decoy_bait_attached") {
      this.showFeedback(qizhenContent.decoy.correct, "success");
      return;
    }
    if (name === "qizhen_direct_paper_cast_failed") {
      this.showFeedback(qizhenContent.lake.directPaperFailure, "system");
      return;
    }
    if (name === "qizhen_item_caught") {
      const spotId = String(payload?.spotId ?? "");
      this.showFeedback(
        spotId === "locker_key" ? qizhenContent.toolChain.keyCaught : qizhenContent.toolChain.netFrameCaught,
        "success"
      );
      return;
    }
    if (name === "qizhen_locker_opened") {
      this.showFeedback(qizhenContent.toolChain.lockerOpened, "success");
      return;
    }
    if (name === "qizhen_dip_net_combined") {
      this.showFeedback(qizhenContent.toolChain.netCombined, "success");
      return;
    }
    if (name === "qizhen_feed_tin_retrieved") {
      this.showFeedback(qizhenContent.toolChain.feedTinRetrieved, "success");
      return;
    }
    if (name === "qizhen_feed_tin_opened") {
      this.showFeedback(qizhenContent.toolChain.feedTinOpened, "success");
      return;
    }
    if (name === "qizhen_fish_caught") {
      this.showFeedback(qizhenContent.toolChain.fishCaught, "success");
      return;
    }
    if (name === "qizhen_swan_fed") {
      this.queueDialogue([qizhenContent.swan.reward]);
      return;
    }
    if (name === "qizhen_swan_branch_completed") {
      this.queueDialogue([
        "浮排边的旧饲料盒被捞起并撬开。",
        "饲料撒入围栏，黑天鹅把一枚磁性扣推到船边。"
      ]);
      return;
    }
    if (name === "qizhen_final_rig_combined") {
      this.showFeedback("三处分支素材已合并，可以进行最终捕纸。", "success");
      return;
    }
    if (name === "qizhen_magnetic_rod_combined") {
      this.showFeedback(qizhenContent.swan.rodReady, "success");
      return;
    }
    if (name === "qizhen_paper_captured") {
      this.showFeedback(qizhenContent.swan.paperCapture, "success");
      return;
    }
    if (name === "qizhen_escape_completed") {
      this.showFeedback(qizhenContent.chase.complete, "success");
      return;
    }
    if (name === "qizhen_lake_leave_rejected") {
      this.showFeedback(qizhenContent.dock.leaveLocked, "system");
    }
  }

  private updateTargetVisuals(
    targets: readonly QizhenLakeInteractionTarget[],
    nearest: QizhenLakeInteractionTarget | null,
    state: GameState,
    runtime: QizhenRuntimeProjection
  ): void {
    const activeById = new Map(targets.map((target) => [target.id, target] as const));
    const activeIds = new Set(activeById.keys());
    const selectedItem = state.ui.selectedItem;
    this.targetVisuals.forEach((visual) => {
      const active = activeIds.has(visual.target.id);
      const activeTarget = activeById.get(visual.target.id);
      if (activeTarget) visual.root.setPosition(activeTarget.x, activeTarget.y);
      const vehicleMatches = !visual.target.vehicle || visual.target.vehicle === this.currentVehicle;
      const lockedPortal = !active && vehicleMatches && this.lockedPortalHintFor(visual.target, runtime) !== null;
      const isWaterRipple = isQizhenWaterRippleTarget(visual.target);
      visual.root.setVisible(active || lockedPortal);
      visual.sparkles.forEach((sparkle) => sparkle.setVisible(active));
      visual.pulse.setVisible(active && (isWaterRipple || visual.target.value === "fishing_rod"));
      visual.rippleBands.forEach((band) => band.setVisible(active && isWaterRipple));
      visual.rippleCenter?.setVisible(active && isWaterRipple);
      if (!active) {
        if (lockedPortal) {
          visual.root.setAlpha(0.35).setScale(1);
          visual.pulse.setStrokeStyle(3, visual.color, 0.88);
          visual.label.setVisible(false);
        }
        return;
      }
      const isNearest = nearest?.id === visual.target.id;
      const matchesSelectedItem = selectedItem !== null && qizhenTargetAcceptsItem(visual.target, selectedItem);
      visual.label.setVisible(isWaterRipple && (isNearest || matchesSelectedItem));
      visual.pulse
        .setAlpha(isNearest || matchesSelectedItem ? 1 : isWaterRipple ? 0.82 : 0.5)
        .setStrokeStyle(
          isWaterRipple ? 4 : 3,
          matchesSelectedItem ? 0x63e58b : visual.color,
          matchesSelectedItem ? 1 : 0.88
        );
      visual.root.setScale(isNearest ? 1.08 : 1);
      let alpha = 1;
      if ((visual.target.kind === "reflection" || visual.target.value === "paper_reflection") && runtime.mode !== "dark") {
        alpha = 0.38;
      }
      if (selectedItem !== null && !matchesSelectedItem) alpha = Math.min(alpha, 0.3);
      visual.root.setAlpha(alpha);
    });
    this.staticSwan?.root.setVisible(this.currentZone === "swan_cove" && runtime.phase !== "swan_chase");
    this.syncDropGuides(targets, selectedItem);
  }

  private syncDropGuides(
    targets: readonly QizhenLakeInteractionTarget[],
    selectedItem: ItemId | null
  ): void {
    const activeById = new Map(targets.map((target) => [target.id, target] as const));
    this.dropGuides.forEach((guide) => {
      const activeTarget = activeById.get(guide.target.id);
      const matches = selectedItem !== null && qizhenTargetAcceptsItem(guide.target, selectedItem);
      const visible = activeTarget !== undefined && matches;
      guide.targetOutline.setVisible(visible);
      if (!visible) return;
      guide.targetOutline.setPosition(activeTarget.x, activeTarget.y);
      const ready = isPlayerWithinRpgTarget(activeTarget, this.player.x, this.player.y);
      guide.targetOutline.setStrokeStyle(ready ? 3 : 2, ready ? 0x63e58b : 0x72dcff, 0.92);
    });
  }

  private lockedPortalHintFor(
    target: QizhenLakeInteractionTarget,
    runtime: QizhenRuntimeProjection
  ): string | null {
    if (target.kind !== "zone_portal") return null;
    if (target.id === "qizhen_dock_to_open" && !runtime.boardingTutorialCompleted) {
      return qizhenContent.portals.lockedDockToOpen;
    }
    if (target.id === "qizhen_open_to_swan" && !runtime.fishCaught && runtime.phase !== "swan_exchange") {
      return qizhenContent.portals.lockedOpenToSwan;
    }
    if (target.id === "qizhen_open_to_channel" && runtime.phase !== "swan_chase") {
      if (!runtime.netCombined) return qizhenContent.portals.lockedOpenToChannelNet;
      if (runtime.feedTinOpened && !runtime.fishCaught) return qizhenContent.portals.lockedOpenToChannelDone;
    }
    if (target.id === "qizhen_swan_to_channel" && runtime.phase !== "swan_chase" && !runtime.swanReleased) {
      return qizhenContent.portals.lockedSwanToChannel;
    }
    if (target.id === "qizhen_channel_to_open" && runtime.phase !== "swan_chase" && !runtime.feedTinOpened) {
      return qizhenContent.portals.lockedChannelToOpen;
    }
    return null;
  }

  private updateLockedPortalHint(
    targets: readonly QizhenLakeInteractionTarget[],
    runtime: QizhenRuntimeProjection
  ): void {
    if (this.dialogueLocked || this.zoneTransitioning || this.capsizing) return;
    const activeIds = new Set(targets.map((target) => target.id));
    const portal = targetsForQizhenZone(this.currentZone, this.currentVehicle)
      .find((target) => (
        !activeIds.has(target.id)
        && this.lockedPortalHintFor(target, runtime) !== null
        && isPlayerWithinRpgTarget(target, this.player.x, this.player.y)
      ));
    if (!portal) {
      this.lockedPortalHintId = null;
      return;
    }
    const now = this.time.now;
    if (this.lockedPortalHintId === portal.id && now - this.lockedPortalHintAt < LOCKED_PORTAL_HINT_REPEAT_MS) {
      return;
    }
    this.lockedPortalHintId = portal.id;
    this.lockedPortalHintAt = now;
    const hint = this.lockedPortalHintFor(portal, runtime)!;
    this.showFeedback(hint, this.dialogueToneFor(hint));
  }

  private updatePrompt(target: QizhenLakeInteractionTarget | null, runtime: QizhenRuntimeProjection): void {
    if (!target || this.dialogueLocked || this.zoneTransitioning || this.capsizing || this.photoSessionOpen) {
      this.promptText.setVisible(false);
      return;
    }
    let action = target.kind === "outfit"
      ? target.value === "kayak"
        ? qizhenContent.prompts.collectKayak
        : target.value === "left_paddle"
          ? qizhenContent.prompts.collectLeftPaddle
          : qizhenContent.prompts.collectRightPaddle
      : target.kind === "board"
        ? qizhenContent.prompts.board
        : target.kind === "zone_portal"
          ? target.label
          : target.kind === "reflection"
            ? qizhenContent.prompts.observeReflection
            : target.kind === "fishing_spot"
              ? target.value === "fishing_rod" ? qizhenContent.prompts.collectRod : qizhenContent.prompts.cast
              : target.kind === "item_use"
                ? target.label
                : target.kind === "swan"
                  ? qizhenContent.prompts.feedSwan
                  : target.kind === "paper"
                    ? target.value === "paper_reflection" && !runtime.decoyBaitAttached
                      ? qizhenContent.prompts.decoyFirst
                      : qizhenContent.prompts.useRig
                    : target.kind === "escape"
                      ? qizhenContent.prompts.escape
                      : qizhenContent.prompts.leave;
    if ((target.kind === "outfit" || target.kind === "board") && runtime.mode !== "light") {
      action = qizhenContent.prompts.needLight;
    }
    const itemOnly = target.kind === "paper" && target.value === "paper_reflection" && !runtime.decoyBaitAttached;
    const automaticEscape = target.kind === "escape" && runtime.phase === "swan_chase";
    const camera = this.cameras.main;
    const playerScreenY = (this.player.y - camera.worldView.y)
      * getRpgLogicalCameraZoom(this, camera);
    const promptY = Math.abs(playerScreenY - RPG_HUD_LAYOUT.promptBottomY) < 78
      ? Math.min(492, RPG_HUD_LAYOUT.promptBottomY + 70)
      : RPG_HUD_LAYOUT.promptBottomY;
    this.promptText
      .setY(promptY)
      .setText(
        automaticEscape
          ? qizhenContent.prompts.escapeAuto
          : itemOnly ? formatRpgDragHint(action) : formatRpgInteractionHint(action)
      )
      .setVisible(true);
  }

  private updateStatus(runtime: QizhenRuntimeProjection): void {
    const zoneLabel = this.currentZone === "dock"
      ? qizhenContent.zones.dock
      : this.currentZone === "open_water"
        ? qizhenContent.zones.openWater
        : this.currentZone === "channel" ? qizhenContent.zones.channel : qizhenContent.zones.swanCove;
    this.zoneText.setText(`${zoneLabel} · ${RPG_REALITY_MODE_CONTRACT[runtime.mode].label}`);
    if (this.currentVehicle === "kayak") {
      const tilt = Math.round(Math.min(1, Math.abs(this.kayakRoll)) * 100);
      const danger = tilt >= 70 ? ` · ${qizhenContent.boarding.capsizeWarning}` : "";
      const chaseGap = runtime.phase === "swan_chase"
        ? ` · ${qizhenContent.chase.statusSuffix} · ${qizhenContent.chase.gapLabel} ${Math.max(0, Math.round(this.chaseActualGap))}`
        : "";
      const chaseDanger = runtime.phase === "swan_chase" && this.chaseActualGap <= SWAN_CHASE_NEAR_DISTANCE
        ? ` · ${qizhenContent.chase.dangerClose}`
        : "";
      const strokeMode = this.reverseInputHeld
        ? qizhenContent.boarding.reverseMode
        : this.kayakSpeed < -0.4
          ? qizhenContent.boarding.reverseCoast
          : qizhenContent.boarding.forwardMode;
      this.statusText.setText(
        `${qizhenContent.boarding.controls} · ${strokeMode} · ${qizhenContent.boarding.tilt} ${tilt}%${danger}${chaseGap}${chaseDanger}`
      );
      this.statusText.setColor(tilt >= 70 || chaseDanger.length > 0 ? "#ffaaa0" : "#fff2b6");
    } else if (!runtime.kayakEquipped) {
      this.statusText.setText(qizhenContent.dock.kayakHint).setColor("#fff2b6");
    } else if (!runtime.leftPaddleEquipped) {
      this.statusText.setText(qizhenContent.dock.leftPaddleHint).setColor("#fff2b6");
    } else if (!runtime.rightPaddleEquipped) {
      this.statusText.setText(qizhenContent.dock.rightPaddleHint).setColor("#fff2b6");
    } else {
      this.statusText.setText(qizhenContent.dock.boardPrompt).setColor("#fff2b6");
    }
  }

  private updateAfterRainPuddleEvidence(): void {
    if (
      this.currentZone !== "dock"
      || !this.currentRainSafetyCleared
      || this.currentVehicle !== "on_foot"
      || this.dialogueLocked
      || this.zoneTransitioning
      || this.capsizing
    ) {
      this.activeAfterRainPuddleId = null;
      return;
    }
    const body = this.player.body as Phaser.Physics.Arcade.Body | undefined;
    const footX = body?.center.x ?? this.player.x;
    const footY = body?.bottom ?? this.player.y;
    const puddle = QIZHEN_DOCK_AFTER_RAIN_PUDDLES.find((candidate) => (
      isQizhenAfterRainPuddleFootHit(candidate, footX, footY)
    ));
    this.activeAfterRainPuddleId = puddle?.id ?? null;
    if (!puddle || this.enteredAfterRainPuddleIds.has(puddle.id)) return;
    this.enteredAfterRainPuddleIds.add(puddle.id);
    this.showFeedback(qizhenContent.dock.afterRainProof, "player", 2600);
  }

  /** 触控端 HUD 相机按钮:仅在 coarse/hybrid 指针下创建,放在底部右侧安全区。 */
  private createPhotoCameraButton(): void {
    const profile = detectInputProfile();
    if (profile !== "coarse" && profile !== "hybrid") return;
    const background = this.add.rectangle(0, 0, 128, 44, 0x09212d, 0.92)
      .setStrokeStyle(3, 0x7de8ff, 0.9);
    const label = this.add.text(0, 0, "相机", {
      color: "#e9ffff",
      fontFamily: "monospace",
      fontSize: "16px"
    }).setOrigin(0.5);
    const button = this.add.container(864, 496, [background, label])
      .setScrollFactor(0)
      .setDepth(5200)
      .setSize(128, 44)
      .setInteractive({ useHandCursor: true });
    button.on("pointerdown", () => {
      background.setFillStyle(0x14495c, 0.96);
      this.requestPhotoSession();
    });
    button.on("pointerup", () => background.setFillStyle(0x09212d, 0.92));
    button.on("pointerout", () => background.setFillStyle(0x09212d, 0.92));
    this.photoCameraButton = button;
    this.syncPhotoCameraButton();
  }

  private syncPhotoCameraButton(): void {
    this.photoCameraButton?.setVisible(
      !this.photoSessionOpen
      && !this.zoneTransitioning
      && !this.fishingPendingAttempt
      && !this.fishingActiveAttempt
    );
  }

  private requestPhotoSession(): void {
    if (this.photoSessionOpen) return;
    if (this.fishingPendingAttempt || this.fishingActiveAttempt) {
      this.showFeedback("正在节奏钓取,收竿后再拍。", "system");
      return;
    }
    const state = this.bridge.getState();
    const runtime = readQizhenRuntime(state);
    if (runtime.phase === "swan_chase") {
      this.showFeedback("黑天鹅正追着船尾,顾不上拍照。", "system");
      return;
    }
    if (this.currentVehicle !== "kayak" && this.currentZone !== "dock") {
      this.showFeedback("这里要上船后才能取景。", "system");
      return;
    }
    if (this.capsizing || this.zoneTransitioning) {
      this.showFeedback("船还没停稳,等一下再拍。", "system");
      return;
    }
    if (this.dialogueLocked) {
      this.showFeedback("先听完这段话,再打开相机。", "system");
      return;
    }
    const spotId = resolveQizhenPhotoSpot(this.currentZone, this.player.x, this.player.y);
    if (!spotId) {
      const nearest = nearestQizhenPhotoSpot(this.currentZone, this.player.x, this.player.y);
      this.showFeedback(
        nearest
          ? `这里构不成画面,再往${nearest.label}靠一靠。`
          : "河道里取景太窄,去大湖面或黑天鹅围栏旁再拍。",
        "system"
      );
      return;
    }
    // kind 与 controller 的 journalCaptureKind 保持一致:lake_center 在主帖发布前
    // 一律是主帖拍摄(允许草稿期内重拍);发布后(含归档)才降为普通补拍。
    const journal = state.qizhenLake.journal;
    const mainPublished = journal.publishedSpotIds.includes("lake_center")
      || journal.status === "open"
      || journal.status === "summary_ready"
      || journal.status === "archived";
    const kind: "main" | "spot" = spotId === "lake_center" && !mainPublished ? "main" : "spot";
    const recipe = buildQizhenPhotoRecipe(spotId, {
      kayakX: this.player.x,
      kayakY: this.player.y,
      heading: this.kayakHeading,
      swanDistance: spotId === "swan_cove"
        ? runtime.swanReleased
          ? "gone"
          : Math.hypot(
            this.player.x - SWAN_COVE_SWAN_ANCHOR.x,
            this.player.y - SWAN_COVE_SWAN_ANCHOR.y
          )
        : undefined,
      rippleVisible: spotId === "reflection"
        ? Phaser.Math.Clamp(
          1 - Math.abs(this.kayakSpeed) / 240 - Math.abs(this.kayakRoll) / 1.2,
          0,
          1
        )
        : undefined
    });
    const speed = Math.round(this.kayakSpeed);
    const roll = Number(this.kayakRoll.toFixed(3));
    // 捕获时刻取湖区会话的单调秒数(Phaser 游戏时钟),保证重复请求幂等。
    const capturedAtSeconds = Math.max(0, Math.floor(this.time.now / 1000));
    this.lastPhotoSessionRequest = { spotId, recipe, speed, roll, kind, capturedAtSeconds };
    this.emitDomain("qizhen_photo_session_requested", { spotId, recipe, speed, roll, kind, capturedAtSeconds });
  }

  private handlePhotoSessionOpened(payload?: Record<string, unknown>): void {
    this.photoSessionOpen = true;
    const spotId = payload?.spotId;
    this.photoSessionSpotId = typeof spotId === "string" ? (spotId as QizhenPhotoSpotId) : null;
    this.interactRequested = false;
    this.virtualDirection = { x: 0, y: 0 };
    this.lastVirtualPaddleX = 0;
    this.virtualReverseHeld = false;
    this.reverseInputHeld = false;
    this.promptText.setVisible(false);
    this.syncPhotoCameraButton();
  }

  private handlePhotoSessionClosed(): void {
    if (!this.photoSessionOpen) return;
    this.photoSessionOpen = false;
    this.photoSessionSpotId = null;
    this.interactRequested = false;
    this.virtualDirection = { x: 0, y: 0 };
    this.lastVirtualPaddleX = 0;
    this.virtualReverseHeld = false;
    this.reverseInputHeld = false;
    this.kayakSpeed = 0;
    if (this.player) this.player.setVelocity(0, 0);
    // 相机覆盖层可能吞掉 keyup,重置按键状态避免关闭后按键粘连。
    this.input.keyboard?.resetKeys();
    this.syncPhotoCameraButton();
    // host 侧拥有正式焦点管理;这里做一次兜底,保证 canvas 恢复键盘焦点。
    this.game?.canvas?.focus();
  }

  private updateOcclusion(): void {
    const body = this.player.body as Phaser.Physics.Arcade.Body;
    const playerBounds = this.currentVehicle === "kayak"
      ? new Phaser.Geom.Rectangle(this.player.x - 60, this.player.y - 30, 120, 60)
      : this.player.getBounds();
    const footY = body.bottom;
    const active: string[] = [];
    const softened: string[] = [];
    this.occlusionVisuals.forEach((visual) => {
      const horizontalOverlap = playerBounds.right > visual.bounds.left && playerBounds.left < visual.bounds.right;
      const behind = horizontalOverlap && footY < visual.definition.sortY - 1;
      const intersects = behind && Phaser.Geom.Intersects.RectangleToRectangle(playerBounds, visual.bounds);
      const targetAlpha = intersects ? 0.48 : 1;
      visual.image
        .setDepth(behind ? this.player.y + 175 : -900)
        .setVisible(behind)
        .setAlpha(this.reducedMotion ? targetAlpha : Phaser.Math.Linear(visual.image.alpha, targetAlpha, 0.18));
      if (behind) active.push(visual.definition.id);
      if (intersects) softened.push(visual.definition.id);
    });
    this.activeOcclusionIds = active;
    this.softenedOcclusionIds = softened;
  }

  private playModeTransition(mode: QizhenLakeMode): void {
    this.currentMode = mode;
    this.tweens.killTweensOf(this.darkOverlay);
    this.tweens.add({
      targets: this.darkOverlay,
      alpha: mode === "dark" ? 0.66 : 0,
      duration: this.reducedMotion ? 60 : 260,
      ease: "Cubic.easeInOut"
    });
  }

  private animateFishingCast(
    target: QizhenLakeInteractionTarget,
    splash: boolean,
    onLanded?: () => void
  ): void {
    const line = this.add.line(
      0,
      0,
      this.player.x,
      this.player.y,
      this.player.x,
      this.player.y,
      0xeaf6ee,
      0.9
    ).setOrigin(0).setDepth(2500);
    const bobber = this.add.circle(this.player.x, this.player.y, 7, 0xfff0c4, 1)
      .setStrokeStyle(3, 0xe54d46, 1)
      .setDepth(2502);
    this.tweens.addCounter({
      from: 0,
      to: 1,
      duration: this.reducedMotion ? 80 : 360,
      ease: "Cubic.easeOut",
      onUpdate: (tween) => {
        const progress = tween.getValue() ?? 0;
        const x = Phaser.Math.Linear(this.player.x, target.x, progress);
        const y = Phaser.Math.Linear(this.player.y, target.y, progress) - Math.sin(progress * Math.PI) * 72;
        bobber.setPosition(x, y);
        line.setTo(this.player.x, this.player.y, x, y);
      },
      onComplete: () => {
        line.destroy();
        if (!splash) {
          bobber.destroy();
          onLanded?.();
          return;
        }
        const ring = this.add.ellipse(target.x, target.y, 26, 10, 0xdafaff, 0)
          .setStrokeStyle(3, 0xeaffff, 0.9)
          .setDepth(2501)
          .setScale(0.5);
        bobber.destroy();
        this.tweens.add({
          targets: ring,
          scale: 2.1,
          alpha: { from: 0.9, to: 0 },
          duration: 520,
          ease: "Cubic.easeOut",
          onComplete: () => ring.destroy()
        });
        onLanded?.();
      }
    });
  }

  private queueDialogue(
    lines: readonly string[],
    onComplete?: () => void,
    stepMs = FEEDBACK_MS
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

  private showFeedback(text: string, tone: GameSubtitleTone, durationMs = FEEDBACK_MS - 120): void {
    this.emitDomain("rpg_subtitle", { text, tone, durationMs });
  }

  private emitDropFailure(
    itemId: ItemId,
    reason: "missed_target" | "wrong_item" | "too_far" | "wrong_mode" | "locked",
    targetLabel?: string,
    detail?: string
  ): void {
    this.emitDomain("rpg_item_use_feedback", { itemId, reason, targetLabel, detail });
  }

  private dropCorrectionFor(target: QizhenLakeInteractionTarget): string {
    if (target.value === "paper_reflection") return qizhenContent.decoy.baitFirst;
    if (target.value === "item_1_to_2") return qizhenContent.toolChain.needKey;
    if (target.value === "combine_net") return qizhenContent.toolChain.needNetParts;
    if (target.value === "item_4_to_5") return qizhenContent.toolChain.needDipNet;
    if (target.value === "item_5_to_6") return qizhenContent.toolChain.needFeedTin;
    if (target.kind === "swan") return qizhenContent.swan.wrongItem;
    if (target.value === "combine_magnetic_rod") return qizhenContent.swan.needMagnetParts;
    if (target.value === "paper_body") return qizhenContent.swan.needMagneticRod;
    return qizhenContent.drop.wrongItemFallback;
  }

  private publishDebugState(
    target: QizhenLakeInteractionTarget | null,
    targets: readonly QizhenLakeInteractionTarget[],
    runtime: QizhenRuntimeProjection
  ): void {
    const definition = QIZHEN_LAKE_ZONES[this.currentZone];
    const photoSpotId = resolveQizhenPhotoSpot(this.currentZone, this.player.x, this.player.y);
    setRpgRuntimeDebugState({
      coordinateSystem: "Phaser world coordinates, origin at top-left, x right, y down",
      world: QIZHEN_LAKE_WORLD,
      player: {
        x: Math.round(this.player.x),
        y: Math.round(this.player.y),
        facing: this.currentVehicle === "kayak" ? "side" : this.playerAnimator.facing,
        cardinalFacing: this.currentVehicle === "kayak" ? undefined : this.playerAnimator.cardinalFacing,
        texture: this.currentVehicle === "kayak" ? "dynamic-kayak-rower" : this.playerAnimator.textureKey,
        turning: this.currentVehicle === "kayak" ? Math.abs(this.kayakRoll) > 0.08 : this.playerAnimator.isTurning,
        walkFps: this.currentVehicle === "kayak" ? undefined : RPG_PLAYER_WALK_FPS,
        angle: Number(Phaser.Math.RadToDeg(this.kayakHeading).toFixed(1)),
        collisionWidth: Number((this.player.body?.width ?? 0).toFixed(2)),
        collisionHeight: Number((this.player.body?.height ?? 0).toFixed(2))
      },
      camera: {
        scrollX: Math.round(this.cameras.main.scrollX),
        scrollY: Math.round(this.cameras.main.scrollY),
        zoom: Number(this.cameras.main.zoom.toFixed(2)),
        mode: this.fishingActiveAttempt ? "fishing_lock" : "follow"
      },
      scene: "qizhen_lake",
      checkpoint: this.bridge.getState().rpgCheckpoint,
      activeTargets: targets.map((candidate) => ({
        id: candidate.id,
        label: candidate.label,
        x: candidate.x,
        y: candidate.y,
        width: getRpgDropBounds(candidate).width,
        height: getRpgDropBounds(candidate).height,
        dropWidth: candidate.dropWidth,
        dropHeight: candidate.dropHeight,
        stand: candidate.stand,
        proximity: candidate.proximity,
        acceptedItem: candidate.acceptedItem,
        requiredMode: candidate.requiredMode
      })),
      collisionRects: this.getActiveCollisionRects(this.currentVehicle),
      qizhenLake: {
        phase: runtime.phase,
        mode: runtime.mode,
        plate: this.currentZone,
        zone: this.currentZone,
        vehicle: this.currentVehicle,
        dockSignRemoved: this.currentDockSignRemoved,
        rainEffects: {
          active: this.currentZone === "dock" && !this.currentRainSafetyCleared,
          ...QIZHEN_DOCK_RAIN_EFFECT_PROFILE
        },
        afterRainPuddles: {
          visible: this.currentZone === "dock" && this.currentRainSafetyCleared,
          activeId: this.activeAfterRainPuddleId,
          enteredIds: [...this.enteredAfterRainPuddleIds],
          definitions: QIZHEN_DOCK_AFTER_RAIN_PUDDLES.map((puddle) => ({ ...puddle }))
        },
        activeTarget: target?.id ?? null,
        kayak: {
          heading: Number(this.kayakHeading.toFixed(3)),
          speed: Math.round(this.kayakSpeed),
          travelDirection: this.kayakSpeed < -0.4 ? "reverse" : this.kayakSpeed > 0.4 ? "forward" : "stopped",
          reverseInputHeld: this.reverseInputHeld,
          wakeOrigin: this.kayakSpeed < -0.4 ? "bow" : this.kayakSpeed > 0.4 ? "stern" : "none",
          roll: Number(this.kayakRoll.toFixed(3)),
          strokeIndex: this.strokeIndex,
          lastStrokeSide: this.lastStrokeSide,
          lastStrokeDirection: this.lastStrokeDirection,
          sameSideStreak: this.sameSideStreak,
          capsizing: this.capsizing,
          boundaryBlocked: this.kayakBoundaryBlocked,
          boundaryBlockCount: this.boundaryBlockCount,
          boundaryHeadingAtBlock: Number(this.boundaryHeadingAtBlock.toFixed(3)),
          boundaryRollAtBlock: Number(this.boundaryRollAtBlock.toFixed(3)),
          collisionResponse: "stop_preserve_heading_allow_reverse"
        },
        reflectionLocationObserved: runtime.reflectionLocationObserved,
        directPaperCastFailures: runtime.directPaperCastFailures,
        chain: {
          rodFound: runtime.rodFound,
          decoyBaitAttached: runtime.decoyBaitAttached,
          lockerOpened: runtime.lockerOpened,
          netCombined: runtime.netCombined,
          feedTinRetrieved: runtime.feedTinRetrieved,
          feedTinOpened: runtime.feedTinOpened,
          fishCaught: runtime.fishCaught,
          swanFed: runtime.swanFed,
          magneticRodCombined: runtime.magneticRodCombined,
          paperCaptured: runtime.paperCaptured
        },
        fishing: {
          state: this.fishingActiveAttempt
            ? this.fishingResolving ? "resolving" : "running"
            : this.fishingPendingAttempt ? "prechecking" : "idle",
          sessionId: this.fishingActiveAttempt?.sessionId ?? this.fishingPendingAttempt?.sessionId ?? null,
          spotId: this.fishingActiveAttempt?.spotId ?? this.fishingPendingAttempt?.spotId ?? null,
          elapsedSeconds: Number((this.fishingModel?.elapsedSec ?? 0).toFixed(3)),
          tension: Math.round(this.fishingModel?.tension ?? 50),
          judged: this.fishingModel?.judgedCount ?? 0,
          totalNotes: this.fishingModel?.totalNotes ?? 0,
          assist: this.fishingModel?.assist ?? false,
          failureCounts: { ...this.fishingFailureCounts },
          clock: this.fishingUsesAudioClock ? "audio_context" : "performance_fallback"
        },
        chase: {
          active: runtime.phase === "swan_chase",
          distance: Math.max(runtime.chaseDistance, Math.round(this.chaseStartX - this.player.x)),
          finishX: SWAN_CHASE_FINISH_X,
          reachedFinish: this.player.x <= SWAN_CHASE_FINISH_X,
          completing: this.chaseCompleting,
          failing: this.chaseFailing,
          elapsedSeconds: Number(this.chaseElapsedSeconds.toFixed(2)),
          intensity: Number(this.chaseIntensity.toFixed(3)),
          actualGap: Number(this.chaseActualGap.toFixed(1)),
          catchDistance: SWAN_CHASE_CATCH_DISTANCE,
          catchReady: this.chaseElapsedSeconds >= SWAN_CHASE_GRACE_SECONDS,
          swanSpeed: Number(this.chaseSwanSpeed.toFixed(1)),
          speedRule: "far_faster_near_slower",
          swanX: Math.round(this.chaseSwanX),
          swanY: Math.round(this.chaseSwanY)
        },
        photoCamera: {
          resolvedSpotId: photoSpotId,
          standAreaHit: photoSpotId !== null,
          speed: Math.round(this.kayakSpeed),
          roll: Number(this.kayakRoll.toFixed(3)),
          sessionOpen: this.photoSessionOpen,
          sessionSpotId: this.photoSessionSpotId,
          lastSessionRequest: this.lastPhotoSessionRequest
        },
        activeOcclusionIds: this.activeOcclusionIds,
        softenedOcclusionIds: this.softenedOcclusionIds
      }
    } as unknown as Parameters<typeof setRpgRuntimeDebugState>[0]);
  }

  private getSpawn(
    zone: QizhenLakeZoneId,
    vehicle: QizhenLakeVehicle,
    fromZone: QizhenLakeZoneId | null
  ): { x: number; y: number } | { x: number; y: number; heading: number } {
    const definition = QIZHEN_LAKE_ZONES[zone];
    if (vehicle === "on_foot") return definition.onFootSpawn;
    if (fromZone && definition.kayakEntrySpawns[fromZone]) return definition.kayakEntrySpawns[fromZone]!;
    return definition.kayakSpawn;
  }

  private getInitialSpawn(
    runtime: QizhenRuntimeProjection
  ): { x: number; y: number } | { x: number; y: number; heading: number } {
    const rhythmSpawns: Readonly<Record<string, { x: number; y: number; heading: number }>> = {
      rhythm_locker_key: { x: 895, y: 620, heading: 0 },
      rhythm_net_frame: { x: 910, y: 515, heading: -Math.PI / 2 },
      rhythm_fish: { x: 705, y: 740, heading: -Math.PI / 2 },
      rhythm_paper: { x: 760, y: 615, heading: -Math.PI / 2 }
    };
    const developerRhythmSpawn = window.sessionStorage.getItem(DEVELOPER_QIZHEN_RHYTHM_SPAWN_KEY);
    const rhythmSpawnId = developerRhythmSpawn === "key"
      ? "rhythm_locker_key"
      : developerRhythmSpawn === "net"
        ? "rhythm_net_frame"
        : developerRhythmSpawn === "fish"
          ? "rhythm_fish"
          : developerRhythmSpawn === "paper"
            ? "rhythm_paper"
            : "";
    return rhythmSpawns[rhythmSpawnId]
      ?? this.getSpawn(runtime.zone, runtime.vehicle, null);
  }

  private playRainRescueSequence(): void {
    if (this.rainRescueAnimating || this.currentZone !== "dock") return;
    this.rainRescueAnimating = true;
    this.dialogueLocked = true;
    this.player.setVelocity(0, 0);
    this.showFeedback(qizhenContent.dock.forcedLaunch, "narrator", 1100);

    const splashX = 728;
    const splashY = 626;
    this.tweens.add({
      targets: this.player,
      x: splashX,
      y: splashY,
      duration: this.reducedMotion ? 160 : 620,
      ease: "Sine.easeIn",
      onComplete: () => {
        const splashes: Phaser.GameObjects.GameObject[] = [];
        for (let index = 0; index < 4; index += 1) {
          const ring = this.add.ellipse(
            splashX + (index - 1.5) * 12,
            splashY + (index % 2 === 0 ? -6 : 7),
            28 + index * 12,
            12 + index * 4,
            0x9bdff5,
            0.62
          ).setStrokeStyle(3, 0xe1f8ff, 0.88).setDepth(splashY + 210 + index);
          splashes.push(ring);
          this.tweens.add({
            targets: ring,
            scaleX: 1.7,
            scaleY: 1.55,
            alpha: 0,
            duration: this.reducedMotion ? 220 : 780,
            delay: index * 70,
            onComplete: () => ring.destroy()
          });
        }
        if (!this.reducedMotion) this.cameras.main.shake(260, 0.008);
        this.showFeedback(qizhenContent.dock.forcedCapsize, "system", 1500);
        this.tweens.add({
          targets: this.player,
          angle: 72,
          alpha: 0.22,
          duration: this.reducedMotion ? 180 : 520,
          yoyo: true,
          hold: this.reducedMotion ? 80 : 320,
          onComplete: () => {
            this.player.setAngle(0).setAlpha(1);
            splashes.forEach((splash) => splash.destroy());
          }
        });
      }
    });

    this.time.delayedCall(this.reducedMotion ? 520 : 1680, () => {
      this.showFeedback(qizhenContent.dock.forcedRescue, "narrator", 1900);
    });
    this.time.delayedCall(this.reducedMotion ? 1250 : 3150, () => {
      this.player.setAngle(0).setAlpha(1);
      this.emitDomain("rpg_qizhen_rain_rescue_completed_requested", {
        zone: "dock",
        reason: "forced_launch_capsize"
      });
    });
  }

  private emitDomain(name: string, payload?: Record<string, unknown>): void {
    this.bridge.emit(name, payload);
  }
}

function hasItem(state: GameState, itemId: ItemId): boolean {
  return Boolean((state.items as unknown as Record<string, boolean>)[itemId]);
}

function readQizhenRuntime(state: GameState): QizhenRuntimeProjection {
  const source = state.qizhenLake as unknown as Partial<QizhenRuntimeProjection> & {
    phase: QizhenRuntimePhase;
    mode: QizhenLakeMode;
  };
  const zone = isQizhenZone(source.zone) ? source.zone : "dock";
  const vehicle = source.vehicle === "kayak" ? "kayak" : "on_foot";
  return {
    phase: source.phase,
    mode: source.mode,
    zone,
    vehicle,
    introSeen: source.introSeen === true,
    kayakEquipped: source.kayakEquipped === true,
    leftPaddleEquipped: source.leftPaddleEquipped === true,
    rightPaddleEquipped: source.rightPaddleEquipped === true,
    rainSafetyCleared: source.rainSafetyCleared === true,
    boardingStrokeCount: finiteCount(source.boardingStrokeCount),
    boardingLastSide: source.boardingLastSide === "left" || source.boardingLastSide === "right"
      ? source.boardingLastSide
      : null,
    boardingTutorialCompleted: source.boardingTutorialCompleted === true,
    capsizeCount: finiteCount(source.capsizeCount),
    rodFound: source.rodFound === true,
    decoyBaitAttached: source.decoyBaitAttached === true,
    reflectionLocationObserved: source.reflectionLocationObserved === true,
    observedFishingSpotIds: Array.isArray(source.observedFishingSpotIds)
      ? source.observedFishingSpotIds.map(String)
      : [],
    directPaperCastFailures: finiteCount(source.directPaperCastFailures),
    lockerOpened: source.lockerOpened === true,
    netCombined: source.netCombined === true,
    feedTinRetrieved: source.feedTinRetrieved === true,
    feedTinOpened: source.feedTinOpened === true,
    fishCaught: source.fishCaught === true,
    swanFed: source.swanFed === true,
    magneticRodCombined: source.magneticRodCombined === true,
    paperCaptured: source.paperCaptured === true,
    swanReleased: source.swanReleased === true,
    chaseDistance: finiteCount(source.chaseDistance),
    chaseBestDistance: finiteCount(source.chaseBestDistance),
    chaseAttempts: finiteCount(source.chaseAttempts),
    magneticAttachmentBroken: source.magneticAttachmentBroken === true,
    transitionReady: source.transitionReady === true,
    safeSpawnId: typeof source.safeSpawnId === "string" ? source.safeSpawnId : "qizhen_dock_board"
  };
}

function isQizhenZone(value: unknown): value is QizhenLakeZoneId {
  return value === "dock" || value === "open_water" || value === "channel" || value === "swan_cove";
}

function finiteCount(value: unknown): number {
  const parsed = Number(value);
  return Number.isFinite(parsed) && parsed >= 0 ? parsed : 0;
}
