import Phaser from "phaser";
import { selectIdentityReadable } from "../../core/IdentityAccess";
import type { GameState } from "../../core/types";
import actOneContent from "../../data/act-one-bootstrap.content.json";
import canteenContent from "../../data/chapter3-canteen.content.json";
import qizhenContent from "../../data/chapter3-qizhen-lake.content.json";
import campusRuntimeData from "../../data/maps/zijingang-campus-runtime.json";
import type { RpgBridge } from "./RpgBridge";
import { clearRpgRuntimeDebugState, setRpgRuntimeDebugState } from "./RpgRuntimeDebug";
import { preloadZijingangWorldAssets, ZIJINGANG_CAMPUS_PLATE_KEY } from "./ZijingangLandmarkAssets";
import { drawZijingangWorld, ZIJINGANG_WORLD } from "./ZijingangWorld";
import { CAMPUS_LIBRARY_GATE, LIBRARY_CHECKPOINT_SPAWNS } from "./LibraryInteriorModel";
import { CampusBuildingLayer } from "./CampusBuildings";
import { CampusPathGrid, type CampusPathPoint } from "./CampusPathfinder";
import { RpgMovementController } from "./RpgMovementController";
import { RpgCameraController } from "./RpgCameraController";
import {
  applyCampusRpgPlayerPerspectiveScale,
  configureRpgPlayerSprite,
  ensureRpgPlayerTextures,
  preloadRpgPlayerTextures,
  type RpgPlayerPerspectiveMetrics,
  RpgPlayerAnimator,
  RPG_PLAYER_WALK_FPS
} from "./RpgPlayerTextures";
import { RPG_CONTROL_HINTS, formatRpgInteractionHint } from "./RpgControlHints";
import { subscribeRpgSceneBridge } from "./RpgSceneBridgeSubscription";

const CAMERA_MIN_ZOOM = 0.5;
const CAMERA_MAX_ZOOM = 0.8;
const CAMERA_DEFAULT_ZOOM = 0.55;
const CAMERA_ZOOM_STEP = 0.0625;
const CAMERA_DEADZONE_WIDTH = 300;
const CAMERA_DEADZONE_HEIGHT = 180;
const CAMERA_FOLLOW_OFFSET_Y = 34;

// 寻人篇 · 地图层：暗色校园里沿脚印一路追到大食堂（第 1 张场景，最左侧）。
const CANTEEN_HUNT_SPAWN = { x: 10500, y: 1004 };
const CANTEEN_GATE = campusRuntimeData.canteenGate;
const CANTEEN_APPROACH = campusRuntimeData.walkability.canteenApproach;
const CANTEEN_BIKE = { x: 980, y: 973 };
const CANTEEN_BIKE_RADIUS = 190;
const CANTEEN_DARK_OVERLAY_COLOR = 0x050b1d;
const CANTEEN_DARK_OVERLAY_ALPHA = 0.76;
const CANTEEN_PLAYER_LIGHT_ALPHA = 0.82;
const CANTEEN_PLAYER_LIGHT_SCALE = 0.72;
const CANTEEN_THEATER_JUNCTION = campusRuntimeData.walkability.theaterApproach;
const THEATER_GATE = campusRuntimeData.theaterGate;
const QIZHEN_GATE = campusRuntimeData.qizhenGate;
const QIZHEN_APPROACH = campusRuntimeData.walkability.qizhenApproach;
const CANTEEN_NARRATION_RADIUS = 320;
const FOOTPRINT_SPACING = 46;
const FOOTPRINT_MESSY_RATIO = 0.86;

const CLICK_TO_MOVE_ENABLED = true;
const PATH_DOT_RADIUS = 7;
const PATH_ENDPOINT_RADIUS = 15;

export class BootScene extends Phaser.Scene {
  private bridge!: RpgBridge;
  private player!: Phaser.Physics.Arcade.Sprite;
  private contextualLandmarkLabels: Phaser.GameObjects.Text[] = [];
  private obstacles!: Phaser.Physics.Arcade.StaticGroup;
  private cursors!: Phaser.Types.Input.Keyboard.CursorKeys;
  private keys!: Record<"W" | "A" | "S" | "D" | "SHIFT", Phaser.Input.Keyboard.Key>;
  private virtualDirection = { x: 0, y: 0 };
  private lockedHintShown = false;
  private playerAnimator!: RpgPlayerAnimator;
  private playerPerspective!: RpgPlayerPerspectiveMetrics;
  private characterName!: Phaser.GameObjects.Text;
  private libraryGateMarker!: Phaser.GameObjects.Arc;
  private libraryGatePrompt!: Phaser.GameObjects.Text;
  private interactRequested = false;
  private buildingLayer!: CampusBuildingLayer;
  private buildingCollisionRects = new Map<string, Phaser.GameObjects.Rectangle>();
  private pathGrid!: CampusPathGrid;
  private movement!: RpgMovementController;
  private cameraController!: RpgCameraController;
  private pathIndicatorObjects: Phaser.GameObjects.Arc[] = [];
  private currentPathLength = 0;
  private canteenHuntActive = false;
  private canteenPhase: GameState["canteenHunt"]["phase"] = "tracking";
  private canteenDarkOverlay: Phaser.GameObjects.Rectangle | null = null;
  private canteenPlayerLight: Phaser.GameObjects.Image | null = null;
  private canteenFootprints: Phaser.GameObjects.Image[] = [];
  private canteenGateMarker: Phaser.GameObjects.Arc | null = null;
  private canteenGatePrompt: Phaser.GameObjects.Text | null = null;
  private canteenBike: Phaser.GameObjects.Image | null = null;
  private canteenBikeHint: Phaser.GameObjects.Text | null = null;
  private canteenBikeCodeGlow: Phaser.GameObjects.Arc | null = null;
  private canteenBikeGlare: Phaser.GameObjects.Rectangle | null = null;
  private canteenMessyNarrationShown = false;
  private canteenBikeIntroComplete = false;
  private theaterGateMarker: Phaser.GameObjects.Arc | null = null;
  private theaterGatePrompt: Phaser.GameObjects.Text | null = null;
  private qizhenGateMarker: Phaser.GameObjects.Arc | null = null;
  private qizhenGatePrompt: Phaser.GameObjects.Text | null = null;
  private qizhenBriefingQueued = false;

