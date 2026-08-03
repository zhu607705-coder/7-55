import Phaser from "phaser";
import qizhenDecoyUrl from "../../assets/rpg/interiors/qizhen_lake_decoy.png";
import qizhenMistUrl from "../../assets/rpg/interiors/qizhen_lake_mist.png";
import qizhenReflectionUrl from "../../assets/rpg/interiors/qizhen_lake_reflection.png";
import qizhenSignsUrl from "../../assets/rpg/interiors/qizhen_lake_signs.png";
import type { GameSubtitleTone } from "../../components/GameSubtitleFrame";
import type { GameState, ItemId, QizhenDecoyTargetId, QizhenLakeMode } from "../../core/types";
import qizhenContent from "../../data/chapter3-qizhen-lake.content.json";
import { QIZHEN_REFLECTION_REAL_SEQUENCE } from "../../modules/ChapterThreeQizhenLakeController";
import type { RpgBridge } from "./RpgBridge";
import { formatRpgDragHint, formatRpgInteractionHint } from "./RpgControlHints";
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
  RPG_PLAYER_WALK_FPS
} from "./RpgPlayerTextures";
import { clearRpgRuntimeDebugState, setRpgRuntimeDebugState } from "./RpgRuntimeDebug";
import { subscribeRpgSceneBridge } from "./RpgSceneBridgeSubscription";
import {
  QIZHEN_LAKE_PLATES,
  QIZHEN_LAKE_TARGETS,
  QIZHEN_LAKE_WORLD,
  findNearestQizhenTarget,
  plateForQizhenPhase,
  type QizhenLakeInteractionTarget,
  type QizhenLakeOcclusionRect,
  type QizhenLakePlateId
} from "./QizhenLakeModel";

const PLATE_TEXTURE_KEYS: Readonly<Record<QizhenLakePlateId, string>> = {
  reflection: "chapter-3-qizhen-reflection",
  signs: "chapter-3-qizhen-signs",
  decoy: "chapter-3-qizhen-decoy",
  mist: "chapter-3-qizhen-mist"
};

const PAPER_TEXTURE_KEY = "chapter-3-qizhen-paper";
const WALK_SPEED = 165;
const RUN_SPEED = 228;
const DIALOGUE_STEP_MS = 2500;
const MIST_CYCLE_MS = 2200;
const MIST_WINDOW_START = 0.43;
const MIST_WINDOW_END = 0.57;

interface OcclusionVisual {
  definition: QizhenLakeOcclusionRect;
  bounds: Phaser.Geom.Rectangle;
  image: Phaser.GameObjects.Image;
}

export class QizhenLakeScene extends Phaser.Scene {
  private bridge!: RpgBridge;
  private player!: Phaser.Physics.Arcade.Sprite;
  private playerAnimator!: RpgPlayerAnimator;
  private obstacles!: Phaser.Physics.Arcade.StaticGroup;
  private mapImage!: Phaser.GameObjects.Image;
  private darkOverlay!: Phaser.GameObjects.Rectangle;
  private promptText!: Phaser.GameObjects.Text;
  private cursors!: Phaser.Types.Input.Keyboard.CursorKeys;
  private keys!: Record<"W" | "A" | "S" | "D" | "SHIFT" | "TAB", Phaser.Input.Keyboard.Key>;
  private currentPlate: QizhenLakePlateId = "reflection";
  private currentPhase: GameState["qizhenLake"]["phase"] = "reflection_hunt";
  private currentMode: QizhenLakeMode = "light";
  private virtualDirection = { x: 0, y: 0 };
  private interactRequested = false;
  private dialogueLocked = false;
  private phaseTransitioning = false;
  private reducedMotion = false;
  private occlusionVisuals: OcclusionVisual[] = [];
  private phaseVisuals: Phaser.GameObjects.GameObject[] = [];
  private decoyDropGuides: Array<
    Phaser.GameObjects.Shape | Phaser.GameObjects.Text | Phaser.GameObjects.Container
  > = [];
  private activeOcclusionIds: string[] = [];
  private softenedOcclusionIds: string[] = [];
  private mistHud: Phaser.GameObjects.Container | null = null;
  private mistMarker: Phaser.GameObjects.Container | null = null;
  private mistStatusText: Phaser.GameObjects.Text | null = null;
  private lastMistPhase = 0;

  constructor() {
    super("qizhen-lake");
  }

  preload(): void {
    const sources: Readonly<Record<QizhenLakePlateId, string>> = {
      reflection: qizhenReflectionUrl,
      signs: qizhenSignsUrl,
      decoy: qizhenDecoyUrl,
      mist: qizhenMistUrl
    };
    (Object.keys(sources) as QizhenLakePlateId[]).forEach((plateId) => {
      const key = PLATE_TEXTURE_KEYS[plateId];
      if (!this.textures.exists(key)) this.load.image(key, sources[plateId]);
    });
    preloadRpgPlayerTextures(this);
  }

  create(): void {
    this.bridge = this.registry.get("rpgBridge") as RpgBridge;
    const state = this.bridge.getState();
    this.reducedMotion = window.matchMedia?.("(prefers-reduced-motion: reduce)").matches === true;
    this.currentPhase = state.qizhenLake.phase;
    this.currentMode = state.qizhenLake.mode;
    this.currentPlate = plateForQizhenPhase(this.currentPhase);
    this.cameras.main.setBackgroundColor(0x071724);
    this.physics.world.setBounds(42, 0, QIZHEN_LAKE_WORLD.width - 84, QIZHEN_LAKE_WORLD.height);
    this.obstacles = this.physics.add.staticGroup();
    this.mapImage = this.add.image(0, 0, PLATE_TEXTURE_KEYS[this.currentPlate]).setOrigin(0).setDepth(-1000);
    this.ensurePaperTexture();
    ensureRpgPlayerTextures(this);
    this.rebuildPlate(this.currentPlate, false);

    const spawn = QIZHEN_LAKE_PLATES[this.currentPlate].spawn;
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

    this.cameras.main
      .setBounds(0, 0, QIZHEN_LAKE_WORLD.width, QIZHEN_LAKE_WORLD.height)
      .setZoom(1)
      .startFollow(this.player, true, 0.13, 0.13, 0, 22)
      .setDeadzone(250, 150);

    this.darkOverlay = this.add.rectangle(
      QIZHEN_LAKE_WORLD.width / 2,
      QIZHEN_LAKE_WORLD.height / 2,
      QIZHEN_LAKE_WORLD.width,
      QIZHEN_LAKE_WORLD.height,
      0x07142b,
      0.64
    ).setDepth(1500).setAlpha(this.currentMode === "dark" ? 0.64 : 0);
    this.promptText = this.add.text(RPG_HUD_LAYOUT.centerX, RPG_HUD_LAYOUT.promptBottomY, "", {
      color: "#fff7df",
      backgroundColor: "#102334ee",
      fontFamily: "monospace",
      fontSize: "13px",
      padding: { x: 9, y: 5 }
    }).setOrigin(0.5, 1).setScrollFactor(0).setDepth(5200).setVisible(false);
    this.rebuildPhaseVisuals(state);

    subscribeRpgSceneBridge(
      this.events,
      this.bridge,
      (event) => this.handleBridgeEvent(event.name, event.payload),
      clearRpgRuntimeDebugState
    );
    this.bridge.setRpgLocation("qizhen_lake", checkpointForPhase(this.currentPhase));
    this.bridge.emit("rpg_booted", { scene: "qizhen_lake", checkpoint: this.bridge.getState().rpgCheckpoint });
    this.bridge.emit("qizhen_lake_opened", { phase: this.currentPhase });
    if (this.currentPhase === "mist_timing" || this.currentPhase === "chase_ready") {
      this.bridge.emit("qizhen_mist_music_started", { phase: this.currentPhase });
    } else if (this.currentMode === "dark") {
      this.bridge.emit("qizhen_dark_mode_enabled", { mode: this.currentMode });
    }

    if (!state.qizhenLake.introSeen && this.currentPhase === "reflection_hunt") {
      this.queueDialogue(qizhenContent.reflection.dialogue, () => {
        this.bridge.emit("rpg_qizhen_intro_seen_requested");
      });
    }
  }

