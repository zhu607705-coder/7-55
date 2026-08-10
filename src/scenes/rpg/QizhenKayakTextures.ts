import Phaser from "phaser";
import type { QizhenPaddleDirection } from "../../core/types";
import kayakFrameAUrl from "../../assets/rpg/qizhen/kayak_overhead_frame_a.png";
import kayakFrameBUrl from "../../assets/rpg/qizhen/kayak_overhead_frame_b.png";

export type QizhenPaddleSide = "left" | "right";

export interface QizhenKayakPose {
  x: number;
  y: number;
  heading: number;
  roll: number;
  speed: number;
  chasing?: boolean;
}

const KAYAK_FRAME_A_KEY = "qizhen-kayak-overhead-a";
const KAYAK_FRAME_B_KEY = "qizhen-kayak-overhead-b";
const KAYAK_DISPLAY_SCALE = 0.52;

export function preloadQizhenKayakTextures(scene: Phaser.Scene): void {
  if (!scene.textures.exists(KAYAK_FRAME_A_KEY)) {
    scene.load.image(KAYAK_FRAME_A_KEY, kayakFrameAUrl);
  }
  if (!scene.textures.exists(KAYAK_FRAME_B_KEY)) {
    scene.load.image(KAYAK_FRAME_B_KEY, kayakFrameBUrl);
  }
}

/**
 * Scene-local presentation object. Progression remains owned by the TypeScript
 * controller; this class only animates the kayak, seated rower and paddles.
 */
export class QizhenKayakVisual {
  readonly root: Phaser.GameObjects.Container;
  private readonly scene: Phaser.Scene;
  private readonly body: Phaser.GameObjects.Container;
  private readonly sprite: Phaser.GameObjects.Image;
  private readonly wakeLeft: Phaser.GameObjects.Ellipse;
  private readonly wakeRight: Phaser.GameObjects.Ellipse;
  private readonly bowWakeLeft: Phaser.GameObjects.Ellipse;
  private readonly bowWakeRight: Phaser.GameObjects.Ellipse;
  private lastHeading = -Math.PI / 2;
  private forcedFrameUntil = 0;
  private forcedFrame: 0 | 1 = 0;
  private destroyed = false;

  constructor(scene: Phaser.Scene) {
    this.scene = scene;

    this.wakeLeft = scene.add.ellipse(0, 58, 32, 78, 0xd9fbff, 0)
      .setStrokeStyle(2, 0xd7fbff, 0.46)
      .setName("kayakWakeLeft");
    this.wakeRight = scene.add.ellipse(0, 72, 46, 112, 0xbcefff, 0)
      .setStrokeStyle(2, 0xa8eaff, 0.3)
      .setName("kayakWakeRight");
    this.bowWakeLeft = scene.add.ellipse(0, -54, 30, 68, 0xd9fbff, 0)
      .setStrokeStyle(2, 0xe7fdff, 0.5)
      .setName("kayakReverseWakeLeft");
    this.bowWakeRight = scene.add.ellipse(0, -66, 44, 94, 0xbcefff, 0)
      .setStrokeStyle(2, 0xbcefff, 0.36)
      .setName("kayakReverseWakeRight");
    this.sprite = scene.add.image(0, 0, KAYAK_FRAME_A_KEY)
      .setName("qizhenKayakTwoFrameSprite");
    this.sprite.texture.setFilter(Phaser.Textures.FilterMode.NEAREST);
    this.body = scene.add.container(0, 0, [this.sprite]);
    this.root = scene.add.container(0, 0, [
      this.wakeRight,
      this.wakeLeft,
      this.bowWakeRight,
      this.bowWakeLeft,
      this.body
    ])
      .setDepth(1900)
      .setScale(KAYAK_DISPLAY_SCALE)
      .setVisible(false)
      .setName("qizhenKayakVisual");
  }

  setVisible(visible: boolean): this {
    this.root.setVisible(visible);
    return this;
  }

