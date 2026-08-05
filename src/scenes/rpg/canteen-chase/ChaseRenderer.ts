import {
  projectObstaclePoint,
  visibleObstacles,
  visiblePedestrians,
  VISIBLE_DISTANCE,
  type ChaseObstacleKind,
  type ChasePedestrianKind
} from "./ChaseGeometry";
import { createChaseSprites, type ChaseSprites } from "./ChaseSprites";

export interface ChaseRenderState {
  runState: "running" | "won" | "lost";
  distance: number;
  lane: number;
  invulnerableMs: number;
  collisions: number;
  paused: boolean;
}

const LOGICAL_WIDTH = 960;
const LOGICAL_HEIGHT = 540;
const HORIZON_Y = 145;
const BUFFER_MIN_WIDTH = 480;
const BUFFER_MAX_WIDTH = 960;

const SKY_BANDS = ["#77b8ed", "#93c6ef", "#b4d7f0", "#d6e7ef"] as const;
const SKYLINE: readonly (readonly [number, number, number])[] = [
  [0, 116, 40], [40, 98, 33], [73, 124, 39], [112, 90, 45], [157, 118, 44],
  [201, 82, 51], [252, 124, 49], [301, 102, 46], [347, 120, 40], [400, 110, 36],
  [470, 118, 42], [540, 108, 38], [612, 108, 46], [658, 84, 50], [708, 120, 38],
  [746, 96, 44], [790, 118, 48], [838, 76, 46], [884, 109, 43], [927, 92, 33]
];

interface ObstacleMeta {
  frames: HTMLCanvasElement[];
  baseWidth: number;
}

function clamp01(value: number): number {
  return Math.max(0, Math.min(1, value));
}

// Canvas renderer for the canteen bike chase. The React overlay owns the
// simulation and DOM overlays; this class owns all scene painting. It renders
// into a small backing buffer (min 480x270) that CSS upscales with
// image-rendering: pixelated, so the whole scene shares one chunky pixel grid.
export class ChaseRenderer {
  private readonly canvas: HTMLCanvasElement;
  private readonly ctx: CanvasRenderingContext2D;
  private readonly sprites: ChaseSprites;
  private readonly obstacles: Record<ChaseObstacleKind, ObstacleMeta>;
  private readonly pedestrians: Record<ChasePedestrianKind, ObstacleMeta>;
  private readonly background: HTMLCanvasElement;
  private readonly scaledCache = new Map<string, HTMLCanvasElement>();
  private readonly observer: ResizeObserver;
  private scale = 0.5;
  private reduceMotion = false;
  private riderX = 480;
  private lastNow = 0;
  private lastCollisions = 0;
  private flashStart = -1000;

  constructor(canvas: HTMLCanvasElement) {
    this.canvas = canvas;
    const ctx = canvas.getContext("2d");
    if (!ctx) throw new Error("ChaseRenderer requires a 2D canvas context");
    this.ctx = ctx;
    this.sprites = createChaseSprites();
    this.obstacles = {
      barrier: { frames: this.sprites.barrier, baseWidth: 130 },
      cone: { frames: [this.sprites.cone], baseWidth: 84 },
      car: { frames: [this.sprites.car], baseWidth: 150 },
      crowd: { frames: [this.sprites.crowd], baseWidth: 140 },
      bicycle: { frames: [this.sprites.bicycle], baseWidth: 92 },
      runner: { frames: this.sprites.runner, baseWidth: 96 }
    };
    this.pedestrians = {
      phoneWalker: { frames: this.sprites.pedestrians.phoneWalker, baseWidth: 92 },
      chattingPair: { frames: this.sprites.pedestrians.chattingPair, baseWidth: 108 },
      soyMilk: { frames: this.sprites.pedestrians.soyMilk, baseWidth: 88 },
      bikePusher: { frames: this.sprites.pedestrians.bikePusher, baseWidth: 116 }
    };
    this.background = document.createElement("canvas");
    this.observer = new ResizeObserver(() => this.handleResize());
    this.observer.observe(canvas);
    this.handleResize();
  }

  destroy(): void {
    this.observer.disconnect();
    this.scaledCache.clear();
  }

  setReducedMotion(reduced: boolean): void {
    this.reduceMotion = reduced;
  }

