import Phaser from "phaser";
import {
  RhythmFishingEngine,
  type RhythmFishingAction,
  type RhythmFishingEngineEvents,
  type RhythmFishingNote,
} from "../../../modules/RhythmFishingEngine";
import {
  calculateEndlessFishingScore,
  createEndlessFishingSegment,
  MAX_ENDLESS_FISHING_SCORE,
  type EndlessFishingSegment,
} from "./EndlessFishingRules";
import type { EndlessArcadeControlAction, EndlessArcadeSceneBridge } from "./EndlessArcadeRuntime";

const WIDTH = 390;
const HEIGHT = 650;
const JUDGMENT_Y = 526;
const TRACK_X: Readonly<Record<RhythmFishingAction, number>> = { left: 90, hook: 195, right: 300 };
const TRACK_COLOR: Readonly<Record<RhythmFishingAction, number>> = { left: 0x6ecdd8, hook: 0xf4cf53, right: 0x8cbf79 };
const FONT = '"Fusion Pixel 12px Proportional SC", "Fusion Pixel", "PingFang SC", sans-serif';

interface DrawnNote {
  body: Phaser.GameObjects.Rectangle;
  label: Phaser.GameObjects.Text;
  holdLine: Phaser.GameObjects.Rectangle | null;
}

export class EndlessFishingScene extends Phaser.Scene {
  private bridge!: EndlessArcadeSceneBridge;
  private model: RhythmFishingEngine<string> | null = null;
  private segment: EndlessFishingSegment | null = null;
  private segmentIndex = 0;
  private completedSegments = 0;
  private score = 0;
  private currentCombo = 0;
  private maxCombo = 0;
  private tension = 50;
  private startedAtMs = 0;
  private ended = false;
  private cleanupComplete = false;
  private notes = new Map<number, DrawnNote>();
  private water!: Phaser.GameObjects.Graphics;
  private line!: Phaser.GameObjects.Graphics;
  private tensionFill!: Phaser.GameObjects.Rectangle;
  private tensionText!: Phaser.GameObjects.Text;
  private cueText!: Phaser.GameObjects.Text;
  private tierText!: Phaser.GameObjects.Text;
  private beatPulse!: Phaser.GameObjects.Rectangle;
  private lastBeat = -1;
  private readonly keyboardDown = (event: KeyboardEvent) => this.handleKeyboardPress(event);
  private readonly keyboardUp = (event: KeyboardEvent) => this.handleKeyboardRelease(event);

  constructor() {
    super("endless-fishing");
  }

  create(): void {
    this.cleanupComplete = false;
    this.bridge = this.registry.get("endlessArcadeBridge") as EndlessArcadeSceneBridge;
    this.startedAtMs = this.game.loop.now;
    this.cameras.main.setBackgroundColor(0x10293a);
    this.drawStaticStage();
    this.input.keyboard?.on("keydown", this.keyboardDown);
    this.input.keyboard?.on("keyup", this.keyboardUp);
    this.events.once(Phaser.Scenes.Events.SHUTDOWN, this.destroyScene, this);
    this.events.once(Phaser.Scenes.Events.DESTROY, this.destroyScene, this);
    this.startSegment(0);
  }

  update(_time: number): void {
    if (this.ended || !this.model || !this.segment) return;
    this.model.update();
    if (this.ended || !this.model || !this.segment) return;
    this.updateNotePositions();
    this.updateBeatPulse();
    this.updateTensionBar();
  }

  handleEndlessControl(action: EndlessArcadeControlAction): void {
    if (this.ended) return;
    const pressed: Partial<Record<EndlessArcadeControlAction, RhythmFishingAction>> = {
      left: "left",
      right: "right",
      primary: "hook",
    };
    const released: Partial<Record<EndlessArcadeControlAction, RhythmFishingAction>> = {
      release_left: "left",
      release_right: "right",
      release_primary: "hook",
    };
    const press = pressed[action];
    if (press) this.model?.handlePress(press);
    const release = released[action];
    if (release) this.model?.handleRelease(release);
  }

