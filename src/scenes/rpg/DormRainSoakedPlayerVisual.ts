import Phaser from "phaser";
import {
  DORM_RAIN_SOAKED_VISUAL_PROFILE
} from "./DormHubModel";
import type { RpgPlayerFacing } from "./RpgPlayerTextures";

const WET_DROPLET_SPECS = Object.freeze([
  { x: -16, y: -28, travel: 58, period: 920, phase: 0, width: 3, height: 7 },
  { x: 13, y: -24, travel: 54, period: 1080, phase: 260, width: 3, height: 6 },
  { x: -11, y: -10, travel: 51, period: 860, phase: 510, width: 4, height: 6 },
  { x: 10, y: -5, travel: 48, period: 1030, phase: 710, width: 3, height: 7 },
  { x: -6, y: 7, travel: 36, period: 780, phase: 190, width: 3, height: 6 },
  { x: 16, y: 9, travel: 34, period: 990, phase: 620, width: 3, height: 5 },
  { x: -13, y: 17, travel: 27, period: 840, phase: 390, width: 4, height: 5 },
  { x: 5, y: 20, travel: 25, period: 1120, phase: 850, width: 3, height: 6 }
] as const);

const WET_PATCH_LAYOUTS: Readonly<Record<RpgPlayerFacing, ReadonlyArray<{
  x: number;
  y: number;
  width: number;
  height: number;
  color: number;
  alpha: number;
}>>> = Object.freeze({
  up: Object.freeze([
    { x: 0, y: -20, width: 19, height: 15, color: 0x22475d, alpha: 0.16 },
    { x: 0, y: 2, width: 24, height: 24, color: 0x265973, alpha: 0.18 },
    { x: 0, y: 24, width: 18, height: 12, color: 0x17384b, alpha: 0.2 }
  ]),
  down: Object.freeze([
    { x: 0, y: -20, width: 18, height: 15, color: 0x24495f, alpha: 0.16 },
    { x: 0, y: 3, width: 23, height: 24, color: 0x2b617c, alpha: 0.18 },
    { x: 0, y: 24, width: 18, height: 12, color: 0x1a4156, alpha: 0.21 }
  ]),
  side: Object.freeze([
    { x: 2, y: -20, width: 17, height: 15, color: 0x244b63, alpha: 0.16 },
    { x: 2, y: 2, width: 19, height: 24, color: 0x295f79, alpha: 0.18 },
    { x: 1, y: 24, width: 17, height: 12, color: 0x17394c, alpha: 0.2 }
  ])
});

const WET_HIGHLIGHT_LAYOUTS: Readonly<Record<RpgPlayerFacing, ReadonlyArray<{
  x: number;
  y: number;
  width: number;
  height: number;
  color: number;
  alpha: number;
}>>> = Object.freeze({
  up: Object.freeze([
    { x: 11, y: -31, width: 5, height: 2, color: 0xbfefff, alpha: 0.7 },
    { x: -12, y: -14, width: 2, height: 10, color: 0x7fcde9, alpha: 0.65 },
    { x: 11, y: -10, width: 2, height: 8, color: 0xb3ecff, alpha: 0.58 },
    { x: -6, y: 1, width: 3, height: 14, color: 0x23536c, alpha: 0.3 },
    { x: 7, y: 6, width: 2, height: 11, color: 0x82d5ee, alpha: 0.5 },
    { x: -8, y: 22, width: 4, height: 2, color: 0xa7e7fb, alpha: 0.62 },
    { x: 8, y: 28, width: 3, height: 2, color: 0x6bc2e2, alpha: 0.58 }
  ]),
  down: Object.freeze([
    { x: -10, y: -31, width: 5, height: 2, color: 0xbfefff, alpha: 0.68 },
    { x: -12, y: -12, width: 2, height: 9, color: 0x9fe4f7, alpha: 0.62 },
    { x: 11, y: -8, width: 2, height: 8, color: 0x70c5e4, alpha: 0.58 },
    { x: -6, y: 2, width: 3, height: 12, color: 0x23536c, alpha: 0.3 },
    { x: 7, y: 5, width: 2, height: 12, color: 0xaeeaff, alpha: 0.52 },
    { x: -8, y: 22, width: 4, height: 2, color: 0x86d7ef, alpha: 0.58 },
    { x: 8, y: 28, width: 3, height: 2, color: 0xa8e8fb, alpha: 0.62 }
  ]),
  side: Object.freeze([
    { x: 8, y: -31, width: 4, height: 2, color: 0xc5f2ff, alpha: 0.7 },
    { x: -8, y: -12, width: 2, height: 8, color: 0x73c7e5, alpha: 0.58 },
    { x: 8, y: -9, width: 2, height: 11, color: 0xb1edff, alpha: 0.64 },
    { x: -3, y: 1, width: 3, height: 14, color: 0x24546c, alpha: 0.3 },
    { x: 7, y: 7, width: 2, height: 9, color: 0x83d6ef, alpha: 0.5 },
    { x: -6, y: 23, width: 3, height: 2, color: 0xaeeaff, alpha: 0.6 },
    { x: 7, y: 28, width: 4, height: 2, color: 0x78cce8, alpha: 0.58 }
  ])
});

