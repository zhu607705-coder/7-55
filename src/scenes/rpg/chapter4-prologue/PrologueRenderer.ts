import { PrologueVisualAssets } from "./PrologueVisualAssets";
import {
  FINALE_NPC_ANIMATIONS,
  type FinaleNpcAnimationId
} from "../FinaleNpcTextures";
import { PROLOGUE_PHASES, prologuePhaseAt, type ProloguePhaseId } from "./PrologueTimeline";

/**
 * 第四章序幕「纸条进入段永平教学楼」的 canvas 像素渲染器。
 * 纯表现层：按过场毫秒数绘制六个分镜，不读写任何剧情状态。
 * 分镜：0–4.2s 磁扣断裂；4.2–12.4s 离开湖面；12.4–24.4s 拱廊穿行；
 * 24.4–32.4s 学生推门；32.4–44.2s 门厅湿地；44.2s– 清楼关灯。
 */

const LOGICAL_WIDTH = 960;
const LOGICAL_HEIGHT = 540;
const BUFFER_MIN_WIDTH = 480;
const BUFFER_MAX_WIDTH = 960;
const SCENE_TRANSITION_MS = 1100;
const ENVIRONMENT_FRAME_MS = 4200;

const COLORS = {
  skyTop: "#173e69",
  skyMid: "#236895",
  skyHorizon: "#59a7c8",
  moon: "#e9ecd8",
  moonShade: "#c9cfae",
  star: "#aab6d8",
  water: "#176b91",
  waterMid: "#2586aa",
  waterLight: "#54b2c9",
  moonStreak: "#5f7896",
  ripple: "#7d97bd",
  stone: "#252b37",
  stoneDark: "#1b202a",
  stoneLight: "#3a4354",
  railing: "#4b5a74",
  railingLight: "#6d7fa0",
  building: "#10151f",
  buildingFace: "#1a2230",
  windowLit: "#f2cf7e",
  windowWarm: "#e8b95e",
  windowDark: "#1f2c42",
  paper: "#f1ead2",
  paperWet: "#cfc39f",
  paperLine: "#7c8aa0",
  paperFold: "#b5a87e",
  clasp: "#9fb4c8",
  claspCrack: "#ffe9a8",
  flash: "#fff6d8",
  lamp: "#f0b95e",
  lampGlow: "#8a6420",
  lobbyFloor: "#2b3241",
  lobbyTile: "#394354",
  wetBand: "#3d5a78",
  wetShine: "#7fa6c8",
  wall: "#1c2431",
  wallPanel: "#28324a",
  doorGlass: "#27435c",
  doorGlassLit: "#3f6c8f",
  doorFrame: "#5a6a80",
  clockDigit: "#7fe0a8",
  signYellow: "#e8c84a",
  cautionInk: "#2a2416",
  skin: "#dda868",
  skinShade: "#c08c50",
  studentCoat: "#3d5a80",
  studentPants: "#2b303c",
  cleanerCoat: "#4a7d6e",
  cleanerPants: "#33424a",
  guardCoat: "#3a4664",
  guardPants: "#272d3a",
  hair: "#241c14",
  phoneGlow: "#bfe3ff",
  flashlight: "#ffe9a8",
  speaker: "#39435a",
  ceilingLamp: "#f2d89a",
  corridorWall: "#202839",
  corridorFloor: "#262d3b",
  windStreak: "#6d82a8",
  windGlow: "#73c9e5",
  windCore: "#d8f7ff",
  droplet: "#9fc3e8"
} as const;

function clamp01(value: number): number {
  return Math.max(0, Math.min(1, value));
}

function lerp(a: number, b: number, t: number): number {
  return a + (b - a) * t;
}

function easeOut(t: number): number {
  return 1 - (1 - t) * (1 - t);
}

function easeInOut(t: number): number {
  return t < 0.5 ? 2 * t * t : 1 - (-2 * t + 2) ** 2 / 2;
}

/** 确定性伪随机，保证每帧火花/水滴位置可复现。 */
function pseudo(seed: number): number {
  const value = Math.sin(seed * 12.9898) * 43758.5453;
  return value - Math.floor(value);
}

interface PaperPose {
  x: number;
  y: number;
  groundY?: number;
  angle: number;
  flipT: number;
  darken: number;
  shine: number;
  foldEmphasis: number;
  scale: number;
  airborne?: number;
}

export class PrologueRenderer {
  private readonly canvas: HTMLCanvasElement;
  private readonly ctx: CanvasRenderingContext2D;
  private readonly observer: ResizeObserver;
  private scale = 0.5;
  private reducedMotion = false;
  private readonly visualAssets = new PrologueVisualAssets();

  constructor(canvas: HTMLCanvasElement) {
    this.canvas = canvas;
    const ctx = canvas.getContext("2d");
    if (!ctx) throw new Error("PrologueRenderer requires a 2D canvas context");
    this.ctx = ctx;
    this.observer = new ResizeObserver(() => this.handleResize());
    this.observer.observe(canvas);
    this.handleResize();
  }

  destroy(): void {
    this.observer.disconnect();
  }

  setReducedMotion(reduced: boolean): void {
    this.reducedMotion = reduced;
  }

  render(elapsedMs: number): void {
    const ctx = this.ctx;
    ctx.imageSmoothingEnabled = false;
    ctx.setTransform(this.scale, 0, 0, this.scale, 0, 0);
    ctx.globalAlpha = 1;
    const phase = prologuePhaseAt(elapsedMs);
    const plateDrawn = this.drawScenePlate(ctx, phase.id, phase.localMs);
    if (plateDrawn) this.drawPlateForeground(ctx, phase.id, phase.localMs, phase.durationMs);
    else this.drawPhase(ctx, phase.id, phase.localMs, phase.durationMs);
    ctx.globalAlpha = 1;
  }

  private drawScenePlate(ctx: CanvasRenderingContext2D, id: ProloguePhaseId, localMs: number): boolean {
    const current = this.visualAssets.getFrame(id, false);
    if (!current) return false;

    const phaseIndex = PROLOGUE_PHASES.findIndex((phase) => phase.id === id);
    const previousId = phaseIndex > 0 ? PROLOGUE_PHASES[phaseIndex - 1].id : null;
    const previous = previousId ? this.visualAssets.getFrame(previousId, false) : null;
    const transitionProgress = clamp01(localMs / SCENE_TRANSITION_MS);
    if (!previous || transitionProgress >= 1 || this.reducedMotion) {
      this.drawImageCover(ctx, current);
    } else {
      this.drawSceneTransition(ctx, previous, current, id, easeInOut(transitionProgress));
    }

    const alternate = this.visualAssets.getFrame(id, true);
    if (alternate && !this.reducedMotion && transitionProgress >= 1) {
      const cycle = (localMs - SCENE_TRANSITION_MS) / ENVIRONMENT_FRAME_MS;
      const blend = 0.08 + (Math.sin(cycle * Math.PI * 2 - Math.PI / 2) + 1) * 0.08;
      ctx.globalAlpha = blend;
      this.drawImageCover(ctx, alternate);
      ctx.globalAlpha = 1;
    }
    return true;
  }

  private drawImageCover(ctx: CanvasRenderingContext2D, image: HTMLImageElement): void {
    const sourceRatio = image.naturalWidth / image.naturalHeight;
    const targetRatio = LOGICAL_WIDTH / LOGICAL_HEIGHT;
    let sx = 0;
    let sy = 0;
    let sw = image.naturalWidth;
    let sh = image.naturalHeight;
    if (sourceRatio > targetRatio) {
      sw = Math.round(sh * targetRatio);
      sx = Math.round((image.naturalWidth - sw) / 2);
    } else if (sourceRatio < targetRatio) {
      sh = Math.round(sw / targetRatio);
      sy = Math.round((image.naturalHeight - sh) / 2);
    }
    ctx.drawImage(image, sx, sy, sw, sh, 0, 0, LOGICAL_WIDTH, LOGICAL_HEIGHT);
  }

  private drawImageCoverTransformed(
    ctx: CanvasRenderingContext2D,
    image: HTMLImageElement,
    scale: number,
    translateX = 0,
    translateY = 0,
    centerX = LOGICAL_WIDTH / 2,
    centerY = LOGICAL_HEIGHT / 2
  ): void {
    ctx.save();
    ctx.translate(centerX + translateX, centerY + translateY);
    ctx.scale(scale, scale);
    ctx.translate(-centerX, -centerY);
    this.drawImageCover(ctx, image);
    ctx.restore();
  }

