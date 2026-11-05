#!/usr/bin/env node
// Local observability contracts, not evidence of a Godot browser acceptance pass.
import assert from 'node:assert/strict';
import {test} from 'node:test';
import {mkdtempSync, readFileSync, writeFileSync, mkdirSync, rmSync} from 'node:fs';
import {tmpdir} from 'node:os';
import path from 'node:path';
import {spawn} from 'node:child_process';
import {once} from 'node:events';
import vm from 'node:vm';
import {continuousExercise, createPhoneProgress, phoneRecoveryCase} from '../tools/web_phone_recovery.mjs';
import {assertPhoneCoverage} from '../tools/web_phone_shards.mjs';

function output(t) {
  const dir = mkdtempSync(path.join(tmpdir(), '755-phone-progress-test-'));
  t.after(() => rmSync(dir, {recursive: true, force: true}));
  return path.join(dir, 'phone-progress.jsonl');
}
function writer(filename, extra = {}) {
  return createPhoneProgress({filename, id: 'retina-touch-390', group: 'c2-tiyi', touch: true, dpr: 3, ...extra});
}
const rows = filename => readFileSync(filename, 'utf8').trim().split('\n').filter(Boolean).map(JSON.parse);
function quietErrors(t) {
  const errors = [], original = console.error;
  console.error = (...args) => errors.push(args.join(' '));
  t.after(() => {console.error = original;});
  return errors;
}

function fixture({touch = true, change = '', rejectCheckpoint = false, failMove = false} = {}) {
  let completed = 0, moves = 0, renders = 0, clock = 0;
  const rect = {x: 11, y: 30, width: 430, height: 820};
  const viewport = {width: 430, height: 860};
  const events = [], waits = [], checks = [], evidence = {inputs: [], samples: []};
  const rendered = p => ({x: 7 + p.x * .8, y: 13 + p.y * .6});
  const snapshot = () => ({activeGame: {script: 'res://scripts/games/virtual_run.gd', rect: {...rect}}, viewport: {...viewport},
    visibleControls: [{name: 'RunProgress', text: `${completed} / 10`}, ...(completed === 10 ? [{name: 'ReturnToTiyi'}] : [])],
    state: {actOne: {exerciseStarted: completed === 10}}});
  let traceStart = 0;
  const h = {id: 'fixture', touch, monotonicNow: () => clock, async observeExercise(action) {
    if (action === 'begin') {traceStart = events.length; return true;}
    return {events: events.slice(traceStart).map(e => ({...e, trusted: true, identifier: touch ? 4 : null, buttons: touch ? null : e.phase === 'end' ? 0 : 1})), overflow: false, cancelled: false};
  }, async snapshot() {return snapshot();},
    check(ok, label) {checks.push(label); assert.ok(ok, label);},
    async renderPoint(point) {renders++; const p = rendered(point); if (change === 'canvas' && moves >= 8) p.x += 1; return p;},
    async pointer(phase, point) {
      events.push({phase, ...point});
      if (phase === 'move') {
        moves++;
        if (change === 'viewport' && moves === 8) viewport.width += 1;
        if (change === 'gameRect' && moves === 8) rect.x += 1;
        if (failMove && moves === 3) throw Error('synthetic CDP transport failure');
      }
    },
    async interval(ms) {clock += ms; waits.push(ms);},
    async poll(fn, label) {
      if (label.startsWith('continuous pointer traversal')) {
        if (rejectCheckpoint) throw Error('actual authority did not accept checkpoint');
        completed++;
      }
      const value = await fn(); assert.ok(value, label); return value;
    }};
  return {h, evidence, events, waits, checks, rendered, rect, get renders() {return renders;}};
}

