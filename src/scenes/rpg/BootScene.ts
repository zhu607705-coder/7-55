import Phaser from "phaser";
import { selectIdentityReadable } from "../../core/IdentityAccess";
import type { GameState } from "../../core/types";
import actOneContent from "../../data/act-one-bootstrap.content.json";
import canteenContent from "../../data/chapter3-canteen.content.json";
import campusRuntimeData from "../../data/maps/zijingang-campus-runtime.json";
import type { RpgBridge } from "./RpgBridge";
import { clearRpgRuntimeDebugState, setRpgRuntimeDebugState } from "./RpgRuntimeDebug";
import { preloadZijingangWorldAssets, ZIJINGANG_CAMPUS_PLATE_KEY } from "./ZijingangLandmarkAssets";
import { drawZijingangWorld, ZIJINGANG_WORLD } from "./ZijingangWorld";
import { CampusBuildingLayer } from "./CampusBuildings";
import { CampusPathGrid, type CampusPathPoint } from "./CampusPathfinder";
import { RpgMovementController } from "./RpgMovementController";
import { RpgCameraController } from "./RpgCameraController";
import {
  configureRpgPlayerSprite,
  ensureRpgPlayerTextures,
  getRpgPlayerNameOffsetY,
  preloadRpgPlayerTextures,
  RPG_PLAYER_DISPLAY_SCALE,
  RPG_PLAYER_FRAME_HEIGHT,
  RPG_PLAYER_FRAME_WIDTH,
  RPG_PLAYER_WALK_FPS,
  RpgPlayerAnimator
} from "./RpgPlayerTextures";
import { RPG_CONTROL_HINTS, formatRpgInteractionHint } from "./RpgControlHints";
import { subscribeRpgSceneBridge } from "./RpgSceneBridgeSubscription";

const CAMERA_MIN_ZOOM = 0.7;
const CAMERA_MAX_ZOOM = 1.8;
const CAMERA_DEFAULT_ZOOM = 1.1;
const CAMERA_ZOOM_STEP = 0.125;
const CAMERA_FOLLOW_OFFSET_Y = 34;
const RPG_LOGICAL_WIDTH = 960;
const RPG_LOGICAL_HEIGHT = 540;
const CAMERA_DEADZONE_WIDTH_RATIO = 300 / RPG_LOGICAL_WIDTH;
const CAMERA_DEADZONE_HEIGHT_RATIO = 180 / RPG_LOGICAL_HEIGHT;
const MAX_CAMPUS_RENDER_SCALE = 3;

const CANTEEN_HUNT_SPAWN = campusRuntimeData.canteen.huntSpawn;
const CANTEEN_GATE = campusRuntimeData.canteen.gate;
const CANTEEN_APPROACH = campusRuntimeData.canteen.approach;
const CANTEEN_BIKE = campusRuntimeData.canteen.bike;
const CANTEEN_THEATER_JUNCTION = campusRuntimeData.theater.approach;
const THEATER_GATE = campusRuntimeData.theater.gate;
const LIBRARY_GATE = campusRuntimeData.libraryGate;
const LIBRARY_APPROACH = campusRuntimeData.walkability.gateApproach;
const CANTEEN_BIKE_RADIUS = 170;
const CANTEEN_DARK_OVERLAY_COLOR = 0x050b1d;
const CANTEEN_DARK_OVERLAY_ALPHA = 0.7;
const CANTEEN_PLAYER_LIGHT_ALPHA = 0.78;
const CANTEEN_PLAYER_LIGHT_SCALE = 0.62;
const FOOTPRINT_SPACING = 42;
const FOOTPRINT_MESSY_RATIO = 0.82;
const PATH_DOT_RADIUS = 6;
const PATH_ENDPOINT_RADIUS = 14;

type GateVisual = {
  marker: Phaser.GameObjects.Arc;
  prompt: Phaser.GameObjects.Text;
};

