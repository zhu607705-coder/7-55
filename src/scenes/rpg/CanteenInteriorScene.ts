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
const CANTEEN_CART_KEY = "chapter-3-canteen-cart";
const CANTEEN_PAPER_KEY = "chapter-3-canteen-paper";
const WALK_SPEED = 165;
const RUN_SPEED = 228;
const DIALOGUE_STEP_MS = 2500;

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
  private exitGlows = new Map<CanteenExitId, Phaser.GameObjects.Arc>();
  private paper!: Phaser.GameObjects.Image;
  private menuPanel: Phaser.GameObjects.Container | null = null;
  private currentMode: CanteenMode = "light";
  private currentPhase: GameState["canteenHunt"]["phase"] = "tray_search";
  private dialogueLocked = false;
  private paperBusy = false;
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
    this.input.on("pointerdown", (pointer: Phaser.Input.Pointer) => this.handleMenuPointer(pointer));

    this.cameras.main
      .setBounds(0, 0, CANTEEN_INTERIOR_WORLD.width, CANTEEN_INTERIOR_WORLD.height)
      .setZoom(1)
      .centerOn(835, 470);

    this.createTrays();
    this.createCarts();
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

    if (this.bridge.getState().canteenHunt.active && this.currentPhase === "tray_search") {
      this.dialogueLocked = true;
      this.cameras.main.pan(835, 470, this.reducedMotion ? 120 : 3200, "Sine.easeInOut");
      this.time.delayedCall(this.reducedMotion ? 140 : 1900, () => {
        this.cameras.main.startFollow(this.player, true, 0.13, 0.13, 0, 24).setDeadzone(250, 150);
      });
      this.queueDialogue(canteenContent.entryDialogue, () => {
        this.dialogueLocked = false;
      });
    } else {
      this.cameras.main.startFollow(this.player, true, 0.13, 0.13, 0, 24).setDeadzone(250, 150);
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
      && !this.paperBusy;
    if (movementAllowed && vector.lengthSq() > 0) {
      vector.normalize().scale(this.keys.SHIFT.isDown ? RUN_SPEED : WALK_SPEED);
    } else {
      vector.set(0, 0);
    }
    this.player.setVelocity(vector.x, vector.y).setDepth(this.player.y + 120);
    this.playerAnimator.update(vector, this.time.now);
    this.updateOcclusion();

    const activeTargets = this.getActiveTargets(state);
    const nearest = findNearestCanteenTarget(this.player.x, this.player.y, activeTargets);
    this.updatePrompt(nearest);
    this.publishDebugState(nearest, state);

    const keyboardInteract = Phaser.Input.Keyboard.JustDown(this.cursors.space);
    if (nearest && !this.dialogueLocked && !this.menuPanel && !this.paperBusy && (keyboardInteract || this.interactRequested)) {
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
    if (!this.textures.exists(CANTEEN_CART_KEY)) {
      const g = this.add.graphics();
      g.fillStyle(0x20282d, 0.3).fillEllipse(24, 36, 46, 10);
      g.fillStyle(0x68767b).fillRect(3, 5, 42, 24);
      g.fillStyle(0xb8c1c0).fillRect(6, 8, 36, 4).fillRect(6, 15, 36, 4).fillRect(6, 22, 36, 4);
      g.lineStyle(3, 0x39464b).strokeRect(3, 5, 42, 24).lineBetween(6, 29, 6, 35).lineBetween(42, 29, 42, 35);
      g.fillStyle(0x22292d).fillCircle(6, 36, 4).fillCircle(42, 36, 4);
      g.generateTexture(CANTEEN_CART_KEY, 48, 41);
      g.destroy();
    }
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
    const cartPositions: Record<CanteenExitId, { x: number; y: number }> = {
      west: { x: 150, y: 287 },
      southeast: { x: 1198, y: 824 },
      steam: { x: 1212, y: 300 }
    };
    (Object.entries(cartPositions) as [CanteenExitId, { x: number; y: number }][]).forEach(([exitId, point]) => {
      const glow = this.add.circle(point.x, point.y, 34, 0x2aaeff, 0.12)
        .setStrokeStyle(4, 0x7ad8ff, 0.9)
        .setDepth(point.y + 19)
        .setVisible(false);
      const cart = this.add.image(point.x, point.y, CANTEEN_CART_KEY)
        .setDepth(point.y + 20)
        .setVisible(false)
        .setInteractive({ useHandCursor: true });
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
    if (name === "canteen_pickup_wrong") {
      const windowId = String(payload?.windowId ?? "");
      this.queueDialogue(windowId === "1" ? canteenContent.pickup.window1 : canteenContent.pickup.window2);
      return;
    }
    if (name === "canteen_pickup_solved") {
      this.animatePaperBurst();
      return;
    }
    if (name === "canteen_exit_block_wrong") {
      this.animateWrongBlock(String(payload?.expected ?? "west") as CanteenExitId);
      return;
    }
    if (name === "canteen_exit_blocked") {
      this.animateCorrectBlock(String(payload?.exitId ?? "west") as CanteenExitId, Number(payload?.blockHits) || 1, false);
      return;
    }
    if (name === "canteen_exit_blocking_completed") {
      this.animateCorrectBlock(String(payload?.exitId ?? "steam") as CanteenExitId, 3, true);
    }
  }

  private requestModeToggle(): void {
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
      return CANTEEN_INTERACTION_TARGETS.filter((target) => target.kind === "cart");
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
        this.showFeedback(
          target.value === "3" ? canteenContent.pickup.darkWindow3 : canteenContent.pickup.ticketBack,
          "system"
        );
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
    if (this.dialogueLocked || this.menuPanel || this.paperBusy) return;
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
    if (state.canteenHunt.phase !== "exit_blocking" || this.paperBusy) return;
    if (state.canteenHunt.mode === "dark") {
      this.showFeedback(canteenContent.blocking.cart, "system");
      return;
    }
    this.bridge.emit("rpg_canteen_exit_block_requested", { exitId });
  }

  private updatePrompt(nearest: CanteenInteractionTarget | null): void {
    if (!nearest || this.dialogueLocked || this.menuPanel || this.paperBusy) {
      this.promptText.setVisible(false);
      return;
    }
    const label = nearest.kind === "tray"
      ? "点击餐盘"
      : nearest.kind === "kiosk"
        ? "点击食堂点餐机"
        : nearest.kind === "pickup"
          ? "按暗号找窗口"
          : nearest.kind === "exit"
            ? "离开食堂"
            : "推动餐盘车封堵";
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
    this.cartVisuals.forEach((cart, exitId) => cart.setVisible(blocking && state.canteenHunt.blockHits <= CANTEEN_EXIT_SEQUENCE.indexOf(exitId)));
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
      const button = this.add.rectangle(0, y, 430, 42, 0x183041, 0.94)
        .setStrokeStyle(2, 0x7aa5b6, 0.9);
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
    this.menuPanel = panel;
    this.showFeedback(state.canteenHunt.mode === "dark" ? canteenContent.menu.darkIntro : canteenContent.menu.lightIntro, "system");
  }

  private handleMenuPointer(pointer: Phaser.Input.Pointer): void {
    if (!this.menuPanel) return;
    const localX = pointer.x - 480;
    const localY = pointer.y - 270;
    if (Math.abs(localX - 255) <= 28 && Math.abs(localY + 168) <= 28) {
      this.closeMenuPanel();
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

  private animateWrongBlock(expectedExit: CanteenExitId): void {
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
        this.paperBusy = false;
      }
    });
  }

  private animateCorrectBlock(exitId: CanteenExitId, blockHits: number, complete: boolean): void {
    if (this.paperBusy) return;
    this.paperBusy = true;
    const anchor = CANTEEN_ESCAPE_ANCHORS[exitId];
    const cart = this.cartVisuals.get(exitId);
    const paperOrigin = { x: this.paper.x, y: this.paper.y };
    if (cart) {
      this.tweens.add({
        targets: cart,
        x: anchor.x,
        y: anchor.y,
        duration: this.reducedMotion ? 100 : 200,
        ease: "Cubic.easeOut"
      });
    }
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
            onComplete: () => { this.paperBusy = false; }
          });
          return;
        }
        this.paperBusy = false;
        this.queueDialogue(canteenContent.blocking.escapeDialogue, () => {
          this.bridge.emit("rpg_canteen_leave_requested");
        });
      }
    });
  }

  private queueDialogue(lines: readonly string[], onComplete?: () => void): void {
    this.dialogueLocked = true;
    lines.forEach((text, index) => {
      this.time.delayedCall(index * DIALOGUE_STEP_MS, () => {
        this.showFeedback(text, this.dialogueToneFor(text));
      });
    });
    this.time.delayedCall(lines.length * DIALOGUE_STEP_MS, () => {
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

  private showFeedback(text: string, tone: GameSubtitleTone): void {
    this.bridge.emit("rpg_subtitle", {
      text,
      tone,
      durationMs: DIALOGUE_STEP_MS - 120
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
