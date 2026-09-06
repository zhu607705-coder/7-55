import * as THREE from "three";
import { mergeGeometries } from "three/examples/jsm/utils/BufferGeometryUtils.js";
import { ThreePrimitiveCache, type ThreeFlatMaterial } from "../ThreePrimitiveCache";
import { createChaseHuman, type ChaseHumanInstance } from "./ChaseHumanAsset";
import { syncChaseHumanToRider } from "./ChaseHumanPose";

export const CHASE_RIDER_DISPLAY_SCALE = 1.28;
export const CHASE_RIDER_WHEEL_RADIUS = 0.5;
export const CHASE_RIDER_GEAR_RATIO = 2.2;
export const CHASE_RIDER_CONTACT_EPSILON = 0.00001;

const LEFT_HAND_BASE_POSITION = Object.freeze({ x: 0, y: -0.36, z: -0.04 });
const RIGHT_HAND_BASE_POSITION = Object.freeze({ x: 0, y: -0.36, z: -0.04 });
const LEFT_FOOT_BASE_POSITION = Object.freeze({ x: 0, y: -0.42, z: 0.02 });
const RIGHT_FOOT_BASE_POSITION = Object.freeze({ x: 0, y: -0.42, z: 0.02 });
// The standing offset is derived from the authored hip, two-bone leg and shoe
// contact lengths so both soles meet the same ground plane as the wheels.
const STAND_RIDER_OFFSET_Y = -0.44;
const SEATED_RIDER_OFFSET_Y = 0.08;
const SEATED_RIDER_OFFSET_Z = 0.04;
const DEFAULT_SHOULDER_X = 0.28;
const DEFAULT_SHOULDER_Y = 1.84;
const RIDE_SHOULDER_X = 0.3;
const RIDE_SHOULDER_Y = 1.65;
const RIDE_SHOULDER_Z = -0.32;
const HIP_X = 0.145;
const HIP_Y = 1.27;
const HIP_Z = 0.17;
const DOWN_AXIS = new THREE.Vector3(0, -1, 0);
const IK_FALLBACK_AXIS = new THREE.Vector3(0, 0, 1);
const IK_SECONDARY_FALLBACK_AXIS = new THREE.Vector3(1, 0, 0);
const IK_EPSILON = 0.0001;

export interface ChaseRiderRigPalette {
  outline: number;
  blue: number;
  blueDark: number;
  cyan: number;
  white: number;
  skin: number;
  hair: number;
  metal: number;
  shadow: number;
}

export const DEFAULT_CHASE_RIDER_RIG_PALETTE: ChaseRiderRigPalette = Object.freeze({
  outline: 0x252b2b,
  blue: 0x647768,
  blueDark: 0x3d4b41,
  cyan: 0xb5bbb1,
  white: 0xe8e6dc,
  skin: 0xd8b395,
  hair: 0x30322f,
  metal: 0x989f9a,
  shadow: 0x253128
});

export interface ChaseRiderRig {
  human: ChaseHumanInstance;
  root: THREE.Group;
  /** Compatibility alias retained for the live chase renderer. */
  group: THREE.Group;
  bicycleRoot: THREE.Group;
  riderRoot: THREE.Group;
  upperBody: THREE.Group;
  frontAssembly: THREE.Group;
  wheels: readonly [THREE.Mesh, THREE.Mesh];
  rearWheel: THREE.Mesh;
  frontWheel: THREE.Mesh;
  leftArm: THREE.Group;
  rightArm: THREE.Group;
  leftLeg: THREE.Group;
  rightLeg: THREE.Group;
  leftHand: THREE.Object3D;
  rightHand: THREE.Object3D;
  leftFoot: THREE.Object3D;
  rightFoot: THREE.Object3D;
  leftGrip: THREE.Object3D;
  rightGrip: THREE.Object3D;
  leftHandContact: THREE.Object3D;
  rightHandContact: THREE.Object3D;
  leftGripContact: THREE.Object3D;
  rightGripContact: THREE.Object3D;
  leftFootContact: THREE.Object3D;
  rightFootContact: THREE.Object3D;
  leftPedalContact: THREE.Object3D;
  rightPedalContact: THREE.Object3D;
  rightBrakeLever: THREE.Object3D;
  crank: THREE.Object3D;
  leftPedal: THREE.Object3D;
  rightPedal: THREE.Object3D;
  chain: THREE.Object3D;
  basket: THREE.Object3D;
  leftUpperArm: THREE.Group;
  rightUpperArm: THREE.Group;
  leftForearm: THREE.Group;
  rightForearm: THREE.Group;
  leftThigh: THREE.Group;
  rightThigh: THREE.Group;
  leftShin: THREE.Group;
  rightShin: THREE.Group;
}

export type ChaseBicycleRig = Pick<ChaseRiderRig,
  "bicycleRoot" | "frontAssembly" | "rearWheel" | "frontWheel" |
  "leftGrip" | "rightGrip" | "leftGripContact" | "rightGripContact" |
  "leftPedalContact" | "rightPedalContact" | "rightBrakeLever" |
  "crank" | "leftPedal" | "rightPedal" | "chain" | "basket"
>;

export type ChaseRiderPoseName =
  | "ride"
  | "stand_left"
  | "grip"
  | "leg_over"
  | "seated_balance"
  | "pedal_press"
  | "brake"
  | "left_foot_down"
  | "dismount_leg_over"
  | "stand_with_bike"
  | "push_bike";

export interface ChaseRiderPoseOptions {
  progress?: number;
  pedalPhaseRadians?: number;
  steeringRadians?: number;
}

export interface ChaseRiderContactError {
  handToGripWorldUnits: number;
  footToPedalWorldUnits: number;
  leftHandToGripWorldUnits: number;
  rightHandToGripWorldUnits: number;
  rightHandToNearGripWorldUnits: number;
  leftFootToPedalWorldUnits: number;
  rightFootToPedalWorldUnits: number;
}

export interface ChaseRiderFootOrientationError {
  leftSoleTiltRadians: number;
  rightSoleTiltRadians: number;
  leftToeDirectionRadians: number;
  rightToeDirectionRadians: number;
}

export interface ChaseRiderContactSelection {
  handToGrip?: boolean;
  footToPedal?: boolean;
  leftHandToGrip?: boolean;
  rightHandToGrip?: boolean;
  leftFootToPedal?: boolean;
  rightFootToPedal?: boolean;
}

export interface ChaseRiderRigComplexity {
  meshes: number;
  triangles: number;
  materials: number;
}

export const CHASE_RIDER_POSE_NAMES: readonly ChaseRiderPoseName[] = Object.freeze([
  "ride",
  "stand_left",
  "grip",
  "leg_over",
  "seated_balance",
  "pedal_press",
  "brake",
  "left_foot_down",
  "dismount_leg_over",
  "stand_with_bike",
  "push_bike"
]);

/** Counts the actual merged hero-rig geometry that will be submitted to WebGL. */
export function measureChaseRiderRigComplexity(rig: ChaseRiderRig): ChaseRiderRigComplexity {
  let meshes = 0;
  let triangles = 0;
  const materials = new Set<THREE.Material>();
  rig.root.traverse((object) => {
    if (!(object instanceof THREE.Mesh)) return;
    meshes += 1;
    const position = object.geometry.getAttribute("position");
    const vertexCount = object.geometry.index?.count ?? position?.count ?? 0;
    triangles += Math.floor(vertexCount / 3);
    const entries = Array.isArray(object.material) ? object.material : [object.material];
    entries.forEach((entry) => materials.add(entry));
  });
  return { meshes, triangles, materials: materials.size };
}

function clamp01(value: number): number {
  return Math.max(0, Math.min(1, value));
}

function lerp(from: number, to: number, progress: number): number {
  return from + (to - from) * progress;
}

function setSymmetricShoulders(rig: ChaseRiderRig, x: number, y: number, z: number): void {
  rig.leftArm.position.set(-x, y, z);
  rig.rightArm.position.set(x, y, z);
}

function rigMaterial(
  primitives: ThreePrimitiveCache,
  color: number,
  options: {
    unlit?: boolean;
    opacity?: number;
    depthWrite?: boolean;
    shading?: "lambert" | "standard";
    roughness?: number;
    metalness?: number;
    flatShading?: boolean;
  } = {}
): ThreeFlatMaterial {
  return primitives.material(color, options);
}

function rigBox(
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
    rigMaterial(primitives, color, { unlit })
  );
  mesh.position.set(x, y, z);
  return mesh;
}

