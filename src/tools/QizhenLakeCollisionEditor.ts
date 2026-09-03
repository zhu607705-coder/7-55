import qizhenDockUrl from "../assets/rpg/interiors/qizhen_lake_dock.png";
import qizhenDockNoSignUrl from "../assets/rpg/interiors/qizhen_lake_dock_no_sign.png";
import qizhenOpenWaterUrl from "../assets/rpg/interiors/qizhen_lake_open_water.png";
import qizhenChannelUrl from "../assets/rpg/interiors/qizhen_lake_channel.png";
import qizhenSwanCoveUrl from "../assets/rpg/interiors/qizhen_lake_swan_cove.png";
import {
  QIZHEN_LAKE_TARGETS,
  QIZHEN_LAKE_WORLD,
  QIZHEN_LAKE_ZONES,
  type QizhenLakeCollisionRect,
  type QizhenLakeInteractionTarget,
  type QizhenLakeVehicle,
  type QizhenLakeZoneId
} from "../scenes/rpg/QizhenLakeModel";

type EditorMode = "draw" | "select";
type CollisionLayer = QizhenLakeVehicle;
type ResizeHandle = "nw" | "n" | "ne" | "e" | "se" | "s" | "sw" | "w";
type ZoomSetting = "fit" | "0.5" | "0.75" | "1" | "1.25";

interface PlateOption {
  id: string;
  label: string;
  url: string;
}

interface WorkingZone {
  on_foot: QizhenLakeCollisionRect[];
  kayak: QizhenLakeCollisionRect[];
}

type WorkingZones = Record<QizhenLakeZoneId, WorkingZone>;

interface PersistedDraft {
  schema: "qizhen-lake-collision-editor-session/v1";
  zones: WorkingZones;
}

interface ExportChangeAdded {
  zone: QizhenLakeZoneId;
  vehicle: CollisionLayer;
  rect: QizhenLakeCollisionRect;
}

interface ExportChangeModified {
  zone: QizhenLakeZoneId;
  vehicle: CollisionLayer;
  before: QizhenLakeCollisionRect;
  after: QizhenLakeCollisionRect;
}

interface ExportChangeDeleted {
  zone: QizhenLakeZoneId;
  vehicle: CollisionLayer;
  rect: QizhenLakeCollisionRect;
}

interface DragState {
  kind: "create" | "move" | "resize";
  pointerId: number;
  startX: number;
  startY: number;
  original?: QizhenLakeCollisionRect;
  handle?: ResizeHandle;
  historyPushed: boolean;
  preview?: QizhenLakeCollisionRect;
}

declare global {
  interface Window {
    render_qizhen_collision_editor_to_text?: () => string;
  }
}

const WORLD = QIZHEN_LAKE_WORLD;
const ZONE_ORDER: readonly QizhenLakeZoneId[] = ["dock", "open_water", "channel", "swan_cove"];
const LAYER_ORDER: readonly CollisionLayer[] = ["on_foot", "kayak"];
const STORAGE_KEY = "qizhen-lake-collision-editor-session-v1";
const MIN_RECT_SIZE = 4;
const MIN_CREATE_DRAG_DISTANCE = 8;

const ZONE_LABELS: Record<QizhenLakeZoneId, string> = {
  dock: "小码头",
  open_water: "开阔水面",
  channel: "直河道",
  swan_cove: "天鹅湾"
};

const LAYER_LABELS: Record<CollisionLayer, string> = {
  on_foot: "岸上人物",
  kayak: "皮划艇"
};

const ZONE_PLATES: Record<QizhenLakeZoneId, readonly PlateOption[]> = {
  dock: [
    { id: "dock", label: "小码头 · 常规地图", url: qizhenDockUrl },
    { id: "dock_no_sign", label: "小码头 · 拆除提示牌后", url: qizhenDockNoSignUrl }
  ],
  open_water: [{ id: "open_water", label: "开阔水面", url: qizhenOpenWaterUrl }],
  channel: [{ id: "channel", label: "直河道 · 追逐河段", url: qizhenChannelUrl }],
  swan_cove: [{ id: "swan_cove", label: "天鹅湾 · 围栏区", url: qizhenSwanCoveUrl }]
};

function queryRequired<T extends Element>(parent: ParentNode, selector: string): T {
  const element = parent.querySelector<T>(selector);
  if (!element) throw new Error(`Missing Qizhen Lake collision editor element: ${selector}`);
  return element;
}

function getRequiredCanvasContext(canvas: HTMLCanvasElement): CanvasRenderingContext2D {
  const context = canvas.getContext("2d");
  if (!context) throw new Error("Unable to create Qizhen Lake collision canvas context");
  return context;
}

const root = queryRequired<HTMLDivElement>(document, "#qizhen-lake-collision-editor");

