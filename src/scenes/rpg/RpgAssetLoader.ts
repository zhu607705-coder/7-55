import type Phaser from "phaser";

type RpgTextureKey = string;

/**
 * Shared idempotent asset-loading helpers for Phaser RPG scenes. Keeping the
 * texture-existence guard here prevents scene-local preload code from drifting
 * and avoids duplicate queue entries when a scene is restarted.
 */
export function preloadRpgImage(
  scene: Phaser.Scene,
  key: RpgTextureKey,
  url: string
): void {
  if (!scene.textures.exists(key)) {
    scene.load.setCORS("anonymous");
    scene.load.image(key, url);
  }
}

export function preloadRpgImages(
  scene: Phaser.Scene,
  entries: Iterable<readonly [RpgTextureKey, string]>
): void {
  for (const [key, url] of entries) {
    preloadRpgImage(scene, key, url);
  }
}

export function preloadRpgSpriteSheet(
  scene: Phaser.Scene,
  key: RpgTextureKey,
  url: string,
  frameConfig: Phaser.Types.Loader.FileTypes.ImageFrameConfig
): void {
  if (!scene.textures.exists(key)) {
    scene.load.setCORS("anonymous");
    scene.load.spritesheet(key, url, frameConfig);
  }
}