function rigWheel(
  primitives: ThreePrimitiveCache,
  palette: ChaseRiderRigPalette,
  radius: number
): THREE.Mesh {
  const spokeCount = 24;
  const rimRadius = radius * 0.84;
  const hubHalfWidth = 0.14;
  const tire = transformGeometry(primitives.torus(radius, radius * 0.105, 14, 56), {
    rotation: [0, Math.PI / 2, 0]
  });
  const rim = transformGeometry(primitives.torus(rimRadius, radius * 0.028, 10, 48), {
    rotation: [0, Math.PI / 2, 0]
  });
  const hub = transformGeometry(primitives.cylinder(radius * 0.075, radius * 0.075, hubHalfWidth * 2, 16), {
    rotation: [0, 0, Math.PI / 2]
  });
  const spokeParts: THREE.BufferGeometry[] = [];
  for (let index = 0; index < spokeCount; index += 1) {
    const angle = (index / spokeCount) * Math.PI * 2;
    const crossedAngle = angle + (index % 2 === 0 ? 0.16 : -0.16);
    const rimPoint = new THREE.Vector3(
      0,
      Math.sin(crossedAngle) * rimRadius,
      Math.cos(crossedAngle) * rimRadius
    );
    spokeParts.push(tubeGeometry(
      primitives,
      new THREE.Vector3(index % 2 === 0 ? -hubHalfWidth : hubHalfWidth, 0, 0),
      rimPoint,
      radius * 0.009,
      6
    ));
  }
  const spokes = mergeRigidGeometries(spokeParts);
  const wheelParts = [tire, rim, hub, spokes].map((geometry) => (
    geometry.index ? geometry.toNonIndexed() : geometry.clone()
  ));
  const merged = mergeGeometries(wheelParts, true);
  tire.dispose();
  rim.dispose();
  hub.dispose();
  spokes.dispose();
  wheelParts.forEach((geometry) => geometry.dispose());
  if (!merged) throw new Error("Failed to merge detailed wheel geometry.");
  return new THREE.Mesh(merged, [
    rigMaterial(primitives, palette.outline, {
      shading: "standard",
      roughness: 0.72,
      metalness: 0.08,
      flatShading: false
    }),
    rigMaterial(primitives, palette.blue, {
      shading: "standard",
      roughness: 0.28,
      metalness: 0.78,
      flatShading: false
    }),
    rigMaterial(primitives, palette.metal, {
      shading: "standard",
      roughness: 0.2,
      metalness: 0.92,
      flatShading: false
    }),
    rigMaterial(primitives, 0xb9c2c7, {
      shading: "standard",
      roughness: 0.24,
      metalness: 0.88,
      flatShading: false
    })
  ]);
}

function rigShadow(
  primitives: ThreePrimitiveCache,
  palette: ChaseRiderRigPalette,
  width: number,
  depth: number
): THREE.Mesh {
  const pixels = new Uint8Array(32 * 32 * 4);
  for (let y = 0; y < 32; y += 1) for (let x = 0; x < 32; x += 1) {
    const radius = Math.hypot((x - 15.5) / 15.5, (y - 15.5) / 15.5);
    const offset = (y * 32 + x) * 4;
    pixels[offset] = pixels[offset + 1] = pixels[offset + 2] = 255;
    pixels[offset + 3] = Math.round(255 * Math.max(0, 1 - radius) ** 1.6);
  }
  const texture = new THREE.DataTexture(pixels, 32, 32);
  texture.magFilter = THREE.LinearFilter;
  texture.needsUpdate = true;
  const shadow = new THREE.Mesh(
    primitives.plane(width, depth),
    new THREE.MeshBasicMaterial({ color: palette.shadow, map: texture, transparent: true, opacity: 0.46, depthWrite: false })
  );
  shadow.rotation.x = -Math.PI / 2;
  shadow.position.y = 0.018;
  shadow.name = "canteen-chase-rider-shadow";
  return shadow;
}

function setIdentityTransform(object: THREE.Object3D): void {
  object.position.set(0, 0, 0);
  object.rotation.set(0, 0, 0);
  object.scale.set(1, 1, 1);
}

function createContactPoint(name: string, x: number, y: number, z: number): THREE.Object3D {
  const contact = new THREE.Object3D();
  contact.name = name;
  contact.position.set(x, y, z);
  return contact;
}

interface RigidGeometryTransform {
  position?: readonly [number, number, number];
  rotation?: readonly [number, number, number];
  scale?: readonly [number, number, number];
}

function transformGeometry(
  geometry: THREE.BufferGeometry,
  transform: RigidGeometryTransform = {}
): THREE.BufferGeometry {
  const clone = geometry.clone();
  const pivot = new THREE.Object3D();
  const position = transform.position ?? [0, 0, 0];
  const rotation = transform.rotation ?? [0, 0, 0];
  const scale = transform.scale ?? [1, 1, 1];
  pivot.position.set(position[0], position[1], position[2]);
  pivot.rotation.set(rotation[0], rotation[1], rotation[2]);
  pivot.scale.set(scale[0], scale[1], scale[2]);
  pivot.updateMatrix();
  clone.applyMatrix4(pivot.matrix);
  return clone;
}

function mergeRigidGeometries(parts: readonly THREE.BufferGeometry[]): THREE.BufferGeometry {
  const normalized = parts.map((geometry) => geometry.index ? geometry.toNonIndexed() : geometry.clone());
  const merged = mergeGeometries(normalized, false);
  parts.forEach((geometry) => geometry.dispose());
  normalized.forEach((geometry) => geometry.dispose());
  if (!merged) throw new Error("Failed to merge rider rig geometry.");
  return merged;
}

function rigMergedMesh(
  primitives: ThreePrimitiveCache,
  color: number,
  parts: readonly THREE.BufferGeometry[],
  options: {
    unlit?: boolean;
    shading?: "lambert" | "standard";
    roughness?: number;
    metalness?: number;
    flatShading?: boolean;
  } = {}
): THREE.Mesh {
  return new THREE.Mesh(
    mergeRigidGeometries(parts),
    rigMaterial(primitives, color, options)
  );
}

function tubeGeometry(
  primitives: ThreePrimitiveCache,
  from: THREE.Vector3,
  to: THREE.Vector3,
  radius: number,
  radialSegments = 8
): THREE.BufferGeometry {
  const direction = to.clone().sub(from);
  const length = Math.max(direction.length(), 0.0001);
  const midpoint = from.clone().add(to).multiplyScalar(0.5);
  const quaternion = new THREE.Quaternion().setFromUnitVectors(
    new THREE.Vector3(0, 1, 0),
    direction.normalize()
  );
  const geometry = primitives.cylinder(radius, radius, length, radialSegments).clone();
  geometry.applyMatrix4(new THREE.Matrix4().compose(midpoint, quaternion, new THREE.Vector3(1, 1, 1)));
  return geometry;
}

function curveTubeGeometry(
  points: readonly THREE.Vector3[],
  radius: number,
  tubularSegments = 24,
  radialSegments = 8
): THREE.BufferGeometry {
  const curve = new THREE.CatmullRomCurve3(points.map((point) => point.clone()), false, "centripetal");
  return new THREE.TubeGeometry(curve, tubularSegments, radius, radialSegments, false);
}

function extrudedPanelGeometry(
  points: readonly (readonly [number, number])[],
  frontZ: number,
  depth: number,
  bevelSize = 0.008
): THREE.BufferGeometry {
  const [first, ...rest] = points;
  if (!first) throw new Error("A clothing panel needs at least one point.");
  const shape = new THREE.Shape();
  shape.moveTo(first[0], first[1]);
  rest.forEach(([x, y]) => shape.lineTo(x, y));
  shape.closePath();
  const geometry = new THREE.ExtrudeGeometry(shape, {
    depth,
    steps: 1,
    curveSegments: 12,
    bevelEnabled: true,
    bevelSegments: 3,
    bevelSize,
    bevelThickness: Math.min(depth * 0.28, 0.008)
  });
  geometry.translate(0, 0, frontZ);
  return geometry;
}

/**
 * Creates one continuous youthful head volume. A deformed sphere avoids the
 * visible cheek/chin seam that appeared when the face was assembled from
 * overlapping primitives, while retaining a tapered jaw in every view.
 */
function stylizedHeadGeometry(primitives: ThreePrimitiveCache): THREE.BufferGeometry {
  const geometry = primitives.sphere(1, 48, 36).clone();
  const position = geometry.getAttribute("position") as THREE.BufferAttribute;
  for (let index = 0; index < position.count; index += 1) {
    const sourceX = position.getX(index);
    const sourceY = position.getY(index);
    const sourceZ = position.getZ(index);
    const lowerFace = clamp01((sourceY + 1) / 0.9);
    const crownTaper = sourceY > 0.55 ? lerp(1, 0.89, (sourceY - 0.55) / 0.45) : 1;
    const jawTaper = sourceY < -0.08 ? lerp(0.8, 1, lowerFace) : 1;
    const cheekFullness = sourceY > -0.28 && sourceY < 0.22 ? 1.04 : 1;
    const foreheadTaper = sourceY > 0.2 ? lerp(0.98, 0.9, clamp01((sourceY - 0.2) / 0.8)) : 1;
    const frontCompress = sourceZ < -0.05
      ? lerp(0.82, 0.94, clamp01((sourceY + 1) / 1.2))
      : 1;
    const backFullness = sourceZ > 0.04
      ? lerp(1.02, 1.1, clamp01((sourceY + 0.2) / 1.1))
      : 1;
    const chinPull = sourceY < -0.38 && sourceZ < -0.08 ? -0.008 * clamp01((-0.38 - sourceY) / 0.4) : 0;
    const shapedY = sourceY < -0.72 ? -0.72 + (sourceY + 0.72) * 0.36 : sourceY;
    position.setXYZ(
      index,
      sourceX * 0.228 * jawTaper * crownTaper * cheekFullness * foreheadTaper,
      2.215 + shapedY * 0.252,
      0.018 + sourceZ * 0.182 * frontCompress * backFullness + chinPull
    );
  }
  position.needsUpdate = true;
  geometry.computeVertexNormals();
  geometry.computeBoundingBox();
  geometry.computeBoundingSphere();
  return geometry;
}

