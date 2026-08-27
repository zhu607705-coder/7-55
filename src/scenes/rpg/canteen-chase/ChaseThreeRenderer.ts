import * as THREE from "three";
import { mergeGeometries } from "three/examples/jsm/utils/BufferGeometryUtils.js";
import {
  visibleObstacles,
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
  CHASE_RIDER_WHEEL_RADIUS,
  createChaseRiderRig,
  measureChaseRiderContactError,
  measureChaseRiderFootOrientationError,
  measureChaseRiderRigComplexity,
  type ChaseRiderRig
} from "./ChaseRiderRig";
import { ThreePrimitiveCache, type ThreeFlatMaterial } from "../ThreePrimitiveCache";

const LOGICAL_WIDTH = 960;
const LOGICAL_HEIGHT = 540;
const GOAL_DISTANCE = 755;
const WORLD_PER_METER = 0.22;
const ROAD_HALF_WIDTH = 5.55;
const LANE_X = [-3.35, 0, 3.35] as const;
const PLAYER_CAMERA_GAP = 8.45;
const PLAYER_LOOK_AHEAD = 12.8;
const PLAYER_BASE_Y = 0.08;
const DESTINATION_Z = -GOAL_DISTANCE * WORLD_PER_METER - 8;
const DEFAULT_TONE_MAPPING_EXPOSURE = 1.02;
const MAX_PEDAL_CADENCE_RPM = 110;
const PEDAL_CADENCE_RESPONSE = 10;
const SEATED_PEDAL_BOB_AMPLITUDE = 0.008;
const TWO_PI = Math.PI * 2;

