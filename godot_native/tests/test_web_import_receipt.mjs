import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import { readFileSync } from 'node:fs';
import path from 'node:path';
import test from 'node:test';
import vm from 'node:vm';

// Exercise the actual browser runner with simulated file-picker and snapshot
// observations. This does not substitute for a real browser import.
const runner = readFileSync(new URL('../tools/verify_web_export.mjs', import.meta.url), 'utf8');
const start = runner.indexOf('async function importSave(');
const end = runner.indexOf('// Focused CI scenario:', start);
assert(start >= 0 && end > start);
const implementation = runner.slice(start, end);
const bytes = Buffer.from(JSON.stringify({format: '7-55-godot-native', version: 1,
  state: {native: {chapter: 1, page: 'desktop', scene: ''}}}));
const digest = createHash('sha256').update(bytes).digest('hex');
const snapshot = (receipt, page = 'bonsai') => ({importReceipt: receipt, developerToolsAvailable: false,
  state: {native: {chapter: 1, page, scene: ''}}, world: {visible: false}, saveDigest: 'same-save'});
const before = snapshot({sequence: 7, sourceDigest: 'old', ok: true});

function fixture(observations) {
  let index = 0;
  const inputs = [];
  const active = {id: 'desktop', imports: [], cdp: {async send(method) {
    inputs.push(method);
    if (method === 'DOM.getDocument') return {root: {nodeId: 1}};
    if (method === 'DOM.querySelector') return {nodeId: 2};
    return {};
  }}};
  const samples = [before, ...observations];
  const context = vm.createContext({active, path, Date, JSON,
    readFile: async () => bytes,
    hash: value => createHash('sha256').update(value).digest('hex'),
    check: (ok, label) => assert.ok(ok, label),
    snapshot: async () => samples[Math.min(index++, samples.length - 1)],
    state: value => value?.state,
    settings: async () => inputs.push('settings'),
    clickControl: async () => inputs.push('import button'),
    interval: async () => {},
    acceptPortraitFallback: async () => { throw Error('unexpected world'); },
    poll: async (read, label) => {
      for (let attempt = 0; attempt < 3; attempt++) {
        const value = await read();
        if (value) return value;
      }
      throw Error(`synthetic timeout: ${label}`);
    }});
  vm.runInContext(`${implementation}\nglobalThis.runImport = importSave;`, context);
  return {run: () => context.runImport('/fixture/legacy-desk.json', {page: 'bonsai'}), active, inputs};
}

await test('legacy desk import waits for the exact accepted input and migrated page', async () => {
  const stale = snapshot({sequence: 7, sourceDigest: digest, ok: true});
  const accepted = snapshot({sequence: 8, sourceDigest: digest, ok: true});
  const f = fixture([stale, accepted]);
  await f.run();
  assert.deepEqual(f.inputs, ['settings', 'import button', 'DOM.getDocument', 'DOM.querySelector', 'DOM.setFileInputFiles']);
  assert.equal(f.active.imports.length, 1);
  assert.equal(f.active.imports[0].page, 'bonsai');
  assert.equal(f.active.imports[0].sha256, digest);
  assert.equal(f.active.imports[0].receiptSequence, 8);
});

for (const [label, observed] of [
  ['missing receipt', snapshot(undefined)],
  ['stale receipt', snapshot({sequence: 7, sourceDigest: digest, ok: true})],
  ['different input', snapshot({sequence: 8, sourceDigest: 'wrong', ok: true})],
  ['rejected import', snapshot({sequence: 8, sourceDigest: digest, ok: false})],
  ['unmigrated route', snapshot({sequence: 8, sourceDigest: digest, ok: true}, 'desktop')],
]) await test(`${label} cannot complete the import`, async () => {
  const f = fixture([observed]);
  await assert.rejects(f.run(), /synthetic timeout/);
  assert.equal(f.active.imports.length, 0);
});