root.innerHTML = `
  <style>
    :root {
      color-scheme: dark;
      font-family: ui-monospace, "Fusion Pixel 12px Proportional SC", "Microsoft YaHei", monospace;
      background: #071014;
    }
    * { box-sizing: border-box; }
    html, body { margin: 0; min-width: 320px; min-height: 100%; background: #071014; color: #edf7f6; }
    button, select, input { font: inherit; }
    button { cursor: pointer; }
    button:disabled, input:disabled { cursor: not-allowed; opacity: 0.48; }
    .lake-editor { min-height: 100vh; display: grid; grid-template-rows: auto minmax(0, 1fr); background: #071014; }
    .editor-header {
      position: sticky; top: 0; z-index: 10;
      display: grid; grid-template-columns: minmax(240px, 1fr) auto; gap: 14px; align-items: center;
      padding: 10px 14px; background: rgba(10, 25, 31, 0.98); border-bottom: 1px solid #48646d;
      box-shadow: 0 8px 22px rgba(0, 0, 0, 0.34);
    }
    .editor-title h1 { margin: 0 0 3px; color: #f3d66b; font-size: 17px; }
    .editor-title p { margin: 0; color: #abc0c4; font-size: 11px; line-height: 1.45; }
    .zone-tabs { display: flex; flex-wrap: wrap; justify-content: flex-end; gap: 7px; }
    .zone-tab {
      min-width: 82px; min-height: 38px; padding: 0 11px; color: #dce9e8;
      background: #14272d; border: 1px solid #58747c;
    }
    .zone-tab[aria-pressed="true"] { color: #102024; background: #f3d66b; border-color: #fff0a8; }
    .editor-body { min-height: 0; display: grid; grid-template-columns: minmax(0, 1fr) 336px; }
    .stage-column { min-width: 0; min-height: 0; display: grid; grid-template-rows: auto minmax(0, 1fr); }
    .stage-toolbar {
      display: flex; flex-wrap: wrap; align-items: center; gap: 8px 12px; min-height: 54px;
      padding: 8px 12px; background: #0d1b21; border-bottom: 1px solid #334d55;
    }
    .stage-toolbar label { display: flex; align-items: center; gap: 6px; color: #b9cccf; font-size: 11px; }
    .stage-toolbar select, .inspector input {
      height: 32px; padding: 0 8px; color: #f3f8f7; background: #14272d;
      border: 1px solid #55747d; border-radius: 2px;
    }
    #plate-select { min-width: 205px; }
    #zoom-select { min-width: 92px; }
    .button-group { display: flex; gap: 5px; }
    .tool-button {
      min-height: 32px; padding: 0 10px; color: #dce9e8; background: #14272d; border: 1px solid #58747c;
    }
    .tool-button[aria-pressed="true"] { color: #07191d; background: #86dce9; border-color: #c5f8ff; }
    .layer-button[aria-pressed="true"] { color: #172015; background: #a7e49c; border-color: #d8ffd0; }
    .mode-group { margin-left: auto; }
    .canvas-scroll {
      min-height: 0; overflow: auto; padding: 14px;
      background:
        linear-gradient(45deg, #0b171c 25%, transparent 25%) 0 0 / 18px 18px,
        linear-gradient(45deg, transparent 75%, #0b171c 75%) 0 0 / 18px 18px,
        #071014;
    }
    .canvas-frame { position: relative; width: max-content; min-width: 100%; }
    canvas {
      display: block; max-width: none; height: auto; background: #0d1a1f; border: 1px solid #68818a;
      box-shadow: 0 8px 28px rgba(0, 0, 0, 0.45); image-rendering: pixelated; touch-action: none;
    }
    canvas[data-mode="draw"] { cursor: crosshair; }
    canvas[data-mode="select"] { cursor: default; }
    .canvas-meta {
      position: sticky; left: 0; display: flex; flex-wrap: wrap; justify-content: space-between; gap: 6px 16px;
      width: min(100%, 840px); padding: 8px 2px 2px; color: #91a9af; font-size: 11px;
    }
    .canvas-meta strong { color: #f3dc7d; font-weight: 600; }
    .inspector { min-height: 0; overflow: auto; padding: 13px; background: #0e1b21; border-left: 1px solid #456069; }
    .inspector section { margin: 0 0 12px; padding: 11px; border: 1px solid #3c5962; background: #09161b; }
    .inspector h2 { margin: 0 0 8px; color: #86dce9; font-size: 13px; }
    .inspector p { margin: 0; color: #afc2c6; font-size: 11px; line-height: 1.58; }
    .legend { display: grid; gap: 7px; }
    .legend span { display: flex; align-items: center; gap: 8px; color: #bdcccf; font-size: 11px; }
    .legend i { width: 22px; height: 12px; border: 2px solid; }
    .legend .fixed { border-color: #9aa8ad; background: rgba(130, 145, 151, 0.25); }
    .legend .unchanged { border-color: #ff6e82; background: rgba(255, 75, 101, 0.18); }
    .legend .modified { border-color: #ffad55; background: rgba(255, 151, 55, 0.23); }
    .legend .added { border-color: #70e89d; background: rgba(67, 218, 122, 0.22); }
    .legend .reference { border-color: #6bc9ff; background: rgba(59, 174, 234, 0.13); }
    .legend .selected { border-color: #8eeeff; background: rgba(57, 213, 239, 0.3); }
    .field-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 8px; }
    .field-grid .wide { grid-column: 1 / -1; }
    .inspector label { display: grid; gap: 4px; color: #9fb5ba; font-size: 10px; }
    .inspector input { width: 100%; min-width: 0; }
    .action-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 8px; }
    .action-grid button, .wide-action {
      min-height: 35px; padding: 6px 9px; color: #edf6f4; background: #172a30; border: 1px solid #59757d;
    }
    .action-grid button:hover:not(:disabled), .wide-action:hover:not(:disabled) { border-color: #90dce7; }
    .danger { color: #ffd8dd !important; border-color: #98545e !important; }
    .wide-action { width: 100%; margin-top: 8px; }
    .change-counts { display: grid; grid-template-columns: repeat(3, 1fr); gap: 7px; margin-top: 9px; }
    .change-counts div { padding: 7px 4px; text-align: center; background: #102129; border: 1px solid #35505a; }
    .change-counts strong { display: block; color: #f3d66b; font-size: 16px; }
    .change-counts span { color: #9eb3b8; font-size: 9px; }
    .status { min-height: 34px; margin-top: 8px; padding: 8px; color: #c1d2d4; background: #102027; border-left: 3px solid #6ecbd9; font-size: 10px; line-height: 1.45; }
    kbd { padding: 1px 5px; color: #f5e59c; background: #182b31; border: 1px solid #526d75; }
    @media (max-width: 900px) {
      .editor-header { grid-template-columns: 1fr; }
      .zone-tabs { justify-content: flex-start; }
      .editor-body { grid-template-columns: 1fr; grid-template-rows: minmax(520px, 70vh) auto; }
      .inspector { border-left: 0; border-top: 1px solid #456069; }
      .mode-group { margin-left: 0; }
    }
  </style>
  <main class="lake-editor">
    <header class="editor-header">
      <div class="editor-title">
        <h1>启真湖 · 空气墙调试</h1>
        <p>四张 1672×941 源图共用源像素坐标。编辑内容只保存在本标签页，并导出为草稿，不会直接改动正式游戏。</p>
      </div>
      <nav class="zone-tabs" aria-label="启真湖地图"></nav>
    </header>
    <div class="editor-body">
      <section class="stage-column">
        <div class="stage-toolbar">
          <label>地图底图 <select id="plate-select"></select></label>
          <label>缩放
            <select id="zoom-select">
              <option value="fit">适合窗口</option>
              <option value="0.5">50%</option>
              <option value="0.75">75%</option>
              <option value="1">100%</option>
              <option value="1.25">125%</option>
            </select>
          </label>
          <div class="button-group" aria-label="碰撞对象">
            <button class="tool-button layer-button" type="button" data-layer="on_foot">岸上人物</button>
            <button class="tool-button layer-button" type="button" data-layer="kayak">皮划艇</button>
          </div>
          <label><input id="show-water" type="checkbox" checked /> 水域/遮挡</label>
          <label><input id="show-targets" type="checkbox" checked /> 出生点/目标</label>
          <div class="button-group mode-group" aria-label="编辑模式">
            <button class="tool-button" type="button" data-mode="select">选择/移动</button>
            <button class="tool-button" type="button" data-mode="draw">框选新增</button>
          </div>
        </div>
        <div class="canvas-scroll">
          <div class="canvas-frame">
            <canvas id="collision-canvas" width="${WORLD.width}" height="${WORLD.height}"></canvas>
            <div class="canvas-meta">
              <span id="cursor-position">坐标：—</span>
              <span id="active-summary"></span>
              <span>按 <kbd>Delete</kbd> 删除所选 · <kbd>Ctrl/⌘ Z</kbd> 撤销 · 方向键微调</span>
            </div>
          </div>
        </div>
      </section>
      <aside class="inspector" id="inspector"></aside>
    </div>
  </main>
`;

