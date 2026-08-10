import Phaser from "phaser";
import qizhenChannelUrl from "../../assets/rpg/interiors/qizhen_lake_channel.png";
import qizhenDockUrl from "../../assets/rpg/interiors/qizhen_lake_dock.png";
import qizhenDockNoSignUrl from "../../assets/rpg/interiors/qizhen_lake_dock_no_sign.png";
import qizhenOpenWaterUrl from "../../assets/rpg/interiors/qizhen_lake_open_water.png";
import qizhenSwanCoveUrl from "../../assets/rpg/interiors/qizhen_lake_swan_cove.png";
import qizhenContent from "../../data/chapter3-qizhen-lake.content.json";
import type { GameSubtitleTone } from "../../components/GameSubtitleFrame";
import type { GameState, ItemId, QizhenLakeMode, QizhenPaddleDirection } from "../../core/types";
import type { RpgBridge } from "./RpgBridge";
import { formatRpgDragHint, formatRpgInteractionHint } from "./RpgControlHints";
import { RPG_HUD_LAYOUT } from "./RpgHudLayout";
import {
  formatRpgModeRequirement,
  getRpgDropBounds,
  isFacingVectorTowardRpgTarget,
  isPlayerFacingRpgTarget,
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
import { subscribeRpgSceneBridge } from "./RpgSceneBridgeSubscription";
import {
  QIZHEN_LAKE_TARGETS,
  QIZHEN_LAKE_WORLD,
  QIZHEN_LAKE_ZONES,
  clampKayakToWater,
  findNearestQizhenTarget,
  qizhenTargetAcceptsItem,
  targetsForQizhenZone,
  type QizhenLakeInteractionTarget,
  type QizhenLakeOcclusionRect,
  type QizhenLakeVehicle,
  type QizhenLakeZoneId
} from "./QizhenLakeModel";
import {
  createQizhenBlackSwanVisual,
  preloadQizhenKayakTextures,
  QizhenKayakVisual,
  type QizhenBlackSwanVisual,
  type QizhenPaddleSide
} from "./QizhenKayakTextures";

const ZONE_TEXTURE_KEYS: Readonly<Record<QizhenLakeZoneId, string>> = {
  dock: "chapter-3-qizhen-dock",
  open_water: "chapter-3-qizhen-open-water",
  channel: "chapter-3-qizhen-channel",
  swan_cove: "chapter-3-qizhen-swan-cove"
};
const DOCK_NO_SIGN_TEXTURE_KEY = "chapter-3-qizhen-dock-no-sign";

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

type QizhenRuntimePhase =
  | "inactive"
  | "location_search"
  | "lake_unlocked"
  | "dock_outfitting"
  | "boarding_tutorial"
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
}

interface DropGuideVisual {
  target: QizhenLakeInteractionTarget;
  targetOutline: Phaser.GameObjects.Rectangle;
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
  private keys!: Record<"W" | "A" | "S" | "D" | "SHIFT" | "TAB", Phaser.Input.Keyboard.Key>;

  private currentZone: QizhenLakeZoneId = "dock";
  private currentVehicle: QizhenLakeVehicle = "on_foot";
  private currentPhase: QizhenRuntimePhase = "dock_outfitting";
  private currentMode: QizhenLakeMode = "light";
  private currentDockSignRemoved = false;
  private virtualDirection = { x: 0, y: 0 };
  private lastVirtualPaddleX = 0;
  private virtualReverseHeld = false;
  private reverseInputHeld = false;
  private interactRequested = false;
  private dialogueLocked = false;
  private zoneTransitioning = false;
  private capsizing = false;
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
    this.strokeIndex = runtime.boardingStrokeCount;
    this.lastStrokeSide = runtime.boardingLastSide;
    this.reducedMotion = window.matchMedia?.("(prefers-reduced-motion: reduce)").matches === true;

    this.cameras.main.setBackgroundColor(0x031722);
    this.physics.world.setBounds(0, 0, QIZHEN_LAKE_WORLD.width, QIZHEN_LAKE_WORLD.height);
    this.obstacles = this.physics.add.staticGroup();
    this.mapImage = this.add.image(0, 0, this.getZoneTextureKey(this.currentZone)).setOrigin(0).setDepth(-1000);