  update(): void {
    const state = this.bridge.getState();
    this.syncState(state);

    if (Phaser.Input.Keyboard.JustDown(this.keys.TAB) && !this.dialogueLocked && !this.phaseTransitioning) {
      this.bridge.emit("rpg_qizhen_mode_requested", {
        mode: state.qizhenLake.mode === "dark" ? "light" : "dark"
      });
    }

    const keyboardX = Number(this.cursors.right.isDown || this.keys.D.isDown)
      - Number(this.cursors.left.isDown || this.keys.A.isDown);
    const keyboardY = Number(this.cursors.down.isDown || this.keys.S.isDown)
      - Number(this.cursors.up.isDown || this.keys.W.isDown);
    const vector = new Phaser.Math.Vector2(
      Phaser.Math.Clamp(keyboardX + this.virtualDirection.x, -1, 1),
      Phaser.Math.Clamp(keyboardY + this.virtualDirection.y, -1, 1)
    );
    // Dialogue subtitles may stay on screen while the player keeps walking.
    // dialogueLocked continues to prevent a second interaction from firing.
    if (state.actOne.movementEnabled && !this.phaseTransitioning && vector.lengthSq() > 0) {
      vector.normalize().scale(this.keys.SHIFT.isDown ? RUN_SPEED : WALK_SPEED);
    } else {
      vector.set(0, 0);
    }
    this.player.setVelocity(vector.x, vector.y).setDepth(this.player.y + 120);
    this.playerAnimator.update(vector, this.time.now);
    this.updateOcclusion();
    this.updatePhaseVisuals(state);
    this.updateMistTiming(state);

    const targets = this.getActiveTargets(state);
    const nearest = findNearestQizhenTarget(this.player.x, this.player.y, targets);
    this.updatePrompt(nearest, state);
    this.publishDebugState(nearest, state);
    const keyboardInteract = Phaser.Input.Keyboard.JustDown(this.cursors.space);
    if (nearest && !this.dialogueLocked && !this.phaseTransitioning && (keyboardInteract || this.interactRequested)) {
      this.triggerTarget(nearest, state);
    }
    this.interactRequested = false;
  }

  private rebuildPlate(plateId: QizhenLakePlateId, repositionPlayer: boolean): void {
    const definition = QIZHEN_LAKE_PLATES[plateId];
    this.currentPlate = plateId;
    this.mapImage.setTexture(PLATE_TEXTURE_KEYS[plateId]);
    this.obstacles.clear(true, true);
    this.occlusionVisuals.forEach((visual) => visual.image.destroy());
    this.occlusionVisuals = [];

    const collisionVisible = import.meta.env.DEV
      && new URLSearchParams(window.location.search).get("rpgCollision") === "1";
    definition.collisions.forEach((rect) => {
      const collision = this.add.rectangle(
        (rect.left + rect.right) / 2,
        (rect.top + rect.bottom) / 2,
        rect.right - rect.left,
        rect.bottom - rect.top,
        collisionVisible ? 0xff3355 : 0x000000,
        collisionVisible ? 0.24 : 0
      ).setDepth(collisionVisible ? 4900 : rect.bottom - 20);
      if (collisionVisible) collision.setStrokeStyle(2, 0xffd4dc, 0.9);
      this.obstacles.add(collision);
    });

    definition.occlusions.forEach((occlusion) => {
      const image = this.add.image(0, 0, PLATE_TEXTURE_KEYS[plateId])
        .setOrigin(0)
        .setCrop(
          occlusion.left,
          occlusion.top,
          occlusion.right - occlusion.left,
          occlusion.bottom - occlusion.top
        )
        .setDepth(-900)
        .setVisible(false);
      this.occlusionVisuals.push({
        definition: occlusion,
        bounds: new Phaser.Geom.Rectangle(
          occlusion.left,
          occlusion.top,
          occlusion.right - occlusion.left,
          occlusion.bottom - occlusion.top
        ),
        image
      });
    });

    if (repositionPlayer && this.player) {
      this.player.setPosition(definition.spawn.x, definition.spawn.y).setVelocity(0, 0);
      this.cameras.main.centerOn(definition.spawn.x, definition.spawn.y);
    }
  }

  private rebuildPhaseVisuals(state: GameState): void {
    this.phaseVisuals.forEach((visual) => {
      this.tweens.killTweensOf(visual);
      if (visual instanceof Phaser.GameObjects.Container) {
        visual.list.forEach((child) => this.tweens.killTweensOf(child));
      }
      visual.destroy();
    });
    this.phaseVisuals = [];
    this.decoyDropGuides = [];
    if (this.mistHud) {
      this.tweens.killTweensOf(this.mistHud);
      this.mistHud.list.forEach((child) => {
        this.tweens.killTweensOf(child);
        if (child instanceof Phaser.GameObjects.Container) {
          child.list.forEach((nestedChild) => this.tweens.killTweensOf(nestedChild));
        }
      });
      this.mistHud.destroy();
    }
    this.mistHud = null;
    this.mistMarker = null;
    this.mistStatusText = null;

    this.createAmbientVisuals(state);
    this.createExitMarker();
    if (state.qizhenLake.phase === "reflection_hunt") this.createReflectionVisuals(state);
    else if (state.qizhenLake.phase === "sign_alignment") this.createSignVisuals(state);
    else if (state.qizhenLake.phase === "decoy_setup") this.createDecoyVisuals(state);
    else if (state.qizhenLake.phase === "mist_timing" || state.qizhenLake.phase === "chase_ready") {
      this.createMistVisuals(state);
    }
  }

  private createAmbientVisuals(state: GameState): void {
    const waterBands: ReadonlyArray<readonly [number, number, number]> = this.currentPlate === "decoy"
      ? [[690, 378, 92], [905, 442, 72], [1170, 350, 88]]
      : this.currentPlate === "mist"
        ? [[690, 330, 82], [930, 310, 104], [1210, 345, 76]]
        : [[470, 300, 86], [710, 350, 112], [1005, 288, 92], [1270, 370, 78]];
    waterBands.forEach(([x, y, width], index) => {
      const shimmer = this.add.rectangle(x, y, width, 3, 0xc8f7ff, 0.22)
        .setDepth(1120)
        .setBlendMode(Phaser.BlendModes.ADD);
      const glint = this.add.rectangle(x - width * 0.2, y - 4, Math.max(18, width * 0.34), 2, 0xffffff, 0.28)
        .setDepth(1121)
        .setBlendMode(Phaser.BlendModes.ADD);
      this.phaseVisuals.push(shimmer, glint);
      if (!this.reducedMotion) {
        this.tweens.add({
          targets: shimmer,
          x: x + 22,
          alpha: { from: 0.12, to: 0.46 },
          duration: 1800 + index * 230,
          ease: "Sine.easeInOut",
          yoyo: true,
          repeat: -1,
          delay: index * 180
        });
        this.tweens.add({
          targets: glint,
          x: x + width * 0.28,
          alpha: { from: 0.08, to: 0.5 },
          duration: 1320 + index * 190,
          ease: "Sine.easeInOut",
          yoyo: true,
          repeat: -1,
          delay: 220 + index * 260
        });
      }
    });

    const rippleDefinitions: ReadonlyArray<readonly [number, number, number]> = this.currentPlate === "decoy"
      ? [[1010, 492, 28], [1260, 430, 22], [770, 430, 18]]
      : [[560, 356, 22], [1110, 325, 27], [1340, 395, 18]];
    rippleDefinitions.forEach(([x, y, radius], index) => {
      const ripple = this.add.ellipse(x, y, radius * 2, Math.max(8, radius * 0.52), 0x9beaff, 0)
        .setStrokeStyle(2, 0xc7f7ff, 0.42)
        .setDepth(1118)
        .setScale(0.62);
      this.phaseVisuals.push(ripple);
      if (!this.reducedMotion) {
        this.tweens.add({
          targets: ripple,
          scaleX: 1.72,
          scaleY: 1.72,
          alpha: { from: 0.54, to: 0 },
          duration: 2200,
          ease: "Cubic.easeOut",
          repeat: -1,
          delay: index * 640
        });
      } else {
        ripple.setScale(1).setAlpha(0.28);
      }
    });

    const motes = [
      { x: 395, y: 565, color: 0xffed9e },
      { x: 660, y: 610, color: 0xd8ffbd },
      { x: 1080, y: 575, color: 0xfff1b6 },
      { x: 1320, y: 620, color: 0xc9f7ff }
    ];
    motes.forEach((definition, index) => {
      const mote = this.add.rectangle(definition.x, definition.y, 4, 4, definition.color, 0.42)
        .setDepth(definition.y + 8);
      this.phaseVisuals.push(mote);
      if (!this.reducedMotion) {
        this.tweens.add({
          targets: mote,
          x: definition.x + (index % 2 === 0 ? 18 : -14),
          y: definition.y - 13,
          alpha: { from: 0.18, to: 0.7 },
          duration: 1700 + index * 270,
          ease: "Sine.easeInOut",
          yoyo: true,
          repeat: -1,
          delay: index * 240
        });
      }
    });

    const scanner = this.add.rectangle(480, 116, 820, 2, 0x89e9ff, 0.2)
      .setScrollFactor(0)
      .setDepth(1555)
      .setBlendMode(Phaser.BlendModes.ADD)
      .setName("darkOnly");
    const upperShade = this.add.rectangle(480, 58, 960, 30, 0x03101f, 0.32)
      .setScrollFactor(0)
      .setDepth(1552)
      .setName("darkOnly");
    const lowerShade = this.add.rectangle(480, 522, 960, 36, 0x03101f, 0.34)
      .setScrollFactor(0)
      .setDepth(1552)
      .setName("darkOnly");
    this.phaseVisuals.push(scanner, upperShade, lowerShade);
    if (!this.reducedMotion) {
      this.tweens.add({
        targets: scanner,
        y: 398,
        alpha: { from: 0.08, to: 0.28 },
        duration: 2800,
        ease: "Sine.easeInOut",
        yoyo: true,
        repeat: -1
      });
    }
    [scanner, upperShade, lowerShade].forEach((visual) => visual.setVisible(state.qizhenLake.mode === "dark"));

    const darkFocusOverlays: Phaser.GameObjects.Shape[] = [];
    if (this.currentPlate === "signs") {
      [430, 836, 1240].forEach((x) => {
        darkFocusOverlays.push(
          this.add.ellipse(x, 650, 196, 102, 0x8cefff, 0.1)
            .setDepth(684)
            .setBlendMode(Phaser.BlendModes.ADD)
            .setName("darkOnly")
        );
      });
      darkFocusOverlays.push(
        this.add.ellipse(836, 446, 236, 52, 0x89e9ff, 0.08)
          .setDepth(1652)
          .setBlendMode(Phaser.BlendModes.ADD)
          .setName("darkOnly")
      );
    } else if (this.currentPlate === "mist") {
      darkFocusOverlays.push(
        this.add.ellipse(836, 654, 176, 96, 0x92f4ff, 0.09)
          .setDepth(690)
          .setBlendMode(Phaser.BlendModes.ADD)
          .setName("darkOnly"),
        this.add.ellipse(836, 454, 254, 42, 0xc0ffff, 0.06)
          .setDepth(1122)
          .setBlendMode(Phaser.BlendModes.ADD)
          .setName("darkOnly")
      );
    }
    darkFocusOverlays.forEach((overlay) => {
      overlay.setVisible(state.qizhenLake.mode === "dark");
      this.phaseVisuals.push(overlay);
    });
  }

