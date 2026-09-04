import * as THREE from "three";
import {
  resolveChapterFourStarLampCameraPose,
  resolveChapterFourStarLampSequenceFrame,
  type ChapterFourStarLampSequenceFrame
} from "./ChapterFourStarLampSequence";

const LOGICAL_WIDTH = 960;
const LOGICAL_HEIGHT = 540;

export interface ChapterFourStarLampThreeRendererCallbacks {
  onComplete: () => void;
  onFailure: (reason: string) => void;
  onFrame?: (frame: ChapterFourStarLampSequenceFrame) => void;
}

export interface ChapterFourStarLampThreeRendererSnapshot {
  phase: ChapterFourStarLampSequenceFrame["phase"];
  elapsedMs: number;
  cameraRiseProgress: number;
  cameraPosition: Readonly<{ x: number; y: number; z: number }>;
  lampRotationY: 0;
  ledLevel: number;
  coreLevel: number;
  glowLevel: number;
  canvas: Readonly<{ width: number; height: number }>;
  starLayers: number;
  reducedMotion: boolean;
}

interface StarLayer {
  points: THREE.Points<THREE.BufferGeometry, THREE.PointsMaterial>;
  baseOpacity: number;
  twinkleOffset: number;
}

/**
 * Three.js camera stage for the approved Chapter 4 layered lamp artwork.
 *
 * The original five PNG layers remain the visible lamp in the React layer.
 * Their screen-space projection follows the same camera-rise frame while this
 * renderer moves the three-dimensional star field through a PerspectiveCamera.
 * No lamp mesh or lamp rotation is created here, so the approved artwork cannot
 * be replaced or turned by the WebGL presentation.
 */
export class ChapterFourStarLampThreeRenderer {
  private readonly scene = new THREE.Scene();
  private readonly camera = new THREE.PerspectiveCamera(
    44,
    LOGICAL_WIDTH / LOGICAL_HEIGHT,
    0.1,
    120
  );
  private readonly renderer: THREE.WebGLRenderer;
  private readonly trackedGeometries = new Set<THREE.BufferGeometry>();
  private readonly trackedMaterials = new Set<THREE.Material>();
  private readonly trackedTextures = new Set<THREE.Texture>();
  private readonly starLayers: StarLayer[] = [];
  private readonly lookAtTarget = new THREE.Vector3(0, -4.1, 0);
  private readonly completedCallbackRef: { current: (() => void) | null } = { current: null };
  private readonly failureCallbackRef: { current: ((reason: string) => void) | null } = { current: null };
  private readonly frameCallbackRef: {
    current: ((frame: ChapterFourStarLampSequenceFrame) => void) | null;
  } = { current: null };
  private animationFrameId = 0;
  private elapsedMs = 0;
  private lastTimestamp: number | null = null;
  private lastFrame: ChapterFourStarLampSequenceFrame;
  private running = false;
  private destroyed = false;
  private completed = false;
  private failed = false;

  constructor(
    private readonly canvas: HTMLCanvasElement,
    private readonly reducedMotion = false
  ) {
    this.renderer = new THREE.WebGLRenderer({
      canvas,
      alpha: false,
      antialias: true,
      depth: true,
      powerPreference: "high-performance",
      preserveDrawingBuffer: false,
      stencil: false
    });
    try {
      this.renderer.outputColorSpace = THREE.SRGBColorSpace;
      this.renderer.toneMapping = THREE.ACESFilmicToneMapping;
      this.renderer.toneMappingExposure = 1.02;
      this.scene.background = new THREE.Color(0x01030a);
      this.scene.fog = new THREE.FogExp2(0x01030a, 0.016);
      this.buildStarfield();

      this.lastFrame = resolveChapterFourStarLampSequenceFrame(0, reducedMotion);
      this.canvas.dataset.renderer = "three-camera-stage";
      this.canvas.dataset.lampArtwork = "layered-original-v1";
      this.canvas.dataset.lampRotationY = "0.0000";
      this.canvas.addEventListener("webglcontextlost", this.handleContextLost, false);
      this.resize(canvas.clientWidth || LOGICAL_WIDTH, canvas.clientHeight || LOGICAL_HEIGHT);
      this.renderFrame(this.lastFrame);
    } catch (error) {
      this.destroy();
      throw error;
    }
  }

  start(callbacks: ChapterFourStarLampThreeRendererCallbacks): void {
    if (this.destroyed || this.running || this.completed || this.failed) return;
    this.completedCallbackRef.current = callbacks.onComplete;
    this.failureCallbackRef.current = callbacks.onFailure;
    this.frameCallbackRef.current = callbacks.onFrame ?? null;
    this.elapsedMs = 0;
    this.lastTimestamp = null;
    this.running = true;
    this.frameCallbackRef.current?.(this.lastFrame);
    this.animationFrameId = window.requestAnimationFrame(this.tick);
  }

