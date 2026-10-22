import assert from 'node:assert/strict';
import crypto from 'node:crypto';
import fs from 'node:fs';
import path from 'node:path';
import vm from 'node:vm';
import { createRequire } from 'node:module';
import { fileURLToPath } from 'node:url';

// Execute the original TypeScript with recording presentation ports. This fixture
// is a source oracle, never a second implementation of the gameplay rules.
const nativeRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const rootFlag = process.argv.indexOf('--source-root');
if (rootFlag < 0 || !process.argv[rootFlag + 1] || process.argv[rootFlag + 1].startsWith('--')) {
  throw new Error('Usage: node tests/export_c3_canteen_devices_source.mjs --source-root /path/to/source [--check]');
}
const sourceRoot = path.resolve(process.argv[rootFlag + 1]);
const ts = createRequire(path.join(sourceRoot, 'package.json'))('typescript');
const sceneFile = 'src/scenes/rpg/CanteenInteriorScene.ts';
const bootFile = 'src/scenes/rpg/BootScene.ts';
const controllerFile = 'src/modules/ChapterThreeCanteenController.ts';
const contentFile = 'src/data/chapter3-canteen.content.json';
const mapFile = 'src/data/maps/zijingang-campus-runtime.json';
const files = [sceneFile, bootFile, controllerFile, contentFile, mapFile];
const sources = Object.fromEntries(files.map(file => [file, fs.readFileSync(path.join(sourceRoot, file), 'utf8')]));
const content = JSON.parse(sources[contentFile]);
const campus = JSON.parse(sources[mapFile]);
const extracted = {};

function extract(file, names, kind) {
  const ast = ts.createSourceFile(file, sources[file], ts.ScriptTarget.Latest, true);
  const found = new Map();
  function walk(node) {
    const matches = kind === 'method' ? ts.isMethodDeclaration(node)
      : kind === 'function' ? ts.isFunctionDeclaration(node) : ts.isVariableDeclaration(node);
    const name = matches && node.name?.getText(ast);
    if (name && names.includes(name)) {
      assert(!found.has(name), `Duplicate extracted ${name}`);
      found.set(name, kind === 'constant' ? `const ${node.getText(ast)};` : node.getText(ast));
      (extracted[file] ??= {})[name] = {
        line: ast.getLineAndCharacterOfPosition(node.getStart(ast)).line + 1,
        sha256: crypto.createHash('sha256').update(node.getText(ast)).digest('hex'),
      };
    }
    ts.forEachChild(node, walk);
  }
  walk(ast);
  assert.deepEqual([...found.keys()].sort(), [...names].sort(), `Changed source topology in ${file}`);
  return names.map(name => found.get(name)).join('\n');
}

function record(type, args = []) {
  const item = { type, args, children: [], calls: [], handlers: {}, data: {}, alpha: 1, visible: true };
  const setters = ['ScrollFactor', 'Depth', 'StrokeStyle', 'Origin', 'Text', 'Visible', 'Alpha', 'Color',
    'FillStyle', 'Interactive', 'Position', 'Rotation', 'Scale', 'BlendMode'];
  for (const setter of setters) item[`set${setter}`] = (...values) => {
    item.calls.push({ method: `set${setter}`, args: values });
    item[setter[0].toLowerCase() + setter.slice(1)] = values.length === 1 ? values[0] : values;
    return item;
  };
  for (const method of ['fillStyle', 'fillRect', 'lineStyle', 'strokeRect']) {
    item[method] = (...values) => { item.calls.push({ method, args: values }); return item; };
  }
  item.add = children => { item.children.push(...(Array.isArray(children) ? children : [children])); return item; };
  item.on = (event, handler) => { item.handlers[event] = handler; return item; };
  item.setData = (key, value) => { item.data[key] = value; return item; };
  item.destroy = () => { item.destroyed = true; };
  return item;
}