  constructor() {
    super("campus-bootstrap");
  }

  preload(): void {
    preloadZijingangWorldAssets(this);
    preloadRpgPlayerTextures(this);
  }

  create(): void {
    this.bridge = this.registry.get("rpgBridge") as RpgBridge;
    this.physics.world.setBounds(0, 0, ZIJINGANG_WORLD.width, ZIJINGANG_WORLD.height);
    this.cameras.main.setBackgroundColor(0x080a0c);
    this.obstacles = this.physics.add.staticGroup();
    drawZijingangWorld(this, { addObstacle: (x, y, width, height) => this.addObstacle(x, y, width, height) });
    this.contextualLandmarkLabels = this.children.list.filter(
      (object): object is Phaser.GameObjects.Text =>
        object instanceof Phaser.GameObjects.Text && object.getData("contextualLandmark") === true
    );

    this.buildingLayer = new CampusBuildingLayer(this, ZIJINGANG_CAMPUS_PLATE_KEY);
    const buildingOverlays = this.buildingLayer.build();
    this.buildingCollisionRects = new Map();
    this.buildingLayer.listBuildings().forEach((building) => {
      const collision = this.buildingLayer.getCollisionRect(building.id);
      if (!collision) {
        return;
      }
      const rect = this.add.rectangle(collision.x, collision.y, collision.width, collision.height, 0x000000, 0)
        .setDepth(collision.y - 10);
      this.obstacles.add(rect);
      this.buildingCollisionRects.set(building.id, rect);
    });
    this.buildingLayer.onBuildingChanged = (id) => this.syncBuildingCollisionRect(id);
    if (import.meta.env.DEV) {
      this.registry.set("campusBuildingLayer", this.buildingLayer);
    }

    ensureRpgPlayerTextures(this);
    const state = this.bridge.getState();
    this.canteenHuntActive = state.canteenHunt.active;
    this.canteenPhase = state.canteenHunt.phase;
    const spawn = state.rpgCheckpoint === "campus_canteen_gate"
      ? CANTEEN_APPROACH
      : state.rpgCheckpoint === "campus_qizhen_gate"
      ? QIZHEN_APPROACH
      : this.canteenHuntActive
      ? this.canteenPhase === "chase_ready" || this.canteenPhase === "chasing"
        ? CANTEEN_APPROACH
        : this.canteenPhase === "theater_reached"
          ? CANTEEN_THEATER_JUNCTION
          : CANTEEN_HUNT_SPAWN
      : state.rpgCheckpoint === "campus_library_gate"
        && state.ui.libraryFinalsPhase === "library_route_unlocked"
        ? LIBRARY_CHECKPOINT_SPAWNS.campus_library_gate
        : ZIJINGANG_WORLD.spawn;
    this.player = this.physics.add.sprite(spawn.x, spawn.y, "act1-player-down-0");
    this.player.setCollideWorldBounds(true).setDepth(this.player.y + 30);
    configureRpgPlayerSprite(this.player);
    this.playerPerspective = applyCampusRpgPlayerPerspectiveScale(this.player, this.player.y);
    this.playerAnimator = new RpgPlayerAnimator(this.player, "down");
    this.physics.add.collider(this.player, this.obstacles);
    this.characterName = this.add.text(this.player.x, this.player.y - this.playerPerspective.nameOffsetY, "", {
      color: "#fff7df",
      backgroundColor: "#17212add",
      fontFamily: "monospace",
      fontSize: "11px",
      padding: { x: 4, y: 2 }
    }).setOrigin(0.5).setDepth(this.player.y + 55).setVisible(false);
    this.syncCharacterNameplate(this.bridge.getState());

    this.cursors = this.input.keyboard!.createCursorKeys();
    this.keys = this.input.keyboard!.addKeys("W,A,S,D,SHIFT") as Record<"W" | "A" | "S" | "D" | "SHIFT", Phaser.Input.Keyboard.Key>;

    // 24px 采样格：玩家足盒宽 ~20px，16px 格会把窄于足盒的缝隙（如路缘石之间的缺口）
    // 标为可走，寻路会把玩家卡进物理无法穿行的死角；24px 保守合并保证 nav 通道可容纳足盒。
    this.pathGrid = new CampusPathGrid(campusRuntimeData.walkability, 24);
    this.movement = new RpgMovementController(this.player, { walkSpeed: 220, runSpeed: 320 });
    this.movement.onPathFinished = () => this.clearPathIndicator();

    this.cameraController = new RpgCameraController(this, {
      player: this.player,
      world: { width: ZIJINGANG_WORLD.width, height: ZIJINGANG_WORLD.height },
      minZoom: CAMERA_MIN_ZOOM,
      maxZoom: CAMERA_MAX_ZOOM,
      defaultZoom: CAMERA_DEFAULT_ZOOM,
      zoomStep: CAMERA_ZOOM_STEP,
      deadzone: { width: CAMERA_DEADZONE_WIDTH, height: CAMERA_DEADZONE_HEIGHT },
      followOffsetY: CAMERA_FOLLOW_OFFSET_Y,
      minimap: null
    });
    this.cameraController.attach();
    this.cameraController.minimapCamera?.ignore(this.contextualLandmarkLabels);
    this.cameraController.minimapCamera?.ignore(buildingOverlays);
    if (CLICK_TO_MOVE_ENABLED) {
      this.cameraController.onWorldTap = (worldX, worldY) => this.handleWorldTap(worldX, worldY);
    }

    this.pathIndicatorObjects = [];
    this.currentPathLength = 0;

    this.createLibraryGate();
    this.createCanteenGate();
    if (this.canteenHuntActive) {
      this.setupCanteenHunt();
    }
    this.setupQizhenCampus(state);

    subscribeRpgSceneBridge(this.events, this.bridge, (event) => {
      if (event.name === "rpg_direction_changed") {
        this.virtualDirection = {
          x: Number(event.payload?.x) || 0,
          y: Number(event.payload?.y) || 0
        };
      } else if (event.name === "rpg_camera_recenter") {
        this.cameraController.recenter(true);
      } else if (event.name === "rpg_camera_zoom") {
        this.cameraController.zoomBy(Number(event.payload?.delta) || 0);
      } else if (event.name === "rpg_interact") {
        this.interactRequested = true;
      } else if (event.name === "rpg_inventory_drop_requested") {
        this.handleCanteenInventoryDrop(event.payload);
      } else if (event.name === "canteen_mode_changed" && this.canteenPhase === "chase_ready") {
        this.applyCanteenBikeMode(String(event.payload?.mode) === "dark" ? "dark" : "light");
      } else if (event.name === "canteen_bike_code_read") {
        this.animateCanteenBikeCodeRead();
      } else if (event.name === "canteen_bike_glare_failed") {
        this.showCanteenFeedback(canteenContent.bike.glareFailed, "system");
      } else if (event.name === "canteen_bike_dark_payment_rejected") {
        this.showCanteenFeedback(canteenContent.bike.darkPaymentRejected, "system");
      } else if (event.name === "canteen_bike_scan_rule") {
        this.showCanteenFeedback(canteenContent.bike.scanRule, "task");
      } else if (event.name === "canteen_bike_lock_cleaned") {
        this.animateCanteenBikeCleaned();
      } else if (event.name === "canteen_bike_payment_ready") {
        this.showCanteenFeedback(canteenContent.bike.unlock, "task");
      } else if (event.name === "canteen_chase_completed") {
        this.player.setPosition(CANTEEN_THEATER_JUNCTION.x, CANTEEN_THEATER_JUNCTION.y);
        this.movement.clearPath();
        this.cameraController.recenter(true);
        this.bridge.emit("rpg_subtitle", {
          text: canteenContent.bike.finish,
          tone: "system",
          durationMs: 3200
        });
      }
    }, clearRpgRuntimeDebugState);
    this.bridge.emit("rpg_booted", { scene: "campus_bootstrap" });
  }

