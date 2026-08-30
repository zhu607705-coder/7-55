import Phaser from "phaser";

export const RPG_LOGICAL_WIDTH = 960;
export const RPG_LOGICAL_HEIGHT = 540;
export const RPG_MAX_RENDER_SCALE = 3;
export const RPG_PIXEL_FONT_FAMILY = "'Fusion Pixel 12px Proportional SC', 'Fusion Pixel', 'Zpix', 'PingFang SC', 'Microsoft YaHei', sans-serif";

const RENDER_SCALE_REGISTRY_KEY = "rpgRenderScale";
const RENDER_SNAPSHOT_REGISTRY_KEY = "rpgRenderResolution";
const SCALE_EPSILON = 0.001;
const MIN_TEXT_TEXTURE_RESOLUTION = 2;
const RPG_PIXEL_FONT_FACE = "Fusion Pixel 12px Proportional SC";

const cameraRenderScales = new WeakMap<Phaser.Cameras.Scene2D.Camera, number>();

interface LogicalScreenSpaceEntry {
  object: Phaser.GameObjects.GameObject & {
    depth: number;
    parentContainer?: Phaser.GameObjects.Container;
    scrollFactorX?: number;
    scrollFactorY?: number;
  };
  wrapper: Phaser.GameObjects.Container;
}

export interface RpgRenderResolutionSnapshot {
  logicalWidth: number;
  logicalHeight: number;
  displayWidth: number;
  displayHeight: number;
  backingWidth: number;
  backingHeight: number;
  devicePixelRatio: number;
  renderScale: number;
}

function finitePositive(value: number, fallback: number): number {
  return Number.isFinite(value) && value > 0 ? value : fallback;
}

function hasLiveScaleManager(game: Phaser.Game): boolean {
  const lifecycleGame = game as Phaser.Game & { pendingDestroy?: boolean };
  const scale = game.scale as Phaser.Scale.ScaleManager & {
    game: Phaser.Game | null;
    canvas: HTMLCanvasElement | null;
    canvasBounds: Phaser.Geom.Rectangle | null;
  };
  return game.isBooted
    && lifecycleGame.pendingDestroy !== true
    && scale.game === game
    && scale.canvas !== null
    && scale.canvasBounds !== null;
}

export function calculateRpgRenderScale(
  displayWidth: number,
  displayHeight: number,
  devicePixelRatio = typeof window === "undefined" ? 1 : window.devicePixelRatio || 1
): number {
  const width = finitePositive(displayWidth, RPG_LOGICAL_WIDTH);
  const height = finitePositive(displayHeight, RPG_LOGICAL_HEIGHT);
  const dpr = Math.max(1, finitePositive(devicePixelRatio, 1));
  const displayScale = Math.min(width / RPG_LOGICAL_WIDTH, height / RPG_LOGICAL_HEIGHT);
  return Phaser.Math.Clamp(Math.max(1, displayScale * dpr), 1, RPG_MAX_RENDER_SCALE);
}

export function getRpgRenderScale(scene: Phaser.Scene): number {
  const registered = Number(scene.registry.get(RENDER_SCALE_REGISTRY_KEY));
  return finitePositive(registered, 1);
}

export function toRpgLogicalScreenPoint(
  scene: Phaser.Scene,
  x: number,
  y: number
): Phaser.Math.Vector2 {
  const renderScale = getRpgRenderScale(scene);
  return new Phaser.Math.Vector2(x / renderScale, y / renderScale);
}

export function toRpgRenderZoom(scene: Phaser.Scene, logicalZoom: number): number {
  return logicalZoom * getRpgRenderScale(scene);
}

export function getRpgLogicalCameraZoom(
  scene: Phaser.Scene,
  camera: Phaser.Cameras.Scene2D.Camera = scene.cameras.main
): number {
  return camera.zoom / getRpgRenderScale(scene);
}