  private createExitMarker(): void {
    const target = QIZHEN_LAKE_TARGETS.find((candidate) => candidate.kind === "exit")!;
    const marker = this.add.container(target.x, target.y, [
      this.add.rectangle(-20, -22, 5, 52, 0x284c47, 1),
      this.add.triangle(-3, -35, 0, 0, 28, 13, 0, 26, 0x9ee0c7, 0.96),
      this.add.text(8, 10, "离开湖区", {
        color: "#e7fff3",
        backgroundColor: "#102b2acc",
        fontFamily: "monospace",
        fontSize: "12px",
        padding: { x: 6, y: 3 }
      }).setOrigin(0.5)
    ]).setDepth(target.y + 35).setSize(110, 82).setInteractive({ useHandCursor: true });
    marker.on("pointerdown", () => this.triggerPointerTarget(target));
    this.phaseVisuals.push(marker);
  }

  private createReflectionVisuals(state: GameState): void {
    const expected = QIZHEN_REFLECTION_REAL_SEQUENCE[Math.min(state.qizhenLake.reflectionRound, 2)];
    const ghostX = expected === "right" ? 430 : expected === "left" ? 1240 : 836;
    const ghostPaper = this.add.container(0, 0, [
      this.add.image(-10, 3, PAPER_TEXTURE_KEY).setAlpha(0.2).setTint(0x6ec9ef),
      this.add.image(-5, 1, PAPER_TEXTURE_KEY).setAlpha(0.38).setTint(0x8fe7ff),
      this.add.image(0, 0, PAPER_TEXTURE_KEY).setAlpha(0.94),
      this.add.rectangle(2, 3, 24, 2, 0xd8fbff, 0.8).setAngle(7)
    ]).setName("ghostPaper");
    const ghost = this.add.container(ghostX, 390, [
      this.add.ellipse(0, 5, 128, 42, 0x65d9ff, 0.09).setStrokeStyle(2, 0x9ceaff, 0.52),
      this.add.ellipse(0, 5, 84, 26, 0xb7f4ff, 0.08).setStrokeStyle(2, 0xd5fbff, 0.72),
      ghostPaper
    ]).setDepth(1650).setName("reflectionGhost");
    ghost.setData("reflectionRound", state.qizhenLake.reflectionRound);
    if (!this.reducedMotion) {
      this.tweens.add({
        targets: ghostPaper,
        y: -7,
        angle: 3,
        alpha: { from: 0.72, to: 1 },
        duration: 860,
        ease: "Sine.easeInOut",
        yoyo: true,
        repeat: -1
      });
    }
    this.phaseVisuals.push(ghost);
    QIZHEN_LAKE_TARGETS.filter((target) => target.kind === "reflection_spot").forEach((target) => {
      const outerRing = this.add.circle(0, 0, 44, 0xf0dc89, 0.025)
        .setStrokeStyle(3, 0xeed97a, 0.48)
        .setName("outerRing");
      const proximityGlow = this.add.circle(0, 0, 35, 0xffed9e, 0.1)
        .setStrokeStyle(2, 0xfff4bc, 0.76)
        .setAlpha(0)
        .setName("proximityGlow");
      const marker = this.add.container(target.x, target.y, [
        this.add.ellipse(0, 7, 58, 20, 0xf0dc89, 0.08).setStrokeStyle(2, 0xeed97a, 0.34),
        outerRing,
        proximityGlow,
        this.add.rectangle(-33, 0, 13, 3, 0xfff0a8, 0.72),
        this.add.rectangle(33, 0, 13, 3, 0xfff0a8, 0.72),
        this.add.rectangle(0, -33, 3, 13, 0xfff0a8, 0.72),
        this.add.rectangle(0, 33, 3, 13, 0xfff0a8, 0.72),
        this.add.circle(0, 1, 4, 0xfff6c9, 0.96),
        this.add.circle(0, 1, 13, 0xfff6c9, 0.03).setStrokeStyle(1, 0xfff6c9, 0.5)
      ]).setDepth(target.y + 30)
        .setSize(96, 96)
        .setInteractive({ useHandCursor: true })
        .setName("reflectionSpot");
      marker.setData("targetId", target.id);
      marker.on("pointerdown", () => this.triggerPointerTarget(target));
      if (!this.reducedMotion) {
        this.tweens.add({
          targets: outerRing,
          scale: 1.08,
          alpha: { from: 0.5, to: 0.92 },
          duration: 1400,
          ease: "Sine.easeInOut",
          yoyo: true,
          repeat: -1,
          delay: target.x % 300
        });
      }
      this.phaseVisuals.push(marker);
    });
  }

  private createSignVisuals(state: GameState): void {
    const signs = QIZHEN_LAKE_TARGETS.filter((target) => target.kind === "sign");
    signs.forEach((target, index) => {
      const arrow = this.add.container(0, -14, [
        this.add.circle(0, 0, 19, 0x123d49, 0.1).setStrokeStyle(2, 0x4b8790, 0.62),
        this.add.rectangle(-3, 0, 28, 5, 0x28758a, 1),
        this.add.triangle(16, 0, 0, -9, 15, 0, 0, 9, 0x28758a, 1),
        this.add.circle(-14, 0, 4, 0xcaf7f3, 0.92)
      ]).setName("arrow");
      arrow.setData("renderedRotation", state.qizhenLake.signRotations[index]);
      arrow.setAngle(state.qizhenLake.signRotations[index] * 90);
      const proximityGlow = this.add.rectangle(0, -28, 176, 58, 0x8ee9ef, 0.1)
        .setStrokeStyle(3, 0xaef8ff, 0.9)
        .setAlpha(0)
        .setName("proximityGlow");
      const sign = this.add.container(target.x, target.y, [
        this.add.ellipse(0, 35, 42, 10, 0x142520, 0.28),
        this.add.rectangle(0, 8, 9, 66, 0x243c38, 1).setStrokeStyle(2, 0x7f9c94, 0.78),
        this.add.rectangle(0, -25, 174, 56, 0x203c39, 0.92).setStrokeStyle(2, 0x18312e, 1),
        this.add.rectangle(0, -29, 166, 48, 0xd9e4df, 0.98).setStrokeStyle(3, 0x315a55, 1),
        this.add.rectangle(0, -50, 160, 4, 0xf4f9f6, 0.7),
        this.add.rectangle(0, -8, 160, 4, 0x244d49, 0.36),
        proximityGlow,
        this.add.circle(-73, -39, 11, 0x2f686f, 0.94).setStrokeStyle(2, 0xc7fcff, 0.86),
        this.add.text(-73, -39, `${index + 1}`, {
          color: "#f0ffff",
          fontFamily: "monospace",
          fontSize: "10px",
          fontStyle: "bold"
        }).setOrigin(0.5),
        this.add.text(0, -39, qizhenContent.signs.labels[index], {
          color: "#203f3b",
          fontFamily: "monospace",
          fontSize: "11px",
          align: "center"
        }).setOrigin(0.5),
        arrow,
        this.add.circle(-59, -15, 3, 0x6f8c83, 0.9),
        this.add.circle(59, -15, 3, 0x6f8c83, 0.9)
      ]).setDepth(target.y + 40)
        .setSize(194, 118)
        .setInteractive({ useHandCursor: true })
        .setName("qizhenSign");
      sign.setData("signIndex", index);
      sign.setData("targetId", target.id);
      sign.on("pointerdown", () => this.triggerPointerTarget(target));
      this.phaseVisuals.push(sign);
    });
    const clueText = this.add.text(0, 0, "◀   ◇   ▶", {
      color: "#b8f5ff",
      fontFamily: "monospace",
      fontSize: "22px",
      fontStyle: "bold"
    }).setOrigin(0.5);
    const reflectionArrow = this.add.container(836, 445, [
      this.add.ellipse(0, 4, 196, 54, 0x56cff3, 0.08).setStrokeStyle(2, 0x8de8ff, 0.46),
      this.add.ellipse(0, 4, 150, 34, 0xbaf7ff, 0.05),
      clueText,
      this.add.text(0, 24, "水里的箭头缺了一截", {
        color: "#d8fbff",
        fontFamily: "monospace",
        fontSize: "11px"
      }).setOrigin(0.5)
    ]).setAlpha(0.9).setDepth(1650).setName("reflectionArrow");
    if (!this.reducedMotion) {
      this.tweens.add({
        targets: reflectionArrow,
        y: 439,
        alpha: { from: 0.66, to: 1 },
        duration: 1400,
        ease: "Sine.easeInOut",
        yoyo: true,
        repeat: -1
      });
    }
    this.phaseVisuals.push(reflectionArrow);
    this.updatePhaseVisuals(state);
  }

