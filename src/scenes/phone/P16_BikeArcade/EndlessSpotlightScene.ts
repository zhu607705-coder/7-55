import Phaser from "phaser";
import {
  createEndlessSpotlightWave,
  MAX_ENDLESS_SPOTLIGHT_SCORE,
  scoreEndlessSpotlight,
  type EndlessSpotlightPoint,
  type EndlessSpotlightWave,
} from "./EndlessSpotlightRules";
import type { EndlessArcadeControlAction, EndlessArcadeSceneBridge } from "./EndlessArcadeRuntime";

const WIDTH = 390;
const HEIGHT = 650;
const STAGE_CENTER_X = WIDTH / 2;
const STAGE_CENTER_Y = 278;
const MIN_BEAM_X = 34;
const MAX_BEAM_X = WIDTH - 34;
const BEAM_SPEED = 270;
const TRANSITION_MS = 400;
const MAX_BATTERY_CHARGES = 3;
const FONT = '"Fusion Pixel 12px Proportional SC", "Fusion Pixel", "PingFang SC", sans-serif';

type SpotlightPhase = "preview" | "action" | "transition" | "ended";
type SpotlightFeedback = "preview" | "action" | "locking" | "off_target" | "penalty" | "success";

interface SpotlightPosition {
  x: number;
  y: number;
}

export class EndlessSpotlightScene extends Phaser.Scene {
  private bridge!: EndlessArcadeSceneBridge;
  private wave!: EndlessSpotlightWave;
  private waveIndex = 0;
  private nextWaveIndex = 0;
  private completedWaves = 0;
  private score = 0;
  private combo = 0;
  private maxCombo = 0;
  private batteryCharges = MAX_BATTERY_CHARGES;
  private runElapsedMs = 0;
  private previewElapsedMs = 0;
  private waveElapsedMs = 0;
  private transitionRemainingMs = 0;
  private lockMs = 0;
  private beamX = STAGE_CENTER_X;
  private beamOn = false;
  private moveLeft = false;
  private moveRight = false;
  private ended = false;
  private earlyPenaltyApplied = false;
  private decoyCoverageActive = false;
  private phase: SpotlightPhase = "preview";
  private feedback: SpotlightFeedback = "preview";
  private cleanupComplete = false;
  private targetPosition: SpotlightPosition = { x: 35, y: 150 };
  private decoyPosition: SpotlightPosition | null = null;
  private lastPublishedBucket = -1;
  private stageGraphics!: Phaser.GameObjects.Graphics;
  private routeGraphics!: Phaser.GameObjects.Graphics;
  private hudGraphics!: Phaser.GameObjects.Graphics;
  private targetGraphics!: Phaser.GameObjects.Graphics;
  private decoyGraphics!: Phaser.GameObjects.Graphics;
  private cueText!: Phaser.GameObjects.Text;
  private waveText!: Phaser.GameObjects.Text;
  private lockText!: Phaser.GameObjects.Text;
  private batteryText!: Phaser.GameObjects.Text;
  private previousRenderEndlessSpotlightToText: (() => string) | undefined;
  private previousAdvanceTime: ((ms: number) => void | Promise<void>) | undefined;
  private readonly keyboardDown = (event: KeyboardEvent) => this.handleKeyboardPress(event);
  private readonly keyboardUp = (event: KeyboardEvent) => this.handleKeyboardRelease(event);

  constructor() {
    super("endless-spotlight");
  }

  create(): void {
    this.cleanupComplete = false;
    this.bridge = this.registry.get("endlessArcadeBridge") as EndlessArcadeSceneBridge;
    this.cameras.main.setBackgroundColor(0x11151e);
    this.drawStaticStage();
    this.input.keyboard?.on("keydown", this.keyboardDown);
    this.input.keyboard?.on("keyup", this.keyboardUp);
    this.events.once(Phaser.Scenes.Events.SHUTDOWN, this.destroyScene, this);
    this.events.once(Phaser.Scenes.Events.DESTROY, this.destroyScene, this);
    this.installInspectionHooks();
    this.startWave(0);
  }

