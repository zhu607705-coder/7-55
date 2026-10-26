// Synthetic sparse-checkout/module/transport contracts; no browser or gameplay claim.
import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import {spawnSync} from 'node:child_process';
import {createHash} from 'node:crypto';
import {test} from 'node:test';
import {createBundle} from '../tools/web_acceptance_bundle.mjs';

const repository = path.resolve(import.meta.dirname, '../..');
const hash = bytes => createHash('sha256').update(bytes).digest('hex');
const entrypoints = ['verify_web_export.mjs', 'web_acceptance_bundle.mjs'];
const closure = new Set();
function visit(relative) {
  assert.ok(relative.startsWith('godot_native/tools/'), `Consumer dependency escaped exact tools checkout: ${relative}`);
  if (closure.has(relative)) return;
  closure.add(relative);
  const source = fs.readFileSync(path.join(repository, relative), 'utf8');
  // Traverse the actual checked-in static imports and source-hash dependencies.
  const references = [...source.matchAll(/\bfrom\s+['"]([^'"]+)['"]|\bimport\s*\(\s*['"]([^'"]+)['"]\s*\)|new URL\(\s*['"]([^'"]+)['"]\s*,\s*import\.meta\.url\s*\)/g)].map(match => match[1] || match[2] || match[3]);
  for (const reference of references) {
    if (reference.startsWith('node:')) continue;
    assert.ok(reference.startsWith('./') || reference.startsWith('../'), `Unexpected consumer package/module: ${reference}`);
    visit(path.posix.normalize(path.posix.join(path.posix.dirname(relative), reference)));
  }
}
for (const entry of entrypoints) visit(`godot_native/tools/${entry}`);

