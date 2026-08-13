#!/usr/bin/env node
/**
 * 第四章楼梯间三视角空间解谜 —— 关卡数据永久校验脚本。
 * 只 import src/tools/chapter4-stair/levels.ts 与 three，node 直接运行：
 *   node scripts/verify-chapter4-stair-levels.mjs
 *
 * 断言内容（设计文档 §5.3 / §6 / §7，共享契约 types.ts）：
 *  1. 引用完整性：edge 端点、connector.nodeId/ownerId、link 配对、mechanismEdge 引用、geometry owner。
 *  2. 节点覆盖：全部节点被物理 / 机关 / 投影边连通关系覆盖，无孤立节点。
 *  3. 关键接缝成立：A（西南 + 中央梯 0 档）、B 下层（西南 + 下层梯 3 档 + 升降台 0 档）、
 *     B 上层（上方 + 上层梯 1 档）—— 屏幕距离 ≤6px 且切线点积 ≤ -cos(20°)。
 *  4. B 错误重合（东南 + 上层梯 3 档）：距离 ≤6px 但切线同向（点积 > 0，橙色虚线）。
 *  5. 非关键视角 / 档位不出现意外有效接缝；错误重合只出现安排的一次。
 *  6. 初始状态（两关各自 initialState）下任何视角都没有有效接缝，且起点到出口不可达。
 *  7. 解题状态下（物理 + 机关边 + 关键视角投影边）起点到出口连通。
 *  8. 白名单外（跨 linkGroup）的端点组合在任何视角 / 档位下都不产生候选（距离 ≤6px）。
 */
import * as THREE from "three";

import {
  LEVEL_A,
  LEVEL_B,
  LEVEL_CAMERAS,
  getStairLevel
} from "../src/tools/chapter4-stair/levels.ts";

const INTERNAL_WIDTH = 480;
const INTERNAL_HEIGHT = 270;
const MAX_DIST_PX = 6;
const MIN_OPPOSING_DOT = -Math.cos((20 * Math.PI) / 180);
const VIEW_IDS = ["south_east", "south_west", "top_oblique"];
const ROTATE_STEP = Math.PI / 2;

const failures = [];
const notes = [];
function assert(condition, message) {
  if (condition) {
    notes.push(`PASS  ${message}`);
  } else {
    failures.push(message);
    notes.push(`FAIL  ${message}`);
  }
}

/* ---------------------------- 投影与变换工具 ---------------------------- */

const cameraCache = new Map();
function buildCamera(levelId, viewId) {
  const key = `${levelId}:${viewId}`;
  if (cameraCache.has(key)) return cameraCache.get(key);
  const spec = LEVEL_CAMERAS[levelId];
  const view = spec.views[viewId];
  const camera = new THREE.OrthographicCamera(
    -spec.halfWidth,
    spec.halfWidth,
    spec.halfHeight,
    -spec.halfHeight,
    spec.near,
    spec.far
  );
  camera.position.set(...view.position);
  camera.lookAt(new THREE.Vector3(...spec.center));
  camera.updateMatrixWorld(true);
  camera.updateProjectionMatrix();
  cameraCache.set(key, camera);
  return camera;
}

function projectToScreen(world, camera) {
  const ndc = world.clone().project(camera);
  return {
    x: (ndc.x * 0.5 + 0.5) * INTERNAL_WIDTH,
    y: (1 - (ndc.y * 0.5 + 0.5)) * INTERNAL_HEIGHT
  };
}

function mechanismMatrix(definition, state) {
  if (definition.kind === "rotate") {
    const [px, py, pz] = definition.pivot;
    return new THREE.Matrix4()
      .makeTranslation(px, py, pz)
      .multiply(new THREE.Matrix4().makeRotationY(state * ROTATE_STEP))
      .multiply(new THREE.Matrix4().makeTranslation(-px, -py, -pz));
  }
  const offset = { x: 0, y: 0, z: 0 };
  offset[definition.axis] = definition.stepSize * state;
  return new THREE.Matrix4().makeTranslation(offset.x, offset.y, offset.z);
}