  render(state: ChaseRenderState): void {
    const now = performance.now();
    const deltaMs = this.lastNow === 0 ? 16 : Math.min(100, Math.max(0, now - this.lastNow));
    this.lastNow = now;
    const ctx = this.ctx;
    const s = this.scale;
    ctx.imageSmoothingEnabled = false;
    ctx.setTransform(s, 0, 0, s, 0, 0);
    ctx.globalAlpha = 1;
    ctx.drawImage(this.background, 0, 0, LOGICAL_WIDTH, LOGICAL_HEIGHT);

    this.drawClouds(ctx, state.distance);
    this.drawLaneDashes(ctx, state.distance, -0.5);
    this.drawLaneDashes(ctx, state.distance, 0.5);
    this.drawRoadside(ctx, state.distance);
    this.drawPedestrians(ctx, state.distance);
    this.drawPaper(ctx, state.distance);
    this.drawObstacles(ctx, state);
    this.drawRider(ctx, state, deltaMs);
    if (state.runState === "running" && !this.reduceMotion) this.drawSpeedLines(ctx, state.distance);
    this.drawCollisionFlash(ctx, state, now);
    ctx.globalAlpha = 1;
  }

  private handleResize(): void {
    const cssWidth = this.canvas.clientWidth || LOGICAL_WIDTH;
    const width = Math.max(BUFFER_MIN_WIDTH, Math.min(BUFFER_MAX_WIDTH, Math.round(cssWidth / 2)));
    const height = Math.round((width * 9) / 16);
    if (this.canvas.width === width && this.canvas.height === height) return;
    this.canvas.width = width;
    this.canvas.height = height;
    this.scale = width / LOGICAL_WIDTH;
    this.scaledCache.clear();
    this.buildBackground();
  }

  private getScaled(key: string, sprite: HTMLCanvasElement, width: number): HTMLCanvasElement {
    const cacheKey = `${key}@${width}`;
    const cached = this.scaledCache.get(cacheKey);
    if (cached) return cached;
    const height = Math.max(1, Math.round((sprite.height * width) / sprite.width));
    const scaled = document.createElement("canvas");
    scaled.width = width;
    scaled.height = height;
    const ctx = scaled.getContext("2d");
    if (ctx) {
      ctx.imageSmoothingEnabled = false;
      ctx.drawImage(sprite, 0, 0, width, height);
    }
    this.scaledCache.set(cacheKey, scaled);
    return scaled;
  }

  // Draws a sprite anchored bottom-center at logical (cx, bottomY), snapped to
  // the backing-buffer pixel grid so upscale never shimmers.
  private blit(
    ctx: CanvasRenderingContext2D,
    key: string,
    sprite: HTMLCanvasElement,
    cx: number,
    bottomY: number,
    logicalWidth: number,
    alpha: number,
    flip = false
  ): { width: number; height: number } {
    const s = this.scale;
    const drawWidth = Math.max(4, Math.round((logicalWidth * s) / 2) * 2);
    const scaled = this.getScaled(key, sprite, drawWidth);
    const bx = Math.round(cx * s - drawWidth / 2);
    const by = Math.round(bottomY * s) - scaled.height;
    const logicalH = scaled.height / s;
    ctx.globalAlpha = alpha;
    if (flip) {
      ctx.save();
      ctx.translate((bx + drawWidth) / s, by / s);
      ctx.scale(-1, 1);
      ctx.drawImage(scaled, 0, 0, drawWidth / s, logicalH);
      ctx.restore();
    } else {
      ctx.drawImage(scaled, bx / s, by / s, drawWidth / s, logicalH);
    }
    ctx.globalAlpha = 1;
    return { width: drawWidth / s, height: logicalH };
  }

  private blitCentered(
    ctx: CanvasRenderingContext2D,
    key: string,
    sprite: HTMLCanvasElement,
    cx: number,
    cy: number,
    logicalWidth: number,
    alpha: number
  ): void {
    const s = this.scale;
    const drawWidth = Math.max(4, Math.round((logicalWidth * s) / 2) * 2);
    const scaled = this.getScaled(key, sprite, drawWidth);
    const bx = Math.round(cx * s - drawWidth / 2);
    const by = Math.round(cy * s - scaled.height / 2);
    ctx.globalAlpha = alpha;
    ctx.drawImage(scaled, bx / s, by / s, drawWidth / s, scaled.height / s);
    ctx.globalAlpha = 1;
  }

