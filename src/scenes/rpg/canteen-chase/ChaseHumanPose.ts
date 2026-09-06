import * as THREE from "three";
import type { ChaseRiderRig } from "./ChaseRiderRig";
import { resetChaseHumanBones } from "./ChaseHumanAsset";

const Y = new THREE.Vector3(0, 1, 0);
const V = () => new THREE.Vector3();
const Q = () => new THREE.Quaternion();
const position = (node: THREE.Object3D) => node.getWorldPosition(V());

function worldRotation(node: THREE.Object3D, quaternion: THREE.Quaternion): void {
  node.quaternion.copy(node.parent!.getWorldQuaternion(Q()).invert().multiply(quaternion));
  node.updateWorldMatrix(false, true);
}

function worldPosition(node: THREE.Object3D, point: THREE.Vector3): void {
  node.position.copy(node.parent!.worldToLocal(point.clone()));
  node.updateWorldMatrix(false, true);
}

/** Rotate real bones with their own bind axes and lengths; never scale a limb. */
function solveLimb(upper: THREE.Bone, lower: THREE.Bone, end: THREE.Object3D, target: THREE.Vector3, pole: THREE.Vector3): number {
  const origin = position(upper), middle = position(lower), terminal = position(end);
  const a = origin.distanceTo(middle), b = middle.distanceTo(terminal);
  const raw = target.clone().sub(origin), distance = raw.length();
  const direction = raw.normalize();
  const d = THREE.MathUtils.clamp(distance, Math.abs(a - b) + 0.00001, a + b - 0.00001);
  const bend = pole.clone().sub(origin);
  bend.addScaledVector(direction, -bend.dot(direction));
  if (bend.lengthSq() < 0.000001) bend.copy(Y).addScaledVector(direction, -Y.dot(direction));
  bend.normalize();
  const along = (a * a + d * d - b * b) / (2 * d);
  const wantedMiddle = origin.clone().addScaledVector(direction, along).addScaledVector(bend, Math.sqrt(Math.max(0, a * a - along * along)));
  const upperDelta = Q().setFromUnitVectors(middle.sub(origin).normalize(), wantedMiddle.clone().sub(origin).normalize());
  worldRotation(upper, upperDelta.multiply(upper.getWorldQuaternion(Q())));
  const actualMiddle = position(lower);
  const lowerDelta = Q().setFromUnitVectors(position(end).sub(actualMiddle).normalize(), target.clone().sub(actualMiddle).normalize());
  worldRotation(lower, lowerDelta.multiply(lower.getWorldQuaternion(Q())));
  return position(end).distanceTo(target);
}

