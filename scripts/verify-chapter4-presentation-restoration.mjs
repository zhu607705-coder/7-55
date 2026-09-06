import assert from 'node:assert/strict';
import fs from 'node:fs';
import ts from 'typescript';

const file = 'src/scenes/rpg/ChapterFourTemporalMazeScene.ts';
const source = fs.readFileSync(file, 'utf8');
const ast = ts.createSourceFile(file, source, ts.ScriptTarget.Latest, true);
const scene = ast.statements.find(n => ts.isClassDeclaration(n) && n.name?.text === 'ChapterFourTemporalMazeScene');
const members = new Map(scene.members.filter(n => n.name).map(n => [n.name.getText(ast), n.getText(ast)]));
const layout = JSON.parse(fs.readFileSync('src/data/chapter4-three-floor-maze.layout.json', 'utf8'));
const content = JSON.parse(fs.readFileSync('src/data/chapter4-755.content.json', 'utf8'));
const loadMethod = (name, bindings = {}) => {
  const js = ts.transpile(`class Probe { ${members.get(name)} }`, { target: ts.ScriptTarget.ES2022 });
  return Function(...Object.keys(bindings), `${js}; return Probe.prototype.${name}`)(...Object.values(bindings));
};
let count = 0;
function check(name, run) { run(); count++; console.log(`PASS ${name}`); }
function sprite() {
  const obj = { active: true, x: 0, y: 0 };
  for (const method of ['stop', 'play', 'setTexture', 'setOrigin', 'setScale', 'setFlipX', 'setCrop', 'setDepth', 'setAlpha', 'setVisible', 'setVelocity', 'setTint', 'clearTint', 'setFrame']) {
    obj[method] = (...args) => { obj[method + 'Args'] = args; return obj; };
  }
  obj.setPosition = (x, y) => { obj.x = x; obj.y = y; return obj; };
  obj.destroy = () => { obj.active = false; };
  return obj;
}
const runtime = layout.maintenanceRuntime;
const base = { MAINTENANCE_RUNTIME: runtime, PLAYER_DEPTH_BASE: 1000, getFloor: () => ({ offsetX: 0 }) };

