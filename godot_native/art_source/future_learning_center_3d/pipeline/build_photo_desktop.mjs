/** Photo-informed design candidates, not scale-certified measurements.
 * Run from the art root after Blender exports the three independent LOD sources.
 * Uses the existing locked pipeline and real Draco integrity check. No remote calls.
 */
import fs from 'node:fs/promises';
import {execFileSync} from 'node:child_process';
const report=JSON.parse(await fs.readFile('review/photo_desktop/build_report.json'));
const ids=['photo_monitor_stand','photo_keyboard','photo_mouse'];
for(const id of ids){
 const records=[0,1,2].map(level=>report.records.filter(r=>r.asset===id&&r.level===level));
 if(records.some(rows=>rows.length!==1))throw Error(`${id}: require exactly one Blender receipt per LOD`);
 const height=records[0][0].sizeBlenderXYZ?.[2],base=`sources/models/photo_desktop/${id}`;
 if(!Number.isFinite(height)||height<=0||height>=1)throw Error(`${id}: invalid candidate height`);
 for(const level of [0,1,2])await fs.access(`${base}/lod${level}_source.glb`);
 await fs.access(`${base}/${id}.blend`);
 execFileSync(process.execPath,['pipeline/build_asset.mjs',`${base}/lod0_source.glb`,`web/assets/models/photo_desktop/${id}`,String(height),'0','1024',`${base}/lod1_source.glb`,`${base}/lod2_source.glb`,'20'],{stdio:'inherit'});
}
