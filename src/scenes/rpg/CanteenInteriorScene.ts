import Phaser from "phaser";
import canteenInteriorMapUrl from "../../assets/rpg/interiors/canteen_interior.png";
import canteenCounterAuntiesSheetUrl from "../../assets/rpg/npcs/canteen/counter_aunties_2frame.png";
import canteenQueueStudentsSheetUrl from "../../assets/rpg/npcs/canteen/queue_students_2frame.png";
import canteenReturnAuntieSheetUrl from "../../assets/rpg/npcs/canteen/return_auntie_2frame.png";
import canteenSeatedStudentsExtraSheetUrl from "../../assets/rpg/npcs/canteen/seated_students_extra_2frame.png";
import canteenSeatedStudentsSheetUrl from "../../assets/rpg/npcs/canteen/seated_students_2frame.png";
import canteenShadowAuntieSheetUrl from "../../assets/rpg/npcs/canteen/shadow_auntie_3frame.png";
import playerPushCartSheetUrl from "../../assets/rpg/player/player_push_cart_sheet.png";
import type { GameSubtitleTone } from "../../components/GameSubtitleFrame";
import type { CanteenExitId, CanteenMode, GameState, ItemId } from "../../core/types";
import canteenContent from "../../data/chapter3-canteen.content.json";
import { CANTEEN_EXIT_SEQUENCE } from "../../modules/ChapterThreeCanteenController";
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
import { subscribeRpgSceneBridge } from "./RpgSceneBridgeSubscription";
import {
  CanteenDefenseRuntime,
  type CanteenDefenseExitId
} from "./CanteenDefenseRuntime";
import {
  CANTEEN_BLOCK_SPAWNS,
  CANTEEN_CARTS,
  CANTEEN_ESCAPE_ANCHORS,
  CANTEEN_INTERACTION_TARGETS,
  CANTEEN_INTERIOR_WORLD,
  CANTEEN_OCCLUSION_RECTS,
  CANTEEN_PHASE_SPAWNS,
  CANTEEN_PICKUP_WINDOWS,
  CANTEEN_SPAWN,
  CANTEEN_STATIC_COLLISION_RECTS,
  CANTEEN_TRAYS,
  findNearestCanteenTarget,
  type CanteenInteractionTarget
} from "./CanteenInteriorModel";

const CANTEEN_MAP_KEY = "chapter-3-canteen-interior-map";
const CANTEEN_PUSH_CART_SHEET_KEY = "chapter-3-canteen-player-push-cart";
const CANTEEN_QUEUE_NPC_SHEET_KEY = "chapter-3-canteen-queue-npcs";
const CANTEEN_COUNTER_NPC_SHEET_KEY = "chapter-3-canteen-counter-npcs";
const CANTEEN_SEATED_NPC_SHEET_KEY = "chapter-3-canteen-seated-npcs";
const CANTEEN_SEATED_EXTRA_NPC_SHEET_KEY = "chapter-3-canteen-seated-extra-npcs";
const CANTEEN_RETURN_NPC_SHEET_KEY = "chapter-3-canteen-return-npc";
const CANTEEN_SHADOW_NPC_SHEET_KEY = "chapter-3-canteen-shadow-npc";
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

export class CanteenInteriorScene extends Phaser.Scene {
  private bridge!: RpgBridge;
  private player!: Phaser.Physics.Arcade.Sprite;
  private playerAnimator!: RpgPlayerAnimator;
  private playerCollisionDebug: Phaser.GameObjects.Rectangle | null = null;
  private obstacles!: Phaser.Physics.Arcade.StaticGroup;
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
  private pickupWindowVisuals = new Map<string, PickupWindowVisual>();
  private cartVisuals = new Map<CanteenExitId, Phaser.GameObjects.Image>();
  private exitGlows = new Map<CanteenExitId, Phaser.GameObjects.Arc>();
  private paper!: Phaser.GameObjects.Image;
  private paperFloatTween!: Phaser.Tweens.Tween;
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

