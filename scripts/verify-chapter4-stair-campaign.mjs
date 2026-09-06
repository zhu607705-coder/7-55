import assert from 'node:assert/strict';
import { build } from 'esbuild';
import * as THREE from 'three';

const bundle = await build({ stdin: { contents: 'export * from "./src/tools/chapter4-stair/levels.ts"; export * from "./src/tools/chapter4-stair/engine.ts";', resolveDir: process.cwd() }, bundle: true, platform: 'node', format: 'esm', write: false });
const api = await import(`data:text/javascript;base64,${Buffer.from(bundle.outputFiles[0].text).toString('base64')}`);
const viewIds = ['south_east', 'south_west', 'top_oblique'];
function camera(level, view) {
  const c = api.LEVEL_CAMERAS[level.id];
  const result = new THREE.OrthographicCamera(-c.halfWidth, c.halfWidth, c.halfHeight, -c.halfHeight, c.near, c.far);
  result.position.set(...c.views[view].position); result.lookAt(...c.center); result.updateMatrixWorld(true);
  return result;
}
function graph(level, values, view) {
  const runtime = api.buildMechanismRuntime(level, values);
  const resolved = api.resolveConnectorWorld(level, runtime);
  const seams = api.evaluatePerspectiveSeams(level, camera(level, view), view, resolved).seams;
  return { seams, graph: api.buildNavGraph(level, values, seams) };
}
let states = 0;
for (const level of [api.LEVEL_C, api.LEVEL_D]) {
  const values = Object.fromEntries(level.mechanisms.map(m => [m.id, m.initialState]));
  const nodeIds = new Set(level.nodes.map(n => n.id));
  const door = level.geometry.decorations.find(d => d.kind === 'fire_door');
  for (const view of viewIds) {
    const top = new THREE.Vector3(...door.position).add(new THREE.Vector3(0, 2.3, 0)).project(camera(level, view));
    assert(Math.abs(top.x) < 0.97 && Math.abs(top.y) < 0.97, `${level.id}: exit clipped in ${view}`);
  }
  for (const edge of [...level.physicalEdges, ...level.mechanismEdges]) {
    assert(nodeIds.has(edge.a) && nodeIds.has(edge.b), `${level.id}: dangling edge`);
  }
  // Enumerate every mechanism configuration and view. A static solution must not
  // bypass riding a transfer, and each seam has exactly one intended view/pose.
  function visit(index) {
    if (index < level.mechanisms.length) {
      const m = level.mechanisms[index];
      for (let n = 0; n < m.stateCount; n++) { values[m.id] = n; visit(index + 1); }
      return;
    }
    for (const view of viewIds) {
      const result = graph(level, values, view); states++;
      assert(!api.findPath(result.graph, level.startNodeId, level.exitNodeId), `${level.id}: static route bypasses transfer`);
      for (const seam of result.seams.filter(s => s.valid)) {
        const linkIndex = level.perspectiveLinks.findIndex(l => l.id === seam.linkId);
        assert.equal(view, level.ascentViewSequence[linkIndex], `${level.id}: unintended view for ${seam.linkId}`);
        assert.equal(values[`${level.id}_${linkIndex + 1}_rotate`], 0, `${level.id}: unintended rotation`);
      }
    }
  }
  visit(0);
  for (const m of level.mechanisms) values[m.id] = m.initialState;
  let current = level.startNodeId;
  level.ascentViewSequence.forEach((view, i) => {
    const prefix = `${level.id}_${i + 1}`;
    values[`${prefix}_rotate`] = 0;
    values[`${prefix}_transfer`] = 0;
    let result = graph(level, values, view);
    const path = api.findPath(result.graph, current, `${prefix}_car`);
    assert(path, `${level.id}: cannot board transfer ${i + 1}`);
    assert(path.includes(`${prefix}_high`) && path.includes(`${prefix}_island`), 'must traverse calibrated seam');
    const before = result.graph.nodes.get(`${prefix}_car`).position.clone();
    values[`${prefix}_transfer`] = 2;
    result = graph(level, values, view);
    assert(before.distanceTo(result.graph.nodes.get(`${prefix}_car`).position) >= 1.5, 'must ride a moving platform');
    current = i === level.ascentViewSequence.length - 1 ? level.exitNodeId : `${prefix}_transfer_exit`;
    assert(api.findPath(result.graph, `${prefix}_car`, current), 'must be able to disembark');
  });
  assert.equal(current, level.exitNodeId);
  console.log(`${level.id}: sequential solution verified (${level.nodes.length} nodes, ${level.mechanisms.length} mechanisms)`);
}
console.log(`Campaign: ${states} view/configuration combinations passed; all advanced ride sequences reach their exit.`);