  resize(width: number, height: number): void {
    if (this.destroyed) return;
    const renderWidth = Math.max(1, Math.round(width));
    const renderHeight = Math.max(1, Math.round(height));
    const pixelRatio = Math.min(window.devicePixelRatio || 1, 2);
    this.renderer.setPixelRatio(pixelRatio);
    this.renderer.setSize(renderWidth, renderHeight, false);
    this.camera.aspect = renderWidth / renderHeight;
    this.camera.updateProjectionMatrix();
    this.renderFrame(this.lastFrame);
  }

  renderAtElapsed(elapsedMs: number): void {
    if (this.destroyed) return;
    this.elapsedMs = Math.max(0, elapsedMs);
    const frame = resolveChapterFourStarLampSequenceFrame(this.elapsedMs, this.reducedMotion);
    this.lastFrame = frame;
    this.renderFrame(frame);
    this.frameCallbackRef.current?.(frame);
  }

  getSnapshot(): ChapterFourStarLampThreeRendererSnapshot {
    const cameraPosition = resolveChapterFourStarLampCameraPose(this.lastFrame);
    return {
      phase: this.lastFrame.phase,
      elapsedMs: Math.round(this.lastFrame.elapsedMs),
      cameraRiseProgress: Number(this.lastFrame.cameraRiseProgress.toFixed(4)),
      cameraPosition: {
        x: Number(cameraPosition.x.toFixed(4)),
        y: Number(cameraPosition.y.toFixed(4)),
        z: Number(cameraPosition.z.toFixed(4))
      },
      lampRotationY: 0,
      ledLevel: Number(this.lastFrame.ledLevel.toFixed(4)),
      coreLevel: Number(this.lastFrame.coreLevel.toFixed(4)),
      glowLevel: Number(this.lastFrame.glowLevel.toFixed(4)),
      canvas: { width: this.canvas.width, height: this.canvas.height },
      starLayers: this.starLayers.length,
      reducedMotion: this.reducedMotion
    };
  }

  destroy(): void {
    if (this.destroyed) return;
    this.destroyed = true;
    this.running = false;
    window.cancelAnimationFrame(this.animationFrameId);
    this.canvas.removeEventListener("webglcontextlost", this.handleContextLost, false);
    this.completedCallbackRef.current = null;
    this.failureCallbackRef.current = null;
    this.frameCallbackRef.current = null;
    this.scene.clear();
    this.trackedGeometries.forEach((geometry) => geometry.dispose());
    this.trackedMaterials.forEach((material) => material.dispose());
    this.trackedTextures.forEach((texture) => texture.dispose());
    this.trackedGeometries.clear();
    this.trackedMaterials.clear();
    this.trackedTextures.clear();
    this.renderer.dispose();
  }

  private readonly tick = (timestamp: number): void => {
    if (!this.running || this.destroyed || this.failed || this.completed) return;
    if (document.visibilityState === "hidden") {
      this.lastTimestamp = null;
      this.animationFrameId = window.requestAnimationFrame(this.tick);
      return;
    }

    if (this.lastTimestamp === null) this.lastTimestamp = timestamp;
    const frameDelta = Math.min(100, Math.max(0, timestamp - this.lastTimestamp));
    this.lastTimestamp = timestamp;
    this.elapsedMs += frameDelta;

    try {
      this.renderAtElapsed(this.elapsedMs);
    } catch (error) {
      this.fail(error instanceof Error ? error.message : "star_lamp_webgl_render_failed");
      return;
    }

    if (this.lastFrame.phase === "complete") {
      this.completed = true;
      this.running = false;
      this.completedCallbackRef.current?.();
      return;
    }
    this.animationFrameId = window.requestAnimationFrame(this.tick);
  };

  private readonly handleContextLost = (event: Event): void => {
    event.preventDefault();
    this.fail("star_lamp_webgl_context_lost");
  };

  private fail(reason: string): void {
    if (this.failed || this.completed || this.destroyed) return;
    this.failed = true;
    this.running = false;
    window.cancelAnimationFrame(this.animationFrameId);
    this.failureCallbackRef.current?.(reason);
  }

  private buildStarfield(): void {
    const starTexture = this.createStarPointTexture();
    this.starLayers.push(
      this.createStarLayer(4200, 38, 54, 0.12, 0x97acd2, 0.5, 1.1, starTexture),
      this.createStarLayer(1600, 28, 38, 0.19, 0xd4dded, 0.66, 2.4, starTexture),
      this.createStarLayer(520, 20, 28, 0.28, 0xffe7ae, 0.82, 4.7, starTexture)
    );
    this.starLayers.forEach(({ points }) => this.scene.add(points));
  }