  private createDecoyVisuals(state: GameState): void {
    QIZHEN_LAKE_TARGETS.filter((target) => target.kind === "decoy_spot").forEach((target) => {
      const kind = target.value ?? "notice";
      const focusWidth = kind === "lamp" ? 82 : 148;
      const focusHeight = kind === "lamp" ? 190 : 82;
      const focusY = kind === "lamp" ? -92 : -50;
      const focusChildren: Phaser.GameObjects.GameObject[] = [
        this.add.rectangle(2, 3, focusWidth, focusHeight, 0x061517, 0.01)
          .setStrokeStyle(1, 0x061517, 0.2),
        this.add.rectangle(0, -focusHeight / 2 + 3, 28, 7, 0x173d42, 0.92)
          .setStrokeStyle(1, 0x83c7c4, 0.74),
        this.add.rectangle(0, -focusHeight / 2 + 3, 15, 2, 0xdbfff3, 0.7),
        this.add.circle(-9, -focusHeight / 2 + 3, 2, 0xf0d58b, 0.96),
        this.add.circle(9, -focusHeight / 2 + 3, 2, 0xf0d58b, 0.96),
        this.add.triangle(
          0,
          focusHeight / 2 + 8,
          0,
          0,
          10,
          0,
          5,
          7,
          0xf0d58b,
          0.9
        )
      ];
      ([-1, 1] as const).forEach((horizontal) => {
        ([-1, 1] as const).forEach((vertical) => {
          focusChildren.push(
            this.add.rectangle(
              horizontal * (focusWidth / 2 - 10),
              vertical * focusHeight / 2,
              20,
              3,
              0x07191b,
              0.76
            ),
            this.add.rectangle(
              horizontal * focusWidth / 2,
              vertical * (focusHeight / 2 - 10),
              3,
              20,
              0x07191b,
              0.76
            ),
            this.add.rectangle(
              horizontal * (focusWidth / 2 - 9),
              vertical * focusHeight / 2,
              17,
              2,
              0xa8f5ff,
              0.96
            ),
            this.add.rectangle(
              horizontal * focusWidth / 2,
              vertical * (focusHeight / 2 - 9),
              2,
              17,
              0xa8f5ff,
              0.96
            ),
            this.add.rectangle(
              horizontal * (focusWidth / 2 - 4),
              vertical * (focusHeight / 2 - 4),
              3,
              3,
              0xdbfff3,
              0.9
            )
          );
        });
      });
      const proximityGlow = this.add.container(0, focusY, focusChildren)
        .setAlpha(0)
        .setName("proximityGlow");
      const children: Phaser.GameObjects.GameObject[] = [
        this.add.ellipse(0, 4, 54, 14, 0x11231d, 0.3),
        proximityGlow
      ];
      if (kind === "lamp") {
        children.push(
          this.add.ellipse(0, -136, 112, 154, 0xffdda0, 0.08).setName("lampGlow"),
          this.add.rectangle(0, -76, 9, 154, 0x24383b, 1).setStrokeStyle(2, 0x779094, 0.75),
          this.add.rectangle(0, -154, 42, 48, 0x23353a, 1).setStrokeStyle(3, 0x80989b, 0.9),
          this.add.rectangle(0, -154, 25, 29, 0xffefad, 0.72),
          this.add.rectangle(0, -163, 21, 3, 0xfffacf, 0.86),
          this.add.triangle(0, -182, -24, 16, 0, 0, 24, 16, 0x1c2d31, 1),
          this.add.rectangle(0, 3, 34, 8, 0x1c3032, 1),
          this.add.circle(0, -154, 4, 0xfff8d2, 0.95)
        );
      } else if (kind === "bridge") {
        children.push(
          this.add.rectangle(-43, -18, 7, 52, 0x3b5045, 1),
          this.add.rectangle(43, -18, 7, 52, 0x3b5045, 1),
          this.add.rectangle(0, -48, 120, 46, 0x263f3b, 0.92).setStrokeStyle(2, 0x172c29, 1),
          this.add.rectangle(0, -51, 112, 42, 0xb8cbb9, 0.97).setStrokeStyle(3, 0x3a5e54, 1),
          this.add.rectangle(0, -69, 106, 3, 0xe9f4e9, 0.7),
          this.add.text(0, -48, "桥边告示", {
            color: "#2b4a42", fontFamily: "monospace", fontSize: "11px"
          }).setOrigin(0.5),
          this.add.circle(-48, -52, 3, 0x5e756a, 1),
          this.add.circle(48, -52, 3, 0x5e756a, 1)
        );
      } else {
        children.push(
          this.add.rectangle(-28, -20, 6, 54, 0x544a36, 1),
          this.add.rectangle(28, -20, 6, 54, 0x544a36, 1),
          this.add.rectangle(0, -55, 120, 58, 0x564b34, 0.96).setStrokeStyle(2, 0x392f20, 1),
          this.add.rectangle(0, -57, 110, 50, 0xe6dfbd, 0.98).setStrokeStyle(3, 0x695c3d, 1),
          this.add.rectangle(0, -78, 104, 3, 0xfff7d7, 0.72),
          this.add.text(0, -55, "岸边告示", {
            color: "#51472f", fontFamily: "monospace", fontSize: "11px"
          }).setOrigin(0.5),
          this.add.circle(-47, -72, 3, 0x9b8350, 1),
          this.add.circle(47, -72, 3, 0x9b8350, 1)
        );
      }
      const marker = this.add.container(target.x, target.y, children)
        .setDepth(target.y + 38)
        .setSize(kind === "lamp" ? 120 : 150, kind === "lamp" ? 210 : 110)
        .setInteractive({ useHandCursor: true })
        .setName("qizhenDecoyFixture");
      marker.setData("targetId", target.id);
      marker.setData("targetValue", kind);
      marker.on("pointerdown", () => this.triggerPointerTarget(target));
      const dropBounds = getRpgDropBounds(target);
      const guideWidth = dropBounds.width;
      const guideHeight = dropBounds.height;
      const bracketColor = 0x8fd8d4;
      const bracketHighlight = 0xdbfff3;
      const guideShadow = 0x041315;
      const bracketChildren: Phaser.GameObjects.GameObject[] = [
        this.add.rectangle(2, 3, guideWidth, guideHeight, 0x061517, 0.04)
          .setStrokeStyle(1, 0x061517, 0.18),
        this.add.rectangle(0, 0, guideWidth, guideHeight, 0x0b2b31, 0.012)
          .setStrokeStyle(1, 0x5d9291, 0.22),
        this.add.rectangle(0, -guideHeight / 2 + 3, 24, 7, 0x173d42, 0.9)
          .setStrokeStyle(2, 0x6aaead, 0.76),
        this.add.rectangle(0, -guideHeight / 2 + 3, 14, 2, bracketHighlight, 0.62),
        this.add.circle(-8, -guideHeight / 2 + 3, 2, 0xf0d58b, 0.92),
        this.add.circle(8, -guideHeight / 2 + 3, 2, 0xf0d58b, 0.92)
      ];
      ([-1, 1] as const).forEach((horizontal) => {
        ([-1, 1] as const).forEach((vertical) => {
          bracketChildren.push(
            this.add.rectangle(
              horizontal * (guideWidth / 2 - 11),
              vertical * guideHeight / 2,
              22,
              4,
              0x07191b,
              0.72
            ),
            this.add.rectangle(
              horizontal * guideWidth / 2,
              vertical * (guideHeight / 2 - 11),
              4,
              22,
              0x07191b,
              0.72
            ),
            this.add.rectangle(
              horizontal * (guideWidth / 2 - 10),
              vertical * guideHeight / 2,
              18,
              2,
              bracketColor,
              0.92
            ),
            this.add.rectangle(
              horizontal * guideWidth / 2,
              vertical * (guideHeight / 2 - 10),
              2,
              18,
              bracketColor,
              0.92
            ),
            this.add.rectangle(
              horizontal * (guideWidth / 2 - 4),
              vertical * (guideHeight / 2 - 4),
              3,
              3,
              bracketHighlight,
              0.72
            )
          );
        });
      });
      const idleBracket = this.add.container(target.x, target.y, bracketChildren)
        .setDepth(target.y + 41)
        .setAlpha(0.22)
        .setName("qizhenDecoyIdleGuide");
      idleBracket.setData("targetId", target.id);
      const paperSlot = this.add.container(0, 2, [
        this.add.rectangle(0, 0, 24, 30, 0xe8f7e9, 0.035)
          .setStrokeStyle(2, bracketHighlight, 0.56),
        this.add.rectangle(0, -12, 11, 4, 0x24565c, 0.94)
          .setStrokeStyle(1, 0xb9eee4, 0.8),
        this.add.rectangle(0, -1, 14, 2, bracketHighlight, 0.34),
        this.add.rectangle(0, 5, 11, 2, bracketHighlight, 0.24)
      ]).setAngle(-3);
      const scanLine = this.add.rectangle(
        0,
        -guideHeight / 2 + 11,
        guideWidth - 24,
        2,
        bracketHighlight,
        0.32
      ).setName("qizhenDecoyScanLine");
      const activeFrameChildren: Phaser.GameObjects.GameObject[] = [
        this.add.rectangle(3, 4, guideWidth + 4, guideHeight + 4, guideShadow, 0.16),
        this.add.rectangle(0, 0, guideWidth, guideHeight, 0x0d3540, 0.045)
          .setStrokeStyle(2, bracketColor, 0.96),
        this.add.rectangle(0, 0, guideWidth - 12, guideHeight - 12, 0x0d3540, 0)
          .setStrokeStyle(1, bracketHighlight, 0.22),
        scanLine,
        paperSlot
      ];
      ([-1, 1] as const).forEach((horizontal) => {
        ([-1, 1] as const).forEach((vertical) => {
          activeFrameChildren.push(
            this.add.rectangle(
              horizontal * (guideWidth / 2 - 10),
              vertical * guideHeight / 2,
              20,
              4,
              bracketHighlight,
              0.96
            ),
            this.add.rectangle(
              horizontal * guideWidth / 2,
              vertical * (guideHeight / 2 - 10),
              4,
              20,
              bracketHighlight,
              0.96
            ),
            this.add.rectangle(
              horizontal * (guideWidth / 2 - 4),
              vertical * (guideHeight / 2 - 4),
              4,
              4,
              0xf0d58b,
              0.96
            )
          );
        });
      });
      const dropFrame = this.add.container(target.x, target.y, activeFrameChildren)
        .setDepth(target.y + 42)
        .setName("qizhenDecoyDropGuide")
        .setVisible(false);
      dropFrame.setData("targetId", target.id);
      if (!this.reducedMotion) {
        this.tweens.add({
          targets: scanLine,
          y: guideHeight / 2 - 11,
          alpha: { from: 0.14, to: 0.5 },
          duration: 1180,
          ease: "Sine.easeInOut",
          yoyo: true,
          repeat: -1
        });
      } else {
        scanLine.setY(0).setAlpha(0.24);
      }
      const dropLabelText = this.add.text(5, 0, "假纸条夹这里", {
        color: "#effff8",
        fontFamily: "monospace",
        fontSize: "11px",
        fontStyle: "bold"
      }).setOrigin(0.5);
      const dropLabelWidth = Math.ceil(dropLabelText.width) + 32;
      const dropLabel = this.add.container(
        target.x,
        target.y - guideHeight / 2 - 18,
        [
          this.add.rectangle(2, 3, dropLabelWidth, 24, guideShadow, 0.28),
          this.add.rectangle(0, 0, dropLabelWidth, 24, 0x102b32, 0.94)
            .setStrokeStyle(2, bracketColor, 0.92),
          this.add.rectangle(-dropLabelWidth / 2 + 8, 0, 4, 12, 0xf0d58b, 0.92),
          dropLabelText,
          this.add.triangle(0, 15, 0, 0, 8, 0, 4, 5, bracketColor, 0.94)
        ]
      )
        .setDepth(target.y + 43)
        .setName("qizhenDecoyDropGuide")
        .setVisible(false);
      dropLabel.setData("targetId", target.id);
      const stand = target.stand ?? target;
      const leftFoot = this.add.rectangle(-7, 1, 6, 10, bracketHighlight, 0.74);
      const leftToe = this.add.rectangle(-7, -5, 8, 3, bracketHighlight, 0.86);
      const rightFoot = this.add.rectangle(7, 1, 6, 10, bracketHighlight, 0.74);
      const rightToe = this.add.rectangle(7, -5, 8, 3, bracketHighlight, 0.86);
      const standMarker = this.add.container(stand.x, stand.y, [
        this.add.ellipse(2, 3, 58, 24, guideShadow, 0.22),
        this.add.ellipse(0, 0, 54, 20, 0x0d3038, 0.04)
          .setStrokeStyle(2, bracketColor, 0.82),
        this.add.rectangle(-19, -9, 10, 3, bracketHighlight, 0.78),
        this.add.rectangle(19, -9, 10, 3, bracketHighlight, 0.78),
        this.add.rectangle(-22, 0, 3, 8, bracketHighlight, 0.78),
        this.add.rectangle(22, 0, 3, 8, bracketHighlight, 0.78),
        this.add.rectangle(0, -8, 10, 2, 0xf0d58b, 0.72),
        leftFoot,
        leftToe,
        rightFoot,
        rightToe,
        this.add.text(0, 18, "站这里", {
          color: "#effff8",
          backgroundColor: "#102b32d8",
          fontFamily: "monospace",
          fontSize: "9px",
          padding: { x: 4, y: 1 }
        }).setOrigin(0.5)
      ])
        .setDepth(stand.y + 36)
        .setName("qizhenDecoyDropGuide")
        .setVisible(false);
      standMarker.setData("targetId", target.id);
      if (!this.reducedMotion) {
        this.tweens.add({
          targets: [leftFoot, leftToe, rightFoot, rightToe],
          alpha: { from: 0.58, to: 1 },
          duration: 720,
          ease: "Sine.easeInOut",
          yoyo: true,
          repeat: -1
        });
      }
      const pinnedPaper = this.add.container(target.x, target.y - 5, [
        this.add.image(0, 0, PAPER_TEXTURE_KEY).setScale(1.18),
        this.add.circle(0, -12, 4, 0xc8534d, 1).setStrokeStyle(1, 0xffd5a2, 0.9),
        this.add.rectangle(0, -12, 2, 9, 0x6e2e2a, 0.9)
      ]).setDepth(target.y + 44)
        .setName("decoyPlacedPaper")
        .setVisible(state.qizhenLake.decoyPlacedAt === kind);
      pinnedPaper.setData("targetValue", kind);
      if (pinnedPaper.visible && !this.reducedMotion) {
        this.tweens.add({
          targets: pinnedPaper,
          angle: { from: -2.5, to: 2.5 },
          duration: 900,
          ease: "Sine.easeInOut",
          yoyo: true,
          repeat: -1
        });
      }
      const lampGlow = marker.getByName("lampGlow");
      if (lampGlow && !this.reducedMotion) {
        this.tweens.add({
          targets: lampGlow,
          alpha: { from: 0.05, to: 0.16 },
          scale: { from: 0.94, to: 1.06 },
          duration: 2000,
          ease: "Sine.easeInOut",
          yoyo: true,
          repeat: -1
        });
      }
      this.decoyDropGuides.push(dropFrame, dropLabel, standMarker);
      this.phaseVisuals.push(marker, idleBracket, dropFrame, dropLabel, standMarker, pinnedPaper);
    });
  }

