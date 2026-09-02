import * as THREE from "three";
import "./chapter-four-monument-stair-demo.css";

import {
  buildMechanismRuntime,
  buildNavGraph,
  evaluatePerspectiveSeams,
  findPath,
  nearestBoundaryNode,
  resolveConnectorWorld,
  selectDirectionalNeighbor,
  stepMechanism
} from "./chapter4-stair/engine";
import type { ConnectorWorldState, OcclusionTest, ScreenPoint } from "./chapter4-stair/engine";
import { getStairLevel, LEVEL_CAMERAS } from "./chapter4-stair/levels";
import {
  addHardOutline,
  configurePixelRenderer,
  createBlobShadow,
  createStairBoxGeometry,
  createStairMaterial,
  disposeStairMaterials,
  getStairMaterialTextureStatus,
  lowSegCylinder,
  lowSegSphere,
  STAIR_PALETTE
} from "./chapter4-stair/pixelStyle";
import { StairPlayerSprite } from "./chapter4-stair/playerSprite";
import {
  CAMERA_TRANSITION_MS,
  CANVAS_HEIGHT,
  CANVAS_WIDTH,
  IDLE_HINT_MS,
  INTERNAL_HEIGHT,
  INTERNAL_WIDTH,
  INVALID_SEAM_HOLD_MS,
  LEVEL_CURTAIN_MS
} from "./chapter4-stair/types";
import type {
  CameraViewId,
  DecorationSpec,
  DemoPhase,
  LevelId,
  MechanismDefinition,
  NavEdgeKind,
  NavGraph,
  PerspectiveSeam,
  StairDemoDevApi,
  StairDemoSnapshot,
  StairLevelDefinition
} from "./chapter4-stair/types";

/**
 * 第四章楼梯间三视角正交投影空间解谜 —— 独立 Demo 主入口。
 * 设计依据：docs/plans/2026-08-08-chapter4-monument-perspective-two-level-design.md
 *
 * 本文件负责：渲染管线（§8.1，480×270 内部缓冲 → 960×540 最近邻放大）、
 * 三个固定正交视角（§5.1）、投影接缝表现（§5.3 / §8.5）、点击移动与
 * 断路停边（§5.4）、机关交互与携带（§5.5）、两关流程与转场（§6.5 / §7 / §9）、
 * 像素 UI（§8.6）、render_game_to_text 与 stairDemoDev 调试接口（§10）。
 * 关卡数据、投影判定与图搜索全部来自 src/tools/chapter4-stair/ 四个模块。
 */

declare global {
  interface Window {
    // render_game_to_text 已在 src/vite-env.d.ts 声明，这里只补本 Demo 的开发 API。
    stairDemoDev?: StairDemoDevApi;
  }
}

/* ------------------------------ 常量 ------------------------------ */

const VIEW_ORDER: readonly CameraViewId[] = ["south_east", "south_west", "top_oblique"];
const VIEW_GLYPHS: Record<CameraViewId, string> = {
  south_east: "◢",
  south_west: "◣",
  top_oblique: "⬢"
};
const VIEW_NAMES: Record<CameraViewId, string> = {
  south_east: "东南",
  south_west: "西南",
  top_oblique: "上方"
};

/** 行走速度（世界单位/秒）。 */
const WALK_SPEED = 2.4;
/** 投影边通行的最短时长，保证接缝连续可读。 */
const PERSPECTIVE_MIN_WALK_MS = 620;
/** 世界坐标在投影边进度 45% 处切换到目标端点空间（§8.4）。 */
const PERSPECTIVE_SPACE_SWITCH_T = 0.45;
/** 投影边逐帧画面跳变上限（内部像素，§8.4）。 */
const PERSPECTIVE_MAX_SCREEN_JUMP_PX = 2;
/** 机关单档动画时长（§5.5：420–520ms 区间取中）。 */
const MECHANISM_ANIM_MS = 470;
/** 升降/横移动画的显示更新节拍（§8.5：每 60ms 一次整数像素位移）。 */
const MECHANISM_LINEAR_TICK_MS = 60;
/** 旋转 90° 的离散姿态帧数（§8.5）。 */
const ROTATE_POSE_COUNT = 4;
/** 正交半高 5.5 → 竖直 11 世界单位对应内部 270px。 */
const PX_PER_WORLD = INTERNAL_HEIGHT / 11;
/** 消防门四帧开门（§8.5），每帧时长。 */
const DOOR_FRAMES = 4;
const DOOR_FRAME_MS = 95;
/** 人物走入门内的时长。 */
const DOOR_WALK_IN_MS = 520;
/** 有效接缝四帧出现动画总时长（§8.5）。 */
const SEAM_VALID_ANIM_MS = 440;
/** 错误接缝三帧动画中“闪一次”窗口。 */
const SEAM_INVALID_FLASH_MS = 240;
/** 局部反馈文案的驻留时长。 */
const TOAST_MS = 3400;
/** 正式章节的四段场景演出。时长只承担视觉建立，关卡判定仍由导航图负责。 */
const ENTRY_SEQUENCE_MS = 2100;
const LEVEL_BREAK_SEQUENCE_MS = 1750;
const LEVEL_REVEAL_SEQUENCE_MS = 1650;
const FINALE_SEQUENCE_MS = 2400;
/** 所有空间特效按离散时间片更新，保持硬边像素节奏。 */
const SPATIAL_FX_TICK_MS = 70;

/* ------------------------------ DOM ------------------------------ */

export interface ChapterFourMonumentStairMountOptions {
  onComplete?: () => void;
  subscribeDirection?: (listener: (direction: ScreenPoint) => void) => () => void;
}

