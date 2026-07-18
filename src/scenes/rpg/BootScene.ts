import Phaser from "phaser";
import actOneContent from "../../data/act-one-bootstrap.content.json";
import type { RpgBridge } from "./RpgBridge";
import { clearRpgRuntimeDebugState, setRpgRuntimeDebugState } from "./RpgRuntimeDebug";
import { preloadZijingangWorldAssets } from "./ZijingangLandmarkAssets";
import { drawZijingangWorld, ZIJINGANG_WORLD } from "./ZijingangWorld";
import { CAMPUS_LIBRARY_GATE } from "./LibraryInteriorModel";
import {
  configureRpgPlayerSprite,
  ensureRpgPlayerTextures,
  preloadRpgPlayerTextures,
  RPG_PLAYER_NAME_OFFSET_Y,
  type RpgPlayerFacing
} from "./RpgPlayerTextures";
import { RPG_CONTROL_HINTS } from "./RpgControlHints";
import { subscribeRpgSceneBridge } from "./RpgSceneBridgeSubscription";

const CAMERA_MIN_ZOOM = 0.25;
const CAMERA_MAX_ZOOM = 0.75;
const CAMERA_DEFAULT_ZOOM = 0.375;
const CAMERA_ZOOM_STEP = 0.0625;

export class BootScene extends Phaser.Scene {
  private bridge!: RpgBridge;
  private player!: Phaser.Physics.Arcade.Sprite;
  private playerMarker!: Phaser.GameObjects.Arc;
  private contextualLandmarkLabels: Phaser.GameObjects.Text[] = [];
  private obstacles!: Phaser.Physics.Arcade.StaticGroup;
  private cursors!: Phaser.Types.Input.Keyboard.CursorKeys;
  private keys!: Record<"W" | "A" | "S" | "D" | "SHIFT", Phaser.Input.Keyboard.Key>;
  private virtualDirection = { x: 0, y: 0 };
  private lockedHintShown = false;
  private walkingFrame = 0;
  private facing: RpgPlayerFacing = "down";
  private characterName!: Phaser.GameObjects.Text;
  private libraryGateMarker!: Phaser.GameObjects.Arc;
  private libraryGatePrompt!: Phaser.GameObjects.Text;
  private interactRequested = false;
  private cameraDragging = false;
  private manualCamera = false;
  private dragOrigin = { pointerX: 0, pointerY: 0, scrollX: 0, scrollY: 0 };

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

    ensureRpgPlayerTextures(this);
    this.player = this.physics.add.sprite(ZIJINGANG_WORLD.spawn.x, ZIJINGANG_WORLD.spawn.y, "act1-player-down-0");
    this.player.setCollideWorldBounds(true).setDepth(this.player.y + 30);
    configureRpgPlayerSprite(this.player);
    this.physics.add.collider(this.player, this.obstacles);
    this.characterName = this.add.text(this.player.x, this.player.y - RPG_PLAYER_NAME_OFFSET_Y, actOneContent.studentName, {
      color: "#fff7df",
      backgroundColor: "#17212add",
      fontFamily: "monospace",
      fontSize: "11px",
      padding: { x: 4, y: 2 }
    }).setOrigin(0.5).setDepth(this.player.y + 55);

    this.cursors = this.input.keyboard!.createCursorKeys();
    this.keys = this.input.keyboard!.addKeys("W,A,S,D,SHIFT") as Record<"W" | "A" | "S" | "D" | "SHIFT", Phaser.Input.Keyboard.Key>;

    this.setupCamera();
    this.setupCameraInput();
    this.createLibraryGate();

