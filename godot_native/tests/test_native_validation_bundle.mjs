// Synthetic transport/provenance tests only: no Godot execution or gameplay claim.
import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import {execFileSync} from 'node:child_process';
import {createHash} from 'node:crypto';
import {test} from 'node:test';
import {createBundle, verifyBundle, PREPARATION_IDS} from '../tools/native_validation_bundle.mjs';
import {createValidationCatalog, PREFLIGHT} from '../tools/native_validation_plan.mjs';
import {validationIdentity, fixtureIdentity, stageIdentity} from '../tools/native_validation_identity.mjs';

const temporary = fs.mkdtempSync(path.join(os.tmpdir(), '755-native-bundle-test-'));
const engine = path.join(temporary, 'mock-godot');
fs.writeFileSync(engine, '#!/bin/sh\nprintf "4.7.1.stable.official.mock\\n"\n'); fs.chmodSync(engine, 0o755);
const originalGodot = process.env.GODOT_BIN;
process.env.GODOT_BIN = engine;
let sequence = 0;
const hash = bytes => createHash('sha256').update(bytes).digest('hex');
const read = file => JSON.parse(fs.readFileSync(file));
function write(file, value) {fs.mkdirSync(path.dirname(file), {recursive: true}); fs.writeFileSync(file, value);}
const json = (file, value) => write(file, JSON.stringify(value, null, 2) + '\n');
const git = (root, ...args) => execFileSync('git', args, {cwd: root, encoding: 'utf8', stdio: ['ignore', 'pipe', 'pipe']}).trim();
function fixture() {
  const directory = path.join(temporary, String(++sequence)), root = path.join(directory, 'checkout');
  fs.mkdirSync(root, {recursive: true});
  write(path.join(root, '.gitignore'), 'node_modules/\ngodot_native/.godot/\ngodot_native/assets/\ngodot_native/data/\ngodot_native/.validation/\ngodot_native/exports/\ngodot_native/.screenshots/\n*.import\n*.log\n');
  write(path.join(root, 'godot_native/project.godot'), '; synthetic project, not a game\n');
  for (const id of [...PREPARATION_IDS.filter(id => id.endsWith('.gd')), 'test_reader.gd']) write(path.join(root, 'godot_native/tests', id), '# mock test\n');
  write(path.join(root, 'godot_native/tools/hook.sh'), '#!/bin/sh\nexit 0\n'); fs.chmodSync(path.join(root, 'godot_native/tools/hook.sh'), 0o755);
  write(path.join(root, 'src/mock.ts'), 'export const mock = true;\n');
  const sourceAsset = 'checked-in source asset\n';
  write(path.join(root, 'src/assets/source-copy.png'), sourceAsset);
  write(path.join(root, 'src/identical-copy.bin'), sourceAsset);
  write(path.join(root, 'godot_native/docs/reference.txt'), 'checked-in documentation\n');
  json(path.join(root, 'godot_native/data/asset_manifest.json'), {assetCount: 1, totalBytes: Buffer.byteLength(sourceAsset), assets: [{path: 'assets/source-copy.png', bytes: Buffer.byteLength(sourceAsset), sha256: hash(sourceAsset)}]});
  git(root, 'init', '-q'); git(root, 'config', 'user.email', 'test@example.invalid'); git(root, 'config', 'user.name', 'Synthetic test');
  git(root, 'add', '.'); git(root, 'add', '-f', 'godot_native/data/asset_manifest.json'); git(root, 'commit', '-qm', 'Synthetic source');
  const expected = {commit: git(root, 'rev-parse', 'HEAD'), tree: git(root, 'rev-parse', 'HEAD^{tree}'), head: 'b'.repeat(40), base: 'c'.repeat(40), run: '12345', attempt: '1', event: 'pull_request'};
  for (const [name, contents] of [
    ['.godot/imported/texture.mock', 'imported bytes'], ['.godot/global_script_class_cache.cfg', 'script classes'], ['.godot/uid_cache.bin', 'uid cache'],
    ['.godot/editor/layout.cfg', 'exclude editor'], ['assets/generated.png', 'generated asset'], ['assets/generated.png.import', 'adjacent metadata'],
    ['assets/source-copy.png', sourceAsset],
    ['data/source/mock.json', '{"source":true}'], ['.validation/media-prepared.json', '{"synthetic":true}'], ['.validation/runner.lock', 'exclude lock'],
    ['tests/fixtures/lake_live_source.json', '{"synthetic":true}'],
    ['exports/game.pck', 'exclude export'], ['.screenshots/test.png', 'exclude screenshot'], ['test.log', 'exclude logs'],
    ['node_modules/skip.js', 'exclude dependency'], ['.git/skip', 'exclude repository metadata']
  ]) write(path.join(root, 'godot_native', name), contents);
  fs.chmodSync(path.join(root, 'godot_native/tests/fixtures/lake_live_source.json'), 0o600);
  fs.chmodSync(path.join(root, 'godot_native/assets/source-copy.png'), 0o600);
  fs.mkdirSync(path.join(root, 'godot_native/empty-source-directory'));
  const project = path.join(root, 'godot_native'), catalog = createValidationCatalog(project, engine);
  const identity = validationIdentity(root, {executable: engine, jobs: 2});
  const rows = catalog.map(stage => {
    const selected = PREPARATION_IDS.includes(stage.id);
    return {id: stage.id, label: stage.id, selected, result: selected ? 'pass' : 'not-run', failed: selected ? false : null, status: selected ? 0 : null,
      ...(selected ? {command: stage.command, args: stage.args, reused: false, signal: null, error: null, output: 'synthetic success\n',
        identity: PREFLIGHT.includes(stage.id) ? null : stageIdentity(identity, stage, fixtureIdentity(root, stage.id))} : {})};
  });
  const meta = {schema: 2, profile: 'prepare', effectiveProfile: 'prepare', gitHead: expected.commit, gitTree: expected.tree, project, executable: engine,
    jobs: 2, completed: true, partial: true, fullSuitePassed: false, inputChangedDuringRun: false, resumable: true, identity, selected: PREPARATION_IDS.length,
    total: rows.length, summary: Object.fromEntries(['not-run', 'pass', 'prepared', 'failed', 'blocked', 'deduplicated'].map(status => [status, rows.filter(row => row.result === status).length]))};
  const preparationReport = path.join(directory, 'preparation.json'); json(preparationReport, rows); json(`${preparationReport}.meta.json`, meta);
  return {directory, root, bundleDir: path.join(directory, 'bundle'), preparationReport, expected};
}
function built() {const value = fixture(); value.result = createBundle(value); return value;}
const verify = (value, options = {}) => verifyBundle({...value, receiptSha: value.result.receiptSha, producerAttempt: '1', ...options});
function changeJson(file, mutation) {const value = read(file); mutation(value); json(file, value);}
function resigned(value, mutation) {
  const receiptFile = path.join(value.bundleDir, 'bundle-receipt.json');
  changeJson(receiptFile, mutation); value.result.receiptSha = hash(fs.readFileSync(receiptFile));
}
function clone(value) {const root = path.join(value.directory, 'consumer'); git(value.directory, 'clone', '-q', value.root, root); return root;}
function modeNormalized(directory) {
  for (const entry of fs.readdirSync(directory, {withFileTypes: true})) {
    const file = path.join(directory, entry.name);
    fs.chmodSync(file, entry.isDirectory() ? 0o755 : 0o644);
    if (entry.isDirectory()) {modeNormalized(file); if (!fs.readdirSync(file).length) fs.rmdirSync(file);}
  }
}

