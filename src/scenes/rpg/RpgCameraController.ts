import Phaser from "phaser";

export interface RpgCameraOptions {
  player: Phaser.GameObjects.Sprite;
  world: { width: number; height: number };
  minZoom?: number;
  maxZoom?: number;
  defaultZoom?: number;
  zoomStep?: number;
  deadzone?: { width: number; height: number };
  followOffsetY?: number;
  minimap?: { x: number; y: number; width: number; height: number; name: string } | null;
}

const DEFAULT_MIN_ZOOM = 0.25;
const DEFAULT_MAX_ZOOM = 0.75;
const DEFAULT_ZOOM = 0.375;
const DEFAULT_ZOOM_STEP = 0.0625;
const DEFAULT_DEADZONE = { width: 300, height: 180 };
const DEFAULT_FOLLOW_OFFSET_Y = 34;
const DEFAULT_MINIMAP = { x: 16, y: 504, width: 220, height: 20, name: "campus-minimap" };

const DRAG_THRESHOLD_PX = 8;
const TAP_MAX_DURATION_MS = 400;
const INERTIA_DECAY_PER_FRAME = 0.92;
const INERTIA_STOP_SPEED = 0.02; // world px per ms
const INERTIA_MAX_SPEED = 8; // world px per ms
const INERTIA_SAMPLE_WINDOW_MS = 120;
const ZOOM_TWEEN_MS = 120;
const WHEEL_ZOOM_SENSITIVITY = 0.00075;
const MINIMAP_BACKGROUND = 0x10171c;
const VIEWPORT_FRAME_COLOR = 0xf0d54e;
const VIEWPORT_FRAME_STROKE = 48; // world units, ~1.2px at minimap zoom

interface PointerSample {
  t: number;
  x: number;
  y: number;
}

interface ZoomTween {
  from: number;
  to: number;
  elapsed: number;
  anchor: { screenX: number; screenY: number; worldX: number; worldY: number } | null;
}

type Gesture = "none" | "pending" | "dragging" | "minimap";

/** Campus map camera: follow, drag pan with inertia, eased zoom, minimap nav. */
export class RpgCameraController {
  onWorldTap?: (worldX: number, worldY: number) => void;

  private readonly scene: Phaser.Scene;
  private readonly player: Phaser.GameObjects.Sprite;
  private readonly world: { width: number; height: number };
  private readonly minZoom: number;
  private readonly maxZoom: number;
  private readonly defaultZoom: number;
  private readonly zoomStep: number;
  private readonly deadzone: { width: number; height: number };
  private readonly followOffsetY: number;
  private readonly minimapOptions: { x: number; y: number; width: number; height: number; name: string } | null;

  private camera!: Phaser.Cameras.Scene2D.Camera;
  private minimap: Phaser.Cameras.Scene2D.Camera | null = null;
  private viewportFrame: Phaser.GameObjects.Rectangle | null = null;

  private manual = false;
  private gesture: Gesture = "none";
  private attached = false;
  private destroyed = false;
  private downTime = 0;
  private downX = 0;
  private downY = 0;
  private dragOrigin = { pointerX: 0, pointerY: 0, scrollX: 0, scrollY: 0 };
  private samples: PointerSample[] = [];
  private inertiaX = 0;
  private inertiaY = 0;
  private zoomTween: ZoomTween | null = null;

  constructor(scene: Phaser.Scene, options: RpgCameraOptions) {
    this.scene = scene;
    this.player = options.player;
    this.world = options.world;
    this.minZoom = options.minZoom ?? DEFAULT_MIN_ZOOM;
    this.maxZoom = options.maxZoom ?? DEFAULT_MAX_ZOOM;
    this.defaultZoom = options.defaultZoom ?? DEFAULT_ZOOM;
    this.zoomStep = options.zoomStep ?? DEFAULT_ZOOM_STEP;
    this.deadzone = options.deadzone ?? DEFAULT_DEADZONE;
    this.followOffsetY = options.followOffsetY ?? DEFAULT_FOLLOW_OFFSET_Y;
    this.minimapOptions = options.minimap === null ? null : (options.minimap ?? DEFAULT_MINIMAP);
  }

  get manualMode(): boolean {
    return this.manual;
  }

  get minimapCamera(): Phaser.Cameras.Scene2D.Camera | null {
    return this.minimap;
  }