  private drawShadow(ctx: CanvasRenderingContext2D, cx: number, cy: number, logicalWidth: number, alpha: number): void {
    ctx.globalAlpha = 0.32 * alpha;
    ctx.fillStyle = "#11191e";
    ctx.beginPath();
    ctx.ellipse(cx, cy - 2, logicalWidth * 0.42, logicalWidth * 0.1, 0, 0, Math.PI * 2);
    ctx.fill();
    ctx.globalAlpha = 1;
  }

  private buildBackground(): void {
    const s = this.scale;
    this.background.width = this.canvas.width;
    this.background.height = this.canvas.height;
    const ctx = this.background.getContext("2d");
    if (!ctx) return;
    ctx.imageSmoothingEnabled = false;
    ctx.setTransform(s, 0, 0, s, 0, 0);

    // sky bands with a 2px dithered seam
    const bandHeight = HORIZON_Y / SKY_BANDS.length;
    SKY_BANDS.forEach((color, index) => {
      ctx.fillStyle = color;
      ctx.fillRect(0, Math.floor(index * bandHeight), LOGICAL_WIDTH, Math.ceil(bandHeight));
      if (index > 0) {
        ctx.fillStyle = SKY_BANDS[index - 1];
        for (let x = 0; x < LOGICAL_WIDTH; x += 4) {
          ctx.fillRect(x + (index % 2) * 2, Math.floor(index * bandHeight), 2, 1);
        }
      }
    });

    this.blitCentered(ctx, "sun", this.sprites.sun, 790, 76, 72, 0.95);

    // campus skyline silhouette
    ctx.globalAlpha = 0.5;
    ctx.fillStyle = "#718b94";
    for (const [x, top, width] of SKYLINE) {
      ctx.fillRect(x, top, width, HORIZON_Y - top);
    }
    ctx.globalAlpha = 1;

    // ground, verges, sidewalks
    ctx.fillStyle = "#658a55";
    ctx.fillRect(0, HORIZON_Y, LOGICAL_WIDTH, LOGICAL_HEIGHT - HORIZON_Y);
    ctx.fillStyle = "#3b7142";
    ctx.beginPath();
    ctx.moveTo(0, 150); ctx.lineTo(30, 540); ctx.lineTo(0, 540); ctx.closePath();
    ctx.moveTo(960, 150); ctx.lineTo(930, 540); ctx.lineTo(960, 540); ctx.closePath();
    ctx.fill();
    ctx.fillStyle = "#9d9b90";
    ctx.beginPath();
    ctx.moveTo(410, HORIZON_Y); ctx.lineTo(12, 540); ctx.lineTo(30, 540); ctx.lineTo(420, HORIZON_Y); ctx.closePath();
    ctx.moveTo(550, HORIZON_Y); ctx.lineTo(948, 540); ctx.lineTo(930, 540); ctx.lineTo(540, HORIZON_Y); ctx.closePath();
    ctx.fill();

    // road trapezoid with deterministic asphalt speckle
    ctx.fillStyle = "#3a4248";
    ctx.beginPath();
    ctx.moveTo(420, HORIZON_Y);
    ctx.lineTo(540, HORIZON_Y);
    ctx.lineTo(930, 540);
    ctx.lineTo(30, 540);
    ctx.closePath();
    ctx.fill();
    ctx.save();
    ctx.clip();
    for (let i = 0; i < 480; i += 1) {
      const rx = (Math.imul(i + 3, 2654435761) >>> 0) / 4294967296;
      const ry = (Math.imul(i + 91, 1597334677) >>> 0) / 4294967296;
      ctx.fillStyle = i % 2 === 0 ? "#454e55" : "#31383e";
      ctx.fillRect(Math.floor(rx * LOGICAL_WIDTH), HORIZON_Y + Math.floor(ry * (LOGICAL_HEIGHT - HORIZON_Y)), 2, 1);
    }
    ctx.restore();

    // yellow edge lines and pale inner guides
    ctx.strokeStyle = "#f0d54e";
    ctx.lineWidth = 7;
    ctx.beginPath();
    ctx.moveTo(420, HORIZON_Y); ctx.lineTo(30, 540);
    ctx.moveTo(540, HORIZON_Y); ctx.lineTo(930, 540);
    ctx.stroke();
    ctx.strokeStyle = "#f8edb0";
    ctx.lineWidth = 2;
    ctx.globalAlpha = 0.65;
    ctx.beginPath();
    ctx.moveTo(414, HORIZON_Y); ctx.lineTo(18, 540);
    ctx.moveTo(546, HORIZON_Y); ctx.lineTo(942, 540);
    ctx.stroke();
    ctx.globalAlpha = 1;
  }