const context = vm.createContext({
  record, canteenContent: content, campusRuntimeData: campus, ZIJINGANG_WORLD: campus.world,
  window: { devicePixelRatio: 1, matchMedia: () => ({ matches: false }) },
  toRpgLogicalScreenPoint: (_scene, x, y) => ({ x, y }),
  Phaser: { BlendModes: { ADD: 'ADD' }, Math: { Distance: { Between: (x1, y1, x2, y2) => Math.hypot(x1 - x2, y1 - y2) } } },
});
const sceneMethods = extract(sceneFile, [
  'hasModalPanel', 'isMovementAllowed', 'handleModalKeyboard', 'openDrinkChoicePanel',
  'handleDrinkChoicePointer', 'refreshDrinkChoiceSelection', 'confirmDrinkChoiceSelection',
  'closeDrinkChoicePanel', 'openMenuPanel', 'handleMenuPointer', 'closeMenuPanel', 'refreshMenuPanel',
], 'method');
const controllerMethods = extract(controllerFile, [
  'collectDrink', 'inspectMenuClue', 'selectMenuOption', 'inspectBikeLock', 'cleanBikeLock', 'payForBike', 'startChase',
], 'method');
const controllerConstants = extract(controllerFile, [
  'CANTEEN_BIKE_FARE_CENTS', 'CANTEEN_DRINK_RECIPE', 'CANTEEN_MENU_OPTIONS',
  'CANTEEN_SIDE_GAME_PHASES', 'CANTEEN_MENU_OBSERVATION_PHASES',
], 'constant');
const controllerHelpers = extract(controllerFile, ['canPlayCanteenSideGames', 'canPlayDrinkPuzzle'], 'function');
const bootMethods = extract(bootFile, [
  'createCanteenBike', 'createCanteenBikeModeLayer', 'getCanteenBikeWalletHint',
  'requestCanteenBikeIfNearby', 'handleCanteenInventoryDrop', 'applyCanteenBikeMode',
  'animateCanteenBikeCodeRead', 'animateCanteenBikeCleaned', 'showCanteenFeedback',
], 'method');
const bootConstants = extract(bootFile, [
  'CANTEEN_BIKE', 'CANTEEN_BIKE_RADIUS', 'CANTEEN_DARK_OVERLAY_COLOR', 'CANTEEN_DARK_OVERLAY_ALPHA',
  'CANTEEN_PLAYER_LIGHT_SCALE', 'CANTEEN_PLAYER_LIGHT_ALPHA',
], 'constant');
const code = `
${controllerConstants}\n${controllerHelpers}\n${bootConstants}
class RecordingScene {
  constructor(state) {
    this.state = state; this.events = []; this.feedback = []; this.nodes = []; this.tweenCalls = [];
    this.menuPanel = null; this.drinkChoicePanel = null; this.mixerPanel = null;
    this.drinkChoiceItem = null; this.drinkChoiceSelection = 0; this.drinkChoiceControls = null;
    this.suppressWorldPointerUntil = 0; this.time = { now: 1234 };
    this.add = Object.fromEntries(['container', 'rectangle', 'text', 'graphics', 'image', 'circle'].map(type =>
      [type, (...args) => { const node = record(type, args); this.nodes.push(node); return node; }]));
    this.bridge = { getState: () => this.state, emit: (id, payload) => this.events.push({ id, ...(payload === undefined ? {} : { payload }) }) };
    this.player = { x: CANTEEN_BIKE.x, y: CANTEEN_BIKE.y };
    this.cameras = { main: { getWorldPoint: (x, y) => ({ x, y }) } };
    this.tweens = { add: tween => { this.tweenCalls.push(tween); return tween; } };
  }
  showFeedback(text, tone) { this.feedback.push({ text, tone }); }
  closeMixerPanel() { this.mixerPanel = null; }
}
class Scene extends RecordingScene { ${sceneMethods} }
class Boot extends RecordingScene { ${bootMethods} }
class Controller {
  constructor(state) {
    this.state = state; this.emitted = []; this.writeCount = 0;
    this.store = { getState: () => this.state, setState: update => { this.state = update(this.state); this.writeCount++; } };
    this.events = { emit: (id, payload) => this.emitted.push({ id, ...(payload === undefined ? {} : { payload }) }) };
  }
  ${controllerMethods}
}
globalThis.Scene = Scene; globalThis.Boot = Boot; globalThis.Controller = Controller;`;
vm.runInContext(ts.transpileModule(code, { compilerOptions: { target: ts.ScriptTarget.ES2022 } }).outputText, context);