  attach(): void {
    if (this.attached || this.destroyed) {
      return;
    }
    this.attached = true;

    const camera = this.scene.cameras.main;
    this.camera = camera;
    camera
      .setBounds(0, 0, this.world.width, this.world.height)
      .setZoom(this.defaultZoom)
      .startFollow(this.player, true, 0.1, 0.1, 0, this.followOffsetY)
      .setDeadzone(this.deadzone.width, this.deadzone.height);
    camera.centerOn(this.player.x, this.player.y);

    if (this.minimapOptions) {
      const { x, y, width, height, name } = this.minimapOptions;
      const minimap = this.scene.cameras.add(x, y, width, height, false, name);
      minimap
        .setBounds(0, 0, this.world.width, this.world.height)
        .setZoom(Math.min(width / this.world.width, height / this.world.height))
        .setBackgroundColor(MINIMAP_BACKGROUND)
        .centerOn(this.world.width / 2, this.world.height / 2);
      this.minimap = minimap;

      this.viewportFrame = this.scene.add
        .rectangle(0, 0, 1, 1, VIEWPORT_FRAME_COLOR, 0)
        .setStrokeStyle(VIEWPORT_FRAME_STROKE, VIEWPORT_FRAME_COLOR, 0.85)
        .setDepth(20000);
      camera.ignore(this.viewportFrame);
      this.syncMinimapViewport();
    }

    this.scene.input.mouse?.disableContextMenu();
    this.scene.input.on("pointerdown", this.handlePointerDown);
    this.scene.input.on("pointermove", this.handlePointerMove);
    this.scene.input.on("pointerup", this.handlePointerUp);
    this.scene.input.on("pointerupoutside", this.handlePointerUpOutside);
    this.scene.input.on("wheel", this.handleWheel);
    window.addEventListener("pointerup", this.handleWindowRelease, true);
    window.addEventListener("pointercancel", this.handleWindowRelease, true);
    window.addEventListener("blur", this.handleWindowRelease);
    this.scene.events.once("shutdown", this.handleSceneLifecycle);
    this.scene.events.once("destroy", this.handleSceneLifecycle);
    this.scene.game.canvas.style.cursor = "grab";
  }

  recenter(immediate = false): void {
    if (this.destroyed || !this.attached) {
      return;
    }
    this.resumeFollow(immediate);
  }

  zoomBy(direction: number): void {
    if (this.destroyed || !this.attached) {
      return;
    }
    const step = Math.sign(direction);
    if (step === 0) {
      return;
    }
    const baseZoom = this.zoomTween ? this.zoomTween.to : this.camera.zoom;
    const nextZoom = Phaser.Math.Clamp(baseZoom + step * this.zoomStep, this.minZoom, this.maxZoom);
    if (nextZoom === baseZoom) {
      return;
    }
    this.resumeFollow(true);
    this.zoomTween = { from: this.camera.zoom, to: nextZoom, elapsed: 0, anchor: null };
  }

  update(deltaMs: number): void {
    if (this.destroyed || !this.attached) {
      return;
    }

    // Release happened outside every listener (e.g. pointer left the window).
    if ((this.gesture === "pending" || this.gesture === "dragging") && !this.scene.input.activePointer.isDown) {
      if (this.gesture === "dragging") {
        this.startInertia();
      }
      this.endGesture();
    }

    if (this.manual && this.gesture !== "dragging" && this.isPlayerMoving()) {
      this.resumeFollow(false);
    }

    if ((this.inertiaX !== 0 || this.inertiaY !== 0) && this.gesture !== "dragging") {
      this.camera.scrollX = this.camera.clampX(this.camera.scrollX + this.inertiaX * deltaMs);
      this.camera.scrollY = this.camera.clampY(this.camera.scrollY + this.inertiaY * deltaMs);
      const decay = Math.pow(INERTIA_DECAY_PER_FRAME, deltaMs / (1000 / 60));
      this.inertiaX *= decay;
      this.inertiaY *= decay;
      if (Math.hypot(this.inertiaX, this.inertiaY) < INERTIA_STOP_SPEED) {
        this.stopInertia();
      }
    }

    if (this.zoomTween) {
      const tween = this.zoomTween;
      tween.elapsed += deltaMs;
      const t = Phaser.Math.Clamp(tween.elapsed / ZOOM_TWEEN_MS, 0, 1);
      const eased = t * t * (3 - 2 * t);
      this.camera.setZoom(t >= 1 ? tween.to : tween.from + (tween.to - tween.from) * eased);
      if (tween.anchor) {
        const after = this.camera.getWorldPoint(tween.anchor.screenX, tween.anchor.screenY);
        this.camera.scrollX += tween.anchor.worldX - after.x;
        this.camera.scrollY += tween.anchor.worldY - after.y;
      }
      if (t >= 1) {
        this.zoomTween = null;
      }
    }

    this.syncMinimapViewport();
  }