export class BootScene extends Phaser.Scene {
  private bridge!: RpgBridge;
  private player!: Phaser.Physics.Arcade.Sprite;
  private obstacles!: Phaser.Physics.Arcade.StaticGroup;
  private buildingLayer!: CampusBuildingLayer;
  private cursors!: Phaser.Types.Input.Keyboard.CursorKeys;
  private keys!: Record<"W" | "A" | "S" | "D" | "SHIFT", Phaser.Input.Keyboard.Key>;
  private virtualDirection = { x: 0, y: 0 };
  private lockedHintShown = false;
  private playerAnimator!: RpgPlayerAnimator;
  private characterName!: Phaser.GameObjects.Text;
  private contextualLandmarkLabels: Phaser.GameObjects.Text[] = [];
  private interactRequested = false;
  private pathGrid!: CampusPathGrid;
  private movement!: RpgMovementController;
  private cameraController!: RpgCameraController;
  private pathIndicatorObjects: Phaser.GameObjects.Arc[] = [];
  private currentPathLength = 0;
  private campusRenderScale = 1;
  private libraryGate!: GateVisual;
  private canteenGate!: GateVisual;
  private theaterGate!: GateVisual;
  private presentedCanteenPhase: GameState["canteenHunt"]["phase"] | "inactive" | null = null;
  private canteenDarkOverlay: Phaser.GameObjects.Rectangle | null = null;
  private canteenPlayerLight: Phaser.GameObjects.Image | null = null;
  private canteenFootprints: Phaser.GameObjects.Image[] = [];
  private canteenBike: Phaser.GameObjects.Image | null = null;
  private canteenBikeHint: Phaser.GameObjects.Text | null = null;
  private canteenBikeCodeGlow: Phaser.GameObjects.Arc | null = null;
  private canteenBikeGlare: Phaser.GameObjects.Rectangle | null = null;

  constructor() {
    super("campus-bootstrap");
  }

  preload(): void {
    preloadZijingangWorldAssets(this);
    preloadRpgPlayerTextures(this);
  }