function mirroredContactPosition(contact: THREE.Object3D): THREE.Vector3 {
  return new THREE.Vector3(-contact.position.x, contact.position.y, contact.position.z);
}

function solveTwoBoneIK(
  root: THREE.Object3D,
  rootPivot: THREE.Group,
  midPivot: THREE.Group,
  endEffector: THREE.Object3D,
  targetContact: THREE.Object3D,
  endContact: THREE.Object3D,
  bendHintWorld: THREE.Vector3
): void {
  const rootParent = rootPivot.parent;
  if (!rootParent) throw new Error(`${rootPivot.name || "root pivot"} must have a parent before IK.`);
  if (midPivot.parent !== rootPivot) {
    throw new Error(`${midPivot.name || "mid pivot"} must be parented to ${rootPivot.name || "root pivot"} for IK.`);
  }
  if (endEffector.parent !== midPivot) {
    throw new Error(`${endEffector.name || "end effector"} must be parented to ${midPivot.name || "mid pivot"} for IK.`);
  }

  rootPivot.quaternion.identity();
  midPivot.quaternion.identity();
  endEffector.quaternion.identity();
  root.updateWorldMatrix(true, true);

  const upperRest = midPivot.position.clone();
  const upperLength = Math.max(upperRest.length(), IK_EPSILON);
  const upperAxis = upperRest.normalize();
  const lowerRest = midPivot.worldToLocal(endContact.getWorldPosition(new THREE.Vector3()));
  const lowerLength = Math.max(lowerRest.length(), IK_EPSILON);
  const lowerAxis = lowerRest.clone().normalize();

  const rootOrigin = rootPivot.position.clone();
  const targetLocal = rootParent
    .worldToLocal(targetContact.getWorldPosition(new THREE.Vector3()))
    .sub(rootOrigin);
  const targetDistance = targetLocal.length();
  const clampedDistance = Math.max(
    IK_EPSILON,
    Math.min(targetDistance, upperLength + lowerLength - IK_EPSILON)
  );
  const direction = targetDistance > IK_EPSILON
    ? targetLocal.clone().normalize()
    : upperAxis.clone();
  const hintLocal = rootParent.worldToLocal(bendHintWorld.clone()).sub(rootOrigin);
  const pole = hintLocal.sub(direction.clone().multiplyScalar(hintLocal.dot(direction)));
  if (pole.lengthSq() < IK_EPSILON) {
    const fallbackAxis = Math.abs(direction.dot(IK_FALLBACK_AXIS)) < 0.95
      ? IK_FALLBACK_AXIS
      : IK_SECONDARY_FALLBACK_AXIS;
    pole.copy(fallbackAxis).sub(direction.clone().multiplyScalar(fallbackAxis.dot(direction)));
  }
  pole.normalize();

  const upperCos = THREE.MathUtils.clamp(
    (clampedDistance * clampedDistance + upperLength * upperLength - lowerLength * lowerLength)
      / (2 * clampedDistance * upperLength),
    -1,
    1
  );
  const upperAlong = upperLength * upperCos;
  const upperAcross = Math.sqrt(Math.max(0, upperLength * upperLength - upperAlong * upperAlong));
  const elbow = direction.clone().multiplyScalar(upperAlong).add(pole.multiplyScalar(upperAcross));
  const upperDirection = elbow.clone().normalize();
  const lowerVector = targetLocal.clone().sub(elbow);
  const lowerDirection = lowerVector.lengthSq() > IK_EPSILON
    ? lowerVector.normalize()
    : lowerAxis.clone();

  const rootRotation = new THREE.Quaternion().setFromUnitVectors(upperAxis, upperDirection);
  rootPivot.quaternion.copy(rootRotation);
  const upperInverse = rootRotation.clone().invert();
  const lowerDirectionLocal = lowerDirection.clone().applyQuaternion(upperInverse);
  midPivot.quaternion.copy(new THREE.Quaternion().setFromUnitVectors(lowerAxis, lowerDirectionLocal));
  root.updateWorldMatrix(true, true);
}

/**
 * Keeps a pedal-bound shoe level with the bicycle instead of inheriting the
 * shin's terminal rotation. Repositioning the foot after the quaternion update
 * preserves the authored sole-to-pedal contact point exactly.
 */
function alignPedalFootOrientation(
  root: THREE.Object3D,
  foot: THREE.Object3D,
  footContact: THREE.Object3D,
  pedalContact: THREE.Object3D,
  bicycleRoot: THREE.Object3D
): void {
  const parent = foot.parent;
  if (!parent) throw new Error(`${foot.name || "foot"} must have a parent before ankle alignment.`);

  root.updateWorldMatrix(true, true);
  const pedalWorld = pedalContact.getWorldPosition(new THREE.Vector3());
  const bicycleWorldQuaternion = bicycleRoot.getWorldQuaternion(new THREE.Quaternion());
  const parentWorldQuaternion = parent.getWorldQuaternion(new THREE.Quaternion());
  foot.quaternion.copy(parentWorldQuaternion.invert().multiply(bicycleWorldQuaternion));

  root.updateWorldMatrix(true, true);
  const currentContactWorld = footContact.getWorldPosition(new THREE.Vector3());
  const pedalInParent = parent.worldToLocal(pedalWorld.clone());
  const currentContactInParent = parent.worldToLocal(currentContactWorld.clone());
  foot.position.add(pedalInParent.sub(currentContactInParent));
  root.updateWorldMatrix(true, true);
}

/**
 * Builds the one canonical low-poly rider and blue campus bicycle.
 *
 * The cache is injected so the chase and deterministic transition renderer
 * share immutable geometry/material ownership. bicycleRoot and riderRoot stay
 * at unit transform; their extra hierarchy therefore preserves the original
 * buildRider() world transforms used by the live chase.
 */
