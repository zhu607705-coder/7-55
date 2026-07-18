import Phaser from "phaser";
import campusMapUrl from "../../data/maps/zijingang-campus.json?url";
import crescentBuildingUrl from "../../assets/rpg/landmarks/crescent_building.png";
import foundationLibraryUrl from "../../assets/rpg/landmarks/foundation_library.png";
import mainLibraryUrl from "../../assets/rpg/landmarks/main_library.png";
import managementSchoolUrl from "../../assets/rpg/landmarks/management_school.png";
import qiushiAuditoriumUrl from "../../assets/rpg/landmarks/qiushi_auditorium.png";
import southGateUrl from "../../assets/rpg/landmarks/south_gate.png";
import environmentAtlasUrl from "../../assets/rpg/props/zijingang_environment.png";
import qizhenBridgeSegmentUrl from "../../assets/rpg/props/qizhen_bridge_segment.png";
import zijingangStadiumUrl from "../../assets/rpg/landmarks/zijingang_stadium.png";
import terrainTilesUrl from "../../assets/rpg/tiles/zijingang_terrain.png";

export const ZIJINGANG_MAP_KEY = "zijingang-campus-map";
export const ZIJINGANG_TILESET_KEY = "zijingang-terrain";
export const ZIJINGANG_ENVIRONMENT_KEY = "zijingang-environment";
export const ZIJINGANG_BRIDGE_KEY = "zijingang-qizhen-bridge-segment";

export const ZIJINGANG_LANDMARK_ASSETS = {
  crescent_building: { key: "zijingang-crescent-building", url: crescentBuildingUrl },
  foundation_library: { key: "zijingang-foundation-library", url: foundationLibraryUrl },
  main_library: { key: "zijingang-main-library", url: mainLibraryUrl },
  management_school: { key: "zijingang-management-school", url: managementSchoolUrl },
  qiushi_auditorium: { key: "zijingang-qiushi-auditorium", url: qiushiAuditoriumUrl },
  south_gate: { key: "zijingang-south-gate", url: southGateUrl },
  zijingang_stadium: { key: "zijingang-stadium", url: zijingangStadiumUrl }
} as const;

export function preloadZijingangWorldAssets(scene: Phaser.Scene): void {
  if (!scene.cache.tilemap.exists(ZIJINGANG_MAP_KEY)) {
    scene.load.tilemapTiledJSON(ZIJINGANG_MAP_KEY, campusMapUrl);
  }
  if (!scene.textures.exists(ZIJINGANG_TILESET_KEY)) {
    scene.load.image(ZIJINGANG_TILESET_KEY, terrainTilesUrl);
  }
  if (!scene.textures.exists(ZIJINGANG_ENVIRONMENT_KEY)) {
    scene.load.spritesheet(ZIJINGANG_ENVIRONMENT_KEY, environmentAtlasUrl, {
      frameWidth: 512,
      frameHeight: 512
    });
  }
  if (!scene.textures.exists(ZIJINGANG_BRIDGE_KEY)) {
    scene.load.image(ZIJINGANG_BRIDGE_KEY, qizhenBridgeSegmentUrl);
  }
  Object.values(ZIJINGANG_LANDMARK_ASSETS).forEach(({ key, url }) => {
    if (!scene.textures.exists(key)) {
      scene.load.image(key, url);
    }
  });
}
