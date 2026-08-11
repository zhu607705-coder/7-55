/**
 * Qizhen Lake rhythm-fishing Phaser visual: bobber ripple rings, action icons,
 * hold arcs, tension line and the narrow top status strip.
 *
 * Contract: docs/chapter-3-qizhen-fishing-rhythm.md §7 and §9.2.
 * Self-contained: vector Graphics + Text only, no texture assets, no scene
 * imports (avoids circular dependencies) and no camera access. Tweens go
 * through `scene.tweens`, timers through `scene.time`.
 */

import Phaser from "phaser";
import {
  QIZHEN_FISHING_TENSION,
  QIZHEN_FISHING_TIMING,
} from "./QizhenFishingRhythmModel";
import type {
  QizhenFishingAction,
  QizhenFishingFailReason,
  QizhenFishingGrade,
  QizhenFishingJudgment,
  QizhenFishingNote,
  QizhenFishingResult,
  QizhenFishingRhythmModel,
  QizhenFishingWarningKind,
} from "./QizhenFishingRhythmModel";

export interface QizhenFishingRhythmVisualOptions {
  scene: Phaser.Scene;
  model: QizhenFishingRhythmModel;
  /** Bobber world position: the judgment anchor. */
  anchor: { x: number; y: number };
  targetLabel: string;
  /** Kayak bow world position getter for the tension line. */
  lineFrom?: () => { x: number; y: number };
  reducedMotion: boolean;
  /** Defaults to 2600 (above the cast bobber at 2502). */
  depth?: number;
}

const RING_START_RADIUS = 72;
const RING_END_RADIUS = 14;
const HOLD_ARC_RADIUS = 24;
const REDUCED_RING_STEPS = [72, 48, 32, 14] as const;
const STATUS_BAR_X = 480;
const STATUS_BAR_Y = 64;

const RING_COLORS: Record<QizhenFishingAction, number> = {
  left: 0x86d98a,
  right: 0xffc95e,
  hook: 0x8fd4ff,
};
const RING_COLORS_ASSIST: Record<QizhenFishingAction, number> = {
  left: 0xc6ffca,
  right: 0xffe6a8,
  hook: 0xd6f2ff,
};
const ACTION_ARROWS: Record<QizhenFishingAction, string> = {
  left: "←",
  right: "→",
  hook: "↑",
};
const ACTION_CSS: Record<QizhenFishingAction, string> = {
  left: "#a5e8a8",
  right: "#ffd166",
  hook: "#a8ddff",
};
const JUDGMENT_WORDS: Record<QizhenFishingJudgment, string> = {
  perfect: "Perfect",
  great: "Great",
  good: "Good",
  miss: "Miss",
};
const JUDGMENT_CSS: Record<QizhenFishingJudgment, string> = {
  perfect: "#ffd75e",
  great: "#8affc1",
  good: "#9fd8ff",
  miss: "#c08a8a",
};
const JUDGMENT_COLORS: Record<QizhenFishingJudgment, number> = {
  perfect: 0xffd75e,
  great: 0x8affc1,
  good: 0x9fd8ff,
  miss: 0x9aa4ad,
};
const GRADE_CSS: Record<QizhenFishingGrade, string> = {
  S: "#ffd75e",
  A: "#8affc1",
  B: "#eaffff",
  C: "#b9c0c7",
};
const HUD_TEXT_STYLE: Phaser.Types.GameObjects.Text.TextStyle = {
  fontFamily: "monospace",
  fontSize: "13px",
  color: "#e9ffff",
  stroke: "#07111c",
  strokeThickness: 3,
};

interface NoteVisual {
  ring: Phaser.GameObjects.Graphics | null;
  icon: Phaser.GameObjects.Container | null;
  holdArc: Phaser.GameObjects.Graphics | null;
  countdown: Phaser.GameObjects.Text | null;
  lastRadius: number;
  wasHolding: boolean;
}

export class QizhenFishingRhythmVisual {
  private readonly options: QizhenFishingRhythmVisualOptions;
  private readonly scene: Phaser.Scene;
  private readonly model: QizhenFishingRhythmModel;
  private readonly anchor: { x: number; y: number };
  private readonly depth: number;
  private readonly reducedMotion: boolean;
  private destroyed = false;

