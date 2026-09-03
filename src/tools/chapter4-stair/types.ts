import type * as THREE from "three";

/**
 * 第四章楼梯间三视角空间解谜 —— 共享类型契约。
 * 设计依据：docs/plans/2026-08-08-chapter4-monument-perspective-two-level-design.md
 * 本文件是关卡数据、投影引擎、渲染与主 Demo 之间的唯一接口定义，各模块只依赖这里导出的类型。
 */

export type CameraViewId = "south_east" | "south_west" | "top_oblique";

export type LevelId = "stair_a" | "stair_b";

export type DemoPhase =
  | "entry_sequence"
  | "playing"
  | "walking"
  | "camera_transition"
  | "level_complete"
  | "level_interlude"
  | "finale"
  | "all_complete";

export type MechanismKind = "rotate" | "vertical" | "horizontal";

/** 内部像素网格（渲染缓冲区）尺寸；画布逻辑尺寸为其整数倍放大。 */
export const INTERNAL_WIDTH = 480;
export const INTERNAL_HEIGHT = 270;
export const CANVAS_WIDTH = 960;
export const CANVAS_HEIGHT = 540;

/** 投影接缝判定常量（设计文档 §5.3）。 */
export const PROJECTION_MAX_SCREEN_DISTANCE_PX = 6;
export const PROJECTION_TANGENT_MAX_DEGREES = 20;

/** 视角切换时长（减弱动态模式降为 1ms）。 */
export const CAMERA_TRANSITION_MS = 480;
/** 机关单档运动时长区间。 */
export const MECHANISM_STEP_MIN_MS = 420;
export const MECHANISM_STEP_MAX_MS = 520;
/** 关卡间像素块遮罩转场时长。 */
export const LEVEL_CURTAIN_MS = 360;
/** 错误重合橙色虚线首次保留时长。 */
export const INVALID_SEAM_HOLD_MS = 1200;
/** 卡关无输入后机关脉冲提示的等待时长。 */
export const IDLE_HINT_MS = 12_000;

/**
 * 可走表面暴露的连接端点（设计文档 §5.2）。
 * ownerId 为机关 id 时，worldPosition / worldTangent 以该机关 0 档姿态声明，
 * 引擎按机关当前档位做刚体变换得到实际世界坐标；ownerId 为 "level" 时为静态端点。
 */
export interface PerspectiveConnector {
  id: string;
  ownerId: string;
  worldPosition: THREE.Vector3;
  worldTangent: THREE.Vector3;
  nodeId: string;
  views: CameraViewId[];
  linkGroup: string;
  projectionMode: "physical" | "perspective";
}

/**
 * 关卡白名单：只有作者明确配对的一组端点可以形成投影临时边。
 * connectorA → connectorB 同时声明玩家上行方向，供屏幕重合时的 ↑/↓ 输入判定。
 */
export interface PerspectiveLinkDefinition {
  id: string;
  linkGroup: string;
  connectorA: string;
  connectorB: string;
}

export interface MechanismDefinition {
  id: string;
  kind: MechanismKind;
  /** rotate 为 4（0–3，每档 90°），vertical/horizontal 为 3（0–2）。 */
  stateCount: number;
  initialState: number;
  /** 旋转枢轴 / 平移基准点（世界坐标，0 档姿态）。 */
  pivot: readonly [number, number, number];
  /** vertical 为 y；horizontal 为 x 或 z；rotate 绕 y。 */
  axis: "x" | "y" | "z";
  /** 每档位移（世界单位；rotate 忽略，固定 90°）。 */
  stepSize: number;
  /** UI 底部显示的机关名（不含答案性文字）。 */
  label: string;
}

export interface NavNodeDefinition {
  id: string;
  /** "level" 为静态节点；机关 id 表示节点随该机关刚体运动。 */
  ownerId: string;
  /** owner 0 档姿态下的世界坐标。 */
  position: readonly [number, number, number];
  /** 安全平台节点：用于关卡重算后的恢复落点，不限制站定时的视角切换。 */
  safe: boolean;
}

/** 固定平台与楼梯内部的物理边（始终存在）。 */
export interface PhysicalEdgeDefinition {
  id: string;
  a: string;
  b: string;
}

/** 机关当前档位产生的真实机械连接边。 */
export interface MechanismEdgeDefinition {
  id: string;
  a: string;
  b: string;
  mechanismId: string;
  /** 机关处于该档位时边生效。 */
  requiredState: number;
}

/** 渲染所需的几何布局（数据驱动，主 Demo 据此构建 Three.js 场景）。 */
export interface PlatformBoxSpec {
  id: string;
  /** 所属者："level" 静态，或机关 id（随机关刚体运动）。 */
  ownerId: string;
  center: readonly [number, number, number];
  size: readonly [number, number, number];
  material: StairMaterialKey;
  walkable: boolean;
}