/** 计算全部端点在给定档位组合下的世界位置 / 世界切线。 */
function resolveConnectors(level, values) {
  const resolved = new Map();
  for (const connector of level.connectors) {
    const position = connector.worldPosition.clone();
    const tangent = connector.worldTangent.clone();
    if (connector.ownerId !== "level") {
      const definition = level.mechanisms.find((m) => m.id === connector.ownerId);
      const matrix = mechanismMatrix(definition, values[definition.id]);
      position.applyMatrix4(matrix);
      tangent.transformDirection(matrix);
    }
    resolved.set(connector.id, { connector, position, tangent });
  }
  return resolved;
}

/** 评估一对端点：屏幕距离（px）与投影切线归一化点积。 */
function evaluatePair(levelId, viewId, worldA, worldB) {
  const camera = buildCamera(levelId, viewId);
  const screenA = projectToScreen(worldA.position, camera);
  const screenB = projectToScreen(worldB.position, camera);
  const dist = Math.hypot(screenA.x - screenB.x, screenA.y - screenB.y);
  const dirA = screenDirection(worldA, camera);
  const dirB = screenDirection(worldB, camera);
  const dot = dirA && dirB ? dirA.x * dirB.x + dirA.y * dirB.y : null;
  return { dist, dot };
}

function screenDirection(world, camera) {
  const base = projectToScreen(world.position, camera);
  const tip = projectToScreen(world.position.clone().add(world.tangent), camera);
  const dx = tip.x - base.x;
  const dy = tip.y - base.y;
  const length = Math.hypot(dx, dy);
  if (length < 1e-6) return null;
  return { x: dx / length, y: dy / length };
}

function projectedPlatformClearance(level, clearance) {
  const node = level.nodes.find((entry) => entry.id === clearance.nodeId);
  const platform = level.geometry.platforms.find((entry) => entry.id === clearance.platformId);
  if (!node || !platform) return Infinity;
  const camera = buildCamera(level.id, clearance.viewId);
  const nodeOwner = node.ownerId === "level"
    ? new THREE.Matrix4()
    : mechanismMatrix(
        level.mechanisms.find((entry) => entry.id === node.ownerId),
        clearance.mechanismValues[node.ownerId]
      );
  const nodeScreen = projectToScreen(new THREE.Vector3(...node.position).applyMatrix4(nodeOwner), camera);
  const platformOwner = platform.ownerId === "level"
    ? new THREE.Matrix4()
    : mechanismMatrix(
        level.mechanisms.find((entry) => entry.id === platform.ownerId),
        clearance.mechanismValues[platform.ownerId]
      );
  const half = platform.size.map((value) => value / 2);
  const projectedCorners = [];
  for (const dx of [-half[0], half[0]]) {
    for (const dy of [-half[1], half[1]]) {
      for (const dz of [-half[2], half[2]]) {
        projectedCorners.push(
          projectToScreen(
            new THREE.Vector3(
              platform.center[0] + dx,
              platform.center[1] + dy,
              platform.center[2] + dz
            ).applyMatrix4(platformOwner),
            camera
          )
        );
      }
    }
  }
  const minX = Math.min(...projectedCorners.map((point) => point.x));
  const maxX = Math.max(...projectedCorners.map((point) => point.x));
  const minY = Math.min(...projectedCorners.map((point) => point.y));
  const maxY = Math.max(...projectedCorners.map((point) => point.y));
  const gapX = nodeScreen.x < minX ? minX - nodeScreen.x : nodeScreen.x > maxX ? nodeScreen.x - maxX : 0;
  const gapY = nodeScreen.y < minY ? minY - nodeScreen.y : nodeScreen.y > maxY ? nodeScreen.y - maxY : 0;
  return Math.hypot(gapX, gapY);
}

/** 枚举一关的全部机关档位组合。 */
function enumerateStateCombos(level) {
  const combos = [{}];
  for (const mechanism of level.mechanisms) {
    const next = [];
    for (const combo of combos) {
      for (let state = 0; state < mechanism.stateCount; state += 1) {
        next.push({ ...combo, [mechanism.id]: state });
      }
    }
    combos.length = 0;
    combos.push(...next);
  }
  return combos;
}