await test('actual Web consumer dependency closure fits the exact tools-only sparse checkout', async t => {
  assert.deepEqual([...closure].sort(), ['verify_web_export.mjs', 'web_acceptance_bundle.mjs', 'web_phone_navigation.mjs', 'web_phone_recovery.mjs', 'web_phone_shards.mjs'].map(name => `godot_native/tools/${name}`).sort());
  const temporary = fs.mkdtempSync(path.join(os.tmpdir(), '755-web-sparse-consumer-'));
  t.after(() => fs.rmSync(temporary, {recursive:true, force:true}));
  const full = path.join(temporary, 'full'), sparse = path.join(temporary, 'sparse');
  fs.mkdirSync(full);
  const git = (cwd, ...args) => {
    const result = spawnSync('git', args, {cwd, encoding:'utf8'});
    assert.equal(result.status, 0, result.stderr); return result.stdout.trim();
  };
  git(full, 'init', '--initial-branch=fixture');
  for (const relative of [...closure, '.gitignore', 'godot_native/.gitignore']) {
    fs.mkdirSync(path.dirname(path.join(full, relative)), {recursive:true});
    fs.copyFileSync(path.join(repository, relative), path.join(full, relative));
  }
  fs.mkdirSync(path.join(full, 'src/assets'), {recursive:true});
  fs.writeFileSync(path.join(full, 'src/assets/synthetic-not-runtime.txt'), 'This source asset must not be materialized in the consumer.');
  git(full, 'add', '--all');
  git(full, '-c', 'user.name=Sparse contract', '-c', 'user.email=sparse-contract@example.invalid', 'commit', '-m', 'Synthetic sparse checkout fixture');
  const commit = git(full, 'rev-parse', 'HEAD'), tree = git(full, 'rev-parse', 'HEAD^{tree}');
  // A local fixture clone tests real Git cone semantics without network or a
  // production checkout mutation. Workflow contracts enforce blob:none separately.
  git(temporary, 'clone', '--no-local', '--no-checkout', full, sparse);
  git(sparse, 'sparse-checkout', 'set', '--cone', 'godot_native/tools');
  git(sparse, 'checkout', '--detach', commit);
  assert.equal(git(sparse, 'rev-parse', 'HEAD'), commit);
  assert.equal(git(sparse, 'rev-parse', 'HEAD^{tree}'), tree);
  assert.equal(fs.existsSync(path.join(sparse, 'src/assets/synthetic-not-runtime.txt')), false);
  assert.ok(fs.existsSync(path.join(sparse, 'godot_native/.gitignore')), 'Cone checkout must retain parent ignore rules');
  for (const relative of closure) assert.equal(hash(fs.readFileSync(path.join(sparse, relative))), hash(fs.readFileSync(path.join(repository, relative))));
  const selfTest = () => spawnSync(process.execPath, ['godot_native/tools/verify_web_export.mjs', '--self-test-paths'], {cwd:sparse, encoding:'utf8'});
  await t.test('real runner loads every helper without native/source assets', () => {
    const result = selfTest(); assert.equal(result.status, 0, result.stderr); assert.match(result.stdout, /Artifact path self-test PASS/);
  });

  const exportDir = path.join(temporary, 'site'), fixturesDir = path.join(temporary, 'earned'), sourceFile = path.join(temporary, 'source.json'), bundleDir = path.join(temporary, 'bundle');
  fs.mkdirSync(exportDir); fs.mkdirSync(fixturesDir);
  const expected = {commit, tree, head:commit, base:null, run:'12345', attempt:'1', event:'push', dirty:false};
  const source = {event:expected.event, head:commit, base:null, checkedOutCommit:commit, tree, run:expected.run, attempt:'1', dirty:false};
  const json = (file, value) => fs.writeFileSync(file, JSON.stringify(value, null, 2) + '\n');
  json(sourceFile, source); json(path.join(fixturesDir, 'fixture-provenance.json'), {source, scope:'Synthetic transport input, not earned gameplay.'});
  const inputFiles = [{path:'scripts/synthetic.gd', bytes:10, sha256:hash('mock source')}];
  json(path.join(exportDir, 'source-inputs.json'), {files:inputFiles, digest:hash(JSON.stringify(inputFiles))});
  fs.writeFileSync(path.join(exportDir, 'index.html'), 'Synthetic non-executable export');
  const html = fs.readFileSync(path.join(exportDir, 'index.html'));
  json(path.join(exportDir, 'build-manifest.json'), {schema:'7-55-godot-web-release/v1', sourceCommit:commit, sourceTree:tree, sourceDirty:false, sourceChanges:[],
    engine:'4.7.1.stable.official', runtime:'godot-web', production:true, storyOnly:true, threads:false, chapterShortcuts:false,
    bootChunks:{schema:'755-boot-chunks-v1'}, delivery:'chapter-content-packs', content:{exactCoverage:true,packs:1}, initialPayloadBytes:html.length,
    sourceInputSha256:hash(JSON.stringify(inputFiles)), sourceInputCount:1, files:[{path:'index.html',bytes:html.length,sha256:hash(html)}], totalPayloadBytes:html.length});
  const result = createBundle({bundleDir, exportDir, fixturesDir, sourceFile, expected});
  const environment = {...process.env, GITHUB_SHA:commit, ACCEPTANCE_HEAD_SHA:commit, ACCEPTANCE_BASE_SHA:'', GITHUB_RUN_ID:'12345', GITHUB_RUN_ATTEMPT:'1', GITHUB_EVENT_NAME:'push'};
  const verify = (extra = {}) => spawnSync(process.execPath, ['godot_native/tools/web_acceptance_bundle.mjs', 'verify', '--bundle-dir', bundleDir,
    '--receipt-sha', result.receiptSha, '--producer-attempt', '1', '--output-receipt', 'godot_native/exports/verification/sparse-inputs.json'], {cwd:sparse, env:{...environment,...extra}, encoding:'utf8'});
  await t.test('full sealed-byte verification retains commit/tree/clean-checkout proof', () => {
    const checked = verify(); assert.equal(checked.status, 0, checked.stderr);
    assert.equal(git(sparse, 'status', '--porcelain', '--untracked-files=all'), '', 'Evidence output must remain ignored under cone checkout');
    const receipt = JSON.parse(fs.readFileSync(path.join(sparse, 'godot_native/exports/verification/sparse-inputs.json')));
    assert.deepEqual(receipt.source, source); assert.equal(receipt.receiptSha, result.receiptSha); assert.equal(receipt.verified, true);
    assert.notEqual(verify({GITHUB_SHA:'a'.repeat(40)}).status, 0, 'Sparse checkout cannot accept a different triggering commit');
    fs.appendFileSync(path.join(bundleDir, 'web-release/index.html'), 'tampered');
    assert.notEqual(verify().status, 0, 'Sparse checkout cannot accept altered runtime bytes');
    fs.writeFileSync(path.join(bundleDir, 'web-release/index.html'), html);
    assert.equal(verify().status, 0, 'Restore the exact bundle so the next negative isolates missing source');
  });
  await t.test('missing transitive phone helper fails closed before browser launch', () => {
    fs.rmSync(path.join(sparse, 'godot_native/tools/web_phone_shards.mjs'));
    const missing = selfTest(); assert.notEqual(missing.status, 0); assert.match(missing.stderr, /ERR_MODULE_NOT_FOUND|Cannot find module/);
    const changed = verify();
    assert.notEqual(changed.status, 0, 'A modified sparse validator checkout cannot certify inputs');
    assert.match(changed.stderr, /Acceptance checkout must be clean/);
  });
});
