#!/usr/bin/env node
// Test-driver geometry/trace contracts, not a substitute for Godot browser play.
import assert from 'node:assert/strict';
import {test} from 'node:test';
import {continuousExercise, createExerciseMoveQueue, verifyExerciseObservation, exerciseInputObserver} from '../tools/web_phone_recovery.mjs';

const radius = 83, straight = 130, length = Math.PI * radius * 2 + straight * 2;
const fractions = [0, .075, .175, .275, .375, .475, .575, .675, .775, .875, 1];
function sourcePoint(distance) {
  let d = distance, quarter = Math.PI * radius / 2;
  if (d <= quarter) return {x: 180 + Math.cos(Math.PI / 2 + d / radius) * radius, y: 245 + Math.sin(Math.PI / 2 + d / radius) * radius};
  d -= quarter;
  if (d <= straight) return {x: 97, y: 245 - d};
  d -= straight;
  if (d <= Math.PI * radius) return {x: 180 + Math.cos(Math.PI + d / radius) * radius, y: 115 + Math.sin(Math.PI + d / radius) * radius};
  d -= Math.PI * radius;
  if (d <= straight) return {x: 263, y: 115 + d};
  d -= straight;
  return {x: 180 + Math.cos(d / radius) * radius, y: 245 + Math.sin(d / radius) * radius};
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

for (const touch of [true, false]) await test(`cached canvas preserves every original ${touch ? 'touch' : 'mouse'} source sample, cadence and ten accepts`, async () => {
  const f = fixture({touch}); await continuousExercise(f.h, f.evidence);
  const expected = [];
  for (let segment = 0; segment < 10; segment++) {
    const start = fractions[segment] * length, finish = fractions[segment + 1] * length;
    const screen = d => {const p = sourcePoint(d); return f.rendered({x: f.rect.x + 35 + p.x, y: f.rect.y + 209 + p.y});};
    expected.push({phase: 'start', ...screen(start)});
    const steps = Math.ceil((finish - start) / 2);
    for (let step = 1; step <= steps; step++) expected.push({phase: 'move', ...screen(start + (finish - start) * step / steps)});
    expected.push({phase: 'end', ...screen(finish)});
  }
  assert.equal(f.events.length, expected.length);
  f.events.forEach((event, i) => {assert.equal(event.phase, expected[i].phase); assert.ok(Math.hypot(event.x - expected[i].x, event.y - expected[i].y) < 1e-9);});
  const moves = expected.filter(event => event.phase === 'move').length;
  assert.equal(f.waits.length, moves); assert.ok(f.waits.every(ms => ms === 80));
  const expectedCalls = fractions.slice(1).reduce((sum, finish, i) => sum + 2 + Math.floor(Math.ceil((finish - fractions[i]) * length / 2) / 8), 0);
  assert.equal(f.renders, expectedCalls); assert.ok(f.renders < moves / 5);
  assert.equal(f.evidence.inputs.length, 10); assert.equal(f.evidence.samples.length, 10);
  assert.ok(f.evidence.inputs.every(event => event.method === (touch ? 'ordinaryTouchDrag' : 'ordinaryMouseDrag')));
  assert.equal(f.evidence.exerciseTransport.reduce((sum, row) => sum + row.pointerMoves, 0), moves);
  assert.equal(f.evidence.exerciseTransport.reduce((sum, row) => sum + row.geometryCalls, 0), f.renders);
  assert.ok(f.evidence.exerciseTransport.every(row => row.finishedAt >= row.startedAt));
});

for (const change of ['canvas', 'viewport', 'gameRect']) await test(`${change} change fails at the eight-input boundary and releases held input`, async () => {
  const f = fixture({change}); await assert.rejects(continuousExercise(f.h, f.evidence), /remains registered/);
  assert.equal(f.events.filter(e => e.phase === 'move').length, 8); assert.equal(f.events.at(-1).phase, 'end');
  assert.equal(f.evidence.samples.length, 0); assert.equal(f.evidence.inputs.length, 1);
});
await test('checkpoint refusal never fabricates progress and always releases', async () => {
  const f = fixture({rejectCheckpoint: true}); await assert.rejects(continuousExercise(f.h, f.evidence), /authority did not accept/);
  assert.equal(f.events.at(-1).phase, 'end'); assert.equal(f.evidence.samples.length, 0); assert.equal(f.evidence.inputs.length, 1);
});
await test('pointer transport failure releases without retrying or proceeding', async () => {
  const f = fixture({failMove: true}); await assert.rejects(continuousExercise(f.h, f.evidence), /CDP transport failure/);
  assert.equal(f.events.at(-1).phase, 'end'); assert.equal(f.events.filter(e => e.phase === 'move').length, 3);
  assert.equal(f.evidence.samples.length, 0);
});

function timedFixture(options = {}) {
  const f = fixture(options), state = {now: 1000}, costs = {start: 11, move: 7, end: 13};
  for (const [method, cost] of [['snapshot', 5], ['renderPoint', 3], ['interval', null]]) {
    const original = f.h[method]; f.h[method] = async (...args) => {if (method === 'interval') for (let i = 0; i < 8; i++) await Promise.resolve(); state.now += cost ?? args[0]; return original(...args);};
  }
  const pointer = f.h.pointer;
  f.h.pointer = async (phase, point) => {state.now += costs[phase]; return pointer(phase, point);};
  return {...f, state, costs};
}
await test('immediate ACK telemetry measures spans without changing input or wait budget', async () => {
  const f = timedFixture(), originalNow = Date.now;
  Date.now = () => f.state.now;
  try {
    await continuousExercise(f.h, f.evidence);
    for (const row of f.evidence.exerciseTransport) {
      for (const phase of ['start', 'move', 'end']) {
        const stats = row.pointerAck[phase], count = phase === 'move' ? row.pointerMoves : 1;
        assert.deepEqual(stats, {calls: count, acknowledged: count, failed: 0, totalMs: count * f.costs[phase], maxMs: f.costs[phase]});
      }
      assert.equal(row.snapshots.failed, 0); assert.equal(row.snapshots.maxMs, 5);
      assert.equal(row.snapshots.totalMs, row.snapshots.calls * 5);
      assert.equal(row.geometryMs, row.geometryCalls * 3);
      assert.equal(row.elapsedMs, row.finishedAt - row.startedAt);
      assert.equal(row.elapsedMs, row.geometryMs + row.snapshots.totalMs + row.inputWaitMs +
        Object.values(row.pointerAck).reduce((sum, stats) => sum + stats.totalMs, 0));
    }
    assert.equal(f.events.filter(e => e.phase === 'move').length, 399);
    assert.equal(f.waits.length, 399); assert.equal(f.waits.reduce((a, b) => a + b, 0), 31920);
  } finally {Date.now = originalNow;}
});
for (const phase of ['start', 'move', 'end']) await test(`${phase} ACK failure is timed as failed, never as an acknowledged move`, async () => {
  const f = timedFixture({failMove: phase === 'move'}), originalNow = Date.now;
  const pointer = f.h.pointer;
  if (phase !== 'move') f.h.pointer = async (p, point) => {await pointer(p, point); if (p === phase) throw Error(`synthetic ${phase} failure`);};
  Date.now = () => f.state.now;
  try {
    await assert.rejects(continuousExercise(f.h, f.evidence), /synthetic/);
    const row = f.evidence.exerciseTransport[0], stats = row.pointerAck[phase];
    assert.equal(stats.failed, 1); assert.equal(stats.acknowledged, stats.calls - 1);
    assert.equal(stats.totalMs, stats.calls * f.costs[phase]); assert.equal(stats.maxMs, f.costs[phase]);
    assert.equal(row.pointerMoves, row.pointerAck.move.acknowledged);
    assert.equal(row.elapsedMs, row.finishedAt - row.startedAt);
    assert.equal(row.elapsedMs, row.geometryMs + row.snapshots.totalMs + row.inputWaitMs +
      Object.values(row.pointerAck).reduce((sum, value) => sum + value.totalMs, 0));
    assert.equal(f.events.filter(e => e.phase === 'end').length, 1,
      'uncertain failed start is also released exactly once, after outstanding moves settle');
  } finally {Date.now = originalNow;}
});
await test('snapshot failure includes its elapsed time and the existing final release ACK', async () => {
  const f = timedFixture(), originalNow = Date.now, snapshot = f.h.snapshot; let calls = 0;
  f.h.snapshot = async () => {const result = await snapshot(); if (++calls === 3) throw Error('synthetic snapshot failure'); return result;};
  Date.now = () => f.state.now;
  try {
    await assert.rejects(continuousExercise(f.h, f.evidence), /snapshot failure/);
    const row = f.evidence.exerciseTransport[0];
    assert.deepEqual(row.snapshots, {calls: 2, failed: 1, totalMs: 10, maxMs: 5});
    assert.equal(row.pointerMoves, 8); assert.equal(row.pointerAck.end.acknowledged, 1);
    assert.equal(row.elapsedMs, row.geometryMs + row.snapshots.totalMs + row.inputWaitMs +
      Object.values(row.pointerAck).reduce((sum, value) => sum + value.totalMs, 0));
  } finally {Date.now = originalNow;}
});

await test('serial queue waits for delayed ACKs, retains 80ms spacing and never overlaps moves', async () => {
  const sent = [], ack = [], stats = {inputWaitMs: 0}; let active = 0, peak = 0;
  const queue = createExerciseMoveQueue(point => {
    const i = point.x; sent.push({i, at: performance.now()}); active++; peak = Math.max(peak, active);
    return new Promise(resolve => setTimeout(() => {ack.push(i); active--; resolve();}, i === 0 ? 50 : 15));
  }, ms => new Promise(resolve => setTimeout(resolve, ms)), stats);
  for (let i = 0; i < 9; i++) await queue.move({x: i, y: 1});
  await queue.drain();
  assert.equal(active, 0); assert.equal(peak, 1); assert.equal(stats.maxInFlight, 1);
  assert.deepEqual(sent.map(e => e.i), Array.from({length: 9}, (_, i) => i));
  assert.deepEqual(ack, sent.map(e => e.i));
  for (let i = 1; i < sent.length; i++) assert.ok(sent[i].at - sent[i - 1].at >= 79.5, 'no catch-up burst');
  assert.ok(stats.inputWaitMs >= 720 && stats.inputWaitMs < 730);
});
for (const kind of ['sync', 'reject', 'timeout']) await test(`${kind} move failure stops issuing commands and drains every earlier command`, async () => {
  const sent = [], stats = {inputWaitMs: 0}; let clock = 0;
  const queue = createExerciseMoveQueue(point => {
    sent.push(point.x);
    if (point.x === 2) {
      if (kind === 'sync') throw Error('sync dispatch failed');
      return Promise.reject(Error(kind === 'timeout' ? 'CDP command timed out' : 'CDP rejected'));
    }
    return Promise.resolve();
  }, async ms => {clock += ms;}, stats, () => clock);
  await queue.move({x: 0}); await queue.move({x: 1});
  await assert.rejects(queue.move({x: 2}), /failed|timed out|rejected/);
  let settled = false; const settlement = queue.settle().then(() => {settled = true;});
  await settlement; assert.equal(settled, true);
  await settlement;
  await assert.rejects(queue.move({x: 3}), /failed|timed out|rejected/);
  await assert.rejects(queue.drain(), /failed|timed out|rejected/);
  assert.deepEqual(sent, [0, 1, 2]);
});
for (const change of ['missing', 'extra', 'reordered', 'coordinate', 'untrusted', 'cancelled', 'overflow', 'identifier']) await test(`real-event observation rejects ${change} rather than accepting ACK evidence`, () => {
  const sent = [{phase: 'start', x: 1, y: 2}, {phase: 'move', x: 2, y: 3}, {phase: 'move', x: 3, y: 4}];
  const observation = {events: sent.map(row => ({...row, trusted: true, identifier: 4})), overflow: false, cancelled: false};
  verifyExerciseObservation(observation, sent, true);
  if (change === 'missing') observation.events.pop();
  if (change === 'extra') observation.events.push({...observation.events.at(-1)});
  if (change === 'reordered') [observation.events[1], observation.events[2]] = [observation.events[2], observation.events[1]];
  if (change === 'coordinate') observation.events[1].x += 1;
  if (change === 'untrusted') observation.events[1].trusted = false;
  if (change === 'identifier') observation.events[1].identifier = 9;
  if (['cancelled', 'overflow'].includes(change)) observation[change] = true;
  assert.throws(() => verifyExerciseObservation(observation, sent, true), /observation|order\/coordinate/);
});
await test('observer is passive, capture-only, bounded and removes exact registered listeners', () => {
  const previous = globalThis.window, listeners = new Map(), removed = [];
  globalThis.window = {
    addEventListener(type, fn, options) {assert.deepEqual(options, {capture: true, passive: true}); listeners.set(type, fn);},
    removeEventListener(type, fn, options) {assert.equal(listeners.get(type), fn); assert.deepEqual(options, {capture: true}); removed.push(type);}
  };
  try {
    exerciseInputObserver('begin', true); assert.throws(() => exerciseInputObserver('begin', true), /already active/);
    listeners.get('touchmove')({type: 'touchmove', changedTouches: [{clientX: 3, clientY: 4, identifier: 4}], isTrusted: true});
    const first = exerciseInputObserver('read', true); assert.equal(first.events.length, 1);
    first.events.pop(); assert.equal(exerciseInputObserver('read', true).events.length, 1);
    for (let i = 0; i < 1025; i++) listeners.get('touchmove')({type: 'touchmove', changedTouches: [{clientX: i, clientY: 4, identifier: 4}], isTrusted: true});
    listeners.get('touchcancel')({type: 'touchcancel', changedTouches: []});
    const final = exerciseInputObserver('end', true); assert.equal(final.events.length, 1024); assert.ok(final.cancelled && final.overflow);
    assert.equal(removed.length, 4); assert.throws(() => exerciseInputObserver('read', true), /not active/);
  } finally {globalThis.window = previous;}
});
await test('eight-point and segment boundaries have no pending ACK; failed observer cleans up once', async () => {
  const f = fixture(), pointer = f.h.pointer, observe = f.h.observeExercise; let pending = 0, ended = 0;
  f.h.pointer = async (phase, point) => {
    if (phase === 'end') {assert.equal(pending, 0); ended++;}
    if (phase === 'move') {pending++; await new Promise(resolve => setImmediate(resolve)); pending--;}
    return pointer(phase, point);
  };
  f.h.observeExercise = async action => {
    if (action !== 'begin') assert.equal(pending, 0);
    const result = await observe(action);
    if (action === 'read') result.events.splice(2, 1);
    return result;
  };
  await assert.rejects(continuousExercise(f.h, f.evidence), /lost, added/);
  assert.equal(f.events.filter(e => e.phase === 'move').length, 8); assert.equal(ended, 1);
  assert.equal(f.evidence.exerciseTransport[0].observed.events.at(-1).phase, 'end');
});
for (const kind of ['sync', 'async']) await test(`uncertain observer begin ${kind} failure attempts cleanup without sending input or masking first failure`, async () => {
  const f = fixture(), actions = [];
  f.h.observeExercise = action => {
    actions.push(action);
    if (action === 'end') throw Error('secondary cleanup failure');
    if (kind === 'sync') throw Error('original begin failure');
    return Promise.reject(Error('original begin failure'));
  };
  await assert.rejects(continuousExercise(f.h, f.evidence), /original begin failure/);
  assert.deepEqual(actions, ['begin', 'end']); assert.equal(f.events.length, 0);
  assert.equal(f.evidence.exerciseTransport[0].observationError, 'secondary cleanup failure');
});
await test('early timer wake adds only the missing cadence and never emits a catch-up burst', async () => {
  let now = 0; const sent = [], waits = [], timing = {inputWaitMs: 0};
  const queue = createExerciseMoveQueue(() => {sent.push(now);}, async ms => {
    waits.push(ms); now += ms === 80 ? 79 : ms;
  }, timing, () => now);
  for (let i = 0; i < 3; i++) await queue.move({x: i});
  await queue.drain();
  assert.deepEqual(sent, [0, 80, 160]); assert.deepEqual(waits, [80, 1, 80, 1, 80, 1]);
});
await test('all ten segments observe and snapshot only after delayed moves drain; start/end never overlap moves', async () => {
  const f = fixture(), pointer = f.h.pointer, snapshot = f.h.snapshot, observe = f.h.observeExercise;
  let pending = 0; const observedMoveCounts = [];
  f.h.pointer = async (phase, point) => {
    if (phase !== 'move') assert.equal(pending, 0);
    if (phase === 'move') {pending++; await new Promise(resolve => setImmediate(resolve)); pending--;}
    return pointer(phase, point);
  };
  f.h.snapshot = async () => {assert.equal(pending, 0); return snapshot();};
  f.h.observeExercise = async action => {
    assert.equal(pending, 0); const result = await observe(action);
    if (action === 'read') observedMoveCounts.push(result.events.filter(e => e.phase === 'move').length);
    return result;
  };
  await continuousExercise(f.h, f.evidence);
  assert.equal(f.evidence.samples.length, 10); assert.equal(f.events.filter(e => e.phase === 'move').length, 399);
  assert.equal(f.events.filter(e => e.phase === 'end').length, 10);
  assert.ok(f.evidence.exerciseTransport.every(row => row.maxInFlight === 1 && row.observed.events.length === row.sent.length));
  assert.equal(observedMoveCounts[0], 8); assert.equal(observedMoveCounts[1], 16);
});
await test('pending moves settle before release and release failure cannot mask first move failure', async () => {
  const f = fixture(), pointer = f.h.pointer; let pending = 0, moves = 0;
  f.h.pointer = async (phase, point) => {
    if (phase === 'move') {
      const i = ++moves;
      if (i === 3) throw Error('first move failure');
      pending++; await new Promise(resolve => setImmediate(resolve)); pending--;
    }
    if (phase === 'end') {assert.equal(pending, 0); await pointer(phase, point); throw Error('secondary release failure');}
    return pointer(phase, point);
  };
  await assert.rejects(continuousExercise(f.h, f.evidence), /first move failure/);
  assert.equal(moves, 3); assert.equal(pending, 0);
  assert.equal(f.evidence.exerciseTransport[0].releaseError, 'secondary release failure');
  assert.equal(f.events.filter(e => e.phase === 'end').length, 1);
});
await test('a pending serial ACK prevents the next dispatch and the cadence starts only after ACK', async () => {
  let resolveFirst, now = 0; const sent = [], waits = [], timing = {inputWaitMs: 0};
  const queue = createExerciseMoveQueue(point => {
    sent.push({x: point.x, now});
    if (point.x === 0) return new Promise(resolve => {resolveFirst = resolve;});
  }, async ms => {waits.push({ms, now}); now += ms;}, timing, () => now);
  const run = (async () => {await queue.move({x: 0}); await queue.move({x: 1}); await queue.drain();})();
  for (let i = 0; i < 10; i++) await Promise.resolve();
  assert.deepEqual(sent, [{x: 0, now: 0}]); assert.deepEqual(waits, []);
  now = 450; resolveFirst(); await run;
  assert.deepEqual(sent, [{x: 0, now: 0}, {x: 1, now: 530}]);
  assert.equal(waits[0].now, 450); assert.equal(timing.maxInFlight, 1);
});
