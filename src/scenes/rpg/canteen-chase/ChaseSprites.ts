// Pixel-art sprite baking for the canteen bike chase scene.
// Every sprite is authored in code at 1px = 1 sprite unit and baked once
// into a small canvas; the renderer upscales with smoothing disabled.

type PixelContext = CanvasRenderingContext2D;

const INK = "#141c24";
const DARK = "#26333b";
const NAVY = "#1d2d42";
const NAVY_L = "#263b56";
const METAL = "#7c8a92";
const METAL_D = "#4a565e";
const SKIN = "#d8a76e";
const HAIR = "#20262d";
const BLUE = "#2f5d9e";
const BLUE_D = "#1f3f6e";
const CYAN = "#75d5dc";
const YELLOW = "#f0d54e";
const YELLOW_D = "#c9a92e";
const RED = "#e05a4e";
const RED_D = "#9e3530";
const ORANGE = "#ef7d3a";
const ORANGE_D = "#bf5828";
const PURPLE = "#756aa9";
const PURPLE_D = "#55488a";
const CORAL = "#e97b70";
const CORAL_D = "#b2554e";
const WHITE = "#f2ede0";
const AMBER = "#ffe79a";
const GLASS = "#385b6d";
const TRUNK = "#6d4b32";
const TRUNK_D = "#4c3523";
const LEAF = "#3f8147";
const LEAF_D = "#2a5c38";
const LEAF_L = "#a3cf70";
const WALL = "#cfc6b4";
const BRICK = "#b94b39";
const SLATE = "#bbc4ca";
const CLOUD = "#f5fbff";
const CLOUD_D = "#d8e6ee";
const PAPER_GLOW = "#68d8ff";

export interface ChaseSprites {
  rider: HTMLCanvasElement[];
  barrier: HTMLCanvasElement[];
  cone: HTMLCanvasElement;
  car: HTMLCanvasElement;
  bicycle: HTMLCanvasElement;
  crowd: HTMLCanvasElement;
  runner: HTMLCanvasElement[];
  paper: HTMLCanvasElement;
  tree: HTMLCanvasElement;
  lamp: HTMLCanvasElement;
  buildings: HTMLCanvasElement[];
  clouds: HTMLCanvasElement[];
  sun: HTMLCanvasElement;
}

function makeSprite(width: number, height: number, draw: (ctx: PixelContext) => void): HTMLCanvasElement {
  const canvas = document.createElement("canvas");
  canvas.width = width;
  canvas.height = height;
  const ctx = canvas.getContext("2d");
  if (!ctx) return canvas;
  ctx.imageSmoothingEnabled = false;
  draw(ctx);
  return canvas;
}

function rect(ctx: PixelContext, x: number, y: number, w: number, h: number, color: string): void {
  ctx.fillStyle = color;
  ctx.fillRect(x, y, w, h);
}

function disc(ctx: PixelContext, cx: number, cy: number, r: number, color: string): void {
  ctx.fillStyle = color;
  for (let dy = -r; dy <= r; dy += 1) {
    const half = Math.floor(Math.sqrt(Math.max(0, r * r - dy * dy)));
    ctx.fillRect(cx - half, cy + dy, half * 2 + 1, 1);
  }
}

function ring(ctx: PixelContext, cx: number, cy: number, rx: number, ry: number, thickness: number, color: string): void {
  const innerRx = Math.max(0, rx - thickness);
  const innerRy = Math.max(0, ry - thickness);
  ctx.fillStyle = color;
  for (let dy = -ry; dy <= ry; dy += 1) {
    const outer = Math.floor(rx * Math.sqrt(Math.max(0, 1 - (dy * dy) / (ry * ry))));
    const inner = dy >= -innerRy && dy <= innerRy && innerRy > 0
      ? Math.floor(innerRx * Math.sqrt(Math.max(0, 1 - (dy * dy) / (innerRy * innerRy))))
      : 0;
    if (outer > inner) {
      ctx.fillRect(cx - outer, cy + dy, outer - inner, 1);
      ctx.fillRect(cx + inner + 1, cy + dy, outer - inner, 1);
    } else {
      ctx.fillRect(cx - outer, cy + dy, outer * 2 + 1, 1);
    }
  }
}

