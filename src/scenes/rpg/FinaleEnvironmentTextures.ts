import type Phaser from "phaser";
import manifest from "../../assets/rpg/interiors/finale/finale_environment_manifest.json";

import arrivalArcadeUrl from "../../assets/rpg/interiors/finale/finale_arrival_arcade.png";
import firstFloorLobbyUrl from "../../assets/rpg/interiors/finale/finale_1f_lobby_maxwell.png";
import stairwellUrl from "../../assets/rpg/interiors/finale/finale_stairwell.png";
import verticalCoreUrl from "../../assets/rpg/interiors/finale/finale_vertical_core.png";
import secondFloorActivityUrl from "../../assets/rpg/interiors/finale/finale_2f_activity.png";
import finalClassroomUrl from "../../assets/rpg/interiors/finale/finale_final_classroom.png";
import teachingBuildingFloor1Url from "../../assets/rpg/interiors/finale/teaching_building_floor_1.png";
import teachingBuildingFloor2Url from "../../assets/rpg/interiors/finale/teaching_building_floor_2.png";
import teachingBuildingFloor3Url from "../../assets/rpg/interiors/finale/teaching_building_floor_3.png";
import { preloadRpgImage } from "./RpgAssetLoader";

export type FinaleEnvironmentId = typeof manifest.scenes[number]["id"];

export interface FinaleEnvironmentAsset {
  id: FinaleEnvironmentId;
  title: string;
  url: string;
  projection: string;
  temporalCellId: string | null;
  purpose: string;
  dynamicLayers: readonly string[];
  sourceSize: { width: number; height: number };
  logicalViewport: { width: number; height: number };
  baseLayerOnly: boolean;
  sha256: string;
}

const urls: Record<FinaleEnvironmentId, string> = {
  finale_arrival_arcade: arrivalArcadeUrl,
  finale_1f_lobby_maxwell: firstFloorLobbyUrl,
  finale_stairwell: stairwellUrl,
  finale_vertical_core: verticalCoreUrl,
  finale_2f_activity: secondFloorActivityUrl,
  finale_final_classroom: finalClassroomUrl,
  teaching_building_floor_1: teachingBuildingFloor1Url,
  teaching_building_floor_2: teachingBuildingFloor2Url,
  teaching_building_floor_3: teachingBuildingFloor3Url
};

export const FINALE_ENVIRONMENTS = Object.freeze(
  Object.fromEntries(
    manifest.scenes.map((entry) => [
      entry.id,
      {
        ...entry,
        url: urls[entry.id]
      }
    ])
  ) as Record<FinaleEnvironmentId, FinaleEnvironmentAsset>
);

export const FINALE_ENVIRONMENT_SOURCE_MANIFEST = manifest;

export function preloadFinaleEnvironmentTextures(scene: Phaser.Scene): void {
  Object.values(FINALE_ENVIRONMENTS).forEach((asset) => {
    preloadRpgImage(scene, asset.id, asset.url);
  });
}
