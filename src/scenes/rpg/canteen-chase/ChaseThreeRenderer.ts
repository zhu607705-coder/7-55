import * as THREE from "three";
import { visibleStuntObstacles as visibleObstacles, STUNT_RAMPS, STUNT_PICKUPS } from "./ChaseStuntModel";
import { mergeGeometries } from "three/examples/jsm/utils/BufferGeometryUtils.js";
import {
  visiblePedestrians,
  VISIBLE_DISTANCE,
  type ChaseObstacle,
  type ChaseObstacleKind,
  type ChasePedestrian,
  type ChasePedestrianKind
} from "./ChaseGeometry";
import type { ChaseRenderState, ChaseRendererBackend } from "./ChaseRenderContract";
import {
  applyChaseRiderPose,
  CHASE_RIDER_GEAR_RATIO,
  CHASE_RIDER_DISPLAY_SCALE,
  CHASE_RIDER_WHEEL_RADIUS,
  createChaseRiderRig,
  createChaseBicycleRig,
  measureChaseRiderContactError,
  measureChaseRiderFootOrientationError,
  measureChaseRiderRigComplexity,
  type ChaseRiderRig
} from "./ChaseRiderRig";
import { ThreePrimitiveCache, type ThreeFlatMaterial } from "../ThreePrimitiveCache";
import { createChaseCampusEnvironment, createChaseTheaterFacade } from "./ChaseCampusEnvironment";
import { CHASE_WORLD_PER_METER, chaseStageAt } from "./ChaseRoute";
import { createChasePedestrian, animateChasePedestrian, type ChasePedestrianModel as PedestrianModel } from "./ChasePeople";

const LOGICAL_WIDTH = 960;
const LOGICAL_HEIGHT = 540;
const GOAL_DISTANCE = 755;
const WORLD_PER_METER = CHASE_WORLD_PER_METER;
const ROAD_HALF_WIDTH = 5.55;
const LANE_X = [-3.35, 0, 3.35] as const;
const PLAYER_CAMERA_GAP = 8.1;
const PLAYER_LOOK_AHEAD = 13.5;
const PLAYER_BASE_Y = 0.08;
const DESTINATION_Z = -GOAL_DISTANCE * WORLD_PER_METER - 8;
const DEFAULT_TONE_MAPPING_EXPOSURE = 1.02;
const MAX_PEDAL_CADENCE_RPM = 110;
const PEDAL_CADENCE_RESPONSE = 10;
const SEATED_PEDAL_BOB_AMPLITUDE = 0.008;
const LANE_POSITION_RESPONSE = 11;
const LANE_VELOCITY_RESPONSE = 14;
const STEERING_RESPONSE = 12;
const HANDLEBAR_RESPONSE = 16;
const CAMERA_FOLLOW_RESPONSE = 5.5;
const TWO_PI = Math.PI * 2;

const PALETTE = {
  sky: 0xc4dfe4,
  fog: 0xd6e4df,
  grass: 0x6f9852,
  grassDark: 0x4e713f,
  water: 0x397f96,
  waterLight: 0x6fb8bd,
  road: 0x657073,
  roadEdge: 0xe7d39a,
  lane: 0xf0e8cf,
  pavement: 0xb4a88e,
  pavementLight: 0xd2c5a6,
  outline: 0x17232b,
  blue: 0x315f9f,
  blueDark: 0x234672,
  cyan: 0x6bbec8,
  yellow: 0xe8c94e,
  amber: 0xf0b34d,
  red: 0xd95b4e,
  orange: 0xe87938,
  white: 0xf1ead7,
  skin: 0xf6bd86,
  hair: 0x293038,
  brick: 0xa95740,
  brickDark: 0x794033,
  cream: 0xdccdae,
  creamDark: 0xad9d81,
  glass: 0x385a68,
  glassLight: 0x7fa3ad,
  theaterRoof: 0xd7d6ce,
  theaterRoofShade: 0xaeb2af,
  theaterStone: 0xc8c1ad,
  theaterFrame: 0xe2ded0,
  tree: 0x4f8248,
  treeLight: 0x7cab57,
  trunk: 0x66472f,
  metal: 0x68757a,
  shadow: 0x253128
} as const;

const CHASE_PRIMITIVES = new ThreePrimitiveCache();

type VoxelMaterial = ThreeFlatMaterial;

function clamp(value: number, minimum: number, maximum: number): number {
  return Math.max(minimum, Math.min(maximum, value));
}

function safeMatchMedia(query: string): boolean {
  return typeof window !== "undefined"
    && typeof window.matchMedia === "function"
    && window.matchMedia(query).matches;
}

function defaultPixelRatioCap(): number {
  return 1.25;
}

function smoothstep(value: number): number {
  const t = clamp(value, 0, 1);
  return t * t * (3 - 2 * t);
}

function frameResponse(rate: number, deltaSeconds: number): number {
  if (deltaSeconds <= 0) return 0;
  return 1 - Math.exp(-rate * deltaSeconds);
}

function hashString(value: string): number {
  let hash = 2166136261;
  for (let index = 0; index < value.length; index += 1) {
    hash ^= value.charCodeAt(index);
    hash = Math.imul(hash, 16777619);
  }
  return hash >>> 0;
}

function material(color: number, unlit = false): VoxelMaterial {
  return CHASE_PRIMITIVES.material(color, { unlit, shading: "standard", roughness: 0.78, flatShading: false });
}