  update(_time: number, delta: number): void {
    this.advanceSimulation(Math.max(0, Math.min(100, delta)));
  }

  handleEndlessControl(action: EndlessArcadeControlAction): void {
    if (this.ended) return;
    if (action === "release_left") this.moveLeft = false;
    if (action === "release_right") this.moveRight = false;
    if (action === "release_primary") {
      if (this.phase === "action" && this.lockMs > 0) {
        this.applyPenalty("锁定中断");
        return;
      }
      this.beamOn = false;
      this.lockMs = 0;
      this.updateVisuals();
      return;
    }
    if (this.phase === "transition") return;
    if (action === "left") this.moveLeft = true;
    if (action === "right") this.moveRight = true;
    if (action === "primary") {
      if (this.phase === "preview") {
        if (!this.earlyPenaltyApplied) {
          this.earlyPenaltyApplied = true;
          this.applyPenalty("提前照射");
        }
        return;
      }
      this.beamOn = true;
    }
    this.updateVisuals();
  }

  releaseEndlessControls(): void {
    this.moveLeft = false;
    this.moveRight = false;
    this.beamOn = false;
    this.lockMs = 0;
    this.decoyCoverageActive = false;
    if (this.wave) this.updateVisuals();
  }

  cleanupEndlessScene(): void {
    this.destroyScene();
  }

  setEndlessAim(normalizedX: number): void {
    const aim = Phaser.Math.Clamp(Number.isFinite(normalizedX) ? normalizedX : 0.5, 0, 1);
    this.beamX = Phaser.Math.Linear(MIN_BEAM_X, MAX_BEAM_X, aim);
    this.updateVisuals();
  }

  private drawStaticStage(): void {
    this.stageGraphics = this.add.graphics().setDepth(0);
    this.routeGraphics = this.add.graphics().setDepth(1);
    this.hudGraphics = this.add.graphics().setDepth(7);
    this.targetGraphics = this.add.graphics().setDepth(5);
    this.decoyGraphics = this.add.graphics().setDepth(4);

    this.stageGraphics.fillStyle(0x11151e, 1);
    this.stageGraphics.fillRect(0, 0, WIDTH, HEIGHT);
    this.stageGraphics.fillStyle(0x1c2430, 1);
    this.stageGraphics.fillRect(16, 64, WIDTH - 32, 410);
    this.stageGraphics.lineStyle(2, 0x4b5666, 0.72);
    this.stageGraphics.strokeRect(16, 64, WIDTH - 32, 410);
    for (let y = 94; y <= 430; y += 56) {
      this.stageGraphics.lineStyle(1, 0x394454, 0.36);
      this.stageGraphics.lineBetween(18, y, WIDTH - 18, y);
    }
    this.stageGraphics.fillStyle(0x0a0d13, 1);
    this.stageGraphics.fillRect(0, 474, WIDTH, HEIGHT - 474);
    this.stageGraphics.fillStyle(0x2c3542, 1);
    this.stageGraphics.fillRect(22, 604, WIDTH - 44, 18);
    this.stageGraphics.fillStyle(0x667284, 1);
    this.stageGraphics.fillCircle(38, 613, 7);
    this.stageGraphics.fillCircle(WIDTH - 38, 613, 7);

    this.add.text(18, 14, "灯光追逐", { color: "#f6e3a0", fontFamily: FONT, fontSize: "16px" }).setDepth(8);
    this.waveText = this.add.text(WIDTH - 18, 16, "第 1 轮 · T1", {
      color: "#f4c95d",
      fontFamily: FONT,
      fontSize: "13px",
    }).setOrigin(1, 0).setDepth(8);
    this.cueText = this.add.text(STAGE_CENTER_X, 492, "记住预览路线，行动开始后再照射", {
      align: "center",
      color: "#d9e1ea",
      fontFamily: FONT,
      fontSize: "12px",
      wordWrap: { width: 350 },
    }).setOrigin(0.5).setDepth(8);
    this.lockText = this.add.text(STAGE_CENTER_X, 535, "预览", {
      color: "#f7f2df",
      fontFamily: FONT,
      fontSize: "13px",
    }).setOrigin(0.5).setDepth(9);
    this.batteryText = this.add.text(STAGE_CENTER_X, 562, "照明电量 3 / 3", {
      color: "#d8e3eb",
      fontFamily: FONT,
      fontSize: "11px",
    }).setOrigin(0.5).setDepth(9);
    this.add.text(STAGE_CENTER_X, 637, "← / → 移动 · 按住 SPACE 照射", {
      color: "#aeb9c7",
      fontFamily: FONT,
      fontSize: "11px",
    }).setOrigin(0.5).setDepth(8);
  }