  update(_time: number, delta: number): void {
    const state = this.bridge.getState();
    this.applyDepthScale();
    this.syncCharacterNameplate(state);
    const keyboardX = Number(this.cursors.right.isDown || this.keys.D.isDown) - Number(this.cursors.left.isDown || this.keys.A.isDown);
    const keyboardY = Number(this.cursors.down.isDown || this.keys.S.isDown) - Number(this.cursors.up.isDown || this.keys.W.isDown);
    const x = Math.max(-1, Math.min(1, keyboardX + this.virtualDirection.x));
    const y = Math.max(-1, Math.min(1, keyboardY + this.virtualDirection.y));

    this.updateContextualLandmarkLabel();
    this.updateLibraryGate();
    this.updateCanteenGate(state);
    if (this.canteenHuntActive) {
      this.updateCanteenHunt();
    }
    this.updateQizhenGate();
    this.interactRequested = false;
    this.publishDebugState();

    if (!state.actOne.movementEnabled) {
      this.movement.setManualInput(0, 0, false);
      this.movement.clearPath();
      this.player.setVelocity(0);
      this.playerAnimator.update(new Phaser.Math.Vector2(0, 0), this.time.now);
      if ((x !== 0 || y !== 0) && !this.lockedHintShown) {
        this.lockedHintShown = true;
        this.bridge.emit("toast", { text: actOneContent.narration.locked, tone: "xiaoying" });
      }
      this.cameraController.update(delta);
      return;
    }

    this.movement.setManualInput(x, y, this.keys.SHIFT.isDown);
    const velocity = this.movement.update(delta);
    this.playerAnimator.update(velocity, this.time.now);
    this.player.setDepth(this.player.y + 30);
    this.cameraController.update(delta);
  }

  private syncCharacterNameplate(state: GameState): void {
    const identityReadable = selectIdentityReadable(state);
    this.characterName
      .setText(identityReadable && state.actOne.characterNamed ? actOneContent.studentName : "")
      .setVisible(identityReadable && state.actOne.characterNamed)
      .setPosition(this.player.x, this.player.y - this.playerPerspective.nameOffsetY)
      .setDepth(this.player.y + 72);
  }

  private applyDepthScale(): void {
    this.playerPerspective = applyCampusRpgPlayerPerspectiveScale(this.player, this.player.y);
  }

  private createLibraryGate(): void {
    this.libraryGateMarker = this.add.circle(
      CAMPUS_LIBRARY_GATE.x,
      CAMPUS_LIBRARY_GATE.y,
      24,
      0x1d9b75,
      0.22
    ).setStrokeStyle(5, 0xe6d268, 0.95).setDepth(CAMPUS_LIBRARY_GATE.y + 80);
    this.libraryGatePrompt = this.add.text(
      CAMPUS_LIBRARY_GATE.x,
      CAMPUS_LIBRARY_GATE.y - 52,
      `基础图书馆入口  ·  ${RPG_CONTROL_HINTS.libraryGate}`,
      {
        color: "#fff7df",
        backgroundColor: "#10231fee",
        fontFamily: "monospace",
        fontSize: "13px",
        padding: { x: 8, y: 5 }
      }
    ).setOrigin(0.5).setDepth(CAMPUS_LIBRARY_GATE.y + 90).setVisible(false);
    this.cameraController.minimapCamera?.ignore([this.libraryGateMarker, this.libraryGatePrompt]);

    this.tweens.add({
      targets: this.libraryGateMarker,
      scale: { from: 0.86, to: 1.18 },
      alpha: { from: 0.56, to: 1 },
      duration: 720,
      yoyo: true,
      repeat: -1,
      ease: "Stepped"
    });
  }

