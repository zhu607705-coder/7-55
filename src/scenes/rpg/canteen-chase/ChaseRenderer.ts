import {
  projectObstaclePoint,
  visibleObstacles,
  visiblePedestrians,
  VISIBLE_DISTANCE,
  type ChaseObstacleKind,
  type ChasePedestrianKind
} from "./ChaseGeometry";

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
const HORIZON_Y = 136;
const BUFFER_MIN_WIDTH = 480;
const BUFFER_MAX_WIDTH = 960;

const COLORS = {
  skyTop: "#9bc6d1",
  skyMid: "#bdd8d5",
  skyLow: "#dce4cf",
  mist: "#edf0dc",
  road: "#34434a",
  roadDark: "#29373d",
  lane: "#e8ebdd",
  curb: "#cbd0bb",
  grass: "#557d55",
  grassDark: "#3e6749",
  sidewalk: "#a9aa97",
  sidewalkLight: "#c2c1aa",
  ink: "#17252b",
  blue: "#315e8a",
  blueLight: "#6aa9bd",
  amber: "#e3c45e",
  amberDark: "#8f7630",
  red: "#c65d52",
  white: "#f2f0df",
  skin: "#d7a56e",
  tree: "#3b7047",
  treeLight: "#6f9557",
  trunk: "#674931",
  cyan: "#75d5dc"
} as const;