const copy = value => JSON.parse(JSON.stringify(value));
function state({ hunt = {}, items = {}, cashCents = 200, ...rest } = {}) {
  return { actOne: { movementEnabled: true }, wallet: { cashCents },
    items: { greaseTissue: true, cafeteriaWages: true, ...items },
    canteenHunt: { active: true, phase: 'menu_order', mode: 'light', promoDrinkPlaced: false,
      queueGapOpened: false, menuDarkClueRead: false, orderedMenuOption: null, orderAttemptCount: 0,
      bikeCodeRead: false, bikeLockCleaned: false, bikePaid: false, chaseCompleted: false, ...hunt }, ...rest };
}
function serialNode(node) {
  return { type: node.type, args: node.args, visible: node.visible, alpha: node.alpha,
    calls: node.calls, data: node.data, children: node.children.map(serialNode) };
}
function drinkSnapshot(scene) {
  return copy({ open: scene.drinkChoicePanel !== null, itemId: scene.drinkChoiceItem,
    selection: scene.drinkChoiceSelection, movementAllowed: scene.isMovementAllowed(scene.state),
    events: scene.events, items: scene.state.items, suppressWorldPointerUntil: scene.suppressWorldPointerUntil,
    labels: scene.drinkChoiceControls ? {
      take: scene.drinkChoiceControls.takeLabel.text, cancel: scene.drinkChoiceControls.cancelLabel.text,
    } : null });
}
function press(scene, key, code = key, repeat = false) {
  let prevented = false;
  scene.handleModalKeyboard({ key, code, repeat, preventDefault() { prevented = true; } });
  return { key, code, repeat, prevented, ...drinkSnapshot(scene) };
}

const drinkPresentations = {};
for (const itemId of ['sparklingWater', 'lemonTea', 'blackCoffee']) {
  const scene = new context.Scene(state());
  const before = copy(scene.state);
  scene.openDrinkChoicePanel(itemId);
  assert.deepEqual(copy(scene.state), before);
  assert.equal(scene.events.length, 0);
  drinkPresentations[itemId] = { opened: drinkSnapshot(scene), panel: serialNode(scene.drinkChoicePanel) };
}
const keyboardCases = [];
for (const [name, keys] of [
  ['cancel_by_right_enter', [['ArrowRight'], ['Enter']]],
  ['cancel_by_d_space', [['d', 'KeyD'], [' ', 'Space']]],
  ['escape', [['Escape']]],
  ['take_by_left_enter', [['ArrowRight'], ['ArrowLeft'], ['Enter']]],
  ['take_by_a_space', [['d', 'KeyD'], ['a', 'KeyA'], [' ', 'Space']]],
  ['repeated_confirm_and_escape_ignored', [['Enter', 'Enter', true], ['Escape', 'Escape', true], ['Escape']]],
]) {
  const scene = new context.Scene(state());
  scene.openDrinkChoicePanel('sparklingWater');
  keyboardCases.push({ name, steps: keys.map(args => press(scene, ...args)) });
}
const pointerCases = [];
for (const [name, x, y] of [['take', 385, 352], ['cancel', 575, 352], ['outside', 480, 420]]) {
  const scene = new context.Scene(state());
  scene.openDrinkChoicePanel('lemonTea');
  scene.handleDrinkChoicePointer({ x, y });
  pointerCases.push({ name, x, y, ...drinkSnapshot(scene) });
}
const directPointerCases = [];
for (const control of ['takeButton', 'takeLabel', 'cancelButton', 'cancelLabel']) {
  const scene = new context.Scene(state());
  scene.openDrinkChoicePanel('blackCoffee');
  const handler = scene.drinkChoiceControls[control].handlers.pointerdown;
  let stopped = 0;
  handler({}, 0, 0, { stopPropagation() { stopped++; } });
  handler({}, 0, 0, { stopPropagation() { stopped++; } });
  directPointerCases.push({ control, stopped, ...drinkSnapshot(scene) });
}
const blockedOpenCases = [];
for (const blocker of ['menuPanel', 'mixerPanel', 'drinkChoicePanel']) {
  const scene = new context.Scene(state());
  scene[blocker] = record('existing');
  scene.openDrinkChoicePanel('lemonTea');
  blockedOpenCases.push({ blocker, nodesCreated: scene.nodes.length, events: copy(scene.events) });
}
const reopenScene = new context.Scene(state());
reopenScene.openDrinkChoicePanel('sparklingWater');
press(reopenScene, 'ArrowRight');
press(reopenScene, 'Escape');
reopenScene.openDrinkChoicePanel('blackCoffee');
const reopened = drinkSnapshot(reopenScene);
assert.equal(reopened.selection, 0);
assert.equal(reopened.events.length, 0);

