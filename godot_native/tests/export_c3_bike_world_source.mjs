import assert from 'node:assert/strict';
import crypto from 'node:crypto';
import fs from 'node:fs';
import path from 'node:path';
import vm from 'node:vm';
import { createRequire } from 'node:module';
import { fileURLToPath } from 'node:url';

// Record original executable TypeScript. Do not rewrite its geometry or guards
// here: consumers restore the visible drawing and retain chapter authority.
const nativeRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const rootFlag = process.argv.indexOf('--source-root');
if (rootFlag < 0 || !process.argv[rootFlag + 1] || process.argv[rootFlag + 1].startsWith('--')) {
  throw new Error('Usage: node tests/export_c3_bike_world_source.mjs --source-root /path/to/source [--check]');
}
const sourceRoot = path.resolve(process.argv[rootFlag + 1]);
const ts = createRequire(path.join(sourceRoot, 'package.json'))('typescript');
const bootFile = 'src/scenes/rpg/BootScene.ts';
const contentFile = 'src/data/chapter3-canteen.content.json';
const mapFile = 'src/data/maps/zijingang-campus-runtime.json';
const files = [bootFile, contentFile, mapFile];
const sources = Object.fromEntries(files.map(file => [file, fs.readFileSync(path.join(sourceRoot, file), 'utf8')]));
const content = JSON.parse(sources[contentFile]);
const campus = JSON.parse(sources[mapFile]);
const hash = text => crypto.createHash('sha256').update(text).digest('hex');
const copy = value => JSON.parse(JSON.stringify(value));
const extracted = {};

function extract(file, names, kind) {
  const ast = ts.createSourceFile(file, sources[file], ts.ScriptTarget.Latest, true);
  const found = new Map();
  function walk(node) {
    const matches = kind === 'method' ? ts.isMethodDeclaration(node) : ts.isVariableDeclaration(node);
    const name = matches && node.name?.getText(ast);
    if (name && names.includes(name)) {
      assert(!found.has(name), `Duplicate extracted ${name}`);
      found.set(name, kind === 'constant' ? `const ${node.getText(ast)};` : node.getText(ast));
      (extracted[file] ??= {})[name] = {
        line: ast.getLineAndCharacterOfPosition(node.getStart(ast)).line + 1,
        sha256: hash(node.getText(ast)),
      };
    }
    ts.forEachChild(node, walk);
  }
  walk(ast);
  assert.deepEqual([...found.keys()].sort(), [...names].sort(), `Changed source topology in ${file}`);
  return names.map(name => found.get(name)).join('\n');
}

function record(type, args = []) {
  const node = { type, args, calls: [], handlers: {}, visible: true, alpha: 1 };
  for (const method of ['setDepth', 'setInteractive', 'setOrigin', 'setVisible', 'setAlpha', 'setScale',
    'setBlendMode', 'setStrokeStyle', 'setRotation', 'setPosition', 'setText']) {
    node[method] = (...values) => {
      node.calls.push({ method, args: values });
      const property = method.slice(3, 4).toLowerCase() + method.slice(4);
      node[property] = values.length === 1 ? values[0] : values;
      return node;
    };
  }
  node.on = (event, handler) => { node.handlers[event] = handler; return node; };
  return node;
}

function graphics(textures) {
  const node = record('graphics');
  node.primitives = [];
  let line = null, fill = null;
  for (const method of ['lineStyle', 'fillStyle', 'strokeCircle', 'lineBetween', 'fillRoundedRect', 'fillRect']) {
    node[method] = (...args) => {
      node.calls.push({ method, args });
      if (method === 'lineStyle') line = { width: args[0], color: args[1], alpha: args[2] };
      else if (method === 'fillStyle') fill = { color: args[0], alpha: args[1] };
      else node.primitives.push({ method, args, style: copy(method.startsWith('fill') ? fill : line) });
      return node;
    };
  }
  node.generateTexture = (key, width, height) => {
    node.calls.push({ method: 'generateTexture', args: [key, width, height] });
    textures.push({ key, width, height, calls: copy(node.calls), primitives: copy(node.primitives) });
    return node;
  };
  node.destroy = () => { node.destroyed = true; };
  return node;
}