export function createChaseBicycleRig(
  primitives: ThreePrimitiveCache,
  palette: ChaseRiderRigPalette = DEFAULT_CHASE_RIDER_RIG_PALETTE
): ChaseBicycleRig {
  const bicycleRoot = new THREE.Group();
  bicycleRoot.name = "canteen-chase-bicycle-root";
  setIdentityTransform(bicycleRoot);

  const rearWheel = rigWheel(primitives, palette, CHASE_RIDER_WHEEL_RADIUS);
  rearWheel.name = "canteen-chase-rear-wheel";
  rearWheel.position.set(0, 0.52, 0.72);

  const frontAssembly = new THREE.Group();
  frontAssembly.name = "canteen-chase-front-assembly";
  frontAssembly.position.set(0, 0, -0.72);

  const frontWheel = rigWheel(primitives, palette, CHASE_RIDER_WHEEL_RADIUS);
  frontWheel.name = "canteen-chase-front-wheel";
  frontWheel.position.set(0, 0.52, 0);

  const forkCrownLeft = new THREE.Vector3(-0.12, 1.02, -0.02);
  const forkCrownRight = new THREE.Vector3(0.12, 1.02, -0.02);
  const forkDropoutLeft = new THREE.Vector3(-0.13, 0.53, 0);
  const forkDropoutRight = new THREE.Vector3(0.13, 0.53, 0);
  const frontAssemblyBody = rigMergedMesh(primitives, palette.blue, [
    tubeGeometry(primitives, new THREE.Vector3(0, 0.98, 0.04), new THREE.Vector3(0, 1.35, 0.1), 0.06, 12),
    curveTubeGeometry([
      new THREE.Vector3(0, 1.34, 0.1),
      new THREE.Vector3(-0.2, 1.38, 0.05),
      new THREE.Vector3(-0.32, 1.43, 0.03),
      new THREE.Vector3(-0.45, 1.39, 0.07)
    ], 0.029, 22, 10),
    curveTubeGeometry([
      new THREE.Vector3(0, 1.34, 0.1),
      new THREE.Vector3(0.2, 1.38, 0.05),
      new THREE.Vector3(0.32, 1.43, 0.03),
      new THREE.Vector3(0.45, 1.39, 0.07)
    ], 0.029, 22, 10),
    tubeGeometry(primitives, forkCrownLeft, forkDropoutLeft, 0.047, 12),
    tubeGeometry(primitives, forkCrownRight, forkDropoutRight, 0.047, 12),
    transformGeometry(primitives.box(0.2, 0.08, 0.18), {
      position: [0, 0.98, -0.02]
    })
  ], { shading: "standard", roughness: 0.45, metalness: 0.42, flatShading: false });
  frontAssemblyBody.name = "canteen-chase-front-assembly-body";

  const leftGrip = new THREE.Group();
  leftGrip.name = "canteen-chase-left-grip";
  leftGrip.position.set(-0.49, 1.38, 0.08);
  leftGrip.add(
    rigMergedMesh(primitives, palette.outline, [
      transformGeometry(primitives.cylinder(0.045, 0.045, 0.24, 8), {
        rotation: [0, 0, Math.PI / 2]
      })
    ], { shading: "standard", roughness: 0.72, metalness: 0.18, flatShading: false })
  );
  const leftGripContact = createContactPoint("canteen-chase-left-grip-contact", 0.011, 0.018, 0.108);
  leftGrip.add(leftGripContact);

  const rightGrip = new THREE.Group();
  rightGrip.name = "canteen-chase-right-grip";
  rightGrip.position.set(0.49, 1.38, 0.08);
  rightGrip.add(
    rigMergedMesh(primitives, palette.outline, [
      transformGeometry(primitives.cylinder(0.045, 0.045, 0.24, 8), {
        rotation: [0, 0, Math.PI / 2]
      })
    ], { shading: "standard", roughness: 0.72, metalness: 0.18, flatShading: false })
  );
  const rightGripContact = createContactPoint("canteen-chase-right-grip-contact", -0.011, 0.018, 0.108);
  rightGrip.add(rightGripContact);

  const headLamp = new THREE.Mesh(
    mergeRigidGeometries([
      transformGeometry(primitives.sphere(0.11, 10, 8), {
        scale: [1.15, 0.9, 1]
      }),
      transformGeometry(primitives.cylinder(0.028, 0.028, 0.1, 8), {
        position: [0, -0.08, 0.04]
      })
    ]),
    rigMaterial(primitives, palette.white, {
      shading: "standard",
      roughness: 0.32,
      metalness: 0.08,
      flatShading: false
    })
  );
  headLamp.position.set(0, 1.14, -0.18);

  const bell = rigMergedMesh(primitives, palette.metal, [
    transformGeometry(primitives.sphere(0.075, 16, 12), {
      position: [-0.37, 1.45, 0],
      scale: [1, 0.72, 1]
    }),
    transformGeometry(primitives.cylinder(0.018, 0.018, 0.09, 10), {
      position: [-0.29, 1.43, 0],
      rotation: [0, 0, Math.PI / 2]
    })
  ], { shading: "standard", roughness: 0.16, metalness: 0.94, flatShading: false });

  const rightBrakeLever = new THREE.Group();
  rightBrakeLever.name = "canteen-chase-right-brake-lever";
  rightBrakeLever.position.set(0.4, 1.35, -0.01);
  rightBrakeLever.rotation.z = -0.38;
  rightBrakeLever.add(
    rigMergedMesh(primitives, palette.metal, [
      curveTubeGeometry([new THREE.Vector3(0, 0.02, 0), new THREE.Vector3(0.08, -0.015, -0.075), new THREE.Vector3(0.18, 0.005, -0.05)], 0.017, 12, 8),
      transformGeometry(primitives.sphere(0.03, 8, 6), {
        position: [0, 0.03, 0]
      })
    ], { shading: "standard", roughness: 0.28, metalness: 0.82, flatShading: false })
  );

  const leftBrakeLever = rightBrakeLever.clone();
  leftBrakeLever.name = "canteen-chase-left-brake-lever";
  leftBrakeLever.position.x = -0.4;
  leftBrakeLever.rotation.y = Math.PI;
  const brakeCables = rigMergedMesh(primitives, 0x252d32, [-1, 1].map((side) => curveTubeGeometry([
    new THREE.Vector3(side * 0.38, 1.37, -0.04),
    new THREE.Vector3(side * 0.29, 1.2, -0.28),
    new THREE.Vector3(side * 0.18, 0.87, -0.23),
    new THREE.Vector3(side * 0.1, 0.88, -0.02)
  ], 0.009, 20, 6)), { shading: "standard", roughness: 0.72, flatShading: false });
  brakeCables.name = "canteen-chase-brake-cables";

  const basket = new THREE.Group();
  basket.name = "canteen-chase-front-basket";
  basket.position.set(0, 0.98, -0.46);
  const basketWires: THREE.BufferGeometry[] = [
      tubeGeometry(primitives, new THREE.Vector3(-0.34, -0.18, -0.24), new THREE.Vector3(0.34, -0.18, -0.24), 0.018, 6),
      tubeGeometry(primitives, new THREE.Vector3(-0.34, -0.18, 0.24), new THREE.Vector3(0.34, -0.18, 0.24), 0.018, 6),
      tubeGeometry(primitives, new THREE.Vector3(-0.34, 0.14, -0.24), new THREE.Vector3(0.34, 0.14, -0.24), 0.018, 6),
      tubeGeometry(primitives, new THREE.Vector3(-0.34, 0.14, 0.24), new THREE.Vector3(0.34, 0.14, 0.24), 0.018, 6),
      tubeGeometry(primitives, new THREE.Vector3(-0.34, -0.18, -0.24), new THREE.Vector3(-0.34, 0.14, -0.24), 0.018, 6),
      tubeGeometry(primitives, new THREE.Vector3(0.34, -0.18, -0.24), new THREE.Vector3(0.34, 0.14, -0.24), 0.018, 6),
      tubeGeometry(primitives, new THREE.Vector3(-0.34, -0.18, 0.24), new THREE.Vector3(-0.34, 0.14, 0.24), 0.018, 6),
      tubeGeometry(primitives, new THREE.Vector3(0.34, -0.18, 0.24), new THREE.Vector3(0.34, 0.14, 0.24), 0.018, 6),
      tubeGeometry(primitives, new THREE.Vector3(-0.34, -0.18, -0.24), new THREE.Vector3(-0.34, -0.18, 0.24), 0.018, 6),
      tubeGeometry(primitives, new THREE.Vector3(0.34, -0.18, -0.24), new THREE.Vector3(0.34, -0.18, 0.24), 0.018, 6),
      tubeGeometry(primitives, new THREE.Vector3(-0.34, 0.14, -0.24), new THREE.Vector3(-0.34, 0.14, 0.24), 0.018, 6),
      tubeGeometry(primitives, new THREE.Vector3(0.34, 0.14, -0.24), new THREE.Vector3(0.34, 0.14, 0.24), 0.018, 6)
  ];
  for (const x of [-0.22, -0.11, 0, 0.11, 0.22]) {
    basketWires.push(
      tubeGeometry(primitives, new THREE.Vector3(x, -0.17, -0.235), new THREE.Vector3(x, 0.13, -0.235), 0.008, 6),
      tubeGeometry(primitives, new THREE.Vector3(x, -0.17, 0.235), new THREE.Vector3(x, 0.13, 0.235), 0.008, 6),
      tubeGeometry(primitives, new THREE.Vector3(x, -0.175, -0.23), new THREE.Vector3(x, -0.175, 0.23), 0.008, 6)
    );
  }
  for (const z of [-0.12, 0, 0.12]) {
    basketWires.push(
      tubeGeometry(primitives, new THREE.Vector3(-0.335, -0.16, z), new THREE.Vector3(-0.335, 0.12, z), 0.008, 6),
      tubeGeometry(primitives, new THREE.Vector3(0.335, -0.16, z), new THREE.Vector3(0.335, 0.12, z), 0.008, 6)
    );
  }
  basket.add(rigMergedMesh(primitives, palette.blueDark, basketWires, {
    shading: "standard",
    roughness: 0.46,
    metalness: 0.54,
    flatShading: false
  }));

  const frontFenderPoints = Array.from({ length: 25 }, (_, index) => {
    const angle = 0.12 + (Math.PI - 0.24) * (index / 24);
    return new THREE.Vector3(0, 0.52 + Math.sin(angle) * 0.57, Math.cos(angle) * 0.57);
  });
  const frontFender = new THREE.Mesh(
    curveTubeGeometry(frontFenderPoints, 0.032, 36, 10),
    rigMaterial(primitives, palette.blue, {
      shading: "standard",
      roughness: 0.3,
      metalness: 0.7,
      flatShading: false
    })
  );
  frontFender.name = "canteen-chase-front-fender";

  frontAssembly.add(
    frontAssemblyBody,
    frontWheel,
    leftGrip,
    rightGrip,
    headLamp,
    bell,
    rightBrakeLever,
    leftBrakeLever,
    brakeCables,
    basket,
    frontFender
  );
  bicycleRoot.add(rearWheel, frontAssembly);

  const frame = new THREE.Group();
  frame.name = "canteen-chase-blue-frame";
  const seatTop = new THREE.Vector3(0, 1.18, 0.44);
  const headJoint = new THREE.Vector3(0, 1.02, -0.54);
  const bottomBracket = new THREE.Vector3(0, 0.56, 0.14);
  const stepThroughJoint = new THREE.Vector3(0, 0.77, -0.08);
  const rearAxleLeft = new THREE.Vector3(-0.09, 0.52, 0.72);
  const rearAxleRight = new THREE.Vector3(0.09, 0.52, 0.72);
  frame.add(
    rigMergedMesh(primitives, palette.blue, [
      curveTubeGeometry([headJoint, new THREE.Vector3(0, 0.9, -0.33), stepThroughJoint, bottomBracket], 0.045, 28, 12),
      curveTubeGeometry([headJoint, new THREE.Vector3(0, 1.025, -0.18), new THREE.Vector3(0, 1.07, 0.12), seatTop], 0.032, 30, 12),
      tubeGeometry(primitives, seatTop, bottomBracket, 0.037, 12),
      tubeGeometry(primitives, new THREE.Vector3(-0.05, 0.58, 0.18), rearAxleLeft, 0.042, 10),
      tubeGeometry(primitives, new THREE.Vector3(0.05, 0.58, 0.18), rearAxleRight, 0.042, 10),
      tubeGeometry(primitives, new THREE.Vector3(-0.02, 1.14, 0.39), rearAxleLeft, 0.034, 10),
      tubeGeometry(primitives, new THREE.Vector3(0.02, 1.14, 0.39), rearAxleRight, 0.034, 10),
      transformGeometry(primitives.capsule(0.07, 0.38, 6, 12), {
        position: [0, 1.22, 0.44],
        rotation: [0, 0, Math.PI / 2],
        scale: [1, 0.82, 0.9]
      })
    ], { shading: "standard", roughness: 0.42, metalness: 0.55, flatShading: false }),
    rigMergedMesh(primitives, palette.outline, [
      transformGeometry(primitives.capsule(0.045, 0.2, 6, 12), {
        position: [0, 1.28, 0.52],
        rotation: [0.12, 0, Math.PI / 2]
      })
    ], { shading: "standard", roughness: 0.82, metalness: 0.08, flatShading: false })
  );
  const saddle = rigMergedMesh(primitives, 0x25292d, [
    transformGeometry(primitives.sphere(1, 18, 12), { position: [0, 1.285, 0.4], scale: [0.18, 0.048, 0.25] }),
    transformGeometry(primitives.sphere(1, 16, 10), { position: [0, 1.28, 0.23], scale: [0.075, 0.04, 0.15] })
  ], { shading: "standard", roughness: 0.85, flatShading: false });
  saddle.name = "canteen-chase-shaped-saddle";
  frame.add(saddle);
  bicycleRoot.add(frame);

  const rearFenderPoints = Array.from({ length: 25 }, (_, index) => {
    const angle = 0.12 + (Math.PI - 0.24) * (index / 24);
    return new THREE.Vector3(0, 0.52 + Math.sin(angle) * 0.57, 0.72 + Math.cos(angle) * 0.57);
  });
  const rearFender = new THREE.Mesh(
    curveTubeGeometry(rearFenderPoints, 0.035, 38, 10),
    rigMaterial(primitives, palette.blue, {
      shading: "standard",
      roughness: 0.3,
      metalness: 0.7,
      flatShading: false
    })
  );
  rearFender.name = "canteen-chase-rear-fender";

  const rearRackParts: THREE.BufferGeometry[] = [
    tubeGeometry(primitives, new THREE.Vector3(-0.27, 1.08, 0.46), new THREE.Vector3(-0.27, 1.08, 1.05), 0.022, 8),
    tubeGeometry(primitives, new THREE.Vector3(0.27, 1.08, 0.46), new THREE.Vector3(0.27, 1.08, 1.05), 0.022, 8),
    tubeGeometry(primitives, new THREE.Vector3(-0.27, 1.08, 0.46), new THREE.Vector3(0.27, 1.08, 0.46), 0.022, 8),
    tubeGeometry(primitives, new THREE.Vector3(-0.27, 1.08, 1.05), new THREE.Vector3(0.27, 1.08, 1.05), 0.022, 8),
    tubeGeometry(primitives, new THREE.Vector3(-0.25, 1.05, 0.97), rearAxleLeft, 0.018, 8),
    tubeGeometry(primitives, new THREE.Vector3(0.25, 1.05, 0.97), rearAxleRight, 0.018, 8)
  ];
  for (const z of [0.58, 0.72, 0.86, 1]) {
    rearRackParts.push(tubeGeometry(
      primitives,
      new THREE.Vector3(-0.26, 1.08, z),
      new THREE.Vector3(0.26, 1.08, z),
      0.014,
      6
    ));
  }
  const rearRack = rigMergedMesh(primitives, palette.metal, rearRackParts, {
    shading: "standard",
    roughness: 0.26,
    metalness: 0.86,
    flatShading: false
  });
  rearRack.name = "canteen-chase-rear-rack";

  const rearReflector = rigMergedMesh(primitives, 0xc8443c, [
    transformGeometry(primitives.box(0.18, 0.13, 0.06), { position: [0, 1.04, 1.1] })
  ], { shading: "standard", roughness: 0.24, metalness: 0.05, flatShading: false });
  rearReflector.name = "canteen-chase-rear-reflector";

  const kickstand = rigMergedMesh(primitives, palette.metal, [
    tubeGeometry(primitives, new THREE.Vector3(0.18, 0.82, 0.2), new THREE.Vector3(0.25, 0.54, 0.85), 0.024, 10),
    transformGeometry(primitives.capsule(0.028, 0.1, 4, 8), {
      position: [0.25, 0.54, 0.85],
      rotation: [0, 0, Math.PI / 2]
    })
  ], { shading: "standard", roughness: 0.34, metalness: 0.82, flatShading: false });
  kickstand.name = "canteen-chase-kickstand";
  bicycleRoot.add(rearFender, rearRack, rearReflector, kickstand);

  const crank = new THREE.Group();
  crank.name = "canteen-chase-crank";
  crank.position.copy(bottomBracket);
  const crankBody = rigMergedMesh(primitives, palette.metal, [
    transformGeometry(primitives.cylinder(0.08, 0.08, 0.44, 14), {
      rotation: [0, 0, Math.PI / 2]
    }),
    transformGeometry(primitives.torus(0.21, 0.026, 10, 38), {
      rotation: [0, Math.PI / 2, 0],
      position: [-0.03, 0, 0]
    }),
    tubeGeometry(primitives, new THREE.Vector3(0.12, -0.02, 0), new THREE.Vector3(0.28, -0.22, 0), 0.025, 8),
    tubeGeometry(primitives, new THREE.Vector3(-0.12, 0.02, 0), new THREE.Vector3(-0.28, 0.22, 0), 0.025, 8),
    tubeGeometry(primitives, new THREE.Vector3(-0.03, 0, 0), new THREE.Vector3(-0.23, 0.07, 0), 0.018, 6),
    tubeGeometry(primitives, new THREE.Vector3(-0.03, 0, 0), new THREE.Vector3(-0.23, -0.07, 0), 0.018, 6),
    tubeGeometry(primitives, new THREE.Vector3(-0.03, 0, 0), new THREE.Vector3(-0.1, 0.22, 0), 0.018, 6),
    tubeGeometry(primitives, new THREE.Vector3(-0.03, 0, 0), new THREE.Vector3(-0.1, -0.22, 0), 0.018, 6)
  ], { shading: "standard", roughness: 0.24, metalness: 0.88, flatShading: false });
  const rightPedal = new THREE.Group();
  rightPedal.name = "canteen-chase-right-pedal";
  rightPedal.position.set(0.3, -0.22, 0);
  rightPedal.add(
    rigMergedMesh(primitives, palette.outline, [
      transformGeometry(primitives.capsule(0.03, 0.22, 4, 8), {
        rotation: [0, 0, Math.PI / 2]
      }),
      transformGeometry(primitives.cylinder(0.012, 0.012, 0.12, 6), {
        position: [0, 0.04, 0]
      })
    ], { shading: "standard", roughness: 0.86, metalness: 0.06, flatShading: false })
  );
  const rightPedalContact = createContactPoint("canteen-chase-right-pedal-contact", 0, 0.04, 0);
  rightPedal.add(rightPedalContact);
  const leftPedal = new THREE.Group();
  leftPedal.name = "canteen-chase-left-pedal";
  leftPedal.position.set(-0.3, 0.22, 0);
  leftPedal.add(
    rigMergedMesh(primitives, palette.outline, [
      transformGeometry(primitives.capsule(0.03, 0.22, 4, 8), {
        rotation: [0, 0, Math.PI / 2]
      }),
      transformGeometry(primitives.cylinder(0.012, 0.012, 0.12, 6), {
        position: [0, -0.04, 0]
      })
    ], { shading: "standard", roughness: 0.86, metalness: 0.06, flatShading: false })
  );
  const leftPedalContact = createContactPoint("canteen-chase-left-pedal-contact", 0, 0.04, 0);
  leftPedal.add(leftPedalContact);
  crank.add(crankBody, rightPedal, leftPedal);
  bicycleRoot.add(crank);

  const chain = new THREE.Group();
  chain.name = "canteen-chase-short-chain";
  chain.add(
    rigMergedMesh(primitives, palette.outline, [
      tubeGeometry(primitives, new THREE.Vector3(-0.2, 0.35, 0.16), new THREE.Vector3(-0.2, 0.58, 0.72), 0.012, 8),
      tubeGeometry(primitives, new THREE.Vector3(-0.2, 0.77, 0.16), new THREE.Vector3(-0.2, 0.72, 0.72), 0.012, 8),
      transformGeometry(primitives.torus(0.105, 0.012, 8, 30), {
        position: [-0.2, 0.65, 0.72],
        rotation: [0, Math.PI / 2, 0]
      })
    ], { shading: "standard", roughness: 0.34, metalness: 0.78, flatShading: false })
  );
  const chainGuard = rigMergedMesh(primitives, palette.blue, [
    transformGeometry(primitives.capsule(0.095, 0.52, 8, 16), {
      position: [-0.23, 0.61, 0.4],
      rotation: [1.4, 0, 0],
      scale: [0.72, 1, 0.9]
    }),
    transformGeometry(primitives.cylinder(0.23, 0.23, 0.055, 24), {
      position: [-0.23, 0.56, 0.14],
      rotation: [0, 0, Math.PI / 2]
    })
  ], { shading: "standard", roughness: 0.34, metalness: 0.48, flatShading: false });
  chainGuard.name = "canteen-chase-chain-guard";
  bicycleRoot.add(chain);
  bicycleRoot.add(chainGuard);

  return {
    bicycleRoot, rearWheel, frontAssembly, frontWheel, leftGrip, rightGrip,
    leftGripContact, rightGripContact, leftPedalContact, rightPedalContact,
    rightBrakeLever, crank, leftPedal, rightPedal, chain, basket
  };
}