  private startWave(index: number): void {
    if (this.ended) return;
    this.wave = createEndlessSpotlightWave(this.bridge.seed, index);
    this.waveIndex = index;
    this.nextWaveIndex = index;
    this.phase = "preview";
    this.feedback = "preview";
    this.previewElapsedMs = 0;
    this.waveElapsedMs = 0;
    this.transitionRemainingMs = 0;
    this.lockMs = 0;
    this.beamOn = false;
    this.moveLeft = false;
    this.moveRight = false;
    this.earlyPenaltyApplied = false;
    this.decoyCoverageActive = false;
    this.lastPublishedBucket = -1;
    this.targetPosition = this.resolvePathPosition(this.wave.pathPoints, 0);
    this.decoyPosition = this.wave.decoyPathPoints.length > 0
      ? this.resolvePathPosition(this.wave.decoyPathPoints, 0)
      : null;
    this.waveText.setText(`第 ${index + 1} 轮 · T${this.wave.tier} · 预览`);
    this.setFeedback("preview", "记住预览路线，行动开始后再照射", 0xd9e1ea);
    this.drawWaveRoute();
    this.updateVisuals();
    this.publishSnapshot("路线预览");
  }

  private advanceSimulation(deltaMs: number): void {
    if (this.ended || !this.wave || deltaMs <= 0) return;
    this.runElapsedMs += deltaMs;
    if (this.phase === "transition") {
      this.transitionRemainingMs = Math.max(0, this.transitionRemainingMs - deltaMs);
      this.updateVisuals();
      if (this.transitionRemainingMs <= 0) this.startWave(this.nextWaveIndex);
      return;
    }

    const direction = Number(this.moveRight) - Number(this.moveLeft);
    this.beamX = Phaser.Math.Clamp(
      this.beamX + direction * BEAM_SPEED * (deltaMs / 1_000),
      MIN_BEAM_X,
      MAX_BEAM_X,
    );

    if (this.phase === "preview") {
      this.previewElapsedMs = Math.min(this.wave.previewMs, this.previewElapsedMs + deltaMs);
      const previewProgress = Math.min(1, this.previewElapsedMs / this.wave.previewMs);
      this.targetPosition = this.resolvePathPosition(this.wave.pathPoints, previewProgress);
      this.decoyPosition = this.wave.decoyPathPoints.length > 0
        ? this.resolvePathPosition(this.wave.decoyPathPoints, previewProgress)
        : null;
      this.updateVisuals();
      if (this.previewElapsedMs >= this.wave.previewMs) this.beginAction();
      return;
    }

    this.waveElapsedMs = Math.min(this.wave.actionMs, this.waveElapsedMs + deltaMs);
    const progress = Math.min(1, this.waveElapsedMs / this.wave.actionMs);
    this.targetPosition = this.resolvePathPosition(this.wave.pathPoints, progress);
    this.decoyPosition = this.wave.decoyPathPoints.length > 0
      ? this.resolvePathPosition(this.wave.decoyPathPoints, progress)
      : null;
    const targetCovered = Math.abs(this.beamX - this.targetPosition.x) <= this.wave.beamRadius;
    const decoyCovered = this.decoyPosition !== null
      && Math.abs(this.beamX - this.decoyPosition.x) <= this.wave.beamRadius;
    const wasLocking = this.lockMs > 0;

    if (this.beamOn && targetCovered) {
      this.decoyCoverageActive = false;
      this.lockMs = Math.min(this.wave.requiredLockMs, this.lockMs + deltaMs);
      this.setFeedback("locking", "路线匹配，锁定中", 0xc5ddd4);
    } else if (this.beamOn && decoyCovered) {
      this.lockMs = 0;
      if (!this.decoyCoverageActive) {
        this.decoyCoverageActive = true;
        this.applyPenalty("路线判断错误");
        return;
      }
    } else if (wasLocking) {
      this.lockMs = 0;
      this.applyPenalty("锁定中断");
      return;
    } else {
      this.decoyCoverageActive = false;
      this.lockMs = 0;
      if (this.beamOn) this.setFeedback("off_target", "光束未覆盖纸条", 0xd8c88f);
    }

    this.updateVisuals();
    if (this.lockMs >= this.wave.requiredLockMs) {
      this.completeWave();
      return;
    }
    if (this.waveElapsedMs >= this.wave.actionMs) {
      this.applyPenalty("行动超时");
      return;
    }

    const publishBucket = Math.floor(this.waveElapsedMs / 120);
    if (publishBucket !== this.lastPublishedBucket) {
      this.lastPublishedBucket = publishBucket;
      this.publishSnapshot(this.beamOn && targetCovered ? "锁定中" : this.beamOn ? "照射中" : "追踪中");
    }
  }