export function setRpgLogicalCameraZoom(
  scene: Phaser.Scene,
  logicalZoom: number,
  camera: Phaser.Cameras.Scene2D.Camera = scene.cameras.main
): Phaser.Cameras.Scene2D.Camera {
  const renderScale = getRpgRenderScale(scene);
  cameraRenderScales.set(camera, renderScale);
  return camera.setZoom(logicalZoom * renderScale);
}

export function zoomRpgCameraTo(
  scene: Phaser.Scene,
  logicalZoom: number,
  duration: number,
  ease: string,
  camera: Phaser.Cameras.Scene2D.Camera = scene.cameras.main
): Phaser.Cameras.Scene2D.Camera {
  const renderScale = getRpgRenderScale(scene);
  cameraRenderScales.set(camera, renderScale);
  return camera.zoomTo(logicalZoom * renderScale, duration, ease);
}

function activeCameras(game: Phaser.Game): Phaser.Cameras.Scene2D.Camera[] {
  return game.scene.getScenes(true).flatMap((scene) => scene.cameras.cameras);
}

function scaleCamera(
  camera: Phaser.Cameras.Scene2D.Camera,
  nextScale: number,
  center?: { x: number; y: number }
): void {
  const previousScale = cameraRenderScales.get(camera) ?? 1;
  if (Math.abs(previousScale - nextScale) >= SCALE_EPSILON) {
    const ratio = nextScale / previousScale;
    camera.setZoom(camera.zoom * ratio);
    if (camera.zoomEffect.isRunning) {
      camera.zoomEffect.source *= ratio;
      camera.zoomEffect.destination *= ratio;
    }
  }
  cameraRenderScales.set(camera, nextScale);
  if (center) camera.centerOn(center.x, center.y);
}

function syncActiveCameraScales(game: Phaser.Game, nextScale: number): void {
  activeCameras(game).forEach((camera) => scaleCamera(camera, nextScale));
}

function visitDisplayTree(
  object: Phaser.GameObjects.GameObject,
  visit: (candidate: Phaser.GameObjects.GameObject) => void
): void {
  visit(object);
  const children = (object as Phaser.GameObjects.GameObject & {
    list?: Phaser.GameObjects.GameObject[];
  }).list;
  if (!Array.isArray(children)) return;
  children.forEach((child) => visitDisplayTree(child, visit));
}

function syncScreenSpaceDescendantScrollFactors(
  object: Phaser.GameObjects.GameObject
): void {
  visitDisplayTree(object, (candidate) => {
    const scrollable = candidate as Phaser.GameObjects.GameObject & {
      setScrollFactor?: (x: number, y?: number) => unknown;
    };
    scrollable.setScrollFactor?.(0, 0);
  });
}

function parseHexStrokeColor(stroke: string): readonly [number, number, number] | null {
  const normalized = stroke.trim().toLowerCase();
  if (normalized === "black") return [0, 0, 0];
  const match = /^#([0-9a-f]{3}|[0-9a-f]{6})(?:[0-9a-f]{2})?$/.exec(normalized);
  if (!match) return null;
  const hex = match[1].length === 3
    ? match[1].split("").map((value) => value + value).join("")
    : match[1];
  return [
    Number.parseInt(hex.slice(0, 2), 16),
    Number.parseInt(hex.slice(2, 4), 16),
    Number.parseInt(hex.slice(4, 6), 16)
  ];
}

function isDarkNeutralStroke(stroke: unknown): stroke is string {
  if (typeof stroke !== "string") return false;
  const rgb = parseHexStrokeColor(stroke);
  if (!rgb) return false;
  const darkest = Math.min(...rgb);
  const lightest = Math.max(...rgb);
  return lightest <= 72 && lightest - darkest <= 40;
}

function maximumDarkStrokeThickness(fontSize: string | number): number {
  const parsedSize = Number.parseFloat(String(fontSize));
  if (!Number.isFinite(parsedSize) || parsedSize <= 20) return 1;
  if (parsedSize <= 36) return 2;
  return 3;
}

