/** Retired reference only. Active fishing uses LakeFishingRitualVisual and its one-button first-cast guide. */
import Phaser from "phaser";
import type { QizhenFishingAction } from "./QizhenFishingRhythmModel";

export interface QizhenFishingTutorialStep {
  action: QizhenFishingAction;
  title: string;
  detail: string;
  holdDurationSec?: number;
}

export interface QizhenFishingTutorialOverlayOptions {
  scene: Phaser.Scene;
  anchor: { x: number; y: number };
  targetLabel: string;
  steps: readonly QizhenFishingTutorialStep[];
  reducedMotion: boolean;
  now: () => number;
  depth?: number;
}

export interface QizhenFishingTutorialInputResult {
  consumed: boolean;
  completed: boolean;
}

const PANEL_X = 480;
const PANEL_Y = 234;
const KEYCARD_Y = 312;
const KEYCARD_SPACING = 118;
const HOLD_BAR_WIDTH = 210;

const ACTION_KEYS: Record<QizhenFishingAction, string> = {
  left: "A",
  hook: "S",
  right: "D",
};

const ACTION_LABELS: Record<QizhenFishingAction, string> = {
  left: "左收线",
  hook: "提竿",
  right: "右收线",
};

const ACTION_COLORS: Record<QizhenFishingAction, number> = {
  left: 0x9ee6a4,
  hook: 0x9fdcff,
  right: 0xffd36a,
};

const TEXT_STYLE: Phaser.Types.GameObjects.Text.TextStyle = {
  fontFamily: "monospace",
  fontSize: "14px",
  color: "#f7fbff",
  stroke: "#07111c",
  strokeThickness: 3,
};

interface KeyCardVisual {
  action: QizhenFishingAction;
  root: Phaser.GameObjects.Container;
  frame: Phaser.GameObjects.Graphics;
  keyText: Phaser.GameObjects.Text;
  labelText: Phaser.GameObjects.Text;
}

export class QizhenFishingTutorialOverlay {
  private readonly scene: Phaser.Scene;
  private readonly anchor: { x: number; y: number };
  private readonly targetLabel: string;
  private readonly reducedMotion: boolean;
  private readonly now: () => number;
  private readonly depth: number;
  private readonly steps: readonly QizhenFishingTutorialStep[];
  private readonly owned = new Set<Phaser.GameObjects.GameObject>();
  private readonly ring: Phaser.GameObjects.Graphics;
  private readonly panel: Phaser.GameObjects.Container;
  private readonly panelBg: Phaser.GameObjects.Graphics;
  private readonly titleText: Phaser.GameObjects.Text;
  private readonly detailText: Phaser.GameObjects.Text;
  private readonly footerText: Phaser.GameObjects.Text;
  private readonly holdBar: Phaser.GameObjects.Graphics;
  private readonly holdLabel: Phaser.GameObjects.Text;
  private readonly keyCards: KeyCardVisual[];

  private stepIndex = 0;
  private holdStartedAtSec: number | null = null;
  private complete = false;
  private feedbackUntil = 0;
  private feedbackColor = "#f7fbff";
  private feedbackText = "";
  private lastPromptKey = "";
  private destroyed = false;

  constructor(options: QizhenFishingTutorialOverlayOptions) {
    this.scene = options.scene;
    this.anchor = options.anchor;
    this.targetLabel = options.targetLabel;
    this.reducedMotion = options.reducedMotion;
    this.now = options.now;
    this.depth = options.depth ?? 2610;
    this.steps = options.steps;

    this.ring = this.track(this.scene.add.graphics().setDepth(this.depth - 1));
    this.panelBg = this.scene.add.graphics();
    this.titleText = this.scene.add.text(0, -36, "", {
      ...TEXT_STYLE,
      fontSize: "18px",
      fontStyle: "bold",
      color: "#ffe7a8",
    }).setOrigin(0.5, 0.5);
    this.detailText = this.scene.add.text(0, -6, "", {
      ...TEXT_STYLE,
      fontSize: "13px",
      color: "#e5f2ff",
      align: "center",
      wordWrap: { width: 420, useAdvancedWrap: true },
    }).setOrigin(0.5, 0.5);
    this.footerText = this.scene.add.text(0, 102, "", {
      ...TEXT_STYLE,
      fontSize: "12px",
      color: "#f7fbff",
    }).setOrigin(0.5, 0.5);
    this.holdBar = this.scene.add.graphics();
    this.holdLabel = this.scene.add.text(0, 66, "", {
      ...TEXT_STYLE,
      fontSize: "12px",
      color: "#f7fbff",
    }).setOrigin(0.5, 0.5);
    this.keyCards = this.buildKeyCards();
    this.panel = this.track(this.scene.add.container(
      PANEL_X,
      PANEL_Y,
      [
        this.panelBg,
        this.titleText,
        this.detailText,
        this.holdBar,
        this.holdLabel,
        ...this.keyCards.map((card) => card.root),
        this.footerText,
      ],
    ).setScrollFactor(0).setDepth(this.depth + 2));
    this.drawPanelFrame();
    this.refreshPrompt(true);
  }

