import libraryInteriorUrl from "../assets/rpg/interiors/library_interior.png";
import playerUpUrl from "../assets/rpg/player/player_up_0.png";
import {
  LIBRARY_SHELF_REVEAL_FRAMES,
  LIBRARY_SHELF_REVEAL_SHIFT_PX,
  scaleLibraryShelfRevealOffset
} from "../scenes/rpg/LibraryShelfRevealMotion";

type Selection = "shelf" | "player";

interface ShelfDebugConfig {
  cropLeft: number;
  cropTop: number;
  cropWidth: number;
  cropHeight: number;
  renderX: number;
  renderY: number;
  renderWidth: number;
  renderHeight: number;
  patchSourceTop: number;
  shelfDepth: number;
  playerX: number;
  playerY: number;
  playerScale: number;
  frameOffset: number;
  frameMs: number;
}

const WORLD = { width: 1500, height: 900 } as const;
const DEFAULTS: ShelfDebugConfig = {
  cropLeft: 511,
  cropTop: 105,
  cropWidth: 112,
  cropHeight: 146,
  renderX: 511,
  renderY: 105,
  renderWidth: 112,
  renderHeight: 146,
  patchSourceTop: 265,
  shelfDepth: 330,
  playerX: 567,
  playerY: 252,
  playerScale: 0.65,
  frameOffset: LIBRARY_SHELF_REVEAL_SHIFT_PX,
  frameMs: 165
};

const root = document.querySelector<HTMLDivElement>("#library-shelf-debug");
if (!root) throw new Error("Missing library shelf debug root");

root.innerHTML = `
  <style>
    :root { color-scheme: dark; font-family: ui-monospace, "Fusion Pixel 12px Proportional SC", "Microsoft YaHei", monospace; }
    * { box-sizing: border-box; }
    body { margin: 0; background: #090d0f; color: #eaf2ef; }
    button, input { font: inherit; }
    .debug-shell { min-height: 100vh; display: grid; grid-template-columns: minmax(0, 1fr) 332px; }
    .debug-stage { overflow: auto; padding: 16px; background: #06090b; }
    canvas {
      display: block; width: min(1500px, calc(100vw - 380px)); min-width: 760px; height: auto;
      background: #101716; border: 1px solid #52635f; image-rendering: pixelated; touch-action: none;
    }
    .debug-panel {
      position: sticky; top: 0; height: 100vh; overflow: auto; padding: 16px;
      background: #11191b; border-left: 1px solid #52635f;
    }
    h1 { margin: 0 0 8px; font-size: 18px; color: #f1d96d; }
    .lead, .hint, .status { margin: 0 0 12px; font-size: 12px; line-height: 1.55; color: #b9cac5; }
    fieldset { margin: 0 0 12px; padding: 10px; border: 1px solid #49615c; }
    legend { padding: 0 6px; color: #87dbe4; }
    .grid { display: grid; grid-template-columns: 1fr 1fr; gap: 8px; }
    label { display: grid; gap: 3px; font-size: 11px; color: #adc1bb; }
    input {
      width: 100%; height: 30px; padding: 0 7px; color: #f4fbf8;
      background: #172225; border: 1px solid #536b66; border-radius: 2px;
    }
    .actions { display: grid; grid-template-columns: 1fr 1fr; gap: 8px; margin-bottom: 10px; }
    button {
      min-height: 36px; color: #eef6f4; background: #1d2c30; border: 1px solid #64807a; cursor: pointer;
    }
    button[aria-pressed="true"] { color: #101718; background: #f0d967; border-color: #fff1a5; }
    button:hover { border-color: #8fe4e9; }
    .status { min-height: 38px; padding: 8px; color: #ffe89a; background: #0c1315; border: 1px solid #394d49; }
    @media (max-width: 980px) {
      .debug-shell { grid-template-columns: 1fr; }
      .debug-panel { position: static; height: auto; border-left: 0; border-top: 1px solid #52635f; }
      canvas { width: 1500px; }
    }
  </style>
  <main class="debug-shell">
    <section class="debug-stage">
      <canvas id="library-shelf-canvas" width="${WORLD.width}" height="${WORLD.height}"></canvas>
    </section>
    <aside class="debug-panel">
      <h1>图书馆书架手动校准</h1>
      <p class="lead">画布使用原始 1500×900 坐标。拖动书架或人物调位置，拖书架四角调尺寸。</p>
      <div class="actions">
        <button id="select-shelf" type="button" aria-pressed="true">调书架</button>
        <button id="select-player" type="button" aria-pressed="false">调人物</button>
        <button id="toggle-frames" type="button" aria-pressed="true">多帧动画：开</button>
        <button id="reset-config" type="button">恢复代码值</button>
      </div>
      <fieldset>
        <legend>源图裁剪</legend>
        <div class="grid">
          <label>Left<input data-key="cropLeft" type="number" /></label>
          <label>Top<input data-key="cropTop" type="number" /></label>
          <label>Width<input data-key="cropWidth" type="number" min="8" /></label>
          <label>Height<input data-key="cropHeight" type="number" min="8" /></label>
          <label>地面补片 Top<input data-key="patchSourceTop" type="number" /></label>
          <label>书架 Depth<input data-key="shelfDepth" type="number" /></label>
        </div>
      </fieldset>
      <fieldset>
        <legend>场景中的书架</legend>
        <div class="grid">
          <label>X<input data-key="renderX" type="number" /></label>
          <label>Y<input data-key="renderY" type="number" /></label>
          <label>Width<input data-key="renderWidth" type="number" min="8" /></label>
          <label>Height<input data-key="renderHeight" type="number" min="8" /></label>
          <label>终态偏移<input data-key="frameOffset" type="number" min="0" max="24" /></label>
          <label>帧间隔 ms<input data-key="frameMs" type="number" min="120" step="20" /></label>
        </div>
      </fieldset>
      <fieldset>
        <legend>人物遮挡测试</legend>
        <div class="grid">
          <label>X<input data-key="playerX" type="number" /></label>
          <label>Y<input data-key="playerY" type="number" /></label>
          <label>Scale<input data-key="playerScale" type="number" min="0.2" max="2" step="0.01" /></label>
        </div>
      </fieldset>
      <div class="actions">
        <button id="copy-config" type="button">复制校准 JSON</button>
        <button id="copy-constants" type="button">复制 TS 常量</button>
      </div>
      <p class="hint">前后关系规则：人物 depth = Y + 120。黄框是书架尺寸，青色十字是人物落脚点。</p>
      <div id="debug-status" class="status"></div>
    </aside>
  </main>
`;