function syncRpgTextPresentation(
  scene: Phaser.Scene,
  renderScale: number,
  presentationVersion: number,
  appliedVersions: WeakMap<Phaser.GameObjects.Text, number>
): void {
  const targetResolution = Math.max(
    MIN_TEXT_TEXTURE_RESOLUTION,
    Math.ceil(renderScale - SCALE_EPSILON)
  );
  scene.children.list.forEach((root) => {
    visitDisplayTree(root, (object) => {
      if (!(object instanceof Phaser.GameObjects.Text)) return;
      const shouldRefreshFont = appliedVersions.get(object) !== presentationVersion
        || object.style.fontFamily !== RPG_PIXEL_FONT_FAMILY;
      if (shouldRefreshFont) {
        object.setFontFamily(RPG_PIXEL_FONT_FAMILY);
      }

      const maximumStrokeThickness = maximumDarkStrokeThickness(object.style.fontSize);
      if (
        object.style.strokeThickness > maximumStrokeThickness
        && isDarkNeutralStroke(object.style.stroke)
      ) {
        object.setStroke(object.style.stroke, maximumStrokeThickness);
      }

      if (object.style.resolution + SCALE_EPSILON < targetResolution) {
        object.setResolution(targetResolution);
      }
      // Phaser 3.87 redraws the larger text canvas but does not refresh this
      // source field after construction. Without it, higher-resolution text is
      // rendered physically larger instead of retaining its authored size.
      if (object.frame.source.resolution !== object.style.resolution) {
        object.frame.source.resolution = object.style.resolution;
      }
      appliedVersions.set(object, presentationVersion);
    });
  });
}

function createLogicalScreenSpaceWrapper(
  scene: Phaser.Scene,
  object: LogicalScreenSpaceEntry["object"]
): LogicalScreenSpaceEntry {
  const wrapper = scene.add.container(0, 0)
    .setScrollFactor(0)
    .setDepth(object.depth);
  syncScreenSpaceDescendantScrollFactors(object);
  wrapper.add(object);
  return { object, wrapper };
}

function syncLogicalScreenSpaceWrapperTransform(
  scene: Phaser.Scene,
  wrapper: Phaser.GameObjects.Container,
  renderScale: number
): void {
  const camera = scene.cameras.main;
  const cameraRotation = (camera as Phaser.Cameras.Scene2D.Camera & {
    rotation: number;
  }).rotation;
  const originX = camera.width * camera.originX;
  const originY = camera.height * camera.originY;
  const cos = Math.cos(cameraRotation);
  const sin = Math.sin(cameraRotation);
  const a = cos * camera.zoomX;
  const b = sin * camera.zoomX;
  const c = -sin * camera.zoomY;
  const d = cos * camera.zoomY;
  const e = Math.floor(camera.x + originX + 0.5) - a * originX - c * originY;
  const f = Math.floor(camera.y + originY + 0.5) - b * originX - d * originY;
  const determinant = a * d - b * c;
  if (Math.abs(determinant) < SCALE_EPSILON) return;

  // Canvas-rendered scrollFactor(0) objects still inherit the camera matrix.
  // Apply C^-1 * D on a parent, where C is that camera transform and D is the
  // desired logical-viewport-to-backing-store scale. This keeps authored HUD
  // coordinates at 960x540 while the backing canvas uses native device pixels.
  const desiredX = camera.x;
  const desiredY = camera.y;
  const deltaX = desiredX - e;
  const deltaY = desiredY - f;
  const pa = d * renderScale / determinant;
  const pb = -b * renderScale / determinant;
  const pc = -c * renderScale / determinant;
  const pd = a * renderScale / determinant;
  const pe = (d * deltaX - c * deltaY) / determinant;
  const pf = (-b * deltaX + a * deltaY) / determinant;
  const scaleX = Math.hypot(pa, pb);
  const rotation = Math.atan2(pb, pa);
  const scaleY = scaleX > SCALE_EPSILON
    ? (pa * pd - pb * pc) / scaleX
    : 1;
  wrapper
    .setPosition(pe, pf)
    .setRotation(rotation)
    .setScale(scaleX, scaleY);
}