function pixelTextTexture(
  text: string,
  background: string,
  foreground = "#F3E8C9",
  width = 320,
  height = 72
): THREE.CanvasTexture {
  const canvas = document.createElement("canvas");
  canvas.width = width;
  canvas.height = height;
  const context = canvas.getContext("2d");
  if (context) {
    context.imageSmoothingEnabled = false;
    context.fillStyle = background;
    context.fillRect(0, 0, width, height);
    context.strokeStyle = foreground;
    context.lineWidth = 6;
    context.strokeRect(6, 6, width - 12, height - 12);
    context.fillStyle = foreground;
    context.font = "700 34px monospace, sans-serif";
    context.textAlign = "center";
    context.textBaseline = "middle";
    context.fillText(text, width / 2, height / 2 + 1);
  }
  const texture = new THREE.CanvasTexture(canvas);
  texture.colorSpace = THREE.SRGBColorSpace;
  texture.magFilter = THREE.NearestFilter;
  texture.minFilter = THREE.NearestFilter;
  texture.generateMipmaps = false;
  return texture;
}

function pixelSign(text: string, width = 3.8, color = "#173A57"): THREE.Group {
  const group = new THREE.Group();
  const texture = pixelTextTexture(text, color);
  const face = new THREE.Mesh(
    CHASE_PRIMITIVES.plane(width, 0.88),
    new THREE.MeshBasicMaterial({ map: texture, transparent: false, toneMapped: false })
  );
  face.position.set(0, 2.55, 0.05);
  group.add(
    box(width + 0.18, 1.04, 0.18, PALETTE.outline, 0, 2.55, 0),
    box(0.16, 2.2, 0.16, PALETTE.outline, -width * 0.34, 1.1, 0),
    box(0.16, 2.2, 0.16, PALETTE.outline, width * 0.34, 1.1, 0),
    face
  );
  return group;
}

function box(
  width: number,
  height: number,
  depth: number,
  color: number,
  x = 0,
  y = 0,
  z = 0,
  unlit = false
): THREE.Mesh {
  const mesh = new THREE.Mesh(CHASE_PRIMITIVES.box(width, height, depth), material(color, unlit));
  mesh.position.set(x, y, z);
  return mesh;
}

function roundedPart(radius: number, length: number, color: number, x: number, y: number, z: number): THREE.Mesh {
  const part = new THREE.Mesh(CHASE_PRIMITIVES.capsule(radius, length, 6, 12), material(color));
  part.position.set(x, y, z);
  return part;
}

function ovalPart(width: number, height: number, depth: number, color: number, x: number, y: number, z: number): THREE.Mesh {
  const part = new THREE.Mesh(CHASE_PRIMITIVES.sphere(1, 16, 12), material(color));
  part.scale.set(width, height, depth);
  part.position.set(x, y, z);
  return part;
}

function pixelWheel(radius: number): THREE.Mesh {
  const wheel = new THREE.Mesh(
    CHASE_PRIMITIVES.torus(radius, radius * 0.18, 4, 10),
    material(PALETTE.outline)
  );
  wheel.rotation.y = Math.PI / 2;
  return wheel;
}

function blobShadow(width: number, depth: number): THREE.Mesh {
  const shadow = new THREE.Mesh(
    CHASE_PRIMITIVES.plane(width, depth),
    CHASE_PRIMITIVES.material(PALETTE.shadow, { unlit: true, opacity: 0.34, depthWrite: false })
  );
  shadow.rotation.x = -Math.PI / 2;
  shadow.position.y = 0.018;
  shadow.name = "canteen-chase-blob-shadow";
  return shadow;
}

function buildPerson(kind: ChasePedestrianKind, seed: number): PedestrianModel {
  return createChasePedestrian(CHASE_PRIMITIVES, kind, seed);
}

function buildSimpleBicycle(color: number): THREE.Group {
  return createChaseBicycleRig(CHASE_PRIMITIVES, { ...PALETTE, blue: color }).bicycleRoot;
}