  /**
   * 场景衔接由画面内的纸条、石柱和门完成遮挡，避免整幅环境图直接换页。
   * 每段衔接都保留同一运动方向，前一镜的出口对应后一镜的入口。
   */
  private drawSceneTransition(
    ctx: CanvasRenderingContext2D,
    previous: HTMLImageElement,
    current: HTMLImageElement,
    id: ProloguePhaseId,
    progress: number
  ): void {
    if (id === "lake_exit") {
      this.drawImageCoverTransformed(ctx, previous, lerp(1, 1.18, progress), 0, 0, 484, 396);
      ctx.save();
      ctx.beginPath();
      ctx.arc(484, 396, lerp(12, 740, easeOut(progress)), 0, Math.PI * 2);
      ctx.clip();
      this.drawImageCoverTransformed(ctx, current, lerp(1.08, 1, progress), 0, 0, 484, 396);
      ctx.restore();
      ctx.globalAlpha = 0.72 * (1 - progress);
      strokePixelEllipse(ctx, 484, 402, 24 + progress * 120, 7 + progress * 26, 4, "#d3f6ff");
      ctx.globalAlpha = 1;
      return;
    }

    if (id === "arcade") {
      this.drawImageCover(ctx, current);
      const pillarX = lerp(LOGICAL_WIDTH + 96, -128, progress);
      ctx.save();
      ctx.beginPath();
      ctx.rect(0, 0, Math.max(0, pillarX + 24), LOGICAL_HEIGHT);
      ctx.clip();
      this.drawImageCoverTransformed(ctx, previous, 1, -progress * 72);
      ctx.restore();
      this.drawPassingPillar(ctx, pillarX, 112);
      return;
    }

    if (id === "entrance") {
      this.drawImageCoverTransformed(ctx, previous, lerp(1, 1.22, progress), -progress * 46, 0, 860, 330);
      const apertureWidth = lerp(20, LOGICAL_WIDTH + 160, easeOut(progress));
      const apertureHeight = lerp(110, LOGICAL_HEIGHT + 80, easeOut(progress));
      ctx.save();
      ctx.beginPath();
      ctx.rect(860 - apertureWidth / 2, 330 - apertureHeight / 2, apertureWidth, apertureHeight);
      ctx.clip();
      this.drawImageCoverTransformed(ctx, current, lerp(1.12, 1, progress), 0, 0, 520, 330);
      ctx.restore();
      ctx.globalAlpha = 0.72 * (1 - progress);
      ctx.strokeStyle = "#ffe5a4";
      ctx.lineWidth = 8;
      ctx.strokeRect(860 - apertureWidth / 2, 330 - apertureHeight / 2, apertureWidth, apertureHeight);
      ctx.globalAlpha = 1;
      return;
    }

    if (id === "lobby") {
      this.drawImageCover(ctx, current);
      const opening = easeOut(progress) * (LOGICAL_WIDTH / 2 + 16);
      ctx.save();
      ctx.beginPath();
      ctx.rect(0, 0, Math.max(0, LOGICAL_WIDTH / 2 - opening), LOGICAL_HEIGHT);
      ctx.rect(LOGICAL_WIDTH / 2 + opening, 0, Math.max(0, LOGICAL_WIDTH / 2 - opening), LOGICAL_HEIGHT);
      ctx.clip();
      this.drawImageCover(ctx, previous);
      ctx.restore();
      const leftDoorX = LOGICAL_WIDTH / 2 - opening;
      const rightDoorX = LOGICAL_WIDTH / 2 + opening;
      this.drawSlidingGlassDoor(ctx, leftDoorX, rightDoorX, 1 - progress);
      return;
    }

    this.drawImageCover(ctx, current);
    const wallX = lerp(LOGICAL_WIDTH + 160, -160, easeInOut(progress));
    ctx.save();
    ctx.beginPath();
    ctx.rect(0, 0, Math.max(0, wallX), LOGICAL_HEIGHT);
    ctx.clip();
    this.drawImageCoverTransformed(ctx, previous, 1, -progress * 54);
    ctx.restore();
    this.drawPassingWall(ctx, wallX);
  }

  private drawPassingPillar(ctx: CanvasRenderingContext2D, x: number, width: number): void {
    ctx.fillStyle = "#26313c";
    ctx.fillRect(Math.round(x), 0, width, LOGICAL_HEIGHT);
    ctx.fillStyle = "#8797a3";
    ctx.fillRect(Math.round(x), 0, 10, LOGICAL_HEIGHT);
    ctx.fillStyle = "#151d25";
    ctx.fillRect(Math.round(x + width - 14), 0, 14, LOGICAL_HEIGHT);
    for (let y = 28; y < LOGICAL_HEIGHT; y += 44) {
      ctx.fillStyle = "#42505b";
      ctx.fillRect(Math.round(x + 12), y, width - 28, 3);
    }
  }

  private drawSlidingGlassDoor(
    ctx: CanvasRenderingContext2D,
    leftDoorX: number,
    rightDoorX: number,
    opacity: number
  ): void {
    ctx.globalAlpha = opacity * 0.72;
    ctx.fillStyle = "#76aec4";
    ctx.fillRect(Math.round(leftDoorX - 82), 64, 82, 412);
    ctx.fillRect(Math.round(rightDoorX), 64, 82, 412);
    ctx.globalAlpha = 1;
    ctx.fillStyle = "#d7e7df";
    ctx.fillRect(Math.round(leftDoorX - 8), 54, 8, 432);
    ctx.fillRect(Math.round(rightDoorX), 54, 8, 432);
  }

  private drawPassingWall(ctx: CanvasRenderingContext2D, x: number): void {
    ctx.fillStyle = "#172333";
    ctx.fillRect(Math.round(x), 0, 148, LOGICAL_HEIGHT);
    ctx.fillStyle = "#4b6071";
    ctx.fillRect(Math.round(x), 0, 10, LOGICAL_HEIGHT);
    ctx.fillStyle = "#0d1620";
    ctx.fillRect(Math.round(x + 132), 0, 16, LOGICAL_HEIGHT);
    ctx.fillStyle = "#b7d3d4";
    ctx.fillRect(Math.round(x + 24), 80, 86, 8);
  }

  private drawPhase(ctx: CanvasRenderingContext2D, id: ProloguePhaseId, localMs: number, durationMs: number): void {
    if (id === "snap") this.drawSnap(ctx, localMs);
    else if (id === "lake_exit") this.drawLakeExit(ctx, localMs);
    else if (id === "arcade") this.drawArcade(ctx, localMs);
    else if (id === "entrance") this.drawEntrance(ctx, localMs);
    else if (id === "lobby") this.drawLobby(ctx, localMs);
    else this.drawClosing(ctx, localMs, durationMs);
  }

  private drawPlateForeground(
    ctx: CanvasRenderingContext2D,
    id: ProloguePhaseId,
    localMs: number,
    durationMs: number
  ): void {
    if (id === "snap") this.drawPlateSnap(ctx, localMs);
    else if (id === "lake_exit") this.drawPlateLakeExit(ctx, localMs, durationMs);
    else if (id === "arcade") this.drawPlateArcade(ctx, localMs, durationMs);
    else if (id === "entrance") this.drawPlateEntrance(ctx, localMs, durationMs);
    else if (id === "lobby") this.drawPlateLobby(ctx, localMs, durationMs);
    else this.drawPlateClosing(ctx, localMs, durationMs);
  }

  private drawPlateSnap(ctx: CanvasRenderingContext2D, t: number): void {
    const snapped = t >= 2100;
    const tension = clamp01((t - 200) / 1900);
    const tremble = this.reducedMotion ? 0 : Math.sin(t / 36) * (1 + tension * 3);
    const claspX = 474;
    const claspY = 322;

    ctx.strokeStyle = "#d8f1f4";
    ctx.lineWidth = 3;
    ctx.beginPath();
    ctx.moveTo(44, 92);
    if (!snapped) ctx.quadraticCurveTo(256, 170 + tremble, claspX + tremble, claspY);
    else ctx.quadraticCurveTo(230, 132, lerp(claspX, 84, easeOut(clamp01((t - 2100) / 700))), 92);
    ctx.stroke();

    if (!snapped) {
      ctx.fillStyle = COLORS.clasp;
      ctx.fillRect(Math.round(claspX - 12 + tremble), claspY - 8, 24, 16);
      ctx.fillStyle = COLORS.claspCrack;
      for (let index = 0; index < Math.min(4, Math.floor(tension * 5)); index += 1) {
        ctx.fillRect(Math.round(claspX - 8 + index * 5 + tremble), claspY - 7 + (index % 2) * 4, 2, 10);
      }
    } else {
      const split = easeOut(clamp01((t - 2100) / 700));
      ctx.fillStyle = COLORS.clasp;
      ctx.fillRect(Math.round(claspX - 12 - split * 28), Math.round(claspY - 8 - split * 12), 10, 16);
      ctx.fillRect(Math.round(claspX + 2 + split * 30), Math.round(claspY - 8 + split * 10), 10, 16);
      const flash = clamp01(1 - (t - 2100) / 320);
      if (flash > 0) {
        ctx.globalAlpha = flash * 0.72;
        fillPixelCircle(ctx, claspX, claspY, Math.round(12 + (1 - flash) * 28), COLORS.flash);
        ctx.globalAlpha = 1;
      }
    }

    if (t >= 3200) {
      const rippleT = clamp01((t - 3200) / 1000);
      ctx.globalAlpha = 1 - rippleT;
      strokePixelEllipse(ctx, 484, 402, 18 + rippleT * 68, 5 + rippleT * 16, 3, "#c8f3ff");
      ctx.globalAlpha = 1;
    }
    this.drawPaper(ctx, {
      x: 484,
      y: 396,
      angle: this.reducedMotion ? 0 : Math.sin(t / 530) * 0.05,
      flipT: 0,
      darken: 0,
      shine: 0.72,
      foldEmphasis: t >= 3400 ? 0.72 : 0.2,
      scale: 1.28
    }, t);
  }

  private drawPlateLakeExit(ctx: CanvasRenderingContext2D, t: number, durationMs: number): void {
    const activeMs = Math.max(0, t - SCENE_TRANSITION_MS * 0.55);
    const travel = easeInOut(clamp01(activeMs / Math.max(1, durationMs - SCENE_TRANSITION_MS * 0.55)));
    const lift = t > 3300 && t < 4700 ? Math.sin(((t - 3300) / 1400) * Math.PI) : 0;
    const climb = easeOut(clamp01((t - 900) / 2600));
    const x = lerp(484, 930, travel);
    const y = lerp(362, 270, climb) - lift * 30 + (this.reducedMotion ? 0 : Math.sin(t / 230) * 5);
    this.drawWindWake(ctx, x, y, t, 0.74 + lift * 0.26, 1.04 + lift * 0.18);
    this.drawPaper(ctx, {
      x,
      y,
      groundY: 420,
      angle: 0.04 + lift * 0.48,
      flipT: lift,
      darken: 0,
      shine: 0.78,
      foldEmphasis: 0.34 + lift * 0.5,
      scale: 1.18,
      airborne: 0.58 + climb * 0.32 + lift * 0.08
    }, t);
  }

