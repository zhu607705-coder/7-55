import * as THREE from "three";

import {
  INTERNAL_HEIGHT,
  INTERNAL_WIDTH,
  PROJECTION_MAX_SCREEN_DISTANCE_PX,
  PROJECTION_TANGENT_MAX_DEGREES
} from "./types";
import type {
  CameraViewId,
  MechanismDefinition,
  MechanismRuntimeState,
  NavGraph,
  NavGraphEdge,
  NavGraphNode,
  PerspectiveSeam,
  StairLevelDefinition
} from "./types";

/**
 * 第四章楼梯间三视角空间解谜 —— 纯逻辑投影引擎（设计文档 §5）。
 * 本模块不依赖 DOM 与渲染代码，只使用 three 数学类与 types.ts 契约，
 * 供主 Demo、渲染层与 scripts/verify-chapter4-stair-engine.mjs 共用。
 */

/** 屏幕二维点/向量（内部 480×270 像素坐标）。 */
export interface ScreenPoint {
  x: number;
  y: number;
}

/** 端点在当前机关档位下的世界姿态（resolveConnectorWorld 的输出）。 */
export interface ConnectorWorldState {
  id: string;
  nodeId: string;
  ownerId: string;
  linkGroup: string;
  views: CameraViewId[];
  projectionMode: "physical" | "perspective";
  worldPosition: THREE.Vector3;
  worldTangent: THREE.Vector3;
}

/**
 * 遮挡测试回调：由调用方（渲染层）注入，from → to 射线被实心面挡住时返回 true。
 * 不注入时默认无遮挡。
 */
export type OcclusionTest = (from: THREE.Vector3, to: THREE.Vector3) => boolean;

/** 节点 → 屏幕坐标投影函数（由调用方按当前相机构造）。 */
export type NodeScreenProjector = (nodeId: string) => ScreenPoint;

/**
 * 投影接缝评估结果。
 * seams 为每个 linkGroup 保留的屏幕距离最小候选；其余通过全部判定但被同组
 * 更近候选挤掉的候选记录到 droppedCandidates（供调试快照，设计文档 §11）。
 * types.ts 的 PerspectiveSeam 无此聚合字段，故在本模块补充本地导出接口。
 */
export interface PerspectiveSeamEvaluation {
  seams: PerspectiveSeam[];
  droppedCandidates: PerspectiveSeam[];
}

/** rotate 机关每档固定 90°（types.ts：stepSize 对 rotate 无效）。 */
const ROTATE_STEP_RADIANS = Math.PI / 2;
/** 相向连接判定阈值：归一化点积 ≤ -cos(20°)。 */
const MIN_OPPOSING_TANGENT_DOT = -Math.cos((PROJECTION_TANGENT_MAX_DEGREES * Math.PI) / 180);
/** 投影后长度低于该值的切线/方向视为无法定义方向。 */
const SCREEN_DIRECTION_EPSILON = 1e-6;

/** 档位取模归一：values 缺省时回退 initialState，负数与超界均循环到合法档位。 */
function normalizeMechanismState(definition: MechanismDefinition, rawValue: number | undefined): number {
  const value = rawValue ?? definition.initialState;
  return ((value % definition.stateCount) + definition.stateCount) % definition.stateCount;
}

/**
 * 1) 机关运行态：每个机关输出当前档位与 0 档坐标 → 世界坐标的刚体矩阵。
 * rotate 绕 pivot 的 y 轴每档 90°，绕任意 pivot 的旋转 = T(pivot)·R·T(-pivot)；
 * vertical/horizontal 沿 axis 每档 stepSize 的纯平移（pivot 不影响平移矩阵）。
 */
export function buildMechanismRuntime(
  level: StairLevelDefinition,
  values: Record<string, number>
): MechanismRuntimeState[] {
  return level.mechanisms.map((definition) => {
    const state = normalizeMechanismState(definition, values[definition.id]);
    let matrix: THREE.Matrix4;
    if (definition.kind === "rotate") {
      const [px, py, pz] = [definition.pivot[0], definition.pivot[1], definition.pivot[2]];
      matrix = new THREE.Matrix4()
        .makeTranslation(px, py, pz)
        .multiply(new THREE.Matrix4().makeRotationY(state * ROTATE_STEP_RADIANS))
        .multiply(new THREE.Matrix4().makeTranslation(-px, -py, -pz));
    } else {
      const offset = { x: 0, y: 0, z: 0 };
      offset[definition.axis] = definition.stepSize * state;
      matrix = new THREE.Matrix4().makeTranslation(offset.x, offset.y, offset.z);
    }
    return { id: definition.id, state, matrix };
  });
}

