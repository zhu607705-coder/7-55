import * as THREE from "three";
import { ThreePrimitiveCache, type ThreeFlatMaterial } from "../ThreePrimitiveCache";
import { createChasePedestrian } from "./ChasePeople";
import { createChaseTransitionEnvironment } from "./ChaseCampusEnvironment";
import { syncChaseHumanToRider } from "./ChaseHumanPose";
import {
  applyChaseRiderPose,
  createChaseRiderRig,
  DEFAULT_CHASE_RIDER_RIG_PALETTE,
  measureChaseRiderContactError,
  measureChaseRiderRigComplexity,
  type ChaseRiderRig
} from "./ChaseRiderRig";
import {
  clampCanteenBikeTransitionFrame,
  getCanteenBikeTransitionCamera,
  getCanteenBikeTransitionEvents,
  getCanteenBikeTransitionLastFrame,
  getCanteenBikeTransitionPose,
  getCanteenBikeTransitionSegment,
  type CanteenBikeTransitionCameraShot,
  type CanteenBikeTransitionStage
} from "./CanteenBikeTransitionTimeline";

const LOGICAL_WIDTH = 960;
const LOGICAL_HEIGHT = 540;
const DEFAULT_TONE_MAPPING_EXPOSURE = 1.02;

const PALETTE = Object.freeze({
  sky: 0xc5dbe0,
  fog: 0xdce6df,
  grass: 0x6f9755,
  grassDark: 0x426d3f,
  road: 0x494a46,
  roadEdge: 0xead8a5,
  lane: 0xece2c6,
  pavement: 0xb9ad92,
  pavementLight: 0xd3c7aa,
  canteenBrick: 0xa95843,
  canteenBrickDark: 0x784033,
  canteenGlass: 0x426a77,
  theaterStone: 0xc9c1ad,
  theaterStoneLight: 0xeee5ce,
  theaterStoneShadow: 0xa69f8c,
  theaterFrame: 0xe4dfd0,
  theaterBrick: 0xb97848,
  theaterBrickDark: 0x87523a,
  theaterGlass: 0x284856,
  theaterGlassHighlight: 0x3a718b,
  theaterDark: 0x17272d,
  theaterHedge: 0x4d7738,
  theaterHedgeLight: 0x72a14a,
  lampMetal: 0x26333a,
  lampGlow: 0xf0d486,
  trunk: 0x674a32,
  paper: 0xe9d8a8,
  paperStain: 0x9c6d46,
  white: 0xf1ead7,
  blue: 0x315f9f,
  greenNpc: 0x557d51,
  skin: 0xf6bd86,
  hair: 0x293038,
  outline: 0x17232b,
  metal: 0x68757a,
  amber: 0xe5bd54
});

export interface CanteenBikeTransitionRendererSnapshot {
  stage: CanteenBikeTransitionStage;
  frame: number;
  lastFrame: number;
  segment: string;
  camera: CanteenBikeTransitionCameraShot;
  pose: string;
  poseProgress: number;
  wheelSpeedRatio: number;
  paperVisible: boolean;
  npcVisible: boolean;
  doorOcclusion: number;
  events: readonly string[];
  canvas: { width: number; height: number };
  riderComplexity: { meshes: number; triangles: number; materials: number };
  inspectionView: CanteenBikeTransitionInspectionView | null;
  riderContactError: {
    leftHandToGripWorldUnits: number;
    rightHandToGripWorldUnits: number;
    rightHandToNearGripWorldUnits: number;
    leftFootToPedalWorldUnits: number;
    rightFootToPedalWorldUnits: number;
  };
}

export type CanteenBikeTransitionInspectionView =
  | "hero"
  | "hero_front"
  | "hero_close"
  | "hero_side"
  | "hero_back"
  | "ride_side"
  | "ride_front"
  | "bicycle";

export interface CanteenBikeTransitionRendererOptions {
  /** Debug/anchor capture only. Production callers should keep the default false. */
  preserveDrawingBuffer?: boolean;
  renderWidth?: number;
  renderHeight?: number;
  pixelRatioCap?: number;
  enableCaptureShadows?: boolean;
  shadowMapSize?: 1024 | 2048;
  inspectionView?: CanteenBikeTransitionInspectionView;
  inspectionPedalPhase?: number;
}

