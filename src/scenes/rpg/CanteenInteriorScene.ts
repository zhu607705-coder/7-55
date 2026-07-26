import Phaser from "phaser";
import canteenInteriorMapUrl from "../../assets/rpg/interiors/canteen_interior.png";
import type { GameSubtitleTone } from "../../components/GameSubtitleFrame";
import type { CanteenExitId, CanteenMode, GameState } from "../../core/types";
import canteenContent from "../../data/chapter3-canteen.content.json";
import { CANTEEN_EXIT_SEQUENCE } from "../../modules/ChapterThreeCanteenController";
import type { RpgBridge } from "./RpgBridge";
import { formatRpgInteractionHint } from "./RpgControlHints";
import { RPG_HUD_LAYOUT } from "./RpgHudLayout";
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
  CANTEEN_BLOCK_SPAWNS,
  CANTEEN_CARTS,
  CANTEEN_ESCAPE_ANCHORS,
  CANTEEN_INTERACTION_TARGETS,
  CANTEEN_INTERIOR_WORLD,
  CANTEEN_OCCLUSION_RECTS,
  CANTEEN_PHASE_SPAWNS,
  CANTEEN_SPAWN,
  CANTEEN_STATIC_COLLISION_RECTS,
  CANTEEN_TRAYS,
  findNearestCanteenTarget,
  type CanteenInteractionTarget
} from "./CanteenInteriorModel";

const CANTEEN_MAP_KEY = "chapter-3-canteen-interior-map";
const CANTEEN_TRAY_KEY = "chapter-3-canteen-tray";
const CANTEEN_CART_FRAME_KEYS = [
  "chapter-3-canteen-cart-0",
  "chapter-3-canteen-cart-1",
  "chapter-3-canteen-cart-2",
  "chapter-3-canteen-cart-3"
] as const;
const CANTEEN_PAPER_KEY = "chapter-3-canteen-paper";
const WALK_SPEED = 165;
const RUN_SPEED = 228;
const DIALOGUE_STEP_MS = 2500;
const ENTRY_DIALOGUE_STEP_MS = 1600;
const CART_APPROACH_SPEED = 175;
const CART_MIN_ROLL_DURATION_MS = 520;
const CART_ROLL_FRAME_MS = 82;

interface TrayVisual {
  container: Phaser.GameObjects.Container;
  glow: Phaser.GameObjects.Arc;
}

interface OcclusionVisual {
  id: string;
  bounds: Phaser.Geom.Rectangle;
  sortY: number;
  image: Phaser.GameObjects.Image;
}

export class CanteenInteriorScene extends Phaser.Scene {
  private bridge!: RpgBridge;
  private player!: Phaser.Physics.Arcade.Sprite;
  private playerAnimator!: RpgPlayerAnimator;
  private obstacles!: Phaser.Physics.Arcade.StaticGroup;
  private cursors!: Phaser.Types.Input.Keyboard.CursorKeys;
  private keys!: Record<"W" | "A" | "S" | "D" | "SHIFT" | "TAB", Phaser.Input.Keyboard.Key>;
  private virtualDirection = { x: 0, y: 0 };
  private interactRequested = false;
  private promptText!: Phaser.GameObjects.Text;
  private darkOverlay!: Phaser.GameObjects.Rectangle;
  private modeFibers: Phaser.GameObjects.Arc[] = [];
  private trayVisuals = new Map<string, TrayVisual>();
  private cartVisuals = new Map<CanteenExitId, Phaser.GameObjects.Image>();
  private cartBlockers = new Map<CanteenExitId, Phaser.GameObjects.Rectangle>();
  private exitGlows = new Map<CanteenExitId, Phaser.GameObjects.Arc>();
  private paper!: Phaser.GameObjects.Image;
  private menuPanel: Phaser.GameObjects.Container | null = null;
  private currentMode: CanteenMode = "light";
  private currentPhase: GameState["canteenHunt"]["phase"] = "tray_search";
  private dialogueLocked = false;
  private paperBusy = false;
  private cartPushBusy = false;
  private cartMotionExit: CanteenExitId | null = null;
  private cartMotionVector = new Phaser.Math.Vector2();
  private reducedMotion = false;
  private occlusionVisuals: OcclusionVisual[] = [];
  private activeOcclusionIds: string[] = [];
  private softenedOcclusionIds: string[] = [];