for (const touch of [true, false]) await test(`progress retains the exact ${touch ? 'touch' : 'mouse'} input, observation, geometry and read sequence`, async t => {
  const run = async progress => {
    const f = fixture({touch}), calls = [];
    for (const name of ['pointer', 'interval', 'observeExercise', 'snapshot', 'renderPoint', 'poll', 'check']) {
      const original = f.h[name];
      f.h[name] = (...args) => {calls.push([name, ...args.map(arg => typeof arg === 'function' ? '<callback>' : structuredClone(arg))]); return original(...args);};
    }
    f.h.progress = progress;
    await continuousExercise(f.h, f.evidence);
    return {f, calls};
  };
  const filename = output(t), baseline = await run(), observed = await run(writer(filename, {touch}));
  assert.deepEqual(observed.calls, baseline.calls);
  assert.equal(observed.f.events.filter(event => event.phase === 'move').length, 399);
  assert.deepEqual(observed.f.waits, Array(399).fill(80));
  const log = rows(filename), starts = log.filter(row => row.event === 'exercise-segment-start');
  const ends = log.filter(row => row.event === 'exercise-segment-finished');
  const boundaries = log.filter(row => row.event === 'exercise-input-boundary');
  assert.equal(starts.length, 10); assert.equal(ends.length, 10); assert.equal(boundaries.length, 49);
  assert.equal(log.length, 69); assert.ok(readFileSync(filename).length < 128 * 4096);
  assert.ok(log.every(row => row.complete === false && row.diagnosticOnly === true && row.dpr === 3));
  assert.ok(log.every(row => !('sent' in row.exercise) && !('observed' in row.exercise)));
  assert.ok(boundaries.every(row => row.exercise.pointerMoves % 8 === 0 && row.exercise.maxInFlight === 1));
  assert.ok(ends.every(row => row.exercise.pointerAck.end.acknowledged === 1 && row.exercise.sentCount === row.exercise.observedCount));
  assert.throws(() => assertPhoneCoverage(log.at(-1), 'c2-tiyi'), /Incomplete/);
});

await test('writer truncates stale diagnostic data and enforces a sticky 128-record bound', t => {
  const filename = output(t); writeFileSync(filename, 'stale success\n');
  const progress = writer(filename), errors = quietErrors(t);
  for (let i = 0; i < 128; i++) progress('boundary');
  assert.equal(rows(filename).length, 128); assert.equal(rows(filename)[0].sequence, 1);
  assert.throws(() => progress('overflow'), /record limit 128/);
  assert.throws(() => progress('still failed'), /record limit 128/);
  assert.equal(rows(filename).length, 128); assert.equal(errors.length, 1);
});

await test('writer bounds individual records and propagates initialization and append errors', t => {
  const filename = output(t), errors = quietErrors(t);
  const progress = writer(filename);
  assert.throws(() => progress('x'.repeat(4096)), /record byte limit 4096/);
  assert.equal(readFileSync(filename, 'utf8'), '');
  const next = writer(filename); rmSync(filename); mkdirSync(filename);
  assert.throws(() => next('append fails'), /diagnostic write failed/);
  rmSync(filename, {recursive: true});
  assert.throws(() => next('remains failed'), /diagnostic write failed/);
  assert.throws(() => writer(path.join(filename, 'missing', 'progress.jsonl')), /diagnostic write failed/);
  assert.equal(errors.length, 3);
});

await test('large in-memory traces serialize only counts and bounded summary fields', async t => {
  const f = fixture(); await continuousExercise(f.h, f.evidence);
  const timing = f.evidence.exerciseTransport[0], filename = output(t), progress = writer(filename);
  timing.sent = Array(10000).fill({payload: 'x'.repeat(1000)});
  timing.observed.events = Array(10000).fill({payload: 'x'.repeat(1000)});
  timing.releaseError = 'e'.repeat(10000); timing.observationError = 'e'.repeat(10000);
  progress('exercise-segment-failed', timing);
  const row = rows(filename)[0];
  assert.equal(row.exercise.sentCount, 10000); assert.equal(row.exercise.observedCount, 10000);
  assert.equal(row.exercise.releaseError.length, 256); assert.equal(row.exercise.observationError.length, 256);
  assert.ok(readFileSync(filename).length < 4096);
});