function clamp01(value: number): number {
  return Math.max(0, Math.min(1, value));
}

function safeMatchMedia(query: string): boolean {
  return typeof window !== "undefined"
    && typeof window.matchMedia === "function"
    && window.matchMedia(query).matches;
}

function defaultPixelRatioCap(): number {
  return safeMatchMedia("(any-pointer: coarse)") || safeMatchMedia("(max-width: 900px)") ? 1.25 : 1.5;
}

function resolveRenderDimension(value: number | undefined, fallback: number): number {
  if (!Number.isFinite(value)) return fallback;
  return Math.max(1, Math.round(value as number));
}

function hasAncestor(object: THREE.Object3D, ancestor: THREE.Object3D): boolean {
  let current: THREE.Object3D | null = object;
  while (current) {
    if (current === ancestor) return true;
    current = current.parent;
  }
  return false;
}

function material(
  primitives: ThreePrimitiveCache,
  color: number,
  options: { unlit?: boolean; opacity?: number; depthWrite?: boolean } = {}
): ThreeFlatMaterial {
  return primitives.material(color, { shading: "standard", roughness: 0.83, flatShading: false, ...options });
}

function box(
  primitives: ThreePrimitiveCache,
  width: number,
  height: number,
  depth: number,
  color: number,
  x = 0,
  y = 0,
  z = 0,
  unlit = false
): THREE.Mesh {
  const mesh = new THREE.Mesh(
    primitives.box(width, height, depth),
    material(primitives, color, { unlit })
  );
  mesh.position.set(x, y, z);
  return mesh;
}

function plane(
  primitives: ThreePrimitiveCache,
  width: number,
  depth: number,
  color: number,
  x = 0,
  y = 0,
  z = 0,
  unlit = false
): THREE.Mesh {
  const mesh = new THREE.Mesh(
    primitives.plane(width, depth),
    material(primitives, color, { unlit })
  );
  mesh.rotation.x = -Math.PI / 2;
  mesh.position.set(x, y, z);
  return mesh;
}



function buildNpc(
  primitives: ThreePrimitiveCache,
  coatColor: number,
  facingRadians: number
): THREE.Group {
  const group = createChasePedestrian(primitives, "soyMilk", coatColor % 7, coatColor).group;
  group.name = "canteen-transition-native-npc";
  group.rotation.y = facingRadians;
  return group;
}

function buildPaper(primitives: ThreePrimitiveCache): THREE.Group {
  const group = new THREE.Group();
  group.name = "canteen-transition-single-paper";
  const sheet = box(primitives, 0.9, 0.62, 0.055, PALETTE.paper, 0, 0, 0, true);
  sheet.rotation.z = 0.12;
  sheet.add(
    box(primitives, 0.42, 0.06, 0.025, PALETTE.paperStain, -0.12, 0.13, -0.04, true),
    box(primitives, 0.2, 0.16, 0.025, PALETTE.paperStain, 0.22, -0.17, -0.04, true)
  );
  group.add(sheet);
  return group;
}


function disposeScene(root: THREE.Object3D): void {
  const geometries = new Set<THREE.BufferGeometry>();
  const materials = new Set<THREE.Material>();
  root.traverse((child) => {
    child.userData.disposeHuman?.();
    if (!(child instanceof THREE.Mesh)) return;
    geometries.add(child.geometry);
    const entries = Array.isArray(child.material) ? child.material : [child.material];
    entries.forEach((entry) => materials.add(entry));
  });
  geometries.forEach((geometry) => geometry.dispose());
  materials.forEach((entry) => {
    if ("map" in entry && entry.map instanceof THREE.Texture) entry.map.dispose();
    entry.dispose();
  });
}