  constructor() {
    super("canteen-interior");
  }

  preload(): void {
    if (!this.textures.exists(CANTEEN_MAP_KEY)) {
      this.load.image(CANTEEN_MAP_KEY, canteenInteriorMapUrl);
    }
    preloadRpgPlayerTextures(this);
  }

  create(): void {
    this.bridge = this.registry.get("rpgBridge") as RpgBridge;
    this.reducedMotion = window.matchMedia?.("(prefers-reduced-motion: reduce)").matches === true;
    this.currentMode = this.bridge.getState().canteenHunt.mode;
    this.currentPhase = this.bridge.getState().canteenHunt.phase;
    this.cameras.main.setBackgroundColor(0x0b0d0f);
    this.physics.world.setBounds(28, 16, CANTEEN_INTERIOR_WORLD.width - 56, CANTEEN_INTERIOR_WORLD.height - 34);
    this.obstacles = this.physics.add.staticGroup();
    this.drawInterior();
    this.ensureCanteenTextures();
    ensureRpgPlayerTextures(this);

    const spawn = this.currentPhase === "menu_order"
      ? CANTEEN_PHASE_SPAWNS.menu_order
      : this.currentPhase === "pickup_search"
        ? CANTEEN_PHASE_SPAWNS.pickup_search
        : this.currentPhase === "exit_blocking"
          ? CANTEEN_BLOCK_SPAWNS[Math.min(2, this.bridge.getState().canteenHunt.blockHits)]
          : CANTEEN_SPAWN;
    this.player = this.physics.add.sprite(spawn.x, spawn.y, "act1-player-up-0");
    this.player.setCollideWorldBounds(true).setDepth(spawn.y + 120);
    configureRpgPlayerSprite(this.player);
    this.playerAnimator = new RpgPlayerAnimator(this.player, "up");
    this.physics.add.collider(this.player, this.obstacles);

    this.cursors = this.input.keyboard!.createCursorKeys();
    this.keys = this.input.keyboard!.addKeys("W,A,S,D,SHIFT,TAB") as Record<
      "W" | "A" | "S" | "D" | "SHIFT" | "TAB",
      Phaser.Input.Keyboard.Key
    >;
    this.input.keyboard!.addCapture(Phaser.Input.Keyboard.KeyCodes.TAB);
    this.input.keyboard!.addCapture(Phaser.Input.Keyboard.KeyCodes.SPACE);
    const requestKeyboardInteraction = (event: KeyboardEvent) => {
      event.preventDefault();
      if (!event.repeat) this.interactRequested = true;
    };
    this.input.keyboard!.on("keydown-SPACE", requestKeyboardInteraction);
    this.events.once(Phaser.Scenes.Events.SHUTDOWN, () => {
      this.input.keyboard?.off("keydown-SPACE", requestKeyboardInteraction);
    });
    this.input.on("pointerdown", (pointer: Phaser.Input.Pointer) => this.handleMenuPointer(pointer));

    this.cameras.main
      .setBounds(0, 0, CANTEEN_INTERIOR_WORLD.width, CANTEEN_INTERIOR_WORLD.height)
      .setZoom(1)
      .centerOn(835, 470);

    this.createTrays();
    this.createCarts();
    this.createPickupWindowSigns();
    this.createPaper();
    this.createWorldHotspots();
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
    if (this.bridge.getState().canteenHunt.active && this.currentPhase === "tray_search") {
      this.queueDialogue(canteenContent.entryDialogue, () => {
        this.dialogueLocked = false;
      }, ENTRY_DIALOGUE_STEP_MS);
    }
  }