function syncLogicalScreenSpace(
  game: Phaser.Game,
  renderScale: number,
  entries: Set<LogicalScreenSpaceEntry>,
  wrappers: WeakSet<Phaser.GameObjects.Container>,
  textPresentationVersion: number,
  textPresentationVersions: WeakMap<Phaser.GameObjects.Text, number>
): void {
  for (const entry of [...entries]) {
    if (!entry.object.scene || entry.object.parentContainer !== entry.wrapper) {
      if (entry.wrapper.scene) entry.wrapper.destroy();
      entries.delete(entry);
      continue;
    }
    syncScreenSpaceDescendantScrollFactors(entry.object);
    entry.wrapper.setDepth(entry.object.depth);
    syncLogicalScreenSpaceWrapperTransform(
      entry.object.scene,
      entry.wrapper,
      renderScale
    );
  }

  for (const scene of game.scene.getScenes(true)) {
    for (const candidate of [...scene.children.list]) {
      if (candidate instanceof Phaser.GameObjects.Container && wrappers.has(candidate)) continue;
      const object = candidate as LogicalScreenSpaceEntry["object"];
      if (
        object.scrollFactorX !== 0
        || object.scrollFactorY !== 0
      ) continue;
      const entry = createLogicalScreenSpaceWrapper(scene, object);
      syncLogicalScreenSpaceWrapperTransform(scene, entry.wrapper, renderScale);
      wrappers.add(entry.wrapper);
      entries.add(entry);
    }
    syncRpgTextPresentation(
      scene,
      renderScale,
      textPresentationVersion,
      textPresentationVersions
    );
  }
}

function createSnapshot(host: HTMLElement): RpgRenderResolutionSnapshot {
  const bounds = host.getBoundingClientRect();
  const displayWidth = finitePositive(bounds.width, RPG_LOGICAL_WIDTH);
  const displayHeight = finitePositive(bounds.height, RPG_LOGICAL_HEIGHT);
  const devicePixelRatio = typeof window === "undefined"
    ? 1
    : Math.max(1, finitePositive(window.devicePixelRatio || 1, 1));
  const renderScale = calculateRpgRenderScale(displayWidth, displayHeight, devicePixelRatio);
  return {
    logicalWidth: RPG_LOGICAL_WIDTH,
    logicalHeight: RPG_LOGICAL_HEIGHT,
    displayWidth,
    displayHeight,
    backingWidth: Math.round(RPG_LOGICAL_WIDTH * renderScale),
    backingHeight: Math.round(RPG_LOGICAL_HEIGHT * renderScale),
    devicePixelRatio,
    renderScale
  };
}

function exposeSnapshot(game: Phaser.Game, host: HTMLElement, snapshot: RpgRenderResolutionSnapshot): void {
  game.registry.set(RENDER_SNAPSHOT_REGISTRY_KEY, snapshot);
  host.dataset.rpgLogicalSize = `${snapshot.logicalWidth}x${snapshot.logicalHeight}`;
  host.dataset.rpgBackingSize = `${snapshot.backingWidth}x${snapshot.backingHeight}`;
  host.dataset.rpgRenderScale = snapshot.renderScale.toFixed(3);
  game.canvas.dataset.rpgLogicalSize = host.dataset.rpgLogicalSize;
  game.canvas.dataset.rpgBackingSize = host.dataset.rpgBackingSize;
  game.canvas.dataset.rpgRenderScale = host.dataset.rpgRenderScale;
}

