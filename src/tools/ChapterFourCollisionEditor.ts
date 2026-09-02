import mazeLayoutJson from "../data/chapter4-three-floor-maze.layout.json";
import a1BaseUrl from "../assets/rpg/interiors/finale/chapter4-755/base/a1.png";
import a2BaseUrl from "../assets/rpg/interiors/finale/chapter4-755/base/a2.png";
import a3BaseUrl from "../assets/rpg/interiors/finale/chapter4-755/base/a3.png";
import a1OpeningUrl from "../assets/rpg/interiors/finale/chapter4-755/states/a1_2245_opening.png";
import a1BakeryUrl from "../assets/rpg/interiors/finale/chapter4-755/states/a1_1225_bakery.png";
import a1MaintenanceUrl from "../assets/rpg/interiors/finale/chapter4-755/states/a1_2245_maintenance.png";
import a1BlackoutUrl from "../assets/rpg/interiors/finale/chapter4-755/states/a1_0754_blackout.png";
import a1MorningUrl from "../assets/rpg/interiors/finale/chapter4-755/states/a1_0755_morning.png";
import a2EveningUrl from "../assets/rpg/interiors/finale/chapter4-755/states/a2_1850_evening.png";
import a2ChaseUrl from "../assets/rpg/interiors/finale/chapter4-755/states/a2_0754_chase.png";
import a2FinalMinuteUrl from "../assets/rpg/interiors/finale/chapter4-755/states/a2_202_final_minute.png";
import a3ReferenceUrl from "../assets/rpg/interiors/finale/chapter4-755/states/a3_1850_reference.png";

type StoryFloor = "A1" | "A2" | "A3";
type EditorMode = "draw" | "select";
type ResizeHandle = "nw" | "n" | "ne" | "e" | "se" | "s" | "sw" | "w";
type DragState =
  | { kind: "create"; pointerId: number; startX: number; startY: number }
  | {
      kind: "move" | "resize";
      pointerId: number;
      startX: number;
      startY: number;
      original: DraftCollisionRect;
      handle?: ResizeHandle;
    };

interface CollisionRect {
  id: string;
  label?: string;
  x: number;
  y: number;
  width: number;
  height: number;
}

interface DraftCollisionRect extends CollisionRect {
  label: string;
}

interface FloorLayout {
  storyFloor: StoryFloor;
  displayFloor: number;
  staticCollisions: CollisionRect[];
}

interface MazeLayout {
  worldSize: { width: number; height: number };
  floors: FloorLayout[];
}

interface PlateOption {
  id: string;
  label: string;
  url: string;
}

interface EditorSnapshot {
  drafts: Record<StoryFloor, DraftCollisionRect[]>;
}

interface PersistedDrafts {
  schema: "chapter4-collision-editor-draft/v1";
  floors: Record<StoryFloor, DraftCollisionRect[]>;
}

declare global {
  interface Window {
    render_collision_editor_to_text?: () => string;
  }
}

const mazeLayout = mazeLayoutJson as MazeLayout;
const WORLD = mazeLayout.worldSize;
const FLOOR_ORDER: readonly StoryFloor[] = ["A1", "A2", "A3"];
const STORAGE_KEY = "chapter4-collision-editor-drafts-v1";
const MIN_RECT_SIZE = 4;
const MIN_CREATE_DRAG_DISTANCE = 8;

const FLOOR_PLATES: Record<StoryFloor, readonly PlateOption[]> = {
  A1: [
    { id: "a1_1225_bakery", label: "12:25 · 面包坊（桌椅最清楚）", url: a1BakeryUrl },
    { id: "a1_base", label: "结构母图", url: a1BaseUrl },
    { id: "a1_2245_opening", label: "22:45 · 初次进入", url: a1OpeningUrl },
    { id: "a1_2245_maintenance", label: "22:45 · 维修阶段", url: a1MaintenanceUrl },
    { id: "a1_0754_blackout", label: "07:54 · 停电阶段", url: a1BlackoutUrl },
    { id: "a1_0755_morning", label: "07:55 · 晨间阶段", url: a1MorningUrl }
  ],
  A2: [
    { id: "a2_1850_evening", label: "18:50 · 教室与开放学习区", url: a2EveningUrl },
    { id: "a2_base", label: "结构母图", url: a2BaseUrl },
    { id: "a2_0754_chase", label: "07:54 · 追逐阶段", url: a2ChaseUrl },
    { id: "a2_202_final_minute", label: "07:54 · 202 最后一分钟", url: a2FinalMinuteUrl }
  ],
  A3: [
    { id: "a3_1850_reference", label: "18:50 · 三楼参照", url: a3ReferenceUrl },
    { id: "a3_base", label: "结构母图", url: a3BaseUrl }
  ]
};

const DEFAULT_DRAFTS: Record<StoryFloor, DraftCollisionRect[]> = {
  A1: [],
  A2: [],
  A3: []
};

const root = document.querySelector<HTMLDivElement>("#chapter4-collision-editor");
if (!root) throw new Error("Missing Chapter 4 collision editor root");