const bootMethods = extract(bootFile, [
  'ensureCanteenTextures', 'createCanteenBike', 'createCanteenBikeModeLayer',
  'getCanteenBikeWalletHint', 'requestCanteenBikeIfNearby', 'handleCanteenInventoryDrop',
], 'method');
const bootConstants = extract(bootFile, [
  'CANTEEN_BIKE', 'CANTEEN_BIKE_RADIUS', 'CANTEEN_DARK_OVERLAY_COLOR', 'CANTEEN_DARK_OVERLAY_ALPHA',
  'CANTEEN_PLAYER_LIGHT_SCALE', 'CANTEEN_PLAYER_LIGHT_ALPHA',
], 'constant');
const context = vm.createContext({
  record, graphics, campusRuntimeData: campus, canteenContent: content, ZIJINGANG_WORLD: campus.world,
  window: { devicePixelRatio: 1 },
  Phaser: { BlendModes: { ADD: 'ADD' }, Math: { Distance: { Between: (x1, y1, x2, y2) => Math.hypot(x1 - x2, y1 - y2) } } },
});
const code = `${bootConstants}
class Boot {
  constructor(state) {
    this.state = state; this.events = []; this.nodes = []; this.generatedTextures = [];
    this.textureChecks = [];
    this.textures = { exists: key => { this.textureChecks.push(key); return key !== 'canteen-bike'; } };
    this.add = Object.fromEntries(['image', 'text', 'rectangle', 'circle'].map(type =>
      [type, (...args) => { const node = record(type, args); this.nodes.push(node); return node; }]));
    this.add.graphics = () => { const node = graphics(this.generatedTextures); this.nodes.push(node); return node; };
    this.bridge = { getState: () => this.state, emit: (id, payload) =>
      this.events.push({ id, ...(payload === undefined ? {} : { payload }) }) };
    this.player = { x: CANTEEN_BIKE.x, y: CANTEEN_BIKE.y };
    this.worldPointCalls = [];
    this.cameraTransform = { scale: 1, offsetX: 0, offsetY: 0 };
    this.cameras = { main: { getWorldPoint: (x, y) => {
      const t = this.cameraTransform;
      const point = { x: x * t.scale + t.offsetX, y: y * t.scale + t.offsetY };
      this.worldPointCalls.push({ canvas: { x, y }, world: point });
      return point;
    } } };
  }
  ${bootMethods}
}
globalThis.Boot = Boot;
globalThis.sourceConstants = { bike: CANTEEN_BIKE, inspectRadius: CANTEEN_BIKE_RADIUS };
`;
vm.runInContext(ts.transpileModule(code, { compilerOptions: { target: ts.ScriptTarget.ES2022 } }).outputText, context);

function state(hunt = {}) {
  return { wallet: { cashCents: 200 }, items: { greaseTissue: true, cafeteriaWages: true },
    canteenHunt: { active: true, phase: 'chase_ready', mode: 'light', bikeCodeRead: false,
      bikeLockCleaned: false, bikePaid: false, chaseCompleted: false, ...hunt } };
}
function serialNode(node) {
  return copy({ type: node.type, args: node.args, visible: node.visible, alpha: node.alpha,
    calls: node.calls, events: Object.keys(node.handlers) });
}
const textureScene = new context.Boot(state());
textureScene.ensureCanteenTextures();
assert.deepEqual(copy(textureScene.textureChecks), ['canteen-footprint', 'canteen-light', 'canteen-bike']);
assert.equal(textureScene.generatedTextures.length, 1);
const texture = copy(textureScene.generatedTextures[0]);
assert.equal(texture.key, 'canteen-bike');
assert.deepEqual([texture.width, texture.height], [92, 62]);
assert.equal(texture.primitives.length, 16);
assert.equal(textureScene.nodes[0].destroyed, true);

const presentations = [];
for (const mode of ['light', 'dark']) for (const bikeLockCleaned of [false, true]) {
  const scene = new context.Boot(state({ mode, bikeLockCleaned }));
  const before = copy(scene.state);
  scene.createCanteenBike();
  scene.createCanteenBikeModeLayer(scene.state);
  assert.deepEqual(copy(scene.state), before);
  assert.equal(scene.events.length, 0);
  presentations.push({ mode, bikeLockCleaned, bike: serialNode(scene.canteenBike),
    hint: serialNode(scene.canteenBikeHint), codeGlow: serialNode(scene.canteenBikeCodeGlow),
    glare: serialNode(scene.canteenBikeGlare), darkness: serialNode(scene.canteenDarkOverlay),
    playerLight: serialNode(scene.canteenPlayerLight), stateUnchanged: true });
}

const inspectRequests = [];
for (const [name, hunt, offset, viaPointer] of [
  ['nearby', {}, 0, false], ['boundary', {}, 170, false], ['outside', {}, 170.001, false],
  ['wrong_phase', { phase: 'menu_order' }, 0, false], ['sprite_pointer', {}, 0, true],
]) {
  const scene = new context.Boot(state(hunt));
  scene.player.x += offset;
  const before = copy(scene.state);
  if (viaPointer) { scene.createCanteenBike(); scene.canteenBike.handlers.pointerdown(); }
  else scene.requestCanteenBikeIfNearby();
  assert.deepEqual(copy(scene.state), before);
  inspectRequests.push({ name, playerOffset: { x: offset, y: 0 }, viaPointer,
    events: copy(scene.events), stateUnchanged: true });
}

