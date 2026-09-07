import Phaser from "phaser";
import { RPG_PIXEL_FONT_FAMILY } from "./RpgRenderResolution";

/** A seven-second paper close-up. Presentation only; the scene owns progression. */
export function createChapterFourPaperPickupPresentation(scene: Phaser.Scene): Phaser.GameObjects.Container {
  const root = scene.add.container(0, 0).setScrollFactor(0).setDepth(12500);
  const ink = 0x26332f;
  const cream = 0xf0e4c4;
  const red = 0xa43f32;
  const text = (x: number, y: number, value: string, size: number, color = "#26332f") =>
    scene.add.text(x, y, value, {
      fontFamily: RPG_PIXEL_FONT_FAMILY, fontSize: `${size}px`, color,
      fontStyle: "normal", resolution: 2, padding: { x: 3, y: 3 }
    }).setOrigin(0.5);

  const shade = scene.add.rectangle(0, 0, 960, 540, 0x0e1717, 0.86).setAlpha(0);
  const frame = scene.add.graphics();
  frame.lineStyle(1, 0xd6c8a5, 0.28);
  frame.lineBetween(-438, -188, 438, -188);
  frame.lineBetween(-438, 206, 438, 206);
  const kicker = text(-350, -209, "一张迟到的记录", 14, "#c9c2af");
  const serial = text(370, -209, "第四章 / 7:55", 12, "#9aab9f");
  const room = scene.add.container(-286, -25).setAlpha(0);
  room.add([
    text(0, -68, "此刻 · 教学楼", 16, "#b0bcae"),
    text(0, -12, "22:45", 48, "#ead8a9"),
    scene.add.rectangle(0, 35, 100, 1, 0xb9b995, 0.5),
    text(0, 67, "夜还没有结束", 14, "#9aab9f")
  ]);

  const paper = scene.add.container(70, 320).setAngle(-12).setAlpha(0);
  const shape = scene.add.graphics();
  shape.fillStyle(0x020909, 0.48);
  shape.fillRect(-145, -169, 326, 353);
  shape.fillStyle(cream, 1);
  shape.beginPath();
  shape.moveTo(-164, -181);
  shape.lineTo(135, -181);
  shape.lineTo(164, -151);
  shape.lineTo(164, 169);
  for (let x = 164; x > -164; x -= 16) {
    shape.lineTo(x - 8, 175);
    shape.lineTo(Math.max(-164, x - 16), 169);
  }
  shape.lineTo(-164, -181);
  shape.closePath();
  shape.fillPath();
  shape.fillStyle(0xc4b691);
  shape.fillTriangle(135, -181, 135, -151, 164, -151);
  shape.lineStyle(1, ink, 0.22);
  shape.lineBetween(-137, -71, 137, -71);
  shape.lineBetween(-137, 35, 137, 35);
  shape.lineBetween(-137, 114, 137, 114);
  // A crease, perforations and uneven ink make the paper itself the focal point.
  shape.lineStyle(1, 0xffffff, 0.34);
  shape.lineBetween(-155, 65, 156, 55);
  shape.lineStyle(1, ink, 0.08);
  shape.lineBetween(-155, 67, 156, 57);
  for (let y = -146; y < 145; y += 22) {
    shape.fillStyle(0xb8af96, 0.6);
    shape.fillCircle(-151, y, 2);
  }
  for (let n = 0; n < 31; n++) {
    shape.fillStyle(ink, n % 3 === 0 ? 0.6 : 0.28);
    shape.fillRect(-106 + n * 7, 133, n % 4 === 0 ? 4 : 2, 15 + n % 3 * 3);
  }
  paper.add([
    shape,
    text(0, -143, "签 到 记 录", 26),
    text(0, -103, "已找回的纸条", 13, "#6a7160"),
    text(0, -47, "手机停留在", 14, "#77745e"),
    text(0, -3, "07:55:23", 42),
    text(0, 88, "纸条回来了，时间没有。", 16)
  ]);

  const stamp = scene.add.container(13, 63).setAngle(-9).setScale(1.65).setAlpha(0);
  const stampBorder = scene.add.graphics().lineStyle(3, red, 0.94);
  stampBorder.strokeRect(-102, -25, 204, 50);
  stampBorder.lineStyle(1, red, 0.8).strokeRect(-96, -19, 192, 38);
  stamp.add([stampBorder, text(0, 0, "时间不符", 26, "#a43f32")]);
  paper.add(stamp);
  const footer = text(0, 226, "签到记录已收好", 14, "#ddcfad").setAlpha(0);
  root.add([shade, frame, kicker, serial, room, paper, footer]);

  const layout = () => {
    const camera = scene.cameras.main;
    // Cancel map zoom while retaining the single 960 × 540 presentation space.
    root.setPosition(camera.width / 2, camera.height / 2);
    root.setScale(camera.width / 960 / camera.zoom);
  };
  layout();
  scene.events.on(Phaser.Scenes.Events.POST_UPDATE, layout);
  const tweens: Phaser.Tweens.Tween[] = [];
  const animate = (config: Phaser.Types.Tweens.TweenBuilderConfig) => { tweens.push(scene.tweens.add(config)); };
  animate({ targets: shade, alpha: 1, duration: 350 });
  animate({ targets: paper, y: -3, angle: 3, alpha: 1, duration: 850, ease: "Cubic.easeOut" });
  animate({ targets: room, alpha: 1, delay: 900, duration: 600 });
  animate({ targets: stamp, alpha: 1, scale: 1, delay: 2600, duration: 220, ease: "Cubic.easeIn" });
  animate({ targets: paper, x: 73, y: 1, angle: 2, delay: 2820, duration: 90, yoyo: true });
  animate({ targets: footer, alpha: 1, delay: 3100, duration: 400 });
  animate({ targets: paper, x: 305, y: 242, scale: 0.26, angle: -6, alpha: 0, delay: 5200, duration: 600, ease: "Cubic.easeIn" });
  animate({ targets: [shade, frame, kicker, serial, room, footer], alpha: 0, delay: 5500, duration: 550 });
  root.once(Phaser.GameObjects.Events.DESTROY, () => {
    scene.events.off(Phaser.Scenes.Events.POST_UPDATE, layout);
    tweens.forEach(tween => tween.remove());
  });
  return root;
}