/**
 * 2) 端点世界姿态：机关拥有的端点用其当前档位矩阵做刚体变换；
 * 切线只按方向变换（transformDirection，去除平移分量并保持归一化，刚体变换下无损失）。
 */
export function resolveConnectorWorld(
  level: StairLevelDefinition,
  runtime: readonly MechanismRuntimeState[]
): ReadonlyMap<string, ConnectorWorldState> {
  const runtimeById = new Map(runtime.map((entry) => [entry.id, entry]));
  const resolved = new Map<string, ConnectorWorldState>();
  for (const connector of level.connectors) {
    const worldPosition = connector.worldPosition.clone();
    const worldTangent = connector.worldTangent.clone();
    if (connector.ownerId !== "level") {
      const owner = runtimeById.get(connector.ownerId);
      if (!owner) {
        throw new Error(`Connector ${connector.id} references unknown mechanism "${connector.ownerId}".`);
      }
      worldPosition.applyMatrix4(owner.matrix);
      worldTangent.transformDirection(owner.matrix);
    }
    resolved.set(connector.id, {
      id: connector.id,
      nodeId: connector.nodeId,
      ownerId: connector.ownerId,
      linkGroup: connector.linkGroup,
      views: [...connector.views],
      projectionMode: connector.projectionMode,
      worldPosition,
      worldTangent
    });
  }
  return resolved;
}

/** 世界坐标 → 内部 480×270 像素屏幕坐标（y 轴翻转为屏幕向下）。 */
function projectToInternalScreen(world: THREE.Vector3, camera: THREE.OrthographicCamera): ScreenPoint {
  const ndc = world.clone().project(camera);
  return {
    x: (ndc.x * 0.5 + 0.5) * INTERNAL_WIDTH,
    y: (1 - (ndc.y * 0.5 + 0.5)) * INTERNAL_HEIGHT
  };
}

/** 世界切线 → 归一化屏幕方向；投影后长度为零（切线与视线平行）时返回 null。 */
function projectTangentToScreenDirection(
  worldPosition: THREE.Vector3,
  worldTangent: THREE.Vector3,
  camera: THREE.OrthographicCamera
): ScreenPoint | null {
  const base = projectToInternalScreen(worldPosition, camera);
  const tip = projectToInternalScreen(worldPosition.clone().add(worldTangent), camera);
  const dx = tip.x - base.x;
  const dy = tip.y - base.y;
  const length = Math.hypot(dx, dy);
  if (length < SCREEN_DIRECTION_EPSILON) return null;
  return { x: dx / length, y: dy / length };
}

/**
 * 3) 投影接缝评估（设计文档 §5.3）。只比较 perspectiveLinks 白名单内、
 * 同 linkGroup、双方都允许当前视角的端点对；屏幕距离 ≤6px 为候选；
 * 投影切线归一化点积 ≤ -cos(20°) 为 valid，否则保留为橙色虚线 invalid；
 * 注入的 occlude 对相机 → 任一端点返回 true 即丢弃该对。
 * 同一 linkGroup 出现多个候选时只保留屏幕距离最小的一组，其余进 droppedCandidates。
 */