export interface DormRainSoakedVisualUpdate {
  active: boolean;
  timeMs: number;
  velocityX: number;
  velocityY: number;
  facing: RpgPlayerFacing;
}

export interface DormRainSoakedVisualDebugSnapshot {
  active: boolean;
  moving: boolean;
  dropletCount: number;
  footprintCount: number;
  effectMode: "full" | "reduced" | "off";
}

/** Canvas-safe wet-character presentation made from pixel shapes and tweens. */
export class DormRainSoakedPlayerVisual {
  private readonly scene: Phaser.Scene;
  private readonly player: Phaser.Physics.Arcade.Sprite;
  private readonly reducedMotion: boolean;
  private readonly bodyLayer: Phaser.GameObjects.Container;
  private readonly groundLayer: Phaser.GameObjects.Container;
  private readonly wetPatches: Phaser.GameObjects.Ellipse[];
  private readonly highlights: Phaser.GameObjects.Rectangle[];
  private readonly droplets: Phaser.GameObjects.Rectangle[];
  private readonly groundSheen: Phaser.GameObjects.Ellipse;
  private readonly ripples: Phaser.GameObjects.Ellipse[];
  private footprints: Phaser.GameObjects.Ellipse[] = [];
  private active = false;
  private moving = false;
  private footprintSide = 1;
  private lastFootprintPosition: { x: number; y: number } | null = null;
  private destroyed = false;

  constructor(
    scene: Phaser.Scene,
    player: Phaser.Physics.Arcade.Sprite,
    reducedMotion: boolean
  ) {
    this.scene = scene;
    this.player = player;
    this.reducedMotion = reducedMotion;

    this.groundSheen = scene.add.ellipse(0, 0, 40, 12, 0x1c556f, 0.28)
      .setStrokeStyle(2, 0xb9eef8, 0.26);
    this.ripples = [0, 1].map(() => scene.add.ellipse(0, 0, 34, 8, 0x235a73, 0)
      .setStrokeStyle(2, 0xaee7f4, 0.34));
    this.groundLayer = scene.add.container(0, 0, [this.groundSheen, ...this.ripples])
      .setVisible(false);

    this.wetPatches = Array.from({ length: WET_PATCH_LAYOUTS.up.length }, () => (
      scene.add.ellipse(0, 0, 10, 10, 0x295d76, 0.18)
    ));
    this.highlights = Array.from({ length: WET_HIGHLIGHT_LAYOUTS.up.length }, () => (
      scene.add.rectangle(0, 0, 2, 4, 0xaeeaff, 0.6)
    ));
    this.droplets = WET_DROPLET_SPECS.map((spec, index) => (
      scene.add.rectangle(0, 0, spec.width, spec.height, index % 3 === 0 ? 0xc8f4ff : 0x82d8ef, 0.92)
    ));
    this.bodyLayer = scene.add.container(0, 0, [...this.wetPatches, ...this.highlights, ...this.droplets])
      .setVisible(false);

    scene.events.once(Phaser.Scenes.Events.SHUTDOWN, this.destroy, this);
    scene.events.once(Phaser.Scenes.Events.DESTROY, this.destroy, this);
  }