  private drawPlateArcade(ctx: CanvasRenderingContext2D, t: number, durationMs: number): void {
    if (t < 720) return;
    const activeMs = t - 720;
    const travel = easeInOut(clamp01(activeMs / Math.max(1, durationMs - 720)));
    const x = lerp(32, 930, travel);
    const stepFold = t > 6500 && t < 7600 ? Math.sin(((t - 6500) / 1100) * Math.PI) : 0;
    const y = 272 + (this.reducedMotion ? 0 : Math.sin(t / 260) * 9) - stepFold * 24;
    if (!this.reducedMotion && t > 1500) {
      ctx.fillStyle = COLORS.windGlow;
      ctx.globalAlpha = 0.52;
      for (let index = 0; index < 7; index += 1) {
        const streakX = Math.round(((index * 176 - t * 0.68) % 1080 + 1080) % 1080 - 60);
        const streakY = 204 + index * 20;
        ctx.fillRect(streakX, streakY, 22, 2);
        ctx.fillRect(streakX + 32, streakY + (index % 2 === 0 ? 2 : -2), 12, 2);
        ctx.fillRect(streakX + 52, streakY, 7, 2);
      }
      ctx.globalAlpha = 1;
    }
    this.drawWindWake(ctx, x, y, t, 0.92, 1.28);
    this.drawPaper(ctx, {
      x,
      y,
      groundY: 456,
      angle: (this.reducedMotion ? 0.03 : Math.sin(t / 280) * 0.1) + stepFold * 0.42,
      flipT: 0,
      darken: 0,
      shine: 0.86,
      foldEmphasis: 0.34 + stepFold * 0.6,
      scale: 1.16,
      airborne: 0.82
    }, t);
  }

  private drawPlateEntrance(ctx: CanvasRenderingContext2D, t: number, durationMs: number): void {
    if (t < 560) return;
    let studentX = 818;
    let studentAnimation: FinaleNpcAnimationId = "student_walk";
    let studentAnimationMs = t;
    let studentOpacity = 1;
    if (t < 1200) {
      studentX = lerp(836, 688, easeInOut(t / 1200));
    } else if (t < 2200) {
      studentX = 688;
      studentAnimation = "student_phone_glance";
      studentAnimationMs = t - 1200;
    } else if (t < 3000) {
      studentX = lerp(688, 640, easeInOut((t - 2200) / 800));
      studentAnimation = "student_adjust_bag";
      studentAnimationMs = t - 2200;
    } else if (t < 4800) {
      studentX = lerp(640, 548, easeInOut((t - 3000) / 1800));
      studentAnimation = "student_push_door";
      studentAnimationMs = t - 3000;
    } else {
      studentX = lerp(548, 514, clamp01((t - 4800) / 1000));
      studentAnimation = "student_walk";
      studentAnimationMs = t - 4800;
      studentOpacity = 1 - clamp01((t - 5200) / 700);
    }
    if (studentOpacity > 0) {
      const rendered = this.drawNpcAnimation(
        ctx,
        studentAnimation,
        studentX,
        482,
        studentAnimationMs,
        0.82,
        true,
        studentOpacity
      );
      if (!rendered) {
        this.drawPerson(ctx, studentX, 470, COLORS.studentCoat, COLORS.studentPants, "push", -1, t);
      }
    }
    const paperProgress = easeInOut(clamp01(t / Math.max(1, durationMs - 1700)));
    const suction = t > 3000 ? Math.sin(clamp01((t - 3000) / 1800) * Math.PI) : 0;
    const paperX = lerp(30, 518, paperProgress);
    const paperY = lerp(316, 272, paperProgress) - suction * 34;
    this.drawWindWake(ctx, paperX, paperY, t, 0.82 + suction * 0.18, 1.12);
    this.drawPaper(ctx, {
      x: paperX,
      y: paperY,
      groundY: 470,
      angle: suction * 0.16,
      flipT: 0,
      darken: 0,
      shine: 0.7,
      foldEmphasis: 0.38,
      scale: 1.14,
      airborne: 0.7 + suction * 0.24
    }, t);
  }

  private drawPlateLobby(ctx: CanvasRenderingContext2D, t: number, durationMs: number): void {
    if (t < 820) return;
    const activeMs = t - 820;
    const travel = easeInOut(clamp01(activeMs / Math.max(1, durationMs - 820)));
    const paperX = lerp(472, 918, travel);
    const climb = easeOut(clamp01((t - 1050) / 1700));
    const paperY = lerp(374, 268, climb) - travel * 18 + (this.reducedMotion ? 0 : Math.sin(t / 230) * 5);
    this.drawWindWake(ctx, paperX, paperY, t, 0.66, 0.96);
    let cleanerAnimation: FinaleNpcAnimationId = "cleaner_mop";
    let cleanerX = 286;
    let cleanerAnimationMs = t;
    if (t >= 1800 && t < 3200) {
      cleanerAnimation = "cleaner_idle";
      cleanerAnimationMs = t - 1800;
    } else if (t >= 3200) {
      cleanerAnimation = "cleaner_push_cart";
      cleanerX = Math.max(286, Math.min(744, paperX - 172));
      cleanerAnimationMs = t - 3200;
    }
    if (!this.drawNpcAnimation(ctx, cleanerAnimation, cleanerX, 478, cleanerAnimationMs, 0.78, false)) {
      this.drawPerson(ctx, cleanerX, 458, COLORS.cleanerCoat, COLORS.cleanerPants, t >= 3200 ? "push" : "mop", 1, t);
    }
    this.drawPaper(ctx, {
      x: paperX,
      y: paperY,
      groundY: 468,
      angle: this.reducedMotion ? 0.03 : Math.sin(t / 250) * 0.06,
      flipT: 0,
      darken: 0,
      shine: 0.9,
      foldEmphasis: 0.4,
      scale: 1.16,
      airborne: 0.68 + climb * 0.3
    }, t);
  }

  private drawPlateClosing(ctx: CanvasRenderingContext2D, t: number, durationMs: number): void {
    if (t < 820) return;
    const lightOut = clamp01((t - 5600) / 1200);
    if (lightOut > 0) {
      ctx.globalAlpha = lightOut * 0.16;
      ctx.fillStyle = "#143554";
      for (let x = 0; x < LOGICAL_WIDTH; x += 96) {
        if ((x / 96) % 2 === 0 || lightOut > 0.65) ctx.fillRect(x, 0, 96, LOGICAL_HEIGHT);
      }
      ctx.globalAlpha = 1;
    }
    let guardAnimation: FinaleNpcAnimationId = "guard_walk";
    let guardAnimationMs = t;
    let guardX = lerp(888, 802, easeInOut(clamp01(t / 1300)));
    if (t >= 1300 && t < 2500) {
      guardAnimation = "guard_check_watch";
      guardAnimationMs = t - 1300;
      guardX = 802;
    } else if (t >= 2500 && t < 4800) {
      guardAnimation = "guard_flashlight_down";
      guardAnimationMs = t - 2500;
      guardX = 802;
    } else if (t >= 4800) {
      guardAnimation = "guard_radio";
      guardAnimationMs = t - 4800;
      guardX = 802;
    }
    if (!this.drawNpcAnimation(ctx, guardAnimation, guardX, 490, guardAnimationMs, 0.82, true)) {
      this.drawPerson(ctx, guardX, 472, COLORS.guardCoat, COLORS.guardPants, "flashlight", -1, t);
    }
    if (t >= 2500 && t < 5000) {
      ctx.globalAlpha = 0.18;
      ctx.fillStyle = COLORS.flashlight;
      ctx.beginPath();
      ctx.moveTo(768, 420);
      ctx.lineTo(644, 438);
      ctx.lineTo(644, 482);
      ctx.closePath();
      ctx.fill();
      ctx.globalAlpha = 1;
    }
    if (t >= 5000) {
      this.drawNpcAnimation(ctx, "cleaner_toggle_lights", 150, 476, t - 5000, 0.76, false);
    }
    const paperX = lerp(64, 690, easeInOut(clamp01(t / durationMs)));
    const paperY = 268 + (this.reducedMotion ? 0 : Math.sin(t / 220) * 10);
    this.drawWindWake(ctx, paperX, paperY, t, 0.72, 1.08);
    this.drawPaper(ctx, {
      x: paperX,
      y: paperY,
      groundY: 472,
      angle: 0.04,
      flipT: 0,
      darken: lightOut * 0.18,
      shine: 0.72 - lightOut * 0.22,
      foldEmphasis: 0.34,
      scale: 1.14,
      airborne: 0.76
    }, t);
  }

  /* ---------------------------------- 共用 ---------------------------------- */

  private drawNightSky(ctx: CanvasRenderingContext2D, horizonY: number): void {
    const gradient = ctx.createLinearGradient(0, 0, 0, horizonY);
    gradient.addColorStop(0, COLORS.skyTop);
    gradient.addColorStop(0.7, COLORS.skyMid);
    gradient.addColorStop(1, COLORS.skyHorizon);
    ctx.fillStyle = gradient;
    ctx.fillRect(0, 0, LOGICAL_WIDTH, horizonY);
    for (let index = 0; index < 26; index += 1) {
      const x = Math.floor(pseudo(index + 3) * LOGICAL_WIDTH);
      const y = Math.floor(pseudo(index + 41) * (horizonY - 40));
      ctx.fillStyle = pseudo(index + 77) > 0.6 ? COLORS.star : COLORS.skyHorizon;
      ctx.fillRect(x, y, 2, 2);
    }
    fillPixelCircle(ctx, 800, 74, 24, COLORS.moon);
    fillPixelCircle(ctx, 792, 68, 6, COLORS.moonShade);
    fillPixelCircle(ctx, 808, 82, 4, COLORS.moonShade);
  }

