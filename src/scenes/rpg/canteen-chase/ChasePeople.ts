import * as THREE from "three";
import { ThreePrimitiveCache } from "../ThreePrimitiveCache";
import { createChaseBicycleRig, DEFAULT_CHASE_RIDER_RIG_PALETTE } from "./ChaseRiderRig";
import { createChaseHuman, type ChaseHumanInstance } from "./ChaseHumanAsset";
import type { ChasePedestrianKind } from "./ChaseGeometry";

export interface ChasePedestrianModel {
  group: THREE.Group;
  human: ChaseHumanInstance;
  kind: ChasePedestrianKind;
  pair?: ChasePedestrianModel;
}

/** Campus pedestrians use the licensed asset and its original Walk clip. */
export function createChasePedestrian(cache: ThreePrimitiveCache, kind: ChasePedestrianKind, seed: number, shirtColor?: number): ChasePedestrianModel {
  const shirts = [0x597b91, 0x9b6f60, 0x827d97, 0x658875, 0xb19e80];
  const group = new THREE.Group();
  const human = createChaseHuman(1.95 + seed % 3 * 0.045, shirtColor ?? shirts[seed % shirts.length]);
  group.add(human.group);
  const model: ChasePedestrianModel = { group, human, kind };
  human.onReady = () => {
    if (kind === "phoneWalker" || kind === "soyMilk") {
      const prop = new THREE.Group();
      prop.name = kind === "phoneWalker" ? "pedestrian-held-phone" : "pedestrian-held-drink";
      // Original bone coordinates use centimetres; the imported root supplies
      // the same uniform conversion as the hand and the rest of the character.
      prop.position.set(0, 8, 0);
      const material = cache.material(kind === "phoneWalker" ? 0x263641 : 0xe8dfc6, { shading: "standard", roughness: 0.68 });
      const mesh = new THREE.Mesh(kind === "phoneWalker" ? cache.box(7, 13, 1) : cache.cylinder(4, 3.3, 11, 10), material);
      prop.add(mesh);
      if (kind === "phoneWalker") {
        const screen = new THREE.Mesh(cache.box(5.8, 10.8, 0.2), cache.material(0x86b7cd, { shading: "standard", roughness: 0.28 }));
        screen.position.z = 0.65;
        prop.add(screen);
      }
      human.bones.get("WristR")?.add(prop);
    }
    const clip = human.clips.find((entry) => entry.name.endsWith("|Walk"));
    if (clip) human.mixer!.clipAction(clip).play();
    animateChasePedestrian(model, seed * 0.73, false);
  };
  if (human.ready) human.onReady();
  if (kind === "bikePusher") {
    const bike = createChaseBicycleRig(cache, { ...DEFAULT_CHASE_RIDER_RIG_PALETTE, blue: 0x78958a }).bicycleRoot;
    bike.position.set(0.74, 0.02, -0.24);
    group.add(bike);
  }
  if (kind === "chattingPair") {
    const pair = createChasePedestrian(cache, "soyMilk", seed + 1);
    pair.group.position.set(0.68, 0, -0.18);
    group.add(pair.group);
    model.pair = pair;
  }
  return model;
}

export function animateChasePedestrian(model: ChasePedestrianModel, phase: number, reduced: boolean): void {
  if (model.human.ready) model.human.mixer?.setTime(reduced ? 0 : phase / 5.7);
  if (model.pair) animateChasePedestrian(model.pair, phase + 1.2, reduced);
}