function buildObstacle(kind: ChaseObstacleKind): THREE.Group {
  const group = new THREE.Group();
  if (kind === "barrier") {
    group.add(blobShadow(2.4, 0.7));
    group.add(box(2.4, 0.58, 0.2, PALETTE.yellow, 0, 0.9, 0));
    for (const x of [-0.72, 0, 0.72]) group.add(box(0.3, 0.62, 0.22, PALETTE.outline, x, 0.9, 0));
    group.add(box(0.15, 1.1, 0.15, PALETTE.metal, -0.82, 0.52, 0));
    group.add(box(0.15, 1.1, 0.15, PALETTE.metal, 0.82, 0.52, 0));
    group.add(box(0.28, 0.28, 0.22, PALETTE.red, 0, 1.36, 0, true));
  } else if (kind === "cone") {
    group.add(blobShadow(1.1, 1.0));
    const cone = new THREE.Mesh(CHASE_PRIMITIVES.cone(0.45, 1.25, 24), material(PALETTE.orange));
    cone.position.y = 0.7;
    group.add(box(1.05, 0.14, 1.05, PALETTE.outline, 0, 0.07, 0), cone);
    const stripe = new THREE.Mesh(CHASE_PRIMITIVES.cylinder(0.21, 0.27, 0.15, 24), material(PALETTE.white));
    stripe.position.y = 0.62;
    group.add(stripe);
  } else if (kind === "car") {
    group.add(blobShadow(2.35, 4.1));
    const profile = new THREE.Shape();
    profile.moveTo(-1.85, 0.45);
    profile.lineTo(-1.78, 0.94);
    profile.lineTo(-0.99, 1.02);
    profile.lineTo(-0.48, 1.67);
    profile.lineTo(0.86, 1.64);
    profile.lineTo(1.36, 1.09);
    profile.lineTo(1.78, 1.0);
    profile.lineTo(1.85, 0.46);
    profile.closePath();
    const bodyGeometry = new THREE.ExtrudeGeometry(profile, { depth: 1.94, steps: 1, bevelEnabled: true, bevelSize: 0.055, bevelThickness: 0.055, bevelSegments: 3 });
    bodyGeometry.translate(0, 0, -0.97);
    bodyGeometry.rotateY(Math.PI / 2);
    const body = new THREE.Mesh(bodyGeometry, CHASE_PRIMITIVES.material(0x6c929b, { shading: "standard", metalness: 0.35, roughness: 0.35, flatShading: false }));
    group.add(body);
    const windscreen = box(1.77, 0.64, 0.035, 0x466776, 0, 1.35, 0.76);
    windscreen.rotation.x = -0.64;
    group.add(windscreen);
    for (const side of [-1, 1]) {
      group.add(box(0.02, 0.44, 0.61, 0x466776, side * 1.012, 1.34, -0.34));
      group.add(box(0.02, 0.44, 0.57, 0x557c88, side * 1.012, 1.34, 0.33));
      group.add(box(0.025, 0.033, 0.21, 0xd3d7d2, side * 1.018, 1.03, -0.23));
      group.add(ovalPart(0.16, 0.085, 0.13, 0x6c929b, side * 1.12, 1.15, 0.65));
      group.add(box(0.027, 0.06, 2.35, 0x405358, side * 1.02, 0.45, 0));
    }
    for (const x of [-1.08, 1.08]) {
      for (const z of [-1.18, 1.18]) {
        const wheel = new THREE.Mesh(CHASE_PRIMITIVES.cylinder(0.38, 0.38, 0.28, 32), material(PALETTE.outline));
        wheel.rotation.z = Math.PI / 2;
        wheel.position.set(x, 0.38, z);
        group.add(wheel);
        const hub = new THREE.Mesh(CHASE_PRIMITIVES.cylinder(0.24, 0.24, 0.29, 24), material(0xc1c9c8));
        hub.rotation.z = Math.PI / 2;
        hub.position.copy(wheel.position);
        group.add(hub);
      }
    }
    for (const side of [-1, 1]) {
      group.add(box(0.38, 0.11, 0.06, PALETTE.white, side * 0.62, 0.88, 1.91, true));
      group.add(box(0.4, 0.1, 0.055, 0xb86559, side * 0.62, 0.92, -1.91));
    }
    group.add(box(0.88, 0.16, 0.06, 0x34494f, 0, 0.63, 1.92));
    group.add(box(0.45, 0.13, 0.07, 0xe3dcc7, 0, 0.67, -1.92));
  } else if (kind === "bicycle") {
    group.add(buildSimpleBicycle(PALETTE.red));
    group.rotation.y = Math.PI;
  } else if (kind === "crowd") {
    for (let index = 0; index < 3; index += 1) {
      const person = buildPerson(index === 1 ? "soyMilk" : "phoneWalker", index + 10);
      person.group.position.x = (index - 1) * 0.75;
      person.group.position.z = index % 2 === 0 ? 0.18 : -0.18;
      group.add(person.group);
    }
  } else {
    group.add(buildPerson("phoneWalker", 19).group);
  }
  return group;
}


function disposeObject(object: THREE.Object3D): void {
  object.traverse((child) => {
    child.userData.disposeHuman?.();
    if (!(child instanceof THREE.Mesh)) return;
    if (!CHASE_PRIMITIVES.ownsGeometry(child.geometry)) child.geometry.dispose();
    const materials = Array.isArray(child.material) ? child.material : [child.material];
    materials.forEach((entry) => {
      if ("map" in entry && entry.map instanceof THREE.Texture) entry.map.dispose();
      if (!CHASE_PRIMITIVES.ownsMaterial(entry)) entry.dispose();
    });
  });
}

/**
 * Collapse immutable world meshes that share one material into one draw call.
 * Animated actors, runtime obstacles, text planes, lights and transparent
 * shadows stay separate so their behavior and visual order are unchanged.
 */
function mergeStaticWorldMeshes(root: THREE.Object3D): void {
  root.updateWorldMatrix(true, true);
  const buckets = new Map<THREE.Material, Map<number, THREE.BufferGeometry[]>>();
  const mergedSources: THREE.Mesh[] = [];
  root.traverse((child) => {
    if (!(child instanceof THREE.Mesh)) return;
    if (Array.isArray(child.material)) return;
    if (!CHASE_PRIMITIVES.ownsMaterial(child.material)) return;
    if (child.material.transparent) return;
    const geometry = child.geometry.index ? child.geometry.toNonIndexed() : child.geometry.clone();
    geometry.applyMatrix4(child.matrixWorld);
    geometry.computeBoundingSphere();
    const sphere = geometry.boundingSphere;
    const chunk = sphere && sphere.radius < 40 ? Math.floor(sphere.center.z / 24) : Number.MAX_SAFE_INTEGER;
    const materialBuckets = buckets.get(child.material) ?? new Map<number, THREE.BufferGeometry[]>();
    const entries = materialBuckets.get(chunk) ?? [];
    entries.push(geometry);
    materialBuckets.set(chunk, entries);
    buckets.set(child.material, materialBuckets);
    mergedSources.push(child);
  });
  mergedSources.forEach((mesh) => {
    mesh.removeFromParent();
    if (!CHASE_PRIMITIVES.ownsGeometry(mesh.geometry)) mesh.geometry.dispose();
  });
  buckets.forEach((chunks, material) => {
    chunks.forEach((geometries, chunk) => {
      const merged = mergeGeometries(geometries, false);
      geometries.forEach((geometry) => geometry.dispose());
      if (!merged) return;
      merged.computeBoundingSphere();
      merged.computeBoundingBox();
      const mesh = new THREE.Mesh(merged, material);
      mesh.name = `canteen-campus-chunk-${chunk}`;
      mesh.userData.worldMinZ = merged.boundingBox!.min.z;
      mesh.userData.worldMaxZ = merged.boundingBox!.max.z;
      root.add(mesh);
    });
  });
}

