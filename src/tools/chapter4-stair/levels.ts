import * as THREE from "three";

import type {
  CameraViewId,
  LevelId,
  PerspectiveLinkDefinition,
  StairLevelDefinition
} from "./types";

/**
 * 第四章楼梯间三视角空间解谜 —— 关卡数据（设计文档 §6 折返楼梯间 / §7 环形错层楼梯井）。
 * 本模块是纯数据：节点、物理边、机关、机关条件边、投影端点、白名单、几何布局与反馈文案。
 * 坐标经 scripts/verify-chapter4-stair-levels.mjs 全量（视角 × 档位组合）投影验证。
 *
 * 契约缺口说明：types.ts 未定义相机参数（视角位置 / lookAt 中心 / 正交范围），
 * 引擎与渲染层需要统一的相机来源，故在本模块补充 StairLevelCameraSpec / LEVEL_CAMERAS。
 */

/** 投影端点 linkGroup 常量（防止跨组误连，设计文档 §5.2）。 */
export const LINK_GROUP_A = "A_LINK";
export const LINK_GROUP_B_LOWER = "B_LOWER_LINK";
export const LINK_GROUP_B_UPPER = "B_UPPER_LINK";

/** 单个视角的确定性正交相机参数（设计文档 §5.1）。 */
export interface StairViewCameraSpec {
  /** 相机位置（文档 §5.1 参考位置）。 */
  position: readonly [number, number, number];
}

/** 一关的相机组：三个视角共用同一 lookAt 中心与同一正交可见范围。 */
export interface StairLevelCameraSpec {
  /** 三个视角共用的 lookAt 中心。 */
  center: readonly [number, number, number];
  /** 正交半宽 / 半高（参照现有原型 ±9.8 / ±5.5）。 */
  halfWidth: number;
  halfHeight: number;
  near: number;
  far: number;
  views: Record<CameraViewId, StairViewCameraSpec>;
}

/** 文档 §5.1 的固定视角位置，两关共用。 */
const VIEW_POSITIONS: Record<CameraViewId, StairViewCameraSpec> = {
  south_east: { position: [12, 11, 14] },
  south_west: { position: [-12, 11, 14] },
  top_oblique: { position: [0, 17, 12] }
};

/** 每关相机：同一关卡内三个视角 lookAt 同一中心。 */
export const LEVEL_CAMERAS: Record<LevelId, StairLevelCameraSpec> = {
  stair_a: {
    center: [0, 1.55, 0],
    halfWidth: 9.8,
    halfHeight: 5.5,
    near: 0.1,
    far: 80,
    views: VIEW_POSITIONS
  },
  stair_b: {
    // 第二关错层更高，中心上移，保证高区孤岛在三视角内可见。
    center: [0, 4.5, 0.5],
    halfWidth: 9.8,
    halfHeight: 5.5,
    near: 0.1,
    far: 80,
    views: VIEW_POSITIONS
  }
};

const ALL_VIEWS: CameraViewId[] = ["south_east", "south_west", "top_oblique"];

/* --------------------------------------------------------------------------
 * 第一关：折返楼梯间（设计文档 §6）
 * 关键链：横移台中档接通入口→中央梯段；西南视角 + 中央梯 0 档形成投影接缝
 * A_STAIR_HIGH ↔ A_MID_ISLAND；升降台中档同时短接孤台与出口。
 * ----------------------------------------------------------------------- */