  private createMistVisuals(state: GameState): void {
    const mister = QIZHEN_LAKE_TARGETS.find((target) => target.kind === "mister")!;
    const proximityGlow = this.add.ellipse(0, 0, 132, 88, 0x8af6ff, 0.1)
      .setStrokeStyle(3, 0xbefcff, 0.86)
      .setAlpha(0)
      .setName("proximityGlow");
    const indicator = this.add.circle(-24, -3, 7, 0x5fd7c4, 0.92)
      .setStrokeStyle(2, 0xd5fff8, 0.88)
      .setName("mistIndicator");
    const machine = this.add.container(mister.x, mister.y, [
      this.add.ellipse(0, 25, 104, 22, 0x10252a, 0.38),
      proximityGlow,
      this.add.rectangle(0, 6, 92, 52, 0x18363d, 0.98).setStrokeStyle(3, 0x82cbd2, 0.92),
      this.add.rectangle(0, -14, 84, 11, 0x315f68, 1).setStrokeStyle(2, 0x9de3e5, 0.72),
      this.add.rectangle(-31, 7, 11, 35, 0x10282f, 0.96),
      this.add.rectangle(31, 7, 11, 35, 0x10282f, 0.96),
      indicator,
      this.add.circle(-24, -3, 2, 0xe8fffa, 1),
      this.add.rectangle(7, 2, 25, 13, 0x0b2028, 0.92).setStrokeStyle(1, 0x7bc8d0, 0.8),
      this.add.rectangle(7, 2, 15, 3, 0x9ef3df, 0.9),
      this.add.rectangle(48, -3, 25, 13, 0x1e4650, 1).setStrokeStyle(2, 0x9de3e5, 0.9),
      this.add.triangle(67, -3, 0, 0, 18, 7, 0, 14, 0xb8f1ef, 0.96),
      this.add.rectangle(-11, 25, 18, 6, 0x0f272d, 0.95),
      this.add.rectangle(11, 25, 18, 6, 0x0f272d, 0.95),
      this.add.text(0, 43, "喷雾机", {
        color: "#efffff",
        backgroundColor: "#102c36e8",
        fontFamily: "monospace",
        fontSize: "11px",
        padding: { x: 7, y: 3 }
      }).setOrigin(0.5)
    ]).setDepth(mister.y + 35)
      .setSize(150, 106)
      .setInteractive({ useHandCursor: true })
      .setName("qizhenMister");
    machine.setData("targetId", mister.id);
    machine.on("pointerdown", () => this.triggerPointerTarget(mister));
    const mistWisps = [0, 1, 2].map((index) => {
      const wisp = this.add.ellipse(mister.x + 73 + index * 11, mister.y - 3 - index * 4, 26, 12, 0xe8ffff, 0.12)
        .setDepth(mister.y + 30)
        .setScale(0.55)
        .setName("mistWisp");
      if (!this.reducedMotion) {
        this.tweens.add({
          targets: wisp,
          x: wisp.x + 52,
          y: wisp.y - 12,
          scaleX: 1.55,
          scaleY: 1.3,
          alpha: { from: 0.26, to: 0 },
          duration: 820,
          ease: "Cubic.easeOut",
          repeat: -1,
          delay: index * 340,
          repeatDelay: MIST_CYCLE_MS - 820
        });
      }
      return wisp;
    });
    if (!this.reducedMotion) {
      this.tweens.add({
        targets: indicator,
        alpha: { from: 0.45, to: 1 },
        scale: { from: 0.9, to: 1.12 },
        duration: MIST_CYCLE_MS / 2,
        ease: "Sine.easeInOut",
        yoyo: true,
        repeat: -1
      });
    }
    this.phaseVisuals.push(machine, ...mistWisps);

    const plaque = this.add.container(1518, 575, [
      this.add.rectangle(4, 6, 220, 120, 0x21140d, 0.46),
      this.add.rectangle(0, 0, 216, 116, 0x402311, 0.99).setStrokeStyle(6, 0xd6a947, 1),
      this.add.rectangle(0, -48, 198, 4, 0xffdc7d, 0.68),
      this.add.text(0, -20, "启真湖", {
        color: "#ffd767", fontFamily: "monospace", fontSize: "24px", fontStyle: "bold"
      }).setOrigin(0.5),
      this.add.text(0, 26, "湖边步道", {
        color: "#f6e9c8", fontFamily: "monospace", fontSize: "13px"
      }).setOrigin(0.5),
      this.add.rectangle(-74, 49, 42, 3, 0xd6a947, 0.68),
      this.add.rectangle(74, 49, 42, 3, 0xd6a947, 0.68)
    ]).setDepth(720);
    this.phaseVisuals.push(plaque);

    const hud = this.add.container(750, 175).setScrollFactor(0).setDepth(5100);
    const shade = this.add.rectangle(3, 4, 384, 96, 0x020a10, 0.48);
    const panel = this.add.rectangle(0, 0, 384, 96, 0x07151f, 0.95).setStrokeStyle(3, 0x75ccd6, 0.9);
    const title = this.add.text(-168, -35, "喷雾时机", {
      color: "#8de7f0", fontFamily: "monospace", fontSize: "12px", fontStyle: "bold"
    }).setOrigin(0, 0.5);
    this.mistStatusText = this.add.text(168, -35, "", {
      color: "#d7fbff", fontFamily: "monospace", fontSize: "11px"
    }).setOrigin(1, 0.5).setName("mistStatus");
    const track = this.add.rectangle(0, 7, 304, 14, 0x102d3a, 1).setStrokeStyle(2, 0x28566a, 0.9);
    const windowGlow = this.add.rectangle(0, 7, 52, 28, 0x6cf0b5, 0.12)
      .setStrokeStyle(2, 0xb8ffe0, 0.96)
      .setName("mistWindowGlow");
    const tickMarks = [-120, -80, -40, 0, 40, 80, 120].map((x) => (
      this.add.rectangle(x, 7, x === 0 ? 3 : 2, x === 0 ? 21 : 12, x === 0 ? 0xb8ffe0 : 0x5a8290, x === 0 ? 0.86 : 0.56)
    ));
    const modeLabel = this.add.text(0, 34, "", {
      color: "#c9eef2", fontFamily: "monospace", fontSize: "11px"
    }).setOrigin(0.5).setName("mistModeLabel");
    const trail = [-16, -10, -5].map((x, index) => (
      this.add.circle(x, 0, Math.max(2, 5 - index), 0xffe98a, 0.14 + index * 0.12)
    ));
    const diamond = this.add.rectangle(0, 0, 12, 12, 0xfff0a1, 1)
      .setAngle(45)
      .setStrokeStyle(2, 0xffffff, 0.92)
      .setName("mistDiamond");
    this.mistMarker = this.add.container(-140, 7, [...trail, diamond]).setName("mistMarker");
    hud.add([shade, panel, title, this.mistStatusText, track, windowGlow, ...tickMarks, modeLabel, this.mistMarker]);
    this.mistHud = hud;
    if (!this.reducedMotion) {
      this.tweens.add({
        targets: windowGlow,
        alpha: { from: 0.54, to: 1 },
        scaleY: { from: 0.92, to: 1.08 },
        duration: 740,
        ease: "Sine.easeInOut",
        yoyo: true,
        repeat: -1
      });
    }
  }