root.innerHTML = `
  <style>
    :root {
      color-scheme: dark;
      font-family: ui-monospace, "Fusion Pixel 12px Proportional SC", "Microsoft YaHei", monospace;
      background: #080d11;
    }
    * { box-sizing: border-box; }
    html, body { margin: 0; min-width: 320px; min-height: 100%; background: #080d11; color: #edf4f1; }
    button, select, input { font: inherit; }
    button { cursor: pointer; }
    .collision-editor {
      min-height: 100vh;
      display: grid;
      grid-template-rows: auto minmax(0, 1fr);
      background: #080d11;
    }
    .editor-header {
      position: sticky;
      top: 0;
      z-index: 10;
      display: grid;
      grid-template-columns: minmax(210px, 1fr) auto;
      gap: 14px;
      align-items: center;
      padding: 10px 14px;
      background: rgba(13, 23, 29, 0.97);
      border-bottom: 1px solid #536873;
      box-shadow: 0 8px 20px rgba(0, 0, 0, 0.32);
    }
    .editor-title { min-width: 0; }
    .editor-title h1 { margin: 0 0 3px; color: #f1d566; font-size: 17px; font-weight: 700; }
    .editor-title p { margin: 0; color: #aebfc5; font-size: 11px; line-height: 1.45; }
    .floor-tabs { display: flex; gap: 7px; }
    .floor-tab {
      min-width: 72px;
      min-height: 38px;
      padding: 0 12px;
      color: #d9e5e7;
      background: #16242b;
      border: 1px solid #5a737e;
    }
    .floor-tab[aria-pressed="true"] {
      color: #11191c;
      background: #f1d566;
      border-color: #fff0a3;
    }
    .editor-body {
      min-height: 0;
      display: grid;
      grid-template-columns: minmax(0, 1fr) 326px;
    }
    .stage-column { min-width: 0; min-height: 0; display: grid; grid-template-rows: auto minmax(0, 1fr); }
    .stage-toolbar {
      display: flex;
      flex-wrap: wrap;
      align-items: center;
      gap: 8px 12px;
      min-height: 48px;
      padding: 8px 12px;
      background: #101a20;
      border-bottom: 1px solid #344851;
    }
    .stage-toolbar label { display: flex; align-items: center; gap: 6px; color: #bdcdd1; font-size: 11px; }
    .stage-toolbar select,
    .inspector input,
    .inspector select {
      height: 32px;
      padding: 0 8px;
      color: #f3f7f6;
      background: #17262d;
      border: 1px solid #566f79;
      border-radius: 2px;
    }
    #plate-select { min-width: 230px; }
    #zoom-select { min-width: 94px; }
    .mode-group { display: flex; gap: 6px; margin-left: auto; }
    .mode-button {
      min-height: 32px;
      padding: 0 12px;
      color: #dbe7e8;
      background: #192930;
      border: 1px solid #5e7781;
    }
    .mode-button[aria-pressed="true"] {
      color: #06212b;
      background: #8de2f1;
      border-color: #c5f6ff;
    }
    .canvas-scroll {
      min-height: 0;
      overflow: auto;
      padding: 14px;
      background:
        linear-gradient(45deg, #0d151a 25%, transparent 25%) 0 0 / 18px 18px,
        linear-gradient(45deg, transparent 75%, #0d151a 75%) 0 0 / 18px 18px,
        #080d11;
    }
    .canvas-frame { position: relative; width: max-content; min-width: 100%; }
    canvas {
      display: block;
      max-width: none;
      height: auto;
      background: #111b20;
      border: 1px solid #657b84;
      box-shadow: 0 8px 28px rgba(0, 0, 0, 0.42);
      image-rendering: pixelated;
      touch-action: none;
      cursor: crosshair;
    }
    .canvas-meta {
      position: sticky;
      left: 0;
      display: flex;
      justify-content: space-between;
      gap: 16px;
      width: min(100%, 780px);
      padding: 8px 2px 2px;
      color: #91a8b0;
      font-size: 11px;
    }
    .canvas-meta strong { color: #f3dc7d; font-weight: 600; }
    .inspector {
      min-height: 0;
      overflow: auto;
      padding: 14px;
      background: #111b20;
      border-left: 1px solid #465c65;
    }
    .inspector section { margin: 0 0 13px; padding: 11px; border: 1px solid #405760; background: #0d171c; }
    .inspector h2 { margin: 0 0 8px; color: #8de2f1; font-size: 13px; }
    .inspector p { margin: 0; color: #afc0c5; font-size: 11px; line-height: 1.6; }
    .legend { display: grid; gap: 7px; }
    .legend span { display: flex; align-items: center; gap: 8px; color: #bbc9cd; font-size: 11px; }
    .legend i { width: 22px; height: 12px; border: 2px solid; }
    .legend .existing { border-color: #ff6d83; background: rgba(255, 79, 104, 0.18); }
    .legend .draft { border-color: #f1d566; background: rgba(241, 213, 102, 0.24); }
    .legend .selected { border-color: #8de2f1; background: rgba(67, 199, 231, 0.28); }
    .field-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 8px; }
    .field-grid .wide { grid-column: 1 / -1; }
    .inspector label { display: grid; gap: 4px; color: #9fb3b9; font-size: 10px; }
    .inspector input, .inspector select { width: 100%; min-width: 0; }
    .action-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 8px; }
    .action-grid button,
    .danger-button {
      min-height: 35px;
      padding: 6px 9px;
      color: #ecf4f2;
      background: #19282e;
      border: 1px solid #5b737c;
    }
    .action-grid button:hover { border-color: #8de2f1; }
    .action-grid .primary { color: #101819; background: #f1d566; border-color: #fff0a3; }
    .danger-button { width: 100%; margin-top: 8px; color: #ffc4cc; border-color: #8c4c58; background: #27171b; }
    button:disabled, input:disabled, select:disabled { cursor: default; opacity: 0.43; }
    .status {
      min-height: 52px;
      padding: 9px;
      color: #ffe798;
      background: #091115;
      border: 1px solid #384d55;
      font-size: 11px;
      line-height: 1.55;
      white-space: pre-wrap;
    }
    .count-line { margin-top: 8px !important; color: #dce8e6 !important; }
    @media (max-width: 900px) {
      .editor-header { grid-template-columns: 1fr; }
      .floor-tabs { width: 100%; }
      .floor-tab { flex: 1; }
      .editor-body { grid-template-columns: 1fr; }
      .stage-column { min-height: 520px; }
      .inspector { border-left: 0; border-top: 1px solid #465c65; }
      .mode-group { margin-left: 0; }
      #plate-select { min-width: 180px; max-width: calc(100vw - 95px); }
    }
  </style>
  <main class="collision-editor">
    <header class="editor-header">
      <div class="editor-title">
        <h1>第四章三层桌椅碰撞标注</h1>
        <p>源图坐标 1672×941。每张桌子与四周座椅画一个独立矩形，参照食堂保留桌间过道。</p>
      </div>
      <nav class="floor-tabs" aria-label="选择楼层">
        ${FLOOR_ORDER.map((floor) => `<button class="floor-tab" data-floor="${floor}" type="button">${floor}</button>`).join("")}
      </nav>
    </header>
    <div class="editor-body">
      <div class="stage-column">
        <div class="stage-toolbar">
          <label>底图状态 <select id="plate-select"></select></label>
          <label>显示比例
            <select id="zoom-select">
              <option value="fit">适应窗口</option>
              <option value="50">50%</option>
              <option value="75">75%</option>
              <option value="100">100%</option>
              <option value="125">125%</option>
            </select>
          </label>
          <label><input id="show-existing" type="checkbox" checked />显示已有结构碰撞</label>
          <div class="mode-group">
            <button id="draw-mode" class="mode-button" type="button">框选桌椅 D</button>
            <button id="select-mode" class="mode-button" type="button">选择调整 V</button>
          </div>
        </div>
        <div id="canvas-scroll" class="canvas-scroll">
          <div class="canvas-frame">
            <canvas id="collision-canvas" width="${WORLD.width}" height="${WORLD.height}"></canvas>
            <div class="canvas-meta">
              <span id="pointer-position">坐标：—</span>
              <span><strong id="active-floor-label">A1</strong> · 已有 <span id="existing-count">0</span> · 新增 <span id="draft-count">0</span></span>
            </div>
          </div>
        </div>
      </div>
      <aside class="inspector">
        <section>
          <h2>框选规则</h2>
          <p>选择“框选桌椅”，从实体左上角拖到右下角。范围覆盖桌面和椅子外沿，走道、门口及人物可站立地面不要包含。单击产生的 4×4 点会被忽略；已有结构碰撞只作红色参照，不会随草稿导出。</p>
          <div class="legend">
            <span><i class="existing"></i>已有结构碰撞</span>
            <span><i class="draft"></i>本轮新增草稿</span>
            <span><i class="selected"></i>当前选中草稿</span>
          </div>
        </section>
        <section>
          <h2>当前矩形</h2>
          <div class="field-grid">
            <label class="wide">选择草稿<select id="draft-select"></select></label>
            <label class="wide">ID<input id="rect-id" type="text" /></label>
            <label class="wide">说明<input id="rect-label" type="text" /></label>
            <label>X<input id="rect-x" type="number" /></label>
            <label>Y<input id="rect-y" type="number" /></label>
            <label>宽<input id="rect-width" type="number" min="4" /></label>
            <label>高<input id="rect-height" type="number" min="4" /></label>
          </div>
          <button id="delete-selected" class="danger-button" type="button">删除当前矩形</button>
        </section>
        <section>
          <h2>三层草稿</h2>
          <div class="action-grid">
            <button id="undo-action" type="button">撤销</button>
            <button id="clear-floor" type="button">清空本层</button>
            <button id="copy-json" class="primary" type="button">复制三层 JSON</button>
            <button id="download-json" type="button">下载 JSON</button>
          </div>
          <p class="count-line" id="all-floor-counts"></p>
        </section>
        <div id="editor-status" class="status" role="status">在地图上拖框即可开始。本页只保存 session 草稿，不会改动正式地图。</div>
      </aside>
    </div>
  </main>
`;