export class ChaseThreeRenderer implements ChaseRendererBackend {
  private readonly canvas: HTMLCanvasElement;
  private readonly renderer: THREE.WebGLRenderer;
  private readonly scene = new THREE.Scene();
  private readonly camera = new THREE.PerspectiveCamera(51, 16 / 9, 0.1, 150);
  private readonly observer: ResizeObserver;
  private readonly rider: ChaseRiderRig;
  private readonly paper = new THREE.Group();
  private readonly obstacleModels = new Map<string, THREE.Group>();
  private readonly pedestrianModels = new Map<string, PedestrianModel>();
  private readonly sun = new THREE.DirectionalLight(0xffecd3, 2.4);
  private readonly sunTarget = new THREE.Object3D();
  private staticWorld: THREE.Group | null = null;
  private quality: "high" | "balanced" | "light" = "high";
  private qualityFrameCount = 0;
  private qualityFrameTimeMs = 0;
  private readonly enableLiveShadows = safeMatchMedia("(pointer: fine)") && !safeMatchMedia("(any-pointer: coarse)");
  private reducedMotion = false;
  private lastTime = performance.now();
  private animationSeconds = 0;
  private previousDistance = 0;
  private pedalPhaseRadians = 0;
  private pedalCadenceRpm = 0;
  private previousRiderX = 0;
  private smoothedLaneVelocity = 0;
  private bodySteerRadians = 0;
  private lastCollisions = 0;
  private collisionFlashSeconds = 0;
  private readonly steeringPivot = new THREE.Vector3();
  private readonly steeringTip = new THREE.Vector3();
  private nextDebugSnapshotAt = 0;
  private readonly clearingStarts = new Map<string, number>();
  private readonly stuntObjects = new Map<string, THREE.Group>();
  private readonly bellRing = new THREE.Mesh(new THREE.RingGeometry(0.93,1,48), new THREE.MeshBasicMaterial({color:0xfbe5a2,transparent:true,opacity:0,side:THREE.DoubleSide,depthWrite:false}));
  private readonly trayShield = new THREE.Mesh(new THREE.TorusGeometry(1.25,.05,8,40),new THREE.MeshBasicMaterial({color:0x8becda,transparent:true,opacity:.72,depthWrite:false}));

  constructor(canvas: HTMLCanvasElement) {
    this.canvas = canvas;
    const context = canvas.getContext("webgl2", {
      alpha: false,
      antialias: true,
      depth: true,
      powerPreference: "high-performance",
      preserveDrawingBuffer: false,
      stencil: false
    });
    if (!context) throw new Error("WebGL2 unavailable for the 3D chase renderer.");
    this.renderer = new THREE.WebGLRenderer({ canvas, context, antialias: true, alpha: false, powerPreference: "high-performance" });
    this.renderer.outputColorSpace = THREE.SRGBColorSpace;
    this.renderer.toneMapping = THREE.ACESFilmicToneMapping;
    this.renderer.toneMappingExposure = DEFAULT_TONE_MAPPING_EXPOSURE;
    this.renderer.shadowMap.enabled = this.enableLiveShadows;
    this.renderer.shadowMap.type = THREE.PCFShadowMap;
    this.scene.background = new THREE.Color(PALETTE.sky);
    this.scene.fog = new THREE.Fog(PALETTE.fog, 45, 120);
    this.scene.add(new THREE.HemisphereLight(0xeaf4f1, 0x6e7b65, 2.0));
    this.sun.position.set(7, 15, 6);
    this.sun.target = this.sunTarget;
    this.scene.add(this.sunTarget, this.sun);
    const fill = new THREE.DirectionalLight(0xa7d2e4, 0.38);
    fill.position.set(-8, 7, -8);
    const portraitFill = new THREE.DirectionalLight(0xffd7ba, 0.28);
    portraitFill.position.set(0, 4.5, -8);
    this.scene.add(fill, portraitFill);
    this.configureLiveShadows();
    this.buildWorld();
    this.rider = createChaseRiderRig(CHASE_PRIMITIVES);
    this.rider.group.position.set(0, PLAYER_BASE_Y, 0);
    this.scene.add(this.rider.group);
    this.configureHeroShadowState();
    const riderComplexity = measureChaseRiderRigComplexity(this.rider);
    this.canvas.dataset.chaseRiderMeshes = String(riderComplexity.meshes);
    this.canvas.dataset.chaseRiderTriangles = String(riderComplexity.triangles);
    this.canvas.dataset.chaseRiderMaterials = String(riderComplexity.materials);
    this.buildPaper();
    this.scene.add(this.paper);
    this.bellRing.rotation.x=-Math.PI/2;this.scene.add(this.bellRing,this.trayShield);
    this.observer = new ResizeObserver(() => this.handleResize());
    this.observer.observe(canvas);
    this.handleResize();
    this.lastTime = performance.now();
  }

  destroy(): void {
    this.observer.disconnect();
    disposeObject(this.scene);
    // StrictMode and reduced-motion changes can reuse this canvas/context.
    // Restore pixel-store flags before the next renderer creates 3D placeholders.
    this.renderer.resetState();
    this.renderer.dispose();
  }

  setReducedMotion(reduced: boolean): void {
    this.reducedMotion = reduced;
  }

  getAssetState(): "loading" | "ready" | "error" {
    return this.rider.human.error ? "error" : this.rider.human.ready ? "ready" : "loading";
  }

