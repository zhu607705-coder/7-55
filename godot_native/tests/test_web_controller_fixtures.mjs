// Synthetic orchestration contracts only: no engine, browser, or network runs.
import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import {EventEmitter} from 'node:events';
import {test} from 'node:test';
import {prepareWebControllerFixtures, validateControllerReport, mergeControllerFiles} from '../tools/prepare_web_controller_fixtures.mjs';

function report(library = false) {
  return {kind: 'continuous-native-controller-campaign', completedChapters: library ? [1, 2] : [1, 2, 3, 4],
    failures: 0, checks: library ? 136 : 1160, notManualPlaythrough: true, spatialSetupExplicit: true};
}
function save(state) {return {format: '7-55-godot-native', version: 1, sourceVersion: 36, state};}
function outputs(spec) {
  const capture = spec.env.CONTINUITY_CAPTURE_DIR || spec.env.LIBRARY_CAPTURE_DIR;
  const write = (name, value) => fs.writeFileSync(path.join(capture, name), JSON.stringify(value));
  const library = Boolean(spec.env.LIBRARY_CAPTURE_DIR);
  fs.writeFileSync(spec.env.CAMPAIGN_REPORT, JSON.stringify(report(library)));
  if (library) {
    for (const name of ['before_library_rule_read.json', 'before_library_022_opening.json']) write(name, save({native: {chapter: 2}}));
  } else {
    write('before_c1_plant_light.json', save({native: {chapter: 1, page: 'phone_home'},
      flags: {plantWatered: true, plantFertilized: true, plantLit: false, flowerBloomed: false, checkinDone: false},
      phoneBattery: {percent: 75}, ui: {brightness: 40}, actOne: {tiyiUpdateStage: 'not_started'}}));
    write('before_c1_tiyi_digit.json', save({native: {chapter: 1}, flags: {tiyiCountTaken: false}, digits: {d2: null}}));
    write('before_c2_tiyi_update.json', save({native: {chapter: 2}, actOne: {phase: 'movement_required', tiyiUpdateStage: 'not_started', exerciseStarted: false, weatherWaterTaken: false}}));
    for (const name of ['before_c2_dorm_exit.json', 'after_c2_dorm_exit.json']) write(name, save({native: {chapter: 2}}));
  }
}

function fixture(t, behavior = () => {}) {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), '755-web-controller-contract-'));
  t.after(() => fs.rmSync(root, {recursive: true, force: true}));
  const project = path.join(root, 'project'); fs.mkdirSync(project);
  const output = path.join(project, 'exports/verification/controller-earned');
  const sourceFile = path.join(root, 'source.json');
  const source = {event: 'pull_request', head: 'a'.repeat(40), base: 'b'.repeat(40), checkedOutCommit: 'c'.repeat(40),
    tree: 'd'.repeat(40), run: '100', attempt: '1', dirty: false};
  fs.writeFileSync(sourceFile, JSON.stringify(source));
  const spawned = [], sandboxes = [], events = [];
  let released = false, lockHeld = false;
  const createSandbox = (_project, prefix) => {
    const sandbox = path.join(root, `${prefix}${sandboxes.length}`); fs.mkdirSync(sandbox);
    sandboxes.push(sandbox);
    return {root: sandbox, project, env: {XDG_DATA_HOME: `${sandbox}/data`, XDG_CONFIG_HOME: `${sandbox}/config`,
      XDG_CACHE_HOME: `${sandbox}/cache`, XDG_STATE_HOME: `${sandbox}/state`}};
  };
  const spawnProcess = (executable, command, options) => {
    const index = spawned.length;
    const child = new EventEmitter(); child.stdout = new EventEmitter(); child.stderr = new EventEmitter();
    const spec = {executable, command, env: options.env, child, index, closed: false, signals: []};
    child.kill = signal => {
      spec.signals.push(signal); events.push(`kill:${index}:${signal}`);
      if (!spec.ignoreTerm || signal === 'SIGKILL') setTimeout(() => spec.close(null, signal), 3);
      return true;
    };
    spec.close = (status = 0, signal = null) => {
      if (spec.closed) return;
      spec.closed = true; events.push(`close:${index}`); child.emit('close', status, signal);
    };
    spawned.push(spec); events.push(`spawn:${index}`);
    behavior(spec, {spawned, output, events, root});
    return child;
  };
  const options = {project, output, sourceFile, createSandbox, spawnProcess, log: () => {}, cancellationGraceMs: 10,
    acquireLock: () => {lockHeld = true; return () => {released = true; events.push('release');};}};
  return {root, project, output, source, sourceFile, spawned, sandboxes, events, options,
    released: () => released, lockHeld: () => lockHeld};
}

