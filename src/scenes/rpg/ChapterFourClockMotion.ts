import Phaser from "phaser";

/** Local mechanism motion, never an authority for chapter time or completion. */
export class ChapterFourClockMotion {
  private readonly face: Phaser.GameObjects.Image;
  private readonly hands: Phaser.GameObjects.Graphics;
  private elapsed = 0;
  private stateKey = "";
  private lastDraw = -Infinity;

  constructor(scene: Phaser.Scene) {
    this.face = scene.add.image(0, 0, "chapter4_clock_states", "blank_face");
    this.hands = scene.add.graphics();
  }

  update(delta: number, options: {
    x: number; y: number; radius: number; scale: number; depth: number; visible: boolean;
    frame: string; seconds: number; running: boolean; hasHourHand: boolean;
    manualMinute: boolean;
  }): void {
    const { frame, seconds, running, manualMinute } = options;
    this.face.setVisible(options.visible).setPosition(options.x, options.y).setScale(options.scale).setDepth(options.depth);
    this.hands.setVisible(options.visible).setPosition(options.x, options.y).setDepth(options.depth + 1);
    if (!options.visible) return;
    const key = `${frame}:${seconds}:${running}:${manualMinute}:${options.hasHourHand}`;
    if (key !== this.stateKey) {
      this.stateKey = key;
      this.elapsed = 0;
      this.lastDraw = -Infinity;
    }
    this.elapsed += Math.min(delta, 100) / 1000;
    if (this.elapsed - this.lastDraw < 1 / 24) return;
    this.lastDraw = this.elapsed;
    const g = this.hands.clear();
    const radius = options.radius;
    const movingSeconds = running && !manualMinute ? this.elapsed : 0;
    const time = seconds + movingSeconds;
    const beat = this.elapsed % 1.4;
    const recoil = running ? 0 : Math.sin(Math.min(1, beat / 0.46) * Math.PI) * 0.07;
    const point = (angle: number, length: number) => ({ x: Math.sin(angle) * length, y: -Math.cos(angle) * length });
    const hand = (angle: number, length: number, width: number, color: number) => {
      const end = point(angle, length);
      g.lineStyle(width + 1, 0x191e19, 0.3).lineBetween(1, 1, end.x + 1, end.y + 1);
      g.lineStyle(width, color, 1).lineBetween(0, 0, end.x, end.y);
    };
    const gear = (x: number, y: number, r: number, angle: number) => {
      g.lineStyle(1.1, 0x997038, 0.9).strokeCircle(x, y, r * 0.72);
      for (let i = 0; i < 10; i++) {
        const a = angle + i * Math.PI / 5;
        g.lineBetween(x + Math.cos(a) * r * 0.62, y + Math.sin(a) * r * 0.62,
          x + Math.cos(a) * r, y + Math.sin(a) * r);
      }
      g.fillStyle(0x654b2c).fillCircle(x, y, 1);
    };
    // Counter-rotating wheels make the repair state legible without speeding up time.
    const gearing = running && !manualMinute ? this.elapsed * 0.8 : recoil * 3;
    g.fillStyle(0x463d2d, 0.13).fillRoundedRect(-13, radius * 0.4 - 8, 26, 14, 3);
    gear(-6, radius * 0.4 - 1, 5, gearing);
    gear(5, radius * 0.4 - 1, 6, -gearing * 5 / 6);
    if (options.hasHourHand) hand((time % 43200) / 43200 * Math.PI * 2, radius * 0.49, 3.2, 0x26312c);
    if (!manualMinute) hand((time % 3600) / 3600 * Math.PI * 2 + recoil, radius * 0.77, 2.2, 0x38423a);
    if (running && !manualMinute) {
      const angle = (Math.floor(time) % 60) / 60 * Math.PI * 2;
      const end = point(angle, radius * 0.83);
      const tail = point(angle, -radius * 0.18);
      g.lineStyle(1, 0xaa4932, 1).lineBetween(tail.x, tail.y, end.x, end.y);
    }
    g.fillStyle(0x785128).fillCircle(0, 0, 3);
    g.fillStyle(0xe0b569).fillCircle(-0.5, -0.5, 1.7);
  }

  destroy(): void { this.face.destroy(); this.hands.destroy(); }
}