export class CanteenBikeTransitionRenderer {
  private readonly canvas: HTMLCanvasElement;
  private readonly renderer: THREE.WebGLRenderer;
  private readonly scene = new THREE.Scene();
  private readonly camera = new THREE.PerspectiveCamera(46, LOGICAL_WIDTH / LOGICAL_HEIGHT, 0.1, 180);
  private readonly worldFog = new THREE.Fog(PALETTE.fog, 38, 105);
  private readonly primitives = new ThreePrimitiveCache();
  private readonly rider: ChaseRiderRig;
  private readonly startWorld: THREE.Group;
  private readonly finishWorld: THREE.Group;
  private readonly macroWorld = new THREE.Group();
  private readonly paper: THREE.Group;
  private readonly npcs = new THREE.Group();
  private readonly doorOccluder: THREE.Mesh;
  private readonly hemi = new THREE.HemisphereLight(0xeaf4f1, 0x6e7b65, 2.0);
  private readonly sun: THREE.DirectionalLight;
  private readonly sunTarget = new THREE.Object3D();
  private readonly fill = new THREE.DirectionalLight(0xb3d7e8, 0.38);
  private readonly portraitFill = new THREE.DirectionalLight(0xffd7ba, 0.46);
  private readonly rim = new THREE.DirectionalLight(0xd7e9ff, 0.34);
  private readonly renderWidth: number;
  private readonly renderHeight: number;
  private readonly pixelRatioCap: number;
  private readonly enableCaptureShadows: boolean;
  private readonly shadowMapSize: 1024 | 2048;
  private readonly inspectionView: CanteenBikeTransitionInspectionView | null;
  private readonly inspectionPedalPhase: number;
  private stage: CanteenBikeTransitionStage;
  private frame = 0;
  private destroyed = false;

  constructor(
    canvas: HTMLCanvasElement,
    stage: CanteenBikeTransitionStage = "start",
    options: CanteenBikeTransitionRendererOptions = {}
  ) {
    this.canvas = canvas;
    this.stage = stage;
    this.renderWidth = resolveRenderDimension(options.renderWidth, LOGICAL_WIDTH);
    this.renderHeight = resolveRenderDimension(options.renderHeight, LOGICAL_HEIGHT);
    this.pixelRatioCap = options.pixelRatioCap ?? defaultPixelRatioCap();
    this.enableCaptureShadows = options.enableCaptureShadows ?? false;
    this.shadowMapSize = options.shadowMapSize ?? (this.renderWidth >= 1920 || this.renderHeight >= 1080 ? 2048 : 1024);
    this.inspectionView = options.inspectionView ?? null;
    this.inspectionPedalPhase = options.inspectionPedalPhase ?? 0;
    this.renderer = new THREE.WebGLRenderer({
      canvas,
      alpha: false,
      antialias: true,
      depth: true,
      powerPreference: "high-performance",
      preserveDrawingBuffer: options.preserveDrawingBuffer ?? false,
      stencil: false
    });
    this.applyRenderSizing();
    this.renderer.outputColorSpace = THREE.SRGBColorSpace;
    this.renderer.toneMapping = THREE.ACESFilmicToneMapping;
    this.renderer.toneMappingExposure = DEFAULT_TONE_MAPPING_EXPOSURE;
    this.renderer.shadowMap.enabled = this.enableCaptureShadows;
    this.renderer.shadowMap.type = THREE.PCFShadowMap;
    this.scene.background = new THREE.Color(PALETTE.sky);
    this.scene.fog = this.worldFog;
    this.scene.add(this.hemi);
    this.sun = new THREE.DirectionalLight(0xffecd3, 2.4);
    this.sun.position.set(8, 14, 7);
    this.sun.target = this.sunTarget;
    this.scene.add(this.sunTarget, this.sun);
    this.fill.position.set(-9, 6, -7);
    this.portraitFill.position.set(0, 4.5, -8);
    this.rim.position.set(-4, 9, 11);
    this.scene.add(this.fill, this.portraitFill, this.rim);

    this.startWorld = createChaseTransitionEnvironment(this.primitives, "start");
    this.finishWorld = createChaseTransitionEnvironment(this.primitives, "finish");
    this.macroWorld.name = "canteen-transition-neutral-macro-world";
    this.macroWorld.add(
      plane(this.primitives, 28, 28, 0x6f7872, 0, -0.025, -2)
    );
    this.scene.add(this.startWorld, this.finishWorld, this.macroWorld);

    this.rider = createChaseRiderRig(this.primitives, DEFAULT_CHASE_RIDER_RIG_PALETTE);
    this.scene.add(this.rider.root);
    this.paper = buildPaper(this.primitives);
    this.scene.add(this.paper);

    const whiteNpc = buildNpc(this.primitives, PALETTE.white, Math.PI);
    whiteNpc.position.set(-7.1, 0.02, -7.5);
    const greenNpc = buildNpc(this.primitives, PALETTE.greenNpc, 0);
    greenNpc.position.set(7.2, 0.02, -11.5);
    this.npcs.add(whiteNpc, greenNpc);
    this.scene.add(this.npcs);

    this.scene.add(this.camera);
    this.doorOccluder = new THREE.Mesh(
      this.primitives.plane(4.2, 2.5),
      material(this.primitives, PALETTE.theaterDark, { unlit: true })
    );
    this.doorOccluder.name = "canteen-transition-theater-door-occluder";
    this.doorOccluder.position.set(3.4, 0, -0.5);
    this.doorOccluder.renderOrder = 100;
    this.camera.add(this.doorOccluder);
    this.configureCaptureShadows();
    this.renderFrame(0);
    this.rider.human.onReady = () => {
      if (!this.destroyed) this.renderFrame(this.frame);
    };
  }