  private drawClouds(ctx: CanvasRenderingContext2D, distance: number): void {
    const drift = this.reduceMotion ? 0 : distance * 0.35;
    const slots: readonly (readonly [number, number, number])[] = [[120, 70, 130], [660, 95, 90]];
    slots.forEach(([base, y, width], index) => {
      const x = (((base + drift * (index === 0 ? 1 : 0.6)) % 1160) + 1160) % 1160 - 100;
      this.blitCentered(ctx, `cloud${index}`, this.sprites.clouds[index], x, y, width, 0.85);
    });
  }

  private drawLaneDashes(ctx: CanvasRenderingContext2D, distance: number, laneOffset: number): void {
    const travel = distance * 0.72;
    const spacing = 42;
    const firstWorldIndex = Math.floor(travel / spacing) + 1;
    ctx.fillStyle = "#f4f0de";
    for (let index = 0; index < 12; index += 1) {
      const ahead = (firstWorldIndex + index) * spacing - travel;
      const depthNear = clamp01(1 - ahead / 420);
      const depthFar = clamp01(1 - (ahead + 18) / 420);
      if (depthNear <= 0) continue;
      const pNear = depthNear * depthNear;
      const pFar = depthFar * depthFar;
      const top = HORIZON_Y + pFar * 395;
      const bottom = HORIZON_Y + pNear * 395;
      const xTop = 480 + laneOffset * (44 + pFar * 260);
      const xBottom = 480 + laneOffset * (44 + pNear * 260);
      const halfTop = 1.5 + pFar * 2;
      const halfBottom = 2 + pNear * 2.5;
      ctx.globalAlpha = 0.18 + depthNear * 0.6;
      ctx.beginPath();
      ctx.moveTo(xTop - halfTop, top);
      ctx.lineTo(xTop + halfTop, top);
      ctx.lineTo(xBottom + halfBottom, bottom);
      ctx.lineTo(xBottom - halfBottom, bottom);
      ctx.closePath();
      ctx.fill();
    }
    ctx.globalAlpha = 1;
  }

  private drawRoadside(ctx: CanvasRenderingContext2D, distance: number): void {
    const spacing = 24;
    const firstWorldIndex = Math.floor(distance / spacing) + 1;
    for (let index = 9; index >= 0; index -= 1) {
      const worldIndex = firstWorldIndex + index;
      const ahead = worldIndex * spacing - distance;
      const depth = clamp01(1 - ahead / 220);
      const perspective = depth * depth;
      for (const side of [-1, 1] as const) {
        const variant = worldIndex * 2 + (side > 0 ? 1 : 0);
        const x = 480 + side * (78 + perspective * 430);
        const y = HORIZON_Y + perspective * 350;
        const scale = 0.15 + perspective * 1.18;
        const opacity = 0.28 + perspective * 0.72;
        if (variant % 5 === 0) {
          this.drawShadow(ctx, x, y, 100 * scale, opacity);
          this.blit(ctx, "lamp", this.sprites.lamp, x, y, 100 * scale, opacity, side > 0);
        } else if (variant % 3 === 0) {
          this.drawShadow(ctx, x, y, 150 * scale, opacity);
          this.blit(ctx, "tree", this.sprites.tree, x, y, 150 * scale, opacity);
        } else {
          const buildingIndex = variant % 3 === 1 ? 0 : variant % 3 === 2 ? 1 : 2;
          this.drawShadow(ctx, x, y, 200 * scale, opacity);
          this.blit(ctx, `building${buildingIndex}`, this.sprites.buildings[buildingIndex], x, y, 200 * scale, opacity);
        }
      }
    }
  }