  isCompleted(): boolean {
    return this.complete;
  }

  getDebugState(): Record<string, unknown> {
    const step = this.currentStep();
    return {
      state: this.complete
        ? "completed"
        : this.isHoldingStep(step) && this.holdStartedAtSec !== null
          ? "holding"
          : "awaiting_press",
      stepIndex: this.stepIndex + 1,
      totalSteps: this.steps.length,
      expectedAction: step?.action ?? null,
      prompt: this.feedbackUntil > this.scene.time.now ? this.feedbackText : this.detailText.text,
      requiresRelease: this.isHoldingStep(step),
      holdProgress: Number(this.currentHoldProgress().toFixed(3)),
      targetLabel: this.targetLabel,
    };
  }

  update(): void {
    if (this.destroyed) return;
    this.drawRing();
    this.refreshPrompt();
    this.refreshHoldBar();
  }

  handleInput(action: QizhenFishingAction, type: "press" | "release"): QizhenFishingTutorialInputResult {
    if (this.destroyed || this.complete) return { consumed: false, completed: false };
    const step = this.currentStep();
    if (!step) return { consumed: false, completed: false };
    const nowSec = this.now();
    if (type === "release") {
      if (!this.isHoldingStep(step) || action !== step.action || this.holdStartedAtSec === null) {
        return { consumed: false, completed: false };
      }
      if (this.currentHoldProgress() >= 1) {
        this.advanceStep();
      } else {
        this.holdStartedAtSec = null;
        this.flashFeedback("继续按住，再松开。", "#ffb89e");
      }
      return { consumed: true, completed: this.complete };
    }

    if (action !== step.action) {
      this.flashFeedback(`这一步按 ${ACTION_KEYS[step.action]} ${ACTION_LABELS[step.action]}`, "#ffb89e");
      return { consumed: true, completed: false };
    }
    if (this.isHoldingStep(step)) {
      if (this.holdStartedAtSec === null) {
        this.holdStartedAtSec = nowSec;
        this.flashFeedback(`按住 ${ACTION_KEYS[action]}，进度满了再松开`, "#d7ecff");
      }
      return { consumed: true, completed: false };
    }
    this.advanceStep();
    return { consumed: true, completed: this.complete };
  }

  destroy(): void {
    if (this.destroyed) return;
    this.destroyed = true;
    for (const obj of this.owned) obj.destroy();
    this.owned.clear();
  }

  private currentStep(): QizhenFishingTutorialStep | null {
    return this.steps[this.stepIndex] ?? null;
  }

  private isHoldingStep(
    step: QizhenFishingTutorialStep | null
  ): step is QizhenFishingTutorialStep & { holdDurationSec: number } {
    return typeof step?.holdDurationSec === "number" && step.holdDurationSec > 0;
  }

  private currentHoldProgress(): number {
    const step = this.currentStep();
    if (!this.isHoldingStep(step) || this.holdStartedAtSec === null) return 0;
    const holdDurationSec = step.holdDurationSec ?? 0;
    return Phaser.Math.Clamp((this.now() - this.holdStartedAtSec) / holdDurationSec, 0, 1);
  }

  private advanceStep(): void {
    const step = this.currentStep();
    if (!step) return;
    this.holdStartedAtSec = null;
    this.flashFeedback(`${ACTION_KEYS[step.action]} ${ACTION_LABELS[step.action]} 已确认`, "#b9ffd0");
    this.stepIndex += 1;
    if (this.stepIndex >= this.steps.length) {
      this.complete = true;
      this.titleText.setText("教学完成");
      this.detailText.setText("已经知道按键和时机，正式节奏马上开始。");
      this.footerText.setText(`目标：${this.targetLabel}  ·  正式开始前保留 4 拍预备`);
      this.holdBar.clear();
      this.holdLabel.setText("");
      this.refreshKeyCards();
      return;
    }
    this.refreshPrompt(true);
  }

  private flashFeedback(text: string, color: string): void {
    this.feedbackText = text;
    this.feedbackColor = color;
    this.feedbackUntil = this.scene.time.now + 780;
    this.footerText.setColor(color);
    this.footerText.setText(text);
  }

  private drawPanelFrame(): void {
    this.panelBg.clear();
    this.panelBg.fillStyle(0x07111c, 0.84);
    this.panelBg.fillRoundedRect(-254, -64, 508, 186, 12);
    this.panelBg.lineStyle(2, 0x9fd8ff, 0.42);
    this.panelBg.strokeRoundedRect(-254, -64, 508, 186, 12);
    this.panelBg.lineStyle(1, 0xffd36a, 0.24);
    this.panelBg.strokeRoundedRect(-248, -58, 496, 174, 10);
  }