/** The hero and roadside bicycles share the same authored mechanical structure. */
export function createChaseRiderRig(
  primitives: ThreePrimitiveCache,
  palette: ChaseRiderRigPalette = DEFAULT_CHASE_RIDER_RIG_PALETTE
): ChaseRiderRig {
  const root = new THREE.Group();
  root.name = "canteen-chase-player";
  const riderRoot = new THREE.Group();
  riderRoot.name = "canteen-chase-rider-root";
  const bike = createChaseBicycleRig(primitives, palette);
  root.add(rigShadow(primitives, palette, 1.45, 2.2), bike.bicycleRoot, riderRoot);
  // Non-rendering controls retain the authored transition and interaction targets.
  // Only the licensed skinned model provides the visible human geometry.
  const upperBody = new THREE.Group();
  upperBody.position.set(0, HIP_Y, HIP_Z);
  riderRoot.add(upperBody);
  const makeLimb = (side: number, arm: boolean) => {
    const limb = new THREE.Group(), upper = new THREE.Group(), lower = new THREE.Group(), end = new THREE.Group();
    limb.position.set(side * (arm ? DEFAULT_SHOULDER_X : HIP_X), arm ? DEFAULT_SHOULDER_Y : HIP_Y, arm ? 0.02 : HIP_Z);
    lower.position.y = arm ? -0.36 : -0.42;
    const base = arm ? LEFT_HAND_BASE_POSITION : LEFT_FOOT_BASE_POSITION;
    end.position.set(base.x, base.y, base.z);
    const contact = createContactPoint(
      `canteen-chase-${side < 0 ? "left" : "right"}-${arm ? "hand" : "foot"}-contact`,
      0, arm ? 0 : -0.085, arm ? -0.1 : 0
    );
    end.add(contact); lower.add(end); upper.add(lower); limb.add(upper); riderRoot.add(limb);
    return { limb, upper, lower, end, contact };
  };
  const la = makeLimb(-1, true), ra = makeLimb(1, true);
  const ll = makeLimb(-1, false), rl = makeLimb(1, false);
  const human = createChaseHuman(2.15, 0x315b7b, true);
  root.add(human.group);
  root.scale.setScalar(CHASE_RIDER_DISPLAY_SCALE);
  const rig: ChaseRiderRig = {
    root, group: root, ...bike, riderRoot, upperBody, human,
    wheels: [bike.rearWheel, bike.frontWheel],
    leftArm: la.limb, rightArm: ra.limb, leftLeg: ll.limb, rightLeg: rl.limb,
    leftUpperArm: la.upper, rightUpperArm: ra.upper, leftForearm: la.lower, rightForearm: ra.lower,
    leftThigh: ll.upper, rightThigh: rl.upper, leftShin: ll.lower, rightShin: rl.lower,
    leftHand: la.end, rightHand: ra.end, leftFoot: ll.end, rightFoot: rl.end,
    leftHandContact: la.contact, rightHandContact: ra.contact,
    leftFootContact: ll.contact, rightFootContact: rl.contact
  };
  human.onReady = () => syncChaseHumanToRider(rig);
  return rig;
}