export const LEVEL_A: StairLevelDefinition = {
  id: "stair_a",
  title: "折返楼梯间",
  startNodeId: "A_START",
  exitNodeId: "A_EXIT",
  nodes: [
    { id: "A_START", ownerId: "level", position: [-5.2, 0.9, 0], safe: true },
    { id: "A_SLIDE", ownerId: "a_slide", position: [-2.9, 0.9, -1.2], safe: false },
    { id: "A_STAIR_LOW", ownerId: "a_stair", position: [-0.7, 0.9, 0], safe: false },
    { id: "A_STAIR_HIGH", ownerId: "a_stair", position: [3.85, 3.0, 0], safe: false },
    { id: "A_MID_ISLAND", ownerId: "level", position: [5.88, 1.4, -2.36], safe: true },
    { id: "A_LIFT", ownerId: "a_lift", position: [7.28, 0.2, -2.36], safe: false },
    { id: "A_EXIT", ownerId: "level", position: [9.0, 1.4, -2.36], safe: true }
  ],
  physicalEdges: [
    // 中央梯段内部：低端（旋转不变点）与高端始终连通。
    { id: "a_edge_stair_span", a: "A_STAIR_LOW", b: "A_STAIR_HIGH" }
  ],
  mechanisms: [
    {
      id: "a_slide",
      kind: "horizontal",
      stateCount: 3,
      initialState: 0,
      pivot: [-2.9, 0.72, -1.2],
      axis: "z",
      stepSize: 1.2,
      label: "入口横移台"
    },
    {
      id: "a_stair",
      kind: "rotate",
      stateCount: 4,
      initialState: 1,
      pivot: [-0.7, 0.3, 0],
      axis: "y",
      stepSize: 0,
      label: "中央旋转梯"
    },
    {
      id: "a_lift",
      kind: "vertical",
      stateCount: 3,
      initialState: 0,
      pivot: [7.28, 0.02, -2.36],
      axis: "y",
      stepSize: 1.2,
      label: "出口升降台"
    }
  ],
  mechanismEdges: [
    // 横移台中档（1）：把起点平台接到中央梯段下方。
    { id: "a_edge_start_slide", a: "A_START", b: "A_SLIDE", mechanismId: "a_slide", requiredState: 1 },
    { id: "a_edge_slide_stair", a: "A_SLIDE", b: "A_STAIR_LOW", mechanismId: "a_slide", requiredState: 1 },
    // 升降台中档（1）：孤台 → 升降台 → 出口一次短接（设计文档 §6.4 步骤 5–6）。
    { id: "a_edge_island_lift", a: "A_MID_ISLAND", b: "A_LIFT", mechanismId: "a_lift", requiredState: 1 },
    { id: "a_edge_lift_exit", a: "A_LIFT", b: "A_EXIT", mechanismId: "a_lift", requiredState: 1 }
  ],
  connectors: [
    {
      id: "a_seam_stair_high",
      ownerId: "a_stair",
      // 0 档姿态：梯段高端，行进方向 +x。
      worldPosition: new THREE.Vector3(3.85, 3.0, 0),
      worldTangent: new THREE.Vector3(1, 0, 0),
      nodeId: "A_STAIR_HIGH",
      views: ALL_VIEWS,
      linkGroup: LINK_GROUP_A,
      projectionMode: "perspective"
    },
    {
      id: "a_seam_island",
      ownerId: "level",
      // 孤台端点：位于西南视线上（与 0 档梯顶重合），朝向回望梯段。
      worldPosition: new THREE.Vector3(5.88, 1.4, -2.36),
      worldTangent: new THREE.Vector3(-1, 0, 0),
      nodeId: "A_MID_ISLAND",
      views: ALL_VIEWS,
      linkGroup: LINK_GROUP_A,
      projectionMode: "perspective"
    }
  ],
  perspectiveLinks: [
    {
      id: "a_link_stair_island",
      linkGroup: LINK_GROUP_A,
      connectorA: "a_seam_stair_high",
      connectorB: "a_seam_island"
    }
  ],
  ascentViewSequence: ["south_west"],
  geometry: {
    platforms: [
      // 入口安全平台。
      { id: "a_platform_start", ownerId: "level", center: [-5.2, 0.72, 0], size: [3.6, 0.36, 3.2], material: "stone_lit", walkable: true },
      // 横移台台面（0 档位于 z=-1.2，中档与入口对齐）。
      { id: "a_platform_slide", ownerId: "a_slide", center: [-2.9, 0.72, -1.2], size: [2.7, 0.36, 1.4], material: "structure", walkable: true },
      // 中央梯段底部固定基座（旋转不变点，衔接横移台）。
      { id: "a_platform_stair_base", ownerId: "level", center: [-0.7, 0.72, 0], size: [1.2, 0.36, 1.6], material: "stone_back", walkable: true },
      // 中层孤台。
      { id: "a_platform_island", ownerId: "level", center: [6.28, 1.22, -2.36], size: [2.4, 0.36, 2.0], material: "stone_lit", walkable: true },
      // 出口升降台台面（0 档沉底，中档与孤台 / 出口齐平）。
      { id: "a_platform_lift", ownerId: "a_lift", center: [7.28, 0.02, -2.36], size: [2.4, 0.36, 2.2], material: "structure", walkable: true },
      // 消防门前平台。
      { id: "a_platform_exit", ownerId: "level", center: [9.0, 1.22, -2.36], size: [1.6, 0.36, 1.8], material: "stone_lit", walkable: true },
      // 背景山墙（-z 远端，所有端点之前，不遮挡任何视线）。
      { id: "a_backdrop_wall", ownerId: "level", center: [2.0, 2.0, -5.6], size: [20, 5.6, 0.4], material: "wall_lit", walkable: false }
    ],
    stairs: [
      // 中央旋转梯（0 档沿 +x 上升）。
      { id: "a_stair_span", ownerId: "a_stair", from: [-0.7, 0.9, 0], to: [3.85, 3.0, 0], width: 1.42, steps: 13, material: "stone_lit" }
    ],
    decorations: [
      { id: "a_deco_fire_door", kind: "fire_door", position: [9.62, 1.4, -2.36], rotationY: Math.PI / 2 },
      { id: "a_deco_floor_plate", kind: "floor_plate", position: [-4.0, 2.6, -5.38] },
      { id: "a_deco_lamp_1", kind: "wall_lamp", position: [-1.5, 3.4, -5.38] },
      { id: "a_deco_lamp_2", kind: "wall_lamp", position: [6.5, 2.8, -5.38] },
      { id: "a_deco_window_1", kind: "window_frame", position: [1.5, 2.4, -5.39] },
      { id: "a_deco_window_2", kind: "window_frame", position: [8.6, 2.2, -5.39] },
      { id: "a_deco_plant_1", kind: "potted_plant", position: [-6.6, 0.9, 1.2] },
      { id: "a_deco_plant_2", kind: "potted_plant", position: [7.35, 1.4, -3.1] }
    ]
  },
  feedback: {
    objective: "让入口、中央梯段和出口在合适视角中连续。",
    firstSeam: "这个视角下，两端连在一起。",
    blocked: "通路在这里中断。调整机关或切换视角。",
    wrongDirection: "端点位置接近，行进方向没有接上。"
  }
};

