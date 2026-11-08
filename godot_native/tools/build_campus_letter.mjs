#!/usr/bin/env node
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import {spawnSync} from 'node:child_process';

// Small independent Godot preview. No production preset, entry or save is changed.
const native = path.resolve(import.meta.dirname, '..');
const godot = process.env.GODOT_BIN || 'godot';
const version = spawnSync(godot, ['--version'], {encoding:'utf8'}).stdout?.trim();
if (!version?.startsWith('4.7.1.stable.official')) throw Error('This preview requires the project-pinned Godot 4.7.1.');
const project = path.join(native, 'exports/campus-letter-project');
const output = path.join(native, 'exports/campus-letter-web');
fs.mkdirSync(project,{recursive:true}); fs.mkdirSync(output,{recursive:true});
// Rebuild only generated resource directories; keep the import cache.
for (const dir of ['assets','campuses','scripts','tests','ui_assets']) fs.rmSync(path.join(project,dir),{recursive:true,force:true});
const files = new Map();
function copyResource(relative) {
  if (files.has(relative)) return;
  const source = path.join(native,relative);
  const bytes = fs.readFileSync(source);
  files.set(relative,{path:relative,sha256:crypto.createHash('sha256').update(bytes).digest('hex'),bytes:bytes.length});
  const target = path.join(project,relative);
  fs.mkdirSync(path.dirname(target),{recursive:true}); fs.writeFileSync(target,bytes);
  if (/\.(gd|tscn)$/.test(relative)) {
    for (const match of bytes.toString().matchAll(/res:\/\/([^"'\s]+\.(?:gd|tscn|png|jpg|ttf|otf|glb|json|scn|gdshader))/g)) copyResource(match[1]);
  }
}
copyResource('campuses/campus_letter/scenes/samples.tscn');
copyResource('tests/test_campus_letter.gd');
fs.writeFileSync(path.join(project,'project.godot'),`config_version=5
[application]
config/name="7:55 · 校园来信"
run/main_scene="res://campuses/campus_letter/scenes/samples.tscn"
config/use_custom_user_dir=true
config/custom_user_dir_name="SevenFiftyFiveCampusLetterPreview"
config/features=PackedStringArray("4.7", "GL Compatibility")
[display]
window/size/viewport_width=1280
window/size/viewport_height=720
window/size/window_width_override=1280
window/size/window_height_override=720
window/stretch/mode="canvas_items"
window/stretch/aspect="keep"
[input_devices]
pointing/emulate_mouse_from_touch=false
[rendering]
renderer/rendering_method="gl_compatibility"
renderer/rendering_method.mobile="gl_compatibility"
textures/canvas_textures/default_texture_filter=1
anti_aliasing/quality/msaa_3d=2
lights_and_shadows/directional_shadow/size=4096
textures/default_filters/use_nearest_mipmap_filter=false
`);
fs.writeFileSync(path.join(project,'export_presets.cfg'),`[preset.0]
name="Campus letter web"
platform="Web"
runnable=true
export_filter="all_resources"
include_filter=""
exclude_filter="tests/*"
export_path="../campus-letter-web/index.html"
[preset.0.options]
variant/extensions_support=false
variant/thread_support=false
vram_texture_compression/for_desktop=true
vram_texture_compression/for_mobile=false
html/canvas_resize_policy=2
html/focus_canvas_on_start=true
progressive_web_app/enabled=false
`);
function run(args,logName) {
  const result = spawnSync(godot,['--headless','--path',project,...args],{encoding:'utf8',maxBuffer:32*1024*1024});
  const log=(result.stdout||'')+(result.stderr||'');
  fs.writeFileSync(path.join(output,logName),log);
  if (result.status!==0 || /SCRIPT ERROR:|ERROR:/.test(log)) throw Error(log.slice(-12000));
}
run(['--editor','--import'],'import.log');
run(['--script','res://tests/test_campus_letter.gd'],'tests.log');
fs.rmSync(path.join(project,'.godot/exported'),{recursive:true,force:true});
run(['--export-release','Campus letter web',path.join(output,'index.html')],'export.log');
const htmlPath = path.join(output,'index.html');
let html = fs.readFileSync(htmlPath,'utf8').replace('<html lang="en">','<html lang="zh-CN">');
html = html.replace('</body>', `<style>#portrait-guide{display:none;position:fixed;inset:0;background:#e8ede6;color:#23464c;z-index:20;align-items:center;justify-content:center;text-align:center;font:22px/1.8 system-ui,sans-serif;padding:36px;box-sizing:border-box}@media(orientation:portrait){#portrait-guide{display:flex}}#portrait-guide span{display:block;font-size:16px;margin-top:12px}</style><div id="portrait-guide"><div>请横屏游玩<span>转动手机后，继续第一人称探索。</span></div></div></body>`);
fs.writeFileSync(htmlPath,html);
fs.writeFileSync(path.join(output,'sample-manifest.json'),JSON.stringify({engine:version,entry:'campuses/campus_letter/scenes/samples.tscn',sourceFiles:[...files.values()],scope:'Four standalone campus-life samples; no main-game persistence or production deployment.'},null,2));
console.log(JSON.stringify({project,output,engine:version,resources:files.size}));