  update(update: DormRainSoakedVisualUpdate): void {
    if (this.destroyed) return;
    if (this.active !== update.active) {
      this.active = update.active;
      this.bodyLayer.setVisible(this.active);
      this.groundLayer.setVisible(this.active);
      this.lastFootprintPosition = this.active
        ? { x: this.player.x, y: this.player.y }
        : null;
      if (!this.active) this.clearFootprints();
    }
    if (!this.active) {
      this.moving = false;
      return;
    }

    const speed = Math.hypot(update.velocityX, update.velocityY);
    this.moving = speed > 1;
    const directionX = speed > 0 ? update.velocityX / speed : 0;
    const directionY = speed > 0 ? update.velocityY / speed : 0;
    const mirror = this.player.flipX ? -1 : 1;
    const playerDepth = this.player.depth;

    this.bodyLayer
      .setPosition(this.player.x, this.player.y)
      .setScale(mirror, 1)
      .setDepth(playerDepth + 3);
    this.groundLayer
      .setPosition(this.player.x, this.player.y + 39)
      .setDepth(playerDepth - 3);

    const highlightLayout = WET_HIGHLIGHT_LAYOUTS[update.facing];
    const wetPatchLayout = WET_PATCH_LAYOUTS[update.facing];
    this.wetPatches.forEach((patch, index) => {
      const layout = wetPatchLayout[index];
      const pulse = this.reducedMotion
        ? 1
        : 0.92 + Math.sin(update.timeMs * 0.004 + index * 0.9) * 0.08;
      patch
        .setPosition(layout.x, layout.y)
        .setDisplaySize(layout.width, layout.height)
        .setFillStyle(layout.color, layout.alpha * pulse);
    });
    this.highlights.forEach((highlight, index) => {
      const layout = highlightLayout[index];
      const pulse = this.reducedMotion
        ? 0.9
        : 0.84 + Math.sin(update.timeMs * 0.007 + index * 1.7) * 0.16;
      highlight
        .setPosition(layout.x, layout.y)
        .setDisplaySize(layout.width, layout.height)
        .setFillStyle(layout.color, layout.alpha * pulse);
    });

    const visibleDroplets = this.reducedMotion
      ? DORM_RAIN_SOAKED_VISUAL_PROFILE.reducedMotionDropletCount
      : DORM_RAIN_SOAKED_VISUAL_PROFILE.dropletCount;
    this.droplets.forEach((droplet, index) => {
      const spec = WET_DROPLET_SPECS[index];
      const visible = index < visibleDroplets;
      droplet.setVisible(visible);
      if (!visible) return;
      const motionMultiplier = this.moving ? 0.74 : 1;
      const reducedMultiplier = this.reducedMotion ? 1.65 : 1;
      const period = spec.period * motionMultiplier * reducedMultiplier;
      const progress = ((update.timeMs + spec.phase) % period) / period;
      const edgeFade = Math.min(progress / 0.12, (1 - progress) / 0.24, 1);
      const trailingDistance = this.moving ? progress * 13 : 0;
      const flutter = this.reducedMotion ? 0 : Math.sin(progress * Math.PI * 2 + index) * 1.3;
      droplet
        .setPosition(
          spec.x + flutter - directionX * trailingDistance * mirror,
          spec.y + progress * spec.travel - directionY * trailingDistance * 0.35
        )
        .setAlpha(Math.max(0, edgeFade) * (this.moving ? 1 : 0.88))
        .setAngle(this.moving ? Phaser.Math.Clamp(-directionX * 24, -24, 24) * mirror : 0);
    });

    const pulseTime = this.reducedMotion ? 0.25 : (update.timeMs % 1500) / 1500;
    this.groundSheen
      .setScale(this.moving ? 0.86 : 1 + Math.sin(update.timeMs * 0.004) * 0.06, 1)
      .setAlpha(this.moving ? 0.18 : 0.3);
    this.ripples.forEach((ripple, index) => {
      const phase = (pulseTime + index * 0.5) % 1;
      ripple
        .setScale(0.75 + phase * 0.65, 0.8 + phase * 0.3)
        .setAlpha((1 - phase) * (this.moving ? 0.18 : 0.36));
    });

    if (this.moving && !this.reducedMotion) {
      this.maybeLeaveFootprint(directionX, directionY);
    }
  }