function line(ctx: PixelContext, x0: number, y0: number, x1: number, y1: number, thickness: number, color: string): void {
  const steps = Math.max(Math.abs(x1 - x0), Math.abs(y1 - y0), 1) * 2;
  ctx.fillStyle = color;
  for (let i = 0; i <= steps; i += 1) {
    const t = i / steps;
    const x = Math.round(x0 + (x1 - x0) * t - thickness / 2);
    const y = Math.round(y0 + (y1 - y0) * t - thickness / 2);
    ctx.fillRect(x, y, thickness, thickness);
  }
}

// Rider: rear-view cyclist, 24x32, 3 pedal frames.
function buildRiderFrame(frame: number): HTMLCanvasElement {
  return makeSprite(24, 32, (ctx) => {
    // wheels
    ring(ctx, 12, 25, 3, 6, 2, INK);
    rect(ctx, 12, 21, 1, 9, METAL);
    ring(ctx, 12, 14, 2, 4, 1, INK);
    // frame
    line(ctx, 9, 13, 9, 22, 2, YELLOW);
    line(ctx, 15, 13, 15, 22, 2, YELLOW);
    line(ctx, 9, 13, 15, 13, 2, YELLOW_D);
    rect(ctx, 10, 11, 4, 2, DARK);
    // crank
    disc(ctx, 12, 20, 1, METAL_D);
    // legs (per pedal frame)
    if (frame === 0) {
      line(ctx, 10, 13, 9, 18, 3, NAVY);
      line(ctx, 9, 18, 10, 23, 3, NAVY);
      rect(ctx, 9, 23, 4, 2, WHITE);
      line(ctx, 14, 13, 15, 16, 3, NAVY_L);
      line(ctx, 15, 16, 13, 18, 3, NAVY_L);
      rect(ctx, 12, 18, 4, 2, WHITE);
    } else if (frame === 2) {
      line(ctx, 10, 13, 9, 16, 3, NAVY_L);
      line(ctx, 9, 16, 11, 18, 3, NAVY_L);
      rect(ctx, 10, 18, 4, 2, WHITE);
      line(ctx, 14, 13, 15, 18, 3, NAVY);
      line(ctx, 15, 18, 14, 23, 3, NAVY);
      rect(ctx, 13, 23, 4, 2, WHITE);
    } else {
      line(ctx, 10, 13, 9, 17, 3, NAVY);
      line(ctx, 9, 17, 9, 20, 3, NAVY);
      rect(ctx, 8, 20, 4, 2, WHITE);
      line(ctx, 14, 13, 15, 17, 3, NAVY_L);
      line(ctx, 15, 17, 15, 20, 3, NAVY_L);
      rect(ctx, 14, 20, 4, 2, WHITE);
    }
    // torso
    rect(ctx, 7, 5, 10, 9, INK);
    rect(ctx, 8, 6, 8, 7, BLUE);
    rect(ctx, 8, 6, 2, 7, BLUE_D);
    rect(ctx, 8, 9, 8, 1, CYAN);
    // handlebar and arms
    rect(ctx, 5, 5, 14, 2, DARK);
    rect(ctx, 5, 5, 2, 2, INK);
    rect(ctx, 17, 5, 2, 2, INK);
    line(ctx, 9, 7, 6, 6, 2, BLUE);
    line(ctx, 15, 7, 18, 6, 2, BLUE);
    // head + helmet
    disc(ctx, 12, 3, 3, HAIR);
    rect(ctx, 10, 4, 4, 2, SKIN);
    rect(ctx, 11, 1, 2, 1, METAL);
  });
}

// Barrier: striped construction barricade, 32x20, 2 warning-light frames.
function buildBarrierFrame(lightOn: boolean): HTMLCanvasElement {
  return makeSprite(32, 20, (ctx) => {
    // legs
    line(ctx, 6, 11, 3, 18, 2, METAL_D);
    line(ctx, 6, 11, 9, 18, 2, METAL_D);
    line(ctx, 26, 11, 23, 18, 2, METAL_D);
    line(ctx, 26, 11, 29, 18, 2, METAL_D);
    rect(ctx, 1, 18, 6, 1, INK);
    rect(ctx, 25, 18, 6, 1, INK);
    // board
    rect(ctx, 1, 4, 30, 8, INK);
    rect(ctx, 2, 5, 28, 6, YELLOW);
    for (let sx = 3; sx < 28; sx += 6) line(ctx, sx, 5, sx + 3, 10, 2, DARK);
    // warning light
    rect(ctx, 15, 1, 2, 3, INK);
    disc(ctx, 16, 2, 2, lightOn ? RED : RED_D);
    if (lightOn) rect(ctx, 15, 1, 1, 1, WHITE);
  });
}