/* --------------------------------------------------------------------------
 * 第二关：环形错层楼梯井（设计文档 §7）
 * 关键链：西南视角 + 下层梯 3 档形成接缝 B_LOWER_HIGH ↔ B_MID_LIFT_LOW；
 * 升降台高档对接中层平台；上方视角 + 上层梯 1 档形成接缝 B_UPPER_HIGH ↔ B_HIGH_ISLAND；
 * 东南视角 + 上层梯 3 档为安排的唯一错误重合（位置重合、切线同向，橙色虚线）；
 * 出口横移台末档短接孤台与消防门。
 * ----------------------------------------------------------------------- */
export const LEVEL_B: StairLevelDefinition = {
  id: "stair_b",
  title: "环形错层楼梯井",
  startNodeId: "B_START",
  exitNodeId: "B_EXIT",
  nodes: [
    { id: "B_START", ownerId: "level", position: [-5.2, 0.9, 1.8], safe: true },
    { id: "B_LOWER_LOW", ownerId: "b_lower_stair", position: [-2.15, 0.9, 1.35], safe: false },
    { id: "B_LOWER_HIGH", ownerId: "b_lower_stair", position: [1.35, 2.7, 1.35], safe: false },
    { id: "B_MID_LIFT_LOW", ownerId: "b_mid_lift", position: [-0.3035, 1.7, 2.7731], safe: false },
    // 中层升降台高停靠平台（静态，安全）：升降台高档时与台面齐平。
    { id: "B_MID_LIFT_HIGH", ownerId: "level", position: [0.85, 3.9, 1.75], safe: true },
    { id: "B_UPPER_LOW", ownerId: "b_upper_stair", position: [2.0, 3.9, 0.8], safe: false },
    { id: "B_UPPER_HIGH", ownerId: "b_upper_stair", position: [0.3043, 5.6, 3.5138], safe: false },
    { id: "B_HIGH_ISLAND", ownerId: "level", position: [4.7138, 8.5437, 5.204], safe: true },
    { id: "B_EXIT_SLIDE", ownerId: "b_exit_slide", position: [8.1138, 8.5437, 5.7], safe: false },
    { id: "B_EXIT", ownerId: "level", position: [4.7138, 8.5437, 7.9], safe: true }
  ],
  physicalEdges: [
    { id: "b_edge_start_lower", a: "B_START", b: "B_LOWER_LOW" },
    { id: "b_edge_lower_span", a: "B_LOWER_LOW", b: "B_LOWER_HIGH" },
    // 中层平台与上层梯下端（旋转不变点）固定相邻。
    { id: "b_edge_landing_upper", a: "B_MID_LIFT_HIGH", b: "B_UPPER_LOW" },
    { id: "b_edge_upper_span", a: "B_UPPER_LOW", b: "B_UPPER_HIGH" }
  ],
  mechanisms: [
    {
      id: "b_lower_stair",
      kind: "rotate",
      stateCount: 4,
      initialState: 1,
      pivot: [-2.15, 0.3, 1.35],
      axis: "y",
      stepSize: 0,
      label: "下层旋转梯"
    },
    {
      id: "b_mid_lift",
      kind: "vertical",
      stateCount: 3,
      initialState: 0,
      pivot: [-0.3035, 1.52, 2.7731],
      axis: "y",
      stepSize: 1.1,
      label: "中层升降台"
    },
    {
      id: "b_upper_stair",
      kind: "rotate",
      stateCount: 4,
      initialState: 0,
      pivot: [2.0, 3.3, 0.8],
      axis: "y",
      stepSize: 0,
      label: "上层旋转梯"
    },
    {
      id: "b_exit_slide",
      kind: "horizontal",
      stateCount: 3,
      initialState: 0,
      pivot: [8.1138, 8.3637, 5.7],
      axis: "x",
      stepSize: -1.7,
      label: "出口横移台"
    }
  ],
  mechanismEdges: [
    // 升降台高档（2）：台面与中层平台齐平，人物下台。
    { id: "b_edge_lift_landing", a: "B_MID_LIFT_LOW", b: "B_MID_LIFT_HIGH", mechanismId: "b_mid_lift", requiredState: 2 },
    // 出口横移台末档（2）：高层孤台 → 横移台 → 消防门。
    { id: "b_edge_island_slide", a: "B_HIGH_ISLAND", b: "B_EXIT_SLIDE", mechanismId: "b_exit_slide", requiredState: 2 },
    { id: "b_edge_slide_exit", a: "B_EXIT_SLIDE", b: "B_EXIT", mechanismId: "b_exit_slide", requiredState: 2 }
  ],
  connectors: [
    {
      id: "b_seam_lower_high",
      ownerId: "b_lower_stair",
      // 0 档姿态：下层梯高端，行进方向 +x；3 档时朝向 +z 并在西南视角对准升降台。
      worldPosition: new THREE.Vector3(1.35, 2.7, 1.35),
      worldTangent: new THREE.Vector3(1, 0, 0),
      nodeId: "B_LOWER_HIGH",
      views: ALL_VIEWS,
      linkGroup: LINK_GROUP_B_LOWER,
      projectionMode: "perspective"
    },
    {
      id: "b_seam_lift_low",
      ownerId: "b_mid_lift",
      // 0 档姿态：升降台台面（低停靠点），位于下层梯 3 档高端的西南视线上。
      worldPosition: new THREE.Vector3(-0.3035, 1.7, 2.7731),
      worldTangent: new THREE.Vector3(0, 0, -1),
      nodeId: "B_MID_LIFT_LOW",
      views: ALL_VIEWS,
      linkGroup: LINK_GROUP_B_LOWER,
      projectionMode: "perspective"
    },
    {
      id: "b_seam_upper_high",
      ownerId: "b_upper_stair",
      // 0 档姿态：上层梯高端（臂方向 φ=122°）；1 档在上方视角对准孤台，3 档在东南视角错误重合。
      worldPosition: new THREE.Vector3(0.3043, 5.6, 3.5138),
      worldTangent: new THREE.Vector3(-0.529919, 0, 0.848048),
      nodeId: "B_UPPER_HIGH",
      views: ALL_VIEWS,
      linkGroup: LINK_GROUP_B_UPPER,
      projectionMode: "perspective"
    },
    {
      id: "b_seam_high_island",
      ownerId: "level",
      // 高层孤台端点：同时位于 1 档梯顶的上方视线与 3 档梯顶的东南视线上。
      worldPosition: new THREE.Vector3(4.7138, 8.5437, 5.204),
      worldTangent: new THREE.Vector3(-0.848048, 0, -0.529919),
      nodeId: "B_HIGH_ISLAND",
      views: ALL_VIEWS,
      linkGroup: LINK_GROUP_B_UPPER,
      projectionMode: "perspective"
    }
  ],
  perspectiveLinks: [
    {
      id: "b_link_lower_stair_lift",
      linkGroup: LINK_GROUP_B_LOWER,
      connectorA: "b_seam_lower_high",
      connectorB: "b_seam_lift_low"
    },
    {
      id: "b_link_upper_stair_island",
      linkGroup: LINK_GROUP_B_UPPER,
      connectorA: "b_seam_upper_high",
      connectorB: "b_seam_high_island"
    }
  ],
  ascentViewSequence: ["south_west", "top_oblique"],
  geometry: {
    platforms: [
      // 下层入口平台。
      { id: "b_platform_start", ownerId: "level", center: [-4.8, 0.72, 1.6], size: [4.8, 0.36, 2.4], material: "stone_lit", walkable: true },
      // 下层梯底部固定基座（旋转不变点）。
      { id: "b_platform_lower_base", ownerId: "level", center: [-2.15, 0.72, 1.35], size: [1.3, 0.36, 1.5], material: "stone_back", walkable: true },
      // 中层升降台台面（0 档低停靠点，高档与中层平台齐平）。
      { id: "b_platform_lift", ownerId: "b_mid_lift", center: [-0.3035, 1.52, 2.7731], size: [2.0, 0.36, 2.0], material: "structure", walkable: true },
      // 中层平台（升降台高停靠点与上层梯下端之间的固定平台，安全）。
      { id: "b_platform_landing", ownerId: "level", center: [0.85, 3.72, 1.75], size: [3.4, 0.36, 3.2], material: "stone_lit", walkable: true },
      // 高层孤台：近侧边缘落在投影接缝点 z=5.204，避免梯顶与落脚点藏进平台内部。
      { id: "b_platform_island", ownerId: "level", center: [4.7138, 8.3637, 6.404], size: [2.2, 0.36, 2.4], material: "stone_lit", walkable: true },
      // 出口横移台台面（0 档偏离孤台，末档接通孤台与消防门）。
      // 从右侧横向滑入：初始位完全让开上楼口，2 档回到 x=4.7138 接通高层孤台与出口。
      { id: "b_platform_exit_slide", ownerId: "b_exit_slide", center: [8.1138, 8.3637, 5.7], size: [2.0, 0.36, 2.6], material: "structure", walkable: true },
      // 最终消防门前平台。
      { id: "b_platform_exit", ownerId: "level", center: [4.7138, 8.3637, 7.9], size: [2.0, 0.36, 2.0], material: "stone_lit", walkable: true },
      // 背景山墙（-z 远端，不遮挡任何端点与接缝）。
      { id: "b_backdrop_wall", ownerId: "level", center: [1.0, 3.5, -5.8], size: [22, 9.0, 0.4], material: "wall_lit", walkable: false }
    ],
    stairs: [
      // 下层旋转梯（0 档沿 +x 上升）。
      { id: "b_lower_stair_span", ownerId: "b_lower_stair", from: [-2.15, 0.9, 1.35], to: [1.35, 2.7, 1.35], width: 1.34, steps: 12, material: "stone_lit" },
      // 上层旋转梯（0 档沿 φ=122° 方向上升）。
      { id: "b_upper_stair_span", ownerId: "b_upper_stair", from: [2.0, 3.9, 0.8], to: [0.3043, 5.6, 3.5138], width: 1.34, steps: 11, material: "stone_lit" }
    ],
    decorations: [
      { id: "b_deco_fire_door", kind: "fire_door", position: [4.7138, 8.5437, 8.75], rotationY: Math.PI },
      { id: "b_deco_floor_plate", kind: "floor_plate", position: [-3.5, 3.2, -5.58] },
      { id: "b_deco_lamp_1", kind: "wall_lamp", position: [0.5, 4.6, -5.58] },
      { id: "b_deco_lamp_2", kind: "wall_lamp", position: [5.5, 5.4, -5.58] },
      { id: "b_deco_window_1", kind: "window_frame", position: [-6.0, 2.6, -5.59] },
      { id: "b_deco_window_2", kind: "window_frame", position: [2.5, 5.8, -5.59] },
      { id: "b_deco_plant_1", kind: "potted_plant", position: [-6.9, 0.9, 2.6] },
      { id: "b_deco_plant_2", kind: "potted_plant", position: [2.3, 3.9, 3.1] }
    ]
  },
  feedback: {
    objective: "每升高一段都切换视角，让入口、两段梯段和出口逐层连续。",
    firstSeam: "这个视角下，两端连在一起。",
    blocked: "通路在这里中断。调整机关或切换视角。",
    wrongDirection: "端点位置接近，行进方向没有接上。"
  }
};

/** 按关卡 id 取关卡定义；未知 id 抛错（调用方只传 LevelId）。 */
export function getStairLevel(id: LevelId): StairLevelDefinition {
  if (id === "stair_a") return LEVEL_A;
  if (id === "stair_b") return LEVEL_B;
  throw new Error(`Unknown stair level "${id}".`);
}

// 类型自检：确保 perspectiveLinks 引用的 connector 分属同一 linkGroup（运行期校验由
// scripts/verify-chapter4-stair-levels.mjs 负责，这里只做数据形状提示）。
export const LEVEL_LINKS: Record<LevelId, readonly PerspectiveLinkDefinition[]> = {
  stair_a: LEVEL_A.perspectiveLinks,
  stair_b: LEVEL_B.perspectiveLinks
};