const canvas = document.querySelector<HTMLCanvasElement>("#collision-canvas")!;
const context = canvas.getContext("2d")!;
const canvasScroll = document.querySelector<HTMLDivElement>("#canvas-scroll")!;
const plateSelect = document.querySelector<HTMLSelectElement>("#plate-select")!;
const zoomSelect = document.querySelector<HTMLSelectElement>("#zoom-select")!;
const showExistingInput = document.querySelector<HTMLInputElement>("#show-existing")!;
const drawModeButton = document.querySelector<HTMLButtonElement>("#draw-mode")!;
const selectModeButton = document.querySelector<HTMLButtonElement>("#select-mode")!;
const draftSelect = document.querySelector<HTMLSelectElement>("#draft-select")!;
const deleteSelectedButton = document.querySelector<HTMLButtonElement>("#delete-selected")!;
const undoButton = document.querySelector<HTMLButtonElement>("#undo-action")!;
const clearFloorButton = document.querySelector<HTMLButtonElement>("#clear-floor")!;
const status = document.querySelector<HTMLDivElement>("#editor-status")!;
const pointerPosition = document.querySelector<HTMLSpanElement>("#pointer-position")!;
const activeFloorLabel = document.querySelector<HTMLElement>("#active-floor-label")!;
const existingCount = document.querySelector<HTMLElement>("#existing-count")!;
const draftCount = document.querySelector<HTMLElement>("#draft-count")!;
const allFloorCounts = document.querySelector<HTMLElement>("#all-floor-counts")!;
const inputs = {
  id: document.querySelector<HTMLInputElement>("#rect-id")!,
  label: document.querySelector<HTMLInputElement>("#rect-label")!,
  x: document.querySelector<HTMLInputElement>("#rect-x")!,
  y: document.querySelector<HTMLInputElement>("#rect-y")!,
  width: document.querySelector<HTMLInputElement>("#rect-width")!,
  height: document.querySelector<HTMLInputElement>("#rect-height")!
};