  private updatePhaseVisuals(state: GameState): void {
    this.phaseVisuals.forEach((visual) => {
      if (visual.name === "reflectionArrow") {
        (visual as Phaser.GameObjects.Container).setVisible(state.qizhenLake.mode === "dark");
      }
      if (visual.name === "darkOnly") {
        (visual as Phaser.GameObjects.Rectangle).setVisible(state.qizhenLake.mode === "dark");
      }
      if (visual.name === "reflectionSpot") {
        (visual as Phaser.GameObjects.Container).setAlpha(state.qizhenLake.mode === "light" ? 1 : 0.24);
      }
      if (visual instanceof Phaser.GameObjects.Container && visual.getData("signIndex") !== undefined) {
        const signIndex = Number(visual.getData("signIndex"));
        const arrow = visual.getByName("arrow") as Phaser.GameObjects.Container | null;
        const rotation = state.qizhenLake.signRotations[signIndex];
        if (arrow && Number(arrow.getData("renderedRotation")) !== rotation) {
          arrow.setData("renderedRotation", rotation);
          const targetAngle = rotation * 90;
          this.tweens.killTweensOf(arrow);
          if (this.reducedMotion) {
            arrow.setAngle(targetAngle);
          } else {
            this.tweens.add({
              targets: arrow,
              angle: targetAngle,
              scale: { from: 1.14, to: 1 },
              duration: 210,
              ease: "Back.easeOut"
            });
          }
        }
        visual.setAlpha(state.qizhenLake.mode === "light" ? 1 : 0.9);
      }
      if (visual.name === "qizhenDecoyIdleGuide") {
        (visual as Phaser.GameObjects.Container)
          .setVisible(state.qizhenLake.mode === "light" && !state.qizhenLake.decoyPlacedAt)
          .setAlpha(state.ui.selectedItem === "decoyPaper" ? 0.08 : 0.2);
      }
      if (visual.name === "decoyPlacedPaper" && visual instanceof Phaser.GameObjects.Container) {
        const placed = state.qizhenLake.decoyPlacedAt === visual.getData("targetValue");
        const previouslyPlaced = visual.getData("renderedPlaced") === true;
        visual.setVisible(placed);
        if (placed && !previouslyPlaced) {
          visual.setData("renderedPlaced", true);
          if (!this.reducedMotion) {
            visual.setScale(0.42).setAngle(-12);
            this.tweens.add({
              targets: visual,
              scale: 1,
              angle: 0,
              duration: 280,
              ease: "Back.easeOut"
            });
          }
        }
      }
    });
    const showDecoyGuides = state.qizhenLake.phase === "decoy_setup"
      && state.qizhenLake.mode === "light"
      && state.ui.selectedItem === "decoyPaper"
      && !state.qizhenLake.decoyPlacedAt;
    this.decoyDropGuides.forEach((guide) => guide.setVisible(showDecoyGuides));
    if (state.qizhenLake.phase === "reflection_hunt") {
      const expected = QIZHEN_REFLECTION_REAL_SEQUENCE[Math.min(state.qizhenLake.reflectionRound, 2)];
      const ghostX = expected === "right" ? 430 : expected === "left" ? 1240 : 836;
      const ghost = this.phaseVisuals.find((visual) => visual.name === "reflectionGhost") as Phaser.GameObjects.Container | undefined;
      if (ghost && Number(ghost.getData("reflectionRound")) !== state.qizhenLake.reflectionRound) {
        ghost.setData("reflectionRound", state.qizhenLake.reflectionRound);
        this.tweens.killTweensOf(ghost);
        if (this.reducedMotion) {
          ghost.setX(ghostX);
        } else {
          this.tweens.add({
            targets: ghost,
            x: ghostX,
            alpha: { from: 0.36, to: 1 },
            duration: 460,
            ease: "Cubic.easeOut"
          });
        }
      }
      ghost?.setVisible(state.qizhenLake.mode === "dark");
    }
    const showMistHud = state.qizhenLake.phase === "mist_timing"
      && (state.qizhenLake.mode === "dark" || state.qizhenLake.mistRhythmRead);
    this.mistHud?.setVisible(showMistHud);
    const modeLabel = this.mistHud?.getByName("mistModeLabel") as Phaser.GameObjects.Text | null;
    modeLabel?.setText(state.qizhenLake.mode === "dark"
      ? "看纸条怎么过中线"
      : "进绿框时启动喷雾");
    this.mistStatusText?.setText(state.qizhenLake.mistRhythmRead ? "看清了" : "先看一轮");
  }

