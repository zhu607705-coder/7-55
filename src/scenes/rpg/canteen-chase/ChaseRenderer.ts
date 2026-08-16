import {
  projectObstaclePoint,
  visibleObstacles,
  visiblePedestrians,
  VISIBLE_DISTANCE,
  type ChaseObstacleKind,
  type ChasePedestrianKind
} from "./ChaseGeometry";
import campusAvenuePlateUrl from "../../../assets/rpg/canteen_chase/campus_avenue_plate.png";
import campusAvenueDistanceAtlasUrl from "../../../assets/rpg/canteen_chase/campus_avenue_distance_atlas_273f.png";
import riderCycleUrl from "../../../assets/rpg/canteen_chase/rider_cycle_6f.png";
import roadsideActorAtlasUrl from "../../../assets/rpg/canteen_chase/roadside_actor_atlas_8f.png";
import runnerCrowdCycleUrl from "../../../assets/rpg/canteen_chase/runner_crowd_cycle_4f.png";
import frontWalkerCycleUrl from "../../../assets/rpg/canteen_chase/front_walker_cycle_4f.png";
import riderTurnCycleUrl from "../../../assets/rpg/canteen_chase/rider_turn_cycle_12f.png";
import { ChaseThreeRenderer } from "./ChaseThreeRenderer";
import type { ChaseRenderState, ChaseRendererBackend } from "./ChaseRenderContract";

export type { ChaseRenderState } from "./ChaseRenderContract";

const LOGICAL_WIDTH = 960;
const LOGICAL_HEIGHT = 540;
const HORIZON_Y = 136;
const BUFFER_MIN_WIDTH = 480;
const BUFFER_MAX_WIDTH = 960;
const GOAL_DISTANCE = 755;
const DISTANCE_KEYFRAMES = [
  0, 47, 95, 143, 190, 238, 285, 331, 377, 424, 470, 518, 566, 600, 635, 668, 700, 755
] as const;
const DISTANCE_ATLAS_COLUMNS = 16;
const DISTANCE_FRAMES_PER_INTERVAL = 16;
const DISTANCE_FRAME_WIDTH = 320;
const DISTANCE_FRAME_HEIGHT = 180;

interface SpriteCrop {
  x: number;
  y: number;
  width: number;
  height: number;
}

const RIDER_CROPS: readonly SpriteCrop[] = [
  { x: 65, y: 189, width: 167, height: 456 },
  { x: 373, y: 189, width: 168, height: 456 },
  { x: 687, y: 189, width: 168, height: 456 },
  { x: 991, y: 189, width: 169, height: 456 },
  { x: 1304, y: 189, width: 168, height: 456 },
  { x: 1613, y: 189, width: 168, height: 456 }
] as const;

const RIDER_TURN_CELL_WIDTH = 256;
const RIDER_TURN_CELL_HEIGHT = 384;

function riderTurnCrop(row: 0 | 1 | 2, column: 0 | 1 | 2 | 3): SpriteCrop {
  return {
    x: column * RIDER_TURN_CELL_WIDTH + 32,
    y: row * RIDER_TURN_CELL_HEIGHT + 12,
    width: 192,
    height: 358
  };
}

const ACTOR_CROPS = {
  phoneA: { x: 91, y: 177, width: 170, height: 392 },
  phoneB: { x: 346, y: 178, width: 169, height: 388 },
  soyMilkA: { x: 608, y: 182, width: 169, height: 384 },
  soyMilkB: { x: 853, y: 182, width: 233, height: 384 },
  cone: { x: 1086, y: 357, width: 272, height: 209 },
  barrier: { x: 1358, y: 378, width: 271, height: 185 },
  bicycle: { x: 1629, y: 330, width: 271, height: 239 },
  car: { x: 1900, y: 265, width: 224, height: 299 }
} as const satisfies Record<string, SpriteCrop>;

const FRONT_WALKER_CROPS = {
  phoneA: { x: 132, y: 85, width: 264, height: 690 },
  phoneB: { x: 538, y: 85, width: 270, height: 690 },
  soyMilkA: { x: 936, y: 85, width: 275, height: 690 },
  soyMilkB: { x: 1344, y: 85, width: 276, height: 690 }
} as const satisfies Record<string, SpriteCrop>;

const ROAD_HAZARD_CROPS = {
  runnerA: { x: 172, y: 238, width: 222, height: 328 },
  runnerB: { x: 612, y: 238, width: 235, height: 337 },
  crowdA: { x: 1053, y: 227, width: 356, height: 361 },
  crowdB: { x: 1578, y: 214, width: 363, height: 374 }
} as const satisfies Record<string, SpriteCrop>;

// Warm morning palette: low sun from the upper right, gold-lit greens, and
// long shadows falling left across the scene.
const COLORS = {
  skyTop: "#7cb6d9",
  skyMid: "#a9d0e2",
  skyWarm: "#e9dfba",
  skyGlow: "#f9e3ae",
  sunCore: "#fff6d8",
  sunGlow: "#fbe7a4",
  cloud: "#fbfdff",
  cloudShade: "#e4eef0",
  road: "#4a453c",
  roadDark: "#38342c",
  roadLight: "#5c564a",
  lane: "#f2ead2",
  curb: "#c9bb9c",
  curbLight: "#e4d6b2",
  grass: "#7aa14e",
  grassDark: "#5c7f3c",
  grassLight: "#96b95e",
  flower: "#f2e3a0",
  sidewalk: "#ab9f86",
  sidewalkLight: "#c3b698",
  ink: "#2a241c",
  blue: "#35689b",
  blueDark: "#26486e",
  blueLight: "#7fb2c9",
  amber: "#f0b93e",
  amberDark: "#b38430",
  red: "#d45a48",
  redDark: "#a03a30",
  orange: "#ef7d3a",
  orangeLight: "#f7a05e",
  white: "#f7f2df",
  skin: "#dda868",
  skinShade: "#c08c50",
  pants: "#3d4149",
  tree: "#4e7d3a",
  treeDark: "#3a6130",
  treeLight: "#82ad4f",
  treeGold: "#b5cb62",
  trunk: "#6d4b32",
  trunkDark: "#4e3524",
  cyan: "#7fdce2",
  glass: "#3d5a66",
  glassLight: "#8fb0ba",
  brick: "#a8583f",
  brickDark: "#7e4434",
  cream: "#e8d9b8",
  creamShade: "#c9b891",
  metal: "#9aa4a8",
  shadow: "#2e2a1e"
} as const;

function clamp01(value: number): number {
  return Math.max(0, Math.min(1, value));
}

function lerp(a: number, b: number, t: number): number {
  return a + (b - a) * t;
}