const canvas = queryRequired<HTMLCanvasElement>(root, "#collision-canvas");
const canvasScroll = queryRequired<HTMLDivElement>(root, ".canvas-scroll");
const zoneTabs = queryRequired<HTMLElement>(root, ".zone-tabs");
const plateSelect = queryRequired<HTMLSelectElement>(root, "#plate-select");
const zoomSelect = queryRequired<HTMLSelectElement>(root, "#zoom-select");
const showWaterInput = queryRequired<HTMLInputElement>(root, "#show-water");
const showTargetsInput = queryRequired<HTMLInputElement>(root, "#show-targets");
const cursorPosition = queryRequired<HTMLElement>(root, "#cursor-position");
const activeSummary = queryRequired<HTMLElement>(root, "#active-summary");
const inspector = queryRequired<HTMLElement>(root, "#inspector");
const context = getRequiredCanvasContext(canvas);

const cloneRect = (rect: QizhenLakeCollisionRect): QizhenLakeCollisionRect => ({ ...rect });
const cloneWorkingZones = (source: WorkingZones): WorkingZones => ({
  dock: { on_foot: source.dock.on_foot.map(cloneRect), kayak: source.dock.kayak.map(cloneRect) },
  open_water: { on_foot: source.open_water.on_foot.map(cloneRect), kayak: source.open_water.kayak.map(cloneRect) },
  channel: { on_foot: source.channel.on_foot.map(cloneRect), kayak: source.channel.kayak.map(cloneRect) },
  swan_cove: { on_foot: source.swan_cove.on_foot.map(cloneRect), kayak: source.swan_cove.kayak.map(cloneRect) }
});

const baseline: WorkingZones = {
  dock: {
    on_foot: QIZHEN_LAKE_ZONES.dock.onFootCollisions.map(cloneRect),
    kayak: QIZHEN_LAKE_ZONES.dock.kayakCollisions.map(cloneRect)
  },
  open_water: {
    on_foot: QIZHEN_LAKE_ZONES.open_water.onFootCollisions.map(cloneRect),
    kayak: QIZHEN_LAKE_ZONES.open_water.kayakCollisions.map(cloneRect)
  },
  channel: {
    on_foot: QIZHEN_LAKE_ZONES.channel.onFootCollisions.map(cloneRect),
    kayak: QIZHEN_LAKE_ZONES.channel.kayakCollisions.map(cloneRect)
  },
  swan_cove: {
    on_foot: QIZHEN_LAKE_ZONES.swan_cove.onFootCollisions.map(cloneRect),
    kayak: QIZHEN_LAKE_ZONES.swan_cove.kayakCollisions.map(cloneRect)
  }
};

let activeZone: QizhenLakeZoneId = "dock";
let activeLayer: CollisionLayer = "kayak";
let mode: EditorMode = "select";
let zoomSetting: ZoomSetting = "fit";
let working = loadPersistedDraft();
let selectedId: string | null = null;
let plateImage = new Image();
let plateReady = false;
let dragState: DragState | null = null;
let history: WorkingZones[] = [];
let statusMessage = "已载入正式空气墙副本。先选择并移动现有矩形，或切换到“框选新增”。";

function isValidRect(value: unknown): value is QizhenLakeCollisionRect {
  if (!value || typeof value !== "object") return false;
  const rect = value as Partial<QizhenLakeCollisionRect>;
  return typeof rect.id === "string"
    && [rect.left, rect.top, rect.right, rect.bottom].every((coordinate) => typeof coordinate === "number" && Number.isFinite(coordinate))
    && (rect.right ?? 0) > (rect.left ?? 0)
    && (rect.bottom ?? 0) > (rect.top ?? 0);
}

function loadPersistedDraft(): WorkingZones {
  try {
    const raw = sessionStorage.getItem(STORAGE_KEY);
    if (!raw) return cloneWorkingZones(baseline);
    const parsed = JSON.parse(raw) as Partial<PersistedDraft>;
    if (parsed.schema !== "qizhen-lake-collision-editor-session/v1" || !parsed.zones) {
      return cloneWorkingZones(baseline);
    }
    const result = cloneWorkingZones(baseline);
    ZONE_ORDER.forEach((zone) => {
      LAYER_ORDER.forEach((layer) => {
        const candidates = parsed.zones?.[zone]?.[layer];
        if (Array.isArray(candidates) && candidates.every(isValidRect)) {
          result[zone][layer] = candidates.map((rect) => normalizeRect(rect));
        }
      });
    });
    return result;
  } catch {
    return cloneWorkingZones(baseline);
  }
}

function persistDraft(): void {
  const payload: PersistedDraft = {
    schema: "qizhen-lake-collision-editor-session/v1",
    zones: cloneWorkingZones(working)
  };
  sessionStorage.setItem(STORAGE_KEY, JSON.stringify(payload));
}

function isWorldBoundary(rect: QizhenLakeCollisionRect): boolean {
  return rect.id.startsWith("world_");
}

function rectsEqual(a: QizhenLakeCollisionRect, b: QizhenLakeCollisionRect): boolean {
  return a.id === b.id && a.left === b.left && a.top === b.top && a.right === b.right && a.bottom === b.bottom;
}

