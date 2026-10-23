// Pure mock transport/provenance tests; no game, renderer, browser or earned-play claim.
import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import {createHash} from 'node:crypto';
import {test} from 'node:test';
import {createBundle, verifyBundle} from '../tools/web_acceptance_bundle.mjs';

const hash = bytes => createHash('sha256').update(bytes).digest('hex');
const root = fs.mkdtempSync(path.join(os.tmpdir(), '755-ci-bundle-test-'));
let sequence = 0;
const expected = {commit: 'a'.repeat(40), head: 'b'.repeat(40), base: 'c'.repeat(40), tree: 'd'.repeat(40), run: '12345', attempt: '1', event: 'pull_request', dirty: false};
function json(file, value) { fs.writeFileSync(file, JSON.stringify(value, null, 2) + '\n'); }
function read(file) { return JSON.parse(fs.readFileSync(file)); }
function fixture() {
  const directory = path.join(root, String(++sequence)); fs.mkdirSync(directory);
  const exportDir = path.join(directory, 'site'), fixturesDir = path.join(directory, 'earned'), sourceFile = path.join(directory, 'source.json'), bundleDir = path.join(directory, 'bundle');
  fs.mkdirSync(exportDir); fs.mkdirSync(fixturesDir);
  const source = {event: expected.event, head: expected.head, base: expected.base, checkedOutCommit: expected.commit, tree: expected.tree, run: expected.run, attempt: expected.attempt, dirty: false};
  json(sourceFile, source);
  const files = [{path: 'scripts/fake.gd', bytes: 10, sha256: hash('mock source')}];
  json(path.join(exportDir, 'source-inputs.json'), {digest: hash(JSON.stringify(files)), files, excluded: []});
  fs.writeFileSync(path.join(exportDir, '.nojekyll'), '');
  fs.writeFileSync(path.join(exportDir, 'index.html'), 'mock export, not executable');
  fs.mkdirSync(path.join(exportDir, 'content'));
  fs.writeFileSync(path.join(exportDir, 'content/mock.pck'), 'mock, not a PCK');
  const siteFiles = ['content/mock.pck', 'index.html'].map(name => { const bytes = fs.readFileSync(path.join(exportDir, name)); return {path: name, bytes: bytes.length, sha256: hash(bytes)}; });
  json(path.join(exportDir, 'build-manifest.json'), {schema: '7-55-godot-web-release/v1', sourceCommit: expected.commit, sourceTree: expected.tree, sourceDirty: false, sourceChanges: [],
    engine: '4.7.1.stable.official', runtime: 'godot-web', production: true, storyOnly: true, threads: false, chapterShortcuts: false,
    bootChunks: {schema: '755-boot-chunks-v1'}, delivery: 'chapter-content-packs', content: {exactCoverage: true, packs: 1}, initialPayloadBytes: 50,
    sourceInputSha256: hash(JSON.stringify(files)), sourceInputCount: files.length, files: siteFiles, totalPayloadBytes: siteFiles.reduce((sum, file) => sum + file.bytes, 0)});
  json(path.join(fixturesDir, 'fixture-provenance.json'), {source, scope: 'Synthetic unit input only, not controller-earned evidence.'});
  json(path.join(fixturesDir, 'mock-save.json'), {notAnEarnedSave: true});
  return {directory, exportDir, fixturesDir, sourceFile, bundleDir, expected: {...expected}};
}
function built() { const value = fixture(); value.result = createBundle(value); return value; }
function verify(value, change = {}) { return verifyBundle({bundleDir: value.bundleDir, receiptSha: value.result.receiptSha, producerAttempt: '1', expected: value.expected, ...change}); }
function changeJson(file, change) { const value = read(file); change(value); json(file, value); }