await test('immutable native prepared bundle transport, not completed native acceptance', async t => {
  t.after(() => {if (originalGodot === undefined) delete process.env.GODOT_BIN; else process.env.GODOT_BIN = originalGodot; fs.rmSync(temporary, {recursive: true, force: true});});
  await t.test('exact payload includes imports and preparation evidence; excludes mutable outputs', () => {
    const value = built(), receipt = read(path.join(value.bundleDir, 'bundle-receipt.json'));
    assert.equal(receipt.schema, '755-native-prepared-bundle-v2'); assert.equal(value.result.bundleName, 'godot-native-inputs-12345-1');
    assert.equal(receipt.preparation.fixtureSha256, fixtureIdentity(value.root));
    assert.equal(receipt.preparation.fixtureSha256, fixtureIdentity(value.bundleDir));
    assert.equal(hash(fs.readFileSync(path.join(value.bundleDir, 'bundle-receipt.json'))), value.result.receiptSha);
    for (const name of ['.godot/imported/texture.mock', '.godot/global_script_class_cache.cfg', '.godot/uid_cache.bin', 'assets/generated.png.import', '.validation/media-prepared.json']) assert.ok(receipt.files.some(file => file.path === `godot_native/${name}`), name);
    for (const name of ['.godot/editor/layout.cfg', '.validation/runner.lock', 'exports/game.pck', '.screenshots/test.png', 'test.log', 'node_modules/skip.js', '.git/skip']) assert.ok(!receipt.files.some(file => file.path === `godot_native/${name}`), name);
    const result = verify(value);
    assert.equal(result.verified, true); assert.equal(result.restored, false); assert.deepEqual(result.preparationRows, read(value.preparationReport));
    assert.equal(result.engine.version, '4.7.1.stable.official.mock'); assert.equal(result.totalBytes, receipt.files.reduce((sum, file) => sum + file.bytes, 0));
    assert.equal(result.logicalBytes, result.totalBytes);
    assert.equal(result.transportBytes, result.payloadBytes + result.receiptBytes);
    assert.equal(result.referenceBytes + result.payloadBytes, result.logicalBytes);
    assert.ok(result.referenceBytes > 0 && result.referenceCount > 0);
    assert.equal(receipt.files.find(file => file.path === 'godot_native/project.godot').reference.kind, 'checkout');
    assert.equal(receipt.files.find(file => file.path === 'godot_native/assets/source-copy.png').reference.path, 'src/assets/source-copy.png');
    for (const name of ['godot_native/project.godot', 'godot_native/assets/source-copy.png', 'godot_native/docs', 'godot_native/empty-source-directory']) assert.equal(fs.existsSync(path.join(value.bundleDir, name)), false, name);
  });
  await t.test('fresh consumer restores exact bytes/modes from mode-normalized upload; removes stale generated files', () => {
    const value = built(), root = clone(value);
    write(path.join(root, 'godot_native/.godot/imported/stale'), 'stale');
    write(path.join(root, 'keep-outside-native'), 'untouched');
    modeNormalized(value.bundleDir);
    const before = hash(fs.readFileSync(path.join(value.bundleDir, 'bundle-receipt.json'))), outputReceipt = path.join(value.directory, 'verification/consumer.json');
    const result = verify(value, {root, restore: true, outputReceipt});
    assert.equal(result.restored, true); assert.deepEqual(read(outputReceipt), result);
    assert.equal(fs.statSync(path.join(root, 'godot_native/tools/hook.sh')).mode & 0o777, 0o755);
    assert.equal(fs.statSync(path.join(root, 'godot_native/tests/fixtures/lake_live_source.json')).mode & 0o777, 0o600);
    assert.equal(fs.statSync(path.join(root, 'godot_native/assets/source-copy.png')).mode & 0o777, 0o600);
    assert.equal(fs.statSync(path.join(root, 'src/assets/source-copy.png')).mode & 0o777, 0o644);
    assert.equal(fs.readFileSync(path.join(root, 'godot_native/assets/source-copy.png'), 'utf8'), fs.readFileSync(path.join(root, 'src/assets/source-copy.png'), 'utf8'));
    assert.notEqual(fs.statSync(path.join(root, 'godot_native/assets/source-copy.png')).ino, fs.statSync(path.join(root, 'src/assets/source-copy.png')).ino);
    assert.equal(fs.readFileSync(path.join(root, 'godot_native/docs/reference.txt'), 'utf8'), 'checked-in documentation\n');
    assert.equal(fs.statSync(path.join(root, 'godot_native/empty-source-directory')).isDirectory(), true);
    assert.equal(result.preparedFixtureSha256, fixtureIdentity(root));
    assert.equal(fs.readFileSync(path.join(root, 'godot_native/.godot/imported/texture.mock'), 'utf8'), 'imported bytes');
    assert.equal(fs.existsSync(path.join(root, 'godot_native/.godot/imported/stale')), false);
    assert.equal(fs.readFileSync(path.join(root, 'keep-outside-native'), 'utf8'), 'untouched');
    assert.equal(git(root, 'status', '--porcelain', '--untracked-files=no'), '');
    assert.equal(hash(fs.readFileSync(path.join(value.bundleDir, 'bundle-receipt.json'))), before);
  });
  await t.test('consumer retry permits earlier producer attempt only within same workflow run', () => {
    const value = built(); value.expected.attempt = '3';
    assert.equal(verify(value).producerAttempt, '1'); assert.equal(verify(value).consumerAttempt, '3');
  });
  await t.test('verification does not restore the consumer project or trust existing generated inputs', () => {
    const value = built(), root = clone(value);
    write(path.join(root, 'godot_native/assets/generated.png'), 'stale local generated bytes');
    const result = verify(value, {root});
    assert.equal(result.restored, false);
    assert.equal(fs.readFileSync(path.join(root, 'godot_native/assets/generated.png'), 'utf8'), 'stale local generated bytes');
    assert.equal(fs.existsSync(path.join(root, 'godot_native/.godot')), false);
    assert.equal(fs.existsSync(path.join(root, 'godot_native/tests/fixtures/lake_live_source.json')), false);
  });
  for (const [name, mutation] of [
    ['missing reference', receipt => {delete receipt.files.find(file => file.reference).reference;}],
    ['wrong same-content alias path', receipt => {receipt.files.find(file => file.reference?.kind === 'synced-asset').reference.path = 'src/identical-copy.bin';}],
    ['traversal reference', receipt => {receipt.files.find(file => file.reference).reference.path = '../escape';}],
    ['wrong tracked same-content path', receipt => {receipt.files.find(file => file.path.endsWith('/test_all_scripts_parse.gd')).reference.path = 'godot_native/tests/test_reader.gd';}],
    ['wrong committed blob', receipt => {receipt.files.find(file => file.reference).reference.gitBlob = '0'.repeat(40);}],
    ['wrong reference source mode', receipt => {receipt.files.find(file => file.reference?.kind === 'synced-asset').reference.mode = 0o600;}],
    ['wrong manifest SHA', receipt => {receipt.referenceManifest.sha256 = '0'.repeat(64);}],
    ['wrong manifest mode', receipt => {receipt.referenceManifest.mode = 0o600;}],
    ['wrong manifest path', receipt => {receipt.referenceManifest.path = 'src/identical-copy.bin';}],
  ]) await t.test(`reject trusted receipt ${name}`, () => {const value = built(); resigned(value, mutation); assert.throws(() => verify(value, {restore: true}));});
  for (const [name, relative] of [['synced alias', 'src/assets/source-copy.png'], ['same-path native', 'godot_native/project.godot'], ['asset manifest', 'godot_native/data/asset_manifest.json']]) {
    await t.test(`reject changed ${name} source mode even when Git reports clean`, () => {
      const value = built(); fs.chmodSync(path.join(value.root, relative), 0o600);
      assert.equal(git(value.root, 'status', '--porcelain', '--untracked-files=no'), '');
      assert.throws(() => verify(value, {restore: true}));
    });
    await t.test(`reject changed ${name} bytes even with assume-unchanged Git metadata`, () => {
      const value = built(); git(value.root, 'update-index', '--assume-unchanged', relative); fs.appendFileSync(path.join(value.root, relative), 'changed');
      assert.equal(git(value.root, 'status', '--porcelain', '--untracked-files=no'), '');
      assert.throws(() => verify(value, {restore: true}), /committed Git blob/);
    });
    await t.test(`reject missing ${name} source rather than falling back to native copy`, () => {
      const value = built(); fs.unlinkSync(path.join(value.root, relative)); assert.throws(() => verify(value, {restore: true}));
    });
  }
  await t.test('reject a different checkout commit even when tracked bytes are unchanged', () => {
    const value = built(); git(value.root, 'commit', '--allow-empty', '-qm', 'Different source provenance');
    assert.throws(() => verify(value, {restore: true}), /commit\/tree differs/);
  });
  for (const [name, mutate] of [
    ['wrong checkout SHA', value => {value.expected.commit = '1'.repeat(40);}],
    ['wrong source tree', value => {value.expected.tree = '1'.repeat(40);}],
    ['different head', value => {value.expected.head = '1'.repeat(40);}],
    ['different base', value => {value.expected.base = '1'.repeat(40);}],
    ['different run', value => {value.expected.run = '999';}],
    ['different event', value => {value.expected.event = 'push';}],
    ['malformed consumer attempt', value => {value.expected.attempt = '0';}],
    ['dirty checkout', value => {fs.appendFileSync(path.join(value.root, 'src/mock.ts'), 'changed');}],
    ['receipt tamper', value => {fs.appendFileSync(path.join(value.bundleDir, 'bundle-receipt.json'), ' ');}],
    ['added payload', value => {write(path.join(value.bundleDir, 'godot_native/new-file'), 'extra');}],
    ['added root file', value => {write(path.join(value.bundleDir, 'extra'), 'extra');}],
    ['added empty directory', value => {fs.mkdirSync(path.join(value.bundleDir, 'godot_native/new-dir'));}],
    ['missing import', value => {fs.unlinkSync(path.join(value.bundleDir, 'godot_native/assets/generated.png.import'));}],
    ['altered import', value => {fs.appendFileSync(path.join(value.bundleDir, 'godot_native/.godot/imported/texture.mock'), '!');}],
    ['altered prep report', value => {fs.appendFileSync(path.join(value.bundleDir, 'preparation-report.json'), ' ');}],
    ['symlink payload file', value => {const file = path.join(value.bundleDir, 'godot_native/assets/generated.png'); fs.unlinkSync(file); fs.symlinkSync(path.join(value.root, 'godot_native/project.godot'), file);}],
    ['symlink payload directory', value => {fs.symlinkSync(value.root, path.join(value.bundleDir, 'godot_native/link'));}],
  ]) await t.test(`reject ${name} before any consumer mutation`, () => {
    const value = built(); mutate(value);
    const before = fs.readFileSync(path.join(value.root, 'godot_native/project.godot'));
    assert.throws(() => verify(value, {restore: true})); assert.deepEqual(fs.readFileSync(path.join(value.root, 'godot_native/project.godot')), before);
  });
  for (const [name, options] of [['missing trusted receipt SHA', {receiptSha: undefined}], ['wrong trusted receipt SHA', {receiptSha: '0'.repeat(64)}], ['future producer attempt', {producerAttempt: '2'}], ['invalid producer attempt', {producerAttempt: '01'}]]) {
    await t.test(`reject ${name}`, () => assert.throws(() => verify(built(), options)));
  }
  await t.test('reject mismatched explicit old producer attempt', () => {const value = built(); value.expected.attempt = '3'; assert.throws(() => verify(value, {producerAttempt: '2'}), /source\/run\/producer attempt/);});
  await t.test('reject unsafe receipt path even with newly supplied trusted SHA', () => {const value = built(); resigned(value, receipt => {receipt.files[0].path = '../escape';}); assert.throws(() => verify(value), /Unsafe receipt path/);});
  await t.test('reject unsafe receipt mode even with newly supplied trusted SHA', () => {const value = built(); resigned(value, receipt => {receipt.files[0].mode = 0o4755;}); assert.throws(() => verify(value), /Unsafe receipt path\/mode/);});
  await t.test('reject missing or false producer fixture SHA in trusted receipt', () => {
    const value = built();
    resigned(value, receipt => {delete receipt.preparation.fixtureSha256;});
    assert.throws(() => verify(value), /Preparation receipts/);
    resigned(value, receipt => {receipt.preparation.fixtureSha256 = '0'.repeat(64);});
    assert.throws(() => verify(value), /Preparation receipts/);
  });
  await t.test('reject receipt output inside immutable bundle', () => {const value = built(); assert.throws(() => verify(value, {outputReceipt: path.join(value.bundleDir, 'consumer.json')}), /outside immutable bundle/);});
  await t.test('reject bundle inside source tree or containing source tree', () => {const value = fixture(); assert.throws(() => createBundle({...value, bundleDir: path.join(value.root, 'out')}), /outside the checkout/); assert.throws(() => createBundle({...value, bundleDir: value.directory}), /cannot contain it/);});
  await t.test('reject existing bundle destination', () => {const value = built(); assert.throws(() => createBundle(value), /must not exist/);});
  await t.test('reject symlink producer input', () => {const value = fixture(); fs.symlinkSync(path.join(value.root, 'src/mock.ts'), path.join(value.root, 'godot_native/assets/link')); assert.throws(() => createBundle(value));});
  await t.test('reject symlink consumer project before removal', () => {const value = built(), root = clone(value), project = path.join(root, 'godot_native'); fs.renameSync(project, path.join(root, 'moved')); fs.symlinkSync(path.join(root, 'moved'), project); assert.throws(() => verify(value, {root, restore: true})); assert.equal(fs.lstatSync(project).isSymbolicLink(), true);});
  await t.test('reject symlink destination ancestor', () => {const value = fixture(); fs.symlinkSync(value.directory, path.join(temporary, 'linked')); try {assert.throws(() => createBundle({...value, bundleDir: path.join(temporary, 'linked/bundle')}), /Symlink path/);} finally {fs.unlinkSync(path.join(temporary, 'linked'));}});
  await t.test('reject special input file', () => {const value = fixture(); execFileSync('mkfifo', [path.join(value.root, 'godot_native/assets/fifo')]); assert.throws(() => createBundle(value), /non-regular|Nonregular/);});
  for (const [name, mutation] of [
    ['failed required result', rows => {rows[0].result = 'failed'; rows[0].failed = true;}],
    ['nonzero required result', rows => {rows[0].status = 1;}],
    ['runtime errors in zero-exit output', rows => {rows[0].output = 'SCRIPT ERROR: broken';}],
    ['reused preflight', rows => {rows[0].reused = true;}],
    ['imported preflight', rows => {rows[0].imported = true;}],
    ['missing required result', rows => {rows.splice(0, 1);}],
    ['new unexpected result', rows => {rows.push({...rows[0], id: 'unknown'});}],
    ['duplicate result', rows => {rows[1] = {...rows[0]};}],
    ['unselected pass', rows => {rows.find(row => !row.selected).result = 'pass';}],
    ['wrong fixture identity', rows => {rows.find(row => row.selected && !PREFLIGHT.includes(row.id)).identity = '0'.repeat(64);}],
    ['wrong preparatory command', rows => {rows[0].args = ['--version'];}],
    ['missing selection', rows => {rows[0].selected = false;}]
  ]) await t.test(`reject producer ${name}`, () => {const value = fixture(); changeJson(value.preparationReport, mutation); assert.throws(() => createBundle(value));});
  for (const [name, mutation] of [
    ['changed inputs', meta => {meta.inputChangedDuringRun = true;}], ['absent change check', meta => {delete meta.inputChangedDuringRun;}],
    ['incomplete run', meta => {meta.completed = false;}], ['wrong profile', meta => {meta.profile = 'full';}], ['incorrect full claim', meta => {meta.fullSuitePassed = true;}],
    ['source mismatch', meta => {meta.gitTree = '0'.repeat(40);}], ['error', meta => {meta.error = 'failure';}], ['nonresumable override', meta => {meta.resumable = false;}],
    ['wrong selected count', meta => {meta.selected++;}], ['wrong total', meta => {meta.total++;}], ['wrong summary', meta => {meta.summary.pass++;}],
    ['identity digest tamper', meta => {meta.identity.environmentSha256 = '0'.repeat(64);}], ['wrong engine version', meta => {meta.identity.godotVersion = '4.6.3.stable.official';}]
  ]) await t.test(`reject producer ${name}`, () => {const value = fixture(); changeJson(`${value.preparationReport}.meta.json`, mutation); assert.throws(() => createBundle(value));});
  await t.test('reject new generated source after successful report', () => {const value = fixture(); write(path.join(value.root, 'godot_native/assets/fresh.png'), 'fresh'); assert.throws(() => createBundle(value), /input files changed/);});
  await t.test('reject changed generated source after successful report', () => {const value = fixture(); write(path.join(value.root, 'godot_native/assets/generated.png'), 'changed'); assert.throws(() => createBundle(value), /input files changed/);});
  await t.test('reject added native test not represented by producer report', () => {const value = fixture(); write(path.join(value.root, 'godot_native/tests/test_new.gd'), '#new'); assert.throws(() => createBundle(value), /result catalog/);});
  await t.test('reject installed engine binary mismatch even when version is unchanged', () => {const value = built(), other = path.join(value.directory, 'other-engine'); fs.copyFileSync(engine, other); fs.appendFileSync(other, '#different binary\n'); fs.chmodSync(other, 0o755); process.env.GODOT_BIN = other; try {assert.throws(() => verify(value), /engine version\/binary/);} finally {process.env.GODOT_BIN = engine;}});
  await t.test('CLI create emits exact producer outputs; restore writes receipt outside frozen input', () => {
    const value = fixture(), helper = path.resolve(import.meta.dirname, '../tools/native_validation_bundle.mjs'), output = path.join(value.directory, 'github-output');
    const env = {...process.env, GITHUB_SHA: value.expected.commit, GITHUB_RUN_ID: value.expected.run, GITHUB_RUN_ATTEMPT: value.expected.attempt, GITHUB_EVENT_NAME: value.expected.event, GITHUB_OUTPUT: output};
    const common = ['--root', value.root, '--bundle-dir', value.bundleDir, '--head', value.expected.head, '--base', value.expected.base];
    const result = JSON.parse(execFileSync(process.execPath, [helper, 'create', ...common, '--preparation-report', value.preparationReport], {env, encoding: 'utf8'}));
    assert.equal(fs.readFileSync(output, 'utf8'), `bundle_name=${result.bundleName}\nreceipt_sha=${result.receiptSha}\nproducer_attempt=1\n`);
    const outputReceipt = path.join(value.directory, 'consumer.json');
    const restored = JSON.parse(execFileSync(process.execPath, [helper, 'restore', ...common, '--receipt-sha', result.receiptSha, '--producer-attempt', '1', '--output-receipt', outputReceipt], {env, encoding: 'utf8'}));
    assert.equal(restored.restored, true); assert.equal(read(outputReceipt).receiptSha, result.receiptSha);
  });
});
