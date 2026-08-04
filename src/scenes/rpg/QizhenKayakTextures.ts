import Phaser from "phaser";

export type QizhenPaddleSide = "left" | "right";

export interface QizhenKayakPose {
  x: number;
  y: number;
  heading: number;
  roll: number;
  speed: number;
  chasing?: boolean;
}

const HULL_LENGTH = 124;
const HULL_HALF_WIDTH = 25;
const KAYAK_DISPLAY_SCALE = 0.72;
const ROWER_DISPLAY_SCALE = 0.72;

/**
 * Scene-local presentation object. Progression remains owned by the TypeScript
 * controller; this class only animates the kayak, seated rower and paddles.
 */
export class QizhenKayakVisual {
  readonly root: Phaser.GameObjects.Container;
  private readonly scene: Phaser.Scene;
  private readonly body: Phaser.GameObjects.Container;
  private readonly leftPaddle: Phaser.GameObjects.Container;
  private readonly rightPaddle: Phaser.GameObjects.Container;
  private readonly leftArm: Phaser.GameObjects.Rectangle;
  private readonly rightArm: Phaser.GameObjects.Rectangle;
  private readonly wakeLeft: Phaser.GameObjects.Ellipse;
  private readonly wakeRight: Phaser.GameObjects.Ellipse;
  private lastHeading = -Math.PI / 2;
  private destroyed = false;

  constructor(scene: Phaser.Scene) {
    this.scene = scene;

    this.wakeLeft = scene.add.ellipse(-42, 0, 86, 18, 0xd9fbff, 0)
      .setStrokeStyle(2, 0xd7fbff, 0.46)
      .setName("kayakWakeLeft");
    this.wakeRight = scene.add.ellipse(-64, 0, 120, 28, 0xbcefff, 0)
      .setStrokeStyle(2, 0xa8eaff, 0.3)
      .setName("kayakWakeRight");

    const shadow = scene.add.ellipse(0, 8, 130, 45, 0x031b28, 0.34);
    const hull = scene.add.polygon(0, 0, [
      HULL_LENGTH / 2, 0,
      44, -HULL_HALF_WIDTH,
      -35, -HULL_HALF_WIDTH + 3,
      -HULL_LENGTH / 2, 0,
      -35, HULL_HALF_WIDTH - 3,
      44, HULL_HALF_WIDTH
    ], 0xea7d27, 1).setStrokeStyle(4, 0x63301a, 1);
    const hullInset = scene.add.polygon(0, 0, [
      49, 0,
      35, -16,
      -30, -14,
      -49, 0,
      -30, 14,
      35, 16
    ], 0x963d24, 1).setStrokeStyle(3, 0xffbb52, 0.82);
    const bowHighlight = scene.add.triangle(48, 0, -10, -11, 14, 0, -10, 11, 0xffc45f, 0.9);
    const sternBand = scene.add.rectangle(-37, 0, 8, 35, 0x4d2725, 0.96);
    const seat = scene.add.ellipse(-2, 0, 38, 25, 0x1d2b38, 1).setStrokeStyle(3, 0xb5844a, 0.9);

    const legs = scene.add.container(13, 0, [
      scene.add.rectangle(0, -7, 25, 7, 0x233d58, 1).setAngle(-8),
      scene.add.rectangle(0, 7, 25, 7, 0x233d58, 1).setAngle(8),
      scene.add.rectangle(13, -8, 8, 6, 0xe9e3d2, 1),
      scene.add.rectangle(13, 8, 8, 6, 0xe9e3d2, 1)
    ]);
    const torso = scene.add.rectangle(-3, 0, 28, 24, 0x285479, 1).setStrokeStyle(2, 0x11283c, 1);
    const collar = scene.add.rectangle(7, 0, 5, 19, 0xa5d8ed, 0.82);
    const head = scene.add.circle(-19, 0, 11, 0xf0c7a0, 1).setStrokeStyle(3, 0x202831, 1);
    const hair = scene.add.arc(-22, 0, 11, 80, 280, false, 0x1b2531, 1);
    this.leftArm = scene.add.rectangle(-2, -17, 31, 7, 0xf0c7a0, 1)
      .setOrigin(0.12, 0.5)
      .setAngle(-18);
    this.rightArm = scene.add.rectangle(-2, 17, 31, 7, 0xf0c7a0, 1)
      .setOrigin(0.12, 0.5)
      .setAngle(18);

    this.leftPaddle = this.createBranchPaddle();
    this.rightPaddle = this.createWarningSignPaddle();
    const rower = scene.add.container(-2, 0, [
      legs,
      torso,
      collar,
      this.leftArm,
      this.rightArm,
      head,
      hair
    ]).setScale(ROWER_DISPLAY_SCALE);
    this.body = scene.add.container(0, 0, [
      shadow,
      hull,
      hullInset,
      bowHighlight,
      sternBand,
      seat,
      rower,
      this.leftPaddle,
      this.rightPaddle
    ]);
    this.root = scene.add.container(0, 0, [this.wakeRight, this.wakeLeft, this.body])
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
    const speedRatio = Phaser.Math.Clamp(Math.abs(pose.speed) / 360, 0, 1);
    this.root
      .setPosition(pose.x, pose.y)
      .setRotation(pose.heading)
      .setDepth(pose.y + 150);
    this.body
      .setAngle(rollRatio * 12)
      .setScale(1 + Math.abs(rollRatio) * 0.035, 1 - Math.abs(rollRatio) * 0.1);
    this.wakeLeft.setAlpha(0.12 + speedRatio * 0.54).setScale(0.76 + speedRatio * 0.7);
    this.wakeRight.setAlpha(0.08 + speedRatio * 0.36).setScale(0.68 + speedRatio * 0.9);
    this.body.setScale(
      1 + Math.abs(rollRatio) * 0.035 + (pose.chasing ? 0.012 : 0),
      1 - Math.abs(rollRatio) * 0.1
    );
  }