  private readonly owned = new Set<Phaser.GameObjects.GameObject>();
  private readonly timers = new Set<Phaser.Time.TimerEvent>();
  private readonly noteVisuals = new Map<number, NoteVisual>();

  private readonly bobber: Phaser.GameObjects.Container;
  private readonly lineGraphics: Phaser.GameObjects.Graphics;
  private readonly lineLowMarker: Phaser.GameObjects.Text;
  private readonly lineHighMarker: Phaser.GameObjects.Text;

  private readonly statusBar: Phaser.GameObjects.Container;
  private readonly statusBg: Phaser.GameObjects.Graphics;
  private readonly labelText: Phaser.GameObjects.Text;
  private readonly tensionText: Phaser.GameObjects.Text;
  private readonly comboText: Phaser.GameObjects.Text;
  private statusCache = "";
  private warningUntil = 0;
  private warningCss = "#ff9a6e";

  constructor(options: QizhenFishingRhythmVisualOptions) {
    this.options = options;
    this.scene = options.scene;
    this.model = options.model;
    this.anchor = options.anchor;
    this.depth = options.depth ?? 2600;
    this.reducedMotion = options.reducedMotion;

    this.bobber = this.buildBobber();

    this.lineGraphics = this.track(this.scene.add.graphics().setDepth(this.depth - 1));
    this.lineLowMarker = this.track(
      this.scene.add.text(0, 0, "▼", {
        ...HUD_TEXT_STYLE,
        fontSize: "14px",
        fontStyle: "bold",
        color: "#9fd8ff",
      }).setOrigin(0.5).setDepth(this.depth + 1).setVisible(false),
    );
    this.lineHighMarker = this.track(
      this.scene.add.text(0, 0, "▲", {
        ...HUD_TEXT_STYLE,
        fontSize: "14px",
        fontStyle: "bold",
        color: "#ff9a6e",
      }).setOrigin(0.5).setDepth(this.depth + 1).setVisible(false),
    );

    // Narrow status strip: fixed to the canvas, below the shared React task bar.
    this.statusBar = this.track(
      this.scene.add.container(STATUS_BAR_X, STATUS_BAR_Y).setScrollFactor(0).setDepth(this.depth + 4),
    );
    this.statusBg = this.scene.add.graphics();
    this.labelText = this.scene.add.text(0, 0, "", HUD_TEXT_STYLE).setOrigin(0, 0.5);
    this.tensionText = this.scene.add.text(0, 0, "", {
      ...HUD_TEXT_STYLE,
      color: "#fff2b6",
    }).setOrigin(0, 0.5);
    this.comboText = this.scene.add.text(0, 0, "", HUD_TEXT_STYLE).setOrigin(0, 0.5);
    this.statusBar.add([this.statusBg, this.labelText, this.tensionText, this.comboText]);
    this.refreshStatusBar(true);
  }

  update(): void {
    if (this.destroyed) return;
    this.refreshStatusBar();
    this.updateLine();
    if (!this.reducedMotion) {
      this.bobber.setY(this.anchor.y + Math.sin(this.scene.time.now / 260) * 1.5);
    }
    if (this.model.phase !== "running") return;
    const elapsed = this.model.elapsedSec;
    for (const note of this.model.notes) {
      const judgment = note.judgment;
      if (judgment === null) {
        if (elapsed >= note.spawnSec) this.renderNote(note, elapsed);
        continue;
      }
      if (note.holding) {
        this.renderHoldState(note, elapsed);
        continue;
      }
      const visual = this.noteVisuals.get(note.index);
      if (!visual) continue;
      const completedHold = visual.wasHolding;
      this.removeNoteVisual(visual);
      this.noteVisuals.delete(note.index);
      // A finished hold gets one small pop; broken holds are covered by
      // notifyHoldBroken. Other judgments feed back via notifyJudgment, so
      // reaching this sweep means the event was not forwarded: clean up only.
      if (completedHold && judgment !== "miss" && !this.reducedMotion) {
        this.spawnBurst(JUDGMENT_COLORS[judgment], HOLD_ARC_RADIUS);
      }
    }
  }