  create(): void {
    this.campusRenderScale = this.enableNativeCampusResolution();
    this.events.once(Phaser.Scenes.Events.SHUTDOWN, this.restoreLogicalCanvasResolution, this);
    this.bridge = this.registry.get("rpgBridge") as RpgBridge;
    this.physics.world.setBounds(0, 0, ZIJINGANG_WORLD.width, ZIJINGANG_WORLD.height);
    this.cameras.main.setBackgroundColor(0x10171c);
    this.obstacles = this.physics.add.staticGroup();
    drawZijingangWorld(this, {
      addObstacle: (x, y, width, height) => this.addObstacle(x, y, width, height)
    });
    this.contextualLandmarkLabels = this.children.list.filter(
      (object): object is Phaser.GameObjects.Text =>
        object instanceof Phaser.GameObjects.Text && object.getData("contextualLandmark") === true
    );

    this.buildingLayer = new CampusBuildingLayer(this, ZIJINGANG_CAMPUS_PLATE_KEY);
    const buildingOverlays = this.buildingLayer.build();
    this.pathGrid = new CampusPathGrid(campusRuntimeData.walkability, 24);
    ensureRpgPlayerTextures(this);
    const state = this.bridge.getState();
    const spawn = this.resolveSpawn(state);
    this.player = this.physics.add.sprite(spawn.x, spawn.y, "act1-player-down-0");
    this.player.setCollideWorldBounds(true).setDepth(this.player.y + 30);
    configureRpgPlayerSprite(this.player);
    this.playerAnimator = new RpgPlayerAnimator(this.player, "down");
    this.physics.add.collider(this.player, this.obstacles);
    this.characterName = this.add.text(
      this.player.x,
      this.player.y - getRpgPlayerNameOffsetY(),
      "",
      {
        color: "#fff7df",
        backgroundColor: "#17212add",
        fontFamily: "monospace",
        fontSize: "11px",
        padding: { x: 4, y: 2 },
        resolution: Math.max(2, window.devicePixelRatio || 1)
      }
    ).setOrigin(0.5).setDepth(this.player.y + 55).setVisible(false);

    this.cursors = this.input.keyboard!.createCursorKeys();
    this.keys = this.input.keyboard!.addKeys("W,A,S,D,SHIFT") as Record<"W" | "A" | "S" | "D" | "SHIFT", Phaser.Input.Keyboard.Key>;
    this.input.keyboard!.addCapture(Phaser.Input.Keyboard.KeyCodes.SPACE);
    this.movement = new RpgMovementController(this.player, { walkSpeed: 110, runSpeed: 160 });
    this.movement.onPathFinished = () => this.clearPathIndicator();

    this.cameraController = new RpgCameraController(this, {
      player: this.player,
      world: ZIJINGANG_WORLD,
      minZoom: CAMERA_MIN_ZOOM * this.campusRenderScale,
      maxZoom: CAMERA_MAX_ZOOM * this.campusRenderScale,
      defaultZoom: CAMERA_DEFAULT_ZOOM * this.campusRenderScale,
      zoomStep: CAMERA_ZOOM_STEP * this.campusRenderScale,
      deadzoneRatio: {
        width: CAMERA_DEADZONE_WIDTH_RATIO,
        height: CAMERA_DEADZONE_HEIGHT_RATIO
      },
      followOffsetY: CAMERA_FOLLOW_OFFSET_Y,
      minimap: null
    });
    this.cameraController.attach();
    this.cameraController.minimapCamera?.ignore(this.contextualLandmarkLabels);
    this.cameraController.minimapCamera?.ignore(buildingOverlays);
    this.cameraController.onWorldTap = (worldX, worldY) => this.handleWorldTap(worldX, worldY);

    this.libraryGate = this.createGateVisual(
      LIBRARY_GATE,
      `基础图书馆入口  ·  ${RPG_CONTROL_HINTS.libraryGate}`,
      0x1d9b75
    );
    this.canteenGate = this.createGateVisual(
      CANTEEN_GATE,
      `东区大食堂入口  ·  ${formatRpgInteractionHint("进入食堂")}`,
      0x9b7228
    );
    this.theaterGate = this.createGateVisual(
      THEATER_GATE,
      `剧场入口  ·  ${formatRpgInteractionHint("进入剧场")}`,
      0x8d3244
    );
    this.ensureCanteenTextures();
    this.syncCanteenPresentation(state, true);

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
      } else if (event.name === "canteen_mode_changed") {
        this.applyCanteenBikeMode(String(event.payload?.mode) === "dark" ? "dark" : "light");
      } else if (event.name === "canteen_bike_code_read") {
        this.animateCanteenBikeCodeRead();
      } else if (event.name === "canteen_bike_glare_failed") {
        this.showCanteenFeedback(canteenContent.bike.glareFailed, "system");
      } else if (event.name === "canteen_bike_dark_payment_rejected") {
        this.showCanteenFeedback(canteenContent.bike.darkPaymentRejected, "system");
      } else if (event.name === "canteen_bike_scan_rule") {
        return;
      } else if (event.name === "canteen_bike_lock_cleaned") {
        this.animateCanteenBikeCleaned();
      } else if (event.name === "canteen_bike_payment_ready") {
        return;
      } else if (event.name === "canteen_chase_completed") {
        this.player.setPosition(CANTEEN_THEATER_JUNCTION.x, CANTEEN_THEATER_JUNCTION.y);
        this.player.body?.reset(CANTEEN_THEATER_JUNCTION.x, CANTEEN_THEATER_JUNCTION.y);
        this.movement.clearPath();
        this.cameraController.recenter(true);
        this.syncCanteenPresentation(this.bridge.getState(), true);
      }
    }, clearRpgRuntimeDebugState);

    this.syncCharacterNameplate(state);
    this.bridge.emit("rpg_booted", { scene: "campus_bootstrap", projection: "north-up-top-down-2d" });
  }

  update(_time: number, delta: number): void {
    const state = this.bridge.getState();
    this.syncCharacterNameplate(state);
    this.syncCanteenPresentation(state);
    this.updateContextualLandmarkLabel();
    this.updateStoryGates(state);
    this.updateCanteenEffects(state);
    this.publishDebugState();

    const keyboardX = Number(this.cursors.right.isDown || this.keys.D.isDown)
      - Number(this.cursors.left.isDown || this.keys.A.isDown);
    const keyboardY = Number(this.cursors.down.isDown || this.keys.S.isDown)
      - Number(this.cursors.up.isDown || this.keys.W.isDown);
    const x = Phaser.Math.Clamp(keyboardX + this.virtualDirection.x, -1, 1);
    const y = Phaser.Math.Clamp(keyboardY + this.virtualDirection.y, -1, 1);
    this.interactRequested = false;

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
    this.buildingLayer.updateOcclusionForPlayer(
      this.player.x,
      this.player.y,
      this.player.depth
    );
    this.cameraController.update(delta);
  }

  private resolveSpawn(state: GameState): { x: number; y: number } {
    if (state.rpgCheckpoint === "campus_library_gate") return LIBRARY_APPROACH;
    if (state.rpgCheckpoint === "campus_canteen_gate") return CANTEEN_APPROACH;
    if (state.rpgCheckpoint === "campus_theater_junction") return CANTEEN_THEATER_JUNCTION;
    if (state.canteenHunt.active) {
      if (["chase_ready", "chasing"].includes(state.canteenHunt.phase)) return CANTEEN_APPROACH;
      if (state.canteenHunt.phase === "theater_reached") return CANTEEN_THEATER_JUNCTION;
      return CANTEEN_HUNT_SPAWN;
    }
    return ZIJINGANG_WORLD.spawn;
  }

  private createGateVisual(
    gate: { x: number; y: number },
    label: string,
    color: number
  ): GateVisual {
    const marker = this.add.circle(gate.x, gate.y, 24, color, 0.24)
      .setStrokeStyle(5, 0xe6d268, 0.95)
      .setDepth(gate.y + 80)
      .setVisible(false);
    const prompt = this.add.text(gate.x, gate.y - 52, label, {
      color: "#fff7df",
      backgroundColor: "#10231fee",
      fontFamily: "monospace",
      fontSize: "13px",
      padding: { x: 8, y: 5 },
      resolution: Math.max(2, window.devicePixelRatio || 1)
    }).setOrigin(0.5).setDepth(gate.y + 90).setVisible(false);
    this.tweens.add({
      targets: marker,
      scale: { from: 0.86, to: 1.18 },
      alpha: { from: 0.56, to: 1 },
      duration: 720,
      yoyo: true,
      repeat: -1,
      ease: "Sine.easeInOut"
    });
    return { marker, prompt };
  }

  private updateStoryGates(state: GameState): void {
    const libraryAvailable = state.actOne.canLeaveDorm
      && state.ui.libraryFinalsPhase !== "friend_contacted"
      && !state.canteenHunt.active;
    const canteenStoryEntry = state.canteenHunt.active
      && [
        "tracking",
        "canteen_reached",
        "entered",
        "tray_search",
        "drink_mix",
        "menu_order",
        "pickup_search",
        "exit_blocking",
        "chase_ready"
      ].includes(state.canteenHunt.phase);
    const canteenAvailable = canteenStoryEntry || (!state.canteenHunt.active && state.actOne.canLeaveDorm);
    const theaterAvailable = state.canteenHunt.active && state.canteenHunt.phase === "theater_reached";

    if (this.updateGate(this.libraryGate, LIBRARY_GATE, libraryAvailable)) {
      this.bridge.setCheckpoint("campus_library_gate");
      this.bridge.emit("rpg_library_gate_requested", { landmark: "foundation_library" });
    }
    if (this.updateGate(this.canteenGate, CANTEEN_GATE, canteenAvailable)) {
      this.bridge.setCheckpoint("campus_canteen_gate");
      this.bridge.emit("rpg_canteen_entry_requested", { mode: canteenStoryEntry ? "story" : "explore" });
    }
    if (this.updateGate(this.theaterGate, THEATER_GATE, theaterAvailable)) {
      this.bridge.setCheckpoint("campus_theater_junction");
      this.bridge.emit("rpg_theater_entry_requested");
    }
  }

  private updateGate(
    visual: GateVisual,
    gate: { x: number; y: number; radius: number },
    available: boolean
  ): boolean {
    const nearby = available && Phaser.Math.Distance.Between(
      this.player.x,
      this.player.y,
      gate.x,
      gate.y
    ) <= gate.radius;
    visual.marker.setVisible(available);
    visual.prompt.setVisible(nearby);
    return nearby && (
      Phaser.Input.Keyboard.JustDown(this.cursors.space)
      || this.interactRequested
    );
  }

  private syncCanteenPresentation(state: GameState, force = false): void {
    const phase = state.canteenHunt.active ? state.canteenHunt.phase : "inactive";
    if (!force && phase === this.presentedCanteenPhase) return;
    this.clearCanteenPresentation();
    this.presentedCanteenPhase = phase;
    if (!state.canteenHunt.active) return;
    if (["tracking", "canteen_reached"].includes(phase)) {
      this.createCanteenDarkness();
      this.createCanteenFootprintTrail();
    } else if (phase === "chase_ready") {
      this.createCanteenBike();
      this.createCanteenBikeModeLayer(state);
    }
  }

  private clearCanteenPresentation(): void {
    this.canteenDarkOverlay?.destroy();
    this.canteenPlayerLight?.destroy();
    this.canteenBike?.destroy();
    this.canteenBikeHint?.destroy();
    this.canteenBikeCodeGlow?.destroy();
    this.canteenBikeGlare?.destroy();
    this.canteenFootprints.forEach((footprint) => footprint.destroy());
    this.canteenDarkOverlay = null;
    this.canteenPlayerLight = null;
    this.canteenBike = null;
    this.canteenBikeHint = null;
    this.canteenBikeCodeGlow = null;
    this.canteenBikeGlare = null;
    this.canteenFootprints = [];
  }

  private ensureCanteenTextures(): void {
    if (!this.textures.exists("canteen-footprint")) {
      const g = this.add.graphics();
      g.fillStyle(0xcdf3ff, 1).fillEllipse(8, 6, 8, 9).fillEllipse(8, 15, 6, 7);
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
      [20, 70].forEach((wheelX) => {
        g.lineStyle(5, 0x172129, 1).strokeCircle(wheelX, 42, 17);
        g.lineStyle(2, 0xbcc7c7, 0.9).strokeCircle(wheelX, 42, 13);
        g.lineBetween(wheelX - 13, 42, wheelX + 13, 42);
        g.lineBetween(wheelX, 29, wheelX, 55);
      });
      g.lineStyle(6, 0x3e79ae, 1)
        .lineBetween(20, 42, 39, 20)
        .lineBetween(39, 20, 52, 42)
        .lineBetween(52, 42, 20, 42)
        .lineBetween(39, 20, 70, 42)
        .lineBetween(38, 19, 34, 10);
      g.fillStyle(0x26343c, 1).fillRoundedRect(29, 7, 18, 6, 2);
      g.fillStyle(0x26343c, 1).fillRoundedRect(55, 20, 14, 13, 2);
      g.fillStyle(0x73d7f2, 1).fillRect(59, 23, 6, 6);
      g.generateTexture("canteen-bike", 92, 62);
      g.destroy();
    }
  }

  private createCanteenDarkness(): void {
    this.canteenDarkOverlay = this.add.rectangle(
      ZIJINGANG_WORLD.width / 2,
      ZIJINGANG_WORLD.height / 2,
      ZIJINGANG_WORLD.width,
      ZIJINGANG_WORLD.height,
      CANTEEN_DARK_OVERLAY_COLOR,
      CANTEEN_DARK_OVERLAY_ALPHA
    ).setDepth(9000).setAlpha(0);
    this.canteenPlayerLight = this.add.image(this.player.x, this.player.y, "canteen-light")
      .setDepth(9001)
      .setBlendMode(Phaser.BlendModes.ADD)
      .setScale(CANTEEN_PLAYER_LIGHT_SCALE)
      .setAlpha(0);
    this.tweens.add({ targets: this.canteenDarkOverlay, alpha: CANTEEN_DARK_OVERLAY_ALPHA, duration: 800 });
    this.tweens.add({ targets: this.canteenPlayerLight, alpha: CANTEEN_PLAYER_LIGHT_ALPHA, duration: 800 });
  }

  private createCanteenFootprintTrail(): void {
    const path = this.pathGrid.findPath(CANTEEN_HUNT_SPAWN, CANTEEN_APPROACH);
    if (!path || path.length < 2) return;
    const spaced = this.resamplePath(path, FOOTPRINT_SPACING);
    const messStart = Math.floor(spaced.length * FOOTPRINT_MESSY_RATIO);
    spaced.forEach((point, index) => {
      const messy = index >= messStart;
      const side = index % 2 === 0 ? 1 : -1;
      const perpendicularX = Math.cos(point.angle + Math.PI / 2);
      const perpendicularY = Math.sin(point.angle + Math.PI / 2);
      const footprint = this.add.image(
        point.x + perpendicularX * side * 7 + (messy ? Phaser.Math.Between(-18, 18) : 0),
        point.y + perpendicularY * side * 7 + (messy ? Phaser.Math.Between(-12, 12) : 0),
        "canteen-footprint"
      )
        .setRotation(point.angle + Math.PI / 2 + (messy ? Phaser.Math.FloatBetween(-0.8, 0.8) : 0))
        .setAlpha(messy ? 0.45 : 0.84)
        .setTint(0xb6efff)
        .setBlendMode(Phaser.BlendModes.ADD)
        .setDepth(point.y + 4);
      this.canteenFootprints.push(footprint);
    });
  }

  private resamplePath(path: CampusPathPoint[], step: number): Array<{ x: number; y: number; angle: number }> {
    const result: Array<{ x: number; y: number; angle: number }> = [];
    let carry = 0;
    for (let index = 0; index < path.length - 1; index += 1) {
      const start = path[index];
      const end = path[index + 1];
      const dx = end.x - start.x;
      const dy = end.y - start.y;
      const length = Math.hypot(dx, dy);
      if (length === 0) continue;
      const angle = Math.atan2(dy, dx);
      let distance = carry;
      while (distance < length) {
        const progress = distance / length;
        result.push({ x: start.x + dx * progress, y: start.y + dy * progress, angle });
        distance += step;
      }
      carry = distance - length;
    }
    return result;
  }

  private createCanteenBike(): void {
    this.canteenBike = this.add.image(CANTEEN_BIKE.x, CANTEEN_BIKE.y, "canteen-bike")
      .setDepth(CANTEEN_BIKE.y + 6)
      .setInteractive({ useHandCursor: true })
      .on("pointerdown", () => this.requestCanteenBikeIfNearby());
    this.canteenBikeHint = this.add.text(CANTEEN_BIKE.x, CANTEEN_BIKE.y - 58, this.getCanteenBikeWalletHint(), {
      color: "#fff7df",
      backgroundColor: "#241a12ee",
      fontFamily: "monospace",
      fontSize: "12px",
      padding: { x: 7, y: 4 },
      resolution: Math.max(2, window.devicePixelRatio || 1)
    }).setOrigin(0.5).setDepth(CANTEEN_BIKE.y + 12).setVisible(false);
  }

  private createCanteenBikeModeLayer(state: GameState): void {
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
    this.canteenBikeCodeGlow = this.add.circle(CANTEEN_BIKE.x + 18, CANTEEN_BIKE.y - 5, 22, 0x4bc9ff, 0.16)
      .setStrokeStyle(4, 0x88e7ff, 0.95)
      .setDepth(CANTEEN_BIKE.y + 4)
      .setVisible(state.canteenHunt.mode === "dark");
    this.canteenBikeGlare = this.add.rectangle(CANTEEN_BIKE.x + 18, CANTEEN_BIKE.y - 5, 13, 11, 0xffffff, 0.7)
      .setStrokeStyle(2, 0xffedba, 0.9)
      .setRotation(-0.18)
      .setDepth(CANTEEN_BIKE.y + 10)
      .setVisible(state.canteenHunt.mode === "light" && !state.canteenHunt.bikeLockCleaned);
  }

  private updateCanteenEffects(state: GameState): void {
    this.canteenPlayerLight?.setPosition(this.player.x, this.player.y);
    if (state.canteenHunt.phase === "chase_ready" && this.canteenBikeHint) {
      const nearby = Phaser.Math.Distance.Between(this.player.x, this.player.y, CANTEEN_BIKE.x, CANTEEN_BIKE.y) <= CANTEEN_BIKE_RADIUS;
      this.canteenBikeHint.setText(this.getCanteenBikeWalletHint()).setVisible(nearby);
      if (nearby && (Phaser.Input.Keyboard.JustDown(this.cursors.space) || this.interactRequested)) {
        this.requestCanteenBikeIfNearby();
      }
    }
  }

  private getCanteenBikeWalletHint(): string {
    const cashCents = Math.max(0, this.bridge.getState().wallet.cashCents);
    return `${canteenContent.bike.scan}\n${canteenContent.bike.balance.replace("{amount}", (cashCents / 100).toFixed(2))}`;
  }

  private requestCanteenBikeIfNearby(): void {
    if (this.bridge.getState().canteenHunt.phase !== "chase_ready") return;
    if (Phaser.Math.Distance.Between(this.player.x, this.player.y, CANTEEN_BIKE.x, CANTEEN_BIKE.y) > CANTEEN_BIKE_RADIUS) return;
    this.bridge.emit("rpg_canteen_bike_inspect_requested");
  }

  private handleCanteenInventoryDrop(payload?: Record<string, unknown>): void {
    const itemId = String(payload?.itemId ?? "");
    if (this.bridge.getState().canteenHunt.phase !== "chase_ready") {
      this.bridge.emit("rpg_item_use_feedback", {
        itemId,
        reason: "locked",
        targetLabel: "共享单车",
        detail: "共享单车交互尚未开放，请先完成食堂内部流程。"
      });
      return;
    }
    if (itemId !== "cafeteriaWages" && itemId !== "greaseTissue") {
      this.bridge.emit("rpg_item_use_feedback", {
        itemId,
        reason: "wrong_item",
        targetLabel: "共享单车",
        detail: "共享单车当前只接收纸巾或 2 元现金。"
      });
      return;
    }
    const canvasX = Number(payload?.canvasX);
    const canvasY = Number(payload?.canvasY);
    if (!Number.isFinite(canvasX) || !Number.isFinite(canvasY)) {
      this.bridge.emit("rpg_item_use_feedback", { itemId, reason: "missed_target", targetLabel: "共享单车" });
      return;
    }
    const worldPoint = this.cameras.main.getWorldPoint(canvasX, canvasY);
    if (Phaser.Math.Distance.Between(worldPoint.x, worldPoint.y, CANTEEN_BIKE.x, CANTEEN_BIKE.y) <= 100) {
      this.bridge.emit(itemId === "greaseTissue" ? "rpg_canteen_bike_tissue_requested" : "rpg_canteen_bike_requested");
      return;
    }
    this.bridge.emit("rpg_item_use_feedback", {
      itemId,
      reason: "missed_target",
      targetLabel: "共享单车",
      detail: "松手点没有进入共享单车车身的高亮范围。"
    });
  }

  private applyCanteenBikeMode(mode: GameState["canteenHunt"]["mode"]): void {
    const duration = window.matchMedia?.("(prefers-reduced-motion: reduce)").matches ? 120 : 420;
    if (this.canteenDarkOverlay) {
      this.tweens.add({ targets: this.canteenDarkOverlay, alpha: mode === "dark" ? CANTEEN_DARK_OVERLAY_ALPHA : 0, duration });
    }
    if (this.canteenPlayerLight) {
      this.tweens.add({ targets: this.canteenPlayerLight, alpha: mode === "dark" ? CANTEEN_PLAYER_LIGHT_ALPHA : 0, duration });
    }
    this.canteenBikeCodeGlow?.setVisible(mode === "dark");
    this.canteenBikeGlare?.setVisible(mode === "light" && !this.bridge.getState().canteenHunt.bikeLockCleaned);
  }

  private animateCanteenBikeCodeRead(): void {
    this.showCanteenFeedback(canteenContent.bike.codeVisible, "system");
    if (this.canteenBikeCodeGlow) {
      this.tweens.add({ targets: this.canteenBikeCodeGlow, scale: 1.34, duration: 170, yoyo: true, repeat: 1 });
    }
  }

  private animateCanteenBikeCleaned(): void {
    this.showCanteenFeedback(canteenContent.bike.lockCleaned, "success");
    if (this.canteenBikeGlare) {
      this.tweens.add({
        targets: this.canteenBikeGlare,
        x: CANTEEN_BIKE.x + 28,
        alpha: 0,
        duration: 360,
        onComplete: () => this.canteenBikeGlare?.setVisible(false)
      });
    }
  }

  private showCanteenFeedback(text: string, tone: "system" | "success"): void {
    this.bridge.emit("rpg_subtitle", { text, tone, durationMs: 3200 });
  }

  private handleWorldTap(worldX: number, worldY: number): void {
    if (!this.bridge.getState().actOne.movementEnabled) return;
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
      ).setStrokeStyle(isEndpoint ? 4 : 2, 0xe6d268, isEndpoint ? 0.95 : 0.8).setDepth(point.y + 3);
      this.pathIndicatorObjects.push(dot);
    });
  }

  private showUnreachableMarker(x: number, y: number): void {
    const marker = this.add.circle(x, y, 16, 0x8d3244, 0.24)
      .setStrokeStyle(4, 0xff8e7a, 0.95)
      .setDepth(y + 3);
    this.tweens.add({ targets: marker, alpha: 0, scale: 1.5, duration: 520, onComplete: () => marker.destroy() });
  }

  private clearPathIndicator(): void {
    this.pathIndicatorObjects.forEach((object) => object.destroy());
    this.pathIndicatorObjects = [];
    this.currentPathLength = 0;
  }

  private updateContextualLandmarkLabel(): void {
    let nearest: Phaser.GameObjects.Text | undefined;
    let nearestDistance = Number.POSITIVE_INFINITY;
    this.contextualLandmarkLabels.forEach((label) => {
      const distance = Phaser.Math.Distance.Between(
        this.player.x,
        this.player.y,
        Number(label.getData("anchorX")),
        Number(label.getData("anchorY"))
      );
      if (distance <= Number(label.getData("revealRadius")) && distance < nearestDistance) {
        nearest = label;
        nearestDistance = distance;
      }
    });
    this.contextualLandmarkLabels.forEach((label) => label.setVisible(label === nearest));
  }

  private syncCharacterNameplate(state: GameState): void {
    const readable = selectIdentityReadable(state);
    this.characterName
      .setText(readable && state.actOne.characterNamed ? actOneContent.studentName : "")
      .setVisible(readable && state.actOne.characterNamed)
      .setPosition(this.player.x, this.player.y - getRpgPlayerNameOffsetY())
      .setDepth(this.player.y + 72);
  }

  private publishDebugState(): void {
    const camera = this.cameras.main;
    setRpgRuntimeDebugState({
      coordinateSystem: "Phaser world coordinates, origin at top-left, x right, y down",
      world: ZIJINGANG_WORLD,
      player: {
        x: Math.round(this.player.x),
        y: Math.round(this.player.y),
        facing: this.playerAnimator.facing,
        texture: this.playerAnimator.textureKey,
        turning: this.playerAnimator.isTurning,
        walkFps: RPG_PLAYER_WALK_FPS,
        angle: this.player.angle,
        normalizedDepth: 0,
        perspectiveMultiplier: 1,
        displayScale: RPG_PLAYER_DISPLAY_SCALE,
        displayWidth: Math.round(RPG_PLAYER_FRAME_WIDTH * RPG_PLAYER_DISPLAY_SCALE),
        displayHeight: Math.round(RPG_PLAYER_FRAME_HEIGHT * RPG_PLAYER_DISPLAY_SCALE),
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
      path: { followingPath: this.movement.followingPath, pathLength: this.currentPathLength },
      scene: "campus_bootstrap",
      checkpoint: this.bridge.getState().rpgCheckpoint
    });
  }

  private addObstacle(x: number, y: number, width: number, height: number): void {
    const collision = this.add.rectangle(x, y, width, height, 0x000000, 0).setDepth(y - 10);
    this.obstacles.add(collision);
  }

  private enableNativeCampusResolution(): number {
    const bounds = this.game.canvas.getBoundingClientRect();
    this.game.canvas.style.imageRendering = "auto";
    const deviceScale = Math.max(1, window.devicePixelRatio || 1);
    const displayScale = Math.min(bounds.width / RPG_LOGICAL_WIDTH, bounds.height / RPG_LOGICAL_HEIGHT);
    const renderScale = Phaser.Math.Clamp(Math.max(1, displayScale * deviceScale), 1, MAX_CAMPUS_RENDER_SCALE);
    this.scale.setGameSize(
      Math.round(RPG_LOGICAL_WIDTH * renderScale),
      Math.round(RPG_LOGICAL_HEIGHT * renderScale)
    );
    return renderScale;
  }

  private restoreLogicalCanvasResolution(): void {
    this.clearCanteenPresentation();
    this.scale.setGameSize(RPG_LOGICAL_WIDTH, RPG_LOGICAL_HEIGHT);
    this.game.canvas.style.imageRendering = "";
    this.campusRenderScale = 1;
  }
}