const canvas = document.querySelector<HTMLCanvasElement>("#library-shelf-canvas")!;
const context = canvas.getContext("2d")!;
context.imageSmoothingEnabled = false;
const status = document.querySelector<HTMLDivElement>("#debug-status")!;
const inputs = [...document.querySelectorAll<HTMLInputElement>("input[data-key]")];
const selectShelf = document.querySelector<HTMLButtonElement>("#select-shelf")!;
const selectPlayer = document.querySelector<HTMLButtonElement>("#select-player")!;
const toggleFrames = document.querySelector<HTMLButtonElement>("#toggle-frames")!;

let config: ShelfDebugConfig = { ...DEFAULTS };
let selection: Selection = "shelf";
let animateFrames = true;
let frameIndex = 0;
let dragging: null | {
  kind: "move" | "resize";
  startX: number;
  startY: number;
  config: ShelfDebugConfig;
  corner?: "nw" | "ne" | "sw" | "se";
} = null;

const mapImage = new Image();
const playerImage = new Image();
mapImage.src = libraryInteriorUrl;
playerImage.src = playerUpUrl;
mapImage.addEventListener("load", draw);
playerImage.addEventListener("load", draw);

function syncInputs(): void {
  inputs.forEach((input) => {
    const key = input.dataset.key as keyof ShelfDebugConfig;
    input.value = String(config[key]);
  });
}

function pointFromEvent(event: PointerEvent): { x: number; y: number } {
  const bounds = canvas.getBoundingClientRect();
  return {
    x: (event.clientX - bounds.left) * WORLD.width / bounds.width,
    y: (event.clientY - bounds.top) * WORLD.height / bounds.height
  };
}

function shelfBounds() {
  return {
    left: config.renderX,
    top: config.renderY,
    right: config.renderX + config.renderWidth,
    bottom: config.renderY + config.renderHeight
  };
}