export function syncChaseHumanToRider(rig: ChaseRiderRig): void {
  const human = rig.human;
  if (!human.ready || !human.model) return;
  resetChaseHumanBones(human);
  const bone = (name: string) => {
    const result = human.bones.get(name);
    if (!result) throw new Error(`Licensed chase character is missing ${name}`);
    return result;
  };
  const scale = human.heightScale;
  const worldScale = scale * rig.root.getWorldScale(V()).x;
  const standingLift = Math.max(0, -rig.riderRoot.position.y - 0.16);
  human.group.position.copy(rig.riderRoot.position).add(new THREE.Vector3(0, 1.27 - 0.96415064 * scale + standingLift, 0.17 + 0.0450637 * scale));
  human.group.quaternion.copy(rig.riderRoot.quaternion);
  rig.root.updateWorldMatrix(true, true);
  // The source faces +Z; the uniformly rotated model faces the bike's -Z.
  const riderQ = rig.riderRoot.getWorldQuaternion(Q());
  const handOnGrip = (contact: THREE.Object3D) => Math.min(position(contact).distanceTo(position(rig.leftGripContact)), position(contact).distanceTo(position(rig.rightGripContact))) < 0.005;
  const palmOffset = new THREE.Vector3(0, -0.35, -0.94).normalize().multiplyScalar(0.085 * worldScale).applyQuaternion(riderQ);
  const hips = bone("Hips"), hipsRestQ = hips.getWorldQuaternion(Q());
  const leanAxis = new THREE.Vector3(1, 0, 0).applyQuaternion(riderQ);
  let lean = rig.upperBody.rotation.x * 1.6;
  // Fit the posture to the imported person's real reach. This modest extra
  // forward bend is needed during mounting/foot-down; bones are never stretched.
  for (let attempt = 0; attempt < 16; attempt += 1) {
    worldRotation(hips, Q().setFromAxisAngle(leanAxis, lean).multiply(hipsRestQ));
    const reachable = ([["L", rig.leftHandContact], ["R", rig.rightHandContact]] as const).every(([suffix, contact]) => {
      if (!handOnGrip(contact)) return true;
      const upper = position(bone(`UpperArm${suffix}`)), lower = position(bone(`LowerArm${suffix}`)), wrist = position(bone(`Wrist${suffix}`));
      return upper.distanceTo(position(contact).sub(palmOffset)) < upper.distanceTo(lower) + lower.distanceTo(wrist) - 0.006;
    });
    if (reachable || lean <= -1.3) break;
    lean -= 0.085;
  }
  const headQ = Q().setFromAxisAngle(new THREE.Vector3(1, 0, 0).applyQuaternion(riderQ), -lean * 0.55);
  worldRotation(bone("Head"), headQ.multiply(bone("Head").getWorldQuaternion(Q())));

  const contactErrors: Record<string, number> = {};
  for (const [suffix, side, footControl, footContact, handContact] of [
    ["L", -1, rig.leftFoot, rig.leftFootContact, rig.leftHandContact],
    ["R", 1, rig.rightFoot, rig.rightFootContact, rig.rightHandContact]
  ] as const) {
    const foot = bone(`Foot${suffix}`);
    // Feet are independent root bones in this asset. Preserve their bind
    // orientation and translate the measured sole contact onto the pedal.
    const neutralFootQ = foot.getWorldQuaternion(Q());
    const footQ = footControl.getWorldQuaternion(Q()).multiply(riderQ.clone().invert()).multiply(neutralFootQ);
    worldRotation(foot, footQ);
    const soleOffset = new THREE.Vector3(0, -0.02415 * worldScale, -0.0879 * worldScale).applyQuaternion(footControl.getWorldQuaternion(Q()));
    const desiredSole = position(footContact);
    const soleInRig = rig.root.worldToLocal(desiredSole.clone());
    if (soleInRig.y < 0.02) desiredSole.copy(rig.root.localToWorld(soleInRig.setY(0.02)));
    const desiredFoot = desiredSole.clone().sub(soleOffset);
    worldPosition(foot, desiredFoot);
    const kneePole = rig.riderRoot.localToWorld(new THREE.Vector3(side * 0.2, 0.86, -0.72));
    const ankleEnd = human.model.getObjectByName(`LowerLeg${suffix}_end`)!;
    contactErrors[`ankle${suffix}`] = solveLimb(bone(`UpperLeg${suffix}`), bone(`LowerLeg${suffix}`), ankleEnd, desiredFoot, kneePole);
    contactErrors[`sole${suffix}`] = position(foot).add(soleOffset).distanceTo(desiredSole);

    const upper = bone(`UpperArm${suffix}`), lower = bone(`LowerArm${suffix}`), wrist = bone(`Wrist${suffix}`);
    // Fingers curl around the transverse grip. Wrist-to-palm distance is
    // measured in the asset's centimetre-scaled bone coordinate system.
    const targetWrist = position(handContact).sub(palmOffset);
    const elbowPole = rig.riderRoot.localToWorld(new THREE.Vector3(side * 0.65, 1.28, -0.3));
    const wristError = solveLimb(upper, lower, wrist, targetWrist, elbowPole);
    if (handOnGrip(handContact)) contactErrors[`wrist${suffix}`] = wristError;
    // Keep the palm aligned to the initial target while arms bend underneath it.
    const palmDirection = position(handContact).sub(position(wrist)).normalize();
    const wristAxis = Y.clone().applyQuaternion(wrist.getWorldQuaternion(Q()));
    worldRotation(wrist, Q().setFromUnitVectors(wristAxis, palmDirection).multiply(wrist.getWorldQuaternion(Q())));
    if (handOnGrip(handContact)) contactErrors[`palm${suffix}`] = position(wrist).add(Y.clone().multiplyScalar(0.085 * worldScale).applyQuaternion(wrist.getWorldQuaternion(Q()))).distanceTo(position(handContact));
    for (const finger of handOnGrip(handContact) ? ["Index", "Middle", "Ring", "Pinky"] : []) {
      for (const segment of [2, 3, 4]) {
        const joint = human.bones.get(`${finger}${segment}${suffix}`);
        if (joint) joint.rotateX(-0.8);
      }
    }
  }
  rig.root.updateMatrixWorld(true);
  human.group.userData.contactErrors = contactErrors;
  human.group.userData.ready = true;
}
