/**
 * 第四章楼梯间投影引擎（src/tools/chapter4-stair/engine.ts）的独立验证脚本。
 * 直接运行：node scripts/verify-chapter4-stair-engine.mjs
 *
 * 自带合成夹具数据（不 import levels.ts），通过 esbuild 将 TypeScript 引擎
 * 打包为内存中的 ESM 再断言：
 *  - 旋转变换正确（pivot 偏移下 0 档端点转 90° 到位）
 *  - 投影距离/方向判定边界（5.9px 通过、6.1px 拒绝、相向 -0.95 通过、同向 +0.9 判 invalid）
 *  - BFS 与边界节点选择正确
 *  - 档位取模循环正确
 */
import { createRequire } from "node:module";
import { fileURLToPath } from "node:url";
import * as THREE from "three";

const require = createRequire(import.meta.url);
const esbuild = require("esbuild");

const engineEntry = fileURLToPath(new URL("../src/tools/chapter4-stair/engine.ts", import.meta.url));
let engine;
try {
  const result = await esbuild.build({
    entryPoints: [engineEntry],
    bundle: true,
    format: "esm",
    platform: "node",
    target: "es2022",
    write: false,
    logLevel: "warning"
  });
  const code = result.outputFiles[0].text;
  engine = await import(`data:text/javascript;base64,${Buffer.from(code).toString("base64")}`);
} catch (error) {
  console.error("Failed to bundle src/tools/chapter4-stair/engine.ts with esbuild.");
  console.error(error);
  process.exit(1);
}

const {
  buildMechanismRuntime,
  resolveConnectorWorld,
  evaluatePerspectiveSeams,
  buildNavGraph,
  findPath,
  nearestBoundaryNode,
  selectDirectionalNeighbor,
  stepMechanism,
  nodeWorldPosition
} = engine;

let passed = 0;
let failed = 0;
function check(name, condition, detail = "") {
  if (condition) {
    passed += 1;
    return;
  }
  failed += 1;
  console.error(`FAIL: ${name}${detail ? ` — ${detail}` : ""}`);
}
function approx(actual, expected, epsilon = 1e-6) {
  return Math.abs(actual - expected) <= epsilon;
}
function approxVector(actual, expected, epsilon = 1e-6) {
  return approx(actual.x, expected[0], epsilon) && approx(actual.y, expected[1], epsilon) && approx(actual.z, expected[2], epsilon);
}

const ALL_VIEWS = ["south_east", "south_west", "top_oblique"];

function makeLevel(overrides = {}) {
  return {
    id: "stair_a",
    title: "fixture level",
    startNodeId: "n1",
    exitNodeId: "n_exit",
    nodes: [],
    physicalEdges: [],
    mechanisms: [],
    mechanismEdges: [],
    connectors: [],
    perspectiveLinks: [],
    ascentViewSequence: [],
    geometry: { platforms: [], stairs: [], decorations: [] },
    feedback: { firstSeam: "", blocked: "", wrongDirection: "", objective: "" },
    ...overrides
  };
}

function makeMechanism(id, overrides = {}) {
  return {
    id,
    kind: "rotate",
    stateCount: 4,
    initialState: 0,
    pivot: [0, 0, 0],
    axis: "y",
    stepSize: 0,
    label: id,
    ...overrides
  };
}

function makeConnector(id, { position, tangent, nodeId = `node_${id}`, views = ALL_VIEWS, linkGroup = "G", ownerId = "level", projectionMode = "perspective" }) {
  return {
    id,
    ownerId,
    worldPosition: new THREE.Vector3(position[0], position[1], position[2]),
    worldTangent: new THREE.Vector3(tangent[0], tangent[1], tangent[2]),
    nodeId,
    views,
    linkGroup,
    projectionMode
  };
}

/** 正前方正交相机：世界 1 单位 = 内部 25px（480/19.2、270/10.8），+x → 屏幕右，+y → 屏幕上。 */
function makeFrontCamera() {
  const camera = new THREE.OrthographicCamera(-9.6, 9.6, 5.4, -5.4, 0.1, 50);
  camera.position.set(0, 0, 10);
  camera.lookAt(0, 0, 0);
  camera.updateMatrixWorld(true);
  return camera;
}