  private beginAction(): void {
    this.phase = "action";
    this.previewElapsedMs = this.wave.previewMs;
    this.waveElapsedMs = 0;
    this.lockMs = 0;
    this.beamOn = false;
    this.routeGraphics.clear();
    this.targetPosition = this.resolvePathPosition(this.wave.pathPoints, 0);
    this.decoyPosition = this.wave.decoyPathPoints.length > 0
      ? this.resolvePathPosition(this.wave.decoyPathPoints, 0)
      : null;
    this.waveText.setText(`第 ${this.waveIndex + 1} 轮 · T${this.wave.tier} · 行动`);
    this.setFeedback("action", "行动开始：按住照射并跟随预览路线", 0xc5ddd4);
    this.publishSnapshot("行动开始");
    this.updateVisuals();
  }

  private completeWave(): void {
    const completedTier = this.wave.tier;
    const completedLockMs = this.wave.requiredLockMs;
    this.completedWaves += 1;
    this.combo += 1;
    this.maxCombo = Math.max(this.maxCombo, this.combo);
    this.score = Math.min(
      MAX_ENDLESS_SPOTLIGHT_SCORE,
      this.score + scoreEndlessSpotlight(completedTier, completedLockMs, this.combo),
    );
    this.beginTransition(this.waveIndex + 1, "锁定完成", "success", 0xc5ddd4, "本轮完成");
  }

  private applyPenalty(reason: string): void {
    if (this.phase === "transition" || this.ended) return;
    this.batteryCharges = Math.max(0, this.batteryCharges - 1);
    this.combo = 0;
    this.lockMs = 0;
    this.beamOn = false;
    if (this.batteryCharges <= 0) {
      this.finish(`${reason}，电量耗尽`);
      return;
    }
    this.beginTransition(this.waveIndex, `${reason}，消耗 1 格电量`, "penalty", 0xe0a39a, reason);
  }