  notifyJudgment(
    note: QizhenFishingNote,
    judgment: QizhenFishingJudgment,
    _errorMs: number,
  ): void {
    if (this.destroyed) return;
    const visual = this.noteVisuals.get(note.index);
    const holding = note.holdBeats > 0 && note.holding;
    let radius = RING_END_RADIUS;
    if (visual) {
      radius = visual.lastRadius;
      if (holding) {
        // Hold notes are judged on press but keep playing: drop the ring and
        // icon, keep the entry alive for the closing hold arc.
        if (visual.ring) {
          this.release(visual.ring);
          visual.ring = null;
        }
        if (visual.icon) {
          this.release(visual.icon);
          visual.icon = null;
        }
      } else {
        this.removeNoteVisual(visual);
        this.noteVisuals.delete(note.index);
      }
    }
    this.flashJudgmentText(judgment);
    if (!this.reducedMotion) {
      const muted = judgment === "miss";
      this.spawnBurst(muted ? 0x9aa4ad : JUDGMENT_COLORS[judgment], radius, muted);
    }
  }

  notifyHoldBroken(note: QizhenFishingNote): void {
    if (this.destroyed) return;
    const visual = this.noteVisuals.get(note.index);
    if (visual) {
      this.removeNoteVisual(visual);
      this.noteVisuals.delete(note.index);
    }
    const flash = this.scene.add.graphics().setDepth(this.depth + 2);
    flash.lineStyle(3, 0xff5a4e, 1);
    const r = 14;
    flash.beginPath();
    flash.moveTo(this.anchor.x - r, this.anchor.y - r);
    flash.lineTo(this.anchor.x + r, this.anchor.y + r);
    flash.moveTo(this.anchor.x + r, this.anchor.y - r);
    flash.lineTo(this.anchor.x - r, this.anchor.y + r);
    flash.strokePath();
    flash.lineStyle(2, 0xff5a4e, 0.8);
    flash.strokeCircle(this.anchor.x, this.anchor.y, HOLD_ARC_RADIUS + 2);
    this.track(flash);
    if (this.reducedMotion) {
      this.delay(480, () => this.release(flash));
      return;
    }
    this.scene.tweens.add({
      targets: flash,
      alpha: 0.15,
      duration: 120,
      yoyo: true,
      repeat: 2,
      onComplete: () => this.release(flash),
    });
  }

  notifyWarning(kind: QizhenFishingWarningKind, _tension: number): void {
    if (this.destroyed) return;
    this.warningCss = kind === "tension_low" ? "#9fd8ff" : "#ff9a6e";
    this.warningUntil = this.scene.time.now + 750;
  }

  playResult(result: QizhenFishingResult, onComplete: () => void): void {
    if (this.destroyed) return;
    this.clearNoteVisuals();
    const cx = this.anchor.x;
    const cy = this.anchor.y - 50;
    const gradeText = this.track(
      this.scene.add.text(cx, cy, result.grade, {
        fontFamily: "monospace",
        fontSize: "38px",
        fontStyle: "bold",
        color: GRADE_CSS[result.grade],
        stroke: "#07111c",
        strokeThickness: 5,
      }).setOrigin(0.5).setDepth(this.depth + 3),
    );
    const accuracyText = this.track(
      this.scene.add.text(cx, cy + 32, `准确率 ${(result.accuracy * 100).toFixed(1)}%`, {
        fontFamily: "monospace",
        fontSize: "15px",
        color: "#eaffff",
        stroke: "#07111c",
        strokeThickness: 4,
      }).setOrigin(0.5).setDepth(this.depth + 3),
    );
    // Small item icon flying toward the world lower-right (inventory dock).
    const iconGraphics = this.scene.add.graphics();
    iconGraphics.fillStyle(0xffd75e, 1);
    iconGraphics.fillCircle(0, 0, 5);
    iconGraphics.fillTriangle(-4, 0, -11, -4, -11, 4);
    iconGraphics.fillStyle(0x401218, 1);
    iconGraphics.fillCircle(2, -1, 1);
    const icon = this.track(
      this.scene.add.container(cx, cy + 6, [iconGraphics]).setDepth(this.depth + 3),
    );
    if (!this.reducedMotion) {
      gradeText.setScale(0.4);
      this.scene.tweens.add({ targets: gradeText, scale: 1, duration: 240, ease: "Back.easeOut" });
      accuracyText.setAlpha(0);
      this.scene.tweens.add({ targets: accuracyText, alpha: 1, duration: 200, delay: 120 });
      this.scene.tweens.add({
        targets: icon,
        x: cx + 220,
        y: cy + 170,
        alpha: 0.1,
        duration: 600,
        delay: 220,
        ease: "Cubic.easeIn",
      });
      this.scene.tweens.add({
        targets: [gradeText, accuracyText],
        alpha: 0,
        duration: 140,
        delay: 660,
      });
    }
    this.delay(840, () => {
      this.release(gradeText);
      this.release(accuracyText);
      this.release(icon);
      onComplete();
    });
  }

