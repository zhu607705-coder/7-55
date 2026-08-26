import type Phaser from "phaser";
import manifest from "../../assets/rpg/npcs/finale/finale_npc_manifest.json";

import studentWalkUrl from "../../assets/rpg/npcs/finale/student_walk_8frame.png";
import studentPhoneUrl from "../../assets/rpg/npcs/finale/student_phone_glance_2frame.png";
import studentAdjustBagUrl from "../../assets/rpg/npcs/finale/student_adjust_bag_2frame.png";
import studentPushDoorUrl from "../../assets/rpg/npcs/finale/student_push_door_3frame.png";
import studentIdleUrl from "../../assets/rpg/npcs/finale/student_idle_1frame.png";
import cleanerPushCartUrl from "../../assets/rpg/npcs/finale/cleaner_push_cart_8frame.png";
import cleanerPushCartDownUrl from "../../assets/rpg/npcs/finale/cleaner_push_cart_down_8frame.png";
import cleanerPushCartUpUrl from "../../assets/rpg/npcs/finale/cleaner_push_cart_up_8frame.png";
import cleanerMopUrl from "../../assets/rpg/npcs/finale/cleaner_mop_4frame.png";
import cleaningCartUrl from "../../assets/rpg/npcs/finale/cleaning_cart_1frame.png";
import cleanerPlaceSignUrl from "../../assets/rpg/npcs/finale/cleaner_place_sign_2frame.png";
import cleanerToggleLightsUrl from "../../assets/rpg/npcs/finale/cleaner_toggle_lights_2frame.png";
import cleanerRestUrl from "../../assets/rpg/npcs/finale/cleaner_rest_1frame.png";
import cleanerIdleUrl from "../../assets/rpg/npcs/finale/cleaner_idle_8frame.png";
import guardWalkUrl from "../../assets/rpg/npcs/finale/guard_walk_8frame.png";
import guardWalkDownUrl from "../../assets/rpg/npcs/finale/guard_walk_down_8frame.png";
import guardWalkUpUrl from "../../assets/rpg/npcs/finale/guard_walk_up_8frame.png";
import guardCheckListUrl from "../../assets/rpg/npcs/finale/guard_check_list_2frame.png";
import guardCheckWatchUrl from "../../assets/rpg/npcs/finale/guard_check_watch_2frame.png";
import guardFlashlightUrl from "../../assets/rpg/npcs/finale/guard_flashlight_down_2frame.png";
import guardRadioUrl from "../../assets/rpg/npcs/finale/guard_radio_2frame.png";
import { preloadRpgSpriteSheet } from "./RpgAssetLoader";

export type FinaleNpcAnimationId = typeof manifest.animations[number]["id"];

export interface FinaleNpcAnimationAsset {
  id: FinaleNpcAnimationId;
  url: string;
  frameWidth: number;
  frameHeight: number;
  frameCount: number;
  fps: number;
  loop: boolean;
  footAnchor: { x: number; y: number };
}

const urls: Record<FinaleNpcAnimationId, string> = {
  student_walk: studentWalkUrl,
  student_phone_glance: studentPhoneUrl,
  student_adjust_bag: studentAdjustBagUrl,
  student_push_door: studentPushDoorUrl,
  student_idle: studentIdleUrl,
  cleaner_push_cart: cleanerPushCartUrl,
  cleaner_push_cart_down: cleanerPushCartDownUrl,
  cleaner_push_cart_up: cleanerPushCartUpUrl,
  cleaner_mop: cleanerMopUrl,
  cleaning_cart: cleaningCartUrl,
  cleaner_place_sign: cleanerPlaceSignUrl,
  cleaner_toggle_lights: cleanerToggleLightsUrl,
  cleaner_rest: cleanerRestUrl,
  cleaner_idle: cleanerIdleUrl,
  guard_walk: guardWalkUrl,
  guard_walk_down: guardWalkDownUrl,
  guard_walk_up: guardWalkUpUrl,
  guard_check_list: guardCheckListUrl,
  guard_check_watch: guardCheckWatchUrl,
  guard_flashlight_down: guardFlashlightUrl,
  guard_radio: guardRadioUrl
};

export const FINALE_NPC_ANIMATIONS = Object.freeze(
  Object.fromEntries(
    manifest.animations.map((entry) => [
      entry.id,
      {
        id: entry.id,
        url: urls[entry.id],
        frameWidth: entry.frameWidth,
        frameHeight: entry.frameHeight,
        frameCount: entry.frameCount,
        fps: entry.fps,
        loop: entry.loop,
        footAnchor: entry.footAnchor
      }
    ])
  ) as Record<FinaleNpcAnimationId, FinaleNpcAnimationAsset>
);

export const FINALE_NPC_SOURCE_MANIFEST = manifest;

export function preloadFinaleNpcTextures(scene: Phaser.Scene): void {
  Object.values(FINALE_NPC_ANIMATIONS).forEach((asset) => {
    preloadRpgSpriteSheet(scene, asset.id, asset.url, {
      frameWidth: asset.frameWidth,
      frameHeight: asset.frameHeight
    });
  });
}

export function ensureFinaleNpcAnimations(scene: Phaser.Scene): void {
  Object.values(FINALE_NPC_ANIMATIONS).forEach((asset) => {
    if (asset.frameCount <= 1 || scene.anims.exists(asset.id)) return;
    scene.anims.create({
      key: asset.id,
      frames: scene.anims.generateFrameNumbers(asset.id, {
        start: 0,
        end: asset.frameCount - 1
      }),
      frameRate: asset.fps,
      repeat: asset.loop ? -1 : 0
    });
  });
}