function mixColor(from: string, to: string, t: number): string {
  const a = [
    parseInt(from.slice(1, 3), 16),
    parseInt(from.slice(3, 5), 16),
    parseInt(from.slice(5, 7), 16)
  ];
  const b = [
    parseInt(to.slice(1, 3), 16),
    parseInt(to.slice(3, 5), 16),
    parseInt(to.slice(5, 7), 16)
  ];
  return `rgb(${Math.round(lerp(a[0], b[0], t))},${Math.round(lerp(a[1], b[1], t))},${Math.round(lerp(a[2], b[2], t))})`;
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

export class ChaseCanvasRenderer implements ChaseRendererBackend {
  private readonly canvas: HTMLCanvasElement;
  private readonly ctx: CanvasRenderingContext2D;
  private readonly background: HTMLCanvasElement;
  private readonly pixelBackground: HTMLCanvasElement;
  private readonly observer: ResizeObserver;
  private scale = 0.5;
  private reduceMotion = false;
  private riderX = 480;
  private lastNow = 0;
  private lastCollisions = 0;
  private flashStart = -1000;
  private animationMs = 0;
  private readonly campusAvenuePlate: HTMLImageElement;
  private readonly campusAvenueDistanceAtlas: HTMLImageElement;
  private readonly riderCycle: HTMLImageElement;
  private readonly actorAtlas: HTMLImageElement;
  private readonly runnerCrowdCycle: HTMLImageElement;
  private readonly frontWalkerCycle: HTMLImageElement;
  private readonly riderTurnCycle: HTMLImageElement;

  constructor(canvas: HTMLCanvasElement) {
    this.canvas = canvas;
    const ctx = canvas.getContext("2d");
    if (!ctx) throw new Error("ChaseRenderer requires a 2D canvas context");
    this.ctx = ctx;
    this.background = document.createElement("canvas");
    this.pixelBackground = document.createElement("canvas");
    this.pixelBackground.width = DISTANCE_FRAME_WIDTH;
    this.pixelBackground.height = DISTANCE_FRAME_HEIGHT;
    this.campusAvenuePlate = this.loadImage(campusAvenuePlateUrl, () => this.buildBackground());
    this.campusAvenueDistanceAtlas = this.loadImage(campusAvenueDistanceAtlasUrl);
    this.riderCycle = this.loadImage(riderCycleUrl);
    this.actorAtlas = this.loadImage(roadsideActorAtlasUrl);
    this.runnerCrowdCycle = this.loadImage(runnerCrowdCycleUrl);
    this.frontWalkerCycle = this.loadImage(frontWalkerCycleUrl);
    this.riderTurnCycle = this.loadImage(riderTurnCycleUrl);
    this.observer = new ResizeObserver(() => this.handleResize());
    this.observer.observe(canvas);
    this.handleResize();
  }

  destroy(): void {
    this.observer.disconnect();
  }

  setReducedMotion(reduced: boolean): void {
    this.reduceMotion = reduced;
  }

  render(state: ChaseRenderState): void {
    const now = performance.now();
    const deltaMs = this.lastNow === 0 ? 16 : Math.min(100, Math.max(0, now - this.lastNow));
    this.lastNow = now;
    if (state.runState === "running" && !state.paused && !this.reduceMotion) {
      this.animationMs += deltaMs;
    }
    const ctx = this.ctx;
    ctx.imageSmoothingEnabled = false;
    ctx.setTransform(this.scale, 0, 0, this.scale, 0, 0);
    ctx.globalAlpha = 1;
    const generatedPlateReady = this.isReady(this.campusAvenueDistanceAtlas);
    if (generatedPlateReady) {
      this.drawGeneratedBackground(ctx, state.distance);
      this.drawRoadSurfaceFlow(ctx, state.distance);
    } else {
      ctx.drawImage(this.background, 0, 0, LOGICAL_WIDTH, LOGICAL_HEIGHT);
      this.drawClouds(ctx, state.distance);
      this.drawRoadMotion(ctx, state.distance);
      this.drawRoadside(ctx, state.distance);
    }
    this.drawPedestrians(ctx, state.distance);
    this.drawPaper(ctx, state.distance);
    this.drawObstacles(ctx, state);
    this.drawRider(ctx, state, deltaMs);
    if (state.runState === "running" && !this.reduceMotion) {
      this.drawSpeedTicks(ctx, state.distance);
      this.drawWheelSpray(ctx, state.distance);
    }
    this.drawCollisionFlash(ctx, state, now);
    ctx.globalAlpha = 1;
  }

  private loadImage(source: string, onLoad?: () => void): HTMLImageElement {
    const image = new Image();
    image.decoding = "async";
    if (onLoad) image.addEventListener("load", onLoad, { once: true });
    image.src = source;
    return image;
  }

  private isReady(image: HTMLImageElement): boolean {
    return image.complete && image.naturalWidth > 0 && image.naturalHeight > 0;
  }

  private drawGeneratedBackground(ctx: CanvasRenderingContext2D, distance: number): void {
    // The atlas contains 16 calibrated camera poses between every adjacent
    // generated plate, including the new 755 m terminal plate. Runtime draws
    // one opaque pixel frame, so no alpha ghosting or dissolve texture remains.
    const pixelCtx = this.pixelBackground.getContext("2d");
    if (!pixelCtx || !this.isReady(this.campusAvenueDistanceAtlas)) return;

    const clampedDistance = Math.max(0, Math.min(GOAL_DISTANCE, distance));
    let lowerIndex = 0;
    for (let index = 1; index < DISTANCE_KEYFRAMES.length; index += 1) {
      if (DISTANCE_KEYFRAMES[index] > clampedDistance) break;
      lowerIndex = index;
    }
    const upperIndex = Math.min(lowerIndex + 1, DISTANCE_KEYFRAMES.length - 1);
    const lowerDistance = DISTANCE_KEYFRAMES[lowerIndex];
    const upperDistance = DISTANCE_KEYFRAMES[upperIndex];
    const intervalProgress = upperIndex === lowerIndex
      ? 1
      : clamp01((clampedDistance - lowerDistance) / (upperDistance - lowerDistance));
    const lastFrameIndex = (DISTANCE_KEYFRAMES.length - 1) * DISTANCE_FRAMES_PER_INTERVAL;
    const framePosition = lowerIndex === DISTANCE_KEYFRAMES.length - 1
      ? lastFrameIndex
      : lowerIndex * DISTANCE_FRAMES_PER_INTERVAL
        + intervalProgress * DISTANCE_FRAMES_PER_INTERVAL;
    const frameIndex = Math.min(lastFrameIndex, Math.floor(framePosition));
    const sourceX = (frameIndex % DISTANCE_ATLAS_COLUMNS) * DISTANCE_FRAME_WIDTH;
    const sourceY = Math.floor(frameIndex / DISTANCE_ATLAS_COLUMNS) * DISTANCE_FRAME_HEIGHT;

    pixelCtx.setTransform(1, 0, 0, 1, 0, 0);
    pixelCtx.clearRect(0, 0, DISTANCE_FRAME_WIDTH, DISTANCE_FRAME_HEIGHT);
    pixelCtx.imageSmoothingEnabled = false;
    pixelCtx.drawImage(
      this.campusAvenueDistanceAtlas,
      sourceX,
      sourceY,
      DISTANCE_FRAME_WIDTH,
      DISTANCE_FRAME_HEIGHT,
      0,
      0,
      DISTANCE_FRAME_WIDTH,
      DISTANCE_FRAME_HEIGHT
    );

    ctx.save();
    ctx.imageSmoothingEnabled = false;
    ctx.drawImage(this.pixelBackground, 0, 0, LOGICAL_WIDTH, LOGICAL_HEIGHT);
    ctx.restore();
  }

  private drawRoadSurfaceFlow(ctx: CanvasRenderingContext2D, distance: number): void {
    // The source plate already owns every lane marking. Only low-contrast road
    // texture flecks move toward the rider, adding speed without drawing a
    // second set of divider lines over the authored image.
    const travel = distance * 1.7;
    ctx.save();
    ctx.globalAlpha = 0.12;
    for (let index = 0; index < 18; index += 1) {
      const seed = index * 47 + 19;
      const ahead = ((seed - travel) % 430 + 430) % 430;
      const depth = clamp01(1 - ahead / 430);
      const perspective = depth * depth;
      const y = HORIZON_Y + perspective * (LOGICAL_HEIGHT - HORIZON_Y);
      const halfRoad = 42 + perspective * 315;
      const lateral = ((((seed * 73) % 100) / 100) * 2 - 1) * halfRoad * 0.82;
      const width = Math.max(1, Math.round(1 + perspective * 8));
      const height = Math.max(1, Math.round(1 + perspective * 3));
      ctx.fillStyle = index % 2 === 0 ? "#f1e4c5" : "#17202b";
      ctx.fillRect(Math.round(480 + lateral), Math.round(y), width, height);
    }
    ctx.restore();
  }

  private drawSprite(
    ctx: CanvasRenderingContext2D,
    image: HTMLImageElement,
    crop: SpriteCrop,
    x: number,
    bottomY: number,
    targetHeight: number,
    alpha = 1,
    flipX = false
  ): void {
    const targetWidth = targetHeight * (crop.width / crop.height);
    ctx.save();
    ctx.globalAlpha = alpha;
    if (flipX) {
      ctx.translate(Math.round(x * 2), 0);
      ctx.scale(-1, 1);
    }
    ctx.drawImage(
      image,
      crop.x,
      crop.y,
      crop.width,
      crop.height,
      Math.round(x - targetWidth / 2),
      Math.round(bottomY - targetHeight),
      Math.round(targetWidth),
      Math.round(targetHeight)
    );
    ctx.restore();
  }

  private handleResize(): void {
    const cssWidth = this.canvas.clientWidth || LOGICAL_WIDTH;
    // Keep the logical 960 px scene at native resolution on desktop. The
    // previous half-width backing store doubled every authored pixel and made
    // the rider, pedestrians, and obstacle silhouettes look unfinished.
    const width = Math.max(BUFFER_MIN_WIDTH, Math.min(BUFFER_MAX_WIDTH, Math.round(cssWidth)));
    const height = Math.round((width * 9) / 16);
    // Scale must track every observed size, not just ones that change the
    // buffer: React StrictMode remounts create a fresh renderer (scale = 0.5,
    // empty background) on a canvas whose backing store already matches.
    this.scale = width / LOGICAL_WIDTH;
    if (this.canvas.width !== width || this.canvas.height !== height) {
      this.canvas.width = width;
      this.canvas.height = height;
    }
    if (this.background.width !== width || this.background.height !== height) {
      this.background.width = width;
      this.background.height = height;
      this.buildBackground();
    }
  }

  private buildBackground(): void {
    const ctx = this.background.getContext("2d");
    if (!ctx) return;
    ctx.imageSmoothingEnabled = false;
    ctx.setTransform(this.scale, 0, 0, this.scale, 0, 0);

    if (this.isReady(this.campusAvenuePlate)) {
      ctx.clearRect(0, 0, LOGICAL_WIDTH, LOGICAL_HEIGHT);
      ctx.drawImage(this.campusAvenuePlate, 0, 0, LOGICAL_WIDTH, LOGICAL_HEIGHT);
      return;
    }

    // Banded morning sky: cool blue up top warming into gold at the horizon.
    for (let y = 0; y < HORIZON_Y; y += 2) {
      const t = y / HORIZON_Y;
      const color = t < 0.5
        ? mixColor(COLORS.skyTop, COLORS.skyMid, t / 0.5)
        : t < 0.8
          ? mixColor(COLORS.skyMid, COLORS.skyWarm, (t - 0.5) / 0.3)
          : mixColor(COLORS.skyWarm, COLORS.skyGlow, (t - 0.8) / 0.2);
      ctx.fillStyle = color;
      ctx.fillRect(0, y, LOGICAL_WIDTH, 2);
    }

    // Low sun in the upper right with a soft halo.
    ctx.globalAlpha = 0.16;
    fillPixelCircle(ctx, 716, 52, 56, COLORS.sunGlow);
    ctx.globalAlpha = 0.3;
    fillPixelCircle(ctx, 716, 52, 34, COLORS.sunGlow);
    ctx.globalAlpha = 1;
    fillPixelCircle(ctx, 716, 52, 18, COLORS.sunCore);
    ctx.fillStyle = COLORS.sunCore;
    ctx.fillRect(716 - 26, 51, 52, 2);
    ctx.fillRect(715, 52 - 26, 2, 52);
    // Warm haze pooling along the horizon under the sun.
    ctx.globalAlpha = 0.28;
    ctx.fillStyle = COLORS.skyGlow;
    ctx.fillRect(520, 112, 440, 24);
    ctx.globalAlpha = 0.16;
    ctx.fillRect(0, 120, 520, 16);
    ctx.globalAlpha = 1;

    this.drawDistantCampus(ctx);

    ctx.fillStyle = COLORS.grass;
    ctx.fillRect(0, HORIZON_Y, LOGICAL_WIDTH, LOGICAL_HEIGHT - HORIZON_Y);
    ctx.fillStyle = COLORS.grassDark;
    ctx.fillRect(0, HORIZON_Y + 18, LOGICAL_WIDTH, 7);
    // Golden wash on the sunlit right half of the lawns.
    ctx.globalAlpha = 0.1;
    ctx.fillStyle = COLORS.sunGlow;
    ctx.beginPath();
    ctx.moveTo(560, HORIZON_Y);
    ctx.lineTo(LOGICAL_WIDTH, HORIZON_Y);
    ctx.lineTo(LOGICAL_WIDTH, LOGICAL_HEIGHT);
    ctx.lineTo(700, LOGICAL_HEIGHT);
    ctx.closePath();
    ctx.fill();
    ctx.globalAlpha = 1;
    // Grass tufts and sparse tiny flowers, scattered deterministically.
    for (let index = 0; index < 150; index += 1) {
      const x = (Math.imul(index + 53, 1103515245) >>> 5) % LOGICAL_WIDTH;
      const y = HORIZON_Y + 26 + ((Math.imul(index + 97, 2654435761) >>> 6) % (LOGICAL_HEIGHT - HORIZON_Y - 26));
      if (x > 96 && x < 864) continue;
      ctx.fillStyle = index % 3 === 0 ? COLORS.grassLight : COLORS.grassDark;
      ctx.globalAlpha = 0.5;
      ctx.fillRect(x, y, 4, 2);
      if (index % 9 === 0) {
        ctx.fillStyle = COLORS.flower;
        ctx.fillRect(x + 5, y - 2, 2, 2);
      }
    }
    ctx.globalAlpha = 1;

    ctx.fillStyle = COLORS.sidewalk;
    ctx.beginPath();
    ctx.moveTo(390, HORIZON_Y);
    ctx.lineTo(112, LOGICAL_HEIGHT);
    ctx.lineTo(24, LOGICAL_HEIGHT);
    ctx.lineTo(372, HORIZON_Y);
    ctx.closePath();
    ctx.moveTo(570, HORIZON_Y);
    ctx.lineTo(848, LOGICAL_HEIGHT);
    ctx.lineTo(936, LOGICAL_HEIGHT);
    ctx.lineTo(588, HORIZON_Y);
    ctx.closePath();
    ctx.fill();

    ctx.fillStyle = COLORS.sidewalkLight;
    for (let index = 0; index < 10; index += 1) {
      const t = index / 10;
      const y = HORIZON_Y + t * t * (LOGICAL_HEIGHT - HORIZON_Y);
      const leftX = 384 - t * t * 320;
      const rightX = 576 + t * t * 320;
      ctx.fillRect(Math.round(leftX), Math.round(y), Math.max(2, Math.round(7 + t * 16)), 2);
      ctx.fillRect(Math.round(rightX), Math.round(y), Math.max(2, Math.round(7 + t * 16)), 2);
    }

    ctx.fillStyle = COLORS.road;
    ctx.beginPath();
    ctx.moveTo(404, HORIZON_Y);
    ctx.lineTo(556, HORIZON_Y);
    ctx.lineTo(850, LOGICAL_HEIGHT);
    ctx.lineTo(110, LOGICAL_HEIGHT);
    ctx.closePath();
    ctx.fill();

    ctx.save();
    ctx.clip();
    for (let index = 0; index < 260; index += 1) {
      const x = (Math.imul(index + 29, 1103515245) >>> 5) % LOGICAL_WIDTH;
      const y = HORIZON_Y + ((Math.imul(index + 71, 2654435761) >>> 6) % (LOGICAL_HEIGHT - HORIZON_Y));
      ctx.fillStyle = index % 2 === 0 ? COLORS.roadDark : COLORS.roadLight;
      ctx.globalAlpha = 0.26;
      ctx.fillRect(x, y, 2, 1);
    }
    // Sunlight raking across the right lane.
    ctx.globalAlpha = 0.07;
    ctx.fillStyle = COLORS.sunGlow;
    ctx.beginPath();
    ctx.moveTo(520, HORIZON_Y);
    ctx.lineTo(556, HORIZON_Y);
    ctx.lineTo(850, LOGICAL_HEIGHT);
    ctx.lineTo(560, LOGICAL_HEIGHT);
    ctx.closePath();
    ctx.fill();
    ctx.restore();
    ctx.globalAlpha = 1;

    ctx.strokeStyle = COLORS.curb;
    ctx.lineWidth = 5;
    ctx.beginPath();
    ctx.moveTo(404, HORIZON_Y); ctx.lineTo(110, LOGICAL_HEIGHT);
    ctx.moveTo(556, HORIZON_Y); ctx.lineTo(850, LOGICAL_HEIGHT);
    ctx.stroke();
    ctx.strokeStyle = COLORS.curbLight;
    ctx.lineWidth = 2;
    ctx.globalAlpha = 0.8;
    ctx.beginPath();
    ctx.moveTo(407, HORIZON_Y); ctx.lineTo(117, LOGICAL_HEIGHT);
    ctx.moveTo(553, HORIZON_Y); ctx.lineTo(843, LOGICAL_HEIGHT);
    ctx.stroke();
    ctx.globalAlpha = 1;
  }

  private drawDistantCampus(ctx: CanvasRenderingContext2D): void {
    // Flanking dorms in warm cream with brick rooflines.
    for (const base of [{ x: 46, y: 92, w: 242, h: 44 }, { x: 672, y: 84, w: 232, h: 52 }]) {
      ctx.fillStyle = COLORS.creamShade;
      ctx.fillRect(base.x, base.y + 4, base.w, base.h);
      ctx.fillStyle = COLORS.cream;
      ctx.fillRect(base.x + 4, base.y + 8, base.w - 8, base.h - 4);
      ctx.fillStyle = COLORS.brick;
      ctx.fillRect(base.x, base.y, base.w, 6);
      ctx.fillStyle = COLORS.brickDark;
      for (let x = base.x + 4; x < base.x + base.w - 4; x += 22) ctx.fillRect(x, base.y + 2, 12, 2);
      for (let x = base.x + 16; x < base.x + base.w - 20; x += 30) {
        ctx.fillStyle = COLORS.glass;
        ctx.fillRect(x, base.y + 14, 18, 14);
        ctx.fillStyle = COLORS.glassLight;
        ctx.fillRect(x + 2, base.y + 16, 5, 3);
      }
      // A couple of windows still lit from inside on early mornings.
      ctx.fillStyle = COLORS.amber;
      ctx.fillRect(base.x + 46, base.y + 14, 18, 14);
      ctx.fillStyle = COLORS.glass;
      ctx.fillRect(base.x + 48, base.y + 16, 14, 10);
    }

    // Destination theater at the vanishing point: brick facade, amber marquee
    // with bulb dots, dark entrance. It is the visual "finish line".
    ctx.fillStyle = COLORS.brickDark;
    ctx.fillRect(428, 88, 104, 48);
    ctx.fillStyle = COLORS.brick;
    ctx.fillRect(432, 90, 96, 46);
    ctx.fillStyle = COLORS.ink;
    ctx.fillRect(430, 96, 100, 12);
    ctx.fillStyle = COLORS.amber;
    ctx.fillRect(432, 98, 96, 8);
    ctx.fillStyle = COLORS.sunCore;
    for (let x = 436; x < 524; x += 8) ctx.fillRect(x, 100, 3, 3);
    ctx.fillStyle = COLORS.ink;
    ctx.fillRect(458, 112, 44, 24);
    ctx.fillStyle = COLORS.glass;
    ctx.fillRect(462, 116, 36, 20);
    ctx.fillStyle = COLORS.cream;
    ctx.fillRect(438, 112, 12, 24);
    ctx.fillRect(510, 112, 12, 24);

    // Tree line behind the road gap, flanking the theater.
    for (let x = 292; x <= 668; x += 34) {
      if (x > 400 && x < 560) continue;
      fillPixelCircle(ctx, x, 126, 18, COLORS.tree);
      fillPixelCircle(ctx, x - 5, 121, 10, COLORS.treeLight);
      fillPixelCircle(ctx, x + 7, 118, 6, COLORS.treeGold);
    }
  }

  private drawClouds(ctx: CanvasRenderingContext2D, distance: number): void {
    // Slow parallax drift; tied to travel distance like the lane dashes.
    const drift = this.reduceMotion ? 0 : distance * 0.22;
    const clouds = [
      { base: 120, y: 30, scale: 1.1, speed: 1 },
      { base: 460, y: 60, scale: 0.8, speed: 0.7 },
      { base: 780, y: 40, scale: 1.35, speed: 0.5 }
    ];
    for (const cloud of clouds) {
      const x = ((cloud.base + drift * cloud.speed) % 1160) - 100;
      const s = cloud.scale;
      ctx.globalAlpha = 0.92;
      ctx.fillStyle = COLORS.cloud;
      ctx.fillRect(Math.round(x), Math.round(cloud.y), Math.round(44 * s), Math.round(10 * s));
      ctx.fillRect(Math.round(x + 8 * s), Math.round(cloud.y - 6 * s), Math.round(26 * s), Math.round(8 * s));
      ctx.fillRect(Math.round(x + 30 * s), Math.round(cloud.y - 3 * s), Math.round(18 * s), Math.round(7 * s));
      ctx.fillStyle = COLORS.cloudShade;
      ctx.fillRect(Math.round(x + 3 * s), Math.round(cloud.y + 8 * s), Math.round(40 * s), Math.max(2, Math.round(3 * s)));
    }
    ctx.globalAlpha = 1;
  }

  private drawRoadMotion(ctx: CanvasRenderingContext2D, distance: number): void {
    const travel = distance * 0.82;
    const spacing = 48;
    ctx.fillStyle = COLORS.lane;
    for (const laneOffset of [-0.5, 0.5]) {
      const first = Math.floor(travel / spacing) + 1;
      for (let index = 0; index < 10; index += 1) {
        const ahead = (first + index) * spacing - travel;
        const nearDepth = clamp01(1 - ahead / 430);
        const farDepth = clamp01(1 - (ahead + 20) / 430);
        if (nearDepth <= 0) continue;
        const nearPerspective = nearDepth * nearDepth;
        const farPerspective = farDepth * farDepth;
        const top = HORIZON_Y + farPerspective * 404;
        const bottom = HORIZON_Y + nearPerspective * 404;
        const topX = 480 + laneOffset * (34 + farPerspective * 210);
        const bottomX = 480 + laneOffset * (34 + nearPerspective * 210);
        ctx.globalAlpha = 0.3 + nearDepth * 0.62;
        ctx.beginPath();
        ctx.moveTo(topX - 2, top);
        ctx.lineTo(topX + 2, top);
        ctx.lineTo(bottomX + 5, bottom);
        ctx.lineTo(bottomX - 5, bottom);
        ctx.closePath();
        ctx.fill();
      }
    }
    ctx.globalAlpha = 1;
  }

  private drawRoadside(ctx: CanvasRenderingContext2D, distance: number): void {
    const spacing = 54;
    const first = Math.floor(distance / spacing) + 1;
    for (let index = 6; index >= 0; index -= 1) {
      const worldIndex = first + index;
      const ahead = worldIndex * spacing - distance;
      const depth = clamp01(1 - ahead / 290);
      const perspective = depth * depth;
      if (depth <= 0) continue;
      for (const side of [-1, 1] as const) {
        const x = 480 + side * (112 + perspective * 390);
        const y = HORIZON_Y + perspective * 358;
        const size = 0.22 + perspective * 0.92;
        const alpha = 0.28 + depth * 0.72;
        // Morning shadows stretch left, away from the sun.
        this.drawLongShadow(ctx, x, y, 58 * size, alpha * 0.34);
        if ((worldIndex + (side > 0 ? 1 : 0)) % 4 === 0) {
          this.drawLamp(ctx, x, y, size, side, alpha);
        } else {
          this.drawTree(ctx, x, y, size, alpha);
        }
      }
    }
  }

  private drawLongShadow(
    ctx: CanvasRenderingContext2D,
    x: number,
    y: number,
    length: number,
    alpha: number
  ): void {
    ctx.globalAlpha = Math.min(0.3, alpha);
    ctx.fillStyle = COLORS.shadow;
    ctx.beginPath();
    ctx.moveTo(Math.round(x - 10), Math.round(y - 2));
    ctx.lineTo(Math.round(x + 10), Math.round(y - 2));
    ctx.lineTo(Math.round(x - length + 16), Math.round(y + 10 + length * 0.22));
    ctx.lineTo(Math.round(x - length - 6), Math.round(y + 8 + length * 0.22));
    ctx.closePath();
    ctx.fill();
    ctx.globalAlpha = 1;
  }

  private drawTree(ctx: CanvasRenderingContext2D, x: number, y: number, scale: number, alpha: number): void {
    ctx.globalAlpha = alpha;
    ctx.fillStyle = COLORS.trunkDark;
    ctx.fillRect(Math.round(x - 4 * scale), Math.round(y - 36 * scale), Math.max(2, Math.round(8 * scale)), Math.round(34 * scale));
    ctx.fillStyle = COLORS.trunk;
    ctx.fillRect(Math.round(x - 3 * scale), Math.round(y - 38 * scale), Math.max(2, Math.round(6 * scale)), Math.round(36 * scale));
    fillPixelCircle(ctx, x, y - 56 * scale, Math.max(4, Math.round(22 * scale)), COLORS.tree);
    fillPixelCircle(ctx, x - 13 * scale, y - 50 * scale, Math.max(3, Math.round(14 * scale)), COLORS.treeDark);
    fillPixelCircle(ctx, x + 13 * scale, y - 51 * scale, Math.max(3, Math.round(13 * scale)), COLORS.treeLight);
    // Sunlit crown rim on the upper right.
    fillPixelCircle(ctx, x + 9 * scale, y - 63 * scale, Math.max(3, Math.round(9 * scale)), COLORS.treeGold);
    ctx.globalAlpha = 1;
  }

  private drawLamp(ctx: CanvasRenderingContext2D, x: number, y: number, scale: number, side: -1 | 1, alpha: number): void {
    ctx.globalAlpha = alpha;
    ctx.fillStyle = COLORS.ink;
    ctx.fillRect(Math.round(x - 10 * scale), Math.round(y - 3 * scale), Math.round(20 * scale), Math.max(2, Math.round(4 * scale)));
    ctx.fillRect(Math.round(x - 2 * scale), Math.round(y - 64 * scale), Math.max(2, Math.round(4 * scale)), Math.round(62 * scale));
    const armX = side < 0 ? x + 2 * scale : x - 22 * scale;
    ctx.fillRect(Math.round(armX), Math.round(y - 64 * scale), Math.round(22 * scale), Math.max(2, Math.round(3 * scale)));
    // Lamp is off in daylight; head keeps a faint warm rim from the sun.
    ctx.fillStyle = COLORS.amberDark;
    ctx.fillRect(Math.round(side < 0 ? x + 18 * scale : x - 22 * scale), Math.round(y - 61 * scale), Math.max(2, Math.round(7 * scale)), Math.max(2, Math.round(5 * scale)));
    // Campus banner hanging from the pole.
    ctx.fillStyle = COLORS.blue;
    ctx.fillRect(Math.round(x + (side < 0 ? -9 : 4) * scale), Math.round(y - 56 * scale), Math.max(2, Math.round(5 * scale)), Math.round(14 * scale));
    ctx.fillStyle = COLORS.white;
    ctx.fillRect(Math.round(x + (side < 0 ? -8 : 5) * scale), Math.round(y - 53 * scale), Math.max(1, Math.round(3 * scale)), Math.max(2, Math.round(3 * scale)));
    ctx.globalAlpha = 1;
  }

  private drawPedestrians(ctx: CanvasRenderingContext2D, distance: number): void {
    const pedestrians = visiblePedestrians(distance).slice(-4);
    const phase = this.reduceMotion ? 0 : Math.floor(this.animationMs / 180) % 2;
    pedestrians.forEach((pedestrian) => {
      const ahead = pedestrian.distance - distance;
      const depth = clamp01(1 - ahead / VISIBLE_DISTANCE);
      const perspective = depth * depth;
      // Anchor walkers to the centre line of each authored sidewalk. Their
      // lateral separation grows with depth, matching the plate's vanishing
      // point instead of drifting across the road.
      const sidewalkHalfSpan = 106 + perspective * 270;
      const sidewalkWidth = 10 + perspective * 36;
      const x = 480 + pedestrian.side * (
        sidewalkHalfSpan + (pedestrian.laneOffset - 0.5) * sidewalkWidth
      );
      const y = HORIZON_Y + perspective * 350;
      const scale = 0.2 + perspective * 0.85;
      this.drawPedestrian(ctx, pedestrian.kind, x, y, scale, pedestrian.side, (phase + pedestrian.phase) % 2);
    });
  }

  private drawPedestrian(
    ctx: CanvasRenderingContext2D,
    kind: ChasePedestrianKind,
    x: number,
    y: number,
    scale: number,
    side: -1 | 1,
    frame: number
  ): void {
    if (this.isReady(this.runnerCrowdCycle) && kind === "chattingPair") {
      const crop = frame === 0 ? ROAD_HAZARD_CROPS.crowdA : ROAD_HAZARD_CROPS.crowdB;
      fillPixelEllipse(ctx, x, y - scale, 20 * scale, 4 * scale, "rgba(35,31,24,0.3)");
      this.drawSprite(ctx, this.runnerCrowdCycle, crop, x, y, 62 * scale, 0.94);
      return;
    }
    if (this.isReady(this.actorAtlas) && this.isReady(this.frontWalkerCycle) && kind === "bikePusher") {
      const walker = frame === 0 ? FRONT_WALKER_CROPS.phoneA : FRONT_WALKER_CROPS.phoneB;
      fillPixelEllipse(ctx, x, y - scale, 18 * scale, 4 * scale, "rgba(35,31,24,0.3)");
      this.drawSprite(ctx, this.actorAtlas, ACTOR_CROPS.bicycle, x + side * 10 * scale, y, 48 * scale, 0.92, side > 0);
      this.drawSprite(ctx, this.frontWalkerCycle, walker, x - side * 7 * scale, y, 60 * scale, 0.94, side > 0);
      return;
    }
    if (this.isReady(this.frontWalkerCycle) && (kind === "phoneWalker" || kind === "soyMilk")) {
      const crop = kind === "phoneWalker"
        ? (frame === 0 ? FRONT_WALKER_CROPS.phoneA : FRONT_WALKER_CROPS.phoneB)
        : (frame === 0 ? FRONT_WALKER_CROPS.soyMilkA : FRONT_WALKER_CROPS.soyMilkB);
      fillPixelEllipse(ctx, x, y - scale, 14 * scale, 3.5 * scale, "rgba(35,31,24,0.32)");
      // These walkers move down-screen as the rider closes in, so they use a
      // front three-quarter cycle. This keeps the gait consistent with their
      // apparent travel direction instead of showing rear sprites sliding feet-first.
      this.drawSprite(ctx, this.frontWalkerCycle, crop, x, y, 64 * scale, 0.94, side > 0);
      return;
    }
    const pair = kind === "chattingPair" ? 2 : 1;
    fillPixelEllipse(ctx, x, y - scale, 14 * scale, 3.5 * scale, "rgba(46,42,30,0.4)");
    for (let person = 0; person < pair; person += 1) {
      const offset = pair === 2 ? (person === 0 ? -8 : 8) * scale : 0;
      const px = x + offset;
      const step = (frame === person ? 2 : -2) * scale;
      ctx.globalAlpha = 0.92;
      ctx.fillStyle = kind === "soyMilk" ? "#c26a4e" : kind === "bikePusher" ? "#537c69" : person === 0 ? "#6b6388" : "#4f7288";
      ctx.fillRect(Math.round(px - 5 * scale), Math.round(y - 31 * scale), Math.round(10 * scale), Math.round(17 * scale));
      ctx.fillStyle = COLORS.skin;
      ctx.fillRect(Math.round(px - 4 * scale), Math.round(y - 41 * scale), Math.round(8 * scale), Math.round(9 * scale));
      ctx.fillStyle = COLORS.ink;
      ctx.fillRect(Math.round(px - 5 * scale), Math.round(y - 43 * scale), Math.round(10 * scale), Math.round(5 * scale));
      ctx.fillStyle = COLORS.pants;
      ctx.fillRect(Math.round(px - 4 * scale + step), Math.round(y - 14 * scale), Math.max(2, Math.round(3 * scale)), Math.round(13 * scale));
      ctx.fillRect(Math.round(px + 1 * scale - step), Math.round(y - 14 * scale), Math.max(2, Math.round(3 * scale)), Math.round(13 * scale));
      if (kind === "phoneWalker") {
        ctx.fillStyle = COLORS.cyan;
        ctx.fillRect(Math.round(px + side * 5 * scale), Math.round(y - 28 * scale), Math.max(2, Math.round(3 * scale)), Math.round(5 * scale));
      }
      if (kind === "soyMilk") {
        ctx.fillStyle = COLORS.white;
        ctx.fillRect(Math.round(px + side * 6 * scale), Math.round(y - 27 * scale), Math.max(2, Math.round(4 * scale)), Math.round(7 * scale));
        ctx.fillStyle = COLORS.red;
        ctx.fillRect(Math.round(px + side * 6 * scale), Math.round(y - 28 * scale), Math.max(2, Math.round(4 * scale)), Math.max(1, Math.round(2 * scale)));
      }
    }
    if (kind === "bikePusher") {
      ctx.strokeStyle = COLORS.ink;
      ctx.lineWidth = Math.max(1, 2 * scale);
      ctx.beginPath();
      ctx.ellipse(x + side * 13 * scale, y - 4 * scale, 6 * scale, 9 * scale, 0, 0, Math.PI * 2);
      ctx.stroke();
      ctx.strokeStyle = COLORS.metal;
      ctx.beginPath();
      ctx.moveTo(x + side * 8 * scale, y - 12 * scale);
      ctx.lineTo(x + side * 13 * scale, y - 4 * scale);
      ctx.stroke();
    }
    ctx.globalAlpha = 1;
  }

  private drawPaper(ctx: CanvasRenderingContext2D, distance: number): void {
    // The note wanders on gusts, tumbles, and visibly grows as the rider
    // closes the 755 m gap — it is the chase's emotional anchor.
    const progress = clamp01(distance / GOAL_DISTANCE);
    const gust = Math.sin(distance * 0.045) * 24 + Math.sin(distance * 0.013) * 36;
    const bob = this.reduceMotion ? 0 : Math.sin(distance * 0.45) * 3;
    const tumble = this.reduceMotion ? 0 : Math.sin(distance * 0.09) * 0.3;
    const scale = 0.85 + progress * 0.75;
    const px = 480 + gust;
    const py = 108 + bob + progress * 6;

    // Cyan glow trail marking it as the target.
    for (let spark = 0; spark < 5; spark += 1) {
      const trailT = spark / 5;
      const sx = px - 12 - trailT * 34 + Math.sin(distance * 0.3 + spark * 1.7) * 5;
      const sy = py + 10 + trailT * 12 + Math.cos(distance * 0.24 + spark) * 3;
      ctx.globalAlpha = 0.5 * (1 - trailT);
      ctx.fillStyle = COLORS.cyan;
      const size = Math.max(2, Math.round((4 - trailT * 2) * scale));
      ctx.fillRect(Math.round(sx), Math.round(sy), size, 2);
    }
    ctx.globalAlpha = 1;

    ctx.save();
    ctx.translate(Math.round(px), Math.round(py));
    ctx.rotate(tumble);
    ctx.scale(scale, scale);
    ctx.fillStyle = COLORS.ink;
    ctx.fillRect(-13, -10, 26, 20);
    ctx.fillStyle = COLORS.white;
    ctx.fillRect(-11, -8, 22, 16);
    ctx.fillStyle = COLORS.blue;
    ctx.fillRect(-7, -4, 12, 2);
    ctx.fillRect(-7, 0, 9, 2);
    ctx.fillRect(-7, 4, 11, 2);
    // Red seal stamp in the corner.
    ctx.fillStyle = COLORS.red;
    ctx.fillRect(4, 1, 5, 5);
    ctx.restore();
  }

  private drawObstacles(ctx: CanvasRenderingContext2D, state: ChaseRenderState): void {
    for (const obstacle of visibleObstacles(state.distance)) {
      const projection = projectObstaclePoint(obstacle, obstacle.distance - state.distance);
      if (projection.opacity < 0.28) continue;
      const pulse = this.reduceMotion ? 0 : Math.floor(state.distance * 8) % 2;
      this.drawObstacle(ctx, obstacle.kind, projection.x, projection.y, projection.scale, projection.opacity, pulse, projection.crossingSide);
    }
  }

  private drawObstacle(
    ctx: CanvasRenderingContext2D,
    kind: ChaseObstacleKind,
    x: number,
    y: number,
    scale: number,
    alpha: number,
    frame: number,
    side: -1 | 1
  ): void {
    if (this.isReady(this.runnerCrowdCycle) && (kind === "crowd" || kind === "runner")) {
      const crop = kind === "runner"
        ? (frame === 0 ? ROAD_HAZARD_CROPS.runnerA : ROAD_HAZARD_CROPS.runnerB)
        : (frame === 0 ? ROAD_HAZARD_CROPS.crowdA : ROAD_HAZARD_CROPS.crowdB);
      const targetHeight = (kind === "runner" ? 86 : 78) * Math.max(0.25, scale);
      fillPixelEllipse(ctx, x, y - scale, (kind === "crowd" ? 38 : 24) * scale, 7 * scale, "rgba(35,31,24,0.34)");
      this.drawSprite(ctx, this.runnerCrowdCycle, crop, x, y, targetHeight, alpha, kind === "runner" && side < 0);
      return;
    }
    if (this.isReady(this.actorAtlas) && kind !== "crowd" && kind !== "runner") {
      const crop = kind === "barrier"
        ? ACTOR_CROPS.barrier
        : kind === "cone"
          ? ACTOR_CROPS.cone
          : kind === "bicycle"
            ? ACTOR_CROPS.bicycle
            : ACTOR_CROPS.car;
      const targetHeight = kind === "car" ? 104 : kind === "bicycle" ? 82 : kind === "barrier" ? 66 : 72;
      fillPixelEllipse(ctx, x, y - scale, (kind === "car" ? 44 : 34) * scale, 7 * scale, "rgba(35,31,24,0.34)");
      this.drawSprite(ctx, this.actorAtlas, crop, x, y, targetHeight * Math.max(0.25, scale), alpha);
      return;
    }
    ctx.save();
    ctx.translate(Math.round(x), Math.round(y));
    ctx.scale(Math.max(0.25, scale), Math.max(0.25, scale));
    ctx.globalAlpha = alpha;
    // Lane-anchored soft shadow: reads which lane the obstacle owns.
    fillPixelEllipse(ctx, 0, -2, kind === "car" ? 46 : 34, 7, "rgba(46,42,30,0.42)");
    if (kind === "barrier") {
      // A-frame legs.
      ctx.fillStyle = COLORS.ink;
      ctx.beginPath();
      ctx.moveTo(-30, 4); ctx.lineTo(-22, 4); ctx.lineTo(-25, -26); ctx.lineTo(-31, -26); ctx.closePath();
      ctx.moveTo(22, 4); ctx.lineTo(30, 4); ctx.lineTo(31, -26); ctx.lineTo(25, -26); ctx.closePath();
      ctx.fill();
      // Striped board with sunlit top edge and dark base.
      ctx.fillStyle = COLORS.ink;
      ctx.fillRect(-38, -33, 76, 27);
      ctx.fillStyle = COLORS.amber;
      ctx.fillRect(-35, -30, 70, 19);
      ctx.fillStyle = COLORS.sunGlow;
      ctx.fillRect(-35, -30, 70, 3);
      ctx.fillStyle = COLORS.ink;
      for (let stripe = -29; stripe < 31; stripe += 16) {
        ctx.beginPath();
        ctx.moveTo(stripe, -27); ctx.lineTo(stripe + 9, -27); ctx.lineTo(stripe - 1, -13); ctx.lineTo(stripe - 10, -13); ctx.closePath();
        ctx.fill();
      }
      ctx.fillStyle = COLORS.amberDark;
      ctx.fillRect(-35, -11, 70, 3);
      // Blinking beacon.
      ctx.fillStyle = frame ? COLORS.red : COLORS.amberDark;
      ctx.fillRect(-5, -41, 10, 8);
      if (frame) {
        ctx.globalAlpha = alpha * 0.4;
        fillPixelCircle(ctx, 0, -37, 11, COLORS.red);
      }
    } else if (kind === "cone") {
      // Companion cone behind-left makes the cluster read at a glance.
      ctx.fillStyle = COLORS.ink;
      ctx.fillRect(-34, -4, 22, 5);
      ctx.fillStyle = COLORS.orange;
      ctx.beginPath();
      ctx.moveTo(-23, -30); ctx.lineTo(-14, -4); ctx.lineTo(-32, -4); ctx.closePath();
      ctx.fill();
      ctx.fillStyle = COLORS.white;
      ctx.fillRect(-28, -16, 11, 5);
      // Main cone.
      ctx.fillStyle = COLORS.ink;
      ctx.fillRect(-16, -5, 38, 7);
      ctx.fillStyle = COLORS.orange;
      ctx.beginPath();
      ctx.moveTo(2, -52); ctx.lineTo(19, -6); ctx.lineTo(-15, -6); ctx.closePath();
      ctx.fill();
      ctx.fillStyle = COLORS.orangeLight;
      ctx.beginPath();
      ctx.moveTo(2, -52); ctx.lineTo(8, -6); ctx.lineTo(-3, -6); ctx.closePath();
      ctx.fill();
      ctx.fillStyle = COLORS.white;
      ctx.fillRect(-9, -28, 22, 8);
      ctx.fillStyle = COLORS.orange;
      ctx.fillRect(-3, -55, 10, 4);
    } else if (kind === "car") {
      this.drawLongShadow(ctx, 8, 0, 56, alpha * 0.5);
      // Wheels first so the body overlaps them.
      ctx.fillStyle = COLORS.ink;
      ctx.fillRect(-44, -16, 14, 17);
      ctx.fillRect(30, -16, 14, 17);
      ctx.fillStyle = COLORS.metal;
      ctx.fillRect(-41, -10, 8, 6);
      ctx.fillRect(33, -10, 8, 6);
      // Body.
      ctx.fillStyle = COLORS.redDark;
      ctx.fillRect(-44, -56, 88, 53);
      ctx.fillStyle = COLORS.red;
      ctx.fillRect(-40, -52, 80, 42);
      // Roof and windshield.
      ctx.fillStyle = COLORS.redDark;
      ctx.fillRect(-28, -74, 56, 24);
      ctx.fillStyle = COLORS.red;
      ctx.fillRect(-26, -72, 52, 20);
      ctx.fillStyle = COLORS.glass;
      ctx.fillRect(-22, -69, 44, 17);
      ctx.fillStyle = COLORS.glassLight;
      ctx.beginPath();
      ctx.moveTo(-16, -69); ctx.lineTo(-6, -69); ctx.lineTo(-14, -52); ctx.lineTo(-22, -52); ctx.closePath();
      ctx.fill();
      // Headlights, grille, plate.
      ctx.fillStyle = COLORS.amber;
      ctx.fillRect(-36, -30, 16, 11);
      ctx.fillRect(20, -30, 16, 11);
      ctx.fillStyle = COLORS.sunCore;
      ctx.fillRect(-33, -28, 10, 6);
      ctx.fillRect(23, -28, 10, 6);
      ctx.fillStyle = COLORS.ink;
      ctx.fillRect(-14, -27, 28, 8);
      ctx.fillStyle = COLORS.white;
      ctx.fillRect(-9, -25, 18, 9);
      // Side mirrors.
      ctx.fillStyle = COLORS.redDark;
      ctx.fillRect(-50, -48, 7, 9);
      ctx.fillRect(43, -48, 7, 9);
    } else if (kind === "bicycle") {
      // Parked shared bike, side view, teal to differ from the rider's bike.
      ctx.strokeStyle = COLORS.ink;
      ctx.lineWidth = 6;
      ctx.beginPath();
      ctx.ellipse(-22, -17, 14, 17, 0, 0, Math.PI * 2);
      ctx.ellipse(22, -17, 14, 17, 0, 0, Math.PI * 2);
      ctx.stroke();
      ctx.strokeStyle = "#4aa8a2";
      ctx.lineWidth = 6;
      ctx.beginPath();
      ctx.moveTo(-22, -17); ctx.lineTo(0, -48); ctx.lineTo(22, -17);
      ctx.moveTo(0, -48); ctx.lineTo(-22, -17);
      ctx.moveTo(0, -48); ctx.lineTo(15, -48);
      ctx.stroke();
      ctx.fillStyle = COLORS.ink;
      ctx.fillRect(-7, -57, 15, 6);
      ctx.fillRect(13, -55, 5, 9);
      // Front basket with a parcel inside.
      ctx.fillStyle = COLORS.amber;
      ctx.fillRect(22, -50, 18, 15);
      ctx.fillStyle = COLORS.amberDark;
      ctx.fillRect(22, -50, 18, 4);
      ctx.fillStyle = COLORS.white;
      ctx.fillRect(26, -55, 10, 6);
      // Kickstand.
      ctx.strokeStyle = COLORS.ink;
      ctx.lineWidth = 4;
      ctx.beginPath();
      ctx.moveTo(-9, -15); ctx.lineTo(-16, 0);
      ctx.stroke();
    } else if (kind === "crowd") {
      const walkers = [
        { offset: -24, height: 0, color: "#6777a1", wave: false },
        { offset: 0, height: 4, color: "#c26a4e", wave: true },
        { offset: 23, height: -2, color: "#537c69", wave: false }
      ];
      walkers.forEach((walker, index) => {
        const lift = walker.height;
        fillPixelEllipse(ctx, walker.offset, -2, 13, 4, "rgba(46,42,30,0.35)");
        ctx.fillStyle = walker.color;
        ctx.fillRect(walker.offset - 10, -44 - lift, 20, 35);
        ctx.fillStyle = COLORS.skin;
        ctx.fillRect(walker.offset - 7, -57 - lift, 14, 13);
        ctx.fillStyle = COLORS.ink;
        ctx.fillRect(walker.offset - 8, -61 - lift, 16, 6);
        if (walker.wave) {
          // Middle figure waves an arm on alternating frames.
          ctx.fillStyle = walker.color;
          if (frame) ctx.fillRect(walker.offset + 10, -66 - lift, 6, 18);
          else ctx.fillRect(walker.offset + 10, -52 - lift, 12, 6);
          ctx.fillStyle = COLORS.skin;
          if (frame) ctx.fillRect(walker.offset + 10, -70 - lift, 6, 5);
        }
        void index;
      });
    } else {
      // Crossing runner, leaning into the sprint with motion streaks.
      const direction = side < 0 ? -1 : 1;
      ctx.globalAlpha = alpha * 0.35;
      ctx.fillStyle = COLORS.white;
      ctx.fillRect(-direction * 26, -44, direction * 16, 3);
      ctx.fillRect(-direction * 30, -34, direction * 20, 3);
      ctx.globalAlpha = alpha;
      ctx.fillStyle = "#705f92";
      ctx.fillRect(-10, -50, 20, 30);
      ctx.fillStyle = COLORS.skin;
      ctx.fillRect(-7, -62, 14, 12);
      ctx.fillStyle = COLORS.ink;
      ctx.fillRect(-9, -66, 18, 6);
      // White headband flashing on the sprint.
      ctx.fillStyle = COLORS.white;
      ctx.fillRect(-9, -60, 18, 3);
      ctx.fillStyle = COLORS.ink;
      ctx.fillRect(-7 - direction * frame * 6, -21, 7, 23);
      ctx.fillRect(direction * 4 + direction * frame * 6, -21, 7, 23);
      ctx.fillStyle = COLORS.white;
      ctx.fillRect(-11 - direction * frame * 6, -1, 12, 5);
      ctx.fillRect(direction * 3 + direction * frame * 6, -1, 12, 5);
    }
    ctx.restore();
    ctx.globalAlpha = 1;
  }

  private drawRider(ctx: CanvasRenderingContext2D, state: ChaseRenderState, deltaMs: number): void {
    const targetX = 480 + (state.lane - 1) * 238;
    this.riderX += (targetX - this.riderX) * Math.min(1, deltaMs / 180);
    const frame = state.runState === "running" && !this.reduceMotion
      ? Math.floor(this.animationMs / 72) % (RIDER_CROPS.length + 4)
      : 1;
    const remainingTurn = targetX - this.riderX;
    const turnDistance = Math.abs(remainingTurn);
    const turning = turnDistance > 8 && this.isReady(this.riderTurnCycle);
    const lean = turning ? 0 : Math.max(-4, Math.min(4, remainingTurn * 0.03));
    const sway = state.runState === "running" && !this.reduceMotion ? Math.sin(frame * Math.PI * 0.5) * 1.4 : 0;
    const pedal = Math.sin(frame * Math.PI * 0.5);
    const x = Math.round(this.riderX);
    const y = 506;
    if (this.isReady(this.riderCycle)) {
      const alpha = state.invulnerableMs > 0
        ? (this.reduceMotion || Math.floor(state.invulnerableMs / 110) % 2 === 0 ? 0.48 : 0.82)
        : 1;
      fillPixelEllipse(ctx, x, y - 2, 38, 7, "rgba(22,17,10,0.44)");
      ctx.save();
      ctx.translate(x, y);
      ctx.rotate(((lean + sway) * Math.PI) / 180);
      if (turning) {
        // The generated sheet is authored from the rider's rear view. Screen-
        // left steering therefore consumes its visually right-facing row, and
        // screen-right consumes the visually left-facing row.
        const row: 0 | 2 = remainingTurn < 0 ? 2 : 0;
        const column: 0 | 1 | 2 | 3 = turnDistance > 150
          ? 0
          : turnDistance > 85
            ? 1
            : turnDistance > 30
              ? 2
              : 3;
        this.drawSprite(ctx, this.riderTurnCycle, riderTurnCrop(row, column), 0, 0, 183, alpha);
      } else if (frame < RIDER_CROPS.length) {
        this.drawSprite(ctx, this.riderCycle, RIDER_CROPS[frame], 0, 0, 174, alpha);
      } else {
        const column = (frame - RIDER_CROPS.length) as 0 | 1 | 2 | 3;
        this.drawSprite(ctx, this.riderTurnCycle, riderTurnCrop(1, column), 0, 0, 183, alpha);
      }
      ctx.restore();
      return;
    }
    ctx.save();
    ctx.translate(x, y);
    ctx.rotate(((lean + sway) * Math.PI) / 180);
    ctx.scale(0.8, 0.8);
    ctx.globalAlpha = state.invulnerableMs > 0
      ? (this.reduceMotion || Math.floor(state.invulnerableMs / 110) % 2 === 0 ? 0.48 : 0.82)
      : 1;

    // Contact shadow plus a long morning shadow trailing left.
    fillPixelEllipse(ctx, 0, -2, 46, 9, "rgba(22,17,10,0.5)");
    ctx.globalAlpha *= 0.35;
    ctx.fillStyle = COLORS.shadow;
    ctx.beginPath();
    ctx.moveTo(-16, -3); ctx.lineTo(16, -3); ctx.lineTo(-58, 16); ctx.lineTo(-84, 12); ctx.closePath();
    ctx.fill();
    ctx.globalAlpha = state.invulnerableMs > 0
      ? (this.reduceMotion || Math.floor(state.invulnerableMs / 110) % 2 === 0 ? 0.48 : 0.82)
      : 1;

    // Rear wheel: tire ring, rim, and spinning spokes.
    strokePixelEllipse(ctx, 0, -24, 14, 32, 5, COLORS.ink);
    strokePixelEllipse(ctx, 0, -24, 9, 26, 3, COLORS.metal);
    const spin = state.runState === "running" ? state.distance * 2.2 : 0;
    ctx.strokeStyle = COLORS.metal;
    ctx.lineWidth = 2;
    ctx.globalAlpha *= 0.7;
    for (const angle of [spin, spin + Math.PI / 2]) {
      ctx.save();
      ctx.translate(0, -24);
      ctx.rotate(angle);
      ctx.beginPath();
      ctx.moveTo(0, -24); ctx.lineTo(0, 24);
      ctx.stroke();
      ctx.restore();
    }
    ctx.globalAlpha = state.invulnerableMs > 0
      ? (this.reduceMotion || Math.floor(state.invulnerableMs / 110) % 2 === 0 ? 0.48 : 0.82)
      : 1;

    // Frame, rear rack, fender, and crank.
    ctx.strokeStyle = COLORS.amber;
    ctx.lineWidth = 6;
    ctx.beginPath();
    ctx.moveTo(-26, -62); ctx.lineTo(0, -26); ctx.lineTo(26, -62);
    ctx.stroke();
    ctx.fillStyle = COLORS.ink;
    ctx.fillRect(-8, -68, 16, 6);
    ctx.fillRect(-30, -64, 60, 6);
    ctx.fillStyle = COLORS.amberDark;
    ctx.fillRect(-16, -58, 32, 4);
    ctx.fillStyle = COLORS.red;
    ctx.fillRect(12, -57, 5, 4);
    fillPixelCircle(ctx, 0, -34, 6, COLORS.ink);

    // Pedals and pumping legs: feet ride the crank circle.
    const leftLift = Math.round(pedal * 9);
    const rightLift = -leftLift;
    const stride = frame % 2 === 0 ? 2 : -2;
    ctx.fillStyle = COLORS.ink;
    ctx.fillRect(-13 + stride, -38 + leftLift, 12, 5);
    ctx.fillRect(1 - stride, -38 + rightLift, 12, 5);
    ctx.fillStyle = COLORS.pants;
    ctx.fillRect(-19 + stride, -76, 12, 40 + leftLift);
    ctx.fillRect(7 - stride, -76, 12, 40 + rightLift);
    ctx.fillStyle = COLORS.white;
    ctx.fillRect(-22 + stride, -40 + leftLift, 19, 8);
    ctx.fillRect(3 - stride, -40 + rightLift, 19, 8);
    ctx.fillStyle = COLORS.ink;
    ctx.fillRect(-22 + stride, -34 + leftLift, 19, 3);
    ctx.fillRect(3 - stride, -34 + rightLift, 19, 3);

    // Slim jacket torso; the bottom hem flickers in the wind.
    ctx.fillStyle = COLORS.blue;
    ctx.fillRect(-23, -122, 46, 52);
    ctx.fillRect(-20, -126, 40, 6);
    ctx.fillStyle = COLORS.blueDark;
    ctx.fillRect(-2, -122, 4, 52);
    ctx.fillStyle = COLORS.blueLight;
    ctx.fillRect(-23, -86, 46, 7);
    ctx.fillStyle = COLORS.blueDark;
    if (!this.reduceMotion && frame % 2 === 1) {
      ctx.fillRect(-23, -71, 46, 3);
    } else {
      ctx.fillRect(-23, -70, 23, 2);
      ctx.fillRect(4, -72, 19, 2);
    }

    // Backpack with shoulder straps.
    ctx.fillStyle = "#2e445f";
    ctx.fillRect(-17, -115, 34, 30);
    ctx.fillStyle = "#1a2839";
    ctx.fillRect(-17, -115, 34, 6);
    ctx.fillStyle = COLORS.blueDark;
    ctx.fillRect(-15, -122, 7, 20);
    ctx.fillRect(8, -122, 7, 20);
    ctx.fillStyle = COLORS.cyan;
    ctx.fillRect(-3, -103, 6, 4);

    // Arms in a darker blue so they read apart from the torso; hands on grips.
    ctx.fillStyle = COLORS.blueDark;
    ctx.fillRect(-33, -114, 9, 38);
    ctx.fillRect(24, -114, 9, 38);
    ctx.fillStyle = COLORS.skin;
    ctx.fillRect(-32, -80, 8, 7);
    ctx.fillRect(24, -80, 8, 7);
    ctx.fillStyle = COLORS.ink;
    ctx.fillRect(-40, -76, 80, 6);
    ctx.fillRect(-43, -77, 7, 8);
    ctx.fillRect(36, -77, 7, 8);

    // Head: dark hair, amber headband with a cyan glint.
    ctx.fillStyle = COLORS.skin;
    ctx.fillRect(-16, -150, 32, 25);
    ctx.fillStyle = COLORS.skinShade;
    ctx.fillRect(-16, -136, 32, 4);
    ctx.fillStyle = COLORS.ink;
    ctx.fillRect(-20, -160, 40, 16);
    ctx.fillRect(-20, -148, 6, 10);
    ctx.fillRect(14, -148, 6, 10);
    ctx.fillStyle = COLORS.amber;
    ctx.fillRect(-20, -152, 40, 5);
    ctx.fillStyle = COLORS.cyan;
    ctx.fillRect(-4, -152, 8, 4);
    ctx.restore();
    ctx.globalAlpha = 1;
  }

  private drawSpeedTicks(ctx: CanvasRenderingContext2D, distance: number): void {
    // Edge streaks grow longer and brighter as the pace picks up.
    const urgency = clamp01(distance / GOAL_DISTANCE);
    ctx.fillStyle = COLORS.white;
    for (let index = 0; index < 6; index += 1) {
      const y = 200 + ((distance * 28 + index * 73) % 310);
      const side = index % 2 === 0 ? -1 : 1;
      const x = 480 + side * (216 + (y - 200) * 0.56);
      ctx.globalAlpha = 0.08 + urgency * 0.12;
      ctx.fillRect(Math.round(x), Math.round(y), Math.round(38 + urgency * 30), 2);
    }
    ctx.globalAlpha = 1;
  }

  private drawWheelSpray(ctx: CanvasRenderingContext2D, distance: number): void {
    // Dust and leaf flecks kicked off the rear wheel, deterministic per
    // distance so frames stay reproducible.
    for (let index = 0; index < 8; index += 1) {
      const cycle = ((distance * 1.1 + index * 29) % 90) / 90;
      const side = index % 2 === 0 ? -1 : 1;
      const px = this.riderX + side * (12 + cycle * 40) + Math.sin(index * 2.3) * 6;
      const py = 496 + cycle * 26 - (index % 3) * 4;
      ctx.globalAlpha = (1 - cycle) * 0.45;
      ctx.fillStyle = index % 3 === 0 ? COLORS.treeGold : index % 3 === 1 ? "#cfc4a4" : COLORS.grassLight;
      const size = Math.max(2, Math.round(2 + cycle * 3));
      ctx.fillRect(Math.round(px), Math.round(py), size, size);
    }
    ctx.globalAlpha = 1;
  }

  private drawCollisionFlash(ctx: CanvasRenderingContext2D, state: ChaseRenderState, now: number): void {
    if (state.collisions > this.lastCollisions) this.flashStart = now;
    this.lastCollisions = state.collisions;
    const progress = (now - this.flashStart) / 240;
    if (progress >= 1) return;
    ctx.globalAlpha = 0.24 * (1 - progress);
    ctx.fillStyle = COLORS.red;
    ctx.fillRect(0, 0, LOGICAL_WIDTH, LOGICAL_HEIGHT);
    ctx.globalAlpha = 1;
  }
}

/**
 * Runtime selector: the authored 3D world is primary. The previous canvas
 * renderer remains a capability fallback for browsers without WebGL.
 */
export class ChaseRenderer implements ChaseRendererBackend {
  private readonly backend: ChaseRendererBackend;

  constructor(canvas: HTMLCanvasElement) {
    try {
      this.backend = new ChaseThreeRenderer(canvas);
      canvas.dataset.chaseRenderer = "three";
    } catch {
      this.backend = new ChaseCanvasRenderer(canvas);
      canvas.dataset.chaseRenderer = "canvas-fallback";
    }
  }

  destroy(): void {
    this.backend.destroy();
  }

  setReducedMotion(reduced: boolean): void {
    this.backend.setReducedMotion(reduced);
  }

  render(state: ChaseRenderState): void {
    this.backend.render(state);
  }
}
