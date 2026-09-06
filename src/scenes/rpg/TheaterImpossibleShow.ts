import Phaser from "phaser";
import {
  createTheaterShow, getTheaterShowFood, getTheaterShowHazards, getTheaterShowMouth,
  stepTheaterShow, THEATER_SHOW_ACTS, THEATER_SHOW_MAX_TICKS, THEATER_SHOW_STEP_MS,
  type TheaterShowInput, type TheaterShowPoint, type TheaterShowState, type TheaterSpotlightAttempt
} from "./TheaterSpotlightModel";

type ShowScreen = "intro" | "running" | "paused" | "awaiting" | "result";
interface ShowCallbacks {
  submit: (attempt: TheaterSpotlightAttempt) => void;
  restart: () => void;
  finale: () => void;
}
const FONT = '"Fusion Pixel 12px Proportional SC", "Fusion Pixel", monospace';
const COLORS = { ink: 0x11152d, floor: 0x202947, cream: 0xfff0cb, rose: 0xe85881, gold: 0xffcf68, mint: 0x94f3d0 };
const PRIMARY = { x: 330, y: 351, width: 300, height: 49 };
const DASH = { x: 718, y: 460, width: 178, height: 44 };
const PAUSE = { x: 638, y: 460, width: 64, height: 44 };
function inside(point: TheaterShowPoint, box: { x: number; y: number; width: number; height: number }) {
  return point.x >= box.x && point.x <= box.x + box.width && point.y >= box.y && point.y <= box.y + box.height;
}

/** A new theatrical light-creature game, drawn entirely inside the existing Phaser surface. */
export class TheaterImpossibleShow {
  readonly container: Phaser.GameObjects.Container;
  private readonly art: Phaser.GameObjects.Graphics;
  private readonly hud: Phaser.GameObjects.Text;
  private readonly status: Phaser.GameObjects.Text;
  private readonly overlayTitle: Phaser.GameObjects.Text;
  private readonly overlayBody: Phaser.GameObjects.Text;
  private readonly primaryLabel: Phaser.GameObjects.Text;
  private readonly dashLabel: Phaser.GameObjects.Text;
  private readonly foodLabels: Phaser.GameObjects.Text[];
  private readonly mouthLabel: Phaser.GameObjects.Text;
  private readonly badge: Phaser.GameObjects.Text;
  private model: TheaterShowState;
  private screen: ShowScreen = "intro";
  private pointerTarget: TheaterShowPoint | null = null;
  private pointerHeld = false;
  private queuedDash = false;
  private inputs: TheaterShowInput[] = [];
  private accumulator = 0;
  private visualTime = 0;
  private finalAct = false;
  private approved = false;
  private disposed = false;
  private readonly visibilityHandler = () => {
    if (document.hidden && this.screen === "running") this.pause();
  };

  constructor(private readonly scene: Phaser.Scene, round: number, attempt: number, private readonly callbacks: ShowCallbacks) {
    this.model = createTheaterShow(round, attempt);
    this.container = scene.add.container(0, 0).setScrollFactor(0).setDepth(7000);
    this.art = scene.add.graphics();
    this.container.add(this.art);
    const text = (x: number, y: number, value: string, size = 16, color = "#fff0cb", center = false) => {
      const label = scene.add.text(x, y, value, { fontFamily: FONT, fontSize: `${size}px`, color, lineSpacing: 8,
        wordWrap: { width: center ? 540 : 640 }, align: center ? "center" : "left" });
      if (center) label.setOrigin(0.5);
      this.container.add(label);
      return label;
    };
    text(67, 61, "追光灯辞职以后", 23);
    this.badge = text(67, 95, `第 ${round + 1} 幕 / 3 · ${THEATER_SHOW_ACTS[round].title}`, 15, "#ff94bc");
    text(PAUSE.x + PAUSE.width / 2, PAUSE.y + PAUSE.height / 2, "Ⅱ", 22, "#fff0cb", true);
    this.hud = text(68, 434, "", 16);
    this.status = text(68, 478, "", 14, "#b7bdd6").setWordWrapWidth(540);
    this.dashLabel = text(DASH.x + DASH.width / 2, DASH.y + DASH.height / 2, "谢幕 · Space", 16, "#11152d", true);
    this.foodLabels = Array.from({ length: 6 }, () => text(0, 0, THEATER_SHOW_ACTS[round].glyph, 36, "#fff0cb", true));
    this.mouthLabel = text(839, 325, "", 13, "#ffb1c4", true);
    this.overlayTitle = text(480, 206, "", 25, "#fff0cb", true);
    this.overlayBody = text(480, 282, "", 17, "#cdd2e8", true);
    this.primaryLabel = text(480, 376, "", 18, "#11152d", true);
    document.addEventListener("visibilitychange", this.visibilityHandler);
    this.paint();
  }

