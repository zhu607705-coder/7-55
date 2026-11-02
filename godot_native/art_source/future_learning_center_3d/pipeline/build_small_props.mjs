import fs from 'node:fs/promises';
import {execFileSync} from 'node:child_process';
const report=JSON.parse(await fs.readFile('review/small_props/build_report.json'));
for(const id of ['caliper_150','screwdriver_3x100','display_tray']){
 const near=report.records.find(r=>r.asset===id&&r.level===0),base=`sources/models/small_props/${id}`;
 execFileSync(process.execPath,['pipeline/build_asset.mjs',`${base}/lod0_source.glb`,`web/assets/models/small_props/${id}`,String(near.sizeBlenderXYZ[2]),'0','1024',`${base}/lod1_source.glb`,`${base}/lod2_source.glb`],{stdio:'inherit'});
}
