import Phaser from "phaser";
import qizhenDecoyUrl from "../../assets/rpg/interiors/qizhen_lake_decoy.png";
import qizhenMistUrl from "../../assets/rpg/interiors/qizhen_lake_mist.png";
import qizhenReflectionUrl from "../../assets/rpg/interiors/qizhen_lake_reflection.png";
import qizhenSignsUrl from "../../assets/rpg/interiors/qizhen_lake_signs.png";
import type { GameSubtitleTone } from "../../components/GameSubtitleFrame";
import type { GameState, QizhenDecoyTargetId, QizhenLakeMode } from "../../core/types";
import qizhenContent from "../../data/chapter3-qizhen-lake.content.json";
import { QIZHEN_REFLECTION_REAL_SEQUENCE } from "../../modules/ChapterThreeQizhenLakeController";
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
  private activeOcclusionIds: string[] = [];
  private softenedOcclusionIds: string[] = [];
  private mistHud: Phaser.GameObjects.Container | null = null;
  private mistMarker: Phaser.GameObjects.Arc | null = null;
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
    if (state.actOne.movementEnabled && !this.dialogueLocked && !this.phaseTransitioning && vector.lengthSq() > 0) {
      vector.normalize().scale(this.keys.SHIFT.isDown ? RUN_SPEED : WALK_SPEED);
    } else {
      vector.set(0, 0);
    }
    this.player.setVelocity(vector.x, vector.y).setDepth(this.player.y + 120);
    this.playerAnimator.update(vector, this.time.now);
    this.updateOcclusion();
    this.updateMistTiming(state);
    this.updatePhaseVisuals(state);

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
    this.phaseVisuals.forEach((visual) => visual.destroy());
    this.phaseVisuals = [];
    this.mistHud?.destroy();
    this.mistHud = null;
    this.mistMarker = null;

    this.createExitMarker();
    if (state.qizhenLake.phase === "reflection_hunt") this.createReflectionVisuals(state);
    else if (state.qizhenLake.phase === "sign_alignment") this.createSignVisuals(state);
    else if (state.qizhenLake.phase === "decoy_setup") this.createDecoyVisuals();
    else if (state.qizhenLake.phase === "mist_timing" || state.qizhenLake.phase === "chase_ready") {
      this.createMistVisuals(state);
    }
  }

  private createExitMarker(): void {
    const target = QIZHEN_LAKE_TARGETS.find((candidate) => candidate.kind === "exit")!;
    const marker = this.add.container(target.x, target.y, [
      this.add.rectangle(-20, -22, 5, 52, 0x284c47, 1),
      this.add.triangle(-3, -35, 0, 0, 28, 13, 0, 26, 0x9ee0c7, 0.96),
      this.add.text(8, 10, "返回校园", {
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
    const ghost = this.add.container(ghostX, 390, [
      this.add.ellipse(0, 0, 92, 30, 0x7edfff, 0.16).setStrokeStyle(3, 0x9ceaff, 0.9),
      this.add.image(0, 0, PAPER_TEXTURE_KEY).setAlpha(0.88)
    ]).setDepth(1650);
    this.phaseVisuals.push(ghost);
    QIZHEN_LAKE_TARGETS.filter((target) => target.kind === "reflection_spot").forEach((target) => {
      const marker = this.add.container(target.x, target.y, [
        this.add.ellipse(0, 5, 48, 18, 0xf0dc89, 0.1).setStrokeStyle(2, 0xeed97a, 0.46),
        this.add.rectangle(-17, -3, 10, 3, 0xfff0a8, 0.7).setAngle(-25),
        this.add.rectangle(17, -3, 10, 3, 0xfff0a8, 0.7).setAngle(25),
        this.add.circle(0, 1, 3, 0xfff6c9, 0.92)
      ]).setDepth(target.y + 30).setSize(86, 86).setInteractive({ useHandCursor: true });
      marker.on("pointerdown", () => this.triggerPointerTarget(target));
      this.phaseVisuals.push(marker);
    });
  }

  private createSignVisuals(state: GameState): void {
    const signs = QIZHEN_LAKE_TARGETS.filter((target) => target.kind === "sign");
    signs.forEach((target, index) => {
      const sign = this.add.container(target.x, target.y, [
        this.add.ellipse(0, 35, 42, 10, 0x142520, 0.28),
        this.add.rectangle(0, 7, 7, 62, 0x304b46, 1).setStrokeStyle(1, 0x8ca79f, 0.8),
        this.add.rectangle(0, -28, 166, 48, 0xd9e4df, 0.97).setStrokeStyle(3, 0x315a55, 1),
        this.add.text(0, -36, qizhenContent.signs.labels[index], {
          color: "#203f3b",
          fontFamily: "monospace",
          fontSize: "11px",
          align: "center"
        }).setOrigin(0.5),
        this.add.text(0, -17, "➜", {
          color: "#28758a",
          fontFamily: "monospace",
          fontSize: "20px"
        }).setOrigin(0.5).setName("arrow")
      ]).setDepth(target.y + 40).setSize(184, 112).setInteractive({ useHandCursor: true });
      sign.setData("signIndex", index);
      sign.on("pointerdown", () => this.triggerPointerTarget(target));
      this.phaseVisuals.push(sign);
    });
    const reflectionArrow = this.add.text(836, 445, "◀   ◇   ▶", {
      color: "#9beaff",
      fontFamily: "monospace",
      fontSize: "22px"
    }).setOrigin(0.5).setAlpha(0.86).setDepth(1650).setName("reflectionArrow");
    this.phaseVisuals.push(reflectionArrow);
    this.updatePhaseVisuals(state);
  }

  private createDecoyVisuals(): void {
    QIZHEN_LAKE_TARGETS.filter((target) => target.kind === "decoy_spot").forEach((target) => {
      const kind = target.value ?? "notice";
      const children: Phaser.GameObjects.GameObject[] = [this.add.ellipse(0, 4, 48, 12, 0x11231d, 0.3)];
      if (kind === "lamp") {
        children.push(
          this.add.rectangle(0, -76, 7, 154, 0x24383b, 1).setStrokeStyle(1, 0x779094, 0.75),
          this.add.rectangle(0, -154, 38, 45, 0x23353a, 1).setStrokeStyle(3, 0x80989b, 0.9),
          this.add.rectangle(0, -154, 22, 27, 0xffefad, 0.62),
          this.add.triangle(0, -182, -24, 16, 0, 0, 24, 16, 0x1c2d31, 1),
          this.add.rectangle(0, 3, 30, 7, 0x1c3032, 1)
        );
      } else if (kind === "bridge") {
        children.push(
          this.add.rectangle(0, -18, 7, 52, 0x3b5045, 1),
          this.add.rectangle(0, -48, 112, 42, 0xb8cbb9, 0.96).setStrokeStyle(3, 0x3a5e54, 1),
          this.add.text(0, -48, "桥中告示", {
            color: "#2b4a42", fontFamily: "monospace", fontSize: "11px"
          }).setOrigin(0.5)
        );
      } else {
        children.push(
          this.add.rectangle(-28, -20, 6, 54, 0x544a36, 1),
          this.add.rectangle(28, -20, 6, 54, 0x544a36, 1),
          this.add.rectangle(0, -55, 110, 52, 0xe6dfbd, 0.97).setStrokeStyle(3, 0x695c3d, 1),
          this.add.text(0, -55, "湖区公告", {
            color: "#51472f", fontFamily: "monospace", fontSize: "11px"
          }).setOrigin(0.5)
        );
      }
      const marker = this.add.container(target.x, target.y, children)
        .setDepth(target.y + 38)
        .setSize(kind === "lamp" ? 120 : 150, kind === "lamp" ? 210 : 110)
        .setInteractive({ useHandCursor: true });
      marker.on("pointerdown", () => this.triggerPointerTarget(target));
      this.phaseVisuals.push(marker);
    });
  }

  private createMistVisuals(state: GameState): void {
    const mister = QIZHEN_LAKE_TARGETS.find((target) => target.kind === "mister")!;
    const machine = this.add.container(mister.x, mister.y, [
      this.add.ellipse(0, 18, 86, 18, 0x10252a, 0.35),
      this.add.rectangle(0, 0, 78, 42, 0x244f58, 0.98).setStrokeStyle(3, 0x9de3e5, 0.9),
      this.add.circle(-19, 0, 9, 0x9de3e5, 0.5),
      this.add.rectangle(20, -2, 16, 9, 0xd4ffff, 0.9),
      this.add.triangle(37, -2, 0, 0, 14, 6, 0, 12, 0xb8f1ef, 0.9),
      this.add.text(0, 34, "喷雾", {
        color: "#efffff", backgroundColor: "#102c36cc", fontFamily: "monospace", fontSize: "11px", padding: { x: 6, y: 2 }
      }).setOrigin(0.5)
    ]).setDepth(mister.y + 35).setSize(118, 82).setInteractive({ useHandCursor: true });
    machine.on("pointerdown", () => this.triggerPointerTarget(mister));
    this.phaseVisuals.push(machine);

    const plaque = this.add.container(1518, 575, [
      this.add.rectangle(0, 0, 208, 112, 0x402311, 0.99).setStrokeStyle(6, 0xd6a947, 1),
      this.add.text(0, -16, "启真湖", {
        color: "#ffd767", fontFamily: "monospace", fontSize: "24px"
      }).setOrigin(0.5),
      this.add.text(0, 26, "倒影观测区", {
        color: "#f6e9c8", fontFamily: "monospace", fontSize: "13px"
      }).setOrigin(0.5)
    ]).setDepth(720);
    this.phaseVisuals.push(plaque);

    const hud = this.add.container(480, 454).setScrollFactor(0).setDepth(5100);
    const shade = this.add.rectangle(0, 0, 360, 74, 0x07151f, 0.94).setStrokeStyle(3, 0x75ccd6, 0.9);
    const track = this.add.rectangle(0, 12, 300, 12, 0x183847, 1);
    const window = this.add.rectangle(0, 12, 42, 20, 0x7ee2b8, 0.38).setStrokeStyle(2, 0xb8ffe0, 0.9);
    const label = this.add.text(0, -18, state.qizhenLake.mode === "dark" ? "观察残影经过中央的节奏" : "在中央区启动喷雾", {
      color: "#e8fdff", fontFamily: "monospace", fontSize: "13px"
    }).setOrigin(0.5);
    this.mistMarker = this.add.circle(-140, 12, 7, 0xfff3a4, 1);
    hud.add([shade, track, window, label, this.mistMarker]);
    this.mistHud = hud;
  }

  private updatePhaseVisuals(state: GameState): void {
    this.phaseVisuals.forEach((visual) => {
      if (visual.name === "reflectionArrow") {
        (visual as Phaser.GameObjects.Text).setVisible(state.qizhenLake.mode === "dark");
      }
      if (visual instanceof Phaser.GameObjects.Container && visual.getData("signIndex") !== undefined) {
        const signIndex = Number(visual.getData("signIndex"));
        const arrow = visual.getByName("arrow") as Phaser.GameObjects.Text | null;
        arrow?.setAngle(state.qizhenLake.signRotations[signIndex] * 90);
      }
    });
    if (state.qizhenLake.phase === "reflection_hunt") {
      const expected = QIZHEN_REFLECTION_REAL_SEQUENCE[Math.min(state.qizhenLake.reflectionRound, 2)];
      const ghostX = expected === "right" ? 430 : expected === "left" ? 1240 : 836;
      const ghost = this.phaseVisuals.find((visual) => visual instanceof Phaser.GameObjects.Container
        && visual.y === 390) as Phaser.GameObjects.Container | undefined;
      ghost?.setX(ghostX).setVisible(state.qizhenLake.mode === "dark");
    }
    this.mistHud?.setVisible(state.qizhenLake.phase === "mist_timing" && (state.qizhenLake.mode === "dark" || state.qizhenLake.mistRhythmRead));
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
        this.showFeedback("深色模式观察倒影箭头缺口。", "task");
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
      this.showFeedback("把假纸条拖到这里。", "task");
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
    if (!target || this.dialogueLocked || this.phaseTransitioning) {
      this.promptText.setVisible(false);
      return;
    }
    const label = target.kind === "exit"
      ? "返回校园地图"
      : target.kind === "water"
        ? state.qizhenLake.phase === "mist_timing" ? "观察残影节奏" : "查看湖面倒影"
        : target.kind === "reflection_spot"
          ? "在现实位置拦截"
          : target.kind === "sign"
            ? "旋转反光警示牌"
            : target.kind === "decoy_spot"
              ? "拖入假纸条"
              : "启动自动喷雾";
    this.promptText.setText(formatRpgInteractionHint(label)).setVisible(true);
  }

  private handleInventoryDrop(payload?: Record<string, unknown>): void {
    const itemId = String(payload?.itemId ?? "");
    if (itemId !== "decoyPaper") return;
    const canvasX = Number(payload?.canvasX);
    const canvasY = Number(payload?.canvasY);
    if (!Number.isFinite(canvasX) || !Number.isFinite(canvasY)) return;
    const world = this.cameras.main.getWorldPoint(canvasX, canvasY);
    const target = this.getActiveTargets(this.bridge.getState())
      .filter((candidate) => candidate.acceptedItem === itemId)
      .find((candidate) => Math.hypot(world.x - candidate.x, world.y - candidate.y) <= Math.max(125, candidate.proximity));
    if (!target || !findNearestQizhenTarget(this.player.x, this.player.y, [target])) return;
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
      this.showFeedback("深色模式：残影会周期性经过湖面中央。", "task");
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
    this.mistMarker?.setX(-140 + this.lastMistPhase * 280);
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
        x: candidate.x,
        y: candidate.y,
        width: candidate.proximity * 2,
        height: candidate.proximity * 2,
        acceptedItem: candidate.acceptedItem
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