// Traffic cone, 14x18.
function buildCone(): HTMLCanvasElement {
  return makeSprite(14, 18, (ctx) => {
    rect(ctx, 1, 15, 12, 2, INK);
    rect(ctx, 2, 15, 10, 1, ORANGE_D);
    for (let y = 3; y <= 14; y += 1) {
      const half = Math.max(1, Math.round((y - 2) * 0.42));
      const left = 7 - half;
      rect(ctx, left, y, half * 2, 1, y >= 8 && y <= 9 ? WHITE : ORANGE);
      rect(ctx, left, y, 1, 1, INK);
      rect(ctx, left + half * 2 - 1, y, 1, 1, INK);
    }
    rect(ctx, 6, 3, 2, 1, AMBER);
  });
}

// Car: rear view, 36x32.
function buildCar(): HTMLCanvasElement {
  return makeSprite(36, 32, (ctx) => {
    // wheels
    rect(ctx, 4, 26, 7, 5, INK);
    rect(ctx, 25, 26, 7, 5, INK);
    rect(ctx, 6, 28, 3, 1, METAL_D);
    rect(ctx, 27, 28, 3, 1, METAL_D);
    // body
    rect(ctx, 3, 9, 30, 18, INK);
    rect(ctx, 4, 10, 28, 16, RED);
    rect(ctx, 4, 22, 28, 4, RED_D);
    // roof and rear window
    rect(ctx, 9, 2, 18, 9, INK);
    rect(ctx, 10, 3, 16, 7, RED);
    rect(ctx, 11, 4, 14, 5, GLASS);
    rect(ctx, 12, 5, 4, 1, METAL);
    // taillights
    rect(ctx, 4, 12, 8, 6, INK);
    rect(ctx, 5, 13, 6, 4, AMBER);
    rect(ctx, 24, 12, 8, 6, INK);
    rect(ctx, 25, 13, 6, 4, AMBER);
    // plate and bumper
    rect(ctx, 15, 18, 6, 4, WHITE);
    rect(ctx, 16, 19, 4, 1, METAL_D);
    rect(ctx, 3, 24, 30, 3, METAL_D);
  });
}

 // Parked shared bicycle, front view, 20x28.
function buildBicycle(): HTMLCanvasElement {
  return makeSprite(20, 28, (ctx) => {
    ring(ctx, 10, 20, 4, 7, 2, INK);
    rect(ctx, 10, 15, 1, 11, METAL);
    line(ctx, 9, 12, 9, 15, 1, METAL_D);
    line(ctx, 11, 12, 11, 15, 1, METAL_D);
    // basket
    rect(ctx, 5, 7, 10, 6, INK);
    rect(ctx, 6, 8, 8, 4, METAL);
    rect(ctx, 6, 9, 8, 1, METAL_D);
    rect(ctx, 9, 8, 1, 4, METAL_D);
    // stem and handlebar
    rect(ctx, 9, 4, 2, 4, METAL_D);
    rect(ctx, 3, 3, 14, 2, INK);
    rect(ctx, 3, 3, 3, 2, DARK);
    rect(ctx, 14, 3, 3, 2, DARK);
    // reflector
    rect(ctx, 9, 10, 2, 1, RED);
  });
}

// Crowd of three students, 36x28.
function buildCrowd(): HTMLCanvasElement {
  const person = (ctx: PixelContext, cx: number, dy: number, shirt: string, shade: string, backpack: boolean) => {
    disc(ctx, cx, 6 + dy, 3, INK);
    disc(ctx, cx, 6 + dy, 2, SKIN);
    rect(ctx, cx - 2, 3 + dy, 4, 2, HAIR);
    rect(ctx, cx - 4, 9 + dy, 9, 10, INK);
    rect(ctx, cx - 3, 10 + dy, 7, 8, shirt);
    rect(ctx, cx - 3, 10 + dy, 2, 8, shade);
    rect(ctx, cx - 3, 19 + dy, 3, 7, NAVY);
    rect(ctx, cx + 1, 19 + dy, 3, 7, NAVY_L);
    rect(ctx, cx - 3, 26 + dy, 3, 2, WHITE);
    rect(ctx, cx + 1, 26 + dy, 3, 2, WHITE);
    if (backpack) {
      rect(ctx, cx + 3, 11 + dy, 4, 6, INK);
      rect(ctx, cx + 4, 12 + dy, 2, 4, PURPLE_D);
    }
  };
  return makeSprite(36, 28, (ctx) => {
    person(ctx, 6, 0, BLUE, BLUE_D, false);
    person(ctx, 18, 1, PURPLE, PURPLE_D, true);
    person(ctx, 30, 0, CORAL, CORAL_D, false);
  });
}