  private beginTransition(
    nextWaveIndex: number,
    message: string,
    feedback: "penalty" | "success",
    color: number,
    status: string,
  ): void {
    this.phase = "transition";
    this.nextWaveIndex = nextWaveIndex;
    this.transitionRemainingMs = TRANSITION_MS;
    this.beamOn = false;
    this.moveLeft = false;
    this.moveRight = false;
    this.lockMs = 0;
    this.routeGraphics.clear();
    this.waveText.setText(`第 ${this.waveIndex + 1} 轮 · 结算`);
    this.setFeedback(feedback, message, color);
    this.publishSnapshot(status);
    this.updateVisuals();
  }

  private finish(reason: string): void {
    if (this.ended) return;
    this.ended = true;
    this.phase = "ended";
    this.moveLeft = false;
    this.moveRight = false;
    this.beamOn = false;
    this.lockMs = 0;
    this.routeGraphics.clear();
    this.updateVisuals();
    this.cueText.setText(reason).setColor("#e0a39a");
    this.bridge.finish({
      mode: "spotlight",
      score: this.score,
      progress: this.completedWaves,
      tier: this.wave?.tier ?? 1,
      combo: this.maxCombo,
      lives: this.batteryCharges,
      durationMs: Math.max(0, Math.round(this.runElapsedMs)),
      status: reason,
    });
  }

  private publishSnapshot(status: string): void {
    this.bridge.publishSnapshot({
      mode: "spotlight",
      score: this.score,
      progress: this.completedWaves,
      tier: this.wave?.tier ?? 1,
      combo: this.combo,
      lives: this.batteryCharges,
      status,
    });
  }

  private drawWaveRoute(): void {
    this.routeGraphics.clear();
    this.drawPath(this.wave.pathPoints, 0xd4c48e, 0.6);
  }

  private drawPath(points: readonly EndlessSpotlightPoint[], color: number, alpha: number): void {
    if (points.length < 2) return;
    this.routeGraphics.lineStyle(2, color, alpha);
    const first = this.toStagePosition(points[0]);
    this.routeGraphics.beginPath();
    this.routeGraphics.moveTo(first.x, first.y);
    for (const point of points.slice(1)) {
      const position = this.toStagePosition(point);
      this.routeGraphics.lineTo(position.x, position.y);
    }
    this.routeGraphics.strokePath();
    for (const point of points) {
      const position = this.toStagePosition(point);
      this.routeGraphics.fillStyle(color, alpha);
      this.routeGraphics.fillCircle(position.x, position.y, 2.5);
    }
  }