    ensureRpgPlayerTextures(this);
    const spawn = this.getSpawn(this.currentZone, this.currentVehicle, null);
    this.player = this.physics.add.sprite(spawn.x, spawn.y, "act1-player-up-0");
    if ("heading" in spawn) this.kayakHeading = spawn.heading;
    this.player.setCollideWorldBounds(true).setDepth(spawn.y + 120);
    configureRpgPlayerSprite(this.player);
    this.playerAnimator = new RpgPlayerAnimator(this.player, "up");
    this.playerCollider = this.physics.add.collider(this.player, this.obstacles);
    this.kayak = new QizhenKayakVisual(this);

    this.cursors = this.input.keyboard!.createCursorKeys();
    this.keys = this.input.keyboard!.addKeys("W,A,S,D,SHIFT,TAB") as Record<
      "W" | "A" | "S" | "D" | "SHIFT" | "TAB",
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

    this.cameras.main
      .setBounds(0, 0, QIZHEN_LAKE_WORLD.width, QIZHEN_LAKE_WORLD.height)
      .setZoom(1)
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

    this.rebuildZone(this.currentZone, this.currentVehicle, null, false);
    this.applyVehicle(this.currentVehicle, false);

    subscribeRpgSceneBridge(
      this.events,
      this.bridge,
      (event) => this.handleBridgeEvent(event.name, event.payload),
      clearRpgRuntimeDebugState
    );
    if (runtime.zone === "dock" && runtime.mode !== "light") {
      this.emitDomain("rpg_qizhen_mode_requested", {
        mode: "light",
        reason: "dock_restore"
      });
    }
    this.events.once(Phaser.Scenes.Events.SHUTDOWN, () => {
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
    this.emitDomain("qizhen_lake_opened", {
      phase: this.currentPhase,
      zone: this.currentZone,
      vehicle: this.currentVehicle
    });
    if (!runtime.introSeen && runtime.phase === "dock_outfitting") {
      this.queueDialogue([
        ...qizhenContent.dock.intro,
        qizhenContent.dock.outfitPrompt
      ], () => this.emitDomain("rpg_qizhen_intro_seen_requested"));
    } else {
      this.maybePlayReflectionDialogue();
    }
  }

  update(_time: number, delta: number): void {
    const state = this.bridge.getState();
    const runtime = readQizhenRuntime(state);
    this.syncState(runtime);

    if (Phaser.Input.Keyboard.JustDown(this.keys.TAB) && !this.dialogueLocked && !this.zoneTransitioning) {
      if (runtime.phase === "swan_chase" || runtime.phase === "complete") {
        this.showFeedback(qizhenContent.mist.modeLocked, "system");
      } else {
        this.emitDomain("rpg_qizhen_mode_requested", {
          mode: runtime.mode === "dark" ? "light" : "dark"
        });
      }
    }

    if (this.currentVehicle === "kayak") {
      this.updateKayakInput(runtime);
      this.updateKayakMotion(delta / 1000, runtime);
    } else {
      this.updateOnFootMovement(state);
    }

    this.updateOcclusion();
    const targets = this.getActiveTargets(state, runtime);
    const nearest = findNearestQizhenTarget(this.player.x, this.player.y, targets);
    this.updateTargetVisuals(targets, nearest, state, runtime);
    this.updatePrompt(nearest, runtime);
    this.updateStatus(runtime);
    this.updateLockedPortalHint(targets, runtime);
    this.publishDebugState(nearest, targets, runtime);

    const keyboardInteract = Phaser.Input.Keyboard.JustDown(this.cursors.space);
    if (
      nearest
      && !this.dialogueLocked
      && !this.zoneTransitioning
      && !this.capsizing
      && (keyboardInteract || this.interactRequested)
    ) {
      if (this.isFacingTarget(nearest)) {
        this.triggerTarget(nearest, state, runtime);
      } else {
        this.showFeedback(`面向「${nearest.label}」后再操作。`, "task");
      }
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
    if (state.actOne.movementEnabled && !this.dialogueLocked && !this.zoneTransitioning && vector.lengthSq() > 0) {
      vector.normalize().scale(this.keys.SHIFT.isDown ? RUN_SPEED : WALK_SPEED);
    } else {
      vector.set(0, 0);
    }
    this.player.setVelocity(vector.x, vector.y).setDepth(this.player.y + 120);
    this.playerAnimator.update(vector, this.time.now);
  }

  private updateKayakInput(runtime: QizhenRuntimeProjection): void {
    this.reverseInputHeld = this.cursors.down.isDown || this.keys.S.isDown || this.virtualReverseHeld;
    if (this.dialogueLocked || this.zoneTransitioning || this.capsizing) return;
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
    this.chaseFailing = false;
    this.chaseSwanSpeed = 0;
    this.chaseActualGap = SWAN_CHASE_INITIAL_GAP;
    this.boundaryBlockedHintAt = Number.NEGATIVE_INFINITY;
    this.kayakBoundaryBlocked = false;
    this.boundaryBlockCount = 0;
    this.boundaryHeadingAtBlock = this.kayakHeading;
    this.boundaryRollAtBlock = 0;
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
      this.showFeedback(qizhenContent.boarding.boundaryBlocked, "task", 2200);
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
      this.showFeedback(qizhenContent.chase.finishReached, "success");
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
    this.showFeedback(qizhenContent.chase.caught, "system", 3000);
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
      this.showFeedback(qizhenContent.chase.failed, "task", 2200);
    });
  }