const fmtValues = (values) =>
  Object.entries(values)
    .map(([id, state]) => `${id}=${state}`)
    .join(",");

/* ------------------------------ 全量扫描 ------------------------------ */

/**
 * 扫描一关在（3 视角 × 全部档位组合）下的全部同组端点对：
 * 返回每对白名单 link 的候选（距离 ≤6px）记录，以及跨组距离 ≤6px 的意外重合。
 */
function scanLevel(level) {
  const linkRecords = new Map(level.perspectiveLinks.map((link) => [link.id, []]));
  const crossGroupNear = [];
  for (const viewId of VIEW_IDS) {
    for (const values of enumerateStateCombos(level)) {
      const resolved = resolveConnectors(level, values);
      // 白名单配对
      for (const link of level.perspectiveLinks) {
        const worldA = resolved.get(link.connectorA);
        const worldB = resolved.get(link.connectorB);
        const { dist, dot } = evaluatePair(level.id, viewId, worldA, worldB);
        if (dist <= MAX_DIST_PX) {
          linkRecords.get(link.id).push({ viewId, values, dist, dot });
        }
      }
      // 跨 linkGroup 配对（引擎规则不允许成边，此处断言连候选都不出现）
      const entries = [...resolved.values()];
      for (let i = 0; i < entries.length; i += 1) {
        for (let j = i + 1; j < entries.length; j += 1) {
          const a = entries[i];
          const b = entries[j];
          if (a.connector.linkGroup === b.connector.linkGroup) continue;
          const { dist } = evaluatePair(level.id, viewId, a, b);
          if (dist <= MAX_DIST_PX) {
            crossGroupNear.push({ viewId, values, a: a.connector.id, b: b.connector.id, dist });
          }
        }
      }
    }
  }
  return { linkRecords, crossGroupNear };
}

/** 判断一组候选记录是否落在期望的（视角 + 档位约束）内。 */
function matches(record, viewId, constraints) {
  if (record.viewId !== viewId) return false;
  return Object.entries(constraints).every(([id, state]) => record.values[id] === state);
}

/* ------------------------------ 单关校验 ------------------------------ */