/** Reset every pose-controlled node while leaving root placement and scale intact. */
export function resetChaseRiderRigPose(rig: ChaseRiderRig): void {
  setIdentityTransform(rig.bicycleRoot);
  setIdentityTransform(rig.riderRoot);
  rig.upperBody.rotation.set(0, 0, 0);
  rig.frontAssembly.rotation.set(0, 0, 0);
  rig.leftArm.position.set(-DEFAULT_SHOULDER_X, DEFAULT_SHOULDER_Y, 0.02);
  rig.rightArm.position.set(DEFAULT_SHOULDER_X, DEFAULT_SHOULDER_Y, 0.02);
  rig.leftArm.rotation.set(-0.72, 0, -0.2);
  rig.rightArm.rotation.set(-0.72, 0, 0.2);
  rig.leftLeg.position.set(-HIP_X, HIP_Y, HIP_Z);
  rig.rightLeg.position.set(HIP_X, HIP_Y, HIP_Z);
  rig.leftLeg.rotation.set(0, 0, 0);
  rig.rightLeg.rotation.set(0, 0, 0);
  rig.leftUpperArm.rotation.set(0, 0, 0);
  rig.rightUpperArm.rotation.set(0, 0, 0);
  rig.leftForearm.rotation.set(0, 0, 0);
  rig.rightForearm.rotation.set(0, 0, 0);
  rig.leftThigh.rotation.set(0, 0, 0);
  rig.rightThigh.rotation.set(0, 0, 0);
  rig.leftShin.rotation.set(0, 0, 0);
  rig.rightShin.rotation.set(0, 0, 0);
  rig.leftHand.position.set(
    LEFT_HAND_BASE_POSITION.x,
    LEFT_HAND_BASE_POSITION.y,
    LEFT_HAND_BASE_POSITION.z
  );
  rig.rightHand.position.set(
    RIGHT_HAND_BASE_POSITION.x,
    RIGHT_HAND_BASE_POSITION.y,
    RIGHT_HAND_BASE_POSITION.z
  );
  rig.leftFoot.position.set(
    LEFT_FOOT_BASE_POSITION.x,
    LEFT_FOOT_BASE_POSITION.y,
    LEFT_FOOT_BASE_POSITION.z
  );
  rig.rightFoot.position.set(
    RIGHT_FOOT_BASE_POSITION.x,
    RIGHT_FOOT_BASE_POSITION.y,
    RIGHT_FOOT_BASE_POSITION.z
  );
  rig.leftFoot.rotation.set(0, 0, 0);
  rig.rightFoot.rotation.set(0, 0, 0);
  rig.crank.rotation.set(0, 0, 0);
  rig.rightBrakeLever.rotation.set(0, 0, -0.38);
}

/**
 * Aligns the visible palm and sole surfaces with their authored target
 * surfaces after a deterministic pose has moved the limbs, crank or steering.
 */
export function enforceChaseRiderContactConstraints(
  rig: ChaseRiderRig,
  selection: ChaseRiderContactSelection = { handToGrip: true, footToPedal: true }
): void {
  if (selection.leftHandToGrip ?? selection.handToGrip ?? true) {
    solveTwoBoneIK(
      rig.root,
      rig.leftUpperArm,
      rig.leftForearm,
      rig.leftHand,
      rig.leftGripContact,
      rig.leftHandContact,
      rig.leftArm.localToWorld(new THREE.Vector3(-0.48, -0.18, -0.32))
    );
  }
  if (selection.rightHandToGrip ?? selection.handToGrip ?? true) {
    solveTwoBoneIK(
      rig.root,
      rig.rightUpperArm,
      rig.rightForearm,
      rig.rightHand,
      rig.rightGripContact,
      rig.rightHandContact,
      rig.rightArm.localToWorld(new THREE.Vector3(0.48, -0.18, -0.32))
    );
  }
  if (selection.leftFootToPedal ?? selection.footToPedal ?? true) {
    solveTwoBoneIK(
      rig.root,
      rig.leftThigh,
      rig.leftShin,
      rig.leftFoot,
      rig.leftPedalContact,
      rig.leftFootContact,
      rig.leftLeg.localToWorld(new THREE.Vector3(-0.16, -0.08, -0.62))
    );
    alignPedalFootOrientation(
      rig.root,
      rig.leftFoot,
      rig.leftFootContact,
      rig.leftPedalContact,
      rig.bicycleRoot
    );
  }
  if (selection.rightFootToPedal ?? selection.footToPedal ?? true) {
    solveTwoBoneIK(
      rig.root,
      rig.rightThigh,
      rig.rightShin,
      rig.rightFoot,
      rig.rightPedalContact,
      rig.rightFootContact,
      rig.rightLeg.localToWorld(new THREE.Vector3(0.16, -0.08, -0.62))
    );
    alignPedalFootOrientation(
      rig.root,
      rig.rightFoot,
      rig.rightFootContact,
      rig.rightPedalContact,
      rig.bicycleRoot
    );
  }
}

