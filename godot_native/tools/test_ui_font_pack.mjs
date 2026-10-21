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
  const fonts=['CampusUISans-Regular.otf','SelectedSans-Regular.otf','SelectedSans-Bold.otf','SelectedCoverage-Regular.otf','SelectedCoverage-Bold.otf','SelectedBoutique-Regular.ttf'];
  const licenses=['OFL.txt','SELECTED_NOTO_LICENSE.txt','SELECTED_BOUTIQUE_OFL.txt'];
  const records=[['project.binary',Buffer.from('controlled ownership fixture, not a PCK')]];
  const required=[];
  for(const filename of fonts) {
    const logical='ui_assets/fonts/'+filename;
    const metadata=fs.readFileSync(path.join(project,logical+'.import'));
    const target=metadata.toString().match(/path="res:\/\/([^"\n]+)"/)[1];
    records.push([logical+'.import',metadata],[target,fs.readFileSync(path.join(project,target))]);
    required.push(logical+'.import',target);
  }
  for(const filename of licenses) {
    const logical='ui_assets/fonts/'+filename;
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
    assert.match(preset,/export_filter="all_resources"/,'Recognized OTF resource exported');
    const include=preset.match(/^include_filter="([^"]+)"/m)[1].split(',');
    for(const filename of licenses) assert.ok(include.includes('ui_assets/fonts/'+filename),'Exact font license explicitly bundled: '+filename);
  }
  console.log('UI_FONT_PACK: PASS; all six actual font imports/payloads retained in explicit core; three presets include all font licenses; later chapter control still deferred');
} finally {fs.rmSync(tmp,{recursive:true,force:true});}
