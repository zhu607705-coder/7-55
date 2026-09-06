import { createServer } from "vite";
import * as THREE from "three";
import { readFileSync } from "node:fs";
import { createHash } from "node:crypto";
import { GLTFLoader } from "three/examples/jsm/loaders/GLTFLoader.js";

const failures = [];
let checks = 0;
const check = (value, message) => { checks += 1; if (!value) failures.push(message); };
const server = await createServer({
  configFile: false, appType: "custom", logLevel: "error",
  optimizeDeps: { noDiscovery: true, include: [] }, server: { middlewareMode: true, ws: false }
});
try {
  const route = await server.ssrLoadModule("/src/scenes/rpg/canteen-chase/ChaseRoute.ts");
  const geometry = await server.ssrLoadModule("/src/scenes/rpg/canteen-chase/ChaseGeometry.ts");
  const model = await server.ssrLoadModule("/src/scenes/rpg/canteen-chase/ChaseRiderRig.ts");
  const humanAsset = await server.ssrLoadModule("/src/scenes/rpg/canteen-chase/ChaseHumanAsset.ts");
  const glb = readFileSync("src/assets/rpg/canteen-characters/quaternius_casual.glb");
  check(createHash("sha256").update(glb).digest("hex") === "fea7e71271203e7073f1a073fa1208de7402df276f87f80e149bf7589b5d46b4", "licensed GitHub source is byte-identical");
  const gltf = await new GLTFLoader().parseAsync(glb.buffer.slice(glb.byteOffset, glb.byteOffset + glb.byteLength), "");
  humanAsset.installChaseHumanTemplate(gltf);
  const { ThreePrimitiveCache } = await server.ssrLoadModule("/src/scenes/rpg/ThreePrimitiveCache.ts");
  check(route.CHASE_GOAL_METERS === 755, "shared stage metadata ends at the controller's 755m goal");
  check(route.CHASE_ROUTE_STAGES.length === 4, "four authored environment stages remain");
  const obstacles = geometry.obstaclesBetween(0, 999);
  check(obstacles.length === 70 && geometry.CHASE_HAZARD_BEATS.length === 35, "base hazard layer contains 35 authored two-obstacle groups");
  obstacles.forEach((obstacle, index) => {
    check(obstacle.lane >= 0 && obstacle.lane <= 2, `${obstacle.id} lane in range`);
    check(obstacle.distance <= 726, `${obstacle.id} leaves final approach clear`);
  });
  geometry.CHASE_HAZARD_BEATS.forEach((beat, index, beats) => {
    const group = obstacles.filter((obstacle) => obstacle.distance === beat.distance);
    check(group.length === 2 && new Set(group.map((obstacle) => obstacle.lane)).size === 2, `${beat.distance} has exactly two occupied lanes`);
    check(group.every((obstacle) => obstacle.lane !== beat.openLane), `${beat.distance} has a clear opening`);
    if (index) {
      check(Math.abs(beat.openLane - beats[index - 1].openLane) === 1, `${beat.distance} needs one adjacent lane change`);
      check((beat.distance - beats[index - 1].distance) / 21.5 >= 0.5, `${beat.distance} base groups remain separated at boosted speed`);
    }
  });
  check(JSON.stringify(obstacles) === JSON.stringify(geometry.obstaclesBetween(0, 999)), "obstacles are deterministic across retries");

  const rig = model.createChaseRiderRig(new ThreePrimitiveCache());
  const complexity = model.measureChaseRiderRigComplexity(rig);
  check(complexity.triangles < 60000, `hero detail budget below old 58030 baseline plus margin: ${complexity.triangles}`);
  check(rig.human.ready && rig.human.bones.size === 62, "real GitHub asset has 62 bound joints");
  check(Boolean(rig.human.model.getObjectByName("Casual2_Head")), "original character head is the active consumer");
  check(!rig.root.getObjectByName("canteen-chase-player-tailored-jacket"), "procedural human geometry is removed");
  for (const steering of [-0.32, 0, 0.32]) {
    for (let phase = 0; phase < 24; phase += 1) {
      model.applyChaseRiderPose(rig, "ride", { pedalPhaseRadians: -phase / 24 * Math.PI * 2, steeringRadians: steering });
      const error = model.measureChaseRiderContactError(rig);
      for (const [key, value] of Object.entries(rig.human.group.userData.contactErrors)) {
        check(value < 0.005, `actual skinned bone ${key} steer=${steering} phase=${phase} error=${value}`);
      }
      for (const key of ["leftHandToGripWorldUnits", "rightHandToGripWorldUnits", "leftFootToPedalWorldUnits", "rightFootToPedalWorldUnits"]) {
        check(error[key] <= model.CHASE_RIDER_CONTACT_EPSILON, `ride steer=${steering} phase=${phase} ${key}=${error[key]}`);
      }
      const foot = model.measureChaseRiderFootOrientationError(rig);
      check(foot.leftSoleTiltRadians < 0.00001 && foot.rightSoleTiltRadians < 0.00001, "pedal-bound soles remain level");
      for (const side of ["L", "R"]) {
        const hip = rig.human.bones.get(`UpperLeg${side}`).getWorldPosition(new THREE.Vector3());
        const knee = rig.human.bones.get(`LowerLeg${side}`).getWorldPosition(new THREE.Vector3());
        const ankle = rig.human.model.getObjectByName(`LowerLeg${side}_end`).getWorldPosition(new THREE.Vector3());
        const bendDegrees = hip.clone().sub(knee).angleTo(ankle.clone().sub(knee)) * 180 / Math.PI;
        check(bendDegrees > 55 && bendDegrees < 175, `skinned knee ${side} phase=${phase} stays in riding envelope: ${bendDegrees}`);
        check(knee.z < hip.z, `skinned knee ${side} phase=${phase} bends toward bike front`);
      }
    }
  }
  model.applyChaseRiderPose(rig, "ride", { pedalPhaseRadians: 0 });
  rig.root.updateWorldMatrix(true, true);
  const crankCenter = rig.crank.getWorldPosition(new THREE.Vector3());
  const pedalBefore = rig.rightPedalContact.getWorldPosition(new THREE.Vector3());
  const radial = pedalBefore.clone().sub(crankCenter);
  model.applyChaseRiderPose(rig, "ride", { pedalPhaseRadians: -0.08 });
  rig.root.updateWorldMatrix(true, true);
  const pedalDelta = rig.rightPedalContact.getWorldPosition(new THREE.Vector3()).sub(pedalBefore);
  check(pedalDelta.dot(new THREE.Vector3(0, -radial.z, radial.y)) < 0, "forward -Z travel uses negative-X pedaling");
  for (const pose of model.CHASE_RIDER_POSE_NAMES) for (const progress of [0, 0.5, 1]) {
    model.applyChaseRiderPose(rig, pose, { progress });
    for (const [key, value] of Object.entries(rig.human.group.userData.contactErrors)) {
      check(value < 0.005, `transition skinned bone ${pose} ${progress} ${key} error=${value}`);
    }
    rig.root.traverse((node) => { if (node.isSkinnedMesh) node.computeBoundingBox(); });
    const bounds = new THREE.Box3().setFromObject(rig.root);
    check(Number.isFinite(bounds.min.x + bounds.max.y + bounds.min.z), `${pose} ${progress} produces finite geometry`);
    check(bounds.max.y < 4 && bounds.min.y > -1, `${pose} ${progress} remains in the authored human/bicycle envelope`);
  }
  console.log(`Canteen chase model: ${checks} checks; hero ${complexity.meshes} meshes / ${complexity.triangles} triangles; stunt route stages / 755m`);
} finally {
  await server.close();
}
if (failures.length) {
  console.error(failures.join("\n"));
  process.exitCode = 1;
} else console.log("Canteen chase model PASS");