  private hit(point: TheaterShowPoint, box: { x: number; y: number; width: number; height: number }): boolean {
    const renderedWidth = this.scene.game.canvas.getBoundingClientRect().width;
    const minimum = 28 * 960 / Math.max(1, renderedWidth);
    const extraX = Math.max(0, (minimum - box.width) / 2);
    const extraY = Math.max(0, (minimum - box.height) / 2);
    return inside(point, { x: box.x - extraX, y: box.y - extraY, width: box.width + extraX * 2, height: box.height + extraY * 2 });
  }

  pointerDown(point: TheaterShowPoint): void {
    if (this.disposed) return;
    if (this.screen !== "running") { if (this.hit(point, PRIMARY)) this.primary(); return; }
    if (this.hit(point, PAUSE)) { this.pause(); return; }
    if (this.hit(point, DASH)) { this.queuedDash = true; return; }
    if (point.y >= 126 && point.y <= 415 && point.x >= 56 && point.x <= 904) {
      this.pointerTarget = point; this.pointerHeld = true;
    }
  }
  pointerMove(point: TheaterShowPoint): void { if (this.pointerHeld) this.pointerTarget = point; }
  pointerUp(): void { this.pointerHeld = false; this.pointerTarget = null; }
  keyDown(event: KeyboardEvent): void {
    if (event.repeat) return;
    if (event.key === "Escape" && this.screen === "running") this.pause();
    else if (event.key === " " && this.screen === "running") this.queuedDash = true;
    else if (event.key === "Enter" && this.screen !== "running") this.primary();
  }
  interact(): void {
    if (this.screen === "running") this.queuedDash = true;
    else this.primary();
  }
  private primary(): void {
    if (this.screen === "intro" || this.screen === "paused") {
      this.screen = "running"; this.accumulator = 0; this.pointerUp(); this.queuedDash = false;
    } else if (this.screen === "result") {
      if (this.approved && this.finalAct) this.callbacks.finale();
      else this.callbacks.restart();
      return;
    }
    this.paint();
  }
  private pause(): void { this.screen = "paused"; this.accumulator = 0; this.pointerUp(); this.queuedDash = false; this.paint(); }
  resolve(accepted: boolean, finalAct = false): void {
    this.approved = accepted; this.finalAct = finalAct; this.screen = "result"; this.pointerUp(); this.paint();
  }
  update(delta: number, keyboard: TheaterShowPoint): void {
    if (this.disposed || document.hidden) return;
    if (this.screen !== "paused") this.visualTime += Math.min(delta, 100);
    if (this.screen === "running") {
      this.accumulator += Math.min(delta, 150);
      while (this.accumulator >= THEATER_SHOW_STEP_MS && this.screen === "running") {
        this.accumulator -= THEATER_SHOW_STEP_MS;
        let { x, y } = keyboard;
        if (Math.hypot(x, y) < 0.01 && this.pointerTarget) {
          const dx = this.pointerTarget.x - this.model.head.x, dy = this.pointerTarget.y - this.model.head.y;
          const distance = Math.hypot(dx, dy);
          if (distance > 9) { x = dx / distance; y = dy / distance; }
        }
        const input: TheaterShowInput = { x: Math.max(-1, Math.min(1, x)), y: Math.max(-1, Math.min(1, y)), dash: this.queuedDash };
        this.queuedDash = false;
        this.inputs.push(input);
        this.model = stepTheaterShow(this.model, input);
        if (this.model.status !== "running") {
          this.screen = "awaiting"; this.pointerUp();
          this.callbacks.submit({ version: 2, round: this.model.round, attempt: this.model.attempt, inputs: [...this.inputs] });
        }
      }
    }
    if (!this.disposed) this.paint();
  }