  setStage(stage: CanteenBikeTransitionStage): void {
    if (this.stage === stage) return;
    this.stage = stage;
    this.frame = 0;
    this.renderFrame(0);
  }

  getStage(): CanteenBikeTransitionStage {
    return this.stage;
  }

  getFrame(): number {
    return this.frame;
  }

  getAssetState(): "loading" | "ready" | "error" {
    return this.rider.human.error ? "error" : this.rider.human.ready ? "ready" : "loading";
  }

  resizeViewport(): void {
    this.applyRenderSizing();
    this.renderFrame(this.frame);
  }

  renderFrame(frame: number): void {
    if (this.destroyed) return;
    this.frame = clampCanteenBikeTransitionFrame(this.stage, frame);
    const pose = getCanteenBikeTransitionPose(this.stage, this.frame);
    const camera = getCanteenBikeTransitionCamera(this.stage, this.frame);

    applyChaseRiderPose(this.rider, pose.pose, {
      progress: pose.poseProgress,
      pedalPhaseRadians: pose.pedalPhaseRadians,
      steeringRadians: 0
    });
    this.rider.root.position.set(pose.rootX, pose.rootY, pose.rootZ);
    this.rider.bicycleRoot.position.x += pose.bicycleOffsetX;
    this.rider.bicycleRoot.position.z += pose.bicycleOffsetZ;
    this.rider.riderRoot.position.x += pose.riderOffsetX;
    this.rider.riderRoot.position.z += pose.riderOffsetZ;
    this.rider.wheels.forEach((wheel) => { wheel.rotation.x = pose.wheelRotationRadians; });
    syncChaseHumanToRider(this.rider);

    const macroShot = camera.shot === "grip_pedal_macro" || camera.shot === "brake_wheel_macro";
    this.applyShotEnvironment(macroShot);
    this.startWorld.visible = this.stage === "start" && !macroShot;
    this.finishWorld.visible = this.stage === "finish" && !macroShot;
    this.macroWorld.visible = macroShot;
    this.macroWorld.children.forEach((child) => { child.visible = true; });
    this.paper.position.set(pose.paperX, pose.paperY, pose.paperZ);
    this.paper.rotation.y = Math.sin(this.frame * 0.19) * 0.26;
    this.paper.rotation.z = Math.sin(this.frame * 0.27) * 0.12;
    this.paper.visible = pose.paperVisible;
    this.npcs.visible = pose.npcVisible;
    this.setRigVisibilityForShot(camera.shot);

    this.camera.position.set(...camera.position);
    this.camera.fov = camera.fov;
    this.camera.aspect = this.renderWidth / this.renderHeight;
    this.camera.updateProjectionMatrix();
    if (macroShot) this.applyMacroCamera(camera.shot);
    else this.camera.lookAt(...camera.lookAt);
    this.doorOccluder.visible = pose.doorOcclusion > 0;
    this.doorOccluder.position.x = 3.4 * (1 - clamp01(pose.doorOcclusion));

    if (this.inspectionView) this.applyInspectionView();

    this.canvas.dataset.transitionStage = this.stage;
    this.canvas.dataset.transitionFrame = String(this.frame);
    this.canvas.dataset.transitionSegment = getCanteenBikeTransitionSegment(this.stage, this.frame).id;
    this.canvas.dataset.transitionCamera = camera.shot;
    this.canvas.dataset.transitionPose = pose.pose;
    this.canvas.dataset.transitionWheelSpeed = pose.wheelSpeedRatio.toFixed(3);
    this.canvas.dataset.chaseHumanState = this.getAssetState();
    this.canvas.dataset.chaseHumanContactErrors = JSON.stringify(this.rider.human.group.userData.contactErrors);
    this.renderer.render(this.scene, this.camera);
  }