// ---------------------------------------------------------------------------
// 1) 机关运行态：绕任意 pivot 的 y 轴旋转、沿轴平移、档位取模
// ---------------------------------------------------------------------------
{
  const level = makeLevel({
    mechanisms: [
      makeMechanism("rot", { kind: "rotate", stateCount: 4, pivot: [2, 0, 0], axis: "y" }),
      makeMechanism("lift", { kind: "vertical", stateCount: 3, axis: "y", stepSize: 1.5 }),
      makeMechanism("slide", { kind: "horizontal", stateCount: 3, axis: "x", stepSize: 2 })
    ],
    nodes: [
      { id: "n_rot", ownerId: "rot", position: [4, 0, 0], safe: false },
      { id: "n_lift", ownerId: "lift", position: [5, 1, 5], safe: false },
      { id: "n_slide", ownerId: "slide", position: [1, 0, 1], safe: false },
      { id: "n_static", ownerId: "level", position: [9, 9, 9], safe: true }
    ],
    connectors: [
      makeConnector("c_rot", { ownerId: "rot", position: [4, 0, 0], tangent: [1, 0, 0] })
    ]
  });

  // 0 档恒等。
  check("rotate state 0 keeps declared position", approxVector(nodeWorldPosition(level, { rot: 0 }, "n_rot"), [4, 0, 0]));
  // pivot 偏移 +2x，1 档绕 y 转 90°：相对 pivot 的 (2,0,0) → (0,0,-2)，世界坐标 (2,0,-2)。
  const rotated = nodeWorldPosition(level, { rot: 1 }, "n_rot");
  check("rotate state 1 maps endpoint around pivot by 90°", approxVector(rotated, [2, 0, -2]), `got (${rotated.x}, ${rotated.y}, ${rotated.z})`);
  // 3 档（亦由 -1 取模得到）：(2,0,0) → (0,0,2)。
  check("rotate state 3 via negative modulo maps to (2,0,2)", approxVector(nodeWorldPosition(level, { rot: -1 }, "n_rot"), [2, 0, 2]));
  // 平移机关。
  check("vertical lift state 2 offsets y by 2 * stepSize", approxVector(nodeWorldPosition(level, { lift: 2 }, "n_lift"), [5, 4, 5]));
  check("horizontal slide state 1 offsets x by stepSize", approxVector(nodeWorldPosition(level, { slide: 1 }, "n_slide"), [3, 0, 1]));
  check("static node ignores mechanism values", approxVector(nodeWorldPosition(level, { rot: 3, lift: 2 }, "n_static"), [9, 9, 9]));
  // 端点世界姿态：位置与切线同步旋转，切线保持单位长度。
  const runtime = buildMechanismRuntime(level, { rot: 1 });
  const connectorWorld = resolveConnectorWorld(level, runtime);
  const cRot = connectorWorld.get("c_rot");
  check("connector world position follows pivot rotation", approxVector(cRot.worldPosition, [2, 0, -2]));
  check("connector world tangent rotates as pure direction", approxVector(cRot.worldTangent, [0, 0, -1]));
  // 超界档位取模：rot 7 → 3。
  const normalized = buildMechanismRuntime(level, { rot: 7 }).find((entry) => entry.id === "rot");
  check("mechanism state 7 normalizes to 3 (mod stateCount)", normalized.state === 3);
}