  private updateLibraryGate(): void {
    const state = this.bridge.getState();
    const available = state.actOne.canLeaveDorm
      && state.ui.libraryFinalsPhase !== "friend_contacted"
      && !this.canteenHuntActive;
    const distance = Phaser.Math.Distance.Between(
      this.player.x,
      this.player.y,
      CAMPUS_LIBRARY_GATE.x,
      CAMPUS_LIBRARY_GATE.y
    );
    const nearby = available && distance <= CAMPUS_LIBRARY_GATE.radius;
    this.libraryGateMarker.setVisible(available);
    this.libraryGatePrompt.setVisible(nearby);

    const keyboardInteract = nearby && Phaser.Input.Keyboard.JustDown(this.cursors.space);
    if (nearby && (keyboardInteract || this.interactRequested)) {
      this.bridge.setCheckpoint("campus_library_gate");
      this.bridge.emit("rpg_library_gate_requested", { landmark: "foundation_library" });
    }
  }

  private setupCanteenHunt(): void {
    this.ensureCanteenTextures();
    if (["tracking", "canteen_reached"].includes(this.canteenPhase)) {
      this.createCanteenDarkness();
      this.createCanteenFootprintTrail();
      this.createCanteenGate();
      this.bridge.emit("rpg_subtitle", {
        text: canteenContent.hints[0],
        tone: "task",
        durationMs: 4200
      });
      return;
    }
    if (this.canteenPhase === "chase_ready") {
      this.createCanteenBike();
      this.createCanteenBikeModeLayer();
      const bikeIntro = [...canteenContent.bike.setupDialogue, ...canteenContent.bike.noMoney];
      this.emitCanteenSequence(bikeIntro);
      this.time.delayedCall(bikeIntro.length * 2500, () => {
        this.canteenBikeIntroComplete = true;
      });
      return;
    }
    if (this.canteenPhase === "theater_reached") {
      this.createTheaterGate();
    }
  }

  private createTheaterGate(): void {
    this.theaterGateMarker = this.add.circle(THEATER_GATE.x, THEATER_GATE.y, 25, 0x8d3244, 0.24)
      .setStrokeStyle(5, 0xe8c16f, 0.95)
      .setDepth(THEATER_GATE.y + 85);
    this.theaterGatePrompt = this.add.text(
      THEATER_GATE.x,
      THEATER_GATE.y - 54,
      `剧院入口  ·  ${formatRpgInteractionHint("进入剧院")}`,
      {
        color: "#fff4df",
        backgroundColor: "#28141cee",
        fontFamily: "monospace",
        fontSize: "13px",
        padding: { x: 8, y: 5 }
      }
    ).setOrigin(0.5).setDepth(THEATER_GATE.y + 90).setVisible(false);
    this.tweens.add({
      targets: this.theaterGateMarker,
      scale: { from: 0.86, to: 1.18 },
      alpha: { from: 0.5, to: 1 },
      duration: 760,
      yoyo: true,
      repeat: -1,
      ease: "Sine.easeInOut"
    });
    this.cameraController.minimapCamera?.ignore([this.theaterGateMarker, this.theaterGatePrompt]);
  }

  private ensureCanteenTextures(): void {
    if (!this.textures.exists("canteen-footprint")) {
      const g = this.add.graphics();
      g.fillStyle(0xcdf3ff, 1);
      g.fillEllipse(8, 6, 8, 9);
      g.fillEllipse(8, 15, 6, 7);
      g.generateTexture("canteen-footprint", 16, 20);
      g.destroy();
    }
    if (!this.textures.exists("canteen-light")) {
      const size = 720;
      const canvasTexture = this.textures.createCanvas("canteen-light", size, size);
      if (canvasTexture) {
        const ctx = canvasTexture.getContext();
        const grad = ctx.createRadialGradient(size / 2, size / 2, 24, size / 2, size / 2, size / 2);
        grad.addColorStop(0, "rgba(255,244,214,0.92)");
        grad.addColorStop(0.45, "rgba(255,240,205,0.40)");
        grad.addColorStop(1, "rgba(255,240,205,0)");
        ctx.fillStyle = grad;
        ctx.fillRect(0, 0, size, size);
        canvasTexture.refresh();
      }
    }
    if (!this.textures.exists("canteen-bike")) {
      const g = this.add.graphics();
      g.lineStyle(3, 0x2b2f36, 1);
      g.strokeCircle(13, 27, 9);
      g.strokeCircle(41, 27, 9);
      g.lineStyle(3, 0xe8654f, 1);
      g.beginPath();
      g.moveTo(13, 27);
      g.lineTo(27, 13);
      g.lineTo(41, 27);
      g.moveTo(27, 13);
      g.lineTo(21, 27);
      g.moveTo(27, 13);
      g.lineTo(35, 12);
      g.strokePath();
      g.lineStyle(3, 0x2b2f36, 1);
      g.beginPath();
      g.moveTo(35, 12);
      g.lineTo(39, 7);
      g.moveTo(23, 13);
      g.lineTo(27, 10);
      g.strokePath();
      g.generateTexture("canteen-bike", 54, 40);
      g.destroy();
    }
  }

  private createCanteenDarkness(): void {
    const w = ZIJINGANG_WORLD.width;
    const h = ZIJINGANG_WORLD.height;
    this.canteenDarkOverlay = this.add.rectangle(w / 2, h / 2, w, h, CANTEEN_DARK_OVERLAY_COLOR, 1)
      .setAlpha(0)
      .setDepth(500);
    this.tweens.add({
      targets: this.canteenDarkOverlay,
      alpha: CANTEEN_DARK_OVERLAY_ALPHA,
      duration: 2000,
      ease: "Cubic.easeOut"
    });
    this.canteenPlayerLight = this.add.image(this.player.x, this.player.y, "canteen-light")
      .setDepth(501)
      .setBlendMode(Phaser.BlendModes.ADD)
      .setScale(CANTEEN_PLAYER_LIGHT_SCALE)
      .setAlpha(0);
    this.tweens.add({
      targets: this.canteenPlayerLight,
      alpha: CANTEEN_PLAYER_LIGHT_ALPHA,
      duration: 2000,
      delay: 300
    });
    this.cameraController.minimapCamera?.ignore([this.canteenDarkOverlay, this.canteenPlayerLight]);
  }