// Runner: side view crossing the road, 20x28, 4 run-cycle frames.
const RUNNER_LEGS: readonly (readonly [number, number, number, number])[][] = [
  [[10, 15, 15, 18], [15, 18, 17, 23], [9, 15, 4, 17], [4, 17, 1, 13]],
  [[10, 15, 11, 20], [11, 20, 10, 25], [9, 15, 6, 18], [6, 18, 8, 13]],
  [[10, 15, 5, 18], [5, 18, 2, 23], [9, 15, 14, 17], [14, 17, 17, 13]],
  [[10, 15, 9, 20], [9, 20, 8, 25], [9, 15, 12, 18], [12, 18, 14, 13]]
];
const RUNNER_ARMS: readonly (readonly [number, number, number, number])[][] = [
  [[11, 9, 6, 12], [11, 9, 16, 10]],
  [[11, 9, 8, 13], [11, 9, 14, 12]],
  [[11, 9, 16, 12], [11, 9, 6, 10]],
  [[11, 9, 14, 13], [11, 9, 8, 12]]
];

function buildRunnerFrame(frame: number): HTMLCanvasElement {
  return makeSprite(20, 28, (ctx) => {
    const legs = RUNNER_LEGS[frame];
    const arms = RUNNER_ARMS[frame];
    // far limbs first
    line(ctx, legs[2][0], legs[2][1], legs[2][2], legs[2][3], 3, NAVY);
    line(ctx, legs[3][0], legs[3][1], legs[3][2], legs[3][3], 3, NAVY);
    rect(ctx, legs[3][2] - 1, legs[3][3], 3, 2, WHITE);
    line(ctx, arms[1][0], arms[1][1], arms[1][2], arms[1][3], 2, PURPLE_D);
    rect(ctx, arms[1][2] - 1, arms[1][3] - 1, 2, 2, SKIN);
    // torso
    rect(ctx, 6, 6, 9, 11, INK);
    rect(ctx, 7, 7, 7, 9, PURPLE);
    rect(ctx, 7, 7, 2, 9, PURPLE_D);
    // carried book package
    rect(ctx, 12, 8, 4, 4, WHITE);
    rect(ctx, 12, 9, 4, 1, PURPLE_D);
    // backpack
    rect(ctx, 4, 8, 3, 6, INK);
    rect(ctx, 5, 9, 1, 4, BLUE_D);
    // near limbs
    line(ctx, legs[0][0], legs[0][1], legs[0][2], legs[0][3], 3, NAVY_L);
    line(ctx, legs[1][0], legs[1][1], legs[1][2], legs[1][3], 3, NAVY_L);
    rect(ctx, legs[1][2] - 1, legs[1][3], 3, 2, WHITE);
    line(ctx, arms[0][0], arms[0][1], arms[0][2], arms[0][3], 2, PURPLE);
    rect(ctx, arms[0][2] - 1, arms[0][3] - 1, 2, 2, SKIN);
    // head
    disc(ctx, 13, 4, 3, INK);
    disc(ctx, 13, 4, 2, SKIN);
    rect(ctx, 11, 1, 5, 3, HAIR);
    rect(ctx, 15, 4, 1, 1, INK);
  });
}

// Target paper at the horizon, 12x8.
function buildPaper(): HTMLCanvasElement {
  return makeSprite(12, 8, (ctx) => {
    rect(ctx, 0, 0, 12, 8, PAPER_GLOW);
    rect(ctx, 1, 1, 10, 6, WHITE);
    rect(ctx, 3, 3, 6, 1, METAL_D);
    rect(ctx, 3, 5, 5, 1, METAL_D);
  });
}