function verifyLevel(level, expectations) {
  console.log(`\n=== ${level.id} «${level.title}» ===`);
  const mechanismIds = new Set(level.mechanisms.map((m) => m.id));
  const nodeIds = new Set(level.nodes.map((n) => n.id));
  const connectorIds = new Set(level.connectors.map((c) => c.id));

  // 1) 引用完整性
  assert(nodeIds.has(level.startNodeId), `${level.id}: startNodeId ${level.startNodeId} 存在`);
  assert(nodeIds.has(level.exitNodeId), `${level.id}: exitNodeId ${level.exitNodeId} 存在`);
  for (const node of level.nodes) {
    assert(
      node.ownerId === "level" || mechanismIds.has(node.ownerId),
      `${level.id}: 节点 ${node.id} ownerId=${node.ownerId} 可解析`
    );
  }
  for (const edge of [...level.physicalEdges, ...level.mechanismEdges]) {
    assert(nodeIds.has(edge.a) && nodeIds.has(edge.b), `${level.id}: 边 ${edge.id} 端点存在`);
  }
  for (const edge of level.mechanismEdges) {
    const definition = level.mechanisms.find((m) => m.id === edge.mechanismId);
    assert(Boolean(definition), `${level.id}: 机关边 ${edge.id} 引用的机关 ${edge.mechanismId} 存在`);
    if (definition) {
      assert(
        edge.requiredState >= 0 && edge.requiredState < definition.stateCount,
        `${level.id}: 机关边 ${edge.id} requiredState=${edge.requiredState} 在档位范围内`
      );
    }
  }
  for (const mechanism of level.mechanisms) {
    assert(
      mechanism.initialState >= 0 && mechanism.initialState < mechanism.stateCount,
      `${level.id}: 机关 ${mechanism.id} initialState 合法`
    );
  }
  const linkGroups = new Map();
  for (const connector of level.connectors) {
    assert(nodeIds.has(connector.nodeId), `${level.id}: 端点 ${connector.id} 的 nodeId 存在`);
    assert(
      connector.ownerId === "level" || mechanismIds.has(connector.ownerId),
      `${level.id}: 端点 ${connector.id} ownerId 可解析`
    );
    assert(
      Math.abs(connector.worldTangent.length() - 1) < 1e-3,
      `${level.id}: 端点 ${connector.id} 切线已归一化`
    );
    const list = linkGroups.get(connector.linkGroup) ?? [];
    list.push(connector.id);
    linkGroups.set(connector.linkGroup, list);
  }
  for (const link of level.perspectiveLinks) {
    assert(
      connectorIds.has(link.connectorA) && connectorIds.has(link.connectorB),
      `${level.id}: 白名单 ${link.id} 引用的端点存在`
    );
    const group = linkGroups.get(link.linkGroup) ?? [];
    assert(
      group.length === 2 && group.includes(link.connectorA) && group.includes(link.connectorB),
      `${level.id}: linkGroup ${link.linkGroup} 恰好由白名单 ${link.id} 的两个端点组成`
    );
  }
  assert(
    level.ascentViewSequence.length === expectations.solutionSeams.length
      && level.ascentViewSequence.every((viewId, index) => viewId === expectations.solutionSeams[index]?.viewId),
    `${level.id}: 上行视角顺序与解题接缝一致（${level.ascentViewSequence.join(" → ")}）`
  );
  assert(
    level.ascentViewSequence.every((viewId, index, views) => index === 0 || viewId !== views[index - 1]),
    `${level.id}: 连续上行接缝不重复使用同一视角`
  );
  for (const spec of [...level.geometry.platforms, ...level.geometry.stairs]) {
    assert(
      spec.ownerId === "level" || mechanismIds.has(spec.ownerId),
      `${level.id}: 几何 ${spec.id} ownerId 可解析`
    );
  }
  for (const landing of expectations.visibleLandingEdges ?? []) {
    const node = level.nodes.find((entry) => entry.id === landing.nodeId);
    const platform = level.geometry.platforms.find((entry) => entry.id === landing.platformId);
    const topError = node && platform
      ? Math.abs(node.position[1] - (platform.center[1] + platform.size[1] / 2))
      : Infinity;
    const horizontalEdgeError = node && platform
      ? Math.min(
          Math.abs(node.position[0] - (platform.center[0] - platform.size[0] / 2)),
          Math.abs(node.position[0] - (platform.center[0] + platform.size[0] / 2)),
          Math.abs(node.position[2] - (platform.center[2] - platform.size[2] / 2)),
          Math.abs(node.position[2] - (platform.center[2] + platform.size[2] / 2))
        )
      : Infinity;
    assert(
      Boolean(node && platform) && topError <= 0.001,
      `${level.id}: ${landing.label} 落点位于平台顶面（误差 ${topError.toFixed(3)}）`
    );
    assert(
      Boolean(node && platform) && horizontalEdgeError <= 0.05,
      `${level.id}: ${landing.label} 落点位于可见平台边缘（误差 ${horizontalEdgeError.toFixed(3)}）`
    );
  }
  for (const clearance of expectations.inactivePlatformScreenClearances ?? []) {
    const screenClearance = projectedPlatformClearance(level, clearance);
    assert(
      screenClearance >= clearance.minDistancePx,
      `${level.id}: ${clearance.label}（净空 ${screenClearance.toFixed(2)}px，要求 ≥${clearance.minDistancePx}px）`
    );
  }
  for (const docking of expectations.mechanismDockings ?? []) {
    const platform = level.geometry.platforms.find((entry) => entry.id === docking.platformId);
    const mechanism = level.mechanisms.find((entry) => entry.id === platform?.ownerId);
    const worldCenter = platform && mechanism
      ? new THREE.Vector3(...platform.center).applyMatrix4(mechanismMatrix(mechanism, docking.state))
      : null;
    const error = worldCenter ? worldCenter.distanceTo(new THREE.Vector3(...docking.expectedCenter)) : Infinity;
    assert(
      Boolean(platform && mechanism) && error <= 0.001,
      `${level.id}: ${docking.label}（停靠误差 ${error.toFixed(3)}）`
    );
  }

  // 2) 节点覆盖：每个节点至少被一条边或一个端点触达
  const covered = new Set();
  for (const edge of [...level.physicalEdges, ...level.mechanismEdges]) {
    covered.add(edge.a);
    covered.add(edge.b);
  }
  for (const connector of level.connectors) covered.add(connector.nodeId);
  for (const node of level.nodes) {
    assert(covered.has(node.id), `${level.id}: 节点 ${node.id} 被边 / 端点覆盖`);
  }

  // 3) 全量投影扫描
  const { linkRecords, crossGroupNear } = scanLevel(level);

  // 3a) 关键接缝：期望组合内每次评估都必须成立（距离 ≤6px 且点积 ≤ -cos20°）
  for (const expected of expectations.validSeams) {
    const records = linkRecords.get(expected.linkId) ?? [];
    const hits = records.filter((r) => matches(r, expected.viewId, expected.constraints));
    // 命中次数 = 不受约束机关的档位组合数
    const unconstrained = level.mechanisms.filter((m) => !(m.id in expected.constraints));
    const expectedHits = unconstrained.reduce((acc, m) => acc * m.stateCount, 1);
    assert(
      hits.length === expectedHits,
      `${level.id}: ${expected.label} 在期望视角 / 档位成立（命中 ${hits.length}/${expectedHits} 组）`
    );
    const worst = hits.reduce(
      (acc, r) => ({
        dist: Math.max(acc.dist, r.dist),
        dot: Math.min(acc.dot, r.dot ?? 1)
      }),
      { dist: 0, dot: 1 }
    );
    assert(
      hits.every((r) => r.dot !== null && r.dot <= MIN_OPPOSING_DOT),
      `${level.id}: ${expected.label} 切线相向（最差距离 ${worst.dist.toFixed(2)}px，点积 ${worst.dot.toFixed(3)}）`
    );
    console.log(
      `  [关键接缝] ${expected.label}: 最差距离 ${worst.dist.toFixed(2)}px / 最差点积 ${worst.dot.toFixed(3)}`
    );
  }

  // 3b) 错误重合（橙色虚线）：距离 ≤6px、点积 > 0，且只出现在期望组合
  for (const expected of expectations.invalidSeams ?? []) {
    const records = linkRecords.get(expected.linkId) ?? [];
    const oranges = records.filter((r) => r.dot !== null && r.dot > MIN_OPPOSING_DOT);
    const expectedHits = level.mechanisms
      .filter((m) => !(m.id in expected.constraints))
      .reduce((acc, m) => acc * m.stateCount, 1);
    assert(
      oranges.length === expectedHits &&
        oranges.every((r) => matches(r, expected.viewId, expected.constraints)),
      `${level.id}: ${expected.label} 只出现在期望组合（橙色记录 ${oranges.length}/${expectedHits} 组）`
    );
    assert(
      oranges.every((r) => r.dot > 0),
      `${level.id}: ${expected.label} 切线同向（点积为正）`
    );
    if (oranges.length > 0) {
      const worstDist = Math.max(...oranges.map((r) => r.dist));
      const minDot = Math.min(...oranges.map((r) => r.dot));
      console.log(
        `  [错误重合] ${expected.label}: 最差距离 ${worstDist.toFixed(2)}px / 最小点积 ${minDot.toFixed(3)}`
      );
    }
  }

  // 3c) 非关键视角 / 档位不得出现意外有效接缝
  for (const link of level.perspectiveLinks) {
    const records = linkRecords.get(link.id) ?? [];
    const valids = records.filter((r) => r.dot !== null && r.dot <= MIN_OPPOSING_DOT);
    const unexpected = valids.filter(
      (r) =>
        !expectations.validSeams.some(
          (expected) => expected.linkId === link.id && matches(r, expected.viewId, expected.constraints)
        )
    );
    assert(
      unexpected.length === 0,
      `${level.id}: 白名单 ${link.id} 无非预期有效接缝（意外 ${unexpected.length} 组）`
    );
    if (unexpected.length > 0) {
      for (const r of unexpected.slice(0, 5)) {
        console.log(`    意外有效: view=${r.viewId} ${fmtValues(r.values)} dist=${r.dist.toFixed(2)} dot=${r.dot?.toFixed(3)}`);
      }
    }
  }

  // 3d) 白名单外（跨组）端点组合不产生候选
  assert(
    crossGroupNear.length === 0,
    `${level.id}: 跨 linkGroup 端点组合无 ≤6px 重合（发现 ${crossGroupNear.length} 组）`
  );
  if (crossGroupNear.length > 0) {
    for (const r of crossGroupNear.slice(0, 5)) {
      console.log(`    跨组重合: view=${r.viewId} ${r.a} ↔ ${r.b} dist=${r.dist.toFixed(2)} ${fmtValues(r.values)}`);
    }
  }

  // 4) 初始状态：任何视角无有效接缝，起点不可达出口
  const initialValues = Object.fromEntries(level.mechanisms.map((m) => [m.id, m.initialState]));
  const initialResolved = resolveConnectors(level, initialValues);
  let initialValid = 0;
  for (const viewId of VIEW_IDS) {
    for (const link of level.perspectiveLinks) {
      const { dist, dot } = evaluatePair(
        level.id,
        viewId,
        initialResolved.get(link.connectorA),
        initialResolved.get(link.connectorB)
      );
      if (dist <= MAX_DIST_PX && dot !== null && dot <= MIN_OPPOSING_DOT) initialValid += 1;
    }
  }
  assert(initialValid === 0, `${level.id}: 初始状态无有效接缝（发现 ${initialValid} 组）`);
  assert(
    !isConnected(level, initialValues, []),
    `${level.id}: 初始状态下 ${level.startNodeId} → ${level.exitNodeId} 不可达`
  );

  // 5) 解题状态：物理 + 机关边 + 关键视角投影边连通起点与出口。
  // 每条投影接缝按其跨越时刻的档位（seam.values）评估：例如 B 第一条接缝在
  // 升降台 0 档时跨越，随后人物才随台升至高档（设计文档 §7.4）。
  const seamEdges = expectations.solutionSeams.map((seam) => {
    const link = level.perspectiveLinks.find((l) => l.id === seam.linkId);
    const crossValues = { ...expectations.solutionValues, ...(seam.values ?? {}) };
    const resolved = resolveConnectors(level, crossValues);
    const { dist, dot } = evaluatePair(
      level.id,
      seam.viewId,
      resolved.get(link.connectorA),
      resolved.get(link.connectorB)
    );
    assert(
      dist <= MAX_DIST_PX && dot !== null && dot <= MIN_OPPOSING_DOT,
      `${level.id}: 解题链 ${seam.label} 在 ${seam.viewId}（跨越档位 ${fmtValues(crossValues)}）成立（${dist.toFixed(2)}px，点积 ${dot?.toFixed(3)}）`
    );
    return { a: nodeOf(level, link.connectorA), b: nodeOf(level, link.connectorB) };
  });
  assert(
    isConnected(level, expectations.solutionValues, seamEdges),
    `${level.id}: 解题状态下 ${level.startNodeId} → ${level.exitNodeId} 连通`
  );
}