function normalizeRect(rect: QizhenLakeCollisionRect): QizhenLakeCollisionRect {
  let left = Math.round(Math.min(rect.left, rect.right));
  let right = Math.round(Math.max(rect.left, rect.right));
  let top = Math.round(Math.min(rect.top, rect.bottom));
  let bottom = Math.round(Math.max(rect.top, rect.bottom));
  left = Math.max(0, Math.min(WORLD.width - MIN_RECT_SIZE, left));
  top = Math.max(0, Math.min(WORLD.height - MIN_RECT_SIZE, top));
  right = Math.max(left + MIN_RECT_SIZE, Math.min(WORLD.width, right));
  bottom = Math.max(top + MIN_RECT_SIZE, Math.min(WORLD.height, bottom));
  return { id: rect.id, left, top, right, bottom };
}

function currentRects(): QizhenLakeCollisionRect[] {
  return working[activeZone][activeLayer];
}

function selectedRect(): QizhenLakeCollisionRect | null {
  return selectedId ? currentRects().find((rect) => rect.id === selectedId) ?? null : null;
}

function baselineRect(zone: QizhenLakeZoneId, layer: CollisionLayer, id: string): QizhenLakeCollisionRect | null {
  return baseline[zone][layer].find((rect) => rect.id === id) ?? null;
}

function pushHistory(): void {
  history.push(cloneWorkingZones(working));
  if (history.length > 80) history = history.slice(-80);
}

function undo(): void {
  const previous = history.pop();
  if (!previous) {
    setStatus("当前没有可撤销的修改。");
    return;
  }
  working = previous;
  if (selectedId && !currentRects().some((rect) => rect.id === selectedId)) selectedId = null;
  persistDraft();
  setStatus("已撤销上一步修改。");
  renderAll();
}

function nextRectId(): string {
  const prefix = `qizhen_${activeZone}_${activeLayer}_air_wall_`;
  const allIds = new Set(ZONE_ORDER.flatMap((zone) => LAYER_ORDER.flatMap((layer) => working[zone][layer].map((rect) => rect.id))));
  let index = 1;
  while (allIds.has(`${prefix}${String(index).padStart(3, "0")}`)) index += 1;
  return `${prefix}${String(index).padStart(3, "0")}`;
}

function getChanges(): {
  added: ExportChangeAdded[];
  modified: ExportChangeModified[];
  deleted: ExportChangeDeleted[];
} {
  const added: ExportChangeAdded[] = [];
  const modified: ExportChangeModified[] = [];
  const deleted: ExportChangeDeleted[] = [];
  ZONE_ORDER.forEach((zone) => {
    LAYER_ORDER.forEach((vehicle) => {
      const originalById = new Map(baseline[zone][vehicle].map((rect) => [rect.id, rect]));
      const workingById = new Map(working[zone][vehicle].map((rect) => [rect.id, rect]));
      working[zone][vehicle].forEach((rect) => {
        const original = originalById.get(rect.id);
        if (!original) added.push({ zone, vehicle, rect: cloneRect(rect) });
        else if (!rectsEqual(original, rect)) modified.push({ zone, vehicle, before: cloneRect(original), after: cloneRect(rect) });
      });
      baseline[zone][vehicle].forEach((rect) => {
        if (!workingById.has(rect.id)) deleted.push({ zone, vehicle, rect: cloneRect(rect) });
      });
    });
  });
  return { added, modified, deleted };
}

function buildExportPayload(): object {
  const changes = getChanges();
  return {
    schema: "qizhen-lake-collision-draft/v1",
    coordinateSystem: {
      origin: "top_left",
      unit: "source_pixel",
      rectangleSemantics: "left_top_right_bottom"
    },
    worldSize: { ...WORLD },
    authoringRule: "空气墙只覆盖可见实体；保留水上通路、出生点、区域入口和交互目标的可达空间。",
    zones: {
      dock: {
        onFootCollisions: working.dock.on_foot.map(cloneRect),
        kayakCollisions: working.dock.kayak.map(cloneRect)
      },
      open_water: {
        onFootCollisions: working.open_water.on_foot.map(cloneRect),
        kayakCollisions: working.open_water.kayak.map(cloneRect)
      },
      channel: {
        onFootCollisions: working.channel.on_foot.map(cloneRect),
        kayakCollisions: working.channel.kayak.map(cloneRect)
      },
      swan_cove: {
        onFootCollisions: working.swan_cove.on_foot.map(cloneRect),
        kayakCollisions: working.swan_cove.kayak.map(cloneRect)
      }
    },
    changes
  };
}

function exportJson(): string {
  return JSON.stringify(buildExportPayload(), null, 2);
}

function setStatus(message: string): void {
  statusMessage = message;
  const status = inspector.querySelector<HTMLElement>("#editor-status");
  if (status) status.textContent = statusMessage;
}

function effectiveZoom(): number {
  if (zoomSetting !== "fit") return Number(zoomSetting);
  const width = Math.max(280, canvasScroll.clientWidth - 30);
  const height = Math.max(220, canvasScroll.clientHeight - 50);
  return Math.min(1, width / WORLD.width, height / WORLD.height);
}

function applyCanvasScale(): void {
  const zoom = effectiveZoom();
  canvas.style.width = `${Math.round(WORLD.width * zoom)}px`;
  canvas.style.height = `${Math.round(WORLD.height * zoom)}px`;
}

function pointerToWorld(event: PointerEvent): { x: number; y: number } {
  const bounds = canvas.getBoundingClientRect();
  return {
    x: Math.max(0, Math.min(WORLD.width, (event.clientX - bounds.left) * (WORLD.width / bounds.width))),
    y: Math.max(0, Math.min(WORLD.height, (event.clientY - bounds.top) * (WORLD.height / bounds.height)))
  };
}

function drawFilledRect(rect: QizhenLakeCollisionRect, stroke: string, fill: string, lineWidth = 3, dashed = false): void {
  context.save();
  context.strokeStyle = stroke;
  context.fillStyle = fill;
  context.lineWidth = lineWidth;
  if (dashed) context.setLineDash([10, 7]);
  context.fillRect(rect.left, rect.top, rect.right - rect.left, rect.bottom - rect.top);
  context.strokeRect(rect.left, rect.top, rect.right - rect.left, rect.bottom - rect.top);
  context.restore();
}

function drawLabel(text: string, x: number, y: number, color: string): void {
  context.save();
  context.font = "600 16px ui-monospace, monospace";
  const width = Math.min(440, context.measureText(text).width + 12);
  const labelX = Math.max(0, Math.min(WORLD.width - width, x));
  const labelY = Math.max(18, Math.min(WORLD.height, y));
  context.fillStyle = "rgba(4, 13, 17, 0.84)";
  context.fillRect(labelX, labelY - 18, width, 22);
  context.fillStyle = color;
  context.fillText(text, labelX + 6, labelY - 2, width - 12);
  context.restore();
}