  releaseEndlessControls(): void {
    this.model?.releaseHeldInputs();
  }

  cleanupEndlessScene(): void {
    this.destroyScene();
  }

  private drawStaticStage(): void {
    this.water = this.add.graphics().setDepth(0);
    this.line = this.add.graphics().setDepth(2);
    this.water.fillStyle(0x12384d, 1);
    this.water.fillRect(0, 0, WIDTH, HEIGHT);
    for (let y = 80; y < HEIGHT; y += 68) {
      this.water.lineStyle(2, 0x32657a, 0.55);
      this.water.lineBetween(0, y, WIDTH, y);
    }
    this.add.rectangle(WIDTH / 2, 26, WIDTH, 52, 0x0a1a25).setDepth(1);
    this.add.text(18, 14, "湖面收线", { color: "#d8eff0", fontFamily: FONT, fontSize: "14px" }).setDepth(3);
    this.tierText = this.add.text(372, 14, "T1", { color: "#f4cf53", fontFamily: FONT, fontSize: "14px" })
      .setOrigin(1, 0)
      .setDepth(3);
    for (const [action, x] of Object.entries(TRACK_X) as [RhythmFishingAction, number][]) {
      const color = TRACK_COLOR[action];
      this.line.lineStyle(2, color, 0.36);
      this.line.lineBetween(x, 84, x, JUDGMENT_Y + 14);
      this.add.text(x, 62, action === "left" ? "J" : action === "hook" ? "K" : "L", {
        color: `#${color.toString(16).padStart(6, "0")}`,
        fontFamily: FONT,
        fontSize: "16px",
      }).setOrigin(0.5).setDepth(3);
    }
    this.line.lineStyle(4, 0xf7f0d8, 0.95);
    this.line.lineBetween(40, JUDGMENT_Y, 350, JUDGMENT_Y);
    this.add.text(195, JUDGMENT_Y + 12, "判定线", { color: "#d8eff0", fontFamily: FONT, fontSize: "11px" })
      .setOrigin(0.5)
      .setDepth(3);
    this.add.rectangle(195, 594, 300, 24, 0x071017).setStrokeStyle(2, 0xd8eff0).setDepth(2);
    this.tensionFill = this.add.rectangle(47, 594, 0, 16, 0x6ecdd8).setOrigin(0, 0.5).setDepth(3);
    this.tensionText = this.add.text(195, 594, "张力 50", { color: "#edf7f7", fontFamily: FONT, fontSize: "12px" })
      .setOrigin(0.5)
      .setDepth(4);
    this.cueText = this.add.text(195, 560, "跟随落到判定线的符号", {
      color: "#b8d1d5",
      fontFamily: FONT,
      fontSize: "12px",
    }).setOrigin(0.5).setDepth(4);
    this.beatPulse = this.add.rectangle(195, 42, 8, 8, 0xf4cf53).setAlpha(0.45).setDepth(4);
  }