function drawShelf(): void {
  const frame = LIBRARY_SHELF_REVEAL_FRAMES[frameIndex] ?? LIBRARY_SHELF_REVEAL_FRAMES[0];
  const offset = animateFrames
    ? scaleLibraryShelfRevealOffset(frame.offsetPx, config.frameOffset)
    : 0;
  context.drawImage(
    mapImage,
    config.cropLeft,
    config.cropTop,
    config.cropWidth,
    config.cropHeight,
    config.renderX + offset,
    config.renderY,
    config.renderWidth,
    config.renderHeight
  );
  if (animateFrames && frame.phase === "sliding") {
    const unitX = config.renderWidth / config.cropWidth;
    const unitY = config.renderHeight / config.cropHeight;
    context.fillStyle = "rgba(255, 232, 129, 0.86)";
    context.fillRect(config.renderX + config.renderWidth * 0.53, config.renderY + config.renderHeight * 0.22, Math.max(2, unitX * 3), Math.max(2, unitY * 2));
  }
}

function drawPlayer(): void {
  if (!playerImage.complete) return;
  const width = 96 * config.playerScale;
  const height = 128 * config.playerScale;
  context.drawImage(playerImage, config.playerX - width / 2, config.playerY - height / 2, width, height);
  context.strokeStyle = "#6ff3ff";
  context.lineWidth = 2;
  context.beginPath();
  context.moveTo(config.playerX - 9, config.playerY);
  context.lineTo(config.playerX + 9, config.playerY);
  context.moveTo(config.playerX, config.playerY - 9);
  context.lineTo(config.playerX, config.playerY + 9);
  context.stroke();
}

function drawSelection(): void {
  const bounds = shelfBounds();
  context.save();
  context.lineWidth = 3;
  context.strokeStyle = selection === "shelf" ? "#ffe56d" : "rgba(255, 229, 109, 0.45)";
  context.setLineDash([8, 5]);
  context.strokeRect(bounds.left, bounds.top, config.renderWidth, config.renderHeight);
  context.setLineDash([]);
  if (selection === "shelf") {
    context.fillStyle = "#fff5a6";
    [[bounds.left, bounds.top], [bounds.right, bounds.top], [bounds.left, bounds.bottom], [bounds.right, bounds.bottom]]
      .forEach(([x, y]) => context.fillRect(x - 7, y - 7, 14, 14));
  }
  context.restore();
}

function draw(): void {
  context.clearRect(0, 0, WORLD.width, WORLD.height);
  if (!mapImage.complete) return;
  context.drawImage(mapImage, 0, 0, WORLD.width, WORLD.height);
  context.drawImage(
    mapImage,
    config.cropLeft,
    config.patchSourceTop,
    config.cropWidth,
    config.cropHeight,
    config.renderX,
    config.renderY,
    config.renderWidth,
    config.renderHeight
  );
  const playerDepth = config.playerY + 120;
  if (playerDepth < config.shelfDepth) drawPlayer();
  drawShelf();
  if (playerDepth >= config.shelfDepth) drawPlayer();
  drawSelection();
  const relation = playerDepth >= config.shelfDepth ? "人物在书架前" : "人物在书架后";
  status.textContent = `当前：${relation} · player depth ${playerDepth.toFixed(0)} / shelf depth ${config.shelfDepth} · 第 ${frameIndex + 1}/${LIBRARY_SHELF_REVEAL_FRAMES.length} 帧 · 偏移 ${scaleLibraryShelfRevealOffset((LIBRARY_SHELF_REVEAL_FRAMES[frameIndex] ?? LIBRARY_SHELF_REVEAL_FRAMES[0]).offsetPx, config.frameOffset)}px`;
}

function setSelection(next: Selection): void {
  selection = next;
  selectShelf.setAttribute("aria-pressed", String(next === "shelf"));
  selectPlayer.setAttribute("aria-pressed", String(next === "player"));
  draw();
}

function near(value: number, target: number, tolerance = 14): boolean {
  return Math.abs(value - target) <= tolerance;
}

canvas.addEventListener("pointerdown", (event) => {
  const point = pointFromEvent(event);
  const bounds = shelfBounds();
  if (selection === "player") {
    if (Math.hypot(point.x - config.playerX, point.y - config.playerY) > 80) return;
    dragging = { kind: "move", startX: point.x, startY: point.y, config: { ...config } };
  } else {
    const corners = [
      ["nw", bounds.left, bounds.top], ["ne", bounds.right, bounds.top],
      ["sw", bounds.left, bounds.bottom], ["se", bounds.right, bounds.bottom]
    ] as const;
    const corner = corners.find(([, x, y]) => near(point.x, x) && near(point.y, y));
    const inside = point.x >= bounds.left && point.x <= bounds.right && point.y >= bounds.top && point.y <= bounds.bottom;
    if (!corner && !inside) return;
    dragging = {
      kind: corner ? "resize" : "move",
      corner: corner?.[0],
      startX: point.x,
      startY: point.y,
      config: { ...config }
    };
  }
  canvas.setPointerCapture(event.pointerId);
});