  private triggerCapsize(reason: "same_side_strokes", runtime: QizhenRuntimeProjection): void {
    if (this.capsizing) return;
    this.capsizing = true;
    this.kayakSpeed = 0;
    this.player.setVelocity(0, 0);
    this.emitDomain("rpg_qizhen_capsized", {
      zone: this.currentZone,
      reason,
      count: runtime.capsizeCount + 1,
      safeSpawnId: runtime.safeSpawnId
    });
    this.showFeedback(
      runtime.phase === "swan_chase"
        ? `${qizhenContent.boarding.capsizeSameSide}${qizhenContent.chase.failed}`
        : qizhenContent.boarding.capsizeSameSide,
      "system"
    );
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
        this.time.delayedCall(1500, () => this.showFeedback(qizhenContent.chase.instruction, "task"));
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
    const bands: ReadonlyArray<readonly [number, number, number]> = this.currentZone === "channel"
      ? [[330, 340, 110], [930, 600, 150], [1320, 390, 94]]
      : this.currentZone === "swan_cove"
        ? [[380, 360, 120], [735, 610, 156], [1180, 650, 96]]
        : this.currentZone === "dock"
          ? [[930, 290, 145], [1220, 540, 118], [1480, 340, 84]]
          : [[560, 500, 130], [915, 350, 180], [1320, 620, 112]];
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

  private createTargetVisuals(): void {
    QIZHEN_LAKE_TARGETS.filter((target) => target.zone === this.currentZone).forEach((target) => {
      const isOutfit = target.kind === "outfit";
      const color = target.kind === "zone_portal" || target.kind === "escape"
        ? 0xffe36d
        : target.kind === "reflection" || target.kind === "paper"
          ? 0x7de8ff
          : target.kind === "swan"
            ? 0xffd1a4
            : 0xb8ffd7;
      const pulse = target.kind === "zone_portal" || target.kind === "escape"
        ? this.add.triangle(0, 0, -22, -18, 24, 0, -22, 18, color, 0.25).setStrokeStyle(3, color, 0.88)
        : isOutfit
          ? this.add.ellipse(0, 0, 64, 30, color, 0.1).setStrokeStyle(3, color, 0.9)
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
      const prop = this.createDockOutfitProp(target);
      const rootChildren: Phaser.GameObjects.GameObject[] = prop
        ? [prop, pulse, label, ...sparkles]
        : [pulse, label, ...sparkles];
      const root = this.add.container(target.x, target.y, rootChildren)
        .setDepth(target.y + 48)
        .setSize(Math.max(88, target.dropWidth ?? 88), Math.max(64, target.dropHeight ?? 64))
        .setInteractive({ useHandCursor: true })
        .setVisible(false)
        .setName("qizhenTarget");
      root.setData("targetId", target.id);
      root.on("pointerdown", () => this.triggerPointerTarget(target));
      this.targetVisuals.push({ target, root, label, pulse, color, sparkles });
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
    this.targetVisuals.forEach(({ root, pulse, sparkles }) => {
      this.tweens.killTweensOf(root);
      this.tweens.killTweensOf(pulse);
      sparkles.forEach((sparkle) => this.tweens.killTweensOf(sparkle));
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
    return targetsForQizhenZone(this.currentZone, this.currentVehicle).filter((target) => {
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
        if (target.id === "qizhen_open_to_swan") return runtime.fishCaught || runtime.phase === "swan_exchange";
        if (target.id === "qizhen_open_to_channel") {
          return runtime.netCombined && !runtime.feedTinOpened && runtime.phase !== "swan_chase";
        }
        if (target.id === "qizhen_swan_to_open") return runtime.phase !== "swan_chase" && !runtime.paperCaptured;
        if (target.id === "qizhen_swan_to_channel") return runtime.phase === "swan_chase" || runtime.swanReleased;
        if (target.id === "qizhen_channel_from_swan") return false;
        if (target.id === "qizhen_channel_to_open") return runtime.phase !== "swan_chase" && runtime.feedTinOpened;
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
          return runtime.reflectionLocationObserved && !runtime.rodFound;
        }
        if (target.value === "item_1") {
          return runtime.rodFound
            && runtime.decoyBaitAttached
            && runtime.observedFishingSpotIds.includes("locker_key")
            && !hasItem(state, CHAIN_ITEMS.key)
            && !runtime.lockerOpened;
        }
        if (target.value === "item_3") {
          return runtime.lockerOpened
            && runtime.observedFishingSpotIds.includes("net_frame")
            && !hasItem(state, CHAIN_ITEMS.netFrame)
            && !runtime.netCombined;
        }
        if (target.value === "fish") {
          return runtime.feedTinOpened
            && runtime.observedFishingSpotIds.includes("fish")
            && !runtime.fishCaught;
        }
        return false;
      }
      if (target.kind === "item_use") {
        if (runtime.mode !== "light") return false;
        if (target.value === "item_1_to_2") return hasItem(state, CHAIN_ITEMS.key) && !runtime.lockerOpened;
        if (target.value === "combine_net") {
          return hasItem(state, CHAIN_ITEMS.cord) && hasItem(state, CHAIN_ITEMS.netFrame) && !runtime.netCombined;
        }
        if (target.value === "item_4_to_5") return runtime.netCombined && !runtime.feedTinRetrieved;
        if (target.value === "item_5_to_6") return runtime.feedTinRetrieved && !runtime.feedTinOpened;
        if (target.value === "combine_magnetic_rod") {
          return runtime.swanFed && hasItem(state, CHAIN_ITEMS.magnet) && !runtime.magneticRodCombined;
        }
        return false;
      }
      if (target.kind === "swan") {
        return runtime.mode === "light" && runtime.fishCaught && !runtime.swanFed;
      }
      if (target.kind === "paper") {
        if (runtime.mode !== "light") return false;
        if (target.value === "paper_reflection") {
          return runtime.rodFound
            && runtime.observedFishingSpotIds.includes("paper")
            && !runtime.paperCaptured;
        }
        return runtime.magneticRodCombined
          && runtime.observedFishingSpotIds.includes("paper")
          && !runtime.paperCaptured;
      }
      if (target.kind === "escape") return runtime.phase === "swan_chase";
      return true;
    });
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
      this.emitDomain("rpg_qizhen_fish_requested", { targetId: target.id, itemId });
      this.animateFishingCast(target, true);
      return;
    }
    if (target.kind === "item_use") {
      if (target.value === "combine_net") {
        this.emitDomain("rpg_qizhen_combine_requested", {
          itemIds: [CHAIN_ITEMS.cord, CHAIN_ITEMS.netFrame],
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
      this.emitDomain("rpg_qizhen_swan_feed_requested", { itemId: CHAIN_ITEMS.fish, targetId: target.id });
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
      this.emitDomain("rpg_qizhen_paper_caught_requested", {
        rigItemId: CHAIN_ITEMS.magneticRod,
        targetId: target.id
      });
      this.animateFishingCast(target, true);
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
    if (this.dialogueLocked || this.zoneTransitioning || this.capsizing) return;
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
    if (!this.isFacingTarget(target)) {
      this.showFeedback(`面向「${target.label}」后再操作。`, "system");
      return;
    }
    this.triggerTarget(target, state, runtime);
  }

  private isFacingTarget(target: QizhenLakeInteractionTarget): boolean {
    if (this.currentVehicle === "kayak") {
      return isFacingVectorTowardRpgTarget(
        target,
        this.player.x,
        this.player.y,
        { x: Math.cos(this.kayakHeading), y: Math.sin(this.kayakHeading) }
      );
    }
    return isPlayerFacingRpgTarget(
      target,
      this.player.x,
      this.player.y,
      this.playerAnimator.cardinalFacing
    );
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
    if (!this.isFacingTarget(target)) {
      this.emitDropFailure(
        itemId,
        "wrong_facing",
        target.label,
        `靠近并面向「${target.label}」后再操作。`
      );
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
        this.emitDomain("rpg_qizhen_fish_requested", { targetId: target.id, itemId });
        this.animateFishingCast(target, true);
        return;
      }
      if (["item_1", "item_3"].includes(String(target.value)) && itemId === CHAIN_ITEMS.fishingRod) {
        this.emitDomain("rpg_qizhen_fish_requested", { targetId: target.id, itemId });
        this.animateFishingCast(target, true);
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
    if (target.value === "combine_net" && [CHAIN_ITEMS.cord, CHAIN_ITEMS.netFrame].includes(itemId as never)) {
      this.emitDomain("rpg_qizhen_combine_requested", {
        itemIds: [CHAIN_ITEMS.cord, CHAIN_ITEMS.netFrame],
        targetId: target.id
      });
      return;
    }
    if (target.kind === "swan" && itemId === CHAIN_ITEMS.fish) {
      this.emitDomain("rpg_qizhen_swan_feed_requested", { itemId, targetId: target.id });
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
      this.emitDomain("rpg_qizhen_paper_caught_requested", { rigItemId: itemId, targetId: target.id });
      this.animateFishingCast(target, true);
      return;
    }
    this.emitDropFailure(itemId, "wrong_item", target.label, this.dropCorrectionFor(target));
  }

  private handleBridgeEvent(name: string, payload?: Record<string, unknown>): void {
    if (!this.sys?.isActive()) return;
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
      this.playModeTransition(
        String(payload?.mode) === "dark" ? "dark" : "light",
        typeof payload?.reason === "string" ? payload.reason : undefined
      );
      return;
    }
    if (name === "qizhen_outfit_part_collected") {
      const part = String(payload?.part ?? "kayak");
      const complete = payload?.complete === true;
      const message = complete
        ? qizhenContent.dock.outfitComplete
        : part === "kayak"
          ? qizhenContent.dock.kayakCollected
          : part === "left_paddle"
            ? qizhenContent.dock.leftPaddleCollected
            : qizhenContent.dock.rightPaddleCollected;
      this.showFeedback(message, "success");
      return;
    }
    if (name === "qizhen_kayak_boarded") {
      this.showFeedback(qizhenContent.boarding.start, "task");
      return;
    }
    if (name === "qizhen_boarding_stroke_recorded") {
      const count = Number(payload?.count) || 0;
      if (String(payload?.direction ?? "forward") === "reverse") {
        this.showFeedback(qizhenContent.boarding.reverseTutorial, "task", 1800);
      } else if (payload?.alternating === true && count >= 1) {
        const strokes = qizhenContent.boarding.strokes;
        const line = strokes[Math.min(count, strokes.length) - 1];
        this.showFeedback(line, this.dialogueToneFor(line), 1500);
      } else if (payload?.alternating !== true && this.time.now - this.sameSideHintAt > SAME_SIDE_HINT_COOLDOWN_MS) {
        this.sameSideHintAt = this.time.now;
        this.showFeedback(qizhenContent.boarding.sameSide, "system", 1800);
      }
      return;
    }
    if (name === "qizhen_boarding_completed") {
      this.showFeedback(qizhenContent.boarding.complete, "success");
      return;
    }
    if (name === "qizhen_reflection_observed") {
      if (String(payload?.spotId ?? "") === "paper") {
        this.playSubtitleSequence(qizhenContent.reflection.afterPaper);
      } else {
        this.showFeedback(qizhenContent.reflection.correct, "success");
      }
      return;
    }
    if (name === "qizhen_fishing_rod_found") {
      this.queueDialogue([qizhenContent.lake.rodFound, ...qizhenContent.decoy.dialogue]);
      return;
    }
    if (name === "qizhen_decoy_bait_attached") {
      this.playSubtitleSequence([qizhenContent.decoy.correct, qizhenContent.lake.baitNext]);
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
      this.queueDialogue([qizhenContent.swan.reward, qizhenContent.swan.combineHint]);
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
    const activeIds = new Set(targets.map((target) => target.id));
    const selectedItem = state.ui.selectedItem;
    this.targetVisuals.forEach((visual) => {
      const active = activeIds.has(visual.target.id);
      const vehicleMatches = !visual.target.vehicle || visual.target.vehicle === this.currentVehicle;
      const lockedPortal = !active && vehicleMatches && this.lockedPortalHintFor(visual.target, runtime) !== null;
      visual.root.setVisible(active || lockedPortal);
      visual.sparkles.forEach((sparkle) => sparkle.setVisible(active));
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
      visual.label.setVisible(false);
      visual.pulse
        .setAlpha(isNearest || matchesSelectedItem ? 0.96 : 0.5)
        .setStrokeStyle(3, matchesSelectedItem ? 0x63e58b : visual.color, matchesSelectedItem ? 1 : 0.88);
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
    const activeIds = new Set(targets.map((target) => target.id));
    this.dropGuides.forEach((guide) => {
      const matches = selectedItem !== null && qizhenTargetAcceptsItem(guide.target, selectedItem);
      const visible = activeIds.has(guide.target.id) && matches;
      guide.targetOutline.setVisible(visible);
      if (!visible) return;
      const ready = isPlayerWithinRpgTarget(guide.target, this.player.x, this.player.y)
        && this.isFacingTarget(guide.target);
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
    if (!target || this.dialogueLocked || this.zoneTransitioning || this.capsizing) {
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
    const playerScreenY = (this.player.y - camera.worldView.y) * camera.zoom;
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

  private playModeTransition(mode: QizhenLakeMode, reason?: string): void {
    const changed = mode !== this.currentMode;
    this.currentMode = mode;
    this.tweens.killTweensOf(this.darkOverlay);
    this.tweens.add({
      targets: this.darkOverlay,
      alpha: mode === "dark" ? 0.66 : 0,
      duration: this.reducedMotion ? 60 : 260,
      ease: "Cubic.easeInOut"
    });
    if (!changed) return;
    const text = reason === "dock_return"
      ? qizhenContent.mist.lightPrompt
      : mode === "dark"
        ? qizhenContent.lake.darkPrompt
        : qizhenContent.lake.lightPrompt;
    this.showFeedback(text, "system", 2200);
  }

  private animateFishingCast(target: QizhenLakeInteractionTarget, splash: boolean): void {
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

  private playSubtitleSequence(lines: readonly string[], stepMs = 1500): void {
    lines.forEach((text, index) => {
      this.time.delayedCall(index * stepMs, () => {
        this.showFeedback(text, this.dialogueToneFor(text), stepMs - 120);
      });
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
    reason: "missed_target" | "wrong_item" | "too_far" | "wrong_facing" | "wrong_mode" | "locked",
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
        mode: "follow"
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
        requiredMode: candidate.requiredMode,
        requiredFacing: candidate.requiredFacing
      })),
      collisionRects: this.getActiveCollisionRects(this.currentVehicle),
      qizhenLake: {
        phase: runtime.phase,
        mode: runtime.mode,
        plate: this.currentZone,
        zone: this.currentZone,
        vehicle: this.currentVehicle,
        dockSignRemoved: this.currentDockSignRemoved,
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