  private drawWater(ctx: CanvasRenderingContext2D, top: number, width: number, shimmerSeed: number): void {
    ctx.fillStyle = COLORS.water;
    ctx.fillRect(0, top, width, LOGICAL_HEIGHT - top);
    ctx.fillStyle = COLORS.waterMid;
    for (let y = top + 8; y < LOGICAL_HEIGHT; y += 18) {
      const drift = Math.floor(pseudo(y + shimmerSeed) * 30);
      for (let x = -20; x < width; x += 90) {
        ctx.fillRect(x + drift, y, 46, 2);
      }
    }
    ctx.fillStyle = COLORS.waterLight;
    for (let y = top + 16; y < LOGICAL_HEIGHT; y += 36) {
      const drift = Math.floor(pseudo(y * 3 + shimmerSeed) * 50);
      for (let x = -30; x < width; x += 140) {
        ctx.fillRect(x + drift, y, 24, 2);
      }
    }
    // 月光水痕
    ctx.fillStyle = COLORS.moonStreak;
    for (let index = 0; index < 8; index += 1) {
      const y = top + 18 + index * 16;
      const w = 34 - index * 3;
      if (w > 4 && 780 < width) ctx.fillRect(780 - w, y, w * 2, 3);
    }
  }

  private drawPaper(ctx: CanvasRenderingContext2D, pose: PaperPose, timeMs: number): void {
    const flutter = this.reducedMotion ? 0 : Math.sin(timeMs / 170) * 1.6;
    const airborne = clamp01(pose.airborne ?? 0);
    const frame = this.reducedMotion
      ? 0
      : Math.floor(timeMs / 145 + clamp01(pose.foldEmphasis) * 3) % 5;
    const paperFrame = this.visualAssets.getPaperFrame(frame);
    const shadowY = pose.groundY ?? pose.y + 18 + airborne * 38;
    ctx.save();
    ctx.translate(Math.round(pose.x), Math.round(shadowY));
    ctx.globalAlpha = lerp(0.24, 0.06, airborne);
    ctx.fillStyle = "#102131";
    ctx.fillRect(-15, 0, 9, 2);
    ctx.fillRect(-2, 0, 13, 2);
    if (airborne < 0.58) ctx.fillRect(-8, 3, 14, 2);
    ctx.restore();
    ctx.save();
    ctx.translate(Math.round(pose.x), Math.round(pose.y + flutter * 0.4));
    ctx.rotate(pose.angle + flutter * 0.012);
    ctx.scale(pose.scale, pose.scale * Math.max(0.18, Math.abs(Math.cos(pose.flipT * Math.PI))));
    if (paperFrame) {
      ctx.drawImage(paperFrame, -28, -28, 56, 56);
      if (pose.darken > 0) {
        ctx.globalCompositeOperation = "source-atop";
        ctx.globalAlpha = clamp01(pose.darken * 0.72);
        ctx.fillStyle = "#253547";
        ctx.fillRect(-24, -25, 48, 50);
        ctx.globalCompositeOperation = "source-over";
        ctx.globalAlpha = 1;
      }
    } else {
      const body = mixToward(COLORS.paper, COLORS.paperWet, 0.55);
      const shade = pose.darken > 0 ? mixToward(body, "#39414f", pose.darken) : body;
      ctx.fillStyle = "#514833";
      ctx.fillRect(-18, -13, 36, 26);
      ctx.fillStyle = shade;
      ctx.fillRect(-16, -12, 32, 24);
      ctx.fillRect(-18, -8, 2, 15);
      ctx.fillRect(16, -4, 2, 12);
      const foldLift = pose.foldEmphasis > 0 ? Math.round(4 + pose.foldEmphasis * 5) : 3;
      ctx.fillStyle = pose.darken > 0 ? mixToward(COLORS.paperFold, "#39414f", pose.darken) : COLORS.paperFold;
      ctx.beginPath();
      ctx.moveTo(16, -12);
      ctx.lineTo(16 - foldLift * 2, -12);
      ctx.lineTo(16, -12 + foldLift * 2);
      ctx.closePath();
      ctx.fill();
      ctx.fillStyle = COLORS.paperLine;
      ctx.fillRect(-10, -5, 15, 2);
      ctx.fillRect(-10, 0, 20, 2);
      ctx.fillRect(-10, 5, 12, 2);
      ctx.fillStyle = COLORS.paperWet;
      ctx.fillRect(-16, 7, 32, 5);
    }
    if (pose.shine > 0) {
      ctx.globalAlpha = pose.shine * 0.72;
      ctx.fillStyle = COLORS.wetShine;
      ctx.fillRect(-17, -17, 13, 3);
      ctx.fillRect(7, -11, 8, 3);
      ctx.fillRect(-12, 13, 20, 3);
      ctx.fillRect(20, -3, 3, 7);
      ctx.globalAlpha = 1;
    }
    ctx.restore();
  }

  private drawWindWake(
    ctx: CanvasRenderingContext2D,
    x: number,
    y: number,
    timeMs: number,
    intensity = 1,
    lengthScale = 1
  ): void {
    const strength = clamp01(intensity);
    const motion = this.reducedMotion ? 0 : timeMs * 0.07;
    ctx.save();
    for (let lane = 0; lane < 4; lane += 1) {
      const drift = (motion + lane * 17) % 28;
      const wave = this.reducedMotion ? 0 : Math.sin(timeMs / 220 + lane * 1.1) * 4;
      const laneY = y - 20 + lane * 13 + wave;
      for (let segment = 0; segment < 5; segment += 1) {
        const gap = Math.round((15 + lane * 2) * lengthScale);
        const segmentX = x - 36 - lane * 8 - drift - segment * gap;
        const segmentY = laneY + (segment % 3 === 1 ? 2 : 0);
        const segmentWidth = Math.max(4, Math.round((13 - segment * 1.8) * lengthScale));
        ctx.globalAlpha = strength * (0.82 - segment * 0.11);
        ctx.fillStyle = (lane + segment) % 2 === 0 ? COLORS.windCore : COLORS.windGlow;
        ctx.fillRect(Math.round(segmentX), Math.round(segmentY), segmentWidth, segment === 0 ? 3 : 2);
      }
    }
    for (let index = 0; index < 5; index += 1) {
      const particleX = x - 24 - ((motion * 1.8 + index * 29) % 112);
      const particleY = y - 18 + index * 10 + (this.reducedMotion ? 0 : Math.sin(timeMs / 170 + index) * 5);
      ctx.globalAlpha = strength * (0.76 - index * 0.08);
      ctx.fillStyle = index % 2 === 0 ? COLORS.windCore : COLORS.windGlow;
      const size = index % 3 === 0 ? 3 : 2;
      ctx.fillRect(Math.round(particleX), Math.round(particleY), size, size);
    }
    ctx.restore();
  }

  private drawDroplet(ctx: CanvasRenderingContext2D, x: number, y: number, alpha: number): void {
    ctx.globalAlpha = clamp01(alpha);
    ctx.fillStyle = COLORS.droplet;
    ctx.fillRect(Math.round(x), Math.round(y), 2, 3);
    ctx.globalAlpha = 1;
  }

  private drawNpcAnimation(
    ctx: CanvasRenderingContext2D,
    id: FinaleNpcAnimationId,
    x: number,
    groundY: number,
    animationMs: number,
    scale: number,
    mirror = false,
    opacity = 1
  ): boolean {
    const asset = FINALE_NPC_ANIMATIONS[id];
    const image = this.visualAssets.getImage(asset.url);
    if (!image) return false;
    const frameDurationMs = 1000 / Math.max(1, asset.fps);
    const rawFrame = Math.floor(Math.max(0, animationMs) / frameDurationMs);
    const frame = asset.loop
      ? rawFrame % asset.frameCount
      : Math.min(asset.frameCount - 1, rawFrame);
    const width = Math.round(asset.frameWidth * scale);
    const height = Math.round(asset.frameHeight * scale);
    ctx.save();
    ctx.globalAlpha = opacity;
    ctx.translate(Math.round(x), Math.round(groundY));
    ctx.scale(mirror ? -1 : 1, 1);
    ctx.drawImage(
      image,
      frame * asset.frameWidth,
      0,
      asset.frameWidth,
      asset.frameHeight,
      Math.round(-width * asset.footAnchor.x),
      Math.round(-height * asset.footAnchor.y),
      width,
      height
    );
    ctx.restore();
    return true;
  }

  private drawPerson(
    ctx: CanvasRenderingContext2D,
    x: number,
    groundY: number,
    coat: string,
    pants: string,
    pose: "phone" | "push" | "mop" | "idle" | "flashlight",
    facing: -1 | 1,
    timeMs: number
  ): void {
    const bob = this.reducedMotion ? 0 : Math.round(Math.sin(timeMs / 260) * 1);
    ctx.save();
    ctx.translate(Math.round(x), Math.round(groundY) + bob);
    ctx.scale(facing, 1);
    // 腿
    ctx.fillStyle = pants;
    ctx.fillRect(-7, -26, 6, 26);
    ctx.fillRect(2, -26, 6, 26);
    // 上衣
    ctx.fillStyle = coat;
    ctx.fillRect(-10, -52, 20, 28);
    // 头
    ctx.fillStyle = COLORS.skin;
    ctx.fillRect(-7, -66, 14, 13);
    ctx.fillStyle = COLORS.hair;
    ctx.fillRect(-7, -68, 14, 5);
    if (pose === "phone") {
      // 低头看手机：脸朝下、手举发光小屏
      ctx.fillStyle = COLORS.hair;
      ctx.fillRect(-7, -60, 14, 3);
      ctx.fillStyle = coat;
      ctx.fillRect(4, -46, 12, 5);
      ctx.fillStyle = COLORS.phoneGlow;
      ctx.fillRect(12, -52, 6, 9);
    } else if (pose === "push") {
      // 手肘前顶
      ctx.fillStyle = coat;
      ctx.fillRect(6, -48, 14, 6);
      ctx.fillStyle = COLORS.skinShade;
      ctx.fillRect(18, -48, 5, 6);
    } else if (pose === "mop") {
      // 双手前伸扶拖把
      ctx.fillStyle = coat;
      ctx.fillRect(6, -46, 13, 5);
      ctx.fillRect(6, -40, 11, 5);
      ctx.strokeStyle = "#8a6f4a";
      ctx.lineWidth = 3;
      ctx.beginPath();
      ctx.moveTo(16, -48);
      ctx.lineTo(26, -2);
      ctx.stroke();
      ctx.fillStyle = "#c9cfae";
      ctx.fillRect(21, -6, 12, 6);
    } else if (pose === "flashlight") {
      ctx.fillStyle = coat;
      ctx.fillRect(6, -44, 12, 5);
      ctx.fillStyle = "#39435a";
      ctx.fillRect(16, -46, 8, 6);
      ctx.fillStyle = COLORS.flashlight;
      ctx.fillRect(24, -45, 4, 4);
    } else {
      ctx.fillStyle = coat;
      ctx.fillRect(-13, -48, 4, 20);
      ctx.fillRect(9, -48, 4, 20);
    }
    ctx.restore();
  }

