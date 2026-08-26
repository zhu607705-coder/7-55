import * as THREE from "three";
import { mergeGeometries } from "three/examples/jsm/utils/BufferGeometryUtils.js";
import { ThreePrimitiveCache, type ThreeFlatMaterial } from "../ThreePrimitiveCache";

export const CHASE_RIDER_DISPLAY_SCALE = 1.28;
export const CHASE_RIDER_WHEEL_RADIUS = 0.5;
export const CHASE_RIDER_GEAR_RATIO = 2.6;
export const CHASE_RIDER_CONTACT_EPSILON = 0.00001;

const LEFT_HAND_BASE_POSITION = Object.freeze({ x: 0, y: -0.31, z: -0.04 });
const RIGHT_HAND_BASE_POSITION = Object.freeze({ x: 0, y: -0.31, z: -0.04 });
const LEFT_FOOT_BASE_POSITION = Object.freeze({ x: 0, y: -0.42, z: 0.02 });
const RIGHT_FOOT_BASE_POSITION = Object.freeze({ x: 0, y: -0.42, z: 0.02 });
// The standing offset is derived from the authored hip, two-bone leg and shoe
// contact lengths so both soles meet the same ground plane as the wheels.
const STAND_RIDER_OFFSET_Y = -0.44;
const SEATED_RIDER_OFFSET_Y = -0.08;
const SEATED_RIDER_OFFSET_Z = 0.04;
const DEFAULT_SHOULDER_X = 0.28;
const DEFAULT_SHOULDER_Y = 1.84;
const RIDE_SHOULDER_X = 0.3;
const RIDE_SHOULDER_Y = 1.67;
const RIDE_SHOULDER_Z = -0.22;
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
  outline: 0x17232b,
  blue: 0x315f9f,
  blueDark: 0x234672,
  cyan: 0x6bbec8,
  white: 0xf1ead7,
  skin: 0xf4b781,
  hair: 0x252a31,
  metal: 0x68757a,
  shadow: 0x253128
});

export interface ChaseRiderRig {
  root: THREE.Group;
  /** Compatibility alias retained for the live chase renderer. */
  group: THREE.Group;
  bicycleRoot: THREE.Group;
  riderRoot: THREE.Group;
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
  const spokeCount = 16;
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
  const shadow = new THREE.Mesh(
    primitives.plane(width, depth),
    rigMaterial(primitives, palette.shadow, {
      unlit: true,
      opacity: 0.34,
      depthWrite: false
    })
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
export function createChaseRiderRig(
  primitives: ThreePrimitiveCache,
  palette: ChaseRiderRigPalette = DEFAULT_CHASE_RIDER_RIG_PALETTE
): ChaseRiderRig {
  const root = new THREE.Group();
  root.name = "canteen-chase-player";

  const bicycleRoot = new THREE.Group();
  bicycleRoot.name = "canteen-chase-bicycle-root";
  setIdentityTransform(bicycleRoot);

  const riderRoot = new THREE.Group();
  riderRoot.name = "canteen-chase-rider-root";
  setIdentityTransform(riderRoot);

  root.add(rigShadow(primitives, palette, 1.45, 2.2), bicycleRoot, riderRoot);

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
    tubeGeometry(primitives, new THREE.Vector3(0, 0.98, 0.04), new THREE.Vector3(0, 1.19, -0.02), 0.06, 12),
    curveTubeGeometry([
      new THREE.Vector3(0, 1.18, -0.02),
      new THREE.Vector3(-0.2, 1.22, -0.07),
      new THREE.Vector3(-0.43, 1.27, -0.09),
      new THREE.Vector3(-0.58, 1.23, -0.05)
    ], 0.047, 22, 10),
    curveTubeGeometry([
      new THREE.Vector3(0, 1.18, -0.02),
      new THREE.Vector3(0.2, 1.22, -0.07),
      new THREE.Vector3(0.43, 1.27, -0.09),
      new THREE.Vector3(0.58, 1.23, -0.05)
    ], 0.047, 22, 10),
    tubeGeometry(primitives, forkCrownLeft, forkDropoutLeft, 0.047, 12),
    tubeGeometry(primitives, forkCrownRight, forkDropoutRight, 0.047, 12),
    transformGeometry(primitives.box(0.2, 0.08, 0.18), {
      position: [0, 0.98, -0.02]
    })
  ], { shading: "standard", roughness: 0.45, metalness: 0.42, flatShading: false });
  frontAssemblyBody.name = "canteen-chase-front-assembly-body";