  render(state: ChaseRenderState): void {
    const humanState = this.getAssetState();
    if (humanState === "ready" && this.canvas.dataset.chaseHumanState !== "ready") {
      const complexity = measureChaseRiderRigComplexity(this.rider);
      this.canvas.dataset.chaseRiderMeshes = String(complexity.meshes);
      this.canvas.dataset.chaseRiderTriangles = String(complexity.triangles);
      this.canvas.dataset.chaseRiderMaterials = String(complexity.materials);
      this.configureHeroShadowState();
    }
    this.canvas.dataset.chaseHumanState = humanState;
    if (this.rider.human.ready) this.canvas.dataset.chaseHumanContactErrors = JSON.stringify(this.rider.human.group.userData.contactErrors);
    const now = performance.now();
    const frameTimeMs = now - this.lastTime;
    const deltaSeconds = clamp(frameTimeMs / 1000, 0, 0.25);
    this.lastTime = now;
    this.updateRenderQuality(frameTimeMs);
    if (!state.paused && state.runState === "running" && !this.reducedMotion) {
      this.animationSeconds += deltaSeconds;
    }
    if (state.collisions > this.lastCollisions) this.collisionFlashSeconds = 0.22;
    this.lastCollisions = state.collisions;
    this.collisionFlashSeconds = Math.max(0, this.collisionFlashSeconds - deltaSeconds);

    const playerZ = -state.distance * WORLD_PER_METER;
    this.staticWorld?.children.forEach((object) => {
      const { worldMinZ, worldMaxZ } = object.userData;
      if (!Number.isFinite(worldMinZ) || !Number.isFinite(worldMaxZ)) return;
      const ahead = this.quality === "light" ? 65 : this.quality === "balanced" ? 85 : 115;
      object.visible = worldMaxZ >= playerZ - ahead && worldMinZ <= playerZ + 20;
    });
    const targetX = LANE_X[0] + clamp(state.lane,0,2) / 2 * (LANE_X[2]-LANE_X[0]);
    const easing = this.reducedMotion ? 1 : frameResponse(LANE_POSITION_RESPONSE, deltaSeconds);
    if(state.airHeight !== undefined)this.rider.group.position.x=targetX;
    else this.rider.group.position.x += (targetX - this.rider.group.position.x) * easing;
    this.rider.group.position.z = playerZ;
    const rawLaneVelocity = deltaSeconds > 0
      ? (this.rider.group.position.x - this.previousRiderX) / deltaSeconds
      : 0;
    this.previousRiderX = this.rider.group.position.x;
    if (this.reducedMotion) {
      this.smoothedLaneVelocity = 0;
      this.bodySteerRadians = 0;
    } else {
      this.smoothedLaneVelocity += (rawLaneVelocity - this.smoothedLaneVelocity)
        * frameResponse(LANE_VELOCITY_RESPONSE, deltaSeconds);
      const targetBodySteer = clamp(-this.smoothedLaneVelocity * 0.032, -0.28, 0.28);
      this.bodySteerRadians += (targetBodySteer - this.bodySteerRadians)
        * frameResponse(STEERING_RESPONSE, deltaSeconds);
    }
    const handlebarSteer = this.bodySteerRadians * 1.1;
    const resolvedHandlebarSteer = this.rider.frontAssembly.rotation.y
      + (handlebarSteer - this.rider.frontAssembly.rotation.y)
        * frameResponse(HANDLEBAR_RESPONSE, deltaSeconds);
    this.rider.group.rotation.z += (this.bodySteerRadians * 0.45 - this.rider.group.rotation.z)
      * frameResponse(STEERING_RESPONSE, deltaSeconds);
    const distanceReset = state.distance + Number.EPSILON < this.previousDistance;
    if (distanceReset) {
      this.clearingStarts.clear();
      this.pedalPhaseRadians = 0;
      this.pedalCadenceRpm = 0;
      this.rider.wheels.forEach((wheel) => { wheel.rotation.x = 0; });
    }
    const distanceDelta = Math.max(0, state.distance - this.previousDistance);
    this.previousDistance = state.distance;
    const wheelSpin = distanceDelta * WORLD_PER_METER / (CHASE_RIDER_WHEEL_RADIUS * CHASE_RIDER_DISPLAY_SCALE);
    // Travel is along -Z. Both wheel and crank must rotate about -X.
    const crankDelta = -wheelSpin / CHASE_RIDER_GEAR_RATIO;
    const pedalsCanAdvance = !state.paused && !this.reducedMotion && distanceDelta > 0;
    if (pedalsCanAdvance) {
      this.pedalPhaseRadians = (this.pedalPhaseRadians + crankDelta) % TWO_PI;
    }
    const targetCadenceRpm = pedalsCanAdvance && deltaSeconds > 0
      ? clamp((Math.abs(crankDelta) / deltaSeconds) * (60 / TWO_PI), 0, MAX_PEDAL_CADENCE_RPM)
      : 0;
    this.pedalCadenceRpm += (targetCadenceRpm - this.pedalCadenceRpm)
      * Math.min(1, deltaSeconds * PEDAL_CADENCE_RESPONSE);
    const pedalPhase = this.reducedMotion ? 0 : this.pedalPhaseRadians;
    const seatedPedalBob = this.reducedMotion
      ? 0
      : SEATED_PEDAL_BOB_AMPLITUDE * (0.5 - Math.cos(pedalPhase * 2) * 0.5);
    this.rider.group.position.y = PLAYER_BASE_Y + seatedPedalBob + (state.airHeight ?? 0);
    this.rider.group.rotation.x = (state.airHeight ?? 0)>0.05 ? -0.12 : (state.charge ?? 0)*0.06;
    applyChaseRiderPose(this.rider, "ride", {
      pedalPhaseRadians: pedalPhase,
      steeringRadians: resolvedHandlebarSteer
    });
    this.rider.wheels.forEach((wheel) => { wheel.rotation.x -= wheelSpin; });

    this.updateObstacles(state);
    this.updatePedestrians(state.distance);
    this.updatePaper(state);
    this.updateStuntObjects(state);
    this.updateShadowRig(playerZ);
    this.updateCamera(playerZ, deltaSeconds, state);
    const steeringPivot = this.rider.frontAssembly.localToWorld(this.steeringPivot.set(0, 0, 0)).project(this.camera);
    const steeringTip = this.rider.frontAssembly.localToWorld(this.steeringTip.set(0, 0, -1)).project(this.camera);
    const background = this.scene.background;
    if (background instanceof THREE.Color) {
      background.setHex(this.collisionFlashSeconds > 0 ? 0xb86868 : PALETTE.sky);
    }
    this.renderer.render(this.scene, this.camera);
    if (now >= this.nextDebugSnapshotAt) {
      this.nextDebugSnapshotAt = now + 100;
      this.canvas.dataset.chaseSteer = this.bodySteerRadians.toFixed(3);
      this.canvas.dataset.chaseHandlebarSteer = this.rider.frontAssembly.rotation.y.toFixed(3);
      this.canvas.dataset.chaseHandlebarScreenDx = (steeringTip.x - steeringPivot.x).toFixed(3);
      this.canvas.dataset.chaseRiderX = this.rider.group.position.x.toFixed(3);
      this.canvas.dataset.chaseTargetX = targetX.toFixed(3);
      this.canvas.dataset.chaseLaneVelocity = this.smoothedLaneVelocity.toFixed(3);
      this.canvas.dataset.chaseBodyRoll = this.rider.group.rotation.z.toFixed(3);
      this.canvas.dataset.chaseCameraX = this.camera.position.x.toFixed(3);
      this.canvas.dataset.chaseDrawCalls = String(this.renderer.info.render.calls);
      this.canvas.dataset.chaseTriangles = String(this.renderer.info.render.triangles);
      this.canvas.dataset.chaseStage = chaseStageAt(state.distance).id;
      this.canvas.dataset.chaseGameplay = "stunts-and-bell";
      this.canvas.dataset.chaseAirHeight = (state.airHeight??0).toFixed(3);
      this.canvas.dataset.chaseGeometries = String(this.renderer.info.memory.geometries);
      this.canvas.dataset.chaseTextures = String(this.renderer.info.memory.textures);
      this.canvas.dataset.chasePrimitiveGeometries = String(CHASE_PRIMITIVES.geometryCount);
      this.canvas.dataset.chasePrimitiveMaterials = String(CHASE_PRIMITIVES.materialCount);
      const contactError = measureChaseRiderContactError(this.rider);
      const footOrientationError = measureChaseRiderFootOrientationError(this.rider);
      this.canvas.dataset.chaseLeftHandContactError = contactError.leftHandToGripWorldUnits.toFixed(6);
      this.canvas.dataset.chaseRightHandContactError = contactError.rightHandToGripWorldUnits.toFixed(6);
      this.canvas.dataset.chaseLeftFootContactError = contactError.leftFootToPedalWorldUnits.toFixed(6);
      this.canvas.dataset.chaseRightFootContactError = contactError.rightFootToPedalWorldUnits.toFixed(6);
      this.canvas.dataset.chaseLeftFootSoleTilt = footOrientationError.leftSoleTiltRadians.toFixed(6);
      this.canvas.dataset.chaseRightFootSoleTilt = footOrientationError.rightSoleTiltRadians.toFixed(6);
      this.canvas.dataset.chaseLeftToeDirectionError = footOrientationError.leftToeDirectionRadians.toFixed(6);
      this.canvas.dataset.chaseRightToeDirectionError = footOrientationError.rightToeDirectionRadians.toFixed(6);
      this.canvas.dataset.chasePedalPhase = pedalPhase.toFixed(4);
      this.canvas.dataset.chaseCrankAngle = this.rider.crank.rotation.x.toFixed(4);
      this.canvas.dataset.chaseWheelAngle = this.rider.frontWheel.rotation.x.toFixed(4);
      this.canvas.dataset.chasePedalCadenceRpm = this.pedalCadenceRpm.toFixed(1);
      this.canvas.dataset.chasePedalGearRatio = CHASE_RIDER_GEAR_RATIO.toFixed(1);
      this.canvas.dataset.chaseSeatedPedalBob = seatedPedalBob.toFixed(4);
    }
  }

