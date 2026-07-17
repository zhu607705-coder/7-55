import Phaser from "phaser";
import campusPlateUrl from "../../assets/rpg/campus/zijingang_campus_plate.png";

export const ZIJINGANG_CAMPUS_PLATE_URL = campusPlateUrl;
export const ZIJINGANG_CAMPUS_PLATE_KEY = "zijingang-campus-topdown-plate";

export function preloadZijingangWorldAssets(scene: Phaser.Scene): void {
  if (!scene.textures.exists(ZIJINGANG_CAMPUS_PLATE_KEY)) {
    scene.load.image(ZIJINGANG_CAMPUS_PLATE_KEY, ZIJINGANG_CAMPUS_PLATE_URL);
  }
}
