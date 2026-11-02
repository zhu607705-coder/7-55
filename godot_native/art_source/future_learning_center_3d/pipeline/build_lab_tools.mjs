import fs from 'node:fs/promises';
import {execFileSync} from 'node:child_process';
const report=JSON.parse(await fs.readFile('review/lab_tools/build_report.json'));
for(const id of ['printer_enclosure_study','laser_enclosure_study','bench_power_supply']){
 const near=report.records.find(r=>r.asset===id&&r.level===0),base=`sources/models/lab_tools/${id}`;
 execFileSync(process.execPath,['pipeline/build_asset.mjs',`${base}/lod0_source.glb`,`web/assets/models/lab_tools/${id}`,String(near.sizeBlenderXYZ[2]),'0','1024',`${base}/lod1_source.glb`,`${base}/lod2_source.glb`,'20'],{stdio:'inherit'});
}