const inventoryDrops = [];
const anchor = copy(context.sourceConstants.bike);
function dropCase(name, payload, hunt = {}, transform = null, playerOffset = 0) {
  const scene = new context.Boot(state(hunt));
  if (transform) scene.cameraTransform = transform;
  scene.player.x += playerOffset;
  const before = copy(scene.state);
  scene.handleCanteenInventoryDrop(payload);
  assert.deepEqual(copy(scene.state), before);
  inventoryDrops.push({ name, payload: payload ?? null, hunt: copy(scene.state.canteenHunt),
    cameraTransform: copy(scene.cameraTransform), playerOffset,
    worldPointCalls: copy(scene.worldPointCalls), events: copy(scene.events), stateUnchanged: true });
}
for (const itemId of ['greaseTissue', 'cafeteriaWages']) {
  for (const [name, x, y] of [['center', 0, 0], ['boundary_x', 100, 0], ['boundary_y', 0, 100],
    ['boundary_diagonal', 60, 80], ['outside', 100.001, 0]]) {
    dropCase(`${itemId}_${name}`, { itemId, canvasX: anchor.x + x, canvasY: anchor.y + y });
  }
}
dropCase('wrong_item', { itemId: 'blackCoffee', canvasX: anchor.x, canvasY: anchor.y });
dropCase('wrong_phase', { itemId: 'greaseTissue', canvasX: anchor.x, canvasY: anchor.y }, { phase: 'menu_order' });
dropCase('missing_payload', undefined);
dropCase('missing_coordinates', { itemId: 'greaseTissue' });
dropCase('non_numeric_coordinate', { itemId: 'greaseTissue', canvasX: 'invalid', canvasY: anchor.y });
dropCase('transformed_canvas_tissue', { itemId: 'greaseTissue', canvasX: 160, canvasY: 100 }, {},
  { scale: 2, offsetX: anchor.x - 320, offsetY: anchor.y - 200 });
dropCase('far_player_drop_is_still_source_request', { itemId: 'greaseTissue', canvasX: anchor.x, canvasY: anchor.y }, {}, null, 1000);
dropCase('dark_mode_still_routes_to_controller', { itemId: 'cafeteriaWages', canvasX: anchor.x, canvasY: anchor.y }, { mode: 'dark' });
dropCase('repeat_tissue_request', { itemId: 'greaseTissue', canvasX: anchor.x, canvasY: anchor.y }, { bikeLockCleaned: true });
dropCase('repeat_wages_request', { itemId: 'cafeteriaWages', canvasX: anchor.x, canvasY: anchor.y }, { bikePaid: true });

// Verify that the source oracle reaches original branches, not only stub code.
assert.deepEqual(anchor, { x: 3220, y: 650 });
assert.equal(inspectRequests[1].events[0].id, 'rpg_canteen_bike_inspect_requested');
assert.equal(inspectRequests[2].events.length, 0);
assert.equal(inspectRequests[3].events.length, 0);
assert.equal(inspectRequests[4].events[0].id, 'rpg_canteen_bike_inspect_requested');
for (const itemId of ['greaseTissue', 'cafeteriaWages']) {
  const boundary = inventoryDrops.find(row => row.name === `${itemId}_boundary_x`);
  assert.equal(boundary.events[0].id, itemId === 'greaseTissue' ? 'rpg_canteen_bike_tissue_requested' : 'rpg_canteen_bike_requested');
  assert.equal(inventoryDrops.find(row => row.name === `${itemId}_outside`).events[0].payload.reason, 'missed_target');
}
assert.equal(inventoryDrops.find(row => row.name === 'transformed_canvas_tissue').events[0].id, 'rpg_canteen_bike_tissue_requested');

const output = {
  schemaVersion: 1,
  execution: 'Original extracted TypeScript texture and scene methods, recording graphics and bridge ports',
  sources: Object.fromEntries(files.map(file => [file, hash(sources[file])])),
  extracted,
  sourceMethodNames: { inspectRequest: 'requestCanteenBikeIfNearby', inventoryDrop: 'handleCanteenInventoryDrop' },
  bike: {
    texture,
    anchor,
    origin: { x: 0.5, y: 0.5, basis: 'Phaser Image default; source does not override origin or scale' },
    scale: { x: 1, y: 1 },
    textureWorldRect: { x: anchor.x - texture.width / 2, y: anchor.y - texture.height / 2,
      width: texture.width, height: texture.height },
    inspectRadius: context.sourceConstants.inspectRadius,
    sourceDropRadius: 100,
    radiusRoles: {
      inspectRadius: 'Player proximity guard for inspection only',
      sourceDropRadius: 'Source maximum world-point distance; restoration uses drawn-body picking and existing compact pointer tolerance inside this upper guard',
    },
    presentationOnly: true,
    chapterAuthority: 'Existing ChapterThreeCanteenController; scene methods emit requests and do not write progression, items, or wallet',
    controllerFixture: 'c3_canteen_devices_source.json: bike.controllerScenarios',
    presentations,
    inspectRequests,
    inventoryDrops,
  },
};
const target = path.join(nativeRoot, 'tests/fixtures/c3_bike_world_source.json');
const data = JSON.stringify(output, null, 2) + '\n';
if (process.argv.includes('--check')) {
  assert.equal(fs.readFileSync(target, 'utf8'), data, 'C3 bicycle world fixture is stale');
  console.log('C3 bicycle world fixture matches executed original TypeScript');
} else {
  fs.writeFileSync(target, data);
  console.log(target);
}