context.imageSmoothingEnabled = false;

const existingByFloor = Object.fromEntries(
  FLOOR_ORDER.map((floor) => [
    floor,
    mazeLayout.floors.find((entry) => entry.storyFloor === floor)?.staticCollisions ?? []
  ])
) as Record<StoryFloor, CollisionRect[]>;

let activeFloor: StoryFloor = "A1";
let activePlateId = FLOOR_PLATES.A1[0].id;
let editorMode: EditorMode = "draw";
let drafts = loadDrafts();
let selectedId: string | null = drafts.A1[0]?.id ?? null;
let temporaryRect: DraftCollisionRect | null = null;
let drag: DragState | null = null;
let history: EditorSnapshot[] = [];
let activeImage: HTMLImageElement | null = null;
const imageCache = new Map<string, HTMLImageElement>();

function cloneDrafts(source: Record<StoryFloor, DraftCollisionRect[]>): Record<StoryFloor, DraftCollisionRect[]> {
  return {
    A1: source.A1.map((rect) => ({ ...rect })),
    A2: source.A2.map((rect) => ({ ...rect })),
    A3: source.A3.map((rect) => ({ ...rect }))
  };
}

function isValidRect(value: unknown): value is DraftCollisionRect {
  if (!value || typeof value !== "object") return false;
  const rect = value as Partial<DraftCollisionRect>;
  return typeof rect.id === "string"
    && typeof rect.label === "string"
    && typeof rect.x === "number"
    && Number.isFinite(rect.x)
    && typeof rect.y === "number"
    && Number.isFinite(rect.y)
    && typeof rect.width === "number"
    && Number.isFinite(rect.width)
    && typeof rect.height === "number"
    && Number.isFinite(rect.height);
}

function loadDrafts(): Record<StoryFloor, DraftCollisionRect[]> {
  try {
    const raw = window.sessionStorage.getItem(STORAGE_KEY);
    if (!raw) return cloneDrafts(DEFAULT_DRAFTS);
    const parsed = JSON.parse(raw) as Partial<PersistedDrafts>;
    if (parsed.schema !== "chapter4-collision-editor-draft/v1" || !parsed.floors) {
      return cloneDrafts(DEFAULT_DRAFTS);
    }
    return {
      A1: Array.isArray(parsed.floors.A1) ? parsed.floors.A1.filter(isValidRect).map(clampRect).filter((rect) => !isAccidentalClickRect(rect)) : [],
      A2: Array.isArray(parsed.floors.A2) ? parsed.floors.A2.filter(isValidRect).map(clampRect).filter((rect) => !isAccidentalClickRect(rect)) : [],
      A3: Array.isArray(parsed.floors.A3) ? parsed.floors.A3.filter(isValidRect).map(clampRect).filter((rect) => !isAccidentalClickRect(rect)) : []
    };
  } catch {
    return cloneDrafts(DEFAULT_DRAFTS);
  }
}

function persistDrafts(): void {
  const payload: PersistedDrafts = {
    schema: "chapter4-collision-editor-draft/v1",
    floors: cloneDrafts(drafts)
  };
  try {
    window.sessionStorage.setItem(STORAGE_KEY, JSON.stringify(payload));
  } catch {
    setStatus("浏览器未允许 session 草稿存储，请在离开前复制三层 JSON。");
  }
}

function rememberSnapshot(): void {
  history.push({ drafts: cloneDrafts(drafts) });
  if (history.length > 80) history = history.slice(-80);
  undoButton.disabled = history.length === 0;
}

function selectedRect(): DraftCollisionRect | null {
  if (!selectedId) return null;
  return drafts[activeFloor].find((rect) => rect.id === selectedId) ?? null;
}

function clampRect(rect: DraftCollisionRect): DraftCollisionRect {
  const width = Math.max(MIN_RECT_SIZE, Math.min(Math.round(rect.width), WORLD.width));
  const height = Math.max(MIN_RECT_SIZE, Math.min(Math.round(rect.height), WORLD.height));
  return {
    ...rect,
    x: Math.round(Math.max(0, Math.min(rect.x, WORLD.width - width))),
    y: Math.round(Math.max(0, Math.min(rect.y, WORLD.height - height))),
    width,
    height
  };
}

function setStatus(message: string): void {
  status.textContent = message;
}

function nextDraftId(floor: StoryFloor): string {
  const used = new Set(drafts[floor].map((rect) => rect.id));
  let index = 1;
  while (used.has(`${floor.toLowerCase()}_furniture_${String(index).padStart(3, "0")}`)) index += 1;
  return `${floor.toLowerCase()}_furniture_${String(index).padStart(3, "0")}`;
}

function pointFromEvent(event: PointerEvent): { x: number; y: number } {
  const bounds = canvas.getBoundingClientRect();
  return {
    x: Math.round(Math.max(0, Math.min(WORLD.width, (event.clientX - bounds.left) * WORLD.width / bounds.width))),
    y: Math.round(Math.max(0, Math.min(WORLD.height, (event.clientY - bounds.top) * WORLD.height / bounds.height)))
  };
}

function rectFromPoints(startX: number, startY: number, endX: number, endY: number): DraftCollisionRect {
  return clampRect({
    id: nextDraftId(activeFloor),
    label: "桌椅阻挡",
    x: Math.min(startX, endX),
    y: Math.min(startY, endY),
    width: Math.max(MIN_RECT_SIZE, Math.abs(endX - startX)),
    height: Math.max(MIN_RECT_SIZE, Math.abs(endY - startY))
  });
}