  update(): void {
    const state = this.bridge.getState();
    this.syncWorldFromState(state);

    if (Phaser.Input.Keyboard.JustDown(this.keys.TAB) && !this.menuPanel && !this.dialogueLocked) {
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
    const movementAllowed = state.actOne.movementEnabled
      && !this.dialogueLocked
      && !this.menuPanel
      && !this.paperBusy
      && !this.cartPushBusy;
    if (movementAllowed && vector.lengthSq() > 0) {
      vector.normalize().scale(this.keys.SHIFT.isDown ? RUN_SPEED : WALK_SPEED);
    } else {
      vector.set(0, 0);
    }
    this.player.setVelocity(vector.x, vector.y).setDepth(this.player.y + 120);
    this.playerAnimator.update(
      this.cartPushBusy && this.cartMotionVector.lengthSq() > 0 ? this.cartMotionVector : vector,
      this.time.now
    );
    this.updateOcclusion();

    const activeTargets = this.getActiveTargets(state);
    const nearest = findNearestCanteenTarget(this.player.x, this.player.y, activeTargets);
    this.updatePrompt(nearest, state);
    this.publishDebugState(nearest, state);

    const keyboardInteract = Phaser.Input.Keyboard.JustDown(this.cursors.space);
    if (nearest && !this.dialogueLocked && !this.menuPanel && !this.paperBusy && !this.cartPushBusy && (keyboardInteract || this.interactRequested)) {
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

  private ensureCanteenTextures(): void {
    if (!this.textures.exists(CANTEEN_TRAY_KEY)) {
      const g = this.add.graphics();
      g.fillStyle(0x172028, 0.34).fillEllipse(18, 14, 36, 10);
      g.fillStyle(0xaab5b8).fillRoundedRect(2, 2, 32, 18, 4);
      g.fillStyle(0xe7ece9).fillRoundedRect(5, 5, 26, 12, 3);
      g.lineStyle(2, 0x657278).strokeRoundedRect(2, 2, 32, 18, 4);
      g.generateTexture(CANTEEN_TRAY_KEY, 36, 24);
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
      g.fillStyle(0x142a44, 0.3).fillEllipse(18, 26, 34, 10);
      g.fillStyle(0xe8edf1).fillPoints([
        new Phaser.Geom.Point(4, 4),
        new Phaser.Geom.Point(31, 8),
        new Phaser.Geom.Point(27, 30),
        new Phaser.Geom.Point(7, 27)
      ], true);
      g.lineStyle(2, 0x58c7ff, 0.95).strokePoints([
        new Phaser.Geom.Point(4, 4),
        new Phaser.Geom.Point(31, 8),
        new Phaser.Geom.Point(27, 30),
        new Phaser.Geom.Point(7, 27)
      ], true);
      g.lineStyle(2, 0x5f7180, 0.75).lineBetween(10, 12, 25, 15).lineBetween(9, 18, 23, 21);
      g.generateTexture(CANTEEN_PAPER_KEY, 36, 34);
      g.destroy();
    }
  }

  private createTrays(): void {
    CANTEEN_TRAYS.forEach((tray) => {
      const glow = this.add.circle(0, 0, 23, 0x2aaeff, 0.18)
        .setStrokeStyle(4, 0x7ad8ff, 0.95)
        .setVisible(false);
      const image = this.add.image(0, 0, CANTEEN_TRAY_KEY);
      const container = this.add.container(tray.x, tray.y, [glow, image])
        .setDepth(tray.y + 30)
        .setSize(46, 40)
        .setInteractive({ useHandCursor: true });
      container.on("pointerdown", () => {
        const target = CANTEEN_INTERACTION_TARGETS.find((candidate) => candidate.id === tray.id);
        if (target) this.triggerPointerTarget(target);
      });
      this.trayVisuals.set(tray.id, { container, glow });
      this.tweens.add({
        targets: glow,
        scale: { from: 0.82, to: 1.16 },
        alpha: { from: 0.42, to: 0.92 },
        duration: 800,
        yoyo: true,
        repeat: -1,
        ease: "Sine.easeInOut"
      });
    });
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
      // The visual cart rolls freely. Once parked, its lower frame becomes a
      // real obstacle so the player cannot walk through a sealed exit.
      const blocker = this.add.rectangle(x, y + 17, 82, 34, 0x000000, 0)
        .setDepth(-900)
        .setVisible(false);
      this.obstacles.add(blocker);
      const blockerBody = blocker.body as Phaser.Physics.Arcade.StaticBody | null;
      if (blockerBody) blockerBody.enable = false;
      this.applyCartOrientation(cart, definition);
      cart.on("pointerdown", () => {
        const target = CANTEEN_INTERACTION_TARGETS.find((candidate) => candidate.id === `cart_${exitId}`);
        if (target) this.triggerPointerTarget(target);
      });
      this.cartVisuals.set(exitId, cart);
      this.cartBlockers.set(exitId, blocker);
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
    [
      { number: "1", x: 654 },
      { number: "2", x: 815 },
      { number: "3", x: 978 }
    ].forEach(({ number, x }) => {
      const plate = this.add.rectangle(0, 0, 118, 42, 0x173544, 0.98)
        .setStrokeStyle(3, 0xe2c866, 0.96);
      const badge = this.add.rectangle(-43, 0, 27, 28, 0xe2c866, 1)
        .setStrokeStyle(2, 0x3b3013, 1);
      const digit = this.add.text(-43, 0, number, {
        color: "#172128",
        fontFamily: "monospace",
        fontSize: "21px",
        fontStyle: "bold"
      }).setOrigin(0.5);
      const label = this.add.text(20, 0, "号窗口", {
        color: "#fff7df",
        fontFamily: "monospace",
        fontSize: "17px",
        fontStyle: "bold"
      }).setOrigin(0.5);
      this.add.container(x, 678, [plate, badge, digit, label])
        .setDepth(1705)
        .setSize(124, 48);
    });
  }

  private createPaper(): void {
    this.paper = this.add.image(978, 637, CANTEEN_PAPER_KEY)
      .setDepth(2100)
      .setVisible(false);
    this.tweens.add({
      targets: this.paper,
      y: "+=8",
      angle: { from: -4, to: 4 },
      duration: 800,
      yoyo: true,
      repeat: -1,
      ease: "Sine.easeInOut"
    });
  }

  private createWorldHotspots(): void {
    const hotspotBounds: Record<string, { x: number; y: number; width: number; height: number }> = {
      ordering_kiosk: { x: 260, y: 760, width: 420, height: 160 },
      pickup_window_1: { x: 654, y: 746, width: 145, height: 150 },
      pickup_window_2: { x: 815, y: 746, width: 145, height: 150 },
      pickup_window_3: { x: 978, y: 746, width: 145, height: 150 },
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
      { x: 296, y: 282 }, { x: 750, y: 510 }, { x: 1132, y: 636 },
      { x: 978, y: 640 }, { x: 82, y: 250 }, { x: 1380, y: 850 }, { x: 1235, y: 227 }
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
      backgroundColor: "#10231fee",
      fontFamily: "monospace",
      fontSize: "13px",
      padding: { x: 9, y: 5 }
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
    if (name === "rpg_canteen_toggle_mode") {
      this.requestModeToggle();
      return;
    }
    if (name === "canteen_mode_changed") {
      this.playModeTransition(String(payload?.mode) === "dark" ? "dark" : "light");
      return;
    }
    if (name === "canteen_tray_identified") {
      this.showFeedback(canteenContent.tray.glowing, "system");
      return;
    }
    if (name === "canteen_tray_unidentified") {
      this.showFeedback(canteenContent.tray.wrongReturn, "system");
      return;
    }
    if (name === "canteen_tray_rejected") {
      this.showFeedback(canteenContent.tray.ordinary, "system");
      return;
    }
    if (name === "canteen_tray_hit_student") {
      this.showFeedback(canteenContent.tray.studentHit, "system");
      return;
    }
    if (name === "canteen_tray_returned") {
      const trayId = String(payload?.trayId ?? "");
      this.animateTrayReturn(trayId, Number(payload?.count) || 0);
      return;
    }
    if (name === "canteen_trays_completed") {
      this.queueDialogue(canteenContent.tray.completionDialogue);
      return;
    }
    if (name === "canteen_menu_dark_clue_read") {
      this.showFeedback(canteenContent.menu.darkClueRead, "task");
      return;
    }
    if (name === "canteen_menu_order_locked") {
      this.showFeedback(canteenContent.menu.orderLocked, "task");
      return;
    }
    if (name === "canteen_order_wrong") {
      const optionId = String(payload?.optionId ?? "");
      this.closeMenuPanel();
      this.queueDialogue(optionId === "A" ? canteenContent.menu.wrongA : canteenContent.menu.wrongGeneric);
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
      this.showFeedback(canteenContent.pickup.darkClueRead, "task");
      return;
    }
    if (name === "canteen_pickup_dark_clue_missed") {
      this.showFeedback(canteenContent.pickup.ticketBack, "system");
      return;
    }
    if (name === "canteen_pickup_order_locked") {
      this.showFeedback(canteenContent.pickup.orderLocked, "task");
      return;
    }
    if (name === "canteen_pickup_wrong") {
      const windowId = String(payload?.windowId ?? "");
      this.queueDialogue(windowId === "1" ? canteenContent.pickup.window1 : canteenContent.pickup.window2);
      return;
    }
    if (name === "canteen_pickup_solved") {
      this.animatePaperBurst();
      return;
    }
    if (name === "canteen_exit_dark_clue_read") {
      this.showFeedback(canteenContent.blocking.darkClueRead, "task");
      return;
    }
    if (name === "canteen_exit_dark_clue_missed") {
      this.showFeedback(canteenContent.blocking.darkClueMissed, "system");
      return;
    }
    if (name === "canteen_exit_block_unidentified") {
      this.showFeedback(canteenContent.blocking.orderLocked, "task");
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
    if (this.cartPushBusy) return;
    const state = this.bridge.getState();
    if (!["tray_search", "menu_order", "pickup_search", "exit_blocking"].includes(state.canteenHunt.phase)) return;
    const mode: CanteenMode = state.canteenHunt.mode === "light" ? "dark" : "light";
    this.bridge.emit("rpg_canteen_mode_requested", { mode });
  }

  private playModeTransition(mode: CanteenMode): void {
    this.currentMode = mode;
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
    if (state.canteenHunt.phase === "tray_search") {
      return CANTEEN_INTERACTION_TARGETS.filter((target) => target.kind === "tray");
    }
    if (state.canteenHunt.phase === "menu_order") {
      return CANTEEN_INTERACTION_TARGETS.filter((target) => target.kind === "kiosk");
    }
    if (state.canteenHunt.phase === "pickup_search") {
      return CANTEEN_INTERACTION_TARGETS.filter((target) => target.kind === "pickup");
    }
    if (state.canteenHunt.phase === "exit_blocking") {
      return CANTEEN_INTERACTION_TARGETS.filter((target) => (
        target.kind === "cart"
        && CANTEEN_EXIT_SEQUENCE.indexOf(String(target.value) as CanteenExitId) >= state.canteenHunt.blockHits
      ));
    }
    return [];
  }

  private triggerTarget(target: CanteenInteractionTarget, state: GameState): void {
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
      this.bridge.emit("rpg_canteen_leave_requested");
    }
  }

  private triggerPointerTarget(target: CanteenInteractionTarget): void {
    const state = this.bridge.getState();
    if (this.dialogueLocked || this.menuPanel || this.paperBusy || this.cartPushBusy) return;
    if (!this.getActiveTargets(state).some((candidate) => candidate.id === target.id)) return;
    if (!findNearestCanteenTarget(this.player.x, this.player.y, [target])) return;
    this.triggerTarget(target, state);
  }

  private triggerTrayById(trayId: string): void {
    const state = this.bridge.getState();
    if (state.canteenHunt.phase !== "tray_search" || this.dialogueLocked) return;
    const definition = CANTEEN_TRAYS.find((tray) => tray.id === trayId);
    if (!definition) return;
    this.bridge.emit("rpg_canteen_tray_requested", {
      trayId,
      queueCollision: definition.queueCollision === true
    });
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
    const definition = CANTEEN_CARTS[exitId];
    this.syncCartBlocker(exitId, definition.x, definition.y, false);
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

    const playerBody = this.player.body as Phaser.Physics.Arcade.Body | null;
    if (playerBody) playerBody.enable = false;
    this.syncCartBlocker(exitId, cart.x, cart.y, false);
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
      onUpdate: () => this.player.setDepth(this.player.y + 120),
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
        this.player.setDepth(this.player.y + 120);
      },
      onComplete: () => {
        this.placeCart(exitId, targetX, targetY, 0);
        this.player.setPosition(targetX + definition.handleOffsetX, targetY + definition.handleOffsetY)
          .setDepth(this.player.y + 120);
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
      playerBody.enable = true;
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

  private syncCartBlocker(exitId: CanteenExitId, x: number, y: number, enabled: boolean): void {
    const blocker = this.cartBlockers.get(exitId);
    if (!blocker) return;
    blocker.setPosition(x, y + 17);
    const body = blocker.body as Phaser.Physics.Arcade.StaticBody | null;
    if (!body) return;
    body.enable = enabled;
    body.updateFromGameObject();
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
      this.playerAnimator.setFacing("side", deltaX < 0);
      return;
    }
    this.playerAnimator.setFacing(deltaY < 0 ? "up" : "down");
  }

  private updatePrompt(nearest: CanteenInteractionTarget | null, state: GameState): void {
    if (!nearest || this.dialogueLocked || this.menuPanel || this.paperBusy || this.cartPushBusy) {
      this.promptText.setVisible(false);
      return;
    }
    const label = nearest.kind === "tray"
      ? state.canteenHunt.mode === "dark"
        ? "识别餐盘蓝色纸屑"
        : "回收已识别餐盘"
      : nearest.kind === "kiosk"
        ? state.canteenHunt.mode === "dark"
          ? "查看点餐菜单残影"
          : state.canteenHunt.menuDarkClueRead
            ? "站在点餐机下方操作"
            : "先切深色模式查看菜单"
        : nearest.kind === "pickup"
          ? state.canteenHunt.mode === "dark"
            ? `查看${nearest.value}号窗口暗号`
            : state.canteenHunt.pickupDarkClueRead
              ? `在${nearest.value}号窗口核验 0755`
              : "先切深色模式确认窗口"
          : nearest.kind === "exit"
            ? "靠近东南门离开食堂"
            : state.canteenHunt.mode === "dark"
              ? "确认蓝色轨迹指向"
              : state.canteenHunt.identifiedExitIds.includes(String(nearest.value) as CanteenExitId)
                ? "站在餐盘车后方推动"
                : "先切深色模式确认这辆餐车";
    this.promptText.setText(formatRpgInteractionHint(label)).setVisible(true);
  }

  private syncWorldFromState(state: GameState, immediate = false): void {
    if (state.canteenHunt.mode !== this.currentMode) {
      if (immediate) {
        this.currentMode = state.canteenHunt.mode;
        this.darkOverlay?.setAlpha(this.currentMode === "dark" ? 0.56 : 0);
      } else {
        this.playModeTransition(state.canteenHunt.mode);
      }
    }
    this.currentPhase = state.canteenHunt.phase;
    this.trayVisuals.forEach((visual, trayId) => {
      const returned = state.canteenHunt.returnedTrayIds.includes(trayId);
      const definition = CANTEEN_TRAYS.find((tray) => tray.id === trayId);
      visual.container.setVisible(state.canteenHunt.phase === "tray_search" && !returned);
      visual.glow.setVisible(
        state.canteenHunt.phase === "tray_search"
        && state.canteenHunt.mode === "dark"
        && definition?.target === true
        && !returned
      );
    });
    const blocking = state.canteenHunt.phase === "exit_blocking";
    const expectedExit = CANTEEN_EXIT_SEQUENCE[state.canteenHunt.blockHits];
    this.cartVisuals.forEach((cart, exitId) => {
      const index = CANTEEN_EXIT_SEQUENCE.indexOf(exitId);
      const isPlaced = index >= 0 && index < state.canteenHunt.blockHits;
      const isAnimating = this.cartPushBusy && this.cartMotionExit === exitId;
      const definition = CANTEEN_CARTS[exitId];
      if (!isAnimating) {
        this.placeCart(
          exitId,
          isPlaced ? definition.pushToX : definition.x,
          isPlaced ? definition.pushToY : definition.y
        );
      }
      const visible = isAnimating || isPlaced || (blocking && index >= state.canteenHunt.blockHits);
      cart.setVisible(visible);
      this.syncCartBlocker(exitId, cart.x, cart.y, isPlaced && !isAnimating);
    });
    this.exitGlows.forEach((glow, exitId) => glow.setVisible(blocking && state.canteenHunt.mode === "dark" && exitId === expectedExit));
    if (blocking && !this.paper.visible) {
      this.paper.setPosition(836, 470).setVisible(true);
    }
  }

  private animateTrayReturn(trayId: string, count: number): void {
    const visual = this.trayVisuals.get(trayId);
    if (!visual) return;
    this.dialogueLocked = true;
    this.bridge.emit("canteen_tray_slide_started", { trayId });
    this.tweens.add({
      targets: visual.container,
      x: 1215,
      y: 506,
      angle: 10,
      duration: this.reducedMotion ? 120 : 620,
      ease: "Cubic.easeInOut",
      onComplete: () => {
        visual.container.setVisible(false);
        this.dialogueLocked = false;
        this.bridge.emit("canteen_tray_slide_completed", { trayId, count });
        if (count < 3) this.showFeedback(canteenContent.tray.incomplete, "system");
      }
    });
  }

  private openMenuPanel(): void {
    if (this.menuPanel) return;
    const state = this.bridge.getState();
    if (state.canteenHunt.mode === "light" && !state.canteenHunt.menuDarkClueRead) {
      this.showFeedback(canteenContent.menu.orderLocked, "task");
      return;
    }
    const canOrder = state.canteenHunt.mode === "light" && state.canteenHunt.menuDarkClueRead;
    const panel = this.add.container(480, 270).setScrollFactor(0).setDepth(6000);
    const shade = this.add.rectangle(0, 0, 570, 376, 0x081018, 0.97).setStrokeStyle(4, 0xd1b766, 0.95);
    const title = this.add.text(0, -148, state.canteenHunt.mode === "dark" ? canteenContent.menu.darkIntro : canteenContent.menu.lightIntro, {
      color: "#fff7df",
      fontFamily: "monospace",
      fontSize: "20px",
      align: "center"
    }).setOrigin(0.5);
    panel.add([shade, title]);
    canteenContent.menu.options.forEach((option, index) => {
      const y = -94 + index * 55;
      const button = this.add.rectangle(0, y, 430, 42, canOrder ? 0x183f43 : 0x263039, 0.94)
        .setStrokeStyle(2, canOrder ? 0x80d4aa : 0x75818a, 0.9);
      const label = this.add.text(0, y, `${option.id}  ${state.canteenHunt.mode === "dark" ? option.dark : option.light}`, {
        color: state.canteenHunt.mode === "dark" ? "#86dcff" : "#fff7df",
        fontFamily: "monospace",
        fontSize: "18px"
      }).setOrigin(0.5);
      button.setData("optionId", option.id);
      panel.add([button, label]);
    });
    const close = this.add.text(255, -168, "×", {
      color: "#fff7df",
      fontFamily: "monospace",
      fontSize: "28px"
    }).setOrigin(0.5);
    panel.add(close);
    const gateText = state.canteenHunt.mode === "dark"
      ? "观察模式 · 已记录残影后切回浅色"
      : canOrder
        ? "操作模式 · 可以下单"
        : "操作锁定 · 先查看深色残影";
    panel.add(this.add.text(0, 166, gateText, {
      color: canOrder ? "#9af0bd" : "#f0c875",
      fontFamily: "monospace",
      fontSize: "13px"
    }).setOrigin(0.5));
    this.menuPanel = panel;
    this.showFeedback(state.canteenHunt.mode === "dark" ? canteenContent.menu.darkIntro : canteenContent.menu.lightIntro, "system");
    if (state.canteenHunt.mode === "dark") {
      this.bridge.emit("rpg_canteen_menu_clue_requested");
    }
  }

  private handleMenuPointer(pointer: Phaser.Input.Pointer): void {
    if (!this.menuPanel) return;
    const localX = pointer.x - 480;
    const localY = pointer.y - 270;
    if (Math.abs(localX - 255) <= 28 && Math.abs(localY + 168) <= 28) {
      this.closeMenuPanel();
      return;
    }
    const state = this.bridge.getState();
    if (state.canteenHunt.mode !== "light" || !state.canteenHunt.menuDarkClueRead) {
      this.showFeedback(canteenContent.menu.orderLocked, "task");
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
    this.paperBusy = true;
    this.paper.setPosition(978, 637).setScale(0.45).setAlpha(0).setVisible(true);
    this.showFeedback(canteenContent.pickup.window3, "system");
    this.bridge.emit("canteen_paper_burst_started");
    this.tweens.add({
      targets: this.paper,
      x: 836,
      y: 470,
      scale: 1,
      alpha: 1,
      angle: 350,
      duration: this.reducedMotion ? 120 : 680,
      ease: "Back.easeOut",
      onComplete: () => {
        this.paperBusy = false;
        this.bridge.emit("canteen_paper_burst_completed");
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
    setRpgRuntimeDebugState({
      coordinateSystem: "Phaser world coordinates, origin at top-left, x right, y down",
      world: CANTEEN_INTERIOR_WORLD,
      player: {
        x: Math.round(this.player.x),
        y: Math.round(this.player.y),
        facing: this.playerAnimator.facing,
        texture: this.playerAnimator.textureKey,
        turning: this.playerAnimator.isTurning,
        walkFps: RPG_PLAYER_WALK_FPS,
        collisionWidth: Number((this.player.body?.width ?? 0).toFixed(2)),
        collisionHeight: Number((this.player.body?.height ?? 0).toFixed(2))
      },
      camera: {
        scrollX: Math.round(this.cameras.main.scrollX),
        scrollY: Math.round(this.cameras.main.scrollY),
        zoom: Number(this.cameras.main.zoom.toFixed(2)),
        mode: "follow"
      },
      scene: "canteen_interior",
      canteen: {
        phase: state.canteenHunt.phase,
        mode: state.canteenHunt.mode,
        identifiedTrayIds: state.canteenHunt.identifiedTrayIds,
        returnedTrayIds: state.canteenHunt.returnedTrayIds,
        menuDarkClueRead: state.canteenHunt.menuDarkClueRead,
        pickupDarkClueRead: state.canteenHunt.pickupDarkClueRead,
        identifiedExitIds: state.canteenHunt.identifiedExitIds,
        blockHits: state.canteenHunt.blockHits,
        activeTarget: nearest?.id ?? null,
        menuOpen: this.menuPanel !== null,
        dialogueLocked: this.dialogueLocked,
        paperBusy: this.paperBusy,
        activeOcclusionIds: this.activeOcclusionIds,
        softenedOcclusionIds: this.softenedOcclusionIds
      },
      collisionRects: CANTEEN_STATIC_COLLISION_RECTS
    });
  }
}
