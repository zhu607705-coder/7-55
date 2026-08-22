import Phaser from "phaser";
import type { RpgBridge } from "./RpgBridge";
import { FINALE_ENVIRONMENTS } from "./FinaleEnvironmentTextures";
import { clearRpgRuntimeDebugState, setRpgRuntimeDebugState } from "./RpgRuntimeDebug";
import { subscribeRpgSceneBridge } from "./RpgSceneBridgeSubscription";

const ASSET = FINALE_ENVIRONMENTS.finale_stairwell;
const STAIR_BACKGROUND_KEY = "chapter4-stairwell-background";
const WORLD = ASSET.sourceSize;
const CAMERA_ZOOM = 960 / WORLD.width;
const PIVOT = { x: 836, y: 470 } as const;
const UPPER_ENDPOINT = { x: 836, y: 292 } as const;
const LOWER_ENDPOINT = { x: 836, y: 648 } as const;

export class ChapterFourStairAlignmentScene extends Phaser.Scene {
  private bridge!: RpgBridge;
  private player!: Phaser.GameObjects.Sprite;
  private shade!: Phaser.GameObjects.Rectangle;
  private echoLayer!: Phaser.GameObjects.Graphics;
  private turntable!: Phaser.GameObjects.Container;
  private routeGlow!: Phaser.GameObjects.Graphics;
  private instruction!: Phaser.GameObjects.Text;
  private cursors!: Phaser.Types.Input.Keyboard.CursorKeys;
  private keys!: Record<"A" | "D", Phaser.Input.Keyboard.Key>;
  private rotationInputReady = true;
  private interactRequested = false;
  private animationLocked = false;

  constructor() {
    super("chapter-four-stair-alignment");
  }

  preload(): void {
    if (!this.textures.exists(STAIR_BACKGROUND_KEY)) {
      this.load.image(STAIR_BACKGROUND_KEY, ASSET.url);
    }
  }

  create(): void {
    this.bridge = this.registry.get("rpgBridge") as RpgBridge;
    this.cameras.main.setBackgroundColor(0x02050a);
    this.add.image(0, 0, STAIR_BACKGROUND_KEY).setOrigin(0).setDepth(0);
    this.textures.get(STAIR_BACKGROUND_KEY).setFilter(Phaser.Textures.FilterMode.NEAREST);

    this.createRealityLayers();
    this.createAlignmentBoard();
    const completed = this.bridge.getState().chapter4.stairAlignmentSolved;
    const playerTexture = this.resolvePlayerTexture(completed ? "down" : "up");
    this.player = this.add.sprite(
      completed ? LOWER_ENDPOINT.x : UPPER_ENDPOINT.x,
      completed ? LOWER_ENDPOINT.y + 36 : UPPER_ENDPOINT.y - 34,
      playerTexture
    );
    this.player.setDisplaySize(58, 77).setOrigin(0.5, 0.84).setDepth(6400);

    this.instruction = this.add.text(480, 465, "", {
      color: "#f9f3d4",
      backgroundColor: "#081625ee",
      fontFamily: "monospace",
      fontSize: "15px",
      padding: { x: 14, y: 9 },
      align: "center"
    }).setOrigin(0.5).setScrollFactor(0).setDepth(9000);

    this.cursors = this.input.keyboard!.createCursorKeys();
    this.keys = this.input.keyboard!.addKeys("A,D") as Record<"A" | "D", Phaser.Input.Keyboard.Key>;
    this.input.keyboard!.addCapture([
      Phaser.Input.Keyboard.KeyCodes.SPACE,
      Phaser.Input.Keyboard.KeyCodes.LEFT,
      Phaser.Input.Keyboard.KeyCodes.RIGHT
    ]);
    this.cameras.main.setBounds(0, 0, WORLD.width, WORLD.height).setZoom(CAMERA_ZOOM).centerOn(WORLD.width / 2, WORLD.height / 2);

    subscribeRpgSceneBridge(
      this.events,
      this.bridge,
      (event) => this.handleBridgeEvent(event.name, event.payload),
      clearRpgRuntimeDebugState
    );
    this.bridge.setRpgLocation(
      "duan_yongping_temporal_maze",
      completed ? "c4_b2_activity" : "c4_b3_landing"
    );
    this.bridge.emit("rpg_booted", { scene: "duan_yongping_temporal_maze" });
    if (!completed) {
      this.bridge.emit("rpg_subtitle", {
        text: "楼梯的空间关系发生错位。",
        tone: "narrator",
        durationMs: 2600
      });
    }
    this.syncVisuals(true);
    this.publishDebug();
  }