  private updateVisuals(): void {
    if (!this.wave) return;
    const remainingRatio = this.phase === "preview"
      ? 1
      : Math.max(0, 1 - this.waveElapsedMs / this.wave.actionMs);
    const lockRatio = Math.max(0, Math.min(1, this.lockMs / this.wave.requiredLockMs));
    const withinBeam = Math.abs(this.beamX - this.targetPosition.x) <= this.wave.beamRadius;
    const beamColor = this.beamOn && withinBeam ? 0xc5ddd4 : 0xd8c88f;

    this.hudGraphics.clear();
    this.hudGraphics.fillStyle(0x252d39, 1);
    this.hudGraphics.fillRoundedRect(34, 510, WIDTH - 68, 18, 5);
    this.hudGraphics.fillStyle(beamColor, 1);
    this.hudGraphics.fillRoundedRect(38, 514, Math.round((WIDTH - 76) * lockRatio), 10, 3);
    for (let index = 0; index < MAX_BATTERY_CHARGES; index += 1) {
      const x = 118 + index * 55;
      this.hudGraphics.fillStyle(index < this.batteryCharges ? 0xd8c88f : 0x303a48, 1);
      this.hudGraphics.fillRoundedRect(x, 548, 44, 10, 3);
    }
    this.hudGraphics.fillStyle(0x303a48, 1);
    this.hudGraphics.fillRect(34, 577, WIDTH - 68, 8);
    this.hudGraphics.fillStyle(remainingRatio < 0.28 ? 0xe0a39a : 0xb7c7cf, 1);
    this.hudGraphics.fillRect(34, 577, Math.round((WIDTH - 68) * remainingRatio), 8);

    if (this.beamOn) {
      this.hudGraphics.fillStyle(beamColor, withinBeam ? 0.18 : 0.1);
      this.hudGraphics.fillTriangle(this.beamX - 18, 604, this.beamX + 18, 604, this.beamX, this.targetPosition.y - 4);
      this.hudGraphics.lineStyle(3, beamColor, 0.88);
      this.hudGraphics.strokeCircle(this.beamX, this.targetPosition.y, this.wave.beamRadius);
    } else {
      this.hudGraphics.lineStyle(2, 0xd8c88f, 0.38);
      this.hudGraphics.strokeCircle(this.beamX, this.targetPosition.y, this.wave.beamRadius);
    }
    this.hudGraphics.fillStyle(0xd8c88f, 1);
    this.hudGraphics.fillRoundedRect(this.beamX - 20, 594, 40, 20, 6);
    this.hudGraphics.fillStyle(0x25202a, 1);
    this.hudGraphics.fillCircle(this.beamX, 604, 6);

    this.drawPaper(this.targetGraphics, this.targetPosition);
    this.decoyGraphics.clear();
    if (this.decoyPosition) this.drawPaper(this.decoyGraphics, this.decoyPosition);
    this.lockText.setText(this.phase === "preview"
      ? `预览 ${(Math.max(0, this.wave.previewMs - this.previewElapsedMs) / 1_000).toFixed(1)} 秒`
      : this.phase === "transition"
        ? `继续 ${(this.transitionRemainingMs / 1_000).toFixed(1)} 秒`
        : `锁定 ${Math.round(lockRatio * 100)}%`);
    this.batteryText.setText(`照明电量 ${this.batteryCharges} / ${MAX_BATTERY_CHARGES}`);
  }

  private setFeedback(kind: SpotlightFeedback, text: string, color: number): void {
    if (this.feedback === kind && this.cueText.text === text) return;
    this.feedback = kind;
    this.cueText.setText(text).setColor(`#${color.toString(16).padStart(6, "0")}`);
  }

  private drawPaper(graphics: Phaser.GameObjects.Graphics, position: SpotlightPosition): void {
    graphics.clear();
    graphics.fillStyle(0xe5dfd5, 0.96);
    graphics.fillRoundedRect(position.x - 16, position.y - 11, 32, 22, 3);
    graphics.lineStyle(2, 0x8d877e, 0.8);
    graphics.strokeRoundedRect(position.x - 16, position.y - 11, 32, 22, 3);
    graphics.lineStyle(1, 0x9f9990, 0.72);
    graphics.lineBetween(position.x - 10, position.y - 3, position.x + 7, position.y - 3);
    graphics.lineBetween(position.x - 10, position.y + 3, position.x + 9, position.y + 3);
    graphics.lineBetween(position.x + 8, position.y - 9, position.x + 14, position.y - 3);
  }

  private resolvePathPosition(points: readonly EndlessSpotlightPoint[], progress: number): SpotlightPosition {
    if (points.length === 0) return { x: STAGE_CENTER_X, y: STAGE_CENTER_Y };
    if (points.length === 1) return this.toStagePosition(points[0]);
    const segmentProgress = Math.max(0, Math.min(1, progress)) * (points.length - 1);
    const startIndex = Math.min(points.length - 2, Math.floor(segmentProgress));
    const localProgress = segmentProgress - startIndex;
    const start = points[startIndex];
    const end = points[startIndex + 1];
    return this.toStagePosition({
      x: Phaser.Math.Linear(start.x, end.x, localProgress),
      y: Phaser.Math.Linear(start.y, end.y, localProgress),
    });
  }

  private toStagePosition(point: EndlessSpotlightPoint): SpotlightPosition {
    return { x: STAGE_CENTER_X + point.x, y: STAGE_CENTER_Y + point.y };
  }