  private drawRing(): void {
    const step = this.currentStep();
    const action = step?.action ?? "hook";
    const color = ACTION_COLORS[action];
    const nowMs = this.scene.time.now;
    const baseRadius = this.reducedMotion ? 28 : 30 + Math.sin(nowMs / 130) * 4;
    this.ring.clear();
    this.ring.lineStyle(3, color, 0.96);
    this.ring.strokeCircle(this.anchor.x, this.anchor.y, baseRadius);
    this.ring.lineStyle(2, 0xffffff, 0.7);
    this.ring.strokeCircle(this.anchor.x, this.anchor.y, baseRadius + 11);
    this.ring.fillStyle(color, 0.2);
    this.ring.fillCircle(this.anchor.x, this.anchor.y, 10);
  }

  private refreshPrompt(force = false): void {
    const step = this.currentStep();
    if (!step) return;
    const promptKey = `${this.stepIndex}|${this.holdStartedAtSec !== null}|${this.complete}`;
    if (!force && promptKey === this.lastPromptKey && this.feedbackUntil > this.scene.time.now) return;
    this.lastPromptKey = promptKey;
    this.titleText.setText(`教学 ${Math.min(this.stepIndex + 1, this.steps.length)}/${this.steps.length} · ${this.targetLabel}`);
    if (this.feedbackUntil > this.scene.time.now) {
      this.detailText.setColor(this.feedbackColor);
      this.detailText.setText(this.feedbackText);
    } else {
      this.detailText.setColor("#e5f2ff");
      this.detailText.setText(step.detail);
    }
    if (this.feedbackUntil <= this.scene.time.now) {
      this.footerText.setColor("#f7fbff");
      this.footerText.setText(step.title);
    }
    this.refreshKeyCards();
  }

  private refreshKeyCards(): void {
    const step = this.currentStep();
    const activeAction = this.complete ? null : step?.action ?? null;
    for (const card of this.keyCards) {
      const active = activeAction === card.action;
      const color = ACTION_COLORS[card.action];
      card.frame.clear();
      card.frame.fillStyle(active ? 0x173042 : 0x101b24, 0.96);
      card.frame.fillRoundedRect(-42, -24, 84, 52, 10);
      card.frame.lineStyle(active ? 3 : 2, active ? color : 0x5f7280, active ? 1 : 0.55);
      card.frame.strokeRoundedRect(-42, -24, 84, 52, 10);
      card.keyText.setColor(active ? Phaser.Display.Color.IntegerToColor(color).rgba : "#d6e7f5");
      card.labelText.setColor(active ? "#ffffff" : "#b4c7d6");
      if (this.complete) {
        card.labelText.setText("已就绪");
      } else if (this.isHoldingStep(step) && active && this.holdStartedAtSec !== null) {
        card.labelText.setText("按住中");
      } else {
        card.labelText.setText(ACTION_LABELS[card.action]);
      }
    }
  }

  private refreshHoldBar(): void {
    const step = this.currentStep();
    if (!this.isHoldingStep(step)) {
      this.holdBar.clear();
      this.holdLabel.setText("");
      return;
    }
    const holdStep = step;
    const progress = this.currentHoldProgress();
    const color = ACTION_COLORS[holdStep.action];
    const top = 44;
    this.holdBar.clear();
    this.holdBar.fillStyle(0x07111c, 0.96);
    this.holdBar.fillRoundedRect(-HOLD_BAR_WIDTH / 2, top, HOLD_BAR_WIDTH, 14, 7);
    this.holdBar.lineStyle(2, 0xe8f4ff, 0.8);
    this.holdBar.strokeRoundedRect(-HOLD_BAR_WIDTH / 2, top, HOLD_BAR_WIDTH, 14, 7);
    this.holdBar.fillStyle(color, 0.96);
    this.holdBar.fillRoundedRect(-HOLD_BAR_WIDTH / 2 + 3, top + 3, (HOLD_BAR_WIDTH - 6) * progress, 8, 4);
    this.holdLabel.setText(
      this.holdStartedAtSec === null
        ? `按住 ${ACTION_KEYS[holdStep.action]}，进度满了再松开`
        : `长按进度 ${Math.round(progress * 100)}%`
    );
  }

  private buildKeyCards(): KeyCardVisual[] {
    const actions: QizhenFishingAction[] = ["left", "hook", "right"];
    return actions.map((action, index) => {
      const frame = this.scene.add.graphics();
      const keyText = this.scene.add.text(0, -3, ACTION_KEYS[action], {
        ...TEXT_STYLE,
        fontSize: "18px",
        fontStyle: "bold",
      }).setOrigin(0.5, 0.5);
      const labelText = this.scene.add.text(0, 16, ACTION_LABELS[action], {
        ...TEXT_STYLE,
        fontSize: "11px",
      }).setOrigin(0.5, 0.5);
      const root = this.track(this.scene.add.container(
        (index - 1) * KEYCARD_SPACING,
        KEYCARD_Y - PANEL_Y,
        [frame, keyText, labelText],
      ));
      return { action, root, frame, keyText, labelText };
    });
  }

  private track<T extends Phaser.GameObjects.GameObject>(obj: T): T {
    this.owned.add(obj);
    return obj;
  }
}