  private handleResize(): void {
    const cssWidth = this.canvas.clientWidth || LOGICAL_WIDTH;
    const cssHeight = this.canvas.clientHeight || LOGICAL_HEIGHT;
    const width = Math.max(480, Math.min(LOGICAL_WIDTH, Math.round(cssWidth)));
    const height = Math.max(270, Math.min(LOGICAL_HEIGHT, Math.round(cssHeight)));
    const qualityScale = this.quality === "light" ? 0.78 : this.quality === "balanced" ? 1 : defaultPixelRatioCap();
    this.renderer.setPixelRatio(Math.min(window.devicePixelRatio || 1, qualityScale));
    this.renderer.setSize(width, height, false);
    this.camera.aspect = width / height;
    this.camera.updateProjectionMatrix();
  }

  private updateRenderQuality(frameTimeMs: number): void {
    if (frameTimeMs <= 0 || frameTimeMs > 1000 || this.qualityFrameCount >= 50) return;
    this.qualityFrameCount += 1;
    this.qualityFrameTimeMs += frameTimeMs;
    if (this.qualityFrameCount !== 24) return;
    const mean = this.qualityFrameTimeMs / this.qualityFrameCount;
    this.quality = mean > 65 ? "light" : mean > 34 ? "balanced" : "high";
    this.canvas.dataset.chaseQuality = this.quality;
    this.canvas.dataset.chaseMeasuredFrameMs = mean.toFixed(1);
    if (this.quality === "high") return;
    this.renderer.shadowMap.enabled = false;
    const shadow = this.rider.root.getObjectByName("canteen-chase-rider-shadow");
    if (shadow) shadow.visible = true;
    this.camera.far = this.quality === "light" ? 92 : 115;
    this.scene.fog = new THREE.Fog(PALETTE.fog, 34, this.camera.far - 4);
    this.handleResize();
  }

