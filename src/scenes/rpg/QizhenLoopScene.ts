import Phaser from "phaser";
import type { GameSubtitleTone } from "../../components/GameSubtitleFrame";
import { selectIdentityReadable } from "../../core/IdentityAccess";
import type { GameState } from "../../core/types";
import actOneContent from "../../data/act-one-bootstrap.content.json";
import qizhenContent from "../../data/chapter3-qizhen-lake.content.json";
import type { RpgBridge } from "./RpgBridge";
import { clearRpgRuntimeDebugState, setRpgRuntimeDebugState } from "./RpgRuntimeDebug";
import { CampusPathGrid, type CampusPathPoint } from "./CampusPathfinder";
import { RpgCameraController } from "./RpgCameraController";
import { RpgMovementController } from "./RpgMovementController";
import {
  applyCampusRpgPlayerPerspectiveScale,
  configureRpgPlayerSprite,
  ensureRpgPlayerTextures,
  preloadRpgPlayerTextures,
  type RpgPlayerPerspectiveMetrics,
  RPG_PLAYER_WALK_FPS,
  RpgPlayerAnimator
} from "./RpgPlayerTextures";
import { formatRpgInteractionHint } from "./RpgControlHints";
import { subscribeRpgSceneBridge } from "./RpgSceneBridgeSubscription";
import {
  drawQizhenLoopWorld,
  preloadQizhenLoopWorld,
  QIZHEN_LOOP_RUNTIME
} from "./QizhenLoopWorld";

const RPG_LOGICAL_WIDTH = 960;
const RPG_LOGICAL_HEIGHT = 540;
const CAMERA_MIN_ZOOM = 0.7;
const CAMERA_MAX_ZOOM = 1.8;
const CAMERA_DEFAULT_ZOOM = 1.1;
const CAMERA_ZOOM_STEP = 0.125;
const MAX_RENDER_SCALE = 3;
const CORRIDOR_LEFT = QIZHEN_LOOP_RUNTIME.theater.approach.x - 260;
const CORRIDOR_RIGHT = QIZHEN_LOOP_RUNTIME.qizhen.gate.x + 250;
const PATH_DOT_RADIUS = 7;
// 过渡字幕时长分档(对齐食堂 queueDialogue):叙述短句 2400、对白句 2800、任务/指引类 4200,逐句间隔 120ms。
const TRANSITION_NARRATOR_MS = 2400;
const TRANSITION_DIALOGUE_MS = 2800;
const TRANSITION_GUIDANCE_MS = 4200;
const TRANSITION_SUBTITLE_GAP_MS = 120;
// 启真湖入口文案:本场景不设独立 content.json,措辞沿用 chapter3-qizhen-lake locationSearch 的对话与任务提示。
const GATE_ENTRY_LABEL = "启真湖入口";
const GATE_LOCKED_PROMPT_LABEL = "查看入口";
const GATE_LOCKED_FEEDBACK = "系统：还没确认湿纸指向的地点。先核对论坛、馆藏记录和地图线索。";

export class QizhenLoopScene extends Phaser.Scene {
  private bridge!: RpgBridge;
  private player!: Phaser.Physics.Arcade.Sprite;
  private obstacles!: Phaser.Physics.Arcade.StaticGroup;
  private cursors!: Phaser.Types.Input.Keyboard.CursorKeys;
  private keys!: Record<"W" | "A" | "S" | "D" | "SHIFT", Phaser.Input.Keyboard.Key>;
  private virtualDirection = { x: 0, y: 0 };
  private interactRequested = false;
  private playerAnimator!: RpgPlayerAnimator;
  private playerPerspective!: RpgPlayerPerspectiveMetrics;
  private characterName!: Phaser.GameObjects.Text;
  private movement!: RpgMovementController;
  private pathGrid!: CampusPathGrid;
  private cameraController!: RpgCameraController;
  private pathIndicators: Phaser.GameObjects.Arc[] = [];
  private renderScale = 1;
  private cinematicActive = false;
  private briefingQueued = false;
  private transitionPaper: Phaser.GameObjects.Image | null = null;
  private transitionTrail: Phaser.GameObjects.Ellipse[] = [];
  private gateMarker!: Phaser.GameObjects.Arc;
  private gatePrompt!: Phaser.GameObjects.Text;