await test('immutable acceptance bundle transport (not browser acceptance)', async t => {
  t.after(() => fs.rmSync(root, {recursive: true, force: true}));
  await t.test('whole bundle exact bytes, hidden files, receipt hash and source bytes preserved', () => {
    const value = fixture(), before = fs.readFileSync(value.sourceFile);
    value.result = createBundle(value);
    const receiptBytes = fs.readFileSync(path.join(value.bundleDir, 'bundle-receipt.json')), receipt = JSON.parse(receiptBytes);
    assert.equal(value.result.receiptSha, hash(receiptBytes));
    assert.equal(value.result.bundleName, 'godot-web-inputs-12345-1');
    assert.ok(receipt.files.some(file => file.path === 'web-release/.nojekyll'));
    for (const file of receipt.files) {
      const bytes = fs.readFileSync(path.join(value.bundleDir, file.path));
      assert.equal(file.bytes, bytes.length); assert.equal(file.sha256, hash(bytes));
    }
    assert.deepEqual(fs.readFileSync(value.sourceFile), before);
    const outputReceipt = path.join(value.directory, 'verification/inputs.json');
    const result = verify(value, {outputReceipt});
    assert.deepEqual(read(outputReceipt), result); assert.equal(result.verified, true);
    assert.equal(result.totalBytes, receipt.files.reduce((sum, file) => sum + file.bytes, 0));
    assert.equal(result.transportBytes, result.totalBytes + receiptBytes.length);
  });
  await t.test('failed-job rerun consumes explicit old producer attempt in the same run', () => {
    const value = built(); value.expected.attempt = '2';
    const result = verify(value);
    assert.equal(result.producerAttempt, '1'); assert.equal(result.consumerAttempt, '2');
  });
  await t.test('push source has null base and exact head/checkout', () => {
    const value = fixture(); value.expected.event = 'push'; value.expected.base = null; value.expected.head = value.expected.commit;
    changeJson(value.sourceFile, source => { source.event = 'push'; source.base = null; source.head = value.expected.head; });
    changeJson(path.join(value.fixturesDir, 'fixture-provenance.json'), fixture => { fixture.source = read(value.sourceFile); });
    value.result = createBundle(value); assert.equal(verify(value).source.base, null);
  });
  for (const [name, mutation] of [
    ['wrong triggering SHA', value => { value.expected.commit = '1'.repeat(40); }],
    ['wrong head SHA', value => { value.expected.head = '1'.repeat(40); }],
    ['wrong base SHA', value => { value.expected.base = '1'.repeat(40); }],
    ['wrong tree', value => { value.expected.tree = '1'.repeat(40); }],
    ['different workflow run', value => { value.expected.run = '12346'; }],
    ['different event', value => { value.expected.event = 'push'; }],
    ['dirty consumer checkout', value => { value.expected.dirty = true; }],
    ['malformed attempt', value => { value.expected.attempt = '0'; }],
    ['extra root file', value => { fs.writeFileSync(path.join(value.bundleDir, 'extra'), 'x'); }],
    ['extra nested file', value => { fs.writeFileSync(path.join(value.bundleDir, 'controller-earned/extra'), 'x'); }],
    ['extra empty directory', value => { fs.mkdirSync(path.join(value.bundleDir, 'controller-earned/extra')); }],
    ['missing hidden file', value => { fs.unlinkSync(path.join(value.bundleDir, 'web-release/.nojekyll')); }],
    ['modified static bytes', value => { fs.appendFileSync(path.join(value.bundleDir, 'web-release/index.html'), 'x'); }],
    ['modified fixture bytes', value => { fs.appendFileSync(path.join(value.bundleDir, 'controller-earned/mock-save.json'), ' '); }],
    ['missing fixture', value => { fs.unlinkSync(path.join(value.bundleDir, 'controller-earned/mock-save.json')); }],
    ['symlink file', value => { const file = path.join(value.bundleDir, 'controller-earned/mock-save.json'); fs.unlinkSync(file); fs.symlinkSync(path.join(value.fixturesDir, 'mock-save.json'), file); }],
    ['symlink directory', value => { fs.symlinkSync(value.exportDir, path.join(value.bundleDir, 'controller-earned/link')); }],
    ['modified receipt', value => { fs.appendFileSync(path.join(value.bundleDir, 'bundle-receipt.json'), ' '); }],
  ]) await t.test(`reject ${name}`, () => { const value = built(); mutation(value); assert.throws(() => verify(value)); });

  await t.test('reject wrong trusted receipt SHA', () => { assert.throws(() => verify(built(), {receiptSha: '0'.repeat(64)}), /receipt SHA/); });
  await t.test('reject absent trusted receipt SHA', () => { assert.throws(() => verify(built(), {receiptSha: undefined}), /receipt SHA/); });
  await t.test('reject mismatched explicit producer attempt', () => { const value = built(); value.expected.attempt = '2'; assert.throws(() => verify(value, {producerAttempt: '2'}), /producer attempt/); });
  await t.test('reject future producer attempt', () => { assert.throws(() => verify(built(), {producerAttempt: '2'}), /future producer/); });
  await t.test('reject verifier receipt written inside immutable input', () => { const value = built(); assert.throws(() => verify(value, {outputReceipt: path.join(value.bundleDir, 'verification.json')}), /outside immutable bundle/); });
  await t.test('reject overwriting an existing bundle', () => { const value = built(); assert.throws(() => createBundle(value), /must not exist/); });
  for (const [name, mutation] of [
    ['wrong engine', value => { value.engine = '4.6.3.stable.official'; }],
    ['dirty producer', value => { value.sourceDirty = true; }],
    ['wrong source input SHA', value => { value.sourceInputSha256 = '0'.repeat(64); }],
    ['wrong source tree', value => { value.sourceTree = '0'.repeat(40); }],
    ['initial payload overflow', value => { value.initialPayloadBytes = 100_000_001; }],
    ['nonproduction bundle', value => { value.production = false; }],
    ['unverified coverage', value => { value.content.exactCoverage = false; }],
    ['wrong manifest file bytes', value => { value.files[0].bytes++; }],
  ]) await t.test(`reject producer ${name}`, () => { const value = fixture(); changeJson(path.join(value.exportDir, 'build-manifest.json'), mutation); assert.throws(() => createBundle(value)); });
  await t.test('reject source inventory with stale digest', () => { const value = fixture(); changeJson(path.join(value.exportDir, 'source-inputs.json'), input => { input.files[0].bytes++; }); assert.throws(() => createBundle(value), /Source-input SHA/); });
  await t.test('reject fixture provenance from another run', () => { const value = fixture(); changeJson(path.join(value.fixturesDir, 'fixture-provenance.json'), input => { input.source.run = '999'; }); assert.throws(() => createBundle(value), /Earned fixture provenance/); });
  await t.test('reject symlink input before copying', () => { const value = fixture(); fs.symlinkSync(value.sourceFile, path.join(value.exportDir, 'linked.json')); assert.throws(() => createBundle(value), /Symlink/); });
  await t.test('reject symlink input root', () => { const value = fixture(), linked = path.join(value.directory, 'linked'); fs.symlinkSync(value.exportDir, linked); assert.throws(() => createBundle({...value, exportDir: linked}), /real directory/); });
});
