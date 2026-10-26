import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import {createHash} from 'node:crypto';
import {spawnSync} from 'node:child_process';
import {fileURLToPath} from 'node:url';
import assert from 'node:assert/strict';

const project = path.dirname(fileURLToPath(import.meta.url));
const data = JSON.parse(fs.readFileSync(path.join(project, 'data/north_plan_registry.json'), 'utf8'));
assert.equal(data.schemaVersion, 1);
assert.equal(data.navigationEnabled, false);
assert.deepEqual(data.buildings.map(b => b.id), ['north1', 'north2', 'north3', 'north4']);
const hashes = new Set();
for (const building of data.buildings) {
  assert.equal(building.currentTotalFloorCount, null);
  assert.deepEqual(building.documentedFloorNumbers, building.id === 'north1' || building.id === 'north2' ? [1, 2, 3, 4] : [1, 2, 3, 4, 5]);
  assert.equal(building.floors.length, building.documentedFloorNumbers.length);
  const source = data.sources[building.sourceId];
  for (const field of ['noticeUrl', 'archiveUrl']) assert.equal(new URL(source[field]).hostname, 'www.grs.zju.edu.cn');
  for (const floor of building.floors) {
    assert.equal(floor.id, `${building.id}:f${floor.number}`);
    assert.equal(floor.geometry.status, 'not_extracted');
    assert.deepEqual(floor.objectLayer.instances, []);
    if (floor.number !== 1) {
      assert.equal(floor.art, null);
      assert.equal(floor.artStatus, 'not_created');
      continue;
    }
    assert.match(floor.art.path, /^res:\/\/assets\/north[1-4]-floor1-empty-architecture-candidate-v2\.png$/);
    const bytes = fs.readFileSync(path.join(project, floor.art.path.slice(6)));
    const hash = createHash('sha256').update(bytes).digest('hex');
    assert.equal(hash, floor.art.sha256, 'Approved original remains byte-identical');
    hashes.add(hash);
    assert.equal(bytes.readUInt32BE(16), floor.art.dimensions[0]);
    assert.equal(bytes.readUInt32BE(20), floor.art.dimensions[1]);
    assert.equal(bytes[25], 6, 'RGBA PNG color type');
  }
}
assert.equal(hashes.size, 4, 'Four independent plates; not mirrored or duplicated resources');
const config = fs.readFileSync(path.join(project, 'project.godot'), 'utf8');
assert.ok(!config.includes('[autoload]'), 'No story state or persistence autoload');
assert.ok(fs.existsSync(path.join(project, '.gdignore')), 'Parent project must ignore the independent sample');
const executable = process.env.GODOT_BIN || 'godot';
const sandbox = fs.mkdtempSync(path.join(os.tmpdir(), '755-north-preview-'));
const env = {...process.env};
for (const [key, directory] of Object.entries({XDG_DATA_HOME: 'data', XDG_CACHE_HOME: 'cache', XDG_CONFIG_HOME: 'config', XDG_STATE_HOME: 'state'})) {
  env[key] = path.join(sandbox, directory);
  fs.mkdirSync(env[key]);
}
const version = spawnSync(executable, ['--headless', '--version'], {encoding: 'utf8', env});
assert.equal(version.status, 0, version.stderr);
assert.match(version.stdout, /^4\.7\.1\.stable\./, 'Use the project-pinned Godot 4.7.1, not the system fallback');
const gpu = process.argv.includes('--gpu');
if (gpu) {
  assert.ok(process.env.NORTH_PREVIEW_CAPTURE_DIR, '--gpu needs NORTH_PREVIEW_CAPTURE_DIR outside the deliverable');
  fs.mkdirSync(process.env.NORTH_PREVIEW_CAPTURE_DIR, {recursive: true});
}
const report = {engine: version.stdout.trim(), scope: 'independent read-only preview, not production game acceptance', stages: []};
function run(label, args) {
  const result = spawnSync(executable, ['--path', project, '--audio-driver', 'Dummy', ...args], {encoding: 'utf8', env, timeout: 120000, maxBuffer: 16 * 1024 * 1024});
  const output = (result.stdout || '') + (result.stderr || '');
  const failed = Boolean(result.error) || result.status !== 0 || /SCRIPT ERROR:|Parse Error:|(?:^|\n)ERROR:|TEST FAILED/.test(output);
  report.stages.push({label, status: result.status, failed, output});
  fs.writeFileSync(path.join(sandbox, 'report.json'), JSON.stringify(report, null, 2));
  console.log(`${failed ? 'FAIL' : 'PASS'} ${label}`);
  if (failed) { console.error(output); throw result.error || new Error(label); }
  console.log(output.split('\n').filter(line => /checks,/.test(line)).join('\n'));
}
run('Clean sample import/parse', ['--headless', '--editor', '--import', '--quit']);
run(gpu ? 'Rendered UI / input / captures' : 'Headless registry / UI / input', [...(gpu ? [] : ['--headless']), '--script', 'res://tests/test_preview.gd']);
run('Native suite registry regression', ['--headless', '--script', path.resolve(project, '../../tests/test_north_real_plan_registry.gd')]);
run('Ordinary sample startup', ['--headless', '--quit-after', '8']);
console.log(`Evidence: ${path.join(sandbox, 'report.json')}`);
console.log('Not run here: full native suite, production Godot Web acceptance, physical-device acceptance.');