  private startSegment(index: number): void {
    if (this.ended) return;
    const segment = createEndlessFishingSegment(this.bridge.seed, index);
    this.segment = segment;
    this.segmentIndex = index;
    this.lastBeat = -1;
    this.clearNotes();
    const timing = {
      beatSec: segment.beatSec,
      leadSec: Math.max(1.05, segment.beatSec * 2),
      assistLeadSec: Math.max(1.25, segment.beatSec * 2.5),
      perfectMs: 70,
      greatMs: 130,
      goodMs: 190,
      assistGoodMs: 230,
      holdReleaseSlackSec: 0.08,
    };
    const events: RhythmFishingEngineEvents<string> = {
      onNoteJudged: (note, judgment) => this.onNoteJudged(note, judgment),
      onHoldBroken: () => this.showCue("收线太早", 0xffa080),
      onWarning: (kind) => this.showCue(kind === "tension_low" ? "张力过低" : "张力过高", 0xffb26e),
      onCompleted: () => this.completeSegment(),
      onFailed: (reason) => this.finish(reason === "line_snapped" ? "张力过高，线断了" : "张力过低，鱼脱钩了"),
    };
    this.model = new RhythmFishingEngine({
      chartId: segment.id,
      chart: segment,
      now: () => this.game.loop.now / 1000,
      timing,
      tension: {
        initial: 50,
        min: 0,
        max: 100,
        perfectRecover: 4,
        greatShift: 3,
        goodShift: 7,
        missPenalty: 14,
        wrongActionPenalty: 16,
        holdBreakPenalty: 12,
        warnLow: 20,
        warnHigh: 80,
        passMin: 15,
        passMax: 85,
        failSustainMs: 350,
        assistFailSustainMs: 700,
      },
      events,
      initialTension: this.tension,
      initialCombo: this.currentCombo,
    });
    this.model.start();
    this.createNoteObjects();
    this.tierText.setText(`T${segment.tier}`);
    this.showCue(`第 ${index + 1} 段：收线`, 0xd8eff0);
    this.publishSnapshot();
  }

  private createNoteObjects(): void {
    if (!this.model) return;
    for (const note of this.model.notes) {
      const color = TRACK_COLOR[note.action];
      const body = this.add.rectangle(TRACK_X[note.action], -40, 38, 22, color).setStrokeStyle(2, 0xeef6ef).setDepth(5);
      const label = this.add.text(TRACK_X[note.action], -40, note.action === "left" ? "J" : note.action === "hook" ? "K" : "L", {
        color: "#102129",
        fontFamily: FONT,
        fontSize: "14px",
      }).setOrigin(0.5).setDepth(6);
      const holdLine = note.holdBeats > 0
        ? this.add.rectangle(TRACK_X[note.action], -40, 6, 6, color).setDepth(4)
        : null;
      this.notes.set(note.index, { body, label, holdLine });
    }
  }

  private updateNotePositions(): void {
    if (!this.model || !this.segment) return;
    const elapsed = this.model.elapsedSec;
    for (const note of this.model.notes) {
      const drawn = this.notes.get(note.index);
      if (!drawn) continue;
      const progress = (elapsed - note.spawnSec) / this.model.leadSec;
      const y = 88 + Math.max(0, Math.min(1.2, progress)) * (JUDGMENT_Y - 88);
      const visible = note.judgment === null && progress >= 0 && progress <= 1.16;
      drawn.body.setVisible(visible).setPosition(TRACK_X[note.action], y);
      drawn.label.setVisible(visible).setPosition(TRACK_X[note.action], y);
      if (drawn.holdLine) {
        const holdHeight = Math.max(8, (note.holdSec / this.model.leadSec) * (JUDGMENT_Y - 88));
        drawn.holdLine.setVisible(visible).setPosition(TRACK_X[note.action], y - holdHeight / 2).setSize(6, holdHeight);
      }
    }
  }

  private updateBeatPulse(): void {
    if (!this.model || !this.segment) return;
    const beat = Math.floor(this.model.elapsedSec / this.segment.beatSec);
    if (beat === this.lastBeat) return;
    this.lastBeat = beat;
    this.beatPulse.setScale(2.6).setAlpha(1);
    if (!this.bridge.reducedMotion) {
      this.tweens.add({ targets: this.beatPulse, scaleX: 1, scaleY: 1, alpha: 0.45, duration: 120 });
    } else {
      this.beatPulse.setScale(1).setAlpha(0.65);
    }
  }