function drawReferenceOverlays(): void {
  const definition = QIZHEN_LAKE_ZONES[activeZone];
  if (showWaterInput.checked) {
    definition.waterAreas.forEach((area) => {
      drawFilledRect(area, "rgba(83, 194, 255, 0.82)", "rgba(40, 150, 221, 0.10)", 3, true);
      drawLabel(`水域 · ${area.id}`, area.left + 6, area.top + 24, "#95dcff");
    });
    definition.occlusions.forEach((rect) => {
      drawFilledRect(rect, "rgba(192, 119, 255, 0.85)", "rgba(152, 75, 213, 0.10)", 3, true);
      drawLabel(`前景遮挡 · ${rect.id}`, rect.left + 6, rect.top + 24, "#ddb5ff");
    });
  }
  if (!showTargetsInput.checked) return;

  const targets = QIZHEN_LAKE_TARGETS.filter((target) => (
    target.zone === activeZone && (!target.vehicle || target.vehicle === activeLayer)
  ));
  targets.forEach((target) => drawTarget(target));

  if (activeLayer === "on_foot") {
    drawPoint(definition.onFootSpawn.x, definition.onFootSpawn.y, "#ffe37a", "人物出生点");
  } else {
    drawHeadingPoint(definition.kayakSpawn.x, definition.kayakSpawn.y, definition.kayakSpawn.heading, "皮划艇出生点", "#ffbd64");
    Object.entries(definition.kayakEntrySpawns).forEach(([fromZone, spawn]) => {
      if (spawn) drawHeadingPoint(spawn.x, spawn.y, spawn.heading, `由${ZONE_LABELS[fromZone as QizhenLakeZoneId]}进入`, "#f7d692");
    });
  }
}

function drawTarget(target: QizhenLakeInteractionTarget): void {
  const width = target.dropWidth ?? target.width ?? target.proximity * 2;
  const height = target.dropHeight ?? target.height ?? target.proximity * 2;
  const rect: QizhenLakeCollisionRect = {
    id: target.id,
    left: target.x - width / 2,
    top: target.y - height / 2,
    right: target.x + width / 2,
    bottom: target.y + height / 2
  };
  drawFilledRect(rect, "rgba(77, 223, 239, 0.92)", "rgba(35, 188, 211, 0.10)", 3, true);
  drawLabel(`目标 · ${target.label}`, rect.left + 4, rect.top + 22, "#9af3ff");
  context.save();
  context.fillStyle = "#d8fbff";
  context.beginPath();
  context.arc(target.x, target.y, 7, 0, Math.PI * 2);
  context.fill();
  context.restore();
  if (target.stand) drawPoint(target.stand.x, target.stand.y, "#7df0c0", `站位 · ${target.label}`);
}

function drawPoint(x: number, y: number, color: string, label: string): void {
  context.save();
  context.fillStyle = color;
  context.strokeStyle = "rgba(5, 14, 18, 0.9)";
  context.lineWidth = 4;
  context.beginPath();
  context.arc(x, y, 11, 0, Math.PI * 2);
  context.fill();
  context.stroke();
  context.restore();
  drawLabel(label, x + 14, y - 10, color);
}

function drawHeadingPoint(x: number, y: number, heading: number, label: string, color: string): void {
  drawPoint(x, y, color, label);
  context.save();
  context.strokeStyle = color;
  context.lineWidth = 6;
  context.beginPath();
  context.moveTo(x, y);
  context.lineTo(x + Math.cos(heading) * 54, y + Math.sin(heading) * 54);
  context.stroke();
  context.restore();
}

function rectChangeKind(rect: QizhenLakeCollisionRect): "fixed" | "unchanged" | "modified" | "added" {
  if (isWorldBoundary(rect)) return "fixed";
  const original = baselineRect(activeZone, activeLayer, rect.id);
  if (!original) return "added";
  return rectsEqual(original, rect) ? "unchanged" : "modified";
}

function drawCollisionRects(): void {
  currentRects().forEach((rect) => {
    const kind = rectChangeKind(rect);
    const colors = {
      fixed: ["rgba(175, 190, 195, 0.9)", "rgba(125, 142, 148, 0.22)"],
      unchanged: ["rgba(255, 95, 119, 0.96)", "rgba(255, 67, 94, 0.19)"],
      modified: ["rgba(255, 175, 78, 0.98)", "rgba(255, 145, 43, 0.24)"],
      added: ["rgba(102, 238, 151, 0.98)", "rgba(58, 211, 113, 0.23)"]
    }[kind];
    drawFilledRect(rect, colors[0], colors[1], rect.id === selectedId ? 5 : 3);
    drawLabel(rect.id, rect.left + 4, rect.top + 20, colors[0]);
  });

  const selected = selectedRect();
  if (selected) {
    drawFilledRect(selected, "#8eeeff", "rgba(57, 213, 239, 0.18)", 5);
    if (!isWorldBoundary(selected)) drawResizeHandles(selected);
  }
  if (dragState?.kind === "create" && dragState.preview) {
    drawFilledRect(dragState.preview, "#f3d66b", "rgba(243, 214, 107, 0.20)", 4, true);
  }
}

function handlePoints(rect: QizhenLakeCollisionRect): Record<ResizeHandle, { x: number; y: number }> {
  const midX = (rect.left + rect.right) / 2;
  const midY = (rect.top + rect.bottom) / 2;
  return {
    nw: { x: rect.left, y: rect.top }, n: { x: midX, y: rect.top }, ne: { x: rect.right, y: rect.top },
    e: { x: rect.right, y: midY }, se: { x: rect.right, y: rect.bottom }, s: { x: midX, y: rect.bottom },
    sw: { x: rect.left, y: rect.bottom }, w: { x: rect.left, y: midY }
  };
}

function drawResizeHandles(rect: QizhenLakeCollisionRect): void {
  const radius = 7 / effectiveZoom();
  context.save();
  Object.values(handlePoints(rect)).forEach((point) => {
    context.fillStyle = "#e9fcff";
    context.strokeStyle = "#167c91";
    context.lineWidth = Math.max(2, 2 / effectiveZoom());
    context.fillRect(point.x - radius, point.y - radius, radius * 2, radius * 2);
    context.strokeRect(point.x - radius, point.y - radius, radius * 2, radius * 2);
  });
  context.restore();
}