  update(): void {
    const leftDown = this.cursors.left.isDown || this.keys.A.isDown;
    const rightDown = this.cursors.right.isDown || this.keys.D.isDown;
    if (!leftDown && !rightDown) this.rotationInputReady = true;
    if (!this.animationLocked && this.rotationInputReady && leftDown !== rightDown) {
      this.rotationInputReady = false;
      this.requestRotation(leftDown ? "left" : "right");
    }
    if (Phaser.Input.Keyboard.JustDown(this.cursors.space)) this.interactRequested = true;
    if (this.interactRequested && !this.animationLocked) this.requestInteraction();
    this.interactRequested = false;
    this.syncVisuals(false);
    this.publishDebug();
  }

  private createRealityLayers(): void {
    this.shade = this.add.rectangle(WORLD.width / 2, WORLD.height / 2, WORLD.width, WORLD.height, 0x071525, 0)
      .setDepth(3000);
    this.echoLayer = this.add.graphics().setDepth(3600);
    const echoes = [
      { x: 568, y: 310, radius: 58, alpha: 0.18 },
      { x: 1108, y: 454, radius: 76, alpha: 0.25 },
      { x: LOWER_ENDPOINT.x, y: LOWER_ENDPOINT.y, radius: 112, alpha: 0.52 }
    ];
    for (const echo of echoes) {
      this.echoLayer.lineStyle(8, 0x67dbff, echo.alpha).strokeCircle(echo.x, echo.y, echo.radius);
      this.echoLayer.lineStyle(4, 0xb9f4ff, echo.alpha * 0.7).strokeCircle(echo.x, echo.y, echo.radius + 24);
    }
  }

  private createAlignmentBoard(): void {
    this.routeGlow = this.add.graphics().setDepth(4800);
    this.routeGlow.lineStyle(16, 0x43e0ff, 0.42);
    this.routeGlow.beginPath();
    this.routeGlow.moveTo(UPPER_ENDPOINT.x, UPPER_ENDPOINT.y);
    this.routeGlow.lineTo(PIVOT.x, PIVOT.y);
    this.routeGlow.lineTo(LOWER_ENDPOINT.x, LOWER_ENDPOINT.y);
    this.routeGlow.strokePath();

    const base = this.add.graphics();
    base.fillStyle(0x101b28, 0.97).fillCircle(0, 0, 118);
    base.lineStyle(10, 0xd2b65c, 0.88).strokeCircle(0, 0, 118);
    base.lineStyle(5, 0x64899d, 0.8).strokeCircle(0, 0, 90);

    const bridge = this.add.graphics();
    bridge.fillStyle(0x46515c, 1).fillRoundedRect(-168, -50, 336, 100, 18);
    bridge.lineStyle(10, 0xd8d9ce, 0.95).strokeRoundedRect(-168, -50, 336, 100, 18);
    bridge.lineStyle(4, 0x202b35, 0.9);
    for (let x = -132; x <= 132; x += 33) bridge.lineBetween(x, -42, x, 42);
    bridge.lineStyle(7, 0x6de6ff, 0.72).lineBetween(-152, 0, 152, 0);

    const crank = this.add.graphics();
    crank.fillStyle(0xd2b65c, 1).fillCircle(0, 0, 18);
    crank.lineStyle(7, 0x1b2732, 1).strokeCircle(0, 0, 18);
    crank.lineStyle(8, 0xd2b65c, 1).lineBetween(0, 0, 50, -42);
    crank.fillStyle(0xe9dfae, 1).fillCircle(52, -44, 13);

    this.turntable = this.add.container(PIVOT.x, PIVOT.y, [base, bridge, crank]).setDepth(5200);
  }

  private handleBridgeEvent(name: string, payload?: Record<string, unknown>): void {
    if (name === "rpg_interact") {
      this.interactRequested = true;
      return;
    }
    if (name !== "rpg_direction_changed" || this.animationLocked || !this.rotationInputReady) return;
    const x = Number(payload?.x) || 0;
    if (Math.abs(x) < 0.5) {
      this.rotationInputReady = true;
      return;
    }
    this.rotationInputReady = false;
    this.requestRotation(x < 0 ? "left" : "right");
  }

  private requestRotation(direction: "left" | "right"): void {
    const state = this.bridge.getState().chapter4;
    if (state.mode !== "light" || !state.stairEchoObserved || state.stairAlignmentSolved) return;
    this.animationLocked = true;
    this.bridge.emit("rpg_chapter4_action_requested", { action: "rotate_stair", direction });
    const targetQuarterTurns = (state.stairRotationQuarterTurns + (direction === "left" ? -1 : 1) + 4) % 4;
    this.tweens.add({
      targets: this.turntable,
      angle: targetQuarterTurns * 90,
      duration: 520,
      ease: "Cubic.InOut",
      onComplete: () => { this.animationLocked = false; }
    });
  }

