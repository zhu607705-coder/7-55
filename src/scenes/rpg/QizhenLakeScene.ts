import Phaser from "phaser";
import qizhenChannelUrl from "../../assets/rpg/interiors/qizhen_lake_channel.png";
import qizhenDockUrl from "../../assets/rpg/interiors/qizhen_lake_dock.png";
import qizhenOpenWaterUrl from "../../assets/rpg/interiors/qizhen_lake_open_water.png";
import qizhenSwanCoveUrl from "../../assets/rpg/interiors/qizhen_lake_swan_cove.png";
import type { GameState, ItemId, QizhenLakeMode } from "../../core/types";
import type { RpgBridge } from "./RpgBridge";
import { formatRpgDragHint, formatRpgInteractionHint } from "./RpgControlHints";
import { RPG_HUD_LAYOUT } from "./RpgHudLayout";
import {
  getRpgDropBounds,
  isPlayerWithinRpgTarget,
  isRpgDropPointWithin
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

const WALK_SPEED = 165;
const RUN_SPEED = 228;
const KAYAK_MAX_SPEED = 340;
const KAYAK_STROKE_SPEED = 104;
const KAYAK_SAME_SIDE_SPEED = 52;
const KAYAK_DRAG_PER_SECOND = 0.68;
const KAYAK_ROLL_DECAY_PER_SECOND = 1.05;
const KAYAK_TURN_PER_STROKE = 0.16;
const KAYAK_CAPSIZE_THRESHOLD = 0.92;
const KAYAK_COLLISION_CAPSIZE_SPEED = 270;
const SWAN_CHASE_START_SPEED = 212;
const SWAN_CHASE_END_SPEED = 286;
const SWAN_CHASE_START_GAP = 150;
const SWAN_CHASE_END_GAP = 40;
const SWAN_CHASE_PRESSURE_SECONDS = 5.5;
const SWAN_CATCH_DISTANCE = 66;
const FEEDBACK_MS = 2700;

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
  private virtualDirection = { x: 0, y: 0 };
  private lastVirtualPaddleX = 0;
  private interactRequested = false;
  private dialogueLocked = false;
  private zoneTransitioning = false;
  private capsizing = false;
  private reducedMotion = false;

  private targetVisuals: TargetVisual[] = [];
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
  private sameSideStreak = 0;
  private strokeIndex = 0;
  private lastStrokeAt = 0;
  private lastChaseProgressSent = 0;
  private chaseStartX = 0;
  private chaseElapsedSeconds = 0;
  private chaseDesiredGap = SWAN_CHASE_START_GAP;
  private chaseSwanX = 0;
  private chaseSwanY = 0;
  private chaseAnnounced = false;

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
    preloadQizhenKayakTextures(this);
    preloadRpgPlayerTextures(this);
  }

  create(): void {
    this.bridge = this.registry.get("rpgBridge") as RpgBridge;
    const state = this.bridge.getState();
    const runtime = readQizhenRuntime(state);
    this.currentZone = runtime.zone;
    this.currentVehicle = runtime.vehicle;
    this.currentPhase = runtime.phase;
    this.currentMode = runtime.mode;
    this.strokeIndex = runtime.boardingStrokeCount;
    this.lastStrokeSide = runtime.boardingLastSide;
    this.reducedMotion = window.matchMedia?.("(prefers-reduced-motion: reduce)").matches === true;

    this.cameras.main.setBackgroundColor(0x031722);
    this.physics.world.setBounds(0, 0, QIZHEN_LAKE_WORLD.width, QIZHEN_LAKE_WORLD.height);
    this.obstacles = this.physics.add.staticGroup();
    this.mapImage = this.add.image(0, 0, ZONE_TEXTURE_KEYS[this.currentZone]).setOrigin(0).setDepth(-1000);

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
      Phaser.Input.Keyboard.KeyCodes.A,
      Phaser.Input.Keyboard.KeyCodes.D
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
      backgroundColor: "#092432de",
      fontFamily: "monospace",
      fontSize: "13px",
      padding: { x: 9, y: 5 }
    }).setScrollFactor(0).setDepth(5200);
    this.statusText = this.add.text(18, 112, "", {
      color: "#fff2b6",
      backgroundColor: "#102334e8",
      fontFamily: "monospace",
      fontSize: "12px",
      padding: { x: 9, y: 5 }
    }).setScrollFactor(0).setDepth(5200);
    this.promptText = this.add.text(RPG_HUD_LAYOUT.centerX, RPG_HUD_LAYOUT.promptBottomY, "", {
      color: "#fff7df",
      backgroundColor: "#102334ee",
      fontFamily: "monospace",
      fontSize: "13px",
      padding: { x: 9, y: 5 }
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
        "任务：到小码头取皮划艇和两支临时船桨。",
        "系统：左右桨要交替划；连续划同一侧会偏航并增加侧倾。"
      ], () => this.emitDomain("rpg_qizhen_intro_seen_requested"));
    }
  }

  update(_time: number, delta: number): void {
    const state = this.bridge.getState();
    const runtime = readQizhenRuntime(state);
    this.syncState(runtime);

    if (Phaser.Input.Keyboard.JustDown(this.keys.TAB) && !this.dialogueLocked && !this.zoneTransitioning) {
      this.emitDomain("rpg_qizhen_mode_requested", {
        mode: runtime.mode === "dark" ? "light" : "dark"
      });
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
    this.updateTargetVisuals(targets, nearest, runtime);
    this.updatePrompt(nearest, runtime);
    this.updateStatus(runtime);
    this.publishDebugState(nearest, targets, runtime);

    const keyboardInteract = Phaser.Input.Keyboard.JustDown(this.cursors.space);
    if (
      nearest
      && !this.dialogueLocked
      && !this.zoneTransitioning
      && !this.capsizing
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
    if (state.actOne.movementEnabled && !this.dialogueLocked && !this.zoneTransitioning && vector.lengthSq() > 0) {
      vector.normalize().scale(this.keys.SHIFT.isDown ? RUN_SPEED : WALK_SPEED);
    } else {
      vector.set(0, 0);
    }
    this.player.setVelocity(vector.x, vector.y).setDepth(this.player.y + 120);
    this.playerAnimator.update(vector, this.time.now);
  }

  private updateKayakInput(runtime: QizhenRuntimeProjection): void {
    if (this.dialogueLocked || this.zoneTransitioning || this.capsizing) return;
    if (Phaser.Input.Keyboard.JustDown(this.cursors.left) || Phaser.Input.Keyboard.JustDown(this.keys.A)) {
      this.performPaddleStroke("left", runtime);
    }
    if (Phaser.Input.Keyboard.JustDown(this.cursors.right) || Phaser.Input.Keyboard.JustDown(this.keys.D)) {
      this.performPaddleStroke("right", runtime);
    }
  }

  private performPaddleStroke(
    side: QizhenPaddleSide,
    runtime: QizhenRuntimeProjection,
    emitIntent = true
  ): void {
    if (this.currentVehicle !== "kayak" || this.capsizing || this.zoneTransitioning) return;
    const now = this.time.now;
    const withinCadence = now - this.lastStrokeAt <= 1450;
    const alternating = withinCadence && this.lastStrokeSide !== null && this.lastStrokeSide !== side;
    const repeated = withinCadence && this.lastStrokeSide === side;
    this.sameSideStreak = repeated ? this.sameSideStreak + 1 : 1;
    this.strokeIndex += 1;

    if (alternating) {
      this.kayakSpeed = Math.min(KAYAK_MAX_SPEED, this.kayakSpeed + KAYAK_STROKE_SPEED);
      this.kayakRoll *= 0.36;
      this.sameSideStreak = 1;
    } else {
      this.kayakSpeed = Math.min(KAYAK_MAX_SPEED, this.kayakSpeed + KAYAK_SAME_SIDE_SPEED);
      const sideSign = side === "left" ? 1 : -1;
      this.kayakHeading += sideSign * (KAYAK_TURN_PER_STROKE + Math.min(0.13, this.sameSideStreak * 0.025));
      this.kayakRoll += sideSign * (0.23 + Math.min(0.18, this.sameSideStreak * 0.035));
    }

    this.lastStrokeAt = now;
    this.lastStrokeSide = side;
    this.kayak.stroke(side, repeated ? 1.2 : 1);
    if (emitIntent) {
      this.emitDomain("rpg_qizhen_paddle_requested", {
        side,
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
    this.kayakRoll *= Math.exp(-KAYAK_ROLL_DECAY_PER_SECOND * deltaSeconds);
    const velocityX = Math.cos(this.kayakHeading) * this.kayakSpeed;
    const velocityY = Math.sin(this.kayakHeading) * this.kayakSpeed;
    this.player.setVelocity(velocityX, velocityY).setDepth(this.player.y + 120);

    const water = clampKayakToWater(this.currentZone, this.player.x, this.player.y);
    if (!water.contained) {
      this.player.setPosition(water.x, water.y);
      this.kayakSpeed *= 0.42;
      this.kayakRoll += velocityX >= 0 ? 0.08 : -0.08;
    }

    const body = this.player.body as Phaser.Physics.Arcade.Body;
    const hitObstacle = body.blocked.left || body.blocked.right || body.blocked.up || body.blocked.down;
    if (hitObstacle) {
      const impactSpeed = Math.abs(this.kayakSpeed);
      this.kayakSpeed *= 0.34;
      this.kayakRoll += body.blocked.left || body.blocked.up ? 0.18 : -0.18;
      if (impactSpeed >= KAYAK_COLLISION_CAPSIZE_SPEED) {
        this.triggerCapsize("obstacle_impact", runtime);
      }
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

  private updateSwanChase(deltaSeconds: number, runtime: QizhenRuntimeProjection): void {
    if (!this.chaseSwan) this.createChaseSwan();
    this.chaseElapsedSeconds += deltaSeconds;
    const pressure = Phaser.Math.Clamp(
      this.chaseElapsedSeconds / SWAN_CHASE_PRESSURE_SECONDS,
      0,
      1
    );
    this.chaseDesiredGap = Phaser.Math.Linear(
      SWAN_CHASE_START_GAP,
      SWAN_CHASE_END_GAP,
      pressure
    );
    const pursuitSpeed = Phaser.Math.Linear(
      SWAN_CHASE_START_SPEED,
      SWAN_CHASE_END_SPEED,
      pressure
    );
    const desiredX = Math.min(
      QIZHEN_LAKE_WORLD.width - 70,
      this.player.x + this.chaseDesiredGap
    );
    const desiredY = this.player.y;
    const dx = desiredX - this.chaseSwanX;
    const dy = desiredY - this.chaseSwanY;
    const distanceToDesired = Math.hypot(dx, dy);
    if (distanceToDesired > 0.001) {
      const step = Math.min(distanceToDesired, pursuitSpeed * deltaSeconds);
      this.chaseSwanX += dx / distanceToDesired * step;
      this.chaseSwanY += dy / distanceToDesired * step;
    }
    const heading = Math.atan2(this.player.y - this.chaseSwanY, this.player.x - this.chaseSwanX);
    const beat = Math.sin(this.time.now / 90);
    this.chaseSwan?.update(this.chaseSwanX, this.chaseSwanY, heading, beat);

    const progress = Math.max(runtime.chaseDistance, this.chaseStartX - this.player.x);
    if (progress >= this.lastChaseProgressSent + 20) {
      this.lastChaseProgressSent = progress;
      this.emitDomain("rpg_qizhen_chase_progress", { distance: Math.round(progress), zone: "channel" });
    }
    if (Math.hypot(this.chaseSwanX - this.player.x, this.chaseSwanY - this.player.y) <= SWAN_CATCH_DISTANCE) {
      this.triggerCapsize("swan_hit", runtime);
    }
  }

  private triggerCapsize(reason: "same_side_strokes" | "obstacle_impact" | "swan_hit", runtime: QizhenRuntimeProjection): void {
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
      reason === "swan_hit"
        ? "黑天鹅撞上船尾。保持左右交替，重新拉开距离。"
        : reason === "obstacle_impact"
          ? "船身撞上障碍。减速后再调整朝向。"
          : "连续划同一侧导致翻船。左右交替可以稳住船身。",
      "system"
    );
    this.kayak.playCapsize(() => {
      const safe = this.getSpawn(this.currentZone, "kayak", null);
      this.player.setPosition(safe.x, safe.y).setVelocity(0, 0);
      this.kayakHeading = "heading" in safe ? safe.heading : -Math.PI / 2;
      this.kayakRoll = 0;
      this.sameSideStreak = 0;
      this.lastStrokeSide = null;
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
        this.showFeedback("围栏机关已被触发。黑天鹅进入直河道，立刻返航！", "task");
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
    });
  }

  private rebuildZone(
    zone: QizhenLakeZoneId,
    vehicle: QizhenLakeVehicle,
    fromZone: QizhenLakeZoneId | null,
    reposition: boolean
  ): void {
    this.mapImage.setTexture(ZONE_TEXTURE_KEYS[zone]);
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
    const definition = QIZHEN_LAKE_ZONES[this.currentZone];
    const collisions = vehicle === "kayak" ? definition.kayakCollisions : definition.onFootCollisions;
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

  private createOcclusionVisuals(): void {
    const textureKey = ZONE_TEXTURE_KEYS[this.currentZone];
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
      const color = target.kind === "zone_portal" || target.kind === "escape"
        ? 0xffe36d
        : target.kind === "reflection" || target.kind === "paper"
          ? 0x7de8ff
          : target.kind === "swan"
            ? 0xffd1a4
            : 0xb8ffd7;
      const pulse = target.kind === "zone_portal" || target.kind === "escape"
        ? this.add.triangle(0, 0, -22, -18, 24, 0, -22, 18, color, 0.25).setStrokeStyle(3, color, 0.88)
        : this.add.ellipse(0, 0, 72, 34, color, 0.08).setStrokeStyle(3, color, 0.82);
      const center = this.add.circle(0, 0, 5, color, 0.96);
      const label = this.add.text(0, -34, target.label, {
        color: "#f4ffff",
        backgroundColor: "#09212dda",
        fontFamily: "monospace",
        fontSize: "11px",
        padding: { x: 6, y: 3 }
      }).setOrigin(0.5, 1);
      const root = this.add.container(target.x, target.y, [pulse, center, label])
        .setDepth(target.y + 48)
        .setSize(Math.max(88, target.dropWidth ?? 88), Math.max(64, target.dropHeight ?? 64))
        .setInteractive({ useHandCursor: true })
        .setVisible(false)
        .setName("qizhenTarget");
      root.setData("targetId", target.id);
      root.on("pointerdown", () => this.triggerPointerTarget(target));
      if (!this.reducedMotion) {
        this.tweens.add({
          targets: pulse,
          scale: 1.18,
          alpha: { from: 0.38, to: 0.9 },
          duration: 1100,
          ease: "Sine.easeInOut",
          yoyo: true,
          repeat: -1,
          delay: target.x % 420
        });
      }
      this.targetVisuals.push({ target, root, label, pulse });
    });
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
    this.chaseDesiredGap = SWAN_CHASE_START_GAP;
    this.lastChaseProgressSent = 0;
    this.chaseSwanX = Math.min(QIZHEN_LAKE_WORLD.width - 70, this.player.x + 240);
    this.chaseSwanY = this.player.y;
    this.chaseSwan?.update(this.chaseSwanX, this.chaseSwanY, Math.PI, 0);
  }

  private destroyZoneVisuals(): void {
    this.targetVisuals.forEach(({ root }) => {
      this.tweens.killTweensOf(root);
      root.destroy(true);
    });
    this.targetVisuals = [];
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
      this.player.setVisible(false).setAlpha(0);
      body.setSize(76, 38, true);
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

  private getActiveTargets(state: GameState, runtime: QizhenRuntimeProjection): QizhenLakeInteractionTarget[] {
    return targetsForQizhenZone(this.currentZone, this.currentVehicle).filter((target) => {
      if (target.kind === "exit") return runtime.phase !== "swan_chase";
      if (target.kind === "outfit") {
        return !runtime.kayakEquipped || !runtime.leftPaddleEquipped || !runtime.rightPaddleEquipped;
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
    if (target.kind === "exit") {
      this.emitDomain("rpg_qizhen_leave_requested");
      return;
    }
    if (target.kind === "outfit") {
      this.emitDomain("rpg_qizhen_outfit_requested", { targetId: target.id });
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
    if (!this.getActiveTargets(state, runtime).some((candidate) => candidate.id === target.id)) return;
    if (!findNearestQizhenTarget(this.player.x, this.player.y, [target])) {
      this.emitDomain("rpg_item_use_feedback", {
        reason: "too_far",
        targetLabel: target.label,
        detail: "先把人物或皮划艇划到发光范围内。"
      });
      return;
    }
    this.triggerTarget(target, state, runtime);
  }

  private handleInventoryDrop(payload?: Record<string, unknown>): void {
    const itemId = String(payload?.itemId ?? "") as ItemId;
    const canvasX = Number(payload?.canvasX);
    const canvasY = Number(payload?.canvasY);
    if (!Number.isFinite(canvasX) || !Number.isFinite(canvasY)) {
      this.emitDropFailure(itemId, "missed_target", undefined, "拖到场景中明确标出的发光框内。");
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
      this.emitDropFailure(itemId, "missed_target", undefined, "没有命中当前可用目标，靠近后拖进发光框。");
      return;
    }
    if (runtime.mode !== "light") {
      this.emitDropFailure(itemId, "wrong_mode", target.label, "当前是深色观察，切到浅色操作后再使用实体道具。");
      return;
    }
    if (!isPlayerWithinRpgTarget(target, this.player.x, this.player.y)) {
      this.emitDropFailure(itemId, "too_far", target.label, "目标对了，先把皮划艇划进标记圈。 ");
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
        if (x < 0 && this.lastVirtualPaddleX >= 0) this.performPaddleStroke("left", readQizhenRuntime(this.bridge.getState()));
        if (x > 0 && this.lastVirtualPaddleX <= 0) this.performPaddleStroke("right", readQizhenRuntime(this.bridge.getState()));
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
      this.performPaddleStroke(side, readQizhenRuntime(this.bridge.getState()));
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
    if (name === "qizhen_outfit_collected") {
      this.showFeedback("皮划艇就绪：左桨是削去叶子的树枝，右桨是“禁止游泳”三角牌。", "success");
      return;
    }
    if (name === "qizhen_kayak_boarded") {
      this.showFeedback("上船阶段横向稳定性低。左右交替划四次，先把重心稳住。", "task");
      return;
    }
    if (name === "qizhen_boarding_completed") {
      this.showFeedback("船身稳定，可以划向大湖。", "success");
      return;
    }
    if (name === "qizhen_reflection_observed") {
      this.showFeedback("暗色倒影标出了真实水面的对应位置。切回浅色操作。", "task");
      return;
    }
    if (name === "qizhen_fishing_rod_found") {
      this.showFeedback("钓鱼竿已捞起。纸条本体现在还钓不上来。", "success");
      return;
    }
    if (name === "qizhen_decoy_bait_attached") {
      this.showFeedback("假纸条已经装成诱饵，去倒影对应的浅色水面抛竿。", "success");
      return;
    }
    if (name === "qizhen_direct_paper_cast_failed") {
      this.showFeedback("鱼钩穿过倒影，纸条没有实体响应。需要先完成水下道具链。", "system");
      return;
    }
    if (name === "qizhen_locker_opened") {
      this.showFeedback("码头储物柜打开，里面是一卷尼龙绳。", "success");
      return;
    }
    if (name === "qizhen_dip_net_combined") {
      this.showFeedback("尼龙绳已经固定到破损网框，临时抄网完成。去浮排下取密封盒。", "success");
      return;
    }
    if (name === "qizhen_feed_tin_retrieved") {
      this.showFeedback("临时抄网从浮排下捞出了密封饲料盒。", "success");
      return;
    }
    if (name === "qizhen_feed_tin_opened") {
      this.showFeedback("在浮排硬边撬开盒盖，得到鱼食颗粒。", "success");
      return;
    }
    if (name === "qizhen_fish_caught") {
      this.showFeedback("鱼食颗粒引来一条小鲤鱼。带去黑天鹅围栏。", "success");
      return;
    }
    if (name === "qizhen_swan_fed") {
      this.showFeedback("黑天鹅吞下小鲤鱼，推来一个磁吸配件。", "success");
      return;
    }
    if (name === "qizhen_magnetic_rod_combined") {
      this.showFeedback("磁吸钓竿组合完成，现在可以钓纸条本体。", "success");
      return;
    }
    if (name === "qizhen_paper_captured") {
      this.showFeedback("纸条被磁吸钓竿拉出水面，却悄悄拨开了围栏。", "system");
      return;
    }
    if (name === "qizhen_escape_completed") {
      this.showFeedback("已逃回小码头。磁吸配件损坏，纸条再次逃走。", "success");
    }
  }

  private updateTargetVisuals(
    targets: readonly QizhenLakeInteractionTarget[],
    nearest: QizhenLakeInteractionTarget | null,
    runtime: QizhenRuntimeProjection
  ): void {
    const activeIds = new Set(targets.map((target) => target.id));
    this.targetVisuals.forEach((visual) => {
      const active = activeIds.has(visual.target.id);
      visual.root.setVisible(active);
      if (!active) return;
      const distance = Math.hypot(this.player.x - visual.target.x, this.player.y - visual.target.y);
      const selected = nearest?.id === visual.target.id;
      visual.label.setVisible(!selected && distance <= Math.max(250, visual.target.proximity * 1.8));
      visual.pulse.setAlpha(selected ? 0.96 : 0.5);
      visual.root.setScale(selected ? 1.08 : 1);
      if ((visual.target.kind === "reflection" || visual.target.value === "paper_reflection") && runtime.mode !== "dark") {
        visual.root.setAlpha(0.38);
      } else {
        visual.root.setAlpha(1);
      }
    });
    this.staticSwan?.root.setVisible(this.currentZone === "swan_cove" && runtime.phase !== "swan_chase");
  }

  private updatePrompt(target: QizhenLakeInteractionTarget | null, runtime: QizhenRuntimeProjection): void {
    if (!target || this.dialogueLocked || this.zoneTransitioning || this.capsizing) {
      this.promptText.setVisible(false);
      return;
    }
    const action = target.kind === "outfit"
      ? "取皮划艇和船桨"
      : target.kind === "board"
        ? "从小码头上船"
        : target.kind === "zone_portal"
          ? target.label
          : target.kind === "reflection"
            ? "观察倒影位置"
            : target.kind === "fishing_spot"
              ? target.value === "fishing_rod" ? "捞起钓鱼竿" : "在对应位置抛竿"
              : target.kind === "item_use"
                ? target.label
                : target.kind === "swan"
                  ? "把小鲤鱼喂给黑天鹅"
                  : target.kind === "paper"
                    ? target.value === "paper_reflection" && !runtime.decoyBaitAttached
                      ? "直接抛竿会失败；拖入假纸条作饵"
                      : "使用当前钓具"
                    : target.kind === "escape"
                      ? "冲回小码头"
                      : "离开启真湖";
    const itemOnly = target.kind === "paper" && target.value === "paper_reflection" && !runtime.decoyBaitAttached;
    const camera = this.cameras.main;
    const playerScreenY = (this.player.y - camera.worldView.y) * camera.zoom;
    const promptY = Math.abs(playerScreenY - RPG_HUD_LAYOUT.promptBottomY) < 78
      ? Math.min(492, RPG_HUD_LAYOUT.promptBottomY + 70)
      : RPG_HUD_LAYOUT.promptBottomY;
    this.promptText
      .setY(promptY)
      .setText(itemOnly ? formatRpgDragHint(action) : formatRpgInteractionHint(action))
      .setVisible(true);
  }

  private updateStatus(runtime: QizhenRuntimeProjection): void {
    const zoneLabel = this.currentZone === "dock"
      ? "小码头"
      : this.currentZone === "open_water"
        ? "启真湖大湖面"
        : this.currentZone === "channel" ? "浮排直河道" : "黑天鹅围栏";
    this.zoneText.setText(`${zoneLabel} · ${runtime.mode === "dark" ? "深色观察" : "浅色操作"}`);
    if (this.currentVehicle === "kayak") {
      const tilt = Math.round(Math.min(1, Math.abs(this.kayakRoll)) * 100);
      const danger = tilt >= 70 ? " · 即将翻船" : "";
      this.statusText.setText(`A/← 左桨 · D/→ 右桨 · 侧倾 ${tilt}%${danger}`);
      this.statusText.setColor(tilt >= 70 ? "#ffaaa0" : "#fff2b6");
    } else if (!runtime.kayakEquipped) {
      this.statusText.setText("先到皮划艇架领取船和两支创意桨").setColor("#fff2b6");
    } else {
      this.statusText.setText("装备已取齐，走到小码头上船位").setColor("#fff2b6");
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

  private queueDialogue(lines: readonly string[], onComplete?: () => void): void {
    this.dialogueLocked = true;
    lines.forEach((text, index) => {
      this.time.delayedCall(index * FEEDBACK_MS, () => this.showFeedback(text, text.startsWith("任务：") ? "task" : "system"));
    });
    this.time.delayedCall(lines.length * FEEDBACK_MS, () => {
      this.dialogueLocked = false;
      onComplete?.();
    });
  }

  private showFeedback(text: string, tone: "system" | "task" | "success"): void {
    this.emitDomain("rpg_subtitle", { text, tone, durationMs: FEEDBACK_MS - 120 });
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
    if (target.value === "paper_reflection") return "先拖入假纸条当饵；直接用普通钓鱼竿只会穿过倒影。";
    if (target.value === "item_1_to_2") return "这里需要锈蚀储物柜钥匙。";
    if (target.value === "combine_net") return "把尼龙绳或破损抄网框拖进组合位。";
    if (target.value === "item_4_to_5") return "这里需要临时抄网。";
    if (target.value === "item_5_to_6") return "把密封饲料罐拖到硬边上撬开。";
    if (target.kind === "swan") return "黑天鹅只接受刚钓到的小鲤鱼。";
    if (target.value === "combine_magnetic_rod") return "把天鹅磁吸件或普通钓鱼竿拖进组合位。";
    if (target.value === "paper_body") return "需要磁吸钓鱼竿。";
    return "当前道具与这个目标不匹配。";
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
        requiredMode: candidate.requiredMode
      })),
      collisionRects: this.currentVehicle === "kayak" ? definition.kayakCollisions : definition.onFootCollisions,
      qizhenLake: {
        phase: runtime.phase,
        mode: runtime.mode,
        plate: this.currentZone,
        zone: this.currentZone,
        vehicle: this.currentVehicle,
        activeTarget: target?.id ?? null,
        kayak: {
          heading: Number(this.kayakHeading.toFixed(3)),
          speed: Math.round(this.kayakSpeed),
          roll: Number(this.kayakRoll.toFixed(3)),
          strokeIndex: this.strokeIndex,
          lastStrokeSide: this.lastStrokeSide,
          sameSideStreak: this.sameSideStreak,
          capsizing: this.capsizing
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
          elapsedSeconds: Number(this.chaseElapsedSeconds.toFixed(2)),
          desiredGap: Number(this.chaseDesiredGap.toFixed(1)),
          actualGap: Number(Math.hypot(this.chaseSwanX - this.player.x, this.chaseSwanY - this.player.y).toFixed(1)),
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
