/** Run only after all three authoring workers confirm a source freeze. */
import fs from 'node:fs/promises';
import {execFileSync} from 'node:child_process';
import {NodeIO,getBounds} from '@gltf-transform/core';
const groups={photo_instruments:6,photo_lab_contents:7,photo_bench_contents:7};
const io=new NodeIO();const selected=process.argv[2];
for(const [group,count] of Object.entries(groups)){
 if(selected&&group!==selected)continue;
 const root=`sources/models/${group}`,ids=(await fs.readdir(root,{withFileTypes:true})).filter(e=>e.isDirectory()).map(e=>e.name).sort();
 if(ids.length!==count)throw Error(`${group}: expected ${count} sources, found ${ids.length}`);
 for(const id of ids){
  const base=`${root}/${id}`;await fs.access(`${base}/${id}.blend`);
  for(const n of [0,1,2])await fs.access(`${base}/lod${n}_source.glb`);
  const b=getBounds((await io.read(`${base}/lod0_source.glb`)).getRoot().listScenes()[0]);
  execFileSync(process.execPath,['pipeline/build_asset.mjs',`${base}/lod0_source.glb`,`web/assets/models/${group}/${id}`,String(b.max[1]-b.min[1]),'0','1024',`${base}/lod1_source.glb`,`${base}/lod2_source.glb`,'20'],{stdio:'inherit'});
 }
}