const menuPresentations = {};
for (const mode of ['light', 'dark']) {
  const scene = new context.Scene(state({ hunt: { mode } }));
  scene.openMenuPanel();
  const panel = serialNode(scene.menuPanel);
  const onOpen = copy(scene.events);
  const optionRows = scene.menuPanel.children.filter(node => node.type === 'rectangle' && node.data.optionId)
    .map(node => ({ id: node.data.optionId, x: node.args[0], y: node.args[1], width: node.args[2], height: node.args[3] }));
  const selections = [];
  for (const row of optionRows) {
    scene.events.length = 0; scene.feedback.length = 0;
    scene.handleMenuPointer({ x: 480 + row.x, y: 270 + row.y });
    selections.push({ optionId: row.id, events: copy(scene.events), feedback: copy(scene.feedback) });
  }
  scene.events.length = 0; scene.feedback.length = 0;
  scene.handleMenuPointer({ x: 735, y: 102 });
  menuPresentations[mode] = { panel, optionRows, onOpen, selections,
    closed: scene.menuPanel === null, closeEvents: copy(scene.events), closeFeedback: copy(scene.feedback) };
}

function controllerScenario(name, initial, calls) {
  const controller = new context.Controller(initial);
  const steps = calls.map(([method, ...args]) => {
    const eventStart = controller.emitted.length, writesBefore = controller.writeCount;
    const result = controller[method](...args);
    return { method, args, result, writes: controller.writeCount - writesBefore,
      events: copy(controller.emitted.slice(eventStart)), state: copy(controller.state) };
  });
  return { name, initial: copy(initial), steps };
}
const bikeState = changes => state({ ...changes, hunt: { phase: 'chase_ready', ...changes?.hunt } });
const bikeScenarios = [
  controllerScenario('dark_inspect_repeat_and_clean_refusal', bikeState({ hunt: { mode: 'dark' } }),
    [['inspectBikeLock'], ['inspectBikeLock'], ['cleanBikeLock'], ['payForBike']]),
  controllerScenario('light_clean_pay_idempotence_without_code', bikeState(),
    [['inspectBikeLock'], ['payForBike'], ['cleanBikeLock'], ['cleanBikeLock'], ['inspectBikeLock'], ['payForBike'], ['payForBike'], ['startChase'], ['startChase']]),
  controllerScenario('wrong_phase', state(), [['inspectBikeLock'], ['cleanBikeLock'], ['payForBike'], ['startChase']]),
  controllerScenario('no_tissue', bikeState({ items: { greaseTissue: false } }), [['cleanBikeLock']]),
  controllerScenario('no_wages', bikeState({ hunt: { bikeLockCleaned: true }, items: { cafeteriaWages: false } }), [['payForBike']]),
  controllerScenario('insufficient_cash', bikeState({ hunt: { bikeLockCleaned: true }, cashCents: 199 }), [['payForBike']]),
  controllerScenario('dark_cleaned', bikeState({ hunt: { mode: 'dark', bikeLockCleaned: true } }), [['payForBike']]),
  controllerScenario('excess_cash_deducts_exact_fare', bikeState({ hunt: { bikeLockCleaned: true }, cashCents: 325 }), [['payForBike'], ['payForBike']]),
  controllerScenario('unpaid_cannot_start', bikeState(), [['startChase']]),
  controllerScenario('completed_cannot_restart', bikeState({ hunt: { bikePaid: true, chaseCompleted: true } }), [['startChase']]),
];
const menuScenarios = [
  ...content.menu.options.map(option => controllerScenario(`light_option_${option.id}`, state(), [['selectMenuOption', option.id], ['selectMenuOption', option.id]])),
  controllerScenario('dark_refuses_selection', state({ hunt: { mode: 'dark' } }), [['inspectMenuClue'], ['selectMenuOption', 'D']]),
  controllerScenario('active_order_refuses_selection', state({ hunt: { orderedMenuOption: 'A' } }), [['selectMenuOption', 'D']]),
  controllerScenario('existing_ticket_refuses_selection', state({ items: { pickupTicket0755: true } }), [['selectMenuOption', 'D']]),
  controllerScenario('invalid_option', state(), [['selectMenuOption', 'Z']]),
];
const drinkScenarios = [
  controllerScenario('collect_and_repeat', state(), [['collectDrink', 'sparklingWater'], ['collectDrink', 'sparklingWater']]),
  controllerScenario('promo_placed_refuses_collect', state({ hunt: { promoDrinkPlaced: true } }), [['collectDrink', 'lemonTea']]),
  controllerScenario('queue_gap_refuses_collect', state({ hunt: { queueGapOpened: true } }), [['collectDrink', 'lemonTea']]),
  controllerScenario('wrong_phase_refuses_collect', state({ hunt: { phase: 'chasing' } }), [['collectDrink', 'lemonTea']]),
];