export function installRpgAdaptiveResolution(game: Phaser.Game, host: HTMLElement): () => void {
  let stopped = false;
  let refreshFrame = 0;
  let lastDevicePixelRatio = Math.max(1, window.devicePixelRatio || 1);
  let textPresentationVersion = 0;
  const logicalScreenSpaceEntries = new Set<LogicalScreenSpaceEntry>();
  const logicalScreenSpaceWrappers = new WeakSet<Phaser.GameObjects.Container>();
  const textPresentationVersions = new WeakMap<Phaser.GameObjects.Text, number>();

  game.canvas.style.imageRendering = "auto";
  game.registry.set(RENDER_SCALE_REGISTRY_KEY, 1);

  const refresh = () => {
    refreshFrame = 0;
    if (stopped || !hasLiveScaleManager(game)) return;

    const snapshot = createSnapshot(host);
    lastDevicePixelRatio = snapshot.devicePixelRatio;
    const previousScale = finitePositive(Number(game.registry.get(RENDER_SCALE_REGISTRY_KEY)), 1);
    const cameras = activeCameras(game);
    const centers = new Map(
      cameras.map((camera) => [camera, { x: camera.midPoint.x, y: camera.midPoint.y }] as const)
    );
    const backingChanged = game.scale.width !== snapshot.backingWidth
      || game.scale.height !== snapshot.backingHeight;

    game.registry.set(RENDER_SCALE_REGISTRY_KEY, snapshot.renderScale);
    if (backingChanged) {
      game.scale.setGameSize(snapshot.backingWidth, snapshot.backingHeight);
    }
    cameras.forEach((camera) => scaleCamera(camera, snapshot.renderScale, centers.get(camera)));
    syncLogicalScreenSpace(
      game,
      snapshot.renderScale,
      logicalScreenSpaceEntries,
      logicalScreenSpaceWrappers,
      textPresentationVersion,
      textPresentationVersions
    );
    exposeSnapshot(game, host, snapshot);

    if (Math.abs(previousScale - snapshot.renderScale) < SCALE_EPSILON) {
      syncActiveCameraScales(game, snapshot.renderScale);
    }
  };

  const scheduleRefresh = () => {
    if (stopped || refreshFrame !== 0) return;
    refreshFrame = window.requestAnimationFrame(refresh);
  };
  const syncNewSceneCameras = () => {
    if (stopped || !hasLiveScaleManager(game)) return;
    const currentDevicePixelRatio = Math.max(1, window.devicePixelRatio || 1);
    if (Math.abs(currentDevicePixelRatio - lastDevicePixelRatio) >= SCALE_EPSILON) {
      scheduleRefresh();
      return;
    }
    const scale = finitePositive(Number(game.registry.get(RENDER_SCALE_REGISTRY_KEY)), 1);
    syncActiveCameraScales(game, scale);
  };
  const syncPresentation = () => {
    if (stopped || !hasLiveScaleManager(game)) return;
    const scale = finitePositive(Number(game.registry.get(RENDER_SCALE_REGISTRY_KEY)), 1);
    syncLogicalScreenSpace(
      game,
      scale,
      logicalScreenSpaceEntries,
      logicalScreenSpaceWrappers,
      textPresentationVersion,
      textPresentationVersions
    );
  };

  if (typeof document !== "undefined" && document.fonts) {
    void document.fonts.load(`16px "${RPG_PIXEL_FONT_FACE}"`).then(() => {
      if (stopped) return;
      textPresentationVersion += 1;
      syncPresentation();
    }).catch(() => undefined);
  }

  const resizeObserver = typeof ResizeObserver === "undefined"
    ? null
    : new ResizeObserver(scheduleRefresh);
  resizeObserver?.observe(host);
  window.addEventListener("resize", scheduleRefresh, { passive: true });
  window.addEventListener("orientationchange", scheduleRefresh, { passive: true });
  window.visualViewport?.addEventListener("resize", scheduleRefresh, { passive: true });
  game.events.on(Phaser.Core.Events.PRE_STEP, syncNewSceneCameras);
  game.events.on(Phaser.Core.Events.PRE_RENDER, syncPresentation);
  refresh();

  return () => {
    stopped = true;
    if (refreshFrame !== 0) window.cancelAnimationFrame(refreshFrame);
    resizeObserver?.disconnect();
    window.removeEventListener("resize", scheduleRefresh);
    window.removeEventListener("orientationchange", scheduleRefresh);
    window.visualViewport?.removeEventListener("resize", scheduleRefresh);
    game.events.off(Phaser.Core.Events.PRE_STEP, syncNewSceneCameras);
    game.events.off(Phaser.Core.Events.PRE_RENDER, syncPresentation);
    logicalScreenSpaceEntries.clear();
  };
}