  /* -------------------------------- 0–4.2s 断裂 -------------------------------- */

  private drawSnap(ctx: CanvasRenderingContext2D, t: number): void {
    this.drawNightSky(ctx, 210);
    this.drawWater(ctx, 210, LOGICAL_WIDTH, 3);
    const claspX = 470;
    const claspY = 320;
    const snapped = t >= 2100;
    const tension = clamp01((t - 200) / 1900);
    const tremble = this.reducedMotion ? 0 : Math.sin(t / 36) * (1 + tension * 3);

    // 钓线：从左上角船外延伸到磁扣；断裂后向后弹回。
    ctx.strokeStyle = COLORS.railingLight;
    ctx.lineWidth = 2;
    ctx.beginPath();
    if (!snapped) {
      ctx.moveTo(-10, 20);
      ctx.quadraticCurveTo(220, 120 + tremble * 2, claspX + tremble, claspY - 6);
    } else {
      const recoil = easeOut(clamp01((t - 2600) / 800));
      const endX = lerp(claspX, 60, recoil);
      const endY = lerp(claspY - 6, 60, recoil);
      const whip = this.reducedMotion ? 0 : Math.sin((t - 2600) / 60) * 26 * (1 - recoil);
      ctx.moveTo(-10, 20);
      ctx.quadraticCurveTo(200 + whip, 90 + whip, endX, endY);
    }
    ctx.stroke();

    // 磁扣本体：亮色裂纹随张力增加；断裂时分成两半。
    if (!snapped) {
      ctx.fillStyle = COLORS.clasp;
      ctx.fillRect(claspX - 12 + tremble, claspY - 8, 24, 16);
      const cracks = Math.min(4, Math.floor(tension * 5));
      ctx.fillStyle = COLORS.claspCrack;
      for (let index = 0; index < cracks; index += 1) {
        const cx = claspX - 8 + index * 5 + tremble;
        ctx.fillRect(cx, claspY - 7 + (index % 2) * 4, 2, 10);
      }
      if (!this.reducedMotion && tension > 0.5) {
        for (let index = 0; index < 3; index += 1) {
          const spark = pseudo(Math.floor(t / 90) * 7 + index);
          if (spark > 0.55) {
            ctx.fillStyle = COLORS.flash;
            ctx.fillRect(claspX - 16 + Math.floor(spark * 30), claspY - 14 + Math.floor(pseudo(index + t) * 8), 2, 2);
          }
        }
      }
    } else {
      const split = easeOut(clamp01((t - 2100) / 700));
      ctx.save();
      ctx.translate(claspX - 8 - split * 30, claspY - split * 14);
      ctx.rotate(-split * 0.5);
      ctx.fillStyle = COLORS.clasp;
      ctx.fillRect(-6, -8, 11, 16);
      ctx.restore();
      ctx.save();
      ctx.translate(claspX + 8 + split * 34, claspY - split * 8 + split * split * 20);
      ctx.rotate(split * 0.7);
      ctx.fillStyle = COLORS.clasp;
      ctx.fillRect(-5, -8, 11, 16);
      ctx.restore();
      const flash = clamp01(1 - (t - 2100) / 380);
      if (flash > 0) {
        ctx.globalAlpha = flash * 0.9;
        fillPixelCircle(ctx, claspX, claspY, Math.round(10 + (1 - flash) * 34), COLORS.flash);
        ctx.globalAlpha = 1;
      }
    }

    // 水面涟漪：断裂后一圈小涟漪从纸下扩散。
    if (t >= 3200) {
      const rippleT = (t - 3200) / 1000;
      const alpha = clamp01(1 - rippleT);
      strokePixelEllipse(ctx, claspX + 6, 392, 14 + rippleT * 62, 4 + rippleT * 14, 2, alpha > 0 ? COLORS.ripple : COLORS.water);
      if (rippleT > 0.35) {
        strokePixelEllipse(ctx, claspX + 6, 392, 8 + (rippleT - 0.35) * 40, 3 + (rippleT - 0.35) * 9, 2, COLORS.ripple);
      }
      ctx.globalAlpha = 1;
    }

    // 湿纸条漂在水边，断裂后一角翘起。
    const paperPose: PaperPose = {
      x: claspX + 8,
      y: 388 + Math.sin(t / 420) * (this.reducedMotion ? 0.4 : 1.6),
      angle: Math.sin(t / 530) * 0.05,
      flipT: 0,
      darken: 0,
      shine: 0.4,
      foldEmphasis: t >= 3400 ? 0.5 + (this.reducedMotion ? 0 : Math.sin(t / 300) * 0.4) : 0.15,
      scale: 1.15
    };
    this.drawPaper(ctx, paperPose, t);
  }

  /* ------------------------------ 4.2–12.4s 离开湖面 ------------------------------ */

  private drawLakeExit(ctx: CanvasRenderingContext2D, t: number): void {
    this.drawNightSky(ctx, 190);
    // 右侧石板岸与栏杆
    this.drawWater(ctx, 190, 640, 29);
    ctx.fillStyle = COLORS.stone;
    ctx.fillRect(620, 330, 340, 210);
    ctx.fillStyle = COLORS.stoneDark;
    for (let y = 340; y < 540; y += 24) ctx.fillRect(620, y, 340, 2);
    for (let x = 640; x < 960; x += 56) ctx.fillRect(x, 330, 2, 210);
    ctx.fillStyle = COLORS.stoneLight;
    ctx.fillRect(620, 330, 340, 6);
    // 栏杆
    ctx.fillStyle = COLORS.railing;
    for (let x = 596; x <= 640; x += 22) ctx.fillRect(x, 262, 5, 72);
    ctx.fillRect(590, 258, 58, 6);
    ctx.fillStyle = COLORS.railingLight;
    ctx.fillRect(590, 258, 58, 2);
    // 远处仍亮着灯的教学楼剪影
    ctx.fillStyle = COLORS.building;
    ctx.fillRect(790, 120, 170, 210);
    for (let row = 0; row < 3; row += 1) {
      for (let col = 0; col < 3; col += 1) {
        ctx.fillStyle = pseudo(row * 9 + col) > 0.35 ? COLORS.windowLit : COLORS.windowDark;
        ctx.fillRect(806 + col * 50, 142 + row * 56, 26, 20);
      }
    }

    // 纸条路径：滑水 → 撞栏杆 → 翻转 → 落石板 → 二次卷起并升到栏杆上方。
    let pose: PaperPose;
    if (t < 2700) {
      const k = easeInOut(t / 2700);
      pose = {
        x: lerp(140, 566, k),
        y: 386 + Math.sin(t / 300) * (this.reducedMotion ? 0.4 : 2),
        angle: 0.04,
        flipT: 0,
        darken: 0,
        shine: 0.5,
        foldEmphasis: 0.2,
        scale: 1.1
      };
      // 水痕尾迹
      ctx.globalAlpha = 0.5;
      ctx.fillStyle = COLORS.ripple;
      ctx.fillRect(Math.round(pose.x - 66), Math.round(pose.y + 8), 52, 2);
      ctx.globalAlpha = 1;
    } else if (t < 3400) {
      const k = (t - 2700) / 700;
      const bump = Math.sin(k * Math.PI);
      pose = {
        x: 566 - bump * 14,
        y: 384 - bump * 10,
        angle: -bump * 0.3,
        flipT: 0,
        darken: 0,
        shine: 0.5,
        foldEmphasis: 0.4,
        scale: 1.1
      };
      for (let index = 0; index < 3; index += 1) {
        this.drawDroplet(ctx, 574 + index * 6, 360 - k * 30 + index * 8, 1 - k);
      }
    } else if (t < 4400) {
      const k = easeInOut((t - 3400) / 1000);
      pose = {
        x: lerp(566, 682, k),
        y: 384 - Math.sin(k * Math.PI) * 90,
        groundY: 414,
        angle: 0,
        flipT: k,
        darken: 0,
        shine: 0.45,
        foldEmphasis: 0.3,
        scale: 1.1,
        airborne: 0.88
      };
    } else if (t < 5600) {
      const settle = clamp01((t - 4400) / 500);
      pose = { x: 682, y: 404, angle: 0, flipT: 0, darken: 0, shine: 0.35, foldEmphasis: 0.25, scale: 1.1 };
      // 落点湿痕
      ctx.globalAlpha = 0.4 * settle;
      ctx.fillStyle = COLORS.stoneDark;
      fillPixelEllipse(ctx, 682, 414, 26, 6, COLORS.stoneDark);
      ctx.globalAlpha = 1;
    } else {
      const k = clamp01((t - 5600) / 2600);
      const lift = Math.sin(clamp01((t - 5600) / 700) * Math.PI);
      pose = {
        x: lerp(682, 930, easeInOut(k)),
        y: lerp(366, 276, easeOut(k)) - lift * 42 + Math.sin(t / 160) * (this.reducedMotion ? 0 : 5),
        groundY: 428,
        angle: 0.08 + (this.reducedMotion ? 0 : Math.sin(t / 210) * 0.1),
        flipT: 0,
        darken: 0,
        shine: 0.4,
        foldEmphasis: 0.3,
        scale: 1.1,
        airborne: 0.64 + k * 0.26 + lift * 0.1
      };
      // 纸边水滴落到夜间地面，形成清晰像素高光。
      const dropSeed = Math.floor((t - 5600) / 380);
      for (let index = 0; index <= dropSeed; index += 1) {
        const dropAt = 5600 + index * 380;
        const age = t - dropAt;
        if (age < 0 || age > 900) continue;
        const fallK = clamp01(age / 520);
        const dropX = lerp(682, 930, easeInOut(clamp01((dropAt - 5600) / 2600))) - 12;
        const dropY = lerp(pose.y + 16, 428, fallK);
        if (fallK < 1) {
          this.drawDroplet(ctx, dropX, dropY, 0.9);
        } else {
          ctx.globalAlpha = clamp01(1 - (age - 520) / 380);
          ctx.fillStyle = COLORS.droplet;
          ctx.fillRect(Math.round(dropX) - 1, 428, 4, 2);
          ctx.globalAlpha = 1;
        }
      }
    }
    if (t >= 3400 && t < 4400) {
      this.drawWindWake(ctx, pose.x, pose.y, t, 0.74, 1.02);
    } else if (t >= 5600) {
      this.drawWindWake(ctx, pose.x, pose.y, t, 0.88, 1.16);
    }
    this.drawPaper(ctx, pose, t);
  }