const PALETTE = {
  sky: 0x89bcdc,
  fog: 0xa9c8d6,
  grass: 0x6f9852,
  grassDark: 0x4e713f,
  water: 0x397f96,
  waterLight: 0x6fb8bd,
  road: 0x464640,
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

interface PedestrianModel {
  group: THREE.Group;
  leftLeg: THREE.Group;
  rightLeg: THREE.Group;
  leftArm: THREE.Group;
  rightArm: THREE.Group;
  pair?: PedestrianModel;
}

function clamp(value: number, minimum: number, maximum: number): number {
  return Math.max(minimum, Math.min(maximum, value));
}

function safeMatchMedia(query: string): boolean {
  return typeof window !== "undefined"
    && typeof window.matchMedia === "function"
    && window.matchMedia(query).matches;
}

function defaultPixelRatioCap(): number {
  return safeMatchMedia("(any-pointer: coarse)") || safeMatchMedia("(max-width: 900px)") ? 1.25 : 1.5;
}

function smoothstep(value: number): number {
  const t = clamp(value, 0, 1);
  return t * t * (3 - 2 * t);
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
  return CHASE_PRIMITIVES.material(color, { unlit });
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
  const shirtPalette = [PALETTE.blue, PALETTE.red, 0x6e65a0, 0x4c8461, 0xb37447] as const;
  const shirt = shirtPalette[seed % shirtPalette.length];
  const group = new THREE.Group();
  group.add(blobShadow(kind === "chattingPair" ? 1.3 : 0.7, 0.55));
  const torso = box(0.5, 0.78, 0.34, shirt, 0, 1.22, 0);
  const head = box(0.38, 0.42, 0.36, PALETTE.skin, 0, 1.84, -0.02);
  const hair = box(0.42, 0.16, 0.4, PALETTE.hair, 0, 2.05, -0.02);
  group.add(torso, head, hair);
  const leftLeg = new THREE.Group();
  const rightLeg = new THREE.Group();
  leftLeg.position.set(-0.14, 0.88, 0);
  rightLeg.position.set(0.14, 0.88, 0);
  leftLeg.add(box(0.18, 0.72, 0.2, PALETTE.outline, 0, -0.34, 0));
  rightLeg.add(box(0.18, 0.72, 0.2, PALETTE.outline, 0, -0.34, 0));
  group.add(leftLeg, rightLeg);
  const leftArm = new THREE.Group();
  const rightArm = new THREE.Group();
  leftArm.position.set(-0.34, 1.5, 0);
  rightArm.position.set(0.34, 1.5, 0);
  leftArm.add(box(0.14, 0.62, 0.16, shirt, 0, -0.28, 0));
  rightArm.add(box(0.14, 0.62, 0.16, shirt, 0, -0.28, 0));
  group.add(leftArm, rightArm);

  if (kind === "phoneWalker") {
    const phone = box(0.22, 0.34, 0.08, PALETTE.outline, 0, 1.38, -0.32);
    phone.add(box(0.14, 0.22, 0.02, PALETTE.cyan, 0, 0, -0.052, true));
    group.add(phone);
    leftArm.rotation.x = -0.75;
    rightArm.rotation.x = -0.75;
  } else if (kind === "soyMilk") {
    const cup = box(0.2, 0.34, 0.2, PALETTE.white, 0.42, 1.3, -0.18);
    cup.add(box(0.06, 0.3, 0.06, PALETTE.red, 0, 0.27, 0));
    group.add(cup);
    rightArm.rotation.z = 0.48;
  } else if (kind === "bikePusher") {
    const bicycle = buildSimpleBicycle(PALETTE.cyan);
    bicycle.scale.setScalar(0.58);
    bicycle.position.set(0.62, 0, -0.18);
    bicycle.rotation.y = Math.PI;
    group.add(bicycle);
    rightArm.rotation.z = 0.58;
  }

  const model: PedestrianModel = { group, leftLeg, rightLeg, leftArm, rightArm };
  if (kind === "chattingPair") {
    const pair = buildPerson("phoneWalker", seed + 5);
    pair.group.position.x = 0.64;
    group.position.x = -0.32;
    group.add(pair.group);
    model.pair = pair;
  }
  return model;
}

function buildSimpleBicycle(color: number): THREE.Group {
  const group = new THREE.Group();
  const rear = pixelWheel(0.44);
  rear.position.set(0, 0.46, 0.66);
  const front = pixelWheel(0.44);
  front.position.set(0, 0.46, -0.66);
  group.add(
    rear,
    front,
    box(0.12, 0.12, 1.12, color, 0, 0.68, 0),
    box(0.12, 0.66, 0.12, color, 0, 0.86, 0.36),
    box(0.72, 0.1, 0.1, PALETTE.outline, 0, 1.04, -0.58)
  );
  return group;
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
    const cone = new THREE.Mesh(CHASE_PRIMITIVES.cone(0.45, 1.25, 6), material(PALETTE.orange));
    cone.position.y = 0.7;
    group.add(box(1.05, 0.14, 1.05, PALETTE.outline, 0, 0.07, 0), cone);
    group.add(box(0.64, 0.15, 0.64, PALETTE.white, 0, 0.62, 0));
  } else if (kind === "car") {
    group.add(blobShadow(2.35, 4.1));
    group.add(box(2.15, 0.82, 3.7, PALETTE.red, 0, 0.72, 0));
    group.add(box(1.72, 0.68, 1.9, PALETTE.glass, 0, 1.34, -0.28));
    for (const x of [-1.08, 1.08]) {
      for (const z of [-1.18, 1.18]) {
        const wheel = new THREE.Mesh(CHASE_PRIMITIVES.cylinder(0.38, 0.38, 0.28, 8), material(PALETTE.outline));
        wheel.rotation.z = Math.PI / 2;
        wheel.position.set(x, 0.38, z);
        group.add(wheel);
      }
    }
    group.add(box(0.44, 0.22, 0.08, PALETTE.white, -0.62, 0.72, -1.9, true));
    group.add(box(0.44, 0.22, 0.08, PALETTE.white, 0.62, 0.72, -1.9, true));
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

function buildTree(seed: number): THREE.Group {
  const group = new THREE.Group();
  group.add(blobShadow(2.2, 1.5));
  group.add(box(0.38, 2.7, 0.38, PALETTE.trunk, 0, 1.35, 0));
  const foliageColors = [PALETTE.tree, PALETTE.treeLight, 0x3f7440] as const;
  for (let index = 0; index < 4; index += 1) {
    const crown = new THREE.Mesh(
      CHASE_PRIMITIVES.icosahedron(0.82 + ((seed + index) % 3) * 0.12, 1),
      material(foliageColors[(seed + index) % foliageColors.length])
    );
    crown.position.set((index - 1.5) * 0.38, 2.75 + (index % 2) * 0.45, ((seed + index) % 2) * 0.28);
    group.add(crown);
  }
  return group;
}

function buildLamp(): THREE.Group {
  const group = new THREE.Group();
  group.add(box(0.12, 3.5, 0.12, PALETTE.outline, 0, 1.75, 0));
  group.add(box(0.55, 0.12, 0.12, PALETTE.outline, 0.22, 3.45, 0));
  group.add(box(0.34, 0.3, 0.3, PALETTE.amber, 0.48, 3.32, 0, true));
  return group;
}

function buildCampusBlock(width: number, height: number, depth: number, seed: number): THREE.Group {
  const group = new THREE.Group();
  const wall = seed % 3 === 0 ? PALETTE.cream : PALETTE.brick;
  group.add(box(width, height, depth, wall, 0, height / 2, 0));
  group.add(box(width + 0.28, 0.26, depth + 0.28, PALETTE.creamDark, 0, height + 0.13, 0));
  group.add(box(width * 0.42, height * 0.88, 0.16, PALETTE.cream, 0, height * 0.48, depth / 2 + 0.08));
  group.add(box(width * 0.34, height * 0.72, 0.18, PALETTE.glass, 0, height * 0.48, depth / 2 + 0.18, true));
  const columns = Math.max(2, Math.floor(width / 1.45));
  const rows = Math.max(2, Math.floor(height / 1.25));
  for (let row = 0; row < rows; row += 1) {
    for (let column = 0; column < columns; column += 1) {
      const x = -width / 2 + 0.7 + column * ((width - 1.4) / Math.max(1, columns - 1));
      const y = 0.8 + row * ((height - 1.5) / Math.max(1, rows - 1));
      group.add(box(0.52, 0.52, 0.08, (row + column + seed) % 7 === 0 ? PALETTE.amber : PALETTE.glass, x, y, depth / 2 + 0.05, true));
    }
  }
  for (const side of [-1, 1]) {
    group.add(box(0.28, height + 0.12, 0.26, PALETTE.cream, side * width * 0.29, height / 2, depth / 2 + 0.2));
    group.add(box(1.25, 0.7, 1.1, PALETTE.grassDark, side * width * 0.38, 0.38, depth / 2 + 0.8));
  }
  return group;
}

function buildLakesideHall(seed: number): THREE.Group {
  const group = new THREE.Group();
  const width = 9.2 + (seed % 2) * 1.4;
  group.add(box(width, 4.9, 4.6, PALETTE.theaterStone, 0, 2.45, 0));
  group.add(box(width + 0.55, 0.42, 5.05, PALETTE.theaterRoof, 0, 5.1, 0));
  group.add(box(width * 0.78, 3.35, 0.22, PALETTE.glass, 0, 2.65, 2.44, true));
  for (let x = -width * 0.31; x <= width * 0.31; x += width * 0.155) {
    group.add(box(0.22, 3.75, 0.28, PALETTE.theaterFrame, x, 2.7, 2.62));
  }
  group.add(box(width * 0.28, 2.55, 0.32, PALETTE.outline, 0, 1.85, 2.72));
  group.add(box(width * 0.22, 2.18, 0.16, PALETTE.glassLight, 0, 1.82, 2.91, true));
  return group;
}

function buildLakeRoadside(side: number, centerZ: number, length: number, seed: number): THREE.Group {
  const group = new THREE.Group();
  const water = new THREE.Mesh(CHASE_PRIMITIVES.plane(10.8, length), material(PALETTE.water));
  water.rotation.x = -Math.PI / 2;
  water.position.set(side * 14.3, 0.018, centerZ);
  group.add(water);
  group.add(box(0.48, 0.34, length, PALETTE.theaterStone, side * 8.82, 0.17, centerZ));
  group.add(box(0.72, 0.42, length, PALETTE.grassDark, side * 19.88, 0.18, centerZ));
  for (let row = -1; row <= 1; row += 1) {
    for (let index = 0; index < 8; index += 1) {
      const wave = box(1.25, 0.025, 0.12, PALETTE.waterLight, side * (11.2 + row * 2.4), 0.042, centerZ - length / 2 + 2.3 + index * 3.25, true);
      wave.rotation.y = side * (0.08 + row * 0.03);
      group.add(wave);
    }
  }
  const hall = buildLakesideHall(seed);
  hall.position.set(side * 23.1, 0, centerZ - 1.6);
  hall.rotation.y = side > 0 ? -Math.PI / 2 : Math.PI / 2;
  group.add(hall);
  return group;
}

function buildStoneCampusMarker(): THREE.Group {
  const group = new THREE.Group();
  const marker = box(3.9, 1.35, 0.72, PALETTE.cream, 0, 0.68, 0);
  const face = new THREE.Mesh(
    CHASE_PRIMITIVES.plane(3.45, 0.72),
    new THREE.MeshBasicMaterial({ map: pixelTextTexture("紫金港校区", "#DCCDAE", "#254B67"), toneMapped: false })
  );
  face.position.set(0, 0.75, 0.37);
  group.add(marker, face, box(4.45, 0.18, 1.05, PALETTE.creamDark, 0, 0.09, 0));
  return group;
}

function buildCampusBicycleRack(): THREE.Group {
  const group = new THREE.Group();
  for (let index = -2; index <= 2; index += 1) {
    const bicycle = buildSimpleBicycle(index % 2 === 0 ? PALETTE.cyan : PALETTE.yellow);
    bicycle.scale.setScalar(0.52);
    bicycle.position.set(index * 0.72, 0, (index % 2) * 0.22);
    bicycle.rotation.y = Math.PI / 2;
    group.add(bicycle);
  }
  group.add(box(4.25, 0.12, 0.16, PALETTE.metal, 0, 0.25, 0.42));
  return group;
}

function ellipticalCylinder(
  radiusX: number,
  height: number,
  radiusZ: number,
  color: number,
  y: number,
  z = 0,
  segments = 24
): THREE.Mesh {
  const mesh = new THREE.Mesh(
    CHASE_PRIMITIVES.cylinder(1, 1, height, segments, 1, false),
    material(color)
  );
  mesh.scale.set(radiusX, 1, radiusZ);
  mesh.position.set(0, y, z);
  return mesh;
}

function buildTheaterDestination(): THREE.Group {
  const group = new THREE.Group();
  group.name = "canteen-chase-theater-destination";

  // 剧场：白色椭圆屋顶、弧形蓝玻璃幕墙与正立面白色立柱。
  group.add(ellipticalCylinder(10.35, 0.78, 4.55, PALETTE.theaterRoofShade, 6.58, -0.45));
  group.add(ellipticalCylinder(9.92, 0.62, 4.2, PALETTE.theaterRoof, 7.02, -0.48));
  group.add(ellipticalCylinder(9.35, 4.55, 3.62, PALETTE.glass, 3.56, -0.35));
  group.add(ellipticalCylinder(9.52, 0.38, 3.78, PALETTE.theaterFrame, 5.67, -0.37));
  group.add(ellipticalCylinder(9.42, 0.34, 3.72, PALETTE.theaterFrame, 1.28, -0.34));

  const facadeRadiusX = 9.35;
  const facadeRadiusZ = 3.62;
  for (const x of [-7.25, -5.15, -3.0, 0, 3.0, 5.15, 7.25]) {
    const normalizedX = x / facadeRadiusX;
    const frontZ = -0.35 + facadeRadiusZ * Math.sqrt(Math.max(0, 1 - normalizedX * normalizedX));
    group.add(box(0.48, 4.55, 0.52, PALETTE.theaterFrame, x, 3.55, frontZ + 0.16));
  }

  // 中央入口在弧形幕墙前方，保持从道路正中能够读出真实到达点。
  group.add(box(4.0, 3.3, 0.52, PALETTE.outline, 0, 2.42, 3.64));
  group.add(box(1.68, 2.85, 0.18, PALETTE.glassLight, -0.92, 2.34, 3.94, true));
  group.add(box(1.68, 2.85, 0.18, PALETTE.glassLight, 0.92, 2.34, 3.94, true));
  group.add(box(0.16, 2.85, 0.18, PALETTE.theaterFrame, 0, 2.34, 4.05));
  group.add(box(4.65, 0.34, 0.72, PALETTE.theaterFrame, 0, 4.15, 3.78));

  const signTexture = pixelTextTexture("剧场", "#24323A", "#E7D9A8", 420, 88);
  const sign = new THREE.Mesh(
    CHASE_PRIMITIVES.plane(5.8, 1.22),
    new THREE.MeshBasicMaterial({ map: signTexture, toneMapped: false })
  );
  sign.position.set(5.95, 1.35, 4.58);
  group.add(sign);

  for (let step = 0; step < 4; step += 1) {
    group.add(box(8.8 + step * 1.2, 0.18, 0.96, step % 2 === 0 ? PALETTE.theaterStone : PALETTE.creamDark, 0, 0.09 + step * 0.18, 4.1 + step * 0.46));
  }

  for (const side of [-1, 1]) {
    group.add(box(4.1, 0.78, 1.55, PALETTE.grassDark, side * 7.05, 0.39, 4.38));
    group.add(box(3.62, 0.28, 1.18, PALETTE.treeLight, side * 7.05, 0.88, 4.38));
    const lamp = buildLamp();
    lamp.position.set(side * 9.0, 0, 5.05);
    if (side < 0) lamp.scale.x = -1;
    group.add(lamp);
  }

  // 屋顶边缘与幕墙分格使用低面数硬边块，避免出现写实光滑表面。
  for (let index = -7; index <= 7; index += 1) {
    const x = index * 1.22;
    const normalizedX = x / 9.35;
    const frontZ = -0.35 + facadeRadiusZ * Math.sqrt(Math.max(0, 1 - normalizedX * normalizedX));
    group.add(box(0.08, 3.55, 0.1, PALETTE.outline, x, 3.42, frontZ + 0.2));
  }
  return group;
}

function disposeObject(object: THREE.Object3D): void {
  object.traverse((child) => {
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
  const buckets = new Map<THREE.Material, THREE.BufferGeometry[]>();
  const mergedSources: THREE.Mesh[] = [];
  root.traverse((child) => {
    if (!(child instanceof THREE.Mesh)) return;
    if (Array.isArray(child.material)) return;
    if (!CHASE_PRIMITIVES.ownsGeometry(child.geometry) || !CHASE_PRIMITIVES.ownsMaterial(child.material)) return;
    if (child.material.transparent) return;
    const geometry = child.geometry.index ? child.geometry.toNonIndexed() : child.geometry.clone();
    geometry.applyMatrix4(child.matrixWorld);
    const entries = buckets.get(child.material) ?? [];
    entries.push(geometry);
    buckets.set(child.material, entries);
    mergedSources.push(child);
  });
  mergedSources.forEach((mesh) => mesh.removeFromParent());
  buckets.forEach((geometries, material) => {
    const merged = mergeGeometries(geometries, false);
    geometries.forEach((geometry) => geometry.dispose());
    if (!merged) return;
    root.add(new THREE.Mesh(merged, material));
  });
}

export class ChaseThreeRenderer implements ChaseRendererBackend {
  private readonly canvas: HTMLCanvasElement;
  private readonly renderer: THREE.WebGLRenderer;
  private readonly scene = new THREE.Scene();
  private readonly camera = new THREE.PerspectiveCamera(55, 16 / 9, 0.1, 420);
  private readonly observer: ResizeObserver;
  private readonly rider: ChaseRiderRig;
  private readonly paper = new THREE.Group();
  private readonly obstacleModels = new Map<string, THREE.Group>();
  private readonly pedestrianModels = new Map<string, PedestrianModel>();
  private readonly sun = new THREE.DirectionalLight(0xffedbd, 1.3);
  private readonly sunTarget = new THREE.Object3D();
  private readonly enableLiveShadows = safeMatchMedia("(pointer: fine)") && !safeMatchMedia("(any-pointer: coarse)");
  private reducedMotion = false;
  private lastTime = performance.now();
  private animationSeconds = 0;
  private previousDistance = 0;
  private pedalPhaseRadians = 0;
  private pedalCadenceRpm = 0;
  private previousRiderX = 0;
  private lastCollisions = 0;
  private collisionFlashSeconds = 0;
  private readonly steeringPivot = new THREE.Vector3();
  private readonly steeringTip = new THREE.Vector3();
  private nextDebugSnapshotAt = 0;

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
    this.scene.fog = new THREE.Fog(PALETTE.fog, 38, 126);
    this.scene.add(new THREE.HemisphereLight(0xf2ecd8, 0x4f6747, this.enableLiveShadows ? 1.38 : 1.25));
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
    this.rider = createChaseRiderRig(CHASE_PRIMITIVES, PALETTE);
    this.rider.group.position.set(0, PLAYER_BASE_Y, 0);
    this.scene.add(this.rider.group);
    this.configureHeroShadowState();
    const riderComplexity = measureChaseRiderRigComplexity(this.rider);
    this.canvas.dataset.chaseRiderMeshes = String(riderComplexity.meshes);
    this.canvas.dataset.chaseRiderTriangles = String(riderComplexity.triangles);
    this.canvas.dataset.chaseRiderMaterials = String(riderComplexity.materials);
    this.buildPaper();
    this.scene.add(this.paper);
    this.observer = new ResizeObserver(() => this.handleResize());
    this.observer.observe(canvas);
    this.handleResize();
  }

  destroy(): void {
    this.observer.disconnect();
    disposeObject(this.scene);
    this.renderer.dispose();
  }

  setReducedMotion(reduced: boolean): void {
    this.reducedMotion = reduced;
  }

  render(state: ChaseRenderState): void {
    const now = performance.now();
    const deltaSeconds = clamp((now - this.lastTime) / 1000, 0, 0.08);
    this.lastTime = now;
    if (!state.paused && state.runState === "running" && !this.reducedMotion) {
      this.animationSeconds += deltaSeconds;
    }
    if (state.collisions > this.lastCollisions) this.collisionFlashSeconds = 0.22;
    this.lastCollisions = state.collisions;
    this.collisionFlashSeconds = Math.max(0, this.collisionFlashSeconds - deltaSeconds);

    const playerZ = -state.distance * WORLD_PER_METER;
    const targetX = LANE_X[clamp(Math.round(state.lane), 0, 2)];
    const easing = this.reducedMotion ? 1 : Math.min(1, deltaSeconds * 11);
    this.rider.group.position.x += (targetX - this.rider.group.position.x) * easing;
    this.rider.group.position.z = playerZ;
    const laneVelocity = deltaSeconds > 0 ? (this.rider.group.position.x - this.previousRiderX) / deltaSeconds : 0;
    this.previousRiderX = this.rider.group.position.x;
    const bodySteer = clamp(-laneVelocity * 0.055, -0.42, 0.42);
    const handlebarSteer = bodySteer * 1.32;
    const resolvedHandlebarSteer = this.rider.frontAssembly.rotation.y
      + (handlebarSteer - this.rider.frontAssembly.rotation.y) * Math.min(1, deltaSeconds * 16);
    this.rider.group.rotation.z += (bodySteer * 0.45 - this.rider.group.rotation.z) * Math.min(1, deltaSeconds * 12);
    const distanceReset = state.distance + Number.EPSILON < this.previousDistance;
    if (distanceReset) {
      this.pedalPhaseRadians = 0;
      this.pedalCadenceRpm = 0;
      this.rider.wheels.forEach((wheel) => { wheel.rotation.x = 0; });
    }
    const distanceDelta = Math.max(0, state.distance - this.previousDistance);
    this.previousDistance = state.distance;
    const wheelSpin = distanceDelta * WORLD_PER_METER / CHASE_RIDER_WHEEL_RADIUS;
    const crankDelta = wheelSpin / CHASE_RIDER_GEAR_RATIO;
    const pedalsCanAdvance = !state.paused && !this.reducedMotion && distanceDelta > 0;
    if (pedalsCanAdvance) {
      this.pedalPhaseRadians = (this.pedalPhaseRadians + crankDelta) % TWO_PI;
    }
    const targetCadenceRpm = pedalsCanAdvance && deltaSeconds > 0
      ? clamp((crankDelta / deltaSeconds) * (60 / TWO_PI), 0, MAX_PEDAL_CADENCE_RPM)
      : 0;
    this.pedalCadenceRpm += (targetCadenceRpm - this.pedalCadenceRpm)
      * Math.min(1, deltaSeconds * PEDAL_CADENCE_RESPONSE);
    const pedalPhase = this.reducedMotion ? 0 : this.pedalPhaseRadians;
    const seatedPedalBob = this.reducedMotion
      ? 0
      : SEATED_PEDAL_BOB_AMPLITUDE * (0.5 - Math.cos(pedalPhase * 2) * 0.5);
    this.rider.group.position.y = PLAYER_BASE_Y + seatedPedalBob;
    applyChaseRiderPose(this.rider, "ride", {
      pedalPhaseRadians: pedalPhase,
      steeringRadians: resolvedHandlebarSteer
    });
    this.rider.wheels.forEach((wheel) => { wheel.rotation.x -= wheelSpin; });

    this.updateObstacles(state.distance);
    this.updatePedestrians(state.distance);
    this.updatePaper(state.distance);
    this.updateShadowRig(playerZ);
    this.updateCamera(playerZ, laneVelocity, deltaSeconds, state);
    const steeringPivot = this.rider.frontAssembly.localToWorld(this.steeringPivot.set(0, 0, 0)).project(this.camera);
    const steeringTip = this.rider.frontAssembly.localToWorld(this.steeringTip.set(0, 0, -1)).project(this.camera);
    const background = this.scene.background;
    if (background instanceof THREE.Color) {
      background.setHex(this.collisionFlashSeconds > 0 ? 0xb86868 : PALETTE.sky);
    }
    this.renderer.render(this.scene, this.camera);
    if (now >= this.nextDebugSnapshotAt) {
      this.nextDebugSnapshotAt = now + 100;
      this.canvas.dataset.chaseSteer = bodySteer.toFixed(3);
      this.canvas.dataset.chaseHandlebarSteer = this.rider.frontAssembly.rotation.y.toFixed(3);
      this.canvas.dataset.chaseHandlebarScreenDx = (steeringTip.x - steeringPivot.x).toFixed(3);
      this.canvas.dataset.chaseDrawCalls = String(this.renderer.info.render.calls);
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
    this.renderer.setPixelRatio(Math.min(window.devicePixelRatio || 1, defaultPixelRatioCap()));
    this.renderer.setSize(width, height, false);
    this.camera.aspect = width / height;
    this.camera.updateProjectionMatrix();
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
    this.sun.shadow.normalBias = 0.018;
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
    const staticWorld = new THREE.Group();
    staticWorld.name = "canteen-chase-static-world";
    const routeLength = GOAL_DISTANCE * WORLD_PER_METER + 86;
    const routeCenter = -(GOAL_DISTANCE * WORLD_PER_METER) / 2 + 4;
    const grass = new THREE.Mesh(CHASE_PRIMITIVES.plane(72, routeLength), material(PALETTE.grass));
    grass.rotation.x = -Math.PI / 2;
    grass.position.set(0, -0.03, routeCenter);
    staticWorld.add(grass);
    const road = new THREE.Mesh(CHASE_PRIMITIVES.plane(ROAD_HALF_WIDTH * 2, routeLength), material(PALETTE.road));
    road.rotation.x = -Math.PI / 2;
    road.position.set(0, 0, routeCenter);
    staticWorld.add(road);
    for (const side of [-1, 1]) {
      const sidewalk = new THREE.Mesh(CHASE_PRIMITIVES.plane(2.7, routeLength), material(PALETTE.pavement));
      sidewalk.rotation.x = -Math.PI / 2;
      sidewalk.position.set(side * (ROAD_HALF_WIDTH + 1.42), 0.012, routeCenter);
      staticWorld.add(sidewalk);
      const curb = box(0.22, 0.2, routeLength, PALETTE.pavementLight, side * (ROAD_HALF_WIDTH + 0.11), 0.1, routeCenter);
      staticWorld.add(curb);
      const edge = new THREE.Mesh(CHASE_PRIMITIVES.plane(0.13, routeLength), material(PALETTE.roadEdge, true));
      edge.rotation.x = -Math.PI / 2;
      edge.position.set(side * (ROAD_HALF_WIDTH - 0.18), 0.025, routeCenter);
      staticWorld.add(edge);
    }
    for (const x of [-ROAD_HALF_WIDTH / 3, ROAD_HALF_WIDTH / 3]) {
      for (let z = 20; z > -routeLength + 20; z -= 5.8) {
        const dash = new THREE.Mesh(CHASE_PRIMITIVES.plane(0.2, 2.9), material(PALETTE.lane, true));
        dash.rotation.x = -Math.PI / 2;
        dash.position.set(x, 0.028, z);
        staticWorld.add(dash);
      }
    }

    // 路线按草坪树阵、校园楼群与启真湖水岸三类路段交替，避免两侧重复砖楼。
    staticWorld.add(buildLakeRoadside(1, -61, 28, 4));
    staticWorld.add(buildLakeRoadside(-1, -132, 28, 9));

    for (let index = 0; index < 30; index += 1) {
      const z = 11 - index * 6.2;
      const zoneIndex = Math.floor(Math.max(0, -z + 4) / 30);
      const zoneType = zoneIndex % 3;
      const firstLake = z <= -47 && z >= -75;
      const secondLake = z <= -118 && z >= -146;
      const lakeSide = firstLake ? 1 : -1;
      for (const side of [-1, 1]) {
        const seed = index * 7 + (side > 0 ? 3 : 0);
        const isLakeZone = firstLake || secondLake;
        const isWaterEdge = isLakeZone && side === lakeSide;
        if (!isWaterEdge || index % 3 === 0) {
          const tree = buildTree(seed);
          tree.position.set(side * (isWaterEdge ? 20.5 : 9.2 + (seed % 3) * 0.55), 0, z - (seed % 4) * 0.7);
          staticWorld.add(tree);
        }
        if (index % 2 === 0) {
          const lamp = buildLamp();
          lamp.position.set(side * 6.45, 0, z - 2.7);
          if (side < 0) lamp.scale.x = -1;
          staticWorld.add(lamp);
        }
        if (!isLakeZone && zoneType === 1 && index % 3 === 1) {
          const width = 7 + (seed % 3) * 1.6;
          const height = 4.8 + (seed % 4) * 0.8;
          const building = buildCampusBlock(width, height, 5.2, seed);
          building.position.set(side * (14.2 + width * 0.34), 0, z - 1.5);
          if (side < 0) building.rotation.y = Math.PI;
          staticWorld.add(building);
        } else if (isLakeZone && side !== lakeSide && index % 4 === 1) {
          const hall = buildLakesideHall(seed);
          hall.position.set(side * 16.8, 0, z - 1.2);
          hall.rotation.y = side > 0 ? -Math.PI / 2 : Math.PI / 2;
          staticWorld.add(hall);
        }
      }
    }

    const campusMarker = buildStoneCampusMarker();
    campusMarker.position.set(-8.05, 0, -16);
    campusMarker.rotation.y = 0.08;
    staticWorld.add(campusMarker);

    const qiushiRoadSign = pixelSign("求是路", 3.2);
    qiushiRoadSign.position.set(7.25, 0, -42);
    qiushiRoadSign.rotation.y = -0.08;
    staticWorld.add(qiushiRoadSign);

    const theaterGuideSign = pixelSign("剧场 →", 5.2, "#244A66");
    theaterGuideSign.position.set(-7.55, 0, -103);
    theaterGuideSign.rotation.y = 0.08;
    staticWorld.add(theaterGuideSign);

    const firstRack = buildCampusBicycleRack();
    firstRack.position.set(8.35, 0.02, -28);
    staticWorld.add(firstRack);
    const secondRack = buildCampusBicycleRack();
    secondRack.position.set(-8.35, 0.02, -118);
    secondRack.rotation.y = Math.PI;
    staticWorld.add(secondRack);

    for (const z of [-70, -139]) {
      for (const side of [-1, 1]) {
        const hedge = box(4.4, 0.72, 1.35, PALETTE.grassDark, side * 8.7, 0.36, z);
        hedge.add(box(4.0, 0.3, 1.0, PALETTE.treeLight, 0, 0.42, 0));
        staticWorld.add(hedge);
      }
    }

    const destination = buildTheaterDestination();
    destination.position.set(0, 0, DESTINATION_Z);
    staticWorld.add(destination);
    mergeStaticWorldMeshes(staticWorld);
    if (this.enableLiveShadows) {
      staticWorld.traverse((object) => {
        if (!(object instanceof THREE.Mesh)) return;
        object.castShadow = false;
        object.receiveShadow = true;
      });
    }
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

  private updatePaper(distance: number): void {
    const progress = clamp(distance / GOAL_DISTANCE, 0, 1);
    const ahead = 28 - progress * 15;
    this.paper.position.set(
      Math.sin(this.animationSeconds * 1.7) * (1.6 - progress * 0.8),
      3.25 + Math.sin(this.animationSeconds * 5.2) * 0.28,
      -distance * WORLD_PER_METER - ahead
    );
    this.paper.rotation.y = Math.sin(this.animationSeconds * 3.1) * 0.3;
    this.paper.rotation.z = Math.sin(this.animationSeconds * 4.4) * 0.12;
  }

  private updateObstacles(distance: number): void {
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
    });
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
    const stride = this.reducedMotion ? 0 : Math.sin(this.animationSeconds * 7.4 + pedestrian.phase * Math.PI);
    model.leftLeg.rotation.x = stride * 0.54;
    model.rightLeg.rotation.x = -stride * 0.54;
    model.leftArm.rotation.x = -stride * 0.4;
    model.rightArm.rotation.x = stride * 0.4;
    if (model.pair) {
      model.pair.leftLeg.rotation.x = -stride * 0.48;
      model.pair.rightLeg.rotation.x = stride * 0.48;
    }
  }

  private updateCamera(playerZ: number, laneVelocity: number, deltaSeconds: number, state: ChaseRenderState): void {
    const targetCameraX = this.rider.group.position.x * 0.27;
    const cameraEase = this.reducedMotion ? 1 : Math.min(1, deltaSeconds * 5.5);
    this.camera.position.x += (targetCameraX - this.camera.position.x) * cameraEase;
    const speed = clamp((state.distance + 70) / GOAL_DISTANCE, 0, 1);
    const bob = this.reducedMotion ? 0 : Math.sin(this.animationSeconds * (7 + speed * 3)) * (0.035 + speed * 0.035);
    const lateralLag = clamp(-laneVelocity * 0.032, -0.5, 0.5);
    this.camera.position.set(
      this.camera.position.x + lateralLag,
      4.82 + bob,
      playerZ + PLAYER_CAMERA_GAP
    );
    this.camera.lookAt(this.rider.group.position.x * 0.46, 1.12, playerZ - PLAYER_LOOK_AHEAD);
  }
}