  private createCanteenFootprintTrail(): void {
    const path = this.pathGrid.findPath(
      { x: CANTEEN_HUNT_SPAWN.x, y: CANTEEN_HUNT_SPAWN.y },
      { x: CANTEEN_APPROACH.x, y: CANTEEN_APPROACH.y }
    );
    if (!path || path.length < 2) {
      return;
    }
    const spaced = this.resamplePath(path, FOOTPRINT_SPACING);
    const messStart = Math.floor(spaced.length * FOOTPRINT_MESSY_RATIO);
    spaced.forEach((point, index) => {
      const messy = index >= messStart;
      const side = index % 2 === 0 ? 1 : -1;
      const perpX = Math.cos(point.angle + Math.PI / 2);
      const perpY = Math.sin(point.angle + Math.PI / 2);
      let ox = point.x + perpX * side * 7;
      let oy = point.y + perpY * side * 7;
      let rotation = point.angle + Math.PI / 2;
      let alpha = 0.9;
      let scale = 1;
      if (messy) {
        ox += Phaser.Math.Between(-30, 30);
        oy += Phaser.Math.Between(-22, 22);
        rotation += Phaser.Math.FloatBetween(-1.3, 1.3);
        alpha = Phaser.Math.FloatBetween(0.28, 0.8);
        scale = Phaser.Math.FloatBetween(0.7, 1.2);
      }
      const footprint = this.add.image(ox, oy, "canteen-footprint")
        .setRotation(rotation)
        .setAlpha(0)
        .setScale(scale)
        .setTint(0xb6efff)
        .setBlendMode(Phaser.BlendModes.ADD)
        .setDepth(oy + 4);
      this.tweens.add({
        targets: footprint,
        alpha,
        duration: 500,
        delay: Math.min(index * 12, 2600),
        ease: "Cubic.easeOut"
      });
      this.canteenFootprints.push(footprint);
    });
    const tail = spaced[spaced.length - 1];
    for (let k = 0; k < 28; k++) {
      const ox = tail.x + Phaser.Math.Between(-140, 140);
      const oy = tail.y + Phaser.Math.Between(8, 96);
      const footprint = this.add.image(ox, oy, "canteen-footprint")
        .setRotation(Phaser.Math.FloatBetween(-Math.PI, Math.PI))
        .setAlpha(0)
        .setScale(Phaser.Math.FloatBetween(0.6, 1.1))
        .setTint(0xb6efff)
        .setBlendMode(Phaser.BlendModes.ADD)
        .setDepth(oy + 4);
      this.tweens.add({
        targets: footprint,
        alpha: Phaser.Math.FloatBetween(0.2, 0.6),
        duration: 600,
        delay: 2600 + k * 28
      });
      this.canteenFootprints.push(footprint);
    }
    this.cameraController.minimapCamera?.ignore(this.canteenFootprints);
  }

  private resamplePath(
    path: CampusPathPoint[],
    step: number
  ): { x: number; y: number; angle: number }[] {
    const result: { x: number; y: number; angle: number }[] = [];
    let carry = 0;
    for (let i = 0; i < path.length - 1; i++) {
      const a = path[i];
      const b = path[i + 1];
      const dx = b.x - a.x;
      const dy = b.y - a.y;
      const segmentLength = Math.hypot(dx, dy);
      if (segmentLength === 0) {
        continue;
      }
      const angle = Math.atan2(dy, dx);
      let dist = carry;
      while (dist < segmentLength) {
        const t = dist / segmentLength;
        result.push({ x: a.x + dx * t, y: a.y + dy * t, angle });
        dist += step;
      }
      carry = dist - segmentLength;
    }
    const lastPoint = path[path.length - 1];
    const lastAngle = result.length > 0 ? result[result.length - 1].angle : 0;
    result.push({ x: lastPoint.x, y: lastPoint.y, angle: lastAngle });
    return result;
  }

  private createCanteenGate(): void {
    if (this.canteenGateMarker) return;
    this.canteenGateMarker = this.add.circle(CANTEEN_GATE.x, CANTEEN_GATE.y, 24, 0x9b7228, 0.3)
      .setStrokeStyle(5, 0xffdf73, 1)
      .setDepth(CANTEEN_GATE.y + 80);
    this.canteenGatePrompt = this.add.text(
      CANTEEN_GATE.x,
      CANTEEN_GATE.y - 52,
      `大食堂入口  ·  ${formatRpgInteractionHint("进入食堂")}`,
      {
        color: "#fff7df",
        backgroundColor: "#10231fee",
        fontFamily: "monospace",
        fontSize: "13px",
        padding: { x: 8, y: 5 }
      }
    ).setOrigin(0.5).setDepth(CANTEEN_GATE.y + 90).setVisible(false);
    this.cameraController.minimapCamera?.ignore([this.canteenGateMarker, this.canteenGatePrompt]);
    this.tweens.add({
      targets: this.canteenGateMarker,
      scale: { from: 0.86, to: 1.18 },
      alpha: { from: 0.56, to: 1 },
      duration: 720,
      yoyo: true,
      repeat: -1,
      ease: "Stepped"
    });
  }

  private createCanteenBike(): void {
    this.canteenBike = this.add.image(CANTEEN_BIKE.x, CANTEEN_BIKE.y, "canteen-bike")
      .setDepth(CANTEEN_BIKE.y + 6)
      .setAlpha(0.95)
      .setInteractive({ useHandCursor: true })
      .on("pointerdown", () => this.requestCanteenBikeIfNearby());
    this.canteenBikeHint = this.add.text(
      CANTEEN_BIKE.x,
      CANTEEN_BIKE.y - 40,
      `${canteenContent.bike.scan}\n${canteenContent.bike.balance}`,
      {
        color: "#fff7df",
        backgroundColor: "#241a12ee",
        fontFamily: "monospace",
        fontSize: "12px",
        padding: { x: 7, y: 4 }
      }
    ).setOrigin(0.5).setDepth(CANTEEN_BIKE.y + 12).setVisible(false);
    this.cameraController.minimapCamera?.ignore([this.canteenBike, this.canteenBikeHint]);
  }

