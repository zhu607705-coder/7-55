import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import { performance } from 'node:perf_hooks';
import ts from 'typescript';

const source = await readFile(new URL('../src/core/state/JsonSnapshotWriter.ts', import.meta.url), 'utf8');
const { outputText } = ts.transpileModule(source, { compilerOptions: { target: ts.ScriptTarget.ES2020, module: ts.ModuleKind.ES2020 } });
const { createJsonSnapshotWriter } = await import(`data:text/javascript;base64,${Buffer.from(outputText).toString('base64')}`);
let passed = 0;
function test(name, body) { body(); passed++; console.log(`PASS ${name}`); }
const initial = { scene: 'phone', ui: { open: false }, progress: { facts: [] } };

test('100,000 structurally shared updates serialize once and never write', () => {
  let serializations = 0, writes = 0;
  const gate = createJsonSnapshotWriter({ initial, serialize: s => { serializations++; return JSON.stringify(s); }, write: () => { writes++; return true; } });
  for (let i = 0; i < 100_000; i++) assert.equal(gate({ ...initial }), 'unchanged');
  assert.equal(serializations, 1); assert.equal(writes, 0);
});
test('deep equal allocation is deduplicated then uses structural fast path', () => {
  let writes = 0;
  const gate = createJsonSnapshotWriter({ initial, write: () => { writes++; return true; } });
  const clone = JSON.parse(JSON.stringify(initial));
  assert.equal(gate(clone), 'unchanged'); assert.equal(gate(clone), 'unchanged'); assert.equal(writes, 0);
});
test('false and thrown writes remain retryable for exactly the same state', () => {
  let attempts = 0;
  const next = { ...initial, scene: 'rpg' };
  const gate = createJsonSnapshotWriter({ initial, write: () => { attempts++; if (attempts === 1) return false; if (attempts === 2) throw Error('quota'); return true; } });
  assert.equal(gate(next), 'failed'); assert.equal(gate(next), 'failed');
  assert.equal(gate(next), 'saved'); assert.equal(gate(next), 'unchanged'); assert.equal(attempts, 3);
});
test('developer gate runs before serialization and does not advance fingerprint', () => {
  let allowed = false, count = 0;
  const next = { ...initial, scene: 'rpg' };
  const gate = createJsonSnapshotWriter({ initial, canWrite: () => allowed, serialize: s => { count++; return JSON.stringify(s); }, write: () => true });
  assert.equal(gate(next), 'skipped'); assert.equal(count, 1);
  allowed = true; assert.equal(gate(next), 'saved'); assert.equal(count, 2);
});
test('returning from skipped state to saved state does not write', () => {
  let allowed = false, writes = 0;
  const gate = createJsonSnapshotWriter({ initial, canWrite: () => allowed, write: () => { writes++; return true; } });
  gate({ ...initial, scene: 'rpg' }); allowed = true;
  assert.equal(gate({ ...initial }), 'unchanged'); assert.equal(writes, 0);
});
test('changed nested references, added and removed keys are detected', () => {
  const gate = createJsonSnapshotWriter({ initial, write: () => true });
  assert.equal(gate({ ...initial, progress: { facts: ['admitted'] } }), 'saved');
  assert.equal(gate({ ...initial, extra: 1 }), 'saved'); assert.equal(gate(initial), 'saved');
});
test('2,000 critical progress updates are persisted synchronously in order', () => {
  const writes = [];
  const gate = createJsonSnapshotWriter({ initial: { revision: 0 }, write: s => { writes.push(s.revision); return true; } });
  for (let i = 1; i <= 2000; i++) { assert.equal(gate({ revision: i }), 'saved'); assert.equal(writes.at(-1), i); }
  assert.equal(writes.length, 2000);
});
test('serialization failure and permission getter exception are contained', () => {
  const gate = createJsonSnapshotWriter({ initial, write: () => true });
  const cycle = {}; cycle.self = cycle;
  assert.equal(gate(cycle), 'failed'); assert.equal(gate({ ...initial, scene: 'rpg' }), 'saved');
  assert.equal(createJsonSnapshotWriter({ initial, canWrite: () => { throw Error('SecurityError'); }, write: () => true })({ ...initial, scene: 'rpg' }), 'failed');
});

test('failed hydration write retries even with identical initial state', () => {
  let writes = 0;
  const gate = createJsonSnapshotWriter({ initial, initialPersisted: false, write: () => { writes++; return true; } });
  assert.equal(gate(initial), 'saved'); assert.equal(gate(initial), 'unchanged'); assert.equal(writes, 1);
});

const large = { scene: 'rpg', history: Array.from({ length: 256 }, (_, i) => ({ id: i, text: 'unchanged-history' })), ui: { open: false } };
const iterations = 20_000;
let count = 0;
const gate = createJsonSnapshotWriter({ initial: large, serialize: s => { count++; return JSON.stringify(s); }, write: () => true });
let started = performance.now();
for (let i = 0; i < iterations; i++) JSON.stringify({ ...large });
const oldMs = performance.now() - started;
started = performance.now();
for (let i = 0; i < iterations; i++) gate({ ...large });
const newMs = performance.now() - started;
assert.equal(count, 1);
console.log(JSON.stringify({ passed, benchmark: 'synthetic structurally-shared no-op updates; NOT game FPS', iterations, baselineSerializations: iterations, optimizedSerializations: count, oldMs, newMs }));