function renderCanvas(): void {
  context.clearRect(0, 0, WORLD.width, WORLD.height);
  context.imageSmoothingEnabled = false;
  if (plateReady) context.drawImage(plateImage, 0, 0, WORLD.width, WORLD.height);
  else {
    context.fillStyle = "#102129";
    context.fillRect(0, 0, WORLD.width, WORLD.height);
    context.fillStyle = "#b8c9cc";
    context.font = "32px ui-monospace, monospace";
    context.fillText("正在加载地图底图…", 60, 80);
  }
  drawReferenceOverlays();
  drawCollisionRects();
}

function renderZoneTabs(): void {
  zoneTabs.innerHTML = ZONE_ORDER.map((zone) => (
    `<button type="button" class="zone-tab" data-zone="${zone}" aria-pressed="${zone === activeZone}">${ZONE_LABELS[zone]}</button>`
  )).join("");
  zoneTabs.querySelectorAll<HTMLButtonElement>("[data-zone]").forEach((button) => {
    button.addEventListener("click", () => {
      const next = button.dataset.zone as QizhenLakeZoneId;
      if (next === activeZone) return;
      activeZone = next;
      selectedId = null;
      updatePlateOptions();
      setStatus(`已切换到${ZONE_LABELS[activeZone]}，当前编辑${LAYER_LABELS[activeLayer]}空气墙。`);
      renderAll();
    });
  });
}

function updatePlateOptions(): void {
  const options = ZONE_PLATES[activeZone];
  plateSelect.innerHTML = options.map((plate) => `<option value="${plate.id}">${plate.label}</option>`).join("");
  loadPlate(options[0]);
}

function loadPlate(plate: PlateOption): void {
  plateReady = false;
  plateImage = new Image();
  plateImage.addEventListener("load", () => {
    plateReady = true;
    renderCanvas();
  });
  plateImage.addEventListener("error", () => {
    plateReady = false;
    setStatus(`底图加载失败：${plate.label}。空气墙数据仍可导出。`);
    renderCanvas();
  });
  plateImage.src = plate.url;
  renderCanvas();
}

function renderToolbarState(): void {
  root.querySelectorAll<HTMLButtonElement>("[data-layer]").forEach((button) => {
    button.setAttribute("aria-pressed", String(button.dataset.layer === activeLayer));
  });
  root.querySelectorAll<HTMLButtonElement>("[data-mode]").forEach((button) => {
    button.setAttribute("aria-pressed", String(button.dataset.mode === mode));
  });
  canvas.dataset.mode = mode;
  const changes = getChanges();
  activeSummary.innerHTML = `<strong>${ZONE_LABELS[activeZone]} · ${LAYER_LABELS[activeLayer]}</strong>　${currentRects().length} 个空气墙　全局改动 ${changes.added.length + changes.modified.length + changes.deleted.length} 项`;
}

function renderInspector(): void {
  const rect = selectedRect();
  const locked = rect ? isWorldBoundary(rect) : false;
  const changes = getChanges();
  inspector.innerHTML = `
    <section>
      <h2>操作说明</h2>
      <p><strong>${mode === "select" ? "选择/移动" : "框选新增"}</strong>模式。红色为现有空气墙，橙色为已调整，绿色为新增。世界四边界锁定。水域、遮挡、出生点与目标仅作可达性参照。</p>
    </section>
    <section>
      <h2>图层图例</h2>
      <div class="legend">
        <span><i class="fixed"></i> 固定世界边界</span>
        <span><i class="unchanged"></i> 正式空气墙副本</span>
        <span><i class="modified"></i> 已移动或缩放</span>
        <span><i class="added"></i> 本次新增</span>
        <span><i class="reference"></i> 水域、目标与出生点参照</span>
        <span><i class="selected"></i> 当前选中</span>
      </div>
    </section>
    <section>
      <h2>矩形检查器</h2>
      ${rect ? `
        <div class="field-grid">
          <label class="wide">ID<input id="field-id" value="${escapeHtml(rect.id)}" ${locked ? "disabled" : ""} /></label>
          <label>Left<input id="field-left" type="number" value="${rect.left}" ${locked ? "disabled" : ""} /></label>
          <label>Top<input id="field-top" type="number" value="${rect.top}" ${locked ? "disabled" : ""} /></label>
          <label>Right<input id="field-right" type="number" value="${rect.right}" ${locked ? "disabled" : ""} /></label>
          <label>Bottom<input id="field-bottom" type="number" value="${rect.bottom}" ${locked ? "disabled" : ""} /></label>
          <label>Width<input value="${rect.right - rect.left}" disabled /></label>
          <label>Height<input value="${rect.bottom - rect.top}" disabled /></label>
        </div>
        <button id="delete-selected" class="wide-action danger" type="button" ${locked ? "disabled" : ""}>删除当前矩形</button>
        ${locked ? "<p style=\"margin-top:8px\">地图边界用于限制角色与船体离开 1672×941 源图，调试页不允许修改。</p>" : ""}
      ` : "<p>点击一个空气墙查看和修改精确坐标。切到“框选新增”可在底图上拖出新矩形。</p>"}
    </section>
    <section>
      <h2>草稿与导出</h2>
      <p>导出包含四张地图、两套完整碰撞数组及相对当前源码的增改删清单。</p>
      <div class="change-counts">
        <div><strong>${changes.added.length}</strong><span>新增</span></div>
        <div><strong>${changes.modified.length}</strong><span>修改</span></div>
        <div><strong>${changes.deleted.length}</strong><span>删除</span></div>
      </div>
      <div class="action-grid" style="margin-top:8px">
        <button id="undo-change" type="button" ${history.length === 0 ? "disabled" : ""}>撤销</button>
        <button id="reset-current" type="button">重置当前层</button>
        <button id="copy-json" type="button">复制完整 JSON</button>
        <button id="download-json" type="button">下载 JSON</button>
      </div>
      <button id="reset-all" class="wide-action danger" type="button">重置四图全部草稿</button>
      <div class="status" id="editor-status">${escapeHtml(statusMessage)}</div>
    </section>
  `;
  bindInspectorEvents(rect, locked);
}

function escapeHtml(value: string): string {
  return value.replace(/[&<>"]/g, (character) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", "\"": "&quot;" })[character] ?? character);
}