  private createCanteenBikeModeLayer(): void {
    const state = this.bridge.getState();
    this.canteenDarkOverlay = this.add.rectangle(
      ZIJINGANG_WORLD.width / 2,
      ZIJINGANG_WORLD.height / 2,
      ZIJINGANG_WORLD.width,
      ZIJINGANG_WORLD.height,
      CANTEEN_DARK_OVERLAY_COLOR,
      CANTEEN_DARK_OVERLAY_ALPHA
    ).setDepth(500).setAlpha(state.canteenHunt.mode === "dark" ? CANTEEN_DARK_OVERLAY_ALPHA : 0);
    this.canteenPlayerLight = this.add.image(this.player.x, this.player.y, "canteen-light")
      .setDepth(501)
      .setBlendMode(Phaser.BlendModes.ADD)
      .setScale(CANTEEN_PLAYER_LIGHT_SCALE)
      .setAlpha(state.canteenHunt.mode === "dark" ? CANTEEN_PLAYER_LIGHT_ALPHA : 0);
    this.canteenBikeCodeGlow = this.add.circle(CANTEEN_BIKE.x, CANTEEN_BIKE.y, 31, 0x4bc9ff, 0.16)
      .setStrokeStyle(4, 0x88e7ff, 0.95)
      .setDepth(CANTEEN_BIKE.y + 4)
      .setVisible(state.canteenHunt.mode === "dark");
    this.canteenBikeGlare = this.add.rectangle(CANTEEN_BIKE.x + 8, CANTEEN_BIKE.y - 5, 22, 18, 0xffffff, 0.76)
      .setStrokeStyle(2, 0xffedba, 0.9)
      .setRotation(-0.18)
      .setDepth(CANTEEN_BIKE.y + 10)
      .setVisible(state.canteenHunt.mode === "light" && !state.canteenHunt.bikeLockCleaned);
    this.tweens.add({
      targets: this.canteenBikeCodeGlow,
      scale: { from: 0.86, to: 1.16 },
      alpha: { from: 0.35, to: 0.95 },
      duration: 720,
      yoyo: true,
      repeat: -1,
      ease: "Sine.easeInOut"
    });
    this.cameraController.minimapCamera?.ignore([
      this.canteenDarkOverlay,
      this.canteenPlayerLight,
      this.canteenBikeCodeGlow,
      this.canteenBikeGlare
    ]);
  }

  private applyCanteenBikeMode(mode: GameState["canteenHunt"]["mode"]): void {
    const duration = window.matchMedia?.("(prefers-reduced-motion: reduce)").matches ? 120 : 420;
    if (this.canteenDarkOverlay) {
      this.tweens.add({ targets: this.canteenDarkOverlay, alpha: mode === "dark" ? CANTEEN_DARK_OVERLAY_ALPHA : 0, duration, ease: "Sine.easeInOut" });
    }
    if (this.canteenPlayerLight) {
      this.tweens.add({ targets: this.canteenPlayerLight, alpha: mode === "dark" ? CANTEEN_PLAYER_LIGHT_ALPHA : 0, duration, ease: "Sine.easeInOut" });
    }
    this.canteenBikeCodeGlow?.setVisible(mode === "dark");
    this.canteenBikeGlare?.setVisible(mode === "light" && !this.bridge.getState().canteenHunt.bikeLockCleaned);
    this.bridge.emit(mode === "dark" ? "canteen_dark_mode_enabled" : "canteen_light_mode_enabled");
  }

  private animateCanteenBikeCodeRead(): void {
    this.showCanteenFeedback(canteenContent.bike.codeVisible, "system");
    if (!this.canteenBikeCodeGlow) return;
    this.tweens.add({
      targets: this.canteenBikeCodeGlow,
      scale: 1.34,
      duration: 170,
      yoyo: true,
      repeat: 1,
      ease: "Cubic.easeOut"
    });
  }

  private animateCanteenBikeCleaned(): void {
    this.showCanteenFeedback(canteenContent.bike.lockCleaned, "success");
    if (!this.canteenBikeGlare) return;
    this.tweens.add({
      targets: this.canteenBikeGlare,
      x: CANTEEN_BIKE.x + 28,
      alpha: 0,
      duration: 360,
      ease: "Cubic.easeOut",
      onComplete: () => this.canteenBikeGlare?.setVisible(false)
    });
  }

  private showCanteenFeedback(text: string, tone: "system" | "task" | "success"): void {
    this.bridge.emit("rpg_subtitle", { text, tone, durationMs: 3200 });
  }

  private updateCanteenHunt(): void {
    this.canteenPhase = this.bridge.getState().canteenHunt.phase;
    if (this.canteenPhase === "theater_reached") {
      this.updateTheaterGate();
      return;
    }
    if (this.canteenPhase === "chase_ready") {
      this.updateCanteenBike();
      return;
    }
    if (!["tracking", "canteen_reached"].includes(this.canteenPhase)) {
      this.canteenBikeHint?.setVisible(false);
      return;
    }
    if (this.canteenPlayerLight) {
      this.canteenPlayerLight.setPosition(this.player.x, this.player.y);
    }
    const distanceToGate = Phaser.Math.Distance.Between(
      this.player.x,
      this.player.y,
      CANTEEN_GATE.x,
      CANTEEN_GATE.y
    );
    if (!this.canteenMessyNarrationShown && distanceToGate <= CANTEEN_NARRATION_RADIUS) {
      this.canteenMessyNarrationShown = true;
    }
  }

  private updateCanteenGate(state: GameState): void {
    const storyEntry = state.canteenHunt.active
      && ["tracking", "canteen_reached"].includes(state.canteenHunt.phase);
    const freeExploreEntry = !state.canteenHunt.active && state.actOne.canLeaveDorm;
    const available = storyEntry || freeExploreEntry;
    const distanceToGate = Phaser.Math.Distance.Between(
      this.player.x,
      this.player.y,
      CANTEEN_GATE.x,
      CANTEEN_GATE.y
    );
    const nearby = available && distanceToGate <= CANTEEN_GATE.radius;

    this.canteenGateMarker?.setVisible(available);
    this.canteenGatePrompt?.setVisible(nearby);

    const keyboardInteract = nearby && Phaser.Input.Keyboard.JustDown(this.cursors.space);
    if (nearby && (keyboardInteract || this.interactRequested)) {
      this.bridge.setCheckpoint("campus_canteen_gate");
      this.bridge.emit("rpg_canteen_entry_requested", { mode: storyEntry ? "story" : "explore" });
    }
  }

