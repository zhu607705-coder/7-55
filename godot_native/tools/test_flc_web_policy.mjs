import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import crypto from 'node:crypto';
import assert from 'node:assert/strict';
import {spawnSync} from 'node:child_process';
import {campusPayloadIdentity,assertStoryOnlyPackEntries,isFlcRuntimePath,FLC_FONT_DEPENDENCIES} from './web_story_content_policy.mjs';
const temp=fs.mkdtempSync(path.join(os.tmpdir(),'755-flc-policy-'));
const flc='campuses/future_learning_center/';
const files=[...FLC_FONT_DEPENDENCIES,flc+'scripts/floor_view.gd',flc+'scripts/puzzles/logic_view.gd',flc+'data/floor_2.json',flc+'assets/floors/floor_2.png',flc+'tests/test_logic.gd','campuses/buct/scenes/playable.tscn','campuses/new_research/asset.png'];
try {
 for(const name of files){const file=path.join(temp,name);fs.mkdirSync(path.dirname(file),{recursive:true});fs.writeFileSync(file,'fixture');}
 const identity=campusPayloadIdentity(temp);
 for(const name of files){
  const hash=crypto.createHash('md5').update('res://'+name).digest('hex');
  for(const candidate of [name,`.godot/imported/asset-${hash}.ctex`,`.godot/exported/123/export-${hash}-floor.scn`]){
   assert.equal(identity.owner(candidate),name);
   if(isFlcRuntimePath(name))assert.doesNotThrow(()=>assertStoryOnlyPackEntries([{path:candidate}],identity));
   else assert.throws(()=>assertStoryOnlyPackEntries([{path:candidate}],identity),/Research campus resource leaked/);
  }
 }
 for(const name of ['design/model.json','review/image.png','docs/review.png','scripts/../tests/test.gd','assets/../../buct/file.png'])assert.equal(isFlcRuntimePath(flc+name),false);
 const project=path.resolve(import.meta.dirname,'..');
 const presets=fs.readFileSync(path.join(project,'export_presets.cfg'),'utf8');
 const preset=presets.split('[preset.2]')[1];
 for (const font of FLC_FONT_DEPENDENCIES) assert.ok(!presets.includes(font), `Native or Web preset excludes required font: ${font}`);
 const bench=fs.readFileSync(path.join(project,flc+'scripts/physical_bench.gd'),'utf8');
 for (const match of bench.matchAll(/load\("res:\/\/(ui_assets\/fonts\/[^"]+)"\)/g)) assert.ok(FLC_FONT_DEPENDENCIES.includes(match[1]), `Physical font requires explicit package ownership: ${match[1]}`);
 assert.match(preset,/755_production,755_web,755_story_only/);assert.match(preset,/campuses\/buct\*/);assert.ok(!preset.includes('campuses/*,'));
 for (const font of FLC_FONT_DEPENDENCIES) assert.ok(!preset.includes(font), `FLC font excluded: ${font}`);
 for (const file of ['CampusUISans-Regular.otf','SelectedSans-Bold.otf','SelectedCoverage-Bold.otf','SelectedBoutique-Regular.ttf']) assert.ok(preset.includes('ui_assets/fonts/'+file));
 const loader=fs.readFileSync(path.join(project,'web/content_loader.js'),'utf8');assert.ok(loader.includes("'flc_activity'"));
 // Use the actual planner and actual boot-source traversal with tiny exported
 // fixture entries: this proves family assignment and remap closure, not a Web export.
 const payload='.godot/exported/test/export-fixture-floor.scn';
 const fixture=[['project.binary','core'],[flc+'scripts/floor_view.gd','script'],[flc+'data/floor_2.json','{}'],[flc+'scenes/floor.tscn.remap',`[remap]\npath="res://${payload}"`],[payload,'scene'],...FLC_FONT_DEPENDENCIES.flatMap((font,i)=>[[font,'font'],[font+'.import',`[remap]\npath="res://.godot/imported/flcfont${i}.fontdata"`],[`.godot/imported/flcfont${i}.fontdata`,'imported font']])];
 let offset=0;const entries=fixture.map(([name,value])=>{const bytes=Buffer.from(value);const entry={path:name,offset,bytes:bytes.length};offset+=bytes.length;return entry;});
 fs.writeFileSync(path.join(temp,'input.pck'),Buffer.concat(fixture.map(([,value])=>Buffer.from(value))));fs.writeFileSync(path.join(temp,'inventory.json'),JSON.stringify({entries}));
 const result=spawnSync(process.execPath,[path.join(project,'tools/plan_web_content.mjs'),'--input',path.join(temp,'input.pck'),'--inventory',path.join(temp,'inventory.json'),'--output',path.join(temp,'groups.json')],{encoding:'utf8'});
 assert.equal(result.status,0,result.stderr);
 const groups=JSON.parse(fs.readFileSync(path.join(temp,'groups.json'))).groups;
 const activity=groups.filter(g=>g.id.startsWith('flc_activity_')).flatMap(g=>g.paths);
 for(const [name] of fixture.slice(1))assert.ok(activity.includes(name),`deferred FLC resource ${name}`);
 const report=JSON.parse(fs.readFileSync(path.join(temp,'groups.report.json')));
 assert.equal(report.groups.find(g=>g.id==='core').count,1,'FLC fonts must not grow core');
 assert.ok(!activity.includes('project.binary'));
 assert.ok(!report.startupPromotions.some(item=>item.logicalPath?.startsWith(flc)));
 console.log('PASS: FLC-only logical/anonymous policy, research exclusion, story flag, loader family, actual planner lazy remap closure');
}finally{fs.rmSync(temp,{recursive:true,force:true});}