  preload(): void {
    if (!this.textures.exists(CANTEEN_MAP_KEY)) {
      this.load.image(CANTEEN_MAP_KEY, canteenInteriorMapUrl);
    }
    if (!this.textures.exists(CANTEEN_PUSH_CART_SHEET_KEY)) {
      this.load.spritesheet(CANTEEN_PUSH_CART_SHEET_KEY, playerPushCartSheetUrl, {
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
      this.load.spritesheet(key, url, {
        frameWidth: CANTEEN_NPC_FRAME_WIDTH,
        frameHeight: CANTEEN_NPC_FRAME_HEIGHT
      });
    });
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
    this.createCanteenNpcs();
    this.createInitialNpcInteractions();

    const spawn = this.currentPhase === "menu_order"
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
    const requestKeyboardInteraction = (event: KeyboardEvent) => {
      event.preventDefault();
      if (!event.repeat) this.interactRequested = true;
    };
    this.input.keyboard!.on("keydown-SPACE", requestKeyboardInteraction);
    this.events.once(Phaser.Scenes.Events.SHUTDOWN, () => {
      this.input.keyboard?.off("keydown-SPACE", requestKeyboardInteraction);
      this.defenseRestartTimer?.remove(false);
      this.defenseRuntime?.destroy();
      this.defenseRuntime = null;
    });
    this.input.on("pointerdown", (pointer: Phaser.Input.Pointer) => this.handleMenuPointer(pointer));

    this.cameras.main
      .setBounds(0, 0, CANTEEN_INTERIOR_WORLD.width, CANTEEN_INTERIOR_WORLD.height)
      .setZoom(1)
      .centerOn(835, 470);

    this.createTrays();
    this.carriedTrayVisual = this.add.image(0, 0, CANTEEN_TRAY_KEY)
      .setScale(0.75)
      .setDepth(2300)
      .setVisible(false);
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
    if (this.currentPhase === "exit_blocking") {
      this.startDefense();
    }
    if (this.bridge.getState().canteenHunt.active && this.currentPhase === "tray_search") {
      this.queueDialogue(canteenContent.entryDialogue, () => {
        this.dialogueLocked = false;
      }, ENTRY_DIALOGUE_STEP_MS);
    }
  }

  update(_time: number, deltaMs: number): void {
    const state = this.bridge.getState();
    this.syncWorldFromState(state);
    this.updateCarriedTrayVisual(state);
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
      && !this.menuPanel
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
      this.updateCarriedTrayVisual(state);
      this.updatePlayerCollisionDebug();
      this.promptText.setVisible(false);
      this.publishDebugState(null, state);
      this.interactRequested = false;
      return;
    }
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
    this.player.setVelocity(vector.x, vector.y);
    this.updatePlayerWorldDepth();
    this.playerAnimator.update(
      this.cartPushBusy && this.cartMotionVector.lengthSq() > 0 ? this.cartMotionVector : vector,
      this.time.now
    );
    this.updateOcclusion();
    this.updateCarriedTrayVisual(state);
    this.updatePlayerCollisionDebug();

    const activeTargets = this.getActiveTargets(state);
    const nearest = findNearestCanteenTarget(this.player.x, this.player.y, activeTargets);
    this.updatePrompt(nearest, state);
    this.publishDebugState(nearest, state);

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
    this.rebuildStaticCollisionBodies();
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
    CANTEEN_COUNTER_NPC_X.forEach((x, columnIndex) => {
      CANTEEN_QUEUE_NPC_Y.forEach((y, rowIndex) => {
        this.createLightNpc(
          x,
          y,
          CANTEEN_QUEUE_NPC_SHEET_KEY,
          queueIndex,
          y + 120,
          1.35 + (queueIndex % 4) * 0.1,
          180 + ((columnIndex * 3 + rowIndex) * 137) % 520
        );
        this.createLightNpcFootCollision(x, y, `queue-${queueIndex}`);
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

  private createLightNpcFootCollision(x: number, footBottomY: number, npcId: string): void {
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
      proximity: 48,
      kind: "npc",
      dialogue: CANTEEN_COUNTER_NPC_DIALOGUE
    };

    this.returnAuntieTarget = {
      id: "return-auntie",
      label: "与收餐口阿姨交谈",
      x: CANTEEN_RETURN_NPC_POSITION.x,
      y: CANTEEN_RETURN_NPC_POSITION.y,
      stand: { x: 1215, y: 600 },
      proximity: 58,
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
    const showSceneNpcs = this.currentPhase !== "exit_blocking" && !this.defenseRuntime;
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
      CANTEEN_TRAYS.map(({ x, y }) => ({ x, y }))
    );
    CANTEEN_TRAYS.forEach((tray, index) => {
      const position = shuffledPositions[index];
      const cleanImage = this.add.image(0, 0, CANTEEN_TRAY_KEY).setScale(0.75);
      const dirtyImage = this.add.image(0, 0, CANTEEN_DIRTY_TRAY_KEY)
        .setScale(0.75)
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
        stand: { x: position.x, y: position.y + 62 },
        proximity: 55,
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

  private createWorldHotspots(): void {
    const hotspotBounds: Record<string, { x: number; y: number; width: number; height: number }> = {
      ordering_kiosk: { x: 260, y: 760, width: 420, height: 160 },
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
      this.showFeedback(canteenContent.tray.taskStarted, "task", 2600);
      return;
    }
    if (name === "canteen_tray_collect_wrong_mode") {
      this.showFeedback(canteenContent.tray.collectWrongMode, "task");
      return;
    }
    if (name === "canteen_tray_hands_full") {
      this.showFeedback(canteenContent.tray.handsFull, "task");
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
    if (name === "canteen_defense_completed") {
      this.finishDefense();
      this.queueDialogue(canteenContent.blocking.escapeDialogue, () => {
        this.bridge.emit("rpg_canteen_leave_requested");
      });
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
    if (this.cartPushBusy || this.defenseRuntime) return;
    const state = this.bridge.getState();
    if (!["tray_search", "menu_order", "pickup_search"].includes(state.canteenHunt.phase)) return;
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
    if (state.canteenHunt.phase === "tray_search") {
      if (state.canteenHunt.mode !== "light") return [];
      return [
        ...this.initialNpcInteractionTargets,
        ...(state.canteenHunt.trayTaskStarted
          ? [...this.trayInteractionTargets.values()]
          : [])
      ];
    }
    if (state.canteenHunt.phase === "menu_order") {
      return [
        ...CANTEEN_INTERACTION_TARGETS.filter((target) => target.kind === "kiosk"),
        ...(state.canteenHunt.mode === "light" ? [this.returnAuntieTarget] : [])
      ];
    }
    if (state.canteenHunt.phase === "pickup_search") {
      return [
        ...CANTEEN_INTERACTION_TARGETS.filter((target) => target.kind === "pickup"),
        ...(state.canteenHunt.mode === "light" ? [this.returnAuntieTarget] : [])
      ];
    }
    if (state.canteenHunt.phase === "exit_blocking") {
      return [];
    }
    return [];
  }

  private triggerTarget(target: CanteenInteractionTarget, state: GameState): void {
    if (target.kind === "npc") {
      if (target.id === "return-auntie") {
        if (state.canteenHunt.phase !== "tray_search" || state.items.greaseTissue) {
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
        this.bridge.emit("rpg_item_use_feedback", {
          itemId: "pickupTicket0755",
          reason: "locked",
          targetLabel: target.label,
          detail: state.canteenHunt.pickupDarkClueRead
            ? `人物已到${target.value}号窗口。请把 0755 取餐号拖进窗口上方的发光验票框。`
            : "先切到深色模式观察取餐号和窗口残影。"
        });
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

  private handleInventoryDrop(payload?: Record<string, unknown>): void {
    const itemId = String(payload?.itemId ?? "") as ItemId;
    const canvasX = Number(payload?.canvasX);
    const canvasY = Number(payload?.canvasY);
    if (!Number.isFinite(canvasX) || !Number.isFinite(canvasY)) {
      this.bridge.emit("rpg_item_use_feedback", { itemId, reason: "missed_target" });
      return;
    }
    const state = this.bridge.getState();
    const pickupTargets = this.getActiveTargets(state)
      .filter((target) => target.kind === "pickup");
    const worldPoint = this.cameras.main.getWorldPoint(canvasX, canvasY);
    const result = resolveRpgItemDrop({
      targets: pickupTargets,
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
        detail: "取餐号已退回：请拖进 1、2、3 号窗口上方明确标出的验票框。"
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
    if (!state.canteenHunt.pickupDarkClueRead) {
      this.bridge.emit("rpg_item_use_feedback", {
        itemId,
        reason: "locked",
        targetLabel: result.target.label,
        detail: "先在深色模式观察取餐号背面的窗口残影，再切回浅色模式验票。"
      });
      return;
    }
    if (result.kind === "too_far") {
      this.bridge.emit("rpg_item_use_feedback", {
        itemId,
        reason: "too_far",
        targetLabel: result.target.label,
        detail: `落点正确；人物还没有站进${result.target.value}号窗口前的蓝色站位。`
      });
      return;
    }
    if (result.kind !== "accepted") return;
    this.bridge.emit("rpg_canteen_pickup_selected", { windowId: result.target.value });
  }

  private triggerTrayById(trayId: string): void {
    const state = this.bridge.getState();
    if (state.canteenHunt.phase !== "tray_search" || this.dialogueLocked) return;
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
    const label = nearest.kind === "npc"
      ? nearest.label
      : nearest.kind === "tray"
      ? state.canteenHunt.carriedTrayIds.length > 0
        ? "先把手上的餐盘交给阿姨"
        : "拿起桌上的餐盘"
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
              ? `把 0755 拖入${nearest.value}号窗口验票框`
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
    const pickupVisible = state.canteenHunt.active && state.canteenHunt.phase === "pickup_search";
    const showPickupDrop = pickupVisible
      && state.canteenHunt.mode === "light"
      && state.canteenHunt.pickupDarkClueRead
      && state.ui.selectedItem === "pickupTicket0755";
    this.pickupWindowVisuals.forEach((visual) => {
      visual.sign.setVisible(pickupVisible);
      visual.standMarker.setVisible(pickupVisible);
      visual.dropFrame.setVisible(showPickupDrop);
      visual.dropLabel.setVisible(showPickupDrop);
    });
    this.trayVisuals.forEach((visual, trayId) => {
      const definition = CANTEEN_TRAYS.find((tray) => tray.id === trayId);
      const removed = state.canteenHunt.returnedTrayIds.includes(trayId)
        || state.canteenHunt.carriedTrayIds.includes(trayId);
      const visible = state.canteenHunt.phase === "tray_search" && !removed;
      const dirtyVisible = visible
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
    if (blocking) {
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
    if (blocking && !this.paper.visible) {
      this.paper.setPosition(836, 470).setVisible(true);
      this.paperFloatTween.restart();
    } else if (!blocking && !this.paperBusy && !this.defenseRuntime) {
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
        this.showFeedback(canteenContent.tray.collected, "task", 2200);
      }
    });
  }

  private updateCarriedTrayVisual(state: GameState): void {
    if (!this.carriedTrayVisual) return;
    const carrying = state.canteenHunt.phase === "tray_search"
      && state.canteenHunt.carriedTrayIds.length > 0;
    this.carriedTrayVisual
      .setPosition(this.player.x, this.player.y - 48)
      .setDepth(this.player.depth + 4)
      .setVisible(carrying && !this.dialogueLocked);
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
    const steamWindow = CANTEEN_PICKUP_WINDOWS[2];
    this.paperBusy = true;
    this.paperFloatTween.pause();
    this.paper
      .setPosition(steamWindow.x, steamWindow.y)
      .setScale(0.32, 0.72)
      .setAngle(-18)
      .setAlpha(0)
      .setVisible(true);
    this.showFeedback(canteenContent.pickup.window3, "system");
    this.bridge.emit("canteen_paper_burst_started");
    this.tweens.add({
      targets: this.paper,
      x: 836,
      y: 470,
      scaleX: 1,
      scaleY: 1,
      alpha: 1,
      angle: 340,
      duration: this.reducedMotion ? 120 : 680,
      ease: "Back.easeOut",
      onComplete: () => {
        this.paperBusy = false;
        this.bridge.emit("canteen_paper_burst_completed");
        this.startDefense();
      }
    });
  }

  private startDefense(): void {
    if (this.defenseRuntime || this.bridge.getState().canteenHunt.phase !== "exit_blocking") return;
    this.currentPhase = "exit_blocking";
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
      camera.width / CANTEEN_INTERIOR_WORLD.width,
      camera.height / CANTEEN_INTERIOR_WORLD.height
    ) * 0.985;
    camera
      .stopFollow()
      .setDeadzone(0, 0)
      .setZoom(fullMapZoom)
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
      }
    );
    this.showFeedback("守住三个出口。空格键冲刺，纸条回头时会自动闪出路线。", "task", 2600);
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
    this.player.setVelocity(0, 0);
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
        mode: this.defenseRuntime ? "manual" : "follow"
      },
      scene: "canteen_interior",
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
        activeTarget: nearest?.id ?? null,
        pickupTargets: CANTEEN_PICKUP_WINDOWS.map((window) => ({
          id: window.id,
          window: window.value,
          anchor: { x: window.x, y: window.y },
          stand: window.stand!,
          proximity: window.proximity,
          dropBounds: getRpgDropBounds(window),
          acceptedItem: window.acceptedItem,
          requiredMode: window.requiredMode
        })),
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