  private requestInteraction(): void {
    const state = this.bridge.getState().chapter4;
    if (!state.stairEchoObserved) {
      this.bridge.emit("rpg_chapter4_action_requested", { action: "observe_stair_echo" });
      return;
    }
    if (state.stairRotationQuarterTurns !== 1) {
      this.bridge.emit("rpg_chapter4_action_requested", { action: "traverse_stair" });
      return;
    }
    this.animationLocked = true;
    this.tweens.add({
      targets: this.player,
      x: LOWER_ENDPOINT.x,
      y: LOWER_ENDPOINT.y + 36,
      duration: 1250,
      ease: "Sine.InOut",
      onComplete: () => {
        if (this.textures.exists("act1-player-down-0")) this.player.setTexture("act1-player-down-0");
        this.bridge.emit("rpg_chapter4_action_requested", { action: "traverse_stair" });
        this.animationLocked = false;
      }
    });
  }

  private syncVisuals(force: boolean): void {
    const state = this.bridge.getState().chapter4;
    this.shade.setAlpha(state.mode === "dark" ? 0.38 : 0);
    this.echoLayer.setVisible(state.mode === "dark" || state.stairEchoObserved);
    this.echoLayer.setAlpha(state.mode === "dark" ? 1 : 0.25);
    this.routeGlow.setVisible(state.stairEchoObserved && state.stairRotationQuarterTurns === 1);
    if (force || !this.animationLocked) this.turntable.setAngle(state.stairRotationQuarterTurns * 90);

    const instruction = state.stairAlignmentSolved
      ? "B2 已接通"
      : !state.stairEchoObserved
        ? state.mode === "dark" ? "空格键  记录下层回声" : "切到深色观察后确认下层方向"
        : state.mode === "dark"
          ? "已确认下层方向 · 切回浅色操作"
          : state.stairRotationQuarterTurns === 1
            ? "端点已对齐 · 空格键通过"
            : "A / ← 左转 · D / → 右转 · 让两端发光后通过";
    this.instruction.setText(instruction);
  }

  private resolvePlayerTexture(facing: "up" | "down"): string {
    const sharedKey = `act1-player-${facing}-0`;
    if (this.textures.exists(sharedKey)) return sharedKey;
    const localKey = `chapter4-stair-player-${facing}`;
    if (this.textures.exists(localKey)) return localKey;
    const graphics = this.make.graphics({ x: 0, y: 0 });
    graphics.fillStyle(0x172028, 0.45).fillEllipse(24, 58, 38, 10);
    graphics.fillStyle(0x24313e, 1).fillRect(12, 39, 10, 18).fillRect(28, 39, 10, 18);
    graphics.fillStyle(facing === "up" ? 0x244b7d : 0x315f9f, 1).fillRoundedRect(8, 18, 34, 27, 5);
    graphics.fillStyle(0xe0b36f, 1).fillCircle(25, 13, 12);
    graphics.fillStyle(0x2a2220, 1).fillRect(12, 3, 26, 10).fillRect(10, 8, 7, 14);
    graphics.generateTexture(localKey, 50, 64);
    graphics.destroy();
    return localKey;
  }

  private publishDebug(): void {
    const state = this.bridge.getState().chapter4;
    setRpgRuntimeDebugState({
      engine: "phaser",
      coordinateSystem: "Phaser world coordinates, origin at top-left, x right, y down",
      world: { ...WORLD },
      player: { x: this.player.x, y: this.player.y, facing: "down" },
      input: {
        gameEnabled: this.game.input.enabled,
        sceneEnabled: this.input.enabled,
        keyboardEnabled: this.input.keyboard?.enabled ?? false,
        keys: {
          up: false,
          down: false,
          left: this.cursors?.left.isDown ?? false,
          right: this.cursors?.right.isDown ?? false,
          interact: this.cursors?.space.isDown ?? false
        }
      },
      camera: { scrollX: this.cameras.main.scrollX, scrollY: this.cameras.main.scrollY, zoom: this.cameras.main.zoom, mode: "manual" },
      scene: "duan_yongping_temporal_maze",
      checkpoint: this.bridge.getState().rpgCheckpoint,
      activeTargets: [{
        id: "b_stair_temporal_turntable",
        label: "错位折返楼梯",
        x: PIVOT.x,
        y: PIVOT.y,
        width: 336,
        height: 236,
        requiredMode: state.stairEchoObserved ? "light" : "dark"
      }],
      chapterFour: {
        phase: state.phase,
        mode: state.mode,
        stairAlignment: {
          echoObserved: state.stairEchoObserved,
          rotationQuarterTurns: state.stairRotationQuarterTurns,
          solved: state.stairAlignmentSolved
        }
      }
    });
  }
}