  private createStarLayer(
    count: number,
    minimumRadius: number,
    maximumRadius: number,
    size: number,
    color: number,
    baseOpacity: number,
    seed: number,
    starTexture: THREE.Texture
  ): StarLayer {
    const positions = new Float32Array(count * 3);
    let randomState = Math.floor(seed * 1_000_003) >>> 0;
    const random = () => {
      randomState = (Math.imul(randomState, 1664525) + 1013904223) >>> 0;
      return randomState / 0x1_0000_0000;
    };
    for (let index = 0; index < count; index += 1) {
      const radius = minimumRadius + random() * (maximumRadius - minimumRadius);
      const cosTheta = random() * 2 - 1;
      const sinTheta = Math.sqrt(1 - cosTheta * cosTheta);
      const phi = random() * Math.PI * 2;
      positions[index * 3] = radius * sinTheta * Math.cos(phi);
      positions[index * 3 + 1] = radius * cosTheta;
      positions[index * 3 + 2] = radius * sinTheta * Math.sin(phi);
    }
    const geometry = this.trackGeometry(new THREE.BufferGeometry());
    geometry.setAttribute("position", new THREE.BufferAttribute(positions, 3));
    const material = this.trackMaterial(new THREE.PointsMaterial({
      blending: THREE.AdditiveBlending,
      color,
      depthWrite: false,
      map: starTexture,
      opacity: baseOpacity,
      size,
      sizeAttenuation: true,
      toneMapped: false,
      transparent: true
    }));
    return {
      points: new THREE.Points(geometry, material),
      baseOpacity,
      twinkleOffset: seed
    };
  }

  private createStarPointTexture(): THREE.DataTexture {
    const size = 32;
    const data = new Uint8Array(size * size * 4);
    for (let y = 0; y < size; y += 1) {
      for (let x = 0; x < size; x += 1) {
        const dx = (x + 0.5) / size * 2 - 1;
        const dy = (y + 0.5) / size * 2 - 1;
        const radius = Math.sqrt(dx * dx + dy * dy);
        const alpha = Math.round(Math.pow(Math.max(0, 1 - radius), 1.7) * 255);
        const offset = (y * size + x) * 4;
        data[offset] = 255;
        data[offset + 1] = 255;
        data[offset + 2] = 255;
        data[offset + 3] = alpha;
      }
    }
    const texture = this.trackTexture(new THREE.DataTexture(
      data,
      size,
      size,
      THREE.RGBAFormat,
      THREE.UnsignedByteType
    ));
    texture.colorSpace = THREE.SRGBColorSpace;
    texture.needsUpdate = true;
    return texture;
  }

  private renderFrame(frame: ChapterFourStarLampSequenceFrame): void {
    if (this.destroyed) return;
    const cameraPosition = resolveChapterFourStarLampCameraPose(frame);
    this.camera.position.set(cameraPosition.x, cameraPosition.y, cameraPosition.z);
    this.lookAtTarget.set(0, frame.cameraLookAtHeight, 0);
    this.camera.lookAt(this.lookAtTarget);

    this.starLayers.forEach((layer) => {
      const twinkle = 0.88 + Math.sin(frame.elapsedMs * 0.0012 + layer.twinkleOffset) * 0.12;
      layer.points.material.opacity = layer.baseOpacity * frame.starfieldLevel * twinkle;
    });

    this.canvas.dataset.sequencePhase = frame.phase;
    this.canvas.dataset.sequenceProgress = frame.progress.toFixed(4);
    this.canvas.dataset.cameraRise = frame.cameraRiseProgress.toFixed(4);
    this.canvas.dataset.cameraX = cameraPosition.x.toFixed(4);
    this.canvas.dataset.cameraY = cameraPosition.y.toFixed(4);
    this.canvas.dataset.cameraZ = cameraPosition.z.toFixed(4);
    this.canvas.dataset.lampRotationY = "0.0000";
    this.canvas.dataset.lightLevel = Math.max(
      frame.ledLevel,
      frame.coreLevel,
      frame.glowLevel
    ).toFixed(4);
    this.renderer.render(this.scene, this.camera);
  }

  private trackGeometry<T extends THREE.BufferGeometry>(geometry: T): T {
    this.trackedGeometries.add(geometry);
    return geometry;
  }

  private trackMaterial<T extends THREE.Material>(material: T): T {
    this.trackedMaterials.add(material);
    return material;
  }

  private trackTexture<T extends THREE.Texture>(texture: T): T {
    this.trackedTextures.add(texture);
    return texture;
  }
}