  private chair(x: number, y: number, phase: number, scale = 1): void {
    const g = this.art;
    g.fillStyle(0x0a1021, 0.5).fillEllipse(x, y + 24 * scale, 53 * scale, 12 * scale);
    g.fillStyle(0xffb18e).fillRect(x - 17 * scale, y - 27 * scale, 34 * scale, 26 * scale);
    g.fillStyle(0x773b66).fillRect(x - 12 * scale, y - 22 * scale, 24 * scale, 15 * scale);
    g.fillStyle(0xffb18e).fillRect(x - 21 * scale, y, 42 * scale, 9 * scale);
    const kick = Math.sin(phase) * 8 * scale;
    g.lineStyle(5 * scale, 0xffcf68).lineBetween(x - 14 * scale, y + 7 * scale, x - 18 * scale + kick, y + 24 * scale);
    g.lineBetween(x + 14 * scale, y + 7 * scale, x + 18 * scale - kick, y + 24 * scale);
    g.fillStyle(COLORS.cream).fillRect(x - 7 * scale, y - 19 * scale, 5 * scale, 6 * scale).fillRect(x + 3 * scale, y - 19 * scale, 5 * scale, 6 * scale);
    g.fillStyle(COLORS.ink).fillRect(x - 5 * scale, y - 17 * scale, 2 * scale, 3 * scale).fillRect(x + 5 * scale, y - 17 * scale, 2 * scale, 3 * scale);
  }
  private eye(x: number, y: number, size: number, awake = true): void {
    const g = this.art;
    g.fillStyle(awake ? 0xfff0cb : 0x566080, awake ? 1 : 0.6).fillEllipse(x, y, size * 2, size);
    const dx = Phaser.Math.Clamp((this.model.head.x - x) / 110, -size * 0.24, size * 0.24);
    const dy = Phaser.Math.Clamp((this.model.head.y - y) / 110, -size * 0.13, size * 0.13);
    g.fillStyle(0x171936).fillCircle(x + dx, y + dy, size * 0.27);
    g.fillStyle(0xe85881).fillRect(x + dx - 2, y + dy - 2, 4, 4);
  }