  playFailure(reason: QizhenFishingFailReason | "grade", onComplete: () => void): void {
    if (this.destroyed) return;
    this.clearNoteVisuals();
    const word = reason === "line_snapped" ? "断线" : reason === "hook_escaped" ? "脱钩" : "未通过";
    const text = this.track(
      this.scene.add.text(this.anchor.x, this.anchor.y - 42, word, {
        fontFamily: "monospace",
        fontSize: "30px",
        fontStyle: "bold",
        color: "#ff8a7a",
        stroke: "#07111c",
        strokeThickness: 5,
      }).setOrigin(0.5).setDepth(this.depth + 3),
    );
    if (!this.reducedMotion) {
      text.setScale(0.8);
      this.scene.tweens.add({ targets: text, scale: 1, duration: 180, ease: "Cubic.easeOut" });
      this.scene.tweens.add({ targets: text, alpha: 0, duration: 140, delay: 460 });
    }
    this.delay(620, () => {
      this.release(text);
      onComplete();
    });
  }

  destroy(): void {
    if (this.destroyed) return;
    this.destroyed = true;
    for (const timer of this.timers) timer.remove();
    this.timers.clear();
    this.noteVisuals.clear();
    for (const obj of this.owned) {
      try {
        this.scene.tweens.killTweensOf(obj);
      } catch {
        // The tween manager may already be torn down during scene shutdown.
      }
      obj.destroy();
    }
    this.owned.clear();
  }

  // ---------------------------------------------------------------- internal

  private track<T extends Phaser.GameObjects.GameObject>(obj: T): T {
    this.owned.add(obj);
    return obj;
  }

  private release(obj: Phaser.GameObjects.GameObject): void {
    if (!this.owned.delete(obj)) return;
    try {
      this.scene.tweens.killTweensOf(obj);
    } catch {
      // The tween manager may already be torn down during scene shutdown.
    }
    obj.destroy();
  }

  private delay(ms: number, callback: () => void): void {
    const timer = this.scene.time.delayedCall(ms, () => {
      this.timers.delete(timer);
      if (!this.destroyed) callback();
    });
    this.timers.add(timer);
  }

  private buildBobber(): Phaser.GameObjects.Container {
    const body = this.scene.add.graphics();
    // Red body with a white top cap, matching the cast bobber style.
    body.fillStyle(0xe54d46, 1);
    body.fillCircle(0, 0, 7);
    body.fillStyle(0xfff0c4, 1);
    body.beginPath();
    body.moveTo(0, 0);
    body.lineTo(-7, 0);
    body.arc(0, 0, 7, Math.PI, Math.PI * 2, false);
    body.closePath();
    body.fillPath();
    body.fillRect(-1, -10, 2, 3);
    body.lineStyle(1, 0x3a0d12, 0.9);
    body.strokeCircle(0, 0, 7);
    return this.track(
      this.scene.add.container(this.anchor.x, this.anchor.y, [body]).setDepth(this.depth),
    );
  }