  getSnapshot(): CanteenBikeTransitionRendererSnapshot {
    const pose = getCanteenBikeTransitionPose(this.stage, this.frame);
    const camera = getCanteenBikeTransitionCamera(this.stage, this.frame);
    const contactError = measureChaseRiderContactError(this.rider);
    return {
      stage: this.stage,
      frame: this.frame,
      lastFrame: getCanteenBikeTransitionLastFrame(this.stage),
      segment: getCanteenBikeTransitionSegment(this.stage, this.frame).id,
      camera: camera.shot,
      pose: pose.pose,
      poseProgress: Number(pose.poseProgress.toFixed(4)),
      wheelSpeedRatio: Number(pose.wheelSpeedRatio.toFixed(4)),
      paperVisible: pose.paperVisible,
      npcVisible: pose.npcVisible,
      doorOcclusion: Number(pose.doorOcclusion.toFixed(4)),
      events: getCanteenBikeTransitionEvents(this.stage, this.frame),
      canvas: { width: this.canvas.width, height: this.canvas.height },
      riderComplexity: measureChaseRiderRigComplexity(this.rider),
      inspectionView: this.inspectionView,
      riderContactError: {
        leftHandToGripWorldUnits: Number(contactError.leftHandToGripWorldUnits.toFixed(6)),
        rightHandToGripWorldUnits: Number(contactError.rightHandToGripWorldUnits.toFixed(6)),
        rightHandToNearGripWorldUnits: Number(contactError.rightHandToNearGripWorldUnits.toFixed(6)),
        leftFootToPedalWorldUnits: Number(contactError.leftFootToPedalWorldUnits.toFixed(6)),
        rightFootToPedalWorldUnits: Number(contactError.rightFootToPedalWorldUnits.toFixed(6))
      }
    };
  }

  destroy(): void {
    if (this.destroyed) return;
    this.destroyed = true;
    disposeScene(this.scene);
    this.renderer.resetState();
    this.renderer.dispose();
  }

  private applyRenderSizing(): void {
    const exactCanvasSize = this.renderWidth !== LOGICAL_WIDTH || this.renderHeight !== LOGICAL_HEIGHT;
    const pixelRatio = exactCanvasSize ? 1 : Math.min(window.devicePixelRatio || 1, this.pixelRatioCap);
    this.renderer.setPixelRatio(pixelRatio);
    this.renderer.setSize(this.renderWidth, this.renderHeight, false);
    this.camera.aspect = this.renderWidth / this.renderHeight;
    this.camera.updateProjectionMatrix();
  }

  private configureCaptureShadows(): void {
    this.sun.castShadow = this.enableCaptureShadows;
    this.sun.intensity = 2.4;
    this.fill.intensity = this.enableCaptureShadows ? 0.58 : 0.38;
    this.portraitFill.intensity = this.enableCaptureShadows ? 0.56 : 0.46;
    this.hemi.intensity = 2.0;
    this.sun.shadow.mapSize.set(this.shadowMapSize, this.shadowMapSize);
    this.sun.shadow.camera.near = 0.5;
    this.sun.shadow.camera.far = 52;
    this.sun.shadow.camera.left = -18;
    this.sun.shadow.camera.right = 18;
    this.sun.shadow.camera.top = 18;
    this.sun.shadow.camera.bottom = -18;
    this.sun.shadow.bias = -0.00018;
    this.sun.shadow.normalBias = 0.015;
    this.sun.shadow.radius = 2.4;
    this.sunTarget.position.set(0, 1.2, -8);
    this.sun.target.updateMatrixWorld();
    this.scene.traverse((object) => {
      if (!(object instanceof THREE.Mesh)) return;
      if (object === this.doorOccluder) {
        object.castShadow = false;
        object.receiveShadow = false;
        return;
      }
      const isGroundLike = object.rotation.x === -Math.PI / 2 || object.position.y <= 0.12;
      object.castShadow = this.enableCaptureShadows && hasAncestor(object, this.rider.root) && object.name !== "canteen-chase-rider-shadow";
      object.receiveShadow = this.enableCaptureShadows && isGroundLike;
    });
  }