  private updateTheaterGate(): void {
    const distance = Phaser.Math.Distance.Between(
      this.player.x,
      this.player.y,
      THEATER_GATE.x,
      THEATER_GATE.y
    );
    const nearby = distance <= 110;
    this.theaterGateMarker?.setVisible(true);
    this.theaterGatePrompt?.setVisible(nearby);
    const keyboardInteract = nearby && Phaser.Input.Keyboard.JustDown(this.cursors.space);
    if (nearby && (keyboardInteract || this.interactRequested)) {
      this.bridge.setCheckpoint("campus_theater_junction");
      this.bridge.emit("rpg_theater_entry_requested");
    }
  }

  private setupQizhenCampus(state: GameState): void {
    if (
      state.qizhenLake.active
      && state.qizhenLake.phase === "location_search"
      && !state.qizhenLake.locationBriefingSeen
      && !this.qizhenBriefingQueued
    ) {
      this.qizhenBriefingQueued = true;
      this.emitCanteenSequence(qizhenContent.locationSearch.dialogue);
      this.time.delayedCall(qizhenContent.locationSearch.dialogue.length * 2500, () => {
        this.bridge.emit("rpg_qizhen_location_briefing_seen_requested");
      });
    }
    if (state.qizhenLake.active && !["inactive", "location_search"].includes(state.qizhenLake.phase)) {
      this.createQizhenGate();
    }
  }

  private createQizhenGate(): void {
    if (this.qizhenGateMarker) return;
    this.qizhenGateMarker = this.add.circle(QIZHEN_GATE.x, QIZHEN_GATE.y, 27, 0x1c8297, 0.24)
      .setStrokeStyle(5, 0xa5e6d5, 0.96)
      .setDepth(QIZHEN_GATE.y + 85);
    this.qizhenGatePrompt = this.add.text(
      QIZHEN_GATE.x,
      QIZHEN_GATE.y - 56,
      `启真湖入口  ·  ${formatRpgInteractionHint("进入启真湖")}`,
      {
        color: "#effff8",
        backgroundColor: "#0d2930ee",
        fontFamily: "monospace",
        fontSize: "13px",
        padding: { x: 8, y: 5 }
      }
    ).setOrigin(0.5).setDepth(QIZHEN_GATE.y + 90).setVisible(false);
    this.tweens.add({
      targets: this.qizhenGateMarker,
      scale: { from: 0.86, to: 1.18 },
      alpha: { from: 0.52, to: 1 },
      duration: 760,
      yoyo: true,
      repeat: -1,
      ease: "Sine.easeInOut"
    });
    this.cameraController.minimapCamera?.ignore([this.qizhenGateMarker, this.qizhenGatePrompt]);
  }

  private updateQizhenGate(): void {
    const state = this.bridge.getState();
    const available = state.qizhenLake.active && !["inactive", "location_search"].includes(state.qizhenLake.phase);
    if (!available) {
      this.qizhenGateMarker?.setVisible(false);
      this.qizhenGatePrompt?.setVisible(false);
      return;
    }
    if (!this.qizhenGateMarker) this.createQizhenGate();
    const distance = Phaser.Math.Distance.Between(this.player.x, this.player.y, QIZHEN_GATE.x, QIZHEN_GATE.y);
    const nearby = distance <= QIZHEN_GATE.radius;
    this.qizhenGateMarker?.setVisible(true);
    this.qizhenGatePrompt?.setVisible(nearby);
    const keyboardInteract = nearby && Phaser.Input.Keyboard.JustDown(this.cursors.space);
    if (nearby && (keyboardInteract || this.interactRequested)) {
      this.bridge.setCheckpoint("campus_qizhen_gate");
      this.bridge.emit("rpg_qizhen_entry_requested");
    }
  }

  private updateCanteenBike(): void {
    this.canteenPlayerLight?.setPosition(this.player.x, this.player.y);
    const distanceToBike = Phaser.Math.Distance.Between(
      this.player.x,
      this.player.y,
      CANTEEN_BIKE.x,
      CANTEEN_BIKE.y
    );
    if (this.canteenBikeHint) {
      this.canteenBikeHint.setVisible(this.canteenBikeIntroComplete && distanceToBike <= CANTEEN_BIKE_RADIUS);
    }
    const keyboardInteract = distanceToBike <= CANTEEN_BIKE_RADIUS
      && Phaser.Input.Keyboard.JustDown(this.cursors.space);
    if (distanceToBike <= CANTEEN_BIKE_RADIUS && (keyboardInteract || this.interactRequested)) {
      this.requestCanteenBikeIfNearby();
    }
  }

  private requestCanteenBikeIfNearby(): void {
    if (this.canteenPhase !== "chase_ready" || !this.canteenBikeIntroComplete) return;
    if (Phaser.Math.Distance.Between(this.player.x, this.player.y, CANTEEN_BIKE.x, CANTEEN_BIKE.y) > CANTEEN_BIKE_RADIUS) return;
    this.bridge.emit("rpg_canteen_bike_inspect_requested");
  }

  private handleCanteenInventoryDrop(payload?: Record<string, unknown>): void {
    if (this.canteenPhase !== "chase_ready" || !this.canteenBikeIntroComplete) return;
    const itemId = String(payload?.itemId ?? "");
    if (itemId !== "cafeteriaWages" && itemId !== "greaseTissue") return;
    const canvasX = Number(payload?.canvasX);
    const canvasY = Number(payload?.canvasY);
    if (!Number.isFinite(canvasX) || !Number.isFinite(canvasY)) return;
    const worldPoint = this.cameras.main.getWorldPoint(canvasX, canvasY);
    if (Phaser.Math.Distance.Between(worldPoint.x, worldPoint.y, CANTEEN_BIKE.x, CANTEEN_BIKE.y) <= 100) {
      this.bridge.emit(itemId === "greaseTissue" ? "rpg_canteen_bike_tissue_requested" : "rpg_canteen_bike_requested");
    }
  }

