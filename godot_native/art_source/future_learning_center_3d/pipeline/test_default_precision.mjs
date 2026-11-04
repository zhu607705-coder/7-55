// Prove the optional20-bit route did not silently change existing16-bit outputs.
import fs from 'node:fs/promises';
import os from 'node:os';
import path from 'node:path';
import assert from 'node:assert/strict';
import {execFileSync} from 'node:child_process';
const base='sources/models/small_props/caliper_150',old='web/assets/models/small_props/caliper_150';
const manifest=JSON.parse(await fs.readFile(old+'/manifest.json')),temp=await fs.mkdtemp(path.join(os.tmpdir(),'flc-default-precision-'));
const rows=[];
try{
 execFileSync(process.execPath,['pipeline/build_asset.mjs',base+'/lod0_source.glb',temp,String(manifest.calibration.targetHeight),'0','1024',base+'/lod1_source.glb',base+'/lod2_source.glb'],{stdio:'pipe'});
 for(let level=0;level<3;level++)for(const suffix of ['.glb','.draco.glb']){
  const file=`lod${level}${suffix}`,pass=(await fs.readFile(old+'/'+file)).equals(await fs.readFile(path.join(temp,file)));
  rows.push({file,pass});assert.ok(pass,'Default encoding changed '+file);
 }
 await fs.writeFile('review/lab_tools/default_pipeline_regression.json',JSON.stringify({checks:rows.length,failures:0,rows},null,2)+'\n');
 console.log('Default encoding:6 files byte-identical');
}finally{await fs.rm(temp,{recursive:true,force:true});}