function pointInsideRect(rect: CollisionRect, x: number, y: number, padding = 0): boolean {
  return x >= rect.x - padding
    && x <= rect.x + rect.width + padding
    && y >= rect.y - padding
    && y <= rect.y + rect.height + padding;
}

function hitDraft(x: number, y: number): DraftCollisionRect | null {
  return [...drafts[activeFloor]].reverse().find((rect) => pointInsideRect(rect, x, y)) ?? null;
}

function resizeHandleAt(rect: DraftCollisionRect, x: number, y: number): ResizeHandle | null {
  const displayScale = canvas.getBoundingClientRect().width / WORLD.width;
  const tolerance = Math.max(6, 11 / Math.max(displayScale, 0.1));
  const left = rect.x;
  const right = rect.x + rect.width;
  const top = rect.y;
  const bottom = rect.y + rect.height;
  const centerX = (left + right) / 2;
  const centerY = (top + bottom) / 2;
  const points: readonly [ResizeHandle, number, number][] = [
    ["nw", left, top], ["n", centerX, top], ["ne", right, top], ["e", right, centerY],
    ["se", right, bottom], ["s", centerX, bottom], ["sw", left, bottom], ["w", left, centerY]
  ];
  return points.find(([, handleX, handleY]) => Math.abs(x - handleX) <= tolerance && Math.abs(y - handleY) <= tolerance)?.[0] ?? null;
}

function moveRect(original: DraftCollisionRect, dx: number, dy: number): DraftCollisionRect {
  return clampRect({ ...original, x: original.x + dx, y: original.y + dy });
}

function resizeRect(original: DraftCollisionRect, handle: ResizeHandle, dx: number, dy: number): DraftCollisionRect {
  let left = original.x;
  let top = original.y;
  let right = original.x + original.width;
  let bottom = original.y + original.height;
  if (handle.includes("w")) left += dx;
  if (handle.includes("e")) right += dx;
  if (handle.includes("n")) top += dy;
  if (handle.includes("s")) bottom += dy;
  left = Math.max(0, Math.min(left, right - MIN_RECT_SIZE));
  top = Math.max(0, Math.min(top, bottom - MIN_RECT_SIZE));
  right = Math.min(WORLD.width, Math.max(right, left + MIN_RECT_SIZE));
  bottom = Math.min(WORLD.height, Math.max(bottom, top + MIN_RECT_SIZE));
  return clampRect({ ...original, x: left, y: top, width: right - left, height: bottom - top });
}

function drawRect(rect: CollisionRect, kind: "existing" | "draft" | "selected" | "temporary"): void {
  const styles = {
    existing: { fill: "rgba(255, 70, 98, 0.13)", stroke: "#ff6d83", line: 2 },
    draft: { fill: "rgba(241, 213, 102, 0.21)", stroke: "#f1d566", line: 3 },
    selected: { fill: "rgba(67, 199, 231, 0.29)", stroke: "#8de2f1", line: 4 },
    temporary: { fill: "rgba(141, 226, 241, 0.18)", stroke: "#d2f8ff", line: 3 }
  } as const;
  const style = styles[kind];
  context.fillStyle = style.fill;
  context.strokeStyle = style.stroke;
  context.lineWidth = style.line;
  context.setLineDash(kind === "temporary" ? [12, 8] : []);
  context.fillRect(rect.x, rect.y, rect.width, rect.height);
  context.strokeRect(rect.x, rect.y, rect.width, rect.height);
  context.setLineDash([]);

  if (kind === "existing") return;
  const label = rect.id;
  context.font = kind === "selected" ? "bold 15px monospace" : "12px monospace";
  context.textBaseline = "top";
  const labelWidth = Math.min(rect.width, context.measureText(label).width + 10);
  if (labelWidth >= 30) {
    context.fillStyle = kind === "selected" ? "rgba(4, 31, 40, 0.92)" : "rgba(39, 31, 8, 0.88)";
    context.fillRect(rect.x, rect.y, labelWidth, kind === "selected" ? 23 : 19);
    context.fillStyle = kind === "selected" ? "#dcfaff" : "#fff1ac";
    context.save();
    context.beginPath();
    context.rect(rect.x, rect.y, labelWidth, 23);
    context.clip();
    context.fillText(label, rect.x + 5, rect.y + 3);
    context.restore();
  }
}

function drawHandles(rect: DraftCollisionRect): void {
  context.fillStyle = "#fff1a3";
  context.strokeStyle = "#10232a";
  context.lineWidth = 2;
  const left = rect.x;
  const right = rect.x + rect.width;
  const top = rect.y;
  const bottom = rect.y + rect.height;
  const centerX = (left + right) / 2;
  const centerY = (top + bottom) / 2;
  [[left, top], [centerX, top], [right, top], [right, centerY], [right, bottom], [centerX, bottom], [left, bottom], [left, centerY]]
    .forEach(([x, y]) => {
      context.fillRect(x - 6, y - 6, 12, 12);
      context.strokeRect(x - 6, y - 6, 12, 12);
    });
}

function draw(): void {
  context.clearRect(0, 0, WORLD.width, WORLD.height);
  if (activeImage?.complete && activeImage.naturalWidth > 0) {
    context.drawImage(activeImage, 0, 0, WORLD.width, WORLD.height);
  } else {
    context.fillStyle = "#15232a";
    context.fillRect(0, 0, WORLD.width, WORLD.height);
    context.fillStyle = "#cbdadd";
    context.font = "24px monospace";
    context.fillText("底图加载中…", 48, 58);
  }

  if (showExistingInput.checked) {
    existingByFloor[activeFloor].forEach((rect) => drawRect(rect, "existing"));
  }
  drafts[activeFloor].forEach((rect) => drawRect(rect, rect.id === selectedId ? "selected" : "draft"));
  if (temporaryRect) drawRect(temporaryRect, "temporary");
  const selected = selectedRect();
  if (selected && editorMode === "select") drawHandles(selected);
}