function nodeOf(level, connectorId) {
  return level.connectors.find((c) => c.id === connectorId).nodeId;
}

/** 物理边 + 当前档位机关边 + 给定投影边下的 BFS 连通判定。 */
function isConnected(level, values, extraEdges) {
  const adjacency = new Map(level.nodes.map((n) => [n.id, []]));
  const addEdge = (a, b) => {
    adjacency.get(a)?.push(b);
    adjacency.get(b)?.push(a);
  };
  for (const edge of level.physicalEdges) addEdge(edge.a, edge.b);
  for (const edge of level.mechanismEdges) {
    if (values[edge.mechanismId] === edge.requiredState) addEdge(edge.a, edge.b);
  }
  for (const edge of extraEdges) addEdge(edge.a, edge.b);
  const visited = new Set([level.startNodeId]);
  const queue = [level.startNodeId];
  while (queue.length > 0) {
    const current = queue.shift();
    for (const next of adjacency.get(current) ?? []) {
      if (visited.has(next)) continue;
      visited.add(next);
      queue.push(next);
    }
  }
  return visited.has(level.exitNodeId);
}

/* -------------------------------- 执行 -------------------------------- */

verifyLevel(LEVEL_A, {
  validSeams: [
    {
      linkId: "a_link_stair_island",
      viewId: "south_west",
      constraints: { a_stair: 0 },
      label: "A_LINK 西南视角 + 中央梯 0 档"
    }
  ],
  invalidSeams: [],
  solutionValues: { a_slide: 1, a_stair: 0, a_lift: 1 },
  solutionSeams: [{ linkId: "a_link_stair_island", viewId: "south_west", label: "A_STAIR_HIGH↔A_MID_ISLAND" }]
});

