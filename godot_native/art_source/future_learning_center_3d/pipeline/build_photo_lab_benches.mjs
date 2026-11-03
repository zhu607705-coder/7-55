/** Build the two independent lab-bench photo batches. Run from the art root.
 * Default: all batches. Positional arguments select namespaces or asset IDs.
 * --record-baseline records the 37 unchanged old assets from the immutable commit.
 */
import fs from 'node:fs/promises';
import path from 'node:path';
import crypto from 'node:crypto';
import {fileURLToPath} from 'node:url';
import {execFileSync} from 'node:child_process';

export const baseline = '82abe881a8bab3f23cb2d65c2ac20322a15949fa';
export const art = 'godot_native/art_source/future_learning_center_3d/';
export const groups = {
  photo_lab_center: {expectedCount: 5, ids: [
    'photo_lab_center_four_leg_table', 'photo_lab_center_black_task_chair',
    'photo_lab_center_open_shelf', 'photo_lab_center_plain_storage_box',
    'photo_lab_center_black_transit_case'
  ]},
  photo_electronics: {expectedCount: 6, ids: [
    'photo_electronics_drawer_bench', 'photo_electronics_back_shelf_frame',
    'photo_electronics_wide_instrument_shell', 'photo_electronics_tall_instrument_shell',
    'photo_electronics_green_cutting_mat', 'photo_electronics_open_bin'
  ]}
};
const sha = bytes => crypto.createHash('sha256').update(bytes).digest('hex');

export function baselinePaths() {
  const namespaces = ['photo_desktop', 'photo_living', 'photo_lounge', 'photo_workshop', 'photo_print_honors'];
  const roots = namespaces.flatMap(namespace => [art + 'sources/models/' + namespace, art + 'web/assets/models/' + namespace]);
  const paths = execFileSync('git', ['ls-tree', '-r', '--name-only', '--full-tree', baseline, '--', ...roots], {encoding: 'utf8'}).trim().split('\n').filter(Boolean);
  // Only independent authored assets have lod0_source.glb. Review/legacy assembly
  // files are deliberately not miscounted as additional independent assets.
  const assetKeys = new Set(paths.filter(p => p.endsWith('/lod0_source.glb') && p.includes('/sources/models/')).map(p => p.split('/sources/models/')[1].split('/').slice(0, 2).join('/')));
  return paths.filter(file => {
    const match = file.match(/\/(?:sources\/models|web\/assets\/models)\/([^/]+\/[^/]+)\//);
    return match && assetKeys.has(match[1]) && /\.(blend|glb|png)$|\/manifest\.json$/.test(file);
  });
}

export async function recordBaseline() {
  const files = [], ids = new Set();
  for (const file of baselinePaths()) {
    const data = execFileSync('git', ['show', baseline + ':' + file], {maxBuffer: 128 * 1024 * 1024});
    const relative = file.slice(art.length);
    ids.add(relative.match(/(?:sources\/models|web\/assets\/models)\/[^/]+\/([^/]+)/)[1]);
    files.push({path: relative, bytes: data.length, sha256: sha(data)});
  }
  if (ids.size !== 37 || files.filter(f => /\.blend$/.test(f.path)).length !== 37) throw Error('Baseline must contain all 37 unchanged old assets.');
  await fs.mkdir('review/photo_lab_benches', {recursive: true});
  const report = {schema: 1, baselineCommit: baseline,
    scope: 'Immutable committed bytes of all 37 prior independent assets. They may be instanced by reference but none may be edited. No main-scene or Godot change.',
    assets: [...ids].sort(), files};
  await fs.writeFile('review/photo_lab_benches/baseline.json', JSON.stringify(report, null, 2) + '\n');
  console.log(`Recorded ${ids.size} old assets and ${files.length} files from ${baseline}.`);
  return report;
}

export async function readBatch(namespace) {
  const group = groups[namespace];
  if (!group) throw Error(`Unknown namespace ${namespace}`);
  const bytes = await fs.readFile(`review/${namespace}/build_report.json`);
  const report = JSON.parse(bytes);
  if (report.units !== 'm') throw Error(`${namespace}: source units must be metres`);
  const ids = [...new Set(report.records.map(r => r.asset))];
  if (ids.length !== group.expectedCount || ids.some(id => !/^[a-z][a-z0-9_]+$/.test(id))) throw Error(`${namespace}: incomplete or invalid asset IDs`);
  if (!group.ids.length || ids.slice().sort().join(',') !== group.ids.slice().sort().join(',')) throw Error(`${namespace}: authored IDs do not match the fixed delivery contract`);
  return {report, bytes, ids};
}

export async function build(selected = Object.keys(groups)) {
  const known = new Set([...Object.keys(groups), ...Object.values(groups).flatMap(g => g.ids)]);
  if (!selected.length || selected.some(id => !known.has(id))) throw Error('Select known lab-bench namespaces or asset IDs only.');
  for (const [namespace, group] of Object.entries(groups)) {
    if (!selected.includes(namespace) && !group.ids.some(id => selected.includes(id))) continue;
    const {report, ids} = await readBatch(namespace);
    for (const id of ids.filter(id => selected.includes(namespace) || selected.includes(id))) {
      const rows = [0, 1, 2].map(level => report.records.filter(r => r.asset === id && r.level === level));
      if (rows.some(r => r.length !== 1)) throw Error(`${id}: exactly one receipt per LOD is required`);
      const height = rows[0][0].sizeBlenderXYZ?.[2], base = `sources/models/${namespace}/${id}`;
      if (!(Number.isFinite(height) && height > 0 && height < 5)) throw Error(`${id}: invalid metric height`);
      const blend = await fs.readFile(`${base}/${id}.blend`);
      if (blend.subarray(0, 7).toString() !== 'BLENDER') throw Error(`${id}: missing native editable source`);
      for (const level of [0, 1, 2]) if (sha(await fs.readFile(`${base}/lod${level}_source.glb`)) !== rows[level][0].sha256) throw Error(`${id} LOD${level}: source receipt hash mismatch`);
      execFileSync(process.execPath, ['pipeline/build_asset.mjs', `${base}/lod0_source.glb`,
        `web/assets/models/${namespace}/${id}`, String(height), '0', '1024',
        `${base}/lod1_source.glb`, `${base}/lod2_source.glb`, '20'], {stdio: 'inherit'});
    }
  }
}

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  const args = process.argv.slice(2);
  if (args.length === 1 && args[0] === '--record-baseline') await recordBaseline();
  else await build(args.length ? args : undefined);
}