  /* ------------------------------ 12.4–24.4s 拱廊穿行 ------------------------------ */

  private drawArcade(ctx: CanvasRenderingContext2D, t: number): void {
    ctx.fillStyle = COLORS.skyTop;
    ctx.fillRect(0, 0, LOGICAL_WIDTH, LOGICAL_HEIGHT);
    const scroll = t * 0.055;
    const paperScreenX = 300 + easeInOut(clamp01(t / 12000)) * 80 + (t > 9400 ? (t - 9400) * 0.09 : 0);
    let paperDarken = 0;
    let paperShine = 0.25;

    // 连续拱廊：整面石墙 + 带半圆拱顶的连续拱孔，孔外是夜色远景。
    ctx.fillStyle = COLORS.buildingFace;
    ctx.fillRect(0, 56, LOGICAL_WIDTH, 384);
    const columnSpacing = 260;
    const openingWidth = 148;
    const firstColumn = Math.floor(scroll / columnSpacing) - 1;
    for (let index = firstColumn; index < firstColumn + 7; index += 1) {
      const pierX = index * columnSpacing - scroll + 640;
      const openingX = pierX + 56;
      if (openingX < -openingWidth - 80 || openingX > LOGICAL_WIDTH + 80) continue;
      // 拱孔：矩形孔身 + 半圆拱顶，透出孔外的夜空与远树。
      ctx.fillStyle = COLORS.skyHorizon;
      ctx.fillRect(Math.round(openingX), 150, openingWidth, 188);
      fillPixelCircle(ctx, Math.round(openingX + openingWidth / 2), 150, openingWidth / 2, COLORS.skyHorizon);
      fillPixelEllipse(ctx, Math.round(openingX + 40), 300, 30, 44, COLORS.skyMid);
      fillPixelEllipse(ctx, Math.round(openingX + 104), 310, 24, 34, COLORS.skyMid);
      ctx.fillStyle = COLORS.stoneDark;
      ctx.fillRect(Math.round(openingX), 330, openingWidth, 8);
      // 拱孔外沿描边
      ctx.fillStyle = COLORS.stoneLight;
      ctx.fillRect(Math.round(openingX) - 3, 148, 3, 190);
      ctx.fillRect(Math.round(openingX + openingWidth), 148, 3, 190);
      // 石柱（墙垛）：纸经过柱影时短暂变暗
      ctx.fillStyle = COLORS.stone;
      ctx.fillRect(Math.round(pierX), 56, 56, 384);
      ctx.fillStyle = COLORS.stoneLight;
      ctx.fillRect(Math.round(pierX), 56, 8, 384);
      ctx.fillStyle = COLORS.stoneDark;
      ctx.fillRect(Math.round(pierX + 46), 56, 10, 384);
      if (paperScreenX > pierX - 20 && paperScreenX < pierX + 66) paperDarken = 0.55;
      // 墙面灯光带：墙垛基座上的暖色灯条与灯下湿地反光
      const lampX = pierX + columnSpacing / 2 - 20;
      ctx.fillStyle = COLORS.lamp;
      ctx.fillRect(Math.round(lampX), 348, 40, 8);
      ctx.fillStyle = COLORS.lampGlow;
      ctx.fillRect(Math.round(lampX), 356, 40, 3);
      ctx.globalAlpha = 0.24;
      fillPixelEllipse(ctx, Math.round(lampX + 20), 456, 80, 15, COLORS.lamp);
      ctx.globalAlpha = 1;
      if (paperScreenX > lampX - 60 && paperScreenX < lampX + 100) paperShine = 0.85;
    }
    // 顶部檐口
    ctx.fillStyle = COLORS.stoneDark;
    ctx.fillRect(0, 56, LOGICAL_WIDTH, 10);
    ctx.fillStyle = COLORS.stone;
    ctx.fillRect(0, 46, LOGICAL_WIDTH, 10);
    // 连续拱廊的地面石板
    ctx.fillStyle = COLORS.stoneDark;
    ctx.fillRect(0, 430, LOGICAL_WIDTH, 110);
    ctx.fillStyle = COLORS.stone;
    ctx.fillRect(0, 430, LOGICAL_WIDTH, 10);
    for (let index = 0; index < 12; index += 1) {
      const slabX = ((index * 120 - scroll * 1.0) % 1080 + 1080) % 1080 - 60;
      ctx.fillStyle = COLORS.stone;
      ctx.fillRect(Math.round(slabX), 470, 90, 3);
      ctx.fillRect(Math.round(slabX + 30), 505, 90, 3);
    }
    // 台阶边缘：纸在 6.8s 处折起一次。
    const stepX = 680 - (scroll - 374);
    if (stepX > -80 && stepX < LOGICAL_WIDTH + 80) {
      ctx.fillStyle = COLORS.stoneLight;
      ctx.fillRect(Math.round(stepX), 414, 120, 16);
      ctx.fillStyle = COLORS.stone;
      ctx.fillRect(Math.round(stepX + 36), 398, 120, 16);
    }
    // 玻璃入口的亮光在末端出现
    if (t > 9000) {
      const doorGlow = clamp01((t - 9000) / 1800);
      ctx.globalAlpha = doorGlow;
      ctx.fillStyle = COLORS.buildingFace;
      ctx.fillRect(820, 120, 140, 320);
      ctx.fillStyle = COLORS.doorGlassLit;
      ctx.fillRect(856, 190, 84, 250);
      ctx.fillStyle = COLORS.windowLit;
      ctx.fillRect(862, 200, 72, 10);
      ctx.globalAlpha = 1;
    }
    // 横风速度线
    if (!this.reducedMotion && t > 9400) {
      ctx.fillStyle = COLORS.windStreak;
      for (let index = 0; index < 6; index += 1) {
        const streakX = ((index * 210 - t * 0.6) % 1100 + 1100) % 1100 - 60;
        ctx.globalAlpha = 0.35 + pseudo(index) * 0.3;
        ctx.fillRect(Math.round(streakX), 224 + index * 18, 18, 2);
        ctx.fillRect(Math.round(streakX + 28), 226 + index * 18, 9, 2);
      }
      ctx.globalAlpha = 1;
    }

    const fold = t > 6600 && t < 7400 ? Math.sin(((t - 6600) / 800) * Math.PI) : 0;
    const baseY = 274 + Math.sin(t / 240) * (this.reducedMotion ? 0 : 9) - fold * 24;
    const pose: PaperPose = {
      x: paperScreenX,
      y: baseY,
      groundY: 462,
      angle: (this.reducedMotion ? 0.02 : Math.sin(t / 300) * 0.09) + fold * 0.5,
      flipT: 0,
      darken: paperDarken,
      shine: paperShine,
      foldEmphasis: 0.3 + fold * 0.7,
      scale: 1.05,
      airborne: 0.8
    };
    // 灯光带下纸的湿润反光
    if (paperShine > 0.6) {
      ctx.globalAlpha = 0.5;
      fillPixelEllipse(ctx, Math.round(pose.x), 462, 30, 5, COLORS.wetShine);
      ctx.globalAlpha = 1;
    }
    this.drawWindWake(ctx, pose.x, pose.y, t, 0.9, 1.2);
    this.drawPaper(ctx, pose, t);
  }

  /* ------------------------------ 24.4–32.4s 学生推门 ------------------------------ */

