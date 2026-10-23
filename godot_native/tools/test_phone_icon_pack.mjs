#!/usr/bin/env node
// Builds a minimal real PCK from the production SVG import metadata/payloads,
// then loads the production dynamic icon helper with no source tree available.
import fs from 'node:fs';
import path from 'node:path';
import os from 'node:os';
import assert from 'node:assert/strict';
import {spawnSync} from 'node:child_process';
import {fileURLToPath} from 'node:url';
import {createNativeTestSandbox} from './native_test_sandbox.mjs';
const project=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..');
const tmp=fs.mkdtempSync(path.join(os.tmpdir(),'755-phone-icon-pack-'));
const sandbox=createNativeTestSandbox(project,'755-phone-icon-pack-profile-');
const ids=['messages','sports','album','recovery','voice','controls','clock'];
try {
  const config=path.join(tmp,'project.godot');
  fs.writeFileSync(config,'config_version=5\n[application]\nconfig/name="PhoneIconPackProbe"\n[rendering]\nrenderer/rendering_method="gl_compatibility"\n');
  const probe=path.join(tmp,'probe.gd');
  fs.writeFileSync(probe,`extends SceneTree
func _initialize()->void:
 var helper=load("res://scripts/ui/phone_launcher_icons.gd")
 var unique:Dictionary={}
 for id:String in helper.FILES:
  var button:=Control.new()
  var glyph:TextureRect=helper.add_to(button,id)
  assert(glyph.texture!=null,"Packed dynamic SVG must load: "+id)
  var pixels:Image=glyph.texture.get_image()
  assert(pixels!=null and not pixels.is_empty(),"Actual imported texture pixels exist: "+id)
  var ink:=0
  for y:int in pixels.get_height():
   for x:int in pixels.get_width():
    if pixels.get_pixel(x,y).a>.1:ink+=1
  assert(ink>20 and ink<pixels.get_width()*pixels.get_height(),"Glyph has real strokes and transparent surround: "+id)
  unique[hash(pixels.get_data())]=true
  button.free()
 assert(unique.size()==7,"Seven source-CSS textures survive packing; PNG/gear/wordmark use their existing renderers")
 print("PHONE_ICON_PACK: PASS seven distinct source-CSS textures loaded from source-less PCK")
 quit()
`);
  const pack=path.join(tmp,'icons.pck');
  const entries=[['res://project.godot',config],['res://probe.gd',probe],['res://scripts/ui/phone_launcher_icons.gd',path.join(project,'scripts/ui/phone_launcher_icons.gd')]];
  for(const id of ids){
    const logical='ui_assets/phone_icons/'+id+'.svg';
    const metadata=fs.readFileSync(path.join(project,logical+'.import'),'utf8');
    const imported=metadata.match(/path="res:\/\/([^"\n]+)"/)[1];
    entries.push(['res://'+logical+'.import',path.join(project,logical+'.import')],['res://'+imported,path.join(project,imported)]);
  }
  const builder=path.join(tmp,'build.gd');
  fs.writeFileSync(builder,`extends SceneTree
func _initialize()->void:
 var pack:=PCKPacker.new()
 assert(pack.pck_start(${JSON.stringify(pack)})==OK)
 for pair:Array in ${JSON.stringify(entries)}:
  assert(pack.add_file(pair[0],pair[1])==OK)
 assert(pack.flush()==OK)
 quit()
`);
  const run=(args,cwd)=>{const r=spawnSync('godot',args,{cwd,env:sandbox.env,encoding:'utf8',timeout:45000});assert.equal(r.status,0,r.stdout+r.stderr);assert.doesNotMatch(r.stdout+r.stderr,/SCRIPT ERROR|ERROR:/);return r.stdout;};
  run(['--headless','--path',project,'--script',builder],tmp);
  const empty=path.join(tmp,'source-less');fs.mkdirSync(empty);
  const output=run(['--headless','--path',empty,'--main-pack',pack,'--script','res://probe.gd'],empty);
  assert.match(output,/PHONE_ICON_PACK: PASS/);console.log(output.trim());
} finally {fs.rmSync(tmp,{recursive:true,force:true});fs.rmSync(sandbox.root,{recursive:true,force:true});}
