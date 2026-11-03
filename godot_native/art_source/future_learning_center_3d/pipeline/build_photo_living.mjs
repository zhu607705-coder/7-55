/** Build independent photo-informed living-area candidates. Run from the art root.
 * Dimensions are estimates, not a scan or manufacturer CAD. No scene integration.
 * Optional positional asset IDs allow a source owner to rebuild only their batch.
 */
import fs from 'node:fs/promises';
import path from 'node:path';
import crypto from 'node:crypto';
import {fileURLToPath} from 'node:url';
import {execFileSync} from 'node:child_process';

export const batches = {
  furniture_build_report: [
    'photo_living_capsule_table', 'photo_living_caramel_armchair',
    'photo_living_pale_shell_chair', 'photo_living_orange_office_chair',
    'photo_living_wood_planter'
  ],
  pantry_build_report: [
    'photo_pantry_counter', 'photo_pantry_sink_faucets',
    'photo_pantry_grey_roundfront_appliance', 'photo_pantry_white_cleartop_appliance',
    'photo_pantry_backsplash_shelves', 'photo_side_by_side_fridge',
    'photo_fridge_wood_surround'
  ],
  waste_bins_build_report: ['waste_bin_grey', 'waste_bin_blue']
};

export async function build(selected = Object.values(batches).flat()) {
  const known = new Set(Object.values(batches).flat());
  if (!selected.length || selected.some(id => !known.has(id))) {
    throw Error('Select known photo-living asset IDs only.');
  }
  const sha = bytes => crypto.createHash('sha256').update(bytes).digest('hex');
  for (const [reportName, ids] of Object.entries(batches)) {
    if (!ids.some(id => selected.includes(id))) continue;
    const report = JSON.parse(await fs.readFile(`review/photo_living/${reportName}.json`));
    if (report.units !== 'm') throw Error(`${reportName}: authoring units must be metres`);
    for (const id of ids.filter(id => selected.includes(id))) {
      const records = [0, 1, 2].map(level => report.records.filter(r => r.asset === id && r.level === level));
      if (records.some(rows => rows.length !== 1)) throw Error(`${id}: exactly one source receipt per LOD is required`);
      const height = records[0][0].sizeBlenderXYZ?.[2];
      if (!(Number.isFinite(height) && height > 0 && height < 5)) throw Error(`${id}: invalid metric height`);
      const base = `sources/models/photo_living/${id}`;
      const blend = await fs.readFile(`${base}/${id}.blend`);
      if (blend.subarray(0, 7).toString() !== 'BLENDER') throw Error(`${id}: missing editable Blender source`);
      for (const level of [0, 1, 2]) {
        const bytes = await fs.readFile(`${base}/lod${level}_source.glb`);
        if (sha(bytes) !== records[level][0].sha256) throw Error(`${id} LOD${level}: receipt does not match source bytes`);
      }
      execFileSync(process.execPath, [
        'pipeline/build_asset.mjs', `${base}/lod0_source.glb`,
        `web/assets/models/photo_living/${id}`, String(height), '0', '1024',
        `${base}/lod1_source.glb`, `${base}/lod2_source.glb`, '20'
      ], {stdio: 'inherit'});
    }
  }
}

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  await build(process.argv.length > 2 ? process.argv.slice(2) : undefined);
}