  private configureLiveShadows(): void {
    if (!this.enableLiveShadows) return;
    this.sun.castShadow = true;
    this.sun.shadow.mapSize.set(1024, 1024);
    this.sun.shadow.camera.near = 0.5;
    this.sun.shadow.camera.far = 42;
    this.sun.shadow.camera.left = -9.5;
    this.sun.shadow.camera.right = 9.5;
    this.sun.shadow.camera.top = 12;
    this.sun.shadow.camera.bottom = -4.5;
    this.sun.shadow.bias = -0.00016;
    this.sun.shadow.normalBias = 0.065;
    this.sun.shadow.radius = 2.2;
  }

  private configureHeroShadowState(): void {
    this.rider.group.traverse((object) => {
      if (!(object instanceof THREE.Mesh)) return;
      object.castShadow = this.enableLiveShadows;
      object.receiveShadow = false;
      if (object.name === "canteen-chase-rider-shadow") object.visible = !this.enableLiveShadows;
    });
  }

  private updateShadowRig(playerZ: number): void {
    if (!this.enableLiveShadows) return;
    this.sun.position.z = playerZ + 8;
    this.sunTarget.position.set(this.rider.group.position.x * 0.18, 1.15, playerZ - 10);
    this.sun.target.updateMatrixWorld();
  }

  private buildWorld(): void {
    const staticWorld = createChaseCampusEnvironment(CHASE_PRIMITIVES);
    this.staticWorld = staticWorld;
    const destination = createChaseTheaterFacade(CHASE_PRIMITIVES);
    destination.position.set(0, 0, DESTINATION_Z);
    staticWorld.add(destination);
    mergeStaticWorldMeshes(staticWorld);
    staticWorld.traverse((object) => {
      if (!(object instanceof THREE.Mesh)) return;
      const material = object.material as THREE.MeshStandardMaterial;
      const color = material.color?.getHex();
      const ground = [0x788b6d, 0x657073, 0x727b7b, 0xe0d9c8, 0xecece0, 0xb9bfb6].includes(color);
      const foliage = [0x3b6045, 0x59794e, 0x2c4c3b].includes(color);
      object.castShadow = this.enableLiveShadows && !ground;
      object.receiveShadow = this.enableLiveShadows && !foliage;
    });
    this.scene.add(staticWorld);
  }

  private buildPaper(): void {
    const sheet = box(1.0, 0.72, 0.08, PALETTE.white, 0, 0, 0, true);
    sheet.rotation.z = 0.12;
    sheet.add(box(0.68, 0.08, 0.03, PALETTE.blue, 0, 0.16, -0.06, true));
    sheet.add(box(0.5, 0.07, 0.03, PALETTE.blue, -0.08, -0.04, -0.06, true));
    sheet.add(box(0.24, 0.18, 0.03, PALETTE.red, 0.26, -0.21, -0.06, true));
    this.paper.add(sheet);
    const glow = new THREE.PointLight(0x6fd8ff, 0.75, 6);
    this.paper.add(glow);
  }

  private updatePaper(state: ChaseRenderState): void {
    const distance=state.distance;
    const progress = clamp(distance / GOAL_DISTANCE, 0, 1);
    const ahead = state.paperGap ?? 28 - progress * 15;
    this.paper.position.set(
      state.paperLane !== undefined ? (state.paperLane-1)*3.4 : Math.sin(this.animationSeconds * 1.7) * (1.6 - progress * 0.8),
      3.25 + Math.sin(this.animationSeconds * 5.2) * 0.28,
      -distance * WORLD_PER_METER - ahead
    );
    this.paper.rotation.y = Math.sin(this.animationSeconds * 3.1) * 0.3;
    this.paper.rotation.z = Math.sin(this.animationSeconds * 4.4) * 0.12;
  }

  private updateObstacles(state: ChaseRenderState): void {
    const distance=state.distance;
    const visible = visibleObstacles(distance);
    const active = new Set(visible.map((entry) => entry.id));
    this.obstacleModels.forEach((model, id) => {
      if (active.has(id)) return;
      this.scene.remove(model);
      disposeObject(model);
      this.obstacleModels.delete(id);
    });
    visible.forEach((obstacle) => {
      let model = this.obstacleModels.get(obstacle.id);
      if (!model) {
        model = buildObstacle(obstacle.kind);
        this.obstacleModels.set(obstacle.id, model);
        this.scene.add(model);
      }
      this.placeObstacle(model, obstacle, distance);
      if(state.clearedObstacleIds?.has(obstacle.id)) {
        if(!this.clearingStarts.has(obstacle.id))this.clearingStarts.set(obstacle.id,this.animationSeconds);
        const progress=this.reducedMotion?1:clamp((this.animationSeconds-this.clearingStarts.get(obstacle.id)!)/.55,0,1);
        model.position.x += (obstacle.lane<1?-1:1)*progress*6;
        model.rotation.z = progress*(obstacle.lane<1?.45:-.45);
        model.visible=progress<1;
      } else {model.visible=true;model.rotation.z=0;}
    });
  }

