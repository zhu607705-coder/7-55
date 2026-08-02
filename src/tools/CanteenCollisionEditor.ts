import canteenMapUrl from "../assets/rpg/interiors/canteen_interior.png";
import {
  CANTEEN_INTERIOR_WORLD,
  CANTEEN_STATIC_COLLISION_RECTS,
  type CanteenCollisionRect
} from "../scenes/rpg/CanteenInteriorModel";

type EditableRect = CanteenCollisionRect;
type DragMode = "move" | "left" | "right" | "top" | "bottom" | "top-left"
  | "top-right" | "bottom-left" | "bottom-right";

interface DragState {
  mode: DragMode;
  pointerX: number;
  pointerY: number;
  start: EditableRect;
}

const root = document.querySelector<HTMLDivElement>("#canteen-collision-editor");
if (!root) throw new Error("Missing canteen collision editor root");

root.innerHTML = `
  <style>
    :root { color-scheme: dark; font-family: ui-monospace, "Microsoft YaHei", monospace; }
    * { box-sizing: border-box; }
    body { margin: 0; background: #0b0f12; color: #eaf2f4; }
    .editor-shell { min-height: 100vh; display: grid; grid-template-rows: auto 1fr; }
    .editor-toolbar {
      position: sticky; top: 0; z-index: 4; display: flex; flex-wrap: wrap; gap: 10px;
      align-items: center; padding: 10px 14px; background: #111a20f2; border-bottom: 1px solid #4f6875;
    }
    .editor-toolbar strong { color: #8de2ff; margin-right: 8px; }
    .editor-toolbar label { display: flex; align-items: center; gap: 5px; font-size: 13px; }
    .editor-toolbar select, .editor-toolbar input, .editor-toolbar button {
      height: 32px; border: 1px solid #607783; border-radius: 3px;
      background: #18242b; color: #f4fbfd; font: inherit;
    }
    .editor-toolbar input { width: 66px; padding: 0 6px; }
    .editor-toolbar select { min-width: 210px; padding: 0 8px; }
    .editor-toolbar button { padding: 0 11px; cursor: pointer; }
    .editor-toolbar button:hover { border-color: #8de2ff; background: #213642; }
    .editor-help { color: #b9c9d0; font-size: 12px; flex-basis: 100%; }
    .editor-stage { overflow: auto; padding: 14px; }
    canvas {
      display: block; width: min(1672px, calc(100vw - 28px)); height: auto;
      border: 1px solid #6e838d; background: #090d10; image-rendering: pixelated;
      touch-action: none; cursor: crosshair;
    }
    .status { color: #ffd96a; font-size: 12px; }
  </style>
  <main class="editor-shell">
    <section class="editor-toolbar">
      <strong>食堂碰撞体手动校准</strong>
      <label>碰撞体
        <select id="collision-id"></select>
      </label>
      <label>L <input id="collision-left" type="number" /></label>
      <label>T <input id="collision-top" type="number" /></label>
      <label>R <input id="collision-right" type="number" /></label>
      <label>B <input id="collision-bottom" type="number" /></label>
      <button id="collision-reset" type="button">恢复代码值</button>
      <button id="collision-copy" type="button">复制 JSON</button>
      <button id="collision-download" type="button">下载 JSON</button>
      <span id="collision-status" class="status"></span>
      <div class="editor-help">
        点击选择；拖框移动；拖四条边或四个角缩放；方向键移动 1px，Shift+方向键移动 5px。
        每张桌子都有独立的 table_行_列 碰撞体。校准后把 JSON 发回来即可合入游戏。
      </div>
    </section>
    <section class="editor-stage">
      <canvas id="collision-canvas" width="${CANTEEN_INTERIOR_WORLD.width}" height="${CANTEEN_INTERIOR_WORLD.height}"></canvas>
    </section>
  </main>
`;

const canvas = document.querySelector<HTMLCanvasElement>("#collision-canvas")!;
const context = canvas.getContext("2d")!;
const select = document.querySelector<HTMLSelectElement>("#collision-id")!;
const coordinateInputs = {
  left: document.querySelector<HTMLInputElement>("#collision-left")!,
  top: document.querySelector<HTMLInputElement>("#collision-top")!,
  right: document.querySelector<HTMLInputElement>("#collision-right")!,
  bottom: document.querySelector<HTMLInputElement>("#collision-bottom")!
};
const status = document.querySelector<HTMLSpanElement>("#collision-status")!;
const initialRects = CANTEEN_STATIC_COLLISION_RECTS.map((rect) => ({ ...rect }));
let rects: EditableRect[] = initialRects.map((rect) => ({ ...rect }));
let selectedId = rects.find((rect) => rect.id.startsWith("table_"))?.id ?? rects[0].id;
let drag: DragState | null = null;