// ---------------------------------------------------------------------------
// 2) 投影接缝：距离/方向/视角/遮挡/linkGroup 白名单/同组最近候选
// ---------------------------------------------------------------------------
{
  const camera = makeFrontCamera();
  const makeSeamLevel = ({ separation, tangentB, views = ALL_VIEWS, linkGroupB = "G" }) =>
    makeLevel({
      connectors: [
        makeConnector("ca", { position: [0, 0, 0], tangent: [1, 0, 0], views }),
        makeConnector("cb", { position: [separation, 0, 0], tangent: tangentB, views, linkGroup: linkGroupB })
      ],
      perspectiveLinks: [{ id: "link_main", linkGroup: "G", connectorA: "ca", connectorB: "cb" }]
    });

  // 5.9px（0.236 世界单位）相向切线 → valid。
  const near = evaluatePerspectiveSeams(
    makeSeamLevel({ separation: 0.236, tangentB: [-1, 0, 0] }),
    camera,
    "south_east",
    resolveConnectorWorld(makeSeamLevel({ separation: 0.236, tangentB: [-1, 0, 0] }), [])
  );
  check("5.9px opposing pair is a valid seam", near.seams.length === 1 && near.seams[0].valid, JSON.stringify(near.seams));
  check(
    "5.9px seam reports distance ≈ 5.9",
    near.seams.length === 1 && approx(near.seams[0].screenDistancePx, 5.9, 0.05),
    near.seams[0] ? String(near.seams[0].screenDistancePx) : "no seam"
  );

  // 6.1px（0.244 世界单位）→ 拒绝。
  const farLevel = makeSeamLevel({ separation: 0.244, tangentB: [-1, 0, 0] });
  const far = evaluatePerspectiveSeams(farLevel, camera, "south_east", resolveConnectorWorld(farLevel, []));
  check("6.1px pair is rejected", far.seams.length === 0, JSON.stringify(far.seams));

  // 相向点积 -0.95 ≤ -cos(20°) → valid。
  const opposingLevel = makeSeamLevel({ separation: 0.236, tangentB: [-0.95, 0.31224989991991997, 0] });
  const opposing = evaluatePerspectiveSeams(opposingLevel, camera, "south_east", resolveConnectorWorld(opposingLevel, []));
  check("opposing tangents (dot -0.95) pass direction check", opposing.seams.length === 1 && opposing.seams[0].valid);

  // 点积 -0.9（偏过 20°）→ invalid。
  const shallowLevel = makeSeamLevel({ separation: 0.236, tangentB: [-0.9, 0.43588989435406733, 0] });
  const shallow = evaluatePerspectiveSeams(shallowLevel, camera, "south_east", resolveConnectorWorld(shallowLevel, []));
  check("barely-opposing tangents (dot -0.9) are invalid", shallow.seams.length === 1 && !shallow.seams[0].valid);

  // 同向点积 +0.9 → invalid（橙色虚线保留在返回值中，不写入导航图）。
  const sameDirLevel = makeSeamLevel({ separation: 0.236, tangentB: [0.9, 0.43588989435406733, 0] });
  const sameDir = evaluatePerspectiveSeams(sameDirLevel, camera, "south_east", resolveConnectorWorld(sameDirLevel, []));
  check(
    "same-direction tangents (dot +0.9) produce invalid seam",
    sameDir.seams.length === 1 && sameDir.seams[0].valid === false && approx(sameDir.seams[0].screenDistancePx, 5.9, 0.05)
  );

  // 视角门控：端点只允许 south_east 时，south_west 不产生候选。
  const gatedLevel = makeSeamLevel({ separation: 0.236, tangentB: [-1, 0, 0], views: ["south_east"] });
  const gated = evaluatePerspectiveSeams(gatedLevel, camera, "south_west", resolveConnectorWorld(gatedLevel, []));
  check("connectors rejecting current view produce no seam", gated.seams.length === 0 && gated.droppedCandidates.length === 0);

  // 遮挡回调返回 true → 丢弃该对。
  const occludedLevel = makeSeamLevel({ separation: 0.236, tangentB: [-1, 0, 0] });
  const occluded = evaluatePerspectiveSeams(
    occludedLevel,
    camera,
    "south_east",
    resolveConnectorWorld(occludedLevel, []),
    () => true
  );
  check("occluded pair is dropped", occluded.seams.length === 0);

  // linkGroup 与白名单不一致 → 不参与比较。
  const mismatchedLevel = makeSeamLevel({ separation: 0.236, tangentB: [-1, 0, 0], linkGroupB: "OTHER" });
  const mismatched = evaluatePerspectiveSeams(mismatchedLevel, camera, "south_east", resolveConnectorWorld(mismatchedLevel, []));
  check("linkGroup mismatch against whitelist is skipped", mismatched.seams.length === 0);

  // 同 linkGroup 多候选：保留屏幕距离最小的一组，其余进 droppedCandidates。
  const dedupLevel = makeLevel({
    connectors: [
      makeConnector("c1", { position: [0, 0, 0], tangent: [1, 0, 0], linkGroup: "G2" }),
      makeConnector("c2", { position: [0.08, 0, 0], tangent: [-1, 0, 0], linkGroup: "G2" }),
      makeConnector("c3", { position: [3, 0, 0], tangent: [1, 0, 0], linkGroup: "G2" }),
      makeConnector("c4", { position: [3.12, 0, 0], tangent: [-1, 0, 0], linkGroup: "G2" })
    ],
    perspectiveLinks: [
      { id: "ld_far", linkGroup: "G2", connectorA: "c3", connectorB: "c4" },
      { id: "ld_near", linkGroup: "G2", connectorA: "c1", connectorB: "c2" }
    ]
  });
  const dedup = evaluatePerspectiveSeams(dedupLevel, camera, "south_east", resolveConnectorWorld(dedupLevel, []));
  check(
    "multi-candidate group keeps only the nearest pair",
    dedup.seams.length === 1 && dedup.seams[0].id === "ld_near" && approx(dedup.seams[0].screenDistancePx, 2, 0.05),
    JSON.stringify(dedup.seams)
  );
  check(
    "losing candidate is recorded in droppedCandidates",
    dedup.droppedCandidates.length === 1 && dedup.droppedCandidates[0].id === "ld_far" && approx(dedup.droppedCandidates[0].screenDistancePx, 3, 0.05),
    JSON.stringify(dedup.droppedCandidates)
  );
}