  private setRigVisibilityForShot(shot: CanteenBikeTransitionCameraShot): void {
    this.rider.root.traverse((object) => { object.visible = true; });
    const rootShadow = this.rider.root.children.find((child) => child.name === "canteen-chase-rider-shadow");
    const isGripMacro = shot === "grip_pedal_macro";
    const isBrakeMacro = shot === "brake_wheel_macro";
    if (this.enableCaptureShadows && rootShadow) rootShadow.visible = false;
    if (!isGripMacro && !isBrakeMacro) return;

    if (rootShadow) rootShadow.visible = false;

    // Macro anchors use an explicit mesh whitelist. Keeping the hierarchy
    // visible preserves the authored IK transforms while preventing a parent
    // group from pulling the face, torso or a second limb back into frame.
    this.setMeshVisibility(this.rider.riderRoot, false);
    this.setMeshVisibility(this.rider.bicycleRoot, false);
    this.showHandAndCuff(this.rider.rightForearm, this.rider.rightHand);
    this.setMeshVisibility(this.rider.rightGrip, true);

    // Detail shots use the actual frame and transmission from the ride.
    this.setMeshVisibility(this.rider.bicycleRoot, true);
    if (isGripMacro) {
      this.setMeshVisibility(this.rider.rightFoot, true);
      this.showDirectMeshes(this.rider.crank);
      this.setMeshVisibility(this.rider.rightPedal, true);
      this.setMeshVisibility(this.rider.chain, true);
    } else {
      this.setMeshVisibility(this.rider.frontWheel, true);
      this.setMeshVisibility(this.rider.rightBrakeLever, true);
    }
  }

  private setMeshVisibility(root: THREE.Object3D, visible: boolean): void {
    root.traverse((object) => {
      if (object instanceof THREE.Mesh) object.visible = visible;
    });
  }

  private showDirectMeshes(root: THREE.Object3D): void {
    root.children.forEach((child) => {
      if (child instanceof THREE.Mesh) child.visible = true;
    });
  }

  private showHandAndCuff(forearm: THREE.Group, hand: THREE.Object3D): void {
    const directForearmMeshes = forearm.children.filter((child): child is THREE.Mesh => child instanceof THREE.Mesh);
    const cuff = directForearmMeshes.at(-1);
    if (cuff) cuff.visible = true;
    this.setMeshVisibility(hand, true);
  }

  private applyShotEnvironment(macroShot: boolean): void {
    if (this.inspectionView) return;
    this.scene.background = new THREE.Color(macroShot ? 0x9ca9ac : PALETTE.sky);
    this.scene.fog = macroShot ? null : this.worldFog;
    this.renderer.toneMappingExposure = macroShot ? 1.1 : DEFAULT_TONE_MAPPING_EXPOSURE;
    this.sun.intensity = macroShot ? 1.8 : 2.4;
    this.fill.intensity = macroShot ? 0.68 : this.enableCaptureShadows ? 0.58 : 0.38;
    this.portraitFill.intensity = macroShot ? 0.66 : this.enableCaptureShadows ? 0.56 : 0.46;
    this.hemi.intensity = 2.0;
  }

  private applyMacroCamera(shot: CanteenBikeTransitionCameraShot): void {
    if (shot === "grip_pedal_macro") {
      this.camera.position.set(4.6, 1.78, 0.2);
      this.camera.fov = 20;
      this.camera.lookAt(0.18, 1.2, -0.04);
    } else {
      this.camera.position.set(3.15, 1.9, 0.48);
      this.camera.fov = 18;
      this.camera.lookAt(0.28, 1.26, -0.96);
    }
    this.camera.updateProjectionMatrix();
  }