await test('both original recorders start concurrently with independent saves/captures; merged provenance retains exact source', async t => {
  const f = fixture(t, (spec, state) => {
    setTimeout(() => {
      assert.equal(state.spawned.length, 2, 'second process starts without waiting for the first');
      outputs(spec); spec.child.stdout.emit('data', Buffer.from('CONTINUOUS CAMPAIGN failures=0\n')); spec.close();
    }, spec.index === 0 ? 12 : 2);
  });
  const provenance = await prepareWebControllerFixtures(f.options);
  assert.deepEqual(f.events.slice(0, 2), ['spawn:0', 'spawn:1']);
  assert.deepEqual(f.spawned.map(s => s.command.at(-1)), ['res://tests/campaign_continuity_recorder.gd', 'res://tests/library_continuity_recorder.gd']);
  assert.notEqual(f.spawned[0].env.CONTINUITY_CAPTURE_DIR, f.spawned[1].env.LIBRARY_CAPTURE_DIR);
  for (const key of ['XDG_DATA_HOME', 'XDG_CONFIG_HOME', 'XDG_CACHE_HOME', 'XDG_STATE_HOME']) assert.notEqual(f.spawned[0].env[key], f.spawned[1].env[key]);
  assert.deepEqual(provenance.source, f.source); assert.equal(provenance.checks, 1160); assert.equal(provenance.libraryInputs.checks, 136);
  assert.equal(provenance.phoneRecoveryInputs.variants.length, 2);
  assert.deepEqual(provenance.libraryInputs.fixtures.map(v => v.fixture), ['before_library_rule_read.json', 'before_library_022_opening.json']);
  assert.deepEqual(JSON.parse(fs.readFileSync(path.join(f.output, 'fixture-provenance.json'))), provenance);
  assert.ok(fs.existsSync(`${f.output}-diagnostics/campaign/controller-campaign.log`));
  assert.ok(fs.existsSync(`${f.output}-diagnostics/library/library-controller-report.json`));
  assert.ok(f.released()); assert.ok(f.sandboxes.every(dir => !fs.existsSync(dir)));
  assert.ok(f.events.indexOf('release') > f.events.indexOf('close:0'));
  assert.ok(f.events.indexOf('release') > f.events.indexOf('close:1'));
});

for (const mode of ['exit', 'script-error', 'invalid-report', 'spawn-event-error', 'spawn-throw', 'SIGKILL']) {
  await test(`${mode}: failed recorder cancels and joins its live peer before cleaning; no certified output`, async t => {
    const f = fixture(t, (spec) => {
      if (mode === 'spawn-throw' && spec.index === 1) throw Error('spawn failed synchronously');
      if (mode === 'SIGKILL' && spec.index === 0) spec.ignoreTerm = true;
      if (spec.index === 0) return; // peer stays live until cancellation
      setTimeout(() => {
        outputs(spec);
        if (mode === 'script-error') spec.child.stderr.emit('data', 'SCRIPT ERROR: synthetic failure\n');
        if (mode === 'invalid-report') fs.writeFileSync(spec.env.CAMPAIGN_REPORT, JSON.stringify({...report(true), failures: 1}));
        if (mode === 'spawn-event-error') spec.child.emit('error', Error('synthetic process error'));
        spec.close(['exit', 'SIGKILL'].includes(mode) ? 1 : 0);
      }, 2);
    });
    // Keep a referenced test timer while the fake child awaits kill escalation;
    // the real child process itself holds the event loop in production.
    const keepAlive = setInterval(() => {}, 100);
    try {await assert.rejects(prepareWebControllerFixtures(f.options));} finally {clearInterval(keepAlive);}
    assert.equal(fs.existsSync(f.output), false);
    assert.ok(f.spawned[0].closed); assert.ok(f.spawned[0].signals.includes('SIGTERM'));
    if (mode === 'SIGKILL') assert.ok(f.spawned[0].signals.includes('SIGKILL'));
    assert.ok(f.released()); assert.ok(f.sandboxes.every(dir => !fs.existsSync(dir)));
    assert.ok(f.events.indexOf('release') > f.events.indexOf('close:0'));
  });
}

await test('duplicate capture output is rejected before any final output exists', async t => {
  const f = fixture(t, spec => setTimeout(() => {
    outputs(spec);
    const capture = spec.env.CONTINUITY_CAPTURE_DIR || spec.env.LIBRARY_CAPTURE_DIR;
    fs.writeFileSync(path.join(capture, 'collision.json'), '{}'); spec.close();
  }, 1));
  await assert.rejects(prepareWebControllerFixtures(f.options), /collision/);
  assert.equal(fs.existsSync(f.output), false); assert.ok(f.released());
});