  // Sidewalk pedestrians: deterministic world slots on both sidewalks, drawn
  // between the roadside props and the road traffic so crossing obstacles
  // still pass in front. They never enter the road or the collision set.
  private drawPedestrians(ctx: CanvasRenderingContext2D, distance: number): void {
    const frameStep = this.reduceMotion ? 0 : Math.floor(distance * 0.15);
    for (const pedestrian of visiblePedestrians(distance)) {
      const ahead = pedestrian.distance - distance;
      const depth = clamp01(1 - ahead / VISIBLE_DISTANCE);
      const perspective = depth * depth;
      const half = 88 + perspective * 436 + (pedestrian.laneOffset - 0.5) * 22;
      const x = 480 + pedestrian.side * half;
      const y = HORIZON_Y + 3 + perspective * 352;
      const scale = 0.16 + perspective * 1.22;
      const opacity = 0.3 + perspective * 0.7;
      const meta = this.pedestrians[pedestrian.kind];
      const frame = (frameStep + pedestrian.phase) % 2;
      const logicalWidth = meta.baseWidth * scale;
      this.drawShadow(ctx, x, y, logicalWidth, opacity);
      this.blit(
        ctx,
        `ped-${pedestrian.kind}${frame}`,
        meta.frames[frame],
        x,
        y,
        logicalWidth,
        opacity,
        pedestrian.side > 0
      );
    }
  }

  private drawPaper(ctx: CanvasRenderingContext2D, distance: number): void {
    const bob = this.reduceMotion ? 0 : Math.sin(distance * 0.6) * 3;
    ctx.globalAlpha = 0.35;
    ctx.fillStyle = "#68d8ff";
    ctx.fillRect(480 - 26, 122 + bob - 14, 52, 30);
    ctx.globalAlpha = 1;
    this.blitCentered(ctx, "paper", this.sprites.paper, 480, 122 + bob, 40, 1);
  }

  private drawObstacles(ctx: CanvasRenderingContext2D, state: ChaseRenderState): void {
    for (const obstacle of visibleObstacles(state.distance)) {
      const projection = projectObstaclePoint(obstacle, obstacle.distance - state.distance);
      const meta = this.obstacles[obstacle.kind];
      let frame = 0;
      if (obstacle.kind === "barrier") {
        frame = this.reduceMotion ? 0 : Math.floor(state.distance * 3) % 2;
      } else if (obstacle.kind === "runner") {
        frame = Math.floor(state.distance * 8) % 4;
      }
      const logicalWidth = meta.baseWidth * projection.scale;
      this.drawShadow(ctx, projection.x, projection.y, logicalWidth, projection.opacity);
      this.blit(
        ctx,
        `${obstacle.kind}${frame}`,
        meta.frames[frame],
        projection.x,
        projection.y,
        logicalWidth,
        projection.opacity,
        obstacle.kind === "runner" && projection.crossingSide < 0
      );
    }
  }

  private drawRider(ctx: CanvasRenderingContext2D, state: ChaseRenderState, deltaMs: number): void {
    const targetX = 480 + (state.lane - 1) * 258;
    this.riderX += (targetX - this.riderX) * Math.min(1, deltaMs / 120);
    if (state.invulnerableMs > 0) {
      if (this.reduceMotion) {
        ctx.globalAlpha = 0.5;
      } else if (Math.floor(state.invulnerableMs / 110) % 2 === 0) {
        return;
      }
    }
    const frame = state.runState === "running" ? Math.floor(state.distance * 4) % 3 : 1;
    this.drawShadow(ctx, this.riderX, 452, 150, 1);
    this.blit(ctx, `rider${frame}`, this.sprites.rider[frame], this.riderX, 452, 150, 1);
    ctx.globalAlpha = 1;
  }

  private drawSpeedLines(ctx: CanvasRenderingContext2D, distance: number): void {
    ctx.fillStyle = "#f4f0de";
    for (let index = 0; index < 6; index += 1) {
      const y = ((distance * 36 + index * 91) % 560) - 10;
      const leftSide = index % 2 === 0;
      const x = (leftSide ? 40 : 700) + ((index * 53) % 120);
      ctx.globalAlpha = 0.1;
      ctx.fillRect(x, y, 90, 3);
    }
    ctx.globalAlpha = 1;
  }

  private drawCollisionFlash(ctx: CanvasRenderingContext2D, state: ChaseRenderState, now: number): void {
    if (state.collisions > this.lastCollisions) this.flashStart = now;
    this.lastCollisions = state.collisions;
    const progress = (now - this.flashStart) / 240;
    if (progress >= 1) return;
    ctx.globalAlpha = 0.3 * (1 - progress);
    ctx.fillStyle = "#e05a4e";
    ctx.fillRect(0, 0, LOGICAL_WIDTH, LOGICAL_HEIGHT);
    ctx.globalAlpha = 1;
  }
}