export interface StairSpanSpec {
  id: string;
  ownerId: string;
  /** 梯段低端中心（走面）。 */
  from: readonly [number, number, number];
  /** 梯段高端中心（走面）。 */
  to: readonly [number, number, number];
  width: number;
  steps: number;
  material: StairMaterialKey;
}

export type DecorationKind = "fire_door" | "floor_plate" | "wall_lamp" | "window_frame" | "potted_plant";

export interface DecorationSpec {
  id: string;
  kind: DecorationKind;
  position: readonly [number, number, number];
  /** 朝向（绕 y 弧度）。 */
  rotationY?: number;
}

export interface StairLevelGeometry {
  platforms: PlatformBoxSpec[];
  stairs: StairSpanSpec[];
  decorations: DecorationSpec[];
}

export type StairMaterialKey =
  | "wall_lit"
  | "wall_side"
  | "stone_lit"
  | "stone_back"
  | "structure"
  | "outline"
  | "night_glass"
  | "warn";

export interface StairLevelFeedbackText {
  /** 首次出现有效投影接缝。 */
  firstSeam: string;
  /** 不可达点击走到断口。 */
  blocked: string;
  /** 位置重合但行进方向不通。 */
  wrongDirection: string;
  /** 本关任务目标（顶部显示，不含逐项步骤）。 */
  objective: string;
}

export interface StairLevelDefinition {
  id: LevelId;
  title: string;
  startNodeId: string;
  exitNodeId: string;
  nodes: NavNodeDefinition[];
  physicalEdges: PhysicalEdgeDefinition[];
  mechanisms: MechanismDefinition[];
  mechanismEdges: MechanismEdgeDefinition[];
  connectors: PerspectiveConnector[];
  perspectiveLinks: PerspectiveLinkDefinition[];
  /** 按解题推进顺序记录的上行投影视角；相邻阶段必须不同。 */
  ascentViewSequence: readonly CameraViewId[];
  geometry: StairLevelGeometry;
  feedback: StairLevelFeedbackText;
}

/** 引擎输出的投影接缝。valid=false 为橙色虚线（距离满足、方向失败），不写入导航图。 */
export interface PerspectiveSeam {
  id: string;
  linkId: string;
  linkGroup: string;
  connectorA: string;
  connectorB: string;
  nodeA: string;
  nodeB: string;
  screenDistancePx: number;
  valid: boolean;
}

export type NavEdgeKind = "physical" | "mechanism" | "perspective";

export interface NavGraphEdge {
  id: string;
  a: string;
  b: string;
  kind: NavEdgeKind;
}

export interface NavGraphNode {
  id: string;
  safe: boolean;
  position: THREE.Vector3;
}

export interface NavGraph {
  nodes: ReadonlyMap<string, NavGraphNode>;
  edges: readonly NavGraphEdge[];
  adjacency: ReadonlyMap<string, readonly string[]>;
}

/** 机关运行态：当前档位 + 刚体变换（引擎与渲染共用）。 */
export interface MechanismRuntimeState {
  id: string;
  state: number;
  /** 当前档位下，把 0 档声明坐标变换到世界坐标的矩阵。 */
  matrix: THREE.Matrix4;
}

/** 设计文档 §10 的确定性调试快照。 */
export interface StairDemoSnapshot {
  levelId: LevelId;
  phase: DemoPhase;
  cameraView: CameraViewId;
  mechanismValues: Record<string, number>;
  playerNodeId: string;
  targetNodeId: string | null;
  activePhysicalEdges: string[];
  activePerspectiveEdges: string[];
  invalidProjectedPairs: string[];
  inputLocked: boolean;
  viewSwitchAvailable: boolean;
  presentation: {
    stage: "entry" | "level_break" | "level_reveal" | "finale" | null;
    floatingFragmentCount: number;
    energyRingCount: number;
    dustPointCount: number;
    routeEffectActive: boolean;
  };
  materialTextures: {
    setId: string;
    expected: number;
    loaded: number;
    failed: readonly string[];
    ready: boolean;
    pixelLevels: Readonly<Record<string, readonly number[]>>;
    mappedMaterials: readonly string[];
    pixelSizes: Readonly<Record<string, readonly [number, number]>>;
  };
}

/** 独立 Demo 开发 API（仅验收用，不进入正式玩家 UI）。 */
export interface StairDemoDevApi {
  setView(view: CameraViewId): void;
  setMechanism(id: string, state: number): void;
  clickNode(nodeId: string): void;
  resetLevel(): void;
  replayAll(): void;
}
