import Phaser from "phaser";
import campusPlateUrl from "../../assets/rpg/campus/zijingang_campus_plate.png";
import campusWaterUrl from "../../assets/rpg/campus/water/zijingang_water_frames.png";
import campusWaterMaskUrl from "../../assets/rpg/campus/water/zijingang_water_mask_atlas.png";
import { preloadRpgImage, preloadRpgSpriteSheet } from "./RpgAssetLoader";

export const ZIJINGANG_CAMPUS_PLATE_URL = campusPlateUrl;
export const ZIJINGANG_CAMPUS_PLATE_KEY = "zijingang-campus-topdown-plate";
export const ZIJINGANG_CAMPUS_WATER_URL = campusWaterUrl;
export const ZIJINGANG_CAMPUS_WATER_KEY = "zijingang-campus-water-frames";
export const ZIJINGANG_CAMPUS_WATER_MASK_URL = campusWaterMaskUrl;
export const ZIJINGANG_CAMPUS_WATER_MASK_KEY = "zijingang-campus-water-mask-atlas";

export function preloadZijingangWorldAssets(scene: Phaser.Scene): void {
  preloadRpgImage(scene, ZIJINGANG_CAMPUS_PLATE_KEY, ZIJINGANG_CAMPUS_PLATE_URL);
  preloadRpgSpriteSheet(scene, ZIJINGANG_CAMPUS_WATER_KEY, ZIJINGANG_CAMPUS_WATER_URL, {
    frameWidth: 128,
    frameHeight: 128
  });
  preloadRpgImage(scene, ZIJINGANG_CAMPUS_WATER_MASK_KEY, ZIJINGANG_CAMPUS_WATER_MASK_URL);
}
