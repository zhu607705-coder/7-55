#!/usr/bin/env node
import fs from 'node:fs';
import assert from 'node:assert/strict';
import { packContentFamilies, verifyContentPacking } from './web_content_packing.mjs';
import { CONTENT_PACK_TARGET, CONTENT_PACK_LIMIT, CONTENT_PACK_POLICY, CONTENT_PRESSURE_PACK_POLICY } from './web_content_chunks.mjs';
import { contentSizeException, verifyContentPackPolicy, verifyContentSizeException } from './web_content_delivery.mjs';

const fixture = JSON.parse(fs.readFileSync(new URL('./fixtures/campus_pack_pressure_102.json', import.meta.url)));
const entries = fixture.families.flatMap((family, f) => family.entries.map(([bytes, pathBytes], i) => {
  // Preserve the exact budget and tie order of every real exported entry.
  const name = `${f}/${String(i).padStart(5, '0')}`;
  assert.ok(pathBytes >= name.length);
  return { path: name.padEnd(pathBytes, 'x'), bytes, family: family.id };
}));
const families = fixture.families.map(({ id }) => ({ id, paths: entries.filter(e => e.family === id).map(e => e.path) }));
const baseline = families.flatMap(family => packContentFamilies([family], entries).chunks);
assert.equal(baseline.length, 102);
const packed = packContentFamilies(families, entries);
assert.equal(packed.ordinaryPackCount, 102);
assert.equal(packed.chunks.length, 100);
assert.deepEqual(packed.merges, [
  { id: 'phone_bonsai_001', absorbed: 'phone_bonsai_002', estimatedPackBytes: 6434749 },
  { id: 'chapter3_010', absorbed: 'chapter3_028', estimatedPackBytes: 8296151 },
]);
assert.equal(packed.merges.length, baseline.length - 100, 'Minimum number of pair merges');
assert.equal(Math.max(...packed.chunks.map(b => b.estimatedPackBytes)), 22203141);
const owner = new Map(entries.map(entry => [entry.path, entry.family]));
const allPaths = packed.chunks.flatMap(chunk => chunk.paths);
assert.equal(new Set(allPaths).size, entries.length);
assert.equal(allPaths.length, entries.length);
assert.equal(packed.chunks.reduce((sum, chunk) => sum + chunk.payloadBytes, 0), entries.reduce((sum, entry) => sum + entry.bytes, 0));
for (const chunk of packed.chunks) {
  assert.ok(chunk.estimatedPackBytes <= CONTENT_PACK_LIMIT);
  assert.ok(chunk.paths.every(name => owner.get(name) === chunk.family));
  if (!chunk.pressureSources) assert.deepEqual(chunk, baseline.find(b => b.id === chunk.id), 'Unchanged IDs/membership preserve caches');
  if (chunk.oversizedResource) assert.equal(chunk.paths.length, 1);
}
assert.deepEqual(packContentFamilies(families.map(f => ({ ...f, paths: [...f.paths].reverse() })), [...entries].reverse()), packed, 'Input order cannot affect packing');
const membership = new Map(packed.chunks.flatMap(chunk => chunk.paths.map(name => [name, chunk.id])));
const owned = entries.map(({ family, ...entry }) => ({ ...entry, group: membership.get(entry.path) }));
owned.push({ path: 'project.binary', bytes: 22698373, group: 'core' });
assert.deepEqual(verifyContentPacking(owned), packed, 'Recompute pressure without trusting manifest labels; core untouched');
const altered = structuredClone(owned);
altered.find(entry => entry.group === 'chapter3_010').group = 'chapter3_002';
assert.throws(() => verifyContentPacking(altered), /membership differs/);
const wrongFamily = structuredClone(owned); wrongFamily[0].group = 'unknown_001';
assert.throws(() => verifyContentPacking(wrongFamily), /Unknown deferred/);
for (const chunk of packed.chunks.filter(chunk => chunk.pressureSources)) {
  const actual = owned.filter(entry => entry.group === chunk.id);
  const record = { id: chunk.id, bytes: chunk.estimatedPackBytes };
  assert.deepEqual(contentSizeException(record, actual, packed), { reason: 'pack-count-pressure', ordinaryPackCount: 102, sourcePacks: chunk.pressureSources });
  const exception = contentSizeException(record, actual, packed);
  verifyContentSizeException({ ...record, sizeException: exception }, actual, packed);
  for (const sizeException of [undefined, { ...exception, ordinaryPackCount: 103 }, { ...exception, sourcePacks: ['chapter4_001', 'chapter4_002'] }, { ...exception, reason: 'single-resource' }])
    assert.throws(() => verifyContentSizeException({ ...record, sizeException }, actual, packed), /size exception differs/);
  assert.throws(() => contentSizeException(record, actual), /single-resource/, 'No policy downgrade bypass');
  assert.throws(() => contentSizeException(record, actual.slice(1), packed), /single-resource/, 'Exception cannot excuse changed membership');
  assert.throws(() => contentSizeException({ ...record, bytes: CONTENT_PACK_LIMIT + 1 }, actual, packed), /single-resource/);
}
// Exact boundary: the first-fit plan is unmodified at 100, pressure starts at101.
const make = (count, bytes) => Array.from({ length: count }, (_, i) => ({ path: `chapter2/${String(i).padStart(3, '0')}`, bytes }));
const plan = items => packContentFamilies([{ id: 'chapter2', paths: items.map(e => e.path) }], items);
const ordinary = make(100, 4_000_000);
const atLimit = plan(ordinary);
assert.deepEqual(verifyContentPackPolicy(CONTENT_PRESSURE_PACK_POLICY, owned), packed);
assert.equal(verifyContentPackPolicy(CONTENT_PACK_POLICY, owned), null, 'Legacy policy remains readable');
assert.throws(() => verifyContentPackPolicy({ ...CONTENT_PRESSURE_PACK_POLICY, countBudget: { maxPacks: 101 } }, owned), /Unknown.*policy/);
assert.throws(() => verifyContentPackPolicy(CONTENT_PRESSURE_PACK_POLICY, ordinary.map((entry, i) => ({ ...entry, group: atLimit.chunks[i].id }))), /unnecessary/);
assert.throws(() => verifyContentSizeException({ id: 'chapter2_001', bytes: 200, sizeException: { reason: 'pack-count-pressure' } }, []), /size exception differs/);
assert.equal(atLimit.chunks.length, 100); assert.deepEqual(atLimit.merges, []);
assert.ok(atLimit.chunks.every((b, i) => b.id === `chapter2_${String(i + 1).padStart(3, '0')}` && b.paths.length === 1 && !b.pressureSources));
assert.equal(plan(make(101, 4_000_000)).merges.length, 1);
assert.throws(() => plan(make(101, CONTENT_PACK_TARGET + 1)), /cannot meet.*100-pack/, 'Single-resource exceptions are never merged');
assert.throws(() => plan(make(401, CONTENT_PACK_TARGET - 512)), /cannot meet.*100-pack/, 'No relaxation when 24MB cannot satisfy count');
assert.throws(() => plan(make(1, CONTENT_PACK_LIMIT)), /exceeds.*budget/);
// Metadata and its anonymous exported resource keep their original family.
const imports = [{ path: 'assets/native/campus_layered/tile.png.import', bytes: 140 }, { path: '.godot/imported/tile.ctex', bytes: 1_000 }, { path: 'scenes/objects/lake.tscn.remap', bytes: 70 }, { path: '.godot/exported/lake.scn', bytes: 900 }];
const imported = packContentFamilies([{ id: 'chapter2', paths: imports.slice(0, 2).map(e => e.path) }, { id: 'chapter35', paths: imports.slice(2).map(e => e.path) }], imports);
assert.deepEqual(imported.chunks.map(c => [c.family, c.paths.length]), [['chapter2', 2], ['chapter35', 2]]);
assert.deepEqual(imported.merges, []);
assert.match(fs.readFileSync(new URL('./build_web.mjs', import.meta.url), 'utf8'), /const deliveryTools = .*'tools\/web_content_packing\.mjs'/, 'New production dependency participates in source provenance');
const workflow = fs.readFileSync(new URL('../../.github/workflows/deploy-pages.yml', import.meta.url), 'utf8');
const contracts = workflow.match(/^  browser_contracts:[\s\S]*?(?=^  [a-z_]+:)/m)?.[0] || '';
assert.match(contracts, /node godot_native\/tools\/test_web_content_packing\.mjs/);
assert.match(contracts, /node godot_native\/tools\/test_web_content_chunks\.mjs/);
console.log(JSON.stringify({ success: true, realExportEntries: entries.length, ordinaryPacks: 102, finalPacks: packed.chunks.length, merges: packed.merges, maxEstimatedPackBytes: 22203141, unchangedBins: 98 }, null, 2));