/** A rider walking on the bicycle's left side reaches the near (left) grip with the right hand. */
function enforceRightHandOnNearGrip(rig: ChaseRiderRig): void {
  solveTwoBoneIK(
    rig.root,
    rig.rightUpperArm,
    rig.rightForearm,
    rig.rightHand,
    rig.leftGripContact,
    rig.rightHandContact,
    rig.rightArm.localToWorld(new THREE.Vector3(0.22, -0.16, -0.38))
  );
}

export function measureChaseRiderContactError(rig: ChaseRiderRig): ChaseRiderContactError {
  rig.root.updateWorldMatrix(true, true);
  const leftHand = rig.leftHandContact.getWorldPosition(new THREE.Vector3());
  const rightHand = rig.rightHandContact.getWorldPosition(new THREE.Vector3());
  const leftGrip = rig.leftGripContact.getWorldPosition(new THREE.Vector3());
  const rightGrip = rig.rightGripContact.getWorldPosition(new THREE.Vector3());
  const leftFoot = rig.leftFootContact.getWorldPosition(new THREE.Vector3());
  const rightFoot = rig.rightFootContact.getWorldPosition(new THREE.Vector3());
  const leftPedal = rig.leftPedalContact.getWorldPosition(new THREE.Vector3());
  const rightPedal = rig.rightPedalContact.getWorldPosition(new THREE.Vector3());
  const leftHandToGripWorldUnits = leftHand.distanceTo(leftGrip);
  const rightHandToGripWorldUnits = rightHand.distanceTo(rightGrip);
  const rightHandToNearGripWorldUnits = rightHand.distanceTo(leftGrip);
  const leftFootToPedalWorldUnits = leftFoot.distanceTo(leftPedal);
  const rightFootToPedalWorldUnits = rightFoot.distanceTo(rightPedal);
  return {
    handToGripWorldUnits: Math.max(leftHandToGripWorldUnits, rightHandToGripWorldUnits),
    footToPedalWorldUnits: Math.max(leftFootToPedalWorldUnits, rightFootToPedalWorldUnits),
    leftHandToGripWorldUnits,
    rightHandToGripWorldUnits,
    rightHandToNearGripWorldUnits,
    leftFootToPedalWorldUnits,
    rightFootToPedalWorldUnits
  };
}

export function measureChaseRiderFootOrientationError(
  rig: ChaseRiderRig
): ChaseRiderFootOrientationError {
  rig.root.updateWorldMatrix(true, true);
  const bicycleWorldQuaternion = rig.bicycleRoot.getWorldQuaternion(new THREE.Quaternion());
  const bicycleUp = new THREE.Vector3(0, 1, 0).applyQuaternion(bicycleWorldQuaternion).normalize();
  const bicycleForward = new THREE.Vector3(0, 0, -1).applyQuaternion(bicycleWorldQuaternion).normalize();
  const leftFootQuaternion = rig.leftFoot.getWorldQuaternion(new THREE.Quaternion());
  const rightFootQuaternion = rig.rightFoot.getWorldQuaternion(new THREE.Quaternion());
  const leftUp = new THREE.Vector3(0, 1, 0).applyQuaternion(leftFootQuaternion).normalize();
  const rightUp = new THREE.Vector3(0, 1, 0).applyQuaternion(rightFootQuaternion).normalize();
  const leftForward = new THREE.Vector3(0, 0, -1).applyQuaternion(leftFootQuaternion).normalize();
  const rightForward = new THREE.Vector3(0, 0, -1).applyQuaternion(rightFootQuaternion).normalize();
  return {
    leftSoleTiltRadians: leftUp.angleTo(bicycleUp),
    rightSoleTiltRadians: rightUp.angleTo(bicycleUp),
    leftToeDirectionRadians: leftForward.angleTo(bicycleForward),
    rightToeDirectionRadians: rightForward.angleTo(bicycleForward)
  };
}

export function assertChaseRiderContactConstraints(
  rig: ChaseRiderRig,
  epsilon = CHASE_RIDER_CONTACT_EPSILON
): ChaseRiderContactError {
  const error = measureChaseRiderContactError(rig);
  if (error.handToGripWorldUnits > epsilon || error.footToPedalWorldUnits > epsilon) {
    throw new Error(
      `Rider contact constraint failed: hand=${error.handToGripWorldUnits.toFixed(8)}`
      + ` foot=${error.footToPedalWorldUnits.toFixed(8)} epsilon=${epsilon.toFixed(8)}`
    );
  }
  return error;
}

/**
 * Applies a deterministic named pose for transition-frame rendering.
 * The live chase keeps its existing explicit per-frame update order and only
 * consumes the shared node references returned by createChaseRiderRig().
 */
export function applyChaseRiderPose(
  rig: ChaseRiderRig,
  pose: ChaseRiderPoseName,
  options: ChaseRiderPoseOptions = {}
): void {
  applyChaseRiderControlPose(rig, pose, options);
  syncChaseHumanToRider(rig);
}

