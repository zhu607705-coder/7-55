/** Build the three independent photo-expansion batches. Run from the art root.
 * Default: all batches. Positional arguments select namespaces or asset IDs.
 * --record-baseline records the 18 unchanged old assets from the immutable commit.
 */
import fs from 'node:fs/promises';
import path from 'node:path';
import crypto from 'node:crypto';
import {fileURLToPath} from 'node:url';
import {execFileSync} from 'node:child_process';

export const baseline = 'caa2f4253e0df29af09d774f77c2921f0afa07b0';
export const art = 'godot_native/art_source/future_learning_center_3d/';
export const excludedOldAsset = 'photo_pantry_grey_roundfront_appliance';
export const groups = {
  photo_lounge: {expectedCount: 6, ids: [
    'photo_lounge_orange_single', 'photo_lounge_orange_double', 'photo_lounge_round_table',
    'photo_lounge_grey_bar_chair', 'photo_lounge_square_stool', 'photo_lounge_window_counter'
  ]},
  photo_workshop: {expectedCount: 6, ids: [
    'photo_workshop_green_tool_cart', 'photo_workshop_square_hole_board', 'photo_workshop_blue_driver_rack',
    'photo_workshop_red_flat_case', 'photo_workshop_black_red_case', 'photo_workshop_small_vise'
  ]},
  photo_print_honors: {expectedCount: 6, ids: [
    'photo_print_white_mfp', 'photo_print_black_compact', 'photo_honors_display_cabinet',
    'photo_honors_lightwood_frame', 'photo_honors_certificate_stand', 'photo_honors_trophy_silhouette'
  ]}
};
const sha = bytes => crypto.createHash('sha256').update(bytes).digest('hex');

export function baselinePaths() {
  return execFileSync('git', ['ls-tree', '-r', '--name-only', '--full-tree', baseline, '--',
    art + 'sources/models/photo_desktop', art + 'web/assets/models/photo_desktop',
    art + 'sources/models/photo_living', art + 'web/assets/models/photo_living'
  ], {encoding: 'utf8'}).trim().split('\n').filter(file =>
    !file.includes('/' + excludedOldAsset + '/') &&
    !file.includes('/photo_pantry_assembly/') && /\.(blend|glb|png)$|\/manifest\.json$/.test(file)
  );
}

export async function recordBaseline() {
  const files = [], ids = new Set();
  for (const file of baselinePaths()) {
    const data = execFileSync('git', ['show', baseline + ':' + file], {maxBuffer: 128 * 1024 * 1024});
    const relative = file.slice(art.length);
    ids.add(relative.match(/(?:sources\/models|web\/assets\/models)\/(?:photo_desktop|photo_living)\/([^/]+)/)[1]);
    files.push({path: relative, bytes: data.length, sha256: sha(data)});
  }
  if (ids.size !== 18 || files.filter(f => /\.blend$/.test(f.path)).length !== 18) throw Error('Baseline must contain all 18 unchanged old assets.');
  await fs.mkdir('review/photo_expansion', {recursive: true});
  const report = {schema: 1, baselineCommit: baseline, excludedAsset: excludedOldAsset,
    scope: 'Immutable committed bytes of 18 prior independent assets. Only the grey appliance is approved for revision; no main scene or Godot change.',
    assets: [...ids].sort(), files};
  await fs.writeFile('review/photo_expansion/baseline.json', JSON.stringify(report, null, 2) + '\n');
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
  if (!selected.length || selected.some(id => !known.has(id))) throw Error('Select known photo-expansion namespaces or asset IDs only.');
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