export function evaluatePerspectiveSeams(
  level: StairLevelDefinition,
  camera: THREE.OrthographicCamera,
  view: CameraViewId,
  connectorWorld: ReadonlyMap<string, ConnectorWorldState>,
  occlude?: OcclusionTest
): PerspectiveSeamEvaluation {
  const connectorsById = new Map(level.connectors.map((connector) => [connector.id, connector]));
  const cameraPosition = new THREE.Vector3();
  camera.getWorldPosition(cameraPosition);
  const candidatesByGroup = new Map<string, PerspectiveSeam[]>();

  for (const link of level.perspectiveLinks) {
    const connectorA = connectorsById.get(link.connectorA);
    const connectorB = connectorsById.get(link.connectorB);
    if (!connectorA || !connectorB) {
      throw new Error(
        `PerspectiveLink ${link.id} references unknown connector "${link.connectorA}" / "${link.connectorB}".`
      );
    }
    // 白名单数据完整性：两端点必须与 link 同属一个 linkGroup，否则不参与比较。
    if (
      connectorA.linkGroup !== link.linkGroup ||
      connectorB.linkGroup !== link.linkGroup ||
      connectorA.linkGroup !== connectorB.linkGroup
    ) {
      continue;
    }
    if (!connectorA.views.includes(view) || !connectorB.views.includes(view)) {
      continue;
    }
    const worldA = connectorWorld.get(link.connectorA);
    const worldB = connectorWorld.get(link.connectorB);
    if (!worldA || !worldB) {
      throw new Error(`PerspectiveLink ${link.id} is missing resolved world state.`);
    }

    const screenA = projectToInternalScreen(worldA.worldPosition, camera);
    const screenB = projectToInternalScreen(worldB.worldPosition, camera);
    const screenDistancePx = Math.hypot(screenA.x - screenB.x, screenA.y - screenB.y);
    if (screenDistancePx > PROJECTION_MAX_SCREEN_DISTANCE_PX) {
      continue;
    }
    if (
      occlude &&
      (occlude(cameraPosition, worldA.worldPosition) || occlude(cameraPosition, worldB.worldPosition))
    ) {
      continue;
    }

    const directionA = projectTangentToScreenDirection(worldA.worldPosition, worldA.worldTangent, camera);
    const directionB = projectTangentToScreenDirection(worldB.worldPosition, worldB.worldTangent, camera);
    let valid = false;
    if (directionA && directionB) {
      const dot = directionA.x * directionB.x + directionA.y * directionB.y;
      valid = dot <= MIN_OPPOSING_TANGENT_DOT;
    }
    const seam: PerspectiveSeam = {
      id: link.id,
      linkId: link.id,
      linkGroup: link.linkGroup,
      connectorA: link.connectorA,
      connectorB: link.connectorB,
      nodeA: connectorA.nodeId,
      nodeB: connectorB.nodeId,
      screenDistancePx,
      valid
    };
    const group = candidatesByGroup.get(link.linkGroup);
    if (group) {
      group.push(seam);
    } else {
      candidatesByGroup.set(link.linkGroup, [seam]);
    }
  }

  const seams: PerspectiveSeam[] = [];
  const droppedCandidates: PerspectiveSeam[] = [];
  for (const candidates of candidatesByGroup.values()) {
    // 距离升序、id 字典序兜底，保证同一状态下结果确定。
    candidates.sort(
      (a, b) => a.screenDistancePx - b.screenDistancePx || a.id.localeCompare(b.id)
    );
    seams.push(candidates[0]);
    for (let index = 1; index < candidates.length; index += 1) {
      droppedCandidates.push(candidates[index]);
    }
  }
  return { seams, droppedCandidates };
}

/**
 * 4) 导航图：physical 边 + 当前档位生效的 mechanismEdges + valid 投影边。
 * 节点坐标为机关刚体变换后的世界坐标。
 */
export function buildNavGraph(
  level: StairLevelDefinition,
  values: Record<string, number>,
  seams: readonly PerspectiveSeam[]
): NavGraph {
  const runtime = buildMechanismRuntime(level, values);
  const runtimeById = new Map(runtime.map((entry) => [entry.id, entry]));
  const stateById = new Map(runtime.map((entry) => [entry.id, entry.state]));

  const nodes = new Map<string, NavGraphNode>();
  for (const definition of level.nodes) {
    const position = new THREE.Vector3(definition.position[0], definition.position[1], definition.position[2]);
    if (definition.ownerId !== "level") {
      const owner = runtimeById.get(definition.ownerId);
      if (!owner) {
        throw new Error(`NavNode ${definition.id} references unknown mechanism "${definition.ownerId}".`);
      }
      position.applyMatrix4(owner.matrix);
    }
    nodes.set(definition.id, { id: definition.id, safe: definition.safe, position });
  }

  const edges: NavGraphEdge[] = [];
  for (const edge of level.physicalEdges) {
    edges.push({ id: edge.id, a: edge.a, b: edge.b, kind: "physical" });
  }
  for (const edge of level.mechanismEdges) {
    const state = stateById.get(edge.mechanismId);
    if (state === undefined) {
      throw new Error(`MechanismEdge ${edge.id} references unknown mechanism "${edge.mechanismId}".`);
    }
    if (state === edge.requiredState) {
      edges.push({ id: edge.id, a: edge.a, b: edge.b, kind: "mechanism" });
    }
  }
  for (const seam of seams) {
    if (seam.valid) {
      edges.push({ id: seam.id, a: seam.nodeA, b: seam.nodeB, kind: "perspective" });
    }
  }

  for (const edge of edges) {
    if (!nodes.has(edge.a) || !nodes.has(edge.b)) {
      throw new Error(`NavEdge ${edge.id} (${edge.kind}) references unknown node "${edge.a}" -> "${edge.b}".`);
    }
  }
  const adjacency = new Map<string, string[]>();
  for (const id of nodes.keys()) {
    adjacency.set(id, []);
  }
  for (const edge of edges) {
    adjacency.get(edge.a)!.push(edge.b);
    adjacency.get(edge.b)!.push(edge.a);
  }
  return { nodes, edges, adjacency };
}