  private updateStuntObjects(state: ChaseRenderState):void {
    const active=new Set<string>();
    for(const ramp of STUNT_RAMPS){
      if(ramp.distance<state.distance-8||ramp.distance>state.distance+100)continue;active.add(ramp.id);
      let group=this.stuntObjects.get(ramp.id);
      if(!group){group=new THREE.Group();
        const shape=new THREE.Shape();shape.moveTo(-2.4,0);shape.lineTo(2.4,0);shape.lineTo(2.4,1.15);shape.closePath();
        const geo=new THREE.ExtrudeGeometry(shape,{depth:2.3,bevelEnabled:false});geo.rotateY(Math.PI/2);geo.translate(-1.15,0,0);
        group.add(new THREE.Mesh(geo,material(0xd69431)));for(let i=0;i<3;i++)group.add(box(.22,.05,.8,0xffe7a7,(i-1)*.55,.7,.0));
        this.stuntObjects.set(ramp.id,group);this.scene.add(group);
      }
      group.position.set(LANE_X[ramp.lane],.01,-ramp.distance*WORLD_PER_METER);
    }
    for(const item of STUNT_PICKUPS){
      if(item.distance<state.distance-3||item.distance>state.distance+100||state.collectedPickupIds?.has(item.id))continue;active.add(item.id);
      let group=this.stuntObjects.get(item.id);
      if(!group){group=new THREE.Group();
        const ring=new THREE.Mesh(new THREE.TorusGeometry(.62,.09,8,20),new THREE.MeshStandardMaterial({color:item.kind==="tray"?0x82e8d2:0xffd783,emissive:item.kind==="tray"?0x246b5f:0x8f661b,emissiveIntensity:.6,roughness:.3}));group.add(ring);
        if(item.kind==="tray")group.add(box(.68,.48,.1,0xbfd5d0,0,0,0));else{const flap=box(.5,.65,.045,0xffedb9,0,0,0);flap.rotation.z=.25;group.add(flap);}
        this.stuntObjects.set(item.id,group);this.scene.add(group);
      }
      group.position.set(LANE_X[item.lane],1.6+Math.sin(this.animationSeconds*3)*.16,-item.distance*WORLD_PER_METER);group.rotation.y=this.animationSeconds*1.3;
    }
    for(const [id,group]of this.stuntObjects)if(!active.has(id)){this.scene.remove(group);disposeObject(group);this.stuntObjects.delete(id);}
    const pulse=state.bellPulse??0;this.bellRing.visible=pulse>0;this.bellRing.position.set(this.rider.group.position.x,.14,this.rider.group.position.z-3);this.bellRing.scale.setScalar(1+(1-pulse)*10);(this.bellRing.material as THREE.MeshBasicMaterial).opacity=pulse*.72;
    this.trayShield.visible=state.shield===true;this.trayShield.position.copy(this.rider.group.position);this.trayShield.position.y+=1.3;this.trayShield.rotation.y=this.animationSeconds*1.7;
  }

  private placeObstacle(model: THREE.Group, obstacle: ChaseObstacle, distance: number): void {
    const ahead = obstacle.distance - distance;
    let x = LANE_X[obstacle.lane];
    if (obstacle.kind === "runner") {
      const progress = smoothstep((1 - ahead / VISIBLE_DISTANCE - 0.28) / 0.68);
      const startX = obstacle.crossingSide < 0 ? -7.2 : 7.2;
      x = startX + (LANE_X[obstacle.lane] - startX) * progress;
      model.rotation.y = obstacle.crossingSide < 0 ? -Math.PI / 2 : Math.PI / 2;
      model.position.y = Math.abs(Math.sin(this.animationSeconds * 10)) * 0.05;
    }
    model.position.x = x;
    model.position.z = -obstacle.distance * WORLD_PER_METER;
  }

  private updatePedestrians(distance: number): void {
    const visible = visiblePedestrians(distance);
    const active = new Set(visible.map((entry) => entry.id));
    this.pedestrianModels.forEach((model, id) => {
      if (active.has(id)) return;
      this.scene.remove(model.group);
      disposeObject(model.group);
      this.pedestrianModels.delete(id);
    });
    visible.forEach((pedestrian) => {
      let model = this.pedestrianModels.get(pedestrian.id);
      if (!model) {
        model = buildPerson(pedestrian.kind, hashString(pedestrian.id));
        this.pedestrianModels.set(pedestrian.id, model);
        this.scene.add(model.group);
      }
      this.placePedestrian(model, pedestrian);
    });
  }

  private placePedestrian(model: PedestrianModel, pedestrian: ChasePedestrian): void {
    const seed = hashString(pedestrian.id);
    const sameDirection = (seed & 1) === 0;
    const direction = sameDirection ? -1 : 1;
    const walkRange = 3.8;
    const phase = (this.animationSeconds * 0.68 + pedestrian.phase * 1.9 + (seed % 13) * 0.17) % walkRange;
    const walkOffset = (phase - walkRange / 2) * direction;
    const sidewalkX = pedestrian.side * (6.45 + pedestrian.laneOffset * 1.45);
    model.group.position.set(sidewalkX, 0.04, -pedestrian.distance * WORLD_PER_METER + walkOffset);
    model.group.rotation.y = direction < 0 ? 0 : Math.PI;
    animateChasePedestrian(model, this.animationSeconds * 5.7 + pedestrian.phase * Math.PI, this.reducedMotion);
  }

  private updateCamera(playerZ: number, deltaSeconds: number, state: ChaseRenderState): void {
    const targetCameraX = this.rider.group.position.x * 0.34 + 1.7;
    const cameraEase = this.reducedMotion ? 1 : frameResponse(CAMERA_FOLLOW_RESPONSE, deltaSeconds);
    this.camera.position.x += (targetCameraX - this.camera.position.x) * cameraEase;
    const speed = clamp((state.distance + 70) / GOAL_DISTANCE, 0, 1);
    const targetFov = this.reducedMotion ? 53 : 53 + speed * 5 + ((state.boostSeconds??0)>0?7:0);
    this.camera.fov += (targetFov - this.camera.fov) * cameraEase;
    this.camera.updateProjectionMatrix();
    const bob = this.reducedMotion ? 0 : Math.sin(this.animationSeconds * (7 + speed * 3)) * 0.012;
    this.camera.position.set(
      this.camera.position.x,
      3.85 + bob + (state.airHeight??0)*.35,
      playerZ + PLAYER_CAMERA_GAP
    );
    this.camera.lookAt(this.rider.group.position.x * 0.46, 1.1, playerZ - PLAYER_LOOK_AHEAD);
  }
}
