#!/usr/bin/env node
// Executes the real ownership planner on a controlled inventory. This is not
// a Web export test: verify_web_content_boot_assets checks actual packed bytes.
import fs from 'node:fs';
import path from 'node:path';
import os from 'node:os';
import assert from 'node:assert/strict';
import crypto from 'node:crypto';
import {spawnSync} from 'node:child_process';
import {fileURLToPath} from 'node:url';
const project=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..');
const tmp=fs.mkdtempSync(path.join(os.tmpdir(),'755-ui-font-pack-'));
try {
  const fonts=['ui_assets/fonts/MorningNote-Regular.ttf','ui_assets/fonts/MorningNote-Medium.ttf','assets/rpg/fonts/fusion_pixel_12px_proportional_zh_hans.ttf'];
  const licenses=['ui_assets/fonts/OFL.txt','ui_assets/fonts/MORNING_NOTE_OFL.txt','assets/rpg/fonts/licenses/FUSION_PIXEL_FONT_OFL.txt'];
  const records=[['project.binary',Buffer.from('controlled ownership fixture, not a PCK')]];
  const required=[];
  for(const logical of fonts) {
    const metadata=fs.readFileSync(path.join(project,logical+'.import'));
    const target=metadata.toString().match(/path="res:\/\/([^"\n]+)"/)[1];
    records.push([logical+'.import',metadata],[target,fs.readFileSync(path.join(project,target))]);
    required.push(logical+'.import',target);
  }
  for(const id of ['messages','sports','campus','settings','album','recovery','voice','forum','controls','clock']) {
    const logical='ui_assets/phone_icons/'+id+'.svg';
    const metadata=fs.readFileSync(path.join(project,logical+'.import'));
    const target=metadata.toString().match(/path="res:\/\/([^"\n]+)"/)[1];
    records.push([logical+'.import',metadata],[target,fs.readFileSync(path.join(project,target))]);
    required.push(logical+'.import',target);
  }
  for(const logical of licenses) {
    records.push([logical,fs.readFileSync(path.join(project,logical))]);required.push(logical);
  }
  records.push(['assets/rpg/interiors/library_fixture.png',Buffer.from('deferred chapter-two fixture')]);
  let offset=0;
  const entries=records.map(([name,bytes])=>{
    const entry={path:name,offset,bytes:bytes.length,md5:crypto.createHash('md5').update(bytes).digest('hex')};offset+=bytes.length;return entry;
  });
  const input=path.join(tmp,'payload.bin'),inventory=path.join(tmp,'inventory.json'),output=path.join(tmp,'groups.json');
  fs.writeFileSync(input,Buffer.concat(records.map(([,bytes])=>bytes)));
  fs.writeFileSync(inventory,JSON.stringify({entries}));
  const run=spawnSync(process.execPath,[path.join(project,'tools/plan_web_content.mjs'),'--input',input,'--inventory',inventory,'--output',output],{encoding:'utf8'});
  assert.equal(run.status,0,run.stderr+run.stdout);
  const plan=JSON.parse(fs.readFileSync(output));
  const report=JSON.parse(fs.readFileSync(output.replace('.json','.report.json')));
  const deferred=plan.groups.flatMap(g=>g.paths);
  for(const asset of required) {
    assert.ok(!deferred.includes(asset),'Font/import/license must not be deferred: '+asset);
    assert.ok(!report.unresolved.some(e=>e.path===asset),'Core font ownership must be explicit: '+asset);
  }
  assert.ok(deferred.includes('assets/rpg/interiors/library_fixture.png'),'Control asset remains deferred');
  assert.equal(report.groups.find(g=>g.id==='core').count,1+required.length,'Font import and payload propagate to core together');
  const presets=fs.readFileSync(path.join(project,'export_presets.cfg'),'utf8').split(/(?=\[preset\.\d+\]\n)/).filter(p=>p.startsWith('[preset.'));
  assert.equal(presets.length,3);
  for(const preset of presets) {
    assert.match(preset,/export_filter="all_resources"/,'Recognized font resources are exported');
    const include=preset.match(/^include_filter="([^"]+)"/m)[1].split(',');
    for(const logical of licenses) assert.ok(include.includes(logical),'Exact font license explicitly bundled: '+logical);
  }
  console.log('UI_FONT_PACK: PASS; project Regular/Medium, explicit symbol fallback and ten phone SVG imports/payloads retained in core; three presets include all related font licenses; later chapter control still deferred');
} finally {fs.rmSync(tmp,{recursive:true,force:true});}