await test('boundary write failure stops subsequent moves and still releases exactly once', async t => {
  const f = fixture(), filename = output(t), progress = writer(filename), errors = quietErrors(t);
  f.h.progress = (event, timing) => {
    if (event === 'exercise-input-boundary') {rmSync(filename); mkdirSync(filename);}
    progress(event, timing);
  };
  await assert.rejects(continuousExercise(f.h, f.evidence), /diagnostic write failed/);
  assert.equal(f.events.filter(event => event.phase === 'move').length, 8);
  assert.equal(f.events.filter(event => event.phase === 'end').length, 1);
  assert.equal(f.evidence.samples.length, 0); assert.ok(errors.length >= 1);
});

await test('a secondary final diagnostic failure does not mask the first CDP error', async t => {
  const f = fixture({failMove: true}), errors = quietErrors(t);
  f.h.progress = event => {if (event === 'exercise-segment-failed') throw Error('secondary disk failure');};
  await assert.rejects(continuousExercise(f.h, f.evidence), /synthetic CDP transport failure/);
  assert.equal(f.events.filter(event => event.phase === 'move').length, 3);
  assert.equal(f.events.filter(event => event.phase === 'end').length, 1);
  assert.match(errors[0], /secondary disk failure/);
});

await test('segment-start and final-only diagnostic failures cannot produce exercise acceptance', async t => {
  quietErrors(t);
  for (const phase of ['exercise-segment-start', 'exercise-segment-finished']) {
    const f = fixture();
    f.h.progress = event => {if (event === phase) throw Error('disk failure');};
    await assert.rejects(continuousExercise(f.h, f.evidence), /disk failure/);
    assert.equal(f.evidence.exerciseTransport.length, 1);
    assert.equal(f.events.filter(event => event.phase === 'end').length, phase === 'exercise-segment-start' ? 0 : 1);
  }
});

await test('C2 import milestone failure leaves coverage incomplete and does not dispatch input', async t => {
  let evidence, imports = 0; const filename = output(t), progress = writer(filename);
  await assert.rejects(phoneRecoveryCase({group: 'c2-tiyi', fixtureDir: '/synthetic', progress,
    record(value) {evidence = value;}, async importSave() {imports++; throw Error('ordinary import failed');}}), /ordinary import failed/);
  assert.equal(imports, 1); assert.equal(evidence.completed, false);
  assert.deepEqual(rows(filename).map(row => row.event), ['c2-import-start']);
  assert.throws(() => assertPhoneCoverage(evidence, 'c2-tiyi'), /Incomplete/);
});

await test('hard-killed stalled exercise retains a complete JSONL prefix, never an acceptance file', {timeout: 10000}, async t => {
  const filename = output(t), moduleUrl = new URL('../tools/web_phone_recovery.mjs', import.meta.url).href;
  const source = `import assert from 'node:assert/strict';
    import {continuousExercise, createPhoneProgress} from ${JSON.stringify(moduleUrl)};
    const fixture = ${fixture.toString()}; const f = fixture();
    f.h.progress = createPhoneProgress({filename: ${JSON.stringify(filename)}, id: 'fixture', group: 'c2-tiyi', touch: true, dpr: 3});
    const pointer = f.h.pointer; let moves = 0;
    f.h.pointer = async (phase, point) => {
      if (phase === 'move' && ++moves === 9) {process.stdout.write('stalled\\n'); await new Promise(() => {});}
      return pointer(phase, point);
    };
    process.stdin.resume(); await continuousExercise(f.h, f.evidence);`;
  const child = spawn(process.execPath, ['--input-type=module', '-e', source], {stdio: ['pipe', 'pipe', 'pipe']});
  t.after(() => {if (child.exitCode === null && child.signalCode === null) child.kill('SIGKILL');});
  let stderr = ''; child.stderr.on('data', chunk => {stderr += chunk;});
  const closed = once(child, 'close');
  const first = await Promise.race([once(child.stdout, 'data'), closed.then(() => {throw Error(`child exited early: ${stderr}`);})]);
  assert.equal(String(first[0]), 'stalled\n');
  child.kill('SIGKILL'); const [code, signal] = await closed;
  assert.equal(code, null); assert.equal(signal, 'SIGKILL');
  const log = rows(filename);
  assert.deepEqual(log.map(row => row.event), ['exercise-segment-start', 'exercise-input-boundary']);
  assert.equal(log[1].exercise.pointerAck.move.acknowledged, 8);
  assert.equal(log[1].exercise.inputWaitMs, 640);
  assert.ok(log.every(row => row.complete === false && row.diagnosticOnly));
  assert.throws(() => readFileSync(path.join(path.dirname(filename), 'web-acceptance.json')), /ENOENT/);
});