verifyLevel(LEVEL_B, {
  validSeams: [
    {
      linkId: "b_link_lower_stair_lift",
      viewId: "south_west",
      constraints: { b_lower_stair: 3, b_mid_lift: 0 },
      label: "B_LOWER_LINK 西南视角 + 下层梯 3 档 + 升降台 0 档"
    },
    {
      linkId: "b_link_upper_stair_island",
      viewId: "top_oblique",
      constraints: { b_upper_stair: 1 },
      label: "B_UPPER_LINK 上方视角 + 上层梯 1 档"
    }
  ],
  invalidSeams: [
    {
      linkId: "b_link_upper_stair_island",
      viewId: "south_east",
      constraints: { b_upper_stair: 3 },
      label: "B_UPPER_LINK 东南视角 + 上层梯 3 档错误重合"
    }
  ],
  solutionValues: { b_lower_stair: 3, b_mid_lift: 2, b_upper_stair: 1, b_exit_slide: 2 },
  visibleLandingEdges: [
    { nodeId: "B_HIGH_ISLAND", platformId: "b_platform_island", label: "上层梯到高层孤台" }
  ],
  inactivePlatformScreenClearances: [
    {
      nodeId: "B_HIGH_ISLAND",
      platformId: "b_platform_exit_slide",
      viewId: "top_oblique",
      mechanismValues: { b_exit_slide: 0 },
      minDistancePx: 30,
      label: "上层落点与未接通出口横移台保持屏幕净空"
    }
  ],
  mechanismDockings: [
    {
      platformId: "b_platform_exit_slide",
      state: 2,
      expectedCenter: [4.7138, 8.3637, 5.7],
      label: "出口横移台第 2 档回到高层通道"
    }
  ],
  solutionSeams: [
    { linkId: "b_link_lower_stair_lift", viewId: "south_west", values: { b_mid_lift: 0 }, label: "B_LOWER_HIGH↔B_MID_LIFT_LOW" },
    { linkId: "b_link_upper_stair_island", viewId: "top_oblique", label: "B_UPPER_HIGH↔B_HIGH_ISLAND" }
  ]
});

/* -------------------------------- 汇总 -------------------------------- */

console.log("\n=== 断言汇总 ===");
for (const line of notes) console.log(line);
console.log(`\n通过 ${notes.length - failures.length} 项，失败 ${failures.length} 项。`);
if (failures.length > 0) {
  console.error("\n校验失败：");
  for (const failure of failures) console.error(` - ${failure}`);
  process.exit(1);
}
// getStairLevel 帮助函数冒烟测试
if (getStairLevel("stair_a") !== LEVEL_A || getStairLevel("stair_b") !== LEVEL_B) {
  console.error("getStairLevel 返回错误");
  process.exit(1);
}
console.log("全部断言通过。");