canvas.addEventListener("pointermove", (event) => {
  if (!dragging) return;
  const point = pointFromEvent(event);
  const dx = Math.round(point.x - dragging.startX);
  const dy = Math.round(point.y - dragging.startY);
  config = { ...dragging.config };
  if (selection === "player") {
    config.playerX = dragging.config.playerX + dx;
    config.playerY = dragging.config.playerY + dy;
  } else if (dragging.kind === "move") {
    config.renderX = dragging.config.renderX + dx;
    config.renderY = dragging.config.renderY + dy;
  } else {
    const corner = dragging.corner ?? "se";
    if (corner.includes("w")) {
      config.renderX = dragging.config.renderX + dx;
      config.renderWidth = Math.max(8, dragging.config.renderWidth - dx);
    } else {
      config.renderWidth = Math.max(8, dragging.config.renderWidth + dx);
    }
    if (corner.includes("n")) {
      config.renderY = dragging.config.renderY + dy;
      config.renderHeight = Math.max(8, dragging.config.renderHeight - dy);
    } else {
      config.renderHeight = Math.max(8, dragging.config.renderHeight + dy);
    }
  }
  syncInputs();
  draw();
});

const finishDrag = () => { dragging = null; };
canvas.addEventListener("pointerup", finishDrag);
canvas.addEventListener("pointercancel", finishDrag);

inputs.forEach((input) => {
  input.addEventListener("input", () => {
    const key = input.dataset.key as keyof ShelfDebugConfig;
    const value = Number(input.value);
    if (!Number.isFinite(value)) return;
    config = { ...config, [key]: value };
    draw();
  });
});

selectShelf.addEventListener("click", () => setSelection("shelf"));
selectPlayer.addEventListener("click", () => setSelection("player"));
toggleFrames.addEventListener("click", () => {
  animateFrames = !animateFrames;
  toggleFrames.setAttribute("aria-pressed", String(animateFrames));
  toggleFrames.textContent = `多帧动画：${animateFrames ? "开" : "关"}`;
  if (!animateFrames) frameIndex = 0;
  draw();
});
document.querySelector<HTMLButtonElement>("#reset-config")!.addEventListener("click", () => {
  config = { ...DEFAULTS };
  syncInputs();
  draw();
});

async function copyText(text: string, success: string): Promise<void> {
  await navigator.clipboard.writeText(text);
  status.textContent = success;
}

document.querySelector<HTMLButtonElement>("#copy-config")!.addEventListener("click", () => {
  void copyText(JSON.stringify(config, null, 2), "已复制校准 JSON。");
});
document.querySelector<HTMLButtonElement>("#copy-constants")!.addEventListener("click", () => {
  const constants = `const SHELF_SPRITE_BOUNDS = { left: ${config.cropLeft}, top: ${config.cropTop}, width: ${config.cropWidth}, height: ${config.cropHeight} } as const;\nconst SHELF_BASE_X = ${config.renderX + config.renderWidth / 2};\nconst SHELF_BASE_Y = ${config.renderY + config.renderHeight / 2};\nconst SHELF_RENDER_SIZE = { width: ${config.renderWidth}, height: ${config.renderHeight} } as const;\nconst SHELF_FLOOR_SOURCE_TOP = ${config.patchSourceTop};\nconst SHELF_FRONT_DEPTH = ${config.shelfDepth};`;
  void copyText(constants, "已复制 TypeScript 常量。");
});

let lastFrameAt = performance.now();
function animate(now: number): void {
  if (animateFrames && now - lastFrameAt >= Math.max(120, config.frameMs)) {
    frameIndex = (frameIndex + 1) % LIBRARY_SHELF_REVEAL_FRAMES.length;
    lastFrameAt = now;
    draw();
  }
  requestAnimationFrame(animate);
}

syncInputs();
draw();
requestAnimationFrame(animate);