function updateFloorTabs(): void {
  document.querySelectorAll<HTMLButtonElement>(".floor-tab").forEach((button) => {
    button.setAttribute("aria-pressed", String(button.dataset.floor === activeFloor));
  });
}

function updatePlateOptions(): void {
  plateSelect.innerHTML = "";
  FLOOR_PLATES[activeFloor].forEach((plate) => {
    const option = document.createElement("option");
    option.value = plate.id;
    option.textContent = plate.label;
    plateSelect.append(option);
  });
  const availableIds = new Set(FLOOR_PLATES[activeFloor].map((plate) => plate.id));
  if (!availableIds.has(activePlateId)) activePlateId = FLOOR_PLATES[activeFloor][0].id;
  plateSelect.value = activePlateId;
  loadActivePlate();
}

function loadActivePlate(): void {
  const plate = FLOOR_PLATES[activeFloor].find((option) => option.id === activePlateId) ?? FLOOR_PLATES[activeFloor][0];
  activePlateId = plate.id;
  const cached = imageCache.get(plate.url);
  if (cached) {
    activeImage = cached;
    draw();
    return;
  }
  const image = new Image();
  image.decoding = "async";
  image.addEventListener("load", () => {
    imageCache.set(plate.url, image);
    if (activePlateId !== plate.id) return;
    activeImage = image;
    setStatus(`${activeFloor} 底图已就绪。当前模式：${editorMode === "draw" ? "框选桌椅" : "选择调整"}。`);
    draw();
  });
  image.addEventListener("error", () => {
    if (activePlateId !== plate.id) return;
    setStatus(`底图 ${plate.id} 加载失败。请刷新页面或切换底图后重试。`);
    draw();
  });
  activeImage = null;
  image.src = plate.url;
  draw();
}

function updateDraftSelect(): void {
  draftSelect.innerHTML = "";
  const empty = document.createElement("option");
  empty.value = "";
  empty.textContent = drafts[activeFloor].length === 0 ? "本层还没有草稿" : "未选择";
  draftSelect.append(empty);
  drafts[activeFloor].forEach((rect) => {
    const option = document.createElement("option");
    option.value = rect.id;
    option.textContent = `${rect.id} · ${rect.x},${rect.y} ${rect.width}×${rect.height}`;
    draftSelect.append(option);
  });
  draftSelect.value = selectedRect()?.id ?? "";
}

function syncInspector(): void {
  const rect = selectedRect();
  const disabled = rect === null;
  Object.values(inputs).forEach((input) => { input.disabled = disabled; });
  deleteSelectedButton.disabled = disabled;
  if (rect) {
    inputs.id.value = rect.id;
    inputs.label.value = rect.label;
    inputs.x.value = String(rect.x);
    inputs.y.value = String(rect.y);
    inputs.width.value = String(rect.width);
    inputs.height.value = String(rect.height);
  } else {
    Object.values(inputs).forEach((input) => { input.value = ""; });
  }
  updateDraftSelect();
}

function updateCounts(): void {
  activeFloorLabel.textContent = activeFloor;
  existingCount.textContent = String(existingByFloor[activeFloor].length);
  draftCount.textContent = String(drafts[activeFloor].length);
  allFloorCounts.textContent = FLOOR_ORDER.map((floor) => `${floor}：${drafts[floor].length} 个`).join("　");
  clearFloorButton.disabled = drafts[activeFloor].length === 0;
  undoButton.disabled = history.length === 0;
}

function syncUi(): void {
  updateFloorTabs();
  drawModeButton.setAttribute("aria-pressed", String(editorMode === "draw"));
  selectModeButton.setAttribute("aria-pressed", String(editorMode === "select"));
  canvas.style.cursor = editorMode === "draw" ? "crosshair" : "default";
  syncInspector();
  updateCounts();
  applyZoom();
  draw();
}

function setEditorMode(mode: EditorMode): void {
  editorMode = mode;
  temporaryRect = null;
  drag = null;
  syncUi();
  setStatus(mode === "draw"
    ? "框选模式：按住并拖动，给一张桌子及其四周座椅画一个矩形。"
    : "调整模式：点击黄色矩形后拖动；拖八个控制点调整边界。方向键移动 1px，Shift 为 5px。");
}

function switchFloor(floor: StoryFloor): void {
  if (floor === activeFloor) return;
  activeFloor = floor;
  activePlateId = FLOOR_PLATES[floor][0].id;
  selectedId = drafts[floor][0]?.id ?? null;
  temporaryRect = null;
  drag = null;
  updatePlateOptions();
  syncUi();
  setStatus(`已切换到 ${floor}。该层草稿 ${drafts[floor].length} 个，另外两层草稿仍保留。`);
}

function applyZoom(): void {
  if (zoomSelect.value === "fit") {
    const availableWidth = Math.max(420, canvasScroll.clientWidth - 30);
    canvas.style.width = `${Math.min(WORLD.width, availableWidth)}px`;
  } else {
    const scale = Number(zoomSelect.value) / 100;
    canvas.style.width = `${Math.round(WORLD.width * scale)}px`;
  }
}

function commitDraftChange(message: string): void {
  persistDrafts();
  syncInspector();
  updateCounts();
  draw();
  setStatus(message);
}

function isAccidentalClickRect(rect: Readonly<DraftCollisionRect>): boolean {
  return rect.width === MIN_RECT_SIZE && rect.height === MIN_RECT_SIZE;
}