function clamp01(value: number): number {
  return Math.max(0, Math.min(1, value));
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

export class ChaseRenderer {
  private readonly canvas: HTMLCanvasElement;
  private readonly ctx: CanvasRenderingContext2D;
  private readonly background: HTMLCanvasElement;
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
    this.background = document.createElement("canvas");
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
    const ctx = this.ctx;
    ctx.imageSmoothingEnabled = false;
    ctx.setTransform(this.scale, 0, 0, this.scale, 0, 0);
    ctx.globalAlpha = 1;
    ctx.drawImage(this.background, 0, 0, LOGICAL_WIDTH, LOGICAL_HEIGHT);
    this.drawRoadMotion(ctx, state.distance);
    this.drawRoadside(ctx, state.distance);
    this.drawPedestrians(ctx, state.distance);
    this.drawPaper(ctx, state.distance);
    this.drawObstacles(ctx, state);
    this.drawRider(ctx, state, deltaMs);
    if (state.runState === "running" && !this.reduceMotion) this.drawSpeedTicks(ctx, state.distance);
    this.drawCollisionFlash(ctx, state, now);
    ctx.globalAlpha = 1;
  }

  private handleResize(): void {
    const cssWidth = this.canvas.clientWidth || LOGICAL_WIDTH;
    // Keep the logical 960 px scene at native resolution on desktop. The
    // previous half-width backing store doubled every authored pixel and made
    // the rider, pedestrians, and obstacle silhouettes look unfinished.
    const width = Math.max(BUFFER_MIN_WIDTH, Math.min(BUFFER_MAX_WIDTH, Math.round(cssWidth)));
    const height = Math.round((width * 9) / 16);
    if (this.canvas.width === width && this.canvas.height === height) return;
    this.canvas.width = width;
    this.canvas.height = height;
    this.scale = width / LOGICAL_WIDTH;
    this.background.width = width;
    this.background.height = height;
    this.buildBackground();
  }

  private buildBackground(): void {
    const ctx = this.background.getContext("2d");
    if (!ctx) return;
    ctx.imageSmoothingEnabled = false;
    ctx.setTransform(this.scale, 0, 0, this.scale, 0, 0);

    ctx.fillStyle = COLORS.skyTop;
    ctx.fillRect(0, 0, LOGICAL_WIDTH, 46);
    ctx.fillStyle = COLORS.skyMid;
    ctx.fillRect(0, 46, LOGICAL_WIDTH, 44);
    ctx.fillStyle = COLORS.skyLow;
    ctx.fillRect(0, 90, LOGICAL_WIDTH, 46);
    ctx.fillStyle = COLORS.mist;
    for (let x = 0; x < LOGICAL_WIDTH; x += 12) ctx.fillRect(x, 87 + (x % 24 === 0 ? 0 : 2), 6, 2);

    this.drawDistantCampus(ctx);

    ctx.fillStyle = COLORS.grass;
    ctx.fillRect(0, HORIZON_Y, LOGICAL_WIDTH, LOGICAL_HEIGHT - HORIZON_Y);
    ctx.fillStyle = COLORS.grassDark;
    ctx.fillRect(0, HORIZON_Y + 18, LOGICAL_WIDTH, 7);

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
      ctx.fillStyle = index % 2 === 0 ? COLORS.roadDark : "#46545a";
      ctx.globalAlpha = 0.26;
      ctx.fillRect(x, y, 2, 1);
    }
    ctx.restore();
    ctx.globalAlpha = 1;

    ctx.strokeStyle = COLORS.curb;
    ctx.lineWidth = 5;
    ctx.beginPath();
    ctx.moveTo(404, HORIZON_Y); ctx.lineTo(110, LOGICAL_HEIGHT);
    ctx.moveTo(556, HORIZON_Y); ctx.lineTo(850, LOGICAL_HEIGHT);
    ctx.stroke();
    ctx.strokeStyle = COLORS.white;
    ctx.lineWidth = 2;
    ctx.globalAlpha = 0.7;
    ctx.beginPath();
    ctx.moveTo(410, HORIZON_Y); ctx.lineTo(124, LOGICAL_HEIGHT);
    ctx.moveTo(550, HORIZON_Y); ctx.lineTo(836, LOGICAL_HEIGHT);
    ctx.stroke();
    ctx.globalAlpha = 1;
  }

  private drawDistantCampus(ctx: CanvasRenderingContext2D): void {
    ctx.fillStyle = "#738d8b";
    ctx.fillRect(46, 92, 242, 44);
    ctx.fillRect(672, 84, 232, 52);
    ctx.fillStyle = "#d7dacd";
    ctx.fillRect(54, 98, 226, 38);
    ctx.fillRect(680, 90, 216, 46);
    ctx.fillStyle = "#42656b";
    for (let x = 66; x < 270; x += 30) {
      ctx.fillRect(x, 108, 18, 14);
      ctx.fillStyle = "#8ca4a1";
      ctx.fillRect(x + 2, 110, 5, 3);
      ctx.fillStyle = "#42656b";
    }
    for (let x = 694; x < 888; x += 30) {
      ctx.fillRect(x, 103, 18, 14);
      ctx.fillStyle = "#8ca4a1";
      ctx.fillRect(x + 2, 105, 5, 3);
      ctx.fillStyle = "#42656b";
    }
    ctx.fillStyle = "#8e4f42";
    ctx.fillRect(54, 98, 226, 5);
    ctx.fillRect(680, 90, 216, 5);
    ctx.fillStyle = "#66483b";
    for (let x = 58; x < 278; x += 22) ctx.fillRect(x, 101, 12, 2);
    for (let x = 684; x < 898; x += 22) ctx.fillRect(x, 93, 12, 2);
    ctx.fillStyle = COLORS.ink;
    ctx.fillRect(440, 104, 80, 32);
    ctx.fillStyle = COLORS.white;
    ctx.fillRect(448, 110, 64, 18);
    ctx.fillStyle = COLORS.blue;
    ctx.fillRect(474, 113, 12, 15);
    for (let x = 300; x <= 650; x += 34) {
      fillPixelCircle(ctx, x, 124, 18, COLORS.tree);
      fillPixelCircle(ctx, x - 5, 119, 10, COLORS.treeLight);
    }
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
        if ((worldIndex + (side > 0 ? 1 : 0)) % 4 === 0) {
          this.drawLamp(ctx, x, y, size, side, alpha);
        } else {
          this.drawTree(ctx, x, y, size, alpha);
        }
      }
    }
  }

  private drawTree(ctx: CanvasRenderingContext2D, x: number, y: number, scale: number, alpha: number): void {
    ctx.globalAlpha = alpha;
    ctx.fillStyle = "#233b32";
    ctx.fillRect(Math.round(x - 18 * scale), Math.round(y - 4 * scale), Math.round(36 * scale), Math.max(2, Math.round(5 * scale)));
    ctx.fillStyle = COLORS.trunk;
    ctx.fillRect(Math.round(x - 3 * scale), Math.round(y - 38 * scale), Math.max(2, Math.round(6 * scale)), Math.round(36 * scale));
    fillPixelCircle(ctx, x, y - 54 * scale, Math.max(4, Math.round(22 * scale)), COLORS.tree);
    fillPixelCircle(ctx, x - 12 * scale, y - 48 * scale, Math.max(3, Math.round(14 * scale)), COLORS.tree);
    fillPixelCircle(ctx, x + 13 * scale, y - 49 * scale, Math.max(3, Math.round(13 * scale)), COLORS.treeLight);
    ctx.globalAlpha = 1;
  }

  private drawLamp(ctx: CanvasRenderingContext2D, x: number, y: number, scale: number, side: -1 | 1, alpha: number): void {
    ctx.globalAlpha = alpha;
    ctx.fillStyle = "#26373a";
    ctx.fillRect(Math.round(x - 10 * scale), Math.round(y - 3 * scale), Math.round(20 * scale), Math.max(2, Math.round(4 * scale)));
    ctx.fillRect(Math.round(x - 2 * scale), Math.round(y - 64 * scale), Math.max(2, Math.round(4 * scale)), Math.round(62 * scale));
    const armX = side < 0 ? x + 2 * scale : x - 22 * scale;
    ctx.fillRect(Math.round(armX), Math.round(y - 64 * scale), Math.round(22 * scale), Math.max(2, Math.round(3 * scale)));
    ctx.fillStyle = COLORS.amber;
    ctx.fillRect(Math.round(side < 0 ? x + 18 * scale : x - 22 * scale), Math.round(y - 61 * scale), Math.max(2, Math.round(7 * scale)), Math.max(2, Math.round(5 * scale)));
    ctx.globalAlpha = 1;
  }

  private drawPedestrians(ctx: CanvasRenderingContext2D, distance: number): void {
    const pedestrians = visiblePedestrians(distance).slice(-4);
    const phase = this.reduceMotion ? 0 : Math.floor(distance * 0.12) % 2;
    pedestrians.forEach((pedestrian) => {
      const ahead = pedestrian.distance - distance;
      const depth = clamp01(1 - ahead / VISIBLE_DISTANCE);
      const perspective = depth * depth;
      const x = 480 + pedestrian.side * (96 + perspective * 335 + (pedestrian.laneOffset - 0.5) * 18);
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
    const pair = kind === "chattingPair" ? 2 : 1;
    for (let person = 0; person < pair; person += 1) {
      const offset = pair === 2 ? (person === 0 ? -8 : 8) * scale : 0;
      const px = x + offset;
      const step = (frame === person ? 2 : -2) * scale;
      ctx.globalAlpha = 0.88;
      ctx.fillStyle = "#203136";
      ctx.fillRect(Math.round(px - 8 * scale), Math.round(y - 2 * scale), Math.round(16 * scale), Math.max(2, Math.round(3 * scale)));
      ctx.fillStyle = kind === "soyMilk" ? "#a96545" : kind === "bikePusher" ? "#537c69" : person === 0 ? "#6b6388" : "#4f7288";
      ctx.fillRect(Math.round(px - 5 * scale), Math.round(y - 31 * scale), Math.round(10 * scale), Math.round(17 * scale));
      ctx.fillStyle = COLORS.skin;
      ctx.fillRect(Math.round(px - 4 * scale), Math.round(y - 41 * scale), Math.round(8 * scale), Math.round(9 * scale));
      ctx.fillStyle = COLORS.ink;
      ctx.fillRect(Math.round(px - 5 * scale), Math.round(y - 43 * scale), Math.round(10 * scale), Math.round(5 * scale));
      ctx.fillRect(Math.round(px - 4 * scale + step), Math.round(y - 14 * scale), Math.max(2, Math.round(3 * scale)), Math.round(13 * scale));
      ctx.fillRect(Math.round(px + 1 * scale - step), Math.round(y - 14 * scale), Math.max(2, Math.round(3 * scale)), Math.round(13 * scale));
      if (kind === "phoneWalker") {
        ctx.fillStyle = COLORS.cyan;
        ctx.fillRect(Math.round(px + side * 5 * scale), Math.round(y - 28 * scale), Math.max(2, Math.round(3 * scale)), Math.round(5 * scale));
      }
      if (kind === "soyMilk") {
        ctx.fillStyle = COLORS.white;
        ctx.fillRect(Math.round(px + side * 6 * scale), Math.round(y - 27 * scale), Math.max(2, Math.round(4 * scale)), Math.round(7 * scale));
      }
    }
    if (kind === "bikePusher") {
      ctx.strokeStyle = COLORS.ink;
      ctx.lineWidth = Math.max(1, 2 * scale);
      ctx.beginPath();
      ctx.ellipse(x + side * 13 * scale, y - 4 * scale, 6 * scale, 9 * scale, 0, 0, Math.PI * 2);
      ctx.stroke();
    }
    ctx.globalAlpha = 1;
  }

  private drawPaper(ctx: CanvasRenderingContext2D, distance: number): void {
    const bob = this.reduceMotion ? 0 : Math.round(Math.sin(distance * 0.45) * 3);
    ctx.fillStyle = COLORS.cyan;
    ctx.globalAlpha = 0.28;
    ctx.fillRect(448, 114 + bob, 18, 2);
    ctx.fillRect(427, 118 + bob, 12, 2);
    ctx.globalAlpha = 1;
    ctx.fillStyle = COLORS.ink;
    ctx.fillRect(469, 102 + bob, 23, 17);
    ctx.fillStyle = COLORS.white;
    ctx.fillRect(472, 104 + bob, 18, 13);
    ctx.fillStyle = COLORS.blue;
    ctx.fillRect(476, 108 + bob, 10, 2);
    ctx.fillRect(476, 112 + bob, 7, 2);
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
    ctx.save();
    ctx.translate(Math.round(x), Math.round(y));
    ctx.scale(Math.max(0.25, scale), Math.max(0.25, scale));
    ctx.globalAlpha = alpha;
    ctx.fillStyle = "rgba(19,31,35,0.34)";
    ctx.fillRect(-34, -4, 68, 7);
    if (kind === "barrier") {
      ctx.fillStyle = COLORS.ink;
      ctx.fillRect(-37, -31, 74, 25);
      ctx.fillStyle = COLORS.amber;
      ctx.fillRect(-34, -28, 68, 18);
      ctx.fillStyle = COLORS.ink;
      for (let stripe = -28; stripe < 30; stripe += 16) {
        ctx.beginPath();
        ctx.moveTo(stripe, -28); ctx.lineTo(stripe + 9, -28); ctx.lineTo(stripe - 1, -10); ctx.lineTo(stripe - 10, -10); ctx.closePath();
        ctx.fill();
      }
      ctx.fillRect(-28, -9, 6, 14);
      ctx.fillRect(22, -9, 6, 14);
      ctx.fillStyle = frame ? COLORS.red : COLORS.amberDark;
      ctx.fillRect(-5, -39, 10, 8);
    } else if (kind === "cone") {
      ctx.fillStyle = COLORS.ink;
      ctx.fillRect(-18, -5, 36, 7);
      ctx.fillStyle = "#df7c3f";
      ctx.beginPath();
      ctx.moveTo(0, -49); ctx.lineTo(16, -7); ctx.lineTo(-16, -7); ctx.closePath();
      ctx.fill();
      ctx.fillStyle = COLORS.white;
      ctx.fillRect(-10, -25, 20, 7);
    } else if (kind === "car") {
      ctx.fillStyle = COLORS.ink;
      ctx.fillRect(-42, -54, 84, 51);
      ctx.fillStyle = COLORS.red;
      ctx.fillRect(-38, -50, 76, 42);
      ctx.fillStyle = "#385762";
      ctx.fillRect(-26, -68, 52, 25);
      ctx.fillStyle = COLORS.amber;
      ctx.fillRect(-33, -27, 16, 10);
      ctx.fillRect(17, -27, 16, 10);
      ctx.fillStyle = COLORS.white;
      ctx.fillRect(-9, -19, 18, 9);
    } else if (kind === "bicycle") {
      ctx.strokeStyle = COLORS.ink;
      ctx.lineWidth = 5;
      ctx.beginPath();
      ctx.ellipse(0, -17, 14, 24, 0, 0, Math.PI * 2);
      ctx.stroke();
      ctx.fillStyle = COLORS.cyan;
      ctx.fillRect(-4, -61, 8, 43);
      ctx.fillRect(-24, -60, 48, 7);
      ctx.fillStyle = COLORS.amber;
      ctx.fillRect(-17, -76, 34, 16);
    } else if (kind === "crowd") {
      [-22, 0, 22].forEach((offset, index) => {
        ctx.fillStyle = index === 0 ? "#6777a1" : index === 1 ? "#a25c4e" : "#537c69";
        ctx.fillRect(offset - 10, -44 - (index % 2) * 3, 20, 35);
        ctx.fillStyle = COLORS.skin;
        ctx.fillRect(offset - 7, -57 - (index % 2) * 3, 14, 13);
        ctx.fillStyle = COLORS.ink;
        ctx.fillRect(offset - 8, -61 - (index % 2) * 3, 16, 6);
      });
    } else {
      const direction = side < 0 ? -1 : 1;
      ctx.fillStyle = "#705f92";
      ctx.fillRect(-10, -48, 20, 28);
      ctx.fillStyle = COLORS.skin;
      ctx.fillRect(-7, -60, 14, 12);
      ctx.fillStyle = COLORS.ink;
      ctx.fillRect(-9, -64, 18, 6);
      ctx.fillRect(-7 - direction * frame * 5, -20, 7, 22);
      ctx.fillRect(direction * 4 + direction * frame * 5, -20, 7, 22);
      ctx.fillStyle = COLORS.white;
      ctx.fillRect(-11 - direction * frame * 5, -1, 12, 5);
      ctx.fillRect(direction * 3 + direction * frame * 5, -1, 12, 5);
    }
    ctx.restore();
    ctx.globalAlpha = 1;
  }

  private drawRider(ctx: CanvasRenderingContext2D, state: ChaseRenderState, deltaMs: number): void {
    const targetX = 480 + (state.lane - 1) * 238;
    this.riderX += (targetX - this.riderX) * Math.min(1, deltaMs / 105);
    const frame = state.runState === "running" ? Math.floor(state.distance * 5) % 4 : 1;
    const lean = Math.max(-6, Math.min(6, (targetX - this.riderX) * 0.045));
    const x = Math.round(this.riderX);
    const y = 506;
    ctx.save();
    ctx.translate(x, y);
    ctx.rotate((lean * Math.PI) / 180);
    ctx.scale(0.78, 0.78);
    ctx.globalAlpha = state.invulnerableMs > 0
      ? (this.reduceMotion || Math.floor(state.invulnerableMs / 110) % 2 === 0 ? 0.48 : 0.82)
      : 1;
    ctx.fillStyle = "rgba(16,28,32,0.45)";
    ctx.fillRect(-45, -7, 90, 9);
    ctx.strokeStyle = COLORS.ink;
    ctx.lineWidth = 8;
    ctx.beginPath();
    ctx.ellipse(0, -22, 17, 38, 0, 0, Math.PI * 2);
    ctx.stroke();
    ctx.strokeStyle = COLORS.amber;
    ctx.lineWidth = 6;
    ctx.beginPath();
    ctx.moveTo(-24, -58); ctx.lineTo(0, -25); ctx.lineTo(24, -58); ctx.lineTo(-24, -58);
    ctx.stroke();
    ctx.fillStyle = COLORS.ink;
    ctx.fillRect(-34, -64, 68, 8);
    ctx.fillRect(-10, -31, 20, 8);
    const legShift = frame < 2 ? -7 : 7;
    ctx.fillRect(-20 + legShift, -73, 14, 39);
    ctx.fillRect(6 - legShift, -73, 14, 39);
    ctx.fillStyle = COLORS.white;
    ctx.fillRect(-23 + legShift, -37, 20, 7);
    ctx.fillRect(3 - legShift, -37, 20, 7);
    ctx.fillStyle = COLORS.blue;
    ctx.fillRect(-29, -119, 58, 54);
    ctx.fillStyle = COLORS.blueLight;
    ctx.fillRect(-29, -84, 58, 8);
    ctx.fillStyle = COLORS.ink;
    ctx.fillRect(-39, -111, 12, 43);
    ctx.fillRect(27, -111, 12, 43);
    ctx.fillRect(-42, -70, 84, 8);
    ctx.fillStyle = "#294254";
    ctx.fillRect(-21, -112, 42, 32);
    ctx.fillStyle = COLORS.skin;
    ctx.fillRect(-17, -146, 34, 27);
    ctx.fillStyle = COLORS.ink;
    ctx.fillRect(-22, -157, 44, 18);
    ctx.fillStyle = COLORS.amber;
    ctx.fillRect(-19, -161, 38, 8);
    ctx.fillStyle = COLORS.cyan;
    ctx.fillRect(-4, -158, 8, 5);
    ctx.restore();
    ctx.globalAlpha = 1;
  }

  private drawSpeedTicks(ctx: CanvasRenderingContext2D, distance: number): void {
    ctx.fillStyle = COLORS.white;
    for (let index = 0; index < 4; index += 1) {
      const y = 210 + ((distance * 28 + index * 87) % 300);
      const side = index % 2 === 0 ? -1 : 1;
      const x = 480 + side * (220 + (y - 210) * 0.56);
      ctx.globalAlpha = 0.1;
      ctx.fillRect(Math.round(x), Math.round(y), 38, 2);
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