  private getActiveTargets(state: GameState): QizhenLakeInteractionTarget[] {
    const targets: QizhenLakeInteractionTarget[] = QIZHEN_LAKE_TARGETS.filter((target) => target.kind === "exit");
    if (state.qizhenLake.phase === "reflection_hunt") {
      if (state.qizhenLake.mode === "dark") {
        targets.push(...QIZHEN_LAKE_TARGETS.filter((target) => target.kind === "water"));
      } else {
        targets.push(...QIZHEN_LAKE_TARGETS.filter((target) => target.kind === "reflection_spot"));
      }
    } else if (state.qizhenLake.phase === "sign_alignment") {
      targets.push(...QIZHEN_LAKE_TARGETS.filter((target) => (
        state.qizhenLake.mode === "dark" ? target.kind === "water" : target.kind === "sign"
      )));
    } else if (state.qizhenLake.phase === "decoy_setup") {
      targets.push(...QIZHEN_LAKE_TARGETS.filter((target) => target.kind === "decoy_spot"));
    } else if (state.qizhenLake.phase === "mist_timing") {
      targets.push(...QIZHEN_LAKE_TARGETS.filter((target) => (
        state.qizhenLake.mode === "dark" ? target.kind === "water" : target.kind === "mister"
      )));
    }
    return targets;
  }

  private triggerTarget(target: QizhenLakeInteractionTarget, state: GameState): void {
    if (target.kind === "exit") {
      this.bridge.emit("rpg_qizhen_leave_requested");
      return;
    }
    if (target.kind === "water") {
      if (state.qizhenLake.phase === "reflection_hunt") {
        this.showFeedback(
          state.qizhenLake.mode === "dark" ? qizhenContent.reflection.darkWater : qizhenContent.reflection.lightWater,
          "system"
        );
      } else if (state.qizhenLake.phase === "sign_alignment") {
        this.showFeedback("水里的箭头缺了一截。", "task");
      } else if (state.qizhenLake.phase === "mist_timing") {
        this.bridge.emit("rpg_qizhen_mist_observe_requested");
      }
      return;
    }
    if (target.kind === "reflection_spot") {
      this.bridge.emit("rpg_qizhen_reflection_requested", { positionId: target.value });
      return;
    }
    if (target.kind === "sign") {
      this.bridge.emit("rpg_qizhen_sign_rotate_requested", { signIndex: Number(target.value) });
      return;
    }
    if (target.kind === "decoy_spot") {
      if (!state.items.reflectionCoordinate) {
        this.showFeedback(qizhenContent.decoy.missingCoordinate, "system");
        return;
      }
      this.showFeedback("假纸条夹这里。", "task");
      return;
    }
    if (target.kind === "mister") {
      if (state.qizhenLake.mode === "dark") {
        this.showFeedback(qizhenContent.mist.darkPrompt, "system");
        return;
      }
      if (!state.qizhenLake.mistRhythmRead) {
        this.showFeedback(qizhenContent.mist.lightPrompt, "system");
        return;
      }
      const success = this.lastMistPhase >= MIST_WINDOW_START && this.lastMistPhase <= MIST_WINDOW_END;
      this.bridge.emit("rpg_qizhen_mist_trigger_requested", { success });
    }
  }

  private triggerPointerTarget(target: QizhenLakeInteractionTarget): void {
    const state = this.bridge.getState();
    if (this.dialogueLocked || this.phaseTransitioning) return;
    if (!this.getActiveTargets(state).some((candidate) => candidate.id === target.id)) return;
    if (!findNearestQizhenTarget(this.player.x, this.player.y, [target])) return;
    this.triggerTarget(target, state);
  }

  private updatePrompt(target: QizhenLakeInteractionTarget | null, state: GameState): void {
    this.updateTargetProximity(target?.id ?? null);
    if (!target || this.dialogueLocked || this.phaseTransitioning) {
      this.promptText.setVisible(false);
      return;
    }
    const label = target.kind === "exit"
      ? "离开湖区"
      : target.kind === "water"
        ? state.qizhenLake.phase === "mist_timing" ? "看水面" : "看倒影"
        : target.kind === "reflection_spot"
          ? "拦住纸条"
          : target.kind === "sign"
            ? "转动指示牌"
            : target.kind === "decoy_spot"
              ? "夹上假纸条"
              : "启动喷雾";
    this.promptText
      .setText(target.kind === "decoy_spot" ? formatRpgDragHint("假纸条 → 蓝色夹位") : formatRpgInteractionHint(label))
      .setVisible(true);
  }

  private updateTargetProximity(targetId: string | null): void {
    this.phaseVisuals.forEach((visual) => {
      if (!(visual instanceof Phaser.GameObjects.Container)) return;
      const visualTargetId = String(visual.getData("targetId") ?? "");
      const proximityGlow = visual.getByName("proximityGlow") as
        | Phaser.GameObjects.Shape
        | Phaser.GameObjects.Container
        | null;
      if (!proximityGlow) return;
      proximityGlow.setAlpha(visualTargetId === targetId ? 0.92 : 0);
    });
  }

  private handleInventoryDrop(payload?: Record<string, unknown>): void {
    const itemId = String(payload?.itemId ?? "") as ItemId;
    const canvasX = Number(payload?.canvasX);
    const canvasY = Number(payload?.canvasY);
    if (!Number.isFinite(canvasX) || !Number.isFinite(canvasY)) {
      this.bridge.emit("rpg_item_use_feedback", { itemId, reason: "missed_target" });
      return;
    }
    const world = this.cameras.main.getWorldPoint(canvasX, canvasY);
    const state = this.bridge.getState();
    const activeTargets = this.getActiveTargets(state);
    const result = resolveRpgItemDrop({
      targets: activeTargets,
      itemId,
      dropX: world.x,
      dropY: world.y,
      playerX: this.player.x,
      playerY: this.player.y,
      mode: state.qizhenLake.mode
    });
    if (!result.target) {
      this.bridge.emit("rpg_item_use_feedback", {
        itemId,
        reason: "missed_target",
        detail: "没夹住。把假纸条拖进蓝色夹位。"
      });
      return;
    }
    const targetLabel = result.target.label;
    if (result.kind === "wrong_item") {
      this.bridge.emit("rpg_item_use_feedback", {
        itemId,
        reason: result.target.acceptedItem ? "wrong_item" : "locked",
        targetLabel
      });
      return;
    }
    if (result.kind === "wrong_mode") {
      this.bridge.emit("rpg_item_use_feedback", {
        itemId,
        reason: "locked",
        targetLabel,
        detail: formatRpgModeRequirement(result.expectedMode ?? "light")
      });
      return;
    }
    if (!state.qizhenLake.signsSolved || !state.items.reflectionCoordinate) {
      this.bridge.emit("rpg_item_use_feedback", {
        itemId,
        reason: "locked",
        targetLabel,
        detail: "还不能放。先把三块指示牌转对，再记下倒影位置。"
      });
      return;
    }
    if (result.kind === "too_far") {
      this.bridge.emit("rpg_item_use_feedback", {
        itemId,
        reason: "too_far",
        targetLabel,
        detail: "位置对了。先站到夹位前的脚印上。"
      });
      return;
    }
    if (result.kind !== "accepted") return;
    const target = result.target;
    this.bridge.emit("rpg_qizhen_decoy_requested", { targetId: target.value as QizhenDecoyTargetId });
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
    if (name === "qizhen_mode_changed") {
      this.playModeTransition(String(payload?.mode) === "dark" ? "dark" : "light");
      return;
    }
    if (name === "qizhen_reflection_wrong") {
      this.showFeedback(qizhenContent.reflection.wrong, "system");
      return;
    }
    if (name === "qizhen_reflection_correct") {
      this.animateReflectionHit(false);
      return;
    }
    if (name === "qizhen_reflection_completed") {
      this.animateReflectionHit(true);
      return;
    }
    if (name === "qizhen_sign_rotated") {
      this.showFeedback(qizhenContent.signs.wrong, "system");
      return;
    }
    if (name === "qizhen_signs_completed") {
      this.showFeedback(qizhenContent.signs.correct, "success");
      return;
    }
    if (name === "qizhen_decoy_wrong") {
      this.showFeedback(qizhenContent.decoy.missingCoordinate, "system");
      return;
    }
    if (name === "qizhen_decoy_placed") {
      this.showFeedback(qizhenContent.decoy.correct, "success");
      return;
    }
    if (name === "qizhen_decoy_revealed") {
      this.showFeedback(qizhenContent.decoy.darkReveal, "system");
      return;
    }
    if (name === "qizhen_mist_rhythm_read") {
      this.showFeedback("纸条每隔一会儿会从湖心经过。", "task");
      return;
    }
    if (name === "qizhen_mist_wrong") {
      this.animateMist(false);
      return;
    }
    if (name === "qizhen_mist_completed") {
      this.animateMist(true);
    }
  }