function exportedDraftCount(floor: StoryFloor): number {
  return drafts[floor].filter((rect) => !isAccidentalClickRect(rect)).length;
}

function accidentalClickDraftCount(): number {
  return FLOOR_ORDER.reduce(
    (total, floor) => total + drafts[floor].filter(isAccidentalClickRect).length,
    0
  );
}

function exportPayload(): object {
  return {
    schema: "chapter4-furniture-collision-draft/v1",
    coordinateSystem: {
      origin: "top_left",
      unit: "source_pixel",
      rectangleSemantics: "x_y_width_height"
    },
    worldSize: WORLD,
    authoringRule: "one visible table plus its surrounding chairs per rectangle; preserve walkable aisles",
    floors: Object.fromEntries(FLOOR_ORDER.map((floor) => [
      floor,
      drafts[floor]
        .filter((rect) => !isAccidentalClickRect(rect))
        .map((rect) => ({ ...rect }))
    ]))
  };
}

function exportJson(): string {
  return JSON.stringify(exportPayload(), null, 2);
}

canvas.addEventListener("pointerdown", (event) => {
  const point = pointFromEvent(event);
  if (editorMode === "draw") {
    temporaryRect = rectFromPoints(point.x, point.y, point.x + MIN_RECT_SIZE, point.y + MIN_RECT_SIZE);
    drag = { kind: "create", pointerId: event.pointerId, startX: point.x, startY: point.y };
    canvas.setPointerCapture(event.pointerId);
    draw();
    return;
  }

  const currentSelected = selectedRect();
  const handle = currentSelected ? resizeHandleAt(currentSelected, point.x, point.y) : null;
  const target = handle ? currentSelected : hitDraft(point.x, point.y);
  if (!target) {
    selectedId = null;
    syncInspector();
    draw();
    return;
  }
  selectedId = target.id;
  rememberSnapshot();
  drag = {
    kind: handle ? "resize" : "move",
    pointerId: event.pointerId,
    startX: point.x,
    startY: point.y,
    original: { ...target },
    handle: handle ?? undefined
  };
  canvas.setPointerCapture(event.pointerId);
  syncInspector();
  draw();
});

canvas.addEventListener("pointermove", (event) => {
  const point = pointFromEvent(event);
  pointerPosition.textContent = `坐标：${point.x}, ${point.y}`;
  const activeDrag = drag;
  if (!activeDrag || activeDrag.pointerId !== event.pointerId) return;
  if (activeDrag.kind === "create") {
    temporaryRect = rectFromPoints(activeDrag.startX, activeDrag.startY, point.x, point.y);
    draw();
    return;
  }
  const index = drafts[activeFloor].findIndex((rect) => rect.id === activeDrag.original.id);
  if (index < 0) return;
  const dx = point.x - activeDrag.startX;
  const dy = point.y - activeDrag.startY;
  drafts[activeFloor][index] = activeDrag.kind === "move"
    ? moveRect(activeDrag.original, dx, dy)
    : resizeRect(activeDrag.original, activeDrag.handle ?? "se", dx, dy);
  syncInspector();
  draw();
});

canvas.addEventListener("pointerleave", () => {
  if (!drag) pointerPosition.textContent = "坐标：—";
});

function finishPointerDrag(event: PointerEvent): void {
  if (!drag || drag.pointerId !== event.pointerId) return;
  if (drag.kind === "create" && temporaryRect) {
    const point = pointFromEvent(event);
    const draggedFarEnough = Math.abs(point.x - drag.startX) >= MIN_CREATE_DRAG_DISTANCE
      || Math.abs(point.y - drag.startY) >= MIN_CREATE_DRAG_DISTANCE;
    if (!draggedFarEnough) {
      temporaryRect = null;
      drag = null;
      canvas.releasePointerCapture(event.pointerId);
      setStatus("已忽略单击产生的 4×4 点。请按住并拖过家具实体范围。");
      draw();
      return;
    }
    const rect = temporaryRect;
    if (rect.width >= MIN_RECT_SIZE && rect.height >= MIN_RECT_SIZE) {
      rememberSnapshot();
      drafts[activeFloor].push(rect);
      selectedId = rect.id;
      temporaryRect = null;
      drag = null;
      canvas.releasePointerCapture(event.pointerId);
      commitDraftChange(`已新增 ${rect.id}：x=${rect.x}, y=${rect.y}, ${rect.width}×${rect.height}。可直接继续框选；需要微调时按 V。`);
      syncUi();
      return;
    }
  }
  const completedKind = drag.kind;
  temporaryRect = null;
  drag = null;
  canvas.releasePointerCapture(event.pointerId);
  if (completedKind === "move" || completedKind === "resize") {
    commitDraftChange("矩形位置已更新并保存到本次浏览器会话。");
  } else {
    draw();
  }
}

canvas.addEventListener("pointerup", finishPointerDrag);
canvas.addEventListener("pointercancel", finishPointerDrag);

document.querySelectorAll<HTMLButtonElement>(".floor-tab").forEach((button) => {
  button.addEventListener("click", () => switchFloor(button.dataset.floor as StoryFloor));
});

plateSelect.addEventListener("change", () => {
  activePlateId = plateSelect.value;
  loadActivePlate();
  setStatus(`已切换底图状态：${plateSelect.selectedOptions[0]?.textContent ?? activePlateId}。碰撞草稿坐标保持不变。`);
});

zoomSelect.addEventListener("change", () => {
  applyZoom();
  draw();
});

showExistingInput.addEventListener("change", draw);
drawModeButton.addEventListener("click", () => setEditorMode("draw"));
selectModeButton.addEventListener("click", () => setEditorMode("select"));