  destroy(): void {
    if (this.destroyed) {
      return;
    }
    this.destroyed = true;

    this.scene.input.off("pointerdown", this.handlePointerDown);
    this.scene.input.off("pointermove", this.handlePointerMove);
    this.scene.input.off("pointerup", this.handlePointerUp);
    this.scene.input.off("pointerupoutside", this.handlePointerUpOutside);
    this.scene.input.off("wheel", this.handleWheel);
    window.removeEventListener("pointerup", this.handleWindowRelease, true);
    window.removeEventListener("pointercancel", this.handleWindowRelease, true);
    window.removeEventListener("blur", this.handleWindowRelease);
    this.scene.events.off("shutdown", this.handleSceneLifecycle);
    this.scene.events.off("destroy", this.handleSceneLifecycle);

    if (this.viewportFrame) {
      this.viewportFrame.destroy();
      this.viewportFrame = null;
    }
    if (this.minimap) {
      this.scene.cameras.remove(this.minimap);
      this.minimap = null;
    }
    this.zoomTween = null;
    this.samples = [];
    this.stopInertia();
    this.gesture = "none";
  }

  private handlePointerDown = (pointer: Phaser.Input.Pointer): void => {
    if (!pointer.leftButtonDown()) {
      return;
    }
    this.stopInertia();

    if (this.isOverMinimap(pointer.x, pointer.y)) {
      this.completeZoomTween();
      this.gesture = "minimap";
      this.manual = true;
      this.camera.stopFollow();
      const worldPoint = this.minimap!.getWorldPoint(pointer.x, pointer.y);
      this.camera.centerOn(worldPoint.x, worldPoint.y);
      return;
    }

    this.gesture = "pending";
    this.downTime = this.scene.time.now;
    this.downX = pointer.x;
    this.downY = pointer.y;
    this.samples = [];
  };

  private handlePointerMove = (pointer: Phaser.Input.Pointer): void => {
    if (this.gesture === "pending") {
      if (!pointer.isDown) {
        this.endGesture();
        return;
      }
      const dx = pointer.x - this.downX;
      const dy = pointer.y - this.downY;
      if (dx * dx + dy * dy < DRAG_THRESHOLD_PX * DRAG_THRESHOLD_PX) {
        return;
      }
      // Re-anchor at the threshold crossing so the pan starts without a jump.
      this.completeZoomTween();
      this.manual = true;
      this.camera.stopFollow();
      this.dragOrigin = {
        pointerX: pointer.x,
        pointerY: pointer.y,
        scrollX: this.camera.scrollX,
        scrollY: this.camera.scrollY
      };
      this.samples = [{ t: this.scene.time.now, x: pointer.x, y: pointer.y }];
      this.gesture = "dragging";
      this.scene.game.canvas.style.cursor = "grabbing";
    }

    if (this.gesture !== "dragging" || !pointer.isDown) {
      return;
    }
    this.camera.setScroll(
      this.dragOrigin.scrollX - (pointer.x - this.dragOrigin.pointerX) / this.camera.zoom,
      this.dragOrigin.scrollY - (pointer.y - this.dragOrigin.pointerY) / this.camera.zoom
    );
    this.samples.push({ t: this.scene.time.now, x: pointer.x, y: pointer.y });
    if (this.samples.length > 8) {
      this.samples.shift();
    }
  };

  private handlePointerUp = (pointer: Phaser.Input.Pointer): void => {
    if (this.gesture === "pending") {
      if (this.scene.time.now - this.downTime < TAP_MAX_DURATION_MS && this.onWorldTap) {
        const worldPoint = this.camera.getWorldPoint(pointer.x, pointer.y);
        this.onWorldTap(worldPoint.x, worldPoint.y);
      }
    } else if (this.gesture === "dragging") {
      this.startInertia();
    }
    this.endGesture();
  };

  private handlePointerUpOutside = (): void => {
    if (this.gesture === "dragging") {
      this.startInertia();
    }
    this.endGesture();
  };