  private paint(): void {
    const g = this.art, s = this.model, act = THEATER_SHOW_ACTS[s.round];
    const t = this.visualTime / 1000;
    const overlay = this.screen !== "running";
    g.clear();
    g.fillStyle(COLORS.ink).fillRect(0, 0, 960, 540);
    g.fillStyle(0x24233e).fillRect(46, 122, 868, 296);
    // Velvet curtains and irregular hem; no image from the retired game is used.
    for (let i = 0; i < 6; i++) {
      g.fillStyle(i % 2 ? 0x78334f : 0xa43d60).fillRect(i * 8, 115, 8, 309 - i * 13);
      g.fillStyle(i % 2 ? 0x78334f : 0xa43d60).fillRect(912 + i * 8, 115, 8, 244 + i * 13);
    }
    g.fillStyle(0x77354f).fillRect(46, 116, 868, 14);
    for (let x = 50; x < 915; x += 48) g.fillStyle(0xab496d).fillTriangle(x, 128, x + 47, 128, x + 24, 144);
    // A moon that has literally been issued a seat.
    const moonX = 170 + Math.sin(t * 0.35) * 12, moonY = 201;
    g.fillStyle(0x666078, 0.18).fillCircle(moonX, moonY, 51);
    g.fillStyle(0xf8d68f, 0.11).fillCircle(moonX, moonY, 41);
    this.chair(moonX, moonY + 8, t * 2, 0.7);
    g.fillStyle(0x24233e, 0.6).fillRect(105, 150, 132, 115);
    // Audience turns into a ceiling in the third act, responding to the same current.
    for (let i = 0; i < 13; i++) {
      const x = 82 + i * 65;
      const y = s.round === 2 ? 157 + Math.sin(t + i) * 8 : 389 + Math.sin(i * 2) * 4;
      g.fillStyle(0x37354f).fillEllipse(x, y + 12, 43, 42);
      this.eye(x, y + 3, 12, s.round === 2);
    }
    g.fillStyle(COLORS.floor).fillRect(49, 410, 862, 14);
    g.lineStyle(1, 0x626585, 0.4).lineBetween(49, 416, 911, 416);
    for (let i = 0; i < 15; i++) g.lineBetween(55 + i * 60, 410, 37 + i * 63, 424);
    if (s.round === 2) {
      const flow = Math.sin(s.tick * 0.028);
      for (let i = 0; i < 10; i++) {
        const x = 80 + i * 87, y = 185 + ((s.tick * 2 + i * 43) % 190);
        g.lineStyle(2, 0x96e6d5, 0.12).lineBetween(x, y, x + 5, y + flow * 30);
      }
    }
    const mouth = getTheaterShowMouth(s), exitOpen = s.collected.length === act.count;
    g.fillStyle(0x713852).fillEllipse(mouth.x, mouth.y, 108, exitOpen ? 95 : 47);
    g.fillStyle(0xf582a7).fillEllipse(mouth.x, mouth.y, 91, exitOpen ? 78 : 29);
    g.fillStyle(0x0c1024).fillEllipse(mouth.x, mouth.y,  70, exitOpen ? 61 : 9);
    for (let i = 0; i < 5; i++) {
      g.fillStyle(COLORS.cream).fillRect(mouth.x - 30 + i * 13, mouth.y - (exitOpen ? 29 : 4), 9, exitOpen ? 11 : 5);
      if (exitOpen) g.fillRect(mouth.x - 30 + i * 13, mouth.y + 19, 9, 10);
    }
    this.mouthLabel.setPosition(mouth.x, mouth.y + (exitOpen ? 57 : 35)).setText(exitOpen ? "请从嘴里退场" : `还差 ${act.count - s.collected.length} 个标点`);
    const foods = getTheaterShowFood(s);
    this.foodLabels.forEach(label => label.setVisible(false));
    for (const food of foods) {
      g.fillStyle(act.color, 0.08).fillCircle(food.x, food.y, 28 + Math.sin(t * 3 + food.id) * 3);
      g.lineStyle(1, act.color, 0.25).strokeCircle(food.x, food.y, 24);
      this.foodLabels[food.id].setPosition(food.x, food.y - 9 + Math.sin(t * 3 + food.id) * 2).setVisible(true);
    }
    for (const hazard of getTheaterShowHazards(s)) {
      if (hazard.kind === "chair") this.chair(hazard.x, hazard.y, t * 6 + hazard.x);
      else if (hazard.kind === "shadow") {
        g.fillStyle(0x06080f, 0.75).fillEllipse(hazard.x, hazard.y, 49, 39);
        g.fillTriangle(hazard.x - 24, hazard.y, hazard.x + 24, hazard.y, hazard.x, hazard.y + 31);
        this.eye(hazard.x, hazard.y - 3, 13);
      } else {
        g.lineStyle(3, 0xff94bc, 0.6).strokeCircle(hazard.x, hazard.y, 25);
        this.eye(hazard.x, hazard.y, 25);
      }
    }
    const drawTrail = (width: number, color: number, alpha: number) => {
      g.lineStyle(width, color, alpha).beginPath();
      s.trail.forEach((p, index) => index === 0 ? g.moveTo(p.x, p.y) : g.lineTo(p.x, p.y));
      g.strokePath();
    };
    drawTrail(s.dashTicks > 0 ? 34 : 25, act.color, 0.09);
    drawTrail(12, act.color, 0.75); drawTrail(4, COLORS.cream, 0.92);
    const blink = s.invulnerable > 0 && s.tick % 4 < 2;
    g.fillStyle(blink ? 0xffffff : act.color).fillCircle(s.head.x, s.head.y, 13);
    g.fillStyle(COLORS.ink).fillRect(s.head.x - 15, s.head.y - 19, 30, 5).fillRect(s.head.x - 8, s.head.y - 32, 16, 15);
    g.fillStyle(COLORS.cream).fillRect(s.head.x - 8, s.head.y - 30, 16, 3);
    g.fillStyle(COLORS.ink).fillRect(s.head.x - 6, s.head.y - 3, 3, 5).fillRect(s.head.x + 3, s.head.y - 3, 3, 5);
    g.lineStyle(2, COLORS.ink).lineBetween(s.head.x - 3, s.head.y + 6, s.head.x + 4, s.head.y + 6);
    g.lineStyle(1, 0x595a77).strokeRect(59, 52, 842, 62);
    g.lineStyle(1, 0x595a77).strokeRect(PAUSE.x, PAUSE.y, PAUSE.width, PAUSE.height);
    g.fillStyle(s.dashCooldown === 0 ? act.color : 0x4a4c65).fillRect(DASH.x, DASH.y, DASH.width, DASH.height);
    this.dashLabel.setText(s.dashCooldown > 0 ? `谢幕冷却 ${Math.ceil(s.dashCooldown / 20)}s` : "谢幕 · Space");
    this.hud.setText(`标点 ${s.collected.length}/${act.count}     灯芯 ${"●".repeat(s.lives)}${"○".repeat(3 - s.lives)}     ${Math.ceil((THEATER_SHOW_MAX_TICKS - s.tick) / 20)}s`);
    this.status.setText(s.lastEvent === "hurt" ? "影子咬掉了一截光。谢幕可以冲过去。" : "按住舞台拖动 / WASD 移动 · 集齐标点后从嘴里退场");
    for (const label of [this.overlayTitle, this.overlayBody, this.primaryLabel]) label.setVisible(overlay);
    if (overlay) {
      g.fillStyle(0x0a0f23, 0.84).fillRect(48, 128, 864, 296);
      g.fillStyle(0x24233e).fillRect(186, 165, 588, 244);
      g.lineStyle(2, act.color, 0.75).strokeRect(186, 165, 588, 244);
      g.fillStyle(act.color).fillRect(PRIMARY.x, PRIMARY.y, PRIMARY.width, PRIMARY.height);
      if (this.screen === "intro") {
        this.overlayTitle.setText(act.title);
        this.overlayBody.setText(`${act.subtitle}\n按住舞台拖动，或用 WASD / 方向键移动。\nSpace「谢幕」可以短暂穿过影子。`);
        this.primaryLabel.setText("让灯自己演");
      } else if (this.screen === "paused") {
        this.overlayTitle.setText("演出暂停，影子也停下了");
        this.overlayBody.setText("按继续后再演。计时和动作都从暂停处恢复。");
        this.primaryLabel.setText("继续演出");
      } else if (this.screen === "awaiting") {
        this.overlayTitle.setText("正在收下这场演出"); this.overlayBody.setText(""); this.primaryLabel.setText("稍等一下");
      } else {
        this.overlayTitle.setText(this.approved ? this.finalAct ? "全体观众，都被演出了" : "这一幕已经无法撤回" : "影子把这场演出吃掉了");
        this.overlayBody.setText(this.approved ? this.finalAct ? "灯光谢幕。台上只剩下一张湿节目单。" : "收下这一幕。下一幕的规则会变。" : "已经完成的幕次保留。\n再演一次，这一幕从头开始。");
        this.primaryLabel.setText(this.approved ? this.finalAct ? "拉开最后的幕布" : "下一幕" : "重演这一幕");
      }
      // Text labels created above the Graphics remain readable over its modal fill.
      this.foodLabels.forEach(label => label.setVisible(false)); this.mouthLabel.setVisible(false);
    } else this.mouthLabel.setVisible(true);
  }
  snapshot() {
    return { game: "light-creature-v2", screen: this.screen, round: this.model.round, tick: this.model.tick, status: this.model.status,
      head: this.model.head, lives: this.model.lives, collected: this.model.collected.length, required: THEATER_SHOW_ACTS[this.model.round].count,
      foods: getTheaterShowFood(this.model), hazards: getTheaterShowHazards(this.model), mouth: getTheaterShowMouth(this.model),
      dashCooldown: this.model.dashCooldown, controls: { primary: PRIMARY, dash: DASH, pause: PAUSE } };
  }
  destroy(): void {
    this.disposed = true; document.removeEventListener("visibilitychange", this.visibilityHandler); this.container.destroy(true);
  }
}