// ---------------------------------------------------------------------------
// 3) 导航图、BFS 与边界节点选择
// ---------------------------------------------------------------------------
{
  const level = makeLevel({
    mechanisms: [makeMechanism("lift", { kind: "vertical", stateCount: 3, axis: "y", stepSize: 1.5 })],
    nodes: [
      { id: "n1", ownerId: "level", position: [0, 0, 0], safe: true },
      { id: "n2", ownerId: "level", position: [2, 0, 0], safe: false },
      { id: "n3", ownerId: "level", position: [4, 0, 0], safe: false },
      { id: "n4", ownerId: "level", position: [6, 0, 0], safe: false },
      { id: "n5", ownerId: "level", position: [8, 0, 0], safe: true },
      { id: "n6", ownerId: "level", position: [2, 2, 0], safe: false },
      { id: "n7", ownerId: "level", position: [20, 0, 0], safe: true }
    ],
    physicalEdges: [
      { id: "e1", a: "n1", b: "n2" },
      { id: "e2", a: "n2", b: "n3" },
      { id: "e3", a: "n4", b: "n5" },
      { id: "e4", a: "n2", b: "n6" }
    ],
    mechanismEdges: [{ id: "me1", a: "n3", b: "n4", mechanismId: "lift", requiredState: 1 }]
  });

  const validSeam = {
    id: "seam_p", linkId: "lp", linkGroup: "G",
    connectorA: "cx", connectorB: "cy", nodeA: "n5", nodeB: "n6",
    screenDistancePx: 3, valid: true
  };
  const invalidSeam = { ...validSeam, id: "seam_bad", nodeA: "n3", valid: false };

  const graphOff = buildNavGraph(level, { lift: 0 }, [validSeam, invalidSeam]);
  const edgeIds = (graph) => graph.edges.map((edge) => `${edge.kind}:${edge.id}`);
  check("mechanism edge inactive at wrong state", !graphOff.edges.some((edge) => edge.id === "me1"));
  check("valid perspective seam becomes a perspective edge", graphOff.edges.some((edge) => edge.id === "seam_p" && edge.kind === "perspective"));
  check("invalid seam never enters the nav graph", !graphOff.edges.some((edge) => edge.id === "seam_bad"));
  check("physical edges always present", ["e1", "e2", "e3", "e4"].every((id) => graphOff.edges.some((edge) => edge.id === id && edge.kind === "physical")), edgeIds(graphOff).join(","));

  const graphOn = buildNavGraph(level, { lift: 1 }, []);
  check("mechanism edge active at required state", graphOn.edges.some((edge) => edge.id === "me1" && edge.kind === "mechanism"));
  const graphWrapped = buildNavGraph(level, { lift: 4 }, []);
  check("mechanism edge honors modulo-normalized state (4 → 1)", graphWrapped.edges.some((edge) => edge.id === "me1"));

  // BFS 最短路。
  check("BFS finds direct path", JSON.stringify(findPath(graphOff, "n1", "n3")) === JSON.stringify(["n1", "n2", "n3"]));
  check("BFS routes through perspective edge when present", JSON.stringify(findPath(graphOff, "n1", "n4")) === JSON.stringify(["n1", "n2", "n6", "n5", "n4"]));
  check("BFS uses perspective edge for shortest route", JSON.stringify(findPath(graphOff, "n6", "n5")) === JSON.stringify(["n6", "n5"]));
  check("BFS reaches via mechanism edge when active", JSON.stringify(findPath(graphOn, "n1", "n5")) === JSON.stringify(["n1", "n2", "n3", "n4", "n5"]));
  check("BFS trivial self path", JSON.stringify(findPath(graphOff, "n1", "n1")) === JSON.stringify(["n1"]));
  check("BFS unknown node returns null", findPath(graphOff, "n1", "nope") === null);

  // 有效投影接缝的两端在屏幕上近乎重合。方向输入必须优先按世界高度解释：
  // ↑ 从较低端跨到较高端，↓ 从较高端返回较低端，不能受亚像素误差翻转。
  const coincidentProjector = (nodeId) => {
    if (nodeId === "n5" || nodeId === "n6") return { x: 240, y: 135 };
    const position = graphOff.nodes.get(nodeId).position;
    return { x: 240 + 25 * position.x, y: 135 - 25 * position.y };
  };
  check("directional neighbor selector is exported", typeof selectDirectionalNeighbor === "function");
  check(
    "ArrowUp crosses a coincident perspective seam toward the higher node",
    typeof selectDirectionalNeighbor === "function"
      && selectDirectionalNeighbor(graphOff, "n5", { x: 0, y: -1 }, coincidentProjector) === "n6"
  );
  check(
    "ArrowDown crosses a coincident perspective seam toward the lower node",
    typeof selectDirectionalNeighbor === "function"
      && selectDirectionalNeighbor(graphOff, "n6", { x: 0, y: 1 }, coincidentProjector) === "n5"
  );
  check(
    "ArrowDown does not traverse the authored ascent direction",
    typeof selectDirectionalNeighbor === "function"
      && selectDirectionalNeighbor(graphOff, "n5", { x: 0, y: 1 }, coincidentProjector) !== "n6"
  );
  check(
    "ArrowUp does not traverse the authored descent direction",
    typeof selectDirectionalNeighbor === "function"
      && selectDirectionalNeighbor(graphOff, "n6", { x: 0, y: -1 }, coincidentProjector) !== "n5"
  );

  // 边界节点：分量 n1-n2-n3-n6（度数 1/3/1/1），边界为度 1 的 n3 与 n6。
  const graphPlain = buildNavGraph(level, { lift: 0 }, []);
  check("BFS returns null across disconnected components", findPath(graphPlain, "n1", "n4") === null);
  const projector = (nodeId) => {
    const position = graphPlain.nodes.get(nodeId).position;
    return { x: 240 + 25 * position.x, y: 135 - 25 * position.y };
  };
  check(
    "boundary walk prefers screen direction toward target (right → n3)",
    nearestBoundaryNode(graphPlain, "n1", { x: 1, y: 0 }, projector) === "n3"
  );
  check(
    "boundary walk prefers screen direction toward target (up → n6)",
    nearestBoundaryNode(graphPlain, "n1", { x: 0, y: -1 }, projector) === "n6"
  );
  check(
    "boundary selection from mid component (left → n1)",
    nearestBoundaryNode(graphPlain, "n3", { x: -1, y: 0 }, projector) === "n1"
  );
  check("isolated player node returns itself", nearestBoundaryNode(graphPlain, "n7", { x: 1, y: 0 }, projector) === "n7");

  // 数据错误快速失败。
  let threw = false;
  try {
    buildNavGraph(makeLevel({ nodes: [{ id: "a", ownerId: "level", position: [0, 0, 0], safe: true }], physicalEdges: [{ id: "bad", a: "a", b: "ghost" }] }), {}, []);
  } catch {
    threw = true;
  }
  check("nav graph rejects edges referencing unknown nodes", threw);
}