function bindInspectorEvents(rect: QizhenLakeCollisionRect | null, locked: boolean): void {
  if (rect && !locked) {
    const idField = inspector.querySelector<HTMLInputElement>("#field-id");
    const coordinateFields = ["left", "top", "right", "bottom"] as const;
    const commitId = (): void => {
      if (!idField || !idField.isConnected) return;
      const value = idField.value.trim();
      if (!value || currentRects().some((candidate) => candidate !== rect && candidate.id === value)) {
        setStatus(value ? `ID “${value}” 已存在，请换一个名称。` : "ID 不能为空。");
        renderInspector();
        return;
      }
      if (value === rect.id) return;
      pushHistory();
      rect.id = value;
      selectedId = value;
      persistDraft();
      setStatus("已更新矩形 ID。");
      renderAll();
    };
    idField?.addEventListener("change", commitId);
    idField?.addEventListener("keydown", (event) => {
      if (event.key === "Enter") commitId();
    });
    coordinateFields.forEach((key) => {
      const input = inspector.querySelector<HTMLInputElement>(`#field-${key}`);
      const commitCoordinate = (): void => {
        if (!input || !input.isConnected) return;
        const value = Number(input.value);
        if (!Number.isFinite(value)) {
          renderInspector();
          return;
        }
        if (value === rect[key]) return;
        pushHistory();
        const updated = normalizeRect({ ...rect, [key]: value });
        Object.assign(rect, updated);
        persistDraft();
        setStatus("已按源像素坐标更新矩形。");
        renderAll();
      };
      input?.addEventListener("change", commitCoordinate);
      input?.addEventListener("keydown", (event) => {
        if (event.key === "Enter") commitCoordinate();
      });
    });
    inspector.querySelector<HTMLButtonElement>("#delete-selected")?.addEventListener("click", deleteSelected);
  }
  inspector.querySelector<HTMLButtonElement>("#undo-change")?.addEventListener("click", undo);
  inspector.querySelector<HTMLButtonElement>("#reset-current")?.addEventListener("click", () => {
    pushHistory();
    working[activeZone][activeLayer] = baseline[activeZone][activeLayer].map(cloneRect);
    selectedId = null;
    persistDraft();
    setStatus(`已把${ZONE_LABELS[activeZone]}的${LAYER_LABELS[activeLayer]}空气墙恢复为当前源码。`);
    renderAll();
  });
  inspector.querySelector<HTMLButtonElement>("#reset-all")?.addEventListener("click", () => {
    pushHistory();
    working = cloneWorkingZones(baseline);
    selectedId = null;
    persistDraft();
    setStatus("已把四张地图的两套空气墙全部恢复为当前源码。");
    renderAll();
  });
  inspector.querySelector<HTMLButtonElement>("#copy-json")?.addEventListener("click", async () => {
    try {
      await navigator.clipboard.writeText(exportJson());
      setStatus("完整碰撞草稿已复制，可直接粘贴给我。");
    } catch {
      setStatus("浏览器拒绝剪贴板访问，请使用“下载 JSON”。");
    }
  });
  inspector.querySelector<HTMLButtonElement>("#download-json")?.addEventListener("click", () => {
    const blob = new Blob([exportJson()], { type: "application/json;charset=utf-8" });
    const url = URL.createObjectURL(blob);
    const anchor = document.createElement("a");
    anchor.href = url;
    anchor.download = "qizhen-lake-collision-draft.json";
    anchor.click();
    URL.revokeObjectURL(url);
    setStatus("已下载完整碰撞草稿 JSON。");
  });
}

function renderAll(): void {
  applyCanvasScale();
  renderZoneTabs();
  renderToolbarState();
  renderCanvas();
  renderInspector();
}

function deleteSelected(): void {
  const rect = selectedRect();
  if (!rect || isWorldBoundary(rect)) return;
  pushHistory();
  working[activeZone][activeLayer] = currentRects().filter((candidate) => candidate !== rect);
  selectedId = null;
  persistDraft();
  setStatus(`已删除空气墙 ${rect.id}。`);
  renderAll();
}

function findHandle(rect: QizhenLakeCollisionRect, x: number, y: number): ResizeHandle | null {
  const tolerance = 11 / effectiveZoom();
  for (const [handle, point] of Object.entries(handlePoints(rect)) as [ResizeHandle, { x: number; y: number }][]) {
    if (Math.abs(x - point.x) <= tolerance && Math.abs(y - point.y) <= tolerance) return handle;
  }
  return null;
}

function hitTest(x: number, y: number): QizhenLakeCollisionRect | null {
  const rects = currentRects();
  for (let index = rects.length - 1; index >= 0; index -= 1) {
    const rect = rects[index];
    if (x >= rect.left && x <= rect.right && y >= rect.top && y <= rect.bottom) return rect;
  }
  return null;
}

function resizedRect(original: QizhenLakeCollisionRect, handle: ResizeHandle, dx: number, dy: number): QizhenLakeCollisionRect {
  const next = { ...original };
  if (handle.includes("w")) next.left += dx;
  if (handle.includes("e")) next.right += dx;
  if (handle.includes("n")) next.top += dy;
  if (handle.includes("s")) next.bottom += dy;
  return normalizeRect(next);
}

function movedRect(original: QizhenLakeCollisionRect, dx: number, dy: number): QizhenLakeCollisionRect {
  const width = original.right - original.left;
  const height = original.bottom - original.top;
  const left = Math.max(0, Math.min(WORLD.width - width, Math.round(original.left + dx)));
  const top = Math.max(0, Math.min(WORLD.height - height, Math.round(original.top + dy)));
  return { ...original, left, top, right: left + width, bottom: top + height };
}

canvas.addEventListener("pointerdown", (event) => {
  const point = pointerToWorld(event);
  canvas.setPointerCapture(event.pointerId);
  if (mode === "draw") {
    dragState = {
      kind: "create", pointerId: event.pointerId, startX: point.x, startY: point.y,
      historyPushed: false,
      preview: { id: "preview", left: point.x, top: point.y, right: point.x + MIN_RECT_SIZE, bottom: point.y + MIN_RECT_SIZE }
    };
    renderCanvas();
    return;
  }

  const selected = selectedRect();
  const handle = selected && !isWorldBoundary(selected) ? findHandle(selected, point.x, point.y) : null;
  if (selected && handle) {
    dragState = {
      kind: "resize", pointerId: event.pointerId, startX: point.x, startY: point.y,
      original: cloneRect(selected), handle, historyPushed: false
    };
    return;
  }

  const hit = hitTest(point.x, point.y);
  selectedId = hit?.id ?? null;
  if (hit && !isWorldBoundary(hit)) {
    dragState = {
      kind: "move", pointerId: event.pointerId, startX: point.x, startY: point.y,
      original: cloneRect(hit), historyPushed: false
    };
  } else {
    dragState = null;
  }
  renderCanvas();
  renderInspector();
});