    subscribeRpgSceneBridge(this.events, this.bridge, (event) => {
      if (event.name === "rpg_direction_changed") {
        this.virtualDirection = {
          x: Number(event.payload?.x) || 0,
          y: Number(event.payload?.y) || 0
        };
      } else if (event.name === "rpg_camera_recenter") {
        this.resumeCameraFollow(true);
      } else if (event.name === "rpg_camera_zoom") {
        this.changeCameraZoom(Number(event.payload?.delta) || 0);
      } else if (event.name === "rpg_interact") {
        this.interactRequested = true;
      }
    }, clearRpgRuntimeDebugState);
    this.bridge.emit("rpg_booted", { scene: "campus_bootstrap" });
  }

  update(): void {
    const state = this.bridge.getState();
    const keyboardX = Number(this.cursors.right.isDown || this.keys.D.isDown) - Number(this.cursors.left.isDown || this.keys.A.isDown);
    const keyboardY = Number(this.cursors.down.isDown || this.keys.S.isDown) - Number(this.cursors.up.isDown || this.keys.W.isDown);
    const x = Math.max(-1, Math.min(1, keyboardX + this.virtualDirection.x));
    const y = Math.max(-1, Math.min(1, keyboardY + this.virtualDirection.y));

    this.playerMarker.setPosition(this.player.x, this.player.y);
    this.updateContextualLandmarkLabel();
    this.updateLibraryGate();
    this.publishDebugState();

    if (!state.actOne.movementEnabled) {
      this.player.setVelocity(0);
      if ((x !== 0 || y !== 0) && !this.lockedHintShown) {
        this.lockedHintShown = true;
        this.bridge.emit("toast", { text: actOneContent.narration.locked, tone: "xiaoying" });
      }
      return;
    }

    const vector = new Phaser.Math.Vector2(x, y);
    if (vector.lengthSq() > 0) {
      const speed = this.keys.SHIFT.isDown ? 320 : 220;
      vector.normalize().scale(speed);
      if (this.cameraDragging && !this.input.activePointer.isDown) {
        this.finishCameraDrag();
      }
      if (this.manualCamera && !this.cameraDragging) {
        this.resumeCameraFollow(false);
      }
    }
    this.player.setVelocity(vector.x, vector.y);
    this.updatePlayerAnimation(vector);
    this.player.setDepth(this.player.y + 30);
    this.characterName.setPosition(this.player.x, this.player.y - RPG_PLAYER_NAME_OFFSET_Y).setDepth(this.player.y + 72);
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
    this.cameras.getCamera("campus-minimap")?.ignore([this.libraryGateMarker, this.libraryGatePrompt]);

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
    const available = state.actOne.canLeaveDorm && state.ui.libraryFinalsPhase !== "friend_contacted";
    const distance = Phaser.Math.Distance.Between(
      this.player.x,
      this.player.y,
      CAMPUS_LIBRARY_GATE.x,
      CAMPUS_LIBRARY_GATE.y
    );
    const nearby = available && distance <= CAMPUS_LIBRARY_GATE.radius;
    this.libraryGateMarker.setVisible(available);
    this.libraryGatePrompt.setVisible(nearby);

    const keyboardInteract = Phaser.Input.Keyboard.JustDown(this.cursors.space);
    if (nearby && (keyboardInteract || this.interactRequested)) {
      this.bridge.setCheckpoint("campus_library_gate");
      this.bridge.emit("rpg_library_gate_requested", { landmark: "foundation_library" });
    }
    this.interactRequested = false;
  }

  private setupCamera(): void {
    const camera = this.cameras.main;
    camera
      .setBounds(0, 0, ZIJINGANG_WORLD.width, ZIJINGANG_WORLD.height)
      .setZoom(CAMERA_DEFAULT_ZOOM)
      .startFollow(this.player, true, 0.1, 0.1, 0, 34)
      .setDeadzone(300, 180);
    camera.centerOn(this.player.x, this.player.y);

    const minimapSize = 128;
    const minimap = this.cameras.add(16, 392, minimapSize, minimapSize, false, "campus-minimap");
    minimap
      .setBounds(0, 0, ZIJINGANG_WORLD.width, ZIJINGANG_WORLD.height)
      .setZoom(minimapSize / ZIJINGANG_WORLD.width)
      .setBackgroundColor(0x10171c)
      .centerOn(ZIJINGANG_WORLD.width / 2, ZIJINGANG_WORLD.height / 2);
    minimap.ignore(this.contextualLandmarkLabels);

    this.playerMarker = this.add.circle(this.player.x, this.player.y, 22, 0xf0d54e, 0.94)
      .setStrokeStyle(8, 0xffffff, 0.95)
      .setDepth(20000);
    camera.ignore(this.playerMarker);
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

  private setupCameraInput(): void {
    const camera = this.cameras.main;
    this.input.mouse?.disableContextMenu();

    this.input.on("pointerdown", (pointer: Phaser.Input.Pointer) => {
      if (!pointer.leftButtonDown()) {
        return;
      }
      this.cameraDragging = true;
      this.manualCamera = true;
      camera.stopFollow();
      this.dragOrigin = {
        pointerX: pointer.x,
        pointerY: pointer.y,
        scrollX: camera.scrollX,
        scrollY: camera.scrollY
      };
      this.game.canvas.style.cursor = "grabbing";
    });

    this.input.on("pointermove", (pointer: Phaser.Input.Pointer) => {
      if (!this.cameraDragging || !pointer.isDown) {
        return;
      }
      camera.setScroll(
        this.dragOrigin.scrollX - (pointer.x - this.dragOrigin.pointerX) / camera.zoom,
        this.dragOrigin.scrollY - (pointer.y - this.dragOrigin.pointerY) / camera.zoom
      );
    });

    const finishDrag = () => this.finishCameraDrag();
    this.input.on("pointerup", finishDrag);
    this.input.on("pointerupoutside", finishDrag);
    window.addEventListener("pointerup", finishDrag, true);
    window.addEventListener("pointercancel", finishDrag, true);
    window.addEventListener("blur", finishDrag);

    let cleanedUp = false;
    const cleanupWindowDragListeners = () => {
      if (cleanedUp) return;
      cleanedUp = true;
      window.removeEventListener("pointerup", finishDrag, true);
      window.removeEventListener("pointercancel", finishDrag, true);
      window.removeEventListener("blur", finishDrag);
    };
    this.events.once("shutdown", cleanupWindowDragListeners);
    this.events.once("destroy", cleanupWindowDragListeners);

    this.input.on(
      "wheel",
      (pointer: Phaser.Input.Pointer, _objects: Phaser.GameObjects.GameObject[], _deltaX: number, deltaY: number) => {
        const before = camera.getWorldPoint(pointer.x, pointer.y);
        const rawZoom = camera.zoom - deltaY * 0.00075;
        const nextZoom = Phaser.Math.Clamp(
          Math.round(rawZoom / CAMERA_ZOOM_STEP) * CAMERA_ZOOM_STEP,
          CAMERA_MIN_ZOOM,
          CAMERA_MAX_ZOOM
        );
        if (nextZoom === camera.zoom) {
          return;
        }
        this.manualCamera = true;
        camera.stopFollow();
        camera.setZoom(nextZoom);
        const after = camera.getWorldPoint(pointer.x, pointer.y);
        camera.scrollX += before.x - after.x;
        camera.scrollY += before.y - after.y;
      }
    );

    this.game.canvas.style.cursor = "grab";
  }

  private finishCameraDrag(): void {
    this.cameraDragging = false;
    this.game.canvas.style.cursor = "grab";
  }

  private resumeCameraFollow(immediate: boolean): void {
    this.manualCamera = false;
    const camera = this.cameras.main;
    camera.startFollow(this.player, true, 0.1, 0.1, 0, 34).setDeadzone(300, 180);
    if (immediate) {
      camera.centerOn(this.player.x, this.player.y + 34);
    }
  }

  private publishDebugState(): void {
    const camera = this.cameras.main;
    setRpgRuntimeDebugState({
      coordinateSystem: "Phaser world coordinates, origin at top-left, x right, y down",
      world: { width: ZIJINGANG_WORLD.width, height: ZIJINGANG_WORLD.height },
      player: { x: Math.round(this.player.x), y: Math.round(this.player.y), facing: this.facing },
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
        mode: this.manualCamera ? "manual" : "follow"
      }
    });
  }

  private changeCameraZoom(delta: number): void {
    const camera = this.cameras.main;
    const direction = Math.sign(delta);
    const nextZoom = Phaser.Math.Clamp(camera.zoom + direction * CAMERA_ZOOM_STEP, CAMERA_MIN_ZOOM, CAMERA_MAX_ZOOM);
    if (nextZoom === camera.zoom) {
      return;
    }
    camera.setZoom(nextZoom);
    this.resumeCameraFollow(true);
  }

  private updatePlayerAnimation(vector: Phaser.Math.Vector2): void {
    if (vector.lengthSq() > 0) {
      if (Math.abs(vector.x) > Math.abs(vector.y)) {
        this.facing = "side";
        this.player.setFlipX(vector.x < 0);
      } else {
        this.facing = vector.y < 0 ? "up" : "down";
        this.player.setFlipX(false);
      }
      const nextFrame = Math.floor(this.time.now / 120) % 2;
      if (nextFrame !== this.walkingFrame || this.player.texture.key !== `act1-player-${this.facing}-${nextFrame}`) {
        this.walkingFrame = nextFrame;
        this.player.setTexture(`act1-player-${this.facing}-${nextFrame}`);
      }
      return;
    }

    if (this.walkingFrame !== 0 || this.player.texture.key !== `act1-player-${this.facing}-0`) {
      this.walkingFrame = 0;
      this.player.setTexture(`act1-player-${this.facing}-0`);
    }
  }

  private addObstacle(x: number, y: number, width: number, height: number): void {
    const collision = this.add.rectangle(x, y, width, height, 0x000000, 0).setDepth(y - 10);
    this.obstacles.add(collision);
  }

}