  private drawEntrance(ctx: CanvasRenderingContext2D, t: number): void {
    // 立面与门厅内透
    ctx.fillStyle = COLORS.buildingFace;
    ctx.fillRect(0, 0, LOGICAL_WIDTH, 470);
    ctx.fillStyle = COLORS.wall;
    ctx.fillRect(0, 0, LOGICAL_WIDTH, 60);
    ctx.fillStyle = COLORS.wallPanel;
    ctx.fillRect(0, 60, 360, 410);
    ctx.fillRect(620, 60, 340, 410);
    // 门厅暖光从玻璃门透出
    ctx.fillStyle = COLORS.windowWarm;
    ctx.fillRect(380, 90, 220, 380);
    ctx.fillStyle = COLORS.windowLit;
    ctx.fillRect(392, 102, 196, 356);
    // 玻璃双开门：门框只画四周边梃，玻璃半透叠在门厅暖光上；
    // 右扇在 1.8s 被手肘推开，7s 前缓缓合拢。
    const openT = t < 1800 ? 0 : t < 2400 ? easeOut((t - 1800) / 600) : t < 6600 ? 1 : 1 - easeInOut((t - 6600) / 900);
    const doorSwing = openT * 46;
    ctx.globalAlpha = 0.72;
    ctx.fillStyle = COLORS.doorGlass;
    ctx.fillRect(388, 98, 100, 364);
    ctx.fillStyle = COLORS.doorGlassLit;
    ctx.fillRect(492 + Math.round(doorSwing * 0.4), 98, Math.max(14, 100 - Math.round(doorSwing)), 364);
    ctx.globalAlpha = 1;
    ctx.fillStyle = COLORS.doorFrame;
    ctx.fillRect(380, 90, 220, 8);
    ctx.fillRect(380, 462, 220, 8);
    ctx.fillRect(380, 90, 8, 380);
    ctx.fillRect(592, 90, 8, 380);
    ctx.fillRect(486, 90, 8, 380);
    ctx.fillRect(586 + Math.round(doorSwing * 0.4), 90, 8, 380);
    ctx.fillRect(388, 280, 96, 6);
    ctx.fillRect(492 + Math.round(doorSwing * 0.4), 280, Math.max(14, 96 - Math.round(doorSwing)), 6);
    // 电子钟：22:44:57 → 22:45:00
    const clockText = t < 4100 ? "22:44:57" : t < 5100 ? "22:44:58" : t < 6100 ? "22:44:59" : "22:45:00";
    ctx.fillStyle = "#0c1420";
    ctx.fillRect(398, 116, 176, 44);
    ctx.fillStyle = COLORS.doorFrame;
    ctx.fillRect(398, 116, 176, 3);
    ctx.fillRect(398, 157, 176, 3);
    const chimeFlash = t >= 6100 && t < 6600 ? Math.sin(((t - 6100) / 500) * Math.PI) : 0;
    ctx.fillStyle = chimeFlash > 0 ? COLORS.flash : COLORS.clockDigit;
    ctx.font = "28px monospace";
    ctx.textAlign = "center";
    ctx.textBaseline = "middle";
    ctx.fillText(clockText, 486, 140);
    ctx.textAlign = "left";

    // 地面
    ctx.fillStyle = COLORS.stone;
    ctx.fillRect(0, 470, LOGICAL_WIDTH, 70);
    ctx.fillStyle = COLORS.stoneDark;
    for (let x = 20; x < 960; x += 64) ctx.fillRect(x, 500, 2, 40);
    ctx.fillRect(0, 470, LOGICAL_WIDTH, 4);
    ctx.fillStyle = COLORS.stoneLight;

    // 学生：远处走来，低头看手机、调整双肩包、用手肘推门。
    const studentX = t < 1400 ? lerp(830, 610, easeInOut(t / 1400)) : 610;
    const pushing = t >= 1600 && t < 2600;
    const studentGone = t >= 4700;
    if (!studentGone) {
      const walkIn = t >= 3800 ? clamp01((t - 3800) / 900) : 0;
      const insideX = studentX - walkIn * 120;
      // 双肩包
      this.drawPerson(ctx, insideX, 462, COLORS.studentCoat, COLORS.studentPants, pushing ? "push" : "phone", -1, t);
      ctx.fillStyle = "#6b4a2f";
      ctx.fillRect(Math.round(insideX) + 6, 462 - 50, 10, 22);
      if (t >= 1400 && t < 1700) {
        // 调整双肩包：手臂后抬
        ctx.fillStyle = COLORS.studentCoat;
        ctx.fillRect(Math.round(insideX) + 2, 462 - 56, 14, 5);
      }
    }

    // 纸条沿入口前的气流悬起，压差把它吸入门厅。
    let pose: PaperPose;
    if (t < 3200) {
      pose = {
        x: lerp(60, 430, easeInOut(t / 3200)),
        y: lerp(320, 292, easeOut(clamp01(t / 3200))) + Math.sin(t / 200) * (this.reducedMotion ? 0 : 6),
        groundY: 470,
        angle: 0.05,
        flipT: 0,
        darken: 0,
        shine: 0.3,
        foldEmphasis: 0.3,
        scale: 1,
        airborne: 0.62
      };
    } else {
      const k = easeInOut(clamp01((t - 3200) / 1400));
      pose = {
        x: lerp(430, 520, k),
        y: 292 - Math.sin(k * Math.PI) * 36,
        groundY: 470,
        angle: 0.12 * Math.sin(k * Math.PI),
        flipT: 0,
        darken: 0,
        shine: 0.45,
        foldEmphasis: 0.3,
        scale: 1,
        airborne: 0.66 + Math.sin(k * Math.PI) * 0.24
      };
      // 压差气流线
      if (!this.reducedMotion && k < 1) {
        ctx.fillStyle = COLORS.windStreak;
        ctx.globalAlpha = 0.5 * (1 - k);
        for (let index = 0; index < 4; index += 1) {
          ctx.fillRect(Math.round(pose.x - 70 - index * 26), Math.round(pose.y - 8 + index * 7), 40, 2);
        }
        ctx.globalAlpha = 1;
      }
    }
    this.drawWindWake(ctx, pose.x, pose.y, t, 0.82, 1.08);
    this.drawPaper(ctx, pose, t);
  }

  /* ------------------------------ 32.4–44.2s 门厅湿地 ------------------------------ */

  private drawLobby(ctx: CanvasRenderingContext2D, t: number): void {
    // 门厅墙面与指示牌
    ctx.fillStyle = COLORS.wall;
    ctx.fillRect(0, 0, LOGICAL_WIDTH, 380);
    ctx.fillStyle = COLORS.wallPanel;
    ctx.fillRect(0, 250, LOGICAL_WIDTH, 130);
    ctx.fillStyle = COLORS.windowDark;
    ctx.fillRect(60, 80, 150, 110);
    ctx.fillStyle = COLORS.windowLit;
    ctx.fillRect(66, 86, 138, 98);
    ctx.fillStyle = COLORS.wallPanel;
    ctx.fillRect(60, 80, 150, 8);
    // 麦斯威方向牌
    ctx.fillStyle = COLORS.signYellow;
    ctx.fillRect(420, 120, 130, 34);
    ctx.fillStyle = COLORS.cautionInk;
    ctx.font = "19px monospace";
    ctx.textAlign = "center";
    ctx.textBaseline = "middle";
    ctx.fillText("麦斯威 →", 485, 138);
    ctx.textAlign = "left";
    // 小心地滑警示牌
    ctx.fillStyle = COLORS.signYellow;
    ctx.beginPath();
    ctx.moveTo(286, 330);
    ctx.lineTo(306, 384);
    ctx.lineTo(266, 384);
    ctx.closePath();
    ctx.fill();
    ctx.fillStyle = COLORS.cautionInk;
    ctx.fillRect(282, 344, 8, 22);
    ctx.fillRect(282, 370, 8, 4);

    // 刚拖过的湿地：整条反光水膜。
    ctx.fillStyle = COLORS.lobbyFloor;
    ctx.fillRect(0, 380, LOGICAL_WIDTH, 160);
    ctx.fillStyle = COLORS.lobbyTile;
    for (let x = 0; x < 960; x += 80) ctx.fillRect(x, 380, 2, 160);
    for (let y = 412; y < 540; y += 32) ctx.fillRect(0, y, 960, 2);
    ctx.fillStyle = COLORS.wetBand;
    ctx.fillRect(0, 430, LOGICAL_WIDTH, 66);
    ctx.globalAlpha = 0.5;
    ctx.fillStyle = COLORS.wetShine;
    for (let x = 30; x < 940; x += 150) ctx.fillRect(x, 448 + (x % 3) * 8, 60, 3);
    ctx.globalAlpha = 1;

    // 阶梯教室侧门：右端虚掩，透出环廊暗光。
    ctx.fillStyle = COLORS.doorFrame;
    ctx.fillRect(860, 250, 90, 240);
    ctx.fillStyle = COLORS.corridorWall;
    ctx.fillRect(868, 258, 74, 232);
    ctx.fillStyle = COLORS.doorGlass;
    ctx.fillRect(872, 262, 50, 228);

    // 纸条进入门厅后迅速升到人物头顶上方，保洁员随后从地面追赶。
    const paperX = t < 7600 ? lerp(40, 560, easeInOut(t / 7600)) : lerp(560, 888, easeInOut(clamp01((t - 7600) / 3600)));
    const climb = easeOut(clamp01((t - 900) / 1800));
    const paperY = lerp(390, 274, climb) - clamp01((t - 7600) / 1800) * 18
      + Math.sin(t / 220) * (this.reducedMotion ? 0 : 5);
    // 侧门气流把纸带入环廊
    if (!this.reducedMotion && t > 8600) {
      ctx.fillStyle = COLORS.windStreak;
      ctx.globalAlpha = 0.45;
      for (let index = 0; index < 4; index += 1) {
        const streakX = 620 + ((index * 90 + t * 0.35) % 240);
        ctx.fillRect(Math.round(streakX), 252 + index * 14, 16, 2);
        ctx.fillRect(Math.round(streakX + 26), 254 + index * 14, 8, 2);
      }
      ctx.globalAlpha = 1;
    }

    // 保洁员先抬头确认目标，随后推车追在纸条后方。
    const cleanerChasing = t >= 3200;
    const cleanerX = cleanerChasing
      ? Math.max(286, Math.min(736, paperX - 168))
      : 286;
    this.drawPerson(
      ctx,
      cleanerX,
      452,
      COLORS.cleanerCoat,
      COLORS.cleanerPants,
      cleanerChasing ? "push" : "mop",
      1,
      t
    );
    if (cleanerChasing) {
      const cartX = Math.round(cleanerX + 24);
      ctx.fillStyle = "#2c4054";
      ctx.fillRect(cartX, 425, 36, 22);
      ctx.fillStyle = COLORS.wetShine;
      ctx.fillRect(cartX + 3, 428, 30, 4);
      ctx.fillStyle = COLORS.stoneDark;
      ctx.fillRect(cartX + 4, 447, 7, 5);
      ctx.fillRect(cartX + 26, 447, 7, 5);
    } else {
      ctx.fillStyle = "#3a5a78";
      ctx.fillRect(318, 424, 30, 22);
      ctx.fillStyle = "#7fa6c8";
      ctx.fillRect(318, 424, 30, 4);
    }

    const pose: PaperPose = {
      x: paperX,
      y: paperY,
      groundY: 468,
      angle: 0.03 + (this.reducedMotion ? 0 : Math.sin(t / 260) * 0.05),
      flipT: 0,
      darken: 0,
      shine: 0.75,
      foldEmphasis: 0.35,
      scale: 1,
      airborne: 0.7 + climb * 0.28
    };
    if (t > 6200) this.drawWindWake(ctx, pose.x, pose.y, t, 0.62, 0.94);
    this.drawPaper(ctx, pose, t);
  }