// ---------------------------------------------------------------------------
// 4) 机关步进：取模循环 + 纯函数
// ---------------------------------------------------------------------------
{
  const level = makeLevel({
    mechanisms: [
      makeMechanism("rot", { kind: "rotate", stateCount: 4 }),
      makeMechanism("lift", { kind: "vertical", stateCount: 3, axis: "y", stepSize: 1.5 })
    ]
  });
  check("rotate wraps 3 +1 → 0", stepMechanism(level, { rot: 3 }, "rot", 1).rot === 0);
  check("rotate wraps 0 -1 → 3", stepMechanism(level, { rot: 0 }, "rot", -1).rot === 3);
  check("lift wraps 2 +1 → 0", stepMechanism(level, { lift: 2 }, "lift", 1).lift === 0);
  check("lift wraps 0 -1 → 2", stepMechanism(level, { lift: 0 }, "lift", -1).lift === 2);
  check("missing value falls back to initialState before stepping", stepMechanism(level, {}, "rot", 1).rot === 1);
  const before = { rot: 3, lift: 2 };
  const after = stepMechanism(level, before, "rot", 1);
  check("stepMechanism is pure (input untouched, new object)", before.rot === 3 && after.rot === 0 && after.lift === 2 && after !== before);
  check("out-of-range stored value normalizes before stepping (7 → 3 → 0)", stepMechanism(level, { rot: 7 }, "rot", 1).rot === 0);
  let threw = false;
  try {
    stepMechanism(level, {}, "ghost", 1);
  } catch {
    threw = true;
  }
  check("stepMechanism rejects unknown mechanism id", threw);
}

if (failed > 0) {
  console.error(`\nchapter4 stair engine: ${failed} check(s) failed, ${passed} passed.`);
  process.exit(1);
}
console.log(`chapter4 stair engine: all ${passed} checks passed.`);