/** 5) BFS 最短路（边等权），返回含起终点在内的节点 id 序列，不可达返回 null。 */
export function findPath(graph: NavGraph, fromId: string, toId: string): string[] | null {
  if (!graph.nodes.has(fromId) || !graph.nodes.has(toId)) return null;
  if (fromId === toId) return [fromId];
  const previous = new Map<string, string>();
  const visited = new Set<string>([fromId]);
  const queue: string[] = [fromId];
  while (queue.length > 0) {
    const current = queue.shift()!;
    for (const next of graph.adjacency.get(current) ?? []) {
      if (visited.has(next)) continue;
      visited.add(next);
      previous.set(next, current);
      if (next === toId) {
        const path = [toId];
        let cursor = toId;
        while (cursor !== fromId) {
          cursor = previous.get(cursor)!;
          path.unshift(cursor);
        }
        return path;
      }
      queue.push(next);
    }
  }
  return null;
}

/**
 * 方向输入选邻居。有效投影接缝在屏幕上近乎重合，直接使用亚像素 dx/dy 会让
 * “向上”随机失效或反转。投影边保留作者声明的 a → b 上行方向：↑ 优先 a → b，
 * ↓ 优先 b → a；其余方向与普通物理边继续按屏幕方向选择。
 */
export function selectDirectionalNeighbor(
  graph: NavGraph,
  fromId: string,
  direction: ScreenPoint,
  projectNode: NodeScreenProjector
): string | null {
  if (!graph.nodes.has(fromId)) {
    throw new Error(`selectDirectionalNeighbor received unknown node "${fromId}".`);
  }
  const verticalIntent = Math.abs(direction.y) >= Math.abs(direction.x) && Math.abs(direction.y) > 0;
  if (verticalIntent) {
    const forward = direction.y < 0;
    const perspectiveTarget = graph.edges.find((edge) => {
      if (edge.kind !== "perspective") return false;
      return forward ? edge.a === fromId : edge.b === fromId;
    });
    if (perspectiveTarget) {
      return forward ? perspectiveTarget.b : perspectiveTarget.a;
    }
  }

  const neighbors = graph.adjacency.get(fromId) ?? [];
  const perspectiveNeighbors = verticalIntent
    ? new Set(graph.edges.flatMap((edge) => {
        if (edge.kind !== "perspective") return [];
        if (edge.a === fromId) return [edge.b];
        if (edge.b === fromId) return [edge.a];
        return [];
      }))
    : new Set<string>();
  const origin = projectNode(fromId);
  const directionLength = Math.hypot(direction.x, direction.y);
  if (directionLength < SCREEN_DIRECTION_EPSILON) return null;
  let best: string | null = null;
  let bestAlignment = 0.25;
  for (const neighbor of neighbors) {
    if (perspectiveNeighbors.has(neighbor)) continue;
    const point = projectNode(neighbor);
    const dx = point.x - origin.x;
    const dy = point.y - origin.y;
    const length = Math.hypot(dx, dy);
    if (length < SCREEN_DIRECTION_EPSILON) continue;
    const alignment = (dx * direction.x + dy * direction.y) / (length * directionLength);
    if (alignment > bestAlignment) {
      bestAlignment = alignment;
      best = neighbor;
    }
  }
  return best;
}