  private emitCanteenSequence(lines: readonly string[]): void {
    lines.forEach((text, index) => {
      this.time.delayedCall(index * 2500, () => {
        this.bridge.emit("rpg_subtitle", {
          text,
          tone: text.startsWith("玩家：") ? "player" : text.startsWith("系统：") ? "system" : "narrator",
          durationMs: 2380
        });
      });
    });
  }

  private syncBuildingCollisionRect(id: string): void {
    const rect = this.buildingCollisionRects.get(id);
    const collision = this.buildingLayer.getCollisionRect(id);
    if (!rect || !collision) {
      return;
    }
    rect.setPosition(collision.x, collision.y);
    rect.setSize(collision.width, collision.height);
    rect.setDepth(collision.y - 10);
    (rect.body as Phaser.Physics.Arcade.StaticBody | null)?.updateFromGameObject();
  }

  private handleWorldTap(worldX: number, worldY: number): void {
    if (!this.bridge.getState().actOne.movementEnabled) {
      return;
    }
    // walkability 掩码描述的是足盒可站立区域，而路点需要驱动精灵锚点；
    // 在足盒空间寻路，再换算回锚点空间喂给移动控制器，避免路点落在足盒无法到达的位置。
    const body = this.player.body as Phaser.Physics.Arcade.Body | null;
    const footOffsetY = body ? body.center.y - this.player.y : 0;
    const path = this.pathGrid.findPath(
      { x: this.player.x, y: this.player.y + footOffsetY },
      { x: worldX, y: worldY }
    );
    if (!path || path.length === 0) {
      this.showUnreachableMarker(worldX, worldY);
      return;
    }
    this.movement.setPath(path.map((point) => ({ x: point.x, y: point.y - footOffsetY })));
    this.currentPathLength = path.length;
    this.showPathIndicator(path);
  }

  private showPathIndicator(path: CampusPathPoint[]): void {
    this.clearPathIndicator();
    const points = path.length > 1 ? path.slice(1) : path;
    points.forEach((point, index) => {
      const isEndpoint = index === points.length - 1;
      const dot = this.add.circle(
        point.x,
        point.y,
        isEndpoint ? PATH_ENDPOINT_RADIUS : PATH_DOT_RADIUS,
        0x1d9b75,
        isEndpoint ? 0.16 : 0.2
      )
        .setStrokeStyle(isEndpoint ? 4 : 2, 0xe6d268, isEndpoint ? 0.95 : 0.8)
        .setDepth(point.y);
      if (isEndpoint) {
        this.tweens.add({
          targets: dot,
          scale: { from: 0.86, to: 1.18 },
          alpha: { from: 0.56, to: 1 },
          duration: 720,
          yoyo: true,
          repeat: -1,
          ease: "Stepped"
        });
      }
      this.pathIndicatorObjects.push(dot);
    });
    this.cameraController.minimapCamera?.ignore(this.pathIndicatorObjects);
  }

  private showUnreachableMarker(x: number, y: number): void {
    const marker = this.add.circle(x, y, 13, 0x1d9b75, 0)
      .setStrokeStyle(3, 0xe97b70, 0.85)
      .setDepth(y);
    this.cameraController.minimapCamera?.ignore(marker);
    this.tweens.add({
      targets: marker,
      scale: { from: 0.7, to: 1.35 },
      alpha: { from: 0.85, to: 0 },
      duration: 480,
      ease: "Cubic.easeOut",
      onComplete: () => marker.destroy()
    });
  }

  private clearPathIndicator(): void {
    this.pathIndicatorObjects.forEach((object) => {
      this.tweens.killTweensOf(object);
      object.destroy();
    });
    this.pathIndicatorObjects = [];
    this.currentPathLength = 0;
  }

  private updateContextualLandmarkLabel(): void {
    let nearest: Phaser.GameObjects.Text | undefined;
    let nearestDistance = Number.POSITIVE_INFINITY;

    for (const label of this.contextualLandmarkLabels) {
      const anchorX = Number(label.getData("anchorX"));
      const anchorY = Number(label.getData("anchorY"));
      const revealRadius = Number(label.getData("revealRadius"));
      const distance = Phaser.Math.Distance.Between(this.player.x, this.player.y, anchorX, anchorY);
      if (distance <= revealRadius && distance < nearestDistance) {
        nearest = label;
        nearestDistance = distance;
      }
    }

    this.contextualLandmarkLabels.forEach((label) => label.setVisible(label === nearest));
  }

  private publishDebugState(): void {
    const camera = this.cameras.main;
    setRpgRuntimeDebugState({
      coordinateSystem: "Phaser world coordinates, origin at top-left, x right, y down",
      world: { width: ZIJINGANG_WORLD.width, height: ZIJINGANG_WORLD.height },
      player: {
        x: Math.round(this.player.x),
        y: Math.round(this.player.y),
        facing: this.playerAnimator.facing,
        texture: this.playerAnimator.textureKey,
        turning: this.playerAnimator.isTurning,
        walkFps: RPG_PLAYER_WALK_FPS,
        angle: this.player.angle,
        normalizedDepth: Number(this.playerPerspective.normalizedDepth.toFixed(3)),
        perspectiveMultiplier: Number(this.playerPerspective.perspectiveMultiplier.toFixed(3)),
        displayScale: Number(this.playerPerspective.displayScale.toFixed(3)),
        displayWidth: Math.round(this.playerPerspective.displayWidth),
        displayHeight: Math.round(this.playerPerspective.displayHeight),
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
        scrollX: Math.round(camera.scrollX),
        scrollY: Math.round(camera.scrollY),
        zoom: Number(camera.zoom.toFixed(2)),
        mode: this.cameraController.manualMode ? "manual" : "follow"
      },
      path: {
        followingPath: this.movement.followingPath,
        pathLength: this.currentPathLength
      }
    });
  }

  private addObstacle(x: number, y: number, width: number, height: number): void {
    const collision = this.add.rectangle(x, y, width, height, 0x000000, 0).setDepth(y - 10);
    this.obstacles.add(collision);
  }

}