  private handleKeyboardPress(event: KeyboardEvent): void {
    const key = event.key.toLowerCase();
    if (["arrowleft", "arrowright", " ", "spacebar", "a", "d"].includes(key)) event.preventDefault();
    if (key === "arrowleft" || key === "a") this.handleEndlessControl("left");
    if (key === "arrowright" || key === "d") this.handleEndlessControl("right");
    if ((key === " " || key === "spacebar") && !event.repeat) this.handleEndlessControl("primary");
  }

  private handleKeyboardRelease(event: KeyboardEvent): void {
    const key = event.key.toLowerCase();
    if (["arrowleft", "arrowright", " ", "spacebar", "a", "d"].includes(key)) event.preventDefault();
    if (key === "arrowleft" || key === "a") this.handleEndlessControl("release_left");
    if (key === "arrowright" || key === "d") this.handleEndlessControl("release_right");
    if (key === " " || key === "spacebar") this.handleEndlessControl("release_primary");
  }

  private installInspectionHooks(): void {
    this.previousRenderEndlessSpotlightToText = window.render_endless_spotlight_to_text;
    this.previousAdvanceTime = window.advanceTime;
    const renderEndlessSpotlightToText = () => JSON.stringify({
      coordinateSystem: "390x650 canvas; origin top-left; x right; y down",
      mode: "spotlight",
      phase: this.phase,
      wave: this.waveIndex + 1,
      tier: this.wave?.tier ?? 1,
      score: this.score,
      progress: this.completedWaves,
      combo: this.combo,
      batteryCharges: this.batteryCharges,
      beam: {
        x: Math.round(this.beamX),
        normalizedX: Number(((this.beamX - MIN_BEAM_X) / (MAX_BEAM_X - MIN_BEAM_X)).toFixed(3)),
        on: this.beamOn,
        radius: this.wave?.beamRadius ?? 0,
      },
      routePaper: { x: Math.round(this.targetPosition.x), y: Math.round(this.targetPosition.y) },
      otherPaper: this.decoyPosition
        ? { x: Math.round(this.decoyPosition.x), y: Math.round(this.decoyPosition.y) }
        : null,
      lockMs: Math.round(this.lockMs),
      requiredLockMs: this.wave?.requiredLockMs ?? 0,
      feedback: this.feedback,
      previewRemainingMs: this.phase === "preview"
        ? Math.max(0, Math.round((this.wave?.previewMs ?? 0) - this.previewElapsedMs))
        : 0,
      transitionRemainingMs: this.phase === "transition" ? Math.round(this.transitionRemainingMs) : 0,
      remainingMs: Math.max(0, Math.round((this.wave?.actionMs ?? 0) - this.waveElapsedMs)),
      ended: this.ended,
    });
    const advanceTime = (milliseconds: number) => {
      let remaining = Math.max(0, Math.min(60_000, milliseconds));
      while (remaining > 0 && !this.ended) {
        const step = Math.min(1000 / 60, remaining);
        this.advanceSimulation(step);
        remaining -= step;
      }
    };
    window.render_endless_spotlight_to_text = renderEndlessSpotlightToText;
    window.advanceTime = advanceTime;
  }

  private destroyScene(): void {
    if (this.cleanupComplete) return;
    this.cleanupComplete = true;
    this.releaseEndlessControls();
    this.input.keyboard?.off("keydown", this.keyboardDown);
    this.input.keyboard?.off("keyup", this.keyboardUp);
    if (this.previousRenderEndlessSpotlightToText) {
      window.render_endless_spotlight_to_text = this.previousRenderEndlessSpotlightToText;
    } else {
      delete window.render_endless_spotlight_to_text;
    }
    if (this.previousAdvanceTime) window.advanceTime = this.previousAdvanceTime;
    else delete window.advanceTime;
  }
}
