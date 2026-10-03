import fs from 'node:fs';
import path from 'node:path';
import os from 'node:os';
import {spawnSync} from 'node:child_process';
const project=path.resolve(import.meta.dirname,'..');
const executable=process.env.GODOT_BIN||'godot';
const logs=[];
function run(label,args,command=executable){
 const sandbox=fs.mkdtempSync(path.join(os.tmpdir(),'755-native-check-'));
 for(const folder of ['data','config','cache','state'])fs.mkdirSync(path.join(sandbox,folder));
 const env={...process.env,XDG_DATA_HOME:path.join(sandbox,'data'),XDG_CONFIG_HOME:path.join(sandbox,'config'),XDG_CACHE_HOME:path.join(sandbox,'cache'),XDG_STATE_HOME:path.join(sandbox,'state'),GODOT_SILENCE_ROOT_WARNING:'1'};
 const timeout=(label==='Godot asset import and editor parse'?20:label==='test_full_campaign.gd'?12:5)*60*1000;
 const r=spawnSync(command,args,{encoding:'utf8',maxBuffer:32*1024*1024,timeout,env});
 const text=(r.stdout||'')+(r.stderr||''); logs.push({label,status:r.status,output:text});
 const failed=r.error||r.status!==0||/(?:^|\n)ERROR:|SCRIPT ERROR:|Parse Error:|Failed to load script|TEST FAILED|ASSERTION FAILED/.test(text);
 console.log(`${failed?'FAIL':'PASS'} ${label}`);
 if(failed){console.error(text.slice(-24000));process.exitCode=1;} return !failed;
}
if(!fs.existsSync(path.join(project,'assets/rpg/fonts/fusion_pixel_12px_proportional_zh_hans.ttf')))throw Error('Run node godot_native/tools/sync_source.mjs first');
run('Godot asset import and editor parse',['--headless','--path',project,'--editor','--import','--quit']);
run('Native startup',['--headless','--path',project,'--quit-after','15','--','--fresh']);
for(const f of fs.readdirSync(path.join(project,'tests')).filter(x=>x.endsWith('.gd')&&x!=='test_save_migration.gd'&&(x.startsWith('test_')||x.startsWith('smoke_'))).sort())run(f,['--headless','--path',project,'--script',`res://tests/${f}`]);
for(const relative of ['tools/export-save-domains.mjs','tools/export-audio-director.mjs','tools/export-c3-world-source.mjs','tools/export-chapter4-device-source.mjs','tools/export-chapter4-context-source.mjs','tests/export_audio_state_fixtures.mjs','tests/export_chapter3_scene_source.mjs','tests/export_library_story_source.mjs','tests/export_lake_live_source_fixtures.mjs','tests/export_chapter3_narrative_source.mjs','tests/export_library_world_source.mjs','tests/export_canteen_mixer_source.mjs','tests/export_c3_devices_source.mjs','tests/export_c3_canteen_devices_source.mjs','tests/export_c3_bike_world_source.mjs']) {
 const args=[path.join(project,relative),'--check'];
 if(['tests/export_c3_canteen_devices_source.mjs','tests/export_c3_bike_world_source.mjs'].includes(relative))args.push('--source-root',path.dirname(project));
 run('Source catalog '+relative,args,process.execPath);
}
for(const relative of ['tests/verify_source_model_parity.mjs','tests/verify_canteen_defense_source.mjs','tests/verify_lake_branch_source.mjs'])run('Source oracle '+relative,[path.join(project,relative)],process.execPath);
run('Phone entry source contracts', [path.join(project,'tests/verify_phone_entry_source.py')], 'python3');
run('Photo brightness source lifecycle', [path.join(project,'tests/verify_photo_consumer_source.mjs')],process.execPath);
run('Tiyi presence source setter', [path.join(project,'tests/export_tiyi_presence_source.mjs'),'--check'],process.execPath);
run('Tiyi presence source CLI', [path.join(project,'tests/verify_tiyi_oracle_cli.mjs')],process.execPath);
run('Canteen objective source handoff', [path.join(project,'tests/export_canteen_handoff_source.mjs'),'--source-root',path.dirname(project),'--check'],process.execPath);
run('Canteen self-drink source contract', [path.join(project,'tests/export_canteen_self_drink_source.mjs'),'--source-root',path.dirname(project),'--check'],process.execPath);
run('Original SaveStore differential', [path.join(project,'tests/verify_save_migration.mjs')],process.execPath);
if(process.env.GODOT_TEST_REPORT)fs.writeFileSync(process.env.GODOT_TEST_REPORT,JSON.stringify(logs,null,2));