canvas.addEventListener("pointermove", (event) => {
  const point = pointerToWorld(event);
  cursorPosition.textContent = `坐标：${Math.round(point.x)}, ${Math.round(point.y)}`;
  if (!dragState || dragState.pointerId !== event.pointerId) return;
  const dx = point.x - dragState.startX;
  const dy = point.y - dragState.startY;

  if (dragState.kind === "create") {
    dragState.preview = normalizeRect({
      id: "preview", left: dragState.startX, top: dragState.startY, right: point.x, bottom: point.y
    });
    renderCanvas();
    return;
  }

  const rect = selectedRect();
  if (!rect || !dragState.original) return;
  if (!dragState.historyPushed && Math.hypot(dx, dy) >= 1) {
    pushHistory();
    dragState.historyPushed = true;
  }
  const updated = dragState.kind === "move"
    ? movedRect(dragState.original, dx, dy)
    : resizedRect(dragState.original, dragState.handle ?? "se", dx, dy);
  Object.assign(rect, updated);
  renderCanvas();
  renderInspector();
});

function finishPointer(event: PointerEvent): void {
  if (!dragState || dragState.pointerId !== event.pointerId) return;
  if (dragState.kind === "create" && dragState.preview) {
    const width = dragState.preview.right - dragState.preview.left;
    const height = dragState.preview.bottom - dragState.preview.top;
    if (width >= MIN_CREATE_DRAG_DISTANCE && height >= MIN_CREATE_DRAG_DISTANCE) {
      pushHistory();
      const rect = { ...dragState.preview, id: nextRectId() };
      currentRects().push(rect);
      selectedId = rect.id;
      mode = "select";
      setStatus(`已新增空气墙 ${rect.id}，可继续拖动边角或填写精确坐标。`);
    } else {
      setStatus("框选范围过小，未新增空气墙。");
    }
  } else if (dragState.historyPushed) {
    persistDraft();
    setStatus("空气墙位置已更新并保存在当前标签页。");
  }
  dragState = null;
  persistDraft();
  renderAll();
}

canvas.addEventListener("pointerup", finishPointer);
canvas.addEventListener("pointercancel", () => {
  if (dragState?.kind !== "create" && dragState?.historyPushed && dragState.original) {
    const rect = selectedRect();
    if (rect) Object.assign(rect, dragState.original);
    history.pop();
  }
  dragState = null;
  renderAll();
});
canvas.addEventListener("pointerleave", () => {
  if (!dragState) cursorPosition.textContent = "坐标：—";
});

root.querySelectorAll<HTMLButtonElement>("[data-layer]").forEach((button) => {
  button.addEventListener("click", () => {
    activeLayer = button.dataset.layer as CollisionLayer;
    selectedId = null;
    setStatus(`当前编辑${ZONE_LABELS[activeZone]}的${LAYER_LABELS[activeLayer]}空气墙。`);
    renderAll();
  });
});

root.querySelectorAll<HTMLButtonElement>("[data-mode]").forEach((button) => {
  button.addEventListener("click", () => {
    mode = button.dataset.mode as EditorMode;
    setStatus(mode === "draw" ? "在底图上按住并拖动，框出新的空气墙。" : "点击现有空气墙进行移动、缩放或精确编辑。" );
    renderAll();
  });
});

plateSelect.addEventListener("change", () => {
  const plate = ZONE_PLATES[activeZone].find((candidate) => candidate.id === plateSelect.value);
  if (plate) loadPlate(plate);
});

zoomSelect.addEventListener("change", () => {
  zoomSetting = zoomSelect.value as ZoomSetting;
  applyCanvasScale();
  renderCanvas();
});

showWaterInput.addEventListener("change", renderCanvas);
showTargetsInput.addEventListener("change", renderCanvas);
window.addEventListener("resize", () => {
  if (zoomSetting === "fit") {
    applyCanvasScale();
    renderCanvas();
  }
});

window.addEventListener("keydown", (event) => {
  const activeElement = document.activeElement;
  if (activeElement instanceof HTMLInputElement || activeElement instanceof HTMLSelectElement) return;
  if ((event.metaKey || event.ctrlKey) && event.key.toLowerCase() === "z") {
    event.preventDefault();
    undo();
    return;
  }
  if ((event.key === "Delete" || event.key === "Backspace") && selectedRect() && !isWorldBoundary(selectedRect()!)) {
    event.preventDefault();
    deleteSelected();
    return;
  }
  const rect = selectedRect();
  if (!rect || isWorldBoundary(rect) || !["ArrowLeft", "ArrowRight", "ArrowUp", "ArrowDown"].includes(event.key)) return;
  event.preventDefault();
  pushHistory();
  const step = event.shiftKey ? 10 : 1;
  const dx = event.key === "ArrowLeft" ? -step : event.key === "ArrowRight" ? step : 0;
  const dy = event.key === "ArrowUp" ? -step : event.key === "ArrowDown" ? step : 0;
  Object.assign(rect, movedRect(rect, dx, dy));
  persistDraft();
  setStatus(`已用方向键移动 ${step} 个源像素。`);
  renderAll();
});

window.render_qizhen_collision_editor_to_text = () => JSON.stringify({
  editor: "qizhen_lake_collision",
  world: WORLD,
  activeZone,
  activeZoneLabel: ZONE_LABELS[activeZone],
  activeLayer,
  activeLayerLabel: LAYER_LABELS[activeLayer],
  mode,
  plateReady,
  plate: plateSelect.value,
  rectangleCount: currentRects().length,
  selected: selectedRect(),
  changes: getChanges(),
  references: {
    waterAreas: QIZHEN_LAKE_ZONES[activeZone].waterAreas.length,
    occlusions: QIZHEN_LAKE_ZONES[activeZone].occlusions.length,
    targets: QIZHEN_LAKE_TARGETS.filter((target) => target.zone === activeZone && (!target.vehicle || target.vehicle === activeLayer)).length
  }
});
window.render_game_to_text = window.render_qizhen_collision_editor_to_text;

updatePlateOptions();
renderAll();