const image = new Image();
image.addEventListener("load", draw);
image.src = canteenMapUrl;
if (image.complete) draw();

rects.forEach((rect) => {
  const option = document.createElement("option");
  option.value = rect.id;
  option.textContent = rect.id;
  select.append(option);
});
select.value = selectedId;
syncInputs();

function selectedRect(): EditableRect {
  return rects.find((rect) => rect.id === selectedId) ?? rects[0];
}

function clampRect(rect: EditableRect): void {
  rect.left = Math.round(Math.max(0, Math.min(rect.left, CANTEEN_INTERIOR_WORLD.width - 6)));
  rect.top = Math.round(Math.max(0, Math.min(rect.top, CANTEEN_INTERIOR_WORLD.height - 6)));
  rect.right = Math.round(Math.max(rect.left + 6, Math.min(rect.right, CANTEEN_INTERIOR_WORLD.width)));
  rect.bottom = Math.round(Math.max(rect.top + 6, Math.min(rect.bottom, CANTEEN_INTERIOR_WORLD.height)));
}

function syncInputs(): void {
  const rect = selectedRect();
  select.value = rect.id;
  coordinateInputs.left.value = String(rect.left);
  coordinateInputs.top.value = String(rect.top);
  coordinateInputs.right.value = String(rect.right);
  coordinateInputs.bottom.value = String(rect.bottom);
}

function canvasPoint(event: PointerEvent): { x: number; y: number } {
  const bounds = canvas.getBoundingClientRect();
  return {
    x: (event.clientX - bounds.left) * canvas.width / bounds.width,
    y: (event.clientY - bounds.top) * canvas.height / bounds.height
  };
}

function hitMode(rect: EditableRect, x: number, y: number): DragMode | null {
  const tolerance = 11;
  const nearLeft = Math.abs(x - rect.left) <= tolerance;
  const nearRight = Math.abs(x - rect.right) <= tolerance;
  const nearTop = Math.abs(y - rect.top) <= tolerance;
  const nearBottom = Math.abs(y - rect.bottom) <= tolerance;
  const insideX = x >= rect.left - tolerance && x <= rect.right + tolerance;
  const insideY = y >= rect.top - tolerance && y <= rect.bottom + tolerance;
  if (nearTop && nearLeft) return "top-left";
  if (nearTop && nearRight) return "top-right";
  if (nearBottom && nearLeft) return "bottom-left";
  if (nearBottom && nearRight) return "bottom-right";
  if (nearLeft && insideY) return "left";
  if (nearRight && insideY) return "right";
  if (nearTop && insideX) return "top";
  if (nearBottom && insideX) return "bottom";
  if (x >= rect.left && x <= rect.right && y >= rect.top && y <= rect.bottom) return "move";
  return null;
}

function draw(): void {
  context.clearRect(0, 0, canvas.width, canvas.height);
  if (image.complete) context.drawImage(image, 0, 0, canvas.width, canvas.height);
  rects.forEach((rect) => {
    const selected = rect.id === selectedId;
    context.fillStyle = selected ? "rgba(52, 210, 255, 0.25)" : "rgba(255, 45, 78, 0.17)";
    context.strokeStyle = selected ? "#8eeaff" : "#ff526d";
    context.lineWidth = selected ? 4 : 2;
    context.fillRect(rect.left, rect.top, rect.right - rect.left, rect.bottom - rect.top);
    context.strokeRect(rect.left, rect.top, rect.right - rect.left, rect.bottom - rect.top);
    if (selected || rect.id.startsWith("table_")) {
      context.font = selected ? "bold 15px monospace" : "11px monospace";
      context.textBaseline = "top";
      const width = context.measureText(rect.id).width + 8;
      context.fillStyle = selected ? "#07232e" : "rgba(35, 4, 10, 0.76)";
      context.fillRect(rect.left, rect.top, width, selected ? 22 : 16);
      context.fillStyle = selected ? "#dff9ff" : "#ffd6dd";
      context.fillText(rect.id, rect.left + 4, rect.top + 2);
    }
  });
  const selected = selectedRect();
  context.fillStyle = "#fff4a8";
  [
    [selected.left, selected.top],
    [selected.right, selected.top],
    [selected.left, selected.bottom],
    [selected.right, selected.bottom],
    [(selected.left + selected.right) / 2, selected.top],
    [(selected.left + selected.right) / 2, selected.bottom],
    [selected.left, (selected.top + selected.bottom) / 2],
    [selected.right, (selected.top + selected.bottom) / 2]
  ].forEach(([x, y]) => context.fillRect(x - 6, y - 6, 12, 12));
}

