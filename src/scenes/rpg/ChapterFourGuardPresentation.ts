import type Phaser from "phaser";
import type { RpgBridge } from "./RpgBridge";
import { FINALE_NPC_ANIMATIONS, type FinaleNpcAnimationId } from "./FinaleNpcTextures";

export const GUARD_CAUGHT_LINE = "你在这里干什么？已经这么晚了，快点回去，要清楼了。";
export const GUARD_CAUGHT_DISPLAY_MS = 5200;
export function presentGuardCapture(scene: Phaser.Scene, bridge: RpgBridge, resume: () => void): void {
  scene.physics.pause();
  bridge.emit("rpg_subtitle", { speaker: "保安", text: GUARD_CAUGHT_LINE, tone: "dialogue", durationMs: GUARD_CAUGHT_DISPLAY_MS });
  let settled = false;
  const detach = () => {
    scene.events.off("shutdown", cancel);
    scene.events.off("destroy", cancel);
  };
  const cancel = () => {
    if (settled) return;
    settled = true;
    timer.remove(false);
    detach();
    // ArcadePhysics has already destroyed its world during scene shutdown.
    // Cancelling a presentation must never resume that world or submit a retry.
  };
  const timer = scene.time.delayedCall(GUARD_CAUGHT_DISPLAY_MS, () => {
    if (settled) return;
    settled = true;
    detach();
    if (!scene.sys.isActive() || !scene.physics.world) return;
    scene.physics.resume();
    resume();
  });
  scene.events.once("shutdown", cancel);
  scene.events.once("destroy", cancel);
}

/** Switch only to loaded animation frames and preserve the world-space foot box. */
export function playGuardAnimation(scene: Phaser.Scene, sprite: Phaser.Physics.Arcade.Sprite, id: FinaleNpcAnimationId): void {
  if (!scene.textures.exists(id) || !scene.anims.exists(id) || sprite.anims.currentAnim?.key === id) return;
  const body = sprite.body as Phaser.Physics.Arcade.Body;
  const foot = { x: body.center.x, y: body.center.y };
  const velocity = { x: body.velocity.x, y: body.velocity.y };
  const asset = FINALE_NPC_ANIMATIONS[id];
  const width = body.width, height = body.height;
  sprite.setOrigin(0.5, 1).play(id, true);
  body.setSize(width / sprite.scaleX, height / sprite.scaleY).setOffset((asset.frameWidth-width/sprite.scaleX)/2,asset.frameHeight-height/sprite.scaleY);
  body.updateFromGameObject();
  sprite.setPosition(sprite.x + foot.x-body.center.x, sprite.y + foot.y-body.center.y);
  body.reset(sprite.x, sprite.y);
  body.setVelocity(velocity.x, velocity.y);
}