  setPose(pose: QizhenKayakPose): void {
    if (this.destroyed) return;
    this.lastHeading = pose.heading;
    const rollRatio = Phaser.Math.Clamp(pose.roll, -1, 1);
    const forwardSpeedRatio = Phaser.Math.Clamp(Math.max(0, pose.speed) / 360, 0, 1);
    const reverseSpeedRatio = Phaser.Math.Clamp(Math.max(0, -pose.speed) / 230, 0, 1);
    const speedRatio = Math.max(forwardSpeedRatio, reverseSpeedRatio);
    this.root
      .setPosition(pose.x, pose.y)
      .setRotation(pose.heading + Math.PI / 2)
      .setDepth(pose.y + 150);
    this.body
      .setPosition(0, rollRatio * 5)
      .setAngle(0)
      .setScale(1 + (pose.chasing ? 0.012 : 0));
    this.wakeLeft
      .setAlpha(forwardSpeedRatio * 0.66)
      .setScale(0.76 + forwardSpeedRatio * 0.7);
    this.wakeRight
      .setAlpha(forwardSpeedRatio * 0.44)
      .setScale(0.68 + forwardSpeedRatio * 0.9);
    this.bowWakeLeft
      .setAlpha(reverseSpeedRatio * 0.72)
      .setScale(0.7 + reverseSpeedRatio * 0.82);
    this.bowWakeRight
      .setAlpha(reverseSpeedRatio * 0.5)
      .setScale(0.62 + reverseSpeedRatio * 0.96);
    const automaticFrame = Math.floor(this.scene.time.now / (speedRatio > 0.08 ? 150 : 420)) % 2 as 0 | 1;
    const frame = this.scene.time.now < this.forcedFrameUntil ? this.forcedFrame : automaticFrame;
    this.sprite.setTexture(frame === 0 ? KAYAK_FRAME_A_KEY : KAYAK_FRAME_B_KEY);
  }

  stroke(side: QizhenPaddleSide, direction: QizhenPaddleDirection, intensity = 1): void {
    if (this.destroyed || !this.root.visible) return;
    this.forcedFrame = side === "left" ? 1 : 0;
    this.forcedFrameUntil = this.scene.time.now + 180;
    this.sprite.setTexture(this.forcedFrame === 0 ? KAYAK_FRAME_A_KEY : KAYAK_FRAME_B_KEY);
    this.splash(side, direction, intensity);
  }

  playCapsize(onComplete: () => void): void {
    if (this.destroyed) return;
    this.scene.tweens.killTweensOf(this.body);
    this.scene.tweens.add({
      targets: this.body,
      y: this.body.y >= 0 ? 10 : -10,
      scale: 0.82,
      alpha: 0.38,
      duration: 390,
      ease: "Cubic.easeIn",
      yoyo: true,
      hold: 260,
      onComplete: () => {
        this.body.setPosition(0, 0).setAngle(0).setScale(1).setAlpha(1);
        onComplete();
      }
    });
  }

  destroy(): void {
    if (this.destroyed) return;
    this.destroyed = true;
    this.scene.tweens.killTweensOf(this.root);
    this.scene.tweens.killTweensOf(this.body);
    this.root.destroy(true);
  }

  private splash(side: QizhenPaddleSide, direction: QizhenPaddleDirection, intensity: number): void {
    const sideAngle = this.lastHeading + (side === "left" ? -Math.PI / 2 : Math.PI / 2);
    const x = this.root.x + Math.cos(sideAngle) * 48;
    const y = this.root.y + Math.sin(sideAngle) * 48;
    const splash = this.scene.add.ellipse(x, y, 26, 12, 0xd7fbff, 0)
      .setStrokeStyle(3, 0xe9ffff, 0.86)
      .setDepth(this.root.depth + 1)
      .setScale(0.45);
    this.scene.tweens.add({
      targets: splash,
      scaleX: 1.5 + intensity * 0.35,
      scaleY: 1.15 + intensity * 0.2,
      alpha: { from: 0.92, to: 0 },
      duration: 430,
      ease: "Cubic.easeOut",
      onComplete: () => splash.destroy()
    });

    const forwardX = Math.cos(this.lastHeading);
    const forwardY = Math.sin(this.lastHeading);
    const wakeOffset = direction === "reverse" ? 58 : -58;
    const strokeWake = this.scene.add.ellipse(
      this.root.x + forwardX * wakeOffset,
      this.root.y + forwardY * wakeOffset,
      direction === "reverse" ? 34 : 42,
      direction === "reverse" ? 18 : 14,
      0xd7fbff,
      0
    )
      .setStrokeStyle(3, direction === "reverse" ? 0xf3ffff : 0xcdf7ff, 0.9)
      .setRotation(this.lastHeading)
      .setDepth(this.root.depth - 1)
      .setScale(0.5);
    this.scene.tweens.add({
      targets: strokeWake,
      scaleX: 1.7 + intensity * 0.32,
      scaleY: 1.2 + intensity * 0.16,
      alpha: { from: 0.94, to: 0 },
      duration: direction === "reverse" ? 520 : 460,
      ease: "Cubic.easeOut",
      onComplete: () => strokeWake.destroy()
    });
  }
}

export interface QizhenBlackSwanVisual {
  root: Phaser.GameObjects.Container;
  update: (x: number, y: number, heading: number, wingBeat: number, chaseIntensity?: number) => void;
  destroy: () => void;
}