canvas.addEventListener("pointerdown", (event) => {
  const point = canvasPoint(event);
  let target = selectedRect();
  let mode = hitMode(target, point.x, point.y);
  if (!mode) {
    target = [...rects].reverse().find((rect) => hitMode(rect, point.x, point.y)) ?? target;
    mode = hitMode(target, point.x, point.y);
  }
  if (!mode) return;
  selectedId = target.id;
  drag = {
    mode,
    pointerX: point.x,
    pointerY: point.y,
    start: { ...target }
  };
  canvas.setPointerCapture(event.pointerId);
  syncInputs();
  draw();
});

canvas.addEventListener("pointermove", (event) => {
  if (!drag) return;
  const point = canvasPoint(event);
  const rect = selectedRect();
  const dx = Math.round(point.x - drag.pointerX);
  const dy = Math.round(point.y - drag.pointerY);
  Object.assign(rect, drag.start);
  if (drag.mode === "move") {
    rect.left += dx;
    rect.right += dx;
    rect.top += dy;
    rect.bottom += dy;
  } else {
    if (drag.mode.includes("left")) rect.left += dx;
    if (drag.mode.includes("right")) rect.right += dx;
    if (drag.mode.includes("top")) rect.top += dy;
    if (drag.mode.includes("bottom")) rect.bottom += dy;
  }
  clampRect(rect);
  syncInputs();
  draw();
});

canvas.addEventListener("pointerup", (event) => {
  drag = null;
  canvas.releasePointerCapture(event.pointerId);
});

select.addEventListener("change", () => {
  selectedId = select.value;
  syncInputs();
  draw();
});

Object.entries(coordinateInputs).forEach(([edge, input]) => {
  input.addEventListener("change", () => {
    const value = Number(input.value);
    if (!Number.isFinite(value)) return;
    selectedRect()[edge as keyof Pick<EditableRect, "left" | "top" | "right" | "bottom">] = Math.round(value);
    clampRect(selectedRect());
    syncInputs();
    draw();
  });
});

window.addEventListener("keydown", (event) => {
  if (event.target instanceof HTMLInputElement || event.target instanceof HTMLSelectElement) return;
  const amount = event.shiftKey ? 5 : 1;
  const delta = {
    ArrowLeft: [-amount, 0],
    ArrowRight: [amount, 0],
    ArrowUp: [0, -amount],
    ArrowDown: [0, amount]
  }[event.key];
  if (!delta) return;
  event.preventDefault();
  const rect = selectedRect();
  rect.left += delta[0];
  rect.right += delta[0];
  rect.top += delta[1];
  rect.bottom += delta[1];
  clampRect(rect);
  syncInputs();
  draw();
});

document.querySelector<HTMLButtonElement>("#collision-reset")!.addEventListener("click", () => {
  rects = initialRects.map((rect) => ({ ...rect }));
  syncInputs();
  status.textContent = "已恢复";
  draw();
});

function collisionJson(): string {
  return JSON.stringify(rects, null, 2);
}

document.querySelector<HTMLButtonElement>("#collision-copy")!.addEventListener("click", async () => {
  await navigator.clipboard.writeText(collisionJson());
  status.textContent = "JSON 已复制";
});

document.querySelector<HTMLButtonElement>("#collision-download")!.addEventListener("click", () => {
  const url = URL.createObjectURL(new Blob([collisionJson()], { type: "application/json" }));
  const anchor = document.createElement("a");
  anchor.href = url;
  anchor.download = "canteen-collision-rects.json";
  anchor.click();
  URL.revokeObjectURL(url);
  status.textContent = "JSON 已下载";
});