draftSelect.addEventListener("change", () => {
  selectedId = draftSelect.value || null;
  editorMode = "select";
  syncUi();
});

inputs.id.addEventListener("change", () => {
  const rect = selectedRect();
  if (!rect) return;
  const nextId = inputs.id.value.trim();
  if (!nextId) {
    inputs.id.value = rect.id;
    setStatus("ID 不能为空。");
    return;
  }
  if (drafts[activeFloor].some((entry) => entry.id === nextId && entry !== rect)) {
    inputs.id.value = rect.id;
    setStatus(`ID ${nextId} 已存在，请换一个名称。`);
    return;
  }
  rememberSnapshot();
  rect.id = nextId;
  selectedId = nextId;
  commitDraftChange("矩形 ID 已更新。");
});

inputs.label.addEventListener("change", () => {
  const rect = selectedRect();
  if (!rect) return;
  rememberSnapshot();
  rect.label = inputs.label.value.trim() || "桌椅阻挡";
  commitDraftChange("矩形说明已更新。");
});

(["x", "y", "width", "height"] as const).forEach((key) => {
  inputs[key].addEventListener("change", () => {
    const rect = selectedRect();
    if (!rect) return;
    const value = Number(inputs[key].value);
    if (!Number.isFinite(value)) {
      syncInspector();
      return;
    }
    rememberSnapshot();
    Object.assign(rect, clampRect({ ...rect, [key]: Math.round(value) }));
    commitDraftChange("矩形源像素坐标已更新。");
  });
});

deleteSelectedButton.addEventListener("click", () => {
  const rect = selectedRect();
  if (!rect) return;
  rememberSnapshot();
  drafts[activeFloor] = drafts[activeFloor].filter((entry) => entry.id !== rect.id);
  selectedId = drafts[activeFloor][0]?.id ?? null;
  commitDraftChange(`已删除 ${rect.id}。`);
});

undoButton.addEventListener("click", () => {
  const snapshot = history.pop();
  if (!snapshot) return;
  drafts = cloneDrafts(snapshot.drafts);
  selectedId = drafts[activeFloor][0]?.id ?? null;
  commitDraftChange("已撤销上一步，三层草稿状态同步恢复。");
});

clearFloorButton.addEventListener("click", () => {
  if (drafts[activeFloor].length === 0) return;
  rememberSnapshot();
  drafts[activeFloor] = [];
  selectedId = null;
  commitDraftChange(`已清空 ${activeFloor} 的新增草稿；其他楼层保持不变。`);
});

document.querySelector<HTMLButtonElement>("#copy-json")!.addEventListener("click", async () => {
  try {
    await navigator.clipboard.writeText(exportJson());
    const ignored = accidentalClickDraftCount();
    setStatus(`三层 JSON 已复制：A1 ${exportedDraftCount("A1")} 个，A2 ${exportedDraftCount("A2")} 个，A3 ${exportedDraftCount("A3")} 个${ignored > 0 ? `；已过滤 ${ignored} 个历史 4×4 误点` : ""}。`);
  } catch {
    setStatus("浏览器拒绝剪贴板写入，请使用“下载 JSON”。");
  }
});

document.querySelector<HTMLButtonElement>("#download-json")!.addEventListener("click", () => {
  const url = URL.createObjectURL(new Blob([exportJson()], { type: "application/json" }));
  const anchor = document.createElement("a");
  anchor.href = url;
  anchor.download = "chapter4-three-floor-furniture-collisions.json";
  anchor.click();
  window.setTimeout(() => URL.revokeObjectURL(url), 0);
  const ignored = accidentalClickDraftCount();
  setStatus(`三层碰撞草稿 JSON 已下载${ignored > 0 ? `；已过滤 ${ignored} 个历史 4×4 误点` : ""}。`);
});

window.addEventListener("keydown", (event) => {
  if (event.target instanceof HTMLInputElement || event.target instanceof HTMLSelectElement) return;
  if (event.key.toLowerCase() === "d") {
    setEditorMode("draw");
    return;
  }
  if (event.key.toLowerCase() === "v") {
    setEditorMode("select");
    return;
  }
  if ((event.metaKey || event.ctrlKey) && event.key.toLowerCase() === "z") {
    event.preventDefault();
    undoButton.click();
    return;
  }
  const rect = selectedRect();
  if (!rect || editorMode !== "select") return;
  const amount = event.shiftKey ? 5 : 1;
  const delta = {
    ArrowLeft: [-amount, 0],
    ArrowRight: [amount, 0],
    ArrowUp: [0, -amount],
    ArrowDown: [0, amount]
  }[event.key];
  if (!delta) return;
  event.preventDefault();
  rememberSnapshot();
  Object.assign(rect, moveRect(rect, delta[0], delta[1]));
  commitDraftChange(`已移动 ${rect.id}：x=${rect.x}, y=${rect.y}。`);
});

window.addEventListener("resize", () => {
  if (zoomSelect.value === "fit") applyZoom();
});

window.render_collision_editor_to_text = () => JSON.stringify({
  coordinateSystem: "source pixels; origin top-left; x right; y down",
  worldSize: WORLD,
  activeFloor,
  activePlateId,
  editorMode,
  showExisting: showExistingInput.checked,
  existingCollisionCount: existingByFloor[activeFloor].length,
  draftCounts: Object.fromEntries(FLOOR_ORDER.map((floor) => [floor, drafts[floor].length])),
  exportedDraftCounts: Object.fromEntries(FLOOR_ORDER.map((floor) => [floor, exportedDraftCount(floor)])),
  ignoredClickDraftCount: accidentalClickDraftCount(),
  selected: selectedRect()
});

updatePlateOptions();
setEditorMode("draw");
syncUi();
