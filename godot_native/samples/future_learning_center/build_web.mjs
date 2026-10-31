import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import crypto from 'node:crypto';
import {spawnSync} from 'node:child_process';

const native=path.resolve(import.meta.dirname,'../..');
const output=process.argv[2]&&path.resolve(process.argv[2]);
if(!output)throw Error('Pass a standalone review output directory');
const engine=process.env.GODOT_BIN||'godot';
const version=spawnSync(engine,['--version'],{encoding:'utf8'});
if(version.status!==0||!version.stdout.trim().startsWith('4.7.1.'))throw Error('Godot 4.7.1 is required');
const template=process.env.GODOT_WEB_TEMPLATE;
if(!template||!fs.existsSync(template))throw Error('Set GODOT_WEB_TEMPLATE to the matching 4.7.1 web_nothreads_release.zip');
const temporary=fs.mkdtempSync(path.join(os.tmpdir(),'755-flc-workshop-'));
const project=path.join(temporary,'project');fs.mkdirSync(project,{recursive:true});fs.mkdirSync(output,{recursive:true});
const copied=new Set();
function copy(relative){
 if(copied.has(relative))return;copied.add(relative);
 const source=path.join(native,relative),target=path.join(project,relative);
 fs.mkdirSync(path.dirname(target),{recursive:true});fs.copyFileSync(source,target);
 if(relative.endsWith('.gd'))for(const match of fs.readFileSync(source,'utf8').matchAll(/["']res:\/\/([^"'\n]+)["']/g)){
  const dep=match[1];if(!dep.includes('%')&&fs.existsSync(path.join(native,dep)))copy(dep);
 }
}
copy('samples/future_learning_center/standalone.gd');
const campus='campuses/future_learning_center';
// Station scripts are loaded by registry at runtime, not static preload.
for(const name of fs.readdirSync(path.join(native,campus,'scripts/puzzles')))if(name.endsWith('.gd'))copy(campus+'/scripts/puzzles/'+name);
for(const name of ['floor_2.json','floor_3.json','floor_4.json','object_assets.json'])copy(campus+'/data/'+name);
for(const dir of ['assets/rooms','assets/objects'])for(const name of fs.readdirSync(path.join(native,campus,dir)))if(name.endsWith('.png'))copy(campus+'/'+dir+'/'+name);
// Atrium resources can live outside the room directory; copy exact source refs.
for(const f of [2,3,4]){
 const data=JSON.parse(fs.readFileSync(path.join(native,campus,`data/floor_${f}.json`),'utf8'));
 for(const row of [...data.modules,...data.objects,...(data.atriums||[]),...(data.atrium?[data.atrium]:[])])for(const key of ['path','source'])if(row[key]?.startsWith('res://'))copy(row[key].slice(6));
}
for(const facing of ['down','up','side'])for(let i=0;i<8;i++)copy(`assets/rpg/player/player_${facing}_${i}.png`);
for(const license of ['ui_assets/fonts/MORNING_NOTE_OFL.txt','ui_assets/fonts/SELECTED_NOTO_LICENSE.txt','ui_assets/fonts/SELECTED_BOUTIQUE_OFL.txt','assets/rpg/fonts/licenses/FUSION_PIXEL_FONT_OFL.txt'])if(fs.existsSync(path.join(native,license)))copy(license);
const config=`config_version=5
[application]
config/name="7:55 · 房间谜题试玩"
config/use_custom_user_dir=true
config/custom_user_dir_name="755FLCWorkshopReview"
run/main_scene="res://main.tscn"
config/features=PackedStringArray("4.7", "GL Compatibility")
[display]
window/size/viewport_width=960
window/size/viewport_height=540
window/stretch/mode="disabled"
[input_devices]
pointing/emulate_mouse_from_touch=false
[rendering]
renderer/rendering_method="gl_compatibility"
renderer/rendering_method.mobile="gl_compatibility"
textures/canvas_textures/default_texture_filter=0
environment/defaults/default_clear_color=Color(0.06,0.09,0.12,1)
`;
fs.writeFileSync(path.join(project,'project.godot'),config);
fs.writeFileSync(path.join(project,'main.tscn'),'[gd_scene load_steps=2 format=3]\n[ext_resource type="Script" path="res://samples/future_learning_center/standalone.gd" id="1"]\n[node name="FLCWorkshopReview" type="Node"]\nscript = ExtResource("1")\n');
fs.writeFileSync(path.join(project,'export_presets.cfg'),`[preset.0]
name="FLC review"
platform="Web"
runnable=true
advanced_options=true
export_filter="all_resources"
include_filter="*.json,*.txt"
exclude_filter="*.md,*.mjs"
script_export_mode=2
[preset.0.options]
custom_template/release=${JSON.stringify(path.resolve(template))}
variant/extensions_support=false
variant/thread_support=false
vram_texture_compression/for_desktop=true
vram_texture_compression/for_mobile=false
html/export_icon=false
html/canvas_resize_policy=2
html/focus_canvas_on_start=true
progressive_web_app/enabled=false
`);
const env={...process.env};for(const name of ['XDG_DATA_HOME','XDG_CONFIG_HOME','XDG_CACHE_HOME','XDG_STATE_HOME']){env[name]=path.join(temporary,name);fs.mkdirSync(env[name],{recursive:true});}
const report={engine:version.stdout.trim(),projectConfigSha256:crypto.createHash('sha256').update(config).digest('hex'),autoloads:[],productionSaveAccess:false,browserAcceptance:false,stages:[]};
function run(label,args){
 console.log('START '+label);
 const r=spawnSync(engine,['--headless','--audio-driver','Dummy','--path',project,...args],{env,encoding:'utf8',timeout:240000,maxBuffer:16*1024*1024});
 const log=(r.stdout||'')+(r.stderr||'');
 const passed=!r.error&&r.status===0&&!/SCRIPT ERROR:|Parse Error:|(?:^|\n)ERROR:/.test(log);
 report.stages.push({label,passed,status:r.status});fs.writeFileSync(path.join(output,label+'.log'),log);
 if(!passed){console.error(log.slice(-8000));throw Error(label+' failed');}console.log('PASS '+label);
}
try{
 run('import',['--editor','--import','--quit']);
 run('startup',['--quit-after','15']);
 run('web_export',['--export-release','FLC review',path.join(output,'index.html')]);
 for(const name of ['index.html','index.js','index.wasm','index.pck'])if(!fs.existsSync(path.join(output,name)))throw Error('Missing '+name);
 fs.writeFileSync(path.join(output,'build_receipt.json'),JSON.stringify(report,null,2)+'\n');
 console.log('Standalone Godot review export: '+output);
}finally{fs.rmSync(temporary,{recursive:true,force:true});}