const bikePresentations = [];
for (const mode of ['light', 'dark']) for (const bikeLockCleaned of [false, true]) {
  const scene = new context.Boot(bikeState({ hunt: { mode, bikeLockCleaned } }));
  scene.createCanteenBike();
  scene.createCanteenBikeModeLayer(scene.state);
  bikePresentations.push({ mode, bikeLockCleaned, bike: serialNode(scene.canteenBike),
    walletHint: scene.getCanteenBikeWalletHint(), codeGlow: serialNode(scene.canteenBikeCodeGlow),
    glare: serialNode(scene.canteenBikeGlare) });
}
const bikeRequests = [];
for (const [name, initial, offset] of [
  ['nearby', bikeState(), 0], ['boundary', bikeState(), 170], ['too_far', bikeState(), 171], ['wrong_phase', state(), 0],
]) {
  const scene = new context.Boot(initial);
  scene.player.x += offset;
  scene.requestCanteenBikeIfNearby();
  bikeRequests.push({ name, offset, events: copy(scene.events) });
}
const modeScene = new context.Boot(bikeState());
modeScene.createCanteenBikeModeLayer(modeScene.state);
const bikeModeTransitions = [];
for (const [mode, cleaned] of [['dark', false], ['light', false], ['light', true]]) {
  modeScene.state.canteenHunt.mode = mode;
  modeScene.state.canteenHunt.bikeLockCleaned = cleaned;
  modeScene.tweenCalls.length = 0;
  modeScene.applyCanteenBikeMode(mode);
  bikeModeTransitions.push({ mode, cleaned, codeGlowVisible: modeScene.canteenBikeCodeGlow.visible,
    glareVisible: modeScene.canteenBikeGlare.visible,
    tweens: modeScene.tweenCalls.map(({ targets, ...parameters }) => ({ targetType: targets.type, ...parameters })),
    events: copy(modeScene.events) });
}
const bikeAnimations = [];
for (const method of ['animateCanteenBikeCodeRead', 'animateCanteenBikeCleaned']) {
  const scene = new context.Boot(bikeState());
  scene.createCanteenBikeModeLayer(scene.state);
  const before = copy(scene.state);
  scene[method]();
  const tweens = scene.tweenCalls.map(({ targets, onComplete, ...parameters }) => ({
    targetType: targets.type, ...parameters, hasCompletionCallback: !!onComplete,
  }));
  scene.tweenCalls.forEach(tween => tween.onComplete?.());
  assert.deepEqual(copy(scene.state), before);
  bikeAnimations.push({ method, tweens, events: copy(scene.events),
    glareVisibleAfterCompletion: scene.canteenBikeGlare.visible, stateUnchanged: true });
}
const bikeDrops = [];
for (const [name, initial, itemId, offset, hasCoordinates] of [
  ['tissue', bikeState(), 'greaseTissue', 0, true], ['cash', bikeState(), 'cafeteriaWages', 0, true],
  ['boundary', bikeState(), 'greaseTissue', 100, true], ['outside', bikeState(), 'greaseTissue', 101, true],
  ['wrong_item', bikeState(), 'blackCoffee', 0, true], ['missing_coordinates', bikeState(), 'greaseTissue', 0, false],
  ['wrong_phase', state(), 'greaseTissue', 0, true],
]) {
  const scene = new context.Boot(initial);
  const payload = { itemId, ...(hasCoordinates ? { canvasX: campus.canteen.bike.x + offset, canvasY: campus.canteen.bike.y } : {}) };
  scene.handleCanteenInventoryDrop(payload);
  bikeDrops.push({ name, payload, events: copy(scene.events) });
}