await test('invalid phone input cannot leave success provenance or partial final fixtures', async t => {
  const f = fixture(t, spec => setTimeout(() => {outputs(spec); spec.close();}, 1));
  await assert.rejects(prepareWebControllerFixtures({...f.options, preparePhoneInputs: () => {throw Error('phone inputs invalid');}}), /phone inputs invalid/);
  assert.equal(fs.existsSync(f.output), false);
  assert.equal(fs.existsSync(`${f.output}-diagnostics/validated-merge`), false);
});

await test('external cancellation terminates and joins both recorders, even if they would otherwise pass', async t => {
  const f = fixture(t, spec => {
    if (spec.index === 1) setTimeout(() => process.emit('SIGTERM'), 1);
  });
  const before = process.listenerCount('SIGTERM');
  await assert.rejects(prepareWebControllerFixtures(f.options), /cancelled: SIGTERM/);
  assert.equal(fs.existsSync(f.output), false);
  assert.ok(f.spawned.every(spec => spec.closed && spec.signals.includes('SIGTERM')));
  assert.equal(process.listenerCount('SIGTERM'), before);
  assert.ok(f.released());
});

await test('missing portable boundary fails after both successful processes without finalizing', async t => {
  const f = fixture(t, spec => setTimeout(() => {
    outputs(spec);
    if (spec.index === 1) fs.unlinkSync(path.join(spec.env.LIBRARY_CAPTURE_DIR, 'before_library_022_opening.json'));
    spec.close();
  }, 1));
  await assert.rejects(prepareWebControllerFixtures(f.options), /before_library_022_opening/);
  assert.equal(fs.existsSync(f.output), false); assert.ok(f.released());
});

await test('busy workspace fails before spawning or creating stale diagnostic output', async t => {
  const f = fixture(t);
  await assert.rejects(prepareWebControllerFixtures({...f.options, acquireLock: () => {throw Error('busy');}}), /busy/);
  assert.equal(f.spawned.length, 0); assert.equal(fs.existsSync(`${f.output}-diagnostics`), false);
});

await test('stale final output is never overwritten or silently certified', async t => {
  const f = fixture(t); fs.mkdirSync(f.output, {recursive: true});
  fs.writeFileSync(path.join(f.output, 'old.json'), 'old');
  await assert.rejects(prepareWebControllerFixtures(f.options), /already exists/);
  assert.equal(f.spawned.length, 0); assert.equal(fs.readFileSync(path.join(f.output, 'old.json'), 'utf8'), 'old');
});

await test('report validation retains every original success gate and strict positive check counts', () => {
  assert.deepEqual(validateControllerReport(report()), report()); assert.deepEqual(validateControllerReport(report(true), true), report(true));
  for (const mutate of [r => {r.failures = 1;}, r => {r.checks = 0;}, r => {r.checks = -1;}, r => {r.checks = 1.1;},
    r => {r.kind = 'different';}, r => {r.notManualPlaythrough = false;}, r => {r.spatialSetupExplicit = false;}]) {
    const value = report(); mutate(value); assert.throws(() => validateControllerReport(value));
  }
  assert.throws(() => validateControllerReport({...report(true), completedChapters: [1]}, true));
  assert.throws(() => validateControllerReport(null));
});

await test('merge rejects links, directories, reserved generated names, and duplicate files before copying', t => {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), '755-controller-merge-'));
  t.after(() => fs.rmSync(root, {recursive: true, force: true}));
  for (const mode of ['link', 'directory', 'receipt', 'derived', 'compat', 'duplicate']) {
    const first = path.join(root, `${mode}-first`), second = path.join(root, `${mode}-second`), destination = path.join(root, `${mode}-out`);
    fs.mkdirSync(first); fs.mkdirSync(second);
    fs.writeFileSync(path.join(first, 'valid.json'), '{}');
    if (mode === 'link') fs.symlinkSync(path.join(first, 'valid.json'), path.join(second, 'link.json'));
    else if (mode === 'directory') fs.mkdirSync(path.join(second, 'directory.json'));
    else fs.writeFileSync(path.join(second, {receipt: 'fixture-provenance.json', derived: 'phone-recovery-inputs.json', compat: 'compat-c1.json', duplicate: 'valid.json'}[mode]), '{}');
    assert.throws(() => mergeControllerFiles([first, second], destination)); assert.equal(fs.existsSync(destination), false);
  }
});