  constructor() {
    super("campus-qizhen-loop");
  }

  preload(): void {
    preloadQizhenLoopWorld(this);
    preloadRpgPlayerTextures(this);
  }

  create(): void {
    this.renderScale = this.enableNativeResolution();
    this.events.once(Phaser.Scenes.Events.SHUTDOWN, this.restoreLogicalResolution, this);
    this.bridge = this.registry.get("rpgBridge") as RpgBridge;
    this.physics.world.setBounds(0, 0, QIZHEN_LOOP_RUNTIME.world.width, QIZHEN_LOOP_RUNTIME.world.height);
    this.cameras.main.setBackgroundColor(0x080a0c);
    this.obstacles = this.physics.add.staticGroup();
    drawQizhenLoopWorld(this, {
      addObstacle: (x, y, width, height) => this.addObstacle(x, y, width, height)
    });

    ensureRpgPlayerTextures(this);
    const state = this.bridge.getState();
    const spawn = state.rpgCheckpoint === "campus_qizhen_gate"
      ? QIZHEN_LOOP_RUNTIME.qizhen.approach
      : state.rpgCheckpoint === "campus_qizhen_transition_stop"
        ? QIZHEN_LOOP_RUNTIME.qizhen.approachTransition.stop
        : QIZHEN_LOOP_RUNTIME.qizhen.approachTransition.start;
    this.player = this.physics.add.sprite(spawn.x, spawn.y, "act1-player-side-0");
    this.player.setCollideWorldBounds(true).setDepth(this.player.y + 30);
    configureRpgPlayerSprite(this.player);
    this.playerPerspective = applyCampusRpgPlayerPerspectiveScale(this.player, this.player.y);
    this.playerAnimator = new RpgPlayerAnimator(this.player, "side");
    this.physics.add.collider(this.player, this.obstacles);
    this.characterName = this.add.text(
      this.player.x,
      this.player.y - this.playerPerspective.nameOffsetY,
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
    this.pathGrid = new CampusPathGrid(QIZHEN_LOOP_RUNTIME.walkability, 24);
    this.movement = new RpgMovementController(this.player, { walkSpeed: 220, runSpeed: 320 });
    this.movement.onPathFinished = () => this.clearPathIndicators();
    this.cameraController = new RpgCameraController(this, {
      player: this.player,
      world: QIZHEN_LOOP_RUNTIME.world,
      minZoom: CAMERA_MIN_ZOOM * this.renderScale,
      maxZoom: CAMERA_MAX_ZOOM * this.renderScale,
      defaultZoom: CAMERA_DEFAULT_ZOOM * this.renderScale,
      zoomStep: CAMERA_ZOOM_STEP * this.renderScale,
      deadzoneRatio: { width: 300 / RPG_LOGICAL_WIDTH, height: 180 / RPG_LOGICAL_HEIGHT },
      followOffsetY: 34,
      minimap: null
    });
    this.cameraController.attach();
    this.cameraController.onWorldTap = (worldX, worldY) => this.handleWorldTap(worldX, worldY);

    this.createQizhenGate();
    subscribeRpgSceneBridge(this.events, this.bridge, (event) => {
      if (event.name === "rpg_direction_changed") {
        this.virtualDirection = { x: Number(event.payload?.x) || 0, y: Number(event.payload?.y) || 0 };
      } else if (event.name === "rpg_camera_recenter") {
        this.cameraController.recenter(true);
      } else if (event.name === "rpg_camera_zoom") {
        this.cameraController.zoomBy(Number(event.payload?.delta) || 0);
      } else if (event.name === "rpg_interact") {
        this.interactRequested = true;
      }
    }, clearRpgRuntimeDebugState);

    if (
      state.qizhenLake.active
      && state.qizhenLake.phase === "location_search"
      && !state.qizhenLake.locationBriefingSeen
    ) {
      this.briefingQueued = true;
      this.time.delayedCall(160, () => this.startApproachTransition());
    }
    this.syncCharacterNameplate(state);
    this.bridge.emit("rpg_booted", { scene: "campus_qizhen_loop", projection: "side-view-pseudo-2.5d" });
  }

  update(_time: number, delta: number): void {
    const state = this.bridge.getState();
    this.playerPerspective = applyCampusRpgPlayerPerspectiveScale(this.player, this.player.y);
    this.syncCharacterNameplate(state);
    this.updateQizhenGate(state);
    this.publishDebugState();

    if (this.cinematicActive) {
      this.interactRequested = false;
      this.movement.setManualInput(0, 0, false);
      this.movement.clearPath();
      this.player.setVelocity(0);
      this.cameraController.update(delta);
      return;
    }

    const keyboardX = Number(this.cursors.right.isDown || this.keys.D.isDown)
      - Number(this.cursors.left.isDown || this.keys.A.isDown);
    const keyboardY = Number(this.cursors.down.isDown || this.keys.S.isDown)
      - Number(this.cursors.up.isDown || this.keys.W.isDown);
    this.movement.setManualInput(
      Phaser.Math.Clamp(keyboardX + this.virtualDirection.x, -1, 1),
      Phaser.Math.Clamp(keyboardY + this.virtualDirection.y, -1, 1),
      this.keys.SHIFT.isDown
    );
    const velocity = this.movement.update(delta);
    this.playerAnimator.update(velocity, this.time.now);
    this.player.x = Phaser.Math.Clamp(this.player.x, CORRIDOR_LEFT, CORRIDOR_RIGHT);
    this.player.setDepth(this.player.y + 30);
    this.interactRequested = false;
    this.cameraController.update(delta);
  }

  private createQizhenGate(): void {
    const gate = QIZHEN_LOOP_RUNTIME.qizhen.gate;
    this.gateMarker = this.add.circle(gate.x, gate.y, 27, 0x1c8297, 0.24)
      .setStrokeStyle(5, 0xa5e6d5, 0.96)
      .setDepth(gate.y + 85)
      .setVisible(false);
    this.gatePrompt = this.add.text(
      gate.x,
      gate.y - 56,
      `${GATE_ENTRY_LABEL}  ·  ${formatRpgInteractionHint("进入启真湖")}`,
      {
        color: "#effff8",
        backgroundColor: "#0d2930ee",
        fontFamily: "monospace",
        fontSize: "13px",
        padding: { x: 8, y: 5 },
        resolution: Math.max(2, window.devicePixelRatio || 1)
      }
    ).setOrigin(0.5).setDepth(gate.y + 90).setVisible(false);
    this.tweens.add({
      targets: this.gateMarker,
      scale: { from: 0.86, to: 1.18 },
      alpha: { from: 0.52, to: 1 },
      duration: 760,
      yoyo: true,
      repeat: -1,
      ease: "Sine.easeInOut"
    });
  }

  private updateQizhenGate(state: GameState): void {
    const phase = state.qizhenLake.phase;
    const active = state.qizhenLake.active && phase !== "inactive";
    const available = active && phase !== "location_search";
    const gate = QIZHEN_LOOP_RUNTIME.qizhen.gate;
    const nearby = active && Phaser.Math.Distance.Between(this.player.x, this.player.y, gate.x, gate.y) <= gate.radius;
    // 地点确认期间 marker 常显但压暗:既给出「去启真湖」的方向,又表明入口暂未开放。
    this.gateMarker
      .setVisible(active)
      .setFillStyle(0x1c8297, available ? 0.24 : 0.1)
      .setStrokeStyle(5, available ? 0xa5e6d5 : 0x5f8f86, available ? 0.96 : 0.62);
    this.gatePrompt.setVisible(nearby);
    if (nearby) {
      this.gatePrompt.setText(available
        ? `${GATE_ENTRY_LABEL}  ·  ${formatRpgInteractionHint("进入启真湖")}`
        : `${GATE_ENTRY_LABEL}  ·  ${formatRpgInteractionHint(GATE_LOCKED_PROMPT_LABEL)}`);
    }
    if (nearby && (Phaser.Input.Keyboard.JustDown(this.cursors.space) || this.interactRequested)) {
      if (available) {
        this.bridge.setCheckpoint("campus_qizhen_gate");
        this.bridge.emit("rpg_qizhen_entry_requested");
      } else {
        this.showFeedback(GATE_LOCKED_FEEDBACK, this.dialogueToneFor(GATE_LOCKED_FEEDBACK), TRANSITION_GUIDANCE_MS);
      }
    }
  }

  private startApproachTransition(): void {
    if (this.cinematicActive) return;
    const runtime = QIZHEN_LOOP_RUNTIME.qizhen.approachTransition;
    const content = qizhenContent.locationSearch.approachTransition;
    this.cinematicActive = true;
    this.movement.clearPath();
    this.clearPathIndicators();
    this.virtualDirection = { x: 0, y: 0 };
    this.player.setPosition(runtime.start.x, runtime.start.y).setVelocity(0);
    const body = this.player.body as Phaser.Physics.Arcade.Body | null;
    if (body) {
      body.stop();
      body.enable = false;
    }
    this.cameraController.beginCinematicFollow(-270, CAMERA_MIN_ZOOM * this.renderScale);
    this.ensureWetPaperTexture();
    this.transitionPaper = this.add.image(runtime.paperStart.x, runtime.paperStart.y, "qizhen-transition-wet-paper")
      .setDepth(runtime.paperStart.y + 140)
      .setAngle(-8);

    const trailStartX = runtime.paperStart.x + 28;
    const trailEndX = runtime.paperStop.x - 120;
    const trailCount = Math.max(6, Math.floor((trailEndX - trailStartX) / runtime.trailSpacing));
    for (let index = 0; index <= trailCount; index += 1) {
      const progress = index / Math.max(1, trailCount);
      const x = Phaser.Math.Linear(trailStartX, trailEndX, progress);
      const y = Phaser.Math.Linear(runtime.paperStart.y + 4, runtime.paperStop.y + 4, progress)
        + Math.sin(index * 1.7) * 3;
      const drop = this.add.ellipse(x, y, index % 3 === 0 ? 15 : 9, index % 2 === 0 ? 5 : 4, 0x8fd8e6, 0)
        .setDepth(y + 8);
      this.transitionTrail.push(drop);
      this.time.delayedCall(content.paperLeadMs + index * 95, () => {
        if (!drop.active) return;
        drop.setAlpha(0.72);
        this.tweens.add({ targets: drop, alpha: 0.18, scaleX: 1.45, duration: 860 });
      });
      this.time.delayedCall(content.trailFadeAtMs + index * 34, () => {
        if (!drop.active) return;
        this.tweens.add({ targets: drop, alpha: 0, duration: 900, onComplete: () => drop.destroy() });
      });
    }

    this.tweens.add({
      targets: this.transitionPaper,
      x: runtime.paperStop.x,
      y: runtime.paperStop.y,
      angle: 18,
      duration: 4550,
      ease: "Sine.easeInOut",
      onUpdate: (_tween, target) => {
        const paper = target as Phaser.GameObjects.Image;
        paper.setDepth(paper.y + 140).setScale(1 + Math.sin(this.time.now / 115) * 0.08);
      },
      onComplete: () => {
        if (!this.transitionPaper?.active) return;
        this.tweens.add({
          targets: this.transitionPaper,
          alpha: 0,
          y: runtime.paperStop.y - 18,
          duration: 720,
          onComplete: () => {
            this.transitionPaper?.destroy();
            this.transitionPaper = null;
          }
        });
      }
    });
    this.movePlayerThroughTransition(0);

    this.queueTransitionSubtitles(content.visualBeats, qizhenContent.locationSearch.dialogue);
    this.time.delayedCall(content.completeAtMs, () => this.finishApproachTransition());
  }

  // 剧场→启真湖过渡字幕:queueDialogue 式逐句步进,前一句展示完整时长后再出下一句。
  private queueTransitionSubtitles(
    visualBeats: readonly string[],
    dialogue: readonly string[]
  ): void {
    const lines: Array<{ text: string; durationMs: number }> = [];
    visualBeats.forEach((text, index) => {
      lines.push({ text, durationMs: TRANSITION_NARRATOR_MS });
      const reply = dialogue[index];
      if (reply) lines.push({ text: reply, durationMs: TRANSITION_DIALOGUE_MS });
    });
    // 末尾多出的对白是下一步行动指引,按任务/线索类时长展示。
    dialogue.slice(visualBeats.length).forEach((text) => {
      lines.push({ text, durationMs: TRANSITION_GUIDANCE_MS });
    });
    let atMs = 0;
    lines.forEach((line) => {
      this.time.delayedCall(atMs, () => {
        this.showFeedback(line.text, this.dialogueToneFor(line.text), line.durationMs);
      });
      atMs += line.durationMs + TRANSITION_SUBTITLE_GAP_MS;
    });
  }

  private dialogueToneFor(text: string): GameSubtitleTone {
    if (text.startsWith("玩家：")) return "player";
    if (text.startsWith("系统：")) return "system";
    if (text.startsWith("任务：")) return "task";
    return "narrator";
  }

  private showFeedback(text: string, tone: GameSubtitleTone, durationMs: number): void {
    this.bridge.emit("rpg_subtitle", { text, tone, durationMs });
  }

  private movePlayerThroughTransition(index: number): void {
    const waypoint = QIZHEN_LOOP_RUNTIME.qizhen.approachTransition.waypoints[index];
    if (!waypoint || !this.cinematicActive) {
      this.playerAnimator.update(new Phaser.Math.Vector2(0, 0), this.time.now);
      return;
    }
    let previousX = this.player.x;
    let previousY = this.player.y;
    this.tweens.add({
      targets: this.player,
      x: waypoint.x,
      y: waypoint.y,
      duration: waypoint.durationMs,
      ease: "Sine.easeInOut",
      onUpdate: () => {
        const direction = new Phaser.Math.Vector2(this.player.x - previousX, this.player.y - previousY);
        previousX = this.player.x;
        previousY = this.player.y;
        this.playerAnimator.update(direction, this.time.now);
        this.playerPerspective = applyCampusRpgPlayerPerspectiveScale(this.player, this.player.y);
        this.player.setDepth(this.player.y + 30);
      },
      onComplete: () => this.movePlayerThroughTransition(index + 1)
    });
  }

  private finishApproachTransition(): void {
    if (!this.cinematicActive) return;
    this.cinematicActive = false;
    const stop = QIZHEN_LOOP_RUNTIME.qizhen.approachTransition.stop;
    this.player.setPosition(stop.x, stop.y);
    const body = this.player.body as Phaser.Physics.Arcade.Body | null;
    if (body) {
      body.enable = true;
      body.reset(stop.x, stop.y);
    }
    this.player.setVelocity(0);
    this.transitionTrail.forEach((drop) => drop.destroy());
    this.transitionTrail = [];
    this.transitionPaper?.destroy();
    this.transitionPaper = null;
    this.cameraController.endCinematicFollow();
    this.bridge.setCheckpoint("campus_qizhen_transition_stop");
    this.bridge.emit("rpg_qizhen_location_briefing_seen_requested");
  }

  private ensureWetPaperTexture(): void {
    if (this.textures.exists("qizhen-transition-wet-paper")) return;
    const graphics = this.add.graphics();
    graphics.fillStyle(0x10222c, 0.34).fillEllipse(24, 22, 42, 11);
    graphics.fillStyle(0xdce6df, 1).fillPoints([
      new Phaser.Geom.Point(4, 4),
      new Phaser.Geom.Point(43, 1),
      new Phaser.Geom.Point(47, 25),
      new Phaser.Geom.Point(8, 29)
    ]);
    graphics.lineStyle(3, 0x315f6b, 1).strokePoints([
      new Phaser.Geom.Point(4, 4),
      new Phaser.Geom.Point(43, 1),
      new Phaser.Geom.Point(47, 25),
      new Phaser.Geom.Point(8, 29),
      new Phaser.Geom.Point(4, 4)
    ]);
    graphics.lineStyle(2, 0x577a82, 0.86)
      .lineBetween(12, 10, 34, 8)
      .lineBetween(11, 16, 38, 14)
      .lineBetween(15, 22, 33, 20);
    graphics.generateTexture("qizhen-transition-wet-paper", 52, 34);
    graphics.destroy();
  }

  private handleWorldTap(worldX: number, worldY: number): void {
    if (this.cinematicActive) return;
    const targetX = Phaser.Math.Clamp(worldX, CORRIDOR_LEFT, CORRIDOR_RIGHT);
    const body = this.player.body as Phaser.Physics.Arcade.Body | null;
    const footOffsetY = body ? body.center.y - this.player.y : 0;
    const path = this.pathGrid.findPath(
      { x: this.player.x, y: this.player.y + footOffsetY },
      { x: targetX, y: worldY }
    );
    if (!path?.length) return;
    this.movement.setPath(path.map((point) => ({ x: point.x, y: point.y - footOffsetY })));
    this.showPathIndicators(path);
  }

  private showPathIndicators(path: CampusPathPoint[]): void {
    this.clearPathIndicators();
    path.slice(1).forEach((point, index, points) => {
      const marker = this.add.circle(point.x, point.y, index === points.length - 1 ? 14 : PATH_DOT_RADIUS, 0x1c8297, 0.2)
        .setStrokeStyle(index === points.length - 1 ? 4 : 2, 0xa5e6d5, 0.9)
        .setDepth(point.y + 3);
      this.pathIndicators.push(marker);
    });
  }

  private clearPathIndicators(): void {
    this.pathIndicators.forEach((marker) => marker.destroy());
    this.pathIndicators = [];
  }

  private syncCharacterNameplate(state: GameState): void {
    const readable = selectIdentityReadable(state);
    this.characterName
      .setText(readable && state.actOne.characterNamed ? actOneContent.studentName : "")
      .setVisible(readable && state.actOne.characterNamed)
      .setPosition(this.player.x, this.player.y - this.playerPerspective.nameOffsetY)
      .setDepth(this.player.y + 72);
  }

  private publishDebugState(): void {
    const camera = this.cameras.main;
    setRpgRuntimeDebugState({
      coordinateSystem: "Phaser world coordinates, origin at top-left, x right, y down",
      world: QIZHEN_LOOP_RUNTIME.world,
      player: {
        x: Math.round(this.player.x),
        y: Math.round(this.player.y),
        facing: this.playerAnimator.facing,
        texture: this.playerAnimator.textureKey,
        turning: this.playerAnimator.isTurning,
        walkFps: RPG_PLAYER_WALK_FPS,
        normalizedDepth: Number(this.playerPerspective.normalizedDepth.toFixed(3)),
        perspectiveMultiplier: Number(this.playerPerspective.perspectiveMultiplier.toFixed(3)),
        displayScale: Number(this.playerPerspective.displayScale.toFixed(3)),
        displayWidth: Math.round(this.playerPerspective.displayWidth),
        displayHeight: Math.round(this.playerPerspective.displayHeight)
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
      qizhenApproach: {
        active: this.cinematicActive,
        briefingSeen: this.bridge.getState().qizhenLake.locationBriefingSeen,
        stop: QIZHEN_LOOP_RUNTIME.qizhen.approachTransition.stop
      },
      scene: "campus_qizhen_loop",
      checkpoint: this.bridge.getState().rpgCheckpoint
    });
  }

  private addObstacle(x: number, y: number, width: number, height: number): void {
    const collision = this.add.rectangle(x, y, width, height, 0x000000, 0).setDepth(y - 10);
    this.obstacles.add(collision);
  }

  private enableNativeResolution(): number {
    const bounds = this.game.canvas.getBoundingClientRect();
    this.game.canvas.style.imageRendering = "auto";
    const deviceScale = Math.max(1, window.devicePixelRatio || 1);
    const displayScale = Math.min(bounds.width / RPG_LOGICAL_WIDTH, bounds.height / RPG_LOGICAL_HEIGHT);
    const renderScale = Phaser.Math.Clamp(Math.max(1, displayScale * deviceScale), 1, MAX_RENDER_SCALE);
    this.scale.setGameSize(Math.round(RPG_LOGICAL_WIDTH * renderScale), Math.round(RPG_LOGICAL_HEIGHT * renderScale));
    return renderScale;
  }

  private restoreLogicalResolution(): void {
    this.transitionTrail.forEach((drop) => drop.destroy());
    this.transitionPaper?.destroy();
    this.scale.setGameSize(RPG_LOGICAL_WIDTH, RPG_LOGICAL_HEIGHT);
    this.game.canvas.style.imageRendering = "";
    this.renderScale = 1;
  }
}
