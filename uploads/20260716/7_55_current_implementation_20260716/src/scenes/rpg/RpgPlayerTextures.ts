import Phaser from "phaser";
import playerDown0Url from "../../assets/rpg/player/player_down_0.png";
import playerDown1Url from "../../assets/rpg/player/player_down_1.png";
import playerSide0Url from "../../assets/rpg/player/player_side_0.png";
import playerSide1Url from "../../assets/rpg/player/player_side_1.png";
import playerUp0Url from "../../assets/rpg/player/player_up_0.png";
import playerUp1Url from "../../assets/rpg/player/player_up_1.png";

export type RpgPlayerFacing = "down" | "up" | "side";

export const RPG_PLAYER_FRAME_WIDTH = 48;
export const RPG_PLAYER_FRAME_HEIGHT = 64;
export const RPG_PLAYER_DISPLAY_SCALE = 1.3;
export const RPG_PLAYER_NAME_OFFSET_Y = 54;
export const RPG_PLAYER_FOOT_COLLISION = Object.freeze({
  width: 15,
  height: 11.25,
  offsetX: 16.5,
  offsetY: 50.75
});

const RPG_PLAYER_TEXTURE_ASSETS = {
  "act1-player-down-0": playerDown0Url,
  "act1-player-down-1": playerDown1Url,
  "act1-player-up-0": playerUp0Url,
  "act1-player-up-1": playerUp1Url,
  "act1-player-side-0": playerSide0Url,
  "act1-player-side-1": playerSide1Url
} as const;

export function preloadRpgPlayerTextures(scene: Phaser.Scene): void {
  Object.entries(RPG_PLAYER_TEXTURE_ASSETS).forEach(([key, url]) => {
    if (!scene.textures.exists(key)) {
      scene.load.image(key, url);
    }
  });
}

export function ensureRpgPlayerTextures(scene: Phaser.Scene): void {
  const drawPlayer = (texture: string, facing: RpgPlayerFacing, stepping: boolean) => {
    if (scene.textures.exists(texture)) {
      return;
    }
    const graphics = scene.make.graphics({ x: 0, y: 0 });
    graphics.scaleCanvas(RPG_PLAYER_FRAME_WIDTH / 28, RPG_PLAYER_FRAME_HEIGHT / 43);
    graphics.fillStyle(0x172028, 0.42).fillEllipse(14, 39, 24, 7);
    const leftStep = stepping ? 2 : 5;
    const rightStep = stepping ? 17 : 15;
    graphics.fillStyle(0x26313b).fillRect(leftStep, 32, 8, 7).fillRect(rightStep, stepping ? 30 : 32, 8, 7);
    graphics.fillStyle(0x17212a).fillRect(leftStep - 1, 37, 10, 4).fillRect(rightStep - 1, stepping ? 35 : 37, 10, 4);

    if (facing === "up") {
      graphics.fillStyle(0x244b7d).fillRect(4, 17, 20, 17);
      graphics.lineStyle(2, 0x17212a).strokeRect(4, 17, 20, 17);
      graphics.fillStyle(0x59432f).fillRect(8, 19, 12, 11);
      graphics.fillStyle(0xf0d54e).fillRect(7, 31, 14, 3);
    } else if (facing === "side") {
      graphics.fillStyle(0x315f9f).fillRect(5, 17, 17, 17);
      graphics.lineStyle(2, 0x17212a).strokeRect(5, 17, 17, 17);
      graphics.fillStyle(0x59432f).fillRect(3, 20, 6, 12);
      graphics.fillStyle(0xf0d54e).fillRect(8, 22, 13, 3);
    } else {
      graphics.fillStyle(0x315f9f).fillRect(4, 17, 20, 17);
      graphics.lineStyle(2, 0x17212a).strokeRect(4, 17, 20, 17);
      graphics.fillStyle(0xf0d54e).fillRect(7, 21, 14, 4);
      graphics.fillStyle(0xe8eced).fillRect(12, 25, 4, 6);
    }

    graphics.fillStyle(0xe0b36f).fillCircle(14, 10, 9);
    graphics.lineStyle(2, 0x17212a).strokeCircle(14, 10, 9);
    graphics.fillStyle(0x2a2220).fillRect(6, 4, 16, 6).fillRect(5, 7, 4, 8);
    if (facing === "up") {
      graphics.fillStyle(0x2a2220).fillRect(9, 11, 12, 6);
    } else if (facing === "side") {
      graphics.fillStyle(0x17212a).fillRect(19, 10, 3, 3);
    } else {
      graphics.fillStyle(0x17212a).fillRect(9, 10, 3, 3).fillRect(17, 10, 3, 3);
    }
    graphics.generateTexture(texture, RPG_PLAYER_FRAME_WIDTH, RPG_PLAYER_FRAME_HEIGHT);
    graphics.destroy();
  };

  (["down", "up", "side"] as const).forEach((direction) => {
    drawPlayer(`act1-player-${direction}-0`, direction, false);
    drawPlayer(`act1-player-${direction}-1`, direction, true);
  });
}

export function configureRpgPlayerSprite(player: Phaser.Physics.Arcade.Sprite): void {
  player.setScale(RPG_PLAYER_DISPLAY_SCALE);
  player.body
    ?.setSize(RPG_PLAYER_FOOT_COLLISION.width, RPG_PLAYER_FOOT_COLLISION.height)
    .setOffset(RPG_PLAYER_FOOT_COLLISION.offsetX, RPG_PLAYER_FOOT_COLLISION.offsetY);
}
