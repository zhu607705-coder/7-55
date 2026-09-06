import * as THREE from "three";
import { GLTFLoader, type GLTF } from "three/examples/jsm/loaders/GLTFLoader.js";
import { clone } from "three/examples/jsm/utils/SkeletonUtils.js";
import casualUrl from "../../../assets/rpg/canteen-characters/quaternius_casual.glb?url";

let template: GLTF | undefined;
let pending: Promise<void> | undefined;

/** Also used by the dependency-light validator with the checked-in GLB bytes. */
export function installChaseHumanTemplate(gltf: GLTF): void {
  gltf.scene.traverse((node) => {
    if ((node as THREE.SkinnedMesh).isSkinnedMesh) (node as THREE.SkinnedMesh).skeleton.pose();
  });
  gltf.scene.updateMatrixWorld(true);
  template = gltf;
}

export function preloadChaseHuman(): Promise<void> {
  if (template) return Promise.resolve();
  pending ??= new GLTFLoader().loadAsync(casualUrl).then(installChaseHumanTemplate).catch((error) => {
    pending = undefined;
    throw error;
  });
  return pending;
}

export interface ChaseHumanInstance {
  group: THREE.Group;
  model?: THREE.Object3D;
  bones: Map<string, THREE.Bone>;
  rest: Map<string, { position: THREE.Vector3; quaternion: THREE.Quaternion; scale: THREE.Vector3 }>;
  ready: boolean;
  error: boolean;
  mixer?: THREE.AnimationMixer;
  clips: readonly THREE.AnimationClip[];
  heightScale: number;
  disposed?: boolean;
  onReady?: () => void;
}

export function createChaseHuman(height = 2.15, shirtColor?: number, isPlayer = false): ChaseHumanInstance {
  const human: ChaseHumanInstance = {
    group: new THREE.Group(), bones: new Map(), rest: new Map(), ready: false,
    error: false, clips: [], heightScale: height / 1.8579765166
  };
  human.group.name = "quaternius-casual-character";
  human.group.userData.assetSource = "Quaternius / GitHub / CC0-1.0";
  human.group.userData.disposeHuman = () => {
    human.disposed = true;
    human.mixer?.stopAllAction();
    if (human.model) human.mixer?.uncacheRoot(human.model);
    human.model?.traverse((node) => {
      if ((node as THREE.SkinnedMesh).isSkinnedMesh) (node as THREE.SkinnedMesh).skeleton.dispose();
    });
  };
  const mount = () => {
    if (!template || human.disposed) return;
    const model = clone(template.scene);
    // Per-instance GPU resources have one owner: the containing renderer.
    // Destroying a transition must never dispose the live chase's skeleton.
    model.traverse((node) => {
      if ((node as THREE.Mesh).isMesh) {
        const mesh = node as THREE.Mesh;
        mesh.geometry = mesh.geometry.clone();
        const copyMaterial = (source: THREE.Material) => {
          const material = source.clone();
          if (material instanceof THREE.MeshStandardMaterial) {
            material.metalness = 0;
            material.roughness = 0.88;
            if (shirtColor !== undefined && material.name === "LightBrown") material.color.setHex(shirtColor);
            if (isPlayer && ["Hair", "Eyebrows"].includes(material.name)) material.color.setHex(0x171d24);
            if (isPlayer && material.name === "Red_Dark") material.color.setHex(0x202730);
          }
          return material;
        };
        mesh.material = Array.isArray(mesh.material) ? mesh.material.map(copyMaterial) : copyMaterial(mesh.material);
        node.castShadow = true;
        node.receiveShadow = true;
        node.frustumCulled = false;
      }
      if ((node as THREE.Bone).isBone) {
        human.bones.set(node.name, node as THREE.Bone);
        human.rest.set(node.name, { position: node.position.clone(), quaternion: node.quaternion.clone(), scale: node.scale.clone() });
      }
    });
    model.scale.setScalar(human.heightScale);
    model.rotation.y = Math.PI;
    human.group.add(model);
    human.model = model;
    human.clips = template.animations;
    human.mixer = new THREE.AnimationMixer(model);
    human.ready = true;
    human.onReady?.();
  };
  if (template) mount();
  else if (typeof document !== "undefined") void preloadChaseHuman().then(mount).catch(() => { human.error = true; });
  return human;
}

export function resetChaseHumanBones(human: ChaseHumanInstance): void {
  for (const [name, bone] of human.bones) {
    const rest = human.rest.get(name)!;
    bone.position.copy(rest.position);
    bone.quaternion.copy(rest.quaternion);
    bone.scale.copy(rest.scale);
  }
}