  private syncState(state: GameState): void {
    if (state.qizhenLake.phase !== this.currentPhase && !this.phaseTransitioning) {
      const previousPhase = this.currentPhase;
      this.currentPhase = state.qizhenLake.phase;
      this.transitionToPhase(state, previousPhase);
    }
    if (state.qizhenLake.mode !== this.currentMode) {
      this.playModeTransition(state.qizhenLake.mode);
    }
  }

  private transitionToPhase(state: GameState, previousPhase: GameState["qizhenLake"]["phase"]): void {
    const plate = plateForQizhenPhase(state.qizhenLake.phase);
    this.phaseTransitioning = true;
    const fadeMs = this.reducedMotion ? 60 : 180;
    this.cameras.main.fadeOut(fadeMs, 6, 16, 26);
    this.time.delayedCall(fadeMs, () => {
      this.rebuildPlate(plate, true);
      this.rebuildPhaseVisuals(state);
      this.cameras.main.fadeIn(fadeMs, 6, 16, 26);
      this.phaseTransitioning = false;
      if (state.qizhenLake.phase === "sign_alignment" && previousPhase === "reflection_hunt") {
        this.queueDialogue(qizhenContent.signs.dialogue);
      } else if (state.qizhenLake.phase === "decoy_setup" && previousPhase === "sign_alignment") {
        this.queueDialogue(qizhenContent.decoy.dialogue);
      }
    });
  }

  private playModeTransition(mode: QizhenLakeMode): void {
    this.currentMode = mode;
    if (!this.darkOverlay) return;
    this.tweens.killTweensOf(this.darkOverlay);
    this.tweens.add({
      targets: this.darkOverlay,
      alpha: mode === "dark" ? 0.64 : 0,
      duration: this.reducedMotion ? 60 : 260,
      ease: "Cubic.easeInOut"
    });
  }

  private updateMistTiming(state: GameState): void {
    if (state.qizhenLake.phase !== "mist_timing") return;
    this.lastMistPhase = (this.time.now % MIST_CYCLE_MS) / MIST_CYCLE_MS;
    const markerX = -140 + this.lastMistPhase * 280;
    const inWindow = this.lastMistPhase >= MIST_WINDOW_START && this.lastMistPhase <= MIST_WINDOW_END;
    this.mistMarker?.setX(markerX).setScale(inWindow ? 1.18 : 1);
    const diamond = this.mistMarker?.getByName("mistDiamond") as Phaser.GameObjects.Rectangle | null;
    diamond?.setFillStyle(inWindow ? 0xb8ffe0 : 0xfff0a1, 1);
    this.mistStatusText?.setText(inWindow
      ? state.qizhenLake.mode === "dark" ? "经过中线" : "现在可以喷"
      : state.qizhenLake.mistRhythmRead ? "等它进框" : "先看一轮");
  }

  private updateOcclusion(): void {
    const body = this.player.body as Phaser.Physics.Arcade.Body | null;
    const footY = body?.bottom ?? this.player.y;
    const playerBounds = this.player.getBounds();
    const active: string[] = [];
    const softened: string[] = [];
    this.occlusionVisuals.forEach((visual) => {
      const horizontalOverlap = playerBounds.right > visual.bounds.left && playerBounds.left < visual.bounds.right;
      const behind = horizontalOverlap && footY < visual.definition.sortY - 1;
      const intersects = behind && Phaser.Geom.Intersects.RectangleToRectangle(playerBounds, visual.bounds);
      const targetAlpha = intersects ? 0.48 : 1;
      visual.image
        .setDepth(behind ? this.player.depth + 2 : -900)
        .setVisible(behind)
        .setAlpha(this.reducedMotion ? targetAlpha : Phaser.Math.Linear(visual.image.alpha, targetAlpha, 0.18));
      if (behind) active.push(visual.definition.id);
      if (intersects) softened.push(visual.definition.id);
    });
    this.activeOcclusionIds = active;
    this.softenedOcclusionIds = softened;
  }

  private animateReflectionHit(complete: boolean): void {
    this.showFeedback(qizhenContent.reflection.correct, complete ? "success" : "system");
    this.cameras.main.shake(this.reducedMotion ? 60 : 180, 0.004);
  }

  private animateMist(success: boolean): void {
    const mist = this.add.rectangle(836, 470, 1500, 360, 0xeafcff, 0).setDepth(1800);
    this.tweens.add({
      targets: mist,
      alpha: success ? 0.9 : 0.55,
      duration: this.reducedMotion ? 80 : 360,
      yoyo: !success,
      onComplete: () => {
        if (!success) {
          mist.destroy();
          this.queueDialogue(qizhenContent.mist.wrongDialogue);
          return;
        }
        const paper = this.add.image(836, 450, PAPER_TEXTURE_KEY).setDepth(2200).setScale(0.8);
        this.tweens.add({
          targets: paper,
          x: 1150,
          y: 700,
          angle: 420,
          scale: 1.5,
          duration: this.reducedMotion ? 160 : 880,
          ease: "Cubic.easeOut",
          onComplete: () => {
            mist.destroy();
            paper.destroy();
            this.queueDialogue(qizhenContent.mist.successDialogue);
          }
        });
      }
    });
  }

  private ensurePaperTexture(): void {
    if (this.textures.exists(PAPER_TEXTURE_KEY)) return;
    const graphics = this.add.graphics();
    graphics.fillStyle(0xece8d8).fillPoints([
      new Phaser.Geom.Point(3, 4),
      new Phaser.Geom.Point(34, 7),
      new Phaser.Geom.Point(29, 35),
      new Phaser.Geom.Point(7, 31)
    ], true);
    graphics.lineStyle(3, 0x5a6870, 0.95).strokePoints([
      new Phaser.Geom.Point(3, 4),
      new Phaser.Geom.Point(34, 7),
      new Phaser.Geom.Point(29, 35),
      new Phaser.Geom.Point(7, 31)
    ], true);
    graphics.lineStyle(2, 0x76878e, 0.9).lineBetween(10, 14, 26, 16).lineBetween(9, 22, 24, 24);
    graphics.generateTexture(PAPER_TEXTURE_KEY, 38, 38);
    graphics.destroy();
  }

  private queueDialogue(lines: readonly string[], onComplete?: () => void): void {
    this.dialogueLocked = true;
    lines.forEach((text, index) => {
      this.time.delayedCall(index * DIALOGUE_STEP_MS, () => this.showFeedback(text, this.dialogueToneFor(text)));
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
    this.bridge.emit("rpg_subtitle", { text, tone, durationMs: DIALOGUE_STEP_MS - 120 });
  }

  private publishDebugState(target: QizhenLakeInteractionTarget | null, state: GameState): void {
    const plate = QIZHEN_LAKE_PLATES[this.currentPlate];
    setRpgRuntimeDebugState({
      coordinateSystem: "Phaser world coordinates, origin at top-left, x right, y down",
      world: QIZHEN_LAKE_WORLD,
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
      scene: "qizhen_lake",
      checkpoint: state.rpgCheckpoint,
      activeTargets: this.getActiveTargets(state).map((candidate) => ({
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
      collisionRects: plate.collisions,
      qizhenLake: {
        phase: state.qizhenLake.phase,
        mode: state.qizhenLake.mode,
        plate: this.currentPlate,
        activeTarget: target?.id ?? null,
        reflectionRound: state.qizhenLake.reflectionRound,
        signRotations: state.qizhenLake.signRotations,
        decoyPlacedAt: state.qizhenLake.decoyPlacedAt,
        mistRhythmRead: state.qizhenLake.mistRhythmRead,
        mistPhase: Number(this.lastMistPhase.toFixed(3)),
        activeOcclusionIds: this.activeOcclusionIds,
        softenedOcclusionIds: this.softenedOcclusionIds
      }
    });
  }
}

function checkpointForPhase(phase: GameState["qizhenLake"]["phase"]): GameState["rpgCheckpoint"] {
  if (phase === "sign_alignment") return "qizhen_signs";
  if (phase === "decoy_setup") return "qizhen_decoy";
  if (phase === "mist_timing" || phase === "chase_ready") return "qizhen_mist";
  return "qizhen_reflection";
}