  private refreshStatusBar(force = false): void {
    const assistLabel = this.model.assist ? "辅助·" : "";
    const label = `${assistLabel}目标：${this.options.targetLabel}  ${this.model.judgedCount}/${this.model.totalNotes}`;
    const tension = Math.round(this.model.tension);
    const combo = this.model.combo;
    const cacheKey = `${label}|${tension}|${combo}`;
    if (force || cacheKey !== this.statusCache) {
      this.statusCache = cacheKey;
      this.labelText.setText(label);
      this.tensionText.setText(`张力 ${tension}`);
      this.comboText.setText(`连击 ${combo}`);
      const gap = 18;
      const pad = 14;
      const contentWidth =
        this.labelText.width + gap + this.tensionText.width + gap + this.comboText.width;
      let x = -contentWidth / 2;
      this.labelText.setX(x);
      x += this.labelText.width + gap;
      this.tensionText.setX(x);
      x += this.tensionText.width + gap;
      this.comboText.setX(x);
      this.statusBg.clear();
      this.statusBg.fillStyle(0x07111c, 0.62);
      this.statusBg.fillRect(-contentWidth / 2 - pad, -13, contentWidth + pad * 2, 26);
      this.statusBg.lineStyle(1, 0x9fd8ff, 0.35);
      this.statusBg.strokeRect(-contentWidth / 2 - pad, -13, contentWidth + pad * 2, 26);
    }
    // The numeric tension stays visible at all times; color is auxiliary.
    const now = this.scene.time.now;
    const value = this.model.tension;
    const warning = now < this.warningUntil;
    let css = "#fff2b6";
    if (warning) css = this.warningCss;
    else if (value < QIZHEN_FISHING_TENSION.warnLow) css = "#9fd8ff";
    else if (value > QIZHEN_FISHING_TENSION.warnHigh) css = "#ff9a6e";
    this.tensionText.setColor(css);
    if (warning && !this.reducedMotion) {
      this.tensionText.setAlpha(Math.floor(now / 120) % 2 === 0 ? 1 : 0.45);
    } else {
      this.tensionText.setAlpha(1);
    }
  }

  private updateLine(): void {
    const from = this.options.lineFrom?.();
    if (!from) {
      this.lineGraphics.clear();
      this.lineLowMarker.setVisible(false);
      this.lineHighMarker.setVisible(false);
      return;
    }
    const toX = this.anchor.x;
    const toY = this.anchor.y;
    const tension = this.model.tension;
    const low = tension < QIZHEN_FISHING_TENSION.warnLow;
    const high = tension > QIZHEN_FISHING_TENSION.warnHigh;
    const g = this.lineGraphics;
    g.clear();
    g.lineStyle(1.5, low ? 0x9fd8ff : high ? 0xffb0a0 : 0xeaf6ee, 0.9);
    const midX = (from.x + toX) / 2;
    const midY = (from.y + toY) / 2;
    if (low) {
      // Slack line: a clearly sagging quadratic curve plus the ▼ marker.
      const dist = Math.hypot(toX - from.x, toY - from.y);
      const sag = Phaser.Math.Clamp(dist * 0.16, 12, 36);
      const ctrlY = midY + sag * 2;
      const segments = 12;
      g.beginPath();
      g.moveTo(from.x, from.y);
      for (let i = 1; i <= segments; i += 1) {
        const t = i / segments;
        g.lineTo(
          (1 - t) * (1 - t) * from.x + 2 * (1 - t) * t * midX + t * t * toX,
          (1 - t) * (1 - t) * from.y + 2 * (1 - t) * t * ctrlY + t * t * toY,
        );
      }
      g.strokePath();
      this.lineLowMarker.setPosition(midX, midY + sag + 8).setVisible(true);
      this.lineHighMarker.setVisible(false);
      return;
    }
    if (high) {
      // Over-tensioned line: high-frequency jitter plus the ▲ marker.
      const dist = Math.hypot(toX - from.x, toY - from.y);
      const segments = Math.max(4, Math.floor(dist / 9));
      const nx = dist > 0 ? -(toY - from.y) / dist : 0;
      const ny = dist > 0 ? (toX - from.x) / dist : 0;
      g.beginPath();
      g.moveTo(from.x, from.y);
      for (let i = 1; i < segments; i += 1) {
        const t = i / segments;
        const offset = (Math.random() * 2 - 1) * 1.8;
        g.lineTo(
          from.x + (toX - from.x) * t + nx * offset,
          from.y + (toY - from.y) * t + ny * offset,
        );
      }
      g.lineTo(toX, toY);
      g.strokePath();
      this.lineHighMarker.setPosition(midX, midY - 14).setVisible(true);
      this.lineLowMarker.setVisible(false);
      return;
    }
    g.lineBetween(from.x, from.y, toX, toY);
    this.lineLowMarker.setVisible(false);
    this.lineHighMarker.setVisible(false);
  }