function applyChaseRiderControlPose(
  rig: ChaseRiderRig,
  pose: ChaseRiderPoseName,
  options: ChaseRiderPoseOptions = {}
): void {
  const progress = clamp01(options.progress ?? 1);
  const pedalPhase = options.pedalPhaseRadians ?? 0;
  const steering = options.steeringRadians ?? 0;
  resetChaseRiderRigPose(rig);

  if (pose === "ride" || pose === "brake" || pose === "pedal_press" || pose === "seated_balance" || pose === "leg_over") {
    rig.upperBody.rotation.x = -0.6;
  } else if (pose === "grip") {
    rig.upperBody.rotation.x = -0.6 * progress;
  } else if (pose === "left_foot_down" || pose === "dismount_leg_over") {
    rig.upperBody.rotation.x = -0.6 * (1 - progress);
  }

  if (pose === "ride") {
    setSymmetricShoulders(rig, RIDE_SHOULDER_X, RIDE_SHOULDER_Y, RIDE_SHOULDER_Z);
    rig.riderRoot.position.y = SEATED_RIDER_OFFSET_Y;
    rig.riderRoot.position.z = SEATED_RIDER_OFFSET_Z;
    rig.frontAssembly.rotation.y = steering;
    rig.leftArm.rotation.y = steering * 0.42;
    rig.rightArm.rotation.y = steering * 0.42;
    rig.crank.rotation.x = pedalPhase;
    // The crank contacts and two-bone IK own the complete hip-knee-foot chain.
    // Adding a second leg-root swing here produces a conflicting gait.
    enforceChaseRiderContactConstraints(rig);
    return;
  }

  if (pose === "stand_left") {
    rig.riderRoot.position.x = lerp(0, -0.58, progress);
    rig.riderRoot.position.y = lerp(0, STAND_RIDER_OFFSET_Y, progress);
    rig.riderRoot.position.z = lerp(0, 0.08, progress);
    rig.leftArm.rotation.x = lerp(-0.72, -0.34, progress);
    rig.rightArm.rotation.x = lerp(-0.72, -0.5, progress);
    rig.leftLeg.rotation.x = lerp(0, 0.08, progress);
    rig.rightLeg.rotation.x = lerp(0, -0.08, progress);
    return;
  }

  if (pose === "stand_with_bike") {
    rig.riderRoot.position.set(-0.58, STAND_RIDER_OFFSET_Y, -0.24);
    rig.leftArm.rotation.set(-0.2, 0, -0.08);
    rig.rightArm.position.set(DEFAULT_SHOULDER_X, 1.74, -0.16);
    rig.rightArm.rotation.set(-0.5, 0, 0.04);
    rig.leftLeg.rotation.x = 0.04;
    rig.rightLeg.rotation.x = -0.04;
    enforceRightHandOnNearGrip(rig);
    return;
  }

  if (pose === "grip") {
    setSymmetricShoulders(
      rig,
      lerp(DEFAULT_SHOULDER_X, RIDE_SHOULDER_X, progress),
      lerp(DEFAULT_SHOULDER_Y, RIDE_SHOULDER_Y, progress),
      lerp(0.02, RIDE_SHOULDER_Z, progress)
    );
    rig.riderRoot.position.x = lerp(-0.58, -0.08, clamp01(progress / 0.48));
    rig.riderRoot.position.y = lerp(STAND_RIDER_OFFSET_Y, -0.22, progress);
    rig.riderRoot.position.z = lerp(0.08, SEATED_RIDER_OFFSET_Z, progress);
    rig.leftArm.rotation.x = lerp(-0.34, -0.72, progress);
    rig.rightArm.rotation.x = lerp(-0.5, -0.72, progress);
    enforceChaseRiderContactConstraints(rig, {
      handToGrip: false,
      footToPedal: false,
      leftHandToGrip: true,
      rightHandToGrip: progress >= 0.48
    });
    return;
  }

  if (pose === "leg_over") {
    setSymmetricShoulders(
      rig,
      lerp(DEFAULT_SHOULDER_X, RIDE_SHOULDER_X, progress),
      lerp(DEFAULT_SHOULDER_Y, RIDE_SHOULDER_Y, progress),
      lerp(0.02, RIDE_SHOULDER_Z, progress)
    );
    rig.riderRoot.position.x = lerp(-0.08, 0, progress);
    rig.riderRoot.position.y = lerp(-0.22, SEATED_RIDER_OFFSET_Y, progress);
    rig.riderRoot.position.z = lerp(0.08, SEATED_RIDER_OFFSET_Z, progress);
    rig.rightThigh.rotation.set(lerp(0, 0.82, progress), 0, lerp(0, -0.22, progress));
    rig.rightShin.rotation.set(lerp(0, -1.35, progress), 0, lerp(0, 0.08, progress));
    rig.leftThigh.rotation.x = lerp(0, 0.08, progress);
    enforceChaseRiderContactConstraints(rig, { handToGrip: true, footToPedal: false });
    return;
  }

  if (pose === "seated_balance") {
    setSymmetricShoulders(rig, RIDE_SHOULDER_X, RIDE_SHOULDER_Y, RIDE_SHOULDER_Z);
    rig.riderRoot.position.x = lerp(-0.08, 0, progress);
    rig.riderRoot.position.y = SEATED_RIDER_OFFSET_Y;
    rig.riderRoot.position.z = SEATED_RIDER_OFFSET_Z;
    rig.leftThigh.rotation.set(0.08, 0, 0);
    rig.rightThigh.rotation.set(0.82, 0, -0.22);
    rig.rightShin.rotation.set(-1.35, 0, 0.08);
    const startLeftThigh = rig.leftThigh.quaternion.clone();
    const startLeftShin = rig.leftShin.quaternion.clone();
    const startRightThigh = rig.rightThigh.quaternion.clone();
    const startRightShin = rig.rightShin.quaternion.clone();
    enforceChaseRiderContactConstraints(rig);
    const targetLeftThigh = rig.leftThigh.quaternion.clone();
    const targetLeftShin = rig.leftShin.quaternion.clone();
    const targetRightThigh = rig.rightThigh.quaternion.clone();
    const targetRightShin = rig.rightShin.quaternion.clone();
    rig.leftThigh.quaternion.copy(startLeftThigh).slerp(targetLeftThigh, progress);
    rig.leftShin.quaternion.copy(startLeftShin).slerp(targetLeftShin, progress);
    rig.rightThigh.quaternion.copy(startRightThigh).slerp(targetRightThigh, progress);
    rig.rightShin.quaternion.copy(startRightShin).slerp(targetRightShin, progress);
    return;
  }

  if (pose === "pedal_press") {
    setSymmetricShoulders(rig, RIDE_SHOULDER_X, RIDE_SHOULDER_Y, RIDE_SHOULDER_Z);
    rig.riderRoot.position.y = SEATED_RIDER_OFFSET_Y;
    rig.riderRoot.position.z = SEATED_RIDER_OFFSET_Z;
    rig.crank.rotation.x = lerp(0, -Math.PI / 4, progress);
    rig.leftLeg.rotation.x = lerp(0, 0.42, progress);
    rig.rightLeg.rotation.x = lerp(0, -0.48, progress);
    enforceChaseRiderContactConstraints(rig);
    return;
  }

  if (pose === "brake") {
    setSymmetricShoulders(rig, RIDE_SHOULDER_X, RIDE_SHOULDER_Y, RIDE_SHOULDER_Z);
    rig.riderRoot.position.y = SEATED_RIDER_OFFSET_Y;
    rig.riderRoot.position.z = SEATED_RIDER_OFFSET_Z;
    rig.crank.rotation.x = pedalPhase;
    rig.rightBrakeLever.rotation.z = lerp(-0.38, -0.68, progress);
    rig.rightArm.rotation.x = lerp(-0.72, -0.78, progress);
    enforceChaseRiderContactConstraints(rig);
    return;
  }

  if (pose === "left_foot_down") {
    setSymmetricShoulders(rig, RIDE_SHOULDER_X, RIDE_SHOULDER_Y, RIDE_SHOULDER_Z);
    rig.riderRoot.position.x = lerp(0, -0.12, progress);
    rig.riderRoot.position.y = lerp(SEATED_RIDER_OFFSET_Y, -0.38, progress);
    rig.riderRoot.position.z = lerp(SEATED_RIDER_OFFSET_Z, 0.08, progress);
    rig.leftThigh.rotation.x = lerp(0, 0.08, progress);
    rig.leftShin.rotation.x = lerp(0, -0.06, progress);
    enforceChaseRiderContactConstraints(rig, {
      handToGrip: true,
      footToPedal: false,
      rightFootToPedal: true
    });
    return;
  }

  if (pose === "dismount_leg_over") {
    const crossPhase = clamp01(progress / 0.58);
    const landingPhase = clamp01((progress - 0.58) / 0.42);
    rig.riderRoot.position.x = progress < 0.58
      ? lerp(-0.12, -0.18, crossPhase)
      : lerp(-0.18, -0.58, landingPhase);
    rig.riderRoot.position.y = lerp(-0.38, STAND_RIDER_OFFSET_Y, progress);
    rig.riderRoot.position.z = lerp(0.08, -0.24, progress);
    rig.leftThigh.rotation.x = 0.06;

    if (progress < 0.58) {
      setSymmetricShoulders(rig, RIDE_SHOULDER_X, RIDE_SHOULDER_Y, RIDE_SHOULDER_Z);
      enforceChaseRiderContactConstraints(rig, {
        handToGrip: true,
        footToPedal: false,
        rightFootToPedal: true
      });
      const pedalThigh = rig.rightThigh.quaternion.clone();
      const pedalShin = rig.rightShin.quaternion.clone();
      const peakThigh = new THREE.Quaternion().setFromEuler(new THREE.Euler(0.82, 0, -0.22));
      const peakShin = new THREE.Quaternion().setFromEuler(new THREE.Euler(-1.35, 0, 0.08));
      rig.rightThigh.quaternion.copy(pedalThigh).slerp(peakThigh, crossPhase);
      rig.rightShin.quaternion.copy(pedalShin).slerp(peakShin, crossPhase);
    } else {
      rig.leftArm.rotation.set(-0.2, 0, -0.08);
      rig.rightArm.position.set(DEFAULT_SHOULDER_X, 1.74, -0.16);
      rig.rightArm.rotation.set(-0.5, 0, 0.04);
      const peakThigh = new THREE.Quaternion().setFromEuler(new THREE.Euler(0.82, 0, -0.22));
      const peakShin = new THREE.Quaternion().setFromEuler(new THREE.Euler(-1.35, 0, 0.08));
      rig.rightThigh.quaternion.copy(peakThigh).slerp(new THREE.Quaternion(), landingPhase);
      rig.rightShin.quaternion.copy(peakShin).slerp(new THREE.Quaternion(), landingPhase);
      enforceRightHandOnNearGrip(rig);
    }
    return;
  }

  if (pose === "push_bike") {
    rig.riderRoot.position.x = -0.58;
    rig.riderRoot.position.y = STAND_RIDER_OFFSET_Y;
    rig.riderRoot.position.z = -0.24;
    rig.leftArm.rotation.x = -0.2;
    rig.leftArm.rotation.z = -0.08;
    rig.rightArm.position.set(DEFAULT_SHOULDER_X, 1.74, -0.16);
    rig.rightArm.rotation.set(-0.5, 0, 0.04);
    rig.leftLeg.rotation.x = Math.sin(progress * Math.PI) * 0.2;
    rig.rightLeg.rotation.x = -Math.sin(progress * Math.PI) * 0.2;
    rig.bicycleRoot.rotation.z = Math.sin(progress * Math.PI) * 0.012;
    enforceRightHandOnNearGrip(rig);
    return;
  }

  rig.riderRoot.position.x = -0.58;
  rig.riderRoot.position.y = STAND_RIDER_OFFSET_Y;
  rig.leftArm.rotation.x = -0.56;
  rig.rightArm.rotation.x = -0.62;
  rig.leftLeg.rotation.x = Math.sin(progress * Math.PI) * 0.34;
  rig.rightLeg.rotation.x = -Math.sin(progress * Math.PI) * 0.34;
  rig.bicycleRoot.rotation.z = Math.sin(progress * Math.PI) * 0.025;
}