  stroke(side: QizhenPaddleSide, intensity = 1): void {
    if (this.destroyed || !this.root.visible) return;
    const paddle = side === "left" ? this.leftPaddle : this.rightPaddle;
    const arm = side === "left" ? this.leftArm : this.rightArm;
    const restAngle = side === "left" ? -28 : 28;
    const pullAngle = side === "left" ? 36 : -36;
    this.scene.tweens.killTweensOf([paddle, arm]);
    paddle.setAngle(restAngle - (side === "left" ? 24 : -24));
    arm.setAngle(side === "left" ? -28 : 28);
    this.scene.tweens.add({
      targets: paddle,
      angle: pullAngle,
      duration: 135,
      ease: "Cubic.easeOut",
      yoyo: true,
      hold: 35,
      onComplete: () => paddle.setAngle(restAngle)
    });
    this.scene.tweens.add({
      targets: arm,
      angle: side === "left" ? 26 : -26,
      duration: 125,
      ease: "Sine.easeInOut",
      yoyo: true
    });
    this.splash(side, intensity);
  }

  playCapsize(onComplete: () => void): void {
    if (this.destroyed) return;
    this.scene.tweens.killTweensOf(this.body);
    this.scene.tweens.add({
      targets: this.body,
      angle: this.body.angle >= 0 ? 105 : -105,
      scaleY: 0.18,
      alpha: 0.38,
      duration: 390,
      ease: "Cubic.easeIn",
      yoyo: true,
      hold: 260,
      onComplete: () => {
        this.body.setAngle(0).setScale(1).setAlpha(1);
        onComplete();
      }
    });
  }

  destroy(): void {
    if (this.destroyed) return;
    this.destroyed = true;
    this.scene.tweens.killTweensOf(this.root);
    this.scene.tweens.killTweensOf(this.body);
    this.scene.tweens.killTweensOf(this.leftPaddle);
    this.scene.tweens.killTweensOf(this.rightPaddle);
    this.root.destroy(true);
  }

  private createBranchPaddle(): Phaser.GameObjects.Container {
    const shaft = this.scene.add.rectangle(0, 0, 106, 7, 0x71502c, 1)
      .setStrokeStyle(2, 0x2d261b, 1);
    const blade = this.scene.add.polygon(-58, 0, [
      -13, 0, -5, -11, 11, -8, 16, 0, 11, 8, -5, 11
    ], 0x9a6a37, 1).setStrokeStyle(2, 0x3b2a1c, 1);
    const cutOne = this.scene.add.rectangle(-16, -5, 16, 4, 0xb58a52, 1).setAngle(-24);
    const cutTwo = this.scene.add.rectangle(8, 5, 14, 4, 0xb58a52, 1).setAngle(22);
    const ring = this.scene.add.circle(45, 0, 5, 0xc39a63, 1).setStrokeStyle(2, 0x46321f, 1);
    return this.scene.add.container(0, -31, [shaft, blade, cutOne, cutTwo, ring])
      .setAngle(-28)
      .setName("leftBranchPaddle");
  }

  private createWarningSignPaddle(): Phaser.GameObjects.Container {
    const shaft = this.scene.add.rectangle(0, 0, 108, 7, 0xb4b9b5, 1)
      .setStrokeStyle(2, 0x333b3c, 1);
    const sign = this.scene.add.triangle(59, 0, -18, 16, -18, -16, 18, 0, 0xffe46b, 1)
      .setStrokeStyle(4, 0xe33b2f, 1);
    const iconHead = this.scene.add.circle(54, -3, 3, 0x263640, 1);
    const iconBody = this.scene.add.rectangle(59, 4, 12, 3, 0x263640, 1).setAngle(-15);
    const slash = this.scene.add.rectangle(59, 0, 30, 3, 0xe33b2f, 1).setAngle(42);
    const grip = this.scene.add.rectangle(-44, 0, 23, 10, 0x2b3d42, 1).setStrokeStyle(2, 0xd4ece8, 0.7);
    return this.scene.add.container(0, 31, [shaft, sign, iconHead, iconBody, slash, grip])
      .setAngle(28)
      .setName("rightWarningSignPaddle");
  }

  private splash(side: QizhenPaddleSide, intensity: number): void {
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
  }
}

export interface QizhenBlackSwanVisual {
  root: Phaser.GameObjects.Container;
  update: (x: number, y: number, heading: number, wingBeat: number) => void;
  destroy: () => void;
}

export function createQizhenBlackSwanVisual(scene: Phaser.Scene): QizhenBlackSwanVisual {
  const wake = scene.add.ellipse(-30, 0, 92, 30, 0xdefaff, 0)
    .setStrokeStyle(2, 0xdafaff, 0.48);
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
    wake,
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
    update: (x, y, heading, wingBeat) => {
      root.setPosition(x, y).setRotation(heading).setDepth(y + 165);
      leftWing.setAngle(-16 - wingBeat * 24);
      rightWing.setAngle(16 + wingBeat * 24);
      wake.setScale(0.9 + Math.abs(wingBeat) * 0.35).setAlpha(0.24 + Math.abs(wingBeat) * 0.35);
    },
    destroy: () => root.destroy(true)
  };
}