check('push uses authored character-only crop and left-facing pose', () => {
  const context = { add: { sprite }, phaseRuntimeObjects: [] };
  const result = loadMethod('ensureMaintenancePushCharacter', base).call(context);
  const crop = runtime.repairedPush.visibleCharacterCrop;
  assert.deepEqual(result.setCropArgs, [crop.x, crop.y, crop.width, crop.height]);
  assert.deepEqual(result.setFlipXArgs, [runtime.repairedPush.flipX]);
  assert.equal(context.phaseRuntimeObjects.length, 1);
  loadMethod('ensureMaintenancePushCharacter', base).call(context);
  assert.equal(context.phaseRuntimeObjects.length, 1, 'repeated attempt reuses the same character');
});
check('cart and cleaner move continuously with a shared offset', () => {
  const context = { maintenanceAttemptSprite: sprite(), maintenanceCart: sprite(), maintenanceCleaner: sprite() };
  loadMethod('positionMaintenancePushLayers', base).call(context, -33, 0);
  assert.equal(context.maintenanceCart.x, runtime.cleaningCart.position.x - 33);
  assert.equal(context.maintenanceCleaner.x, runtime.cleaner.position.x - 33);
  assert.equal(context.maintenanceAttemptSprite.x, runtime.repairedPush.from.x - 33);
});
check('chase does not spend grace or move the guard during power success', () => {
  const guard = sprite();
  const runtimeState = { elapsedMs: 0 };
  const context = { bridge: { getState: () => ({ chapter4: { phase: 'final_chase' } }) }, finalChaseState: runtimeState, chaseGuard: guard, storyPresentation: 'power_grid_success' };
  // Any attempt to reach normal chase calculations would fail without the rest of the scene.
  loadMethod('updateFinalChaseRuntime').call(context, 1320);
  assert.deepEqual(guard.setVelocityArgs, [0, 0]);
  assert.deepEqual(guard.setVisibleArgs, [false]);
  assert.equal(runtimeState.elapsedMs, 0);
});
check('power success is guarded, finishes once, and cleans all transient visuals', () => {
  const timers = [], events = [];
  const context = {
    bridge: { getState: () => ({ chapter4: { phase: 'final_chase', lightGrid: { locked: true, mask: 1 } } }) },
    storyPresentation: 'idle', player: sprite(), lightGridPanelSprite: sprite(),
    lightGridSuccessVisuals: [], lightGridSuccessTweens: [],
    clearStoryPresentationTimers() {}, ensureLightGridRuntime() {}, syncStoryInputLock() {},
    scheduleStoryPresentation(ms, callback) { timers.push({ ms, callback }); },
    safeBridgeEmit(name) { events.push(name); },
    add: { rectangle: sprite, text: sprite },
    tweens: { add: () => ({ stop() {} }) }
  };
  context.destroyLightGridSuccessVisuals = loadMethod('destroyLightGridSuccessVisuals').bind(context);
  const begin = loadMethod('beginPowerGridSuccessPresentation', {
    ...base, LIGHT_GRID_RUNTIME: layout.lightGridRuntime, chapterFourContent: content,
    hasChapterFourFact: () => true, RPG_PIXEL_FONT_FAMILY: 'test',
    rectCenterX: r => r.x + r.width / 2, rectCenterY: r => r.y + r.height / 2,
    rectBottom: r => r.y + r.height
  }).bind(context);
  begin(); begin();
  assert.equal(events.filter(n => n.endsWith('_started')).length, 1);
  assert.equal(timers.filter(t => t.ms === 1320).length, 1);
  timers.sort((a, b) => a.ms - b.ms).forEach(t => t.callback());
  assert.equal(context.storyPresentation, 'idle');
  assert.equal(events.filter(n => n.endsWith('_completed')).length, 1);
  assert.equal(context.lightGridSuccessVisuals.length, 0);
  assert.equal(context.lightGridSuccessTweens.length, 0);
});
check('sign-in fixtures retain separate reader and paper slot artwork', () => {
  const paints = [];
  const graphics = new Proxy({}, { get: (_, name) => (...args) => { paints.push([name, ...args]); return graphics; } });
  const paint = loadMethod('paintMorningCheckinFixture', { Phaser: { Geom: { Point: class { constructor(x,y) { this.x=x; this.y=y; } } } } });
  paint.call({}, 'a1_campus_card_reader', graphics, { left: 100, top: 100, width: 30, height: 28 }, false);
  const reader = JSON.stringify(paints);
  paints.length = 0;
  paint.call({}, 'a1_attendance_paper_slot', graphics, { left: 100, top: 100, width: 30, height: 28 }, true);
  assert.notEqual(reader, JSON.stringify(paints));
  assert.ok(paints.filter(p => p[0] === 'fillRect').length > 5);
});
check('wall face follows the foot crossing and restores opacity on the front side', () => {
  const shade = loadMethod('syncWallFaceOcclusion', { PLAYER_TOP_DEPTH: 9900, PLAYER_DEPTH_BASE: 4000 });
  for (const definition of layout.floors.find(f => f.storyFloor === 'A1').foregroundOcclusions.filter(f => f.playerRevealAlpha !== undefined)) {
    const image = sprite();
    const context = { currentFloor: 1, player: { body: { bottom: definition.baselineY - 1 } }, appliedForegrounds: [{ ...definition, floor: 1, image }] };
    shade.call(context);
    assert.deepEqual(image.setDepthArgs, [9901], 'wall overlaps only the portion of the player behind it');
    assert.deepEqual(image.setAlphaArgs, [.78], 'the authored wall reveals 22 percent of covered body pixels');
    context.player.body.bottom = definition.baselineY + 1;
    shade.call(context);
    assert.deepEqual(image.setDepthArgs, [4000 + definition.baselineY]);
    assert.deepEqual(image.setAlphaArgs, [1]);
  }
});
check('foreground staging preserves the reveal field and explicitly selects the full map frame', () => {
  const calls = [];
  const context = {
    injectPlateTransactionFault() {}, destroyForegrounds() {},
    add: { image(...args) {
      calls.push(args);
      return {
        visible: true, isCropped: false, texture: { key: args[2] }, depth: 0,
        setOrigin() { return this; },
        setCrop() { this.isCropped = true; return this; },
        setDepth(value) { this.depth = value; return this; },
        setVisible(value) { this.visible = value; return this; }
      };
    } }
  };
  const definition = { id: 'wall', floor: 1, plateId: 'a1_1225_bakery', localBounds: { x: 43, y: 134, width: 496, height: 130 }, worldBounds: { x: 43, y: 134, width: 496, height: 130 }, baselineY: 264, playerRevealAlpha: .22 };
  const result = loadMethod('stagePlateForegrounds', { PLAYER_DEPTH_BASE: 4000, getFloor: () => ({ offsetX: 0 }) }).call(context, [definition]);
  assert.equal(calls[0][3], '__BASE', 'adding door-leaf crop frames must not change the foreground image');
  assert.equal(result[0].playerRevealAlpha, .22);
});
check('entry snapshots only loaded floors and retains the exact frame for rollback', () => {
  const image = { texture: { key: 'a1_2245_opening' }, frame: { name: '__BASE' } };
  const context = { backgrounds: new Map([[1, image]]) };
  const snapshots = loadMethod('snapshotBackgroundTextures', { FLOORS: [{ displayFloor: 1 }, { displayFloor: 2 }, { displayFloor: 3 }] }).call(context);
  assert.equal(snapshots.length, 1);
  assert.equal(snapshots[0].image, image);
  assert.equal(snapshots[0].frameName, '__BASE');
});
check('staged warmup does not report unloaded sprite sheets as corrupt', () => {
  const failures = new Set();
  const validate = loadMethod('validateFrameRegistrationReport', {
    CHAPTER_FOUR_755_SPRITESHEETS: { first: { id: 'first' }, later: { id: 'later' } },
    CHAPTER_FOUR_755_MANIFEST_FRAME_COUNT: 62, EXPECTED_MANIFEST_ENTRY_COUNT: 62, EXPECTED_EMPTY_FRAME_COUNT: 1
  });
  const context = { persistentContractFailures: failures, textures: { exists: id => id === 'first' } };
  const partial = { contractFailures: [], manifestFrameCount: 8, registeredFrameCount: 8, reusedFrameCount: 0, skippedEmptyFrameCount: 0 };
  validate.call(context, partial);
  assert.equal(failures.size, 0);
  context.textures.exists = () => true;
  validate.call(context, partial);
  assert(failures.size > 0, 'a fully loaded but incomplete atlas must still fail');
});
check('bakery conveyor and its controls render above the opaque counter crop', () => {
  const floor = { ...layout.floors.find(f => f.storyFloor === 'A1'), offsetX: 0 };
  const created = [];
  const make = (...args) => {
    const object = sprite();
    object.setStrokeStyle = () => object;
    object.setOrigin = () => object;
    object.setDepth = value => { object.depth = value; return object; };
    created.push(object);
    return object;
  };
  const context = {
    destroyBakeryConveyorFixture() {}, ensureBakeryConveyorTileTexture() {}, setBakeryConveyorMotion() {},
    bakeryConveyorFixtureObjects: [], tweens: { add() { return {}; } },
    add: { rectangle: make, tileSprite: make, circle: make, container: make, triangle: make }
  };
  const bindings = {
    BAKERY_RUNTIME: layout.bakeryRuntime, PLAYER_DEPTH_BASE: 4000,
    BAKERY_CONVEYOR_TILE_TEXTURE: 'belt', getFloor: () => floor,
    rectBottom: r => r.y + r.height, rectRight: r => r.x + r.width,
    rectCenterX: r => r.x + r.width / 2, rectCenterY: r => r.y + r.height / 2
  };
  if (members.has('bakeryCounterSurfaceDepth')) context.bakeryCounterSurfaceDepth = loadMethod('bakeryCounterSurfaceDepth', bindings).bind(context);
  loadMethod('createBakeryConveyorFixture', bindings).call(context);
  const counterDepth = 4000 + floor.foregroundOcclusions.find(f => f.id === layout.bakeryRuntime.baker.foregroundOcclusionId).baselineY;
  for (const object of context.bakeryConveyorFixtureObjects) {
    assert(object.depth > counterDepth, 'counter must not redraw over a conveyor part');
    assert(object.depth < 9900, 'counter fixture must not redraw over the player');
  }
});
console.log(`Chapter 4 presentation restoration: ${count}/${count} passed`);