await test('CDP cursor only observes existing sends, ACKs, timeouts and closure', async () => {
  const source = readFileSync(new URL('../tools/verify_web_export.mjs', import.meta.url), 'utf8');
  const code = source.slice(source.indexOf('async function connect('), source.indexOf('async function enableNetworkObservation('));
  const sent = [], timers = [], cancelled = [], events = []; let socket;
  class WebSocket {
    constructor() {socket = this; this.listeners = new Map();}
    addEventListener(name, fn) {this.listeners.set(name, fn); if (name === 'open') queueMicrotask(fn);}
    send(value) {sent.push(JSON.parse(value));}
    close() {this.listeners.get('close')();}
    response(value) {this.listeners.get('message')({data: JSON.stringify(value)});}
  }
  const connect = vm.runInNewContext(`${code}; connect`, {WebSocket, Date, Error, setTimeout(fn, ms) {timers.push({fn, ms}); return timers.length;}, clearTimeout(id) {cancelled.push(id);}});
  const cdp = await connect('ws://synthetic', event => events.push(event));
  const snapshot = () => JSON.parse(JSON.stringify(cdp.progress()));
  assert.deepEqual(snapshot(), {lastInitiated: null, lastCompleted: null, pending: 0});
  const first = cdp.send('Input.dispatchTouchEvent', {type: 'touchMove'});
  assert.equal(snapshot().lastInitiated.method, 'Input.dispatchTouchEvent'); assert.equal(snapshot().pending, 1);
  assert.equal(timers[0].ms, 30000); assert.equal(sent.length, 1);
  socket.response({id: 1, result: {ok: true}}); assert.deepEqual(JSON.parse(JSON.stringify(await first)), {ok: true});
  assert.equal(snapshot().lastCompleted.status, 'acknowledged'); assert.equal(snapshot().pending, 0);
  const second = cdp.send('Runtime.evaluate', {expression: 'existing read'}, 8000);
  const secondFailure = assert.rejects(second, /CDP timeout Runtime.evaluate/); timers[1].fn(); await secondFailure;
  assert.equal(snapshot().lastCompleted.status, 'timeout'); assert.equal(timers[1].ms, 8000);
  const third = cdp.send('Page.captureScreenshot'); const thirdFailure = assert.rejects(third, /server failure/);
  socket.response({id: 3, error: {message: 'server failure'}}); await thirdFailure;
  assert.equal(snapshot().lastCompleted.status, 'failed');
  socket.response({method: 'Network.loadingFinished', params: {requestId: 'original'}});
  assert.equal(events.length, 1); assert.equal(sent.length, 3);
  const fourth = cdp.send('Runtime.evaluate'); const fourthFailure = assert.rejects(fourth, /CDP closed/);
  cdp.close(); await fourthFailure;
  assert.equal(snapshot().lastCompleted.status, 'closed'); assert.equal(snapshot().pending, 0);
  assert.equal(sent.length, 4); assert.equal(timers.length, 4); assert.deepEqual(cancelled, [1, 3, 4]);
});
