// Source-to-prepared transport integration. Synthetic fixtures, no gameplay or hosted speed claim.
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

const helper = new URL('../tools/native_source_transport.py', import.meta.url);
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
  write(path.join(root, 'godot_native/tools/native_source_transport.py'), fs.readFileSync(helper));
  write(path.join(root, 'godot_native/art_source/.gdignore'), '');
  write(path.join(root, 'godot_native/art_source/original.bin'), Buffer.from([0, 1, 2, 255]));
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
  const sourceBundle = path.join(directory, 'original-source');
  const sourceEnv = {...process.env, GITHUB_REPOSITORY: 'fixture/repo', GITHUB_WORKFLOW: 'native',
    GITHUB_EVENT_NAME: expected.event, GITHUB_RUN_ID: expected.run, GITHUB_RUN_ATTEMPT: expected.attempt, GITHUB_SHA: expected.commit};
  delete sourceEnv.GITHUB_OUTPUT;
  const captured = execFileSync('python3', ['-B', helper.pathname, 'capture', '--root', root, '--bundle-dir', sourceBundle,
    '--head', expected.head, '--base', expected.base], {env: sourceEnv, encoding: 'utf8'});
  const sourceResult = JSON.parse(captured.trim().split('\n').at(-1));
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
  return {sourceBundle, sourceEnv, sourceResult, directory, root, bundleDir: path.join(directory, 'bundle'), preparationReport, expected};
}


test('complete source restore preserves exact validationIdentity and prepared referencePlan', t => {
  t.after(() => {if (originalGodot === undefined) delete process.env.GODOT_BIN; else process.env.GODOT_BIN = originalGodot; fs.rmSync(temporary, {recursive: true, force: true});});
  const value=fixture(), result=createBundle(value);
  const identityBefore=validationIdentity(value.root,{executable:engine,jobs:2});
  const receiptBefore=fs.readFileSync(path.join(value.bundleDir,'bundle-receipt.json'));
  const receipt=JSON.parse(receiptBefore);
  assert.ok(receipt.files.some(f=>f.path==='godot_native/art_source/original.bin' && f.reference?.kind==='checkout'));
  assert.ok(receipt.files.some(f=>f.path==='godot_native/art_source/.gdignore' && f.reference?.kind==='checkout'));
  assert.ok(receipt.files.some(f=>f.reference?.kind==='synced-asset'));
  const indexBefore=git(value.root,'ls-files','--stage');
  const ids=git(value.root,'rev-list','--objects','--filter=blob:none','HEAD').split('\n').map(l=>l.split(' ')[0]).join('\n')+'\n';
  const pack=execFileSync('git',['pack-objects','--stdout'],{cwd:value.root,input:ids});
  const saved=path.join(value.directory,'producer-original');fs.renameSync(value.root,saved);
  fs.mkdirSync(value.root);git(value.root,'init','-q');
  execFileSync('git',['unpack-objects','-q'],{cwd:value.root,input:pack});
  git(value.root,'update-ref','--no-deref','HEAD',value.expected.commit);git(value.root,'read-tree','HEAD');
  execFileSync('python3',['-B',helper.pathname,'restore','--root',value.root,'--bundle-dir',value.sourceBundle,
    '--head',value.expected.head,'--base',value.expected.base,'--manifest-sha',value.sourceResult.manifest_sha,
    '--archive-sha',value.sourceResult.archive_sha,'--producer-attempt','1'],{env:{...value.sourceEnv,GITHUB_RUN_ATTEMPT:'2'}});
  assert.equal(git(value.root,'status','--porcelain'),'');assert.equal(git(value.root,'ls-files','--stage'),indexBefore);
  assert.ok(fs.existsSync(path.join(value.root,'godot_native/art_source/.gdignore')));
  assert.ok(!fs.existsSync(path.join(value.root,'godot_native/.godot/imported/texture.mock')),'source transport must not smuggle derived bytes');
  const verified=verifyBundle({...value,expected:{...value.expected,attempt:'2'},receiptSha:result.receiptSha,producerAttempt:'1',restore:true});
  assert.equal(verified.verified,true);assert.equal(verified.restored,true);
  assert.deepEqual(fs.readFileSync(path.join(value.bundleDir,'bundle-receipt.json')),receiptBefore,'referencePlan receipt stays byte-identical');
  assert.deepEqual(validationIdentity(value.root,{executable:engine,jobs:2}),identityBefore,'all identity fields, including full input SHA, stay exact');
  const roundtripBundle=path.join(value.directory,'prepared-again');
  createBundle({...value,bundleDir:roundtripBundle});
  const receiptAfter=read(path.join(roundtripBundle,'bundle-receipt.json'));
  assert.deepEqual(receiptAfter.files,receipt.files,'same referencePlan and complete native input inventory');
  assert.equal(git(value.root,'show','HEAD:src/mock.ts'),'export const mock = true;');
});