  const leftGrip = new THREE.Group();
  leftGrip.name = "canteen-chase-left-grip";
  leftGrip.position.set(-0.64, 1.22, -0.04);
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
  rightGrip.position.set(0.64, 1.22, -0.04);
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
      position: [-0.37, 1.29, -0.12],
      scale: [1, 0.72, 1]
    }),
    transformGeometry(primitives.cylinder(0.018, 0.018, 0.09, 10), {
      position: [-0.29, 1.27, -0.12],
      rotation: [0, 0, Math.PI / 2]
    })
  ], { shading: "standard", roughness: 0.16, metalness: 0.94, flatShading: false });

  const rightBrakeLever = new THREE.Group();
  rightBrakeLever.name = "canteen-chase-right-brake-lever";
  rightBrakeLever.position.set(0.54, 1.19, -0.13);
  rightBrakeLever.rotation.z = -0.38;
  rightBrakeLever.add(
    rigMergedMesh(primitives, palette.metal, [
      tubeGeometry(primitives, new THREE.Vector3(0, 0.02, 0), new THREE.Vector3(0, -0.26, 0), 0.02, 8),
      transformGeometry(primitives.sphere(0.03, 8, 6), {
        position: [0, 0.03, 0]
      })
    ], { shading: "standard", roughness: 0.28, metalness: 0.82, flatShading: false })
  );

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
    basket,
    frontFender
  );
  bicycleRoot.add(rearWheel, frontAssembly);

  const frame = new THREE.Group();
  frame.name = "canteen-chase-blue-frame";
  const seatTop = new THREE.Vector3(0, 1.18, 0.44);
  const headJoint = new THREE.Vector3(0, 1.02, -0.54);
  const bottomBracket = new THREE.Vector3(0, 0.84, 0.14);
  const stepThroughJoint = new THREE.Vector3(0, 0.77, -0.08);
  const rearAxleLeft = new THREE.Vector3(-0.09, 0.52, 0.72);
  const rearAxleRight = new THREE.Vector3(0.09, 0.52, 0.72);
  frame.add(
    rigMergedMesh(primitives, palette.blue, [
      curveTubeGeometry([headJoint, new THREE.Vector3(0, 0.9, -0.33), stepThroughJoint, bottomBracket], 0.064, 28, 12),
      curveTubeGeometry([headJoint, new THREE.Vector3(0, 0.78, -0.18), new THREE.Vector3(0, 0.72, 0.12), seatTop], 0.046, 30, 12),
      tubeGeometry(primitives, seatTop, bottomBracket, 0.06, 12),
      tubeGeometry(primitives, new THREE.Vector3(-0.05, 0.86, 0.18), rearAxleLeft, 0.042, 10),
      tubeGeometry(primitives, new THREE.Vector3(0.05, 0.86, 0.18), rearAxleRight, 0.042, 10),
      tubeGeometry(primitives, new THREE.Vector3(-0.02, 1.14, 0.39), rearAxleLeft, 0.034, 10),
      tubeGeometry(primitives, new THREE.Vector3(0.02, 1.14, 0.39), rearAxleRight, 0.034, 10),
      transformGeometry(primitives.capsule(0.07, 0.38, 6, 12), {
        position: [0, 1.31, 0.48],
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
    tubeGeometry(primitives, new THREE.Vector3(0.18, 0.82, 0.2), new THREE.Vector3(0.34, 0.08, 0.54), 0.024, 10),
    transformGeometry(primitives.capsule(0.028, 0.1, 4, 8), {
      position: [0.35, 0.07, 0.55],
      rotation: [0, 0, Math.PI / 2]
    })
  ], { shading: "standard", roughness: 0.34, metalness: 0.82, flatShading: false });
  kickstand.name = "canteen-chase-kickstand";
  bicycleRoot.add(rearFender, rearRack, rearReflector, kickstand);

  const crank = new THREE.Group();
  crank.name = "canteen-chase-crank";
  crank.position.set(0, 0.84, 0.14);
  const crankBody = rigMergedMesh(primitives, palette.metal, [
    transformGeometry(primitives.cylinder(0.08, 0.08, 0.44, 14), {
      rotation: [0, 0, Math.PI / 2]
    }),
    transformGeometry(primitives.torus(0.21, 0.026, 10, 38), {
      rotation: [0, Math.PI / 2, 0],
      position: [-0.03, 0, 0]
    }),
    tubeGeometry(primitives, new THREE.Vector3(0.12, -0.02, 0), new THREE.Vector3(0.28, -0.34, 0), 0.025, 8),
    tubeGeometry(primitives, new THREE.Vector3(-0.12, 0.02, 0), new THREE.Vector3(-0.28, 0.34, 0), 0.025, 8),
    tubeGeometry(primitives, new THREE.Vector3(-0.03, 0, 0), new THREE.Vector3(-0.23, 0.07, 0), 0.018, 6),
    tubeGeometry(primitives, new THREE.Vector3(-0.03, 0, 0), new THREE.Vector3(-0.23, -0.07, 0), 0.018, 6),
    tubeGeometry(primitives, new THREE.Vector3(-0.03, 0, 0), new THREE.Vector3(-0.1, 0.22, 0), 0.018, 6),
    tubeGeometry(primitives, new THREE.Vector3(-0.03, 0, 0), new THREE.Vector3(-0.1, -0.22, 0), 0.018, 6)
  ], { shading: "standard", roughness: 0.24, metalness: 0.88, flatShading: false });
  const rightPedal = new THREE.Group();
  rightPedal.name = "canteen-chase-right-pedal";
  rightPedal.position.set(0.3, -0.34, 0);
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
  leftPedal.position.set(-0.3, 0.34, 0);
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
      tubeGeometry(primitives, new THREE.Vector3(-0.2, 0.68, 0.16), new THREE.Vector3(-0.2, 0.58, 0.72), 0.012, 8),
      tubeGeometry(primitives, new THREE.Vector3(-0.2, 1, 0.16), new THREE.Vector3(-0.2, 0.72, 0.72), 0.012, 8),
      transformGeometry(primitives.torus(0.105, 0.012, 8, 30), {
        position: [-0.2, 0.65, 0.72],
        rotation: [0, Math.PI / 2, 0]
      })
    ], { shading: "standard", roughness: 0.34, metalness: 0.78, flatShading: false })
  );
  const chainGuard = rigMergedMesh(primitives, palette.blue, [
    transformGeometry(primitives.capsule(0.095, 0.52, 8, 16), {
      position: [-0.23, 0.78, 0.4],
      rotation: [Math.PI / 2, 0, 0],
      scale: [0.72, 1, 0.9]
    }),
    transformGeometry(primitives.cylinder(0.23, 0.23, 0.055, 24), {
      position: [-0.23, 0.84, 0.14],
      rotation: [0, 0, Math.PI / 2]
    })
  ], { shading: "standard", roughness: 0.34, metalness: 0.48, flatShading: false });
  chainGuard.name = "canteen-chase-chain-guard";
  bicycleRoot.add(chain);
  bicycleRoot.add(chainGuard);

  const torso = rigMergedMesh(primitives, palette.blueDark, [
    transformGeometry(primitives.capsule(0.145, 0.4, 10, 20), {
      position: [0, 1.61, 0.105],
      rotation: [-0.055, 0, 0],
      scale: [1.64, 1.03, 0.94]
    }),
    transformGeometry(primitives.capsule(0.105, 0.17, 9, 18), {
      position: [0, 1.325, 0.115],
      rotation: [-0.02, 0, 0],
      scale: [1.92, 1, 0.92]
    })
  ], { shading: "standard", roughness: 0.76, metalness: 0.03, flatShading: false });
  torso.name = "canteen-chase-player-jacket-shell";

  const shirt = rigMergedMesh(primitives, palette.white, [
    transformGeometry(primitives.capsule(0.105, 0.38, 10, 20), {
      position: [0, 1.615, -0.085],
      rotation: [-0.06, 0, 0],
      scale: [1.02, 1.02, 0.28]
    }),
    transformGeometry(primitives.cylinder(0.079, 0.095, 0.065, 20), {
      position: [0, 1.895, -0.082],
      scale: [1.12, 1, 0.45]
    }),
    tubeGeometry(primitives, new THREE.Vector3(0, 1.37, -0.125), new THREE.Vector3(0, 1.78, -0.128), 0.008, 8)
  ], { shading: "standard", roughness: 0.96, metalness: 0, flatShading: false });
  shirt.name = "canteen-chase-player-light-shirt";

  const jacketPanels = rigMergedMesh(primitives, palette.blue, [
    extrudedPanelGeometry([
      [-0.045, 1.875], [-0.178, 1.935], [-0.288, 1.785],
      [-0.278, 1.34], [-0.222, 1.286], [-0.098, 1.302], [-0.07, 1.736]
    ], -0.136, 0.058),
    extrudedPanelGeometry([
      [0.045, 1.875], [0.07, 1.736], [0.098, 1.302],
      [0.222, 1.286], [0.278, 1.34], [0.288, 1.785], [0.178, 1.935]
    ], -0.136, 0.058)
  ], { shading: "standard", roughness: 0.68, metalness: 0.04, flatShading: false });
  jacketPanels.name = "canteen-chase-player-open-jacket";

  const jacketTrim = rigMergedMesh(primitives, 0x4e78a1, [
    tubeGeometry(primitives, new THREE.Vector3(-0.084, 1.304, -0.143), new THREE.Vector3(-0.074, 1.735, -0.143), 0.01, 10),
    tubeGeometry(primitives, new THREE.Vector3(0.084, 1.304, -0.143), new THREE.Vector3(0.074, 1.735, -0.143), 0.01, 10),
    tubeGeometry(primitives, new THREE.Vector3(-0.178, 1.91, -0.142), new THREE.Vector3(-0.05, 1.84, -0.151), 0.015, 10),
    tubeGeometry(primitives, new THREE.Vector3(0.178, 1.91, -0.142), new THREE.Vector3(0.05, 1.84, -0.151), 0.015, 10),
    curveTubeGeometry([
      new THREE.Vector3(-0.242, 1.3, -0.136),
      new THREE.Vector3(-0.17, 1.285, -0.144),
      new THREE.Vector3(-0.092, 1.295, -0.146)
    ], 0.011, 12, 8),
    curveTubeGeometry([
      new THREE.Vector3(0.092, 1.295, -0.146),
      new THREE.Vector3(0.17, 1.285, -0.144),
      new THREE.Vector3(0.242, 1.3, -0.136)
    ], 0.011, 12, 8),
    tubeGeometry(primitives, new THREE.Vector3(-0.255, 1.535, -0.142), new THREE.Vector3(-0.155, 1.495, -0.148), 0.007, 8),
    tubeGeometry(primitives, new THREE.Vector3(0.155, 1.495, -0.148), new THREE.Vector3(0.255, 1.535, -0.142), 0.007, 8)
  ], { shading: "standard", roughness: 0.64, metalness: 0.03, flatShading: false });
  jacketTrim.name = "canteen-chase-player-jacket-trim";

  const head = rigMergedMesh(primitives, palette.skin, [
    transformGeometry(primitives.cylinder(0.069, 0.076, 0.105, 20), {
      position: [0, 1.992, 0.045]
    }),
    stylizedHeadGeometry(primitives),
    transformGeometry(primitives.sphere(0.04, 18, 14), {
      position: [-0.229, 2.213, 0.014],
      scale: [0.58, 1.02, 0.7]
    }),
    transformGeometry(primitives.sphere(0.04, 18, 14), {
      position: [0.229, 2.213, 0.014],
      scale: [0.58, 1.02, 0.7]
    })
  ], { shading: "standard", roughness: 0.92, metalness: 0, flatShading: false });
  head.name = "canteen-chase-player-face";

  const eyeWhites = rigMergedMesh(primitives, 0xf8f1e7, [
    transformGeometry(primitives.capsule(0.016, 0.068, 10, 18), {
      position: [-0.083, 2.229, -0.176],
      rotation: [0, 0, Math.PI / 2],
      scale: [0.98, 0.68, 0.14]
    }),
    transformGeometry(primitives.capsule(0.016, 0.068, 10, 18), {
      position: [0.083, 2.229, -0.176],
      rotation: [0, 0, Math.PI / 2],
      scale: [0.98, 0.68, 0.14]
    })
  ], { shading: "standard", roughness: 0.72, metalness: 0, flatShading: false });
  eyeWhites.name = "canteen-chase-player-eye-whites";

  const irises = rigMergedMesh(primitives, 0x2a211d, [
    transformGeometry(primitives.sphere(0.019, 20, 16), {
      position: [-0.073, 2.227, -0.184],
      scale: [0.78, 1, 0.18]
    }),
    transformGeometry(primitives.sphere(0.019, 20, 16), {
      position: [0.073, 2.227, -0.184],
      scale: [0.78, 1, 0.18]
    })
  ], { shading: "standard", roughness: 0.56, metalness: 0.01, flatShading: false });
  irises.name = "canteen-chase-player-irises";

  const faceLinework = rigMergedMesh(primitives, 0x342925, [
    curveTubeGeometry([
      new THREE.Vector3(-0.138, 2.294, -0.17),
      new THREE.Vector3(-0.086, 2.307, -0.176),
      new THREE.Vector3(-0.03, 2.301, -0.172)
    ], 0.008, 12, 10),
    curveTubeGeometry([
      new THREE.Vector3(0.03, 2.301, -0.172),
      new THREE.Vector3(0.086, 2.307, -0.176),
      new THREE.Vector3(0.138, 2.294, -0.17)
    ], 0.008, 12, 10),
    curveTubeGeometry([
      new THREE.Vector3(-0.124, 2.24, -0.182),
      new THREE.Vector3(-0.083, 2.248, -0.186),
      new THREE.Vector3(-0.04, 2.24, -0.183)
    ], 0.0048, 10, 8),
    curveTubeGeometry([
      new THREE.Vector3(0.04, 2.24, -0.183),
      new THREE.Vector3(0.083, 2.248, -0.186),
      new THREE.Vector3(0.124, 2.24, -0.182)
    ], 0.0048, 10, 8),
    curveTubeGeometry([
      new THREE.Vector3(-0.024, 2.094, -0.175),
      new THREE.Vector3(0, 2.089, -0.178),
      new THREE.Vector3(0.024, 2.094, -0.175)
    ], 0.0032, 10, 8)
  ], { shading: "standard", roughness: 0.7, metalness: 0, flatShading: false });
  faceLinework.name = "canteen-chase-player-brows-mouth";

  const eyeHighlights = rigMergedMesh(primitives, 0xffffff, [
    transformGeometry(primitives.sphere(0.0044, 12, 10), { position: [-0.079, 2.233, -0.189] }),
    transformGeometry(primitives.sphere(0.0044, 12, 10), { position: [0.069, 2.233, -0.189] })
  ], { shading: "standard", roughness: 0.28, metalness: 0, flatShading: false });
  eyeHighlights.name = "canteen-chase-player-eye-highlights";

  const noseAccent = rigMergedMesh(primitives, 0xe1a36f, [
    transformGeometry(primitives.sphere(0.014, 18, 14), {
      position: [0, 2.158, -0.181],
      scale: [0.42, 0.82, 0.3]
    })
  ], { shading: "standard", roughness: 0.94, metalness: 0, flatShading: false });
  noseAccent.name = "canteen-chase-player-nose-accent";

  const hairBase = rigMergedMesh(primitives, 0x2c333c, [
    transformGeometry(primitives.sphere(0.235, 40, 30), {
      position: [0, 2.392, 0.06],
      scale: [0.98, 0.8, 0.88]
    }),
    transformGeometry(primitives.sphere(0.205, 34, 26), {
      position: [0, 2.332, 0.148],
      scale: [1.06, 1.02, 0.94]
    }),
    transformGeometry(primitives.icosahedron(0.105, 3), {
      position: [-0.162, 2.45, 0.02],
      rotation: [0.12, 0.08, -0.28],
      scale: [1.04, 0.74, 0.88]
    }),
    transformGeometry(primitives.icosahedron(0.112, 3), {
      position: [-0.058, 2.492, 0.012],
      rotation: [0.18, 0.05, -0.1],
      scale: [1, 0.76, 0.84]
    }),
    transformGeometry(primitives.icosahedron(0.108, 3), {
      position: [0.056, 2.492, 0.014],
      rotation: [0.12, -0.04, 0.06],
      scale: [1, 0.76, 0.86]
    }),
    transformGeometry(primitives.icosahedron(0.102, 3), {
      position: [0.168, 2.45, 0.03],
      rotation: [0.08, -0.06, 0.24],
      scale: [1.02, 0.76, 0.88]
    }),
    transformGeometry(primitives.icosahedron(0.082, 3), {
      position: [-0.204, 2.306, 0.075],
      rotation: [0.06, 0.08, -0.16],
      scale: [0.68, 1.1, 0.76]
    }),
    transformGeometry(primitives.icosahedron(0.078, 3), {
      position: [0.206, 2.31, 0.078],
      rotation: [0.05, -0.06, 0.14],
      scale: [0.66, 1.08, 0.74]
    }),
    transformGeometry(primitives.icosahedron(0.095, 3), {
      position: [-0.11, 2.276, 0.212],
      rotation: [0.18, 0.05, -0.12],
      scale: [0.86, 1.02, 0.7]
    }),
    transformGeometry(primitives.icosahedron(0.1, 3), {
      position: [0, 2.262, 0.222],
      rotation: [0.12, 0, 0.02],
      scale: [0.96, 1.02, 0.72]
    }),
    transformGeometry(primitives.icosahedron(0.09, 3), {
      position: [0.114, 2.28, 0.212],
      rotation: [0.16, -0.05, 0.15],
      scale: [0.84, 1, 0.7]
    })
  ], { shading: "standard", roughness: 0.72, metalness: 0.01, flatShading: false });
  hairBase.name = "canteen-chase-player-layered-hair";

  const hairStrandParts: THREE.BufferGeometry[] = [];
  const fringe = [
    [-0.18, 2.344, -0.162, -0.38, 0.044, 0.15],
    [-0.106, 2.36, -0.175, -0.24, 0.046, 0.16],
    [-0.022, 2.372, -0.182, -0.08, 0.042, 0.145],
    [0.05, 2.382, -0.178, 0.13, 0.039, 0.12],
    [0.118, 2.364, -0.17, 0.28, 0.043, 0.14],
    [0.182, 2.338, -0.152, 0.42, 0.04, 0.145]
  ] as const;
  fringe.forEach(([x, y, z, tilt, radius, height], index) => {
    hairStrandParts.push(transformGeometry(primitives.icosahedron(1, 2), {
      position: [x, y, z],
      rotation: [index % 2 === 0 ? -0.08 : 0.06, 0, tilt],
      scale: [radius * 0.86, height * 0.53, radius * 0.48]
    }));
  });
  hairStrandParts.push(
    transformGeometry(primitives.icosahedron(1, 2), {
      position: [-0.224, 2.334, -0.1],
      rotation: [0.06, 0, -0.52],
      scale: [0.034, 0.07, 0.024]
    }),
    transformGeometry(primitives.icosahedron(1, 2), {
      position: [0.226, 2.338, -0.094],
      rotation: [-0.06, 0, 0.48],
      scale: [0.032, 0.068, 0.023]
    }),
    transformGeometry(primitives.icosahedron(1, 2), {
      position: [-0.136, 2.518, 0.072],
      rotation: [0.2, 0.08, -0.72],
      scale: [0.035, 0.078, 0.032]
    }),
    transformGeometry(primitives.icosahedron(1, 2), {
      position: [0.14, 2.51, 0.078],
      rotation: [0.18, -0.06, 0.58],
      scale: [0.033, 0.074, 0.03]
    }),
    transformGeometry(primitives.icosahedron(1, 2), {
      position: [0.008, 2.552, 0.098],
      rotation: [0.12, 0, 0.12],
      scale: [0.024, 0.055, 0.022]
    }),
    transformGeometry(primitives.icosahedron(1, 2), {
      position: [-0.14, 2.34, 0.29],
      rotation: [0.08, 0.12, -0.22],
      scale: [0.07, 0.11, 0.045]
    }),
    transformGeometry(primitives.icosahedron(1, 2), {
      position: [-0.045, 2.3, 0.315],
      rotation: [0.04, 0.05, -0.08],
      scale: [0.076, 0.12, 0.044]
    }),
    transformGeometry(primitives.icosahedron(1, 2), {
      position: [0.055, 2.305, 0.315],
      rotation: [0.04, -0.04, 0.1],
      scale: [0.076, 0.118, 0.044]
    }),
    transformGeometry(primitives.icosahedron(1, 2), {
      position: [0.145, 2.345, 0.285],
      rotation: [0.08, -0.1, 0.22],
      scale: [0.068, 0.105, 0.043]
    })
  );
  const hairStrands = rigMergedMesh(primitives, 0x20252c, hairStrandParts, {
    shading: "standard",
    roughness: 0.68,
    metalness: 0.01,
    flatShading: false
  });
  hairStrands.name = "canteen-chase-player-hair-strands";

  const hairHighlights = rigMergedMesh(primitives, 0x51565e, [
    curveTubeGeometry([
      new THREE.Vector3(-0.155, 2.515, -0.075),
      new THREE.Vector3(-0.1, 2.565, -0.09),
      new THREE.Vector3(-0.045, 2.58, -0.08)
    ], 0.008, 16, 8),
    curveTubeGeometry([
      new THREE.Vector3(-0.01, 2.585, -0.078),
      new THREE.Vector3(0.05, 2.57, -0.088),
      new THREE.Vector3(0.11, 2.53, -0.078)
    ], 0.007, 16, 8),
    curveTubeGeometry([
      new THREE.Vector3(0.13, 2.49, -0.11),
      new THREE.Vector3(0.16, 2.455, -0.135),
      new THREE.Vector3(0.18, 2.405, -0.15)
    ], 0.006, 14, 8),
    curveTubeGeometry([
      new THREE.Vector3(-0.13, 2.43, 0.308),
      new THREE.Vector3(-0.04, 2.46, 0.325),
      new THREE.Vector3(0.05, 2.45, 0.326)
    ], 0.007, 16, 8)
  ], { shading: "standard", roughness: 0.62, metalness: 0.02, flatShading: false });
  hairHighlights.name = "canteen-chase-player-hair-highlights";

  const pantsWaist = rigMergedMesh(primitives, palette.outline, [
    transformGeometry(primitives.capsule(0.11, 0.19, 10, 20), {
      position: [0, 1.235, 0.1],
      rotation: [0, 0, Math.PI / 2],
      scale: [1, 0.72, 0.92]
    }),
    transformGeometry(primitives.capsule(0.052, 0.18, 8, 16), {
      position: [0, 1.19, 0.025],
      rotation: [0, 0, Math.PI / 2],
      scale: [0.82, 0.62, 0.7]
    })
  ], { shading: "standard", roughness: 0.8, metalness: 0.02, flatShading: false });
  pantsWaist.name = "canteen-chase-player-pants-waist";

  const pantsDetail = rigMergedMesh(primitives, 0x39414a, [
    curveTubeGeometry([
      new THREE.Vector3(-0.18, 1.26, -0.002),
      new THREE.Vector3(0, 1.245, -0.018),
      new THREE.Vector3(0.18, 1.26, -0.002)
    ], 0.007, 16, 8),
    tubeGeometry(primitives, new THREE.Vector3(0, 1.245, -0.02), new THREE.Vector3(0, 1.16, -0.03), 0.006, 8)
  ], { shading: "standard", roughness: 0.78, metalness: 0.02, flatShading: false });
  pantsDetail.name = "canteen-chase-player-pants-detail";

  const jacketBackDetail = rigMergedMesh(primitives, 0x557ba2, [
    curveTubeGeometry([
      new THREE.Vector3(-0.205, 1.805, 0.235),
      new THREE.Vector3(0, 1.83, 0.255),
      new THREE.Vector3(0.205, 1.805, 0.235)
    ], 0.009, 18, 8),
    curveTubeGeometry([
      new THREE.Vector3(-0.19, 1.315, 0.225),
      new THREE.Vector3(0, 1.295, 0.238),
      new THREE.Vector3(0.19, 1.315, 0.225)
    ], 0.011, 18, 8)
  ], { shading: "standard", roughness: 0.66, metalness: 0.03, flatShading: false });
  jacketBackDetail.name = "canteen-chase-player-jacket-back-detail";

  riderRoot.add(
    torso,
    shirt,
    jacketPanels,
    jacketTrim,
    head,
    eyeWhites,
    irises,
    faceLinework,
    eyeHighlights,
    noseAccent,
    hairBase,
    hairStrands,
    hairHighlights,
    pantsWaist,
    pantsDetail,
    jacketBackDetail
  );

  const leftArm = new THREE.Group();
  const rightArm = new THREE.Group();
  leftArm.name = "canteen-chase-left-arm";
  rightArm.name = "canteen-chase-right-arm";
  leftArm.position.set(-DEFAULT_SHOULDER_X, DEFAULT_SHOULDER_Y, 0.02);
  rightArm.position.set(DEFAULT_SHOULDER_X, DEFAULT_SHOULDER_Y, 0.02);
  const leftUpperArm = new THREE.Group();
  const rightUpperArm = new THREE.Group();
  const leftForearm = new THREE.Group();
  const rightForearm = new THREE.Group();
  const armUpperLength = 0.34;
  const armLowerLength = 0.31;
  leftForearm.position.set(0, -armUpperLength, 0);
  rightForearm.position.set(0, -armUpperLength, 0);
  leftUpperArm.add(
    rigMergedMesh(primitives, palette.blue, [
      transformGeometry(primitives.capsule(0.056, armUpperLength - 0.06, 9, 16), {
        position: [0, -armUpperLength / 2, 0],
        scale: [1.08, 1, 1]
      }),
      tubeGeometry(primitives, new THREE.Vector3(0.04, -0.012, 0), new THREE.Vector3(0, -0.04, 0), 0.048, 12),
      transformGeometry(primitives.sphere(0.052, 18, 14), { position: [0.01, -0.035, 0], scale: [1.06, 0.88, 1] }),
      transformGeometry(primitives.sphere(0.06, 14, 10), { position: [0, -armUpperLength, 0], scale: [1, 0.92, 1] })
    ], { shading: "standard", roughness: 0.68, metalness: 0.03, flatShading: false })
  );
  rightUpperArm.add(
    rigMergedMesh(primitives, palette.blue, [
      transformGeometry(primitives.capsule(0.056, armUpperLength - 0.06, 9, 16), {
        position: [0, -armUpperLength / 2, 0],
        scale: [1.08, 1, 1]
      }),
      tubeGeometry(primitives, new THREE.Vector3(-0.04, -0.012, 0), new THREE.Vector3(0, -0.04, 0), 0.048, 12),
      transformGeometry(primitives.sphere(0.052, 18, 14), { position: [-0.01, -0.035, 0], scale: [1.06, 0.88, 1] }),
      transformGeometry(primitives.sphere(0.06, 14, 10), { position: [0, -armUpperLength, 0], scale: [1, 0.92, 1] })
    ], { shading: "standard", roughness: 0.68, metalness: 0.03, flatShading: false })
  );
  leftForearm.add(
    rigMergedMesh(primitives, palette.blue, [
      transformGeometry(primitives.capsule(0.048, armLowerLength - 0.05, 8, 14), {
        position: [0, -armLowerLength / 2, 0],
        scale: [1, 1, 0.98]
      }),
      transformGeometry(primitives.sphere(0.056, 14, 10), { position: [0, -0.008, 0], scale: [1.02, 0.94, 1] }),
      transformGeometry(primitives.sphere(0.048, 14, 10), { position: [0, -armLowerLength, 0], scale: [1, 0.9, 1] })
    ], { shading: "standard", roughness: 0.68, metalness: 0.03, flatShading: false }),
    rigMergedMesh(primitives, 0x6d9ac4, [
      transformGeometry(primitives.cylinder(0.058, 0.055, 0.08, 14), {
        position: [0, -armLowerLength + 0.03, 0],
        scale: [1, 1, 0.92]
      })
    ], { shading: "standard", roughness: 0.62, metalness: 0.02, flatShading: false })
  );
  rightForearm.add(
    rigMergedMesh(primitives, palette.blue, [
      transformGeometry(primitives.capsule(0.048, armLowerLength - 0.05, 8, 14), {
        position: [0, -armLowerLength / 2, 0],
        scale: [1, 1, 0.98]
      }),
      transformGeometry(primitives.sphere(0.056, 14, 10), { position: [0, -0.008, 0], scale: [1.02, 0.94, 1] }),
      transformGeometry(primitives.sphere(0.048, 14, 10), { position: [0, -armLowerLength, 0], scale: [1, 0.9, 1] })
    ], { shading: "standard", roughness: 0.68, metalness: 0.03, flatShading: false }),
    rigMergedMesh(primitives, 0x6d9ac4, [
      transformGeometry(primitives.cylinder(0.058, 0.055, 0.08, 14), {
        position: [0, -armLowerLength + 0.03, 0],
        scale: [1, 1, 0.92]
      })
    ], { shading: "standard", roughness: 0.62, metalness: 0.02, flatShading: false })
  );
  const leftHand = new THREE.Group();
  const rightHand = new THREE.Group();
  leftHand.position.set(
    LEFT_HAND_BASE_POSITION.x,
    LEFT_HAND_BASE_POSITION.y,
    LEFT_HAND_BASE_POSITION.z
  );
  rightHand.position.set(
    RIGHT_HAND_BASE_POSITION.x,
    RIGHT_HAND_BASE_POSITION.y,
    RIGHT_HAND_BASE_POSITION.z
  );
  leftHand.add(
    rigMergedMesh(primitives, palette.skin, [
      transformGeometry(primitives.sphere(0.056, 16, 12), {
        scale: [1.08, 0.8, 1]
      }),
      transformGeometry(primitives.capsule(0.02, 0.08, 6, 12), {
        position: [0, -0.03, -0.018],
        rotation: [0.3, 0, Math.PI / 2]
      })
    ], { shading: "standard", roughness: 0.96, metalness: 0.01, flatShading: false })
  );
  rightHand.add(
    rigMergedMesh(primitives, palette.skin, [
      transformGeometry(primitives.sphere(0.056, 16, 12), {
        scale: [1.08, 0.8, 1]
      }),
      transformGeometry(primitives.capsule(0.02, 0.08, 6, 12), {
        position: [0, -0.03, -0.018],
        rotation: [0.3, 0, Math.PI / 2]
      })
    ], { shading: "standard", roughness: 0.96, metalness: 0.01, flatShading: false })
  );
  leftHand.name = "canteen-chase-left-hand";
  rightHand.name = "canteen-chase-right-hand";
  const leftHandContact = createContactPoint("canteen-chase-left-hand-contact", 0, 0, -0.1);
  const rightHandContact = createContactPoint("canteen-chase-right-hand-contact", 0, 0, -0.1);
  leftHand.add(leftHandContact);
  rightHand.add(rightHandContact);
  leftForearm.add(leftHand);
  rightForearm.add(rightHand);
  leftUpperArm.add(leftForearm);
  rightUpperArm.add(rightForearm);
  leftArm.add(leftUpperArm);
  rightArm.add(rightUpperArm);
  leftArm.rotation.x = -0.72;
  rightArm.rotation.x = -0.72;
  leftArm.rotation.z = -0.2;
  rightArm.rotation.z = 0.2;
  riderRoot.add(leftArm, rightArm);

  const leftLeg = new THREE.Group();
  const rightLeg = new THREE.Group();
  leftLeg.name = "canteen-chase-left-leg";
  rightLeg.name = "canteen-chase-right-leg";
  leftLeg.position.set(-HIP_X, HIP_Y, HIP_Z);
  rightLeg.position.set(HIP_X, HIP_Y, HIP_Z);
  const leftThigh = new THREE.Group();
  const rightThigh = new THREE.Group();
  const leftShin = new THREE.Group();
  const rightShin = new THREE.Group();
  const legUpperLength = 0.42;
  const legLowerLength = 0.39;
  leftShin.position.set(0, -legUpperLength, 0);
  rightShin.position.set(0, -legUpperLength, 0);
  leftThigh.add(
    rigMergedMesh(primitives, 0x242b34, [
      transformGeometry(primitives.capsule(0.098, legUpperLength - 0.06, 10, 20), {
        position: [0, -legUpperLength / 2, 0],
        scale: [1.08, 1, 1.06]
      }),
      transformGeometry(primitives.sphere(0.106, 20, 16), { position: [0, -0.01, 0], scale: [1.02, 0.86, 1.08] }),
      transformGeometry(primitives.sphere(0.094, 18, 14), { position: [0, -legUpperLength, 0], scale: [1, 0.9, 1.04] })
    ], { shading: "standard", roughness: 0.78, metalness: 0.02, flatShading: false }),
    rigMergedMesh(primitives, 0x313842, [
      tubeGeometry(primitives, new THREE.Vector3(0, -0.08, -0.093), new THREE.Vector3(0, -0.32, -0.085), 0.009, 8)
    ], { shading: "standard", roughness: 0.76, metalness: 0.02, flatShading: false })
  );
  rightThigh.add(
    rigMergedMesh(primitives, 0x242b34, [
      transformGeometry(primitives.capsule(0.098, legUpperLength - 0.06, 10, 20), {
        position: [0, -legUpperLength / 2, 0],
        scale: [1.08, 1, 1.06]
      }),
      transformGeometry(primitives.sphere(0.106, 20, 16), { position: [0, -0.01, 0], scale: [1.02, 0.86, 1.08] }),
      transformGeometry(primitives.sphere(0.094, 18, 14), { position: [0, -legUpperLength, 0], scale: [1, 0.9, 1.04] })
    ], { shading: "standard", roughness: 0.78, metalness: 0.02, flatShading: false }),
    rigMergedMesh(primitives, 0x313842, [
      tubeGeometry(primitives, new THREE.Vector3(0, -0.08, -0.093), new THREE.Vector3(0, -0.32, -0.085), 0.009, 8)
    ], { shading: "standard", roughness: 0.76, metalness: 0.02, flatShading: false })
  );
  leftShin.add(
    rigMergedMesh(primitives, 0x242b34, [
      transformGeometry(primitives.capsule(0.084, legLowerLength - 0.05, 10, 20), {
        position: [0, -legLowerLength / 2, 0],
        scale: [1.04, 1, 1.04]
      }),
      transformGeometry(primitives.sphere(0.092, 18, 14), { position: [0, -0.008, 0], scale: [1, 0.9, 1.04] }),
      transformGeometry(primitives.sphere(0.079, 18, 14), { position: [0, -legLowerLength, 0], scale: [1, 0.88, 1.02] })
    ], { shading: "standard", roughness: 0.78, metalness: 0.02, flatShading: false }),
    rigMergedMesh(primitives, 0x313842, [
      tubeGeometry(primitives, new THREE.Vector3(0, -0.07, -0.078), new THREE.Vector3(0, -0.31, -0.071), 0.008, 8)
    ], { shading: "standard", roughness: 0.76, metalness: 0.02, flatShading: false })
  );
  rightShin.add(
    rigMergedMesh(primitives, 0x242b34, [
      transformGeometry(primitives.capsule(0.084, legLowerLength - 0.05, 10, 20), {
        position: [0, -legLowerLength / 2, 0],
        scale: [1.04, 1, 1.04]
      }),
      transformGeometry(primitives.sphere(0.092, 18, 14), { position: [0, -0.008, 0], scale: [1, 0.9, 1.04] }),
      transformGeometry(primitives.sphere(0.079, 18, 14), { position: [0, -legLowerLength, 0], scale: [1, 0.88, 1.02] })
    ], { shading: "standard", roughness: 0.78, metalness: 0.02, flatShading: false }),
    rigMergedMesh(primitives, 0x313842, [
      tubeGeometry(primitives, new THREE.Vector3(0, -0.07, -0.078), new THREE.Vector3(0, -0.31, -0.071), 0.008, 8)
    ], { shading: "standard", roughness: 0.76, metalness: 0.02, flatShading: false })
  );
  const leftFoot = new THREE.Group();
  const rightFoot = new THREE.Group();
  leftFoot.position.set(
    LEFT_FOOT_BASE_POSITION.x,
    LEFT_FOOT_BASE_POSITION.y,
    LEFT_FOOT_BASE_POSITION.z
  );
  rightFoot.position.set(
    RIGHT_FOOT_BASE_POSITION.x,
    RIGHT_FOOT_BASE_POSITION.y,
    RIGHT_FOOT_BASE_POSITION.z
  );
  leftFoot.add(
    rigMergedMesh(primitives, palette.white, [
      transformGeometry(primitives.capsule(0.084, 0.23, 10, 20), {
        position: [0, -0.012, -0.04],
        rotation: [Math.PI / 2, 0, 0],
        scale: [1.22, 1.06, 0.78]
      }),
      transformGeometry(primitives.capsule(0.038, 0.13, 8, 16), {
        position: [0, 0.03, 0.012],
        rotation: [Math.PI / 2, 0, 0],
        scale: [1.12, 1, 0.46]
      })
    ], { shading: "standard", roughness: 0.72, metalness: 0.02, flatShading: false }),
    rigMergedMesh(primitives, 0xaeb7bf, [
      transformGeometry(primitives.capsule(0.069, 0.245, 8, 18), {
        position: [0, -0.056, -0.03],
        rotation: [Math.PI / 2, 0, 0],
        scale: [1.3, 1.04, 0.34]
      }),
      transformGeometry(primitives.box(0.138, 0.018, 0.026), { position: [0, 0.052, -0.12] }),
      transformGeometry(primitives.box(0.138, 0.018, 0.026), { position: [0, 0.052, -0.07] }),
      transformGeometry(primitives.box(0.132, 0.018, 0.026), { position: [0, 0.05, -0.02] }),
      transformGeometry(primitives.box(0.075, 0.055, 0.062), { position: [0, 0.022, 0.052] })
    ], { shading: "standard", roughness: 0.68, metalness: 0.05, flatShading: false })
  );
  rightFoot.add(
    rigMergedMesh(primitives, palette.white, [
      transformGeometry(primitives.capsule(0.084, 0.23, 10, 20), {
        position: [0, -0.012, -0.04],
        rotation: [Math.PI / 2, 0, 0],
        scale: [1.22, 1.06, 0.78]
      }),
      transformGeometry(primitives.capsule(0.038, 0.13, 8, 16), {
        position: [0, 0.03, 0.012],
        rotation: [Math.PI / 2, 0, 0],
        scale: [1.12, 1, 0.46]
      })
    ], { shading: "standard", roughness: 0.72, metalness: 0.02, flatShading: false }),
    rigMergedMesh(primitives, 0xaeb7bf, [
      transformGeometry(primitives.capsule(0.069, 0.245, 8, 18), {
        position: [0, -0.056, -0.03],
        rotation: [Math.PI / 2, 0, 0],
        scale: [1.3, 1.04, 0.34]
      }),
      transformGeometry(primitives.box(0.138, 0.018, 0.026), { position: [0, 0.052, -0.12] }),
      transformGeometry(primitives.box(0.138, 0.018, 0.026), { position: [0, 0.052, -0.07] }),
      transformGeometry(primitives.box(0.132, 0.018, 0.026), { position: [0, 0.05, -0.02] }),
      transformGeometry(primitives.box(0.075, 0.055, 0.062), { position: [0, 0.022, 0.052] })
    ], { shading: "standard", roughness: 0.68, metalness: 0.05, flatShading: false })
  );
  leftFoot.name = "canteen-chase-left-foot";
  rightFoot.name = "canteen-chase-right-foot";
  const leftFootContact = createContactPoint("canteen-chase-left-foot-contact", 0, -0.085, 0);
  const rightFootContact = createContactPoint("canteen-chase-right-foot-contact", 0, -0.085, 0);
  leftFoot.add(leftFootContact);
  rightFoot.add(rightFootContact);
  leftShin.add(leftFoot);
  rightShin.add(rightFoot);
  leftThigh.add(leftShin);
  rightThigh.add(rightShin);
  leftLeg.add(leftThigh);
  rightLeg.add(rightThigh);
  riderRoot.add(leftLeg, rightLeg);

  root.scale.setScalar(CHASE_RIDER_DISPLAY_SCALE);

  return {
    root,
    group: root,
    bicycleRoot,
    riderRoot,
    frontAssembly,
    wheels: [rearWheel, frontWheel],
    rearWheel,
    frontWheel,
    leftArm,
    rightArm,
    leftLeg,
    rightLeg,
    leftHand,
    rightHand,
    leftFoot,
    rightFoot,
    leftGrip,
    rightGrip,
    leftHandContact,
    rightHandContact,
    leftGripContact,
    rightGripContact,
    leftFootContact,
    rightFootContact,
    leftPedalContact,
    rightPedalContact,
    rightBrakeLever,
    crank,
    leftPedal,
    rightPedal,
    chain,
    basket,
    leftUpperArm,
    rightUpperArm,
    leftForearm,
    rightForearm,
    leftThigh,
    rightThigh,
    leftShin,
    rightShin
  };
}

/** Reset every pose-controlled node while leaving root placement and scale intact. */
export function resetChaseRiderRigPose(rig: ChaseRiderRig): void {
  setIdentityTransform(rig.bicycleRoot);
  setIdentityTransform(rig.riderRoot);
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
  const progress = clamp01(options.progress ?? 1);
  const pedalPhase = options.pedalPhaseRadians ?? 0;
  const steering = options.steeringRadians ?? 0;
  resetChaseRiderRigPose(rig);

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
    rig.riderRoot.position.x = lerp(-0.58, -0.08, progress);
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
