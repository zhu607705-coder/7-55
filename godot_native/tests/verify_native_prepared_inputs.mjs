import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import vm from 'node:vm';
import {stripTypeScriptTypes} from 'node:module';
import {fileDigest} from '../tools/native_validation_identity.mjs';
import {applySourceTextRevisions} from '../tools/apply-zh-text-revisions.mjs';
const project = path.resolve(import.meta.dirname, '..'), root = path.dirname(project);
const read = file => JSON.parse(fs.readFileSync(file, 'utf8'));
function walk(directory) {return fs.readdirSync(directory, {withFileTypes: true}).flatMap(e => e.isDirectory() ? walk(path.join(directory, e.name)) : [path.join(directory, e.name)]);}
const manifest = read(path.join(project, 'data/asset_manifest.json'));
const originals = walk(path.join(root, 'src/assets')).map(f => path.relative(path.join(root, 'src'), f)).sort();
assert.deepEqual(manifest.assets.map(a => a.path).sort(), originals, 'Source asset set changed: run native:sync');
for (const asset of manifest.assets) {
 assert.equal(fileDigest(path.join(root, 'src', asset.path)), asset.sha256, `Stale source manifest: ${asset.path}`);
 assert.equal(fileDigest(path.join(project, asset.path)), asset.sha256, `Stale copied asset: ${asset.path}`);
}
const jsonFiles = walk(path.join(root, 'src/data')).filter(f => f.endsWith('.json'));
for (const original of jsonFiles) {
 const relative = path.relative(path.join(root, 'src/data'), original);
 const expected = applySourceTextRevisions(root, relative, read(original));
 assert.deepEqual(read(path.join(project, 'data/source', relative)), expected, `Stale source JSON: ${relative}`);
}
const source = fs.readFileSync(path.join(root, 'src/core/GameState.ts'), 'utf8');
const body = source.split('export function createInitialGameState(): GameState {')[1].split('\nexport function createGameStore')[0];
const initial = vm.runInNewContext('(function(){' + body + ')()', {DEFAULT_PHONE_HOME_APP_ORDER: ['wechat','tiyi','zjuding','settings','photos','timeline_recovery','voice_memos','cc98','control_center','clock']});
assert.deepEqual(read(path.join(project, 'data/initial_state.json')), JSON.parse(JSON.stringify(initial)), 'Stale source initial state');
const itemModule = await import('data:text/javascript;base64,' + Buffer.from(stripTypeScriptTypes(fs.readFileSync(path.join(root, 'src/data/itemCatalog.ts'), 'utf8'), {mode: 'transform'})).toString('base64'));
assert.deepEqual(read(path.join(project, 'data/native/item_catalog.json')), itemModule.ITEM_CATALOG, 'Stale item catalog');
const mediaFile = path.join(project, '.validation/media-prepared.json');
assert.ok(fs.existsSync(mediaFile), 'Missing media preparation receipt: run npm run native:media');
const media = read(mediaFile);
assert.equal(media.converterSha256, fileDigest(path.join(project, 'tools/convert_media.sh')), 'Media converter changed: run native:media');
const expectedClips = ['rpg/cinematics/chapter4-prologue/chapter35_to_chapter4_h3_transition', 'rpg/cinematics/qizhen-rain-rescue/qizhen_rain_rescue_hailuo23_v01'];
assert.deepEqual(media.reports.map(r => r.input).sort(), expectedClips.map(f => `assets/${f}.mp4`).sort());
for (const row of media.reports) {
 assert.equal(row.fullStreamValidation, true);
 assert.equal(fileDigest(path.join(project, row.input)), row.sourceSha256, `Stale media input ${row.input}`);
 assert.equal(fileDigest(path.join(project, row.output)), row.outputSha256, `Stale media output ${row.output}`);
}
console.log(`Prepared inputs verified: ${originals.length} assets, ${jsonFiles.length} JSON files, source state/items, 2 complete converted streams.`);