// Guard the oracle itself against accidentally exercising only stub behavior.
assert.equal(keyboardCases[0].steps.at(-1).events.length, 0);
assert.equal(keyboardCases[3].steps.at(-1).events[0].id, 'rpg_canteen_drink_requested');
assert.equal(menuPresentations.dark.selections.every(row => row.events.length === 0 && row.feedback.length === 1), true);
const payment = bikeScenarios.find(row => row.name === 'light_clean_pay_idempotence_without_code').steps;
assert.deepEqual(payment.map(step => step.result), ['glare', 'rule', 'cleaned', 'cleaned', 'payment_ready', 'paid', 'paid', true, true]);
assert.equal(payment[3].writes, 0);
assert.equal(payment[6].writes, 0);
assert.equal(payment[6].state.wallet.cashCents, 0);
assert.equal(payment[6].state.items.greaseTissue, true);
assert.equal(payment[6].state.canteenHunt.bikeCodeRead, false);

const output = {
  schemaVersion: 1,
  execution: 'Extracted original TypeScript methods and constants; recording scene, store and event ports',
  sources: Object.fromEntries(files.map(file => [file, crypto.createHash('sha256').update(sources[file]).digest('hex')])),
  extracted,
  logicalViewport: { width: 960, height: 540 },
  drinkChoice: { presentations: drinkPresentations, keyboardCases, pointerCases, directPointerCases, blockedOpenCases, reopened },
  menu: { presentations: menuPresentations, controllerScenarios: menuScenarios },
  bike: { presentations: bikePresentations, modeTransitions: bikeModeTransitions, animations: bikeAnimations,
    inspectRequests: bikeRequests, inventoryDrops: bikeDrops, controllerScenarios: bikeScenarios },
  drinkControllerScenarios: drinkScenarios,
};
const target = path.join(nativeRoot, 'tests/fixtures/c3_canteen_devices_source.json');
const data = JSON.stringify(output, null, 2) + '\n';
if (process.argv.includes('--check')) {
  assert.equal(fs.readFileSync(target, 'utf8'), data, 'Canteen devices fixture is stale');
  console.log('C3 canteen devices fixture matches executed original TypeScript');
} else {
  fs.writeFileSync(target, data);
  console.log(target);
}