/**
 * 6) 断口边缘节点：在 fromId 所在连通分量内，先取度数最小的节点作为边界节点
 * （断口/死角通常度数最小），再从中选屏幕方向与 targetScreenDir 夹角最小者。
 * targetScreenDir 为零向量时退化为取屏幕距离最近的边界节点；
 * 与玩家屏幕位置重合（无法定义方向）的候选跳过。孤立节点直接返回自身。
 */
export function nearestBoundaryNode(
  graph: NavGraph,
  fromId: string,
  targetScreenDir: ScreenPoint,
  projectNode: NodeScreenProjector
): string {
  if (!graph.nodes.has(fromId)) {
    throw new Error(`nearestBoundaryNode received unknown node "${fromId}".`);
  }
  // BFS 收集 fromId 的连通分量（按发现顺序，保证确定性）。
  const component: string[] = [];
  const visited = new Set<string>([fromId]);
  const queue: string[] = [fromId];
  while (queue.length > 0) {
    const current = queue.shift()!;
    component.push(current);
    for (const next of graph.adjacency.get(current) ?? []) {
      if (visited.has(next)) continue;
      visited.add(next);
      queue.push(next);
    }
  }
  const candidates = component.filter((id) => id !== fromId);
  if (candidates.length === 0) return fromId;

  const degreeOf = (id: string): number => graph.adjacency.get(id)?.length ?? 0;
  const minDegree = Math.min(...candidates.map(degreeOf));
  const boundary = candidates.filter((id) => degreeOf(id) === minDegree);

  const origin = projectNode(fromId);
  const targetLength = Math.hypot(targetScreenDir.x, targetScreenDir.y);
  let bestId: string | null = null;
  let bestAlignment = -Infinity;
  let bestDistance = Infinity;
  for (const id of boundary) {
    const point = projectNode(id);
    const dx = point.x - origin.x;
    const dy = point.y - origin.y;
    const distance = Math.hypot(dx, dy);
    let alignment: number;
    if (targetLength < SCREEN_DIRECTION_EPSILON) {
      alignment = 0; // 无方向偏好：全部由距离与 id 决定
    } else if (distance < SCREEN_DIRECTION_EPSILON) {
      continue;
    } else {
      alignment = (dx * targetScreenDir.x + dy * targetScreenDir.y) / (distance * targetLength);
    }
    const betterAlignment = alignment > bestAlignment + 1e-9;
    const sameAlignment = Math.abs(alignment - bestAlignment) <= 1e-9;
    if (
      bestId === null ||
      betterAlignment ||
      (sameAlignment && distance < bestDistance - 1e-9) ||
      (sameAlignment && Math.abs(distance - bestDistance) <= 1e-9 && id < bestId)
    ) {
      bestId = id;
      bestAlignment = alignment;
      bestDistance = distance;
    }
  }
  // 极端情况：所有边界候选都与玩家屏幕位置重合，退回字典序最小者保证确定性。
  if (bestId === null) {
    bestId = [...boundary].sort()[0];
  }
  return bestId;
}

/** 7) 机关步进：返回取模循环后的新 values，纯函数，不改入参。 */
export function stepMechanism(
  level: StairLevelDefinition,
  values: Record<string, number>,
  mechanismId: string,
  delta: -1 | 1
): Record<string, number> {
  const definition = level.mechanisms.find((mechanism) => mechanism.id === mechanismId);
  if (!definition) {
    throw new Error(`Unknown mechanism "${mechanismId}".`);
  }
  const current = normalizeMechanismState(definition, values[mechanismId]);
  const next = (current + delta + definition.stateCount) % definition.stateCount;
  return { ...values, [mechanismId]: next };
}

/** 8) 节点世界坐标：含所属机关在当前档位下的刚体变换。 */
export function nodeWorldPosition(
  level: StairLevelDefinition,
  values: Record<string, number>,
  nodeId: string
): THREE.Vector3 {
  const definition = level.nodes.find((node) => node.id === nodeId);
  if (!definition) {
    throw new Error(`Unknown nav node "${nodeId}".`);
  }
  const position = new THREE.Vector3(definition.position[0], definition.position[1], definition.position[2]);
  if (definition.ownerId === "level") {
    return position;
  }
  const runtime = buildMechanismRuntime(level, values).find((entry) => entry.id === definition.ownerId);
  if (!runtime) {
    throw new Error(`NavNode ${nodeId} references unknown mechanism "${definition.ownerId}".`);
  }
  return position.applyMatrix4(runtime.matrix);
}