export function createQizhenBlackSwanVisual(scene: Phaser.Scene): QizhenBlackSwanVisual {
  const outerWake = scene.add.ellipse(-46, 0, 126, 46, 0xdefaff, 0)
    .setStrokeStyle(2, 0xdafaff, 0.3);
  const wake = scene.add.ellipse(-30, 0, 92, 30, 0xdefaff, 0)
    .setStrokeStyle(2, 0xdafaff, 0.48);
  const wakeLeft = scene.add.ellipse(-34, -17, 66, 16, 0xdefaff, 0)
    .setStrokeStyle(2, 0xf1ffff, 0.34).setAngle(-12);
  const wakeRight = scene.add.ellipse(-34, 17, 66, 16, 0xdefaff, 0)
    .setStrokeStyle(2, 0xf1ffff, 0.34).setAngle(12);
  const tail = scene.add.triangle(-31, 0, 15, -14, 15, 14, -18, 0, 0x10151c, 1)
    .setStrokeStyle(2, 0x344652, 0.9);
  const body = scene.add.ellipse(-2, 0, 64, 38, 0x10151c, 1)
    .setStrokeStyle(3, 0x3b4d58, 1);
  const breast = scene.add.ellipse(15, 0, 27, 30, 0x1b232c, 1);
  const leftWing = scene.add.polygon(-5, -10, [
    -21, 3, -10, -14, 8, -18, 25, -9, 14, 0, -3, 4
  ], 0x1a222b, 1).setStrokeStyle(2, 0x445660, 0.86);
  const rightWing = scene.add.polygon(-5, 10, [
    -21, -3, -10, 14, 8, 18, 25, 9, 14, 0, -3, -4
  ], 0x1a222b, 1).setStrokeStyle(2, 0x445660, 0.86);
  const leftFeathers = [
    scene.add.rectangle(-8, -16, 28, 3, 0x55646b, 0.58).setAngle(-16),
    scene.add.rectangle(-1, -20, 23, 3, 0x55646b, 0.46).setAngle(-9)
  ];
  const rightFeathers = [
    scene.add.rectangle(-8, 16, 28, 3, 0x55646b, 0.58).setAngle(16),
    scene.add.rectangle(-1, 20, 23, 3, 0x55646b, 0.46).setAngle(9)
  ];
  const neck = scene.add.graphics();
  neck.lineStyle(12, 0x0e141a, 1);
  neck.beginPath();
  neck.moveTo(18, 1);
  neck.lineTo(24, -8);
  neck.lineTo(31, -14);
  neck.lineTo(39, -12);
  neck.lineTo(44, -7);
  neck.strokePath();
  neck.lineStyle(2, 0x3c4b53, 0.7);
  neck.beginPath();
  neck.moveTo(20, 3);
  neck.lineTo(26, -6);
  neck.lineTo(33, -11);
  neck.strokePath();
  const head = scene.add.ellipse(46, -7, 17, 15, 0x0e141a, 1)
    .setStrokeStyle(2, 0x3c4b53, 1);
  const beakBand = scene.add.rectangle(53, -6, 5, 10, 0xe8edf0, 1).setAngle(3);
  const beak = scene.add.triangle(61, -5, -8, -6, 9, 0, -8, 6, 0xe34b32, 1)
    .setStrokeStyle(1, 0x71231e, 1);
  const eye = scene.add.circle(48, -11, 2, 0xf6e37a, 1)
    .setStrokeStyle(1, 0x050608, 1);
  const root = scene.add.container(0, 0, [
    outerWake,
    wake,
    wakeLeft,
    wakeRight,
    tail,
    body,
    breast,
    leftWing,
    rightWing,
    ...leftFeathers,
    ...rightFeathers,
    neck,
    head,
    beakBand,
    beak,
    eye
  ])
    .setDepth(1950)
    .setName("qizhenBlackSwan");
  return {
    root,
    update: (x, y, heading, wingBeat, chaseIntensity = 0) => {
      const intensity = Math.max(0, Math.min(1, chaseIntensity));
      const beatStrength = Math.abs(wingBeat);
      root
        .setPosition(x, y)
        .setRotation(heading)
        .setScale(1 + intensity * 0.09)
        .setDepth(y + 165);
      leftWing.setAngle(-16 - wingBeat * (24 + intensity * 11));
      rightWing.setAngle(16 + wingBeat * (24 + intensity * 11));
      outerWake
        .setScale(0.88 + intensity * 0.44, 0.86 + intensity * 0.22)
        .setAlpha(0.12 + intensity * 0.42);
      wake
        .setScale(0.9 + beatStrength * 0.35 + intensity * 0.28)
        .setAlpha(0.24 + beatStrength * 0.28 + intensity * 0.26);
      wakeLeft
        .setScale(0.82 + intensity * 0.7, 0.84 + beatStrength * 0.28)
        .setAlpha(0.12 + intensity * 0.5);
      wakeRight
        .setScale(0.82 + intensity * 0.7, 0.84 + (1 - Math.min(1, beatStrength)) * 0.18)
        .setAlpha(0.12 + intensity * 0.5);
    },
    destroy: () => root.destroy(true)
  };
}