  private createNoteVisual(note: QizhenFishingNote): NoteVisual {
    const ring = this.track(this.scene.add.graphics().setDepth(this.depth - 1));
    const icon = this.track(
      this.scene.add.container(this.anchor.x, this.anchor.y).setDepth(this.depth + 1),
    );
    const iconGraphics = this.scene.add.graphics();
    this.drawActionIcon(iconGraphics, note.action);
    const arrow = this.scene.add.text(0, 9, ACTION_ARROWS[note.action], {
      ...HUD_TEXT_STYLE,
      fontStyle: "bold",
      color: ACTION_CSS[note.action],
    }).setOrigin(0.5, 0);
    icon.add([iconGraphics, arrow]);
    if (note.cue) {
      icon.add(
        this.scene.add.text(0, 25, note.cue === "left_intro" ? "左收线" : "右收线", {
          ...HUD_TEXT_STYLE,
          fontSize: "11px",
          color: "#eaffff",
        }).setOrigin(0.5, 0),
      );
    }
    let countdown: Phaser.GameObjects.Text | null = null;
    if (this.reducedMotion) {
      countdown = this.scene.add.text(20, -12, "", {
        ...HUD_TEXT_STYLE,
        fontSize: "14px",
        fontStyle: "bold",
        color: "#ffffff",
      }).setOrigin(0.5);
      icon.add(countdown);
    }
    const visual: NoteVisual = {
      ring,
      icon,
      holdArc: null,
      countdown,
      lastRadius: RING_START_RADIUS,
      wasHolding: false,
    };
    this.noteVisuals.set(note.index, visual);
    return visual;
  }

  private renderNote(note: QizhenFishingNote, elapsed: number): void {
    const visual = this.noteVisuals.get(note.index) ?? this.createNoteVisual(note);
    const span = Math.max(note.timeSec - note.spawnSec, 0.001);
    const progress = Phaser.Math.Clamp((elapsed - note.spawnSec) / span, 0, 1);
    const radius = this.reducedMotion
      ? this.discreteRadius(progress)
      : Phaser.Math.Linear(RING_START_RADIUS, RING_END_RADIUS, progress);
    visual.lastRadius = radius;
    const ring = visual.ring;
    if (ring) {
      const assist = this.model.assist;
      const color = (assist ? RING_COLORS_ASSIST : RING_COLORS)[note.action];
      ring.clear();
      ring.lineStyle(assist ? 4 : 2.5, color, assist ? 1 : 0.8);
      ring.strokeCircle(this.anchor.x, this.anchor.y, radius);
      if (!this.reducedMotion) {
        ring.lineStyle(1, color, assist ? 0.5 : 0.3);
        ring.strokeCircle(this.anchor.x, this.anchor.y, radius + 6);
      }
      if (note.holdBeats > 0) {
        // Static hint arc marking a hold note before it is pressed.
        ring.lineStyle(2, 0xffffff, assist ? 0.6 : 0.35);
        ring.beginPath();
        ring.arc(
          this.anchor.x,
          this.anchor.y,
          HOLD_ARC_RADIUS - 2,
          Phaser.Math.DegToRad(-90),
          Phaser.Math.DegToRad(150),
          false,
        );
        ring.strokePath();
      }
    }
    visual.icon?.setPosition(this.anchor.x, this.anchor.y - Math.max(radius - 11, 2));
    if (visual.countdown) {
      const beatsLeft = Math.max(
        0,
        Math.ceil((note.timeSec - elapsed) / QIZHEN_FISHING_TIMING.beatSec),
      );
      visual.countdown.setText(beatsLeft > 0 ? String(beatsLeft) : "·");
    }
  }

  private renderHoldState(note: QizhenFishingNote, elapsed: number): void {
    let visual = this.noteVisuals.get(note.index);
    if (!visual) {
      visual = {
        ring: null,
        icon: null,
        holdArc: null,
        countdown: null,
        lastRadius: RING_END_RADIUS,
        wasHolding: false,
      };
      this.noteVisuals.set(note.index, visual);
    }
    visual.wasHolding = true;
    if (!visual.holdArc) {
      visual.holdArc = this.track(this.scene.add.graphics().setDepth(this.depth + 1));
    }
    // The arc closes toward a full circle as the remaining hold time runs out.
    const progress = Phaser.Math.Clamp(
      (elapsed - note.timeSec) / Math.max(note.holdSec, 0.001),
      0,
      1,
    );
    visual.holdArc.clear();
    visual.holdArc.lineStyle(3.5, 0xffffff, 0.95);
    visual.holdArc.beginPath();
    visual.holdArc.arc(
      this.anchor.x,
      this.anchor.y,
      HOLD_ARC_RADIUS,
      -Math.PI / 2,
      -Math.PI / 2 + progress * Math.PI * 2,
      false,
    );
    visual.holdArc.strokePath();
  }