  /* -------------------------------- 44.2s– 清楼开始 -------------------------------- */

  private drawClosing(ctx: CanvasRenderingContext2D, t: number, _durationMs: number): void {
    // 环廊：吊顶灯带、公告栏、广播喇叭。
    ctx.fillStyle = COLORS.corridorWall;
    ctx.fillRect(0, 0, LOGICAL_WIDTH, LOGICAL_HEIGHT);
    ctx.fillStyle = COLORS.wall;
    ctx.fillRect(0, 0, LOGICAL_WIDTH, 90);
    ctx.fillStyle = COLORS.corridorFloor;
    ctx.fillRect(0, 430, LOGICAL_WIDTH, 110);
    ctx.fillStyle = COLORS.stoneDark;
    ctx.fillRect(0, 430, LOGICAL_WIDTH, 4);
    ctx.fillStyle = COLORS.wallPanel;
    ctx.fillRect(300, 150, 190, 120);
    ctx.fillStyle = COLORS.paper;
    ctx.fillRect(316, 166, 60, 44);
    ctx.fillRect(388, 166, 60, 44);
    ctx.fillStyle = COLORS.paperLine;
    ctx.fillRect(322, 176, 48, 3);
    ctx.fillRect(322, 186, 48, 3);
    ctx.fillRect(394, 176, 48, 3);
    // 广播喇叭
    ctx.fillStyle = COLORS.speaker;
    ctx.fillRect(104, 60, 34, 26);
    ctx.beginPath();
    ctx.moveTo(138, 58);
    ctx.lineTo(164, 48);
    ctx.lineTo(164, 96);
    ctx.lineTo(138, 88);
    ctx.closePath();
    ctx.fill();
    // 广播电流声：喇叭前的短促电波纹与一次屏闪。
    if (t < 900) {
      const burst = 1 - t / 900;
      ctx.globalAlpha = clamp01(burst);
      ctx.strokeStyle = COLORS.flash;
      ctx.lineWidth = 2;
      for (let index = 0; index < 3; index += 1) {
        ctx.beginPath();
        ctx.arc(170, 72, 10 + index * 12 + (1 - burst) * 8, -0.7, 0.7);
        ctx.stroke();
      }
      if (!this.reducedMotion && t < 260) {
        ctx.globalAlpha = 0.16 * (1 - t / 260);
        ctx.fillStyle = COLORS.flash;
        ctx.fillRect(0, 0, LOGICAL_WIDTH, LOGICAL_HEIGHT);
      }
      ctx.globalAlpha = 1;
    }

    // 5.8s 起部分照明关闭：灯带分两批熄灭。
    const firstOut = t >= 5800;
    const secondOut = t >= 6600;
    const lamps = [
      { x: 210, on: !firstOut },
      { x: 430, on: !secondOut },
      { x: 650, on: !firstOut },
      { x: 840, on: !secondOut }
    ];
    for (const lamp of lamps) {
      ctx.fillStyle = lamp.on ? COLORS.ceilingLamp : COLORS.stoneDark;
      ctx.fillRect(lamp.x - 34, 88, 68, 8);
      if (lamp.on) {
        ctx.globalAlpha = 0.16;
        ctx.fillStyle = COLORS.ceilingLamp;
        ctx.beginPath();
        ctx.moveTo(lamp.x - 34, 96);
        ctx.lineTo(lamp.x + 34, 96);
        ctx.lineTo(lamp.x + 70, 430);
        ctx.lineTo(lamp.x - 70, 430);
        ctx.closePath();
        ctx.fill();
        ctx.globalAlpha = 1;
      }
    }
    if (firstOut) {
      ctx.globalAlpha = secondOut ? 0.42 : 0.24;
      ctx.fillStyle = "#060910";
      ctx.fillRect(0, 0, LOGICAL_WIDTH, LOGICAL_HEIGHT);
      ctx.globalAlpha = 1;
    }

    // 保安：手电筒压在手边，广播后抬手示意。
    const guardAlert = t >= 1000;
    this.drawPerson(ctx, 800, 470, COLORS.guardCoat, COLORS.guardPants, guardAlert ? "flashlight" : "idle", -1, t);
    if (guardAlert) {
      ctx.globalAlpha = 0.2;
      ctx.fillStyle = COLORS.flashlight;
      ctx.beginPath();
      ctx.moveTo(800 - 26, 470 - 46);
      ctx.lineTo(800 - 120, 470 - 20);
      ctx.lineTo(800 - 120, 470 + 8);
      ctx.closePath();
      ctx.fill();
      ctx.globalAlpha = 1;
    }

    // 纸条被气流带着深入环廊，关灯后只剩余光里的轮廓。
    const paperX = lerp(180, 640, easeInOut(clamp01(t / 7000)));
    const pose: PaperPose = {
      x: paperX,
      y: 270 + Math.sin(t / 240) * (this.reducedMotion ? 0 : 9),
      groundY: 472,
      angle: 0.04,
      flipT: 0,
      darken: secondOut ? 0.45 : firstOut ? 0.2 : 0,
      shine: secondOut ? 0.2 : 0.5,
      foldEmphasis: 0.3,
      scale: 1,
      airborne: 0.72
    };
    this.drawWindWake(ctx, pose.x, pose.y, t, secondOut ? 0.58 : 0.72, 1.08);
    this.drawPaper(ctx, pose, t);
  }

  private handleResize(): void {
    const cssWidth = this.canvas.clientWidth || LOGICAL_WIDTH;
    const width = Math.max(BUFFER_MIN_WIDTH, Math.min(BUFFER_MAX_WIDTH, Math.round(cssWidth)));
    const height = Math.round((width * 9) / 16);
    if (this.canvas.width !== width || this.canvas.height !== height) {
      this.canvas.width = width;
      this.canvas.height = height;
    }
    this.scale = width / LOGICAL_WIDTH;
  }
}

function fillPixelCircle(
  ctx: CanvasRenderingContext2D,
  cx: number,
  cy: number,
  radius: number,
  color: string
): void {
  ctx.fillStyle = color;
  for (let y = -radius; y <= radius; y += 2) {
    const half = Math.floor(Math.sqrt(Math.max(0, radius * radius - y * y)));
    ctx.fillRect(Math.round(cx - half), Math.round(cy + y), Math.max(2, half * 2), 2);
  }
}

function fillPixelEllipse(
  ctx: CanvasRenderingContext2D,
  cx: number,
  cy: number,
  rx: number,
  ry: number,
  color: string
): void {
  ctx.fillStyle = color;
  for (let y = -ry; y <= ry; y += 2) {
    const half = Math.floor(rx * Math.sqrt(Math.max(0, 1 - (y * y) / (ry * ry))));
    ctx.fillRect(Math.round(cx - half), Math.round(cy + y), Math.max(2, half * 2), 2);
  }
}

function strokePixelEllipse(
  ctx: CanvasRenderingContext2D,
  cx: number,
  cy: number,
  rx: number,
  ry: number,
  thickness: number,
  color: string
): void {
  ctx.fillStyle = color;
  const innerRx = Math.max(1, rx - thickness);
  const innerRy = Math.max(1, ry - thickness);
  for (let y = -ry; y <= ry; y += 2) {
    const outer = Math.floor(rx * Math.sqrt(Math.max(0, 1 - (y * y) / (ry * ry))));
    const inner = y >= -innerRy && y <= innerRy
      ? Math.floor(innerRx * Math.sqrt(Math.max(0, 1 - (y * y) / (innerRy * innerRy))))
      : 0;
    if (inner <= 0) {
      ctx.fillRect(Math.round(cx - outer), Math.round(cy + y), Math.max(2, outer * 2), 2);
      continue;
    }
    ctx.fillRect(Math.round(cx - outer), Math.round(cy + y), Math.max(1, outer - inner), 2);
    ctx.fillRect(Math.round(cx + inner), Math.round(cy + y), Math.max(1, outer - inner), 2);
  }
}

function mixToward(from: string, to: string, t: number): string {
  const a = [parseInt(from.slice(1, 3), 16), parseInt(from.slice(3, 5), 16), parseInt(from.slice(5, 7), 16)];
  const b = [parseInt(to.slice(1, 3), 16), parseInt(to.slice(3, 5), 16), parseInt(to.slice(5, 7), 16)];
  return `rgb(${Math.round(lerp(a[0], b[0], t))},${Math.round(lerp(a[1], b[1], t))},${Math.round(lerp(a[2], b[2], t))})`;
}