// Roadside tree, 24x36.
function buildTree(): HTMLCanvasElement {
  return makeSprite(24, 36, (ctx) => {
    rect(ctx, 8, 33, 8, 2, TRUNK_D);
    rect(ctx, 10, 20, 4, 14, TRUNK);
    rect(ctx, 10, 20, 1, 14, TRUNK_D);
    disc(ctx, 12, 13, 10, LEAF_D);
    disc(ctx, 6, 17, 6, LEAF_D);
    disc(ctx, 18, 17, 6, LEAF_D);
    disc(ctx, 12, 12, 9, LEAF);
    disc(ctx, 6, 16, 5, LEAF);
    disc(ctx, 18, 16, 5, LEAF);
    disc(ctx, 9, 8, 2, LEAF_L);
    disc(ctx, 15, 10, 1, LEAF_L);
  });
}

// Roadside lamp, 12x40; arm points +x, flip for the right side.
function buildLamp(): HTMLCanvasElement {
  return makeSprite(12, 40, (ctx) => {
    rect(ctx, 3, 36, 6, 3, INK);
    rect(ctx, 4, 36, 4, 2, METAL_D);
    rect(ctx, 5, 8, 2, 28, METAL_D);
    rect(ctx, 5, 8, 1, 28, METAL);
    rect(ctx, 5, 8, 7, 2, METAL_D);
    rect(ctx, 9, 10, 3, 4, INK);
    rect(ctx, 10, 11, 1, 2, AMBER);
    // sign board
    rect(ctx, 0, 15, 5, 9, INK);
    rect(ctx, 1, 16, 3, 7, "#214e65");
    rect(ctx, 1, 18, 3, 1, WHITE);
  });
}

// Roadside buildings, 36x40, 3 variants.
function buildBuilding(wall: string, rows: number, cols: number, antenna: boolean): HTMLCanvasElement {
  return makeSprite(36, 40, (ctx) => {
    if (antenna) rect(ctx, 17, 0, 2, 4, METAL_D);
    rect(ctx, 0, 3, 36, 4, INK);
    rect(ctx, 1, 4, 34, 2, METAL_D);
    rect(ctx, 2, 6, 32, 32, INK);
    rect(ctx, 3, 7, 30, 30, wall);
    const startX = cols === 3 ? 7 : 5;
    const stepX = cols === 3 ? 9 : 7;
    for (let r = 0; r < rows; r += 1) {
      for (let c = 0; c < cols; c += 1) {
        const x = startX + c * stepX;
        const y = 10 + r * 7;
        rect(ctx, x - 1, y - 1, 6, 6, INK);
        rect(ctx, x, y, 4, 4, (r + c) % 3 === 0 ? AMBER : GLASS);
      }
    }
    rect(ctx, 15, 29, 6, 9, INK);
    rect(ctx, 16, 30, 4, 8, DARK);
    rect(ctx, 17, 31, 2, 2, GLASS);
  });
}

// Clouds.
function buildCloud(variant: number): HTMLCanvasElement {
  return variant === 0
    ? makeSprite(20, 8, (ctx) => {
        disc(ctx, 6, 5, 3, CLOUD);
        disc(ctx, 11, 4, 4, CLOUD);
        disc(ctx, 15, 5, 3, CLOUD);
        rect(ctx, 4, 7, 13, 1, CLOUD_D);
      })
    : makeSprite(14, 6, (ctx) => {
        disc(ctx, 4, 4, 2, CLOUD);
        disc(ctx, 8, 3, 3, CLOUD);
        disc(ctx, 11, 4, 2, CLOUD);
        rect(ctx, 3, 5, 9, 1, CLOUD_D);
      });
}

// Sun, 12x12.
function buildSun(): HTMLCanvasElement {
  return makeSprite(12, 12, (ctx) => {
    disc(ctx, 6, 6, 5, "#fff4c2");
    disc(ctx, 6, 6, 3, "#fff9dd");
  });
}

export function createChaseSprites(): ChaseSprites {
  return {
    rider: [buildRiderFrame(0), buildRiderFrame(1), buildRiderFrame(2)],
    barrier: [buildBarrierFrame(true), buildBarrierFrame(false)],
    cone: buildCone(),
    car: buildCar(),
    bicycle: buildBicycle(),
    crowd: buildCrowd(),
    runner: [buildRunnerFrame(0), buildRunnerFrame(1), buildRunnerFrame(2), buildRunnerFrame(3)],
    paper: buildPaper(),
    tree: buildTree(),
    lamp: buildLamp(),
    buildings: [
      buildBuilding(WALL, 3, 3, false),
      buildBuilding(BRICK, 4, 3, true),
      buildBuilding(SLATE, 3, 4, false)
    ],
    clouds: [buildCloud(0), buildCloud(1)],
    sun: buildSun()
  };
}
