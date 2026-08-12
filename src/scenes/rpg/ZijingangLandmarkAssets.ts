import Phaser from "phaser";
import campusPlateUrl from "../../assets/rpg/campus/zijingang_campus_plate.png";
import { preloadRpgImage } from "./RpgAssetLoader";

export const ZIJINGANG_CAMPUS_PLATE_URL = campusPlateUrl;
export const ZIJINGANG_CAMPUS_PLATE_KEY = "zijingang-campus-topdown-plate";

export function preloadZijingangWorldAssets(scene: Phaser.Scene): void {
  preloadRpgImage(scene, ZIJINGANG_CAMPUS_PLATE_KEY, ZIJINGANG_CAMPUS_PLATE_URL);
}