  private applyInspectionView(): void {
    const inspectionView = this.inspectionView;
    if (!inspectionView) return;
    // Inspection captures are presentation evidence for the character and bike.
    // Keep a neutral studio field so environment props do not distort the
    // silhouette or make material/lighting comparisons harder to read.
    this.scene.background = new THREE.Color(0x98a6ac);
    this.scene.fog = null;
    this.renderer.toneMappingExposure = 1.08;
    this.sun.intensity = 1.42;
    this.fill.intensity = 0.64;
    this.portraitFill.intensity = 0.72;
    this.rim.intensity = 0.5;
    applyChaseRiderPose(this.rider, "stand_left", { progress: 1 });
    this.rider.root.position.set(0, 0.08, 0);
    this.rider.root.rotation.set(0, 0, 0);
    this.rider.leftArm.rotation.set(0, 0, -0.035);
    this.rider.rightArm.rotation.set(0, 0, 0.035);
    this.rider.leftLeg.rotation.set(0, 0, 0);
    this.rider.rightLeg.rotation.set(0, 0, 0);
    syncChaseHumanToRider(this.rider);
    this.rider.root.traverse((object) => { object.visible = true; });
    const rootShadow = this.rider.root.children.find((child) => child.name === "canteen-chase-rider-shadow");
    if (rootShadow) rootShadow.visible = !this.enableCaptureShadows;
    this.startWorld.visible = false;
    this.finishWorld.visible = false;
    this.macroWorld.visible = true;
    this.macroWorld.children.forEach((child, index) => {
      child.visible = index === 0;
    });
    const neutralGround = this.macroWorld.children[0];
    if (neutralGround instanceof THREE.Mesh) {
      const materials = Array.isArray(neutralGround.material)
        ? neutralGround.material
        : [neutralGround.material];
      materials.forEach((entry) => {
        if (
          entry instanceof THREE.MeshStandardMaterial
          || entry instanceof THREE.MeshLambertMaterial
          || entry instanceof THREE.MeshBasicMaterial
        ) {
          entry.color.setHex(0x98a6ac);
        }
      });
    }
    this.paper.visible = false;
    this.npcs.visible = false;
    this.doorOccluder.visible = false;
    if (inspectionView.startsWith("ride")) {
      applyChaseRiderPose(this.rider, "ride", { pedalPhaseRadians: this.inspectionPedalPhase });
      this.rider.root.position.set(0, 0.08, 0);
      syncChaseHumanToRider(this.rider);
      this.rider.bicycleRoot.visible = true;
      this.camera.position.set(inspectionView === "ride_side" ? 7.5 : 0, 2.2, inspectionView === "ride_side" ? 0.05 : -8);
      this.camera.lookAt(0, 1.65, 0);
      this.camera.fov = 32;
    } else if (inspectionView.startsWith("hero")) {
      this.rider.bicycleRoot.visible = false;
      this.rider.riderRoot.visible = true;
      this.camera.fov = 29;
      if (inspectionView === "hero_close") {
        this.camera.position.set(1.4, 2.5, -5);
      } else if (inspectionView === "hero_front") {
        this.camera.position.set(-0.58, 2.15, -7);
      } else if (inspectionView === "hero_side") {
        this.camera.position.set(6.45, 2.15, 0.02);
      } else if (inspectionView === "hero_back") {
        this.camera.position.set(-0.58, 2.15, 7);
      } else {
        this.camera.position.set(4.1, 2.55, -6.5);
      }
      if (inspectionView === "hero_close") this.camera.lookAt(-0.58, 2.05, 0.02);
      else this.camera.lookAt(-0.58, 1.65, 0.02);
    } else {
      this.rider.bicycleRoot.visible = true;
      this.rider.riderRoot.visible = false;
      this.rider.human.group.visible = false;
      this.camera.position.set(4.65, 1.9, -4.55);
      this.camera.lookAt(0, 0.82, 0.02);
      this.camera.fov = 30;
    }
    this.camera.updateProjectionMatrix();
    this.canvas.dataset.transitionInspection = inspectionView;
    this.renderer.render(this.scene, this.camera);
  }
}