  private onNoteJudged(note: RhythmFishingNote, judgment: "perfect" | "great" | "good" | "miss"): void {
    if (!this.model || !this.segment || this.ended) return;
    const drawn = this.notes.get(note.index);
    drawn?.body.setVisible(false);
    drawn?.label.setVisible(false);
    drawn?.holdLine?.setVisible(false);
    this.currentCombo = this.model.combo;
    this.maxCombo = Math.max(this.maxCombo, this.model.maxCombo);
    this.tension = this.model.tension;
    this.score = Math.min(MAX_ENDLESS_FISHING_SCORE, this.score + calculateEndlessFishingScore({
      tier: this.segment.tier,
      combo: this.currentCombo,
      judgment,
    }));
    this.showCue(
      judgment === "perfect" ? "精准" : judgment === "great" ? "很好" : judgment === "good" ? "擦边" : "漏拍",
      judgment === "miss" ? 0xff9584 : TRACK_COLOR[note.action],
    );
    this.publishSnapshot();
  }

  private completeSegment(): void {
    if (!this.model || !this.segment || this.ended) return;
    this.tension = this.model.tension;
    this.currentCombo = this.model.combo;
    this.maxCombo = Math.max(this.maxCombo, this.model.maxCombo);
    this.completedSegments += 1;
    this.startSegment(this.segmentIndex + 1);
  }

  private updateTensionBar(): void {
    if (!this.model) return;
    this.tension = this.model.tension;
    this.currentCombo = this.model.combo;
    this.maxCombo = Math.max(this.maxCombo, this.model.maxCombo);
    const width = Math.round(294 * this.tension / 100);
    const color = this.tension < 20 ? 0x75cce8 : this.tension > 80 ? 0xeb8a68 : 0x6ecdd8;
    this.tensionFill.setSize(width, 16).setFillStyle(color);
    this.tensionText.setText(`张力 ${Math.round(this.tension)} · 连 ${this.currentCombo}`);
  }

  private publishSnapshot(): void {
    const segment = this.segment;
    this.bridge.publishSnapshot({
      mode: "fishing",
      score: this.score,
      progress: this.completedSegments,
      tier: segment?.tier ?? 1,
      combo: this.currentCombo,
      status: "fishing",
    });
  }

  private finish(reason: string): void {
    if (this.ended) return;
    this.ended = true;
    this.showCue(reason, 0xffa080);
    this.bridge.finish({
      mode: "fishing",
      score: this.score,
      progress: this.completedSegments,
      tier: this.segment?.tier ?? 1,
      combo: this.maxCombo,
      durationMs: Math.max(0, Math.round(this.game.loop.now - this.startedAtMs)),
      status: reason,
    });
  }

  private showCue(text: string, color: number): void {
    this.cueText.setText(text).setColor(`#${color.toString(16).padStart(6, "0")}`);
  }

  private handleKeyboardPress(event: KeyboardEvent): void {
    if (event.repeat) return;
    if (event.key.toLowerCase() === "j") this.handleEndlessControl("left");
    if (event.key.toLowerCase() === "k") this.handleEndlessControl("primary");
    if (event.key.toLowerCase() === "l") this.handleEndlessControl("right");
  }

  private handleKeyboardRelease(event: KeyboardEvent): void {
    if (event.key.toLowerCase() === "j") this.handleEndlessControl("release_left");
    if (event.key.toLowerCase() === "k") this.handleEndlessControl("release_primary");
    if (event.key.toLowerCase() === "l") this.handleEndlessControl("release_right");
  }

  private clearNotes(): void {
    this.notes.forEach(({ body, label, holdLine }) => {
      body.destroy();
      label.destroy();
      holdLine?.destroy();
    });
    this.notes.clear();
  }

  private destroyScene(): void {
    if (this.cleanupComplete) return;
    this.cleanupComplete = true;
    this.releaseEndlessControls();
    this.input.keyboard?.off("keydown", this.keyboardDown);
    this.input.keyboard?.off("keyup", this.keyboardUp);
    this.clearNotes();
    this.model?.cancel();
    this.model = null;
  }
}
