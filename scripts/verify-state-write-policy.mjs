import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import { performance } from 'node:perf_hooks';
import { fileURLToPath } from 'node:url';
import { build } from 'esbuild';
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

// Exercise the real subscription and SaveStore boundary as well as the helper.
// Storage quota errors must not suppress the next immutable store notification.
const bundle = await build({
  stdin: {
    contents: `export * from './src/core/GameState.ts'; export * from './src/core/SaveStore.ts'; export * from './src/core/StorageKeys.ts';
      export * from './src/core/DeveloperSession.ts';
      export {getActiveDeveloperCheckpoint, getDeveloperCc98Mode} from './src/modules/DeveloperChannel.ts';`,
    resolveDir: fileURLToPath(new URL('..', import.meta.url))
  },
  bundle: true, platform: 'node', format: 'esm', write: false
});
const { createInitialGameState, createPersistentGameStore, SaveStore, GAME_SAVE_KEY, DEVELOPER_ACTIVE_KEY,
  DEVELOPER_BACKUP_KEY, DEVELOPER_SESSION_KEYS, clearDeveloperSession, getActiveDeveloperCheckpoint, getDeveloperCc98Mode } =
  await import(`data:text/javascript;base64,${Buffer.from(bundle.outputFiles[0].text).toString('base64')}`);
class MemoryStorage {
  values = new Map();
  primaryAttempts = 0;
  failNextWrites = 0;
  get length() { return this.values.size; }
  key(index) { return [...this.values.keys()][index] ?? null; }
  getItem(key) { return this.values.get(key) ?? null; }
  setItem(key, value) {
    if (key === GAME_SAVE_KEY) {
      this.primaryAttempts++;
      if (this.failNextWrites > 0) { this.failNextWrites--; throw Error('QuotaExceededError'); }
    }
    this.values.set(key, String(value));
  }
  removeItem(key) { this.values.delete(key); }
  clear() { this.values.clear(); }
}
test('real store retries the unchanged state after a failed primary save', () => {
  const storage = new MemoryStorage();
  storage.failNextWrites = 1;
  const store = createPersistentGameStore(storage);
  store.setState(state => ({ ...state, currentScene: 'phone_home' }));
  assert.equal(store.getState().currentScene, 'phone_home');
  assert.equal(storage.primaryAttempts, 1); assert.equal(storage.getItem(GAME_SAVE_KEY), null);
  store.setState(state => ({ ...state }));
  assert.equal(storage.primaryAttempts, 2);
  assert.equal(JSON.parse(storage.getItem(GAME_SAVE_KEY)).state.currentScene, 'phone_home');
  store.setState(state => ({ ...state }));
  assert.equal(storage.primaryAttempts, 2);
});
test('real store retries a failed hydration refresh without requiring new progress', () => {
  const storage = new MemoryStorage();
  assert.equal(new SaveStore(storage).save({ ...createInitialGameState(), currentScene: 'phone_home' }), true);
  storage.failNextWrites = 1;
  const store = createPersistentGameStore(storage);
  assert.equal(store.getState().currentScene, 'phone_home');
  assert.equal(storage.primaryAttempts, 2);
  store.setState(state => ({ ...state }));
  assert.equal(storage.primaryAttempts, 3);
  store.setState(state => ({ ...state }));
  assert.equal(storage.primaryAttempts, 3);
});
test('real developer checkpoint gate leaves later formal saves retryable', () => {
  const previousWindow = globalThis.window;
  const sessionStorage = new MemoryStorage();
  const storage = new MemoryStorage();
  globalThis.window = { sessionStorage };
  try {
    sessionStorage.setItem(DEVELOPER_ACTIVE_KEY, '1');
    const store = createPersistentGameStore(storage);
    store.setState(state => ({ ...state, currentScene: 'phone_home' }));
    assert.equal(storage.primaryAttempts, 0);
    sessionStorage.removeItem(DEVELOPER_ACTIVE_KEY);
    store.setState(state => ({ ...state }));
    assert.equal(storage.primaryAttempts, 1);
    assert.equal(JSON.parse(storage.getItem(GAME_SAVE_KEY)).state.currentScene, 'phone_home');
  } finally {
    if (previousWindow === undefined) delete globalThis.window;
    else globalThis.window = previousWindow;
  }
});

test('production session cleanup resumes formal saves without restoring a QA backup', () => {
  const previousWindow = globalThis.window;
  const sessionStorage = new MemoryStorage();
  const storage = new MemoryStorage();
  globalThis.window = { sessionStorage };
  try {
    const initial = createInitialGameState();
    const formal = { ...initial, phoneBattery: { ...initial.phoneBattery, percent: 73 } };
    assert(new SaveStore(storage).save(formal));
    for (const key of DEVELOPER_SESSION_KEYS) sessionStorage.setItem(key, 'old-qa-value');
    sessionStorage.setItem(DEVELOPER_ACTIVE_KEY, 'c2-cc98-upload');
    sessionStorage.setItem(DEVELOPER_BACKUP_KEY, JSON.stringify({ ...formal, phoneBattery: { ...formal.phoneBattery, percent: 9 }, currentScene: 'ending' }));
    sessionStorage.setItem('reader-preference', 'keep');
    const seedWrites = storage.primaryAttempts;
    const store = createPersistentGameStore(storage);
    assert.equal(store.getState().phoneBattery.percent, 73, 'pre-cleanup hydration uses the formal save, not the QA backup');
    assert.equal(store.getState().currentScene, formal.currentScene);
    assert(storage.primaryAttempts > seedWrites, 'required hydration save is not suppressed by the stale marker');
    const savedBefore = storage.getItem(GAME_SAVE_KEY);
    const writesBefore = storage.primaryAttempts;
    store.setState(state => ({ ...state, phoneBattery: { ...state.phoneBattery, percent: 72 } }));
    assert.equal(storage.primaryAttempts, writesBefore, 'old QA marker demonstrably blocks the real writer');
    assert.equal(getActiveDeveloperCheckpoint(sessionStorage), 'c2-cc98-upload');
    assert.equal(getDeveloperCc98Mode(sessionStorage), 'investigation');
    clearDeveloperSession(sessionStorage);
    assert.equal(storage.getItem(GAME_SAVE_KEY), savedBefore, 'cleanup leaves the formal save bytes intact');
    assert.equal(sessionStorage.getItem('reader-preference'), 'keep');
    for (const key of DEVELOPER_SESSION_KEYS) assert.equal(sessionStorage.getItem(key), null);
    assert.equal(getActiveDeveloperCheckpoint(sessionStorage), null, 'CC98 maintenance has no active developer session');
    assert.equal(getDeveloperCc98Mode(sessionStorage), null);
    assert.equal(store.getState().phoneBattery.percent, 72, 'cleanup never restores the QA backup');
    store.setState(state => ({ ...state, phoneBattery: { ...state.phoneBattery, percent: 71 } }));
    assert.equal(storage.primaryAttempts, writesBefore + 1);
    const reloaded = new SaveStore(storage).load(createInitialGameState());
    assert.equal(reloaded.phoneBattery.percent, 71);
    assert.equal(reloaded.currentScene, formal.currentScene);
  } finally {
    if (previousWindow === undefined) delete globalThis.window;
    else globalThis.window = previousWindow;
  }
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