export function mountChapterFourMonumentStairDemo(
  root: HTMLElement,
  options: ChapterFourMonumentStairMountOptions = {}
): () => void {

root.innerHTML = `
  <section class="stair-shell">
    <header class="stair-topbar">
      <span class="stair-chapter">04</span>
      <div class="stair-topbar-text">
        <h1 class="stair-level-name">楼梯间</h1>
        <p class="stair-objective"></p>
      </div>
      <span class="stair-level-progress" aria-label="空间校准进度"><b>01</b><i>/02</i></span>
    </header>
    <div class="stair-mid">
      <div class="stair-stage-wrap">
        <div class="stair-stage">
          <canvas class="stair-canvas" width="${INTERNAL_WIDTH}" height="${INTERNAL_HEIGHT}" aria-label="楼梯间三维像素场景"></canvas>
          <div class="stair-screen-fx" aria-hidden="true">
            <span class="stair-screen-fx-frame"></span>
            <span class="stair-screen-fx-corner is-nw"></span>
            <span class="stair-screen-fx-corner is-ne"></span>
            <span class="stair-screen-fx-corner is-sw"></span>
            <span class="stair-screen-fx-corner is-se"></span>
            <span class="stair-screen-fx-scan"></span>
            <span class="stair-screen-fx-flash"></span>
          </div>
          <div class="stair-sequence" hidden aria-live="polite">
            <span class="stair-sequence-index"></span>
            <strong class="stair-sequence-title"></strong>
            <p class="stair-sequence-detail"></p>
            <span class="stair-sequence-track"><i></i></span>
          </div>
          <div class="stair-curtain" hidden></div>
          <div class="stair-complete" hidden>
            <div class="stair-complete-card">
              <span class="stair-complete-chapter">A2</span>
              <b>下降通路已固定</b>
              <p>重新校准可再次观察两段空间结构。</p>
              <button class="stair-pixel-button" type="button" data-act="replay">↺ 重新校准</button>
            </div>
          </div>
          <div class="stair-webgl-error" hidden>
            <div class="stair-webgl-error-card">
              <b>无法启动三维画面</b>
              <p>当前浏览器或设备不支持 WebGL。请更换浏览器后重试。</p>
              <a class="stair-pixel-button" href="./index.html">返回游戏主页</a>
            </div>
          </div>
        </div>
      </div>
      <nav class="stair-views" aria-label="视角切换">
        ${VIEW_ORDER.map(
          (view, index) => `
        <button class="stair-view-button" type="button" data-view="${view}"
          aria-label="${VIEW_NAMES[view]}视角（快捷键 ${index + 1}）" aria-pressed="false">
          <span class="stair-view-glyph" aria-hidden="true">${VIEW_GLYPHS[view]}</span>
          <span class="stair-view-num">${index + 1}</span>
        </button>`
        ).join("")}
      </nav>
    </div>
    <footer class="stair-bottombar">
      <p class="stair-status" role="status"></p>
      <div class="stair-mech">
        <span class="stair-mech-label">未选中机关</span>
        <button class="stair-pixel-button" type="button" data-act="mech-minus">Q</button>
        <button class="stair-pixel-button" type="button" data-act="mech-plus">E</button>
      </div>
      <button class="stair-pixel-button stair-reset" type="button" data-act="reset" aria-label="重置当前关卡">↺ 重置本关</button>
    </footer>
  </section>
`;

const topbarEl = root.querySelector<HTMLElement>(".stair-topbar")!;
const levelNameEl = root.querySelector<HTMLElement>(".stair-level-name")!;
const objectiveEl = root.querySelector<HTMLElement>(".stair-objective")!;
const levelProgressEl = root.querySelector<HTMLElement>(".stair-level-progress")!;
const stageWrapEl = root.querySelector<HTMLElement>(".stair-stage-wrap")!;
const stageEl = root.querySelector<HTMLElement>(".stair-stage")!;
const canvasEl = root.querySelector<HTMLCanvasElement>(".stair-canvas")!;
const sequenceEl = root.querySelector<HTMLElement>(".stair-sequence")!;
const sequenceIndexEl = root.querySelector<HTMLElement>(".stair-sequence-index")!;
const sequenceTitleEl = root.querySelector<HTMLElement>(".stair-sequence-title")!;
const sequenceDetailEl = root.querySelector<HTMLElement>(".stair-sequence-detail")!;
const sequenceTrackFillEl = root.querySelector<HTMLElement>(".stair-sequence-track i")!;
const curtainEl = root.querySelector<HTMLElement>(".stair-curtain")!;
const completeEl = root.querySelector<HTMLElement>(".stair-complete")!;
const webglErrorEl = root.querySelector<HTMLElement>(".stair-webgl-error")!;
const statusEl = root.querySelector<HTMLElement>(".stair-status")!;
const mechLabelEl = root.querySelector<HTMLElement>(".stair-mech-label")!;
const mechMinusButton = root.querySelector<HTMLButtonElement>("[data-act='mech-minus']")!;
const mechPlusButton = root.querySelector<HTMLButtonElement>("[data-act='mech-plus']")!;
const resetButton = root.querySelector<HTMLButtonElement>("[data-act='reset']")!;
const replayButton = root.querySelector<HTMLButtonElement>("[data-act='replay']")!;
const viewsEl = root.querySelector<HTMLElement>(".stair-views")!;
const viewButtons = new Map<CameraViewId, HTMLButtonElement>();
root.querySelectorAll<HTMLButtonElement>(".stair-view-button").forEach((button) => {
  viewButtons.set(button.dataset.view as CameraViewId, button);
});

/* 像素块遮罩（§9：16×9 块，不用透明度淡入）。 */
const CURTAIN_COLS = 16;
const CURTAIN_ROWS = 9;
const curtainBlocks: HTMLElement[] = [];
for (let row = 0; row < CURTAIN_ROWS; row += 1) {
  for (let col = 0; col < CURTAIN_COLS; col += 1) {
    const block = document.createElement("span");
    block.className = "stair-curtain-block";
    block.dataset.col = String(col);
    curtainEl.appendChild(block);
    curtainBlocks.push(block);
  }
}

const reducedMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches;

/* ------------------------- WebGL 可用性（§11） ------------------------- */

let renderer: THREE.WebGLRenderer | null = null;
try {
  if (!window.WebGLRenderingContext) {
    throw new Error("WebGLRenderingContext unavailable");
  }
  renderer = new THREE.WebGLRenderer({
    canvas: canvasEl,
    antialias: false,
    powerPreference: "high-performance"
  });
} catch {
  renderer = null;
}

if (!renderer) {
  webglErrorEl.hidden = false;
  canvasEl.hidden = true;
  return () => {
    root.replaceChildren();
  };
}
const disposeRuntime = boot(renderer);
return () => {
  disposeRuntime();
  renderer.dispose();
  root.replaceChildren();
};

/* ==================================================================== */

function boot(renderer: THREE.WebGLRenderer): () => void {
  /* §8.1：内部 480×270 缓冲，抗锯齿在构造参数关闭，像素比恒 1。 */
  configurePixelRenderer(renderer);
  renderer.setSize(INTERNAL_WIDTH, INTERNAL_HEIGHT, false);
  renderer.setClearColor(STAIR_PALETTE.outline, 1);

  const scene = new THREE.Scene();
  scene.background = new THREE.Color(STAIR_PALETTE.outline);

  const camera = new THREE.OrthographicCamera(-9.8, 9.8, 5.5, -5.5, 0.1, 80);

  const player = new StairPlayerSprite();
  scene.add(player.object3d);
  const playerShadow = createBlobShadow(0.42, 0.3);
  scene.add(playerShadow);

  /* ---------------------------- 运行时状态 ---------------------------- */

  interface FireDoorHandle {
    group: THREE.Group;
    panel: THREE.Mesh;
    closedX: number;
    openOffset: number;
  }

  interface LevelScene {
    definition: StairLevelDefinition;
    group: THREE.Group;
    mechanismGroups: Map<string, THREE.Group>;
    /** 可点击选中机关的实体网格。 */
    mechanismHitMeshes: THREE.Object3D[];
    /** 可走表面网格（含机关台面）。 */
    walkMeshes: THREE.Object3D[];
    /** §5.3 规则 5 的实心遮挡面。 */
    occluderMeshes: THREE.Object3D[];
    door: FireDoorHandle | null;
    /** 纯表现层：不参与射线、遮挡、导航图或完成判定。 */
    effectRoot: THREE.Group;
    effectMaterials: THREE.Material[];
    floatingFragments: FloatingFragment[];
    energyRings: THREE.LineLoop[];
    dustField: THREE.Points | null;
    routeEffect: RouteEffect | null;
  }

  interface FloatingFragment {
    object: THREE.Object3D;
    basePosition: THREE.Vector3;
    driftDirection: THREE.Vector3;
    phase: number;
    spinX: number;
    spinY: number;
  }

  interface RouteEffect {
    group: THREE.Group;
    line: THREE.Line;
    sparks: THREE.Points;
    pointCount: number;
    startedAt: number;
  }

  interface CameraTransition {
    to: CameraViewId;
    fromPos: THREE.Vector3;
    toPos: THREE.Vector3;
    startedAt: number;
    duration: number;
  }

  interface MechanismAnimation {
    id: string;
    kind: MechanismDefinition["kind"];
    delta: -1 | 1;
    startedAt: number;
    duration: number;
    fromAngle: number;
    toAngle: number;
    fromOffset: THREE.Vector3;
    toOffset: THREE.Vector3;
  }

  interface WalkState {
    path: string[];
    edgeKinds: (NavEdgeKind | null)[];
    edgeIds: (string | null)[];
    index: number;
    elapsed: number;
    duration: number;
    fromPos: THREE.Vector3;
    toPos: THREE.Vector3;
    targetNodeId: string;
    blocked: boolean;
    wrongDirection: boolean;
    lastScreen: ScreenPoint | null;
  }

  type SeamVisualState = "appear" | "stable" | "invalid";

  interface SeamVisual {
    linkId: string;
    valid: boolean;
    line: THREE.Line;
    lineMaterial: THREE.LineBasicMaterial;
    markerA: THREE.Sprite;
    markerB: THREE.Sprite;
    pointA: THREE.Vector3;
    pointB: THREE.Vector3;
    /** 屏幕空间缝合线的两个世界端点（沿接缝中点与切线屏幕方向展开，保证可读）。 */
    stitchStart: THREE.Vector3;
    stitchEnd: THREE.Vector3;
    state: SeamVisualState;
    startedAt: number;
    firstInvalid: boolean;
  }

  interface CurtainState {
    phase: "cover" | "reveal";
    startedAt: number;
    onCovered: (() => void) | null;
  }

  interface LevelCompleteState {
    stage: "door" | "walk_in";
    startedAt: number;
    walkFrom: THREE.Vector3;
    walkTo: THREE.Vector3;
  }

  type PresentationStage = "entry" | "level_break" | "level_reveal" | "finale";

  interface PresentationState {
    stage: PresentationStage;
    startedAt: number;
    duration: number;
    onFinished: (() => void) | null;
  }

  const state = {
    levelId: "stair_a" as LevelId,
    phase: "playing" as DemoPhase,
    cameraView: "south_east" as CameraViewId,
    playerNodeId: "A_START",
    targetNodeId: null as string | null,
    selectedMechanismId: null as string | null,
    lockedPerspectiveEdgeId: null as string | null
  };

  let levelScene: LevelScene;
  let levelDef: StairLevelDefinition;
  let mechanismValues: Record<string, number> = {};
  /** rotate 机关的连续角度，保证逐档动画不走回头路。 */
  const mechanismAngles = new Map<string, number>();
  let navGraph: NavGraph;
  let connectorWorld: ReadonlyMap<string, ConnectorWorldState>;
  let currentSeams: PerspectiveSeam[] = [];
  let graphRevision = 0;
  let firstSeamToastShown = false;
  let lastBlockedSignature: string | null = null;
  const invalidHoldDone = new Set<string>();

  let cameraTransition: CameraTransition | null = null;
  let mechanismAnimation: MechanismAnimation | null = null;
  let walk: WalkState | null = null;
  let curtain: CurtainState | null = null;
  let levelComplete: LevelCompleteState | null = null;
  let presentation: PresentationState | null = null;
  const seamVisuals = new Map<string, SeamVisual>();

  let lastInputAt = performance.now();
  let idlePulseUntil = 0;
  let toastTimer = 0;

  const pointerRay = new THREE.Raycaster();
  pointerRay.params.Line.threshold = 0;
  const occlusionRay = new THREE.Raycaster();
  occlusionRay.params.Line.threshold = 0;
  const scratchA = new THREE.Vector3();
  const scratchB = new THREE.Vector3();
  const scratchC = new THREE.Vector3();

  const selectionBox = new THREE.Box3();
  const selectionHelper = new THREE.Box3Helper(selectionBox, new THREE.Color(STAIR_PALETTE.selection));
  selectionHelper.visible = false;
  scene.add(selectionHelper);

  /* ---------------------------- 场景构建 ---------------------------- */

  function mechanismById(id: string): MechanismDefinition {
    const definition = levelDef.mechanisms.find((mechanism) => mechanism.id === id);
    if (!definition) {
      throw new Error(`Unknown mechanism "${id}".`);
    }
    return definition;
  }

  /** 机关拥有者的局部坐标换算：rotate 组原点位于 pivot，其余组直接用 0 档世界坐标。 */
  function localize(ownerId: string, position: THREE.Vector3): THREE.Vector3 {
    if (ownerId === "level") {
      return position;
    }
    const definition = mechanismById(ownerId);
    if (definition.kind === "rotate") {
      return position.sub(new THREE.Vector3(definition.pivot[0], definition.pivot[1], definition.pivot[2]));
    }
    return position;
  }

  function parentFor(ownerId: string): THREE.Object3D {
    if (ownerId === "level") {
      return levelScene.group;
    }
    return levelScene.mechanismGroups.get(ownerId)!;
  }

  function registerMesh(
    mesh: THREE.Mesh,
    ownerId: string,
    options: { walkable?: boolean; mechanismId?: string; nodeId?: string; occluder?: boolean }
  ): void {
    mesh.userData.ownerId = ownerId;
    if (options.walkable) mesh.userData.walkable = true;
    if (options.mechanismId) mesh.userData.mechanismId = options.mechanismId;
    if (options.nodeId) mesh.userData.nodeId = options.nodeId;
    if (options.occluder) mesh.userData.occluder = true;
    if (options.walkable) levelScene.walkMeshes.push(mesh);
    if (options.mechanismId) levelScene.mechanismHitMeshes.push(mesh);
    if (options.occluder) levelScene.occluderMeshes.push(mesh);
  }

  function buildPlatforms(): void {
    for (const spec of levelDef.geometry.platforms) {
      const mesh = new THREE.Mesh(
        createStairBoxGeometry(spec.size[0], spec.size[1], spec.size[2]),
        createStairMaterial(spec.material)
      );
      mesh.name = spec.id;
      mesh.position.copy(localize(spec.ownerId, new THREE.Vector3(spec.center[0], spec.center[1], spec.center[2])));
      addHardOutline(mesh);
      const isMechanism = spec.ownerId !== "level";
      registerMesh(mesh, spec.ownerId, {
        walkable: spec.walkable,
        mechanismId: isMechanism ? spec.ownerId : undefined,
        occluder: !spec.walkable
      });
      parentFor(spec.ownerId).add(mesh);
    }
  }

  function buildStairs(): void {
    for (const spec of levelDef.geometry.stairs) {
      const from = new THREE.Vector3(spec.from[0], spec.from[1], spec.from[2]);
      const to = new THREE.Vector3(spec.to[0], spec.to[1], spec.to[2]);
      const run = to.clone().sub(from);
      const yaw = Math.atan2(-run.z, run.x);
      const stepLength = Math.hypot(run.x, run.z) / spec.steps;
      const isMechanism = spec.ownerId !== "level";
      for (let index = 0; index < spec.steps; index += 1) {
        const t = (index + 0.5) / spec.steps;
        const position = from.clone().lerp(to, t);
        position.y -= 0.13;
        const step = new THREE.Mesh(
          createStairBoxGeometry(stepLength + 0.07, 0.26, spec.width),
          createStairMaterial(spec.material)
        );
        step.name = `${spec.id}-step-${index}`;
        step.rotation.y = yaw;
        step.position.copy(localize(spec.ownerId, position));
        addHardOutline(step);
        registerMesh(step, spec.ownerId, {
          walkable: true,
          mechanismId: isMechanism ? spec.ownerId : undefined
        });
        parentFor(spec.ownerId).add(step);
      }
    }
  }

  function buildFireDoor(spec: DecorationSpec): FireDoorHandle {
    const group = new THREE.Group();
    group.name = spec.id;
    group.position.set(spec.position[0], spec.position[1], spec.position[2]);
    group.rotation.y = spec.rotationY ?? 0;

    const postGeometry = createStairBoxGeometry(0.22, 2.3, 0.34);
    const lintelGeometry = createStairBoxGeometry(1.7, 0.24, 0.36);
    const outlineMaterial = createStairMaterial("outline");
    const leftPost = new THREE.Mesh(postGeometry, outlineMaterial);
    leftPost.position.set(-0.74, 1.15, 0);
    const rightPost = new THREE.Mesh(postGeometry, outlineMaterial);
    rightPost.position.set(0.74, 1.15, 0);
    const lintel = new THREE.Mesh(lintelGeometry, outlineMaterial);
    lintel.position.set(0, 2.3, 0);
    group.add(leftPost, rightPost, lintel);

    const panel = new THREE.Mesh(
      createStairBoxGeometry(1.24, 2.06, 0.14),
      createStairMaterial("wall_side")
    );
    panel.name = `${spec.id}-panel`;
    panel.position.set(0, 1.03, 0);
    addHardOutline(panel);
    const stripe = new THREE.Mesh(createStairBoxGeometry(1.24, 0.18, 0.16), createStairMaterial("warn"));
    stripe.position.set(0, 0.34, 0);
    panel.add(stripe);
    group.add(panel);

    // 门整体可点击，映射到本关出口节点（§5.4）。
    group.traverse((object) => {
      if (object instanceof THREE.Mesh) {
        object.userData.nodeId = levelDef.exitNodeId;
        levelScene.walkMeshes.push(object);
      }
    });
    levelScene.group.add(group);
    return { group, panel, closedX: 0, openOffset: 1.32 };
  }

  function buildDecoration(spec: DecorationSpec): void {
    if (spec.kind === "fire_door") {
      levelScene.door = buildFireDoor(spec);
      return;
    }
    const group = new THREE.Group();
    group.name = spec.id;
    group.position.set(spec.position[0], spec.position[1], spec.position[2]);
    group.rotation.y = spec.rotationY ?? 0;
    if (spec.kind === "floor_plate") {
      const plate = new THREE.Mesh(createStairBoxGeometry(1.05, 0.72, 0.08), createStairMaterial("structure"));
      const face = new THREE.Mesh(createStairBoxGeometry(0.85, 0.52, 0.04), createStairMaterial("wall_lit"));
      face.position.z = 0.04;
      const mark = new THREE.Mesh(createStairBoxGeometry(0.2, 0.2, 0.05), createStairMaterial("warn"));
      mark.position.set(-0.26, 0, 0.05);
      group.add(plate, face, mark);
    } else if (spec.kind === "wall_lamp") {
      const bracket = new THREE.Mesh(createStairBoxGeometry(0.16, 0.3, 0.12), createStairMaterial("outline"));
      const lamp = new THREE.Mesh(createStairBoxGeometry(0.34, 0.2, 0.14), createStairMaterial("wall_lit"));
      lamp.position.set(0, 0.24, 0.04);
      group.add(bracket, lamp);
    } else if (spec.kind === "window_frame") {
      const frame = new THREE.Mesh(createStairBoxGeometry(1.3, 1.6, 0.1), createStairMaterial("structure"));
      const glass = new THREE.Mesh(createStairBoxGeometry(1.06, 1.36, 0.06), createStairMaterial("night_glass"));
      glass.position.z = 0.03;
      const barV = new THREE.Mesh(createStairBoxGeometry(0.08, 1.36, 0.08), createStairMaterial("structure"));
      barV.position.z = 0.06;
      const barH = new THREE.Mesh(createStairBoxGeometry(1.06, 0.08, 0.08), createStairMaterial("structure"));
      barH.position.z = 0.06;
      group.add(frame, glass, barV, barH);
    } else {
      // potted_plant
      const pot = new THREE.Mesh(lowSegCylinder(0.2, 0.26, 0.3, 6), createStairMaterial("warn"));
      pot.position.y = 0.15;
      const foliage = new THREE.Mesh(lowSegSphere(0.3), createStairMaterial("stone_back"));
      foliage.position.y = 0.52;
      group.add(pot, foliage);
    }
    levelScene.group.add(group);
  }

  /**
   * 在真实楼梯结构外围增加离散漂浮构件、能量环和尘点。
   * 这些对象不会注册到交互、遮挡或导航集合，视觉密度不会改变谜题答案。
   */
  function buildSpatialEffects(definition: StairLevelDefinition): void {
    const fragmentMaterial = new THREE.MeshBasicMaterial({
      color: STAIR_PALETTE.selection,
      transparent: true,
      opacity: definition.id === "stair_a" ? 0.2 : 0.26,
      depthWrite: false,
      fog: false,
      toneMapped: false,
      blending: THREE.AdditiveBlending
    });
    const fragmentEdgeMaterial = new THREE.LineBasicMaterial({
      color: STAIR_PALETTE.seamValid,
      transparent: true,
      opacity: 0.7,
      depthWrite: false,
      fog: false,
      toneMapped: false,
      blending: THREE.AdditiveBlending
    });
    const ringMaterial = new THREE.LineBasicMaterial({
      color: STAIR_PALETTE.selection,
      transparent: true,
      opacity: 0.34,
      depthWrite: false,
      fog: false,
      toneMapped: false,
      blending: THREE.AdditiveBlending
    });
    const dustMaterial = new THREE.PointsMaterial({
      color: STAIR_PALETTE.seamValid,
      size: definition.id === "stair_a" ? 0.075 : 0.09,
      sizeAttenuation: true,
      transparent: true,
      opacity: 0.46,
      depthWrite: false,
      fog: false,
      toneMapped: false,
      blending: THREE.AdditiveBlending
    });
    levelScene.effectMaterials.push(fragmentMaterial, fragmentEdgeMaterial, ringMaterial, dustMaterial);

    const fragmentCount = definition.id === "stair_a" ? 30 : 46;
    const maxY = definition.id === "stair_a" ? 5.2 : 10.2;
    for (let index = 0; index < fragmentCount; index += 1) {
      const side = index % 2 === 0 ? -1 : 1;
      const lane = ((index * 37) % 101) / 100;
      const depth = ((index * 53 + 17) % 97) / 96;
      const height = ((index * 29 + 11) % 89) / 88;
      const width = 0.16 + (index % 5) * 0.07;
      const fragmentHeight = 0.12 + ((index + 2) % 4) * 0.08;
      const fragmentDepth = 0.12 + ((index + 1) % 3) * 0.09;
      const geometry = createStairBoxGeometry(width, fragmentHeight, fragmentDepth, 0.7);
      const fragment = new THREE.Mesh(geometry, fragmentMaterial);
      fragment.name = `${definition.id}-spatial-fragment-${index}`;
      const base = new THREE.Vector3(
        side * (5.4 + lane * 4.4),
        0.5 + height * maxY,
        -4.7 + depth * 9.4
      );
      fragment.position.copy(base);
      fragment.rotation.set((index % 7) * 0.23, (index % 9) * 0.31, (index % 5) * 0.19);
      fragment.renderOrder = 14;
      const edge = new THREE.LineSegments(new THREE.EdgesGeometry(geometry, 1), fragmentEdgeMaterial);
      edge.renderOrder = 15;
      fragment.add(edge);
      levelScene.effectRoot.add(fragment);
      levelScene.floatingFragments.push({
        object: fragment,
        basePosition: base,
        driftDirection: new THREE.Vector3(side, 0.28 + (index % 3) * 0.08, depth - 0.5).normalize(),
        phase: index * 0.71,
        spinX: 0.08 + (index % 4) * 0.025,
        spinY: 0.11 + (index % 5) * 0.02
      });
    }

    const ringCount = definition.id === "stair_a" ? 3 : 5;
    for (let index = 0; index < ringCount; index += 1) {
      const points: THREE.Vector3[] = [];
      const sides = index % 2 === 0 ? 8 : 6;
      const radius = 1.25 + index * 0.42;
      for (let point = 0; point < sides; point += 1) {
        const angle = (point / sides) * Math.PI * 2;
        points.push(new THREE.Vector3(Math.cos(angle) * radius, Math.sin(angle) * radius, 0));
      }
      const ring = new THREE.LineLoop(new THREE.BufferGeometry().setFromPoints(points), ringMaterial);
      ring.name = `${definition.id}-energy-ring-${index}`;
      ring.position.set(
        definition.id === "stair_a" ? 1.2 + index * 1.1 : 0.8 + index * 0.95,
        definition.id === "stair_a" ? 2.0 + index * 0.34 : 3.0 + index * 0.92,
        -4.9 + index * 0.2
      );
      ring.rotation.z = index * 0.22;
      ring.renderOrder = 12;
      levelScene.effectRoot.add(ring);
      levelScene.energyRings.push(ring);
    }

    const dustCount = definition.id === "stair_a" ? 96 : 144;
    const dustPositions = new Float32Array(dustCount * 3);
    for (let index = 0; index < dustCount; index += 1) {
      dustPositions[index * 3] = -9.2 + (((index * 47) % 193) / 192) * 18.4;
      dustPositions[index * 3 + 1] = 0.4 + (((index * 67 + 13) % 181) / 180) * maxY;
      dustPositions[index * 3 + 2] = -4.8 + (((index * 83 + 29) % 173) / 172) * 9.6;
    }
    const dustGeometry = new THREE.BufferGeometry();
    dustGeometry.setAttribute("position", new THREE.BufferAttribute(dustPositions, 3));
    const dust = new THREE.Points(dustGeometry, dustMaterial);
    dust.name = `${definition.id}-spatial-dust`;
    dust.renderOrder = 11;
    levelScene.effectRoot.add(dust);
    levelScene.dustField = dust;
  }

  function buildLevelScene(definition: StairLevelDefinition): LevelScene {
    levelDef = definition;
    const group = new THREE.Group();
    group.name = `level-${definition.id}`;
    const effectRoot = new THREE.Group();
    effectRoot.name = `${definition.id}-presentation-effects`;
    levelScene = {
      definition,
      group,
      mechanismGroups: new Map(),
      mechanismHitMeshes: [],
      walkMeshes: [],
      occluderMeshes: [],
      door: null,
      effectRoot,
      effectMaterials: [],
      floatingFragments: [],
      energyRings: [],
      dustField: null,
      routeEffect: null
    };
    for (const mechanism of definition.mechanisms) {
      const mechanismGroup = new THREE.Group();
      mechanismGroup.name = `mechanism-${mechanism.id}`;
      levelScene.mechanismGroups.set(mechanism.id, mechanismGroup);
      group.add(mechanismGroup);
    }
    buildPlatforms();
    buildStairs();
    for (const decoration of definition.geometry.decorations) {
      buildDecoration(decoration);
    }
    group.add(effectRoot);
    buildSpatialEffects(definition);
    // 场景装饰：数据山墙背后的同色系延展区，消除画框边缘的深色空区（§8.2 亮度档）。
    // 纯渲染用途：不走 registerMesh，不参与导航、点击与 §5.3 规则 5 遮挡判定。
    const backdropExtension = new THREE.Mesh(
      createStairBoxGeometry(48, definition.id === "stair_a" ? 24 : 26, 0.3),
      createStairMaterial("wall_lit")
    );
    backdropExtension.name = `${definition.id}-backdrop-extension`;
    backdropExtension.position.set(
      definition.id === "stair_a" ? 2.0 : 1.0,
      definition.id === "stair_a" ? 2.0 : 3.5,
      definition.id === "stair_a" ? -6.05 : -6.3
    );
    group.add(backdropExtension);
    scene.add(group);
    return levelScene;
  }

  function disposeLevelScene(): void {
    if (!levelScene) return;
    scene.remove(levelScene.group);
    levelScene.group.traverse((object) => {
      if (
        object instanceof THREE.Mesh
        || object instanceof THREE.LineSegments
        || object instanceof THREE.Line
        || object instanceof THREE.Points
      ) {
        object.geometry.dispose();
        // 材质来自 createStairMaterial 共享缓存，不逐个 dispose。
      }
    });
    levelScene.effectMaterials.forEach((material) => material.dispose());
  }

  /* ---------------------------- 坐标换算 ---------------------------- */

  function worldToScreen(position: THREE.Vector3): ScreenPoint {
    const ndc = scratchC.copy(position).project(camera);
    return {
      x: (ndc.x * 0.5 + 0.5) * INTERNAL_WIDTH,
      y: (1 - (ndc.y * 0.5 + 0.5)) * INTERNAL_HEIGHT
    };
  }

  const projectNode = (nodeId: string): ScreenPoint => {
    const node = navGraph.nodes.get(nodeId);
    if (!node) return { x: 0, y: 0 };
    return worldToScreen(node.position);
  };

  function applyCameraView(view: CameraViewId): void {
    const spec = LEVEL_CAMERAS[state.levelId];
    camera.left = -spec.halfWidth;
    camera.right = spec.halfWidth;
    camera.top = spec.halfHeight;
    camera.bottom = -spec.halfHeight;
    camera.near = spec.near;
    camera.far = spec.far;
    camera.updateProjectionMatrix();
    camera.up.set(0, 1, 0);
    camera.position.set(spec.views[view].position[0], spec.views[view].position[1], spec.views[view].position[2]);
    camera.lookAt(spec.center[0], spec.center[1], spec.center[2]);
    camera.updateMatrixWorld(true);
  }

  /** §5.3 规则 5：相机到端点的射线先命中实心遮挡面（backdrop 墙等非走面实体）则丢弃。 */
  const occlude: OcclusionTest = (from, to) => {
    scratchA.copy(to).sub(from);
    const distance = scratchA.length();
    if (distance < 1e-6) return false;
    scratchA.divideScalar(distance);
    occlusionRay.set(from, scratchA);
    occlusionRay.near = 0;
    occlusionRay.far = Math.max(0, distance - 0.3);
    const hits = occlusionRay.intersectObjects(levelScene.occluderMeshes, true);
    return hits.some((hit) => hit.object instanceof THREE.Mesh);
  };

  /* ---------------------------- 投影接缝 ---------------------------- */

  /** 缝合线半长（内部像素）：接缝两端屏幕上重合，世界端点连线会缩成一点，
   *  因此沿切线屏幕方向在中点两侧展开一条 16px 的实线 / 虚线接缝（§5.3、§8.5）。 */
  const SEAM_STITCH_HALF_PX = 11;

  /** 内部屏幕坐标 + 相机深度 → 世界坐标（正交投影逆变换）。 */
  function unprojectScreenPoint(px: number, py: number, depth: number): THREE.Vector3 {
    const spec = LEVEL_CAMERAS[state.levelId];
    const forward = camera.getWorldDirection(scratchA);
    const right = scratchB.set(1, 0, 0).applyQuaternion(camera.quaternion);
    const up = scratchC.set(0, 1, 0).applyQuaternion(camera.quaternion);
    const world = camera.position.clone().addScaledVector(forward, depth);
    world.addScaledVector(right, (px - INTERNAL_WIDTH / 2) / (INTERNAL_WIDTH / (2 * spec.halfWidth)));
    world.addScaledVector(up, -(py - INTERNAL_HEIGHT / 2) / (INTERNAL_HEIGHT / (2 * spec.halfHeight)));
    return world;
  }

  /** 计算缝合线世界端点：屏幕中点沿切线屏幕方向 ±SEAM_STITCH_HALF_PX，深度取两端点中点。 */
  function computeStitch(worldA: ConnectorWorldState, worldB: ConnectorWorldState): [THREE.Vector3, THREE.Vector3] {
    const screenA = worldToScreen(worldA.worldPosition);
    const screenB = worldToScreen(worldB.worldPosition);
    const mid = { x: (screenA.x + screenB.x) / 2, y: (screenA.y + screenB.y) / 2 };
    let dirX = 1;
    let dirY = 0;
    const tangentTip = worldToScreen(scratchA.copy(worldA.worldPosition).add(worldA.worldTangent));
    const tanDx = tangentTip.x - screenA.x;
    const tanDy = tangentTip.y - screenA.y;
    const tanLength = Math.hypot(tanDx, tanDy);
    if (tanLength > 1e-3) {
      dirX = tanDx / tanLength;
      dirY = tanDy / tanLength;
    }
    const forward = camera.getWorldDirection(scratchB);
    const midWorld = scratchC.copy(worldA.worldPosition).add(worldB.worldPosition).multiplyScalar(0.5);
    const depth = midWorld.sub(camera.position).dot(forward);
    const start = unprojectScreenPoint(mid.x - dirX * SEAM_STITCH_HALF_PX, mid.y - dirY * SEAM_STITCH_HALF_PX, depth);
    const end = unprojectScreenPoint(mid.x + dirX * SEAM_STITCH_HALF_PX, mid.y + dirY * SEAM_STITCH_HALF_PX, depth);
    return [start, end];
  }

  function makeSeamMarker(color: string): THREE.Sprite {
    const material = new THREE.SpriteMaterial({
      color,
      depthTest: false,
      transparent: true,
      fog: false,
      toneMapped: false
    });
    const sprite = new THREE.Sprite(material);
    sprite.scale.set(0.22, 0.22, 1);
    sprite.renderOrder = 91;
    return sprite;
  }

  function createSeamVisual(seam: PerspectiveSeam, worldA: ConnectorWorldState, worldB: ConnectorWorldState, now: number): SeamVisual {
    const color = seam.valid ? STAIR_PALETTE.seamValid : STAIR_PALETTE.seamInvalid;
    const [stitchStart, stitchEnd] = computeStitch(worldA, worldB);
    const stitchLength = stitchStart.distanceTo(stitchEnd);
    const lineMaterial = seam.valid
      ? new THREE.LineBasicMaterial({ color, depthTest: false, transparent: true, fog: false, toneMapped: false })
      : new THREE.LineDashedMaterial({
          color,
          depthTest: false,
          transparent: true,
          dashSize: stitchLength / 3.2,
          gapSize: stitchLength / 5.4,
          fog: false,
          toneMapped: false
        });
    const geometry = new THREE.BufferGeometry().setFromPoints([stitchStart, stitchEnd]);
    const line = new THREE.Line(geometry, lineMaterial);
    line.renderOrder = 90;
    line.computeLineDistances();
    const markerA = makeSeamMarker(color);
    const markerB = makeSeamMarker(color);
    markerA.position.copy(worldA.worldPosition);
    markerB.position.copy(worldB.worldPosition);
    scene.add(line, markerA, markerB);
    return {
      linkId: seam.linkId,
      valid: seam.valid,
      line,
      lineMaterial,
      markerA,
      markerB,
      pointA: worldA.worldPosition.clone(),
      pointB: worldB.worldPosition.clone(),
      stitchStart,
      stitchEnd,
      state: seam.valid ? "appear" : "invalid",
      startedAt: now,
      firstInvalid: !seam.valid && !invalidHoldDone.has(seam.linkId)
    };
  }

  function removeSeamVisual(visual: SeamVisual): void {
    scene.remove(visual.line, visual.markerA, visual.markerB);
    visual.line.geometry.dispose();
    visual.lineMaterial.dispose();
    (visual.markerA.material as THREE.SpriteMaterial).dispose();
    (visual.markerB.material as THREE.SpriteMaterial).dispose();
  }

  /** 重算后同步接缝表现：新接缝播出现动画，消失的接缝立即移除，持续的接缝更新端点。 */
  function updateSeamVisuals(seams: readonly PerspectiveSeam[], now: number): void {
    const seen = new Set<string>();
    for (const seam of seams) {
      seen.add(seam.linkId);
      const worldA = connectorWorld.get(seam.connectorA);
      const worldB = connectorWorld.get(seam.connectorB);
      if (!worldA || !worldB) continue;
      const existing = seamVisuals.get(seam.linkId);
      if (existing && existing.valid === seam.valid) {
        existing.pointA.copy(worldA.worldPosition);
        existing.pointB.copy(worldB.worldPosition);
        const [stitchStart, stitchEnd] = computeStitch(worldA, worldB);
        existing.stitchStart.copy(stitchStart);
        existing.stitchEnd.copy(stitchEnd);
        if (existing.state === "stable") {
          setSeamLine(existing, 1);
        }
        existing.markerA.position.copy(worldA.worldPosition);
        existing.markerB.position.copy(worldB.worldPosition);
        continue;
      }
      if (existing) {
        removeSeamVisual(existing);
      }
      seamVisuals.set(seam.linkId, createSeamVisual(seam, worldA, worldB, now));
      if (!seam.valid) {
        invalidHoldDone.add(seam.linkId);
      }
    }
    for (const [linkId, visual] of seamVisuals) {
      if (!seen.has(linkId)) {
        removeSeamVisual(visual);
        seamVisuals.delete(linkId);
      }
    }
  }

  /** 有效接缝四帧：端点点亮 → 短线延伸 → 接缝闭合 → 稳定实线（§8.5）。 */
  function setSeamLine(visual: SeamVisual, k: number): void {
    const position = visual.line.geometry.getAttribute("position") as THREE.BufferAttribute;
    position.setXYZ(0, visual.stitchStart.x, visual.stitchStart.y, visual.stitchStart.z);
    const tip = scratchB.copy(visual.stitchStart).lerp(visual.stitchEnd, k);
    position.setXYZ(1, tip.x, tip.y, tip.z);
    position.needsUpdate = true;
    visual.line.computeLineDistances();
  }

  function updateSeamAnimations(now: number): void {
    for (const visual of seamVisuals.values()) {
      const elapsed = now - visual.startedAt;
      if (visual.valid) {
        if (visual.state === "appear") {
          const t = Math.min(1, elapsed / SEAM_VALID_ANIM_MS);
          if (t < 0.25) {
            visual.line.visible = false;
          } else if (t < 0.5) {
            visual.line.visible = true;
            setSeamLine(visual, 0.35);
          } else {
            visual.line.visible = true;
            setSeamLine(visual, 1);
          }
          visual.markerA.visible = true;
          visual.markerB.visible = true;
          if (t >= 1) {
            visual.state = "stable";
            visual.line.visible = true;
            setSeamLine(visual, 1);
          }
        }
      } else {
        // 错误接缝三帧：橙点出现 → 虚线闪一次 → 保持弱亮；首次保留 1200ms 全亮（§7.5）。
        const holdMs = visual.firstInvalid ? INVALID_SEAM_HOLD_MS : SEAM_INVALID_FLASH_MS;
        const dimmed = elapsed >= holdMs;
        const flashing = elapsed < SEAM_INVALID_FLASH_MS;
        visual.line.visible = flashing ? Math.floor(elapsed / 110) % 2 === 1 : true;
        setSeamLine(visual, 1);
        visual.lineMaterial.opacity = dimmed ? 0.45 : 1;
        (visual.markerA.material as THREE.SpriteMaterial).opacity = dimmed ? 0.55 : 1;
        (visual.markerB.material as THREE.SpriteMaterial).opacity = dimmed ? 0.55 : 1;
      }
    }
  }

  /* ---------------------------- 世界重算 ---------------------------- */

  function snapMechanismTransforms(): void {
    for (const mechanism of levelDef.mechanisms) {
      const group = levelScene.mechanismGroups.get(mechanism.id)!;
      const value = mechanismValues[mechanism.id] ?? mechanism.initialState;
      if (mechanism.kind === "rotate") {
        mechanismAngles.set(mechanism.id, value * (Math.PI / 2));
        group.position.set(mechanism.pivot[0], mechanism.pivot[1], mechanism.pivot[2]);
        group.rotation.set(0, value * (Math.PI / 2), 0);
      } else {
        group.position.set(0, 0, 0);
        group.position.setComponent(
          mechanism.axis === "x" ? 0 : mechanism.axis === "y" ? 1 : 2,
          mechanism.stepSize * value
        );
        group.rotation.set(0, 0, 0);
      }
    }
  }

  /** 机关停止 / 相机稳定 / 关卡加载后的完整重算：先更新世界矩阵，再算投影与导航图（§5.3、§5.5）。 */
  function recomputeWorld(): void {
    scene.updateMatrixWorld(true);
    camera.updateMatrixWorld(true);
    const runtime = buildMechanismRuntime(levelDef, mechanismValues);
    connectorWorld = resolveConnectorWorld(levelDef, runtime);
    const evaluation = evaluatePerspectiveSeams(levelDef, camera, state.cameraView, connectorWorld, occlude);
    currentSeams = evaluation.seams;
    navGraph = buildNavGraph(levelDef, mechanismValues, evaluation.seams);
    graphRevision += 1;
    updateSeamVisuals(evaluation.seams, performance.now());
    syncPlayerPerspectiveVisibility();
    if (evaluation.droppedCandidates.length > 0) {
      console.debug(
        "[stair-demo] 同组更近候选挤掉的投影边：",
        evaluation.droppedCandidates.map((seam) => `${seam.linkId}@${seam.screenDistancePx.toFixed(2)}px`)
      );
    }
    // §11：重算后玩家节点失效时放回最近安全节点。
    if (!navGraph.nodes.has(state.playerNodeId)) {
      console.warn(`[stair-demo] 玩家节点 ${state.playerNodeId} 失效，放回最近安全节点。`);
      let best: string | null = null;
      let bestDistance = Infinity;
      const foot = player.object3d.position;
      for (const node of navGraph.nodes.values()) {
        if (!node.safe) continue;
        const distance = node.position.distanceTo(foot);
        if (distance < bestDistance) {
          bestDistance = distance;
          best = node.id;
        }
      }
      if (best) {
        state.playerNodeId = best;
        player.object3d.position.copy(navGraph.nodes.get(best)!.position);
      }
    }
    if (!firstSeamToastShown && evaluation.seams.some((seam) => seam.valid)) {
      firstSeamToastShown = true;
      showToast(levelDef.feedback.firstSeam, "ok");
    }
  }

  /* ---------------------------- 空间演出层 ---------------------------- */

  const PRESENTATION_COPY: Record<PresentationStage, { index: string; title: string; detail: string }> = {
    entry: {
      index: "03F / 楼梯井",
      title: "空间偏移",
      detail: "墙面、平台与梯段分处不同空间层。"
    },
    level_break: {
      index: "第一段 / 已稳定",
      title: "上层继续偏移",
      detail: "消防门后的结构仍未回到同一位置。"
    },
    level_reveal: {
      index: "第二段 / 错层井",
      title: "垂直结构展开",
      detail: "更高的落差需要连续观察。"
    },
    finale: {
      index: "两段 / 已连通",
      title: "下降路径固定",
      detail: "消防门后的落点已稳定在 A2。"
    }
  };

  function createRouteEffect(): void {
    if (levelScene.routeEffect) return;
    // 使用关卡节点的作者顺序回放玩家刚刚经过的完整路径。最终机关姿态可能已让
    // 早先接缝失效，因此这里不再要求当前导航图仍保留一条起点到终点的同时连通路径。
    const route = levelDef.nodes.map((node) => node.id);
    if (route.length < 2) return;
    const densePoints: THREE.Vector3[] = [];
    for (let index = 0; index < route.length - 1; index += 1) {
      const from = navGraph.nodes.get(route[index])?.position;
      const to = navGraph.nodes.get(route[index + 1])?.position;
      if (!from || !to) continue;
      const divisions = Math.max(3, Math.ceil(from.distanceTo(to) * 4));
      for (let step = 0; step < divisions; step += 1) {
        if (index > 0 && step === 0) continue;
        densePoints.push(from.clone().lerp(to, step / divisions).add(new THREE.Vector3(0, 0.09, 0)));
      }
    }
    const exit = navGraph.nodes.get(route[route.length - 1])?.position;
    if (exit) densePoints.push(exit.clone().add(new THREE.Vector3(0, 0.09, 0)));
    if (densePoints.length < 2) return;

    const lineMaterial = new THREE.LineBasicMaterial({
      color: STAIR_PALETTE.seamValid,
      transparent: true,
      opacity: 0.92,
      depthTest: false,
      depthWrite: false,
      fog: false,
      toneMapped: false,
      blending: THREE.AdditiveBlending
    });
    const sparkMaterial = new THREE.PointsMaterial({
      color: STAIR_PALETTE.wallLit,
      size: 0.16,
      sizeAttenuation: true,
      transparent: true,
      opacity: 0.95,
      depthTest: false,
      depthWrite: false,
      fog: false,
      toneMapped: false,
      blending: THREE.AdditiveBlending
    });
    levelScene.effectMaterials.push(lineMaterial, sparkMaterial);
    const lineGeometry = new THREE.BufferGeometry().setFromPoints(densePoints);
    const sparkGeometry = new THREE.BufferGeometry().setFromPoints(densePoints);
    lineGeometry.setDrawRange(0, 0);
    sparkGeometry.setDrawRange(0, 0);
    const line = new THREE.Line(lineGeometry, lineMaterial);
    const sparks = new THREE.Points(sparkGeometry, sparkMaterial);
    line.renderOrder = 95;
    sparks.renderOrder = 96;
    const group = new THREE.Group();
    group.name = `${levelDef.id}-completion-route`;
    group.add(line, sparks);
    levelScene.effectRoot.add(group);
    levelScene.routeEffect = {
      group,
      line,
      sparks,
      pointCount: densePoints.length,
      startedAt: performance.now()
    };
  }

  function updateRouteEffect(now: number): void {
    const effect = levelScene.routeEffect;
    if (!effect) return;
    const elapsed = now - effect.startedAt;
    const reveal = reducedMotion ? 1 : Math.min(1, elapsed / 1650);
    const visibleCount = Math.max(2, Math.ceil(effect.pointCount * reveal));
    effect.line.geometry.setDrawRange(0, visibleCount);
    effect.sparks.geometry.setDrawRange(Math.max(0, visibleCount - 9), Math.min(9, visibleCount));
    const pulse = reducedMotion ? 1 : 0.72 + Math.floor((elapsed % 420) / 105) * 0.08;
    (effect.line.material as THREE.LineBasicMaterial).opacity = Math.min(1, pulse);
    (effect.sparks.material as THREE.PointsMaterial).size = 0.12 + (Math.floor(elapsed / 90) % 3) * 0.035;
  }

  function updateSpatialEffects(now: number): void {
    if (!levelScene) return;
    const tick = Math.floor(now / SPATIAL_FX_TICK_MS) * SPATIAL_FX_TICK_MS;
    const seconds = tick / 1000;
    const stage = presentation?.stage ?? null;
    const rawProgress = presentation
      ? Math.min(1, Math.max(0, (now - presentation.startedAt) / presentation.duration))
      : 0;
    const breakProgress = stage === "level_break" ? rawProgress * rawProgress : 0;
    const finalePulse = stage === "finale" ? Math.sin(rawProgress * Math.PI) : 0;
    for (const fragment of levelScene.floatingFragments) {
      const bob = Math.sin(seconds * 1.35 + fragment.phase) * (0.07 + finalePulse * 0.2);
      fragment.object.position.copy(fragment.basePosition)
        .addScaledVector(fragment.driftDirection, breakProgress * 4.6);
      fragment.object.position.y += bob + breakProgress * 0.8;
      fragment.object.rotation.x = fragment.phase * 0.17 + seconds * fragment.spinX;
      fragment.object.rotation.y = fragment.phase * 0.23 + seconds * fragment.spinY;
      const scale = 1 + breakProgress * 0.9 + finalePulse * 0.35;
      fragment.object.scale.setScalar(scale);
    }
    levelScene.energyRings.forEach((ring, index) => {
      ring.rotation.z = index * 0.22 + seconds * (index % 2 === 0 ? 0.08 : -0.07);
      const scale = 1 + Math.sin(seconds * 0.9 + index) * 0.025 + finalePulse * 0.13;
      ring.scale.setScalar(scale);
    });
    if (levelScene.dustField) {
      levelScene.dustField.rotation.y = seconds * 0.018;
      levelScene.dustField.position.y = Math.sin(seconds * 0.42) * 0.08;
    }
    updateRouteEffect(now);
  }

  function beginPresentation(
    stage: PresentationStage,
    duration: number,
    onFinished: (() => void) | null = null
  ): void {
    const copy = PRESENTATION_COPY[stage];
    presentation = {
      stage,
      startedAt: performance.now(),
      duration: reducedMotion ? 1 : duration,
      onFinished
    };
    state.phase = stage === "level_break"
      ? "level_interlude"
      : stage === "finale"
        ? "finale"
        : "entry_sequence";
    stageEl.dataset.presentation = stage;
    sequenceIndexEl.textContent = copy.index;
    sequenceTitleEl.textContent = copy.title;
    sequenceDetailEl.textContent = copy.detail;
    sequenceTrackFillEl.style.transform = "scaleX(0)";
    sequenceEl.hidden = false;
    if (stage === "level_break") {
      let index = 0;
      for (const group of levelScene.mechanismGroups.values()) {
        group.userData.presentationBasePosition = group.position.clone();
        group.userData.presentationBaseRotationY = group.rotation.y;
        group.userData.presentationBreakDirection = new THREE.Vector3(index % 2 === 0 ? -1 : 1, 0.35 + index * 0.12, index % 3 === 0 ? 0.6 : -0.45).normalize();
        index += 1;
      }
    }
    updateMechUI();
    updateViewButtons();
  }

  function updatePresentation(now: number): void {
    if (!presentation) return;
    const active = presentation;
    const t = Math.min(1, Math.max(0, (now - active.startedAt) / active.duration));
    const stepped = reducedMotion ? 1 : Math.floor(t * 12) / 12;
    sequenceTrackFillEl.style.transform = `scaleX(${stepped})`;
    stageEl.style.setProperty("--stair-sequence-progress", String(stepped));

    applyCameraView(state.cameraView);
    if (active.stage === "entry") {
      camera.zoom = 0.82 + stepped * 0.18;
      player.object3d.visible = t >= 0.38;
    } else if (active.stage === "level_reveal") {
      camera.zoom = 0.76 + stepped * 0.24;
      player.object3d.visible = t >= 0.28;
    } else if (active.stage === "level_break") {
      camera.zoom = 1 + Math.sin(t * Math.PI) * 0.08;
      player.object3d.visible = false;
      let index = 0;
      for (const group of levelScene.mechanismGroups.values()) {
        const basePosition = group.userData.presentationBasePosition as THREE.Vector3 | undefined;
        const baseRotationY = Number(group.userData.presentationBaseRotationY ?? group.rotation.y);
        const direction = group.userData.presentationBreakDirection as THREE.Vector3 | undefined;
        if (basePosition && direction) {
          group.position.copy(basePosition).addScaledVector(direction, stepped * (0.8 + index * 0.18));
          group.rotation.y = baseRotationY + (index % 2 === 0 ? -1 : 1) * stepped * 0.18;
        }
        index += 1;
      }
    } else {
      camera.zoom = 1 + Math.sin(t * Math.PI) * 0.055;
      player.object3d.visible = false;
    }
    camera.updateProjectionMatrix();

    if (t < 1) return;
    const finishedStage = active.stage;
    const onFinished = active.onFinished;
    presentation = null;
    delete stageEl.dataset.presentation;
    stageEl.style.removeProperty("--stair-sequence-progress");
    sequenceEl.hidden = true;
    player.object3d.visible = true;
    camera.zoom = 1;
    applyCameraView(state.cameraView);
    state.phase = "playing";
    updateMechUI();
    updateViewButtons();
    if (finishedStage !== "level_break") {
      recomputeWorld();
    }
    onFinished?.();
  }

  /* ---------------------------- 输入锁 ---------------------------- */

  function computeInputLocked(): boolean {
    return state.phase !== "playing" || mechanismAnimation !== null || curtain !== null;
  }

  function canSwitchViewNow(): boolean {
    return !computeInputLocked() && state.lockedPerspectiveEdgeId === null;
  }

  function noteInput(): void {
    lastInputAt = performance.now();
  }

  function denyFeedback(element?: HTMLElement): void {
    const target = element ?? statusEl;
    target.classList.remove("is-denied");
    void target.offsetWidth;
    target.classList.add("is-denied");
  }

  /* ---------------------------- 相机切换（§5.1） ---------------------------- */

  function requestViewSwitch(view: CameraViewId, options?: { instant?: boolean }): void {
    if (view === state.cameraView) {
      denyFeedback(viewButtons.get(view));
      return;
    }
    const button = viewButtons.get(view);
    if (!canSwitchViewNow()) {
      denyFeedback(button);
      return;
    }
    noteInput();
    if (options?.instant) {
      state.cameraView = view;
      applyCameraView(view);
      recomputeWorld();
      updateViewButtons();
      return;
    }
    state.phase = "camera_transition";
    const spec = LEVEL_CAMERAS[state.levelId];
    cameraTransition = {
      to: view,
      fromPos: camera.position.clone(),
      toPos: new THREE.Vector3(spec.views[view].position[0], spec.views[view].position[1], spec.views[view].position[2]),
      startedAt: performance.now(),
      // 减弱动态模式降为 1ms，仍执行同一重算流程。
      duration: reducedMotion ? 1 : CAMERA_TRANSITION_MS
    };
    updateViewButtons();
    updateMechUI();
  }

  function updateCameraTransition(now: number): void {
    if (!cameraTransition) return;
    const t = Math.min(1, (now - cameraTransition.startedAt) / cameraTransition.duration);
    // 四个离散姿态帧，保持像素硬切换感。
    const pose = t >= 1 ? 1 : Math.floor(t * 4) / 4;
    camera.position.copy(cameraTransition.fromPos).lerp(cameraTransition.toPos, pose);
    const spec = LEVEL_CAMERAS[state.levelId];
    camera.lookAt(spec.center[0], spec.center[1], spec.center[2]);
    camera.updateMatrixWorld(true);
    if (t >= 1) {
      state.cameraView = cameraTransition.to;
      cameraTransition = null;
      state.phase = "playing";
      // 相机切换完成后执行一次完整投影重算（§5.3）。
      recomputeWorld();
      updateViewButtons();
      updateMechUI();
    }
  }

  function updateViewButtons(): void {
    const canSwitch = canSwitchViewNow();
    for (const [view, button] of viewButtons) {
      const current = view === state.cameraView;
      button.setAttribute("aria-pressed", String(current));
      button.classList.toggle("is-current", current);
      button.disabled = !current && !canSwitch;
    }
  }

  /* ---------------------------- 机关（§5.5） ---------------------------- */

  function selectMechanism(id: string | null): void {
    state.selectedMechanismId = id;
    updateMechUI();
  }

  function mechanismControlLabels(mechanism: MechanismDefinition | null): [string, string] {
    if (!mechanism) return ["Q", "E"];
    if (mechanism.kind === "rotate") return ["Q · 逆", "E · 顺"];
    if (mechanism.kind === "vertical") return ["Q · 降", "E · 升"];
    return ["Q · 移", "E · 移"];
  }

  function updateMechUI(): void {
    const mechanism = state.selectedMechanismId
      ? levelDef.mechanisms.find((entry) => entry.id === state.selectedMechanismId) ?? null
      : null;
    mechLabelEl.textContent = mechanism ? mechanism.label : "未选中机关";
    const [minusLabel, plusLabel] = mechanismControlLabels(mechanism);
    mechMinusButton.textContent = minusLabel;
    mechPlusButton.textContent = plusLabel;
    const disabled = computeInputLocked() || !mechanism;
    mechMinusButton.disabled = disabled;
    mechPlusButton.disabled = disabled;
  }

  function requestMechanismStep(delta: -1 | 1): void {
    if (computeInputLocked() || !state.selectedMechanismId) {
      denyFeedback(delta < 0 ? mechMinusButton : mechPlusButton);
      return;
    }
    const mechanism = mechanismById(state.selectedMechanismId);
    noteInput();
    const next = stepMechanism(levelDef, mechanismValues, mechanism.id, delta);
    const nextValue = next[mechanism.id];
    mechanismValues = next;
    const group = levelScene.mechanismGroups.get(mechanism.id)!;
    const animation: MechanismAnimation = {
      id: mechanism.id,
      kind: mechanism.kind,
      delta,
      startedAt: performance.now(),
      duration: MECHANISM_ANIM_MS,
      fromAngle: 0,
      toAngle: 0,
      fromOffset: new THREE.Vector3(),
      toOffset: new THREE.Vector3()
    };
    if (mechanism.kind === "rotate") {
      const currentAngle = mechanismAngles.get(mechanism.id) ?? mechanism.initialState * (Math.PI / 2);
      animation.fromAngle = currentAngle;
      animation.toAngle = currentAngle + delta * (Math.PI / 2);
      mechanismAngles.set(mechanism.id, animation.toAngle);
    } else {
      animation.fromOffset.copy(group.position);
      animation.toOffset.set(0, 0, 0);
      animation.toOffset.setComponent(
        mechanism.axis === "x" ? 0 : mechanism.axis === "y" ? 1 : 2,
        mechanism.stepSize * nextValue
      );
    }
    mechanismAnimation = animation;
    updateMechUI();
    updateViewButtons();
  }

  /** 机关携带人物：站在该机关节点上时按引擎矩阵的插值姿态跟随（§5.5）。 */
  function carriedFootPosition(mechanism: MechanismDefinition, pose: number): THREE.Vector3 | null {
    const nodeDef = levelDef.nodes.find((node) => node.id === state.playerNodeId);
    if (!nodeDef || nodeDef.ownerId !== mechanism.id || !mechanismAnimation) {
      return null;
    }
    const base = new THREE.Vector3(nodeDef.position[0], nodeDef.position[1], nodeDef.position[2]);
    if (mechanism.kind === "rotate") {
      const angle = THREE.MathUtils.lerp(mechanismAnimation.fromAngle, mechanismAnimation.toAngle, pose);
      const pivot = new THREE.Vector3(mechanism.pivot[0], mechanism.pivot[1], mechanism.pivot[2]);
      return base.sub(pivot).applyAxisAngle(new THREE.Vector3(0, 1, 0), angle).add(pivot);
    }
    const offset = scratchA.copy(mechanismAnimation.fromOffset).lerp(mechanismAnimation.toOffset, pose);
    return base.add(offset);
  }

  function updateMechanismAnimation(now: number): void {
    if (!mechanismAnimation) return;
    const mechanism = mechanismById(mechanismAnimation.id);
    const group = levelScene.mechanismGroups.get(mechanism.id)!;
    const t = Math.min(1, (now - mechanismAnimation.startedAt) / mechanismAnimation.duration);
    if (mechanism.kind === "rotate") {
      // 90° 分四个离散姿态帧（§8.5）。
      const pose = t >= 1 ? 1 : Math.floor(t * ROTATE_POSE_COUNT) / ROTATE_POSE_COUNT;
      group.rotation.y = THREE.MathUtils.lerp(mechanismAnimation.fromAngle, mechanismAnimation.toAngle, pose);
    } else {
      // 每 60ms 一次内部像素整数位移（§8.5）。
      const tickT =
        t >= 1 ? 1 : Math.min(1, (Math.floor((now - mechanismAnimation.startedAt) / MECHANISM_LINEAR_TICK_MS) * MECHANISM_LINEAR_TICK_MS) / mechanismAnimation.duration);
      const offset = scratchA.copy(mechanismAnimation.fromOffset).lerp(mechanismAnimation.toOffset, tickT);
      offset.x = Math.round(offset.x * PX_PER_WORLD) / PX_PER_WORLD;
      offset.y = Math.round(offset.y * PX_PER_WORLD) / PX_PER_WORLD;
      offset.z = Math.round(offset.z * PX_PER_WORLD) / PX_PER_WORLD;
      group.position.copy(offset);
    }
    const carried = carriedFootPosition(mechanism, t);
    if (carried) {
      player.object3d.position.copy(carried);
    }
    if (t >= 1) {
      mechanismAnimation = null;
      snapMechanismTransforms();
      // 机关停止后先更新世界矩阵，再重算投影与导航图（§5.5）。
      recomputeWorld();
      const node = navGraph.nodes.get(state.playerNodeId);
      if (node) {
        player.object3d.position.copy(node.position);
      }
      updateMechUI();
      updateViewButtons();
    }
  }

  /* ---------------------------- 点击移动（§5.4） ---------------------------- */

  function nearestNodeToPoint(point: THREE.Vector3): string | null {
    let best: string | null = null;
    let bestDistance = Infinity;
    for (const node of navGraph.nodes.values()) {
      const distance = node.position.distanceTo(point);
      if (distance < bestDistance) {
        bestDistance = distance;
        best = node.id;
      }
    }
    return best;
  }

  function directionToNode(nodeId: string): ScreenPoint {
    const from = projectNode(state.playerNodeId);
    const to = projectNode(nodeId);
    return { x: to.x - from.x, y: to.y - from.y };
  }

  /**
   * 有效接缝的屏幕重合区点击解析：命中 9px 内时目标为离玩家更远的端点；
   * 玩家已在某一端时则跨越到另一端。方向失败的错误重合不适用（§7.4 仍走断路停边）。
   */
  function resolveSeamCrossClick(click: ScreenPoint): string | null {
    for (const seam of currentSeams) {
      if (!seam.valid) continue;
      const pointA = projectNode(seam.nodeA);
      const pointB = projectNode(seam.nodeB);
      const mid = { x: (pointA.x + pointB.x) / 2, y: (pointA.y + pointB.y) / 2 };
      if (Math.hypot(click.x - mid.x, click.y - mid.y) > 9) continue;
      if (seam.nodeA === state.playerNodeId) return seam.nodeB;
      if (seam.nodeB === state.playerNodeId) return seam.nodeA;
      const pathA = findPath(navGraph, state.playerNodeId, seam.nodeA);
      const pathB = findPath(navGraph, state.playerNodeId, seam.nodeB);
      if (pathA && pathB) return pathA.length > pathB.length ? seam.nodeA : seam.nodeB;
      if (pathA) return seam.nodeA;
      if (pathB) return seam.nodeB;
    }
    return null;
  }

  function edgeBetween(a: string, b: string): { id: string; kind: NavEdgeKind } | null {
    for (const edge of navGraph.edges) {
      if ((edge.a === a && edge.b === b) || (edge.a === b && edge.b === a)) {
        return { id: edge.id, kind: edge.kind };
      }
    }
    return null;
  }

  /** 断路反馈只显示一次（§5.4）；方向错误时换成方向文案（§7.4）。 */
  function showBlockedFeedback(targetNodeId: string, wrongDirection: boolean): void {
    const signature = `${state.playerNodeId}>${targetNodeId}|${wrongDirection ? "w" : "b"}|r${graphRevision}`;
    if (signature === lastBlockedSignature) {
      return;
    }
    lastBlockedSignature = signature;
    showToast(wrongDirection ? levelDef.feedback.wrongDirection : levelDef.feedback.blocked, "warn");
  }

  function startWalkToNode(targetNodeId: string, screenDirHint?: ScreenPoint): void {
    if (computeInputLocked()) {
      denyFeedback();
      return;
    }
    if (!navGraph.nodes.has(targetNodeId)) {
      return;
    }
    noteInput();
    let path = findPath(navGraph, state.playerNodeId, targetNodeId);
    let blocked = false;
    let wrongDirection = false;
    if (!path) {
      blocked = true;
      wrongDirection = currentSeams.some(
        (seam) => !seam.valid && (seam.nodeA === targetNodeId || seam.nodeB === targetNodeId)
      );
      const direction = screenDirHint ?? directionToNode(targetNodeId);
      const boundary = nearestBoundaryNode(navGraph, state.playerNodeId, direction, projectNode);
      if (boundary === state.playerNodeId) {
        showBlockedFeedback(targetNodeId, wrongDirection);
        return;
      }
      path = findPath(navGraph, state.playerNodeId, boundary);
      if (!path || path.length < 2) {
        showBlockedFeedback(targetNodeId, wrongDirection);
        return;
      }
    }
    if (path.length < 2) {
      return;
    }
    const edgeKinds: (NavEdgeKind | null)[] = [];
    const edgeIds: (string | null)[] = [];
    for (let index = 0; index < path.length - 1; index += 1) {
      const edge = edgeBetween(path[index], path[index + 1]);
      edgeKinds.push(edge?.kind ?? null);
      edgeIds.push(edge?.id ?? null);
    }
    walk = {
      path,
      edgeKinds,
      edgeIds,
      index: 0,
      elapsed: 0,
      duration: 0,
      fromPos: new THREE.Vector3(),
      toPos: new THREE.Vector3(),
      targetNodeId,
      blocked,
      wrongDirection,
      lastScreen: null
    };
    state.phase = "walking";
    state.targetNodeId = targetNodeId;
    beginWalkSegment();
    player.setWalking(true);
    updateMechUI();
    updateViewButtons();
  }

  function beginWalkSegment(): void {
    if (!walk) return;
    const from = navGraph.nodes.get(walk.path[walk.index]);
    const to = navGraph.nodes.get(walk.path[walk.index + 1]);
    if (!from || !to) {
      finishWalk();
      return;
    }
    walk.fromPos.copy(from.position);
    walk.toPos.copy(to.position);
    walk.elapsed = 0;
    const kind = walk.edgeKinds[walk.index];
    const edgeId = walk.edgeIds[walk.index];
    if (kind === "perspective" && edgeId) {
      // 投影边通行期间锁定相机 / 机关 / 重置（§5.4）。
      state.lockedPerspectiveEdgeId = edgeId;
      walk.duration = Math.max(PERSPECTIVE_MIN_WALK_MS, (walk.fromPos.distanceTo(walk.toPos) / WALK_SPEED) * 1000);
    } else {
      state.lockedPerspectiveEdgeId = null;
      walk.duration = Math.max(120, (walk.fromPos.distanceTo(walk.toPos) / WALK_SPEED) * 1000);
    }
    const velocity = scratchA.copy(walk.toPos).sub(walk.fromPos);
    player.setDirectionFromVelocity(velocity, camera);
    syncPlayerPerspectiveVisibility();
  }

  function updateWalk(now: number, deltaSeconds: number): void {
    if (!walk) return;
    walk.elapsed += deltaSeconds * 1000;
    const t = Math.min(1, walk.elapsed / walk.duration);
    const kind = walk.edgeKinds[walk.index];
    let position: THREE.Vector3;
    if (kind === "perspective") {
      // §8.4：两个端点空间在世界坐标中共线（接缝两端在屏幕上重合），
      // 45% 进度处即世界线段中点，两侧分属源端点 / 目标端点空间；
      // 脚底沿屏幕接缝连续移动等价于沿该线段插值。
      position = scratchB.copy(walk.fromPos).lerp(walk.toPos, t);
      // 画面跳变 ≤2px 保护：本帧位移超限时保持上一帧位置。
      const screen = worldToScreen(position);
      if (walk.lastScreen) {
        const jump = Math.hypot(screen.x - walk.lastScreen.x, screen.y - walk.lastScreen.y);
        if (jump > PERSPECTIVE_MAX_SCREEN_JUMP_PX) {
          position = scratchB.copy(player.object3d.position);
          screen.x = walk.lastScreen.x;
          screen.y = walk.lastScreen.y;
        }
      }
      walk.lastScreen = screen;
    } else {
      position = scratchB.copy(walk.fromPos).lerp(walk.toPos, t);
    }
    player.object3d.position.copy(position);
    if (t >= 1) {
      walk.index += 1;
      walk.lastScreen = null;
      if (walk.index >= walk.path.length - 1) {
        finishWalk();
      } else {
        beginWalkSegment();
      }
    }
  }

  function finishWalk(): void {
    if (!walk) return;
    const arrivedNodeId = walk.path[walk.path.length - 1];
    const blocked = walk.blocked;
    const wrongDirection = walk.wrongDirection;
    const requestedTarget = walk.targetNodeId;
    walk = null;
    state.playerNodeId = arrivedNodeId;
    state.phase = "playing";
    state.targetNodeId = null;
    state.lockedPerspectiveEdgeId = null;
    player.setWalking(false);
    const node = navGraph.nodes.get(arrivedNodeId);
    if (node) {
      player.object3d.position.copy(node.position);
    }
    syncPlayerPerspectiveVisibility();
    if (blocked) {
      showBlockedFeedback(requestedTarget, wrongDirection);
    }
    updateMechUI();
    updateViewButtons();
    if (arrivedNodeId === levelDef.exitNodeId) {
      startLevelComplete();
    }
  }

  function syncPlayerPerspectiveVisibility(): void {
    // 静止时遵循真实深度遮挡，避免人物覆盖未接通的平台而产生穿墙读法。
    // 只在跨越投影接缝的短动画中提升人物层，保证过渡动作连续可见。
    player.setOcclusionOverride(state.lockedPerspectiveEdgeId !== null);
  }

  /* ---------------------------- 关卡流程（§6.5 / §9） ---------------------------- */

  function startLevelComplete(): void {
    createRouteEffect();
    if (!levelScene.door) {
      advanceAfterDoor();
      return;
    }
    state.phase = "level_complete";
    const doorWorld = levelScene.door.group.position.clone();
    const from = player.object3d.position.clone();
    const direction = doorWorld.clone().sub(from);
    direction.y = 0;
    if (direction.lengthSq() < 1e-6) {
      direction.set(1, 0, 0);
    }
    direction.normalize();
    levelComplete = {
      stage: "door",
      startedAt: performance.now(),
      walkFrom: from,
      walkTo: doorWorld.addScaledVector(direction, 0.55)
    };
    updateMechUI();
    updateViewButtons();
  }

  function updateLevelComplete(now: number): void {
    if (!levelComplete) return;
    if (levelComplete.stage === "door") {
      // 消防门四帧打开，不用透明度淡入（§8.5）。
      const frame = Math.min(
        DOOR_FRAMES,
        Math.floor((now - levelComplete.startedAt) / DOOR_FRAME_MS)
      );
      if (levelScene.door) {
        levelScene.door.panel.position.x =
          levelScene.door.closedX + (levelScene.door.openOffset * frame) / DOOR_FRAMES;
      }
      if (frame >= DOOR_FRAMES) {
        levelComplete = { ...levelComplete, stage: "walk_in", startedAt: now };
        player.setWalking(true);
        const velocity = scratchA.copy(levelComplete.walkTo).sub(levelComplete.walkFrom);
        player.setDirectionFromVelocity(velocity, camera);
      }
      return;
    }
    const t = Math.min(1, (now - levelComplete.startedAt) / DOOR_WALK_IN_MS);
    player.object3d.position.copy(levelComplete.walkFrom).lerp(levelComplete.walkTo, t);
    if (t >= 1) {
      player.setWalking(false);
      advanceAfterDoor();
    }
  }

  function advanceAfterDoor(): void {
    levelComplete = null;
    if (state.levelId === "stair_a") {
      beginPresentation("level_break", LEVEL_BREAK_SEQUENCE_MS, () => {
        // 第一段在画面中解体后，再用同一像素块语言进入升高后的第二段。
        startCurtain(() => {
          loadLevel("stair_b", { resetView: true });
          beginPresentation("level_reveal", LEVEL_REVEAL_SEQUENCE_MS);
        });
      });
    } else {
      beginPresentation("finale", FINALE_SEQUENCE_MS, () => {
        state.phase = "all_complete";
        updateMechUI();
        updateViewButtons();
        if (options.onComplete) {
          options.onComplete();
        } else {
          completeEl.hidden = false;
        }
      });
    }
  }

  function startCurtain(onCovered: (() => void) | null): void {
    curtainEl.hidden = false;
    curtain = { phase: "cover", startedAt: performance.now(), onCovered };
  }

  function updateCurtain(now: number): void {
    if (!curtain) return;
    const elapsed = now - curtain.startedAt;
    const sweep = Math.min(1, elapsed / LEVEL_CURTAIN_MS);
    curtainBlocks.forEach((block) => {
      const col = Number(block.dataset.col);
      const threshold = (col + 1) / CURTAIN_COLS;
      const covered = curtain!.phase === "cover" ? sweep >= threshold : sweep < threshold;
      block.classList.toggle("is-covered", covered);
    });
    if (sweep >= 1) {
      if (curtain.phase === "cover") {
        const onCovered = curtain.onCovered;
        curtain = { phase: "reveal", startedAt: now, onCovered: null };
        onCovered?.();
      } else {
        curtain = null;
        curtainEl.hidden = true;
        curtainBlocks.forEach((block) => block.classList.remove("is-covered"));
        updateMechUI();
        updateViewButtons();
      }
    }
  }

  /* ---------------------------- 关卡装载 ---------------------------- */

  function loadLevel(levelId: LevelId, options: { resetView: boolean }): void {
    for (const visual of seamVisuals.values()) {
      removeSeamVisual(visual);
    }
    seamVisuals.clear();
    disposeLevelScene();

    const definition = getStairLevel(levelId);
    buildLevelScene(definition);
    state.levelId = levelId;
    state.phase = "playing";
    state.playerNodeId = definition.startNodeId;
    state.targetNodeId = null;
    state.selectedMechanismId = null;
    state.lockedPerspectiveEdgeId = null;
    mechanismValues = {};
    for (const mechanism of definition.mechanisms) {
      mechanismValues[mechanism.id] = mechanism.initialState;
    }
    mechanismAngles.clear();
    if (options.resetView) {
      state.cameraView = "south_east";
    }
    cameraTransition = null;
    mechanismAnimation = null;
    walk = null;
    levelComplete = null;
    firstSeamToastShown = false;
    lastBlockedSignature = null;
    invalidHoldDone.clear();
    completeEl.hidden = true;
    sequenceEl.hidden = true;
    delete stageEl.dataset.presentation;
    stageEl.style.removeProperty("--stair-sequence-progress");

    applyCameraView(state.cameraView);
    snapMechanismTransforms();
    recomputeWorld();
    player.setWalking(false);
    player.object3d.position.copy(navGraph.nodes.get(definition.startNodeId)!.position);

    levelNameEl.textContent = definition.title;
    objectiveEl.textContent = definition.feedback.objective;
    levelProgressEl.querySelector("b")!.textContent = levelId === "stair_a" ? "01" : "02";
    statusEl.textContent = "";
    updateMechUI();
    updateViewButtons();
  }

  function resetCurrentLevel(): void {
    // 投影边通行 / 行走 / 转场期间关卡重置同样锁定（§5.4）。
    if (curtain || computeInputLocked() || state.lockedPerspectiveEdgeId !== null) {
      denyFeedback(resetButton);
      return;
    }
    noteInput();
    loadLevel(state.levelId, { resetView: false });
    showToast("本关已重置。", "info");
  }

  function replayAll(): void {
    noteInput();
    completeEl.hidden = true;
    startCurtain(() => {
      loadLevel("stair_a", { resetView: true });
      beginPresentation("entry", ENTRY_SEQUENCE_MS);
    });
  }

  /* ---------------------------- 反馈 ---------------------------- */

  function showToast(text: string, kind: "info" | "ok" | "warn"): void {
    statusEl.textContent = text;
    statusEl.classList.toggle("is-warn", kind === "warn");
    statusEl.classList.toggle("is-ok", kind === "ok");
    window.clearTimeout(toastTimer);
    toastTimer = window.setTimeout(() => {
      statusEl.textContent = "";
      statusEl.classList.remove("is-warn", "is-ok");
    }, TOAST_MS);
  }

  /* ---------------------------- 输入：指针 ---------------------------- */

  function handleCanvasPointerDown(event: PointerEvent): void {
    noteInput();
    if (computeInputLocked()) {
      denyFeedback();
      return;
    }
    const rect = canvasEl.getBoundingClientRect();
    const ndc = new THREE.Vector2(
      ((event.clientX - rect.left) / rect.width) * 2 - 1,
      -(((event.clientY - rect.top) / rect.height) * 2 - 1)
    );
    // §6.4 / §7.4：有效接缝两端在屏幕上重合，点击重合区域视为跨越请求，
    // 目标取离玩家更远的接缝端点（避免命中近端实体后误判为选中机关）。
    const clickScreen: ScreenPoint = {
      x: (ndc.x * 0.5 + 0.5) * INTERNAL_WIDTH,
      y: (1 - (ndc.y * 0.5 + 0.5)) * INTERNAL_HEIGHT
    };
    const seamTarget = resolveSeamCrossClick(clickScreen);
    if (seamTarget) {
      startWalkToNode(seamTarget, directionToNode(seamTarget));
      return;
    }
    pointerRay.setFromCamera(ndc, camera);
    const clickable = [...levelScene.mechanismHitMeshes, ...levelScene.walkMeshes];
    const hits = pointerRay
      .intersectObjects(clickable, true)
      .filter((hit) => hit.object instanceof THREE.Mesh);
    if (hits.length === 0) {
      return;
    }
    const hit = hits[0];
    // 沿父链找语义标记（描边等子节点没有 userData）。
    let object: THREE.Object3D | null = hit.object;
    let mechanismId: string | null = null;
    let nodeId: string | null = null;
    let walkable = false;
    while (object) {
      if (!mechanismId && typeof object.userData.mechanismId === "string") {
        mechanismId = object.userData.mechanismId;
      }
      if (!nodeId && typeof object.userData.nodeId === "string") {
        nodeId = object.userData.nodeId;
      }
      if (object.userData.walkable) {
        walkable = true;
      }
      object = object.parent;
    }
    if (mechanismId) {
      if (state.selectedMechanismId !== mechanismId) {
        // §5.5：点击机关实体先选中，选中后才显示方向控制。
        selectMechanism(mechanismId);
        return;
      }
      // 再次点击已选中机关：视为前往该机关最近节点的移动请求。
      const target = nearestNodeToPoint(hit.point);
      if (target) {
        startWalkToNode(target, directionToNode(target));
      }
      return;
    }
    const target = nodeId ?? (walkable ? nearestNodeToPoint(hit.point) : null);
    if (target) {
      startWalkToNode(target);
    }
  }

  /* ---------------------------- 输入：键盘（§12.3） ---------------------------- */

  function arrowMove(direction: ScreenPoint): void {
    if (computeInputLocked()) {
      denyFeedback();
      return;
    }
    if ((navGraph.adjacency.get(state.playerNodeId) ?? []).length === 0) {
      denyFeedback();
      return;
    }
    const best = selectDirectionalNeighbor(navGraph, state.playerNodeId, direction, projectNode);
    if (best) {
      startWalkToNode(best);
    } else {
      denyFeedback();
    }
  }

  const unsubscribeDirection = options.subscribeDirection?.((direction) => {
    noteInput();
    arrowMove(direction);
  }) ?? (() => undefined);

  const handleKeyDown = (event: KeyboardEvent) => {
    if (event.repeat) return;
    const key = event.key;
    if (key === "1" || key === "2" || key === "3") {
      noteInput();
      requestViewSwitch(VIEW_ORDER[Number(key) - 1]);
      return;
    }
    if (key === "q" || key === "Q") {
      noteInput();
      requestMechanismStep(-1);
      return;
    }
    if (key === "e" || key === "E") {
      noteInput();
      requestMechanismStep(1);
      return;
    }
    if (key === "ArrowLeft" || key === "ArrowRight" || key === "ArrowUp" || key === "ArrowDown") {
      noteInput();
      event.preventDefault();
      const direction: ScreenPoint =
        key === "ArrowLeft"
          ? { x: -1, y: 0 }
          : key === "ArrowRight"
            ? { x: 1, y: 0 }
            : key === "ArrowUp"
              ? { x: 0, y: -1 }
              : { x: 0, y: 1 };
      arrowMove(direction);
      return;
    }
    if (key === " ") {
      noteInput();
      event.preventDefault();
      // Space：朝向出口的等价移动请求（不可达时走断口边缘）。
      startWalkToNode(levelDef.exitNodeId);
    }
  };
  window.addEventListener("keydown", handleKeyDown);

  canvasEl.addEventListener("pointerdown", handleCanvasPointerDown);
  const handleMechanismMinus = () => requestMechanismStep(-1);
  const handleMechanismPlus = () => requestMechanismStep(1);
  const handleViewClicks = new Map<HTMLButtonElement, () => void>();
  mechMinusButton.addEventListener("click", handleMechanismMinus);
  mechPlusButton.addEventListener("click", handleMechanismPlus);
  resetButton.addEventListener("click", resetCurrentLevel);
  replayButton.addEventListener("click", replayAll);
  for (const [view, button] of viewButtons) {
    const handler = () => requestViewSwitch(view);
    handleViewClicks.set(button, handler);
    button.addEventListener("click", handler);
  }

  /* ---------------------------- 选中框 / 卡关脉冲 ---------------------------- */

  function updateSelectionHelper(now: number): void {
    const mechanismId = state.selectedMechanismId;
    if (!mechanismId || !levelScene || state.phase !== "playing") {
      selectionHelper.visible = false;
      return;
    }
    const group = levelScene.mechanismGroups.get(mechanismId);
    if (!group) {
      selectionHelper.visible = false;
      return;
    }
    // 选中框贴合机关实际包围盒（§5.5）。
    selectionBox.setFromObject(group);
    selectionHelper.visible = now < idlePulseUntil ? Math.floor(now / 140) % 2 === 0 : true;
  }

  function updateIdleHint(now: number): void {
    // 12s 无输入仅脉冲当前可操作机关，不提示答案（§7.5）。
    if (state.phase !== "playing" || mechanismAnimation || !state.selectedMechanismId) {
      return;
    }
    if (now - lastInputAt >= IDLE_HINT_MS) {
      idlePulseUntil = now + 900;
      lastInputAt = now;
    }
  }

  /* ---------------------------- 调试接口（§10） ---------------------------- */

  function buildSnapshot(): StairDemoSnapshot {
    return {
      levelId: state.levelId,
      phase: state.phase,
      cameraView: state.cameraView,
      mechanismValues: { ...mechanismValues },
      playerNodeId: state.playerNodeId,
      targetNodeId: state.targetNodeId,
      activePhysicalEdges: navGraph.edges.filter((edge) => edge.kind !== "perspective").map((edge) => edge.id),
      activePerspectiveEdges: navGraph.edges.filter((edge) => edge.kind === "perspective").map((edge) => edge.id),
      invalidProjectedPairs: currentSeams.filter((seam) => !seam.valid).map((seam) => seam.linkId),
      inputLocked: computeInputLocked(),
      viewSwitchAvailable: canSwitchViewNow(),
      presentation: {
        stage: presentation?.stage ?? null,
        floatingFragmentCount: levelScene.floatingFragments.length,
        energyRingCount: levelScene.energyRings.length,
        dustPointCount: levelScene.dustField
          ? (levelScene.dustField.geometry.getAttribute("position")?.count ?? 0)
          : 0,
        routeEffectActive: levelScene.routeEffect !== null
      },
      materialTextures: getStairMaterialTextureStatus()
    };
  }

  const devApi: StairDemoDevApi = {
    setView(view) {
      if (computeInputLocked()) return;
      requestViewSwitch(view, { instant: true });
    },
    setMechanism(id, nextValue) {
      if (computeInputLocked()) return;
      const mechanism = levelDef.mechanisms.find((entry) => entry.id === id);
      if (!mechanism) return;
      const normalized = ((nextValue % mechanism.stateCount) + mechanism.stateCount) % mechanism.stateCount;
      mechanismValues = { ...mechanismValues, [id]: normalized };
      snapMechanismTransforms();
      scene.updateMatrixWorld(true);
      recomputeWorld();
      const node = navGraph.nodes.get(state.playerNodeId);
      if (node) {
        player.object3d.position.copy(node.position);
      }
      updateMechUI();
    },
    clickNode(nodeId) {
      if (computeInputLocked()) return;
      startWalkToNode(nodeId);
    },
    resetLevel() {
      if (curtain || computeInputLocked() || state.lockedPerspectiveEdgeId !== null) return;
      loadLevel(state.levelId, { resetView: false });
    },
    replayAll() {
      replayAll();
    }
  };
  const previousRenderGameToText = window.render_game_to_text;
  const renderGameToText = () => JSON.stringify(buildSnapshot());
  window.stairDemoDev = devApi;
  window.render_game_to_text = renderGameToText;

  /* ---------------------------- 舞台缩放（§8.1 整数倍优先） ---------------------------- */

  function layoutStage(): void {
    const viewportWidth = root.clientWidth || window.innerWidth;
    const viewportHeight = root.clientHeight || window.innerHeight;
    const railWidth = viewsEl.offsetWidth + 10;
    const chromeHeight = topbarEl.offsetHeight + (root.querySelector<HTMLElement>(".stair-bottombar")?.offsetHeight ?? 0) + 44;
    const availableWidth = Math.max(220, viewportWidth - 24 - railWidth);
    const availableHeight = Math.max(150, viewportHeight - chromeHeight);
    let scale = Math.min(availableWidth / CANVAS_WIDTH, availableHeight / CANVAS_HEIGHT, 2);
    if (scale >= 1) {
      scale = Math.max(1, Math.floor(scale));
    }
    stageWrapEl.style.width = `${Math.round(CANVAS_WIDTH * scale)}px`;
    stageWrapEl.style.height = `${Math.round(CANVAS_HEIGHT * scale)}px`;
    stageEl.style.transform = `scale(${scale})`;
  }

  window.addEventListener("resize", layoutStage);
  layoutStage();
  window.setTimeout(layoutStage, 60);

  /* ---------------------------- 主循环 ---------------------------- */

  let lastFrameAt = performance.now();
  renderer.setAnimationLoop(() => {
    const now = performance.now();
    const deltaSeconds = Math.min(0.05, Math.max(0, (now - lastFrameAt) / 1000));
    lastFrameAt = now;

    updateCameraTransition(now);
    updateMechanismAnimation(now);
    updateWalk(now, deltaSeconds);
    updateLevelComplete(now);
    updatePresentation(now);
    updateCurtain(now);
    updateSeamAnimations(now);
    updateSelectionHelper(now);
    updateIdleHint(now);
    updateSpatialEffects(now);
    player.update(now);
    playerShadow.position.set(
      player.object3d.position.x,
      player.object3d.position.y + 0.02,
      player.object3d.position.z
    );
    playerShadow.visible = player.object3d.visible;

    renderer.render(scene, camera);
  });

  /* ---------------------------- 启动 ---------------------------- */

  loadLevel("stair_a", { resetView: true });
  beginPresentation("entry", ENTRY_SEQUENCE_MS);
  // 开场像素块遮罩收起（§9 同一转场语言）。
  curtainBlocks.forEach((block) => block.classList.add("is-covered"));
  curtainEl.hidden = false;
  curtain = { phase: "reveal", startedAt: performance.now(), onCovered: null };

  return () => {
    renderer.setAnimationLoop(null);
    window.clearTimeout(toastTimer);
    unsubscribeDirection();
    window.removeEventListener("keydown", handleKeyDown);
    window.removeEventListener("resize", layoutStage);
    canvasEl.removeEventListener("pointerdown", handleCanvasPointerDown);
    mechMinusButton.removeEventListener("click", handleMechanismMinus);
    mechPlusButton.removeEventListener("click", handleMechanismPlus);
    resetButton.removeEventListener("click", resetCurrentLevel);
    replayButton.removeEventListener("click", replayAll);
    for (const [button, handler] of handleViewClicks) {
      button.removeEventListener("click", handler);
    }
    for (const visual of seamVisuals.values()) removeSeamVisual(visual);
    seamVisuals.clear();
    disposeLevelScene();
    disposeStairMaterials();
    selectionHelper.geometry.dispose();
    (selectionHelper.material as THREE.Material).dispose();
    if (window.stairDemoDev === devApi) delete window.stairDemoDev;
    if (window.render_game_to_text === renderGameToText) {
      window.render_game_to_text = previousRenderGameToText;
    }
  };
}

}
