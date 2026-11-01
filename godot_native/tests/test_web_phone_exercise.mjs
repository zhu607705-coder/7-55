#!/usr/bin/env node
// Test-driver geometry/trace contracts, not a substitute for Godot browser play.
import assert from 'node:assert/strict';
import {test} from 'node:test';
import {continuousExercise} from '../tools/web_phone_recovery.mjs';

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
  let completed = 0, moves = 0, renders = 0;
  const rect = {x: 11, y: 30, width: 430, height: 820};
  const viewport = {width: 430, height: 860};
  const events = [], waits = [], checks = [], evidence = {inputs: [], samples: []};
  const rendered = p => ({x: 7 + p.x * .8, y: 13 + p.y * .6});
  const snapshot = () => ({activeGame: {script: 'res://scripts/games/virtual_run.gd', rect: {...rect}}, viewport: {...viewport},
    visibleControls: [{name: 'RunProgress', text: `${completed} / 10`}, ...(completed === 10 ? [{name: 'ReturnToTiyi'}] : [])],
    state: {actOne: {exerciseStarted: completed === 10}}});
  const h = {id: 'fixture', touch, async snapshot() {return snapshot();},
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
    async interval(ms) {waits.push(ms);},
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