  getDebugSnapshot(): DormRainSoakedVisualDebugSnapshot {
    return {
      active: this.active,
      moving: this.moving,
      dropletCount: this.active
        ? (this.reducedMotion
          ? DORM_RAIN_SOAKED_VISUAL_PROFILE.reducedMotionDropletCount
          : DORM_RAIN_SOAKED_VISUAL_PROFILE.dropletCount)
        : 0,
      footprintCount: this.footprints.length,
      effectMode: this.active ? (this.reducedMotion ? "reduced" : "full") : "off"
    };
  }

  destroy(): void {
    if (this.destroyed) return;
    this.destroyed = true;
    this.scene.events.off(Phaser.Scenes.Events.SHUTDOWN, this.destroy, this);
    this.scene.events.off(Phaser.Scenes.Events.DESTROY, this.destroy, this);
    this.clearFootprints();
    this.bodyLayer.destroy(true);
    this.groundLayer.destroy(true);
  }

  private maybeLeaveFootprint(directionX: number, directionY: number): void {
    if (this.lastFootprintPosition === null) {
      this.lastFootprintPosition = { x: this.player.x, y: this.player.y };
      return;
    }
    if (Phaser.Math.Distance.Between(
      this.lastFootprintPosition.x,
      this.lastFootprintPosition.y,
      this.player.x,
      this.player.y
    ) < DORM_RAIN_SOAKED_VISUAL_PROFILE.footprintSpacing) return;
    this.lastFootprintPosition = { x: this.player.x, y: this.player.y };
    this.footprintSide *= -1;
    const lateralX = -directionY * this.footprintSide * 5;
    const lateralY = directionX * this.footprintSide * 2;
    const footprint = this.scene.add.ellipse(
      this.player.x + lateralX,
      this.player.y + 39 + lateralY,
      12,
      5,
      0x22566e,
      0.38
    ).setStrokeStyle(1, 0xa9e6f5, 0.26)
      .setAngle(Phaser.Math.RadToDeg(Math.atan2(directionY, directionX)))
      .setDepth(this.player.depth - 4);
    this.footprints.push(footprint);
    while (this.footprints.length > DORM_RAIN_SOAKED_VISUAL_PROFILE.maxFootprints) {
      const oldest = this.footprints.shift();
      if (!oldest) break;
      this.scene.tweens.killTweensOf(oldest);
      oldest.destroy();
    }
    this.scene.tweens.add({
      targets: footprint,
      scaleX: 1.45,
      scaleY: 1.25,
      alpha: 0,
      duration: DORM_RAIN_SOAKED_VISUAL_PROFILE.footprintLifetimeMs,
      ease: "Sine.easeOut",
      onComplete: () => {
        this.footprints = this.footprints.filter((entry) => entry !== footprint);
        footprint.destroy();
      }
    });
  }

  private clearFootprints(): void {
    for (const footprint of this.footprints) {
      this.scene.tweens.killTweensOf(footprint);
      footprint.destroy();
    }
    this.footprints = [];
  }
}