  private discreteRadius(progress: number): number {
    const step = Math.min(
      REDUCED_RING_STEPS.length - 1,
      Math.floor(progress * REDUCED_RING_STEPS.length),
    );
    return REDUCED_RING_STEPS[step];
  }

  private drawActionIcon(g: Phaser.GameObjects.Graphics, action: QizhenFishingAction): void {
    if (action === "left") {
      // Willow-branch left paddle: a curved green branch with small leaves.
      g.lineStyle(2, 0x7fbf5a, 1);
      g.beginPath();
      g.moveTo(-8, 6);
      g.lineTo(-4, 2);
      g.lineTo(0, -2);
      g.lineTo(5, -7);
      g.strokePath();
      g.fillStyle(0x9fe6a0, 1);
      g.fillEllipse(-5, -1, 7, 4);
      g.fillEllipse(1, 3, 7, 4);
      g.fillEllipse(6, -9, 6, 3.5);
      return;
    }
    if (action === "right") {
      // Triangular warning-sign right paddle.
      g.fillStyle(0xffd166, 1);
      g.fillTriangle(0, -10, -9, 6, 9, 6);
      g.lineStyle(2, 0xe54d46, 1);
      g.strokeTriangle(0, -10, -9, 6, 9, 6);
      g.lineStyle(2, 0x7a1f1f, 1);
      g.beginPath();
      g.moveTo(0, -5);
      g.lineTo(0, 0);
      g.strokePath();
      g.fillStyle(0x7a1f1f, 1);
      g.fillCircle(0, 3, 1.3);
      return;
    }
    // Upward fish hook.
    g.lineStyle(2, 0xd8f4ff, 1);
    g.beginPath();
    g.moveTo(3, -9);
    g.lineTo(3, 1);
    g.lineTo(2, 4);
    g.lineTo(0, 6);
    g.lineTo(-2, 6);
    g.lineTo(-4, 4);
    g.strokePath();
    g.strokeCircle(3, -9, 1.6);
    g.fillStyle(0xd8f4ff, 1);
    g.fillTriangle(-4, 4, -1, 2, -4, 1);
  }

  private flashJudgmentText(judgment: QizhenFishingJudgment): void {
    const text = this.track(
      this.scene.add.text(this.anchor.x, this.anchor.y - 42, JUDGMENT_WORDS[judgment], {
        fontFamily: "monospace",
        fontSize: "17px",
        fontStyle: "bold",
        color: JUDGMENT_CSS[judgment],
        stroke: "#07111c",
        strokeThickness: 4,
      }).setOrigin(0.5).setDepth(this.depth + 2),
    );
    if (this.reducedMotion) {
      this.delay(420, () => this.release(text));
      return;
    }
    this.scene.tweens.add({
      targets: text,
      y: text.y - 14,
      alpha: 0,
      duration: 420,
      ease: "Cubic.easeOut",
      onComplete: () => this.release(text),
    });
  }

  private spawnBurst(color: number, radius: number, muted = false): void {
    const startRadius = Math.max(radius, 8);
    const ring = this.track(
      this.scene.add.circle(this.anchor.x, this.anchor.y, startRadius, 0xffffff, 0)
        .setStrokeStyle(muted ? 2 : 3, color, muted ? 0.7 : 0.95)
        .setDepth(this.depth + 2),
    );
    const endRadius = startRadius + (muted ? 16 : 30);
    this.scene.tweens.add({
      targets: ring,
      scaleX: endRadius / startRadius,
      scaleY: endRadius / startRadius,
      alpha: 0,
      duration: muted ? 240 : 300,
      ease: "Cubic.easeOut",
      onComplete: () => this.release(ring),
    });
  }

  private removeNoteVisual(visual: NoteVisual): void {
    if (visual.ring) {
      this.release(visual.ring);
      visual.ring = null;
    }
    if (visual.icon) {
      this.release(visual.icon);
      visual.icon = null;
    }
    if (visual.holdArc) {
      this.release(visual.holdArc);
      visual.holdArc = null;
    }
  }

  private clearNoteVisuals(): void {
    for (const visual of this.noteVisuals.values()) this.removeNoteVisual(visual);
    this.noteVisuals.clear();
  }
}