  // Wheel zoom keeps the BootScene contract: discrete zoomStep levels, pointer-anchored,
  // switches to manual mode until the player moves. The step runs through the eased tween.
  private handleWheel = (
    pointer: Phaser.Input.Pointer,
    _currentlyOver: Phaser.GameObjects.GameObject[],
    _deltaX: number,
    deltaY: number
  ): void => {
    const baseZoom = this.zoomTween ? this.zoomTween.to : this.camera.zoom;
    const rawZoom = baseZoom - deltaY * WHEEL_ZOOM_SENSITIVITY;
    const nextZoom = Phaser.Math.Clamp(
      Math.round(rawZoom / this.zoomStep) * this.zoomStep,
      this.minZoom,
      this.maxZoom
    );
    if (nextZoom === baseZoom) {
      return;
    }
    this.stopInertia();
    this.manual = true;
    this.camera.stopFollow();
    const before = this.camera.getWorldPoint(pointer.x, pointer.y);
    this.zoomTween = {
      from: this.camera.zoom,
      to: nextZoom,
      elapsed: 0,
      anchor: { screenX: pointer.x, screenY: pointer.y, worldX: before.x, worldY: before.y }
    };
  };

  // Capture-phase window listener fires before the scene's own pointerup, so a
  // still-pending gesture is left for handlePointerUp (or the update safety) to close.
  private handleWindowRelease = (): void => {
    if (this.gesture === "dragging") {
      this.startInertia();
      this.endGesture();
    } else if (this.gesture === "minimap") {
      this.endGesture();
    }
  };

  private handleSceneLifecycle = (): void => {
    this.destroy();
  };

  private endGesture(): void {
    if (this.gesture === "none") {
      return;
    }
    this.gesture = "none";
    this.samples = [];
    this.scene.game.canvas.style.cursor = "grab";
  }

  private startInertia(): void {
    const last = this.samples[this.samples.length - 1];
    if (!last) {
      return;
    }
    let first = this.samples[0];
    for (let i = this.samples.length - 1; i >= 0; i--) {
      if (last.t - this.samples[i].t <= INERTIA_SAMPLE_WINDOW_MS) {
        first = this.samples[i];
      } else {
        break;
      }
    }
    const dt = last.t - first.t;
    if (dt <= 0) {
      return;
    }
    const vx = -((last.x - first.x) / dt) / this.camera.zoom;
    const vy = -((last.y - first.y) / dt) / this.camera.zoom;
    const speed = Math.hypot(vx, vy);
    if (speed < INERTIA_STOP_SPEED) {
      return;
    }
    const cap = speed > INERTIA_MAX_SPEED ? INERTIA_MAX_SPEED / speed : 1;
    this.inertiaX = vx * cap;
    this.inertiaY = vy * cap;
  }

  private stopInertia(): void {
    this.inertiaX = 0;
    this.inertiaY = 0;
  }

  private completeZoomTween(): void {
    if (!this.zoomTween) {
      return;
    }
    this.camera.setZoom(this.zoomTween.to);
    this.zoomTween = null;
  }

  private resumeFollow(immediate: boolean): void {
    this.stopInertia();
    this.completeZoomTween();
    this.manual = false;
    this.camera
      .startFollow(this.player, true, 0.1, 0.1, 0, this.followOffsetY)
      .setDeadzone(this.deadzone.width, this.deadzone.height);
    if (immediate) {
      this.camera.centerOn(this.player.x, this.player.y + this.followOffsetY);
    }
  }

  private isPlayerMoving(): boolean {
    const body = (this.player as Phaser.Physics.Arcade.Sprite).body as Phaser.Physics.Arcade.Body | null;
    if (!body) {
      return false;
    }
    return body.velocity.x !== 0 || body.velocity.y !== 0;
  }

  private isOverMinimap(x: number, y: number): boolean {
    if (!this.minimapOptions) {
      return false;
    }
    const { x: mx, y: my, width, height } = this.minimapOptions;
    return x >= mx && x <= mx + width && y >= my && y <= my + height;
  }

  private syncMinimapViewport(): void {
    if (!this.viewportFrame) {
      return;
    }
    const width = this.camera.width / this.camera.zoom;
    const height = this.camera.height / this.camera.zoom;
    this.viewportFrame
      .setPosition(this.camera.scrollX + width / 2, this.camera.scrollY + height / 2)
      .setSize(width, height);
  }
}
